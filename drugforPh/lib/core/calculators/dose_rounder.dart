// ============================================================
// Drug Dosage Calculator — Dose Rounder
// ============================================================
// Rounds calculated doses to formulary-available vial sizes or
// practical administration units.
//
// DISCLAIMER: SaMD prototype — not for clinical use.
// ============================================================

class DoseRounder {
  const DoseRounder._();

  /// Rounds a [calculatedDose] to the nearest available formulation
  /// combination using [availableStrengths].
  ///
  /// Uses a greedy algorithm or simply finds the nearest multiple of the
  /// smallest available strength, while preferring exact matches or halves.
  ///
  /// Example:
  /// Dose = 642 mg, strengths = [500, 1000]
  /// Smallest unit is 500. We can do half-vials (250).
  /// Multiples: 250, 500, 750, 1000.
  /// 642 is closest to 750 (difference 108) or 500 (difference 142).
  /// So it rounds to 750 mg (1.5 vials of 500mg).
  static double? roundToNearestStrength(
    double calculatedDose,
    List<double> strengths,
  ) {
    if (strengths.isEmpty) return null;

    // Sort strengths ascending
    final sortedStrengths = List<double>.from(strengths)..sort();

    // We assume that the pharmacy can easily prepare half-vials
    // of the smallest available strength, or multiples of it.
    final smallestVial = sortedStrengths.first;
    final halfVial = smallestVial / 2.0;

    // Generate possible practical doses up to 3x the max strength or 4x the calculated dose
    // to give a good search space.
    final maxSearch = calculatedDose * 2;
    List<double> possibleDoses = [];

    for (double d = halfVial; d <= maxSearch + smallestVial; d += halfVial) {
      possibleDoses.add(d);
    }

    if (possibleDoses.isEmpty) return calculatedDose;

    // Find the closest possible dose
    double closestDose = possibleDoses.first;
    double minDiff = (calculatedDose - closestDose).abs();

    for (final dose in possibleDoses) {
      final diff = (calculatedDose - dose).abs();
      // If it's a tie or closer, pick it.
      if (diff < minDiff) {
        closestDose = dose;
        minDiff = diff;
      }
    }

    // If the rounded dose is 0 (e.g. calculated dose was extremely small),
    // at least return the smallest half vial.
    if (closestDose == 0.0) {
      return halfVial;
    }

    return closestDose;
  }
}
