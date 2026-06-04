import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import 'package:flutter/services.dart';
import 'lab_tests_list_screen.dart';

class LabTesterLookupScreen extends StatefulWidget {
  const LabTesterLookupScreen({super.key});

  @override
  State<LabTesterLookupScreen> createState() => _LabTesterLookupScreenState();
}

class _LabTesterLookupScreenState extends State<LabTesterLookupScreen> {
  final TextEditingController _abhaController = TextEditingController();
  bool _isLoading = false;

  void _lookupPatient(String abhaId) {
    if (abhaId.isEmpty) return;
    
    // Format ABHA ID if needed (assuming they might type without dashes)
    String formattedAbha = abhaId;
    if (abhaId.length == 14 && !abhaId.contains('-')) {
      formattedAbha = "${abhaId.substring(0,4)}-${abhaId.substring(4,8)}-${abhaId.substring(8,12)}-${abhaId.substring(12,14)}";
    }

    Navigator.push(context, MaterialPageRoute(
      builder: (context) => LabTestsListScreen(abhaId: formattedAbha)
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Patient Lookup",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Search for a patient using their ABHA ID to view their pending lab tests.",
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Card(
                elevation: 4,
                margin: const EdgeInsets.all(24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.qr_code_scanner, size: 64, color: AppColors.primary),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _abhaController,
                        decoration: const InputDecoration(
                          labelText: 'ABHA ID',
                          hintText: 'e.g. 1111-2222-3333-4444',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_search),
                        ),
                        onSubmitted: _lookupPatient,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () => _lookupPatient(_abhaController.text),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Lookup Patient", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
