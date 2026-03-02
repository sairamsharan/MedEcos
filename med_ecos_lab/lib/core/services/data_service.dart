import '../models/lab_request_model.dart';
import '../models/lab_report_model.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  // Mock pending tests coming from doctors
  final List<LabRequest> _pendingRequests = [
    LabRequest(
      id: "REQ-1001",
      patientId: "P001",
      patientName: "John Doe",
      doctorName: "Dr. Smith",
      dateRequested: DateTime.now().subtract(const Duration(hours: 2)),
      requestedTests: ["Complete Blood Count (CBC)", "Lipid Profile"],
    ),
    LabRequest(
      id: "REQ-1002",
      patientId: "P002",
      patientName: "Jane Smith",
      doctorName: "Dr. Gupta",
      dateRequested: DateTime.now().subtract(const Duration(days: 1)),
      requestedTests: ["Thyroid Profile", "Urine Routine"],
    ),
    LabRequest(
      id: "REQ-1003",
      patientId: "P003",
      patientName: "Robert Brown",
      doctorName: "Dr. Tanishq",
      dateRequested: DateTime.now(),
      requestedTests: ["MRI Scan - Brain"],
    ),
  ];

  final List<LabReport> _completedReports = [];

  List<LabRequest> get pendingRequests => List.unmodifiable(_pendingRequests);
  List<LabReport> get completedReports => List.unmodifiable(_completedReports);

  void uploadReport(LabReport report) {
    _completedReports.add(report);
    // Remove the request from pending once completed
    _pendingRequests.removeWhere((req) => req.id == report.requestId);
  }

  List<LabRequest> searchRequests(String query) {
    if (query.isEmpty) return _pendingRequests;
    final lower = query.toLowerCase();
    return _pendingRequests
        .where((r) =>
            r.patientName.toLowerCase().contains(lower) ||
            r.id.toLowerCase().contains(lower))
        .toList();
  }
}
