// ============================================================
// Drug Dosage Calculator — Allergy Matching Service (F7)
// ============================================================
// Clinical allergy checking engine supporting exact molecule matches,
// pharmacological class matches, cross-reactivity tables, and Thai synonyms.
//
// Single source of truth for allergy safety evaluation.
// ============================================================

import 'drug_class.dart';
import 'dose_limit.dart';

/// Clinical allergy match result (D9, F7).
class AllergyAlert {
  /// Whether the allergen is the exact same chemical entity (molecule) as the prescribed drug.
  final bool hasDirectMatch;

  /// Whether the alert represents pharmacological class-level cross-reactivity.
  final bool hasCrossReactivity;

  /// The patient's reported allergen string.
  final String allergen;

  /// The prescribed drug name evaluated.
  final String matchedAgent;

  /// Severity level (hard for direct/class contraindication, soft for cross-reactivity, info for unverified).
  final LimitSeverity severity;

  /// Clinical advisory text in English.
  final String messageEn;

  /// Clinical advisory text in Thai.
  final String messageTh;

  const AllergyAlert({
    required this.hasDirectMatch,
    required this.hasCrossReactivity,
    required this.allergen,
    required this.matchedAgent,
    required this.severity,
    required this.messageEn,
    required this.messageTh,
  });

  @override
  String toString() =>
      'AllergyAlert(direct: $hasDirectMatch, cross: $hasCrossReactivity, allergen: $allergen, agent: $matchedAgent)';
}

/// Allergy matching engine supporting cross-reactivity tables and TH/EN synonyms (D9, F7).
class AllergyService {
  const AllergyService._();

