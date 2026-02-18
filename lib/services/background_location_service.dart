import 'dart:async';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';

/// Speed threshold in m/s. 10 km/h = ~2.78 m/s.
const double speedThresholdMps = 2.78;

/// How often to check location (in seconds).
const int locationCheckIntervalSec = 15;

class BackgroundLocationService {
  static final FlutterBackgroundService _service = FlutterBackgroundService();

  /// Initializes and configures the background service.
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

/// Entry point for the background service — runs in an isolate.
@pragma('vm:entry-point')
Future<void> _onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  bool isTripActive = false;

  // Initialize notifications directly in the isolate
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

      final speed = position.speed; // m/s

      // Send location data back to the UI
      service.invoke('locationUpdate', {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'speed': speed,
        'speedKmh': speed * 3.6,
        'timestamp': position.timestamp.toIso8601String(),
        'isTripActive': speed > speedThresholdMps,
      });

      // Trip detection: speed exceeds threshold
      if (speed > speedThresholdMps && !isTripActive) {
        isTripActive = true;
        await notifPlugin.show(
          0,
          'Trip Detected',
          'It looks like you are travelling. Tap to log your trip details.',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'trip_detection_channel',
              'Trip Detection',
              channelDescription: 'Notifications when a trip is detected',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      } else if (speed <= speedThresholdMps) {
        isTripActive = false;
      }
    } catch (e) {
      // Silently handle — location may be temporarily unavailable
    }
  });
}

@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  return true;
}
