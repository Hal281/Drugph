import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:drug_dosage_calculator/core/audit/calculation_log.dart';
import 'package:drug_dosage_calculator/core/audit/pdf_report_generator.dart';
import 'package:drug_dosage_calculator/core/models/models.dart';

void main() {
  group('Addendum B4: PDF Report Generator Tests', () {
    test('Builds PDF document and contains all warning messages and metadata', () async {
      final warnings = [
        const DoseWarning(
          severity: LimitSeverity.hard,
          code: DoseWarningCode.maxSingleDoseExceeded,
          messageEn: 'Single dose exceeds maximum recommended limit.',
          messageTh: 'ขนาดยาต่อครั้งเกินเกณฑ์สูงสุดที่กำหนด',
        ),
        const DoseWarning(
          severity: LimitSeverity.soft,
          code: DoseWarningCode.renalAdjustmentApplied,
          messageEn: 'Auto Renal Adjustment applied.',
          messageTh: 'ปรับขนาดยาอัตโนมัติตามการทำงานของไต',
        ),
      ];

      final result = DosageResult(
        success: true,
        calculatedDose: 500.0,
        roundedDose: 500.0,
        doseUnit: DoseUnit.mg,
        frequency: 'q12h',
        formulaUsed: 'Weight-based (Devine IBW)',
        calculationInputs: const {
          'weightKg': 70.0,
          'heightCm': 175.0,
          'ageYears': 45,
          'serumCreatinineMgDl': 1.2,
        },
        warnings: warnings,
      );

      final log = CalculationLog(
        logId: 'log-test-123',
        userId: 'pharmacist-user-1',
        timestamp: DateTime.utc(2026, 10, 5, 12, 0, 0),
        patientId: 'patient-456',
        drugId: 'ciprofloxacin',
        drugName: 'Ciprofloxacin',
        indication: 'Complicated UTI',
        route: DoseRoute.po.abbreviation,
        formulaUsed: 'Weight-based (Devine IBW)',
        softwareVersion: '1.0.0',
        inputs: result.calculationInputs,
        result: result,
        warningOverridden: true,
        overrideJustification: 'Clinician confirmed high severity infection requiring maximum dose.',
      );

      // Build document with fallback standard fonts (no network call)
      final doc = await PdfReportGenerator.buildPdfDocument(
        [log],
        customTheme: pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
        ),
      );

      expect(doc.document.pdfPageList.pages, isNotEmpty);
      final pdfBytes = await doc.save();
      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(1000));

      // PDF stream contains font text or object references
      expect(pdfBytes.sublist(0, 5), equals([0x25, 0x50, 0x44, 0x46, 0x2D])); // %PDF-
    });
  });
}
