import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://travel-tracker-8li7.onrender.com';

  static Future<bool> submitTrip(Map<String, dynamic> tripData) async {
    try {
      if (kDebugMode) {
        debugPrint('[ApiService] POST $baseUrl/api/trips');
        debugPrint('[ApiService] Body: ${jsonEncode(tripData)}');
      }
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/trips'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(tripData),
          )
          .timeout(const Duration(seconds: 10));
      if (kDebugMode) {
        debugPrint(
          '[ApiService] Response: ${response.statusCode} ${response.body}',
        );
      }
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ApiService] ERROR: $e');
      }
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getTrips() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/trips'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
