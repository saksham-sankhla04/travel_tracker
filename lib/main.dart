import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/services/notification_service.dart';
import 'core/services/background_location_service.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  await BackgroundLocationService.initialize();

  final initialPayload = NotificationService.initialPayload;

  runApp(ProviderScope(
    child: TravelTrackerApp(initialPayload: initialPayload),
  ));
}

class TravelTrackerApp extends StatefulWidget {
  final String? initialPayload;
  const TravelTrackerApp({super.key, this.initialPayload});

  @override
  State<TravelTrackerApp> createState() => _TravelTrackerAppState();
}

class _TravelTrackerAppState extends State<TravelTrackerApp> {
  @override
  void initState() {
    super.initState();

    // Cold start: app launched by tapping a notification
    if (widget.initialPayload != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateFromPayload(widget.initialPayload!);
      });
    }

    // Warm start: notification tapped while app is running
    NotificationService.onNotificationTap.stream.listen((payload) {
      _navigateFromPayload(payload);
    });
  }

  void _navigateFromPayload(String payload) {
    if (!payload.startsWith('survey:')) return;
    final data = payload.substring('survey:'.length);
    final parts = data.split(',');
    final startTime = parts[0];
    final endTime = parts.length > 1 ? parts[1] : null;

    var uri = '/survey?startTime=$startTime';
    if (endTime != null) {
      uri += '&endTime=$endTime';
    }
    appRouter.go(uri);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Travel Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
