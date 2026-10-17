import '../models/transparent_calculation_result.dart';
import '../models/verified_drug_schema.dart';

/// Result of evaluating patient allergies against a [VerifiedDrugEntry].
class AllergyEvaluationOutput {
  final List<TransparentSafetyAlert> matchedAlerts;
  final List<String> unrecognizedAllergies;

  const AllergyEvaluationOutput({
    required this.matchedAlerts,
    required this.unrecognizedAllergies,
  });
}

/// Result of evaluating concomitant medications against a [VerifiedDrugEntry].
class DdiEvaluationOutput {
  final List<TransparentSafetyAlert> matchedAlerts;
  final List<String> unrecognizedMedications;

  const DdiEvaluationOutput({
    required this.matchedAlerts,
    required this.unrecognizedMedications,
  });
}

/// Deterministic Clinical Safety Check Engine (Pillar 2).
///
/// Enforces:
/// 1. Strict input validation (`weightKg <= 0`, `ageYears < 0`, `crclMlMin < 0`,
///    `dosesPerDay <= 0`, `concentrationMgPerMl <= 0` immediately throw
///    [InvalidPatientInputException]).
/// 2. Exact & alias-based Allergy evaluation (NO loose `.contains()` substring matching
///    that would cause `"in"` or `"a"` to falsely match `"Penicillin"` or `"Warfarin"`),
///    supporting English generic names, hospital brand names, Thai names, and
///    bounded Levenshtein-1 typo tolerance for words of length `>= 6`.
/// 3. Exact & alias-based Drug-Drug Interaction (DDI) checks with explicit
///    `databaseSource` attribution and unrecognized-medication warnings when an
///    entered drug is outside the verified database.
/// 4. Explicit `SafetyAlertSeverity.info` notices when `ageYears`, `crclMlMin`,
///    or `allergyAssessmentStatus` are unassessed (`notAssessed`).
/// 5. Unified Non-Blocking Policy alerts for Overdose (including `mg/kg` ceiling),
///    Subtherapeutic Dose (`< min_mg_per_kg`), Renal Contraindication ("Avoid"),
///    and Allergies.
class SafetyCheckEngine {
  const SafetyCheckEngine._();

  /// Non-specific words that must never trigger a single-token match on their own.
  static const Set<String> _stopWords = {
    'mg',
    'ml',
    'tab',
    'tablet',
    'cap',
    'capsule',
    'syrup',
    'suspension',
    'susp',
    'oral',
    'high',
    'low',
    'dose',
    'acid',
    'sodium',
    'potassium',
    'calcium',
    'trihydrate',
    'hydrochloride',
    'hcl',
    'anti',
    'inflammatory',
    'and',
    'the',
    'for',
    'with',
  };

  /// Known valid drug/allergen concepts across the clinical domain so we can
  /// distinguish a known non-cross-reactive allergy (e.g. "Sulfa" when taking
  /// Paracetamol) from an unrecognized or gibberish allergy input (e.g. "in", "xyz123").
  static const Set<String> _knownGlobalAllergensAndDrugs = {
    'paracetamol',
    'acetaminophen',
    'apap',
    'tylenol',
    'sara',
    'พาราเซตามอล',
    'อะเซตามิโนเฟน',
    'ไทลีนอล',
    'ซาร่า',
    'amoxicillin',
    'amoxycillin',
    'amoxil',
    'moxilin',
    'อะม็อกซี่ซิลลิน',
    'อะม็อกซิลลิน',
    'penicillin',
    'penicillin g',
    'penicillin v',
    'เพนิซิลลิน',
    'ampicillin',
    'แอมพิซิลลิน',
    'amoxicillin-clavulanate',
    'augmentin',
    'co-amoxiclav',
    'ออกเมนติน',
    'piperacillin',
    'cloxacillin',
    'dicloxacillin',
    'cephalexin',
    'cefalexin',
    'keflex',
    'เซฟาเล็กซิน',
    'cefadroxil',
    'เซฟาดร็อกซิล',
    'cefaclor',
    'เซฟาคลอร์',
    'ceftriaxone',
    'cefdinir',
    'cefuroxime',
    'ibuprofen',
    'brufen',
    'nurofen',
    'ไอบูโพรเฟน',
    'บรูเฟน',
    'นูโรเฟน',
    'aspirin',
    'acetylsalicylic acid',
    'asa',
    'แอสไพริน',
    'naproxen',
    'นาพรอกเซน',
    'diclofenac',
    'voltaren',
    'ไดโคลฟีแนค',
    'โวลทาเรน',
    'mefenamic acid',
    'ponstan',
    'พอนสแตน',
    'indomethacin',
    'piroxicam',
    'meloxicam',
    'celecoxib',
    'etoricoxib',
    'warfarin',
    'marevan',
    'orfarin',
    'coumadin',
    'วาร์ฟาริน',
    'มาเรแวน',
    'ออร์ฟาริน',
    'isoniazid',
    'inh',
    'ไอโซไนอะซิด',
    'methotrexate',
    'mtx',
    'เมโทเทรกเซต',
    'allopurinol',
    'zyloprim',
    'อัลโลพิวรินอล',
    'enalapril',
    'renitec',
    'anapril',
    'อีนาลาพริล',
    'เรนิเทค',
    'sulfa',
    'sulfonamide',
    'cotrimoxazole',
    'bactrim',
    'ซัลฟา',
  };

