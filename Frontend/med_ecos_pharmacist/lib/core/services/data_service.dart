import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/patient_model.dart';
import '../models/prescription_model.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  final String baseUrl = 'http://localhost:5000/api/v1/doctor';

  List<Patient> _patients = [];
  List<Prescription> _prescriptions = [];

  List<Patient> get patients => List.unmodifiable(_patients);
  List<Prescription> get prescriptions => List.unmodifiable(_prescriptions);

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('pharmacist_jwt_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> loadData() async {
    try {
      final headers = await _getHeaders();
      
      // Fetch Patients
      final pRes = await http.get(Uri.parse('$baseUrl/patients'), headers: headers);
      if (pRes.statusCode == 200) {
        final List<dynamic> pData = jsonDecode(pRes.body);
        _patients = pData.map((e) => Patient(
          id: e['id'] ?? e['_id'],
          name: e['name'] ?? e['username'] ?? 'Unknown',
          age: e['age'] ?? 0,
          gender: e['gender'] ?? 'Unknown',
          contact: e['contact'] ?? 'N/A'
        )).toList();
      }

      // Fetch Prescriptions
      final rxRes = await http.get(Uri.parse('$baseUrl/prescriptions'), headers: headers);
      if (rxRes.statusCode == 200) {
        final List<dynamic> rxData = jsonDecode(rxRes.body);
        _prescriptions = rxData.map((e) => Prescription(
          id: e['id'] ?? e['_id'],
          patientId: e['patientId'] ?? '',
          patientName: e['patientName'] ?? '',
          pharmacistName: e['doctorName'] ?? '',
          date: DateTime.parse(e['date'] ?? DateTime.now().toIso8601String()),
          diagnosis: e['diagnosis'] ?? '',
          medicines: (e['medicines'] as List<dynamic>?)?.map((m) => <String, String>{
            'name': m['name']?.toString() ?? '',
            'dosage': m['dosage']?.toString() ?? '',
            'frequency': m['frequency']?.toString() ?? '',
            'duration': m['duration']?.toString() ?? '',
          }).toList() ?? <Map<String, String>>[],
          labTests: (e['labTests'] as List<dynamic>?)?.map((l) => l.toString()).toList() ?? <String>[],
        )).toList();
      }
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  Future<void> addPrescription(Prescription prescription) async {
    try {
      final headers = await _getHeaders();
      final body = jsonEncode({
        'patientId': prescription.patientId,
        'patientName': prescription.patientName,
        'pharmacistName': prescription.pharmacistName,
        'date': prescription.date.toIso8601String(),
        'diagnosis': prescription.diagnosis,
        'medicines': prescription.medicines,
        'labTests': prescription.labTests,
      });

      final res = await http.post(
        Uri.parse('$baseUrl/prescriptions'),
        headers: headers,
        body: body,
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        // If successful, reload data
        await loadData();
      }
    } catch (e) {
      print('Error adding prescription: $e');
      // Optimistic update fallback
      _prescriptions.add(prescription);
    }
  }

  void addPatient(Patient patient) {
    _patients.add(patient);
  }

  List<Patient> searchPatients(String query) {
    if (query.isEmpty) return _patients;
    final lowerQuery = query.toLowerCase();
    return _patients.where((p) => 
      p.name.toLowerCase().contains(lowerQuery) || 
      p.id.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  List<Prescription> searchPrescriptions(String query) {
    if (query.isEmpty) return _prescriptions;
    final lowerQuery = query.toLowerCase();
    return _prescriptions.where((p) => 
      p.id.toLowerCase().contains(lowerQuery) || 
      p.patientName.toLowerCase().contains(lowerQuery) ||
      p.date.toString().contains(query)
    ).toList();
  }

  List<Prescription> getPrescriptionsForPatient(String patientId) {
    final patientPrescriptions = _prescriptions.where((p) => p.patientId == patientId).toList();
    patientPrescriptions.sort((a, b) => b.date.compareTo(a.date)); // Descending order
    return patientPrescriptions;
  }
  
  Patient? getPatientById(String id) {
    try {
      return _patients.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }
}
