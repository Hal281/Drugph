import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/calculators/pk_simulation_engine.dart';
import 'package:drug_dosage_calculator/core/models/pk_model.dart';

void main() {
  group('PK Challenger M12 Stress Suite - Singularity Sweep (|ka - ke| -> 0)', () {
    const vd = 50.0;
    const dose = 500.0;
    const ke = 0.15; // hr^-1 (t1/2 ~ 4.62 hr)
    const tau = 12.0;
    const f = 1.0;

    // Single-dose oral concentration analytical reference at ka == ke
    double analyticalSingleDoseOralSingular(double t, double keVal) {
      if (t <= 0) return 0.0;
      return (f * dose * keVal / vd) * t * exp(-keVal * t);
    }

    // Steady-state oral concentration analytical reference at ka == ke
    double analyticalSteadyStateOralSingular(double t, double keVal, double tauVal) {
      if (t < 0) return 0.0;
      final tCycle = tauVal > 0 ? (t % tauVal) : t;
      final z = exp(-keVal * tauVal);
      final denom = 1.0 - z;
      final prefactor = (f * dose * keVal) / vd;
      return prefactor * exp(-keVal * tCycle) * ((tCycle / denom) + (tauVal * z / (denom * denom)));
    }

    test('single-dose oral Bateman equation is continuous and finite across |ka - ke| sweep', () {
      final deltas = [
        1.0,
        0.5,
        0.1,
        0.01,
        1e-3,
        1e-4,
        1e-5,
        1.0001e-6,
        0.9999e-6,
        1e-7,
        1e-9,
        1e-12,
        0.0,
        -1e-12,
        -1e-9,
        -1e-7,
        -0.9999e-6,
        -1.0001e-6,
        -1e-5,
        -1e-4,
        -1e-3,
        -0.01,
        -0.1,
      ];

      final testTimes = [0.0, 0.5, 1.0, 2.0, 4.0, 6.0, 8.0, 12.0, 24.0];

      for (final delta in deltas) {
        final ka = ke + delta;
        if (ka <= 0) continue;

        for (final t in testTimes) {
          final c = PkSimulationEngine.calculateOneCompOralConcentration(
            timeHours: t,
            dose: dose,
            tau: tau,
            vd: vd,
            ke: ke,
            ka: ka,
            bioavailability: f,
            isSteadyState: false,
            numberOfDoses: 1,
          );

          expect(c.isNaN, isFalse, reason: 'NaN detected at delta=$delta, t=$t');
          expect(c.isInfinite, isFalse, reason: 'Infinity detected at delta=$delta, t=$t');
          expect(c, greaterThanOrEqualTo(0.0), reason: 'Negative concentration at delta=$delta, t=$t');

          // Check convergence to exact L\'Hopital limit when |delta| <= 1e-4
          if (delta.abs() <= 1e-4 && t > 0) {
            final expected = analyticalSingleDoseOralSingular(t, ke);
            final relError = (c - expected).abs() / expected;
            expect(
              relError,
              lessThan(0.002), // Within 0.2% of analytical singularity limit
              reason: 'Bateman did not converge to L\'Hopital limit at delta=$delta, t=$t: got $c, expected $expected',
            );
          }
        }
      }
    });

    test('steady-state oral Bateman equation handles ka == ke singularity with zero discontinuous jumps', () {
      final deltas = [
        1.0,
        0.1,
        1e-3,
        1e-5,
        1.0001e-6,
        0.9999e-6,
        1e-9,
        0.0,
        -1e-9,
        -0.9999e-6,
        -1.0001e-6,
        -1e-5,
        -1e-3,
        -0.1,
      ];

      for (final delta in deltas) {
        final ka = ke + delta;
        if (ka <= 0) continue;

        final params = PkSimulationParams(
          modelType: PkModelType.oneCompartment,
          route: AdministrationRoute.oralExtravascular,
          dose: dose,
          tau: tau,
          isSteadyState: true,
          horizonHours: 24.0,
          pk1: PkParameters(vd: vd, ke: ke, ka: ka, bioavailability: f),
        );

        final result = PkSimulationEngine.simulate(params);

        expect(result.cMax.isNaN, isFalse);
        expect(result.cMax.isInfinite, isFalse);
        expect(result.cMax, greaterThan(0.0));

        expect(result.cMin.isNaN, isFalse);
        expect(result.cMin.isInfinite, isFalse);
        expect(result.cMin, greaterThan(0.0));

        expect(result.cMax, greaterThan(result.cMin));

        // Theoretical AUC24 at steady-state = (Daily Dose * F) / Cl
        const cl = vd * ke;
        const theoreticalAuc24 = (dose * f * (24.0 / tau)) / cl;
        expect(result.auc0To24, closeTo(theoreticalAuc24, 1e-6));

        // Validate that curve points have no discontinuous step jumps
        for (var i = 1; i < result.curve.length; i++) {
          final pPrev = result.curve[i - 1];
          final pCurr = result.curve[i];
          final dt = pCurr.timeHours - pPrev.timeHours;
          if (dt > 1e-6) {
            final slope = (pCurr.concentrationMgL - pPrev.concentrationMgL).abs() / dt;
            // Physical oral concentration slope cannot exceed (ka * dose / Vd)
            final maxPossibleSlope = (max(ka, ke) * dose / vd) * 5.0;
            expect(
              slope,
              lessThan(maxPossibleSlope),
              reason: 'Discontinuous jump detected between t=${pPrev.timeHours} and t=${pCurr.timeHours} for delta=$delta',
            );
          }
        }

        // Compare with exact analytical steady-state singular curve when |delta| <= 1e-4
        if (delta.abs() <= 1e-4) {
          for (final pt in result.curve) {
            final expected = analyticalSteadyStateOralSingular(pt.timeHours, ke, tau);
            if (expected > 0.05) {
              final relDiff = (pt.concentrationMgL - expected).abs() / expected;
              expect(
                relDiff,
                lessThan(0.005),
                reason: 'Steady-state curve deviated from L\'Hopital at t=${pt.timeHours}, delta=$delta',
              );
            }
          }
        }
      }
    });

    test('2-compartment oral absorption handles ka == alpha and ka == beta singularities', () {
      const twoComp = TwoCompartmentParameters(
        vc: 30.0,
        k10: 0.15,
        k12: 0.40,
        k21: 0.25,
      );

      final alpha = twoComp.alpha;
      final beta = twoComp.beta;

      final testKas = [
        alpha - 0.01,
        alpha - 1e-4,
        alpha - 1e-6,
        alpha,
        alpha + 1e-6,
        alpha + 1e-4,
        alpha + 0.01,
        beta - 0.01,
        beta - 1e-4,
        beta - 1e-6,
        beta,
        beta + 1e-6,
        beta + 1e-4,
        beta + 0.01,
      ];

      for (final ka in testKas) {
        if (ka <= 0) continue;

        for (final t in [0.0, 0.5, 1.0, 2.0, 5.0, 10.0, 24.0]) {
          final cSs = PkSimulationEngine.calculateTwoCompOralConcentration(
            timeHours: t,
            dose: dose,
            tau: tau,
            vc: twoComp.vc,
            k10: twoComp.k10,
            k12: twoComp.k12,
            k21: twoComp.k21,
            ka: ka,
            bioavailability: f,
            isSteadyState: true,
          );

          expect(cSs.isNaN, isFalse, reason: '2-comp oral NaN at ka=$ka, t=$t');
          expect(cSs.isInfinite, isFalse, reason: '2-comp oral Infinity at ka=$ka, t=$t');
          expect(cSs, greaterThanOrEqualTo(0.0));

          final cSingle = PkSimulationEngine.calculateTwoCompOralConcentration(
            timeHours: t,
            dose: dose,
            tau: tau,
            vc: twoComp.vc,
            k10: twoComp.k10,
            k12: twoComp.k12,
            k21: twoComp.k21,
            ka: ka,
            bioavailability: f,
            isSteadyState: false,
            numberOfDoses: 1,
          );

          expect(cSingle.isNaN, isFalse);
          expect(cSingle.isInfinite, isFalse);
          expect(cSingle, greaterThanOrEqualTo(0.0));
        }
      }
    });
  });

  group('PK Challenger M12 Stress Suite - Extreme Parameters Stress Harness', () {
    final extremeClearances = [0.001, 0.01, 0.1, 1.0, 10.0, 50.0, 100.0]; // L/hr
    final extremeVds = [0.01, 0.1, 1.0, 10.0, 50.0, 200.0, 500.0]; // L
    final extremeDoses = [0.001, 0.1, 10.0, 1000.0, 100000.0]; // mg (1 mcg to 100 g)
    final extremeIntervals = [1.0, 4.0, 12.0, 24.0, 168.0]; // hr (1 hr to 1 week)

    test('stress tests combinations of extreme clearances and volumes of distribution in IV bolus', () {
      for (final cl in extremeClearances) {
        for (final vd in extremeVds) {
          final ke = cl / vd;
          if (ke <= 0 || ke.isNaN || !ke.isFinite) continue;

          for (final tau in [1.0, 12.0, 168.0]) {
            const testDose = 100.0;
            final params = PkSimulationParams(
              modelType: PkModelType.oneCompartment,
              route: AdministrationRoute.ivBolus,
              dose: testDose,
              tau: tau,
              isSteadyState: true,
              horizonHours: min(tau * 2.0, 72.0),
              pk1: PkParameters(vd: vd, ke: ke),
            );

            final result = PkSimulationEngine.simulate(params);

            expect(result.cMax.isNaN, isFalse);
            expect(result.cMax.isInfinite, isFalse);
            expect(result.cMax, greaterThan(0.0));

            expect(result.cMin.isNaN, isFalse);
            expect(result.cMin.isInfinite, isFalse);
            expect(result.cMin, greaterThanOrEqualTo(0.0));

            expect(result.cMax, greaterThanOrEqualTo(result.cMin));
            expect(result.auc0To24, greaterThan(0.0));
            expect(result.tHalf, greaterThan(0.0));

            // Check every single point on the sampled curve
            for (final pt in result.curve) {
              expect(pt.concentrationMgL.isNaN, isFalse);
              expect(pt.concentrationMgL.isInfinite, isFalse);
              expect(pt.concentrationMgL, greaterThanOrEqualTo(0.0));
            }
          }
        }
      }
    });

    test('stress tests extreme dose limits: 1 mcg (0.001 mg) to 100 g (100,000 mg)', () {
      const vd = 40.0;
      const ke = 0.08;
      const tau = 12.0;

      for (final dose in extremeDoses) {
        final params = PkSimulationParams(
          modelType: PkModelType.oneCompartment,
          route: AdministrationRoute.ivBolus,
          dose: dose,
          tau: tau,
          isSteadyState: true,
          horizonHours: 24.0,
          pk1: const PkParameters(vd: vd, ke: ke),
          therapeuticWindow: const TherapeuticWindow(mec: 10.0, mtc: 25.0),
        );

        final result = PkSimulationEngine.simulate(params);

        expect(result.cMax.isNaN, isFalse);
        expect(result.cMax, greaterThan(0.0));
        expect(result.cMin, greaterThanOrEqualTo(0.0));

        // When dose is 1 mcg (0.001 mg), Cmax should be on the order of 10^-5 mg/L
        if (dose == 0.001) {
          expect(result.cMax, lessThan(0.001));
          expect(result.hasOverdoseWarning, isFalse);
        }

        // When dose is 100 g (100,000 mg), Cmax will be massively toxic (> 1,000 mg/L)
        if (dose == 100000.0) {
          expect(result.cMax, greaterThan(1000.0));
          // Rule 5: Non-blocking overdose warning MUST be triggered
          expect(result.hasOverdoseWarning, isTrue);
          expect(result.overdoseWarningMessage, isNotNull);
          expect(result.overdoseWarningMessage, contains('Overdose Warning'));
          // Invariant: curve coordinates must NOT be zeroed or suppressed
          expect(result.curve.length, greaterThanOrEqualTo(200));
          expect(result.curve.first.concentrationMgL, closeTo(result.cMax, 1e-4));
        }
      }
    });

    test('stress tests extreme dosing intervals tau from 1 hr to 168 hr (weekly)', () {
      const dose = 500.0;
      const vd = 50.0;
      const ke = 0.05;

      for (final tau in extremeIntervals) {
        final params = PkSimulationParams(
          modelType: PkModelType.oneCompartment,
          route: AdministrationRoute.ivBolus,
          dose: dose,
          tau: tau,
          isSteadyState: true,
          horizonHours: tau,
          pk1: const PkParameters(vd: vd, ke: ke),
        );

        final result = PkSimulationEngine.simulate(params);

        expect(result.cMax, greaterThan(0.0));
        expect(result.cMin, greaterThanOrEqualTo(0.0));
        expect(result.cMax, greaterThanOrEqualTo(result.cMin));

        // At tau = 1 hr (rapid dosing), accumulation is very high
        if (tau == 1.0) {
          final acc = PkSimulationEngine.calculateAccumulationFactor(ke: ke, tau: tau);
          expect(acc, greaterThan(15.0)); // 1 / (1 - exp(-0.05)) ~ 20.5
          expect(result.accumulationFactor, closeTo(acc, 1e-6));
        }

        // At tau = 168 hr (weekly dosing), accumulation is near 1.0 (negligible)
        if (tau == 168.0) {
          expect(result.accumulationFactor, closeTo(1.0, 1e-3));
        }
      }
    });
  });

  group('PK Challenger M12 Stress Suite - Boundary Limits (Tinf -> 0 Convergence to IV Bolus)', () {
    const dose = 1000.0;
    const vd = 50.0;
    const ke = 0.05;
    const tau = 12.0;

    test('1-compartment intermittent infusion converges to IV bolus within 0.05% as Tinf -> 0', () {
      // True IV bolus steady-state benchmarks
      final bolusAcc = PkSimulationEngine.calculateAccumulationFactor(ke: ke, tau: tau);
      final bolusCMaxSs = (dose / vd) * bolusAcc;
      final bolusCMinSs = bolusCMaxSs * exp(-ke * tau);

      // Sweep Tinf from 1 hr down to 10^-9 hr
      final tInfs = [1.0, 0.5, 0.1, 0.01, 0.001, 1e-4, 1e-5, 1e-6, 1e-7, 1e-9];

      for (final tInf in tInfs) {
        final infCMaxSs = PkSimulationEngine.calculateSteadyStatePeakInfusion(
          dose: dose,
          tau: tau,
          tInf: tInf,
          vd: vd,
          ke: ke,
        );

        final infCMinSs = infCMaxSs * exp(-ke * (tau - tInf));

        // For Tinf <= 0.001 hr (3.6 seconds or less), verify convergence within 0.05%
        if (tInf <= 0.001) {
          final cMaxRelError = (infCMaxSs - bolusCMaxSs).abs() / bolusCMaxSs;
          final cMinRelError = (infCMinSs - bolusCMinSs).abs() / bolusCMinSs;

          expect(
            cMaxRelError,
            lessThan(0.0005), // Strictly within 0.05%
            reason: '1-comp Cmax failed 0.05% convergence to bolus at Tinf=$tInf hr (error: ${(cMaxRelError * 100).toStringAsFixed(4)}%)',
          );
          expect(
            cMinRelError,
            lessThan(0.0005),
            reason: '1-comp Cmin failed 0.05% convergence to bolus at Tinf=$tInf hr (error: ${(cMinRelError * 100).toStringAsFixed(4)}%)',
          );
        }

        // Verify full curve evaluation at interior post-infusion times: t in (Tinf, tau)
        for (final t in [1.5, 3.0, 6.0, 9.0, 11.9]) {
          if (t <= tInf) continue;
          final cInf = PkSimulationEngine.calculateOneCompInfusionConcentration(
            timeHours: t,
            dose: dose,
            tau: tau,
            tInf: tInf,
            vd: vd,
            ke: ke,
            isSteadyState: true,
          );
          final cBolus = PkSimulationEngine.calculateOneCompBolusConcentration(
            timeHours: t,
            dose: dose,
            tau: tau,
            vd: vd,
            ke: ke,
            isSteadyState: true,
          );

          if (tInf <= 0.001) {
            final relDiff = (cInf - cBolus).abs() / cBolus;
            expect(
              relDiff,
              lessThan(0.0005),
              reason: 'Curve concentration at t=$t failed 0.05% convergence to bolus at Tinf=$tInf hr',
            );
          }
        }
      }
    });

    test('2-compartment intermittent infusion converges to 2-compartment IV bolus within 0.05% as Tinf -> 0', () {
      const twoComp = TwoCompartmentParameters(
        vc: 25.0,
        k10: 0.10,
        k12: 0.30,
        k21: 0.20,
      );

      final alpha = twoComp.alpha;
      final beta = twoComp.beta;
      final denom = alpha - beta;
      final aCoeff = (dose / twoComp.vc) * ((alpha - twoComp.k21) / denom);
      final bCoeff = (dose / twoComp.vc) * ((twoComp.k21 - beta) / denom);

      // True 2-compartment bolus steady-state peak (t = 0+) and trough (t = tau-)
      final bolusCMaxSs = (aCoeff / (1.0 - exp(-alpha * tau))) + (bCoeff / (1.0 - exp(-beta * tau)));
      final bolusCMinSs = (aCoeff * exp(-alpha * tau) / (1.0 - exp(-alpha * tau))) +
          (bCoeff * exp(-beta * tau) / (1.0 - exp(-beta * tau)));

      final tInfs = [0.1, 0.01, 0.001, 1e-4, 1e-5, 1e-6, 1e-7];

      for (final tInf in tInfs) {
        final cInfPeak = PkSimulationEngine.calculateTwoCompInfusionConcentration(
          timeHours: tInf,
          dose: dose,
          tau: tau,
          tInf: tInf,
          vc: twoComp.vc,
          k10: twoComp.k10,
          k12: twoComp.k12,
          k21: twoComp.k21,
          isSteadyState: true,
        );

        // Evaluate pre-dose trough just prior to next cycle: t = tau - 1e-6 (tau-)
        final cInfTrough = PkSimulationEngine.calculateTwoCompInfusionConcentration(
          timeHours: tau - 1e-6,
          dose: dose,
          tau: tau,
          tInf: tInf,
          vc: twoComp.vc,
          k10: twoComp.k10,
          k12: twoComp.k12,
          k21: twoComp.k21,
          isSteadyState: true,
        );

        if (tInf <= 0.0001) {
          final cMaxRelError = (cInfPeak - bolusCMaxSs).abs() / bolusCMaxSs;
          final cMinRelError = (cInfTrough - bolusCMinSs).abs() / bolusCMinSs;

          expect(
            cMaxRelError,
            lessThan(0.0005), // Within 0.05%
            reason: '2-comp infusion Cmax failed 0.05% convergence to bolus at Tinf=$tInf hr',
          );
          expect(
            cMinRelError,
            lessThan(0.0005), // Within 0.05%
            reason: '2-comp infusion Cmin failed 0.05% convergence to bolus at Tinf=$tInf hr',
          );
        }

        // Test interior points in (Tinf, tau)
        for (final t in [1.0, 2.0, 5.0, 8.0, 11.5]) {
          if (t <= tInf) continue;
          final cInf = PkSimulationEngine.calculateTwoCompInfusionConcentration(
            timeHours: t,
            dose: dose,
            tau: tau,
            tInf: tInf,
            vc: twoComp.vc,
            k10: twoComp.k10,
            k12: twoComp.k12,
            k21: twoComp.k21,
            isSteadyState: true,
          );
          final cBolus = PkSimulationEngine.calculateTwoCompBolusConcentration(
            timeHours: t,
            dose: dose,
            tau: tau,
            vc: twoComp.vc,
            k10: twoComp.k10,
            k12: twoComp.k12,
            k21: twoComp.k21,
            isSteadyState: true,
          );

          if (tInf <= 0.0001) {
            final relDiff = (cInf - cBolus).abs() / cBolus;
            expect(
              relDiff,
              lessThan(0.0005),
              reason: '2-comp curve at t=$t failed 0.05% convergence to bolus at Tinf=$tInf hr',
            );
          }
        }
      }
    });
  });

  group('PK Challenger M12 Stress Suite - Multi-Dose Accumulation Asymptotic Convergence', () {
    const dose = 500.0;
    const vd = 40.0;
    const ke = 0.10; // t1/2 = 6.93 hr
    const tau = 8.0;

    test('1-compartment IV bolus consecutive dose simulation matches steady-state Cmax within 0.1% after >= 10 half-lives', () {
      // Analytical Cmax,ss
      final accFactor = PkSimulationEngine.calculateAccumulationFactor(ke: ke, tau: tau);
      final cMaxSs = (dose / vd) * accFactor;

      // Half-life is ~6.93 hr. Tau = 8 hr.
      // Number of doses to reach 10 half-lives: 10 * 6.93 / 8 ~ 8.66 doses -> N >= 9 doses.
      // At N=12 doses: elapsed time = 11 * 8 = 88 hr (~12.7 half-lives).
      // Relative error = exp(-N * ke * tau) = exp(-12 * 0.8) = exp(-9.6) ~ 6.77e-5 = 0.0068% < 0.1%.

      for (var n = 1; n <= 15; n++) {
        // Peak of n-th dose occurs at t = (n - 1) * tau
        final tPeak = (n - 1) * tau;
        final cMaxN = PkSimulationEngine.calculateOneCompBolusConcentration(
          timeHours: tPeak,
          dose: dose,
          tau: tau,
          vd: vd,
          ke: ke,
          isSteadyState: false,
          numberOfDoses: n,
        );

        final expectedAccumulated = (dose / vd) * ((1.0 - exp(-n * ke * tau)) / (1.0 - exp(-ke * tau)));
        expect(cMaxN, closeTo(expectedAccumulated, 1e-6));

        final relErrorFromSs = (cMaxSs - cMaxN) / cMaxSs;

        if (n >= 10) {
          expect(
            relErrorFromSs,
            lessThan(0.001), // Strictly within 0.1%
            reason: 'Consecutive dose N=$n failed to converge to Cmax,ss within 0.1% (error: ${(relErrorFromSs * 100).toStringAsFixed(4)}%)',
          );
        }
      }
    });

    test('1-compartment IV intermittent infusion matches Cmax,ss within 0.1% after sufficient doses', () {
      const tInf = 1.0;
      final cMaxSs = PkSimulationEngine.calculateSteadyStatePeakInfusion(
        dose: dose,
        tau: tau,
        tInf: tInf,
        vd: vd,
        ke: ke,
      );

      for (var n = 1; n <= 15; n++) {
        final tPeak = (n - 1) * tau + tInf;
        final cMaxN = PkSimulationEngine.calculateOneCompInfusionConcentration(
          timeHours: tPeak,
          dose: dose,
          tau: tau,
          tInf: tInf,
          vd: vd,
          ke: ke,
          isSteadyState: false,
          numberOfDoses: n,
        );

        final relErrorFromSs = (cMaxSs - cMaxN) / cMaxSs;

        if (n >= 10) {
          expect(
            relErrorFromSs,
            lessThan(0.001), // Within 0.1%
            reason: 'Infusion consecutive dose N=$n failed 0.1% convergence to Cmax,ss (error: ${(relErrorFromSs * 100).toStringAsFixed(4)}%)',
          );
        }
      }
    });

    test('2-compartment IV bolus consecutive dose simulation converges to Cmax,ss within 0.1%', () {
      const twoComp = TwoCompartmentParameters(
        vc: 30.0,
        k10: 0.12,
        k12: 0.35,
        k21: 0.20,
      );

      final tHalfBeta = twoComp.eliminationHalfLife;

      final cMaxSs = PkSimulationEngine.calculateTwoCompBolusConcentration(
        timeHours: 0.0,
        dose: dose,
        tau: tau,
        vc: twoComp.vc,
        k10: twoComp.k10,
        k12: twoComp.k12,
        k21: twoComp.k21,
        isSteadyState: true,
      );

      // Number of doses to reach ~10 beta half-lives
      final nRequired = ((10.0 * tHalfBeta) / tau).ceil() + 2;

      final tPeakFinal = (nRequired - 1) * tau;
      final cMaxFinite = PkSimulationEngine.calculateTwoCompBolusConcentration(
        timeHours: tPeakFinal,
        dose: dose,
        tau: tau,
        vc: twoComp.vc,
        k10: twoComp.k10,
        k12: twoComp.k12,
        k21: twoComp.k21,
        isSteadyState: false,
        numberOfDoses: nRequired,
      );

      final relError = (cMaxSs - cMaxFinite).abs() / cMaxSs;
      expect(
        relError,
        lessThan(0.001), // Within 0.1%
        reason: '2-comp bolus consecutive doses N=$nRequired failed 0.1% convergence to steady-state',
      );
    });
  });

  group('PK Challenger M12 Stress Suite - 2-Compartment Characteristic Root Stability & Biexponential Decay Harness', () {
    // 20 distinct parameter combinations spanning clinical drugs and extreme mathematical regimes
    final parameterSets = <Map<String, dynamic>>[
      {'name': '1. Vancomycin (standard NTI)', 'vc': 35.0, 'k10': 0.065, 'k12': 0.15, 'k21': 0.10},
      {'name': '2. Digoxin (extensive tissue distribution)', 'vc': 50.0, 'k10': 0.030, 'k12': 0.80, 'k21': 0.15},
      {'name': '3. Theophylline (moderate distribution)', 'vc': 20.0, 'k10': 0.080, 'k12': 0.25, 'k21': 0.20},
      {'name': '4. Gentamicin (low peripheral affinity)', 'vc': 15.0, 'k10': 0.200, 'k12': 0.05, 'k21': 0.15},
      {'name': '5. Lidocaine (rapid redistribution)', 'vc': 40.0, 'k10': 0.400, 'k12': 1.20, 'k21': 0.60},
      {'name': '6. Fentanyl (highly lipophilic anesthetic)', 'vc': 30.0, 'k10': 0.500, 'k12': 2.50, 'k21': 0.35},
      {'name': '7. Propofol (ultra-fast initial distribution)', 'vc': 25.0, 'k10': 0.600, 'k12': 3.00, 'k21': 0.80},
      {'name': '8. Methotrexate (oncology high-dose)', 'vc': 18.0, 'k10': 0.350, 'k12': 0.45, 'k21': 0.25},
      {'name': '9. Amiodarone-like (deep tissue reservoir)', 'vc': 60.0, 'k10': 0.010, 'k12': 0.90, 'k21': 0.02},
      {'name': '10. Renal failure Vancomycin (near-zero k10)', 'vc': 35.0, 'k10': 0.005, 'k12': 0.12, 'k21': 0.08},
      {'name': '11. Septic hyperclearance (k10 elevated)', 'vc': 45.0, 'k10': 0.800, 'k12': 0.30, 'k21': 0.40},
      {'name': '12. Symmetric rate constants (all equal)', 'vc': 25.0, 'k10': 0.200, 'k12': 0.20, 'k21': 0.20},
      {'name': '13. Minimal peripheral distribution (k12 -> 0)', 'vc': 30.0, 'k10': 0.100, 'k12': 0.001, 'k21': 0.10},
      {'name': '14. Dominant peripheral trapping (k12 >> k21)', 'vc': 20.0, 'k10': 0.050, 'k12': 1.50, 'k21': 0.05},
      {'name': '15. Dominant central return (k21 >> k12)', 'vc': 30.0, 'k10': 0.150, 'k12': 0.05, 'k21': 1.50},
      {'name': '16. Rapid kinetics regime (high k)', 'vc': 10.0, 'k10': 5.000, 'k12': 8.00, 'k21': 4.00},
      {'name': '17. Slow kinetics regime (low k)', 'vc': 100.0, 'k10': 0.002, 'k12': 0.008, 'k21': 0.004},
      {'name': '18. Large central volume, low rate constants', 'vc': 250.0, 'k10': 0.015, 'k12': 0.030, 'k21': 0.025},
      {'name': '19. Very small central, huge peripheral volume', 'vc': 2.0, 'k10': 0.100, 'k12': 2.50, 'k21': 0.10},
      {'name': '20. Asymmetric fast distribution, slow release', 'vc': 50.0, 'k10': 0.050, 'k12': 1.00, 'k21': 0.01},
    ];

    test('verifies alpha > beta > 0, Vieta identities, and macro-coefficients across all 20 parameter sets', () {
      expect(parameterSets.length, equals(20));

      for (final p in parameterSets) {
        final name = p['name'] as String;
        final vc = p['vc'] as double;
        final k10 = p['k10'] as double;
        final k12 = p['k12'] as double;
        final k21 = p['k21'] as double;

        final params = TwoCompartmentParameters(
          vc: vc,
          k10: k10,
          k12: k12,
          k21: k21,
        );

        final alpha = params.alpha;
        final beta = params.beta;

        // 1. Root ordering and positivity
        expect(alpha, greaterThan(beta), reason: '$name: alpha must be strictly greater than beta');
        expect(beta, greaterThan(0.0), reason: '$name: beta must be strictly positive');
        expect(alpha.isNaN, isFalse);
        expect(beta.isNaN, isFalse);

        // 2. Vieta\'s formulas (sum and product of roots)
        final expectedSum = k10 + k12 + k21;
        final expectedProd = k10 * k21;
        expect(alpha + beta, closeTo(expectedSum, 1e-9), reason: '$name: Vieta sum of roots failed');
        expect(alpha * beta, closeTo(expectedProd, 1e-9), reason: '$name: Vieta product of roots failed');

        // 3. Macro-coefficients A and B for IV bolus
        const testDose = 1000.0;
        final denom = alpha - beta;
        final aCoeff = (testDose / vc) * ((alpha - k21) / denom);
        final bCoeff = (testDose / vc) * ((k21 - beta) / denom);

        expect(aCoeff, greaterThan(0.0), reason: '$name: Coefficient A must be strictly positive');
        expect(bCoeff, greaterThan(0.0), reason: '$name: Coefficient B must be strictly positive');
        expect(aCoeff + bCoeff, closeTo(testDose / vc, 1e-9), reason: '$name: A + B must equal C0 = Dose/Vc');

        // 4. Volume relationships: Vss = Vc + Vp > Vc; Vbeta = Cl / beta >= Vss
        final vp = params.vp;
        final vss = params.vss;
        final vBeta = params.vBeta;
        expect(vp, greaterThanOrEqualTo(0.0));
        expect(vss, greaterThanOrEqualTo(vc));
        expect(vBeta, greaterThanOrEqualTo(vss - 1e-6), reason: '$name: V_beta ($vBeta) must be >= Vss ($vss)');

        // 5. Total AUC conservation: AUC_0-inf = A/alpha + B/beta == Dose / Clearance
        final aucFromRoots = (aCoeff / alpha) + (bCoeff / beta);
        final aucFromClearance = testDose / params.clearance;
        expect(aucFromRoots, closeTo(aucFromClearance, 1e-7), reason: '$name: AUC conservation failed');
      }
    });

    test('verifies strict monotonic decay and strict convexity of 2-compartment concentration across all 20 sets', () {
      for (final p in parameterSets) {
        final name = p['name'] as String;
        final vc = p['vc'] as double;
        final k10 = p['k10'] as double;
        final k12 = p['k12'] as double;
        final k21 = p['k21'] as double;

        final twoComp = TwoCompartmentParameters(
          vc: vc,
          k10: k10,
          k12: k12,
          k21: k21,
        );

        final tHalfBeta = twoComp.eliminationHalfLife;
        const testDose = 1000.0;
        const numSamples = 60;
        final dt = (3.0 * tHalfBeta) / numSamples;

        final concentrations = <double>[];
        for (var i = 0; i <= numSamples; i++) {
          final t = i * dt;
          final c = PkSimulationEngine.calculateTwoCompBolusConcentration(
            timeHours: t,
            dose: testDose,
            tau: 24.0,
            vc: vc,
            k10: k10,
            k12: k12,
            k21: k21,
            isSteadyState: false,
            numberOfDoses: 1,
          );
          concentrations.add(c);
        }

        // Strict monotonicity: C(t_i) > C(t_{i+1}) > 0
        for (var i = 0; i < concentrations.length - 1; i++) {
          expect(
            concentrations[i],
            greaterThan(concentrations[i + 1]),
            reason: '$name: Monotonic decay violated at sample $i (t=${i * dt})',
          );
          expect(concentrations[i], greaterThan(0.0));
        }

        // Strict convexity: second difference > 0 (decay rate is slowing down)
        for (var i = 1; i < concentrations.length - 1; i++) {
          final secondDiff = concentrations[i - 1] - 2.0 * concentrations[i] + concentrations[i + 1];
          expect(
            secondDiff,
            greaterThan(0.0),
            reason: '$name: Convexity violated at sample $i (t=${i * dt})',
          );
        }
      }
    });

    test('verifies trapezoidal AUC numerical integration matches analytical integral within 0.2% for biexponential curves with phase-resolved grid', () {
      for (final p in parameterSets.take(5)) {
        final name = p['name'] as String;
        final vc = p['vc'] as double;
        final k10 = p['k10'] as double;
        final k12 = p['k12'] as double;
        final k21 = p['k21'] as double;

        final twoComp = TwoCompartmentParameters(
          vc: vc,
          k10: k10,
          k12: k12,
          k21: k21,
        );

        final tHalfAlpha = twoComp.distributionHalfLife;
        final tHalfBeta = twoComp.eliminationHalfLife;
        const testDose = 1000.0;
        final horizon = 10.0 * tHalfBeta;

        final grid = <PkDataPoint>[];
        // Phase 1: High-resolution distribution alpha phase (0 <= t <= 5 * tHalfAlpha)
        const alphaSamples = 100;
        final dtAlpha = (5.0 * tHalfAlpha) / alphaSamples;
        for (var i = 0; i <= alphaSamples; i++) {
          final t = i * dtAlpha;
          final c = PkSimulationEngine.calculateTwoCompBolusConcentration(
            timeHours: t,
            dose: testDose,
            tau: horizon,
            vc: vc,
            k10: k10,
            k12: k12,
            k21: k21,
            isSteadyState: false,
            numberOfDoses: 1,
          );
          grid.add(PkDataPoint(timeHours: t, concentrationMgL: c));
        }

        // Phase 2: Terminal elimination beta phase (5 * tHalfAlpha < t <= 10 * tHalfBeta)
        const betaSamples = 200;
        final tStartBeta = 5.0 * tHalfAlpha;
        final dtBeta = (horizon - tStartBeta) / betaSamples;
        for (var i = 1; i <= betaSamples; i++) {
          final t = tStartBeta + (i * dtBeta);
          final c = PkSimulationEngine.calculateTwoCompBolusConcentration(
            timeHours: t,
            dose: testDose,
            tau: horizon,
            vc: vc,
            k10: k10,
            k12: k12,
            k21: k21,
            isSteadyState: false,
            numberOfDoses: 1,
          );
          grid.add(PkDataPoint(timeHours: t, concentrationMgL: c));
        }

        final numericalAuc = PkSimulationEngine.calculateTrapezoidalAuc(grid);
        final analyticalAucTotal = testDose / twoComp.clearance;

        // Over 10 beta half-lives, remaining AUC is < exp(-10 * ln2) ~ 0.097%
        final relError = (numericalAuc - analyticalAucTotal).abs() / analyticalAucTotal;
        expect(
          relError,
          lessThan(0.002), // Within 0.2%
          reason: '$name: Trapezoidal AUC deviated from analytical AUC: got $numericalAuc, expected $analyticalAucTotal',
        );
      }
    });
  });

  group('PK Challenger M12 Stress Suite - Continuous Infusion & High-Alert NTI Safety Harness', () {
    test('continuous zero-order infusion approaches steady state Css = k0 / Cl within 0.1% after >= 7 half-lives', () {
      const cl = 3.5; // L/hr
      const vd = 50.0; // L
      const ke = cl / vd; // 0.07 hr^-1
      final tHalf = log(2) / ke; // ~9.9 hr
      const k0 = 35.0; // mg/hr -> Css = 10 mg/L

      const cSs = k0 / cl;

      // At t = 7 half-lives (~69.3 hr):
      // C(t) = Css * (1 - exp(-7 * ln2)) = Css * (1 - 1/128) = Css * 0.9921875
      // At t = 10 half-lives: error is 1/1024 ~ 0.098% < 0.1%
      final t10HalfLives = 10.0 * tHalf;

      final params = PkSimulationParams(
        modelType: PkModelType.oneCompartment,
        route: AdministrationRoute.continuousInfusion,
        continuousRate: k0,
        horizonHours: t10HalfLives,
        pk1: const PkParameters(vd: vd, ke: ke),
      );

      final result = PkSimulationEngine.simulate(params);

      final finalPoint = result.curve.last;
      expect(finalPoint.timeHours, closeTo(t10HalfLives, 1e-6));

      final relDiffFromCss = (finalPoint.concentrationMgL - cSs).abs() / cSs;
      expect(
        relDiffFromCss,
        lessThan(0.001), // Strictly within 0.1%
        reason: 'Continuous infusion did not reach within 0.1% of Css after 10 half-lives',
      );
    });

    test('NTI Digoxin distribution phase hazard alert triggers without suppressing mathematical results', () {
      const digoxinParams = PkSimulationParams(
        modelType: PkModelType.twoCompartment,
        route: AdministrationRoute.ivBolus,
        dose: 0.5, // 500 mcg = 0.5 mg
        tau: 24.0,
        isSteadyState: true,
        horizonHours: 24.0,
        hasDistributionPhaseWarning: true,
        distributionSafeHours: 6.0,
        pk2: TwoCompartmentParameters(
          vc: 50.0,
          k10: 0.03,
          k12: 0.80,
          k21: 0.15,
        ),
        therapeuticWindow: TherapeuticWindow(
          mec: 0.0005, // 0.5 mcg/L = 0.0005 mg/L
          mtc: 0.0020, // 2.0 mcg/L = 0.0020 mg/L
        ),
      );

      final result = PkSimulationEngine.simulate(digoxinParams);

      expect(result.hasDistributionPhaseWarning, isTrue);
      expect(result.distributionPhaseWarningMessage, isNotNull);
      expect(result.distributionPhaseWarningMessage, contains('Distribution Phase Warning'));
      expect(result.distributionPhaseWarningMessage, contains('6 ชม.'));

      // Invariant: curves and calculations remain completely accessible
      expect(result.cMax, greaterThan(0.0));
      expect(result.cMin, greaterThan(0.0));
      expect(result.curve.length, greaterThanOrEqualTo(200));
    });
  });
}
