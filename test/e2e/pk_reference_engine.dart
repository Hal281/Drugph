// ============================================================================
// E2E Reference Pharmacokinetic & Pharmacodynamic Engine (Oracle Harness)
// ============================================================================
// Authoritative references:
// - Rowland & Tozer: Clinical Pharmacokinetics and Pharmacodynamics (4th ed)
// - DiPiro: Pharmacotherapy: A Pathophysiologic Approach
// - Winter: Basic Clinical Pharmacokinetics
// - Bauer: Applied Clinical Pharmacokinetics
// - Matzke et al. (1984): Vancomycin kinetic models
// - Nicolau et al. (1995): Hartford aminoglycoside nomogram
// - Sheiner & Tozer (1975): Albumin-adjusted phenytoin kinetics
// ============================================================================

import 'dart:math';

/// Route of administration for PK-PD modeling.
enum PkRoute {
  ivBolus,
  ivIntermittentInfusion,
  oralExtravascular,
  continuousInfusion,
}

/// Compartment disposition model.
enum PkCompartmentModel {
  oneCompartment,
  twoCompartment,
}

/// Discrete concentration-time point on a simulated curve.
class PkDataPoint {
  final double timeHours;
  final double concentrationMgL;
  final bool isInfusing;

  const PkDataPoint({
    required this.timeHours,
    required this.concentrationMgL,
    this.isInfusing = false,
  });

  @override
  String toString() =>
      'PkDataPoint(t: ${timeHours.toStringAsFixed(2)}h, C: ${concentrationMgL.toStringAsFixed(3)} mg/L, infusing: $isInfusing)';
}

/// Target therapeutic window defining efficacy and safety zones.
class PkTherapeuticWindow {
  final double mecMgL;
  final double mtcMgL;
  final double? targetTroughMinMgL;
  final double? targetTroughMaxMgL;
  final double? targetAuc24Min;
  final double? targetAuc24Max;

  const PkTherapeuticWindow({
    required this.mecMgL,
    required this.mtcMgL,
    this.targetTroughMinMgL,
    this.targetTroughMaxMgL,
    this.targetAuc24Min,
    this.targetAuc24Max,
  }) : assert(mtcMgL > mecMgL, 'MTC must be strictly greater than MEC');

  /// Evaluates the clinical exposure zone for a given concentration.
  String classifyConcentration(double c) {
    if (c < mecMgL) return 'subTherapeutic';
    if (c > mtcMgL) return 'toxicOverdose';
    return 'therapeutic';
  }
}

/// Complete simulation profile containing curve coordinates and derived PK parameters.
class PkCurveProfile {
  final PkRoute route;
  final PkCompartmentModel model;
  final double doseMg;
  final double tauHours;
  final double cMax;
  final double cMin;
  final double tMax;
  final double auc0To24;
  final double halfLifeHours;
  final double ke;
  final double accumulationFactorR;
  final List<PkDataPoint> curvePoints;
  final PkTherapeuticWindow? window;
  final bool hasOverdoseBreach;
  final bool hasDistributionPhaseWarning;

  const PkCurveProfile({
    required this.route,
    required this.model,
    required this.doseMg,
    required this.tauHours,
    required this.cMax,
    required this.cMin,
    required this.tMax,
    required this.auc0To24,
    required this.halfLifeHours,
    required this.ke,
    required this.accumulationFactorR,
    required this.curvePoints,
    this.window,
    required this.hasOverdoseBreach,
    this.hasDistributionPhaseWarning = false,
  });
}

/// Regimen comparison delta metrics.
class PkRegimenComparison {
  final PkCurveProfile baseline;
  final PkCurveProfile proposed;
  final double deltaCmax;
  final double deltaCmin;
  final double deltaAuc24;

  const PkRegimenComparison({
    required this.baseline,
    required this.proposed,
    required this.deltaCmax,
    required this.deltaCmin,
    required this.deltaAuc24,
  });
}

