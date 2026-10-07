import 'drug_class.dart';

/// Clinical drug ontology resolver mapping active ingredients and identifiers
/// to their pharmacological DrugClass according to WHO-ATC and Lexicomp standards.
class DrugOntology {
  const DrugOntology._();

  static const Map<String, DrugClass> _identifierClassMap = {
    // ---- Beta-Lactam Penicillins ----
    'amoxicillin': DrugClass.betaLactamPenicillin,
    'ampicillin': DrugClass.betaLactamPenicillin,
    'cloxacillin': DrugClass.betaLactamPenicillin,
    'piperacillin': DrugClass.betaLactamPenicillin,
    'piperacillin_tazobactam': DrugClass.betaLactamPenicillin,
    'piperacillin/tazobactam': DrugClass.betaLactamPenicillin,
    'augmentin': DrugClass.betaLactamPenicillin,
    'amoxicillin_clavulanate': DrugClass.betaLactamPenicillin,
    'amoxicillin/clavulanate': DrugClass.betaLactamPenicillin,
    'penicillin': DrugClass.betaLactamPenicillin,

    // ---- Beta-Lactam Cephalosporins ----
    'cefazolin': DrugClass.betaLactamCephalosporin,
    'ceftriaxone': DrugClass.betaLactamCephalosporin,
    'cefepime': DrugClass.betaLactamCephalosporin,
    'cefotaxime': DrugClass.betaLactamCephalosporin,
    'ceftazidime': DrugClass.betaLactamCephalosporin,
    'cephalexin': DrugClass.betaLactamCephalosporin,

    // ---- Beta-Lactam Carbapenems ----
    'meropenem': DrugClass.betaLactamCarbapenem,
    'imipenem': DrugClass.betaLactamCarbapenem,
    'ertapenem': DrugClass.betaLactamCarbapenem,

    // ---- Aminoglycosides ----
    'gentamicin': DrugClass.aminoglycoside,
    'amikacin': DrugClass.aminoglycoside,
    'tobramycin': DrugClass.aminoglycoside,

    // ---- Fluoroquinolones ----
    'ciprofloxacin': DrugClass.fluoroquinolone,
    'levofloxacin': DrugClass.fluoroquinolone,
    'moxifloxacin': DrugClass.fluoroquinolone,

    // ---- Glycopeptides ----
    'vancomycin': DrugClass.glycopeptide,
    'teicoplanin': DrugClass.glycopeptide,

    // ---- Macrolides ----
    'azithromycin': DrugClass.macrolide,
    'clarithromycin': DrugClass.macrolide,
    'erythromycin': DrugClass.macrolide,

    // ---- Sulfonamides ----
    'cotrimoxazole': DrugClass.sulfonamide,
    'sulfamethoxazole': DrugClass.sulfonamide,
    'silver_sulfadiazine': DrugClass.sulfonamide,

    // ---- NSAIDs ----
    'aspirin': DrugClass.nsaid,
    'ibuprofen': DrugClass.nsaid,
    'naproxen': DrugClass.nsaid,
    'diclofenac': DrugClass.nsaid,
    'mefenamic_acid': DrugClass.nsaid,
    'mefenamic acid': DrugClass.nsaid,
    'meloxicam': DrugClass.nsaid,
    'celecoxib': DrugClass.nsaid,
    'indomethacin': DrugClass.nsaid,
    'ketorolac': DrugClass.nsaid,
    'piroxicam': DrugClass.nsaid,

    // ---- ACE Inhibitors ----
    'enalapril': DrugClass.aceInhibitor,
    'ramipril': DrugClass.aceInhibitor,
    'captopril': DrugClass.aceInhibitor,
    'lisinopril': DrugClass.aceInhibitor,

    // ---- ARBs (Angiotensin Receptor Blockers) ----
    'losartan': DrugClass.arb,
    'valsartan': DrugClass.arb,
    'candesartan': DrugClass.arb,
    'telmisartan': DrugClass.arb,
    'irbesartan': DrugClass.arb,

    // ---- Anticoagulants (VKA) ----
    'warfarin': DrugClass.anticoagulantVka,

    // ---- Anticoagulants (DOAC) ----
    'apixaban': DrugClass.anticoagulantDoac,
    'rivaroxaban': DrugClass.anticoagulantDoac,
    'dabigatran': DrugClass.anticoagulantDoac,
    'edoxaban': DrugClass.anticoagulantDoac,

    // ---- Anticoagulants (Heparin / LMWH) ----
    'heparin': DrugClass.anticoagulantHeparin,
    'enoxaparin': DrugClass.anticoagulantHeparin,
    'fondaparinux': DrugClass.anticoagulantHeparin,

    // ---- Statins (HMG-CoA Reductase Inhibitors) ----
    'atorvastatin': DrugClass.statin,
    'simvastatin': DrugClass.statin,
    'rosuvastatin': DrugClass.statin,
    'pravastatin': DrugClass.statin,

    // ---- Diuretics ----
    'furosemide': DrugClass.loopDiuretic,
    'torsemide': DrugClass.loopDiuretic,
    'spironolactone': DrugClass.potassiumSparingDiuretic,
    'eplerenone': DrugClass.potassiumSparingDiuretic,
    'amiloride': DrugClass.potassiumSparingDiuretic,
    'hydrochlorothiazide': DrugClass.thiazideDiuretic,
    'hctz': DrugClass.thiazideDiuretic,
    'indapamide': DrugClass.thiazideDiuretic,

    // ---- Calcium Channel Blockers ----
    'amlodipine': DrugClass.calciumChannelBlocker,
    'diltiazem': DrugClass.calciumChannelBlocker,
    'verapamil': DrugClass.calciumChannelBlocker,
    'nicardipine': DrugClass.calciumChannelBlocker,
    'nifedipine': DrugClass.calciumChannelBlocker,

    // ---- Opioids ----
    'morphine': DrugClass.opioid,
    'tramadol': DrugClass.opioid,
    'fentanyl': DrugClass.opioid,
    'pethidine': DrugClass.opioid,
    'codeine': DrugClass.opioid,

    // ---- Antidiabetic Agents ----
    'metformin': DrugClass.biguanide,
    'glipizide': DrugClass.sulfonylurea,
    'glimepiride': DrugClass.sulfonylurea,
    'gliclazide': DrugClass.sulfonylurea,
    'empagliflozin': DrugClass.sglt2Inhibitor,
    'dapagliflozin': DrugClass.sglt2Inhibitor,
    'sitagliptin': DrugClass.dpp4Inhibitor,
    'linagliptin': DrugClass.dpp4Inhibitor,
    'vildagliptin': DrugClass.dpp4Inhibitor,

    // ---- Antidepressants ----
    'sertraline': DrugClass.ssri,
    'fluoxetine': DrugClass.ssri,
    'escitalopram': DrugClass.ssri,
    'amitriptyline': DrugClass.tca,
    'nortriptyline': DrugClass.tca,

    // ---- Anticonvulsants ----
    'phenytoin': DrugClass.anticonvulsant,
    'valproic_acid': DrugClass.anticonvulsant,
    'carbamazepine': DrugClass.anticonvulsant,
    'levetiracetam': DrugClass.anticonvulsant,
    'gabapentin': DrugClass.anticonvulsant,

    // ---- Corticosteroids ----
    'dexamethasone': DrugClass.corticosteroid,
    'prednisolone': DrugClass.corticosteroid,
    'hydrocortisone': DrugClass.corticosteroid,
    'methylprednisolone': DrugClass.corticosteroid,
  };

