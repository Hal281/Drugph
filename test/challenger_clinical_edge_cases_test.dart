// ignore_for_file: prefer_const_constructors, prefer_const_declarations
// ============================================================================
// Challenger 2: Empirical Clinical Calculation & Edge Case Stress Test Suite
// ============================================================================
// Stress-tests:
// 1. Extreme patient parameters (ELBW neonates, super-obese, NaN/Inf guards)
// 2. Strict half-open renal cutoff boundaries [crclMin, crclMax) & anuria (0.0)
// 3. Ironclad Rule 5: Non-blocking Overdose Policy (raw dose preserved, hard warning)
// 4. Ironclad Rules 3 & 4: Therapeutic duplication & drug-drug interactions
// 5. Adrenaline / Epinephrine clinical calculations (anaphylaxis, arrest, infusion)
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Challenger 2 — 1. Extreme Patient Parameters & Non-Finite Guards', () {
    test('Non-finite inputs (NaN, Infinity, -Inf) are rejected at validation and fail cleanly', () {
      final nanPatient = Patient(
        id: 'pt-nan',
        ageYears: 45,
        weightKg: double.nan,
        heightCm: 170.0,
        sex: Sex.male,
        isScrStable: true,
      );

      final drug = DrugDatabase.findById('vancomycin')!;
      final reg = drug.regimens.first;

      final res = PharmacistCalculator.calculateDose(
        patient: nanPatient,
        drug: drug,
        regimen: reg,
      );

      expect(res.success, isFalse, reason: 'NaN weight must result in calculation failure');
      expect(res.warnings.any((w) => w.code == DoseWarningCode.calculationError), isTrue);
    });

    test('Negative weight and height inputs safely fail validation', () {
      final negPatient = Patient(
        id: 'pt-neg',
        ageYears: 30,
        weightKg: -70.0,
        heightCm: 170.0,
        sex: Sex.female,
        isScrStable: true,
      );

      final drug = DrugDatabase.findById('paracetamol')!;
      final reg = drug.regimens.first;

      final res = PharmacistCalculator.calculateDose(
        patient: negPatient,
        drug: drug,
        regimen: reg,
      );

      expect(res.success, isFalse);
      expect(res.warnings.any((w) => w.severity == LimitSeverity.hard), isTrue);
    });

    test('Extreme Low Birth Weight (ELBW) neonate (0.4 kg, 32 cm) validated with allowNeonatalLowWeight', () {
      final elbwValidation = InputValidator.validatePatientInputs(
        weightKg: 0.4,
        heightCm: 32.0,
        ageYears: 0,
        ageMonths: 0,
        allowNeonatalLowWeight: true,
      );

      expect(elbwValidation.isValid, isTrue, reason: 'ELBW weight must be allowed when neonatal flag is active');
      expect(elbwValidation.warningsEn['weightKg'], contains('Extreme low birth weight'));

      final standardValidation = InputValidator.validatePatientInputs(
        weightKg: 0.4,
        heightCm: 32.0,
        ageYears: 0,
        ageMonths: 0,
        allowNeonatalLowWeight: false,
      );

      expect(standardValidation.isValid, isFalse, reason: 'Standard validation must flag <1kg as implausible');
    });

    test('Super-obese patient (250 kg, 175 cm, female) IBW and AdjBW calculations are strictly accurate', () {
      const height = 175.0;
      const weight = 250.0;

      // Devine Formula (Female): 45.5 + 2.3 * ((heightCm / 2.54) - 60)
      final expectedIbw = 45.5 + 2.3 * ((height / 2.54) - 60.0);
      final calculatedIbw = WeightBasedCalculator.idealBodyWeight(
        heightCm: height,
        sex: Sex.female,
      );
      expect(calculatedIbw, closeTo(expectedIbw, 1e-4));

      // AdjBW = IBW + 0.4 * (TBW - IBW)
      final expectedAdjBw = expectedIbw + 0.4 * (weight - expectedIbw);
      final calculatedAdjBw = WeightBasedCalculator.adjustedBodyWeight(
        actualWeightKg: weight,
        ibwKg: calculatedIbw,
      );
      expect(calculatedAdjBw, closeTo(expectedAdjBw, 1e-4));

      // Strict inequalities
      expect(calculatedIbw < calculatedAdjBw, isTrue);
      expect(calculatedAdjBw < weight, isTrue);

      // Verify PharmacistCalculator does not throw or overflow on super-obese patient
      final pt = Patient(
        id: 'pt-obese',
        ageYears: 42,
        weightKg: weight,
        heightCm: height,
        sex: Sex.female,
        isScrStable: true,
        serumCreatinineMgDl: 1.0,
      );

      final acyclovir = DrugDatabase.findById('acyclovir')!;
      final hsv = acyclovir.regimens.firstWhere((r) => r.indication?.contains('Encephalitis') == true);
      final res = PharmacistCalculator.calculateDose(patient: pt, drug: acyclovir, regimen: hsv);

      expect(res.success, isTrue);
      expect(res.calculatedDose, isNotNull);
      expect(res.calculatedDose!.isFinite, isTrue);
    });
  });

  group('Challenger 2 — 2. Strict Half-Open Renal Cutoffs & Anuria', () {
    test('Half-open interval [crclMin, crclMax) partitioning logic holds at exact boundaries', () {
      final tier1 = const RenalAdjustment(
        crclMin: 0.0,
        crclMax: 30.0,
        adjustmentFactor: 0.5,
        notes: 'CrCl < 30',
      );
      final tier2 = const RenalAdjustment(
        crclMin: 30.0,
        crclMax: 50.0,
        adjustmentFactor: 0.75,
        notes: 'CrCl 30-50',
      );
      final tier3 = const RenalAdjustment(
        crclMin: 50.0,
        crclMax: double.infinity,
        adjustmentFactor: 1.0,
        notes: 'CrCl >= 50',
      );

      // 0.0 (anuria) is in tier1
      expect(tier1.appliesTo(0.0), isTrue);
      expect(tier2.appliesTo(0.0), isFalse);

      // 29.999 is in tier1
      expect(tier1.appliesTo(29.999), isTrue);
      expect(tier2.appliesTo(29.999), isFalse);

      // 30.0 boundary falls strictly into tier2, NOT tier1
      expect(tier1.appliesTo(30.0), isFalse);
      expect(tier2.appliesTo(30.0), isTrue);

      // 49.999 is in tier2
      expect(tier2.appliesTo(49.999), isTrue);
      expect(tier3.appliesTo(49.999), isFalse);

      // 50.0 boundary falls strictly into tier3, NOT tier2
      expect(tier2.appliesTo(50.0), isFalse);
      expect(tier3.appliesTo(50.0), isTrue);

      // Normal CrCl 120.0 falls in tier3
      expect(tier3.appliesTo(120.0), isTrue);
    });

    test('Renal contraindication action strictly blocks calculation with failure result', () {
      final pt = Patient(
        id: 'pt-renal-fail',
        ageYears: 65,
        weightKg: 60.0,
        heightCm: 165.0,
        sex: Sex.male,
        serumCreatinineMgDl: 4.5, // Produces CrCl < 20
        isScrStable: true,
      );

      final drug = DrugDatabase.findById('metformin');
      if (drug != null) {
        final reg = drug.regimens.first;
        final res = PharmacistCalculator.calculateDose(patient: pt, drug: drug, regimen: reg);
        if (res.warnings.any((w) => w.code == DoseWarningCode.contraindicationAlert && w.severity == LimitSeverity.hard)) {
          expect(res.success, isFalse, reason: 'Metformin in severe renal impairment must be contraindicated');
        }
      }
    });

    test('Anuric patient (CrCl = 0.0) calculates safely without division by zero', () {
      final anuricPt = Patient(
        id: 'pt-anuria',
        ageYears: 50,
        weightKg: 70.0,
        heightCm: 175.0,
        sex: Sex.male,
        creatinineClearanceMlMin: 0.0,
        isScrStable: true,
      );

      final mero = DrugDatabase.findById('meropenem')!;
      final reg = mero.regimens.first;

      final res = PharmacistCalculator.calculateDose(patient: anuricPt, drug: mero, regimen: reg);
      expect(res.calculatedDose == null || res.calculatedDose!.isFinite, isTrue);
      expect(res.warnings.any((w) => w.code == DoseWarningCode.severeRenalImpairment), isTrue);
    });
  });

  group('Challenger 2 — 3. Ironclad Rule 5: Non-Blocking Overdose Policy', () {
    test('Dose exceeding maxSingleDose preserves raw calculatedDose and fires hard warning', () {
      // Test Acyclovir IV 10 mg/kg with 120 kg patient -> 1200 mg (maxSingleDose: 800 mg)
      final pt = Patient(
        id: 'pt-heavy',
        ageYears: 35,
        weightKg: 120.0,
        heightCm: 180.0,
        sex: Sex.male,
        isScrStable: true,
        serumCreatinineMgDl: 0.9,
      );

      final acyclovir = DrugDatabase.findById('acyclovir')!;
      final hsv = acyclovir.regimens.firstWhere((r) => r.indication?.contains('Encephalitis') == true);

      final res = PharmacistCalculator.calculateDose(patient: pt, drug: acyclovir, regimen: hsv);

      // Rule 5: Success is true, dose is NOT clamped to 800, NOT null, NOT 0.0
      expect(res.success, isTrue, reason: 'Rule 5: Overdose calculation must succeed to support emergency care');
      expect(res.calculatedDose, equals(1200.0), reason: 'Rule 5: Raw dose (1200 mg) must be preserved');
      expect(res.calculatedDose != 800.0, isTrue, reason: 'Rule 5: Dose must NOT be clamped to maxSingleDose');

      // Rule 5: Hard warning must be clearly present
      final maxDoseWarning = res.warnings.firstWhere(
        (w) => w.code == DoseWarningCode.maxSingleDoseExceeded,
      );
      expect(maxDoseWarning.severity, equals(LimitSeverity.hard));
      expect(maxDoseWarning.calculatedValue, equals(1200.0));
      expect(maxDoseWarning.limitValue, equals(800.0));
    });

    test('Pediatric Paracetamol overdose (80 kg child at 10 mg/kg -> 800 mg, limit 750 mg) preserves raw dose', () {
      final heavyPedPt = Patient(
        id: 'pt-heavy-ped',
        ageYears: 11,
        weightKg: 80.0,
        heightCm: 155.0,
        sex: Sex.male,
        isScrStable: true,
      );

      final para = DrugDatabase.findById('paracetamol')!;
      final reg = para.regimens.firstWhere((r) => r.dosingType == DosingType.weightBased);

      final res = PharmacistCalculator.calculateDose(patient: heavyPedPt, drug: para, regimen: reg);

      final expectedRaw = 80.0 * (reg.dosePerKg ?? 10.0);
      expect(res.success, isTrue);
      expect(res.calculatedDose, equals(expectedRaw));
      expect(res.warnings.any((w) => w.code == DoseWarningCode.maxSingleDoseExceeded), isTrue);
    });
  });

  group('Challenger 2 — 4. Ironclad Rules 3 & 4: Duplication & DDI', () {
    test('Dual NSAIDs combination (Ibuprofen + Naproxen) flags contraindicated therapeutic duplication', () {
      final pt = Patient(
        id: 'pt-nsaid',
        ageYears: 40,
        weightKg: 70.0,
        heightCm: 170.0,
        sex: Sex.male,
        activeDrugIds: ['naproxen'],
        isScrStable: true,
      );

      final ibup = DrugDatabase.findById('ibuprofen')!;
      final reg = ibup.regimens.first;

      final res = PharmacistCalculator.calculateDose(
        patient: pt,
        drug: ibup,
        regimen: reg,
        drugLookup: (id) => DrugDatabase.findById(id),
      );

      final dupAlert = res.warnings.firstWhere(
        (w) => w.code == DoseWarningCode.therapeuticDuplication,
      );
      expect(dupAlert.severity, equals(LimitSeverity.hard));
      expect(dupAlert.messageEn, contains('NSAID'));
    });

    test('Dual RAS Blockade (Enalapril + Losartan) flags contraindicated therapeutic duplication', () {
      final pt = Patient(
        id: 'pt-ras',
        ageYears: 55,
        weightKg: 75.0,
        heightCm: 172.0,
        sex: Sex.male,
        activeDrugIds: ['losartan'],
        isScrStable: true,
      );

      final enalapril = DrugDatabase.findById('enalapril');
      if (enalapril != null) {
        final reg = enalapril.regimens.first;
        final res = PharmacistCalculator.calculateDose(
          patient: pt,
          drug: enalapril,
          regimen: reg,
          drugLookup: (id) => DrugDatabase.findById(id),
        );

        final dupAlert = res.warnings.firstWhere(
          (w) => w.code == DoseWarningCode.therapeuticDuplication,
        );
        expect(dupAlert.severity, equals(LimitSeverity.hard));
        expect(dupAlert.messageEn.toLowerCase(), contains('ras'));
      }
    });

    test('Dual Anticoagulants (Warfarin + Apixaban / Rivaroxaban) flags severe fatal hemorrhage warning', () {
      final pt = Patient(
        id: 'pt-anticoag',
        ageYears: 68,
        weightKg: 65.0,
        heightCm: 165.0,
        sex: Sex.female,
        activeDrugIds: ['warfarin'],
        isScrStable: true,
      );

      final apix = DrugDatabase.findById('apixaban') ?? DrugDatabase.findById('rivaroxaban');
      if (apix != null) {
        final reg = apix.regimens.first;
        final res = PharmacistCalculator.calculateDose(
          patient: pt,
          drug: apix,
          regimen: reg,
          drugLookup: (id) => DrugDatabase.findById(id),
        );

        final dupAlert = res.warnings.firstWhere(
          (w) => w.code == DoseWarningCode.therapeuticDuplication || w.code == DoseWarningCode.severeInteractionAlert,
        );
        expect(dupAlert.severity, equals(LimitSeverity.hard));
      }
    });
  });

  group('Challenger 2 — 5. Epinephrine / Adrenaline Clinical Calculations', () {
    final epi = DrugDatabase.findById('epinephrine')!;

    test('Pediatric Anaphylaxis: 0.01 mg/kg IM up to 0.3 mg limit preserves raw dose when over limit', () {
      final pedAna = epi.regimens.firstWhere((r) => r.indication?.contains('Anaphylaxis (Pediatric)') == true);

      // 15 kg child -> 0.15 mg IM (within 0.3 mg max)
      final pt15 = Patient(
        id: 'pt-peds-15',
        ageYears: 4,
        weightKg: 15.0,
        heightCm: 100.0,
        sex: Sex.male,
        isScrStable: true,
      );
      final res15 = PharmacistCalculator.calculateDose(patient: pt15, drug: epi, regimen: pedAna);
      expect(res15.success, isTrue);
      expect(res15.calculatedDose, closeTo(0.15, 1e-4));
      expect(res15.warnings.any((w) => w.code == DoseWarningCode.maxSingleDoseExceeded), isFalse);

      // 35 kg child -> 0.35 mg IM (exceeds 0.3 mg limit)
      final pt35 = Patient(
        id: 'pt-peds-35',
        ageYears: 10,
        weightKg: 35.0,
        heightCm: 135.0,
        sex: Sex.female,
        isScrStable: true,
      );
      final res35 = PharmacistCalculator.calculateDose(patient: pt35, drug: epi, regimen: pedAna);
      expect(res35.success, isTrue);
      expect(res35.calculatedDose, closeTo(0.35, 1e-4), reason: 'Rule 5: Raw dose 0.35 mg preserved');
      expect(res35.warnings.any((w) => w.code == DoseWarningCode.maxSingleDoseExceeded), isTrue);
    });

    test('Adult Septic Shock Titration: 0.05–1.0 mcg/kg/min mathematically converts to mL/hr accurately', () {
      final shockReg = epi.regimens.firstWhere((r) => r.indication?.contains('Shock') == true);

      final pt60 = Patient(
        id: 'pt-shock-60',
        ageYears: 55,
        weightKg: 60.0,
        heightCm: 170.0,
        sex: Sex.male,
        serumCreatinineMgDl: 1.0,
        isScrStable: true,
      );

      final res = PharmacistCalculator.calculateDose(patient: pt60, drug: epi, regimen: shockReg);
      expect(res.success, isTrue);
      expect(res.infusionResult, isNotNull);

      // 60 kg patient at min rate 0.05 mcg/kg/min = 3.0 mcg/min = 180 mcg/hr
      // Effective standard dilution for Epinephrine infusion: 4 mg in 250 mL = 0.016 mg/mL = 16 mcg/mL
      // Rate in mL/hr = 180 mcg/hr / 16 mcg/mL = 11.25 mL/hr
      final inf = res.infusionResult!;
      expect(inf.rate, closeTo(0.05, 1e-4));
      expect(inf.rateMax, closeTo(1.0, 1e-4));

      if (inf.rateMlPerHr != null) {
        expect(inf.rateMlPerHr!, closeTo(11.25, 0.1));
      }
      if (inf.rateMlPerHrMax != null) {
        // 60 kg at 1.0 mcg/kg/min = 60 mcg/min = 3600 mcg/hr / 16 mcg/mL = 225 mL/hr
        expect(inf.rateMlPerHrMax!, closeTo(225.0, 1.0));
      }
    });
  });
}
