import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
const String apiBaseUrl = 'https://travel-tracker-8li7.onrender.com';

class BackgroundLocationService {
  static final FlutterBackgroundService _service = FlutterBackgroundService();
  static const String _pendingTripKey = 'pending_trip';
  static const String _tripRecordsKey = 'trip_records';

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

  static Future<void> endCurrentTripManually() async {
    _service.invoke('manualStopTrip');
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

  Future<void> persistTripData({
    required DateTime tripEndTime,
    required double tripEndLat,
    required double tripEndLng,
    required bool endedManually,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final startTime =
        tripStartTime?.toIso8601String() ?? tripEndTime.toIso8601String();

    final pendingTrip = {
      'startTime': startTime,
      'endTime': tripEndTime.toIso8601String(),
      'startLat': tripStartLat,
      'startLng': tripStartLng,
      'endLat': tripEndLat,
      'endLng': tripEndLng,
      'routePoints': routePoints,
    };
    await prefs.setString(
      BackgroundLocationService._pendingTripKey,
      jsonEncode(pendingTrip),
    );

    final raw =
        prefs.getStringList(BackgroundLocationService._tripRecordsKey) ?? [];
    final tripRecord = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'startTime': startTime,
      'endTime': tripEndTime.toIso8601String(),
      'startLat': tripStartLat,
      'startLng': tripStartLng,
      'endLat': tripEndLat,
      'endLng': tripEndLng,
      'routePoints': routePoints,
      'endedManually': endedManually,
      'surveySubmitted': false,
      'isSynced': false,
      'createdAt': DateTime.now().toIso8601String(),
    };
    raw.add(jsonEncode(tripRecord));
    await prefs.setStringList(BackgroundLocationService._tripRecordsKey, raw);

    final synced = await _submitTripRecordWithDefaults(tripRecord);
    if (synced) {
      final syncedList = raw.map((s) {
        final json = jsonDecode(s) as Map<String, dynamic>;
        if (json['id'] == tripRecord['id']) {
          json['isSynced'] = true;
        }
        return jsonEncode(json);
      }).toList();
      await prefs.setStringList(
        BackgroundLocationService._tripRecordsKey,
        syncedList,
      );
    }
  }

  Future<void> finalizeTrip({
    required DateTime tripEndTime,
    required double tripEndLat,
    required double tripEndLng,
    required bool endedManually,
  }) async {
    if (!isTripActive) return;

    isTripActive = false;
    await persistTripData(
      tripEndTime: tripEndTime,
      tripEndLat: tripEndLat,
      tripEndLng: tripEndLng,
      endedManually: endedManually,
    );

    await notifPlugin.show(
      1,
      'Trip Ended',
      endedManually
          ? 'Trip ended manually. Tap to complete the survey.'
          : 'Your trip has ended. Tap to complete the survey.',
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

    tripStartTime = null;
    tripStartLat = null;
    tripStartLng = null;
    routePoints = [];
    lowSpeedReadingCount = 0;
    cooldownStartTime = null;
    cooldownStartLat = null;
    cooldownStartLng = null;
  }

  service.on('manualStopTrip').listen((_) async {
    if (!isTripActive) return;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      routePoints.add({'lat': position.latitude, 'lng': position.longitude});
      await finalizeTrip(
        tripEndTime: DateTime.now(),
        tripEndLat: position.latitude,
        tripEndLng: position.longitude,
        endedManually: true,
      );
      service.invoke('locationUpdate', {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'speed': position.speed,
        'speedKmh': position.speed * 3.6,
        'timestamp': DateTime.now().toIso8601String(),
        'isTripActive': false,
        'tripStartTime': null,
        'isCoolingDown': false,
        'cooldownProgress': 0.0,
        'accuracy': position.accuracy,
      });
    } catch (_) {
      // Ignore manual-stop failures if location is temporarily unavailable.
    }
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
        routePoints = [
          {'lat': position.latitude, 'lng': position.longitude},
        ];
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
            await finalizeTrip(
              tripEndTime: cooldownStartTime!,
              tripEndLat: cooldownStartLat!,
              tripEndLng: cooldownStartLng!,
              endedManually: false,
            );
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

Future<bool> _submitTripRecordWithDefaults(
  Map<String, dynamic> tripRecord,
) async {
  try {
    final httpClient = HttpClient();
    final request = await httpClient.postUrl(
      Uri.parse('$apiBaseUrl/api/trips'),
    );
    request.headers.contentType = ContentType.json;
    request.add(
      utf8.encode(
        jsonEncode({
          'tripStartTime': tripRecord['startTime'],
          'tripEndTime': tripRecord['endTime'],
          'tripPurpose': 'unknown',
          'modeOfTransport': 'unknown',
          'numberOfPassengers': 0,
          'surveyCompletedAt': tripRecord['endTime'],
          'startLat': tripRecord['startLat'],
          'startLng': tripRecord['startLng'],
          'endLat': tripRecord['endLat'],
          'endLng': tripRecord['endLng'],
          'routePoints': tripRecord['routePoints'],
          'isAutoSubmitted': true,
        }),
      ),
    );
    final response = await request.close();
    await response.drain();
    httpClient.close();
    return response.statusCode == 200 || response.statusCode == 201;
  } catch (_) {
    return false;
  }
}

@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  return true;
}
