import 'frequency.dart';

/// Clinical action to take for a renal impairment tier (D5).
enum RenalAction {
  /// Adjust dose by factor, absolute dose, and/or frequency.
  adjust(labelEn: 'Dose Adjustment', labelTh: 'ปรับขนาดยา'),

  /// Clinically avoid use; produces a hard block with no calculated dose.
  avoid(labelEn: 'Avoid Use', labelTh: 'หลีกเลี่ยงการใช้'),

  /// Strictly contraindicated; produces a hard block with no calculated dose.
  contraindicated(labelEn: 'Contraindicated', labelTh: 'ข้อห้ามใช้เด็ดขาด'),

  /// Normal dose, but monitor renal function and drug levels.
  monitorOnly(labelEn: 'Monitor Closely', labelTh: 'ติดตามการทำงานของไตอย่างใกล้ชิด');

  final String labelEn;
  final String labelTh;

  const RenalAction({required this.labelEn, required this.labelTh});
}

/// Structured renal adjustment tier with half-open range `[crclMin, crclMax)` (D5).
class RenalAdjustment {
  /// Inclusive lower bound of CrCl range in mL/min: `[crclMin, crclMax)`.
  final double crclMin;

  /// Exclusive upper bound of CrCl range in mL/min: `[crclMin, crclMax)`.
  /// Use `double.infinity` for the upper ceiling tier.
  final double crclMax;

  /// Clinical action required for patients in this tier.
  final RenalAction action;

  /// Multiplier for the standard dose (e.g. 0.5 = 50% dose). Default is 1.0.
  final double adjustmentFactor;

  /// Specific absolute dose override in mg (or regimen dose unit).
  final double? absoluteDose;

  /// Structured frequency override for this renal tier.
  final Frequency? adjustedFrequency;

  /// English clinical notes and rationale.
  final String? notes;

  /// Thai clinical notes and rationale.
  final String? notesTh;

  const RenalAdjustment({
    required this.crclMin,
    required this.crclMax,
    this.action = RenalAction.adjust,
    this.adjustmentFactor = 1.0,
    this.absoluteDose,
    this.adjustedFrequency,
    this.notes,
    this.notesTh,
  }) : assert(crclMin < crclMax, 'crclMin ($crclMin) must be strictly less than crclMax ($crclMax)');

  /// Checks whether a patient's [crcl] falls in the half-open interval `[crclMin, crclMax)`.
  ///
  /// Reference: D5 half-open range policy.
  bool appliesTo(double crcl) => crcl >= crclMin && crcl < crclMax;
}
