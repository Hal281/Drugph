// ============================================================
// Drug Dosage Calculator — Calculation Audit Log
// ============================================================
// Immutable log entry for every dose calculation performed.
// Designed for traceability and audit logging in educational SaMD prototype.
//
// DISCLAIMER: Educational prototype — not for clinical use.
// ============================================================

import '../models/dosage_result.dart';
import '../models/dose_limit.dart';
import '../models/unit.dart';

/// A typed snapshot of patient and calculation inputs.
class CalculationInputs {
  final double? weightKg;
  final double? heightCm;
  final int? ageYears;
  final int? ageMonths;
  final String? sex;
  final double? serumCreatinineMgDl;
  final double? creatinineClearanceMlMin;
  final bool? isScrStable;
  final double? targetAuc;
  final Map<String, dynamic> rawInputs;

  const CalculationInputs({
    this.weightKg,
    this.heightCm,
    this.ageYears,
    this.ageMonths,
    this.sex,
    this.serumCreatinineMgDl,
    this.creatinineClearanceMlMin,
    this.isScrStable,
    this.targetAuc,
    this.rawInputs = const {},
  });

  factory CalculationInputs.fromMap(Map<String, dynamic> map) {
    return CalculationInputs(
      weightKg: (map['weightKg'] as num?)?.toDouble() ?? (map['weight'] as num?)?.toDouble(),
      heightCm: (map['heightCm'] as num?)?.toDouble() ?? (map['height'] as num?)?.toDouble(),
      ageYears: (map['ageYears'] as num?)?.toInt() ?? (map['age'] as num?)?.toInt(),
      ageMonths: (map['ageMonths'] as num?)?.toInt(),
      sex: map['sex']?.toString() ?? map['gender']?.toString(),
      serumCreatinineMgDl: (map['serumCreatinineMgDl'] as num?)?.toDouble() ?? (map['scr'] as num?)?.toDouble(),
      creatinineClearanceMlMin: (map['creatinineClearanceMlMin'] as num?)?.toDouble() ?? (map['crcl'] as num?)?.toDouble(),
      isScrStable: map['isScrStable'] as bool?,
      targetAuc: (map['targetAuc'] as num?)?.toDouble(),
      rawInputs: Map.unmodifiable(map),
    );
  }

  Map<String, dynamic> toMap() => {
    if (weightKg != null) 'weightKg': weightKg,
    if (heightCm != null) 'heightCm': heightCm,
    if (ageYears != null) 'ageYears': ageYears,
    if (ageMonths != null) 'ageMonths': ageMonths,
    if (sex != null) 'sex': sex,
    if (serumCreatinineMgDl != null) 'serumCreatinineMgDl': serumCreatinineMgDl,
    if (creatinineClearanceMlMin != null) 'creatinineClearanceMlMin': creatinineClearanceMlMin,
    if (isScrStable != null) 'isScrStable': isScrStable,
    if (targetAuc != null) 'targetAuc': targetAuc,
    ...rawInputs,
  };
}

/// An immutable audit log entry for a single dose calculation.
///
/// Records WHO, WHAT, WHEN, and HOW a calculation was performed,
/// supporting clinical traceability and retrospective review.
class CalculationLog {
  /// Unique log entry ID.
  final String logId;

  /// ISO 8601 timestamp of the calculation in UTC.
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

  /// All input values used in the calculation (unmodifiable map).
  final Map<String, dynamic> inputs;

  /// Optional typed snapshot of input values.
  final CalculationInputs? calculationInputs;

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

  CalculationLog({
    required this.logId,
    required DateTime timestamp,
    required this.userId,
    this.patientId,
    required this.drugName,
    required this.drugId,
    required this.route,
    this.indication,
    required Map<String, dynamic> inputs,
    this.calculationInputs,
    required this.result,
    required this.formulaUsed,
    required this.softwareVersion,
    this.warningOverridden = false,
    this.overrideJustification,
  })  : timestamp = timestamp.isUtc ? timestamp : timestamp.toUtc(),
        inputs = Map.unmodifiable(inputs) {
    if (warningOverridden &&
        (overrideJustification == null ||
            overrideJustification!.trim().isEmpty)) {
      throw ArgumentError(
        'Override justification is required when warnings are overridden',
      );
    }
  }

