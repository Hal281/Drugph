import 'package:flutter/foundation.dart';

import '../core/models/patient.dart';
import '../core/models/population_criteria.dart';
import '../core/models/renal_replacement_mode.dart';
import '../core/models/unit.dart';

/// Singleton service to manage the current active patient session and ward list.
class PatientSession {
  PatientSession._privateConstructor();
  static final PatientSession _instance = PatientSession._privateConstructor();
  static PatientSession get instance => _instance;

  /// The active patient globally across the app.
  final ValueNotifier<Patient?> currentPatient = ValueNotifier<Patient?>(null);

  /// Current clinician user ID (D0).
  String currentUserId = 'RPH-042';

  /// Sets the active clinician ID.
  void setUserId(String id) {
    currentUserId = id;
  }

  /// The list of saved patients (Ward List).
  final ValueNotifier<List<Patient>> wardPatients =
      ValueNotifier<List<Patient>>([]);

  /// Updates the active patient and notifies listeners.
  void setPatient(Patient? patient) {
    currentPatient.value = patient;
  }

  /// Clears the active patient.
  void clearPatient() {
    currentPatient.value = null;
  }

  /// Updates the active patient's clinical parameters and persists changes
  /// to the Ward List. If no patient is currently active, a new [Patient]
  /// instance is initialized with safe clinical defaults.
  ///
  /// Notifies all listeners of [currentPatient] and [wardPatients].
  Patient updateCurrentPatient({
    double? weightKg,
    double? heightCm,
    int? ageYears,
    int? ageMonths,
    Sex? sex,
    double? serumCreatinineMgDl,
    double? creatinineClearanceMlMin,
    double? eGfrMlMinPer173m2,
    bool? isScrStable,
    RenalReplacementMode? renalReplacementMode,
    ChildPughClass? hepaticImpairment,
    List<String>? activeDrugIds,
    List<String>? allergies,
    bool? isPregnant,
    String? patientName,
    String? hospitalNumber,
  }) {
    final existing = currentPatient.value;
    final Patient updated;

    if (existing != null) {
      updated = existing.copyWith(
        weightKg: weightKg,
        heightCm: heightCm,
        ageYears: ageYears,
        ageMonths: ageMonths,
        sex: sex,
        serumCreatinineMgDl: serumCreatinineMgDl,
        creatinineClearanceMlMin: creatinineClearanceMlMin,
        eGfrMlMinPer173m2: eGfrMlMinPer173m2,
        isScrStable: isScrStable,
        renalReplacementMode: renalReplacementMode,
        hepaticImpairment: hepaticImpairment,
        activeDrugIds: activeDrugIds,
        allergies: allergies,
        isPregnant: isPregnant,
        patientName: patientName,
        hospitalNumber: hospitalNumber,
      );
    } else {
      updated = Patient(
        id: 'PATIENT-${DateTime.now().millisecondsSinceEpoch}',
        patientName: patientName,
        hospitalNumber: hospitalNumber,
        weightKg: weightKg ?? 70.0,
        heightCm: heightCm ?? 170.0,
        ageYears: ageYears ?? 35,
        ageMonths: ageMonths,
        sex: sex ?? Sex.male,
        serumCreatinineMgDl: serumCreatinineMgDl,
        creatinineClearanceMlMin: creatinineClearanceMlMin,
        eGfrMlMinPer173m2: eGfrMlMinPer173m2,
        isScrStable: isScrStable ?? true,
        renalReplacementMode: renalReplacementMode ?? RenalReplacementMode.none,
        hepaticImpairment: hepaticImpairment,
        activeDrugIds: activeDrugIds ?? const [],
        allergies: allergies ?? const [],
        isPregnant: isPregnant ?? false,
      );
    }

    savePatient(updated, setAsCurrent: true);
    return updated;
  }

  /// Saves or updates a patient in the Ward List.
  /// If [setAsCurrent] is true, it also sets this patient as active.
  void savePatient(Patient patient, {bool setAsCurrent = false}) {
    final list = List<Patient>.from(wardPatients.value);
    final index = list.indexWhere((p) => p.id == patient.id);
    if (index >= 0) {
      list[index] = patient;
    } else {
      list.add(patient);
    }
    wardPatients.value = list;

    if (setAsCurrent || currentPatient.value?.id == patient.id) {
      setPatient(patient);
    }
  }

  /// Removes a patient from the Ward List by ID.
  void removePatient(String id) {
    final list = List<Patient>.from(wardPatients.value);
    list.removeWhere((p) => p.id == id);
    wardPatients.value = list;

    if (currentPatient.value?.id == id) {
      clearPatient();
    }
  }
}
