import 'dart:math';

/// A deterministic calculator for Pharmacokinetics (PK) and Therapeutic Drug Monitoring (TDM).
/// Implements standard one-compartment steady-state equations for intermittent intravenous infusions.
///
/// Population Pharmacokinetic Model:
/// - Elimination rate constant (Ke) uses Matzke's linear regression model based on CrCl:
///     Ke (hr^-1) = 0.00083 * CrCl (mL/min) + 0.0044
/// - Target AUC24: 400–600 mg·hr/L for serious MRSA infections.
///
/// Primary Source Citations:
/// 1. Matzke GR, McGory RW, Halstenson CE, Keane WF. Pharmacokinetics of vancomycin in patients with
///    various degrees of renal function. Antimicrob Agents Chemother. 1984;25(4):433-437.
/// 2. Rybak MJ, Le J, Lodise TP, et al. Therapeutic monitoring of vancomycin for serious methicillin-
///    resistant Staphylococcus aureus infections: A revised consensus guideline and review by
///    ASHP/IDSA/PIDS/SIDP. Am J Health-Syst Pharm. 2020;77(11):835-864.
/// 3. Sawchuk RJ, Zaske DE. Pharmacokinetics of aminoglycosides in post-burn patients.
///    J Pharmacokinet Biopharm. 1976;4(2):183-195.
class TdmCalculator {
  const TdmCalculator._();

  /// Calculates Volume of Distribution (Vd) for Vancomycin.
  /// Typically 0.7 L/kg based on Total Body Weight (TBW).
  ///
  /// Returns Vd in Liters. Throws [ArgumentError] if [weightKg] <= 0.
  static double calculateVd({required double weightKg}) {
    return calculateVdWithModel(
      weightKg: weightKg,
      model: VancomycinVdModel.standardAdult,
    );
  }

  /// Calculates Volume of Distribution (Vd) for Vancomycin using a selected
  /// clinical population model:
  /// - [VancomycinVdModel.standardAdult]: 0.70 L/kg TBW (Bauer / Matzke standard)
  /// - [VancomycinVdModel.obesity]: 0.52 L/kg TBW (PENDING citation verification — value observed in ClinCalc obesity model via REA)
  /// - [VancomycinVdModel.criticallyIllIcu]: 0.85 L/kg TBW (PENDING citation verification — ICU Vd expansion observed in VancoPK via REA)
  static double calculateVdWithModel({
    required double weightKg,
    VancomycinVdModel model = VancomycinVdModel.standardAdult,
  }) {
    if (weightKg <= 0) {
      throw ArgumentError.value(weightKg, 'weightKg', 'Weight must be > 0');
    }
    return model.litersPerKg * weightKg;
  }

  /// Calculates Dosing Weight (kg) for Aminoglycosides (Gentamicin, Amikacin):
  /// - Ideal Body Weight (IBW, Devine 1974):
  ///     Male: 50 + 2.3 * (height_inches - 60)
  ///     Female: 45.5 + 2.3 * (height_inches - 60)
  /// - If TBW < IBW: uses TBW.
  /// - If TBW >= 1.2 * IBW (obese): uses Adjusted Body Weight:
  ///     AdjBW = IBW + 0.4 * (TBW - IBW)
  /// - Otherwise: uses IBW.
  static double calculateAminoglycosideDosingWeight({
    required double weightKg,
    required double heightCm,
    required bool isMale,
  }) {
    if (weightKg <= 0) {
      throw ArgumentError.value(weightKg, 'weightKg', 'Weight must be > 0');
    }
    if (heightCm <= 0) {
      throw ArgumentError.value(heightCm, 'heightCm', 'Height must be > 0');
    }
    final heightInches = heightCm / 2.54;
    final baseKg = isMale ? 50.0 : 45.5;
    final ibw = heightInches > 60.0
        ? baseKg + 2.3 * (heightInches - 60.0)
        : max(10.0, baseKg - 2.3 * (60.0 - heightInches));

    if (weightKg < ibw) {
      return weightKg;
    }
    if (weightKg >= 1.2 * ibw) {
      return ibw + 0.4 * (weightKg - ibw);
    }
    return ibw;
  }

  /// Calculates Volume of Distribution (Vd) for Aminoglycosides (Gentamicin, Amikacin).
  /// Standard extracellular fluid Vd = 0.25 L/kg of Aminoglycoside Dosing Weight.
  ///
  /// Reference: Bauer LA. Applied Clinical Pharmacokinetics; Sawchuk RJ, Zaske DE. 1976.
  static double calculateAminoglycosideVd({required double dosingWeightKg}) {
    if (dosingWeightKg <= 0) {
      throw ArgumentError.value(
        dosingWeightKg,
        'dosingWeightKg',
        'Dosing weight must be > 0',
      );
    }
    return 0.25 * dosingWeightKg;
  }

