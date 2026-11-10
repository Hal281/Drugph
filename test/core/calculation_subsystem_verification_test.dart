import 'package:test/test.dart';
import 'package:drug_dosage_calculator/core/calculators/calculators.dart';
import 'package:drug_dosage_calculator/core/models/models.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';

void main() {
  group('Calculation Subsystem End-to-End Verification Test Suite', () {
    const adultPatient = Patient(
      id: 'p_adult',
      weightKg: 70.0,
      heightCm: 175.0,
      ageYears: 35,
      sex: Sex.male,
      serumCreatinineMgDl: 0.9,
      isScrStable: true,
    );

    // -------------------------------------------------------------------------
    // 1. Order Verification Guard on Non-Positive / Non-Finite Ordered Doses
    // -------------------------------------------------------------------------
    group('PharmacistCalculator.verifyOrder non-positive and non-finite guards', () {
      final amox = DrugDatabase.findById('amoxicillin_clavulanate')!;
      final reg = amox.regimens.first;

      test('Ordered dose <= 0 is immediately rejected with hard limit severity', () {
        final zeroOrder = PharmacistCalculator.verifyOrder(
          patient: adultPatient,
          drug: amox,
          regimen: reg,
          orderedDose: 0.0,
          orderedFrequency: Frequency.q12h,
        );
        expect(zeroOrder.isAcceptable, isFalse);
        expect(zeroOrder.warnings, isNotEmpty);
        expect(zeroOrder.warnings.first.severity, equals(LimitSeverity.hard));
        expect(zeroOrder.summaryEn, contains('Ordered dose must be a positive number'));

        final negOrder = PharmacistCalculator.verifyOrder(
          patient: adultPatient,
          drug: amox,
          regimen: reg,
          orderedDose: -250.0,
          orderedFrequency: Frequency.q12h,
        );
        expect(negOrder.isAcceptable, isFalse);
        expect(negOrder.warnings.first.severity, equals(LimitSeverity.hard));
      });

      test('Ordered dose with NaN or Infinity is immediately rejected with hard limit severity', () {
        final nanOrder = PharmacistCalculator.verifyOrder(
          patient: adultPatient,
          drug: amox,
          regimen: reg,
          orderedDose: double.nan,
          orderedFrequency: Frequency.q12h,
        );
        expect(nanOrder.isAcceptable, isFalse);
        expect(nanOrder.warnings.first.severity, equals(LimitSeverity.hard));

        final infOrder = PharmacistCalculator.verifyOrder(
          patient: adultPatient,
          drug: amox,
          regimen: reg,
          orderedDose: double.infinity,
          orderedFrequency: Frequency.q12h,
        );
        expect(infOrder.isAcceptable, isFalse);
        expect(infOrder.warnings.first.severity, equals(LimitSeverity.hard));
      });

      test('Clinically valid prescribed dose within limits is accepted', () {
        final validOrder = PharmacistCalculator.verifyOrder(
          patient: adultPatient,
          drug: amox,
          regimen: reg,
          orderedDose: 1000.0,
          orderedFrequency: Frequency.q12h,
        );
        expect(validOrder.isAcceptable, isTrue);
      });
    });

    // -------------------------------------------------------------------------
    // 2. Neonatal Low Weight Handling (Pillar 2 Alignment)
    // -------------------------------------------------------------------------
    group('Neonatal low weight calculation support', () {
      test('ELBW neonate (0.8 kg) calculates weight-based dose successfully', () {
        const neonate = Patient(
          id: 'p_elbw',
          weightKg: 0.8,
          heightCm: 35.0,
          ageYears: 0,
          ageMonths: 1,
          sex: Sex.female,
          isScrStable: true,
        );

        const neonateDrug = Drug(
          id: 'ampicillin_neo',
          genericName: 'Ampicillin',
          category: DrugCategory.antibiotic,
          regimens: [
            DosingRegimen(
              audience: RegimenAudience.pediatric,
              route: DoseRoute.iv,
              indication: 'Neonatal Sepsis',
              dosingType: DosingType.weightBased,
              dosePerKg: 50.0,
              doseUnit: DoseUnit.mg,
              frequency: Frequency.q12h,
            ),
          ],
        );

        final result = PharmacistCalculator.calculateDose(
          patient: neonate,
          drug: neonateDrug,
          regimen: neonateDrug.regimens.first,
        );

        expect(result.success, isTrue);
        // 50 mg/kg * 0.8 kg = 40 mg
        expect(result.calculatedDose, closeTo(40.0, 0.01));
      });
    });

    // -------------------------------------------------------------------------
    // 3. Obese vs Non-Obese Dosing Weight Strategy
    // -------------------------------------------------------------------------
    group('Obese vs Non-obese dosing weight logic', () {
      const aminoglycosideRegimen = DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Gram-negative Sepsis',
        dosingType: DosingType.weightBased,
        dosePerKg: 5.0, // 5 mg/kg
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q24h,
        dosingWeightStrategy: DosingWeightStrategy.adjustedIfObese,
      );

      const testAmikacin = Drug(
        id: 'amikacin_weight_test',
        genericName: 'Amikacin',
        category: DrugCategory.antibiotic,
        regimens: [aminoglycosideRegimen],
      );

      test('Obese patient (BMI >= 30, TBW > IBW) uses Adjusted Body Weight', () {
        // Height 170 cm, Weight 120 kg (BMI = 120 / 1.7^2 = 41.52)
        // IBW male = 50 + 2.3 * (66.93 - 60) = 50 + 15.94 = ~65.94 kg
        // AdjBW = 65.94 + 0.4 * (120 - 65.94) = 65.94 + 21.62 = ~87.56 kg
        const obesePatient = Patient(
          id: 'p_obese',
          weightKg: 120.0,
          heightCm: 170.0,
          ageYears: 40,
          sex: Sex.male,
          isScrStable: true,
        );

        final result = PharmacistCalculator.calculateDose(
          patient: obesePatient,
          drug: testAmikacin,
          regimen: aminoglycosideRegimen,
        );

        expect(result.success, isTrue);
        expect(result.adjBwKg, isNotNull);
        // Dose = 5 mg/kg * ~87.56 kg = ~437.8 mg
        expect(result.calculatedDose, closeTo(437.8, 2.0));
      });

      test('Overweight but non-obese patient (BMI < 30) uses Actual Weight', () {
        // Height 170 cm, Weight 75 kg (BMI = 75 / 1.7^2 = 25.95 < 30)
        const overweightPatient = Patient(
          id: 'p_overweight',
          weightKg: 75.0,
          heightCm: 170.0,
          ageYears: 40,
          sex: Sex.male,
          isScrStable: true,
        );

        final result = PharmacistCalculator.calculateDose(
          patient: overweightPatient,
          drug: testAmikacin,
          regimen: aminoglycosideRegimen,
        );

        expect(result.success, isTrue);
        // Dose = 5 mg/kg * 75 kg = 375 mg
        expect(result.calculatedDose, equals(375.0));
      });

      test('Underweight patient (TBW < IBW) uses Actual Weight', () {
        // Height 170 cm (IBW ~66 kg), Weight 45 kg
        const cachecticPatient = Patient(
          id: 'p_cachectic',
          weightKg: 45.0,
          heightCm: 170.0,
          ageYears: 40,
          sex: Sex.male,
          isScrStable: true,
        );

        final result = PharmacistCalculator.calculateDose(
          patient: cachecticPatient,
          drug: testAmikacin,
          regimen: aminoglycosideRegimen,
        );

        expect(result.success, isTrue);
        // Dose = 5 mg/kg * 45 kg = 225 mg
        expect(result.calculatedDose, equals(225.0));
      });
    });

    // -------------------------------------------------------------------------
    // 4. Biological Units (IU, mEq) Volume Calculation Safety
    // -------------------------------------------------------------------------
    group('Biological units volume protection', () {
      test('Heparin in units does not divide by effDilutionMgPerMl incorrectly', () {
        final heparin = DrugDatabase.findById('heparin')!;
        final reg = heparin.regimens.first;

        final result = PharmacistCalculator.calculateDose(
          patient: adultPatient,
          drug: heparin,
          regimen: reg,
        );

        expect(result.success, isTrue);
        // Infusion rate must be in units/kg/hr or units/hr, not corrupted by mg dilution
        expect(result.infusionResult, isNotNull);
        expect(result.infusionResult!.rateUnit, equals(RateUnit.uKgHr));
      });
    });

    // -------------------------------------------------------------------------
    // 5. Ironclad Rule 5: Non-Blocking Overdose Policy
    // -------------------------------------------------------------------------
    group('Ironclad Rule 5: Non-blocking overdose calculation', () {
      test('Prescribed dose exceeding max limit computes dose and attaches warning without blocking', () {
        const paracetamol = Drug(
          id: 'pcm_od_test',
          genericName: 'Paracetamol',
          category: DrugCategory.analgesic,
          availableStrengths: [500.0],
          tabletSplittable: true,
          regimens: [
            DosingRegimen(
              route: DoseRoute.po,
              indication: 'Fever',
              dosingType: DosingType.weightBased,
              dosePerKg: 15.0, // 15 mg/kg
              doseUnit: DoseUnit.mg,
              frequency: Frequency.q6h,
              limits: DoseLimit(
                maxSingleDose: 1000.0, // max 1000 mg
                maxDailyDose: 4000.0,
              ),
            ),
          ],
        );

        // 120 kg patient: 15 mg/kg * 120 = 1800 mg (exceeds 1000 mg max single dose)
        const heavyPatient = Patient(
          id: 'p_heavy',
          weightKg: 120.0,
          heightCm: 180.0,
          ageYears: 30,
          sex: Sex.male,
          isScrStable: true,
        );

        final result = PharmacistCalculator.calculateDose(
          patient: heavyPatient,
          drug: paracetamol,
          regimen: paracetamol.regimens.first,
        );

        // Rule 5: DO NOT zero out or hide calculatedDose!
        expect(result.success, isTrue);
        expect(result.calculatedDose, equals(1800.0));
        expect(result.roundedDose, equals(1750.0));

        // Warning must be generated
        expect(result.warnings, isNotEmpty);
        final odWarning = result.warnings.firstWhere(
          (w) => w.code == DoseWarningCode.maxSingleDoseExceeded,
        );
        expect(odWarning, isNotNull);
        expect(odWarning.calculatedValue, equals(1800.0));
        expect(odWarning.limitValue, equals(1000.0));
      });
    });

    // -------------------------------------------------------------------------
    // 6. Contiguous Renal Adjustment Tiers
    // -------------------------------------------------------------------------
    group('Contiguous renal adjustment boundary mapping', () {
      test('Meropenem continuous half-open tiers map CrCl 25.5, 9.5, and 26.0 accurately', () {
        final mero = DrugDatabase.findById('meropenem')!;
        final reg = mero.regimens.first;

        // CrCl = 25.5 mL/min (matches [10, 26) -> 500 mg q12h)
        const p25 = Patient(
          id: 'p_25',
          weightKg: 70.0,
          heightCm: 175.0,
          ageYears: 70,
          sex: Sex.male,
          creatinineClearanceMlMin: 25.5,
          isScrStable: true,
        );

        final res25 = PharmacistCalculator.calculateDose(
          patient: p25,
          drug: mero,
          regimen: reg,
        );
        expect(res25.success, isTrue);
        expect(res25.isRenallyAdjusted, isTrue);
        expect(res25.adjustedFrequency, equals('q12h'));
        expect(res25.calculatedDose, equals(500.0));

        // CrCl = 9.5 mL/min (matches [0, 10) -> 500 mg q24h)
        const p9 = Patient(
          id: 'p_9',
          weightKg: 70.0,
          heightCm: 175.0,
          ageYears: 80,
          sex: Sex.male,
          creatinineClearanceMlMin: 9.5,
          isScrStable: true,
        );

        final res9 = PharmacistCalculator.calculateDose(
          patient: p9,
          drug: mero,
          regimen: reg,
        );
        expect(res9.success, isTrue);
        expect(res9.isRenallyAdjusted, isTrue);
        expect(res9.adjustedFrequency, equals('q24h'));
        expect(res9.calculatedDose, equals(500.0));
      });
    });

    // -------------------------------------------------------------------------
    // 7. Pediatric BSA (Haycock) vs Adult BSA (Mosteller) Routing
    // -------------------------------------------------------------------------
    group('Pediatric BSA (Haycock) vs Adult BSA (Mosteller) routing and calculations', () {
      test('Direct BsaCalculator formulas and boundary validation', () {
        // Adult 70 kg, 175 cm Mosteller: sqrt((175 * 70) / 3600) = sqrt(3.402777) = 1.84466 m²
        expect(BsaCalculator.mosteller(heightCm: 175.0, weightKg: 70.0), closeTo(1.84466, 0.001));

        // Pediatric 30 kg, 135 cm Haycock: 0.024265 * (135^0.3964) * (30^0.5378) ~ 1.056 m²
        expect(BsaCalculator.haycock(heightCm: 135.0, weightKg: 30.0), closeTo(1.056, 0.01));

        // Neonate 3 kg, 50 cm Haycock: ~ 0.208 m²
        expect(BsaCalculator.haycock(heightCm: 50.0, weightKg: 3.0), closeTo(0.208, 0.01));

        // Guards
        expect(() => BsaCalculator.mosteller(heightCm: 0, weightKg: 70), throwsArgumentError);
        expect(() => BsaCalculator.mosteller(heightCm: 175, weightKg: -5), throwsArgumentError);
        expect(() => BsaCalculator.mosteller(heightCm: 301, weightKg: 70), throwsArgumentError);
        expect(() => BsaCalculator.mosteller(heightCm: 175, weightKg: 501), throwsArgumentError);
      });

      test('PharmacistCalculator routes child (<18y) to Haycock and adult (>=18y) to Mosteller', () {
        const childBsaRegimen = DosingRegimen(
          audience: RegimenAudience.pediatric,
          route: DoseRoute.ivInfusion,
          indication: 'Pediatric BSA Chemo Test',
          dosingType: DosingType.bsaBased,
          dosePerM2: 100.0,
          doseUnit: DoseUnit.mg,
          frequency: Frequency.q24h,
        );
        const adultBsaRegimen = DosingRegimen(
          audience: RegimenAudience.adult,
          route: DoseRoute.ivInfusion,
          indication: 'Adult BSA Chemo Test',
          dosingType: DosingType.bsaBased,
          dosePerM2: 100.0,
          doseUnit: DoseUnit.mg,
          frequency: Frequency.q24h,
        );
        const testBsaDrug = Drug(
          id: 'test_bsa_drug',
          genericName: 'Test Chemo',
          category: DrugCategory.other,
          regimens: [childBsaRegimen, adultBsaRegimen],
        );

        // Pediatric patient (10 yo)
        const childPatient = Patient(
          id: 'p_child_bsa',
          weightKg: 30.0,
          heightCm: 135.0,
          ageYears: 10,
          sex: Sex.male,
          isScrStable: true,
        );
        final childRes = PharmacistCalculator.calculateDose(
          patient: childPatient,
          drug: testBsaDrug,
          regimen: childBsaRegimen,
        );
        expect(childRes.success, isTrue);
        expect(childRes.formulaUsed, contains('Haycock'));
        final expectedChildBsa = BsaCalculator.haycock(heightCm: 135.0, weightKg: 30.0);
        expect(childRes.calculatedDose, closeTo(100.0 * expectedChildBsa, 0.01));

        // Adult patient (25 yo)
        const adultPatientBsa = Patient(
          id: 'p_adult_bsa',
          weightKg: 70.0,
          heightCm: 175.0,
          ageYears: 25,
          sex: Sex.female,
          isScrStable: true,
        );
        final adultRes = PharmacistCalculator.calculateDose(
          patient: adultPatientBsa,
          drug: testBsaDrug,
          regimen: adultBsaRegimen,
        );
        expect(adultRes.success, isTrue);
        expect(adultRes.formulaUsed, contains('Mosteller'));
        final expectedAdultBsa = BsaCalculator.mosteller(heightCm: 175.0, weightKg: 70.0);
        expect(adultRes.calculatedDose, closeTo(100.0 * expectedAdultBsa, 0.01));
      });
    });

    // -------------------------------------------------------------------------
    // 8. Bedside Schwartz and CKD-EPI 2021 Renal Function Evaluation
    // -------------------------------------------------------------------------
    group('Bedside Schwartz and CKD-EPI 2021 renal function evaluation', () {
      test('Bedside Schwartz pure function exactness and input guards', () {
        // eGFR = 0.413 * height / SCr
        // 135 cm, SCr 0.6 mg/dL -> 0.413 * 135 / 0.6 = 92.925 mL/min/1.73m²
        expect(RenalCalculator.bedsideSchwartz(heightCm: 135.0, serumCreatinineMgDl: 0.6), closeTo(92.925, 0.001));
        // 75 cm, SCr 0.3 mg/dL -> 0.413 * 75 / 0.3 = 103.25 mL/min/1.73m²
        expect(RenalCalculator.bedsideSchwartz(heightCm: 75.0, serumCreatinineMgDl: 0.3), closeTo(103.25, 0.001));

        expect(() => RenalCalculator.bedsideSchwartz(heightCm: 0, serumCreatinineMgDl: 0.6), throwsArgumentError);
        expect(() => RenalCalculator.bedsideSchwartz(heightCm: 100, serumCreatinineMgDl: 0), throwsArgumentError);
        expect(() => RenalCalculator.bedsideSchwartz(heightCm: 100, serumCreatinineMgDl: -0.5), throwsArgumentError);
      });

      test('PharmacistCalculator routes pediatric eGFR with Bedside Schwartz and protects infants < 1 year', () {
        const pedRenalRegimen = DosingRegimen(
          audience: RegimenAudience.pediatric,
          route: DoseRoute.iv,
          indication: 'Pediatric Infection',
          dosingType: DosingType.weightBased,
          dosePerKg: 20.0,
          doseUnit: DoseUnit.mg,
          frequency: Frequency.q8h,
          renalAdjustments: [
            RenalAdjustment(
              crclMin: 0,
              crclMax: 30,
              adjustmentFactor: 0.5,
              adjustedFrequency: Frequency.q12h,
            ),
          ],
        );
        const pedRenalDrug = Drug(
          id: 'ped_renal_drug',
          genericName: 'Pediatric Antimicrobial',
          category: DrugCategory.antibiotic,
          requiresRenalAdjustment: true,
          regimens: [pedRenalRegimen],
        );

        // Child (5 yo, height 110 cm, SCr 0.4 mg/dL)
        const childPatient = Patient(
          id: 'p_child_renal',
          weightKg: 18.0,
          heightCm: 110.0,
          ageYears: 5,
          sex: Sex.male,
          serumCreatinineMgDl: 0.4,
          isScrStable: true,
        );
        final childRes = PharmacistCalculator.calculateDose(
          patient: childPatient,
          drug: pedRenalDrug,
          regimen: pedRenalRegimen,
        );
        expect(childRes.success, isTrue);
        expect(childRes.warnings.any((w) => w.messageEn.contains('Bedside Schwartz')), isTrue);

        // Infant (< 1 year, ageYears: 0, ageMonths: 6)
        const infantPatient = Patient(
          id: 'p_infant_renal',
          weightKg: 7.0,
          heightCm: 65.0,
          ageYears: 0,
          ageMonths: 6,
          sex: Sex.female,
          serumCreatinineMgDl: 0.3,
          isScrStable: true,
        );
        final infantRes = PharmacistCalculator.calculateDose(
          patient: infantPatient,
          drug: pedRenalDrug,
          regimen: pedRenalRegimen,
        );
        expect(infantRes.warnings.any((w) => w.messageEn.contains('Infant (< 1 year)')), isTrue);
      });

      test('CKD-EPI 2021 race-free adult exactness and pediatric rejection guard', () {
        // Adult age 40 male, SCr 0.9 mg/dL: kappa=0.9, alpha=-0.302, SCr/kappa=1.0 -> 142 * (1.0)^-0.302 * (1.0)^-1.2 * 0.9938^40 = 142 * 0.77918 = ~110.64 mL/min/1.73m²
        final egfrMale = RenalCalculator.ckdEpi2021(ageYears: 40, sex: Sex.male, serumCreatinineMgDl: 0.9);
        expect(egfrMale, closeTo(110.64, 0.5));

        // Adult age 40 female, SCr 0.7 mg/dL: kappa=0.7, alpha=-0.241, SCr/kappa=1.0 -> 142 * 1.012 * 0.9938^40 = ~111.97 mL/min/1.73m²
        final egfrFemale = RenalCalculator.ckdEpi2021(ageYears: 40, sex: Sex.female, serumCreatinineMgDl: 0.7);
        expect(egfrFemale, closeTo(111.97, 0.5));

        // Rejection for age < 18
        expect(() => RenalCalculator.ckdEpi2021(ageYears: 17, sex: Sex.male, serumCreatinineMgDl: 0.8), throwsArgumentError);
        expect(() => RenalCalculator.ckdEpi2021(ageYears: 40, sex: Sex.male, serumCreatinineMgDl: 0.0), throwsArgumentError);
      });
    });

    // -------------------------------------------------------------------------
    // 9. Cockcroft-Gault Adult Clearance and Boundary Guards
    // -------------------------------------------------------------------------
    group('Cockcroft-Gault adult clearance and boundary guards', () {
      test('Cockcroft-Gault formula matches clinical standards and female coefficient 0.85', () {
        // 70 kg, 35 yo male, SCr 0.9: (105 * 70) / (72 * 0.9) = 7350 / 64.8 = 113.426 mL/min
        expect(RenalCalculator.cockcroftGault(ageYears: 35, weightKg: 70.0, sex: Sex.male, serumCreatinineMgDl: 0.9), closeTo(113.426, 0.001));

        // Same patient if female: 113.4259 * 0.85 = 96.412 mL/min
        expect(RenalCalculator.cockcroftGault(ageYears: 35, weightKg: 70.0, sex: Sex.female, serumCreatinineMgDl: 0.9), closeTo(96.412, 0.001));
      });

      test('Extreme centenarian boundary (age 145) floors CrCl to 0.0 without negative output', () {
        // (140 - 145) * 50 / (72 * 1.0) = -250 / 72 = -3.472 -> pinned to 0.0
        final crcl = RenalCalculator.cockcroftGault(ageYears: 145, weightKg: 50.0, sex: Sex.male, serumCreatinineMgDl: 1.0);
        expect(crcl, equals(0.0));
      });

      test('Age > 150 or negative age throws ArgumentError', () {
        expect(() => RenalCalculator.cockcroftGault(ageYears: 151, weightKg: 70.0, sex: Sex.male, serumCreatinineMgDl: 1.0), throwsArgumentError);
        expect(() => RenalCalculator.cockcroftGault(ageYears: -1, weightKg: 70.0, sex: Sex.male, serumCreatinineMgDl: 1.0), throwsArgumentError);
      });

      test('Elderly patient (>=65y) with low SCr (<0.6 mg/dL) receives clinical advisory warning', () {
        const elderlyPatient = Patient(
          id: 'p_elderly_low_scr',
          weightKg: 50.0,
          heightCm: 160.0,
          ageYears: 75,
          sex: Sex.female,
          serumCreatinineMgDl: 0.45,
          isScrStable: true,
        );
        final mero = DrugDatabase.findById('meropenem')!;
        final res = PharmacistCalculator.calculateDose(
          patient: elderlyPatient,
          drug: mero,
          regimen: mero.regimens.first,
        );
        expect(res.success, isTrue);
        expect(res.warnings.any((w) => w.messageEn.contains('low SCr (<0.6 mg/dL)')), isTrue);
      });
    });

    // -------------------------------------------------------------------------
    // 10. Extended Rule 5 Overdose Preservation Matrix
    // -------------------------------------------------------------------------
    group('Extended Rule 5 Overdose Preservation Matrix', () {
      test('10x massive overdose (Paracetamol 150 mg/kg): calculates 10,500 mg without clamping or hiding', () {
        const paracetamol = Drug(
          id: 'pcm_10x_test',
          genericName: 'Paracetamol',
          category: DrugCategory.analgesic,
          availableStrengths: [500.0],
          regimens: [
            DosingRegimen(
              route: DoseRoute.po,
              indication: 'Massive Pain',
              dosingType: DosingType.weightBased,
              dosePerKg: 150.0, // 10x normal 15 mg/kg
              doseUnit: DoseUnit.mg,
              frequency: Frequency.q6h,
              limits: DoseLimit(
                maxSingleDose: 1000.0,
                maxDailyDose: 4000.0,
              ),
            ),
          ],
        );
        const pt = Patient(
          id: 'p_pcm_10x',
          weightKg: 70.0,
          heightCm: 175.0,
          ageYears: 30,
          sex: Sex.male,
          isScrStable: true,
        );
        final res = PharmacistCalculator.calculateDose(
          patient: pt,
          drug: paracetamol,
          regimen: paracetamol.regimens.first,
        );
        // Rule 5: Dose must be 10,500 mg, NOT clamped to 1000 mg
        expect(res.success, isTrue);
        expect(res.calculatedDose, equals(10500.0));
        expect(res.roundedDose, equals(10500.0));
        expect(res.warnings.any((w) => w.code == DoseWarningCode.maxSingleDoseExceeded), isTrue);
        expect(res.warnings.any((w) => w.code == DoseWarningCode.maxDailyDoseExceeded), isTrue);
      });

      test('Pediatric anaphylaxis Epinephrine IM (35 kg child -> 0.35 mg uncapped when limit is 0.30 mg)', () {
        const adrenalineDrug = Drug(
          id: 'epinephrine_ped_od',
          genericName: 'Epinephrine',
          category: DrugCategory.vasopressor,
          regimens: [
            DosingRegimen(
              audience: RegimenAudience.pediatric,
              route: DoseRoute.im,
              indication: 'Anaphylaxis',
              dosingType: DosingType.weightBased,
              dosePerKg: 0.01,
              doseUnit: DoseUnit.mg,
              frequency: Frequency(isOnce: true, displayEn: 'Stat', displayTh: 'ทันที'),
              standardDilutionMgPerMl: 1.0, // 1:1,000 = 1 mg/mL
              limits: DoseLimit(
                maxSingleDose: 0.30, // pediatric max single dose is 0.3 mg
              ),
            ),
          ],
        );
        const child35 = Patient(
          id: 'p_child_35',
          weightKg: 35.0,
          heightCm: 140.0,
          ageYears: 10,
          sex: Sex.male,
          isScrStable: true,
        );
        final res = PharmacistCalculator.calculateDose(
          patient: child35,
          drug: adrenalineDrug,
          regimen: adrenalineDrug.regimens.first,
        );
        // Rule 5: 35 kg * 0.01 = 0.35 mg, volume = 0.35 mL, must NOT be clamped to 0.30 mg
        expect(res.success, isTrue);
        expect(res.calculatedDose, closeTo(0.35, 0.001));
        expect(res.volumeMl, closeTo(0.35, 0.001));
        expect(res.warnings.any((w) => w.code == DoseWarningCode.maxSingleDoseExceeded), isTrue);
      });
    });
  });
}
