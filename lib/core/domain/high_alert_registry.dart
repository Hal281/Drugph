import 'dart:convert';

import '../models/models.dart';

/// Immutable entry from an authoritative High-Alert Medication list (WP-03).
class HighAlertEntry {
  final String drugId;
  final Set<String> applicableRoutes;
  final String ismpCategory;
  final String sourceEdition;
  final String rationale;

  const HighAlertEntry({
    required this.drugId,
    required this.applicableRoutes,
    required this.ismpCategory,
    required this.sourceEdition,
    required this.rationale,
  });

  bool appliesToRoute(DoseRoute? route) {
    if (applicableRoutes.contains('all')) return true;
    if (route == null) return applicableRoutes.isNotEmpty;
    return applicableRoutes.contains(route.name);
  }
}

/// Optional per-hospital PTC override hook for High-Alert classifications (WP-03 / WP-15).
class HighAlertOverride {
  final Set<String> addedDrugIds;
  final Set<String> removedDrugIds;
  final Map<String, Set<String>> routeOverrides;

  const HighAlertOverride({
    this.addedDrugIds = const {},
    this.removedDrugIds = const {},
    this.routeOverrides = const {},
  });
}

/// Authoritative route-aware registry of High-Alert Medications grounded in the
/// **ISMP List of High-Alert Medications in Acute Care Settings (2024 Edition)**,
/// separated from Narrow Therapeutic Index (NTI) / TDM medications (FB-11).
class HighAlertRegistry {
  const HighAlertRegistry._();

  static const String sourceEdition = 'ISMP Acute Care 2024';

  /// Canonical NTI / TDM drugs displayed with a distinct `NTI / TDM` tag rather than
  /// inflating the ISMP High-Alert Drug list.
  static const Set<String> narrowTherapeuticIndexDrugIds = {
    'vancomycin',
    'gentamicin',
    'amikacin',
    'digoxin',
    'phenytoin',
    'valproic_acid',
    'lithium',
    'tacrolimus',
    'carbamazepine',
    'theophylline',
    'warfarin',
  };

