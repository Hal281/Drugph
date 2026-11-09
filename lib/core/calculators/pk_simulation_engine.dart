import 'dart:math';

import '../models/pk_model.dart';

/// Pure mathematical calculation and simulation engine for Pharmacokinetics & Pharmacodynamics (PK-PD).
///
/// Implements deterministic 1-compartment and 2-compartment modeling across multiple administration routes
/// (IV Bolus, IV Intermittent Infusion, Oral/Extravascular Absorption, and Continuous Infusion),
/// multi-dose accumulation, analytical L'Hôpital limits, discrete boundary-pinned curve generation,
/// therapeutic window categorization, and before/after regimen comparison.
///
/// Designed to comply with:
/// - Ironclad Rule 1 (Zero-Error Calculation Policy)
/// - Ironclad Rule 2 (Strict Evidence-Based Medicine Citations)
/// - Ironclad Rule 5 (Non-Blocking Overdose Policy)
/// - Pure Dart architecture (Zero Flutter UI dependencies; safe for `Isolate.run`)
class PkSimulationEngine {
  const PkSimulationEngine._();

  /// Executes a complete deterministic pharmacokinetic simulation based on [params].
  static PkSimulationResult simulate(PkSimulationParams params) {
    params.validate();

    switch (params.modelType) {
      case PkModelType.oneCompartment:
        return _simulateOneCompartment(params);
      case PkModelType.twoCompartment:
        return _simulateTwoCompartment(params);
    }
  }

  // ===========================================================================
  // 1-COMPARTMENT SIMULATION ENGINE
  // ===========================================================================

