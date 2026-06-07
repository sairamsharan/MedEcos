import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../prescription/services/pdf_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrescriptionsScreen extends StatefulWidget {
  const PrescriptionsScreen({super.key});

  @override
  State<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _prescriptions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPrescriptions();
  }

  Future<void> _fetchPrescriptions() async {
    try {
      final list = await _api.getPrescriptions();
      if (mounted) {
        setState(() {
          _prescriptions = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text('Error: $_error', style: const TextStyle(color: Colors.red)),
      );
    }

    if (_prescriptions.isEmpty) {
      return const Center(child: Text('No prescriptions found.', style: TextStyle(fontSize: 18, color: Colors.grey)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "My Prescriptions",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 24),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _prescriptions.length,
            itemBuilder: (context, index) {
              final p = _prescriptions[index];
              final date = DateTime.parse(p['date']);
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Dr. ${p['doctorName'] ?? 'Unknown'}",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('MMM dd, yyyy').format(date),
                                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (p['status'] == 'Active') ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              (p['status']?.toString().toUpperCase() ?? 'ACTIVE'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: (p['status'] == 'Active') ? Colors.green : Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Diagnosis: ${p['diagnosis'] ?? 'N/A'}",
                        style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                      ),
                      const Divider(height: 24),
                      const Text(
                        "Medicines:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...(p['medicines'] as List<dynamic>).map((m) {
                        if (m is Map) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.medication, size: 16, color: Colors.blueGrey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(m['name']?.toString() ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600)),
                                      Text("${m['dosage'] ?? m['timing'] ?? ''} • ${m['frequency'] ?? m['context'] ?? ''} • ${m['duration'] ?? ''}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Row(
                            children: [
                              const Icon(Icons.medication, size: 16, color: Colors.blueGrey),
                              const SizedBox(width: 8),
                              Text(m.toString()),
                            ],
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () async {
                            try {
                              final prefs = await SharedPreferences.getInstance();
                              final patientName = prefs.getString('username') ?? 'Patient';
                              final patientId = prefs.getString('user_id') ?? 'Unknown ID';
                              
                              final List<Map<String, String>> medList = (p['medicines'] as List<dynamic>).map((m) {
                                if (m is Map) {
                                  return {
                                    'name': m['name']?.toString() ?? '',
                                    'timing': m['timing']?.toString().isNotEmpty == true ? m['timing'].toString() : (m['dosage']?.toString() ?? ''),
                                    'context': m['context']?.toString().isNotEmpty == true ? m['context'].toString() : (m['frequency']?.toString() ?? ''),
                                    'duration': m['duration']?.toString() ?? '',
                                    'instruction': m['instruction']?.toString() ?? '',
                                  };
                                }
                                return {'name': m.toString(), 'timing': '', 'context': '', 'duration': '', 'instruction': ''};
                              }).toList();

                              await PdfService.generateAndPrintPrescription(
                                doctorName: "Dr. ${p['doctorName'] ?? 'Unknown'}",
                                patientName: patientName,
                                patientId: patientId,
                                symptoms: p['diagnosis'] ?? 'N/A',
                                medicines: medList,
                                labTests: [], // Add lab tests if they exist in p['labTests']
                                date: DateFormat('MMM dd, yyyy hh:mm a').format(date),
                                doctorSpeciality: prefs.getString('speciality') ?? 'General Physician',
                                clinicLocation: prefs.getString('location') ?? 'MedEcos Clinic Network',
                              );
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error generating PDF: $e")));
                              }
                            }
                          },
                          icon: const Icon(Icons.download),
                          label: const Text("Download PDF"),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
