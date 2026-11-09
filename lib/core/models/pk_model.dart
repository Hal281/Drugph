import 'dart:math';

/// Pharmacokinetic compartment architecture model type.
enum PkModelType {
  /// One-compartment model assuming instantaneous distribution.
  oneCompartment,

  /// Two-compartment model distinguishing central and peripheral compartments.
  twoCompartment,
}

/// Route of drug administration for pharmacokinetic simulation.
enum AdministrationRoute {
  /// Intravenous bolus injection (instantaneous input).
  ivBolus,

  /// Intravenous intermittent infusion over duration [tInf].
  ivIntermittentInfusion,

  /// Oral or extravascular administration with first-order absorption [ka] and bioavailability [F].
  oralExtravascular,

  /// Continuous zero-order intravenous infusion [k0].
  continuousInfusion,
}

/// Clinical therapeutic target zone classification.
enum TherapeuticZone {
  /// Sub-therapeutic concentration (< Minimum Effective Concentration).
  subTherapeutic,

  /// Target therapeutic concentration (MEC <= C <= MTC).
  therapeutic,

  /// Supratherapeutic / toxic concentration (> Minimum Toxic Concentration).
  toxic,
}

/// Pure pharmacokinetic parameters for 1-compartment modeling.
class PkParameters {
  /// Apparent volume of distribution in Liters (Vd > 0).
  final double vd;

  /// Elimination rate constant in hr^-1 (ke > 0).
  final double ke;

  /// Absorption rate constant in hr^-1 for oral route (ka > 0).
  final double ka;

  /// Fraction of drug absorbed into systemic circulation (0 < F <= 1.0).
  final double bioavailability;

  /// Absorption lag time in hours (tLag >= 0).
  final double tLag;

  /// Creates a validated [PkParameters] configuration.
  const PkParameters({
    required this.vd,
    required this.ke,
    this.ka = 1.0,
    this.bioavailability = 1.0,
    this.tLag = 0.0,
  });

  /// Systemic clearance in L/hr: Cl = Vd * ke.
  double get clearance => vd * ke;

  /// Terminal elimination half-life in hours: t1/2 = ln(2) / ke.
  double get eliminationHalfLife => log(2) / ke;

  /// Validates numerical constraints and throws [ArgumentError] if violated.
  void validate() {
    if (vd.isNaN || !vd.isFinite || vd <= 0) {
      throw ArgumentError.value(vd, 'vd', 'Volume of distribution must be finite and > 0');
    }
    if (ke.isNaN || !ke.isFinite || ke <= 0) {
      throw ArgumentError.value(ke, 'ke', 'Elimination rate constant must be finite and > 0');
    }
    if (ka.isNaN || !ka.isFinite || ka <= 0) {
      throw ArgumentError.value(ka, 'ka', 'Absorption rate constant must be finite and > 0');
    }
    if (bioavailability.isNaN || !bioavailability.isFinite || bioavailability <= 0 || bioavailability > 1.0) {
      throw ArgumentError.value(bioavailability, 'bioavailability', 'Bioavailability F must be in range (0, 1.0]');
    }
    if (tLag.isNaN || !tLag.isFinite || tLag < 0) {
      throw ArgumentError.value(tLag, 'tLag', 'Lag time must be finite and >= 0');
    }
  }

