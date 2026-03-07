import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/trip_survey_model.dart';
import '../../data/services/survey_storage_service.dart';
import '../providers/survey_provider.dart';

class TripHistoryPage extends ConsumerStatefulWidget {
  const TripHistoryPage({super.key});

  @override
  ConsumerState<TripHistoryPage> createState() => _TripHistoryPageState();
}

class _TripHistoryPageState extends ConsumerState<TripHistoryPage> {
  bool _isLoadingRecords = true;
  List<Map<String, dynamic>> _tripRecords = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(surveyProvider.notifier).loadSurveys();
      await _loadTripRecords();
    });
  }

  Future<void> _loadTripRecords() async {
    final records = await SurveyStorageService.getTripRecords();
    records.sort(
      (a, b) => DateTime.parse(
        b['endTime'] as String,
      ).compareTo(DateTime.parse(a['endTime'] as String)),
    );
    if (!mounted) return;
    setState(() {
      _tripRecords = records;
      _isLoadingRecords = false;
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
    if (state.isLoading || _isLoadingRecords) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_tripRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.route,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No trips recorded yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tracked trips will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    final surveysByKey = <String, TripSurveyModel>{};
    for (final survey in state.completedSurveys) {
      final key = _tripKey(
        survey.tripStartTime.toIso8601String(),
        survey.tripEndTime.toIso8601String(),
      );
      surveysByKey[key] = survey;
    }

    final recent = _tripRecords.take(30).toList();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recent.length,
      itemBuilder: (context, index) {
        final record = recent[index];
        final key = _tripKey(
          record['startTime'] as String,
          record['endTime'] as String,
        );
        final survey = surveysByKey[key];
        return _TripCard(record: record, survey: survey);
      },
    );
  }

  static String _tripKey(String startTime, String endTime) {
    return '$startTime|$endTime';
  }
}

class _TripCard extends StatelessWidget {
  final Map<String, dynamic> record;
  final TripSurveyModel? survey;

  const _TripCard({required this.record, required this.survey});

  @override
  Widget build(BuildContext context) {
    final startTime = DateTime.parse(record['startTime'] as String);
    final endTime = DateTime.parse(record['endTime'] as String);
    final duration = endTime.difference(startTime);
    final durationStr = _formatDuration(duration);
    final isCompleted = (record['surveySubmitted'] as bool?) == true;
    final isSynced = (record['isSynced'] as bool?) == true;
    final routePoints = (record['routePoints'] as List<dynamic>?) ?? [];

    final transport = survey != null
        ? _capitalize(survey!.modeOfTransport)
        : 'Unknown';
    final purpose = survey != null
        ? _capitalize(survey!.tripPurpose)
        : 'Unknown';
    final passengers = survey != null ? '${survey!.numberOfPassengers}' : '0';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _formatDate(startTime),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(width: 8),
                _statusChip(context, isCompleted: isCompleted),
                const Spacer(),
                Icon(
                  isSynced ? Icons.cloud_done : Icons.cloud_off,
                  size: 18,
                  color: isSynced ? Colors.green : Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(startTime),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const Divider(height: 20),
            _detailRow(
              context,
              icon: _transportIcon(survey?.modeOfTransport),
              label: 'Transport',
              value: transport,
            ),
            const SizedBox(height: 8),
            _detailRow(
              context,
              icon: _purposeIcon(survey?.tripPurpose),
              label: 'Purpose',
              value: purpose,
            ),
            const SizedBox(height: 8),
            _detailRow(
              context,
              icon: Icons.timer_outlined,
              label: 'Duration',
              value: durationStr,
            ),
            const SizedBox(height: 8),
            _detailRow(
              context,
              icon: Icons.people_outline,
              label: 'Passengers',
              value: passengers,
            ),
            const SizedBox(height: 8),
            _detailRow(
              context,
              icon: Icons.alt_route,
              label: 'Route points',
              value: '${routePoints.length}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _statusChip(BuildContext context, {required bool isCompleted}) {
    final color = isCompleted ? Colors.green : Colors.orange;
    final label = isCompleted ? 'Completed' : 'Auto-saved';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static IconData _transportIcon(String? mode) {
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

  static IconData _purposeIcon(String? purpose) {
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

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  static String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    return '${d.inMinutes}m';
  }

  static String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
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
