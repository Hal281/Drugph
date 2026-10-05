import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:drug_dosage_calculator/core/audit/calculation_log.dart';
import 'package:drug_dosage_calculator/core/audit/pdf_report_generator.dart';
import 'package:drug_dosage_calculator/core/models/models.dart';

void main() {
  group('Addendum B4 & E7: PDF Report Generator Tests', () {
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
      dailyDose: 1000.0,
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

    test('E7: Decoupled PdfReportModel contains all required fields without invoking PDF widgets', () {
      final now = DateTime.utc(2026, 10, 5, 12, 30, 0);
      final model = PdfReportGenerator.buildReportModel([log], now: now);

      expect(model.title, isNotEmpty);
      expect(model.subtitle, isNotEmpty);
      expect(model.disclaimer, contains('Educational SaMD Prototype'));
      expect(model.generatedAt, equals(now));
      expect(model.items.length, equals(1));

      final item = model.items.first;
      expect(item.logId, equals('log-test-123'));
      expect(item.userId, equals('pharmacist-user-1'));
      expect(item.patientId, equals('patient-456'));
      expect(item.drugName, equals('Ciprofloxacin'));
      expect(item.calculatedDose, equals(500.0));
      expect(item.roundedDose, equals(500.0));
      expect(item.dailyDose, equals(1000.0));
      expect(item.doseUnit, equals('mg'));
      expect(item.formulaUsed, equals('Weight-based (Devine IBW)'));
      expect(item.patientInputs['weightKg'], equals(70.0));
      expect(item.patientInputs['serumCreatinineMgDl'], equals(1.2));
      expect(item.warningOverridden, isTrue);
      expect(item.overrideJustification, equals('Clinician confirmed high severity infection requiring maximum dose.'));
      expect(item.warnings.length, equals(2));
      expect(item.warnings[0].messageEn, contains('exceeds maximum'));
      expect(item.warnings[0].messageTh, contains('เกินเกณฑ์สูงสุด'));
    });

    test('Builds PDF document with custom theme and saves bytes', () async {
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
      expect(pdfBytes.sublist(0, 5), equals([0x25, 0x50, 0x44, 0x46, 0x2D])); // %PDF-
    });

    test('E7: Builds PDF document using bundled font asset with Thai glyphs', () async {
      final doc = await PdfReportGenerator.buildPdfDocument([log]);
      expect(doc.document.pdfPageList.pages, isNotEmpty);
      final pdfBytes = await doc.save();
      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(1000));
      expect(pdfBytes.sublist(0, 5), equals([0x25, 0x50, 0x44, 0x46, 0x2D]));
    });
  });
}
