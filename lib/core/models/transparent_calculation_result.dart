/// Transparent Calculation Result Models (Pillar 2: No Black-Box Output).
///
/// Enforces a Unified Non-Blocking Policy across Overdose, Renal Contraindication
/// ("Avoid"), and Allergy alerts: calculated doses and volumes are NEVER hidden
/// or zeroed out; instead, explicit safety alerts and flags are attached.
library;

import 'verified_drug_schema.dart';

/// Exception thrown immediately when patient input is clinically invalid
/// (e.g., `weightKg <= 0`, `ageYears < 0`, `crclMlMin < 0`, `dosesPerDay <= 0`,
/// or `concentrationMgPerMl <= 0`).
class InvalidPatientInputException implements Exception {
  final String field;
  final String message;

  const InvalidPatientInputException({
    required this.field,
    required this.message,
  });

  @override
  String toString() => 'InvalidPatientInputException($field): $message';
}

/// 3-state clinical allergy assessment status so that an unassessed allergy list
/// is never falsely recorded as "No Known Drug Allergies (NKDA)".
enum AllergyAssessmentStatus {
  /// Allergy history has not yet been asked or verified.
  notAssessed,

  /// Clinician explicitly confirmed the patient has No Known Drug Allergies (NKDA).
  nkdaConfirmed,

  /// Patient has one or more documented drug allergies.
  hasAllergies,
}

/// Summary of validated patient parameters with explicit clinical units,
/// distinguishing pediatric Bedside Schwartz eGFR (`mL/min/1.73m²`) from
/// adult Cockcroft-Gault CrCl (`mL/min`), and distinguishing unassessed
/// parameters from confirmed negative findings.
class TransparentPatientInputSummary {
  final double weightKg;
  final double? ageYears;
  final double? crclMlMin;
  final String renalMetricType;
  final List<String> allergies;
  final AllergyAssessmentStatus allergyAssessmentStatus;
  final List<String> concomitantMedications;

  const TransparentPatientInputSummary({
    required this.weightKg,
    this.ageYears,
    this.crclMlMin,
    this.renalMetricType = 'crcl_cockcroft_gault_ml_min',
    this.allergies = const [],
    AllergyAssessmentStatus? allergyAssessmentStatus,
    this.concomitantMedications = const [],
  }) : allergyAssessmentStatus = allergyAssessmentStatus ??
            (allergies.length > 0
                ? AllergyAssessmentStatus.hasAllergies
                : AllergyAssessmentStatus.notAssessed);

  String get renalUnitLabel =>
      renalMetricType == 'eGFR_schwartz_ml_min_1_73m2'
          ? 'mL/min/1.73m² (Schwartz)'
          : 'mL/min (Cockcroft-Gault)';

  String get formattedAllergyStatus {
    if (allergies.isNotEmpty) {
      return allergies.join(', ');
    }
    return switch (allergyAssessmentStatus) {
      AllergyAssessmentStatus.nkdaConfirmed => 'ปฏิเสธแพ้ยา (NKDA ยืนยันแล้ว)',
      AllergyAssessmentStatus.notAssessed => 'ไม่ได้ประเมิน (Not Assessed)',
      AllergyAssessmentStatus.hasAllergies => 'ไม่ได้ระบุชื่อยาที่แพ้',
    };
  }

  String toFormattedString() {
    final parts = <String>[
      'น้ำหนัก: ${weightKg.toStringAsFixed(1)} kg',
      ageYears != null
          ? 'อายุ: ${ageYears!.toStringAsFixed(2)} ปี'
          : 'อายุ: ไม่ได้ประเมิน (Not Assessed)',
      crclMlMin != null
          ? 'ค่าไต: ${crclMlMin!.toStringAsFixed(2)} $renalUnitLabel'
          : 'ค่าไต: ไม่ได้ประเมิน (Not Assessed)',
      'ประวัติแพ้ยา: $formattedAllergyStatus',
      'ยาร่วมปัจจุบัน: ${concomitantMedications.isEmpty ? "ไม่มีที่ระบุ" : concomitantMedications.join(", ")}',
    ];
    return parts.join(' | ');
  }

  Map<String, dynamic> toJson() => {
        'weight_kg': weightKg,
        'age_years': ageYears,
        'crcl_ml_min': crclMlMin,
        'renal_metric_type': renalMetricType,
        'allergies': allergies,
        'allergy_assessment_status': allergyAssessmentStatus.name,
        'concomitant_medications': concomitantMedications,
        'formatted_summary': toFormattedString(),
      };
}

enum SafetyAlertType {
  overdoseWarning,
  subtherapeuticDoseWarning,
  frequencyExceedsMaxWarning,
  renalAdjustment,
  allergySynonymMatch,
  allergySameClass,
  allergyCrossReactivity,
  drugInteraction,
  patientCriteriaWarning,
  unassessedInputNotice,
  unrecognizedMedicationNotice,
  roundingDeviationWarning,
}

enum SafetyAlertSeverity {
  info,
  minor,
  moderate,
  major,
  contraindicated,
  criticalOverdose,
}

