// ============================================================
// Drug Dosage Calculator — Calculation Audit Log
// ============================================================
// Immutable log entry for every dose calculation performed.
// Supports audit trail requirements per IEC 62304 / SaMD.
//
// DISCLAIMER: SaMD prototype — not for clinical use.
// ============================================================

import '../models/dosage_result.dart';

/// An immutable audit log entry for a single dose calculation.
///
/// Every calculation must produce a [CalculationLog] that records:
/// - WHO performed the calculation (userId)
/// - WHAT was calculated (drug, inputs, result)
/// - WHEN it was calculated (timestamp)
/// - HOW it was calculated (formula used)
///
/// This satisfies audit-trail requirements for SaMD under
/// IEC 62304 and Thai FDA regulations.
class CalculationLog {
  /// Unique log entry ID (UUID recommended).
  final String logId;

  /// ISO 8601 timestamp of the calculation.
  final DateTime timestamp;

  /// User / clinician ID who performed the calculation.
  final String userId;

  /// Patient identifier (anonymized or internal ID).
  final String? patientId;

  /// Drug generic name.
  final String drugName;

  /// Drug ID from the database.
  final String drugId;

  /// Route of administration used.
  final String route;

  /// Indication selected (if applicable).
  final String? indication;

  /// All input values used in the calculation.
  final Map<String, dynamic> inputs;

  /// The complete calculation result.
  final DosageResult result;

  /// Formula or method name used.
  final String formulaUsed;

  /// Software version that produced this result.
  final String softwareVersion;

  /// Whether the clinician overrode any warnings.
  final bool warningOverridden;

  /// Override justification (required if [warningOverridden] is true).
  final String? overrideJustification;

  const CalculationLog({
    required this.logId,
    required this.timestamp,
    required this.userId,
    this.patientId,
    required this.drugName,
    required this.drugId,
    required this.route,
    this.indication,
    required this.inputs,
    required this.result,
    required this.formulaUsed,
    required this.softwareVersion,
    this.warningOverridden = false,
    this.overrideJustification,
  });

  /// Serializes this log entry to a JSON-compatible Map.
  ///
  /// Use this for persistent storage (database, file, API).
  Map<String, dynamic> toJson() {
    return {
      'logId': logId,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'patientId': patientId,
      'drugName': drugName,
      'drugId': drugId,
      'route': route,
      'indication': indication,
      'inputs': inputs,
      'formulaUsed': formulaUsed,
      'calculatedDose': result.calculatedDose,
      'doseUnit': result.doseUnit?.symbol,
      'frequency': result.frequency,
      'dailyDose': result.dailyDose,
      'volumeMl': result.volumeMl,
      'infusionRateMlPerHr': result.infusionRateMlPerHr,
      'warningCount': result.warnings.length,
      'hasHardLimitViolation': result.hasHardLimitViolation,
      'warnings': result.warnings
          .map((w) => {
                'severity': w.severity.labelEn,
                'messageEn': w.messageEn,
                'messageTh': w.messageTh,
              })
          .toList(),
      'success': result.success,
      'errorMessage': result.errorMessage,
      'softwareVersion': softwareVersion,
      'warningOverridden': warningOverridden,
      'overrideJustification': overrideJustification,
    };
  }

  @override
  String toString() =>
      'CalculationLog($logId: $drugName → '
      '${result.calculatedDose} ${result.doseUnit?.symbol} '
      'at ${timestamp.toIso8601String()})';
}
