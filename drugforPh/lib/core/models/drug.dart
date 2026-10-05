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

export 'renal_adjustment.dart';
export 'frequency.dart';
export 'dose_basis.dart';
export 'rate_unit.dart';
export 'dosing_phase.dart';
export 'population_criteria.dart';
export 'drug_class.dart';
export 'interaction.dart';
export 'formulation.dart';
export 'provenance.dart';

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
    this.standardDilutionMgPerMl,
    this.infusionTimeMinutes,
    this.maxInfusionRateMgPerMin,
    this.renalAdjustments,
    this.notes,
    this.notesTh,
    this.dosingWeightStrategy = DosingWeightStrategy.actual,
  });

  @override
  String toString() =>
      'DosingRegimen(${route.abbreviation}, ${dosingType.nameEn}, ${frequency.displayEn})';
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

  /// Status of renal dose review (D6, D12).
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

  /// Whether hepatic dose adjustment/caution is required.
  final bool requiresHepaticCaution;

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

  /// Primary source citation for drug dosing rules (e.g. Lexicomp 2024, Sanford Guide).
  final String sourceCitation;

  /// ISO 8601 date when this drug's rules were last reviewed.
  final String lastReviewedDate;

  /// Whether oral tablets of this drug may be split (e.g., scored tablets).
  final bool isSplittable;

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
    this.renalReviewStatus = RenalReviewStatus.reviewedWithTiers,
    this.renalExemptionReason,
    this.formulation,
    this.contraindications = const [],
    this.availableStrengths,
    this.requiresRenalAdjustment = false,
    this.requiresHepaticCaution = false,
    this.requiresTDM = false,
    this.isHighAlert = false,
    this.allergyClass,
    this.pregnancyCategory,
    this.severeInteractions = const [],
    this.specialNotes,
    this.specialNotesTh,
    this.sourceCitation = 'Lexicomp / Sanford Guide / UpToDate',
    this.lastReviewedDate = '2026-10-04',
    this.isSplittable = true,
  });

  /// Finds the regimen matching [route] and optional [indication].
  ///
  /// Matching policy (A1, A9):
  /// - Route matching: exact match (`r.route == route`), or if [route] is `DoseRoute.iv`,
  ///   matches `ivPush` or `ivInfusion`.
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

  @override
  String toString() => 'Drug($genericName [${category.nameEn}])';
}
