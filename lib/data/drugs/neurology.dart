import '../../core/models/models.dart';

final List<Drug> neurology = [
  const Drug(
    id: 'diazepam',
    genericName: 'Diazepam',
    brandNames: ['Valium'],
    nameTh: 'ไดอะซีแพม',
    category: DrugCategory.sedative,
    requiresHepaticCaution: true,
    allergyClass: 'Benzodiazepine',
    severeInteractions: [
      'Opioids (Profound sedation, respiratory depression, coma)',
      'Alcohol (Increased CNS depression)'
    ],
    contraindications: [
      'Severe respiratory insufficiency',
      'Sleep apnea syndrome',
      'Severe hepatic impairment'
    ],
    sourceCitation:
        'Lexicomp Drug Information Handbook 2024 / AES Status Epilepticus Guideline 2016 / Ramathibodi IV Guide',
    sideEffects: [
      'Drowsiness, sedation, lethargy',
      'Ataxia, muscle weakness, dizziness',
      'Pain or phlebitis at IV injection site',
      'Paradoxical agitation (especially in children/elderly)',
    ],
    sideEffectsTh: [
      'ง่วงซึม อ่อนเพลีย',
      'เดินเซ กล้ามเนื้ออ่อนแรง เวียนศีรษะ',
      'ปวดหรือหลอดเลือดดำอักเสบตำแหน่งที่ฉีด IV',
      'กระสับกระส่ายหรือตื่นตัวผิดปกติ (พบได้ในเด็กและผู้สูงอายุ)',
    ],
    seriousSideEffects: [
      'Respiratory depression / apnea (especially rapid IV push or with opioids)',
      'Hypotension & cardiovascular collapse',
      'Propylene glycol toxicity / metabolic acidosis (prolonged high-dose IV)',
      'Physical dependence & acute withdrawal seizures on abrupt stop',
    ],
    seriousSideEffectsTh: [
      'กดการหายใจหรือหยุดหายใจ (โดยเฉพาะเมื่อฉีด IV เร็ว หรือใช้ร่วมกับ Opioid)',
      'ความดันโลหิตตกและระบบไหลเวียนล้มเหลว',
      'ภาวะเลือดเป็นกรดจากตัวทำละลาย Propylene glycol (เมื่อใช้ IV ขนาดสูงต่อเนื่อง)',
      'การติดยาและอาการชักซ้ำเมื่อหยุดยากะทันหัน',
    ],
    specialNotes: 'High risk of dependence. Rapid IV push can cause respiratory arrest (push max 5mg/min).',
    specialNotesTh: 'เสี่ยงติดยา การฉีด IV เร็วเกินไปอาจทำให้หยุดหายใจได้ (ดันยาไม่เกิน 5mg/นาที)',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Anxiety / Muscle Spasm (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 5.0, // 2-10 mg
        doseUnit: DoseUnit.mg,
        frequency: Frequency(minIntervalHours: 6, maxIntervalHours: 8, displayEn: 'q6-8h', displayTh: 'ทุก 6-8 ชม.'),
        limits: DoseLimit(
          maxDailyDose: 40.0,
        ),
      ),
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Status Epilepticus (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 10.0, // 5-10 mg
        doseUnit: DoseUnit.mg,
        frequency: Frequency(isOnce: true, isPrn: true, displayEn: 'Stat (repeat 10-15min PRN)', displayTh: 'ทันที (ซ้ำได้ใน 10-15 นาที)'),
        limits: DoseLimit(
          maxSingleDose: 10.0,
          maxDailyDose: 30.0,
        ),
      ),
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Status Epilepticus (Pediatric)',
        dosingType: DosingType.weightBased,
        dosePerKg: 0.2, // 0.1-0.3 mg/kg
        doseUnit: DoseUnit.mg,
        frequency: Frequency.stat,
        limits: DoseLimit(
          maxSingleDose: 10.0,
        ),
      ),
    ],
  ),
  const Drug(
    id: 'phenytoin',
    genericName: 'Phenytoin',
    brandNames: ['Dilantin'],
    nameTh: 'ฟีนิทอยน์',
    category: DrugCategory.neurological,
    requiresHepaticCaution: true,
    isHighAlert: false,
    requiresTDM: true,
    allergyClass: 'Hydantoin',
    severeInteractions: [
      'Valproic Acid (Displaces phenytoin from proteins - requires free phenytoin monitoring)',
      'Amiodarone / Fluconazole (Increases phenytoin levels)'
    ],
    contraindications: ['Sinus bradycardia', 'Sinoatrial block'],
    sourceCitation:
        'Lexicomp Drug Information Handbook 2024 / AES Status Epilepticus Guideline 2016 / Ramathibodi IV Guide',
    sideEffects: [
      'Nystagmus, ataxia, slurred speech (dose-dependent)',
      'Dizziness, drowsiness, mild confusion',
      'Gingival hyperplasia & hirsutism (chronic therapy)',
      'Nausea, vomiting, venous irritation at IV site',
    ],
    sideEffectsTh: [
      'ตากระตุก เดินเซ พูดไม่ชัด (สัมพันธ์กับระดับยาในเลือด)',
      'เวียนศีรษะ ง่วงซึม มึนงง',
      'เหงือกบวมหนาและขนดก (เมื่อใช้ระยะยาว)',
      'คลื่นไส้ อาเจียน ระคายเคืองหลอดเลือดดำตำแหน่งให้ยา',
    ],
    seriousSideEffects: [
      'Severe hypotension, bradycardia, or cardiac arrest (rapid IV infusion >50 mg/min)',
      'Purple Glove Syndrome & tissue necrosis from IV extravasation',
      'Stevens-Johnson Syndrome (SJS) / TEN (screen HLA-B*1502)',
      'DRESS syndrome & acute hepatotoxicity',
    ],
    seriousSideEffectsTh: [
      'ความดันตก หัวใจเต้นช้า หรือหัวใจหยุดเต้นหากหยด IV เร็วเกิน 50 mg/นาที',
      'ภาวะมือม่วง/เนื้อเยื่อตาย (Purple Glove Syndrome) หากยารั่วซึมหรือให้ทาง IV ส่วนปลาย',
      'ผื่นแพ้ยารุนแรง SJS / TEN (สัมพันธ์กับยีน HLA-B*1502)',
      'กลุ่มอาการ DRESS และตับอักเสบเฉียบพลัน',
    ],
    specialNotes: 'Non-linear pharmacokinetics. Target TDM: 10-20 mcg/mL. Max IV rate 50mg/min to prevent arrhythmias.',
    specialNotesTh: 'ต้องเจาะเลือดดูระดับยา (Target 10-20) การให้ IV ห้ามเกิน 50mg/min ป้องกันหัวใจหยุดเต้น',
    ivDiluentCompatibility: IvDiluentCompatibility(
      compatibleDiluents: [IvDiluent.nss],
      preferredDiluent: IvDiluent.nss,
      incompatibleDiluents: [IvDiluent.d5w, IvDiluent.d5nss, IvDiluent.lrs],
      incompatibilityReasonEn:
          'D5W, D5NSS, and LRS may cause precipitation; dilute in NSS only.',
      incompatibilityReasonTh:
          'D5W, D5NSS และ LRS เสี่ยงตกตะกอน; เจือจางใน NSS เท่านั้น',
      stabilityNoteEn:
          'NSS concentration <=10 mg/mL; use a 0.22-micron filter. Max rate: 50 mg/min (25 mg/min in elderly/cardiac disease); use within 1 h.',
      stabilityNoteTh:
          'เจือจางใน NSS <=10 mg/mL ผ่านตัวกรอง 0.22 micron; อัตราสูงสุด 50 mg/min (ผู้สูงอายุ/โรคหัวใจ 25 mg/min); ใช้ภายใน 1 ชม.',
      sourceCitation:
          'US FDA Phenytoin Sodium Injection SPL / Trissel\'s Handbook on Injectable Drugs / คู่มือยาฉีดรามาธิบดี',
    ),
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Status Epilepticus Loading Dose (Adult)',
        dosingType: DosingType.weightBased,
        dosePerKg: 15.0, // 15-20 mg/kg
        doseUnit: DoseUnit.mg,
        frequency: Frequency.stat,
        maxInfusionRateMgPerMin: 50.0,
        limits: DoseLimit(
          maxSingleDose: 1500.0,
        ),
      ),
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Maintenance Dosing (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 300.0, // or 100mg TID
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q24h,
        limits: DoseLimit(
          maxDailyDose: 600.0,
        ),
      ),
    ],
  ),
  const Drug(
    id: 'levetiracetam',
    genericName: 'Levetiracetam',
    brandNames: ['Keppra'],
    nameTh: 'ลีวีไทราซีแทม',
    category: DrugCategory.neurological,
    requiresRenalAdjustment: true,
    allergyClass: 'Pyrrolidine derivative',
    sourceCitation:
        'AES Status Epilepticus Guideline 2016 / Lexicomp Drug Information Handbook 2024',
    severeInteractions: [],
    sideEffects: [
      'Somnolence, fatigue, dizziness',
      'Headache & mild nasopharyngitis',
      'Irritability, mood swings, agitation',
      'Mild GI upset or anorexia',
    ],
    sideEffectsTh: [
      'ง่วงซึม อ่อนเพลีย เวียนศีรษะ',
      'ปวดศีรษะ คัดจมูกเล็กน้อย',
      'หงุดหงิด อารมณ์แปรปรวน กระสับกระส่าย',
      'ระคายเคืองกระเพาะอาหารหรือเบื่ออาหารเล็กน้อย',
    ],
    seriousSideEffects: [
      'Severe behavioral psychosis, aggression, or suicidal ideation',
      'Stevens-Johnson Syndrome (SJS) / TEN / DRESS (rare)',
      'Pancytopenia / neutropenia / thrombocytopenia (rare)',
    ],
    seriousSideEffectsTh: [
      'พฤติกรรมก้าวร้าวรุนแรง อาการทางจิต หรือความคิดทำร้ายตนเอง',
      'ผื่นแพ้ยารุนแรง SJS / TEN / DRESS (พบได้น้อย)',
      'กดไขกระดูก เม็ดเลือดขาวหรือเกล็ดเลือดต่ำ (พบได้น้อย)',
    ],
    specialNotes: 'Can cause behavioral abnormalities (aggression, agitation). Very safe for liver.',
    specialNotesTh: 'อาจทำให้มีอาการก้าวร้าวหรืออารมณ์แปรปรวนได้ ปลอดภัยต่อตับแต่ต้องปรับโดสตามไต',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Seizure Prophylaxis (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 500.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q12h,
        limits: DoseLimit(maxDailyDose: 3000.0),
        renalAdjustments: [
          RenalAdjustment(crclMin: 50, crclMax: 80, action: RenalAction.adjust, adjustmentFactor: 1.0, adjustedFrequency: Frequency.q12h),
          RenalAdjustment(crclMin: 30, crclMax: 50, action: RenalAction.adjust, adjustmentFactor: 0.5, adjustedFrequency: Frequency.q12h),
          RenalAdjustment(crclMin: 0, crclMax: 30, action: RenalAction.adjust, adjustmentFactor: 0.5, adjustedFrequency: Frequency.q12h, notes: '250-500 mg q12h'),
        ],
      ),
      DosingRegimen(
        route: DoseRoute.iv,
        indication: 'Status Epilepticus (Adult IV Loading)',
        audience: RegimenAudience.adult,
        dosingType: DosingType.weightBased,
        dosePerKg: 60.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.once,
        verificationStatus: VerificationStatus.pendingReview,
        notes:
            'AES Guideline 2016 / ESETT Trial: 60 mg/kg IV once over 10–15 minutes (max 4,500 mg/dose).',
        notesTh:
            'Status Epilepticus (ผู้ใหญ่): 60 mg/kg หยด IV นาน 10–15 นาที ครั้งเดียว (สูงสุดไม่เกิน 4,500 mg)',
        limits: DoseLimit(maxSingleDose: 4500.0),
      ),
      DosingRegimen(
        route: DoseRoute.iv,
        indication: 'Status Epilepticus (Pediatric IV Loading)',
        audience: RegimenAudience.pediatric,
        population: PopulationCriteria(maxAgeMonths: 215),
        dosingType: DosingType.weightBased,
        dosePerKg: 60.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.once,
        verificationStatus: VerificationStatus.pendingReview,
        notes:
            'AES Guideline 2016 / ESETT Trial (Pediatric): 60 mg/kg IV once over 10–15 minutes (max 4,500 mg/dose).',
        notesTh:
            'Status Epilepticus (เด็ก): 60 mg/kg หยด IV นาน 10–15 นาที ครั้งเดียว (สูงสุดไม่เกิน 4,500 mg)',
        limits: DoseLimit(maxSingleDose: 4500.0),
      ),
    ],
  ),
  const Drug(
    id: 'gabapentin',
    genericName: 'Gabapentin',
    brandNames: ['Neurontin'],
    nameTh: 'กาบาเพนติน',
    category: DrugCategory.neurological,
    requiresRenalAdjustment: true,
    allergyClass: 'GABA analogue',
    severeInteractions: ['Antacids (Decreases absorption - separate by 2 hours)'],
    specialNotes: 'Requires strictly adjusted dosing based on renal function to prevent neurotoxicity/coma.',
    specialNotesTh: 'ต้องปรับโดสตามค่า CrCl อย่างเคร่งครัด หากไตวายแล้วไม่ปรับโดสอาจทำให้ซึมลึกหรือโคม่าได้',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Neuropathic Pain (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 300.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q8h,
        limits: DoseLimit(maxDailyDose: 3600.0),
        renalAdjustments: [
          RenalAdjustment(crclMin: 30, crclMax: 60, action: RenalAction.adjust, adjustmentFactor: 1.0, adjustedFrequency: Frequency.q12h, notes: '400-1400 mg/day divided BID'),
          RenalAdjustment(crclMin: 15, crclMax: 30, action: RenalAction.adjust, adjustmentFactor: 1.0, adjustedFrequency: Frequency.q24h, notes: '200-700 mg/day (OD)'),
          RenalAdjustment(crclMin: 0, crclMax: 15, action: RenalAction.adjust, absoluteDose: 100.0, adjustedFrequency: Frequency.q24h, notes: 'Start at 100 mg OD (100-300 mg/day) to prevent neurotoxicity', notesTh: 'เริ่มต้นที่ 100 mg วันละครั้ง (100-300 mg/วัน) ป้องกันพิษต่อระบบประสาท'),
        ],
        renalReplacementProtocols: [
          RenalReplacementProtocol(
            mode: RenalReplacementMode.ihd,
            specificDose: 200.0,
            doseUnit: DoseUnit.mg,
            frequency: Frequency.q24h,
            requiresPostHdSupplement: true,
            clinicalInstructionEn:
                '100–300 mg PO administered immediately AFTER each hemodialysis session (e.g. 100–300 mg post-HD 3 times/week). Dialysis removes 35–50% of drug. Monitor closely for sedation and neurotoxicity.',
            clinicalInstructionTh:
                '100–300 มก. รับประทานทันทีหลังการฟอกเลือดเสร็จสิ้นในแต่ละครั้ง (เช่น 100–300 มก. หลังฟอกไต สัปดาห์ละ 3 ครั้ง) การฟอกไตขจัดยาออก 35–50% ต้องเฝ้าระวังอาการง่วงซึมและพิษต่อระบบประสาทอย่างใกล้ชิด',
            provenance: Provenance(
              source: 'Lexicomp 2024 / FDA Neurontin Package Insert §2.2 / KDIGO 2023',
              reviewedBy: 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
              reviewedAt: '2024-10-29',
            ),
          ),
          RenalReplacementProtocol(
            mode: RenalReplacementMode.capd,
            specificDose: 100.0,
            doseUnit: DoseUnit.mg,
            frequency: Frequency.q48h,
            requiresPostHdSupplement: false,
            clinicalInstructionEn:
                '100–200 mg PO every 48 hours (or 100 mg PO once daily with caution). Peritoneal clearance is minimal.',
            clinicalInstructionTh:
                '100–200 มก. รับประทาน ทุก 48 ชม. (หรือ 100 มก. วันละครั้งอย่างระมัดระวัง) การล้างไตทางช่องท้องขจัดยาน้อยมาก',
            provenance: Provenance(
              source: 'Lexicomp 2024 / KDIGO 2023',
              reviewedBy: 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
              reviewedAt: '2024-10-29',
            ),
          ),
          RenalReplacementProtocol(
            mode: RenalReplacementMode.crrt,
            specificDose: 100.0,
            doseUnit: DoseUnit.mg,
            frequency: Frequency.q12h,
            requiresPostHdSupplement: false,
            clinicalInstructionEn:
                'CRRT (CVVH/CVVHD/CVVHDF): 100–200 mg PO q12–24h. CRRT filters clear gabapentin readily (sieving coefficient ~1.0). Titrate slowly and monitor for central nervous system depression, ataxia, and myoclonus.',
            clinicalInstructionTh:
                'CRRT (CVVH/CVVHD/CVVHDF): 100–200 มก. รับประทาน ทุก 12–24 ชม. ตัวกรอง CRRT ขจัดยาออกได้อย่างมีประสิทธิภาพ (sieving coeff ~1.0) ค่อยๆ ปรับขนาดยาและติดตามอาการซึม กล้ามเนื้อกระตุก และพิษต่อระบบประสาทอย่างใกล้ชิด',
            provenance: Provenance(
              source: 'Lexicomp 2024 / KDIGO 2023',
              reviewedBy: 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
              reviewedAt: '2024-10-29',
            ),
          ),
        ],
      ),
    ],
  ),
  const Drug(
    id: 'valproic_acid',
    genericName: 'Valproic Acid / Sodium Valproate',
    brandNames: ['Depakine'],
    nameTh: 'วาลโปรอิก แอซิด (เดพาคีน)',
    category: DrugCategory.neurological,
    requiresHepaticCaution: true,
    isHighAlert: false,
    requiresTDM: true,
    pregnancyCategory: 'D/X',
    interactions: [
      DrugInteraction(
        targetDrugId: 'meropenem',
        targetClass: DrugClass.betaLactamCarbapenem,
        severity: InteractionSeverity.contraindicated,
        mechanismEn:
            'Carbapenems rapidly decrease serum valproic acid concentrations below therapeutic levels (>50% drop within 24 hours), causing breakthrough seizures.',
        mechanismTh:
            'ยากลุ่มคาร์บาพีเนม (Meropenem) ลดระดับยากันชัก Valproic acid ในเลือดลงอย่างรวดเร็วกว่า 50% ทำให้เกิดอาการชักซ้ำได้',
        managementEn:
            'Avoid coadministration. Select alternative antibacterial therapy or change antiepileptic.',
        managementTh:
            'ห้ามใช้ร่วมกันเด็ดขาด (Contraindicated) ให้เลือกใช้ยาปฏิชีวนะกลุ่มอื่น หรือปรับเปลี่ยนยากันชัก',
        source: 'FDA Valproate Package Insert / AHFS 2024',
      ),
    ],
    severeInteractions: [
      'Carbapenem antibiotics (Meropenem reduces Valproic acid level by >50% - AVOID)',
      'Phenytoin (Displaces protein binding)'
    ],
    contraindications: ['Hepatic disease or significant hepatic dysfunction', 'Urea cycle disorders'],
    specialNotes: 'Target level: 50-100 mcg/mL. Extremely hepatotoxic. NEVER use with Meropenem.',
    specialNotesTh: 'ห้ามจ่ายคู่กับ Meropenem เด็ดขาด (ระดับยากันชักจะตกฮวบ) ระวังตับวาย Target TDM: 50-100',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Seizures / Mania / Migraine Prophylaxis',
        dosingType: DosingType.weightBased,
        dosePerKg: 15.0, // Initial 10-15 mg/kg/day
        doseBasis: DoseBasis.perDay,
        doseUnit: DoseUnit.mg,
        frequency: Frequency(minIntervalHours: 8, maxIntervalHours: 12, displayEn: 'Divided BID-TID', displayTh: 'แบ่งวันละ 2-3 ครั้ง'),
        limits: DoseLimit(
          maxDosePerKgPerDay: 60.0,
        ),
      ),
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Seizures (Pediatric >= 2 years)',
        audience: RegimenAudience.pediatric,
        population: PopulationCriteria(minAgeMonths: 24, maxAgeMonths: 215),
        dosingType: DosingType.weightBased,
        dosePerKg: 15.0, // Initial 10-15 mg/kg/day
        doseBasis: DoseBasis.perDay,
        doseUnit: DoseUnit.mg,
        frequency: Frequency(
          minIntervalHours: 8,
          maxIntervalHours: 12,
          displayEn: 'Divided BID-TID',
          displayTh: 'แบ่งวันละ 2-3 ครั้ง',
        ),
        limits: DoseLimit(
          maxDosePerKgPerDay: 60.0,
        ),
      ),
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Status Epilepticus',
        dosingType: DosingType.weightBased,
        dosePerKg: 20.0, // 20-40 mg/kg
        doseUnit: DoseUnit.mg,
        frequency: Frequency.stat,
        maxInfusionRateMgPerMin: 150.0, // usually up to 3-6 mg/kg/min
        limits: DoseLimit(maxSingleDose: 3000.0),
      ),
    ],
  ),
  const Drug(
    id: 'midazolam',
    genericName: 'Midazolam',
    brandNames: ['Dormicum', 'Versed'],
    nameTh: 'มิดาโซแลม',
    category: DrugCategory.sedative,
    allergyClass: 'Benzodiazepine',
    isHighAlert: true,
    sourceCitation:
        'Ramathibodi High-Alert IV Infusion Guide 2024 / PADIS Guidelines 2018 / Neurocritical Care Society 2016',
    sideEffects: [
      'Sedation, drowsiness, amnesia',
      'Mild hypotension & dizziness',
      'Nausea, vomiting, hiccups',
      'Paradoxical agitation / disinhibition (pediatrics/elderly)',
    ],
    sideEffectsTh: [
      'ง่วงซึม สับสนชั่วคราว สูญเสียความจำระยะสั้น',
      'ความดันโลหิตต่ำเล็กน้อย เวียนศีรษะ',
      'คลื่นไส้ อาเจียน สะอึก',
      'กระสับกระส่ายหรือตื่นตัวผิดปกติ (ในเด็ก/ผู้สูงอายุ)',
    ],
    seriousSideEffects: [
      'Severe respiratory depression, hypoventilation, or apnea',
      'Hypotension & cardiac arrest (with rapid IV bolus or concurrent opioids)',
      'ICU delirium & prolonged weaning with continuous infusion',
      'Physical dependence & withdrawal syndrome after prolonged infusion',
    ],
    seriousSideEffectsTh: [
      'กดการหายใจรุนแรง หรือหยุดหายใจ (โดยเฉพาะเมื่อฉีดร่วมกับ Opioid)',
      'ความดันโลหิตตกวิกฤตหรือหัวใจหยุดเต้นเมื่อฉีด IV เร็วเกินไป',
      'ภาวะสับสนเฉียบพลันในไอซียู (ICU Delirium) และหย่าเครื่องช่วยหายใจยากขึ้น',
      'อาการถอนยาเมื่อหยุดให้ยาหยดต่อเนื่องเป็นเวลานาน',
    ],
    lastReviewedDate: '2024-10-12',
    provenance: Provenance(
      source:
          'Ramathibodi High-Alert IV Infusion Guide 2024 / PADIS Guidelines 2018 / Neurocritical Care Society Status Epilepticus 2016',
      reviewedBy: 'Pending Clinical Pharmacist Sign-off',
      reviewedAt: '2024-10-12',
      sourceDetail:
          'ICU Continuous Sedation & Refractory Status Epilepticus Infusion Protocols',
    ),
    monograph: ClinicalMonograph(
      textbookName:
          'Ramathibodi High-Alert IV Infusion Guide / PADIS Guidelines 2018',
      editionYear: '2024 Manual / 2018 Guidelines',
      sectionOrTable:
          'Midazolam Continuous Infusion & Status Epilepticus Protocol',
      dosingGuideline:
          '• ICU Sedation (การให้ยาต่อเนื่อง): 0.02–0.1 mg/kg/hr ปรับ Titrate ทุก 15–30 นาที ตาม Sedation score (RASS -1 to -2)\n'
          '• Refractory Status Epilepticus (สถานะชักต่อเนื่องดื้อยา): โหลด 0.2 mg/kg IV bolus ตามด้วย 0.05–2.0 mg/kg/hr Titrate ตามคลื่นสมอง EEG burst suppression\n'
          '• Procedural Sedation: 0.5–2.0 mg ฉีด IV ช้าๆ ใน 2 นาที (ขนาดสูงสุดไม่เกิน 2.5 mg ต่อครั้ง)',
      renalGuideline:
          '• เมแทบอไลต์ที่ออกฤทธิ์ (1-hydroxymidazolam glucuronide) ขับออกทางไตเป็นหลัก\n'
          '• ในผู้ป่วยไตบกพร่อง (CrCl < 30 mL/min) ยาจะสะสมทำให้ผู้ป่วยตื่นช้าและโคม่าเป็นเวลานาน ควรปรับลดขนาดยาหรือเปลี่ยนเป็นยานอนหลับชนิดอื่น (เช่น Propofol หรือ Dexmedetomidine)',
      administrationGuideline:
          '• การผสมยามาตรฐาน: 50 mg ใน NSS หรือ D5W 50 mL (1.0 mg/mL) หรือ 100 mg ใน 100 mL (1.0 mg/mL)\n'
          '• สูตรความเข้มข้นจำกัดน้ำ: 100 mg ใน 50 mL (2.0 mg/mL)\n'
          '• ยาแก้พิษ (Antidote): Flumazenil 0.2 mg IV push ใน 15 วินาที (ระวังการชักถอนยาในผู้ป่วยติด Benzodiazepine หรือโรคลมชัก)',
      clinicalNotes:
          '• ยาเตือนภัยสูงระดับวิกฤต (High-Alert Sedative)\n'
          '• กดการหายใจและความดันโลหิต ต้องติดตาม SpO2, EKG และความดันโลหิตต่อเนื่อง\n'
          '• ระวังอาการเพ้อในหอผู้ป่วยวิกฤต (ICU Delirium) จากยากลุ่ม Benzodiazepine',
      externalUrl:
          'https://www.sccm.org/Research/Clinical-Guidelines/PADIS-Guidelines',
    ),
    specialNotes:
        'Active metabolite accumulates in renal failure. Monitor for prolonged sedation and respiratory depression.',
    specialNotesTh:
        'เมแทบอไลต์สะสมในผู้ป่วยไตวาย ติดตามอาการกดการหายใจและการตื่นตัวช้า ยาแก้พิษคือ Flumazenil',
    ivDiluentCompatibility: IvDiluentCompatibility(
      compatibleDiluents: [IvDiluent.nss, IvDiluent.d5w],
      preferredDiluent: IvDiluent.nss,
      stabilityNoteEn:
          '50 mg in 50 mL NSS or D5W (1.0 mg/mL). Protect from light. Stable for 24 hours at room temperature.',
      stabilityNoteTh:
          '50 มก. ใน 50 มล. NSS หรือ D5W (1.0 มก./มล.) ป้องกันแสง คงตัว 24 ชั่วโมงที่อุณหภูมิห้อง',
      sourceCitation: 'Ramathibodi High-Alert IV Guide 2024 / Lexicomp 2024',
    ),
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'ICU Sedation (Continuous Infusion)',
        dosingType: DosingType.titrated,
        doseUnit: DoseUnit.mg,
        continuousRateMin: 0.02,
        continuousRateMax: 0.10,
        continuousRateUnit: 'mg/kg/hr',
        rateUnit: RateUnit.mgKgHr,
        standardDilutionMgPerMl: 1.0, // 50 mg in 50 mL = 1 mg/mL
        verificationStatus: VerificationStatus.pendingReview,
        frequency: Frequency.continuous,
        limits: DoseLimit(
          maxInfusionRate: 0.20,
          infusionRateUnit: 'mg/kg/hr',
        ),
      ),
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Refractory Status Epilepticus Infusion',
        dosingType: DosingType.titrated,
        doseUnit: DoseUnit.mg,
        continuousRateMin: 0.05,
        continuousRateMax: 2.0,
        continuousRateUnit: 'mg/kg/hr',
        rateUnit: RateUnit.mgKgHr,
        standardDilutionMgPerMl: 1.0,
        verificationStatus: VerificationStatus.pendingReview,
        frequency: Frequency.continuous,
        limits: DoseLimit(
          maxInfusionRate: 2.0,
          infusionRateUnit: 'mg/kg/hr',
        ),
      ),
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Procedural Sedation (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 1.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.stat,
        limits: DoseLimit(
          maxSingleDose: 2.5,
          maxDailyDose: 10.0,
        ),
      ),
    ],
  ),
  const Drug(
    id: 'propofol',
    genericName: 'Propofol',
    brandNames: ['Diprivan', 'Fresofol', 'Recofol'],
    nameTh: 'โพรโพฟอล',
    category: DrugCategory.sedative,
    isHighAlert: true,
    sourceCitation:
        'PADIS Guidelines 2018 / Ramathibodi High-Alert Guide 2024 / US FDA Diprivan SPL',
    lastReviewedDate: '2024-10-12',
    provenance: Provenance(
      source:
          'PADIS Guidelines 2018 / Ramathibodi High-Alert Guide 2024 / US FDA Diprivan SPL',
      reviewedBy: 'Pending Clinical Pharmacist Sign-off',
      reviewedAt: '2024-10-12',
      sourceDetail:
          'ICU Sedation, General Anesthesia Induction, and Propofol Infusion Syndrome (PRIS) Safety Protocols',
    ),
    monograph: ClinicalMonograph(
      textbookName: 'PADIS Guidelines 2018 / US FDA Diprivan SPL',
      editionYear: '2018 Guidelines / 2024 Label',
      sectionOrTable:
          'Propofol ICU Sedation & Propofol Infusion Syndrome (PRIS) Warning',
      dosingGuideline:
          '• ICU Sedation (ผู้ป่วยใส่ท่อช่วยหายใจ): เริ่มต้น 5 mcg/kg/min (0.3 mg/kg/hr) ปรับ Titrate เพิ่มครั้งละ 5–10 mcg/kg/min ทุก 5–10 นาที ขนาดยาปกติ 5–50 mcg/kg/min (0.3–3.0 mg/kg/hr)\n'
          '• การระงับความรู้สึกนำสลบ (RSI / Anesthesia Induction): 1.5–2.5 mg/kg IV push ช้าๆ\n'
          '• การผ่าตัดหรือหัตถการสั้น (Procedural Sedation): 0.5–1.0 mg/kg IV bolus ช้าๆ ใน 1–5 นาที\n'
          '• คำเตือนวิกฤต PRIS: ห้ามให้ยาขนาดเกิน 4–5 mg/kg/hr (ประมาณ 67–83 mcg/kg/min) หรือให้นานเกิน 48 ชั่วโมง เนื่องจากเสี่ยงต่อกลุ่มอาการ Propofol Infusion Syndrome (PRIS) ถึงแก่ชีวิต',
      renalGuideline:
          '• ไม่จำเป็นต้องปรับขนาดยาตามค่าไต (No renal dose adjustment needed)\n'
          '• เมแทบอไลต์ขับออกทางไต แต่ไม่มีฤทธิ์กดประสาท',
      administrationGuideline:
          '• สารละลายและอิมัลชัน: 1% lipid emulsion (10 mg/mL หรือ 10,000 mcg/mL) บริหารยาแบบ Neat infusion โดยตรง ไม่แนะนำให้เจือจาง\n'
          '• หากจำเป็นต้องเจือจาง ให้ผสมใน D5W เท่านั้น โดยความเข้มข้นต้องไม่ต่ำกว่า 2 mg/mL\n'
          '• การควบคุมการติดเชื้อ: ยามีส่วนผสมของไขมันถั่วเหลืองและไข่ไก่ ไม่มีสารกันเสีย ต้องเปลี่ยนชุดให้ยาทุก 12 ชั่วโมง และทิ้งขวดที่เปิดแล้วภายใน 12 ชั่วโมง\n'
          '• พลังงานแคลอรี่: อิมัลชันไขมัน 10% ให้พลังงาน 1.1 kcal/mL ต้องนำไปคำนวณหักลบในสารอาหารทางสายให้อาหาร',
      clinicalNotes:
          '• จัดเป็นยาเตือนภัยสูงระดับวิกฤต (High-Alert Anesthetic/Sedative)\n'
          '• เฝ้าระวังความดันโลหิตตกอย่างรุนแรง (Hypotension) และหัวใจเต้นช้า (Bradycardia)\n'
          '• ต้องตรวจระดับ Triglycerides ในเลือดหากให้นานเกิน 48 ชั่วโมง',
      externalUrl:
          'https://www.sccm.org/Research/Clinical-Guidelines/PADIS-Guidelines',
    ),
    specialNotes:
        'PRIS Warning: Infusions > 4-5 mg/kg/hr (> 83 mcg/kg/min) or > 48h risk fatal Propofol Infusion Syndrome.',
    specialNotesTh:
        'คำเตือน PRIS: การให้ยาเกิน 4-5 mg/kg/hr (> 83 mcg/kg/min) หรือนานเกิน 48 ชม. เสี่ยงต่อภาวะหัวใจวายและกรดเกินในเลือดรุนแรงถึงแก่ชีวิต',
    ivDiluentCompatibility: IvDiluentCompatibility(
      compatibleDiluents: [IvDiluent.d5w],
      preferredDiluent: IvDiluent.d5w,
      incompatibleDiluents: [IvDiluent.nss, IvDiluent.lrs],
      incompatibilityReasonEn:
          'Emulsion breakdown with NSS/LRS; administer undiluted.',
      incompatibilityReasonTh:
          'อิเล็กโทรไลต์ใน NSS/LRS ทำให้อิมัลชันแตกตัว; ให้ยาโดยไม่เจือจาง',
      stabilityNoteEn:
          '10 mg/mL (1%) emulsion; change tubing and bottle every 12 h.',
      stabilityNoteTh:
          'อิมัลชัน 10 mg/mL (1%); เปลี่ยนสายและขวดยาทุก 12 ชม.',
      sourceCitation: 'US FDA Diprivan SPL §2.4 / Lexicomp 2024',
    ),
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'ICU Sedation (Mechanically Ventilated)',
        dosingType: DosingType.titrated,
        doseUnit: DoseUnit.mcg,
        continuousRateMin: 5.0,
        continuousRateMax: 50.0,
        continuousRateUnit: 'mcg/kg/min',
        rateUnit: RateUnit.mcgKgMin,
        standardDilutionMgPerMl: 10.0, // 10 mg/mL (1% emulsion)
        verificationStatus: VerificationStatus.pendingReview,
        frequency: Frequency.continuous,
        limits: DoseLimit(
          maxInfusionRate: 83.0, // > 5 mg/kg/hr = ~83 mcg/kg/min PRIS ceiling
          infusionRateUnit: 'mcg/kg/min',
        ),
      ),
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Procedural Sedation',
        dosingType: DosingType.weightBased,
        dosePerKg: 0.5,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.stat,
        limits: DoseLimit(
          maxSingleDose: 100.0,
        ),
      ),
    ],
  ),
  const Drug(
    id: 'dexmedetomidine',
    genericName: 'Dexmedetomidine',
    brandNames: ['Precedex'],
    nameTh: 'เดกซ์เมดีโทมิดีน',
    category: DrugCategory.sedative,
    sideEffects: ['Bradycardia', 'Hypotension'],
    sideEffectsTh: ['หัวใจเต้นช้า', 'ความดันโลหิตต่ำ'],
    isHighAlert: true,
    sourceCitation:
        'PADIS Guidelines 2018 / Lexicomp 2024 / US FDA Precedex SPL',
    lastReviewedDate: '2024-10-12',
    provenance: Provenance(
      source: 'PADIS Guidelines 2018 / Lexicomp 2024 / US FDA Precedex SPL',
      reviewedBy: 'Pending Clinical Pharmacist Sign-off',
      reviewedAt: '2024-10-12',
      sourceDetail:
          'Non-GABAergic ICU Sedation & Delirium Reduction Continuous Infusion Protocols',
    ),
    monograph: ClinicalMonograph(
      textbookName: 'PADIS Guidelines 2018 / US FDA Precedex SPL',
      editionYear: '2018 Guidelines / 2024 Label',
      sectionOrTable:
          'Dexmedetomidine ICU Sedation & Non-intubated Sedation Protocol',
      dosingGuideline:
          '• ICU Sedation (การให้ยาต่อเนื่อง): 0.2–1.4 mcg/kg/hr เริ่มต้น 0.2–0.7 mcg/kg/hr ปรับ Titrate เพิ่มครั้งละ 0.1–0.2 mcg/kg/hr ทุก 30 นาที จนได้ระดับ Sedation ที่ต้องการ (RASS 0 to -1)\n'
          '• Loading Dose (ขนาดเริ่มต้น): 1 mcg/kg นาน 10 นาที (หมายเหตุ: ใน ICU ปัจจุบันมักงด Loading dose เพื่อหลีกเลี่ยงภาวะหัวใจเต้นช้าและความดันโลหิตตกเฉียบพลัน)\n'
          '• ข้อได้เปรียบทางคลินิก: ไม่กดการหายใจ ผู้ป่วยสามารถสื่อสารและปลุกตื่นได้ง่าย (Cooperative sedation) และช่วยลดภาวะเพ้อสับสนในไอซียู (Delirium)',
      renalGuideline:
          '• ไม่จำเป็นต้องปรับลดขนาดยาตามการทำงานของไต (No renal dose adjustment needed)\n'
          '• ถูกเมแทบอไลต์ในตับเป็นหลักผ่านกระบวนการ Glucuronidation และ CYP2A6',
      administrationGuideline:
          '• การผสมยามาตรฐาน: 200 mcg ใน NSS หรือ D5W 50 mL (ความเข้มข้น 4 mcg/mL หรือ 0.004 mg/mL)\n'
          '• หากต้องการปริมาตร 100 mL: 400 mcg ใน 100 mL (4 mcg/mL)\n'
          '• เส้นทางการให้ยา: สามารถให้ผ่านหลอดเลือดดำส่วนปลาย (Peripheral IV) หรือหลอดเลือดดำใหญ่ (Central Line) ได้',
      clinicalNotes:
          '• ยาเตือนภัยสูงระดับวิกฤต (High-Alert Selective Alpha-2 Agonist)\n'
          '• ผลข้างเคียงสำคัญ: Bradycardia และ Hypotension ต้องเฝ้าระวังอัตราการเต้นของหัวใจและความดันโลหิตอย่างใกล้ชิด\n'
          '• หากหยุดยากะทันหันหลังใช้นานเกิน 48 ชม. อาจเกิด Rebound hypertension ได้',
      externalUrl:
          'https://www.sccm.org/Research/Clinical-Guidelines/PADIS-Guidelines',
    ),
    specialNotes:
        'Alpha-2 agonist. Minimal respiratory depression. Monitor heart rate and blood pressure for bradycardia/hypotension.',
    specialNotesTh:
        'ยากระตุ้น Alpha-2 ไม่กดการหายใจ เฝ้าระวังชีพจรเต้นช้าและความดันตกอย่างใกล้ชิด',
    ivDiluentCompatibility: IvDiluentCompatibility(
      compatibleDiluents: [IvDiluent.nss, IvDiluent.d5w],
      preferredDiluent: IvDiluent.nss,
      stabilityNoteEn:
          '200 mcg in 50 mL NSS or D5W (4 mcg/mL). Stable for 24 hours at room temperature.',
      stabilityNoteTh:
          '200 มคก. ใน 50 มล. NSS หรือ D5W (4 มคก./มล.) คงตัว 24 ชั่วโมงที่อุณหภูมิห้อง',
      sourceCitation: 'US FDA Precedex SPL §2.4 / Lexicomp 2024',
    ),
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'ICU Sedation (Delirium-sparing)',
        dosingType: DosingType.titrated,
        doseUnit: DoseUnit.mcg,
        continuousRateMin: 0.2,
        continuousRateMax: 1.4,
        continuousRateUnit: 'mcg/kg/hr',
        rateUnit: RateUnit.mcgKgHr,
        standardDilutionMgPerMl: 0.004, // 4 mcg/mL = 0.004 mg/mL
        verificationStatus: VerificationStatus.pendingReview,
        frequency: Frequency.continuous,
        limits: DoseLimit(
          maxInfusionRate: 1.4,
          infusionRateUnit: 'mcg/kg/hr',
        ),
      ),
    ],
  ),
];

