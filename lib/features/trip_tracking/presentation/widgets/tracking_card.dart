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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trip Tracking',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  serviceRunning ? Icons.circle : Icons.circle_outlined,
                  color: serviceRunning ? Colors.green : Colors.grey,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(serviceRunning ? 'Service running' : 'Service stopped'),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: permissionsGranted ? onToggleService : null,
              icon: Icon(serviceRunning ? Icons.stop : Icons.play_arrow),
              label: Text(
                  serviceRunning ? 'Stop Tracking' : 'Start Tracking'),
            ),
            if (!permissionsGranted)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Grant all permissions first to start tracking.',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
