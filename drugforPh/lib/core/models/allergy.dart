import 'drug_class.dart';
import 'dose_limit.dart';

/// Clinical allergy match result (D9).
class AllergyAlert {
  final bool hasDirectMatch;
  final bool hasCrossReactivity;
  final String allergen;
  final String matchedAgent;
  final LimitSeverity severity;
  final String messageEn;
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
}

/// Allergy matching engine supporting cross-reactivity tables and TH/EN synonyms (D9).
class AllergyService {
  const AllergyService._();

  // Synonym dictionary normalizing clinical names and Thai words
  static const Map<String, String> _synonymMap = {
    // Penicillins
    'penicillin': 'penicillin',
    'penicillins': 'penicillin',
    'เพนิซิลลิน': 'penicillin',
    'amoxicillin': 'penicillin',
    'อะม็อกซีซิลลิน': 'penicillin',
    'amox': 'penicillin',
    'ampicillin': 'penicillin',
    'แอมพิซิลลิน': 'penicillin',
    'augmentin': 'penicillin',

    // Cephalosporins
    'cephalosporin': 'cephalosporin',
    'cephalosporins': 'cephalosporin',
    'เซฟาโลสปอริน': 'cephalosporin',
    'เซฟา': 'cephalosporin',
    'ceftriaxone': 'cephalosporin',
    'cefazolin': 'cephalosporin',
    'cefepime': 'cephalosporin',

    // Carbapenems
    'carbapenem': 'carbapenem',
    'คาร์บาพีเนม': 'carbapenem',
    'meropenem': 'carbapenem',

    // Sulfonamides
    'sulfa': 'sulfonamide',
    'sulfonamide': 'sulfonamide',
    'sulfonamides': 'sulfonamide',
    'ซัลฟา': 'sulfonamide',
    'bactrim': 'sulfonamide',
    'cotrimoxazole': 'sulfonamide',

    // NSAIDs
    'nsaid': 'nsaid',
    'nsaids': 'nsaid',
    'เอ็นเสด': 'nsaid',
    'aspirin': 'nsaid',
    'แอสไพริน': 'nsaid',
    'ibuprofen': 'nsaid',
    'ไอบูโพรเฟน': 'nsaid',

    // Aminoglycosides
    'aminoglycoside': 'aminoglycoside',
    'อะมิโนไกลโคไซด์': 'aminoglycoside',
    'gentamicin': 'aminoglycoside',
    'amikacin': 'aminoglycoside',

    // Fluoroquinolones
    'fluoroquinolone': 'fluoroquinolone',
    'ฟลูออโรควิโนโลน': 'fluoroquinolone',
    'ciprofloxacin': 'fluoroquinolone',
    'levofloxacin': 'fluoroquinolone',
  };

  /// Normalizes an allergy input string to a canonical token.
  static String normalize(String allergen) {
    final lower = allergen.trim().toLowerCase();
    return _synonymMap[lower] ?? lower;
  }

