import 'drug.dart';
import 'dose_limit.dart';


/// Clinical service detecting therapeutic duplication (identical molecules and
/// contraindicated same-class duplicates) and major peer-reviewed DDIs.
class TherapeuticDuplicationService {
  const TherapeuticDuplicationService._();

  /// Checks for therapeutic duplication between two prescribed drugs.
  /// Returns a [DoseWarning] if contraindicated duplication is detected, otherwise `null`.
  static DoseWarning? checkDuplication(Drug drugA, Drug drugB) {
    // 1. Identical Active Drug Duplication
    if (drugA.id.toLowerCase() == drugB.id.toLowerCase()) {
      return DoseWarning(
        severity: LimitSeverity.hard,
        code: DoseWarningCode.therapeuticDuplication,
        messageEn:
            'DUPLICATE ACTIVE DRUG: Patient is already prescribed ${drugB.genericName}. Prescribing the same drug concurrently risks accidental overdose.',
        messageTh:
            'การจ่ายยาซ้ำซ้อน: มีการสั่งใช้ยา ${drugB.genericName} ซ้ำซ้อน เสี่ยงต่อการได้รับยาเกินขนาด (Overdose)',
        clinicalAlternativesEn: [
          'Verify if order is an intended dose modification or continuation.',
          'Consolidate multiple orders of ${drugB.genericName} into a single validated regimen.',
        ],
        clinicalAlternativesTh: [
          'ตรวจสอบว่าเป็นการเปลี่ยนขนาดยาหรือคำสั่งยาซ้ำซ้อนโดยไม่ได้ตั้งใจ',
          'รวมคำสั่งใช้ยา ${drugB.genericName} ให้เป็นคำสั่งเดียวที่ได้รับการยืนยัน',
        ],
      );
    }

    final classA = drugA.effectiveDrugClass;
    final classB = drugB.effectiveDrugClass;
    if (classA == null || classB == null) return null;

    // 2. Dual Systemic NSAID Duplication
    if (classA == DrugClass.nsaid && classB == DrugClass.nsaid) {
      return DoseWarning(
        severity: LimitSeverity.hard,
        code: DoseWarningCode.therapeuticDuplication,
        messageEn:
            'THERAPEUTIC DUPLICATION (Contraindicated): Patient is already prescribed ${drugB.genericName} (NSAID). Concurrent use of multiple systemic NSAIDs is contraindicated due to additive risk of severe GI ulceration, hemorrhage, and acute kidney injury without added analgesia.',
        messageTh:
            'ข้อห้ามใช้จากการจ่ายยาซ้ำซ้อน: ผู้ป่วยได้รับยา ${drugB.genericName} (กลุ่ม NSAIDs) อยู่แล้ว ห้ามใช้ยาในกลุ่ม NSAIDs ร่วมกันเนื่องจากเพิ่มความเสี่ยงแผลในกระเพาะ เลือดออกรุนแรง และไตวายเฉียบพลัน โดยไม่เพิ่มประสิทธิภาพระงับปวด',
        clinicalAlternativesEn: [
          'Discontinue one NSAID and titrate the single agent to approved clinical maximum.',
          'Add non-NSAID analgesic (e.g. Paracetamol or appropriate adjunct) if pain relief inadequate.',
        ],
        clinicalAlternativesTh: [
          'หยุดใช้ยา NSAID ตัวใดตัวหนึ่ง และปรับขนาดยาตัวเดียวให้อยู่ในเกณฑ์เหมาะสม',
          'พิจารณาใช้พาราเซตามอลหรือยาแก้ปวดกลุ่มอื่นเสริมแทนการใช้ NSAID ซ้อนกัน',
        ],
      );
    }

    // 3. Dual RAS Blockade (ACE Inhibitor + ARB)
    final isRasA = classA == DrugClass.aceInhibitor || classA == DrugClass.arb;
    final isRasB = classB == DrugClass.aceInhibitor || classB == DrugClass.arb;
    if (isRasA && isRasB) {
      return DoseWarning(
        severity: LimitSeverity.hard,
        code: DoseWarningCode.therapeuticDuplication,
        messageEn:
            'THERAPEUTIC DUPLICATION (Contraindicated): Patient is already prescribed ${drugB.genericName} (${drugB.effectiveDrugClass?.nameEn}). Dual RAS Blockade (ACEI + ARB) is contraindicated due to increased risk of hyperkalemia, severe hypotension, and acute renal failure without clinical benefit.',
        messageTh:
            'ข้อห้ามใช้จากการจ่ายยาซ้ำซ้อน: มีการสั่งยากลุ่ม ACEI ร่วมกับ ARB (Dual RAS Blockade) ซึ่งเป็นข้อห้ามใช้เด็ดขาด เนื่องจากเพิ่มความเสี่ยงโพแทสเซียมในเลือดสูง ความดันตกวิกฤต และไตวายเฉียบพลัน',
        clinicalAlternativesEn: [
          'Select either ACE Inhibitor OR ARB monotherapy according to tolerability (e.g. switch to ARB if cough develops).',
          'Add calcium channel blocker or thiazide diuretic for additional blood pressure control.',
        ],
        clinicalAlternativesTh: [
          'เลือกใช้ยาเดี่ยวระหว่าง ACEI หรือ ARB เพียงตัวเดียว',
          'หากต้องการลดความดันเพิ่ม ให้เสริมด้วยยากลุ่ม CCB หรือยาขับปัสสาวะ Thiazide แทน',
        ],
      );
    }

    // 4. Dual Oral Anticoagulant Duplication (VKA + DOAC or DOAC + DOAC)
    final isOralOacA = classA == DrugClass.anticoagulantVka || classA == DrugClass.anticoagulantDoac;
    final isOralOacB = classB == DrugClass.anticoagulantVka || classB == DrugClass.anticoagulantDoac;
    if (isOralOacA && isOralOacB) {
      return DoseWarning(
        severity: LimitSeverity.hard,
        code: DoseWarningCode.therapeuticDuplication,
        messageEn:
            'THERAPEUTIC DUPLICATION (Contraindicated): Patient is already prescribed ${drugB.genericName} (Oral Anticoagulant). Concurrent use of multiple oral anticoagulants is contraindicated due to extreme risk of major or fatal hemorrhage.',
        messageTh:
            'ข้อห้ามใช้จากการจ่ายยาซ้ำซ้อน: ผู้ป่วยได้รับยา ${drugB.genericName} (ยาต้านการแข็งตัวของเลือด) อยู่แล้ว ห้ามใช้ยาต้านการแข็งตัวของเลือดชนิดรับประทานซ้ำซ้อนเนื่องจากเสี่ยงต่อภาวะเลือดออกรุนแรงถึงแก่ชีวิต',
        clinicalAlternativesEn: [
          'Confirm anticoagulation transition protocol if switching agents; discontinue previous oral anticoagulant.',
        ],
        clinicalAlternativesTh: [
          'หากเป็นการเปลี่ยนตัวยา ให้หยุดยาต้านการแข็งตัวของเลือดตัวเดิมทันทีก่อนเริ่มยาใหม่ตามโปรโตคอล',
        ],
      );
    }

    // 5. Dual Statin Duplication
    if (classA == DrugClass.statin && classB == DrugClass.statin) {
      return DoseWarning(
        severity: LimitSeverity.hard,
        code: DoseWarningCode.therapeuticDuplication,
        messageEn:
            'THERAPEUTIC DUPLICATION (Contraindicated): Concurrent use of multiple statins (${drugA.genericName} + ${drugB.genericName}) is contraindicated due to additive risk of severe myopathy and rhabdomyolysis.',
        messageTh:
            'ข้อห้ามใช้จากการจ่ายยาซ้ำซ้อน: การใช้ยากลุ่มสแตตินซ้ำซ้อน (${drugA.genericName} + ${drugB.genericName}) เพิ่มความเสี่ยงกล้ามเนื้อลายสลาย (Rhabdomyolysis) อย่างรุนแรง',
      );
    }

    // 6. Dual Potassium-Sparing Diuretic Duplication
    if (classA == DrugClass.potassiumSparingDiuretic && classB == DrugClass.potassiumSparingDiuretic) {
      return DoseWarning(
        severity: LimitSeverity.hard,
        code: DoseWarningCode.therapeuticDuplication,
        messageEn:
            'THERAPEUTIC DUPLICATION (Contraindicated): Concurrent use of multiple potassium-sparing diuretics (${drugA.genericName} + ${drugB.genericName}) is contraindicated due to high risk of life-threatening hyperkalemia.',
        messageTh:
            'ข้อห้ามใช้จากการจ่ายยาซ้ำซ้อน: การใช้ยาขับปัสสาวะประหยัดโพแทสเซียมซ้ำซ้อน เสี่ยงต่อภาวะโพแทสเซียมในเลือดสูงขั้นวิกฤต',
      );
    }

    // 7. Dual Heparin / LMWH Duplication
    if (classA == DrugClass.anticoagulantHeparin && classB == DrugClass.anticoagulantHeparin) {
      return DoseWarning(
        severity: LimitSeverity.hard,
        code: DoseWarningCode.therapeuticDuplication,
        messageEn:
            'THERAPEUTIC DUPLICATION (Contraindicated): Concurrent use of multiple parenteral anticoagulants (${drugA.genericName} + ${drugB.genericName}) is contraindicated due to severe bleeding risk.',
        messageTh:
            'ข้อห้ามใช้จากการจ่ายยาซ้ำซ้อน: การใช้ยาเฮพารินหรือ LMWH ซ้ำซ้อน (${drugA.genericName} + ${drugB.genericName}) เสี่ยงต่อภาวะเลือดออกรุนแรงถึงแก่ชีวิต',
      );
    }

    // 8. Dual Loop Diuretic Duplication
    if (classA == DrugClass.loopDiuretic && classB == DrugClass.loopDiuretic) {
      return DoseWarning(
        severity: LimitSeverity.hard,
        code: DoseWarningCode.therapeuticDuplication,
        messageEn:
            'THERAPEUTIC DUPLICATION (Contraindicated): Concurrent use of multiple loop diuretics (${drugA.genericName} + ${drugB.genericName}) is contraindicated due to severe volume depletion, electrolyte wasting, and acute kidney injury.',
        messageTh:
            'ข้อห้ามใช้จากการจ่ายยาซ้ำซ้อน: การใช้ยาขับปัสสาวะกลุ่ม Loop ซ้ำซ้อน (${drugA.genericName} + ${drugB.genericName}) เสี่ยงต่อภาวะขาดน้ำ เกลือแร่ผิดปกติรุนแรง และไตวายเฉียบพลัน',
      );
    }

    // 9. Dual SSRI Duplication
    if (classA == DrugClass.ssri && classB == DrugClass.ssri) {
      return DoseWarning(
        severity: LimitSeverity.hard,
        code: DoseWarningCode.therapeuticDuplication,
        messageEn:
            'THERAPEUTIC DUPLICATION (Contraindicated): Concurrent use of multiple SSRIs (${drugA.genericName} + ${drugB.genericName}) is contraindicated due to high risk of life-threatening Serotonin Syndrome.',
        messageTh:
            'ข้อห้ามใช้จากการจ่ายยาซ้ำซ้อน: การใช้ยาต้านเศร้ากลุ่ม SSRI ซ้ำซ้อน (${drugA.genericName} + ${drugB.genericName}) เสี่ยงต่อกลุ่มอาการเซโรโทนิน (Serotonin Syndrome) ขั้นวิกฤต',
      );
    }

    // 10. Dual Opioid Duplication (Systemic Agonists)
    if (classA == DrugClass.opioid && classB == DrugClass.opioid) {
      return DoseWarning(
        severity: LimitSeverity.hard,
        code: DoseWarningCode.therapeuticDuplication,
        messageEn:
            'THERAPEUTIC DUPLICATION: Concurrent use of multiple opioids (${drugA.genericName} + ${drugB.genericName}) significantly increases risk of fatal respiratory depression and severe sedation.',
        messageTh:
            'การจ่ายยาซ้ำซ้อน: การใช้ยาแก้ปวดกลุ่มโอปิออยด์ซ้ำซ้อน (${drugA.genericName} + ${drugB.genericName}) เพิ่มความเสี่ยงภาวะกดการหายใจขั้นวิกฤตและหมดสติ',
      );
    }

    // 11. Dual Benzodiazepine Duplication
    if (classA == DrugClass.benzodiazepine && classB == DrugClass.benzodiazepine) {
      return DoseWarning(
        severity: LimitSeverity.hard,
        code: DoseWarningCode.therapeuticDuplication,
        messageEn:
            'THERAPEUTIC DUPLICATION: Concurrent use of multiple benzodiazepines (${drugA.genericName} + ${drugB.genericName}) increases risk of severe sedation, ataxia, respiratory depression, and cognitive impairment.',
        messageTh:
            'การจ่ายยาซ้ำซ้อน: การใช้ยากลุ่มเบนโซไดอะซีปีนซ้ำซ้อน (${drugA.genericName} + ${drugB.genericName}) เพิ่มความเสี่ยงง่วงซึมรุนแรง กดการหายใจ และเสียการทรงตัว',
      );
    }

    // 12. Dual Beta-Blocker Duplication
    if (classA == DrugClass.betaBlocker && classB == DrugClass.betaBlocker) {
      return DoseWarning(
        severity: LimitSeverity.hard,
        code: DoseWarningCode.therapeuticDuplication,
        messageEn:
            'THERAPEUTIC DUPLICATION (Contraindicated): Concurrent use of multiple beta-blockers (${drugA.genericName} + ${drugB.genericName}) is contraindicated due to severe bradycardia, heart block, and profound hypotension.',
        messageTh:
            'ข้อห้ามใช้จากการจ่ายยาซ้ำซ้อน: การใช้ยากลุ่ม Beta-blocker ซ้ำซ้อน (${drugA.genericName} + ${drugB.genericName}) เสี่ยงต่อภาวะหัวใจเต้นช้าขั้นรุนแรง หัวใจหยุดเต้น และความดันตกวิกฤต',
      );
    }

    // 13. Dual PPI Duplication
    if (classA == DrugClass.protonPumpInhibitor && classB == DrugClass.protonPumpInhibitor) {
      return DoseWarning(
        severity: LimitSeverity.hard,
        code: DoseWarningCode.therapeuticDuplication,
        messageEn:
            'THERAPEUTIC DUPLICATION (Contraindicated): Concurrent use of multiple proton pump inhibitors (${drugA.genericName} + ${drugB.genericName}) provides no additive acid suppression and increases adverse event risks.',
        messageTh:
            'ข้อห้ามใช้จากการจ่ายยาซ้ำซ้อน: การใช้ยาลดกรดกลุ่ม PPI ซ้ำซ้อน (${drugA.genericName} + ${drugB.genericName}) ไม่เพิ่มประสิทธิภาพการยับยั้งกรด และเพิ่มความเสี่ยงอาการไม่พึงประสงค์',
      );
    }

    // 14. Dual Sulfonylurea Duplication
    if (classA == DrugClass.sulfonylurea && classB == DrugClass.sulfonylurea) {
      return DoseWarning(
        severity: LimitSeverity.hard,
        code: DoseWarningCode.therapeuticDuplication,
        messageEn:
            'THERAPEUTIC DUPLICATION (Contraindicated): Concurrent use of multiple sulfonylureas (${drugA.genericName} + ${drugB.genericName}) is contraindicated due to severe risk of prolonged, refractory hypoglycemia.',
        messageTh:
            'ข้อห้ามใช้จากการจ่ายยาซ้ำซ้อน: การใช้ยากลุ่มซัลโฟนิลยูเรียซ้ำซ้อน (${drugA.genericName} + ${drugB.genericName}) เสี่ยงต่อภาวะน้ำตาลในเลือดต่ำขั้นวิกฤตและยาวนาน',
      );
    }

    // 15. Dual DPP-4 Inhibitor Duplication
    if (classA == DrugClass.dpp4Inhibitor && classB == DrugClass.dpp4Inhibitor) {
      return DoseWarning(
        severity: LimitSeverity.hard,
        code: DoseWarningCode.therapeuticDuplication,
        messageEn:
            'THERAPEUTIC DUPLICATION (Contraindicated): Concurrent use of multiple DPP-4 inhibitors (${drugA.genericName} + ${drugB.genericName}) is contraindicated without additive glycemic benefit.',
        messageTh:
            'ข้อห้ามใช้จากการจ่ายยาซ้ำซ้อน: การใช้ยากลุ่ม DPP-4 inhibitor ซ้ำซ้อน (${drugA.genericName} + ${drugB.genericName}) ไม่มีประโยชน์เพิ่มและเป็นข้อห้ามใช้',
      );
    }

    // 16. Dual SGLT2 Inhibitor Duplication
    if (classA == DrugClass.sglt2Inhibitor && classB == DrugClass.sglt2Inhibitor) {
      return DoseWarning(
        severity: LimitSeverity.hard,
        code: DoseWarningCode.therapeuticDuplication,
        messageEn:
            'THERAPEUTIC DUPLICATION (Contraindicated): Concurrent use of multiple SGLT2 inhibitors (${drugA.genericName} + ${drugB.genericName}) is contraindicated due to additive risk of euglycemic DKA and volume depletion.',
        messageTh:
            'ข้อห้ามใช้จากการจ่ายยาซ้ำซ้อน: การใช้ยากลุ่ม SGLT2 inhibitor ซ้ำซ้อน (${drugA.genericName} + ${drugB.genericName}) เสี่ยงต่อภาวะเลือดเป็นกรด euglycemic DKA และขาดน้ำรุนแรง',
      );
    }

    // 17. Dual Thiazide Diuretic Duplication
    if (classA == DrugClass.thiazideDiuretic && classB == DrugClass.thiazideDiuretic) {
      return DoseWarning(
        severity: LimitSeverity.hard,
        code: DoseWarningCode.therapeuticDuplication,
        messageEn:
            'THERAPEUTIC DUPLICATION (Contraindicated): Concurrent use of multiple thiazide diuretics (${drugA.genericName} + ${drugB.genericName}) is contraindicated due to severe electrolyte wasting (hypokalemia, hyponatremia).',
        messageTh:
            'ข้อห้ามใช้จากการจ่ายยาซ้ำซ้อน: การใช้ยาขับปัสสาวะกลุ่ม Thiazide ซ้ำซ้อน (${drugA.genericName} + ${drugB.genericName}) เสี่ยงต่อภาวะโพแทสเซียมและโซเดียมในเลือดต่ำขั้นรุนแรง',
      );
    }

    return null;
  }
}

