import 'package:test/test.dart';
import 'package:drug_dosage_calculator/core/calculators/calculators.dart';
import 'package:drug_dosage_calculator/core/models/models.dart';

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
  });
}


