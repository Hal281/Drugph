import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/calculators/pk_simulation_engine.dart';
import 'package:drug_dosage_calculator/core/models/pk_model.dart';

void main() {
  group('PkSimulationEngine - 1-Compartment IV Bolus Kinetics', () {
    test('calculates single-dose IV bolus concentration and AUC accurately', () {
      const dose = 1000.0; // mg
      const vd = 50.0; // L
      const ke = 0.05; // hr^-1
      const cl = vd * ke; // 2.5 L/hr
      final tHalf = log(2) / ke; // ~13.86 hr

      const params = PkSimulationParams(
        modelType: PkModelType.oneCompartment,
        route: AdministrationRoute.ivBolus,
        dose: dose,
        tau: 24.0,
        isSteadyState: false,
        numberOfDoses: 1,
        horizonHours: 24.0,
        pk1: PkParameters(vd: vd, ke: ke),
      );

      final result = PkSimulationEngine.simulate(params);

      // C0 = Dose / Vd = 1000 / 50 = 20.0 mg/L
      expect(result.cMax, closeTo(20.0, 1e-6));
      expect(result.tMax, equals(0.0));
      expect(result.ke, closeTo(ke, 1e-9));
      expect(result.tHalf, closeTo(tHalf, 1e-4));

      // At t = 13.8629 (1 half-life), concentration should be half of C0 (10.0 mg/L)
      final halfLifeC = PkSimulationEngine.calculateOneCompBolusConcentration(
        timeHours: tHalf,
        dose: dose,
        tau: 24.0,
        vd: vd,
        ke: ke,
        isSteadyState: false,
      );
      expect(halfLifeC, closeTo(10.0, 1e-4));

      // Single-dose 24h AUC: (Dose / Cl) * (1 - exp(-ke * 24))
      final expectedAuc24 = (dose / cl) * (1.0 - exp(-ke * 24.0));
      expect(result.auc0To24, closeTo(expectedAuc24, 1e-3));
    });

    test('calculates multi-dose steady-state accumulation and peak/trough', () {
      const dose = 1000.0;
      const vd = 50.0;
      const ke = 0.05;
      const tau = 12.0;

      final accFactor = PkSimulationEngine.calculateAccumulationFactor(ke: ke, tau: tau);
      final expDecay = exp(-ke * tau); // exp(-0.6) ~ 0.5488116
      expect(accFactor, closeTo(1.0 / (1.0 - expDecay), 1e-6));

      const params = PkSimulationParams(
        modelType: PkModelType.oneCompartment,
        route: AdministrationRoute.ivBolus,
        dose: dose,
        tau: tau,
        isSteadyState: true,
        horizonHours: 24.0,
        pk1: PkParameters(vd: vd, ke: ke),
      );

      final result = PkSimulationEngine.simulate(params);

      final expectedCMax = (dose / vd) * accFactor; // 20.0 * 2.21628 = 44.3256 mg/L
      final expectedCMin = expectedCMax * expDecay; // 24.3256 mg/L
      expect(result.cMax, closeTo(expectedCMax, 1e-4));
      expect(result.cMin, closeTo(expectedCMin, 1e-4));
      // Peak - Trough at steady state must equal single dose C0 = 20.0 mg/L
      expect(result.cMax - result.cMin, closeTo(dose / vd, 1e-4));

      // Steady state AUC24 = (Daily Dose) / Clearance = (1000 * 24 / 12) / 2.5 = 800.0 mg*hr/L
      expect(result.auc0To24, closeTo(800.0, 1e-6));
    });

    test('finite N-dose simulation matches exact superposition', () {
      const dose = 500.0;
      const vd = 40.0;
      const ke = 0.1;
      const tau = 8.0;

      // Simulate 3 doses
      const params = PkSimulationParams(
        modelType: PkModelType.oneCompartment,
        route: AdministrationRoute.ivBolus,
        dose: dose,
        tau: tau,
        numberOfDoses: 3,
        isSteadyState: false,
        horizonHours: 24.0,
        pk1: PkParameters(vd: vd, ke: ke),
      );

      final result = PkSimulationEngine.simulate(params);

      // Just after dose 1: C = 500 / 40 = 12.5
      final cDose1 = PkSimulationEngine.calculateOneCompBolusConcentration(
        timeHours: 0.0,
        dose: dose,
        tau: tau,
        vd: vd,
        ke: ke,
        isSteadyState: false,
        numberOfDoses: 3,
      );
      expect(cDose1, closeTo(12.5, 1e-5));

      // Just before dose 2 (t = 7.999h): C = 12.5 * exp(-0.1 * 8) = 12.5 * exp(-0.8) ~ 5.616
      final cTrough1 = PkSimulationEngine.calculateOneCompBolusConcentration(
        timeHours: 8.0 - 1e-6,
        dose: dose,
        tau: tau,
        vd: vd,
        ke: ke,
        isSteadyState: false,
        numberOfDoses: 3,
      );
      expect(cTrough1, closeTo(12.5 * exp(-0.8), 1e-3));

      // Just after dose 2 (t = 8.0h): C = 12.5 * exp(-0.8) + 12.5 ~ 18.116
      final cPeak2 = PkSimulationEngine.calculateOneCompBolusConcentration(
        timeHours: 8.0,
        dose: dose,
        tau: tau,
        vd: vd,
        ke: ke,
        isSteadyState: false,
        numberOfDoses: 3,
      );
      expect(cPeak2, closeTo(12.5 * exp(-0.8) + 12.5, 1e-3));
      expect(result.curve.isNotEmpty, isTrue);
    });
  });

  group('PkSimulationEngine - 1-Compartment IV Intermittent Infusion', () {
    test('calculates steady-state intermittent infusion peak and trough (Vancomycin benchmark)', () {
      // Standard clinical Vancomycin regimen: 1000 mg IV q12h over 1 hour
      const dose = 1000.0;
      const tau = 12.0;
      const tInf = 1.0;
      const vd = 49.0; // 0.7 L/kg for 70 kg
      const ke = 0.058; // CrCl ~65 mL/min

      const params = PkSimulationParams(
        modelType: PkModelType.oneCompartment,
        route: AdministrationRoute.ivIntermittentInfusion,
        dose: dose,
        tau: tau,
        tInf: tInf,
        isSteadyState: true,
        horizonHours: 24.0,
        pk1: PkParameters(vd: vd, ke: ke),
      );

      final result = PkSimulationEngine.simulate(params);

      // Verify peak occurs at end of infusion tInf = 1.0 hr
      expect(result.tMax, equals(1.0));

      // Peak formula: (Dose / (tInf * Vd * ke)) * ((1 - exp(-ke * tInf)) / (1 - exp(-ke * tau)))
      const cl = vd * ke;
      final expectedPeak = (dose / (tInf * cl)) * (1.0 - exp(-ke * tInf)) / (1.0 - exp(-ke * tau));
      expect(result.cMax, closeTo(expectedPeak, 1e-5));

      // Trough formula: Cmax * exp(-ke * (tau - tInf))
      final expectedTrough = expectedPeak * exp(-ke * (tau - tInf));
      expect(result.cMin, closeTo(expectedTrough, 1e-5));

      // Steady state AUC24: (1000 * 2) / (49 * 0.058) = 2000 / 2.842 ~ 703.73 mg*hr/L
      expect(result.auc0To24, closeTo(2000.0 / cl, 1e-3));
    });

    test('converges smoothly to IV bolus formula when tInf approaches zero', () {
      const dose = 1000.0;
      const tau = 12.0;
      const vd = 50.0;
      const ke = 0.05;

      // Standard bolus steady-state peak
      final bolusPeak = (dose / vd) / (1.0 - exp(-ke * tau));

      // Infusion with tInf = 0.0001 hr (~0.36 seconds)
      final nearBolusPeak = PkSimulationEngine.calculateSteadyStatePeakInfusion(
        dose: dose,
        tau: tau,
        tInf: 0.0001,
        vd: vd,
        ke: ke,
      );

      // Peak must match within 0.01%
      expect(nearBolusPeak, closeTo(bolusPeak, bolusPeak * 0.0001));

      // Zero-duration infusion (< 1e-6) gracefully routes to bolus
      final zeroInfPeak = PkSimulationEngine.calculateSteadyStatePeakInfusion(
        dose: dose,
        tau: tau,
        tInf: 1e-8,
        vd: vd,
        ke: ke,
      );
      expect(zeroInfPeak, closeTo(bolusPeak, 1e-5));
    });

    test('evaluates concentrations during and after infusion with exact boundary continuity', () {
      const dose = 1000.0;
      const tau = 12.0;
      const tInf = 2.0;
      const vd = 40.0;
      const ke = 0.08;

      // Concentration at t = 2.0h (end of infusion) from inflow formula
      final cAtEndInflow = PkSimulationEngine.calculateOneCompInfusionConcentration(
        timeHours: 2.0,
        dose: dose,
        tau: tau,
        tInf: tInf,
        vd: vd,
        ke: ke,
        isSteadyState: true,
      );

      // Concentration at t = 2.000001h (start of elimination)
      final cAtStartElim = PkSimulationEngine.calculateOneCompInfusionConcentration(
        timeHours: 2.000001,
        dose: dose,
        tau: tau,
        tInf: tInf,
        vd: vd,
        ke: ke,
        isSteadyState: true,
      );

      expect(cAtEndInflow, closeTo(cAtStartElim, 1e-4));
    });
  });

  group('PkSimulationEngine - 1-Compartment Oral Absorption & Singularity', () {
    test('calculates standard Bateman oral curve when ka != ke', () {
      const dose = 500.0;
      const vd = 50.0;
      const ke = 0.1;
      const ka = 1.0;
      const f = 0.8;

      final expectedTMax = log(ka / ke) / (ka - ke); // ln(10) / 0.9 = 2.302585 / 0.9 = 2.5584 hr
      final calculatedTMax = PkSimulationEngine.calculateSingleDoseOralTMax(ka: ka, ke: ke);
      expect(calculatedTMax, closeTo(expectedTMax, 1e-5));

      const params = PkSimulationParams(
        modelType: PkModelType.oneCompartment,
        route: AdministrationRoute.oralExtravascular,
        dose: dose,
        tau: 12.0,
        isSteadyState: false,
        numberOfDoses: 1,
        horizonHours: 24.0,
        pk1: PkParameters(vd: vd, ke: ke, ka: ka, bioavailability: f),
      );

      final result = PkSimulationEngine.simulate(params);

      expect(result.tMax, closeTo(expectedTMax, 1e-4));
      expect(result.cMax, greaterThan(0.0));
      // At t = 0, oral concentration must be exactly 0
      final c0 = PkSimulationEngine.calculateOneCompOralConcentration(
        timeHours: 0.0,
        dose: dose,
        tau: 12.0,
        vd: vd,
        ke: ke,
        ka: ka,
        bioavailability: f,
        isSteadyState: false,
      );
      expect(c0, equals(0.0));
    });

    test('exact analytical L Hopital limit handles ka == ke singularity without 0/0 division', () {
      const dose = 500.0;
      const vd = 50.0;
      const ke = 0.10;
      const ka = 0.10; // Exactly equal!
      const f = 1.0;

      // Analytical L'Hopital single-dose solutions:
      // Tmax = 1 / ke = 1 / 0.10 = 10.0 hours
      final tMax = PkSimulationEngine.calculateSingleDoseOralTMax(ka: ka, ke: ke);
      expect(tMax, closeTo(10.0, 1e-9));

      // Cmax = (F * Dose) / (Vd * e) = 500 / (50 * e) = 10 / e ~ 3.678794 mg/L
      final cMax = PkSimulationEngine.calculateOneCompOralConcentration(
        timeHours: 10.0,
        dose: dose,
        tau: 24.0,
        vd: vd,
        ke: ke,
        ka: ka,
        bioavailability: f,
        isSteadyState: false,
      );
      expect(cMax, closeTo(10.0 / exp(1), 1e-5));

      // Verify smooth continuity: limit as ka -> ke from above and below
      final cNearAbove = PkSimulationEngine.calculateOneCompOralConcentration(
        timeHours: 10.0,
        dose: dose,
        tau: 24.0,
        vd: vd,
        ke: ke,
        ka: ke + 1e-5,
        bioavailability: f,
        isSteadyState: false,
      );
      final cNearBelow = PkSimulationEngine.calculateOneCompOralConcentration(
        timeHours: 10.0,
        dose: dose,
        tau: 24.0,
        vd: vd,
        ke: ke,
        ka: ke - 1e-5,
        bioavailability: f,
        isSteadyState: false,
      );

      expect(cMax, closeTo(cNearAbove, 1e-3));
      expect(cMax, closeTo(cNearBelow, 1e-3));
    });

    test('steady-state oral simulation with ka == ke executes flawlessly', () {
      const dose = 250.0;
      const vd = 25.0;
      const ke = 0.15;
      const ka = 0.15;
      const tau = 12.0;

      const params = PkSimulationParams(
        modelType: PkModelType.oneCompartment,
        route: AdministrationRoute.oralExtravascular,
        dose: dose,
        tau: tau,
        isSteadyState: true,
        horizonHours: 24.0,
        pk1: PkParameters(vd: vd, ke: ke, ka: ka),
      );

      final result = PkSimulationEngine.simulate(params);
      expect(result.cMax, greaterThan(0.0));
      expect(result.cMin, greaterThan(0.0));
      expect(result.auc0To24, closeTo((250.0 * 2.0) / (25.0 * 0.15), 1e-4));
    });

    test('respects oral lag time tLag', () {
      const dose = 500.0;
      const vd = 50.0;
      const ke = 0.1;
      const ka = 1.0;
      const tLag = 1.5; // 1.5 hours delay

      const params = PkSimulationParams(
        modelType: PkModelType.oneCompartment,
        route: AdministrationRoute.oralExtravascular,
        dose: dose,
        tau: 24.0,
        isSteadyState: false,
        numberOfDoses: 1,
        horizonHours: 24.0,
        pk1: PkParameters(vd: vd, ke: ke, ka: ka, tLag: tLag),
      );

      final result = PkSimulationEngine.simulate(params);

      // Before lag time, concentration is 0
      final cBeforeLag = PkSimulationEngine.calculateOneCompOralConcentration(
        timeHours: 1.0,
        dose: dose,
        tau: 24.0,
        vd: vd,
        ke: ke,
        ka: ka,
        tLag: tLag,
        isSteadyState: false,
      );
      expect(cBeforeLag, equals(0.0));

      // Tmax should shift by tLag
      expect(result.tMax, closeTo(tLag + (log(ka / ke) / (ka - ke)), 1e-3));
    });
  });

  group('PkSimulationEngine - 1-Compartment Continuous Infusion', () {
    test('approaches steady-state Css = k0 / Cl accurately', () {
      const k0 = 50.0; // mg/hr
      const vd = 100.0; // L
      const ke = 0.05; // hr^-1
      const cl = vd * ke; // 5.0 L/hr
      const expectedCss = k0 / cl; // 50 / 5 = 10.0 mg/L

      const params = PkSimulationParams(
        modelType: PkModelType.oneCompartment,
        route: AdministrationRoute.continuousInfusion,
        continuousRate: k0,
        cStart: 0.0,
        horizonHours: 120.0, // 120 hours ~ 8.6 half-lives (>99% Css)
        pk1: PkParameters(vd: vd, ke: ke),
      );

      final result = PkSimulationEngine.simulate(params);

      // Steady state AUC24 = 24 * Css = 240.0 mg*hr/L
      expect(result.auc0To24, closeTo(240.0, 1e-6));

      // At 5 half-lives (5 * 13.86h = 69.3h), should reach 1 - exp(-0.05 * 69.3) = 96.88% of Css
      final c5tHalf = PkSimulationEngine.calculateOneCompContinuousConcentration(
        timeHours: 69.3147,
        continuousRate: k0,
        cl: cl,
        ke: ke,
        cStart: 0.0,
      );
      expect(c5tHalf, closeTo(expectedCss * 0.96875, 1e-2));

      // By 120 hours, concentration is practically at steady-state
      final cFinal = result.curve.last.concentrationMgL;
      expect(cFinal, closeTo(expectedCss, 0.05));
    });

    test('superimposes initial baseline concentrationtStart', () {
      const k0 = 50.0;
      const cl = 5.0;
      const ke = 0.05;
      const cStart = 20.0; // Starting higher than Css = 10.0

      final cInitial = PkSimulationEngine.calculateOneCompContinuousConcentration(
        timeHours: 0.0,
        continuousRate: k0,
        cl: cl,
        ke: ke,
        cStart: cStart,
      );
      expect(cInitial, equals(cStart));

      // Decays toward Css = 10.0
      final cLongTime = PkSimulationEngine.calculateOneCompContinuousConcentration(
        timeHours: 100.0,
        continuousRate: k0,
        cl: cl,
        ke: ke,
        cStart: cStart,
      );
      expect(cLongTime, closeTo(10.0, 0.1));
    });
  });

  group('PkSimulationEngine - 2-Compartment Kinetics & Digoxin Alert', () {
    test('derives hybrid alpha and beta macro-constants and biexponential parameters correctly', () {
      // Benchmark 2-compartment parameters:
      const vc = 20.0; // L
      const k10 = 0.20; // hr^-1
      const k12 = 0.50; // hr^-1
      const k21 = 0.30; // hr^-1

      const pk2 = TwoCompartmentParameters(vc: vc, k10: k10, k12: k12, k21: k21);
      pk2.validate();

      // alpha + beta = k10 + k12 + k21 = 0.20 + 0.50 + 0.30 = 1.00
      expect(pk2.alpha + pk2.beta, closeTo(1.00, 1e-9));

      // alpha * beta = k10 * k21 = 0.20 * 0.30 = 0.06
      expect(pk2.alpha * pk2.beta, closeTo(0.06, 1e-9));

      // Cl = Vc * k10 = 20 * 0.20 = 4.0 L/hr
      expect(pk2.clearance, closeTo(4.0, 1e-9));

      // Vp = Vc * (k12 / k21) = 20 * (0.5 / 0.3) = 33.33 L
      expect(pk2.vp, closeTo(20.0 * (0.5 / 0.3), 1e-6));

      // Vss = Vc + Vp = 20 + 33.33 = 53.33 L
      expect(pk2.vss, closeTo(20.0 + 20.0 * (0.5 / 0.3), 1e-6));
    });

    test('2-compartment IV bolus shows biexponential distribution and elimination phases', () {
      const dose = 500.0;
      const vc = 20.0;
      const k10 = 0.20;
      const k12 = 0.50;
      const k21 = 0.30;
      const tau = 12.0;

      const params = PkSimulationParams(
        modelType: PkModelType.twoCompartment,
        route: AdministrationRoute.ivBolus,
        dose: dose,
        tau: tau,
        isSteadyState: true,
        horizonHours: 24.0,
        pk2: TwoCompartmentParameters(vc: vc, k10: k10, k12: k12, k21: k21),
      );

      final result = PkSimulationEngine.simulate(params);

      expect(result.cMax, greaterThan(0.0));
      expect(result.cMin, greaterThan(0.0));
      // AUC24 = (500 * 2) / (20 * 0.20) = 1000 / 4 = 250 mg*hr/L
      expect(result.auc0To24, closeTo(250.0, 1e-4));
    });

    test('triggers Digoxin alpha distribution phase warning when flag is set', () {
      const dose = 0.25; // mg (250 mcg)
      const vc = 100.0; // L
      const k10 = 0.03;
      const k12 = 0.40;
      const k21 = 0.15;

      const params = PkSimulationParams(
        modelType: PkModelType.twoCompartment,
        route: AdministrationRoute.ivBolus,
        dose: dose,
        tau: 24.0,
        isSteadyState: true,
        hasDistributionPhaseWarning: true,
        distributionSafeHours: 6.0,
        pk2: TwoCompartmentParameters(vc: vc, k10: k10, k12: k12, k21: k21),
      );

      final result = PkSimulationEngine.simulate(params);

      expect(result.hasDistributionPhaseWarning, isTrue);
      expect(result.distributionPhaseWarningMessage, contains('Distribution Phase Warning'));
      expect(result.distributionPhaseWarningMessage, contains('6 ชม.'));
    });
  });

  group('PkSimulationEngine - Discrete Sampling & Boundary Pinning', () {
    test('generates between 200 and 500 points with exact pinned boundary coordinates', () {
      const params = PkSimulationParams(
        modelType: PkModelType.oneCompartment,
        route: AdministrationRoute.ivIntermittentInfusion,
        dose: 1000.0,
        tau: 12.0,
        tInf: 1.0,
        isSteadyState: true,
        horizonHours: 24.0,
        pointsPerPhase: 30,
        pk1: PkParameters(vd: 50.0, ke: 0.05),
      );

      final result = PkSimulationEngine.simulate(params);
      final curve = result.curve;

      // Must have high resolution (between 200 and 500 points)
      expect(curve.length, inInclusiveRange(200, 500));

      // Times must be monotonically increasing
      for (var i = 1; i < curve.length; i++) {
        expect(curve[i].timeHours, greaterThan(curve[i - 1].timeHours));
      }

      // Exact boundary pinned points must be present
      final times = curve.map((p) => p.timeHours).toList();
      expect(times.any((t) => (t - 0.0).abs() < 1e-6), isTrue);
      expect(times.any((t) => (t - 1.0).abs() < 1e-6), isTrue); // tInf cycle 1
      expect(times.any((t) => (t - 12.0).abs() < 1e-6), isTrue); // tau
      expect(times.any((t) => (t - 13.0).abs() < 1e-6), isTrue); // tInf cycle 2
      expect(times.any((t) => (t - 24.0).abs() < 1e-6), isTrue); // horizon
    });
  });

  group('PkSimulationEngine - Trapezoidal vs Analytical AUC Consistency', () {
    test('trapezoidal AUC across steady-state cycle matches analytical AUC within 0.5%', () {
      const dose = 1000.0;
      const tau = 12.0;
      const tInf = 1.0;
      const vd = 50.0;
      const ke = 0.06;
      const cl = vd * ke; // 3.0 L/hr

      const params = PkSimulationParams(
        modelType: PkModelType.oneCompartment,
        route: AdministrationRoute.ivIntermittentInfusion,
        dose: dose,
        tau: tau,
        tInf: tInf,
        isSteadyState: true,
        horizonHours: 24.0,
        pointsPerPhase: 50,
        pk1: PkParameters(vd: vd, ke: ke),
      );

      final result = PkSimulationEngine.simulate(params);

      // Analytical steady-state AUC24
      const analyticalAuc24 = (dose * (24.0 / tau)) / cl; // 2000 / 3 = 666.67 mg*hr/L
      expect(result.auc0To24, closeTo(analyticalAuc24, 1e-4));

      // Numerical trapezoidal integration over 24 hours
      final numericalAuc24 = PkSimulationEngine.calculateTrapezoidalAuc(result.curve, upToHour: 24.0);

      // Discrepancy must be under 0.5%
      final discrepancyPercent = ((numericalAuc24 - analyticalAuc24) / analyticalAuc24).abs() * 100.0;
      expect(discrepancyPercent, lessThan(0.5));
    });
  });

  group('PkSimulationEngine - Therapeutic Windows & Rule 5 Non-Blocking Overdose Policy', () {
    test('categorizes concentrations into subTherapeutic, therapeutic, and toxic zones', () {
      const window = TherapeuticWindow(
        mec: 10.0,
        mtc: 20.0,
        targetTroughMin: 10.0,
        targetTroughMax: 15.0,
        targetPeakMin: 20.0,
        targetPeakMax: 35.0,
      );

      expect(window.classify(5.0), equals(TherapeuticZone.subTherapeutic));
      expect(window.classify(15.0), equals(TherapeuticZone.therapeutic));
      expect(window.classify(25.0), equals(TherapeuticZone.toxic));
    });

    test('enforces Rule 5: displays overdose warning without blocking or zeroing calculated curve', () {
      // Overdose case: Dose is 3000 mg (MTC is 20 mg/L)
      const dose = 3000.0;
      const vd = 50.0;
      const ke = 0.05;
      const window = TherapeuticWindow(mec: 10.0, mtc: 20.0);

      const params = PkSimulationParams(
        modelType: PkModelType.oneCompartment,
        route: AdministrationRoute.ivBolus,
        dose: dose,
        tau: 12.0,
        isSteadyState: true,
        therapeuticWindow: window,
        pk1: PkParameters(vd: vd, ke: ke),
      );

      final result = PkSimulationEngine.simulate(params);

      // Rule 5: Peak exceeds MTC
      expect(result.cMax, greaterThan(window.mtc));
      expect(result.hasOverdoseWarning, isTrue);
      expect(result.overdoseWarningMessage, contains('Overdose Warning'));

      // Invariant: Curve and numbers are NOT clamped to 20 or zeroed!
      expect(result.cMax, closeTo((3000.0 / 50.0) / (1.0 - exp(-0.05 * 12.0)), 1e-4));
      expect(result.curve.any((p) => p.concentrationMgL > window.mtc), isTrue);
    });
  });

  group('PkSimulationEngine - Regimen Comparison Engine', () {
    test('computes exact delta metrics between baseline and adjusted regimens', () {
      // Baseline: 1000 mg q12h
      const baselineParams = PkSimulationParams(
        modelType: PkModelType.oneCompartment,
        route: AdministrationRoute.ivIntermittentInfusion,
        dose: 1000.0,
        tau: 12.0,
        tInf: 1.0,
        isSteadyState: true,
        pk1: PkParameters(vd: 50.0, ke: 0.05),
      );
      final baselineResult = PkSimulationEngine.simulate(baselineParams);

      // Adjusted: 1250 mg q12h (+25% dose)
      final adjustedParams = baselineParams.copyWith(dose: 1250.0);
      final adjustedResult = PkSimulationEngine.simulate(adjustedParams);

      final comparison = PkSimulationEngine.compareRegimens(
        baseline: baselineResult,
        adjusted: adjustedResult,
      );

      expect(comparison.deltaCMax, greaterThan(0.0));
      expect(comparison.deltaCMin, greaterThan(0.0));
      expect(comparison.deltaAuc24, greaterThan(0.0));

      // Because clearance is linear and dose increased by 25%, delta AUC24 % change must be exactly +25%
      expect(comparison.percentChangeAuc24, closeTo(25.0, 1e-4));
      expect(comparison.percentChangeCMax, closeTo(25.0, 1e-4));
      expect(comparison.percentChangeCMin, closeTo(25.0, 1e-4));
    });
  });

  group('PkSimulationEngine - Parameter Bounds & NaN/Inf Safety Guards', () {
    test('throws ArgumentError on non-positive or non-finite inputs', () {
      expect(
        () => const PkParameters(vd: -10.0, ke: 0.05).validate(),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => const PkParameters(vd: double.nan, ke: 0.05).validate(),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => const PkParameters(vd: 50.0, ke: -0.05).validate(),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => const PkParameters(vd: 50.0, ke: 0.05, bioavailability: 1.5).validate(),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => const PkSimulationParams(
          route: AdministrationRoute.ivBolus,
          dose: 0.0,
          pk1: PkParameters(vd: 50.0, ke: 0.05),
        ).validate(),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => const PkSimulationParams(
          route: AdministrationRoute.ivIntermittentInfusion,
          dose: 1000.0,
          tau: 1.0,
          tInf: 2.0, // tInf > tau is illegal!
          pk1: PkParameters(vd: 50.0, ke: 0.05),
        ).validate(),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => const TherapeuticWindow(mec: 20.0, mtc: 10.0).validate(), // mtc <= mec is illegal
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('PkSimulationEngine - M12 Remediation: Bolus Boundary Pinning & Singularity Guards', () {
    test('1-Compartment IV Bolus steady-state pins (k*tau - 1e-6, Cmin) and (k*tau, Cmax), and ends at (horizon, Cmin)', () {
      const dose = 600.0;
      const tau = 8.0;
      const vd = 40.0;
      const ke = 0.08;

      const params = PkSimulationParams(
        modelType: PkModelType.oneCompartment,
        route: AdministrationRoute.ivBolus,
        dose: dose,
        tau: tau,
        isSteadyState: true,
        horizonHours: 24.0,
        pk1: PkParameters(vd: vd, ke: ke),
      );

      final result = PkSimulationEngine.simulate(params);

      // 1. Intermediate boundary at t = 8.0h: trough before redose
      final pointBeforeRedose1 = result.curve.firstWhere(
        (p) => (p.timeHours - (8.0 - 1e-6)).abs() < 1e-7,
        orElse: () => throw TestFailure('Trough point at t = 8.0 - 1e-6 must exist'),
      );
      expect(pointBeforeRedose1.concentrationMgL, closeTo(result.cMin, 1e-5));

      // 2. Intermediate boundary at t = 8.0h: peak after redose
      final pointAtRedose1 = result.curve.firstWhere(
        (p) => (p.timeHours - 8.0).abs() < 1e-7,
        orElse: () => throw TestFailure('Peak point at t = 8.0 must exist'),
      );
      expect(pointAtRedose1.concentrationMgL, closeTo(result.cMax, 1e-5));

      // 3. Intermediate boundary at t = 16.0h: trough and peak
      final pointBeforeRedose2 = result.curve.firstWhere(
        (p) => (p.timeHours - (16.0 - 1e-6)).abs() < 1e-7,
        orElse: () => throw TestFailure('Trough point at t = 16.0 - 1e-6 must exist'),
      );
      expect(pointBeforeRedose2.concentrationMgL, closeTo(result.cMin, 1e-5));

      final pointAtRedose2 = result.curve.firstWhere(
        (p) => (p.timeHours - 16.0).abs() < 1e-7,
        orElse: () => throw TestFailure('Peak point at t = 16.0 must exist'),
      );
      expect(pointAtRedose2.concentrationMgL, closeTo(result.cMax, 1e-5));

      // 4. Terminal boundary at t = 24.0h (horizonHours): MUST be Cmin, NOT Cmax!
      final terminalPoint = result.curve.last;
      expect(terminalPoint.timeHours, closeTo(24.0, 1e-7));
      expect(terminalPoint.concentrationMgL, closeTo(result.cMin, 1e-5));
      expect(terminalPoint.concentrationMgL, isNot(closeTo(result.cMax, 1.0)));
    });

    test('IV Bolus tau = 24h numerical trapezoidal AUC matches analytical AUC within < 0.15% (eliminates ramp-up artifact)', () {
      const dose = 500.0;
      const vd = 50.0;
      const ke = 0.065;
      const cl = vd * ke;
      const tau = 24.0;

      const params = PkSimulationParams(
        modelType: PkModelType.oneCompartment,
        route: AdministrationRoute.ivBolus,
        dose: dose,
        tau: tau,
        isSteadyState: true,
        horizonHours: 24.0,
        pk1: PkParameters(vd: vd, ke: ke),
      );

      final result = PkSimulationEngine.simulate(params);

      final expectedAuc24 = PkSimulationEngine.calculateSteadyStateAuc24(
        dose: dose,
        tau: tau,
        clearance: cl,
        bioavailability: 1.0,
      );

      final numericalAuc24 = PkSimulationEngine.calculateTrapezoidalAuc(result.curve, upToHour: 24.0);
      final pctError = ((numericalAuc24 - expectedAuc24).abs() / expectedAuc24) * 100.0;

      // Previously inflated by 0.80% due to boundary ramp-up to Cmax; now < 0.15%
      expect(pctError, lessThan(0.15), reason: 'IV Bolus AUC error must be < 0.15%, observed: $pctError%');
      expect(result.curve.last.concentrationMgL, closeTo(result.cMin, 1e-5));
    });

    test('2-Compartment IV Bolus steady-state boundary evaluation and terminal Cmin', () {
      const dose = 800.0;
      const tau = 12.0;
      const vc = 25.0;
      const k10 = 0.10;
      const k12 = 0.20;
      const k21 = 0.15;
      const cl = vc * k10;

      const pk2 = TwoCompartmentParameters(vc: vc, k10: k10, k12: k12, k21: k21);

      const params = PkSimulationParams(
        modelType: PkModelType.twoCompartment,
        route: AdministrationRoute.ivBolus,
        dose: dose,
        tau: tau,
        isSteadyState: true,
        horizonHours: 24.0,
        pk2: pk2,
      );

      final result = PkSimulationEngine.simulate(params);

      // Intermediate boundary at t = 12.0h
      final trough12 = result.curve.firstWhere((p) => (p.timeHours - (12.0 - 1e-6)).abs() < 1e-7);
      final peak12 = result.curve.firstWhere((p) => (p.timeHours - 12.0).abs() < 1e-7);
      expect(trough12.concentrationMgL, closeTo(result.cMin, 1e-5));
      expect(peak12.concentrationMgL, closeTo(result.cMax, 1e-5));

      // Terminal boundary at t = 24.0h must evaluate to Cmin
      final terminalPoint = result.curve.last;
      expect(terminalPoint.timeHours, closeTo(24.0, 1e-7));
      expect(terminalPoint.concentrationMgL, closeTo(result.cMin, 1e-5));

      // Trapezoidal AUC matches analytical steady-state AUC within < 0.15%
      final expectedAuc24 = PkSimulationEngine.calculateSteadyStateAuc24(
        dose: dose,
        tau: tau,
        clearance: cl,
        bioavailability: 1.0,
      );
      final numericalAuc24 = PkSimulationEngine.calculateTrapezoidalAuc(result.curve, upToHour: 24.0);
      final pctError = ((numericalAuc24 - expectedAuc24).abs() / expectedAuc24) * 100.0;
      expect(pctError, lessThan(0.15));
    });

    test('2-Compartment Oral absorption handles ka == alpha and ka == beta singularities continuously without NaN', () {
      const vc = 30.0;
      const k10 = 0.12;
      const k12 = 0.18;
      const k21 = 0.14;

      const pkBase = TwoCompartmentParameters(vc: vc, k10: k10, k12: k12, k21: k21);
      final alpha = pkBase.alpha;
      final beta = pkBase.beta;

      // Test 1: ka exactly equals alpha
      final pkKaAlpha = TwoCompartmentParameters(vc: vc, k10: k10, k12: k12, k21: k21, ka: alpha);
      final paramsAlpha = PkSimulationParams(
        modelType: PkModelType.twoCompartment,
        route: AdministrationRoute.oralExtravascular,
        dose: 500.0,
        tau: 12.0,
        isSteadyState: true,
        horizonHours: 24.0,
        pk2: pkKaAlpha,
      );
      final resultAlpha = PkSimulationEngine.simulate(paramsAlpha);
      expect(resultAlpha.tMax.isFinite, isTrue);
      expect(resultAlpha.tMax, greaterThan(0.0));
      expect(resultAlpha.cMax.isFinite, isTrue);
      expect(resultAlpha.cMax, greaterThan(0.0));
      expect(resultAlpha.curve.every((p) => p.concentrationMgL.isFinite && !p.concentrationMgL.isNaN), isTrue);

      // Test 2: ka exactly equals beta
      final pkKaBeta = TwoCompartmentParameters(vc: vc, k10: k10, k12: k12, k21: k21, ka: beta);
      final paramsBeta = PkSimulationParams(
        modelType: PkModelType.twoCompartment,
        route: AdministrationRoute.oralExtravascular,
        dose: 500.0,
        tau: 12.0,
        isSteadyState: true,
        horizonHours: 24.0,
        pk2: pkKaBeta,
      );
      final resultBeta = PkSimulationEngine.simulate(paramsBeta);
      expect(resultBeta.tMax.isFinite, isTrue);
      expect(resultBeta.tMax, greaterThan(0.0));
      expect(resultBeta.cMax.isFinite, isTrue);
      expect(resultBeta.cMax, greaterThan(0.0));
      expect(resultBeta.curve.every((p) => p.concentrationMgL.isFinite && !p.concentrationMgL.isNaN), isTrue);
    });
  });
}
