import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart' show WidgetsFlutterBinding;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import 'calculation_log.dart';

/// Structured warning entry in the PDF report model (E7).
class PdfReportWarning {
  final String severity;
  final String messageEn;
  final String messageTh;

  const PdfReportWarning({
    required this.severity,
    required this.messageEn,
    required this.messageTh,
  });
}

/// Structured calculation record in the PDF report model (E7, F5).
class PdfReportItem {
  final String logId;
  final String userId;
  final String? patientId;
  final String drugName;
  final String? indication;
  final String route;
  final DateTime timestamp;
  final bool success;
  final bool isBlocked;
  final bool hasHardWarning;
  final String softwareVersion;
  final double? crcl;
  final double? dosingWeight;
  final VerificationStatus verificationStatus;
  final double? calculatedDose;
  final double? roundedDose;
  final double? dailyDose;
  final String? doseUnit;
  final String? frequency;
  final String? errorMessageEn;
  final String? errorMessageTh;
  final String formulaUsed;
  final CalculationInputs patientInputs;
  final bool warningOverridden;
  final String? overrideJustification;
  final List<PdfReportWarning> warnings;

  const PdfReportItem({
    required this.logId,
    required this.userId,
    required this.patientId,
    required this.drugName,
    required this.indication,
    required this.route,
    required this.timestamp,
    required this.success,
    required this.isBlocked,
    required this.hasHardWarning,
    required this.softwareVersion,
    this.crcl,
    this.dosingWeight,
    required this.verificationStatus,
    this.calculatedDose,
    this.roundedDose,
    this.dailyDose,
    this.doseUnit,
    this.frequency,
    this.errorMessageEn,
    this.errorMessageTh,
    required this.formulaUsed,
    required this.patientInputs,
    required this.warningOverridden,
    this.overrideJustification,
    required this.warnings,
  });
}

/// Pure data model representing the audit report, decoupled from rendering (E7).
class PdfReportModel {
  final String title;
  final String subtitle;
  final String disclaimer;
  final DateTime generatedAt;
  final List<PdfReportItem> items;

  const PdfReportModel({
    required this.title,
    required this.subtitle,
    required this.disclaimer,
    required this.generatedAt,
    required this.items,
  });
}

class PdfReportGenerator {
  /// Transforms raw logs into a decoupled [PdfReportModel] without invoking PDF widgets (E7, F5).
  static PdfReportModel buildReportModel(
    List<CalculationLog> logs, {
    DateTime? now,
  }) {
    final generatedAt = (now ?? DateTime.now()).toUtc();
    final items = logs.map((log) {
      final res = log.result;
      final inputs = log.calculationInputs ?? CalculationInputs.fromMap(log.inputs);
      final crcl = res.crclMlMin ?? inputs.creatinineClearanceMlMin;
      final dosingWeight = (res.calculationInputs['dosingWeightUsedKg'] as num?)?.toDouble() ??
          inputs.weightKg;
      final verificationStatus = res.verificationStatus;

      return PdfReportItem(
        logId: log.logId,
        userId: log.userId,
        patientId: log.patientId,
        drugName: log.drugName,
        indication: log.indication,
        route: log.route,
        timestamp: log.timestamp.isUtc ? log.timestamp : log.timestamp.toUtc(),
        success: res.success,
        isBlocked: res.isBlocked,
        hasHardWarning: res.hasHardWarning,
        softwareVersion: log.softwareVersion,
        crcl: crcl,
        dosingWeight: dosingWeight,
        verificationStatus: verificationStatus,
        calculatedDose: res.calculatedDose,
        roundedDose: res.roundedDose,
        dailyDose: res.dailyDose,
        doseUnit: res.doseUnit?.symbol,
        frequency: res.frequency,
        errorMessageEn: res.errorMessage,
        errorMessageTh: res.errorMessageTh,
        formulaUsed: log.formulaUsed,
        patientInputs: inputs,
        warningOverridden: log.warningOverridden,
        overrideJustification: log.overrideJustification,
        warnings: res.warnings
            .map((w) => PdfReportWarning(
                  severity: w.severity.labelEn,
                  messageEn: w.messageEn,
                  messageTh: w.messageTh,
                ))
            .toList(),
      );
    }).toList();

    return PdfReportModel(
      title: 'Clinical Dose Calculation Audit Report',
      subtitle: 'Educational SaMD Prototype — Designed for Traceability & Audit Logging',
      disclaimer: 'Educational SaMD Prototype — Not for Real Patient Use',
      generatedAt: generatedAt,
      items: items,
    );
  }

  /// Builds the [pw.Document] representing the calculation audit report.
  static Future<pw.Document> buildPdfDocument(
    List<CalculationLog> logs, {
    pw.ThemeData? customTheme,
  }) async {
    final model = buildReportModel(logs);
    return buildPdfDocumentFromModel(model, customTheme: customTheme);
  }

