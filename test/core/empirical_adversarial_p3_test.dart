// ============================================================
// Drug Dosage Calculator — Phase 3 Adversarial Empirical Stress Suite
// ============================================================
// Rigorous adversarial stress harness challenging the remediated
// calculation core, input validator, allergy matching, and DDI registry.
//
// Author: challenger_p3 (Empirical Challenger)
// Date: 2026-11-04
// ============================================================

import 'package:test/test.dart';
import 'package:drug_dosage_calculator/core/calculators/calculators.dart';
import 'package:drug_dosage_calculator/core/models/models.dart';
import 'package:drug_dosage_calculator/core/validators/input_validator.dart';
import 'package:drug_dosage_calculator/core/formatters/clinical_order_formatter.dart';

void main() {
  group('Phase 3 Challenger Empirical Adversarial Stress Suite', () {
    // =========================================================================
    // DIMENSION 1: EXTREME BOUNDS & NUMERICAL INSTABILITY
    // =========================================================================
    group('1. Extreme Bounds & Numerical Instability', () {
      group('1.1 Weight boundary conditions', () {
        test('0.4 kg: min viable neonatal weight is accepted for neonate with ELBW warning', () {
          final res = InputValidator.validatePatientInputs(
            weightKg: 0.4,
            heightCm: 30.0,
            ageYears: 0,
            ageMonths: 0,
            allowNeonatalLowWeight: true,
          );
          expect(res.isValid, isTrue, reason: '0.4 kg should be valid for ELBW neonate');
          expect(res.warningsEn.containsKey('weightKg'), isTrue);
          expect(res.warningsEn['weightKg'], contains('ELBW'));
        });

        test('0.39 kg: below min neonatal weight (< 0.4 kg) is rejected as implausible', () {
          final res = InputValidator.validatePatientInputs(
            weightKg: 0.39,
            heightCm: 30.0,
            ageYears: 0,
            ageMonths: 0,
            allowNeonatalLowWeight: true,
          );
          expect(res.isValid, isFalse);
          expect(res.errorsEn['weightKg'], contains('below 1 kg is implausible'));
        });

        test('0.99 kg: accepted for neonate with ELBW warning', () {
          final res = InputValidator.validatePatientInputs(
            weightKg: 0.99,
            heightCm: 35.0,
            ageYears: 0,
            ageMonths: 1,
            allowNeonatalLowWeight: true,
          );
          expect(res.isValid, isTrue);
          expect(res.warningsEn.containsKey('weightKg'), isTrue);
          expect(res.warningsEn['weightKg'], contains('ELBW'));
        });

        test('1.0 kg: standard minimum weight floor is accepted without ELBW warning', () {
          final res = InputValidator.validatePatientInputs(
            weightKg: 1.0,
            heightCm: 35.0,
            ageYears: 0,
            ageMonths: 1,
            allowNeonatalLowWeight: true,
          );
          expect(res.isValid, isTrue);
          expect(res.warningsEn.containsKey('weightKg'), isFalse);
        });

        test('0.4 kg in adult (age 30, allowNeonatalLowWeight: false) is strictly rejected', () {
          final res = InputValidator.validatePatientInputs(
            weightKg: 0.4,
            heightCm: 170.0,
            ageYears: 30,
            allowNeonatalLowWeight: false,
          );
          expect(res.isValid, isFalse);
          expect(res.errorsEn.containsKey('weightKg'), isTrue);
        });

        test('300 kg with 180 cm (severe adult obesity) is valid', () {
          final res = InputValidator.validatePatientInputs(
            weightKg: 300.0,
            heightCm: 180.0,
            ageYears: 40,
          );
          expect(res.isValid, isTrue);
          expect(res.errorsEn, isEmpty);
        });

        test('500.0 kg with 205 cm (maximum allowable weight boundary) is valid', () {
          final res = InputValidator.validatePatientInputs(
            weightKg: 500.0,
            heightCm: 205.0,
            ageYears: 40,
          );
          expect(res.isValid, isTrue);
        });

        test('500.1 kg: exceeds 500 kg limit and is rejected', () {
          final res = InputValidator.validatePatientInputs(
            weightKg: 500.1,
            heightCm: 200.0,
            ageYears: 40,
          );
          expect(res.isValid, isFalse);
          expect(res.errorsEn['weightKg'], contains('exceeds 500 kg'));
        });
      });

      group('1.2 Height boundary conditions', () {
        test('30.0 cm is minimum valid height', () {
          final res = InputValidator.validatePatientInputs(
            weightKg: 1.0,
            heightCm: 30.0,
            ageYears: 0,
            ageMonths: 0,
            allowNeonatalLowWeight: true,
          );
          expect(res.isValid, isTrue);
        });

        test('29.9 cm is rejected as implausible height (< 30 cm)', () {
          final res = InputValidator.validatePatientInputs(
            weightKg: 1.0,
            heightCm: 29.9,
            ageYears: 0,
            ageMonths: 0,
            allowNeonatalLowWeight: true,
          );
          expect(res.isValid, isFalse);
          expect(res.errorsEn['heightCm'], contains('below 30 cm is implausible'));
        });

        test('300.0 cm is maximum valid height', () {
          final res = InputValidator.validatePatientInputs(
            weightKg: 100.0,
            heightCm: 300.0,
            ageYears: 25,
          );
          expect(res.isValid, isTrue);
        });

        test('300.1 cm is rejected as exceeding maximum height', () {
          final res = InputValidator.validatePatientInputs(
            weightKg: 100.0,
            heightCm: 300.1,
            ageYears: 25,
          );
          expect(res.isValid, isFalse);
          expect(res.errorsEn['heightCm'], contains('exceeds 300 cm'));
        });
      });

      group('1.3 Age & months boundary conditions', () {
        test('Age 0 years, months 0 is valid', () {
          final res = InputValidator.validatePatientInputs(
            weightKg: 3.0,
            heightCm: 50.0,
            ageYears: 0,
            ageMonths: 0,
          );
          expect(res.isValid, isTrue);
        });

        test('Age 0 years, months 11 is valid', () {
          final res = InputValidator.validatePatientInputs(
            weightKg: 9.0,
            heightCm: 75.0,
            ageYears: 0,
            ageMonths: 11,
          );
          expect(res.isValid, isTrue);
        });

        test('Age 0 years, months 12 is rejected', () {
          final res = InputValidator.validatePatientInputs(
            weightKg: 9.0,
            heightCm: 75.0,
            ageYears: 0,
            ageMonths: 12,
          );
          expect(res.isValid, isFalse);
          expect(res.errorsEn['ageMonths'], contains('Months must be 0–11'));
        });

        test('Negative age (-1) is rejected', () {
          final res = InputValidator.validatePatientInputs(
            weightKg: 70.0,
            heightCm: 170.0,
            ageYears: -1,
          );
          expect(res.isValid, isFalse);
          expect(res.errorsEn['ageYears'], contains('cannot be negative'));
        });

        test('Age 150 is valid, 151 is rejected', () {
          expect(
            InputValidator.validatePatientInputs(
              weightKg: 50.0,
              heightCm: 160.0,
              ageYears: 150,
            ).isValid,
            isTrue,
          );
          expect(
            InputValidator.validatePatientInputs(
              weightKg: 50.0,
              heightCm: 160.0,
              ageYears: 151,
            ).isValid,
            isFalse,
          );
        });
      });

      group('1.4 Serum creatinine boundary conditions', () {
        test('SCr 0.0 mg/dL and negative are rejected', () {
          final resZero = InputValidator.validatePatientInputs(
            weightKg: 70.0,
            heightCm: 170.0,
            ageYears: 40,
            serumCreatinineMgDl: 0.0,
          );
          expect(resZero.isValid, isFalse);
          expect(resZero.errorsEn['serumCreatinineMgDl'], contains('must be greater than 0'));

          final resNeg = InputValidator.validatePatientInputs(
            weightKg: 70.0,
            heightCm: 170.0,
            ageYears: 40,
            serumCreatinineMgDl: -0.5,
          );
          expect(resNeg.isValid, isFalse);
        });

        test('SCr 30.0 mg/dL is valid, 30.1 mg/dL is rejected', () {
          expect(
            InputValidator.validatePatientInputs(
              weightKg: 70.0,
              heightCm: 170.0,
              ageYears: 40,
              serumCreatinineMgDl: 30.0,
            ).isValid,
            isTrue,
          );
          expect(
            InputValidator.validatePatientInputs(
              weightKg: 70.0,
              heightCm: 170.0,
              ageYears: 40,
              serumCreatinineMgDl: 30.1,
            ).isValid,
            isFalse,
          );
        });
      });

      group('1.5 Non-finite values (NaN, +Infinity, -Infinity) safety sweep', () {
        test('InputValidator rejects NaN and Infinity across all fields without throwing', () {
          for (final nonFinite in [double.nan, double.infinity, double.negativeInfinity]) {
            final resWeight = InputValidator.validatePatientInputs(
              weightKg: nonFinite,
              heightCm: 170.0,
              ageYears: 30,
            );
            expect(resWeight.isValid, isFalse);
            expect(resWeight.errorsEn.containsKey('weightKg'), isTrue);

            final resHeight = InputValidator.validatePatientInputs(
              weightKg: 70.0,
              heightCm: nonFinite,
              ageYears: 30,
            );
            expect(resHeight.isValid, isFalse);
            expect(resHeight.errorsEn.containsKey('heightCm'), isTrue);

            final resScr = InputValidator.validatePatientInputs(
              weightKg: 70.0,
              heightCm: 170.0,
              ageYears: 30,
              serumCreatinineMgDl: nonFinite,
            );
            expect(resScr.isValid, isFalse);
            expect(resScr.errorsEn.containsKey('serumCreatinineMgDl'), isTrue);

            expect(InputValidator.validateDose(dose: nonFinite).isValid, isFalse);
            expect(
              InputValidator.validatePositive(
                value: nonFinite,
                fieldNameEn: 'Rate',
                fieldNameTh: 'อัตรา',
              ).isValid,
              isFalse,
            );
          }
        });

        test('DoseRounder handles non-finite doses and strengths safely (returns null, never throws)', () {
          for (final nonFinite in [double.nan, double.infinity, double.negativeInfinity]) {
            expect(
              DoseRounder.roundToNearestStrength(nonFinite, [250.0, 500.0]),
              isNull,
            );
            expect(
              DoseRounder.roundToNearestStrength(500.0, [nonFinite]),
              isNull,
            );
          }
          // Mixed list containing NaN: safely ignores NaN and uses valid strength
          final rounded = DoseRounder.roundToNearestStrength(495.0, [double.nan, 500.0]);
          expect(rounded, equals(500.0));
        });

        test('WeightBasedCalculator rejects non-finite inputs with ArgumentError', () {
          for (final nf in [double.nan, double.infinity, double.negativeInfinity]) {
            expect(
              () => WeightBasedCalculator.idealBodyWeight(heightCm: nf, sex: Sex.male),
              throwsArgumentError,
            );
            expect(
              () => WeightBasedCalculator.adjustedBodyWeight(actualWeightKg: nf, ibwKg: 70.0),
              throwsArgumentError,
            );
            expect(
              () => WeightBasedCalculator.adjustedBodyWeight(actualWeightKg: 70.0, ibwKg: nf),
              throwsArgumentError,
            );
            expect(
              () => WeightBasedCalculator.calculateDose(weightKg: nf, dosePerKg: 10.0),
              throwsArgumentError,
            );
            expect(
              () => WeightBasedCalculator.calculateDose(weightKg: 70.0, dosePerKg: nf),
              throwsArgumentError,
            );
            expect(
              () => WeightBasedCalculator.calculateBsaDose(bsaM2: nf, dosePerM2: 50.0),
              throwsArgumentError,
            );
            expect(
              () => WeightBasedCalculator.calvertFormula(targetAuc: nf, gfrMlMin: 100.0),
              throwsArgumentError,
            );
            expect(
              () => WeightBasedCalculator.calvertFormula(targetAuc: 5.0, gfrMlMin: nf),
              throwsArgumentError,
            );
          }
        });

        test('RenalCalculator rejects non-finite inputs with ArgumentError', () {
          for (final nf in [double.nan, double.infinity, double.negativeInfinity]) {
            expect(
              () => RenalCalculator.cockcroftGault(
                ageYears: 50,
                weightKg: nf,
                sex: Sex.male,
                serumCreatinineMgDl: 1.0,
              ),
              throwsArgumentError,
            );
            expect(
              () => RenalCalculator.cockcroftGault(
                ageYears: 50,
                weightKg: 70.0,
                sex: Sex.male,
                serumCreatinineMgDl: nf,
              ),
              throwsArgumentError,
            );
            expect(
              () => RenalCalculator.bedsideSchwartz(heightCm: nf, serumCreatinineMgDl: 1.0),
              throwsArgumentError,
            );
            expect(
              () => RenalCalculator.bedsideSchwartz(heightCm: 120.0, serumCreatinineMgDl: nf),
              throwsArgumentError,
            );
            expect(
              () => RenalCalculator.ckdEpi2021(ageYears: 50, sex: Sex.male, serumCreatinineMgDl: nf),
              throwsArgumentError,
            );
          }
        });

        test('BsaCalculator rejects non-finite inputs with ArgumentError', () {
          for (final nf in [double.nan, double.infinity, double.negativeInfinity]) {
            expect(
              () => BsaCalculator.mosteller(heightCm: nf, weightKg: 70.0),
              throwsArgumentError,
            );
            expect(
              () => BsaCalculator.mosteller(heightCm: 170.0, weightKg: nf),
              throwsArgumentError,
            );
            expect(
              () => BsaCalculator.dubois(heightCm: nf, weightKg: 70.0),
              throwsArgumentError,
            );
            expect(
              () => BsaCalculator.haycock(heightCm: nf, weightKg: 70.0),
              throwsArgumentError,
            );
          }
        });

        test('IvRateCalculator rejects non-finite inputs with ArgumentError', () {
          for (final nf in [double.nan, double.infinity, double.negativeInfinity]) {
            expect(
              () => IvRateCalculator.infusionRateMlPerHr(volumeMl: nf, timeMinutes: 60.0),
              throwsArgumentError,
            );
            expect(
              () => IvRateCalculator.infusionRateMlPerHr(volumeMl: 500.0, timeMinutes: nf),
              throwsArgumentError,
            );
            expect(
              () => IvRateCalculator.dripRateDropsPerMin(volumeMl: nf, timeMinutes: 60.0),
              throwsArgumentError,
            );
            expect(
              () => IvRateCalculator.volumeForDose(desiredDoseMg: nf, concentrationMgPerMl: 10.0),
              throwsArgumentError,
            );
            expect(
              () => IvRateCalculator.doseRateMgPerHr(concentrationMgPerMl: nf, rateMlPerHr: 50.0),
              throwsArgumentError,
            );
            expect(
              () => IvRateCalculator.mcgPerKgPerMin(
                concentrationMcgPerMl: nf,
                rateMlPerHr: 10.0,
                weightKg: 70.0,
              ),
              throwsArgumentError,
            );
            expect(
              () => IvRateCalculator.rateMlPerHrFromMcgKgMin(
                desiredMcgKgMin: nf,
                weightKg: 70.0,
                concentrationMcgPerMl: 16.0,
              ),
              throwsArgumentError,
            );
            expect(
              () => IvRateCalculator.rateMlPerHrFromUnits(
                desiredUnitsPerHr: nf,
                concentrationUnitsPerMl: 1.0,
              ),
              throwsArgumentError,
            );
          }
        });

        test('PharmacistCalculator.calculateDose with patient having NaN inputs returns failure safely without throwing', () {
          const patientWithNan = Patient(
            id: 'nan_p',
            weightKg: double.nan,
            heightCm: 170.0,
            ageYears: 30,
            sex: Sex.male,
            isScrStable: true,
          );
          const drug = Drug(
            id: 'test_drug',
            genericName: 'TestDrug',
            category: DrugCategory.antibiotic,
            regimens: [
              DosingRegimen(
                route: DoseRoute.po,
                indication: 'Test',
                dosingType: DosingType.fixed,
                fixedDose: 500.0,
                doseUnit: DoseUnit.mg,
                frequency: Frequency.q12h,
              ),
            ],
          );

          final result = PharmacistCalculator.calculateDose(
            patient: patientWithNan,
            drug: drug,
            regimen: drug.regimens.first,
          );
          expect(result.success, isFalse);
          expect(result.warnings.first.severity, equals(LimitSeverity.hard));
          expect(result.warnings.first.code, equals(DoseWarningCode.calculationError));
        });

        test('PharmacistCalculator.verifyOrder rejects non-positive and non-finite ordered doses without throwing', () {
          const patient = Patient(
            id: 'valid_p',
            weightKg: 70.0,
            heightCm: 170.0,
            ageYears: 30,
            sex: Sex.male,
            isScrStable: true,
          );
          const drug = Drug(
            id: 'test_drug',
            genericName: 'TestDrug',
            category: DrugCategory.antibiotic,
            regimens: [
              DosingRegimen(
                route: DoseRoute.po,
                indication: 'Test',
                dosingType: DosingType.fixed,
                fixedDose: 500.0,
                doseUnit: DoseUnit.mg,
                frequency: Frequency.q12h,
              ),
            ],
          );

          for (final badDose in [double.nan, double.infinity, double.negativeInfinity, 0.0, -100.0]) {
            final orderRes = PharmacistCalculator.verifyOrder(
              patient: patient,
              drug: drug,
              regimen: drug.regimens.first,
              orderedDose: badDose,
              orderedFrequency: Frequency.q12h,
            );
            expect(orderRes.isAcceptable, isFalse);
            expect(orderRes.warnings, isNotEmpty);
            final errWarn = orderRes.warnings.firstWhere((w) => w.code == DoseWarningCode.calculationError);
            expect(errWarn.severity, equals(LimitSeverity.hard));
            expect(errWarn.messageEn, contains('INVALID ORDERED DOSE'));
          }
        });
      });

      group('1.6 Division by zero safety', () {
        test('Serum creatinine = 0 in Cockcroft-Gault throws ArgumentError instead of returning Infinity', () {
          expect(
            () => RenalCalculator.cockcroftGault(
              ageYears: 40,
              weightKg: 70.0,
              sex: Sex.male,
              serumCreatinineMgDl: 0.0,
            ),
            throwsArgumentError,
          );
        });

        test('Serum creatinine = 0 in Bedside Schwartz throws ArgumentError', () {
          expect(
            () => RenalCalculator.bedsideSchwartz(heightCm: 120.0, serumCreatinineMgDl: 0.0),
            throwsArgumentError,
          );
        });

        test('Serum creatinine = 0 in CKD-EPI 2021 throws ArgumentError', () {
          expect(
            () => RenalCalculator.ckdEpi2021(ageYears: 40, sex: Sex.male, serumCreatinineMgDl: 0.0),
            throwsArgumentError,
          );
        });

        test('Time minutes = 0 in IV rate calculations throws ArgumentError', () {
          expect(
            () => IvRateCalculator.infusionRateMlPerHr(volumeMl: 500.0, timeMinutes: 0.0),
            throwsArgumentError,
          );
          expect(
            () => IvRateCalculator.dripRateDropsPerMin(volumeMl: 500.0, timeMinutes: 0.0),
            throwsArgumentError,
          );
        });

        test('Concentration = 0 in IV volume and rate calculations throws ArgumentError', () {
          expect(
            () => IvRateCalculator.volumeForDose(desiredDoseMg: 500.0, concentrationMgPerMl: 0.0),
            throwsArgumentError,
          );
          expect(
            () => IvRateCalculator.rateMlPerHrFromUnits(desiredUnitsPerHr: 10.0, concentrationUnitsPerMl: 0.0),
            throwsArgumentError,
          );
          expect(
            () => IvRateCalculator.calculateInfusionMlPerHour(
              doseRatePerMin: 5.0,
              doseRateUnit: RateUnit.mgHr,
              concentration: const Concentration(0.0, ConcentrationUnit.mgPerMl),
            ),
            throwsArgumentError,
          );
        });

        test('Weight = 0 in weight-based infusion calculations throws ArgumentError', () {
          expect(
            () => IvRateCalculator.calculateInfusionMlPerHour(
              doseRatePerMin: 2.0,
              doseRateUnit: RateUnit.mcgKgMin,
              concentration: const Concentration(4.0, ConcentrationUnit.mgPerMl),
              weightKg: 0.0,
            ),
            throwsArgumentError,
          );
          expect(
            () => IvRateCalculator.mcgPerKgPerMin(
              concentrationMcgPerMl: 16.0,
              rateMlPerHr: 15.0,
              weightKg: 0.0,
            ),
            throwsArgumentError,
          );
        });
      });
    });

    // =========================================================================
    // DIMENSION 2: CLINICAL CORNER CASES
    // =========================================================================
    group('2. Clinical Corner Cases', () {
      group('2.1 Cachectic patient dosing weight integrity', () {
        test('Cachectic male (35 kg, 175 cm, IBW ~70.5 kg) AdjBW is guaranteed <= TBW (returns actual weight 35 kg)', () {
          final ibw = WeightBasedCalculator.idealBodyWeight(heightCm: 175.0, sex: Sex.male);
          expect(ibw, closeTo(70.46, 0.1));

          // Actual weight 35 kg < IBW 70.46 kg
          final adjBw = WeightBasedCalculator.adjustedBodyWeight(
            actualWeightKg: 35.0,
            ibwKg: ibw,
          );
          expect(adjBw, equals(35.0), reason: 'AdjBW must never be below actual weight or pull weight falsely towards IBW');
          expect(adjBw <= 35.0, isTrue);

          // Dosing weight selector returns actual weight 35 kg (patient is lean, not obese)
          final dosingWt = WeightBasedCalculator.dosingWeight(
            actualWeightKg: 35.0,
            heightCm: 175.0,
            sex: Sex.male,
            useAdjBwIfObese: true,
          );
          expect(dosingWt, equals(35.0));
          expect(WeightBasedCalculator.isObese(actualWeightKg: 35.0, ibwKg: ibw), isFalse);
        });

        test('Severely malnourished female (28 kg, 160 cm, IBW 52.4 kg) AdjBW equals actual weight 28 kg', () {
          final ibw = WeightBasedCalculator.idealBodyWeight(heightCm: 160.0, sex: Sex.female);
          final adjBw = WeightBasedCalculator.adjustedBodyWeight(
            actualWeightKg: 28.0,
            ibwKg: ibw,
          );
          expect(adjBw, equals(28.0));
        });
      });

      group('2.2 Short stature adult Devine IBW verification (< 60 inches)', () {
        test('Height 140 cm (55.118 inches) adult Devine IBW', () {
          // 140 cm / 2.54 = 55.118 inches. Height < 60 in uses base - 2.3 * (60 - heightInches)
          // Male: 50 - 2.3 * 4.8819 = 38.77 kg
          // Female: 45.5 - 2.3 * 4.8819 = 34.27 kg
          final ibwMale = WeightBasedCalculator.idealBodyWeight(heightCm: 140.0, sex: Sex.male);
          final ibwFemale = WeightBasedCalculator.idealBodyWeight(heightCm: 140.0, sex: Sex.female);

          expect(ibwMale, closeTo(38.77, 0.1));
          expect(ibwFemale, closeTo(34.27, 0.1));
          expect(ibwMale > 10.0, isTrue);
          expect(ibwFemale > 10.0, isTrue);
        });

        test('Height exactly 60 inches (152.4 cm) returns exact base values', () {
          final ibwMale = WeightBasedCalculator.idealBodyWeight(heightCm: 152.4, sex: Sex.male);
          final ibwFemale = WeightBasedCalculator.idealBodyWeight(heightCm: 152.4, sex: Sex.female);

          expect(ibwMale, closeTo(50.0, 0.01));
          expect(ibwFemale, closeTo(45.5, 0.01));
        });

        test('Extremely short stature adult (100 cm, 39.37 inches) clamps at clinical minimum 10.0 kg', () {
          final ibwMale = WeightBasedCalculator.idealBodyWeight(heightCm: 100.0, sex: Sex.male);
          final ibwFemale = WeightBasedCalculator.idealBodyWeight(heightCm: 100.0, sex: Sex.female);

          expect(ibwMale, equals(10.0));
          expect(ibwFemale, equals(10.0));
        });
      });

      group('2.3 Non-blocking overdose policy (Ironclad Rule 5)', () {
        test('Extreme dose (e.g. 5,000 mg single dose) calculates successfully, generates warning, and NEVER hides or zeroes dose', () {
          const amoxicillin = Drug(
            id: 'amox_test',
            genericName: 'Amoxicillin',
            category: DrugCategory.antibiotic,
            availableStrengths: [500.0, 1000.0],
            regimens: [
              DosingRegimen(
                route: DoseRoute.po,
                indication: 'Severe Sepsis Challenge',
                dosingType: DosingType.weightBased,
                dosePerKg: 50.0, // 50 mg/kg
                doseUnit: DoseUnit.mg,
                frequency: Frequency.q8h,
                limits: DoseLimit(
                  maxSingleDose: 1000.0,
                  maxDailyDose: 3000.0,
                ),
              ),
            ],
          );

          // 100 kg patient: 50 mg/kg * 100 kg = 5000 mg (5x max single dose of 1000 mg)
          const patient = Patient(
            id: 'p_100',
            weightKg: 100.0,
            heightCm: 180.0,
            ageYears: 35,
            sex: Sex.male,
            isScrStable: true,
          );

          final result = PharmacistCalculator.calculateDose(
            patient: patient,
            drug: amoxicillin,
            regimen: amoxicillin.regimens.first,
          );

          // Ironclad Rule 5 Invariants:
          // 1. Success must be true
          expect(result.success, isTrue);
          // 2. calculatedDose MUST NOT be null or 0.0
          expect(result.calculatedDose, isNotNull);
          expect(result.calculatedDose, equals(5000.0));
          // 3. roundedDose MUST NOT be null or 0.0
          expect(result.roundedDose, isNotNull);
          expect(result.roundedDose, equals(5000.0));
          // 4. Hard overdose warning must be attached
          expect(result.warnings, isNotEmpty);
          final odWarning = result.warnings.firstWhere(
            (w) => w.code == DoseWarningCode.maxSingleDoseExceeded,
          );
          expect(odWarning.severity, equals(LimitSeverity.hard));
          expect(odWarning.calculatedValue, equals(5000.0));
          expect(odWarning.limitValue, equals(1000.0));

          // 5. ClinicalOrderFormatter renders dose and appends explicit OVERDOSE WARNING tag
          final order = ClinicalOrderFormatter.formatHisOrder(
            patient: patient,
            drug: amoxicillin,
            regimen: amoxicillin.regimens.first,
            result: result,
          );
          expect(order, contains('Amoxicillin 5000 mg'));
          expect(order, contains('OVERDOSE WARNING'));
        });
      });
    });

    // =========================================================================
    // DIMENSION 3: ALLERGY & DDI INVARIANTS
    // =========================================================================
    group('3. Allergy & DDI Invariants', () {
      group('3.1 Bidirectional beta-lactam cross-reactivity', () {
        test('Cephalosporin allergy -> Penicillin prescribed: flags 2–5% cross-reactivity alert', () {
          final alerts = AllergyService.evaluateAllergies(
            patientAllergies: ['Cefazolin'],
            drugGenericName: 'Amoxicillin',
            drugId: 'amoxicillin',
            drugClass: DrugClass.betaLactamPenicillin,
            legacyAllergyClass: 'Penicillin',
          );
          expect(alerts, isNotEmpty);
          final cross = alerts.firstWhere((a) => a.hasCrossReactivity);
          expect(cross.severity, equals(LimitSeverity.soft));
          expect(cross.hasDirectMatch, isFalse);
          expect(cross.messageEn, contains('cephalosporin allergy'));
          expect(cross.messageEn, contains('2–5%'));
        });

        test('Carbapenem allergy -> Cephalosporin prescribed: flags ~1% cross-reactivity alert', () {
          final alerts = AllergyService.evaluateAllergies(
            patientAllergies: ['Meropenem'],
            drugGenericName: 'Ceftriaxone',
            drugId: 'ceftriaxone',
            drugClass: DrugClass.betaLactamCephalosporin,
            legacyAllergyClass: 'Cephalosporin',
          );
          expect(alerts, isNotEmpty);
          final cross = alerts.firstWhere((a) => a.hasCrossReactivity);
          expect(cross.severity, equals(LimitSeverity.soft));
          expect(cross.hasDirectMatch, isFalse);
          expect(cross.messageEn, contains('carbapenem allergy'));
          expect(cross.messageEn, contains('1%'));
        });

        test('Carbapenem allergy -> Penicillin prescribed: flags ~1% cross-reactivity alert', () {
          final alerts = AllergyService.evaluateAllergies(
            patientAllergies: ['Meropenem'],
            drugGenericName: 'Ampicillin',
            drugId: 'ampicillin',
            drugClass: DrugClass.betaLactamPenicillin,
            legacyAllergyClass: 'Penicillin',
          );
          expect(alerts, isNotEmpty);
          final cross = alerts.firstWhere((a) => a.hasCrossReactivity);
          expect(cross.severity, equals(LimitSeverity.soft));
          expect(cross.messageEn, contains('carbapenem allergy'));
        });

        test('Penicillin allergy -> Cephalosporin prescribed: flags 2–5% cross-reactivity alert', () {
          final alerts = AllergyService.evaluateAllergies(
            patientAllergies: ['Amoxicillin'],
            drugGenericName: 'Cefazolin',
            drugId: 'cefazolin',
            drugClass: DrugClass.betaLactamCephalosporin,
            legacyAllergyClass: 'Cephalosporin',
          );
          expect(alerts, isNotEmpty);
          final cross = alerts.firstWhere((a) => a.hasCrossReactivity);
          expect(cross.severity, equals(LimitSeverity.soft));
          expect(cross.messageEn, contains('penicillin allergy'));
        });

        test('Penicillin allergy -> Carbapenem prescribed: flags ~1% cross-reactivity alert', () {
          final alerts = AllergyService.evaluateAllergies(
            patientAllergies: ['Penicillin'],
            drugGenericName: 'Meropenem',
            drugId: 'meropenem',
            drugClass: DrugClass.betaLactamCarbapenem,
            legacyAllergyClass: 'Carbapenem',
          );
          expect(alerts, isNotEmpty);
          final cross = alerts.firstWhere((a) => a.hasCrossReactivity);
          expect(cross.severity, equals(LimitSeverity.soft));
          expect(cross.messageEn, contains('penicillin allergy'));
        });

        test('Direct molecule match (Amoxicillin allergy -> Amoxicillin prescribed) triggers HARD contraindication', () {
          final alerts = AllergyService.evaluateAllergies(
            patientAllergies: ['Amoxicillin 500mg'],
            drugGenericName: 'Amoxicillin',
            drugId: 'amoxicillin',
            drugClass: DrugClass.betaLactamPenicillin,
            legacyAllergyClass: 'Penicillin',
          );
          expect(alerts, isNotEmpty);
          final direct = alerts.firstWhere((a) => a.hasDirectMatch);
          expect(direct.severity, equals(LimitSeverity.hard));
          expect(direct.messageEn, contains('DIRECT ALLERGY CONTRAINDICATION'));
        });

        test('Negative controls: Penicillin allergy does NOT trigger alerts for non-beta-lactams', () {
          final nonBetaLactams = [
            {'name': 'Ciprofloxacin', 'id': 'ciprofloxacin', 'class': DrugClass.fluoroquinolone},
            {'name': 'Gentamicin', 'id': 'gentamicin', 'class': DrugClass.aminoglycoside},
            {'name': 'Vancomycin', 'id': 'vancomycin', 'class': DrugClass.glycopeptide},
          ];

          for (final drug in nonBetaLactams) {
            final alerts = AllergyService.evaluateAllergies(
              patientAllergies: ['Penicillin'],
              drugGenericName: drug['name'] as String,
              drugId: drug['id'] as String,
              drugClass: drug['class'] as DrugClass,
              legacyAllergyClass: null,
            );
            expect(alerts, isEmpty, reason: 'Penicillin should not cross-react with ${drug['name']}');
          }
        });
      });

      group('3.2 Statin + Macrolide DDI specificity', () {
        const rosuva = Drug(
          id: 'rosuvastatin',
          genericName: 'Rosuvastatin',
          category: DrugCategory.cardiovascular,
          drugClass: DrugClass.statin,
          regimens: [],
        );
        const simva = Drug(
          id: 'simvastatin',
          genericName: 'Simvastatin',
          category: DrugCategory.cardiovascular,
          drugClass: DrugClass.statin,
          regimens: [],
        );
        const atorva = Drug(
          id: 'atorvastatin',
          genericName: 'Atorvastatin',
          category: DrugCategory.cardiovascular,
          drugClass: DrugClass.statin,
          regimens: [],
        );
        const azithro = Drug(
          id: 'azithromycin',
          genericName: 'Azithromycin',
          category: DrugCategory.antibiotic,
          drugClass: DrugClass.macrolide,
          regimens: [],
        );
        const clarithro = Drug(
          id: 'clarithromycin',
          genericName: 'Clarithromycin',
          category: DrugCategory.antibiotic,
          drugClass: DrugClass.macrolide,
          regimens: [],
        );
        const erythro = Drug(
          id: 'erythromycin',
          genericName: 'Erythromycin',
          category: DrugCategory.antibiotic,
          drugClass: DrugClass.macrolide,
          regimens: [],
        );

        test('Azithromycin + Rosuvastatin does NOT produce false hard contraindication', () {
          final warnings = ClinicalInteractionRegistry.checkInteractions(rosuva, azithro);
          expect(warnings, isEmpty);

          final reverseWarnings = ClinicalInteractionRegistry.checkInteractions(azithro, rosuva);
          expect(reverseWarnings, isEmpty);
        });

        test('Azithromycin + Atorvastatin does NOT produce false hard contraindication', () {
          final warnings = ClinicalInteractionRegistry.checkInteractions(atorva, azithro);
          expect(warnings, isEmpty);
        });

        test('Clarithromycin + Simvastatin DOES produce hard contraindication', () {
          final warnings = ClinicalInteractionRegistry.checkInteractions(simva, clarithro);
          expect(warnings, isNotEmpty);
          final ddi = warnings.firstWhere((w) => w.code == DoseWarningCode.severeInteractionAlert);
          expect(ddi.severity, equals(LimitSeverity.hard));
          expect(ddi.messageEn, contains('strongly inhibits CYP3A4'));
          expect(ddi.messageEn, contains('rhabdomyolysis'));
        });

        test('Erythromycin + Atorvastatin DOES produce hard contraindication', () {
          final warnings = ClinicalInteractionRegistry.checkInteractions(atorva, erythro);
          expect(warnings, isNotEmpty);
          final ddi = warnings.firstWhere((w) => w.code == DoseWarningCode.severeInteractionAlert);
          expect(ddi.severity, equals(LimitSeverity.hard));
          expect(ddi.messageEn, contains('rhabdomyolysis'));
        });
      });

      group('3.3 New therapeutic duplications', () {
        test('Dual Sulfonylureas (Glipizide + Glibenclamide) triggers hard therapeutic duplication', () {
          const drugA = Drug(
            id: 'glipizide',
            genericName: 'Glipizide',
            category: DrugCategory.endocrine,
            drugClass: DrugClass.sulfonylurea,
            regimens: [],
          );
          const drugB = Drug(
            id: 'glibenclamide',
            genericName: 'Glibenclamide',
            category: DrugCategory.endocrine,
            drugClass: DrugClass.sulfonylurea,
            regimens: [],
          );
          final warning = TherapeuticDuplicationService.checkDuplication(drugA, drugB);
          expect(warning, isNotNull);
          expect(warning!.severity, equals(LimitSeverity.hard));
          expect(warning.messageEn, contains('sulfonylureas'));
          expect(warning.messageEn, contains('hypoglycemia'));
        });

        test('Dual DPP-4 inhibitors (Sitagliptin + Linagliptin) triggers hard therapeutic duplication', () {
          const drugA = Drug(
            id: 'sitagliptin',
            genericName: 'Sitagliptin',
            category: DrugCategory.endocrine,
            drugClass: DrugClass.dpp4Inhibitor,
            regimens: [],
          );
          const drugB = Drug(
            id: 'linagliptin',
            genericName: 'Linagliptin',
            category: DrugCategory.endocrine,
            drugClass: DrugClass.dpp4Inhibitor,
            regimens: [],
          );
          final warning = TherapeuticDuplicationService.checkDuplication(drugA, drugB);
          expect(warning, isNotNull);
          expect(warning!.severity, equals(LimitSeverity.hard));
          expect(warning.messageEn, contains('DPP-4 inhibitors'));
        });

        test('Dual SGLT2 inhibitors (Empagliflozin + Dapagliflozin) triggers hard therapeutic duplication', () {
          const drugA = Drug(
            id: 'empagliflozin',
            genericName: 'Empagliflozin',
            category: DrugCategory.endocrine,
            drugClass: DrugClass.sglt2Inhibitor,
            regimens: [],
          );
          const drugB = Drug(
            id: 'dapagliflozin',
            genericName: 'Dapagliflozin',
            category: DrugCategory.endocrine,
            drugClass: DrugClass.sglt2Inhibitor,
            regimens: [],
          );
          final warning = TherapeuticDuplicationService.checkDuplication(drugA, drugB);
          expect(warning, isNotNull);
          expect(warning!.severity, equals(LimitSeverity.hard));
          expect(warning.messageEn, contains('SGLT2 inhibitors'));
          expect(warning.messageEn, contains('euglycemic DKA'));
        });

        test('Dual Thiazides (Hydrochlorothiazide + Indapamide) triggers hard therapeutic duplication', () {
          const drugA = Drug(
            id: 'hydrochlorothiazide',
            genericName: 'Hydrochlorothiazide',
            category: DrugCategory.cardiovascular,
            drugClass: DrugClass.thiazideDiuretic,
            regimens: [],
          );
          const drugB = Drug(
            id: 'indapamide',
            genericName: 'Indapamide',
            category: DrugCategory.cardiovascular,
            drugClass: DrugClass.thiazideDiuretic,
            regimens: [],
          );
          final warning = TherapeuticDuplicationService.checkDuplication(drugA, drugB);
          expect(warning, isNotNull);
          expect(warning!.severity, equals(LimitSeverity.hard));
          expect(warning.messageEn, contains('thiazide diuretics'));
          expect(warning.messageEn, contains('electrolyte wasting'));
        });
      });

      group('3.4 Major interactions registry expansions', () {
        test('Anticoagulant + NSAID triggers hard major GI bleeding interaction', () {
          const warfarin = Drug(
            id: 'warfarin',
            genericName: 'Warfarin',
            category: DrugCategory.cardiovascular,
            drugClass: DrugClass.anticoagulantVka,
            regimens: [],
          );
          const ibuprofen = Drug(
            id: 'ibuprofen',
            genericName: 'Ibuprofen',
            category: DrugCategory.analgesic,
            drugClass: DrugClass.nsaid,
            regimens: [],
          );
          final warnings = ClinicalInteractionRegistry.checkInteractions(warfarin, ibuprofen);
          expect(warnings, isNotEmpty);
          expect(warnings.first.severity, equals(LimitSeverity.hard));
          expect(warnings.first.messageEn, contains('gastrointestinal ulceration and major hemorrhage'));
        });

        test('Spironolactone + Potassium Chloride triggers hard fatal hyperkalemia contraindication', () {
          const spiro = Drug(
            id: 'spironolactone',
            genericName: 'Spironolactone',
            category: DrugCategory.cardiovascular,
            drugClass: DrugClass.potassiumSparingDiuretic,
            regimens: [],
          );
          const kcl = Drug(
            id: 'potassium_chloride',
            genericName: 'Potassium Chloride',
            category: DrugCategory.cardiovascular,
            regimens: [],
          );
          final warnings = ClinicalInteractionRegistry.checkInteractions(spiro, kcl);
          expect(warnings, isNotEmpty);
          expect(warnings.first.severity, equals(LimitSeverity.hard));
          expect(warnings.first.messageEn, contains('fatal hyperkalemia'));
        });

        test('Lithium + NSAID / ACEI / ARB triggers hard lithium toxicity warning', () {
          const lithium = Drug(
            id: 'lithium',
            genericName: 'Lithium',
            category: DrugCategory.psychiatric,
            regimens: [],
          );
          const enalapril = Drug(
            id: 'enalapril',
            genericName: 'Enalapril',
            category: DrugCategory.cardiovascular,
            drugClass: DrugClass.aceInhibitor,
            regimens: [],
          );
          final warnings = ClinicalInteractionRegistry.checkInteractions(lithium, enalapril);
          expect(warnings, isNotEmpty);
          expect(warnings.first.severity, equals(LimitSeverity.hard));
          expect(warnings.first.messageEn, contains('lithium toxicity'));
        });
      });
    });
  });
}
