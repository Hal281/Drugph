// ============================================================
// ADVERSARIAL INFUSION INVERTIBILITY & EXTREME PHYSIOLOGY TEST
// ============================================================
// Empirical challenger verification harness for continuous IV infusion rates.
//
// Stress-tests:
//   1. Multi-dimensional grid round-trip invertibility identity (error < 1e-6)
//      across rates (0.001–100 mcg/kg/min), weights (0.4–350 kg),
//      and concentrations (1–50,000 mcg/mL).
//   2. Micro-dosing in neonatal intensive care (ELBW infants down to 0.4 kg).
//   3. Massive bariatric resuscitation (weights 250–350 kg, high-dose pressors).
//   4. SpecializedDosingCalculator vasoactive engine invertibility & Rule 5 alerts.
//   5. PharmacistCalculator end-to-end continuous infusion database evaluation
//      and pediatric safety gating.
//   6. Adversarial boundary guards: zero NaN, zero Infinity, zero unhandled crash.
//
// References: Lexicomp 2024, Sanford Guide 2024, AHA ACLS 2020, Surviving Sepsis 2021.
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/calculators/iv_rate_calculator.dart';
import 'package:drug_dosage_calculator/core/calculators/pharmacist_calculator.dart';
import 'package:drug_dosage_calculator/core/calculators/specialized_dosing_calculator.dart';
import 'package:drug_dosage_calculator/core/models/models.dart';
import 'package:drug_dosage_calculator/core/models/specialized_dosing_models.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';