  /// Validates patient and drug parameters before any mathematical calculation runs.
  /// Throws [InvalidPatientInputException] if any parameter is out of bounds.
  static void validatePatientInputs({
    required double weightKg,
    double? ageYears,
    double? crclMlMin,
    int? dosesPerDay,
    double? customDoseRateMgPerKg,
    double? concentrationMgPerMl,
  }) {
    if (weightKg.isNaN || weightKg.isInfinite || weightKg <= 0) {
      throw InvalidPatientInputException(
        field: 'weightKg',
        message:
            'น้ำหนักตัวผู้ป่วยต้องมีค่ามากกว่า 0 kg (ได้รับค่า: $weightKg kg)',
      );
    }

    if (ageYears != null &&
        (ageYears.isNaN || ageYears.isInfinite || ageYears < 0)) {
      throw InvalidPatientInputException(
        field: 'ageYears',
        message: 'อายุผู้ป่วยต้องไม่ติดลบ (ได้รับค่า: $ageYears ปี)',
      );
    }

    if (crclMlMin != null &&
        (crclMlMin.isNaN || crclMlMin.isInfinite || crclMlMin < 0)) {
      throw InvalidPatientInputException(
        field: 'crclMlMin',
        message:
            'ค่าการทำงานของไต (CrCl/eGFR) ต้องไม่ติดลบ (ได้รับค่า: $crclMlMin)',
      );
    }

    if (dosesPerDay != null && dosesPerDay <= 0) {
      throw InvalidPatientInputException(
        field: 'dosesPerDay',
        message:
            'จำนวนมื้อยาต่อวัน (dosesPerDay) ต้องมากกว่า 0 (ได้รับค่า: $dosesPerDay)',
      );
    }

    if (customDoseRateMgPerKg != null &&
        (customDoseRateMgPerKg.isNaN ||
            customDoseRateMgPerKg.isInfinite ||
            customDoseRateMgPerKg <= 0)) {
      throw InvalidPatientInputException(
        field: 'customDoseRateMgPerKg',
        message:
            'ขนาดยาตั้งต้น (mg/kg) ต้องมากกว่า 0 (ได้รับค่า: $customDoseRateMgPerKg)',
      );
    }

    if (concentrationMgPerMl != null &&
        (concentrationMgPerMl.isNaN ||
            concentrationMgPerMl.isInfinite ||
            concentrationMgPerMl <= 0)) {
      throw InvalidPatientInputException(
        field: 'concentrationMgPerMl',
        message:
            'ความเข้มข้นของยา (mg/mL) ต้องมากกว่า 0 (ได้รับค่า: $concentrationMgPerMl)',
      );
    }
  }

