import 'package:flutter/material.dart';
import '../../../core/models/patient_model.dart';
import '../../../core/services/data_service.dart';
import '../../../core/theme/app_colors.dart';

class AddPatientDialog extends StatefulWidget {
  const AddPatientDialog({super.key});

  @override
  State<AddPatientDialog> createState() => _AddPatientDialogState();
}

class _AddPatientDialogState extends State<AddPatientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _contactController = TextEditingController();
  String _gender = 'Male';

  void _savePatient() {
    if (_formKey.currentState!.validate()) {
      final id = "PAT-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";
      final patient = Patient(
        id: id,
        name: _nameController.text,
        age: int.parse(_ageController.text),
        gender: _gender,
        contact: _contactController.text,
      );

      DataService().addPatient(patient);
      Navigator.pop(context, patient);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Register New Patient"),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Full Name"),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(labelText: "Age"),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _gender,
                      items: ['Male', 'Female', 'Other'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _gender = v!),
                      decoration: const InputDecoration(labelText: "Gender"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(labelText: "Contact Number"),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: _savePatient, 
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text("Register"),
        ),
      ],
    );
  }
}
