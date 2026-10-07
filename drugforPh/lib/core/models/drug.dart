// ============================================================
// Drug Dosage Calculator — Drug & Dosing Regimen Models
// ============================================================
// Core domain models for drug definitions, dosing regimens,
// and renal dose adjustment rules.
//
// DISCLAIMER: SaMD prototype — not for clinical use.
// ============================================================

import 'unit.dart';
import 'dose_limit.dart';
import 'frequency.dart';
import 'dose_basis.dart';
import 'rate_unit.dart';
import 'dosing_phase.dart';
import 'population_criteria.dart';
import 'renal_adjustment.dart';
import 'drug_class.dart';
import 'interaction.dart';
import 'formulation.dart';
import 'provenance.dart';
import 'dose_rule.dart';
import 'drug_ontology.dart';

export 'renal_adjustment.dart';
export 'frequency.dart';
export 'dose_basis.dart';
export 'rate_unit.dart';
export 'dosing_phase.dart';
export 'population_criteria.dart';
export 'drug_class.dart';
export 'interaction.dart';
export 'dose_rule.dart';
export 'formulation.dart';
export 'provenance.dart';

/// Unit of medication concentration (E6).
enum ConcentrationUnit {
  mgPerMl('mg/mL'),
  mcgPerMl('mcg/mL'),
  unitsPerMl('Units/mL'),
  mUPerMl('mU/mL'),
  gPerMl('g/mL');

  final String symbol;
  const ConcentrationUnit(this.symbol);
}

/// Structured medication concentration (E6).
class Concentration {
  final double value;
  final ConcentrationUnit unit;

  const Concentration(this.value, this.unit);

  /// Converts concentration to numeric base value per mL
  /// (mg/mL for mass units, Units/mL for biological units).
  double toBaseUnitPerMl() {
    switch (unit) {
      case ConcentrationUnit.mgPerMl:
        return value;
      case ConcentrationUnit.mcgPerMl:
        return value / 1000.0;
      case ConcentrationUnit.gPerMl:
        return value * 1000.0;
      case ConcentrationUnit.unitsPerMl:
        return value;
      case ConcentrationUnit.mUPerMl:
        return value / 1000.0; // 1000 mU = 1 Unit
    }
  }

  /// Converts concentration to numeric value (mg/mL equivalent where applicable).
  /// Deprecated in favor of [toBaseUnitPerMl].
  double toMgPerMl() => toBaseUnitPerMl();

  @override
  String toString() => '$value ${unit.symbol}';
}

/// Strategy for selecting body weight for weight-based drug calculations.
enum DosingWeightStrategy {
  /// Actual/Total Body Weight (TBW). Used for Vancomycin, Heparin, etc.
  actual('Actual Body Weight (TBW)', 'น้ำหนักจริง (TBW)'),

  /// Ideal Body Weight (IBW). Used for Theophylline, etc.
  ideal('Ideal Body Weight (IBW)', 'น้ำหนักในอุดมคติ (IBW)'),

  /// IBW for non-obese, Adjusted Body Weight (AdjBW) for obese (>= 120% IBW).
  /// Mandatory for Aminoglycosides (Gentamicin, Amikacin) to prevent nephro/ototoxicity.
  adjustedIfObese('IBW or AdjBW if Obese', 'IBW หรือ AdjBW หากผู้ป่วยอ้วน');

  const DosingWeightStrategy(this.nameEn, this.nameTh);
  final String nameEn;
  final String nameTh;
}

/// A single dosing regimen for a drug.
///
/// A drug may have multiple regimens for different routes, indications,
/// or patient populations.
class DosingRegimen {
  /// Route of administration.
  final DoseRoute route;

  /// Clinical indication (e.g. 'Sepsis', 'UTI', 'Prophylaxis').
  final String? indication;

  /// How the dose is calculated.
  final DosingType dosingType;

  // ---- Dose values (use the field matching [dosingType]) ----

  /// Dose per kg body weight — for [DosingType.weightBased].
  final double? dosePerKg;

  /// Dose per m² BSA — for [DosingType.bsaBased].
  final double? dosePerM2;

  /// Target AUC for Calvert formula — for [DosingType.gfrBased].
  final double? targetAuc;

