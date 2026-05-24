import 'package:flutter/material.dart';
import '../../../core/services/data_service.dart';
import '../../../core/models/prescription_model.dart';
import '../../../core/theme/app_colors.dart';
import 'prescription_form_screen.dart';
import '../../patient/screens/patient_details_screen.dart';

class PrescriptionListScreen extends StatefulWidget {
  const PrescriptionListScreen({super.key});

  @override
  State<PrescriptionListScreen> createState() => _PrescriptionListScreenState();
}

class _PrescriptionListScreenState extends State<PrescriptionListScreen> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final prescriptions = DataService().searchPrescriptions(_searchQuery);

    return Column(
      children: [
        // Header & Search
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Prescription History",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: "Search by ID, Patient Name, or Date...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),
            ],
          ),
        ),
        
        // List
        Expanded(
          child: prescriptions.isEmpty
              ? Center(
                  child: Text(
                    "No prescriptions found.",
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  itemCount: prescriptions.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final p = prescriptions[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: const Icon(Icons.description, color: AppColors.primary),
                        ),
                        title: Text(p.patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text("ID: ${p.id} • ${p.date.toString().split(' ')[0]}"),
                            Text("Dr. ${p.doctorName} • ${p.medicines.length} Medicines"),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                           // Navigate to detail view or re-open form in view mode
                           // For now, we can show a simple dialog or navigate to patient details
                           Navigator.push(context, MaterialPageRoute(builder: (_) => PatientDetailsScreen(patientId: p.patientId)));
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
