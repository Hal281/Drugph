import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/models/models.dart';
import 'package:drug_dosage_calculator/core/calculators/calculators.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';

void main() {
  group('Addendum E: Test Quality, Missing Coverage & Strict Typing', () {
    // =========================================================================
    // E2: Apixaban AFib 2-of-3 Criteria Matrix
    // =========================================================================
    group('E2: Apixaban AFib Matrix', () {
      final apixaban = DrugDatabase.findById('apixaban')!;
      final afibRegimen = apixaban.regimens.firstWhere(
        (r) => (r.indication ?? '').contains('AFib'),
      );

      test('0 criteria met: 70y, 75kg, SCr 1.0 -> 5 mg BID', () {
        const p = Patient(
          id: 'p-afib-0',
          ageYears: 70,
          weightKg: 75.0,
          heightCm: 170.0,
          sex: Sex.male,
          serumCreatinineMgDl: 1.0,
          isScrStable: true,
        );
        final res = PharmacistCalculator.calculateDose(
          patient: p,
          drug: apixaban,
          regimen: afibRegimen,
        );
        expect(res.calculatedDose, equals(5.0));
        expect(res.frequency, equals('q12h'));
        expect(res.warnings.any((w) => w.code == DoseWarningCode.renalAdjustmentApplied), isFalse);
      });

      test('1 criterion met (Age only: 85y, 70kg, SCr 1.0) -> 5 mg BID', () {
        const p = Patient(
          id: 'p-afib-1-age',
          ageYears: 85,
          weightKg: 70.0,
          heightCm: 170.0,
          sex: Sex.male,
          serumCreatinineMgDl: 1.0,
          isScrStable: true,
        );
        final res = PharmacistCalculator.calculateDose(
          patient: p,
          drug: apixaban,
          regimen: afibRegimen,
        );
        expect(res.calculatedDose, equals(5.0));
      });

      test('1 criterion met (Weight only: 70y, 55kg, SCr 1.0) -> 5 mg BID', () {
        const p = Patient(
          id: 'p-afib-1-wt',
          ageYears: 70,
          weightKg: 55.0,
          heightCm: 160.0,
          sex: Sex.female,
          serumCreatinineMgDl: 1.0,
          isScrStable: true,
        );
        final res = PharmacistCalculator.calculateDose(
          patient: p,
          drug: apixaban,
          regimen: afibRegimen,
        );
        expect(res.calculatedDose, equals(5.0));
      });

      test('1 criterion met (SCr only: 70y, 70kg, SCr 1.8) -> 5 mg BID', () {
        const p = Patient(
          id: 'p-afib-1-scr',
          ageYears: 70,
          weightKg: 70.0,
          heightCm: 170.0,
          sex: Sex.male,
          serumCreatinineMgDl: 1.8,
          isScrStable: true,
        );
        final res = PharmacistCalculator.calculateDose(
          patient: p,
          drug: apixaban,
          regimen: afibRegimen,
        );
        expect(res.calculatedDose, equals(5.0));
      });

      test('2 criteria met (Age + Weight: 82y, 55kg, SCr 1.0) -> 2.5 mg BID', () {
        const p = Patient(
          id: 'p-afib-2-agewt',
          ageYears: 82,
          weightKg: 55.0,
          heightCm: 160.0,
          sex: Sex.female,
          serumCreatinineMgDl: 1.0,
          isScrStable: true,
        );
        final res = PharmacistCalculator.calculateDose(
          patient: p,
          drug: apixaban,
          regimen: afibRegimen,
        );
        expect(res.calculatedDose, equals(2.5));
        expect(res.frequency, equals('q12h'));
        expect(res.warnings.any((w) => w.code == DoseWarningCode.renalAdjustmentApplied), isTrue);
      });

      test('2 criteria met (Age + SCr: 82y, 70kg, SCr 1.8) -> 2.5 mg BID', () {
        const p = Patient(
          id: 'p-afib-2-agescr',
          ageYears: 82,
          weightKg: 70.0,
          heightCm: 170.0,
          sex: Sex.male,
          serumCreatinineMgDl: 1.8,
          isScrStable: true,
        );
        final res = PharmacistCalculator.calculateDose(
          patient: p,
          drug: apixaban,
          regimen: afibRegimen,
        );
        expect(res.calculatedDose, equals(2.5));
        expect(res.warnings.any((w) => w.code == DoseWarningCode.renalAdjustmentApplied), isTrue);
      });

      test('2 criteria met (Weight + SCr: 65y, 55kg, SCr 1.8) -> 2.5 mg BID', () {
        const p = Patient(
          id: 'p-afib-2-wtscr',
          ageYears: 65,
          weightKg: 55.0,
          heightCm: 160.0,
          sex: Sex.female,
          serumCreatinineMgDl: 1.8,
          isScrStable: true,
        );
        final res = PharmacistCalculator.calculateDose(
          patient: p,
          drug: apixaban,
          regimen: afibRegimen,
        );
        expect(res.calculatedDose, equals(2.5));
        expect(res.warnings.any((w) => w.code == DoseWarningCode.renalAdjustmentApplied), isTrue);
      });

      test('3 criteria met (Age + Weight + SCr: 82y, 55kg, SCr 1.8) -> 2.5 mg BID', () {
        const p = Patient(
          id: 'p-afib-3',
          ageYears: 82,
          weightKg: 55.0,
          heightCm: 160.0,
          sex: Sex.female,
          serumCreatinineMgDl: 1.8,
          isScrStable: true,
        );
        final res = PharmacistCalculator.calculateDose(
          patient: p,
          drug: apixaban,
          regimen: afibRegimen,
        );
        expect(res.calculatedDose, equals(2.5));
        expect(res.warnings.any((w) => w.code == DoseWarningCode.renalAdjustmentApplied), isTrue);
      });

      test('Exact threshold boundary: 80y, 60.0kg, SCr 1.5 -> 2.5 mg BID', () {
        const p = Patient(
          id: 'p-afib-boundary-on',
          ageYears: 80,
          weightKg: 60.0,
          heightCm: 165.0,
          sex: Sex.male,
          serumCreatinineMgDl: 1.5,
          isScrStable: true,
        );
        final res = PharmacistCalculator.calculateDose(
          patient: p,
          drug: apixaban,
          regimen: afibRegimen,
        );
        expect(res.calculatedDose, equals(2.5));
      });

      test('Just below threshold boundary: 79y, 60.1kg, SCr 1.49 -> 5.0 mg BID', () {
        const p = Patient(
          id: 'p-afib-boundary-off',
          ageYears: 79,
          weightKg: 60.1,
          heightCm: 165.0,
          sex: Sex.male,
          serumCreatinineMgDl: 1.49,
          isScrStable: true,
        );
        final res = PharmacistCalculator.calculateDose(
          patient: p,
          drug: apixaban,
          regimen: afibRegimen,
        );
        expect(res.calculatedDose, equals(5.0));
      });

      test('Missing SCr: 82y, 70kg, SCr null -> 5.0 mg with scrMissing warning', () {
        const p = Patient(
          id: 'p-afib-missing-scr',
          ageYears: 82,
          weightKg: 70.0,
          heightCm: 170.0,
          sex: Sex.male,
          serumCreatinineMgDl: null,
          isScrStable: true,
        );
        final res = PharmacistCalculator.calculateDose(
          patient: p,
          drug: apixaban,
          regimen: afibRegimen,
        );
        expect(res.calculatedDose, equals(5.0));
        expect(res.warnings.any((w) => w.code == DoseWarningCode.scrMissing), isTrue);
      });
    });

    // =========================================================================
    // E3: Missing Coverage Tests
    // =========================================================================
    group('E3: Missing Engine & Safety Coverage', () {
      test('4.2: Unknown/irregular frequency yields daily limit check warning', () {
        const p = Patient(
          id: 'p-custom-freq',
          ageYears: 45,
          weightKg: 70.0,
          heightCm: 170.0,
          sex: Sex.male,
          serumCreatinineMgDl: 1.0,
          isScrStable: true,
        );
        const testDrug = Drug(
          id: 'test_drug',
          genericName: 'Test Drug',
          category: DrugCategory.analgesic,
          regimens: [
            DosingRegimen(
              route: DoseRoute.po,
              indication: 'Test Indication',
              dosingType: DosingType.fixed,
              fixedDose: 100.0,
              doseUnit: DoseUnit.mg,
              frequency: Frequency(
                kind: FrequencyKind.custom,
                displayEn: 'As directed by physician',
                displayTh: 'ตามแพทย์สั่ง',
                customReason: 'Special titration protocol',
              ),
              limits: DoseLimit(maxDailyDose: 200.0),
            ),
          ],
        );

        final res = PharmacistCalculator.calculateDose(
          patient: p,
          drug: testDrug,
          regimen: testDrug.regimens.first,
        );
        expect(res.dailyDose, isNull);
        expect(
          res.warnings.any((w) =>
              w.code == DoseWarningCode.unknownFrequency &&
              w.messageEn.contains('Daily dose limits not checked')),
          isTrue,
        );
      });

      test('4.3: DoseChecker flags violation when formulary rounding exceeds max single dose', () {
        const p = Patient(
          id: 'p-round-check',
          ageYears: 45,
          weightKg: 70.0,
          heightCm: 170.0,
          sex: Sex.male,
          serumCreatinineMgDl: 1.0,
          isScrStable: true,
        );
        // Calculated dose = 480 mg (within maxSingleDose 490 mg),
        // but formulary rounding to nearest 100 mg results in 500 mg (> 490 mg).
        const roundingDrug = Drug(
          id: 'round_drug',
          genericName: 'Rounding Drug',
          category: DrugCategory.antibiotic,
          availableStrengths: [100.0, 500.0],
          regimens: [
            DosingRegimen(
              route: DoseRoute.po,
              indication: 'Infection',
              dosingType: DosingType.fixed,
              fixedDose: 480.0,
              doseUnit: DoseUnit.mg,
              frequency: Frequency.q12h,
              limits: DoseLimit(maxSingleDose: 490.0),
            ),
          ],
        );

        final res = PharmacistCalculator.calculateDose(
          patient: p,
          drug: roundingDrug,
          regimen: roundingDrug.regimens.first,
        );
        expect(res.calculatedDose, equals(480.0));
        expect(res.roundedDose, equals(500.0));
        expect(res.hasHardLimitViolation, isTrue);
        expect(res.isBlocked, isTrue);
      });

      test('A5: Manual CrCl warning emitted and used for renal adjustment when SCr is absent', () {
        const p = Patient(
          id: 'p-manual-crcl',
          ageYears: 65,
          weightKg: 70.0,
          heightCm: 170.0,
          sex: Sex.male,
          serumCreatinineMgDl: null,
          creatinineClearanceMlMin: 40.0,
          isScrStable: true,
        );
        final cipro = DrugDatabase.findById('ciprofloxacin')!;
        final reg = cipro.regimens.firstWhere((r) => r.route == DoseRoute.po);

        final res = PharmacistCalculator.calculateDose(
          patient: p,
          drug: cipro,
          regimen: reg,
        );
        expect(
          res.warnings.any((w) =>
              w.code == DoseWarningCode.generalAlert &&
              w.messageEn.contains('manually entered')),
          isTrue,
        );
        expect(res.calculatedDose, equals(500.0)); // Adjusted for CrCl 30-50
      });

      test('A6: Per-kg/day uses adjusted body weight when dosing strategy is adjustedIfObese', () {
        const obesePatient = Patient(
          id: 'p-obese-adj',
          ageYears: 50,
          weightKg: 120.0,
          heightCm: 165.0,
          sex: Sex.male,
          serumCreatinineMgDl: 1.0,
          isScrStable: true,
        );
        // IBW = 50 + 2.3 * (65 - 60) = 61.5 kg
        // AdjBW = 61.5 + 0.4 * (120 - 61.5) = 84.9 kg
        const testAdjDrug = Drug(
          id: 'adj_drug',
          genericName: 'Adjusted Drug',
          category: DrugCategory.antibiotic,
          regimens: [
            DosingRegimen(
              route: DoseRoute.ivInfusion,
              indication: 'Severe Sepsis',
              dosingType: DosingType.weightBased,
              dosingWeightStrategy: DosingWeightStrategy.adjustedIfObese,
              dosePerKg: 5.0,
              doseUnit: DoseUnit.mg,
              frequency: Frequency.q24h,
              limits: DoseLimit(maxDosePerKgPerDay: 5.5),
            ),
          ],
        );

        final res = PharmacistCalculator.calculateDose(
          patient: obesePatient,
          drug: testAdjDrug,
          regimen: testAdjDrug.regimens.first,
        );
        expect(res.success, isTrue);
        expect(res.calculatedDose, closeTo(84.9 * 5.0, 0.5));
      });

      test('A8: Regimen contraindicated in pregnancy blocks pregnant patient', () {
        const pregnantPatient = Patient(
          id: 'p-pregnant',
          ageYears: 28,
          weightKg: 65.0,
          heightCm: 165.0,
          sex: Sex.female,
          isPregnant: true,
          serumCreatinineMgDl: 0.6,
          isScrStable: true,
        );
        const teratogenicDrug = Drug(
          id: 'teratogen',
          genericName: 'Teratogenic Drug',
          category: DrugCategory.cardiovascular,
          regimens: [
            DosingRegimen(
              route: DoseRoute.po,
              indication: 'Hypertension',
              dosingType: DosingType.fixed,
              fixedDose: 10.0,
              doseUnit: DoseUnit.mg,
              frequency: Frequency.q24h,
              population: PopulationCriteria(contraindicatedPregnancy: true),
            ),
          ],
        );

        final res = PharmacistCalculator.calculateDose(
          patient: pregnantPatient,
          drug: teratogenicDrug,
          regimen: teratogenicDrug.regimens.first,
        );
        expect(res.isBlocked, isTrue);
        expect(res.warnings.any((w) => w.code == DoseWarningCode.contraindicationAlert), isTrue);
      });

      test('A8: Exceeding maxInfusionRateMgPerMin flags hard warning', () {
        const p = Patient(
          id: 'p-infusion',
          ageYears: 45,
          weightKg: 70.0,
          heightCm: 170.0,
          sex: Sex.male,
          serumCreatinineMgDl: 1.0,
          isScrStable: true,
        );
        const fastInfusionDrug = Drug(
          id: 'fast_infusion',
          genericName: 'Fast Infusion Drug',
          category: DrugCategory.antibiotic,
          regimens: [
            DosingRegimen(
              route: DoseRoute.ivInfusion,
              indication: 'Infusion Test',
              dosingType: DosingType.fixed,
              fixedDose: 1000.0,
              doseUnit: DoseUnit.mg,
              frequency: Frequency.q12h,
              infusionTimeMinutes: 30.0, // 1000 mg / 30 min = 33.3 mg/min > 10 mg/min
              maxInfusionRateMgPerMin: 10.0,
            ),
          ],
        );

        final res = PharmacistCalculator.calculateDose(
          patient: p,
          drug: fastInfusionDrug,
          regimen: fastInfusionDrug.regimens.first,
        );
        expect(res.warnings.any((w) => w.code == DoseWarningCode.maxInfusionRateExceeded), isTrue);
        expect(res.hasHardLimitViolation, isTrue);
      });

      test('A12: Engine calls InputValidator and rejects invalid patient inputs', () {
        const invalidPatient = Patient(
          id: 'p-invalid',
          ageYears: -5,
          weightKg: 0.0,
          heightCm: 170.0,
          sex: Sex.male,
          serumCreatinineMgDl: 1.0,
          isScrStable: true,
        );
        final amox = DrugDatabase.findById('amoxicillin_clavulanate')!;

        final res = PharmacistCalculator.calculateDose(
          patient: invalidPatient,
          drug: amox,
          regimen: amox.regimens.first,
        );
        expect(res.success, isFalse);
        expect(res.isBlocked, isTrue);
        expect(res.errorMessage, isNotNull);
      });

      test('D3: Vancomycin contains loading and maintenance phases', () {
        final vanco = DrugDatabase.findById('vancomycin')!;
        final reg = vanco.regimens.first;
        expect(reg.phases, isNotNull);
        expect(reg.phases!.length, equals(2));

        final loading = reg.phases![0];
        expect(loading.type, equals(PhaseType.loading));
        expect(loading.role, equals(DoseRole.start));
        expect(loading.dosePerKg, equals(25.0));

        final maint = reg.phases![1];
        expect(maint.type, equals(PhaseType.maintenance));
        expect(maint.role, equals(DoseRole.usual));
        expect(maint.dosePerKg, equals(15.0));
      });

      test('D3: NAC paracetamol antidote 3-bag protocol caps weight at 100 kg', () {
        final nac = DrugDatabase.findById('n_acetylcysteine')!;
        final antidoteReg = nac.regimens.firstWhere(
          (r) => (r.indication ?? '').contains('Paracetamol'),
        );
        expect(antidoteReg.maxDosingWeightKg, equals(100.0));
        expect(antidoteReg.phases!.length, equals(3));

        // 120 kg patient
        const heavyPatient = Patient(
          id: 'p-heavy',
          ageYears: 35,
          weightKg: 120.0,
          heightCm: 175.0,
          sex: Sex.male,
          serumCreatinineMgDl: 0.9,
          isScrStable: true,
        );
        final res = PharmacistCalculator.calculateDose(
          patient: heavyPatient,
          drug: nac,
          regimen: antidoteReg,
        );
        // Capped at 100 kg * 150 mg/kg = 15,000 mg
        expect(res.calculatedDose, equals(15000.0));
      });

      test('D4: Oxytocin with female population criteria is blocked for a male patient', () {
        const malePatient = Patient(
          id: 'p-male',
          ageYears: 30,
          weightKg: 70.0,
          heightCm: 175.0,
          sex: Sex.male,
          serumCreatinineMgDl: 1.0,
          isScrStable: true,
        );
        final oxytocin = DrugDatabase.findById('oxytocin')!;
        final reg = oxytocin.regimens.first;

        final res = PharmacistCalculator.calculateDose(
          patient: malePatient,
          drug: oxytocin,
          regimen: reg,
        );
        expect(res.isBlocked, isTrue);
        expect(res.warnings.any((w) => w.code == DoseWarningCode.populationMismatch), isTrue);
      });

      test('RenalAction.avoid: Rivaroxaban on CrCl < 15 is blocked with tier notes', () {
        const esrdPatient = Patient(
          id: 'p-esrd',
          ageYears: 75,
          weightKg: 60.0,
          heightCm: 165.0,
          sex: Sex.female,
          serumCreatinineMgDl: 4.5, // Cockcroft-Gault CrCl < 15 mL/min
          isScrStable: true,
        );
        final rivaroxaban = DrugDatabase.findById('rivaroxaban')!;
        final reg = rivaroxaban.regimens.first;

        final res = PharmacistCalculator.calculateDose(
          patient: esrdPatient,
          drug: rivaroxaban,
          regimen: reg,
        );
        expect(res.isBlocked, isTrue);
        expect(res.warnings.any((w) => w.code == DoseWarningCode.contraindicationAlert), isTrue);
        expect(
          res.warnings.any((w) => w.messageEn.contains('CrCl < 15 mL/min')),
          isTrue,
        );
      });

      test('Database alert when requiresRenalAdjustment is true but renalAdjustments is null', () {
        const p = Patient(
          id: 'p-std',
          ageYears: 45,
          weightKg: 70.0,
          heightCm: 170.0,
          sex: Sex.male,
          serumCreatinineMgDl: 1.0,
          isScrStable: true,
        );
        const unreviewedDrug = Drug(
          id: 'unreviewed_drug',
          genericName: 'Unreviewed Drug',
          category: DrugCategory.antibiotic,
          requiresRenalAdjustment: true,
          renalReviewStatus: RenalReviewStatus.reviewedWithTiers,
          regimens: [
            DosingRegimen(
              route: DoseRoute.po,
              indication: 'Test',
              dosingType: DosingType.fixed,
              fixedDose: 500.0,
              doseUnit: DoseUnit.mg,
              frequency: Frequency.q12h,
              renalAdjustments: null, // missing tiers
            ),
          ],
        );

        final res = PharmacistCalculator.calculateDose(
          patient: p,
          drug: unreviewedDrug,
          regimen: unreviewedDrug.regimens.first,
        );
        expect(
          res.warnings.any((w) =>
              w.code == DoseWarningCode.severeRenalImpairment &&
              w.messageEn.contains('DATABASE WARNING')),
          isTrue,
        );
      });

      test('verifyOrder flags dose below minimum, frequency interval mismatch, and irregular schedule', () {
        const p = Patient(
          id: 'p-verify',
          ageYears: 45,
          weightKg: 70.0,
          heightCm: 170.0,
          sex: Sex.male,
          serumCreatinineMgDl: 1.0,
          isScrStable: true,
        );
        const testDrug = Drug(
          id: 'verify_drug',
          genericName: 'Verify Drug',
          category: DrugCategory.antibiotic,
          regimens: [
            DosingRegimen(
              route: DoseRoute.po,
              indication: 'Verify Indication',
              dosingType: DosingType.fixed,
              fixedDose: 500.0,
              doseUnit: DoseUnit.mg,
              frequency: Frequency.q12h,
              limits: DoseLimit(
                minSingleDose: 250.0,
                maxSingleDose: 1000.0,
              ),
            ),
          ],
        );
        final reg = testDrug.regimens.first;

        // 1. Below minimum dose (100 mg < 250 mg)
        final belowMin = PharmacistCalculator.verifyOrder(
          patient: p,
          drug: testDrug,
          regimen: reg,
          orderedDose: 100.0,
          orderedFrequency: Frequency.q12h,
        );
        expect(belowMin.warnings.any((w) => w.code == DoseWarningCode.minDoseNotReached), isTrue);

        // 2. Frequency interval mismatch (ordered q6h vs regimen q12h)
        final freqMismatch = PharmacistCalculator.verifyOrder(
          patient: p,
          drug: testDrug,
          regimen: reg,
          orderedDose: 500.0,
          orderedFrequency: Frequency.q6h,
        );
        expect(
          freqMismatch.warnings.any((w) =>
              w.code == DoseWarningCode.unknownFrequency &&
              w.messageEn.contains('FREQUENCY MISMATCH')),
          isTrue,
        );

        // 3. Irregular frequency (PRN without fixed interval)
        final irregularOrder = PharmacistCalculator.verifyOrder(
          patient: p,
          drug: testDrug,
          regimen: reg,
          orderedDose: 500.0,
          orderedFrequency: Frequency.prn,
        );
        expect(
          irregularOrder.warnings.any((w) =>
              w.code == DoseWarningCode.unknownFrequency &&
              w.messageEn.contains('irregular or variable')),
          isTrue,
        );
      });

      test('Structured DDI: Warfarin + Ibuprofen and Valproate + Meropenem', () {
        // Patient taking Warfarin and Meropenem
        const pWithMeds = Patient(
          id: 'p-ddi',
          ageYears: 55,
          weightKg: 70.0,
          heightCm: 170.0,
          sex: Sex.male,
          serumCreatinineMgDl: 1.0,
          isScrStable: true,
          activeDrugIds: ['warfarin', 'meropenem'],
        );

        // Check Ibuprofen
        final ibuprofen = DrugDatabase.findById('ibuprofen')!;
        final resIbu = PharmacistCalculator.calculateDose(
          patient: pWithMeds,
          drug: ibuprofen,
          regimen: ibuprofen.regimens.first,
        );
        expect(resIbu.warnings.any((w) => w.code == DoseWarningCode.severeInteractionAlert), isTrue);

        // Check Valproic acid
        final valproate = DrugDatabase.findById('valproic_acid')!;
        final resVal = PharmacistCalculator.calculateDose(
          patient: pWithMeds,
          drug: valproate,
          regimen: valproate.regimens.first,
        );
        expect(resVal.warnings.any((w) => w.code == DoseWarningCode.severeInteractionAlert), isTrue);
      });

      test('Continuous infusion mL/hr golden values for Heparin, Insulin DKA, and Norepinephrine', () {
        const p70 = Patient(
          id: 'p-70',
          ageYears: 45,
          weightKg: 70.0,
          heightCm: 170.0,
          sex: Sex.male,
          serumCreatinineMgDl: 1.0,
          isScrStable: true,
        );

        // 1. Heparin: 18 U/kg/hr for 70 kg = 1260 U/hr; 100 U/mL -> 12.6 mL/hr
        final heparin = DrugDatabase.findById('heparin')!;
        final resHep = PharmacistCalculator.calculateDose(
          patient: p70,
          drug: heparin,
          regimen: heparin.regimens.first,
        );
        expect(resHep.infusionResult?.rateMlPerHr, closeTo(12.6, 0.01));

        // 2. Insulin DKA: 0.05-0.2 U/kg/hr. Min 0.05 * 70 = 3.5 mL/hr, Max 0.2 * 70 = 14.0 mL/hr
        // At 0.1 U/kg/hr, standard dilution 1.0 U/mL -> rate = 7.0 mL/hr
        final insulin = DrugDatabase.findById('insulin_regular')!;
        final dkaReg = insulin.regimens.firstWhere(
          (r) => (r.indication ?? '').contains('Diabetic Ketoacidosis'),
        );
        final resIns = PharmacistCalculator.calculateDose(
          patient: p70,
          drug: insulin,
          regimen: dkaReg,
        );
        expect(resIns.infusionResult?.rateMlPerHr, closeTo(3.5, 0.01));
        expect(resIns.infusionResult?.rateMlPerHrMax, closeTo(14.0, 0.01));

        // 3. Norepinephrine: 0.01 mcg/kg/min * 70 kg * 60 / 1000 = 0.042 mg/hr / 0.016 mg/mL = 2.625 mL/hr
        // For 0.05 mcg/kg/min: 0.05 * 70 * 60 / 1000 = 0.21 mg/hr / 0.016 = 13.125 mL/hr
        final norepi = DrugDatabase.findById('norepinephrine')!;
        final resNorepi = PharmacistCalculator.calculateDose(
          patient: p70,
          drug: norepi,
          regimen: norepi.regimens.first,
        );
        // Min rate 0.01 -> 2.625 mL/hr
        expect(resNorepi.infusionResult?.rateMlPerHr, closeTo(2.625, 0.01));
        // Verify formula at 0.05 mcg/kg/min yields 13.125 mL/hr exactly:
        final amountAt005 = RateUnit.mcgKgMin.toAmountPerHour(0.05, 70.0)!;
        final mlAt005 = amountAt005 / norepi.regimens.first.standardDilutionMgPerMl!;
        expect(mlAt005, closeTo(13.125, 0.001));
      });
    });

    // =========================================================================
    // E4: Allergy Matching Without legacyAllergyClass
    // =========================================================================
    group('E4: Allergy Matching Without legacyAllergyClass', () {
      test('Lowercase allergen matching matches beta-lactam penicillin class', () {
        final alerts = AllergyService.evaluateAllergies(
          patientAllergies: ['penicillin'],
          drugGenericName: 'Amoxicillin',
          drugId: 'amoxicillin',
          drugClass: DrugClass.betaLactamPenicillin,
          legacyAllergyClass: null,
        );
        expect(alerts, isNotEmpty);
        expect(alerts.first.hasDirectMatch, isTrue);
        expect(alerts.first.severity, equals(LimitSeverity.hard));
      });

      test('Thai allergen input matches beta-lactam penicillin class', () {
        final alerts = AllergyService.evaluateAllergies(
          patientAllergies: ['เพนิซิลลิน'],
          drugGenericName: 'Ampicillin',
          drugId: 'ampicillin',
          drugClass: DrugClass.betaLactamPenicillin,
          legacyAllergyClass: null,
        );
        expect(alerts, isNotEmpty);
        expect(alerts.first.hasDirectMatch, isTrue);
        expect(alerts.first.severity, equals(LimitSeverity.hard));
      });

      test('Negative control: Penicillin allergy does NOT match Ciprofloxacin', () {
        final alerts = AllergyService.evaluateAllergies(
          patientAllergies: ['penicillin'],
          drugGenericName: 'Ciprofloxacin',
          drugId: 'ciprofloxacin',
          drugClass: DrugClass.fluoroquinolone,
          legacyAllergyClass: null,
        );
        expect(alerts, isEmpty);
      });

      test('Cefazolin soft cross-reactivity alert on penicillin allergy', () {
        final alerts = AllergyService.evaluateAllergies(
          patientAllergies: ['penicillin'],
          drugGenericName: 'Cefazolin',
          drugId: 'cefazolin',
          drugClass: DrugClass.betaLactamCephalosporin,
          legacyAllergyClass: null,
        );
        expect(alerts, isNotEmpty);
        expect(alerts.first.hasCrossReactivity, isTrue);
        expect(alerts.first.severity, equals(LimitSeverity.soft));
      });

      test('Short substring safety: "sul" does not match "Insulin"', () {
        final alerts = AllergyService.evaluateAllergies(
          patientAllergies: ['sul'],
          drugGenericName: 'Insulin Regular (RI)',
          drugId: 'insulin_regular',
          drugClass: null,
          legacyAllergyClass: 'Insulin',
        );
        expect(alerts, isEmpty, reason: 'Short string "sul" must not trigger match against Insulin');
      });
    });

    // =========================================================================
    // Widget Test: Blocked dose UI rendering
    // =========================================================================
    testWidgets('Widget Test: Blocked DosageResult renders NO dose values without override', (tester) async {
      const blockedResult = DosageResult(
        success: true,
        calculatedDose: 1500.0,
        roundedDose: 1500.0,
        doseUnit: DoseUnit.mg,
        frequency: 'q12h',
        formulaUsed: 'Weight-based (Devine IBW)',
        warnings: [
          DoseWarning(
            severity: LimitSeverity.hard,
            code: DoseWarningCode.maxSingleDoseExceeded,
            messageEn: 'Single dose exceeds hard limit',
            messageTh: 'ขนาดยาเกินเกณฑ์สูงสุด',
          ),
        ],
      );
      expect(blockedResult.isBlocked, isTrue);

      // Simple UI widget rendering the result following the isBlocked rule
      Widget buildTestWidget({bool isOverrideAccepted = false}) {
        return MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final isBlockedWithoutOverride = blockedResult.isBlocked && !isOverrideAccepted;
                if (isBlockedWithoutOverride) {
                  return const Text('DOSE BLOCKED DUE TO HARD SAFETY LIMIT');
                }
                return Text('Dose: ${blockedResult.calculatedDose} mg');
              },
            ),
          ),
        );
      }

      // Without override -> Dose is NOT rendered
      await tester.pumpWidget(buildTestWidget(isOverrideAccepted: false));
      expect(find.text('DOSE BLOCKED DUE TO HARD SAFETY LIMIT'), findsOneWidget);
      expect(find.textContaining('1500.0'), findsNothing);

      // With override -> Dose is rendered
      await tester.pumpWidget(buildTestWidget(isOverrideAccepted: true));
      expect(find.textContaining('1500.0 mg'), findsOneWidget);
    });
  });
}
