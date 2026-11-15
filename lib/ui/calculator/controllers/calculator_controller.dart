import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../core/core.dart';
import '../../../data/history_service.dart';
import '../../../data/patient_session.dart';
import '../models/calculator_ui_state.dart';

/// Pure Controller (ChangeNotifier) for the Clinical Calculator Dashboard.
///
/// Encapsulates:
/// - Patient session synchronization
/// - Input controllers lifecycle
/// - Deterministic clinical validation via [InputValidator]
/// - Dosage computation via [PharmacistCalculator]
/// - Immutable [CalculatorUiState] mutations
/// - Clinical audit log persistence via [HistoryService]
class CalculatorController extends ChangeNotifier {
  final TextEditingController weightCtrl = TextEditingController();
  final TextEditingController heightCtrl = TextEditingController();
  final TextEditingController ageCtrl = TextEditingController();
  final TextEditingController scrCtrl = TextEditingController();

  CalculatorUiState _state;
  bool _isDisposed = false;
  bool _isSyncingToSession = false;
  bool _isSyncingFromSession = false;
  bool _hasManuallySelectedRegimen = false;

  CalculatorController({required Drug drug})
      : _state = CalculatorUiState.initial(
          drug,
          patientAgeYears:
              PatientSession.instance.currentPatient.value?.ageYears,
          patientWeightKg:
              PatientSession.instance.currentPatient.value?.weightKg,
        ) {
    _syncFromSession();
    PatientSession.instance.currentPatient.addListener(_syncFromSession);
    weightCtrl.addListener(_onDemographicsEdited);
    ageCtrl.addListener(_onDemographicsEdited);
  }

  CalculatorUiState get state => _state;

  void _onDemographicsEdited() {
    if (_isDisposed || _isSyncingFromSession || _hasManuallySelectedRegimen) {
      return;
    }
    final weight = double.tryParse(weightCtrl.text);
    final age = int.tryParse(ageCtrl.text);
    final best = CalculatorUiState.selectBestRegimenForPatient(
      _state.drug,
      ageYears: age,
      weightKg: weight,
      current: _state.selectedRegimen,
    );
    if (best != null && best != _state.selectedRegimen) {
      _state = _state.copyWith(
        selectedRegimen: best,
        selectedLiquidConcentration: best.defaultLiquidConcentration,
        clearLiquidConcentration: best.defaultLiquidConcentration == null,
        clearResult: true,
        status: CalculatorUiStatus.empty,
      );
      notifyListeners();
    }
  }

