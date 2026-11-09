/// Narrow Therapeutic Index (NTI) drug classification.
enum NtiDrugType {
  vancomycin,
  gentamicin,
  amikacin,
  phenytoin,
  digoxin,
  lithium,
  theophylline,
}

/// Clinical infection severity classification for TDM target stratification.
enum InfectionSeverity {
  /// Uncomplicated infection (e.g. cellulitis, uncomplicated skin/soft tissue, UTI).
  mildModerate,

  /// Serious or invasive infection (e.g. bacteremia, infective endocarditis, osteomyelitis, meningitis, HAP/VAP, septic shock).
  severeInvasive,
}

/// Hartford once-daily aminoglycoside nomogram dosing intervals.
enum HartfordInterval {
  /// Administer dose every 24 hours.
  q24h,

  /// Administer dose every 36 hours.
  q36h,

  /// Administer dose every 48 hours.
  q48h,

  /// Concentration is above the 48h nomogram line or off-nomogram: hold therapy, monitor serial troughs, and individualize.
  offNomogramHold,
}

/// High-alert continuous infusion vasoactive agents.
enum VasoactiveDrug {
  norepinephrine,
  epinephrine,
  dopamine,
  dobutamine,
}

/// Standardized hospital vasoactive dilution categories.
enum VasoactiveDilution {
  /// Single strength standard dilution (e.g., Norepi 4 mg in 250 mL = 16 mcg/mL).
  singleStrength,

  /// Double strength fluid-restriction dilution (e.g., Norepi 8 mg in 250 mL = 32 mcg/mL).
  doubleStrength,

  /// Custom pharmacist / ICU prepared concentration.
  custom,
}

/// Result of Vancomycin AUC24/MIC, trough, kinetic, and loading dose evaluation.
class VancomycinDosingResult {
  /// 24-hour Area Under the Curve in mg·h/L.
  final double auc24;

  /// Broth microdilution Minimum Inhibitory Concentration in mg/L (default 1.0).
  final double micMgL;

  /// Calculated AUC24 / MIC ratio (unitless / mg·h/L).
  final double aucToMicRatio;

  /// Stratified clinical infection severity.
  final InfectionSeverity severity;

  /// Whether the ratio is within target therapeutic range (400-600 for severe, 300-450 for mild).
  final bool isTherapeutic;

  /// Whether exposure is sub-therapeutic (ratio < targetMin).
  final bool isSubtherapeutic;

  /// Whether exposure exceeds nephrotoxic threshold (> 600 mg·h/L).
  final bool isSupratherapeuticNephrotoxic;

  /// Minimum guideline target ratio.
  final double targetMin;

  /// Maximum guideline target ratio.
  final double targetMax;

  /// Recommended surrogate trough lower bound (10 mcg/mL mild, 15 mcg/mL severe).
  final double troughTargetMin;

  /// Recommended surrogate trough upper bound (15 mcg/mL mild, 20 mcg/mL severe).
  final double troughTargetMax;

  /// Actionable clinical guidance text.
  final String clinicalGuidance;

  /// Recommended maintenance dose in mg per interval to achieve target AUC24.
  final double? recommendedDoseMg;

  /// Loading dose in mg (25-30 mg/kg, capped at 3000 mg).
  final double? loadingDoseMg;

  /// Uncapped raw mathematical loading dose in mg.
  final double? loadingDoseRawMg;

  /// Whether the 3000 mg (or 2000 mg) loading dose ceiling was applied.
  final bool loadingDoseCapApplied;

  /// Planned or evaluated infusion duration in minutes.
  final double? infusionDurationMinutes;

  /// Whether infusion rate exceeds 10 mg/min, risking Red Man Syndrome.
  final bool hasRedManSyndromeRisk;

  /// Individualized elimination rate constant from Sawchuk-Zaske in hr^-1.
  final double? sawchukZaskeKe;

  /// Individualized volume of distribution from Sawchuk-Zaske in Liters.
  final double? sawchukZaskeVd;

  /// True back-extrapolated peak concentration in mg/L (mcg/mL).
  final double? truePeak;

  /// True forward-extrapolated trough concentration in mg/L (mcg/mL).
  final double? trueTrough;

  /// Machine and human readable clinical alerts.
  final List<String> warnings;

