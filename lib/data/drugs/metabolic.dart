import '../../core/models/models.dart';

final List<Drug> metabolic = [
  const Drug(
    id: 'metformin',
    genericName: 'Metformin',
    brandNames: ['Glucophage'],
    nameTh: 'เมทฟอร์มิน',
    category: DrugCategory.endocrine, // Or metabolic
    requiresRenalAdjustment: true,
    allergyClass: 'Biguanide',
    severeInteractions: [
      'Iodinated Contrast Media (Risk of lactic acidosis - withhold Metformin for 48h after procedure)'
    ],
    contraindications: [
      'eGFR < 30 mL/min/1.73m2',
      'Acute or chronic metabolic acidosis (e.g. DKA)'
    ],
    specialNotes: 'Risk of lactic acidosis. Monitor eGFR closely.',
    specialNotesTh: 'เสี่ยงต่อภาวะเลือดเป็นกรด (Lactic acidosis) ห้ามใช้ในผู้ป่วยที่ไตวาย (eGFR < 30) และต้องงดยาก่อนฉีดสี 48 ชั่วโมง',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Type 2 Diabetes (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 500.0, // Initial 500 mg BID or OD
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q12h,
        limits: DoseLimit(
          maxDailyDose: 2550.0,
        ),
        renalAdjustments: [
          RenalAdjustment(crclMin: 30, crclMax: 45, action: RenalAction.adjust, adjustmentFactor: 0.5, notes: 'Max 1,000 mg/day. Do not initiate new therapy.'),
          RenalAdjustment(crclMin: 0, crclMax: 30, action: RenalAction.contraindicated, notes: 'CONTRAINDICATED: Risk of lactic acidosis at CrCl < 30 mL/min', notesTh: 'ข้อห้ามใช้เด็ดขาด: เสี่ยงต่อภาวะ Lactic acidosis เมื่อ CrCl < 30 มล./นาที'), // 0.0 conceptually blocks it if logic implemented, or use notes
        ],
      ),
    ],
  ),
  const Drug(
    id: 'atorvastatin',
    genericName: 'Atorvastatin',
    brandNames: ['Lipitor', 'Xarator'],
    nameTh: 'อะทอร์วาสแตติน',
    category: DrugCategory.endocrine, // Lipid lowering
    requiresHepaticCaution: true,
    allergyClass: 'Statin',
    severeInteractions: [
      'Macrolide Antibiotics (e.g. Clarithromycin) - Increases risk of rhabdomyolysis',
      'Cyclosporine (Avoid or max 10mg/day)',
      'Gemfibrozil (Avoid combination)'
    ],
    contraindications: [
      'Active liver disease',
      'Unexplained persistent elevations of hepatic transaminases',
      'Pregnancy and lactation'
    ],
    specialNotes: 'Risk of myopathy and rhabdomyolysis. Monitor liver enzymes.',
    specialNotesTh: 'ระวังกล้ามเนื้อสลายตัว (Rhabdomyolysis) ห้ามใช้ในคนท้องและผู้ป่วยตับอักเสบ ห้ามกินร่วมกับยาฆ่าเชื้อบางชนิด',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Hyperlipidemia / ASCVD Risk (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 40.0, // 40-80 mg High intensity, 10-20 mg Moderate
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q24h,
        limits: DoseLimit(
          maxDailyDose: 80.0,
        ),
      ),
    ],
  ),
];

