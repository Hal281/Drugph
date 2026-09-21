import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'calculation_log.dart';
import 'package:intl/intl.dart';

class PdfReportGenerator {
  /// Generates and previews a PDF report of calculation logs.
  static Future<void> generateAndPrint(List<CalculationLog> logs) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm:ss');
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Clinical Dose Calculation Report', 
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
              pw.SizedBox(height: 5),
              pw.Text('Software as a Medical Device (SaMD) Prototype - Audit Log'),
              pw.SizedBox(height: 10),
              pw.Text('Exported on: ${dateFormat.format(DateTime.now())}'),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 10),
            ],
          );
        },
        build: (pw.Context context) {
          if (logs.isEmpty) {
            return [pw.Center(child: pw.Text('No calculation history available.'))];
          }

          return logs.map((log) {
            final hasWarnings = log.result.warnings.isNotEmpty;
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 16),
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(log.drugName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey)),
                      pw.Text(dateFormat.format(log.timestamp), style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
                    ]
                  ),
                  pw.SizedBox(height: 8),
                  if (log.result.success)
                    pw.Text(
                      'Calculated Dose: ${log.result.calculatedDose?.toStringAsFixed(2)} ${log.result.doseUnit?.symbol} ${log.result.frequency}',
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green700),
                    )
                  else
                    pw.Text('Calculation Failed/Error', style: const pw.TextStyle(color: PdfColors.red)),
                  
                  pw.SizedBox(height: 8),
                  pw.Text('Patient Inputs', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  pw.Text('Weight: ${log.inputs['weightKg'] ?? '-'} kg | Height: ${log.inputs['heightCm'] ?? '-'} cm | Age: ${log.inputs['ageYears'] ?? '-'} y'),
                  pw.Text('Sex: ${log.inputs['sex']} | Serum Creatinine: ${log.inputs['scr'] ?? '-'} mg/dL'),
                  
                  if (hasWarnings) ...[
                    pw.SizedBox(height: 8),
                    pw.Text('Safety Warnings (${log.result.warnings.length}):', style: pw.TextStyle(color: PdfColors.orange700, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Please review warnings in the application.', style: const pw.TextStyle(color: PdfColors.orange700, fontSize: 10)),
                  ],

                  pw.SizedBox(height: 12),
                  pw.Text('Audit ID: ${log.logId}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey400)),
                ],
              ),
            );
          }).toList();
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
          );
        }
      ),
    );

    // This will open a print dialog or PDF preview natively on mobile/web/desktop
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Clinical_Dose_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }
}