  /// Evaluates patient allergies against a drug's generic name and class.
  static List<AllergyAlert> evaluateAllergies({
    required List<String> patientAllergies,
    required String drugGenericName,
    required String drugId,
    required DrugClass? drugClass,
    required String? legacyAllergyClass,
  }) {
    final alerts = <AllergyAlert>[];
    final normalizedDrugGeneric = normalize(drugGenericName);
    final normalizedLegacyClass = legacyAllergyClass != null ? normalize(legacyAllergyClass) : null;

    for (final rawAllergy in patientAllergies) {
      if (rawAllergy.trim().isEmpty) continue;
      final normalizedAllergen = normalize(rawAllergy);

      // 1. Direct Generic Name Match
      if (normalizedAllergen == normalizedDrugGeneric ||
          normalizedAllergen == drugId.toLowerCase()) {
        alerts.add(AllergyAlert(
          hasDirectMatch: true,
          hasCrossReactivity: false,
          allergen: rawAllergy,
          matchedAgent: drugGenericName,
          severity: LimitSeverity.hard,
          messageEn:
              'ALLERGY ALERT: Patient is allergic to "$rawAllergy", which directly matches $drugGenericName.',
          messageTh:
              'การแจ้งเตือนการแพ้ยา: ผู้ป่วยมีประวัติแพ้ยา "$rawAllergy" ซึ่งตรงกับยา $drugGenericName โดยตรง (ห้ามใช้)',
        ));
        continue;
      }

      // 2. Direct Class Match
      bool isDirectClassMatch = false;
      if (drugClass != null) {
        if (drugClass == DrugClass.betaLactamPenicillin && normalizedAllergen == 'penicillin') {
          isDirectClassMatch = true;
        } else if (drugClass == DrugClass.betaLactamCephalosporin && normalizedAllergen == 'cephalosporin') {
          isDirectClassMatch = true;
        } else if (drugClass == DrugClass.betaLactamCarbapenem && normalizedAllergen == 'carbapenem') {
          isDirectClassMatch = true;
        } else if (drugClass == DrugClass.nsaid && normalizedAllergen == 'nsaid') {
          isDirectClassMatch = true;
        } else if (drugClass == DrugClass.aminoglycoside && normalizedAllergen == 'aminoglycoside') {
          isDirectClassMatch = true;
        } else if (drugClass == DrugClass.fluoroquinolone && normalizedAllergen == 'fluoroquinolone') {
          isDirectClassMatch = true;
        }
      }

      if (!isDirectClassMatch && normalizedLegacyClass != null) {
        if (normalizedAllergen == normalizedLegacyClass ||
            normalizedLegacyClass.contains(normalizedAllergen)) {
          isDirectClassMatch = true;
        }
      }

      if (isDirectClassMatch) {
        alerts.add(AllergyAlert(
          hasDirectMatch: true,
          hasCrossReactivity: false,
          allergen: rawAllergy,
          matchedAgent: drugGenericName,
          severity: LimitSeverity.hard,
          messageEn:
              'CLASS ALLERGY ALERT: Patient is allergic to "$rawAllergy", matching the pharmacological class of $drugGenericName.',
          messageTh:
              'การแจ้งเตือนการแพ้ยากลุ่ม: ผู้ป่วยมีประวัติแพ้ยา "$rawAllergy" ตรงกับกลุ่มยาของ $drugGenericName (ห้ามใช้)',
        ));
        continue;
      }

      // 3. Cross-Reactivity Table
      // Beta-lactam cross reactivity (Penicillin <-> Cephalosporin ~5-10%)
      if (normalizedAllergen == 'penicillin' &&
          drugClass == DrugClass.betaLactamCephalosporin) {
        alerts.add(AllergyAlert(
          hasDirectMatch: false,
          hasCrossReactivity: true,
          allergen: rawAllergy,
          matchedAgent: drugGenericName,
          severity: LimitSeverity.soft,
          messageEn:
              'CROSS-REACTIVITY WARNING: Patient has penicillin allergy. Cephalosporins have 3-5% cross-reactivity. Monitor closely for allergic manifestations.',
          messageTh:
              'คำเตือนการแพ้ข้ามกลุ่ม: ผู้ป่วยมีประวัติแพ้เพนิซิลลิน ยาเซฟาโลสปอรินมีความเสี่ยงแพ้ข้ามกลุ่มประมาณ 3-5% โปรดเฝ้าระวังอาการแพ้อย่างใกล้ชิด',
        ));
      } else if (normalizedAllergen == 'penicillin' &&
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
      } else if (normalizedAllergen == 'nsaid' &&
          drugClass == DrugClass.nsaid) {
        alerts.add(AllergyAlert(
          hasDirectMatch: true,
          hasCrossReactivity: true,
          allergen: rawAllergy,
          matchedAgent: drugGenericName,
          severity: LimitSeverity.hard,
          messageEn:
              'NSAID CROSS-REACTIVITY: Patient has NSAID/Aspirin hypersensitivity. Cross-reactivity among COX-1 inhibitors is high. Avoid use.',
          messageTh:
              'การแพ้ยากลุ่ม NSAIDs: ผู้ป่วยมีประวัติแพ้ยากลุ่ม NSAIDs/Aspirin มีความเสี่ยงแพ้ข้ามกลุ่มสูง ห้ามใช้',
        ));
      }
    }

    return alerts;
  }
}
