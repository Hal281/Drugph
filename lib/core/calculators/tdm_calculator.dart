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
    if (weightKg <= 0) {
      throw ArgumentError.value(weightKg, 'weightKg', 'Weight must be > 0');
    }
    return 0.7 * weightKg;
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

    final peakSS =
        (dose / (tInf * vd * ke)) *
        (1 - exp(-ke * tInf)) /
        (1 - exp(-ke * tau));

    final troughSS = peakSS * exp(-ke * (tau - tInf));
    return troughSS;
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
}