  static PkSimulationResult _simulateOneCompartment(PkSimulationParams params) {
    final pk = params.pk1!;
    final vd = pk.vd;
    final ke = pk.ke;
    final cl = pk.clearance;
    final tHalf = pk.eliminationHalfLife;
    final tau = params.tau;
    final dose = params.dose;
    final f = pk.bioavailability;
    final ka = pk.ka;
    final tLag = pk.tLag;
    final tInf = params.tInf;
    final horizon = params.horizonHours;
    final isSteadyState = params.isSteadyState;
    final nDoses = params.numberOfDoses;
    final window = params.therapeuticWindow;

    final accumulationFactor = calculateAccumulationFactor(ke: ke, tau: tau);

    double cMax;
    double cMin;
    double tMax;
    double auc0To24;

    switch (params.route) {
      case AdministrationRoute.ivBolus:
        if (isSteadyState) {
          cMax = (dose / vd) * accumulationFactor;
          cMin = cMax * exp(-ke * tau);
          tMax = 0.0;
          auc0To24 = calculateSteadyStateAuc24(dose: dose, tau: tau, clearance: cl, bioavailability: 1.0);
        } else {
          cMax = dose / vd;
          cMin = (dose / vd) * exp(-ke * (nDoses * tau));
          tMax = 0.0;
          auc0To24 = _calculateFiniteDoseAuc(dose: dose, clearance: cl, nDoses: nDoses, tau: tau, ke: ke, maxHours: 24.0);
        }
        break;

      case AdministrationRoute.ivIntermittentInfusion:
        if (isSteadyState) {
          cMax = calculateSteadyStatePeakInfusion(
            dose: dose,
            tau: tau,
            tInf: tInf,
            vd: vd,
            ke: ke,
          );
          cMin = cMax * exp(-ke * (tau - tInf));
          tMax = tInf;
          auc0To24 = calculateSteadyStateAuc24(dose: dose, tau: tau, clearance: cl, bioavailability: 1.0);
        } else {
          cMax = (dose / (tInf * cl)) * (1.0 - exp(-ke * tInf));
          cMin = cMax * exp(-ke * (tau - tInf));
          tMax = tInf;
          auc0To24 = _calculateFiniteDoseAuc(dose: dose, clearance: cl, nDoses: nDoses, tau: tau, ke: ke, maxHours: 24.0);
        }
        break;

      case AdministrationRoute.oralExtravascular:
        if (isSteadyState) {
          tMax = calculateSteadyStateOralTMax(ka: ka, ke: ke, tau: tau) + tLag;
          cMax = calculateOneCompOralConcentration(
            timeHours: tMax,
            dose: dose,
            tau: tau,
            vd: vd,
            ke: ke,
            ka: ka,
            bioavailability: f,
            tLag: tLag,
            isSteadyState: true,
          );
          cMin = calculateOneCompOralConcentration(
            timeHours: tau,
            dose: dose,
            tau: tau,
            vd: vd,
            ke: ke,
            ka: ka,
            bioavailability: f,
            tLag: tLag,
            isSteadyState: true,
          );
          auc0To24 = calculateSteadyStateAuc24(dose: dose, tau: tau, clearance: cl, bioavailability: f);
        } else {
          tMax = calculateSingleDoseOralTMax(ka: ka, ke: ke) + tLag;
          cMax = calculateOneCompOralConcentration(
            timeHours: tMax,
            dose: dose,
            tau: tau,
            vd: vd,
            ke: ke,
            ka: ka,
            bioavailability: f,
            tLag: tLag,
            isSteadyState: false,
            numberOfDoses: 1,
          );
          cMin = calculateOneCompOralConcentration(
            timeHours: tau,
            dose: dose,
            tau: tau,
            vd: vd,
            ke: ke,
            ka: ka,
            bioavailability: f,
            tLag: tLag,
            isSteadyState: false,
            numberOfDoses: 1,
          );
          auc0To24 = _calculateFiniteDoseAuc(dose: dose * f, clearance: cl, nDoses: nDoses, tau: tau, ke: ke, maxHours: 24.0);
        }
        break;

      case AdministrationRoute.continuousInfusion:
        final k0 = params.continuousRate;
        final cSs = k0 / cl;
        tMax = params.cStart < cSs ? horizon : 0.0;
        cMax = max(params.cStart, calculateOneCompContinuousConcentration(timeHours: horizon, continuousRate: k0, cl: cl, ke: ke, cStart: params.cStart));
        cMin = min(params.cStart, calculateOneCompContinuousConcentration(timeHours: horizon, continuousRate: k0, cl: cl, ke: ke, cStart: params.cStart));
        auc0To24 = 24.0 * cSs;
        break;
    }

    // Generate boundary-pinned sampling grid (200-500 points)
    final timePoints = _generateBoundaryPinnedTimeGrid(
      route: params.route,
      tau: tau,
      tInf: tInf,
      tMax: tMax,
      horizonHours: horizon,
      pointsPerPhase: params.pointsPerPhase,
    );

    final curve = <PkDataPoint>[];
    for (final t in timePoints) {
      double c;
      bool isInfusing = false;

      switch (params.route) {
        case AdministrationRoute.ivBolus:
          final isCycleBoundary = tau > 0 && t > 0 && ((t / tau).round() * tau - t).abs() < 1e-7;
          final isTerminal = (t - horizon).abs() < 1e-7;
          final k = tau > 0 ? (t / tau).round() : 0;
          final hasRedose = isSteadyState || k < nDoses;

          if (isCycleBoundary && hasRedose) {
            if (!isTerminal) {
              final troughT = t - 1e-6;
              final troughC = calculateOneCompBolusConcentration(
                timeHours: t,
                dose: dose,
                tau: tau,
                vd: vd,
                ke: ke,
                isSteadyState: isSteadyState,
                numberOfDoses: nDoses,
                isTroughBoundary: true,
              );
              curve.add(PkDataPoint(
                timeHours: troughT,
                concentrationMgL: max(0.0, troughC),
                isInfusing: false,
                zone: window?.classify(troughC),
              ));
              c = calculateOneCompBolusConcentration(
                timeHours: t,
                dose: dose,
                tau: tau,
                vd: vd,
                ke: ke,
                isSteadyState: isSteadyState,
                numberOfDoses: nDoses,
                isTroughBoundary: false,
              );
            } else {
              c = calculateOneCompBolusConcentration(
                timeHours: t,
                dose: dose,
                tau: tau,
                vd: vd,
                ke: ke,
                isSteadyState: isSteadyState,
                numberOfDoses: nDoses,
                isTroughBoundary: true,
              );
            }
          } else {
            c = calculateOneCompBolusConcentration(
              timeHours: t,
              dose: dose,
              tau: tau,
              vd: vd,
              ke: ke,
              isSteadyState: isSteadyState,
              numberOfDoses: nDoses,
              isTroughBoundary: isCycleBoundary && isTerminal,
            );
          }
          break;

        case AdministrationRoute.ivIntermittentInfusion:
          final localT = tau > 0 ? (t % tau) : t;
          isInfusing = localT <= tInf + 1e-9 && (isSteadyState || (t / tau).floor() < nDoses);
          c = calculateOneCompInfusionConcentration(
            timeHours: t,
            dose: dose,
            tau: tau,
            tInf: tInf,
            vd: vd,
            ke: ke,
            isSteadyState: isSteadyState,
            numberOfDoses: nDoses,
          );
          break;

        case AdministrationRoute.oralExtravascular:
          c = calculateOneCompOralConcentration(
            timeHours: t,
            dose: dose,
            tau: tau,
            vd: vd,
            ke: ke,
            ka: ka,
            bioavailability: f,
            tLag: tLag,
            isSteadyState: isSteadyState,
            numberOfDoses: nDoses,
          );
          break;

        case AdministrationRoute.continuousInfusion:
          isInfusing = true;
          c = calculateOneCompContinuousConcentration(
            timeHours: t,
            continuousRate: params.continuousRate,
            cl: cl,
            ke: ke,
            cStart: params.cStart,
          );
          break;
      }

      final zone = window?.classify(c);
      curve.add(PkDataPoint(
        timeHours: t,
        concentrationMgL: max(0.0, c),
        isInfusing: isInfusing,
        zone: zone,
      ));
    }

    final totalAuc = calculateTrapezoidalAuc(curve);

    // Distribution Phase Warning Check (e.g. Digoxin or Vancomycin)
    bool hasDistWarning = false;
    String? distWarningMsg;
    if (params.hasDistributionPhaseWarning && tMax < params.distributionSafeHours) {
      hasDistWarning = true;
      distWarningMsg =
          '⚠️ คำเตือนช่วงการกระจายตัว (Distribution Phase Warning): ระดับยาอยู่ในระยะกระจายตัว (Alpha Phase, < ${params.distributionSafeHours.toStringAsFixed(1)} ชม.) '
          'ซึ่งสะท้อนความเข้มข้นในเลือดส่วนกลาง ยังไม่สมดุลกับเนื้อเยื่อเป้าหมาย ห้ามเจาะเลือดตรวจหรือปรับลดขนาดยาในช่วงนี้เพราะจะได้ผลสูงลวง (Pseudo-toxicity)';
    }

    // Overdose Rule 5 Check
    final hasOverdose = window != null && cMax > window.mtc;
    final overdoseMsg = hasOverdose
        ? '⚠️ คำเตือน: ขนาดยานี้เกินเกณฑ์สูงสุดที่แนะนำ (Overdose Warning: Cmax ${cMax.toStringAsFixed(2)} mg/L > MTC ${window.mtc.toStringAsFixed(2)} mg/L) — โปรดใช้ดุลยพินิจของแพทย์/เภสัชกรในการให้ยา'
        : null;

    return PkSimulationResult(
      params: params,
      curve: curve,
      cMax: cMax,
      cMin: cMin,
      tMax: tMax,
      auc0To24: auc0To24,
      aucTotal: totalAuc,
      ke: ke,
      tHalf: tHalf,
      accumulationFactor: accumulationFactor,
      hasDistributionPhaseWarning: hasDistWarning,
      distributionPhaseWarningMessage: distWarningMsg,
      hasOverdoseWarning: hasOverdose,
      overdoseWarningMessage: overdoseMsg,
    );
  }

  // ===========================================================================
  // 2-COMPARTMENT SIMULATION ENGINE
  // ===========================================================================

