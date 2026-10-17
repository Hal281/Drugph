import '../models/verified_drug_schema.dart';

/// Result of validating a [VerifiedDrugKnowledgeBase] against Pillar 1 rules.
class SchemaValidationReport {
  final bool isValid;
  final List<String> errors;

  const SchemaValidationReport({
    required this.isValid,
    required this.errors,
  });
}

/// Deterministic structural & metadata validator for Pillar 1: Verified Drug Knowledge Base Schema.
///
/// Scope & Honest Audit Guarantees:
/// 1. Complete `drug_info` with canonical NLM RxNorm RxCUI and positive concentration.
/// 2. Valid `dosing_rules` with contiguous `renal_adjustment` ranges
///    (`crcl >= min && crcl < max`, zero decimal gaps between tiers).
/// 3. Complete `safety_checks` (`allergy_cross_reactivity` & `drug_interactions`)
///    with mechanism, action/management, and textbook reference.
/// 4. Complete `verification_metadata` with `source_name`, `edition_and_page`,
///    syntactically valid `https://` `reference_url` (rejecting broken non-UUID
///    DailyMed `setid` links), `evidence_image_path`, and mandatory human sign-off
///    fields (`verified_by` + `verified_date` in `YYYY-MM-DD`) whenever
///    `source_verified == true` or `verified_status == "VERIFIED"`.
///
/// Note: Static unit tests do not perform live HTTP requests or verify textbook
/// clinical constants on their own; clinical truth requires human pharmacist/faculty
/// sign-off recorded in `verified_by` and `verified_date`.
class SchemaValidator {
  const SchemaValidator._();

  static const Set<String> allowedSeverities = {
    'Minor',
    'Moderate',
    'Major',
    'Contraindicated',
  };

  /// Canonical NLM RxNorm Concept Unique Identifiers (RxCUI) for known ingredients
  /// in the verified knowledge base, preventing fabricated or mismatched RxCUI strings.
  static const Map<String, String> canonicalRxCuiByIngredient = {
    'paracetamol (acetaminophen)': '161',
    'acetaminophen': '161',
    'paracetamol': '161',
    'amoxicillin': '723',
    'ibuprofen': '5640',
    'warfarin': '11289',
    'isoniazid': '6038',
    'methotrexate': '6851',
    'allopurinol': '519',
    'enalapril': '3827',
    'aspirin (high-dose / anti-inflammatory)': '1191',
    'aspirin': '1191',
  };

  static SchemaValidationReport validateKnowledgeBase(
    VerifiedDrugKnowledgeBase kb,
  ) {
    final errors = <String>[];

    if (kb.schemaVersion.trim().isEmpty) {
      errors.add('Missing schema_version at root level.');
    }

    if (kb.drugs.isEmpty) {
      errors.add('Knowledge base must contain at least one drug entry.');
    }

    final seenIds = <String>{};
    for (final entry in kb.drugs) {
      final id = entry.drugInfo.drugId.trim();
      if (id.isEmpty) {
        errors.add('Drug entry has an empty drug_id.');
      } else if (!seenIds.add(id)) {
        errors.add('Duplicate drug_id found: "$id".');
      }
      errors.addAll(validateDrugEntry(entry));
    }

    return SchemaValidationReport(
      isValid: errors.isEmpty,
      errors: List.unmodifiable(errors),
    );
  }