  /// Calculates Elimination Rate Constant (Ke, hr^-1) for Aminoglycosides
  /// (Gentamicin, Tobramycin, Amikacin) using the Sawchuk-Zaske / Bauer linear regression model:
  ///   Ke (hr^-1) = 0.00293 * CrCl (mL/min) + 0.014
  ///
  /// For anuric patients (CrCl = 0), non-renal baseline Ke is 0.014 hr^-1.
  static double calculateAminoglycosideKe({required double crclMlMin}) {
    if (crclMlMin < 0) {
      throw ArgumentError.value(
        crclMlMin,
        'crclMlMin',
        'CrCl cannot be negative',
      );
    }
    return (0.00293 * crclMlMin) + 0.014;
  }

  /// Calculates Elimination Rate Constant (Ke) based on Creatinine Clearance (CrCl)
  /// using Matzke's population regression model:
  ///   Ke (hr^-1) = (0.00083 * CrCl) + 0.0044
  ///
  /// CrCl must be in mL/min. For anuric patients (CrCl = 0), baseline Ke is 0.0044 hr^-1.
  /// Throws [ArgumentError] if [crclMlMin] < 0.
  static double calculateKe({required double crclMlMin}) {
    if (crclMlMin < 0) {
      throw ArgumentError.value(crclMlMin, 'crclMlMin', 'CrCl cannot be negative');
    }
    if (crclMlMin == 0) return 0.0044; // minimum Ke for anuric
    return (0.00083 * crclMlMin) + 0.0044;
  }

  /// Calculates Half-life (t1/2) from Ke.
  /// Formula: t1/2 = ln(2) / Ke
  ///
  /// Returns t1/2 in hours. Throws [ArgumentError] if [ke] <= 0.
  static double calculateHalfLife({required double ke}) {
    if (ke <= 0) {
      throw ArgumentError.value(ke, 'ke', 'Ke must be > 0');
    }
    return ln2 / ke; // ln2 = 0.693147...
  }

  /// Calculates a recommended Loading Dose.
  /// Usually 25-30 mg/kg based on Actual Body Weight.
  /// Returns [minDose, maxDose] capped at max limit (e.g. 3000 mg).
  static List<double> calculateLoadingDose({
    required double weightKg,
    double minMgPerKg = 25.0,
    double maxMgPerKg = 30.0,
    double absoluteMaxMg = 3000.0,
  }) {
    if (weightKg <= 0) {
      throw ArgumentError.value(weightKg, 'weightKg', 'Weight must be > 0');
    }
    double minVal = weightKg * minMgPerKg;
    double maxVal = weightKg * maxMgPerKg;

    if (minVal > absoluteMaxMg) minVal = absoluteMaxMg;
    if (maxVal > absoluteMaxMg) maxVal = absoluteMaxMg;

    return [minVal, maxVal];
  }

  /// Predicts the steady-state Peak concentration (Cmax,ss) at the end of infusion (t = t_inf).
  /// Using One-compartment intermittent IV infusion steady-state equation:
  ///   Cmax,ss = (Dose / (t_inf * Vd * Ke)) * (1 - e^(-Ke * t_inf)) / (1 - e^(-Ke * tau))
  ///
  /// [dose] in mg, [tau] in hours (interval), [tInf] in hours (infusion time).
  /// Requires [tInf] > 0 and [tau] > [tInf].
  static double predictPeak({
    required double dose,
    required double tau,
    required double tInf,
    required double vd,
    required double ke,
  }) {
    if (dose <= 0) throw ArgumentError.value(dose, 'dose', 'Dose must be > 0');
    if (tInf <= 0) throw ArgumentError.value(tInf, 'tInf', 'Infusion time (tInf) must be > 0');
    if (tau <= tInf) {
      throw ArgumentError.value(
        tau,
        'tau',
        'Dosing interval (tau=$tau) must be strictly greater than infusion time (tInf=$tInf)',
      );
    }
    if (vd <= 0) throw ArgumentError.value(vd, 'vd', 'Vd must be > 0');
    if (ke <= 0) throw ArgumentError.value(ke, 'ke', 'Ke must be > 0');

    return (dose / (tInf * vd * ke)) *
        (1 - exp(-ke * tInf)) /
        (1 - exp(-ke * tau));
  }

