// ============================================================
// Drug Dosage Calculator — Oral Liquid Formulation Model
// ============================================================
// Structured model for commercial pediatric oral liquid concentrations
// (syrup, suspension, drops, elixir) and household teaspoon conversions.
//
// Reference: Drug Information Handbook (Lexicomp 2024),
// Pediatric & Neonatal Dosage Handbook, RDU Thailand.
//
// DISCLAIMER: SaMD prototype — not for clinical use.
// ============================================================

/// Represents a standard commercial oral liquid concentration.
class OralLiquidConcentration {
  /// User-friendly label for display (e.g. '120 mg / 5 mL (24 mg/mL)').
  final String label;

  /// Active drug amount in milligrams (e.g. 120.0).
  final double amountMg;

  /// Volume corresponding to [amountMg] in milliliters (standard is usually 5.0 mL or 1.0 mL).
  final double perVolumeMl;

  /// Pharmaceutical formulation or brand designation (e.g. 'Syrup', 'Suspension', 'Drops', 'Forte').
  final String? brandOrForm;

  /// Primary clinical source citation (e.g. 'Lexicomp 2024 / RDU Thailand').
  final String? citation;

  /// Whether this is the default commercial concentration for the regimen.
  final bool isDefault;

  const OralLiquidConcentration({
    required this.label,
    required this.amountMg,
    this.perVolumeMl = 5.0,
    this.brandOrForm,
    this.citation,
    this.isDefault = false,
  }) : assert(amountMg > 0, 'amountMg must be > 0'),
       assert(perVolumeMl > 0, 'perVolumeMl must be > 0');

  /// Active concentration in mg/mL (e.g. 120 mg / 5 mL = 24.0 mg/mL).
  double get concentrationMgPerMl => amountMg / perVolumeMl;

  /// Calculates the volume in milliliters (mL) required for the given dose in milligrams (mg).
  double doseToVolumeMl(double doseMg) {
    if (doseMg <= 0) return 0.0;
    return doseMg / concentrationMgPerMl;
  }

  /// Calculates the equivalent household teaspoons (tsp) for the given dose in milligrams (mg),
  /// based on the standard 5 mL per teaspoon conversion.
  double doseToTeaspoons(double doseMg) {
    if (doseMg <= 0) return 0.0;
    return doseToVolumeMl(doseMg) / 5.0;
  }

  @override
  String toString() => 'OralLiquidConcentration($label, conc: ${concentrationMgPerMl.toStringAsFixed(1)} mg/mL)';
}