/// Pure deterministic reference implementation of PK-PD simulation equations.
abstract class PkReferenceEngine {
  /// Evaluates 1-compartment concentration at time t after a single dose.
  static double evaluateOneCompSingleDose({
    required PkRoute route,
    required double t,
    required double doseMg,
    required double vdLitres,
    required double keHrInv,
    double tInfHours = 1.0,
    double bioavailabilityF = 1.0,
    double kaHrInv = 1.0,
    double continuousRateMgHr = 0.0,
  }) {
    if (t < 0) return 0.0;
    if (doseMg <= 0 && route != PkRoute.continuousInfusion) {
      throw ArgumentError('Dose must be > 0');
    }
    if (vdLitres <= 0 || keHrInv <= 0) {
      throw ArgumentError('Vd and Ke must be > 0');
    }

    switch (route) {
      case PkRoute.ivBolus:
        final c0 = doseMg / vdLitres;
        return c0 * exp(-keHrInv * t);

      case PkRoute.ivIntermittentInfusion:
        if (tInfHours <= 0) {
          // Zero-infusion limit: behaves identically to IV bolus
          final c0 = doseMg / vdLitres;
          return c0 * exp(-keHrInv * t);
        }
        final rate = doseMg / tInfHours;
        final steadyMultiplier = rate / (vdLitres * keHrInv);
        if (t <= tInfHours) {
          return steadyMultiplier * (1.0 - exp(-keHrInv * t));
        } else {
          final peak = steadyMultiplier * (1.0 - exp(-keHrInv * tInfHours));
          return peak * exp(-keHrInv * (t - tInfHours));
        }

      case PkRoute.oralExtravascular:
        // Check Bateman singularity: ka == ke
        if ((kaHrInv - keHrInv).abs() < 1e-6) {
          // L'Hopital limit: C(t) = (F * Dose * ke / Vd) * t * exp(-ke * t)
          return (bioavailabilityF * doseMg * keHrInv / vdLitres) * t * exp(-keHrInv * t);
        } else {
          // Bateman equation
          final coeff = (bioavailabilityF * doseMg * kaHrInv) /
              (vdLitres * (kaHrInv - keHrInv));
          return coeff * (exp(-keHrInv * t) - exp(-kaHrInv * t));
        }

      case PkRoute.continuousInfusion:
        final clearance = vdLitres * keHrInv;
        final cSs = continuousRateMgHr / clearance;
        return cSs * (1.0 - exp(-keHrInv * t));
    }
  }

  /// Evaluates 1-compartment steady-state concentration at cycle time t' (0 <= t' <= tau).
  static double evaluateOneCompSteadyState({
    required PkRoute route,
    required double tPrime,
    required double doseMg,
    required double tauHours,
    required double vdLitres,
    required double keHrInv,
    double tInfHours = 1.0,
    double bioavailabilityF = 1.0,
    double kaHrInv = 1.0,
  }) {
    if (tauHours <= 0) throw ArgumentError('tau must be > 0');
    if (route == PkRoute.ivIntermittentInfusion && tInfHours >= tauHours) {
      throw ArgumentError('tau must be strictly greater than tInf');
    }

    final rSs = 1.0 / (1.0 - exp(-keHrInv * tauHours));

    switch (route) {
      case PkRoute.ivBolus:
        final cMaxSs = (doseMg / vdLitres) * rSs;
        return cMaxSs * exp(-keHrInv * tPrime);

      case PkRoute.ivIntermittentInfusion:
        final rate = doseMg / tInfHours;
        final cMaxSs = (rate / (vdLitres * keHrInv)) *
            ((1.0 - exp(-keHrInv * tInfHours)) / (1.0 - exp(-keHrInv * tauHours)));
        final cMinSs = cMaxSs * exp(-keHrInv * (tauHours - tInfHours));
        if (tPrime <= tInfHours) {
          return cMinSs * exp(-keHrInv * tPrime) +
              (rate / (vdLitres * keHrInv)) * (1.0 - exp(-keHrInv * tPrime));
        } else {
          return cMaxSs * exp(-keHrInv * (tPrime - tInfHours));
        }

      case PkRoute.oralExtravascular:
        if ((kaHrInv - keHrInv).abs() < 1e-6) {
          // Exact analytical superposition limit for ka = ke
          final term1 = tPrime * exp(-keHrInv * tPrime) * rSs;
          final term2 = (tauHours * exp(-keHrInv * (tPrime + tauHours))) /
              pow(1.0 - exp(-keHrInv * tauHours), 2);
          return (bioavailabilityF * doseMg * keHrInv / vdLitres) * (term1 + term2);
        } else {
          final rKa = 1.0 / (1.0 - exp(-kaHrInv * tauHours));
          final coeff = (bioavailabilityF * doseMg * kaHrInv) /
              (vdLitres * (kaHrInv - keHrInv));
          return coeff * (rSs * exp(-keHrInv * tPrime) - rKa * exp(-kaHrInv * tPrime));
        }

      case PkRoute.continuousInfusion:
        final clearance = vdLitres * keHrInv;
        return doseMg / clearance; // Continuous steady state is constant
    }
  }

