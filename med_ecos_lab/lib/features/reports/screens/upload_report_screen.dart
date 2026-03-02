import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/lab_request_model.dart';
import '../../../core/models/lab_report_model.dart';
import '../../../core/services/data_service.dart';
import '../services/pdf_report_service.dart';

class UploadReportScreen extends StatefulWidget {
  final LabRequest request;

  const UploadReportScreen({super.key, required this.request});

  @override
  State<UploadReportScreen> createState() => _UploadReportScreenState();
}

class _UploadReportScreenState extends State<UploadReportScreen> {
  // Store dynamic results: Map<TestName, List<Map<Parameter, Value>>>
  // For simplicity here, just storing one value per test
  final Map<String, TextEditingController> _testControllers = {};

  @override
  void initState() {
    super.initState();
    for (var test in widget.request.requestedTests) {
      _testControllers[test] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var controller in _testControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _generateAndUpload() async {
    bool hasData = _testControllers.values.any((c) => c.text.isNotEmpty);
    if (!hasData) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Please enter at least one test result.")));
      return;
    }

    try {
      final Map<String, String> results = {};
      _testControllers.forEach((test, controller) {
        if (controller.text.isNotEmpty) {
          results[test] = controller.text;
        }
      });

      final String reportId =
          "REP-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";

      final report = LabReport(
        id: reportId,
        requestId: widget.request.id,
        patientId: widget.request.patientId,
        patientName: widget.request.patientName,
        doctorName: widget.request.doctorName,
        dateCompleted: DateTime.now(),
        testResults: results,
        technicianName: "Tech. Robert",
      );

      DataService().uploadReport(report);

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Report Generated Successfully")));

      await PdfReportService.generateAndPrintReport(
        report: report,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Test Results")),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Form
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // patient info header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Patient: ${widget.request.patientName}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 20)),
                            Text("ID: ${widget.request.patientId}"),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("Ref: ${widget.request.doctorName}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text("Req ID: ${widget.request.id}"),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text("Enter Test Results",
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary)),
                  const SizedBox(height: 24),

                  ...widget.request.requestedTests.map((test) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(test,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          if (test.toLowerCase().contains("scan") ||
                              test.toLowerCase().contains("x-ray") ||
                              test.toLowerCase().contains("mri"))
                            // Image upload placeholder
                            Container(
                              height: 150,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.grey.shade400,
                                    style: BorderStyle.solid),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey.shade100,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.cloud_upload,
                                      size: 48, color: Colors.grey),
                                  const SizedBox(height: 8),
                                  Text("Upload DICOM / Image file for $test",
                                      style:
                                          const TextStyle(color: Colors.grey)),
                                  TextButton(
                                      onPressed: () {},
                                      child: const Text("Browse Files"))
                                ],
                              ),
                            )
                          else
                            // Text input for blood/urine values
                            TextField(
                              controller: _testControllers[test],
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText:
                                    "Enter result values, observations, or attach CSV...",
                                suffixIcon: IconButton(
                                    icon: const Icon(Icons.attach_file),
                                    onPressed: () {}),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _generateAndUpload,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("Generate Official PDF Report & Upload"),
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(60)),
                  ),
                ],
              ),
            ),
          ),

          // Right: Guidelines/Reference
          Expanded(
            flex: 1,
            child: Container(
              color: AppColors.background,
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Lab References",
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Complete Blood Count (CBC)",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Divider(),
                          Text("Hemoglobin: 13.8 to 17.2 g/dL (Men)"),
                          Text("Hemoglobin: 12.1 to 15.1 g/dL (Women)"),
                          Text("WBC: 4,500 to 11,000 cells/mcL"),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Lipid Profile",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Divider(),
                          Text("Total Cholesterol: < 200 mg/dL"),
                          Text("LDL: < 100 mg/dL"),
                          Text("HDL: > 60 mg/dL"),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