  static PkSimulationResult _simulateTwoCompartment(PkSimulationParams params) {
    final pk = params.pk2!;
    final vc = pk.vc;
    final k10 = pk.k10;
    final k12 = pk.k12;
    final k21 = pk.k21;
    final alpha = pk.alpha;
    final beta = pk.beta;
    final cl = pk.clearance;
    final tHalfBeta = pk.eliminationHalfLife;
    final tau = params.tau;
    final dose = params.dose;
    final f = pk.bioavailability;
    final ka = pk.ka;
    final tInf = params.tInf;
    final horizon = params.horizonHours;
    final isSteadyState = params.isSteadyState;
    final nDoses = params.numberOfDoses;
    final window = params.therapeuticWindow;

    final accumulationFactor = calculateAccumulationFactor(ke: beta, tau: tau);

    // Hybrid macro-coefficients for IV Bolus: C(t) = A*exp(-alpha*t) + B*exp(-beta*t)
    final denomAlphaBeta = alpha - beta;
    final aCoeff = denomAlphaBeta.abs() > 1e-12 ? (dose / vc) * ((alpha - k21) / denomAlphaBeta) : (dose / vc) / 2.0;
    final bCoeff = denomAlphaBeta.abs() > 1e-12 ? (dose / vc) * ((k21 - beta) / denomAlphaBeta) : (dose / vc) / 2.0;

    double cMax;
    double cMin;
    double tMax;
    double auc0To24;

    switch (params.route) {
      case AdministrationRoute.ivBolus:
        if (isSteadyState) {
          cMax = (aCoeff / (1.0 - exp(-alpha * tau))) + (bCoeff / (1.0 - exp(-beta * tau)));
          cMin = (aCoeff * exp(-alpha * tau) / (1.0 - exp(-alpha * tau))) + (bCoeff * exp(-beta * tau) / (1.0 - exp(-beta * tau)));
          tMax = 0.0;
          auc0To24 = calculateSteadyStateAuc24(dose: dose, tau: tau, clearance: cl, bioavailability: 1.0);
        } else {
          cMax = aCoeff + bCoeff;
          cMin = calculateTwoCompBolusConcentration(
            timeHours: tau,
            dose: dose,
            tau: tau,
            vc: vc,
            k10: k10,
            k12: k12,
            k21: k21,
            isSteadyState: false,
            numberOfDoses: 1,
          );
          tMax = 0.0;
          auc0To24 = _calculateFiniteDoseAuc(dose: dose, clearance: cl, nDoses: nDoses, tau: tau, ke: beta, maxHours: 24.0);
        }
        break;

      case AdministrationRoute.ivIntermittentInfusion:
        if (isSteadyState) {
          final aInfSs = (aCoeff / (alpha * tInf)) * ((1.0 - exp(-alpha * tInf)) / (1.0 - exp(-alpha * tau)));
          final bInfSs = (bCoeff / (beta * tInf)) * ((1.0 - exp(-beta * tInf)) / (1.0 - exp(-beta * tau)));
          cMax = aInfSs + bInfSs;
          cMin = (aInfSs * exp(-alpha * (tau - tInf))) + (bInfSs * exp(-beta * (tau - tInf)));
          tMax = tInf;
          auc0To24 = calculateSteadyStateAuc24(dose: dose, tau: tau, clearance: cl, bioavailability: 1.0);
        } else {
          cMax = (aCoeff / (alpha * tInf)) * (1.0 - exp(-alpha * tInf)) + (bCoeff / (beta * tInf)) * (1.0 - exp(-beta * tInf));
          cMin = calculateTwoCompInfusionConcentration(
            timeHours: tau,
            dose: dose,
            tau: tau,
            tInf: tInf,
            vc: vc,
            k10: k10,
            k12: k12,
            k21: k21,
            isSteadyState: false,
            numberOfDoses: 1,
          );
          tMax = tInf;
          auc0To24 = _calculateFiniteDoseAuc(dose: dose, clearance: cl, nDoses: nDoses, tau: tau, ke: beta, maxHours: 24.0);
        }
        break;

      case AdministrationRoute.oralExtravascular:
        // Triexponential 2-compartment oral absorption
        tMax = _estimateTwoCompOralTMax(ka: ka, alpha: alpha, beta: beta, k21: k21);
        if (isSteadyState) {
          cMax = calculateTwoCompOralConcentration(
            timeHours: tMax,
            dose: dose,
            tau: tau,
            vc: vc,
            k10: k10,
            k12: k12,
            k21: k21,
            ka: ka,
            bioavailability: f,
            isSteadyState: true,
          );
          cMin = calculateTwoCompOralConcentration(
            timeHours: tau,
            dose: dose,
            tau: tau,
            vc: vc,
            k10: k10,
            k12: k12,
            k21: k21,
            ka: ka,
            bioavailability: f,
            isSteadyState: true,
          );
          auc0To24 = calculateSteadyStateAuc24(dose: dose, tau: tau, clearance: cl, bioavailability: f);
        } else {
          cMax = calculateTwoCompOralConcentration(
            timeHours: tMax,
            dose: dose,
            tau: tau,
            vc: vc,
            k10: k10,
            k12: k12,
            k21: k21,
            ka: ka,
            bioavailability: f,
            isSteadyState: false,
            numberOfDoses: 1,
          );
          cMin = calculateTwoCompOralConcentration(
            timeHours: tau,
            dose: dose,
            tau: tau,
            vc: vc,
            k10: k10,
            k12: k12,
            k21: k21,
            ka: ka,
            bioavailability: f,
            isSteadyState: false,
            numberOfDoses: 1,
          );
          auc0To24 = _calculateFiniteDoseAuc(dose: dose * f, clearance: cl, nDoses: nDoses, tau: tau, ke: beta, maxHours: 24.0);
        }
        break;

      case AdministrationRoute.continuousInfusion:
        final k0 = params.continuousRate;
        final cSs = k0 / cl;
        tMax = params.cStart < cSs ? horizon : 0.0;
        cMax = max(params.cStart, cSs);
        cMin = min(params.cStart, cSs);
        auc0To24 = 24.0 * cSs;
        break;
    }

    // Generate boundary-pinned sampling grid
    final timePoints = _generateBoundaryPinnedTimeGrid(
      route: params.route,
      tau: tau,
      tInf: tInf,
      tMax: tMax,
      horizonHours: horizon,
      pointsPerPhase: params.pointsPerPhase,
    );

    final curve = <PkDataPoint>[];
    for (final t in timePoints) {
      double c;
      bool isInfusing = false;

      switch (params.route) {
        case AdministrationRoute.ivBolus:
          final isCycleBoundary = tau > 0 && t > 0 && ((t / tau).round() * tau - t).abs() < 1e-7;
          final isTerminal = (t - horizon).abs() < 1e-7;
          final k = tau > 0 ? (t / tau).round() : 0;
          final hasRedose = isSteadyState || k < nDoses;

          if (isCycleBoundary && hasRedose) {
            if (!isTerminal) {
              final troughT = t - 1e-6;
              final troughC = calculateTwoCompBolusConcentration(
                timeHours: t,
                dose: dose,
                tau: tau,
                vc: vc,
                k10: k10,
                k12: k12,
                k21: k21,
                isSteadyState: isSteadyState,
                numberOfDoses: nDoses,
                isTroughBoundary: true,
              );
              curve.add(PkDataPoint(
                timeHours: troughT,
                concentrationMgL: max(0.0, troughC),
                isInfusing: false,
                zone: window?.classify(troughC),
              ));
              c = calculateTwoCompBolusConcentration(
                timeHours: t,
                dose: dose,
                tau: tau,
                vc: vc,
                k10: k10,
                k12: k12,
                k21: k21,
                isSteadyState: isSteadyState,
                numberOfDoses: nDoses,
                isTroughBoundary: false,
              );
            } else {
              c = calculateTwoCompBolusConcentration(
                timeHours: t,
                dose: dose,
                tau: tau,
                vc: vc,
                k10: k10,
                k12: k12,
                k21: k21,
                isSteadyState: isSteadyState,
                numberOfDoses: nDoses,
                isTroughBoundary: true,
              );
            }
          } else {
            c = calculateTwoCompBolusConcentration(
              timeHours: t,
              dose: dose,
              tau: tau,
              vc: vc,
              k10: k10,
              k12: k12,
              k21: k21,
              isSteadyState: isSteadyState,
              numberOfDoses: nDoses,
              isTroughBoundary: isCycleBoundary && isTerminal,
            );
          }
          break;

        case AdministrationRoute.ivIntermittentInfusion:
          final localT = tau > 0 ? (t % tau) : t;
          isInfusing = localT <= tInf + 1e-9 && (isSteadyState || (t / tau).floor() < nDoses);
          c = calculateTwoCompInfusionConcentration(
            timeHours: t,
            dose: dose,
            tau: tau,
            tInf: tInf,
            vc: vc,
            k10: k10,
            k12: k12,
            k21: k21,
            isSteadyState: isSteadyState,
            numberOfDoses: nDoses,
          );
          break;

        case AdministrationRoute.oralExtravascular:
          c = calculateTwoCompOralConcentration(
            timeHours: t,
            dose: dose,
            tau: tau,
            vc: vc,
            k10: k10,
            k12: k12,
            k21: k21,
            ka: ka,
            bioavailability: f,
            isSteadyState: isSteadyState,
            numberOfDoses: nDoses,
          );
          break;

        case AdministrationRoute.continuousInfusion:
          isInfusing = true;
          // Approximate continuous 2-compartment approach
          final k0 = params.continuousRate;
          c = params.cStart * exp(-beta * t) + (k0 / cl) * (1.0 - exp(-beta * t));
          break;
      }

      final zone = window?.classify(c);
      curve.add(PkDataPoint(
        timeHours: t,
        concentrationMgL: max(0.0, c),
        isInfusing: isInfusing,
        zone: zone,
      ));
    }

    final totalAuc = calculateTrapezoidalAuc(curve);

    // Digoxin / NTI distribution phase hazard check (alpha phase duration)
    bool hasDistWarning = false;
    String? distWarningMsg;
    if (params.hasDistributionPhaseWarning) {
      hasDistWarning = true;
      distWarningMsg =
          '⚠️ คำเตือนช่วงการกระจายตัว (Distribution Phase Warning): Digoxin มีระยะกระจายตัวยาวนาน (${params.distributionSafeHours.toStringAsFixed(1)} ชม.) '
          'ห้ามเจาะวัดระดับยาในเลือดก่อนเวลา ${params.distributionSafeHours.toStringAsFixed(0)} ชม. หลังให้ยา เนื่องจากระดับยาในหลอดเลือดส่วนกลางยังไม่สมดุลกับกล้ามเนื้อหัวใจ (Myocardium) จะได้ผลระดับยาสูงเกินจริง';
    }

    // Overdose Rule 5 Check
    final hasOverdose = window != null && cMax > window.mtc;
    final overdoseMsg = hasOverdose
        ? '⚠️ คำเตือน: ขนาดยานี้เกินเกณฑ์สูงสุดที่แนะนำ (Overdose Warning: Cmax ${cMax.toStringAsFixed(2)} mg/L > MTC ${window.mtc.toStringAsFixed(2)} mg/L) — โปรดใช้ดุลยพินิจของแพทย์/เภสัชกรในการให้ยา'
        : null;

    return PkSimulationResult(
      params: params,
      curve: curve,
      cMax: cMax,
      cMin: cMin,
      tMax: tMax,
      auc0To24: auc0To24,
      aucTotal: totalAuc,
      ke: beta,
      tHalf: tHalfBeta,
      accumulationFactor: accumulationFactor,
      hasDistributionPhaseWarning: hasDistWarning,
      distributionPhaseWarningMessage: distWarningMsg,
      hasOverdoseWarning: hasOverdose,
      overdoseWarningMessage: overdoseMsg,
    );
  }