  /// Macro-parameter conversion for 2-compartment model.
  static Map<String, double> calculateTwoCompMacroConstants({
    required double vcLitres,
    required double k10HrInv,
    required double k12HrInv,
    required double k21HrInv,
    required double doseMg,
  }) {
    if (vcLitres <= 0 || k10HrInv <= 0 || k21HrInv <= 0) {
      throw ArgumentError('2-compartment micro constants must be > 0');
    }
    final sumK = k10HrInv + k12HrInv + k21HrInv;
    final prodK = k10HrInv * k21HrInv;
    final discriminant = max(0.0, (sumK * sumK) - (4.0 * prodK));
    final sqrtDisc = sqrt(discriminant);

    final alpha = (sumK + sqrtDisc) / 2.0;
    final beta = (sumK - sqrtDisc) / 2.0;

    final aCoeff = (doseMg / vcLitres) * ((alpha - k21HrInv) / (alpha - beta));
    final bCoeff = (doseMg / vcLitres) * ((k21HrInv - beta) / (alpha - beta));

    final clearance = vcLitres * k10HrInv;
    final vBeta = clearance / beta;
    final vSs = vcLitres * (1.0 + (k12HrInv / k21HrInv));

    return {
      'alpha': alpha,
      'beta': beta,
      'A': aCoeff,
      'B': bCoeff,
      'tHalfAlpha': log(2) / alpha,
      'tHalfBeta': log(2) / beta,
      'clearance': clearance,
      'vBeta': vBeta,
      'vSs': vSs,
    };
  }

  /// Evaluates 2-compartment IV bolus concentration: C(t) = A*exp(-alpha*t) + B*exp(-beta*t)
  static double evaluateTwoCompBolus({
    required double t,
    required double aCoeff,
    required double alpha,
    required double bCoeff,
    required double beta,
  }) {
    if (t < 0) return 0.0;
    return aCoeff * exp(-alpha * t) + bCoeff * exp(-beta * t);
  }