  const VancomycinDosingResult({
    required this.auc24,
    required this.micMgL,
    required this.aucToMicRatio,
    required this.severity,
    required this.isTherapeutic,
    required this.isSubtherapeutic,
    required this.isSupratherapeuticNephrotoxic,
    required this.targetMin,
    required this.targetMax,
    required this.troughTargetMin,
    required this.troughTargetMax,
    required this.clinicalGuidance,
    this.recommendedDoseMg,
    this.loadingDoseMg,
    this.loadingDoseRawMg,
    this.loadingDoseCapApplied = false,
    this.infusionDurationMinutes,
    this.hasRedManSyndromeRisk = false,
    this.sawchukZaskeKe,
    this.sawchukZaskeVd,
    this.truePeak,
    this.trueTrough,
    this.warnings = const [],
  });

  Map<String, dynamic> toMap() => {
        'auc24': auc24,
        'micMgL': micMgL,
        'aucToMicRatio': aucToMicRatio,
        'severity': severity.name,
        'isTherapeutic': isTherapeutic,
        'isSubtherapeutic': isSubtherapeutic,
        'isSupratherapeuticNephrotoxic': isSupratherapeuticNephrotoxic,
        'targetMin': targetMin,
        'targetMax': targetMax,
        'troughTargetMin': troughTargetMin,
        'troughTargetMax': troughTargetMax,
        'clinicalGuidance': clinicalGuidance,
        'recommendedDoseMg': recommendedDoseMg,
        'loadingDoseMg': loadingDoseMg,
        'loadingDoseRawMg': loadingDoseRawMg,
        'loadingDoseCapApplied': loadingDoseCapApplied,
        'infusionDurationMinutes': infusionDurationMinutes,
        'hasRedManSyndromeRisk': hasRedManSyndromeRisk,
        'sawchukZaskeKe': sawchukZaskeKe,
        'sawchukZaskeVd': sawchukZaskeVd,
        'truePeak': truePeak,
        'trueTrough': trueTrough,
        'warnings': warnings,
      };

  factory VancomycinDosingResult.fromMap(Map<String, dynamic> map) =>
      VancomycinDosingResult(
        auc24: (map['auc24'] as num).toDouble(),
        micMgL: (map['micMgL'] as num).toDouble(),
        aucToMicRatio: (map['aucToMicRatio'] as num).toDouble(),
        severity: InfectionSeverity.values.byName(map['severity'] as String),
        isTherapeutic: map['isTherapeutic'] as bool,
        isSubtherapeutic: map['isSubtherapeutic'] as bool,
        isSupratherapeuticNephrotoxic:
            map['isSupratherapeuticNephrotoxic'] as bool,
        targetMin: (map['targetMin'] as num).toDouble(),
        targetMax: (map['targetMax'] as num).toDouble(),
        troughTargetMin: (map['troughTargetMin'] as num).toDouble(),
        troughTargetMax: (map['troughTargetMax'] as num).toDouble(),
        clinicalGuidance: map['clinicalGuidance'] as String,
        recommendedDoseMg: (map['recommendedDoseMg'] as num?)?.toDouble(),
        loadingDoseMg: (map['loadingDoseMg'] as num?)?.toDouble(),
        loadingDoseRawMg: (map['loadingDoseRawMg'] as num?)?.toDouble(),
        loadingDoseCapApplied: map['loadingDoseCapApplied'] as bool? ?? false,
        infusionDurationMinutes:
            (map['infusionDurationMinutes'] as num?)?.toDouble(),
        hasRedManSyndromeRisk:
            map['hasRedManSyndromeRisk'] as bool? ?? false,
        sawchukZaskeKe: (map['sawchukZaskeKe'] as num?)?.toDouble(),
        sawchukZaskeVd: (map['sawchukZaskeVd'] as num?)?.toDouble(),
        truePeak: (map['truePeak'] as num?)?.toDouble(),
        trueTrough: (map['trueTrough'] as num?)?.toDouble(),
        warnings: List<String>.from(map['warnings'] as List? ?? const []),
      );

