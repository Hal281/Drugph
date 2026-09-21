import 'package:flutter/foundation.dart';

import '../core/models/patient.dart';

/// Singleton service to manage the current active patient session and ward list.
class PatientSession {
  PatientSession._privateConstructor();
  static final PatientSession _instance = PatientSession._privateConstructor();
  static PatientSession get instance => _instance;

  /// The active patient globally across the app.
  final ValueNotifier<Patient?> currentPatient = ValueNotifier<Patient?>(null);

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
