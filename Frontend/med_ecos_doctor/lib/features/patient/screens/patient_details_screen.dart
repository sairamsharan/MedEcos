import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/patient_model.dart';
import '../../../core/services/data_service.dart';
import '../../prescription/screens/prescription_form_screen.dart';
import '../../../core/services/data_service.dart';
import '../../../core/models/patient_model.dart';
import '../../../core/models/prescription_model.dart';
import '../../../core/utils/medicine_utils.dart';
import 'package:intl/intl.dart';

class PatientDetailsScreen extends StatefulWidget {
  final String patientId;

  const PatientDetailsScreen({super.key, required this.patientId});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  Patient? _patient;
  List<Prescription> _prescriptions = [];
  List<String> _activeMedicines = [];
  List<String> _previousMedicines = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _patient = DataService().getPatientById(widget.patientId);
      _prescriptions = DataService().getPrescriptionsForPatient(widget.patientId);
      _processMedicines();
    });
  }

  void _processMedicines() {
    _activeMedicines.clear();
    _previousMedicines.clear();

    if (_prescriptions.isEmpty) return;

    final activeSet = <String>{};
    final previousSet = <String>{};

    for (var prescription in _prescriptions) {
      for (var med in prescription.medicines) {
        if (med['name'] != null && med['duration'] != null) {
          final name = med['name']!;
          if (MedicineUtils.isActiveMedicine(prescription.date, med['duration']!)) {
            activeSet.add(name);
          } else {
            // Only add to previous if it's not currently active from another prescription
            if (!activeSet.contains(name)) {
              previousSet.add(name);
            }
          }
        }
      }
    }
    
    // Ensure nothing in previous is also in active (in case an older prescription was processed before a newer one added it to active, though we are sorted descending)
    previousSet.removeWhere((name) => activeSet.contains(name));

    _activeMedicines = activeSet.toList()..sort();
    _previousMedicines = previousSet.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    if (_patient == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Patient Details")),
        body: const Center(child: Text("Patient not found")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Patient Details"),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
        ],
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
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40, color: AppColors.primary),
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
                          "ID: ${_patient!.id}",
                          style: TextStyle(color: Colors.white.withOpacity(0.9)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${_patient!.gender} • ${_patient!.age} Years",
                          style: TextStyle(color: Colors.white.withOpacity(0.9)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Contact: ${_patient!.contact}",
                          style: TextStyle(color: Colors.white.withOpacity(0.9)),
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
                    onPressed: () async {
                      // Navigate to Prescription Form and wait for return
                      await Navigator.push(
                        context, 
                        MaterialPageRoute(
                          builder: (_) => PrescriptionFormScreen(
                            patientId: _patient!.id, 
                            patientName: _patient!.name
                          )
                        )
                      );
                      // Reload data when returning
                      _loadData();
                    },
                    icon: const Icon(Icons.edit_note),
                    label: const Text("Write Prescription"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.history),
                    label: const Text("View Full History"),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            Text("Medical Overview", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Active Medicines
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.medication, color: Colors.green),
                        const SizedBox(width: 8),
                        Text("Active Medicines", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(),
                    if (_activeMedicines.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text("No active medicines currently prescribed.", style: TextStyle(color: AppColors.textSecondary)),
                      )
                    else
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: _activeMedicines.map((med) => Chip(
                          label: Text(med),
                          backgroundColor: Colors.green.withOpacity(0.1),
                          side: const BorderSide(color: Colors.green, width: 0.5),
                        )).toList(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Previous Medicines
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.history, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text("Previous Medicines", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(),
                    if (_previousMedicines.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text("No previous medicine history.", style: TextStyle(color: AppColors.textSecondary)),
                      )
                    else
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: _previousMedicines.map((med) => Chip(
                          label: Text(med),
                          backgroundColor: Colors.orange.withOpacity(0.1),
                          side: const BorderSide(color: Colors.orange, width: 0.5),
                        )).toList(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Prescription History
            Text("Past Prescriptions", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (_prescriptions.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("No prescriptions found."),
              ))
            else
              ..._prescriptions.map((p) => _buildPrescriptionItem(context, p)),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionItem(BuildContext context, Prescription prescription) {
    final dateStr = DateFormat('dd MMM yyyy').format(prescription.date);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.article, color: AppColors.primary),
        ),
        title: Text(prescription.diagnosis.isNotEmpty ? prescription.diagnosis : "Prescription", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${prescription.doctorName} • $dateStr"),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Could open details here in the future
        },
      ),
    );
  }
}

