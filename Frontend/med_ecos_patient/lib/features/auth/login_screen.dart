import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../dashboard/screens/dashboard_screen.dart';
import 'signup_screen.dart';
import '../../../core/utils/abha_formatter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _abhaController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _transactionId;

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
          _errorMessage = data['message'] ?? 'Failed to generate OTP';
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

  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty || _transactionId == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/auth/abha/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'abhaId': _abhaController.text,
          'transactionId': _transactionId,
          'otp': _otpController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('patient_jwt_token', data['token']);
        await prefs.setString('patient_user_id', data['_id']);
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        }
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Invalid OTP';
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

  bool _isEmailLogin = true; // Default to email login
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _loginWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('patient_jwt_token', data['token']);
        await prefs.setString('patient_user_id', data['_id']);
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        }
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Invalid credentials';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Patient Portal Login')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.person, size: 80, color: Colors.blue),
                  const SizedBox(height: 32),
                  
                  // Toggle Switch
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('ABHA OTP', style: TextStyle(fontWeight: !_isEmailLogin ? FontWeight.bold : FontWeight.normal)),
                      Switch(
                        value: _isEmailLogin,
                        onChanged: (val) {
                          setState(() {
                            _isEmailLogin = val;
                            _errorMessage = null;
                          });
                        },
                      ),
                      Text('Email', style: TextStyle(fontWeight: _isEmailLogin ? FontWeight.bold : FontWeight.normal)),
                    ],
                  ),
                  const SizedBox(height: 24),
  
                  if (_isEmailLogin) ...[
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _loginWithEmail,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading 
                          ? const CircularProgressIndicator() 
                          : const Text('Login'),
                    ),
                  ] else ...[
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
                      const SizedBox(height: 24),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _generateOtp,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading 
                            ? const CircularProgressIndicator() 
                            : const Text('Send OTP'),
                      ),
                    ] else ...[
                      Text(
                        'OTP sent to registered mobile for ${_abhaController.text}',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _otpController,
                        decoration: const InputDecoration(
                          labelText: 'Enter OTP (Try 123456)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading 
                            ? const CircularProgressIndicator() 
                            : const Text('Verify & Login'),
                      ),
                    ],
                  ],
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen()));
                    },
                    child: const Text("Don't have an account? Sign Up (Email & ABHA)"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