/// Peer-reviewed Drug-Drug Interaction Registry based on Lexicomp, Sanford Guide, and ACC/AHA standards.
class ClinicalInteractionRegistry {
  const ClinicalInteractionRegistry._();

  /// Evaluates major and contraindicated drug interactions between [currentDrug] and [activeDrug].
  static List<DoseWarning> checkInteractions(Drug currentDrug, Drug activeDrug) {
    final warnings = <DoseWarning>[];
    final curId = currentDrug.id.toLowerCase();
    final actId = activeDrug.id.toLowerCase();
    final curClass = currentDrug.effectiveDrugClass;
    final actClass = activeDrug.effectiveDrugClass;

    // 1. Methotrexate + NSAID (OAT inhibition & renal clearance impairment)
    final isMtxNsaid = (curId == 'methotrexate' && actClass == DrugClass.nsaid) ||
        (actId == 'methotrexate' && curClass == DrugClass.nsaid);
    if (isMtxNsaid) {
      warnings.add(const DoseWarning(
        severity: LimitSeverity.hard,
        code: DoseWarningCode.severeInteractionAlert,
        messageEn:
            'Major Interaction: Methotrexate renal elimination is reduced by NSAIDs via OAT1/3 and prostaglandin inhibition, markedly increasing risk of severe bone marrow suppression and nephrotoxicity.',
        messageTh:
            'ปฏิกิริยารุนแรง: ยากลุ่ม NSAIDs ยับยั้งการขับออกของ Methotrexate ทางไต ทำให้เกิดพิษกดไขกระดูกรุนแรงและไตวายเฉียบพลัน',
        clinicalAlternativesEn: [
          'Avoid concurrent NSAIDs with high/intermediate dose Methotrexate.',
          'Consider Paracetamol or low-dose adjunct analgesics under specialist monitoring.',
        ],
        clinicalAlternativesTh: [
          'หลีกเลี่ยงการใช้ NSAID ร่วมกับ Methotrexate',
          'พิจารณาใช้พาราเซตามอลแทนในการระงับปวด',
        ],
      ));
    }

    // 2. ACEI / ARB + Potassium-Sparing Diuretics (Hyperkalemia)
    final isAceSpiro = ((curClass == DrugClass.aceInhibitor || curClass == DrugClass.arb) &&
            actClass == DrugClass.potassiumSparingDiuretic) ||
        ((actClass == DrugClass.aceInhibitor || actClass == DrugClass.arb) &&
            curClass == DrugClass.potassiumSparingDiuretic);
    if (isAceSpiro) {
      warnings.add(DoseWarning(
        severity: LimitSeverity.soft,
        code: DoseWarningCode.severeInteractionAlert,
        messageEn:
            'Major Interaction: Concomitant ${currentDrug.genericName} and ${activeDrug.genericName} synergistically suppresses potassium excretion, risking severe Hyperkalemia and cardiac arrest.',
        messageTh:
            'ปฏิกิริยารุนแรง: การใช้ ${currentDrug.genericName} ร่วมกับ ${activeDrug.genericName} ลดการขับโพแทสเซียม เสี่ยงต่อภาวะโพแทสเซียมในเลือดสูง (Hyperkalemia) และหัวใจหยุดเต้น',
      ));
    }

    // 3. ACEI / ARB + NSAID (Hemodynamic AKI)
    final isAceNsaid = ((curClass == DrugClass.aceInhibitor || curClass == DrugClass.arb) &&
            actClass == DrugClass.nsaid) ||
        (curClass == DrugClass.nsaid &&
            (actClass == DrugClass.aceInhibitor || actClass == DrugClass.arb));
    if (isAceNsaid) {
      warnings.add(const DoseWarning(
        severity: LimitSeverity.soft,
        code: DoseWarningCode.severeInteractionAlert,
        messageEn:
            'Major Interaction: NSAIDs cause renal afferent vasoconstriction while ACEI/ARBs dilate efferent arterioles, causing acute decline in GFR (hemodynamic AKI).',
        messageTh:
            'ปฏิกิริยารุนแรง: การใช้ NSAID ร่วมกับ ACEI/ARB ทำให้แรงดันในไตลดลงเฉียบพลัน นำไปสู่ภาวะไตวายเฉียบพลัน',
      ));
    }

    // 4. Clopidogrel + Omeprazole / Esomeprazole (CYP2C19 inhibition)
    final isClopOme = (curId == 'clopidogrel' && (actId == 'omeprazole' || actId == 'esomeprazole')) ||
        (actId == 'clopidogrel' && (curId == 'omeprazole' || curId == 'esomeprazole'));
    if (isClopOme) {
      warnings.add(const DoseWarning(
        severity: LimitSeverity.soft,
        code: DoseWarningCode.severeInteractionAlert,
        messageEn:
            'Major Interaction: Omeprazole competitively inhibits CYP2C19, significantly impairing bioactivation of Clopidogrel and reducing antiplatelet protection.',
        messageTh:
            'ปฏิกิริยาระดับสำคัญ: Omeprazole ยับยั้งเอนไซม์ CYP2C19 ลดการเปลี่ยน Clopidogrel ไปเป็นรูปออกฤทธิ์ เพิ่มความเสี่ยงการเกิดลิ่มเลือดอุดตันซ้ำ',
        clinicalAlternativesEn: [
          'Switch to Pantoprazole, which has significantly less CYP2C19 inhibition.',
          'Consider H2-blockers (e.g. Famotidine) if gastric protection required.',
        ],
        clinicalAlternativesTh: [
          'เปลี่ยนไปใช้ Pantoprazole ซึ่งส่งผลต่อเอนไซม์ CYP2C19 น้อยกว่ามาก',
          'พิจารณาใช้ยาลดกรดกลุ่ม H2-blocker เช่น Famotidine แทน',
        ],
      ));
    }

    // 5. Statin + Strong CYP3A4 Macrolide Inhibitors (Simvastatin/Atorvastatin/Lovastatin + Clarithromycin/Erythromycin)
    const cyp3a4Statins = {'simvastatin', 'atorvastatin', 'lovastatin'};
    const cyp3a4Macrolides = {'clarithromycin', 'erythromycin'};

    final isCyp3a4StatinMacrolide =
        (cyp3a4Statins.contains(curId) && cyp3a4Macrolides.contains(actId)) ||
        (cyp3a4Statins.contains(actId) && cyp3a4Macrolides.contains(curId));

    if (isCyp3a4StatinMacrolide) {
      final statinName =
          cyp3a4Statins.contains(curId) ? currentDrug.genericName : activeDrug.genericName;
      final macrolideName =
          cyp3a4Macrolides.contains(curId) ? currentDrug.genericName : activeDrug.genericName;
      warnings.add(DoseWarning(
        severity: LimitSeverity.hard,
        code: DoseWarningCode.severeInteractionAlert,
        messageEn:
            'Contraindicated Interaction: $macrolideName strongly inhibits CYP3A4, markedly increasing $statinName exposure and triggering life-threatening rhabdomyolysis and acute renal failure.',
        messageTh:
            'ข้อห้ามใช้จากปฏิกิริยาระหว่างยา: $macrolideName ยับยั้งเอนไซม์ CYP3A4 อย่างรุนแรง ทำให้ระดับยา $statinName สูงขึ้นหลายเท่า เสี่ยงกล้ามเนื้อลายสลาย (Rhabdomyolysis) และไตวายเฉียบพลัน',
        clinicalAlternativesEn: [
          'Switch macrolide to Azithromycin (no significant CYP3A4 inhibition).',
          'Temporarily withhold $statinName during short-course macrolide antimicrobial therapy.',
        ],
        clinicalAlternativesTh: [
          'เปลี่ยนยาฆ่าเชื้อเป็น Azithromycin (ไม่ยับยั้ง CYP3A4)',
          'หยุดยา $statinName ชั่วคราวระหว่างการรับประทานยาฆ่าเชื้อ',
        ],
      ));
    }

    // 6. Digoxin + Amiodarone (P-gp inhibition)
    final isDigoxinAmio = (curId == 'digoxin' && actId == 'amiodarone') ||
        (curId == 'amiodarone' && actId == 'digoxin');
    if (isDigoxinAmio) {
      warnings.add(const DoseWarning(
        severity: LimitSeverity.hard,
        code: DoseWarningCode.severeInteractionAlert,
        messageEn:
            'Major Interaction: Amiodarone inhibits P-glycoprotein-mediated Digoxin elimination, doubling serum Digoxin concentrations and risking lethal digitalis toxicity.',
        messageTh:
            'ปฏิกิริยารุนแรง: อะมิโอดาโรนยับยั้งการขับออกของ Digoxin ทำให้ระดับยาในเลือดเพิ่มขึ้นเป็น 2 เท่า เสี่ยงพิษจาก Digoxin ที่เป็นอันตรายถึงชีวิต',
      ));
    }

    // 7. Anticoagulant (VKA/DOAC) + NSAID (Major GI Bleeding)
    final isAnticoagNsaid =
        ((curClass == DrugClass.anticoagulantVka || curClass == DrugClass.anticoagulantDoac) &&
                actClass == DrugClass.nsaid) ||
            ((actClass == DrugClass.anticoagulantVka || actClass == DrugClass.anticoagulantDoac) &&
                curClass == DrugClass.nsaid);
    if (isAnticoagNsaid) {
      warnings.add(const DoseWarning(
        severity: LimitSeverity.hard,
        code: DoseWarningCode.severeInteractionAlert,
        messageEn:
            'Major Interaction: Concomitant anticoagulant and NSAID markedly increases the risk of severe gastrointestinal ulceration and major hemorrhage. Avoid combination.',
        messageTh:
            'ปฏิกิริยารุนแรง: การใช้ยาต้านการแข็งตัวของเลือดร่วมกับ NSAIDs เพิ่มความเสี่ยงเลือดออกรุนแรงในทางเดินอาหารอย่างมาก ควรหลีกเลี่ยง',
        clinicalAlternativesEn: ['Use Paracetamol or topical analgesics for pain relief.'],
        clinicalAlternativesTh: ['ใช้พาราเซตามอลหรือยาทาภายนอกแทน'],
      ));
    }

    // 8. Potassium-Sparing Diuretics + Potassium Supplement (KCl) (Fatal Hyperkalemia)
    final isSpiroKcl =
        (curClass == DrugClass.potassiumSparingDiuretic &&
                (actId == 'potassium_chloride' || actId == 'kcl' || actId.contains('potassium'))) ||
            (actClass == DrugClass.potassiumSparingDiuretic &&
                (curId == 'potassium_chloride' || curId == 'kcl' || curId.contains('potassium')));
    if (isSpiroKcl) {
      warnings.add(const DoseWarning(
        severity: LimitSeverity.hard,
        code: DoseWarningCode.severeInteractionAlert,
        messageEn:
            'Contraindicated Interaction: Potassium-sparing diuretics combined with potassium supplements can produce rapid, fatal hyperkalemia.',
        messageTh:
            'ข้อห้ามใช้: การให้ยาขับปัสสาวะประหยัดโพแทสเซียมร่วมกับโพแทสเซียมเสริม เสี่ยงต่อภาวะโพแทสเซียมสูงวิกฤตจนหัวใจหยุดเต้น',
      ));
    }

    // 9. Lithium + NSAID / ACEI / ARB (Lithium Toxicity)
    final isLithiumNsaidOrRas =
        (curId == 'lithium' &&
                (actClass == DrugClass.nsaid ||
                    actClass == DrugClass.aceInhibitor ||
                    actClass == DrugClass.arb)) ||
            (actId == 'lithium' &&
                (curClass == DrugClass.nsaid ||
                    curClass == DrugClass.aceInhibitor ||
                    curClass == DrugClass.arb));
    if (isLithiumNsaidOrRas) {
      warnings.add(const DoseWarning(
        severity: LimitSeverity.hard,
        code: DoseWarningCode.severeInteractionAlert,
        messageEn:
            'Major Interaction: NSAIDs and ACEI/ARBs reduce renal lithium clearance by 20–40%, risking severe lithium toxicity.',
        messageTh:
            'ปฏิกิริยารุนแรง: ยากลุ่ม NSAIDs หรือ ACEI/ARB ลดการขับลิเทียมทางไต ทำให้ระดับลิเทียมสูงขึ้นจนเกิดพิษอันตราย',
      ));
    }

    return warnings;
  }
}
