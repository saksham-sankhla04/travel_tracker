import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/trip_survey_model.dart';
import '../../data/services/survey_storage_service.dart';

class SurveyState {
  final List<TripSurveyModel> completedSurveys;
  final bool isLoading;

  const SurveyState({
    this.completedSurveys = const [],
    this.isLoading = false,
  });

  SurveyState copyWith({
    List<TripSurveyModel>? completedSurveys,
    bool? isLoading,
  }) {
    return SurveyState(
      completedSurveys: completedSurveys ?? this.completedSurveys,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SurveyNotifier extends StateNotifier<SurveyState> {
  SurveyNotifier() : super(const SurveyState());

  Future<void> loadSurveys() async {
    state = state.copyWith(isLoading: true);
    final surveys = await SurveyStorageService.getAllSurveys();
    state = state.copyWith(completedSurveys: surveys, isLoading: false);
  }

  Future<void> submitSurvey(TripSurveyModel survey) async {
    await SurveyStorageService.saveSurvey(survey);
    await loadSurveys();
  }
}

final surveyProvider = StateNotifierProvider<SurveyNotifier, SurveyState>(
  (ref) => SurveyNotifier(),
);
