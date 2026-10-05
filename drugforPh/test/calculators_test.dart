import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/calculators/unit_converter.dart';
import 'package:drug_dosage_calculator/core/calculators/dose_rounder.dart';
import 'package:drug_dosage_calculator/core/calculators/dose_checker.dart';
import 'package:drug_dosage_calculator/core/calculators/tdm_calculator.dart';
import 'package:drug_dosage_calculator/core/models/drug.dart';
import 'package:drug_dosage_calculator/core/models/dose_limit.dart';
import 'package:drug_dosage_calculator/core/validators/input_validator.dart';

void main() {
  group('Step 2: Core Calculators & Safety Enhancements', () {
    // -------------------------------------------------------------------------
    // UnitConverter (4.2, 4.8)
    // -------------------------------------------------------------------------
    test('4.2: SCr unit conversion between umol/L and mg/dL (factor 88.4)', () {
      // 88.4 umol/L == 1.0 mg/dL
      expect(UnitConverter.scrUmolPerLToMgPerDl(88.4), closeTo(1.0, 0.001));
      expect(UnitConverter.scrMgPerDlToUmolPerL(1.0), closeTo(88.4, 0.001));
      // 176.8 umol/L == 2.0 mg/dL
      expect(UnitConverter.scrUmolPerLToMgPerDl(176.8), closeTo(2.0, 0.001));
    });

    test('4.8: lb/kg and in/cm unit conversions', () {
      expect(UnitConverter.lbToKg(154.32358), closeTo(70.0, 0.01));
      expect(UnitConverter.kgToLb(70.0), closeTo(154.32, 0.05));
      expect(UnitConverter.inToCm(70.0), closeTo(177.8, 0.01));
      expect(UnitConverter.cmToIn(177.8), closeTo(70.0, 0.01));
    });

    test('4.2 & 4.8: dosesPerDay handles standard frequencies and returns 0 for unsupported/variable frequencies', () {
      // Standard
      expect(UnitConverter.dosesPerDay('q8h'), equals(3.0));
      expect(UnitConverter.dosesPerDay('q12h'), equals(2.0));
      expect(UnitConverter.dosesPerDay('bid'), equals(2.0));
      expect(UnitConverter.dosesPerDay('tid'), equals(3.0));
      expect(UnitConverter.dosesPerDay('qid'), equals(4.0));
      expect(UnitConverter.dosesPerDay('daily'), equals(1.0));

      // Unsupported / variable / continuous intervals must return 0
      expect(UnitConverter.dosesPerDay('q6-8h'), equals(0.0));
      expect(UnitConverter.dosesPerDay('prn'), equals(0.0));
      expect(UnitConverter.dosesPerDay('qod'), equals(0.0));
      expect(UnitConverter.dosesPerDay('weekly'), equals(0.0));
      expect(UnitConverter.dosesPerDay('continuous'), equals(0.0));
    });

    // -------------------------------------------------------------------------
    // DoseRounder (4.3)
    // -------------------------------------------------------------------------
    test('4.3: DoseRounder uses integer multiples of step and enforces maxDeviation tolerance', () {
      // Tablet strength 500 mg, splittable -> step = 250 mg
      // Dose = 510 mg -> nearest multiple of 250 is 500 mg.
      // Deviation = |500 - 510| / 510 = 10 / 510 = ~1.96% <= 5% -> valid 500.0
      final rounded1 = DoseRounder.roundToNearestStrength(
        510,
        [500],
        isSplittable: true,
        maxDeviation: 0.05,
      );
      expect(rounded1, equals(500.0));

      // Dose = 642 mg with [500], splittable (step 250):
      // Multiples of 250: 500 (diff 142, dev 22.1%), 750 (diff 108, dev 16.8%).
      // Both exceed 5% deviation limit -> must return null for safety!
      final roundedExceeded = DoseRounder.roundToNearestStrength(
        642,
        [500],
        isSplittable: true,
        maxDeviation: 0.05,
      );
      expect(roundedExceeded, isNull);

      // Non-splittable tablet (step = full strength 500 mg):
      // Dose = 260 mg with [500] non-splittable:
      // Multiples: 0 or 500. Nearest is 0 or 500. Deviation is huge (> 5%) -> null
      final roundedNonSplittable = DoseRounder.roundToNearestStrength(
        260,
        [500],
        isSplittable: false,
        maxDeviation: 0.05,
      );
      expect(roundedNonSplittable, isNull);

      // Non-splittable tablet: 980 mg with [500] non-splittable:
      // Nearest multiple: 1000 mg (2 tablets). Deviation: |1000 - 980| / 980 = 2.04% <= 5% -> 1000.0
      final roundedTwoTabs = DoseRounder.roundToNearestStrength(
        980,
        [500],
        isSplittable: false,
        maxDeviation: 0.05,
      );
      expect(roundedTwoTabs, equals(1000.0));
    });

    // -------------------------------------------------------------------------
    // RenalAdjustment & DoseChecker (A7)
    // -------------------------------------------------------------------------
    test('A7: RenalAdjustment appliesTo and DoseChecker at decimal boundaries (9.5, 9.6, 25.5, 49.5)', () {
      const tier1 = RenalAdjustment(crclMin: 0, crclMax: 10, adjustmentFactor: 0.25);
      const tier2 = RenalAdjustment(crclMin: 10, crclMax: 25, adjustmentFactor: 0.5);
      const tier3 = RenalAdjustment(crclMin: 25, crclMax: 50, adjustmentFactor: 0.75);
      const tier4 = RenalAdjustment(crclMin: 50, crclMax: 100, adjustmentFactor: 1.0);

      // CrCl 9.5 falls in [0, 10)
      expect(tier1.appliesTo(9.5), isTrue);

      // CrCl 9.6 falls in [0, 10)
      expect(tier1.appliesTo(9.6), isTrue);

      // CrCl 10.0 falls in [10, 25)
      expect(tier2.appliesTo(10.0), isTrue);

      // CrCl 25.5 falls in [25, 50)
      expect(tier3.appliesTo(25.5), isTrue);

      // CrCl 49.5 falls in [25, 50)
      expect(tier3.appliesTo(49.5), isTrue);
      expect(tier4.appliesTo(60), isTrue);

      // Check severe renal impairment threshold (< 10) in DoseChecker
      final warn94 = DoseChecker.checkRenalAdjustment(crclMlMin: 9.4, adjustments: [tier1, tier2]);
      expect(warn94.any((w) => w.code == DoseWarningCode.severeRenalImpairment), isTrue);

      final warn10 = DoseChecker.checkRenalAdjustment(crclMlMin: 10.0, adjustments: [tier1, tier2]);
      expect(warn10.any((w) => w.code == DoseWarningCode.severeRenalImpairment), isFalse);
    });

    // -------------------------------------------------------------------------
    // InputValidator (A12)
    // -------------------------------------------------------------------------
    test('A12: InputValidator validatePositive shares same keys and validatePatientInputs catches swapped height/weight', () {
      final posRes = InputValidator.validatePositive(
        value: -5.0,
        fieldNameEn: 'Weight',
        fieldNameTh: 'น้ำหนัก',
      );
      expect(posRes.isValid, isFalse);
      // errorsEn and errorsTh must share the identical key
      expect(posRes.errorsEn.keys.first, equals(posRes.errorsTh.keys.first));

      // Swapped height-weight plausibility check:
      // Weight = 170 kg, Height = 70 cm -> BMI = 170 / (0.7)^2 = 346.9 (implausible!)
      final swappedRes = InputValidator.validatePatientInputs(
        weightKg: 170.0,
        heightCm: 70.0,
        ageYears: 30,
        serumCreatinineMgDl: 1.0,
      );
      expect(swappedRes.isValid, isFalse);
      expect(swappedRes.errorsEn.containsKey('bmi'), isTrue);
      expect(swappedRes.errorsTh.containsKey('bmi'), isTrue);
    });

    // -------------------------------------------------------------------------
    // TdmCalculator (4.7)
    // -------------------------------------------------------------------------
    test('4.7: TdmCalculator validates input boundaries and throws ArgumentError on invalid parameters', () {
      // Negative weight
      expect(() => TdmCalculator.calculateVd(weightKg: -5), throwsArgumentError);

      // Negative CrCl
      expect(() => TdmCalculator.calculateKe(crclMlMin: -10), throwsArgumentError);

      // predictTrough requires tInf > 0 and tau > tInf
      expect(
        () => TdmCalculator.predictTrough(
          dose: 1000,
          tau: 1,
          tInf: 2, // tInf > tau is physically impossible
          vd: 40,
          ke: 0.05,
        ),
        throwsArgumentError,
      );

      expect(
        () => TdmCalculator.predictTrough(
          dose: 1000,
          tau: 12,
          tInf: 0, // tInf <= 0 invalid
          vd: 40,
          ke: 0.05,
        ),
        throwsArgumentError,
      );

      // calculateAuc24 with negative or zero tau
      expect(
        () => TdmCalculator.calculateAuc24(dose: 1000, tau: 0, vd: 40, ke: 0.05),
        throwsArgumentError,
      );
    });
  });
}