  /// Emits explicit `SafetyAlertSeverity.info` notices whenever age, renal function,
  /// or allergy history was not assessed (`null` / `notAssessed`), preventing silent
  /// clinical assumptions.
  static List<TransparentSafetyAlert> evaluateUnassessedInputs({
    required VerifiedDrugEntry drug,
    required double? ageYears,
    required double? crclMlMin,
    required AllergyAssessmentStatus allergyAssessmentStatus,
  }) {
    final notices = <TransparentSafetyAlert>[];
    final citation =
        '${drug.verificationMetadata.sourceName} (${drug.verificationMetadata.editionAndPage})';

    if (ageYears == null) {
      notices.add(
        TransparentSafetyAlert(
          type: SafetyAlertType.unassessedInputNotice,
          severity: SafetyAlertSeverity.info,
          title:
              'ℹ️ ไม่ได้ประเมินอายุผู้ป่วย (Age Not Assessed) — ข้ามการตรวจเกณฑ์อายุขั้นต่ำ (< ${drug.dosingRules.patientCriteria.minAgeMonths} เดือน)',
          message:
              'ไม่ได้ระบุอายุผู้ป่วย ระบบจึงไม่สามารถตรวจสอบเกณฑ์อายุขั้นต่ำของยานี้ (${drug.dosingRules.patientCriteria.minAgeMonths} เดือน) ได้โดยอัตโนมัติ',
          mechanism:
              'ยามีเกณฑ์อายุขั้นต่ำที่ต้องระวังในทารก (เช่น การทำงานของตับและไตยังพัฒนาไม่สมบูรณ์)',
          management:
              'โปรดระบุอายุผู้ป่วยเพื่อตรวจสอบเกณฑ์อายุขั้นต่ำและเลือกสมการประเมินค่าไต (Pediatric Schwartz vs Adult Cockcroft-Gault) ให้ถูกต้อง',
          reference: citation,
        ),
      );
    }

    if (crclMlMin == null) {
      notices.add(
        TransparentSafetyAlert(
          type: SafetyAlertType.unassessedInputNotice,
          severity: SafetyAlertSeverity.info,
          title:
              'ℹ️ ไม่ได้ประเมินค่าการทำงานของไต (Renal Function Not Assessed) — คำนวณโดยสมมติค่าไตปกติ',
          message:
              'ไม่ได้ระบุค่า CrCl/eGFR ระบบจึงคำนวณขนาดยาสำหรับผู้ป่วยที่มีการทำงานของไตปกติ (ตัวคูณ = 1.0, ความถี่ ${drug.dosingRules.frequencyHours})',
          mechanism:
              'หากผู้ป่วยมีภาวะไตเสื่อมที่ยังไม่ได้ตรวจ อาจเกิดการสะสมของยาหรือพิษต่อไตได้',
          management:
              'หากผู้ป่วยมีความเสี่ยงโรคไตหรืออยู่ในหอผู้ป่วยวิกฤต โปรดระบุค่า CrCl/eGFR เพื่อตรวจสอบตารางปรับขนาดยาตามไต',
          reference: citation,
        ),
      );
    }

    if (allergyAssessmentStatus == AllergyAssessmentStatus.notAssessed) {
      notices.add(
        TransparentSafetyAlert(
          type: SafetyAlertType.unassessedInputNotice,
          severity: SafetyAlertSeverity.info,
          title:
              'ℹ️ ยังไม่ได้ยืนยันประวัติแพ้ยา (Allergy Status Not Assessed)',
          message:
              'ยังไม่ได้ซักประวัติหรือยืนยันสถานะปฏิเสธแพ้ยา (NKDA) ของผู้ป่วย',
          mechanism:
              'การเว้นว่างช่องแพ้ยาโดยไม่ได้ยืนยัน NKDA อาจทำให้เกิดความเข้าใจผิดว่าผู้ป่วยไม่แพ้ยา',
          management:
              'โปรดซักประวัติแพ้ยาและเลือกสถานะ "ยืนยันปฏิเสธแพ้ยา (NKDA)" หรือระบุชื่อยาที่ผู้ป่วยแพ้ก่อนสั่งใช้ยา',
          reference: citation,
        ),
      );
    }

    return notices;
  }

  /// Evaluates patient allergies against drug synonyms and
  /// [VerifiedSafetyChecks.allergyCrossReactivity] using exact normalized matching,
  /// brand/Thai alias matching, and bounded Levenshtein-1 typo matching (`length >= 6`).
  ///
  /// Never uses loose substring `.contains()` so short inputs like `"in"` or `"a"`
  /// will NEVER falsely match `"Penicillin"`, `"Aspirin"`, or `"Warfarin"`.
  static AllergyEvaluationOutput evaluateAllergiesDetailed({
    required VerifiedDrugEntry drug,
    required List<String> patientAllergies,
  }) {
    final alerts = <TransparentSafetyAlert>[];
    final unrecognized = <String>[];
    if (patientAllergies.isEmpty) {
      return const AllergyEvaluationOutput(
        matchedAlerts: [],
        unrecognizedAllergies: [],
      );
    }

    final cleanedInputs = patientAllergies
        .map((a) => a.trim())
        .where((a) => a.isNotEmpty)
        .toList(growable: false);

    if (cleanedInputs.isEmpty) {
      return const AllergyEvaluationOutput(
        matchedAlerts: [],
        unrecognizedAllergies: [],
      );
    }

    final normalizedGeneric = drug.drugInfo.genericName.trim().toLowerCase();
    final rxnormId = drug.drugInfo.rxnormId.trim();
    final normalizedSynonyms = drug.drugInfo.synonyms
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty)
        .toList(growable: false);

    final matchedInputs = <String>{};
    final triggeredRules = <int>{};

