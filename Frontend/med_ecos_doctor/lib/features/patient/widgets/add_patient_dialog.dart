import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/models/patient_model.dart';
import '../../../../core/services/data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/abha_formatter.dart';

class AddPatientDialog extends StatefulWidget {
  const AddPatientDialog({super.key});

  @override
  State<AddPatientDialog> createState() => _AddPatientDialogState();
}

class _AddPatientDialogState extends State<AddPatientDialog> {
  final _abhaController = TextEditingController();
  final _otpController = TextEditingController();
  
  bool _isLoading = false;
  String? _transactionId;
  String? _errorMessage;

  Future<void> _generateOtp() async {
    if (_abhaController.text.isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/auth/abha/generate-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'abhaId': _abhaController.text}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _transactionId = data['transactionId'];
        });
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Failed to send OTP';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOtpAndRegister() async {
    if (_otpController.text.isEmpty || _transactionId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('doctor_jwt_token') ?? '';

      final response = await http.post(
        Uri.parse('http://localhost:5000/api/v1/doctor/patients/abha-register'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'transactionId': _transactionId,
          'otp': _otpController.text,
          'abhaId': _abhaController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Patient created and returned from backend
        final patient = Patient(
          id: data['abhaId'] ?? data['_id'],
          name: data['username'] ?? 'Unknown Patient',
          age: data['age'] ?? 0,
          gender: data['gender'] ?? 'Unknown',
          contact: data['mobileNumber'] ?? 'N/A',
        );
        
        DataService().addPatient(patient);
        if (mounted) {
          Navigator.pop(context, patient);
        }
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Verification failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Register Patient via ABHA"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_transactionId == null) ...[
              TextField(
                controller: _abhaController,
                inputFormatters: [AbhaInputFormatter()],
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'ABHA ID (e.g. 1111-2222-3333-4444)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                ),
              ElevatedButton(
                onPressed: _isLoading ? null : _generateOtp,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Send OTP"),
              ),
            ] else ...[
              Text(
                'OTP sent to mobile linked with ABHA ID: ${_abhaController.text}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _otpController,
                decoration: const InputDecoration(
                  labelText: 'Enter OTP (Try 123456)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                ),
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtpAndRegister,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Verify & Register"),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _transactionId = null;
                    _otpController.clear();
                    _errorMessage = null;
                  });
                },
                child: const Text("Use different ABHA ID"),
              )
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
      ],
    );
  }
}
