// ============================================================================
// Clinical Decision & Pharmacist Sign-Off Domain Registry
// ============================================================================
// Pure Dart domain model and immutable catalog of pending clinical pharmacist
// judgment items in Drugph.
//
// ZERO Flutter UI dependency — pure deterministic domain logic.
//
// Reference Guidelines & Standards:
// - The Sanford Guide to Antimicrobial Therapy 2024
// - Lexicomp Clinical Drug Information 2024
// - AHA Pediatric Advanced Life Support (PALS) Guidelines 2020
// - World Allergy Organization (WAO) Anaphylaxis Guidelines 2020
// - Global Initiative for Asthma (GINA) 2023
// - Nicolau DP et al. Antimicrob Agents Chemother. 1995;39(3):650-655
// ============================================================================

/// Clinical specialty category for pending pharmacist determinations.
enum PendingDecisionCategory {
  antimicrobialStewardship(
    titleEn: 'Infectious Disease / Antimicrobial Stewardship',
    titleTh: 'โรคติดเชื้อและการกำกับการใช้ยาต้านจุลชีพ',
  ),
  emergencyResuscitation(
    titleEn: 'Emergency Medicine & Resuscitation',
    titleTh: 'เวชศาสตร์ฉุกเฉินและการกู้ชีพ',
  ),
  respiratoryAllergy(
    titleEn: 'Pediatric Respiratory & Allergy',
    titleTh: 'ระบบทางเดินหายใจและโรคภูมิแพ้ในเด็ก',
  ),
  pharmacokineticsTdm(
    titleEn: 'Therapeutic Drug Monitoring & Pharmacokinetics',
    titleTh: 'การตรวจติดตามระดับยาในเลือดและเภสัชจลนศาสตร์',
  );

  final String titleEn;
  final String titleTh;

  const PendingDecisionCategory({
    required this.titleEn,
    required this.titleTh,
  });
}

/// Administrative and clinical sign-off status for pending decisions.
enum PendingDecisionStatus {
  pendingPharmacistDecision(
    labelEn: 'Pending Clinical Pharmacist Determination',
    labelTh: 'รอการตัดสินใจทางคลินิกโดยเภสัชกร',
  ),
  underCommitteeReview(
    labelEn: 'Under Hospital P&T Committee Review',
    labelTh: 'อยู่ระหว่างการพิจารณาของคณะกรรมการ P&T',
  ),
  ratified(
    labelEn: 'Ratified Institutional Policy',
    labelTh: 'ผ่านการรับรองเป็นนโยบายโรงพยาบาลแล้ว',
  );

  final String labelEn;
  final String labelTh;

  const PendingDecisionStatus({
    required this.labelEn,
    required this.labelTh,
  });
}

/// A peer-reviewed candidate clinical option for resolving a pending decision.
class CandidateClinicalOption {
  /// Unique option key within the decision (e.g. 'optionA', 'optionB', 'optionC').
  final String id;

  /// Concise English title of this candidate approach.
  final String titleEn;

  /// Concise Thai title of this candidate approach.
  final String titleTh;

  /// Detailed English description of the clinical rule, formula, or ceiling.
  final String descriptionEn;

  /// Detailed Thai description of the clinical rule, formula, or ceiling.
  final String descriptionTh;

  /// Primary medical textbook, journal article, or clinical guideline citation.
  final String citation;

  /// Verbatim or translated excerpt from the cited reference.
  final String? guidelineExcerpt;

  /// Clinical, pharmacological, and safety rationale for this option.
  final String clinicalRationale;

  const CandidateClinicalOption({
    required this.id,
    required this.titleEn,
    required this.titleTh,
    required this.descriptionEn,
    required this.descriptionTh,
    required this.citation,
    this.guidelineExcerpt,
    required this.clinicalRationale,
  });
}

/// An open clinical decision requiring formal pharmacist sign-off.
class PendingClinicalDecision {
  /// Unique decision identifier (e.g. 'DEC-PND-001').
  final String id;

  /// Institutional decision tracking code (e.g. 'DEC-PND-001').
  final String decisionCode;

  /// English title summarizing the clinical decision topic.
  final String titleEn;

  /// Thai title summarizing the clinical decision topic.
  final String titleTh;

  /// Clinical specialty category.
  final PendingDecisionCategory category;

  /// Source repository file affected by this decision.
  final String targetFile;

  /// Identifiers of all drugs governed or impacted by this decision.
  final List<String> affectedDrugIds;

  /// English description of the clinical dilemma and conflicting evidence.
  final String clinicalDilemmaEn;

  /// Thai description of the clinical dilemma and conflicting evidence.
  final String clinicalDilemmaTh;

  /// English explanation of the active baseline behavior currently executing in Drugph.
  final String currentBaselineBehaviorEn;

  /// Thai explanation of the active baseline behavior currently executing in Drugph.
  final String currentBaselineBehaviorTh;

  /// List of candidate clinical options with citations and rationales.
  final List<CandidateClinicalOption> candidateOptions;

  /// Current review or sign-off status (defaults to pendingPharmacistDecision).
  final PendingDecisionStatus status;

  /// ID of the recommended baseline option (e.g. 'optionA').
  final String defaultOptionId;

  const PendingClinicalDecision({
    required this.id,
    required this.decisionCode,
    required this.titleEn,
    required this.titleTh,
    required this.category,
    required this.targetFile,
    required this.affectedDrugIds,
    required this.clinicalDilemmaEn,
    required this.clinicalDilemmaTh,
    required this.currentBaselineBehaviorEn,
    required this.currentBaselineBehaviorTh,
    required this.candidateOptions,
    this.status = PendingDecisionStatus.pendingPharmacistDecision,
    required this.defaultOptionId,
  });

  /// Retrieves the default candidate clinical option.
  CandidateClinicalOption get defaultOption =>
      candidateOptions.firstWhere((opt) => opt.id == defaultOptionId);
}

/// Immutable registry containing all 6 pending clinical pharmacist decisions in Drugph.
class PendingPharmacistRegistry {
  /// Total count of cataloged pending decisions.
  static int get count => allDecisions.length;