  /// Predicts the Trough concentration for a given dosing regimen.
  /// Using One-compartment steady-state equations:
  ///   Peak = (Dose / (t_inf * Vd * Ke)) * (1 - e^(-Ke * t_inf)) / (1 - e^(-Ke * tau))
  ///   Trough = Peak * e^(-Ke * (tau - t_inf))
  ///
  /// [dose] in mg, [tau] in hours (interval), [tInf] in hours (infusion time).
  /// Requires [tInf] > 0 and [tau] > [tInf].
  static double predictTrough({
    required double dose,
    required double tau,
    required double tInf,
    required double vd,
    required double ke,
  }) {
    final peakSS = predictPeak(
      dose: dose,
      tau: tau,
      tInf: tInf,
      vd: vd,
      ke: ke,
    );
    return peakSS * exp(-ke * (tau - tInf));
  }

  /// Predicts the Trough concentration given an infusion duration in minutes ([infusionDurationMinutes]).
  ///
  /// Cohesion Helper: Explicitly converts minutes to hours (`tInf = infusionDurationMinutes / 60.0`)
  /// preventing unit mismatch bugs when callers pass duration in minutes.
  static double predictTroughFromMinutes({
    required double dose,
    required double tau,
    required double infusionDurationMinutes,
    required double vd,
    required double ke,
  }) {
    if (infusionDurationMinutes <= 0) {
      throw ArgumentError.value(
        infusionDurationMinutes,
        'infusionDurationMinutes',
        'Infusion duration in minutes must be > 0',
      );
    }
    return predictTrough(
      dose: dose,
      tau: tau,
      tInf: infusionDurationMinutes / 60.0,
      vd: vd,
      ke: ke,
    );
  }

  /// Calculates 24-hour Area Under the Curve (AUC24) for Vancomycin at steady state.
  /// Formula: AUC24 = Daily Dose / Clearance = (Dose * (24 / tau)) / (Vd * Ke)
  ///
  /// Target: 400–600 mg·hr/L per ASHP/IDSA/PIDS/SIDP 2020 Guidelines.
  static double calculateAuc24({
    required double dose,
    required double tau,
    required double vd,
    required double ke,
  }) {
    if (dose <= 0) throw ArgumentError.value(dose, 'dose', 'Dose must be > 0');
    if (tau <= 0) throw ArgumentError.value(tau, 'tau', 'Interval (tau) must be > 0');
    if (vd <= 0) throw ArgumentError.value(vd, 'vd', 'Vd must be > 0');
    if (ke <= 0) throw ArgumentError.value(ke, 'ke', 'Ke must be > 0');

    final dailyDose = dose * (24.0 / tau);
    final clearanceLPerHr = vd * ke;
    return dailyDose / clearanceLPerHr;
  }

  /// Calculates the patient's individual Elimination Rate Constant (Ke) from two
  /// post-infusion serum concentration measurements using the Sawchuk-Zaske method.
  ///
  /// Formula: Ke = ln(C1 / C2) / deltaHours
  ///
  /// Where [c1] is the earlier concentration (e.g. post-infusion peak),
  /// [c2] is the later concentration (e.g. pre-dose trough), and [deltaHours]
  /// is the elapsed time in hours between the two draws (deltaHours > 0).
  ///
  /// Reference: Sawchuk RJ, Zaske DE. J Pharmacokinet Biopharm. 1976;4(2):183-195.
  static double calculateIndividualKe({
    required double c1,
    required double c2,
    required double deltaHours,
  }) {
    if (c1 <= 0) throw ArgumentError.value(c1, 'c1', 'Earlier concentration C1 must be > 0');
    if (c2 <= 0) throw ArgumentError.value(c2, 'c2', 'Later concentration C2 must be > 0');
    if (c1 <= c2) {
      throw ArgumentError.value(
        c2,
        'c2',
        'Earlier concentration C1 ($c1) must be strictly greater than later concentration C2 ($c2)',
      );
    }
    if (deltaHours <= 0) {
      throw ArgumentError.value(deltaHours, 'deltaHours', 'Time difference between draws must be > 0 hours');
    }

    return log(c1 / c2) / deltaHours;
  }

