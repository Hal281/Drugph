// ============================================================================
// Specialized Dosing Calculator & High-Alert Infusion Unit Test Suite (M13)
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
import 'package:drug_dosage_calculator/core/models/specialized_dosing_models.dart';
import 'package:drug_dosage_calculator/core/calculators/specialized_dosing_calculator.dart';

void main() {
  group('1. Vancomycin AUC24/MIC Target & Kinetic Engine', () {
    test('1.1: Serious invasive MRSA bacteremia target (400-600) evaluation', () {
      // Therapeutic target attainment
      final therapeutic = SpecializedDosingCalculator.evaluateVancomycinAuc(
        auc24: 500.0,
        micMgL: 1.0,
        severity: InfectionSeverity.severeInvasive,
      );
      expect(therapeutic.isTherapeutic, isTrue);
      expect(therapeutic.isSubtherapeutic, isFalse);
      expect(therapeutic.isSupratherapeuticNephrotoxic, isFalse);
      expect(therapeutic.aucToMicRatio, equals(500.0));
      expect(therapeutic.troughTargetMin, equals(15.0));
      expect(therapeutic.troughTargetMax, equals(20.0));
      expect(therapeutic.clinicalGuidance, contains('within target therapeutic window'));

      // Sub-therapeutic exposure
      final sub = SpecializedDosingCalculator.evaluateVancomycinAuc(
        auc24: 350.0,
        micMgL: 1.0,
        severity: InfectionSeverity.severeInvasive,
      );
      expect(sub.isSubtherapeutic, isTrue);
      expect(sub.isTherapeutic, isFalse);
      expect(sub.clinicalGuidance, contains('risk of clinical failure and MRSA resistance'));

      // Supratherapeutic / nephrotoxic threshold breach
      final toxic = SpecializedDosingCalculator.evaluateVancomycinAuc(
        auc24: 650.0,
        micMgL: 1.0,
        severity: InfectionSeverity.severeInvasive,
      );
      expect(toxic.isSupratherapeuticNephrotoxic, isTrue);
      expect(toxic.isTherapeutic, isFalse);
      expect(toxic.clinicalGuidance, contains('Acute Kidney Injury (AKI) risk'));
    });

    test('1.2: Mild-moderate uncomplicated infection target (300-450) evaluation', () {
      final mild = SpecializedDosingCalculator.evaluateVancomycinAuc(
        auc24: 380.0,
        micMgL: 1.0,
        severity: InfectionSeverity.mildModerate,
      );
      expect(mild.isTherapeutic, isTrue);
      expect(mild.troughTargetMin, equals(10.0));
      expect(mild.troughTargetMax, equals(15.0));
      expect(mild.targetMin, equals(300.0));
      expect(mild.targetMax, equals(450.0));

      final subMild = SpecializedDosingCalculator.evaluateVancomycinAuc(
        auc24: 280.0,
        micMgL: 1.0,
        severity: InfectionSeverity.mildModerate,
      );
      expect(subMild.isSubtherapeutic, isTrue);
      expect(subMild.isTherapeutic, isFalse);
    });

    test('1.3: Trough level checks trigger nephrotoxicity and sub-target warnings', () {
      final res = SpecializedDosingCalculator.evaluateVancomycinAuc(
        auc24: 480.0,
        micMgL: 1.0,
        troughMgL: 22.5,
      );
      expect(res.warnings.any((w) => w.contains('High trough concentration')), isTrue);
      expect(res.warnings.any((w) => w.contains('nephrotoxicity')), isTrue);

      final resSubTrough = SpecializedDosingCalculator.evaluateVancomycinAuc(
        auc24: 480.0,
        micMgL: 1.0,
        troughMgL: 11.0,
        severity: InfectionSeverity.severeInvasive,
      );
      expect(resSubTrough.warnings.any((w) => w.contains('Sub-target trough concentration')), isTrue);
    });

    test('1.4: 2-point Sawchuk-Zaske kinetic parameter estimation', () {
      // Dose 1000 mg q12h over 1.0h infusion.
      // C1 = 28.0 mg/L drawn 1.0h post-infusion.
      // C2 = 12.0 mg/L drawn 9.0h after C1 (trough at 11h).
      final sz = SpecializedDosingCalculator.calculateVancomycinSawchukZaske(
        c1MgL: 28.0,
        c2MgL: 12.0,
        deltaTHours: 9.0,
        t1PostInfHours: 1.0,
        doseMg: 1000.0,
        tauHours: 12.0,
        tInfHours: 1.0,
      );

      // ke = ln(28 / 12) / 9 = ln(2.3333) / 9 = 0.847298 / 9 ≈ 0.09414 hr^-1
      expect(sz['ke']!, closeTo(0.09414, 0.001));

      // True peak at end of infusion: C1 * exp(ke * 1.0) = 28 * exp(0.09414) ≈ 30.76 mg/L
      expect(sz['truePeak']!, closeTo(30.76, 0.10));

      // True trough at end of interval (tau - tInf = 11h): 30.76 * exp(-0.09414 * 11) ≈ 10.92 mg/L
      expect(sz['trueTrough']!, closeTo(10.92, 0.15));

      // Vd and Clearance
      expect(sz['vd']!, greaterThan(20.0));
      expect(sz['clearance']!, greaterThan(2.0));
      expect(sz['auc24']!, greaterThan(300.0));
    });

    test('1.5: Recommend maintenance dose for target AUC24', () {
      // Target AUC 500 mg*h/L, Vd 49.0 L, ke 0.0874 hr^-1, tau 12h
      final recDose = SpecializedDosingCalculator.recommendVancomycinDoseForTargetAuc(
        targetAuc: 500.0,
        vd: 49.0,
        ke: 0.0874,
        tauHours: 12.0,
      );
      // Daily Dose = 500 * (49 * 0.0874) = 500 * 4.2826 = 2141.3 mg/day
      // Dose q12h = 2141.3 / 2 = 1070.65 mg
      expect(recDose, closeTo(1070.65, 0.10));
    });

    test('1.6: Empiric loading dose calculation and ceiling cap adherence', () {
      // 70 kg adult: 25-30 mg/kg = 1750 - 2100 mg (under 3000 mg cap)
      final load70 = SpecializedDosingCalculator.calculateVancomycinLoadingDose(
        weightKg: 70.0,
        isSevereOrCriticallyIll: true,
      );
      expect(load70['recommendedMinDoseMg'], equals(1750.0));
      expect(load70['recommendedMaxDoseMg'], equals(2100.0));
      expect(load70['capApplied'], isFalse);

      // 120 kg obese patient: 25-30 mg/kg = 3000 - 3600 mg (> 3000 mg ceiling!)
      final load120 = SpecializedDosingCalculator.calculateVancomycinLoadingDose(
        weightKg: 120.0,
        isSevereOrCriticallyIll: true,
      );
      expect(load120['rawMaxDoseMg'], equals(3600.0));
      expect(load120['recommendedMaxDoseMg'], equals(3000.0));
      expect(load120['capApplied'], isTrue);
      expect(load120['warning'], contains('Loading dose capped at 3000 mg'));
    });

    test('1.7: Red Man Syndrome infusion rate threshold checks', () {
      // 1500 mg infused over 60 min -> 25 mg/min (> 10 mg/min -> alert!)
      final fastCheck = SpecializedDosingCalculator.checkRedManSyndromeRisk(
        doseMg: 1500.0,
        infusionDurationMinutes: 60.0,
      );
      expect(fastCheck['hasRedManSyndromeRisk'], isTrue);
      expect(fastCheck['rateMgPerMin'], equals(25.0));
      expect(fastCheck['minSafeDurationMinutes'], equals(150.0));

      // 1500 mg infused over 180 min -> 8.33 mg/min (<= 10 mg/min -> safe)
      final safeCheck = SpecializedDosingCalculator.checkRedManSyndromeRisk(
        doseMg: 1500.0,
        infusionDurationMinutes: 180.0,
      );
      expect(safeCheck['hasRedManSyndromeRisk'], isFalse);
      expect(safeCheck['rateMgPerMin'], closeTo(8.33, 0.05));
    });
  });

  group('2. Aminoglycosides Engine (Hartford Nomogram & Conventional Dosing)', () {
    test('2.1: Hartford nomogram intervals: q24h, q36h, q48h, and off-nomogram hold', () {
      // Level at 10h: q24 boundary = 9.0 - (7/8)*4 = 5.5 mg/L
      // Level = 4.0 mg/L -> q24h
      final res24 = SpecializedDosingCalculator.evaluateHartfordNomogram(
        randomLevelMgL: 4.0,
        hoursPostDose: 10.0,
      );
      expect(res24.interval, equals(HartfordInterval.q24h));
      expect(res24.recommendedIntervalHours, equals(24));
      expect(res24.isOffNomogram, isFalse);

      // Level at 10h: q36 boundary = 11.0 - (6.5/8)*4 = 7.75 mg/L
      // Level = 6.5 mg/L -> q36h
      final res36 = SpecializedDosingCalculator.evaluateHartfordNomogram(
        randomLevelMgL: 6.5,
        hoursPostDose: 10.0,
      );
      expect(res36.interval, equals(HartfordInterval.q36h));
      expect(res36.recommendedIntervalHours, equals(36));

      // Level at 10h: q48 boundary = 13.0 - (6/8)*4 = 10.0 mg/L
      // Level = 8.5 mg/L -> q48h
      final res48 = SpecializedDosingCalculator.evaluateHartfordNomogram(
        randomLevelMgL: 8.5,
        hoursPostDose: 10.0,
      );
      expect(res48.interval, equals(HartfordInterval.q48h));
      expect(res48.recommendedIntervalHours, equals(48));

      // Level at 10h: Level = 11.5 mg/L (> 10.0) -> off-nomogram hold
      final resHold = SpecializedDosingCalculator.evaluateHartfordNomogram(
        randomLevelMgL: 11.5,
        hoursPostDose: 10.0,
      );
      expect(resHold.interval, equals(HartfordInterval.offNomogramHold));
      expect(resHold.recommendedIntervalHours, isNull);
      expect(resHold.isOffNomogram, isTrue);
      expect(resHold.clinicalGuidance, contains('OFF-NOMOGRAM / TOXIC ACCUMULATION'));
    });

    test('2.2: Amikacin level normalization (division by 2.0) before plotting', () {
      // Amikacin level = 18.0 mg/L at 10h post-dose.
      // Normalized = 18.0 / 2.0 = 9.0 mg/L (falls between q36 [7.75] and q48 [10.0]) -> q48h!
      final amikacinRes = SpecializedDosingCalculator.evaluateHartfordNomogram(
        randomLevelMgL: 18.0,
        hoursPostDose: 10.0,
        isAmikacin: true,
      );
      expect(amikacinRes.normalizedLevelMgL, closeTo(9.0, 1e-6));
      expect(amikacinRes.interval, equals(HartfordInterval.q48h));
      expect(amikacinRes.recommendedIntervalHours, equals(48));
    });

    test('2.3: Sampling window violation (< 6.0h or > 14.0h) triggers advisory', () {
      final earlyRes = SpecializedDosingCalculator.evaluateHartfordNomogram(
        randomLevelMgL: 5.0,
        hoursPostDose: 4.5,
      );
      expect(earlyRes.isWindowViolation, isTrue);
      expect(earlyRes.interval, equals(HartfordInterval.offNomogramHold));
      expect(earlyRes.clinicalGuidance, contains('outside valid Hartford nomogram window'));

      final lateRes = SpecializedDosingCalculator.evaluateHartfordNomogram(
        randomLevelMgL: 3.0,
        hoursPostDose: 15.0,
      );
      expect(lateRes.isWindowViolation, isTrue);
    });

    test('2.4: Conventional multiple-daily Gentamicin peak, trough, and peak/MIC validation', () {
      // Gentamicin 120 mg q8h over 0.5h, Vd = 17.5 L, ke = 0.25 hr^-1
      final conv = SpecializedDosingCalculator.evaluateConventionalAminoglycoside(
        drug: NtiDrugType.gentamicin,
        doseMg: 120.0,
        tauHours: 8.0,
        tInfHours: 0.5,
        vd: 17.5,
        ke: 0.25,
        micMgL: 0.5,
      );

      expect(conv.peakMgL, closeTo(7.85, 0.50));
      expect(conv.isPeakTherapeutic, isTrue);
      expect(conv.troughMgL, lessThan(1.5));
      expect(conv.isTroughSafe, isTrue);
      expect(conv.isTroughToxic, isFalse);
      expect(conv.peakToMicRatio, greaterThan(10.0));
      expect(conv.isPeakToMicOptimal, isTrue);
    });

    test('2.5: Conventional Amikacin target peak/trough validation and toxicity detection', () {
      // Amikacin 500 mg q12h over 1.0h, low clearance ke = 0.05 hr^-1, Vd = 18.0 L
      final amkToxic = SpecializedDosingCalculator.evaluateConventionalAminoglycoside(
        drug: NtiDrugType.amikacin,
        doseMg: 500.0,
        tauHours: 12.0,
        tInfHours: 1.0,
        vd: 18.0,
        ke: 0.05,
      );

      // Elevated accumulation due to low ke
      expect(amkToxic.troughMgL, greaterThan(10.0));
      expect(amkToxic.isTroughToxic, isTrue);
      expect(amkToxic.warnings.any((w) => w.contains('acute tubular necrosis')), isTrue);
    });
  });

  group('3. Phenytoin Non-Linear Michaelis-Menten Kinetics', () {
    test('3.1: Michaelis-Menten steady-state prediction and non-linear concentration surge', () {
      // Adult 70 kg: Vmax = 490 mg/day, Km = 4.0 mg/L
      // Ordered dose = 350 mg/day -> predicted Css = (4 * 350) / (490 - 350) = 1400 / 140 = 10.0 mg/L
      final p1 = SpecializedDosingCalculator.evaluatePhenytoin(
        orderedDailyDoseMg: 350.0,
        weightKg: 70.0,
      );
      expect(p1.predictedCssMgL, closeTo(10.0, 1e-5));
      expect(p1.isTherapeutic, isTrue);
      expect(p1.isCapacityExceeded, isFalse);
      expect(p1.isToxic, isFalse);

      // 14% dose increase to 400 mg/day -> Css = (4 * 400) / (490 - 400) = 1600 / 90 ≈ 17.78 mg/L (78% surge!)
      final p2 = SpecializedDosingCalculator.evaluatePhenytoin(
        orderedDailyDoseMg: 400.0,
        weightKg: 70.0,
      );
      expect(p2.predictedCssMgL, closeTo(17.78, 0.05));
      expect(p2.isTherapeutic, isTrue);

      // Dose = 440 mg/day -> Css = (4 * 440) / (490 - 440) = 1760 / 50 = 35.2 mg/L (> 20 -> toxic!)
      final p3 = SpecializedDosingCalculator.evaluatePhenytoin(
        orderedDailyDoseMg: 440.0,
        weightKg: 70.0,
      );
      expect(p3.predictedCssMgL, closeTo(35.2, 0.10));
      expect(p3.isToxic, isTrue);
      expect(p3.toxicityTier, contains('Ataxia'));
      expect(p3.warningCodes, contains('phenytoinTargetExceeded'));
    });

    test('3.2: Saturation guard: Dose >= Vmax prevents division by zero and preserves dose (Rule 5)', () {
      // 70 kg patient: Vmax = 490 mg/day. Ordered dose = 500 mg/day (> Vmax)
      final saturated = SpecializedDosingCalculator.evaluatePhenytoin(
        orderedDailyDoseMg: 500.0,
        weightKg: 70.0,
      );
      expect(saturated.isCapacityExceeded, isTrue);
      expect(saturated.predictedCssMgL, isNull);
      expect(saturated.orderedDailyDoseMg, equals(500.0)); // Preserved per Rule 5!
      expect(saturated.isToxic, isTrue);
      expect(saturated.warningCodes, contains('phenytoinCapacityExceeded'));
      expect(saturated.clinicalGuidance, contains('CRITICAL SATURATION'));
    });

    test('3.3: Sheiner-Tozer albumin adjustment for normal renal function', () {
      // Albumin = 2.0 g/dL, measured phenytoin = 10.0 mg/L, CrCl = 80 mL/min
      // Cadj = 10.0 / (0.2 * 2.0 + 0.1) = 10.0 / 0.5 = 20.0 mg/L
      final st = SpecializedDosingCalculator.evaluatePhenytoin(
        orderedDailyDoseMg: 300.0,
        weightKg: 70.0,
        observedSerumPhenytoinMgL: 10.0,
        serumAlbuminGPerDl: 2.0,
        crclMlMin: 80.0,
      );
      expect(st.isSheinerTozerApplied, isTrue);
      expect(st.isWinterTozerApplied, isFalse);
      expect(st.adjustedCssMgL, closeTo(20.0, 1e-5));
      expect(st.warningCodes, contains('phenytoinHypoalbuminemia'));
    });

    test('3.4: Winter-Tozer albumin adjustment for severe renal failure / ESRD', () {
      // Albumin = 2.0 g/dL, measured phenytoin = 10.0 mg/L, CrCl = 12 mL/min (< 20)
      // Cadj = 10.0 / (0.1 * 2.0 + 0.1) = 10.0 / 0.3 = 33.33 mg/L (Critical toxicity!)
      final wt = SpecializedDosingCalculator.evaluatePhenytoin(
        orderedDailyDoseMg: 300.0,
        weightKg: 70.0,
        observedSerumPhenytoinMgL: 10.0,
        serumAlbuminGPerDl: 2.0,
        crclMlMin: 12.0,
      );
      expect(wt.isWinterTozerApplied, isTrue);
      expect(wt.adjustedCssMgL, closeTo(33.33, 0.05));
      expect(wt.isToxic, isTrue);
      expect(wt.warningCodes, contains('phenytoinRenalImpairment'));
    });

    test('3.5: IV infusion rate limit check: <= 50 mg/min adult, <= 25 mg/min cardiac/elderly', () {
      // Rate = 60 mg/min adult -> breach!
      final adultFast = SpecializedDosingCalculator.evaluatePhenytoin(
        orderedDailyDoseMg: 300.0,
        weightKg: 70.0,
        ivInfusionRateMgPerMin: 60.0,
      );
      expect(adultFast.hasIvRateRisk, isTrue);
      expect(adultFast.warningCodes, contains('phenytoinIvRateExceeded'));

      // Rate = 40 mg/min in cardiac patient -> breach of 25 mg/min limit!
      final cardiacFast = SpecializedDosingCalculator.evaluatePhenytoin(
        orderedDailyDoseMg: 300.0,
        weightKg: 70.0,
        ivInfusionRateMgPerMin: 40.0,
        isElderlyOrCardiac: true,
      );
      expect(cardiacFast.hasIvRateRisk, isTrue);

      // Rate = 20 mg/min in cardiac patient -> safe
      final safeRate = SpecializedDosingCalculator.evaluatePhenytoin(
        orderedDailyDoseMg: 300.0,
        weightKg: 70.0,
        ivInfusionRateMgPerMin: 20.0,
        isElderlyOrCardiac: true,
      );
      expect(safeRate.hasIvRateRisk, isFalse);
    });

    test('3.6: Dose calculation for desired target Css', () {
      // Target Css = 15 mg/L, Weight 70 kg (Vmax = 490 mg/day, Km = 4.0 mg/L)
      // Dose = (490 * 15) / (4 + 15) = 7350 / 19 ≈ 386.84 mg/day
      final dose = SpecializedDosingCalculator.calculatePhenytoinDoseForTargetCss(
        targetCssMgL: 15.0,
        weightKg: 70.0,
      );
      expect(dose, closeTo(386.84, 0.05));
    });
  });

  group('4. Digoxin, Lithium, Theophylline Safety & Timing Guards', () {
    test('4.1: Digoxin electrolyte disturbance alerts: K+ < 3.5, Mg2+ < 1.7, Ca2+ > 10.5', () {
      final res = SpecializedDosingCalculator.checkNtiSafety(
        drug: NtiDrugType.digoxin,
        serumPotassiumMEqL: 3.1,
        serumMagnesiumMgDl: 1.5,
        serumCalciumMgDl: 11.2,
      );
      expect(res.hasPotassiumRisk, isTrue);
      expect(res.hasMagnesiumRisk, isTrue);
      expect(res.hasCalciumRisk, isTrue);
      expect(res.isSafe, isFalse);
      expect(res.clinicalWarnings.length, equals(3));
    });

    test('4.2: Digoxin alpha distribution phase sampling warning (< 6.0h)', () {
      final premature = SpecializedDosingCalculator.checkNtiSafety(
        drug: 'digoxin',
        hoursPostDoseSampling: 3.5,
      );
      expect(premature.hasDistributionPhaseWarning, isTrue);
      expect(premature.clinicalWarnings.any((w) => w.contains('Alpha distribution phase incomplete')), isTrue);

      final mature = SpecializedDosingCalculator.checkNtiSafety(
        drug: 'digoxin',
        hoursPostDoseSampling: 7.0,
      );
      expect(mature.hasDistributionPhaseWarning, isFalse);
    });

    test('4.3: Lithium hyponatremia alert, 12h trough timing, and DDI warning', () {
      final lithium = SpecializedDosingCalculator.checkNtiSafety(
        drug: NtiDrugType.lithium,
        serumSodiumMEqL: 130.0,
        hoursPostDoseSampling: 8.0,
        hasNsaidOrAceiOrArbOrThiazide: true,
      );
      expect(lithium.hasSodiumRisk, isTrue);
      expect(lithium.clinicalWarnings.any((w) => w.contains('Hyponatremia')), isTrue);
      expect(lithium.clinicalWarnings.any((w) => w.contains('exactly 12 hours post-dose')), isTrue);
      expect(lithium.clinicalWarnings.any((w) => w.contains('DDI Alert')), isTrue);
    });

    test('4.4: Theophylline steady-state timing check (< 48h alert)', () {
      final theo = SpecializedDosingCalculator.checkNtiSafety(
        drug: 'theophylline',
        hoursOnMaintenanceTherapy: 24.0,
      );
      expect(theo.clinicalWarnings.any((w) => w.contains('48-72 hours')), isTrue);
    });
  });

  group('5. Special Populations Dosing: Weight Selection & Renal Estimation', () {
    test('5.1: Devine IBW calculation in males and females', () {
      // 175 cm male: 50.0 + 2.3 * (68.8976 - 60) = 70.46 kg
      final ibwMale = SpecializedDosingCalculator.calculateDevineIbw(
        heightCm: 175.0,
        isMale: true,
      );
      expect(ibwMale, closeTo(70.46, 0.05));

      // 165 cm female: 45.5 + 2.3 * (64.9606 - 60) = 45.5 + 11.41 = 56.91 kg
      final ibwFemale = SpecializedDosingCalculator.calculateDevineIbw(
        heightCm: 165.0,
        isMale: false,
      );
      expect(ibwFemale, closeTo(56.91, 0.05));
    });

    test('5.2: Underweight patient (TBW < IBW) enforces TBW', () {
      // 170 cm female (IBW = 61.44 kg), cancer patient TBW = 42.0 kg
      final res = SpecializedDosingCalculator.selectWeightForSpecialPopulations(
        tbwKg: 42.0,
        heightCm: 170.0,
        isMale: false,
        drugType: NtiDrugType.gentamicin,
      );
      expect(res.isUnderweight, isTrue);
      expect(res.selectedWeightKg, equals(42.0));
      expect(res.rationale, contains('Underweight (TBW < IBW): Actual Body Weight enforced'));
    });

    test('5.3: Obese patient enforces mandatory AdjBW 0.4 for aminoglycosides', () {
      // 175 cm male (IBW = 70.46 kg), TBW = 110 kg (BMI = 35.9)
      // AdjBW 0.4 = 70.46 + 0.4 * (110 - 70.46) = 86.28 kg
      final res = SpecializedDosingCalculator.selectWeightForSpecialPopulations(
        tbwKg: 110.0,
        heightCm: 175.0,
        isMale: true,
        drugType: NtiDrugType.gentamicin,
      );
      expect(res.isObese, isTrue);
      expect(res.selectedWeightKg, closeTo(86.28, 0.05));
      expect(res.rationale, contains('MANDATORY Adjusted Body Weight'));
    });

    test('5.4: Cockcroft-Gault with elderly sarcopenia SCr floor (0.8 mg/dL)', () {
      // 78-year-old female, 60 kg, SCr = 0.5 mg/dL
      final renal = SpecializedDosingCalculator.calculateCockcroftGaultWithElderlyFloor(
        ageYears: 78.0,
        weightKg: 60.0,
        serumCreatinineMgDl: 0.5,
        isMale: false,
      );
      expect(renal['rawCrCl'], closeTo(87.83, 0.10));
      expect(renal['effectiveCrCl'], closeTo(54.90, 0.10));
      expect(renal['floorApplied'], isTrue);
    });

    test('5.5: Pediatric Schwartz formula across subpopulation k-values', () {
      // Preterm infant: height 40 cm, SCr 0.8, k = 0.33
      final preterm = SpecializedDosingCalculator.calculateBedsideSchwartz(
        heightCm: 40.0,
        serumCreatinineMgDl: 0.8,
        isPreterm: true,
      );
      // (0.33 * 40) / 0.8 = 16.5
      expect(preterm, closeTo(16.5, 0.05));

      // Term infant: height 50 cm, SCr 0.5, k = 0.45
      final termInfant = SpecializedDosingCalculator.calculateBedsideSchwartz(
        heightCm: 50.0,
        serumCreatinineMgDl: 0.5,
        isTermInfant: true,
      );
      // (0.45 * 50) / 0.5 = 45.0
      expect(termInfant, closeTo(45.0, 0.05));

      // Child: height 110 cm, SCr 0.6, k = 0.413
      final child = SpecializedDosingCalculator.calculateBedsideSchwartz(
        heightCm: 110.0,
        serumCreatinineMgDl: 0.6,
      );
      // (0.413 * 110) / 0.6 = 75.72
      expect(child, closeTo(75.72, 0.05));
    });
  });

  group('6. High-Alert Continuous Infusions (Inotropes & Vasopressors)', () {
    test('6.1: Norepinephrine standard and double-strength pump rate calculation', () {
      // Patient 70 kg, ordered rate 0.1 mcg/kg/min
      // Single strength (16 mcg/mL): pump rate = (0.1 * 70 * 60) / 16 = 26.25 mL/hr
      final singleRes = SpecializedDosingCalculator.calculateVasoactiveInfusion(
        drug: VasoactiveDrug.norepinephrine,
        orderedDose: 0.10,
        doseUnit: 'mcg/kg/min',
        patientWeightKg: 70.0,
        dilution: VasoactiveDilution.singleStrength,
      );
      expect(singleRes.pumpRateMlPerHr, closeTo(26.25, 0.01));
      expect(singleRes.isCeilingExceeded, isFalse);

      // Double strength (32 mcg/mL): pump rate = (0.1 * 70 * 60) / 32 = 13.125 mL/hr
      final doubleRes = SpecializedDosingCalculator.calculateVasoactiveInfusion(
        drug: VasoactiveDrug.norepinephrine,
        orderedDose: 0.10,
        doseUnit: 'mcg/kg/min',
        patientWeightKg: 70.0,
        dilution: VasoactiveDilution.doubleStrength,
      );
      expect(doubleRes.pumpRateMlPerHr, closeTo(13.125, 0.01));
    });

    test('6.2: Dopamine rate calculation and unit conversion from absolute mcg/min', () {
      // Patient 80 kg, ordered dose 400 mcg/min, standard concentration 1600 mcg/mL
      // Rate = (400 * 60) / 1600 = 15.0 mL/hr
      // Delivered dose = 400 / 80 = 5.0 mcg/kg/min
      final dopa = SpecializedDosingCalculator.calculateVasoactiveInfusion(
        drug: VasoactiveDrug.dopamine,
        orderedDose: 400.0,
        doseUnit: 'mcg/min',
        patientWeightKg: 80.0,
      );
      expect(dopa.pumpRateMlPerHr, closeTo(15.0, 0.01));
      expect(dopa.deliveredMcgKgMin, closeTo(5.0, 0.01));
      expect(dopa.isCeilingExceeded, isFalse);
    });

    test('6.3: Rule 5 Non-blocking overdose policy on titration ceiling breach with clinical override', () {
      // Norepinephrine at 1.8 mcg/kg/min (ceiling = 1.0 mcg/kg/min) in 70 kg patient
      // Pump rate = (1.8 * 70 * 60) / 16 = 472.5 mL/hr
      final override = ClinicalOverrideJustification(
        clinicianId: 'MD-ICU-8821',
        justificationCategory: 'Refractory septic shock unresponsive to second-line vasopressor',
        clinicalNotes: 'Arterial MAP < 55 mmHg despite Vasopressin 0.03 U/min.',
        timestamp: DateTime(2026, 11, 6, 20, 30),
        deliveredDose: 1.80,
        rateUnit: 'mcg/kg/min',
      );

      final result = SpecializedDosingCalculator.calculateVasoactiveInfusion(
        drug: 'norepinephrine',
        orderedDose: 1.80,
        doseUnit: 'mcg/kg/min',
        patientWeightKg: 70.0,
        concentrationMcgPerMl: 16.0,
        overrideJustification: override,
      );

      expect(result.pumpRateMlPerHr, closeTo(472.5, 0.10));
      expect(result.isCeilingExceeded, isTrue);
      expect(result.warningMessage, contains('TITRATION CEILING EXCEEDED'));
      expect(result.overrideJustification, isNotNull);
      expect(result.overrideJustification!.clinicianId, equals('MD-ICU-8821'));
    });
  });

  group('7. Non-Positive, NaN, and Infinity Safety Guards', () {
    test('7.1: Vancomycin rejects non-positive or non-finite inputs', () {
      expect(
        () => SpecializedDosingCalculator.evaluateVancomycinAuc(auc24: -10.0),
        throwsArgumentError,
      );
      expect(
        () => SpecializedDosingCalculator.evaluateVancomycinAuc(auc24: double.nan),
        throwsArgumentError,
      );
      expect(
        () => SpecializedDosingCalculator.evaluateVancomycinAuc(auc24: double.infinity),
        throwsArgumentError,
      );
      expect(
        () => SpecializedDosingCalculator.evaluateVancomycinAuc(auc24: 500.0, micMgL: 0),
        throwsArgumentError,
      );
    });

    test('7.2: Sawchuk-Zaske rejects C1 <= C2 or Tau <= tInf', () {
      expect(
        () => SpecializedDosingCalculator.calculateVancomycinSawchukZaske(
          c1MgL: 10.0,
          c2MgL: 15.0, // C1 < C2 impossible!
          deltaTHours: 8.0,
          t1PostInfHours: 1.0,
          doseMg: 1000.0,
          tauHours: 12.0,
          tInfHours: 1.0,
        ),
        throwsArgumentError,
      );
      expect(
        () => SpecializedDosingCalculator.calculateVancomycinSawchukZaske(
          c1MgL: 25.0,
          c2MgL: 10.0,
          deltaTHours: 8.0,
          t1PostInfHours: 1.0,
          doseMg: 1000.0,
          tauHours: 1.0, // Tau == tInf impossible!
          tInfHours: 1.0,
        ),
        throwsArgumentError,
      );
    });

    test('7.3: Phenytoin rejects non-positive or non-finite inputs', () {
      expect(
        () => SpecializedDosingCalculator.evaluatePhenytoin(
          orderedDailyDoseMg: -300.0,
          weightKg: 70.0,
        ),
        throwsArgumentError,
      );
      expect(
        () => SpecializedDosingCalculator.evaluatePhenytoin(
          orderedDailyDoseMg: 300.0,
          weightKg: double.nan,
        ),
        throwsArgumentError,
      );
    });

    test('7.4: Special populations functions reject non-positive inputs', () {
      expect(
        () => SpecializedDosingCalculator.calculateDevineIbw(heightCm: -160.0, isMale: true),
        throwsArgumentError,
      );
      expect(
        () => SpecializedDosingCalculator.calculateBedsideSchwartz(
          heightCm: 100.0,
          serumCreatinineMgDl: 0.0,
        ),
        throwsArgumentError,
      );
      expect(
        () => SpecializedDosingCalculator.calculateCockcroftGaultWithElderlyFloor(
          ageYears: -70.0,
          weightKg: 60.0,
          serumCreatinineMgDl: 0.8,
          isMale: true,
        ),
        throwsArgumentError,
      );
    });

    test('7.5: Vasoactive infusion rejects non-positive inputs', () {
      expect(
        () => SpecializedDosingCalculator.calculateVasoactiveInfusion(
          drug: VasoactiveDrug.norepinephrine,
          orderedDose: -0.1,
          doseUnit: 'mcg/kg/min',
          patientWeightKg: 70.0,
        ),
        throwsArgumentError,
      );
      expect(
        () => SpecializedDosingCalculator.calculateVasoactiveInfusion(
          drug: VasoactiveDrug.norepinephrine,
          orderedDose: 0.1,
          doseUnit: 'mcg/kg/min',
          patientWeightKg: 0.0,
        ),
        throwsArgumentError,
      );
    });
  });

  group('8. Domain Model Serialization & Value Equality', () {
    test('8.1: VancomycinDosingResult serialization roundtrip', () {
      final orig = SpecializedDosingCalculator.evaluateVancomycinAuc(
        auc24: 510.0,
        micMgL: 1.0,
        severity: InfectionSeverity.severeInvasive,
        recommendedDoseMg: 1000.0,
      );
      final map = orig.toMap();
      final restored = VancomycinDosingResult.fromMap(map);
      expect(restored, equals(orig));
      expect(restored.hashCode, equals(orig.hashCode));
      expect(restored.toString(), contains('VancomycinDosingResult'));
    });

    test('8.2: HartfordNomogramResult serialization roundtrip', () {
      final orig = SpecializedDosingCalculator.evaluateHartfordNomogram(
        randomLevelMgL: 7.0,
        hoursPostDose: 9.0,
      );
      final map = orig.toMap();
      final restored = HartfordNomogramResult.fromMap(map);
      expect(restored, equals(orig));
      expect(restored.hashCode, equals(orig.hashCode));
    });

    test('8.3: ConventionalAminoglycosideResult serialization roundtrip', () {
      final orig = SpecializedDosingCalculator.evaluateConventionalAminoglycoside(
        drug: NtiDrugType.gentamicin,
        doseMg: 120.0,
        tauHours: 8.0,
        tInfHours: 0.5,
        vd: 17.5,
        ke: 0.25,
      );
      final map = orig.toMap();
      final restored = ConventionalAminoglycosideResult.fromMap(map);
      expect(restored, equals(orig));
    });

    test('8.4: PhenytoinDosingResult serialization roundtrip', () {
      final orig = SpecializedDosingCalculator.evaluatePhenytoin(
        orderedDailyDoseMg: 350.0,
        weightKg: 70.0,
        observedSerumPhenytoinMgL: 12.0,
        serumAlbuminGPerDl: 3.0,
      );
      final map = orig.toMap();
      final restored = PhenytoinDosingResult.fromMap(map);
      expect(restored, equals(orig));
    });

    test('8.5: ClinicalOverrideJustification and VasoactiveInfusionResult serialization roundtrip', () {
      final override = ClinicalOverrideJustification(
        clinicianId: 'MD-991',
        justificationCategory: 'Cardiogenic shock',
        clinicalNotes: 'Max inotrope required',
        timestamp: DateTime(2026, 11, 6, 12, 0),
        deliveredDose: 2.0,
        rateUnit: 'mcg/kg/min',
      );
      final mapOverride = override.toMap();
      final restoredOverride = ClinicalOverrideJustification.fromMap(mapOverride);
      expect(restoredOverride, equals(override));

      final vaso = SpecializedDosingCalculator.calculateVasoactiveInfusion(
        drug: VasoactiveDrug.epinephrine,
        orderedDose: 2.0,
        doseUnit: 'mcg/kg/min',
        patientWeightKg: 70.0,
        overrideJustification: override,
      );
      final mapVaso = vaso.toMap();
      final restoredVaso = VasoactiveInfusionResult.fromMap(mapVaso);
      expect(restoredVaso, equals(vaso));
    });

    test('8.6: SpecialPopulationWeightResult serialization roundtrip', () {
      final orig = SpecializedDosingCalculator.selectWeightForSpecialPopulations(
        tbwKg: 105.0,
        heightCm: 170.0,
        isMale: true,
        drugType: NtiDrugType.gentamicin,
      );
      final map = orig.toMap();
      final restored = SpecialPopulationWeightResult.fromMap(map);
      expect(restored, equals(orig));
    });

    test('8.7: NtiSafetyCheckResult serialization roundtrip', () {
      final orig = SpecializedDosingCalculator.checkNtiSafety(
        drug: NtiDrugType.digoxin,
        serumPotassiumMEqL: 3.2,
      );
      final map = orig.toMap();
      final restored = NtiSafetyCheckResult.fromMap(map);
      expect(restored, equals(orig));
    });
  });
}
