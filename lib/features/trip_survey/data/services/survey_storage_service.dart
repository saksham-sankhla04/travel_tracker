import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trip_survey_model.dart';

class SurveyStorageService {
  static const String _storageKey = 'completed_surveys';
  static const String _tripRecordsKey = 'trip_records';

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
        .map(
          (s) =>
              TripSurveyModel.fromJson(jsonDecode(s) as Map<String, dynamic>),
        )
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

  // --- Pending trip (written by background service, read by foreground) ---

  static const String _pendingTripKey = 'pending_trip';

  /// Save pending trip data so the app can show the survey on next open.
  static Future<void> savePendingTrip({
    required String startTime,
    required String endTime,
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    List<Map<String, double>>? routePoints,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _pendingTripKey,
      jsonEncode({
        'startTime': startTime,
        'endTime': endTime,
        'startLat': startLat,
        'startLng': startLng,
        'endLat': endLat,
        'endLng': endLng,
        'routePoints': routePoints,
      }),
    );
  }

  /// Returns pending trip data if available, or null.
  static Future<Map<String, dynamic>?> getPendingTrip() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingTripKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  /// Clear pending trip (call after survey is submitted).
  static Future<void> clearPendingTrip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingTripKey);
  }

  /// Returns all ended trips captured from tracking, including ones without survey.
  static Future<List<Map<String, dynamic>>> getTripRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_tripRecordsKey) ?? [];
    return stored.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
  }

  /// Returns trip logs that have not reached backend yet.
  static Future<List<Map<String, dynamic>>> getUnsyncedTripRecords() async {
    final all = await getTripRecords();
    return all.where((r) => r['isSynced'] != true).toList();
  }

  /// Marks a raw tracked trip as synced.
  static Future<void> markTripRecordSynced(String tripId) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_tripRecordsKey) ?? [];
    final updated = stored.map((s) {
      final json = jsonDecode(s) as Map<String, dynamic>;
      if (json['id'] == tripId) {
        json['isSynced'] = true;
      }
      return jsonEncode(json);
    }).toList();
    await prefs.setStringList(_tripRecordsKey, updated);
  }

  /// Marks a tracked trip as survey-submitted using start/end timestamps.
  static Future<void> markTripRecordSurveySubmitted({
    required String startTime,
    required String endTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_tripRecordsKey) ?? [];
    final updated = stored.map((s) {
      final json = jsonDecode(s) as Map<String, dynamic>;
      if (json['startTime'] == startTime && json['endTime'] == endTime) {
        json['surveySubmitted'] = true;
      }
      return jsonEncode(json);
    }).toList();
    await prefs.setStringList(_tripRecordsKey, updated);
  }
}
