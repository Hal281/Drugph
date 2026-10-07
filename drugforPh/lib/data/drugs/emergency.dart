import '../../core/models/models.dart';

/// Emergency & Resuscitation drugs commonly used in ER and ICU.
final List<Drug> emergency = [
  const Drug(
    id: 'epinephrine',
    genericName: 'Epinephrine (Adrenaline)',
    brandNames: ['Adrenaline'],
    nameTh: 'อีพิเนฟริน (อะดรีนาลิน)',
    category: DrugCategory.vasopressor,
    isHighAlert: true,
    allergyClass: 'Catecholamine',
    severeInteractions: [
      'Non-selective Beta-blockers (Paradoxical hypertension)',
      'MAOIs (Severe hypertensive crisis)',
      'Halothane (Cardiac arrhythmias)'
    ],
    specialNotes: 'Anaphylaxis: IM into anterolateral thigh. Cardiac arrest: IV/IO. Dilute 1:10,000 for IV push.',
    specialNotesTh: 'แพ้ยารุนแรง: ฉีด IM ที่ต้นขาด้านนอก, หัวใจหยุดเต้น: IV/IO ใช้ความเข้มข้น 1:10,000 ฉีด IV Push',
    regimens: [
      DosingRegimen(
        route: DoseRoute.im,
        indication: 'Anaphylaxis (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 0.3, // 0.3-0.5 mg IM (1:1,000)
        doseUnit: DoseUnit.mg,
        frequency: Frequency(isOnce: true, isPrn: true, displayEn: 'Stat (repeat 5-15min PRN)', displayTh: 'ทันที (ซ้ำได้ทุก 5-15 นาที)'),
        limits: DoseLimit(maxSingleDose: 0.5),
      ),
      DosingRegimen(
        route: DoseRoute.im,
        indication: 'Anaphylaxis (Pediatric)',
        dosingType: DosingType.weightBased,
        dosePerKg: 0.01, // 0.01 mg/kg IM
        doseUnit: DoseUnit.mg,
        frequency: Frequency(isOnce: true, isPrn: true, displayEn: 'Stat (repeat 5-15min PRN)', displayTh: 'ทันที (ซ้ำได้ทุก 5-15 นาที)'),
        limits: DoseLimit(maxSingleDose: 0.3),
      ),
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Cardiac Arrest / ACLS (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 1.0, // 1 mg IV (1:10,000)
        doseUnit: DoseUnit.mg,
        frequency: Frequency(
          displayEn: 'q3-5min',
          displayTh: 'ทุก 3-5 นาที ระหว่างกู้ชีพ',
          customReason: 'ACLS cardiac arrest protocol every 3-5 minutes',
        ),
      ),
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Cardiac Arrest / PALS (Pediatric)',
        dosingType: DosingType.weightBased,
        dosePerKg: 0.01,
        doseUnit: DoseUnit.mg,
        frequency: Frequency(
          displayEn: 'q3-5min',
          displayTh: 'ทุก 3-5 นาที ระหว่างกู้ชีพ',
          customReason: 'PALS cardiac arrest protocol every 3-5 minutes',
        ),
        limits: DoseLimit(maxSingleDose: 1.0),
      ),
    ],
  ),
  const Drug(
    id: 'atropine',
    genericName: 'Atropine',
    brandNames: ['Atropine Sulfate'],
    nameTh: 'อะโทรปีน',
    category: DrugCategory.cardiovascular,
    isHighAlert: true,
    allergyClass: 'Anticholinergic',
    severeInteractions: ['Other Anticholinergics (Additive effects)'],
    contraindications: ['Narrow-angle glaucoma (relative)'],
    specialNotes: 'For symptomatic bradycardia. May be ineffective in transplanted hearts (denervated).',
    specialNotesTh: 'ใช้รักษาหัวใจเต้นช้าที่มีอาการ ไม่ค่อยได้ผลในคนไข้ที่เปลี่ยนหัวใจ',
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Symptomatic Bradycardia (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 0.5,
        doseUnit: DoseUnit.mg,
        frequency: Frequency(isPrn: true, displayEn: 'q3-5min PRN', displayTh: 'ทุก 3-5 นาที เมื่อจำเป็น'),
        limits: DoseLimit(maxSingleDose: 1.0),
      ),
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Bradycardia (Pediatric)',
        dosingType: DosingType.weightBased,
        dosePerKg: 0.02,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.stat,
        limits: DoseLimit(minSingleDose: 0.1, maxSingleDose: 0.5),
      ),
    ],
  ),
  const Drug(
    id: 'magnesium_sulfate',
    genericName: 'Magnesium Sulfate',
    brandNames: ['MgSO4'],
    nameTh: 'แมกนีเซียมซัลเฟต',
    category: DrugCategory.cardiovascular,
    isHighAlert: true,
    requiresRenalAdjustment: true,
    severeInteractions: [
      'Calcium Channel Blockers (Potentiates hypotension)',
      'Neuromuscular blockers (Prolongs paralysis)'
    ],
    contraindications: ['Heart block', 'Myocardial damage'],
    specialNotes: 'Monitor deep tendon reflexes, respiratory rate, and urine output. Calcium gluconate is the antidote.',
    specialNotesTh: 'ต้องวัดรีเฟล็กซ์เข่า อัตราการหายใจ และปัสสาวะอย่างต่อเนื่อง ถ้าเกิดพิษ ให้ Calcium gluconate เป็นยาแก้พิษ',
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Eclampsia / Pre-eclampsia (Loading)',
        dosingType: DosingType.fixed,
        fixedDose: 4000.0, // 4g loading dose
        doseUnit: DoseUnit.mg,
        frequency: Frequency.once,
        notes: 'Loading dose over 15-20 min, then 1-2g/hr maintenance',
        infusionTimeMinutes: 20,
      ),
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Eclampsia / Pre-eclampsia (Maintenance)',
        dosingType: DosingType.titrated,
        doseUnit: DoseUnit.g,
        frequency: Frequency.continuous,
        continuousRateMin: 1.0,
        continuousRateMax: 2.0,
        continuousRateUnit: 'g/hr',
        standardDilutionMgPerMl: 40.0,
      ),
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Torsades de Pointes / Hypomagnesemia (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 2000.0, // 2g
        doseUnit: DoseUnit.mg,
        frequency: Frequency.stat,
        notes: 'Slow IV push over 2-5 min',
      ),
    ],
  ),
  const Drug(
    id: 'dexamethasone',
    genericName: 'Dexamethasone',
    brandNames: ['Dexon', 'Oradexon'],
    nameTh: 'เดกซาเมทาโซน',
    category: DrugCategory.antiInflammatory,
    tags: ['obstetric'],
    allergyClass: 'Corticosteroid',
    severeInteractions: [
      'Warfarin (Increases bleeding risk)',
      'NSAIDs (Increased GI bleeding risk)',
      'Live Vaccines (Avoid)'
    ],
    specialNotes: 'Monitor blood glucose (hyperglycemia). Taper slowly if used >7 days to avoid adrenal crisis.',
    specialNotesTh: 'ระวังน้ำตาลในเลือดสูง หากใช้ยานานเกิน 7 วัน ต้องค่อยๆ ลดโดสยา (Taper) ป้องกันภาวะต่อมหมวกไตบกพร่องเฉียบพลัน',
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Cerebral Edema (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 10.0, // 10 mg IV loading
        doseUnit: DoseUnit.mg,
        frequency: Frequency.stat,
      ),
      DosingRegimen(
        route: DoseRoute.im,
        indication: 'Fetal lung maturity',
        dosingType: DosingType.fixed,
        fixedDose: 6.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency(
          intervalHours: 12,
          displayEn: 'q12h (4 doses)',
          displayTh: 'ทุก 12 ชม. (4 ครั้ง)',
        ),
        limits: DoseLimit(maxDailyDose: 12.0),
      ),
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Croup (Pediatric)',
        dosingType: DosingType.weightBased,
        dosePerKg: 0.6,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.once,
        limits: DoseLimit(maxSingleDose: 10.0),
      ),
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Anti-inflammatory (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 4.0, // 4-8 mg
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q24h,
        limits: DoseLimit(maxDailyDose: 20.0),
      ),
    ],
  ),
  const Drug(
    id: 'hydrocortisone',
    genericName: 'Hydrocortisone',
    brandNames: ['Solu-Cortef'],
    nameTh: 'ไฮโดรคอร์ติโซน',
    category: DrugCategory.antiInflammatory,
    allergyClass: 'Corticosteroid',
    severeInteractions: [
      'NSAIDs (Increased GI bleeding)',
      'Live Vaccines (Avoid)'
    ],
    specialNotes: 'Stress dose for septic shock: 200 mg/day. Monitor electrolytes and blood glucose.',
    specialNotesTh: 'โดสสำหรับช็อคจากติดเชื้อ: 200 mg/วัน ต้องวัดน้ำตาลและเกลือแร่',
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Septic Shock (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 50.0, // 50 mg q8h = 150mg or 50 q6h = 200mg
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q8h,
        limits: DoseLimit(maxDailyDose: 200.0),
      ),
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Adrenal Crisis (Pediatric)',
        dosingType: DosingType.weightBased,
        dosePerKg: 2.0, // 2 mg/kg bolus
        doseUnit: DoseUnit.mg,
        frequency: Frequency.stat,
        limits: DoseLimit(maxSingleDose: 100.0),
      ),
    ],
  ),
  const Drug(
    id: 'naloxone',
    genericName: 'Naloxone',
    brandNames: ['Narcan'],
    nameTh: 'นาลอกโซน',
    category: DrugCategory.analgesic, // antidote
    isHighAlert: true,
    specialNotes: 'Opioid reversal agent. Short duration (30-90 min); re-sedation may occur. Titrate to respiratory effort.',
    specialNotesTh: 'ยาแก้พิษฝิ่น (Opioid) ออกฤทธิ์สั้น (30-90 นาที) คนไข้อาจซึมกลับมาอีก ต้อง Titrate ตามอัตราการหายใจ',
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Opioid Overdose / Reversal (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 0.4, // 0.04-0.4 mg titrate
        doseUnit: DoseUnit.mg,
        frequency: Frequency(isPrn: true, displayEn: 'q2-3min PRN', displayTh: 'ทุก 2-3 นาที เมื่อจำเป็น'),
        limits: DoseLimit(maxSingleDose: 2.0),
      ),
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Opioid Reversal (Pediatric)',
        dosingType: DosingType.weightBased,
        dosePerKg: 0.01,
        doseUnit: DoseUnit.mg,
        frequency: Frequency(isPrn: true, displayEn: 'q2-3min PRN', displayTh: 'ทุก 2-3 นาที เมื่อจำเป็น'),
        limits: DoseLimit(maxSingleDose: 2.0),
      ),
    ],
  ),
  const Drug(
    id: 'dobutamine',
    genericName: 'Dobutamine',
    brandNames: ['Dobutrex'],
    nameTh: 'โดบูทามีน',
    category: DrugCategory.vasopressor,
    isHighAlert: true,
    severeInteractions: ['Beta-blockers (Antagonistic effect)'],
    specialNotes: 'Inotrope for acute decompensated heart failure. Increases cardiac output. May cause tachycardia.',
    specialNotesTh: 'ยาเพิ่มแรงบีบตัวของหัวใจ สำหรับหัวใจล้มเหลวเฉียบพลัน อาจทำให้หัวใจเต้นเร็ว',
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Cardiogenic Shock / Acute HF',
        dosingType: DosingType.titrated,
        continuousRateMin: 2.0,
        continuousRateMax: 20.0,
        continuousRateUnit: 'mcg/kg/min',
        doseUnit: DoseUnit.mcg,
        frequency: Frequency.continuous,
        standardDilutionMgPerMl: 1.0, // 250mg in 250mL
        limits: DoseLimit(maxInfusionRate: 20.0, infusionRateUnit: 'mcg/kg/min'),
      ),
    ],
  ),
];