/// Structured clinical safety alert with mechanism, management, database source,
/// and textbook reference.
class TransparentSafetyAlert {
  final SafetyAlertType type;
  final SafetyAlertSeverity severity;
  final String title;
  final String message;
  final String mechanism;
  final String management;
  final String reference;
  final String? databaseSource;

  const TransparentSafetyAlert({
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.mechanism,
    required this.management,
    required this.reference,
    this.databaseSource,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'severity': severity.name,
        'title': title,
        'message': message,
        'mechanism': mechanism,
        'management': management,
        'reference': reference,
        if (databaseSource != null) 'database_source': databaseSource,
      };
}

/// Complete, auditable return object for Pillar 2 (Transparent Calculation Engine).
class TransparentCalculationResult {
  /// 1. Validated input summary with units.
  final TransparentPatientInputSummary inputSummary;

  /// 2. Standard mathematical equation selected for this calculation.
  final String formulaUsed;

  /// 3. Line-by-line substitution breakdown (`calculation_steps`).
  final List<String> calculationSteps;

  /// 4. Clinical safety alerts (Max Dose / Non-Blocking Overdose, Renal,
  ///    Synonym/Same-Class/Cross-Reactivity Allergy, DDI, Age/Weight Criteria,
  ///    Unassessed Inputs, Unrecognized Drugs, and Volume Rounding Deviation).
  final List<TransparentSafetyAlert> safetyAlerts;

  /// 5. Textbook reference citation for the formula and drug entry.
  final VerificationMetadata referenceCitation;

  // --- Drug Metadata ---
  final String drugId;
  final String genericName;
  final String strengthLabel;
  final double concentrationMgPerMl;
  final String formulaType;
  final int dosesPerDay;
  final String recommendedFrequency;
  final String roundingRuleUsed;

  // --- Dose & Volume Breakdown (Exact vs Practical & Raw vs Capped) ---
  /// Raw total daily dose (mg/day) calculated strictly from weight before ceiling cap.
  final double rawCalculatedDailyDoseMg;

  /// Raw single dose (mg/dose) calculated strictly from weight before ceiling cap.
  final double rawCalculatedSingleDoseMg;

  /// Renal dose adjustment factor applied (`1.0` normal/interval-only, `< 1.0` reduced).
  final double renalDoseAdjustmentFactor;

  /// Final recommended single dose (mg/dose) after applying Max Single Dose cap,
  /// Max mg/kg cap, and renal factor.
  /// Under the Unified Non-Blocking Policy, this is NEVER zeroed out for allergy or renal "Avoid".
  final double finalRecommendedSingleDoseMg;

  /// Final recommended daily dose (mg/day) equals `finalRecommendedSingleDoseMg * dosesPerDay`,
  /// guaranteed never to exceed `effectiveMaxDailyDoseMg`.
  final double finalRecommendedDailyDoseMg;

  /// Exact mathematical volume (mL) for `finalRecommendedSingleDoseMg` (`dose / concentration`).
  final double exactVolumeMl;

  /// Clinically measurable volume (mL) rounded via Round Half Away From Zero.
  final double practicalVolumeMl;

  /// Number of decimal places used for `practicalVolumeMl` (`2` for `< 1.0 mL`
  /// on a 1 mL syringe with 0.01 mL graduations, `1` for `>= 1.0 mL`).
  final int practicalVolumeDecimalsUsed;

  /// Actual dose (mg) delivered to the patient when drawing `practicalVolumeMl`
  /// (`practicalVolumeMl * concentrationMgPerMl`).
  final double actualDeliveredSingleDoseMg;

  /// Difference (mg) between `actualDeliveredSingleDoseMg` and `finalRecommendedSingleDoseMg`.
  final double roundingDiscrepancyMg;

  /// Percentage difference (%) caused by rounding `exactVolumeMl` to `practicalVolumeMl`.
  final double roundingDiscrepancyPercent;

  /// Recommended measuring device (`1 mL Syringe`, `5 mL Syringe`, `10 mL Syringe`,
  /// `20 mL Syringe`, or `Graduated Medication Cup` when > 20 mL).
  final String dispensingDeviceRecommendation;

  /// Exact mathematical volume (mL) for the unclipped `rawCalculatedSingleDoseMg`
  /// (preserved under Non-Blocking Overdose Policy).
  final double rawUnclippedExactVolumeMl;

  /// Practical rounded volume (mL) for the unclipped `rawCalculatedSingleDoseMg`.
  final double rawUnclippedPracticalVolumeMl;

  // --- Audit Flags ---
  final bool isSingleDoseCappedAtMax;
  final bool isDailyDoseCappedAtMax;
  final bool isMgPerKgCappedAtMax;
  final bool isDoseBelowMinimumRange;
  final bool isFrequencyReducedForDailyMax;
  final bool isRenallyContraindicated;
  final bool hasAllergyAlert;
  final bool hasDrugInteractionAlert;
  final bool isAgeBelowMinimumCriteria;
  final bool isWeightBelowMinimumCriteria;
  final int totalSafetyRulesEvaluated;
  final List<String> unrecognizedAllergies;
  final List<String> unrecognizedConcomitantMedications;

