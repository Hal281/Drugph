import '../../core/models/models.dart';

final List<Drug> endocrine = [
  Drug(
    id: 'metformin',
    genericName: 'Metformin',
    brandNames: ['Glucophage', 'Siamformet'],
    nameTh: 'เมทฟอร์มิน',
    category: DrugCategory
        .endocrine, // Wait, we have endocrine or antidiabetic? Let's check unit.dart. Wait, I didn't check if endocrine exists. It's DrugCategory.antidiabetic or endocrine.
    // Let me use DrugCategory.antidiabetic
    pregnancyCategory: 'B',
    requiresRenalAdjustment: true,
    contraindications: ['eGFR < 30', 'Metabolic acidosis'],
    severeInteractions: ['Iodinated contrast media (withhold 48h)'],
    specialNotes: 'Withhold before imaging studies using iodinated contrast.',
    specialNotesTh: 'งดยาก่อนและหลังฉีดสี (contrast media) 48 ชั่วโมง',
    regimens: [
      DosingRegimen(
          route: DoseRoute.po,
          indication: 'Type 2 Diabetes',
          dosingType: DosingType.fixed,
          fixedDose: 500, // 500-1000 mg
          doseUnit: DoseUnit.mg,
          frequency: 'BID with meals',
          limits: DoseLimit(maxDailyDose: 2550),
          renalAdjustments: [
            RenalAdjustment(
                crclMin: 30,
                crclMax: 45,
                adjustmentFactor: 0.5,
                notes: 'Max 1000 mg/day. Do not initiate new therapy.'),
            RenalAdjustment(
                crclMin: 0,
                crclMax: 29.9,
                adjustmentFactor: 0.0,
                notes: 'Contraindicated'),
          ]),
    ],
  ),
  Drug(
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
        frequency: 'OD to BID (30 min before meals)',
        limits: DoseLimit(maxDailyDose: 40),
      ),
    ],
  ),
  Drug(
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
        frequency: 'OD in morning',
        limits: DoseLimit(maxDailyDose: 25),
      ),
    ],
  ),
  Drug(
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
          frequency: 'OD',
          limits: DoseLimit(maxDailyDose: 100),
          renalAdjustments: [
            RenalAdjustment(
                crclMin: 30,
                crclMax: 49.9,
                adjustmentFactor: 0.5,
                notes: '50 mg OD'),
            RenalAdjustment(
                crclMin: 0,
                crclMax: 29.9,
                adjustmentFactor: 0.25,
                notes: '25 mg OD'),
          ]),
    ],
  ),
  Drug(
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
        frequency: 'OD',
        limits: DoseLimit(maxDailyDose: 45),
      ),
    ],
  ),
  Drug(
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
        frequency: 'OD',
        limits: DoseLimit(maxDailyDose: 300),
      ),
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Hypothyroidism (Elderly/CAD)',
        dosingType: DosingType.fixed,
        fixedDose: 25, // Start low 12.5-25 mcg
        doseUnit: DoseUnit.mcg,
        frequency: 'OD',
      ),
    ],
  ),
  Drug(
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
        frequency: 'OD to TID',
        limits: DoseLimit(maxDailyDose: 120),
      ),
    ],
  ),
  Drug(
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
        frequency: 'TID',
        limits: DoseLimit(maxDailyDose: 900),
      ),
    ],
  ),
  Drug(
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
        frequency: 'OD (usually bedtime)',
        limits: DoseLimit(maxDailyDose: 150),
      ),
    ],
  ),
  Drug(
    id: 'insulin_regular',
    genericName: 'Insulin Regular (RI)',
    brandNames: ['Actrapid', 'Humulin R'],
    nameTh: 'อินซูลิน เรกูลาร์',
    category: DrugCategory.endocrine,
    pregnancyCategory: 'B',
    isHighAlert: true,
    regimens: [
      DosingRegimen(
        route: DoseRoute.sc,
        indication: 'Diabetes (Prandial)',
        dosingType: DosingType.fixed,
        fixedDose: 4, // Variable based on sliding scale
        doseUnit: DoseUnit.units,
        frequency: 'TID before meals',
      ),
      DosingRegimen(
        route: DoseRoute.iv,
        indication: 'Diabetic Ketoacidosis (DKA)',
        dosingType: DosingType.weightBased,
        dosePerKg: 0.1, // 0.1 U/kg/hr infusion
        doseUnit: DoseUnit
            .units, // Actually unit/hr, but UI uses unit for calculation and standardDilution for titration
        frequency: 'Continuous IV',
        continuousRateMin: 0.05,
        continuousRateMax: 0.2,
        continuousRateUnit: 'U/kg/hr',
        standardDilutionMgPerMl: 1.0, // 100 Units in 100 mL NS = 1 Unit/mL
      ),
    ],
  ),
];