  // ===========================================================================
  // EXACT MATHEMATICAL CONCENTRATION EQUATIONS (1-COMPARTMENT)
  // ===========================================================================

  /// Calculates 1-compartment IV bolus concentration at [timeHours].
  ///
  /// Single-dose: C(t) = (Dose / Vd) * exp(-ke * t)
  /// Steady-state: C_ss(t') = (Dose / (Vd * (1 - exp(-ke * tau)))) * exp(-ke * t')
  ///
  /// When [isTroughBoundary] is true at exact cycle boundaries (t = k * tau, k >= 1),
  /// evaluates the left-hand limit (trough C_min, tCycle = tau) rather than the peak C_max.
  static double calculateOneCompBolusConcentration({
    required double timeHours,
    required double dose,
    required double tau,
    required double vd,
    required double ke,
    bool isSteadyState = true,
    int numberOfDoses = 1,
    bool isTroughBoundary = false,
  }) {
    if (timeHours < 0) return 0.0;
    final c0 = dose / vd;

    if (isSteadyState) {
      double tCycle;
      if (tau > 0) {
        final isCycleEnd = timeHours > 0 && ((timeHours / tau).round() * tau - timeHours).abs() < 1e-7;
        if (isTroughBoundary && isCycleEnd) {
          tCycle = tau;
        } else {
          tCycle = timeHours % tau;
        }
      } else {
        tCycle = timeHours;
      }
      final acc = 1.0 / (1.0 - exp(-ke * tau));
      return c0 * acc * exp(-ke * tCycle);
    } else {
      double sum = 0.0;
      final effectiveTime = isTroughBoundary ? max(0.0, timeHours - 1e-9) : timeHours;
      final maxCycle = min(numberOfDoses - 1, tau > 0 ? (effectiveTime / tau).floor() : 0);
      for (var j = 0; j <= maxCycle; j++) {
        final elapsed = timeHours - (j * tau);
        if (elapsed >= 0) {
          sum += c0 * exp(-ke * elapsed);
        }
      }
      return sum;
    }
  }

