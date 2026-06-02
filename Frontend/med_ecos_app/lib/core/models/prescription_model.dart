class Prescription {
  final String id;
  final String patientId;
  final String patientName;
  final String doctorName;
  final String? pharmacistName;
  final DateTime date;
  final String diagnosis;
  final List<Map<String, String>> medicines;
  final List<String> labTests;
  final String status;
  final String? doctorNotes;
  final String? pharmacistNotes;

  Prescription({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorName,
    this.pharmacistName,
    required this.date,
    required this.diagnosis,
    required this.medicines,
    required this.labTests,
    this.status = 'Active',
    this.doctorNotes,
    this.pharmacistNotes,
  });
}