  /// Creates a copy with optional overridden fields.
  PkParameters copyWith({
    double? vd,
    double? ke,
    double? ka,
    double? bioavailability,
    double? tLag,
  }) {
    return PkParameters(
      vd: vd ?? this.vd,
      ke: ke ?? this.ke,
      ka: ka ?? this.ka,
      bioavailability: bioavailability ?? this.bioavailability,
      tLag: tLag ?? this.tLag,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PkParameters &&
          runtimeType == other.runtimeType &&
          vd == other.vd &&
          ke == other.ke &&
          ka == other.ka &&
          bioavailability == other.bioavailability &&
          tLag == other.tLag;

  @override
  int get hashCode => Object.hash(vd, ke, ka, bioavailability, tLag);

  @override
  String toString() =>
      'PkParameters(vd: $vd L, ke: $ke hr^-1, Cl: ${clearance.toStringAsFixed(2)} L/hr, t1/2: ${eliminationHalfLife.toStringAsFixed(2)} hr, ka: $ka hr^-1, F: $bioavailability)';
}

/// Pure pharmacokinetic parameters for 2-compartment modeling.
class TwoCompartmentParameters {
  /// Central compartment volume in Liters (Vc > 0).
  final double vc;

  /// Elimination rate constant from central compartment in hr^-1 (k10 > 0).
  final double k10;

  /// Transfer rate constant from central to peripheral compartment in hr^-1 (k12 >= 0).
  final double k12;

  /// Transfer rate constant from peripheral to central compartment in hr^-1 (k21 > 0).
  final double k21;

  /// Absorption rate constant in hr^-1 for oral 2-compartment route (ka > 0).
  final double ka;

  /// Bioavailability fraction for extravascular routes (0 < F <= 1.0).
  final double bioavailability;

  /// Creates a validated [TwoCompartmentParameters] configuration.
  const TwoCompartmentParameters({
    required this.vc,
    required this.k10,
    required this.k12,
    required this.k21,
    this.ka = 1.0,
    this.bioavailability = 1.0,
  });

  /// Validates numerical constraints and throws [ArgumentError] if violated.
  void validate() {
    if (vc.isNaN || !vc.isFinite || vc <= 0) {
      throw ArgumentError.value(vc, 'vc', 'Central volume Vc must be finite and > 0');
    }
    if (k10.isNaN || !k10.isFinite || k10 <= 0) {
      throw ArgumentError.value(k10, 'k10', 'Elimination micro-constant k10 must be finite and > 0');
    }
    if (k12.isNaN || !k12.isFinite || k12 < 0) {
      throw ArgumentError.value(k12, 'k12', 'Transfer micro-constant k12 must be finite and >= 0');
    }
    if (k21.isNaN || !k21.isFinite || k21 <= 0) {
      throw ArgumentError.value(k21, 'k21', 'Transfer micro-constant k21 must be finite and > 0');
    }
    if (ka.isNaN || !ka.isFinite || ka <= 0) {
      throw ArgumentError.value(ka, 'ka', 'Absorption rate constant ka must be finite and > 0');
    }
    if (bioavailability.isNaN || !bioavailability.isFinite || bioavailability <= 0 || bioavailability > 1.0) {
      throw ArgumentError.value(bioavailability, 'bioavailability', 'Bioavailability F must be in range (0, 1.0]');
    }
  }

  /// Systemic clearance in L/hr: Cl = Vc * k10.
  double get clearance => vc * k10;

  /// Apparent peripheral compartment volume in Liters: Vp = Vc * (k12 / k21).
  double get vp => k21 > 0 ? vc * (k12 / k21) : 0.0;

  /// Volume of distribution at steady state in Liters: Vss = Vc + Vp = Vc * (1 + k12 / k21).
  double get vss => vc + vp;

  /// Fast disposition / distribution hybrid rate constant (alpha > beta).
  ///
  /// Roots of the characteristic quadratic equation:
  /// lambda^2 + (k10 + k12 + k21)*lambda + k10*k21 = 0
  double get alpha {
    final s = k10 + k12 + k21;
    final p = k10 * k21;
    final discriminant = max(0.0, s * s - 4.0 * p);
    return (s + sqrt(discriminant)) / 2.0;
  }

  /// Slow disposition / terminal elimination hybrid rate constant (beta < alpha).
  double get beta {
    final s = k10 + k12 + k21;
    final p = k10 * k21;
    final discriminant = max(0.0, s * s - 4.0 * p);
    return (s - sqrt(discriminant)) / 2.0;
  }

  /// Distribution half-life in hours: t1/2,alpha = ln(2) / alpha.
  double get distributionHalfLife => log(2) / alpha;

  /// Terminal elimination half-life in hours: t1/2,beta = ln(2) / beta.
  double get eliminationHalfLife => log(2) / beta;

  /// Terminal elimination phase volume of distribution: V_beta = Cl / beta.
  double get vBeta => beta > 0 ? clearance / beta : vss;

  /// Creates a copy with optional overridden fields.
  TwoCompartmentParameters copyWith({
    double? vc,
    double? k10,
    double? k12,
    double? k21,
    double? ka,
    double? bioavailability,
  }) {
    return TwoCompartmentParameters(
      vc: vc ?? this.vc,
      k10: k10 ?? this.k10,
      k12: k12 ?? this.k12,
      k21: k21 ?? this.k21,
      ka: ka ?? this.ka,
      bioavailability: bioavailability ?? this.bioavailability,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TwoCompartmentParameters &&
          runtimeType == other.runtimeType &&
          vc == other.vc &&
          k10 == other.k10 &&
          k12 == other.k12 &&
          k21 == other.k21 &&
          ka == other.ka &&
          bioavailability == other.bioavailability;

  @override
  int get hashCode => Object.hash(vc, k10, k12, k21, ka, bioavailability);

  @override
  String toString() =>
      'TwoCompartmentParameters(vc: $vc L, k10: $k10, k12: $k12, k21: $k21, alpha: ${alpha.toStringAsFixed(3)}, beta: ${beta.toStringAsFixed(3)}, t1/2,alpha: ${distributionHalfLife.toStringAsFixed(2)} hr, t1/2,beta: ${eliminationHalfLife.toStringAsFixed(2)} hr)';
}

/// Clinical therapeutic target window for safety and efficacy visualization.
class TherapeuticWindow {
  /// Minimum Effective Concentration in mg/L (MEC).
  final double mec;

  /// Minimum Toxic Concentration in mg/L (MTC).
  final double mtc;

  /// Target steady-state trough minimum in mg/L (optional).
  final double? targetTroughMin;

  /// Target steady-state trough maximum in mg/L (optional).
  final double? targetTroughMax;

  /// Target steady-state peak minimum in mg/L (optional).
  final double? targetPeakMin;

  /// Target steady-state peak maximum in mg/L (optional).
  final double? targetPeakMax;

  /// Target 24-hour AUC minimum in mg·hr/L (e.g. 400 for Vancomycin).
  final double? targetAuc24Min;

  /// Target 24-hour AUC maximum in mg·hr/L (e.g. 600 for Vancomycin).
  final double? targetAuc24Max;

  /// Creates a validated [TherapeuticWindow].
  const TherapeuticWindow({
    required this.mec,
    required this.mtc,
    this.targetTroughMin,
    this.targetTroughMax,
    this.targetPeakMin,
    this.targetPeakMax,
    this.targetAuc24Min,
    this.targetAuc24Max,
  });

  /// Validates window thresholds.
  void validate() {
    if (mec.isNaN || !mec.isFinite || mec < 0) {
      throw ArgumentError.value(mec, 'mec', 'MEC must be finite and >= 0');
    }
    if (mtc.isNaN || !mtc.isFinite || mtc <= mec) {
      throw ArgumentError.value(mtc, 'mtc', 'MTC must be finite and strictly greater than MEC');
    }
  }

  /// Classifies a concentration into its corresponding [TherapeuticZone].
  TherapeuticZone classify(double concentration) {
    if (concentration > mtc) {
      return TherapeuticZone.toxic;
    } else if (concentration < mec) {
      return TherapeuticZone.subTherapeutic;
    } else {
      return TherapeuticZone.therapeutic;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TherapeuticWindow &&
          runtimeType == other.runtimeType &&
          mec == other.mec &&
          mtc == other.mtc &&
          targetTroughMin == other.targetTroughMin &&
          targetTroughMax == other.targetTroughMax &&
          targetPeakMin == other.targetPeakMin &&
          targetPeakMax == other.targetPeakMax &&
          targetAuc24Min == other.targetAuc24Min &&
          targetAuc24Max == other.targetAuc24Max;

  @override
  int get hashCode => Object.hash(
        mec,
        mtc,
        targetTroughMin,
        targetTroughMax,
        targetPeakMin,
        targetPeakMax,
        targetAuc24Min,
        targetAuc24Max,
      );

  @override
  String toString() => 'TherapeuticWindow(mec: $mec mg/L, mtc: $mtc mg/L)';
}

/// A discrete coordinate on a concentration-time simulation curve.
class PkDataPoint {
  /// Elapsed simulation time in hours.
  final double timeHours;

  /// Serum drug concentration in mg/L (mcg/mL).
  final double concentrationMgL;

  /// True during active intravenous infusion delivery.
  final bool isInfusing;

  /// Clinical therapeutic zone classification at this coordinate.
  final TherapeuticZone? zone;

  /// Creates a single immutable [PkDataPoint].
  const PkDataPoint({
    required this.timeHours,
    required this.concentrationMgL,
    this.isInfusing = false,
    this.zone,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PkDataPoint &&
          runtimeType == other.runtimeType &&
          (timeHours - other.timeHours).abs() < 1e-9 &&
          (concentrationMgL - other.concentrationMgL).abs() < 1e-9 &&
          isInfusing == other.isInfusing &&
          zone == other.zone;

  @override
  int get hashCode => Object.hash(timeHours, concentrationMgL, isInfusing, zone);

  @override
  String toString() =>
      'PkDataPoint(t: ${timeHours.toStringAsFixed(2)}h, C: ${concentrationMgL.toStringAsFixed(2)} mg/L, infusing: $isInfusing, zone: $zone)';
}

/// Complete parameter specification for executing a PK simulation.
class PkSimulationParams {
  /// Compartment architecture (oneCompartment or twoCompartment).
  final PkModelType modelType;

  /// Route of administration.
  final AdministrationRoute route;

  /// Administered dose in mg (must be > 0 for bolus, intermittent infusion, oral).
  final double dose;

  /// Dosing interval tau in hours (must be > 0).
  final double tau;

  /// Duration of intermittent intravenous infusion in hours (0 < tInf < tau).
  final double tInf;

  /// Continuous infusion delivery rate in mg/hr (for continuousInfusion route).
  final double continuousRate;

  /// Initial baseline concentration at t=0 in mg/L (default 0.0).
  final double cStart;

  /// 1-compartment pharmacokinetic parameters (required if modelType is oneCompartment).
  final PkParameters? pk1;

  /// 2-compartment pharmacokinetic parameters (required if modelType is twoCompartment).
  final TwoCompartmentParameters? pk2;

  /// Target therapeutic window for zone classification and safety guardrails.
  final TherapeuticWindow? therapeuticWindow;

  /// Number of doses to simulate (>= 1).
  final int numberOfDoses;

  /// When true, models steady-state superposition (N -> infinity).
  final bool isSteadyState;

  /// Total simulation time horizon in hours.
  final double horizonHours;

  /// Number of sampling points generated per phase (inflow and elimination).
  final int pointsPerPhase;

  /// Flag indicating whether the drug possesses a prolonged alpha distribution phase (e.g. Digoxin).
  final bool hasDistributionPhaseWarning;

  /// Safe distribution equilibrium wait time in hours (default 6.0 for Digoxin).
  final double distributionSafeHours;

  /// Creates a validated, immutable [PkSimulationParams] payload.
  const PkSimulationParams({
    this.modelType = PkModelType.oneCompartment,
    required this.route,
    this.dose = 0.0,
    this.tau = 24.0,
    this.tInf = 1.0,
    this.continuousRate = 0.0,
    this.cStart = 0.0,
    this.pk1,
    this.pk2,
    this.therapeuticWindow,
    this.numberOfDoses = 1,
    this.isSteadyState = true,
    this.horizonHours = 24.0,
    this.pointsPerPhase = 50,
    this.hasDistributionPhaseWarning = false,
    this.distributionSafeHours = 6.0,
  });

  /// Validates all parameters and enforces physical and clinical consistency.
  void validate() {
    if (horizonHours.isNaN || !horizonHours.isFinite || horizonHours <= 0) {
      throw ArgumentError.value(horizonHours, 'horizonHours', 'Simulation horizon must be finite and > 0');
    }
    if (pointsPerPhase < 5) {
      throw ArgumentError.value(pointsPerPhase, 'pointsPerPhase', 'Points per phase must be >= 5');
    }
    if (cStart.isNaN || !cStart.isFinite || cStart < 0) {
      throw ArgumentError.value(cStart, 'cStart', 'Starting concentration must be finite and >= 0');
    }

    if (route == AdministrationRoute.continuousInfusion) {
      if (continuousRate.isNaN || !continuousRate.isFinite || continuousRate <= 0) {
        throw ArgumentError.value(continuousRate, 'continuousRate', 'Continuous infusion rate must be finite and > 0');
      }
    } else {
      if (dose.isNaN || !dose.isFinite || dose <= 0) {
        throw ArgumentError.value(dose, 'dose', 'Dose must be finite and > 0');
      }
      if (tau.isNaN || !tau.isFinite || tau <= 0) {
        throw ArgumentError.value(tau, 'tau', 'Dosing interval tau must be finite and > 0');
      }
    }

    if (route == AdministrationRoute.ivIntermittentInfusion) {
      if (tInf.isNaN || !tInf.isFinite || tInf <= 0) {
        throw ArgumentError.value(tInf, 'tInf', 'Infusion duration tInf must be finite and > 0');
      }
      if (tInf >= tau) {
        throw ArgumentError('Dosing interval tau ($tau h) must be strictly greater than infusion duration tInf ($tInf h)');
      }
    }

    if (modelType == PkModelType.oneCompartment) {
      if (pk1 == null) {
        throw ArgumentError('pk1 parameters must be provided when modelType is oneCompartment');
      }
      pk1!.validate();
    } else {
      if (pk2 == null) {
        throw ArgumentError('pk2 parameters must be provided when modelType is twoCompartment');
      }
      pk2!.validate();
    }

    if (therapeuticWindow != null) {
      therapeuticWindow!.validate();
    }

    if (numberOfDoses < 1) {
      throw ArgumentError.value(numberOfDoses, 'numberOfDoses', 'Number of doses must be >= 1');
    }
  }

  /// Creates a copy with optional overridden properties.
  PkSimulationParams copyWith({
    PkModelType? modelType,
    AdministrationRoute? route,
    double? dose,
    double? tau,
    double? tInf,
    double? continuousRate,
    double? cStart,
    PkParameters? pk1,
    TwoCompartmentParameters? pk2,
    TherapeuticWindow? therapeuticWindow,
    int? numberOfDoses,
    bool? isSteadyState,
    double? horizonHours,
    int? pointsPerPhase,
    bool? hasDistributionPhaseWarning,
    double? distributionSafeHours,
  }) {
    return PkSimulationParams(
      modelType: modelType ?? this.modelType,
      route: route ?? this.route,
      dose: dose ?? this.dose,
      tau: tau ?? this.tau,
      tInf: tInf ?? this.tInf,
      continuousRate: continuousRate ?? this.continuousRate,
      cStart: cStart ?? this.cStart,
      pk1: pk1 ?? this.pk1,
      pk2: pk2 ?? this.pk2,
      therapeuticWindow: therapeuticWindow ?? this.therapeuticWindow,
      numberOfDoses: numberOfDoses ?? this.numberOfDoses,
      isSteadyState: isSteadyState ?? this.isSteadyState,
      horizonHours: horizonHours ?? this.horizonHours,
      pointsPerPhase: pointsPerPhase ?? this.pointsPerPhase,
      hasDistributionPhaseWarning: hasDistributionPhaseWarning ?? this.hasDistributionPhaseWarning,
      distributionSafeHours: distributionSafeHours ?? this.distributionSafeHours,
    );
  }
}

/// The complete deterministic result of a pharmacokinetic simulation.
class PkSimulationResult {
  /// Input parameters utilized to generate this simulation.
  final PkSimulationParams params;

  /// High-resolution piecewise concentration-time coordinate points.
  final List<PkDataPoint> curve;

  /// Maximum concentration achieved across the simulation horizon (mg/L).
  final double cMax;

  /// Minimum / trough concentration prior to redosing at steady-state or end of cycle (mg/L).
  final double cMin;

  /// Time in hours at which the peak concentration occurs.
  final double tMax;

  /// 24-hour area under the curve in mg·hr/L.
  final double auc0To24;

  /// Total trapezoidal area under the curve across the entire simulation horizon in mg·hr/L.
  final double aucTotal;

  /// Effective elimination rate constant in hr^-1.
  final double ke;

  /// Effective elimination half-life in hours.
  final double tHalf;

  /// Accumulation factor R = 1 / (1 - exp(-ke * tau)).
  final double accumulationFactor;

  /// True if blood level sampling is within the alpha distribution phase for NTI drugs (e.g. Digoxin < 6h).
  final bool hasDistributionPhaseWarning;

  /// Human-readable clinical advisory for distribution phase sampling.
  final String? distributionPhaseWarningMessage;

  /// True if calculated peak exceeds the Minimum Toxic Concentration (Rule 5 Non-blocking Overdose Policy).
  final bool hasOverdoseWarning;

  /// Structured clinical warning for overdose threshold breach.
  final String? overdoseWarningMessage;

  /// Creates an immutable [PkSimulationResult].
  const PkSimulationResult({
    required this.params,
    required this.curve,
    required this.cMax,
    required this.cMin,
    required this.tMax,
    required this.auc0To24,
    required this.aucTotal,
    required this.ke,
    required this.tHalf,
    required this.accumulationFactor,
    this.hasDistributionPhaseWarning = false,
    this.distributionPhaseWarningMessage,
    this.hasOverdoseWarning = false,
    this.overdoseWarningMessage,
  });

  @override
  String toString() =>
      'PkSimulationResult(Cmax: ${cMax.toStringAsFixed(2)} mg/L, Cmin: ${cMin.toStringAsFixed(2)} mg/L, Tmax: ${tMax.toStringAsFixed(2)}h, AUC24: ${auc0To24.toStringAsFixed(1)} mg·hr/L, t1/2: ${tHalf.toStringAsFixed(2)}h, overdose: $hasOverdoseWarning)';
}

/// Comparative delta metrics between a baseline and an adjusted regimen.
class PkSimulationComparison {
  /// Baseline / current regimen simulation result.
  final PkSimulationResult baseline;

  /// Adjusted / proposed regimen simulation result.
  final PkSimulationResult adjusted;

  /// Delta peak concentration: adjusted.cMax - baseline.cMax (mg/L).
  final double deltaCMax;

  /// Delta trough concentration: adjusted.cMin - baseline.cMin (mg/L).
  final double deltaCMin;

  /// Delta 24-hour AUC: adjusted.auc0To24 - baseline.auc0To24 (mg·hr/L).
  final double deltaAuc24;

  /// Delta elimination half-life in hours.
  final double deltaTHalf;

  /// Percent change in Cmax: ((adjusted.cMax - baseline.cMax) / baseline.cMax) * 100.
  final double percentChangeCMax;

  /// Percent change in Cmin: ((adjusted.cMin - baseline.cMin) / baseline.cMin) * 100.
  final double percentChangeCMin;

  /// Percent change in AUC24: ((adjusted.auc0To24 - baseline.auc0To24) / baseline.auc0To24) * 100.
  final double percentChangeAuc24;

  /// Creates an immutable [PkSimulationComparison].
  const PkSimulationComparison({
    required this.baseline,
    required this.adjusted,
    required this.deltaCMax,
    required this.deltaCMin,
    required this.deltaAuc24,
    required this.deltaTHalf,
    required this.percentChangeCMax,
    required this.percentChangeCMin,
    required this.percentChangeAuc24,
  });

  @override
  String toString() =>
      'PkSimulationComparison(ΔCmax: ${deltaCMax > 0 ? "+$deltaCMax" : "$deltaCMax"} mg/L ($percentChangeCMax%), ΔCmin: ${deltaCMin > 0 ? "+$deltaCMin" : "$deltaCMin"} mg/L ($percentChangeCMin%), ΔAUC24: ${deltaAuc24 > 0 ? "+$deltaAuc24" : "$deltaAuc24"} mg·hr/L ($percentChangeAuc24%))';
}
