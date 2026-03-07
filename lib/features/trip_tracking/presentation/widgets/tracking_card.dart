import 'package:flutter/material.dart';

class TrackingCard extends StatelessWidget {
  final bool serviceRunning;
  final bool permissionsGranted;
  final VoidCallback onToggleService;

  const TrackingCard({
    super.key,
    required this.serviceRunning,
    required this.permissionsGranted,
    required this.onToggleService,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trip Tracking',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: serviceRunning
                    ? Colors.green.withValues(alpha: 0.08)
                    : colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    serviceRunning
                        ? Icons.radio_button_checked
                        : Icons.pause_circle_outline,
                    color: serviceRunning ? Colors.green : colorScheme.outline,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      serviceRunning
                          ? 'Tracking is active'
                          : 'Tracking is stopped',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: permissionsGranted ? onToggleService : null,
                icon: Icon(serviceRunning ? Icons.stop : Icons.play_arrow),
                label: Text(
                  serviceRunning ? 'Stop Tracking' : 'Start Tracking',
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (!permissionsGranted)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Complete onboarding permissions to start tracking.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
