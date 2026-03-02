import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../prescription/screens/prescription_form_screen.dart';

class PatientDetailsScreen extends StatelessWidget {
  final String patientId;

  const PatientDetailsScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
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
                        const Text(
                          "John Doe", // Mock Data
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "ID: $patientId",
                          style: TextStyle(color: Colors.white.withOpacity(0.9)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Male • 34 Years",
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
                    onPressed: () {
                      // Navigate to Prescription Form
                      Navigator.push(context, MaterialPageRoute(builder: (_) => PrescriptionFormScreen(patientId: patientId, patientName: "John Doe")));
                    },
                    icon: const Icon(Icons.edit_note),
                    label: const Text("Process Prescription"),
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
                    label: const Text("View History"),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            Text("Medical History", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // History List (Mock)
            _buildHistoryItem(context, "Viral Fever", "12 Jan 2024", "Dr. Tanishq"),
            _buildHistoryItem(context, "Routine Checkup", "10 Oct 2023", "Dr. Gupta"),
            _buildHistoryItem(context, "Allergy Test", "15 Aug 2023", "Dr. Smith"),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, String diagnosis, String date, String doctor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.article, color: AppColors.primary),
        ),
        title: Text(diagnosis, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("$doctor • $date"),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }
}