  /// Recommends the maintenance dose in mg required to achieve a specific [targetAuc]
  /// (e.g. 400–600 mg·hr/L for Vancomycin) at steady state for a given interval [tau].
  ///
  /// Derived from AUC24 = (Dose * (24 / tau)) / (Vd * Ke):
  ///   Recommended Dose = (targetAuc * Vd * Ke) / (24 / tau)
  ///
  /// Reference: Rybak MJ et al. Am J Health-Syst Pharm. 2020;77(11):835-864.
  static double recommendDoseForTargetAuc24({
    required double targetAuc,
    required double tau,
    required double vd,
    required double ke,
  }) {
    if (targetAuc <= 0) throw ArgumentError.value(targetAuc, 'targetAuc', 'Target AUC must be > 0');
    if (tau <= 0) throw ArgumentError.value(tau, 'tau', 'Dosing interval tau must be > 0');
    if (vd <= 0) throw ArgumentError.value(vd, 'vd', 'Vd must be > 0');
    if (ke <= 0) throw ArgumentError.value(ke, 'ke', 'Ke must be > 0');

    final dosesPerDay = 24.0 / tau;
    final clearanceLPerHr = vd * ke;
    return (targetAuc * clearanceLPerHr) / dosesPerDay;
  }

  /// Calculates the steady-state serum concentration C_ss(t) in mg/L at time [timeHours] (t >= 0)
  /// within a one-compartment intermittent IV infusion dosing regimen.
  ///
  /// Within each dosing interval [0, tau]:
  /// - During infusion (0 <= t_cycle <= tInf):
  ///     C_ss(t_cycle) = Cmin,ss * e^(-Ke * t_cycle) + (Dose / (tInf * Vd * Ke)) * (1 - e^(-Ke * t_cycle))
  /// - Post-infusion elimination phase (tInf < t_cycle <= tau):
  ///     C_ss(t_cycle) = Cmax,ss * e^(-Ke * (t_cycle - tInf))
  static double concentrationAtSteadyStateTime({
    required double timeHours,
    required double dose,
    required double tau,
    required double tInf,
    required double vd,
    required double ke,
  }) {
    if (timeHours < 0) {
      throw ArgumentError.value(timeHours, 'timeHours', 'Time must be >= 0');
    }
    final peakSS = predictPeak(
      dose: dose,
      tau: tau,
      tInf: tInf,
      vd: vd,
      ke: ke,
    );
    final troughSS = peakSS * exp(-ke * (tau - tInf));

    // Normalize time into the current [0, tau] dosing cycle
    double tCycle = timeHours % tau;
    if (tCycle < 1e-9 && timeHours > 0) {
      tCycle = 0.0; // End of cycle equals trough Cmin,ss
    }

    if (tCycle <= tInf) {
      final infCoeff = dose / (tInf * vd * ke);
      return troughSS * exp(-ke * tCycle) + infCoeff * (1 - exp(-ke * tCycle));
    } else {
      return peakSS * exp(-ke * (tCycle - tInf));
    }
  }