  // Synonym dictionary normalizing patient-reported allergen tokens to canonical tokens
  static const Map<String, String> _allergenSynonymMap = {
    // Penicillin class tokens
    'penicillin': 'penicillin',
    'penicillins': 'penicillin',
    'เพนิซิลลิน': 'penicillin',

    // Specific Penicillins (molecules)
    'amoxicillin': 'amoxicillin',
    'อะม็อกซีซิลลิน': 'amoxicillin',
    'amox': 'amoxicillin',
    'ampicillin': 'ampicillin',
    'แอมพิซิลลิน': 'ampicillin',
    'augmentin': 'amoxicillin/clavulanate',
    'amoxicillin/clavulanate': 'amoxicillin/clavulanate',
    'cloxacillin': 'cloxacillin',
    'คล็อกซาซิลลิน': 'cloxacillin',
    'piperacillin': 'piperacillin',
    'piperacillin/tazobactam': 'piperacillin/tazobactam',
    'tazocin': 'piperacillin/tazobactam',

    // Cephalosporin class tokens
    'cephalosporin': 'cephalosporin',
    'cephalosporins': 'cephalosporin',
    'เซฟาโลสปอริน': 'cephalosporin',
    'เซฟา': 'cephalosporin',

    // Specific Cephalosporins
    'ceftriaxone': 'ceftriaxone',
    'เซฟไตรอะโซน': 'ceftriaxone',
    'cefazolin': 'cefazolin',
    'เซฟาโซลิน': 'cefazolin',
    'cefepime': 'cefepime',
    'เซฟีพิม': 'cefepime',
    'cefotaxime': 'cefotaxime',
    'ceftazidime': 'ceftazidime',
    'cephalexin': 'cephalexin',

    // Carbapenem class tokens
    'carbapenem': 'carbapenem',
    'carbapenems': 'carbapenem',
    'คาร์บาพีเนม': 'carbapenem',

    // Specific Carbapenems
    'meropenem': 'meropenem',
    'เมโรพีเนม': 'meropenem',
    'imipenem': 'imipenem',
    'ertapenem': 'ertapenem',

    // Sulfonamide tokens
    'sulfa': 'sulfonamide',
    'sulfonamide': 'sulfonamide',
    'sulfonamides': 'sulfonamide',
    'ซัลฟา': 'sulfonamide',
    'bactrim': 'cotrimoxazole',
    'cotrimoxazole': 'cotrimoxazole',
    'co-trimoxazole': 'cotrimoxazole',
    'sulfamethoxazole': 'sulfamethoxazole',
    'furosemide': 'furosemide',
    'ฟูโรซีไมด์': 'furosemide',

    // NSAID tokens
    'nsaid': 'nsaid',
    'nsaids': 'nsaid',
    'เอ็นเสด': 'nsaid',
    'aspirin': 'aspirin',
    'แอสไพริน': 'aspirin',
    'ibuprofen': 'ibuprofen',
    'ไอบูโพรเฟน': 'ibuprofen',
    'naproxen': 'naproxen',
    'diclofenac': 'diclofenac',
    'ไดโคลฟีแนค': 'diclofenac',
    'mefenamic acid': 'mefenamic acid',
    'mefenamic_acid': 'mefenamic acid',
    'กรดมีฟีนามิก': 'mefenamic acid',
    'meloxicam': 'meloxicam',
    'เมล็อกซิแคม': 'meloxicam',
    'celecoxib': 'celecoxib',
    'เซเลค็อกซิบ': 'celecoxib',
    'indomethacin': 'indomethacin',
    'อินโดเมทาซิน': 'indomethacin',
    'ketorolac': 'ketorolac',
    'คีโตโรแลค': 'ketorolac',
    'piroxicam': 'piroxicam',
    'ไพร็อกซิแคม': 'piroxicam',

    // Aminoglycoside tokens
    'aminoglycoside': 'aminoglycoside',
    'aminoglycosides': 'aminoglycoside',
    'อะมิโนไกลโคไซด์': 'aminoglycoside',
    'gentamicin': 'gentamicin',
    'เจนตามัยซิน': 'gentamicin',
    'amikacin': 'amikacin',
    'อะมิกาซิน': 'amikacin',

    // Fluoroquinolone tokens
    'fluoroquinolone': 'fluoroquinolone',
    'fluoroquinolones': 'fluoroquinolone',
    'ฟลูออโรควิโนโลน': 'fluoroquinolone',
    'ciprofloxacin': 'ciprofloxacin',
    'ซิโปรฟล็อกซาซิน': 'ciprofloxacin',
    'levofloxacin': 'levofloxacin',
    'ลีโวฟล็อกซาซิน': 'levofloxacin',

    // Glycopeptides
    'vancomycin': 'vancomycin',
    'แวนโคมัยซิน': 'vancomycin',

    // Others
    'paracetamol': 'paracetamol',
    'พาราเซตามอล': 'paracetamol',
    'acetaminophen': 'paracetamol',
    'morphine': 'morphine',
    'fentanyl': 'fentanyl',
    'tramadol': 'tramadol',

    // High-frequency brand names (Thai & International)
    'ponstan': 'mefenamic acid',
    'พอนสแตน': 'mefenamic acid',
    'brufen': 'ibuprofen',
    'บรูเฟน': 'ibuprofen',
    'nurofen': 'ibuprofen',
    'นูโรเฟน': 'ibuprofen',
    'voltaren': 'diclofenac',
    'โวลทาเรน': 'diclofenac',
    'tylenol': 'paracetamol',
    'ไทลินอล': 'paracetamol',
    'sara': 'paracetamol',
    'ซาร่า': 'paracetamol',
    'celebrex': 'celecoxib',
    'ซีลีเบร็กซ์': 'celecoxib',
    'arcoxia': 'etoricoxib',
    'อาร์ค็อกเซีย': 'etoricoxib',
    'plavix': 'clopidogrel',
    'พลาวิกซ์': 'clopidogrel',
    'rocephin': 'ceftriaxone',
    'โรเซฟิน': 'ceftriaxone',
    'cravit': 'levofloxacin',
    'คราวิท': 'levofloxacin',
    'meronem': 'meropenem',
    'เมโรเนม': 'meropenem',
    'zithromax': 'azithromycin',
    'ซิโทรแมกซ์': 'azithromycin',
    'klacid': 'clarithromycin',
    'คลาซิด': 'clarithromycin',
    'lipitor': 'atorvastatin',
    'crestor': 'rosuvastatin',
    'glucophage': 'metformin',
  };

