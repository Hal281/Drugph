import '../../core/models/models.dart';

/// Dermatology, Ophthalmology, ENT, and Topical drugs.
final List<Drug> topical = [
  const Drug(
    id: 'silver_sulfadiazine',
    genericName: 'Silver Sulfadiazine 1% Cream',
    brandNames: ['Silvadene', 'Flamazine'],
    nameTh: 'ซิลเวอร์ซัลฟาไดอะซีน ครีม',
    category: DrugCategory.antibiotic,
    allergyClass: 'Sulfonamide (Sulfa)',
    contraindications: ['Premature infants', 'Newborns <2 months', 'Pregnancy at term'],
    specialNotes: 'Apply to clean wound 1-2 times daily with sterile gloves. Transient leukopenia may occur.',
    specialNotesTh: 'ทาบนแผลที่ทำความสะอาดแล้ว วันละ 1-2 ครั้ง ต้องสวมถุงมือปลอดเชื้อ อาจทำให้เม็ดเลือดขาวต่ำชั่วคราว',
    regimens: [
      DosingRegimen(
        route: DoseRoute.topical,
        indication: 'Burns / Wound Infection',
        dosingType: DosingType.fixed,
        fixedDose: 1.0, // apply thin layer
        doseUnit: DoseUnit.application,
        frequency: Frequency(minIntervalHours: 12, maxIntervalHours: 24, displayEn: 'q12-24h', displayTh: 'ทุก 12-24 ชม.'),
      ),
    ],
  ),
  const Drug(
    id: 'mupirocin',
    genericName: 'Mupirocin 2% Ointment',
    brandNames: ['Bactroban'],
    nameTh: 'มิวพิโรซิน',
    category: DrugCategory.antibiotic,
    specialNotes: 'Effective against MRSA skin infections. Apply thin layer to affected area TID for 5-14 days.',
    specialNotesTh: 'ยาฆ่า MRSA ทาผิวหนัง ทาบางๆ วันละ 3 ครั้ง ติดต่อกัน 5-14 วัน',
    regimens: [
      DosingRegimen(
        route: DoseRoute.topical,
        indication: 'Impetigo / MRSA Skin Infection',
        dosingType: DosingType.fixed,
        fixedDose: 1.0,
        doseUnit: DoseUnit.application,
        frequency: Frequency.q8h,
      ),
    ],
  ),
];