  @override
  String toString() =>
      'VancomycinDosingResult(auc24: $auc24, ratio: $aucToMicRatio, therapeutic: $isTherapeutic, toxic: $isSupratherapeuticNephrotoxic)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VancomycinDosingResult &&
          runtimeType == other.runtimeType &&
          auc24 == other.auc24 &&
          micMgL == other.micMgL &&
          aucToMicRatio == other.aucToMicRatio &&
          severity == other.severity &&
          isTherapeutic == other.isTherapeutic &&
          isSubtherapeutic == other.isSubtherapeutic &&
          isSupratherapeuticNephrotoxic ==
              other.isSupratherapeuticNephrotoxic &&
          hasRedManSyndromeRisk == other.hasRedManSyndromeRisk;

  @override
  int get hashCode => Object.hash(
        auc24,
        micMgL,
        aucToMicRatio,
        severity,
        isTherapeutic,
        isSubtherapeutic,
        isSupratherapeuticNephrotoxic,
        hasRedManSyndromeRisk,
      );
}

/// Evaluation result from Hartford once-daily aminoglycoside nomogram.
class HartfordNomogramResult {
  /// Evaluated aminoglycoside drug (gentamicin or amikacin).
  final NtiDrugType drug;

  /// Raw measured serum concentration in mg/L (mcg/mL).
  final double randomLevelMgL;

  /// Elapsed time from start of 60-min infusion in hours (valid 6.0 - 14.0h).
  final double hoursPostDose;

  /// Normalized concentration (Amikacin divided by 2.0; Gentamicin unchanged).
  final double normalizedLevelMgL;

  /// Recommended interval zone on nomogram.
  final HartfordInterval interval;

  /// Recommended interval duration in hours (24, 36, 48, or null if hold).
  final int? recommendedIntervalHours;

  /// Whether concentration plots above q48h line (toxic hold required).
  final bool isOffNomogram;

  /// Whether sampling time violates 6.0-14.0h window.
  final bool isWindowViolation;

  /// Clinical guidance and action instructions.
  final String clinicalGuidance;

  /// Warning advisories.
  final List<String> warnings;

  const HartfordNomogramResult({
    required this.drug,
    required this.randomLevelMgL,
    required this.hoursPostDose,
    required this.normalizedLevelMgL,
    required this.interval,
    this.recommendedIntervalHours,
    required this.isOffNomogram,
    required this.isWindowViolation,
    required this.clinicalGuidance,
    this.warnings = const [],
  });

  Map<String, dynamic> toMap() => {
        'drug': drug.name,
        'randomLevelMgL': randomLevelMgL,
        'hoursPostDose': hoursPostDose,
        'normalizedLevelMgL': normalizedLevelMgL,
        'interval': interval.name,
        'recommendedIntervalHours': recommendedIntervalHours,
        'isOffNomogram': isOffNomogram,
        'isWindowViolation': isWindowViolation,
        'clinicalGuidance': clinicalGuidance,
        'warnings': warnings,
      };

  factory HartfordNomogramResult.fromMap(Map<String, dynamic> map) =>
      HartfordNomogramResult(
        drug: NtiDrugType.values.byName(map['drug'] as String),
        randomLevelMgL: (map['randomLevelMgL'] as num).toDouble(),
        hoursPostDose: (map['hoursPostDose'] as num).toDouble(),
        normalizedLevelMgL: (map['normalizedLevelMgL'] as num).toDouble(),
        interval: HartfordInterval.values.byName(map['interval'] as String),
        recommendedIntervalHours: map['recommendedIntervalHours'] as int?,
        isOffNomogram: map['isOffNomogram'] as bool,
        isWindowViolation: map['isWindowViolation'] as bool,
        clinicalGuidance: map['clinicalGuidance'] as String,
        warnings: List<String>.from(map['warnings'] as List? ?? const []),
      );

  @override
  String toString() =>
      'HartfordNomogramResult(drug: ${drug.name}, hours: $hoursPostDose, level: $randomLevelMgL, interval: ${interval.name})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HartfordNomogramResult &&
          runtimeType == other.runtimeType &&
          drug == other.drug &&
          randomLevelMgL == other.randomLevelMgL &&
          hoursPostDose == other.hoursPostDose &&
          normalizedLevelMgL == other.normalizedLevelMgL &&
          interval == other.interval &&
          recommendedIntervalHours == other.recommendedIntervalHours &&
          isOffNomogram == other.isOffNomogram &&
          isWindowViolation == other.isWindowViolation;