  /// Fixed dose value — for [DosingType.fixed].
  final double? fixedDose;

  /// Minimum dose per kg (range dosing).
  final double? minDosePerKg;

  /// Maximum dose per kg (range dosing).
  final double? maxDosePerKg;

  /// Continuous infusion rate — lower bound (e.g. mcg/kg/min).
  final double? continuousRateMin;

  /// Continuous infusion rate — upper bound.
  final double? continuousRateMax;

  /// Unit string for continuous infusion rate.
  final String? continuousRateUnit;

  /// Unit in which the dose is expressed.
  final DoseUnit doseUnit;

  /// Dosing frequency value type (D1).
  final Frequency frequency;

  /// Explicit dose basis (perDose, perDay, perWeek) (D1).
  final DoseBasis doseBasis;

  /// Structured unit for continuous infusion rates (D2).
  final RateUnit? rateUnit;

  /// Multi-phase dosing sequence (loading, maintenance, taper) (D3).
  final List<DosingPhase>? phases;

  /// Population applicability constraints (age, weight, sex, pregnancy) (D4).
  final PopulationCriteria? population;

  /// Pharmaceutical formulation for this regimen (D10).
  final DrugFormulation? formulation;

  /// Clinical provenance / citation (D11).
  final Provenance? provenance;

  // ---- Dose safety limits ----

  /// Hard and soft limits for this regimen.
  final DoseLimit? limits;

  // ---- IV preparation info ----

  /// Concentration after reconstitution in mg/mL.
  final double? reconcentrationMgPerMl;

  /// Standard dilution concentration for infusion in mg/mL.
  final double? standardDilutionMgPerMl;

  /// Structured standard dilution concentration (E6).
  final Concentration? standardDilution;

  /// Clinical verification status for this regimen (E5).
  final VerificationStatus verificationStatus;

  /// Recommended infusion time in minutes.
  final double? infusionTimeMinutes;

  /// Maximum infusion rate in mg/min.
  final double? maxInfusionRateMgPerMin;

  // ---- Renal adjustments ----

  /// Renal dose adjustment tiers sorted by CrCl range.
  final List<RenalAdjustment>? renalAdjustments;

  /// Clinician notes (English).
  final String? notes;

  /// Clinician notes (Thai).
  final String? notesTh;

  /// Strategy for selecting body weight (TBW, IBW, AdjBW).
  final DosingWeightStrategy dosingWeightStrategy;

  /// Explicit audience. When `null` it is inferred by [effectiveAudience].
  final RegimenAudience? audience;

  /// Upper cap (kg) on the weight used for mg/kg dosing, where the primary
  /// source defines one (e.g. IV acetylcysteine uses at most 100 kg).
  final double? maxDosingWeightKg;

  /// Minimum acceptable ordered single dose (F2 range verification).
  final double? doseRangeMin;

  /// Maximum acceptable ordered single dose (F2 range verification).
  final double? doseRangeMax;

  /// Clinical dose cap explicitly defined by guidelines (F3, separate from limits).
  final double? doseCap;

  /// Source citation for the explicit dose cap (F3).
  final String? doseCapCitation;

  const DosingRegimen({
    required this.route,
    this.indication,
    required this.dosingType,
    this.dosePerKg,
    this.dosePerM2,
    this.targetAuc,
    this.fixedDose,
    this.minDosePerKg,
    this.maxDosePerKg,
    this.continuousRateMin,
    this.continuousRateMax,
    this.continuousRateUnit,
    required this.doseUnit,
    required this.frequency,
    this.doseBasis = DoseBasis.perDose,
    this.rateUnit,
    this.phases,
    this.population,
    this.formulation,
    this.provenance,
    this.limits,
    this.reconcentrationMgPerMl,
    this.standardDilution,
    this.standardDilutionMgPerMl,
    this.infusionTimeMinutes,
    this.maxInfusionRateMgPerMin,
    this.renalAdjustments,
    this.notes,
    this.notesTh,
    this.dosingWeightStrategy = DosingWeightStrategy.actual,
    this.audience,
    this.maxDosingWeightKg,
    this.doseRangeMin,
    this.doseRangeMax,
    this.doseCap,
    this.doseCapCitation,
    this.verificationStatus = VerificationStatus.unverified,
  });

