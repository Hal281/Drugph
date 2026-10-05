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
        frequency: Frequency.q12h,
        limits: DoseLimit(maxDailyDose: 3000.0),
        renalAdjustments: [
          RenalAdjustment(crclMin: 50, crclMax: 80, action: RenalAction.adjust, adjustmentFactor: 1.0, adjustedFrequency: Frequency.q12h),
          RenalAdjustment(crclMin: 30, crclMax: 50, action: RenalAction.adjust, adjustmentFactor: 0.5, adjustedFrequency: Frequency.q12h),
          RenalAdjustment(crclMin: 0, crclMax: 30, action: RenalAction.adjust, adjustmentFactor: 0.5, adjustedFrequency: Frequency.q12h, notes: '250-500 mg q12h'),
        ],
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
          RenalAdjustment(crclMin: 0, crclMax: 15, action: RenalAction.adjust, adjustmentFactor: 1.0, adjustedFrequency: Frequency.q24h, notes: '100-300 mg/day (OD)'),
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
        frequency: Frequency(minIntervalHours: 8, maxIntervalHours: 12, displayEn: 'Divided BID-TID', displayTh: 'แบ่งวันละ 2-3 ครั้ง'),
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
];

