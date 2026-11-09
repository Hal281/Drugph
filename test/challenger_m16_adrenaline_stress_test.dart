// ============================================================================
// CHALLENGER M16: Empirical Adversarial Stress-Test Suite for Adrenaline (Epinephrine)
// ============================================================================
// Authoritative references:
// - AHA ACLS & PALS Guidelines 2020 (Circulation 2020)
// - World Allergy Organization (WAO) Anaphylaxis Guidelines 2020
// - US FDA Adrenalin SPL / Thai FDA / Ramathibodi High-Alert IV Guide 2024
// - AGENTS.md Rules 1-5 (Zero-Error Math, Evidence-Based, Non-Blocking Overdose)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/core/models/specialized_dosing_models.dart';
import 'package:drug_dosage_calculator/core/calculators/specialized_dosing_calculator.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:drug_dosage_calculator/data/patient_session.dart';
import 'package:drug_dosage_calculator/ui/iv_titration_screen.dart';
import 'package:drug_dosage_calculator/ui/calculator/models/calculator_ui_state.dart';
import 'package:drug_dosage_calculator/ui/calculator/widgets/dosage_result_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final epi = DrugDatabase.findById('epinephrine');

  group('CHALLENGE 1: Drug Model & Regimen Contract Invariants', () {
    test('Epinephrine exists, is High-Alert, and contains all 5 required indications', () {
      expect(epi, isNotNull, reason: 'Epinephrine must exist in DrugDatabase');
      expect(epi!.isHighAlert, isTrue, reason: 'Epinephrine is a Critical High-Alert Medication');
      expect(epi.category, equals(DrugCategory.vasopressor));
      expect(epi.regimens.length, equals(5));

      final indications = epi.regimens.map((r) => r.indication ?? '').toList();
      expect(indications.any((ind) => ind.contains('Anaphylaxis (Adult)')), isTrue);
      expect(indications.any((ind) => ind.contains('Anaphylaxis (Pediatric)')), isTrue);
      expect(indications.any((ind) => ind.contains('ACLS (Adult)')), isTrue);
      expect(indications.any((ind) => ind.contains('PALS (Pediatric)')), isTrue);
      expect(indications.any((ind) => ind.contains('Shock')), isTrue);
    });
  });

  group('CHALLENGE 2: Adult Anaphylaxis IM (0.3 - 0.5 mg, 1:1,000 [1 mg/mL])', () {
    late DosingRegimen adultRegimen;

    setUp(() {
      adultRegimen = epi!.regimens.firstWhere(
        (r) => r.indication?.contains('Anaphylaxis (Adult)') == true,
      );
    });

    test('Route, concentration, and volume: 0.3 mg yields exactly 0.3 mL', () {
      expect(adultRegimen.route, equals(DoseRoute.im));
      expect(adultRegimen.standardDilutionMgPerMl, equals(1.0));
      expect(adultRegimen.fixedDose, equals(0.3));
      expect(adultRegimen.limits?.maxSingleDose, equals(0.5));

      const adult70 = Patient(
        id: 'pt-adult-70',
        ageYears: 35,
        weightKg: 70.0,
        heightCm: 175.0,
        sex: Sex.male,
        isScrStable: true,
      );

      final result = PharmacistCalculator.calculateDose(
        patient: adult70,
        drug: epi!,
        regimen: adultRegimen,
      );

      expect(result.calculatedDose, equals(0.3));
      expect(result.volumeMl, equals(0.3));
      expect(result.isBlocked, isFalse);
      expect(result.hasHardLimitViolation, isFalse);
    });

    test('Weight independence across diverse adult patients (40 kg to 180 kg)', () {
      final weights = [40.0, 50.0, 60.0, 75.0, 90.0, 120.0, 180.0];
      for (final w in weights) {
        final pt = Patient(
          id: 'pt-adult-$w',
          ageYears: 40,
          weightKg: w,
          heightCm: 170.0,
          sex: Sex.female,
          isScrStable: true,
        );

        final res = PharmacistCalculator.calculateDose(
          patient: pt,
          drug: epi!,
          regimen: adultRegimen,
        );

        expect(res.calculatedDose, equals(0.3), reason: 'Fixed dose must not vary by weight');
        expect(res.volumeMl, equals(0.3), reason: 'Volume must be exactly 0.3 mL');
        expect(res.isBlocked, isFalse);
      }
    });

    test('Severe renal impairment does NOT reduce anaphylaxis dose (rapid MAO/COMT clearance)', () {
      const renalFailurePt = Patient(
        id: 'pt-renal-fail',
        ageYears: 65,
        weightKg: 70.0,
        heightCm: 165.0,
        sex: Sex.male,
        serumCreatinineMgDl: 8.5,
        isScrStable: true,
      );

      final res = PharmacistCalculator.calculateDose(
        patient: renalFailurePt,
        drug: epi!,
        regimen: adultRegimen,
      );

      expect(res.calculatedDose, equals(0.3));
      expect(res.volumeMl, equals(0.3));
      expect(res.isRenallyAdjusted, isFalse, reason: 'Epinephrine IM requires NO renal dose reduction');
    });

    test('Clinical verification check: 0.5 mg is accepted, while 0.7 mg triggers single dose limit', () {
      const pt = Patient(
        id: 'pt-adult-override',
        ageYears: 30,
        weightKg: 70.0,
        heightCm: 175.0,
        sex: Sex.male,
        isScrStable: true,
      );

      // Verify ordered 0.5 mg (within upper range of 0.3-0.5 mg)
      final res05 = PharmacistCalculator.verifyOrder(
        patient: pt,
        drug: epi!,
        regimen: adultRegimen,
        orderedDose: 0.5,
        orderedFrequency: adultRegimen.frequency,
      );
      expect(res05.warnings.any((w) => w.code == DoseWarningCode.maxSingleDoseExceeded), isFalse);

      // Verify ordered 0.7 mg (exceeds maxSingleDose 0.5 mg)
      final res07 = PharmacistCalculator.verifyOrder(
        patient: pt,
        drug: epi,
        regimen: adultRegimen,
        orderedDose: 0.7,
        orderedFrequency: adultRegimen.frequency,
      );
      expect(res07.warnings.any((w) => w.code == DoseWarningCode.maxSingleDoseExceeded), isTrue);
      // Under Rule 5: verify order does not crash or silently wipe ordered dose
      expect(res07.recommendedResult.calculatedDose, equals(0.3));
      expect(res07.orderedDose, equals(0.7));
    });
  });

  group('CHALLENGE 3: Pediatric Anaphylaxis IM (0.01 mg/kg, 1 mg/mL, Rule 5 Non-Blocking)', () {
    late DosingRegimen pedRegimen;

    setUp(() {
      pedRegimen = epi!.regimens.firstWhere(
        (r) => r.indication?.contains('Anaphylaxis (Pediatric)') == true,
      );
    });

    test('Regimen configuration verification: 0.01 mg/kg IM, 1:1,000 (1.0 mg/mL)', () {
      expect(pedRegimen.route, equals(DoseRoute.im));
      expect(pedRegimen.dosingType, equals(DosingType.weightBased));
      expect(pedRegimen.dosePerKg, equals(0.01));
      expect(pedRegimen.standardDilutionMgPerMl, equals(1.0));
      expect(pedRegimen.limits?.maxSingleDose, equals(0.3));
    });

    test('Comprehensive weight spectrum sweep (3 kg to 70 kg): math correctness & Rule 5 compliance', () {
      // Test cases: (weight, expectedDoseMg, expectedVolumeMl, shouldExceedLimit)
      final cases = [
        (3.0, 0.03, 0.03, false),
        (5.0, 0.05, 0.05, false),
        (8.0, 0.08, 0.08, false),
        (10.0, 0.10, 0.10, false),
        (12.5, 0.125, 0.125, false),
        (15.0, 0.15, 0.15, false),
        (20.0, 0.20, 0.20, false),
        (25.0, 0.25, 0.25, false),
        (30.0, 0.30, 0.30, false), // Exact ceiling boundary
        (30.1, 0.301, 0.301, true), // Just above ceiling
        (35.0, 0.35, 0.35, true), // Nurse/Clinical benchmark case
        (40.0, 0.40, 0.40, true),
        (50.0, 0.50, 0.50, true),
        (60.0, 0.60, 0.60, true),
        (70.0, 0.70, 0.70, true),
      ];

      for (final (weight, expDose, expVol, shouldExceed) in cases) {
        final pt = Patient(
          id: 'pt-ped-$weight',
          ageYears: (weight / 3.5).clamp(0, 16).toInt(),
          weightKg: weight,
          heightCm: (weight * 2.5).clamp(50, 180),
          sex: Sex.male,
          isScrStable: true,
        );

        final result = PharmacistCalculator.calculateDose(
          patient: pt,
          drug: epi!,
          regimen: pedRegimen,
        );

        // 1. Math precision: Zero-error calculation (Rule 1)
        expect(
          result.calculatedDose,
          closeTo(expDose, 1e-6),
          reason: 'Weight $weight kg must compute exact calculatedDose $expDose mg',
        );
        expect(
          result.volumeMl,
          closeTo(expVol, 1e-6),
          reason: 'Weight $weight kg must compute exact volumeMl $expVol mL',
        );

        // 2. Rule 5: Non-Blocking Overdose Policy
        expect(result.success, isTrue, reason: 'Calculation must succeed without failure');
        expect(result.calculatedDose, isNotNull, reason: 'Dose must NOT be concealed or set to null');
        expect(result.volumeMl, isNotNull, reason: 'Volume must NOT be concealed or set to null');

        // 3. Limit violation behavior
        if (shouldExceed) {
          expect(
            result.hasHardLimitViolation,
            isTrue,
            reason: 'Weight $weight kg (> 30 kg) must set hasHardLimitViolation = true',
          );
          expect(
            result.warnings.any((w) => w.code == DoseWarningCode.maxSingleDoseExceeded),
            isTrue,
            reason: 'Weight $weight kg must trigger maxSingleDoseExceeded warning',
          );
          // Confirm that the dose is NOT clamped to 0.3 mg (Rule 5 requirement)
          expect(
            result.calculatedDose,
            greaterThan(0.30),
            reason: 'Raw calculatedDose must remain un-clamped (> 0.3 mg) for clinical visibility',
          );
        } else {
          expect(
            result.hasHardLimitViolation,
            isFalse,
            reason: 'Weight $weight kg (<= 30 kg) must not violate hard limits',
          );
          expect(
            result.warnings.any((w) => w.code == DoseWarningCode.maxSingleDoseExceeded),
            isFalse,
          );
        }
      }
    });
  });

  group('CHALLENGE 4: Adult Cardiac Arrest ACLS IV Push (1.0 mg, 0.1 mg/mL [1:10,000])', () {
    late DosingRegimen aclsRegimen;

    setUp(() {
      aclsRegimen = epi!.regimens.firstWhere(
        (r) => r.indication?.contains('ACLS (Adult)') == true,
      );
    });

    test('Dilution 0.1 mg/mL yields EXACTLY 10.0 mL for 1.0 mg fixed dose', () {
      expect(aclsRegimen.route, equals(DoseRoute.ivPush));
      expect(aclsRegimen.standardDilutionMgPerMl, equals(0.1));
      expect(aclsRegimen.fixedDose, equals(1.0));
      expect(aclsRegimen.limits?.maxSingleDose, equals(1.0));

      const pt = Patient(
        id: 'pt-acls-70',
        ageYears: 50,
        weightKg: 70.0,
        heightCm: 172.0,
        sex: Sex.male,
        isScrStable: true,
      );

      final res = PharmacistCalculator.calculateDose(
        patient: pt,
        drug: epi!,
        regimen: aclsRegimen,
      );

      // Math: 1.0 mg / 0.1 mg/mL = 10.0 mL
      expect(res.calculatedDose, equals(1.0));
      expect(res.volumeMl, closeTo(10.0, 1e-6));
      expect(res.isBlocked, isFalse);
      expect(res.hasHardLimitViolation, isFalse);
    });
  });

  group('CHALLENGE 5: Pediatric Cardiac Arrest PALS IV Push (0.01 mg/kg, 0.1 mg/mL [1:10,000])', () {
    late DosingRegimen palsRegimen;

    setUp(() {
      palsRegimen = epi!.regimens.firstWhere(
        (r) => r.indication?.contains('PALS (Pediatric)') == true,
      );
    });

    test('Formula proof: Volume is exactly 0.1 mL/kg (0.01 mg/kg / 0.1 mg/mL)', () {
      expect(palsRegimen.route, equals(DoseRoute.ivPush));
      expect(palsRegimen.standardDilutionMgPerMl, equals(0.1));
      expect(palsRegimen.dosePerKg, equals(0.01));
      expect(palsRegimen.limits?.maxSingleDose, equals(1.0));

      // 15 kg child -> 0.15 mg -> 1.5 mL (exactly 0.1 mL/kg * 15 kg)
      const child15 = Patient(
        id: 'pt-pals-15',
        ageYears: 3,
        weightKg: 15.0,
        heightCm: 96.0,
        sex: Sex.female,
        isScrStable: true,
      );

      final res15 = PharmacistCalculator.calculateDose(
        patient: child15,
        drug: epi!,
        regimen: palsRegimen,
      );

      expect(res15.calculatedDose, closeTo(0.15, 1e-6));
      expect(res15.volumeMl, closeTo(1.5, 1e-6));
      expect(res15.volumeMl! / child15.weightKg, closeTo(0.1, 1e-6));
      expect(res15.isBlocked, isFalse);
      expect(res15.hasHardLimitViolation, isFalse);
    });

    test('Boundary & Overdose test for 100 kg and 120 kg patients (Rule 5 Non-blocking)', () {
      // 100 kg -> 1.0 mg -> 10.0 mL (exact maxSingleDose boundary, safe)
      const pt100 = Patient(
        id: 'pt-pals-100',
        ageYears: 16,
        weightKg: 100.0,
        heightCm: 180.0,
        sex: Sex.male,
        isScrStable: true,
      );

      final res100 = PharmacistCalculator.calculateDose(
        patient: pt100,
        drug: epi!,
        regimen: palsRegimen,
      );

      expect(res100.calculatedDose, closeTo(1.0, 1e-6));
      expect(res100.volumeMl, closeTo(10.0, 1e-6));
      expect(res100.hasHardLimitViolation, isFalse);

      // 120 kg obese adolescent -> 1.2 mg -> 12.0 mL (exceeds maxSingleDose 1.0 mg)
      const pt120 = Patient(
        id: 'pt-pals-120',
        ageYears: 17,
        weightKg: 120.0,
        heightCm: 180.0,
        sex: Sex.male,
        isScrStable: true,
      );

      final res120 = PharmacistCalculator.calculateDose(
        patient: pt120,
        drug: epi,
        regimen: palsRegimen,
      );

      expect(res120.calculatedDose, closeTo(1.2, 1e-6));
      expect(res120.volumeMl, closeTo(12.0, 1e-6));
      expect(res120.hasHardLimitViolation, isTrue);
      expect(res120.warnings.any((w) => w.code == DoseWarningCode.maxSingleDoseExceeded), isTrue);
      expect(res120.success, isTrue, reason: 'Rule 5: calculation succeeds without crashing or concealing numbers');
    });
  });

  group('CHALLENGE 6: Continuous IV Infusion & SpecializedDosingCalculator Hardening', () {
    test('Standard dilution 16 mcg/mL (4 mg in 250 mL): Nurse 60 kg at 0.10 mcg/kg/min yields EXACTLY 22.5 mL/hr', () {
      final res = SpecializedDosingCalculator.calculateVasoactiveInfusion(
        drug: 'epinephrine',
        orderedDose: 0.10,
        doseUnit: 'mcg/kg/min',
        patientWeightKg: 60.0,
        concentrationMcgPerMl: 16.0,
      );

      // Math: (0.10 * 60 * 60) / 16.0 = 360 / 16 = 22.5 mL/hr
      expect(res.pumpRateMlPerHr, closeTo(22.5, 1e-6));
      expect(res.deliveredMcgKgMin, closeTo(0.10, 1e-6));
      expect(res.concentrationMcgPerMl, equals(16.0));
      expect(res.isCeilingExceeded, isFalse);
    });

    test('Standard dilution 16 mcg/mL: 70 kg at 0.05 mcg/kg/min yields EXACTLY 13.125 mL/hr', () {
      final res = SpecializedDosingCalculator.calculateVasoactiveInfusion(
        drug: 'epinephrine',
        orderedDose: 0.05,
        doseUnit: 'mcg/kg/min',
        patientWeightKg: 70.0,
        concentrationMcgPerMl: 16.0,
      );

      // Math: (0.05 * 70 * 60) / 16.0 = 210 / 16 = 13.125 mL/hr
      expect(res.pumpRateMlPerHr, closeTo(13.125, 1e-6));
      expect(res.deliveredMcgKgMin, closeTo(0.05, 1e-6));
      expect(res.isCeilingExceeded, isFalse);
    });

    test('Double strength 32 mcg/mL (8 mg in 250 mL): 60 kg at 0.10 mcg/kg/min yields EXACTLY 11.25 mL/hr', () {
      final res = SpecializedDosingCalculator.calculateVasoactiveInfusion(
        drug: 'epinephrine',
        orderedDose: 0.10,
        doseUnit: 'mcg/kg/min',
        patientWeightKg: 60.0,
        concentrationMcgPerMl: 32.0,
      );

      // Math: (0.10 * 60 * 60) / 32.0 = 360 / 32 = 11.25 mL/hr
      expect(res.pumpRateMlPerHr, closeTo(11.25, 1e-6));
      expect(res.deliveredMcgKgMin, closeTo(0.10, 1e-6));
      expect(res.isCeilingExceeded, isFalse);
    });

    test('Distinctness: Non-weight-based mcg/min vs Weight-based mcg/kg/min', () {
      const weight = 60.0;
      const conc = 16.0;

      // 1. Non-weight-based: 6.0 mcg/min
      // Rate = (6.0 * 60) / 16.0 = 22.5 mL/hr
      // Delivered = 6.0 / 60.0 = 0.10 mcg/kg/min
      final nonWeightRes = SpecializedDosingCalculator.calculateVasoactiveInfusion(
        drug: 'epinephrine',
        orderedDose: 6.0,
        doseUnit: 'mcg/min',
        patientWeightKg: weight,
        concentrationMcgPerMl: conc,
      );
      expect(nonWeightRes.pumpRateMlPerHr, closeTo(22.5, 1e-6));
      expect(nonWeightRes.deliveredMcgKgMin, closeTo(0.10, 1e-6));
      expect(nonWeightRes.isCeilingExceeded, isFalse);

      // 2. Weight-based: 6.0 mcg/kg/min (massive overdose!)
      // Rate = (6.0 * 60 * 60) / 16.0 = 1350.0 mL/hr
      // Delivered = 6.0 mcg/kg/min
      final weightRes = SpecializedDosingCalculator.calculateVasoactiveInfusion(
        drug: 'epinephrine',
        orderedDose: 6.0,
        doseUnit: 'mcg/kg/min',
        patientWeightKg: weight,
        concentrationMcgPerMl: conc,
      );
      expect(weightRes.pumpRateMlPerHr, closeTo(1350.0, 1e-6));
      expect(weightRes.deliveredMcgKgMin, closeTo(6.0, 1e-6));
      expect(weightRes.isCeilingExceeded, isTrue);

      // Mathematical ratio proof: weightRes pump rate is exactly 60 times nonWeightRes
      expect(weightRes.pumpRateMlPerHr / nonWeightRes.pumpRateMlPerHr, closeTo(60.0, 1e-6));
    });

    test('Unit normalization: whitespace, mixed casing, and aliases', () {
      final validUnits = [
        'mcg/kg/min',
        'MCG/KG/MIN',
        '  mcg/kg/min  ',
        'mcg/kg/minute',
        'mcgkgmin',
      ];
      for (final u in validUnits) {
        final res = SpecializedDosingCalculator.calculateVasoactiveInfusion(
          drug: 'epinephrine',
          orderedDose: 0.10,
          doseUnit: u,
          patientWeightKg: 60.0,
          concentrationMcgPerMl: 16.0,
        );
        expect(res.pumpRateMlPerHr, closeTo(22.5, 1e-6));
      }
    });

    test('Unsupported unit strings strictly throw ArgumentError (no silent unsafe fallbacks)', () {
      final invalidUnits = [
        'mg/hr',
        'mL/hr',
        'mg/kg/min',
        'units/hr',
        'mcg/hr',
        'g/hr',
        'drops/min',
        '',
        'random_string',
      ];

      for (final badUnit in invalidUnits) {
        expect(
          () => SpecializedDosingCalculator.calculateVasoactiveInfusion(
            drug: 'epinephrine',
            orderedDose: 0.10,
            doseUnit: badUnit,
            patientWeightKg: 60.0,
            concentrationMcgPerMl: 16.0,
          ),
          throwsArgumentError,
          reason: 'Unit "$badUnit" must throw ArgumentError',
        );
      }
    });

    test('Titration ceiling stress test (> 1.0 mcg/kg/min): Rule 5 Non-blocking preservation', () {
      // Overdose cases above 1.0 mcg/kg/min ceiling
      final ceilingCases = [
        (1.01, 70.0, 16.0, 265.125), // (1.01 * 70 * 60) / 16 = 265.125
        (1.50, 70.0, 16.0, 393.75), // (1.50 * 70 * 60) / 16 = 393.75
        (2.00, 60.0, 16.0, 450.0), // (2.00 * 60 * 60) / 16 = 450.0
        (5.00, 50.0, 16.0, 937.5), // (5.00 * 50 * 60) / 16 = 937.5
        (1.50, 60.0, 32.0, 168.75), // (1.50 * 60 * 60) / 32 = 168.75 (double strength)
      ];

      for (final (dose, weight, conc, expRate) in ceilingCases) {
        final res = SpecializedDosingCalculator.calculateVasoactiveInfusion(
          drug: 'epinephrine',
          orderedDose: dose,
          doseUnit: 'mcg/kg/min',
          patientWeightKg: weight,
          concentrationMcgPerMl: conc,
        );

        // 1. Full pump rate is PRESERVED, not zeroed, not capped at ceiling (Rule 5)
        expect(
          res.pumpRateMlPerHr,
          closeTo(expRate, 1e-6),
          reason: 'Dose $dose mcg/kg/min must preserve calculated pump rate $expRate mL/hr',
        );

        // 2. Ceiling violation flag is raised
        expect(res.isCeilingExceeded, isTrue);

        // 3. Warning banner contains critical alert
        expect(res.warningMessage, contains('TITRATION CEILING EXCEEDED'));
        expect(res.warningMessage, contains('Rule 5 non-blocking active'));
      }
    });

    test('Domain boundary validation: zero, negative, NaN, and infinite inputs throw ArgumentError', () {
      // Dose <= 0, NaN, Inf
      expect(
        () => SpecializedDosingCalculator.calculateVasoactiveInfusion(
          drug: 'epinephrine',
          orderedDose: 0.0,
          doseUnit: 'mcg/kg/min',
          patientWeightKg: 60.0,
        ),
        throwsArgumentError,
      );
      expect(
        () => SpecializedDosingCalculator.calculateVasoactiveInfusion(
          drug: 'epinephrine',
          orderedDose: -0.1,
          doseUnit: 'mcg/kg/min',
          patientWeightKg: 60.0,
        ),
        throwsArgumentError,
      );
      expect(
        () => SpecializedDosingCalculator.calculateVasoactiveInfusion(
          drug: 'epinephrine',
          orderedDose: double.nan,
          doseUnit: 'mcg/kg/min',
          patientWeightKg: 60.0,
        ),
        throwsArgumentError,
      );
      expect(
        () => SpecializedDosingCalculator.calculateVasoactiveInfusion(
          drug: 'epinephrine',
          orderedDose: double.infinity,
          doseUnit: 'mcg/kg/min',
          patientWeightKg: 60.0,
        ),
        throwsArgumentError,
      );

      // Weight <= 0, NaN, Inf
      expect(
        () => SpecializedDosingCalculator.calculateVasoactiveInfusion(
          drug: 'epinephrine',
          orderedDose: 0.10,
          doseUnit: 'mcg/kg/min',
          patientWeightKg: 0.0,
        ),
        throwsArgumentError,
      );
      expect(
        () => SpecializedDosingCalculator.calculateVasoactiveInfusion(
          drug: 'epinephrine',
          orderedDose: 0.10,
          doseUnit: 'mcg/kg/min',
          patientWeightKg: -70.0,
        ),
        throwsArgumentError,
      );

      // Concentration <= 0, NaN, Inf
      expect(
        () => SpecializedDosingCalculator.calculateVasoactiveInfusion(
          drug: 'epinephrine',
          orderedDose: 0.10,
          doseUnit: 'mcg/kg/min',
          patientWeightKg: 60.0,
          concentrationMcgPerMl: 0.0,
        ),
        throwsArgumentError,
      );
      expect(
        () => SpecializedDosingCalculator.calculateVasoactiveInfusion(
          drug: 'epinephrine',
          orderedDose: 0.10,
          doseUnit: 'mcg/kg/min',
          patientWeightKg: 60.0,
          concentrationMcgPerMl: -16.0,
        ),
        throwsArgumentError,
      );
    });
  });

  group('CHALLENGE 7: Cross-Vasoactive Invariants (Norepinephrine, Dopamine, Dobutamine)', () {
    test('Norepinephrine: standard 16 mcg/mL and double 32 mcg/mL matches Epinephrine exactly', () {
      final res16 = SpecializedDosingCalculator.calculateVasoactiveInfusion(
        drug: 'norepinephrine',
        orderedDose: 0.10,
        doseUnit: 'mcg/kg/min',
        patientWeightKg: 60.0,
      );
      expect(res16.pumpRateMlPerHr, closeTo(22.5, 1e-6));

      final res32 = SpecializedDosingCalculator.calculateVasoactiveInfusion(
        drug: 'norepinephrine',
        orderedDose: 0.10,
        doseUnit: 'mcg/kg/min',
        patientWeightKg: 60.0,
        dilution: VasoactiveDilution.doubleStrength,
      );
      expect(res32.pumpRateMlPerHr, closeTo(11.25, 1e-6));
    });

    test('Dopamine: 1600 mcg/mL standard, 20 mcg/kg/min ceiling', () {
      final res = SpecializedDosingCalculator.calculateVasoactiveInfusion(
        drug: 'dopamine',
        orderedDose: 5.0,
        doseUnit: 'mcg/kg/min',
        patientWeightKg: 60.0,
      );
      // Math: (5.0 * 60 * 60) / 1600.0 = 18000 / 1600 = 11.25 mL/hr
      expect(res.pumpRateMlPerHr, closeTo(11.25, 1e-6));
      expect(res.isCeilingExceeded, isFalse);

      final over = SpecializedDosingCalculator.calculateVasoactiveInfusion(
        drug: 'dopamine',
        orderedDose: 25.0,
        doseUnit: 'mcg/kg/min',
        patientWeightKg: 60.0,
      );
      // Math: (25.0 * 60 * 60) / 1600.0 = 90000 / 1600 = 56.25 mL/hr
      expect(over.pumpRateMlPerHr, closeTo(56.25, 1e-6));
      expect(over.isCeilingExceeded, isTrue);
    });

    test('Dobutamine: 1000 mcg/mL standard, 20 mcg/kg/min ceiling', () {
      final res = SpecializedDosingCalculator.calculateVasoactiveInfusion(
        drug: 'dobutamine',
        orderedDose: 5.0,
        doseUnit: 'mcg/kg/min',
        patientWeightKg: 60.0,
      );
      // Math: (5.0 * 60 * 60) / 1000.0 = 18000 / 1000 = 18.0 mL/hr
      expect(res.pumpRateMlPerHr, closeTo(18.0, 1e-6));
      expect(res.isCeilingExceeded, isFalse);
    });
  });

  group('CHALLENGE 8: End-to-End UI Presentation Verification', () {
    testWidgets('DosageResultCard displays explicit volume badge for Anaphylaxis IM', (tester) async {
      final adultReg = epi!.regimens.firstWhere(
        (r) => r.indication?.contains('Anaphylaxis (Adult)') == true,
      );

      const patient = Patient(
        id: 'pt-ui-test',
        weightKg: 70.0,
        heightCm: 175.0,
        ageYears: 30,
        sex: Sex.male,
        isScrStable: true,
      );

      const result = DosageResult(
        success: true,
        calculatedDose: 0.3,
        roundedDose: 0.3,
        doseUnit: DoseUnit.mg,
        volumeMl: 0.3,
        frequency: 'Stat (repeat 5-15min PRN)',
        formulaUsed: 'Fixed Dose',
        calculationInputs: {'fixedDose': 0.3},
      );

      final state = CalculatorUiState.initial(epi).copyWith(
        selectedRegimen: adultReg,
        result: result,
        status: CalculatorUiStatus.active,
        lastEvaluatedPatient: patient,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DosageResultCard(
                state: state,
                isThai: false,
                onBuildPatient: () => patient,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dosage_result_volume_badge')), findsOneWidget);
      expect(find.textContaining('Volume to Administer: 0.30 mL'), findsOneWidget);
    });

    testWidgets('DosageResultCard displays volume for Pediatric Cardiac Arrest (1.50 mL for 15 kg)', (tester) async {
      final palsReg = epi!.regimens.firstWhere(
        (r) => r.indication?.contains('PALS (Pediatric)') == true,
      );

      const child = Patient(
        id: 'pt-ui-child',
        weightKg: 15.0,
        heightCm: 95.0,
        ageYears: 3,
        sex: Sex.female,
        isScrStable: true,
      );

      const result = DosageResult(
        success: true,
        calculatedDose: 0.15,
        roundedDose: 0.15,
        doseUnit: DoseUnit.mg,
        volumeMl: 1.5,
        frequency: 'q3-5min',
        formulaUsed: 'Weight-based (0.01 mg/kg)',
        calculationInputs: {'dosePerKg': 0.01, 'weightKg': 15.0},
      );

      final state = CalculatorUiState.initial(epi).copyWith(
        selectedRegimen: palsReg,
        result: result,
        status: CalculatorUiStatus.active,
        lastEvaluatedPatient: child,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DosageResultCard(
                state: state,
                isThai: false,
                onBuildPatient: () => child,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dosage_result_volume_badge')), findsOneWidget);
      expect(find.textContaining('Volume to Administer: 1.5 mL'), findsOneWidget);
    });

    testWidgets('IVTitrationScreen displays formatted mcg/mL label in header and table', (tester) async {
      final infusionRegimen = epi!.regimens.firstWhere(
        (r) => r.route == DoseRoute.ivInfusion,
      );

      const patient = Patient(
        id: 'pt-titrate-header',
        ageYears: 50,
        weightKg: 60.0,
        heightCm: 168.0,
        sex: Sex.female,
        isScrStable: true,
      );
      PatientSession.instance.setPatient(patient);

      await tester.pumpWidget(
        MaterialApp(
          home: IVTitrationScreen(
            drug: epi,
            regimen: infusionRegimen,
            isThai: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('16 mcg/mL (0.016 mg/mL) [4 mg in 250 mL]'),
        findsOneWidget,
      );
    });

    testWidgets('DosageResultCard displays unmasked 0.35 mg dose and 0.35 mL volume when 35 kg child exceeds limit (Rule 5)', (tester) async {
      final pedReg = epi!.regimens.firstWhere(
        (r) => r.indication?.contains('Anaphylaxis (Pediatric)') == true,
      );

      const child35 = Patient(
        id: 'pt-ui-child35',
        weightKg: 35.0,
        heightCm: 140.0,
        ageYears: 10,
        sex: Sex.male,
        isScrStable: true,
      );

      final result35 = PharmacistCalculator.calculateDose(
        patient: child35,
        drug: epi,
        regimen: pedReg,
      );

      expect(result35.calculatedDose, closeTo(0.35, 1e-6));
      expect(result35.volumeMl, closeTo(0.35, 1e-6));
      expect(result35.hasHardLimitViolation, isTrue);

      final state = CalculatorUiState.initial(epi).copyWith(
        selectedRegimen: pedReg,
        result: result35,
        warnings: result35.warnings,
        status: CalculatorUiStatus.active,
        lastEvaluatedPatient: child35,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DosageResultCard(
                state: state,
                isThai: false,
                onBuildPatient: () => child35,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify that the critical safety alert banner is shown
      expect(find.text('CRITICAL SAFETY ALERT'), findsOneWidget);

      // Verify that the calculated dose is STILL VISIBLE (0.35 mg) and NOT masked or replaced with 0.0 or 0.3
      expect(find.text('0.35 mg'), findsOneWidget);

      // Verify that the volume to administer is STILL VISIBLE (0.35 mL)
      expect(find.textContaining('Volume to Administer: 0.35 mL'), findsOneWidget);
    });
  });
}
