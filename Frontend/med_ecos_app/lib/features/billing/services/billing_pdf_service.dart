import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class BillingPdfService {
  static Future<void> generateAndPrintBill(Map<String, dynamic> billData) async {
    final pdf = pw.Document();

    final date = DateFormat.yMMMd().add_jm().format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text("MedEcos Pharmacy", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text("Invoice", style: pw.TextStyle(fontSize: 18)),
              ),
              pw.SizedBox(height: 24),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("Patient: ${billData['patientName'] ?? 'Guest'}"),
                      pw.Text("ABHA ID: ${billData['abhaId'] ?? 'N/A'}"),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("Date: $date"),
                      if (billData['prescriptionId'] != null)
                        pw.Text("Linked Rx: ${billData['prescriptionId']}"),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Table.fromTextArray(
                context: context,
                border: null,
                headerAlignment: pw.Alignment.centerLeft,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.centerLeft,
                headers: ['Item', 'Quantity', 'Price/Unit', 'Total'],
                data: (billData['medicines'] as List<dynamic>).map((item) {
                  return [
                    item['medicineName'],
                    item['quantity'].toString(),
                    "Rs. ${item['pricePerUnit'].toStringAsFixed(2)}",
                    "Rs. ${item['total'].toStringAsFixed(2)}",
                  ];
                }).toList(),
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text("Grand Total: ", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.Text("Rs. ${billData['grandTotal'].toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 40),
              pw.Center(
                child: pw.Text("Thank you for choosing MedEcos!", style: const pw.TextStyle(fontSize: 14)),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'MedEcos_Bill_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }
}