    for (final rawInput in cleanedInputs) {
      final normInput = rawInput.toLowerCase();
      var matchedThisInput = false;

      for (var rIdx = 0;
          rIdx < drug.safetyChecks.allergyCrossReactivity.length;
          rIdx++) {
        final rule = drug.safetyChecks.allergyCrossReactivity[rIdx];
        String? matchedCrossAgent;

        for (final candidate in rule.crossReactiveAgents) {
          if (_matchesDrugIdentifier(normInput, candidate.trim().toLowerCase())) {
            matchedCrossAgent = candidate;
            break;
          }
        }

        if (matchedCrossAgent == null &&
            _matchesDrugIdentifier(
              normInput,
              rule.allergenGroup.trim().toLowerCase(),
            )) {
          matchedCrossAgent = rule.allergenGroup;
        }

        if (matchedCrossAgent != null) {
          matchedThisInput = true;
          matchedInputs.add(rawInput);
          if (triggeredRules.add(rIdx)) {
            final alertType = _mapAllergyMatchType(rule.matchType);
            final typeLabel = switch (alertType) {
              SafetyAlertType.allergySynonymMatch =>
                'แพ้ตัวยาเดิมชื่อพ้อง (Synonym / Identical Active Ingredient)',
              SafetyAlertType.allergySameClass =>
                'แพ้ยากลุ่มเดียวกัน (Same Pharmacological Class)',
              _ => 'แพ้ยาข้ามกลุ่ม (Cross-Reactivity)',
            };

            alerts.add(
              TransparentSafetyAlert(
                type: alertType,
                severity: SafetyAlertSeverity.contraindicated,
                title:
                    '🚨 แจ้งเตือน$typeLabel (${rule.riskLevel}): ${drug.drugInfo.genericName}',
                message:
                    'ผู้ป่วยมีประวัติแพ้ยา "$rawInput" ซึ่งตรงกับ "$matchedCrossAgent" ในกลุ่ม "${rule.allergenGroup}" (แสดงขนาดยาตามนโยบาย Non-Blocking พร้อมป้ายห้ามใช้สีแดง)',
                mechanism: rule.mechanism,
                management: rule.action,
                reference: rule.reference,
              ),
            );
          }
        }
      }

      // Check fallback against drug_info.genericName, rxnormId, or synonyms
      if (!matchedThisInput) {
        final matchesDrugDirectly =
            (rxnormId.isNotEmpty && normInput == rxnormId) ||
                _matchesDrugIdentifier(normInput, normalizedGeneric) ||
                normalizedSynonyms.any(
                  (syn) => _matchesDrugIdentifier(normInput, syn),
                );
        if (matchesDrugDirectly) {
          matchedThisInput = true;
          matchedInputs.add(rawInput);
          alerts.add(
            TransparentSafetyAlert(
              type: SafetyAlertType.allergySynonymMatch,
              severity: SafetyAlertSeverity.contraindicated,
              title:
                  '🚨 แจ้งเตือนแพ้ตัวยาเดิมชื่อพ้อง (Synonym Match - Contraindicated): ${drug.drugInfo.genericName}',
              message:
                  'ผู้ป่วยมีประวัติแพ้ยา "$rawInput" ซึ่งเป็นตัวยาสำคัญชนิดเดียวกันกับ ${drug.drugInfo.genericName}',
              mechanism:
                  'Direct hypersensitivity reaction to the identical chemical entity.',
              management:
                  'ห้ามใช้ยานี้เนื่องจากเป็นตัวยาสำคัญชนิดเดียวกันกับที่ผู้ป่วยแพ้',
              reference: drug.verificationMetadata.sourceName,
            ),
          );
        }
      }

      // If not matched to this drug's allergy rules, check if it's a recognized drug/allergen in our global dictionary
      if (!matchedThisInput) {
        final isKnownOtherAllergen = _knownGlobalAllergensAndDrugs.any(
          (known) => _matchesDrugIdentifier(normInput, known),
        );
        if (!isKnownOtherAllergen) {
          unrecognized.add(rawInput);
          alerts.add(
            TransparentSafetyAlert(
              type: SafetyAlertType.unrecognizedMedicationNotice,
              severity: SafetyAlertSeverity.moderate,
              title:
                  '⚠️ ไม่สามารถตรวจสอบประวัติแพ้ยา "$rawInput" ได้ (Unrecognized Allergen)',
              message:
                  'ชื่อยาหรือกลุ่มยาที่แพ้ "$rawInput" ไม่อยู่ในพจนานุกรมฐานข้อมูลที่ระบบรู้จัก จึงไม่สามารถตรวจสอบการแพ้ยาข้ามกลุ่มโดยอัตโนมัติได้ (ไม่ได้แปลว่าปลอดภัย)',
              mechanism:
                  'ข้อมูลที่กรอกอาจเป็นชื่อการค้าเฉพาะ การสะกดคำย่อ หรือตัวยานอกฐานข้อมูลปัจจุบัน',
              management:
                  'โปรดตรวจสอบโครงสร้างทางเคมีและกลุ่มยาของ "$rawInput" เทียบกับ ${drug.drugInfo.genericName} จากตำราเภสัชกรรมด้วยตนเองก่อนสั่งใช้ยา',
              reference: drug.verificationMetadata.sourceName,
            ),
          );
        }
      }
    }

