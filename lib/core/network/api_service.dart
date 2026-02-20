import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Change this to your server's IP when testing on a physical device.
  static const String baseUrl = 'http://192.168.31.211:3000';

  static Future<bool> submitTrip(Map<String, dynamic> tripData) async {
    try {
      print('[ApiService] POST $baseUrl/api/trips');
      print('[ApiService] Body: ${jsonEncode(tripData)}');
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/trips'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(tripData),
          )
          .timeout(const Duration(seconds: 10));
      print('[ApiService] Response: ${response.statusCode} ${response.body}');
      return response.statusCode == 201;
    } catch (e) {
      print('[ApiService] ERROR: $e');
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