  /// Effective standard dilution concentration in base unit per mL equivalent.
  double? get effectiveStandardDilutionMgPerMl =>
      standardDilution?.toBaseUnitPerMl() ?? standardDilutionMgPerMl;

  /// Who this regimen is written for.
  ///
  /// Resolution order: explicit [audience]; then [population] age bounds
  /// (18 years = 216 months); then the word "pediatric" in [indication];
  /// otherwise adult. A data-lint test pins this so a pediatric regimen can
  /// never silently be treated as an adult one.
  RegimenAudience get effectiveAudience {
    if (audience != null) return audience!;
    final pop = population;
    if (pop != null) {
      if (pop.minAgeMonths != null && pop.minAgeMonths! >= 216) {
        return RegimenAudience.adult;
      }
      if (pop.maxAgeMonths != null && pop.maxAgeMonths! < 216) {
        return RegimenAudience.pediatric;
      }
    }
    if ((indication ?? '').toLowerCase().contains('pediatric')) {
      return RegimenAudience.pediatric;
    }
    return RegimenAudience.adult;
  }

  @override
  String toString() =>
      'DosingRegimen(${route.abbreviation}, ${dosingType.nameEn}, ${frequency.displayEn})';
}

/// Intended patient population of a [DosingRegimen].
enum RegimenAudience { adult, pediatric }

/// Policy for handling renal data evaluation and missing SCr (F4).
enum RenalDataPolicy {
  /// Strictly blocks calculation when renal function is unknown.
  block,

  /// Warns with non-blocking advisory for emergent/STAT first dose.
  warn,

  /// Renal adjustment is not clinically required.
  notNeeded,
}

/// Complete drug definition with all dosing information.
class Drug {
  /// Unique identifier (lowercase, underscore-separated).
  final String id;

  /// Generic (INN) name.
  final String genericName;

  /// Common brand names.
  final List<String> brandNames;

  /// Thai name.
  final String? nameTh;

  /// Therapeutic category.
  final DrugCategory category;

  /// Secondary category tags (D11).
  final List<String> tags;

  /// All available dosing regimens.
  final List<DosingRegimen> regimens;

  /// Pharmacological drug class for interaction and allergy matching (D9).
  final DrugClass? drugClass;

  /// Structured drug-drug interactions (D9).
  final List<DrugInteraction> interactions;

  /// Status of renal dose review (D6, D12, F1).
  final RenalReviewStatus renalReviewStatus;

  /// Clinical rationale if drug does not require renal adjustment (D6).
  final String? renalExemptionReason;

  /// Primary pharmaceutical formulation (D10).
  final DrugFormulation? formulation;

  /// Known contraindications (English).
  final List<String> contraindications;

  /// Available vial sizes or tablet strengths (e.g., [250, 500, 1000]).
  final List<double>? availableStrengths;

  /// Whether renal dose adjustment is required.
  final bool requiresRenalAdjustment;

  /// Policy for handling missing SCr on this drug (F4).
  final RenalDataPolicy renalDataPolicy;

  /// Whether initial/STAT first dose may be administered unadjusted (F4).
  final bool firstDoseUnadjustedOk;

  /// Clinical citation for first dose unadjusted policy (F4).
  final String? firstDoseCitation;

  /// Whether hepatic dose adjustment/caution is required.
  final bool requiresHepationCaution;

  /// Alias for hepatic caution requirement.
  bool get requiresHepaticCaution => requiresHepationCaution;

  /// Whether TDM (Therapeutic Drug Monitoring) is required.
  final bool requiresTDM;

  /// Is this a high-alert medication?
  final bool isHighAlert;

  /// Drug class for allergy cross-reactivity checking (e.g. 'penicillin').
  final String? allergyClass;

  /// Pregnancy safety category (e.g. 'A', 'B', 'C', 'D', 'X').
  final String? pregnancyCategory;

  /// List of generic names of drugs that cause severe interactions.
  final List<String> severeInteractions;

  /// Clinical notes (English).
  final String? specialNotes;

  /// Clinical notes (Thai).
  final String? specialNotesTh;