  /// Generates a complete deterministic [SteadyStatePkProfile] including Cmax,ss, Cmin,ss,
  /// AUC24, infusion rate safety check, and high-resolution concentration-time curves
  /// for both a single dosing interval [0, tau] and a 24-hour window [0, max(24, tau)].
  static SteadyStatePkProfile generateSteadyStateProfile({
    required double dose,
    required double tau,
    required double tInf,
    required double vd,
    required double ke,
    int pointsPerPhase = 24,
  }) {
    if (pointsPerPhase < 2) {
      throw ArgumentError.value(pointsPerPhase, 'pointsPerPhase', 'Must be >= 2');
    }

    final peakSS = predictPeak(
      dose: dose,
      tau: tau,
      tInf: tInf,
      vd: vd,
      ke: ke,
    );
    final troughSS = peakSS * exp(-ke * (tau - tInf));
    final auc24 = calculateAuc24(
      dose: dose,
      tau: tau,
      vd: vd,
      ke: ke,
    );
    final aucTau = dose / (vd * ke);
    final infusionRateMgPerMin = dose / (tInf * 60.0);

    List<PkDataPoint> buildIntervalCurve(double startHour) {
      final pts = <PkDataPoint>[];
      // 1. Infusion phase: [0, tInf]
      for (var i = 0; i <= pointsPerPhase; i++) {
        final localT = (tInf * i) / pointsPerPhase;
        final c = concentrationAtSteadyStateTime(
          timeHours: localT,
          dose: dose,
          tau: tau,
          tInf: tInf,
          vd: vd,
          ke: ke,
        );
        pts.add(
          PkDataPoint(
            timeHours: startHour + localT,
            concentrationMgL: c,
            isInfusing: true,
          ),
        );
      }
      // 2. Post-infusion elimination phase: (tInf, tau]
      final elimDuration = tau - tInf;
      for (var i = 1; i <= pointsPerPhase; i++) {
        final localT = tInf + (elimDuration * i) / pointsPerPhase;
        final c = peakSS * exp(-ke * (localT - tInf));
        pts.add(
          PkDataPoint(
            timeHours: startHour + localT,
            concentrationMgL: c,
            isInfusing: false,
          ),
        );
      }
      return pts;
    }

    final singleIntervalCurve = buildIntervalCurve(0.0);

    final horizonHours = tau > 24.0 ? tau : 24.0;
    final numCycles = (horizonHours / tau).ceil();
    final twentyFourHourCurve = <PkDataPoint>[];
    for (var cycle = 0; cycle < numCycles; cycle++) {
      final cycleStart = cycle * tau;
      final cyclePts = buildIntervalCurve(cycleStart);
      for (final p in cyclePts) {
        if (p.timeHours <= horizonHours + 1e-9) {
          if (twentyFourHourCurve.isNotEmpty &&
              (twentyFourHourCurve.last.timeHours - p.timeHours).abs() < 1e-9) {
            continue;
          }
          twentyFourHourCurve.add(p);
        }
      }
    }

    return SteadyStatePkProfile(
      peakMgL: peakSS,
      troughMgL: troughSS,
      aucTauMgHrL: aucTau,
      auc24MgHrL: auc24,
      tauHours: tau,
      tInfHours: tInf,
      infusionRateMgPerMin: infusionRateMgPerMin,
      hasRedManSyndromeRisk: infusionRateMgPerMin > 10.0,
      singleIntervalCurve: singleIntervalCurve,
      twentyFourHourCurve: twentyFourHourCurve,
    );
  }

  /// Performs a complete deterministic Two-Point Sawchuk-Zaske Individualized PK Analysis
  /// from two measured post-infusion serum concentrations ([c1] and [c2]).
  ///
  /// Equations (Sawchuk RJ, Zaske DE. J Pharmacokinet Biopharm 1976;4:183-195;
  /// Bauer LA. Applied Clinical Pharmacokinetics):
  /// - Individual elimination rate constant:
  ///     Ke = ln(C1 / C2) / deltaHours
  /// - Individual half-life:
  ///     t1/2 = ln(2) / Ke
  /// - True back-extrapolated Peak at completion of infusion (t = tInf):
  ///     Cmax,true = C1 * e^(Ke * t1PostInfusionHours)
  /// - True forward-extrapolated Trough at end of dosing interval (t = tau):
  ///     Cmin,true = Cmax,true * e^(-Ke * (tau - tInf))
  /// - Individual Volume of Distribution (Vd, Liters) at steady state:
  ///     Vd = (Dose * (1 - e^(-Ke * tInf))) / (tInf * Ke * (Cmax,true - Cmin,true * e^(-Ke * tInf)))
  /// - Individual Clearance (CL, L/hr):
  ///     CL = Vd * Ke
  /// - Individual 24-hour AUC (AUC24, mg·hr/L):
  ///     AUC24 = (Dose * (24 / tau)) / (Vd * Ke)
  static SawchukZaskeAnalysis analyzeTwoPointSawchukZaske({
    required double dose,
    required double tau,
    required double tInf,
    required double c1,
    required double c2,
    required double deltaHours,
    double t1PostInfusionHours = 1.0,
    bool isVancomycin = true,
  }) {
    if (dose <= 0) throw ArgumentError.value(dose, 'dose', 'Dose must be > 0');
    if (tInf <= 0) throw ArgumentError.value(tInf, 'tInf', 'tInf must be > 0');
    if (tau <= tInf) {
      throw ArgumentError.value(
        tau,
        'tau',
        'Interval tau ($tau) must be > infusion time tInf ($tInf)',
      );
    }
    if (t1PostInfusionHours < 0) {
      throw ArgumentError.value(
        t1PostInfusionHours,
        't1PostInfusionHours',
        't1PostInfusionHours must be >= 0',
      );
    }

    final ke = calculateIndividualKe(
      c1: c1,
      c2: c2,
      deltaHours: deltaHours,
    );
    final halfLife = calculateHalfLife(ke: ke);

    // Back-extrapolate true Cmax at end of infusion (t = tInf)
    final truePeakMgL = c1 * exp(ke * t1PostInfusionHours);
    // Forward-extrapolate true Cmin at end of dosing interval (t = tau)
    final trueTroughMgL = truePeakMgL * exp(-ke * (tau - tInf));

    // Individual Vd at steady state
    final denominator =
        tInf * ke * (truePeakMgL - trueTroughMgL * exp(-ke * tInf));
    if (denominator <= 0) {
      throw StateError(
        'Invalid steady-state Sawchuk-Zaske denominator ($denominator)',
      );
    }
    final individualVdL = (dose * (1.0 - exp(-ke * tInf))) / denominator;
    final individualClearanceLPerHr = individualVdL * ke;
    final individualAuc24MgHrL = calculateAuc24(
      dose: dose,
      tau: tau,
      vd: individualVdL,
      ke: ke,
    );

    return SawchukZaskeAnalysis(
      individualKe: ke,
      individualHalfLifeHours: halfLife,
      individualVdLiters: individualVdL,
      individualClearanceLPerHr: individualClearanceLPerHr,
      truePeakMgL: truePeakMgL,
      trueTroughMgL: trueTroughMgL,
      individualAuc24MgHrL: individualAuc24MgHrL,
      hasShortSamplingIntervalWarning: deltaHours < 2.0,
      hasDistributionPhaseWarning: isVancomycin && t1PostInfusionHours < 1.0,
    );
  }

