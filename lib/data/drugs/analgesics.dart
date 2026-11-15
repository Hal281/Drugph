// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import '../../core/models/models.dart';

final List<Drug> analgesics = [
  Drug(
    id: 'paracetamol',
    genericName: 'Paracetamol (Acetaminophen)',
    brandNames: ['Tylenol', 'Sara', 'Calpol'],
    nameTh: 'พาราเซตามอล',
    category: DrugCategory.analgesic,
    requiresHepaticCaution: true,
    sourceCitation: 'Lexicomp Drug Information / บัญชียาหลักแห่งชาติ & คู่มือการใช้ยาอย่างสมเหตุผล (RDU Thailand)',
    lastReviewedDate: '2024-10-12',
    provenance: const Provenance(
      source: 'Lexicomp Drug Information 2024 / แนวทางการใช้ยาอย่างสมเหตุผล (RDU Thailand)',
      reviewedBy: 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
      reviewedAt: '2024-10-12',
      sourceDetail: 'Acetaminophen Monograph & RDU Pain Practice Guidelines',
    ),
    monograph: const ClinicalMonograph(
      textbookName: 'Lexicomp Drug Information / RDU Thailand',
      editionYear: '2024 Edition',
      sectionOrTable: 'Acetaminophen Dosing, Toxicity & Hepatic Safety',
      dosingGuideline:
          '• ผู้ใหญ่ (Oral/IV): 500–1,000 mg ทุก 4–6 ชม. เมื่อมีอาการปวดหรือไข้\n'
          '• ขนาดยาสูงสุด: ไม่เกิน 4,000 mg/วัน (แนวทาง อย. และ RDU ประเทศไทย แนะนำไม่เกิน 3,000 mg/วัน หรือ 60 mg/kg/day สำหรับผู้ป่วยนอกทั่วไป เพื่อป้องกันภาวะตับอักเสบเรื้อรัง)\n'
          '• เด็ก (Pediatric): 10–15 mg/kg/dose ทุก 4–6 ชม. เมื่อจำเป็น (สูงสุดไม่เกิน 75 mg/kg/day หรือ 3,750 mg/day)',
      renalGuideline:
          '• CrCl >= 50 mL/min: ให้ยาทุก 4–6 ชม. ตามปกติ\n'
          '• CrCl 10–50 mL/min: ขยายระยะเวลาการบริหารยาเป็นทุก 6 ชม.\n'
          '• CrCl < 10 mL/min: ขยายระยะเวลาการบริหารยาเป็นทุก 8 ชม.',
      administrationGuideline:
          '• ยาเม็ด/ยาน้ำรับประทาน: สามารถรับประทานก่อนหรือหลังอาหารก็ได้\n'
          '• ยาฉีด IV Infusion (1,000 mg/100 mL): หยดทางหลอดเลือดดำนาน 15 นาที',
      clinicalNotes:
          '• พิษต่อตับเฉียบพลัน (Severe Hepatotoxicity / Centrilobular Necrosis): เกิดขึ้นเมื่อรับประทานยาเกินขนาด (Single ingestion >= 7.5–10 g ในผู้ใหญ่ หรือ >= 150 mg/kg ในเด็ก)\n'
          '• ในผู้ป่วยโรคตับแข็ง (Cirrhosis), ทุพโภชนาการ, หรือติดสุราเรื้อรัง (Chronic Alcoholism): จำกัดขนาดยาสูงสุดไม่เกิน 2,000 mg/วัน\n'
          '• ยาต้านพิษ (Antidote): N-acetylcysteine (NAC) ตาม Rumack-Matthew nomogram',
      externalUrl: 'https://online.lexi.com',
    ),
    specialNotes: 'Max daily dose 4g in adults to prevent hepatotoxicity. Reduce to 2g/day in severe hepatic impairment or chronic alcoholism.',
    specialNotesTh: 'ขนาดยาสูงสุด 4 กรัม/วัน ในผู้ใหญ่เพื่อป้องกันตับอักเสบ ลดเหลือ 2 กรัม/วัน ในผู้ป่วยโรคตับรุนแรงหรือติดสุราเรื้อรัง',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Fever/Pain (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 500.0, // 500 - 1000 mg
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q4_6hPrn,
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
        frequency: Frequency.q4_6hPrn,
        formulation: DrugFormulation.oralLiquid,
        liquidConcentrations: const [
          OralLiquidConcentration(
            label: '120 mg / 5 mL (24 mg/mL)',
            amountMg: 120.0,
            perVolumeMl: 5.0,
            brandOrForm: 'Syrup / Suspension',
            citation: 'Drug Information Handbook (Lexicomp) 2024 / RDU Thailand',
            isDefault: true,
          ),
          OralLiquidConcentration(
            label: '250 mg / 5 mL (50 mg/mL)',
            amountMg: 250.0,
            perVolumeMl: 5.0,
            brandOrForm: 'Forte Suspension',
            citation: 'Drug Information Handbook (Lexicomp) 2024 / RDU Thailand',
          ),
        ],
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
        frequency: Frequency.q6hPrn,
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
    drugClass: DrugClass.nsaid,
    sourceCitation: 'Lexicomp Drug Information 2024 / RDU Thailand Guidelines',
    lastReviewedDate: '2024-10-12',
    provenance: const Provenance(
      source: 'Lexicomp Drug Information 2024 / RDU NSAID Guidelines',
      reviewedBy: 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
      reviewedAt: '2024-10-12',
      sourceDetail: 'Ibuprofen Monograph: Renal & Cardiovascular Safety Profile',
    ),
    monograph: const ClinicalMonograph(
      textbookName: 'Lexicomp Drug Information / RDU Thailand',
      editionYear: '2024 Edition',
      sectionOrTable: 'Ibuprofen Dosing & Renal Safety Guidance',
      dosingGuideline:
          '• ผู้ใหญ่: 400 mg รับประทานทุก 6–8 ชม. หลังอาหารทันทีเมื่อมีอาการปวดหรืออักเสบ (ขนาดยาสูงสุด 2,400 mg/วัน; ในข้ออักเสบรูมาตอยด์รุนแรงภายใต้การดูแลของแพทย์ไม่เกิน 3,200 mg/วัน)\n'
          '• เด็ก (> 6 เดือน): 5–10 mg/kg/dose ทุก 6–8 ชม. PRN (ขนาดยาสูงสุด 40 mg/kg/day หรือไม่เกิน 2,400 mg/day)',
      renalGuideline:
          '• CrCl 30–60 mL/min: ใช้ด้วยความระมัดระวัง ใช้ขนาดยาต่ำสุดในระยะเวลาสั้นที่สุด\n'
          '• CrCl < 30 mL/min: หลีกเลี่ยงการใช้โดยเด็ดขาด เนื่องจากยับยั้ง Vasodilatory prostaglandins (PGI2/PGE2) ที่ Afferent arteriole ทำให้เกิดไตวายเฉียบพลัน (Prerenal AKI) และโพแทสเซียมคั่ง',
      administrationGuideline:
          '• รับประทานพร้อมอาหารหรือหลังอาหารทันที และดื่มน้ำตามมากๆ เพื่อลดการระคายเคืองเยื่อบุกระเพาะอาหาร',
      clinicalNotes:
          '• ข้อห้ามใช้เด็ดขาด: ห้ามใช้ในผู้ป่วยที่สงสัยไข้เลือดออก (Dengue hemorrhagic fever) หรือมีภาวะเลือดออกในทางเดินอาหาร\n'
          '• ข้อห้ามใช้ในสตรีมีครรภ์: Category D ในไตรมาสที่ 3 (เสี่ยงปิดท่อหลอดเลือด Ductus Arteriosus ก่อนกำหนด และ Oligohydramnios)\n'
          '• ห้ามใช้ซ้ำซ้อนกับ NSAID ตัวอื่น (Dual NSAIDs Contradiction)',
      externalUrl: 'https://online.lexi.com',
    ),
    interactions: [
      DrugInteraction(
        targetDrugId: 'warfarin',
        targetClass: DrugClass.anticoagulantVka,
        severity: InteractionSeverity.major,
        mechanismEn:
            'Ibuprofen inhibits platelet COX-1 and causes gastric mucosal injury, markedly increasing the risk of major upper GI bleeding with Warfarin.',
        mechanismTh:
            'ไอบูโพรเฟนยับยั้งการทำงานของเกล็ดเลือดและระคายเคืองเยื่อบุกระเพาะอาหาร เพิ่มความเสี่ยงเลือดออกในทางเดินอาหารอย่างรุนแรงเมื่อใช้ร่วมกับ Warfarin',
        managementEn:
            'Avoid combination. Consider Paracetamol for analgesia. If NSAID unavoidable, monitor closely and coprescribe PPI.',
        managementTh:
            'หลีกเลี่ยงการใช้ร่วมกัน พิจารณาใช้พาราเซตามอลแทน หากจำเป็นต้องใช้ให้เฝ้าระวังอย่างใกล้ชิดและจ่ายร่วมกับยาลดกรดกลุ่ม PPI',
        source: 'Lexicomp / AHFS Drug Information 2024',
      ),
    ],
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
        frequency: Frequency.q6_8hPrn,
        population: const PopulationCriteria(minAgeMonths: 216),
        audience: RegimenAudience.adult,
        notes: 'Mild-to-moderate pain, fever, or dysmenorrhea: 400 mg PO q6–8h PRN after meals (max 2,400–3,200 mg/day).',
        notesTh: 'ลดไข้ / ปวดเล็กน้อยถึงปานกลาง (ผู้ใหญ่): 400 mg PO ทุก 6–8 ชม. หลังอาหารทันที เมื่อมีอาการ',
        limits: const DoseLimit(
          maxSingleDose: 800.0,
          maxDailyDose: 3200.0,
        ),
        renalAdjustments: [
          const RenalAdjustment(
            crclMin: 0,
            crclMax: 30,
            action: RenalAction.avoid,
            notes: 'Avoid in CrCl < 30 mL/min; risk of AKI and severe fluid retention',
          ),
        ],
      ),
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Osteoarthritis / Rheumatoid Arthritis / Inflammatory (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 600.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q8h,
        population: const PopulationCriteria(minAgeMonths: 216),
        audience: RegimenAudience.adult,
        notes: 'Anti-inflammatory regimen for osteoarthritis or rheumatoid arthritis: 600 mg PO q8h (up to 800 mg q6–8h; max 3,200 mg/day).',
        notesTh: 'ต้านการอักเสบ / ข้อเสื่อม / ข้ออักเสบรูมาตอยด์ (ผู้ใหญ่): 600 mg PO ทุก 8 ชม. หลังอาหาร (สูงสุด 3,200 mg/วัน)',
        limits: const DoseLimit(
          maxSingleDose: 800.0,
          maxDailyDose: 3200.0,
        ),
        renalAdjustments: [
          const RenalAdjustment(
            crclMin: 0,
            crclMax: 30,
            action: RenalAction.avoid,
            notes: 'Avoid in CrCl < 30 mL/min; risk of AKI and severe fluid retention',
          ),
        ],
      ),
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Fever/Pain (Pediatric >6 months)',
        dosingType: DosingType.weightBased,
        dosePerKg: 10.0,
        minDosePerKg: 5.0,
        maxDosePerKg: 10.0,
        doseBasis: DoseBasis.perDose,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q6_8hPrn,
        formulation: DrugFormulation.oralLiquid,
        liquidConcentrations: const [
          OralLiquidConcentration(
            label: '100 mg / 5 mL (20 mg/mL)',
            amountMg: 100.0,
            perVolumeMl: 5.0,
            brandOrForm: 'Oral Suspension',
            citation: 'Drug Information Handbook (Lexicomp) 2024 / Pediatric & Neonatal Dosage Handbook',
            isDefault: true,
          ),
        ],
        population: const PopulationCriteria(minAgeMonths: 6, maxAgeMonths: 215),
        audience: RegimenAudience.pediatric,
        notes: 'Pediatric fever or acute pain (>6 months): 5–10 mg/kg/dose PO q6–8h PRN (max 400 mg/dose, max 40 mg/kg/day or 2,400 mg/day).',
        notesTh: 'ลดไข้ / แก้ปวดในเด็ก (> 6 เดือน): 5–10 mg/kg/ครั้ง ทุก 6–8 ชม. เมื่อมีอาการ (สูงสุด 400 mg/ครั้ง หรือ 40 mg/kg/วัน)',
        limits: const DoseLimit(
          maxSingleDose: 400.0,
          maxDailyDose: 2400.0,
          maxDosePerKgPerDay: 40.0,
        ),
        renalAdjustments: [
          const RenalAdjustment(
            crclMin: 0,
            crclMax: 30,
            action: RenalAction.avoid,
            notes: 'Avoid in CrCl < 30 mL/min; risk of AKI and severe fluid retention',
          ),
        ],
      ),
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Juvenile Idiopathic Arthritis / Inflammatory (Pediatric >6 months)',
        dosingType: DosingType.weightBased,
        dosePerKg: 35.0,
        minDosePerKg: 30.0,
        maxDosePerKg: 40.0,
        doseBasis: DoseBasis.perDay,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q8h,
        population: const PopulationCriteria(minAgeMonths: 6, maxAgeMonths: 215),
        audience: RegimenAudience.pediatric,
        notes: 'Juvenile idiopathic arthritis (JIA): 30–40 mg/kg/day PO divided q8h (up to 50 mg/kg/day under specialist care; max 2,400 mg/day).',
        notesTh: 'ข้ออักเสบในเด็ก JIA (> 6 เดือน): 30–40 mg/kg/วัน แบ่งทุก 8 ชม. หลังอาหาร (สูงสุด 2,400 mg/วัน)',
        limits: const DoseLimit(
          maxSingleDose: 800.0,
          maxDailyDose: 2400.0,
          maxDosePerKgPerDay: 50.0,
        ),
        renalAdjustments: [
          const RenalAdjustment(
            crclMin: 0,
            crclMax: 30,
            action: RenalAction.avoid,
            notes: 'Avoid in CrCl < 30 mL/min; risk of AKI and severe fluid retention',
          ),
        ],
      ),
    ],
  ),
  const Drug(
    id: 'naproxen',
    genericName: 'Naproxen',
    brandNames: ['Synflex', 'Aleve'],
    nameTh: 'นาพรอกเซน',
    category: DrugCategory.nsaid,
    requiresRenalAdjustment: true,
    allergyClass: 'NSAID / Aspirin',
    drugClass: DrugClass.nsaid,
    sourceCitation: 'Lexicomp Drug Information 2024 / แนวทางการใช้ยาอย่างสมเหตุผล (RDU Thailand)',
    lastReviewedDate: '2024-10-12',
    provenance: Provenance(
      source: 'Lexicomp Drug Information 2024 / RDU NSAID Guidelines',
      reviewedBy: 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
      reviewedAt: '2024-10-12',
      sourceDetail: 'Naproxen Monograph: Adult/Pediatric Dosing & Renal/GI Safety',
    ),
    monograph: ClinicalMonograph(
      textbookName: 'Lexicomp Drug Information / RDU Thailand',
      editionYear: '2024 Edition',
      sectionOrTable: 'Naproxen Dosing, Contraindications & Renal Safety Guidance',
      dosingGuideline:
          '• ผู้ใหญ่ (Pain / Osteoarthritis / Inflammation): 250–500 mg รับประทานทุก 12 ชม. (ขนาดยาสูงสุดไม่เกิน 1,250 mg/วัน ในวันแรก และไม่เกิน 1,000 mg/วัน สำหรับการให้ต่อเนื่อง)\n'
          '• โรคเกาต์เฉียบพลัน (Acute Gout): เริ่มต้น 750 mg ครั้งเดียว ตามด้วย 250 mg ทุก 8 ชม. จนอาการสงบ\n'
          '• เด็ก (> 2 ปี, Pain / Juvenile Idiopathic Arthritis): 5–7 mg/kg/dose รับประทานทุก 12 ชม. (10–15 mg/kg/day แบ่งให้วันละ 2 ครั้ง, สูงสุด 1,000 mg/day)',
      renalGuideline:
          '• CrCl >= 30 mL/min: ไม่จำเป็นต้องปรับขนาดยา แต่ควรใช้ขนาดต่ำสุดในระยะเวลาสั้นที่สุด\n'
          '• CrCl < 30 mL/min: หลีกเลี่ยงการใช้โดยเด็ดขาด เนื่องจากลด Renal blood flow (ยับยั้ง PGI2/PGE2) เสี่ยงไตวายเฉียบพลัน (AKI) และคั่งของสารน้ำ/โพแทสเซียม',
      administrationGuideline:
          '• รับประทานพร้อมอาหารหรือหลังอาหารทันที เพื่อลดการระคายเคืองและลดความเสี่ยงแผลในกระเพาะอาหาร',
      clinicalNotes:
          '• ข้อห้ามใช้เด็ดขาด: ผู้ป่วยที่สงสัยไข้เลือดออก (Dengue), มีแผลหรือเลือดออกในทางเดินอาหาร, ไตเสื่อมรุนแรง (CrCl < 30 mL/min), หรือหลังผ่าตัดบายพาสหลอดเลือดหัวใจ (CABG)\n'
          '• ห้ามใช้ซ้ำซ้อนกับ NSAID ตัวอื่น (Dual NSAIDs Contraindication)\n'
          '• ระมัดระวังอันตรกิริยารุนแรงกับ Warfarin, Lithium, Methotrexate และ ACEi/ARB',
      externalUrl: 'https://dailymed.nlm.nih.gov/dailymed/search.cfm?labeltype=all&query=naproxen',
    ),
    severeInteractions: ['Warfarin', 'ACE inhibitors', 'Lithium', 'Methotrexate'],
    contraindications: ['Active GI bleeding', 'Severe renal impairment (CrCl < 30 mL/min)', 'Dengue fever (suspected)', 'CABG surgery'],
    specialNotes: 'Take with food to reduce GI irritation. Avoid in CrCl < 30 mL/min, suspected Dengue fever, and active GI bleeding. Do not combine with other NSAIDs.',
    specialNotesTh: 'รับประทานหลังอาหารทันทีเพื่อลดการระคายเคืองกระเพาะ หลีกเลี่ยงในผู้ป่วย CrCl < 30 mL/min, สงสัยไข้เลือดออก หรือมีเลือดออกในทางเดินอาหาร ห้ามใช้ร่วมกับ NSAIDs ตัวอื่น',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Pain / Inflammation (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 250.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q12h,
        limits: DoseLimit(
          maxSingleDose: 500.0,
          maxDailyDose: 1250.0,
        ),
        renalAdjustments: [
          RenalAdjustment(
            crclMin: 0,
            crclMax: 30,
            action: RenalAction.avoid,
            notes: 'Avoid in CrCl < 30 mL/min; risk of AKI and severe fluid retention',
          ),
        ],
      ),
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Pain / Juvenile Idiopathic Arthritis (Pediatric >2 yrs)',
        dosingType: DosingType.weightBased,
        dosePerKg: 5.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q12h,
        population: PopulationCriteria(minAgeMonths: 24, maxAgeMonths: 215),
        limits: DoseLimit(
          maxSingleDose: 500.0,
          maxDailyDose: 1000.0,
          maxDosePerKgPerDay: 15.0,
        ),
        renalAdjustments: [
          RenalAdjustment(
            crclMin: 0,
            crclMax: 30,
            action: RenalAction.avoid,
            notes: 'Avoid in CrCl < 30 mL/min; risk of AKI and severe fluid retention',
          ),
        ],
      ),
    ],
  ),
  const Drug(
    id: 'tramadol',
    genericName: 'Tramadol',
    brandNames: ['Tramal'],
    nameTh: 'ทรามาดอล',
    category: DrugCategory.opioid,
    drugClass: DrugClass.opioid,
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
        frequency: Frequency.q6hPrn,
        limits: DoseLimit(
          maxSingleDose: 100.0,
          maxDailyDose: 400.0,
        ),
        renalAdjustments: [
          RenalAdjustment(crclMin: 0, crclMax: 30, action: RenalAction.adjust, adjustmentFactor: 1.0, adjustedFrequency: Frequency.q12h, notes: 'Max 200 mg/day'),
        ],
      ),
      DosingRegimen(
        route: DoseRoute.iv,
        indication: 'Moderate to Severe Pain (Adult IV)',
        dosingType: DosingType.fixed,
        fixedDose: 50.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q6hPrn,
        limits: DoseLimit(
          maxSingleDose: 100.0,
          maxDailyDose: 400.0,
        ),
        renalAdjustments: [
          RenalAdjustment(
            crclMin: 0,
            crclMax: 30,
            action: RenalAction.adjust,
            adjustmentFactor: 1.0,
            adjustedFrequency: Frequency.q12h,
            notes: 'Max 200 mg/day in CrCl < 30 mL/min',
          ),
        ],
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
    sourceCitation: 'Lexicomp Drug Information 2024 / สมาคมบริบาลผู้ป่วยระยะท้ายไทย & รพ.รามาธิบดี',
    lastReviewedDate: '2024-10-12',
    provenance: const Provenance(
      source: 'Lexicomp Drug Information 2024 / แนวทางการระงับปวดในผู้ป่วยมะเร็งและวิกฤต',
      reviewedBy: 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
      reviewedAt: '2024-10-12',
      sourceDetail: 'Morphine Monograph: Active Metabolites & Renal Clearance',
    ),
    monograph: const ClinicalMonograph(
      textbookName: 'Lexicomp Drug Information / รามาธิบดี',
      editionYear: '2024 Edition',
      sectionOrTable: 'Morphine: Acute Pain Management & Renal Impairment',
      dosingGuideline:
          '• ผู้ใหญ่ (Severe Acute Pain IV Push): เริ่มต้น 2–4 mg ฉีดช้าๆ ทุก 5–15 นาที PRN จนบรรเทาปวด หรือ 2–5 mg ทุก 3–4 ชม.\n'
          '• เด็ก (Pediatric): 0.05–0.1 mg/kg IV ทุก 2–4 ชม. PRN (ขนาดยาเริ่มต้นครั้งเดียวไม่เกิน 5 mg)',
      renalGuideline:
          '• CrCl 10–50 mL/min: ลดขนาดยาลงเหลือ 75% ของขนาดปกติ\n'
          '• CrCl < 10 mL/min / ไตวายระยะสุดท้าย (ESRD): ลดขนาดยาลงเหลือ 50% หรือพิจารณาเปลี่ยนไปใช้ยา Fentanyl แทน เนื่องจากสารเมแทบอไลต์ Morphine-6-glucuronide (M6G) จะคั่งค้างในร่างกาย เสี่ยงต่อการกดการหายใจและระบบประสาทรุนแรง',
      administrationGuideline:
          '• การฉีดทางหลอดเลือดดำ (IV Push): เจือจางด้วย NSS ให้ความเข้มข้น 1–2 mg/mL และฉีดช้าๆ อย่างน้อย 4–5 นาที การฉีดเร็วเสี่ยงต่อ Severe respiratory depression, Hypotension และ Chest wall rigidity',
      clinicalNotes:
          '• จัดเป็นยาเสพติดให้โทษประเภท 2 และยาเตือนภัยสูง (High-Alert Medication)\n'
          '• ต้องเฝ้าระวังอัตราการหายใจ (Respiratory Rate) และระดับความรู้สึกตัว (Sedation Score) อย่างต่อเนื่อง\n'
          '• ยาต้านพิษ (Antidote): Naloxone IV (0.04–0.4 mg ค่อยๆ Titrate ให้ผู้ป่วยฟื้นการหายใจโดยไม่กระตุ้น Acute withdrawal pain)',
      externalUrl: 'https://online.lexi.com',
    ),
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
        frequency: Frequency(isPrn: true, displayEn: 'q5-15min PRN', displayTh: 'ทุก 5-15 นาที เมื่อจำเป็น'),
        limits: const DoseLimit(
          softMaxSingleDose: 5.0,
        ),
        renalAdjustments: [
          const RenalAdjustment(crclMin: 10, crclMax: 50, action: RenalAction.adjust, adjustmentFactor: 0.75),
          const RenalAdjustment(crclMin: 0, crclMax: 10, action: RenalAction.adjust, adjustmentFactor: 0.5, notes: 'Reduce dose by 50%'),
        ],
      ),
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Severe Pain (Pediatric)',
        dosingType: DosingType.weightBased,
        dosePerKg: 0.05, // 0.05 - 0.1 mg/kg
        doseUnit: DoseUnit.mg,
        frequency: Frequency(minIntervalHours: 2, maxIntervalHours: 4, isPrn: true, displayEn: 'q2-4h PRN', displayTh: 'ทุก 2-4 ชม. เมื่อจำเป็น'),
        limits: const DoseLimit(
          maxSingleDose: 5.0, // Max initial single dose
        ),
        renalAdjustments: [
          const RenalAdjustment(crclMin: 10, crclMax: 50, action: RenalAction.adjust, adjustmentFactor: 0.75, notes: 'Reduce initial dose by 25% in CrCl 10-50 mL/min'),
          const RenalAdjustment(crclMin: 0, crclMax: 10, action: RenalAction.adjust, adjustmentFactor: 0.5, notes: 'Reduce dose by 50% in CrCl < 10 mL/min'),
        ],
      ),
    ],
  ),
  const Drug(
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
        frequency: Frequency(minIntervalHours: 0, isPrn: true, displayEn: 'q15-30min PRN', displayTh: 'ทุก 15-30 นาที เมื่อจำเป็น'),
        limits: DoseLimit(
          softMaxSingleDose: 100.0,
        ),
      ),
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Continuous Sedation/Analgesia (ICU)',
        dosingType: DosingType.titrated,
        continuousRateMin: 1.0,
        continuousRateMax: 2.0,
        continuousRateUnit: 'mcg/kg/hr',
        doseUnit: DoseUnit.mcg,
        frequency: Frequency.continuous,
        standardDilutionMgPerMl: 0.05, // 50 mcg/mL
        limits: DoseLimit(
          maxInfusionRate: 10.0,
          infusionRateUnit: 'mcg/kg/hr',
        ),
      ),
    ],
  ),
];

