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
    severeInteractions: [
      'Thiazolidinediones (e.g. Pioglitazone) - Increased risk of heart failure',
      'Beta-blockers - May mask symptoms of hypoglycemia',
    ],
    contraindications: ['Episodes of hypoglycemia'],
    specialNotes:
        'HIGH ALERT MEDICATION. Dosed in UNITS. Risk of severe hypoglycemia and hypokalemia.',
    specialNotesTh:
        'ยาความเสี่ยงสูง (High Alert) หน่วยเป็น ยูนิต (Units) ระวังภาวะน้ำตาลตกและโพแทสเซียมในเลือดต่ำรุนแรง',
    regimens: [
      DosingRegimen(
        route: DoseRoute.sc,
        indication: 'Diabetes (Prandial / Sliding Scale)',
        dosingType: DosingType.fixed,
        fixedDose: 4, // Variable based on sliding scale
        doseUnit: DoseUnit.units,
        frequency: Frequency.q8h,
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
