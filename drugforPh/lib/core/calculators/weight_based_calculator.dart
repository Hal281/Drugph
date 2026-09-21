// ============================================================
// Drug Dosage Calculator — Weight-Based Calculator
// ============================================================
// Deterministic weight-based dosing with IBW and AdjBW support.
//
// References:
//   Devine BJ. Drug Intell Clin Pharm 1974;8:650-5. (IBW)
//   Winter MA et al. Am J Health Syst Pharm 2012. (AdjBW)
//
// DISCLAIMER: SaMD prototype — not for clinical use.
// ============================================================

import '../models/unit.dart';

/// Weight-based dosing calculations.
///
/// Supports actual body weight, Ideal Body Weight (IBW),
/// and Adjusted Body Weight (AdjBW) for obese patients.
class WeightBasedCalculator {
  const WeightBasedCalculator._();

  // ------------------------------------------------------------------
  // Ideal Body Weight (Devine formula, 1974)
  //
  // Male  : IBW (kg) = 50   + 2.3 × (height_inches − 60)
  // Female: IBW (kg) = 45.5 + 2.3 × (height_inches − 60)
  //
  // For height ≤ 60 inches (≤ 152.4 cm), IBW = base value.
  // ------------------------------------------------------------------

  /// Calculates Ideal Body Weight using the **Devine** formula.
  ///
  /// [heightCm] must be > 0. Returns IBW in kg.
  static double idealBodyWeight({
    required double heightCm,
    required Sex sex,
  }) {
    if (heightCm <= 0) {
      throw ArgumentError.value(heightCm, 'heightCm', 'Must be > 0');
    }

    final double heightInches = heightCm / 2.54;
    final double base = sex == Sex.male ? 50.0 : 45.5;

    if (heightInches <= 60.0) {
      return base;
    }

    return base + 2.3 * (heightInches - 60.0);
  }

  // ------------------------------------------------------------------
  // Adjusted Body Weight (AdjBW)
  //
  // AdjBW (kg) = IBW + 0.4 × (actual_weight − IBW)
  //
  // Used when actual weight is ≥ 120% of IBW (obese patients)
  // and a drug's dosing should be based on something between
  // IBW and actual weight.
  // ------------------------------------------------------------------

  /// Calculates Adjusted Body Weight.
  ///
  /// [factor] defaults to 0.4 (most common). Some drugs use 0.25.
  static double adjustedBodyWeight({
    required double actualWeightKg,
    required double ibwKg,
    double factor = 0.4,
  }) {
    if (actualWeightKg <= 0) {
      throw ArgumentError.value(
        actualWeightKg, 'actualWeightKg', 'Must be > 0',
      );
    }
    if (ibwKg <= 0) {
      throw ArgumentError.value(ibwKg, 'ibwKg', 'Must be > 0');
    }

    return ibwKg + factor * (actualWeightKg - ibwKg);
  }

  /// Returns `true` if the patient is considered obese
  /// (actual weight ≥ 120 % of IBW).
  static bool isObese({
    required double actualWeightKg,
    required double ibwKg,
  }) {
    if (ibwKg <= 0) return false;
    return actualWeightKg >= ibwKg * 1.2;
  }

  // ------------------------------------------------------------------
  // Dosing weight selection
  //
  // Some drugs (e.g. Aminoglycosides) use IBW for lean patients
  // and AdjBW for obese patients.
  // ------------------------------------------------------------------

  /// Selects the appropriate dosing weight.
  ///
  /// If the patient is obese (≥ 120 % IBW) and [useAdjBwIfObese]
  /// is `true`, returns AdjBW. Otherwise returns actual weight.
  /// If [alwaysUseIbw] is `true`, returns IBW regardless.
  static double dosingWeight({
    required double actualWeightKg,
    required double heightCm,
    required Sex sex,
    bool useAdjBwIfObese = false,
    bool alwaysUseIbw = false,
    double adjBwFactor = 0.4,
  }) {
    final ibw = idealBodyWeight(heightCm: heightCm, sex: sex);

    if (alwaysUseIbw) return ibw;

    if (useAdjBwIfObese && isObese(actualWeightKg: actualWeightKg, ibwKg: ibw)) {
      return adjustedBodyWeight(
        actualWeightKg: actualWeightKg,
        ibwKg: ibw,
        factor: adjBwFactor,
      );
    }

    return actualWeightKg;
  }

  // ------------------------------------------------------------------
  // Simple weight-based dose
  // ------------------------------------------------------------------

  /// Calculates dose = [weightKg] × [dosePerKg].
  ///
  /// Applies [maxDose] cap if provided.
  static double calculateDose({
    required double weightKg,
    required double dosePerKg,
    double? maxDose,
  }) {
    if (weightKg <= 0) {
      throw ArgumentError.value(weightKg, 'weightKg', 'Must be > 0');
    }
    if (dosePerKg < 0) {
      throw ArgumentError.value(dosePerKg, 'dosePerKg', 'Must be ≥ 0');
    }

    double dose = weightKg * dosePerKg;

    if (maxDose != null && dose > maxDose) {
      dose = maxDose;
    }

    return dose;
  }

  // ------------------------------------------------------------------
  // BSA-based dose (convenience wrapper)
  // ------------------------------------------------------------------

  /// Calculates dose = [bsaM2] × [dosePerM2].
  ///
  /// Applies [maxDose] cap if provided.
  static double calculateBsaDose({
    required double bsaM2,
    required double dosePerM2,
    double? maxDose,
  }) {
    if (bsaM2 <= 0) {
      throw ArgumentError.value(bsaM2, 'bsaM2', 'Must be > 0');
    }
    if (dosePerM2 < 0) {
      throw ArgumentError.value(dosePerM2, 'dosePerM2', 'Must be ≥ 0');
    }

    double dose = bsaM2 * dosePerM2;

    if (maxDose != null && dose > maxDose) {
      dose = maxDose;
    }

    return dose;
  }

  // ------------------------------------------------------------------
  // GFR-based dose: Calvert formula (for Carboplatin)
  //
  // Dose (mg) = target_AUC × (GFR + 25)
  //
  // Reference: Calvert AH et al. J Clin Oncol 1989;7:1748-56.
  // ------------------------------------------------------------------

  /// Calculates Carboplatin dose using the **Calvert** formula.
  ///
  /// [gfrMlMin] is the patient's GFR in mL/min (measured or estimated).
  /// [targetAuc] is the target AUC (commonly 5–7 for Carboplatin).
  static double calvertFormula({
    required double targetAuc,
    required double gfrMlMin,
  }) {
    if (targetAuc <= 0) {
      throw ArgumentError.value(targetAuc, 'targetAuc', 'Must be > 0');
    }
    if (gfrMlMin < 0) {
      throw ArgumentError.value(gfrMlMin, 'gfrMlMin', 'Must be ≥ 0');
    }

    return targetAuc * (gfrMlMin + 25.0);
  }
}
