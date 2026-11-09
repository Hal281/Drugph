import 'dart:math';

import '../models/specialized_dosing_models.dart';

/// Pure, deterministic calculation engine for Specialized Narrow Therapeutic Index (NTI)
/// dosing, special population adjustments, and high-alert continuous infusions.
///
/// Adheres strictly to:
/// - Rule 1: 100% calculation accuracy, deterministic pure functions.
/// - Rule 2: Evidence-based medicine (ASHP 2020, Hartford Nomogram 1995, Sheiner-Tozer 1975).
/// - Rule 5: Non-blocking overdose policy (preserves computed rates/doses, emits alerts).
abstract class SpecializedDosingCalculator {
  // ==========================================================================
  // 1. VANCOMYCIN AUC24/MIC & KINETIC ENGINE (ASHP 2020)
  // ==========================================================================

  /// Evaluates 24-hour AUC/MIC target attainment for Vancomycin per ASHP 2020 consensus.
  ///
  /// - [severity] `severeInvasive`: target AUC24/MIC 400 - 600 mg·h/L (surrogate trough 15-20 mcg/mL).
  /// - [severity] `mildModerate`: target AUC24/MIC 300 - 450 mg·h/L (surrogate trough 10-15 mcg/mL).
  /// - AUC24/MIC > 600 mg·h/L triggers critical Acute Kidney Injury (AKI) risk alert.
  static VancomycinDosingResult evaluateVancomycinAuc({
    required double auc24,
    double micMgL = 1.0,
    InfectionSeverity severity = InfectionSeverity.severeInvasive,
    double? troughMgL,
    double? recommendedDoseMg,
    double? loadingDoseMg,
    double? loadingDoseRawMg,
    bool loadingDoseCapApplied = false,
    double? infusionDurationMinutes,
    bool hasRedManSyndromeRisk = false,
    double? sawchukZaskeKe,
    double? sawchukZaskeVd,
    double? truePeak,
    double? trueTrough,
    List<String> warnings = const [],
  }) {
    if (auc24 <= 0 || auc24.isNaN || auc24.isInfinite) {
      throw ArgumentError('AUC24 must be a positive finite number, got $auc24');
    }
    if (micMgL <= 0 || micMgL.isNaN || micMgL.isInfinite) {
      throw ArgumentError('MIC must be a positive finite number, got $micMgL');
    }

    final ratio = auc24 / micMgL;
    final isSevere = severity == InfectionSeverity.severeInvasive;
    final targetMin = isSevere ? 400.0 : 300.0;
    final targetMax = isSevere ? 600.0 : 450.0;
    final troughMin = isSevere ? 15.0 : 10.0;
    final troughMax = isSevere ? 20.0 : 15.0;

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
      guidance =
          'OPTIMAL: AUC24/MIC ratio ($ratio) is within target therapeutic window.';
    }

    final activeWarnings = List<String>.from(warnings);
    if (isToxic && !activeWarnings.any((w) => w.contains('AKI'))) {
      activeWarnings.add(guidance);
    } else if (isSub && !activeWarnings.any((w) => w.contains('SUB-THERAPEUTIC'))) {
      activeWarnings.add(guidance);
    }

    if (troughMgL != null) {
      if (troughMgL > 20.0) {
        activeWarnings.add(
            'High trough concentration ($troughMgL mcg/mL > 20.0): Strong predictor of nephrotoxicity.');
      } else if (troughMgL < troughMin) {
        activeWarnings.add(
            'Sub-target trough concentration ($troughMgL mcg/mL < $troughMin mcg/mL).');
      }
    }

