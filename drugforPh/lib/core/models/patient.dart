// ============================================================
// Drug Dosage Calculator — Patient Data Model
// ============================================================
// Immutable patient record for pharmacokinetic calculations.
// All measurements use SI / standard clinical units.
//
// DISCLAIMER: SaMD prototype — not for clinical use.
// ============================================================

import 'unit.dart';

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

  const Patient({
    required this.id,
    this.patientName,
    this.hospitalNumber,
    required this.weightKg,
    required this.heightCm,
    required this.ageYears,
    this.ageMonths,
    required this.sex,
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

  /// Creates a copy with selected fields replaced.
  Patient copyWith({
    String? id,
    String? patientName,
    String? hospitalNumber,
    double? weightKg,
    double? heightCm,
    int? ageYears,
    int? ageMonths,
    Sex? sex,
    double? serumCreatinineMgDl,
    double? creatinineClearanceMlMin,
    double? eGfrMlMinPer173m2,
    bool? isScrStable,
    List<String>? activeDrugIds,
    List<String>? allergies,
  }) {
    return Patient(
      id: id ?? this.id,
      patientName: patientName ?? this.patientName,
      hospitalNumber: hospitalNumber ?? this.hospitalNumber,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      ageYears: ageYears ?? this.ageYears,
      ageMonths: ageMonths ?? this.ageMonths,
      sex: sex ?? this.sex,
      serumCreatinineMgDl: serumCreatinineMgDl ?? this.serumCreatinineMgDl,
      creatinineClearanceMlMin:
          creatinineClearanceMlMin ?? this.creatinineClearanceMlMin,
      eGfrMlMinPer173m2: eGfrMlMinPer173m2 ?? this.eGfrMlMinPer173m2,
      isScrStable: isScrStable ?? this.isScrStable,
      activeDrugIds: activeDrugIds ?? this.activeDrugIds,
      allergies: allergies ?? this.allergies,
    );
  }

  @override
  String toString() {
    final nameStr = patientName != null ? 'Name: $patientName, ' : '';
    final hnStr = hospitalNumber != null ? 'HN: $hospitalNumber, ' : '';
    final allergyStr = allergies.isNotEmpty ? 'Allergies: ${allergies.join(", ")}, ' : '';
    return 'Patient($nameStr$hnStr$allergyStr'
        'wt: ${weightKg}kg, ht: ${heightCm}cm, '
        'age: $ageYears y${ageMonths != null ? " ${ageMonths}m" : ""}, '
        'sex: ${sex.nameEn}'
        '${serumCreatinineMgDl != null ? ", SCr: $serumCreatinineMgDl" : ""})';
  }
}