  void _syncFromSession() {
    if (_isDisposed || _isSyncingToSession) return;
    final p = PatientSession.instance.currentPatient.value;
    if (p == null) {
      if (weightCtrl.text.isEmpty &&
          heightCtrl.text.isEmpty &&
          ageCtrl.text.isEmpty &&
          scrCtrl.text.isEmpty &&
          _state.result == null) {
        return;
      }

      _isSyncingFromSession = true;
      try {
        weightCtrl.clear();
        heightCtrl.clear();
        ageCtrl.clear();
        scrCtrl.clear();
      } finally {
        _isSyncingFromSession = false;
      }
      _state = CalculatorUiState.initial(_state.drug).copyWith(
        selectedRegimen: _state.selectedRegimen,
        selectedLiquidConcentration: _state.selectedLiquidConcentration,
      );
      notifyListeners();
      return;
    }

    final autoRegimen = _hasManuallySelectedRegimen
        ? _state.selectedRegimen
        : CalculatorUiState.selectBestRegimenForPatient(
            _state.drug,
            ageYears: p.ageYears,
            weightKg: p.weightKg,
            current: _state.selectedRegimen,
          );
    final regimenChanged = autoRegimen != _state.selectedRegimen;

    final profileChanged = (_state.lastEvaluatedPatient != null &&
            _state.lastEvaluatedPatient!.id != p.id) ||
        _state.weightKg != p.weightKg ||
        _state.heightCm != p.heightCm ||
        _state.ageYears != p.ageYears ||
        _state.scrMgDl != p.serumCreatinineMgDl ||
        _state.sex != p.sex ||
        _state.isScrStable != p.isScrStable ||
        _state.renalReplacementMode != p.renalReplacementMode ||
        _state.hepaticImpairment !=
            (p.hepaticImpairment ?? ChildPughClass.none);

    _isSyncingFromSession = true;
    try {
      final currentWeight = double.tryParse(weightCtrl.text);
      if (currentWeight != p.weightKg) {
        weightCtrl.text = p.weightKg.toString();
      }

      final currentHeight = double.tryParse(heightCtrl.text);
      if (currentHeight != p.heightCm) {
        heightCtrl.text = p.heightCm.toString();
      }

      final currentAge = int.tryParse(ageCtrl.text);
      if (currentAge != p.ageYears) {
        ageCtrl.text = p.ageYears.toString();
      }

      final currentScr = double.tryParse(scrCtrl.text);
      if (currentScr != p.serumCreatinineMgDl) {
        scrCtrl.text = p.serumCreatinineMgDl?.toString() ?? '';
      }
    } finally {
      _isSyncingFromSession = false;
    }

    _state = _state.copyWith(
      selectedRegimen: autoRegimen,
      selectedLiquidConcentration: regimenChanged
          ? autoRegimen?.defaultLiquidConcentration
          : _state.selectedLiquidConcentration,
      clearLiquidConcentration:
          regimenChanged && autoRegimen?.defaultLiquidConcentration == null,
      weightKg: p.weightKg,
      heightCm: p.heightCm,
      ageYears: p.ageYears,
      scrMgDl: p.serumCreatinineMgDl,
      sex: p.sex,
      isScrStable: p.isScrStable,
      renalReplacementMode: p.renalReplacementMode,
      hepaticImpairment: p.hepaticImpairment ?? ChildPughClass.none,
      usedDefaultDemographics: false,
      clearResult: profileChanged || regimenChanged,
      clearDosingWeight: profileChanged || regimenChanged,
      status: (profileChanged || regimenChanged)
          ? CalculatorUiStatus.empty
          : null,
    );
    notifyListeners();
  }

  /// Outbound sync: CalculatorController -> PatientSession
  void _syncToSessionIfValid() {
    if (_isDisposed || _isSyncingToSession) return;
    final valResult = validateInputs();
    if (!valResult.isValid) return;

    final weight = double.tryParse(weightCtrl.text.trim());
    final height = double.tryParse(heightCtrl.text.trim());
    final age = int.tryParse(ageCtrl.text.trim());
    final scr = double.tryParse(scrCtrl.text.trim());

    final hasExistingSession = PatientSession.instance.currentPatient.value != null;
    final hasAnyEnteredInput =
        weight != null || height != null || age != null || scr != null;
    if (!hasExistingSession && !hasAnyEnteredInput) return;

    _isSyncingToSession = true;
    try {
      PatientSession.instance.updateCurrentPatient(
        weightKg: weight,
        heightCm: height,
        ageYears: age,
        serumCreatinineMgDl: scr,
        sex: _state.sex,
        isScrStable: _state.isScrStable,
        renalReplacementMode: _state.renalReplacementMode,
        hepaticImpairment: _state.hepaticImpairment == ChildPughClass.none
            ? null
            : _state.hepaticImpairment,
      );
    } finally {
      _isSyncingToSession = false;
    }
  }

  /// Selects a dosing regimen and clears previous calculation results.
  void selectRegimen(DosingRegimen? regimen) {
    _hasManuallySelectedRegimen = true;
    _state = _state.copyWith(
      selectedRegimen: regimen,
      clearRegimen: regimen == null,
      selectedLiquidConcentration: regimen?.defaultLiquidConcentration,
      clearLiquidConcentration: regimen?.defaultLiquidConcentration == null,
      clearResult: true,
      status: CalculatorUiStatus.empty,
    );
    notifyListeners();
  }

  /// Selects commercial oral liquid concentration (R1).
  void selectLiquidConcentration(OralLiquidConcentration? concentration) {
    _state = _state.copyWith(
      selectedLiquidConcentration: concentration,
      clearLiquidConcentration: concentration == null,
    );
    notifyListeners();
    // If a calculation result is already displayed, recompute with the new concentration
    if (_state.hasCalculatedResult) {
      calculate(isThai: true);
    }
  }

