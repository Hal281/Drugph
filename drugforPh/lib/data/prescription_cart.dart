import 'package:flutter/foundation.dart';
import '../core/models/drug.dart';

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

  /// Checks for any overlapping severe interactions between drugs in the cart.
  /// Returns a list of warning messages.
  List<String> checkInteractions(bool isThai) {
    List<String> warnings = [];
    final currentDrugs = items.value;

    for (int i = 0; i < currentDrugs.length; i++) {
      for (int j = i + 1; j < currentDrugs.length; j++) {
        final d1 = currentDrugs[i];
        final d2 = currentDrugs[j];

        // Simple string matching for prototype purposes
        // In a real app, this would check against a formal DDI database or ontology (like RxNorm or SNOMED).

        bool d1WarnsAboutD2 = d1.severeInteractions.any((interaction) =>
            interaction.toLowerCase().contains(d2.genericName.toLowerCase()));
        bool d2WarnsAboutD1 = d2.severeInteractions.any((interaction) =>
            interaction.toLowerCase().contains(d1.genericName.toLowerCase()));

        bool d1ContraindicatesD2 = d1.contraindications
            .any((c) => c.toLowerCase().contains(d2.genericName.toLowerCase()));
        bool d2ContraindicatesD1 = d2.contraindications
            .any((c) => c.toLowerCase().contains(d1.genericName.toLowerCase()));

        if (d1ContraindicatesD2 || d2ContraindicatesD1) {
          warnings.add(isThai
              ? '❌ ข้อห้ามใช้ร้ายแรง: ${d1.genericName} ห้ามใช้ร่วมกับ ${d2.genericName}'
              : '❌ CONTRAINDICATED: ${d1.genericName} and ${d2.genericName}');
        } else if (d1WarnsAboutD2 || d2WarnsAboutD1) {
          warnings.add(isThai
              ? '⚠️ ระวังการตีกันของยา: ${d1.genericName} และ ${d2.genericName}'
              : '⚠️ INTERACTION: ${d1.genericName} and ${d2.genericName}');
        }
      }
    }

    return warnings;
  }
}