  /// Calculates 1-compartment IV intermittent infusion concentration at [timeHours].
  ///
  /// During infusion (0 <= t' <= tInf):
  /// C(t') = C_min * exp(-ke * t') + (Dose / (tInf * Cl)) * (1 - exp(-ke * t'))
  ///
  /// Post-infusion (tInf < t' <= tau):
  /// C(t') = C_max * exp(-ke * (t' - tInf))
  static double calculateOneCompInfusionConcentration({
    required double timeHours,
    required double dose,
    required double tau,
    required double tInf,
    required double vd,
    required double ke,
    bool isSteadyState = true,
    int numberOfDoses = 1,
  }) {
    if (timeHours < 0) return 0.0;

    // Graceful limit to bolus if infusion time is negligible
    if (tInf < 1e-6) {
      return calculateOneCompBolusConcentration(
        timeHours: timeHours,
        dose: dose,
        tau: tau,
        vd: vd,
        ke: ke,
        isSteadyState: isSteadyState,
        numberOfDoses: numberOfDoses,
      );
    }

    final cl = vd * ke;
    final rInf = dose / tInf;

    if (isSteadyState) {
      final tCycle = tau > 0 ? (timeHours % tau) : timeHours;
      final peakSs = calculateSteadyStatePeakInfusion(
        dose: dose,
        tau: tau,
        tInf: tInf,
        vd: vd,
        ke: ke,
      );
      final troughSs = peakSs * exp(-ke * (tau - tInf));

      if (tCycle <= tInf) {
        return troughSs * exp(-ke * tCycle) + (rInf / cl) * (1.0 - exp(-ke * tCycle));
      } else {
        return peakSs * exp(-ke * (tCycle - tInf));
      }
    } else {
      // Linear superposition across finite completed/ongoing doses
      double sum = 0.0;
      final maxCycle = min(numberOfDoses - 1, tau > 0 ? (timeHours / tau).floor() : 0);
      for (var j = 0; j <= maxCycle; j++) {
        final u = timeHours - (j * tau);
        if (u < 0) continue;
        if (u <= tInf) {
          sum += (rInf / cl) * (1.0 - exp(-ke * u));
        } else {
          final singlePeak = (rInf / cl) * (1.0 - exp(-ke * tInf));
          sum += singlePeak * exp(-ke * (u - tInf));
        }
      }
      return sum;
    }
  }

  /// Calculates 1-compartment oral / extravascular concentration at [timeHours] using the Bateman equation.
  ///
  /// General Bateman equation (ka != ke):
  /// C(t) = (F * Dose * ka) / (Vd * (ka - ke)) * (exp(-ke * t) - exp(-ka * t))
  ///
  /// Critical singularity limit when |ka - ke| < 1e-6 (L'Hôpital's rule analytical solution):
  /// C(t) = (F * Dose * ke / Vd) * t * exp(-ke * t)
  static double calculateOneCompOralConcentration({
    required double timeHours,
    required double dose,
    required double tau,
    required double vd,
    required double ke,
    required double ka,
    double bioavailability = 1.0,
    double tLag = 0.0,
    bool isSteadyState = true,
    int numberOfDoses = 1,
  }) {
    if (timeHours < tLag) return 0.0;
    final tAdjusted = timeHours - tLag;

    final isSingularity = (ka - ke).abs() < 1e-6;

    if (isSteadyState) {
      final tCycle = tau > 0 ? (tAdjusted % tau) : tAdjusted;

      if (isSingularity) {
        // Analytical L'Hôpital limit for steady-state oral superposition
        final z = exp(-ke * tau);
        final denom = 1.0 - z;
        final prefactor = (bioavailability * dose * ke) / vd;
        return prefactor * exp(-ke * tCycle) * ((tCycle / denom) + (tau * z / (denom * denom)));
      } else {
        final coeff = (bioavailability * dose * ka) / (vd * (ka - ke));
        final termKe = exp(-ke * tCycle) / (1.0 - exp(-ke * tau));
        final termKa = exp(-ka * tCycle) / (1.0 - exp(-ka * tau));
        return coeff * (termKe - termKa);
      }
    } else {
      double sum = 0.0;
      final maxCycle = min(numberOfDoses - 1, tau > 0 ? (tAdjusted / tau).floor() : 0);
      for (var j = 0; j <= maxCycle; j++) {
        final u = tAdjusted - (j * tau);
        if (u < 0) continue;

        if (isSingularity) {
          sum += ((bioavailability * dose * ke) / vd) * u * exp(-ke * u);
        } else {
          final coeff = (bioavailability * dose * ka) / (vd * (ka - ke));
          sum += coeff * (exp(-ke * u) - exp(-ka * u));
        }
      }
      return sum;
    }
  }

  /// Calculates 1-compartment continuous zero-order infusion concentration at [timeHours].
  ///
  /// C(t) = cStart * exp(-ke * t) + (k0 / Cl) * (1 - exp(-ke * t))
  static double calculateOneCompContinuousConcentration({
    required double timeHours,
    required double continuousRate,
    required double cl,
    required double ke,
    double cStart = 0.0,
  }) {
    if (timeHours < 0) return cStart;
    final infComponent = (continuousRate / cl) * (1.0 - exp(-ke * timeHours));
    final decayComponent = cStart * exp(-ke * timeHours);
    return decayComponent + infComponent;
  }

  // ===========================================================================
  // EXACT MATHEMATICAL CONCENTRATION EQUATIONS (2-COMPARTMENT)
  // ===========================================================================

