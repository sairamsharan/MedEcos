import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/src/widgets/table_helper.dart';

class PdfService {
  static Future<void> generateAndPrintPrescription({
    required String doctorName,
    required String patientName,
    required String patientId,
    required String prescriptionId,
    required String symptoms,
    required List<Map<String, String>> medicines,
    required List<String> labTests,
    required String date,
    String? digitalSignature,    // Base64 RSA-2048 signature
    String? signerPublicKeyJson, // Doctor's public key JSON
  }) async {
    final fontRegular = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
    );

    final Uint8List logoBytes =
        (await rootBundle.load('assets/Icon.jpeg')).buffer.asUint8List();
    final logoImage = pw.MemoryImage(logoBytes);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(children: [
                    pw.Image(logoImage, height: 50, width: 50),
                    pw.SizedBox(width: 16),
                    pw.Text('MedEcos Clinic',
                        style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.teal)),
                  ]),
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Date: $date'),
                        pw.Text('Ref: $prescriptionId',
                            style: const pw.TextStyle(
                                fontSize: 8, color: PdfColors.grey600)),
                      ]),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // ── Doctor & Patient Info ──────────────────────────────────────
            pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(doctorName,
                            style: pw.TextStyle(
                                fontSize: 18,
                                fontWeight: pw.FontWeight.bold)),
                        pw.Text('Cardiologist'),
                      ]),
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Patient: $patientName',
                            style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold)),
                        pw.Text('ID: $patientId'),
                      ]),
                ]),
            pw.Divider(),
            pw.SizedBox(height: 20),

            // ── Symptoms ──────────────────────────────────────────────────
            pw.Text('Diagnosis / Symptoms:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(symptoms),
            pw.SizedBox(height: 20),

            // ── Medicines Table ───────────────────────────────────────────
            TableHelper.fromTextArray(
              context: ctx,
              border: null,
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.teal),
              rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(
                      bottom:
                          pw.BorderSide(color: PdfColors.grey300))),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.center,
                3: pw.Alignment.center,
                4: pw.Alignment.centerLeft,
              },
              data: <List<String>>[
                ['Medicine', 'Timing', 'Duration', 'Context', 'Instructions'],
                ...medicines.map((m) => [
                      m['name']!,
                      m['timing']!,
                      m['duration'] ?? '-',
                      m['context']!,
                      m['instruction']!,
                    ]),
              ],
            ),

            if (labTests.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              pw.Text('Recommended Lab Tests:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: labTests.map((t) => pw.Bullet(text: t)).toList(),
              ),
            ],

            pw.Spacer(),

            // ── Footer: Digital Signature Block ───────────────────────────
            pw.Divider(),
            _buildFooter(
              prescriptionId: prescriptionId,
              doctorName: doctorName,
              digitalSignature: digitalSignature,
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => doc.save(),
      name: 'Prescription_$patientId.pdf',
    );
  }

  // ── Footer ──────────────────────────────────────────────────────────────────

  static pw.Widget _buildFooter({
    required String prescriptionId,
    required String doctorName,
    String? digitalSignature,
  }) {
    if (digitalSignature == null) {
      return pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Get well soon!',
              style: const pw.TextStyle(color: PdfColors.grey)),
          pw.Text('$doctorName — Authorised Signatory',
              style: const pw.TextStyle(
                  fontSize: 10, color: PdfColors.grey600)),
        ],
      );
    }

    // Signature preview: first 48 chars + ellipsis
    final sigPreview = '${digitalSignature.substring(0, 48)}…';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Get well soon!',
            style: const pw.TextStyle(color: PdfColors.grey)),
        pw.SizedBox(height: 8),
        pw.Container(
          padding:
              const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.teal300, width: 0.8),
            borderRadius:
                const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(children: [
                pw.Text('✓ ',
                    style: pw.TextStyle(
                        color: PdfColors.teal700,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10)),
                pw.Text(
                    'Cryptographically Signed — RSA-2048 / SHA-256',
                    style: pw.TextStyle(
                        color: PdfColors.teal800,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9)),
              ]),
              pw.SizedBox(height: 4),
              pw.Text('Signer: $doctorName',
                  style: const pw.TextStyle(
                      fontSize: 8, color: PdfColors.grey700)),
              pw.Text('Algorithm: RSASSA-PKCS1-v1_5 with SHA-256',
                  style: const pw.TextStyle(
                      fontSize: 7, color: PdfColors.grey600)),
              pw.Text('Prescription ID: $prescriptionId',
                  style: const pw.TextStyle(
                      fontSize: 7, color: PdfColors.grey600)),
              pw.SizedBox(height: 2),
              pw.Text('Sig: $sigPreview',
                  style: const pw.TextStyle(
                      fontSize: 7, color: PdfColors.grey600)),
            ],
          ),
        ),
      ],
    );
  }
}