  @override
  int get hashCode => Object.hash(
        drug,
        randomLevelMgL,
        hoursPostDose,
        normalizedLevelMgL,
        interval,
        recommendedIntervalHours,
        isOffNomogram,
        isWindowViolation,
      );
}

/// Evaluation result for conventional multiple-daily aminoglycoside dosing.
class ConventionalAminoglycosideResult {
  final NtiDrugType drug;
  final double doseMg;
  final double tauHours;
  final double tInfHours;
  final double peakMgL;
  final double troughMgL;
  final double targetPeakMin;
  final double targetPeakMax;
  final double targetTroughMax;
  final bool isPeakTherapeutic;
  final bool isPeakToxic;
  final bool isPeakSubtherapeutic;
  final bool isTroughSafe;
  final bool isTroughToxic;
  final double? peakToMicRatio;
  final double? micMgL;
  final bool isPeakToMicOptimal;
  final String clinicalGuidance;
  final List<String> warnings;

  const ConventionalAminoglycosideResult({
    required this.drug,
    required this.doseMg,
    required this.tauHours,
    required this.tInfHours,
    required this.peakMgL,
    required this.troughMgL,
    required this.targetPeakMin,
    required this.targetPeakMax,
    required this.targetTroughMax,
    required this.isPeakTherapeutic,
    required this.isPeakToxic,
    required this.isPeakSubtherapeutic,
    required this.isTroughSafe,
    required this.isTroughToxic,
    this.peakToMicRatio,
    this.micMgL,
    this.isPeakToMicOptimal = false,
    required this.clinicalGuidance,
    this.warnings = const [],
  });

  Map<String, dynamic> toMap() => {
        'drug': drug.name,
        'doseMg': doseMg,
        'tauHours': tauHours,
        'tInfHours': tInfHours,
        'peakMgL': peakMgL,
        'troughMgL': troughMgL,
        'targetPeakMin': targetPeakMin,
        'targetPeakMax': targetPeakMax,
        'targetTroughMax': targetTroughMax,
        'isPeakTherapeutic': isPeakTherapeutic,
        'isPeakToxic': isPeakToxic,
        'isPeakSubtherapeutic': isPeakSubtherapeutic,
        'isTroughSafe': isTroughSafe,
        'isTroughToxic': isTroughToxic,
        'peakToMicRatio': peakToMicRatio,
        'micMgL': micMgL,
        'isPeakToMicOptimal': isPeakToMicOptimal,
        'clinicalGuidance': clinicalGuidance,
        'warnings': warnings,
      };

  factory ConventionalAminoglycosideResult.fromMap(
          Map<String, dynamic> map) =>
      ConventionalAminoglycosideResult(
        drug: NtiDrugType.values.byName(map['drug'] as String),
        doseMg: (map['doseMg'] as num).toDouble(),
        tauHours: (map['tauHours'] as num).toDouble(),
        tInfHours: (map['tInfHours'] as num).toDouble(),
        peakMgL: (map['peakMgL'] as num).toDouble(),
        troughMgL: (map['troughMgL'] as num).toDouble(),
        targetPeakMin: (map['targetPeakMin'] as num).toDouble(),
        targetPeakMax: (map['targetPeakMax'] as num).toDouble(),
        targetTroughMax: (map['targetTroughMax'] as num).toDouble(),
        isPeakTherapeutic: map['isPeakTherapeutic'] as bool,
        isPeakToxic: map['isPeakToxic'] as bool,
        isPeakSubtherapeutic: map['isPeakSubtherapeutic'] as bool,
        isTroughSafe: map['isTroughSafe'] as bool,
        isTroughToxic: map['isTroughToxic'] as bool,
        peakToMicRatio: (map['peakToMicRatio'] as num?)?.toDouble(),
        micMgL: (map['micMgL'] as num?)?.toDouble(),
        isPeakToMicOptimal: map['isPeakToMicOptimal'] as bool? ?? false,
        clinicalGuidance: map['clinicalGuidance'] as String,
        warnings: List<String>.from(map['warnings'] as List? ?? const []),
      );

