import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/login_screen.dart';
import '../../../core/widgets/location_picker_screen.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  bool _isLocating = false;

  String _morningTime = '08:00 AM';
  String _afternoonTime = '01:00 PM';
  String _eveningTime = '05:00 PM';
  String _nightTime = '09:00 PM';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      final res = await http.get(
        Uri.parse('http://localhost:5000/api/auth/me'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            _profile = jsonDecode(res.body);
            _addressController.text = _profile?['address'] ?? '';
            if (_profile?['location'] != null) {
              _latController.text = _profile!['location']['lat']?.toString() ?? '';
              _lngController.text = _profile!['location']['lng']?.toString() ?? '';
            }
            final routine = _profile?['routine'];
            if (routine != null) {
              _morningTime = routine['morning'] ?? '08:00 AM';
              _afternoonTime = routine['afternoon'] ?? '01:00 PM';
              _eveningTime = routine['evening'] ?? '05:00 PM';
              _nightTime = routine['night'] ?? '09:00 PM';
            }
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
      final token = prefs.getString('jwt_token') ?? '';
      final res = await http.put(
        Uri.parse('http://localhost:5000/api/auth/profile'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'address': _addressController.text,
          'location': {
            'lat': double.tryParse(_latController.text) ?? 0.0,
            'lng': double.tryParse(_lngController.text) ?? 0.0,
          },
          'routine': {
            'morning': _morningTime,
            'afternoon': _afternoonTime,
            'evening': _eveningTime,
            'night': _nightTime,
          }
        }),
      );
      if (res.statusCode == 200) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _detectLocation() async {
    setState(() => _isLocating = true);
    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _latController.text = position.latitude.toString();
        _lngController.text = position.longitude.toString();
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not get location: $e')));
    } finally {
      setState(() => _isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    final p = _profile ?? {};
    final name = p['username'] ?? 'Patient User';
    final abhaId = p['abhaId'] ?? 'user@abdm';

    return Scaffold(
      appBar: AppBar(title: const Text('Patient Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('ABHA Address: $abhaId', style: const TextStyle(fontSize: 16, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text('Age: ${p['age'] ?? 'N/A'} • Gender: ${p['gender'] ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 32),
            const Align(alignment: Alignment.centerLeft, child: Text('Daily Routine Timings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 16),
            _buildTimeSelector('Morning / Wake Up', _morningTime, (t) => setState(() => _morningTime = t)),
            _buildTimeSelector('Afternoon / Lunch', _afternoonTime, (t) => setState(() => _afternoonTime = t)),
            _buildTimeSelector('Evening / Snacks', _eveningTime, (t) => setState(() => _eveningTime = t)),
            _buildTimeSelector('Night / Dinner', _nightTime, (t) => setState(() => _nightTime = t)),
            const SizedBox(height: 24),
            const Align(alignment: Alignment.centerLeft, child: Text('Location & Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextField(controller: _latController, decoration: const InputDecoration(labelText: 'Latitude', border: OutlineInputBorder()))),
                const SizedBox(width: 16),
                Expanded(child: TextField(controller: _lngController, decoration: const InputDecoration(labelText: 'Longitude', border: OutlineInputBorder()))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLocating ? null : _detectLocation,
                    icon: _isLocating
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location),
                    label: Text(_isLocating ? 'Detecting...' : 'Use My Location'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      LatLng? current;
                      if (_latController.text.isNotEmpty && _lngController.text.isNotEmpty) {
                        current = LatLng(double.parse(_latController.text), double.parse(_lngController.text));
                      }
                      final LatLng? picked = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => LocationPickerScreen(initialLocation: current)),
                      );
                      if (picked != null) {
                        setState(() {
                          _latController.text = picked.latitude.toString();
                          _lngController.text = picked.longitude.toString();
                        });
                      }
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('Choose from Map'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
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

  Widget _buildTimeSelector(String label, String time, Function(String) onSelect) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          TextButton.icon(
            onPressed: () async {
              final parsed = TimeOfDay(
                hour: int.parse(time.split(':')[0]) + (time.contains('PM') && time.split(':')[0] != '12' ? 12 : 0),
                minute: int.parse(time.split(':')[1].split(' ')[0]),
              );
              final picked = await showTimePicker(context: context, initialTime: parsed);
              if (picked != null) {
                if (mounted) {
                  final formatted = picked.format(context);
                  onSelect(formatted);
                }
              }
            },
            icon: const Icon(Icons.access_time, size: 18),
            label: Text(time),
          ),
        ],
      ),
    );
  }
}
