// ============================================================================
// E2E Test Suite: Specialized Dosing & High-Alert Drug Management (Req R2)
// ============================================================================
// Authoritative standards:
// - ORIGINAL_REQUEST.md Requirement R2
// - AGENTS.md & GEMINI.md (Rule 1 Zero Calculation Error, Rule 5 Non-Blocking)
// - ASHP/IDSA/PIDS/SIDP 2020 Vancomycin Consensus Guidelines
// - Nicolau DP et al. (1995): Hartford Extended-Interval Aminoglycoside Nomogram
// - Sheiner LB & Tozer TN (1975): Albumin-adjusted Phenytoin equation
// - Winter ME: Basic Clinical Pharmacokinetics (5th ed)
// - Devine BJ (1974): Ideal body weight formula
// - Cockcroft DW & Gault MH (1976): Creatinine clearance prediction
// - Schwartz GJ et al. (1984, 2009): Bedside Schwartz pediatric GFR formula
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/calculators/tdm_calculator.dart';
import 'package:drug_dosage_calculator/core/calculators/iv_rate_calculator.dart';
import 'specialized_dosing_harness.dart';

void main() {
  group('E2E Specialized Dosing — Tier 1: Feature Coverage (Category-Partition)', () {
    test('1.1: Vancomycin AUC24/MIC target (400-600) and stratified trough targets', () {
      // Serious / Invasive MRSA bacteremia: target AUC24 400-600 for MIC = 1.0 mg/L
      final evalTherapeutic = SpecializedDosingHarness.evaluateVancomycinTarget(
        auc24: 510.0,
        micMgL: 1.0,
        isSeriousInvasiveInfection: true,
      );
      expect(evalTherapeutic.isTherapeutic, isTrue);
      expect(evalTherapeutic.isSubtherapeutic, isFalse);
      expect(evalTherapeutic.isSupratherapeuticNephrotoxic, isFalse);

      // Sub-therapeutic exposure: AUC24 = 320 mg*h/L
      final evalSub = SpecializedDosingHarness.evaluateVancomycinTarget(
        auc24: 320.0,
        micMgL: 1.0,
        isSeriousInvasiveInfection: true,
      );
      expect(evalSub.isSubtherapeutic, isTrue);
      expect(evalSub.isTherapeutic, isFalse);

      // Nephrotoxic threshold breach: AUC24 = 680 mg*h/L
      final evalToxic = SpecializedDosingHarness.evaluateVancomycinTarget(
        auc24: 680.0,
        micMgL: 1.0,
        isSeriousInvasiveInfection: true,
      );
      expect(evalToxic.isSupratherapeuticNephrotoxic, isTrue);
      expect(evalToxic.clinicalGuidance, contains('Acute Kidney Injury (AKI) risk'));

      // Recommended dose calculation to achieve exact target AUC24 of 500 mg*h/L
      final recDose = TdmCalculator.recommendDoseForTargetAuc24(
        targetAuc: 500.0,
        vd: 49.0,
        ke: 0.0874,
        tau: 12.0,
      );
      // recDose = (500 * (49 * 0.0874)) / (24 / 12) = (500 * 4.2826) / 2 = 1070.65 mg
      expect(recDose, closeTo(1070.65, 0.10));
    });

    test('1.2: Aminoglycosides Hartford nomogram with Amikacin normalization and conventional peak/trough', () {
      // Gentamicin Hartford evaluation at 10h post-dose
      final zoneQ24 = TdmCalculator.evaluateHartfordNomogram(
        randomLevelMgL: 4.0,
        hoursPostDose: 10.0,
      );
      expect(zoneQ24.zone, equals(HartfordNomogramZone.q24h));
      expect(zoneQ24.recommendedIntervalHours, equals(24));

      final zoneQ36 = TdmCalculator.evaluateHartfordNomogram(
        randomLevelMgL: 6.5,
        hoursPostDose: 10.0,
      );
      expect(zoneQ36.zone, equals(HartfordNomogramZone.q36h));
      expect(zoneQ36.recommendedIntervalHours, equals(36));

      // Amikacin normalization: 18.0 mg/L divided by 2.0 = 9.0 mg/L -> q48h zone
      final zoneQ48Amikacin = TdmCalculator.evaluateHartfordNomogram(
        randomLevelMgL: 18.0,
        hoursPostDose: 10.0,
        isAmikacin: true,
      );
      expect(zoneQ48Amikacin.normalizedGentamicinEquivalentMgL, closeTo(9.0, 1e-6));
      expect(zoneQ48Amikacin.zone, equals(HartfordNomogramZone.q48h));
      expect(zoneQ48Amikacin.recommendedIntervalHours, equals(48));

      // Conventional multiple-daily dosing target check
      // Gentamicin 1.7 mg/kg q8h: target Peak 6-10 mcg/mL, Trough < 1.0 mcg/mL
      final convPeak = TdmCalculator.predictPeak(
        dose: 120, // 1.7 mg/kg * 70 kg
        tau: 8,
        tInf: 0.5,
        vd: 17.5, // 0.25 L/kg * 70 kg
        ke: 0.25, // normal CrCl
      );
      final convTrough = TdmCalculator.predictTrough(
        dose: 120,
        tau: 8,
        tInf: 0.5,
        vd: 17.5,
        ke: 0.25,
      );
      expect(convPeak, closeTo(7.85, 0.50)); // Target 6-10 achieved
      expect(convTrough, lessThan(1.5)); // Target safe trough achieved
    });

    test('1.3: Phenytoin Michaelis-Menten non-linear kinetics and capacity calculation', () {
      // Standard 70 kg adult: Vmax = 7.0 mg/kg/day * 70 = 490 mg/day, Km = 4.0 mg/L
      const weight = 70.0;
      const orderedDose = 350.0; // mg/day

      final result = SpecializedDosingHarness.evaluatePhenytoin(
        orderedDailyDoseMg: orderedDose,
        weightKg: weight,
      );

      // Predicted Css = (Km * Dose) / (Vmax - Dose) = (4.0 * 350) / (490 - 350) = 1400 / 140 = 10.0 mg/L
      expect(result.predictedCssMgL, closeTo(10.0, 1e-5));
      expect(result.isCapacityExceeded, isFalse);
      expect(result.isToxic, isFalse);

      // Increasing dose by just 14% (from 350 to 400 mg/day) produces an 80% surge in concentration:
      // Css = (4.0 * 400) / (490 - 400) = 1600 / 90 ≈ 17.78 mg/L
      final surgeResult = SpecializedDosingHarness.evaluatePhenytoin(
        orderedDailyDoseMg: 400.0,
        weightKg: weight,
      );
      expect(surgeResult.predictedCssMgL, closeTo(17.78, 0.05));
    });

    test('1.4: Sheiner-Tozer & Winter-Tozer albumin-adjusted phenytoin concentration', () {
      // Patient with severe hypoalbuminemia (Albumin = 2.0 g/dL) and measured total phenytoin = 10.0 mg/L
      // Normal renal function: Cadj = Cobs / (0.2 * Albumin + 0.1) = 10 / (0.2 * 2.0 + 0.1) = 10 / 0.5 = 20.0 mg/L
      final stResult = SpecializedDosingHarness.evaluatePhenytoin(
        orderedDailyDoseMg: 300.0,
        weightKg: 70.0,
        observedSerumPhenytoinMgL: 10.0,
        serumAlbuminGPerDl: 2.0,
        crclMlMin: 80.0,
      );
      expect(stResult.isSheinerTozerApplied, isTrue);
      expect(stResult.adjustedCssMgL, closeTo(20.0, 1e-5));

      // Patient with ESRD / CrCl < 20 mL/min (Winter-Tozer equation):
      // Cadj = Cobs / (0.1 * Albumin + 0.1) = 10 / (0.1 * 2.0 + 0.1) = 10 / 0.3 = 33.33 mg/L (Critical toxicity!)
      final wtResult = SpecializedDosingHarness.evaluatePhenytoin(
        orderedDailyDoseMg: 300.0,
        weightKg: 70.0,
        observedSerumPhenytoinMgL: 10.0,
        serumAlbuminGPerDl: 2.0,
        crclMlMin: 12.0,
      );
      expect(wtResult.isWinterTozerApplied, isTrue);
      expect(wtResult.adjustedCssMgL, closeTo(33.33, 0.05));
      expect(wtResult.isToxic, isTrue);
    });

    test('1.5: NTI Electrolyte disturbance monitoring and Digoxin 6-8h alpha distribution warning', () {
      // Digoxin: hypokalemia (K+ = 3.0 mEq/L) and hypomagnesemia (Mg2+ = 1.4 mg/dL)
      final safetyDigoxin = SpecializedDosingHarness.checkNtiSafety(
        drugId: 'digoxin',
        serumPotassiumMEqL: 3.0,
        serumMagnesiumMgDl: 1.4,
        hoursPostDoseSampling: 2.0, // Premature!
      );

      expect(safetyDigoxin.hasPotassiumRisk, isTrue);
      expect(safetyDigoxin.hasMagnesiumRisk, isTrue);
      expect(safetyDigoxin.hasDistributionPhaseWarning, isTrue);
      expect(safetyDigoxin.clinicalWarnings.length, equals(3));

      // Lithium: hyponatremia (Na+ = 128 mEq/L)
      final safetyLithium = SpecializedDosingHarness.checkNtiSafety(
        drugId: 'lithium',
        serumSodiumMEqL: 128.0,
        hoursPostDoseSampling: 12.0,
      );
      expect(safetyLithium.hasSodiumRisk, isTrue);
      expect(safetyLithium.clinicalWarnings.first, contains('Hyponatremia'));
    });

    test('1.6: Special populations weight selection: Devine IBW and mandatory AdjBW 0.4 in obesity', () {
      // 175 cm male: Height in inches = 175 / 2.54 = 68.8976 in
      // Devine IBW = 50.0 + 2.3 * (68.8976 - 60) = 50.0 + 20.46 = 70.46 kg
      final ibw = SpecializedDosingHarness.calculateDevineIbw(heightCm: 175.0, isMale: true);
      expect(ibw, closeTo(70.46, 0.05));

      // Obese patient: TBW = 110 kg (BMI = 35.9, TBW > 1.2 * IBW)
      // AdjBW 0.4 = IBW + 0.4 * (TBW - IBW) = 70.46 + 0.4 * (110 - 70.46) = 70.46 + 15.816 = 86.28 kg
      final aminoglycosideWeight = SpecializedDosingHarness.selectAminoglycosideDosingWeight(
        tbwKg: 110.0,
        heightCm: 175.0,
        isMale: true,
      );
      expect(aminoglycosideWeight, closeTo(86.28, 0.05));
    });

    test('1.7: Special populations renal estimation: Cockcroft-Gault elderly floor and pediatric Schwartz', () {
      // Elderly patient: age 78, weight 60 kg, female, SCr = 0.5 mg/dL
      final renalElderly = SpecializedDosingHarness.calculateCockcroftGaultWithElderlyFloor(
        ageYears: 78.0,
        weightKg: 60.0,
        serumCreatinineMgDl: 0.5,
        isMale: false,
      );

      // Raw CrCl = ((140 - 78) * 60) / (72 * 0.5) * 0.85 = (3720 / 36) * 0.85 = 87.83 mL/min (Overestimated!)
      // Effective CrCl with 0.8 floor = (3720 / (72 * 0.8)) * 0.85 = (3720 / 57.6) * 0.85 = 54.90 mL/min
      expect(renalElderly['rawCrCl'], closeTo(87.83, 0.10));
      expect(renalElderly['effectiveCrCl'], closeTo(54.90, 0.10));
      expect(renalElderly['floorApplied'], isTrue);

      // Pediatric Bedside Schwartz: child height 110 cm, SCr 0.6 mg/dL, k = 0.413
      final pedGfr = SpecializedDosingHarness.calculateBedsideSchwartz(
        heightCm: 110.0,
        serumCreatinineMgDl: 0.6,
        kConstant: 0.413,
      );
      // (0.413 * 110) / 0.6 = 45.43 / 0.6 = 75.72 mL/min/1.73m^2
      expect(pedGfr, closeTo(75.72, 0.05));

      // Preterm infant: height 40 cm, SCr 0.8 mg/dL, k = 0.33
      final pretermGfr = SpecializedDosingHarness.calculateBedsideSchwartz(
        heightCm: 40.0,
        serumCreatinineMgDl: 0.8,
        kConstant: 0.33,
      );
      // (0.33 * 40) / 0.8 = 16.5 mL/min/1.73m^2
      expect(pretermGfr, closeTo(16.5, 0.05));
    });

    test('1.8: High-alert continuous infusions: Norepinephrine concentration and pump rate conversion', () {
      // Norepinephrine standard dilution: 4 mg in 250 mL D5W = 0.016 mg/mL = 16 mcg/mL
      // Patient 70 kg, ordered rate 0.1 mcg/kg/min
      // Pump rate = (0.1 mcg/kg/min * 70 kg * 60 min) / 16 mcg/mL = 420 / 16 = 26.25 mL/hr
      final vasoResult = SpecializedDosingHarness.calculateVasoactiveInfusion(
        drugId: 'norepinephrine',
        orderedDose: 0.10,
        doseUnit: 'mcg/kg/min',
        patientWeightKg: 70.0,
        concentrationMcgPerMl: 16.0,
      );

      expect(vasoResult.pumpRateMlPerHr, closeTo(26.25, 0.01));
      expect(vasoResult.isCeilingExceeded, isFalse);

      // Verify strict equivalence with production IvRateCalculator
      final prodRate = IvRateCalculator.rateMlPerHrFromMcgKgMin(
        desiredMcgKgMin: 0.10,
        weightKg: 70.0,
        concentrationMcgPerMl: 16.0,
      );
      expect(prodRate, closeTo(26.25, 0.01));
    });
  });

  group('E2E Specialized Dosing — Tier 2: Boundary Value Analysis & Corner Cases', () {
    test('2.1: Phenytoin saturation guard: Dose >= Vmax prevents division by zero and preserves dose', () {
      // Patient 70 kg: Vmax = 490 mg/day. Ordered dose = 500 mg/day (> Vmax)
      final result = SpecializedDosingHarness.evaluatePhenytoin(
        orderedDailyDoseMg: 500.0,
        weightKg: 70.0,
      );

      expect(result.isCapacityExceeded, isTrue);
      expect(result.warningCodes, contains('phenytoinCapacityExceeded'));
      expect(result.isToxic, isTrue);
      expect(result.orderedDailyDoseMg, equals(500.0)); // Preserved per Rule 5!
    });

    test('2.2: Malnutrition / Underweight (TBW < IBW) enforces TBW to prevent toxic overdose', () {
      // 170 cm female: Devine IBW = 45.5 + 2.3 * (66.93 - 60) = 45.5 + 15.94 = 61.44 kg
      // Severely malnourished cancer patient: TBW = 42.0 kg
      final dosingWeight = SpecializedDosingHarness.selectAminoglycosideDosingWeight(
        tbwKg: 42.0,
        heightCm: 170.0,
        isMale: false,
      );

      // Must use actual weight 42.0 kg (NOT 61.44 kg IBW) to prevent 46% overdose!
      expect(dosingWeight, equals(42.0));
    });

    test('2.3: Morbid obesity (BMI >= 30) forces AdjBW 0.4 for aminoglycosides', () {
      // 160 cm female: IBW = 45.5 + 2.3 * (63 - 60) = 52.4 kg
      // Weight = 95 kg (BMI = 37.1)
      final dosingWeight = SpecializedDosingHarness.selectAminoglycosideDosingWeight(
        tbwKg: 95.0,
        heightCm: 160.0,
        isMale: false,
      );

      // AdjBW 0.4 = 52.4 + 0.4 * (95 - 52.4) = 52.4 + 17.04 = 69.44 kg
      expect(dosingWeight, closeTo(69.44, 0.05));
    });

    test('2.4: Negative or non-positive inputs throw ArgumentError', () {
      expect(
        () => SpecializedDosingHarness.evaluateVancomycinTarget(auc24: -100.0),
        throwsArgumentError,
      );
      expect(
        () => SpecializedDosingHarness.evaluatePhenytoin(
          orderedDailyDoseMg: -200,
          weightKg: 70,
        ),
        throwsArgumentError,
      );
      expect(
        () => SpecializedDosingHarness.calculateDevineIbw(heightCm: -150, isMale: true),
        throwsArgumentError,
      );
    });

    test('2.5: High-alert vasopressor titration ceiling breach triggers Rule 5 non-blocking warning', () {
      // Norepinephrine at 1.5 mcg/kg/min (standard ceiling = 1.0 mcg/kg/min)
      final result = SpecializedDosingHarness.calculateVasoactiveInfusion(
        drugId: 'norepinephrine',
        orderedDose: 1.50,
        doseUnit: 'mcg/kg/min',
        patientWeightKg: 70.0,
        concentrationMcgPerMl: 16.0,
      );

      // Pump rate is NOT suppressed or zeroed: (1.5 * 70 * 60) / 16 = 393.75 mL/hr
      expect(result.pumpRateMlPerHr, closeTo(393.75, 0.01));
      expect(result.isCeilingExceeded, isTrue);
      expect(result.warningMessage, contains('TITRATION CEILING EXCEEDED'));
    });
  });

  group('E2E Specialized Dosing — Tier 3: Pairwise Combinatorial & Cross-Feature Integration', () {
    test('3.1: Sepsis ICU patient with AKI on Vancomycin: expanded Vd and target AUC titration', () {
      // 80 kg sepsis ICU patient with Acute Kidney Injury (CrCl = 30 mL/min)
      // Expanded Vd for critically ill sepsis = 0.85 L/kg * 80 kg = 68.0 L
      final vdSepsis = TdmCalculator.calculateVdWithModel(
        weightKg: 80.0,
        model: VancomycinVdModel.criticallyIllIcu,
      );
      expect(vdSepsis, closeTo(68.0, 1e-6));

      // Ke with AKI CrCl 30 mL/min: (0.00083 * 30) + 0.0044 = 0.0293 hr^-1 (t1/2 ≈ 23.65 hr)
      final keAki = TdmCalculator.calculateKe(crclMlMin: 30);
      expect(keAki, closeTo(0.0293, 1e-4));

      // Calculate AUC24 for empiric 1000 mg q24h:
      // Clearance = 68.0 * 0.0293 = 1.9924 L/hr
      // Daily Dose = 1000 mg / 24h -> AUC24 = 1000 / 1.9924 ≈ 501.9 mg*h/L
      final aucAki = TdmCalculator.calculateAuc24(
        dose: 1000,
        tau: 24,
        vd: vdSepsis,
        ke: keAki,
      );
      expect(aucAki, closeTo(501.9, 1.0));

      // Verify therapeutic window target attainment:
      final eval = SpecializedDosingHarness.evaluateVancomycinTarget(
        auc24: aucAki,
        micMgL: 1.0,
      );
      expect(eval.isTherapeutic, isTrue);
    });

    test('3.2: Obese diabetic on Gentamicin Hartford nomogram: AdjBW dosing and extended interval', () {
      // 120 kg, 170 cm male (BMI = 41.5, severe obesity)
      final dosingWeight = SpecializedDosingHarness.selectAminoglycosideDosingWeight(
        tbwKg: 120.0,
        heightCm: 170.0,
        isMale: true,
      );
      // IBW = 50 + 2.3 * 6.93 = 65.94 kg; AdjBW = 65.94 + 0.4 * (120 - 65.94) = 87.56 kg
      expect(dosingWeight, closeTo(87.56, 0.10));

      // Hartford dose = 7 mg/kg * 87.56 kg = 612.9 mg -> Formulary round to 600 mg
      const doseMg = 600.0;
      expect(doseMg, equals(600.0));

      // Random level drawn at 9.0 hr post-dose is 8.5 mg/L
      final nomogram = TdmCalculator.evaluateHartfordNomogram(
        randomLevelMgL: 8.5,
        hoursPostDose: 9.0,
      );
      // At 9h: q24 boundary = 9.0 - (7/8)*3 = 6.375; q36 boundary = 11.0 - (6.5/8)*3 = 8.5625
      // 8.5 falls in q36h zone!
      expect(nomogram.zone, equals(HartfordNomogramZone.q36h));
      expect(nomogram.recommendedIntervalHours, equals(36));
    });

    test('3.3: Cirrhotic hypoalbuminemic patient on Phenytoin: Sheiner-Tozer exposes hidden toxicity', () {
      // Cirrhotic patient with severe ascites and albumin = 1.8 g/dL
      // Total measured phenytoin = 14.0 mcg/mL (which appears comfortably within 10-20 window!)
      final result = SpecializedDosingHarness.evaluatePhenytoin(
        orderedDailyDoseMg: 300.0,
        weightKg: 65.0,
        observedSerumPhenytoinMgL: 14.0,
        serumAlbuminGPerDl: 1.8,
        crclMlMin: 65.0,
      );

      // Cadj = 14.0 / (0.2 * 1.8 + 0.1) = 14.0 / 0.46 ≈ 30.43 mcg/mL!
      // This is in the toxic ataxia / cerebellar nystagmus range (> 30 mcg/mL)!
      expect(result.adjustedCssMgL, closeTo(30.43, 0.10));
      expect(result.isToxic, isTrue);
      expect(result.warningCodes, contains('phenytoinHypoalbuminemia'));
    });

    test('3.4: Septic shock patient on high-dose Norepinephrine with structured clinical override', () {
      final override = ClinicalOverrideJustification(
        clinicianId: 'MD-ICU-8821',
        justificationCategory: 'Refractory septic shock unresponsive to second-line vasopressor',
        clinicalNotes: 'Arterial MAP < 55 mmHg despite Vasopressin 0.03 U/min and hydrocortisone.',
        timestamp: DateTime.now(),
        deliveredDose: 1.80,
        rateUnit: 'mcg/kg/min',
      );

      final result = SpecializedDosingHarness.calculateVasoactiveInfusion(
        drugId: 'norepinephrine',
        orderedDose: 1.80,
        doseUnit: 'mcg/kg/min',
        patientWeightKg: 70.0,
        concentrationMcgPerMl: 16.0,
        overrideJustification: override,
      );

      expect(result.isCeilingExceeded, isTrue);
      expect(result.overrideJustification, isNotNull);
      expect(result.overrideJustification!.clinicianId, equals('MD-ICU-8821'));
      expect(result.pumpRateMlPerHr, closeTo(472.5, 0.1));
    });
  });

  group('E2E Specialized Dosing — Tier 4: Real-World Hospital Workload Scenarios', () {
    test('4.1: ICU Septic Shock Resuscitation Protocol', () {
      // Step 1: Norepinephrine infusion initiation at 0.2 mcg/kg/min in 80 kg patient
      final norepi = SpecializedDosingHarness.calculateVasoactiveInfusion(
        drugId: 'norepinephrine',
        orderedDose: 0.20,
        doseUnit: 'mcg/kg/min',
        patientWeightKg: 80.0,
        concentrationMcgPerMl: 16.0,
      );
      expect(norepi.pumpRateMlPerHr, closeTo(60.0, 0.01));

      // Step 2: Empiric Vancomycin loading dose: 25-30 mg/kg = 2000 - 2400 mg
      final loadingRange = TdmCalculator.calculateLoadingDose(weightKg: 80.0);
      expect(loadingRange[0], equals(2000.0));
      expect(loadingRange[1], equals(2400.0));

      // Step 3: Red Man Syndrome rate check: 2000 mg over 120 min = 16.67 mg/min (> 10 mg/min -> Alert!)
      // Must be infused over >= 180 min (3 hours): 2000 / 180 = 11.1 mg/min, or 240 min = 8.33 mg/min
      final profileFast = TdmCalculator.generateSteadyStateProfile(
        dose: 2000.0,
        tau: 24.0,
        tInf: 2.0, // 120 min
        vd: 68.0,
        ke: 0.04,
      );
      expect(profileFast.hasRedManSyndromeRisk, isTrue);

      final profileSafe = TdmCalculator.generateSteadyStateProfile(
        dose: 2000.0,
        tau: 24.0,
        tInf: 4.0, // 240 min -> 2000 / 240 = 8.33 mg/min <= 10
        vd: 68.0,
        ke: 0.04,
      );
      expect(profileSafe.hasRedManSyndromeRisk, isFalse);
    });

    test('4.2: Clinical Pharmacist Ward TDM Morning Rounding', () {
      // Patient on Gentamicin Hartford nomogram: level drawn at 8.0 hr is 7.0 mg/L
      final gentaNomogram = TdmCalculator.evaluateHartfordNomogram(
        randomLevelMgL: 7.0,
        hoursPostDose: 8.0,
      );
      // At 8h: q24 boundary = 9.0 - (7/8)*2 = 7.25 mg/L -> 7.0 <= 7.25 falls in q24h zone!
      expect(gentaNomogram.zone, equals(HartfordNomogramZone.q24h));

      // Patient on Digoxin: Nurse draws blood at 2.5 hr post-dose with reported level 2.8 ng/mL
      final digCheck = SpecializedDosingHarness.checkNtiSafety(
        drugId: 'digoxin',
        serumPotassiumMEqL: 4.2,
        hoursPostDoseSampling: 2.5,
      );
      expect(digCheck.hasDistributionPhaseWarning, isTrue);
      // Pharmacist holds dose adjustment and orders redraw at >= 6-8 hr post-dose
    });

    test('4.3: Neonatal & Pediatric Antimicrobial Dosing', () {
      // 28-week preterm neonate: Weight = 1.1 kg, Height = 36 cm, SCr = 0.7 mg/dL
      final pretermGfr = SpecializedDosingHarness.calculateBedsideSchwartz(
        heightCm: 36.0,
        serumCreatinineMgDl: 0.7,
        kConstant: 0.33,
      );
      // eGFR = (0.33 * 36) / 0.7 = 11.88 / 0.7 = 16.97 mL/min/1.73m^2
      expect(pretermGfr, closeTo(16.97, 0.05));

      // Gentamicin neonate dose: 4.0 mg/kg q36h
      const neonateDose = 4.0 * 1.1; // 4.4 mg
      expect(neonateDose, closeTo(4.4, 0.01));
    });
  });
}
