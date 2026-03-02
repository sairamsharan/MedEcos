import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/models/lab_report_model.dart';

class PdfReportService {
  static Future<void> generateAndPrintReport({
    required LabReport report,
  }) async {
    final doc = pw.Document();

    // Load Logo
    final Uint8List logoBytes =
        (await rootBundle.load('assets/Icon.jpeg')).buffer.asUint8List();
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
                        pw.Text("MedEcos Diagnostics",
                            style: pw.TextStyle(
                                fontSize: 24,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.teal)),
                      ],
                    ),
                    pw.Text(
                        "Report Date: ${report.dateCompleted.toString().split(' ')[0]}"),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Patient & Ref Info
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("Patient Details",
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey600)),
                        pw.Text(report.patientName,
                            style: pw.TextStyle(
                                fontSize: 18, fontWeight: pw.FontWeight.bold)),
                        pw.Text("ID: ${report.patientId}"),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text("Referred By",
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey600)),
                        pw.Text(report.doctorName,
                            style: pw.TextStyle(
                                fontSize: 16, fontWeight: pw.FontWeight.bold)),
                        pw.Text("Req ID: ${report.requestId}"),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 32),
              pw.Text("DIAGNOSTIC TEST RESULTS",
                  style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.teal)),
              pw.Divider(),
              pw.SizedBox(height: 16),

              // Test Results dynamic iteration
              ...report.testResults.entries.map((entry) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      color: PdfColors.teal50,
                      padding: const pw.EdgeInsets.all(8),
                      width: double.infinity,
                      child: pw.Text(entry.key,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 16, bottom: 24),
                      child:
                          pw.Text(entry.value), // Actual result / text entered
                    ),
                  ],
                );
              }).toList(),

              pw.Spacer(),

              // Footer / Signatures
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("End of Report",
                      style: const pw.TextStyle(color: PdfColors.grey)),
                  pw.Column(
                    children: [
                      pw.SizedBox(height: 40),
                      pw.Text(report.technicianName,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text("Approved By",
                          style: const pw.TextStyle(color: PdfColors.grey)),
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
      name: 'LabReport_${report.id}.pdf',
    );
  }
}
