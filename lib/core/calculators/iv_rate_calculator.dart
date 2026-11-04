// ============================================================
// Drug Dosage Calculator — IV Rate Calculator
// ============================================================
// Deterministic intravenous infusion rate calculations.
//
// Covers:
//   • Infusion rate (mL/hr) from volume and time
//   • Drip rate (drops/min) for gravity infusion sets
//   • Volume from dose and concentration
//   • Dose rate (mg/hr, mcg/min, mcg/kg/min)
//
// DISCLAIMER: SaMD prototype — not for clinical use.
// ============================================================

import '../models/drug.dart';

/// IV infusion rate calculations — all pure deterministic functions.
class IvRateCalculator {
  const IvRateCalculator._();

  /// Calculates pump rate in **mL/hr** for a structured dose rate and concentration (F10).
  ///
  /// Strictly checks unit compatibility between [doseRateUnit] and [concentration.unit].
  /// Throws [ArgumentError] if units are incompatible (e.g. mass rate vs biological units).
  static double calculateInfusionMlPerHour({
    required double doseRatePerMin,
    required RateUnit doseRateUnit,
    required Concentration concentration,
    double? weightKg,
  }) {
    if (!doseRatePerMin.isFinite || doseRatePerMin < 0) {
      throw ArgumentError.value(doseRatePerMin, 'doseRatePerMin', 'Must be >= 0');
    }
    if (!concentration.value.isFinite || concentration.value <= 0) {
      throw ArgumentError.value(concentration.value, 'concentration', 'Must be > 0');
    }

    final isWeightBased = doseRateUnit == RateUnit.mcgKgMin ||
        doseRateUnit == RateUnit.mcgKgHr ||
        doseRateUnit == RateUnit.mgKgHr ||
        doseRateUnit == RateUnit.mgKgMin ||
        doseRateUnit == RateUnit.uKgHr;

    if (isWeightBased && (weightKg == null || !weightKg.isFinite || weightKg <= 0)) {
      throw ArgumentError(
        'Weight in kg must be > 0 for weight-based infusion rate unit (${doseRateUnit.symbol})',
      );
    }

    // Check unit compatibility
    final isBiologicalRate = doseRateUnit == RateUnit.mUMin ||
        doseRateUnit == RateUnit.uHr ||
        doseRateUnit == RateUnit.uKgHr;
    final isBiologicalConc = concentration.unit == ConcentrationUnit.unitsPerMl ||
        concentration.unit == ConcentrationUnit.mUPerMl;

    if (isBiologicalRate != isBiologicalConc) {
      throw ArgumentError(
        'Incompatible dose rate unit (${doseRateUnit.symbol}) and concentration unit (${concentration.unit.symbol})',
      );
    }

    // Special case for mU/min with mU/mL
    if (doseRateUnit == RateUnit.mUMin && concentration.unit == ConcentrationUnit.mUPerMl) {
      final mUPerHour = doseRatePerMin * 60.0;
      return mUPerHour / concentration.value;
    }

    final amountPerHour = doseRateUnit.toAmountPerHour(doseRatePerMin, weightKg ?? 1.0);
    if (amountPerHour == null) {
      throw ArgumentError('Unable to convert rate ${doseRateUnit.symbol} to amount per hour');
    }

    final baseConcPerMl = concentration.toBaseUnitPerMl();
    if (baseConcPerMl <= 0) {
      throw ArgumentError('Invalid concentration value');
    }

    return amountPerHour / baseConcPerMl;
  }

  // ------------------------------------------------------------------
  // Infusion rate (mL/hr)
  //
  // rate (mL/hr) = volume_mL / time_hours
  // ------------------------------------------------------------------

  /// Calculates IV pump infusion rate in **mL/hr**.
  ///
  /// [volumeMl] total volume to infuse.
  /// [timeMinutes] infusion duration in minutes.
  static double infusionRateMlPerHr({
    required double volumeMl,
    required double timeMinutes,
  }) {
    if (!volumeMl.isFinite || volumeMl < 0) {
      throw ArgumentError.value(volumeMl, 'volumeMl', 'Must be ≥ 0');
    }
    if (!timeMinutes.isFinite || timeMinutes <= 0) {
      throw ArgumentError.value(timeMinutes, 'timeMinutes', 'Must be > 0');
    }

    final timeHours = timeMinutes / 60.0;
    return volumeMl / timeHours;
  }

  // ------------------------------------------------------------------
  // Drip rate (drops/min) — for gravity infusion sets
  //
  // drops/min = (volume_mL × drop_factor) / (time_minutes)
  //
  // Common drop factors:
  //   Standard set  = 20 drops/mL
  //   Micro-drip    = 60 drops/mL
  //   Blood set     = 15 drops/mL
  // ------------------------------------------------------------------

