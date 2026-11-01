import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';

void main() {
  group('PharmacistCalculator RRT Clinical Dosing Engine Tests', () {
    test('1. Meropenem in CRRT delivers continuous sepsis clearance dose (1000 mg q8-12h)', () {
      final mero = DrugDatabase.findById('meropenem')!;
      const patient = Patient(
        id: 'PT-CRRT-MERO',
        weightKg: 70,
        heightCm: 170,
        ageYears: 50,
        sex: Sex.male,
        serumCreatinineMgDl: 3.5,
        isScrStable: true,
        renalReplacementMode: RenalReplacementMode.crrt,
      );

      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: mero,
        regimen: mero.regimens.first,
      );

      expect(result.renalReplacementMode, equals(RenalReplacementMode.crrt));
      expect(result.calculatedDose, equals(1000.0));
      expect(result.frequency, contains('q12h'));
      expect(result.requiresPostHdSupplement, isFalse);
      expect(result.rrtInstructionEn, contains('CRRT'));
      expect(result.rrtInstructionTh, isNotNull);
    });

    test('2. Meropenem in IHD delivers 500 mg q24h with post-HD supplemental timing', () {
      final mero = DrugDatabase.findById('meropenem')!;
      const patient = Patient(
        id: 'PT-IHD-MERO',
        weightKg: 70,
        heightCm: 170,
        ageYears: 65,
        sex: Sex.male,
        serumCreatinineMgDl: 5.0,
        isScrStable: true,
        renalReplacementMode: RenalReplacementMode.ihd,
      );

      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: mero,
        regimen: mero.regimens.first,
      );

      expect(result.renalReplacementMode, equals(RenalReplacementMode.ihd));
      expect(result.calculatedDose, equals(500.0));
      expect(result.frequency, contains('q24h'));
      expect(result.requiresPostHdSupplement, isTrue);
      expect(result.rrtInstructionEn?.toLowerCase(), contains('post-hemodialysis'));
    });

    test('3. Vancomycin in IHD enforces post-HD administration and TDM monitoring', () {
      final vanco = DrugDatabase.findById('vancomycin')!;
      const patient = Patient(
        id: 'PT-IHD-VANCO',
        weightKg: 68,
        heightCm: 165,
        ageYears: 58,
        sex: Sex.female,
        serumCreatinineMgDl: 4.8,
        isScrStable: true,
        renalReplacementMode: RenalReplacementMode.ihd,
      );

      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: vanco,
        regimen: vanco.regimens.first,
      );

      expect(result.renalReplacementMode, equals(RenalReplacementMode.ihd));
      expect(result.requiresPostHdSupplement, isTrue);
      expect(result.rrtInstructionEn?.toLowerCase(), contains('post-hemodialysis'));
      expect(result.rrtInstructionEn, contains('trough'));
    });

    test('4. Piperacillin/Tazobactam in CRRT provides high-clearance sepsis dose (3.375g q6h / 4.5g q8h)', () {
      final piptazo = DrugDatabase.findById('piperacillin_tazobactam')!;
      const patient = Patient(
        id: 'PT-CRRT-PIPTAZO',
        weightKg: 75,
        heightCm: 172,
        ageYears: 60,
        sex: Sex.male,
        serumCreatinineMgDl: 4.2,
        isScrStable: true,
        renalReplacementMode: RenalReplacementMode.crrt,
      );

      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: piptazo,
        regimen: piptazo.regimens.first,
      );

      expect(result.renalReplacementMode, equals(RenalReplacementMode.crrt));
      expect(result.calculatedDose, equals(3.375)); // 3.375 g
      expect(result.doseUnit, equals(DoseUnit.g));
      expect(result.requiresPostHdSupplement, isFalse);
    });

    test('5. Enoxaparin in IHD sets requiresPostHdSupplement = false (not cleared by hemodialysis)', () {
      final enox = DrugDatabase.findById('enoxaparin')!;
      const patient = Patient(
        id: 'PT-IHD-ENOX',
        weightKg: 70,
        heightCm: 168,
        ageYears: 72,
        sex: Sex.female,
        serumCreatinineMgDl: 6.0,
        isScrStable: true,
        renalReplacementMode: RenalReplacementMode.ihd,
      );

      // Therapeutic regimen
      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: enox,
        regimen: enox.regimens.first,
      );

      expect(result.renalReplacementMode, equals(RenalReplacementMode.ihd));
      expect(result.requiresPostHdSupplement, isFalse);
      expect(result.rrtInstructionEn?.toLowerCase(), contains('not removed by hemodialysis'));
    });

    test('6. Unmapped CRRT drug falls back to CrCl = 25 mL/min continuous clearance and emits advisory', () {
      const testDrug = Drug(
        id: 'unmapped_rrt_antibiotic',
        genericName: 'Test Renal Antibiotic',
        brandNames: ['TestDrug'],
        category: DrugCategory.antibiotic,
        requiresRenalAdjustment: true,
        regimens: [
          DosingRegimen(
            route: DoseRoute.iv,
            indication: 'Severe Infection',
            dosingType: DosingType.fixed,
            fixedDose: 1000.0,
            doseUnit: DoseUnit.mg,
            frequency: Frequency.q8h,
            renalAdjustments: [
              RenalAdjustment(crclMin: 10, crclMax: 50, action: RenalAction.adjust, adjustmentFactor: 0.5, adjustedFrequency: Frequency.q12h),
              RenalAdjustment(crclMin: 0, crclMax: 10, action: RenalAction.adjust, adjustmentFactor: 0.25, adjustedFrequency: Frequency.q24h),
            ],
          ),
        ],
      );

      const patientCrrt = Patient(
        id: 'PT-UNMAPPED-CRRT',
        weightKg: 70,
        heightCm: 170,
        ageYears: 50,
        sex: Sex.male,
        serumCreatinineMgDl: 5.0,
        isScrStable: true,
        renalReplacementMode: RenalReplacementMode.crrt,
      );

      final result = PharmacistCalculator.calculateDose(
        patient: patientCrrt,
        drug: testDrug,
        regimen: testDrug.regimens.first,
      );

      // Effective CrCl for CRRT should be 25.0 mL/min (falling into 10-50 tier: 0.5x = 500 mg q12h)
      // NOT 0-10 anuric tier (which would severely underdose sepsis patient to 250 mg q24h)
      expect(result.crclMlMin, equals(25.0));
      expect(result.calculatedDose, equals(500.0));
      expect(result.frequency, contains('q12h'));
      expect(result.renalReplacementMode, equals(RenalReplacementMode.crrt));
      expect(
        result.warnings.any((w) => w.code == DoseWarningCode.rrtFallbackAdvisory),
        isTrue,
      );
    });

    test('7. Unmapped IHD drug falls back to CrCl = 5 mL/min (anuric) with post-HD supplement advisory', () {
      const testDrug = Drug(
        id: 'unmapped_rrt_antibiotic',
        genericName: 'Test Renal Antibiotic',
        brandNames: ['TestDrug'],
        category: DrugCategory.antibiotic,
        requiresRenalAdjustment: true,
        regimens: [
          DosingRegimen(
            route: DoseRoute.iv,
            indication: 'Severe Infection',
            dosingType: DosingType.fixed,
            fixedDose: 1000.0,
            doseUnit: DoseUnit.mg,
            frequency: Frequency.q8h,
            renalAdjustments: [
              RenalAdjustment(crclMin: 10, crclMax: 50, action: RenalAction.adjust, adjustmentFactor: 0.5, adjustedFrequency: Frequency.q12h),
              RenalAdjustment(crclMin: 0, crclMax: 10, action: RenalAction.adjust, adjustmentFactor: 0.25, adjustedFrequency: Frequency.q24h),
            ],
          ),
        ],
      );

      const patientIhd = Patient(
        id: 'PT-UNMAPPED-IHD',
        weightKg: 70,
        heightCm: 170,
        ageYears: 50,
        sex: Sex.male,
        serumCreatinineMgDl: 5.0,
        isScrStable: true,
        renalReplacementMode: RenalReplacementMode.ihd,
      );

      final result = PharmacistCalculator.calculateDose(
        patient: patientIhd,
        drug: testDrug,
        regimen: testDrug.regimens.first,
      );

      // Effective CrCl for IHD fallback is 5.0 mL/min (0-10 tier: 0.25x = 250 mg q24h)
      expect(result.crclMlMin, equals(5.0));
      expect(result.calculatedDose, equals(250.0));
      expect(result.frequency, contains('q24h'));
      expect(result.requiresPostHdSupplement, isTrue);
      expect(result.renalReplacementMode, equals(RenalReplacementMode.ihd));
      expect(
        result.warnings.any((w) => w.code == DoseWarningCode.rrtFallbackAdvisory),
        isTrue,
      );
    });

    test('8. Non-blocking Overdose Policy preserved under RRT mode', () {
      final mero = DrugDatabase.findById('meropenem')!;
      const patient = Patient(
        id: 'PT-OVERDOSE-RRT',
        weightKg: 70,
        heightCm: 170,
        ageYears: 50,
        sex: Sex.male,
        serumCreatinineMgDl: 4.0,
        isScrStable: true,
        renalReplacementMode: RenalReplacementMode.crrt,
      );

      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: mero,
        regimen: mero.regimens.first,
      );

      // Calculated dose is never stripped or hidden
      expect(result.calculatedDose, isNotNull);
      expect(result.calculatedDose! > 0, isTrue);
    });
  });
}