    return AllergyEvaluationOutput(
      matchedAlerts: alerts,
      unrecognizedAllergies: unrecognized,
    );
  }

  /// Backwards-compatible helper returning all allergy alerts.
  static List<TransparentSafetyAlert> evaluateAllergies({
    required VerifiedDrugEntry drug,
    required List<String> patientAllergies,
  }) =>
      evaluateAllergiesDetailed(
        drug: drug,
        patientAllergies: patientAllergies,
      ).matchedAlerts;

  /// Evaluates concomitant medications against [VerifiedSafetyChecks.drugInteractions]
  /// using exact normalized matching, RxNorm RxCUI matching, Thai/trade alias matching,
  /// and bounded Levenshtein-1 typo matching (`length >= 6`).
  ///
  /// Any entered concomitant medication that is not covered by this drug's verified
  /// interaction table emits an explicit [SafetyAlertType.unrecognizedMedicationNotice]
  /// so the system never claims an unchecked drug combination is "Safe".
  static DdiEvaluationOutput evaluateDrugInteractionsDetailed({
    required VerifiedDrugEntry drug,
    required List<String> concomitantMedications,
  }) {
    final alerts = <TransparentSafetyAlert>[];
    final unrecognized = <String>[];
    if (concomitantMedications.isEmpty) {
      return const DdiEvaluationOutput(
        matchedAlerts: [],
        unrecognizedMedications: [],
      );
    }

    final cleanedMeds = concomitantMedications
        .map((m) => m.trim())
        .where((m) => m.isNotEmpty)
        .toList(growable: false);

    if (cleanedMeds.isEmpty) {
      return const DdiEvaluationOutput(
        matchedAlerts: [],
        unrecognizedMedications: [],
      );
    }

    final triggeredDdiIndices = <int>{};

    for (final rawMed in cleanedMeds) {
      final normMed = rawMed.toLowerCase();
      var matchedAnyDdi = false;

      for (var i = 0; i < drug.safetyChecks.drugInteractions.length; i++) {
        final ddi = drug.safetyChecks.drugInteractions[i];
        final targetDrug = ddi.interactingDrug.trim().toLowerCase();
        final targetRxnorm = ddi.interactingRxnormId.trim().toLowerCase();

        final matchesTarget =
            (targetRxnorm.isNotEmpty && normMed == targetRxnorm) ||
                _matchesDrugIdentifier(normMed, targetDrug) ||
                ddi.interactingDrugAliases.any(
                  (alias) =>
                      _matchesDrugIdentifier(normMed, alias.trim().toLowerCase()),
                );

        if (matchesTarget) {
          matchedAnyDdi = true;
          if (triggeredDdiIndices.add(i)) {
            alerts.add(
              TransparentSafetyAlert(
                type: SafetyAlertType.drugInteraction,
                severity: _parseDdiSeverity(ddi.severity),
                title:
                    '⚠️ ปฏิกิริยาระหว่างยา (DDI Severity: ${ddi.severity} — ${ddi.databaseSource}): ${drug.drugInfo.genericName} + ${ddi.interactingDrug}',
                message: ddi.clinicalEffect,
                mechanism: ddi.mechanism,
                management: ddi.management,
                reference: ddi.reference,
                databaseSource: ddi.databaseSource,
              ),
            );
          }
        }
      }

      if (!matchedAnyDdi) {
        unrecognized.add(rawMed);
        alerts.add(
          TransparentSafetyAlert(
            type: SafetyAlertType.unrecognizedMedicationNotice,
            severity: SafetyAlertSeverity.moderate,
            title:
                '⚠️ ไม่สามารถตรวจสอบปฏิกิริยาระหว่างยากับ "$rawMed" ได้ (Unverified Concomitant Drug)',
            message:
                'ยา "$rawMed" ไม่อยู่ในรายการปฏิกิริยาระหว่างยาที่ฐานข้อมูลของ ${drug.drugInfo.genericName} รองรับในขณะนี้ (ไม่ได้แปลว่าไม่มีปฏิกิริยาระหว่างยา)',
            mechanism:
                'ฐานข้อมูลของ ${drug.drugInfo.genericName} ตรวจสอบเฉพาะคู่ยาที่ระบุไว้ (${drug.safetyChecks.drugInteractions.map((d) => d.interactingDrug).join(", ")}) เท่านั้น',
            management:
                'โปรดตรวจสอบปฏิกิริยาระหว่าง ${drug.drugInfo.genericName} และ "$rawMed" ในฐานข้อมูล Lexicomp หรือ Micromedex ด้วยตนเอง',
            reference: drug.verificationMetadata.sourceName,
          ),
        );
      }
    }

    return DdiEvaluationOutput(
      matchedAlerts: alerts,
      unrecognizedMedications: unrecognized,
    );
  }

  /// Backwards-compatible helper returning all DDI alerts.
  static List<TransparentSafetyAlert> evaluateDrugInteractions({
    required VerifiedDrugEntry drug,
    required List<String> concomitantMedications,
  }) =>
      evaluateDrugInteractionsDetailed(
        drug: drug,
        concomitantMedications: concomitantMedications,
      ).matchedAlerts;

  /// Evaluates `dose_range` (`min_mg_per_kg_per_dose` & `max_mg_per_kg_per_dose`),
  /// `max_doses_per_day`, `max_daily_dose_mg_per_kg`, `max_single_dose_mg`, and
  /// `max_daily_dose_mg` in accordance with Ironclad Rule 5 (Non-Blocking Overdose Policy).
  static List<TransparentSafetyAlert> evaluateMaxDoseAlerts({
    required VerifiedDrugEntry drug,
    required double weightKg,
    required double effectiveDoseRateMgPerKg,
    required int requestedDosesPerDay,
    required double rawCalculatedSingleDoseMg,
    required double rawCalculatedDailyDoseMg,
    required double finalRecommendedSingleDoseMg,
    required double finalRecommendedDailyDoseMg,
    required double effectiveMaxSingleDoseMg,
    required double effectiveMaxDailyDoseMg,
  }) {
    final alerts = <TransparentSafetyAlert>[];
    final rules = drug.dosingRules;
    final range = rules.doseRange;
    final unitLabel =
        rules.formulaType.trim() == 'mg_per_kg_per_day' ? 'mg/kg/day' : 'mg/kg/dose';
    final citation =
        '${drug.verificationMetadata.sourceName} (${drug.verificationMetadata.editionAndPage})';

    // 1. Check subtherapeutic dose (< min_mg_per_kg_per_dose)
    if (effectiveDoseRateMgPerKg + 1e-9 < range.minMgPerKgPerDose) {
      alerts.add(
        TransparentSafetyAlert(
          type: SafetyAlertType.subtherapeuticDoseWarning,
          severity: SafetyAlertSeverity.moderate,
          title:
              '⚠️ ขนาดยาต่ำกว่าเกณฑ์ขั้นต่ำตามตำรา (Subtherapeutic Dose Warning: ${effectiveDoseRateMgPerKg.toStringAsFixed(2)} < ${range.minMgPerKgPerDose.toStringAsFixed(2)} $unitLabel)',
          message:
              'ขนาดยาตั้งต้น (${effectiveDoseRateMgPerKg.toStringAsFixed(2)} $unitLabel) ต่ำกว่าช่วงขนาดยาขั้นต่ำที่แนะนำตามตำรา (${range.minMgPerKgPerDose.toStringAsFixed(2)} - ${range.maxMgPerKgPerDose.toStringAsFixed(2)} $unitLabel)',
          mechanism:
              'การให้ยาต่ำกว่าขนาดรักษาขั้นต่ำ (Subtherapeutic Dose) อาจทำให้ผลการรักษาไม่เพียงพอ หรือเพิ่มความเสี่ยงเชื้อดื้อยาในกลุ่มยาปฏิชีวนะ',
          management:
              'แนะนำให้ใช้ขนาดยาในช่วง ${range.minMgPerKgPerDose.toStringAsFixed(1)} - ${range.maxMgPerKgPerDose.toStringAsFixed(1)} $unitLabel ยกเว้นกรณีปรับลดขนาดยาตามภาวะตับ/ไตบกพร่อง',
          reference: citation,
        ),
      );
    }

    // 2. Check customDosesPerDay > maxDosesPerDay
    if (requestedDosesPerDay > rules.maxDosesPerDay) {
      alerts.add(
        TransparentSafetyAlert(
          type: SafetyAlertType.frequencyExceedsMaxWarning,
          severity: SafetyAlertSeverity.major,
          title:
              '⚠️ จำนวนมื้อยาต่อวันเกินเกณฑ์สูงสุดตามตำรา ($requestedDosesPerDay มื้อ/วัน > สูงสุด ${rules.maxDosesPerDay} มื้อ/วัน)',
          message:
              'จำนวนมื้อยาที่ระบุ ($requestedDosesPerDay มื้อ/วัน) เกินความถี่สูงสุดที่กำหนดในตำรา (${rules.maxDosesPerDay} มื้อ/วัน, ${rules.frequencyHours}) ระบบจึงจำกัดจำนวนมื้อแนะนำไม่เกิน ${rules.maxDosesPerDay} มื้อ/วัน',
          mechanism:
              'การให้ยาถี่เกินระยะเวลาครึ่งชีวิตของยาทำให้เกิดการสะสมของยาในร่างกายและเพิ่มความเสี่ยงต่อพิษเฉียบพลัน',
          management:
              'ห้ามให้ยาเกิน ${rules.maxDosesPerDay} มื้อ/วัน (${rules.frequencyHours})',
          reference: citation,
        ),
      );
    }

    // 3. Check mg/kg ceiling, single dose ceiling, and daily dose ceiling
    final exceedsMgPerKg =
        effectiveDoseRateMgPerKg > range.maxMgPerKgPerDose + 1e-9;
    final exceedsSingle =
        rawCalculatedSingleDoseMg > effectiveMaxSingleDoseMg + 1e-9;
    final exceedsDaily =
        rawCalculatedDailyDoseMg > effectiveMaxDailyDoseMg + 1e-9;

    if (exceedsMgPerKg || exceedsSingle || exceedsDaily) {
      final details = <String>[
        if (exceedsMgPerKg)
          'ขนาดยาตามน้ำหนัก (${effectiveDoseRateMgPerKg.toStringAsFixed(2)} $unitLabel) > เพดานสูงสุดตามน้ำหนัก (${range.maxMgPerKgPerDose.toStringAsFixed(2)} $unitLabel)',
        if (exceedsSingle)
          'โดสตามน้ำหนักจริงต่อครั้ง (${rawCalculatedSingleDoseMg.toStringAsFixed(2)} mg) > เพดานสูงสุดต่อครั้ง (${effectiveMaxSingleDoseMg.toStringAsFixed(2)} mg)',
        if (exceedsDaily)
          'โดสรวมตามน้ำหนักจริงต่อวัน (${rawCalculatedDailyDoseMg.toStringAsFixed(2)} mg/day) > เพดานสูงสุดต่อวัน (${effectiveMaxDailyDoseMg.toStringAsFixed(2)} mg/day)',
      ].join(' | ');

      alerts.add(
        TransparentSafetyAlert(
          type: SafetyAlertType.overdoseWarning,
          severity: SafetyAlertSeverity.criticalOverdose,
          title:
              '⚠️ คำเตือน: ขนาดยานี้เกินเกณฑ์สูงสุดที่แนะนำ (Overdose Warning) — โปรดใช้ดุลยพินิจของแพทย์/เภสัชกรในการให้ยา',
          message:
              '$details — ระบบแสดงทั้งค่าที่คำนวณได้ตามน้ำหนักจริง (${rawCalculatedSingleDoseMg.toStringAsFixed(2)} mg/ครั้ง) และค่าที่ตัดเพดานปลอดภัย (${finalRecommendedSingleDoseMg.toStringAsFixed(2)} mg/ครั้ง, ${finalRecommendedDailyDoseMg.toStringAsFixed(2)} mg/วัน) ตามนโยบาย Non-Blocking Overdose Policy',
          mechanism:
              'ขนาดยาต่อกิโลกรัม น้ำหนักตัวผู้ป่วย หรือจำนวนมื้อต่อวันทำให้ขนาดยาทะลุเพดานสูงสุดตามตำรา (Ceiling Dose) ซึ่งเสี่ยงต่อพิษจากยาเกินขนาด',
          management:
              'แนะนำให้ใช้ขนาดยาไม่เกินเพดานสูงสุดตามตำรา (${finalRecommendedSingleDoseMg.toStringAsFixed(2)} mg/ครั้ง, ไม่เกิน ${effectiveMaxDailyDoseMg.toStringAsFixed(2)} mg/วัน) เว้นแต่อยู่ในภาวะฉุกเฉินภายใต้ดุลยพินิจของแพทย์/เภสัชกร',
          reference: citation,
        ),
      );
    }

    return alerts;
  }

  /// Evaluates renal adjustment alerts when CrCl/eGFR is provided.
  /// Under the Unified Non-Blocking Policy, even when `isContraindicated == true`
  /// ("Avoid"), the calculated dose remains visible alongside this red alert.
  static List<TransparentSafetyAlert> evaluateRenalAlert({
    required VerifiedDrugEntry drug,
    required double crclMlMin,
    required VerifiedRenalAdjustmentTier matchedTier,
  }) {
    final alerts = <TransparentSafetyAlert>[];
    final citation =
        '${drug.verificationMetadata.sourceName} (${drug.verificationMetadata.editionAndPage})';

    if (matchedTier.isContraindicated ||
        matchedTier.doseAdjustmentFactor == 0.0) {
      alerts.add(
        TransparentSafetyAlert(
          type: SafetyAlertType.renalAdjustment,
          severity: SafetyAlertSeverity.contraindicated,
          title:
              '🚨 ข้อห้ามใช้/หลีกเลี่ยงในผู้ป่วยค่าไตต่ำ (Avoid — ค่าไต ${crclMlMin.toStringAsFixed(2)} mL/min)',
          message: matchedTier.clinicalNote,
          mechanism:
              'ค่าการทำงานของไตอยู่ในช่วง ${matchedTier.crclMinMlMin.toStringAsFixed(1)} ถึง < ${matchedTier.crclMaxMlMin.toStringAsFixed(1)} ซึ่งมีความเสี่ยงสูงต่อภาวะไตวายเฉียบพลันหรือพิษสะสม',
          management:
              'คำแนะนำ: ${matchedTier.adjustedInterval} (${matchedTier.clinicalNote})',
          reference: citation,
        ),
      );
    } else if (matchedTier.doseAdjustmentFactor < 1.0 ||
        (matchedTier.adjustedDosesPerDay != null &&
            matchedTier.adjustedDosesPerDay !=
                drug.dosingRules.maxDosesPerDay) ||
        (matchedTier.adjustedDosesPerDay == null &&
            matchedTier.adjustedInterval != drug.dosingRules.frequencyHours)) {
      alerts.add(
        TransparentSafetyAlert(
          type: SafetyAlertType.renalAdjustment,
          severity: SafetyAlertSeverity.moderate,
          title:
              '⚠️ แนะนำปรับขนาดยา/ความถี่ตามค่าไต (ค่าไต ${crclMlMin.toStringAsFixed(2)} mL/min)',
          message: matchedTier.clinicalNote,
          mechanism:
              'การลดลงของอัตราการกรองของไต (ช่วง ${matchedTier.crclMinMlMin.toStringAsFixed(1)} ถึง < ${matchedTier.crclMaxMlMin.toStringAsFixed(1)}) ทำให้ค่าครึ่งชีวิตของยายาวนานขึ้น',
          management:
              'ปรับความถี่เป็น ${matchedTier.adjustedInterval} และตัวคูณขนาดยาต่อครั้ง = ${matchedTier.doseAdjustmentFactor}',
          reference: citation,
        ),
      );
    }

    return alerts;
  }

  /// Deterministic drug/allergen identifier matcher.
  ///
  /// Rules:
  /// 1. Exact full-string match after `.trim().toLowerCase()`.
  /// 2. Exact match against parenthetical base/inner name (e.g. `"aspirin (high-dose / anti-inflammatory)"` -> `"aspirin"`).
  /// 3. Exact match of a multi-word input token (`length >= 4`, not in `_stopWords`) against a single-word target.
  /// 4. Bounded Levenshtein edit distance `<= 1` ONLY when both strings are ASCII Latin words of `length >= 6`
  ///    (catches `"warfrin"` -> `"warfarin"` and `"amoxicilin"` -> `"amoxicillin"`, while rejecting `"in"` or `"a"`).
  static bool _matchesDrugIdentifier(String normInput, String normCandidate) {
    final a = normInput.trim().toLowerCase();
    final b = normCandidate.trim().toLowerCase();
    if (a.isEmpty || b.isEmpty) return false;

    if (a == b) return true;

    // Extract base name before '(' and inside '(...)' for candidates like "paracetamol (acetaminophen)"
    final bVariants = _extractCanonicalVariants(b);
    for (final variant in bVariants) {
      if (a == variant) return true;
      if (_isAsciiTypoMatch(a, variant)) return true;
    }

    // If user typed dosage strength alongside drug name (e.g. "warfarin 5mg"),
    // check individual meaningful tokens of length >= 4 that are not stop words,
    // but ONLY when the candidate variant itself is a single token (so "penicillin g"
    // does not match "penicillin v" via the shared word "penicillin").
    final inputTokens = a
        .split(RegExp(r'[\s,/()+;-]+'))
        .where((t) => t.length >= 4 && !_stopWords.contains(t))
        .toList(growable: false);

    if (inputTokens.length > 1) {
      for (final token in inputTokens) {
        for (final variant in bVariants) {
          if (!variant.contains(' ')) {
            if (token == variant || _isAsciiTypoMatch(token, variant)) {
              return true;
            }
          }
        }
      }
    }

    return false;
  }

  static Set<String> _extractCanonicalVariants(String raw) {
    final variants = <String>{raw};
    final parenMatch = RegExp(r'^([^()]+)\(([^()]+)\)').firstMatch(raw);
    if (parenMatch != null) {
      final before = parenMatch.group(1)!.trim();
      final inside = parenMatch.group(2)!.trim();
      if (before.isNotEmpty && !_stopWords.contains(before)) {
        variants.add(before);
      }
      if (inside.isNotEmpty &&
          !inside.contains('/') &&
          !_stopWords.contains(inside)) {
        variants.add(inside);
      }
    }
    return variants;
  }

  /// Allows Levenshtein distance == 1 ONLY for ASCII alphabetic words of length >= 6.
  static bool _isAsciiTypoMatch(String a, String b) {
    if (a.length < 6 || b.length < 6) return false;
    if ((a.length - b.length).abs() > 1) return false;
    final asciiWord = RegExp(r'^[a-z]+$');
    if (!asciiWord.hasMatch(a) || !asciiWord.hasMatch(b)) return false;
    // Require matching first character to prevent false cross-drug matches
    if (a.codeUnitAt(0) != b.codeUnitAt(0)) return false;
    return _levenshteinDistance(a, b) <= 1;
  }

  static int _levenshteinDistance(String s, String t) {
    final m = s.length;
    final n = t.length;
    var prev = List<int>.generate(n + 1, (j) => j);
    var curr = List<int>.filled(n + 1, 0);

    for (var i = 1; i <= m; i++) {
      curr[0] = i;
      for (var j = 1; j <= n; j++) {
        final cost = s.codeUnitAt(i - 1) == t.codeUnitAt(j - 1) ? 0 : 1;
        final deletion = prev[j] + 1;
        final insertion = curr[j - 1] + 1;
        final substitution = prev[j - 1] + cost;
        var minVal = deletion < insertion ? deletion : insertion;
        if (substitution < minVal) minVal = substitution;
        curr[j] = minVal;
      }
      final temp = prev;
      prev = curr;
      curr = temp;
    }
    return prev[n];
  }

  static SafetyAlertType _mapAllergyMatchType(String matchType) {
    switch (matchType.trim().toLowerCase()) {
      case 'synonym':
        return SafetyAlertType.allergySynonymMatch;
      case 'same_class':
        return SafetyAlertType.allergySameClass;
      case 'cross_reactivity':
      default:
        return SafetyAlertType.allergyCrossReactivity;
    }
  }

  static SafetyAlertSeverity _parseDdiSeverity(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'contraindicated':
        return SafetyAlertSeverity.contraindicated;
      case 'major':
        return SafetyAlertSeverity.major;
      case 'moderate':
        return SafetyAlertSeverity.moderate;
      case 'minor':
      default:
        return SafetyAlertSeverity.minor;
    }
  }
}
