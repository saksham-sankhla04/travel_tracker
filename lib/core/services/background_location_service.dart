import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Speed threshold for trip START in m/s. 10 km/h = ~2.78 m/s.
const double speedThresholdMps = 2.78;

/// Speed threshold for trip END in m/s. 5 km/h = ~1.39 m/s.
/// Lower than start threshold to create hysteresis and avoid toggling.
const double tripEndSpeedThresholdMps = 1.39;

/// How often to check location (in seconds).
const int locationCheckIntervalSec = 15;

/// Consecutive low-speed readings required before trip ends.
/// At 15-second intervals, 20 readings = 5 minutes.
const int cooldownReadingsRequired = 20;

class BackgroundLocationService {
  static final FlutterBackgroundService _service = FlutterBackgroundService();

  static Future<void> initialize() async {
    await _service.configure(
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        isForegroundMode: true,
        autoStart: false,
        autoStartOnBoot: true,
        notificationChannelId: 'travel_tracker_bg',
        initialNotificationTitle: 'Travel Tracker',
        initialNotificationContent: 'Monitoring for trips...',
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
    );
  }

  static Future<void> startService() async {
    await _service.startService();
  }

  static Future<void> stopService() async {
    _service.invoke('stopService');
  }

  static Stream<Map<String, dynamic>?> get updates =>
      _service.on('locationUpdate');
}

@pragma('vm:entry-point')
Future<void> _onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  bool isTripActive = false;
  DateTime? tripStartTime;
  double? tripStartLat;
  double? tripStartLng;

  // Route points collected during the trip
  List<Map<String, double>> routePoints = [];

  // Cooldown state for robust trip-end detection
  int lowSpeedReadingCount = 0;
  DateTime? cooldownStartTime;
  double? cooldownStartLat;
  double? cooldownStartLng;

  final notifPlugin = FlutterLocalNotificationsPlugin();
  await notifPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );

  service.on('stopService').listen((_) async {
    await service.stopSelf();
  });

  Timer.periodic(Duration(seconds: locationCheckIntervalSec), (_) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final speed = position.speed;

      service.invoke('locationUpdate', {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'speed': speed,
        'speedKmh': speed * 3.6,
        'timestamp': position.timestamp.toIso8601String(),
        'isTripActive': isTripActive,
        'tripStartTime': tripStartTime?.toIso8601String(),
        'isCoolingDown': isTripActive && lowSpeedReadingCount > 0,
        'cooldownProgress': isTripActive
            ? lowSpeedReadingCount / cooldownReadingsRequired
            : 0.0,
        'accuracy': position.accuracy,
      });

      // Idle = purely speed-based (no GPS quality check during R&D)
      final bool isIdle = speed <= tripEndSpeedThresholdMps;

      // ---- TRIP START ----
      if (speed > speedThresholdMps && !isTripActive) {
        isTripActive = true;
        tripStartTime = DateTime.now();
        tripStartLat = position.latitude;
        tripStartLng = position.longitude;
        routePoints = [{'lat': position.latitude, 'lng': position.longitude}];
        lowSpeedReadingCount = 0;
        cooldownStartTime = null;
        cooldownStartLat = null;
        cooldownStartLng = null;

        await notifPlugin.show(
          0,
          'Trip Detected',
          'You seem to be travelling. We\'ll ask for details when you stop.',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'trip_detection_channel',
              'Trip Detection',
              channelDescription: 'Notifications when a trip is detected',
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
            ),
          ),
        );
      } else if (isTripActive) {
        // ---- DURING AN ACTIVE TRIP ----
        // Collect all route points during R&D (no GPS filter)
        routePoints.add({'lat': position.latitude, 'lng': position.longitude});

        if (isIdle) {
          // User appears idle — increment cooldown
          lowSpeedReadingCount++;

          if (lowSpeedReadingCount == 1) {
            // First idle reading: capture where they stopped
            cooldownStartTime = DateTime.now();
            cooldownStartLat = position.latitude;
            cooldownStartLng = position.longitude;
          }

          if (lowSpeedReadingCount >= cooldownReadingsRequired) {
            // ---- TRIP END (idle for ~5 minutes) ----
            isTripActive = false;
            final tripEndTime = cooldownStartTime!;
            final tripEndLat = cooldownStartLat!;
            final tripEndLng = cooldownStartLng!;

            await notifPlugin.show(
              1,
              'Trip Ended',
              'Your trip has ended. Tap to complete the survey.',
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'trip_detection_channel',
                  'Trip Detection',
                  channelDescription: 'Notifications when a trip is detected',
                  importance: Importance.high,
                  priority: Priority.high,
                ),
              ),
              payload:
                  'survey:${tripStartTime?.toIso8601String() ?? tripEndTime.toIso8601String()},${tripEndTime.toIso8601String()},$tripStartLat,$tripStartLng,$tripEndLat,$tripEndLng',
            );

            final prefs = await SharedPreferences.getInstance();
            final pendingTrip = {
              'startTime': tripStartTime?.toIso8601String() ?? tripEndTime.toIso8601String(),
              'endTime': tripEndTime.toIso8601String(),
              'startLat': tripStartLat,
              'startLng': tripStartLng,
              'endLat': tripEndLat,
              'endLng': tripEndLng,
              'routePoints': routePoints,
            };
            await prefs.setString('pending_trip', jsonEncode(pendingTrip));

            tripStartTime = null;
            tripStartLat = null;
            tripStartLng = null;
            routePoints = [];
            lowSpeedReadingCount = 0;
            cooldownStartTime = null;
            cooldownStartLat = null;
            cooldownStartLng = null;
          }
        } else {
          // User is moving (good GPS + high speed) — reset cooldown
          lowSpeedReadingCount = 0;
          cooldownStartTime = null;
          cooldownStartLat = null;
          cooldownStartLng = null;
        }
      }
    } catch (e) {
      // Location may be temporarily unavailable
    }
  });
}

@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  return true;
}
