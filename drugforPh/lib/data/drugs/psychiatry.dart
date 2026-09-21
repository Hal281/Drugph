import '../../core/models/models.dart';

final List<Drug> psychiatry = [
  Drug(
    id: 'haloperidol',
    genericName: 'Haloperidol',
    brandNames: ['Haldol', 'Haricon'],
    nameTh: 'ฮาโลเพอริดอล',
    category: DrugCategory.psychiatric,
    pregnancyCategory: 'C',
    requiresHepaticCaution: true,
    isHighAlert: true,
    severeInteractions: ['Amiodarone', 'Ondansetron', 'Metoclopramide'],
    specialNotes:
        'Monitor for QT prolongation and extrapyramidal symptoms (EPS).',
    specialNotesTh:
        'ระวังคลื่นไฟฟ้าหัวใจผิดปกติ (QT prolongation) และอาการเกร็ง/สั่น (EPS)',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Schizophrenia (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 5, // 0.5 - 5 mg BID/TID
        doseUnit: DoseUnit.mg,
        frequency: 'BID to TID',
        limits: DoseLimit(maxDailyDose: 30),
      ),
      DosingRegimen(
        route: DoseRoute.im,
        indication: 'Acute agitation',
        dosingType: DosingType.fixed,
        fixedDose: 5,
        doseUnit: DoseUnit.mg,
        frequency: 'q1-8h as needed',
        limits: DoseLimit(
            maxDailyDose: 20), // Max for IM is usually lower, but up to 20-30mg
      ),
    ],
  ),
  Drug(
    id: 'diazepam',
    genericName: 'Diazepam',
    brandNames: ['Valium', 'Di-a-pam'],
    nameTh: 'ไดอะซีแพม',
    category: DrugCategory.sedative,
    pregnancyCategory: 'D',
    requiresHepaticCaution: true,
    severeInteractions: ['Opioids', 'Alcohol', 'Phenobarbital'],
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Anxiety',
        dosingType: DosingType.fixed,
        fixedDose: 2,
        doseUnit: DoseUnit.mg,
        frequency: 'BID to QID',
        limits: DoseLimit(maxDailyDose: 40),
      ),
      DosingRegimen(
        route: DoseRoute.iv,
        indication: 'Status Epilepticus (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 10, // 5-10 mg
        doseUnit: DoseUnit.mg,
        frequency: 'q5-10min (Max 30mg)',
        maxInfusionRateMgPerMin: 5, // Do not exceed 5mg/min IV push
        limits: DoseLimit(maxDailyDose: 30),
      ),
    ],
  ),
  Drug(
    id: 'lorazepam',
    genericName: 'Lorazepam',
    brandNames: ['Ativan', 'Lora'],
    nameTh: 'ลอราซีแพม',
    category: DrugCategory.sedative,
    pregnancyCategory: 'D',
    severeInteractions: ['Opioids', 'Clozapine'],
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Anxiety/Insomnia',
        dosingType: DosingType.fixed,
        fixedDose: 1, // 1-2 mg
        doseUnit: DoseUnit.mg,
        frequency: 'BID to TID',
        limits: DoseLimit(maxDailyDose: 10),
      ),
      DosingRegimen(
        route: DoseRoute.iv,
        indication: 'Status Epilepticus (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 4,
        doseUnit: DoseUnit.mg,
        frequency: 'q10-15min',
        maxInfusionRateMgPerMin: 2,
        limits: DoseLimit(maxDailyDose: 8),
      ),
    ],
  ),
  Drug(
    id: 'olanzapine',
    genericName: 'Olanzapine',
    brandNames: ['Zyprexa'],
    nameTh: 'โอแลนซาปีน',
    category: DrugCategory.psychiatric,
    pregnancyCategory: 'C',
    severeInteractions: ['Lorazepam IM (avoid giving together)'],
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Schizophrenia / Bipolar',
        dosingType: DosingType.fixed,
        fixedDose: 10,
        doseUnit: DoseUnit.mg,
        frequency: 'OD',
        limits: DoseLimit(maxDailyDose: 20),
      ),
      DosingRegimen(
        route: DoseRoute.im,
        indication: 'Acute agitation',
        dosingType: DosingType.fixed,
        fixedDose: 10,
        doseUnit: DoseUnit.mg,
        frequency: 'q2-4h PRN',
        limits: DoseLimit(maxDailyDose: 30),
      ),
    ],
  ),
  Drug(
    id: 'risperidone',
    genericName: 'Risperidone',
    brandNames: ['Risperdal', 'Neurelan'],
    nameTh: 'ริสเพอริโดน',
    category: DrugCategory.psychiatric,
    pregnancyCategory: 'C',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Schizophrenia',
        dosingType: DosingType.fixed,
        fixedDose: 2, // starts 1-2 mg
        doseUnit: DoseUnit.mg,
        frequency: 'OD to BID',
        limits: DoseLimit(maxDailyDose: 16),
      ),
    ],
  ),
  Drug(
    id: 'quetiapine',
    genericName: 'Quetiapine',
    brandNames: ['Seroquel'],
    nameTh: 'ควิไทอะปีน',
    category: DrugCategory.psychiatric,
    pregnancyCategory: 'C',
    severeInteractions: ['Amiodarone', 'Fluconazole (QT prolongation)'],
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Schizophrenia / Bipolar',
        dosingType: DosingType.fixed,
        fixedDose: 300,
        doseUnit: DoseUnit.mg,
        frequency: 'OD or BID',
        limits: DoseLimit(maxDailyDose: 800),
      ),
    ],
  ),
  Drug(
    id: 'fluoxetine',
    genericName: 'Fluoxetine',
    brandNames: ['Prozac'],
    nameTh: 'ฟลูออกซีทีน',
    category: DrugCategory.psychiatric,
    pregnancyCategory: 'C',
    severeInteractions: ['MAOIs', 'Linezolid', 'Tramadol (Serotonin Syndrome)'],
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Depression (MDD)',
        dosingType: DosingType.fixed,
        fixedDose: 20,
        doseUnit: DoseUnit.mg,
        frequency: 'OD in morning',
        limits: DoseLimit(maxDailyDose: 80),
      ),
    ],
  ),
  Drug(
    id: 'sertraline',
    genericName: 'Sertraline',
    brandNames: ['Zoloft', 'Serlift'],
    nameTh: 'เซอร์ทราลีน',
    category: DrugCategory.psychiatric,
    pregnancyCategory: 'C',
    severeInteractions: ['MAOIs', 'Linezolid (Serotonin Syndrome)'],
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Depression / Panic disorder',
        dosingType: DosingType.fixed,
        fixedDose: 50,
        doseUnit: DoseUnit.mg,
        frequency: 'OD',
        limits: DoseLimit(maxDailyDose: 200),
      ),
    ],
  ),
  Drug(
    id: 'escitalopram',
    genericName: 'Escitalopram',
    brandNames: ['Lexapro'],
    nameTh: 'เอสซิตาโลแพรม',
    category: DrugCategory.psychiatric,
    pregnancyCategory: 'C',
    severeInteractions: ['MAOIs', 'Citalopram'],
    requiresHepaticCaution: true,
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Depression / Anxiety',
        dosingType: DosingType.fixed,
        fixedDose: 10,
        doseUnit: DoseUnit.mg,
        frequency: 'OD',
        limits: DoseLimit(maxDailyDose: 20),
      ),
    ],
  ),
  Drug(
    id: 'amitriptyline',
    genericName: 'Amitriptyline',
    brandNames: ['Tryptanol'],
    nameTh: 'อะมิทริปไทลีน',
    category: DrugCategory.psychiatric,
    pregnancyCategory: 'C',
    severeInteractions: ['MAOIs', 'Tramadol', 'Anticholinergics'],
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Depression / Neuropathic pain',
        dosingType: DosingType.fixed,
        fixedDose: 25,
        doseUnit: DoseUnit.mg,
        frequency: 'OD at bedtime',
        limits:
            DoseLimit(maxDailyDose: 150), // Can go higher in severe depression
      ),
    ],
  ),
  Drug(
    id: 'lithium',
    genericName: 'Lithium',
    brandNames: ['Lithobid', 'Eskalith'],
    nameTh: 'ลิเทียม',
    category: DrugCategory.psychiatric,
    pregnancyCategory: 'D',
    isHighAlert: true,
    requiresTDM: true,
    severeInteractions: ['NSAIDs', 'ACE inhibitors', 'Diuretics (thiazides)'],
    specialNotes:
        'Requires regular therapeutic drug monitoring. Normal level: 0.6-1.2 mEq/L',
    specialNotesTh: 'ต้องเจาะระดับยาในเลือดเสมอ ระดับปกติ: 0.6-1.2 mEq/L',
    requiresRenalAdjustment: true,
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Bipolar disorder',
        dosingType: DosingType.fixed,
        fixedDose: 300,
        doseUnit:
            DoseUnit.mg, // Typically prescribed in mg of lithium carbonate
        frequency: 'BID to TID',
        limits: DoseLimit(maxDailyDose: 2400),
      ),
    ],
  ),
];