  /// Primary source citation for drug dosing rules (F1 safe default is empty).
  final String sourceCitation;

  /// ISO 8601 date when this drug's rules were last reviewed (F1 safe default is empty).
  final String lastReviewedDate;

  /// Whether oral tablets of this drug may be split (F1).
  final bool tabletSplittable;

  /// Whether partial doses from vials are allowed (F1).
  final bool vialPartialAllowed;

  /// Declarative clinical dosing rules attached to this drug (F6).
  final List<DoseRule> doseRules;

  /// Combined helper for splittable/partial dosage forms.
  bool get isSplittable => tabletSplittable || vialPartialAllowed;

  const Drug({
    required this.id,
    required this.genericName,
    this.brandNames = const [],
    this.nameTh,
    required this.category,
    this.tags = const [],
    required this.regimens,
    this.drugClass,
    this.interactions = const [],
    this.doseRules = const [],
    this.renalReviewStatus = RenalReviewStatus.unreviewed,
    this.renalExemptionReason,
    this.formulation,
    this.contraindications = const [],
    this.availableStrengths,
    this.requiresRenalAdjustment = false,
    this.renalDataPolicy = RenalDataPolicy.warn,
    this.firstDoseUnadjustedOk = false,
    this.firstDoseCitation,
    bool requiresHepaticCaution = false,
    this.requiresTDM = false,
    this.isHighAlert = false,
    this.allergyClass,
    this.pregnancyCategory,
    this.severeInteractions = const [],
    this.specialNotes,
    this.specialNotesTh,
    this.sourceCitation = '',
    this.lastReviewedDate = '',
    this.tabletSplittable = false,
    this.vialPartialAllowed = false,
    bool? isSplittable,
  })  : requiresHepationCaution = requiresHepaticCaution;

  /// Finds the regimen matching [route] and optional [indication].
  ///
  /// Matching policy (A1, A9, F13):
  /// - Route matching is completely symmetric:
  ///   - Exact match (`r.route == route`)
  ///   - If requested [route] is `iv`, matches `ivPush` or `ivInfusion`.
  ///   - If regimen route `r.route` is `iv`, matches requested `ivPush` or `ivInfusion`.
  /// - Indication matching: if [indication] is provided, returns the matching regimen
  ///   or `null` if not found (no silent fallback).
  /// - If [indication] is omitted (`null`), returns the regimen only if exactly one exists
  ///   for that route; if multiple indications exist, returns `null` to force clinical selection.
  DosingRegimen? findRegimen(DoseRoute route, [String? indication]) {
    bool isRouteMatch(DosingRegimen r) {
      if (r.route == route) return true;
      if (route == DoseRoute.iv &&
          (r.route == DoseRoute.ivInfusion || r.route == DoseRoute.ivPush)) {
        return true;
      }
      if (r.route == DoseRoute.iv &&
          (route == DoseRoute.ivInfusion || route == DoseRoute.ivPush)) {
        return true;
      }
      return false;
    }

    final routeRegimens = regimens.where(isRouteMatch).toList();
    if (routeRegimens.isEmpty) return null;

    if (indication != null && indication.trim().isNotEmpty) {
      for (final r in routeRegimens) {
        if (r.indication?.toLowerCase().trim() ==
            indication.toLowerCase().trim()) {
          return r;
        }
      }
      return null;
    }

    // If multiple indications exist for this route and none was chosen, force selection
    if (routeRegimens.length == 1) {
      return routeRegimens.first;
    }
    return null;
  }

  /// All distinct routes available for this drug.
  List<DoseRoute> get availableRoutes =>
      regimens.map((r) => r.route).toSet().toList();

  /// All distinct indications available for this drug.
  List<String> get availableIndications => regimens
      .where((r) => r.indication != null)
      .map((r) => r.indication!)
      .toSet()
      .toList();

  /// Effective pharmacological drug class, falling back to DrugOntology if not explicitly specified.
  DrugClass? get effectiveDrugClass =>
      drugClass ?? DrugOntology.resolveDrugClass(id, genericName, allergyClass);

  @override
  String toString() => 'Drug($genericName [${category.nameEn}])';
}
