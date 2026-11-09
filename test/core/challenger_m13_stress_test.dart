// ============================================================================
// Challenger M13 Adversarial Stress Test Suite
// ============================================================================
// Purpose: Empirically stress-test Specialized NTI Dosing & High-Alert Engines
// Archetype: Empirical Challenger (critic, specialist)
// Objectives:
//   1. Extreme patient weights (malnutrition, morbid obesity BMI > 70, micro-premie 0.5kg)
//   2. Phenytoin capacity saturation (Dose == Vmax, Dose > Vmax, hypoalbuminemia down to 0.5 g/dL, ESRD transition)
//   3. Hartford nomogram boundaries (exact 6.0h, exact 14.0h, sub-sampling 5.9h, late 14.1h/24h, Amikacin / 2.0)
//   4. High-alert vasoactive infusions (> 10x max titration ceiling, standard dilutions, zero/NaN inputs)
//   5. Vancomycin extreme kinetics (CrCl=0, ARC CrCl=200, severe Red Man rate, loading dose > 3000mg cap)
//   6. Rule 5 Non-blocking overdose invariant (values NEVER zeroed or clamped, override attached)
//   7. Robustness against IEEE-754 NaN, Infinity, and boundary conditions
//   8. Exact Clinical Boundary Thresholds (Elderly 65yo floor, 120% IBW, NTI electrolytes, Vasoactive 1.0 & 20.0)
//   9. Sawchuk-Zaske Extreme Dynamics & Kinetic Invariants
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/models/specialized_dosing_models.dart';
import 'package:drug_dosage_calculator/core/calculators/specialized_dosing_calculator.dart';

