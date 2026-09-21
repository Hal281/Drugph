import '../../core/models/models.dart';

final List<Drug> analgesics = [
  Drug(
    id: 'paracetamol',
    genericName: 'Paracetamol (Acetaminophen)',
    brandNames: ['Tylenol', 'Sara', 'Calpol'],
    nameTh: 'พาราเซตามอล',
    category: DrugCategory.analgesic,
    requiresHepaticCaution: true,
    specialNotes: 'Max daily dose 4g in adults to prevent hepatotoxicity. Reduce to 2g/day in severe hepatic impairment or chronic alcoholism.',
    specialNotesTh: 'ขนาดยาสูงสุด 4 กรัม/วัน ในผู้ใหญ่เพื่อป้องกันตับอักเสบ ลดเหลือ 2 กรัม/วัน ในผู้ป่วยโรคตับรุนแรงหรือติดสุราเรื้อรัง',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Fever/Pain (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 500.0, // 500 - 1000 mg
        doseUnit: DoseUnit.mg,
        frequency: 'q4h-q6h prn',
        limits: DoseLimit(
          maxSingleDose: 1000.0,
          maxDailyDose: 4000.0, // Hard limit 4g
        ),
      ),
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Fever/Pain (Pediatric)',
        dosingType: DosingType.weightBased,
        dosePerKg: 10.0, // 10-15 mg/kg/dose
        doseUnit: DoseUnit.mg,
        frequency: 'q4h-q6h prn',
        limits: DoseLimit(
          maxSingleDose: 750.0,
          softMaxSingleDose: 500.0,
          maxDailyDose: 3750.0, // Max 75 mg/kg/day or 3750 mg
          maxDosePerKgPerDay: 75.0,
        ),
      ),
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Fever/Pain (Adult IV)',
        dosingType: DosingType.fixed,
        fixedDose: 1000.0,
        doseUnit: DoseUnit.mg,
        frequency: 'q6h prn',
        infusionTimeMinutes: 15.0,
        limits: DoseLimit(
          maxSingleDose: 1000.0,
          maxDailyDose: 4000.0,
        ),
      ),
    ],
  ),
  Drug(
    id: 'ibuprofen',
    genericName: 'Ibuprofen',
    brandNames: ['Brufen', 'Nurofen'],
    nameTh: 'ไอบูโพรเฟน',
    category: DrugCategory.nsaid,
    requiresRenalAdjustment: true,
    allergyClass: 'NSAID / Aspirin',
    severeInteractions: ['Warfarin (bleeding risk)', 'ACE inhibitors (renal failure)', 'Lithium'],
    contraindications: ['Active GI bleeding', 'Severe renal impairment', 'Dengue fever (suspected)'],
    specialNotes: 'Avoid in suspected Dengue fever. Take with food to reduce GI irritation.',
    specialNotesTh: 'หลีกเลี่ยงในผู้ป่วยที่สงสัยไข้เลือดออก ทานพร้อมอาหารเพื่อลดการระคายเคืองกระเพาะ',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Mild to Moderate Pain (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 400.0,
        doseUnit: DoseUnit.mg,
        frequency: 'q6h-q8h prn',
        limits: DoseLimit(
          maxSingleDose: 800.0,
          maxDailyDose: 3200.0,
        ),
      ),
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Fever/Pain (Pediatric >6 months)',
        dosingType: DosingType.weightBased,
        dosePerKg: 10.0, // 5-10 mg/kg/dose
        doseUnit: DoseUnit.mg,
        frequency: 'q6h-q8h prn',
        limits: DoseLimit(
          maxSingleDose: 400.0,
          maxDailyDose: 2400.0,
          maxDosePerKgPerDay: 40.0,
        ),
      ),
    ],
  ),
  Drug(
    id: 'tramadol',
    genericName: 'Tramadol',
    brandNames: ['Tramal', 'Anarex'],
    nameTh: 'ทรามาดอล',
    category: DrugCategory.opioid,
    requiresRenalAdjustment: true,
    requiresHepaticCaution: true,
    isHighAlert: true,
    specialNotes: 'Lowers seizure threshold. Risk of serotonin syndrome when combined with SSRIs. Max 300mg/day in elderly.',
    specialNotesTh: 'ลดระดับการชัก (ระวังในผู้ป่วยโรคลมชัก) เสี่ยง Serotonin syndrome หากใช้ร่วมกับยาต้านซึมเศร้า ผู้สูงอายุไม่เกิน 300mg/วัน',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Moderate to Severe Pain (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 50.0,
        doseUnit: DoseUnit.mg,
        frequency: 'q6h prn',
        limits: DoseLimit(
          maxSingleDose: 100.0,
          maxDailyDose: 400.0,
        ),
        renalAdjustments: [
          RenalAdjustment(crclMin: 0, crclMax: 30, adjustmentFactor: 1.0, adjustedFrequency: 'q12h', notes: 'Max 200mg/day'),
        ],
      ),
      DosingRegimen(
        route: DoseRoute.iv,
        indication: 'Moderate to Severe Pain (Adult IV)',
        dosingType: DosingType.fixed,
        fixedDose: 50.0,
        doseUnit: DoseUnit.mg,
        frequency: 'q6h prn',
        limits: DoseLimit(
          maxSingleDose: 100.0,
          maxDailyDose: 400.0,
        ),
      ),
    ],
  ),
  Drug(
    id: 'morphine',
    genericName: 'Morphine',
    brandNames: ['MST Continus', 'Morphine Sulfate'],
    nameTh: 'มอร์ฟีน',
    category: DrugCategory.opioid,
    requiresRenalAdjustment: true,
    requiresHepaticCaution: true,
    isHighAlert: true,
    contraindications: ['Respiratory depression', 'Paralytic ileus'],
    specialNotes: 'Active metabolites accumulate in renal impairment. Monitor for respiratory depression.',
    specialNotesTh: 'สารเมแทบอไลต์สะสมในผู้ป่วยไตวาย ต้องระวังการกดการหายใจอย่างใกล้ชิด',
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Severe Pain (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 2.0, // 2-4 mg initial
        doseUnit: DoseUnit.mg,
        frequency: 'q5-15min prn (titrate)',
        limits: DoseLimit(
          softMaxSingleDose: 5.0,
        ),
        renalAdjustments: [
          RenalAdjustment(crclMin: 10, crclMax: 50, adjustmentFactor: 0.75),
          RenalAdjustment(crclMin: 0, crclMax: 9, adjustmentFactor: 0.5),
        ],
      ),
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Severe Pain (Pediatric)',
        dosingType: DosingType.weightBased,
        dosePerKg: 0.05, // 0.05 - 0.1 mg/kg
        doseUnit: DoseUnit.mg,
        frequency: 'q2-4h prn',
        limits: DoseLimit(
          maxSingleDose: 5.0, // Max initial single dose
        ),
      ),
    ],
  ),
  Drug(
    id: 'fentanyl',
    genericName: 'Fentanyl',
    brandNames: ['Durogesic', 'Sublimaze'],
    nameTh: 'เฟนทานิล',
    category: DrugCategory.opioid,
    requiresHepaticCaution: true,
    isHighAlert: true,
    specialNotes: 'Dosed in MICROGRAMS (mcg). 100 times more potent than morphine. Preferred in renal failure.',
    specialNotesTh: 'ขนาดยาหน่วยเป็น ไมโครกรัม (mcg) แรงกว่ามอร์ฟีน 100 เท่า ปลอดภัยกว่าในผู้ป่วยโรคไต',
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Analgesia / Procedural Sedation (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 50.0, // 25-50 mcg
        doseUnit: DoseUnit.mcg, // IMPORTANT: mcg
        frequency: 'q15-30min prn',
        limits: DoseLimit(
          softMaxSingleDose: 100.0,
        ),
      ),
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Continuous Sedation/Analgesia (ICU)',
        dosingType: DosingType.weightBased, // or titrated
        dosePerKg: 1.0, // 1-2 mcg/kg/hr
        doseUnit: DoseUnit.mcg,
        frequency: 'continuous',
      ),
    ],
  ),
];

