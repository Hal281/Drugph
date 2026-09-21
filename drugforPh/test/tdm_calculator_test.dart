import 'package:test/test.dart';
import 'package:drug_dosage_calculator/core/calculators/tdm_calculator.dart';

void main() {
  group('TDM Calculator Tests', () {
    test('calculateVd - standard 0.7 L/kg', () {
      final vd = TdmCalculator.calculateVd(weightKg: 70);
      expect(vd, closeTo(49.0, 0.1));
    });

    test('calculateKe - based on normal CrCl', () {
      final ke = TdmCalculator.calculateKe(crclMlMin: 100);
      // (0.00083 * 100) + 0.0044 = 0.083 + 0.0044 = 0.0874
      expect(ke, closeTo(0.0874, 0.0001));
    });

    test('calculateKe - anuric patient (CrCl <= 0)', () {
      final ke = TdmCalculator.calculateKe(crclMlMin: 0);
      // Should return minimum Ke for anuric
      expect(ke, closeTo(0.0044, 0.0001));
    });

    test('calculateHalfLife - valid Ke', () {
      final t12 = TdmCalculator.calculateHalfLife(ke: 0.0874);
      // ln(2) / 0.0874 = 0.693147 / 0.0874 ≈ 7.93
      expect(t12, closeTo(7.93, 0.1));
    });

    test('calculateLoadingDose - standard patient', () {
      final doseRange = TdmCalculator.calculateLoadingDose(weightKg: 70);
      // 70 * 25 = 1750, 70 * 30 = 2100
      expect(doseRange[0], equals(1750.0));
      expect(doseRange[1], equals(2100.0));
    });

    test('calculateLoadingDose - capped at absolute max (obese patient)', () {
      final doseRange = TdmCalculator.calculateLoadingDose(
        weightKg: 150, 
        absoluteMaxMg: 3000.0,
      );
      // 150 * 25 = 3750 (capped to 3000)
      // 150 * 30 = 4500 (capped to 3000)
      expect(doseRange[0], equals(3000.0));
      expect(doseRange[1], equals(3000.0));
    });

    test('predictTrough - steady state calculation', () {
      // Typical Vancomycin dosing
      final trough = TdmCalculator.predictTrough(
        dose: 1000, 
        tau: 12, 
        tInf: 1, 
        vd: 49.0, 
        ke: 0.0874,
      );
      // Math sanity check: 
      // peakSS = (1000 / (1 * 49 * 0.0874)) * (1 - e^-0.0874) / (1 - e^(-0.0874 * 12))
      // troughSS = peakSS * e^(-0.0874 * 11)
      // Ensure it runs and returns a valid clinical range value
      expect(trough, greaterThan(5.0));
      expect(trough, lessThan(25.0));
    });
  });
}
