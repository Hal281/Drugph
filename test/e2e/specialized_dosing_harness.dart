// ============================================================================
// E2E Specialized Dosing & NTI Safety Guard Test Harness (Oracle Harness)
// ============================================================================
// Authoritative standards:
// - ASHP/IDSA/PIDS/SIDP 2020 Vancomycin Consensus Guidelines
// - Nicolau DP et al. (1995): Hartford Once-Daily Aminoglycoside Nomogram
// - Sheiner LB & Tozer TN (1975): Albumin-adjusted Phenytoin equation
// - Winter ME: Basic Clinical Pharmacokinetics (5th ed)
// - Devine BJ (1974): Ideal body weight formula
// - Cockcroft DW & Gault MH (1976): Creatinine clearance prediction
// - Schwartz GJ et al. (1984, 2009): Bedside Schwartz pediatric GFR formula
// ============================================================================

import 'dart:math';

/// Vancomycin AUC24/MIC evaluation result.
class VancomycinAucEvaluation {
  final double auc24;
  final double micMgL;
  final double aucToMicRatio;
  final bool isTherapeutic;
  final bool isSubtherapeutic;
  final bool isSupratherapeuticNephrotoxic;
  final String clinicalGuidance;

  const VancomycinAucEvaluation({
    required this.auc24,
    required this.micMgL,
    required this.aucToMicRatio,
    required this.isTherapeutic,
    required this.isSubtherapeutic,
    required this.isSupratherapeuticNephrotoxic,
    required this.clinicalGuidance,
  });
}

/// Phenytoin Michaelis-Menten kinetic result.
class PhenytoinKineticResult {
  final double orderedDailyDoseMg;
  final double? predictedCssMgL;
  final double? observedCssMgL;
  final double? adjustedCssMgL;
  final double vmaxMgPerDay;
  final double kmMgL;
  final bool isCapacityExceeded;
  final bool isSheinerTozerApplied;
  final bool isWinterTozerApplied;
  final bool isToxic;
  final List<String> warningCodes;

  const PhenytoinKineticResult({
    required this.orderedDailyDoseMg,
    this.predictedCssMgL,
    this.observedCssMgL,
    this.adjustedCssMgL,
    required this.vmaxMgPerDay,
    required this.kmMgL,
    required this.isCapacityExceeded,
    required this.isSheinerTozerApplied,
    required this.isWinterTozerApplied,
    required this.isToxic,
    required this.warningCodes,
  });
}

/// NTI electrolyte safety check result.
class NtiElectrolyteSafetyResult {
  final String drugId;
  final bool hasPotassiumRisk;
  final bool hasMagnesiumRisk;
  final bool hasCalciumRisk;
  final bool hasSodiumRisk;
  final bool hasDistributionPhaseWarning;
  final List<String> clinicalWarnings;

  const NtiElectrolyteSafetyResult({
    required this.drugId,
    required this.hasPotassiumRisk,
    required this.hasMagnesiumRisk,
    required this.hasCalciumRisk,
    required this.hasSodiumRisk,
    required this.hasDistributionPhaseWarning,
    required this.clinicalWarnings,
  });
}

/// Structured clinical override justification for high-alert titration breaches.
class ClinicalOverrideJustification {
  final String clinicianId;
  final String justificationCategory;
  final String? clinicalNotes;
  final DateTime timestamp;
  final double deliveredDose;
  final String rateUnit;

  const ClinicalOverrideJustification({
    required this.clinicianId,
    required this.justificationCategory,
    this.clinicalNotes,
    required this.timestamp,
    required this.deliveredDose,
    required this.rateUnit,
  });
}

/// High-alert continuous infusion calculation result.
class VasoactiveInfusionResult {
  final String drugId;
  final double orderedDose;
  final String doseUnit;
  final double patientWeightKg;
  final double concentrationMcgPerMl;
  final double pumpRateMlPerHr;
  final bool isCeilingExceeded;
  final double ceilingThreshold;
  final ClinicalOverrideJustification? overrideJustification;
  final String warningMessage;

  const VasoactiveInfusionResult({
    required this.drugId,
    required this.orderedDose,
    required this.doseUnit,
    required this.patientWeightKg,
    required this.concentrationMcgPerMl,
    required this.pumpRateMlPerHr,
    required this.isCeilingExceeded,
    required this.ceilingThreshold,
    this.overrideJustification,
    required this.warningMessage,
  });
}

