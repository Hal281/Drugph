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
  final CalculatorUiStatus status;
  final String? errorMessage;
  final String? errorMessageTh;

  const CalculatorUiState({
    required this.drug,
    this.selectedRegimen,
    this.weightKg,
    this.heightCm,
    this.ageYears,
    this.scrMgDl,
    this.sex = Sex.male,
    this.isScrStable = true,
    this.renalReplacementMode = RenalReplacementMode.none,
    this.hepaticImpairment = ChildPughClass.none,
    this.lastChildPughScore,
    this.result,
    this.warnings = const [],
    this.dosingWeightLabel,
    this.dosingWeightValue,
    this.dosingWeightReason,
    this.lastEvaluatedPatient,
    this.status = CalculatorUiStatus.empty,
    this.errorMessage,
    this.errorMessageTh,
  });

  /// Initial factory for a given drug.
  factory CalculatorUiState.initial(Drug drug) {
    return CalculatorUiState(
      drug: drug,
      selectedRegimen: drug.regimens.isNotEmpty ? drug.regimens.first : null,
      sex: Sex.male,
      isScrStable: true,
      renalReplacementMode: RenalReplacementMode.none,
      hepaticImpairment: ChildPughClass.none,
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
    double? weightKg,
    double? heightCm,
    int? ageYears,
    double? scrMgDl,
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
    CalculatorUiStatus? status,
    String? errorMessage,
    String? errorMessageTh,
  }) {
    return CalculatorUiState(
      drug: drug ?? this.drug,
      selectedRegimen:
          clearRegimen ? null : (selectedRegimen ?? this.selectedRegimen),
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      ageYears: ageYears ?? this.ageYears,
      scrMgDl: scrMgDl ?? this.scrMgDl,
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
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      errorMessageTh: errorMessageTh ?? this.errorMessageTh,
    );
  }
}
