import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Emits notification payloads when user taps a notification (warm start).
  static final StreamController<String> onNotificationTap =
      StreamController<String>.broadcast();

  /// Stores payload if the app was launched by tapping a notification (cold start).
  static String? initialPayload;

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Check if app was launched from a notification tap
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      final payload = launchDetails!.notificationResponse?.payload;
      if (payload != null && payload.startsWith('survey:')) {
        initialPayload = payload;
      }
    }

    // Pre-create notification channels
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'travel_tracker_bg',
          'Travel Tracker Background',
          description: 'Foreground service notification for trip monitoring',
          importance: Importance.low,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'trip_detection_channel',
          'Trip Detection',
          description: 'Notifications when a trip is detected',
          importance: Importance.high,
        ),
      );
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.startsWith('survey:')) {
      onNotificationTap.add(payload);
    }
  }
}
