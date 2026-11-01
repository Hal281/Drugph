// ============================================================
// Drug Dosage Calculator — Renal Replacement Therapy (RRT) Mode
// ============================================================
// Types representing dialysis and continuous renal replacement
// modalities for ICU, nephrology, and ward clinical care.
//
// Zero Flutter UI dependency, 100% pure Dart.
// ============================================================

/// Modality of Renal Replacement Therapy (RRT) for dialysis or continuous filtration.
enum RenalReplacementMode {
  /// Standard patient with native renal function (no dialysis / filtration).
  none(
    labelEn: 'None (Standard)',
    labelTh: 'ปกติ (ไม่ล้างไต)',
    badgeEn: 'Standard',
    badgeTh: 'ปกติ',
  ),

  /// Intermittent Hemodialysis (IHD), typically 3 sessions/week.
  ihd(
    labelEn: 'Intermittent Hemodialysis (IHD)',
    labelTh: 'ฟอกเลือดด้วยเครื่องไตเทียม (IHD)',
    badgeEn: 'IHD',
    badgeTh: 'IHD (ฟอกเลือด)',
  ),

  /// Continuous Ambulatory Peritoneal Dialysis (CAPD).
  capd(
    labelEn: 'Continuous Ambulatory Peritoneal Dialysis (CAPD)',
    labelTh: 'ล้างไตทางช่องท้อง (CAPD)',
    badgeEn: 'CAPD',
    badgeTh: 'CAPD (ล้างไตทางช่องท้อง)',
  ),

  /// Continuous Renal Replacement Therapy (CRRT: CVVH, CVVHD, CVVHDF) in ICU.
  crrt(
    labelEn: 'Continuous Renal Replacement Therapy (CRRT)',
    labelTh: 'บำบัดทดแทนไตแบบต่อเนื่อง (CRRT)',
    badgeEn: 'CRRT',
    badgeTh: 'CRRT (บำบัดทดแทนไตต่อเนื่อง)',
  );

  final String labelEn;
  final String labelTh;
  final String badgeEn;
  final String badgeTh;

  const RenalReplacementMode({
    required this.labelEn,
    required this.labelTh,
    required this.badgeEn,
    required this.badgeTh,
  });

  /// True if the patient is undergoing active renal replacement therapy.
  bool get isRrt => this != RenalReplacementMode.none;

  /// True if intermittent hemodialysis where post-HD supplement may be needed.
  bool get isIhd => this == RenalReplacementMode.ihd;

  /// True if continuous renal replacement therapy in ICU.
  bool get isCrrt => this == RenalReplacementMode.crrt;

  /// True if peritoneal dialysis.
  bool get isCapd => this == RenalReplacementMode.capd;

  /// Clinical values list for UI dropdown selectors.
  static List<RenalReplacementMode> get clinicalValues =>
      [none, ihd, capd, crrt];
}
