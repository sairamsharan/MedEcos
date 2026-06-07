import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/book_appointment_dialog.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  List<dynamic> _appointments = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/v1/patient/appointments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _appointments = jsonDecode(response.body);
            _loading = false;
          });
        }
      } else {
        throw Exception('Failed to load appointments');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Confirmed': return Colors.blue;
      case 'Completed': return Colors.green;
      case 'Pending': return Colors.orange;
      case 'RescheduleRequested': return Colors.red;
      default: return Colors.grey;
    }
  }

  Future<void> _acceptReschedule(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/v1/patient/appointments/$id/accept-reschedule'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reschedule Accepted')));
          _fetchAppointments();
        }
      } else {
        throw Exception('Failed to accept reschedule');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)));

    return Scaffold(
      appBar: AppBar(title: const Text('Appointments'), automaticallyImplyLeading: false),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await showDialog(context: context, builder: (_) => const BookAppointmentDialog());
          if (res == true) {
            _fetchAppointments();
          }
        },
        label: const Text("Book Request"),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _appointments.isEmpty
          ? const Center(child: Text('No appointments found'))
          : ListView.builder(
              itemCount: _appointments.length,
              itemBuilder: (context, index) {
                final appt = _appointments[index];
                final doctor = appt['doctorId'];
                final docName = doctor != null ? doctor['username'] : 'Unknown Doctor';
                final date = DateTime.parse(appt['date']);
                final status = appt['status'];
                final isRescheduleRequested = status == 'RescheduleRequested';

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(docName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(status),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Original Date: ${DateFormat.yMMMd().add_jm().format(date)}'),
                        if (appt['notes'] != null && appt['notes'].toString().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text('Reason: ${appt['notes']}', style: const TextStyle(fontStyle: FontStyle.italic)),
                        ],
                        if (isRescheduleRequested && appt['rescheduleDate'] != null) ...[
                          const SizedBox(height: 8),
                          Text('Requested Date: ${DateFormat.yMMMd().add_jm().format(DateTime.parse(appt['rescheduleDate']))}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          if (appt['rescheduleNotes'] != null)
                            Text('Note: ${appt['rescheduleNotes']}'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _acceptReschedule(appt['_id']),
                            child: const Text('Accept Reschedule'),
                          )
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
