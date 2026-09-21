import '../../core/models/models.dart';

final List<Drug> respiratory = [
  Drug(
    id: 'salbutamol',
    genericName: 'Salbutamol (Albuterol)',
    brandNames: ['Ventolin', 'Asmasal'],
    nameTh: 'ซัลบูทามอล',
    category: DrugCategory.respiratory,
    allergyClass: 'Beta-2 Agonist',
    severeInteractions: [
      'Non-selective Beta-blockers (e.g. Propranolol) - Antagonizes effect, may trigger bronchospasm',
      'MAOIs / TCAs - Potentiates cardiovascular effects'
    ],
    specialNotes: 'Can cause tachycardia, tremor, and hypokalemia (at high doses).',
    specialNotesTh: 'อาจทำให้ใจสั่น มือสั่น และโพแทสเซียมต่ำ (หากใช้โดสสูง)',
    regimens: [
      DosingRegimen(
        route: DoseRoute.inhalation,
        indication: 'Asthma / COPD Exacerbation (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 2.5, // 2.5 - 5 mg via nebulizer
        doseUnit: DoseUnit.mg,
        frequency: 'q20min x 3 doses, then q1-4h prn',
        limits: DoseLimit(maxSingleDose: 5.0),
      ),
      DosingRegimen(
        route: DoseRoute.inhalation,
        indication: 'Asthma / Wheezing (Pediatric < 20kg)',
        dosingType: DosingType.weightBased, // Commonly weight or age based, often just 2.5mg fixed, but let's provide a standard
        dosePerKg: 0.15, // 0.15 mg/kg (min 1.25mg, max 2.5mg)
        doseUnit: DoseUnit.mg,
        frequency: 'q20min x 3 doses, then q1-4h prn',
        limits: DoseLimit(
          minSingleDose: 1.25,
          maxSingleDose: 2.5,
        ),
      ),
    ],
  ),
  Drug(
    id: 'chlorpheniramine',
    genericName: 'Chlorpheniramine (CPM)',
    brandNames: ['Piriton'],
    nameTh: 'คลอร์เฟนิรามีน',
    category: DrugCategory.antihistamine,
    allergyClass: 'Antihistamine (1st Gen)',
    severeInteractions: [
      'CNS Depressants (Alcohol, Sedatives) - Increased sedation',
      'MAOIs - Prolongs anticholinergic effects'
    ],
    contraindications: [
      'Neonates or premature infants',
      'Narrow-angle glaucoma',
      'Symptomatic prostate hypertrophy'
    ],
    specialNotes: 'First-generation antihistamine; causes significant drowsiness and anticholinergic effects.',
    specialNotesTh: 'ยาแก้แพ้รุ่นแรก ทำให้ง่วงซึมมาก และระวังในผู้ป่วยต่อมลูกหมากโตหรือต้อหิน',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Allergic Rhinitis (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 4.0,
        doseUnit: DoseUnit.mg,
        frequency: 'q4h-q6h prn',
        limits: DoseLimit(
          maxDailyDose: 24.0,
        ),
      ),
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Allergic Rhinitis (Pediatric 6-12 yrs)',
        dosingType: DosingType.fixed,
        fixedDose: 2.0,
        doseUnit: DoseUnit.mg,
        frequency: 'q4h-q6h prn',
        limits: DoseLimit(
          maxDailyDose: 12.0,
        ),
      ),
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Anaphylaxis / Severe Allergy (Adult IV)',
        dosingType: DosingType.fixed,
        fixedDose: 10.0,
        doseUnit: DoseUnit.mg,
        frequency: 'Stat',
        limits: DoseLimit(maxSingleDose: 20.0, maxDailyDose: 40.0),
      ),
    ],
  ),
  Drug(
    id: 'cetirizine',
    genericName: 'Cetirizine',
    brandNames: ['Zyrtec'],
    nameTh: 'เซทิริซีน',
    category: DrugCategory.antihistamine,
    requiresRenalAdjustment: true,
    allergyClass: 'Antihistamine (2nd Gen)',
    specialNotes: 'Less sedating than CPM, but can still cause drowsiness in some patients.',
    specialNotesTh: 'ง่วงน้อยกว่า CPM แต่อาจทำให้ง่วงได้ในผู้ป่วยบางราย',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Allergic Rhinitis / Urticaria (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 10.0,
        doseUnit: DoseUnit.mg,
        frequency: 'q24h (OD)',
        limits: DoseLimit(maxDailyDose: 10.0),
        renalAdjustments: [
          RenalAdjustment(crclMin: 11, crclMax: 31, adjustmentFactor: 0.5, notes: 'Max 5 mg/day'),
          RenalAdjustment(crclMin: 0, crclMax: 10, adjustmentFactor: 0.5, notes: 'Max 5 mg/day (Avoid in ESRD if possible)'),
        ],
      ),
    ],
  ),
  Drug(
    id: 'ipratropium',
    genericName: 'Ipratropium Bromide',
    brandNames: ['Atrovent'],
    nameTh: 'อิพราโทรเปียม',
    category: DrugCategory.respiratory,
    allergyClass: 'Anticholinergic',
    severeInteractions: ['Other Anticholinergics (Additive effects)'],
    contraindications: ['Soy/peanut allergy (nebulizer solution contains soy lecithin)'],
    specialNotes: 'Often combined with Salbutamol for acute asthma/COPD.',
    specialNotesTh: 'มักใช้ร่วมกับ Salbutamol ในการพ่นยารักษาหอบหืดและ COPD เฉียบพลัน',
    regimens: [
      DosingRegimen(
        route: DoseRoute.inhalation,
        indication: 'COPD / Asthma Exacerbation (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 0.5, // 500 mcg = 0.5 mg
        doseUnit: DoseUnit.mg,
        frequency: 'q20min x 3 doses, then q4-6h prn',
      ),
      DosingRegimen(
        route: DoseRoute.inhalation,
        indication: 'Wheezing (Pediatric)',
        dosingType: DosingType.fixed,
        fixedDose: 0.25,
        doseUnit: DoseUnit.mg,
        frequency: 'q20min x 3 doses, then q4-6h prn',
      ),
    ],
  ),
  Drug(
    id: 'budesonide_neb',
    genericName: 'Budesonide (Nebulizer)',
    brandNames: ['Pulmicort'],
    nameTh: 'บูเดโซไนด์ (พ่น)',
    category: DrugCategory.respiratory,
    allergyClass: 'Corticosteroid',
    specialNotes: 'Inhaled corticosteroid for maintenance. Rinse mouth after use to prevent oral candidiasis.',
    specialNotesTh: 'คอร์ติโคสเตียรอยด์แบบพ่น สำหรับควบคุมอาการ ต้องบ้วนปากหลังใช้ทุกครั้งป้องกันเชื้อราในปาก',
    regimens: [
      DosingRegimen(
        route: DoseRoute.inhalation,
        indication: 'Asthma Maintenance (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 0.5, // 0.5-1 mg BID
        doseUnit: DoseUnit.mg,
        frequency: 'q12h (BID)',
        limits: DoseLimit(maxDailyDose: 2.0),
      ),
      DosingRegimen(
        route: DoseRoute.inhalation,
        indication: 'Croup (Pediatric)',
        dosingType: DosingType.fixed,
        fixedDose: 2.0, // 2 mg nebulized single dose
        doseUnit: DoseUnit.mg,
        frequency: 'Single dose (May repeat once)',
      ),
    ],
  ),
  Drug(
    id: 'prednisolone',
    genericName: 'Prednisolone',
    brandNames: ['Precortalon', 'Solone'],
    nameTh: 'เพรดนิโซโลน',
    category: DrugCategory.antiInflammatory,
    allergyClass: 'Corticosteroid',
    severeInteractions: [
      'NSAIDs (Increased GI bleeding)',
      'Live Vaccines (Avoid)',
      'Warfarin (Increases bleeding risk)'
    ],
    specialNotes: 'Short course (3-5 days) for asthma exacerbation. Monitor blood glucose. Taper if >7 days use.',
    specialNotesTh: 'ใช้ระยะสั้น 3-5 วันสำหรับหอบหืดกำเริบ ระวังน้ำตาลสูง ถ้าใช้เกิน 7 วันต้องค่อยๆ ลดโดส',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Asthma Exacerbation (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 40.0, // 40-60 mg
        doseUnit: DoseUnit.mg,
        frequency: 'q24h for 5-7 days',
        limits: DoseLimit(maxDailyDose: 60.0),
      ),
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Asthma Exacerbation (Pediatric)',
        dosingType: DosingType.weightBased,
        dosePerKg: 1.0, // 1-2 mg/kg/day
        doseUnit: DoseUnit.mg,
        frequency: 'q24h for 3-5 days',
        limits: DoseLimit(maxDailyDose: 60.0),
      ),
    ],
  ),
  Drug(
    id: 'loratadine',
    genericName: 'Loratadine',
    brandNames: ['Clarityne'],
    nameTh: 'ลอราทาดีน',
    category: DrugCategory.antihistamine,
    allergyClass: 'Antihistamine (2nd Gen)',
    specialNotes: 'Non-sedating antihistamine. No significant food interactions.',
    specialNotesTh: 'ยาแก้แพ้รุ่น 2 ไม่ค่อยทำให้ง่วง',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Allergic Rhinitis / Urticaria (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 10.0,
        doseUnit: DoseUnit.mg,
        frequency: 'q24h (OD)',
        limits: DoseLimit(maxDailyDose: 10.0),
      ),
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Allergic Rhinitis (Pediatric 2-12 yr)',
        dosingType: DosingType.fixed,
        fixedDose: 5.0,
        doseUnit: DoseUnit.mg,
        frequency: 'q24h (OD)',
      ),
    ],
  ),
  Drug(
    id: 'fexofenadine',
    genericName: 'Fexofenadine',
    brandNames: ['Telfast', 'Allegra'],
    nameTh: 'เฟกโซเฟนาดีน',
    category: DrugCategory.antihistamine,
    allergyClass: 'Antihistamine (2nd Gen)',
    specialNotes: 'Non-sedating. Avoid grapefruit juice (decreases absorption).',
    specialNotesTh: 'ไม่ทำให้ง่วง ห้ามกินกับน้ำส้มโอ/เกรปฟรุ๊ต',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Allergic Rhinitis / Urticaria (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 180.0,
        doseUnit: DoseUnit.mg,
        frequency: 'q24h (OD)',
      ),
    ],
  ),
  Drug(
    id: 'montelukast',
    genericName: 'Montelukast',
    brandNames: ['Singulair', 'Montair'],
    nameTh: 'มอนเทลูคาสต์',
    category: DrugCategory.respiratory,
    allergyClass: 'Leukotriene Receptor Antagonist',
    severeInteractions: [],
    specialNotes: 'FDA boxed warning: may cause neuropsychiatric events (depression, suicidal thoughts). Monitor mood.',
    specialNotesTh: 'คำเตือน FDA: อาจทำให้มีอาการทางจิตประสาท (ซึมเศร้า ฆ่าตัวตาย) ต้องสังเกตอาการ',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Asthma Maintenance (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 10.0,
        doseUnit: DoseUnit.mg,
        frequency: 'q24h (OD) at bedtime',
      ),
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Asthma Maintenance (Pediatric 6-14 yr)',
        dosingType: DosingType.fixed,
        fixedDose: 5.0,
        doseUnit: DoseUnit.mg,
        frequency: 'q24h (OD) at bedtime',
      ),
    ],
  ),
  Drug(
    id: 'n_acetylcysteine',
    genericName: 'N-Acetylcysteine (NAC)',
    brandNames: ['Fluimucil', 'Mucomyst'],
    nameTh: 'เอ็น-อะเซทิลซิสเทอีน',
    category: DrugCategory.respiratory,
    allergyClass: 'Mucolytic',
    specialNotes: 'Also used as antidote for paracetamol overdose (IV protocol: 150mg/kg over 1hr, then 50mg/kg over 4hr, then 100mg/kg over 16hr).',
    specialNotesTh: 'นอกจากเป็นยาละลายเสมหะ ยังเป็นยาแก้พิษพาราเซตามอล (ดูโปรโตคอลเฉพาะ)',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Mucolytic (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 200.0, // 200 mg TID or 600 mg OD
        doseUnit: DoseUnit.mg,
        frequency: 'q8h (TID)',
        limits: DoseLimit(maxDailyDose: 600.0),
      ),
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Paracetamol Overdose Antidote (Adult)',
        dosingType: DosingType.weightBased,
        dosePerKg: 150.0, // 150 mg/kg first bag
        doseUnit: DoseUnit.mg,
        frequency: '150mg/kg over 1hr → 50mg/kg over 4hr → 100mg/kg over 16hr',
      ),
    ],
  ),
];

