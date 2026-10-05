import '../../core/models/models.dart';

final List<Drug> antibiotics = [
  const Drug(
    id: 'vancomycin',
    genericName: 'Vancomycin',
    brandNames: ['Vancocin'],
    nameTh: 'แวนโคมัยซิน',
    category: DrugCategory.antibiotic,
    availableStrengths: [500.0],
    requiresRenalAdjustment: true,
    isHighAlert: true,
    requiresTDM: true,
    specialNotes: 'Red man syndrome with rapid infusion. Target trough 15-20 mcg/mL for severe infections.',
    specialNotesTh: 'ระวัง Red man syndrome หากดริปเร็วไป. เป้าหมายระดับยา 15-20 mcg/mL ในการติดเชื้อรุนแรง',
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Systemic Infection (Adult)',
        dosingType: DosingType.weightBased,
        dosePerKg: 15.0, // 15 mg/kg
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q12h,
        limits: DoseLimit(
          maxSingleDose: 2000.0,
          softMaxSingleDose: 1500.0,
          maxDosePerKgPerDay: 60.0,
        ),
        phases: [
          DosingPhase(
            type: PhaseType.loading,
            role: DoseRole.start,
            nameEn: 'Loading Dose (Critically Ill)',
            nameTh: 'ขนาดยาเริ่มต้น (สำหรับผู้ป่วยวิกฤต)',
            dosePerKg: 25.0,
            doseUnit: DoseUnit.mg,
            frequency: Frequency.once,
            instructionsEn:
                '25-30 mg/kg (actual body weight, max 2000-3000 mg) as a one-time loading dose',
            instructionsTh:
                '25-30 มก./กก. (คำนวณตามน้ำหนักจริง สูงสุด 2000-3000 มก.) ให้ครั้งเดียว',
          ),
          DosingPhase(
            type: PhaseType.maintenance,
            role: DoseRole.usual,
            nameEn: 'Maintenance Dose',
            nameTh: 'ขนาดยาต่อเนื่อง',
            dosePerKg: 15.0,
            doseUnit: DoseUnit.mg,
            frequency: Frequency.q12h,
            instructionsEn:
                '15-20 mg/kg q8-12h, adjusted for renal function and TDM trough levels',
            instructionsTh:
                '15-20 มก./กก. ทุก 8-12 ชม. ปรับตามการทำงานของไตและระดับยา TDM',
          ),
        ],
        maxInfusionRateMgPerMin:
            10.0, // max 10 mg/min or 60 min, whichever is longer
        renalAdjustments: [
          RenalAdjustment(
            crclMin: 50,
            crclMax: 90,
            adjustmentFactor: 1.0,
            adjustedFrequency: Frequency.q12hTo24h,
          ),
          RenalAdjustment(
            crclMin: 20,
            crclMax: 50,
            adjustmentFactor: 1.0,
            adjustedFrequency: Frequency.q24h,
          ),
          RenalAdjustment(
            crclMin: 10,
            crclMax: 20,
            adjustmentFactor: 1.0,
            adjustedFrequency: Frequency.q48hTo72h,
          ),
          RenalAdjustment(
            crclMin: 0,
            crclMax: 10,
            action: RenalAction.adjust,
            adjustmentFactor: 1.0,
            adjustedFrequency: Frequency(
              isPrn: true,
              displayEn: 'TDM-guided pulse redosing',
              displayTh: 'บริหารซ้ำตามระดับยา TDM',
              kind: FrequencyKind.prn,
            ),
            notes:
                'ESRD / Hemodialysis: Loading dose 20-25 mg/kg (actual weight, max 2000-3000 mg). Re-dose 500-1000 mg only when pre-dialysis or random trough level < 15-20 mcg/mL. Monitor trough before each subsequent dose.',
            notesTh:
                'ไตวายระยะสุดท้าย / ฟอกไต: ขนาดยาเริ่มต้น (Loading) 20-25 mg/kg (น้ำหนักจริง สูงสุด 2000-3000 mg). บริหารยาซ้ำ 500-1000 mg เฉพาะเมื่อระดับยา TDM ในเลือดก่อนฟอกไต < 15-20 mcg/mL. ตรวจติดตามระดับยาทุกครั้งก่อนให้ยาซ้ำ',
          ),
        ],
      ),
    ],
  ),
  const Drug(
    id: 'gentamicin',
    genericName: 'Gentamicin',
    brandNames: ['Garamycin'],
    nameTh: 'เจนตามัยซิน',
    category: DrugCategory.antibiotic,
    requiresRenalAdjustment: true,
    requiresTDM: true,
    specialNotes:
        'Use IBW or AdjBW for dosing. Ototoxicity and nephrotoxicity risk.',
    specialNotesTh: 'ใช้น้ำหนัก IBW หรือ AdjBW. ระวังพิษต่อหูและไต',
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Extended Interval Dosing',
        dosingType: DosingType.weightBased,
        dosingWeightStrategy: DosingWeightStrategy.adjustedIfObese,
        dosePerKg: 5.0, // 5-7 mg/kg
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q24h,
        limits: DoseLimit(maxSingleDose: 700.0),
        renalAdjustments: [
          RenalAdjustment(
            crclMin: 40,
            crclMax: 60,
            adjustmentFactor: 1.0,
            adjustedFrequency: Frequency.q36h,
          ),
          RenalAdjustment(
            crclMin: 20,
            crclMax: 40,
            adjustmentFactor: 1.0,
            adjustedFrequency: Frequency.q48h,
          ),
          RenalAdjustment(
            crclMin: 0,
            crclMax: 20,
            adjustmentFactor: 1.0,
            notes: 'Monitor levels',
          ),
        ],
      ),
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Traditional Dosing',
        dosingType: DosingType.weightBased,
        dosingWeightStrategy: DosingWeightStrategy.adjustedIfObese,
        dosePerKg: 1.5, // 1-2.5 mg/kg
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q8h,
        limits: DoseLimit(maxSingleDose: 300.0),
      ),
    ],
  ),
  const Drug(
    id: 'amikacin',
    genericName: 'Amikacin',
    brandNames: ['Amikin'],
    nameTh: 'อะมิคาซิน',
    category: DrugCategory.antibiotic,
    requiresRenalAdjustment: true,
    requiresTDM: true,
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Extended Interval Dosing',
        dosingType: DosingType.weightBased,
        dosingWeightStrategy: DosingWeightStrategy.adjustedIfObese,
        dosePerKg: 15.0, // 15 mg/kg
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q24h,
        limits: DoseLimit(maxSingleDose: 1500.0),
      ),
    ],
  ),
  const Drug(
    id: 'meropenem',
    genericName: 'Meropenem',
    brandNames: ['Meronem'],
    nameTh: 'เมโรพีเนม',
    category: DrugCategory.antibiotic,
    availableStrengths: [500.0, 1000.0],
    requiresRenalAdjustment: true,
    drugClass: DrugClass.betaLactamCarbapenem,
    interactions: [
      DrugInteraction(
        targetDrugId: 'valproic_acid',
        severity: InteractionSeverity.contraindicated,
        mechanismEn:
            'Meropenem decreases serum valproic acid concentrations below therapeutic levels, risking breakthrough seizures.',
        mechanismTh:
            'Meropenem ลดระดับยา Valproic acid ในเลือดอย่างรวดเร็วจนต่ำกว่าระดับการรักษา เสี่ยงต่ออาการชักกำเริบ',
        managementEn:
            'Avoid coadministration. Choose alternative antibiotic or switch antiepileptic agent.',
        managementTh:
            'หลีกเลี่ยงการใช้ร่วมกันเด็ดขาด ให้เลือกใช้ยาฆ่าเชื้อตัวอื่นหรือเปลี่ยนยากันชัก',
        source: 'FDA Merrem Label / Sanford Guide 2024',
      ),
    ],
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Severe Infection',
        dosingType: DosingType.fixed,
        fixedDose: 1000.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q8h,
        limits: DoseLimit(maxSingleDose: 2000.0, maxDailyDose: 6000.0),
        renalAdjustments: [
          // Reference: Merrem (meropenem) FDA Prescribing Information §2.2; Sanford Guide 2023.
          // CrCl 26-50: 1g q12h; CrCl 10-25: 500mg q12h; CrCl <10: 500mg q24h.
          RenalAdjustment(
            crclMin: 26,
            crclMax: 50,
            adjustmentFactor: 1.0,
            adjustedFrequency: Frequency.q12h,
          ),
          RenalAdjustment(
            crclMin: 10,
            crclMax: 26,
            adjustmentFactor: 0.5,
            adjustedFrequency: Frequency.q12h,
          ),
          RenalAdjustment(
            crclMin: 0,
            crclMax: 10,
            adjustmentFactor: 0.5,
            adjustedFrequency: Frequency.q24h,
          ),
        ],
      ),
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Meningitis',
        dosingType: DosingType.fixed,
        fixedDose: 2000.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q8h,
        limits: DoseLimit(maxSingleDose: 2000.0, maxDailyDose: 6000.0),
      ),
    ],
  ),
  const Drug(
    id: 'ceftriaxone',
    genericName: 'Ceftriaxone',
    brandNames: ['Rocephin'],
    nameTh: 'เซฟไตรอะโซน',
    category: DrugCategory.antibiotic,
    requiresHepaticCaution: true, // Caution in combined renal/hepatic
    contraindications: [
      'Neonates (hyperbilirubinemia)',
      'Concurrent use with IV calcium in neonates',
    ],
    specialNotes:
        'No renal adjustment needed for usual doses. Avoid in neonates.',
    specialNotesTh:
        'ไม่ต้องปรับโดสในผู้ป่วยโรคไต ห้ามใช้ในทารกแรกเกิดที่ตัวเหลือง',
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Severe Infection (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 2000.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q24h,
        limits: DoseLimit(maxDailyDose: 4000.0),
      ),
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Meningitis (Pediatric)',
        dosingType: DosingType.weightBased,
        dosePerKg: 100.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q24h, // Can also be divided q12h
        limits: DoseLimit(maxDailyDose: 4000.0, maxDosePerKgPerDay: 100.0),
      ),
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Standard Infection (Pediatric)',
        dosingType: DosingType.weightBased,
        dosePerKg: 50.0, // 50-75 mg/kg
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q24h,
        limits: DoseLimit(maxDailyDose: 2000.0),
      ),
    ],
  ),
  const Drug(
    id: 'amoxicillin_clavulanate',
    genericName: 'Amoxicillin/Clavulanate',
    brandNames: ['Augmentin', 'Curam', 'Amoksiklav'],
    nameTh: 'ออม็อกซิลลิน/คลาวูลานิก แอซิด',
    category: DrugCategory.antibiotic,
    requiresRenalAdjustment: true,
    requiresHepaticCaution: true,
    allergyClass: 'Penicillin / Beta-lactam',
    severeInteractions: [
      'Methotrexate (increases toxicity)',
      'Probenecid',
      'Allopurinol (rash)',
    ],
    contraindications: [
      'History of penicillin-associated jaundice/hepatic dysfunction',
    ],
    specialNotes: 'Dosing is based on the Amoxicillin component. High doses of clavulanate can cause diarrhea.',
    specialNotesTh: 'คำนวณโดสจาก Amoxicillin เป็นหลัก ระวังท้องเสียจาก Clavulanate ที่สูงเกินไป',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Standard Infection (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 1000.0, // Commonly 875/125 mg = 1000 mg total tablet, but base is amox
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q12h,
        renalAdjustments: [
          RenalAdjustment(
            crclMin: 10,
            crclMax: 30,
            adjustmentFactor: 0.5,
            absoluteDose: 500.0,
            adjustedFrequency: Frequency.q12h,
            notes: 'Use 500/125 mg tablet q12h in CrCl 10-30',
          ),
          RenalAdjustment(
            crclMin: 0,
            crclMax: 10,
            adjustmentFactor: 0.5,
            absoluteDose: 500.0,
            adjustedFrequency: Frequency.q24h,
            notes: 'Use 500/125 mg tablet q24h in CrCl <10',
          ),
        ],
      ),
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Standard Infection (Pediatric)',
        dosingType: DosingType.weightBased,
        dosePerKg: 22.5, // 45 mg/kg/day divided q12h = 22.5 mg/kg/dose
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q12h,
        notes: '45 mg/kg/day divided q12h (22.5 mg/kg/dose)',
        limits: DoseLimit(maxDailyDose: 4000.0), // Amoxicillin component
      ),
    ],
  ),
  const Drug(
    id: 'azithromycin',
    genericName: 'Azithromycin',
    brandNames: ['Zithromax'],
    nameTh: 'อะซิโธรมัยซิน',
    category: DrugCategory.antibiotic,
    requiresHepaticCaution: true,
    allergyClass: 'Macrolide',
    severeInteractions: [
      'Amiodarone (QT prolongation)',
      'Statins (increased myopathy risk)',
      'Warfarin',
    ],
    specialNotes: 'Risk of QT prolongation. Take on an empty stomach for some formulations.',
    specialNotesTh: 'ระวังคลื่นไฟฟ้าหัวใจผิดปกติ (QT prolongation)',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Atypical Pneumonia (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 500.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q24h,
        notes: 'Day 1: 500 mg, then 250 mg q24h on Days 2-5',
        limits: DoseLimit(maxSingleDose: 500.0),
      ),
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Otitis Media / Pneumonia (Pediatric)',
        dosingType: DosingType.weightBased,
        dosePerKg: 10.0, // 10 mg/kg day 1, then 5 mg/kg day 2-5
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q24h,
        notes: 'Day 1: 10 mg/kg (max 500 mg), then 5 mg/kg q24h on Days 2-5 (max 250 mg)',
        limits: DoseLimit(maxSingleDose: 500.0),
      ),
    ],
  ),
  const Drug(
    id: 'ciprofloxacin',
    genericName: 'Ciprofloxacin',
    brandNames: ['Ciproxyl', 'Ciprobay'],
    nameTh: 'ซิโปรฟลอกซาซิน',
    category: DrugCategory.antibiotic,
    requiresRenalAdjustment: true,
    allergyClass: 'Fluoroquinolone',
    severeInteractions: [
      'Tizanidine (Contraindicated - severe hypotension)',
      'Theophylline (Increases toxicity)',
      'Antacids / Calcium / Iron (Decreases absorption)',
    ],
    contraindications: ['Concurrent administration with tizanidine'],
    specialNotes: 'Risk of tendon rupture and QT prolongation. Avoid in children (unless cystic fibrosis) due to cartilage toxicity.',
    specialNotesTh: 'เสี่ยงเอ็นร้อยหวายอักเสบ/ฉีกขาด และ QT ยาวขึ้น ไม่แนะนำในเด็กเนื่องจากผลต่อกระดูกอ่อน ห้ามกินพร้อมนมหรือยาลดกรด',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'UTI / Systemic Infection (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 500.0, // 250 - 750 mg
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q12h,
        limits: DoseLimit(maxDailyDose: 1500.0),
        renalAdjustments: [
          RenalAdjustment(
            crclMin: 0,
            crclMax: 30,
            adjustmentFactor: 0.5,
            notes: 'Max 500 mg q18-24h',
          ),
        ],
      ),
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Severe Infection (Adult IV)',
        dosingType: DosingType.fixed,
        fixedDose: 400.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q12h,
        limits: DoseLimit(maxDailyDose: 1200.0),
      ),
    ],
  ),
  const Drug(
    id: 'levofloxacin',
    genericName: 'Levofloxacin',
    brandNames: ['Cravit', 'Leflox'],
    nameTh: 'ลีโวฟลอกซาซิน',
    category: DrugCategory.antibiotic,
    requiresRenalAdjustment: true,
    allergyClass: 'Fluoroquinolone',
    severeInteractions: [
      'QT Prolonging agents (e.g. Amiodarone)',
      'Antacids / Calcium (Decreases absorption)',
    ],
    specialNotes: 'Risk of tendon rupture and peripheral neuropathy. Highly dependent on renal clearance.',
    specialNotesTh:
        'ระวังเอ็นฉีกขาดและเส้นประสาทอักเสบ ต้องปรับโดสตามไตอย่างเคร่งครัด',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Pneumonia / UTI (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 500.0, // 500-750 mg
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q24h,
        limits: DoseLimit(maxDailyDose: 750.0),
        renalAdjustments: [
          // Reference: Levaquin (levofloxacin) FDA Prescribing Information §2.3; Sanford Guide 2023.
          // CrCl 20-49: 500mg initial then 250mg q24h; CrCl <20: 500mg initial then 250mg q48h.
          RenalAdjustment(
            crclMin: 20,
            crclMax: 50,
            adjustmentFactor: 0.5,
            notes: 'Initial 500mg, then 250mg q24h',
          ),
          RenalAdjustment(
            crclMin: 0,
            crclMax: 20,
            adjustmentFactor: 0.5,
            adjustedFrequency: Frequency.q48h,
            notes: 'Initial 500mg, then 250mg q48h',
          ),
        ],
      ),
    ],
  ),
  const Drug(
    id: 'clindamycin',
    genericName: 'Clindamycin',
    brandNames: ['Dalacin C', 'Clinmanda'],
    nameTh: 'คลินดามัยซิน',
    category: DrugCategory.antibiotic,
    requiresHepaticCaution: true,
    allergyClass: 'Lincosamide',
    severeInteractions: ['Erythromycin (Antagonistic effect)'],
    specialNotes: 'High risk of severe Clostridioides difficile-associated diarrhea (CDAD).',
    specialNotesTh: 'ความเสี่ยงสูงที่จะเกิดลำไส้อักเสบจากการติดเชื้อ C. difficile (ท้องเสียรุนแรง)',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Skin / Soft Tissue Infection (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 300.0, // 150-450 mg
        doseUnit: DoseUnit.mg,
        frequency: Frequency(minIntervalHours: 6, maxIntervalHours: 8, displayEn: 'q6-8h', displayTh: 'ทุก 6-8 ชม.'),
        limits: DoseLimit(maxDailyDose: 1800.0),
      ),
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Infection (Pediatric)',
        dosingType: DosingType.weightBased,
        dosePerKg: 15.0, // 8-25 mg/kg/day divided TID or QID
        doseUnit: DoseUnit.mg,
        frequency: Frequency(minIntervalHours: 6, maxIntervalHours: 8, displayEn: 'Divided q6-8h', displayTh: 'แบ่งทุก 6-8 ชม.', doseBasis: DoseBasis.perDay), // Assuming tool provides total per day
        limits: DoseLimit(maxDailyDose: 1800.0),
      ),
    ],
  ),
  const Drug(
    id: 'metronidazole',
    genericName: 'Metronidazole',
    brandNames: ['Flagyl', 'Robaz'],
    nameTh: 'เมโทรนิดาโซล',
    category: DrugCategory.antibiotic,
    requiresHepaticCaution: true,
    allergyClass: 'Nitroimidazole',
    severeInteractions: [
      'Alcohol (Disulfiram-like reaction: severe vomiting, flushing)',
      'Warfarin (Increases bleeding risk)',
    ],
    contraindications: [
      'First trimester of pregnancy (controversial, but often avoided)',
    ],
    specialNotes: 'Strictly AVOID alcohol during therapy and for 3 days after. May cause metallic taste.',
    specialNotesTh: 'ห้ามดื่มแอลกอฮอล์เด็ดขาดระหว่างกินยาและหลังยาหมด 3 วัน (จะทำให้คลื่นไส้อาเจียนรุนแรง) อาจมีรสเฝื่อนในปาก',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Anaerobic Infection / Trichomoniasis (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 400.0, // or 500mg depending on country/formulation
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q8h,
        limits: DoseLimit(maxDailyDose: 4000.0),
      ),
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Severe Anaerobic Infection (Adult IV)',
        dosingType: DosingType.fixed,
        fixedDose: 500.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q8h,
        limits: DoseLimit(maxDailyDose: 4000.0),
      ),
    ],
  ),
  const Drug(
    id: 'cefazolin',
    genericName: 'Cefazolin',
    brandNames: ['Cefamezin'],
    nameTh: 'เซฟาโซลิน',
    category: DrugCategory.antibiotic,
    requiresRenalAdjustment: true,
    allergyClass: 'Cephalosporin (1st Gen)',
    severeInteractions: [], // Standard
    specialNotes: 'Drug of choice for surgical prophylaxis. Cross-reactivity with penicillin allergy is ~1-5%.',
    specialNotesTh: 'ยาหลักสำหรับป้องกันการติดเชื้อก่อนผ่าตัด ระวังในผู้ป่วยที่แพ้ Penicillin รุนแรง',
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Surgical Prophylaxis (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 2000.0, // 2g for adults > 60kg
        doseUnit: DoseUnit.mg,
        frequency: Frequency.stat,
        limits: DoseLimit(
          maxSingleDose: 3000.0, // 3g for patients >120kg
        ),
      ),
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Systemic Infection (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 1000.0, // 1g q8h
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q8h,
        limits: DoseLimit(maxDailyDose: 6000.0),
        renalAdjustments: [
          // Reference: Cefazolin FDA Prescribing Information §2.2 (Ancef); Sanford Guide 2023.
          // CrCl 35-54: standard dose q8h; CrCl 11-34: 500 mg q12h; CrCl <11: 500 mg q24h.
          RenalAdjustment(
            crclMin: 11,
            crclMax: 35,
            adjustmentFactor: 0.5,
            adjustedFrequency: Frequency.q12h,
            notes: '500 mg IV q12h (50% reduction for CrCl 11-34 mL/min)',
          ),
          RenalAdjustment(
            crclMin: 0,
            crclMax: 11,
            adjustmentFactor: 0.5,
            adjustedFrequency: Frequency.q24h,
            notes: '500 mg IV q24h (50% reduction for CrCl < 11 mL/min)',
          ),
        ],
      ),
    ],
  ),
  const Drug(
    id: 'piperacillin_tazobactam',
    genericName: 'Piperacillin/Tazobactam',
    brandNames: ['Tazocin'],
    nameTh: 'ไพเพอราซิลลิน/ทาโซแบคแตม',
    category: DrugCategory.antibiotic,
    pregnancyCategory: 'B',
    requiresRenalAdjustment: true,
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Severe infections',
        dosingType: DosingType.fixed,
        fixedDose: 4.5,
        doseUnit: DoseUnit.g,
        frequency: Frequency.q6h,
        infusionTimeMinutes: 30,
        notes: 'Standard infusion is 4.5g q6h over 30 min. Extended infusion is 3.375g or 4.5g q8h over 4 hours.',
        limits: DoseLimit(maxDailyDose: 18),
        renalAdjustments: [
          // Reference: Zosyn (piperacillin/tazobactam) FDA Prescribing Information §2.2.
          // For base 4.5g q6h: CrCl 20-40 -> 3.375g q6h (75%); CrCl <20 -> 2.25g q6h (50%).
          RenalAdjustment(
            crclMin: 20,
            crclMax: 40,
            adjustmentFactor: 0.75, // 4.5g * 0.75 = 3.375g
            adjustedFrequency: Frequency.q6h,
            notes: '3.375g IV q6h over 30 min (or 3.375g q8h extended infusion)',
          ),
          RenalAdjustment(
            crclMin: 0,
            crclMax: 20,
            adjustmentFactor: 0.5, // 4.5g * 0.5 = 2.25g
            adjustedFrequency: Frequency.q6h,
            notes: '2.25g IV q6h over 30 min',
          ),
        ],
      ),
    ],
  ),
  const Drug(
    id: 'cefepime',
    genericName: 'Cefepime',
    brandNames: ['Maxipime'],
    nameTh: 'เซฟีปีม',
    category: DrugCategory.antibiotic,
    pregnancyCategory: 'B',
    requiresRenalAdjustment: true,
    specialNotes: 'Risk of neurotoxicity/seizures in renal impairment if dose not adjusted.',
    specialNotesTh:
        'ระวังอาการชักหรือพิษต่อระบบประสาทหากไม่ปรับโดสในผู้ป่วยโรคไต',
    regimens: [
      DosingRegimen(
        route: DoseRoute.iv,
        indication: 'Pseudomonas / Febrile neutropenia',
        dosingType: DosingType.fixed,
        fixedDose: 2,
        doseUnit: DoseUnit.g,
        frequency: Frequency.q8h,
        limits: DoseLimit(maxDailyDose: 6),
      ),
    ],
  ),
  const Drug(
    id: 'linezolid',
    genericName: 'Linezolid',
    brandNames: ['Zyvox'],
    nameTh: 'ลีเนโซลิด',
    category: DrugCategory.antibiotic,
    pregnancyCategory: 'C',
    severeInteractions: ['SSRIs', 'MAOIs (Serotonin Syndrome)'],
    specialNotes: 'Monitor for thrombocytopenia with prolonged use (>14 days).',
    specialNotesTh: 'ระวังเกล็ดเลือดต่ำหากใช้ติดต่อกันเกิน 14 วัน',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'MRSA / VRE infections',
        dosingType: DosingType.fixed,
        fixedDose: 600,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q12h,
        limits: DoseLimit(maxDailyDose: 1200),
      ),
    ],
  ),
  const Drug(
    id: 'doxycycline',
    genericName: 'Doxycycline',
    brandNames: ['Vibramycin'],
    nameTh: 'ด็อกซีไซคลิน',
    category: DrugCategory.antibiotic,
    pregnancyCategory: 'D',
    contraindications: ['Children < 8 years', 'Pregnancy'],
    severeInteractions: ['Antacids', 'Iron supplements (separate by 2 hours)'],
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Scrub typhus / Atypical pneumonia',
        dosingType: DosingType.fixed,
        fixedDose: 100,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q12h,
        limits: DoseLimit(maxDailyDose: 200),
      ),
    ],
  ),
  const Drug(
    id: 'colistin',
    genericName: 'Colistin (Colistimethate Sodium)',
    brandNames: ['Colomycin'],
    nameTh: 'โคลิสติน',
    category: DrugCategory.antibiotic,
    requiresRenalAdjustment: true,
    isHighAlert: true,
    specialNotes: 'Dosing is based on Colistin Base Activity (CBA). 1 million IU = ~33.3 mg CBA. High risk of nephrotoxicity.',
    specialNotesTh: 'ขนาดยาคำนวณตาม CBA (1 ล้านยูนิต = ~33.3 mg CBA) ระวังพิษต่อไตอย่างรุนแรง ควรติดตามค่า SCr ทุกวัน',
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Severe MDR Infection (Loading Dose)',
        dosingType: DosingType.weightBased,
        dosePerKg: 5.0, // 5 mg CBA/kg
        doseUnit: DoseUnit.mg,
        frequency: Frequency.stat,
        limits: DoseLimit(maxSingleDose: 300.0), // Max 300 mg CBA (or 9 million IU)
      ),
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Severe MDR Infection (Maintenance)',
        dosingType: DosingType.fixed,
        fixedDose: 150.0, // Typical maintenance for normal renal function
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q12h,
        limits: DoseLimit(maxDailyDose: 300.0),
        renalAdjustments: [
          RenalAdjustment(crclMin: 30, crclMax: 50, action: RenalAction.adjust, adjustmentFactor: 1.0, adjustedFrequency: Frequency.q12h, notes: '75-150 mg CBA q12h'),
          RenalAdjustment(crclMin: 10, crclMax: 30, action: RenalAction.adjust, adjustmentFactor: 1.0, adjustedFrequency: Frequency.q24h, notes: '75-150 mg CBA q24h'),
          RenalAdjustment(crclMin: 0, crclMax: 10, action: RenalAction.adjust, adjustmentFactor: 1.0, adjustedFrequency: Frequency.q24h, notes: '50-100 mg CBA q24h'),
        ],
      ),
    ],
  ),
  const Drug(
    id: 'acyclovir',
    genericName: 'Acyclovir',
    brandNames: ['Zovirax'],
    nameTh: 'อะไซโคลเวียร์ (แบบฉีด)',
    category: DrugCategory.antibiotic,
    requiresRenalAdjustment: true,
    specialNotes: 'Must infuse over at least 1 hour to prevent renal crystal nephropathy. Ensure adequate hydration. Use IBW for obese patients.',
    specialNotesTh: 'ต้องดริปยานานกว่า 1 ชม. และให้สารน้ำให้เพียงพอ เพื่อป้องกันยาตกผลึกอุดตันในไต (ใช้ IBW คำนวณในคนอ้วน)',
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Herpes Simplex Encephalitis',
        dosingType: DosingType.weightBased,
        dosePerKg: 10.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q8h,
        limits: DoseLimit(maxSingleDose: 800.0),
        renalAdjustments: [
          RenalAdjustment(crclMin: 25, crclMax: 50, action: RenalAction.adjust, adjustmentFactor: 1.0, adjustedFrequency: Frequency.q12h),
          RenalAdjustment(crclMin: 10, crclMax: 25, action: RenalAction.adjust, adjustmentFactor: 1.0, adjustedFrequency: Frequency.q24h),
          RenalAdjustment(crclMin: 0, crclMax: 10, action: RenalAction.adjust, absoluteDose: 500.0, adjustedFrequency: Frequency.q24h, notes: '500 mg q24h'),
        ],
      ),
    ],
  ),
  const Drug(
    id: 'fluconazole',
    genericName: 'Fluconazole',
    brandNames: ['Diflucan'],
    nameTh: 'ฟลูโคนาโซล',
    category: DrugCategory.antibiotic,
    requiresRenalAdjustment: true,
    requiresHepaticCaution: true,
    severeInteractions: ['Amiodarone (QT prolongation)', 'Warfarin (Increases INR)', 'Statins'],
    specialNotes: 'Strong CYP inhibitor. Reduce dose by 50% if CrCl <= 50 mL/min (except single dose for vaginal candidiasis).',
    specialNotesTh: 'ยารบกวนเอนไซม์ตับรุนแรง ยาตีกันเยอะมาก ต้องลดโดสลง 50% หาก CrCl <= 50',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Candidiasis (Systemic)',
        dosingType: DosingType.fixed,
        fixedDose: 400.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q24h,
        limits: DoseLimit(maxDailyDose: 800.0),
        renalAdjustments: [
          RenalAdjustment(crclMin: 0, crclMax: 50, action: RenalAction.adjust, adjustmentFactor: 0.5, notes: 'Reduce daily dose by 50%'),
        ],
      ),
    ],
  ),
  const Drug(
    id: 'ceftazidime',
    genericName: 'Ceftazidime',
    brandNames: ['Fortum'],
    nameTh: 'เซฟตาซิดีม',
    category: DrugCategory.antibiotic,
    requiresRenalAdjustment: true,
    specialNotes: 'Anti-pseudomonal cephalosporin. Risk of neurotoxicity/seizures if dose not adjusted in renal failure.',
    specialNotesTh: 'ยาคลุมเชื้อดื้อยา Pseudomonas ต้องปรับโดสในคนไข้ไตวาย ป้องกันอาการชัก',
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Severe Infection / Pseudomonas',
        dosingType: DosingType.fixed,
        fixedDose: 2000.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q8h,
        limits: DoseLimit(maxDailyDose: 6000.0),
        renalAdjustments: [
          RenalAdjustment(crclMin: 30, crclMax: 50, action: RenalAction.adjust, absoluteDose: 1000.0, adjustedFrequency: Frequency.q12h, notes: '1 g q12h'),
          RenalAdjustment(crclMin: 16, crclMax: 30, action: RenalAction.adjust, absoluteDose: 1000.0, adjustedFrequency: Frequency.q24h, notes: '1 g q24h'),
          RenalAdjustment(crclMin: 6, crclMax: 16, action: RenalAction.adjust, absoluteDose: 500.0, adjustedFrequency: Frequency.q24h, notes: '500 mg q24h'),
          RenalAdjustment(crclMin: 0, crclMax: 6, action: RenalAction.adjust, absoluteDose: 500.0, adjustedFrequency: Frequency.q48h, notes: '500 mg q48h'),
        ],
      ),
    ],
  ),
  const Drug(
    id: 'rifampin',
    genericName: 'Rifampin (Rifampicin)',
    brandNames: ['Rifadin', 'Rimactane'],
    nameTh: 'ไรแฟมพิน (ยารักษาวัณโรค)',
    category: DrugCategory.antibiotic,
    requiresHepaticCaution: true,
    isHighAlert: true,
    severeInteractions: [
      'Apixaban / Rivaroxaban (Decreases DOAC levels - Avoid)',
      'Warfarin (Decreases INR significantly)',
      'Oral Contraceptives (Decreases effectiveness)',
      'Fluconazole / Itraconazole'
    ],
    specialNotes: 'Strong CYP450 inducer (causes many drug interactions). Causes red-orange discoloration of urine and tears. Take on an empty stomach.',
    specialNotesTh: 'บอสใหญ่ยาตีกัน (รบกวนเอนไซม์ตับ) ห้ามใช้คู่กับ DOACs หรือต้องปรับยาอื่น ปัสสาวะและน้ำตาจะเปลี่ยนเป็นสีส้มแดง',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Tuberculosis Treatment',
        dosingType: DosingType.weightBased,
        dosePerKg: 10.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q24h,
        limits: DoseLimit(maxSingleDose: 600.0, maxDailyDose: 600.0), // Max 600 mg/day
      ),
    ],
  ),
  const Drug(
    id: 'isoniazid',
    genericName: 'Isoniazid (INH)',
    brandNames: ['Isoniazid'],
    nameTh: 'ไอโซไนอาซิด (ยารักษาวัณโรค)',
    category: DrugCategory.antibiotic,
    requiresHepaticCaution: true,
    severeInteractions: ['Phenytoin / Carbamazepine (Increases toxicity)', 'Alcohol (Severe hepatotoxicity)'],
    contraindications: ['Active liver disease', 'Severe adverse reaction to INH previously'],
    specialNotes: 'High risk of hepatotoxicity and peripheral neuropathy. MUST supplement with Vitamin B6 (Pyridoxine).',
    specialNotesTh: 'ระวังตับอักเสบรุนแรง และชาปลายมือปลายเท้า **ต้องจ่ายคู่กับ Vitamin B6 เสมอ**',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Tuberculosis Treatment',
        dosingType: DosingType.weightBased,
        dosePerKg: 5.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q24h,
        limits: DoseLimit(maxSingleDose: 300.0, maxDailyDose: 300.0), // Max 300 mg/day
      ),
    ],
  ),
  const Drug(
    id: 'pyrazinamide',
    genericName: 'Pyrazinamide (PZA)',
    brandNames: ['Pyrazinamide'],
    nameTh: 'ไพราซินาไมด์ (ยารักษาวัณโรค)',
    category: DrugCategory.antibiotic,
    requiresHepaticCaution: true,
    requiresRenalAdjustment: true,
    severeInteractions: ['Rifampin (Increases hepatotoxicity risk)'],
    contraindications: ['Severe hepatic damage', 'Acute gout'],
    specialNotes: 'Causes hyperuricemia (high uric acid) and joint pain. Extremely hepatotoxic.',
    specialNotesTh: 'ทำให้กรดยูริกสูง ปวดข้อรุนแรง และมีพิษต่อตับมากที่สุดในกลุ่มยาวัณโรค',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Tuberculosis Treatment',
        dosingType: DosingType.weightBased,
        dosePerKg: 25.0, // 20-30 mg/kg
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q24h,
        limits: DoseLimit(maxDailyDose: 2000.0), // Typically capped at ~2g
        renalAdjustments: [
          RenalAdjustment(crclMin: 0, crclMax: 30, action: RenalAction.adjust, adjustmentFactor: 1.0, adjustedFrequency: Frequency(isWeekly: true, displayEn: '3 times/week', displayTh: 'สัปดาห์ละ 3 ครั้ง'), notes: '25-35 mg/kg 3 times/week'),
        ],
      ),
    ],
  ),
  const Drug(
    id: 'ethambutol',
    genericName: 'Ethambutol (EMB)',
    brandNames: ['Myambutol'],
    nameTh: 'อีแทมบูทอล (ยารักษาวัณโรค)',
    category: DrugCategory.antibiotic,
    requiresRenalAdjustment: true,
    severeInteractions: ['Antacids (Decreases absorption)'],
    contraindications: ['Optic neuritis', 'Patients unable to report visual changes (e.g., young children)'],
    specialNotes: 'High risk of optic neuritis (decreased visual acuity, red-green color blindness). Requires renal dose adjustment.',
    specialNotesTh: 'ผลข้างเคียงสำคัญคือ **ตาบอดสี (ตาบอดสีแดง-เขียว)** หรือมองไม่ชัด ต้องตรวจตาก่อนและระหว่างใช้ยา ต้องปรับโดสในคนไข้ไตวาย',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Tuberculosis Treatment',
        dosingType: DosingType.weightBased,
        dosePerKg: 15.0, // 15-20 mg/kg
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q24h,
        limits: DoseLimit(maxDailyDose: 1600.0), // Max usually around 1.6g
        renalAdjustments: [
          RenalAdjustment(crclMin: 0, crclMax: 30, action: RenalAction.adjust, adjustmentFactor: 1.0, adjustedFrequency: Frequency(isWeekly: true, displayEn: '3 times/week', displayTh: 'สัปดาห์ละ 3 ครั้ง'), notes: '15-25 mg/kg 3 times/week'),
        ],
      ),
    ],
  ),
];