  /// Set of specific NSAID molecule tokens.
  static const Set<String> _nsaidMolecules = {
    'aspirin',
    'ibuprofen',
    'naproxen',
    'diclofenac',
    'mefenamic acid',
    'mefenamic_acid',
    'meloxicam',
    'celecoxib',
    'indomethacin',
    'ketorolac',
    'piroxicam',
  };

  /// Mapping of individual active molecules / class tokens to their DrugClass.
  static const Map<String, DrugClass> _moleculeClassMap = {
    // Penicillins
    'penicillin': DrugClass.betaLactamPenicillin,
    'amoxicillin': DrugClass.betaLactamPenicillin,
    'ampicillin': DrugClass.betaLactamPenicillin,
    'cloxacillin': DrugClass.betaLactamPenicillin,
    'piperacillin': DrugClass.betaLactamPenicillin,
    'piperacillin/tazobactam': DrugClass.betaLactamPenicillin,
    'piperacillin_tazobactam': DrugClass.betaLactamPenicillin,
    'tazocin': DrugClass.betaLactamPenicillin,
    'augmentin': DrugClass.betaLactamPenicillin,
    'amoxicillin/clavulanate': DrugClass.betaLactamPenicillin,

    // Cephalosporins
    'cephalosporin': DrugClass.betaLactamCephalosporin,
    'cefazolin': DrugClass.betaLactamCephalosporin,
    'ceftriaxone': DrugClass.betaLactamCephalosporin,
    'cefepime': DrugClass.betaLactamCephalosporin,
    'cefotaxime': DrugClass.betaLactamCephalosporin,
    'ceftazidime': DrugClass.betaLactamCephalosporin,
    'cephalexin': DrugClass.betaLactamCephalosporin,

    // Carbapenems
    'carbapenem': DrugClass.betaLactamCarbapenem,
    'meropenem': DrugClass.betaLactamCarbapenem,
    'imipenem': DrugClass.betaLactamCarbapenem,
    'ertapenem': DrugClass.betaLactamCarbapenem,

    // NSAIDs
    'nsaid': DrugClass.nsaid,
    'aspirin': DrugClass.nsaid,
    'ibuprofen': DrugClass.nsaid,
    'naproxen': DrugClass.nsaid,
    'diclofenac': DrugClass.nsaid,
    'mefenamic acid': DrugClass.nsaid,
    'mefenamic_acid': DrugClass.nsaid,
    'meloxicam': DrugClass.nsaid,
    'celecoxib': DrugClass.nsaid,
    'indomethacin': DrugClass.nsaid,
    'ketorolac': DrugClass.nsaid,
    'piroxicam': DrugClass.nsaid,

    // Aminoglycosides
    'aminoglycoside': DrugClass.aminoglycoside,
    'gentamicin': DrugClass.aminoglycoside,
    'amikacin': DrugClass.aminoglycoside,

    // Fluoroquinolones
    'fluoroquinolone': DrugClass.fluoroquinolone,
    'ciprofloxacin': DrugClass.fluoroquinolone,
    'levofloxacin': DrugClass.fluoroquinolone,

    // Sulfonamides
    'sulfonamide': DrugClass.sulfonamide,
    'cotrimoxazole': DrugClass.sulfonamide,
    'sulfamethoxazole': DrugClass.sulfonamide,
  };

  /// Normalizes an allergen input string to a canonical token, stripping dose/strength suffixes.
  static String normalizeAllergen(String allergen) {
    final lower = allergen.trim().toLowerCase();
    final stripped = lower
        .replaceAll(
          RegExp(r'\s*\d+(\.\d+)?\s*(mg|g|mcg|ml|cap|tab|เม็ด|แคปซูล)?\b', caseSensitive: false),
          '',
        )
        .trim();
    return _allergenSynonymMap[stripped] ??
        _allergenSynonymMap[lower] ??
        (stripped.isNotEmpty ? stripped : lower);
  }

