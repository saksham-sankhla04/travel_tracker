import 'dart:async';
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

      // Skip trip detection when GPS accuracy is very poor (>50m)
      if (position.accuracy > 50) return;

      if (speed > speedThresholdMps && !isTripActive) {
        // ---- TRIP START (unchanged) ----
        isTripActive = true;
        tripStartTime = DateTime.now();
        tripStartLat = position.latitude;
        tripStartLng = position.longitude;

        // Reset any lingering cooldown state
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
        if (speed <= tripEndSpeedThresholdMps) {
          // Low speed reading — increment cooldown counter
          lowSpeedReadingCount++;

          if (lowSpeedReadingCount == 1) {
            // First low-speed reading: capture where they stopped
            cooldownStartTime = DateTime.now();
            cooldownStartLat = position.latitude;
            cooldownStartLng = position.longitude;
          }

          if (lowSpeedReadingCount >= cooldownReadingsRequired) {
            // ---- TRIP END (sustained low speed for ~5 minutes) ----
            isTripActive = false;

            // Use coordinates from when low speed FIRST started
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
                  'survey:${tripStartTime?.toIso8601String() ?? tripEndTime.toIso8601String()},${tripEndTime.toIso8601String()},${tripStartLat},${tripStartLng},${tripEndLat},${tripEndLng}',
            );

            // Persist pending trip so the survey shows even if user opens app directly
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('pending_trip',
                '{"startTime":"${tripStartTime?.toIso8601String() ?? tripEndTime.toIso8601String()}","endTime":"${tripEndTime.toIso8601String()}","startLat":$tripStartLat,"startLng":$tripStartLng,"endLat":$tripEndLat,"endLng":$tripEndLng}');

            // Reset all state
            tripStartTime = null;
            tripStartLat = null;
            tripStartLng = null;
            lowSpeedReadingCount = 0;
            cooldownStartTime = null;
            cooldownStartLat = null;
            cooldownStartLng = null;
          }
        } else {
          // Speed picked back up during cooldown — reset the counter
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