  /// Resolves a drug identifier or generic name to its clinical [DrugClass].
  static DrugClass? resolveDrugClass(
    String id, [
    String? genericName,
    String? allergyClass,
  ]) {
    final cleanId = id.trim().toLowerCase();
    if (_identifierClassMap.containsKey(cleanId)) {
      return _identifierClassMap[cleanId];
    }

    if (genericName != null) {
      final cleanName = genericName.trim().toLowerCase();
      for (final entry in _identifierClassMap.entries) {
        if (cleanName.contains(entry.key)) {
          return entry.value;
        }
      }
    }

    if (allergyClass != null) {
      final cleanAllergy = allergyClass.trim().toLowerCase();
      if (cleanAllergy.contains('nsaid')) return DrugClass.nsaid;
      if (cleanAllergy.contains('penicillin')) return DrugClass.betaLactamPenicillin;
      if (cleanAllergy.contains('cephalosporin')) return DrugClass.betaLactamCephalosporin;
      if (cleanAllergy.contains('carbapenem')) return DrugClass.betaLactamCarbapenem;
      if (cleanAllergy.contains('ace inhibitor')) return DrugClass.aceInhibitor;
      if (cleanAllergy.contains('arb')) return DrugClass.arb;
      if (cleanAllergy.contains('statin')) return DrugClass.statin;
      if (cleanAllergy.contains('opioid')) return DrugClass.opioid;
      if (cleanAllergy.contains('sulfonamide')) return DrugClass.sulfonamide;
    }

    return null;
  }

  /// Resolves an identifier to human-readable generic name format.
  static String resolveGenericName(String id) {
    final clean = id.trim().replaceAll('_', ' ');
    if (clean.isEmpty) return id;
    return clean[0].toUpperCase() + clean.substring(1);
  }
}

