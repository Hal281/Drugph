// ============================================================
// Drug Dosage Calculator — Renal Function Calculator
// ============================================================
// Deterministic renal function estimation formulas:
//   1. Cockcroft-Gault → CrCl (mL/min)
//   2. CKD-EPI 2021   → eGFR (mL/min/1.73 m²)
//
// References:
//   Cockcroft DW, Gault MH. Nephron 1976;16:31-41.
//   Inker LA et al. N Engl J Med 2021;385:1737-49.
//
// DISCLAIMER: SaMD prototype — not for clinical use.
// ============================================================

import 'dart:math' as math;
import '../models/unit.dart';

/// Deterministic renal function calculations.
class RenalCalculator {
  const RenalCalculator._();

  // ------------------------------------------------------------------
  // Cockcroft-Gault equation
  //
  // CrCl (mL/min) = ((140 − age) × weight_kg × [0.85 if female])
  //                  / (72 × serum_creatinine_mg_dL)
  //
  // Note: Uses ACTUAL body weight by default. For obese patients
  // consider using Adjusted Body Weight via WeightBasedCalculator.
  // ------------------------------------------------------------------

  /// Estimates creatinine clearance using the **Cockcroft-Gault** equation.
  ///
  /// Returns CrCl in **mL/min**.
  static double cockcroftGault({
    required int ageYears,
    required double weightKg,
    required Sex sex,
    required double serumCreatinineMgDl,
  }) {
    if (serumCreatinineMgDl <= 0) {
      throw ArgumentError.value(
        serumCreatinineMgDl,
        'serumCreatinineMgDl',
        'Serum creatinine must be > 0',
      );
    }
    if (ageYears < 0 || ageYears > 150) {
      throw ArgumentError.value(ageYears, 'ageYears', 'Invalid age');
    }
    if (weightKg <= 0) {
      throw ArgumentError.value(weightKg, 'weightKg', 'Weight must be > 0');
    }

    double crcl =
        ((140.0 - ageYears) * weightKg) / (72.0 * serumCreatinineMgDl);

    if (sex == Sex.female) {
      crcl *= 0.85;
    }

    // CrCl cannot be negative (can happen if age > 140).
    return math.max(crcl, 0.0);
  }

  // ------------------------------------------------------------------
  // CKD-EPI 2021 equation (race-free)
  //
  // eGFR = 142
  //        × min(SCr/κ, 1)^α
  //        × max(SCr/κ, 1)^(−1.200)
  //        × 0.9938^age
  //        × [1.012 if female]
  //
  // Where:
  //   κ = 0.7 (female), 0.9 (male)
  //   α = −0.241 (female), −0.302 (male)
  // ------------------------------------------------------------------

  /// Estimates GFR using the **CKD-EPI 2021** equation (race-free).
  ///
  /// Returns eGFR in **mL/min/1.73 m²**.
  static double ckdEpi2021({
    required int ageYears,
    required Sex sex,
    required double serumCreatinineMgDl,
  }) {
    if (serumCreatinineMgDl <= 0) {
      throw ArgumentError.value(
        serumCreatinineMgDl,
        'serumCreatinineMgDl',
        'Serum creatinine must be > 0',
      );
    }
    if (ageYears < 18) {
      throw ArgumentError.value(
        ageYears,
        'ageYears',
        'CKD-EPI 2021 is validated for adults (≥ 18 years)',
      );
    }

    final double kappa = sex == Sex.female ? 0.7 : 0.9;
    final double alpha = sex == Sex.female ? -0.241 : -0.302;

    final double scrOverKappa = serumCreatinineMgDl / kappa;

    double egfr = 142.0 *
        math.pow(math.min(scrOverKappa, 1.0), alpha) *
        math.pow(math.max(scrOverKappa, 1.0), -1.200) *
        math.pow(0.9938, ageYears.toDouble());

    if (sex == Sex.female) {
      egfr *= 1.012;
    }

    return math.max(egfr, 0.0);
  }

  // ------------------------------------------------------------------
  // Convenience dispatcher
  // ------------------------------------------------------------------

  /// Calculates renal function using the specified [formula].
  ///
  /// For [RenalFormula.cockcroftGault], [weightKg] is required.
  /// For [RenalFormula.ckdEpi2021], weight is not used.
  static double calculate({
    required int ageYears,
    required Sex sex,
    required double serumCreatinineMgDl,
    double? weightKg,
    RenalFormula formula = RenalFormula.cockcroftGault,
  }) {
    switch (formula) {
      case RenalFormula.cockcroftGault:
        if (weightKg == null) {
          throw ArgumentError(
            'Cockcroft-Gault requires weightKg',
          );
        }
        return cockcroftGault(
          ageYears: ageYears,
          weightKg: weightKg,
          sex: sex,
          serumCreatinineMgDl: serumCreatinineMgDl,
        );
      case RenalFormula.ckdEpi2021:
        return ckdEpi2021(
          ageYears: ageYears,
          sex: sex,
          serumCreatinineMgDl: serumCreatinineMgDl,
        );
    }
  }
}
