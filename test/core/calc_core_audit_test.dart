import 'package:test/test.dart';
import 'package:drug_dosage_calculator/core/calculators/calculators.dart';
import 'package:drug_dosage_calculator/core/models/models.dart';
import 'package:drug_dosage_calculator/core/validators/input_validator.dart';
import 'package:drug_dosage_calculator/core/formatters/clinical_order_formatter.dart';

void main() {
  group('Calculation Core Robustness & Audit Test Suite', () {
    // -------------------------------------------------------------------------
    // 1. InputValidator Edge Cases & Non-Finite Guards
    // -------------------------------------------------------------------------
    group('InputValidator non-finite & edge cases', () {
      test('validatePatientInputs rejects NaN and Infinity in weightKg, heightCm, and SCr', () {
        final nanWeight = InputValidator.validatePatientInputs(
          weightKg: double.nan,
          heightCm: 170.0,
          ageYears: 45,
        );
        expect(nanWeight.isValid, isFalse);
        expect(nanWeight.errorsEn.containsKey('weightKg'), isTrue);

        final infHeight = InputValidator.validatePatientInputs(
          weightKg: 70.0,
          heightCm: double.infinity,
          ageYears: 45,
        );
        expect(infHeight.isValid, isFalse);
        expect(infHeight.errorsEn.containsKey('heightCm'), isTrue);

        final negInfScr = InputValidator.validatePatientInputs(
          weightKg: 70.0,
          heightCm: 170.0,
          ageYears: 45,
          serumCreatinineMgDl: double.negativeInfinity,
        );
        expect(negInfScr.isValid, isFalse);
        expect(negInfScr.errorsEn.containsKey('serumCreatinineMgDl'), isTrue);
      });

      test('validateDose rejects non-finite and negative doses', () {
        expect(InputValidator.validateDose(dose: null).isValid, isFalse);
        expect(InputValidator.validateDose(dose: -5.0).isValid, isFalse);
        expect(InputValidator.validateDose(dose: double.nan).isValid, isFalse);
        expect(InputValidator.validateDose(dose: double.infinity).isValid, isFalse);
        expect(InputValidator.validateDose(dose: 100.0).isValid, isTrue);
      });

      test('validatePositive rejects non-finite and non-positive numbers', () {
        final nanRes = InputValidator.validatePositive(
          value: double.nan,
          fieldNameEn: 'Rate',
          fieldNameTh: 'อัตราการให้ยา',
        );
        expect(nanRes.isValid, isFalse);
        expect(nanRes.errorsEn['rate'], contains('must be greater than 0'));

        final zeroRes = InputValidator.validatePositive(
          value: 0.0,
          fieldNameEn: 'Volume',
          fieldNameTh: 'ปริมาตร',
        );
        expect(zeroRes.isValid, isFalse);

        final posRes = InputValidator.validatePositive(
          value: 25.0,
          fieldNameEn: 'Volume',
          fieldNameTh: 'ปริมาตร',
        );
        expect(posRes.isValid, isTrue);
      });

      test('validatePatientInputs respects allowNeonatalLowWeight for 0.5 kg ELBW neonate', () {
        final standard = InputValidator.validatePatientInputs(
          weightKg: 0.8,
          heightCm: 35.0,
          ageYears: 0,
          ageMonths: 1,
          allowNeonatalLowWeight: false,
        );
        expect(standard.isValid, isFalse);
        expect(standard.errorsEn['weightKg'], contains('Weight below 1 kg is implausible'));

        final neonatal = InputValidator.validatePatientInputs(
          weightKg: 0.8,
          heightCm: 35.0,
          ageYears: 0,
          ageMonths: 1,
          allowNeonatalLowWeight: true,
        );
        expect(neonatal.isValid, isTrue);
        expect(neonatal.warningsEn['weightKg'], contains('Extreme low birth weight'));
      });
    });

    // -------------------------------------------------------------------------
    // 2. DoseRounder Numerical Stability & Commercial Matching
    // -------------------------------------------------------------------------
    group('DoseRounder numerical stability & commercial matching', () {
      test('Non-finite and non-positive doses return null safely', () {
        expect(DoseRounder.roundToNearestStrength(double.nan, [100.0]), isNull);
        expect(DoseRounder.roundToNearestStrength(double.infinity, [100.0]), isNull);
        expect(DoseRounder.roundToNearestStrength(0.0, [100.0]), isNull);
        expect(DoseRounder.roundToNearestStrength(-10.0, [100.0]), isNull);
      });

      test('Exact commercial strength matching within maxDeviation', () {
        // e.g. calculated 496 mg, available form has strength 500 mg (within 5%)
        final rounded = DoseRounder.roundToNearestStrength(
          496.0,
          [250.0, 500.0],
          isSplittable: true,
          maxDeviation: 0.05,
        );
        expect(rounded, equals(500.0));

        // 98 mg with 100 mg strength
        final rounded100 = DoseRounder.roundToNearestStrength(
          98.0,
          [50.0, 100.0],
          isSplittable: true,
          maxDeviation: 0.05,
        );
        expect(rounded100, equals(100.0));
      });

      test('Liquid injection rounding eliminates floating point IEEE noise', () {
        // Step of 0.02, target 0.060000000000000005
        const noisyDose = 0.05 + 0.010000000000000002;
        final rounded = DoseRounder.roundToNearestStrength(
          noisyDose,
          [0.02],
          isSplittable: false,
          maxDeviation: 0.05,
        );
        expect(rounded, equals(0.06));
      });
    });

    // -------------------------------------------------------------------------
    // 3. WeightBasedCalculator Edge Cases & Guards
    // -------------------------------------------------------------------------
    group('WeightBasedCalculator short stature & AdjBW clamping', () {
      test('IBW calculation handles short stature height <= 60 inches safely', () {
        // Height 140 cm = 55.12 inches (< 60 inches)
        final ibwFemale = WeightBasedCalculator.idealBodyWeight(
          heightCm: 140.0,
          sex: Sex.female,
        );
        expect(ibwFemale, greaterThanOrEqualTo(10.0));
        expect(ibwFemale.isFinite, isTrue);

        // Very short height (100 cm) clamps at 10.0 kg minimum
        final ibwClamped = WeightBasedCalculator.idealBodyWeight(
          heightCm: 100.0,
          sex: Sex.male,
        );
        expect(ibwClamped, equals(10.0));
      });

      test('AdjustedBodyWeight clamps to actual weight when actual <= IBW', () {
        // Patient weighs 40 kg, but IBW is 60 kg (underweight/cachectic)
        final adjBw = WeightBasedCalculator.adjustedBodyWeight(
          actualWeightKg: 40.0,
          ibwKg: 60.0,
        );
        // Should NOT subtract below actual weight; returns actual weight
        expect(adjBw, equals(40.0));
      });

      test('Non-finite inputs throw ArgumentError in WeightBasedCalculator', () {
        expect(
          () => WeightBasedCalculator.calculateDose(
            weightKg: double.nan,
            dosePerKg: 10.0,
          ),
          throwsArgumentError,
        );

        expect(
          () => WeightBasedCalculator.calculateBsaDose(
            bsaM2: double.infinity,
            dosePerM2: 50.0,
          ),
          throwsArgumentError,
        );

        expect(
          () => WeightBasedCalculator.calvertFormula(
            targetAuc: 5.0,
            gfrMlMin: double.nan,
          ),
          throwsArgumentError,
        );
      });
    });

    // -------------------------------------------------------------------------
    // 4. RenalCalculator Non-Finite Guards
    // -------------------------------------------------------------------------
    group('RenalCalculator non-finite guards', () {
      test('cockcroftGault throws ArgumentError on NaN or infinite parameters', () {
        expect(
          () => RenalCalculator.cockcroftGault(
            ageYears: 50,
            weightKg: double.nan,
            serumCreatinineMgDl: 1.0,
            sex: Sex.male,
          ),
          throwsArgumentError,
        );

        expect(
          () => RenalCalculator.cockcroftGault(
            ageYears: 50,
            weightKg: 70.0,
            serumCreatinineMgDl: double.infinity,
            sex: Sex.male,
          ),
          throwsArgumentError,
        );
      });

      test('bedsideSchwartz throws ArgumentError on non-finite parameters', () {
        expect(
          () => RenalCalculator.bedsideSchwartz(
            heightCm: double.nan,
            serumCreatinineMgDl: 0.5,
          ),
          throwsArgumentError,
        );
      });

      test('ckdEpi2021 throws ArgumentError on non-finite parameters', () {
        expect(
          () => RenalCalculator.ckdEpi2021(
            ageYears: 55,
            serumCreatinineMgDl: double.nan,
            sex: Sex.female,
          ),
          throwsArgumentError,
        );
      });
    });

    // -------------------------------------------------------------------------
    // 5. BsaCalculator Non-Finite Guards
    // -------------------------------------------------------------------------
    group('BsaCalculator non-finite guards', () {
      test('All BSA formulas throw ArgumentError on NaN or infinite inputs', () {
        expect(
          () => BsaCalculator.mosteller(heightCm: double.nan, weightKg: 70.0),
          throwsArgumentError,
        );
        expect(
          () => BsaCalculator.dubois(heightCm: 170.0, weightKg: double.infinity),
          throwsArgumentError,
        );
        expect(
          () => BsaCalculator.haycock(heightCm: double.negativeInfinity, weightKg: 10.0),
          throwsArgumentError,
        );
      });
    });

    // -------------------------------------------------------------------------
    // 6. IvRateCalculator Non-Finite & Weight Guards
    // -------------------------------------------------------------------------
    group('IvRateCalculator unit and weight validation', () {
      test('calculateInfusionMlPerHour throws when weight-based unit is called without positive finite weight', () {
        expect(
          () => IvRateCalculator.calculateInfusionMlPerHour(
            doseRatePerMin: 5.0,
            doseRateUnit: RateUnit.mcgKgMin,
            concentration: const Concentration(1.6, ConcentrationUnit.mgPerMl),
            weightKg: null,
          ),
          throwsArgumentError,
        );

        expect(
          () => IvRateCalculator.calculateInfusionMlPerHour(
            doseRatePerMin: 5.0,
            doseRateUnit: RateUnit.mcgKgMin,
            concentration: const Concentration(1.6, ConcentrationUnit.mgPerMl),
            weightKg: 0.0,
          ),
          throwsArgumentError,
        );

        expect(
          () => IvRateCalculator.calculateInfusionMlPerHour(
            doseRatePerMin: 5.0,
            doseRateUnit: RateUnit.mcgKgMin,
            concentration: const Concentration(1.6, ConcentrationUnit.mgPerMl),
            weightKg: double.nan,
          ),
          throwsArgumentError,
        );
      });

      test('calculateInfusionMlPerHour calculates accurately when valid weight is provided', () {
        // Dopamine 5 mcg/kg/min for 70 kg patient = 350 mcg/min = 21,000 mcg/hr = 21 mg/hr
        // Concentration: 400 mg in 250 mL = 1.6 mg/mL
        // Rate: 21 mg/hr / 1.6 mg/mL = 13.125 mL/hr
        final rate = IvRateCalculator.calculateInfusionMlPerHour(
          doseRatePerMin: 5.0,
          doseRateUnit: RateUnit.mcgKgMin,
          concentration: const Concentration(1.6, ConcentrationUnit.mgPerMl),
          weightKg: 70.0,
        );
        expect(rate, closeTo(13.125, 0.001));
      });

      test('infusionRateMlPerHr and dripRateDropsPerMin throw on non-finite inputs', () {
        expect(
          () => IvRateCalculator.infusionRateMlPerHr(
            volumeMl: double.nan,
            timeMinutes: 60.0,
          ),
          throwsArgumentError,
        );

        expect(
          () => IvRateCalculator.dripRateDropsPerMin(
            volumeMl: double.infinity,
            timeMinutes: 60.0,
          ),
          throwsArgumentError,
        );
      });
    });

    // -------------------------------------------------------------------------
    // 7. UnitConverter & Frequency Enhanced Parsing
    // -------------------------------------------------------------------------
    group('UnitConverter and Frequency parsing extensions', () {
      test('dosesPerDay parses regex variations with hour suffixes', () {
        expect(UnitConverter.dosesPerDay('q8hr'), equals(3));
        expect(UnitConverter.dosesPerDay('q8hrs'), equals(3));
        expect(UnitConverter.dosesPerDay('every 8 hours'), equals(3));
        expect(UnitConverter.dosesPerDay('every 12 hrs'), equals(2));
      });

      test('dosesPerDay parses Thai interval strings', () {
        expect(UnitConverter.dosesPerDay('ทุก 8 ชม.'), equals(3));
        expect(UnitConverter.dosesPerDay('ทุก 12 ชั่วโมง'), equals(2));
        expect(UnitConverter.dosesPerDay('วันละ 2 ครั้ง'), equals(2));
        expect(UnitConverter.dosesPerDay('วันละ 3 ครั้ง'), equals(3));
        expect(UnitConverter.dosesPerDay('ครั้งเดียว'), equals(1));
      });

      test('Frequency.fromLegacyString handles hour suffixes and Thai intervals', () {
        final f1 = Frequency.fromLegacyString('q8hrs');
        expect(f1.dosesPerDay, equals(3));
        expect(f1.intervalHours, equals(8));

        final f2 = Frequency.fromLegacyString('ทุก 8 ชม.');
        expect(f2.dosesPerDay, equals(3));
        expect(f2.intervalHours, equals(8));

        final f3 = Frequency.fromLegacyString('วันละ 2 ครั้ง');
        expect(f3.dosesPerDay, equals(2));
      });
    });

    // -------------------------------------------------------------------------
    // 8. ClinicalOrderFormatter Robustness
    // -------------------------------------------------------------------------
    group('ClinicalOrderFormatter robustness', () {
      test('formatHisOrder handles non-finite calculation gracefully', () {
        const calculation = DosageResult(
          success: true,
          calculatedDose: double.nan,
          roundedDose: double.nan,
          doseUnit: DoseUnit.mg,
          frequency: 'q8h',
          structuredFrequency: Frequency.q8h,
          formulaUsed: 'Test Formula',
        );

        const drug = Drug(
          id: 'test_pcm',
          genericName: 'Paracetamol',
          category: DrugCategory.analgesic,
          regimens: [
            DosingRegimen(
              route: DoseRoute.po,
              indication: 'Pain',
              dosingType: DosingType.fixed,
              fixedDose: 500.0,
              doseUnit: DoseUnit.mg,
              frequency: Frequency.q8h,
            ),
          ],
        );

        const patient = Patient(
          id: 'p1',
          weightKg: 70.0,
          heightCm: 175.0,
          ageYears: 40,
          sex: Sex.male,
          isScrStable: true,
        );

        final order = ClinicalOrderFormatter.formatHisOrder(
          result: calculation,
          patient: patient,
          drug: drug,
          regimen: drug.regimens.first,
        );

        expect(order, contains('Paracetamol'));
        expect(order, contains('NaN'));
      });
    });
  });
}