  /// Builds the [pw.Document] from a [PdfReportModel] with bundled Unicode font support (F5).
  static Future<pw.Document> buildPdfDocumentFromModel(
    PdfReportModel model, {
    pw.ThemeData? customTheme,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm:ss');

    // Load font supporting Unicode & Thai glyphs via rootBundle (no dart:io, F5)
    pw.ThemeData? theme = customTheme;
    if (theme == null) {
      try {
        WidgetsFlutterBinding.ensureInitialized();
        final fontData = await rootBundle.load('assets/fonts/ThaiFont.ttf');
        final ttf = pw.Font.ttf(fontData);
        theme = pw.ThemeData.withFont(base: ttf, bold: ttf);
      } catch (e) {
        throw StateError(
          'CRITICAL AUDIT ERROR: Failed to load required bundled Unicode font "assets/fonts/ThaiFont.ttf" via rootBundle: $e. Font asset must be declared in pubspec.yaml and present in assets/fonts/.',
        );
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
                model.title,
                style: const pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey800,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                model.subtitle,
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Generated: ${dateFormat.format(model.generatedAt.toUtc())} UTC',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 8),
            ],
          );
        },
        build: (pw.Context context) {
          if (model.items.isEmpty) {
            return [
              pw.Center(
                child: pw.Text('No calculation history records available.'),
              ),
            ];
          }

          return model.items.map((item) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 14),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: item.isBlocked ? PdfColors.red300 : PdfColors.grey300,
                  width: item.isBlocked ? 1.5 : 1.0,
                ),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                color: item.isBlocked ? PdfColors.red50 : null,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        item.drugName,
                        style: const pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey800,
                        ),
                      ),
                      pw.Text(
                        'Status: ${item.verificationStatus.name.toUpperCase()} | v${item.softwareVersion} | ${dateFormat.format(item.timestamp)} UTC',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  if (item.isBlocked) ...[
                    // Blocked results never render a green dose (F5)
                    pw.Text(
                      'BLOCKED — SAFETY LIMIT EXCEEDED / CALCULATION FAILED',
                      style: const pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red800,
                      ),
                    ),
                    if (item.errorMessageEn != null)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 2),
                        child: pw.Text(
                          'Reason: ${item.errorMessageEn}',
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.red700),
                        ),
                      ),
                    if (item.errorMessageTh != null)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 2),
                        child: pw.Text(
                          'ข้อผิดพลาด: ${item.errorMessageTh}',
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.red700),
                        ),
                      ),
                  ] else if (item.success) ...[
                    pw.Text(
                      'Calculated Dose: ${item.calculatedDose?.toStringAsFixed(2)} ${item.doseUnit ?? ""} ${item.frequency ?? ""}',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green800,
                      ),
                    ),
                    if (item.roundedDose != null)
                      pw.Text(
                        'Formulary Rounded Dose: ${item.roundedDose!.toStringAsFixed(2)} ${item.doseUnit ?? ""}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.teal800,
                        ),
                      ),
                    if (item.dailyDose != null)
                      pw.Text(
                        'Total Daily Dose: ${item.dailyDose!.toStringAsFixed(2)} ${item.doseUnit ?? ""}/day',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                      ),
                  ] else ...[
                    pw.Text(
                      'Calculation Failed: ${item.errorMessageEn ?? "Unknown"}',
                      style: const pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red800,
                      ),
                    ),
                    if (item.errorMessageTh != null)
                      pw.Text(
                        'ข้อผิดพลาด: ${item.errorMessageTh}',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.red700),
                      ),
                  ],
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Formula: ${item.formulaUsed} | CrCl: ${item.crcl != null ? "${item.crcl!.toStringAsFixed(1)} mL/min" : "N/A"} | Dosing Weight: ${item.dosingWeight != null ? "${item.dosingWeight!.toStringAsFixed(1)} kg" : "N/A"}',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Patient Inputs: Weight: ${item.patientInputs.weightKg ?? "-"} kg | Height: ${item.patientInputs.heightCm ?? "-"} cm | Age: ${item.patientInputs.ageYears ?? "-"} y | SCr: ${item.patientInputs.serumCreatinineMgDl ?? "-"} mg/dL',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                  ),
                  if (item.warningOverridden) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '⚠️ Warnings Overridden by Clinician (${item.userId}): ${item.overrideJustification ?? "N/A"}',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.deepOrange800),
                    ),
                  ],
                  if (item.warnings.isNotEmpty) ...[
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Safety Warnings (${item.warnings.length}):',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.orange900,
                      ),
                    ),
                    ...item.warnings.map(
                      (w) => pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 2, left: 6),
                        child: pw.Text(
                          '• [${w.severity}] ${w.messageEn}\n   (${w.messageTh})',
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.orange800),
                        ),
                      ),
                    ),
                  ],
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Audit ID: ${item.logId} | Clinician: ${item.userId}',
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
                  model.disclaimer,
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