  /// Synchronous mirror of `assets/data/high_alert_lists/ismp_acute_care.json`.
  static const Map<String, HighAlertEntry> ismpAcuteCare2024 = {
    'norepinephrine': HighAlertEntry(
      drugId: 'norepinephrine',
      applicableRoutes: {'ivInfusion', 'ivPush', 'iv', 'io'},
      ismpCategory: 'Adrenergic agonists, IV',
      sourceEdition: sourceEdition,
      rationale:
          'IV vasoactive catecholamine; dosing/infusion-rate errors rapidly cause severe hypertension, arrhythmias, or tissue ischemia.',
    ),
    'epinephrine': HighAlertEntry(
      drugId: 'epinephrine',
      applicableRoutes: {'ivInfusion', 'ivPush', 'iv', 'io'},
      ismpCategory: 'Adrenergic agonists, IV',
      sourceEdition: sourceEdition,
      rationale:
          'IV/IO adrenergic agonist requires double-check for concentration and pump rate; IM anaphylaxis is excluded from IV class.',
    ),
    'dopamine': HighAlertEntry(
      drugId: 'dopamine',
      applicableRoutes: {'ivInfusion', 'ivPush', 'iv', 'io'},
      ismpCategory: 'Adrenergic agonists, IV',
      sourceEdition: sourceEdition,
      rationale:
          'IV adrenergic agonist (look-alike Tall Man pair DOPamine/DOBUTamine).',
    ),
    'dobutamine': HighAlertEntry(
      drugId: 'dobutamine',
      applicableRoutes: {'ivInfusion', 'iv'},
      ismpCategory: 'Inotropic medications, IV / Adrenergic agonists, IV',
      sourceEdition: sourceEdition,
      rationale:
          'IV inotropic catecholamine (look-alike Tall Man pair DOBUTamine/DOPamine).',
    ),
    'vasopressin': HighAlertEntry(
      drugId: 'vasopressin',
      applicableRoutes: {'ivInfusion', 'iv', 'io'},
      ismpCategory: 'Vasopressin, IV and intraosseous',
      sourceEdition: sourceEdition,
      rationale:
          'Listed on ISMP 2024 Specific Medications (IV and IO).',
    ),
    'metoprolol': HighAlertEntry(
      drugId: 'metoprolol',
      applicableRoutes: {'ivInfusion', 'ivPush', 'iv'},
      ismpCategory: 'Adrenergic antagonists, IV',
      sourceEdition: sourceEdition,
      rationale: 'IV beta-blocker listed under Adrenergic antagonists, IV.',
    ),
    'amiodarone': HighAlertEntry(
      drugId: 'amiodarone',
      applicableRoutes: {'ivInfusion', 'ivPush', 'iv'},
      ismpCategory: 'Antiarrhythmics, IV',
      sourceEdition: sourceEdition,
      rationale: 'IV antiarrhythmic carrying hypotension and arrhythmia risk.',
    ),
    'adenosine': HighAlertEntry(
      drugId: 'adenosine',
      applicableRoutes: {'ivInfusion', 'ivPush', 'iv'},
      ismpCategory: 'Antiarrhythmics, IV',
      sourceEdition: sourceEdition,
      rationale:
          'IV antiarrhythmic producing transient asystole; requires rapid push protocol.',
    ),
    'digoxin': HighAlertEntry(
      drugId: 'digoxin',
      applicableRoutes: {'ivInfusion', 'ivPush', 'iv'},
      ismpCategory: 'Inotropic medications, IV',
      sourceEdition: sourceEdition,
      rationale:
          'IV digoxin is listed under Inotropic medications, IV; oral digoxin is tracked as NTI/TDM.',
    ),
    'warfarin': HighAlertEntry(
      drugId: 'warfarin',
      applicableRoutes: {'all'},
      ismpCategory: 'Antithrombotic agents — Anticoagulants',
      sourceEdition: sourceEdition,
      rationale:
          'Oral vitamin K antagonist with narrow therapeutic index and fatal hemorrhage risk.',
    ),
    'enoxaparin': HighAlertEntry(
      drugId: 'enoxaparin',
      applicableRoutes: {'all'},
      ismpCategory: 'Antithrombotic agents — Low molecular weight heparins',
      sourceEdition: sourceEdition,
      rationale: 'LMWH anticoagulant with bleeding and spinal hematoma risk.',
    ),
    'heparin': HighAlertEntry(
      drugId: 'heparin',
      applicableRoutes: {'all'},
      ismpCategory: 'Antithrombotic agents — Unfractionated heparin',
      sourceEdition: sourceEdition,
      rationale:
          'High-risk anticoagulant prone to weight-based/vial-strength dosing errors.',
    ),
    'apixaban': HighAlertEntry(
      drugId: 'apixaban',
      applicableRoutes: {'all'},
      ismpCategory: 'Antithrombotic agents — DOACs and factor Xa inhibitors',
      sourceEdition: sourceEdition,
      rationale: 'Direct factor Xa inhibitor carrying major bleeding risk.',
    ),
    'rivaroxaban': HighAlertEntry(
      drugId: 'rivaroxaban',
      applicableRoutes: {'all'},
      ismpCategory: 'Antithrombotic agents — DOACs and factor Xa inhibitors',
      sourceEdition: sourceEdition,
      rationale: 'Direct factor Xa inhibitor carrying major bleeding risk.',
    ),
    'insulin_regular': HighAlertEntry(
      drugId: 'insulin_regular',
      applicableRoutes: {'all'},
      ismpCategory: 'Insulin, subcutaneous and IV',
      sourceEdition: sourceEdition,
      rationale: 'Severe hypoglycemia and hypokalemia risk across SC and IV.',
    ),
    'insulin_glargine': HighAlertEntry(
      drugId: 'insulin_glargine',
      applicableRoutes: {'all'},
      ismpCategory: 'Insulin, subcutaneous and IV',
      sourceEdition: sourceEdition,
      rationale: 'Long-acting insulin with severe hypoglycemia risk.',
    ),
    'glipizide': HighAlertEntry(
      drugId: 'glipizide',
      applicableRoutes: {'all'},
      ismpCategory: 'Hypoglycemics, oral',
      sourceEdition: sourceEdition,
      rationale:
          'Oral sulfonylurea included under ISMP 2024 Hypoglycemics, oral.',
    ),
    'morphine': HighAlertEntry(
      drugId: 'morphine',
      applicableRoutes: {'all'},
      ismpCategory: 'Opioids (all routes)',
      sourceEdition: sourceEdition,
      rationale: 'Opioid analgesic with respiratory depression risk.',
    ),
    'fentanyl': HighAlertEntry(
      drugId: 'fentanyl',
      applicableRoutes: {'all'},
      ismpCategory: 'Opioids (all routes)',
      sourceEdition: sourceEdition,
      rationale: 'Potent opioid dosed in mcg with respiratory arrest risk.',
    ),
    'tramadol': HighAlertEntry(
      drugId: 'tramadol',
      applicableRoutes: {'all'},
      ismpCategory: 'Opioids (all routes)',
      sourceEdition: sourceEdition,
      rationale: 'Opioid agonist across oral and parenteral routes.',
    ),
    'midazolam': HighAlertEntry(
      drugId: 'midazolam',
      applicableRoutes: {'ivInfusion', 'ivPush', 'iv', 'po'},
      ismpCategory: 'Moderate sedation agents, IV / Pediatric oral sedation',
      sourceEdition: sourceEdition,
      rationale: 'IV moderate sedation agent and pediatric oral sedation.',
    ),
    'dexmedetomidine': HighAlertEntry(
      drugId: 'dexmedetomidine',
      applicableRoutes: {'ivInfusion', 'ivPush', 'iv'},
      ismpCategory: 'Moderate sedation agents, IV',
      sourceEdition: sourceEdition,
      rationale: 'ISMP 2024 IV moderate sedation agent.',
    ),
    'propofol': HighAlertEntry(
      drugId: 'propofol',
      applicableRoutes: {'all'},
      ismpCategory: 'Anesthetic agents, general, inhaled and IV',
      sourceEdition: sourceEdition,
      rationale: 'IV general anesthetic carrying apnea, hypotension, and PRIS risk.',
    ),
    'magnesium_sulfate': HighAlertEntry(
      drugId: 'magnesium_sulfate',
      applicableRoutes: {'ivInfusion', 'ivPush', 'iv', 'im'},
      ismpCategory: 'Magnesium sulfate injection',
      sourceEdition: sourceEdition,
      rationale: 'ISMP 2024 Specific Medications (injection).',
    ),
    'oxytocin': HighAlertEntry(
      drugId: 'oxytocin',
      applicableRoutes: {'ivInfusion', 'iv'},
      ismpCategory: 'Oxytocin, IV',
      sourceEdition: sourceEdition,
      rationale: 'ISMP 2024 Specific Medications (IV only).',
    ),
    'potassium_chloride': HighAlertEntry(
      drugId: 'potassium_chloride',
      applicableRoutes: {'ivInfusion', 'iv'},
      ismpCategory: 'Potassium chloride for injection concentrate',
      sourceEdition: sourceEdition,
      rationale:
          'ISMP 2024 Specific Medications (injection concentrate); oral KCl is excluded.',
    ),
    'carboplatin': HighAlertEntry(
      drugId: 'carboplatin',
      applicableRoutes: {'all'},
      ismpCategory: 'Chemotherapeutic agents, parenteral and oral',
      sourceEdition: sourceEdition,
      rationale: 'Parenteral cytotoxic antineoplastic agent.',
    ),
    'methotrexate': HighAlertEntry(
      drugId: 'methotrexate',
      applicableRoutes: {'all'},
      ismpCategory:
          'Chemotherapeutic agents / Methotrexate, oral, non-oncologic use',
      sourceEdition: sourceEdition,
      rationale: 'Parenteral/oral chemotherapy and oral weekly non-oncologic risk.',
    ),
  };

