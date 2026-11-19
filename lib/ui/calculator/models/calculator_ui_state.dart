import '../../../core/core.dart';

/// 4 Explicit UI states for the Clinical Calculator Dashboard.
enum CalculatorUiStatus {
  /// Initial guidance state prompt (e.g. before initial calculation or patient input).
  empty,

  /// Shimmer / skeleton state during calculations or data fetching.
  loading,

  /// Active state with live mathematical calculation results.
  active,

  /// Clinical caution or non-blocking overdose warning state.
  warning,

  /// Critical validation failure or blocking contraindication state.
  error,
}

/// Immutable UI State model for the Clinical Calculator Dashboard.
class CalculatorUiState {
  final Drug drug;
  final DosingRegimen? selectedRegimen;
  final OralLiquidConcentration? selectedLiquidConcentration;
  final double? weightKg;
  final double? heightCm;
  final int? ageYears;
  final double? scrMgDl;
  final Sex sex;
  final bool isScrStable;
  final RenalReplacementMode renalReplacementMode;
  final ChildPughClass hepaticImpairment;
  final int? lastChildPughScore;
  final DosageResult? result;
  final List<DoseWarning> warnings;
  final String? dosingWeightLabel;
  final double? dosingWeightValue;
  final String? dosingWeightReason;
  final Patient? lastEvaluatedPatient;
  final bool usedDefaultDemographics;
  final CalculatorUiStatus status;
  final String? errorMessage;
  final String? errorMessageTh;

  const CalculatorUiState({
    required this.drug,
    this.selectedRegimen,
    this.selectedLiquidConcentration,
    this.weightKg,
    this.heightCm,
    this.ageYears,
    this.scrMgDl,
    this.sex = Sex.male,
    this.isScrStable = true,
    this.renalReplacementMode = RenalReplacementMode.none,
    this.hepaticImpairment = ChildPughClass.notAssessed,
    this.lastChildPughScore,
    this.result,
    this.warnings = const [],
    this.dosingWeightLabel,
    this.dosingWeightValue,
    this.dosingWeightReason,
    this.lastEvaluatedPatient,
    this.usedDefaultDemographics = false,
    this.status = CalculatorUiStatus.empty,
    this.errorMessage,
    this.errorMessageTh,
  });

  /// Selects the most clinically appropriate [DosingRegimen] for a patient's
  /// demographic profile (pediatric vs adult) when regimens exist for both.
  ///
  /// Pediatric criteria match Step 3: age < 18 years OR weight in (0, 25) kg.
  static DosingRegimen? selectBestRegimenForPatient(
    Drug drug, {
    int? ageYears,
    double? weightKg,
    DosingRegimen? current,
  }) {
    if (drug.regimens.isEmpty) return null;
    final fallback = current ?? drug.regimens.first;
    final isPediatric = (ageYears != null && ageYears < 18) ||
        (weightKg != null && weightKg > 0 && weightKg < 25.0);

    if (isPediatric) {
      if (fallback.effectiveAudience == RegimenAudience.pediatric) {
        return fallback;
      }
      return drug.regimens.cast<DosingRegimen?>().firstWhere(
            (r) => r?.effectiveAudience == RegimenAudience.pediatric,
            orElse: () => fallback,
          );
    }

    if (ageYears != null && ageYears >= 18) {
      if (fallback.effectiveAudience == RegimenAudience.adult) {
        return fallback;
      }
      return drug.regimens.cast<DosingRegimen?>().firstWhere(
            (r) => r?.effectiveAudience == RegimenAudience.adult,
            orElse: () => fallback,
          );
    }

    return fallback;
  }

  /// Initial factory for a given drug.
  factory CalculatorUiState.initial(
    Drug drug, {
    int? patientAgeYears,
    double? patientWeightKg,
  }) {
    final selectedRegimen = selectBestRegimenForPatient(
      drug,
      ageYears: patientAgeYears,
      weightKg: patientWeightKg,
    );
    return CalculatorUiState(
      drug: drug,
      selectedRegimen: selectedRegimen,
      selectedLiquidConcentration: selectedRegimen?.defaultLiquidConcentration,
      sex: Sex.male,
      isScrStable: true,
      renalReplacementMode: RenalReplacementMode.none,
      hepaticImpairment: ChildPughClass.notAssessed,
      status: CalculatorUiStatus.empty,
    );
  }

  /// Whether a dose calculation result is available.
  bool get hasCalculatedResult => result != null;

