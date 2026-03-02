class LabReport {
  final String id;
  final String requestId;
  final String patientId;
  final String patientName;
  final String doctorName;
  final DateTime dateCompleted;
  final Map<String, String> testResults; // e.g., {'Hemoglobin': '14.2 g/dL'}
  final String technicianName;

  LabReport({
    required this.id,
    required this.requestId,
    required this.patientId,
    required this.patientName,
    required this.doctorName,
    required this.dateCompleted,
    required this.testResults,
    required this.technicianName,
  });
}
