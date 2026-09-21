import '../../core/models/models.dart';

final List<Drug> nephrology = [
  Drug(
    id: 'sevelamer',
    genericName: 'Sevelamer',
    brandNames: ['Renvela', 'Renagel'],
    nameTh: 'เซเวลาเมอร์',
    category: DrugCategory.nephrology,
    pregnancyCategory: 'C',
    severeInteractions: [
      'Levothyroxine (decreases absorption)',
      'Ciprofloxacin (separate by 2 hours)'
    ],
    specialNotes: 'Take with meals. Do not chew or crush.',
    specialNotesTh: 'ทานพร้อมอาหาร ห้ามเคี้ยวหรือบดยา',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Hyperphosphatemia in CKD',
        dosingType: DosingType.fixed,
        fixedDose: 800, // 800-1600 mg
        doseUnit: DoseUnit.mg,
        frequency: 'TID with meals',
        limits: DoseLimit(maxDailyDose: 14000), // Max is ~14g/day
      ),
    ],
  ),
  Drug(
    id: 'epoetin_alfa',
    genericName: 'Epoetin alfa',
    brandNames: ['Epogen', 'Hemax'],
    nameTh: 'อีโปอีติน อัลฟ่า',
    category: DrugCategory.nephrology,
    pregnancyCategory: 'C',
    isHighAlert: true,
    contraindications: [
      'Uncontrolled hypertension',
      'Pure Red Cell Aplasia (PRCA)'
    ],
    severeInteractions: [],
    specialNotes:
        'Target hemoglobin usually 10-11.5 g/dL. Risk of thrombosis if Hb > 11.5.',
    specialNotesTh:
        'เป้าหมาย Hb 10-11.5 g/dL ระวังเส้นเลือดอุดตันหาก Hb สูงเกินไป',
    regimens: [
      DosingRegimen(
        route: DoseRoute.sc,
        indication: 'Anemia in CKD',
        dosingType: DosingType.weightBased,
        dosePerKg: 50, // 50-100 units/kg
        doseUnit: DoseUnit.units,
        frequency: '1-3 times per week',
      ),
    ],
  ),
  Drug(
    id: 'sodium_polystyrene_sulfonate',
    genericName: 'Sodium polystyrene sulfonate',
    brandNames: ['Kalimate', 'Kayexalate'],
    nameTh: 'คาลิเมท / โซเดียม โพลีสไตรีน ซัลโฟเนต',
    category: DrugCategory.nephrology,
    pregnancyCategory: 'C',
    contraindications: ['Bowel obstruction', 'Hypokalemia'],
    severeInteractions: ['Sorbitol (intestinal necrosis risk)'],
    specialNotes: 'Separate from other oral meds by at least 3 hours.',
    specialNotesTh: 'ควรรับประทานห่างจากยาอื่นอย่างน้อย 3 ชั่วโมง',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Hyperkalemia',
        dosingType: DosingType.fixed,
        fixedDose: 15, // 15-30g
        doseUnit: DoseUnit.g,
        frequency: 'OD to QID',
        limits: DoseLimit(maxDailyDose: 120), // 15g QID x 2 is max typically
      ),
      DosingRegimen(
        route: DoseRoute.pr,
        indication: 'Hyperkalemia (Enema)',
        dosingType: DosingType.fixed,
        fixedDose: 30, // 30-50g
        doseUnit: DoseUnit.g,
        frequency: 'q6h',
      ),
    ],
  ),
  Drug(
    id: 'calcitriol',
    genericName: 'Calcitriol (Active Vitamin D3)',
    brandNames: ['Rocaltrol'],
    nameTh: 'แคลซิไตรออล',
    category: DrugCategory.nephrology,
    pregnancyCategory: 'C',
    contraindications: ['Hypercalcemia', 'Vitamin D toxicity'],
    severeInteractions: [
      'Digitalis (increased toxicity risk with hypercalcemia)'
    ],
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Secondary hyperparathyroidism / Hypocalcemia',
        dosingType: DosingType.fixed,
        fixedDose: 0.25, // 0.25 mcg
        doseUnit: DoseUnit.mcg,
        frequency: 'OD',
      ),
    ],
  ),
  Drug(
    id: 'calcium_carbonate',
    genericName: 'Calcium Carbonate',
    brandNames: ['CaCO3'],
    nameTh: 'แคลเซียมคาร์บอเนต',
    category: DrugCategory.supplement, // It's a supplement too
    pregnancyCategory: 'C',
    contraindications: ['Hypercalcemia'],
    severeInteractions: [
      'Iron',
      'Tetracyclines',
      'Quinolones',
      'Levothyroxine (separate by 2-4 hours)'
    ],
    specialNotes: 'Take with meals when used as a phosphate binder.',
    specialNotesTh: 'ทานพร้อมอาหารเมื่อใช้เพื่อจับฟอสเฟตในเลือด',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Phosphate Binder (CKD)',
        dosingType: DosingType.fixed,
        fixedDose: 1000,
        doseUnit: DoseUnit.mg,
        frequency: 'TID with meals',
        limits: DoseLimit(
            maxDailyDose:
                3000), // Varies, but usually max 3000 mg elemental Ca/day from all sources
      ),
    ],
  ),
  Drug(
    id: 'cinacalcet',
    genericName: 'Cinacalcet',
    brandNames: ['Sensipar'],
    nameTh: 'ซินาแคลเซต',
    category: DrugCategory.nephrology,
    pregnancyCategory: 'C',
    contraindications: ['Hypocalcemia'],
    severeInteractions: [
      'Ketoconazole (strong CYP3A4 inhibitors increase levels)'
    ],
    specialNotes: 'Take with food or shortly after a meal.',
    specialNotesTh: 'ทานพร้อมอาหารหรือหลังอาหารทันที',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Secondary hyperparathyroidism in dialysis',
        dosingType: DosingType.fixed,
        fixedDose: 30,
        doseUnit: DoseUnit.mg,
        frequency: 'OD',
        limits: DoseLimit(maxDailyDose: 300),
      ),
    ],
  ),
  Drug(
    id: 'tacrolimus',
    genericName: 'Tacrolimus',
    brandNames: ['Prograf', 'Advagraf'],
    nameTh: 'ทาโครลิมัส',
    category: DrugCategory.nephrology,
    pregnancyCategory: 'C',
    isHighAlert: true,
    requiresRenalAdjustment: true,
    requiresTDM: true,
    severeInteractions: [
      'Grapefruit juice',
      'Diltiazem',
      'Macrolides (increase tacrolimus levels)'
    ],
    specialNotes:
        'Maintain consistent timing and relationship to meals. Target trough varies by time post-transplant.',
    specialNotesTh:
        'รับประทานยาให้ตรงเวลาสม่ำเสมอ หลีกเลี่ยงน้ำเกรปฟรุต ระดับยาเป้าหมายขึ้นกับระยะเวลาหลังปลูกถ่ายไต',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Kidney Transplant (Maintenance)',
        dosingType: DosingType.weightBased,
        dosePerKg: 0.05, // typically 0.05 - 0.1 mg/kg/dose BID
        doseUnit: DoseUnit.mg,
        frequency: 'BID',
      ),
    ],
  ),
  Drug(
    id: 'mycophenolate',
    genericName: 'Mycophenolate Mofetil (MMF)',
    brandNames: ['CellCept'],
    nameTh: 'ไมโคฟีโนเลต',
    category: DrugCategory.nephrology,
    pregnancyCategory: 'D', // Risk of fetal harm
    isHighAlert: true,
    contraindications: ['Pregnancy (must use effective contraception)'],
    severeInteractions: ['Antacids (decrease absorption)', 'Cholestyramine'],
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Kidney Transplant / Lupus Nephritis',
        dosingType: DosingType.fixed,
        fixedDose: 1000,
        doseUnit: DoseUnit.mg,
        frequency: 'BID',
        limits: DoseLimit(maxDailyDose: 3000),
      ),
    ],
  ),
];
