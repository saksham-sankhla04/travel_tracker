import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/trip_survey_model.dart';
import '../../data/services/survey_storage_service.dart';

class SurveyPage extends ConsumerStatefulWidget {
  final String? tripStartTime;
  final String? tripEndTime;

  const SurveyPage({
    super.key,
    this.tripStartTime,
    this.tripEndTime,
  });

  @override
  ConsumerState<SurveyPage> createState() => _SurveyPageState();
}

class _SurveyPageState extends ConsumerState<SurveyPage> {
  final _formKey = GlobalKey<FormState>();

  String _tripPurpose = 'work';
  String _modeOfTransport = 'bus';
  int _numberOfPassengers = 1;

  static const tripPurposeOptions = [
    'work',
    'education',
    'shopping',
    'leisure',
    'other',
  ];
  static const transportModeOptions = [
    'bus',
    'car',
    'bike',
    'auto',
    'train',
    'walk',
  ];

  Future<void> _submitSurvey() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final survey = TripSurveyModel(
      id: now.millisecondsSinceEpoch.toString(),
      tripStartTime: widget.tripStartTime != null
          ? DateTime.parse(widget.tripStartTime!)
          : now,
      tripEndTime: widget.tripEndTime != null
          ? DateTime.parse(widget.tripEndTime!)
          : now,
      tripPurpose: _tripPurpose,
      modeOfTransport: _modeOfTransport,
      numberOfPassengers: _numberOfPassengers,
      surveyCompletedAt: now,
    );

    await SurveyStorageService.saveSurvey(survey);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Survey submitted. Thank you!')),
      );
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Survey'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'Tell us about your trip',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),

              // Trip Purpose
              DropdownButtonFormField<String>(
                initialValue: _tripPurpose,
                decoration: const InputDecoration(
                  labelText: 'Trip Purpose',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
                ),
                items: tripPurposeOptions
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e[0].toUpperCase() + e.substring(1)),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _tripPurpose = val!),
              ),
              const SizedBox(height: 16),

              // Mode of Transport
              DropdownButtonFormField<String>(
                initialValue: _modeOfTransport,
                decoration: const InputDecoration(
                  labelText: 'Mode of Transport',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.directions),
                ),
                items: transportModeOptions
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e[0].toUpperCase() + e.substring(1)),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _modeOfTransport = val!),
              ),
              const SizedBox(height: 16),

              // Number of Passengers
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.people, color: Colors.grey),
                      const SizedBox(width: 12),
                      const Text('Passengers'),
                      const Spacer(),
                      IconButton(
                        onPressed: _numberOfPassengers > 1
                            ? () =>
                                setState(() => _numberOfPassengers--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        '$_numberOfPassengers',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        onPressed: () =>
                            setState(() => _numberOfPassengers++),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Submit
              FilledButton.icon(
                onPressed: _submitSurvey,
                icon: const Icon(Icons.check),
                label: const Text('Submit Survey'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