  /// Calculates 2-compartment IV bolus biexponential concentration at [timeHours].
  ///
  /// C(t) = A * exp(-alpha * t) + B * exp(-beta * t)
  ///
  /// When [isTroughBoundary] is true at exact cycle boundaries (t = k * tau, k >= 1),
  /// evaluates the left-hand limit (trough C_min, tCycle = tau) rather than the peak C_max.
  static double calculateTwoCompBolusConcentration({
    required double timeHours,
    required double dose,
    required double tau,
    required double vc,
    required double k10,
    required double k12,
    required double k21,
    bool isSteadyState = true,
    int numberOfDoses = 1,
    bool isTroughBoundary = false,
  }) {
    if (timeHours < 0) return 0.0;

    final s = k10 + k12 + k21;
    final p = k10 * k21;
    final discriminant = max(0.0, s * s - 4.0 * p);
    final alpha = (s + sqrt(discriminant)) / 2.0;
    final beta = (s - sqrt(discriminant)) / 2.0;

    final denom = alpha - beta;
    final aCoeff = denom.abs() > 1e-12 ? (dose / vc) * ((alpha - k21) / denom) : (dose / vc) / 2.0;
    final bCoeff = denom.abs() > 1e-12 ? (dose / vc) * ((k21 - beta) / denom) : (dose / vc) / 2.0;

    if (isSteadyState) {
      double tCycle;
      if (tau > 0) {
        final isCycleEnd = timeHours > 0 && ((timeHours / tau).round() * tau - timeHours).abs() < 1e-7;
        if (isTroughBoundary && isCycleEnd) {
          tCycle = tau;
        } else {
          tCycle = timeHours % tau;
        }
      } else {
        tCycle = timeHours;
      }
      final termA = (aCoeff / (1.0 - exp(-alpha * tau))) * exp(-alpha * tCycle);
      final termB = (bCoeff / (1.0 - exp(-beta * tau))) * exp(-beta * tCycle);
      return termA + termB;
    } else {
      double sum = 0.0;
      final effectiveTime = isTroughBoundary ? max(0.0, timeHours - 1e-9) : timeHours;
      final maxCycle = min(numberOfDoses - 1, tau > 0 ? (effectiveTime / tau).floor() : 0);
      for (var j = 0; j <= maxCycle; j++) {
        final u = timeHours - (j * tau);
        if (u >= 0) {
          sum += aCoeff * exp(-alpha * u) + bCoeff * exp(-beta * u);
        }
      }
      return sum;
    }
  }

  /// Calculates 2-compartment IV intermittent infusion concentration at [timeHours].
  static double calculateTwoCompInfusionConcentration({
    required double timeHours,
    required double dose,
    required double tau,
    required double tInf,
    required double vc,
    required double k10,
    required double k12,
    required double k21,
    bool isSteadyState = true,
    int numberOfDoses = 1,
  }) {
    if (timeHours < 0) return 0.0;

    if (tInf < 1e-6) {
      return calculateTwoCompBolusConcentration(
        timeHours: timeHours,
        dose: dose,
        tau: tau,
        vc: vc,
        k10: k10,
        k12: k12,
        k21: k21,
        isSteadyState: isSteadyState,
        numberOfDoses: numberOfDoses,
      );
    }

    final s = k10 + k12 + k21;
    final p = k10 * k21;
    final discriminant = max(0.0, s * s - 4.0 * p);
    final alpha = (s + sqrt(discriminant)) / 2.0;
    final beta = (s - sqrt(discriminant)) / 2.0;

    final denom = alpha - beta;
    final aCoeff = denom.abs() > 1e-12 ? (dose / vc) * ((alpha - k21) / denom) : (dose / vc) / 2.0;
    final bCoeff = denom.abs() > 1e-12 ? (dose / vc) * ((k21 - beta) / denom) : (dose / vc) / 2.0;

    if (isSteadyState) {
      final tCycle = tau > 0 ? (timeHours % tau) : timeHours;
      final aInfSs = (aCoeff / (alpha * tInf)) * ((1.0 - exp(-alpha * tInf)) / (1.0 - exp(-alpha * tau)));
      final bInfSs = (bCoeff / (beta * tInf)) * ((1.0 - exp(-beta * tInf)) / (1.0 - exp(-beta * tau)));

      if (tCycle <= tInf) {
        final currentInfA = (aCoeff / (alpha * tInf)) * (1.0 - exp(-alpha * tCycle));
        final currentInfB = (bCoeff / (beta * tInf)) * (1.0 - exp(-beta * tCycle));
        final priorCarryoverA = aInfSs * exp(-alpha * (tau - tInf + tCycle));
        final priorCarryoverB = bInfSs * exp(-beta * (tau - tInf + tCycle));
        return currentInfA + currentInfB + priorCarryoverA + priorCarryoverB;
      } else {
        return aInfSs * exp(-alpha * (tCycle - tInf)) + bInfSs * exp(-beta * (tCycle - tInf));
      }
    } else {
      double sum = 0.0;
      final maxCycle = min(numberOfDoses - 1, tau > 0 ? (timeHours / tau).floor() : 0);
      for (var j = 0; j <= maxCycle; j++) {
        final u = timeHours - (j * tau);
        if (u < 0) continue;

        if (u <= tInf) {
          sum += (aCoeff / (alpha * tInf)) * (1.0 - exp(-alpha * u)) + (bCoeff / (beta * tInf)) * (1.0 - exp(-beta * u));
        } else {
          final peakA = (aCoeff / (alpha * tInf)) * (1.0 - exp(-alpha * tInf));
          final peakB = (bCoeff / (beta * tInf)) * (1.0 - exp(-beta * tInf));
          sum += peakA * exp(-alpha * (u - tInf)) + peakB * exp(-beta * (u - tInf));
        }
      }
      return sum;
    }
  }

