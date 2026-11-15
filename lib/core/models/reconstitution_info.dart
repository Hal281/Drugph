// ============================================================
// Drug Dosage Calculator — IV Reconstitution & Dilution Info Model
// ============================================================
// Structured model for hospital IV injectable reconstitution parameters,
// powder displacement, and resulting vial concentrations.
//
// Reference: Drug Information Handbook (Lexicomp 2024),
// The Sanford Guide to Antimicrobial Therapy 2024.
//
// DISCLAIMER: SaMD prototype — not for clinical use.
// ============================================================

/// Clinical parameters for reconstituting dry powder vials into injectable solutions.
class ReconstitutionInfo {
  /// Total nominal drug content per vial in milligrams (e.g. 500.0, 1000.0, 4500.0).
  final double vialStrengthMg;

  /// Recommended diluent for reconstitution (e.g. 'Sterile Water for Injection (SWFI)', '0.9% Normal Saline (NSS)').
  final String diluentName;

  /// Volume of diluent to add to the vial in milliliters (mL).
  final double diluentVolumeMl;

  /// Powder displacement volume in milliliters (mL), if clinically significant.
  final double displacedVolumeMl;

  /// Resulting reconstituted drug concentration in milligrams per milliliter (mg/mL).
  final double resultingConcentrationMgPerMl;

  /// Reconstitution instructions in English.
  final String? instructionsEn;

  /// Reconstitution instructions in Thai.
  final String? instructionsTh;

  /// Clinical reference citation (e.g. 'Drug Information Handbook (Lexicomp) 2024 / Sanford Guide 2024').
  final String sourceCitation;

  const ReconstitutionInfo({
    required this.vialStrengthMg,
    required this.diluentName,
    required this.diluentVolumeMl,
    this.displacedVolumeMl = 0.0,
    required this.resultingConcentrationMgPerMl,
    this.instructionsEn,
    this.instructionsTh,
    required this.sourceCitation,
  }) : assert(vialStrengthMg > 0, 'vialStrengthMg must be > 0'),
       assert(diluentVolumeMl > 0, 'diluentVolumeMl must be > 0'),
       assert(resultingConcentrationMgPerMl > 0, 'resultingConcentrationMgPerMl must be > 0');

  /// Total volume inside the vial after reconstitution (diluent volume + powder displacement).
  double get totalVialVolumeMl => diluentVolumeMl + displacedVolumeMl;

  /// Calculates the volume to draw in milliliters (mL) from the reconstituted vial for a desired dose (mg).
  double calculateDrawVolume(double doseMg) {
    if (doseMg <= 0) return 0.0;
    return doseMg / resultingConcentrationMgPerMl;
  }

  /// Calculates the number of whole vials needed to provide the desired dose (mg).
  int calculateVialsNeeded(double doseMg) {
    if (doseMg <= 0) return 0;
    return (doseMg / vialStrengthMg).ceil();
  }

  @override
  String toString() =>
      'ReconstitutionInfo(${vialStrengthMg.toStringAsFixed(0)} mg in $diluentName -> ${resultingConcentrationMgPerMl.toStringAsFixed(1)} mg/mL)';
}