  @override
  String toString() =>
      'ConventionalAminoglycosideResult(drug: ${drug.name}, peak: $peakMgL, trough: $troughMgL, troughSafe: $isTroughSafe)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConventionalAminoglycosideResult &&
          runtimeType == other.runtimeType &&
          drug == other.drug &&
          doseMg == other.doseMg &&
          tauHours == other.tauHours &&
          peakMgL == other.peakMgL &&
          troughMgL == other.troughMgL &&
          isPeakTherapeutic == other.isPeakTherapeutic &&
          isTroughSafe == other.isTroughSafe;

  @override
  int get hashCode => Object.hash(
        drug,
        doseMg,
        tauHours,
        peakMgL,
        troughMgL,
        isPeakTherapeutic,
        isTroughSafe,
      );
}

/// Evaluation result for Phenytoin Michaelis-Menten kinetics and albumin correction.
class PhenytoinDosingResult {
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
  final bool isSubtherapeutic;
  final bool isTherapeutic;
  final double targetCssMin;
  final double targetCssMax;
  final String? toxicityTier;
  final double? ivInfusionRateMgPerMin;
  final bool hasIvRateRisk;
  final String clinicalGuidance;
  final List<String> warningCodes;
  final List<String> warnings;

  const PhenytoinDosingResult({
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
    required this.isSubtherapeutic,
    required this.isTherapeutic,
    this.targetCssMin = 10.0,
    this.targetCssMax = 20.0,
    this.toxicityTier,
    this.ivInfusionRateMgPerMin,
    this.hasIvRateRisk = false,
    required this.clinicalGuidance,
    this.warningCodes = const [],
    this.warnings = const [],
  });

  Map<String, dynamic> toMap() => {
        'orderedDailyDoseMg': orderedDailyDoseMg,
        'predictedCssMgL': predictedCssMgL,
        'observedCssMgL': observedCssMgL,
        'adjustedCssMgL': adjustedCssMgL,
        'vmaxMgPerDay': vmaxMgPerDay,
        'kmMgL': kmMgL,
        'isCapacityExceeded': isCapacityExceeded,
        'isSheinerTozerApplied': isSheinerTozerApplied,
        'isWinterTozerApplied': isWinterTozerApplied,
        'isToxic': isToxic,
        'isSubtherapeutic': isSubtherapeutic,
        'isTherapeutic': isTherapeutic,
        'targetCssMin': targetCssMin,
        'targetCssMax': targetCssMax,
        'toxicityTier': toxicityTier,
        'ivInfusionRateMgPerMin': ivInfusionRateMgPerMin,
        'hasIvRateRisk': hasIvRateRisk,
        'clinicalGuidance': clinicalGuidance,
        'warningCodes': warningCodes,
        'warnings': warnings,
      };

  factory PhenytoinDosingResult.fromMap(Map<String, dynamic> map) =>
      PhenytoinDosingResult(
        orderedDailyDoseMg: (map['orderedDailyDoseMg'] as num).toDouble(),
        predictedCssMgL: (map['predictedCssMgL'] as num?)?.toDouble(),
        observedCssMgL: (map['observedCssMgL'] as num?)?.toDouble(),
        adjustedCssMgL: (map['adjustedCssMgL'] as num?)?.toDouble(),
        vmaxMgPerDay: (map['vmaxMgPerDay'] as num).toDouble(),
        kmMgL: (map['kmMgL'] as num).toDouble(),
        isCapacityExceeded: map['isCapacityExceeded'] as bool,
        isSheinerTozerApplied: map['isSheinerTozerApplied'] as bool,
        isWinterTozerApplied: map['isWinterTozerApplied'] as bool,
        isToxic: map['isToxic'] as bool,
        isSubtherapeutic: map['isSubtherapeutic'] as bool,
        isTherapeutic: map['isTherapeutic'] as bool,
        targetCssMin: (map['targetCssMin'] as num?)?.toDouble() ?? 10.0,
        targetCssMax: (map['targetCssMax'] as num?)?.toDouble() ?? 20.0,
        toxicityTier: map['toxicityTier'] as String?,
        ivInfusionRateMgPerMin:
            (map['ivInfusionRateMgPerMin'] as num?)?.toDouble(),
        hasIvRateRisk: map['hasIvRateRisk'] as bool? ?? false,
        clinicalGuidance: map['clinicalGuidance'] as String,
        warningCodes:
            List<String>.from(map['warningCodes'] as List? ?? const []),
        warnings: List<String>.from(map['warnings'] as List? ?? const []),
      );

