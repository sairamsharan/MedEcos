import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/patient_model.dart';
import '../models/prescription_model.dart';
import '../models/inventory_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<String> get _baseUrl async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role') ?? 'Patient';
    return 'http://localhost:5000/api/v1/${role.toLowerCase()}';
  }

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Generic Data Loading (Previously in ApiService)
  List<Patient> _patients = [];
  List<Prescription> _prescriptions = [];

  List<Patient> get patients => List.unmodifiable(_patients);
  List<Prescription> get prescriptions => List.unmodifiable(_prescriptions);

  Future<void> loadData() async {
    try {
      final headers = await _getHeaders();
      final baseUrl = await _baseUrl;

      // Only Doctor and Pharmacist have /patients endpoints directly in the current backend
      final role = (await SharedPreferences.getInstance()).getString('user_role') ?? 'Patient';
      if (role == 'Doctor' || role == 'Pharmacist') {
        try {
          final patRes = await http.get(Uri.parse('$baseUrl/patients'), headers: headers);
          if (patRes.statusCode == 200) {
            final List<dynamic> patData = jsonDecode(patRes.body);
            _patients = patData.map((e) => Patient(
              id: e['abhaId'] ?? e['_id'],
              name: e['username'] ?? 'Unknown',
              age: e['age'] ?? 0,
              gender: e['gender'] ?? 'Unknown',
              contact: e['contact'] ?? 'N/A'
            )).toList();
          }
        } catch (e) {
          print("Error fetching patients: $e");
        }
      }

      // Fetch Prescriptions (Works for Doctor and Patient, Pharmacist doesn't have it directly but maybe later)
      try {
        final rxRes = await http.get(Uri.parse('$baseUrl/prescriptions'), headers: headers);
        if (rxRes.statusCode == 200) {
          final dynamic data = jsonDecode(rxRes.body);
          List<dynamic> rxData;
          if (data is Map && data.containsKey('records')) {
            rxData = data['records']; // Patient route format
          } else {
            rxData = data; // Doctor route format
          }
          
          _prescriptions = rxData.map((e) => Prescription(
            id: e['id'] ?? e['_id'] ?? e['prescriptionId'] ?? '',
            patientId: e['patientId'] ?? e['abhaId'] ?? '',
            patientName: e['patientName'] ?? '',
            doctorName: e['doctorName'] ?? '',
            date: DateTime.parse(e['date'] ?? DateTime.now().toIso8601String()),
            diagnosis: e['diagnosis'] ?? '',
            medicines: (e['fullMedicines'] as List<dynamic>? ?? e['medicines'] as List<dynamic>?)?.map((m) {
              if (m is Map) {
                return <String, String>{
                  'name': m['name']?.toString() ?? '',
                  'dosage': m['dosage']?.toString() ?? '',
                  'frequency': m['frequency']?.toString() ?? '',
                  'duration': m['duration']?.toString() ?? '',
                  'timing': m['timing']?.toString() ?? '',
                  'context': m['context']?.toString() ?? '',
                  'instruction': m['instruction']?.toString() ?? '',
                };
              }
              return <String, String>{'name': m.toString()};
            }).toList() ?? <Map<String, String>>[],
            labTests: (e['labTests'] as List<dynamic>?)?.map((l) => l.toString()).toList() ?? <String>[],
            status: e['status'] ?? 'Active',
            doctorNotes: e['doctorNotes'],
            pharmacistNotes: e['pharmacistNotes'],
          )).toList();
        }
      } catch (e) {
        print("Error fetching prescriptions: $e");
      }
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  // Dashboard Stats
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final headers = await _getHeaders();
      final baseUrl = await _baseUrl;
      final response = await http.get(Uri.parse('$baseUrl/dashboard-stats'), headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load stats: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Prescriptions List
  Future<List<dynamic>> getPrescriptions() async {
    await loadData();
    // Return dynamically for older patient screen compatibility
    return _prescriptions.map((p) => {
      'prescriptionId': p.id,
      'doctorName': p.doctorName,
      'date': p.date.toIso8601String(),
      'diagnosis': p.diagnosis,
      'medicines': p.medicines,
    }).toList();
  }

  // Doctor/Pharmacist Prescription Management
  Future<void> addPrescription(Prescription prescription) async {
    try {
      final headers = await _getHeaders();
      final baseUrl = await _baseUrl;
      final body = jsonEncode({
        'abhaId': prescription.patientId, // Backend expects abhaId for Doctor
        'patientName': prescription.patientName,
        'doctorName': prescription.doctorName,
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
        await loadData();
      } else {
         throw Exception('Failed: ${res.body}');
      }
    } catch (e) {
      print('Error adding prescription: $e');
      _prescriptions.add(prescription);
    }
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

  Future<List<Prescription>> fetchAllPrescriptionsForPatient(String patientId) async {
    try {
      final headers = await _getHeaders();
      final baseUrl = await _baseUrl;
      final response = await http.get(Uri.parse('$baseUrl/prescriptions/$patientId'), headers: headers);
      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        List<dynamic> rxData;
        if (data is Map && data.containsKey('records')) {
          rxData = data['records'];
        } else {
          rxData = data;
        }
        return rxData.map((e) => Prescription(
          id: e['id'] ?? e['_id'] ?? e['prescriptionId'] ?? '',
          patientId: e['patientId'] ?? e['abhaId'] ?? '',
          patientName: e['patientName'] ?? '',
          doctorName: e['doctorName'] ?? '',
          date: DateTime.parse(e['date'] ?? DateTime.now().toIso8601String()),
          diagnosis: e['diagnosis'] ?? '',
          medicines: (e['fullMedicines'] as List<dynamic>? ?? e['medicines'] as List<dynamic>?)?.map((m) {
            if (m is Map) {
              return <String, String>{
                'name': m['name']?.toString() ?? '',
                'dosage': m['dosage']?.toString() ?? '',
                'frequency': m['frequency']?.toString() ?? '',
                'duration': m['duration']?.toString() ?? '',
                'timing': m['timing']?.toString() ?? '',
                'context': m['context']?.toString() ?? '',
                'instruction': m['instruction']?.toString() ?? '',
              };
            }
            return <String, String>{'name': m.toString()};
          }).toList() ?? <Map<String, String>>[],
          labTests: (e['labTests'] as List<dynamic>?)?.map((l) => l.toString()).toList() ?? <String>[],
          status: e['status'] ?? 'Active',
          doctorNotes: e['doctorNotes'],
          pharmacistNotes: e['pharmacistNotes'],
        )).toList();
      }
    } catch (e) {
      print('Error fetching patient prescriptions from server: $e');
    }
    // Fallback to local
    return getPrescriptionsForPatient(patientId);
  }

  // Patients Management
  List<Patient> searchPatients(String query) {
    if (query.isEmpty) return _patients;
    final lowerQuery = query.toLowerCase();
    return _patients.where((p) => 
      p.name.toLowerCase().contains(lowerQuery) || 
      p.id.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  Patient? getPatientById(String id) {
    try {
      return _patients.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  // ABHA Integration (Doctor flow)
  Future<Patient> registerPatientViaAbha(String abhaId) async {
    final headers = await _getHeaders();
    final baseUrl = await _baseUrl;
    
    // Call the abha-register endpoint directly with mock transaction and OTP
    final response = await http.post(
      Uri.parse('$baseUrl/patients/abha-register'),
      headers: headers,
      body: jsonEncode({
        'abhaId': abhaId,
        'transactionId': 'txn-mock',
        'otp': '123456'
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final patient = Patient(
        id: data['abhaId'] ?? data['_id'],
        name: data['username'] ?? 'Unknown',
        age: data['age'] ?? 0,
        gender: data['gender'] ?? 'Unknown',
        contact: data['contact'] ?? 'N/A'
      );
      _patients.add(patient);
      return patient;
    } else {
      throw Exception('Failed to register patient: ${response.body}');
    }
  }
  
  // History
  Future<void> logMedicineHistory(String medicineId, String medicineName, DateTime takenTime, String status) async {
    try {
      final headers = await _getHeaders();
      final baseUrl = await _baseUrl;
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

  // Update Profile Routine
  Future<void> updateRoutine(Map<String, String> routine) async {
    try {
      final headers = await _getHeaders();
      final baseUrl = await _baseUrl;
      final response = await http.put(
        Uri.parse('$baseUrl/profile'),
        headers: headers,
        body: jsonEncode({'routine': routine}),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update routine: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<dynamic>> getMedicineHistory() async {
    try {
      final headers = await _getHeaders();
      final baseUrl = await _baseUrl;
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

  Future<void> updatePrescriptionNotes(String id, String? doctorNotes, String? pharmacistNotes, String? status) async {
    final headers = await _getHeaders();
    final baseUrl = await _baseUrl;
    final role = (await SharedPreferences.getInstance()).getString('user_role') ?? 'Patient';
    
    // Only Doctor or Pharmacist can update notes
    String route = '';
    if (role == 'Doctor') {
      route = 'http://localhost:5000/api/v1/doctor/prescriptions/$id/notes';
    } else if (role == 'Pharmacist') {
      route = 'http://localhost:5000/api/v1/pharmacist/prescriptions/$id/notes';
    } else {
      throw Exception("Unauthorized to update notes");
    }

    final body = <String, dynamic>{};
    if (doctorNotes != null) body['doctorNotes'] = doctorNotes;
    if (pharmacistNotes != null) body['pharmacistNotes'] = pharmacistNotes;
    if (status != null) body['status'] = status;

    final response = await http.put(Uri.parse(route), headers: headers, body: jsonEncode(body));
    if (response.statusCode != 200) {
      throw Exception("Failed to update prescription notes");
    }
  }

  Future<void> finishAppointment(String appointmentId) async {
    try {
      final headers = await _getHeaders();
      final baseUrl = await _baseUrl;
      final response = await http.post(
        Uri.parse('$baseUrl/appointments/$appointmentId/finish'),
        headers: headers,
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to finish appointment: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Inventory API
  Future<List<InventoryItem>> getInventory() async {
    try {
      final headers = await _getHeaders();
      final baseUrl = await _baseUrl;
      final response = await http.get(Uri.parse('$baseUrl/inventory'), headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => InventoryItem.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load inventory');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> addInventoryItem({
    required String medicineName,
    required int quantity,
    required double price,
    DateTime? expiryDate,
  }) async {
    try {
      final headers = await _getHeaders();
      final baseUrl = await _baseUrl;
      final body = <String, dynamic>{
        'medicineName': medicineName,
        'quantity': quantity,
        'price': price,
      };
      if (expiryDate != null) {
        body['expiryDate'] = expiryDate.toIso8601String();
      }
      final response = await http.post(
        Uri.parse('$baseUrl/inventory'),
        headers: headers,
        body: jsonEncode(body),
      );
      if (response.statusCode != 201) {
        throw Exception('Failed to add inventory item: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Lab Tester API
  Future<Map<String, dynamic>> getPatientLabTests(String abhaId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/v1/lab_tester/patients/$abhaId/lab-tests'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load lab tests: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
