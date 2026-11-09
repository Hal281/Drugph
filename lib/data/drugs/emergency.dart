import '../../core/models/models.dart';

/// Emergency & Resuscitation drugs commonly used in ER and ICU.
final List<Drug> emergency = [
  const Drug(
    id: 'epinephrine',
    genericName: 'Epinephrine (Adrenaline)',
    brandNames: ['Adrenaline'],
    nameTh: 'อีพิเนฟริน (อะดรีนาลิน)',
    category: DrugCategory.vasopressor,
    isHighAlert: true,
    allergyClass: 'Catecholamine',
    sourceCitation: 'AHA ACLS/PALS Guidelines 2020 / World Allergy Organization (WAO) 2020 / US FDA Adrenalin SPL',
    lastReviewedDate: '2024-10-12',
    provenance: Provenance(
      source: 'AHA ACLS/PALS Guidelines 2020 / WAO Anaphylaxis Guidelines 2020 / US FDA Adrenalin SPL',
      reviewedBy: 'Pending Clinical Pharmacist Sign-off',
      reviewedAt: '2024-10-12',
      sourceDetail: 'Anaphylaxis Protocol & ACLS/PALS Cardiac Arrest Resuscitation',
    ),
    monograph: ClinicalMonograph(
      textbookName: 'AHA Guidelines (ACLS/PALS) / World Allergy Organization (WAO)',
      editionYear: '2020 Guidelines / 2024 Update',
      sectionOrTable: 'Anaphylaxis Management & ACLS/PALS Resuscitation Protocol',
      dosingGuideline:
          '• ภาวะแพ้รุนแรง (Anaphylaxis - Intramuscular):\n'
          '  - ผู้ใหญ่: ฉีด 0.3–0.5 mg IM (ใช้ความเข้มข้น 1:1,000 หรือ 1 mg/mL โดยไม่ต้องเจือจาง) เข้าบริเวณกล้ามเนื้อต้นขาด้านนอกส่วนกลาง (Mid-anterolateral thigh) ซ้ำได้ทุก 5–15 นาทีตามอาการ\n'
          '  - เด็ก: ฉีด 0.01 mg/kg IM (1:1,000, 0.01 mL/kg) สูงสุดไม่เกิน 0.3 mg ต่อครั้ง (เพดานผู้ใหญ่ไม่เกิน 0.5 mg) ซ้ำได้ทุก 5–15 นาทีตามอาการ\n'
          '• ภาวะหัวใจหยุดเต้น (Cardiac Arrest - Intravenous):\n'
          '  - ผู้ใหญ่ (ACLS): 1.0 mg IV/IO push (ใช้ความเข้มข้น 1:10,000 หรือ 0.1 mg/mL ปริมาตร 10 mL) ทุก 3–5 นาที ตามด้วย NSS flush 20 mL\n'
          '  - เด็ก (PALS): 0.01 mg/kg IV/IO push (ใช้ความเข้มข้น 1:10,000, 0.1 mL/kg สูงสุดไม่เกิน 1 mg) ทุก 3–5 นาที',
      renalGuideline:
          '• สลายตัวอย่างรวดเร็วผ่านกระบวนการเมแทบอลิซึมของเอนไซม์ MAO และ COMT ในตับและเนื้อเยื่อส่วนปลาย\n'
          '• ไม่จำเป็นต้องปรับขนาดยาในผู้ป่วยที่มีภาวะไตเสื่อม (No renal dose adjustment needed)',
      administrationGuideline:
          '• กฎเหล็กการบริหารยาในภาวะแพ้รุนแรง (Anaphylaxis Route Rule):\n'
          '  - ต้องฉีดเข้ากล้ามเนื้อต้นขาด้านนอก (Mid-anterolateral thigh) เท่านั้น ห้ามฉีดเข้ากล้ามเนื้อสะโพกหรือเดลทอยด์ เนื่องจากต้นขามีหลอดเลือดมาเลี้ยงมาก ทำให้ระดับยาขึ้นสู่กระแสเลือดได้เร็วและสูงกว่า\n'
          '• คำเตือนความปลอดภัยวิกฤต (Fatal Error Warning):\n'
          '  - ห้ามนำสารละลาย 1:1,000 (1 mg/mL) ไปฉีดเข้าหลอดเลือดดำโดยตรง (IV Push) โดยเด็ดขาด เพราะอาจทำให้เกิด Severe Hypertensive Crisis, Intracranial Hemorrhage หรือ Fatal Ventricular Fibrillation\n'
          '  - การให้ทาง IV Push ในภาวะ Cardiac Arrest ต้องใช้ความเข้มข้นเจือจาง 1:10,000 (0.1 mg/mL) เท่านั้น',
      clinicalNotes:
          '• จัดเป็นยาเตือนภัยสูงระดับวิกฤตสูงสุด (Critical High-Alert Medication)\n'
          '• ในภาวะช็อกที่ไม่ตอบสนองต่อสารน้ำ (Septic/Cardiogenic Shock): อาจให้เป็น Continuous IV Infusion 0.05–1.0 mcg/kg/min ผ่าน Central Line โดยใช้ Infusion Pump',
      externalUrl: 'https://dailymed.nlm.nih.gov/dailymed/search.cfm?labeltype=all&query=epinephrine',
    ),
    severeInteractions: [
      'Non-selective Beta-blockers (Paradoxical hypertension)',
      'MAOIs (Severe hypertensive crisis)',
      'Halothane (Cardiac arrhythmias)'
    ],
    specialNotes: 'Anaphylaxis: IM into anterolateral thigh. Cardiac arrest: IV/IO. Dilute 1:10,000 for IV push.',
    specialNotesTh: 'แพ้ยารุนแรง: ฉีด IM ที่ต้นขาด้านนอก, หัวใจหยุดเต้น: IV/IO ใช้ความเข้มข้น 1:10,000 ฉีด IV Push',
    ivDiluentCompatibility: IvDiluentCompatibility(
      compatibleDiluents: [IvDiluent.d5w, IvDiluent.nss, IvDiluent.d5nss],
      preferredDiluent: IvDiluent.d5w,
      stabilityNoteEn:
          'Continuous IV infusion: dilute in D5W or NSS (e.g., 4 mg in 250 mL = 16 mcg/mL). Protect from light; discard if pinkish or brown. NEVER mix with sodium bicarbonate (alkaline inactivation).',
      stabilityNoteTh:
          'สำหรับการหยดต่อเนื่อง: ผสมใน D5W หรือ NSS (เช่น 4 mg ใน 250 mL = 16 mcg/mL) เก็บพ้นแสง ห้ามใช้หากเปลี่ยนเป็นสีชมพูหรือน้ำตาล และห้ามผสมร่วมกับ Sodium Bicarbonate',
      sourceCitation:
          'US FDA Adrenalin (epinephrine) SPL / AHA ACLS Guidelines 2020 / คู่มือยาฉีดความเสี่ยงสูง รามาธิบดี',
    ),
    regimens: [
      DosingRegimen(
        route: DoseRoute.im,
        indication: 'Anaphylaxis (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 0.3, // 0.3-0.5 mg IM (1:1,000)
        doseUnit: DoseUnit.mg,
        frequency: Frequency(isOnce: true, isPrn: true, displayEn: 'Stat (repeat 5-15min PRN)', displayTh: 'ทันที (ซ้ำได้ทุก 5-15 นาที)'),
        standardDilutionMgPerMl: 1.0,
        limits: DoseLimit(maxSingleDose: 0.5),
        verificationStatus: VerificationStatus.pendingReview,
      ),
      DosingRegimen(
        route: DoseRoute.im,
        indication: 'Anaphylaxis (Pediatric)',
        dosingType: DosingType.weightBased,
        dosePerKg: 0.01, // 0.01 mg/kg IM
        doseUnit: DoseUnit.mg,
        frequency: Frequency(isOnce: true, isPrn: true, displayEn: 'Stat (repeat 5-15min PRN)', displayTh: 'ทันที (ซ้ำได้ทุก 5-15 นาที)'),
        standardDilutionMgPerMl: 1.0,
        limits: DoseLimit(maxSingleDose: 0.3),
        verificationStatus: VerificationStatus.pendingReview,
      ),
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Cardiac Arrest / ACLS (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 1.0, // 1 mg IV (1:10,000)
        doseUnit: DoseUnit.mg,
        frequency: Frequency(
          displayEn: 'q3-5min',
          displayTh: 'ทุก 3-5 นาที ระหว่างกู้ชีพ',
          customReason: 'ACLS cardiac arrest protocol every 3-5 minutes',
        ),
        standardDilutionMgPerMl: 0.1,
        limits: DoseLimit(maxSingleDose: 1.0),
        verificationStatus: VerificationStatus.pendingReview,
      ),
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Cardiac Arrest / PALS (Pediatric)',
        dosingType: DosingType.weightBased,
        dosePerKg: 0.01,
        doseUnit: DoseUnit.mg,
        frequency: Frequency(
          displayEn: 'q3-5min',
          displayTh: 'ทุก 3-5 นาที ระหว่างกู้ชีพ',
          customReason: 'PALS cardiac arrest protocol every 3-5 minutes',
        ),
        standardDilutionMgPerMl: 0.1,
        limits: DoseLimit(maxSingleDose: 1.0),
        verificationStatus: VerificationStatus.pendingReview,
      ),
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Septic / Cardiogenic Shock (Inotropic Support)',
        dosingType: DosingType.titrated,
        continuousRateMin: 0.05,
        continuousRateMax: 1.0,
        continuousRateUnit: 'mcg/kg/min',
        rateUnit: RateUnit.mcgKgMin,
        doseUnit: DoseUnit.mcg,
        frequency: Frequency.continuous,
        standardDilutionMgPerMl: 0.016,
        standardDilution: Concentration(16.0, ConcentrationUnit.mcgPerMl),
        limits: DoseLimit(
          maxInfusionRate: 1.0,
          infusionRateUnit: 'mcg/kg/min',
        ),
        verificationStatus: VerificationStatus.pendingReview,
      ),
    ],
  ),
  const Drug(
    id: 'atropine',
    genericName: 'Atropine',
    brandNames: ['Atropine Sulfate'],
    nameTh: 'อะโทรปีน',
    category: DrugCategory.cardiovascular,
    isHighAlert: true,
    allergyClass: 'Anticholinergic',
    severeInteractions: ['Other Anticholinergics (Additive effects)'],
    contraindications: ['Narrow-angle glaucoma (relative)'],
    specialNotes: 'For symptomatic bradycardia. May be ineffective in transplanted hearts (denervated).',
    specialNotesTh: 'ใช้รักษาหัวใจเต้นช้าที่มีอาการ ไม่ค่อยได้ผลในคนไข้ที่เปลี่ยนหัวใจ',
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Symptomatic Bradycardia (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 0.5,
        doseUnit: DoseUnit.mg,
        frequency: Frequency(isPrn: true, displayEn: 'q3-5min PRN', displayTh: 'ทุก 3-5 นาที เมื่อจำเป็น'),
        limits: DoseLimit(maxSingleDose: 1.0),
      ),
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Bradycardia (Pediatric)',
        dosingType: DosingType.weightBased,
        dosePerKg: 0.02,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.stat,
        limits: DoseLimit(minSingleDose: 0.1, maxSingleDose: 0.5),
      ),
    ],
  ),
  const Drug(
    id: 'magnesium_sulfate',
    genericName: 'Magnesium Sulfate',
    brandNames: ['MgSO4'],
    nameTh: 'แมกนีเซียมซัลเฟต',
    category: DrugCategory.cardiovascular,
    isHighAlert: true,
    requiresRenalAdjustment: true,
    sourceCitation: 'ACOG Practice Bulletin No. 222 / AHA ACLS Guidelines 2020 / US FDA SPL',
    lastReviewedDate: '2024-10-12',
    provenance: Provenance(
      source: 'ACOG Practice Bulletin No. 222 / AHA ACLS Guidelines 2020 / US FDA SPL',
      reviewedBy: 'Pending Clinical Pharmacist Sign-off',
      reviewedAt: '2024-10-12',
      sourceDetail: 'Preeclampsia Seizure Prophylaxis & Torsades Management',
    ),
    monograph: ClinicalMonograph(
      textbookName: 'ACOG Guidelines (Bulletin 222) / AHA ACLS Guidelines',
      editionYear: '2020 Guidelines / 2024 Update',
      sectionOrTable: 'Preeclampsia Seizure Prophylaxis & Eclampsia Management',
      dosingGuideline:
          '• การป้องกันและรักษาอาการชักใน Preeclampsia / Eclampsia:\n'
          '  - ขนาดยาเริ่มต้น (Loading Dose): 4–6 g IV เจือจางใน D5W หรือ NSS 100 mL หยดเข้าหลอดเลือดดำช้าๆ นาน 15–20 นาที\n'
          '  - ขนาดยาต่อเนื่อง (Maintenance Infusion): 1–2 g/hr หยดต่อเนื่องผ่าน Infusion Pump ตลอดระยะเวลาการคลอดจนถึง 24 ชั่วโมงหลังคลอด\n'
          '• ภาวะหัวใจเต้นผิดจังหวะ Torsades de Pointes / Hypomagnesemia:\n'
          '  - ผู้ใหญ่: 1–2 g IV เจือจางใน D5W 50–100 mL หยดนาน 15 นาที (หรือฉีดช้าๆ 1–2 นาที ในภาวะ Pulseless Arrest / VT)',
      renalGuideline:
          '• ขับถ่ายออกทางไตเกือบ 100% ในรูปที่ไม่เปลี่ยนแปลง (Almost 100% renal elimination)\n'
          '• ผู้ป่วย CrCl < 30 mL/min หรือ Serum Creatinine >= 1.2 mg/dL:\n'
          '  - ขนาดยาเริ่มต้น (Loading Dose) ให้ขนาดเต็มตามปกติ (4 g) เพื่อกระจายตัวใน Volume of distribution\n'
          '  - ขนาดยาต่อเนื่อง (Maintenance Infusion): ปรับลดอัตราการหยดลง 50% (เหลือ 0.5–1.0 g/hr) หรืออาจพิจารณาหยุดให้ยาต่อเนื่องแล้วตรวจติดตามระดับ Mg ในเลือดเป็นระยะ\n'
          '  - เป้าหมายระดับยาในการรักษา (Therapeutic Range): Serum Magnesium 4.8–8.4 mg/dL (2.0–3.5 mmol/L หรือ 4.0–7.0 mEq/L)',
      administrationGuideline:
          '• สารละลายและการผสมยามาตรฐาน:\n'
          '  - Maintenance: Magnesium sulfate 20 g ใน NSS 500 mL (ความเข้มข้น 40 mg/mL หรือ 4% solution) หยดผ่านเครื่องควบคุมอัตราการให้ยา (Infusion Pump)\n'
          '• การตรวจติดตามความปลอดภัยทางคลินิก (Monitoring Parameters):\n'
          '  1. Deep Tendon Reflexes (Patellar reflex) ต้องมีอยู่เสมอ (หายไปเมื่อ Mg > 9.6–12 mg/dL)\n'
          '  2. อัตราการหายใจ (Respiratory Rate) ต้องไม่ต่ำกว่า 16 ครั้ง/นาที (กดการหายใจเมื่อ Mg > 12–14 mg/dL)\n'
          '  3. ปริมาณปัสสาวะ (Urine Output) ต้องออกไม่น้อยกว่า 25–30 mL/hr (หรือ >= 100 mL ใน 4 ชม.)',
      clinicalNotes:
          '• จัดเป็นยาเตือนภัยสูงระดับวิกฤต (High-Alert Electrolyte/Anticonvulsant)\n'
          '• ยาแก้พิษจำเพาะ (Specific Antidote):\n'
          '  - หากเกิดภาวะพิษจากแมกนีเซียม (Loss of patellar reflexes หรือ Respiratory depression): ให้หยุดหยด Magnesium sulfate ทันที และให้ 10% Calcium Gluconate ขนาด 10 mL (1 g) ฉีดเข้าหลอดเลือดดำช้าๆ นาน 3–5 นาที',
      externalUrl: 'https://dailymed.nlm.nih.gov/dailymed/search.cfm?labeltype=all&query=magnesium+sulfate',
    ),
    severeInteractions: [
      'Calcium Channel Blockers (Potentiates hypotension)',
      'Neuromuscular blockers (Prolongs paralysis)'
    ],
    contraindications: ['Heart block', 'Myocardial damage'],
    specialNotes: 'Monitor deep tendon reflexes, respiratory rate, and urine output. Calcium gluconate is the antidote.',
    specialNotesTh: 'ต้องวัดรีเฟล็กซ์เข่า อัตราการหายใจ และปัสสาวะอย่างต่อเนื่อง ถ้าเกิดพิษ ให้ Calcium gluconate เป็นยาแก้พิษ',
    ivDiluentCompatibility: IvDiluentCompatibility(
      compatibleDiluents: [IvDiluent.d5w, IvDiluent.nss],
      preferredDiluent: IvDiluent.d5w,
      stabilityNoteEn:
          'Dilute 50% MgSO4 solution to <= 20% (<= 200 mg/mL) prior to IV infusion (standard maintenance: 20 g in 500 mL NSS or D5W = 40 mg/mL) via infusion pump.',
      stabilityNoteTh:
          'ต้องเจือจาง 50% MgSO4 ให้มีความเข้มข้น <= 20% ก่อนหยดเข้าหลอดเลือดดำ (ผสมมาตรฐาน: 20 g ใน NSS หรือ D5W 500 mL = 40 mg/mL) ผ่าน Infusion Pump เสมอ',
      sourceCitation:
          'US FDA Magnesium Sulfate Injection SPL / ACOG Practice Bulletin No. 222 / คู่มือยาฉีดรามาธิบดี',
    ),
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Eclampsia / Pre-eclampsia (Loading)',
        dosingType: DosingType.fixed,
        fixedDose: 4000.0, // 4g loading dose
        doseUnit: DoseUnit.mg,
        frequency: Frequency.once,
        notes: 'Loading dose over 15-20 min, then 1-2g/hr maintenance',
        infusionTimeMinutes: 20,
        verificationStatus: VerificationStatus.pendingReview,
        renalAdjustments: [
          RenalAdjustment(
            crclMin: 0,
            crclMax: 30,
            action: RenalAction.monitorOnly,
            notes: 'Give standard loading dose; monitor serum magnesium and reflexes closely',
            notesTh: 'ให้ loading dose ขนาดเต็มตามปกติ แต่ต้องติดตามระดับ Mg ในเลือดและรีเฟล็กซ์อย่างใกล้ชิด',
          ),
        ],
      ),
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Eclampsia / Pre-eclampsia (Maintenance)',
        dosingType: DosingType.titrated,
        doseUnit: DoseUnit.g,
        frequency: Frequency.continuous,
        continuousRateMin: 1.0,
        continuousRateMax: 2.0,
        continuousRateUnit: 'g/hr',
        standardDilutionMgPerMl: 40.0,
        verificationStatus: VerificationStatus.pendingReview,
        renalAdjustments: [
          RenalAdjustment(
            crclMin: 0,
            crclMax: 30,
            action: RenalAction.adjust,
            adjustmentFactor: 0.5,
            notes: 'Reduce maintenance infusion rate by 50% in CrCl < 30 mL/min; target Mg level 4.8-8.4 mg/dL',
            notesTh: 'ลดอัตราการหยดยาคงที่ลง 50% ใน CrCl < 30 มล./นาที และติดตามระดับ Mg ในเลือดให้อยู่ในช่วง 4.8-8.4 mg/dL',
          ),
        ],
      ),
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Torsades de Pointes / Hypomagnesemia (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 2000.0, // 2g
        doseUnit: DoseUnit.mg,
        frequency: Frequency.stat,
        notes: 'Slow IV push over 2-5 min',
        verificationStatus: VerificationStatus.pendingReview,
        renalAdjustments: [
          RenalAdjustment(
            crclMin: 0,
            crclMax: 30,
            action: RenalAction.monitorOnly,
            notes: 'Standard initial dose in cardiac arrest/Torsades; reduce subsequent doses and monitor',
            notesTh: 'ให้ขนาดเริ่มต้นตามปกติในภาวะฉุกเฉินหัวใจเต้นผิดจังหวะ ลดขนาดยาครั้งถัดไปและติดตามระดับ Mg',
          ),
        ],
      ),
    ],
  ),
  const Drug(
    id: 'dexamethasone',
    genericName: 'Dexamethasone',
    brandNames: ['Dexon', 'Oradexon'],
    nameTh: 'เดกซาเมทาโซน',
    category: DrugCategory.antiInflammatory,
    tags: ['obstetric'],
    allergyClass: 'Corticosteroid',
    severeInteractions: [
      'Warfarin (Increases bleeding risk)',
      'NSAIDs (Increased GI bleeding risk)',
      'Live Vaccines (Avoid)'
    ],
    specialNotes: 'Monitor blood glucose (hyperglycemia). Taper slowly if used >7 days to avoid adrenal crisis.',
    specialNotesTh: 'ระวังน้ำตาลในเลือดสูง หากใช้ยานานเกิน 7 วัน ต้องค่อยๆ ลดโดสยา (Taper) ป้องกันภาวะต่อมหมวกไตบกพร่องเฉียบพลัน',
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Cerebral Edema (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 10.0, // 10 mg IV loading
        doseUnit: DoseUnit.mg,
        frequency: Frequency.stat,
      ),
      DosingRegimen(
        route: DoseRoute.im,
        indication: 'Fetal lung maturity',
        dosingType: DosingType.fixed,
        fixedDose: 6.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency(
          intervalHours: 12,
          displayEn: 'q12h (4 doses)',
          displayTh: 'ทุก 12 ชม. (4 ครั้ง)',
        ),
        limits: DoseLimit(maxDailyDose: 12.0),
      ),
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Croup (Pediatric)',
        dosingType: DosingType.weightBased,
        dosePerKg: 0.6,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.once,
        limits: DoseLimit(maxSingleDose: 10.0),
      ),
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Anti-inflammatory (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 4.0, // 4-8 mg
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q24h,
        limits: DoseLimit(maxDailyDose: 20.0),
      ),
    ],
  ),
  const Drug(
    id: 'hydrocortisone',
    genericName: 'Hydrocortisone',
    brandNames: ['Solu-Cortef'],
    nameTh: 'ไฮโดรคอร์ติโซน',
    category: DrugCategory.antiInflammatory,
    allergyClass: 'Corticosteroid',
    severeInteractions: [
      'NSAIDs (Increased GI bleeding)',
      'Live Vaccines (Avoid)'
    ],
    specialNotes: 'Stress dose for septic shock: 200 mg/day. Monitor electrolytes and blood glucose.',
    specialNotesTh: 'โดสสำหรับช็อคจากติดเชื้อ: 200 mg/วัน ต้องวัดน้ำตาลและเกลือแร่',
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Septic Shock (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 50.0, // 50 mg q8h = 150mg or 50 q6h = 200mg
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q8h,
        limits: DoseLimit(maxDailyDose: 200.0),
      ),
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Adrenal Crisis (Pediatric)',
        dosingType: DosingType.weightBased,
        dosePerKg: 2.0, // 2 mg/kg bolus
        doseUnit: DoseUnit.mg,
        frequency: Frequency.stat,
        limits: DoseLimit(maxSingleDose: 100.0),
      ),
    ],
  ),
  const Drug(
    id: 'naloxone',
    genericName: 'Naloxone',
    brandNames: ['Narcan'],
    nameTh: 'นาลอกโซน',
    category: DrugCategory.analgesic, // antidote
    isHighAlert: true,
    specialNotes: 'Opioid reversal agent. Short duration (30-90 min); re-sedation may occur. Titrate to respiratory effort.',
    specialNotesTh: 'ยาแก้พิษฝิ่น (Opioid) ออกฤทธิ์สั้น (30-90 นาที) คนไข้อาจซึมกลับมาอีก ต้อง Titrate ตามอัตราการหายใจ',
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Opioid Overdose / Reversal (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 0.4, // 0.04-0.4 mg titrate
        doseUnit: DoseUnit.mg,
        frequency: Frequency(isPrn: true, displayEn: 'q2-3min PRN', displayTh: 'ทุก 2-3 นาที เมื่อจำเป็น'),
        limits: DoseLimit(maxSingleDose: 2.0),
      ),
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Opioid Reversal (Pediatric)',
        dosingType: DosingType.weightBased,
        dosePerKg: 0.01,
        doseUnit: DoseUnit.mg,
        frequency: Frequency(isPrn: true, displayEn: 'q2-3min PRN', displayTh: 'ทุก 2-3 นาที เมื่อจำเป็น'),
        limits: DoseLimit(maxSingleDose: 2.0),
      ),
    ],
  ),
  const Drug(
    id: 'dobutamine',
    genericName: 'Dobutamine',
    brandNames: ['Dobutrex'],
    nameTh: 'โดบูทามีน',
    category: DrugCategory.vasopressor,
    isHighAlert: true,
    sourceCitation: 'AHA/ACC Heart Failure Guidelines 2022 / คู่มือยาฉีดความเสี่ยงสูง รามาธิบดี / US FDA Dobutrex SPL',
    lastReviewedDate: '2024-10-12',
    provenance: Provenance(
      source: 'AHA/ACC Heart Failure Guidelines 2022 / Ramathibodi High-Alert IV Infusion Guide / US FDA Dobutrex SPL',
      reviewedBy: 'Pending Clinical Pharmacist Sign-off',
      reviewedAt: '2024-10-12',
      sourceDetail: 'Inotrope Support for Acute Decompensated Heart Failure §2.1-2.2',
    ),
    monograph: ClinicalMonograph(
      textbookName: 'AHA/ACC Heart Failure Guidelines / รามาธิบดี',
      editionYear: '2022 Guidelines / 2024 Manual',
      sectionOrTable: 'Inotrope Support for Acute Decompensated Heart Failure',
      dosingGuideline:
          '• อัตราการให้ยาต่อเนื่อง (Continuous IV Infusion):\n'
          '  - ขนาดยาเริ่มต้น: 2.0–2.5 mcg/kg/min ปรับ Titrate เพิ่มขึ้นทีละ 2.5 mcg/kg/min ทุก 15–30 นาที ตามการตอบสนองของระบบไหลเวียนโลหิต\n'
          '  - ขนาดยาในการรักษาทั่วไป: 2.5–15.0 mcg/kg/min (ขนาดยาสูงสุด 20.0 mcg/kg/min)\n'
          '  - เป้าหมายทางคลินิก: เพิ่ม Cardiac Output, บรรเทาภาวะคั่งของน้ำ (Congestion) และฟื้นฟูการไหลเวียนเลือดไปยังอวัยวะสำคัญ (End-organ perfusion)',
      renalGuideline:
          '• สลายตัวผ่านกระบวนการเมแทบอลิซึมในตับและเนื้อเยื่อโดยเอนไซม์ COMT\n'
          '• ไม่จำเป็นต้องปรับลดขนาดยาในผู้ป่วยไตเสื่อม (No renal dose adjustment needed)\n'
          '• การเพิ่มแรงบีบตัวของหัวใจช่วยเพิ่ม Renal blood flow และ GFR ส่งผลให้ผู้ป่วยตอบสนองต่อยาขับปัสสาวะ (Diuretic responsiveness) ได้ดีขึ้น',
      administrationGuideline:
          '• สารละลายและการผสมยามาตรฐาน: Dobutamine 250 mg ใน D5W หรือ NSS 250 mL (ความเข้มข้น 1.0 mg/mL หรือ 1,000 mcg/mL); สำหรับสูตร Double strength: 500 mg ใน 250 mL (2.0 mg/mL)\n'
          '• เส้นทางการให้ยา: ควรให้ผ่านเครื่องควบคุมอัตราการให้ยา (Infusion Pump) เสมอ สามารถให้ผ่านหลอดเลือดดำส่วนปลายขนาดใหญ่หรือหลอดเลือดดำส่วนกลางได้',
      clinicalNotes:
          '• จัดเป็นยาเตือนภัยสูง (High-Alert Inotrope)\n'
          '• กลไกหลัก: กระตุ้น Beta-1 receptor เพิ่ม Inotropy และมีฤทธิ์กระตุ้น Beta-2 receptor เล็กน้อย ทำให้เกิด Vasodilation\n'
          '• ข้อควรระวัง: อาจทำให้เกิด Tachyarrhythmias, Ventricular Ectopy หรือ Myocardial Ischemia ในผู้ป่วย Coronary Artery Disease\n'
          '• หากผู้ป่วยมีภาวะขาดสารน้ำรุนแรง ยาอาจทำให้ความดันโลหิตลดต่ำลง (Hypotension) ได้จากฤทธิ์คลายหลอดเลือด',
      externalUrl: 'https://dailymed.nlm.nih.gov/dailymed/search.cfm?labeltype=all&query=dobutamine',
    ),
    severeInteractions: ['Beta-blockers (Antagonistic effect)'],
    specialNotes: 'Inotrope for acute decompensated heart failure. Increases cardiac output. May cause tachycardia.',
    specialNotesTh: 'ยาเพิ่มแรงบีบตัวของหัวใจ สำหรับหัวใจล้มเหลวเฉียบพลัน อาจทำให้หัวใจเต้นเร็ว',
    ivDiluentCompatibility: IvDiluentCompatibility(
      compatibleDiluents: [
        IvDiluent.d5w,
        IvDiluent.nss,
        IvDiluent.d5nss,
        IvDiluent.lrs,
      ],
      preferredDiluent: IvDiluent.d5w,
      stabilityNoteEn:
          'Standard: 250 mg in 250 mL D5W or NSS (1.0 mg/mL = 1,000 mcg/mL); use within 24 hours. Slight pink discoloration over time reflects mild oxidation without significant potency loss. Incompatible with alkaline sodium bicarbonate.',
      stabilityNoteTh:
          'ผสมมาตรฐาน 250 mg ใน D5W หรือ NSS 250 mL (1.0 mg/mL) ใช้ภายใน 24 ชม. ห้ามผสมร่วมกับ Sodium Bicarbonate หรือสารละลายด่าง',
      sourceCitation:
          'US FDA Dobutrex (dobutamine) SPL / Ramathibodi High-Alert IV Infusion Guide 2024',
    ),
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Cardiogenic Shock / Acute HF',
        dosingType: DosingType.titrated,
        continuousRateMin: 2.0,
        continuousRateMax: 20.0,
        continuousRateUnit: 'mcg/kg/min',
        rateUnit: RateUnit.mcgKgMin,
        verificationStatus: VerificationStatus.pendingReview,
        doseUnit: DoseUnit.mcg,
        frequency: Frequency.continuous,
        standardDilutionMgPerMl: 1.0, // 250mg in 250mL
        limits: DoseLimit(maxInfusionRate: 20.0, infusionRateUnit: 'mcg/kg/min'),
      ),
    ],
  ),
];
