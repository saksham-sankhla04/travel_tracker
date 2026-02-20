import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trip_survey_model.dart';

class SurveyStorageService {
  static const String _storageKey = 'completed_surveys';

  static Future<void> saveSurvey(TripSurveyModel survey) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_storageKey) ?? [];
    existing.add(jsonEncode(survey.toJson()));
    await prefs.setStringList(_storageKey, existing);
  }

  static Future<List<TripSurveyModel>> getAllSurveys() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_storageKey) ?? [];
    return stored
        .map((s) =>
            TripSurveyModel.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  static Future<List<TripSurveyModel>> getUnsyncedSurveys() async {
    final all = await getAllSurveys();
    return all.where((s) => !s.isSynced).toList();
  }

  /// Marks a survey as synced by its id.
  static Future<void> markAsSynced(String surveyId) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_storageKey) ?? [];
    final updated = stored.map((s) {
      final json = jsonDecode(s) as Map<String, dynamic>;
      if (json['id'] == surveyId) {
        json['isSynced'] = true;
      }
      return jsonEncode(json);
    }).toList();
    await prefs.setStringList(_storageKey, updated);
  }

  /// Clears all locally stored surveys.
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
