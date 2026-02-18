import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(initSettings);

    // Pre-create the background service notification channel
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
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

  /// Shows a "Trip Detected" notification that nudges the user to log trip details.
  static Future<void> showTripDetectedNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'trip_detection_channel',
      'Trip Detection',
      channelDescription: 'Notifications when a trip is detected',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      0,
      'Trip Detected',
      'It looks like you are travelling. Tap to log your trip details.',
      details,
    );
  }
}
