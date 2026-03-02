class Prescription {
  final String id;
  final String patientId;
  final String patientName;
  final String pharmacistName;
  final DateTime date;
  final String diagnosis;
  final List<Map<String, String>> medicines;
  final List<String> labTests;

  Prescription({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.pharmacistName,
    required this.date,
    required this.diagnosis,
    required this.medicines,
    required this.labTests,
  });
}
