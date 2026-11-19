// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import '../../core/models/models.dart';

final List<Drug> antibiotics = [
  Drug(
    id: 'vancomycin',
    genericName: 'Vancomycin',
    brandNames: ['Vancocin'],
    nameTh: 'แวนโคมัยซิน',
    category: DrugCategory.antibiotic,
    availableStrengths: [500.0],
    requiresRenalAdjustment: true,
    isHighAlert: false,
    requiresTDM: true,
    sourceCitation: 'The Sanford Guide to Antimicrobial Therapy 2024 / สมาคมโรคไตแห่งประเทศไทย',
    lastReviewedDate: '2024-10-12',
    provenance: const Provenance(
      source: 'The Sanford Guide to Antimicrobial Therapy 2024 (54th Ed.)',
      reviewedBy: 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
      reviewedAt: '2024-10-12',
      sourceDetail: 'Table 10A (Initial Dosing), Table 10B (Renal Impairment & ESRD), Table 17B (TDM)',
    ),
    monograph: const ClinicalMonograph(
      textbookName: 'The Sanford Guide to Antimicrobial Therapy',
      editionYear: '54th Edition, 2024',
      sectionOrTable: 'Table 10A & 10B (Vancomycin Dosing & Renal Adjustments)',
      dosingGuideline:
          '• ขนาดยาเริ่มต้น (Loading Dose ในผู้ป่วยวิกฤต): 25–30 mg/kg (คำนวณตามน้ำหนักจริง Actual Body Weight, สูงสุดไม่เกิน 2,000–3,000 mg)\n'
          '• ขนาดยาต่อเนื่อง (Maintenance Dose): 15–20 mg/kg ทุก 8–12 ชม. (สำหรับผู้ที่การทำงานของไตปกติ)\n'
          '• เป้าหมายระดับยา (TDM Target): AUC24/MIC 400–600 mg·h/L หรือ Trough level 15–20 mcg/mL ในการติดเชื้อรุนแรง (MRSA Bacteremia, Sepsis, Infective Endocarditis, Hospital-Acquired Pneumonia)',
      renalGuideline:
          '• CrCl 50–90 mL/min: 15 mg/kg ทุก 12–24 ชม.\n'
          '• CrCl 20–49 mL/min: 15 mg/kg ทุก 24 ชม.\n'
          '• CrCl 10–19 mL/min: 15 mg/kg ทุก 48–72 ชม.\n'
          '• CrCl < 10 mL/min / ผู้ป่วยฟอกเลือด (Hemodialysis): Loading dose 20–25 mg/kg ครั้งแรก จากนั้นให้ยาซ้ำ 500–1,000 mg เฉพาะเมื่อเจาะตรวจระดับยา TDM ก่อนฟอกไตแล้วพบว่าต่ำกว่า 15–20 mcg/mL',
      administrationGuideline:
          '• การผสมยา (Dilution): ละลายผงยาด้วย Sterile Water for Injection 10 mL ต่อ 500 mg แล้วเจือจางต่อใน NSS หรือ D5W ให้ความเข้มข้นไม่เกิน 5 mg/mL (หากจำกัดสารน้ำและให้ทาง Central line อาจเข้มข้นได้ถึง 10 mg/mL)\n'
          '• อัตราการหยด (Infusion Rate): ต้องหยดช้าๆ นานอย่างน้อย 60 นาที หรือไม่เกิน 10 mg/นาที (เช่น 1,000 mg หยดอย่างน้อย 60 นาที, 1,500 mg หยดอย่างน้อย 90 นาที, 2,000 mg หยดอย่างน้อย 120 นาที) เพื่อป้องกันภาวะ Red Man Syndrome',
      clinicalNotes:
          '• จัดเป็นยาเตือนภัยสูง (High-Alert Drug)\n'
          '• พิษต่อไต (Nephrotoxicity) เพิ่มสูงขึ้นชัดเจนเมื่อใช้ร่วมกับ Piperacillin/Tazobactam, Aminoglycosides, Colistin, หรือ Amphotericin B\n'
          '• ต้องเจาะ Trough level ก่อนการให้ยามื้อที่ 4 หรือ 5 (เมื่อเข้าสู่ภาวะ Steady State)',
      externalUrl: 'https://www.sanfordguide.com',
    ),
    specialNotes: 'Red man syndrome with rapid infusion. Target trough 15-20 mcg/mL for severe infections.',
    specialNotesTh: 'ระวัง Red man syndrome หากดริปเร็วไป. เป้าหมายระดับยา 15-20 mcg/mL ในการติดเชื้อรุนแรง',
    ivDiluentCompatibility: const IvDiluentCompatibility(
      compatibleDiluents: [IvDiluent.nss, IvDiluent.d5w, IvDiluent.lrs],
      preferredDiluent: IvDiluent.nss,
      stabilityNoteEn:
          'Reconstitute with SWFI; dilute in NSS/D5W to <=5 mg/mL (<=10 mg/mL via central line if fluid-restricted). Infuse over >=60 min (<=10–15 mg/min).',
      stabilityNoteTh:
          'ละลายด้วย SWFI; เจือจางใน NSS/D5W <=5 mg/mL (จำกัดน้ำใช้ <=10 mg/mL ทาง Central Line). หยด >=60 นาที (<=10–15 mg/min)',
      sourceCitation:
          'US FDA Vancomycin HCl SPL / ASHP/IDSA Vancomycin Guidelines 2020 / คู่มือยาฉีดรามาธิบดี',
    ),
    interactions: const [
      DrugInteraction(
        targetDrugId: 'piperacillin_tazobactam',
        severity: InteractionSeverity.major,
        mechanismEn:
            'Synergistic tubular toxicity causing Acute Interstitial Nephritis (AIN) and acute kidney injury (3-4x higher risk vs vancomycin + cefepime/meropenem).',
        mechanismTh:
            'เสริมพิษต่อท่อไตทำให้เกิด Acute Interstitial Nephritis และเพิ่มความเสี่ยงไตวายเฉียบพลัน (AKI) สูงขึ้น 3-4 เท่า',
        managementEn:
            'Monitor serum creatinine and urine output daily. Consider cefepime or meropenem instead of piperacillin/tazobactam in high-risk patients.',
        managementTh:
            'ติดตามค่าไต (SCr) และปริมาณปัสสาวะทุกวัน พิจารณาเลี่ยงไปใช้ Cefepime หรือ Meropenem แทนในผู้ป่วยกลุ่มเสี่ยง',
        source: 'ASHP/IDSA Vancomycin Guidelines 2020 / Sanford Guide 2024',
      ),
      DrugInteraction(
        targetDrugId: 'gentamicin',
        severity: InteractionSeverity.major,
        mechanismEn:
            'Additive nephrotoxicity (proximal renal tubular necrosis) and ototoxicity.',
        mechanismTh:
            'เสริมพิษต่อไต (ทำลายเซลล์ท่อไตส่วนต้น) และเพิ่มความเสี่ยงพิษต่อการได้ยิน',
        managementEn:
            'Monitor serum creatinine and TDM concentrations closely.',
        managementTh:
            'ติดตามค่าการทำงานของไต (SCr) และตรวจวัดระดับยาในเลือด (TDM) อย่างใกล้ชิด',
        source: 'Lexicomp / Sanford Guide 2024',
      ),
    ],
    doseRules: [
      DoseRule(
        id: 'vancomycin_esrd_hemodialysis',
        name: 'Vancomycin ESRD / Hemodialysis Pulse Dosing Protocol (CrCl < 10 mL/min)',
        sourceCitation: 'Rybak MJ et al. Therapeutic monitoring of vancomycin: 2020 update. Am J Health-Syst Pharm 2020;77(11):835–864',
        verificationStatus: VerificationStatus.verified,
        applies: (ctx) => ctx.crclMlMin != null && ctx.crclMlMin! < 10.0,
        evaluate: (ctx) {
          final crcl = ctx.crclMlMin!;
          return DoseRuleResult(
            warnings: [
              DoseWarning(
                severity: LimitSeverity.soft,
                code: DoseWarningCode.severeRenalImpairment,
                messageEn:
                    'ESRD / HEMODIALYSIS (CrCl ${crcl.toStringAsFixed(1)} mL/min): Vancomycin clearance is severely reduced. Do NOT dose on a fixed schedule. Follow TDM pulse dosing: Loading dose 20–25 mg/kg, check pre-dialysis trough, and redose 500–1000 mg only when trough < 15–20 mcg/mL.',
                messageTh:
                    'ไตวายระยะสุดท้าย / ฟอกเลือด (CrCl ${crcl.toStringAsFixed(1)} มล./นาที): การขจัดยา Vancomycin ลดลงอย่างมาก ห้ามให้ยาตามเวลาปกติ ให้ใช้การบริหารยาแบบ TDM Pulse Dosing: Loading dose 20–25 มก./กก., เจาะ trough ก่อนฟอกไต และให้ซ้ำ 500–1000 มก. เมื่อ trough < 15–20 mcg/mL เท่านั้น',
                calculatedValue: crcl,
                unit: 'mL/min',
              ),
            ],
          );
        },
      ),
    ],
    regimens: [
      const DosingRegimen(
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
        formulation: DrugFormulation.ivInfusion,
        reconstitution: ReconstitutionInfo(
          vialStrengthMg: 500.0,
          diluentName: 'Sterile Water for Injection (SWFI)',
          diluentVolumeMl: 10.0,
          resultingConcentrationMgPerMl: 50.0,
          instructionsEn:
              'Reconstitute 500 mg vial with 10 mL SWFI (or 1 g vial with 20 mL SWFI) to yield 50 mg/mL.',
          instructionsTh:
              'ละลายผงยา 500 มก. ด้วยน้ำกลั่นสำหรับฉีดยา 10 มล. (หรือ 1 กรัม ด้วย 20 มล.) ได้ความเข้มข้น 50 มก./มล.',
          sourceCitation:
              'Drug Information Handbook (Lexicomp) 2024 / The Sanford Guide to Antimicrobial Therapy 2024',
        ),
        reconstitutionConcentrationMgPerMl: 50.0,
        standardDilutionBagMl: 250.0,
        standardDilutionMgPerMl: 5.0,
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
        renalReplacementProtocols: [
          RenalReplacementProtocol(
            mode: RenalReplacementMode.ihd,
            doseFactor: 0.5,
            frequency: Frequency(
              isPrn: true,
              displayEn: 'Post-HD TDM-guided redosing',
              displayTh: 'บริหารซ้ำหลังฟอกไตตาม TDM',
              kind: FrequencyKind.prn,
            ),
            requiresPostHdSupplement: true,
            clinicalInstructionEn:
                'High-flux HD removes 30–45% of vancomycin. Initial loading dose 20–25 mg/kg (max 2,000–3,000 mg). Maintenance: 500–1,000 mg (7.5–10 mg/kg) IV POST-hemodialysis only when pre-dialysis serum trough is < 15–20 mcg/mL.',
            clinicalInstructionTh:
                'ตัวกรอง High-flux ขจัดยาออก 30–45% ขนาดยาเริ่มต้น (Loading) 20–25 มก./กก. (สูงสุด 2,000–3,000 มก.) ขนาดยาต่อเนื่อง: 500–1,000 มก. (7.5–10 มก./กก.) IV หลังฟอกเลือดเสร็จเฉพาะเมื่อระดับยา TDM ก่อนฟอกไต < 15–20 mcg/mL',
            provenance: Provenance(
              source: 'The Sanford Guide 2024 Table 10B/17B / ASHP/IDSA 2020 Guidelines / Lexicomp 2024',
              reviewedBy: 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
              reviewedAt: '2024-10-29',
            ),
          ),
          RenalReplacementProtocol(
            mode: RenalReplacementMode.capd,
            specificDose: 1000.0,
            doseUnit: DoseUnit.mg,
            frequency: Frequency(
              minIntervalHours: 120,
              maxIntervalHours: 168,
              displayEn: 'Every 5–7 days (TDM-guided)',
              displayTh: 'ทุก 5–7 วัน (ตามผล TDM)',
              kind: FrequencyKind.custom,
              customReason: 'Peritoneal clearance is minimal; redose based on weekly trough',
            ),
            requiresPostHdSupplement: false,
            clinicalInstructionEn:
                'Loading dose 20–25 mg/kg IV once, then 1,000–1,500 mg IV every 5–7 days guided by weekly serum trough (target 15–20 mcg/mL). (For CAPD peritonitis, 1,000 mg IP per bag every 5–7 days).',
            clinicalInstructionTh:
                'Loading dose 20–25 มก./กก. IV ครั้งแรก จากนั้น 1,000–1,500 มก. IV ทุก 5–7 วัน ตามระดับยา TDM รายสัปดาห์ (เป้าหมาย 15–20 mcg/mL) (หากเป็นเยื่อบุช่องท้องอักเสบ ให้ 1,000 มก. IP ต่อน้ำยา 1 ถุง ทุก 5–7 วัน)',
            provenance: Provenance(
              source: 'The Sanford Guide 2024 Table 10B / Lexicomp 2024',
              reviewedBy: 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
              reviewedAt: '2024-10-29',
            ),
          ),
          RenalReplacementProtocol(
            mode: RenalReplacementMode.crrt,
            doseFactor: 1.0,
            frequency: Frequency.q12hTo24h,
            requiresPostHdSupplement: false,
            clinicalInstructionEn:
                'CRRT (CVVH/CVVHD/CVVHDF): Loading dose 20–25 mg/kg (max 2,000 mg), then maintenance 10–15 mg/kg q12–24h (typical 1,000–1,500 mg/day or continuous infusion 500–1,000 mg q12h). Check serum trough at 24h; target AUC24 400–600 mg·h/L or trough 15–20 mcg/mL. Daily TDM mandatory.',
            clinicalInstructionTh:
                'CRRT (CVVH/CVVHD/CVVHDF): Loading dose 20–25 มก./กก. (สูงสุด 2,000 มก.) จากนั้น maintenance 10–15 มก./กก. ทุก 12–24 ชม. (ทั่วไป 1,000–1,500 มก./วัน) เจาะตรวจระดับยาที่ 24 ชม. ตั้งเป้า AUC 400–600 (Trough 15–20 mcg/mL) ต้องเจาะ TDM ติดตามทุกวัน',
            provenance: Provenance(
              source: 'The Sanford Guide 2024 Table 10B/17B / ASHP 2020 Guidelines / KDIGO 2023',
              reviewedBy: 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
              reviewedAt: '2024-10-29',
            ),
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
    isHighAlert: false,
    sourceCitation: 'The Sanford Guide to Antimicrobial Therapy 2024 / Hartford Nomogram',
    lastReviewedDate: '2024-10-12',
    provenance: Provenance(
      source: 'The Sanford Guide to Antimicrobial Therapy 2024 (Table 10D: Aminoglycoside Dosing)',
      reviewedBy: 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
      reviewedAt: '2024-10-12',
      sourceDetail: 'Table 10D & Nicolau DP et al. Antimicrob Agents Chemother 1995 (Hartford Nomogram)',
    ),
    monograph: ClinicalMonograph(
      textbookName: 'The Sanford Guide to Antimicrobial Therapy',
      editionYear: '54th Edition, 2024',
      sectionOrTable: 'Table 10D (Aminoglycoside Once-Daily & Conventional Dosing)',
      dosingGuideline:
          '• การบริหารยาวันละครั้ง (Once-Daily / Extended-Interval Dosing): 5–7 mg/kg IV วันละครั้ง (คำนวณตาม IBW หรือ AdjBW หากน้ำหนักจริงเกิน IBW > 20%)\n'
          '• การบริหารยาแบบเดิม (Conventional Multi-dose): 1.5–2 mg/kg IV ทุก 8 ชม. (Synergy dose ใน Enterococcal endocarditis: 1 mg/kg ทุก 8 ชม.)',
      renalGuideline:
          '• CrCl 40–59 mL/min: ให้ขนาดยาเต็ม 5 mg/kg ทุก 36 ชม. หรือปรับตาม Hartford nomogram\n'
          '• CrCl 20–39 mL/min: ให้ขนาดยาเต็ม 5 mg/kg ทุก 48 ชม.\n'
          '• CrCl < 20 mL/min: ไม่แนะนำให้ใช้แบบ Once-daily ให้เริ่มต้น dose แรก 2 mg/kg แล้วติดตามระดับยา TDM ก่อนให้มื้อต่อไป',
      administrationGuideline:
          '• การเจือจาง: เจือจางใน NSS หรือ D5W ปริมาตร 50–100 mL\n'
          '• อัตราการหยด: หยดทางหลอดเลือดดำนาน 30–60 นาที (ห้ามฉีดแบบ IV push เด็ดขาด)',
      clinicalNotes:
          '• พิษต่อหู (Ototoxicity ทั้ง Vestibular และ Cochlear) อาจเกิดขึ้นแบบถาวร (Irreversible)\n'
          '• พิษต่อไต (Nephrotoxicity): มักเป็นแบบ Acute tubular necrosis สัมพันธ์กับขนาดยาสะสมและ Trough ที่สูง\n'
          '• เป้าหมายระดับยา: Once-daily trough < 1 mcg/mL (เจาะก่อนให้ยามื้อถัดไป), Peak 16–24 mcg/mL',
      externalUrl: 'https://www.sanfordguide.com',
    ),
    specialNotes:
        'Use IBW or AdjBW for dosing. Ototoxicity and nephrotoxicity risk.',
    specialNotesTh: 'ใช้น้ำหนัก IBW หรือ AdjBW. ระวังพิษต่อหูและไต',
    ivDiluentCompatibility: IvDiluentCompatibility(
      compatibleDiluents: [IvDiluent.nss, IvDiluent.d5w],
      preferredDiluent: IvDiluent.nss,
      stabilityNoteEn:
          'Dilute in 50–200 mL NSS/D5W; infuse over 30–60 min. Do not mix or co-infuse via Y-site with beta-lactams.',
      stabilityNoteTh:
          'เจือจางใน NSS/D5W 50–200 mL; หยด 30–60 นาที. ห้ามผสมถุงเดียวกันหรือให้ร่วม Y-site กับ Beta-lactams',
      sourceCitation:
          'The Sanford Guide 2024 / US FDA Gentamicin Sulfate SPL / Trissel\'s Handbook',
    ),
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Extended Interval Dosing',
        dosingType: DosingType.weightBased,
        dosingWeightStrategy: DosingWeightStrategy.adjustedIfObese,
        dosePerKg: 5.0, // 5-7 mg/kg
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q24h,
        formulation: DrugFormulation.ivInfusion,
        reconstitutionConcentrationMgPerMl: 40.0,
        standardDilutionBagMl: 100.0,
        infusionTimeMinutes: 60.0,
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
            adjustmentFactor: 0.4, // 2 mg/kg initial dose (0.4 * 5.0 mg/kg)
            adjustedFrequency: Frequency.q48h,
            notes: 'Once-daily not recommended in CrCl < 20 mL/min. Give 2 mg/kg initial dose then re-dose by serum TDM levels (typically q48h+).',
            notesTh: 'ไม่แนะนำให้แบบ Once-daily ใน CrCl < 20 mL/min ให้เริ่มต้น 2 mg/kg แล้วตรวจติดตามระดับยา TDM ก่อนให้มื้อถัดไป',
          ),
        ],
        renalReplacementProtocols: [
          RenalReplacementProtocol(
            mode: RenalReplacementMode.ihd,
            doseFactor: 0.4, // 2 mg/kg
            frequency: Frequency(
              isPrn: true,
              displayEn: 'Post-HD TDM-guided redosing',
              displayTh: 'บริหารซ้ำหลังฟอกไตตาม TDM',
              kind: FrequencyKind.prn,
            ),
            requiresPostHdSupplement: true,
            clinicalInstructionEn:
                'Loading dose 1.5–2 mg/kg IV once. Maintenance: 1–1.5 mg/kg IV POST-hemodialysis on dialysis days, guided by pre-HD serum concentrations (redose when trough < 1–2 mcg/mL). Hemodialysis removes ~50% of drug.',
            clinicalInstructionTh:
                'Loading dose 1.5–2 มก./กก. IV ครั้งแรก ขนาดยาต่อเนื่อง: 1–1.5 มก./กก. IV หลังฟอกเลือดเสร็จในวันที่มีการฟอกไต ให้ยาซ้ำตามระดับยา TDM ก่อนฟอกไต (ให้ซ้ำเมื่อ trough < 1–2 mcg/mL) การฟอกเลือดขจัดยาออก ~50%',
            provenance: Provenance(
              source: 'The Sanford Guide 2024 Table 10B/10D / Lexicomp 2024',
              reviewedBy: 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
              reviewedAt: '2024-10-29',
            ),
          ),
          RenalReplacementProtocol(
            mode: RenalReplacementMode.capd,
            doseFactor: 0.3, // 1.5 mg/kg
            frequency: Frequency.q48h,
            requiresPostHdSupplement: false,
            clinicalInstructionEn:
                'Initial dose 1.5–2 mg/kg IV once, then 1–1.5 mg/kg IV every 48–72h guided by serum trough (< 1 mcg/mL). (For peritonitis, instill 4–8 mg/L per dialysate bag).',
            clinicalInstructionTh:
                'ขนาดเริ่มต้น 1.5–2 มก./กก. IV ครั้งแรก จากนั้นให้ 1–1.5 มก./กก. IV ทุก 48–72 ชม. ตามระดับ TDM ในเลือด (เป้าหมาย trough < 1 mcg/mL) (หากเป็นเยื่อบุช่องท้องอักเสบ ให้ผสม 4–8 มก./ลิตร ต่อน้ำยา 1 ถุง)',
            provenance: Provenance(
              source: 'The Sanford Guide 2024 Table 10B / Lexicomp 2024',
              reviewedBy: 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
              reviewedAt: '2024-10-29',
            ),
          ),
          RenalReplacementProtocol(
            mode: RenalReplacementMode.crrt,
            doseFactor: 0.4, // 2 mg/kg
            frequency: Frequency.q24h,
            requiresPostHdSupplement: false,
            clinicalInstructionEn:
                'CRRT (CVVH/CVVHD/CVVHDF): Loading dose 2.5–3 mg/kg IV once. Maintenance: 1.5–2 mg/kg IV q24–48h strictly guided by TDM (target peak 16–24 mcg/mL, trough < 1–2 mcg/mL before redosing). CRRT clears gentamicin rapidly.',
            clinicalInstructionTh:
                'CRRT (CVVH/CVVHD/CVVHDF): Loading dose 2.5–3 มก./กก. IV ครั้งแรก ขนาดยาต่อเนื่อง: 1.5–2 มก./กก. IV ทุก 24–48 ชม. ติดตามระดับยา TDM อย่างเคร่งครัด (เป้าหมาย Trough < 1–2 mcg/mL ก่อนให้มื้อถัดไป) CRRT ขจัดยาเจนตามัยซินได้อย่างรวดเร็ว',
            provenance: Provenance(
              source: 'The Sanford Guide 2024 Table 10B/10D / KDIGO 2023 / Lexicomp 2024',
              reviewedBy: 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
              reviewedAt: '2024-10-29',
            ),
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
        renalAdjustments: [
          RenalAdjustment(
            crclMin: 40,
            crclMax: 60,
            adjustmentFactor: 1.0,
            adjustedFrequency: Frequency.q12h,
          ),
          RenalAdjustment(
            crclMin: 20,
            crclMax: 40,
            adjustmentFactor: 1.0,
            adjustedFrequency: Frequency.q24h,
          ),
          RenalAdjustment(
            crclMin: 0,
            crclMax: 20,
            adjustmentFactor: 1.0,
            adjustedFrequency: Frequency.q48h,
            notes: 'Give single 1.5–2 mg/kg dose then monitor serum TDM levels before redosing (q48h+)',
            notesTh: 'ให้ขนาดยาเริ่มต้น 1.5–2 mg/kg แล้วตรวจติดตามระดับยา TDM ในเลือดก่อนให้มื้อถัดไป (มักห่างกัน ≥ 48 ชม.)',
          ),
        ],
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
    isHighAlert: false,
    sourceCitation: 'The Sanford Guide to Antimicrobial Therapy 2024 / Hartford Nomogram',
    lastReviewedDate: '2024-10-12',
    provenance: Provenance(
      source: 'The Sanford Guide to Antimicrobial Therapy 2024 (Table 10D: Aminoglycoside Dosing)',
      reviewedBy: 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
      reviewedAt: '2024-10-12',
      sourceDetail: 'Table 10D & Nicolau DP et al. Antimicrob Agents Chemother 1995 (Hartford Nomogram)',
    ),
    monograph: ClinicalMonograph(
      textbookName: 'The Sanford Guide to Antimicrobial Therapy',
      editionYear: '54th Edition, 2024',
      sectionOrTable: 'Table 10D (Aminoglycoside Once-Daily & Conventional Dosing)',
      dosingGuideline:
          '• การบริหารยาวันละครั้ง (Once-Daily / Extended-Interval Dosing): 15 mg/kg IV วันละครั้ง (คำนวณตาม IBW หรือ AdjBW หากน้ำหนักจริงเกิน IBW ≥ 20%)\n'
          '• การบริหารยาแบบแบ่งมื้อ (Conventional Dosing): 5–7.5 mg/kg IV ทุก 8–12 ชม.',
      renalGuideline:
          '• CrCl 40–59 mL/min: ให้ขนาดยา 15 mg/kg ทุก 36 ชม. หรือปรับตาม Hartford Nomogram (หารระดับยาด้วย 2 ก่อนเทียบกราฟ)\n'
          '• CrCl 20–39 mL/min: ให้ขนาดยา 15 mg/kg ทุก 48 ชม.\n'
          '• CrCl < 20 mL/min: ให้เริ่มต้น 7.5 mg/kg แล้วตรวจติดตามระดับยา TDM ก่อนให้มื้อถัดไป',
      administrationGuideline:
          '• การเจือจาง: เจือจางใน NSS หรือ D5W ปริมาตร 100–200 mL\n'
          '• อัตราการหยด: หยดทางหลอดเลือดดำนาน 30–60 นาที',
      clinicalNotes:
          '• เฝ้าระวังพิษต่อไต (Nephrotoxicity) และพิษต่อหู (Ototoxicity)\n'
          '• เป้าหมายระดับยา Once-daily: Peak 40–60 mcg/mL, Trough < 2.5 mcg/mL (Conventional: Peak 20–35 mcg/mL, Trough < 5–10 mcg/mL)',
      externalUrl: 'https://www.sanfordguide.com',
    ),
    ivDiluentCompatibility: IvDiluentCompatibility(
      compatibleDiluents: [IvDiluent.nss, IvDiluent.d5w, IvDiluent.lrs],
      preferredDiluent: IvDiluent.nss,
      stabilityNoteEn:
          'Dilute in 100–200 mL NSS/D5W; infuse over 30–60 min. Flush line before/after; do not co-infuse with beta-lactams via Y-site.',
      stabilityNoteTh:
          'เจือจางใน NSS/D5W 100–200 mL; หยด 30–60 นาที. Flush สายก่อนและหลัง; ห้ามให้ร่วม Y-site กับ Beta-lactams',
      sourceCitation:
          'The Sanford Guide 2024 / US FDA Amikin (amikacin) SPL / คู่มือยาฉีดรามาธิบดี',
    ),
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Extended Interval Dosing',
        dosingType: DosingType.weightBased,
        dosingWeightStrategy: DosingWeightStrategy.adjustedIfObese,
        dosePerKg: 15.0, // 15 mg/kg
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q24h,
        formulation: DrugFormulation.ivInfusion,
        reconstitutionConcentrationMgPerMl: 250.0,
        standardDilutionBagMl: 100.0,
        infusionTimeMinutes: 60.0,
        limits: DoseLimit(maxSingleDose: 1500.0),
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
            adjustmentFactor: 0.5,
            adjustedFrequency: Frequency.q48h,
            notes: 'Give 7.5 mg/kg initial dose then monitor serum TDM levels (typically q48h+)',
            notesTh: 'ให้ขนาดยาเริ่มต้น 7.5 mg/kg แล้วตรวจติดตามระดับยา TDM ในเลือดก่อนให้มื้อถัดไป',
          ),
        ],
        renalReplacementProtocols: [
          RenalReplacementProtocol(
            mode: RenalReplacementMode.ihd,
            doseFactor: 0.5,
            frequency: Frequency(
              isPrn: true,
              displayEn: 'Post-HD TDM-guided redosing',
              displayTh: 'บริหารซ้ำหลังฟอกไตตาม TDM',
              kind: FrequencyKind.prn,
            ),
            requiresPostHdSupplement: true,
            clinicalInstructionEn:
                'Loading dose 5–7.5 mg/kg IV once. Maintenance: 5–7.5 mg/kg IV POST-hemodialysis on dialysis days, guided by pre-HD serum concentrations (redose when trough < 5–10 mcg/mL). Hemodialysis removes ~50% of drug.',
            clinicalInstructionTh:
                'Loading dose 5–7.5 มก./กก. IV ครั้งแรก ขนาดยาต่อเนื่อง: 5–7.5 มก./กก. IV หลังฟอกเลือดเสร็จในวันที่มีการฟอกไต ให้ยาซ้ำตามระดับยา TDM ก่อนฟอกไต (ให้ซ้ำเมื่อ trough < 5–10 mcg/mL) การฟอกเลือดขจัดยาออก ~50%',
            provenance: Provenance(
              source: 'The Sanford Guide 2024 Table 10B/10D / Lexicomp 2024',
              reviewedBy: 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
              reviewedAt: '2024-10-29',
            ),
          ),
          RenalReplacementProtocol(
            mode: RenalReplacementMode.capd,
            doseFactor: 0.5,
            frequency: Frequency.q48h,
            requiresPostHdSupplement: false,
            clinicalInstructionEn:
                'Initial dose 7.5 mg/kg IV once, then redose based on serum levels (typically q48–72h when trough < 5 mcg/mL). (For peritonitis, instill 25 mg/L per dialysate bag).',
            clinicalInstructionTh:
                'ขนาดเริ่มต้น 7.5 มก./กก. IV ครั้งแรก จากนั้นให้ยาซ้ำตามระดับยา TDM ในเลือด (ทั่วไปทุก 48–72 ชม. เมื่อ trough < 5 mcg/mL) (หากเป็นเยื่อบุช่องท้องอักเสบ ให้ผสม 25 มก./ลิตร ต่อน้ำยาฟอกไต 1 ถุง)',
            provenance: Provenance(
              source: 'The Sanford Guide 2024 Table 10B / Lexicomp 2024',
              reviewedBy: 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
              reviewedAt: '2024-10-29',
            ),
          ),
          RenalReplacementProtocol(
            mode: RenalReplacementMode.crrt,
            doseFactor: 0.5,
            frequency: Frequency.q24h,
            requiresPostHdSupplement: false,
            clinicalInstructionEn:
                'CRRT (CVVH/CVVHD/CVVHDF): Loading dose 10–15 mg/kg IV once. Maintenance: 7.5–10 mg/kg IV q24–48h strictly guided by TDM. Target peak 40–60 mcg/mL, trough < 5 mcg/mL before redosing. CRRT sieving coefficient is ~0.8–0.9.',
            clinicalInstructionTh:
                'CRRT (CVVH/CVVHD/CVVHDF): Loading dose 10–15 มก./กก. IV ครั้งแรก ขนาดยาต่อเนื่อง: 7.5–10 มก./กก. IV ทุก 24–48 ชม. ติดตามระดับยา TDM อย่างเคร่งครัด (เป้าหมาย Peak 40–60 mcg/mL, Trough < 5 mcg/mL ก่อนให้มื้อถัดไป) ค่า Sieving coefficient ใน CRRT สูง ~0.8–0.9',
            provenance: Provenance(
              source: 'The Sanford Guide 2024 Table 10B/10D / KDIGO 2023 / Lexicomp 2024',
              reviewedBy: 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
              reviewedAt: '2024-10-29',
            ),
          ),
        ],
      ),
    ],
  ),
  Drug(
    id: 'meropenem',
    genericName: 'Meropenem',
    brandNames: ['Meronem'],
    nameTh: 'เมโรพีเนม',
    category: DrugCategory.antibiotic,
    availableStrengths: [500.0, 1000.0],
    requiresRenalAdjustment: true,
    drugClass: DrugClass.betaLactamCarbapenem,
    sourceCitation: 'The Sanford Guide to Antimicrobial Therapy 2024 / Merrem FDA Prescribing Information',
    lastReviewedDate: '2024-10-12',
    provenance: const Provenance(
      source: 'The Sanford Guide to Antimicrobial Therapy 2024 / FDA Merrem Label §2.2',
      reviewedBy: 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
      reviewedAt: '2024-10-12',
      sourceDetail: 'Table 10A (Carbapenems) & Merrem Label §2.2',
    ),
    monograph: const ClinicalMonograph(
      textbookName: 'The Sanford Guide to Antimicrobial Therapy',
      editionYear: '54th Edition, 2024',
      sectionOrTable: 'Table 10A (Meropenem Dosage & Renal Adjustments)',
      dosingGuideline:
          '• การติดเชื้อรุนแรงทั่วไป (Severe Systemic Infections): 1,000 mg IV ทุก 8 ชม.\n'
          '• เยื่อหุ้มสมองอักเสบ (Bacterial Meningitis) หรือเชื้อดื้อยา (Pseudomonas): 2,000 mg IV ทุก 8 ชม.\n'
          '• การให้ยาแบบ Extended Infusion (ดริปนาน 3 ชม.) ช่วยเพิ่มค่า Time-above-MIC ในผู้ป่วย Sepsis/ICU',
      renalGuideline:
          '• CrCl > 50 mL/min: 1,000 mg ทุก 8 ชม. (ปกติ)\n'
          '• CrCl 26–50 mL/min: 1,000 mg ทุก 12 ชม.\n'
          '• CrCl 10–25 mL/min: 500 mg ทุก 12 ชม.\n'
          '• CrCl < 10 mL/min / Hemodialysis: 500 mg ทุก 24 ชม. (ในวันฟอกไต ให้ยาหลังฟอกเสร็จ)',
      administrationGuideline:
          '• ละลายผงยา 1,000 mg ด้วย NSS หรือ Sterile water 20 mL แล้วเจือจางต่อใน NSS หรือ D5W 100 mL\n'
          '• ระยะเวลาหยด: หยดทางหลอดเลือดดำนาน 30 นาที (Intermittent) หรือ 3 ชม. (Extended Infusion)',
      clinicalNotes:
          '• ข้อห้ามใช้สำคัญ (Contraindication): ห้ามใช้ร่วมกับยากันชัก Valproic acid (Sodium valproate) โดยเด็ดขาด เนื่องจาก Meropenem ทำให้ระดับยา Valproate ในเลือดตกลงอย่างรวดเร็ว (ลดลง 60–90%) จนเกิดอาการชักรุนแรง\n'
          '• เสี่ยงชักเพิ่มขึ้นในผู้ป่วยที่มีภาวะไตบกพร่องและไม่ได้ปรับลดขนาดยา',
      externalUrl: 'https://www.sanfordguide.com',
    ),
    ivDiluentCompatibility: const IvDiluentCompatibility(
      compatibleDiluents: [IvDiluent.nss, IvDiluent.d5w],
      preferredDiluent: IvDiluent.nss,
      stabilityNoteEn:
          'Prefer NSS for extended infusion: stable ~4 hours at room temperature (24 hours refrigerated); D5W stable ~1 hour at room temperature.',
      stabilityNoteTh:
          'การหยดยาวแนะนำ NSS: คงตัว ~4 ชม. ที่อุณหภูมิห้อง (แช่เย็น 24 ชม.); D5W คงตัว ~1 ชม. ที่อุณหภูมิห้อง',
      sourceCitation:
          'US FDA Merrem IV (meropenem) SPL §2.4 / Trissel\'s Handbook / คู่มือยาฉีดรามาธิบดี',
    ),
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
        formulation: DrugFormulation.ivInfusion,
        reconstitution: const ReconstitutionInfo(
          vialStrengthMg: 1000.0,
          diluentName: 'SWFI or 0.9% NSS',
          diluentVolumeMl: 20.0,
          resultingConcentrationMgPerMl: 50.0,
          instructionsEn:
              'Reconstitute 1 g vial with 20 mL SWFI or NSS (or 500 mg vial with 10 mL) to yield 50 mg/mL.',
          instructionsTh:
              'ละลายผงยา 1 กรัม ด้วยน้ำกลั่นหรือ NSS 20 มล. (หรือ 500 มก. ด้วย 10 มล.) ได้ความเข้มข้น 50 มก./มล.',
          sourceCitation:
              'Drug Information Handbook (Lexicomp) 2024 / The Sanford Guide 2024',
        ),
        reconstitutionConcentrationMgPerMl: 50.0,
        standardDilutionBagMl: 100.0,
        standardDilutionMgPerMl: 10.0,
        infusionTimeMinutes: 30.0,
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
        renalReplacementProtocols: const [
          RenalReplacementProtocol(
            mode: RenalReplacementMode.ihd,
            specificDose: 500.0,
            doseUnit: DoseUnit.mg,
            frequency: Frequency.q24h,
            requiresPostHdSupplement: true,
            clinicalInstructionEn:
                '500 mg IV q24h. On hemodialysis days, administer dose immediately POST-hemodialysis (approx. 50% cleared by HD; for severe/Pseudomonas infection, 1,000 mg post-HD may be used).',
            clinicalInstructionTh:
                '500 mg IV ทุก 24 ชม. ในวันที่มีการฟอกไต ให้บริหารยาทันทีหลังฟอกเลือดเสร็จ (การฟอกเลือดขจัดยาออก ~50%; หากเป็นการติดเชื้อรุนแรงหรือ Pseudomonas สามารถปรับเป็น 1,000 mg หลังฟอกได้)',
            provenance: Provenance(
              source: 'The Sanford Guide to Antimicrobial Therapy 2024 Table 10B / Merrem FDA Label §2.2',
              reviewedBy: 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
              reviewedAt: '2024-10-29',
            ),
          ),
          RenalReplacementProtocol(
            mode: RenalReplacementMode.capd,
            specificDose: 500.0,
            doseUnit: DoseUnit.mg,
            frequency: Frequency.q24h,
            requiresPostHdSupplement: false,
            clinicalInstructionEn:
                '500 mg IV q24h. (For CAPD peritonitis, 125–250 mg/L dialysate may be instilled).',
            clinicalInstructionTh:
                '500 mg IV ทุก 24 ชม. (หากเป็นเยื่อบุช่องท้องอักเสบในผู้ป่วย CAPD สามารถผสมยา 125–250 mg/L ในน้ำยาฟอกไตได้)',
            provenance: Provenance(
              source: 'The Sanford Guide to Antimicrobial Therapy 2024 Table 10B / Lexicomp 2024',
              reviewedBy: 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
              reviewedAt: '2024-10-29',
            ),
          ),
          RenalReplacementProtocol(
            mode: RenalReplacementMode.crrt,
            specificDose: 1000.0,
            doseUnit: DoseUnit.mg,
            frequency: Frequency.q12h,
            requiresPostHdSupplement: false,
            clinicalInstructionEn:
                'CRRT (CVVH/CVVHD/CVVHDF): 1,000 mg IV q12h (or 1,000 mg q8h if effluent rate > 30 mL/kg/h or Pseudomonas/MDR infection). 3-hour extended infusion strongly recommended. Do not reduce to ESRD dose (500 mg q24h) to prevent fatal sepsis underdosing.',
            clinicalInstructionTh:
                'CRRT (CVVH/CVVHD/CVVHDF): 1,000 mg IV ทุก 12 ชม. (ปรับเป็น 1,000 mg ทุก 8 ชม. หาก effluent rate > 30 มล./กก./ชม. หรือติดเชื้อ Pseudomonas/เชื้อดื้อยา) แนะนำหยดยานาน 3 ชม. (Extended infusion) ห้ามลดขนาดยาเหลือ 500 mg วันละครั้งเด็ดขาดเพื่อป้องกันภาวะ underdose เสี่ยงเสียชีวิตในผู้ป่วย Sepsis',
            provenance: Provenance(
              source: 'The Sanford Guide to Antimicrobial Therapy 2024 Table 10B / KDIGO 2023 / Lexicomp 2024',
              reviewedBy: 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
              reviewedAt: '2024-10-29',
            ),
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
        formulation: DrugFormulation.ivInfusion,
        reconstitution: const ReconstitutionInfo(
          vialStrengthMg: 1000.0,
          diluentName: 'SWFI or 0.9% NSS',
          diluentVolumeMl: 20.0,
          resultingConcentrationMgPerMl: 50.0,
          instructionsEn:
              'Reconstitute 1 g vial with 20 mL SWFI or NSS to yield 50 mg/mL.',
          instructionsTh:
              'ละลายผงยา 1 กรัม ด้วยน้ำกลั่นหรือ NSS 20 มล. ได้ความเข้มข้น 50 มก./มล.',
          sourceCitation:
              'Drug Information Handbook (Lexicomp) 2024 / The Sanford Guide 2024',
        ),
        reconstitutionConcentrationMgPerMl: 50.0,
        standardDilutionBagMl: 100.0,
        standardDilutionMgPerMl: 10.0,
        infusionTimeMinutes: 30.0,
        limits: const DoseLimit(maxSingleDose: 2000.0, maxDailyDose: 6000.0),
        renalAdjustments: [
          const RenalAdjustment(
            crclMin: 26,
            crclMax: 50,
            adjustmentFactor: 1.0,
            adjustedFrequency: Frequency.q12h,
          ),
          const RenalAdjustment(
            crclMin: 10,
            crclMax: 26,
            adjustmentFactor: 0.5,
            adjustedFrequency: Frequency.q12h,
          ),
          const RenalAdjustment(
            crclMin: 0,
            crclMax: 10,
            adjustmentFactor: 0.5,
            adjustedFrequency: Frequency.q24h,
          ),
        ],
        renalReplacementProtocols: const [
          RenalReplacementProtocol(
            mode: RenalReplacementMode.ihd,
            specificDose: 1000.0,
            doseUnit: DoseUnit.mg,
            frequency: Frequency.q24h,
            requiresPostHdSupplement: true,
            clinicalInstructionEn:
                '1,000 mg IV q24h POST-hemodialysis on dialysis days.',
            clinicalInstructionTh:
                '1,000 mg IV ทุก 24 ชม. บริหารยาทันทีหลังฟอกเลือดเสร็จในวันฟอกไต',
            provenance: Provenance(
              source: 'The Sanford Guide to Antimicrobial Therapy 2024 Table 10B',
              reviewedBy: 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
              reviewedAt: '2024-10-29',
            ),
          ),
          RenalReplacementProtocol(
            mode: RenalReplacementMode.capd,
            specificDose: 1000.0,
            doseUnit: DoseUnit.mg,
            frequency: Frequency.q24h,
            requiresPostHdSupplement: false,
            clinicalInstructionEn: '1,000 mg IV q24h.',
            clinicalInstructionTh: '1,000 mg IV ทุก 24 ชม.',
            provenance: Provenance(
              source: 'The Sanford Guide to Antimicrobial Therapy 2024 Table 10B',
              reviewedBy: 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
              reviewedAt: '2024-10-29',
            ),
          ),
          RenalReplacementProtocol(
            mode: RenalReplacementMode.crrt,
            specificDose: 1000.0,
            doseUnit: DoseUnit.mg,
            frequency: Frequency.q8h,
            requiresPostHdSupplement: false,
            clinicalInstructionEn:
                'CRRT: 1,000 mg IV q8h (or 2,000 mg IV q12h over 3 hours).',
            clinicalInstructionTh:
                'CRRT: 1,000 mg IV ทุก 8 ชม. (หรือ 2,000 mg IV ทุก 12 ชม. หยดยานาน 3 ชม.)',
            provenance: Provenance(
              source: 'The Sanford Guide to Antimicrobial Therapy 2024 Table 10B / KDIGO 2023',
              reviewedBy: 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
              reviewedAt: '2024-10-29',
            ),
          ),
        ],
      ),
    ],
  ),
  Drug(
    id: 'ceftriaxone',
    genericName: 'Ceftriaxone',
    brandNames: ['Rocephin'],
    nameTh: 'เซฟไตรอะโซน',
    category: DrugCategory.antibiotic,
    requiresHepaticCaution: true, // Caution in combined renal/hepatic
    sourceCitation: 'The Sanford Guide to Antimicrobial Therapy 2024 / IDAT Thailand Guidelines',
    lastReviewedDate: '2024-10-12',
    provenance: const Provenance(
      source: 'The Sanford Guide 2024 / แนวทางการรักษาโรคติดเชื้อในประเทศไทย (สมาคมโรคติดเชื้อแห่งประเทศไทย)',
      reviewedBy: 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
      reviewedAt: '2024-10-12',
      sourceDetail: 'Third-Generation Cephalosporins Monograph',
    ),
    monograph: const ClinicalMonograph(
      textbookName: 'The Sanford Guide to Antimicrobial Therapy',
      editionYear: '54th Edition, 2024',
      sectionOrTable: 'Cephalosporins (Third Generation) - Ceftriaxone',
      dosingGuideline:
          '• การติดเชื้อแบคทีเรียทั่วไป: 1,000–2,000 mg IV วันละ 1 ครั้ง (q24h)\n'
          '• เยื่อหุ้มสมองอักเสบ (Bacterial Meningitis): 2,000 mg IV ทุก 12 ชม. (วันละ 4,000 mg)',
      renalGuideline:
          '• ไม่จำเป็นต้องปรับขนาดยาในผู้ป่วยไตวายเดี่ยว (No renal adjustment needed) เนื่องจากยามีการกำจัด 2 ทางคู่ขนาน: ขับออกทางน้ำดี (Biliary) 40–50% และทางไต 50–60%\n'
          '• กรณีที่มีตับวายและไตวายร่วมกันรุนแรง (Combined hepatic & severe renal impairment): จำกัดขนาดยาสูงสุดไม่เกิน 2,000 mg/วัน',
      administrationGuideline:
          '• เจือจางใน NSS หรือ D5W ปริมาตร 50–100 mL หยดทางหลอดเลือดดำนาน 30 นาที\n'
          '• ข้อห้ามใช้เด็ดขาด: ห้ามผสมหรือให้ร่วมกับสารละลายที่มีแคลเซียม (เช่น Ringer\'s Lactate, Calcium gluconate) ในทารกแรกเกิด เนื่องจากเสี่ยงต่อการเกิดตะกอน Ceftriaxone-Calcium อุดตันในปอดและไตจนเสียชีวิต',
      clinicalNotes:
          '• อาจพบภาวะ Biliary sludging / Pseudolithiasis หรือตะกอนในถุงน้ำดีในรายที่ได้ยานานหรือโดสสูง\n'
          '• ตรวจสอบประวัติแพ้ยาในกลุ่ม Penicillins/Cephalosporins ก่อนเริ่มยา',
      externalUrl: 'https://www.sanfordguide.com',
    ),
    contraindications: [
      'Neonates (hyperbilirubinemia)',
      'Concurrent use with IV calcium in neonates',
    ],
    specialNotes:
        'No renal adjustment needed for usual doses. Monitor for biliary sludging with prolonged high-dose therapy.',
    specialNotesTh:
        'ไม่ต้องปรับโดสในผู้ป่วยโรคไต ระวังตะกอนในถุงน้ำดีหากใช้ยาต่อเนื่องนาน',
    ivDiluentCompatibility: const IvDiluentCompatibility(
      compatibleDiluents: [IvDiluent.nss, IvDiluent.d5w],
      preferredDiluent: IvDiluent.nss,
      incompatibleDiluents: [IvDiluent.lrs],
      incompatibilityReasonEn:
          'Do not mix or co-infuse with calcium-containing fluids (e.g., LRS); precipitation may occur. Do not use with calcium-containing IV fluids in neonates.',
      incompatibilityReasonTh:
          'ห้ามผสมหรือให้ร่วมสายกับสารน้ำที่มีแคลเซียม (เช่น LRS) เนื่องจากเสี่ยงตกตะกอน; ทารกแรกเกิดห้ามใช้ร่วมกับสารน้ำที่มีแคลเซียมทางหลอดเลือดดำ',
      stabilityNoteEn:
          'Dilute in 50–100 mL NSS/D5W; infuse over 30 min. In non-neonates, flush line before sequential calcium-containing fluids.',
      stabilityNoteTh:
          'เจือจางใน NSS/D5W 50–100 mL; หยด 30 นาที. ผู้ที่ไม่ใช่ทารกแรกเกิด ให้ Flush สายก่อนให้สารน้ำที่มีแคลเซียมตามลำดับ',
      sourceCitation:
          'US FDA Rocephin (ceftriaxone) SPL §4 & §5.2 / The Sanford Guide 2024 / คู่มือยาฉีดรามาธิบดี',
    ),
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Severe Infection (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 2000.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q24h,
        formulation: DrugFormulation.ivInfusion,
        reconstitution: const ReconstitutionInfo(
          vialStrengthMg: 1000.0,
          diluentName: 'SWFI or 0.9% NSS',
          diluentVolumeMl: 9.6,
          displacedVolumeMl: 0.4,
          resultingConcentrationMgPerMl: 100.0,
          instructionsEn:
              'Reconstitute 1 g vial with 9.6 mL SWFI or NSS to yield 100 mg/mL (total volume 10 mL).',
          instructionsTh:
              'ละลายผงยา 1 กรัม ด้วยน้ำกลั่นหรือ NSS 9.6 มล. ได้ความเข้มข้น 100 มก./มล. (ปริมาตรรวม 10 มล.)',
          sourceCitation:
              'Drug Information Handbook (Lexicomp) 2024 / The Sanford Guide 2024',
        ),
        reconstitutionConcentrationMgPerMl: 100.0,
        standardDilutionBagMl: 100.0,
        standardDilutionMgPerMl: 10.0,
        infusionTimeMinutes: 30.0,
        population: PopulationCriteria(minAgeMonths: 216),
        audience: RegimenAudience.adult,
        notes: 'Severe infections (bacteremia, pyelonephritis, endocarditis): 2,000 mg IV q24h.',
        notesTh: 'การติดเชื้อรุนแรง (ผู้ใหญ่): 2,000 mg IV วันละ 1 ครั้ง (q24h)',
        limits: DoseLimit(maxSingleDose: 2000.0, maxDailyDose: 4000.0),
      ),
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Standard Infection / CAP / UTI (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 1000.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q24h,
        formulation: DrugFormulation.ivInfusion,
        reconstitution: const ReconstitutionInfo(
          vialStrengthMg: 1000.0,
          diluentName: 'SWFI or 0.9% NSS',
          diluentVolumeMl: 9.6,
          displacedVolumeMl: 0.4,
          resultingConcentrationMgPerMl: 100.0,
          instructionsEn:
              'Reconstitute 1 g vial with 9.6 mL SWFI or NSS to yield 100 mg/mL (total volume 10 mL).',
          instructionsTh:
              'ละลายผงยา 1 กรัม ด้วยน้ำกลั่นหรือ NSS 9.6 มล. ได้ความเข้มข้น 100 มก./มล. (ปริมาตรรวม 10 มล.)',
          sourceCitation:
              'Drug Information Handbook (Lexicomp) 2024 / The Sanford Guide 2024',
        ),
        reconstitutionConcentrationMgPerMl: 100.0,
        standardDilutionBagMl: 100.0,
        standardDilutionMgPerMl: 10.0,
        infusionTimeMinutes: 30.0,
        population: PopulationCriteria(minAgeMonths: 216),
        audience: RegimenAudience.adult,
        notes: 'Standard community-acquired pneumonia, UTI, or uncomplicated systemic infection: 1,000–2,000 mg IV q24h.',
        notesTh: 'การติดเชื้อทั่วไป / ปอดอักเสบชุมชน / ทางเดินปัสสาวะ (ผู้ใหญ่): 1,000 mg IV วันละ 1 ครั้ง (q24h)',
        limits: DoseLimit(maxSingleDose: 2000.0, maxDailyDose: 4000.0),
      ),
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Bacterial Meningitis (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 2000.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q12h,
        formulation: DrugFormulation.ivInfusion,
        reconstitution: const ReconstitutionInfo(
          vialStrengthMg: 1000.0,
          diluentName: 'SWFI or 0.9% NSS',
          diluentVolumeMl: 9.6,
          displacedVolumeMl: 0.4,
          resultingConcentrationMgPerMl: 100.0,
          instructionsEn:
              'Reconstitute 1 g vial with 9.6 mL SWFI or NSS to yield 100 mg/mL (total volume 10 mL).',
          instructionsTh:
              'ละลายผงยา 1 กรัม ด้วยน้ำกลั่นหรือ NSS 9.6 มล. ได้ความเข้มข้น 100 มก./มล. (ปริมาตรรวม 10 มล.)',
          sourceCitation:
              'Drug Information Handbook (Lexicomp) 2024 / The Sanford Guide 2024',
        ),
        reconstitutionConcentrationMgPerMl: 100.0,
        standardDilutionBagMl: 100.0,
        standardDilutionMgPerMl: 10.0,
        infusionTimeMinutes: 30.0,
        population: PopulationCriteria(minAgeMonths: 216),
        audience: RegimenAudience.adult,
        notes: 'CNS penetration regimen for bacterial meningitis: 2,000 mg IV q12h (4,000 mg/day).',
        notesTh: 'เยื่อหุ้มสมองอักเสบ (ผู้ใหญ่): 2,000 mg IV ทุก 12 ชม. (วันละ 4,000 mg)',
        limits: DoseLimit(maxSingleDose: 2000.0, maxDailyDose: 4000.0),
      ),
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Standard Infection (Pediatric)',
        dosingType: DosingType.weightBased,
        dosePerKg: 50.0,
        minDosePerKg: 50.0,
        maxDosePerKg: 75.0,
        doseBasis: DoseBasis.perDay,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q24h,
        population: PopulationCriteria(maxAgeMonths: 215),
        audience: RegimenAudience.pediatric,
        notes: 'Standard pediatric non-CNS infections: 50–75 mg/kg/day IV q24h (max 2,000 mg/day). Avoid in hyperbilirubinemic neonates.',
        notesTh: 'ติดเชื้อทั่วไป (เด็ก): 50–75 mg/kg/วัน IV วันละ 1 ครั้ง (สูงสุด 2,000 mg/วัน) ห้ามใช้ในทารกตัวเหลือง',
        limits: DoseLimit(maxSingleDose: 2000.0, maxDailyDose: 2000.0, maxDosePerKgPerDay: 75.0),
      ),
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Meningitis (Pediatric)',
        dosingType: DosingType.weightBased,
        dosePerKg: 100.0,
        minDosePerKg: 80.0,
        maxDosePerKg: 100.0,
        doseBasis: DoseBasis.perDay,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q12h,
        population: PopulationCriteria(maxAgeMonths: 215),
        audience: RegimenAudience.pediatric,
        notes: 'Pediatric bacterial meningitis: 100 mg/kg/day IV divided q12h (50 mg/kg/dose; max 4,000 mg/day).',
        notesTh: 'เยื่อหุ้มสมองอักเสบ (เด็ก): 100 mg/kg/วัน IV แบ่งให้ทุก 12 ชม. (ครั้งละ 50 mg/kg สูงสุด 4,000 mg/วัน)',
        limits: DoseLimit(maxSingleDose: 2000.0, maxDailyDose: 4000.0, maxDosePerKgPerDay: 100.0),
      ),
    ],
  ),
  const Drug(
    id: 'amoxicillin',
    genericName: 'Amoxicillin',
    brandNames: ['Amoxil', 'Moxilin'],
    nameTh: 'อะม็อกซี่ซิลลิน',
    category: DrugCategory.antibiotic,
    drugClass: DrugClass.betaLactamPenicillin,
    requiresRenalAdjustment: true,
    allergyClass: 'Penicillin / Beta-lactam',
    sourceCitation:
        'The Sanford Guide to Antimicrobial Therapy 2024 / Lexicomp 2024 / RDU Thailand',
    lastReviewedDate: '2024-10-12',
    provenance: Provenance(
      source:
          'The Sanford Guide to Antimicrobial Therapy 2024 / Lexicomp Pediatric & Neonatal Dosage Handbook 2024',
      reviewedBy:
          'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
      reviewedAt: '2024-10-12',
      sourceDetail:
          'Aminopenicillins Monograph (Adult & Pediatric Weight-Based Regimens)',
    ),
    monograph: ClinicalMonograph(
      textbookName: 'The Sanford Guide to Antimicrobial Therapy & Lexicomp',
      editionYear: '54th Edition, 2024',
      sectionOrTable: 'Aminopenicillins - Amoxicillin (Adult & Pediatric)',
      dosingGuideline:
          '• ผู้ใหญ่ (Adult Standard): 500 mg PO ทุก 8 ชม. (หรือ 875 mg PO ทุก 12 ชม.) สูงสุดไม่เกิน 3,000 mg/วัน\n'
          '• เด็ก ติดเชื้อทั่วไป (Pediatric Mild-to-Moderate): 25–50 mg/kg/วัน แบ่งให้ทุก 8–12 ชม. (ขนาดแนะนำ 45 mg/kg/วัน แบ่ง q8h = 15 mg/kg/ครั้ง)\n'
          '• เด็ก หูชั้นกลางอักเสบ / ปอดอักเสบ / ไซนัสอักเสบ (Pediatric High-Dose AOM/CAP): 80–90 mg/kg/วัน แบ่งให้ทุก 12 ชม. (45 mg/kg/ครั้ง)',
      renalGuideline:
          '• CrCl ≥ 30 mL/min: ไม่ต้องปรับขนาดยา\n'
          '• CrCl 10–29 mL/min: ผู้ใหญ่ 250–500 mg ทุก 12 ชม.; เด็ก 15 mg/kg/ครั้ง ทุก 12 ชม. (หลีกเลี่ยงสูตร High-dose)\n'
          '• CrCl < 10 mL/min: ผู้ใหญ่ 250–500 mg ทุก 24 ชม.; เด็ก 15 mg/kg/ครั้ง ทุก 24 ชม.',
      administrationGuideline:
          '• รับประทานได้ทั้งก่อนและหลังอาหาร (การดูดซึมไม่ถูกรบกวนจากอาหาร)\n'
          '• รูปแบบยาน้ำแขวนตะกอน (Suspension 125 mg/5 mL หรือ 250 mg/5 mL): เขย่าขวดก่อนรินยาทุกครั้ง เก็บหลังผสมที่อุณหภูมิห้องหรือตู้เย็นตามฉลากและใช้ให้หมดภายใน 7–14 วัน',
      clinicalNotes:
          '• ตรวจสอบประวัติการแพ้ยาในกลุ่ม Penicillins และ Aminocephalosporins (เช่น Cephalexin, Cefadroxil) ก่อนจ่ายยา\n'
          '• ยาเดี่ยว Amoxicillin ครอบคลุมเชื้อแกรมบวก (Streptococcus pneumoniae, GABHS) ได้ดีโดยมีผลข้างเคียงต่อทางเดินอาหารน้อยกว่า Amoxicillin/Clavulanate',
      externalUrl: 'https://www.sanfordguide.com',
    ),
    severeInteractions: [
      'Methotrexate (decreases renal clearance and increases MTX toxicity)',
      'Probenecid (increases amoxicillin serum levels)',
      'Allopurinol (increases risk of maculopapular rash)',
    ],
    contraindications: [
      'Hypersensitivity to penicillins or beta-lactam antibiotics',
      'Infectious mononucleosis (high incidence of erythematous rash)',
    ],
    specialNotes:
        'Pediatric dosing is specified as total mg/kg/day divided q8h (45 mg/kg/day standard) or q12h (80-90 mg/kg/day high-dose AOM).',
    specialNotesTh:
        'ขนาดยาเด็กคำนวณจาก mg/kg/วัน แล้วหารแบ่งมื้อ: ติดเชื้อทั่วไป 45 mg/kg/วัน แบ่ง q8h; หูชั้นกลางอักเสบ (AOM) 80–90 mg/kg/วัน แบ่ง q12h',
    sideEffects: [
      'Diarrhea, nausea, vomiting',
      'Maculopapular rash (especially in infectious mononucleosis) or urticaria',
      'Hypersensitivity / anaphylaxis (beta-lactam allergy)',
      'Clostridioides difficile-associated diarrhea (rare)',
    ],
    sideEffectsTh: [
      'ท้องเสีย ถ่ายเหลว คลื่นไส้ อาเจียน',
      'ผื่นแดงตามผิวหนัง (พบบ่อยหากเป็นโรค Infectious mononucleosis) หรือผื่นลมพิษ',
      'ปฏิกิริยาภูมิแพ้เฉียบพลัน (Anaphylaxis ในผู้ที่แพ้ยากลุ่มเพนิซิลลิน)',
      'ลำไส้อักเสบจากเชื้อ C. difficile (พบน้อย)',
    ],
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Standard Infection (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 500.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q8h,
        notes: '500 mg PO q8h (up to 1,000 mg q8h for severe infections)',
        limits: DoseLimit(maxSingleDose: 1000.0, maxDailyDose: 3000.0),
        renalAdjustments: [
          RenalAdjustment(
            crclMin: 10,
            crclMax: 30,
            adjustmentFactor: 1.0,
            absoluteDose: 500.0,
            adjustedFrequency: Frequency.q12h,
            notes: '500 mg PO q12h in CrCl 10-30 mL/min',
            notesTh: 'ให้ 500 mg PO ทุก 12 ชม. เมื่อ CrCl 10–30 mL/min',
          ),
          RenalAdjustment(
            crclMin: 0,
            crclMax: 10,
            adjustmentFactor: 1.0,
            absoluteDose: 500.0,
            adjustedFrequency: Frequency.q24h,
            notes: '500 mg PO q24h in CrCl < 10 mL/min',
            notesTh: 'ให้ 500 mg PO ทุก 24 ชม. เมื่อ CrCl < 10 mL/min',
          ),
        ],
      ),
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Standard Infection (Pediatric)',
        audience: RegimenAudience.pediatric,
        population: PopulationCriteria(maxAgeMonths: 215),
        dosingType: DosingType.weightBased,
        dosePerKg: 45.0,
        minDosePerKg: 25.0,
        maxDosePerKg: 50.0,
        doseBasis: DoseBasis.perDay,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q8h,
        formulation: DrugFormulation.oralLiquid,
        liquidConcentrations: [
          OralLiquidConcentration(
            label: '125 mg / 5 mL (25 mg/mL)',
            amountMg: 125.0,
            perVolumeMl: 5.0,
            brandOrForm: 'Dry Syrup / Suspension',
            citation: 'The Sanford Guide to Antimicrobial Therapy 2024 / Lexicomp 2024',
          ),
          OralLiquidConcentration(
            label: '250 mg / 5 mL (50 mg/mL)',
            amountMg: 250.0,
            perVolumeMl: 5.0,
            brandOrForm: 'Forte Suspension',
            citation: 'The Sanford Guide to Antimicrobial Therapy 2024 / Lexicomp 2024',
            isDefault: true,
          ),
        ],
        notes:
            '45 mg/kg/day divided q8h (15 mg/kg/dose; usual range 25-50 mg/kg/day)',
        notesTh:
            'ขนาดยารวม 45 mg/kg/วัน แบ่งให้ทุก 8 ชม. (15 mg/kg/ครั้ง; ช่วงแนะนำ 25–50 mg/kg/วัน)',
        limits: DoseLimit(
          maxSingleDose: 500.0,
          maxDailyDose: 1500.0,
          maxDosePerKgPerDay: 50.0,
        ),
        renalAdjustments: [
          RenalAdjustment(
            crclMin: 10,
            crclMax: 30,
            adjustmentFactor: 1.0,
            adjustedFrequency: Frequency.q12h,
            notes: '15 mg/kg/dose PO q12h in CrCl 10-30 mL/min',
            notesTh: 'ให้ 15 mg/kg/ครั้ง PO ทุก 12 ชม. เมื่อ eGFR/CrCl 10–30',
          ),
          RenalAdjustment(
            crclMin: 0,
            crclMax: 10,
            adjustmentFactor: 1.0,
            adjustedFrequency: Frequency.q24h,
            notes: '15 mg/kg/dose PO q24h in CrCl < 10 mL/min',
            notesTh: 'ให้ 15 mg/kg/ครั้ง PO ทุก 24 ชม. เมื่อ eGFR/CrCl < 10',
          ),
        ],
      ),
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Acute Otitis Media / High-Dose (Pediatric)',
        audience: RegimenAudience.pediatric,
        population: PopulationCriteria(maxAgeMonths: 215),
        dosingType: DosingType.weightBased,
        dosePerKg: 90.0,
        minDosePerKg: 80.0,
        maxDosePerKg: 90.0,
        doseBasis: DoseBasis.perDay,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q12h,
        formulation: DrugFormulation.oralLiquid,
        liquidConcentrations: [
          OralLiquidConcentration(
            label: '250 mg / 5 mL (50 mg/mL)',
            amountMg: 250.0,
            perVolumeMl: 5.0,
            brandOrForm: 'Forte Suspension',
            citation: 'The Sanford Guide to Antimicrobial Therapy 2024 / Lexicomp 2024',
            isDefault: true,
          ),
          OralLiquidConcentration(
            label: '125 mg / 5 mL (25 mg/mL)',
            amountMg: 125.0,
            perVolumeMl: 5.0,
            brandOrForm: 'Dry Syrup / Suspension',
            citation: 'The Sanford Guide to Antimicrobial Therapy 2024 / Lexicomp 2024',
          ),
        ],
        notes:
            '80-90 mg/kg/day divided q12h (45 mg/kg/dose) for Acute Otitis Media or resistant S. pneumoniae',
        notesTh:
            'ขนาดยาสูง 80–90 mg/kg/วัน แบ่งให้ทุก 12 ชม. (45 mg/kg/ครั้ง) สำหรับหูชั้นกลางอักเสบเฉียบพลัน (AOM) หรือปอดอักเสบ',
        limits: DoseLimit(
          maxSingleDose: 1000.0,
          maxDailyDose: 3000.0,
          maxDosePerKgPerDay: 90.0,
        ),
        renalAdjustments: [
          RenalAdjustment(
            crclMin: 10,
            crclMax: 30,
            adjustmentFactor: 0.33,
            adjustedFrequency: Frequency.q12h,
            notes:
                'Avoid high-dose in renal impairment; reduce to ~15 mg/kg/dose PO q12h',
            notesTh:
                'หลีกเลี่ยงสูตร High-dose ในผู้ป่วยไตเสื่อม ลดขนาดยาเหลือ ~15 mg/kg/ครั้ง ทุก 12 ชม.',
          ),
          RenalAdjustment(
            crclMin: 0,
            crclMax: 10,
            adjustmentFactor: 0.33,
            adjustedFrequency: Frequency.q24h,
            notes:
                'Avoid high-dose in severe renal impairment; reduce to ~15 mg/kg/dose PO q24h',
            notesTh:
                'หลีกเลี่ยงสูตร High-dose ในผู้ป่วยไตเสื่อมรุนแรง ลดขนาดยาเหลือ ~15 mg/kg/ครั้ง ทุก 24 ชม.',
          ),
        ],
      ),
    ],
  ),
  const Drug(
    id: 'amoxicillin_clavulanate',
    genericName: 'Amoxicillin/Clavulanate',
    brandNames: ['Augmentin', 'Curam', 'Amoksiklav'],
    nameTh: 'ออม็อกซิลลิน/คลาวูลานิก แอซิด',
    category: DrugCategory.antibiotic,
    drugClass: DrugClass.betaLactamPenicillin,
    requiresRenalAdjustment: true,
    requiresHepaticCaution: true,
    allergyClass: 'Penicillin / Beta-lactam',
    sourceCitation:
        'The Sanford Guide to Antimicrobial Therapy 2024 / Lexicomp 2024',
    lastReviewedDate: '2024-10-12',
    provenance: Provenance(
      source:
          'The Sanford Guide to Antimicrobial Therapy 2024 / Lexicomp Pediatric & Neonatal Dosage Handbook 2024',
      reviewedBy:
          'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
      reviewedAt: '2024-10-12',
      sourceDetail: 'Amoxicillin/Clavulanate Monograph (Standard & High-Dose)',
    ),
    monograph: ClinicalMonograph(
      textbookName: 'The Sanford Guide to Antimicrobial Therapy & Lexicomp',
      editionYear: '54th Edition, 2024',
      sectionOrTable: 'Beta-Lactam / Beta-Lactamase Inhibitors',
      dosingGuideline:
          '• ผู้ใหญ่: 875/125 mg (1,000 mg) PO ทุก 12 ชม. หรือ 500/125 mg PO ทุก 8–12 ชม.\n'
          '• เด็ก ติดเชื้อทั่วไป (Standard): 25–45 mg/kg/วัน (อ้างอิงส่วน Amoxicillin) แบ่งทุก 12 ชม. (22.5 mg/kg/ครั้ง)\n'
          '• เด็ก หูชั้นกลางอักเสบ / ไซนัส / ปอดอักเสบ (High-Dose ES/14:1): 80–90 mg/kg/วัน แบ่งทุก 12 ชม. (45 mg/kg/ครั้ง)',
      renalGuideline:
          '• CrCl < 30 mL/min: ห้ามใช้เม็ดขนาด 875/125 mg (1,000 mg) และหลีกเลี่ยงสูตร High-dose\n'
          '• CrCl 10–30 mL/min: ผู้ใหญ่ 500/125 mg ทุก 12 ชม.; เด็ก 15 mg/kg/ครั้ง ทุก 12 ชม.\n'
          '• CrCl < 10 mL/min: ผู้ใหญ่ 500/125 mg ทุก 24 ชม.; เด็ก 15 mg/kg/ครั้ง ทุก 24 ชม.',
      administrationGuideline:
          '• รับประทานพร้อมอาหารหรือเริ่มมื้ออาหารทันที เพื่อเพิ่มการดูดซึมและลดอาการคลื่นไส้/ท้องเสีย\n'
          '• เลือกอัตราส่วนผสม (เช่น 7:1 หรือ 14:1) ให้เหมาะสมในเด็กเพื่อไม่ให้ได้รับ Clavulanate เกินขนาด (> 10 mg/kg/วัน ทำให้ถ่ายเหลว)',
      clinicalNotes:
          '• การคำนวณทั้งหมดอ้างอิงจากตัวยา Amoxicillin component เป็นหลัก\n'
          '• ระวังภาวะ Cholestatic jaundice หรือตับอักเสบจาก Clavulanate ในผู้สูงอายุหรือผู้ที่มีประวัติตับผิดปกติจากยานี้มาก่อน',
      externalUrl: 'https://www.sanfordguide.com',
    ),
    severeInteractions: [
      'Methotrexate (increases toxicity)',
      'Probenecid',
      'Allopurinol (rash)',
    ],
    contraindications: [
      'History of penicillin-associated jaundice/hepatic dysfunction',
    ],
    specialNotes:
        'Dosing is based on the Amoxicillin component. High doses of clavulanate can cause diarrhea.',
    specialNotesTh:
        'คำนวณโดสจาก Amoxicillin เป็นหลัก ระวังท้องเสียจาก Clavulanate ที่สูงเกินไป',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Standard Infection (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 1000.0, // Commonly 875/125 mg = 1000 mg total tablet, but base is amox
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q12h,
        limits: DoseLimit(maxSingleDose: 2000.0, maxDailyDose: 4000.0),
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
        audience: RegimenAudience.pediatric,
        population: PopulationCriteria(maxAgeMonths: 215),
        dosingType: DosingType.weightBased,
        dosePerKg: 45.0,
        minDosePerKg: 25.0,
        maxDosePerKg: 45.0,
        doseBasis: DoseBasis.perDay,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q12h,
        formulation: DrugFormulation.oralLiquid,
        liquidConcentrations: [
          OralLiquidConcentration(
            label: '200/28.5 mg / 5 mL (40 mg/mL Amox)',
            amountMg: 200.0,
            perVolumeMl: 5.0,
            brandOrForm: 'Oral Suspension (7:1)',
            citation: 'The Sanford Guide 2024 / Lexicomp 2024',
            isDefault: true,
          ),
          OralLiquidConcentration(
            label: '400/57 mg / 5 mL (80 mg/mL Amox)',
            amountMg: 400.0,
            perVolumeMl: 5.0,
            brandOrForm: 'Oral Suspension (7:1)',
            citation: 'The Sanford Guide 2024 / Lexicomp 2024',
          ),
        ],
        notes: '45 mg/kg/day divided q12h (22.5 mg/kg/dose)',
        notesTh: 'ขนาดยารวม 45 mg/kg/วัน แบ่งให้ทุก 12 ชม. (22.5 mg/kg/ครั้ง)',
        limits: DoseLimit(
          maxSingleDose: 875.0,
          maxDailyDose: 1750.0,
          maxDosePerKgPerDay: 45.0,
        ),
        renalAdjustments: [
          RenalAdjustment(
            crclMin: 10,
            crclMax: 30,
            adjustmentFactor: 0.67,
            adjustedFrequency: Frequency.q12h,
            notes: '15 mg/kg q12h in CrCl 10-30 mL/min',
            notesTh: 'ให้ 15 mg/kg/ครั้ง PO ทุก 12 ชม. เมื่อ eGFR/CrCl 10–30',
          ),
          RenalAdjustment(
            crclMin: 0,
            crclMax: 10,
            adjustmentFactor: 0.67,
            adjustedFrequency: Frequency.q24h,
            notes: '15 mg/kg q24h in CrCl < 10 mL/min',
            notesTh: 'ให้ 15 mg/kg/ครั้ง PO ทุก 24 ชม. เมื่อ eGFR/CrCl < 10',
          ),
        ],
      ),
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Acute Otitis Media / High-Dose (Pediatric)',
        audience: RegimenAudience.pediatric,
        population: PopulationCriteria(maxAgeMonths: 215),
        dosingType: DosingType.weightBased,
        dosePerKg: 90.0,
        minDosePerKg: 80.0,
        maxDosePerKg: 90.0,
        doseBasis: DoseBasis.perDay,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q12h,
        formulation: DrugFormulation.oralLiquid,
        liquidConcentrations: [
          OralLiquidConcentration(
            label: '600/42.9 mg / 5 mL (120 mg/mL Amox)',
            amountMg: 600.0,
            perVolumeMl: 5.0,
            brandOrForm: 'Augmentin ES-600 (14:1)',
            citation: 'The Sanford Guide 2024 / Lexicomp 2024',
            isDefault: true,
          ),
          OralLiquidConcentration(
            label: '400/57 mg / 5 mL (80 mg/mL Amox)',
            amountMg: 400.0,
            perVolumeMl: 5.0,
            brandOrForm: 'Oral Suspension (7:1)',
            citation: 'The Sanford Guide 2024 / Lexicomp 2024',
          ),
        ],
        notes:
            '90 mg/kg/day (amoxicillin component, 14:1 ratio) divided q12h (45 mg/kg/dose) for AOM / Sinusitis / CAP',
        notesTh:
            'ขนาดยาสูง 90 mg/kg/วัน (สัดส่วน 14:1) แบ่งให้ทุก 12 ชม. (45 mg/kg/ครั้ง) สำหรับหูชั้นกลางอักเสบ (AOM) หรือปอดอักเสบ',
        limits: DoseLimit(
          maxSingleDose: 2000.0,
          maxDailyDose: 4000.0,
          maxDosePerKgPerDay: 90.0,
        ),
        renalAdjustments: [
          RenalAdjustment(
            crclMin: 10,
            crclMax: 30,
            adjustmentFactor: 0.33,
            adjustedFrequency: Frequency.q12h,
            notes:
                'Avoid high-dose in renal impairment; reduce to 15 mg/kg q12h',
            notesTh:
                'หลีกเลี่ยงสูตร High-dose ในผู้ป่วยไตเสื่อม ลดขนาดยาเหลือ 15 mg/kg/ครั้ง ทุก 12 ชม.',
          ),
          RenalAdjustment(
            crclMin: 0,
            crclMax: 10,
            adjustmentFactor: 0.33,
            adjustedFrequency: Frequency.q24h,
            notes:
                'Avoid high-dose in severe renal impairment; reduce to 15 mg/kg q24h',
            notesTh:
                'หลีกเลี่ยงสูตร High-dose ในผู้ป่วยไตเสื่อมรุนแรง ลดขนาดยาเหลือ 15 mg/kg/ครั้ง ทุก 24 ชม.',
          ),
        ],
      ),
    ],
  ),
  const Drug(
    id: 'azithromycin',
    genericName: 'Azithromycin',
    brandNames: ['Zithromax'],
    nameTh: 'อะซิโธรมัยซิน',
    category: DrugCategory.antibiotic,
    drugClass: DrugClass.macrolide,
    requiresHepaticCaution: true,
    allergyClass: 'Macrolide',
    sourceCitation:
        'The Sanford Guide to Antimicrobial Therapy 2024 / Lexicomp 2024',
    lastReviewedDate: '2024-10-12',
    provenance: Provenance(
      source:
          'The Sanford Guide to Antimicrobial Therapy 2024 / Lexicomp Pediatric & Neonatal Dosage Handbook 2024',
      reviewedBy:
          'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
      reviewedAt: '2024-10-12',
      sourceDetail: 'Macrolides Monograph (Adult & Pediatric Regimens)',
    ),
    monograph: ClinicalMonograph(
      textbookName: 'The Sanford Guide to Antimicrobial Therapy & Lexicomp',
      editionYear: '54th Edition, 2024',
      sectionOrTable: 'Macrolides - Azithromycin',
      dosingGuideline:
          '• ผู้ใหญ่ (CAP / Respiratory): วันแรก 500 mg PO ครั้งเดียว จากนั้น 250 mg PO วันละครั้ง วันที่ 2–5 (หรือ 500 mg/วัน นาน 3 วัน)\n'
          '• เด็ก (Otitis Media / CAP): วันแรก 10 mg/kg/ครั้ง (สูงสุด 500 mg) จากนั้น 5 mg/kg/ครั้ง วันละครั้ง วันที่ 2–5 (สูงสุด 250 mg)',
      renalGuideline:
          '• ไม่ต้องปรับขนาดยาในผู้ป่วยไตเสื่อม (ขับออกทางน้ำดี/อุจจาระเป็นหลัก)',
      administrationGuideline:
          '• ยาน้ำแขวนตะกอนและยาเม็ด: รับประทานก่อนหรือหลังอาหารก็ได้ (แคปซูลบางสูตรให้ก่อนอาหาร 1 ชม. หรือหลังอาหาร 2 ชม.)\n'
          '• หลีกเลี่ยงการรับประทานพร้อมยาลดกรดที่มี Aluminium/Magnesium พร้อมกันทันที (ให้ห่างกันอย่างน้อย 2 ชม.)',
      clinicalNotes:
          '• เฝ้าระวังคลื่นไฟฟ้าหัวใจผิดปกติ (QT prolongation / Torsades de Pointes) โดยเฉพาะเมื่อใช้ร่วมกับ Amiodarone หรือ Fluoroquinolones\n'
          '• ไม่ยับยั้ง CYP3A4 รุนแรงเท่า Erythromycin/Clarithromycin แต่ยังควรติดตาม INR เมื่อใช้ร่วมกับ Warfarin',
      externalUrl: 'https://www.sanfordguide.com',
    ),
    severeInteractions: [
      'Amiodarone (QT prolongation)',
      'Statins (increased myopathy risk)',
      'Warfarin',
    ],
    specialNotes:
        'Risk of QT prolongation. Take on an empty stomach for some formulations.',
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
        audience: RegimenAudience.pediatric,
        population: PopulationCriteria(maxAgeMonths: 215),
        dosingType: DosingType.weightBased,
        dosePerKg: 10.0, // 10 mg/kg day 1, then 5 mg/kg day 2-5
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q24h,
        notes:
            'Day 1: 10 mg/kg (max 500 mg), then 5 mg/kg q24h on Days 2-5 (max 250 mg)',
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
    drugClass: DrugClass.fluoroquinolone,
    requiresRenalAdjustment: true,
    allergyClass: 'Fluoroquinolone',
    sourceCitation:
        'The Sanford Guide to Antimicrobial Therapy 2024 / Lexicomp 2024 / US FDA Cipro SPL',
    lastReviewedDate: '2024-10-12',
    provenance: Provenance(
      source:
          'The Sanford Guide 2024 / Lexicomp Drug Information / US FDA Cipro Label',
      reviewedBy:
          'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
      reviewedAt: '2024-10-12',
      sourceDetail: 'Fluoroquinolones - Ciprofloxacin Multi-Indication Dosing',
    ),
    monograph: ClinicalMonograph(
      textbookName: 'The Sanford Guide to Antimicrobial Therapy & Lexicomp',
      editionYear: '54th Edition, 2024',
      sectionOrTable: 'Fluoroquinolones - Ciprofloxacin',
      dosingGuideline:
          '• กระเพาะปัสสาวะอักเสบไม่ซับซ้อน (Uncomplicated Cystitis): 250 mg PO ทุก 12 ชม. นาน 3 วัน\n'
          '• ติดเชื้อทางเดินปัสสาวะ / ทั่วไป (Complicated UTI / Moderate Systemic): 500 mg PO ทุก 12 ชม. (หรือ 400 mg IV ทุก 12 ชม.)\n'
          '• ติดเชื้อรุนแรง / กระดูกและข้อ / Pseudomonas aeruginosa: 750 mg PO ทุก 12 ชม. (หรือ 400 mg IV ทุก 8–12 ชม.)',
      renalGuideline:
          '• CrCl > 50 mL/min: ไม่ต้องปรับขนาดยา\n'
          '• CrCl 30–50 mL/min: 250–500 mg PO ทุก 12 ชม. (หลีกเลี่ยง 750 mg PO q12h); IV 400 mg ทุก 12 ชม.\n'
          '• CrCl < 30 mL/min: 250–500 mg PO ทุก 18–24 ชม. หรือ 400 mg IV ทุก 24 ชม.',
      administrationGuideline:
          '• ยารับประทาน: ห้ามรับประทานพร้อมนม ผลิตภัณฑ์จากนม แคลเซียม ธาตุเหล็ก สังกะสี หรือยาลดกรด (Aluminum/Magnesium hydroxide) เนื่องจากเกิด Chelation ลดการดูดซึมยา — เว้นห่างอย่างน้อย 2 ชม. ก่อน หรือ 4–6 ชม. หลังแร่ธาตุเหล่านี้\n'
          '• ยาฉีด IV: ให้แบบ IV Infusion นาน 60 นาที ผ่านหลอดเลือดดำขนาดใหญ่ เพื่อลดอาการระคายเคืองหลอดเลือด',
      clinicalNotes:
          '• FDA Black Box Warning: เสี่ยงเอ็นร้อยหวายอักเสบหรือฉีกขาด (Tendinitis/Tendon rupture), เส้นประสาทส่วนปลายอักเสบ, อาการทางระบบประสาทส่วนกลาง และ QT prolongation\n'
          '• หลีกเลี่ยงการใช้ในเด็กและวัยรุ่น (< 18 ปี) และหญิงตั้งครรภ์ เนื่องจากเสี่ยงพิษต่อกระดูกอ่อนข้อต่อ (Arthropathy) ยกเว้นกรณีจำเป็นตามข้อบ่งชี้เฉพาะ',
      externalUrl: 'https://www.sanfordguide.com',
    ),
    severeInteractions: [
      'Tizanidine (Contraindicated - severe hypotension)',
      'Theophylline (Increases toxicity)',
      'Antacids / Calcium / Iron (Decreases absorption)',
    ],
    contraindications: ['Concurrent administration with tizanidine'],
    specialNotes:
        'Risk of tendon rupture and QT prolongation. Avoid in children (unless specific severe indications) due to cartilage toxicity.',
    specialNotesTh:
        'เสี่ยงเอ็นร้อยหวายอักเสบ/ฉีกขาด และ QT ยาวขึ้น ไม่แนะนำในเด็กเนื่องจากผลต่อกระดูกอ่อน ห้ามกินพร้อมนมหรือยาลดกรด',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'UTI / Systemic Infection (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 500.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q12h,
        population: PopulationCriteria(minAgeMonths: 216),
        audience: RegimenAudience.adult,
        notes: 'Standard complicated UTI, prostatitis, or moderate systemic infection: 500 mg PO q12h.',
        notesTh: 'ติดเชื้อทางเดินปัสสาวะซับซ้อน / ติดเชื้อทั่วไป (ผู้ใหญ่): 500 mg PO ทุก 12 ชม.',
        limits: DoseLimit(maxSingleDose: 750.0, maxDailyDose: 1500.0),
        renalAdjustments: [
          RenalAdjustment(
            crclMin: 0,
            crclMax: 30,
            adjustmentFactor: 0.5,
            notes: 'Max 500 mg q18-24h (250 mg PO q12h or 500 mg PO q24h)',
          ),
        ],
      ),
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Uncomplicated Cystitis / UTI (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 250.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q12h,
        population: PopulationCriteria(minAgeMonths: 216),
        audience: RegimenAudience.adult,
        notes: 'Uncomplicated acute cystitis: 250 mg PO q12h for 3 days.',
        notesTh: 'กระเพาะปัสสาวะอักเสบไม่ซับซ้อน (ผู้ใหญ่): 250 mg PO ทุก 12 ชม. นาน 3 วัน',
        limits: DoseLimit(maxSingleDose: 750.0, maxDailyDose: 1500.0),
        renalAdjustments: [
          RenalAdjustment(
            crclMin: 0,
            crclMax: 30,
            adjustmentFactor: 1.0,
            adjustedFrequency: Frequency.q24h,
            notes: '250 mg PO q24h in CrCl < 30 mL/min',
          ),
        ],
      ),
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Severe Pseudomonas / Bone & Joint Infection (Adult PO)',
        dosingType: DosingType.fixed,
        fixedDose: 750.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q12h,
        population: PopulationCriteria(minAgeMonths: 216),
        audience: RegimenAudience.adult,
        notes: 'High-dose oral therapy for severe Pseudomonas, osteomyelitis, or diabetic foot infections: 750 mg PO q12h.',
        notesTh: 'ติดเชื้อ Pseudomonas รุนแรง / กระดูกและข้อ (ผู้ใหญ่ PO): 750 mg PO ทุก 12 ชม.',
        limits: DoseLimit(maxSingleDose: 750.0, maxDailyDose: 1500.0),
        renalAdjustments: [
          RenalAdjustment(
            crclMin: 0,
            crclMax: 30,
            adjustmentFactor: 1.0,
            absoluteDose: 500.0,
            adjustedFrequency: Frequency.q24h,
            notes: 'CrCl < 30 mL/min: Reduce to 500 mg PO q18–24h (avoid 750 mg q12h)',
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
        population: PopulationCriteria(minAgeMonths: 216),
        audience: RegimenAudience.adult,
        notes: 'Intravenous systemic therapy (may increase to 400 mg IV q8h for severe Pseudomonas/nosocomial pneumonia). Infuse over 60 min.',
        notesTh: 'ติดเชื้อรุนแรงแบบฉีดเข้าหลอดเลือดดำ (ผู้ใหญ่ IV): 400 mg IV ทุก 12 ชม. หยดนาน 60 นาที',
        limits: DoseLimit(maxSingleDose: 400.0, maxDailyDose: 1200.0),
        renalAdjustments: [
          RenalAdjustment(
            crclMin: 0,
            crclMax: 30,
            adjustmentFactor: 1.0,
            adjustedFrequency: Frequency.q24h,
            notes: '400 mg IV q24h in CrCl < 30 mL/min',
          ),
        ],
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
        doseBasis: DoseBasis.perDay,
        dosePerKg: 15.0, // 8-25 mg/kg/day divided TID or QID
        doseUnit: DoseUnit.mg,
        frequency: Frequency(minIntervalHours: 6, maxIntervalHours: 8, displayEn: 'Divided q6-8h', displayTh: 'แบ่งทุก 6-8 ชม.', doseBasis: DoseBasis.perDay),
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
    drugClass: DrugClass.nitroimidazole,
    requiresHepaticCaution: true,
    allergyClass: 'Nitroimidazole',
    sourceCitation:
        'The Sanford Guide to Antimicrobial Therapy 2024 / Lexicomp 2024 / US FDA Flagyl SPL',
    lastReviewedDate: '2024-10-12',
    provenance: Provenance(
      source:
          'The Sanford Guide 2024 / Lexicomp Pediatric & Adult Drug Information',
      reviewedBy:
          'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
      reviewedAt: '2024-10-12',
      sourceDetail:
          'Nitroimidazoles - Metronidazole Multi-Indication & Pediatric Dosing',
    ),
    monograph: ClinicalMonograph(
      textbookName: 'The Sanford Guide to Antimicrobial Therapy & Lexicomp',
      editionYear: '54th Edition, 2024',
      sectionOrTable: 'Nitroimidazoles - Metronidazole (Adult & Pediatric)',
      dosingGuideline:
          '• การติดเชื้อแบคทีเรียที่ไม่ใช้ออกซิเจน (ผู้ใหญ่ PO): 400–500 mg ทุก 8 ชม. (สูงสุด 4,000 mg/วัน)\n'
          '• การติดเชื้อรุนแรง (ผู้ใหญ่ IV): 500 mg IV ทุก 8 ชม. หยดนาน 30–60 นาที\n'
          '• เด็ก ติดเชื้อแบคทีเรียที่ไม่ใช้ออกซิเจน (Pediatric Anaerobic Infections): 30 mg/kg/วัน PO หรือ IV แบ่งให้ทุก 6–8 ชม. (สูงสุด 4,000 mg/วัน)',
      renalGuideline:
          '• CrCl ≥ 10 mL/min: ไม่ต้องปรับขนาดยา\n'
          '• CrCl < 10 mL/min / Anuria: ลดขนาดยาลง 50% หรือให้ทุก 12 ชม. เนื่องจากเมแทบอไลต์อาจสะสม',
      administrationGuideline:
          '• ยารับประทาน: รับประทานพร้อมหรือหลังอาหารเพื่อลดอาการคลื่นไส้ระคายเคืองกระเพาะ\n'
          '• ยาฉีด IV: ให้แบบ IV Infusion นาน 30–60 นาที ห้ามฉีดแบบ IV Push และห้ามแช่เย็นหลังเปิดขวด',
      clinicalNotes:
          '• ห้ามดื่มแอลกอฮอล์เด็ดขาดระหว่างใช้ยาและหลังหยุดยาอย่างน้อย 3 วัน (Disulfiram-like reaction)\n'
          '• ผู้ป่วยตับเสื่อมรุนแรง (Child-Pugh C): ลดขนาดยาลง 50% หรือยืดระยะห่างเป็นทุก 12 ชม.',
      externalUrl: 'https://www.sanfordguide.com',
    ),
    severeInteractions: [
      'Alcohol (Disulfiram-like reaction: severe vomiting, flushing)',
      'Warfarin (Increases bleeding risk)',
    ],
    contraindications: [
      'First trimester of pregnancy (controversial, but often avoided)',
    ],
    specialNotes:
        'Strictly AVOID alcohol during therapy and for 3 days after. Reduce dose by 50% in severe hepatic impairment (Child-Pugh C). Pediatric anaerobic dosing is 30 mg/kg/day divided q6–8h.',
    specialNotesTh:
        'ห้ามดื่มแอลกอฮอล์เด็ดขาดระหว่างกินยาและหลังยาหมด 3 วัน ในผู้ป่วยโรคตับรุนแรง (Child-Pugh C) ลดขนาดยาลง 50% ขนาดยาเด็ก 30 mg/kg/วัน แบ่ง q6–8h',
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Anaerobic Infection / Trichomoniasis (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 400.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q8h,
        population: PopulationCriteria(minAgeMonths: 216),
        audience: RegimenAudience.adult,
        notes: 'Oral anaerobic infections / amoebiasis / trichomoniasis: 400–500 mg PO q8h.',
        notesTh: 'ติดเชื้อแบคทีเรียที่ไม่ใช้ออกซิเจน / พยาธิช่องคลอด (ผู้ใหญ่ PO): 400 mg PO ทุก 8 ชม.',
        limits: DoseLimit(maxSingleDose: 2000.0, maxDailyDose: 4000.0),
      ),
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Severe Anaerobic Infection (Adult IV)',
        dosingType: DosingType.fixed,
        fixedDose: 500.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q8h,
        population: PopulationCriteria(minAgeMonths: 216),
        audience: RegimenAudience.adult,
        notes: 'Severe systemic anaerobic infection or CNS abscess: 500 mg IV q8h over 30–60 min.',
        notesTh: 'ติดเชื้อไม่ใช้ออกซิเจนรุนแรง (ผู้ใหญ่ IV): 500 mg IV ทุก 8 ชม. หยดนาน 30–60 นาที',
        limits: DoseLimit(maxSingleDose: 1500.0, maxDailyDose: 4000.0),
      ),
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Clostridioides difficile Colitis (Adult PO)',
        dosingType: DosingType.fixed,
        fixedDose: 500.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q8h,
        population: PopulationCriteria(minAgeMonths: 216),
        audience: RegimenAudience.adult,
        notes: 'Alternative non-severe C. difficile regimen when vancomycin/fidaxomicin are unavailable: 500 mg PO q8h for 10 days.',
        notesTh: 'ลำไส้อักเสบ C. difficile (ทางเลือก ผู้ใหญ่ PO): 500 mg PO ทุก 8 ชม. นาน 10 วัน',
        limits: DoseLimit(maxSingleDose: 500.0, maxDailyDose: 4000.0),
      ),
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Anaerobic Bacterial Infection (Pediatric PO)',
        dosingType: DosingType.weightBased,
        dosePerKg: 30.0,
        minDosePerKg: 20.0,
        maxDosePerKg: 40.0,
        doseBasis: DoseBasis.perDay,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q8h,
        population: PopulationCriteria(maxAgeMonths: 215),
        audience: RegimenAudience.pediatric,
        notes: 'Pediatric oral anaerobic infections: 30 mg/kg/day PO divided q8h (10 mg/kg/dose; max 500 mg/dose, 2,000 mg/day).',
        notesTh: 'ติดเชื้อแบคทีเรียที่ไม่ใช้ออกซิเจน (เด็ก PO): 30 mg/kg/วัน แบ่งทุก 8 ชม. (10 mg/kg/ครั้ง สูงสุด 500 mg/ครั้ง)',
        limits: DoseLimit(maxSingleDose: 500.0, maxDailyDose: 2000.0, maxDosePerKgPerDay: 50.0),
      ),
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Anaerobic Bacterial Infection (Pediatric IV)',
        dosingType: DosingType.weightBased,
        dosePerKg: 30.0,
        minDosePerKg: 20.0,
        maxDosePerKg: 40.0,
        doseBasis: DoseBasis.perDay,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q6h,
        population: PopulationCriteria(maxAgeMonths: 215),
        audience: RegimenAudience.pediatric,
        notes: 'Pediatric IV anaerobic infections: 30 mg/kg/day IV divided q6h (7.5 mg/kg/dose; max 500 mg/dose, 4,000 mg/day).',
        notesTh: 'ติดเชื้อแบคทีเรียที่ไม่ใช้ออกซิเจน (เด็ก IV): 30 mg/kg/วัน IV แบ่งทุก 6 ชม. (7.5 mg/kg/ครั้ง สูงสุด 500 mg/ครั้ง)',
        limits: DoseLimit(maxSingleDose: 500.0, maxDailyDose: 4000.0, maxDosePerKgPerDay: 50.0),
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
    ivDiluentCompatibility: IvDiluentCompatibility(
      compatibleDiluents: [IvDiluent.nss, IvDiluent.d5w, IvDiluent.lrs],
      preferredDiluent: IvDiluent.nss,
      stabilityNoteEn:
          'Reconstitute with SWFI; slow IV push over 3–5 min, or dilute in 50–100 mL NSS/D5W and infuse over 30 min. Stable 24 h at room temperature.',
      stabilityNoteTh:
          'ละลายด้วย SWFI; IV push 3–5 นาที หรือเจือจางใน NSS/D5W 50–100 mL หยด 30 นาที. คงตัว 24 ชม. ที่อุณหภูมิห้อง',
      sourceCitation:
          'US FDA Cefazolin for Injection SPL / ASHP Surgical Prophylaxis Guidelines / คู่มือยาฉีดรามาธิบดี',
    ),
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Surgical Prophylaxis (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 2000.0, // 2g for adults > 60kg
        doseUnit: DoseUnit.mg,
        frequency: Frequency.stat,
        formulation: DrugFormulation.ivInjection,
        reconstitution: ReconstitutionInfo(
          vialStrengthMg: 1000.0,
          diluentName: 'Sterile Water for Injection (SWFI)',
          diluentVolumeMl: 10.0,
          resultingConcentrationMgPerMl: 100.0,
          instructionsEn:
              'Reconstitute 1 g vial with 10 mL SWFI to yield 100 mg/mL.',
          instructionsTh:
              'ละลายผงยา 1 กรัม ด้วยน้ำกลั่นสำหรับฉีดยา 10 มล. ได้ความเข้มข้น 100 มก./มล.',
          sourceCitation:
              'Drug Information Handbook (Lexicomp) 2024 / The Sanford Guide 2024',
        ),
        reconstitutionConcentrationMgPerMl: 100.0,
        standardDilutionBagMl: 100.0,
        infusionTimeMinutes: 30.0,
        limits: DoseLimit(
          maxSingleDose: 3000.0, // 3g for patients >120kg
        ),
        renalAdjustments: [
          RenalAdjustment(
            crclMin: 0,
            crclMax: 35,
            adjustmentFactor: 1.0,
            notes: 'Single preoperative dose is NOT reduced in renal failure. Prolong redosing interval if surgery exceeds 4 hours.',
          ),
        ],
      ),
      DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Systemic Infection (Adult)',
        dosingType: DosingType.fixed,
        fixedDose: 1000.0, // 1g q8h
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q8h,
        formulation: DrugFormulation.ivInjection,
        reconstitution: ReconstitutionInfo(
          vialStrengthMg: 1000.0,
          diluentName: 'Sterile Water for Injection (SWFI)',
          diluentVolumeMl: 10.0,
          resultingConcentrationMgPerMl: 100.0,
          instructionsEn:
              'Reconstitute 1 g vial with 10 mL SWFI to yield 100 mg/mL.',
          instructionsTh:
              'ละลายผงยา 1 กรัม ด้วยน้ำกลั่นสำหรับฉีดยา 10 มล. ได้ความเข้มข้น 100 มก./มล.',
          sourceCitation:
              'Drug Information Handbook (Lexicomp) 2024 / The Sanford Guide 2024',
        ),
        reconstitutionConcentrationMgPerMl: 100.0,
        standardDilutionBagMl: 100.0,
        infusionTimeMinutes: 30.0,
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
        renalReplacementProtocols: [
          RenalReplacementProtocol(
            mode: RenalReplacementMode.ihd,
            specificDose: 1000.0,
            doseUnit: DoseUnit.mg,
            frequency: Frequency.q24h,
            requiresPostHdSupplement: true,
            clinicalInstructionEn:
                'Administer 1,000–2,000 mg (1–2 g) IV immediately POST-hemodialysis on dialysis days (1 g for 48-hour interdialytic period, 2 g for 72-hour weekend period).',
            clinicalInstructionTh:
                'บริหารยา 1,000–2,000 มก. (1–2 กรัม) IV ทันทีหลังฟอกเลือดเสร็จในวันที่มีการฟอกไต (1 กรัมสำหรับช่วงเว้นฟอกไต 48 ชม., 2 กรัมสำหรับช่วงวันหยุดยาว 72 ชม.)',
            provenance: Provenance(
              source: 'The Sanford Guide 2024 Table 10B / Lexicomp 2024 / Thai Nephrology Society',
              reviewedBy: 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
              reviewedAt: '2024-10-29',
            ),
          ),
          RenalReplacementProtocol(
            mode: RenalReplacementMode.capd,
            specificDose: 500.0,
            doseUnit: DoseUnit.mg,
            frequency: Frequency.q24h,
            requiresPostHdSupplement: false,
            clinicalInstructionEn:
                '500 mg IV q24h (or 1,000 mg IV q24–48h). (For CAPD peritonitis, 500 mg/L IP load then 125–250 mg/L IP maintenance).',
            clinicalInstructionTh:
                '500 มก. IV ทุก 24 ชม. (หรือ 1,000 มก. IV ทุก 24–48 ชม.) (หากเป็นเยื่อบุช่องท้องอักเสบ ให้ 500 มก./ลิตร IP ในถุงแรก จากนั้น 125–250 มก./ลิตร IP ในถุงถัดไป)',
            provenance: Provenance(
              source: 'The Sanford Guide 2024 Table 10B / Lexicomp 2024',
              reviewedBy: 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
              reviewedAt: '2024-10-29',
            ),
          ),
          RenalReplacementProtocol(
            mode: RenalReplacementMode.crrt,
            specificDose: 1000.0,
            doseUnit: DoseUnit.mg,
            frequency: Frequency.q12h,
            requiresPostHdSupplement: false,
            clinicalInstructionEn:
                'CRRT (CVVH/CVVHD/CVVHDF): 1,000–2,000 mg IV q12h (1,000 mg q12h for standard effluent, 2,000 mg q12h for severe infection / high effluent rate). Standard ESRD dose (500 mg q24h) causes severe underdosing in CRRT.',
            clinicalInstructionTh:
                'CRRT (CVVH/CVVHD/CVVHDF): 1,000–2,000 มก. IV ทุก 12 ชม. (1,000 มก. ทุก 12 ชม. สำหรับ effluent ปกติ, 2,000 มก. ทุก 12 ชม. สำหรับการติดเชื้อรุนแรงหรือ effluent สูง) ห้ามลดขนาดยาเหลือ 500 มก. วันละครั้งเหมือนไตวายทั่วไปเด็ดขาด',
            provenance: Provenance(
              source: 'The Sanford Guide 2024 Table 10B / KDIGO 2023 / Lexicomp 2024',
              reviewedBy: 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
              reviewedAt: '2024-10-29',
            ),
          ),
        ],
      ),
    ],
  ),
  const Drug(
    id: 'cephalexin',
    genericName: 'Cephalexin',
    brandNames: ['Keflex', 'Ibilex', 'Sporidex'],
    nameTh: 'เซฟาเล็กซิน',
    category: DrugCategory.antibiotic,
    drugClass: DrugClass.betaLactamCephalosporin,
    requiresRenalAdjustment: true,
    allergyClass: 'Cephalosporin (1st Gen)',
    sourceCitation:
        'The Sanford Guide to Antimicrobial Therapy 2024 / Lexicomp 2024 / US FDA Keflex SPL / RDU Thailand',
    lastReviewedDate: '2024-10-29',
    provenance: Provenance(
      source:
          'The Sanford Guide 2024 / Lexicomp Pediatric & Adult Drug Information / US FDA Keflex Label',
      reviewedBy:
          'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
      reviewedAt: '2024-10-29',
      sourceDetail:
          'First-Generation Cephalosporins - Cephalexin Adult & Pediatric Multi-Indication Dosing',
    ),
    monograph: ClinicalMonograph(
      textbookName: 'The Sanford Guide to Antimicrobial Therapy & Lexicomp',
      editionYear: '54th Edition, 2024',
      sectionOrTable: 'Cephalosporins (First Generation) - Cephalexin',
      dosingGuideline:
          '• ผู้ใหญ่ ติดเชื้อทั่วไป (Strep Pharyngitis / Skin & Soft Tissue / Uncomplicated Cystitis): 500 mg PO ทุก 12 ชม. หรือ 250 mg PO ทุก 6 ชม. นาน 7–14 วัน\n'
          '• ผู้ใหญ่ ติดเชื้อรุนแรง (Severe / Deep SSTI / Complicated UTI): 500 mg PO ทุก 6 ชม. (สูงสุดไม่เกิน 4,000 mg/วัน)\n'
          '• เด็ก ติดเชื้อทั่วไป (Pediatric Mild-to-Moderate): 25–50 mg/kg/วัน PO แบ่งทุก 6–12 ชม. (ขนาดมาตรฐาน 50 mg/kg/วัน แบ่ง q12h)\n'
          '• เด็ก หูชั้นกลางอักเสบ / ติดเชื้อรุนแรง (Pediatric Otitis Media / Severe): 75–100 mg/kg/วัน PO แบ่งทุก 6 ชม. (สูงสุด 4,000 mg/วัน)',
      renalGuideline:
          '• CrCl ≥ 30 mL/min: ไม่ต้องปรับขนาดยาตามปกติ\n'
          '• CrCl 15–29 mL/min: ผู้ใหญ่ 250–500 mg PO ทุก 8–12 ชม.\n'
          '• CrCl < 15 mL/min: ผู้ใหญ่ 250 mg PO ทุก 12–24 ชม. เด็ก ลดขนาดรวมต่อวันลง 50% และยืดระยะห่างเป็นทุก 12–24 ชม.',
      administrationGuideline:
          '• รับประทานได้ทั้งก่อนและหลังอาหาร (อาหารอาจชะลอเวลาดูดซึมเล็กน้อยแต่ไม่ลดปริมาณการดูดซึมรวม; หากคลื่นไส้แนะนำทานพร้อมอาหาร)\n'
          '• ยาน้ำแขวนตะกอน (125 mg/5 mL, 250 mg/5 mL): เขย่าขวดก่อนรินยาทุกครั้ง หลังผสมควรแช่ตู้เย็น (2–8°C) และใช้ให้หมดภายใน 14 วัน',
      clinicalNotes:
          '• ยา Cephalosporin รุ่นที่ 1 มีฤทธิ์ครอบคลุมเชื้อแกรมบวก (MSSA, Streptococci) ได้ดีเยี่ยม แต่ไม่ครอบคลุม MRSA หรือ Enterococci\n'
          '• ระวัง Cross-sensitivity ในผู้ที่มีประวัติแพ้ Penicillin แบบรุนแรง (Anaphylaxis / Stevens-Johnson)',
      externalUrl: 'https://www.sanfordguide.com',
    ),
    severeInteractions: [
      'Metformin (Increases metformin serum concentration by ~24–34%; monitor blood glucose)',
      'Probenecid (Inhibits renal tubular secretion and increases cephalexin levels)',
      'Warfarin (May enhance anticoagulant effect / monitor INR)',
    ],
    contraindications: [
      'Known hypersensitivity to cephalosporins or severe IgE-mediated beta-lactam allergy',
    ],
    specialNotes:
        'First-generation oral cephalosporin for skin/soft tissue, streptococcal pharyngitis, uncomplicated cystitis, and pediatric otitis media (75-100 mg/kg/day). Adjust dose if CrCl < 30 mL/min.',
    specialNotesTh:
        'ยาปฏิชีวนะกลุ่ม Cephalosporin รุ่นที่ 1 แบบรับประทาน สำหรับติดเชื้อผิวหนัง คออักเสบ ทางเดินปัสสาวะ และหูชั้นกลางอักเสบในเด็ก (75–100 mg/kg/วัน) ต้องปรับขนาดยาเมื่อ CrCl < 30 mL/min',
    sideEffects: [
      'Diarrhea, nausea, dyspepsia, abdominal pain',
      'Rash, urticaria, pruritus (hypersensitivity)',
      'Transient elevation of hepatic transaminases',
      'Eosinophilia or C. difficile colitis (rare)',
    ],
    sideEffectsTh: [
      'ท้องเสีย คลื่นไส้ ปวดมวนท้อง อาหารไม่ย่อย',
      'ผื่นแพ้ยา ลมพิษ คันตามผิวหนัง',
      'ค่าเอนไซม์ตับเพิ่มขึ้นชั่วคราว',
      'ลำไส้อักเสบจากเชื้อ C. difficile (พบน้อย)',
    ],
    regimens: [
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Standard Infection / Skin / Cystitis (Adult PO)',
        dosingType: DosingType.fixed,
        fixedDose: 500.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q12h,
        population: PopulationCriteria(minAgeMonths: 216),
        audience: RegimenAudience.adult,
        notes: 'Mild-to-moderate SSTI, streptococcal pharyngitis, or uncomplicated cystitis: 500 mg PO q12h (or 250 mg PO q6h) for 7–14 days.',
        notesTh: 'ติดเชื้อทั่วไป / ผิวหนัง / คออักเสบ / กระเพาะปัสสาวะอักเสบ (ผู้ใหญ่ PO): 500 mg PO ทุก 12 ชม. (หรือ 250 mg ทุก 6 ชม.)',
        limits: DoseLimit(maxSingleDose: 1000.0, maxDailyDose: 4000.0),
        renalAdjustments: [
          RenalAdjustment(
            crclMin: 0,
            crclMax: 15,
            adjustmentFactor: 1.0,
            absoluteDose: 250.0,
            adjustedFrequency: Frequency.q12h,
            notes: 'CrCl < 15 mL/min: 250 mg PO q12–24h',
          ),
          RenalAdjustment(
            crclMin: 15,
            crclMax: 30,
            adjustmentFactor: 1.0,
            absoluteDose: 250.0,
            adjustedFrequency: Frequency.q8h,
            notes: 'CrCl 15–29 mL/min: 250–500 mg PO q8–12h',
          ),
        ],
      ),
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Severe / Deep Infection / Cellulitis (Adult PO)',
        dosingType: DosingType.fixed,
        fixedDose: 500.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q6h,
        population: PopulationCriteria(minAgeMonths: 216),
        audience: RegimenAudience.adult,
        notes: 'More severe infections or less susceptible organisms: 500 mg PO q6h (up to 1,000 mg PO q6h; max 4,000 mg/day).',
        notesTh: 'ติดเชื้อรุนแรง / เซลล์เนื้อเยื่ออักเสบ (ผู้ใหญ่ PO): 500 mg PO ทุก 6 ชม. (สูงสุด 4,000 mg/วัน)',
        limits: DoseLimit(maxSingleDose: 1000.0, maxDailyDose: 4000.0),
        renalAdjustments: [
          RenalAdjustment(
            crclMin: 0,
            crclMax: 15,
            adjustmentFactor: 1.0,
            absoluteDose: 250.0,
            adjustedFrequency: Frequency.q12h,
            notes: 'CrCl < 15 mL/min: 250 mg PO q12h',
          ),
          RenalAdjustment(
            crclMin: 15,
            crclMax: 30,
            adjustmentFactor: 1.0,
            absoluteDose: 500.0,
            adjustedFrequency: Frequency.q12h,
            notes: 'CrCl 15–29 mL/min: 500 mg PO q12h',
          ),
        ],
      ),
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Mild-to-Moderate Infection (Pediatric PO)',
        dosingType: DosingType.weightBased,
        dosePerKg: 50.0,
        minDosePerKg: 25.0,
        maxDosePerKg: 50.0,
        doseBasis: DoseBasis.perDay,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q12h,
        population: PopulationCriteria(maxAgeMonths: 215),
        audience: RegimenAudience.pediatric,
        notes: 'Pediatric mild-to-moderate infections (SSTI, pharyngitis, UTI): 25–50 mg/kg/day PO divided q6–12h (default 50 mg/kg/day divided q12h).',
        notesTh: 'ติดเชื้อทั่วไปในเด็ก (เด็ก PO): 25–50 mg/kg/วัน แบ่งทุก 6–12 ชม. (ค่ามาตรฐาน 50 mg/kg/วัน แบ่ง q12h)',
        limits: DoseLimit(maxSingleDose: 1000.0, maxDailyDose: 4000.0, maxDosePerKgPerDay: 100.0),
        renalAdjustments: [
          RenalAdjustment(
            crclMin: 0,
            crclMax: 30,
            adjustmentFactor: 0.5,
            notes: 'CrCl < 30 mL/min: Reduce total daily dose by 50% and extend interval',
          ),
        ],
      ),
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Otitis Media / Severe Infection (Pediatric PO)',
        dosingType: DosingType.weightBased,
        dosePerKg: 75.0,
        minDosePerKg: 75.0,
        maxDosePerKg: 100.0,
        doseBasis: DoseBasis.perDay,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q6h,
        population: PopulationCriteria(maxAgeMonths: 215),
        audience: RegimenAudience.pediatric,
        notes: 'Pediatric acute otitis media or severe osteomyelitis/SSTI: 75–100 mg/kg/day PO divided q6h (max 4,000 mg/day).',
        notesTh: 'หูชั้นกลางอักเสบ / ติดเชื้อรุนแรง (เด็ก PO): 75–100 mg/kg/วัน แบ่งทุก 6 ชม. (สูงสุด 4,000 mg/วัน)',
        limits: DoseLimit(maxSingleDose: 1000.0, maxDailyDose: 4000.0, maxDosePerKgPerDay: 100.0),
        renalAdjustments: [
          RenalAdjustment(
            crclMin: 0,
            crclMax: 30,
            adjustmentFactor: 0.5,
            notes: 'CrCl < 30 mL/min: Avoid high-dose AOM regimen or reduce daily dose by 50%',
          ),
        ],
      ),
    ],
  ),
  Drug(
    id: 'piperacillin_tazobactam',
    genericName: 'Piperacillin/Tazobactam',
    brandNames: ['Tazocin'],
    nameTh: 'ไพเพอราซิลลิน/ทาโซแบคแตม',
    category: DrugCategory.antibiotic,
    pregnancyCategory: 'B',
    requiresRenalAdjustment: true,
    drugClass: DrugClass.betaLactamPenicillin,
    sourceCitation: 'The Sanford Guide to Antimicrobial Therapy 2024 / Zosyn FDA Label §2.2',
    lastReviewedDate: '2024-10-14',
    provenance: const Provenance(
      source: 'The Sanford Guide 2024 Table 10 & Zosyn Prescribing Information §2.2',
      reviewedBy: 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
      reviewedAt: '2024-10-14',
      sourceDetail: 'Table 10 (Antipseudomonal Penicillins), Page 126 & Zosyn FDA Label §2.2',
    ),
    monograph: const ClinicalMonograph(
      textbookName: 'The Sanford Guide to Antimicrobial Therapy',
      editionYear: '54th Edition, 2024',
      sectionOrTable: 'Table 10 (Piperacillin/Tazobactam Dosage & Renal Adjustments)',
      dosingGuideline:
          '• การติดเชื้อรุนแรงทั่วไป (Severe Nosocomial Infections/Sepsis): 4.5 g IV ทุก 6 ชม. (ดริปปกติ 30 นาที) หรือ 4.5 g IV ทุก 8 ชม. แบบ Extended Infusion (ดริปนาน 4 ชม.)\n'
          '• ขนาดยาเด็ก (Pediatric Dosing >= 2 months): 80–100 mg/kg IV ทุก 6–8 ชม. (สูงสุดไม่เกิน 4.5 g ต่อครั้ง)',
      renalGuideline:
          '• CrCl > 40 mL/min: 4.5 g IV ทุก 6 ชม. (หรือ 4.5 g ทุก 8 ชม. Extended Infusion 4 ชม.)\n'
          '• CrCl 20–40 mL/min: 3.375 g IV ทุก 6 ชม. (75% ของขนาดปกติ; หรือ 3.375–4.5 g ทุก 8 ชม. over 4h)\n'
          '• CrCl < 20 mL/min: 2.25 g IV ทุก 6 ชม. (50% ของขนาดปกติ)\n'
          '• Hemodialysis: 2.25 g IV ทุก 8–12 ชม. และให้ 0.75 g เสริมทันทีหลังฟอกเลือดเสร็จในวันที่มีการฟอกไต',
      administrationGuideline:
          '• ละลายผงยา 4.5 g ด้วย Sterile Water หรือ NSS 20 mL แล้วเจือจางต่อใน NSS หรือ D5W 50–100 mL\n'
          '• การให้แบบ Extended Infusion (หยดยาว 4 ชม.): ช่วยเพิ่มระยะเวลาที่ระดับยาในเลือดสูงกว่า MIC (Time > MIC) เพิ่มอัตราการรอดชีวิตในผู้ป่วย ICU',
      clinicalNotes:
          '• ห้ามใช้ในผู้ป่วยที่มีประวัติแพ้ยากลุ่ม Penicillin แบบรุนแรง (Anaphylaxis, Angioedema, SJS/TEN)\n'
          '• คำเตือนสำคัญเรื่องอันตรกิริยา (Major DDI): เมื่อใช้ร่วมกับ Vancomycin เพิ่มความเสี่ยงเกิดภาวะไตวายเฉียบพลัน (Acute Kidney Injury - AKI) สูงขึ้น 3-4 เท่า แนะนำติดตาม Serum Creatinine ทุกวัน',
      externalUrl: 'https://www.sanfordguide.com',
    ),
    ivDiluentCompatibility: const IvDiluentCompatibility(
      compatibleDiluents: [IvDiluent.nss, IvDiluent.d5w],
      preferredDiluent: IvDiluent.nss,
      incompatibleDiluents: [IvDiluent.lrs],
      incompatibilityReasonEn:
          'Avoid LRS unless an EDTA-stabilized formulation is confirmed; use NSS or D5W.',
      incompatibilityReasonTh:
          'หลีกเลี่ยง LRS หากไม่ยืนยันสูตรที่มี EDTA; ใช้ NSS หรือ D5W',
      stabilityNoteEn:
          'Reconstitute with 20 mL SWFI/NSS; dilute in 50–150 mL NSS/D5W. Stable 24 h at room temperature (4-h extended infusion). Check concentration compatibility before Y-site with aminoglycosides or vancomycin.',
      stabilityNoteTh:
          'ละลายด้วย SWFI/NSS 20 mL; เจือจางใน NSS/D5W 50–150 mL. คงตัว 24 ชม. (หยดยาว 4 ชม.). ตรวจสอบความเข้ากันได้ก่อนให้ Y-site กับ Aminoglycosides หรือ Vancomycin',
      sourceCitation:
          'US FDA Zosyn SPL §2.5 / Trissel\'s Handbook / คู่มือยาฉีดรามาธิบดี',
    ),
    interactions: [
      DrugInteraction(
        targetDrugId: 'vancomycin',
        severity: InteractionSeverity.major,
        mechanismEn:
            'Synergistic tubular toxicity causing Acute Interstitial Nephritis (AIN) and acute kidney injury.',
        mechanismTh:
            'กลไกส่งเสริมความเป็นพิษต่อท่อไต ทำให้เกิด Acute Interstitial Nephritis และเพิ่มความเสี่ยงไตวายเฉียบพลัน',
        managementEn:
            'Monitor renal function closely daily. Consider alternative regimen (e.g. Cefepime + Vancomycin or Meropenem) in high-risk patients.',
        managementTh:
            'ติดตามค่าการทำงานของไต (SCr, Urine Output) ทุกวัน หากเป็นไปได้ควรเลี่ยงไปใช้ Cefepime หรือ Meropenem ร่วมกับ Vancomycin แทน',
        source: 'Lexicomp / Sanford Guide 2024 / IDSA Guidelines',
      ),
      DrugInteraction(
        targetDrugId: 'methotrexate',
        severity: InteractionSeverity.major,
        mechanismEn:
            'Piperacillin inhibits renal tubular secretion of methotrexate, increasing serum levels and risk of severe toxicity.',
        mechanismTh:
            'Piperacillin ยับยั้งการขับ Methotrexate ออกทางไต ทำให้ระดับ Methotrexate ในเลือดสูงขึ้น เสี่ยงกดไขกระดูกรุนแรง',
        managementEn: 'Avoid concomitant use or monitor methotrexate levels closely.',
        managementTh: 'หลีกเลี่ยงการใช้ร่วมกัน หรือติดตามระดับยา Methotrexate และเฝ้าระวังพิษต่อตับไตและไขกระดูก',
        source: 'Lexicomp Drug Interactions 2024',
      ),
    ],
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Severe infections',
        dosingType: DosingType.fixed,
        fixedDose: 4.5,
        doseUnit: DoseUnit.g,
        frequency: Frequency.q6h,
        infusionTimeMinutes: 30,
        formulation: DrugFormulation.ivInfusion,
        reconstitution: const ReconstitutionInfo(
          vialStrengthMg: 4500.0,
          diluentName: 'SWFI or 0.9% NSS',
          diluentVolumeMl: 20.0,
          displacedVolumeMl: 3.0,
          resultingConcentrationMgPerMl: 200.0,
          instructionsEn:
              'Reconstitute 4.5 g vial with 20 mL SWFI or NSS (displaces ~3 mL to yield ~23 mL total at ~200 mg/mL piperacillin).',
          instructionsTh:
              'ละลายผงยา 4.5 กรัม ด้วยน้ำกลั่นหรือ NSS 20 มล. (ผงยาเพิ่มปริมาตร ~3 มล. รวมเป็น ~23 มล. ได้ความเข้มข้น ~200 มก./มล.)',
          sourceCitation:
              'Drug Information Handbook (Lexicomp) 2024 / The Sanford Guide 2024',
        ),
        reconstitutionConcentrationMgPerMl: 200.0,
        standardDilutionBagMl: 100.0,
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
        renalReplacementProtocols: const [
          RenalReplacementProtocol(
            mode: RenalReplacementMode.ihd,
            specificDose: 2.25,
            doseUnit: DoseUnit.g,
            frequency: Frequency.q8h,
            requiresPostHdSupplement: true,
            clinicalInstructionEn:
                '2.25 g IV q8h (or 2.25 g q12h with 0.75 g supplemental dose post-HD). On hemodialysis days, administer dose immediately following hemodialysis.',
            clinicalInstructionTh:
                '2.25 g IV ทุก 8 ชม. (หรือ 2.25 g ทุก 12 ชม. โดยให้ยาเสริม 0.75 g ทันทีหลังฟอกไต) ในวันฟอกเลือดให้บริหารยาหลังฟอกเสร็จ',
            provenance: Provenance(
              source: 'The Sanford Guide 2024 Table 10B / Zosyn FDA Label §2.2 / Lexicomp 2024',
              reviewedBy: 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
              reviewedAt: '2024-10-29',
            ),
          ),
          RenalReplacementProtocol(
            mode: RenalReplacementMode.capd,
            specificDose: 2.25,
            doseUnit: DoseUnit.g,
            frequency: Frequency.q12h,
            requiresPostHdSupplement: false,
            clinicalInstructionEn:
                '2.25 g IV q12h (or 2.25 g q8h for severe/Pseudomonal infection). Peritoneal dialysis clears < 10% of drug.',
            clinicalInstructionTh:
                '2.25 g IV ทุก 12 ชม. (หรือ 2.25 g ทุก 8 ชม. ในการติดเชื้อรุนแรง) การล้างไตทางช่องท้องขจัดยาน้อยกว่า 10%',
            provenance: Provenance(
              source: 'The Sanford Guide 2024 Table 10B / Lexicomp 2024',
              reviewedBy: 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
              reviewedAt: '2024-10-29',
            ),
          ),
          RenalReplacementProtocol(
            mode: RenalReplacementMode.crrt,
            specificDose: 3.375,
            doseUnit: DoseUnit.g,
            frequency: Frequency.q6h,
            requiresPostHdSupplement: false,
            clinicalInstructionEn:
                'CRRT (CVVH/CVVHD/CVVHDF): 3.375 g IV q6h (or 4.5 g IV q8h over 4 hours extended infusion). For high effluent rates (> 30 mL/kg/h) or Pseudomonas, 4.5 g q6h may be required. Do not reduce to ESRD dose (2.25 g q12h) to avoid fatal sepsis underdosing.',
            clinicalInstructionTh:
                'CRRT (CVVH/CVVHD/CVVHDF): 3.375 กรัม IV ทุก 6 ชม. (หรือ 4.5 กรัม IV ทุก 8 ชม. หยดยาวนาน 4 ชม.) ในรายที่ effluent rate สูงหรือติดเชื้อ Pseudomonas อาจใช้ 4.5 กรัม ทุก 6 ชม. ห้ามลดขนาดยาเหลือ 2.25 กรัม ทุก 12 ชม. เพื่อป้องกันภาวะ underdose เสี่ยงเสียชีวิตในผู้ป่วย Sepsis',
            provenance: Provenance(
              source: 'The Sanford Guide 2024 Table 10B / KDIGO 2023 / Lexicomp 2024',
              reviewedBy: 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
              reviewedAt: '2024-10-29',
            ),
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
        route: DoseRoute.ivInfusion,
        indication: 'Pseudomonas / Febrile neutropenia',
        dosingType: DosingType.fixed,
        fixedDose: 2,
        doseUnit: DoseUnit.g,
        frequency: Frequency.q8h,
        formulation: DrugFormulation.ivInfusion,
        reconstitution: ReconstitutionInfo(
          vialStrengthMg: 1000.0,
          diluentName: 'SWFI or 0.9% NSS',
          diluentVolumeMl: 10.0,
          resultingConcentrationMgPerMl: 100.0,
          instructionsEn:
              'Reconstitute 1 g vial with 10 mL SWFI or NSS to yield 100 mg/mL.',
          instructionsTh:
              'ละลายผงยา 1 กรัม ด้วยน้ำกลั่นหรือ NSS 10 มล. ได้ความเข้มข้น 100 มก./มล.',
          sourceCitation:
              'Drug Information Handbook (Lexicomp) 2024 / The Sanford Guide 2024',
        ),
        reconstitutionConcentrationMgPerMl: 100.0,
        standardDilutionBagMl: 100.0,
        infusionTimeMinutes: 30.0,
        limits: DoseLimit(maxDailyDose: 6),
        renalAdjustments: [
          RenalAdjustment(
            crclMin: 30,
            crclMax: 60,
            adjustmentFactor: 1.0,
            adjustedFrequency: Frequency.q12h,
            notes: '2 g IV q12h in CrCl 30-60 mL/min',
          ),
          RenalAdjustment(
            crclMin: 11,
            crclMax: 30,
            adjustmentFactor: 1.0,
            adjustedFrequency: Frequency.q24h,
            notes: '2 g IV q24h in CrCl 11-29 mL/min',
          ),
          RenalAdjustment(
            crclMin: 0,
            crclMax: 11,
            adjustmentFactor: 0.5,
            absoluteDose: 1.0,
            adjustedFrequency: Frequency.q24h,
            notes: '1 g IV q24h in CrCl < 11 mL/min',
          ),
        ],
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
  Drug(
    id: 'colistin',
    genericName: 'Colistin (Colistimethate Sodium)',
    brandNames: ['Colomycin'],
    drugClass: DrugClass.polymyxin,
    sourceCitation: 'The Sanford Guide to Antimicrobial Therapy 2024 / แนวทางสมาคมโรคติดเชื้อแห่งประเทศไทย (IDAT)',
    lastReviewedDate: '2024-10-14',
    provenance: const Provenance(
      source: 'The Sanford Guide 2024 Table 10 & Tsuji BT et al. Pharmacotherapy 2019;39(1):10-39',
      reviewedBy: 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
      reviewedAt: '2024-10-14',
      sourceDetail: 'Table 10 (Polymyxins) & 2019 International Consensus Guidelines Table 2',
    ),
    monograph: const ClinicalMonograph(
      textbookName: 'The Sanford Guide to Antimicrobial Therapy',
      editionYear: '54th Edition, 2024',
      sectionOrTable: 'Table 10 (Colistin Dosage & Renal Adjustments) / Tsuji et al. 2019',
      dosingGuideline:
          '• ขนาดยาเริ่มต้น (Loading Dose ในผู้ป่วยวิกฤต): 300 mg Colistin Base Activity (CBA) หรือประมาณ 9 ล้านยูนิต (IU) IV หยดนาน 0.5–1 ชม.\n'
          '• ขนาดยาต่อเนื่อง (Maintenance Dose ในผู้ที่ไตปกติ): 150–180 mg CBA ทุก 12 ชม. (300–360 mg CBA/วัน หรือประมาณ 9–10.8 ล้าน IU/วัน)\n'
          '• หมายเหตุเรื่องหน่วยยาในไทย: 1 ล้าน IU = 80 mg Colistimethate Sodium (CMS) = ~33.3 mg Colistin Base Activity (CBA)',
      renalGuideline:
          '• CrCl >= 50 mL/min: 150–180 mg CBA ทุก 12 ชม. (300–360 mg CBA/วัน)\n'
          '• CrCl 30–49 mL/min: 110–130 mg CBA ทุก 12 ชม. (220–260 mg CBA/วัน)\n'
          '• CrCl 10–29 mL/min: 160 mg CBA ทุก 24 ชม. (หรือ 80 mg CBA ทุก 12 ชม.)\n'
          '• CrCl < 10 mL/min: 130 mg CBA ทุก 24 ชม. (หรือ 65 mg CBA ทุก 12 ชม.)\n'
          '• Hemodialysis: 130 mg CBA/วัน และให้ 40–50 mg CBA เสริมหลังฟอกเลือดเสร็จในวันที่มีการฟอกไต (Loading dose 300 mg CBA ไม่ต้องปรับลดในผู้ป่วยไตวาย)',
      administrationGuideline:
          '• ละลายผงยาด้วย Sterile Water 2–3 mL ต่อขวด แล้วเจือจางใน NSS หรือ D5W 100 mL\n'
          '• ระยะเวลาหยดยา: หยดช้าๆ นาน 1–2 ชม. (ห้ามฉีดเร็วเข้าเส้นเลือดโดยตรงเพื่อป้องกันภาวะหยุดหายใจจาก Neuromuscular Blockade)',
      clinicalNotes:
          '• จัดเป็นยาเตือนภัยสูง (High-Alert Drug)\n'
          '• พิษต่อไต (Nephrotoxicity): สูงถึง 30–50% ในผู้ป่วยวิกฤต ต้องติดตาม Serum Creatinine และสารน้ำอย่างใกล้ชิด\n'
          '• พิษต่อระบบประสาท (Neurotoxicity/Neuromuscular Blockade): ชาปลายมือปลายเท้า เวียนศีรษะ และอาจเกิดภาวะกล้ามเนื้อหายใจอ่อนแรง โดยเฉพาะเมื่อใช้ร่วมกับยาคลายกล้ามเนื้อหรือ Aminoglycosides',
      externalUrl: 'https://www.sanfordguide.com',
    ),
    interactions: [
      DrugInteraction(
        targetDrugId: 'gentamicin',
        severity: InteractionSeverity.major,
        mechanismEn:
            'Profound additive acute tubular necrosis and neuromuscular blockade.',
        mechanismTh:
            'เพิ่มพิษทำลายเซลล์ท่อไตอย่างรุนแรง และเสริมฤทธิ์กดการทำงานของกล้ามเนื้อหายใจ',
        managementEn:
            'Avoid concomitant use if possible. If required, monitor renal function and respiratory status in ICU.',
        managementTh:
            'หลีกเลี่ยงการใช้ร่วมกัน หากจำเป็นต้องติดตามค่าไตและการหายใจอย่างใกล้ชิดในหอผู้ป่วยวิกฤต',
        source: 'The Sanford Guide 2024 / IDAT Guidelines',
      ),
    ],
    nameTh: 'โคลิสติน',
    ivDiluentCompatibility: const IvDiluentCompatibility(
      compatibleDiluents: [IvDiluent.nss, IvDiluent.d5w],
      preferredDiluent: IvDiluent.nss,
      stabilityNoteEn:
          'Gently reconstitute with SWFI/NSS; avoid shaking. Dilute in 50–100 mL NSS/D5W and administer promptly after dilution.',
      stabilityNoteTh:
          'ละลายเบาๆ ด้วย SWFI/NSS ห้ามเขย่าแรง; เจือจางใน NSS/D5W 50–100 mL และให้ยาทันทีหลังผสม',
      sourceCitation:
          'US FDA Coly-Mycin M Parenteral SPL / Tsuji BT et al. Pharmacotherapy 2019 / คู่มือยาฉีดรามาธิบดี',
    ),
    category: DrugCategory.antibiotic,
    requiresRenalAdjustment: true,
    isHighAlert: false,
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
        doseCap: 300.0,
        limits: DoseLimit(maxSingleDose: 300.0), // Max 300 mg CBA (or 9 million IU)
        renalAdjustments: [
          RenalAdjustment(
            crclMin: 0,
            crclMax: 50,
            adjustmentFactor: 1.0,
            notes: 'Loading dose (300 mg CBA) is NOT reduced in renal failure to achieve therapeutic level rapidly. Adjust subsequent maintenance doses.',
          ),
        ],
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
          RenalAdjustment(
            crclMin: 30,
            crclMax: 50,
            action: RenalAction.adjust,
            absoluteDose: 110.0,
            adjustedFrequency: Frequency.q12h,
            notes: '110 mg CBA q12h (220 mg CBA/day; Tsuji 2019 International Consensus Guidelines)',
          ),
          RenalAdjustment(
            crclMin: 10,
            crclMax: 30,
            action: RenalAction.adjust,
            absoluteDose: 160.0,
            adjustedFrequency: Frequency.q24h,
            notes: '160 mg CBA q24h (or 80 mg CBA q12h; Tsuji 2019 International Consensus Guidelines)',
          ),
          RenalAdjustment(
            crclMin: 0,
            crclMax: 10,
            action: RenalAction.adjust,
            absoluteDose: 130.0,
            adjustedFrequency: Frequency.q24h,
            notes: '130 mg CBA q24h (or 65 mg CBA q12h; +40-50 mg CBA post-HD; Tsuji 2019)',
          ),
        ],
        renalReplacementProtocols: const [
          RenalReplacementProtocol(
            mode: RenalReplacementMode.ihd,
            specificDose: 130.0,
            doseUnit: DoseUnit.mg,
            frequency: Frequency.q24h,
            requiresPostHdSupplement: true,
            clinicalInstructionEn:
                '130 mg CBA (~4 MIU) IV q24h. On hemodialysis days, administer a supplemental dose of 40–50 mg CBA (~1.2–1.5 MIU) immediately POST-hemodialysis. Loading dose 300 mg CBA is not reduced.',
            clinicalInstructionTh:
                '130 mg CBA (~4 ล้าน IU) IV ทุก 24 ชม. ในวันฟอกไต ให้ยาเสริม 40–50 mg CBA (~1.2–1.5 ล้าน IU) ทันทีหลังฟอกเลือดเสร็จ (Loading dose 300 mg CBA ไม่ต้องปรับลดในผู้ป่วยฟอกไต)',
            provenance: Provenance(
              source: 'Tsuji et al. Pharmacotherapy 2019 / The Sanford Guide 2024 Table 10B / Lexicomp 2024',
              reviewedBy: 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
              reviewedAt: '2024-10-29',
            ),
          ),
          RenalReplacementProtocol(
            mode: RenalReplacementMode.capd,
            specificDose: 130.0,
            doseUnit: DoseUnit.mg,
            frequency: Frequency.q24h,
            requiresPostHdSupplement: false,
            clinicalInstructionEn:
                '110–130 mg CBA (~3.3–4 MIU) IV q24h (or 65 mg CBA q12h). Loading dose 300 mg CBA once. Peritoneal clearance is minimal.',
            clinicalInstructionTh:
                '110–130 mg CBA (~3.3–4 ล้าน IU) IV ทุก 24 ชม. (หรือ 65 mg CBA ทุก 12 ชม.) Loading dose 300 mg CBA ครั้งแรก การล้างไตทางช่องท้องขจัดยาน้อยมาก',
            provenance: Provenance(
              source: 'Tsuji et al. 2019 / The Sanford Guide 2024 Table 10B',
              reviewedBy: 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
              reviewedAt: '2024-10-29',
            ),
          ),
          RenalReplacementProtocol(
            mode: RenalReplacementMode.crrt,
            specificDose: 130.0,
            doseUnit: DoseUnit.mg,
            frequency: Frequency.q12h,
            requiresPostHdSupplement: false,
            clinicalInstructionEn:
                'CRRT (CVVH/CVVHD/CVVHDF): Loading dose 300 mg CBA (~9 MIU). Maintenance: 110–130 mg CBA (~3.3–4 MIU) IV q12h (total 220–260 mg CBA/day; increase to 150 mg q12h for high effluent rates). CRRT filters clear CMS/colistin extensively; never use standard ESRD dose (130 mg/day).',
            clinicalInstructionTh:
                'CRRT (CVVH/CVVHD/CVVHDF): Loading dose 300 mg CBA (~9 ล้าน IU) จากนั้นขนาดยาต่อเนื่อง 110–130 mg CBA (~3.3–4 ล้าน IU) IV ทุก 12 ชม. (รวม 220–260 mg CBA/วัน; ปรับเป็น 150 mg ทุก 12 ชม. หาก effluent rate สูง) ห้ามลดเหลือ 130 mg/วัน เหมือนไตวายทั่วไปเด็ดขาดเนื่องจากตัวกรอง CRRT ขจัดยาทั้ง CMS และ Colistin ออกอย่างมาก',
            provenance: Provenance(
              source: 'Tsuji et al. 2019 / The Sanford Guide 2024 Table 10B / KDIGO 2023',
              reviewedBy: 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Pharmacist Review)',
              reviewedAt: '2024-10-29',
            ),
          ),
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
    isHighAlert: false,
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
        doseCap: 600.0,
        doseCapCitation: 'WHO Treatment of Tuberculosis Guidelines / Sanford Guide 2023',
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
        doseCap: 300.0,
        doseCapCitation: 'WHO Treatment of Tuberculosis Guidelines / Sanford Guide 2023',
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
    sideEffects: ['Reduced visual acuity', 'Red-green color blindness'],
    sideEffectsTh: ['การมองเห็นลดลง', 'ตาบอดสีแดง-เขียว'],
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
