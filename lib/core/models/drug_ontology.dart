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
    'valproic acid': DrugClass.anticonvulsant,
    'valproate': DrugClass.anticonvulsant,
    'sodium_valproate': DrugClass.anticonvulsant,
    'sodium valproate': DrugClass.anticonvulsant,
    'depakine': DrugClass.anticonvulsant,
    'carbamazepine': DrugClass.anticonvulsant,
    'levetiracetam': DrugClass.anticonvulsant,
    'gabapentin': DrugClass.anticonvulsant,

    // ---- Corticosteroids ----
    'dexamethasone': DrugClass.corticosteroid,
    'prednisolone': DrugClass.corticosteroid,
    'hydrocortisone': DrugClass.corticosteroid,
    'methylprednisolone': DrugClass.corticosteroid,
    'budesonide': DrugClass.corticosteroid,
    'budesonide_neb': DrugClass.corticosteroid,

    // ---- Benzodiazepines ----
    'diazepam': DrugClass.benzodiazepine,
    'lorazepam': DrugClass.benzodiazepine,
    'midazolam': DrugClass.benzodiazepine,
    'clonazepam': DrugClass.benzodiazepine,
    'alprazolam': DrugClass.benzodiazepine,

    // ---- Beta-Blockers ----
    'metoprolol': DrugClass.betaBlocker,
    'atenolol': DrugClass.betaBlocker,
    'propranolol': DrugClass.betaBlocker,
    'carvedilol': DrugClass.betaBlocker,
    'bisoprolol': DrugClass.betaBlocker,

    // ---- Proton Pump Inhibitors (PPIs) ----
    'omeprazole': DrugClass.protonPumpInhibitor,
    'pantoprazole': DrugClass.protonPumpInhibitor,
    'esomeprazole': DrugClass.protonPumpInhibitor,
    'rabeprazole': DrugClass.protonPumpInhibitor,
    'lansoprazole': DrugClass.protonPumpInhibitor,

    // ---- Antiplatelet Agents ----
    'clopidogrel': DrugClass.antiplatelet,
    'ticagrelor': DrugClass.antiplatelet,
    'prasugrel': DrugClass.antiplatelet,

    // ---- Antihistamines ----
    'chlorpheniramine': DrugClass.antihistamine,
    'cpm': DrugClass.antihistamine,
    'cetirizine': DrugClass.antihistamine,
    'loratadine': DrugClass.antihistamine,
    'fexofenadine': DrugClass.antihistamine,

    // ---- Vasopressors & Inotropes ----
    'norepinephrine': DrugClass.vasopressorInotrope,
    'epinephrine': DrugClass.vasopressorInotrope,
    'dopamine': DrugClass.vasopressorInotrope,
    'dobutamine': DrugClass.vasopressorInotrope,

    // ---- Antipsychotics ----
    'haloperidol': DrugClass.typicalAntipsychotic,
    'olanzapine': DrugClass.atypicalAntipsychotic,
    'risperidone': DrugClass.atypicalAntipsychotic,
    'quetiapine': DrugClass.atypicalAntipsychotic,

    // ---- Antimicrobials (Specific Classes) ----
    'clindamycin': DrugClass.lincosamide,
    'metronidazole': DrugClass.nitroimidazole,
    'linezolid': DrugClass.oxazolidinone,
    'doxycycline': DrugClass.tetracycline,
    'colistin': DrugClass.polymyxin,
    'colistimethate': DrugClass.polymyxin,
    'acyclovir': DrugClass.antiviral,
    'fluconazole': DrugClass.antifungal,

    // ---- Analgesics (Non-Opioid) ----
    'paracetamol': DrugClass.nonOpioidAnalgesic,
    'acetaminophen': DrugClass.nonOpioidAnalgesic,

    // ---- Respiratory Beta-2 Agonists ----
    'salbutamol': DrugClass.beta2Agonist,
    'albuterol': DrugClass.beta2Agonist,
    'terbutaline': DrugClass.beta2Agonist,

    // ---- Anticholinergics ----
    'atropine': DrugClass.anticholinergic,
    'ipratropium': DrugClass.anticholinergic,
    'hyoscine_butylbromide': DrugClass.anticholinergic,

    // ---- Antiemetics (5-HT3 & Dopamine Antagonists) ----
    'ondansetron': DrugClass.antiemetic5Ht3,
    'metoclopramide': DrugClass.dopamineAntagonist,
    'domperidone': DrugClass.dopamineAntagonist,

    // ---- Insulins ----
    'insulin_regular': DrugClass.insulin,
    'insulin_glargine': DrugClass.insulin,
    'insulin': DrugClass.insulin,

    // ---- Thyroid & Antithyroid ----
    'levothyroxine': DrugClass.thyroidAgent,
    'methimazole': DrugClass.thyroidAgent,
    'propylthiouracil': DrugClass.thyroidAgent,

    // ---- Immunosuppressants ----
    'tacrolimus': DrugClass.immunosuppressant,
    'mycophenolate': DrugClass.immunosuppressant,
    'mycophenolate_mofetil': DrugClass.immunosuppressant,

    // ---- Specialty & Electrolytes ----
    'lithium': DrugClass.other,
    'amiodarone': DrugClass.other,
    'adenosine': DrugClass.other,
    'digoxin': DrugClass.other,
    'magnesium_sulfate': DrugClass.other,
    'potassium_chloride': DrugClass.other,
    'calcium_gluconate': DrugClass.other,
    'calcium_carbonate': DrugClass.other,
    'vitamin_k': DrugClass.other,
    'naloxone': DrugClass.other,
    'mupirocin': DrugClass.other,
    'oxytocin': DrugClass.other,
    'misoprostol': DrugClass.other,
    'methylergometrine': DrugClass.other,
    'pioglitazone': DrugClass.other,
    'sevelamer': DrugClass.other,
    'epoetin_alfa': DrugClass.other,
    'sodium_polystyrene_sulfonate': DrugClass.other,
    'calcitriol': DrugClass.other,
    'cinacalcet': DrugClass.other,
    'carboplatin': DrugClass.other,
    'methotrexate': DrugClass.other,
    'montelukast': DrugClass.other,
    'n_acetylcysteine': DrugClass.other,
    'rifampin': DrugClass.other,
    'isoniazid': DrugClass.other,
    'pyrazinamide': DrugClass.other,
    'ethambutol': DrugClass.other,
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

