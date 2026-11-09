// ============================================================================
// Challenger M13 Independent Oracle & Adversarial Verification Test Suite
// ============================================================================
// Independent clinical pharmacology oracles and stress-test harnesses for:
// 1. Sawchuk-Zaske 2-point regression & pharmacokinetic parameter concordance
// 2. Hartford Extended-Interval Aminoglycoside Nomogram exact coordinate boundaries
// 3. Bedside Schwartz pediatric eGFR subpopulation k-constant matrix
// 4. Cockcroft-Gault elderly sarcopenia serum creatinine floor (0.8 mg/dL)
// 5. High-alert vasoactive infusions, standard dilutions, & Rule 5 non-blocking
// 6. Phenytoin Michaelis-Menten saturation & Sheiner/Winter-Tozer albumin adjustment
// 7. NTI electrolyte disturbance and sampling timing guards
// 8. Special populations weight selection (Devine IBW, AdjBW 0.4)
// ============================================================================

import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/models/specialized_dosing_models.dart';
import 'package:drug_dosage_calculator/core/calculators/specialized_dosing_calculator.dart';

// ============================================================================
// INDEPENDENT MATHEMATICAL ORACLES
// ============================================================================

/// Independent Sawchuk-Zaske elimination rate constant ke (hr^-1).
double oracleSawchukZaskeKe(double c1, double c2, double deltaT) {
  return math.log(c1 / c2) / deltaT;
}

/// Independent Sawchuk-Zaske true peak concentration at end of infusion.
double oracleSawchukZaskeTruePeak(double c1, double ke, double t1PostInf) {
  return c1 * math.exp(ke * t1PostInf);
}

/// Independent Sawchuk-Zaske true trough concentration at end of interval.
double oracleSawchukZaskeTrueTrough(
    double truePeak, double ke, double tau, double tInf) {
  return truePeak * math.exp(-ke * (tau - tInf));
}

/// Independent Sawchuk-Zaske volume of distribution Vd (L).
double oracleSawchukZaskeVd({
  required double dose,
  required double ke,
  required double tInf,
  required double truePeak,
  required double trueTrough,
}) {
  final denom = tInf * ke * (truePeak - trueTrough * math.exp(-ke * tInf));
  return (dose * (1.0 - math.exp(-ke * tInf))) / denom;
}

/// Independent Sawchuk-Zaske 24-hour AUC (mg·h/L).
double oracleSawchukZaskeAuc24({
  required double dose,
  required double tau,
  required double ke,
  required double vd,
}) {
  return (dose * (24.0 / tau)) / (ke * vd);
}

/// Independent Nicolau 1995 Hartford nomogram boundary lines.
double oracleHartfordCq24(double t) => 9.0 - 0.875 * (t - 6.0);
double oracleHartfordCq36(double t) => 11.0 - 0.8125 * (t - 6.0);
double oracleHartfordCq48(double t) => 13.0 - 0.750 * (t - 6.0);

HartfordInterval oracleHartfordInterval(double normalizedLevel, double t) {
  if (t < 6.0 || t > 14.0) return HartfordInterval.offNomogramHold;
  final cq24 = oracleHartfordCq24(t);
  final cq36 = oracleHartfordCq36(t);
  final cq48 = oracleHartfordCq48(t);
  if (normalizedLevel <= cq24) return HartfordInterval.q24h;
  if (normalizedLevel <= cq36) return HartfordInterval.q36h;
  if (normalizedLevel <= cq48) return HartfordInterval.q48h;
  return HartfordInterval.offNomogramHold;
}

/// Independent Bedside Schwartz eGFR (mL/min/1.73m²).
double oracleBedsideSchwartz(double k, double heightCm, double scr) {
  return (k * heightCm) / scr;
}

/// Independent Cockcroft-Gault CrCl (mL/min).
double oracleCockcroftGault({
  required double age,
  required double weight,
  required double scr,
  required bool isMale,
}) {
  return ((140.0 - age) * weight) / (72.0 * scr) * (isMale ? 1.0 : 0.85);
}

/// Independent vasoactive infusion rate (mL/hr) for weight-based dosing.
double oracleVasoactiveRateWeightBased({
  required double doseMcgKgMin,
  required double weightKg,
  required double concMcgMl,
}) {
  return (doseMcgKgMin * weightKg * 60.0) / concMcgMl;
}

/// Independent vasoactive infusion rate (mL/hr) for absolute dosing.
double oracleVasoactiveRateAbsolute({
  required double doseMcgMin,
  required double concMcgMl,
}) {
  return (doseMcgMin * 60.0) / concMcgMl;
}

// ============================================================================
// MAIN TEST SUITE
// ============================================================================

