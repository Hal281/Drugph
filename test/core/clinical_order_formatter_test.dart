// ============================================================
// Clinical Order Formatter Unit Tests
// ============================================================
// Validates pure deterministic clinical order formatting for HIS
// and structured clinical pharmacist consultation progress notes.
//
// Covers all 5 clinical edge cases:
// (a) Standard regimen (fixed / weight-based)
// (b) Renal-adjusted regimen with CrCl and guideline citation
// (c) Continuous / titrated IV infusion with calculated pump rate
// (d) Overdose-flagged calculation with safety tag
// (e) Unverified regimen with safety tag
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/core.dart';

void main() {
  group('ClinicalOrderFormatter Unit Tests', () {
    const defaultPatient = Patient(
      id: 'PT-001',
      patientName: 'Somchai Jaidee',
      hospitalNumber: 'HN-123456',
      weightKg: 70.0,
      heightCm: 175.0,
      ageYears: 45,
      sex: Sex.male,
      serumCreatinineMgDl: 1.0,
      isScrStable: true,
      allergies: ['Penicillin'],
    );

    // ------------------------------------------------------------
    // (a) Standard Regimen (Fixed / Weight-based)
    // ------------------------------------------------------------
    test('(a) Standard fixed/weight-based regimen formatting', () {
      const regimen = DosingRegimen(
        route: DoseRoute.po,
        indication: 'Fever and Mild Pain',
        dosingType: DosingType.fixed,
        fixedDose: 500.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency(
          intervalHours: 6,
          isPrn: true,
          displayEn: 'q6h PRN',
          displayTh: 'ทุก 6 ชม. เมื่อจำเป็น',
        ),
        verificationStatus: VerificationStatus.verified,
      );

      const drug = Drug(
        id: 'paracetamol',
        genericName: 'Paracetamol',
        nameTh: 'พาราเซตามอล',
        brandNames: ['Tylenol', 'Sara'],
        category: DrugCategory.analgesic,
        availableStrengths: [500.0],
        sourceCitation: 'Lexicomp Drug Information 2024',
        regimens: [regimen],
        provenance: Provenance(
          source: 'Lexicomp Drug Information 2024',
          reviewedBy: 'ภก. สมศักดิ์ (ภ. 12345)',
          reviewedAt: '2024-01-15',
        ),
        monograph: ClinicalMonograph(
          textbookName: 'Lexicomp Drug Information',
          editionYear: '2024',
          sectionOrTable: 'Adult Analgesia & Antipyretic',
          dosingGuideline: '500-1000 mg PO q4-6h PRN',
        ),
      );

      const result = DosageResult(
        success: true,
        formulaUsed: 'Standard Formulary',
        calculatedDose: 500.0,
        roundedDose: 500.0,
        doseUnit: DoseUnit.mg,
        frequency: 'q6h PRN',
        dailyDose: 2000.0,
        verificationStatus: VerificationStatus.verified,
      );

      // HIS Order: concise single-line
      final hisOrder = ClinicalOrderFormatter.formatHisOrder(
        patient: defaultPatient,
        drug: drug,
        regimen: regimen,
        result: result,
      );

      expect(hisOrder, equals('Paracetamol 500 mg PO q6h PRN'));
      expect(hisOrder.contains('\n'), isFalse);

      // Pharmacist Note: structured multi-line progress note
      final note = ClinicalOrderFormatter.formatPharmacistNote(
        patient: defaultPatient,
        drug: drug,
        regimen: regimen,
        result: result,
      );

      expect(note, contains('CLINICAL PHARMACIST DOSING NOTE'));
      expect(note, contains('1. PATIENT PARAMETERS'));
      expect(note, contains('TBW: 70 kg'));
      expect(note, contains('Height: 175 cm'));
      expect(note, contains('Penicillin'));
      expect(note, contains('2. MEDICATION & REGIMEN'));
      expect(note, contains('Paracetamol'));
      expect(note, contains('Oral (PO)'));
      expect(note, contains('3. DOSING CALCULATION & ADMINISTRATION'));
      expect(note, contains('Recommended Dose (Rounded): 500 mg'));
      expect(note, contains('Frequency: q6h PRN'));
      expect(note, contains('4. TEXTBOOK PROVENANCE & VERIFICATION'));
      expect(note, contains('Lexicomp Drug Information'));
      expect(note, contains('Verification Status: VERIFIED'));
      expect(note, contains('5. CLINICAL SAFETY ALERTS & WARNINGS'));
      expect(note, contains('No active safety alerts'));
    });

    // ------------------------------------------------------------
    // (b) Renal-Adjusted Regimen with CrCl and Guideline Citation
    // ------------------------------------------------------------
    test('(b) Renal-adjusted regimen with CrCl and citation', () {
      const regimen = DosingRegimen(
        route: DoseRoute.iv,
        indication: 'Hospital-Acquired Pneumonia',
        dosingType: DosingType.renalAdjusted,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q8h,
        infusionTimeMinutes: 30.0,
        verificationStatus: VerificationStatus.verified,
        provenance: Provenance(
          source: 'Sanford Guide 2024',
          reviewedBy: 'Infectious Disease Pharmacist',
          reviewedAt: '2024-05-10',
        ),
      );

      const drug = Drug(
        id: 'meropenem',
        genericName: 'Meropenem',
        nameTh: 'เมโรพีเนม',
        brandNames: ['Meronem'],
        category: DrugCategory.antibiotic,
        requiresRenalAdjustment: true,
        sourceCitation: 'Sanford Guide 2024',
        regimens: [regimen],
        provenance: Provenance(
          source: 'Sanford Guide 2024',
          reviewedBy: 'Clinical Pharmacist Specialist',
          reviewedAt: '2024-05-10',
        ),
        monograph: ClinicalMonograph(
          textbookName: 'The Sanford Guide to Antimicrobial Therapy',
          editionYear: '2024',
          sectionOrTable: 'Table 10B (Renal Impairment)',
          dosingGuideline: 'CrCl 26-50: 1000 mg IV q12h; CrCl 10-25: 500 mg IV q12h',
        ),
      );

      const result = DosageResult(
        success: true,
        formulaUsed: 'Cockcroft-Gault Renal Tier',
        calculatedDose: 1000.0,
        roundedDose: 1000.0,
        doseUnit: DoseUnit.mg,
        frequency: 'q8h',
        adjustedFrequency: 'q12h',
        crclMlMin: 25.0,
        isRenallyAdjusted: true,
        renalAdjustmentFactor: 0.67,
        renalNotes: 'Dose interval extended from q8h to q12h for CrCl 25 mL/min.',
        verificationStatus: VerificationStatus.verified,
      );

      final hisOrder = ClinicalOrderFormatter.formatHisOrder(
        patient: defaultPatient,
        drug: drug,
        regimen: regimen,
        result: result,
      );

      expect(
        hisOrder,
        equals(
          'Meropenem 1000 mg IV (infuse over 30 min) q12h [Renal adjusted: CrCl 25.0 mL/min; Sanford Guide 2024]',
        ),
      );

      final note = ClinicalOrderFormatter.formatPharmacistNote(
        patient: defaultPatient,
        drug: drug,
        regimen: regimen,
        result: result,
      );

      expect(note, contains('Renal Function: SCr 1.00 mg/dL (Stable) | CrCl: 25.0 mL/min'));
      expect(note, contains('Renal Adjustment: ACTIVE'));
      expect(note, contains('Adjusted Frequency: q12h (Original: q8h)'));
      expect(note, contains('Textbook Source: Sanford Guide 2024'));
    });

    // ------------------------------------------------------------
    // (c) Continuous / Titrated IV Infusion with Pump Rate
    // ------------------------------------------------------------
    test('(c) Continuous/titrated IV infusion with pump rate', () {
      const regimen = DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Septic Shock',
        dosingType: DosingType.titrated,
        doseUnit: DoseUnit.mcg,
        frequency: Frequency.continuous,
        rateUnit: RateUnit.mcgKgMin,
        standardDilutionMgPerMl: 0.016, // 4 mg in 250 mL
        verificationStatus: VerificationStatus.verified,
      );

      const drug = Drug(
        id: 'norepinephrine',
        genericName: 'Norepinephrine',
        nameTh: 'นอร์เอพิเนฟริน',
        brandNames: ['Levophed'],
        category: DrugCategory.vasopressor,
        isHighAlert: true,
        sourceCitation: 'Surviving Sepsis Campaign 2021',
        regimens: [regimen],
        provenance: Provenance(
          source: 'Surviving Sepsis Campaign 2021 / Ramathibodi Hospital Guide',
          reviewedBy: 'Critical Care Specialist',
          reviewedAt: '2024-02-20',
        ),
      );

      const result = DosageResult(
        success: true,
        formulaUsed: 'IV Titration Rate Engine',
        doseUnit: DoseUnit.mcg,
        infusionResult: InfusionResult(
          rate: 0.1,
          rateUnit: RateUnit.mcgKgMin,
          rateMlPerHr: 26.3,
          instructionsEn: 'Titrate continuously to maintain MAP >= 65 mmHg.',
          instructionsTh: 'ปรับอัตราดริปยาอย่างต่อเนื่องเพื่อคงความดัน MAP >= 65 mmHg',
        ),
        verificationStatus: VerificationStatus.verified,
      );

      final hisOrder = ClinicalOrderFormatter.formatHisOrder(
        patient: defaultPatient,
        drug: drug,
        regimen: regimen,
        result: result,
      );

      expect(
        hisOrder,
        equals('Norepinephrine 0.1 mcg/kg/min IV infusion (Pump rate: 26.3 mL/hr)'),
      );

      final note = ClinicalOrderFormatter.formatPharmacistNote(
        patient: defaultPatient,
        drug: drug,
        regimen: regimen,
        result: result,
      );

      expect(note, contains('Infusion Rate: 0.1 mcg/kg/min'));
      expect(note, contains('Pump Rate: 26.3 mL/hr'));
      expect(note, contains('Dilution: 0.016 mg/mL'));
      expect(note, contains('Administration Instructions: Titrate continuously to maintain MAP >= 65 mmHg.'));
    });

    // ------------------------------------------------------------
    // (d) Overdose-Flagged Calculation with Safety Tag
    // ------------------------------------------------------------
    test('(d) Overdose-flagged calculation appends safety warning tag', () {
      const regimen = DosingRegimen(
        route: DoseRoute.po,
        indication: 'Severe Pain',
        dosingType: DosingType.fixed,
        fixedDose: 1500.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q6h,
        limits: DoseLimit(maxSingleDose: 1000.0),
        verificationStatus: VerificationStatus.verified,
      );

      const drug = Drug(
        id: 'paracetamol',
        genericName: 'Paracetamol',
        nameTh: 'พาราเซตามอล',
        brandNames: ['Tylenol'],
        category: DrugCategory.analgesic,
        availableStrengths: [500.0],
        regimens: [regimen],
      );

      const result = DosageResult(
        success: true,
        formulaUsed: 'Standard Formulary',
        calculatedDose: 1500.0,
        roundedDose: 1500.0,
        doseUnit: DoseUnit.mg,
        frequency: 'q6h',
        verificationStatus: VerificationStatus.verified,
        warnings: [
          DoseWarning(
            severity: LimitSeverity.hard,
            code: DoseWarningCode.maxSingleDoseExceeded,
            messageEn: 'Single dose of 1500 mg exceeds maximum recommended 1000 mg.',
            messageTh: 'ขนาดยา 1500 มก. ต่อครั้ง เกินขนาดยาสูงสุดที่แนะนำ (1000 มก.)',
            calculatedValue: 1500.0,
            limitValue: 1000.0,
          ),
        ],
      );

      final hisOrder = ClinicalOrderFormatter.formatHisOrder(
        patient: defaultPatient,
        drug: drug,
        regimen: regimen,
        result: result,
      );

      expect(
        hisOrder,
        equals(
          'Paracetamol 1500 mg PO q6h [⚠️ OVERDOSE WARNING: Dose exceeds recommended limits]',
        ),
      );

      final note = ClinicalOrderFormatter.formatPharmacistNote(
        patient: defaultPatient,
        drug: drug,
        regimen: regimen,
        result: result,
      );

      expect(
        note,
        contains(
          '⚠️ OVERDOSE WARNING: Single dose of 1500 mg exceeds maximum recommended 1000 mg. [Calculated: 1500 vs Limit: 1000]',
        ),
      );
    });

    // ------------------------------------------------------------
    // (e) Unverified Regimen with Safety Tag
    // ------------------------------------------------------------
    test('(e) Unverified regimen calculation appends unverified tag', () {
      const regimen = DosingRegimen(
        route: DoseRoute.po,
        dosingType: DosingType.fixed,
        fixedDose: 250.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q12h,
        verificationStatus: VerificationStatus.unverified,
      );

      const drug = Drug(
        id: 'experimental_agent',
        genericName: 'Experimental Agent',
        category: DrugCategory.other,
        regimens: [regimen],
      );

      const result = DosageResult(
        success: true,
        formulaUsed: 'Unreviewed Clinical Trial Protocol',
        calculatedDose: 250.0,
        doseUnit: DoseUnit.mg,
        frequency: 'q12h',
        verificationStatus: VerificationStatus.unverified,
      );

      final hisOrder = ClinicalOrderFormatter.formatHisOrder(
        patient: defaultPatient,
        drug: drug,
        regimen: regimen,
        result: result,
      );

      expect(
        hisOrder,
        equals('Experimental Agent 250 mg PO q12h [⚠️ UNVERIFIED REGIMEN]'),
      );

      final note = ClinicalOrderFormatter.formatPharmacistNote(
        patient: defaultPatient,
        drug: drug,
        regimen: regimen,
        result: result,
      );

      expect(note, contains('Verification Status: UNVERIFIED'));
    });

    // ------------------------------------------------------------
    // Combined Renal + Overdose + Unverified edge case
    // ------------------------------------------------------------
    test('Combined Renal + Overdose + Unverified triggers all safety tags', () {
      const regimen = DosingRegimen(
        route: DoseRoute.iv,
        dosingType: DosingType.renalAdjusted,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q24h,
        verificationStatus: VerificationStatus.unverified,
      );

      const drug = Drug(
        id: 'vancomycin',
        genericName: 'Vancomycin',
        category: DrugCategory.antibiotic,
        sourceCitation: 'Sanford Guide 2024',
        regimens: [regimen],
      );

      const result = DosageResult(
        success: true,
        formulaUsed: 'Empiric High-Dose',
        calculatedDose: 2500.0,
        roundedDose: 2500.0,
        doseUnit: DoseUnit.mg,
        frequency: 'q24h',
        crclMlMin: 30.0,
        isRenallyAdjusted: true,
        verificationStatus: VerificationStatus.unverified,
        warnings: [
          DoseWarning(
            severity: LimitSeverity.hard,
            code: DoseWarningCode.maxSingleDoseExceeded,
            messageEn: 'Single dose of 2500 mg exceeds 2000 mg limit.',
            messageTh: 'ขนาดยา 2500 มก. เกินเกณฑ์สูงสุด 2000 มก.',
            calculatedValue: 2500.0,
            limitValue: 2000.0,
          ),
        ],
      );

      final hisOrder = ClinicalOrderFormatter.formatHisOrder(
        patient: defaultPatient,
        drug: drug,
        regimen: regimen,
        result: result,
      );

      expect(
        hisOrder,
        equals(
          'Vancomycin 2500 mg IV q24h [Renal adjusted: CrCl 30.0 mL/min; Sanford Guide 2024] [⚠️ OVERDOSE WARNING: Dose exceeds recommended limits] [⚠️ UNVERIFIED REGIMEN]',
        ),
      );
    });

    // ------------------------------------------------------------
    // Bilingual Thai Output Verification
    // ------------------------------------------------------------
    test('Thai bilingual formatting translates headers and labels appropriately', () {
      const regimen = DosingRegimen(
        route: DoseRoute.po,
        dosingType: DosingType.fixed,
        fixedDose: 500.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q6h,
        verificationStatus: VerificationStatus.verified,
      );

      const drug = Drug(
        id: 'paracetamol',
        genericName: 'Paracetamol',
        nameTh: 'พาราเซตามอล',
        category: DrugCategory.analgesic,
        regimens: [regimen],
      );

      const result = DosageResult(
        success: true,
        formulaUsed: 'Standard Formulary',
        calculatedDose: 500.0,
        doseUnit: DoseUnit.mg,
        frequency: 'q6h',
        verificationStatus: VerificationStatus.verified,
      );

      final thaiNote = ClinicalOrderFormatter.formatPharmacistNote(
        patient: defaultPatient,
        drug: drug,
        regimen: regimen,
        result: result,
        isThai: true,
      );

      expect(thaiNote, contains('1. ข้อมูลผู้ป่วย (Patient Parameters)'));
      expect(thaiNote, contains('2. ยาและข้อบ่งใช้ (Medication & Regimen)'));
      expect(thaiNote, contains('3. การคำนวณและบริหารยา (Dosing Calculation & Administration)'));
      expect(thaiNote, contains('4. แหล่งอ้างอิงและการรับรอง (Textbook Provenance & Verification)'));
      expect(thaiNote, contains('5. ความปลอดภัยและข้อเตือน (Clinical Safety Alerts & Warnings)'));
      expect(thaiNote, contains('ไม่มีการแจ้งเตือนความปลอดภัย (No active safety alerts)'));
      expect(thaiNote, contains('พาราเซตามอล'));
    });
  });
}