/// Pure deterministic oracle harness for Requirement R2 Specialized Dosing.
abstract class SpecializedDosingHarness {
  // --------------------------------------------------------------------------
  // 1. Vancomycin AUC24/MIC Evaluation (ASHP 2020)
  // --------------------------------------------------------------------------
  static VancomycinAucEvaluation evaluateVancomycinTarget({
    required double auc24,
    double micMgL = 1.0,
    bool isSeriousInvasiveInfection = true,
  }) {
    if (auc24 <= 0 || micMgL <= 0) {
      throw ArgumentError('AUC24 and MIC must be > 0');
    }
    final ratio = auc24 / micMgL;

    final targetMin = isSeriousInvasiveInfection ? 400.0 : 300.0;
    final targetMax = isSeriousInvasiveInfection ? 600.0 : 450.0;

    final isSub = ratio < targetMin;
    final isToxic = ratio > 600.0;
    final isTherapeutic = ratio >= targetMin && ratio <= targetMax;

    String guidance;
    if (isToxic) {
      guidance =
          'CRITICAL: AUC24/MIC ratio ($ratio) exceeds 600 mg·h/L; elevated Acute Kidney Injury (AKI) risk. Reduce dose or extend interval.';
    } else if (isSub) {
      guidance =
          'SUB-THERAPEUTIC: AUC24/MIC ratio ($ratio) is below target ($targetMin-$targetMax); risk of clinical failure and MRSA resistance.';
    } else {
      guidance = 'OPTIMAL: AUC24/MIC ratio ($ratio) is within target therapeutic window.';
    }

    return VancomycinAucEvaluation(
      auc24: auc24,
      micMgL: micMgL,
      aucToMicRatio: ratio,
      isTherapeutic: isTherapeutic,
      isSubtherapeutic: isSub,
      isSupratherapeuticNephrotoxic: isToxic,
      clinicalGuidance: guidance,
    );
  }

  // --------------------------------------------------------------------------
  // 2. Phenytoin Michaelis-Menten Kinetics & Albumin Correction
  // --------------------------------------------------------------------------
  static PhenytoinKineticResult evaluatePhenytoin({
    required double orderedDailyDoseMg,
    required double weightKg,
    double vmaxMgPerKgDay = 7.0,
    double kmMgL = 4.0,
    double? observedSerumPhenytoinMgL,
    double? serumAlbuminGPerDl,
    double? crclMlMin,
  }) {
    if (orderedDailyDoseMg <= 0 || weightKg <= 0) {
      throw ArgumentError('Dose and Weight must be > 0');
    }

    final totalVmax = vmaxMgPerKgDay * weightKg;
    final warnings = <String>[];

    // Saturation Guard: Dose >= Vmax
    final isCapacityExceeded = orderedDailyDoseMg >= totalVmax;
    double? predictedCss;
    if (isCapacityExceeded) {
      warnings.add('phenytoinCapacityExceeded');
    } else {
      // Steady-state Michaelis-Menten equation: Css = (Km * Dose) / (Vmax - Dose)
      predictedCss = (kmMgL * orderedDailyDoseMg) / (totalVmax - orderedDailyDoseMg);
      if (predictedCss > 20.0) {
        warnings.add('phenytoinTargetExceeded');
      } else if (predictedCss < 10.0) {
        warnings.add('phenytoinSubtherapeutic');
      }
    }

    // Albumin adjustment (Sheiner-Tozer or Winter-Tozer)
    double? adjustedCss;
    bool isSheinerTozer = false;
    bool isWinterTozer = false;

    if (observedSerumPhenytoinMgL != null && serumAlbuminGPerDl != null) {
      final isSevereRenalFailure = crclMlMin != null && crclMlMin < 20.0;
      if (isSevereRenalFailure) {
        // Winter-Tozer equation: Cadj = Cobs / (0.1 * Albumin + 0.1)
        adjustedCss = observedSerumPhenytoinMgL / (0.1 * serumAlbuminGPerDl + 0.1);
        isWinterTozer = true;
        warnings.add('phenytoinRenalImpairment');
      } else {
        // Sheiner-Tozer equation: Cadj = Cobs / (0.2 * Albumin + 0.1)
        adjustedCss = observedSerumPhenytoinMgL / (0.2 * serumAlbuminGPerDl + 0.1);
        isSheinerTozer = true;
        if (serumAlbuminGPerDl < 3.5) {
          warnings.add('phenytoinHypoalbuminemia');
        }
      }
    }

    final effectiveLevel = adjustedCss ?? predictedCss ?? 0.0;
    final isToxic = effectiveLevel > 20.0 || isCapacityExceeded;

    return PhenytoinKineticResult(
      orderedDailyDoseMg: orderedDailyDoseMg,
      predictedCssMgL: predictedCss,
      observedCssMgL: observedSerumPhenytoinMgL,
      adjustedCssMgL: adjustedCss,
      vmaxMgPerDay: totalVmax,
      kmMgL: kmMgL,
      isCapacityExceeded: isCapacityExceeded,
      isSheinerTozerApplied: isSheinerTozer,
      isWinterTozerApplied: isWinterTozer,
      isToxic: isToxic,
      warningCodes: warnings,
    );
  }

