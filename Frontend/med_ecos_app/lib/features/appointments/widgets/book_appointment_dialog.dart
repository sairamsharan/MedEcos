import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';

class BookAppointmentDialog extends StatefulWidget {
  const BookAppointmentDialog({super.key});

  @override
  State<BookAppointmentDialog> createState() => _BookAppointmentDialogState();
}

class _BookAppointmentDialogState extends State<BookAppointmentDialog> {
  bool _loading = true;
  List<dynamic> _doctors = [];
  String? _selectedDoctorId;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  final TextEditingController _notesController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    try {
      final res = await http.get(Uri.parse('http://localhost:5000/api/public/doctors'));
      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            _doctors = jsonDecode(res.body);
            if (_doctors.isNotEmpty) {
              _selectedDoctorId = _doctors[0]['_id'];
            }
            _loading = false;
          });
        }
      } else {
        throw Exception("Failed to load doctors");
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _bookAppointment() async {
    if (_selectedDoctorId == null) return;
    setState(() => _submitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      
      final res = await http.post(
        Uri.parse('http://localhost:5000/api/v1/patient/appointments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'doctorId': _selectedDoctorId,
          'date': _selectedDate.toIso8601String(),
          'notes': _notesController.text,
        }),
      );

      if (res.statusCode == 201) {
        if (mounted) Navigator.pop(context, true);
      } else {
        throw Exception(res.body);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const AlertDialog(content: SizedBox(height: 100, child: Center(child: CircularProgressIndicator())));
    if (_doctors.isEmpty) return AlertDialog(title: const Text("No Doctors"), content: const Text("No doctors available."), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))]);

    return AlertDialog(
      title: const Text("Book Appointment"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedDoctorId,
              items: _doctors.map((d) => DropdownMenuItem<String>(
                value: d['_id'],
                child: Text("${d['username']} (${d['speciality'] ?? 'General'})"),
              )).toList(),
              onChanged: (val) => setState(() => _selectedDoctorId = val),
              decoration: const InputDecoration(labelText: "Select Doctor"),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Text("Date: ${_selectedDate.toString().split(' ')[0]}")),
                TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context, 
                      initialDate: _selectedDate, 
                      firstDate: DateTime.now(), 
                      lastDate: DateTime.now().add(const Duration(days: 365))
                    );
                    if (date != null) setState(() => _selectedDate = date);
                  },
                  child: const Text("Change"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: "Reason to meet (Notes)", border: OutlineInputBorder()),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: _submitting ? null : _bookAppointment,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: _submitting ? const CircularProgressIndicator(color: Colors.white) : const Text("Book Request"),
        ),
      ],
    );
  }
}