  /// Sets patient sex.
  void setSex(Sex sex) {
    _state = _state.copyWith(sex: sex);
    notifyListeners();
    _syncToSessionIfValid();
  }

  /// Toggles serum creatinine stability status (AKI vs stable baseline).
  void setScrStable(bool isStable) {
    _state = _state.copyWith(isScrStable: isStable);
    notifyListeners();
    _syncToSessionIfValid();
  }

  /// Updates active Renal Replacement Therapy modality (None, IHD, CAPD, CRRT).
  void setRenalReplacementMode(RenalReplacementMode mode) {
    _state = _state.copyWith(renalReplacementMode: mode);
    notifyListeners();
    _syncToSessionIfValid();
  }

  /// Updates Child-Pugh Hepatic Function status.
  void setHepaticImpairment(ChildPughClass cpClass, {int? score}) {
    _state = _state.copyWith(
      hepaticImpairment: cpClass,
      lastChildPughScore: score,
      clearChildPughScore: score == null,
    );
    notifyListeners();
    _syncToSessionIfValid();
  }

  ({int age, double? height})? _inferredPediatricDemographics({
    required double? weight,
    required double? height,
    required int? age,
  }) {
    if (_state.selectedRegimen?.effectiveAudience != RegimenAudience.pediatric ||
        weight == null ||
        weight <= 0 ||
        weight >= 25.0 ||
        age == null ||
        age < 18 ||
        age > 150) {
      return null;
    }
    final inferredAge = weight <= 15.0 ? 2 : 6;
    final inferredHeight = (height != null && (height - 170.0).abs() < 0.01)
        ? (weight <= 15.0 ? 85.0 : 115.0)
        : height;
    return (age: inferredAge, height: inferredHeight);
  }

  ({double weight, double height, int age}) _resolvePatientDemographics({
    required double? enteredWeight,
    required double? enteredHeight,
    required int? enteredAge,
  }) {
    final age = enteredAge ?? 35;
    if (enteredWeight != null && enteredHeight != null) {
      return (weight: enteredWeight, height: enteredHeight, age: age);
    }
    if (enteredWeight != null) {
      final bmiAt170 = enteredWeight / (1.70 * 1.70);
      final safeHeight = (bmiAt170 >= 12.0 && bmiAt170 <= 50.0)
          ? 170.0
          : ((enteredWeight / 22.0) > 0
              ? (math.sqrt(enteredWeight / 22.0) * 100.0).clamp(45.0, 220.0)
              : 170.0);
      return (weight: enteredWeight, height: safeHeight, age: age);
    }
    if (enteredHeight != null) {
      final heightM = enteredHeight / 100.0;
      final bmiAt70 = heightM > 0 ? 70.0 / (heightM * heightM) : 22.0;
      final safeWeight = (bmiAt70 >= 12.0 && bmiAt70 <= 50.0)
          ? 70.0
          : (22.0 * heightM * heightM).clamp(3.0, 250.0);
      return (weight: safeWeight, height: enteredHeight, age: age);
    }
    return (weight: 70.0, height: 170.0, age: age);
  }

  /// Constructs a [Patient] instance from the current form inputs and active session.
  Patient buildCurrentPatient() {
    final sessionPatient = PatientSession.instance.currentPatient.value;
    final enteredWeight =
        double.tryParse(weightCtrl.text.trim()) ?? sessionPatient?.weightKg;
    final enteredHeight =
        double.tryParse(heightCtrl.text.trim()) ?? sessionPatient?.heightCm;
    final enteredAge =
        int.tryParse(ageCtrl.text.trim()) ?? sessionPatient?.ageYears;
    final scr = double.tryParse(scrCtrl.text.trim()) ??
        sessionPatient?.serumCreatinineMgDl;

    final resolved = _resolvePatientDemographics(
      enteredWeight: enteredWeight,
      enteredHeight: enteredHeight,
      enteredAge: enteredAge,
    );
    var weight = resolved.weight;
    var height = resolved.height;
    var age = resolved.age;

    final inferred = _inferredPediatricDemographics(
      weight: weight,
      height: height,
      age: age,
    );
    if (inferred != null) {
      age = inferred.age;
      height = inferred.height ?? height;
    }

    return Patient(
      id: sessionPatient?.id ??
          'PATIENT-${DateTime.now().millisecondsSinceEpoch}',
      patientName: sessionPatient?.patientName,
      hospitalNumber: sessionPatient?.hospitalNumber,
      weightKg: weight,
      heightCm: height,
      ageYears: age,
      sex: _state.sex,
      serumCreatinineMgDl: scr,
      isScrStable: _state.isScrStable,
      renalReplacementMode: _state.renalReplacementMode,
      allergies: sessionPatient?.allergies ?? const [],
      activeDrugIds: sessionPatient?.activeDrugIds ?? const [],
      isPregnant: sessionPatient?.isPregnant ?? false,
      hepaticImpairment: _state.hepaticImpairment == ChildPughClass.none
          ? null
          : _state.hepaticImpairment,
    );
  }

