import 'package:flutter/material.dart';

class LiveDataCard extends StatelessWidget {
  final double currentSpeed;
  final bool isTripActive;
  final double gpsAccuracy;
  final bool isCoolingDown;
  final double cooldownProgress;
  final VoidCallback? onManualStopTrip;

  const LiveDataCard({
    super.key,
    required this.currentSpeed,
    required this.isTripActive,
    this.gpsAccuracy = 0.0,
    this.isCoolingDown = false,
    this.cooldownProgress = 0.0,
    this.onManualStopTrip,
  });

  Color _accuracyColor() {
    if (gpsAccuracy < 10) return Colors.green;
    if (gpsAccuracy < 30) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Live Data', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currentSpeed.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: isTripActive ? Colors.green : colorScheme.outline,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'km/h',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _metricChip(
                  context,
                  icon: isTripActive
                      ? Icons.directions_run
                      : Icons.pause_circle_outline,
                  label: isTripActive ? 'Trip in progress' : 'No trip detected',
                  color: isTripActive ? Colors.green : colorScheme.outline,
                ),
                _metricChip(
                  context,
                  icon: gpsAccuracy < 10
                      ? Icons.gps_fixed
                      : Icons.gps_not_fixed,
                  label: 'GPS ${gpsAccuracy.toStringAsFixed(0)}m',
                  color: _accuracyColor(),
                ),
              ],
            ),
            if (isCoolingDown) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: cooldownProgress,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 4),
              Text(
                'Checking if trip ended... ${(cooldownProgress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ],
            if (isTripActive) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onManualStopTrip,
                icon: const Icon(Icons.flag_outlined),
                label: const Text('End Trip Manually'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metricChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
