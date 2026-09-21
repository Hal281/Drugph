import '../../core/models/models.dart';

/// Dermatology, Ophthalmology, ENT, and Topical drugs.
final List<Drug> topical = [
  Drug(
    id: 'silver_sulfadiazine',
    genericName: 'Silver Sulfadiazine 1% Cream',
    brandNames: ['Silvadene', 'Flamazine'],
    nameTh: 'ซิลเวอร์ซัลฟาไดอะซีน ครีม',
    category: DrugCategory.antibiotic,
    allergyClass: 'Sulfonamide (Sulfa)',
    contraindications: ['Premature infants', 'Newborns <2 months', 'Pregnancy at term'],
    specialNotes: 'Apply to clean wound 1-2 times daily with sterile gloves. Transient leukopenia may occur.',
    specialNotesTh: 'ทาบนแผลที่ทำความสะอาดแล้ว วันละ 1-2 ครั้ง ต้องสวมถุงมือปลอดเชื้อ อาจทำให้เม็ดเลือดขาวต่ำชั่วคราว',
    regimens: [
      DosingRegimen(
        route: DoseRoute.topical,
        indication: 'Burns / Wound Infection',
        dosingType: DosingType.fixed,
        fixedDose: 1.0, // apply thin layer
        doseUnit: DoseUnit.application,
        frequency: 'q12h-q24h',
      ),
    ],
  ),
  Drug(
    id: 'mupirocin',
    genericName: 'Mupirocin 2% Ointment',
    brandNames: ['Bactroban'],
    nameTh: 'มิวพิโรซิน',
    category: DrugCategory.antibiotic,
    specialNotes: 'Effective against MRSA skin infections. Apply thin layer to affected area TID for 5-14 days.',
    specialNotesTh: 'ยาฆ่า MRSA ทาผิวหนัง ทาบางๆ วันละ 3 ครั้ง ติดต่อกัน 5-14 วัน',
    regimens: [
      DosingRegimen(
        route: DoseRoute.topical,
        indication: 'Impetigo / MRSA Skin Infection',
        dosingType: DosingType.fixed,
        fixedDose: 1.0,
        doseUnit: DoseUnit.application,
        frequency: 'q8h (TID) for 5-14 days',
      ),
    ],
  ),
];

