class LabRequest {
  final String id;
  final String patientId;
  final String patientName;
  final String doctorName;
  final DateTime dateRequested;
  final List<String> requestedTests;
  final String status; // 'Pending', 'In Progress', 'Completed'

  LabRequest({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorName,
    required this.dateRequested,
    required this.requestedTests,
    this.status = 'Pending',
  });
}
