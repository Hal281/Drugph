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

  CalculatorController({required Drug drug})
      : _state = CalculatorUiState.initial(drug) {
    _syncFromSession();
    PatientSession.instance.currentPatient.addListener(_syncFromSession);
  }

  CalculatorUiState get state => _state;

  void _syncFromSession() {
    if (_isDisposed || _isSyncingToSession) return;
    final p = PatientSession.instance.currentPatient.value;
    if (p != null) {
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

      _state = _state.copyWith(
        weightKg: p.weightKg,
        heightCm: p.heightCm,
        ageYears: p.ageYears,
        scrMgDl: p.serumCreatinineMgDl,
        sex: p.sex,
        renalReplacementMode: p.renalReplacementMode,
        hepaticImpairment: p.hepaticImpairment ?? ChildPughClass.none,
      );
      notifyListeners();
    }
  }

  /// Outbound sync: CalculatorController -> PatientSession
  void _syncToSessionIfValid() {
    if (_isDisposed || _isSyncingToSession) return;
    final valResult = validateInputs();
    if (!valResult.isValid) return;

    final weight = double.tryParse(weightCtrl.text);
    final height = double.tryParse(heightCtrl.text);
    final age = int.tryParse(ageCtrl.text);
    final scr = double.tryParse(scrCtrl.text);

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
    _state = _state.copyWith(
      selectedRegimen: regimen,
      clearRegimen: regimen == null,
      clearResult: true,
      status: CalculatorUiStatus.empty,
    );
    notifyListeners();
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

  /// Constructs a [Patient] instance from the current form inputs and active session.
  Patient buildCurrentPatient() {
    final sessionPatient = PatientSession.instance.currentPatient.value;
    final weight =
        double.tryParse(weightCtrl.text) ?? sessionPatient?.weightKg ?? 70.0;
    final height =
        double.tryParse(heightCtrl.text) ?? sessionPatient?.heightCm ?? 170.0;
    final age = int.tryParse(ageCtrl.text) ?? sessionPatient?.ageYears ?? 35;
    final scr =
        double.tryParse(scrCtrl.text) ?? sessionPatient?.serumCreatinineMgDl;

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
    final weight = double.tryParse(weightCtrl.text);
    final height = double.tryParse(heightCtrl.text);
    final age = int.tryParse(ageCtrl.text);
    final scr = double.tryParse(scrCtrl.text);

    return InputValidator.validatePatientInputs(
      weightKg: weight,
      heightCm: height,
      ageYears: age,
      serumCreatinineMgDl: scr,
    );
  }

  /// Executes pure deterministic dosage calculation via [PharmacistCalculator],
  /// records audit trail log, and transitions UI state.
  ValidationResult calculate({required bool isThai}) {
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

    final weight = double.tryParse(weightCtrl.text)!;
    final height = double.tryParse(heightCtrl.text)!;
    final age = int.tryParse(ageCtrl.text)!;
    final scr = double.tryParse(scrCtrl.text);

    // Sync validated parameters back to PatientSession
    _isSyncingToSession = true;
    final Patient patient;
    try {
      patient = PatientSession.instance.updateCurrentPatient(
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

    // Pure deterministic calculation call
    final dosageResult = PharmacistCalculator.calculateDose(
      patient: patient,
      drug: _state.drug,
      regimen: _state.selectedRegimen!,
    );

    final weightStrategy =
        dosageResult.calculationInputs['weightStrategy'] as String? ?? 'TBW';
    final dosingWeightUsed =
        dosageResult.calculationInputs['dosingWeightUsedKg'] as double?;

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
      lastEvaluatedPatient: patient,
      warnings: dosageResult.warnings,
      result: dosageResult,
      dosingWeightLabel: weightStrategy,
      dosingWeightValue: dosingWeightUsed ?? weight,
      dosingWeightReason: 'ใช้ $weightStrategy ในการคำนวณตามเกณฑ์คลินิก',
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
    weightCtrl.dispose();
    heightCtrl.dispose();
    ageCtrl.dispose();
    scrCtrl.dispose();
    super.dispose();
  }
}
