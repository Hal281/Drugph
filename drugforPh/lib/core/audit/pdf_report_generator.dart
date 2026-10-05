import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'calculation_log.dart';
import 'package:intl/intl.dart';

class PdfReportGenerator {
  /// Builds the [pw.Document] representing the calculation audit report.
  static Future<pw.Document> buildPdfDocument(
    List<CalculationLog> logs, {
    pw.ThemeData? customTheme,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm:ss');

    // Load Thai font supporting Unicode glyphs
    pw.ThemeData? theme = customTheme;
    if (theme == null) {
      try {
        final thaiFont = await PdfGoogleFonts.sarabunRegular();
        final thaiBoldFont = await PdfGoogleFonts.sarabunBold();
        theme = pw.ThemeData.withFont(base: thaiFont, bold: thaiBoldFont);
      } catch (_) {
        // Fallback to default theme if network unavailable
        theme = null;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: theme,
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Clinical Dose Calculation Audit Report',
                style: const pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey800,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Educational SaMD Prototype — Designed for Traceability & Audit Logging',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Generated: ${dateFormat.format(DateTime.now())} (UTC)',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 8),
            ],
          );
        },
        build: (pw.Context context) {
          if (logs.isEmpty) {
            return [
              pw.Center(
                child: pw.Text('No calculation history records available.'),
              ),
            ];
          }

          return logs.map((log) {
            final res = log.result;
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 14),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        log.drugName,
                        style: const pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey800,
                        ),
                      ),
                      pw.Text(
                        dateFormat.format(log.timestamp),
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  if (res.success) ...[
                    pw.Text(
                      'Calculated Dose: ${res.calculatedDose?.toStringAsFixed(2)} ${res.doseUnit?.symbol ?? ""} ${res.frequency ?? ""}',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green800,
                      ),
                    ),
                    if (res.roundedDose != null)
                      pw.Text(
                        'Formulary Rounded Dose: ${res.roundedDose!.toStringAsFixed(2)} ${res.doseUnit?.symbol ?? ""}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.teal800,
                        ),
                      ),
                    if (res.dailyDose != null)
                      pw.Text(
                        'Total Daily Dose: ${res.dailyDose!.toStringAsFixed(2)} ${res.doseUnit?.symbol ?? ""}/day',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                      ),
                  ] else ...[
                    pw.Text(
                      'Calculation Failed / Blocked: ${res.errorMessage ?? "Unknown"}',
                      style: const pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red800,
                      ),
                    ),
                    if (res.errorMessageTh != null)
                      pw.Text(
                        'ข้อผิดพลาด: ${res.errorMessageTh}',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.red700),
                      ),
                  ],
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Formula: ${log.formulaUsed}',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Patient Inputs: Weight: ${log.inputs['weightKg'] ?? '-'} kg | Height: ${log.inputs['heightCm'] ?? '-'} cm | Age: ${log.inputs['ageYears'] ?? '-'} y | SCr: ${log.inputs['serumCreatinineMgDl'] ?? log.inputs['scr'] ?? '-'} mg/dL',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                  ),
                  if (log.warningOverridden) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '⚠️ Warnings Overridden by Clinician (${log.userId}): ${log.overrideJustification ?? "N/A"}',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.deepOrange800),
                    ),
                  ],
                  if (res.warnings.isNotEmpty) ...[
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Safety Warnings (${res.warnings.length}):',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.orange900,
                      ),
                    ),
                    ...res.warnings.map(
                      (w) => pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 2, left: 6),
                        child: pw.Text(
                          '• [${w.severity.labelEn}] ${w.messageEn}\n   (${w.messageTh})',
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.orange800),
                        ),
                      ),
                    ),
                  ],
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Audit ID: ${log.logId} | Clinician: ${log.userId}',
                    style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500),
                  ),
                ],
              ),
            );
          }).toList();
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(top: 8),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Educational SaMD Prototype — Not for Real Patient Use',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf;
  }

  /// Generates and previews a PDF report of calculation logs with Thai font support.
  static Future<void> generateAndPrint(List<CalculationLog> logs) async {
    final pdf = await buildPdfDocument(logs);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Clinical_Dose_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }
}
