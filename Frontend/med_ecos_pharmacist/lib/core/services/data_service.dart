import '../models/patient_model.dart';
import '../models/prescription_model.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  final List<Patient> _patients = [
    Patient(id: "P001", name: "John Doe", age: 34, gender: "Male", contact: "9876543210"),
    Patient(id: "P002", name: "Jane Smith", age: 28, gender: "Female", contact: "8765432109"),
    Patient(id: "P003", name: "Robert Brown", age: 45, gender: "Male", contact: "7654321098"),
    Patient(id: "P004", name: "Emily Davis", age: 22, gender: "Female", contact: "6543210987"),
  ];

  final List<Prescription> _prescriptions = [];

  List<Patient> get patients => List.unmodifiable(_patients);
  List<Prescription> get prescriptions => List.unmodifiable(_prescriptions);

  void addPrescription(Prescription prescription) {
    _prescriptions.add(prescription);
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
  
  Patient? getPatientById(String id) {
    try {
      return _patients.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }
}
