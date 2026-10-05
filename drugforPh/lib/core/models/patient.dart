// ============================================================
// Drug Dosage Calculator — Patient Data Model
// ============================================================
// Immutable patient record for pharmacokinetic calculations.
// All measurements use SI / standard clinical units.
//
// DISCLAIMER: SaMD prototype — not for clinical use.
// ============================================================

import 'unit.dart';
import 'population_criteria.dart';

/// Immutable patient data for dose calculations.
///
/// Standard units:
/// - Weight: kilograms (kg)
/// - Height: centimeters (cm)
/// - Serum creatinine: mg/dL
/// - Creatinine clearance: mL/min
/// - eGFR: mL/min/1.73 m²
class Patient {
  /// Body weight in kilograms.
  final double weightKg;

  /// Height in centimeters.
  final double heightCm;

  /// Age in completed years.
  final int ageYears;

  /// Additional months of age (for pediatric patients < 2 years).
  final int? ageMonths;

  /// Biological sex — required for CrCl, IBW, and some drug formulas.
  final Sex sex;

  /// Whether the patient is currently pregnant (D4).
  final bool isPregnant;

  /// Hepatic impairment classification, if assessed (D4).
  final ChildPughClass? hepaticImpairment;

  /// Serum creatinine in mg/dL.
  /// Required for Cockcroft-Gault and CKD-EPI calculations.
  final double? serumCreatinineMgDl;

  /// Pre-calculated creatinine clearance in mL/min.
  /// If provided, calculators may use this instead of re-calculating.
  final double? creatinineClearanceMlMin;

  /// Pre-calculated eGFR in mL/min/1.73 m².
  final double? eGfrMlMinPer173m2;

  /// Whether the serum creatinine is stable (important for Cockcroft-Gault validity).
  final bool isScrStable;

  /// List of drug IDs the patient is currently taking (for the dashboard).
  final List<String> activeDrugIds;

  /// List of drug names or classes the patient is allergic to.
  final List<String> allergies;

  /// Optional patient name for display.
  final String? patientName;

  /// Optional Hospital Number (HN) for identification.
  final String? hospitalNumber;

  /// Unique internal ID for managing lists.
  final String id;

  /// Convenience alias for [patientName].
  String? get name => patientName;

  /// Convenience alias for [hospitalNumber].
  String? get hn => hospitalNumber;

  const Patient({
    required this.id,
    this.patientName,
    this.hospitalNumber,
    required this.weightKg,
    required this.heightCm,
    required this.ageYears,
    this.ageMonths,
    required this.sex,
    this.isPregnant = false,
    this.hepaticImpairment,
    this.serumCreatinineMgDl,
    this.creatinineClearanceMlMin,
    this.eGfrMlMinPer173m2,
    this.isScrStable = true,
    this.activeDrugIds = const [],
    this.allergies = const [],
  });

  // ---- Derived properties ----

  /// Height converted to inches (for IBW calculation).
  double get heightInches => heightCm / 2.54;

  /// Whether this patient is pediatric (< 18 years).
  bool get isPediatric => ageYears < 18;

  /// Whether this patient is neonatal (< 28 days ≈ < 1 month).
  bool get isNeonatal => ageYears == 0 && (ageMonths == null || ageMonths! < 1);

  /// Whether this patient is an infant (1–12 months).
  bool get isInfant =>
      ageYears == 0 && ageMonths != null && ageMonths! >= 1 && ageMonths! < 12;

  /// Whether this patient is geriatric (≥ 65 years).
  bool get isGeriatric => ageYears >= 65;

  /// Total age expressed in months.
  int get totalAgeMonths => (ageYears * 12) + (ageMonths ?? 0);

  // ---- Copy ----

  // Sentinel constant for clearing nullable fields in copyWith
  static const Object _sentinel = Object();

  /// Creates a copy with selected fields replaced.
  /// Nullable fields can be explicitly cleared by passing `null`.
  Patient copyWith({
    String? id,
    Object? patientName = _sentinel,
    Object? hospitalNumber = _sentinel,
    double? weightKg,
    double? heightCm,
    int? ageYears,
    Object? ageMonths = _sentinel,
    Sex? sex,
    bool? isPregnant,
    Object? hepaticImpairment = _sentinel,
    Object? serumCreatinineMgDl = _sentinel,
    Object? creatinineClearanceMlMin = _sentinel,
    Object? eGfrMlMinPer173m2 = _sentinel,
    bool? isScrStable,
    List<String>? activeDrugIds,
    List<String>? allergies,
  }) {
    return Patient(
      id: id ?? this.id,
      patientName: identical(patientName, _sentinel)
          ? this.patientName
          : patientName as String?,
      hospitalNumber: identical(hospitalNumber, _sentinel)
          ? this.hospitalNumber
          : hospitalNumber as String?,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      ageYears: ageYears ?? this.ageYears,
      ageMonths: identical(ageMonths, _sentinel)
          ? this.ageMonths
          : ageMonths as int?,
      sex: sex ?? this.sex,
      isPregnant: isPregnant ?? this.isPregnant,
      hepaticImpairment: identical(hepaticImpairment, _sentinel)
          ? this.hepaticImpairment
          : hepaticImpairment as ChildPughClass?,
      serumCreatinineMgDl: identical(serumCreatinineMgDl, _sentinel)
          ? this.serumCreatinineMgDl
          : serumCreatinineMgDl as double?,
      creatinineClearanceMlMin: identical(creatinineClearanceMlMin, _sentinel)
          ? this.creatinineClearanceMlMin
          : creatinineClearanceMlMin as double?,
      eGfrMlMinPer173m2: identical(eGfrMlMinPer173m2, _sentinel)
          ? this.eGfrMlMinPer173m2
          : eGfrMlMinPer173m2 as double?,
      isScrStable: isScrStable ?? this.isScrStable,
      activeDrugIds: activeDrugIds ?? this.activeDrugIds,
      allergies: allergies ?? this.allergies,
    );
  }

  @override
  String toString() {
    final nameStr = patientName != null ? 'Name: [REDACTED], ' : '';
    final hnStr = hospitalNumber != null ? 'HN: [REDACTED], ' : '';
    final allergyStr =
        allergies.isNotEmpty ? 'Allergies: [REDACTED (${allergies.length})], ' : '';
    final pregStr = isPregnant ? 'pregnant, ' : '';
    return 'Patient($nameStr$hnStr$allergyStr$pregStr'
        'wt: ${weightKg}kg, ht: ${heightCm}cm, '
        'age: $ageYears y${ageMonths != null ? " ${ageMonths}m" : ""}, '
        'sex: ${sex.nameEn}'
        '${serumCreatinineMgDl != null ? ", SCr: $serumCreatinineMgDl" : ""})';
  }
}