  /// Validates inputs and returns [ValidationResult].
  ValidationResult validateInputs() {
    final weightText = weightCtrl.text.trim();
    final heightText = heightCtrl.text.trim();
    final ageText = ageCtrl.text.trim();
    final scrText = scrCtrl.text.trim();

    final weight = weightText.isEmpty ? null : double.tryParse(weightText);
    final height = heightText.isEmpty ? null : double.tryParse(heightText);
    final age = ageText.isEmpty ? null : int.tryParse(ageText);
    final scr = scrText.isEmpty ? null : double.tryParse(scrText);

    final reqs = _state.inputRequirements;
    final baseResult = InputValidator.validatePatientInputs(
      weightKg: weight,
      heightCm: height,
      ageYears: age,
      serumCreatinineMgDl: scr,
      requireWeight: reqs.isWeightRequired,
      requireHeight: reqs.isHeightRequired,
      requireAge: reqs.isAgeRequired,
      requireScr: reqs.isScrRequired,
    );

    final errorsEn = Map<String, String>.from(baseResult.errorsEn);
    final errorsTh = Map<String, String>.from(baseResult.errorsTh);

    if (weightText.isNotEmpty && weight == null) {
      errorsEn['weightKg'] = 'Invalid weight format';
      errorsTh['weightKg'] = 'รูปแบบน้ำหนักไม่ถูกต้อง';
    }
    if (heightText.isNotEmpty && height == null) {
      errorsEn['heightCm'] = 'Invalid height format';
      errorsTh['heightCm'] = 'รูปแบบส่วนสูงไม่ถูกต้อง';
    }
    if (ageText.isNotEmpty && age == null) {
      errorsEn['ageYears'] = 'Invalid age format';
      errorsTh['ageYears'] = 'รูปแบบอายุไม่ถูกต้อง';
    }
    if (scrText.isNotEmpty && scr == null) {
      errorsEn['serumCreatinineMgDl'] = 'Invalid serum creatinine format';
      errorsTh['serumCreatinineMgDl'] = 'รูปแบบค่าครีเอตินิน (SCr) ไม่ถูกต้อง';
    }

    return ValidationResult(
      isValid: errorsEn.isEmpty,
      errorsEn: errorsEn,
      errorsTh: errorsTh,
      warningsEn: baseResult.warningsEn,
      warningsTh: baseResult.warningsTh,
    );
  }

