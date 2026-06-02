import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/patient_model.dart';
import '../../../core/services/api_service.dart';
import '../../prescription/screens/doctor_prescription_form_screen.dart' as doctor;
import '../../prescription/screens/pharmacist_prescription_form_screen.dart' as pharmacist;
import 'package:intl/intl.dart';

class PatientDetailsScreen extends StatefulWidget {
  final String patientId;

  const PatientDetailsScreen({super.key, required this.patientId});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  String _userRole = 'Doctor';
  Patient? _patient;
  List<dynamic> _prescriptions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('user_role') ?? 'Doctor';
      _patient = ApiService().getPatientById(widget.patientId);
    });

    if (_patient == null && _userRole == 'Doctor') {
      try {
        _patient = await ApiService().registerPatientViaAbha(widget.patientId);
      } catch (e) {
        print(e);
      }
    }

    setState(() {
      _prescriptions = ApiService().getPrescriptionsForPatient(widget.patientId);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_patient == null) return const Scaffold(body: Center(child: Text("Patient not found in database.")));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Patient Details"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                   CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Text(_patient!.name[0], style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _patient!.name,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "ID: ${widget.patientId}",
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${_patient!.gender} • ${_patient!.age} Years",
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_userRole == 'Pharmacist') {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => pharmacist.PrescriptionFormScreen(patientId: widget.patientId, patientName: _patient!.name)));
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => doctor.PrescriptionFormScreen(patientId: widget.patientId, patientName: _patient!.name)));
                      }
                    },
                    icon: const Icon(Icons.edit_note),
                    label: const Text("Write / Fulfill Prescription"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            Text("Prescription History", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _prescriptions.isEmpty ? const Text("No prescription history found.") : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _prescriptions.length,
              itemBuilder: (context, index) {
                final p = _prescriptions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.article, color: AppColors.primary),
                    ),
                    title: Text(p.diagnosis, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${p.doctorName} • ${DateFormat.yMMMd().format(p.date)}"),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