  const TransparentCalculationResult({
    required this.inputSummary,
    required this.formulaUsed,
    required this.calculationSteps,
    required this.safetyAlerts,
    required this.referenceCitation,
    required this.drugId,
    required this.genericName,
    required this.strengthLabel,
    required this.concentrationMgPerMl,
    required this.formulaType,
    required this.dosesPerDay,
    required this.recommendedFrequency,
    this.roundingRuleUsed = 'ROUND_HALF_AWAY_FROM_ZERO',
    required this.rawCalculatedDailyDoseMg,
    required this.rawCalculatedSingleDoseMg,
    required this.renalDoseAdjustmentFactor,
    required this.finalRecommendedSingleDoseMg,
    required this.finalRecommendedDailyDoseMg,
    required this.exactVolumeMl,
    required this.practicalVolumeMl,
    this.practicalVolumeDecimalsUsed = 1,
    required this.actualDeliveredSingleDoseMg,
    required this.roundingDiscrepancyMg,
    required this.roundingDiscrepancyPercent,
    required this.dispensingDeviceRecommendation,
    required this.rawUnclippedExactVolumeMl,
    required this.rawUnclippedPracticalVolumeMl,
    required this.isSingleDoseCappedAtMax,
    required this.isDailyDoseCappedAtMax,
    this.isMgPerKgCappedAtMax = false,
    this.isDoseBelowMinimumRange = false,
    this.isFrequencyReducedForDailyMax = false,
    required this.isRenallyContraindicated,
    required this.hasAllergyAlert,
    required this.hasDrugInteractionAlert,
    this.isAgeBelowMinimumCriteria = false,
    this.isWeightBelowMinimumCriteria = false,
    this.totalSafetyRulesEvaluated = 0,
    this.unrecognizedAllergies = const [],
    this.unrecognizedConcomitantMedications = const [],
  });

  /// Returns only clinically actionable alerts (severity above `info`).
  List<TransparentSafetyAlert> get actionableSafetyAlerts => safetyAlerts
      .where((a) => a.severity != SafetyAlertSeverity.info)
      .toList(growable: false);

  /// Returns informational notices (e.g. unassessed age/renal/allergy parameters).
  List<TransparentSafetyAlert> get informationalNotices => safetyAlerts
      .where((a) => a.severity == SafetyAlertSeverity.info)
      .toList(growable: false);

  Map<String, dynamic> toJson() => {
        'input_summary': inputSummary.toJson(),
        'formula_used': formulaUsed,
        'calculation_steps': calculationSteps,
        'safety_alerts': safetyAlerts.map((a) => a.toJson()).toList(),
        'reference_citation': referenceCitation.toJson(),
        'drug_id': drugId,
        'generic_name': genericName,
        'strength_label': strengthLabel,
        'concentration_mg_per_ml': concentrationMgPerMl,
        'formula_type': formulaType,
        'doses_per_day': dosesPerDay,
        'recommended_frequency': recommendedFrequency,
        'rounding_rule_used': roundingRuleUsed,
        'raw_calculated_daily_dose_mg': rawCalculatedDailyDoseMg,
        'raw_calculated_single_dose_mg': rawCalculatedSingleDoseMg,
        'renal_dose_adjustment_factor': renalDoseAdjustmentFactor,
        'final_recommended_single_dose_mg': finalRecommendedSingleDoseMg,
        'final_recommended_daily_dose_mg': finalRecommendedDailyDoseMg,
        'exact_volume_ml': exactVolumeMl,
        'practical_volume_ml': practicalVolumeMl,
        'practical_volume_decimals_used': practicalVolumeDecimalsUsed,
        'actual_delivered_single_dose_mg': actualDeliveredSingleDoseMg,
        'rounding_discrepancy_mg': roundingDiscrepancyMg,
        'rounding_discrepancy_percent': roundingDiscrepancyPercent,
        'dispensing_device_recommendation': dispensingDeviceRecommendation,
        'raw_unclipped_exact_volume_ml': rawUnclippedExactVolumeMl,
        'raw_unclipped_practical_volume_ml': rawUnclippedPracticalVolumeMl,
        'is_single_dose_capped_at_max': isSingleDoseCappedAtMax,
        'is_daily_dose_capped_at_max': isDailyDoseCappedAtMax,
        'is_mg_per_kg_capped_at_max': isMgPerKgCappedAtMax,
        'is_dose_below_minimum_range': isDoseBelowMinimumRange,
        'is_frequency_reduced_for_daily_max': isFrequencyReducedForDailyMax,
        'is_renally_contraindicated': isRenallyContraindicated,
        'has_allergy_alert': hasAllergyAlert,
        'has_drug_interaction_alert': hasDrugInteractionAlert,
        'is_age_below_minimum_criteria': isAgeBelowMinimumCriteria,
        'is_weight_below_minimum_criteria': isWeightBelowMinimumCriteria,
        'total_safety_rules_evaluated': totalSafetyRulesEvaluated,
        'unrecognized_allergies': unrecognizedAllergies,
        'unrecognized_concomitant_medications':
            unrecognizedConcomitantMedications,
      };
}
