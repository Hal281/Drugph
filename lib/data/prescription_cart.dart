import 'package:flutter/foundation.dart';
import '../core/models/models.dart';
import 'patient_session.dart';

/// Semantic classification for clinical cart safety alerts.
enum CartAlertCategory {
  allergy,
  therapeuticDuplication,
  ddi,
}

/// Structured, practice-frequency-ranked safety alert for [PrescriptionCartScreen].
class CartAlertItem {
  final CartAlertCategory category;
  final InteractionSeverity severity;
  final InteractionFrequency frequency;
  final String messageEn;
  final String messageTh;
  final String? source;
  final String pairKey;

  const CartAlertItem({
    required this.category,
    required this.severity,
    required this.frequency,
    required this.messageEn,
    required this.messageTh,
    this.source,
    required this.pairKey,
  });

  String localizedMessage(bool isThai) => isThai ? messageTh : messageEn;
}

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

  /// Evaluates allergies, therapeutic duplications, and drug-drug interactions,
  /// returning prioritized [CartAlertItem] entries:
  /// 1. Patient allergies & therapeutic duplications
  /// 2. Common in-practice DDIs (sorted by severity descending)
  /// 3. Less-common / special-population DDIs (collapsible in UI)
  List<CartAlertItem> evaluateAlerts() {
    final alerts = <CartAlertItem>[];
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
          alerts.add(CartAlertItem(
            category: CartAlertCategory.allergy,
            severity: _severityFromLimit(alert.severity, isContraindicated: alert.hasDirectMatch),
            frequency: InteractionFrequency.common,
            messageEn: alert.messageEn,
            messageTh: alert.messageTh,
            source: 'Patient Allergy Profile / AllergyService',
            pairKey: 'allergy::${drug.id.toLowerCase()}::${alert.allergen.toLowerCase()}',
          ));
        }
      }
    }

    final seenStructuredDdiKeys = <String>{};

    // 2. Check therapeutic duplication and drug-drug interactions
    for (int i = 0; i < currentDrugs.length; i++) {
      for (int j = i + 1; j < currentDrugs.length; j++) {
        final d1 = currentDrugs[i];
        final d2 = currentDrugs[j];

        final ids = [d1.id.toLowerCase(), d2.id.toLowerCase()]..sort();
        final pairKey = '${ids[0]}::${ids[1]}';
        var hasStructuredDdiForPair = false;

        // 2.1 Therapeutic Duplication Check
        final dup = TherapeuticDuplicationService.checkDuplication(d1, d2);
        if (dup != null) {
          alerts.add(CartAlertItem(
            category: CartAlertCategory.therapeuticDuplication,
            severity: InteractionSeverity.contraindicated,
            frequency: InteractionFrequency.common,
            messageEn: dup.messageEn,
            messageTh: dup.messageTh,
            source: 'Lexicomp / ONTARGET / KDIGO Duplication Guardrail',
            pairKey: 'dup::$pairKey',
          ));
        }

        // 2.2 Peer-Reviewed Clinical Interaction Registry
        final clinicalInters = ClinicalInteractionRegistry.checkInteractions(d1, d2);
        for (final inter in clinicalInters) {
          hasStructuredDdiForPair = true;
          final key = 'ddi::$pairKey';
          if (seenStructuredDdiKeys.add(key)) {
            final isContra =
                inter.messageEn.toLowerCase().startsWith('contraindicated');
            alerts.add(CartAlertItem(
              category: CartAlertCategory.ddi,
              severity: _severityFromLimit(inter.severity, isContraindicated: isContra),
              frequency: InteractionFrequency.common,
              messageEn: inter.messageEn,
              messageTh: inter.messageTh,
              source:
                  'Lexicomp Drug Information Handbook (APhA) / Sanford Guide / ACC-AHA',
              pairKey: key,
            ));
          }
        }

        // 2.3 Structured interactions from d1 and d2
        for (final pair in [(d1, d2), (d2, d1)]) {
          final sourceDrug = pair.$1;
          final targetDrug = pair.$2;
          for (final inter in sourceDrug.interactions) {
            final matchesId =
                inter.targetDrugId?.toLowerCase() == targetDrug.id.toLowerCase();
            final matchesClass =
                inter.targetClass != null && targetDrug.effectiveDrugClass == inter.targetClass;
            if (matchesId || matchesClass) {
              hasStructuredDdiForPair = true;
              final key = 'ddi::$pairKey';
              if (seenStructuredDdiKeys.add(key)) {
                alerts.add(CartAlertItem(
                  category: CartAlertCategory.ddi,
                  severity: inter.severity,
                  frequency: inter.frequency,
                  messageEn:
                      '${inter.severity.labelEn}: ${sourceDrug.genericName} with ${targetDrug.genericName} - ${inter.mechanismEn} ${inter.managementEn}',
                  messageTh:
                      '${inter.severity.labelTh}: ${sourceDrug.genericName} กับ ${targetDrug.genericName} - ${inter.mechanismTh} ${inter.managementTh}',
                  source: inter.source,
                  pairKey: key,
                ));
              }
            }
          }
        }

        // 2.4 Unstructured contraindications and severeInteractions fallback
        // Only evaluated when no structured DDI already matched this pair.
        if (!hasStructuredDdiForPair) {
          final d1NameLower = d1.genericName.toLowerCase();
          final d1IdLower = d1.id.toLowerCase();
          final d2NameLower = d2.genericName.toLowerCase();
          final d2IdLower = d2.id.toLowerCase();

          final d1WarnsAboutD2 = d1.severeInteractions.any((interaction) {
            final s = interaction.toLowerCase();
            return s.contains(d2NameLower) || s.contains(d2IdLower);
          });
          final d2WarnsAboutD1 = d2.severeInteractions.any((interaction) {
            final s = interaction.toLowerCase();
            return s.contains(d1NameLower) || s.contains(d1IdLower);
          });

          final d1ContraindicatesD2 = d1.contraindications.any((c) {
            final s = c.toLowerCase();
            return s.contains(d2NameLower) || s.contains(d2IdLower);
          });
          final d2ContraindicatesD1 = d2.contraindications.any((c) {
            final s = c.toLowerCase();
            return s.contains(d1NameLower) || s.contains(d1IdLower);
          });

          if (d1ContraindicatesD2 || d2ContraindicatesD1) {
            alerts.add(CartAlertItem(
              category: CartAlertCategory.ddi,
              severity: InteractionSeverity.contraindicated,
              frequency: InteractionFrequency.common,
              messageEn:
                  'Contraindicated combination: ${d1.genericName} and ${d2.genericName}',
              messageTh:
                  'ข้อห้ามใช้ร่วมกัน: ${d1.genericName} และ ${d2.genericName}',
              pairKey: 'fallback::$pairKey',
            ));
          } else if (d1WarnsAboutD2 || d2WarnsAboutD1) {
            alerts.add(CartAlertItem(
              category: CartAlertCategory.ddi,
              severity: InteractionSeverity.major,
              frequency: InteractionFrequency.common,
              messageEn: 'Drug interaction: ${d1.genericName} and ${d2.genericName}',
              messageTh:
                  'ปฏิกิริยาระหว่างยา: ${d1.genericName} และ ${d2.genericName}',
              pairKey: 'fallback::$pairKey',
            ));
          }
        }
      }
    }

    alerts.sort((a, b) {
      final rankDiff = _sortRank(a).compareTo(_sortRank(b));
      if (rankDiff != 0) return rankDiff;
      return b.severity.index.compareTo(a.severity.index);
    });

    return alerts;
  }

  /// Checks for any overlapping severe interactions, duplications, and allergies.
  /// Returns prioritized warning strings for backward compatibility.
  List<String> checkInteractions(bool isThai) {
    final seen = <String>{};
    final warnings = <String>[];
    for (final alert in evaluateAlerts()) {
      final msg = alert.localizedMessage(isThai);
      if (seen.add(msg)) {
        warnings.add(msg);
      }
    }
    return warnings;
  }

  static int _sortRank(CartAlertItem item) {
    switch (item.category) {
      case CartAlertCategory.allergy:
        return 0;
      case CartAlertCategory.therapeuticDuplication:
        return 1;
      case CartAlertCategory.ddi:
        return item.frequency == InteractionFrequency.common ? 2 : 3;
    }
  }

  static InteractionSeverity _severityFromLimit(
    LimitSeverity limitSeverity, {
    bool isContraindicated = false,
  }) {
    if (isContraindicated && limitSeverity == LimitSeverity.hard) {
      return InteractionSeverity.contraindicated;
    }
    switch (limitSeverity) {
      case LimitSeverity.hard:
        return InteractionSeverity.major;
      case LimitSeverity.soft:
        return InteractionSeverity.moderate;
      case LimitSeverity.info:
        return InteractionSeverity.minor;
    }
  }
}