  /// Evaluates a random post-dose Aminoglycoside serum concentration using the
  /// **Hartford Hospital Extended-Interval Nomogram** (7 mg/kg Gentamicin/Tobramycin,
  /// or 15 mg/kg Amikacin where serum concentration is halved before plotting).
  ///
  /// Validated sampling window: **6.0 to 14.0 hours** after the start of infusion.
  /// Boundary lines — VERIFICATION STATUS: PENDING. Shape follows the Hartford
  /// nomogram (Nicolau DP et al. Antimicrob Agents Chemother. 1995;39(3):650-655),
  /// but the coordinates below are linear approximations entered by the developer
  /// and have NOT yet been checked against the original figure by a pharmacist:
  /// - **q24h / q36h boundary**: (6 hr, 9.0 mg/L) to (14 hr, 2.0 mg/L)
  /// - **q36h / q48h boundary**: (6 hr, 11.0 mg/L) to (14 hr, 4.5 mg/L)
  /// - **q48h upper boundary**: (6 hr, 13.0 mg/L) to (14 hr, 7.0 mg/L)
  /// Valid only for the 7 mg/kg Gentamicin/Tobramycin regimen (or 15 mg/kg Amikacin, halved).
  static HartfordNomogramEvaluation evaluateHartfordNomogram({
    required double randomLevelMgL,
    required double hoursPostDose,
    bool isAmikacin = false,
  }) {
    if (randomLevelMgL <= 0) {
      throw ArgumentError.value(
        randomLevelMgL,
        'randomLevelMgL',
        'Random serum concentration must be > 0 mg/L',
      );
    }
    if (hoursPostDose <= 0) {
      throw ArgumentError.value(
        hoursPostDose,
        'hoursPostDose',
        'Hours post-dose must be > 0',
      );
    }

    final normalizedMgL = isAmikacin ? (randomLevelMgL / 2.0) : randomLevelMgL;

    if (hoursPostDose < 6.0 || hoursPostDose > 14.0) {
      return HartfordNomogramEvaluation(
        zone: HartfordNomogramZone.outOfTimeWindow,
        recommendedIntervalHours: null,
        normalizedGentamicinEquivalentMgL: normalizedMgL,
        q24BoundaryMgL: 0.0,
        q36BoundaryMgL: 0.0,
        q48BoundaryMgL: 0.0,
        recommendationEn:
            'Sampling time (${hoursPostDose.toStringAsFixed(1)} hr) is outside the validated 6–14 hr Hartford Nomogram window. Use 2-point Sawchuk-Zaske TDM instead.',
        recommendationTh:
            'เวลาเจาะเลือด (${hoursPostDose.toStringAsFixed(1)} ชม.) อยู่นอกช่วง 6–14 ชม. ของ Hartford Nomogram แนะนำให้คำนวณแบบ 2 จุด (Sawchuk-Zaske) แทน',
      );
    }

    final dt = hoursPostDose - 6.0; // [0.0, 8.0]
    final q24Boundary = 9.0 - (7.0 / 8.0) * dt; // 9.0 at 6h -> 2.0 at 14h
    final q36Boundary = 11.0 - (6.5 / 8.0) * dt; // 11.0 at 6h -> 4.5 at 14h
    final q48Boundary = 13.0 - (6.0 / 8.0) * dt; // 13.0 at 6h -> 7.0 at 14h

    if (normalizedMgL <= q24Boundary) {
      return HartfordNomogramEvaluation(
        zone: HartfordNomogramZone.q24h,
        recommendedIntervalHours: 24,
        normalizedGentamicinEquivalentMgL: normalizedMgL,
        q24BoundaryMgL: q24Boundary,
        q36BoundaryMgL: q36Boundary,
        q48BoundaryMgL: q48Boundary,
        recommendationEn:
            'Zone q24h — Administer extended-interval dose every 24 hours (Hartford Nomogram).',
        recommendationTh:
            'อยู่ในโซน q24h — แนะนำให้บริหารยาแบบ Once-Daily ทุก 24 ชั่วโมง (ตามเกณฑ์ Hartford Nomogram)',
      );
    } else if (normalizedMgL <= q36Boundary) {
      return HartfordNomogramEvaluation(
        zone: HartfordNomogramZone.q36h,
        recommendedIntervalHours: 36,
        normalizedGentamicinEquivalentMgL: normalizedMgL,
        q24BoundaryMgL: q24Boundary,
        q36BoundaryMgL: q36Boundary,
        q48BoundaryMgL: q48Boundary,
        recommendationEn:
            'Zone q36h — Extend dosing interval to every 36 hours (Hartford Nomogram).',
        recommendationTh:
            'อยู่ในโซน q36h — แนะนำให้ยืดระยะห่างการให้ยาเป็นทุก 36 ชั่วโมง (ตามเกณฑ์ Hartford Nomogram)',
      );
    } else if (normalizedMgL <= q48Boundary) {
      return HartfordNomogramEvaluation(
        zone: HartfordNomogramZone.q48h,
        recommendedIntervalHours: 48,
        normalizedGentamicinEquivalentMgL: normalizedMgL,
        q24BoundaryMgL: q24Boundary,
        q36BoundaryMgL: q36Boundary,
        q48BoundaryMgL: q48Boundary,
        recommendationEn:
            'Zone q48h — Extend dosing interval to every 48 hours (Hartford Nomogram).',
        recommendationTh:
            'อยู่ในโซน q48h — แนะนำให้ยืดระยะห่างการให้ยาเป็นทุก 48 ชั่วโมง (ตามเกณฑ์ Hartford Nomogram)',
      );
    } else {
      return HartfordNomogramEvaluation(
        zone: HartfordNomogramZone.aboveQ48hHoldAndMonitor,
        recommendedIntervalHours: null,
        normalizedGentamicinEquivalentMgL: normalizedMgL,
        q24BoundaryMgL: q24Boundary,
        q36BoundaryMgL: q36Boundary,
        q48BoundaryMgL: q48Boundary,
        recommendationEn:
            '⚠️ Above q48h boundary — Hold next dose, recheck serum trough (< 1 mg/L for Gentamicin, < 2.5 mg/L for Amikacin) before redosing, and switch to individualized TDM.',
        recommendationTh:
            '⚠️ สูงเกินเส้น q48h — หยุดยามื้อถัดไปชั่วคราว เจาะติดตามระดับยาซ้ำจนกว่าจะต่ำกว่าเกณฑ์ปลอดภัย (< 1 mg/L สำหรับ Gentamicin, < 2.5 mg/L สำหรับ Amikacin) และปรับเป็นวิธีคำนวณเฉพาะราย',
      );
    }
  }
}

