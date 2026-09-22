import '../../core/models/models.dart';

final List<Drug> neurology = [
  Drug(
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
    specialNotes: 'High risk of dependence. Rapid IV push can cause respiratory arrest (push max 5mg/min).',
    specialNotesTh: 'เสี่ยงติดยา การฉีด IV เร็วเกินไปอาจทำให้หยุดหายใจได้ (ดันยาไม่เกิน 5mg/นาที)',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Anxiety / Muscle Spasm (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 5.0, // 2-10 mg
        doseUnit: DoseUnit.mg,
        frequency: 'q6h-q8h (BID-QID)',
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
        frequency: 'Stat (Repeat in 10-15 mins prn)',
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
        frequency: 'Stat',
        limits: DoseLimit(
          maxSingleDose: 10.0,
        ),
      ),
    ],
  ),
  Drug(
    id: 'phenytoin',
    genericName: 'Phenytoin',
    brandNames: ['Dilantin'],
    nameTh: 'ฟีนิทอยน์',
    category: DrugCategory.neurological,
    requiresHepaticCaution: true,
    isHighAlert: true,
    requiresTDM: true,
    allergyClass: 'Hydantoin',
    severeInteractions: [
      'Valproic Acid (Displaces phenytoin from proteins - requires free phenytoin monitoring)',
      'Amiodarone / Fluconazole (Increases phenytoin levels)'
    ],
    contraindications: ['Sinus bradycardia', 'Sinoatrial block'],
    specialNotes: 'Non-linear pharmacokinetics. Target TDM: 10-20 mcg/mL. Max IV rate 50mg/min to prevent arrhythmias.',
    specialNotesTh: 'ต้องเจาะเลือดดูระดับยา (Target 10-20) การให้ IV ห้ามเกิน 50mg/min ป้องกันหัวใจหยุดเต้น',
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Status Epilepticus Loading Dose (Adult)',
        dosingType: DosingType.weightBased,
        dosePerKg: 15.0, // 15-20 mg/kg
        doseUnit: DoseUnit.mg,
        frequency: 'Stat',
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
        frequency: 'q24h (OD)',
        limits: DoseLimit(
          maxDailyDose: 600.0,
        ),
      ),
    ],
  ),
  Drug(
    id: 'levetiracetam',
    genericName: 'Levetiracetam',
    brandNames: ['Keppra'],
    nameTh: 'ลีวีไทราซีแทม',
    category: DrugCategory.neurological,
    requiresRenalAdjustment: true,
    allergyClass: 'Pyrrolidine derivative',
    severeInteractions: [],
    specialNotes: 'Can cause behavioral abnormalities (aggression, agitation). Very safe for liver.',
    specialNotesTh: 'อาจทำให้มีอาการก้าวร้าวหรืออารมณ์แปรปรวนได้ ปลอดภัยต่อตับแต่ต้องปรับโดสตามไต',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Seizure Prophylaxis (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 500.0,
        doseUnit: DoseUnit.mg,
        frequency: 'q12h (BID)',
        limits: DoseLimit(maxDailyDose: 3000.0),
        renalAdjustments: [
          RenalAdjustment(crclMin: 50, crclMax: 79, adjustmentFactor: 1.0, adjustedFrequency: '500-1000 mg q12h'),
          RenalAdjustment(crclMin: 30, crclMax: 49, adjustmentFactor: 0.5, adjustedFrequency: '250-750 mg q12h'),
          RenalAdjustment(crclMin: 0, crclMax: 29, adjustmentFactor: 0.5, adjustedFrequency: '250-500 mg q12h'),
        ],
      ),
    ],
  ),
  Drug(
    id: 'haloperidol',
    genericName: 'Haloperidol',
    brandNames: ['Haldol'],
    nameTh: 'ฮาโลเพอริดอล',
    category: DrugCategory.neurological, // Antipsychotic
    requiresHepaticCaution: true,
    allergyClass: 'Butyrophenone',
    severeInteractions: [
      'Other QT prolonging drugs (e.g. Amiodarone, Ondansetron)',
      'Levodopa (Antagonistic effect)'
    ],
    contraindications: ['Parkinson\'s disease', 'Severe CNS depression', 'Coma'],
    specialNotes: 'High risk of Extrapyramidal Symptoms (EPS) and QT prolongation. Monitor ECG.',
    specialNotesTh: 'เสี่ยงต่อกล้ามเนื้อเกร็ง (EPS) และคลื่นไฟฟ้าหัวใจผิดปกติ (QT prolongation) แนะนำตรวจคลื่นหัวใจ (ECG)',
    regimens: [
      DosingRegimen(
        route: DoseRoute.im,
        indication: 'Acute Agitation / Delirium (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 2.5, // 2.5 - 5 mg
        doseUnit: DoseUnit.mg,
        frequency: 'Stat (May repeat in 60 mins)',
        limits: DoseLimit(
          maxDailyDose: 20.0, // Depends on condition, but 20-30mg is common max for safety
        ),
      ),
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Psychosis (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 2.0, // 0.5 - 5 mg
        doseUnit: DoseUnit.mg,
        frequency: 'q8h-q12h',
        limits: DoseLimit(maxDailyDose: 30.0),
      ),
    ],
  ),
  Drug(
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
        frequency: 'q8h (TID)',
        limits: DoseLimit(maxDailyDose: 3600.0),
        renalAdjustments: [
          RenalAdjustment(crclMin: 30, crclMax: 59, adjustmentFactor: 1.0, adjustedFrequency: '400-1400 mg/day divided BID'),
          RenalAdjustment(crclMin: 15, crclMax: 29, adjustmentFactor: 1.0, adjustedFrequency: '200-700 mg/day (OD)'),
          RenalAdjustment(crclMin: 0, crclMax: 14, adjustmentFactor: 1.0, adjustedFrequency: '100-300 mg/day (OD)'),
        ],
      ),
    ],
  ),
  Drug(
    id: 'valproic_acid',
    genericName: 'Valproic Acid / Sodium Valproate',
    brandNames: ['Depakine'],
    nameTh: 'วาลโปรอิก แอซิด (เดพาคีน)',
    category: DrugCategory.neurological,
    requiresHepaticCaution: true,
    isHighAlert: true,
    requiresTDM: true,
    pregnancyCategory: 'D/X',
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
        doseUnit: DoseUnit.mg,
        frequency: 'divided BID to TID',
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
        frequency: 'Stat',
        maxInfusionRateMgPerMin: 150.0, // usually up to 3-6 mg/kg/min
        limits: DoseLimit(maxSingleDose: 3000.0),
      ),
    ],
  ),
];