void main() {
  group('Empirical Challenger: Continuous IV Infusion Invertibility & Stress Suite', () {
    // -------------------------------------------------------------------------
    // 1. Multi-dimensional Grid Round-Trip Invertibility
    // -------------------------------------------------------------------------
    group('1. Multi-dimensional Parameter Grid Invertibility Identity', () {
      test('1.1: Comprehensive grid (4,624 combinations): rate -> rateMlPerHr -> rate with max error < 1e-6', () {
        // Rates spanning 0.001 to 100 mcg/kg/min (16 values)
        final rates = <double>[
          0.001, 0.002, 0.005, 0.01, 0.02, 0.05,
          0.1, 0.2, 0.5, 1.0, 2.0, 5.0,
          10.0, 20.0, 50.0, 100.0,
        ];

        // Weights spanning 0.4 kg to 350 kg (17 values)
        final weights = <double>[
          0.4, 0.5, 0.75, 1.0, 2.0, 3.5, 5.0,
          10.0, 25.0, 50.0, 70.0, 100.0, 150.0,
          200.0, 250.0, 300.0, 350.0,
        ];

        // Concentrations spanning 1 to 50,000 mcg/mL (17 values)
        final concentrations = <double>[
          1.0, 2.0, 4.0, 8.0, 16.0, 32.0, 64.0,
          100.0, 250.0, 500.0, 1000.0, 1600.0, 3200.0,
          5000.0, 10000.0, 25000.0, 50000.0,
        ];

        int totalEvaluations = 0;
        double maxAbsoluteError = 0.0;
        double maxRelativeError = 0.0;

        for (final rate in rates) {
          for (final weight in weights) {
            for (final conc in concentrations) {
              totalEvaluations++;

              // Step 1: Forward calculation (desired rate -> mL/hr)
              final mlPerHour = IvRateCalculator.rateMlPerHrFromMcgKgMin(
                desiredMcgKgMin: rate,
                weightKg: weight,
                concentrationMcgPerMl: conc,
              );

              // Assertions on forward calculation
              expect(mlPerHour.isFinite, isTrue,
                  reason: 'Pump rate must be finite for rate=$rate, weight=$weight, conc=$conc');
              expect(mlPerHour.isNaN, isFalse);
              expect(mlPerHour > 0, isTrue);

              // Step 2: Inverse calculation (mL/hr -> delivered rate)
              final roundTripRate = IvRateCalculator.mcgPerKgPerMin(
                concentrationMcgPerMl: conc,
                rateMlPerHr: mlPerHour,
                weightKg: weight,
              );

              // Assertions on inverse calculation
              expect(roundTripRate.isFinite, isTrue,
                  reason: 'Round trip rate must be finite for rate=$rate, weight=$weight, conc=$conc');
              expect(roundTripRate.isNaN, isFalse);
              expect(roundTripRate > 0, isTrue);

              // Step 3: Exactness metrics
              final absError = (roundTripRate - rate).abs();
              final relError = absError / rate;

              if (absError > maxAbsoluteError) {
                maxAbsoluteError = absError;
              }
              if (relError > maxRelativeError) {
                maxRelativeError = relError;
              }

              // Assert strict tolerance (< 1e-6 as mandated by objective)
              expect(
                absError,
                lessThan(1e-6),
                reason: 'Invertibility error $absError exceeds 1e-6 at rate=$rate, wt=$weight, conc=$conc',
              );

              // Step 4: Consistency with calculateInfusionMlPerHour
              final mlPerHourFromGeneric = IvRateCalculator.calculateInfusionMlPerHour(
                doseRatePerMin: rate,
                doseRateUnit: RateUnit.mcgKgMin,
                concentration: Concentration(conc, ConcentrationUnit.mcgPerMl),
                weightKg: weight,
              );
              final genericDiff = (mlPerHourFromGeneric - mlPerHour).abs();
              expect(
                genericDiff,
                lessThan(1e-6),
                reason: 'calculateInfusionMlPerHour divergence $genericDiff at rate=$rate, wt=$weight, conc=$conc',
              );
            }
          }
        }

        expect(totalEvaluations, equals(4624));
        // Verify that across 4,624 combinations, maximum error is within IEEE floating point precision (< 1e-10)
        expect(maxAbsoluteError, lessThan(1e-10));
        expect(maxRelativeError, lessThan(1e-12));
      });
    });

    // -------------------------------------------------------------------------
    // 2. Micro-Dosing in Neonatal Intensive Care (ELBW Infants)
    // -------------------------------------------------------------------------
    group('2. Micro-Dosing in Neonatal Intensive Care (ELBW Infants down to 0.4 kg)', () {
      test('2.1: 0.4 kg ELBW infant receiving Epinephrine 0.01 mcg/kg/min (16 mcg/mL)', () {
        const weight = 0.4;
        const rate = 0.01; // mcg/kg/min
        const conc = 16.0; // mcg/mL standard dilution

        // Theoretical pump rate:
        // Dose per min = 0.01 * 0.4 = 0.004 mcg/min
        // Dose per hr = 0.004 * 60 = 0.24 mcg/hr
        // Pump rate = 0.24 / 16.0 = 0.015 mL/hr
        final pumpRate = IvRateCalculator.rateMlPerHrFromMcgKgMin(
          desiredMcgKgMin: rate,
          weightKg: weight,
          concentrationMcgPerMl: conc,
        );

        expect(pumpRate, closeTo(0.015, 1e-9));
        expect(pumpRate.isFinite, isTrue);
        expect(pumpRate.isNaN, isFalse);

        final backRate = IvRateCalculator.mcgPerKgPerMin(
          concentrationMcgPerMl: conc,
          rateMlPerHr: pumpRate,
          weightKg: weight,
        );
        expect(backRate, closeTo(rate, 1e-12));
      });

      test('2.2: 0.4 kg ELBW infant receiving diluted Epinephrine 4.0 mcg/mL (neonatal syringe pump)', () {
        const weight = 0.4;
        const rate = 0.01;
        const conc = 4.0; // Diluted for fine syringe pump delivery

        // Dose per hr = 0.24 mcg/hr -> Pump rate = 0.24 / 4 = 0.06 mL/hr
        final pumpRate = IvRateCalculator.rateMlPerHrFromMcgKgMin(
          desiredMcgKgMin: rate,
          weightKg: weight,
          concentrationMcgPerMl: conc,
        );

        expect(pumpRate, closeTo(0.06, 1e-9));
        final backRate = IvRateCalculator.mcgPerKgPerMin(
          concentrationMcgPerMl: conc,
          rateMlPerHr: pumpRate,
          weightKg: weight,
        );
        expect(backRate, closeTo(rate, 1e-12));
      });

      test('2.3: 0.5 kg ELBW infant receiving Dopamine 2.5 mcg/kg/min (800 mcg/mL)', () {
        const weight = 0.5;
        const rate = 2.5;
        const conc = 800.0; // 40 mg in 50 mL D5W = 800 mcg/mL

        // Dose per hr = 2.5 * 0.5 * 60 = 75.0 mcg/hr -> Pump rate = 75.0 / 800 = 0.09375 mL/hr
        final pumpRate = IvRateCalculator.rateMlPerHrFromMcgKgMin(
          desiredMcgKgMin: rate,
          weightKg: weight,
          concentrationMcgPerMl: conc,
        );

        expect(pumpRate, closeTo(0.09375, 1e-9));
        final backRate = IvRateCalculator.mcgPerKgPerMin(
          concentrationMcgPerMl: conc,
          rateMlPerHr: pumpRate,
          weightKg: weight,
        );
        expect(backRate, closeTo(rate, 1e-12));
      });

      test('2.4: 0.4 kg ELBW infant receiving Dobutamine 5.0 mcg/kg/min (1000 mcg/mL)', () {
        const weight = 0.4;
        const rate = 5.0;
        const conc = 1000.0;

        // Dose per hr = 5.0 * 0.4 * 60 = 120.0 mcg/hr -> Pump rate = 120 / 1000 = 0.12 mL/hr
        final pumpRate = IvRateCalculator.rateMlPerHrFromMcgKgMin(
          desiredMcgKgMin: rate,
          weightKg: weight,
          concentrationMcgPerMl: conc,
        );

        expect(pumpRate, closeTo(0.12, 1e-9));
        final backRate = IvRateCalculator.mcgPerKgPerMin(
          concentrationMcgPerMl: conc,
          rateMlPerHr: pumpRate,
          weightKg: weight,
        );
        expect(backRate, closeTo(rate, 1e-12));
      });

      test('2.5: 0.4 kg ELBW infant receiving Milrinone 0.25 mcg/kg/min (200 mcg/mL)', () {
        const weight = 0.4;
        const rate = 0.25;
        const conc = 200.0;

        // Dose per hr = 0.25 * 0.4 * 60 = 6.0 mcg/hr -> Pump rate = 6.0 / 200 = 0.03 mL/hr
        final pumpRate = IvRateCalculator.rateMlPerHrFromMcgKgMin(
          desiredMcgKgMin: rate,
          weightKg: weight,
          concentrationMcgPerMl: conc,
        );

        expect(pumpRate, closeTo(0.03, 1e-9));
        final backRate = IvRateCalculator.mcgPerKgPerMin(
          concentrationMcgPerMl: conc,
          rateMlPerHr: pumpRate,
          weightKg: weight,
        );
        expect(backRate, closeTo(rate, 1e-12));
      });
    });

    // -------------------------------------------------------------------------
    // 3. Massive Bariatric Resuscitation (250 kg – 350 kg)
    // -------------------------------------------------------------------------
    group('3. Massive Bariatric Resuscitation (250 kg – 350 kg)', () {
      test('3.1: 250 kg patient receiving Norepinephrine 3.0 mcg/kg/min (16 mcg/mL single strength)', () {
        const weight = 250.0;
        const rate = 3.0; // High-dose septic shock resuscitation ceiling
        const conc = 16.0; // 4 mg / 250 mL

        // Dose per hr = 3.0 * 250 * 60 = 45,000 mcg/hr = 45 mg/hr
        // Pump rate = 45,000 / 16 = 2,812.5 mL/hr
        final pumpRate = IvRateCalculator.rateMlPerHrFromMcgKgMin(
          desiredMcgKgMin: rate,
          weightKg: weight,
          concentrationMcgPerMl: conc,
        );

        expect(pumpRate, closeTo(2812.5, 1e-9));
        expect(pumpRate.isFinite, isTrue);

        final backRate = IvRateCalculator.mcgPerKgPerMin(
          concentrationMcgPerMl: conc,
          rateMlPerHr: pumpRate,
          weightKg: weight,
        );
        expect(backRate, closeTo(rate, 1e-12));
      });

      test('3.2: 250 kg patient receiving Norepinephrine 3.0 mcg/kg/min (64 mcg/mL quadruple strength)', () {
        const weight = 250.0;
        const rate = 3.0;
        const conc = 64.0; // 16 mg / 250 mL concentrated infusion for fluid restriction

        // Pump rate = 45,000 / 64 = 703.125 mL/hr
        final pumpRate = IvRateCalculator.rateMlPerHrFromMcgKgMin(
          desiredMcgKgMin: rate,
          weightKg: weight,
          concentrationMcgPerMl: conc,
        );

        expect(pumpRate, closeTo(703.125, 1e-9));
        final backRate = IvRateCalculator.mcgPerKgPerMin(
          concentrationMcgPerMl: conc,
          rateMlPerHr: pumpRate,
          weightKg: weight,
        );
        expect(backRate, closeTo(rate, 1e-12));
      });

      test('3.3: 350 kg extreme bariatric patient receiving Norepinephrine 3.0 mcg/kg/min (64 mcg/mL)', () {
        const weight = 350.0;
        const rate = 3.0;
        const conc = 64.0;

        // Dose per hr = 3.0 * 350 * 60 = 63,000 mcg/hr -> Pump rate = 63,000 / 64 = 984.375 mL/hr
        final pumpRate = IvRateCalculator.rateMlPerHrFromMcgKgMin(
          desiredMcgKgMin: rate,
          weightKg: weight,
          concentrationMcgPerMl: conc,
        );

        expect(pumpRate, closeTo(984.375, 1e-9));
        final backRate = IvRateCalculator.mcgPerKgPerMin(
          concentrationMcgPerMl: conc,
          rateMlPerHr: pumpRate,
          weightKg: weight,
        );
        expect(backRate, closeTo(rate, 1e-12));
      });

      test('3.4: 300 kg bariatric patient receiving Dobutamine 20.0 mcg/kg/min (2000 mcg/mL double strength)', () {
        const weight = 300.0;
        const rate = 20.0;
        const conc = 2000.0;

        // Dose per hr = 20.0 * 300 * 60 = 360,000 mcg/hr -> Pump rate = 360,000 / 2000 = 180.0 mL/hr
        final pumpRate = IvRateCalculator.rateMlPerHrFromMcgKgMin(
          desiredMcgKgMin: rate,
          weightKg: weight,
          concentrationMcgPerMl: conc,
        );

        expect(pumpRate, closeTo(180.0, 1e-9));
        final backRate = IvRateCalculator.mcgPerKgPerMin(
          concentrationMcgPerMl: conc,
          rateMlPerHr: pumpRate,
          weightKg: weight,
        );
        expect(backRate, closeTo(rate, 1e-12));
      });

      test('3.5: 350 kg bariatric patient receiving Dopamine 20.0 mcg/kg/min (3200 mcg/mL double strength)', () {
        const weight = 350.0;
        const rate = 20.0;
        const conc = 3200.0;

        // Dose per hr = 20.0 * 350 * 60 = 420,000 mcg/hr -> Pump rate = 420,000 / 3200 = 131.25 mL/hr
        final pumpRate = IvRateCalculator.rateMlPerHrFromMcgKgMin(
          desiredMcgKgMin: rate,
          weightKg: weight,
          concentrationMcgPerMl: conc,
        );

        expect(pumpRate, closeTo(131.25, 1e-9));
        final backRate = IvRateCalculator.mcgPerKgPerMin(
          concentrationMcgPerMl: conc,
          rateMlPerHr: pumpRate,
          weightKg: weight,
        );
        expect(backRate, closeTo(rate, 1e-12));
      });
    });

    // -------------------------------------------------------------------------
    // 4. SpecializedDosingCalculator Vasoactive Engine Invertibility & Rule 5
    // -------------------------------------------------------------------------
    group('4. SpecializedDosingCalculator Vasoactive Engine Invertibility & Rule 5', () {
      test('4.1: Neonatal micro-dose Epinephrine 0.01 mcg/kg/min for 0.4 kg infant', () {
        final res = SpecializedDosingCalculator.calculateVasoactiveInfusion(
          drug: VasoactiveDrug.epinephrine,
          orderedDose: 0.01,
          doseUnit: 'mcg/kg/min',
          patientWeightKg: 0.4,
          dilution: VasoactiveDilution.singleStrength, // 16 mcg/mL
        );

        expect(res.pumpRateMlPerHr, closeTo(0.015, 1e-9));
        expect(res.deliveredMcgKgMin, closeTo(0.01, 1e-9));
        expect(res.isCeilingExceeded, isFalse);
        expect(res.warningMessage, isEmpty);

        // Round trip back
        final backDose = IvRateCalculator.mcgPerKgPerMin(
          concentrationMcgPerMl: res.concentrationMcgPerMl,
          rateMlPerHr: res.pumpRateMlPerHr,
          weightKg: res.patientWeightKg,
        );
        expect(backDose, closeTo(0.01, 1e-9));
      });

      test('4.2: Massive bariatric Norepinephrine 3.0 mcg/kg/min for 250 kg patient preserves rate under Rule 5', () {
        final res = SpecializedDosingCalculator.calculateVasoactiveInfusion(
          drug: VasoactiveDrug.norepinephrine,
          orderedDose: 3.0,
          doseUnit: 'mcg/kg/min',
          patientWeightKg: 250.0,
          dilution: VasoactiveDilution.singleStrength, // 16 mcg/mL
        );

        // Rule 5: Dose rate is NEVER suppressed or blanked
        expect(res.pumpRateMlPerHr, closeTo(2812.5, 1e-9));
        expect(res.deliveredMcgKgMin, closeTo(3.0, 1e-9));
        expect(res.isCeilingExceeded, isTrue);
        expect(res.ceilingThreshold, equals(1.0));
        expect(res.warningMessage, contains('CRITICAL OVERDOSE / TITRATION CEILING EXCEEDED'));
        expect(res.warningMessage, contains('Rule 5 non-blocking active'));

        // Round-trip back from calculated pump rate
        final backDose = IvRateCalculator.mcgPerKgPerMin(
          concentrationMcgPerMl: res.concentrationMcgPerMl,
          rateMlPerHr: res.pumpRateMlPerHr,
          weightKg: res.patientWeightKg,
        );
        expect(backDose, closeTo(3.0, 1e-9));
      });

      test('4.3: Double strength dilution (32 mcg/mL) for 250 kg Norepinephrine resuscitation', () {
        final res = SpecializedDosingCalculator.calculateVasoactiveInfusion(
          drug: VasoactiveDrug.norepinephrine,
          orderedDose: 3.0,
          doseUnit: 'mcg/kg/min',
          patientWeightKg: 250.0,
          dilution: VasoactiveDilution.doubleStrength, // 32 mcg/mL
        );

        expect(res.pumpRateMlPerHr, closeTo(1406.25, 1e-9));
        expect(res.isCeilingExceeded, isTrue);

        final backDose = IvRateCalculator.mcgPerKgPerMin(
          concentrationMcgPerMl: res.concentrationMcgPerMl,
          rateMlPerHr: res.pumpRateMlPerHr,
          weightKg: res.patientWeightKg,
        );
        expect(backDose, closeTo(3.0, 1e-9));
      });
    });

    // -------------------------------------------------------------------------
    // 5. PharmacistCalculator End-to-End Continuous Regimens & Population Gating
    // -------------------------------------------------------------------------
    group('5. PharmacistCalculator End-to-End Continuous Regimens & Population Gating', () {
      test('5.1: Adult Norepinephrine regimen strictly blocks pediatric infant (<18y) for safety', () {
        const infant = Patient(
          id: 'pt-elbw-0.4kg',
          weightKg: 0.4,
          heightCm: 35.0,
          ageYears: 0,
          ageMonths: 0,
          sex: Sex.male,
          isScrStable: true,
        );

        final norepi = DrugDatabase.findById('norepinephrine')!;
        final reg = norepi.regimens.first;
        final res = PharmacistCalculator.calculateDose(
          patient: infant,
          drug: norepi,
          regimen: reg,
        );

        // Verification of safety block: adult continuous regimens reject infants
        expect(res.success, isFalse);
        expect(res.infusionResult, isNull);
        expect(res.warnings.any((w) => w.code == DoseWarningCode.pediatricBlocked), isTrue);
      });

      test('5.2: Pediatric continuous infusion regimen calculates pump rate for 0.4 kg infant with exact invertibility', () {
        const infant = Patient(
          id: 'pt-elbw-0.4kg',
          weightKg: 0.4,
          heightCm: 35.0,
          ageYears: 0,
          ageMonths: 0,
          sex: Sex.male,
          isScrStable: true,
        );

        // Define pediatric-eligible continuous regimen (audience: RegimenAudience.pediatric)
        const pediatricEpiRegimen = DosingRegimen(
          route: DoseRoute.ivInfusion,
          indication: 'Septic Shock / Inotropic Support (Pediatric)',
          dosingType: DosingType.titrated,
          continuousRateMin: 0.05,
          continuousRateMax: 1.0,
          continuousRateUnit: 'mcg/kg/min',
          rateUnit: RateUnit.mcgKgMin,
          doseUnit: DoseUnit.mcg,
          frequency: Frequency.continuous,
          standardDilutionMgPerMl: 0.016, // 16 mcg/mL
          audience: RegimenAudience.pediatric,
          verificationStatus: VerificationStatus.pendingReview,
        );

        final epi = DrugDatabase.findById('epinephrine')!;
        final res = PharmacistCalculator.calculateDose(
          patient: infant,
          drug: epi,
          regimen: pediatricEpiRegimen,
        );

        expect(res.success, isTrue);
        expect(res.infusionResult, isNotNull);
        final inf = res.infusionResult!;
        expect(inf.rateUnit, equals(RateUnit.mcgKgMin));
        expect(inf.rate, equals(0.05));
        expect(inf.rateMax, equals(1.0));

        // At 0.05 mcg/kg/min: (0.05 * 0.4 * 60) / 16.0 = 0.075 mL/hr
        expect(inf.rateMlPerHr, closeTo(0.075, 1e-6));
        // At 1.0 mcg/kg/min: (1.0 * 0.4 * 60) / 16.0 = 1.5 mL/hr
        expect(inf.rateMlPerHrMax, closeTo(1.5, 1e-6));

        // Round-trip back from calculated pump rates
        final backRate = IvRateCalculator.mcgPerKgPerMin(
          concentrationMcgPerMl: 16.0,
          rateMlPerHr: inf.rateMlPerHr!,
          weightKg: infant.weightKg,
        );
        expect(backRate, closeTo(inf.rate, 1e-9));

        final backRateMax = IvRateCalculator.mcgPerKgPerMin(
          concentrationMcgPerMl: 16.0,
          rateMlPerHr: inf.rateMlPerHrMax!,
          weightKg: infant.weightKg,
        );
        expect(backRateMax, closeTo(inf.rateMax!, 1e-9));
      });

      test('5.3: Cachectic adult (35 kg) Norepinephrine calculation via DrugDatabase', () {
        const cachecticAdult = Patient(
          id: 'pt-cachectic-35kg',
          weightKg: 35.0,
          heightCm: 160.0,
          ageYears: 65,
          sex: Sex.female,
          isScrStable: true,
        );

        final norepi = DrugDatabase.findById('norepinephrine')!;
        final reg = norepi.regimens.first;
        final res = PharmacistCalculator.calculateDose(
          patient: cachecticAdult,
          drug: norepi,
          regimen: reg,
        );

        expect(res.success, isTrue);
        expect(res.infusionResult, isNotNull);
        final inf = res.infusionResult!;
        // At 0.01 mcg/kg/min: (0.01 * 35 * 60) / 16.0 = 1.3125 mL/hr
        expect(inf.rateMlPerHr, closeTo(1.3125, 1e-6));
        // At 3.0 mcg/kg/min: (3.0 * 35 * 60) / 16.0 = 393.75 mL/hr
        expect(inf.rateMlPerHrMax, closeTo(393.75, 1e-6));

        final backRate = IvRateCalculator.mcgPerKgPerMin(
          concentrationMcgPerMl: 16.0,
          rateMlPerHr: inf.rateMlPerHr!,
          weightKg: cachecticAdult.weightKg,
        );
        expect(backRate, closeTo(inf.rate, 1e-9));
      });

      test('5.4: Bariatric (250 kg) Norepinephrine calculation via DrugDatabase', () {
        const bariatric = Patient(
          id: 'pt-bariatric-250kg',
          weightKg: 250.0,
          heightCm: 180.0,
          ageYears: 48,
          sex: Sex.female,
          isScrStable: true,
        );

        final norepi = DrugDatabase.findById('norepinephrine')!;
        final reg = norepi.regimens.first;
        final res = PharmacistCalculator.calculateDose(
          patient: bariatric,
          drug: norepi,
          regimen: reg,
        );

        expect(res.success, isTrue);
        expect(res.infusionResult, isNotNull);
        final inf = res.infusionResult!;
        // At 0.01 mcg/kg/min: (0.01 * 250 * 60) / 16.0 = 9.375 mL/hr
        expect(inf.rateMlPerHr, closeTo(9.375, 1e-6));
        // At 3.0 mcg/kg/min: (3.0 * 250 * 60) / 16.0 = 2812.5 mL/hr
        expect(inf.rateMlPerHrMax, closeTo(2812.5, 1e-6));

        // Invertibility check
        final backRate = IvRateCalculator.mcgPerKgPerMin(
          concentrationMcgPerMl: 16.0,
          rateMlPerHr: inf.rateMlPerHrMax!,
          weightKg: bariatric.weightKg,
        );
        expect(backRate, closeTo(inf.rateMax!, 1e-9));
      });

      test('5.5: Super Bariatric (350 kg) Dopamine titration via DrugDatabase', () {
        const superBariatric = Patient(
          id: 'pt-super-350kg',
          weightKg: 350.0,
          heightCm: 190.0,
          ageYears: 42,
          sex: Sex.male,
          isScrStable: true,
        );

        final dopa = DrugDatabase.findById('dopamine')!;
        final reg = dopa.regimens.first;
        final res = PharmacistCalculator.calculateDose(
          patient: superBariatric,
          drug: dopa,
          regimen: reg,
        );

        expect(res.success, isTrue);
        expect(res.infusionResult, isNotNull);
        final inf = res.infusionResult!;
        expect(inf.rateUnit, equals(RateUnit.mcgKgMin));
        // Dopamine standard conc: 400 mg / 250 mL = 1.6 mg/mL = 1600 mcg/mL
        // Min rate: 2.0 mcg/kg/min -> (2.0 * 350 * 60) / 1600 = 26.25 mL/hr
        expect(inf.rateMlPerHr, closeTo(26.25, 1e-6));
        // Max rate: 20.0 mcg/kg/min -> (20.0 * 350 * 60) / 1600 = 262.5 mL/hr
        expect(inf.rateMlPerHrMax, closeTo(262.5, 1e-6));

        final backMaxRate = IvRateCalculator.mcgPerKgPerMin(
          concentrationMcgPerMl: 1600.0,
          rateMlPerHr: inf.rateMlPerHrMax!,
          weightKg: superBariatric.weightKg,
        );
        expect(backMaxRate, closeTo(20.0, 1e-9));
      });
    });

    // -------------------------------------------------------------------------
    // 6. Adversarial Boundary Guards: Zero NaN, Zero Infinity, Strict Exceptions
    // -------------------------------------------------------------------------
    group('6. Adversarial Boundary Guards & Anomaly Hunting', () {
      test('6.1: Zero rate returns 0.0 mL/hr without exception', () {
        final pump = IvRateCalculator.rateMlPerHrFromMcgKgMin(
          desiredMcgKgMin: 0.0,
          weightKg: 70.0,
          concentrationMcgPerMl: 16.0,
        );
        expect(pump, equals(0.0));

        final dose = IvRateCalculator.mcgPerKgPerMin(
          concentrationMcgPerMl: 16.0,
          rateMlPerHr: 0.0,
          weightKg: 70.0,
        );
        expect(dose, equals(0.0));
      });

      test('6.2: Negative dose, weight, or concentration throws ArgumentError (never NaN/Inf)', () {
        expect(
          () => IvRateCalculator.rateMlPerHrFromMcgKgMin(
            desiredMcgKgMin: -0.01,
            weightKg: 70.0,
            concentrationMcgPerMl: 16.0,
          ),
          throwsArgumentError,
        );
        expect(
          () => IvRateCalculator.rateMlPerHrFromMcgKgMin(
            desiredMcgKgMin: 0.1,
            weightKg: -70.0,
            concentrationMcgPerMl: 16.0,
          ),
          throwsArgumentError,
        );
        expect(
          () => IvRateCalculator.rateMlPerHrFromMcgKgMin(
            desiredMcgKgMin: 0.1,
            weightKg: 70.0,
            concentrationMcgPerMl: -16.0,
          ),
          throwsArgumentError,
        );
      });

      test('6.3: Zero weight or zero concentration throws ArgumentError (guards against division by zero)', () {
        expect(
          () => IvRateCalculator.rateMlPerHrFromMcgKgMin(
            desiredMcgKgMin: 0.1,
            weightKg: 0.0,
            concentrationMcgPerMl: 16.0,
          ),
          throwsArgumentError,
        );
        expect(
          () => IvRateCalculator.rateMlPerHrFromMcgKgMin(
            desiredMcgKgMin: 0.1,
            weightKg: 70.0,
            concentrationMcgPerMl: 0.0,
          ),
          throwsArgumentError,
        );
        expect(
          () => IvRateCalculator.mcgPerKgPerMin(
            concentrationMcgPerMl: 0.0,
            rateMlPerHr: 10.0,
            weightKg: 70.0,
          ),
          throwsArgumentError,
        );
        expect(
          () => IvRateCalculator.mcgPerKgPerMin(
            concentrationMcgPerMl: 16.0,
            rateMlPerHr: 10.0,
            weightKg: 0.0,
          ),
          throwsArgumentError,
        );
      });

      test('6.4: NaN inputs throw ArgumentError and never propagate to calculation output', () {
        expect(
          () => IvRateCalculator.rateMlPerHrFromMcgKgMin(
            desiredMcgKgMin: double.nan,
            weightKg: 70.0,
            concentrationMcgPerMl: 16.0,
          ),
          throwsArgumentError,
        );
        expect(
          () => IvRateCalculator.rateMlPerHrFromMcgKgMin(
            desiredMcgKgMin: 0.1,
            weightKg: double.nan,
            concentrationMcgPerMl: 16.0,
          ),
          throwsArgumentError,
        );
        expect(
          () => IvRateCalculator.rateMlPerHrFromMcgKgMin(
            desiredMcgKgMin: 0.1,
            weightKg: 70.0,
            concentrationMcgPerMl: double.nan,
          ),
          throwsArgumentError,
        );
        expect(
          () => IvRateCalculator.mcgPerKgPerMin(
            concentrationMcgPerMl: double.nan,
            rateMlPerHr: 10.0,
            weightKg: 70.0,
          ),
          throwsArgumentError,
        );
      });

      test('6.5: Infinity and -Infinity inputs throw ArgumentError and never propagate to output', () {
        expect(
          () => IvRateCalculator.rateMlPerHrFromMcgKgMin(
            desiredMcgKgMin: double.infinity,
            weightKg: 70.0,
            concentrationMcgPerMl: 16.0,
          ),
          throwsArgumentError,
        );
        expect(
          () => IvRateCalculator.rateMlPerHrFromMcgKgMin(
            desiredMcgKgMin: 0.1,
            weightKg: double.infinity,
            concentrationMcgPerMl: 16.0,
          ),
          throwsArgumentError,
        );
        expect(
          () => IvRateCalculator.rateMlPerHrFromMcgKgMin(
            desiredMcgKgMin: 0.1,
            weightKg: 70.0,
            concentrationMcgPerMl: double.infinity,
          ),
          throwsArgumentError,
        );
        expect(
          () => IvRateCalculator.rateMlPerHrFromMcgKgMin(
            desiredMcgKgMin: double.negativeInfinity,
            weightKg: 70.0,
            concentrationMcgPerMl: 16.0,
          ),
          throwsArgumentError,
        );
      });

      test('6.6: Ultra-extreme astronomical ranges remain numerically stable without overflow', () {
        // Ultra-microscopic rate: 1e-9 mcg/kg/min for 0.4 kg infant at 50,000 mcg/mL
        final microscopicPump = IvRateCalculator.rateMlPerHrFromMcgKgMin(
          desiredMcgKgMin: 1e-9,
          weightKg: 0.4,
          concentrationMcgPerMl: 50000.0,
        );
        expect(microscopicPump.isFinite, isTrue);
        expect(microscopicPump > 0, isTrue);

        final backMicroscopic = IvRateCalculator.mcgPerKgPerMin(
          concentrationMcgPerMl: 50000.0,
          rateMlPerHr: microscopicPump,
          weightKg: 0.4,
        );
        expect(backMicroscopic, closeTo(1e-9, 1e-15));

        // Massive astronomical rate: 1,000 mcg/kg/min for 500 kg animal/giant at 1 mcg/mL
        final massivePump = IvRateCalculator.rateMlPerHrFromMcgKgMin(
          desiredMcgKgMin: 1000.0,
          weightKg: 500.0,
          concentrationMcgPerMl: 1.0,
        );
        expect(massivePump.isFinite, isTrue);
        expect(massivePump, equals(30000000.0)); // 30 million mL/hr

        final backMassive = IvRateCalculator.mcgPerKgPerMin(
          concentrationMcgPerMl: 1.0,
          rateMlPerHr: massivePump,
          weightKg: 500.0,
        );
        expect(backMassive, closeTo(1000.0, 1e-8));
      });
    });
  });
}