/// Population Volume of Distribution (Vd) models for Vancomycin.
enum VancomycinVdModel {
  /// Standard Adult Vd = 0.70 L/kg TBW (Matzke 1984 / Bauer).
  standardAdult(
    0.70,
    'Standard Adult (0.70 L/kg)',
    'ผู้ใหญ่ทั่วไป (0.70 L/kg)',
  ),

  /// Obesity Vd = 0.52 L/kg TBW (PENDING primary-citation verification; observed in ClinCalc via REA).
  obesity(
    0.52,
    'Obesity BMI ≥ 30 (0.52 L/kg)',
    'ผู้ป่วยภาวะอ้วน BMI ≥ 30 (0.52 L/kg)',
  ),

  /// Critically Ill / Sepsis ICU Vd = 0.85 L/kg TBW (PENDING primary-citation verification; observed in VancoPK via REA).
  criticallyIllIcu(
    0.85,
    'ICU / Sepsis Fluid Expansion (0.85 L/kg)',
    'ผู้ป่วยวิกฤต ICU / Sepsis (0.85 L/kg)',
  );

  final double litersPerKg;
  final String labelEn;
  final String labelTh;

  const VancomycinVdModel(this.litersPerKg, this.labelEn, this.labelTh);
}

/// Deterministic output of a Two-Point Sawchuk-Zaske Individualized PK Analysis.
class SawchukZaskeAnalysis {
  final double individualKe;
  final double individualHalfLifeHours;
  final double individualVdLiters;
  final double individualClearanceLPerHr;
  final double truePeakMgL;
  final double trueTroughMgL;
  final double individualAuc24MgHrL;

