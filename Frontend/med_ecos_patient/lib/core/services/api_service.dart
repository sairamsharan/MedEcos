import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String baseUrl = 'http://localhost:5000/api/v1/patient';

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('patient_jwt_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<dynamic>> getPrescriptions() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/prescriptions'), headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['records'] as List<dynamic>;
      } else {
        throw Exception('Failed to load prescriptions: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> logMedicineHistory(String medicineId, String medicineName, DateTime takenTime, String status) async {
    try {
      final headers = await _getHeaders();
      final body = jsonEncode({
        'medicineId': medicineId,
        'medicineName': medicineName,
        'takenTime': takenTime.toIso8601String(),
        'status': status,
      });
      final response = await http.post(
        Uri.parse('$baseUrl/history'),
        headers: headers,
        body: body,
      );
      if (response.statusCode != 201) {
        throw Exception('Failed to log history: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<dynamic>> getMedicineHistory() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/history'), headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else {
        throw Exception('Failed to get history: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<dynamic>> getPatientLabOrders() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/lab-test-orders'), headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else {
        throw Exception('Failed to get lab orders: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
