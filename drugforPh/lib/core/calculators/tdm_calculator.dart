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
}
