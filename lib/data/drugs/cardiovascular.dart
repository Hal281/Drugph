// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import '../../core/models/models.dart';

final List<Drug> cardiovascular = [
  Drug(
    id: 'norepinephrine',
    genericName: 'Norepinephrine',
    brandNames: ['Levophed'],
    nameTh: 'นอร์เอพิเนฟริน',
    category: DrugCategory.vasopressor,
    isHighAlert: true,
    sourceCitation: 'Surviving Sepsis Campaign Guidelines 2021 / คู่มือยาฉีดความเสี่ยงสูง รพ.รามาธิบดี / US FDA Levophed SPL',
    lastReviewedDate: '2024-10-12',
    provenance: const Provenance(
      source: 'Surviving Sepsis Campaign 2021 / Ramathibodi High-Alert IV Infusion Guide / US FDA Levophed SPL',
      reviewedBy: 'Pending Clinical Pharmacist Sign-off',
      reviewedAt: '2024-10-12',
      sourceDetail: 'Vasoactive Agents Protocol & Extravasation Antidote Guidelines',
    ),
    monograph: const ClinicalMonograph(
      textbookName: 'Surviving Sepsis Campaign / รามาธิบดี',
      editionYear: '2021 Guidelines / 2024 Manual',
      sectionOrTable: 'Norepinephrine Continuous Infusion & Titration Protocol',
      dosingGuideline:
          '• อัตราการให้ยาต่อเนื่อง (Titrated IV Infusion): เริ่มต้น 0.01–0.1 mcg/kg/min ค่อยๆ ปรับ Titrate ทุก 2–5 นาที\n'
          '• เป้าหมายทางคลินิก: Mean Arterial Pressure (MAP) >= 65 mmHg ในภาวะ Septic Shock\n'
          '• ขนาดยาการรักษาสูงสุด: ไม่เกิน 3.0 mcg/kg/min (หากเกิน 0.25 mcg/kg/min ควรพิจารณาให้ Vasopressin ร่วมด้วย)',
      renalGuideline:
          '• ไม่จำเป็นต้องปรับลดขนาดยาตามค่าไต (No renal adjustment needed)\n'
          '• การฟื้นฟูความดันเลือด (MAP >= 65 mmHg) ช่วยเพิ่ม Renal perfusion pressure และป้องกัน Ischemic AKI',
      administrationGuideline:
          '• การผสมยามาตรฐาน: 4 mg ใน D5W หรือ D5NSS 250 mL (ความเข้มข้น 16 mcg/mL); สำหรับสูตร Double strength: 8 mg ใน 250 mL (32 mcg/mL); Quad strength: 16 mg ใน 250 mL (64 mcg/mL)\n'
          '• เส้นทางการให้ยา: ต้องให้ผ่าน Central Line เสมอ เพื่อป้องกันยาซึมออกนอกหลอดเลือด (Extravasation)\n'
          '• หากเกิด Extravasation: หยุดยาทันทีและฉีด Antidote คือ Phentolamine 5–10 mg ละลายใน NSS 10–15 mL ฉีดกระจายรอบบริเวณที่รั่วซึม',
      clinicalNotes:
          '• จัดเป็นยาเตือนภัยสูงระดับวิกฤต (High-Alert Vasopressor)\n'
          '• ต้องติดตามความดันโลหิตแบบ Real-time (Arterial line) และอัตราการเต้นของหัวใจ\n'
          '• ระวังภาวะ Peripheral ischemia / Gangrene บริเวณปลายนิ้วมือนิ้วเท้าหากใช้ยาขนาดสูงเป็นเวลานาน',
      externalUrl: 'https://www.sccm.org/SurvivingSepsisCampaign',
    ),
    specialNotes:
        'Administer via central line to prevent extravasation necrosis.',
    specialNotesTh:
        'ควรให้ทางหลอดเลือดดำใหญ่เพื่อป้องกันเนื้อเยื่อตายจากการรั่วซึม',
    ivDiluentCompatibility: const IvDiluentCompatibility(
      compatibleDiluents: [IvDiluent.d5w, IvDiluent.d5nss],
      preferredDiluent: IvDiluent.d5w,
      incompatibleDiluents: [IvDiluent.nss],
      incompatibilityReasonEn:
          'OXIDATION LOSS OF POTENCY: Per US FDA Levophed SPL §2.2, administration in saline solution alone (NSS) is NOT recommended because dextrose protects norepinephrine against significant loss of potency due to oxidation.',
      incompatibilityReasonTh:
          'ไม่แนะนำให้ผสมใน NSS เดี่ยวๆ: ตามฉลากยา US FDA Levophed §2.2 ยาจะเสื่อมฤทธิ์จากปฏิกิริยาออกซิเดชัน ต้องผสมในสารละลายที่มีน้ำตาล Dextrose (D5W หรือ D5NSS) เพื่อคงความแรงของยา',
      stabilityNoteEn:
          'Standard: 4 mg in 250 mL D5W or D5NSS (16 mcg/mL). Discard if solution turns pinkish, dark yellow, or brown, or contains precipitate.',
      stabilityNoteTh:
          'ผสมมาตรฐาน 4 mg ใน D5W หรือ D5NSS 250 mL (16 mcg/mL) ห้ามใช้หากสารละลายเปลี่ยนเป็นสีชมพู เหลืองเข้ม น้ำตาล หรือมีตะกอน',
      sourceCitation:
          'US FDA Levophed (norepinephrine) SPL §2.2 / คู่มือยาฉีดความเสี่ยงสูง รพ.รามาธิบดี 2024',
    ),
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Septic Shock / Hypotension',
        dosingType: DosingType.titrated,
        continuousRateMin: 0.01,
        continuousRateMax: 3.0,
        continuousRateUnit: 'mcg/kg/min',
        rateUnit: RateUnit.mcgKgMin,
        verificationStatus: VerificationStatus.pendingReview,
        doseUnit: DoseUnit.mcg,
        frequency: Frequency.continuous,
        standardDilutionMgPerMl:
            0.016, // 4mg in 250mL = 0.016 mg/mL (or 16 mcg/mL)
        limits: DoseLimit(
          maxInfusionRate: 3.0,
          infusionRateUnit: 'mcg/kg/min',
        ),
      ),
    ],
  ),
  const Drug(
    id: 'dopamine',
    genericName: 'Dopamine',
    brandNames: ['Intropin'],
    nameTh: 'โดปามีน',
    category: DrugCategory.vasopressor,
    isHighAlert: true,
    sourceCitation: 'Ramathibodi High-Alert IV Infusion Guide 2024 / AHA Shock Guidelines / US FDA Intropin SPL',
    lastReviewedDate: '2024-10-12',
    provenance: Provenance(
      source: 'Ramathibodi High-Alert IV Infusion Guide 2024 / AHA Shock Guidelines / US FDA Intropin SPL',
      reviewedBy: 'Pending Clinical Pharmacist Sign-off',
      reviewedAt: '2024-10-12',
      sourceDetail: 'Inotropic & Vasopressor Titration Protocol §2.1-2.3',
    ),
    monograph: ClinicalMonograph(
      textbookName: 'Ramathibodi High-Alert IV Infusion Guide / AHA Shock Guidelines',
      editionYear: '2024 Manual',
      sectionOrTable: 'Inotropic & Vasopressor Titration Protocol §2.1-2.3',
      dosingGuideline:
          '• อัตราการให้ยาต่อเนื่อง (Continuous IV Infusion): 2–20 mcg/kg/min โดยปรับ Titrate ตามการตอบสนองของระบบไหลเวียนโลหิต\n'
          '• การออกฤทธิ์ตามระดับขนาดยา (Dose-dependent Receptor Specificity):\n'
          '  - Low dose (1–5 mcg/kg/min): กระตุ้น Dopaminergic (D1) receptors ทำให้หลอดเลือดไตและลำไส้ขยายตัว (หมายเหตุ: ปัจจุบัน KDIGO ไม่แนะนำให้ใช้ "Renal dose dopamine" เพื่อป้องกันหรือรักษา AKI อีกต่อไป)\n'
          '  - Medium dose (5–10 mcg/kg/min): กระตุ้น Beta-1 adrenergic receptors เพิ่มแรงบีบตัวและอัตราการเต้นของหัวใจ (Positive Inotropic & Chronotropic)\n'
          '  - High dose (10–20 mcg/kg/min): กระตุ้น Alpha-1 adrenergic receptors เด่นชัด ทำให้หลอดเลือดส่วนปลายหดตัวอย่างรุนแรง เพิ่มความดันโลหิต (Systemic Vasoconstriction)',
      renalGuideline:
          '• ถูกเปลี่ยนแปลงอย่างรวดเร็วในตับ ไต และพลาสมาโดยเอนไซม์ MAO และ COMT\n'
          '• ไม่จำเป็นต้องปรับลดขนาดยาในผู้ป่วยไตเสื่อม (No renal dose adjustment needed)\n'
          '• การฟื้นฟูความดันเลือดช่วยเพิ่ม Renal perfusion pressure',
      administrationGuideline:
          '• สารละลายและการผสมยามาตรฐาน: 400 mg ใน D5W หรือ NSS 250 mL (ความเข้มข้น 1.6 mg/mL หรือ 1,600 mcg/mL)\n'
          '• เส้นทางการให้ยา: ควรให้ผ่านหลอดเลือดดำใหญ่ (Central Venous Catheter) โดยใช้เครื่องควบคุมอัตราการให้ยา (Infusion Pump) เสมอ\n'
          '• การจัดการยาซึมออกนอกเส้นเลือด (Extravasation): หากเกิดรั่วซึม หยุดยาทันทีและฉีด Antidote คือ Phentolamine 5–10 mg ละลายใน NSS 10–15 mL ฉีดแทรกกระจายรอบบริเวณเนื้อเยื่อที่ได้รับผลกระทบเพื่อป้องกันเนื้อเยื่อขาดเลือดและเน่าตาย (Ischemic necrosis)',
      clinicalNotes:
          '• จัดเป็นยาเตือนภัยสูงระดับวิกฤต (High-Alert Inotrope/Vasopressor)\n'
          '• ผลข้างเคียงสำคัญ: หัวใจเต้นเร็ว (Tachycardia), ภาวะหัวใจเต้นผิดจังหวะ (Ventricular Arrhythmias), กล้ามเนื้อหัวใจขาดเลือดจาก Oxygen demand ที่เพิ่มสูงขึ้น\n'
          '• ต้องแก้ไขภาวะขาดสารน้ำ (Hypovolemia) ให้เพียงพอก่อนเริ่มใช้ยาเสมอ',
      externalUrl: 'https://dailymed.nlm.nih.gov/dailymed/search.cfm?labeltype=all&query=dopamine',
    ),
    ivDiluentCompatibility: IvDiluentCompatibility(
      compatibleDiluents: [
        IvDiluent.d5w,
        IvDiluent.nss,
        IvDiluent.d5nss,
        IvDiluent.lrs,
      ],
      preferredDiluent: IvDiluent.d5w,
      stabilityNoteEn:
          'Standard: 400 mg in 250 mL D5W or NSS (1.6 mg/mL = 1,600 mcg/mL). NEVER mix with sodium bicarbonate or alkaline IV solutions (inactivates dopamine).',
      stabilityNoteTh:
          'ผสมมาตรฐาน 400 mg ใน D5W หรือ NSS 250 mL (1.6 mg/mL) ห้ามผสมร่วมกับ Sodium Bicarbonate หรือสารละลายด่างเด็ดขาด (ทำให้ยาเสื่อมฤทธิ์)',
      sourceCitation:
          'US FDA Intropin (dopamine) SPL / Ramathibodi High-Alert IV Infusion Guide 2024',
    ),
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Hemodynamic Support',
        dosingType: DosingType.titrated,
        continuousRateMin: 2.0,
        continuousRateMax: 20.0,
        continuousRateUnit: 'mcg/kg/min',
        rateUnit: RateUnit.mcgKgMin,
        verificationStatus: VerificationStatus.pendingReview,
        doseUnit: DoseUnit.mcg,
        frequency: Frequency.continuous,
        standardDilutionMgPerMl:
            1.6, // 400mg in 250mL = 1.6 mg/mL (1600 mcg/mL)
        limits: DoseLimit(
          maxInfusionRate: 20.0,
          infusionRateUnit: 'mcg/kg/min',
        ),
      ),
    ],
  ),
  const Drug(
    id: 'amiodarone',
    genericName: 'Amiodarone',
    brandNames: ['Cordarone'],
    nameTh: 'อะมิโอดาโรน',
    category: DrugCategory.cardiovascular,
    isHighAlert: true,
    sourceCitation: 'AHA ACLS Guidelines 2020 / คู่มือยาฉีดความเสี่ยงสูง รามาธิบดี / US FDA Cordarone SPL',
    lastReviewedDate: '2024-10-12',
    provenance: Provenance(
      source: 'AHA ACLS Guidelines 2020 / Ramathibodi High-Alert IV Infusion Guide / US FDA Cordarone SPL',
      reviewedBy: 'Pending Clinical Pharmacist Sign-off',
      reviewedAt: '2024-10-12',
      sourceDetail: 'Ventricular Arrhythmias & Cardiac Arrest Infusion Protocol §2.1-2.3',
    ),
    monograph: ClinicalMonograph(
      textbookName: 'AHA ACLS Guidelines / คู่มือยาฉีดความเสี่ยงสูง รามาธิบดี',
      editionYear: '2020 Guidelines / 2024 Manual',
      sectionOrTable: 'Ventricular Arrhythmias & Cardiac Arrest Infusion Protocol',
      dosingGuideline:
          '• ภาวะหัวใจหยุดเต้นจาก Pulseless VT / VF (ACLS Cardiac Arrest):\n'
          '  - เข็มแรก: 300 mg IV/IO push (เจือจางใน D5W 20–30 mL)\n'
          '  - เข็มที่สอง: 150 mg IV/IO push หากยังมี VT/VF คงอยู่\n'
          '• ภาวะ Stable Wide-Complex Tachycardia / Recurrent VT:\n'
          '  - Rapid Loading Infusion: 150 mg ใน D5W 100 mL หยดเข้าหลอดเลือดดำช้าๆ นาน 10 นาที (อัตรา 15 mg/min)\n'
          '  - Slow Loading Infusion: 360 mg หยดเข้าหลอดเลือดดำใน 6 ชั่วโมง (1 mg/min)\n'
          '  - Maintenance Infusion: 540 mg หยดเข้าหลอดเลือดดำใน 18 ชั่วโมงถัดมา (0.5 mg/min) ขนาดยารวมสูงสุดไม่เกิน 2,200 mg ใน 24 ชั่วโมง',
      renalGuideline:
          '• ขับถ่ายผ่านตับและถุงน้ำดีเป็นหลัก (Biliary & Fecal excretion)\n'
          '• ไม่จำเป็นต้องปรับลดขนาดยาในผู้ป่วยที่มีภาวะไตบกพร่องหรือผู้ป่วยที่ฟอกเลือด (No renal dose adjustment in CKD or Hemodialysis)',
      administrationGuideline:
          '• ข้อกำหนดความเข้ากันได้ของสารน้ำ (Compatibility Constraint):\n'
          '  - ต้องเจือจางใน D5W เท่านั้น (Incompatible with NSS: เกิดการตกตะกอนเมื่อเวลาผ่านไป)\n'
          '  - ความเข้มข้นของการหยดต่อเนื่อง > 2 mg/mL ต้องให้ผ่านสายสวนหลอดเลือดดำส่วนกลาง (Central Venous Catheter) เพื่อป้องกัน Severe Chemical Phlebitis\n'
          '  - การหยดยานานกว่า 2 ชั่วโมง ต้องใช้ภาชนะชนิด Polyolefin หรือ Glass (หลีกเลี่ยง PVC bag) และใช้ In-line filter ขนาด 0.22 micron',
      clinicalNotes:
          '• จัดเป็นยาเตือนภัยสูงระดับวิกฤต (High-Alert Antiarrhythmic)\n'
          '• Boxed Warning: เสี่ยงต่อภาวะพิษต่อปอด (Pulmonary Toxicity/Fibrosis), พิษต่อตับ (Hepatotoxicity) และการกระตุ้นหัวใจเต้นผิดจังหวะ (Proarrhythmic effects)\n'
          '• อาการไม่พึงประสงค์เฉียบพลัน: ความดันโลหิตต่ำรุนแรง (Hypotension) และหัวใจเต้นช้า (Bradycardia) มักเกิดจากการหยดยาเร็วเกินไปอันเป็นผลจากสารทำละลาย Polysorbate 80',
      externalUrl: 'https://dailymed.nlm.nih.gov/dailymed/search.cfm?labeltype=all&query=amiodarone',
    ),
    ivDiluentCompatibility: IvDiluentCompatibility(
      compatibleDiluents: [IvDiluent.d5w],
      preferredDiluent: IvDiluent.d5w,
      incompatibleDiluents: [IvDiluent.nss, IvDiluent.lrs],
      incompatibilityReasonEn:
          'PRECIPITATION / INCOMPATIBILITY HAZARD: Amiodarone IV continuous infusion MUST be diluted in D5W only. Dilution in NSS or LRS causes physical instability and precipitation over time.',
      incompatibilityReasonTh:
          'ห้ามผสมหยดต่อเนื่องใน NSS หรือ LRS: Amiodarone IV ต้องเจือจางใน D5W เท่านั้น การผสมใน NSS เสี่ยงต่อการตกตะกอนเมื่อเวลาผ่านไป',
      stabilityNoteEn:
          'Use non-PVC (polyolefin or glass) container for infusions > 2 hours (amiodarone adsorbs to PVC and leaches DEHP) with a 0.22-micron inline filter. Concentrations > 2 mg/mL require a central venous line.',
      stabilityNoteTh:
          'การหยดนานเกิน 2 ชม. ต้องใช้ขวดแก้วหรือถุง Non-PVC (Polyolefin) ร่วมกับ 0.22-micron inline filter ความเข้มข้น > 2 mg/mL ต้องให้ทาง Central Line',
      sourceCitation:
          'US FDA Cordarone IV SPL §2.2 / Ramathibodi High-Alert IV Infusion Guide 2024',
    ),
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Ventricular Arrhythmias (Stable)',
        dosingType: DosingType.fixed,
        fixedDose: 150.0, // 150 mg over 10 mins
        doseUnit: DoseUnit.mg,
        frequency: Frequency.once,
        infusionTimeMinutes: 10.0,
        verificationStatus: VerificationStatus.pendingReview,
      ),
    ],
  ),
  const Drug(
    id: 'amlodipine',
    genericName: 'Amlodipine',
    brandNames: ['Norvasc', 'Amvaz'],
    nameTh: 'แอมโลดิปีน',
    category: DrugCategory.cardiovascular,
    requiresHepaticCaution: true,
    allergyClass: 'Calcium Channel Blocker (CCB)',
    severeInteractions: [
      'Simvastatin (Max simvastatin dose 20 mg/day)',
      'CYP3A4 Inhibitors (e.g. Clarithromycin, Itraconazole - increases Amlodipine level)'
    ],
    specialNotes:
        'Common side effect is peripheral edema. Start at 2.5 mg in elderly or hepatic impairment.',
    specialNotesTh:
        'ผลข้างเคียงที่พบบ่อยคือขาบวม เริ่มยา 2.5 mg ในผู้สูงอายุหรือโรคตับ',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Hypertension (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 5.0, // 5-10 mg
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q24h,
        limits: DoseLimit(
          maxSingleDose: 10.0,
          maxDailyDose: 10.0,
        ),
      ),
    ],
  ),
  const Drug(
    id: 'enalapril',
    genericName: 'Enalapril',
    brandNames: ['Renitec', 'Enaril'],
    nameTh: 'อีนาลาพริล',
    category: DrugCategory.cardiovascular,
    drugClass: DrugClass.aceInhibitor,
    requiresRenalAdjustment: true,
    allergyClass: 'ACE Inhibitor',
    severeInteractions: [
      'Potassium-sparing diuretics / Potassium supplements (Hyperkalemia)',
      'NSAIDs (May worsen renal function)',
      'Lithium (Increases lithium toxicity)'
    ],
    contraindications: [
      'Pregnancy (Teratogenic)',
      'History of Angioedema',
      'Bilateral renal artery stenosis'
    ],
    specialNotes: 'Monitor potassium and creatinine. May cause dry cough.',
    specialNotesTh: 'ระวังโพแทสเซียมในเลือดสูง และค่าไตแย่ลง อาจทำให้ไอแห้งๆ',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Hypertension / Heart Failure (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 5.0, // 5-20 mg
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q24h,
        limits: DoseLimit(
          maxDailyDose: 40.0,
        ),
        renalAdjustments: [
          RenalAdjustment(
              crclMin: 0,
              crclMax: 30,
              adjustmentFactor: 0.5,
              notes: 'Start at 2.5 mg/day'),
        ],
      ),
    ],
  ),
  const Drug(
    id: 'furosemide',
    genericName: 'Furosemide',
    brandNames: ['Lasix'],
    nameTh: 'ฟูโรซีไมด์',
    category: DrugCategory.cardiovascular, // or diuretic
    drugClass: DrugClass.loopDiuretic,
    allergyClass: 'Sulfonamide (Sulfa)',
    severeInteractions: [
      'Aminoglycosides (Increased risk of ototoxicity)',
      'Digoxin (Toxicity if hypokalemic)'
    ],
    specialNotes:
        'Monitor potassium (risk of hypokalemia). IV push slowly (max 20mg/min) to prevent ototoxicity.',
    specialNotesTh:
        'ระวังโพแทสเซียมต่ำ (Hypokalemia) การฉีด IV ควรดันยาช้าๆ (ไม่เกิน 20mg/min) เพื่อป้องกันหูหนวก',
    ivDiluentCompatibility: IvDiluentCompatibility(
      compatibleDiluents: [IvDiluent.nss, IvDiluent.lrs],
      preferredDiluent: IvDiluent.nss,
      incompatibleDiluents: [IvDiluent.d5w],
      incompatibilityReasonEn:
          'ACIDIC PRECIPITATION HAZARD: Furosemide is an alkaline solution (pH ~9) and precipitates in acidic dextrose solutions (pH < 5.5) such as unbuffered D5W. Prefer 0.9% NaCl (NSS).',
      incompatibilityReasonTh:
          'เสี่ยงตกตะกอนใน D5W: Furosemide เป็นสารละลายด่าง (pH ~9) จะตกตะกอนเมื่อผสมในสารละลายที่เป็นกรด (pH < 5.5) เช่น D5W ที่ไม่ผ่านการบัฟเฟอร์ แนะนำผสมใน NSS เป็นหลัก',
      stabilityNoteEn:
          'Protect from light; do not use if solution is yellow/discolored. Max IV push/infusion rate <= 20 mg/min (<= 4 mg/min for high doses) to prevent ototoxicity.',
      stabilityNoteTh:
          'เก็บให้พ้นแสง ห้ามใช้หากยาเปลี่ยนเป็นสีเหลือง อัตราการฉีดไม่เกิน 20 mg/min (ขนาดยาสูง <= 4 mg/min) เพื่อป้องกันพิษต่อหู',
      sourceCitation:
          'US FDA Lasix Injection SPL / Trissel\'s Handbook on Injectable Drugs',
    ),
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Edema / Heart Failure (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 40.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q24h,
        limits: DoseLimit(
          maxSingleDose: 160.0,
          maxDailyDose: 600.0, // Severe edema/renal failure
        ),
      ),
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Acute Pulmonary Edema (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 40.0, // 40-80 mg
        doseUnit: DoseUnit.mg,
        frequency: Frequency.stat,
        limits: DoseLimit(
          maxSingleDose: 200.0,
        ),
      ),
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Edema (Pediatric)',
        dosingType: DosingType.weightBased,
        dosePerKg: 1.0, // 1-2 mg/kg/dose
        doseUnit: DoseUnit.mg,
        frequency: Frequency(minIntervalHours: 12, maxIntervalHours: 24, displayEn: 'q12-24h', displayTh: 'ทุก 12-24 ชม.'),
        limits: DoseLimit(
          maxDosePerKgPerDay: 6.0,
          maxSingleDose: 40.0,
        ),
      ),
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Edema (Pediatric IV)',
        dosingType: DosingType.weightBased,
        dosePerKg: 1.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency(minIntervalHours: 12, maxIntervalHours: 24, displayEn: 'q12-24h', displayTh: 'ทุก 12-24 ชม.'),
        limits: DoseLimit(
          maxDosePerKgPerDay: 6.0,
        ),
      ),
    ],
  ),
  const Drug(
    id: 'adenosine',
    genericName: 'Adenosine',
    brandNames: ['Adenocor'],
    nameTh: 'อะดีโนซีน',
    category: DrugCategory.cardiovascular, // Antiarrhythmic
    isHighAlert: true,
    severeInteractions: [
      'Dipyridamole (potentiates effect - reduce adenosine dose)',
      'Theophylline / Caffeine (antagonizes effect - may need larger dose)'
    ],
    contraindications: [
      'Second or third-degree AV block (without pacemaker)',
      'Sick sinus syndrome (without pacemaker)',
      'Asthma (may cause bronchospasm)'
    ],
    specialNotes:
        'Must be given as a RAPID IV push (1-2 seconds) followed immediately by a rapid normal saline flush.',
    specialNotesTh:
        'ต้องฉีด IV Push เร็วมากๆ (1-2 วินาที) แล้วตามด้วย Normal Saline ทันที ห้ามใช้ในคนไข้หอบหืด',
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'SVT (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 6.0, // First dose 6mg
        doseUnit: DoseUnit.mg,
        frequency: Frequency.stat,
        limits: DoseLimit(
          maxSingleDose: 12.0,
        ),
      ),
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'SVT (Pediatric)',
        dosingType: DosingType.weightBased,
        dosePerKg: 0.1, // 0.1 mg/kg
        doseUnit: DoseUnit.mg,
        frequency: Frequency.stat,
        limits: DoseLimit(
          maxSingleDose: 6.0, // Max first dose 6mg
        ),
      ),
    ],
  ),
  const Drug(
    id: 'digoxin',
    genericName: 'Digoxin',
    brandNames: ['Lanoxin'],
    nameTh: 'ไดจอกซิน',
    category: DrugCategory.cardiovascular,
    requiresRenalAdjustment: true,
    isHighAlert: true,
    requiresTDM: true,
    severeInteractions: [
      'Amiodarone (increases digoxin levels by 50% - reduce digoxin dose)',
      'Furosemide / Diuretics (hypokalemia increases toxicity risk)'
    ],
    contraindications: ['Ventricular fibrillation'],
    specialNotes:
        'Narrow therapeutic index. Monitor potassium and kidney function closely.',
    specialNotesTh:
        'ยามีช่วงการรักษากว้างแคบ (Narrow therapeutic index) ต้องระวังโพแทสเซียมต่ำจะทำให้เกิดพิษง่าย',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Heart Failure / AFib (Adult Maintenance)',
        dosingType: DosingType.fixed,
        fixedDose: 0.25, // 0.125 - 0.25 mg
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q24h,
        limits: DoseLimit(
          maxDailyDose: 0.5,
        ),
        renalAdjustments: [
          RenalAdjustment(
              crclMin: 10,
              crclMax: 50,
              adjustmentFactor: 0.5,
              notes: 'Or administer q48h'),
          RenalAdjustment(
              crclMin: 0,
              crclMax: 10,
              adjustmentFactor: 0.25,
              notes: 'Administer q48h-q72h'),
        ],
      ),
    ],
  ),
  const Drug(
    id: 'nicardipine',
    genericName: 'Nicardipine',
    brandNames: ['Cardene'],
    nameTh: 'นิคาร์ดิปีน',
    category: DrugCategory.cardiovascular,
    requiresHepaticCaution: true,
    isHighAlert: true,
    sourceCitation: '2020 ACC/AHA Hypertensive Emergency Guidelines / คู่มือยาฉีดรามาธิบดี / US FDA Cardene IV SPL',
    lastReviewedDate: '2024-10-12',
    provenance: Provenance(
      source: '2020 ACC/AHA Hypertensive Emergency Guidelines / Ramathibodi IV Manual / US FDA Cardene SPL',
      reviewedBy: 'Pending Clinical Pharmacist Sign-off',
      reviewedAt: '2024-10-12',
      sourceDetail: 'IV Antihypertensive Titration Protocol §2.1-2.4',
    ),
    monograph: ClinicalMonograph(
      textbookName: 'ACC/AHA Hypertensive Emergency Guidelines / คู่มือยาฉีดรามาธิบดี',
      editionYear: '2020 Guidelines / 2024 Manual',
      sectionOrTable: 'IV Antihypertensive Titration Protocol §2.1-2.4',
      dosingGuideline:
          '• อัตราการให้ยาต่อเนื่องในภาวะความดันโลหิตสูงวิกฤต (Hypertensive Emergency):\n'
          '  - ขนาดยาเริ่มต้น: 5.0 mg/hr หยดเข้าหลอดเลือดดำต่อเนื่อง\n'
          '  - การปรับขนาดยา (Titration): เพิ่มอัตราการหยด 2.5 mg/hr ทุก 5–15 นาที จนกระทั่งถึงระดับความดันเป้าหมาย (ขนาดยาสูงสุด 15.0 mg/hr)\n'
          '  - เป้าหมายการลดความดันโลหิต: ลด Mean Arterial Pressure (MAP) ไม่เกิน 20–25% ในชั่วโมงแรกเพื่อป้องกัน Cerebral/Coronary Hypoperfusion\n'
          '  - ขนาดยาคงที่ (Maintenance): เมื่อความดันโลหิตเข้าสู่เกณฑ์ควบคุมได้แล้ว แนะนำปรับลดอัตราการหยดลงเหลือ 3.0 mg/hr',
      renalGuideline:
          '• กำจัดยาผ่านตับเป็นหลัก (Hepatic CYP3A4 metabolism)\n'
          '• ไม่จำเป็นต้องปรับลดขนาดยาในผู้ป่วยไตบกพร่อง (No renal dose adjustment needed)\n'
          '• เป็นยาทางเลือกที่ปลอดภัยในภาวะความดันโลหิตสูงร่วมกับภาวะไตเสื่อมเฉียบพลัน/เรื้อรัง',
      administrationGuideline:
          '• การผสมยามาตรฐาน: Nicardipine 25 mg เจือจางใน D5W หรือ NSS 240 mL (ปริมาตรรวม 250 mL ได้ความเข้มข้น 0.1 mg/mL)\n'
          '• เส้นทางการให้ยา: ให้ผ่าน Infusion Pump เสมอ ควรให้ผ่านหลอดเลือดดำส่วนกลาง (Central Line) หากให้ทาง Peripheral Line ต้องเปลี่ยนตำแหน่งแทงสายน้ำเกลือทุก 12 ชม. เพื่อป้องกันหลอดเลือดดำอักเสบ (Thrombophlebitis)',
      clinicalNotes:
          '• จัดเป็นยาเตือนภัยสูง (High-Alert Antihypertensive)\n'
          '• ข้อห้ามใช้เด็ดขาด: ห้ามใช้ในผู้ป่วย Advanced Aortic Stenosis (เนื่องจากแรงบีบหัวใจลดลงอาจเกิด Severe Hypotension)\n'
          '• ต้องตรวจวัดและติดตามความดันโลหิตและอัตราการเต้นของหัวใจอย่างต่อเนื่อง (Continuous Monitoring)',
      externalUrl: 'https://dailymed.nlm.nih.gov/dailymed/search.cfm?labeltype=all&query=nicardipine',
    ),
    allergyClass: 'Calcium Channel Blocker (CCB)',
    severeInteractions: [
      'Beta-blockers (May cause severe hypotension/heart failure)',
      'CYP3A4 Inhibitors (Increase nicardipine levels)'
    ],
    contraindications: ['Advanced aortic stenosis'],
    specialNotes:
        'Frequent blood pressure monitoring required. Change infusion site q12h to prevent phlebitis.',
    specialNotesTh:
        'ต้องวัดความดันอย่างต่อเนื่อง (Continuous BP) และเปลี่ยนตำแหน่งแทงสายน้ำเกลือทุก 12 ชม. เพื่อลดหลอดเลือดอักเสบ',
    ivDiluentCompatibility: IvDiluentCompatibility(
      compatibleDiluents: [
        IvDiluent.nss,
        IvDiluent.d5w,
        IvDiluent.d5nss,
        IvDiluent.halfNss,
      ],
      preferredDiluent: IvDiluent.nss,
      incompatibleDiluents: [IvDiluent.lrs],
      incompatibilityReasonEn:
          'INCOMPATIBLE WITH LRS: Per US FDA Cardene IV SPL §2.3, Nicardipine is NOT compatible with Lactated Ringer\'s (LRS) or Sodium Bicarbonate (risk of alkaline precipitation).',
      incompatibilityReasonTh:
          'ห้ามผสมใน LRS เด็ดขาด: ตามฉลากยา US FDA Cardene IV §2.3 ยาไม่เข้ากันกับ Lactated Ringer\'s (LRS) และ Sodium Bicarbonate เนื่องจากเสี่ยงตกตะกอน',
      stabilityNoteEn:
          'Standard dilution: 25 mg diluted to 250 mL total volume in NSS or D5W (0.1 mg/mL). Stable 24 hours at room temperature; rotate peripheral IV site every 12 hours.',
      stabilityNoteTh:
          'ผสมมาตรฐาน 25 mg เจือจางให้ได้ปริมาตรรวม 250 mL ใน NSS หรือ D5W (0.1 mg/mL) คงตัวที่อุณหภูมิห้อง 24 ชม. เปลี่ยนตำแหน่ง Peripheral line ทุก 12 ชม.',
      sourceCitation:
          'US FDA Cardene IV (nicardipine) SPL §2.3 / คู่มือยาฉีดรามาธิบดี 2024',
    ),
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Hypertensive Emergency (Adult)',
        dosingType: DosingType.titrated,
        continuousRateMin: 5.0, // 5 mg/hr
        continuousRateMax: 15.0, // Max 15 mg/hr
        continuousRateUnit: 'mg/hr',
        rateUnit: RateUnit.mgHr,
        verificationStatus: VerificationStatus.pendingReview,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.continuous,
        standardDilutionMgPerMl: 0.1, // 25mg in 250mL = 0.1 mg/mL
        limits: DoseLimit(
          maxInfusionRate: 15.0,
          infusionRateUnit: 'mg/hr',
        ),
      ),
    ],
  ),
  const Drug(
    id: 'spironolactone',
    genericName: 'Spironolactone',
    brandNames: ['Aldactone', 'Hyles'],
    nameTh: 'สไปโรโนแลคโตน',
    category: DrugCategory.cardiovascular,
    drugClass: DrugClass.potassiumSparingDiuretic,
    pregnancyCategory: 'C',
    requiresRenalAdjustment: true,
    contraindications: ['Anuria', 'Hyperkalemia', 'Addison disease'],
    severeInteractions: [
      'ACE inhibitors',
      'ARBs (Severe hyperkalemia)',
      'Potassium supplements'
    ],
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Heart Failure',
        dosingType: DosingType.fixed,
        fixedDose: 25, // 12.5-25mg
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q24h,
        limits: DoseLimit(maxDailyDose: 50),
        renalAdjustments: [
          RenalAdjustment(
            crclMin: 30,
            crclMax: 50,
            action: RenalAction.adjust,
            adjustmentFactor: 0.5,
            adjustedFrequency: Frequency.q48h,
            notes: 'Reduce dose by 50% or dose q48h; monitor K+ and Cr closely',
            notesTh: 'ลดขนาดยาลง 50% หรือบริหารยาทุก 48 ชม. ติดตามระดับโพแทสเซียมและการทำงานของไตอย่างใกล้ชิด',
          ),
          RenalAdjustment(
            crclMin: 0,
            crclMax: 30,
            action: RenalAction.contraindicated,
            notes: 'Contraindicated in CrCl < 30 mL/min; high risk of fatal hyperkalemia',
            notesTh: 'ห้ามใช้ใน CrCl < 30 มล./นาที เสี่ยงต่อภาวะโพแทสเซียมสูงรุนแรงถึงแก่ชีวิต',
          ),
        ],
      ),
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Edema / Ascites',
        dosingType: DosingType.fixed,
        fixedDose: 100,
        doseUnit: DoseUnit.mg,
        frequency: Frequency(minIntervalHours: 12, maxIntervalHours: 24, displayEn: 'OD to BID', displayTh: 'วันละ 1-2 ครั้ง'),
        limits: DoseLimit(maxDailyDose: 400),
        renalAdjustments: [
          RenalAdjustment(
            crclMin: 30,
            crclMax: 50,
            action: RenalAction.adjust,
            adjustmentFactor: 0.5,
            adjustedFrequency: Frequency.q48h,
            notes: 'Reduce dose by 50% or dose q48h; monitor K+ closely',
            notesTh: 'ลดขนาดยาลง 50% หรือบริหารยาทุก 48 ชม. ติดตามโพแทสเซียมอย่างใกล้ชิด',
          ),
          RenalAdjustment(
            crclMin: 0,
            crclMax: 30,
            action: RenalAction.contraindicated,
            notes: 'Contraindicated in CrCl < 30 mL/min; high risk of fatal hyperkalemia',
            notesTh: 'ห้ามใช้ใน CrCl < 30 มล./นาที เสี่ยงต่อภาวะโพแทสเซียมสูงรุนแรงถึงแก่ชีวิต',
          ),
        ],
      ),
    ],
  ),
  const Drug(
    id: 'losartan',
    genericName: 'Losartan',
    brandNames: ['Cozaar'],
    nameTh: 'ลอซาร์แทน',
    category: DrugCategory.cardiovascular,
    drugClass: DrugClass.arb,
    pregnancyCategory: 'D',
    requiresHepaticCaution: true,
    severeInteractions: ['Spironolactone (Hyperkalemia)'],
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Hypertension',
        dosingType: DosingType.fixed,
        fixedDose: 50,
        doseUnit: DoseUnit.mg,
        frequency: Frequency(minIntervalHours: 12, maxIntervalHours: 24, displayEn: 'OD to BID', displayTh: 'วันละ 1-2 ครั้ง'),
        limits: DoseLimit(maxDailyDose: 100),
      ),
    ],
  ),
  const Drug(
    id: 'metoprolol',
    genericName: 'Metoprolol',
    brandNames: ['Betaloc'],
    nameTh: 'เมโทโพรลอล',
    category: DrugCategory.cardiovascular,
    pregnancyCategory: 'C',
    requiresHepaticCaution: true,
    contraindications: [
      'Severe bradycardia',
      'Heart block',
      'Decompensated heart failure'
    ],
    severeInteractions: ['Verapamil', 'Diltiazem (Severe bradycardia)'],
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Hypertension / Angina',
        dosingType: DosingType.fixed,
        fixedDose: 50,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q12h,
        limits: DoseLimit(maxDailyDose: 200),
      ),
    ],
  ),
  const Drug(
    id: 'clopidogrel',
    genericName: 'Clopidogrel',
    brandNames: ['Plavix'],
    nameTh: 'โคลพิโดเกรล',
    category: DrugCategory
        .cardiovascular, // Should be antiplatelet, but cardiovascular is fine
    pregnancyCategory: 'B',
    severeInteractions: ['Omeprazole (Decreases clopidogrel efficacy)'],
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'ACS (Maintenance)',
        dosingType: DosingType.fixed,
        fixedDose: 75,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q24h,
      ),
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'ACS (Loading)',
        dosingType: DosingType.fixed,
        fixedDose: 300, // 300-600mg
        doseUnit: DoseUnit.mg,
        frequency: Frequency.once,
      ),
    ],
  ),
  const Drug(
    id: 'rosuvastatin',
    genericName: 'Rosuvastatin',
    brandNames: ['Crestor'],
    nameTh: 'โรซูวาสแตติน',
    category: DrugCategory.cardiovascular,
    drugClass: DrugClass.statin,
    pregnancyCategory: 'X', // Statins are category X
    contraindications: ['Active liver disease'],
    requiresRenalAdjustment: true,
    severeInteractions: ['Gemfibrozil', 'Cyclosporine', 'Colchicine'],
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Hyperlipidemia',
        dosingType: DosingType.fixed,
        fixedDose: 20, // 5-40mg
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q24h,
        limits: DoseLimit(maxDailyDose: 40),
        renalAdjustments: [
          RenalAdjustment(
            crclMin: 0,
            crclMax: 30,
            action: RenalAction.adjust,
            adjustmentFactor: 0.25,
            absoluteDose: 5.0,
            notes: 'Start 5 mg OD; maximum 10 mg OD in severe renal impairment (CrCl < 30 mL/min)',
            notesTh: 'เริ่ม 5 mg วันละครั้ง; ขนาดยาสูงสุดไม่เกิน 10 mg วันละครั้ง ในผู้ป่วยไตบกพร่องรุนแรง (CrCl < 30 มล./นาที)',
          ),
        ],
      ),
    ],
  ),
  const Drug(
    id: 'simvastatin',
    genericName: 'Simvastatin',
    brandNames: ['Zocor'],
    nameTh: 'ซิมวาสแตติน',
    category: DrugCategory.cardiovascular,
    drugClass: DrugClass.statin,
    pregnancyCategory: 'X',
    contraindications: ['Active liver disease', 'Concomitant strong CYP3A4 inhibitors'],
    requiresRenalAdjustment: true,
    severeInteractions: ['Clarithromycin', 'Erythromycin', 'Ketoconazole', 'Gemfibrozil'],
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Hyperlipidemia',
        dosingType: DosingType.fixed,
        fixedDose: 20.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q24h,
        limits: DoseLimit(maxDailyDose: 40.0),
        renalAdjustments: [
          RenalAdjustment(
            crclMin: 0,
            crclMax: 30,
            action: RenalAction.adjust,
            adjustmentFactor: 0.25,
            absoluteDose: 5.0,
            notes: 'Start 5 mg OD in severe renal impairment (CrCl < 30 mL/min); monitor closely for myopathy',
            notesTh: 'เริ่ม 5 mg วันละครั้งในผู้ป่วยไตบกพร่องรุนแรง (CrCl < 30 มล./นาที); ติดตามอาการปวดกล้ามเนื้ออย่างใกล้ชิด',
          ),
        ],
      ),
    ],
  ),
  Drug(
    id: 'vasopressin',
    genericName: 'Vasopressin',
    brandNames: ['Pitressin', 'Vasostrict'],
    nameTh: 'วาโซเพรสซิน',
    category: DrugCategory.vasopressor,
    isHighAlert: true,
    sourceCitation:
        'Surviving Sepsis Campaign Guidelines 2021 / US FDA Vasostrict SPL / Lexicomp 2024',
    lastReviewedDate: '2024-10-12',
    provenance: const Provenance(
      source:
          'Surviving Sepsis Campaign Guidelines 2021 / US FDA Vasostrict SPL / Lexicomp 2024',
      reviewedBy: 'Pending Clinical Pharmacist Sign-off',
      reviewedAt: '2024-10-12',
      sourceDetail:
          'Second-line Vasopressor in Septic Shock & ACLS Cardiac Arrest Protocol',
    ),
    monograph: const ClinicalMonograph(
      textbookName: 'Surviving Sepsis Campaign Guidelines / US FDA Vasostrict SPL',
      editionYear: '2021 Guidelines / 2024 Manual',
      sectionOrTable:
          'Vasopressin Fixed-Rate Infusion in Vasodilatory / Septic Shock',
      dosingGuideline:
          '• อัตราการให้ยาต่อเนื่อง (Continuous IV Infusion): 0.03 units/min (ช่วงแนะนำ 0.01–0.04 units/min) อัตราคงที่ (Fixed-rate infusion)\n'
          '• ข้อบ่งใช้: ยาขนานที่ 2 ร่วมกับ Norepinephrine ในภาวะ Septic Shock เพื่อเพิ่ม Mean Arterial Pressure (MAP) หรือลดขนาด Norepinephrine\n'
          '• คำแนะนำสำคัญ: ห้าม Titrate ขึ้นลงตามอำเภอใจเหมือน Catecholamines เพราะเสี่ยงต่อภาวะขาดเลือดของอวัยวะภายในอย่างรุนแรง (Splanchnic & peripheral ischemia)',
      renalGuideline:
          '• ไม่จำเป็นต้องปรับขนาดยาตามการทำงานของไต (No renal dose adjustment needed)\n'
          '• ถูกสลายโดยเอนไซม์ Vasopressinase ในตับและไต',
      administrationGuideline:
          '• การผสมยามาตรฐาน: 20 units ใน NSS หรือ D5W 100 mL (ความเข้มข้น 0.2 units/mL) อัตราหยด 0.03 units/min = 9.0 mL/hr\n'
          '• สูตร Double Strength: 40 units ใน 100 mL (0.4 units/mL) อัตราหยด 0.03 units/min = 4.5 mL/hr\n'
          '• สูตร Syringe Pump: 50 units ใน 50 mL (1.0 unit/mL) อัตราหยด 0.03 units/min = 1.8 mL/hr\n'
          '• เส้นทางการให้ยา: ควรให้ผ่าน Central Line เสมอเพื่อป้องกันยาซึมออกนอกเส้นเลือด',
      clinicalNotes:
          '• จัดเป็นยาเตือนภัยสูงระดับวิกฤต (High-Alert Vasopressor)\n'
          '• เฝ้าระวังภาวะ Digital ischemia, Myocardial ischemia และ Hyponatremia จากฤทธิ์ Antidiuretic (V2 receptor)',
      externalUrl: 'https://www.sccm.org/SurvivingSepsisCampaign',
    ),
    specialNotes:
        'Administer via central line. Fixed-dose infusion (0.03 units/min) in septic shock; do not titrate.',
    specialNotesTh:
        'ควรให้ผ่านหลอดเลือดดำใหญ่ อัตราคงที่ 0.03 units/min ในภาวะ Septic Shock ไม่ควรปรับขนาดยาขึ้นลง',
    ivDiluentCompatibility: const IvDiluentCompatibility(
      compatibleDiluents: [IvDiluent.nss, IvDiluent.d5w],
      preferredDiluent: IvDiluent.nss,
      stabilityNoteEn:
          '20 units in 100 mL NSS or D5W (0.2 units/mL). Stable for 24 hours at room temperature.',
      stabilityNoteTh:
          '20 ยูนิต ใน NSS หรือ D5W 100 มล. (0.2 ยูนิต/มล.) คงตัว 24 ชั่วโมงที่อุณหภูมิห้อง',
      sourceCitation: 'US FDA Vasostrict SPL §2.2 / Lexicomp 2024',
    ),
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Septic Shock / Vasodilatory Shock',
        dosingType: DosingType.titrated,
        doseUnit: DoseUnit.units,
        continuousRateMin: 0.01,
        continuousRateMax: 0.04,
        continuousRateUnit: 'units/min',
        rateUnit: RateUnit.uMin,
        standardDilutionMgPerMl: 0.2, // 0.2 units/mL
        verificationStatus: VerificationStatus.pendingReview,
        frequency: Frequency.continuous,
        limits: DoseLimit(
          maxInfusionRate: 0.04,
          infusionRateUnit: 'units/min',
        ),
      ),
    ],
  ),
];
