import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class LabLocationsMapScreen extends StatefulWidget {
  const LabLocationsMapScreen({super.key});

  @override
  State<LabLocationsMapScreen> createState() => _LabLocationsMapScreenState();
}

class _LabLocationsMapScreenState extends State<LabLocationsMapScreen> {
  LatLng? _userLocation;
  List<dynamic> _labs = [];
  bool _loading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initMapData();
  }

  Future<void> _initMapData() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      // Fallback location if location services are disabled
      setState(() {
        _userLocation = const LatLng(20.5937, 78.9629); // Center of India roughly
      });
    }
    _fetchLabs();
  }

  Future<void> _fetchLabs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      
      final res = await http.get(
        Uri.parse('https://medecos.onrender.com/api/v1/patient/labs'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            _labs = jsonDecode(res.body);
            _loading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to load labs';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _loading = false;
      });
    }
  }

  void _bookTest(String labId, String testName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      
      final res = await http.post(
        Uri.parse('https://medecos.onrender.com/api/v1/patient/lab-test-orders'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'labTesterId': labId,
          'testName': testName
        })
      );
      
      if (res.statusCode == 201) {
        if (mounted) {
          Navigator.pop(context); // Close bottom sheet
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Test requested successfully: $testName')));
        }
      } else {
        final err = jsonDecode(res.body);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${err['message']}')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showLabDetails(dynamic lab) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        List<dynamic> tests = lab['labTestsProvided'] ?? [];
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lab['username'] ?? 'Unknown Lab',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
              ),
              if (lab['address'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text("Address: ${lab['address']}"),
                ),
              const SizedBox(height: 24),
              const Text("Tests Provided:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              tests.isEmpty 
                ? const Text("No tests listed.") 
                : Wrap(
                    spacing: 12, runSpacing: 12,
                    children: tests.map((test) => ActionChip(
                      label: Text(test.toString()),
                      onPressed: () {
                        // Confirm booking
                        showDialog(
                          context: ctx,
                          builder: (dCtx) => AlertDialog(
                            title: const Text('Book Lab Test'),
                            content: Text('Are you sure you want to book a $test test at ${lab['username']}?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(dCtx);
                                  _bookTest(lab['_id'], test.toString());
                                },
                                child: const Text('Book Test')
                              )
                            ],
                          )
                        );
                      },
                    )).toList()
                  ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close')
                ),
              )
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find Nearby Labs')),
      body: _loading || _userLocation == null
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
            ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
            : FlutterMap(
                options: MapOptions(
                  initialCenter: _userLocation!,
                  initialZoom: 13.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.medecos.app',
                  ),
                  MarkerLayer(
                    markers: [
                      // User Marker
                      Marker(
                        point: _userLocation!,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.my_location, color: Colors.blue, size: 40),
                      ),
                      // Lab Markers
                      ..._labs.where((lab) => lab['location'] != null && lab['location']['lat'] != null).map((lab) {
                        return Marker(
                          point: LatLng(
                            (lab['location']['lat'] as num).toDouble(),
                            (lab['location']['lng'] as num).toDouble()
                          ),
                          width: 50,
                          height: 50,
                          child: GestureDetector(
                            onTap: () => _showLabDetails(lab),
                            child: const Icon(Icons.science, color: Colors.red, size: 40),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ],
              ),
    );
  }
}