  /// Evaluates patient allergies against a drug's generic name and class (F7).
  ///
  /// Matching policy:
  /// 1. Never normalize the drug name through the allergen map.
  /// 2. hasDirectMatch is TRUE ONLY for the same molecule.
  /// 3. Class matches are reported as class matches (hasDirectMatch = false).
  /// 4. Cross-reactivity rates are unified based on clinical literature.
  /// 5. Unrecognized allergens generate an informational advisory to verify manually.
  static List<AllergyAlert> evaluateAllergies({
    required List<String> patientAllergies,
    required String drugGenericName,
    required String drugId,
    required DrugClass? drugClass,
    required String? legacyAllergyClass,
  }) {
    final alerts = <AllergyAlert>[];
    final drugGenericClean = drugGenericName.trim().toLowerCase();
    final drugIdClean = drugId.trim().toLowerCase();

    for (final rawAllergy in patientAllergies) {
      if (rawAllergy.trim().isEmpty) continue;
      final cleanAllergen = rawAllergy.trim().toLowerCase();
      final canonicalToken = normalizeAllergen(cleanAllergen);
      final strippedAllergen = cleanAllergen
          .replaceAll(
            RegExp(r'\s*\d+(\.\d+)?\s*(mg|g|mcg|ml|cap|tab|เม็ด|แคปซูล)?\b', caseSensitive: false),
            '',
          )
          .trim();

      final allergenClass = _moleculeClassMap[canonicalToken] ??
          _moleculeClassMap[cleanAllergen] ??
          _moleculeClassMap[strippedAllergen];

      // Check if allergen exists anywhere in our known dictionary
      final isRecognized = _allergenSynonymMap.containsKey(cleanAllergen) ||
          _allergenSynonymMap.containsKey(strippedAllergen) ||
          _allergenSynonymMap.containsValue(canonicalToken) ||
          allergenClass != null;

      // 1. DIRECT MOLECULE MATCH (Exact same active chemical entity)
      final isDirectMoleculeMatch = cleanAllergen == drugGenericClean ||
          cleanAllergen == drugIdClean ||
          canonicalToken == drugGenericClean ||
          canonicalToken == drugIdClean ||
          (strippedAllergen.isNotEmpty &&
              (strippedAllergen == drugGenericClean || strippedAllergen == drugIdClean));

      if (isDirectMoleculeMatch) {
        alerts.add(AllergyAlert(
          hasDirectMatch: true,
          hasCrossReactivity: false,
          allergen: rawAllergy,
          matchedAgent: drugGenericName,
          severity: LimitSeverity.hard,
          messageEn:
              'DIRECT ALLERGY CONTRAINDICATION: Patient has documented allergy to "$rawAllergy", which is the same active molecule ($drugGenericName). Do not administer.',
          messageTh:
              'ข้อห้ามใช้เด็ดขาด: ผู้ป่วยมีประวัติแพ้ยา "$rawAllergy" ซึ่งตรงกับตัวยา $drugGenericName โดยตรง (ห้ามใช้)',
        ));
        continue;
      }

      // 2. PHARMACOLOGICAL CLASS MATCH (Intra-Class & Class-Wide)
      bool isDirectClassMatch = false;
      if (drugClass != null) {
        if (drugClass == allergenClass) {
          if (drugClass == DrugClass.nsaid) {
            // For NSAIDs, a class name like "nsaid" triggers class match.
            // Specific NSAID molecule vs different NSAID is handled under cross-reactivity (soft) below.
            if (canonicalToken == 'nsaid' || cleanAllergen == 'nsaid') {
              isDirectClassMatch = true;
            }
          } else {
            // Intra-class allergy contraindication for Beta-lactams, Aminoglycosides, Fluoroquinolones, Sulfonamides
            isDirectClassMatch = true;
          }
        } else if (drugClass == DrugClass.betaLactamPenicillin &&
            (canonicalToken == 'penicillin' || cleanAllergen == 'penicillin')) {
          isDirectClassMatch = true;
        } else if (drugClass == DrugClass.betaLactamCephalosporin &&
            (canonicalToken == 'cephalosporin' || cleanAllergen == 'cephalosporin')) {
          isDirectClassMatch = true;
        } else if (drugClass == DrugClass.betaLactamCarbapenem &&
            (canonicalToken == 'carbapenem' || cleanAllergen == 'carbapenem')) {
          isDirectClassMatch = true;
        } else if (drugClass == DrugClass.nsaid &&
            (canonicalToken == 'nsaid' || cleanAllergen == 'nsaid')) {
          isDirectClassMatch = true;
        } else if (drugClass == DrugClass.aminoglycoside &&
            (canonicalToken == 'aminoglycoside' || cleanAllergen == 'aminoglycoside')) {
          isDirectClassMatch = true;
        } else if (drugClass == DrugClass.fluoroquinolone &&
            (canonicalToken == 'fluoroquinolone' || cleanAllergen == 'fluoroquinolone')) {
          isDirectClassMatch = true;
        } else if (drugClass == DrugClass.sulfonamide &&
            (canonicalToken == 'sulfonamide' || cleanAllergen == 'sulfa')) {
          isDirectClassMatch = true;
        }
      }

      if (!isDirectClassMatch && legacyAllergyClass != null) {
        final legacyTokens = legacyAllergyClass
            .toLowerCase()
            .split(RegExp(r'[/,\s]+'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty);
        if (canonicalToken == legacyAllergyClass.toLowerCase() ||
            legacyTokens.contains(canonicalToken)) {
          isDirectClassMatch = true;
        }
      }

      if (isDirectClassMatch) {
        alerts.add(AllergyAlert(
          hasDirectMatch: false,
          hasCrossReactivity: false,
          allergen: rawAllergy,
          matchedAgent: drugGenericName,
          severity: LimitSeverity.hard,
          messageEn:
              'CLASS ALLERGY ALERT: Patient is allergic to pharmacological class "$rawAllergy", which includes $drugGenericName. Avoid use unless allergy testing or desensitization performed.',
          messageTh:
              'การแจ้งเตือนการแพ้ยากลุ่ม: ผู้ป่วยมีประวัติแพ้ยากลุ่ม "$rawAllergy" ซึ่งครอบคลุมยา $drugGenericName (ห้ามใช้)',
        ));
        continue;
      }

      // 3. CROSS-REACTIVITY EVALUATION
      bool evaluatedCrossReactivity = false;

      // Penicillin <-> Cephalosporin (2–5% unified cross-reactivity rate)
      if ((allergenClass == DrugClass.betaLactamPenicillin ||
              canonicalToken == 'penicillin' ||
              canonicalToken == 'amoxicillin' ||
              canonicalToken == 'ampicillin') &&
          drugClass == DrugClass.betaLactamCephalosporin) {
        alerts.add(AllergyAlert(
          hasDirectMatch: false,
          hasCrossReactivity: true,
          allergen: rawAllergy,
          matchedAgent: drugGenericName,
          severity: LimitSeverity.soft,
          messageEn:
              'CROSS-REACTIVITY WARNING: Patient has penicillin allergy. Cephalosporins have 2–5% cross-reactivity. Monitor closely for allergic manifestations.',
          messageTh:
              'คำเตือนการแพ้ข้ามกลุ่ม: ผู้ป่วยมีประวัติแพ้เพนิซิลลิน ยาเซฟาโลสปอรินมีความเสี่ยงแพ้ข้ามกลุ่มประมาณ 2–5% โปรดเฝ้าระวังอาการแพ้อย่างใกล้ชิด',
        ));
        evaluatedCrossReactivity = true;
      }

      // Penicillin <-> Carbapenem (~1% cross-reactivity)
      if ((allergenClass == DrugClass.betaLactamPenicillin ||
              canonicalToken == 'penicillin') &&
          drugClass == DrugClass.betaLactamCarbapenem) {
        alerts.add(AllergyAlert(
          hasDirectMatch: false,
          hasCrossReactivity: true,
          allergen: rawAllergy,
          matchedAgent: drugGenericName,
          severity: LimitSeverity.soft,
          messageEn:
              'CROSS-REACTIVITY WARNING: Patient has penicillin allergy. Carbapenems have ~1% cross-reactivity. Use with clinical caution.',
          messageTh:
              'คำเตือนการแพ้ข้ามกลุ่ม: ผู้ป่วยมีประวัติแพ้เพนิซิลลิน ยาคาร์บาพีเนมมีความเสี่ยงแพ้ข้ามกลุ่มประมาณ 1% ควรใช้ด้วยความระมัดระวัง',
        ));
        evaluatedCrossReactivity = true;
      }

      // Specific NSAID <-> Different NSAID cross-reactivity (COX-1 mediated)
      if ((_nsaidMolecules.contains(canonicalToken) || _nsaidMolecules.contains(cleanAllergen)) &&
          drugClass == DrugClass.nsaid &&
          canonicalToken != drugGenericClean &&
          cleanAllergen != drugGenericClean) {
        alerts.add(AllergyAlert(
          hasDirectMatch: false,
          hasCrossReactivity: true,
          allergen: rawAllergy,
          matchedAgent: drugGenericName,
          severity: LimitSeverity.soft,
          messageEn:
              'NSAID CROSS-REACTIVITY: Patient has documented hypersensitivity to $rawAllergy. Cross-reactivity among nonsteroidal anti-inflammatory drugs is high due to COX-1 inhibition. Avoid use.',
          messageTh:
              'ความเสี่ยงแพ้ข้ามกลุ่มในยากลุ่ม NSAIDs: ผู้ป่วยแพ้ $rawAllergy ยาในกลุ่ม NSAIDs มีความเสี่ยงแพ้ข้ามกลุ่มสูง ห้ามใช้',
        ));
        evaluatedCrossReactivity = true;
      }

      // Sulfonamide antibiotic vs non-antibiotic advisory [PHARMACIST]
      if ((canonicalToken == 'sulfonamide' || canonicalToken == 'cotrimoxazole') &&
          drugIdClean == 'furosemide') {
        alerts.add(AllergyAlert(
          hasDirectMatch: false,
          hasCrossReactivity: true,
          allergen: rawAllergy,
          matchedAgent: drugGenericName,
          severity: LimitSeverity.soft,
          messageEn:
              'SULFONAMIDE ADVISORY: Patient has sulfonamide allergy. Cross-reactivity between antimicrobial sulfonamides and non-antimicrobial sulfonamides (furosemide) is clinically very low, but use with monitoring.',
          messageTh:
              'คำแนะนำยากลุ่มซัลฟา: ผู้ป่วยมีประวัติแพ้ยาซัลฟา ความเสี่ยงแพ้ข้ามกลุ่มระหว่างยาปฏิชีวนะซัลฟากับยาขับปัสสาวะ (Furosemide) ต่ำมาก แต่ควรเฝ้าระวังอาการแพ้',
        ));
        evaluatedCrossReactivity = true;
      }

      if (evaluatedCrossReactivity) {
        continue;
      }

      // 4. UNRECOGNIZED ALLERGEN CHECK
      if (!isRecognized) {
        alerts.add(AllergyAlert(
          hasDirectMatch: false,
          hasCrossReactivity: false,
          allergen: rawAllergy,
          matchedAgent: drugGenericName,
          severity: LimitSeverity.info,
          messageEn:
              'UNRECOGNIZED ALLERGEN: Allergen "$rawAllergy" could not be matched in database; verify manually with clinical records.',
          messageTh:
              'ไม่พบข้อมูลสารก่อภูมิแพ้: ไม่สามารถจับคู่ประวัติแพ้ยา "$rawAllergy" ในฐานข้อมูลได้ โปรดตรวจสอบกับประวัติการรักษาของผู้ป่วยโดยตรง',
        ));
      }
    }

    return alerts;
  }
}