  /// Immutable list of all 6 pending clinical decisions.
  static const List<PendingClinicalDecision> allDecisions = [
    // ------------------------------------------------------------------------
    // 1. DEC-PND-001: Acyclovir IV HSV Encephalitis Dose Ceiling & Obesity
    // ------------------------------------------------------------------------
    PendingClinicalDecision(
      id: 'DEC-PND-001',
      decisionCode: 'DEC-PND-001',
      titleEn:
          'Acyclovir IV: HSV Encephalitis Dose Ceiling & Obesity Weight Metric',
      titleTh:
          'อะไซโคลเวียร์ฉีด (Acyclovir IV): เพดานขนาดยาโรคสมองอักเสบจากเริม และเกณฑ์น้ำหนักในผู้ป่วยอ้วน',
      category: PendingDecisionCategory.antimicrobialStewardship,
      targetFile: 'lib/data/drugs/antibiotics.dart',
      affectedDrugIds: ['acyclovir'],
      clinicalDilemmaEn:
          'The current regimen for IV Herpes Simplex Encephalitis (10 mg/kg q8h) in Drugph inherits an oral 800 mg maxSingleDose ceiling (an artifact of oral Zoster dosing). Consequently, any adult >= 85 kg receives an Overdose Warning (> 800 mg) even though therapeutic high-dose IV encephalitis treatment routinely requires 850–1000 mg doses. Furthermore, while specialNotes advises using Ideal Body Weight (IBW) in obese patients to prevent acyclovir crystallization nephropathy, the calculation engine currently uses Total Body Weight (TBW).',
      clinicalDilemmaTh:
          'สูตรการให้ยา Acyclovir IV ในภาวะ Herpes Simplex Encephalitis (10 mg/kg ทุก 8 ชม.) ในระบบ มีการตั้งเพดานขนาดยาสูงสุดต่อครั้ง (maxSingleDose) ไว้ที่ 800 mg ซึ่งเป็นตัวเลขของยารับประทาน (Oral Zoster) ทำให้ผู้ป่วยผู้ใหญ่ที่มีน้ำหนัก >= 85 kg ขึ้นไป ถูกแจ้งเตือนว่าได้รับยาเกินขนาด (Overdose) ทั้งที่ขนาดมาตรฐานในการรักษาต้องการยา 850-1000 mg/dose นอกจากนี้ ในหมายเหตุแนะนำให้ใช้ IBW ในคนอ้วน แต่สูตรคำนวณปัจจุบันยังใช้ TBW',
      currentBaselineBehaviorEn:
          'Calculates 10 mg/kg based on TBW. Enforces DoseLimit(maxSingleDose: 800.0 mg). Triggers DoseWarningCode.maxSingleDoseExceeded for patients >= 85 kg (e.g., 70 kg -> 700 mg ok; 90 kg -> 900 mg flagged as overdose). Does not auto-substitute IBW.',
      currentBaselineBehaviorTh:
          'คำนวณ 10 mg/kg โดยใช้น้ำหนักจริง (TBW) และมีเพดาน maxSingleDose 800.0 mg ทำให้คนไข้น้ำหนัก 85 kg ขึ้นไปติดเตือน Overdose (เช่น 70 kg ได้ 700 mg ปกติ, 90 kg ได้ 900 mg เตือน Overdose) และยังไม่มีการสลับเป็น IBW อัตโนมัติ',
      defaultOptionId: 'optionA',
      candidateOptions: [
        CandidateClinicalOption(
          id: 'optionA',
          titleEn:
              'Ideal Body Weight (IBW) for BMI >= 30 with 1,000 mg Max Single Dose',
          titleTh:
              'ใช้น้ำหนัก IBW เมื่อ BMI >= 30 และปรับเพดานยาฉีดสูงสุดเป็น 1,000 mg ต่อครั้ง',
          descriptionEn:
              'Use IBW (or TBW if TBW < IBW) when BMI >= 30 kg/m² to prevent renal crystal nephropathy; adjust IV maxSingleDose ceiling from 800 mg to 1,000 mg per single infusion.',
          descriptionTh:
              'ใช้น้ำหนัก IBW (หรือ TBW หากน้อยกว่า IBW) เมื่อผู้ป่วยมีค่า BMI >= 30 kg/m² เพื่อป้องกันผลึกยาอุดตันท่อไต และปรับเพดานยาฉีดต่อครั้งสูงสุดเป็น 1,000 mg',
          citation:
              'The Sanford Guide to Antimicrobial Therapy 2024; Lexicomp Drug Information 2024 (Acyclovir monograph); Turner RB et al. Pharmacotherapy. 2016;36(8):904-910',
          guidelineExcerpt:
              'Dosing weight in obesity: IBW is recommended for IV acyclovir in obese patients (BMI >= 30 kg/m²) because acyclovir distributes minimally into adipose tissue (Vd ~0.7 L/kg of IBW). Typical adult ceiling is 1000 mg q8h.',
          clinicalRationale:
              'Prevents acute crystal nephropathy in obese patients while permitting therapeutic CNS penetration up to 1,000 mg per dose without false-positive overdose warnings.',
        ),
        CandidateClinicalOption(
          id: 'optionB',
          titleEn:
              'Adjusted Body Weight (AdjBW 0.4) for Obese Patients with Removal of Oral Cap',
          titleTh:
              'ใช้น้ำหนักปรับค่า (AdjBW 0.4) ในผู้ป่วยอ้วน และยกเลิกเพดาน 800 mg ของยารับประทาน',
          descriptionEn:
              'Calculate dosing weight as IBW + 0.4 * (TBW - IBW) for patients with BMI >= 30 kg/m²; remove 800 mg oral cap and cap at 1,000 mg IV.',
          descriptionTh:
              'คำนวณขนาดยาโดยใช้ AdjBW = IBW + 0.4*(TBW-IBW) ในผู้ป่วย BMI >= 30 kg/m² และยกเลิกเพดาน 800 mg ของยากิน โดยตั้งเพดานยาฉีดที่ 1,000 mg',
          citation:
              'Pai MP, Nahata MC. Antimicrob Agents Chemother. 2010;54(12):5032-5037; Lexicomp Obesity Dosing Guidelines',
          guidelineExcerpt:
              'For hydrophilic drugs with slight lipophilicity distribution, AdjBW with 40% correction provides optimal AUC target attainment without excess peak concentrations.',
          clinicalRationale:
              'Accounts for partial extracellular fluid expansion in severe obesity while limiting toxic crystalluria risks.',
        ),
        CandidateClinicalOption(
          id: 'optionC',
          titleEn:
              'Total Body Weight (TBW) Dosing with Mandatory Hydration Warning (No Arbitrary Cap)',
          titleTh:
              'คำนวณตามน้ำหนักจริง (TBW) พร้อมคำเตือนบังคับให้สารน้ำ (ไม่กำหนดเพดานตายตัว)',
          descriptionEn:
              'Retain pure TBW dosing (10 mg/kg) without an arbitrary 800 mg or 1,000 mg single-dose cap; require clinical warning for aggressive IV hydration (>= 100 mL/hr) and renal function monitoring.',
          descriptionTh:
              'คงการคำนวณตามน้ำหนักจริง TBW (10 mg/kg) โดยไม่จำกัดเพดาน 800 mg หรือ 1,000 mg แต่แสดงคำเตือนทางคลินิกให้สารน้ำทางหลอดเลือดอย่างเพียงพอ (>= 100 mL/hr) และติดตามค่าไต',
          citation:
              'US FDA Prescribing Information: Zovirax (Acyclovir Sodium for Injection); Goodman & Gilman 14th ed.',
          guidelineExcerpt:
              'FDA label does not specify an absolute mg ceiling for IV acyclovir in severe HSV encephalitis; emphasizes slow infusion over 1 hr and adequate hydration to maintain urinary output.',
          clinicalRationale:
              'Prioritizes maximum viral suppression in life-threatening CNS infection where underdosing can lead to irreversible neurological damage or death.',
        ),
      ],
    ),

    // ------------------------------------------------------------------------
    // 2. DEC-PND-002: Atropine Pediatric Bradycardia Ceiling & Floor
    // ------------------------------------------------------------------------
    PendingClinicalDecision(
      id: 'DEC-PND-002',
      decisionCode: 'DEC-PND-002',
      titleEn:
          'Atropine Pediatric Bradycardia: Single-Dose Ceiling (0.5 mg) vs 0.1 mg Minimum Floor',
      titleTh:
          'อะโทรปีนในภาวะหัวใจเต้นช้าในเด็ก (Pediatric Bradycardia): เพดานขนาดยาต่อครั้ง (0.5 mg) และขนาดยาขั้นต่ำ (0.1 mg)',
      category: PendingDecisionCategory.emergencyResuscitation,
      targetFile: 'lib/data/drugs/emergency.dart',
      affectedDrugIds: ['atropine'],
      clinicalDilemmaEn:
          'In pediatric symptomatic bradycardia, AHA PALS recommends 0.02 mg/kg IV/IO. Historically, a minimum dose of 0.1 mg was mandated due to concern for paradoxical bradycardia with subtherapeutic doses. However, the 2020 AHA PALS Guidelines removed the 0.1 mg minimum dose recommendation based on lack of clinical evidence, while maintaining a single-dose ceiling of 0.5 mg for children (1.0 mg for adolescents). Drugph currently uses DoseLimit(minSingleDose: 0.1, maxSingleDose: 0.5) without an explicit doseCap property, flagging children > 25 kg as an Overdose Warning.',
      clinicalDilemmaTh:
          'การรักษาภาวะ Bradycardia ในเด็กตามแนวทาง PALS แนะนำให้ใช้ Atropine 0.02 mg/kg IV/IO ในอดีตเคยมีข้อกำหนดขนาดยาขั้นต่ำ 0.1 mg เพื่อป้องกันภาวะ Paradoxical Bradycardia แต่แนวทาง AHA PALS 2020 ได้ตัดคำแนะนำขนาดยาขั้นต่ำ 0.1 mg ออกเนื่องจากไม่มีหลักฐานเชิงประจักษ์ชัดเจน ขณะที่คงเพดานสูงสุดต่อครั้งไว้ที่ 0.5 mg ในเด็ก (1.0 mg ในวัยรุ่น) ใน Drugph ปัจจุบันกำหนด minSingleDose: 0.1 และ maxSingleDose: 0.5 แต่ยังไม่มีการใส่ doseCap ทำให้เด็กหนัก > 25 kg ติดเตือน Overdose',
      currentBaselineBehaviorEn:
          'Calculates 0.02 mg/kg. Limits define minSingleDose: 0.1 mg and maxSingleDose: 0.5 mg. For child > 25 kg (e.g. 30 kg), calculates 0.6 mg and triggers maxSingleDoseExceeded warning rather than auto-capping at 0.5 mg.',
      currentBaselineBehaviorTh:
          'คำนวณ 0.02 mg/kg โดยมี minSingleDose: 0.1 mg และ maxSingleDose: 0.5 mg หากเด็กหนัก > 25 kg (เช่น 30 kg) คำนวณได้ 0.6 mg และแจ้งเตือนขนาดยาเกินขนาด แทนที่จะตัดเพดาน (doseCap) ที่ 0.5 mg อัตโนมัติ',
      defaultOptionId: 'optionA',
      candidateOptions: [
        CandidateClinicalOption(
          id: 'optionA',
          titleEn:
              'PALS 2020 Standard: Set Explicit doseCap: 0.5 mg and Remove 0.1 mg Floor',
          titleTh:
              'มาตรฐาน PALS 2020: ตั้งเพดานขนาดยา doseCap: 0.5 mg และตัดเกณฑ์ขั้นต่ำ 0.1 mg ออก',
          descriptionEn:
              'Align with AHA PALS 2020: implement doseCap: 0.5 mg (maximum single child dose), remove minSingleDose: 0.1 mg restriction (infants < 5 kg receive exact 0.02 mg/kg).',
          descriptionTh:
              'ปรับตาม AHA PALS 2020: กำหนด doseCap: 0.5 mg สำหรับเด็ก และตัดเกณฑ์ขั้นต่ำ 0.1 mg ออกเพื่อให้ทารกน้ำหนัก < 5 kg ได้รับยา 0.02 mg/kg ตามสัดส่วนน้ำหนักจริง',
          citation:
              'American Heart Association (AHA) Pediatric Advanced Life Support (PALS) Guidelines 2020; Topjian AA et al. Circulation. 2020;142(16_suppl_2):S469-S523',
          guidelineExcerpt:
              'The previous recommendation for a minimum atropine dose of 0.1 mg has been removed from the 2020 PALS guidelines because clinical data do not support an increased risk of paradoxical bradycardia in infants receiving < 0.1 mg.',
          clinicalRationale:
              'Eliminates accidental relative overdosing in neonates/young infants while properly capping doses at 0.5 mg for older pediatric patients.',
        ),
        CandidateClinicalOption(
          id: 'optionB',
          titleEn:
              'Conservative APLS: Retain 0.1 mg Minimum Floor + Set doseCap: 0.5 mg',
          titleTh:
              'แนวทาง APLS: คงเกณฑ์ขั้นต่ำ 0.1 mg และตั้งเพดานขนาดยา doseCap: 0.5 mg',
          descriptionEn:
              'Maintain traditional safety floor minSingleDose: 0.1 mg to prevent central vagotonic paradoxical bradycardia; add explicit doseCap: 0.5 mg for patients > 25 kg.',
          descriptionTh:
              'คงเกณฑ์ขนาดยาขั้นต่ำ 0.1 mg ไว้เพื่อป้องกัน paradoxical bradycardia จากการกระตุ้น vagal nucleus ส่วนกลาง และตั้งเพดาน doseCap: 0.5 mg สำหรับเด็กหนัก > 25 kg',
          citation:
              'Advanced Paediatric Life Support (APLS UK) 6th ed.; Resuscitation Council UK (RCUK) Paediatric Guidelines',
          guidelineExcerpt:
              'Atropine dose: 20 mcg/kg (minimum dose 100 mcg, maximum single dose 500 mcg) IV/IO.',
          clinicalRationale:
              'Protects against paradoxical slowing in institutions adhering to UK/European resuscitation guidelines.',
        ),
        CandidateClinicalOption(
          id: 'optionC',
          titleEn:
              'Age-Stratified Ceiling: 0.5 mg (< 12 years) vs 1.0 mg (Adolescents >= 12 years)',
          titleTh:
              'แบ่งเพดานตามช่วงอายุ: 0.5 mg (เด็กอายุ < 12 ปี) และ 1.0 mg (วัยรุ่นอายุ >= 12 ปี)',
          descriptionEn:
              'Introduce age-based stratification: cap at 0.5 mg for pediatric patients < 12 years; permit up to 1.0 mg for adolescents >= 12 years (maximum total dose 3 mg).',
          descriptionTh:
              'จำแนกเพดานตามอายุ: จำกัดไม่เกิน 0.5 mg ในเด็กอายุ < 12 ปี และขยายเพดานเป็น 1.0 mg ในเด็กโต/วัยรุ่นอายุ >= 12 ปี (ขนาดยารวมสูงสุดไม่เกิน 3 mg)',
          citation:
              'Lexicomp Pediatric & Neonatal Dosage Handbook 30th ed. 2024; Nelson Textbook of Pediatrics 21st ed.',
          guidelineExcerpt:
              'Pediatric bradycardia: 0.02 mg/kg/dose; minimum dose 0.1 mg; maximum single dose: child 0.5 mg, adolescent 1 mg. May repeat once.',
          clinicalRationale:
              'Accommodates physiological divergence between school-age children and adult-sized adolescents.',
        ),
      ],
    ),

    // ------------------------------------------------------------------------
    // 3. DEC-PND-003: Dexamethasone Pediatric Croup Institutional Ceiling
    // ------------------------------------------------------------------------
    PendingClinicalDecision(
      id: 'DEC-PND-003',
      decisionCode: 'DEC-PND-003',
      titleEn:
          'Dexamethasone Pediatric Croup: Institutional Ceiling (10 mg vs 16 mg)',
      titleTh:
          'เดกซาเมทาโซนในโรคครูปในเด็ก (Pediatric Croup): เพดานขนาดยาสูงสุดของสถาบัน (10 mg เทียบกับ 16 mg)',
      category: PendingDecisionCategory.respiratoryAllergy,
      targetFile: 'lib/data/drugs/emergency.dart',
      affectedDrugIds: ['dexamethasone'],
      clinicalDilemmaEn:
          'Dexamethasone for pediatric croup (laryngotracheobronchitis) is recommended at 0.6 mg/kg PO/IM/IV single dose. In medical textbooks and hospital practice, the maximum single dose varies between 10 mg (recommended by RCH Melbourne, CPS, and many UK/Australian tertiary centers) and 16 mg (cited by Nelson Pediatrics, UpToDate, and Lexicomp). Drugph currently sets maxSingleDose: 10.0 mg, triggering an Overdose Warning for any child > 16.7 kg without auto-capping.',
      clinicalDilemmaTh:
          'การใช้ Dexamethasone ในโรคครูป (Croup) ในเด็ก แนะนำขนาดยา 0.6 mg/kg รับประทานหรือฉีดครั้งเดียว ตำราแพทย์และแนวทางปฏิบัติของโรงพยาบาลมีความแตกต่างกันระหว่างเพดานสูงสุด 10 mg (ตามแนวทาง RCH Melbourne, CPS แคนาดา) กับ 16 mg (ตาม Nelson Pediatrics, Lexicomp, UpToDate) ในระบบ Drugph ปัจจุบันตั้งค่า maxSingleDose: 10.0 mg ทำให้เด็กน้ำหนักเกิน 16.7 kg ติดเตือน Overdose โดยยังไม่ได้ตัดยอดขนาดยา (doseCap) ให้คงที่',
      currentBaselineBehaviorEn:
          'Calculates 0.6 mg/kg single dose. Enforces maxSingleDose: 10.0 mg. For a 20 kg child, calculates 12.0 mg and flags as overdose warning rather than capping at 10 mg or 16 mg.',
      currentBaselineBehaviorTh:
          'คำนวณ 0.6 mg/kg ครั้งเดียว โดยมี maxSingleDose: 10.0 mg ทำให้เด็กน้ำหนัก 20 kg คำนวณได้ 12.0 mg และติดเตือน Overdose แทนที่จะตัดยอดที่ 10 mg หรือ 16 mg',
      defaultOptionId: 'optionA',
      candidateOptions: [
        CandidateClinicalOption(
          id: 'optionA',
          titleEn: 'Institutional 10 mg Ceiling: Implement doseCap: 10.0 mg',
          titleTh: 'เพดานมาตรฐาน 10 mg: กำหนด doseCap: 10.0 mg',
          descriptionEn:
              'Set explicit doseCap: 10.0 mg and maxSingleDose: 10.0 mg for Croup; any child >= 16.7 kg receives exactly 10 mg without triggering an overdose alert.',
          descriptionTh:
              'กำหนด doseCap: 10.0 mg และ maxSingleDose: 10.0 mg สำหรับโรคครูป ทำให้เด็กที่มีน้ำหนัก >= 16.7 kg ได้รับยา 10 mg พอดีโดยไม่ขึ้นเตือน Overdose',
          citation:
              'Royal Children’s Hospital (RCH) Melbourne Clinical Practice Guidelines: Croup (2023); Canadian Paediatric Society (CPS) Position Statement; Thai Pediatric Respiratory Guidelines',
          guidelineExcerpt:
              'Dexamethasone 0.6 mg/kg orally as a single dose (maximum 10 mg). High-quality trial data demonstrate 10 mg achieves clinical cure equivalence to higher doses.',
          clinicalRationale:
              'Prevents excessive systemic corticosteroid exposure in toddlers and older children while achieving complete symptom resolution.',
        ),
        CandidateClinicalOption(
          id: 'optionB',
          titleEn:
              'Tertiary 16 mg Ceiling: Set doseCap: 16.0 mg and maxSingleDose: 16.0 mg',
          titleTh:
              'เพดานระดับตติยภูมิ 16 mg: กำหนด doseCap: 16.0 mg และ maxSingleDose: 16.0 mg',
          descriptionEn:
              'Increase single-dose ceiling to 16.0 mg and set doseCap: 16.0 mg, accommodating older children up to 26.7 kg before capping.',
          descriptionTh:
              'ปรับเพิ่มเพดานสูงสุดเป็น 16.0 mg และตั้ง doseCap: 16.0 mg เพื่อรองรับเด็กโตน้ำหนักถึง 26.7 kg ก่อนตัดยอด',
          citation:
              'Nelson Textbook of Pediatrics 21st ed.; Lexicomp Pediatric Dosage Handbook 2024; UpToDate: Management of Croup',
          guidelineExcerpt:
              'Dexamethasone 0.6 mg/kg single dose, maximum single dose 16 mg. Doses up to 16 mg are safe and well-tolerated in severe acute laryngotracheobronchitis.',
          clinicalRationale:
              'Adheres to North American tertiary pediatric references where 16 mg is standard practice for severe croup.',
        ),
        CandidateClinicalOption(
          id: 'optionC',
          titleEn:
              'Dual-Tier Dosing Regimen: 0.15 mg/kg (Mild-Moderate) vs 0.6 mg/kg (Severe)',
          titleTh:
              'สูตรสองระดับตามความรุนแรง: 0.15 mg/kg (เล็กน้อย-ปานกลาง) และ 0.6 mg/kg (รุนแรง)',
          descriptionEn:
              'Provide two distinct regimens in Drugph: low-dose 0.15 mg/kg (doseCap: 8.0 mg) for mild-to-moderate croup, and standard 0.6 mg/kg (doseCap: 10.0 mg) for severe croup.',
          descriptionTh:
              'แยกเป็น 2 สูตรในระบบ: ขนาดยาต่ำ 0.15 mg/kg (เพดาน 8.0 mg) สำหรับครูปเล็กน้อยถึงปานกลาง และขนาดมาตรฐาน 0.6 mg/kg (เพดาน 10.0 mg) สำหรับครูปรุนแรง',
          citation:
              'Cochrane Database of Systematic Reviews: Glucocorticoids for croup (Russell KF et al. 2018; CD001955)',
          guidelineExcerpt:
              'Low-dose dexamethasone (0.15 mg/kg) appears to be as effective as standard-dose dexamethasone (0.6 mg/kg) for mild-to-moderate croup.',
          clinicalRationale:
              'Allows clinician selection based on Westley Croup Score, minimizing steroid burden in outpatients.',
        ),
      ],
    ),

    // ------------------------------------------------------------------------
    // 4. DEC-PND-004: Epinephrine Pediatric Anaphylaxis Prepubertal Ceiling
    // ------------------------------------------------------------------------
    PendingClinicalDecision(
      id: 'DEC-PND-004',
      decisionCode: 'DEC-PND-004',
      titleEn:
          'Epinephrine Pediatric Anaphylaxis: Prepubertal Single-Dose Ceiling (0.3 mg vs 0.5 mg)',
      titleTh:
          'เอพิเนฟรินในภาวะแพ้รุนแรงในเด็ก (Pediatric Anaphylaxis): เพดานขนาดยาต่อครั้ง (0.3 mg เทียบกับ 0.5 mg)',
      category: PendingDecisionCategory.emergencyResuscitation,
      targetFile: 'lib/data/drugs/emergency.dart',
      affectedDrugIds: ['epinephrine'],
      clinicalDilemmaEn:
          'Intramuscular adrenaline (epinephrine 1:1,000) for anaphylaxis is dosed at 0.01 mg/kg. Guidelines differ on when the transition from pediatric maximum (0.3 mg) to adult maximum (0.5 mg) occurs. WAO and AAP recommend a 0.3 mg ceiling for prepubertal children (< 30 kg or < 12 years). However, EAACI and UK Resuscitation Council allow 0.5 mg for children >= 12 years or >= 36-50 kg. Currently, Drugph enforces maxSingleDose: 0.3 mg without explicit doseCap, triggering an Overdose Warning for any pediatric patient > 30 kg (e.g. 35 kg -> 0.35 mg).',
      clinicalDilemmaTh:
          'การฉีด Epinephrine (1:1,000) กล้ามเนื้อต้นขาในภาวะ Anaphylaxis ในเด็ก แนะนำขนาดยา 0.01 mg/kg แนวทางปฏิบัติสากลมีความแตกต่างกันในจุดเปลี่ยนผ่านระหว่างเพดานเด็ก (0.3 mg) กับเพดานผู้ใหญ่ (0.5 mg) โดย WAO และ AAP แนะนำเพดาน 0.3 mg ในเด็กก่อนวัยเจริญพันธุ์ (< 30 kg หรือ < 12 ปี) แต่ EAACI และ Resuscitation Council UK อนุญาตให้ขยายถึง 0.5 mg ในเด็กอายุ >= 12 ปี ในระบบ Drugph ปัจจุบันตั้งค่า maxSingleDose: 0.3 mg โดยไม่มี doseCap ทำให้เด็กหนัก > 30 kg ติดเตือน Overdose',
      currentBaselineBehaviorEn:
          'Calculates 0.01 mg/kg IM. Enforces maxSingleDose: 0.3 mg via DoseLimit. A 35 kg child calculates 0.35 mg and triggers an overdose alert instead of cleanly capping at 0.3 mg or 0.5 mg.',
      currentBaselineBehaviorTh:
          'คำนวณ 0.01 mg/kg ฉีดเข้ากล้ามเนื้อ โดยมี maxSingleDose: 0.3 mg หากเด็กหนัก 35 kg คำนวณได้ 0.35 mg และติดเตือน Overdose แทนที่จะตัดยอดเป็น 0.3 mg หรือ 0.5 mg ตามเกณฑ์',
      defaultOptionId: 'optionA',
      candidateOptions: [
        CandidateClinicalOption(
          id: 'optionA',
          titleEn: 'Prepubertal 0.3 mg Ceiling: Implement doseCap: 0.3 mg',
          titleTh: 'เพดานเด็ก 0.3 mg: กำหนด doseCap: 0.3 mg',
          descriptionEn:
              'Apply doseCap: 0.3 mg to Pediatric Anaphylaxis regimen; any child > 30 kg is capped at 0.3 mg IM without triggering an overdose warning.',
          descriptionTh:
              'กำหนด doseCap: 0.3 mg ในสูตร Pediatric Anaphylaxis ทำให้เด็กหนัก > 30 kg ได้รับยาที่ถูกตัดยอดเป็น 0.3 mg โดยไม่ขึ้นเตือน Overdose',
          citation:
              'World Allergy Organization (WAO) Anaphylaxis Guidelines 2020; American Academy of Pediatrics (AAP) Pediatric Anaphylaxis Policy; Thai Pediatric Allergy Association',
          guidelineExcerpt:
              'Epinephrine 0.01 mg/kg (1:1000) IM into mid-outer thigh, maximum single dose 0.3 mg in children up to prepubertal age / 30 kg.',
          clinicalRationale:
              'Prevents accidental sympathomimetic toxicity, arrhythmias, or hypertension in pediatric patients while guaranteeing lifesaving alpha-1/beta adrenergic effect.',
        ),
        CandidateClinicalOption(
          id: 'optionB',
          titleEn:
              'Weight-Stratified Transition: 0.3 mg (< 30 kg) vs 0.5 mg (>= 30 kg / Adolescent)',
          titleTh:
              'แบ่งเพดานตามเกณฑ์น้ำหนัก: 0.3 mg (< 30 kg) และ 0.5 mg (>= 30 kg หรือวัยรุ่น)',
          descriptionEn:
              'Configure two weight-stratified rules: cap at 0.3 mg for < 30 kg, and cap at 0.5 mg for >= 30 kg / adolescents (matching adult anaphylaxis ceiling).',
          descriptionTh:
              'กำหนดเกณฑ์ตามน้ำหนัก: ไม่เกิน 0.3 mg สำหรับเด็ก < 30 kg และไม่เกิน 0.5 mg สำหรับเด็ก >= 30 kg หรือวัยรุ่น (เทียบเท่าเพดานผู้ใหญ่)',
          citation:
              'European Academy of Allergy and Clinical Immunology (EAACI) Guidelines 2021; Resuscitation Council UK (RCUK) 2021',
          guidelineExcerpt:
              'Children 6-12 years (or 30-50 kg): 0.3 mg IM. Children > 12 years and adults: 0.5 mg IM.',
          clinicalRationale:
              'Provides adequate pharmacodynamic dosing for heavy or pubertal pediatric patients who have adult-like vascular volumes.',
        ),
        CandidateClinicalOption(
          id: 'optionC',
          titleEn: 'Auto-Injector Step-Dosing Tiers (0.1 / 0.15 / 0.3 / 0.5 mg)',
          titleTh:
              'ขนาดยาขั้นบันไดตามอุปกรณ์ฉีดอัตโนมัติ (0.1 / 0.15 / 0.3 / 0.5 mg)',
          descriptionEn:
              'Provide discrete practical step-doses mapped to auto-injector and syringe calibrations: 0.1 mg (7.5-10 kg), 0.15 mg (10-25 kg), 0.3 mg (25-50 kg), 0.5 mg (> 50 kg).',
          descriptionTh:
              'จัดขนาดยาเป็นขั้นบันไดที่สอดคล้องกับขนาดของ Epipen/เข็มฉีดยาจริง: 0.1 mg (7.5-10 kg), 0.15 mg (10-25 kg), 0.3 mg (25-50 kg), 0.5 mg (> 50 kg)',
          citation:
              'EAACI Anaphylaxis Guidelines 2021; Australasian Society of Clinical Immunology and Allergy (ASCIA) 2023',
          guidelineExcerpt:
              'Fixed step-dosing facilitates immediate administration without drawing up error in high-stress resuscitation environments.',
          clinicalRationale:
              'Eliminates measurement and volumetric calculation error in high-stress pediatric emergency situations.',
        ),
      ],
    ),

    // ------------------------------------------------------------------------
    // 5. DEC-PND-005: Salbutamol Pediatric Nebulizer Population & DoseCap
    // ------------------------------------------------------------------------
    PendingClinicalDecision(
      id: 'DEC-PND-005',
      decisionCode: 'DEC-PND-005',
      titleEn:
          'Salbutamol Pediatric Nebulizer: Population Criteria Filter (< 20 kg) & Single-Dose Cap (2.5 mg)',
      titleTh:
          'ซัลบูทามอลพ่นละอองในเด็ก (Pediatric Nebulizer): การกรองกลุ่มประชากร (< 20 kg) และเพดานขนาดยา (2.5 mg)',
      category: PendingDecisionCategory.respiratoryAllergy,
      targetFile: 'lib/data/drugs/respiratory.dart',
      affectedDrugIds: ['salbutamol'],
      clinicalDilemmaEn:
          'The nebulized salbutamol regimen in respiratory.dart indicates "Asthma / Wheezing (Pediatric < 20kg)" with dosePerKg: 0.15 mg/kg, minSingleDose: 1.25 mg, and maxSingleDose: 2.5 mg. However, it currently lacks an explicit PopulationCriteria(maxWeightKg: 20.0), allowing it to appear or be calculated for patients > 20 kg, where it immediately fires an Overdose Warning (e.g. 25 kg -> 3.75 mg vs 2.5 mg max). Furthermore, it lacks an explicit doseCap: 2.5 mg.',
      clinicalDilemmaTh:
          'สูตรยาพ่น Salbutamol ใน respiratory.dart ระบุข้อบ่งใช้ว่า "Asthma / Wheezing (Pediatric < 20kg)" โดยใช้ขนาด 0.15 mg/kg, minSingleDose: 1.25 mg, maxSingleDose: 2.5 mg แต่ในตัวโค้ดยังไม่มีการใส่ PopulationCriteria(maxWeightKg: 20.0) ทำให้สูตรนี้ถูกเรียกใช้ในผู้ป่วยน้ำหนัก > 20 kg ได้ และจะแจ้งเตือน Overdose ทันที (เช่น 25 kg ได้ 3.75 mg) อีกทั้งยังไม่มีการใส่ doseCap: 2.5 mg',
      currentBaselineBehaviorEn:
          'Calculates 0.15 mg/kg. Lacks PopulationCriteria filter. Enforces DoseLimit(minSingleDose: 1.25, maxSingleDose: 2.5). A 25 kg patient calculates 3.75 mg and triggers maxSingleDoseExceeded warning without capping at 2.5 mg.',
      currentBaselineBehaviorTh:
          'คำนวณ 0.15 mg/kg โดยไม่มีตัวกรอง PopulationCriteria และมี DoseLimit(min: 1.25, max: 2.5) หากคำนวณในผู้ป่วย 25 kg จะได้ 3.75 mg และติดเตือน Overdose โดยไม่มีการตัดยอดเป็น 2.5 mg',
      defaultOptionId: 'optionA',
      candidateOptions: [
        CandidateClinicalOption(
          id: 'optionA',
          titleEn:
              'Add PopulationCriteria(maxWeightKg: 20.0) and Explicit doseCap: 2.5 mg',
          titleTh:
              'เพิ่ม PopulationCriteria(maxWeightKg: 20.0) และกำหนด doseCap: 2.5 mg',
          descriptionEn:
              'Constrain regimen with population: PopulationCriteria(maxWeightKg: 20.0) and set doseCap: 2.5 mg; patients >= 16.7 kg are capped at 2.5 mg without overdose alert, and patients > 20 kg are directed to adult/older child fixed regimens.',
          descriptionTh:
              'จำกัดกลุ่มผู้ป่วยด้วย population: PopulationCriteria(maxWeightKg: 20.0) และใส่ doseCap: 2.5 mg ทำให้เด็กน้ำหนัก 16.7-20 kg ได้รับยาที่ถูกตัดยอดเป็น 2.5 mg พอดี และผู้ป่วยเกิน 20 kg จะต้องใช้สูตรของเด็กโต/ผู้ใหญ่',
          citation:
              'Global Initiative for Asthma (GINA) 2023; British Thoracic Society (BTS/SIGN) Asthma Guideline 2023; Thai Pediatric Asthma Clinical Practice Guidelines',
          guidelineExcerpt:
              'For children < 20 kg (or < 5 years): salbutamol 0.15 mg/kg/dose (minimum 1.25 mg, maximum 2.5 mg). For children >= 20 kg: 2.5 to 5 mg per nebulization.',
          clinicalRationale:
              'Aligns code constraints with clinical indication text, preventing inappropriate selection for older children while properly capping toddlers.',
        ),
        CandidateClinicalOption(
          id: 'optionB',
          titleEn:
              'Dual Weight-Tier Regimens in respiratory.dart (< 20 kg vs >= 20 kg)',
          titleTh:
              'สร้าง 2 สูตรแยกตามน้ำหนักใน respiratory.dart (< 20 kg และ >= 20 kg)',
          descriptionEn:
              'Split into two explicit regimens: (1) Pediatric < 20 kg at 0.15 mg/kg (doseCap: 2.5 mg), and (2) Pediatric >= 20 kg / Adult at fixed 5.0 mg nebulization (doseCap: 5.0 mg).',
          descriptionTh:
              'แยกเป็น 2 สูตรชัดเจน: (1) เด็ก < 20 kg ขนาด 0.15 mg/kg (เพดาน 2.5 mg) และ (2) เด็ก >= 20 kg / ผู้ใหญ่ ขนาดคงที่ 5.0 mg พ่นฝอย (เพดาน 5.0 mg)',
          citation:
              'National Heart, Lung, and Blood Institute (NHLBI) EPR-3 Asthma Guidelines; Lexicomp Pediatric',
          guidelineExcerpt:
              'Nebulized albuterol: Children < 20 kg: 0.15 mg/kg (min 1.25 mg, max 2.5 mg); Children >= 20 kg and adults: 2.5 to 5 mg q20min for 3 doses.',
          clinicalRationale:
              'Provides seamless bedside coverage for all pediatric and adolescent weight ranges within the same drug monograph.',
        ),
        CandidateClinicalOption(
          id: 'optionC',
          titleEn:
              'Universal Fixed 2.5 mg Nebulization for All Children >= 1 Year',
          titleTh:
              'ใช้ขนาดยาคงที่ 2.5 mg พ่นละอองสำหรับเด็กอายุ >= 1 ปีทุกคน',
          descriptionEn:
              'Simplify to standard fixed unit-dose vial: 2.5 mg nebulized for all children >= 1 year regardless of weight, reserving weight-based dosing for neonates < 1 year.',
          descriptionTh:
              'ปรับให้เรียบง่ายโดยใช้หลอดยามาตรฐานขนาดยาคงที่ 2.5 mg พ่นสำหรับเด็กทุกคนที่อายุ >= 1 ปี โดยสำรองการคำนวณตามน้ำหนักไว้สำหรับทารก < 1 ปีเท่านั้น',
          citation:
              'Royal Children’s Hospital (RCH) Melbourne Asthma Clinical Practice Guidelines 2023; BNF for Children (BNFC) 2023-2024',
          guidelineExcerpt:
              'Nebulised salbutamol: Child 1 month-4 years: 2.5 mg; Child 5-11 years: 2.5 to 5 mg; Child 12-17 years: 5 mg. Fixed ampoules eliminate dilution and dosing errors.',
          clinicalRationale:
              'Minimizes nursing medication preparation errors by using pre-packaged 2.5 mg/2.5 mL unit-dose nebules.',
        ),
      ],
    ),

    // ------------------------------------------------------------------------
    // 6. DEC-PND-006: Hartford Nomogram Coordinates & Vancomycin Vd Models
    // ------------------------------------------------------------------------
    PendingClinicalDecision(
      id: 'DEC-PND-006',
      decisionCode: 'DEC-PND-006',
      titleEn:
          'Hartford Nomogram Digitization & Vancomycin Vd Clinical Distribution Models',
      titleTh:
          'การแปลงเส้นแบ่งโซนของ Hartford Nomogram และแบบจำลองปริมาตรการกระจายตัว (Vd) ของ Vancomycin',
      category: PendingDecisionCategory.pharmacokineticsTdm,
      targetFile: 'lib/core/calculators/tdm_calculator.dart',
      affectedDrugIds: [
        'gentamicin',
        'tobramycin',
        'amikacin',
        'vancomycin',
      ],
      clinicalDilemmaEn:
          'In tdm_calculator.dart, the Hartford Nomogram for once-daily aminoglycoside dosing (7 mg/kg) uses linear boundary approximations entered during early development: '
          '(q24h/q36h: 9.0 to 2.0 mg/L; q36h/q48h: 11.0 to 4.5 mg/L; q48h upper: 13.0 to 7.0 mg/L between 6h and 14h). '
          'These linear slopes have not been mathematically checked against the original curved figure of Nicolau et al. 1995. The UI currently displays a prominent warning badge (Key("tdm_hartford_pending_verification")). '
          'In addition, Vancomycin Vd model options in tdm_calculator.dart offer standard adult (0.70 L/kg), obesity (0.52 L/kg), and ICU/septic fluid expansion (0.85 L/kg) which require explicit pharmacokinetic literature backing and validation.',
      clinicalDilemmaTh:
          'ใน tdm_calculator.dart การประเมิน Hartford Nomogram สำหรับ Aminoglycoside ขนาด 7 mg/kg วันละครั้ง ใช้สมการเส้นตรงโดยประมาณที่ผู้พัฒนาใส่ไว้เบื้องต้น '
          '(เส้นแบ่ง q24h/q36h: 9.0 ถึง 2.0 mg/L; q36h/q48h: 11.0 ถึง 4.5 mg/L; ขอบบน q48h: 13.0 ถึง 7.0 mg/L ระหว่าง 6 ถึง 14 ชม.) '
          'ซึ่งสมการเส้นตรงนี้ยังไม่ได้รับการตรวจสอบเทียบพิกัดจุดกับกราฟต้นฉบับของ Nicolau et al. 1995 โดยเภสัชกร หน้าจอ UI จึงต้องแสดงแถบเตือนสีส้ม (Key("tdm_hartford_pending_verification")) ไว้เสมอ '
          'นอกจากนี้ ค่า Vd ของ Vancomycin สำหรับคนอ้วน (0.52 L/kg) และผู้ป่วยวิกฤต ICU (0.85 L/kg) จำเป็นต้องมีหลักฐานทางเภสัชจลนศาสตร์รองรับอย่างชัดเจน',
      currentBaselineBehaviorEn:
          'Evaluates 7 mg/kg Hartford nomogram via linear boundary interpolation dt = hoursPostDose - 6.0: q24Boundary = 9.0 - (7.0/8.0)*dt; q36Boundary = 11.0 - (6.5/8.0)*dt; q48Boundary = 13.0 - (6.0/8.0)*dt. Displays warning banner "tdm_hartford_pending_verification" in TdmScreen. Vancomycin Vd factors are 0.70, 0.52, and 0.85 L/kg.',
      currentBaselineBehaviorTh:
          'คำนวณ Hartford Nomogram 7 mg/kg โดยใช้สมการเส้นตรง dt = hoursPostDose - 6.0: q24Boundary = 9.0 - (7.0/8.0)*dt; q36Boundary = 11.0 - (6.5/8.0)*dt; q48Boundary = 13.0 - (6.0/8.0)*dt และแสดงแถบเตือนสีส้ม "tdm_hartford_pending_verification" ในหน้า TdmScreen ตลอดเวลา ส่วน Vancomycin Vd ใช้ค่า 0.70, 0.52, และ 0.85 L/kg',
      defaultOptionId: 'optionA',
      candidateOptions: [
        CandidateClinicalOption(
          id: 'optionA',
          titleEn:
              'Ratify Linear Hartford Approximation with Verified Pharmacist Coordinates + Standard Vd Literature',
          titleTh:
              'รับรองสมการเส้นตรงของ Hartford พร้อมตรวจพิกัดโดยเภสัชกร + บันทึกหลักฐาน Vd มาตรฐาน',
          descriptionEn:
              'Formally audit and verify the linear boundary approximations against Nicolau 1995; document pharmacokinetic citations for Vancomycin Vd 0.52 L/kg (Blouin 1982, Bauer 2008) and 0.85 L/kg in sepsis (Revilla 2010, Roberts 2011); retain active warning until final P&T sign-off.',
          descriptionTh:
              'ตรวจรับรองความถูกต้องของสมการเส้นตรงเทียบกับกราฟ Nicolau 1995 โดยเภสัชกร พร้อมบันทึกเอกสารอ้างอิงของ Vancomycin Vd 0.52 L/kg (Blouin 1982, Bauer 2008) และ 0.85 L/kg ในภาวะติดเชื้อกระแสเลือด (Revilla 2010, Roberts 2011) โดยคงแถบเตือนไว้จนกว่าจะมีการลงนามสมบูรณ์',
          citation:
              'Nicolau DP, Freeman CD, Belliveau PP, et al. Antimicrob Agents Chemother. 1995;39(3):650-655; Blouin RA et al. Antimicrob Agents Chemother. 1982;21(4):575-580; Roberts JA et al. Crit Care Med. 2011;39(6):1326-1331',
          guidelineExcerpt:
              'Nicolau 1995 Hartford nomogram boundaries: 7 mg/kg dose plotted 6 to 14 hours post-dose. Vancomycin Vd in non-obese adults is 0.7 L/kg; in obesity, lipophilic partitioning is low, yielding 0.4-0.55 L/kg of total weight; in septic capillary leak, Vd expands to 0.8-1.0 L/kg.',
          clinicalRationale:
              'Maintains current mathematical continuity and zero test regression while providing authentic pharmacokinetic literature justification.',
        ),
        CandidateClinicalOption(
          id: 'optionB',
          titleEn:
              'Nonlinear High-Precision Polynomial Digitize of Nicolau Curves + Dynamic AdjBW Vd',
          titleTh:
              'แปลงเส้นโค้งด้วยสมการพหุนามความแม่นยำสูงจาก Nicolau 1995 + คำนวณ Vd แบบไดนามิกตาม AdjBW',
          descriptionEn:
              'Replace linear equations with 2nd-order polynomial fits extracted directly from the published Nicolau 1995 graphic; calculate Vancomycin Vd dynamically as 0.70 L/kg of Adjusted Body Weight (AdjBW 0.4) in obesity.',
          descriptionTh:
              'แทนที่สมการเส้นตรงด้วยสมการ polynomial กำลังสองที่ถอดจากกราฟต้นฉบับ Nicolau 1995 และปรับการคำนวณ Vd ของ Vancomycin ในคนอ้วนเป็น 0.70 L/kg ของ AdjBW 0.4 แบบไดนามิก',
          citation:
              'Nicolau DP et al. 1995; Rybak MJ et al. Therapeutic monitoring of vancomycin: A consensus review. Am J Health-Syst Pharm. 2020;77(11):835-864',
          guidelineExcerpt:
              '2020 Consensus Guidelines recommend AUC-guided dosing and individual pharmacokinetic modeling, with Vd adjusted for fat-free mass in obesity.',
          clinicalRationale:
              'Eliminates subtle 0.1-0.3 mg/L boundary errors near the 6-hour and 14-hour extremes of the Hartford chart.',
        ),
        CandidateClinicalOption(
          id: 'optionC',
          titleEn:
              'Mandatory Sawchuk-Zaske 2-Point Kinetic Confirmation for Non-q24h Intervals',
          titleTh:
              'บังคับตรวจระดับยา 2 จุด (Sawchuk-Zaske) เมื่อตกนอกโซน q24h หรือในผู้ป่วย ICU/อ้วน',
          descriptionEn:
              'Require Sawchuk-Zaske 2-point post-distribution pharmacokinetic calculation whenever a level falls into q36h, q48h, or off-nomogram, rather than relying on empirical interval extensions alone.',
          descriptionTh:
              'กำหนดให้ต้องเจาะเลือดตรวจ 2 จุดเพื่อคำนวณเภสัชจลนศาสตร์แบบ Sawchuk-Zaske เมื่อผลตกอยู่ในโซน q36h, q48h หรือเกินเกณฑ์ แทนที่จะขยายรอบการให้ยาตามการคาดเดาเพียงอย่างเดียว',
          citation:
              'The Sanford Guide to Antimicrobial Therapy 2024; Murphy JE. Clinical Pharmacokinetics 6th ed. (ASHP 2017)',
          guidelineExcerpt:
              'Once-daily aminoglycoside nomograms are intended for patients with normal or mildly impaired renal function. In severe instability or off-nomogram points, individual elimination rate constant (ke) calculation is mandatory.',
          clinicalRationale:
              'Maximizes clinical safety and avoids toxicity or therapeutic failure in patients with rapidly shifting renal clearance.',
        ),
      ],
    ),
  ];

  /// Finds a pending decision by its ID or decision code (e.g. 'DEC-PND-001').
  static PendingClinicalDecision? findById(String id) {
    final needle = id.trim().toUpperCase();
    for (final decision in allDecisions) {
      if (decision.id.toUpperCase() == needle ||
          decision.decisionCode.toUpperCase() == needle) {
        return decision;
      }
    }
    return null;
  }

  /// Filters decisions by specialty category.
  static List<PendingClinicalDecision> getByCategory(
      PendingDecisionCategory category) {
    return allDecisions.where((d) => d.category == category).toList();
  }

  /// Finds all pending decisions affecting a particular drug ID.
  static List<PendingClinicalDecision> getByDrugId(String drugId) {
    final needle = drugId.trim().toLowerCase();
    return allDecisions
        .where((d) => d.affectedDrugIds.map((e) => e.toLowerCase()).contains(needle))
        .toList();
  }
}