  /// Calculates 2-compartment oral absorption triexponential concentration at [timeHours].
  ///
  /// C(t) = A_po * exp(-alpha*t) + B_po * exp(-beta*t) + C_po * exp(-ka*t)
  static double calculateTwoCompOralConcentration({
    required double timeHours,
    required double dose,
    required double tau,
    required double vc,
    required double k10,
    required double k12,
    required double k21,
    required double ka,
    double bioavailability = 1.0,
    bool isSteadyState = true,
    int numberOfDoses = 1,
  }) {
    if (timeHours < 0) return 0.0;

    final s = k10 + k12 + k21;
    final p = k10 * k21;
    final discriminant = max(0.0, s * s - 4.0 * p);
    final alpha = (s + sqrt(discriminant)) / 2.0;
    final beta = (s - sqrt(discriminant)) / 2.0;

    // Small numerical perturbation if ka is identical to alpha or beta to prevent divide-by-zero
    var effectiveKa = ka;
    if ((effectiveKa - alpha).abs() < 1e-6) {
      effectiveKa += 1e-5;
    }
    if ((effectiveKa - beta).abs() < 1e-6) {
      effectiveKa += 1e-5;
    }

    final prefactor = (bioavailability * dose * effectiveKa) / vc;
    final aPo = prefactor * ((k21 - alpha) / ((effectiveKa - alpha) * (beta - alpha)));
    final bPo = prefactor * ((k21 - beta) / ((effectiveKa - beta) * (alpha - beta)));
    final cPo = -(aPo + bPo);

    if (isSteadyState) {
      final tCycle = tau > 0 ? (timeHours % tau) : timeHours;
      final termA = (aPo / (1.0 - exp(-alpha * tau))) * exp(-alpha * tCycle);
      final termB = (bPo / (1.0 - exp(-beta * tau))) * exp(-beta * tCycle);
      final termC = (cPo / (1.0 - exp(-effectiveKa * tau))) * exp(-effectiveKa * tCycle);
      return max(0.0, termA + termB + termC);
    } else {
      double sum = 0.0;
      final maxCycle = min(numberOfDoses - 1, tau > 0 ? (timeHours / tau).floor() : 0);
      for (var j = 0; j <= maxCycle; j++) {
        final u = timeHours - (j * tau);
        if (u >= 0) {
          sum += aPo * exp(-alpha * u) + bPo * exp(-beta * u) + cPo * exp(-effectiveKa * u);
        }
      }
      return max(0.0, sum);
    }
  }

  // ===========================================================================
  // CLINICAL DERIVATIONS & HELPER CALCULATIONS
  // ===========================================================================

  /// Calculates the accumulation factor R = 1 / (1 - exp(-ke * tau)).
  static double calculateAccumulationFactor({
    required double ke,
    required double tau,
  }) {
    if (ke <= 0 || tau <= 0) {
      throw ArgumentError('ke and tau must be strictly positive');
    }
    final expFactor = exp(-ke * tau);
    if ((1.0 - expFactor).abs() < 1e-12) return 1e12;
    return 1.0 / (1.0 - expFactor);
  }

  /// Calculates the steady-state peak concentration for intermittent IV infusions.
  ///
  /// C_max,ss = (Dose / (tInf * Vd * ke)) * ((1 - exp(-ke * tInf)) / (1 - exp(-ke * tau)))
  static double calculateSteadyStatePeakInfusion({
    required double dose,
    required double tau,
    required double tInf,
    required double vd,
    required double ke,
  }) {
    if (tInf < 1e-6) {
      return (dose / vd) * calculateAccumulationFactor(ke: ke, tau: tau);
    }
    final cl = vd * ke;
    final rInf = dose / tInf;
    final acc = calculateAccumulationFactor(ke: ke, tau: tau);
    return (rInf / cl) * (1.0 - exp(-ke * tInf)) * acc;
  }

  /// Calculates single-dose oral T_max: ln(ka / ke) / (ka - ke), or 1/ke when ka == ke.
  static double calculateSingleDoseOralTMax({
    required double ka,
    required double ke,
  }) {
    if ((ka - ke).abs() < 1e-6) {
      return 1.0 / ke;
    }
    return log(ka / ke) / (ka - ke);
  }

  /// Calculates steady-state oral T_max: (1 / (ka - ke)) * ln[ (ka * (1 - exp(-ke*tau))) / (ke * (1 - exp(-ka*tau))) ]
  static double calculateSteadyStateOralTMax({
    required double ka,
    required double ke,
    required double tau,
  }) {
    if ((ka - ke).abs() < 1e-6) {
      final z = exp(-ke * tau);
      final correction = (tau * z) / (1.0 - z);
      return max(0.0, (1.0 / ke) - correction);
    }
    final num = ka * (1.0 - exp(-ke * tau));
    final denom = ke * (1.0 - exp(-ka * tau));
    if (num <= 0 || denom <= 0) return 0.0;
    return (1.0 / (ka - ke)) * log(num / denom);
  }

  /// Calculates analytical steady-state 24-hour AUC: (Daily Dose) / Clearance.
  ///
  /// Valid universally for all linear 1-compartment and multi-compartment systems.
  static double calculateSteadyStateAuc24({
    required double dose,
    required double tau,
    required double clearance,
    double bioavailability = 1.0,
  }) {
    if (clearance <= 0 || tau <= 0) {
      throw ArgumentError('Clearance and tau must be strictly positive');
    }
    final dailyDose = (bioavailability * dose) * (24.0 / tau);
    return dailyDose / clearance;
  }

  /// Computes numerical trapezoidal AUC from discrete coordinates.
  ///
  /// Uses log-linear trapezoidal rule during elimination decay (when c_{i-1} > c_i > 0)
  /// and linear trapezoidal rule during inflow/absorption/zero phases.
  static double calculateTrapezoidalAuc(List<PkDataPoint> curve, {double? upToHour}) {
    if (curve.length < 2) return 0.0;

    double total = 0.0;
    for (var i = 1; i < curve.length; i++) {
      final pPrev = curve[i - 1];
      final pCurr = curve[i];

      if (upToHour != null && pPrev.timeHours >= upToHour) {
        break;
      }

      var tEnd = pCurr.timeHours;
      var cEnd = pCurr.concentrationMgL;
      if (upToHour != null && tEnd > upToHour) {
        // Interpolate concentration at upToHour
        final frac = (upToHour - pPrev.timeHours) / (tEnd - pPrev.timeHours);
        tEnd = upToHour;
        cEnd = pPrev.concentrationMgL + frac * (cEnd - pPrev.concentrationMgL);
      }

      final dt = tEnd - pPrev.timeHours;
      if (dt <= 0) continue;

      final c0 = pPrev.concentrationMgL;
      final c1 = cEnd;

      if (c0 > 0 && c1 > 0 && (c0 - c1).abs() > 1e-9) {
        if (c0 > c1) {
          // Log-linear trapezoidal integration on decay phase
          total += ((c0 - c1) / log(c0 / c1)) * dt;
        } else {
          // Linear trapezoidal on rise phase
          total += ((c0 + c1) / 2.0) * dt;
        }
      } else {
        total += ((c0 + c1) / 2.0) * dt;
      }
    }

    return total;
  }

