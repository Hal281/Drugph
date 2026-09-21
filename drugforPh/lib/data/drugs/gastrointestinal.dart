import '../../core/models/models.dart';

final List<Drug> gastrointestinal = [
  Drug(
    id: 'omeprazole',
    genericName: 'Omeprazole',
    brandNames: ['Miracid', 'Losec', 'O-Sid'],
    nameTh: 'โอเมพราโซล',
    category: DrugCategory.gastrointestinal,
    requiresHepaticCaution: true,
    allergyClass: 'Proton Pump Inhibitor (PPI)',
    severeInteractions: [
      'Clopidogrel (decreases antiplatelet effect - use Pantoprazole instead)',
      'Ketoconazole / Itraconazole (decreased absorption)',
      'Warfarin (may increase bleeding risk)'
    ],
    specialNotes: 'Take 30 minutes before meals. Long-term use associated with hypomagnesemia and bone fractures.',
    specialNotesTh: 'ทานก่อนอาหาร 30 นาที การใช้ระยะยาวอาจทำให้แมกนีเซียมต่ำหรือกระดูกพรุน',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'GERD / Peptic Ulcer Disease (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 20.0, // 20-40 mg
        doseUnit: DoseUnit.mg,
        frequency: 'q24h (OD) or q12h (BID)',
        limits: DoseLimit(
          maxDailyDose: 80.0, // Zollinger-Ellison can go higher, but standard max is 80-120
        ),
      ),
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Bleeding Peptic Ulcer (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 80.0, // 80 mg bolus then 8 mg/hr
        doseUnit: DoseUnit.mg,
        frequency: 'Stat, then continuous infusion',
      ),
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'GERD (Pediatric > 1 year)',
        dosingType: DosingType.weightBased,
        dosePerKg: 1.0, // 1-2 mg/kg/day
        doseUnit: DoseUnit.mg,
        frequency: 'q24h',
        limits: DoseLimit(
          maxDailyDose: 40.0,
        ),
      ),
    ],
  ),
  Drug(
    id: 'metoclopramide',
    genericName: 'Metoclopramide',
    brandNames: ['Plasil'],
    nameTh: 'เมโทโคลพราไมด์',
    category: DrugCategory.antiemetic,
    requiresRenalAdjustment: true,
    allergyClass: 'Benzamide',
    severeInteractions: [
      'Antipsychotics (increased risk of EPS/Tardive Dyskinesia)',
      'Levodopa (antagonistic effect)',
      'CNS Depressants'
    ],
    contraindications: [
      'GI hemorrhage, obstruction, or perforation',
      'History of seizures',
      'Pheochromocytoma'
    ],
    specialNotes: 'Risk of Extrapyramidal Symptoms (EPS) and Tardive Dyskinesia. Avoid in children if possible.',
    specialNotesTh: 'เสี่ยงต่ออาการกล้ามเนื้อเกร็งกระตุก (EPS) หลีกเลี่ยงการใช้ในเด็กหากไม่จำเป็น',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Nausea/Vomiting (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 10.0,
        doseUnit: DoseUnit.mg,
        frequency: 'q8h prn (TID)',
        limits: DoseLimit(
          maxSingleDose: 15.0,
          maxDailyDose: 40.0,
        ),
        renalAdjustments: [
          RenalAdjustment(crclMin: 0, crclMax: 40, adjustmentFactor: 0.5),
        ],
      ),
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Nausea/Vomiting (Adult IV)',
        dosingType: DosingType.fixed,
        fixedDose: 10.0,
        doseUnit: DoseUnit.mg,
        frequency: 'q8h prn (TID)',
        limits: DoseLimit(maxDailyDose: 40.0),
      ),
    ],
  ),
  Drug(
    id: 'domperidone',
    genericName: 'Domperidone',
    brandNames: ['Motilium'],
    nameTh: 'ดอมเพอริโดน',
    category: DrugCategory.antiemetic,
    requiresHepaticCaution: true,
    allergyClass: 'Benzimidazole',
    severeInteractions: [
      'CYP3A4 Inhibitors (Ketoconazole, Erythromycin - significantly increases QT prolongation risk)',
    ],
    contraindications: [
      'Prolonged QT interval',
      'Moderate to severe hepatic impairment',
      'GI hemorrhage or obstruction'
    ],
    specialNotes: 'Does not cross blood-brain barrier well, so lower risk of EPS than metoclopramide. High risk of QT prolongation.',
    specialNotesTh: 'ความเสี่ยงกล้ามเนื้อเกร็ง (EPS) ต่ำกว่า Plasil แต่ต้องระวังหัวใจเต้นผิดจังหวะ (QT prolongation) ห้ามใช้ร่วมกับยาฆ่าเชื้อราหรือ Macrolide',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Nausea/Vomiting (Adult & Adolescents >35kg)',
        dosingType: DosingType.fixed,
        fixedDose: 10.0,
        doseUnit: DoseUnit.mg,
        frequency: 'q8h prn',
        limits: DoseLimit(
          maxDailyDose: 30.0,
        ),
      ),
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Nausea/Vomiting (Pediatric <35kg)',
        dosingType: DosingType.weightBased,
        dosePerKg: 0.25, // 0.25 mg/kg per dose
        doseUnit: DoseUnit.mg,
        frequency: 'q8h prn',
        limits: DoseLimit(
          maxDosePerKgPerDay: 0.75, // Max 0.75 mg/kg/day
        ),
      ),
    ],
  ),
  Drug(
    id: 'ondansetron',
    genericName: 'Ondansetron',
    brandNames: ['Zofran', 'Onsia'],
    nameTh: 'ออนแดนเซทรอน',
    category: DrugCategory.antiemetic,
    requiresHepaticCaution: true, // Max 8mg/day in severe hepatic impairment
    allergyClass: '5-HT3 Antagonist',
    severeInteractions: [
      'Apomorphine (profound hypotension)',
      'Other QT prolonging drugs'
    ],
    contraindications: ['Concurrent use with Apomorphine'],
    specialNotes: 'Dose-dependent QT prolongation. Max 8mg/day in severe liver disease (Child-Pugh C).',
    specialNotesTh: 'ระวังคลื่นไฟฟ้าหัวใจ (QT) ผิดปกติ ผู้ป่วยโรคตับรุนแรงห้ามใช้เกิน 8 mg/วัน',
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'CINV / PONV (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 8.0, // 4-8 mg
        doseUnit: DoseUnit.mg,
        frequency: 'q8h prn',
        limits: DoseLimit(
          maxSingleDose: 16.0, // Single doses >16mg no longer recommended due to QT
          maxDailyDose: 24.0,
        ),
      ),
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Nausea/Vomiting (Pediatric)',
        dosingType: DosingType.weightBased,
        dosePerKg: 0.15, // 0.15 mg/kg/dose
        doseUnit: DoseUnit.mg,
        frequency: 'q8h prn',
        limits: DoseLimit(
          maxSingleDose: 8.0,
        ),
      ),
    ],
  ),
  Drug(
    id: 'hyoscine_butylbromide',
    genericName: 'Hyoscine Butylbromide',
    brandNames: ['Buscopan'],
    nameTh: 'ไฮออสซีน / บัสโคพาน',
    category: DrugCategory.gastrointestinal,
    allergyClass: 'Anticholinergic',
    severeInteractions: [
      'Other anticholinergics (additive effects)',
      'Tricyclic Antidepressants'
    ],
    contraindications: [
      'Myasthenia gravis',
      'Megacolon',
      'Untreated narrow-angle glaucoma'
    ],
    specialNotes: 'Anticholinergic side effects (dry mouth, blurred vision, tachycardia).',
    specialNotesTh: 'มีฤทธิ์ Anticholinergic ทำให้ปากแห้ง คอแห้ง ใจสั่น ปัสสาวะคั่ง ระวังในผู้ป่วยต่อมลูกหมากโต',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'GI Spasm / Cramping (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 10.0, // 10-20 mg
        doseUnit: DoseUnit.mg,
        frequency: 'q6h-q8h (TID to QID)',
        limits: DoseLimit(
          maxSingleDose: 20.0,
          maxDailyDose: 100.0,
        ),
      ),
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Acute GI/GU Spasm (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 20.0,
        doseUnit: DoseUnit.mg,
        frequency: 'q30min prn (max 100mg/day)',
        limits: DoseLimit(
          maxSingleDose: 20.0,
          maxDailyDose: 100.0,
        ),
      ),
    ],
  ),
];