  // --------------------------------------------------------------------------
  // 3. NTI Electrolyte & Alpha Distribution Phase Guard
  // --------------------------------------------------------------------------
  static NtiElectrolyteSafetyResult checkNtiSafety({
    required String drugId,
    double? serumPotassiumMEqL,
    double? serumMagnesiumMgDl,
    double? serumCalciumMgDl,
    double? serumSodiumMEqL,
    double? hoursPostDoseSampling,
  }) {
    final warnings = <String>[];
    bool kRisk = false;
    bool mgRisk = false;
    bool caRisk = false;
    bool naRisk = false;
    bool distPhaseRisk = false;

    if (drugId.toLowerCase() == 'digoxin') {
      if (serumPotassiumMEqL != null && serumPotassiumMEqL < 3.5) {
        kRisk = true;
        warnings.add(
            'Hypokalemia (K+ $serumPotassiumMEqL mEq/L < 3.5): Markedly potentiates digitalis cardiotoxicity.');
      }
      if (serumMagnesiumMgDl != null && serumMagnesiumMgDl < 1.7) {
        mgRisk = true;
        warnings.add(
            'Hypomagnesemia (Mg2+ $serumMagnesiumMgDl mg/dL < 1.7): Increases risk of refractory digitalis arrhythmias.');
      }
      if (serumCalciumMgDl != null && serumCalciumMgDl > 10.5) {
        caRisk = true;
        warnings.add(
            'Hypercalcemia (Ca2+ $serumCalciumMgDl mg/dL > 10.5): Synergistic toxicity with digoxin.');
      }
      if (hoursPostDoseSampling != null && hoursPostDoseSampling < 6.0) {
        distPhaseRisk = true;
        warnings.add(
            'Premature blood sampling ($hoursPostDoseSampling hr post-dose < 6.0 hr): Alpha distribution phase incomplete.');
      }
    } else if (drugId.toLowerCase() == 'lithium') {
      if (serumSodiumMEqL != null && serumSodiumMEqL < 135.0) {
        naRisk = true;
        warnings.add(
            'Hyponatremia (Na+ $serumSodiumMEqL mEq/L < 135): Triggers proximal tubular lithium retention and acute toxicity.');
      }
      if (hoursPostDoseSampling != null &&
          (hoursPostDoseSampling < 11.5 || hoursPostDoseSampling > 12.5)) {
        warnings.add(
            'Lithium trough must be drawn exactly 12 hours post-dose (current: $hoursPostDoseSampling hr).');
      }
    }

    return NtiElectrolyteSafetyResult(
      drugId: drugId,
      hasPotassiumRisk: kRisk,
      hasMagnesiumRisk: mgRisk,
      hasCalciumRisk: caRisk,
      hasSodiumRisk: naRisk,
      hasDistributionPhaseWarning: distPhaseRisk,
      clinicalWarnings: warnings,
    );
  }

  // --------------------------------------------------------------------------
  // 4. Special Populations: Weight & Renal Calculation
  // --------------------------------------------------------------------------
  static double calculateDevineIbw({
    required double heightCm,
    required bool isMale,
  }) {
    if (heightCm <= 0) throw ArgumentError('Height must be > 0');
    final heightInches = heightCm / 2.54;
    final base = isMale ? 50.0 : 45.5;
    return base + 2.3 * (heightInches - 60.0);
  }

  static double calculateAdjBw04({
    required double tbwKg,
    required double ibwKg,
  }) {
    return ibwKg + 0.4 * (tbwKg - ibwKg);
  }

