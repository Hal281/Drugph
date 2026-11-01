// ============================================================
// Drug Dosage Calculator — IV Diluent Compatibility Model
// ============================================================
// Type-safe bedside intravenous diluent compatibility and
// physical precipitation hazard metadata (NSS vs D5W vs LRS).
//
// Zero Flutter UI dependency, zero runtime AI/LLM.
// Primary References:
// - US FDA Structured Product Labeling (SPL)
// - Trissel's Handbook on Injectable Drugs / ASHP
// - Ramathibodi & Siriraj High-Alert IV Administration Manuals
// ============================================================

import 'provenance.dart';

/// Standard hospital intravenous diluents used at the bedside.
enum IvDiluent {
  nss(
    code: 'NSS',
    nameEn: '0.9% NaCl (NSS)',
    nameTh: '0.9% NaCl (น้ำเกลือ NSS)',
  ),
  d5w(
    code: 'D5W',
    nameEn: '5% Dextrose in Water (D5W)',
    nameTh: '5% Dextrose (น้ำตาล D5W)',
  ),
  d5nss(
    code: 'D5NSS',
    nameEn: '5% Dextrose in 0.9% NaCl (D5NSS)',
    nameTh: '5% Dextrose in NSS (D5NSS)',
  ),
  halfNss(
    code: '0.45% NaCl',
    nameEn: '0.45% NaCl (Half NSS)',
    nameTh: '0.45% NaCl (Half NSS)',
  ),
  lrs(
    code: 'LRS',
    nameEn: "Lactated Ringer's (LRS)",
    nameTh: "Lactated Ringer's (LRS — มีแคลเซียม)",
  ),
  sterileWater(
    code: 'SWFI',
    nameEn: 'Sterile Water for Injection (SWFI)',
    nameTh: 'น้ำกลั่นปราศจากเชื้อ (SWFI)',
  );

  final String code;
  final String nameEn;
  final String nameTh;

  const IvDiluent({
    required this.code,
    required this.nameEn,
    required this.nameTh,
  });
}

/// Immutable bedside IV diluent compatibility specification for a drug or regimen.
class IvDiluentCompatibility {
  /// Diluents verified as physically and chemically compatible for administration.
  final List<IvDiluent> compatibleDiluents;

  /// Clinically preferred primary diluent, if one is favored for stability or safety.
  final IvDiluent? preferredDiluent;

  /// Diluents that are strictly incompatible or clinically hazardous (e.g. precipitation).
  final List<IvDiluent> incompatibleDiluents;

  /// English pharmacological explanation of why [incompatibleDiluents] must be avoided.
  final String? incompatibilityReasonEn;

  /// Thai pharmacological explanation of why [incompatibleDiluents] must be avoided.
  final String? incompatibilityReasonTh;

  /// English bedside preparation, container (e.g. non-PVC), or room-temperature stability note.
  final String? stabilityNoteEn;

  /// Thai bedside preparation, container, or room-temperature stability note.
  final String? stabilityNoteTh;

  /// Authoritative textbook, hospital IV manual, or US FDA SPL citation.
  final String sourceCitation;

  /// Honest clinical verification status.
  final VerificationStatus verificationStatus;

  const IvDiluentCompatibility({
    required this.compatibleDiluents,
    this.preferredDiluent,
    this.incompatibleDiluents = const [],
    this.incompatibilityReasonEn,
    this.incompatibilityReasonTh,
    this.stabilityNoteEn,
    this.stabilityNoteTh,
    required this.sourceCitation,
    this.verificationStatus = VerificationStatus.pendingReview,
  });

  /// Returns `true` if [diluent] is explicitly marked as incompatible/hazardous.
  bool isIncompatible(IvDiluent diluent) =>
      incompatibleDiluents.contains(diluent);

  /// Returns `true` if [diluent] is explicitly listed as compatible.
  bool isCompatible(IvDiluent diluent) => compatibleDiluents.contains(diluent);

  /// Returns `true` if [diluent] is the preferred primary diluent.
  bool isPreferred(IvDiluent diluent) => preferredDiluent == diluent;

  /// Ordered set of bedside diluents relevant for interactive UI checking
  /// (always including core ward fluids `NSS`, `D5W`, and `LRS` plus any
  /// additional compatible or incompatible diluents specified on this entry).
  List<IvDiluent> get bedsideCheckDiluents {
    final ordered = <IvDiluent>[
      IvDiluent.nss,
      IvDiluent.d5w,
      IvDiluent.lrs,
    ];
    for (final d in compatibleDiluents) {
      if (!ordered.contains(d)) ordered.add(d);
    }
    for (final d in incompatibleDiluents) {
      if (!ordered.contains(d)) ordered.add(d);
    }
    return List.unmodifiable(ordered);
  }
}
