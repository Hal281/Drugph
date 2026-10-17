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
import 'rate_unit.dart';
import 'frequency.dart';
import 'dosing_phase.dart';
import 'provenance.dart';

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

  /// Dosing frequency string (e.g. 'q8h', 'q12h').
  final String? frequency;

  /// Structured frequency value type (D1).
  final Frequency? structuredFrequency;

  /// Total daily dose (calculatedDose × doses per day).
  final double? dailyDose;

  // ---- IV / infusion output ----

  /// Infusion result with rate, rateUnit, and pump rate (D2).
  final InfusionResult? infusionResult;

  /// Volume to administer in milliliters (for IV/IM).
  final double? volumeMl;

  /// Infusion rate in mL/hr (for continuous IV infusion).
  final double? infusionRateMlPerHr;

  /// Infusion duration in minutes.
  final double? infusionDurationMinutes;

  /// Drip rate in drops/min (for gravity infusion sets).
  final double? dripRateDropsPerMin;

  // ---- Multi-phase regimens (D3) ----

  /// Active phases for this regimen (e.g. loading, maintenance, taper).
  final List<DosingPhase>? activePhases;

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

  /// Clinical notes / instructions for renal adjustment in English (D5).
  final String? renalNotes;

  /// Clinical notes / instructions for renal adjustment in Thai (D5).
  final String? renalNotesTh;

  // ---- Safety ----

  /// All warnings and alerts generated during calculation.
  final List<DoseWarning> warnings;

  /// The final dose after formulary rounding.
  final double? roundedDose;

  /// Indicates if this dose was actively adjusted based on renal function.
  final bool isRenallyAdjusted;

  /// Indicates if this dose was modified by a clinical dose rule (F6).
  final bool isDoseModified;

  /// Clinical rationale for dose modification (F6).
  final String? doseModificationReason;

  /// Indicates if this regimen is administered on a weekly schedule (F12).
  final bool isWeeklySchedule;

  /// Verification status of the calculated regimen (F1, F5).
  final VerificationStatus verificationStatus;

  /// Error description if [success] is `false` (English).
  final String? errorMessage;

  /// Error description if [success] is `false` (Thai).
  final String? errorMessageTh;

  const DosageResult({
    required this.success,
    this.calculatedDose,
    this.doseUnit,
    this.frequency,
    this.structuredFrequency,
    this.dailyDose,
    this.infusionResult,
    this.volumeMl,
    this.infusionRateMlPerHr,
    this.infusionDurationMinutes,
    this.dripRateDropsPerMin,
    this.activePhases,
    required this.formulaUsed,
    this.calculationInputs = const {},
    this.bsaM2,
    this.crclMlMin,
    this.eGfrMlMin,
    this.ibwKg,
    this.adjBwKg,
    this.renalAdjustmentFactor,
    this.adjustedFrequency,
    this.renalNotes,
    this.renalNotesTh,
    this.roundedDose,
    this.isRenallyAdjusted = false,
    this.isDoseModified = false,
    this.doseModificationReason,
    this.isWeeklySchedule = false,
    this.verificationStatus = VerificationStatus.unverified,
    this.warnings = const [],
    this.errorMessage,
    this.errorMessageTh,
  });

  /// Creates a failed result with a single hard-level warning.
  factory DosageResult.error(String messageEn, [String? messageTh]) {
    final th = messageTh ?? messageEn;
    return DosageResult(
      success: false,
      formulaUsed: 'N/A',
      errorMessage: messageEn,
      errorMessageTh: th,
      warnings: [
        DoseWarning(
          severity: LimitSeverity.hard,
          messageEn: messageEn,
          messageTh: th,
        ),
      ],
    );
  }

  /// Creates a failed result with custom reasons and optional warnings.
  factory DosageResult.failure({
    required String reasonEn,
    required String reasonTh,
    List<DoseWarning> warnings = const [],
    String formulaUsed = 'N/A',
    double? crclMlMin,
    Map<String, dynamic> calculationInputs = const {},
  }) {
    return DosageResult(
      success: false,
      formulaUsed: formulaUsed,
      errorMessage: reasonEn,
      errorMessageTh: reasonTh,
      crclMlMin: crclMlMin,
      calculationInputs: calculationInputs,
      warnings: warnings,
    );
  }

  /// `true` if calculation failed or any hard-limit violation exists — UI should **block**.
  bool get isBlocked => !success || hasHardLimitViolation;

  /// `true` if any hard-limit violation exists — UI should **block**.
  /// Safety banners (e.g. weeklyRegimenBanner) do not block calculation.
  bool get hasHardLimitViolation => warnings.any(
        (w) =>
            w.severity == LimitSeverity.hard &&
            w.code != DoseWarningCode.weeklyRegimenBanner,
      );

  /// `true` if any hard warning exists (including safety banners).
  bool get hasHardWarning =>
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

/// Result of verifying an existing clinician order against the dosing engine (D7).
class OrderVerificationResult {
  /// Whether the order is within safe boundaries.
  final bool isAcceptable;

  /// The engine's recommended calculation for this patient and regimen.
  final DosageResult recommendedResult;

  /// Ordered single dose.
  final double orderedDose;

  /// Ordered frequency.
  final Frequency orderedFrequency;

  /// Percentage deviation from recommended dose (|ordered - recommended| / recommended * 100).
  final double? deviationPercent;

  /// Clinical safety warnings identified during order verification.
  final List<DoseWarning> warnings;

  /// Verification summary in English.
  final String summaryEn;

  /// Verification summary in Thai.
  final String summaryTh;

  const OrderVerificationResult({
    required this.isAcceptable,
    required this.recommendedResult,
    required this.orderedDose,
    required this.orderedFrequency,
    this.deviationPercent,
    required this.warnings,
    required this.summaryEn,
    required this.summaryTh,
  });
}
