import 'drug_class.dart';

/// Clinical severity of a drug interaction (D9).
enum InteractionSeverity {
  minor(labelEn: 'Minor', labelTh: 'ระดับเล็กน้อย'),
  moderate(labelEn: 'Moderate', labelTh: 'ระดับปานกลาง'),
  major(labelEn: 'Major', labelTh: 'ระดับรุนแรง (Major)'),
  contraindicated(labelEn: 'Contraindicated', labelTh: 'ห้ามใช้ร่วมกันเด็ดขาด');

  final String labelEn;
  final String labelTh;

  const InteractionSeverity({required this.labelEn, required this.labelTh});
}

/// Structured drug-drug interaction definition (D9).
class DrugInteraction {
  /// Target drug ID if interaction is drug-specific.
  final String? targetDrugId;

  /// Target drug class if interaction applies to an entire drug class.
  final DrugClass? targetClass;

  /// Interaction severity level.
  final InteractionSeverity severity;

  /// Mechanism of interaction in English.
  final String mechanismEn;

  /// Mechanism of interaction in Thai.
  final String mechanismTh;

  /// Clinical management / action recommendation in English.
  final String managementEn;

  /// Clinical management / action recommendation in Thai.
  final String managementTh;

  /// Primary source citation or guideline reference.
  final String source;

  const DrugInteraction({
    this.targetDrugId,
    this.targetClass,
    required this.severity,
    required this.mechanismEn,
    required this.mechanismTh,
    required this.managementEn,
    required this.managementTh,
    required this.source,
  }) : assert(
          targetDrugId != null || targetClass != null,
          'Must specify targetDrugId or targetClass',
        );
}
