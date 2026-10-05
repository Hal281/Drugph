import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/models/dose_limit.dart';
import 'package:drug_dosage_calculator/core/models/dosage_result.dart';
import 'package:drug_dosage_calculator/core/models/unit.dart';
import 'package:drug_dosage_calculator/core/audit/calculation_log.dart';

void main() {
  group('Models & Safety Flags (A3, A9, A10)', () {
    test('A3: DosageResult isBlocked is true when success is false or hard limit violated', () {
      final failedResult = DosageResult.failure(
        reasonEn: 'Invalid age',
        reasonTh: 'อายุไม่ถูกต้อง',
        warnings: const [
          DoseWarning(
            severity: LimitSeverity.hard,
            messageEn: 'Age < 18 not supported',
            messageTh: 'ไม่รองรับผู้ป่วยอายุน้อยกว่า 18 ปี',
            code: DoseWarningCode.pediatricBlocked,
          ),
        ],
      );
      expect(failedResult.success, isFalse);
      expect(failedResult.isBlocked, isTrue);
      expect(failedResult.errorMessage, equals('Invalid age'));
      expect(failedResult.errorMessageTh, equals('อายุไม่ถูกต้อง'));

      const hardWarnResult = DosageResult(
        success: true,
        formulaUsed: 'Test',
        calculatedDose: 500,
        warnings: [
          DoseWarning(
            severity: LimitSeverity.hard,
            messageEn: 'Dose exceeds hard limit',
            messageTh: 'ขนาดยาเกินเกณฑ์อันตราย',
            code: DoseWarningCode.maxSingleDoseExceeded,
          ),
        ],
      );
      expect(hardWarnResult.success, isTrue);
      expect(hardWarnResult.hasHardLimitViolation, isTrue);
      expect(hardWarnResult.isBlocked, isTrue);
    });

    test('A10: DoseWarning has machine-readable code enum', () {
      const warning = DoseWarning(
        severity: LimitSeverity.hard,
        messageEn: 'Missing SCr',
        messageTh: 'ไม่ระบุค่า SCr',
        code: DoseWarningCode.scrMissing,
      );
      expect(warning.code, equals(DoseWarningCode.scrMissing));
    });

    test('A9: DoseRoute does not contain duplicate inhaled', () {
      final names = DoseRoute.values.map((r) => r.name).toList();
      expect(names.contains('inhaled'), isFalse, reason: 'Duplicate inhaled must be removed');
      expect(names.contains('inhalation'), isTrue);
      expect(names.contains('iv'), isTrue);
      expect(names.contains('ivPush'), isTrue);
      expect(names.contains('ivInfusion'), isTrue);
    });

    test('B1: CalculationLog converts timestamp to UTC, has unmodifiable inputs, and enforces justification', () {
      final localTime = DateTime(2026, 10, 5, 12, 0, 0);
      final rawInputs = {'weightKg': 70.0, 'scr': 1.0};
      final log = CalculationLog(
        logId: 'log-001',
        timestamp: localTime,
        userId: 'MD-123',
        drugName: 'Vancomycin',
        drugId: 'vancomycin',
        route: 'iv',
        inputs: rawInputs,
        result: const DosageResult(success: true, formulaUsed: 'Matzke PK', calculatedDose: 1000),
        formulaUsed: 'Matzke PK',
        softwareVersion: '0.1.0',
      );

      expect(log.timestamp.isUtc, isTrue);
      expect(() => (log.inputs as Map)['weightKg'] = 80.0, throwsUnsupportedError);

      // Warning overridden without justification must throw AssertionError
      expect(
        () => CalculationLog(
          logId: 'log-002',
          timestamp: DateTime.now(),
          userId: 'MD-123',
          drugName: 'Vancomycin',
          drugId: 'vancomycin',
          route: 'iv',
          inputs: rawInputs,
          result: const DosageResult(success: true, formulaUsed: 'Test'),
          formulaUsed: 'Test',
          softwareVersion: '0.1.0',
          warningOverridden: true,
          overrideJustification: '',
        ),
        throwsA(isA<AssertionError>()),
      );

      // Serialization round-trip
      final json = log.toJson();
      final restored = CalculationLog.fromJson(json);
      expect(restored.logId, equals(log.logId));
      expect(restored.timestamp, equals(log.timestamp));
      expect(restored.calculationInputs?.weightKg, equals(70.0));
      expect(restored.calculationInputs?.serumCreatinineMgDl, equals(1.0));
    });
  });
}
