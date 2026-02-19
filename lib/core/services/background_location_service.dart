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
        'isTripActive': speed > speedThresholdMps,
        'tripStartTime': tripStartTime?.toIso8601String(),
      });

      if (speed > speedThresholdMps && !isTripActive) {
        // Trip just started
        isTripActive = true;
        tripStartTime = DateTime.now();

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
          payload: 'survey:${tripStartTime!.toIso8601String()}',
        );
      } else if (speed <= speedThresholdMps && isTripActive) {
        // Trip just ended
        isTripActive = false;
        final tripEndTime = DateTime.now();

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
              'survey:${tripStartTime?.toIso8601String() ?? tripEndTime.toIso8601String()},${tripEndTime.toIso8601String()}',
        );
        tripStartTime = null;
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
