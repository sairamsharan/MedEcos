import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';

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
        Uri.parse('http://localhost:5000/api/v1/doctor/appointments'),
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

  Future<void> _acceptAppointment(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/v1/doctor/appointments/$id/accept'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment Accepted')));
          _fetchAppointments();
        }
      } else {
        throw Exception('Failed to accept appointment');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _rescheduleAppointment(String id) async {
    final TextEditingController dateController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    DateTime? selectedDate;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              title: const Text('Reschedule Appointment'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final dt = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (dt != null) {
                        final tm = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (tm != null) {
                          setStateSB(() {
                            selectedDate = DateTime(dt.year, dt.month, dt.day, tm.hour, tm.minute);
                            dateController.text = DateFormat.yMMMd().add_jm().format(selectedDate!);
                          });
                        }
                      }
                    },
                    child: Text(selectedDate == null ? 'Select Date & Time' : dateController.text),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(labelText: 'Notes'),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedDate == null) return;
                    Navigator.pop(context);
                    try {
                      final prefs = await SharedPreferences.getInstance();
                      final token = prefs.getString('jwt_token') ?? '';
                      
                      final response = await http.post(
                        Uri.parse('http://localhost:5000/api/v1/doctor/appointments/$id/reschedule'),
                        headers: {
                          'Content-Type': 'application/json',
                          'Authorization': 'Bearer $token',
                        },
                        body: jsonEncode({
                          'rescheduleDate': selectedDate!.toIso8601String(),
                          'rescheduleNotes': notesController.text,
                        }),
                      );

                      if (response.statusCode == 200) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reschedule Request Sent')));
                          _fetchAppointments();
                        }
                      } else {
                        throw Exception('Failed to reschedule');
                      }
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  child: const Text('Reschedule'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Appointments",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                "View and manage your appointments",
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _appointments.isEmpty
              ? const Center(child: Text('No appointments found'))
              : ListView.builder(
                  itemCount: _appointments.length,
                  itemBuilder: (context, index) {
                    final appt = _appointments[index];
                    final patName = appt['patientName'] ?? 'Unknown Patient';
                    final date = DateTime.parse(appt['date']);
                    final status = appt['status'];
                    final isPending = status == 'Pending';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(patName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text('Status: $status', style: TextStyle(color: status == 'Confirmed' ? Colors.green : Colors.orange)),
                            const SizedBox(height: 8),
                            Text('Date: ${DateFormat.yMMMd().add_jm().format(date)}'),
                            if (appt['notes'] != null && appt['notes'].toString().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text('Reason: ${appt['notes']}', style: const TextStyle(fontStyle: FontStyle.italic)),
                            ],
                            if (isPending) ...[
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: () => _acceptAppointment(appt['_id']),
                                    child: const Text('Accept'),
                                  ),
                                  const SizedBox(width: 16),
                                  OutlinedButton(
                                    onPressed: () => _rescheduleAppointment(appt['_id']),
                                    child: const Text('Reschedule'),
                                  )
                                ],
                              )
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
