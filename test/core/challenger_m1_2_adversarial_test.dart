import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';

void main() {
  group('Challenger M1-2 Adversarial Stress & Overdose Preservation Tests', () {
    const extremeWeightKg = 250.0;
    const extremeLowWeightKg = 35.0;

    // Synthetic drug designed specifically to stress test boundaries and overdose under RRT
    const testOverdoseAntibiotic = Drug(
      id: 'test_overdose_antibiotic',
      genericName: 'Adversarial Cillin',
      brandNames: ['AdvCillin'],
      category: DrugCategory.antibiotic,
      requiresRenalAdjustment: true,
      availableStrengths: [250.0, 500.0, 1000.0],
      vialPartialAllowed: true,
      regimens: [
        DosingRegimen(
          route: DoseRoute.iv,
          indication: 'Severe Sepsis',
          dosingType: DosingType.weightBased,
          dosePerKg: 15.0, // 15 mg/kg -> at 250kg = 3750 mg
          doseUnit: DoseUnit.mg,
          frequency: Frequency.q8h,
          limits: DoseLimit(
            minSingleDose: 250.0,
            maxSingleDose: 1500.0, // 3750 mg easily violates this hard limit!
            softMaxSingleDose: 1000.0,
            maxDailyDose: 4500.0,
          ),
          renalReplacementProtocols: [
            RenalReplacementProtocol(
              mode: RenalReplacementMode.crrt,
              doseFactor: 1.0, // maintains weight-based dose
              frequency: Frequency.q12h,
              requiresPostHdSupplement: false,
              clinicalInstructionEn: 'CRRT continuous sepsis dosing protocol',
              clinicalInstructionTh: 'เกณฑ์ขนาดยา CRRT สำหรับภาวะติดเชื้อรุนแรง',
            ),
            RenalReplacementProtocol(
              mode: RenalReplacementMode.ihd,
              doseFactor: 0.5, // 3750 * 0.5 = 1875 mg -> still exceeds maxSingleDose 1500 mg!
              frequency: Frequency.q24h,
              requiresPostHdSupplement: true,
              clinicalInstructionEn: 'Administer post-hemodialysis',
              clinicalInstructionTh: 'บริหารยาหลังฟอกเลือดเสร็จ',
            ),
            RenalReplacementProtocol(
              mode: RenalReplacementMode.capd,
              doseFactor: 0.5, // 1875 mg -> still exceeds maxSingleDose 1500 mg!
              frequency: Frequency.q24h,
              requiresPostHdSupplement: false,
              clinicalInstructionEn: 'CAPD maintenance dosing',
              clinicalInstructionTh: 'ขนาดยาบำรุงในผู้ป่วย CAPD',
            ),
          ],
        ),
      ],
    );

    // -------------------------------------------------------------
    // 1. Extreme Weight (250 kg) & Overdose Preservation under CRRT
    // -------------------------------------------------------------
    test('1. Extreme weight (250 kg) on CRRT calculates massive dose, fires overdose warning, but NEVER hides calculatedDose / roundedDose (Rule 5)', () {
      const patient = Patient(
        id: 'PT-250KG-CRRT',
        weightKg: extremeWeightKg,
        heightCm: 180,
        ageYears: 45,
        sex: Sex.male,
        serumCreatinineMgDl: 4.5,
        isScrStable: true,
        renalReplacementMode: RenalReplacementMode.crrt,
      );

      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: testOverdoseAntibiotic,
        regimen: testOverdoseAntibiotic.regimens.first,
      );

      // Rule 5 Verification: Calculation succeeds, dose is NOT nulled, NOT zeroed, NOT hidden
      expect(result.success, isTrue);
      expect(result.calculatedDose, equals(3750.0)); // 250 kg * 15 mg/kg
      expect(result.roundedDose, isNotNull);
      expect(result.roundedDose, equals(3750.0)); // rounded to exact strength multiple
      expect(result.renalReplacementMode, equals(RenalReplacementMode.crrt));
      expect(result.requiresPostHdSupplement, isFalse);

      // Must have hard overdose warning
      expect(
        result.warnings.any((w) => w.code == DoseWarningCode.maxSingleDoseExceeded),
        isTrue,
        reason: 'Hard limit violation must be flagged in warnings',
      );
      expect(result.hasHardLimitViolation, isTrue);

      // HIS Order Formatter verification: dose is present, CRRT tag is present, Overdose tag is present
      final hisOrder = ClinicalOrderFormatter.formatHisOrder(
        patient: patient,
        drug: testOverdoseAntibiotic,
        regimen: testOverdoseAntibiotic.regimens.first,
        result: result,
      );
      expect(hisOrder, contains('Adversarial Cillin 3750 mg'));
      expect(hisOrder, contains('[CRRT]'));
      expect(hisOrder, contains('[⚠️ OVERDOSE WARNING: Dose exceeds recommended limits]'));

      // Pharmacist Note Formatter verification:
      final note = ClinicalOrderFormatter.formatPharmacistNote(
        patient: patient,
        drug: testOverdoseAntibiotic,
        regimen: testOverdoseAntibiotic.regimens.first,
        result: result,
      );
      expect(note, contains('Continuous Renal Replacement Therapy (CRRT)'));
      expect(note, contains('3750 mg'));
      expect(note, contains('OVERDOSE WARNING'));
    });

    // -------------------------------------------------------------
    // 2. Extreme Weight (250 kg) & Overdose Preservation under IHD
    // -------------------------------------------------------------
    test('2. Extreme weight (250 kg) on IHD calculates dose, flags Post-HD timing and Overdose warning together', () {
      const patient = Patient(
        id: 'PT-250KG-IHD',
        weightKg: extremeWeightKg,
        heightCm: 180,
        ageYears: 50,
        sex: Sex.male,
        serumCreatinineMgDl: 5.0,
        isScrStable: true,
        renalReplacementMode: RenalReplacementMode.ihd,
      );

      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: testOverdoseAntibiotic,
        regimen: testOverdoseAntibiotic.regimens.first,
      );

      expect(result.success, isTrue);
      // 250 kg * 15 mg/kg * 0.5 (IHD factor) = 1875 mg
      expect(result.calculatedDose, equals(1875.0));
      expect(result.roundedDose, equals(1875.0));
      expect(result.renalReplacementMode, equals(RenalReplacementMode.ihd));
      expect(result.requiresPostHdSupplement, isTrue);

      // 1875 mg > 1500 mg maxSingleDose -> triggers overdose
      expect(
        result.warnings.any((w) => w.code == DoseWarningCode.maxSingleDoseExceeded),
        isTrue,
      );

      // Check HIS Order
      final hisOrder = ClinicalOrderFormatter.formatHisOrder(
        patient: patient,
        drug: testOverdoseAntibiotic,
        regimen: testOverdoseAntibiotic.regimens.first,
        result: result,
      );
      expect(hisOrder, contains('Adversarial Cillin 1875 mg'));
      expect(hisOrder, contains('[IHD: Post-HD Dosing]'));
      expect(hisOrder, contains('[⚠️ OVERDOSE WARNING: Dose exceeds recommended limits]'));
    });

    // -------------------------------------------------------------
    // 3. Extreme Weight (250 kg) & Overdose under CAPD
    // -------------------------------------------------------------
    test('3. Extreme weight (250 kg) on CAPD calculates dose, flags CAPD mode and Overdose warning together', () {
      const patient = Patient(
        id: 'PT-250KG-CAPD',
        weightKg: extremeWeightKg,
        heightCm: 180,
        ageYears: 50,
        sex: Sex.male,
        serumCreatinineMgDl: 5.0,
        isScrStable: true,
        renalReplacementMode: RenalReplacementMode.capd,
      );

      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: testOverdoseAntibiotic,
        regimen: testOverdoseAntibiotic.regimens.first,
      );

      expect(result.success, isTrue);
      expect(result.calculatedDose, equals(1875.0));
      expect(result.roundedDose, equals(1875.0));
      expect(result.renalReplacementMode, equals(RenalReplacementMode.capd));

      final hisOrder = ClinicalOrderFormatter.formatHisOrder(
        patient: patient,
        drug: testOverdoseAntibiotic,
        regimen: testOverdoseAntibiotic.regimens.first,
        result: result,
      );
      expect(hisOrder, contains('Adversarial Cillin 1875 mg'));
      expect(hisOrder, contains('[CAPD]'));
      expect(hisOrder, contains('[⚠️ OVERDOSE WARNING: Dose exceeds recommended limits]'));
    });

    // -------------------------------------------------------------
    // 4. Custom Doses / Ordered Prescription Overdose under RRT
    // -------------------------------------------------------------
    test('4. Physician ordered custom dose of 5000 mg under CRRT retains ordered and recommended doses in OrderVerificationResult', () {
      final mero = DrugDatabase.findById('meropenem')!;
      const patient = Patient(
        id: 'PT-ORDER-VERIFY-RRT',
        weightKg: 70,
        heightCm: 170,
        ageYears: 55,
        sex: Sex.male,
        serumCreatinineMgDl: 4.0,
        isScrStable: true,
        renalReplacementMode: RenalReplacementMode.crrt,
      );

      final verification = PharmacistCalculator.verifyOrder(
        patient: patient,
        drug: mero,
        regimen: mero.regimens.first,
        orderedDose: 5000.0, // Massive overdose (guideline is 1000 mg in CRRT, max single is 2000 mg)
        orderedFrequency: Frequency.q8h,
      );

      // Order verification correctly rejects the dangerous order
      expect(verification.isAcceptable, isFalse);
      expect(verification.orderedDose, equals(5000.0));
      expect(verification.recommendedResult.calculatedDose, equals(1000.0));
      expect(verification.recommendedResult.renalReplacementMode, equals(RenalReplacementMode.crrt));
      expect(
        verification.warnings.any((w) => w.code == DoseWarningCode.maxSingleDoseExceeded),
        isTrue,
      );
    });

    // -------------------------------------------------------------
    // 5. Unmapped RRT Drug with Extreme Weight (250 kg)
    // -------------------------------------------------------------
    test('5. Unmapped RRT drug with 250 kg patient evaluates fallback clearance and triggers overdose without crashing', () {
      const unmappedDrug = Drug(
        id: 'unmapped_weight_antibiotic',
        genericName: 'Unmapped Weight Drug',
        category: DrugCategory.antibiotic,
        requiresRenalAdjustment: true,
        regimens: [
          DosingRegimen(
            route: DoseRoute.iv,
            indication: 'Severe Sepsis',
            dosingType: DosingType.weightBased,
            dosePerKg: 10.0, // 250 kg -> 2500 mg
            doseUnit: DoseUnit.mg,
            frequency: Frequency.q8h,
            limits: DoseLimit(
              maxSingleDose: 1000.0,
            ),
            renalAdjustments: [
              RenalAdjustment(
                crclMin: 10,
                crclMax: 50,
                action: RenalAction.adjust,
                adjustmentFactor: 0.5, // at 25 mL/min CRRT fallback: 2500 * 0.5 = 1250 mg > 1000 mg max
                adjustedFrequency: Frequency.q12h,
              ),
              RenalAdjustment(
                crclMin: 0,
                crclMax: 10,
                action: RenalAction.adjust,
                adjustmentFactor: 0.25, // at 5 mL/min IHD fallback: 2500 * 0.25 = 625 mg
                adjustedFrequency: Frequency.q24h,
              ),
            ],
          ),
        ],
      );

      const patient = Patient(
        id: 'PT-UNMAPPED-250KG-CRRT',
        weightKg: extremeWeightKg,
        heightCm: 180,
        ageYears: 50,
        sex: Sex.male,
        serumCreatinineMgDl: 6.0,
        isScrStable: true,
        renalReplacementMode: RenalReplacementMode.crrt,
      );

      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: unmappedDrug,
        regimen: unmappedDrug.regimens.first,
      );

      expect(result.success, isTrue);
      expect(result.crclMlMin, equals(25.0)); // CRRT continuous clearance fallback
      expect(result.calculatedDose, equals(1250.0)); // 2500 * 0.5
      expect(result.renalReplacementMode, equals(RenalReplacementMode.crrt));
      // Overdose warning triggered because 1250 mg > 1000 mg maxSingleDose
      expect(
        result.warnings.any((w) => w.code == DoseWarningCode.maxSingleDoseExceeded),
        isTrue,
      );
      // RRT Fallback Advisory warning also present
      expect(
        result.warnings.any((w) => w.code == DoseWarningCode.rrtFallbackAdvisory),
        isTrue,
      );
    });

    // -------------------------------------------------------------
    // 6. Extreme Low Weight (35 kg Adult) under RRT
    // -------------------------------------------------------------
    test('6. Extreme low weight (35 kg) under RRT respects minSingleDose safety checks', () {
      const patient = Patient(
        id: 'PT-35KG-IHD',
        weightKg: extremeLowWeightKg,
        heightCm: 150,
        ageYears: 70,
        sex: Sex.female,
        serumCreatinineMgDl: 4.0,
        isScrStable: true,
        renalReplacementMode: RenalReplacementMode.ihd,
      );

      // 35 kg * 15 mg/kg * 0.5 (IHD) = 262.5 mg
      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: testOverdoseAntibiotic,
        regimen: testOverdoseAntibiotic.regimens.first,
      );

      expect(result.success, isTrue);
      expect(result.calculatedDose, equals(262.5));
      expect(result.roundedDose, equals(250.0)); // rounded to nearest available step (125mg step -> 250mg)
      expect(result.requiresPostHdSupplement, isTrue);
    });

    // -------------------------------------------------------------
    // 7. Extreme Serum Creatinine (25.0 mg/dL) does not crash RRT
    // -------------------------------------------------------------
    test('7. Extreme SCr (25.0 mg/dL) does not trigger false AKI block when patient is on RRT', () {
      const patient = Patient(
        id: 'PT-EXTREME-SCR-RRT',
        weightKg: 70,
        heightCm: 170,
        ageYears: 60,
        sex: Sex.male,
        serumCreatinineMgDl: 25.0, // Extremely elevated
        isScrStable: false, // Unstable in native kidney, but patient is on dialysis!
        renalReplacementMode: RenalReplacementMode.crrt,
      );

      final mero = DrugDatabase.findById('meropenem')!;
      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: mero,
        regimen: mero.regimens.first,
      );

      expect(result.success, isTrue);
      expect(result.calculatedDose, equals(1000.0));
      expect(result.renalReplacementMode, equals(RenalReplacementMode.crrt));
      // Does not contain false AKI block
      expect(result.warnings.any((w) => w.code == DoseWarningCode.unstableScr), isFalse);
    });

    // -------------------------------------------------------------
    // 8. Backward Compatibility: Default Patient & Non-RRT Regimens
    // -------------------------------------------------------------
    test('8. Backward Compatibility: default Patient() without renalReplacementMode defaults to .none and produces identical baseline result', () {
      // Legacy Patient constructor call without renalReplacementMode
      const defaultPatient = Patient(
        id: 'PT-LEGACY-DEFAULT',
        weightKg: 70,
        heightCm: 170,
        ageYears: 35,
        sex: Sex.male,
        isScrStable: true,
      );

      expect(defaultPatient.renalReplacementMode, equals(RenalReplacementMode.none));
      expect(defaultPatient.renalReplacementMode.isRrt, isFalse);
      expect(defaultPatient.renalReplacementMode.isIhd, isFalse);
      expect(defaultPatient.renalReplacementMode.isCrrt, isFalse);
      expect(defaultPatient.renalReplacementMode.isCapd, isFalse);

      final mero = DrugDatabase.findById('meropenem')!;
      final result = PharmacistCalculator.calculateDose(
        patient: defaultPatient,
        drug: mero,
        regimen: mero.regimens.first,
      );

      expect(result.success, isTrue);
      expect(result.renalReplacementMode, equals(RenalReplacementMode.none));
      expect(result.requiresPostHdSupplement, isFalse);

      final hisOrder = ClinicalOrderFormatter.formatHisOrder(
        patient: defaultPatient,
        drug: mero,
        regimen: mero.regimens.first,
        result: result,
      );

      // Verify no RRT tags are injected into legacy standard orders
      expect(hisOrder, isNot(contains('[CRRT]')));
      expect(hisOrder, isNot(contains('[IHD]')));
      expect(hisOrder, isNot(contains('[CAPD]')));
      expect(hisOrder, isNot(contains('Post-HD')));
    });
  });
}
