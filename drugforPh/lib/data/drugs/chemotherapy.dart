import '../../core/models/models.dart';

final List<Drug> chemotherapy = [
  Drug(
    id: 'carboplatin',
    genericName: 'Carboplatin',
    brandNames: ['Paraplatin'],
    nameTh: 'คาร์โบพลาติน',
    category: DrugCategory.chemotherapy,
    isHighAlert: true,
    requiresRenalAdjustment: true,
    specialNotes: 'Dosed using Calvert formula based on GFR.',
    specialNotesTh: 'คำนวณโดสด้วยสูตร Calvert โดยใช้ค่า GFR',
    doseRules: [
      DoseRule(
        id: 'carboplatin_severe_renal_advisory',
        name: 'Carboplatin Severe Renal Impairment Advisory (CrCl < 15 mL/min)',
        sourceCitation: 'Calvert AH et al. J Clin Oncol 1989; NCCN Clinical Practice Guidelines in Oncology',
        verificationStatus: VerificationStatus.verified,
        applies: (ctx) => ctx.crclMlMin != null && ctx.crclMlMin! < 15.0,
        evaluate: (ctx) {
          final crcl = ctx.crclMlMin!;
          const alt1En =
              'Target AUC Reduction: Reduce target AUC by 20–30% (e.g. target AUC 3–4 instead of 5–6) to mitigate severe thrombocytopenia and myelosuppression (Recommended).';
          const alt1Th =
              'ปรับลดเป้าหมาย AUC: ลดเป้าหมาย AUC ลง 20–30% (เช่น ปรับเป็น AUC 3–4 แทน 5–6) เพื่อลดความเสี่ยงเกล็ดเลือดต่ำและกดไขกระดูกรุนแรง (แนะนำ)';
          const alt2En =
              'Intensive Hematologic Monitoring: If maintaining AUC, monitor weekly CBC with platelet nadir counts and prepare for transfusion support.';
          const alt2Th =
              'ติดตามโลหิตวิทยาอย่างเข้มงวด: หากคงขนาดยาเดิม ต้องตรวจ CBC และเกล็ดเลือดทุกสัปดาห์และเตรียมพร้อมรับมือเกล็ดเลือดต่ำวิกฤต';
          const alt3En =
              'Oncology Consultation: Consult medical oncology to consider alternative non-nephrotoxic chemotherapy.';
          const alt3Th =
              'ปรึกษาแพทย์มะเร็งวิทยา: พิจารณาเปลี่ยนไปใช้ยาเคมีบำบัดสูตรอื่นที่ไม่มีผลต่อไต';

          return DoseRuleResult(
            warnings: [
              DoseWarning(
                severity: LimitSeverity.soft,
                code: DoseWarningCode.severeRenalImpairment,
                messageEn:
                    'SEVERE RENAL IMPAIRMENT (CrCl ${crcl.toStringAsFixed(1)} mL/min < 15 mL/min): '
                    'Calvert formula accuracy is limited in severe renal dysfunction. Recommend oncology consult. '
                    'Alternatives: 1) $alt1En 2) $alt2En 3) $alt3En',
                messageTh:
                    'ไตบกพร่องรุนแรง (CrCl ${crcl.toStringAsFixed(1)} มล./นาที < 15 มล./นาที): '
                    'การคำนวณโดส Carboplatin ในผู้ป่วยไตบกพร่องรุนแรงเสี่ยงต่อภาวะกดไขกระดูกและเกล็ดเลือดต่ำวิกฤต '
                    'ทางเลือก: 1) $alt1Th 2) $alt2Th 3) $alt3Th',
                calculatedValue: crcl,
                limitValue: 15.0,
                unit: 'mL/min',
                clinicalAlternativesEn: [alt1En, alt2En, alt3En],
                clinicalAlternativesTh: [alt1Th, alt2Th, alt3Th],
              ),
            ],
          );
        },
      ),
    ],
    regimens: [
      const DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Ovarian Cancer / Solid Tumors',
        dosingType: DosingType.gfrBased, // Calvert formula
        targetAuc: 5.0, // Often 4-6
        doseUnit: DoseUnit.mg,
        frequency: Frequency(isOnce: true, displayEn: 'Once per cycle', displayTh: 'ครั้งเดียวต่อรอบการรักษา'),
        limits: DoseLimit(
          maxSingleDose: 900.0,
        ),
      ),
    ],
  ),
  const Drug(
    id: 'methotrexate',
    genericName: 'Methotrexate',
    brandNames: ['Trexall', 'Rheumatrex'],
    nameTh: 'เมโธเทรกเซต',
    category: DrugCategory.chemotherapy,
    isHighAlert: true,
    requiresRenalAdjustment: true,
    specialNotes: 'High dose requires leucovorin rescue. Fatal if dosed daily instead of weekly for RA.',
    specialNotesTh: 'โดสสูงต้องใช้ leucovorin ช่วย. ระวังการให้ยาทุกวันแทนรายสัปดาห์ในผู้ป่วย RA',
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'High-Dose Oncology',
        dosingType: DosingType.bsaBased,
        dosePerM2: 12000.0, // Up to 12 g/m2
        doseUnit: DoseUnit.mg,
        frequency: Frequency(isOnce: true, displayEn: 'Once per cycle', displayTh: 'ครั้งเดียวต่อรอบการรักษา'),
      ),
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Rheumatoid Arthritis',
        dosingType: DosingType.fixed,
        fixedDose: 7.5, // 7.5 to 25 mg weekly
        doseUnit: DoseUnit.mg,
        frequency: Frequency.weekly,
        limits: DoseLimit(
          maxSingleDose: 30.0,
        ),
      ),
    ],
  ),
];

