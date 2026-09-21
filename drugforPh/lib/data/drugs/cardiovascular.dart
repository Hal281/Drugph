import '../../core/models/models.dart';

final List<Drug> cardiovascular = [
  Drug(
    id: 'norepinephrine',
    genericName: 'Norepinephrine',
    brandNames: ['Levophed'],
    nameTh: 'นอร์เอพิเนฟริน',
    category: DrugCategory.vasopressor,
    isHighAlert: true,
    specialNotes:
        'Administer via central line to prevent extravasation necrosis.',
    specialNotesTh:
        'ควรให้ทางหลอดเลือดดำใหญ่เพื่อป้องกันเนื้อเยื่อตายจากการรั่วซึม',
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Septic Shock / Hypotension',
        dosingType: DosingType.titrated,
        continuousRateMin: 0.01,
        continuousRateMax: 3.0,
        continuousRateUnit: 'mcg/kg/min',
        doseUnit: DoseUnit.mcg,
        frequency: 'continuous',
        standardDilutionMgPerMl:
            0.016, // 4mg in 250mL = 0.016 mg/mL (or 16 mcg/mL)
        limits: DoseLimit(
          maxInfusionRate: 3.0,
          infusionRateUnit: 'mcg/kg/min',
        ),
      ),
    ],
  ),
  Drug(
    id: 'dopamine',
    genericName: 'Dopamine',
    brandNames: ['Intropin'],
    nameTh: 'โดปามีน',
    category: DrugCategory.vasopressor,
    isHighAlert: true,
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Hemodynamic Support',
        dosingType: DosingType.titrated,
        continuousRateMin: 2.0,
        continuousRateMax: 20.0,
        continuousRateUnit: 'mcg/kg/min',
        doseUnit: DoseUnit.mcg,
        frequency: 'continuous',
        standardDilutionMgPerMl:
            1.6, // 400mg in 250mL = 1.6 mg/mL (1600 mcg/mL)
        limits: DoseLimit(
          maxInfusionRate: 20.0,
          infusionRateUnit: 'mcg/kg/min',
        ),
      ),
    ],
  ),
  Drug(
    id: 'amiodarone',
    genericName: 'Amiodarone',
    brandNames: ['Cordarone'],
    nameTh: 'อะมิโอดาโรน',
    category: DrugCategory.cardiovascular,
    isHighAlert: true,
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Ventricular Arrhythmias (Stable)',
        dosingType: DosingType.fixed,
        fixedDose: 150.0, // 150 mg over 10 mins
        doseUnit: DoseUnit.mg,
        frequency: 'once',
        infusionTimeMinutes: 10.0,
      ),
    ],
  ),
  Drug(
    id: 'amlodipine',
    genericName: 'Amlodipine',
    brandNames: ['Norvasc', 'Amvaz'],
    nameTh: 'แอมโลดิปีน',
    category: DrugCategory.cardiovascular,
    requiresHepaticCaution: true,
    allergyClass: 'Calcium Channel Blocker (CCB)',
    severeInteractions: [
      'Simvastatin (Max simvastatin dose 20 mg/day)',
      'CYP3A4 Inhibitors (e.g. Clarithromycin, Itraconazole - increases Amlodipine level)'
    ],
    specialNotes:
        'Common side effect is peripheral edema. Start at 2.5 mg in elderly or hepatic impairment.',
    specialNotesTh:
        'ผลข้างเคียงที่พบบ่อยคือขาบวม เริ่มยา 2.5 mg ในผู้สูงอายุหรือโรคตับ',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Hypertension (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 5.0, // 5-10 mg
        doseUnit: DoseUnit.mg,
        frequency: 'q24h (OD)',
        limits: DoseLimit(
          maxSingleDose: 10.0,
          maxDailyDose: 10.0,
        ),
      ),
    ],
  ),
  Drug(
    id: 'enalapril',
    genericName: 'Enalapril',
    brandNames: ['Renitec', 'Enaril'],
    nameTh: 'อีนาลาพริล',
    category: DrugCategory.cardiovascular,
    requiresRenalAdjustment: true,
    allergyClass: 'ACE Inhibitor',
    severeInteractions: [
      'Potassium-sparing diuretics / Potassium supplements (Hyperkalemia)',
      'NSAIDs (May worsen renal function)',
      'Lithium (Increases lithium toxicity)'
    ],
    contraindications: [
      'Pregnancy (Teratogenic)',
      'History of Angioedema',
      'Bilateral renal artery stenosis'
    ],
    specialNotes: 'Monitor potassium and creatinine. May cause dry cough.',
    specialNotesTh: 'ระวังโพแทสเซียมในเลือดสูง และค่าไตแย่ลง อาจทำให้ไอแห้งๆ',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Hypertension / Heart Failure (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 5.0, // 5-20 mg
        doseUnit: DoseUnit.mg,
        frequency: 'q24h or q12h',
        limits: DoseLimit(
          maxDailyDose: 40.0,
        ),
        renalAdjustments: [
          RenalAdjustment(
              crclMin: 0,
              crclMax: 30,
              adjustmentFactor: 0.5,
              notes: 'Start at 2.5 mg/day'),
        ],
      ),
    ],
  ),
  Drug(
    id: 'furosemide',
    genericName: 'Furosemide',
    brandNames: ['Lasix', 'Hyles'],
    nameTh: 'ฟูโรซีไมด์',
    category: DrugCategory.cardiovascular, // or diuretic
    allergyClass: 'Sulfonamide (Sulfa)',
    severeInteractions: [
      'Aminoglycosides (Increased risk of ototoxicity)',
      'Digoxin (Toxicity if hypokalemic)'
    ],
    specialNotes:
        'Monitor potassium (risk of hypokalemia). IV push slowly (max 20mg/min) to prevent ototoxicity.',
    specialNotesTh:
        'ระวังโพแทสเซียมต่ำ (Hypokalemia) การฉีด IV ควรดันยาช้าๆ (ไม่เกิน 20mg/min) เพื่อป้องกันหูหนวก',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Edema / Heart Failure (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 40.0,
        doseUnit: DoseUnit.mg,
        frequency: 'q24h or q12h',
        limits: DoseLimit(
          maxSingleDose: 160.0,
          maxDailyDose: 600.0, // Severe edema/renal failure
        ),
      ),
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Acute Pulmonary Edema (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 40.0, // 40-80 mg
        doseUnit: DoseUnit.mg,
        frequency: 'Stat or q12h',
        limits: DoseLimit(
          maxSingleDose: 200.0,
        ),
      ),
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Edema (Pediatric)',
        dosingType: DosingType.weightBased,
        dosePerKg: 1.0, // 1-2 mg/kg/dose
        doseUnit: DoseUnit.mg,
        frequency: 'q12h to q24h',
        limits: DoseLimit(
          maxDosePerKgPerDay: 6.0,
          maxSingleDose: 40.0,
        ),
      ),
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Edema (Pediatric IV)',
        dosingType: DosingType.weightBased,
        dosePerKg: 1.0,
        doseUnit: DoseUnit.mg,
        frequency: 'q12h to q24h',
        limits: DoseLimit(
          maxDosePerKgPerDay: 6.0,
        ),
      ),
    ],
  ),
  Drug(
    id: 'adenosine',
    genericName: 'Adenosine',
    brandNames: ['Adenocor'],
    nameTh: 'อะดีโนซีน',
    category: DrugCategory.cardiovascular, // Antiarrhythmic
    isHighAlert: true,
    severeInteractions: [
      'Dipyridamole (potentiates effect - reduce adenosine dose)',
      'Theophylline / Caffeine (antagonizes effect - may need larger dose)'
    ],
    contraindications: [
      'Second or third-degree AV block (without pacemaker)',
      'Sick sinus syndrome (without pacemaker)',
      'Asthma (may cause bronchospasm)'
    ],
    specialNotes:
        'Must be given as a RAPID IV push (1-2 seconds) followed immediately by a rapid normal saline flush.',
    specialNotesTh:
        'ต้องฉีด IV Push เร็วมากๆ (1-2 วินาที) แล้วตามด้วย Normal Saline ทันที ห้ามใช้ในคนไข้หอบหืด',
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'SVT (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 6.0, // First dose 6mg
        doseUnit: DoseUnit.mg,
        frequency: 'Stat (can repeat 12mg if no response)',
        limits: DoseLimit(
          maxSingleDose: 12.0,
        ),
      ),
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'SVT (Pediatric)',
        dosingType: DosingType.weightBased,
        dosePerKg: 0.1, // 0.1 mg/kg
        doseUnit: DoseUnit.mg,
        frequency: 'Stat',
        limits: DoseLimit(
          maxSingleDose: 6.0, // Max first dose 6mg
        ),
      ),
    ],
  ),
  Drug(
    id: 'digoxin',
    genericName: 'Digoxin',
    brandNames: ['Lanoxin'],
    nameTh: 'ไดจอกซิน',
    category: DrugCategory.cardiovascular,
    requiresRenalAdjustment: true,
    isHighAlert: true,
    requiresTDM: true,
    severeInteractions: [
      'Amiodarone (increases digoxin levels by 50% - reduce digoxin dose)',
      'Furosemide / Diuretics (hypokalemia increases toxicity risk)'
    ],
    contraindications: ['Ventricular fibrillation'],
    specialNotes:
        'Narrow therapeutic index. Monitor potassium and kidney function closely.',
    specialNotesTh:
        'ยามีช่วงการรักษากว้างแคบ (Narrow therapeutic index) ต้องระวังโพแทสเซียมต่ำจะทำให้เกิดพิษง่าย',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Heart Failure / AFib (Adult Maintenance)',
        dosingType: DosingType.fixed,
        fixedDose: 0.25, // 0.125 - 0.25 mg
        doseUnit: DoseUnit.mg,
        frequency: 'q24h (OD)',
        limits: DoseLimit(
          maxDailyDose: 0.5,
        ),
        renalAdjustments: [
          RenalAdjustment(
              crclMin: 10,
              crclMax: 50,
              adjustmentFactor: 0.5,
              notes: 'Or administer q48h'),
          RenalAdjustment(
              crclMin: 0,
              crclMax: 9,
              adjustmentFactor: 0.25,
              notes: 'Administer q48h-q72h'),
        ],
      ),
    ],
  ),
  Drug(
    id: 'nicardipine',
    genericName: 'Nicardipine',
    brandNames: ['Cardene'],
    nameTh: 'นิคาร์ดิปีน',
    category: DrugCategory.cardiovascular,
    requiresHepaticCaution: true,
    isHighAlert: true,
    allergyClass: 'Calcium Channel Blocker (CCB)',
    severeInteractions: [
      'Beta-blockers (May cause severe hypotension/heart failure)',
      'CYP3A4 Inhibitors (Increase nicardipine levels)'
    ],
    contraindications: ['Advanced aortic stenosis'],
    specialNotes:
        'Frequent blood pressure monitoring required. Change infusion site q12h to prevent phlebitis.',
    specialNotesTh:
        'ต้องวัดความดันอย่างต่อเนื่อง (Continuous BP) และเปลี่ยนตำแหน่งแทงสายน้ำเกลือทุก 12 ชม. เพื่อลดหลอดเลือดอักเสบ',
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Hypertensive Emergency (Adult)',
        dosingType: DosingType.titrated,
        continuousRateMin: 5.0, // 5 mg/hr
        continuousRateMax: 15.0, // Max 15 mg/hr
        continuousRateUnit: 'mg/hr',
        doseUnit: DoseUnit.mg,
        frequency: 'continuous',
        standardDilutionMgPerMl: 0.1, // 25mg in 250mL = 0.1 mg/mL
        limits: DoseLimit(
          maxInfusionRate: 15.0,
          infusionRateUnit: 'mg/hr',
        ),
      ),
    ],
  ),
  Drug(
    id: 'spironolactone',
    genericName: 'Spironolactone',
    brandNames: ['Aldactone', 'Hyles'],
    nameTh: 'สไปโรโนแลคโตน',
    category: DrugCategory.cardiovascular,
    pregnancyCategory: 'C',
    requiresRenalAdjustment: true,
    contraindications: ['Anuria', 'Hyperkalemia', 'Addison disease'],
    severeInteractions: [
      'ACE inhibitors',
      'ARBs (Severe hyperkalemia)',
      'Potassium supplements'
    ],
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Heart Failure',
        dosingType: DosingType.fixed,
        fixedDose: 25, // 12.5-25mg
        doseUnit: DoseUnit.mg,
        frequency: 'OD',
        limits: DoseLimit(maxDailyDose: 50),
      ),
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Edema / Ascites',
        dosingType: DosingType.fixed,
        fixedDose: 100,
        doseUnit: DoseUnit.mg,
        frequency: 'OD to BID',
        limits: DoseLimit(maxDailyDose: 400),
      ),
    ],
  ),
  Drug(
    id: 'losartan',
    genericName: 'Losartan',
    brandNames: ['Cozaar'],
    nameTh: 'ลอซาร์แทน',
    category: DrugCategory.cardiovascular,
    pregnancyCategory: 'D',
    requiresHepaticCaution: true,
    severeInteractions: ['Spironolactone (Hyperkalemia)'],
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Hypertension',
        dosingType: DosingType.fixed,
        fixedDose: 50,
        doseUnit: DoseUnit.mg,
        frequency: 'OD to BID',
        limits: DoseLimit(maxDailyDose: 100),
      ),
    ],
  ),
  Drug(
    id: 'metoprolol',
    genericName: 'Metoprolol',
    brandNames: ['Betaloc'],
    nameTh: 'เมโทโพรลอล',
    category: DrugCategory.cardiovascular,
    pregnancyCategory: 'C',
    requiresHepaticCaution: true,
    contraindications: [
      'Severe bradycardia',
      'Heart block',
      'Decompensated heart failure'
    ],
    severeInteractions: ['Verapamil', 'Diltiazem (Severe bradycardia)'],
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Hypertension / Angina',
        dosingType: DosingType.fixed,
        fixedDose: 50,
        doseUnit: DoseUnit.mg,
        frequency: 'BID',
        limits: DoseLimit(maxDailyDose: 200),
      ),
    ],
  ),
  Drug(
    id: 'clopidogrel',
    genericName: 'Clopidogrel',
    brandNames: ['Plavix'],
    nameTh: 'โคลพิโดเกรล',
    category: DrugCategory
        .cardiovascular, // Should be antiplatelet, but cardiovascular is fine
    pregnancyCategory: 'B',
    severeInteractions: ['Omeprazole (Decreases clopidogrel efficacy)'],
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'ACS (Maintenance)',
        dosingType: DosingType.fixed,
        fixedDose: 75,
        doseUnit: DoseUnit.mg,
        frequency: 'OD',
      ),
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'ACS (Loading)',
        dosingType: DosingType.fixed,
        fixedDose: 300, // 300-600mg
        doseUnit: DoseUnit.mg,
        frequency: 'Once',
      ),
    ],
  ),
  Drug(
    id: 'rosuvastatin',
    genericName: 'Rosuvastatin',
    brandNames: ['Crestor'],
    nameTh: 'โรซูวาสแตติน',
    category: DrugCategory.cardiovascular,
    pregnancyCategory: 'X', // Statins are category X
    contraindications: ['Active liver disease'],
    requiresRenalAdjustment: true,
    severeInteractions: ['Gemfibrozil', 'Cyclosporine', 'Colchicine'],
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Hyperlipidemia',
        dosingType: DosingType.fixed,
        fixedDose: 20, // 5-40mg
        doseUnit: DoseUnit.mg,
        frequency: 'OD',
        limits: DoseLimit(maxDailyDose: 40),
      ),
    ],
  ),
];