  /// Compares two simulation results (baseline vs adjusted) and computes delta metrics.
  static PkSimulationComparison compareRegimens({
    required PkSimulationResult baseline,
    required PkSimulationResult adjusted,
  }) {
    final deltaCMax = adjusted.cMax - baseline.cMax;
    final deltaCMin = adjusted.cMin - baseline.cMin;
    final deltaAuc24 = adjusted.auc0To24 - baseline.auc0To24;
    final deltaTHalf = adjusted.tHalf - baseline.tHalf;

    final pctCMax = baseline.cMax.abs() > 1e-12 ? (deltaCMax / baseline.cMax) * 100.0 : 0.0;
    final pctCMin = baseline.cMin.abs() > 1e-12 ? (deltaCMin / baseline.cMin) * 100.0 : 0.0;
    final pctAuc24 = baseline.auc0To24.abs() > 1e-12 ? (deltaAuc24 / baseline.auc0To24) * 100.0 : 0.0;

    return PkSimulationComparison(
      baseline: baseline,
      adjusted: adjusted,
      deltaCMax: deltaCMax,
      deltaCMin: deltaCMin,
      deltaAuc24: deltaAuc24,
      deltaTHalf: deltaTHalf,
      percentChangeCMax: pctCMax,
      percentChangeCMin: pctCMin,
      percentChangeAuc24: pctAuc24,
    );
  }

  // ===========================================================================
  // PRIVATE MATHEMATICAL UTILITIES
  // ===========================================================================

  static double _calculateFiniteDoseAuc({
    required double dose,
    required double clearance,
    required int nDoses,
    required double tau,
    required double ke,
    required double maxHours,
  }) {
    // Single dose total AUC is dose / Cl
    // For finite doses up to maxHours, evaluate exact integral of sum
    double total = 0.0;
    for (var j = 0; j < nDoses; j++) {
      final tStart = j * tau;
      if (tStart >= maxHours) break;
      final tDuration = min(maxHours - tStart, 1000.0);
      final singleAuc = (dose / clearance) * (1.0 - exp(-ke * tDuration));
      total += singleAuc;
    }
    return total;
  }

  static double _estimateTwoCompOralTMax({
    required double ka,
    required double alpha,
    required double beta,
    required double k21,
  }) {
    var effectiveKa = ka;
    if ((effectiveKa - alpha).abs() < 1e-6) effectiveKa += 1e-5;
    if ((effectiveKa - beta).abs() < 1e-6) effectiveKa += 1e-5;

    // Golden section or bounded search for Tmax between 0.1 and 12h
    double bestT = 1.0;
    double maxC = -1.0;
    for (var t = 0.05; t <= 12.0; t += 0.05) {
      final c = (k21 - alpha) / ((effectiveKa - alpha) * (beta - alpha)) * exp(-alpha * t) +
          (k21 - beta) / ((effectiveKa - beta) * (alpha - beta)) * exp(-beta * t) -
          ((k21 - alpha) / ((effectiveKa - alpha) * (beta - alpha)) + (k21 - beta) / ((effectiveKa - beta) * (alpha - beta))) * exp(-effectiveKa * t);
      if (c > maxC) {
        maxC = c;
        bestT = t;
      }
    }
    return bestT;
  }

  /// Generates a discrete time grid with boundary-pinned coordinates ensuring
  /// sharp transition points (peaks, troughs, start/end of infusions) are preserved.
  static List<double> _generateBoundaryPinnedTimeGrid({
    required AdministrationRoute route,
    required double tau,
    required double tInf,
    required double tMax,
    required double horizonHours,
    required int pointsPerPhase,
  }) {
    final rawPoints = <double>{0.0};

    final numCycles = tau > 0 ? (horizonHours / tau).ceil() + 1 : 1;

    for (var cycle = 0; cycle < numCycles; cycle++) {
      final tStart = cycle * tau;
      if (tStart <= horizonHours) {
        rawPoints.add(tStart);
      }

      if (route == AdministrationRoute.ivIntermittentInfusion) {
        final tInfEnd = tStart + tInf;
        if (tInfEnd <= horizonHours) {
          rawPoints.add(tInfEnd);
          if (tInfEnd + 1e-6 <= horizonHours) {
            rawPoints.add(tInfEnd + 1e-6);
          }
        }
        // Inflow phase points
        for (var i = 1; i < pointsPerPhase; i++) {
          final t = tStart + (tInf * i) / pointsPerPhase;
          if (t <= horizonHours) rawPoints.add(t);
        }
        // Elimination phase points
        final elimDuration = tau - tInf;
        for (var i = 1; i < pointsPerPhase; i++) {
          final t = tInfEnd + (elimDuration * i) / pointsPerPhase;
          if (t <= horizonHours) rawPoints.add(t);
        }
      } else if (route == AdministrationRoute.oralExtravascular) {
        final localTMax = tStart + tMax;
        if (localTMax <= horizonHours) {
          rawPoints.add(localTMax);
        }
        for (var i = 1; i <= pointsPerPhase * 2; i++) {
          final t = tStart + (tau * i) / (pointsPerPhase * 2);
          if (t <= horizonHours) rawPoints.add(t);
        }
      } else {
        // IV Bolus or continuous infusion
        for (var i = 1; i <= pointsPerPhase * 2; i++) {
          final t = tStart + (tau * i) / (pointsPerPhase * 2);
          if (t <= horizonHours) rawPoints.add(t);
        }
      }
    }

    rawPoints.add(horizonHours);

    final sorted = rawPoints.where((t) => t >= 0.0 && t <= horizonHours).toList()..sort();

    // Deduplicate points within 1e-7 hours
    final deduplicated = <double>[];
    for (final pt in sorted) {
      if (deduplicated.isEmpty || (pt - deduplicated.last).abs() > 1e-7) {
        deduplicated.add(pt);
      }
    }

    // Ensure we meet the 200–500 points target for high resolution
    if (deduplicated.length < 200) {
      final expanded = <double>[];
      for (var i = 0; i < deduplicated.length - 1; i++) {
        expanded.add(deduplicated[i]);
        final mid = (deduplicated[i] + deduplicated[i + 1]) / 2.0;
        expanded.add(mid);
      }
      expanded.add(deduplicated.last);
      return expanded;
    }

    return deduplicated;
  }
}
