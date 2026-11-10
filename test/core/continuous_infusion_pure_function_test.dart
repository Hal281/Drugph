// ============================================================
// CONTINUOUS INFUSION PURE FUNCTION VERIFICATION SUITE
// ============================================================
// Validates 100% mathematical exactness, pure function determinism,
// invertibility, and edge-case boundary guards for IvRateCalculator.
// References: Lexicomp 2024, Sanford Guide 2024, AHA ACLS 2020.
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/calculators/iv_rate_calculator.dart';
import 'package:drug_dosage_calculator/core/models/models.dart';

void main() {
  group('IvRateCalculator Pure Function Suite', () {
    // -----------------------------------------------------------------------
    // 1. calculateInfusionMlPerHour
    // -----------------------------------------------------------------------
    group('1. calculateInfusionMlPerHour exactness & unit compatibility', () {
      test('1.1: mcg/kg/min (Epinephrine 0.1 mcg/kg/min, 70 kg, 16 mcg/mL) -> 26.25 mL/hr', () {
        final rate = IvRateCalculator.calculateInfusionMlPerHour(
          doseRatePerMin: 0.1,
          doseRateUnit: RateUnit.mcgKgMin,
          concentration: const Concentration(16.0, ConcentrationUnit.mcgPerMl),
          weightKg: 70.0,
        );
        expect(rate, closeTo(26.25, 0.001));
      });

      test('1.2: mcg/kg/min (Norepinephrine 0.05 mcg/kg/min, 80 kg, 32 mcg/mL) -> 7.5 mL/hr', () {
        final rate = IvRateCalculator.calculateInfusionMlPerHour(
          doseRatePerMin: 0.05,
          doseRateUnit: RateUnit.mcgKgMin,
          concentration: const Concentration(32.0, ConcentrationUnit.mcgPerMl),
          weightKg: 80.0,
        );
        expect(rate, closeTo(7.5, 0.001));
      });

      test('1.3: mcg/kg/min (Dopamine 5 mcg/kg/min, 70 kg, 1.6 mg/mL) -> 13.125 mL/hr', () {
        final rate = IvRateCalculator.calculateInfusionMlPerHour(
          doseRatePerMin: 5.0,
          doseRateUnit: RateUnit.mcgKgMin,
          concentration: const Concentration(1.6, ConcentrationUnit.mgPerMl),
          weightKg: 70.0,
        );
        expect(rate, closeTo(13.125, 0.001));
      });

      test('1.4: mg/hr (Nicardipine 5.0 mg/hr, 0.1 mg/mL) -> 50.0 mL/hr', () {
        final rate = IvRateCalculator.calculateInfusionMlPerHour(
          doseRatePerMin: 5.0,
          doseRateUnit: RateUnit.mgHr,
          concentration: const Concentration(0.1, ConcentrationUnit.mgPerMl),
        );
        expect(rate, closeTo(50.0, 0.001));
      });

      test('1.5: g/hr (Magnesium Sulfate 2.0 g/hr, 40 mg/mL) -> 50.0 mL/hr', () {
        final rate = IvRateCalculator.calculateInfusionMlPerHour(
          doseRatePerMin: 2.0,
          doseRateUnit: RateUnit.gHr,
          concentration: const Concentration(40.0, ConcentrationUnit.mgPerMl),
        );
        expect(rate, closeTo(50.0, 0.001));
      });

      test('1.6: units/kg/hr (Heparin 18 units/kg/hr, 70 kg, 100 units/mL) -> 12.6 mL/hr', () {
        final rate = IvRateCalculator.calculateInfusionMlPerHour(
          doseRatePerMin: 18.0,
          doseRateUnit: RateUnit.uKgHr,
          concentration: const Concentration(100.0, ConcentrationUnit.unitsPerMl),
          weightKg: 70.0,
        );
        expect(rate, closeTo(12.6, 0.001));
      });

      test('1.7: units/hr (Regular Insulin 5 units/hr, 1 unit/mL) -> 5.0 mL/hr', () {
        final rate = IvRateCalculator.calculateInfusionMlPerHour(
          doseRatePerMin: 5.0,
          doseRateUnit: RateUnit.uHr,
          concentration: const Concentration(1.0, ConcentrationUnit.unitsPerMl),
        );
        expect(rate, closeTo(5.0, 0.001));
      });

      test('1.8: mU/min (Oxytocin 2 mU/min, 10 mU/mL) -> 12.0 mL/hr', () {
        final rate = IvRateCalculator.calculateInfusionMlPerHour(
          doseRatePerMin: 2.0,
          doseRateUnit: RateUnit.mUMin,
          concentration: const Concentration(10.0, ConcentrationUnit.mUPerMl),
        );
        expect(rate, closeTo(12.0, 0.001));
      });

      test('1.9: zero rate returns 0.0 mL/hr', () {
        final rate = IvRateCalculator.calculateInfusionMlPerHour(
          doseRatePerMin: 0.0,
          doseRateUnit: RateUnit.mcgKgMin,
          concentration: const Concentration(16.0, ConcentrationUnit.mcgPerMl),
          weightKg: 70.0,
        );
        expect(rate, equals(0.0));
      });

      test('1.10: RateUnit.mlHr throws ArgumentError (cannot convert volume rate to amount)', () {
        expect(
          () => IvRateCalculator.calculateInfusionMlPerHour(
            doseRatePerMin: 50.0,
            doseRateUnit: RateUnit.mlHr,
            concentration: const Concentration(10.0, ConcentrationUnit.mgPerMl),
          ),
          throwsArgumentError,
        );
      });

      test('1.11: Biological vs mass unit mismatch throws ArgumentError', () {
        expect(
          () => IvRateCalculator.calculateInfusionMlPerHour(
            doseRatePerMin: 5.0,
            doseRateUnit: RateUnit.uHr,
            concentration: const Concentration(1.0, ConcentrationUnit.mgPerMl),
          ),
          throwsArgumentError,
        );
        expect(
          () => IvRateCalculator.calculateInfusionMlPerHour(
            doseRatePerMin: 5.0,
            doseRateUnit: RateUnit.mgHr,
            concentration: const Concentration(100.0, ConcentrationUnit.unitsPerMl),
          ),
          throwsArgumentError,
        );
      });

      test('1.12: Missing or invalid weight for weight-based units throws ArgumentError', () {
        expect(
          () => IvRateCalculator.calculateInfusionMlPerHour(
            doseRatePerMin: 0.1,
            doseRateUnit: RateUnit.mcgKgMin,
            concentration: const Concentration(16.0, ConcentrationUnit.mcgPerMl),
            weightKg: null,
          ),
          throwsArgumentError,
        );
        expect(
          () => IvRateCalculator.calculateInfusionMlPerHour(
            doseRatePerMin: 0.1,
            doseRateUnit: RateUnit.mcgKgMin,
            concentration: const Concentration(16.0, ConcentrationUnit.mcgPerMl),
            weightKg: 0.0,
          ),
          throwsArgumentError,
        );
        expect(
          () => IvRateCalculator.calculateInfusionMlPerHour(
            doseRatePerMin: 0.1,
            doseRateUnit: RateUnit.mcgKgMin,
            concentration: const Concentration(16.0, ConcentrationUnit.mcgPerMl),
            weightKg: -70.0,
          ),
          throwsArgumentError,
        );
      });

      test('1.13: Non-finite or negative dose rate and concentration throw ArgumentError', () {
        expect(
          () => IvRateCalculator.calculateInfusionMlPerHour(
            doseRatePerMin: -1.0,
            doseRateUnit: RateUnit.mgHr,
            concentration: const Concentration(1.0, ConcentrationUnit.mgPerMl),
          ),
          throwsArgumentError,
        );
        expect(
          () => IvRateCalculator.calculateInfusionMlPerHour(
            doseRatePerMin: double.nan,
            doseRateUnit: RateUnit.mgHr,
            concentration: const Concentration(1.0, ConcentrationUnit.mgPerMl),
          ),
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
        expect(
          () => IvRateCalculator.calculateInfusionMlPerHour(
            doseRatePerMin: 5.0,
            doseRateUnit: RateUnit.mgHr,
            concentration: const Concentration(double.infinity, ConcentrationUnit.mgPerMl),
          ),
          throwsArgumentError,
        );
      });
    });

    // -----------------------------------------------------------------------
    // 2. mcgPerKgPerMin and rateMlPerHrFromMcgKgMin Invertibility
    // -----------------------------------------------------------------------
    group('2. mcgPerKgPerMin <-> rateMlPerHrFromMcgKgMin exactness & round-trip', () {
      test('2.1: Epinephrine (16 mcg/mL, 70 kg): 0.1 mcg/kg/min -> 26.25 mL/hr and back', () {
        const conc = 16.0;
        const wt = 70.0;
        const desired = 0.10;
        final mlHr = IvRateCalculator.rateMlPerHrFromMcgKgMin(
          desiredMcgKgMin: desired,
          weightKg: wt,
          concentrationMcgPerMl: conc,
        );
        expect(mlHr, closeTo(26.25, 0.001));

        final backDose = IvRateCalculator.mcgPerKgPerMin(
          concentrationMcgPerMl: conc,
          rateMlPerHr: mlHr,
          weightKg: wt,
        );
        expect(backDose, closeTo(desired, 1e-9));
      });

      test('2.2: Norepinephrine (32 mcg/mL, 80 kg): 0.05 mcg/kg/min -> 7.5 mL/hr and back', () {
        const conc = 32.0;
        const wt = 80.0;
        const desired = 0.05;
        final mlHr = IvRateCalculator.rateMlPerHrFromMcgKgMin(
          desiredMcgKgMin: desired,
          weightKg: wt,
          concentrationMcgPerMl: conc,
        );
        expect(mlHr, closeTo(7.5, 0.001));

        final backDose = IvRateCalculator.mcgPerKgPerMin(
          concentrationMcgPerMl: conc,
          rateMlPerHr: mlHr,
          weightKg: wt,
        );
        expect(backDose, closeTo(desired, 1e-9));
      });

      test('2.3: Dobutamine (1000 mcg/mL, 60 kg): 5.0 mcg/kg/min -> 18.0 mL/hr and back', () {
        const conc = 1000.0;
        const wt = 60.0;
        const desired = 5.0;
        final mlHr = IvRateCalculator.rateMlPerHrFromMcgKgMin(
          desiredMcgKgMin: desired,
          weightKg: wt,
          concentrationMcgPerMl: conc,
        );
        expect(mlHr, closeTo(18.0, 0.001));

        final backDose = IvRateCalculator.mcgPerKgPerMin(
          concentrationMcgPerMl: conc,
          rateMlPerHr: mlHr,
          weightKg: wt,
        );
        expect(backDose, closeTo(desired, 1e-9));
      });

      test('2.4: Extreme neonate weight (0.8 kg) with Epinephrine 16 mcg/mL', () {
        const conc = 16.0;
        const wt = 0.8;
        const desired = 0.1;
        // (0.1 * 0.8 * 60) / 16 = 4.8 / 16 = 0.3 mL/hr
        final mlHr = IvRateCalculator.rateMlPerHrFromMcgKgMin(
          desiredMcgKgMin: desired,
          weightKg: wt,
          concentrationMcgPerMl: conc,
        );
        expect(mlHr, closeTo(0.3, 0.001));

        final backDose = IvRateCalculator.mcgPerKgPerMin(
          concentrationMcgPerMl: conc,
          rateMlPerHr: mlHr,
          weightKg: wt,
        );
        expect(backDose, closeTo(desired, 1e-9));
      });

      test('2.5: Zero dose rate returns 0.0 mL/hr and vice versa', () {
        final mlHr = IvRateCalculator.rateMlPerHrFromMcgKgMin(
          desiredMcgKgMin: 0.0,
          weightKg: 70.0,
          concentrationMcgPerMl: 16.0,
        );
        expect(mlHr, equals(0.0));

        final dose = IvRateCalculator.mcgPerKgPerMin(
          concentrationMcgPerMl: 16.0,
          rateMlPerHr: 0.0,
          weightKg: 70.0,
        );
        expect(dose, equals(0.0));
      });

      test('2.6: Comprehensive round-trip mathematical identity across multiple patient weights and rates', () {
        final weights = [2.5, 10.0, 50.0, 70.0, 100.0, 150.0];
        final rates = [0.01, 0.05, 0.1, 0.5, 1.0, 2.0, 5.0, 10.0, 20.0];
        final concentrations = [16.0, 32.0, 64.0, 1000.0, 1600.0, 3200.0];

        for (final wt in weights) {
          for (final d in rates) {
            for (final c in concentrations) {
              final pump = IvRateCalculator.rateMlPerHrFromMcgKgMin(
                desiredMcgKgMin: d,
                weightKg: wt,
                concentrationMcgPerMl: c,
              );
              final roundTripDose = IvRateCalculator.mcgPerKgPerMin(
                concentrationMcgPerMl: c,
                rateMlPerHr: pump,
                weightKg: wt,
              );
              expect(roundTripDose, closeTo(d, 1e-8));
            }
          }
        }
      });

      test('2.7: Invalid arguments throw ArgumentError', () {
        expect(
          () => IvRateCalculator.rateMlPerHrFromMcgKgMin(
            desiredMcgKgMin: -0.1,
            weightKg: 70.0,
            concentrationMcgPerMl: 16.0,
          ),
          throwsArgumentError,
        );
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
            rateMlPerHr: -1.0,
            weightKg: 70.0,
          ),
          throwsArgumentError,
        );
        expect(
          () => IvRateCalculator.mcgPerKgPerMin(
            concentrationMcgPerMl: 16.0,
            rateMlPerHr: 10.0,
            weightKg: -5.0,
          ),
          throwsArgumentError,
        );
      });
    });

    // -----------------------------------------------------------------------
    // 3. infusionRateMlPerHr & dripRateDropsPerMin
    // -----------------------------------------------------------------------
    group('3. infusionRateMlPerHr & dripRateDropsPerMin gravity calculations', () {
      test('3.1: 1000 mL NSS over 8 hours (480 min) -> 125.0 mL/hr', () {
        final rate = IvRateCalculator.infusionRateMlPerHr(
          volumeMl: 1000.0,
          timeMinutes: 480.0,
        );
        expect(rate, closeTo(125.0, 0.001));
      });

      test('3.2: 100 mL IVPB antibiotic over 30 min -> 200.0 mL/hr', () {
        final rate = IvRateCalculator.infusionRateMlPerHr(
          volumeMl: 100.0,
          timeMinutes: 30.0,
        );
        expect(rate, closeTo(200.0, 0.001));
      });

      test('3.3: dripRateDropsPerMin standard set (20 drops/mL): 1000 mL over 480 min -> 41.67 drops/min', () {
        final drip = IvRateCalculator.dripRateDropsPerMin(
          volumeMl: 1000.0,
          timeMinutes: 480.0,
          dropFactor: 20,
        );
        expect(drip, closeTo(41.6667, 0.001));
      });

      test('3.4: dripRateDropsPerMin micro-drip set (60 drops/mL) equals mL/hr', () {
        final drip = IvRateCalculator.dripRateDropsPerMin(
          volumeMl: 100.0,
          timeMinutes: 60.0,
          dropFactor: 60,
        );
        final pump = IvRateCalculator.infusionRateMlPerHr(
          volumeMl: 100.0,
          timeMinutes: 60.0,
        );
        expect(drip, closeTo(100.0, 0.001));
        expect(drip, equals(pump));
      });

      test('3.5: dripRateDropsPerMin blood set (15 drops/mL): 500 mL over 120 min -> 62.5 drops/min', () {
        final drip = IvRateCalculator.dripRateDropsPerMin(
          volumeMl: 500.0,
          timeMinutes: 120.0,
          dropFactor: 15,
        );
        expect(drip, closeTo(62.5, 0.001));
      });

      test('3.6: Invalid time (<= 0) or volume (< 0) or dropFactor (<= 0) throws ArgumentError', () {
        expect(() => IvRateCalculator.infusionRateMlPerHr(volumeMl: 100, timeMinutes: 0), throwsArgumentError);
        expect(() => IvRateCalculator.infusionRateMlPerHr(volumeMl: -50, timeMinutes: 60), throwsArgumentError);
        expect(() => IvRateCalculator.dripRateDropsPerMin(volumeMl: 100, timeMinutes: 60, dropFactor: 0), throwsArgumentError);
        expect(() => IvRateCalculator.dripRateDropsPerMin(volumeMl: 100, timeMinutes: 60, dropFactor: -20), throwsArgumentError);
      });
    });

    // -----------------------------------------------------------------------
    // 4. volumeForDose, doseRateMgPerHr, rateMlPerHrFromUnits
    // -----------------------------------------------------------------------
    group('4. Ancillary IV rate & volume helpers', () {
      test('4.1: volumeForDose (Furosemide 40 mg, 10 mg/mL) -> 4.0 mL', () {
        expect(IvRateCalculator.volumeForDose(desiredDoseMg: 40.0, concentrationMgPerMl: 10.0), closeTo(4.0, 0.001));
      });

      test('4.2: volumeForDose (Adrenaline 0.3 mg, 1.0 mg/mL) -> 0.3 mL', () {
        expect(IvRateCalculator.volumeForDose(desiredDoseMg: 0.3, concentrationMgPerMl: 1.0), closeTo(0.3, 0.001));
      });

      test('4.3: doseRateMgPerHr (Nicardipine 0.1 mg/mL at 50 mL/hr) -> 5.0 mg/hr', () {
        expect(IvRateCalculator.doseRateMgPerHr(concentrationMgPerMl: 0.1, rateMlPerHr: 50.0), closeTo(5.0, 0.001));
      });

      test('4.4: doseRateMgPerHr (Magnesium Sulfate 40 mg/mL at 25 mL/hr) -> 1000 mg/hr', () {
        expect(IvRateCalculator.doseRateMgPerHr(concentrationMgPerMl: 40.0, rateMlPerHr: 25.0), closeTo(1000.0, 0.001));
      });

      test('4.5: rateMlPerHrFromUnits (Heparin 1260 units/hr, 100 units/mL) -> 12.6 mL/hr', () {
        expect(IvRateCalculator.rateMlPerHrFromUnits(desiredUnitsPerHr: 1260.0, concentrationUnitsPerMl: 100.0), closeTo(12.6, 0.001));
      });

      test('4.6: rateMlPerHrFromUnits (Insulin 6 units/hr, 1 unit/mL) -> 6.0 mL/hr', () {
        expect(IvRateCalculator.rateMlPerHrFromUnits(desiredUnitsPerHr: 6.0, concentrationUnitsPerMl: 1.0), closeTo(6.0, 0.001));
      });

      test('4.7: Ancillary helpers throw ArgumentError on invalid inputs', () {
        expect(() => IvRateCalculator.volumeForDose(desiredDoseMg: -10.0, concentrationMgPerMl: 10.0), throwsArgumentError);
        expect(() => IvRateCalculator.volumeForDose(desiredDoseMg: 10.0, concentrationMgPerMl: 0.0), throwsArgumentError);
        expect(() => IvRateCalculator.doseRateMgPerHr(concentrationMgPerMl: 0.0, rateMlPerHr: 10.0), throwsArgumentError);
        expect(() => IvRateCalculator.doseRateMgPerHr(concentrationMgPerMl: 10.0, rateMlPerHr: -5.0), throwsArgumentError);
        expect(() => IvRateCalculator.rateMlPerHrFromUnits(desiredUnitsPerHr: -1.0, concentrationUnitsPerMl: 100.0), throwsArgumentError);
        expect(() => IvRateCalculator.rateMlPerHrFromUnits(desiredUnitsPerHr: 100.0, concentrationUnitsPerMl: 0.0), throwsArgumentError);
      });
    });
  });
}