  /// Whether calculation triggered an overdose warning (Rule 5: Non-blocking overdose policy).
  bool get isOverdose => warnings.any(
        (w) => const {
          DoseWarningCode.maxSingleDoseExceeded,
          DoseWarningCode.softMaxSingleDoseExceeded,
          DoseWarningCode.maxDailyDoseExceeded,
          DoseWarningCode.maxDosePerKgPerDayExceeded,
          DoseWarningCode.maxInfusionRateExceeded,
          DoseWarningCode.doseCappedAtMax,
        }.contains(w.code),
      );

  /// Whether a hard safety violation or critical contraindication is flagged.
  bool get hasCriticalAlert =>
      (result?.hasHardLimitViolation ?? false) ||
      (result?.hasHardWarning ?? false);

  /// Whether any warning is hard severity.
  bool get hasHardWarnings =>
      warnings.any((w) => w.severity == LimitSeverity.hard);

  /// Whether any warning is soft severity.
  bool get hasSoftWarnings =>
      warnings.any((w) => w.severity == LimitSeverity.soft);

  /// Clinical input requirements for the currently selected drug and regimen.
  RegimenInputRequirements get inputRequirements =>
      drug.inputRequirementsFor(selectedRegimen, renalReplacementMode);

  /// Whether IV diluent compatibility card should be displayed.
  bool get shouldShowIvDiluentCard {
    final reg = selectedRegimen;
    if (reg == null) return false;
    final isIv = reg.route == DoseRoute.iv ||
        reg.route == DoseRoute.ivPush ||
        reg.route == DoseRoute.ivInfusion;
    return isIv && reg.effectiveIvDiluentCompatibility(drug) != null;
  }

  CalculatorUiState copyWith({
    Drug? drug,
    DosingRegimen? selectedRegimen,
    bool clearRegimen = false,
    OralLiquidConcentration? selectedLiquidConcentration,
    bool clearLiquidConcentration = false,
    double? weightKg,
    double? heightCm,
    int? ageYears,
    double? scrMgDl,
    bool clearDemographics = false,
    Sex? sex,
    bool? isScrStable,
    RenalReplacementMode? renalReplacementMode,
    ChildPughClass? hepaticImpairment,
    int? lastChildPughScore,
    bool clearChildPughScore = false,
    DosageResult? result,
    bool clearResult = false,
    List<DoseWarning>? warnings,
    String? dosingWeightLabel,
    double? dosingWeightValue,
    String? dosingWeightReason,
    bool clearDosingWeight = false,
    Patient? lastEvaluatedPatient,
    bool? usedDefaultDemographics,
    CalculatorUiStatus? status,
    String? errorMessage,
    String? errorMessageTh,
  }) {
    return CalculatorUiState(
      drug: drug ?? this.drug,
      selectedRegimen:
          clearRegimen ? null : (selectedRegimen ?? this.selectedRegimen),
      selectedLiquidConcentration: clearLiquidConcentration
          ? null
          : (selectedLiquidConcentration ?? this.selectedLiquidConcentration),
      weightKg: clearDemographics ? weightKg : (weightKg ?? this.weightKg),
      heightCm: clearDemographics ? heightCm : (heightCm ?? this.heightCm),
      ageYears: clearDemographics ? ageYears : (ageYears ?? this.ageYears),
      scrMgDl: clearDemographics ? scrMgDl : (scrMgDl ?? this.scrMgDl),
      sex: sex ?? this.sex,
      isScrStable: isScrStable ?? this.isScrStable,
      renalReplacementMode:
          renalReplacementMode ?? this.renalReplacementMode,
      hepaticImpairment: hepaticImpairment ?? this.hepaticImpairment,
      lastChildPughScore: clearChildPughScore
          ? null
          : (lastChildPughScore ?? this.lastChildPughScore),
      result: clearResult ? null : (result ?? this.result),
      warnings: warnings ?? this.warnings,
      dosingWeightLabel: clearDosingWeight
          ? null
          : (dosingWeightLabel ?? this.dosingWeightLabel),
      dosingWeightValue: clearDosingWeight
          ? null
          : (dosingWeightValue ?? this.dosingWeightValue),
      dosingWeightReason: clearDosingWeight
          ? null
          : (dosingWeightReason ?? this.dosingWeightReason),
      lastEvaluatedPatient: lastEvaluatedPatient ?? this.lastEvaluatedPatient,
      usedDefaultDemographics:
          usedDefaultDemographics ?? this.usedDefaultDemographics,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      errorMessageTh: errorMessageTh ?? this.errorMessageTh,
    );
  }
}
