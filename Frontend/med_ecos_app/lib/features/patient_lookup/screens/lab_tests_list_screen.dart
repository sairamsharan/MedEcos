import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class LabTestsListScreen extends StatefulWidget {
  final String abhaId;
  const LabTestsListScreen({super.key, required this.abhaId});

  @override
  State<LabTestsListScreen> createState() => _LabTestsListScreenState();
}

class _LabTestsListScreenState extends State<LabTestsListScreen> {
  Map<String, dynamic>? _patientData;
  List<dynamic> _tests = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchLabTests();
  }

  Future<void> _fetchLabTests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await ApiService().getPatientLabTests(widget.abhaId);
      if (mounted) {
        setState(() {
          _patientData = data['patient'];
          _tests = data['tests'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Lab Tests'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text("Patient Not Found", style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text("ABHA ID: ${widget.abhaId}", style: const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Go Back'),
                      )
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Patient Info Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      color: AppColors.primary.withOpacity(0.05),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _patientData?['name'] ?? 'Unknown Patient',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "ABHA ID: ${_patientData?['abhaId']}",
                            style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Age: ${_patientData?['age'] ?? 'N/A'} • Gender: ${_patientData?['gender'] ?? 'N/A'}",
                            style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _tests.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline, size: 80, color: Colors.green.withOpacity(0.5)),
                                  const SizedBox(height: 16),
                                  const Text(
                                    "No pending lab tests",
                                    style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(24),
                              itemCount: _tests.length,
                              itemBuilder: (context, index) {
                                final test = _tests[index];
                                final dateStr = test['datePrescribed'] != null 
                                  ? DateTime.parse(test['datePrescribed']).toLocal().toString().split(' ')[0]
                                  : 'Unknown Date';
                                
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.primary.withOpacity(0.1),
                                      child: const Icon(Icons.science, color: AppColors.primary),
                                    ),
                                    title: Text(
                                      test['testName'] ?? 'Unknown Test',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("Prescribed By: Dr. ${test['doctorName']}"),
                                          Text("Diagnosis: ${test['diagnosis']}"),
                                          Text("Date: $dateStr"),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: test['status'] == 'In_Progress' ? Colors.orange.withOpacity(0.2) : (test['status'] == 'Completed' ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2)),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text("Status: ${test['status']?.replaceAll('_', ' ') ?? 'Pending'}", style: TextStyle(
                                              color: test['status'] == 'In_Progress' ? Colors.orange.shade800 : (test['status'] == 'Completed' ? Colors.green.shade800 : Colors.grey.shade800),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            )),
                                          ),
                                        ],
                                      ),
                                    ),
                                    trailing: test['status'] == 'Pending' 
                                      ? ElevatedButton(
                                          onPressed: () async {
                                            try {
                                              await ApiService().processLabTest(widget.abhaId, test['testName'], test['prescriptionId']);
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Test marked as in progress')));
                                                _fetchLabTests(); // Reload to show updated status
                                              }
                                            } catch (e) {
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                                              }
                                            }
                                          },
                                          child: const Text('Process'),
                                        )
                                      : (test['status'] == 'In_Progress' && test['orderId'] != null
                                          ? ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                              onPressed: () async {
                                                try {
                                                  await ApiService().updateLabTestStatus(test['orderId'], 'Completed');
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Test completed successfully')));
                                                    _fetchLabTests(); // Reload to show updated status
                                                  }
                                                } catch (e) {
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                                                  }
                                                }
                                              },
                                              child: const Text('Complete'),
                                            )
                                          : null),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
