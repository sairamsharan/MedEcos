import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  
  final TextEditingController _specialityController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _feeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('doctor_jwt_token') ?? '';
      final res = await http.get(
        Uri.parse('http://localhost:5000/api/v1/auth/me'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            _profile = jsonDecode(res.body);
            _specialityController.text = _profile?['speciality'] ?? '';
            _addressController.text = _profile?['address'] ?? '';
            _feeController.text = (_profile?['consultationFee'] ?? 0).toString();
            _loading = false;
          });
        }
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('doctor_jwt_token') ?? '';
      
      int? fee = int.tryParse(_feeController.text);
      
      final res = await http.put(
        Uri.parse('http://localhost:5000/api/v1/auth/profile'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'speciality': _specialityController.text,
          'address': _addressController.text,
          'consultationFee': fee,
        }),
      );
      if (res.statusCode == 200) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    final p = _profile ?? {};
    final name = p['username'] ?? 'Doctor User';
    final doctorId = p['doctorId'] ?? 'doc@abdm';

    return Scaffold(
      appBar: AppBar(title: const Text('Doctor Profile'), automaticallyImplyLeading: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.medical_services, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Doctor ID: $doctorId', style: const TextStyle(fontSize: 16, color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            TextField(
              controller: _specialityController,
              decoration: const InputDecoration(labelText: 'Speciality', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address/Hospital', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _feeController,
              decoration: const InputDecoration(labelText: 'Consultation Fee', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _updateProfile,
              child: const Text('Save Profile'),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
