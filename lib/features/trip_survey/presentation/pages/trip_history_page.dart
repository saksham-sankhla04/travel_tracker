import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/trip_survey_model.dart';
import '../providers/survey_provider.dart';

class TripHistoryPage extends ConsumerStatefulWidget {
  const TripHistoryPage({super.key});

  @override
  ConsumerState<TripHistoryPage> createState() => _TripHistoryPageState();
}

class _TripHistoryPageState extends ConsumerState<TripHistoryPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(surveyProvider.notifier).loadSurveys();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(surveyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip History'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, SurveyState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.completedSurveys.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.route, size: 64,
                color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'No trips recorded yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Completed trip surveys will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      );
    }

    final sorted = List<TripSurveyModel>.from(state.completedSurveys)
      ..sort((a, b) => b.tripEndTime.compareTo(a.tripEndTime));
    final recent = sorted.take(15).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recent.length,
      itemBuilder: (context, index) => _TripCard(trip: recent[index]),
    );
  }
}

class _TripCard extends StatelessWidget {
  final TripSurveyModel trip;
  const _TripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final duration = trip.tripEndTime.difference(trip.tripStartTime);
    final dateStr = _formatDate(trip.tripStartTime);
    final timeStr = _formatTime(trip.tripStartTime);
    final durationStr = _formatDuration(duration);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dateStr,
                    style: Theme.of(context).textTheme.titleSmall),
                Icon(
                  trip.isSynced ? Icons.cloud_done : Icons.cloud_off,
                  size: 18,
                  color: trip.isSynced ? Colors.green : Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const Divider(height: 20),
            _detailRow(context,
                icon: _transportIcon(trip.modeOfTransport),
                label: 'Transport',
                value: _capitalize(trip.modeOfTransport)),
            const SizedBox(height: 8),
            _detailRow(context,
                icon: _purposeIcon(trip.tripPurpose),
                label: 'Purpose',
                value: _capitalize(trip.tripPurpose)),
            const SizedBox(height: 8),
            _detailRow(context,
                icon: Icons.timer_outlined,
                label: 'Duration',
                value: durationStr),
            const SizedBox(height: 8),
            _detailRow(context,
                icon: Icons.people_outline,
                label: 'Passengers',
                value: '${trip.numberOfPassengers}'),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(BuildContext context,
      {required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        Text(value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
      ],
    );
  }

  static IconData _transportIcon(String mode) {
    switch (mode) {
      case 'bus':
        return Icons.directions_bus;
      case 'car':
        return Icons.directions_car;
      case 'bike':
        return Icons.two_wheeler;
      case 'auto':
        return Icons.electric_rickshaw;
      case 'train':
        return Icons.train;
      case 'walk':
        return Icons.directions_walk;
      default:
        return Icons.directions;
    }
  }

  static IconData _purposeIcon(String purpose) {
    switch (purpose) {
      case 'work':
        return Icons.work_outline;
      case 'education':
        return Icons.school_outlined;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'leisure':
        return Icons.park_outlined;
      case 'other':
        return Icons.more_horiz;
      default:
        return Icons.flag_outlined;
    }
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  static String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    return '${d.inMinutes}m';
  }

  static String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  static String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}
