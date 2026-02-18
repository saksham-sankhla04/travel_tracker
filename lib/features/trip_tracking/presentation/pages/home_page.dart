import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/permission_service.dart';
import '../providers/trip_tracking_provider.dart';
import '../widgets/permission_card.dart';
import '../widgets/tracking_card.dart';
import '../widgets/live_data_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          ],
        ),
      ),
    );
  }
}
