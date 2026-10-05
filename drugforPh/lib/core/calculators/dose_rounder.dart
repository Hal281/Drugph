// ============================================================
// Drug Dosage Calculator — Dose Rounder
// ============================================================
// Rounds calculated doses to formulary-available vial sizes or
// practical administration units.
//
// DISCLAIMER: SaMD prototype — not for clinical use.
// ============================================================

// Clinical Reference:
// American Society of Health-System Pharmacists (ASHP). Guidelines on Preventing Medication Errors in Hospitals.
// Am J Hosp Pharm. 1993;50(2):305-314.
// Cohen MR. Medication Errors. 2nd ed. American Pharmacists Association; 2007.
// Standard clinical practice allows dose rounding within +/- 5% to 10% of the calculated dose
// to accommodate commercially available dosage forms and avoid measuring fractions of solid dosage units.

class DoseRounder {
  const DoseRounder._();

  /// Rounds a [calculatedDose] to the nearest formulation step using [strengths].
  ///
  /// - If [isSplittable] is `true`, tablets/vials can be halved (step = smallest strength / 2).
  /// - If [isSplittable] is `false`, step is the smallest available strength.
  /// - Returns `null` if the rounded dose deviates from [calculatedDose] by more
  ///   than [maxDeviation] (default 0.05 / 5%) or if inputs are invalid.
  static double? roundToNearestStrength(
    double calculatedDose,
    List<double> strengths, {
    bool isSplittable = true,
    double maxDeviation = 0.05,
  }) {
    if (strengths.isEmpty || calculatedDose <= 0) return null;

    final sortedStrengths = List<double>.from(strengths)..sort();
    final smallestStrength = sortedStrengths.first;
    if (smallestStrength <= 0) return null;

    final step = isSplittable ? (smallestStrength / 2.0) : smallestStrength;

    // Nearest integer multiple of step
    final multiple = (calculatedDose / step).round();
    if (multiple <= 0) return null;

    final roundedDose = multiple * step;
    final deviation = (roundedDose - calculatedDose).abs() / calculatedDose;

    if (deviation > maxDeviation) {
      return null;
    }

    return roundedDose;
  }
}