    return VancomycinDosingResult(
      auc24: auc24,
      micMgL: micMgL,
      aucToMicRatio: ratio,
      severity: severity,
      isTherapeutic: isTherapeutic,
      isSubtherapeutic: isSub,
      isSupratherapeuticNephrotoxic: isToxic,
      targetMin: targetMin,
      targetMax: targetMax,
      troughTargetMin: troughMin,
      troughTargetMax: troughMax,
      clinicalGuidance: guidance,
      recommendedDoseMg: recommendedDoseMg,
      loadingDoseMg: loadingDoseMg,
      loadingDoseRawMg: loadingDoseRawMg,
      loadingDoseCapApplied: loadingDoseCapApplied,
      infusionDurationMinutes: infusionDurationMinutes,
      hasRedManSyndromeRisk: hasRedManSyndromeRisk,
      sawchukZaskeKe: sawchukZaskeKe,
      sawchukZaskeVd: sawchukZaskeVd,
      truePeak: truePeak,
      trueTrough: trueTrough,
      warnings: activeWarnings,
    );
  }

  /// Calculates individual kinetic parameters via 2-point Sawchuk-Zaske estimation.
  ///
  /// - [c1MgL]: Post-infusion peak drawn >= 1.0 hr post-infusion.
  /// - [c2MgL]: Trough drawn immediately prior to subsequent dose.
  /// - [deltaTHours]: Time elapsed between [c1MgL] and [c2MgL].
  /// - [t1PostInfHours]: Time elapsed from end of infusion to [c1MgL] draw.
  static Map<String, double> calculateVancomycinSawchukZaske({
    required double c1MgL,
    required double c2MgL,
    required double deltaTHours,
    required double t1PostInfHours,
    required double doseMg,
    required double tauHours,
    required double tInfHours,
  }) {
    if (c1MgL <= 0 || c1MgL.isNaN || c1MgL.isInfinite) {
      throw ArgumentError('C1 must be positive and finite');
    }
    if (c2MgL <= 0 || c2MgL.isNaN || c2MgL.isInfinite) {
      throw ArgumentError('C2 must be positive and finite');
    }
    if (c1MgL <= c2MgL) {
      throw ArgumentError('Peak (C1: $c1MgL) must be greater than trough (C2: $c2MgL)');
    }
    if (deltaTHours <= 0 || deltaTHours.isNaN || deltaTHours.isInfinite) {
      throw ArgumentError('deltaT must be positive and finite');
    }
    if (t1PostInfHours < 0 || t1PostInfHours.isNaN || t1PostInfHours.isInfinite) {
      throw ArgumentError('t1PostInf must be non-negative and finite');
    }
    if (doseMg <= 0 || tauHours <= 0 || tInfHours <= 0) {
      throw ArgumentError('Dose, Tau, and tInf must be positive');
    }
    if (tauHours <= tInfHours) {
      throw ArgumentError('Dosing interval (Tau) must exceed infusion duration (tInf)');
    }

    final ke = log(c1MgL / c2MgL) / deltaTHours;
    final truePeak = c1MgL * exp(ke * t1PostInfHours);
    final trueTrough = truePeak * exp(-ke * (tauHours - tInfHours));

    final denom = tInfHours * ke * (truePeak - trueTrough * exp(-ke * tInfHours));
    final vd = (doseMg * (1.0 - exp(-ke * tInfHours))) / denom;
    final cl = vd * ke;
    final auc24 = (doseMg * (24.0 / tauHours)) / cl;

    return {
      'ke': ke,
      'truePeak': truePeak,
      'trueTrough': trueTrough,
      'vd': vd,
      'clearance': cl,
      'auc24': auc24,
    };
  }

  /// Calculates recommended maintenance dose to achieve target 24-hour AUC.
  ///
  /// Dose = (Target AUC * Vd * Ke) / (24 / Tau)
  static double recommendVancomycinDoseForTargetAuc({
    required double targetAuc,
    required double vd,
    required double ke,
    required double tauHours,
  }) {
    if (targetAuc <= 0 || vd <= 0 || ke <= 0 || tauHours <= 0) {
      throw ArgumentError('All parameters must be positive and finite');
    }
    final dailyClearanceDose = targetAuc * (vd * ke);
    final frequencyPerDay = 24.0 / tauHours;
    return dailyClearanceDose / frequencyPerDay;
  }

  /// Calculates empiric Vancomycin loading dose (25-30 mg/kg of TBW), applying Rule 5.
  ///
  /// Cap is 3,000 mg for severe/critically ill, 2,000 mg for mild/moderate.
  static Map<String, dynamic> calculateVancomycinLoadingDose({
    required double weightKg,
    bool isSevereOrCriticallyIll = true,
  }) {
    if (weightKg <= 0 || weightKg.isNaN || weightKg.isInfinite) {
      throw ArgumentError('Weight must be positive and finite');
    }

    final rawMin = 25.0 * weightKg;
    final rawMax = 30.0 * weightKg;
    final ceiling = isSevereOrCriticallyIll ? 3000.0 : 2000.0;

    final capApplied = rawMax > ceiling;
    final recommendedMin = min(rawMin, ceiling);
    final recommendedMax = min(rawMax, ceiling);

    return {
      'rawMinDoseMg': rawMin,
      'rawMaxDoseMg': rawMax,
      'recommendedMinDoseMg': recommendedMin,
      'recommendedMaxDoseMg': recommendedMax,
      'ceilingMg': ceiling,
      'capApplied': capApplied,
      'warning': capApplied
          ? 'Loading dose capped at ${ceiling.toInt()} mg to prevent infusion reactions and acute toxicity. Raw calculated dose: ${rawMin.toInt()}-${rawMax.toInt()} mg.'
          : null,
    };
  }

  /// Checks Vancomycin infusion rate against the 10 mg/min Red Man Syndrome ceiling.
  static Map<String, dynamic> checkRedManSyndromeRisk({
    required double doseMg,
    required double infusionDurationMinutes,
  }) {
    if (doseMg <= 0 || doseMg.isNaN || doseMg.isInfinite) {
      throw ArgumentError('Dose must be positive and finite');
    }
    if (infusionDurationMinutes <= 0 ||
        infusionDurationMinutes.isNaN ||
        infusionDurationMinutes.isInfinite) {
      throw ArgumentError('Infusion duration must be positive and finite');
    }

    final rateMgPerMin = doseMg / infusionDurationMinutes;
    final hasRisk = rateMgPerMin > 10.0;
    final minSafeDurationMinutes = max(60.0, doseMg / 10.0);

    return {
      'hasRedManSyndromeRisk': hasRisk,
      'rateMgPerMin': rateMgPerMin,
      'minSafeDurationMinutes': minSafeDurationMinutes,
      'warning': hasRisk
          ? 'Infusion rate (${rateMgPerMin.toStringAsFixed(1)} mg/min) exceeds 10 mg/min safe ceiling; high risk of Red Man Syndrome. Minimum infusion time is ${minSafeDurationMinutes.toInt()} minutes.'
          : null,
    };
  }

  // ==========================================================================
  // 2. AMINOGLYCOSIDES ENGINE (HARTFORD NOMOGRAM & CONVENTIONAL DOSING)
  // ==========================================================================

  /// Evaluates the Hartford Extended-Interval Aminoglycoside Nomogram (Nicolau 1995).
  ///
  /// - Gentamicin/Tobramycin: 7 mg/kg IV q24h.
  /// - Amikacin: 15 mg/kg IV q24h. Measured level must be divided by 2.0 before plotting.
  /// - Random blood level must be drawn between 6.0 and 14.0 hours after the start of 60-min infusion.
  static HartfordNomogramResult evaluateHartfordNomogram({
    required double randomLevelMgL,
    required double hoursPostDose,
    bool isAmikacin = false,
  }) {
    if (randomLevelMgL < 0 || randomLevelMgL.isNaN || randomLevelMgL.isInfinite) {
      throw ArgumentError('Serum level must be non-negative and finite');
    }
    if (hoursPostDose <= 0 || hoursPostDose.isNaN || hoursPostDose.isInfinite) {
      throw ArgumentError('Hours post-dose must be positive and finite');
    }

    final drug = isAmikacin ? NtiDrugType.amikacin : NtiDrugType.gentamicin;
    final normalized = isAmikacin ? (randomLevelMgL / 2.0) : randomLevelMgL;

    // Window violation check (6.0 - 14.0 hr)
    if (hoursPostDose < 6.0 || hoursPostDose > 14.0) {
      return HartfordNomogramResult(
        drug: drug,
        randomLevelMgL: randomLevelMgL,
        hoursPostDose: hoursPostDose,
        normalizedLevelMgL: normalized,
        interval: HartfordInterval.offNomogramHold,
        recommendedIntervalHours: null,
        isOffNomogram: true,
        isWindowViolation: true,
        clinicalGuidance:
            'Sampling time ($hoursPostDose hr) is outside valid Hartford nomogram window (6.0-14.0 hr post-dose). Nomogram cannot be interpreted; individualize dosing via Sawchuk-Zaske kinetics.',
        warnings: [
          'Hartford window violation: blood sample must be drawn 6-14 hours after start of infusion.'
        ],
      );
    }

    // Boundary equations (Nicolau 1995)
    final deltaT = hoursPostDose - 6.0;
    final cQ24 = 9.0 - (7.0 / 8.0) * deltaT;
    final cQ36 = 11.0 - (6.5 / 8.0) * deltaT;
    final cQ48 = 13.0 - (6.0 / 8.0) * deltaT;

    HartfordInterval interval;
    int? recHours;
    bool isOff = false;
    String guidance;
    final warnings = <String>[];

    if (normalized <= cQ24) {
      interval = HartfordInterval.q24h;
      recHours = 24;
      guidance =
          'Continue ${isAmikacin ? 'Amikacin 15 mg/kg' : 'Gentamicin 7 mg/kg'} every 24 hours.';
    } else if (normalized <= cQ36) {
      interval = HartfordInterval.q36h;
      recHours = 36;
      guidance =
          'Extend interval: administer ${isAmikacin ? 'Amikacin 15 mg/kg' : 'Gentamicin 7 mg/kg'} every 36 hours.';
    } else if (normalized <= cQ48) {
      interval = HartfordInterval.q48h;
      recHours = 48;
      guidance =
          'Extend interval: administer ${isAmikacin ? 'Amikacin 15 mg/kg' : 'Gentamicin 7 mg/kg'} every 48 hours.';
    } else {
      interval = HartfordInterval.offNomogramHold;
      recHours = null;
      isOff = true;
      guidance =
          'OFF-NOMOGRAM / TOXIC ACCUMULATION: Level plots above the 48-hour nomogram boundary. Hold subsequent doses, monitor serial trough until safe (< ${isAmikacin ? '2.5' : '1.0'} mcg/mL), and transition to individualized kinetics.';
      warnings.add(
          'Toxic aminoglycoside retention: hold dose and re-check renal panel.');
    }

    return HartfordNomogramResult(
      drug: drug,
      randomLevelMgL: randomLevelMgL,
      hoursPostDose: hoursPostDose,
      normalizedLevelMgL: normalized,
      interval: interval,
      recommendedIntervalHours: recHours,
      isOffNomogram: isOff,
      isWindowViolation: false,
      clinicalGuidance: guidance,
      warnings: warnings,
    );
  }

  /// Evaluates conventional multiple-daily dosing for Gentamicin or Amikacin.
  static ConventionalAminoglycosideResult evaluateConventionalAminoglycoside({
    required NtiDrugType drug,
    required double doseMg,
    required double tauHours,
    required double tInfHours,
    required double vd,
    required double ke,
    double? micMgL,
  }) {
    if (doseMg <= 0 || tauHours <= 0 || tInfHours <= 0 || vd <= 0 || ke <= 0) {
      throw ArgumentError('Dose, Tau, tInf, Vd, and Ke must be positive');
    }
    if (tauHours <= tInfHours) {
      throw ArgumentError('Tau must exceed tInf');
    }

    // Steady-state intermittent infusion equations
    final peakMgL = (doseMg / (tInfHours * vd * ke)) *
        ((1.0 - exp(-ke * tInfHours)) / (1.0 - exp(-ke * tauHours)));
    final troughMgL = peakMgL * exp(-ke * (tauHours - tInfHours));

    final isAmikacin = drug == NtiDrugType.amikacin;
    final targetPeakMin = isAmikacin ? 20.0 : 6.0;
    final targetPeakMax = isAmikacin ? 30.0 : 10.0;
    final targetTroughMax = isAmikacin ? 5.0 : 2.0;
    final toxicPeakThreshold = isAmikacin ? 35.0 : 10.0;
    final toxicTroughThreshold = isAmikacin ? 10.0 : 2.0;

    final isPeakTherapeutic =
        peakMgL >= targetPeakMin && peakMgL <= targetPeakMax;
    final isPeakToxic = peakMgL > toxicPeakThreshold;
    final isPeakSub = peakMgL < targetPeakMin;
    final isTroughSafe = troughMgL < toxicTroughThreshold;
    final isTroughToxic = troughMgL >= toxicTroughThreshold;

    double? peakToMic;
    bool isPeakToMicOptimal = false;
    if (micMgL != null && micMgL > 0) {
      peakToMic = peakMgL / micMgL;
      isPeakToMicOptimal = peakToMic >= 8.0;
    }

    final warnings = <String>[];
    if (isTroughToxic) {
      warnings.add(
          'CRITICAL: Elevated trough ($troughMgL mcg/mL >= $toxicTroughThreshold mcg/mL) risks acute tubular necrosis and irreversible ototoxicity.');
    }
    if (isPeakToxic) {
      warnings.add(
          'Supratherapeutic peak ($peakMgL mcg/mL > $toxicPeakThreshold mcg/mL).');
    } else if (isPeakSub) {
      warnings.add(
          'Subtherapeutic peak ($peakMgL mcg/mL < $targetPeakMin mcg/mL).');
    }
    if (micMgL != null && !isPeakToMicOptimal) {
      warnings.add(
          'Peak/MIC ratio ($peakToMic < 8.0): Suboptimal concentration-dependent bactericidal killing.');
    }

    final guidance = (isPeakTherapeutic && isTroughSafe)
        ? 'Optimal conventional aminoglycoside regimen achieving target peak ($targetPeakMin-$targetPeakMax mcg/mL) and safe trough (< $targetTroughMax mcg/mL).'
        : 'Suboptimal regimen: adjust dose or interval to attain target peak and safe trough.';

    return ConventionalAminoglycosideResult(
      drug: drug,
      doseMg: doseMg,
      tauHours: tauHours,
      tInfHours: tInfHours,
      peakMgL: peakMgL,
      troughMgL: troughMgL,
      targetPeakMin: targetPeakMin,
      targetPeakMax: targetPeakMax,
      targetTroughMax: targetTroughMax,
      isPeakTherapeutic: isPeakTherapeutic,
      isPeakToxic: isPeakToxic,
      isPeakSubtherapeutic: isPeakSub,
      isTroughSafe: isTroughSafe,
      isTroughToxic: isTroughToxic,
      peakToMicRatio: peakToMic,
      micMgL: micMgL,
      isPeakToMicOptimal: isPeakToMicOptimal,
      clinicalGuidance: guidance,
      warnings: warnings,
    );
  }

  // ==========================================================================
  // 3. PHENYTOIN NON-LINEAR MICHAELIS-MENTEN KINETICS & ALBUMIN CORRECTION
  // ==========================================================================

  /// Evaluates Phenytoin non-linear pharmacokinetics and Sheiner-Tozer albumin adjustment.
  ///
  /// - Michaelis-Menten steady-state: Css = (Km * Dose) / (Vmax - Dose)
  /// - Saturation guard: when Dose >= Vmax, triggers `phenytoinCapacityExceeded` without crashing.
  /// - Normal renal function: Cadj = Cobs / ((0.2 * Albumin) + 0.1)
  /// - ESRD / CrCl < 20 mL/min (Winter-Tozer): Cadj = Cobs / ((0.1 * Albumin) + 0.1)
  static PhenytoinDosingResult evaluatePhenytoin({
    required double orderedDailyDoseMg,
    required double weightKg,
    double vmaxMgPerKgDay = 7.0,
    double kmMgL = 4.0,
    double? observedSerumPhenytoinMgL,
    double? serumAlbuminGPerDl,
    double? crclMlMin,
    double? ivInfusionRateMgPerMin,
    bool isElderlyOrCardiac = false,
  }) {
    if (orderedDailyDoseMg <= 0 ||
        orderedDailyDoseMg.isNaN ||
        orderedDailyDoseMg.isInfinite) {
      throw ArgumentError('Ordered dose must be positive and finite');
    }
    if (weightKg <= 0 || weightKg.isNaN || weightKg.isInfinite) {
      throw ArgumentError('Weight must be positive and finite');
    }

    final totalVmax = vmaxMgPerKgDay * weightKg;
    final warningCodes = <String>[];
    final warnings = <String>[];

    // Saturation Guard
    final isCapacityExceeded = orderedDailyDoseMg >= totalVmax;
    double? predictedCss;

    if (isCapacityExceeded) {
      warningCodes.add('phenytoinCapacityExceeded');
      warnings.add(
          'CRITICAL: Ordered daily dose ($orderedDailyDoseMg mg/day) equals or exceeds total metabolic capacity Vmax ($totalVmax mg/day). Hepatic clearance is fully saturated, leading to unbounded drug accumulation and acute neurotoxicity.');
    } else {
      predictedCss = (kmMgL * orderedDailyDoseMg) / (totalVmax - orderedDailyDoseMg);
      if (predictedCss > 20.0) {
        warningCodes.add('phenytoinTargetExceeded');
        warnings.add(
            'Predicted steady-state concentration (${predictedCss.toStringAsFixed(1)} mg/L) exceeds 20.0 mg/L upper therapeutic limit.');
      } else if (predictedCss < 10.0) {
        warningCodes.add('phenytoinSubtherapeutic');
        warnings.add(
            'Predicted steady-state concentration (${predictedCss.toStringAsFixed(1)} mg/L) is below 10.0 mg/L therapeutic floor.');
      }
    }

    // Albumin adjustment (Sheiner-Tozer vs Winter-Tozer)
    double? adjustedCss;
    bool isSheinerTozer = false;
    bool isWinterTozer = false;

    if (observedSerumPhenytoinMgL != null && serumAlbuminGPerDl != null) {
      // Normalize albumin if given in g/L (e.g. 35 g/L -> 3.5 g/dL)
      final albGPerDl =
          serumAlbuminGPerDl > 10.0 ? (serumAlbuminGPerDl / 10.0) : serumAlbuminGPerDl;

      final isSevereRenalFailure = crclMlMin != null && crclMlMin < 20.0;
      if (isSevereRenalFailure) {
        // Winter-Tozer equation for ESRD
        adjustedCss = observedSerumPhenytoinMgL / (0.1 * albGPerDl + 0.1);
        isWinterTozer = true;
        warningCodes.add('phenytoinRenalImpairment');
        warnings.add(
            'Severe renal impairment (CrCl < 20 mL/min): Winter-Tozer uremic displacement correction applied.');
      } else {
        // Sheiner-Tozer equation
        adjustedCss = observedSerumPhenytoinMgL / (0.2 * albGPerDl + 0.1);
        isSheinerTozer = true;
        if (albGPerDl < 3.5) {
          warningCodes.add('phenytoinHypoalbuminemia');
          warnings.add(
              'Hypoalbuminemia ($albGPerDl g/dL < 3.5): Sheiner-Tozer protein-binding correction applied.');
        }
      }
    }

    final effectiveCss = adjustedCss ?? predictedCss ?? 0.0;
    final isToxic = effectiveCss > 20.0 || isCapacityExceeded;
    final isSub = effectiveCss < 10.0 && !isCapacityExceeded;
    final isTherapeutic =
        effectiveCss >= 10.0 && effectiveCss <= 20.0 && !isCapacityExceeded;

    // Toxicity Stage Classification
    String? toxicityTier;
    if (effectiveCss > 50.0) {
      toxicityTier = 'Coma, paradoxical seizure exacerbation, death risk';
    } else if (effectiveCss > 40.0) {
      toxicityTier = 'Lethargy, confusion, stupor';
    } else if (effectiveCss > 30.0) {
      toxicityTier = 'Ataxia, slurred speech, tremors';
    } else if (effectiveCss > 20.0) {
      toxicityTier = 'Far-lateral nystagmus';
    }

    // IV Infusion Rate Limit Check
    bool hasIvRateRisk = false;
    if (ivInfusionRateMgPerMin != null) {
      final maxRate = isElderlyOrCardiac ? 25.0 : 50.0;
      if (ivInfusionRateMgPerMin > maxRate) {
        hasIvRateRisk = true;
        warningCodes.add('phenytoinIvRateExceeded');
        warnings.add(
            'IV infusion rate ($ivInfusionRateMgPerMin mg/min) exceeds $maxRate mg/min limit. Severe hypotension, arrhythmias, and cardiovascular collapse risk.');
      }
    }

    String guidance;
    if (isCapacityExceeded) {
      guidance =
          'CRITICAL SATURATION: Dose must be reduced below Vmax ($totalVmax mg/day). Rule 5 preserves ordered dose for clinical review.';
    } else if (isToxic) {
      guidance =
          'TOXIC EXPOSURE: Concentration (${effectiveCss.toStringAsFixed(1)} mg/L) exceeds 20.0 mg/L target. ${toxicityTier ?? ''}';
    } else if (isSub) {
      guidance =
          'SUB-THERAPEUTIC: Concentration (${effectiveCss.toStringAsFixed(1)} mg/L) is below 10.0 mg/L; risk of breakthrough seizures.';
    } else {
      guidance =
          'OPTIMAL: Steady-state concentration (${effectiveCss.toStringAsFixed(1)} mg/L) within 10.0-20.0 mg/L therapeutic target.';
    }

    return PhenytoinDosingResult(
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
      isSubtherapeutic: isSub,
      isTherapeutic: isTherapeutic,
      toxicityTier: toxicityTier,
      ivInfusionRateMgPerMin: ivInfusionRateMgPerMin,
      hasIvRateRisk: hasIvRateRisk,
      clinicalGuidance: guidance,
      warningCodes: warningCodes,
      warnings: warnings,
    );
  }

  /// Calculates maintenance daily dose for desired target steady-state Phenytoin concentration.
  ///
  /// Dose = (Vmax * Target Css) / (Km + Target Css)
  static double calculatePhenytoinDoseForTargetCss({
    required double targetCssMgL,
    required double weightKg,
    double vmaxMgPerKgDay = 7.0,
    double kmMgL = 4.0,
  }) {
    if (targetCssMgL <= 0 || weightKg <= 0 || vmaxMgPerKgDay <= 0 || kmMgL <= 0) {
      throw ArgumentError('All parameters must be positive and finite');
    }
    final totalVmax = vmaxMgPerKgDay * weightKg;
    return (totalVmax * targetCssMgL) / (kmMgL + targetCssMgL);
  }

  // ==========================================================================
  // 4. DIGOXIN, LITHIUM, THEOPHYLLINE SAFETY & TIMING GUARDS
  // ==========================================================================

  /// Checks NTI electrolyte disturbances and distribution phase sampling timing.
  static NtiSafetyCheckResult checkNtiSafety({
    required dynamic drug,
    double? serumPotassiumMEqL,
    double? serumMagnesiumMgDl,
    double? serumCalciumMgDl,
    double? serumSodiumMEqL,
    double? hoursPostDoseSampling,
    bool hasNsaidOrAceiOrArbOrThiazide = false,
    double? hoursOnMaintenanceTherapy,
  }) {
    NtiDrugType drugType;
    if (drug is NtiDrugType) {
      drugType = drug;
    } else if (drug is String) {
      final name = drug.toLowerCase().trim();
      if (name.contains('digoxin')) {
        drugType = NtiDrugType.digoxin;
      } else if (name.contains('lithium')) {
        drugType = NtiDrugType.lithium;
      } else if (name.contains('theophylline') || name.contains('aminophylline')) {
        drugType = NtiDrugType.theophylline;
      } else if (name.contains('phenytoin')) {
        drugType = NtiDrugType.phenytoin;
      } else if (name.contains('gentamicin')) {
        drugType = NtiDrugType.gentamicin;
      } else if (name.contains('amikacin')) {
        drugType = NtiDrugType.amikacin;
      } else {
        drugType = NtiDrugType.vancomycin;
      }
    } else {
      throw ArgumentError('Drug must be NtiDrugType or String');
    }

    final warnings = <String>[];
    bool kRisk = false;
    bool mgRisk = false;
    bool caRisk = false;
    bool naRisk = false;
    bool distPhaseRisk = false;

    switch (drugType) {
      case NtiDrugType.digoxin:
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
        break;

      case NtiDrugType.lithium:
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
        if (hasNsaidOrAceiOrArbOrThiazide) {
          warnings.add(
              'DDI Alert: Concurrent NSAID, ACEI, ARB, or Thiazide diuretic reduces lithium clearance by 30-50%.');
        }
        break;

      case NtiDrugType.theophylline:
        if (hoursOnMaintenanceTherapy != null && hoursOnMaintenanceTherapy < 48.0) {
          warnings.add(
              'Theophylline requires 48-72 hours of maintenance dosing to attain steady state before level evaluation.');
        }
        break;

      default:
        break;
    }

    final isSafe = warnings.isEmpty;

    return NtiSafetyCheckResult(
      drug: drugType,
      serumPotassiumMEqL: serumPotassiumMEqL,
      serumMagnesiumMgDl: serumMagnesiumMgDl,
      serumCalciumMgDl: serumCalciumMgDl,
      serumSodiumMEqL: serumSodiumMEqL,
      hoursPostDoseSampling: hoursPostDoseSampling,
      hasPotassiumRisk: kRisk,
      hasMagnesiumRisk: mgRisk,
      hasCalciumRisk: caRisk,
      hasSodiumRisk: naRisk,
      hasDistributionPhaseWarning: distPhaseRisk,
      clinicalWarnings: warnings,
      isSafe: isSafe,
    );
  }

  // ==========================================================================
  // 5. SPECIAL POPULATIONS: BODY WEIGHT & RENAL CLEARANCE
  // ==========================================================================

  /// Devine Ideal Body Weight (IBW) in kg.
  static double calculateDevineIbw({
    required double heightCm,
    required bool isMale,
  }) {
    if (heightCm <= 0 || heightCm.isNaN || heightCm.isInfinite) {
      throw ArgumentError('Height must be positive and finite');
    }
    final heightInches = heightCm / 2.54;
    final base = isMale ? 50.0 : 45.5;
    return base + 2.3 * (heightInches - 60.0);
  }

  /// Adjusted Body Weight (AdjBW 0.4) for obese patients in kg.
  static double calculateAdjBw04({
    required double tbwKg,
    required double ibwKg,
  }) {
    if (tbwKg <= 0 || ibwKg <= 0) {
      throw ArgumentError('Weights must be positive and finite');
    }
    return ibwKg + 0.4 * (tbwKg - ibwKg);
  }

  /// Selects the clinically appropriate dosing weight for aminoglycosides.
  ///
  /// - If TBW < IBW (underweight): use TBW (prevents severe overdose).
  /// - If obese (BMI >= 30.0 or TBW >= 1.20 * IBW): MANDATORY AdjBW 0.4.
  /// - Otherwise (normal weight): use IBW.
  static double selectAminoglycosideDosingWeight({
    required double tbwKg,
    required double heightCm,
    required bool isMale,
  }) {
    final ibw = calculateDevineIbw(heightCm: heightCm, isMale: isMale);
    final bmi = tbwKg / pow(heightCm / 100.0, 2);

    if (tbwKg < ibw) return tbwKg;
    if (bmi >= 30.0 || tbwKg >= 1.20 * ibw) {
      return calculateAdjBw04(tbwKg: tbwKg, ibwKg: ibw);
    }
    return ibw;
  }

  /// Selects dosing weight across special populations and provides rationale.
  static SpecialPopulationWeightResult selectWeightForSpecialPopulations({
    required double tbwKg,
    required double heightCm,
    required bool isMale,
    required NtiDrugType drugType,
  }) {
    if (tbwKg <= 0 || heightCm <= 0) {
      throw ArgumentError('Weight and height must be positive and finite');
    }

    final ibw = calculateDevineIbw(heightCm: heightCm, isMale: isMale);
    final bmi = tbwKg / pow(heightCm / 100.0, 2);
    final adjBw = calculateAdjBw04(tbwKg: tbwKg, ibwKg: ibw);

    final isUnderweight = tbwKg < ibw;
    final isObese = bmi >= 30.0 || tbwKg >= 1.20 * ibw;

    double selected;
    String rationale;

    if (isUnderweight) {
      selected = tbwKg;
      rationale =
          'Underweight (TBW < IBW): Actual Body Weight enforced to prevent toxic overdose.';
    } else if (isObese) {
      if (drugType == NtiDrugType.gentamicin || drugType == NtiDrugType.amikacin) {
        selected = adjBw;
        rationale =
            'Obesity (BMI >= 30 or TBW >= 120% IBW): MANDATORY Adjusted Body Weight (AdjBW 0.4) enforced for hydrophilic aminoglycoside.';
      } else if (drugType == NtiDrugType.vancomycin) {
        selected = adjBw;
        rationale =
            'Obesity (BMI >= 30 or TBW >= 120% IBW): Adjusted Body Weight (AdjBW 0.4) recommended for maintenance dosing.';
      } else {
        selected = adjBw;
        rationale =
            'Obesity (BMI >= 30 or TBW >= 120% IBW): Adjusted Body Weight (AdjBW 0.4) recommended.';
      }
    } else {
      selected = ibw;
      rationale = 'Normal weight: Ideal Body Weight (IBW) selected.';
    }

    return SpecialPopulationWeightResult(
      tbwKg: tbwKg,
      heightCm: heightCm,
      isMale: isMale,
      bmi: bmi,
      ibwKg: ibw,
      adjBw04Kg: adjBw,
      isUnderweight: isUnderweight,
      isObese: isObese,
      selectedWeightKg: selected,
      rationale: rationale,
    );
  }

  /// Calculates Cockcroft-Gault Creatinine Clearance with elderly sarcopenia SCr floor (0.8 mg/dL).
  static Map<String, dynamic> calculateCockcroftGaultWithElderlyFloor({
    required double ageYears,
    required double weightKg,
    required double serumCreatinineMgDl,
    required bool isMale,
  }) {
    if (ageYears <= 0 || weightKg <= 0 || serumCreatinineMgDl <= 0) {
      throw ArgumentError('Age, Weight, and SCr must be positive and finite');
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
      'effectiveScr': effectiveScr,
    };
  }

  /// Pediatric Bedside Schwartz eGFR (mL/min/1.73m²) with subpopulation k-constants.
  ///
  /// - Preterm infants: k = 0.33
  /// - Term infants (0-1 yr): k = 0.45
  /// - Children & adolescent females: k = 0.413
  /// - Adolescent males (13-17 yr): k = 0.62 (or 0.413)
  static double calculateBedsideSchwartz({
    required double heightCm,
    required double serumCreatinineMgDl,
    double? kConstant,
    bool isPreterm = false,
    bool isTermInfant = false,
    bool isAdolescentMale = false,
  }) {
    if (heightCm <= 0 || serumCreatinineMgDl <= 0) {
      throw ArgumentError('Height and SCr must be positive and finite');
    }

    double k;
    if (kConstant != null) {
      if (kConstant <= 0 || kConstant.isNaN || kConstant.isInfinite) {
        throw ArgumentError('kConstant must be positive and finite');
      }
      k = kConstant;
    } else if (isPreterm) {
      k = 0.33;
    } else if (isTermInfant) {
      k = 0.45;
    } else if (isAdolescentMale) {
      k = 0.62;
    } else {
      k = 0.413;
    }

    return (k * heightCm) / serumCreatinineMgDl;
  }

  // ==========================================================================
  // 6. HIGH-ALERT CONTINUOUS INFUSIONS (INOTROPES & VASOPRESSORS)
  // ==========================================================================

  /// Standard hospital concentrations in mcg/mL.
  static double getStandardConcentrationMcgPerMl({
    required VasoactiveDrug drug,
    required VasoactiveDilution dilution,
  }) {
    switch (drug) {
      case VasoactiveDrug.norepinephrine:
      case VasoactiveDrug.epinephrine:
        return dilution == VasoactiveDilution.doubleStrength ? 32.0 : 16.0;
      case VasoactiveDrug.dopamine:
        return dilution == VasoactiveDilution.doubleStrength ? 3200.0 : 1600.0;
      case VasoactiveDrug.dobutamine:
        return dilution == VasoactiveDilution.doubleStrength ? 2000.0 : 1000.0;
    }
  }

  /// Calculates infusion pump rate (mL/hr) for high-alert vasoactive continuous infusions.
  ///
  /// Adheres strictly to **Rule 5 (Non-Blocking Overdose Policy)**:
  /// When maximum titration ceilings are breached, the calculated rate is NEVER suppressed or zeroed,
  /// but triggers an explicit critical warning and records [overrideJustification].
  static VasoactiveInfusionResult calculateVasoactiveInfusion({
    required dynamic drug,
    required double orderedDose,
    required String doseUnit,
    required double patientWeightKg,
    double? concentrationMcgPerMl,
    VasoactiveDilution dilution = VasoactiveDilution.singleStrength,
    ClinicalOverrideJustification? overrideJustification,
  }) {
    if (orderedDose <= 0 || orderedDose.isNaN || orderedDose.isInfinite) {
      throw ArgumentError('Ordered dose must be positive and finite');
    }
    if (patientWeightKg <= 0 || patientWeightKg.isNaN || patientWeightKg.isInfinite) {
      throw ArgumentError('Patient weight must be positive and finite');
    }

    VasoactiveDrug vasoactiveDrug;
    String drugId;
    if (drug is VasoactiveDrug) {
      vasoactiveDrug = drug;
      drugId = drug.name;
    } else if (drug is String) {
      drugId = drug.toLowerCase().trim();
      if (drugId.contains('norepinephrine') ||
          drugId.contains('noradrenaline') ||
          drugId.contains('levophed')) {
        vasoactiveDrug = VasoactiveDrug.norepinephrine;
      } else if (drugId.contains('epinephrine') ||
          drugId.contains('adrenaline') ||
          drugId.contains('adrenalin') ||
          drugId.contains('อะดรีนาลิน')) {
        vasoactiveDrug = VasoactiveDrug.epinephrine;
      } else if (drugId.contains('dopamine') || drugId.contains('intropin')) {
        vasoactiveDrug = VasoactiveDrug.dopamine;
      } else if (drugId.contains('dobutamine') || drugId.contains('dobutrex')) {
        vasoactiveDrug = VasoactiveDrug.dobutamine;
      } else {
        throw ArgumentError(
          'Unrecognized vasoactive drug: "$drug". Expected epinephrine/adrenaline, norepinephrine, dopamine, or dobutamine.',
        );
      }
    } else {
      throw ArgumentError('Drug must be VasoactiveDrug or String');
    }

    final finalConc = concentrationMcgPerMl ??
        getStandardConcentrationMcgPerMl(
          drug: vasoactiveDrug,
          dilution: dilution,
        );

    if (finalConc <= 0 || finalConc.isNaN || finalConc.isInfinite) {
      throw ArgumentError('Concentration must be positive and finite');
    }

    final normalizedUnit = doseUnit.trim().toLowerCase().replaceAll(' ', '');
    double pumpRateMlPerHr;
    double deliveredMcgKgMin;

    if (normalizedUnit == 'mcg/kg/min' ||
        normalizedUnit == 'mcg/kg/minute' ||
        normalizedUnit == 'mcgkgmin') {
      pumpRateMlPerHr = (orderedDose * patientWeightKg * 60.0) / finalConc;
      deliveredMcgKgMin = orderedDose;
    } else if (normalizedUnit == 'mcg/min' ||
        normalizedUnit == 'mcg/minute' ||
        normalizedUnit == 'mcgmin') {
      // absolute mcg/min
      pumpRateMlPerHr = (orderedDose * 60.0) / finalConc;
      deliveredMcgKgMin = orderedDose / patientWeightKg;
    } else {
      throw ArgumentError(
        'Unsupported doseUnit for vasoactive infusion: "$doseUnit". Expected "mcg/kg/min" or "mcg/min".',
      );
    }

    // Standard Titration Ceilings (AHA/ACC/Surviving Sepsis)
    double ceiling;
    switch (vasoactiveDrug) {
      case VasoactiveDrug.norepinephrine:
      case VasoactiveDrug.epinephrine:
        ceiling = 1.0; // mcg/kg/min
        break;
      case VasoactiveDrug.dopamine:
      case VasoactiveDrug.dobutamine:
        ceiling = 20.0; // mcg/kg/min
        break;
    }

    final isCeilingExceeded = deliveredMcgKgMin > ceiling;
    String warning = '';
    if (isCeilingExceeded) {
      warning =
          'CRITICAL OVERDOSE / TITRATION CEILING EXCEEDED: Delivered rate ($deliveredMcgKgMin mcg/kg/min) exceeds standard ceiling ($ceiling mcg/kg/min). Rule 5 non-blocking active.';
    }

    return VasoactiveInfusionResult(
      drug: vasoactiveDrug,
      drugId: drugId,
      orderedDose: orderedDose,
      doseUnit: doseUnit,
      patientWeightKg: patientWeightKg,
      concentrationMcgPerMl: finalConc,
      dilutionType: dilution,
      pumpRateMlPerHr: pumpRateMlPerHr,
      deliveredMcgKgMin: deliveredMcgKgMin,
      isCeilingExceeded: isCeilingExceeded,
      ceilingThreshold: ceiling,
      overrideJustification: overrideJustification,
      warningMessage: warning,
    );
  }
}