  /// True if the time elapsed between C1 and C2 draws is < 2.0 hours (ClinCalc timing safety check).
  final bool hasShortSamplingIntervalWarning;

  /// True if Vancomycin C1 was drawn < 1.0 hour after end of infusion (alpha-distribution phase risk).
  final bool hasDistributionPhaseWarning;

  const SawchukZaskeAnalysis({
    required this.individualKe,
    required this.individualHalfLifeHours,
    required this.individualVdLiters,
    required this.individualClearanceLPerHr,
    required this.truePeakMgL,
    required this.trueTroughMgL,
    required this.individualAuc24MgHrL,
    required this.hasShortSamplingIntervalWarning,
    required this.hasDistributionPhaseWarning,
  });
}

/// Zone classification on the Hartford Hospital Extended-Interval Aminoglycoside Nomogram.
enum HartfordNomogramZone {
  q24h,
  q36h,
  q48h,
  aboveQ48hHoldAndMonitor,
  outOfTimeWindow,
}

/// Result of evaluating a random post-dose serum concentration on the Hartford Nomogram.
class HartfordNomogramEvaluation {
  final HartfordNomogramZone zone;
  final int? recommendedIntervalHours;
  final double normalizedGentamicinEquivalentMgL;
  final double q24BoundaryMgL;
  final double q36BoundaryMgL;
  final double q48BoundaryMgL;
  final String recommendationEn;
  final String recommendationTh;

  const HartfordNomogramEvaluation({
    required this.zone,
    required this.recommendedIntervalHours,
    required this.normalizedGentamicinEquivalentMgL,
    required this.q24BoundaryMgL,
    required this.q36BoundaryMgL,
    required this.q48BoundaryMgL,
    required this.recommendationEn,
    required this.recommendationTh,
  });
}

/// A single point on a pharmacokinetic concentration-time curve.
class PkDataPoint {
  /// Time elapsed in hours (x-axis).
  final double timeHours;

  /// Serum drug concentration in mg/L (mcg/mL) (y-axis).
  final double concentrationMgL;

  /// True during the intravenous infusion phase (0 <= t_cycle <= tInf).
  final bool isInfusing;

  const PkDataPoint({
    required this.timeHours,
    required this.concentrationMgL,
    required this.isInfusing,
  });
}

/// Complete deterministic steady-state pharmacokinetic profile for intermittent IV infusion.
class SteadyStatePkProfile {
  /// Steady-state peak concentration (Cmax,ss) at end of infusion (mg/L).
  final double peakMgL;

  /// Steady-state trough concentration (Cmin,ss) immediately prior to next dose (mg/L).
  final double troughMgL;

  /// Area under the concentration-time curve over a single dosing interval tau (mg·hr/L).
  final double aucTauMgHrL;

  /// 24-hour area under the concentration-time curve at steady state (mg·hr/L).
  final double auc24MgHrL;

  /// Dosing interval tau in hours.
  final double tauHours;

  /// Infusion duration t_inf in hours.
  final double tInfHours;

  /// Intravenous infusion rate in mg/min.
  final double infusionRateMgPerMin;

  /// True if infusion rate exceeds 10 mg/min (ASHP/Sanford threshold for Vancomycin Red Man Syndrome).
  final bool hasRedManSyndromeRisk;

  /// Concentration-time points for one full dosing interval [0, tau].
  final List<PkDataPoint> singleIntervalCurve;

  /// Concentration-time points across 24 hours (or [0, tau] if tau > 24h).
  final List<PkDataPoint> twentyFourHourCurve;

  const SteadyStatePkProfile({
    required this.peakMgL,
    required this.troughMgL,
    required this.aucTauMgHrL,
    required this.auc24MgHrL,
    required this.tauHours,
    required this.tInfHours,
    required this.infusionRateMgPerMin,
    required this.hasRedManSyndromeRisk,
    required this.singleIntervalCurve,
    required this.twentyFourHourCurve,
  });
}
