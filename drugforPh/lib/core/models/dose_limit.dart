// ============================================================
// Drug Dosage Calculator — Dose Limit & Warning Models
// ============================================================
// Safety-critical structures for Hard/Soft dose limit checks.
// Hard limits BLOCK the calculation; Soft limits WARN the user.
//
// DISCLAIMER: SaMD prototype — not for clinical use.
// ============================================================

/// Severity level of a dose limit violation.
enum LimitSeverity {
  /// Informational — dose is near the upper range.
  info('INFO', 'ข้อมูล', '🔵'),

  /// Soft warning — dose exceeds recommended range.
  /// Clinician may override with justification.
  soft('WARNING', 'คำเตือน', '🟡'),

  /// Hard limit — dose exceeds maximum safe threshold.
  /// System MUST block unless explicitly overridden by senior clinician.
  hard('CRITICAL', 'อันตราย', '🔴');

  const LimitSeverity(this.labelEn, this.labelTh, this.icon);
  final String labelEn;
  final String labelTh;
  final String icon;
}

/// Defines the safe dosing boundaries for a drug regimen.
class DoseLimit {
  /// Minimum single dose (drug's own unit).
  final double? minSingleDose;

  /// Maximum single dose (drug's own unit).
  /// Exceeding this triggers a **hard** limit alert.
  final double? maxSingleDose;

  /// Soft-limit single dose — above this triggers a **soft** warning
  /// but below [maxSingleDose].
  final double? softMaxSingleDose;

  /// Maximum total daily dose (drug's own unit).
  final double? maxDailyDose;

  /// Maximum dose per kg per day (for weight-based drugs).
  final double? maxDosePerKgPerDay;

  /// Maximum infusion rate value.
  final double? maxInfusionRate;

  /// Unit string for the infusion rate limit (e.g. 'mg/min', 'mcg/kg/min').
  final String? infusionRateUnit;

  const DoseLimit({
    this.minSingleDose,
    this.maxSingleDose,
    this.softMaxSingleDose,
    this.maxDailyDose,
    this.maxDosePerKgPerDay,
    this.maxInfusionRate,
    this.infusionRateUnit,
  });

  @override
  String toString() =>
      'DoseLimit(max: $maxSingleDose, maxDaily: $maxDailyDose)';
}

/// A warning generated when a calculated dose approaches or exceeds limits.
class DoseWarning {
  /// How severe this warning is.
  final LimitSeverity severity;

  /// Human-readable message in English.
  final String messageEn;

  /// Human-readable message in Thai.
  final String messageTh;

  /// The value that triggered the warning (e.g. calculated dose).
  final double? calculatedValue;

  /// The limit threshold that was exceeded.
  final double? limitValue;

  /// Unit of [calculatedValue] and [limitValue].
  final String? unit;

  const DoseWarning({
    required this.severity,
    required this.messageEn,
    required this.messageTh,
    this.calculatedValue,
    this.limitValue,
    this.unit,
  });

  @override
  String toString() => '${severity.icon} [${severity.labelEn}] $messageEn';
}