  /// Serializes this log entry to a JSON-compatible Map.
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
      'roundedDose': result.roundedDose,
      'doseUnit': result.doseUnit?.symbol,
      'frequency': result.frequency,
      'dailyDose': result.dailyDose,
      'volumeMl': result.volumeMl,
      'infusionRateMlPerHr': result.infusionRateMlPerHr,
      'warningCount': result.warnings.length,
      'hasHardLimitViolation': result.hasHardLimitViolation,
      'warnings': result.warnings
          .map((w) => {
                'severity': w.severity.name,
                'messageEn': w.messageEn,
                'messageTh': w.messageTh,
                'code': w.code.name,
              })
          .toList(),
      'success': result.success,
      'errorMessage': result.errorMessage,
      'errorMessageTh': result.errorMessageTh,
      'softwareVersion': softwareVersion,
      'warningOverridden': warningOverridden,
      'overrideJustification': overrideJustification,
    };
  }

  /// Deserializes a [CalculationLog] from JSON.
  factory CalculationLog.fromJson(Map<String, dynamic> json) {
    final rawInputs = json['inputs'];
    final inputsMap = rawInputs is Map
        ? Map<String, dynamic>.from(rawInputs)
        : <String, dynamic>{};

    final rawWarnings = json['warnings'];
    final warningsList = <DoseWarning>[];
    if (rawWarnings is List) {
      for (final w in rawWarnings) {
        if (w is Map) {
          final sevStr = w['severity'] as String? ?? 'info';
          final sev = LimitSeverity.values.firstWhere(
            (s) => s.name == sevStr || s.labelEn == sevStr,
            orElse: () => LimitSeverity.info,
          );
          final codeStr = w['code'] as String?;
          final code = codeStr != null
              ? DoseWarningCode.values.firstWhere(
                  (c) => c.name == codeStr,
                  orElse: () => DoseWarningCode.generalAlert,
                )
              : DoseWarningCode.generalAlert;
          warningsList.add(DoseWarning(
            severity: sev,
            messageEn: w['messageEn']?.toString() ?? '',
            messageTh: w['messageTh']?.toString() ?? '',
            code: code,
          ));
        }
      }
    }

    final rawSuccess = json['success'] as bool? ?? true;
    final dosageResult = DosageResult(
      success: rawSuccess,
      calculatedDose: (json['calculatedDose'] as num?)?.toDouble(),
      roundedDose: (json['roundedDose'] as num?)?.toDouble(),
      doseUnit: json['doseUnit'] != null
          ? DoseUnit.values.firstWhere(
              (u) => u.symbol == json['doseUnit'] || u.name == json['doseUnit'],
              orElse: () => DoseUnit.mg,
            )
          : null,
      frequency: json['frequency']?.toString(),
      dailyDose: (json['dailyDose'] as num?)?.toDouble(),
      volumeMl: (json['volumeMl'] as num?)?.toDouble(),
      infusionRateMlPerHr: (json['infusionRateMlPerHr'] as num?)?.toDouble(),
      formulaUsed: json['formulaUsed']?.toString() ?? 'N/A',
      errorMessage: json['errorMessage']?.toString(),
      errorMessageTh: json['errorMessageTh']?.toString(),
      warnings: warningsList,
    );

    return CalculationLog(
      logId: json['logId']?.toString() ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String).toUtc(),
      userId: json['userId']?.toString() ?? '',
      patientId: json['patientId']?.toString(),
      drugName: json['drugName']?.toString() ?? '',
      drugId: json['drugId']?.toString() ?? '',
      route: json['route']?.toString() ?? '',
      indication: json['indication']?.toString(),
      inputs: inputsMap,
      calculationInputs: CalculationInputs.fromMap(inputsMap),
      result: dosageResult,
      formulaUsed: json['formulaUsed']?.toString() ?? '',
      softwareVersion: json['softwareVersion']?.toString() ?? 'unknown',
      warningOverridden: json['warningOverridden'] as bool? ?? false,
      overrideJustification: json['overrideJustification']?.toString(),
    );
  }

  @override
  String toString() =>
      'CalculationLog($logId: $drugName → '
      '${result.calculatedDose} ${result.doseUnit?.symbol} '
      'at ${timestamp.toIso8601String()})';
}