void main() {
  group('ADV-1: Extreme Patient Weights & Dosing Weight Selection', () {
    test('1.1 Malnourished adult (TBW 30 kg, IBW 70.46 kg): Enforce TBW, never negative', () {
      // 175 cm male (IBW = 70.46 kg), severe cachexia / malnutrition TBW = 30.0 kg
      final weightRes = SpecializedDosingCalculator.selectWeightForSpecialPopulations(
        tbwKg: 30.0,
        heightCm: 175.0,
        isMale: true,
        drugType: NtiDrugType.gentamicin,
      );

      expect(weightRes.isUnderweight, isTrue);
      expect(weightRes.isObese, isFalse);
      expect(weightRes.selectedWeightKg, equals(30.0));
      expect(weightRes.selectedWeightKg, greaterThan(0.0));
      expect(weightRes.rationale, contains('Underweight (TBW < IBW): Actual Body Weight enforced'));

      // Direct aminoglycoside selector must also enforce TBW
      final directWeight = SpecializedDosingCalculator.selectAminoglycosideDosingWeight(
        tbwKg: 30.0,
        heightCm: 175.0,
        isMale: true,
      );
      expect(directWeight, equals(30.0));
    });

    test('1.2 Severe morbid obesity (TBW 250 kg, height 170 cm, BMI 86.5 > 70): Mandatory AdjBW 0.4', () {
      // 170 cm male: IBW = 50 + 2.3 * (66.929 - 60) = 65.94 kg
      // TBW = 250 kg -> BMI = 250 / (1.7^2) = 86.5 kg/m^2
      // Expected AdjBW 0.4 = IBW + 0.4 * (TBW - IBW) = 65.937 + 0.4 * 184.063 ≈ 139.56 kg
      final weightRes = SpecializedDosingCalculator.selectWeightForSpecialPopulations(
        tbwKg: 250.0,
        heightCm: 170.0,
        isMale: true,
        drugType: NtiDrugType.amikacin,
      );

      expect(weightRes.isObese, isTrue);
      expect(weightRes.isUnderweight, isFalse);
      expect(weightRes.bmi, greaterThan(70.0));
      expect(weightRes.selectedWeightKg, closeTo(139.56, 0.10));
      expect(weightRes.rationale, contains('MANDATORY Adjusted Body Weight'));

      // Aminoglycoside direct function
      final directWeight = SpecializedDosingCalculator.selectAminoglycosideDosingWeight(
        tbwKg: 250.0,
        heightCm: 170.0,
        isMale: true,
      );
      expect(directWeight, closeTo(139.56, 0.10));
    });

    test('1.3 Neonatal micro-premie (0.5 kg / 500 g): Vancomycin and Schwartz scaling', () {
      // 500g micro-premie vancomycin loading dose (25-30 mg/kg)
      final loadRes = SpecializedDosingCalculator.calculateVancomycinLoadingDose(
        weightKg: 0.5,
        isSevereOrCriticallyIll: true,
      );
      expect(loadRes['rawMinDoseMg'], equals(12.5));
      expect(loadRes['rawMaxDoseMg'], equals(15.0));
      expect(loadRes['recommendedMinDoseMg'], equals(12.5));
      expect(loadRes['recommendedMaxDoseMg'], equals(15.0));
      expect(loadRes['capApplied'], isFalse);

      // Micro-premie Schwartz: height 28 cm, SCr 0.65 mg/dL, preterm k = 0.33
      final egfr = SpecializedDosingCalculator.calculateBedsideSchwartz(
        heightCm: 28.0,
        serumCreatinineMgDl: 0.65,
        isPreterm: true,
      );
      // eGFR = (0.33 * 28.0) / 0.65 = 14.215 mL/min/1.73m^2
      expect(egfr, closeTo(14.22, 0.05));
      expect(egfr, greaterThan(0.0));
    });
  });

  group('ADV-2: Phenytoin Non-Linear Saturation & Albumin/Renal Corrections', () {
    test('2.1 Dose == Vmax (Dose exactly saturates capacity): Guard prevents crash and preserves dose', () {
      // 70 kg patient, Vmax = 7.0 mg/kg/day -> total Vmax = 490 mg/day
      // Ordered dose = exactly 490 mg/day
      final res = SpecializedDosingCalculator.evaluatePhenytoin(
        orderedDailyDoseMg: 490.0,
        weightKg: 70.0,
        vmaxMgPerKgDay: 7.0,
        kmMgL: 4.0,
      );

      expect(res.isCapacityExceeded, isTrue);
      expect(res.predictedCssMgL, isNull); // Prevents division by zero or NaN
      expect(res.orderedDailyDoseMg, equals(490.0)); // Preserved per Rule 5
      expect(res.isToxic, isTrue);
      expect(res.warningCodes, contains('phenytoinCapacityExceeded'));
      expect(res.clinicalGuidance, contains('CRITICAL SATURATION'));
    });

    test('2.2 Dose > Vmax (e.g. 10 mg/kg/day vs 7 mg/kg/day = 700 mg/day): Guard intercepts negative denominator', () {
      // 70 kg patient, total Vmax = 490 mg/day. Ordered dose = 700 mg/day (10 mg/kg/day)
      final res = SpecializedDosingCalculator.evaluatePhenytoin(
        orderedDailyDoseMg: 700.0,
        weightKg: 70.0,
      );

      expect(res.isCapacityExceeded, isTrue);
      expect(res.predictedCssMgL, isNull);
      expect(res.orderedDailyDoseMg, equals(700.0));
      expect(res.isToxic, isTrue);
      expect(res.warningCodes, contains('phenytoinCapacityExceeded'));
    });

    test('2.3 Profound hypoalbuminemia (0.5 g/dL) in normal renal function (CrCl 80 mL/min)', () {
      // Sheiner-Tozer: Cadj = Cobs / (0.2 * Alb + 0.1)
      // Alb = 0.5 g/dL -> denom = 0.2 * 0.5 + 0.1 = 0.20
      // Case A: Observed Cobs = 8.5 mg/L -> Cadj = 8.5 / 0.20 = 42.5 mg/L (> 40 mg/L -> Lethargy/Stupor tier)
      final resA = SpecializedDosingCalculator.evaluatePhenytoin(
        orderedDailyDoseMg: 300.0,
        weightKg: 70.0,
        observedSerumPhenytoinMgL: 8.5,
        serumAlbuminGPerDl: 0.5,
        crclMlMin: 80.0,
      );

      expect(resA.isSheinerTozerApplied, isTrue);
      expect(resA.isWinterTozerApplied, isFalse);
      expect(resA.adjustedCssMgL, closeTo(42.5, 1e-4));
      expect(resA.isToxic, isTrue);
      expect(resA.toxicityTier, contains('Lethargy, confusion, stupor'));

      // Case B: Boundary Cobs = 8.0 mg/L -> Cadj = 8.0 / 0.20 = 40.0 mg/L (Ataxia/Tremor tier)
      final resB = SpecializedDosingCalculator.evaluatePhenytoin(
        orderedDailyDoseMg: 300.0,
        weightKg: 70.0,
        observedSerumPhenytoinMgL: 8.0,
        serumAlbuminGPerDl: 0.5,
        crclMlMin: 80.0,
      );
      expect(resB.adjustedCssMgL, closeTo(40.0, 1e-4));
      expect(resB.toxicityTier, contains('Ataxia, slurred speech, tremors'));
    });

    test('2.4 ESRD CrCl < 20 transition: Sharp threshold check between 20.0 and 19.9 mL/min', () {
      // At CrCl = 20.0 mL/min: Sheiner-Tozer applies (denom = 0.2 * 2.0 + 0.1 = 0.5)
      // Cadj = 10.0 / 0.5 = 20.0 mg/L
      final at20 = SpecializedDosingCalculator.evaluatePhenytoin(
        orderedDailyDoseMg: 300.0,
        weightKg: 70.0,
        observedSerumPhenytoinMgL: 10.0,
        serumAlbuminGPerDl: 2.0,
        crclMlMin: 20.0,
      );
      expect(at20.isSheinerTozerApplied, isTrue);
      expect(at20.isWinterTozerApplied, isFalse);
      expect(at20.adjustedCssMgL, closeTo(20.0, 1e-4));

      // At CrCl = 19.9 mL/min: Winter-Tozer applies for ESRD (denom = 0.1 * 2.0 + 0.1 = 0.3)
      // Cadj = 10.0 / 0.3 = 33.33 mg/L
      final below20 = SpecializedDosingCalculator.evaluatePhenytoin(
        orderedDailyDoseMg: 300.0,
        weightKg: 70.0,
        observedSerumPhenytoinMgL: 10.0,
        serumAlbuminGPerDl: 2.0,
        crclMlMin: 19.9,
      );
      expect(below20.isWinterTozerApplied, isTrue);
      expect(below20.isSheinerTozerApplied, isFalse);
      expect(below20.adjustedCssMgL, closeTo(33.33, 0.05));
      expect(below20.isToxic, isTrue);

      // Anuric dialysis patient (CrCl = 0.0 mL/min): Winter-Tozer holds
      final anuric = SpecializedDosingCalculator.evaluatePhenytoin(
        orderedDailyDoseMg: 300.0,
        weightKg: 70.0,
        observedSerumPhenytoinMgL: 10.0,
        serumAlbuminGPerDl: 2.0,
        crclMlMin: 0.0,
      );
      expect(anuric.isWinterTozerApplied, isTrue);
      expect(anuric.adjustedCssMgL, closeTo(33.33, 0.05));
    });

    test('2.5 Target Css dose calculation rejects zero or negative Km and non-positive targets', () {
      expect(
        () => SpecializedDosingCalculator.calculatePhenytoinDoseForTargetCss(
          targetCssMgL: 15.0,
          weightKg: 70.0,
          kmMgL: 0.0,
        ),
        throwsArgumentError,
      );
      expect(
        () => SpecializedDosingCalculator.calculatePhenytoinDoseForTargetCss(
          targetCssMgL: 15.0,
          weightKg: 70.0,
          kmMgL: -4.0,
        ),
        throwsArgumentError,
      );
      expect(
        () => SpecializedDosingCalculator.calculatePhenytoinDoseForTargetCss(
          targetCssMgL: -15.0,
          weightKg: 70.0,
        ),
        throwsArgumentError,
      );
    });
  });

  group('ADV-3: Hartford Aminoglycoside Nomogram Boundary Mathematics', () {
    test('3.1 Exact 6.0h boundary line transitions (earliest valid sampling point)', () {
      // At hoursPostDose = 6.0h (deltaT = 0):
      // cQ24 = 9.0 mg/L, cQ36 = 11.0 mg/L, cQ48 = 13.0 mg/L

      // Exactly at q24 upper bound: 9.0 mg/L -> q24h
      final res24 = SpecializedDosingCalculator.evaluateHartfordNomogram(
        randomLevelMgL: 9.0,
        hoursPostDose: 6.0,
      );
      expect(res24.isWindowViolation, isFalse);
      expect(res24.interval, equals(HartfordInterval.q24h));
      expect(res24.recommendedIntervalHours, equals(24));

      // Just above q24 bound: 9.001 mg/L -> q36h
      final res36a = SpecializedDosingCalculator.evaluateHartfordNomogram(
        randomLevelMgL: 9.001,
        hoursPostDose: 6.0,
      );
      expect(res36a.interval, equals(HartfordInterval.q36h));
      expect(res36a.recommendedIntervalHours, equals(36));

      // Exactly at q36 upper bound: 11.0 mg/L -> q36h
      final res36b = SpecializedDosingCalculator.evaluateHartfordNomogram(
        randomLevelMgL: 11.0,
        hoursPostDose: 6.0,
      );
      expect(res36b.interval, equals(HartfordInterval.q36h));

      // Just above q36 bound: 11.001 mg/L -> q48h
      final res48a = SpecializedDosingCalculator.evaluateHartfordNomogram(
        randomLevelMgL: 11.001,
        hoursPostDose: 6.0,
      );
      expect(res48a.interval, equals(HartfordInterval.q48h));
      expect(res48a.recommendedIntervalHours, equals(48));

      // Exactly at q48 upper bound: 13.0 mg/L -> q48h
      final res48b = SpecializedDosingCalculator.evaluateHartfordNomogram(
        randomLevelMgL: 13.0,
        hoursPostDose: 6.0,
      );
      expect(res48b.interval, equals(HartfordInterval.q48h));

      // Just above q48 bound: 13.001 mg/L -> offNomogramHold
      final resHold = SpecializedDosingCalculator.evaluateHartfordNomogram(
        randomLevelMgL: 13.001,
        hoursPostDose: 6.0,
      );
      expect(resHold.interval, equals(HartfordInterval.offNomogramHold));
      expect(resHold.isOffNomogram, isTrue);
      expect(resHold.recommendedIntervalHours, isNull);
    });

    test('3.2 Exact 14.0h boundary line transitions (latest valid sampling point)', () {
      // At hoursPostDose = 14.0h (deltaT = 8.0):
      // cQ24 = 9.0 - (7/8)*8 = 2.0 mg/L
      // cQ36 = 11.0 - (6.5/8)*8 = 4.5 mg/L
      // cQ48 = 13.0 - (6/8)*8 = 7.0 mg/L

      // Exactly at q24 bound: 2.0 mg/L -> q24h
      final r24 = SpecializedDosingCalculator.evaluateHartfordNomogram(
        randomLevelMgL: 2.0,
        hoursPostDose: 14.0,
      );
      expect(r24.interval, equals(HartfordInterval.q24h));
      expect(r24.recommendedIntervalHours, equals(24));

      // Just above q24 bound: 2.01 mg/L -> q36h
      final r36a = SpecializedDosingCalculator.evaluateHartfordNomogram(
        randomLevelMgL: 2.01,
        hoursPostDose: 14.0,
      );
      expect(r36a.interval, equals(HartfordInterval.q36h));

      // Exactly at q36 bound: 4.5 mg/L -> q36h
      final r36b = SpecializedDosingCalculator.evaluateHartfordNomogram(
        randomLevelMgL: 4.5,
        hoursPostDose: 14.0,
      );
      expect(r36b.interval, equals(HartfordInterval.q36h));

      // Exactly at q48 bound: 7.0 mg/L -> q48h
      final r48 = SpecializedDosingCalculator.evaluateHartfordNomogram(
        randomLevelMgL: 7.0,
        hoursPostDose: 14.0,
      );
      expect(r48.interval, equals(HartfordInterval.q48h));

      // Just above q48 bound: 7.01 mg/L -> offNomogramHold
      final rHold = SpecializedDosingCalculator.evaluateHartfordNomogram(
        randomLevelMgL: 7.01,
        hoursPostDose: 14.0,
      );
      expect(rHold.interval, equals(HartfordInterval.offNomogramHold));
      expect(rHold.isOffNomogram, isTrue);
    });

    test('3.3 Sub-sampling (5.9h) and late-sampling (14.1h and 24.0h) trigger window violation', () {
      // 5.9h (6 minutes before 6.0h window opens)
      final early = SpecializedDosingCalculator.evaluateHartfordNomogram(
        randomLevelMgL: 5.0,
        hoursPostDose: 5.9,
      );
      expect(early.isWindowViolation, isTrue);
      expect(early.interval, equals(HartfordInterval.offNomogramHold));
      expect(early.clinicalGuidance, contains('outside valid Hartford nomogram window'));

      // 14.1h (6 minutes after 14.0h window closes)
      final late14 = SpecializedDosingCalculator.evaluateHartfordNomogram(
        randomLevelMgL: 2.0,
        hoursPostDose: 14.1,
      );
      expect(late14.isWindowViolation, isTrue);
      expect(late14.interval, equals(HartfordInterval.offNomogramHold));

      // 24.0h (trough sampling mistaken for Hartford random level)
      final late24 = SpecializedDosingCalculator.evaluateHartfordNomogram(
        randomLevelMgL: 1.0,
        hoursPostDose: 24.0,
      );
      expect(late24.isWindowViolation, isTrue);
    });

    test('3.4 Amikacin level normalization (level / 2.0) across boundaries', () {
      // At 14.0h: boundary lines are 2.0, 4.5, 7.0
      // Amikacin level = 4.0 mg/L -> normalized = 2.0 mg/L -> q24h!
      final amk24 = SpecializedDosingCalculator.evaluateHartfordNomogram(
        randomLevelMgL: 4.0,
        hoursPostDose: 14.0,
        isAmikacin: true,
      );
      expect(amk24.normalizedLevelMgL, equals(2.0));
      expect(amk24.interval, equals(HartfordInterval.q24h));

      // Amikacin level = 9.0 mg/L -> normalized = 4.5 mg/L -> q36h!
      final amk36 = SpecializedDosingCalculator.evaluateHartfordNomogram(
        randomLevelMgL: 9.0,
        hoursPostDose: 14.0,
        isAmikacin: true,
      );
      expect(amk36.normalizedLevelMgL, equals(4.5));
      expect(amk36.interval, equals(HartfordInterval.q36h));

      // Amikacin level = 14.0 mg/L -> normalized = 7.0 mg/L -> q48h!
      final amk48 = SpecializedDosingCalculator.evaluateHartfordNomogram(
        randomLevelMgL: 14.0,
        hoursPostDose: 14.0,
        isAmikacin: true,
      );
      expect(amk48.normalizedLevelMgL, equals(7.0));
      expect(amk48.interval, equals(HartfordInterval.q48h));

      // Amikacin level = 15.0 mg/L -> normalized = 7.5 mg/L -> offNomogramHold!
      final amkHold = SpecializedDosingCalculator.evaluateHartfordNomogram(
        randomLevelMgL: 15.0,
        hoursPostDose: 14.0,
        isAmikacin: true,
      );
      expect(amkHold.normalizedLevelMgL, equals(7.5));
      expect(amkHold.interval, equals(HartfordInterval.offNomogramHold));
      expect(amkHold.isOffNomogram, isTrue);
    });
  });

  group('ADV-4: High-Alert Vasoactive Infusion Engines & Rule 5 Invariant', () {
    test('4.1 Extreme Overdose (> 10x max titration ceiling): Norepinephrine 15.0 mcg/kg/min', () {
      // Patient 70 kg, ordered dose 15.0 mcg/kg/min (ceiling = 1.0 mcg/kg/min -> 1500% ceiling!)
      // Dilution: standard 16 mcg/mL
      // Expected pump rate = (15.0 * 70 * 60) / 16 = 3937.5 mL/hr
      final override = ClinicalOverrideJustification(
        clinicianId: 'MD-RESUS-01',
        justificationCategory: 'Extreme vasoplegic arrest / cardiopulmonary bypass weaning failure',
        clinicalNotes: 'Max multi-vasopressor escalation protocol.',
        timestamp: DateTime(2026, 11, 7, 10, 0),
        deliveredDose: 15.0,
        rateUnit: 'mcg/kg/min',
      );

      final res = SpecializedDosingCalculator.calculateVasoactiveInfusion(
        drug: VasoactiveDrug.norepinephrine,
        orderedDose: 15.0,
        doseUnit: 'mcg/kg/min',
        patientWeightKg: 70.0,
        overrideJustification: override,
      );

      // Rule 5: Value must NOT be zeroed, clamped to ceiling, or suppressed
      expect(res.pumpRateMlPerHr, closeTo(3937.5, 0.10));
      expect(res.deliveredMcgKgMin, equals(15.0));
      expect(res.isCeilingExceeded, isTrue);
      expect(res.ceilingThreshold, equals(1.0));
      expect(res.warningMessage, contains('TITRATION CEILING EXCEEDED'));
      expect(res.overrideJustification, isNotNull);
      expect(res.overrideJustification!.deliveredDose, equals(15.0));
    });

    test('4.2 Standard and Custom Dilutions (Norepi 16/32/64 mcg/mL, Epi 16/32, Dopa 1600/3200, Dobut 1000/2000)', () {
      // Norepinephrine quadruple custom strength (64 mcg/mL) for profound fluid restriction
      final norepiQuad = SpecializedDosingCalculator.calculateVasoactiveInfusion(
        drug: VasoactiveDrug.norepinephrine,
        orderedDose: 0.50,
        doseUnit: 'mcg/kg/min',
        patientWeightKg: 80.0,
        concentrationMcgPerMl: 64.0,
        dilution: VasoactiveDilution.custom,
      );
      // Rate = (0.50 * 80 * 60) / 64 = 37.5 mL/hr
      expect(norepiQuad.pumpRateMlPerHr, closeTo(37.5, 0.01));
      expect(norepiQuad.concentrationMcgPerMl, equals(64.0));
      expect(norepiQuad.dilutionType, equals(VasoactiveDilution.custom));

      // Epinephrine single vs double strength
      final epiSingle = SpecializedDosingCalculator.getStandardConcentrationMcgPerMl(
        drug: VasoactiveDrug.epinephrine,
        dilution: VasoactiveDilution.singleStrength,
      );
      final epiDouble = SpecializedDosingCalculator.getStandardConcentrationMcgPerMl(
        drug: VasoactiveDrug.epinephrine,
        dilution: VasoactiveDilution.doubleStrength,
      );
      expect(epiSingle, equals(16.0));
      expect(epiDouble, equals(32.0));

      // Dopamine single vs double strength
      final dopaSingle = SpecializedDosingCalculator.getStandardConcentrationMcgPerMl(
        drug: VasoactiveDrug.dopamine,
        dilution: VasoactiveDilution.singleStrength,
      );
      final dopaDouble = SpecializedDosingCalculator.getStandardConcentrationMcgPerMl(
        drug: VasoactiveDrug.dopamine,
        dilution: VasoactiveDilution.doubleStrength,
      );
      expect(dopaSingle, equals(1600.0));
      expect(dopaDouble, equals(3200.0));

      // Dobutamine single vs double strength
      final dobutSingle = SpecializedDosingCalculator.getStandardConcentrationMcgPerMl(
        drug: VasoactiveDrug.dobutamine,
        dilution: VasoactiveDilution.singleStrength,
      );
      final dobutDouble = SpecializedDosingCalculator.getStandardConcentrationMcgPerMl(
        drug: VasoactiveDrug.dobutamine,
        dilution: VasoactiveDilution.doubleStrength,
      );
      expect(dobutSingle, equals(1000.0));
      expect(dobutDouble, equals(2000.0));
    });

    test('4.3 Invalid patient weight, dose, or concentration must throw ArgumentError', () {
      expect(
        () => SpecializedDosingCalculator.calculateVasoactiveInfusion(
          drug: VasoactiveDrug.norepinephrine,
          orderedDose: 0.1,
          doseUnit: 'mcg/kg/min',
          patientWeightKg: 0.0, // Zero weight
        ),
        throwsArgumentError,
      );
      expect(
        () => SpecializedDosingCalculator.calculateVasoactiveInfusion(
          drug: VasoactiveDrug.norepinephrine,
          orderedDose: 0.1,
          doseUnit: 'mcg/kg/min',
          patientWeightKg: -70.0, // Negative weight
        ),
        throwsArgumentError,
      );
      expect(
        () => SpecializedDosingCalculator.calculateVasoactiveInfusion(
          drug: VasoactiveDrug.norepinephrine,
          orderedDose: 0.1,
          doseUnit: 'mcg/kg/min',
          patientWeightKg: double.nan, // NaN weight
        ),
        throwsArgumentError,
      );
      expect(
        () => SpecializedDosingCalculator.calculateVasoactiveInfusion(
          drug: VasoactiveDrug.norepinephrine,
          orderedDose: double.nan, // NaN dose
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
          patientWeightKg: 70.0,
          concentrationMcgPerMl: 0.0, // Zero concentration
        ),
        throwsArgumentError,
      );
    });
  });

  group('ADV-5: Vancomycin Extreme Pharmacokinetics & Safety Rules', () {
    test('5.1 Augmented Renal Clearance (ARC CrCl 200 mL/min): Rapid elimination (ke = 0.15 hr^-1)', () {
      // High elimination in trauma/burn/sepsis ARC patient
      // Target AUC 500 mg*h/L, Vd = 45 L, ke = 0.15 hr^-1 (t1/2 ≈ 4.6 hr), tau = 8h
      final recDose = SpecializedDosingCalculator.recommendVancomycinDoseForTargetAuc(
        targetAuc: 500.0,
        vd: 45.0,
        ke: 0.15,
        tauHours: 8.0,
      );
      // Daily Dose = 500 * (45 * 0.15) = 3375 mg/day
      // Dose q8h = 3375 / 3 = 1125 mg
      expect(recDose, closeTo(1125.0, 0.01));
    });

    test('5.2 Severe Red Man Syndrome infusion rate (> 10 mg/min ceiling): 2000 mg in 15 min', () {
      // 2000 mg infused over 15 minutes = 133.33 mg/min (13x safe ceiling!)
      final check = SpecializedDosingCalculator.checkRedManSyndromeRisk(
        doseMg: 2000.0,
        infusionDurationMinutes: 15.0,
      );

      expect(check['hasRedManSyndromeRisk'], isTrue);
      expect(check['rateMgPerMin'], closeTo(133.33, 0.05));
      expect(check['minSafeDurationMinutes'], equals(200.0)); // 2000 / 10 = 200 min (3.33 hr)
      expect(check['warning'], contains('exceeds 10 mg/min safe ceiling'));
    });

    test('5.3 Loading dose > 3000 mg cap adherence in morbid obesity (160 kg)', () {
      // 160 kg adult, severe sepsis
      // Raw: 25-30 mg/kg = 4000 - 4800 mg
      // Cap: 3000 mg ceiling
      final load = SpecializedDosingCalculator.calculateVancomycinLoadingDose(
        weightKg: 160.0,
        isSevereOrCriticallyIll: true,
      );

      expect(load['rawMinDoseMg'], equals(4000.0));
      expect(load['rawMaxDoseMg'], equals(4800.0));
      expect(load['recommendedMinDoseMg'], equals(3000.0));
      expect(load['recommendedMaxDoseMg'], equals(3000.0));
      expect(load['capApplied'], isTrue);
      expect(load['warning'], contains('Loading dose capped at 3000 mg'));
    });

    test('5.4 Severe nephrotoxicity alert for AUC24 > 600 mg·h/L while preserving ratio (Rule 5)', () {
      // AUC24 = 950 mg*h/L, MIC = 1.0 mg/L -> ratio = 950
      final res = SpecializedDosingCalculator.evaluateVancomycinAuc(
        auc24: 950.0,
        micMgL: 1.0,
        severity: InfectionSeverity.severeInvasive,
      );

      expect(res.isSupratherapeuticNephrotoxic, isTrue);
      expect(res.isTherapeutic, isFalse);
      expect(res.aucToMicRatio, equals(950.0)); // Preserved per Rule 5!
      expect(res.clinicalGuidance, contains('Acute Kidney Injury (AKI) risk'));
    });
  });

  group('ADV-6: IEEE-754 NaN and Infinity Robustness Across All Engines', () {
    test('6.1 Vancomycin rejects NaN, Infinity, negative, and zero', () {
      expect(
        () => SpecializedDosingCalculator.evaluateVancomycinAuc(auc24: double.nan),
        throwsArgumentError,
      );
      expect(
        () => SpecializedDosingCalculator.evaluateVancomycinAuc(auc24: double.infinity),
        throwsArgumentError,
      );
      expect(
        () => SpecializedDosingCalculator.evaluateVancomycinAuc(auc24: double.negativeInfinity),
        throwsArgumentError,
      );
      expect(
        () => SpecializedDosingCalculator.evaluateVancomycinAuc(auc24: -100.0),
        throwsArgumentError,
      );
      expect(
        () => SpecializedDosingCalculator.evaluateVancomycinAuc(auc24: 0.0),
        throwsArgumentError,
      );
      expect(
        () => SpecializedDosingCalculator.evaluateVancomycinAuc(auc24: 500.0, micMgL: double.nan),
        throwsArgumentError,
      );
      expect(
        () => SpecializedDosingCalculator.evaluateVancomycinAuc(auc24: 500.0, micMgL: double.infinity),
        throwsArgumentError,
      );
      expect(
        () => SpecializedDosingCalculator.evaluateVancomycinAuc(auc24: 500.0, micMgL: -1.0),
        throwsArgumentError,
      );
    });

    test('6.2 Vancomycin loading dose and Red Man rate reject NaN and Infinity', () {
      expect(
        () => SpecializedDosingCalculator.calculateVancomycinLoadingDose(weightKg: double.nan),
        throwsArgumentError,
      );
      expect(
        () => SpecializedDosingCalculator.calculateVancomycinLoadingDose(weightKg: double.infinity),
        throwsArgumentError,
      );
      expect(
        () => SpecializedDosingCalculator.checkRedManSyndromeRisk(
          doseMg: double.nan,
          infusionDurationMinutes: 60.0,
        ),
        throwsArgumentError,
      );
      expect(
        () => SpecializedDosingCalculator.checkRedManSyndromeRisk(
          doseMg: 1000.0,
          infusionDurationMinutes: double.infinity,
        ),
        throwsArgumentError,
      );
    });

    test('6.3 Hartford nomogram rejects NaN and Infinity', () {
      expect(
        () => SpecializedDosingCalculator.evaluateHartfordNomogram(
          randomLevelMgL: double.nan,
          hoursPostDose: 8.0,
        ),
        throwsArgumentError,
      );
      expect(
        () => SpecializedDosingCalculator.evaluateHartfordNomogram(
          randomLevelMgL: double.infinity,
          hoursPostDose: 8.0,
        ),
        throwsArgumentError,
      );
      expect(
        () => SpecializedDosingCalculator.evaluateHartfordNomogram(
          randomLevelMgL: 5.0,
          hoursPostDose: double.nan,
        ),
        throwsArgumentError,
      );
      expect(
        () => SpecializedDosingCalculator.evaluateHartfordNomogram(
          randomLevelMgL: 5.0,
          hoursPostDose: double.infinity,
        ),
        throwsArgumentError,
      );
    });

    test('6.4 Phenytoin rejects NaN and Infinity', () {
      expect(
        () => SpecializedDosingCalculator.evaluatePhenytoin(
          orderedDailyDoseMg: double.nan,
          weightKg: 70.0,
        ),
        throwsArgumentError,
      );
      expect(
        () => SpecializedDosingCalculator.evaluatePhenytoin(
          orderedDailyDoseMg: double.infinity,
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
      expect(
        () => SpecializedDosingCalculator.evaluatePhenytoin(
          orderedDailyDoseMg: 300.0,
          weightKg: double.infinity,
        ),
        throwsArgumentError,
      );
    });

    test('6.5 Special populations functions reject NaN and Infinity', () {
      expect(
        () => SpecializedDosingCalculator.calculateDevineIbw(
          heightCm: double.nan,
          isMale: true,
        ),
        throwsArgumentError,
      );
      expect(
        () => SpecializedDosingCalculator.calculateDevineIbw(
          heightCm: double.infinity,
          isMale: true,
        ),
        throwsArgumentError,
      );
    });
  });

  group('ADV-7: Exact Clinical Boundary Thresholds', () {
    test('7.1 Cockcroft-Gault 65-year elderly sarcopenia floor transition', () {
      // Age 64.9 yr, SCr = 0.5 mg/dL -> floor NOT applied
      final below65 = SpecializedDosingCalculator.calculateCockcroftGaultWithElderlyFloor(
        ageYears: 64.9,
        weightKg: 60.0,
        serumCreatinineMgDl: 0.5,
        isMale: false,
      );
      expect(below65['floorApplied'], isFalse);
      expect(below65['effectiveScr'], equals(0.5));

      // Age 65.0 yr, SCr = 0.5 mg/dL -> floor APPLIED (effectiveScr = 0.8)
      final at65 = SpecializedDosingCalculator.calculateCockcroftGaultWithElderlyFloor(
        ageYears: 65.0,
        weightKg: 60.0,
        serumCreatinineMgDl: 0.5,
        isMale: false,
      );
      expect(at65['floorApplied'], isTrue);
      expect(at65['effectiveScr'], equals(0.8));

      // Age 70.0 yr, SCr = 0.8 mg/dL -> floor NOT applied (already at floor)
      final atFloor = SpecializedDosingCalculator.calculateCockcroftGaultWithElderlyFloor(
        ageYears: 70.0,
        weightKg: 60.0,
        serumCreatinineMgDl: 0.8,
        isMale: false,
      );
      expect(atFloor['floorApplied'], isFalse);
      expect(atFloor['effectiveScr'], equals(0.8));
    });

    test('7.2 Aminoglycoside weight selection 120% IBW and BMI 30 boundaries', () {
      final ibw = SpecializedDosingCalculator.calculateDevineIbw(heightCm: 175.0, isMale: true);
      // TBW = 1.19 * IBW (BMI ≈ 27.4 < 30) -> normal weight, use IBW
      final normalW = SpecializedDosingCalculator.selectAminoglycosideDosingWeight(
        tbwKg: ibw * 1.19,
        heightCm: 175.0,
        isMale: true,
      );
      expect(normalW, closeTo(ibw, 0.001));

      // TBW = 1.20 * IBW -> obese threshold reached (>= 120% IBW), use AdjBW 0.4
      final obeseW = SpecializedDosingCalculator.selectAminoglycosideDosingWeight(
        tbwKg: ibw * 1.20,
        heightCm: 175.0,
        isMale: true,
      );
      final expectedAdj = ibw + 0.4 * (ibw * 1.20 - ibw);
      expect(obeseW, closeTo(expectedAdj, 0.001));

      // BMI >= 30.0 boundary test: height 160 cm, TBW = 76.8 kg (BMI = 76.8 / 1.6^2 = 30.0)
      // IBW female 160 cm: 45.5 + 2.3 * (62.99 - 60) = 52.38 kg
      // TBW / IBW = 76.8 / 52.38 = 1.46 (> 1.20)
      final bmi30W = SpecializedDosingCalculator.selectAminoglycosideDosingWeight(
        tbwKg: 76.8,
        heightCm: 160.0,
        isMale: false,
      );
      expect(bmi30W, closeTo(52.38 + 0.4 * (76.8 - 52.38), 0.10));
    });

    test('7.3 Digoxin and Lithium electrolyte threshold boundaries', () {
      // K+ = 3.50 mEq/L (exact lower normal limit -> safe)
      final kSafe = SpecializedDosingCalculator.checkNtiSafety(
        drug: NtiDrugType.digoxin,
        serumPotassiumMEqL: 3.50,
      );
      expect(kSafe.hasPotassiumRisk, isFalse);

      // K+ = 3.49 mEq/L (hypokalemia -> risk alert)
      final kRisk = SpecializedDosingCalculator.checkNtiSafety(
        drug: NtiDrugType.digoxin,
        serumPotassiumMEqL: 3.49,
      );
      expect(kRisk.hasPotassiumRisk, isTrue);

      // Mg2+ = 1.70 mg/dL (exact lower limit -> safe)
      final mgSafe = SpecializedDosingCalculator.checkNtiSafety(
        drug: NtiDrugType.digoxin,
        serumMagnesiumMgDl: 1.70,
      );
      expect(mgSafe.hasMagnesiumRisk, isFalse);

      // Mg2+ = 1.69 mg/dL (hypomagnesemia -> risk alert)
      final mgRisk = SpecializedDosingCalculator.checkNtiSafety(
        drug: NtiDrugType.digoxin,
        serumMagnesiumMgDl: 1.69,
      );
      expect(mgRisk.hasMagnesiumRisk, isTrue);

      // Na+ = 135.0 mEq/L (exact lower limit -> safe)
      final naSafe = SpecializedDosingCalculator.checkNtiSafety(
        drug: NtiDrugType.lithium,
        serumSodiumMEqL: 135.0,
      );
      expect(naSafe.hasSodiumRisk, isFalse);

      // Na+ = 134.9 mEq/L (hyponatremia -> risk alert)
      final naRisk = SpecializedDosingCalculator.checkNtiSafety(
        drug: NtiDrugType.lithium,
        serumSodiumMEqL: 134.9,
      );
      expect(naRisk.hasSodiumRisk, isTrue);
    });

    test('7.4 Vasoactive ceiling boundary thresholds (1.0 mcg/kg/min and 20.0 mcg/kg/min)', () {
      // Norepinephrine exactly at 1.0 mcg/kg/min -> NOT exceeded
      final norepiAt1 = SpecializedDosingCalculator.calculateVasoactiveInfusion(
        drug: VasoactiveDrug.norepinephrine,
        orderedDose: 1.0,
        doseUnit: 'mcg/kg/min',
        patientWeightKg: 70.0,
      );
      expect(norepiAt1.isCeilingExceeded, isFalse);

      // Norepinephrine at 1.001 mcg/kg/min -> EXCEEDED
      final norepiAbove1 = SpecializedDosingCalculator.calculateVasoactiveInfusion(
        drug: VasoactiveDrug.norepinephrine,
        orderedDose: 1.001,
        doseUnit: 'mcg/kg/min',
        patientWeightKg: 70.0,
      );
      expect(norepiAbove1.isCeilingExceeded, isTrue);

      // Dopamine exactly at 20.0 mcg/kg/min -> NOT exceeded
      final dopaAt20 = SpecializedDosingCalculator.calculateVasoactiveInfusion(
        drug: VasoactiveDrug.dopamine,
        orderedDose: 20.0,
        doseUnit: 'mcg/kg/min',
        patientWeightKg: 70.0,
      );
      expect(dopaAt20.isCeilingExceeded, isFalse);

      // Dopamine at 20.01 mcg/kg/min -> EXCEEDED
      final dopaAbove20 = SpecializedDosingCalculator.calculateVasoactiveInfusion(
        drug: VasoactiveDrug.dopamine,
        orderedDose: 20.01,
        doseUnit: 'mcg/kg/min',
        patientWeightKg: 70.0,
      );
      expect(dopaAbove20.isCeilingExceeded, isTrue);
    });
  });

  group('ADV-8: Sawchuk-Zaske Extreme Dynamics & Kinetic Invariants', () {
    test('8.1 Extreme prolonged half-life in dialysis/ESRD (t1/2 > 100 hours)', () {
      // Dose 1000 mg q48h, C1 = 28.0 mg/L drawn 1h post-inf, C2 = 21.0 mg/L drawn 46h after C1
      // ke = ln(28 / 21) / 46 = 0.28768 / 46 ≈ 0.006254 hr^-1 (t1/2 = 110.8 hr)
      final sz = SpecializedDosingCalculator.calculateVancomycinSawchukZaske(
        c1MgL: 28.0,
        c2MgL: 21.0,
        deltaTHours: 46.0,
        t1PostInfHours: 1.0,
        doseMg: 1000.0,
        tauHours: 48.0,
        tInfHours: 1.5,
      );

      expect(sz['ke']!, closeTo(0.006254, 0.0001));
      expect(sz['truePeak']!, greaterThan(28.0));
      expect(sz['trueTrough']!, greaterThan(15.0));
      expect(sz['vd']!, greaterThan(20.0));
      expect(sz['auc24']!, greaterThan(200.0));
    });

    test('8.2 Equal peak and trough (C1 == C2) must throw ArgumentError', () {
      expect(
        () => SpecializedDosingCalculator.calculateVancomycinSawchukZaske(
          c1MgL: 20.0,
          c2MgL: 20.0,
          deltaTHours: 8.0,
          t1PostInfHours: 1.0,
          doseMg: 1000.0,
          tauHours: 12.0,
          tInfHours: 1.0,
        ),
        throwsArgumentError,
      );
    });
  });
}