/// Hematology & Anticoagulant drugs.
final List<Drug> anticoagulants = [
  const Drug(
    id: 'warfarin',
    genericName: 'Warfarin',
    brandNames: ['Coumadin', 'Orfarin'],
    nameTh: 'วาร์ฟาริน',
    category: DrugCategory.cardiovascular,
    isHighAlert: true,
    requiresTDM: true, // INR monitoring
    requiresHepaticCaution: true,
    allergyClass: 'Coumarin',
    drugClass: DrugClass.anticoagulantVka,
    sourceCitation: 'Lexicomp Drug Information 2024 / CHEST Guidelines 2021 / US FDA Coumadin SPL',
    lastReviewedDate: '2024-10-12',
    provenance: Provenance(
      source: 'Lexicomp 2024 / CHEST Guidelines 2021 / US FDA Coumadin SPL',
      reviewedBy: 'Pending Clinical Pharmacist Sign-off',
      reviewedAt: '2024-10-12',
      sourceDetail: 'Oral Anticoagulation & Target INR Protocol §2.1-2.4',
    ),
    monograph: ClinicalMonograph(
      textbookName: 'Lexicomp Drug Information / CHEST Guidelines',
      editionYear: '2024 / 2021 Guidelines',
      sectionOrTable: 'Oral Anticoagulation & Target INR Protocol §2.1-2.4',
      dosingGuideline:
          '• ขนาดยาเริ่มต้น (Initial Dose): 2–5 mg รับประทานวันละ 1 ครั้ง ในเวลาเดียวกันทุกวัน (ช่วงเย็นหรือก่อนนอน)\n'
          '• ในผู้สูงอายุ ผู้มีภาวะทุพโภชนาการ หรือมีภาวะตับบกพร่อง: แนะนำเริ่มที่ <= 2–3 mg/วัน\n'
          '• การปรับขนาดยา (Dose Titration): ปรับขนาดยาตามค่า INR โดยตรวจทุก 2–3 วันในช่วงเริ่มยา จนกระทั่งได้ระดับเป้าหมายที่คงที่ (Stable INR)\n'
          '• เป้าหมายการรักษา (Target INR):\n'
          '  - ข้อบ่งชี้ทั่วไป (AFib, DVT/PE prophylaxis & treatment, Bioprosthetic valve): Target INR 2.0–3.0 (เป้าหมาย 2.5)\n'
          '  - ลิ้นหัวใจเทียมชนิดกลไก (Mechanical Mitral Valve) หรือ High-risk Mechanical Aortic Valve: Target INR 2.5–3.5 (เป้าหมาย 3.0)',
      renalGuideline:
          '• มีการกำจัดยาผ่านตับเป็นหลัก (Hepatic CYP2C9, CYP3A4 metabolism) และขับถ่ายทางน้ำดี\n'
          '• ไม่จำเป็นต้องปรับลดขนาดยาเริ่มต้นในภาวะไตเสื่อม (No renal dose adjustment needed)\n'
          '• ผู้ป่วย End-Stage Renal Disease (ESRD) หรือฟอกไต ต้องติดตามค่า INR บ่อยขึ้นอย่างใกล้ชิด เนื่องจากภาวะ Uremia มีผลต่อการจับโปรตีนและความเสี่ยงเลือดออก (Bleeding risk)',
      administrationGuideline:
          '• การบริหารยา: รับประทานยาวันละ 1 ครั้ง เวลาเดียวกันสม่ำเสมอ (แนะนำช่วงเย็น 18:00–20:00 น.) พร้อมอาหารหรือตอนท้องว่าง\n'
          '• อาหารและวิตามินเค: ต้องรับประทานอาหารที่มีวิตามินเคสม่ำเสมอ (ผักใบเขียว เช่น คะน้า บรอกโคลี ผักโขม) ห้ามเปลี่ยนปริมาณการบริโภคอย่างฉับพลัน',
      clinicalNotes:
          '• จัดเป็นยาเตือนภัยสูงระดับวิกฤต (High-Alert Anticoagulant)\n'
          '• Boxed Warning: เสี่ยงต่อการเกิดภาวะเลือดออกรุนแรงถึงแก่ชีวิต (Fatal Bleeding / Major Hemorrhage)\n'
          '• การแก้พิษ (Reversal Protocol):\n'
          '  - ค่า INR สูงโดยไม่มีเลือดออก (INR 4.5–10): หยุดยาหรือชะลอขนาดยา อาจพิจารณา Oral Vitamin K1 (Phytomenadione) 1–2.5 mg หากเสี่ยงเลือดออกสูง\n'
          '  - เลือดออกรุนแรง (Major/Life-threatening Bleeding): ให้ 4-factor Prothrombin Complex Concentrate (4F-PCC) ร่วมกับ Vitamin K1 5–10 mg หยดเข้าหลอดเลือดดำช้าๆ (Slow IV infusion นานกว่า 30 นาที เพื่อป้องกัน Anaphylaxis)\n'
          '• ข้อห้ามใช้เด็ดขาดในสตรีมีครรภ์ (Teratogenic / Fetal Warfarin Syndrome)',
      externalUrl: 'https://dailymed.nlm.nih.gov/dailymed/search.cfm?labeltype=all&query=warfarin',
    ),
    interactions: [
      DrugInteraction(
        targetDrugId: 'ibuprofen',
        targetClass: DrugClass.nsaid,
        severity: InteractionSeverity.major,
        mechanismEn:
            'NSAIDs inhibit platelet function and cause GI mucosal injury, synergistically increasing major bleeding risk with Warfarin.',
        mechanismTh:
            'ยากลุ่ม NSAIDs ยับยั้งการทำงานของเกล็ดเลือดและระคายเคืองกระเพาะอาหาร เพิ่มความเสี่ยงเลือดออกรุนแรงร่วมกับ Warfarin',
        managementEn:
            'Avoid concomitant NSAID use. Consider alternative analgesia (e.g. Paracetamol) and monitor INR closely.',
        managementTh:
            'หลีกเลี่ยงการใช้ร่วมกับ NSAIDs พิจารณาใช้ยาแก้ปวดตัวอื่น (เช่น พาราเซตามอล) และติดตามค่า INR อย่างใกล้ชิด',
        source: 'AHFS Drug Information 2024',
      ),
    ],
    severeInteractions: [
      'NSAIDs (Increased bleeding risk)',
      'Metronidazole (Increases INR significantly)',
      'Antibiotics (Many alter INR - monitor closely)',
      'Vitamin K-rich foods (Decreases effect)'
    ],
    contraindications: [
      'Active bleeding',
      'Pregnancy (Teratogenic)',
      'Severe hepatic disease',
      'Unsupervised patients'
    ],
    specialNotes: 'Narrow therapeutic index. Target INR 2.0-3.0 for most indications. Vitamin K is antidote.',
    specialNotesTh: 'ยาละลายลิ่มเลือดที่ต้องเจาะเลือดดู INR (เป้าหมาย 2.0-3.0) กินวิตามิน K เป็นยาแก้พิษ ห้ามกินกับผักใบเขียวมากเกินไป',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Anticoagulation (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 5.0, // Initial 5 mg, then adjust by INR
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q24h,
        limits: DoseLimit(maxDailyDose: 15.0), // Rarely >10mg/day
        verificationStatus: VerificationStatus.pendingReview,
      ),
    ],
  ),
  const Drug(
    id: 'enoxaparin',
    genericName: 'Enoxaparin',
    brandNames: ['Clexane', 'Lovenox'],
    nameTh: 'อีน็อกซาพาริน',
    drugClass: DrugClass.anticoagulantHeparin,
    category: DrugCategory.cardiovascular,
    isHighAlert: true,
    requiresRenalAdjustment: true,
    allergyClass: 'Heparin / LMWH',
    sourceCitation: 'Lexicomp Drug Information 2024 / US FDA Lovenox SPL / KDIGO 2023',
    lastReviewedDate: '2024-10-12',
    provenance: Provenance(
      source: 'Lexicomp 2024 / US FDA Lovenox (enoxaparin sodium) SPL / KDIGO 2023',
      reviewedBy: 'Pending Clinical Pharmacist Sign-off',
      reviewedAt: '2024-10-12',
      sourceDetail: 'Section 2.2: Renal Impairment Dosing & Monitoring',
    ),
    monograph: ClinicalMonograph(
      textbookName: 'Lexicomp Drug Information / US FDA Lovenox SPL',
      editionYear: '2024',
      sectionOrTable: 'Section 2.2: Renal Impairment Dosing & Monitoring',
      dosingGuideline:
          '• การรักษาภาวะ VTE / DVT / PE (Treatment):\n'
          '  - ผู้ป่วยไตปกติ: 1 mg/kg ฉีดใต้ผิวหนัง (SC) ทุก 12 ชม. (หรือ 1.5 mg/kg SC วันละ 1 ครั้ง)\n'
          '  - ร่วมกับยาต้านเกล็ดเลือดใน ACS / NSTEMI: 1 mg/kg SC ทุก 12 ชม.\n'
          '• การป้องกันภาวะลิ่มเลือดอุดตัน (Prophylaxis):\n'
          '  - ผู้ป่วยในทั่วไป (Medical inpatients): 40 mg SC วันละ 1 ครั้ง\n'
          '  - ศัลยกรรมกระดูก/ข้อ (Orthopedic surgery): 30 mg SC ทุก 12 ชม. หรือ 40 mg SC วันละ 1 ครั้ง',
      renalGuideline:
          '• ยาขับถ่ายออกทางไตเป็นหลัก (Renal elimination)\n'
          '• ผู้ป่วย CrCl 30–50 mL/min: ไม่จำเป็นต้องปรับลดขนาดยา แต่ควรติดตามอาการเลือดออก\n'
          '• ผู้ป่วย CrCl < 30 mL/min (Severe Renal Impairment):\n'
          '  - ข้อบ่งชี้ Treatment: ปรับลดขนาดยาเป็น 1 mg/kg SC ทุก 24 ชม. (q24h)\n'
          '  - ข้อบ่งชี้ Prophylaxis: ปรับลดขนาดยาเป็น 30 mg SC ทุก 24 ชม. (q24h)\n'
          '• แนะนำเจาะตรวจระดับ Anti-Xa Peak (4 ชม. หลังฉีดยาเข็มที่ 3 หรือ 4; เป้าหมาย Treatment q12h คือ 0.6–1.0 IU/mL; Treatment q24h คือ 1.0–2.0 IU/mL)',
      administrationGuideline:
          '• การบริหารยา: ฉีดเข้าใต้ผิวหนัง (Deep Subcutaneous Injection) บริเวณหน้าท้องด้านซ้ายหรือขวา ห่างจากสะดืออย่างน้อย 2 นิ้ว (Anterolateral / Posterolateral abdominal wall)\n'
          '• เทคนิคการฉีด: สลับข้างซ้าย-ขวาทุกครั้ง, จัดท่านอนหงาย, บีบผิวหนังเป็นรอยพับและแทงเข็มทำมุม 90 องศาจนสุดความยาวเข็ม\n'
          '• ข้อห้าม: ห้ามไล่ฟองอากาศออกจากหลอดฉีดยาพร้อมใช้ (Prefilled syringe) และห้ามนวดหรือคลึงบริเวณที่ฉีดยาโดยเด็ดขาดเพื่อป้องกันรอยช้ำและก้อนเลือดใต้ผิวหนัง (Hematoma)',
      clinicalNotes:
          '• จัดเป็นยาเตือนภัยสูง (High-Alert LMWH)\n'
          '• Boxed Warning: เสี่ยงต่อการเกิดก้อนเลือดกดทับไขสันหลัง (Epidural / Spinal Hematoma) ทำให้เป็นอัมพาตถาวรในผู้ที่ได้รับการทำ Spinal/Epidural Anesthesia หรือ Lumbar Puncture ต้องเว้นระยะห่างการให้ยาอย่างน้อย 12 ชม. สำหรับขนาด Prophylaxis และ 24 ชม. สำหรับขนาด Treatment\n'
          '• การแก้พิษ: Protamine sulfate สามารถลบล้างฤทธิ์ Anti-IIa ได้เกือบสมบูรณ์ แต่ลบล้างฤทธิ์ Anti-Xa ได้เพียงประมาณ 60%',
      externalUrl: 'https://dailymed.nlm.nih.gov/dailymed/search.cfm?labeltype=all&query=enoxaparin',
    ),
    severeInteractions: [
      'Antiplatelet agents (Increased bleeding)',
      'NSAIDs (Increased bleeding)'
    ],
    contraindications: [
      'Active major bleeding',
      'History of heparin-induced thrombocytopenia (HIT)',
      'Severe thrombocytopenia'
    ],
    specialNotes: 'Subcutaneous injection in abdominal wall. Do NOT massage injection site. Anti-Xa monitoring in renal impairment.',
    specialNotesTh: 'ฉีดใต้ผิวหนังบริเวณหน้าท้อง ห้ามนวดตำแหน่งที่ฉีด ต้องเจาะ Anti-Xa ในคนไข้ไตเสื่อม',
    regimens: [
      DosingRegimen(
        route: DoseRoute.sc,
        indication: 'DVT/PE Treatment (Adult)',
        dosingType: DosingType.weightBased,
        dosePerKg: 1.0, // 1 mg/kg q12h
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q12h,
        limits: DoseLimit(maxSingleDose: 100.0),
        verificationStatus: VerificationStatus.pendingReview,
        renalAdjustments: [
          RenalAdjustment(crclMin: 0, crclMax: 30, action: RenalAction.adjust, adjustmentFactor: 1.0, adjustedFrequency: Frequency.q24h, notes: 'Use 1 mg/kg q24h in CrCl < 30 mL/min'),
        ],
        renalReplacementProtocols: [
          RenalReplacementProtocol(
            mode: RenalReplacementMode.ihd,
            doseFactor: 1.0,
            frequency: Frequency.q24h,
            requiresPostHdSupplement: false,
            clinicalInstructionEn:
                '1 mg/kg SC q24h. Unfractionated heparin (UFH) is preferred in ESRD/dialysis. If enoxaparin is used, mandatory peak Anti-Xa monitoring (target 0.5–1.0 IU/mL 4h post-dose) is required. Not removed by hemodialysis (no post-HD supplement needed).',
            clinicalInstructionTh:
                '1 มก./กก. ฉีดใต้ผิวหนัง ทุก 24 ชม. ในผู้ป่วยไตวายเรื้อรังระยะสุดท้าย/ฟอกไต แนะนำให้ใช้ Unfractionated Heparin (UFH) เป็นหลัก หากจำเป็นต้องใช้ Enoxaparin ต้องเจาะตรวจติดตามระดับ Anti-Xa (เป้าหมาย 0.5–1.0 IU/mL ที่ 4 ชม. หลังฉีด) ยาไม่ถูกขจัดออกทางไตเทียม ไม่ต้องให้ยาเสริมหลังฟอกไต',
            provenance: Provenance(
              source: 'Lexicomp 2024 / FDA Lovenox SPL §2.2 / KDIGO 2023',
              reviewedBy: 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
              reviewedAt: '2024-10-29',
            ),
          ),
          RenalReplacementProtocol(
            mode: RenalReplacementMode.capd,
            doseFactor: 1.0,
            frequency: Frequency.q24h,
            requiresPostHdSupplement: false,
            clinicalInstructionEn:
                '1 mg/kg SC q24h with mandatory Anti-Xa monitoring. UFH is preferred.',
            clinicalInstructionTh:
                '1 มก./กก. SC ทุก 24 ชม. พร้อมติดตามระดับ Anti-Xa อย่างเคร่งครัด แนะนำให้ใช้ UFH เป็นทางเลือกแรก',
            provenance: Provenance(
              source: 'Lexicomp 2024 / KDIGO 2023',
              reviewedBy: 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
              reviewedAt: '2024-10-29',
            ),
          ),
          RenalReplacementProtocol(
            mode: RenalReplacementMode.crrt,
            doseFactor: 1.0,
            frequency: Frequency.q24h,
            requiresPostHdSupplement: false,
            clinicalInstructionEn:
                'CRRT: 1 mg/kg SC q24h with mandatory peak Anti-Xa monitoring (target 0.5–1.0 IU/mL). UFH infusion is generally preferred for titratability.',
            clinicalInstructionTh:
                'CRRT: 1 มก./กก. SC ทุก 24 ชม. ต้องเจาะติดตามระดับ Anti-Xa อย่างเคร่งครัด (เป้าหมาย 0.5–1.0 IU/mL) ทั่วไปแนะนำให้ใช้ Heparin (UFH) ทางหลอดเลือดดำมากกว่าเนื่องจากปรับขนาดยาได้ง่ายกว่า',
            provenance: Provenance(
              source: 'Lexicomp 2024 / KDIGO 2023',
              reviewedBy: 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
              reviewedAt: '2024-10-29',
            ),
          ),
        ],
      ),
      DosingRegimen(
        route: DoseRoute.sc,
        indication: 'DVT Prophylaxis (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 40.0, // 40 mg SC q24h
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q24h,
        verificationStatus: VerificationStatus.pendingReview,
        renalAdjustments: [
          RenalAdjustment(crclMin: 0, crclMax: 30, action: RenalAction.adjust, absoluteDose: 30.0, adjustedFrequency: Frequency.q24h, notes: 'Use 30 mg q24h'),
        ],
        renalReplacementProtocols: [
          RenalReplacementProtocol(
            mode: RenalReplacementMode.ihd,
            specificDose: 30.0,
            doseUnit: DoseUnit.mg,
            frequency: Frequency.q24h,
            requiresPostHdSupplement: false,
            clinicalInstructionEn: '30 mg SC q24h. Not cleared by hemodialysis.',
            clinicalInstructionTh: '30 มก. SC ทุก 24 ชม. ยาไม่ถูกขจัดออกทางไตเทียม',
            provenance: Provenance(
              source: 'Lexicomp 2024 / FDA Lovenox SPL §2.2',
              reviewedBy: 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
              reviewedAt: '2024-10-29',
            ),
          ),
          RenalReplacementProtocol(
            mode: RenalReplacementMode.capd,
            specificDose: 30.0,
            doseUnit: DoseUnit.mg,
            frequency: Frequency.q24h,
            requiresPostHdSupplement: false,
            clinicalInstructionEn: '30 mg SC q24h.',
            clinicalInstructionTh: '30 มก. SC ทุก 24 ชม.',
            provenance: Provenance(
              source: 'Lexicomp 2024 / KDIGO 2023',
              reviewedBy: 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
              reviewedAt: '2024-10-29',
            ),
          ),
          RenalReplacementProtocol(
            mode: RenalReplacementMode.crrt,
            specificDose: 30.0,
            doseUnit: DoseUnit.mg,
            frequency: Frequency.q24h,
            requiresPostHdSupplement: false,
            clinicalInstructionEn: '30 mg SC q24h (target prophylactic Anti-Xa 0.2–0.4 IU/mL).',
            clinicalInstructionTh: '30 มก. SC ทุก 24 ชม. (เป้าหมาย Anti-Xa 0.2–0.4 IU/mL)',
            provenance: Provenance(
              source: 'Lexicomp 2024 / KDIGO 2023',
              reviewedBy: 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
              reviewedAt: '2024-10-29',
            ),
          ),
        ],
      ),
    ],
  ),
  const Drug(
    id: 'heparin',
    genericName: 'Unfractionated Heparin (UFH)',
    brandNames: ['Heparin'],
    nameTh: 'เฮปาริน',
    drugClass: DrugClass.anticoagulantHeparin,
    category: DrugCategory.cardiovascular,
    isHighAlert: true,
    requiresTDM: true, // aPTT monitoring
    sourceCitation: 'CHEST Guidelines 2021 / คู่มือยาฉีดความเสี่ยงสูง รามาธิบดี / US FDA Heparin Sodium SPL',
    lastReviewedDate: '2024-10-12',
    provenance: Provenance(
      source: 'CHEST Guidelines 2021 / Ramathibodi High-Alert IV Infusion Guide / US FDA Heparin SPL',
      reviewedBy: 'Pending Clinical Pharmacist Sign-off',
      reviewedAt: '2024-10-12',
      sourceDetail: 'Weight-based Heparin Infusion Nomogram & aPTT Protocol',
    ),
    monograph: ClinicalMonograph(
      textbookName: 'CHEST Guidelines / คู่มือยาฉีดความเสี่ยงสูง รามาธิบดี',
      editionYear: '2021 Guidelines / 2024 Manual',
      sectionOrTable: 'Weight-based Heparin Nomogram & aPTT Monitoring',
      dosingGuideline:
          '• ขนาดยาเริ่มต้น (Weight-based Nomogram สำหรับ VTE/ACS):\n'
          '  - Initial IV Bolus: 80 units/kg (สูงสุดไม่เกิน 4,000–5,000 units) ฉีดเข้าหลอดเลือดดำทันที\n'
          '  - Continuous IV Infusion: 18 units/kg/hr หยดต่อเนื่องผ่าน Infusion Pump ทันทีหลัง Bolus\n'
          '• การติดตามระดับยา (TDM / Laboratory Monitoring):\n'
          '  - เจาะ aPTT หรือ Anti-Xa ที่ 6 ชม. หลังเริ่มยา และ 6 ชม. หลังการปรับอัตราการหยดทุกครั้ง\n'
          '  - เป้าหมายการรักษา: aPTT 1.5–2.5 เท่าของค่า Control (ประมาณ 60–85 วินาที) หรือ Anti-Xa level 0.3–0.7 IU/mL',
      renalGuideline:
          '• กำจัดยาผ่าน Reticuloendothelial system และ Hepatic metabolism เป็นหลัก\n'
          '• ไม่จำเป็นต้องปรับลดขนาดยาในผู้ป่วยไตเสื่อม (No renal dose adjustment needed)\n'
          '• เป็นยาทางเลือกหลักในการรักษา Anticoagulation ในผู้ป่วย Severe Renal Impairment (CrCl < 30 mL/min) หรือฟอกไต',
      administrationGuideline:
          '• สารละลายและการผสมยามาตรฐาน: Heparin 25,000 units ใน D5W หรือ NSS 250 mL (ความเข้มข้น 100 units/mL)\n'
          '• เส้นทางการให้ยา: ต้องให้ผ่านเครื่องควบคุมอัตราการหยดยา (Infusion Pump) อย่างเคร่งครัด ห้ามหยดแบบต่อสายน้ำเกลือธรรมดาเด็ดขาด',
      clinicalNotes:
          '• จัดเป็นยาเตือนภัยสูงระดับวิกฤต (High-Alert Anticoagulant)\n'
          '• ภาวะแทรกซ้อนสำคัญ: Heparin-Induced Thrombocytopenia (HIT Type II) ซึ่งกระตุ้นลิ่มเลือดอุดตันรุนแรง ต้องตรวจระดับเกล็ดเลือด (Platelet count) ทุก 2–3 วันในสัปดาห์แรก\n'
          '• ยาแก้พิษจำเพาะ (Specific Antidote): Protamine sulfate (1 mg แก้ฤทธิ์ Heparin ได้ประมาณ 100 units ที่ได้รับใน 2–3 ชม. ก่อนหน้า โดยฉีดช้าๆ อัตราไม่เกิน 50 mg ใน 10 นาที เพื่อป้องกัน Severe Hypotension และ Anaphylactoid reaction)',
      externalUrl: 'https://dailymed.nlm.nih.gov/dailymed/search.cfm?labeltype=all&query=heparin',
    ),
    severeInteractions: [
      'Antiplatelet agents (Increased bleeding)',
      'NSAIDs (Increased bleeding)'
    ],
    contraindications: [
      'Active bleeding',
      'HIT (Heparin-Induced Thrombocytopenia)',
      'Severe thrombocytopenia'
    ],
    specialNotes: 'Monitor aPTT every 6 hours. Target aPTT 1.5-2.5x normal. Protamine sulfate is the antidote.',
    specialNotesTh: 'ต้องเจาะ aPTT ทุก 6 ชม. (เป้าหมาย 1.5-2.5 เท่าของค่าปกติ) ยาแก้พิษคือ Protamine sulfate',
    ivDiluentCompatibility: IvDiluentCompatibility(
      compatibleDiluents: [IvDiluent.d5w, IvDiluent.nss],
      preferredDiluent: IvDiluent.d5w,
      stabilityNoteEn:
          'Standard dilution: 25,000 units in 250 mL D5W or NSS (100 units/mL). Invert bag at least 6 times after mixing to prevent pooling.',
      stabilityNoteTh:
          'ผสมมาตรฐาน 25,000 units ใน D5W หรือ NSS 250 mL (100 units/mL) ต้องพลิกถุงกลับไปมาอย่างน้อย 6 ครั้งเพื่อป้องกันยาตกก้นถุง',
      sourceCitation:
          'US FDA Heparin Sodium SPL / Ramathibodi High-Alert IV Infusion Guide 2024',
    ),
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Anticoagulation (Adult)',
        dosingType: DosingType.titrated,
        doseUnit: DoseUnit.units,
        frequency: Frequency.continuous,
        continuousRateMin: 18.0,
        continuousRateMax: 18.0,
        continuousRateUnit: 'units/kg/hr',
        rateUnit: RateUnit.uKgHr,
        standardDilutionMgPerMl: 100.0, // 25,000 units in 250 mL = 100 units/mL
        standardDilution: Concentration(100.0, ConcentrationUnit.unitsPerMl),
        verificationStatus: VerificationStatus.pendingReview,
        phases: [
          DosingPhase(
            type: PhaseType.bolus,
            role: DoseRole.start,
            nameEn: 'Initial IV Bolus',
            nameTh: 'ฉีดเข้าหลอดเลือดดำทันที (Bolus)',
            dosePerKg: 80.0,
            doseUnit: DoseUnit.units,
            instructionsEn: '80 units/kg IV bolus (max 4,000-5,000 units)',
            instructionsTh: '80 ยูนิต/กก. ฉีดเข้าหลอดเลือดดำทันที (สูงสุด 4,000-5,000 ยูนิต)',
          ),
          DosingPhase(
            type: PhaseType.infusion,
            role: DoseRole.usual,
            nameEn: 'Continuous Infusion',
            nameTh: 'หยดเข้าหลอดเลือดดำต่อเนื่อง (Infusion)',
            rate: 18.0,
            rateUnit: RateUnit.uKgHr,
            instructionsEn: '18 units/kg/hr continuous infusion, titrated to target aPTT',
            instructionsTh: '18 ยูนิต/กก./ชม. หยดเข้าหลอดเลือดดำต่อเนื่อง ปรับตามระดับ aPTT',
          ),
        ],
      ),
    ],
  ),
  Drug(
    id: 'apixaban',
    genericName: 'Apixaban',
    brandNames: ['Eliquis'],
    nameTh: 'อะพิกซาแบน (ยาละลายลิ่มเลือด)',
    drugClass: DrugClass.anticoagulantDoac,
    category: DrugCategory.cardiovascular,
    requiresRenalAdjustment: true,
    isHighAlert: true,
    requiresHepaticCaution: true,
    sourceCitation: 'US FDA Eliquis Prescribing Information §2.1 / 2023 ACC/AHA/ACCP AFib Guidelines',
    lastReviewedDate: '2024-10-12',
    provenance: const Provenance(
      source: 'US FDA Eliquis Prescribing Information §2.1 / 2023 ACC/AHA AFib Guidelines',
      reviewedBy: 'Pending Clinical Pharmacist Sign-off',
      reviewedAt: '2024-10-12',
      sourceDetail: 'Section 2.1: 2-of-3 Dose Reduction Criteria & VTE Treatment Protocol',
    ),
    monograph: const ClinicalMonograph(
      textbookName: 'US FDA Eliquis Prescribing Information / 2023 ACC/AHA AFib Guidelines',
      editionYear: '2024',
      sectionOrTable: 'Section 2.1: 2-of-3 Dose Reduction Criteria & Nonvalvular Atrial Fibrillation',
      dosingGuideline:
          '• การป้องกันโรคหลอดเลือดสมองในภาวะ Nonvalvular Atrial Fibrillation (NVAF):\n'
          '  - ขนาดยามาตรฐาน: 5 mg รับประทานวันละ 2 ครั้ง (BID)\n'
          '  - เกณฑ์การปรับลดขนาดยา (2-of-3 Dose Reduction Criteria): ปรับลดเป็น 2.5 mg รับประทานวันละ 2 ครั้ง เมื่อผู้ป่วยมีคุณสมบัติอย่างน้อย 2 ใน 3 ข้อ ดังต่อไปนี้:\n'
          '    1. อายุ >= 80 ปี\n'
          '    2. น้ำหนักตัว <= 60 kg\n'
          '    3. Serum Creatinine >= 1.5 mg/dL\n'
          '• การรักษาภาวะ DVT / PE (Treatment of VTE):\n'
          '  - ขนาดยาเริ่มต้น: 10 mg รับประทานวันละ 2 ครั้ง เป็นเวลา 7 วันแรก\n'
          '  - ขนาดยาต่อเนื่อง: 5 mg รับประทานวันละ 2 ครั้ง หลังครบ 7 วัน',
      renalGuideline:
          '• ขับออกทางไตประมาณ 27% (ส่วนใหญ่กำจัดทางอุจจาระและตับผ่าน CYP3A4)\n'
          '• ในข้อบ่งชี้ NVAF: ปรับขนาดยาตามเกณฑ์ 2-of-3 criteria (รวม SCr >= 1.5 mg/dL)\n'
          '• ในข้อบ่งชี้ DVT/PE: ไม่แนะนำให้ใช้ในผู้ป่วยที่มี CrCl < 15 mL/min หรือผู้ป่วยที่ฟอกไต (ESRD/Hemodialysis) เนื่องจากขาดข้อมูลการศึกษาทางคลินิกที่เพียงพอ',
      administrationGuideline:
          '• การบริหารยา: กลืนทั้งเม็ดพร้อมน้ำ รับประทานพร้อมอาหารหรือตอนท้องว่าง\n'
          '• กรณีกลืนยาลำบาก: สามารถบดเม็ดและผสมในน้ำ, D5W หรือน้ำแอปเปิ้ล แล้วรับประทานทันที หรือให้ทางสายให้อาหาร (NG tube) ได้',
      clinicalNotes:
          '• จัดเป็นยาเตือนภัยสูง (High-Alert DOAC)\n'
          '• Boxed Warning (1): การหยุดยากะทันหันเพิ่มความเสี่ยงต่อการเกิดลิ่มเลือดอุดตันในสมอง (Stroke) หากต้องหยุดยาชั่วคราวโดยไม่มีเลือดออก ควรพิจารณาให้ยาต้านการแข็งตัวของเลือดตัวอื่นทดแทน (Bridging therapy)\n'
          '• Boxed Warning (2): เสี่ยงต่อการเกิดก้อนเลือดกดทับไขสันหลัง (Epidural/Spinal Hematoma) ในผู้ป่วยที่ทำ Neuraxial procedures\n'
          '• ยาแก้พิษจำเพาะ (Specific Antidote): Andexanet alfa หรือพิจารณาให้ 4-factor Prothrombin Complex Concentrate (4F-PCC) 50 units/kg หากเกิด Major Life-Threatening Bleeding',
      externalUrl: 'https://dailymed.nlm.nih.gov/dailymed/search.cfm?labeltype=all&query=apixaban',
    ),
    severeInteractions: [
      'Strong CYP3A4 inhibitors (Ketoconazole, Itraconazole, Ritonavir)',
      'Strong CYP3A4 inducers (Rifampin, Phenytoin)',
      'NSAIDs (Bleeding risk)'
    ],
    contraindications: ['Active pathological bleeding', 'Severe hepatic impairment (Child-Pugh C)'],
    specialNotes: 'Dose reduction to 2.5 mg BID required if 2 of 3 criteria met: Age >= 80, Weight <= 60 kg, or SCr >= 1.5 mg/dL.',
    specialNotesTh: 'ยารักษาลิ่มเลือดอุดตัน (DOAC) ต้องลดโดสเหลือ 2.5 mg BID หากเข้าเกณฑ์ 2 ใน 3 ข้อนี้: (1) อายุ 80 ขึ้นไป (2) น้ำหนักตัว 60 กก. ลงมา (3) SCr >= 1.5',
    doseRules: [
      DoseRule(
        id: 'apixaban_2_of_3_criteria',
        name: 'Apixaban 2-of-3 Dose Reduction Criteria (AFib)',
        sourceCitation: 'FDA Eliquis (apixaban) Prescribing Information §2.1; 2023 AHA/ACC/ACCP/NLA AFib Guidelines',
        verificationStatus: VerificationStatus.verified,
        applies: (ctx) {
          final ind = ctx.regimen.indication?.toLowerCase() ?? '';
          return RegExp(r'\bafib\b|atrial fibrillation|\bnvaf\b').hasMatch(ind);
        },
        evaluate: (ctx) {
          final p = ctx.patient;
          int criteriaCount = 0;
          if (p.ageYears >= 80) criteriaCount++;
          if (p.weightKg <= 60.0) criteriaCount++;
          final warnings = <DoseWarning>[];
          if (p.serumCreatinineMgDl != null) {
            if (p.serumCreatinineMgDl! >= 1.5) criteriaCount++;
          } else {
            warnings.add(
              const DoseWarning(
                severity: LimitSeverity.soft,
                code: DoseWarningCode.scrMissing,
                messageEn:
                    'Serum creatinine is missing: Apixaban 2-of-3 dose reduction criteria cannot be fully evaluated.',
                messageTh:
                    'ไม่มีค่า Serum Creatinine: ไม่สามารถประเมินเกณฑ์การปรับลดขนาดยา Apixaban 2 ใน 3 ข้อได้อย่างสมบูรณ์',
              ),
            );
          }

          if (criteriaCount >= 2) {
            warnings.add(
              const DoseWarning(
                severity: LimitSeverity.info,
                code: DoseWarningCode.renalAdjustmentApplied,
                messageEn:
                    'Apixaban dose reduced to 2.5 mg BID (meets ≥2 criteria: Age ≥80, Weight ≤60 kg, SCr ≥1.5 mg/dL).',
                messageTh:
                    'ปรับลดขนาดยา Apixaban เป็น 2.5 mg วันละ 2 ครั้ง (เข้าเกณฑ์ ≥2 ข้อ: อายุ ≥80, นน. ≤60 กก., SCr ≥1.5 mg/dL)',
              ),
            );
            return DoseRuleResult(
              modifiedDose: 2.5,
              modifiedFrequency: Frequency.q12h,
              isDoseModified: true,
              isRenallyAdjusted: false,
              modificationReasonEn:
                  'Apixaban dose reduced to 2.5 mg BID (meets ≥2 criteria: Age ≥80, Weight ≤60 kg, SCr ≥1.5 mg/dL).',
              modificationReasonTh:
                  'ปรับลดขนาดยา Apixaban เป็น 2.5 mg วันละ 2 ครั้ง (เข้าเกณฑ์ ≥2 ข้อ: อายุ ≥80, นน. ≤60 กก., SCr ≥1.5 mg/dL)',
              warnings: warnings,
            );
          }

          return DoseRuleResult(warnings: warnings);
        },
      ),
    ],
    regimens: [
      const DosingRegimen(
        route: DoseRoute.po,
        indication: 'AFib (Stroke Prophylaxis)',
        dosingType: DosingType.fixed,
        fixedDose: 5.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q12h,
        limits: DoseLimit(maxDailyDose: 10.0),
        population: PopulationCriteria(
          maxHepaticImpairment: ChildPughClass.classB,
        ),
        verificationStatus: VerificationStatus.pendingReview,
        renalAdjustments: [
          RenalAdjustment(crclMin: 0, crclMax: 15, action: RenalAction.avoid, notes: 'Avoid in severe renal impairment (CrCl < 15 mL/min)'),
        ],
      ),
      const DosingRegimen(
        route: DoseRoute.po,
        indication: 'DVT/PE Treatment',
        dosingType: DosingType.fixed,
        fixedDose: 10.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q12h,
        limits: DoseLimit(maxDailyDose: 20.0),
        population: PopulationCriteria(
          maxHepaticImpairment: ChildPughClass.classB,
        ),
        verificationStatus: VerificationStatus.pendingReview,
        phases: [
          DosingPhase(
            type: PhaseType.loading,
            role: DoseRole.start,
            nameEn: 'Initial Treatment (Days 1-7)',
            nameTh: 'ระยะเริ่มต้น (วันที่ 1-7)',
            dose: 10.0,
            doseUnit: DoseUnit.mg,
            frequency: Frequency.q12h,
            durationDays: 7,
            instructionsEn: '10 mg PO BID for 7 days',
            instructionsTh: '10 มก. รับประทานวันละ 2 ครั้ง เป็นเวลา 7 วัน',
          ),
          DosingPhase(
            type: PhaseType.maintenance,
            role: DoseRole.usual,
            nameEn: 'Maintenance (After Day 7)',
            nameTh: 'ขนาดยาต่อเนื่อง (หลังวันที่ 7)',
            dose: 5.0,
            doseUnit: DoseUnit.mg,
            frequency: Frequency.q12h,
            instructionsEn: '5 mg PO BID thereafter',
            instructionsTh: '5 มก. รับประทานวันละ 2 ครั้ง ต่อเนื่อง',
          ),
        ],
        renalAdjustments: [
          RenalAdjustment(
            crclMin: 0,
            crclMax: 15,
            action: RenalAction.avoid,
            notes: 'Avoid in severe renal impairment (CrCl < 15 mL/min)',
          ),
        ],
      ),
    ],
  ),
  const Drug(
    id: 'rivaroxaban',
    genericName: 'Rivaroxaban',
    brandNames: ['Xarelto'],
    nameTh: 'ริวาร็อกซาแบน (ยาละลายลิ่มเลือด)',
    drugClass: DrugClass.anticoagulantDoac,
    category: DrugCategory.cardiovascular,
    requiresRenalAdjustment: true,
    isHighAlert: true,
    requiresHepaticCaution: true,
    sourceCitation: 'Lexicomp Drug Information 2024 / US FDA Xarelto SPL',
    lastReviewedDate: '2024-10-12',
    provenance: Provenance(
      source: 'Lexicomp 2024 / US FDA Xarelto (rivaroxaban) SPL',
      reviewedBy: 'Pending Clinical Pharmacist Sign-off',
      reviewedAt: '2024-10-12',
      sourceDetail: 'Section 2.1: Nonvalvular Atrial Fibrillation & Renal Adjustments',
    ),
    monograph: ClinicalMonograph(
      textbookName: 'Lexicomp Drug Information / US FDA Xarelto SPL',
      editionYear: '2024',
      sectionOrTable: 'Section 2.1: Nonvalvular Atrial Fibrillation',
      dosingGuideline:
          '• การป้องกันโรคหลอดเลือดสมองในภาวะ Nonvalvular Atrial Fibrillation (NVAF):\n'
          '  - ขนาดยามาตรฐาน (CrCl > 50 mL/min): 20 mg รับประทานวันละ 1 ครั้ง พร้อมอาหารมื้อเย็น\n'
          '• การรักษาภาวะ DVT / PE (VTE Treatment):\n'
          '  - 15 mg รับประทานวันละ 2 ครั้ง พร้อมอาหาร เป็นเวลา 21 วันแรก จากนั้นปรับเป็น 20 mg วันละ 1 ครั้ง พร้อมอาหาร',
      renalGuideline:
          '• ยาขับออกทางไตประมาณ 36% ในรูปที่ไม่เปลี่ยนแปลง (Unchanged drug) และกำจัดผ่านตับ\n'
          '• ผู้ป่วย CrCl 15–50 mL/min ใน NVAF: ปรับลดขนาดยาเป็น 15 mg รับประทานวันละ 1 ครั้ง พร้อมอาหารมื้อเย็น\n'
          '• ผู้ป่วย CrCl < 15 mL/min: หลีกเลี่ยงการใช้ยา (Avoid use) เนื่องจากเสี่ยงต่อการสะสมยาและเลือดออกรุนแรง',
      administrationGuideline:
          '• ข้อกำหนดสำคัญด้านอาหาร (Mandatory Food Requirement):\n'
          '  - เม็ดยาขนาด 15 mg และ 20 mg "ต้องรับประทานพร้อมอาหาร" เสมอ เนื่องจากอาหารช่วยเพิ่มชีวประสิทธิผล (Oral Bioavailability) จาก 66% เป็นเกือบ 100%\n'
          '  - หากรับประทานตอนท้องว่าง ระดับยาในเลือดจะต่ำกว่าเกณฑ์การรักษาอย่างมีนัยสำคัญทางคลินิก\n'
          '• สามารถบดเม็ดผสมในน้ำหรือซอสแอปเปิ้ล และให้ทางสายยางให้อาหารได้ทันทีก่อนให้อาหารทางสายยาง',
      clinicalNotes:
          '• จัดเป็นยาเตือนภัยสูง (High-Alert DOAC)\n'
          '• Boxed Warning: เสี่ยงต่อการเกิดลิ่มเลือดอุดตันซ้ำซ้อนหรือ Stroke เมื่อหยุดยากะทันหัน และเสี่ยงต่อการเกิด Epidural/Spinal Hematoma ในผู้ป่วยที่ได้รับการแทงไขสันหลัง\n'
          '• ยาแก้พิษจำเพาะ (Specific Antidote): Andexanet alfa หรือ 4-factor Prothrombin Complex Concentrate (4F-PCC) ในภาวะเลือดออกรุนแรง',
      externalUrl: 'https://dailymed.nlm.nih.gov/dailymed/search.cfm?labeltype=all&query=rivaroxaban',
    ),
    severeInteractions: [
      'Strong CYP3A4 inhibitors & P-gp inhibitors',
      'NSAIDs (Bleeding risk)'
    ],
    contraindications: [
      'Active pathological bleeding',
      'Moderate-to-severe hepatic impairment (Child-Pugh B and C) or hepatic disease associated with coagulopathy',
    ],
    specialNotes: 'For doses >= 15 mg, must be taken WITH FOOD to ensure adequate absorption. Avoid if CrCl < 15.',
    specialNotesTh: 'ถ้ารับประทานขนาด 15 mg หรือ 20 mg ต้องกิน "พร้อมอาหาร" เท่านั้นเพื่อการดูดซึมยา หลีกเลี่ยงถ้าไตวาย (CrCl < 15)',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'AFib (Stroke Prophylaxis)',
        dosingType: DosingType.fixed,
        fixedDose: 20.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q24h,
        limits: DoseLimit(maxDailyDose: 20.0),
        population: PopulationCriteria(
          maxHepaticImpairment: ChildPughClass.classA,
        ),
        verificationStatus: VerificationStatus.pendingReview,
        renalAdjustments: [
          RenalAdjustment(crclMin: 15, crclMax: 50, action: RenalAction.adjust, absoluteDose: 15.0, adjustedFrequency: Frequency.q24h, notes: 'Reduce to 15 mg OD'),
          RenalAdjustment(crclMin: 0, crclMax: 15, action: RenalAction.avoid, notes: 'Avoid use in severe renal impairment (CrCl < 15 mL/min)'),
        ],
      ),
    ],
  ),
];

