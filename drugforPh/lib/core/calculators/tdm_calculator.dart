import 'dart:math';

/// A calculator for Pharmacokinetics (PK) and Therapeutic Drug Monitoring (TDM).
/// Specifically focused on One-compartment model for Vancomycin MVP.
class TdmCalculator {
  const TdmCalculator._();

  /// Calculates Volume of Distribution (Vd) for Vancomycin.
  /// Typically 0.7 L/kg based on Total Body Weight (TBW).
  ///
  /// Returns Vd in Liters.
  static double calculateVd({required double weightKg}) {
    return 0.7 * weightKg;
  }

  /// Calculates Elimination Rate Constant (Ke) based on Creatinine Clearance (CrCl).
  /// Formula: Ke = (0.00083 * CrCl) + 0.0044
  ///
  /// CrCl must be in mL/min.
  /// Returns Ke in hr^-1.
  static double calculateKe({required double crclMlMin}) {
    if (crclMlMin <= 0) return 0.0044; // minimum Ke for anuric
    return (0.00083 * crclMlMin) + 0.0044;
  }

  /// Calculates Half-life (t1/2) from Ke.
  /// Formula: t1/2 = ln(2) / Ke
  ///
  /// Returns t1/2 in hours.
  static double calculateHalfLife({required double ke}) {
    if (ke <= 0) return double.infinity;
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
    double minVal = weightKg * minMgPerKg;
    double maxVal = weightKg * maxMgPerKg;

    if (minVal > absoluteMaxMg) minVal = absoluteMaxMg;
    if (maxVal > absoluteMaxMg) maxVal = absoluteMaxMg;

    return [minVal, maxVal];
  }

  /// Predicts the Trough concentration for a given dosing regimen.
  /// Using One-compartment steady-state equations:
  /// Peak = (Dose / (t_inf * Vd * Ke)) * (1 - e^(-Ke * t_inf)) / (1 - e^(-Ke * tau))
  /// Trough = Peak * e^(-Ke * (tau - t_inf))
  ///
  /// [dose] in mg, [tau] in hours (interval), [tInf] in hours (infusion time).
  static double predictTrough({
    required double dose,
    required double tau,
    required double tInf,
    required double vd,
    required double ke,
  }) {
    if (ke <= 0 || vd <= 0) return 0;

    final peakSS =
        (dose / (tInf * vd * ke)) *
        (1 - exp(-ke * tInf)) /
        (1 - exp(-ke * tau));

    final troughSS = peakSS * exp(-ke * (tau - tInf));
    return troughSS;
  }
}
