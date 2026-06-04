import 'package:flutter/material.dart';
import '../../../core/models/medicine_model.dart';

class ActiveMedicinesList extends StatelessWidget {
  final List<Medicine> medicines;

  const ActiveMedicinesList({super.key, required this.medicines});

  @override
  Widget build(BuildContext context) {
    if (medicines.isEmpty) return const Text("No active medicines.");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Active Medicines", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: medicines.length,
          itemBuilder: (context, index) {
            final med = medicines[index];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.medication)),
                title: Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Dosage: ${med.dosage}"),
              ),
            );
          },
        ),
      ],
    );
  }
}
