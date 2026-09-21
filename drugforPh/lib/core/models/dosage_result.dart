// ============================================================
// Drug Dosage Calculator — Dosage Result Model
// ============================================================
// Immutable output of every dose calculation, including the
// calculated dose, IV parameters, audit trail inputs, and
// any safety warnings generated.
//
// DISCLAIMER: SaMD prototype — not for clinical use.
// ============================================================

import 'dose_limit.dart';
import 'unit.dart';

/// The complete result of a dose calculation.
///
/// Every field is `final` so that results are immutable once created.
/// This supports audit-trail integrity: a result cannot be mutated
/// after being logged.
class DosageResult {
  /// Whether the calculation completed without errors.
  final bool success;

  // ---- Primary output ----

  /// Calculated dose value (in [doseUnit]).
  final double? calculatedDose;

  /// Unit of [calculatedDose].
  final DoseUnit? doseUnit;

  /// Dosing frequency (e.g. 'q8h', 'q12h').
  final String? frequency;

  /// Total daily dose (calculatedDose × doses per day).
  final double? dailyDose;

  // ---- IV / infusion output ----

  /// Volume to administer in milliliters (for IV/IM).
  final double? volumeMl;

  /// Infusion rate in mL/hr (for continuous IV infusion).
  final double? infusionRateMlPerHr;

  /// Infusion duration in minutes.
  final double? infusionDurationMinutes;

  /// Drip rate in drops/min (for gravity infusion sets).
  final double? dripRateDropsPerMin;

  // ---- Calculation audit data ----

  /// Name of the formula / method used.
  final String formulaUsed;

  /// All inputs that went into the calculation.
  final Map<String, dynamic> calculationInputs;

  /// BSA value used (m²), if BSA-based.
  final double? bsaM2;

  /// CrCl value used (mL/min), if renal-adjusted.
  final double? crclMlMin;

  /// eGFR value used (mL/min/1.73 m²), if GFR-based.
  final double? eGfrMlMin;

  /// Ideal Body Weight used (kg).
  final double? ibwKg;

  /// Adjusted Body Weight used (kg).
  final double? adjBwKg;

  /// Renal adjustment factor applied (e.g. 0.5 = halved).
  final double? renalAdjustmentFactor;

  /// Frequency after renal adjustment (may differ from [frequency]).
  final String? adjustedFrequency;

  // ---- Safety ----

  /// All warnings and alerts generated during calculation.
  final List<DoseWarning> warnings;

  /// The final dose after formulary rounding.
  final double? roundedDose;

  /// Indicates if this dose was actively adjusted based on renal function.
  final bool isRenallyAdjusted;

  /// Error description if [success] is `false`.
  final String? errorMessage;

  const DosageResult({
    required this.success,
    this.calculatedDose,
    this.doseUnit,
    this.frequency,
    this.dailyDose,
    this.volumeMl,
    this.infusionRateMlPerHr,
    this.infusionDurationMinutes,
    this.dripRateDropsPerMin,
    required this.formulaUsed,
    this.calculationInputs = const {},
    this.bsaM2,
    this.crclMlMin,
    this.eGfrMlMin,
    this.ibwKg,
    this.adjBwKg,
    this.renalAdjustmentFactor,
    this.adjustedFrequency,
    this.roundedDose,
    this.isRenallyAdjusted = false,
    this.warnings = const [],
    this.errorMessage,
  });

  /// Creates a failed result with a single hard-level warning.
  factory DosageResult.error(String message) {
    return DosageResult(
      success: false,
      formulaUsed: 'N/A',
      errorMessage: message,
      warnings: [
        DoseWarning(
          severity: LimitSeverity.hard,
          messageEn: message,
          messageTh: message,
        ),
      ],
    );
  }

  /// `true` if any hard-limit violation exists — UI should **block**.
  bool get hasHardLimitViolation =>
      warnings.any((w) => w.severity == LimitSeverity.hard);

  /// `true` if any soft-limit warning exists — UI should **warn**.
  bool get hasSoftLimitWarning =>
      warnings.any((w) => w.severity == LimitSeverity.soft);

  /// Number of warnings at each severity level.
  Map<LimitSeverity, int> get warningCounts {
    final counts = <LimitSeverity, int>{};
    for (final w in warnings) {
      counts[w.severity] = (counts[w.severity] ?? 0) + 1;
    }
    return counts;
  }

  @override
  String toString() {
    if (!success) return 'DosageResult(ERROR: $errorMessage)';
    final buf = StringBuffer('DosageResult(');
    buf.write('dose: $calculatedDose ${doseUnit?.symbol} $frequency');
    if (volumeMl != null) buf.write(', vol: ${volumeMl}mL');
    if (infusionRateMlPerHr != null) {
      buf.write(', rate: ${infusionRateMlPerHr}mL/hr');
    }
    if (warnings.isNotEmpty) buf.write(', warnings: ${warnings.length}');
    buf.write(')');
    return buf.toString();
  }
}