  /// Parses `assets/data/high_alert_lists/ismp_acute_care.json` for schema parity checks.
  static Map<String, HighAlertEntry> parseJsonAsset(String jsonStr) {
    final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
    final rawEntries = (decoded['entries'] as List<dynamic>? ?? const []);
    final out = <String, HighAlertEntry>{};
    for (final item in rawEntries) {
      final map = item as Map<String, dynamic>;
      final id = (map['drugId'] as String).toLowerCase();
      final routes = (map['applicableRoutes'] as List<dynamic>)
          .map((e) => e.toString())
          .toSet();
      out[id] = HighAlertEntry(
        drugId: id,
        applicableRoutes: routes,
        ismpCategory: map['ismpCategory'] as String,
        sourceEdition: map['sourceEdition'] as String,
        rationale: map['rationale'] as String,
      );
    }
    return out;
  }

  /// Route-aware High-Alert check with optional hospital PTC override hook.
  static bool isHighAlert(
    String drugId, {
    DoseRoute? route,
    HighAlertOverride? hospitalOverride,
  }) {
    final id = drugId.trim().toLowerCase();
    if (hospitalOverride != null) {
      if (hospitalOverride.removedDrugIds.contains(id)) {
        return false;
      }
      final customRoutes = hospitalOverride.routeOverrides[id];
      if (customRoutes != null) {
        if (customRoutes.contains('all')) return true;
        if (route == null) return customRoutes.isNotEmpty;
        return customRoutes.contains(route.name);
      }
      if (hospitalOverride.addedDrugIds.contains(id)) {
        return true;
      }
    }

    final entry = ismpAcuteCare2024[id];
    if (entry == null) return false;
    return entry.appliesToRoute(route);
  }

  /// Catalog-level High-Alert check across a drug's actual configured routes.
  ///
  /// Prevents PO-only drugs (e.g. oral Digoxin or oral Metoprolol) from
  /// displaying the red High-Alert badge when only IV forms are on the ISMP list.
  static bool isDrugHighAlertInCatalog(
    Drug drug, {
    HighAlertOverride? hospitalOverride,
  }) {
    if (drug.regimens.isEmpty) {
      return isHighAlert(drug.id, hospitalOverride: hospitalOverride);
    }
    return drug.regimens.any(
      (r) => isHighAlert(
        drug.id,
        route: r.route,
        hospitalOverride: hospitalOverride,
      ),
    );
  }

  /// Returns `true` when [drug] is a Narrow Therapeutic Index / TDM agent.
  static bool isNarrowTherapeuticIndex(Drug drug) {
    if (drug.requiresTDM) return true;
    return narrowTherapeuticIndexDrugIds.contains(drug.id.trim().toLowerCase());
  }

  /// Returns the ISMP entry metadata if [drugId] is on the ISMP 2024 Acute Care list.
  static HighAlertEntry? entryFor(String drugId) =>
      ismpAcuteCare2024[drugId.trim().toLowerCase()];
}
