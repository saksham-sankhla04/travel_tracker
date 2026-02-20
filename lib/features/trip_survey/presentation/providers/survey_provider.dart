import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
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

  /// Saves survey locally, then attempts to sync to MongoDB.
  /// Returns true if synced to backend, false if saved locally only.
  Future<bool> submitSurvey(TripSurveyModel survey) async {
    // 1. Save locally first (offline-safe)
    await SurveyStorageService.saveSurvey(survey);

    // 2. Attempt to send to MongoDB
    final synced = await ApiService.submitTrip(survey.toApiJson());

    // 3. If successful, mark as synced in local storage
    if (synced) {
      await SurveyStorageService.markAsSynced(survey.id);
    }

    await loadSurveys();
    return synced;
  }

  /// Retries sending all unsynced surveys to MongoDB.
  /// Returns the number of surveys successfully synced.
  Future<int> syncPendingSurveys() async {
    final unsynced = await SurveyStorageService.getUnsyncedSurveys();
    if (unsynced.isEmpty) return 0;

    int syncedCount = 0;
    for (final survey in unsynced) {
      final success = await ApiService.submitTrip(survey.toApiJson());
      if (success) {
        await SurveyStorageService.markAsSynced(survey.id);
        syncedCount++;
      } else {
        // Server unreachable — stop trying the rest
        break;
      }
    }

    if (syncedCount > 0) {
      await loadSurveys();
    }
    return syncedCount;
  }

  /// Clears all local survey data.
  Future<void> clearLocalData() async {
    await SurveyStorageService.clearAll();
    state = state.copyWith(completedSurveys: []);
  }
}

final surveyProvider = StateNotifierProvider<SurveyNotifier, SurveyState>(
  (ref) => SurveyNotifier(),
);
