import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  static Future<void> generateAndPrintPrescription({
    required String pharmacistName,
    required String patientName,
    required String patientId,
    required String symptoms,
    required List<Map<String, String>> medicines,
    required List<String> labTests,
    required String date,
  }) async {
    final doc = pw.Document();
    
    // Load Logo
    final Uint8List logoBytes = (await rootBundle.load('assets/Icon.jpeg')).buffer.asUint8List();
    final logoImage = pw.MemoryImage(logoBytes);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Row(
                      children: [
                        pw.Image(logoImage, height: 50, width: 50),
                        pw.SizedBox(width: 16),
                        pw.Text("MedEcos Pharmacy", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.teal)),
                      ],
                    ),
                    pw.Text("Date: $date"),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Pharmacist & Patient Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                   pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(pharmacistName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      pw.Text("Pharmacist"),
                    ],
                   ),
                   pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("Patient: $patientName", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.Text("ID: $patientId"),
                    ],
                   ),
                ],
              ),
              pw.Divider(),
              pw.SizedBox(height: 20),
              
              // Symptoms
              pw.Text("Diagnosis / Symptoms:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(symptoms),
              pw.SizedBox(height: 20),
              
              // Medicines Table
              pw.Table.fromTextArray(
                context: context,
                border: null,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
                rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerLeft,
                },
                data: <List<String>>[
                  ['Medicine', 'Timing', 'Context', 'Instructions'],
                  ...medicines.map((m) => [
                    m['name']!,
                    m['timing']!,
                    m['context']!,
                    m['instruction']!
                  ]),
                ],
              ),
              
              if (labTests.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Text("Recommended Lab Tests:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: labTests.map((test) => pw.Bullet(text: test)).toList(),
                ),
              ],
              
              pw.Spacer(),
              
              // Footer
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Get well soon!", style: const pw.TextStyle(color: PdfColors.grey)),
                  pw.Column(
                    children: [
                       pw.SizedBox(height: 40),
                       pw.Text("Pharmacist's Signature", style: const pw.TextStyle(decoration: pw.TextDecoration.overline)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Prescription_$patientId.pdf',
    );
  }
}
