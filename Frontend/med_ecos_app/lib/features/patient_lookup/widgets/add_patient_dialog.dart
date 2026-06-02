import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/abha_formatter.dart';

class AddPatientDialog extends StatefulWidget {
  const AddPatientDialog({super.key});

  @override
  State<AddPatientDialog> createState() => _AddPatientDialogState();
}

class _AddPatientDialogState extends State<AddPatientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _abhaController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _registerPatient() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final patient = await ApiService().registerPatientViaAbha(_abhaController.text);
        if (mounted) {
          Navigator.pop(context, patient);
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString().contains('message') 
              ? e.toString() 
              : 'Failed to fetch ABDM data or invalid ABHA ID';
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Register Patient via ABDM"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Enter the patient's ABHA ID. Their details will be fetched automatically from the ABDM database.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _abhaController,
              inputFormatters: [AbhaInputFormatter()],
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "ABHA ID",
                hintText: "1111-2222-3333-4444",
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return "Required";
                if (v.length < 17) return "Invalid ABHA format";
                return null;
              },
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ]
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: _isLoading ? null : _registerPatient, 
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Fetch & Register"),
        ),
      ],
    );
  }
}