  static double selectAminoglycosideDosingWeight({
    required double tbwKg,
    required double heightCm,
    required bool isMale,
  }) {
    final ibw = calculateDevineIbw(heightCm: heightCm, isMale: isMale);
    final bmi = tbwKg / pow(heightCm / 100.0, 2);

    // If underweight, use TBW
    if (tbwKg < ibw) return tbwKg;

    // If obese (BMI >= 30 or TBW >= 1.2 * IBW), MANDATORY AdjBW 0.4
    if (bmi >= 30.0 || tbwKg >= 1.20 * ibw) {
      return calculateAdjBw04(tbwKg: tbwKg, ibwKg: ibw);
    }

    // Normal weight: IBW
    return ibw;
  }

  static Map<String, dynamic> calculateCockcroftGaultWithElderlyFloor({
    required double ageYears,
    required double weightKg,
    required double serumCreatinineMgDl,
    required bool isMale,
  }) {
    if (ageYears <= 0 || weightKg <= 0 || serumCreatinineMgDl <= 0) {
      throw ArgumentError('Age, Weight, and SCr must be > 0');
    }

    final rawCrCl = ((140.0 - ageYears) * weightKg) /
        (72.0 * serumCreatinineMgDl) *
        (isMale ? 1.0 : 0.85);

    bool floorApplied = false;
    double effectiveScr = serumCreatinineMgDl;

    if (ageYears >= 65.0 && serumCreatinineMgDl < 0.8) {
      effectiveScr = 0.8;
      floorApplied = true;
    }

    final effectiveCrCl = ((140.0 - ageYears) * weightKg) /
        (72.0 * effectiveScr) *
        (isMale ? 1.0 : 0.85);

    return {
      'rawCrCl': rawCrCl,
      'effectiveCrCl': effectiveCrCl,
      'floorApplied': floorApplied,
    };
  }

  static double calculateBedsideSchwartz({
    required double heightCm,
    required double serumCreatinineMgDl,
    double kConstant = 0.413,
  }) {
    if (heightCm <= 0 || serumCreatinineMgDl <= 0 || kConstant <= 0) {
      throw ArgumentError('Height, SCr, and kConstant must be > 0');
    }
    return (kConstant * heightCm) / serumCreatinineMgDl;
  }

  // --------------------------------------------------------------------------
  // 5. High-Alert Continuous Infusions (Inotropes / Vasopressors)
  // --------------------------------------------------------------------------
  static VasoactiveInfusionResult calculateVasoactiveInfusion({
    required String drugId,
    required double orderedDose,
    required String doseUnit, // 'mcg/kg/min' or 'mcg/min'
    required double patientWeightKg,
    required double concentrationMcgPerMl,
    ClinicalOverrideJustification? overrideJustification,
  }) {
    if (orderedDose <= 0 || concentrationMcgPerMl <= 0 || patientWeightKg <= 0) {
      throw ArgumentError('Dose, Concentration, and Weight must be > 0');
    }

    double pumpRateMlPerHr;
    double deliveredMcgKgMin;

    if (doseUnit == 'mcg/kg/min') {
      pumpRateMlPerHr = (orderedDose * patientWeightKg * 60.0) / concentrationMcgPerMl;
      deliveredMcgKgMin = orderedDose;
    } else {
      pumpRateMlPerHr = (orderedDose * 60.0) / concentrationMcgPerMl;
      deliveredMcgKgMin = orderedDose / patientWeightKg;
    }

    double ceiling;
    final drugLower = drugId.toLowerCase();
    if (drugLower == 'norepinephrine' || drugLower == 'epinephrine') {
      ceiling = 1.0; // mcg/kg/min
    } else if (drugLower == 'dopamine' || drugLower == 'dobutamine') {
      ceiling = 20.0; // mcg/kg/min
    } else {
      ceiling = 100.0;
    }

    final isCeilingExceeded = deliveredMcgKgMin > ceiling;
    String warning = '';
    if (isCeilingExceeded) {
      warning =
          'CRITICAL OVERDOSE / TITRATION CEILING EXCEEDED: Delivered rate ($deliveredMcgKgMin mcg/kg/min) exceeds standard ceiling ($ceiling mcg/kg/min). Rule 5 non-blocking active.';
    }

    return VasoactiveInfusionResult(
      drugId: drugId,
      orderedDose: orderedDose,
      doseUnit: doseUnit,
      patientWeightKg: patientWeightKg,
      concentrationMcgPerMl: concentrationMcgPerMl,
      pumpRateMlPerHr: pumpRateMlPerHr,
      isCeilingExceeded: isCeilingExceeded,
      ceilingThreshold: ceiling,
      overrideJustification: overrideJustification,
      warningMessage: warning,
    );
  }
}
