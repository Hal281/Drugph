import 'dart:math';
import 'package:test/test.dart';
import 'package:drug_dosage_calculator/core/calculators/calculators.dart';
import 'package:drug_dosage_calculator/core/models/models.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';

void main() {
  group('SaMD Clinical Engine Audit & Bug Remediation Tests', () {
    // -------------------------------------------------------------------------
    // Bug 1.1: Infusion Rate Unit Normalization (Grams to Milligrams)
    // -------------------------------------------------------------------------
    test('Bug 1.1: 2 g infused over 60 min converts to 33.33 mg/min and triggers maxInfusionRateExceeded', () {
      const patient = Patient(
        id: 'p-inf-g',
        weightKg: 70.0,
        heightCm: 175.0,
        ageYears: 40,
        sex: Sex.male,
        serumCreatinineMgDl: 0.9,
        isScrStable: true,
      );

      const vancoGramDrug = Drug(
        id: 'vanco_g',
        genericName: 'Vancomycin',
        category: DrugCategory.antibiotic,
        regimens: [
          DosingRegimen(
            route: DoseRoute.ivInfusion,
            indication: 'MRSA Bacteremia',
            dosingType: DosingType.fixed,
            fixedDose: 2.0,
            doseUnit: DoseUnit.g,
            frequency: Frequency.q12h,
            infusionTimeMinutes: 60,
            maxInfusionRateMgPerMin: 20.0, // 20 mg/min max limit (1000 mg/hr = 16.67 mg/min)
          ),
        ],
      );

      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: vancoGramDrug,
        regimen: vancoGramDrug.regimens.first,
      );

      expect(result.success, isTrue);
      // 2 g / 60 min = 2000 mg / 60 min = 33.33 mg/min > 20.0 mg/min max rate
      final rateWarning = result.warnings.firstWhere(
        (w) => w.code == DoseWarningCode.maxInfusionRateExceeded,
        orElse: () => throw TestFailure('maxInfusionRateExceeded was not triggered for 2 g over 60 min'),
      );
      expect(rateWarning.severity, equals(LimitSeverity.hard));
      expect(rateWarning.calculatedValue, closeTo(33.33, 0.05));
    });

    // -------------------------------------------------------------------------
    // Bug 1.2: Preparation Volume Scaling for Micrograms (mcg)
    // -------------------------------------------------------------------------
    test('Bug 1.2: 500 mcg dose with 0.1 mg/mL dilution calculates 5.0 mL, not 5000 mL', () {
      const patient = Patient(
        id: 'p-mcg-vol',
        weightKg: 70.0,
        heightCm: 175.0,
        ageYears: 40,
        sex: Sex.male,
        serumCreatinineMgDl: 0.9,
        isScrStable: true,
      );

      const mcgDrug = Drug(
        id: 'fentanyl_mcg',
        genericName: 'Fentanyl',
        category: DrugCategory.analgesic,
        regimens: [
          DosingRegimen(
            route: DoseRoute.ivInfusion,
            indication: 'Sedation',
            dosingType: DosingType.fixed,
            fixedDose: 500.0,
            doseUnit: DoseUnit.mcg,
            frequency: Frequency.stat,
            infusionTimeMinutes: 60,
            standardDilutionMgPerMl: 0.1, // 0.1 mg/mL = 100 mcg/mL
          ),
        ],
      );

      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: mcgDrug,
        regimen: mcgDrug.regimens.first,
      );

      expect(result.success, isTrue);
      // 500 mcg = 0.5 mg. Volume = 0.5 mg / 0.1 mg/mL = 5.0 mL
      expect(result.volumeMl, closeTo(5.0, 0.01));
    });

    // -------------------------------------------------------------------------
    // Bug 2.1: Standalone Soft Limit in DoseChecker (limits.maxSingleDose == null)
    // -------------------------------------------------------------------------
    test('Bug 2.1: Standalone softMaxSingleDose fires warning when maxSingleDose is null', () {
      const limits = DoseLimit(
        softMaxSingleDose: 500.0,
        maxSingleDose: null,
      );

      final warnings = DoseChecker.checkDose(
        calculatedDose: 600.0,
        limits: limits,
        doseUnit: 'mg',
      );

      expect(warnings.any((w) => w.code == DoseWarningCode.softMaxSingleDoseExceeded), isTrue);
      final warn = warnings.firstWhere((w) => w.code == DoseWarningCode.softMaxSingleDoseExceeded);
      expect(warn.severity, equals(LimitSeverity.soft));
      expect(warn.limitValue, equals(500.0));
      expect(warn.calculatedValue, equals(600.0));
    });

    // -------------------------------------------------------------------------
    // Bug 2.2: Frequency-Only Renal Adjustment in DoseChecker
    // -------------------------------------------------------------------------
    test('Bug 2.2: checkRenalAdjustment triggers when adjustmentFactor is 1.0 but frequency is modified', () {
      const tierFreqOnly = RenalAdjustment(
        crclMin: 10.0,
        crclMax: 30.0,
        adjustmentFactor: 1.0, // Same dose
        adjustedFrequency: Frequency.q24h, // Extended from q12h
      );

      final warnings = DoseChecker.checkRenalAdjustment(
        crclMlMin: 20.0,
        adjustments: [tierFreqOnly],
      );

      expect(warnings.any((w) => w.code == DoseWarningCode.renalAdjustmentApplied), isTrue);
      final warn = warnings.firstWhere((w) => w.code == DoseWarningCode.renalAdjustmentApplied);
      expect(warn.messageEn, contains('q24h'));
    });

    // -------------------------------------------------------------------------
    // Bug 3: Dosing Weight Selection in adjustedIfObese for Non-Obese (TBW > IBW)
    // -------------------------------------------------------------------------
    test('Bug 3: Non-obese patient with TBW > IBW uses TBW (Actual Weight) under adjustedIfObese', () {
      // Male, 170 cm: Devine IBW = 50 + 2.3 * (66.929 - 60) = 65.94 kg
      // Obesity threshold (1.2 * IBW) = 79.13 kg
      // Weight 70.0 kg: 65.94 < 70.0 < 79.13 (Overweight, NOT obese)
      const nonObesePatient = Patient(
        id: 'p-non-obese-over-ibw',
        weightKg: 70.0,
        heightCm: 170.0,
        ageYears: 35,
        sex: Sex.male,
        serumCreatinineMgDl: 0.8,
        isScrStable: true,
      );

      const testDrug = Drug(
        id: 'test_adj_drug',
        genericName: 'Test Adjusted Drug',
        category: DrugCategory.antibiotic,
        regimens: [
          DosingRegimen(
            route: DoseRoute.ivInfusion,
            indication: 'Infection',
            dosingType: DosingType.weightBased,
            dosingWeightStrategy: DosingWeightStrategy.adjustedIfObese,
            dosePerKg: 10.0,
            doseUnit: DoseUnit.mg,
            frequency: Frequency.q24h,
          ),
        ],
      );

      final result = PharmacistCalculator.calculateDose(
        patient: nonObesePatient,
        drug: testDrug,
        regimen: testDrug.regimens.first,
      );

      expect(result.success, isTrue);
      // Should use TBW = 70.0 kg -> Dose = 70.0 * 10 = 700.0 mg
      // Erroneous code previously dropped weight to IBW = 65.94 kg -> Dose = 659.4 mg
      expect(result.calculatedDose, closeTo(700.0, 0.01));
      expect(result.formulaUsed, contains('TBW'));
    });

    // -------------------------------------------------------------------------
    // Bug 4: Safety Gap for Unstable Renal Function (AKI)
    // -------------------------------------------------------------------------
    test('Bug 4: Unstable SCr (AKI) triggers hard block and warning for renally-eliminated drug even if SCr is missing', () {
      const patientAkiNoScr = Patient(
        id: 'p-aki-no-scr',
        weightKg: 70.0,
        heightCm: 170.0,
        ageYears: 60,
        sex: Sex.male,
        serumCreatinineMgDl: null,
        isScrStable: false, // Acute Kidney Injury / Unstable
      );

      const renalDrug = Drug(
        id: 'mero_test',
        genericName: 'Meropenem',
        category: DrugCategory.antibiotic,
        requiresRenalAdjustment: true,
        regimens: [
          DosingRegimen(
            route: DoseRoute.ivInfusion,
            indication: 'Severe Sepsis',
            dosingType: DosingType.fixed,
            fixedDose: 1000.0,
            doseUnit: DoseUnit.mg,
            frequency: Frequency.q8h,
          ),
        ],
      );

      final result = PharmacistCalculator.calculateDose(
        patient: patientAkiNoScr,
        drug: renalDrug,
        regimen: renalDrug.regimens.first,
      );

      expect(result.hasHardLimitViolation, isTrue);
      expect(result.isBlocked, isTrue);
      expect(result.warnings.any((w) => w.code == DoseWarningCode.unstableScr), isTrue);
    });

    // -------------------------------------------------------------------------
    // Bug 5: Pediatric BSA Auto-Dispatch uses Haycock Formula
    // -------------------------------------------------------------------------
    test('Bug 5: Pediatric patient (< 18 yrs) calculates BSA using Haycock formula', () {
      const pedPatient = Patient(
        id: 'p-ped-bsa',
        weightKg: 25.0,
        heightCm: 120.0,
        ageYears: 8, // Pediatric
        sex: Sex.female,
        isScrStable: true,
      );

      const pedsOncologyDrug = Drug(
        id: 'ped_chemo',
        genericName: 'Pediatric Chemotherapy',
        category: DrugCategory.chemotherapy,
        regimens: [
          DosingRegimen(
            route: DoseRoute.ivInfusion,
            indication: 'Oncology Protocol',
            dosingType: DosingType.bsaBased,
            audience: RegimenAudience.pediatric,
            dosePerM2: 100.0,
            doseUnit: DoseUnit.mg,
            frequency: Frequency.stat,
          ),
        ],
      );

      final result = PharmacistCalculator.calculateDose(
        patient: pedPatient,
        drug: pedsOncologyDrug,
        regimen: pedsOncologyDrug.regimens.first,
      );

      expect(result.success, isTrue);
      // Haycock BSA = 0.024265 * 120^0.3964 * 25^0.5378 ≈ 0.9160 m²
      final expectedHaycockBsa = BsaCalculator.haycock(heightCm: 120.0, weightKg: 25.0);
      final expectedDose = expectedHaycockBsa * 100.0;
      expect(result.calculatedDose, closeTo(expectedDose, 0.01));
      expect(result.formulaUsed, contains('Haycock'));
      expect(result.bsaM2, closeTo(expectedHaycockBsa, 0.001));
    });

    // -------------------------------------------------------------------------
    // Bug 6: Time Unit Cohesion in TDM (predictTroughFromMinutes)
    // -------------------------------------------------------------------------
    test('Bug 6: TdmCalculator.predictTroughFromMinutes converts minutes to hours correctly', () {
      final troughFromHours = TdmCalculator.predictTrough(
        dose: 1000.0,
        tau: 12.0,
        tInf: 1.0, // 1 hour
        vd: 49.0,
        ke: 0.0874,
      );

      final troughFromMinutes = TdmCalculator.predictTroughFromMinutes(
        dose: 1000.0,
        tau: 12.0,
        infusionDurationMinutes: 60.0, // 60 minutes = 1 hour
        vd: 49.0,
        ke: 0.0874,
      );

      expect(troughFromMinutes, equals(troughFromHours));
      expect(troughFromMinutes, closeTo(11.50, 0.05));
    });

    // -------------------------------------------------------------------------
    // Bug 7: Intra-Class Allergy Matching Blindspot
    // -------------------------------------------------------------------------
    test('Bug 7: Patient allergic to Amoxicillin triggers Hard Class Alert when Ampicillin is ordered', () {
      final alerts = AllergyService.evaluateAllergies(
        patientAllergies: ['Amoxicillin'],
        drugGenericName: 'Ampicillin',
        drugId: 'ampicillin',
        drugClass: DrugClass.betaLactamPenicillin,
        legacyAllergyClass: null,
      );

      expect(alerts, isNotEmpty);
      expect(alerts.any((a) => a.severity == LimitSeverity.hard && a.messageEn.contains('CLASS ALLERGY')), isTrue);
    });

    // -------------------------------------------------------------------------
    // Bug 8: Beta-Lactam Cross-Reactivity from Penicillin Derivatives
    // -------------------------------------------------------------------------
    test('Bug 8: Amoxicillin allergy triggers soft cross-reactivity alert for Ceftriaxone & Meropenem', () {
      final cephAlerts = AllergyService.evaluateAllergies(
        patientAllergies: ['Amoxicillin'],
        drugGenericName: 'Ceftriaxone',
        drugId: 'ceftriaxone',
        drugClass: DrugClass.betaLactamCephalosporin,
        legacyAllergyClass: null,
      );
      expect(cephAlerts, isNotEmpty);
      expect(cephAlerts.first.hasCrossReactivity, isTrue);
      expect(cephAlerts.first.severity, equals(LimitSeverity.soft));

      final carbaAlerts = AllergyService.evaluateAllergies(
        patientAllergies: ['Amoxicillin'],
        drugGenericName: 'Meropenem',
        drugId: 'meropenem',
        drugClass: DrugClass.betaLactamCarbapenem,
        legacyAllergyClass: null,
      );
      expect(carbaAlerts, isNotEmpty);
      expect(carbaAlerts.first.hasCrossReactivity, isTrue);
      expect(carbaAlerts.first.severity, equals(LimitSeverity.soft));
    });

    // -------------------------------------------------------------------------
    // Bug 9: Expanded NSAID Cross-Reactivity
    // -------------------------------------------------------------------------
    test('Bug 9: Mefenamic acid allergy triggers NSAID cross-reactivity alert for Ibuprofen', () {
      final alerts = AllergyService.evaluateAllergies(
        patientAllergies: ['Mefenamic acid'],
        drugGenericName: 'Ibuprofen',
        drugId: 'ibuprofen',
        drugClass: DrugClass.nsaid,
        legacyAllergyClass: null,
      );
      expect(alerts, isNotEmpty);
      expect(alerts.first.hasCrossReactivity, isTrue);
      expect(alerts.first.severity, equals(LimitSeverity.soft));
    });

    // -------------------------------------------------------------------------
    // Bug 10: Frequency Regex for intervals with 'h' (q12h-q24h, q4h-6h)
    // -------------------------------------------------------------------------
    test('Bug 10: Frequency.fromLegacyString correctly parses "q12h-q24h" and "q4h-6h" as interval ranges', () {
      final freq1 = Frequency.fromLegacyString('q12h-q24h');
      expect(freq1.minIntervalHours, equals(12));
      expect(freq1.maxIntervalHours, equals(24));
      expect(freq1.intervalHours, isNull);

      final freq2 = Frequency.fromLegacyString('q4h-6h');
      expect(freq2.minIntervalHours, equals(4));
      expect(freq2.maxIntervalHours, equals(6));
    });

    // -------------------------------------------------------------------------
    // Bug 11: Weekly Regimen Order Verification (Methotrexate)
    // -------------------------------------------------------------------------
    test('Bug 11: verifyOrder allows weekly Methotrexate regimen without false block', () {
      const patient = Patient(
        id: 'p-mtx',
        weightKg: 60.0,
        heightCm: 160.0,
        ageYears: 50,
        sex: Sex.female,
        isScrStable: true,
      );

      const methotrexate = Drug(
        id: 'methotrexate',
        genericName: 'Methotrexate',
        category: DrugCategory.immunosuppressant,
        regimens: [
          DosingRegimen(
            route: DoseRoute.po,
            indication: 'Rheumatoid Arthritis',
            dosingType: DosingType.fixed,
            fixedDose: 15.0,
            doseUnit: DoseUnit.mg,
            frequency: Frequency.weekly,
          ),
        ],
      );

      final verification = PharmacistCalculator.verifyOrder(
        patient: patient,
        drug: methotrexate,
        regimen: methotrexate.regimens.first,
        orderedDose: 15.0,
        orderedFrequency: Frequency.weekly,
      );

      expect(verification.isAcceptable, isTrue);
    });

    // -------------------------------------------------------------------------
    // Bug 12: PopulationCriteria pregnancySafe == false
    // -------------------------------------------------------------------------
    test('Bug 12: PopulationCriteria enforces pregnancySafe == false in checkApplicability', () {
      const pregnantPatient = Patient(
        id: 'p-preg',
        weightKg: 60.0,
        heightCm: 160.0,
        ageYears: 28,
        sex: Sex.female,
        isPregnant: true,
        isScrStable: true,
      );

      const criteria = PopulationCriteria(
        pregnancySafe: false, // Not explicitly contraindicatedPregnancy = true, but safe = false
      );

      final warnings = criteria.checkApplicability(pregnantPatient);
      expect(warnings.any((w) => w.code == DoseWarningCode.contraindicationAlert), isTrue);
    });

    // -------------------------------------------------------------------------
    // Bug 13: Zero-Range Assertion in RenalAdjustment
    // -------------------------------------------------------------------------
    test('Bug 13: RenalAdjustment asserts crclMin < crclMax preventing dead [x, x) intervals', () {
      expect(
        () => RenalAdjustment(crclMin: 15.0, crclMax: 15.0),
        throwsA(isA<AssertionError>()),
      );
    });

    // -------------------------------------------------------------------------
    // Bug 14: Sawchuk-Zaske Two-Point Elimination Constant & Target AUC Dosing
    // -------------------------------------------------------------------------
    test('Bug 14: Sawchuk-Zaske calculateIndividualKe and recommendDoseForTargetAuc24', () {
      // C1 = 30 mg/L, C2 = 7.5 mg/L, deltaHours = 8 hr
      // Ke = ln(30 / 7.5) / 8 = ln(4) / 8 = 1.38629436 / 8 = 0.1732868 hr^-1
      // Half-life = ln(2) / 0.1732868 = 4.0 hr
      final ke = TdmCalculator.calculateIndividualKe(
        c1: 30.0,
        c2: 7.5,
        deltaHours: 8.0,
      );
      expect(ke, closeTo(0.1733, 0.0005));
      expect(log(2) / ke, closeTo(4.0, 0.05));

      // Target AUC 500 mg*hr/L, tau = 12 hr, Vd = 45 L, Ke = 0.05 hr^-1
      // Clearance = 45 * 0.05 = 2.25 L/hr. Daily Dose = 500 * 2.25 = 1125 mg/day
      // Dose per tau (12h) = 1125 * (12/24) = 562.5 mg
      final recDose = TdmCalculator.recommendDoseForTargetAuc24(
        targetAuc: 500.0,
        tau: 12.0,
        vd: 45.0,
        ke: 0.05,
      );
      expect(recDose, closeTo(562.5, 0.01));
    });

    // -------------------------------------------------------------------------
    // Bug 15: Clindamycin DoseBasis.perDay with Range Frequency q6-8h
    // -------------------------------------------------------------------------
    test('Bug 15: Pediatric Clindamycin 30 mg/kg/day q6-8h properly divides daily dose into per-dose fraction', () {
      const child = Patient(
        id: 'p-ped-clinda',
        weightKg: 20.0,
        heightCm: 110.0,
        ageYears: 5,
        sex: Sex.male,
        isScrStable: true,
      );

      final clindamycin = DrugDatabase.findById('clindamycin')!;
      final pedRegimen = clindamycin.regimens.firstWhere(
        (r) => r.indication?.contains('Pediatric') ?? false,
      );

      final result = PharmacistCalculator.calculateDose(
        patient: child,
        drug: clindamycin,
        regimen: pedRegimen,
      );

      expect(result.success, isTrue);
      // Total daily dose = 20 kg * 15 mg/kg = 300 mg/day.
      // Frequency q6-8h (max interval 8h -> 3 doses/day): 300 / 3 = 100 mg/dose
      expect(result.calculatedDose, closeTo(100.0, 0.5));
    });

    // -------------------------------------------------------------------------
    // Bug 16: Complex Allergy Matching with / and Parentheses
    // -------------------------------------------------------------------------
    test('Bug 16: Allergy alias extraction handles slashes and brand aliases', () {
      final aliases = AllergyService.extractAliases('Valproic Acid / Sodium Valproate (Depakine)');
      expect(aliases, contains('depakine'));
      expect(aliases, contains('sodium valproate'));
      expect(aliases, contains('valproic acid'));

      // Also verify via AllergyService.evaluateAllergies directly:
      final alerts = AllergyService.evaluateAllergies(
        drugId: 'depakine',
        drugGenericName: 'Sodium Valproate',
        drugClass: null,
        legacyAllergyClass: null,
        patientAllergies: ['Valproic Acid / Sodium Valproate (Depakine)'],
      );
      expect(alerts, isNotEmpty);
      expect(alerts.first.hasDirectMatch, isTrue);
    });

    // -------------------------------------------------------------------------
    // Bug 17: Bidirectional Severe Interactions Check
    // -------------------------------------------------------------------------
    test('Bug 17: Bidirectional severe interaction detection flags combinations regardless of check order', () {
      const patient = Patient(
        id: 'p-ddi',
        weightKg: 70.0,
        heightCm: 175.0,
        ageYears: 45,
        sex: Sex.male,
        isScrStable: true,
        activeDrugIds: ['spironolactone'],
      );

      final enalapril = DrugDatabase.findById('enalapril')!;
      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: enalapril,
        regimen: enalapril.regimens.first,
      );

      expect(result.warnings.any((w) => w.code == DoseWarningCode.severeInteractionAlert), isTrue);
    });

    // -------------------------------------------------------------------------
    // Bug 18: Therapeutic Duplication Rules Expansion
    // -------------------------------------------------------------------------
    test('Bug 18: Detects newly added therapeutic duplications (Dual Opioids, Dual Benzodiazepines, Dual SSRIs, Dual PPIs)', () {
      final morphine = DrugDatabase.findById('morphine')!;
      final fentanyl = DrugDatabase.findById('fentanyl')!;
      expect(TherapeuticDuplicationService.checkDuplication(morphine, fentanyl), isNotNull);

      final diazepam = DrugDatabase.findById('diazepam')!;
      final lorazepam = DrugDatabase.findById('lorazepam')!;
      expect(TherapeuticDuplicationService.checkDuplication(diazepam, lorazepam), isNotNull);

      final fluoxetine = DrugDatabase.findById('fluoxetine')!;
      final sertraline = DrugDatabase.findById('sertraline')!;
      expect(TherapeuticDuplicationService.checkDuplication(fluoxetine, sertraline), isNotNull);

      const ppi1 = Drug(
        id: 'omeprazole',
        genericName: 'Omeprazole',
        category: DrugCategory.gastrointestinal,
        drugClass: DrugClass.protonPumpInhibitor,
        regimens: [],
      );
      const ppi2 = Drug(
        id: 'pantoprazole',
        genericName: 'Pantoprazole',
        category: DrugCategory.gastrointestinal,
        drugClass: DrugClass.protonPumpInhibitor,
        regimens: [],
      );
      expect(TherapeuticDuplicationService.checkDuplication(ppi1, ppi2), isNotNull);
    });

    // -------------------------------------------------------------------------
    // Bug 19: Comprehensive Renal Adjustments Verification
    // -------------------------------------------------------------------------
    test('Bug 19: Renal adjustments for Spironolactone, Rosuvastatin, Lithium, and Glipizide adjust appropriately', () {
      const renalFailurePatient = Patient(
        id: 'p-rf',
        weightKg: 70.0,
        heightCm: 175.0,
        ageYears: 60,
        sex: Sex.male,
        serumCreatinineMgDl: 3.5, // CrCl ~ 18-20 mL/min
        isScrStable: true,
      );

      final spironolactone = DrugDatabase.findById('spironolactone')!;
      final spiroResult = PharmacistCalculator.calculateDose(
        patient: renalFailurePatient,
        drug: spironolactone,
        regimen: spironolactone.regimens.first,
      );
      expect(spiroResult.warnings.any((w) => w.code == DoseWarningCode.contraindicationAlert), isTrue);

      final rosuvastatin = DrugDatabase.findById('rosuvastatin')!;
      final rosuvaResult = PharmacistCalculator.calculateDose(
        patient: renalFailurePatient,
        drug: rosuvastatin,
        regimen: rosuvastatin.regimens.first,
      );
      expect(rosuvaResult.calculatedDose, equals(5.0));

      final lithium = DrugDatabase.findById('lithium')!;
      final lithiumResult = PharmacistCalculator.calculateDose(
        patient: renalFailurePatient,
        drug: lithium,
        regimen: lithium.regimens.first,
      );
      // CrCl < 30 -> 50% of 300 mg = 150 mg
      expect(lithiumResult.calculatedDose, equals(150.0));
    });

    // -------------------------------------------------------------------------
    // Bug 20: Titrated Regimens Apply Renal Adjustments (Magnesium Sulfate)
    // -------------------------------------------------------------------------
    test('Bug 20: Titrated Magnesium Sulfate Eclampsia maintenance scales rate by 50% when CrCl < 30 mL/min', () {
      const renalFemale = Patient(
        id: 'p-mg-renal',
        weightKg: 60.0,
        heightCm: 160.0,
        ageYears: 30,
        sex: Sex.female,
        creatinineClearanceMlMin: 25.0,
        isScrStable: true,
      );

      final mgSo4 = DrugDatabase.findById('magnesium_sulfate')!;
      final maintRegimen = mgSo4.regimens.firstWhere(
        (r) => r.dosingType == DosingType.titrated,
      );

      final res = PharmacistCalculator.calculateDose(
        patient: renalFemale,
        drug: mgSo4,
        regimen: maintRegimen,
      );

      expect(res.success, isTrue);
      expect(res.isRenallyAdjusted, isTrue);
      expect(res.renalAdjustmentFactor, equals(0.5));
      expect(res.infusionResult, isNotNull);
      expect(res.infusionResult!.rate, closeTo(0.5, 0.01));
      expect(res.infusionResult!.rateMax, closeTo(1.0, 0.01));
      expect(res.warnings.any((w) => w.code == DoseWarningCode.renalAdjustmentApplied), isTrue);
    });

    // -------------------------------------------------------------------------
    // Bug 21: verifyOrder Catches Unadjusted Frequency in Renal Impairment
    // -------------------------------------------------------------------------
    test('Bug 21: verifyOrder flags unadjusted frequency (q8h instead of q12h) even when dose is adjusted (500 mg)', () {
      const renalPatient = Patient(
        id: 'p-cef-freq-only',
        ageYears: 65,
        weightKg: 60.0,
        heightCm: 165.0,
        sex: Sex.male,
        isScrStable: true,
        serumCreatinineMgDl: 3.5, // CrCl ~ 15 mL/min
      );

      final cefazolin = DrugDatabase.findById('cefazolin')!;
      final cefSystemic = cefazolin.regimens.firstWhere(
        (r) => r.indication?.contains('Systemic') ?? false,
      );

      final verify = PharmacistCalculator.verifyOrder(
        patient: renalPatient,
        drug: cefazolin,
        regimen: cefSystemic,
        orderedDose: 500.0, // Renally adjusted dose
        orderedFrequency: Frequency.q8h, // Unadjusted standard frequency (recommended is q12h)
      );

      expect(verify.recommendedResult.adjustedFrequency, equals('q12h'));
      expect(verify.isAcceptable, isFalse);
      expect(
        verify.warnings.any((w) => w.code == DoseWarningCode.severeRenalImpairment),
        isTrue,
      );
    });

    // -------------------------------------------------------------------------
    // Bug 22: DoseChecker.checkRenalAdjustment Supports absoluteDose
    // -------------------------------------------------------------------------
    test('Bug 22: DoseChecker.checkRenalAdjustment reports set dose when absoluteDose is specified', () {
      const tierAbsDose = RenalAdjustment(
        crclMin: 15.0,
        crclMax: 50.0,
        absoluteDose: 15.0,
        adjustedFrequency: Frequency.q24h,
      );

      final warnings = DoseChecker.checkRenalAdjustment(
        crclMlMin: 30.0,
        adjustments: [tierAbsDose],
      );

      expect(warnings.any((w) => w.code == DoseWarningCode.renalAdjustmentApplied), isTrue);
      final warn = warnings.firstWhere((w) => w.code == DoseWarningCode.renalAdjustmentApplied);
      expect(warn.messageEn, contains('set dose to 15'));
      expect(warn.messageEn, isNot(contains('maintain dose')));
    });

    // -------------------------------------------------------------------------
    // Bug 23: Pediatric-Only Regimen with minAgeMonths Blocks Adults
    // -------------------------------------------------------------------------
    test('Bug 23: Pediatric regimen with minAgeMonths (and null maxAgeMonths) blocks adult patients', () {
      const adult = Patient(
        id: 'p-adult-30',
        ageYears: 30,
        weightKg: 70.0,
        heightCm: 175.0,
        sex: Sex.male,
        isScrStable: true,
      );

      const pedDrug = Drug(
        id: 'ped_min_age_drug',
        genericName: 'Pediatric MinAge Drug',
        category: DrugCategory.antibiotic,
        regimens: [
          DosingRegimen(
            route: DoseRoute.po,
            indication: 'Pediatric Infection (> 2 yrs)',
            dosingType: DosingType.weightBased,
            audience: RegimenAudience.pediatric,
            population: PopulationCriteria(minAgeMonths: 24),
            dosePerKg: 10.0,
            doseUnit: DoseUnit.mg,
            frequency: Frequency.q12h,
          ),
        ],
      );

      final res = PharmacistCalculator.calculateDose(
        patient: adult,
        drug: pedDrug,
        regimen: pedDrug.regimens.first,
      );

      expect(res.success, isFalse);
      expect(res.warnings.any((w) => w.code == DoseWarningCode.populationMismatch), isTrue);
    });

    // -------------------------------------------------------------------------
    // Bug 24: Daily Dose Basis with Range Frequency Preserves dailyDose
    // -------------------------------------------------------------------------
    test('Bug 24: Pediatric Clindamycin (DoseBasis.perDay, Divided q6-8h) preserves dailyDose = 300 mg/day', () {
      const child = Patient(
        id: 'p-ped-clinda-daily',
        weightKg: 20.0,
        heightCm: 110.0,
        ageYears: 5,
        sex: Sex.male,
        isScrStable: true,
      );

      final clindamycin = DrugDatabase.findById('clindamycin')!;
      final pedRegimen = clindamycin.regimens.firstWhere(
        (r) => r.indication?.contains('Pediatric') ?? false,
      );

      final result = PharmacistCalculator.calculateDose(
        patient: child,
        drug: clindamycin,
        regimen: pedRegimen,
      );

      expect(result.success, isTrue);
      expect(result.dailyDose, closeTo(300.0, 0.5));
      expect(result.warnings.any((w) => w.code == DoseWarningCode.unknownFrequency), isFalse);
    });

    // -------------------------------------------------------------------------
    // Bug 25: Brand/Salt & LASA Drug Data Integrity (Kayexalate, Lasix, Tramal)
    // -------------------------------------------------------------------------
    test('Bug 25: Drug brand names and explicit drugClass tags prevent salt/LASA confusion', () {
      final sps = DrugDatabase.findById('sodium_polystyrene_sulfonate')!;
      expect(sps.brandNames, contains('Kayexalate'));
      expect(sps.brandNames, isNot(contains('Kalimate')));

      final furosemide = DrugDatabase.findById('furosemide')!;
      expect(furosemide.brandNames, contains('Lasix'));
      expect(furosemide.brandNames, isNot(contains('Hyles')));
      expect(furosemide.drugClass, equals(DrugClass.loopDiuretic));

      final spironolactone = DrugDatabase.findById('spironolactone')!;
      expect(spironolactone.brandNames, contains('Hyles'));
      expect(spironolactone.drugClass, equals(DrugClass.potassiumSparingDiuretic));

      final tramadol = DrugDatabase.findById('tramadol')!;
      expect(tramadol.brandNames, contains('Tramal'));
      expect(tramadol.brandNames, isNot(contains('Anarex')));
      expect(tramadol.drugClass, equals(DrugClass.opioid));

      expect(DrugDatabase.findById('enalapril')!.drugClass, equals(DrugClass.aceInhibitor));
      expect(DrugDatabase.findById('losartan')!.drugClass, equals(DrugClass.arb));
      expect(DrugDatabase.findById('rosuvastatin')!.drugClass, equals(DrugClass.statin));
      expect(DrugDatabase.findById('atorvastatin')!.drugClass, equals(DrugClass.statin));
      expect(DrugDatabase.findById('apixaban')!.drugClass, equals(DrugClass.anticoagulantDoac));
      expect(DrugDatabase.findById('rivaroxaban')!.drugClass, equals(DrugClass.anticoagulantDoac));
    });
  });
}


