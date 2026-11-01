import '../../core/models/models.dart';

final List<Drug> obstetric = [
  const Drug(
    id: 'oxytocin',
    genericName: 'Oxytocin',
    brandNames: ['Pitocin', 'Syntocinon'],
    nameTh: 'ออกซิโทซิน',
    category: DrugCategory.obstetric,
    pregnancyCategory:
        'X', // Used specifically for inducing labor, but FDA category X due to non-labor risks
    isHighAlert: true,
    sourceCitation: 'ACOG Practice Bulletins No. 107 & 183 / WHO Guidelines / US FDA Pitocin SPL',
    lastReviewedDate: '2024-10-12',
    provenance: Provenance(
      source: 'ACOG Practice Bulletins No. 107 & 183 / WHO Postpartum Haemorrhage Guidelines / US FDA Pitocin SPL',
      reviewedBy: 'Pending Clinical Pharmacist Sign-off',
      reviewedAt: '2024-10-12',
      sourceDetail: 'Labor Induction & Postpartum Hemorrhage Prevention Protocols §2.1-2.3',
    ),
    monograph: ClinicalMonograph(
      textbookName: 'ACOG Practice Bulletins (No. 107 & 183) / WHO Guidelines',
      editionYear: '2023 Guidelines / 2024 Update',
      sectionOrTable: 'Labor Induction & Postpartum Hemorrhage Prevention',
      dosingGuideline:
          '• การชักนำหรือเร่งการคลอด (Labor Induction / Augmentation):\n'
          '  - ขนาดยาเริ่มต้น (Low-dose protocol): 0.5–2.0 mU/min หยดเข้าหลอดเลือดดำต่อเนื่อง\n'
          '  - การปรับขนาดยา (Titration): เพิ่มอัตราการหยดทีละ 1–2 mU/min ทุก 15–30 นาที จนกระทั่งได้รูปแบบการหดรัดตัวของมดลูกที่เหมาะสม (หดรัดตัวนาน 40–60 วินาที ทุก 2–3 นาที)\n'
          '  - ขนาดยาสูงสุด: ปกติไม่เกิน 20.0 mU/min (หากใช้เกิน 20 mU/min ควรประเมินความปลอดภัยของทารกในครรภ์อย่างใกล้ชิด)\n'
          '• การป้องกันและรักษาการตกเลือดหลังคลอด (Postpartum Hemorrhage - PPH):\n'
          '  - การป้องกัน: 10 units ฉีดเข้ากล้ามเนื้อ (IM) ทันทีหลังทารกคลอด หรือ 10–20 units ในสารน้ำ 1,000 mL หยดทางหลอดเลือดดำในอัตรา 125–250 mL/hr\n'
          '  - การรักษา: 10–40 units ในสารน้ำ 1,000 mL หยดต่อเนื่องทางหลอดเลือดดำ (ปรับตามการหดรัดตัวของมดลูก)',
      renalGuideline:
          '• ถูกสลายตัวอย่างรวดเร็วในตับ ไต และพลาสมาโดยเอนไซม์ Oxytocinase\n'
          '• ไม่จำเป็นต้องปรับลดขนาดยาในผู้ป่วยที่มีภาวะไตบกพร่อง\n'
          '• ข้อควรระวัง: Oxytocin มีโครงสร้างคล้าย Vasopressin (ADH) หากหยดยาขนาดสูงเป็นเวลานานร่วมกับสารน้ำปราศจากอิเล็กโทรไลต์ อาจเกิดภาวะน้ำคั่งและโซเดียมในเลือดต่ำรุนแรง (Water intoxication & Severe hyponatremia)',
      administrationGuideline:
          '• การผสมสารละลายมาตรฐาน: Oxytocin 10 units ใน NSS หรือ Ringer\'s Lactate 1,000 mL (ความเข้มข้น 10 mU/mL หรือ 0.01 units/mL)\n'
          '• กฎเหล็กการบริหารยา (Critical Administration Safety Rule):\n'
          '  - ห้ามฉีดแบบ Undiluted Rapid IV Bolus เป็นอันขาด เนื่องจากทำให้เกิดความดันโลหิตลดฮวบเฉียบพลัน (Severe Hypotension), หัวใจเต้นเร็วผิดปกติ (Reflex Tachycardia) และ Cardiac Arrhythmias\n'
          '  - การชักนำการคลอดต้องใช้เครื่องควบคุมอัตราการให้ยา (Infusion Pump) เสมอ',
      clinicalNotes:
          '• จัดเป็นยาเตือนภัยสูงระดับวิกฤตทางสูติกรรม (High-Alert Obstetric Medication)\n'
          '• ข้อควรระวังสูงสุด: ต้องติดตามอัตราการเต้นของหัวใจทารกในครรภ์ (Fetal Heart Rate) และแรงหดรัดตัวของมดลูกอย่างต่อเนื่อง (Continuous CTG Monitoring)\n'
          '• หากพบภาวะมดลูกหดรัดตัวถี่เกินไป (Uterine Tachysystole: > 5 ครั้งใน 10 นาที) หรือทารกมีภาวะ Fetal Distress ต้องหยุดหยด Oxytocin ทันที และให้ออกซิเจนแก่มารดาเพื่อป้องกันมดลูกแตก (Uterine rupture)',
      externalUrl: 'https://dailymed.nlm.nih.gov/dailymed/search.cfm?labeltype=all&query=oxytocin',
    ),
    severeInteractions: ['Dinoprostone', 'Misoprostol'],
    specialNotes: 'Close fetal and uterine monitoring is required.',
    specialNotesTh:
        'ต้องเฝ้าระวังอัตราการเต้นของหัวใจทารกและการหดรัดตัวของมดลูกอย่างใกล้ชิด',
    ivDiluentCompatibility: IvDiluentCompatibility(
      compatibleDiluents: [IvDiluent.nss, IvDiluent.lrs, IvDiluent.d5w],
      preferredDiluent: IvDiluent.nss,
      stabilityNoteEn:
          'Prefer isotonic electrolyte fluid (NSS or LRS, 10 units in 1,000 mL = 10 mU/mL) over electrolyte-free D5W during prolonged or high-dose infusions to prevent ADH-like water intoxication and severe maternal/neonatal hyponatremia.',
      stabilityNoteTh:
          'แนะนำผสมในสารน้ำเกลือแร่ไอโซโทนิก (NSS หรือ LRS: 10 units ใน 1,000 mL = 10 mU/mL) แทน D5W เมื่อต้องหยดนานหรือขนาดสูง เพื่อป้องกันภาวะน้ำคั่งและโซเดียมต่ำรุนแรง (Water intoxication)',
      sourceCitation:
          'US FDA Pitocin (oxytocin) SPL / ACOG Practice Bulletins No. 107 & 183',
    ),
    regimens: [
      DosingRegimen(
        route: DoseRoute.iv,
        indication: 'Labor induction',
        dosingType: DosingType.titrated,
        doseUnit: DoseUnit.units,
        frequency: Frequency.continuous,
        continuousRateMin: 1, // 1-2 mU/min
        continuousRateMax: 20, // Max usually 20-40 mU/min
        continuousRateUnit: 'mU/min',
        rateUnit: RateUnit.mUMin,
        standardDilutionMgPerMl: 0.01, // e.g. 10 units in 1000ml = 10 mU/ml
        standardDilution: Concentration(0.01, ConcentrationUnit.unitsPerMl),
        population: PopulationCriteria(sex: Sex.female),
        verificationStatus: VerificationStatus.pendingReview,
      ),
      DosingRegimen(
        route: DoseRoute.im,
        indication: 'Postpartum hemorrhage prophylaxis',
        dosingType: DosingType.fixed,
        fixedDose: 10,
        doseUnit: DoseUnit.units, // Actually IU
        frequency: Frequency.once,
        limits: DoseLimit(maxDailyDose: 10),
        population: PopulationCriteria(sex: Sex.female),
        verificationStatus: VerificationStatus.pendingReview,
      ),
    ],
  ),
  const Drug(
    id: 'misoprostol',
    genericName: 'Misoprostol',
    brandNames: ['Cytotec'],
    nameTh: 'ไมโซพรอสทอล',
    category: DrugCategory.obstetric,
    pregnancyCategory: 'X',
    contraindications: ['Previous cesarean section (for induction)'],
    severeInteractions: ['Oxytocin (do not give simultaneously)'],
    regimens: [
      DosingRegimen(
        route: DoseRoute.po, // Or vaginal, sublingual
        indication: 'Postpartum hemorrhage',
        dosingType: DosingType.fixed,
        fixedDose: 600, // 600-800 mcg
        doseUnit: DoseUnit.mcg,
        frequency: Frequency.once,
        limits: DoseLimit(maxDailyDose: 800),
      ),
      DosingRegimen(
        route: DoseRoute.po, // or vaginal
        indication: 'Labor induction (Cervical ripening)',
        dosingType: DosingType.fixed,
        fixedDose: 25,
        doseUnit: DoseUnit.mcg,
        frequency: Frequency(minIntervalHours: 3, maxIntervalHours: 6, displayEn: 'q3-6h', displayTh: 'ทุก 3-6 ชม.'),
        limits: DoseLimit(maxDailyDose: 100), // Max total dose usually limited
      ),
    ],
  ),
  const Drug(
    id: 'methylergometrine',
    genericName: 'Methylergonovine',
    brandNames: ['Methergine'],
    nameTh: 'เมทิลเออร์โกเมทริน',
    category: DrugCategory.obstetric,
    pregnancyCategory: 'C',
    contraindications: ['Hypertension', 'Preeclampsia'],
    severeInteractions: ['Macrolides (Clarithromycin)', 'Triptans'],
    regimens: [
      DosingRegimen(
        route: DoseRoute.im,
        indication: 'Postpartum hemorrhage',
        dosingType: DosingType.fixed,
        fixedDose: 0.2,
        doseUnit: DoseUnit.mg,
        frequency: Frequency(
          minIntervalHours: 2,
          maxIntervalHours: 4,
          isPrn: true,
          displayEn: 'q2-4h PRN',
          displayTh: 'ทุก 2-4 ชม. เมื่อจำเป็น',
        ),
        limits: DoseLimit(maxDailyDose: 1), // Max 5 doses
      ),
    ],
  ),
  const Drug(
    id: 'terbutaline',
    genericName: 'Terbutaline',
    brandNames: ['Bricanyl'],
    nameTh: 'เทอร์บูทาลีน',
    category:
        DrugCategory.obstetric, // Also respiratory but often used as tocolytic
    pregnancyCategory: 'C',
    severeInteractions: ['Beta-blockers', 'MAOIs'],
    specialNotes:
        'Used off-label as a tocolytic (to stop preterm labor). Not for prolonged use > 48h.',
    specialNotesTh: 'ระวังใจสั่น หัวใจเต้นเร็ว (Tachycardia)',
    regimens: [
      DosingRegimen(
        route: DoseRoute.sc,
        indication: 'Preterm labor (Tocolysis)',
        dosingType: DosingType.fixed,
        fixedDose: 0.25,
        doseUnit: DoseUnit.mg,
        frequency: Frequency(minIntervalHours: 0, isPrn: true, displayEn: 'q20-30min PRN', displayTh: 'ทุก 20-30 นาที เมื่อจำเป็น'),
        limits: DoseLimit(
            maxDailyDose: 1), // Limited doses due to maternal cardiac risks
      ),
    ],
  ),
];
