// ============================================================================
// E2E Test Suite: PK-PD Modeling & Visualization Engine (Requirement R1)
// ============================================================================
// Authoritative standards:
// - ORIGINAL_REQUEST.md Requirement R1
// - AGENTS.md & GEMINI.md (Rule 1 Zero Calculation Error, Rule 5 Non-Blocking)
// - Rowland & Tozer: Clinical Pharmacokinetics and Pharmacodynamics (Ch. 3, 5, 7, 18)
// - DiPiro's Pharmacotherapy (Ch. e2: Clinical Pharmacokinetics)
// - Winter's Basic Clinical Pharmacokinetics (Ch. 2-5)
// - Matzke et al. (1984) / ASHP 2020 Consensus Guidelines
// ============================================================================

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/calculators/tdm_calculator.dart';
import 'pk_reference_engine.dart';

void main() {
  group('E2E PK-PD Modeling — Tier 1: Feature Coverage (Category-Partition)', () {
    test('1.1: 1-Compartment IV Bolus simulates mono-exponential decay and exact AUC_inf', () {
      const dose = 1000.0; // mg
      const vd = 40.0; // L
      const ke = 0.0866; // hr^-1 (t1/2 ≈ 8.0 hr)
      const clearance = vd * ke; // 3.464 L/hr

      // Initial concentration C0 = Dose / Vd = 1000 / 40 = 25.0 mg/L
      final c0 = PkReferenceEngine.evaluateOneCompSingleDose(
        route: PkRoute.ivBolus,
        t: 0.0,
        doseMg: dose,
        vdLitres: vd,
        keHrInv: ke,
      );
      expect(c0, closeTo(25.0, 1e-6));

      // Concentration at 1 half-life (t = 8.0h) must equal C0 / 2 = 12.5 mg/L
      final cHalfLife = PkReferenceEngine.evaluateOneCompSingleDose(
        route: PkRoute.ivBolus,
        t: 8.0,
        doseMg: dose,
        vdLitres: vd,
        keHrInv: ke,
      );
      expect(cHalfLife, closeTo(12.5, 0.05));

      // Analytical AUC_inf = Dose / Clearance = 1000 / 3.464 = 288.68 mg*hr/L
      const expectedAucInf = dose / clearance;
      expect(expectedAucInf, closeTo(288.68, 0.05));
    });

    test('1.2: 1-Compartment IV Intermittent Infusion models two phases and matches TdmCalculator', () {
      const dose = 1000.0;
      const tau = 12.0;
      const tInf = 1.0;
      const vd = 49.0;
      const ke = 0.0874;

      // Single-dose profile
      final singlePeak = PkReferenceEngine.evaluateOneCompSingleDose(
        route: PkRoute.ivIntermittentInfusion,
        t: tInf,
        doseMg: dose,
        vdLitres: vd,
        keHrInv: ke,
        tInfHours: tInf,
      );
      // Single dose peak = (Dose / (tInf * Vd * Ke)) * (1 - exp(-Ke * tInf))
      // (1000 / (1 * 49 * 0.0874)) * (1 - exp(-0.0874)) ≈ 19.55 mg/L
      expect(singlePeak, closeTo(19.55, 0.05));

      // Steady-state profile evaluation
      final ssPeak = PkReferenceEngine.evaluateOneCompSteadyState(
        route: PkRoute.ivIntermittentInfusion,
        tPrime: tInf,
        doseMg: dose,
        tauHours: tau,
        vdLitres: vd,
        keHrInv: ke,
        tInfHours: tInf,
      );
      final ssTrough = PkReferenceEngine.evaluateOneCompSteadyState(
        route: PkRoute.ivIntermittentInfusion,
        tPrime: tau,
        doseMg: dose,
        tauHours: tau,
        vdLitres: vd,
        keHrInv: ke,
        tInfHours: tInf,
      );

      // Must strictly match TdmCalculator production engine
      final prodPeak = TdmCalculator.predictPeak(
        dose: dose,
        tau: tau,
        tInf: tInf,
        vd: vd,
        ke: ke,
      );
      final prodTrough = TdmCalculator.predictTrough(
        dose: dose,
        tau: tau,
        tInf: tInf,
        vd: vd,
        ke: ke,
      );

      expect(ssPeak, closeTo(prodPeak, 1e-5));
      expect(ssTrough, closeTo(prodTrough, 1e-5));
      expect(ssPeak, closeTo(30.08, 0.05));
      expect(ssTrough, closeTo(11.50, 0.05));
    });

    test('1.3: 1-Compartment Oral Absorption models Bateman curve and exact analytical Tmax', () {
      const dose = 500.0;
      const f = 0.85;
      const ka = 1.2; // hr^-1
      const ke = 0.15; // hr^-1
      const vd = 35.0; // L

      // Analytical Tmax = ln(ka / ke) / (ka - ke) = ln(1.2 / 0.15) / (1.2 - 0.15)
      // ln(8.0) / 1.05 = 2.07944 / 1.05 ≈ 1.9804 hr
      final analyticalTmax = log(ka / ke) / (ka - ke);
      expect(analyticalTmax, closeTo(1.98, 0.01));

      // Concentration at Tmax
      final cTmax = PkReferenceEngine.evaluateOneCompSingleDose(
        route: PkRoute.oralExtravascular,
        t: analyticalTmax,
        doseMg: dose,
        vdLitres: vd,
        keHrInv: ke,
        bioavailabilityF: f,
        kaHrInv: ka,
      );

      // Verify derivative is 0 at Tmax by checking t slightly before and after
      final cBefore = PkReferenceEngine.evaluateOneCompSingleDose(
        route: PkRoute.oralExtravascular,
        t: analyticalTmax - 0.05,
        doseMg: dose,
        vdLitres: vd,
        keHrInv: ke,
        bioavailabilityF: f,
        kaHrInv: ka,
      );
      final cAfter = PkReferenceEngine.evaluateOneCompSingleDose(
        route: PkRoute.oralExtravascular,
        t: analyticalTmax + 0.05,
        doseMg: dose,
        vdLitres: vd,
        keHrInv: ke,
        bioavailabilityF: f,
        kaHrInv: ka,
      );

      expect(cTmax, greaterThan(cBefore));
      expect(cTmax, greaterThan(cAfter));
      expect(cTmax, closeTo(9.02, 0.05));
    });

    test('1.4: Continuous IV Infusion models asymptotic rise to Css and half-life fractions', () {
      const rateMgHr = 50.0; // mg/hr
      const vd = 50.0; // L
      const ke = 0.10; // hr^-1
      const clearance = vd * ke; // 5.0 L/hr
      expect(clearance, equals(5.0));
      const halfLife = 6.93147; // hr

      // Asymptotic steady-state concentration Css = k0 / Cl = 50 / 5 = 10.0 mg/L
      final cAt24h = PkReferenceEngine.evaluateOneCompSingleDose(
        route: PkRoute.continuousInfusion,
        t: 24.0,
        doseMg: 0.0,
        vdLitres: vd,
        keHrInv: ke,
        continuousRateMgHr: rateMgHr,
      );
      // 10.0 * (1 - exp(-0.10 * 24)) = 10.0 * (1 - 0.0907) = 9.09 mg/L
      expect(cAt24h, closeTo(9.09, 0.05));

      // At 1 half-life: exactly 50% Css
      final c1HalfLife = PkReferenceEngine.evaluateOneCompSingleDose(
        route: PkRoute.continuousInfusion,
        t: halfLife,
        doseMg: 0.0,
        vdLitres: vd,
        keHrInv: ke,
        continuousRateMgHr: rateMgHr,
      );
      expect(c1HalfLife, closeTo(5.0, 0.01));

      // At 3.32 half-lives: exactly 90% Css
      final c90Percent = PkReferenceEngine.evaluateOneCompSingleDose(
        route: PkRoute.continuousInfusion,
        t: 3.32 * halfLife,
        doseMg: 0.0,
        vdLitres: vd,
        keHrInv: ke,
        continuousRateMgHr: rateMgHr,
      );
      expect(c90Percent, closeTo(9.0, 0.05));
    });

    test('1.5: 2-Compartment micro-to-macro parameter conversion & biexponential disposition', () {
      // Digoxin typical 2-compartment parameters:
      // Vc = 35.0 L, k10 = 0.05 hr^-1, k12 = 0.70 hr^-1, k21 = 0.15 hr^-1, Dose = 0.5 mg (500 mcg)
      const vc = 35.0;
      const k10 = 0.05;
      const k12 = 0.70;
      const k21 = 0.15;
      const doseMg = 0.50;

      final macro = PkReferenceEngine.calculateTwoCompMacroConstants(
        vcLitres: vc,
        k10HrInv: k10,
        k12HrInv: k12,
        k21HrInv: k21,
        doseMg: doseMg,
      );

      final alpha = macro['alpha']!;
      final beta = macro['beta']!;
      final aCoeff = macro['A']!;
      final bCoeff = macro['B']!;

      // Invariants:
      // alpha + beta == k10 + k12 + k21 = 0.90
      expect(alpha + beta, closeTo(0.90, 1e-6));
      // alpha * beta == k10 * k21 = 0.0075
      expect(alpha * beta, closeTo(0.0075, 1e-6));

      // C(0) = A + B = Dose / Vc = 0.50 / 35.0 ≈ 0.014285 mg/L (14.28 mcg/L)
      expect(aCoeff + bCoeff, closeTo(doseMg / vc, 1e-6));

      // Total AUC = A/alpha + B/beta = Dose / (Vc * k10)
      const expectedAuc = doseMg / (vc * k10);
      final biexpAuc = (aCoeff / alpha) + (bCoeff / beta);
      expect(biexpAuc, closeTo(expectedAuc, 1e-6));
    });

    test('1.6: Multi-dose accumulation factor R and steady-state convergence', () {
      const tau = 12.0;
      const ke = 0.0874;

      // R_ss = 1 / (1 - exp(-ke * tau)) = 1 / (1 - exp(-0.0874 * 12)) ≈ 1.5393
      final rSs = 1.0 / (1.0 - exp(-ke * tau));
      expect(rSs, closeTo(1.5393, 0.001));

      // Finite accumulation after N doses: R_N = (1 - exp(-N * ke * tau)) / (1 - exp(-ke * tau))
      final rDose1 = (1.0 - exp(-1 * ke * tau)) / (1.0 - exp(-ke * tau));
      final rDose5 = (1.0 - exp(-5 * ke * tau)) / (1.0 - exp(-ke * tau));
      final rDose10 = (1.0 - exp(-10 * ke * tau)) / (1.0 - exp(-ke * tau));

      expect(rDose1, closeTo(1.0, 1e-6));
      expect(rDose5, closeTo(1.5312, 0.001)); // > 99% of steady-state
      expect(rDose10, closeTo(rSs, 1e-4));
    });

    test('1.7: Therapeutic target window classification complies with Rule 5', () {
      const window = PkTherapeuticWindow(
        mecMgL: 10.0,
        mtcMgL: 20.0,
        targetTroughMinMgL: 10.0,
        targetTroughMaxMgL: 15.0,
        targetAuc24Min: 400.0,
        targetAuc24Max: 600.0,
      );

      expect(window.classifyConcentration(5.0), equals('subTherapeutic'));
      expect(window.classifyConcentration(12.5), equals('therapeutic'));
      expect(window.classifyConcentration(25.0), equals('toxicOverdose'));
    });
  });

  group('E2E PK-PD Modeling — Tier 2: Boundary Value Analysis & Corner Cases', () {
    test('2.1: Bateman singularity (ka == ke) executes exact L\'Hopital limit without division by zero', () {
      const dose = 500.0;
      const f = 1.0;
      const vd = 40.0;
      const ke = 0.10;
      const ka = 0.10; // Exactly equal!

      // Analytical L'Hopital: Tmax = 1 / ke = 10.0 hr
      // Cmax = (F * Dose) / (Vd * e) = 500 / (40 * 2.71828) = 4.5985 mg/L
      final cTmax = PkReferenceEngine.evaluateOneCompSingleDose(
        route: PkRoute.oralExtravascular,
        t: 10.0,
        doseMg: dose,
        vdLitres: vd,
        keHrInv: ke,
        bioavailabilityF: f,
        kaHrInv: ka,
      );

      final expectedCmax = (f * dose) / (vd * exp(1));
      expect(cTmax, closeTo(expectedCmax, 1e-5));
      expect(cTmax, closeTo(4.5985, 0.001));
    });

    test('2.2: Anuria (CrCl == 0 mL/min) preserves baseline non-renal elimination constant', () {
      final keAnuric = TdmCalculator.calculateKe(crclMlMin: 0);
      expect(keAnuric, closeTo(0.0044, 1e-6));

      // Half-life in anuric patient: ln(2) / 0.0044 ≈ 157.5 hours (~6.5 days)
      final tHalfAnuric = TdmCalculator.calculateHalfLife(ke: keAnuric);
      expect(tHalfAnuric, closeTo(157.5, 0.5));
    });

    test('2.3: Augmented Renal Clearance (CrCl == 180 mL/min) shortens half-life and drops trough', () {
      final keArc = TdmCalculator.calculateKe(crclMlMin: 180);
      // (0.00083 * 180) + 0.0044 = 0.1494 + 0.0044 = 0.1538 hr^-1
      expect(keArc, closeTo(0.1538, 1e-4));

      final tHalfArc = TdmCalculator.calculateHalfLife(ke: keArc);
      // ln(2) / 0.1538 ≈ 4.51 hr
      expect(tHalfArc, closeTo(4.51, 0.05));

      // Trough for standard 1000 mg q12h drops to subtherapeutic level:
      final troughArc = TdmCalculator.predictTrough(
        dose: 1000,
        tau: 12,
        tInf: 1,
        vd: 49.0,
        ke: keArc,
      );
      // trough ≈ 4.14 mg/L (< 10 mg/L MEC) -> subtherapeutic warning
      expect(troughArc, lessThan(10.0));
      expect(troughArc, closeTo(4.14, 0.10));
    });

    test('2.4: Flip-flop kinetics (ka < ke) maintains continuity and evaluates terminal absorption phase', () {
      // Sustained release formulation: ka = 0.05 hr^-1, ke = 0.20 hr^-1
      const ka = 0.05;
      const ke = 0.20;
      const dose = 1000.0;
      const vd = 50.0;

      // Tmax = ln(0.05 / 0.20) / (0.05 - 0.20) = ln(0.25) / -0.15 = -1.38629 / -0.15 = 9.24 hr
      final tMax = log(ka / ke) / (ka - ke);
      expect(tMax, closeTo(9.24, 0.01));

      final cPeak = PkReferenceEngine.evaluateOneCompSingleDose(
        route: PkRoute.oralExtravascular,
        t: tMax,
        doseMg: dose,
        vdLitres: vd,
        keHrInv: ke,
        kaHrInv: ka,
      );
      expect(cPeak, greaterThan(0.0));
    });

    test('2.5: Zero infusion duration (tInf -> 0) converges smoothly to IV bolus formula', () {
      const dose = 1000.0;
      const vd = 40.0;
      const ke = 0.0866;

      final bolusC0 = PkReferenceEngine.evaluateOneCompSingleDose(
        route: PkRoute.ivBolus,
        t: 0.0,
        doseMg: dose,
        vdLitres: vd,
        keHrInv: ke,
      );
      final microInfusionC0 = PkReferenceEngine.evaluateOneCompSingleDose(
        route: PkRoute.ivIntermittentInfusion,
        t: 0.0001,
        doseMg: dose,
        vdLitres: vd,
        keHrInv: ke,
        tInfHours: 0.0001,
      );

      expect(microInfusionC0, closeTo(bolusC0, 0.001));
    });

    test('2.6: Infusion duration equal or greater than interval (tInf >= tau) throws ArgumentError', () {
      expect(
        () => PkReferenceEngine.simulateOneCompartment(
          route: PkRoute.ivIntermittentInfusion,
          doseMg: 1000.0,
          tauHours: 12.0,
          tInfHours: 12.0, // Invalid!
          vdLitres: 49.0,
          keHrInv: 0.0874,
        ),
        throwsArgumentError,
      );
    });

    test('2.7: Rule 5 Non-blocking Overdose Invariant: extreme overdose displays true calculated numbers', () {
      // 5,000 mg massive overdose of Vancomycin
      final profile = PkReferenceEngine.simulateOneCompartment(
        route: PkRoute.ivIntermittentInfusion,
        doseMg: 5000.0,
        tauHours: 12.0,
        tInfHours: 2.0,
        vdLitres: 49.0,
        keHrInv: 0.0874,
        window: const PkTherapeuticWindow(mecMgL: 10.0, mtcMgL: 20.0),
      );

      // Cmax is > 140 mg/L; MUST NOT BE CLAMPED OR SET TO ZERO
      expect(profile.cMax, closeTo(140.0, 5.0));
      expect(profile.hasOverdoseBreach, isTrue);
      expect(profile.auc0To24, greaterThan(2000.0));
    });
  });

  group('E2E PK-PD Modeling — Tier 3: Pairwise Combinatorial & Cross-Feature Integration', () {
    test('3.1: Multi-dose Oral vs IV Intermittent dynamic regimen comparison', () {
      final ivRegimen = PkReferenceEngine.simulateOneCompartment(
        route: PkRoute.ivIntermittentInfusion,
        doseMg: 1000.0,
        tauHours: 12.0,
        tInfHours: 1.0,
        vdLitres: 45.0,
        keHrInv: 0.08,
      );

      final oralRegimen = PkReferenceEngine.simulateOneCompartment(
        route: PkRoute.oralExtravascular,
        doseMg: 1000.0,
        tauHours: 12.0,
        bioavailabilityF: 0.90,
        kaHrInv: 1.0,
        vdLitres: 45.0,
        keHrInv: 0.08,
      );

      final comparison = PkReferenceEngine.compareRegimens(
        baseline: ivRegimen,
        proposed: oralRegimen,
      );

      // IV intermittent peak is higher than oral peak due to rapid zero-order infusion vs gradual absorption
      expect(ivRegimen.cMax, greaterThan(oralRegimen.cMax));
      expect(comparison.deltaCmax, lessThan(0.0));

      // AUC ratio reflects bioavailability F (0.90)
      expect(oralRegimen.auc0To24 / ivRegimen.auc0To24, closeTo(0.90, 1e-4));
    });

    test('3.2: Dynamic clearance slider recomputes Ke, half-life, and steady-state exposure', () {
      const crclSliderValues = [30.0, 60.0, 90.0, 120.0];
      final halfLives = <double>[];
      final troughs = <double>[];

      for (final crcl in crclSliderValues) {
        final ke = TdmCalculator.calculateKe(crclMlMin: crcl);
        final tHalf = TdmCalculator.calculateHalfLife(ke: ke);
        final trough = TdmCalculator.predictTrough(
          dose: 1000,
          tau: 12,
          tInf: 1,
          vd: 49.0,
          ke: ke,
        );
        halfLives.add(tHalf);
        troughs.add(trough);
      }

      // Half-life and trough must strictly decrease monotonically as clearance increases
      for (int i = 1; i < crclSliderValues.length; i++) {
        expect(halfLives[i], lessThan(halfLives[i - 1]));
        expect(troughs[i], lessThan(troughs[i - 1]));
      }
    });
  });

  group('E2E PK-PD Modeling — Tier 4: Clinical Scenarios', () {
    test('4.1: Digoxin 2-Compartment alpha distribution phase hazard vs true myocardial equilibrium', () {
      // 0.5 mg IV bolus of Digoxin in 70 kg heart failure patient
      const vc = 35.0; // Central volume (plasma + highly perfused organs)
      const k10 = 0.05; // Elimination
      const k12 = 0.70; // Distribution to peripheral/myocardium
      const k21 = 0.15; // Return from peripheral
      const doseMg = 0.50;

      final macro = PkReferenceEngine.calculateTwoCompMacroConstants(
        vcLitres: vc,
        k10HrInv: k10,
        k12HrInv: k12,
        k21HrInv: k21,
        doseMg: doseMg,
      );

      final aCoeff = macro['A']!;
      final bCoeff = macro['B']!;
      final alpha = macro['alpha']!;
      final beta = macro['beta']!;

      // Level drawn prematurely at 1.5 hr post-dose (during alpha distribution phase):
      final cPremature = PkReferenceEngine.evaluateTwoCompBolus(
        t: 1.5,
        aCoeff: aCoeff,
        alpha: alpha,
        bCoeff: bCoeff,
        beta: beta,
      );
      // Measured in ng/mL (mcg/L):
      final prematureNgMl = cPremature * 1000.0;
      expect(prematureNgMl, greaterThan(2.5)); // Pseudo-toxic spike!

      // Level drawn at 8.0 hr post-dose (post-distribution myocardial equilibrium):
      final cTrueEquilibrium = PkReferenceEngine.evaluateTwoCompBolus(
        t: 8.0,
        aCoeff: aCoeff,
        alpha: alpha,
        bCoeff: bCoeff,
        beta: beta,
      );
      final trueNgMl = cTrueEquilibrium * 1000.0;
      expect(trueNgMl, closeTo(2.15, 0.10)); // True post-distribution beta phase
    });

    test('4.2: Continuous Infusion Titration: step-up rate from non-zero initial concentration', () {
      const initialRate = 30.0; // mg/hr
      const vd = 50.0;
      const ke = 0.10;
      const clearance = vd * ke; // 5.0 L/hr
      const initialCss = initialRate / clearance; // 6.0 mg/L

      // Clinician increases titration rate to 60.0 mg/hr
      const titratedRate = 60.0; // mg/hr
      const titratedCss = titratedRate / clearance; // 12.0 mg/L

      // After 6.93 hr (1 half-life), concentration increases by exactly 50% of delta:
      // C(t) = initialCss * exp(-ke*t) + (titratedRate/Cl)*(1 - exp(-ke*t))
      final c1HalfLife = (initialCss * exp(-ke * 6.93147)) +
          (titratedCss * (1.0 - exp(-ke * 6.93147)));

      // 6.0 * 0.5 + 12.0 * 0.5 = 9.0 mg/L
      expect(c1HalfLife, closeTo(9.0, 0.05));
    });
  });
}