  /// Calculates Area Under Curve numerically using linear-up and log-down trapezoidal rule.
  static double calculateTrapezoidalAuc(List<PkDataPoint> points) {
    if (points.length < 2) return 0.0;
    double auc = 0.0;
    for (int i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];
      final dt = p1.timeHours - p0.timeHours;
      if (dt <= 0) continue;

      final c0 = p0.concentrationMgL;
      final c1 = p1.concentrationMgL;

      if (c1 >= c0 || c0 <= 0 || c1 <= 0) {
        // Linear trapezoidal rule
        auc += 0.5 * (c0 + c1) * dt;
      } else {
        // Log-linear trapezoidal rule during elimination decay
        auc += ((c0 - c1) / log(c0 / c1)) * dt;
      }
    }
    return auc;
  }

  /// Full 1-compartment simulation generating discretized coordinates and PK metrics.
  static PkCurveProfile simulateOneCompartment({
    required PkRoute route,
    required double doseMg,
    required double tauHours,
    required double vdLitres,
    required double keHrInv,
    double tInfHours = 1.0,
    double bioavailabilityF = 1.0,
    double kaHrInv = 1.0,
    double continuousRateMgHr = 0.0,
    int numberOfDoses = 1,
    bool isSteadyState = true,
    double horizonHours = 24.0,
    int pointsPerPhase = 50,
    PkTherapeuticWindow? window,
  }) {
    if (tauHours <= 0) throw ArgumentError('tau must be > 0');
    if (vdLitres <= 0 || keHrInv <= 0) throw ArgumentError('Vd and Ke must be > 0');
    if (route == PkRoute.ivIntermittentInfusion && tInfHours >= tauHours) {
      throw ArgumentError('tau must be strictly greater than tInf');
    }

    final halfLife = log(2) / keHrInv;
    final rSs = 1.0 / (1.0 - exp(-keHrInv * tauHours));

    // Analytical parameters
    double cMax;
    double cMin;
    double tMax;
    double auc24;

    final clearance = vdLitres * keHrInv;

    switch (route) {
      case PkRoute.ivBolus:
        tMax = 0.0;
        cMax = (doseMg / vdLitres) * (isSteadyState ? rSs : 1.0);
        cMin = cMax * exp(-keHrInv * tauHours);
        auc24 = (doseMg * (24.0 / tauHours)) / clearance;
        break;

      case PkRoute.ivIntermittentInfusion:
        tMax = tInfHours;
        final rate = doseMg / tInfHours;
        cMax = (rate / (vdLitres * keHrInv)) *
            (1.0 - exp(-keHrInv * tInfHours)) *
            (isSteadyState ? rSs : 1.0);
        cMin = cMax * exp(-keHrInv * (tauHours - tInfHours));
        auc24 = (doseMg * (24.0 / tauHours)) / clearance;
        break;

      case PkRoute.oralExtravascular:
        if ((kaHrInv - keHrInv).abs() < 1e-6) {
          tMax = 1.0 / keHrInv;
          cMax = (bioavailabilityF * doseMg) / (vdLitres * exp(1));
          if (isSteadyState) cMax *= rSs;
        } else {
          tMax = log(kaHrInv / keHrInv) / (kaHrInv - keHrInv);
          final cSingle = (bioavailabilityF * doseMg * kaHrInv) /
              (vdLitres * (kaHrInv - keHrInv)) *
              (exp(-keHrInv * tMax) - exp(-kaHrInv * tMax));
          cMax = isSteadyState ? cSingle * rSs : cSingle;
        }
        cMin = evaluateOneCompSteadyState(
          route: route,
          tPrime: tauHours,
          doseMg: doseMg,
          tauHours: tauHours,
          vdLitres: vdLitres,
          keHrInv: keHrInv,
          bioavailabilityF: bioavailabilityF,
          kaHrInv: kaHrInv,
        );
        auc24 = (bioavailabilityF * doseMg * (24.0 / tauHours)) / clearance;
        break;

      case PkRoute.continuousInfusion:
        tMax = 0.0;
        cMax = continuousRateMgHr / clearance;
        cMin = cMax;
        auc24 = cMax * 24.0;
        break;
    }

    // Discretized sampling
    final points = <PkDataPoint>[];
    final totalCycles = isSteadyState ? (horizonHours / tauHours).ceil() : numberOfDoses;

    for (int cycle = 0; cycle < totalCycles; cycle++) {
      final cycleStart = cycle * tauHours;
      if (route == PkRoute.ivIntermittentInfusion) {
        // Phase 1: Infusion (0 to tInf)
        for (int i = 0; i <= pointsPerPhase; i++) {
          final localT = (tInfHours * i) / pointsPerPhase;
          final globalT = cycleStart + localT;
          if (globalT > horizonHours) break;
          final c = isSteadyState
              ? evaluateOneCompSteadyState(
                  route: route,
                  tPrime: localT,
                  doseMg: doseMg,
                  tauHours: tauHours,
                  vdLitres: vdLitres,
                  keHrInv: keHrInv,
                  tInfHours: tInfHours,
                )
              : evaluateOneCompSingleDose(
                  route: route,
                  t: globalT,
                  doseMg: doseMg,
                  vdLitres: vdLitres,
                  keHrInv: keHrInv,
                  tInfHours: tInfHours,
                );
          points.add(PkDataPoint(
            timeHours: globalT,
            concentrationMgL: c,
            isInfusing: localT < tInfHours,
          ));
        }
        // Phase 2: Post-infusion elimination (tInf to tau)
        for (int i = 1; i <= pointsPerPhase; i++) {
          final localT = tInfHours + ((tauHours - tInfHours) * i) / pointsPerPhase;
          final globalT = cycleStart + localT;
          if (globalT > horizonHours) break;
          final c = isSteadyState
              ? evaluateOneCompSteadyState(
                  route: route,
                  tPrime: localT,
                  doseMg: doseMg,
                  tauHours: tauHours,
                  vdLitres: vdLitres,
                  keHrInv: keHrInv,
                  tInfHours: tInfHours,
                )
              : evaluateOneCompSingleDose(
                  route: route,
                  t: globalT,
                  doseMg: doseMg,
                  vdLitres: vdLitres,
                  keHrInv: keHrInv,
                  tInfHours: tInfHours,
                );
          points.add(PkDataPoint(
            timeHours: globalT,
            concentrationMgL: c,
            isInfusing: false,
          ));
        }
      } else {
        // Equidistant cycle sampling with pinned boundaries
        for (int i = 0; i <= pointsPerPhase * 2; i++) {
          final localT = (tauHours * i) / (pointsPerPhase * 2);
          final globalT = cycleStart + localT;
          if (globalT > horizonHours) break;
          final c = isSteadyState
              ? evaluateOneCompSteadyState(
                  route: route,
                  tPrime: localT,
                  doseMg: doseMg,
                  tauHours: tauHours,
                  vdLitres: vdLitres,
                  keHrInv: keHrInv,
                  bioavailabilityF: bioavailabilityF,
                  kaHrInv: kaHrInv,
                )
              : evaluateOneCompSingleDose(
                  route: route,
                  t: globalT,
                  doseMg: doseMg,
                  vdLitres: vdLitres,
                  keHrInv: keHrInv,
                  bioavailabilityF: bioavailabilityF,
                  kaHrInv: kaHrInv,
                  continuousRateMgHr: continuousRateMgHr,
                );
          points.add(PkDataPoint(
            timeHours: globalT,
            concentrationMgL: c,
            isInfusing: false,
          ));
        }
      }
    }

    final hasOverdose = window != null && cMax > window.mtcMgL;

    return PkCurveProfile(
      route: route,
      model: PkCompartmentModel.oneCompartment,
      doseMg: doseMg,
      tauHours: tauHours,
      cMax: cMax,
      cMin: cMin,
      tMax: tMax,
      auc0To24: auc24,
      halfLifeHours: halfLife,
      ke: keHrInv,
      accumulationFactorR: rSs,
      curvePoints: points,
      window: window,
      hasOverdoseBreach: hasOverdose,
    );
  }

  /// Compares baseline and proposed regimens.
  static PkRegimenComparison compareRegimens({
    required PkCurveProfile baseline,
    required PkCurveProfile proposed,
  }) {
    return PkRegimenComparison(
      baseline: baseline,
      proposed: proposed,
      deltaCmax: proposed.cMax - baseline.cMax,
      deltaCmin: proposed.cMin - baseline.cMin,
      deltaAuc24: proposed.auc0To24 - baseline.auc0To24,
    );
  }
}