  /// Executes pure deterministic dosage calculation via [PharmacistCalculator],
  /// records audit trail log, and transitions UI state.
  ValidationResult calculate({required bool isThai}) {
    if (!_hasManuallySelectedRegimen) {
      final best = CalculatorUiState.selectBestRegimenForPatient(
        _state.drug,
        ageYears: int.tryParse(ageCtrl.text.trim()),
        weightKg: double.tryParse(weightCtrl.text.trim()),
        current: _state.selectedRegimen,
      );
      if (best != null && best != _state.selectedRegimen) {
        _state = _state.copyWith(selectedRegimen: best);
      }
    }

    // Prevent the Default Adult Age Trap: if pediatric regimen + child weight
    // (< 25 kg) with untouched adult age (18–150), align age & default height.
    final inferred = _inferredPediatricDemographics(
      weight: double.tryParse(weightCtrl.text.trim()),
      height: double.tryParse(heightCtrl.text.trim()),
      age: int.tryParse(ageCtrl.text.trim()),
    );
    if (inferred != null) {
      _isSyncingFromSession = true;
      try {
        ageCtrl.text = inferred.age.toString();
        if (inferred.height != null) {
          heightCtrl.text = inferred.height!.toStringAsFixed(0);
        }
      } finally {
        _isSyncingFromSession = false;
      }
    }

    final valResult = validateInputs();

    if (!valResult.isValid) {
      final errEn = valResult.errorsEn.values.join('\n');
      final errTh = valResult.errorsTh.values.join('\n');
      _state = _state.copyWith(
        status: CalculatorUiStatus.error,
        errorMessage: errEn,
        errorMessageTh: errTh,
      );
      notifyListeners();
      return valResult;
    }

    if (_state.selectedRegimen == null) return valResult;

    final enteredWeight = double.tryParse(weightCtrl.text.trim());
    final enteredHeight = double.tryParse(heightCtrl.text.trim());
    final enteredAge = int.tryParse(ageCtrl.text.trim());
    final enteredScr = double.tryParse(scrCtrl.text.trim());

    final resolved = _resolvePatientDemographics(
      enteredWeight: enteredWeight,
      enteredHeight: enteredHeight,
      enteredAge: enteredAge,
    );
    final usedDefaultDemographics =
        enteredWeight == null && enteredHeight == null && enteredAge == null;

    final hasExistingSession = PatientSession.instance.currentPatient.value != null;
    final shouldSyncSession = hasExistingSession ||
        (enteredWeight != null && enteredHeight != null && enteredAge != null);

    // Sync validated parameters back to PatientSession when active or complete
    final Patient patient;
    if (shouldSyncSession) {
      _isSyncingToSession = true;
      try {
        patient = PatientSession.instance.updateCurrentPatient(
          weightKg: resolved.weight,
          heightCm: resolved.height,
          ageYears: resolved.age,
          serumCreatinineMgDl: enteredScr,
          sex: _state.sex,
          isScrStable: _state.isScrStable,
          renalReplacementMode: _state.renalReplacementMode,
          hepaticImpairment: _state.hepaticImpairment == ChildPughClass.none
              ? null
              : _state.hepaticImpairment,
        );
      } finally {
        _isSyncingToSession = false;
      }
    } else {
      patient = Patient(
        id: 'PATIENT-${DateTime.now().millisecondsSinceEpoch}',
        weightKg: resolved.weight,
        heightCm: resolved.height,
        ageYears: resolved.age,
        sex: _state.sex,
        serumCreatinineMgDl: enteredScr,
        isScrStable: _state.isScrStable,
        renalReplacementMode: _state.renalReplacementMode,
        hepaticImpairment: _state.hepaticImpairment == ChildPughClass.none
            ? null
            : _state.hepaticImpairment,
      );
    }

    // Pure deterministic calculation call
    final dosageResult = PharmacistCalculator.calculateDose(
      patient: patient,
      drug: _state.drug,
      regimen: _state.selectedRegimen!,
      liquidConcentration: _state.selectedLiquidConcentration,
    );

    final weightStrategy =
        dosageResult.calculationInputs['weightStrategy'] as String? ?? 'TBW';
    final dosingWeightUsed =
        (dosageResult.calculationInputs['dosingWeightUsedKg'] as num?)
            ?.toDouble();
    final crclWeightStrategy =
        dosageResult.calculationInputs['crclWeightStrategy'] as String?;
    final crclWeightUsed =
        (dosageResult.calculationInputs['crclWeightUsedKg'] as num?)
            ?.toDouble();
    final crclReason = isThai
        ? dosageResult.calculationInputs['crclWeightReasonTh'] as String?
        : dosageResult.calculationInputs['crclWeightReasonEn'] as String?;

    final useRenalWeightForDisplay =
        _state.selectedRegimen!.dosingWeightStrategy ==
                DosingWeightStrategy.actual &&
            crclWeightStrategy != null &&
            crclWeightUsed != null;

    final reqs = _state.inputRequirements;
    final showDosingWeight = enteredWeight != null ||
        reqs.isWeightRequired ||
        (useRenalWeightForDisplay && dosageResult.crclMlMin != null);

    final String? displayWeightLabel;
    final double? displayWeightValue;
    final String? displayWeightReason;
    if (showDosingWeight) {
      displayWeightLabel =
          useRenalWeightForDisplay ? crclWeightStrategy : weightStrategy;
      displayWeightValue = useRenalWeightForDisplay
          ? crclWeightUsed
          : (dosingWeightUsed ?? resolved.weight);
      displayWeightReason = useRenalWeightForDisplay && crclReason != null
          ? crclReason
          : (isThai
              ? 'ใช้ $displayWeightLabel ในการคำนวณขนาดยาตามเกณฑ์คลินิก'
              : 'Using $displayWeightLabel for clinical regimen dosing calculation');
    } else {
      displayWeightLabel = null;
      displayWeightValue = null;
      displayWeightReason = null;
    }

    // Determine status (Active vs Warning/Overdose)
    final hasOverdose = dosageResult.warnings.any(
      (w) => const {
        DoseWarningCode.maxSingleDoseExceeded,
        DoseWarningCode.softMaxSingleDoseExceeded,
        DoseWarningCode.maxDailyDoseExceeded,
        DoseWarningCode.maxDosePerKgPerDayExceeded,
        DoseWarningCode.maxInfusionRateExceeded,
        DoseWarningCode.doseCappedAtMax,
      }.contains(w.code),
    );

    final status = hasOverdose || dosageResult.hasHardLimitViolation
        ? CalculatorUiStatus.warning
        : CalculatorUiStatus.active;

    _state = _state.copyWith(
      clearDemographics: true,
      weightKg: showDosingWeight ? (enteredWeight ?? resolved.weight) : enteredWeight,
      heightCm: showDosingWeight ? (enteredHeight ?? resolved.height) : enteredHeight,
      ageYears: showDosingWeight ? (enteredAge ?? resolved.age) : enteredAge,
      scrMgDl: enteredScr,
      lastEvaluatedPatient: patient,
      usedDefaultDemographics: usedDefaultDemographics,
      warnings: dosageResult.warnings,
      result: dosageResult,
      clearDosingWeight: !showDosingWeight,
      dosingWeightLabel: displayWeightLabel,
      dosingWeightValue: displayWeightValue,
      dosingWeightReason: displayWeightReason,
      status: status,
    );
    notifyListeners();

    // Persist to CalculationLog History (safer with real UUID)
    final log = CalculationLog(
      logId: const Uuid().v4(),
      timestamp: DateTime.now(),
      userId: PatientSession.instance.currentUserId,
      patientId: patient.id,
      drugName: _state.drug.genericName,
      drugId: _state.drug.id,
      route: _state.selectedRegimen!.route.abbreviation,
      indication: _state.selectedRegimen!.indication,
      inputs: dosageResult.calculationInputs,
      result: dosageResult,
      formulaUsed: dosageResult.formulaUsed,
      softwareVersion: '0.1.0-prototype',
    );
    HistoryService().addLog(log);

    return valResult;
  }

  /// Formats HIS order payload text.
  String formatHisOrder(bool isThai) {
    final p = _state.lastEvaluatedPatient ?? buildCurrentPatient();
    return ClinicalOrderFormatter.formatHisOrder(
      patient: p,
      drug: _state.drug,
      regimen: _state.selectedRegimen!,
      result: _state.result!,
      isThai: isThai,
    );
  }

  /// Formats Pharmacist clinical progress note text.
  String formatPharmacistNote(bool isThai) {
    final p = _state.lastEvaluatedPatient ?? buildCurrentPatient();
    return ClinicalOrderFormatter.formatPharmacistNote(
      patient: p,
      drug: _state.drug,
      regimen: _state.selectedRegimen!,
      result: _state.result!,
      isThai: isThai,
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    PatientSession.instance.currentPatient.removeListener(_syncFromSession);
    weightCtrl.removeListener(_onDemographicsEdited);
    ageCtrl.removeListener(_onDemographicsEdited);
    weightCtrl.dispose();
    heightCtrl.dispose();
    ageCtrl.dispose();
    scrCtrl.dispose();
    super.dispose();
  }
}
