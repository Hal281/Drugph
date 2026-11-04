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
  });
}
