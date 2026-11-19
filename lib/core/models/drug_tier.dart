/// Formulary scope tier classification for medications in Drugph (FB-21, WP-08).
///
/// Follows Locked Product Decisions Q1 & Q2:
/// - [core]: Primary Pediatric Dosing & Hospital Injectables formulary.
/// - [extended]: General adult & specialty catalog medications kept accessible.
/// - [referenceOnly]: High-complexity oncology / transplant specialist drugs
///   whose automated bedside calculation is gated in favor of monograph review.
enum DrugTier {
  core(labelEn: 'Core', labelTh: 'Core (ยาหลัก)'),
  extended(labelEn: 'Extended', labelTh: 'Extended'),
  referenceOnly(
    labelEn: 'Reference Only',
    labelTh: 'Reference Only (อ้างอิงเฉพาะทาง)',
  );

  final String labelEn;
  final String labelTh;

  const DrugTier({required this.labelEn, required this.labelTh});
}
