// ============================================================
// IV Rate Calculator & RateUnit.mcgMin Test Suite
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/calculators/iv_rate_calculator.dart';
import 'package:drug_dosage_calculator/core/models/drug.dart';

void main() {
  group('IvRateCalculator & RateUnit Unit Test Suite', () {
    group('RateUnit.mcgMin and RateUnit.uMin resolution and conversion', () {
      test('RateUnit.tryFromSymbol resolves mcg/min variations', () {
        expect(RateUnit.tryFromSymbol('mcg/min'), RateUnit.mcgMin);
        expect(RateUnit.tryFromSymbol('mcg/minute'), RateUnit.mcgMin);
        expect(RateUnit.tryFromSymbol('mcgmin'), RateUnit.mcgMin);
        expect(RateUnit.tryFromSymbol('MCG/MIN'), RateUnit.mcgMin);
      });

      test('RateUnit.tryFromSymbol resolves units/min variations', () {
        expect(RateUnit.tryFromSymbol('units/min'), RateUnit.uMin);
        expect(RateUnit.tryFromSymbol('unit/min'), RateUnit.uMin);
        expect(RateUnit.tryFromSymbol('u/min'), RateUnit.uMin);
        expect(RateUnit.tryFromSymbol('umin'), RateUnit.uMin);
      });

      test('RateUnit.toAmountPerHour converts mcg/min to mg/hr correctly', () {
        // 10 mcg/min * 60 min/hr = 600 mcg/hr = 0.6 mg/hr (weight independent)
        final mgHr = RateUnit.mcgMin.toAmountPerHour(10.0, 70.0);
        expect(mgHr, closeTo(0.6, 1e-9));

        final mgHrNoWeight = RateUnit.mcgMin.toAmountPerHour(10.0, 0.0);
        expect(mgHrNoWeight, closeTo(0.6, 1e-9));
      });

      test('RateUnit.toAmountPerHour converts units/min to units/hr correctly', () {
        // 0.03 units/min * 60 min/hr = 1.8 units/hr
        final uHr = RateUnit.uMin.toAmountPerHour(0.03, 70.0);
        expect(uHr, closeTo(1.8, 1e-9));
      });
    });

    group('calculateInfusionMlPerHour with mcgMin and uMin', () {
      test('mcg/min infusion calculation with mcg/mL concentration', () {
        // 16 mcg/min with 16 mcg/mL concentration -> 60 mL/hr
        final mlHr = IvRateCalculator.calculateInfusionMlPerHour(
          doseRatePerMin: 16.0,
          doseRateUnit: RateUnit.mcgMin,
          concentration: const Concentration(16.0, ConcentrationUnit.mcgPerMl),
        );
        expect(mlHr, closeTo(60.0, 1e-9));
      });

      test('mcg/min infusion calculation with mg/mL concentration', () {
        // 10 mcg/min = 0.6 mg/hr; conc = 0.016 mg/mL (16 mcg/mL) -> 37.5 mL/hr
        final mlHr = IvRateCalculator.calculateInfusionMlPerHour(
          doseRatePerMin: 10.0,
          doseRateUnit: RateUnit.mcgMin,
          concentration: const Concentration(0.016, ConcentrationUnit.mgPerMl),
        );
        expect(mlHr, closeTo(37.5, 1e-9));
      });

      test('units/min infusion calculation for Vasopressin', () {
        // 0.03 units/min with 0.2 units/mL concentration (20 units/100 mL) -> 9.0 mL/hr
        final mlHr = IvRateCalculator.calculateInfusionMlPerHour(
          doseRatePerMin: 0.03,
          doseRateUnit: RateUnit.uMin,
          concentration: const Concentration(0.2, ConcentrationUnit.unitsPerMl),
        );
        expect(mlHr, closeTo(9.0, 1e-9));
      });

      test('Biological vs mass unit mismatch with uMin throws ArgumentError', () {
        expect(
          () => IvRateCalculator.calculateInfusionMlPerHour(
            doseRatePerMin: 0.03,
            doseRateUnit: RateUnit.uMin,
            concentration: const Concentration(10.0, ConcentrationUnit.mgPerMl),
          ),
          throwsArgumentError,
        );
      });
    });

    group('mcgPerMin and rateMlPerHrFromMcgMin helpers & round-trip', () {
      test('mcgPerMin calculates correctly from pump rate', () {
        // Conc = 16 mcg/mL, Rate = 60 mL/hr -> (16 * 60) / 60 = 16 mcg/min
        final dose = IvRateCalculator.mcgPerMin(
          concentrationMcgPerMl: 16.0,
          rateMlPerHr: 60.0,
        );
        expect(dose, closeTo(16.0, 1e-9));
      });

      test('rateMlPerHrFromMcgMin calculates pump rate correctly', () {
        // Desired = 16 mcg/min, Conc = 16 mcg/mL -> (16 * 60) / 16 = 60 mL/hr
        final rate = IvRateCalculator.rateMlPerHrFromMcgMin(
          desiredMcgMin: 16.0,
          concentrationMcgPerMl: 16.0,
        );
        expect(rate, closeTo(60.0, 1e-9));
      });

      test('Round-trip identity: rate -> dose -> rate', () {
        const conc = 32.0; // Double strength
        const originalRate = 45.0; // mL/hr
        final dose = IvRateCalculator.mcgPerMin(
          concentrationMcgPerMl: conc,
          rateMlPerHr: originalRate,
        );
        final calculatedRate = IvRateCalculator.rateMlPerHrFromMcgMin(
          desiredMcgMin: dose,
          concentrationMcgPerMl: conc,
        );
        expect(calculatedRate, closeTo(originalRate, 1e-9));
      });

      test('Invalid inputs throw ArgumentError', () {
        expect(
          () => IvRateCalculator.mcgPerMin(
            concentrationMcgPerMl: 0.0,
            rateMlPerHr: 10.0,
          ),
          throwsArgumentError,
        );
        expect(
          () => IvRateCalculator.mcgPerMin(
            concentrationMcgPerMl: 16.0,
            rateMlPerHr: -5.0,
          ),
          throwsArgumentError,
        );
        expect(
          () => IvRateCalculator.rateMlPerHrFromMcgMin(
            desiredMcgMin: -1.0,
            concentrationMcgPerMl: 16.0,
          ),
          throwsArgumentError,
        );
      });
    });

    group('unitsPerMin and rateMlPerHrFromUnitsPerMin helpers', () {
      test('Vasopressin 0.03 units/min at 0.2 units/mL gives 9.0 mL/hr and back', () {
        final rate = IvRateCalculator.rateMlPerHrFromUnitsPerMin(
          desiredUnitsPerMin: 0.03,
          concentrationUnitsPerMl: 0.2,
        );
        expect(rate, closeTo(9.0, 1e-9));

        final dose = IvRateCalculator.unitsPerMin(
          concentrationUnitsPerMl: 0.2,
          rateMlPerHr: 9.0,
        );
        expect(dose, closeTo(0.03, 1e-9));
      });
    });
  });
}
