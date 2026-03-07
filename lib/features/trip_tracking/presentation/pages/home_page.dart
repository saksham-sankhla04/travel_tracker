import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../onboarding/data/services/onboarding_storage_service.dart';
import '../../../trip_survey/data/services/survey_storage_service.dart';
import '../../../trip_survey/presentation/providers/survey_provider.dart';
import '../providers/trip_tracking_provider.dart';
import '../widgets/tracking_card.dart';
import '../widgets/live_data_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  Future<void> _refreshPermissions() async {
    await ref.read(tripTrackingProvider.notifier).checkPermissions();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      // First-time users must complete onboarding.
      final hasCompletedOnboarding =
          await OnboardingStorageService.hasCompletedOnboarding();
      if (!hasCompletedOnboarding && mounted) {
        appRouter.go('/onboarding');
        return;
      }

      // Permissions may have been granted during onboarding; refresh provider state.
      await _refreshPermissions();

      // Sync any locally-saved surveys that haven't reached MongoDB yet
      final count = await ref
          .read(surveyProvider.notifier)
          .syncPendingSurveys();
      if (count > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Synced $count pending survey(s) to server.')),
        );
      }

      // Sync ended trip logs that were auto-submitted with default fields.
      final tripRecordsSynced = await ref
          .read(surveyProvider.notifier)
          .syncPendingTripRecords();
      if (tripRecordsSynced > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Synced $tripRecordsSynced pending trip record(s) to server.',
            ),
          ),
        );
      }

      // Check if there's a pending trip that needs a survey
      if (!mounted) return;
      final pending = await SurveyStorageService.getPendingTrip();
      if (pending != null && mounted) {
        final startTime = pending['startTime'] as String;
        final endTime = pending['endTime'] as String;
        final startLat = pending['startLat'];
        final startLng = pending['startLng'];
        final endLat = pending['endLat'];
        final endLng = pending['endLng'];
        // Parse route points from pending trip
        final rawPoints = pending['routePoints'] as List<dynamic>?;
        final routePoints = rawPoints
            ?.map(
              (p) => {
                'lat': (p['lat'] as num).toDouble(),
                'lng': (p['lng'] as num).toDouble(),
              },
            )
            .toList();
        final query =
            'startTime=$startTime&endTime=$endTime'
            '&startLat=$startLat&startLng=$startLng'
            '&endLat=$endLat&endLng=$endLng';
        appRouter.go('/survey?$query', extra: {'routePoints': routePoints});
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Also refresh when this page becomes active again.
    _refreshPermissions();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tripTrackingProvider);
    final notifier = ref.read(tripTrackingProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Tracker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TrackingCard(
              serviceRunning: state.serviceRunning,
              permissionsGranted: state.permissionsGranted,
              onToggleService: notifier.toggleService,
            ),
            const SizedBox(height: 16),
            if (state.serviceRunning)
              LiveDataCard(
                currentSpeed: state.currentSpeed,
                isTripActive: state.isTripActive,
                gpsAccuracy: state.gpsAccuracy,
                isCoolingDown: state.isCoolingDown,
                cooldownProgress: state.cooldownProgress,
                onManualStopTrip: notifier.endCurrentTripManually,
              ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () => context.push('/history'),
              icon: const Icon(Icons.history),
              label: const Text('Trip History'),
            ),
            const SizedBox(height: 16),
            // Debug: simulate a trip for testing
            OutlinedButton.icon(
              onPressed: () => _simulateTrip(context),
              icon: const Icon(Icons.bug_report),
              label: const Text('Simulate Trip (Debug)'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _simulateTrip(BuildContext context) async {
    final plugin = FlutterLocalNotificationsPlugin();
    final tripStart = DateTime.now();
    // Simulated start location (Jodhpur)
    const startLat = 26.2389;
    const startLng = 73.0243;

    // Fire informational "Trip Detected" notification (no survey payload)
    await plugin.show(
      0,
      'Trip Detected',
      'Simulated trip at 15 km/h. We\'ll ask for details when you stop.',
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

    // After 5 seconds, fire "Trip Ended" notification
    await Future.delayed(const Duration(seconds: 5));
    final tripEnd = DateTime.now();
    // Simulated end location (Jaipur)
    const endLat = 26.9124;
    const endLng = 75.7873;
    await plugin.show(
      1,
      'Trip Ended',
      'Simulated trip ended. Tap to complete the survey.',
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
          'survey:${tripStart.toIso8601String()},${tripEnd.toIso8601String()},$startLat,$startLng,$endLat,$endLng',
    );

    // Persist pending trip so the survey shows even if user opens app directly
    await SurveyStorageService.savePendingTrip(
      startTime: tripStart.toIso8601String(),
      endTime: tripEnd.toIso8601String(),
      startLat: startLat,
      startLng: startLng,
      endLat: endLat,
      endLng: endLng,
    );
  }
}