  static List<String> validateDrugEntry(VerifiedDrugEntry entry) {
    final errors = <String>[];
    final prefix = entry.drugInfo.drugId.isNotEmpty
        ? '[${entry.drugInfo.drugId}]'
        : '[unknown_drug]';

    // 1. Validate drug_info
    final info = entry.drugInfo;
    if (info.genericName.trim().isEmpty) {
      errors.add('$prefix drug_info.generic_name must not be empty.');
    }
    final trimmedRxcui = info.rxnormId.trim();
    if (trimmedRxcui.isEmpty || !RegExp(r'^\d+$').hasMatch(trimmedRxcui)) {
      errors.add('$prefix drug_info.rxnorm_id must be a numeric RxCUI string.');
    } else {
      final expectedRxcui =
          canonicalRxCuiByIngredient[info.genericName.trim().toLowerCase()];
      if (expectedRxcui != null && trimmedRxcui != expectedRxcui) {
        errors.add(
          '$prefix drug_info.rxnorm_id "$trimmedRxcui" does not match canonical NLM RxCUI "$expectedRxcui" for "${info.genericName}".',
        );
      }
    }
    if (info.dosageForm.trim().isEmpty) {
      errors.add('$prefix drug_info.dosage_form must not be empty.');
    }
    if (info.strengthLabel.trim().isEmpty) {
      errors.add('$prefix drug_info.strength_label must not be empty.');
    }
    if (info.concentrationMgPerMl <= 0) {
      errors.add(
        '$prefix drug_info.concentration_mg_per_ml must be > 0 (got ${info.concentrationMgPerMl}).',
      );
    }
    if (info.dispensingUnit.trim().isEmpty) {
      errors.add('$prefix drug_info.dispensing_unit must not be empty.');
    }

    // 2. Validate dosing_rules
    final rules = entry.dosingRules;
    if (rules.indication.trim().isEmpty) {
      errors.add('$prefix dosing_rules.indication must not be empty.');
    }
    if (rules.formulaType.trim().isEmpty ||
        !const {'mg_per_kg_per_dose', 'mg_per_kg_per_day'}
            .contains(rules.formulaType.trim())) {
      errors.add(
        '$prefix dosing_rules.formula_type must be "mg_per_kg_per_dose" or "mg_per_kg_per_day".',
      );
    }
    if (rules.maxDosesPerDay <= 0) {
      errors.add('$prefix dosing_rules.max_doses_per_day must be > 0.');
    }
    final range = rules.doseRange;
    if (range.minMgPerKgPerDose <= 0 ||
        range.recommendedMgPerKgPerDose < range.minMgPerKgPerDose ||
        range.maxMgPerKgPerDose < range.recommendedMgPerKgPerDose) {
      errors.add(
        '$prefix dosing_rules.dose_range invalid: require 0 < min <= recommended <= max.',
      );
    }
    if (rules.maxSingleDoseMg <= 0) {
      errors.add('$prefix dosing_rules.max_single_dose_mg must be > 0.');
    }
    if (rules.maxDailyDoseMg < rules.maxSingleDoseMg) {
      errors.add(
        '$prefix dosing_rules.max_daily_dose_mg must be >= max_single_dose_mg.',
      );
    }
    if (!rules.nonBlockingOverdosePolicy) {
      errors.add(
        '$prefix dosing_rules.non_blocking_overdose_policy must be true per Ironclad Rule 5.',
      );
    }

    // Validate renal_adjustment contiguity (No decimal gaps like 9.9 -> 10.0)
    errors.addAll(_validateRenalAdjustmentTiers(prefix, rules.renalAdjustment));

    // 3. Validate safety_checks
    final safety = entry.safetyChecks;
    if (safety.allergyCrossReactivity.isEmpty) {
      errors.add(
        '$prefix safety_checks.allergy_cross_reactivity must contain at least one rule.',
      );
    }
    for (var i = 0; i < safety.allergyCrossReactivity.length; i++) {
      final allergy = safety.allergyCrossReactivity[i];
      if (!const {'synonym', 'same_class', 'cross_reactivity'}
          .contains(allergy.matchType.trim())) {
        errors.add(
          '$prefix allergy_cross_reactivity[$i].match_type "${allergy.matchType}" must be one of {synonym, same_class, cross_reactivity}.',
        );
      }
      if (allergy.allergenGroup.trim().isEmpty) {
        errors.add(
          '$prefix allergy_cross_reactivity[$i].allergen_group is empty.',
        );
      }
      if (allergy.crossReactiveAgents.isEmpty) {
        errors.add(
          '$prefix allergy_cross_reactivity[$i].cross_reactive_agents must not be empty.',
        );
      }
      if (allergy.mechanism.trim().isEmpty) {
        errors.add('$prefix allergy_cross_reactivity[$i].mechanism is empty.');
      }
      if (allergy.action.trim().isEmpty) {
        errors.add('$prefix allergy_cross_reactivity[$i].action is empty.');
      }
      if (allergy.reference.trim().isEmpty) {
        errors.add('$prefix allergy_cross_reactivity[$i].reference is empty.');
      }
    }

    if (safety.drugInteractions.isEmpty) {
      errors.add(
        '$prefix safety_checks.drug_interactions must contain at least one interaction.',
      );
    }
    for (var i = 0; i < safety.drugInteractions.length; i++) {
      final ddi = safety.drugInteractions[i];
      if (ddi.interactingDrug.trim().isEmpty) {
        errors.add('$prefix drug_interactions[$i].interacting_drug is empty.');
      }
      final ddiRxcui = ddi.interactingRxnormId.trim();
      if (ddiRxcui.isNotEmpty) {
        if (!RegExp(r'^\d+$').hasMatch(ddiRxcui)) {
          errors.add(
            '$prefix drug_interactions[$i].interacting_rxnorm_id must be numeric.',
          );
        } else {
          final expectedDdiRxcui = canonicalRxCuiByIngredient[
              ddi.interactingDrug.trim().toLowerCase()];
          if (expectedDdiRxcui != null && ddiRxcui != expectedDdiRxcui) {
            errors.add(
              '$prefix drug_interactions[$i].interacting_rxnorm_id "$ddiRxcui" does not match canonical NLM RxCUI "$expectedDdiRxcui" for "${ddi.interactingDrug}".',
            );
          }
        }
      }
      if (!allowedSeverities.contains(ddi.severity)) {
        errors.add(
          '$prefix drug_interactions[$i].severity "${ddi.severity}" must be one of $allowedSeverities.',
        );
      }
      if (ddi.databaseSource.trim().isEmpty) {
        errors.add(
          '$prefix drug_interactions[$i].database_source must not be empty.',
        );
      }
      if (ddi.mechanism.trim().isEmpty) {
        errors.add('$prefix drug_interactions[$i].mechanism is empty.');
      }
      if (ddi.clinicalEffect.trim().isEmpty) {
        errors.add('$prefix drug_interactions[$i].clinical_effect is empty.');
      }
      if (ddi.management.trim().isEmpty) {
        errors.add('$prefix drug_interactions[$i].management is empty.');
      }
      if (ddi.reference.trim().isEmpty) {
        errors.add('$prefix drug_interactions[$i].reference is empty.');
      }
    }

    // 4. Validate verification_metadata & human sign-off traceability
    final meta = entry.verificationMetadata;
    if (meta.sourceName.trim().isEmpty) {
      errors.add('$prefix verification_metadata.source_name is empty.');
    }
    if (meta.editionAndPage.trim().isEmpty) {
      errors.add('$prefix verification_metadata.edition_and_page is empty.');
    }
    errors.addAll(_validateReferenceUrl(prefix, meta.referenceUrl));
    if (!meta.evidenceImagePath.startsWith('assets/evidence/') ||
        !meta.evidenceImagePath.toLowerCase().endsWith('.png')) {
      errors.add(
        '$prefix verification_metadata.evidence_image_path must start with "assets/evidence/" and end with ".png".',
      );
    }

    // Enforce human sign-off requirement: cannot claim source_verified=true or VERIFIED without verified_by & verified_date
    final claimsVerified = meta.sourceVerified ||
        meta.verifiedStatus.trim().toUpperCase() == 'VERIFIED';
    if (claimsVerified) {
      final hasVerifier =
          meta.verifiedBy != null && meta.verifiedBy!.trim().isNotEmpty;
      final hasIsoDate = meta.verifiedDate != null &&
          RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(meta.verifiedDate!.trim());
      if (!hasVerifier || !hasIsoDate) {
        errors.add(
          '$prefix verification_metadata claims verified status (source_verified=${meta.sourceVerified}, verified_status="${meta.verifiedStatus}") '
          'without complete human sign-off (require non-empty verified_by and ISO YYYY-MM-DD verified_date).',
        );
      }
    }

    return errors;
  }

