// ============================================================
// Drug Dosage Calculator — BSA Calculator
// ============================================================
// Body Surface Area (BSA) calculation using three validated
// clinical formulas. Results in m².
//
// References:
//   Mosteller RD. N Engl J Med 1987;317:1098.
//   DuBois D, DuBois EF. Arch Intern Med 1916;17:863-71.
//   Haycock GB et al. J Pediatr 1978;93:62-6.
//
// DISCLAIMER: SaMD prototype — not for clinical use.
// ============================================================

import 'dart:math' as math;
import '../models/unit.dart';

/// Deterministic BSA calculations.
///
/// All formulas are pure functions with no side effects.
/// Inputs: height in cm, weight in kg.
/// Output: BSA in m².
class BsaCalculator {
  const BsaCalculator._();

  // ------------------------------------------------------------------
  // Mosteller formula (most widely used, simple)
  // BSA (m²) = √( (height_cm × weight_kg) / 3600 )
  // ------------------------------------------------------------------

  /// Calculates BSA using the **Mosteller** formula.
  ///
  /// Recommended as the default for adults and older children.
  static double mosteller({
    required double heightCm,
    required double weightKg,
  }) {
    _validateInputs(heightCm, weightKg);
    return math.sqrt((heightCm * weightKg) / 3600.0);
  }

  // ------------------------------------------------------------------
  // DuBois & DuBois formula (classic, still widely referenced)
  // BSA (m²) = 0.007184 × height_cm^0.725 × weight_kg^0.425
  // ------------------------------------------------------------------

  /// Calculates BSA using the **DuBois & DuBois** formula.
  static double dubois({
    required double heightCm,
    required double weightKg,
  }) {
    _validateInputs(heightCm, weightKg);
    return 0.007184 *
        math.pow(heightCm, 0.725) *
        math.pow(weightKg, 0.425);
  }

  // ------------------------------------------------------------------
  // Haycock formula (validated for neonates and young children)
  // BSA (m²) = 0.024265 × height_cm^0.3964 × weight_kg^0.5378
  // ------------------------------------------------------------------

  /// Calculates BSA using the **Haycock** formula.
  ///
  /// Preferred for **pediatric** patients, especially neonates.
  static double haycock({
    required double heightCm,
    required double weightKg,
  }) {
    _validateInputs(heightCm, weightKg);
    return 0.024265 *
        math.pow(heightCm, 0.3964) *
        math.pow(weightKg, 0.5378);
  }

  // ------------------------------------------------------------------
  // Convenience dispatcher
  // ------------------------------------------------------------------

  /// Calculates BSA using the specified [formula].
  static double calculate({
    required double heightCm,
    required double weightKg,
    BsaFormula formula = BsaFormula.mosteller,
  }) {
    switch (formula) {
      case BsaFormula.mosteller:
        return mosteller(heightCm: heightCm, weightKg: weightKg);
      case BsaFormula.dubois:
        return dubois(heightCm: heightCm, weightKg: weightKg);
      case BsaFormula.haycock:
        return haycock(heightCm: heightCm, weightKg: weightKg);
    }
  }

  // ------------------------------------------------------------------
  // Validation
  // ------------------------------------------------------------------

  static void _validateInputs(double heightCm, double weightKg) {
    if (heightCm <= 0) {
      throw ArgumentError.value(
        heightCm, 'heightCm', 'Height must be positive',
      );
    }
    if (weightKg <= 0) {
      throw ArgumentError.value(
        weightKg, 'weightKg', 'Weight must be positive',
      );
    }
    if (heightCm > 300) {
      throw ArgumentError.value(
        heightCm, 'heightCm', 'Height exceeds 300 cm — verify input',
      );
    }
    if (weightKg > 500) {
      throw ArgumentError.value(
        weightKg, 'weightKg', 'Weight exceeds 500 kg — verify input',
      );
    }
  }
}
