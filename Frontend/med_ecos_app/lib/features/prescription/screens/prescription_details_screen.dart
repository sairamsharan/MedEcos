import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/prescription_model.dart';
import '../../../core/services/api_service.dart';

class PrescriptionDetailsScreen extends StatefulWidget {
  final Prescription prescription;

  const PrescriptionDetailsScreen({super.key, required this.prescription});

  @override
  State<PrescriptionDetailsScreen> createState() => _PrescriptionDetailsScreenState();
}

class _PrescriptionDetailsScreenState extends State<PrescriptionDetailsScreen> {
  String _userRole = 'Patient';
  final TextEditingController _notesController = TextEditingController();
  late String _status;
  late String? _doctorNotes;
  late String? _pharmacistNotes;

  @override
  void initState() {
    super.initState();
    _status = widget.prescription.status;
    _doctorNotes = widget.prescription.doctorNotes;
    _pharmacistNotes = widget.prescription.pharmacistNotes;
    _loadRole();
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('user_role') ?? 'Patient';
    });
  }

  Future<void> _generatePdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("MedEcos Prescription", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Text("Doctor: Dr. ${widget.prescription.doctorName}"),
            pw.Text("Patient: ${widget.prescription.patientName}"),
            pw.Text("Date: ${DateFormat.yMMMd().format(widget.prescription.date)}"),
            pw.Text("Status: $_status"),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Text("Diagnosis: ${widget.prescription.diagnosis}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Text("Medicines:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
            ...widget.prescription.medicines.map((m) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Text("- ${m['name']} (Dosage: ${m['dosage'] ?? 'N/A'}, Freq: ${m['frequency'] ?? 'N/A'}, Dur: ${m['duration'] ?? 'N/A'})"),
            )).toList(),
            pw.SizedBox(height: 20),
            if (widget.prescription.labTests.isNotEmpty) ...[
              pw.Text("Lab Tests:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
              ...widget.prescription.labTests.map((l) => pw.Text("- $l")).toList(),
            ],
            pw.SizedBox(height: 20),
            if (_doctorNotes != null && _doctorNotes!.isNotEmpty) pw.Text("Doctor Notes: $_doctorNotes"),
            if (_pharmacistNotes != null && _pharmacistNotes!.isNotEmpty) pw.Text("Pharmacist Notes: $_pharmacistNotes"),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Prescription_${widget.prescription.id}.pdf',
    );
  }

  Widget _buildDots(String? frequency) {
    if (frequency == null || frequency.isEmpty) return const Text("N/A");
    final parts = frequency.split('-');
    if (parts.length != 4 && parts.length != 3) return Text(frequency);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: parts.map((part) {
        bool isTaken = part.trim() != '0';
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: Icon(
            isTaken ? Icons.circle : Icons.radio_button_unchecked,
            color: isTaken ? AppColors.primary : Colors.grey,
            size: 16,
          ),
        );
      }).toList(),
    );
  }

  void _showAddNotesDialog() {
    _notesController.text = _userRole == 'Doctor' ? (_doctorNotes ?? '') : (_pharmacistNotes ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add ${_userRole == 'Doctor' ? 'Doctor' : 'Pharmacist'} Notes"),
        content: TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Enter notes..."),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                String? newDocNotes = _userRole == 'Doctor' ? _notesController.text : null;
                String? newPharmNotes = _userRole == 'Pharmacist' ? _notesController.text : null;
                
                await ApiService().updatePrescriptionNotes(widget.prescription.id, newDocNotes, newPharmNotes, null);
                setState(() {
                  if (_userRole == 'Doctor') _doctorNotes = _notesController.text;
                  if (_userRole == 'Pharmacist') _pharmacistNotes = _notesController.text;
                });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notes updated successfully')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _toggleStatus() async {
    String newStatus = _status == 'Active' ? 'Past' : 'Active';
    try {
      await ApiService().updatePrescriptionNotes(widget.prescription.id, null, null, newStatus);
      setState(() => _status = newStatus);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status changed to $newStatus')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Prescription Details"),
        actions: [
          IconButton(icon: const Icon(Icons.picture_as_pdf), onPressed: _generatePdf, tooltip: "Save as PDF"),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Diagnosis: ${widget.prescription.diagnosis}", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                Chip(
                  label: Text(_status, style: const TextStyle(color: Colors.white)),
                  backgroundColor: _status == 'Active' ? Colors.green : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text("Patient: ${widget.prescription.patientName}", style: const TextStyle(fontSize: 18)),
            Text("Doctor: Dr. ${widget.prescription.doctorName}", style: const TextStyle(fontSize: 18)),
            Text("Date: ${DateFormat.yMMMd().add_jm().format(widget.prescription.date)}", style: const TextStyle(color: Colors.grey)),
            
            const SizedBox(height: 32),
            const Text("Medicines", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...widget.prescription.medicines.map((m) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(m['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Dosage: ${m['dosage'] ?? 'N/A'} • Duration: ${m['duration'] ?? 'N/A'}"),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("Frequency", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    _buildDots(m['frequency']),
                  ],
                ),
              ),
            )).toList(),

            if (widget.prescription.labTests.isNotEmpty) ...[
              const SizedBox(height: 32),
              const Text("Lab Tests", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...widget.prescription.labTests.map((l) => ListTile(
                leading: const Icon(Icons.science),
                title: Text(l),
              )).toList(),
            ],

            const SizedBox(height: 32),
            const Text("Notes", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Doctor Notes:", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(_doctorNotes?.isNotEmpty == true ? _doctorNotes! : "No notes provided."),
                    const Divider(height: 32),
                    const Text("Pharmacist Notes:", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(_pharmacistNotes?.isNotEmpty == true ? _pharmacistNotes! : "No notes provided."),
                  ],
                ),
              ),
            ),

            if (_userRole == 'Doctor' || _userRole == 'Pharmacist') ...[
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showAddNotesDialog,
                      icon: const Icon(Icons.note_add),
                      label: Text("Add ${_userRole} Notes"),
                    ),
                  ),
                  if (_userRole == 'Doctor') ...[
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: _toggleStatus,
                      child: Text(_status == 'Active' ? "Mark as Past" : "Mark as Active"),
                    ),
                  ]
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }
}
