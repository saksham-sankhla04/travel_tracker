import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/permission_service.dart';
import '../../../trip_survey/presentation/providers/survey_provider.dart';
import '../providers/trip_tracking_provider.dart';
import '../widgets/permission_card.dart';
import '../widgets/tracking_card.dart';
import '../widgets/live_data_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    // Sync any locally-saved surveys that haven't reached MongoDB yet
    Future.microtask(() async {
      final count =
          await ref.read(surveyProvider.notifier).syncPendingSurveys();
      if (count > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Synced $count pending survey(s) to server.')),
        );
      }
    });
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
            PermissionCard(
              permissionStatus: state.permissionStatus,
              permissionsGranted: state.permissionsGranted,
              onRequestPermissions: notifier.requestPermissions,
              onOpenSettings: PermissionService.openSettings,
            ),
            const SizedBox(height: 16),
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
    // Simulated start location (Thiruvananthapuram)
    const startLat = 8.5241;
    const startLng = 76.9366;

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
    // Simulated end location (Kochi)
    const endLat = 9.9312;
    const endLng = 76.2673;
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
  }
}