  static List<String> _validateRenalAdjustmentTiers(
    String prefix,
    List<VerifiedRenalAdjustmentTier> tiers,
  ) {
    final errors = <String>[];
    if (tiers.isEmpty) {
      errors.add('$prefix dosing_rules.renal_adjustment must not be empty.');
      return errors;
    }

    final sorted = List<VerifiedRenalAdjustmentTier>.from(tiers)
      ..sort((a, b) => a.crclMinMlMin.compareTo(b.crclMinMlMin));

    if (sorted.first.crclMinMlMin != 0.0) {
      errors.add(
        '$prefix renal_adjustment lowest tier must start at 0.0 mL/min (got ${sorted.first.crclMinMlMin}).',
      );
    }

    for (var i = 0; i < sorted.length; i++) {
      final tier = sorted[i];
      if (tier.crclMinMlMin >= tier.crclMaxMlMin) {
        errors.add(
          '$prefix renal_adjustment[$i] invalid bounds: min (${tier.crclMinMlMin}) must be < max (${tier.crclMaxMlMin}).',
        );
      }
      if (tier.adjustedInterval.trim().isEmpty) {
        errors.add('$prefix renal_adjustment[$i].adjusted_interval is empty.');
      }
      if (tier.doseAdjustmentFactor < 0.0 || tier.doseAdjustmentFactor > 1.0) {
        errors.add(
          '$prefix renal_adjustment[$i].dose_adjustment_factor must be between 0.0 and 1.0.',
        );
      }
      if (tier.clinicalNote.trim().isEmpty) {
        errors.add('$prefix renal_adjustment[$i].clinical_note is empty.');
      }

      if (i > 0) {
        final prev = sorted[i - 1];
        if (tier.crclMinMlMin != prev.crclMaxMlMin) {
          errors.add(
            '$prefix renal_adjustment decimal gap or overlap detected between [${prev.crclMinMlMin} - ${prev.crclMaxMlMin}] and [${tier.crclMinMlMin} - ${tier.crclMaxMlMin}]. Next tier min must equal previous tier max for (crcl >= min && crcl < max) evaluation.',
          );
        }
      }
    }

    if (sorted.last.crclMaxMlMin < 999.0) {
      errors.add(
        '$prefix renal_adjustment highest tier must extend to at least 999.0 mL/min (got ${sorted.last.crclMaxMlMin}).',
      );
    }

    return errors;
  }

  static List<String> _validateReferenceUrl(String prefix, String url) {
    final errors = <String>[];
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      errors.add('$prefix verification_metadata.reference_url is empty.');
      return errors;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        !uri.hasScheme ||
        uri.scheme != 'https' ||
        uri.host.isEmpty) {
      errors.add(
        '$prefix verification_metadata.reference_url must be a valid https:// URL.',
      );
      return errors;
    }

    // Syntax check against invalid non-UUID DailyMed setid links (e.g. setid=161) which return 404.
    // Valid DailyMed setids are 36-char UUIDs, or search URLs using search.cfm?labeltype=all&query=...
    final setIdParam = uri.queryParameters['setid'];
    if (setIdParam != null) {
      final uuidRegex = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      );
      if (!uuidRegex.hasMatch(setIdParam)) {
        errors.add(
          '$prefix verification_metadata.reference_url contains invalid non-UUID DailyMed setid="$setIdParam" (causes 404). Use search.cfm?labeltype=all&query=<drug_name> instead.',
        );
      }
    }

    return errors;
  }
}