  @override
  String toString() =>
      'PhenytoinDosingResult(dose: $orderedDailyDoseMg, predCss: $predictedCssMgL, adjCss: $adjustedCssMgL, toxic: $isToxic, saturated: $isCapacityExceeded)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhenytoinDosingResult &&
          runtimeType == other.runtimeType &&
          orderedDailyDoseMg == other.orderedDailyDoseMg &&
          predictedCssMgL == other.predictedCssMgL &&
          adjustedCssMgL == other.adjustedCssMgL &&
          isCapacityExceeded == other.isCapacityExceeded &&
          isToxic == other.isToxic &&
          isTherapeutic == other.isTherapeutic;

  @override
  int get hashCode => Object.hash(
        orderedDailyDoseMg,
        predictedCssMgL,
        adjustedCssMgL,
        isCapacityExceeded,
        isToxic,
        isTherapeutic,
      );
}

/// NTI electrolyte monitoring and sampling timing guard evaluation result.
class NtiSafetyCheckResult {
  final NtiDrugType drug;
  final double? serumPotassiumMEqL;
  final double? serumMagnesiumMgDl;
  final double? serumCalciumMgDl;
  final double? serumSodiumMEqL;
  final double? hoursPostDoseSampling;
  final bool hasPotassiumRisk;
  final bool hasMagnesiumRisk;
  final bool hasCalciumRisk;
  final bool hasSodiumRisk;
  final bool hasDistributionPhaseWarning;
  final List<String> clinicalWarnings;
  final bool isSafe;

  const NtiSafetyCheckResult({
    required this.drug,
    this.serumPotassiumMEqL,
    this.serumMagnesiumMgDl,
    this.serumCalciumMgDl,
    this.serumSodiumMEqL,
    this.hoursPostDoseSampling,
    required this.hasPotassiumRisk,
    required this.hasMagnesiumRisk,
    required this.hasCalciumRisk,
    required this.hasSodiumRisk,
    required this.hasDistributionPhaseWarning,
    required this.clinicalWarnings,
    required this.isSafe,
  });

  Map<String, dynamic> toMap() => {
        'drug': drug.name,
        'serumPotassiumMEqL': serumPotassiumMEqL,
        'serumMagnesiumMgDl': serumMagnesiumMgDl,
        'serumCalciumMgDl': serumCalciumMgDl,
        'serumSodiumMEqL': serumSodiumMEqL,
        'hoursPostDoseSampling': hoursPostDoseSampling,
        'hasPotassiumRisk': hasPotassiumRisk,
        'hasMagnesiumRisk': hasMagnesiumRisk,
        'hasCalciumRisk': hasCalciumRisk,
        'hasSodiumRisk': hasSodiumRisk,
        'hasDistributionPhaseWarning': hasDistributionPhaseWarning,
        'clinicalWarnings': clinicalWarnings,
        'isSafe': isSafe,
      };

  factory NtiSafetyCheckResult.fromMap(Map<String, dynamic> map) =>
      NtiSafetyCheckResult(
        drug: NtiDrugType.values.byName(map['drug'] as String),
        serumPotassiumMEqL: (map['serumPotassiumMEqL'] as num?)?.toDouble(),
        serumMagnesiumMgDl: (map['serumMagnesiumMgDl'] as num?)?.toDouble(),
        serumCalciumMgDl: (map['serumCalciumMgDl'] as num?)?.toDouble(),
        serumSodiumMEqL: (map['serumSodiumMEqL'] as num?)?.toDouble(),
        hoursPostDoseSampling:
            (map['hoursPostDoseSampling'] as num?)?.toDouble(),
        hasPotassiumRisk: map['hasPotassiumRisk'] as bool,
        hasMagnesiumRisk: map['hasMagnesiumRisk'] as bool,
        hasCalciumRisk: map['hasCalciumRisk'] as bool,
        hasSodiumRisk: map['hasSodiumRisk'] as bool,
        hasDistributionPhaseWarning:
            map['hasDistributionPhaseWarning'] as bool,
        clinicalWarnings:
            List<String>.from(map['clinicalWarnings'] as List? ?? const []),
        isSafe: map['isSafe'] as bool,
      );

