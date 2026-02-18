import 'package:flutter/material.dart';

class LiveDataCard extends StatelessWidget {
  final double currentSpeed;
  final bool isTripActive;

  const LiveDataCard({
    super.key,
    required this.currentSpeed,
    required this.isTripActive,
  });

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
          ],
        ),
      ),
    );
  }
}
