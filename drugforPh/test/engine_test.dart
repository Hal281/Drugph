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
    const limits = DoseLimit(
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

  group('Weight-Based & Calvert Calculator Tests', () {
    test('Devine IBW Male', () {
      // 175 cm = 68.8976 inches -> 50 + 2.3 * 8.8976 = 70.46 kg
      final ibw = WeightBasedCalculator.idealBodyWeight(heightCm: 175, sex: Sex.male);
      expect(ibw, closeTo(70.46, 0.1));
    });

    test('Devine IBW Female', () {
      // 165 cm = 64.96 inches -> 45.5 + 2.3 * 4.96 = 56.91 kg
      final ibw = WeightBasedCalculator.idealBodyWeight(heightCm: 165, sex: Sex.female);
      expect(ibw, closeTo(56.91, 0.1));
    });

    test('Adjusted Body Weight (AdjBW)', () {
      // IBW = 50 kg, Actual = 80 kg -> 50 + 0.4 * (80 - 50) = 62.0 kg
      final adjBw = WeightBasedCalculator.adjustedBodyWeight(actualWeightKg: 80, ibwKg: 50);
      expect(adjBw, equals(62.0));
    });

    test('Calvert Formula for Carboplatin with GFR cap at 125', () {
      // AUC = 5, GFR = 150 (capped at 125) -> 5 * (125 + 25) = 750 mg
      final dose = WeightBasedCalculator.calvertFormula(targetAuc: 5, gfrMlMin: 150);
      expect(dose, equals(750.0));

      // AUC = 6, GFR = 75 -> 6 * (75 + 25) = 600 mg
      final normalDose = WeightBasedCalculator.calvertFormula(targetAuc: 6, gfrMlMin: 75);
      expect(normalDose, equals(600.0));
    });
  });
}