/// Hematology & Anticoagulant drugs.
final List<Drug> anticoagulants = [
  Drug(
    id: 'warfarin',
    genericName: 'Warfarin',
    brandNames: ['Coumadin', 'Orfarin'],
    nameTh: 'วาร์ฟาริน',
    category: DrugCategory.cardiovascular,
    isHighAlert: true,
    requiresTDM: true, // INR monitoring
    requiresHepaticCaution: true,
    allergyClass: 'Coumarin',
    severeInteractions: [
      'NSAIDs (Increased bleeding risk)',
      'Metronidazole (Increases INR significantly)',
      'Antibiotics (Many alter INR - monitor closely)',
      'Vitamin K-rich foods (Decreases effect)'
    ],
    contraindications: [
      'Active bleeding',
      'Pregnancy (Teratogenic)',
      'Severe hepatic disease',
      'Unsupervised patients'
    ],
    specialNotes: 'Narrow therapeutic index. Target INR 2.0-3.0 for most indications. Vitamin K is antidote.',
    specialNotesTh: 'ยาละลายลิ่มเลือดที่ต้องเจาะเลือดดู INR (เป้าหมาย 2.0-3.0) กินวิตามิน K เป็นยาแก้พิษ ห้ามกินกับผักใบเขียวมากเกินไป',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Anticoagulation (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 5.0, // Initial 5 mg, then adjust by INR
        doseUnit: DoseUnit.mg,
        frequency: 'q24h (OD)',
        limits: DoseLimit(maxDailyDose: 15.0), // Rarely >10mg/day
      ),
    ],
  ),
  Drug(
    id: 'enoxaparin',
    genericName: 'Enoxaparin',
    brandNames: ['Clexane', 'Lovenox'],
    nameTh: 'อีน็อกซาพาริน',
    category: DrugCategory.cardiovascular,
    isHighAlert: true,
    requiresRenalAdjustment: true,
    allergyClass: 'Heparin / LMWH',
    severeInteractions: [
      'Antiplatelet agents (Increased bleeding)',
      'NSAIDs (Increased bleeding)'
    ],
    contraindications: [
      'Active major bleeding',
      'History of heparin-induced thrombocytopenia (HIT)',
      'Severe thrombocytopenia'
    ],
    specialNotes: 'Subcutaneous injection in abdominal wall. Do NOT massage injection site. Anti-Xa monitoring in renal impairment.',
    specialNotesTh: 'ฉีดใต้ผิวหนังบริเวณหน้าท้อง ห้ามนวดตำแหน่งที่ฉีด ต้องเจาะ Anti-Xa ในคนไข้ไตเสื่อม',
    regimens: [
      DosingRegimen(
        route: DoseRoute.sc,
        indication: 'DVT/PE Treatment (Adult)',
        dosingType: DosingType.weightBased,
        dosePerKg: 1.0, // 1 mg/kg q12h
        doseUnit: DoseUnit.mg,
        frequency: 'q12h (BID)',
        limits: DoseLimit(maxSingleDose: 100.0),
        renalAdjustments: [
          RenalAdjustment(crclMin: 0, crclMax: 30, adjustmentFactor: 1.0, adjustedFrequency: '1 mg/kg q24h (OD)', notes: 'Use q24h dosing in CrCl <30'),
        ],
      ),
      DosingRegimen(
        route: DoseRoute.sc,
        indication: 'DVT Prophylaxis (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 40.0, // 40 mg SC q24h
        doseUnit: DoseUnit.mg,
        frequency: 'q24h (OD)',
        renalAdjustments: [
          RenalAdjustment(crclMin: 0, crclMax: 30, adjustmentFactor: 0.75, notes: 'Use 30 mg q24h'),
        ],
      ),
    ],
  ),
  Drug(
    id: 'heparin',
    genericName: 'Unfractionated Heparin (UFH)',
    brandNames: ['Heparin'],
    nameTh: 'เฮปาริน',
    category: DrugCategory.cardiovascular,
    isHighAlert: true,
    requiresTDM: true, // aPTT monitoring
    severeInteractions: [
      'Antiplatelet agents (Increased bleeding)',
      'NSAIDs (Increased bleeding)'
    ],
    contraindications: [
      'Active bleeding',
      'HIT (Heparin-Induced Thrombocytopenia)',
      'Severe thrombocytopenia'
    ],
    specialNotes: 'Monitor aPTT every 6 hours. Target aPTT 1.5-2.5x normal. Protamine sulfate is the antidote.',
    specialNotesTh: 'ต้องเจาะ aPTT ทุก 6 ชม. (เป้าหมาย 1.5-2.5 เท่าของค่าปกติ) ยาแก้พิษคือ Protamine sulfate',
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Anticoagulation (Adult)',
        dosingType: DosingType.weightBased,
        dosePerKg: 80.0, // 80 units/kg bolus
        doseUnit: DoseUnit.units,
        frequency: 'Bolus, then 18 units/kg/hr continuous',
        continuousRateMin: 18.0,
        continuousRateMax: 18.0,
        continuousRateUnit: 'units/kg/hr',
      ),
    ],
  ),
];