  /// Calculates gravity drip rate in **drops/min**.
  ///
  /// [dropFactor] is drops per mL of the infusion set (default: 20).
  static double dripRateDropsPerMin({
    required double volumeMl,
    required double timeMinutes,
    int dropFactor = 20,
  }) {
    if (!volumeMl.isFinite || volumeMl < 0) {
      throw ArgumentError.value(volumeMl, 'volumeMl', 'Must be ≥ 0');
    }
    if (!timeMinutes.isFinite || timeMinutes <= 0) {
      throw ArgumentError.value(timeMinutes, 'timeMinutes', 'Must be > 0');
    }
    if (dropFactor <= 0) {
      throw ArgumentError.value(dropFactor, 'dropFactor', 'Must be > 0');
    }

    return (volumeMl * dropFactor) / timeMinutes;
  }

  // ------------------------------------------------------------------
  // Volume from dose & concentration
  //
  // volume (mL) = desired_dose (mg) / concentration (mg/mL)
  // ------------------------------------------------------------------

  /// Calculates volume to draw from vial/bag in **mL**.
  ///
  /// [desiredDoseMg] the calculated dose in mg.
  /// [concentrationMgPerMl] drug concentration in mg/mL.
  static double volumeForDose({
    required double desiredDoseMg,
    required double concentrationMgPerMl,
  }) {
    if (!desiredDoseMg.isFinite || desiredDoseMg < 0) {
      throw ArgumentError.value(
        desiredDoseMg, 'desiredDoseMg', 'Must be ≥ 0',
      );
    }
    if (!concentrationMgPerMl.isFinite || concentrationMgPerMl <= 0) {
      throw ArgumentError.value(
        concentrationMgPerMl,
        'concentrationMgPerMl',
        'Must be > 0',
      );
    }

    return desiredDoseMg / concentrationMgPerMl;
  }

  // ------------------------------------------------------------------
  // Dose rate from concentration & pump rate
  //
  // dose_rate (mg/hr) = concentration (mg/mL) × rate (mL/hr)
  // ------------------------------------------------------------------

  /// Calculates dose delivery rate in **mg/hr**.
  static double doseRateMgPerHr({
    required double concentrationMgPerMl,
    required double rateMlPerHr,
  }) {
    if (!concentrationMgPerMl.isFinite || concentrationMgPerMl <= 0) {
      throw ArgumentError.value(
        concentrationMgPerMl,
        'concentrationMgPerMl',
        'Must be > 0',
      );
    }
    if (!rateMlPerHr.isFinite || rateMlPerHr < 0) {
      throw ArgumentError.value(rateMlPerHr, 'rateMlPerHr', 'Must be ≥ 0');
    }

    return concentrationMgPerMl * rateMlPerHr;
  }

  // ------------------------------------------------------------------
  // mcg/kg/min — for vasopressors and critical-care infusions
  //
  // mcg/kg/min = (concentration_mcg_per_mL × rate_mL_per_hr)
  //              / (weight_kg × 60)
  //
  // OR inverse:
  // rate (mL/hr) = (desired_mcg_kg_min × weight_kg × 60)
  //                / concentration_mcg_per_mL
  // ------------------------------------------------------------------

  /// Calculates dose rate in **mcg/kg/min** from pump settings.
  static double mcgPerKgPerMin({
    required double concentrationMcgPerMl,
    required double rateMlPerHr,
    required double weightKg,
  }) {
    if (!concentrationMcgPerMl.isFinite ||
        concentrationMcgPerMl <= 0 ||
        !rateMlPerHr.isFinite ||
        rateMlPerHr < 0 ||
        !weightKg.isFinite ||
        weightKg <= 0) {
      throw ArgumentError('All values must be positive and finite');
    }

    return (concentrationMcgPerMl * rateMlPerHr) / (weightKg * 60.0);
  }

  /// Calculates pump rate in **mL/hr** for a desired mcg/kg/min.
  static double rateMlPerHrFromMcgKgMin({
    required double desiredMcgKgMin,
    required double weightKg,
    required double concentrationMcgPerMl,
  }) {
    if (!desiredMcgKgMin.isFinite ||
        desiredMcgKgMin < 0 ||
        !weightKg.isFinite ||
        weightKg <= 0 ||
        !concentrationMcgPerMl.isFinite ||
        concentrationMcgPerMl <= 0) {
      throw ArgumentError('All values must be positive and finite');
    }

    return (desiredMcgKgMin * weightKg * 60.0) / concentrationMcgPerMl;
  }

  // ------------------------------------------------------------------
  // units/hr — for Insulin and Heparin infusions
  //
  // rate (mL/hr) = desired_units_per_hr / concentration_units_per_mL
  // ------------------------------------------------------------------

  /// Calculates pump rate in **mL/hr** for unit-based drugs
  /// (e.g. Insulin, Heparin).
  static double rateMlPerHrFromUnits({
    required double desiredUnitsPerHr,
    required double concentrationUnitsPerMl,
  }) {
    if (!desiredUnitsPerHr.isFinite ||
        desiredUnitsPerHr < 0 ||
        !concentrationUnitsPerMl.isFinite ||
        concentrationUnitsPerMl <= 0) {
      throw ArgumentError('All values must be positive and finite');
    }

    return desiredUnitsPerHr / concentrationUnitsPerMl;
  }
}
