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
    // Format: startTime,endTime,startLat,startLng,endLat,endLng
    final parts = data.split(',');

    final params = <String, String>{};
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      params['startTime'] = parts[0];
    }
    if (parts.length > 1 && parts[1].isNotEmpty) {
      params['endTime'] = parts[1];
    }
    if (parts.length > 2 && parts[2].isNotEmpty) {
      params['startLat'] = parts[2];
    }
    if (parts.length > 3 && parts[3].isNotEmpty) {
      params['startLng'] = parts[3];
    }
    if (parts.length > 4 && parts[4].isNotEmpty) {
      params['endLat'] = parts[4];
    }
    if (parts.length > 5 && parts[5].isNotEmpty) {
      params['endLng'] = parts[5];
    }

    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    appRouter.go('/survey?$query');
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
