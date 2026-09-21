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

/// Renal dose adjustment rule for a specific CrCl range.
///
/// Example: Vancomycin CrCl 30–49 → same dose but change to q24h.
class RenalAdjustment {
  /// Minimum CrCl for this tier (inclusive), in mL/min.
  final double crclMin;

  /// Maximum CrCl for this tier (inclusive), in mL/min.
  final double crclMax;

  /// Dose multiplication factor (1.0 = unchanged, 0.5 = halve dose).
  final double adjustmentFactor;

  /// Replacement frequency if changed (e.g. 'q24h' instead of 'q12h').
  final String? adjustedFrequency;

  /// Clinician-facing note for this tier.
  final String? notes;

  const RenalAdjustment({
    required this.crclMin,
    required this.crclMax,
    required this.adjustmentFactor,
    this.adjustedFrequency,
    this.notes,
  });

  /// Returns `true` if [crcl] falls within [crclMin]..[crclMax].
  bool appliesTo(double crcl) => crcl >= crclMin && crcl <= crclMax;

  @override
  String toString() =>
      'RenalAdj(CrCl $crclMin–$crclMax → ×$adjustmentFactor'
      '${adjustedFrequency != null ? ", freq=$adjustedFrequency" : ""})';
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

  /// Dosing frequency (e.g. 'q6h', 'q8h', 'q12h', 'q24h', 'once').
  final String frequency;

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
    this.limits,
    this.reconcentrationMgPerMl,
    this.standardDilutionMgPerMl,
    this.infusionTimeMinutes,
    this.maxInfusionRateMgPerMin,
    this.renalAdjustments,
    this.notes,
    this.notesTh,
  });

  @override
  String toString() =>
      'DosingRegimen(${route.abbreviation}, ${dosingType.nameEn}, $frequency)';
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

  /// All available dosing regimens.
  final List<DosingRegimen> regimens;

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

  const Drug({
    required this.id,
    required this.genericName,
    this.brandNames = const [],
    this.nameTh,
    required this.category,
    required this.regimens,
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
  });

  /// Finds the first regimen matching [route] and optional [indication].
  ///
  /// If no exact indication match, falls back to first regimen for that route.
  DosingRegimen? findRegimen(DoseRoute route, [String? indication]) {
    // Try exact match first
    for (final r in regimens) {
      if (r.route == route &&
          (indication == null || r.indication == indication)) {
        return r;
      }
    }
    // Fallback: match route only
    if (indication != null) {
      for (final r in regimens) {
        if (r.route == route) return r;
      }
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
