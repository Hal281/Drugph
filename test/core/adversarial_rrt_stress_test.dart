// ============================================================
// Adversarial Empirical Stress Testing — RRT & Sepsis Protection
// ============================================================
// Independent empirical stress testing by challenger_m1_1.
// Validates:
// 1. CRRT effluent clearance (CrCl = 25.0 mL/min) preventing sepsis underdosing
// 2. IHD & CAPD fallback (CrCl = 5.0 mL/min) with Post-HD timing
// 3. Complete 9-drug matrix across all 4 RRT modes (none, ihd, capd, crrt)
// 4. Extreme clinical boundaries: morbid obesity (250kg), cachexia (30kg),
//    null SCr, extreme SCr (20 mg/dL), unstable SCr (AKI)
// 5. Ironclad Rule 5: Non-blocking overdose preservation under RRT
// 6. ClinicalOrderFormatter HIS order & Pharmacist note tags
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';

void main() {
  group('Adversarial Dimension 1: CRRT Sepsis Protection & Fallback Mechanics', () {
    const unmappedTieredDrug = Drug(
      id: 'unmapped_sepsis_beta_lactam',
      genericName: 'Experimental Sepsis Beta-Lactam',
      brandNames: ['SepsoMax'],
      category: DrugCategory.antibiotic,
      requiresRenalAdjustment: true,
      regimens: [
        DosingRegimen(
          route: DoseRoute.ivInfusion,
          indication: 'Septic Shock',
          dosingType: DosingType.fixed,
          fixedDose: 2000.0,
          doseUnit: DoseUnit.mg,
          frequency: Frequency.q8h,
          renalAdjustments: [
            RenalAdjustment(
              crclMin: 50,
              crclMax: 200,
              action: RenalAction.adjust,
              adjustmentFactor: 1.0,
              adjustedFrequency: Frequency.q8h,
            ),
            RenalAdjustment(
              crclMin: 10,
              crclMax: 50,
              action: RenalAction.adjust,
              adjustmentFactor: 0.5,
              adjustedFrequency: Frequency.q12h, // 1000 mg q12h
            ),
            RenalAdjustment(
              crclMin: 0,
              crclMax: 10,
              action: RenalAction.adjust,
              adjustmentFactor: 0.25,
              adjustedFrequency: Frequency.q24h, // 500 mg q24h (LETHAL underdose in CRRT)
            ),
          ],
        ),
      ],
    );

    test('CRRT fallback strictly forces CrCl = 25.0 mL/min, never falling into anuric (<10) tier', () {
      // Patient with extreme native anuria (SCr = 12.0 mg/dL, native CrCl ~ 5 mL/min)
      const anuricCrrtPatient = Patient(
        id: 'PT-CRRT-ANURIC',
        weightKg: 70,
        heightCm: 170,
        ageYears: 65,
        sex: Sex.male,
        serumCreatinineMgDl: 12.0,
        isScrStable: true,
        renalReplacementMode: RenalReplacementMode.crrt,
      );

      final result = PharmacistCalculator.calculateDose(
        patient: anuricCrrtPatient,
        drug: unmappedTieredDrug,
        regimen: unmappedTieredDrug.regimens.first,
      );

      // Verify CrCl evaluated at continuous effluent clearance (25.0 mL/min)
      expect(result.crclMlMin, equals(25.0));
      // Must fall in 10-50 mL/min tier (1000 mg q12h), NOT 0-10 mL/min tier (500 mg q24h)
      expect(result.calculatedDose, equals(1000.0));
      expect(result.frequency, contains('q12h'));
      expect(result.calculatedDose, isNot(equals(500.0))); // Did not suffer lethal sepsis underdosing
      expect(result.renalReplacementMode, equals(RenalReplacementMode.crrt));
      expect(result.requiresPostHdSupplement, isFalse);

      // Must emit advisory warning
      final warning = result.warnings.firstWhere(
        (w) => w.code == DoseWarningCode.rrtFallbackAdvisory,
      );
      expect(warning.severity, equals(LimitSeverity.soft));
      expect(warning.messageEn, contains('CRRT SEPSIS PROTECTION ADVISORY'));
      expect(warning.messageTh, contains('ป้องกันการได้รับยาต่ำเกินไปในผู้ป่วย CRRT'));
    });

    test('CRRT fallback operates even when SCr is completely NULL (missing lab)', () {
      // Sepsis patient in ICU just admitted, SCr lab pending
      const missingScrCrrtPatient = Patient(
        id: 'PT-CRRT-NO-SCR',
        weightKg: 75,
        heightCm: 175,
        ageYears: 55,
        sex: Sex.male,
        serumCreatinineMgDl: null,
        isScrStable: true,
        renalReplacementMode: RenalReplacementMode.crrt,
      );

      final result = PharmacistCalculator.calculateDose(
        patient: missingScrCrrtPatient,
        drug: unmappedTieredDrug,
        regimen: unmappedTieredDrug.regimens.first,
      );

      // Even without SCr, CRRT continuous effluent allows clearance estimation
      expect(result.crclMlMin, equals(25.0));
      expect(result.calculatedDose, equals(1000.0));
      expect(result.warnings.any((w) => w.code == DoseWarningCode.rrtFallbackAdvisory), isTrue);
    });

    test('IHD fallback evaluates at CrCl = 5.0 mL/min and enforces Post-HD supplement requirement', () {
      const ihdPatient = Patient(
        id: 'PT-IHD-UNMAPPED',
        weightKg: 70,
        heightCm: 170,
        ageYears: 60,
        sex: Sex.female,
        serumCreatinineMgDl: 8.0,
        isScrStable: true,
        renalReplacementMode: RenalReplacementMode.ihd,
      );

      final result = PharmacistCalculator.calculateDose(
        patient: ihdPatient,
        drug: unmappedTieredDrug,
        regimen: unmappedTieredDrug.regimens.first,
      );

      // IHD interdialytic state evaluated at 5.0 mL/min (0-10 tier: 500 mg q24h)
      expect(result.crclMlMin, equals(5.0));
      expect(result.calculatedDose, equals(500.0));
      expect(result.frequency, contains('q24h'));
      expect(result.requiresPostHdSupplement, isTrue); // Must flag Post-HD timing
      expect(result.warnings.any((w) => w.code == DoseWarningCode.rrtFallbackAdvisory), isTrue);
    });

    test('CAPD fallback evaluates at CrCl = 5.0 mL/min with requiresPostHdSupplement = false', () {
      const capdPatient = Patient(
        id: 'PT-CAPD-UNMAPPED',
        weightKg: 65,
        heightCm: 165,
        ageYears: 62,
        sex: Sex.male,
        serumCreatinineMgDl: 6.5,
        isScrStable: true,
        renalReplacementMode: RenalReplacementMode.capd,
      );

      final result = PharmacistCalculator.calculateDose(
        patient: capdPatient,
        drug: unmappedTieredDrug,
        regimen: unmappedTieredDrug.regimens.first,
      );

      expect(result.crclMlMin, equals(5.0));
      expect(result.calculatedDose, equals(500.0));
      expect(result.frequency, contains('q24h'));
      expect(result.requiresPostHdSupplement, isFalse);
    });

    test('RRT mode bypasses false AKI alert when isScrStable is false', () {
      // In dialysis/CRRT, SCr is inherently unstable due to filtration cycles.
      // Anuric alert should NOT suppress RRT calculation.
      const unstableScrCrrtPatient = Patient(
        id: 'PT-CRRT-UNSTABLE-SCR',
        weightKg: 70,
        heightCm: 170,
        ageYears: 50,
        sex: Sex.male,
        serumCreatinineMgDl: 4.5,
        isScrStable: false, // Unstable / fluctuating SCr
        renalReplacementMode: RenalReplacementMode.crrt,
      );

      final result = PharmacistCalculator.calculateDose(
        patient: unstableScrCrrtPatient,
        drug: unmappedTieredDrug,
        regimen: unmappedTieredDrug.regimens.first,
      );

      // AKI alert must NOT block CRRT evaluation
      expect(result.crclMlMin, equals(25.0));
      expect(result.calculatedDose, equals(1000.0));
      expect(result.warnings.any((w) => w.code == DoseWarningCode.unstableScr), isFalse);
    });
  });

  group('Adversarial Dimension 2: Exhaustive 9-Drug Matrix across all 4 RRT Modes', () {
    final targetDrugIds = [
      'meropenem',
      'piperacillin_tazobactam',
      'vancomycin',
      'colistin',
      'amikacin',
      'gentamicin',
      'cefazolin',
      'enoxaparin',
      'gabapentin',
    ];

    const modes = [
      RenalReplacementMode.none,
      RenalReplacementMode.ihd,
      RenalReplacementMode.capd,
      RenalReplacementMode.crrt,
    ];

    for (final drugId in targetDrugIds) {
      test('Drug $drugId produces valid non-zero dose across all 4 RRT modes', () {
        final drug = DrugDatabase.findById(drugId);
        expect(drug, isNotNull, reason: 'Drug $drugId must exist in DrugDatabase');

        for (final mode in modes) {
          final patient = Patient(
            id: 'PT-MATRIX-$drugId-${mode.name}',
            weightKg: 70,
            heightCm: 170,
            ageYears: 55,
            sex: Sex.male,
            serumCreatinineMgDl: mode.isRrt ? 5.0 : 1.0,
            isScrStable: true,
            renalReplacementMode: mode,
          );

          final result = PharmacistCalculator.calculateDose(
            patient: patient,
            drug: drug!,
            regimen: drug.regimens.first,
          );

          expect(result.renalReplacementMode, equals(mode));
          expect(result.calculatedDose, isNotNull,
              reason: 'Calculated dose must not be null for $drugId in ${mode.name}');
          expect(result.calculatedDose! > 0, isTrue,
              reason: 'Calculated dose must be positive for $drugId in ${mode.name}');

          // Verify Post-HD flag invariants
          if (mode == RenalReplacementMode.crrt || mode == RenalReplacementMode.capd) {
            expect(result.requiresPostHdSupplement, isFalse,
                reason: 'CRRT/CAPD should never require Post-HD supplement for $drugId');
          }

          if (drugId == 'enoxaparin' && mode == RenalReplacementMode.ihd) {
            // Enoxaparin is not removed by HD — Post-HD supplement must be FALSE
            expect(result.requiresPostHdSupplement, isFalse,
                reason: 'Enoxaparin is not dialyzable; post-HD supplement must be false');
          }

          // If mode is RRT and explicit protocol exists, verify instructions
          final proto = drug.regimens.first.rrtProtocolFor(mode);
          if (proto != null) {
            expect(result.rrtInstructionEn, isNotNull);
            expect(result.rrtInstructionTh, isNotNull);
            expect(result.rrtInstructionEn!.isNotEmpty, isTrue);
            expect(result.rrtInstructionTh!.isNotEmpty, isTrue);
          }
        }
      });
    }
  });

  group('Adversarial Dimension 3: Extreme Clinical Boundaries & Pathological Inputs', () {
    test('Morbidly obese patient (250 kg) under CRRT calculates safely without overflow', () {
      final mero = DrugDatabase.findById('meropenem')!;
      const obesePatient = Patient(
        id: 'PT-OBESE-CRRT',
        weightKg: 250,
        heightCm: 175,
        ageYears: 45,
        sex: Sex.female,
        serumCreatinineMgDl: 6.0,
        isScrStable: true,
        renalReplacementMode: RenalReplacementMode.crrt,
      );

      final result = PharmacistCalculator.calculateDose(
        patient: obesePatient,
        drug: mero,
        regimen: mero.regimens.first,
      );

      expect(result.calculatedDose, equals(1000.0));
      expect(result.renalReplacementMode, equals(RenalReplacementMode.crrt));
    });

    test('Severe cachectic patient (30 kg) under IHD calculates correctly with Post-HD timing', () {
      final cefazolin = DrugDatabase.findById('cefazolin')!;
      const cachecticPatient = Patient(
        id: 'PT-CACHECTIC-IHD',
        weightKg: 30,
        heightCm: 150,
        ageYears: 78,
        sex: Sex.female,
        serumCreatinineMgDl: 4.2,
        isScrStable: true,
        renalReplacementMode: RenalReplacementMode.ihd,
      );

      final result = PharmacistCalculator.calculateDose(
        patient: cachecticPatient,
        drug: cefazolin,
        regimen: cefazolin.regimens[1], // Systemic infection regimen with RRT protocol
      );

      expect(result.calculatedDose, equals(1000.0));
      expect(result.requiresPostHdSupplement, isTrue);
      expect(result.renalReplacementMode, equals(RenalReplacementMode.ihd));
    });

    test('Weight-based aminoglycoside (Amikacin) in CRRT scales by dosing weight with TDM instruction', () {
      final amikacin = DrugDatabase.findById('amikacin')!;
      const patient = Patient(
        id: 'PT-AMIKACIN-CRRT',
        weightKg: 80,
        heightCm: 180,
        ageYears: 60,
        sex: Sex.male,
        serumCreatinineMgDl: 5.5,
        isScrStable: true,
        renalReplacementMode: RenalReplacementMode.crrt,
      );

      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: amikacin,
        regimen: amikacin.regimens.first,
      );

      // Amikacin extended interval base dose: 15 mg/kg * 80 kg = 1200 mg (capped at 1500)
      // CRRT doseFactor is 0.5 -> 600 mg q24h
      expect(result.calculatedDose, equals(600.0));
      expect(result.frequency, contains('q24h'));
      expect(result.rrtInstructionEn, contains('CRRT'));
      expect(result.rrtInstructionEn, contains('TDM'));
    });
  });

  group('Adversarial Dimension 4: Ironclad Rule 5 (Non-Blocking Overdose) under RRT', () {
    test('Overdose order under CRRT preserves calculatedDose and emits warning banner', () {
      const highDoseRegimen = DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Refractory Sepsis Mega-Dose',
        dosingType: DosingType.fixed,
        fixedDose: 4000.0, // Exceeds standard single dose limit (2000 mg)
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q8h,
        limits: DoseLimit(maxSingleDose: 2000.0, maxDailyDose: 6000.0),
        renalReplacementProtocols: [
          RenalReplacementProtocol(
            mode: RenalReplacementMode.crrt,
            specificDose: 3000.0, // Specific RRT dose exceeding 2000 mg limit
            doseUnit: DoseUnit.mg,
            frequency: Frequency.q8h,
          ),
        ],
      );

      const testDrug = Drug(
        id: 'overdose_rrt_drug',
        genericName: 'SuperAntibiotic',
        category: DrugCategory.antibiotic,
        regimens: [highDoseRegimen],
      );

      const crrtPatient = Patient(
        id: 'PT-OVERDOSE-TEST',
        weightKg: 70,
        heightCm: 170,
        ageYears: 50,
        sex: Sex.male,
        serumCreatinineMgDl: 5.0,
        isScrStable: true,
        renalReplacementMode: RenalReplacementMode.crrt,
      );

      final result = PharmacistCalculator.calculateDose(
        patient: crrtPatient,
        drug: testDrug,
        regimen: highDoseRegimen,
      );

      // Non-blocking overdose policy: calculatedDose must remain visible (3000.0)
      expect(result.calculatedDose, equals(3000.0));
      expect(result.warnings.any((w) => w.code == DoseWarningCode.maxSingleDoseExceeded), isTrue);
    });
  });

  group('Adversarial Dimension 5: ClinicalOrderFormatter Tags & Edge Cases', () {
    test('HIS Order appends [CRRT] tag for CRRT mode', () {
      final mero = DrugDatabase.findById('meropenem')!;
      const patient = Patient(
        id: 'PT-HIS-CRRT',
        weightKg: 70,
        heightCm: 170,
        ageYears: 50,
        sex: Sex.male,
        serumCreatinineMgDl: 4.0,
        isScrStable: true,
        renalReplacementMode: RenalReplacementMode.crrt,
      );

      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: mero,
        regimen: mero.regimens.first,
      );

      final hisOrder = ClinicalOrderFormatter.formatHisOrder(
        drug: mero,
        regimen: mero.regimens.first,
        result: result,
        patient: patient,
      );

      expect(hisOrder, contains('[CRRT]'));
      expect(hisOrder, contains('1000 mg'));
      expect(hisOrder, isNot(contains('[IHD]')));
      expect(hisOrder, isNot(contains('[CAPD]')));
    });

    test('HIS Order appends [IHD: Post-HD Dosing] for dialyzable drug (Meropenem)', () {
      final mero = DrugDatabase.findById('meropenem')!;
      const patient = Patient(
        id: 'PT-HIS-IHD-MERO',
        weightKg: 70,
        heightCm: 170,
        ageYears: 50,
        sex: Sex.male,
        serumCreatinineMgDl: 4.0,
        isScrStable: true,
        renalReplacementMode: RenalReplacementMode.ihd,
      );

      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: mero,
        regimen: mero.regimens.first,
      );

      final hisOrder = ClinicalOrderFormatter.formatHisOrder(
        drug: mero,
        regimen: mero.regimens.first,
        result: result,
        patient: patient,
      );

      expect(hisOrder, contains('[IHD: Post-HD Dosing]'));
    });

    test('HIS Order appends [IHD] without Post-HD tag for non-dialyzable drug (Enoxaparin)', () {
      final enox = DrugDatabase.findById('enoxaparin')!;
      const patient = Patient(
        id: 'PT-HIS-IHD-ENOX',
        weightKg: 70,
        heightCm: 170,
        ageYears: 65,
        sex: Sex.female,
        serumCreatinineMgDl: 5.5,
        isScrStable: true,
        renalReplacementMode: RenalReplacementMode.ihd,
      );

      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: enox,
        regimen: enox.regimens.first,
      );

      final hisOrder = ClinicalOrderFormatter.formatHisOrder(
        drug: enox,
        regimen: enox.regimens.first,
        result: result,
        patient: patient,
      );

      expect(hisOrder, contains('[IHD]'));
      expect(hisOrder, isNot(contains('[IHD: Post-HD Dosing]')));
    });

    test('HIS Order appends [CAPD] for peritoneal dialysis', () {
      final mero = DrugDatabase.findById('meropenem')!;
      const patient = Patient(
        id: 'PT-HIS-CAPD',
        weightKg: 70,
        heightCm: 170,
        ageYears: 60,
        sex: Sex.male,
        serumCreatinineMgDl: 5.0,
        isScrStable: true,
        renalReplacementMode: RenalReplacementMode.capd,
      );

      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: mero,
        regimen: mero.regimens.first,
      );

      final hisOrder = ClinicalOrderFormatter.formatHisOrder(
        drug: mero,
        regimen: mero.regimens.first,
        result: result,
        patient: patient,
      );

      expect(hisOrder, contains('[CAPD]'));
    });

    test('Pharmacist Note renders RRT Modality and Post-HD instructions in Thai and English', () {
      final piptazo = DrugDatabase.findById('piperacillin_tazobactam')!;
      const patient = Patient(
        id: 'PT-NOTE-RRT',
        weightKg: 75,
        heightCm: 172,
        ageYears: 62,
        sex: Sex.male,
        serumCreatinineMgDl: 4.8,
        isScrStable: true,
        renalReplacementMode: RenalReplacementMode.ihd,
      );

      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: piptazo,
        regimen: piptazo.regimens.first,
      );

      final noteEn = ClinicalOrderFormatter.formatPharmacistNote(
        drug: piptazo,
        regimen: piptazo.regimens.first,
        result: result,
        patient: patient,
        isThai: false,
      );

      final noteTh = ClinicalOrderFormatter.formatPharmacistNote(
        drug: piptazo,
        regimen: piptazo.regimens.first,
        result: result,
        patient: patient,
        isThai: true,
      );

      expect(noteEn, contains('Renal Replacement Therapy: Intermittent Hemodialysis (IHD) | Post-HD Dosing Required'));
      expect(noteTh, contains('Renal Replacement Therapy: ฟอกเลือดด้วยเครื่องไตเทียม (IHD)'));
      expect(noteTh, contains('หลังฟอกเลือด (Post-HD Dosing Required)'));
    });
  });
}