  @override
  String toString() =>
      'NtiSafetyCheckResult(drug: ${drug.name}, safe: $isSafe, warnings: ${clinicalWarnings.length})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NtiSafetyCheckResult &&
          runtimeType == other.runtimeType &&
          drug == other.drug &&
          hasPotassiumRisk == other.hasPotassiumRisk &&
          hasMagnesiumRisk == other.hasMagnesiumRisk &&
          hasCalciumRisk == other.hasCalciumRisk &&
          hasSodiumRisk == other.hasSodiumRisk &&
          hasDistributionPhaseWarning == other.hasDistributionPhaseWarning &&
          isSafe == other.isSafe;

  @override
  int get hashCode => Object.hash(
        drug,
        hasPotassiumRisk,
        hasMagnesiumRisk,
        hasCalciumRisk,
        hasSodiumRisk,
        hasDistributionPhaseWarning,
        isSafe,
      );
}

/// Dosing weight selection result for special populations.
class SpecialPopulationWeightResult {
  final double tbwKg;
  final double heightCm;
  final bool isMale;
  final double bmi;
  final double ibwKg;
  final double adjBw04Kg;
  final bool isUnderweight;
  final bool isObese;
  final double selectedWeightKg;
  final String rationale;

  const SpecialPopulationWeightResult({
    required this.tbwKg,
    required this.heightCm,
    required this.isMale,
    required this.bmi,
    required this.ibwKg,
    required this.adjBw04Kg,
    required this.isUnderweight,
    required this.isObese,
    required this.selectedWeightKg,
    required this.rationale,
  });

  Map<String, dynamic> toMap() => {
        'tbwKg': tbwKg,
        'heightCm': heightCm,
        'isMale': isMale,
        'bmi': bmi,
        'ibwKg': ibwKg,
        'adjBw04Kg': adjBw04Kg,
        'isUnderweight': isUnderweight,
        'isObese': isObese,
        'selectedWeightKg': selectedWeightKg,
        'rationale': rationale,
      };

  factory SpecialPopulationWeightResult.fromMap(Map<String, dynamic> map) =>
      SpecialPopulationWeightResult(
        tbwKg: (map['tbwKg'] as num).toDouble(),
        heightCm: (map['heightCm'] as num).toDouble(),
        isMale: map['isMale'] as bool,
        bmi: (map['bmi'] as num).toDouble(),
        ibwKg: (map['ibwKg'] as num).toDouble(),
        adjBw04Kg: (map['adjBw04Kg'] as num).toDouble(),
        isUnderweight: map['isUnderweight'] as bool,
        isObese: map['isObese'] as bool,
        selectedWeightKg: (map['selectedWeightKg'] as num).toDouble(),
        rationale: map['rationale'] as String,
      );

  @override
  String toString() =>
      'SpecialPopulationWeightResult(selected: ${selectedWeightKg}kg, rationale: $rationale)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpecialPopulationWeightResult &&
          runtimeType == other.runtimeType &&
          tbwKg == other.tbwKg &&
          heightCm == other.heightCm &&
          isMale == other.isMale &&
          selectedWeightKg == other.selectedWeightKg;

  @override
  int get hashCode => Object.hash(tbwKg, heightCm, isMale, selectedWeightKg);
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

  Map<String, dynamic> toMap() => {
        'clinicianId': clinicianId,
        'justificationCategory': justificationCategory,
        'clinicalNotes': clinicalNotes,
        'timestamp': timestamp.toIso8601String(),
        'deliveredDose': deliveredDose,
        'rateUnit': rateUnit,
      };

  factory ClinicalOverrideJustification.fromMap(Map<String, dynamic> map) =>
      ClinicalOverrideJustification(
        clinicianId: map['clinicianId'] as String,
        justificationCategory: map['justificationCategory'] as String,
        clinicalNotes: map['clinicalNotes'] as String?,
        timestamp: DateTime.parse(map['timestamp'] as String),
        deliveredDose: (map['deliveredDose'] as num).toDouble(),
        rateUnit: map['rateUnit'] as String,
      );

