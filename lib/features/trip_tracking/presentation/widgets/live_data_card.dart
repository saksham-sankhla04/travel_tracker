import 'package:flutter/material.dart';

class LiveDataCard extends StatelessWidget {
  final double currentSpeed;
  final bool isTripActive;
  final double gpsAccuracy;
  final bool isCoolingDown;
  final double cooldownProgress;

  const LiveDataCard({
    super.key,
    required this.currentSpeed,
    required this.isTripActive,
    this.gpsAccuracy = 0.0,
    this.isCoolingDown = false,
    this.cooldownProgress = 0.0,
  });

  Color _accuracyColor() {
    if (gpsAccuracy < 10) return Colors.green;
    if (gpsAccuracy < 30) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Live Data',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(
              '${currentSpeed.toStringAsFixed(1)} km/h',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: isTripActive ? Colors.green : Colors.grey,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              isTripActive ? 'Trip in progress' : 'No trip detected',
              style: TextStyle(
                color: isTripActive ? Colors.green : Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  gpsAccuracy < 10 ? Icons.gps_fixed : Icons.gps_not_fixed,
                  size: 16,
                  color: _accuracyColor(),
                ),
                const SizedBox(width: 4),
                Text(
                  'GPS accuracy: ${gpsAccuracy.toStringAsFixed(0)}m',
                  style: TextStyle(fontSize: 12, color: _accuracyColor()),
                ),
              ],
            ),
            if (isCoolingDown) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: cooldownProgress),
              const SizedBox(height: 4),
              Text(
                'Checking if trip ended... ${(cooldownProgress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