/// Vitamins, Supplements, and Electrolyte Replacements.
final List<Drug> supplements = [
  const Drug(
    id: 'potassium_chloride',
    genericName: 'Potassium Chloride (KCl)',
    brandNames: ['KCl', 'K-Lor'],
    nameTh: 'โพแทสเซียม คลอไรด์',
    category: DrugCategory.supplement,
    isHighAlert: true, // Concentrated KCl is high alert
    severeInteractions: [
      'ACE Inhibitors / ARBs (Hyperkalemia)',
      'Potassium-sparing Diuretics (Hyperkalemia)'
    ],
    contraindications: ['Hyperkalemia', 'Severe renal impairment with oliguria'],
    specialNotes: 'NEVER give undiluted IV push (cardiac arrest risk). Max IV rate: 10 mEq/hr via peripheral, 20 mEq/hr via central.',
    specialNotesTh: 'ห้ามฉีด IV Push เด็ดขาด (หัวใจหยุดเต้น) อัตราหยดสูงสุด: 10 mEq/hr ทาง peripheral, 20 mEq/hr ทาง central line',
    ivDiluentCompatibility: IvDiluentCompatibility(
      compatibleDiluents: [IvDiluent.nss, IvDiluent.halfNss, IvDiluent.d5w],
      preferredDiluent: IvDiluent.nss,
      stabilityNoteEn:
          'Prefer NSS over D5W during initial severe hypokalemia replacement (dextrose stimulates insulin release and may transiently worsen hypokalemia). Mix thoroughly before hanging.',
      stabilityNoteTh:
          'แนะนำผสมใน NSS เป็นหลักในการแก้โพแทสเซียมต่ำรุนแรงระยะแรก (การให้ D5W กระตุ้นอินซูลินดึง K+ เข้าเซลล์ อาจทำให้น้ำผลโพแทสเซียมในเลือดต่ำลงชั่วคราว) ต้องเขย่าถุงให้เข้ากันดีก่อนแขวน',
      sourceCitation:
          'Lexicomp Drug Information 2024 / Ramathibodi High-Alert Electrolyte Manual',
    ),
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Hypokalemia Replacement (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 20.0, // 20-40 mEq
        doseUnit: DoseUnit.mEq,
        frequency: Frequency(minIntervalHours: 8, maxIntervalHours: 12, displayEn: 'q8-12h', displayTh: 'ทุก 8-12 ชม.'),
        limits: DoseLimit(maxDailyDose: 200.0),
      ),
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Severe Hypokalemia (Adult IV)',
        dosingType: DosingType.fixed,
        fixedDose: 20.0, // 20 mEq in 100mL over 1-2hr
        doseUnit: DoseUnit.mEq,
        frequency: Frequency(
          displayEn: 'Over 1-2 hours',
          displayTh: 'ให้ใน 1-2 ชม.',
          customReason: 'ICU central line infusion over 1-2 hours',
        ),
        limits: DoseLimit(maxInfusionRate: 10.0, infusionRateUnit: 'mEq/hr'),
      ),
    ],
  ),
  const Drug(
    id: 'calcium_gluconate',
    genericName: 'Calcium Gluconate',
    brandNames: ['Calcium Gluconate'],
    nameTh: 'แคลเซียม กลูโคเนต',
    category: DrugCategory.supplement,
    isHighAlert: true,
    severeInteractions: [
      'Digoxin (Increases toxicity - give slowly with ECG)',
      'Ceftriaxone IV (Precipitation in neonates - CONTRAINDICATED in neonates)'
    ],
    specialNotes: 'Give slowly IV over 5-10 min. Monitor heart rate. Extravasation causes tissue necrosis.',
    specialNotesTh: 'ฉีด IV ช้าๆ ใน 5-10 นาที ดูจอมอนิเตอร์หัวใจ ถ้ายารั่วซึมนอกหลอดเลือดจะทำให้เนื้อเยื่อตาย',
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Hyperkalemia / Hypocalcemia (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 1000.0, // 1g (10mL of 10%)
        doseUnit: DoseUnit.mg,
        frequency: Frequency(
          displayEn: 'Over 5-10 min',
          displayTh: 'ให้ใน 5-10 นาที (ซ้ำได้)',
          customReason: 'Slow IV push over 5-10 minutes under cardiac monitoring',
        ),
      ),
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Hyperkalemia / Hypocalcemia (Pediatric)',
        dosingType: DosingType.weightBased,
        dosePerKg: 60.0, // 60-100 mg/kg slow IV
        doseUnit: DoseUnit.mg,
        frequency: Frequency(
          displayEn: 'Over 5-10 min',
          displayTh: 'ให้ใน 5-10 นาที',
          customReason: 'Slow IV push over 5-10 minutes under cardiac monitoring',
        ),
        limits: DoseLimit(maxSingleDose: 3000.0),
      ),
    ],
  ),
  const Drug(
    id: 'vitamin_k',
    genericName: 'Phytonadione (Vitamin K1)',
    brandNames: ['Konakion'],
    nameTh: 'วิตามินเค (ไฟโตนาไดโอน)',
    category: DrugCategory.supplement,
    allergyClass: 'Vitamin K',
    specialNotes: 'Antidote for warfarin overdose. SC or slow IV (risk of anaphylactoid reaction with IV). Takes 6-24h for effect.',
    specialNotesTh: 'ยาแก้พิษวาร์ฟาริน ควรฉีดใต้ผิวหนังหรือ IV ช้าๆ ออกฤทธิ์ใน 6-24 ชม.',
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Warfarin Reversal / Major Bleeding (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 10.0, // 10 mg slow IV
        doseUnit: DoseUnit.mg,
        frequency: Frequency.stat,
        infusionTimeMinutes: 30,
      ),
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Supratherapeutic INR (No bleeding)',
        dosingType: DosingType.fixed,
        fixedDose: 2.5, // 2.5-5 mg PO
        doseUnit: DoseUnit.mg,
        frequency: Frequency.once,
      ),
    ],
  ),
];