  @override
  String toString() =>
      'ClinicalOverrideJustification(clinicianId: $clinicianId, category: $justificationCategory, dose: $deliveredDose $rateUnit)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClinicalOverrideJustification &&
          runtimeType == other.runtimeType &&
          clinicianId == other.clinicianId &&
          justificationCategory == other.justificationCategory &&
          deliveredDose == other.deliveredDose &&
          rateUnit == other.rateUnit;

  @override
  int get hashCode => Object.hash(
        clinicianId,
        justificationCategory,
        deliveredDose,
        rateUnit,
      );
}

/// High-alert continuous infusion vasoactive calculation result.
class VasoactiveInfusionResult {
  final VasoactiveDrug drug;
  final String drugId;
  final double orderedDose;
  final String doseUnit;
  final double patientWeightKg;
  final double concentrationMcgPerMl;
  final VasoactiveDilution dilutionType;
  final double pumpRateMlPerHr;
  final double deliveredMcgKgMin;
  final bool isCeilingExceeded;
  final double ceilingThreshold;
  final ClinicalOverrideJustification? overrideJustification;
  final String warningMessage;

  const VasoactiveInfusionResult({
    required this.drug,
    required this.drugId,
    required this.orderedDose,
    required this.doseUnit,
    required this.patientWeightKg,
    required this.concentrationMcgPerMl,
    this.dilutionType = VasoactiveDilution.singleStrength,
    required this.pumpRateMlPerHr,
    required this.deliveredMcgKgMin,
    required this.isCeilingExceeded,
    required this.ceilingThreshold,
    this.overrideJustification,
    required this.warningMessage,
  });

  Map<String, dynamic> toMap() => {
        'drug': drug.name,
        'drugId': drugId,
        'orderedDose': orderedDose,
        'doseUnit': doseUnit,
        'patientWeightKg': patientWeightKg,
        'concentrationMcgPerMl': concentrationMcgPerMl,
        'dilutionType': dilutionType.name,
        'pumpRateMlPerHr': pumpRateMlPerHr,
        'deliveredMcgKgMin': deliveredMcgKgMin,
        'isCeilingExceeded': isCeilingExceeded,
        'ceilingThreshold': ceilingThreshold,
        'overrideJustification': overrideJustification?.toMap(),
        'warningMessage': warningMessage,
      };

  factory VasoactiveInfusionResult.fromMap(Map<String, dynamic> map) =>
      VasoactiveInfusionResult(
        drug: VasoactiveDrug.values.byName(map['drug'] as String),
        drugId: map['drugId'] as String,
        orderedDose: (map['orderedDose'] as num).toDouble(),
        doseUnit: map['doseUnit'] as String,
        patientWeightKg: (map['patientWeightKg'] as num).toDouble(),
        concentrationMcgPerMl:
            (map['concentrationMcgPerMl'] as num).toDouble(),
        dilutionType: VasoactiveDilution.values
            .byName(map['dilutionType'] as String? ?? 'singleStrength'),
        pumpRateMlPerHr: (map['pumpRateMlPerHr'] as num).toDouble(),
        deliveredMcgKgMin: (map['deliveredMcgKgMin'] as num).toDouble(),
        isCeilingExceeded: map['isCeilingExceeded'] as bool,
        ceilingThreshold: (map['ceilingThreshold'] as num).toDouble(),
        overrideJustification: map['overrideJustification'] != null
            ? ClinicalOverrideJustification.fromMap(
                map['overrideJustification'] as Map<String, dynamic>)
            : null,
        warningMessage: map['warningMessage'] as String,
      );

  @override
  String toString() =>
      'VasoactiveInfusionResult(drug: $drugId, rate: ${pumpRateMlPerHr}mL/hr, exceeded: $isCeilingExceeded)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VasoactiveInfusionResult &&
          runtimeType == other.runtimeType &&
          drug == other.drug &&
          orderedDose == other.orderedDose &&
          doseUnit == other.doseUnit &&
          patientWeightKg == other.patientWeightKg &&
          concentrationMcgPerMl == other.concentrationMcgPerMl &&
          pumpRateMlPerHr == other.pumpRateMlPerHr &&
          isCeilingExceeded == other.isCeilingExceeded;

  @override
  int get hashCode => Object.hash(
        drug,
        orderedDose,
        doseUnit,
        patientWeightKg,
        concentrationMcgPerMl,
        pumpRateMlPerHr,
        isCeilingExceeded,
      );
}
