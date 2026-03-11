import 'package:flutter/material.dart';
import '../../../core/models/medicine_model.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/notification_service.dart';
import 'package:uuid/uuid.dart';

class AddMedicineDialog extends StatefulWidget {
  const AddMedicineDialog({super.key});

  @override
  State<AddMedicineDialog> createState() => _AddMedicineDialogState();
}

class _AddMedicineDialogState extends State<AddMedicineDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  
  // Simplified for prototype: 1 frequency, selecting meal ref
  MealType _selectedMeal = MealType.lunch;
  TimeType _selectedTimeType = TimeType.afterMeal;

  Future<void> _saveMedicine() async {
    if (_formKey.currentState!.validate()) {
      final medicine = Medicine(
        id: const Uuid().v4(),
        name: _nameController.text,
        dosage: _dosageController.text,
        frequency: 1, // Defaulting to 1 for this simple dialog
        timings: [
          MedicineTiming(
            timeType: _selectedTimeType,
            mealRef: _selectedMeal,
            offsetMinutes: 0, // Default immediate
          )
        ],
        startDate: DateTime.now(),
      );

      await DatabaseService().insertMedicine(medicine);
      await NotificationService().scheduleMedicineReminders(medicine);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Medicine'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Medicine Name'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(labelText: 'Dosage (e.g., 500mg)'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<MealType>(
                value: _selectedMeal,
                decoration: const InputDecoration(labelText: 'Meal'),
                items: MealType.values.map((e) {
                  return DropdownMenuItem(
                    value: e,
                    child: Text(e.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedMeal = val!),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<TimeType>(
                value: _selectedTimeType,
                decoration: const InputDecoration(labelText: 'Timing'),
                items: TimeType.values.map((e) {
                  return DropdownMenuItem(
                    value: e,
                    child: Text(e.name.replaceAll(RegExp(r'(?=[A-Z])'), ' ')), // split camelCase
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedTimeType = val!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _saveMedicine, child: const Text('Add')),
      ],
    );
  }
}