void main() {
  group('Challenger M13.1: Sawchuk-Zaske 2-Point Kinetic Concordance', () {
    test('1.1 Standard sepsis regimen concordance within 1e-6', () {
      const c1 = 28.0;
      const c2 = 12.0;
      const deltaT = 9.0;
      const t1 = 1.0;
      const dose = 1000.0;
      const tau = 12.0;
      const tInf = 1.0;

      final actual = SpecializedDosingCalculator.calculateVancomycinSawchukZaske(
        c1MgL: c1,
        c2MgL: c2,
        deltaTHours: deltaT,
        t1PostInfHours: t1,
        doseMg: dose,
        tauHours: tau,
        tInfHours: tInf,
      );

      final expKe = oracleSawchukZaskeKe(c1, c2, deltaT);
      final expTruePeak = oracleSawchukZaskeTruePeak(c1, expKe, t1);
      final expTrueTrough =
          oracleSawchukZaskeTrueTrough(expTruePeak, expKe, tau, tInf);
      final expVd = oracleSawchukZaskeVd(
        dose: dose,
        ke: expKe,
        tInf: tInf,
        truePeak: expTruePeak,
        trueTrough: expTrueTrough,
      );
      final expAuc24 = oracleSawchukZaskeAuc24(
        dose: dose,
        tau: tau,
        ke: expKe,
        vd: expVd,
      );

      expect(actual['ke']!, closeTo(expKe, 1e-6));
      expect(actual['truePeak']!, closeTo(expTruePeak, 1e-6));
      expect(actual['trueTrough']!, closeTo(expTrueTrough, 1e-6));
      expect(actual['vd']!, closeTo(expVd, 1e-6));
      expect(actual['auc24']!, closeTo(expAuc24, 1e-6));
    });

    test('1.2 Severe renal impairment (slow elimination) concordance within 1e-6', () {
      const c1 = 34.5;
      const c2 = 23.8;
      const deltaT = 18.0;
      const t1 = 1.5;
      const dose = 1000.0;
      const tau = 24.0;
      const tInf = 2.0;

      final actual = SpecializedDosingCalculator.calculateVancomycinSawchukZaske(
        c1MgL: c1,
        c2MgL: c2,
        deltaTHours: deltaT,
        t1PostInfHours: t1,
        doseMg: dose,
        tauHours: tau,
        tInfHours: tInf,
      );

      final expKe = oracleSawchukZaskeKe(c1, c2, deltaT);
      final expTruePeak = oracleSawchukZaskeTruePeak(c1, expKe, t1);
      final expTrueTrough =
          oracleSawchukZaskeTrueTrough(expTruePeak, expKe, tau, tInf);
      final expVd = oracleSawchukZaskeVd(
        dose: dose,
        ke: expKe,
        tInf: tInf,
        truePeak: expTruePeak,
        trueTrough: expTrueTrough,
      );
      final expAuc24 = oracleSawchukZaskeAuc24(
        dose: dose,
        tau: tau,
        ke: expKe,
        vd: expVd,
      );

      expect(actual['ke']!, closeTo(expKe, 1e-6));
      expect(actual['truePeak']!, closeTo(expTruePeak, 1e-6));
      expect(actual['trueTrough']!, closeTo(expTrueTrough, 1e-6));
      expect(actual['vd']!, closeTo(expVd, 1e-6));
      expect(actual['auc24']!, closeTo(expAuc24, 1e-6));
    });

    test('1.3 Augmented renal clearance (rapid elimination) concordance within 1e-6', () {
      const c1 = 22.0;
      const c2 = 4.2;
      const deltaT = 5.0;
      const t1 = 0.5;
      const dose = 1500.0;
      const tau = 8.0;
      const tInf = 1.5;

      final actual = SpecializedDosingCalculator.calculateVancomycinSawchukZaske(
        c1MgL: c1,
        c2MgL: c2,
        deltaTHours: deltaT,
        t1PostInfHours: t1,
        doseMg: dose,
        tauHours: tau,
        tInfHours: tInf,
      );

      final expKe = oracleSawchukZaskeKe(c1, c2, deltaT);
      final expTruePeak = oracleSawchukZaskeTruePeak(c1, expKe, t1);
      final expTrueTrough =
          oracleSawchukZaskeTrueTrough(expTruePeak, expKe, tau, tInf);
      final expVd = oracleSawchukZaskeVd(
        dose: dose,
        ke: expKe,
        tInf: tInf,
        truePeak: expTruePeak,
        trueTrough: expTrueTrough,
      );
      final expAuc24 = oracleSawchukZaskeAuc24(
        dose: dose,
        tau: tau,
        ke: expKe,
        vd: expVd,
      );

      expect(actual['ke']!, closeTo(expKe, 1e-6));
      expect(actual['truePeak']!, closeTo(expTruePeak, 1e-6));
      expect(actual['trueTrough']!, closeTo(expTrueTrough, 1e-6));
      expect(actual['vd']!, closeTo(expVd, 1e-6));
      expect(actual['auc24']!, closeTo(expAuc24, 1e-6));
    });

    test('1.4 Maintenance dose recommendation oracle cross-verification', () {
      const targetAuc = 520.0;
      const vd = 45.0;
      const ke = 0.075;
      const tau = 12.0;

      final recommendedDose =
          SpecializedDosingCalculator.recommendVancomycinDoseForTargetAuc(
        targetAuc: targetAuc,
        vd: vd,
        ke: ke,
        tauHours: tau,
      );

      // Independent math: Daily Clearance Dose = Target AUC * (Vd * Ke)
      // Per-interval Dose = Daily Dose / (24 / Tau)
      const expectedDose = (targetAuc * vd * ke) / (24.0 / tau);
      expect(recommendedDose, closeTo(expectedDose, 1e-6));
    });
  });

  group('Challenger M13.2: Hartford Nomogram Exact Coordinates & Boundary Testing', () {
    test('2.1 Exact boundary equations match Nicolau 1995 coefficients', () {
      // Slopes:
      // q24: (9.0 - 2.0) / (14.0 - 6.0) = 7.0 / 8.0 = 0.875
      // q36: (11.0 - 4.5) / (14.0 - 6.0) = 6.5 / 8.0 = 0.8125
      // q48: (13.0 - 7.0) / (14.0 - 6.0) = 6.0 / 8.0 = 0.750
      expect(oracleHartfordCq24(6.0), equals(9.0));
      expect(oracleHartfordCq24(14.0), equals(2.0));
      expect(oracleHartfordCq36(6.0), equals(11.0));
      expect(oracleHartfordCq36(14.0), equals(4.5));
      expect(oracleHartfordCq48(6.0), equals(13.0));
      expect(oracleHartfordCq48(14.0), equals(7.0));
    });

    test('2.2 Boundary stress-test: right on, right below (-1e-5), and right above (+1e-5) lines', () {
      const testHours = [6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0];
      const eps = 1e-5;

      for (final t in testHours) {
        final cq24 = oracleHartfordCq24(t);
        final cq36 = oracleHartfordCq36(t);
        final cq48 = oracleHartfordCq48(t);

        // 1. Right on C_q24 boundary line
        final onQ24 = SpecializedDosingCalculator.evaluateHartfordNomogram(
          randomLevelMgL: cq24,
          hoursPostDose: t,
        );
        expect(onQ24.interval, equals(HartfordInterval.q24h),
            reason: 'At t=$t, level exactly on C_q24 ($cq24) must yield q24h');
        expect(onQ24.recommendedIntervalHours, equals(24));
        expect(onQ24.isOffNomogram, isFalse);

        // 2. Just below C_q24 line
        final belowQ24 = SpecializedDosingCalculator.evaluateHartfordNomogram(
          randomLevelMgL: cq24 - eps,
          hoursPostDose: t,
        );
        expect(belowQ24.interval, equals(HartfordInterval.q24h));

        // 3. Just above C_q24 line (transitions into q36h)
        final aboveQ24 = SpecializedDosingCalculator.evaluateHartfordNomogram(
          randomLevelMgL: cq24 + eps,
          hoursPostDose: t,
        );
        expect(aboveQ24.interval, equals(HartfordInterval.q36h),
            reason: 'At t=$t, level just above C_q24 ($cq24 + $eps) must yield q36h');
        expect(aboveQ24.recommendedIntervalHours, equals(36));

        // 4. Right on C_q36 boundary line
        final onQ36 = SpecializedDosingCalculator.evaluateHartfordNomogram(
          randomLevelMgL: cq36,
          hoursPostDose: t,
        );
        expect(onQ36.interval, equals(HartfordInterval.q36h));
        expect(onQ36.recommendedIntervalHours, equals(36));

        // 5. Just above C_q36 line (transitions into q48h)
        final aboveQ36 = SpecializedDosingCalculator.evaluateHartfordNomogram(
          randomLevelMgL: cq36 + eps,
          hoursPostDose: t,
        );
        expect(aboveQ36.interval, equals(HartfordInterval.q48h),
            reason: 'At t=$t, level just above C_q36 ($cq36 + $eps) must yield q48h');
        expect(aboveQ36.recommendedIntervalHours, equals(48));

        // 6. Right on C_q48 boundary line
        final onQ48 = SpecializedDosingCalculator.evaluateHartfordNomogram(
          randomLevelMgL: cq48,
          hoursPostDose: t,
        );
        expect(onQ48.interval, equals(HartfordInterval.q48h));
        expect(onQ48.recommendedIntervalHours, equals(48));

        // 7. Just above C_q48 line (transitions into off-nomogram toxic hold)
        final aboveQ48 = SpecializedDosingCalculator.evaluateHartfordNomogram(
          randomLevelMgL: cq48 + eps,
          hoursPostDose: t,
        );
        expect(aboveQ48.interval, equals(HartfordInterval.offNomogramHold),
            reason: 'At t=$t, level just above C_q48 ($cq48 + $eps) must trigger toxic hold');
        expect(aboveQ48.recommendedIntervalHours, isNull);
        expect(aboveQ48.isOffNomogram, isTrue);
      }
    });

    test('2.3 Amikacin 2-fold level normalization across boundary transitions', () {
      // For Amikacin, 15 mg/kg nomogram level is divided by 2.0
      // So level = 2 * C_q24 should land exactly on q24h
      // level = 2 * C_q24 + 0.01 should land on q36h
      // level = 2 * C_q48 + 0.01 should trigger offNomogramHold
      for (final t in [7.0, 10.0, 12.0]) {
        final cq24 = oracleHartfordCq24(t);
        final cq48 = oracleHartfordCq48(t);

        final amkOnQ24 = SpecializedDosingCalculator.evaluateHartfordNomogram(
          randomLevelMgL: 2.0 * cq24,
          hoursPostDose: t,
          isAmikacin: true,
        );
        expect(amkOnQ24.drug, equals(NtiDrugType.amikacin));
        expect(amkOnQ24.normalizedLevelMgL, closeTo(cq24, 1e-6));
        expect(amkOnQ24.interval, equals(HartfordInterval.q24h));

        final amkAboveQ24 = SpecializedDosingCalculator.evaluateHartfordNomogram(
          randomLevelMgL: 2.0 * cq24 + 0.01,
          hoursPostDose: t,
          isAmikacin: true,
        );
        expect(amkAboveQ24.interval, equals(HartfordInterval.q36h));

        final amkToxic = SpecializedDosingCalculator.evaluateHartfordNomogram(
          randomLevelMgL: 2.0 * cq48 + 0.05,
          hoursPostDose: t,
          isAmikacin: true,
        );
        expect(amkToxic.interval, equals(HartfordInterval.offNomogramHold));
        expect(amkToxic.isOffNomogram, isTrue);
      }
    });

    test('2.4 Sampling window violations (< 6.0h or > 14.0h) rigorously handled', () {
      // 5.999h (pre-distribution phase)
      final preWindow = SpecializedDosingCalculator.evaluateHartfordNomogram(
        randomLevelMgL: 5.0,
        hoursPostDose: 5.999,
      );
      expect(preWindow.isWindowViolation, isTrue);
      expect(preWindow.isOffNomogram, isTrue);
      expect(preWindow.recommendedIntervalHours, isNull);
      expect(preWindow.interval, equals(HartfordInterval.offNomogramHold));

      // Exactly 6.0h (valid)
      final atStartWindow = SpecializedDosingCalculator.evaluateHartfordNomogram(
        randomLevelMgL: 5.0,
        hoursPostDose: 6.0,
      );
      expect(atStartWindow.isWindowViolation, isFalse);

      // Exactly 14.0h (valid)
      final atEndWindow = SpecializedDosingCalculator.evaluateHartfordNomogram(
        randomLevelMgL: 1.5,
        hoursPostDose: 14.0,
      );
      expect(atEndWindow.isWindowViolation, isFalse);

      // 14.001h (post-window)
      final postWindow = SpecializedDosingCalculator.evaluateHartfordNomogram(
        randomLevelMgL: 1.5,
        hoursPostDose: 14.001,
      );
      expect(postWindow.isWindowViolation, isTrue);
      expect(postWindow.isOffNomogram, isTrue);
      expect(postWindow.recommendedIntervalHours, isNull);
    });
  });

  group('Challenger M13.3: Bedside Schwartz Subpopulation k-Constants & GFR Oracle', () {
    test('3.1 Subpopulation k constants concordance against independent oracle', () {
      const testCases = [
        // heightCm, scr, isPreterm, isTermInfant, isAdolMale, expectedK
        [45.0, 0.6, true, false, false, 0.33], // Preterm infant
        [50.0, 0.4, false, true, false, 0.45], // Term infant
        [110.0, 0.5, false, false, false, 0.413], // Child / female adolescent
        [170.0, 0.8, false, false, true, 0.62], // Adolescent male
      ];

      for (final tc in testCases) {
        final height = tc[0] as double;
        final scr = tc[1] as double;
        final isPreterm = tc[2] as bool;
        final isTermInfant = tc[3] as bool;
        final isAdolMale = tc[4] as bool;
        final expectedK = tc[5] as double;

        final actualGfr = SpecializedDosingCalculator.calculateBedsideSchwartz(
          heightCm: height,
          serumCreatinineMgDl: scr,
          isPreterm: isPreterm,
          isTermInfant: isTermInfant,
          isAdolescentMale: isAdolMale,
        );

        final oracleGfr = oracleBedsideSchwartz(expectedK, height, scr);
        expect(actualGfr, closeTo(oracleGfr, 1e-9),
            reason: 'k=$expectedK, height=$height, scr=$scr');
      }
    });

    test('3.2 Custom k-constant override works deterministically', () {
      const customK = 0.55;
      const height = 125.0;
      const scr = 0.65;

      final actualGfr = SpecializedDosingCalculator.calculateBedsideSchwartz(
        heightCm: height,
        serumCreatinineMgDl: scr,
        kConstant: customK,
      );

      final oracleGfr = oracleBedsideSchwartz(customK, height, scr);
      expect(actualGfr, closeTo(oracleGfr, 1e-9));
    });

    test('3.3 Schwartz edge cases: non-positive height or SCr throw ArgumentError', () {
      expect(
        () => SpecializedDosingCalculator.calculateBedsideSchwartz(
          heightCm: 0.0,
          serumCreatinineMgDl: 0.5,
        ),
        throwsArgumentError,
      );
      expect(
        () => SpecializedDosingCalculator.calculateBedsideSchwartz(
          heightCm: 100.0,
          serumCreatinineMgDl: -0.5,
        ),
        throwsArgumentError,
      );
      expect(
        () => SpecializedDosingCalculator.calculateBedsideSchwartz(
          heightCm: 100.0,
          serumCreatinineMgDl: 0.5,
          kConstant: -0.1,
        ),
        throwsArgumentError,
      );
    });
  });

  group('Challenger M13.4: Cockcroft-Gault Elderly SCr Floor (0.8 mg/dL)', () {
    test('4.1 Age >= 65 with low SCr (0.4, 0.5, 0.6, 0.7) are floored to 0.8 mg/dL', () {
      const lowScrs = [0.4, 0.5, 0.6, 0.7];
      const ages = [65.0, 70.0, 80.0, 92.0];
      const weight = 60.0;

      for (final age in ages) {
        for (final isMale in [true, false]) {
          for (final scr in lowScrs) {
            final res =
                SpecializedDosingCalculator.calculateCockcroftGaultWithElderlyFloor(
              ageYears: age,
              weightKg: weight,
              serumCreatinineMgDl: scr,
              isMale: isMale,
            );

            expect(res['floorApplied'], isTrue,
                reason: 'Floor must apply for age $age and SCr $scr');
            expect(res['effectiveScr'], equals(0.8));

            // effectiveCrCl MUST match independent oracle with SCr = 0.8
            final expectedEffectiveCrCl = oracleCockcroftGault(
              age: age,
              weight: weight,
              scr: 0.8,
              isMale: isMale,
            );
            expect(res['effectiveCrCl'], closeTo(expectedEffectiveCrCl, 1e-9));

            // rawCrCl MUST match independent oracle with raw SCr
            final expectedRawCrCl = oracleCockcroftGault(
              age: age,
              weight: weight,
              scr: scr,
              isMale: isMale,
            );
            expect(res['rawCrCl'], closeTo(expectedRawCrCl, 1e-9));

            // Effective CrCl must be lower than dangerous unfloored raw CrCl
            expect(res['effectiveCrCl'], lessThan(res['rawCrCl']));
          }
        }
      }
    });

    test('4.2 Age >= 65 with SCr >= 0.8 has NO floor applied (effective == raw)', () {
      const normalAndHighScrs = [0.8, 0.9, 1.2, 1.8, 3.5];
      const age = 75.0;
      const weight = 70.0;

      for (final scr in normalAndHighScrs) {
        final res =
            SpecializedDosingCalculator.calculateCockcroftGaultWithElderlyFloor(
          ageYears: age,
          weightKg: weight,
          serumCreatinineMgDl: scr,
          isMale: true,
        );

        expect(res['floorApplied'], isFalse);
        expect(res['effectiveScr'], equals(scr));
        expect(res['effectiveCrCl'], equals(res['rawCrCl']));

        final expected = oracleCockcroftGault(
          age: age,
          weight: weight,
          scr: scr,
          isMale: true,
        );
        expect(res['effectiveCrCl'], closeTo(expected, 1e-9));
      }
    });

    test('4.3 Young adult (age < 65) with low SCr (0.5) has NO floor applied', () {
      // Sarcopenia floor is strictly restricted to elderly (>= 65 yo)
      const youngAges = [18.0, 30.0, 50.0, 64.9];
      const weight = 65.0;
      const scr = 0.5;

      for (final age in youngAges) {
        final res =
            SpecializedDosingCalculator.calculateCockcroftGaultWithElderlyFloor(
          ageYears: age,
          weightKg: weight,
          serumCreatinineMgDl: scr,
          isMale: false,
        );

        expect(res['floorApplied'], isFalse,
            reason: 'Floor must not apply to age $age');
        expect(res['effectiveScr'], equals(scr));
        expect(res['effectiveCrCl'], equals(res['rawCrCl']));
      }
    });
  });

  group('Challenger M13.5: High-Alert Vasoactive Infusion Engine & Rule 5 Policy', () {
    test('5.1 Standard concentration mappings across all vasoactive drugs', () {
      // Norepinephrine: 16 (single), 32 (double)
      expect(
        SpecializedDosingCalculator.getStandardConcentrationMcgPerMl(
          drug: VasoactiveDrug.norepinephrine,
          dilution: VasoactiveDilution.singleStrength,
        ),
        equals(16.0),
      );
      expect(
        SpecializedDosingCalculator.getStandardConcentrationMcgPerMl(
          drug: VasoactiveDrug.norepinephrine,
          dilution: VasoactiveDilution.doubleStrength,
        ),
        equals(32.0),
      );

      // Epinephrine: 16 (single), 32 (double)
      expect(
        SpecializedDosingCalculator.getStandardConcentrationMcgPerMl(
          drug: VasoactiveDrug.epinephrine,
          dilution: VasoactiveDilution.singleStrength,
        ),
        equals(16.0),
      );
      expect(
        SpecializedDosingCalculator.getStandardConcentrationMcgPerMl(
          drug: VasoactiveDrug.epinephrine,
          dilution: VasoactiveDilution.doubleStrength,
        ),
        equals(32.0),
      );

      // Dopamine: 1600 (single), 3200 (double)
      expect(
        SpecializedDosingCalculator.getStandardConcentrationMcgPerMl(
          drug: VasoactiveDrug.dopamine,
          dilution: VasoactiveDilution.singleStrength,
        ),
        equals(1600.0),
      );
      expect(
        SpecializedDosingCalculator.getStandardConcentrationMcgPerMl(
          drug: VasoactiveDrug.dopamine,
          dilution: VasoactiveDilution.doubleStrength,
        ),
        equals(3200.0),
      );

      // Dobutamine: 1000 (single), 2000 (double)
      expect(
        SpecializedDosingCalculator.getStandardConcentrationMcgPerMl(
          drug: VasoactiveDrug.dobutamine,
          dilution: VasoactiveDilution.singleStrength,
        ),
        equals(1000.0),
      );
      expect(
        SpecializedDosingCalculator.getStandardConcentrationMcgPerMl(
          drug: VasoactiveDrug.dobutamine,
          dilution: VasoactiveDilution.doubleStrength,
        ),
        equals(2000.0),
      );
    });

    test('5.2 Independent oracle infusion rate cross-verification (weight-based & absolute)', () {
      // Norepinephrine weight-based: 0.15 mcg/kg/min, 70 kg, 16 mcg/mL
      final norepiRes = SpecializedDosingCalculator.calculateVasoactiveInfusion(
        drug: VasoactiveDrug.norepinephrine,
        orderedDose: 0.15,
        doseUnit: 'mcg/kg/min',
        patientWeightKg: 70.0,
      );
      final expNorepiRate = oracleVasoactiveRateWeightBased(
        doseMcgKgMin: 0.15,
        weightKg: 70.0,
        concMcgMl: 16.0,
      );
      expect(norepiRes.pumpRateMlPerHr, closeTo(expNorepiRate, 1e-9));
      expect(norepiRes.isCeilingExceeded, isFalse);

      // Dopamine absolute: 400 mcg/min, 80 kg, 1600 mcg/mL
      final dopaRes = SpecializedDosingCalculator.calculateVasoactiveInfusion(
        drug: VasoactiveDrug.dopamine,
        orderedDose: 400.0,
        doseUnit: 'mcg/min',
        patientWeightKg: 80.0,
      );
      final expDopaRate = oracleVasoactiveRateAbsolute(
        doseMcgMin: 400.0,
        concMcgMl: 1600.0,
      );
      expect(dopaRes.pumpRateMlPerHr, closeTo(expDopaRate, 1e-9));
      expect(dopaRes.deliveredMcgKgMin, equals(400.0 / 80.0)); // 5 mcg/kg/min
      expect(dopaRes.isCeilingExceeded, isFalse);
    });

    test('5.3 Rule 5: Non-blocking overdose policy preserves pump rate on titration ceiling breach', () {
      final override = ClinicalOverrideJustification(
        clinicianId: 'MD-ICU-402',
        justificationCategory: 'Refractory septic shock after fluid resuscitation',
        clinicalNotes: 'Targeting MAP >= 65 mmHg on dual vasopressors',
        timestamp: DateTime(2026, 11, 7, 10, 0),
        deliveredDose: 1.5,
        rateUnit: 'mcg/kg/min',
      );

      // Norepinephrine ordered at 1.5 mcg/kg/min (ceiling = 1.0 mcg/kg/min)
      final massiveNorepi =
          SpecializedDosingCalculator.calculateVasoactiveInfusion(
        drug: VasoactiveDrug.norepinephrine,
        orderedDose: 1.5,
        doseUnit: 'mcg/kg/min',
        patientWeightKg: 75.0,
        overrideJustification: override,
      );

      // Rate MUST NOT be zeroed, clamped, or suppressed
      final expectedRate = oracleVasoactiveRateWeightBased(
        doseMcgKgMin: 1.5,
        weightKg: 75.0,
        concMcgMl: 16.0,
      );
      expect(massiveNorepi.pumpRateMlPerHr, closeTo(expectedRate, 1e-9));
      expect(massiveNorepi.isCeilingExceeded, isTrue);
      expect(massiveNorepi.ceilingThreshold, equals(1.0));
      expect(massiveNorepi.warningMessage, contains('TITRATION CEILING EXCEEDED'));
      expect(massiveNorepi.warningMessage, contains('Rule 5 non-blocking active'));
      expect(massiveNorepi.overrideJustification, isNotNull);
      expect(massiveNorepi.overrideJustification!.clinicianId, equals('MD-ICU-402'));
    });

    test('5.4 Dopamine/Dobutamine 20.0 mcg/kg/min ceiling check', () {
      final highDopamine =
          SpecializedDosingCalculator.calculateVasoactiveInfusion(
        drug: VasoactiveDrug.dopamine,
        orderedDose: 25.0,
        doseUnit: 'mcg/kg/min',
        patientWeightKg: 70.0,
      );
      expect(highDopamine.isCeilingExceeded, isTrue);
      expect(highDopamine.ceilingThreshold, equals(20.0));
      expect(highDopamine.pumpRateMlPerHr, greaterThan(0.0));
    });
  });

  group('Challenger M13.6: Phenytoin Michaelis-Menten & Albumin Correction Stress-Testing', () {
    test('6.1 Capacity saturation guard: Dose >= Vmax prevents zero division and preserves dose', () {
      // Patient 70 kg, Vmax = 7 mg/kg/day = 490 mg/day
      // Order: 500 mg/day (exceeds Vmax 490 mg/day)
      final res = SpecializedDosingCalculator.evaluatePhenytoin(
        orderedDailyDoseMg: 500.0,
        weightKg: 70.0,
        vmaxMgPerKgDay: 7.0,
        kmMgL: 4.0,
      );

      expect(res.isCapacityExceeded, isTrue);
      expect(res.predictedCssMgL, isNull);
      expect(res.isToxic, isTrue);
      expect(res.warningCodes, contains('phenytoinCapacityExceeded'));
      expect(res.clinicalGuidance, contains('CRITICAL SATURATION'));
      expect(res.orderedDailyDoseMg, equals(500.0)); // Preserved per Rule 5
    });

    test('6.2 Sheiner-Tozer vs Winter-Tozer albumin adjustment formulas', () {
      const cObs = 12.0;
      const alb = 2.5;

      // Normal renal function (CrCl >= 20): Sheiner-Tozer
      final sheiner = SpecializedDosingCalculator.evaluatePhenytoin(
        orderedDailyDoseMg: 300.0,
        weightKg: 70.0,
        observedSerumPhenytoinMgL: cObs,
        serumAlbuminGPerDl: alb,
        crclMlMin: 60.0,
      );
      // Independent math: C_adj = 12 / (0.2 * 2.5 + 0.1) = 12 / 0.6 = 20.0 mg/L
      const expSheiner = cObs / (0.2 * alb + 0.1);
      expect(sheiner.adjustedCssMgL, closeTo(expSheiner, 1e-9));
      expect(sheiner.isSheinerTozerApplied, isTrue);
      expect(sheiner.isWinterTozerApplied, isFalse);

      // Severe renal failure (CrCl < 20): Winter-Tozer
      final winter = SpecializedDosingCalculator.evaluatePhenytoin(
        orderedDailyDoseMg: 300.0,
        weightKg: 70.0,
        observedSerumPhenytoinMgL: cObs,
        serumAlbuminGPerDl: alb,
        crclMlMin: 15.0,
      );
      // Independent math: C_adj = 12 / (0.1 * 2.5 + 0.1) = 12 / 0.35 ≈ 34.2857 mg/L
      const expWinter = cObs / (0.1 * alb + 0.1);
      expect(winter.adjustedCssMgL, closeTo(expWinter, 1e-9));
      expect(winter.isWinterTozerApplied, isTrue);
      expect(winter.isSheinerTozerApplied, isFalse);
    });

    test('6.3 IV infusion rate ceiling: <= 50 mg/min adult, <= 25 mg/min cardiac/elderly', () {
      // 60 mg/min in standard adult: exceeds 50 mg/min
      final adultRate = SpecializedDosingCalculator.evaluatePhenytoin(
        orderedDailyDoseMg: 300.0,
        weightKg: 70.0,
        ivInfusionRateMgPerMin: 60.0,
        isElderlyOrCardiac: false,
      );
      expect(adultRate.hasIvRateRisk, isTrue);
      expect(adultRate.warningCodes, contains('phenytoinIvRateExceeded'));

      // 30 mg/min in cardiac patient: exceeds 25 mg/min
      final cardiacRate = SpecializedDosingCalculator.evaluatePhenytoin(
        orderedDailyDoseMg: 300.0,
        weightKg: 70.0,
        ivInfusionRateMgPerMin: 30.0,
        isElderlyOrCardiac: true,
      );
      expect(cardiacRate.hasIvRateRisk, isTrue);
      expect(cardiacRate.warningCodes, contains('phenytoinIvRateExceeded'));

      // 20 mg/min in cardiac patient: safe
      final safeCardiac = SpecializedDosingCalculator.evaluatePhenytoin(
        orderedDailyDoseMg: 300.0,
        weightKg: 70.0,
        ivInfusionRateMgPerMin: 20.0,
        isElderlyOrCardiac: true,
      );
      expect(safeCardiac.hasIvRateRisk, isFalse);
    });
  });

  group('Challenger M13.7: Special Population Dosing Weight Oracle', () {
    test('7.1 Devine IBW formula exact concordance for male and female', () {
      // Male 175 cm (68.8976 in): 50 + 2.3 * (68.8976 - 60) ≈ 70.46 kg
      final maleIbw = SpecializedDosingCalculator.calculateDevineIbw(
        heightCm: 175.0,
        isMale: true,
      );
      const heightInches = 175.0 / 2.54;
      const expectedMale = 50.0 + 2.3 * (heightInches - 60.0);
      expect(maleIbw, closeTo(expectedMale, 1e-6));

      // Female 160 cm (62.9921 in): 45.5 + 2.3 * (62.9921 - 60) ≈ 52.38 kg
      final femaleIbw = SpecializedDosingCalculator.calculateDevineIbw(
        heightCm: 160.0,
        isMale: false,
      );
      const femaleInches = 160.0 / 2.54;
      const expectedFemale = 45.5 + 2.3 * (femaleInches - 60.0);
      expect(femaleIbw, closeTo(expectedFemale, 1e-6));
    });

    test('7.2 Mandatory AdjBW 0.4 enforced for aminoglycosides in obesity', () {
      // 120 kg, 175 cm male -> IBW ≈ 70.46 kg. TBW is 170% IBW (BMI = 39.2)
      final weightRes =
          SpecializedDosingCalculator.selectWeightForSpecialPopulations(
        tbwKg: 120.0,
        heightCm: 175.0,
        isMale: true,
        drugType: NtiDrugType.gentamicin,
      );
      expect(weightRes.isObese, isTrue);
      // Selected weight MUST be AdjBW 0.4: IBW + 0.4 * (TBW - IBW)
      final expectedAdjBw = weightRes.ibwKg + 0.4 * (120.0 - weightRes.ibwKg);
      expect(weightRes.selectedWeightKg, closeTo(expectedAdjBw, 1e-6));
      expect(weightRes.rationale, contains('MANDATORY Adjusted Body Weight'));
    });

    test('7.3 Underweight patient (TBW < IBW) enforces TBW across all drugs', () {
      // 40 kg, 170 cm male -> IBW ≈ 67.0 kg. TBW < IBW
      final weightRes =
          SpecializedDosingCalculator.selectWeightForSpecialPopulations(
        tbwKg: 40.0,
        heightCm: 170.0,
        isMale: true,
        drugType: NtiDrugType.amikacin,
      );
      expect(weightRes.isUnderweight, isTrue);
      expect(weightRes.selectedWeightKg, equals(40.0));
      expect(weightRes.rationale, contains('Actual Body Weight enforced'));
    });
  });

  group('Challenger M13.8: NTI Electrolyte Disturbances & Timing Oracles', () {
    test('8.1 Digoxin: hypokalemia, hypomagnesemia, hypercalcemia, and premature alpha-phase sampling', () {
      final safeCheck = SpecializedDosingCalculator.checkNtiSafety(
        drug: NtiDrugType.digoxin,
        serumPotassiumMEqL: 4.2,
        serumMagnesiumMgDl: 2.1,
        serumCalciumMgDl: 9.5,
        hoursPostDoseSampling: 8.0,
      );
      expect(safeCheck.isSafe, isTrue);
      expect(safeCheck.hasPotassiumRisk, isFalse);
      expect(safeCheck.hasDistributionPhaseWarning, isFalse);

      final multiHazardCheck = SpecializedDosingCalculator.checkNtiSafety(
        drug: NtiDrugType.digoxin,
        serumPotassiumMEqL: 3.1, // Hypokalemia (< 3.5)
        serumMagnesiumMgDl: 1.4, // Hypomagnesemia (< 1.7)
        serumCalciumMgDl: 11.2, // Hypercalcemia (> 10.5)
        hoursPostDoseSampling: 3.5, // Alpha distribution phase incomplete (< 6.0h)
      );
      expect(multiHazardCheck.isSafe, isFalse);
      expect(multiHazardCheck.hasPotassiumRisk, isTrue);
      expect(multiHazardCheck.hasMagnesiumRisk, isTrue);
      expect(multiHazardCheck.hasCalciumRisk, isTrue);
      expect(multiHazardCheck.hasDistributionPhaseWarning, isTrue);
      expect(multiHazardCheck.clinicalWarnings.length, equals(4));
    });

    test('8.2 Lithium: hyponatremia and non-12h trough timing alerts', () {
      final lithiumRisk = SpecializedDosingCalculator.checkNtiSafety(
        drug: NtiDrugType.lithium,
        serumSodiumMEqL: 130.0, // Hyponatremia (< 135)
        hoursPostDoseSampling: 8.0, // Not 12h
        hasNsaidOrAceiOrArbOrThiazide: true,
      );
      expect(lithiumRisk.isSafe, isFalse);
      expect(lithiumRisk.hasSodiumRisk, isTrue);
      expect(lithiumRisk.clinicalWarnings.any((w) => w.contains('Hyponatremia')), isTrue);
      expect(lithiumRisk.clinicalWarnings.any((w) => w.contains('12 hours')), isTrue);
      expect(lithiumRisk.clinicalWarnings.any((w) => w.contains('DDI Alert')), isTrue);
    });
  });
}