/// Vitamins, Supplements, and Electrolyte Replacements.
final List<Drug> supplements = [
  Drug(
    id: 'potassium_chloride',
    genericName: 'Potassium Chloride (KCl)',
    brandNames: ['KCl', 'K-Lor'],
    nameTh: 'โพแทสเซียม คลอไรด์',
    category: DrugCategory.supplement,
    isHighAlert: true, // Concentrated KCl is high alert
    severeInteractions: [
      'ACE Inhibitors / ARBs (Hyperkalemia)',
      'Potassium-sparing Diuretics (Hyperkalemia)'
    ],
    contraindications: ['Hyperkalemia', 'Severe renal impairment with oliguria'],
    specialNotes: 'NEVER give undiluted IV push (cardiac arrest risk). Max IV rate: 10 mEq/hr via peripheral, 20 mEq/hr via central.',
    specialNotesTh: 'ห้ามฉีด IV Push เด็ดขาด (หัวใจหยุดเต้น) อัตราหยดสูงสุด: 10 mEq/hr ทาง peripheral, 20 mEq/hr ทาง central line',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Hypokalemia Replacement (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 20.0, // 20-40 mEq
        doseUnit: DoseUnit.mEq,
        frequency: 'q8h-q12h',
        limits: DoseLimit(maxDailyDose: 200.0),
      ),
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Severe Hypokalemia (Adult IV)',
        dosingType: DosingType.fixed,
        fixedDose: 20.0, // 20 mEq in 100mL over 1-2hr
        doseUnit: DoseUnit.mEq,
        frequency: 'over 1-2 hours, then recheck K+',
        limits: DoseLimit(maxInfusionRate: 10.0, infusionRateUnit: 'mEq/hr'),
      ),
    ],
  ),
  Drug(
    id: 'calcium_gluconate',
    genericName: 'Calcium Gluconate',
    brandNames: ['Calcium Gluconate'],
    nameTh: 'แคลเซียม กลูโคเนต',
    category: DrugCategory.supplement,
    isHighAlert: true,
    severeInteractions: [
      'Digoxin (Increases toxicity - give slowly with ECG)',
      'Ceftriaxone IV (Precipitation in neonates - CONTRAINDICATED in neonates)'
    ],
    specialNotes: 'Give slowly IV over 5-10 min. Monitor heart rate. Extravasation causes tissue necrosis.',
    specialNotesTh: 'ฉีด IV ช้าๆ ใน 5-10 นาที ดูจอมอนิเตอร์หัวใจ ถ้ายารั่วซึมนอกหลอดเลือดจะทำให้เนื้อเยื่อตาย',
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Hyperkalemia / Hypocalcemia (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 1000.0, // 1g (10mL of 10%)
        doseUnit: DoseUnit.mg,
        frequency: 'over 5-10 min, may repeat',
      ),
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Hyperkalemia / Hypocalcemia (Pediatric)',
        dosingType: DosingType.weightBased,
        dosePerKg: 60.0, // 60-100 mg/kg slow IV
        doseUnit: DoseUnit.mg,
        frequency: 'over 5-10 min',
        limits: DoseLimit(maxSingleDose: 3000.0),
      ),
    ],
  ),
  Drug(
    id: 'vitamin_k',
    genericName: 'Phytonadione (Vitamin K1)',
    brandNames: ['Konakion'],
    nameTh: 'วิตามินเค (ไฟโตนาไดโอน)',
    category: DrugCategory.supplement,
    allergyClass: 'Vitamin K',
    specialNotes: 'Antidote for warfarin overdose. SC or slow IV (risk of anaphylactoid reaction with IV). Takes 6-24h for effect.',
    specialNotesTh: 'ยาแก้พิษวาร์ฟาริน ควรฉีดใต้ผิวหนังหรือ IV ช้าๆ ออกฤทธิ์ใน 6-24 ชม.',
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Warfarin Reversal / Major Bleeding (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 10.0, // 10 mg slow IV
        doseUnit: DoseUnit.mg,
        frequency: 'Stat (slow infusion over 30 min)',
        infusionTimeMinutes: 30,
      ),
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Supratherapeutic INR (No bleeding)',
        dosingType: DosingType.fixed,
        fixedDose: 2.5, // 2.5-5 mg PO
        doseUnit: DoseUnit.mg,
        frequency: 'Once, recheck INR in 24h',
      ),
    ],
  ),
];
