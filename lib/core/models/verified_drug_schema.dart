/// Verified Drug Knowledge Base Schema Models (Pillar 1).
///
/// Enforces a strict, deterministic, textbook-linked structure for drug
/// dosing rules, renal adjustments, allergy synonym/same-class/cross-reactivity,
/// drug-drug interactions (with database attribution and brand/Thai aliases),
/// and verification metadata (requiring `sourceVerified`, `verifiedBy`, and
/// `verifiedDate` before showing a green verified status).
library;

class VerifiedDrugKnowledgeBase {
  final String schemaVersion;
  final String renalRangeEvaluationRule;
  final List<VerifiedDrugEntry> drugs;

  const VerifiedDrugKnowledgeBase({
    required this.schemaVersion,
    required this.renalRangeEvaluationRule,
    required this.drugs,
  });

  factory VerifiedDrugKnowledgeBase.fromJson(Map<String, dynamic> json) {
    final rawDrugs = json['drugs'];
    if (rawDrugs is! List) {
      throw const FormatException('Field "drugs" must be a JSON List.');
    }
    return VerifiedDrugKnowledgeBase(
      schemaVersion: (json['schema_version'] as String?) ?? '',
      renalRangeEvaluationRule:
          (json['renal_range_evaluation_rule'] as String?) ??
              'crcl >= crcl_min_ml_min && crcl < crcl_max_ml_min',
      drugs: rawDrugs
          .map((e) => VerifiedDrugEntry.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
        'schema_version': schemaVersion,
        'renal_range_evaluation_rule': renalRangeEvaluationRule,
        'drugs': drugs.map((d) => d.toJson()).toList(),
      };

  /// Finds a drug entry by exact match on [drugId], [rxnormId], [genericName],
  /// or [synonyms]. Does NOT use loose substring `.contains()` to prevent
  /// Look-Alike Sound-Alike (LASA) medication selection errors.
  VerifiedDrugEntry? findDrug(String idOrName) {
    final normalized = idOrName.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    for (final entry in drugs) {
      final info = entry.drugInfo;
      if (info.drugId.trim().toLowerCase() == normalized ||
          info.rxnormId.trim().toLowerCase() == normalized ||
          info.genericName.trim().toLowerCase() == normalized ||
          info.synonyms.any((s) => s.trim().toLowerCase() == normalized)) {
        return entry;
      }
    }
    return null;
  }
}

class VerifiedDrugEntry {
  final VerifiedDrugInfo drugInfo;
  final VerifiedDosingRules dosingRules;
  final VerifiedSafetyChecks safetyChecks;
  final VerificationMetadata verificationMetadata;

  const VerifiedDrugEntry({
    required this.drugInfo,
    required this.dosingRules,
    required this.safetyChecks,
    required this.verificationMetadata,
  });

  factory VerifiedDrugEntry.fromJson(Map<String, dynamic> json) {
    return VerifiedDrugEntry(
      drugInfo: VerifiedDrugInfo.fromJson(
        json['drug_info'] as Map<String, dynamic>,
      ),
      dosingRules: VerifiedDosingRules.fromJson(
        json['dosing_rules'] as Map<String, dynamic>,
      ),
      safetyChecks: VerifiedSafetyChecks.fromJson(
        json['safety_checks'] as Map<String, dynamic>,
      ),
      verificationMetadata: VerificationMetadata.fromJson(
        json['verification_metadata'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'drug_info': drugInfo.toJson(),
        'dosing_rules': dosingRules.toJson(),
        'safety_checks': safetyChecks.toJson(),
        'verification_metadata': verificationMetadata.toJson(),
      };
}

class VerifiedDrugInfo {
  final String drugId;
  final String genericName;
  final List<String> synonyms;
  final String rxnormId;
  final String therapeuticClass;
  final String dosageForm;
  final String strengthLabel;
  final double concentrationMgPerMl;
  final String dispensingUnit;

  const VerifiedDrugInfo({
    required this.drugId,
    required this.genericName,
    this.synonyms = const [],
    required this.rxnormId,
    required this.therapeuticClass,
    required this.dosageForm,
    required this.strengthLabel,
    required this.concentrationMgPerMl,
    required this.dispensingUnit,
  });

  factory VerifiedDrugInfo.fromJson(Map<String, dynamic> json) {
    final rawSynonyms = (json['synonyms'] as List?) ?? const [];
    return VerifiedDrugInfo(
      drugId: (json['drug_id'] as String?) ?? '',
      genericName: (json['generic_name'] as String?) ?? '',
      synonyms: rawSynonyms.map((e) => e.toString()).toList(growable: false),
      rxnormId: (json['rxnorm_id'] as String?) ?? '',
      therapeuticClass: (json['therapeutic_class'] as String?) ?? '',
      dosageForm: (json['dosage_form'] as String?) ?? '',
      strengthLabel: (json['strength_label'] as String?) ?? '',
      concentrationMgPerMl:
          (json['concentration_mg_per_ml'] as num?)?.toDouble() ?? 0.0,
      dispensingUnit: (json['dispensing_unit'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'drug_id': drugId,
        'generic_name': genericName,
        'synonyms': synonyms,
        'rxnorm_id': rxnormId,
        'therapeutic_class': therapeuticClass,
        'dosage_form': dosageForm,
        'strength_label': strengthLabel,
        'concentration_mg_per_ml': concentrationMgPerMl,
        'dispensing_unit': dispensingUnit,
      };
}

class VerifiedDosingRules {
  final String indication;
  final VerifiedPatientCriteria patientCriteria;
  final String formulaType;
  final VerifiedDoseRange doseRange;
  final String frequencyHours;
  final int maxDosesPerDay;
  final double maxSingleDoseMg;
  final double maxDailyDoseMg;
  final double maxDailyDoseMgPerKg;
  final bool nonBlockingOverdosePolicy;
  final List<VerifiedRenalAdjustmentTier> renalAdjustment;

  const VerifiedDosingRules({
    required this.indication,
    required this.patientCriteria,
    required this.formulaType,
    required this.doseRange,
    required this.frequencyHours,
    required this.maxDosesPerDay,
    required this.maxSingleDoseMg,
    required this.maxDailyDoseMg,
    required this.maxDailyDoseMgPerKg,
    required this.nonBlockingOverdosePolicy,
    required this.renalAdjustment,
  });

  factory VerifiedDosingRules.fromJson(Map<String, dynamic> json) {
    final rawRenal = (json['renal_adjustment'] as List?) ?? const [];
    return VerifiedDosingRules(
      indication: (json['indication'] as String?) ?? '',
      patientCriteria: VerifiedPatientCriteria.fromJson(
        (json['patient_criteria'] as Map<String, dynamic>?) ?? const {},
      ),
      formulaType: (json['formula_type'] as String?) ?? '',
      doseRange: VerifiedDoseRange.fromJson(
        (json['dose_range'] as Map<String, dynamic>?) ?? const {},
      ),
      frequencyHours: (json['frequency_hours'] as String?) ?? '',
      maxDosesPerDay: (json['max_doses_per_day'] as num?)?.toInt() ?? 0,
      maxSingleDoseMg:
          (json['max_single_dose_mg'] as num?)?.toDouble() ?? 0.0,
      maxDailyDoseMg: (json['max_daily_dose_mg'] as num?)?.toDouble() ?? 0.0,
      maxDailyDoseMgPerKg:
          (json['max_daily_dose_mg_per_kg'] as num?)?.toDouble() ?? 0.0,
      nonBlockingOverdosePolicy:
          (json['non_blocking_overdose_policy'] as bool?) ?? false,
      renalAdjustment: rawRenal
          .map(
            (e) => VerifiedRenalAdjustmentTier.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
    );
  }

  /// Resolves the matching renal adjustment tier using the half-open interval rule:
  /// `crcl >= crcl_min_ml_min && crcl < crcl_max_ml_min`.
  VerifiedRenalAdjustmentTier? findRenalAdjustmentForCrCl(double crcl) {
    if (crcl < 0 || crcl.isNaN) return null;
    for (final tier in renalAdjustment) {
      if (tier.matchesCrCl(crcl)) {
        return tier;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'indication': indication,
        'patient_criteria': patientCriteria.toJson(),
        'formula_type': formulaType,
        'dose_range': doseRange.toJson(),
        'frequency_hours': frequencyHours,
        'max_doses_per_day': maxDosesPerDay,
        'max_single_dose_mg': maxSingleDoseMg,
        'max_daily_dose_mg': maxDailyDoseMg,
        'max_daily_dose_mg_per_kg': maxDailyDoseMgPerKg,
        'non_blocking_overdose_policy': nonBlockingOverdosePolicy,
        'renal_adjustment': renalAdjustment.map((r) => r.toJson()).toList(),
      };
}

class VerifiedPatientCriteria {
  final int minAgeMonths;
  final int maxAgeYears;
  final double minWeightKg;

  const VerifiedPatientCriteria({
    required this.minAgeMonths,
    required this.maxAgeYears,
    required this.minWeightKg,
  });

  factory VerifiedPatientCriteria.fromJson(Map<String, dynamic> json) {
    return VerifiedPatientCriteria(
      minAgeMonths: (json['min_age_months'] as num?)?.toInt() ?? 0,
      maxAgeYears: (json['max_age_years'] as num?)?.toInt() ?? 0,
      minWeightKg: (json['min_weight_kg'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'min_age_months': minAgeMonths,
        'max_age_years': maxAgeYears,
        'min_weight_kg': minWeightKg,
      };
}

class VerifiedDoseRange {
  final double minMgPerKgPerDose;
  final double recommendedMgPerKgPerDose;
  final double maxMgPerKgPerDose;

  const VerifiedDoseRange({
    required this.minMgPerKgPerDose,
    required this.recommendedMgPerKgPerDose,
    required this.maxMgPerKgPerDose,
  });

  factory VerifiedDoseRange.fromJson(Map<String, dynamic> json) {
    return VerifiedDoseRange(
      minMgPerKgPerDose:
          (json['min_mg_per_kg_per_dose'] as num?)?.toDouble() ?? 0.0,
      recommendedMgPerKgPerDose:
          (json['recommended_mg_per_kg_per_dose'] as num?)?.toDouble() ?? 0.0,
      maxMgPerKgPerDose:
          (json['max_mg_per_kg_per_dose'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'min_mg_per_kg_per_dose': minMgPerKgPerDose,
        'recommended_mg_per_kg_per_dose': recommendedMgPerKgPerDose,
        'max_mg_per_kg_per_dose': maxMgPerKgPerDose,
      };
}

class VerifiedRenalAdjustmentTier {
  final double crclMinMlMin;
  final double crclMaxMlMin;
  final String adjustedInterval;
  final int? adjustedDosesPerDay;
  final double doseAdjustmentFactor;
  final bool isContraindicated;
  final String clinicalNote;

  const VerifiedRenalAdjustmentTier({
    required this.crclMinMlMin,
    required this.crclMaxMlMin,
    required this.adjustedInterval,
    this.adjustedDosesPerDay,
    required this.doseAdjustmentFactor,
    this.isContraindicated = false,
    required this.clinicalNote,
  });

  factory VerifiedRenalAdjustmentTier.fromJson(Map<String, dynamic> json) {
    return VerifiedRenalAdjustmentTier(
      crclMinMlMin: (json['crcl_min_ml_min'] as num?)?.toDouble() ?? 0.0,
      crclMaxMlMin: (json['crcl_max_ml_min'] as num?)?.toDouble() ?? 0.0,
      adjustedInterval: (json['adjusted_interval'] as String?) ?? '',
      adjustedDosesPerDay: (json['adjusted_doses_per_day'] as num?)?.toInt(),
      doseAdjustmentFactor:
          (json['dose_adjustment_factor'] as num?)?.toDouble() ?? -1.0,
      isContraindicated: (json['is_contraindicated'] as bool?) ?? false,
      clinicalNote: (json['clinical_note'] as String?) ?? '',
    );
  }

  /// Strict half-open interval check: `crcl >= crclMinMlMin && crcl < crclMaxMlMin`.
  bool matchesCrCl(double crcl) {
    return crcl >= crclMinMlMin && crcl < crclMaxMlMin;
  }

  Map<String, dynamic> toJson() => {
        'crcl_min_ml_min': crclMinMlMin,
        'crcl_max_ml_min': crclMaxMlMin,
        'adjusted_interval': adjustedInterval,
        if (adjustedDosesPerDay != null)
          'adjusted_doses_per_day': adjustedDosesPerDay,
        'dose_adjustment_factor': doseAdjustmentFactor,
        'is_contraindicated': isContraindicated,
        'clinical_note': clinicalNote,
      };
}

class VerifiedSafetyChecks {
  final List<VerifiedAllergyCrossReactivity> allergyCrossReactivity;
  final List<VerifiedDrugInteraction> drugInteractions;

  const VerifiedSafetyChecks({
    required this.allergyCrossReactivity,
    required this.drugInteractions,
  });

  factory VerifiedSafetyChecks.fromJson(Map<String, dynamic> json) {
    final rawAllergy = (json['allergy_cross_reactivity'] as List?) ?? const [];
    final rawDdi = (json['drug_interactions'] as List?) ?? const [];
    return VerifiedSafetyChecks(
      allergyCrossReactivity: rawAllergy
          .map(
            (e) => VerifiedAllergyCrossReactivity.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
      drugInteractions: rawDdi
          .map(
            (e) => VerifiedDrugInteraction.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
        'allergy_cross_reactivity':
            allergyCrossReactivity.map((a) => a.toJson()).toList(),
        'drug_interactions': drugInteractions.map((d) => d.toJson()).toList(),
      };
}

class VerifiedAllergyCrossReactivity {
  /// One of `"synonym"`, `"same_class"`, or `"cross_reactivity"`.
  final String matchType;
  final String allergenGroup;
  final List<String> crossReactiveAgents;
  final String riskLevel;
  final String mechanism;
  final String action;
  final String reference;

  const VerifiedAllergyCrossReactivity({
    this.matchType = 'cross_reactivity',
    required this.allergenGroup,
    required this.crossReactiveAgents,
    required this.riskLevel,
    required this.mechanism,
    required this.action,
    required this.reference,
  });

  factory VerifiedAllergyCrossReactivity.fromJson(Map<String, dynamic> json) {
    final agents = (json['cross_reactive_agents'] as List?) ?? const [];
    return VerifiedAllergyCrossReactivity(
      matchType: (json['match_type'] as String?) ?? 'cross_reactivity',
      allergenGroup: (json['allergen_group'] as String?) ?? '',
      crossReactiveAgents:
          agents.map((e) => e.toString()).toList(growable: false),
      riskLevel: (json['risk_level'] as String?) ?? '',
      mechanism: (json['mechanism'] as String?) ?? '',
      action: (json['action'] as String?) ?? '',
      reference: (json['reference'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'match_type': matchType,
        'allergen_group': allergenGroup,
        'cross_reactive_agents': crossReactiveAgents,
        'risk_level': riskLevel,
        'mechanism': mechanism,
        'action': action,
        'reference': reference,
      };
}

class VerifiedDrugInteraction {
  final String interactingDrug;
  final List<String> interactingDrugAliases;
  final String interactingRxnormId;
  final String severity;
  final String databaseSource;
  final String mechanism;
  final String clinicalEffect;
  final String management;
  final String reference;

  const VerifiedDrugInteraction({
    required this.interactingDrug,
    this.interactingDrugAliases = const [],
    required this.interactingRxnormId,
    required this.severity,
    this.databaseSource = 'Lexicomp Drug Interactions',
    required this.mechanism,
    required this.clinicalEffect,
    required this.management,
    required this.reference,
  });

  factory VerifiedDrugInteraction.fromJson(Map<String, dynamic> json) {
    final rawAliases = (json['interacting_drug_aliases'] as List?) ?? const [];
    return VerifiedDrugInteraction(
      interactingDrug: (json['interacting_drug'] as String?) ?? '',
      interactingDrugAliases:
          rawAliases.map((e) => e.toString()).toList(growable: false),
      interactingRxnormId: (json['interacting_rxnorm_id'] as String?) ?? '',
      severity: (json['severity'] as String?) ?? '',
      databaseSource:
          (json['database_source'] as String?) ?? 'Lexicomp Drug Interactions',
      mechanism: (json['mechanism'] as String?) ?? '',
      clinicalEffect: (json['clinical_effect'] as String?) ?? '',
      management: (json['management'] as String?) ?? '',
      reference: (json['reference'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'interacting_drug': interactingDrug,
        'interacting_drug_aliases': interactingDrugAliases,
        'interacting_rxnorm_id': interactingRxnormId,
        'severity': severity,
        'database_source': databaseSource,
        'mechanism': mechanism,
        'clinical_effect': clinicalEffect,
        'management': management,
        'reference': reference,
      };
}

class VerificationMetadata {
  final String verifiedStatus;
  final bool sourceVerified;
  final String? verifiedBy;
  final String? verifiedDate;
  final String sourceName;
  final String editionAndPage;
  final String referenceUrl;
  final String evidenceImagePath;
  final String verifiedByRole;
  final String lastVerifiedDate;

  const VerificationMetadata({
    required this.verifiedStatus,
    this.sourceVerified = false,
    this.verifiedBy,
    this.verifiedDate,
    required this.sourceName,
    required this.editionAndPage,
    required this.referenceUrl,
    required this.evidenceImagePath,
    required this.verifiedByRole,
    required this.lastVerifiedDate,
  });

  /// Returns `true` ONLY when `sourceVerified == true` AND both `verifiedBy`
  /// and `verifiedDate` are non-empty. Prevents showing a green "Verified"
  /// badge based on a bare boolean without human reviewer attribution.
  bool get isFullyVerified =>
      sourceVerified &&
      verifiedBy != null &&
      verifiedBy!.trim().isNotEmpty &&
      verifiedDate != null &&
      verifiedDate!.trim().isNotEmpty;

  factory VerificationMetadata.fromJson(Map<String, dynamic> json) {
    return VerificationMetadata(
      verifiedStatus: (json['verified_status'] as String?) ?? '',
      sourceVerified: (json['source_verified'] as bool?) ?? false,
      verifiedBy: json['verified_by'] as String?,
      verifiedDate: json['verified_date'] as String?,
      sourceName: (json['source_name'] as String?) ?? '',
      editionAndPage: (json['edition_and_page'] as String?) ?? '',
      referenceUrl: (json['reference_url'] as String?) ?? '',
      evidenceImagePath: (json['evidence_image_path'] as String?) ?? '',
      verifiedByRole: (json['verified_by_role'] as String?) ?? '',
      lastVerifiedDate: (json['last_verified_date'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'verified_status': verifiedStatus,
        'source_verified': sourceVerified,
        'verified_by': verifiedBy,
        'verified_date': verifiedDate,
        'source_name': sourceName,
        'edition_and_page': editionAndPage,
        'reference_url': referenceUrl,
        'evidence_image_path': evidenceImagePath,
        'verified_by_role': verifiedByRole,
        'last_verified_date': lastVerifiedDate,
      };
}
