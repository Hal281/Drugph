import 'package:test/test.dart';
import 'package:drug_dosage_calculator/core/calculators/calculators.dart';
import 'package:drug_dosage_calculator/core/models/models.dart';

void main() {
  group('BSA Calculator Tests', () {
    test('Mosteller formula', () {
      final bsa = BsaCalculator.mosteller(heightCm: 170, weightKg: 70);
      expect(bsa, closeTo(1.818, 0.001)); // sqrt((170*70)/3600) = 1.8181...
    });

    test('DuBois formula', () {
      final bsa = BsaCalculator.dubois(heightCm: 170, weightKg: 70);
      expect(bsa, closeTo(1.810, 0.001)); 
    });
  });

  group('Renal Calculator Tests', () {
    test('Cockcroft-Gault Male', () {
      final crcl = RenalCalculator.cockcroftGault(
        ageYears: 65,
        weightKg: 70,
        sex: Sex.male,
        serumCreatinineMgDl: 1.2,
      );
      // ((140-65) * 70) / (72 * 1.2) = 5250 / 86.4 = 60.76...
      expect(crcl, closeTo(60.76, 0.01));
    });

    test('Cockcroft-Gault Female', () {
      final crcl = RenalCalculator.cockcroftGault(
        ageYears: 65,
        weightKg: 70,
        sex: Sex.female,
        serumCreatinineMgDl: 1.2,
      );
      // 60.76... * 0.85 = 51.65...
      expect(crcl, closeTo(51.65, 0.01));
    });
    test('CKD-EPI 2021 Female', () {
      final egfr = RenalCalculator.ckdEpi2021(
        ageYears: 50,
        sex: Sex.female,
        serumCreatinineMgDl: 1.0,
      );
      expect(egfr, closeTo(68.6, 0.1));
    });

    test('CKD-EPI 2021 Male', () {
      final egfr = RenalCalculator.ckdEpi2021(
        ageYears: 50,
        sex: Sex.male,
        serumCreatinineMgDl: 1.0,
      );
      expect(egfr, closeTo(91.7, 0.1));
    });
  });

  group('Dose Checker Tests', () {
    final limits = DoseLimit(
      maxSingleDose: 1000.0,
      softMaxSingleDose: 800.0,
      minSingleDose: 100.0,
    );

    test('Within limits', () {
      final warnings = DoseChecker.checkDose(
        calculatedDose: 500.0,
        limits: limits,
      );
      expect(warnings, isEmpty);
    });

    test('Exceeds hard limit', () {
      final warnings = DoseChecker.checkDose(
        calculatedDose: 1200.0,
        limits: limits,
      );
      expect(warnings.length, equals(1));
      expect(warnings.first.severity, equals(LimitSeverity.hard));
    });

    test('Exceeds soft limit', () {
      final warnings = DoseChecker.checkDose(
        calculatedDose: 900.0,
        limits: limits,
      );
      expect(warnings.length, equals(1));
      expect(warnings.first.severity, equals(LimitSeverity.soft));
    });
  });
}

