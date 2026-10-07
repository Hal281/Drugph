import 'package:flutter/foundation.dart';
import '../core/models/models.dart';
import 'patient_session.dart';

/// Singleton service to manage the prescription cart.
class PrescriptionCart {
  PrescriptionCart._privateConstructor();
  static final PrescriptionCart _instance =
      PrescriptionCart._privateConstructor();
  static PrescriptionCart get instance => _instance;

  final ValueNotifier<List<Drug>> items = ValueNotifier<List<Drug>>([]);

  void addDrug(Drug drug) {
    if (!items.value.any((d) => d.id == drug.id)) {
      items.value = [...items.value, drug];
    }
  }

  void removeDrug(String drugId) {
    items.value = items.value.where((d) => d.id != drugId).toList();
  }

  void clearCart() {
    items.value = [];
  }

  /// Checks for any overlapping severe interactions, duplications, and allergies.
  /// Returns a list of warning messages.
  List<String> checkInteractions(bool isThai) {
    List<String> warnings = [];
    final currentDrugs = items.value;
    final patient = PatientSession.instance.currentPatient.value;

    // 1. Check patient allergies via clinical AllergyService
    if (patient != null && patient.allergies.isNotEmpty) {
      for (final drug in currentDrugs) {
        final allergyAlerts = AllergyService.evaluateAllergies(
          patientAllergies: patient.allergies,
          drugGenericName: drug.genericName,
          drugId: drug.id,
          drugClass: drug.effectiveDrugClass,
          legacyAllergyClass: drug.allergyClass,
        );
        for (final alert in allergyAlerts) {
          warnings.add(isThai ? alert.messageTh : alert.messageEn);
        }
      }
    }

    // 2. Check therapeutic duplication and drug-drug interactions
    for (int i = 0; i < currentDrugs.length; i++) {
      for (int j = i + 1; j < currentDrugs.length; j++) {
        final d1 = currentDrugs[i];
        final d2 = currentDrugs[j];

        // 2.1 Therapeutic Duplication Check
        final dup = TherapeuticDuplicationService.checkDuplication(d1, d2);
        if (dup != null) {
          warnings.add(isThai ? dup.messageTh : dup.messageEn);
        }

        // 2.2 Peer-Reviewed Clinical Interaction Registry
        final clinicalInters = ClinicalInteractionRegistry.checkInteractions(d1, d2);
        for (final inter in clinicalInters) {
          warnings.add(isThai ? inter.messageTh : inter.messageEn);
        }

        // 2.3 Structured interactions from d1 and d2
        for (final inter in d1.interactions) {
          final matchesId = inter.targetDrugId?.toLowerCase() == d2.id.toLowerCase();
          final matchesClass = inter.targetClass != null && d2.effectiveDrugClass == inter.targetClass;
          if (matchesId || matchesClass) {
            warnings.add(isThai
                ? '${inter.severity.labelTh}: ${d1.genericName} กับ ${d2.genericName} - ${inter.mechanismTh}. ${inter.managementTh}'
                : '${inter.severity.labelEn}: ${d1.genericName} with ${d2.genericName} - ${inter.mechanismEn}. ${inter.managementEn}');
          }
        }

        for (final inter in d2.interactions) {
          final matchesId = inter.targetDrugId?.toLowerCase() == d1.id.toLowerCase();
          final matchesClass = inter.targetClass != null && d1.effectiveDrugClass == inter.targetClass;
          if (matchesId || matchesClass) {
            if (!warnings.any((w) => w.contains(d1.genericName) && w.contains(d2.genericName))) {
              warnings.add(isThai
                  ? '${inter.severity.labelTh}: ${d2.genericName} กับ ${d1.genericName} - ${inter.mechanismTh}. ${inter.managementTh}'
                  : '${inter.severity.labelEn}: ${d2.genericName} with ${d1.genericName} - ${inter.mechanismEn}. ${inter.managementEn}');
            }
          }
        }

        // 2.4 Unstructured contraindications and severeInteractions fallback
        bool d1WarnsAboutD2 = d1.severeInteractions.any((interaction) =>
            interaction.toLowerCase().contains(d2.genericName.toLowerCase()));
        bool d2WarnsAboutD1 = d2.severeInteractions.any((interaction) =>
            interaction.toLowerCase().contains(d1.genericName.toLowerCase()));

        bool d1ContraindicatesD2 = d1.contraindications
            .any((c) => c.toLowerCase().contains(d2.genericName.toLowerCase()));
        bool d2ContraindicatesD1 = d2.contraindications
            .any((c) => c.toLowerCase().contains(d1.genericName.toLowerCase()));

        if (d1ContraindicatesD2 || d2ContraindicatesD1) {
          final msg = isThai
              ? '❌ ข้อห้ามใช้ร้ายแรง: ${d1.genericName} ห้ามใช้ร่วมกับ ${d2.genericName}'
              : '❌ CONTRAINDICATED: ${d1.genericName} and ${d2.genericName}';
          if (!warnings.contains(msg)) warnings.add(msg);
        } else if (d1WarnsAboutD2 || d2WarnsAboutD1) {
          final msg = isThai
              ? '⚠️ ระวังการตีกันของยา: ${d1.genericName} และ ${d2.genericName}'
              : '⚠️ INTERACTION: ${d1.genericName} and ${d2.genericName}';
          if (!warnings.contains(msg)) warnings.add(msg);
        }
      }
    }

    return warnings;
  }
}
