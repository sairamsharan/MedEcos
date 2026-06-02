import 'package:flutter/material.dart';
import '../../../core/models/medicine_model.dart';
import '../../../core/services/api_service.dart';

class ActiveMedicinesList extends StatefulWidget {
  final List<Medicine> medicines;

  const ActiveMedicinesList({super.key, required this.medicines});

  @override
  State<ActiveMedicinesList> createState() => _ActiveMedicinesListState();
}

class _ActiveMedicinesListState extends State<ActiveMedicinesList> {
  List<dynamic> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final history = await ApiService().getMedicineHistory();
      if (mounted) {
        setState(() {
          _history = history;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isTakenRecently(String medicineName) {
    // Basic logic: if taken in the last 4 hours, hide the button.
    // In a real app, this would use the precise frequency.
    for (var h in _history) {
      if (h['medicineName'] == medicineName) {
        final takenTime = DateTime.parse(h['takenTime']);
        if (DateTime.now().difference(takenTime).inHours < 4) {
          return true;
        }
      }
    }
    return false;
  }

  Future<void> _markTaken(Medicine med) async {
    try {
      await ApiService().logMedicineHistory(med.id, med.name, DateTime.now(), 'TAKEN');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${med.name} marked as taken')));
      _fetchHistory();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (widget.medicines.isEmpty) return const Text("No active medicines.");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Active Medicines", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.medicines.length,
          itemBuilder: (context, index) {
            final med = widget.medicines[index];
            final taken = _isTakenRecently(med.name);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.medication)),
                title: Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Dosage: ${med.dosage}"),
                trailing: taken 
                    ? const Icon(Icons.check_circle, color: Colors.green, size: 30)
                    : ElevatedButton(
                        onPressed: () => _markTaken(med),
                        child: const Text("Mark as Taken"),
                      ),
              ),
            );
          },
        ),
      ],
    );
  }
}
