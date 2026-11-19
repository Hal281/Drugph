import '../models/models.dart';

/// Exhaustive 3-tier formulary classification registry across all 123 drugs (WP-08 / FB-21).
class DrugTierRegistry {
  const DrugTierRegistry._();

  /// Draft Core Formulary V1 (34 Pediatric & Hospital Injectable drugs).
  /// Pending formal confirmation from Thai clinical pharmacist advisors (WP-13).
  static const Set<String> coreDrugIds = {
    // Pediatric & Oral Liquids / Common Acute Care (15)
    'paracetamol',
    'ibuprofen',
    'naproxen',
    'amoxicillin',
    'amoxicillin_clavulanate',
    'azithromycin',
    'cephalexin',
    'ceftriaxone',
    'cefazolin',
    'gentamicin',
    'vancomycin',
    'acyclovir',
    'salbutamol',
    'prednisolone',
    'dexamethasone',
    // Hospital Injectables / Resuscitation / ICU (19)
    'epinephrine',
    'atropine',
    'adenosine',
    'amiodarone',
    'midazolam',
    'diazepam',
    'phenytoin',
    'levetiracetam',
    'morphine',
    'fentanyl',
    'naloxone',
    'norepinephrine',
    'dopamine',
    'dobutamine',
    'magnesium_sulfate',
    'calcium_gluconate',
    'potassium_chloride',
    'furosemide',
    'insulin_regular',
  };

  /// Archived oncology & transplant immunosuppressant drugs retained for
  /// monograph reference only (Q2, FB-07, WP-08).
  static const Set<String> referenceOnlyDrugIds = {
    'carboplatin',
    'methotrexate',
    'tacrolimus',
    'mycophenolate',
  };

  /// Resolves the deterministic [DrugTier] for any [drugId].
  static DrugTier tierFor(String drugId) {
    final norm = drugId.trim().toLowerCase();
    if (referenceOnlyDrugIds.contains(norm)) return DrugTier.referenceOnly;
    if (coreDrugIds.contains(norm)) return DrugTier.core;
    return DrugTier.extended;
  }

  /// Sort priority: Core (0) -> Extended (1) -> ReferenceOnly (2).
  static int sortRank(DrugTier tier) {
    switch (tier) {
      case DrugTier.core:
        return 0;
      case DrugTier.extended:
        return 1;
      case DrugTier.referenceOnly:
        return 2;
    }
  }
}

/// Convenience getter exposing [DrugTier] directly on [Drug].
extension DrugTierExtension on Drug {
  DrugTier get tier => DrugTierRegistry.tierFor(id);
}
