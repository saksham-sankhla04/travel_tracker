import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/services/notification_service.dart';
import 'core/services/background_location_service.dart';
import 'core/router/app_router.dart';
import 'features/trip_survey/data/services/survey_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  await BackgroundLocationService.initialize();

  final initialPayload = NotificationService.initialPayload;

  runApp(
    ProviderScope(child: TravelTrackerApp(initialPayload: initialPayload)),
  );
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

  Future<void> _navigateFromPayload(String payload) async {
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

    // Read route points from pending trip in SharedPreferences
    final pending = await SurveyStorageService.getPendingTrip();
    List<Map<String, double>>? routePoints;
    if (pending != null) {
      final rawPoints = pending['routePoints'] as List<dynamic>?;
      routePoints = rawPoints
          ?.map(
            (p) => {
              'lat': (p['lat'] as num).toDouble(),
              'lng': (p['lng'] as num).toDouble(),
            },
          )
          .toList();
    }

    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    appRouter.go('/survey?$query', extra: {'routePoints': routePoints});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Travel Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F7F9),
        cardTheme: const CardThemeData(
          margin: EdgeInsets.zero,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      routerConfig: appRouter,
    );
  }
}
