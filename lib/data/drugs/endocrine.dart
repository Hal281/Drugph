import '../../core/models/models.dart';

final List<Drug> endocrine = [
  const Drug(
    id: 'glipizide',
    genericName: 'Glipizide',
    brandNames: ['Minidiab', 'Glucotrol'],
    nameTh: 'กลิพิไซด์',
    category: DrugCategory.endocrine,
    pregnancyCategory: 'C',
    requiresHepaticCaution: true,
    requiresRenalAdjustment: true,
    severeInteractions: ['Fluconazole (increases glipizide levels)'],
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Type 2 Diabetes',
        dosingType: DosingType.fixed,
        fixedDose: 5,
        doseUnit: DoseUnit.mg,
        frequency: Frequency(minIntervalHours: 12, maxIntervalHours: 24, displayEn: 'OD to BID (before meals)', displayTh: 'วันละ 1-2 ครั้ง (ก่อนอาหาร 30 นาที)'),
        limits: DoseLimit(maxDailyDose: 40),
        renalAdjustments: [
          RenalAdjustment(
            crclMin: 0,
            crclMax: 50,
            action: RenalAction.adjust,
            adjustmentFactor: 0.5,
            notes: 'Reduce dose by 50% in CrCl < 50 mL/min; high risk of severe hypoglycemia',
            notesTh: 'ลดขนาดยาลง 50% ใน CrCl < 50 มล./นาที เพื่อป้องกันภาวะน้ำตาลในเลือดต่ำรุนแรง',
          ),
        ],
      ),
    ],
  ),
  const Drug(
    id: 'empagliflozin',
    genericName: 'Empagliflozin',
    brandNames: ['Jardiance'],
    nameTh: 'เอ็มพากลิโฟลซิน',
    category: DrugCategory.endocrine,
    pregnancyCategory: 'D',
    requiresRenalAdjustment: true,
    contraindications: ['eGFR < 30 (not recommended for glycemic control)'],
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Type 2 Diabetes / Heart Failure',
        dosingType: DosingType.fixed,
        fixedDose: 10,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q24h,
        limits: DoseLimit(maxDailyDose: 25),
        renalAdjustments: [
          RenalAdjustment(
            crclMin: 20,
            crclMax: 30,
            action: RenalAction.adjust,
            absoluteDose: 10.0,
            notes: 'Max 10 mg OD for CV/CKD benefits; not effective for glycemic control',
            notesTh: 'ขนาดยาสูงสุด 10 mg วันละครั้งสำหรับประโยชน์ด้านหัวใจและชะลอไตเสื่อม ไม่แนะนำใช้คุมน้ำตาล',
          ),
          RenalAdjustment(
            crclMin: 0,
            crclMax: 20,
            action: RenalAction.avoid,
            notes: 'Avoid / not recommended in eGFR/CrCl < 20 mL/min',
            notesTh: 'หลีกเลี่ยงหรือไม่แนะนำให้ใช้ในผู้ป่วย eGFR/CrCl < 20 มล./นาที',
          ),
        ],
      ),
    ],
  ),
  const Drug(
    id: 'sitagliptin',
    genericName: 'Sitagliptin',
    brandNames: ['Januvia'],
    nameTh: 'ซิทากลิปติน',
    category: DrugCategory.endocrine,
    pregnancyCategory: 'B',
    requiresRenalAdjustment: true,
    regimens: [
      DosingRegimen(
          route: DoseRoute.po,
          indication: 'Type 2 Diabetes',
          dosingType: DosingType.fixed,
          fixedDose: 100,
          doseUnit: DoseUnit.mg,
          frequency: Frequency.q24h,
          limits: DoseLimit(maxDailyDose: 100),
          renalAdjustments: [
            RenalAdjustment(
                crclMin: 30,
                crclMax: 50,
                adjustmentFactor: 0.5,
                notes: '50 mg OD'),
            RenalAdjustment(
                crclMin: 0,
                crclMax: 30,
                adjustmentFactor: 0.25,
                notes: '25 mg OD'),
          ]),
    ],
  ),
  const Drug(
    id: 'pioglitazone',
    genericName: 'Pioglitazone',
    brandNames: ['Actos'],
    nameTh: 'ไพโอกลิตาโซน',
    category: DrugCategory.endocrine,
    pregnancyCategory: 'C',
    contraindications: ['Heart Failure (NYHA Class III, IV)'],
    severeInteractions: ['Gemfibrozil (increases pioglitazone levels)'],
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Type 2 Diabetes',
        dosingType: DosingType.fixed,
        fixedDose: 15, // 15-30mg
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q24h,
        limits: DoseLimit(maxDailyDose: 45),
      ),
    ],
  ),
  const Drug(
    id: 'levothyroxine',
    genericName: 'Levothyroxine',
    brandNames: ['Eltroxin', 'Thyrosit'],
    nameTh: 'เลโวไทรอกซีน',
    category: DrugCategory.endocrine,
    pregnancyCategory: 'A',
    severeInteractions: [
      'Iron',
      'Calcium',
      'Antacids (Decreases absorption, separate by 4h)'
    ],
    specialNotes: 'Take on an empty stomach, 30-60 min before breakfast.',
    specialNotesTh: 'ทานตอนท้องว่าง ก่อนอาหารเช้าอย่างน้อย 30-60 นาที',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Hypothyroidism (Adult)',
        dosingType: DosingType.weightBased,
        dosePerKg: 1.6,
        doseUnit: DoseUnit.mcg,
        frequency: Frequency.q24h,
        limits: DoseLimit(maxDailyDose: 300),
      ),
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Hypothyroidism (Elderly/CAD)',
        dosingType: DosingType.fixed,
        fixedDose: 25, // Start low 12.5-25 mcg
        doseUnit: DoseUnit.mcg,
        frequency: Frequency.q24h,
      ),
    ],
  ),
  const Drug(
    id: 'methimazole',
    genericName: 'Methimazole',
    brandNames: ['Tapazole'],
    nameTh: 'เมทิมาโซล',
    category: DrugCategory.endocrine,
    pregnancyCategory: 'D', // 1st trimester use PTU instead
    severeInteractions: ['Warfarin'],
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Hyperthyroidism',
        dosingType: DosingType.fixed,
        fixedDose: 15, // 15-60mg divided doses
        doseUnit: DoseUnit.mg,
        frequency: Frequency(minIntervalHours: 8, maxIntervalHours: 24, displayEn: 'OD to TID', displayTh: 'วันละ 1-3 ครั้ง'),
        limits: DoseLimit(maxDailyDose: 120),
      ),
    ],
  ),
  const Drug(
    id: 'propylthiouracil',
    genericName: 'Propylthiouracil (PTU)',
    brandNames: ['PTU'],
    nameTh: 'โพรพิลไทโอยูราซิล',
    category: DrugCategory.endocrine,
    pregnancyCategory: 'D', // Preferred in 1st trimester over Methimazole
    requiresHepaticCaution: true,
    specialNotes: 'Black box warning for severe liver injury.',
    specialNotesTh: 'ระวังตับอักเสบรุนแรง',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Hyperthyroidism',
        dosingType: DosingType.fixed,
        fixedDose: 100, // 300-400mg daily divided q8h
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q8h,
        limits: DoseLimit(maxDailyDose: 900),
      ),
    ],
  ),
  const Drug(
    id: 'insulin_glargine',
    genericName: 'Insulin Glargine',
    brandNames: ['Lantus', 'Toujeo'],
    nameTh: 'อินซูลิน กลาร์จีน',
    category: DrugCategory.endocrine,
    pregnancyCategory: 'C',
    isHighAlert: true,
    specialNotes: 'Long-acting basal insulin. Do not mix with other insulins.',
    specialNotesTh: 'อินซูลินออกฤทธิ์ยาว (Basal) ห้ามผสมกับอินซูลินชนิดอื่น',
    regimens: [
      DosingRegimen(
        route: DoseRoute.sc,
        indication: 'Diabetes (Basal)',
        dosingType: DosingType.weightBased,
        dosePerKg: 0.2, // Starting dose 0.1-0.2 U/kg
        doseUnit: DoseUnit.units,
        frequency: Frequency.q24h,
        limits: DoseLimit(maxDailyDose: 150),
      ),
    ],
  ),
  const Drug(
    id: 'insulin_regular',
    genericName: 'Insulin Regular (RI)',
    brandNames: ['Actrapid', 'Humulin R'],
    nameTh: 'อินซูลิน เรกูลาร์',
    category: DrugCategory.endocrine,
    tags: ['metabolic'],
    pregnancyCategory: 'B',
    isHighAlert: true,
    allergyClass: 'Insulin',
    sourceCitation: 'ADA Standards of Care in Diabetes 2024 / Endocrine Society DKA Protocol / US FDA Humulin R SPL',
    lastReviewedDate: '2024-10-12',
    provenance: Provenance(
      source: 'ADA Standards of Care in Diabetes 2024 / Endocrine Society Guidelines / US FDA Humulin R SPL',
      reviewedBy: 'Pending Clinical Pharmacist Sign-off',
      reviewedAt: '2024-10-12',
      sourceDetail: 'Hospital Care & DKA / HHS Insulin Infusion Protocol §2.1-2.4',
    ),
    monograph: ClinicalMonograph(
      textbookName: 'ADA Standards of Care in Diabetes / Endocrine Society Guidelines',
      editionYear: '2024',
      sectionOrTable: 'Hospital Care & DKA / HHS Insulin Infusion Protocol §2.1-2.4',
      dosingGuideline:
          '• ภาวะเลือดเป็นกรดจากคีโตนในเบาหวาน (Diabetic Ketoacidosis - DKA / HHS):\n'
          '  - IV Bolus (ทางเลือก): 0.1 units/kg IV push (สามารถละเว้นได้หากเริ่มหยดต่อเนื่อง 0.14 units/kg/hr ทันที)\n'
          '  - Continuous IV Infusion: 0.1 units/kg/hr (หรือ 0.14 units/kg/hr หากไม่ bolus)\n'
          '  - เป้าหมายการลดระดับน้ำตาล: ลดลงในอัตรา 50–75 mg/dL ต่อชั่วโมง หากลดน้อยกว่า 50 mg/dL/hr ให้เพิ่มอัตราการหยดยาขึ้น 50–100%\n'
          '  - เมื่อน้ำตาลในเลือดลดลงถึง 200 mg/dL (DKA) หรือ 300 mg/dL (HHS): เปลี่ยนสารน้ำเป็น 5% Dextrose ร่วมกับลดอัตราการหยดอินซูลินลงเหลือ 0.02–0.05 units/kg/hr เพื่อรักษาระดับน้ำตาลที่ 150–200 mg/dL จนกว่าจะหายจากภาวะคีโตซิส (Resolution of DKA: Anion gap ปกติ, Venous pH > 7.3, Bicarbonate >= 18 mEq/L)\n'
          '• การฉีดใต้ผิวหนังตามมื้ออาหาร (Prandial / Sliding Scale):\n'
          '  - ฉีดเข้าใต้ผิวหนัง (SC) 30 นาทีก่อนอาหาร ปรับตามระดับน้ำตาลและปริมาณคาร์โบไฮเดรต',
      renalGuideline:
          '• ไตมีหน้าที่ทำลายและกรองอินซูลินประมาณ 30–80% ของร่างกาย\n'
          '• ในผู้ป่วยไตวาย (CrCl < 50 mL/min หรือ ESRD): การกำจัดอินซูลินลดลงอย่างมาก ค่าครึ่งชีวิตยาวนานขึ้น ส่งผลให้ความต้องการอินซูลินลดลง 25–50%\n'
          '• เสี่ยงต่อภาวะน้ำตาลในเลือดต่ำรุนแรงและยาวนาน (Severe Prolonged Hypoglycemia) ต้องปรับลดยาและติดตามค่าน้ำตาลบ่อยขึ้นอย่างใกล้ชิด',
      administrationGuideline:
          '• การผสมสารละลายมาตรฐานสำหรับ IV Infusion: Regular Insulin 100 units ใน NSS 100 mL (ความเข้มข้น 1 unit/mL)\n'
          '• การเตรียมสายน้ำเกลือ (Tubing Priming Rule): ตัวยาอินซูลินจะจับติดกับผนังพลาสติกของสายน้ำเกลือ (Adsorption to PVC tubing) ดังนั้น ก่อนเริ่มให้ยาแก่ผู้ป่วย ต้องเปิดสารละลายอินซูลินที่ผสมแล้วให้ไหลผ่านสายทิ้งไปก่อนอย่างน้อย 20–50 mL เพื่อให้ผนังสายอิ่มตัวด้วยอินซูลิน\n'
          '• ต้องให้ผ่านเครื่องควบคุมอัตราการให้ยา (Infusion Pump) เสมอ',
      clinicalNotes:
          '• จัดเป็นยาเตือนภัยสูงระดับวิกฤต (Critical High-Alert Medication)\n'
          '• เงื่อนไขความปลอดภัยก่อนเริ่มให้อินซูลินใน DKA (Mandatory Safety Pre-check):\n'
          '  - ห้ามเริ่มให้อินซูลินเด็ดขาดหากระดับโพแทสเซียมในเลือด (Serum K+) < 3.3 mEq/L เนื่องจากอินซูลินจะดึงโพแทสเซียมเข้าสู่เซลล์อย่างรวดเร็ว ก่อให้เกิดภาวะ Hypokalemia รุนแรง นำไปสู่ Cardiac Arrest ได้ ต้องให้สารน้ำและ Potassium supplement จน K+ >= 3.3 mEq/L ก่อนเริ่มยาเสมอ\n'
          '  - ตรวจระดับน้ำตาลปลายนิ้ว (Capillary Blood Glucose) ทุก 1 ชั่วโมง และระดับเกลือแร่ (Electrolytes, K+, HCO3-) ทุก 2–4 ชั่วโมง',
      externalUrl: 'https://dailymed.nlm.nih.gov/dailymed/search.cfm?labeltype=all&query=insulin',
    ),
    severeInteractions: [
      'Thiazolidinediones (e.g. Pioglitazone) - Increased risk of heart failure',
      'Beta-blockers - May mask symptoms of hypoglycemia',
    ],
    contraindications: ['Episodes of hypoglycemia'],
    specialNotes:
        'HIGH ALERT MEDICATION. Dosed in UNITS. Risk of severe hypoglycemia and hypokalemia.',
    specialNotesTh:
        'ยาความเสี่ยงสูง (High Alert) หน่วยเป็น ยูนิต (Units) ระวังภาวะน้ำตาลตกและโพแทสเซียมในเลือดต่ำรุนแรง',
    ivDiluentCompatibility: IvDiluentCompatibility(
      compatibleDiluents: [IvDiluent.nss, IvDiluent.halfNss],
      preferredDiluent: IvDiluent.nss,
      incompatibleDiluents: [IvDiluent.d5w],
      incompatibilityReasonEn:
          'CLINICAL DKA/HHS DILUENT HAZARD: Prepare continuous insulin drip in 0.9% NaCl (NSS) 100 units/100 mL (1 unit/mL) — do NOT mix the insulin bag itself in D5W. Add separate D5W maintenance fluid via Y-site only once glucose falls to <= 200 mg/dL (DKA) or <= 300 mg/dL (HHS).',
      incompatibilityReasonTh:
          'ห้ามผสมถุงอินซูลินดริปใน D5W: ต้องเตรียม Regular Insulin 100 units ใน 0.9% NaCl (NSS) 100 mL (1 unit/mL) เท่านั้น และต่อสาย D5W แยกต่างหากเมื่อระดับน้ำตาลลดลงถึง <= 200 mg/dL (DKA) หรือ <= 300 mg/dL (HHS)',
      stabilityNoteEn:
          'Flush 20–50 mL of prepared insulin solution through PVC IV tubing before connecting to patient to saturate plastic adsorption sites.',
      stabilityNoteTh:
          'ต้องเปิดสารละลายอินซูลินที่ผสมแล้วไล่ผ่านสายน้ำเกลือทิ้ง 20–50 mL ก่อนต่อเข้าผู้ป่วยเสมอ เพื่อให้ผนังสาย PVC อิ่มตัวจากการดูดซับยา',
      sourceCitation:
          'ADA Standards of Care in Diabetes 2024 / US FDA Humulin R SPL / คู่มือยาฉีดความเสี่ยงสูง รามาธิบดี',
    ),
    regimens: [
      DosingRegimen(
        route: DoseRoute.sc,
        indication: 'Diabetes (Prandial / Sliding Scale)',
        dosingType: DosingType.fixed,
        fixedDose: 4, // Variable based on sliding scale
        doseUnit: DoseUnit.units,
        frequency: Frequency.q8h,
        verificationStatus: VerificationStatus.pendingReview,
      ),
      DosingRegimen(
        route: DoseRoute.iv,
        indication: 'Diabetic Ketoacidosis (DKA)',
        dosingType: DosingType.titrated,
        doseUnit: DoseUnit.units,
        frequency: Frequency.continuous,
        continuousRateMin: 0.05,
        continuousRateMax: 0.2,
        continuousRateUnit: 'units/kg/hr',
        rateUnit: RateUnit.uKgHr,
        standardDilutionMgPerMl: 1.0, // 100 Units in 100 mL NS = 1 Unit/mL
        standardDilution: Concentration(1.0, ConcentrationUnit.unitsPerMl),
        verificationStatus: VerificationStatus.pendingReview,
        phases: [
          DosingPhase(
            type: PhaseType.bolus,
            role: DoseRole.start,
            nameEn: 'Initial IV Bolus (Optional)',
            nameTh: 'ฉีดเข้าหลอดเลือดดำทันที (ถ้าจำเป็น)',
            dosePerKg: 0.1,
            doseUnit: DoseUnit.units,
            instructionsEn:
                '0.1 units/kg IV bolus (often omitted if continuous infusion started promptly)',
            instructionsTh:
                '0.1 ยูนิต/กก. ฉีดเข้าหลอดเลือดดำ (อาจละเว้นได้หากเริ่มหยดต่อเนื่องทันที)',
          ),
          DosingPhase(
            type: PhaseType.infusion,
            role: DoseRole.usual,
            nameEn: 'Continuous Infusion',
            nameTh: 'หยดเข้าหลอดเลือดดำต่อเนื่อง (Infusion)',
            rate: 0.1,
            rateUnit: RateUnit.uKgHr,
            instructionsEn:
                '0.1 units/kg/hr (or 0.14 units/kg/hr if no bolus), adjust to lower BG 50-75 mg/dL/hr',
            instructionsTh:
                '0.1 ยูนิต/กก./ชม. ปรับเพื่อให้น้ำตาลลดลง 50-75 มก./ดล./ชม.',
          ),
        ],
      ),
    ],
  ),
];
