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

  group('Clinical Safety & Boundary Tests', () {
    test('CrCl decimal boundary: contiguous half-open ranges [25, 50) and [10, 25) leave zero gaps', () {
      const tier1 = RenalAdjustment(crclMin: 25, crclMax: 50, adjustmentFactor: 1.0);
      const tier2 = RenalAdjustment(crclMin: 10, crclMax: 25, adjustmentFactor: 0.5);

      // CrCl 25.5 falls in tier1 [25, 50)
      expect(tier1.appliesTo(25.5), isTrue);

      // CrCl 25.0 falls in tier1 [25, 50)
      expect(tier1.appliesTo(25.0), isTrue);

      // CrCl 24.9 falls in tier2 [10, 25)
      expect(tier2.appliesTo(24.9), isTrue);

      // CrCl 10.0 falls in tier2 [10, 25)
      expect(tier2.appliesTo(10.0), isTrue);
    });

    test('Vancomycin AUC24 steady-state calculation', () {
      // Dose 1000 mg q12h (2000 mg/day), Vd = 45 L, Ke = 0.05 hr^-1 -> Cl = 2.25 L/hr
      // AUC24 = 2000 / 2.25 = 888.88 mg*hr/L (supratherapeutic)
      final auc = TdmCalculator.calculateAuc24(dose: 1000, tau: 12, vd: 45, ke: 0.05);
      expect(auc, closeTo(888.89, 0.1));

      // Dose 750 mg q12h (1500 mg/day), Cl = 3.0 L/hr -> AUC24 = 500 mg*hr/L (target 400-600)
      final targetAuc = TdmCalculator.calculateAuc24(dose: 750, tau: 12, vd: 50, ke: 0.06);
      expect(targetAuc, closeTo(500.0, 0.1));
    });

    test('Aminoglycoside dosing weight in obese patient uses AdjBW', () {
      // Patient: Height 170cm Male (IBW = 65.94 kg), Weight 120 kg (Obese, 182% IBW)
      final ibw = WeightBasedCalculator.idealBodyWeight(heightCm: 170, sex: Sex.male);
      expect(WeightBasedCalculator.isObese(actualWeightKg: 120, ibwKg: ibw), isTrue);

      // AdjBW = 65.94 + 0.4 * (120 - 65.94) = 87.56 kg
      final adjBw = WeightBasedCalculator.adjustedBodyWeight(actualWeightKg: 120, ibwKg: ibw);
      expect(adjBw, closeTo(87.56, 0.1));

      // Dose at 5 mg/kg should use AdjBW (437.8 mg), NOT TBW (600 mg)!
      final safeDose = WeightBasedCalculator.calculateDose(weightKg: adjBw, dosePerKg: 5.0);
      expect(safeDose, closeTo(437.81, 0.1));
    });
  });
}

