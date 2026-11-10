// ============================================================
// UNIT CONVERSION ENGINE AUDIT TEST SUITE
// ============================================================
// Validates 100% mathematical exactness, pure function determinism,
// dimensional consistency, and laboratory conversions in UnitConverter.
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/calculators/unit_converter.dart';
import 'package:drug_dosage_calculator/core/models/unit.dart';

void main() {
  group('UnitConverter Pure Function Suite', () {
    // -----------------------------------------------------------------------
    // 1. Mass Conversions (convertMass)
    // -----------------------------------------------------------------------
    group('1. convertMass (mcg, mg, g, kg)', () {
      test('1.1: mcg <-> mg exactness', () {
        expect(UnitConverter.convertMass(1000.0, MassUnit.mcg, MassUnit.mg), equals(1.0));
        expect(UnitConverter.convertMass(1.0, MassUnit.mg, MassUnit.mcg), equals(1000.0));
        expect(UnitConverter.convertMass(250.0, MassUnit.mcg, MassUnit.mg), equals(0.25));
      });

      test('1.2: mg <-> g exactness', () {
        expect(UnitConverter.convertMass(1000.0, MassUnit.mg, MassUnit.g), equals(1.0));
        expect(UnitConverter.convertMass(1.0, MassUnit.g, MassUnit.mg), equals(1000.0));
        expect(UnitConverter.convertMass(500.0, MassUnit.mg, MassUnit.g), equals(0.5));
      });

      test('1.3: g <-> kg exactness', () {
        expect(UnitConverter.convertMass(1000.0, MassUnit.g, MassUnit.kg), equals(1.0));
        expect(UnitConverter.convertMass(1.0, MassUnit.kg, MassUnit.g), equals(1000.0));
        expect(UnitConverter.convertMass(70000.0, MassUnit.g, MassUnit.kg), equals(70.0));
      });

      test('1.4: mcg <-> g and mcg <-> kg long-jump conversions', () {
        expect(UnitConverter.convertMass(1000000.0, MassUnit.mcg, MassUnit.g), equals(1.0));
        expect(UnitConverter.convertMass(1.0, MassUnit.g, MassUnit.mcg), equals(1000000.0));
        expect(UnitConverter.convertMass(1000000000.0, MassUnit.mcg, MassUnit.kg), equals(1.0));
        expect(UnitConverter.convertMass(1.0, MassUnit.kg, MassUnit.mcg), equals(1000000000.0));
      });

      test('1.5: Identity conversions (from == to)', () {
        expect(UnitConverter.convertMass(42.5, MassUnit.mg, MassUnit.mg), equals(42.5));
        expect(UnitConverter.convertMass(100.0, MassUnit.mcg, MassUnit.mcg), equals(100.0));
        expect(UnitConverter.convertMass(2.0, MassUnit.g, MassUnit.g), equals(2.0));
        expect(UnitConverter.convertMass(70.0, MassUnit.kg, MassUnit.kg), equals(70.0));
      });
    });

    // -----------------------------------------------------------------------
    // 2. Volume Conversions (convertVolume)
    // -----------------------------------------------------------------------
    group('2. convertVolume (mL, L)', () {
      test('2.1: mL <-> L exactness', () {
        expect(UnitConverter.convertVolume(1000.0, VolumeUnit.mL, VolumeUnit.L), equals(1.0));
        expect(UnitConverter.convertVolume(1.0, VolumeUnit.L, VolumeUnit.mL), equals(1000.0));
        expect(UnitConverter.convertVolume(500.0, VolumeUnit.mL, VolumeUnit.L), equals(0.5));
        expect(UnitConverter.convertVolume(250.0, VolumeUnit.mL, VolumeUnit.L), equals(0.25));
        expect(UnitConverter.convertVolume(2.5, VolumeUnit.L, VolumeUnit.mL), equals(2500.0));
      });

      test('2.2: Identity conversions', () {
        expect(UnitConverter.convertVolume(250.0, VolumeUnit.mL, VolumeUnit.mL), equals(250.0));
        expect(UnitConverter.convertVolume(1.0, VolumeUnit.L, VolumeUnit.L), equals(1.0));
      });
    });

    // -----------------------------------------------------------------------
    // 3. Time Conversions (convertTime)
    // -----------------------------------------------------------------------
    group('3. convertTime (min, hr, day)', () {
      test('3.1: min <-> hr exactness', () {
        expect(UnitConverter.convertTime(60.0, TimeUnit.minute, TimeUnit.hour), equals(1.0));
        expect(UnitConverter.convertTime(1.0, TimeUnit.hour, TimeUnit.minute), equals(60.0));
        expect(UnitConverter.convertTime(90.0, TimeUnit.minute, TimeUnit.hour), equals(1.5));
        expect(UnitConverter.convertTime(0.5, TimeUnit.hour, TimeUnit.minute), equals(30.0));
      });

      test('3.2: hr <-> day exactness', () {
        expect(UnitConverter.convertTime(24.0, TimeUnit.hour, TimeUnit.day), equals(1.0));
        expect(UnitConverter.convertTime(1.0, TimeUnit.day, TimeUnit.hour), equals(24.0));
        expect(UnitConverter.convertTime(48.0, TimeUnit.hour, TimeUnit.day), equals(2.0));
        expect(UnitConverter.convertTime(0.5, TimeUnit.day, TimeUnit.hour), equals(12.0));
      });

      test('3.3: min <-> day exactness', () {
        expect(UnitConverter.convertTime(1440.0, TimeUnit.minute, TimeUnit.day), equals(1.0));
        expect(UnitConverter.convertTime(1.0, TimeUnit.day, TimeUnit.minute), equals(1440.0));
        expect(UnitConverter.convertTime(720.0, TimeUnit.minute, TimeUnit.day), equals(0.5));
      });

      test('3.4: Identity conversions', () {
        expect(UnitConverter.convertTime(120.0, TimeUnit.minute, TimeUnit.minute), equals(120.0));
        expect(UnitConverter.convertTime(8.0, TimeUnit.hour, TimeUnit.hour), equals(8.0));
        expect(UnitConverter.convertTime(1.0, TimeUnit.day, TimeUnit.day), equals(1.0));
      });
    });

    // -----------------------------------------------------------------------
    // 4. Concentration Helpers (% w/v <-> mg/mL <-> mcg/mL)
    // -----------------------------------------------------------------------
    group('4. Concentration helpers (% w/v <-> mg/mL <-> mcg/mL)', () {
      test('4.1: percentWvToMgPerMl and mgPerMlToPercentWv round-trip', () {
        // 0.9% Normal Saline = 9 mg/mL
        expect(UnitConverter.percentWvToMgPerMl(0.9), closeTo(9.0, 0.001));
        expect(UnitConverter.mgPerMlToPercentWv(9.0), closeTo(0.9, 0.001));

        // 5% Dextrose = 50 mg/mL
        expect(UnitConverter.percentWvToMgPerMl(5.0), closeTo(50.0, 0.001));
        expect(UnitConverter.mgPerMlToPercentWv(50.0), closeTo(5.0, 0.001));

        // 10% Calcium Gluconate = 100 mg/mL
        expect(UnitConverter.percentWvToMgPerMl(10.0), closeTo(100.0, 0.001));
        expect(UnitConverter.mgPerMlToPercentWv(100.0), closeTo(10.0, 0.001));

        // 50% Glucose = 500 mg/mL
        expect(UnitConverter.percentWvToMgPerMl(50.0), closeTo(500.0, 0.001));
        expect(UnitConverter.mgPerMlToPercentWv(500.0), closeTo(50.0, 0.001));

        // 2% Lidocaine = 20 mg/mL
        expect(UnitConverter.percentWvToMgPerMl(2.0), closeTo(20.0, 0.001));
        expect(UnitConverter.mgPerMlToPercentWv(20.0), closeTo(2.0, 0.001));
      });

      test('4.2: mgPerMlToMcgPerMl and mcgPerMlToMgPerMl round-trip', () {
        expect(UnitConverter.mgPerMlToMcgPerMl(1.0), equals(1000.0));
        expect(UnitConverter.mcgPerMlToMgPerMl(1000.0), equals(1.0));

        // Norepinephrine / Epinephrine standard dilution 16 mcg/mL = 0.016 mg/mL
        expect(UnitConverter.mgPerMlToMcgPerMl(0.016), closeTo(16.0, 0.001));
        expect(UnitConverter.mcgPerMlToMgPerMl(16.0), closeTo(0.016, 0.001));

        // Norepinephrine double strength 32 mcg/mL = 0.032 mg/mL
        expect(UnitConverter.mgPerMlToMcgPerMl(0.032), closeTo(32.0, 0.001));
        expect(UnitConverter.mcgPerMlToMgPerMl(32.0), closeTo(0.032, 0.001));

        // Dopamine standard dilution 1.6 mg/mL = 1600 mcg/mL
        expect(UnitConverter.mgPerMlToMcgPerMl(1.6), closeTo(1600.0, 0.001));
        expect(UnitConverter.mcgPerMlToMgPerMl(1600.0), closeTo(1.6, 0.001));

        // Dopamine double strength 3.2 mg/mL = 3200 mcg/mL
        expect(UnitConverter.mgPerMlToMcgPerMl(3.2), closeTo(3200.0, 0.001));
        expect(UnitConverter.mcgPerMlToMgPerMl(3200.0), closeTo(3.2, 0.001));

        // Dobutamine standard dilution 1.0 mg/mL = 1000 mcg/mL
        expect(UnitConverter.mgPerMlToMcgPerMl(1.0), closeTo(1000.0, 0.001));
        expect(UnitConverter.mcgPerMlToMgPerMl(1000.0), closeTo(1.0, 0.001));
      });

      test('4.3: volumeForDoseMg calculates volume and rejects non-positive concentration', () {
        expect(UnitConverter.volumeForDoseMg(desiredDoseMg: 500.0, concentrationMgPerMl: 50.0), equals(10.0));
        expect(UnitConverter.volumeForDoseMg(desiredDoseMg: 40.0, concentrationMgPerMl: 10.0), equals(4.0));
        expect(UnitConverter.volumeForDoseMg(desiredDoseMg: 0.0, concentrationMgPerMl: 10.0), equals(0.0));
        expect(() => UnitConverter.volumeForDoseMg(desiredDoseMg: 500.0, concentrationMgPerMl: 0.0), throwsArgumentError);
        expect(() => UnitConverter.volumeForDoseMg(desiredDoseMg: 500.0, concentrationMgPerMl: -10.0), throwsArgumentError);
      });
    });

    // -----------------------------------------------------------------------
    // 5. Clinical Laboratory SCr Conversions (umol/L <-> mg/dL)
    // -----------------------------------------------------------------------
    group('5. Serum Creatinine clinical conversions (factor 88.4)', () {
      test('5.1: Clinical spectrum of SCr conversions', () {
        // Pediatric/low: 44.2 umol/L = 0.5 mg/dL
        expect(UnitConverter.scrUmolPerLToMgPerDl(44.2), closeTo(0.5, 0.001));
        expect(UnitConverter.scrMgPerDlToUmolPerL(0.5), closeTo(44.2, 0.001));

        // Normal adult: 88.4 umol/L = 1.0 mg/dL
        expect(UnitConverter.scrUmolPerLToMgPerDl(88.4), closeTo(1.0, 0.001));
        expect(UnitConverter.scrMgPerDlToUmolPerL(1.0), closeTo(88.4, 0.001));

        // Moderate CKD: 176.8 umol/L = 2.0 mg/dL
        expect(UnitConverter.scrUmolPerLToMgPerDl(176.8), closeTo(2.0, 0.001));
        expect(UnitConverter.scrMgPerDlToUmolPerL(2.0), closeTo(176.8, 0.001));

        // Severe CKD: 353.6 umol/L = 4.0 mg/dL
        expect(UnitConverter.scrUmolPerLToMgPerDl(353.6), closeTo(4.0, 0.001));
        expect(UnitConverter.scrMgPerDlToUmolPerL(4.0), closeTo(353.6, 0.001));

        // Dialysis/ESKD: 707.2 umol/L = 8.0 mg/dL
        expect(UnitConverter.scrUmolPerLToMgPerDl(707.2), closeTo(8.0, 0.001));
        expect(UnitConverter.scrMgPerDlToUmolPerL(8.0), closeTo(707.2, 0.001));
      });
    });

    // -----------------------------------------------------------------------
    // 6. Imperial <-> Metric Body Parameter Conversions
    // -----------------------------------------------------------------------
    group('6. Imperial <-> Metric conversions (lb/kg, in/cm)', () {
      test('6.1: lb <-> kg round-trip across clinical range', () {
        expect(UnitConverter.lbToKg(154.32358), closeTo(70.0, 0.01));
        expect(UnitConverter.kgToLb(70.0), closeTo(154.32358, 0.01));

        // 110 lb (50 kg)
        expect(UnitConverter.lbToKg(110.23113), closeTo(50.0, 0.01));

        // 220.46 lb (100 kg)
        expect(UnitConverter.lbToKg(220.46226), closeTo(100.0, 0.01));
      });

      test('6.2: in <-> cm round-trip', () {
        expect(UnitConverter.inToCm(70.0), closeTo(177.8, 0.001));
        expect(UnitConverter.cmToIn(177.8), closeTo(70.0, 0.001));

        // Neonate length 20 in = 50.8 cm
        expect(UnitConverter.inToCm(20.0), closeTo(50.8, 0.001));
        expect(UnitConverter.cmToIn(50.8), closeTo(20.0, 0.001));
      });
    });

    // -----------------------------------------------------------------------
    // 7. DoseUnit Compatibility & Frequency Parsing
    // -----------------------------------------------------------------------
    group('7. convertDoseUnit & dosesPerDay safe guards', () {
      test('7.1: convertDoseUnit allows mcg/mg/g and rejects non-mass units', () {
        expect(UnitConverter.convertDoseUnit(1000.0, DoseUnit.mcg, DoseUnit.mg), equals(1.0));
        expect(UnitConverter.convertDoseUnit(1.0, DoseUnit.g, DoseUnit.mg), equals(1000.0));
        expect(UnitConverter.convertDoseUnit(500.0, DoseUnit.mg, DoseUnit.mg), equals(500.0));
        expect(() => UnitConverter.convertDoseUnit(100.0, DoseUnit.mg, DoseUnit.units), throwsArgumentError);
        expect(() => UnitConverter.convertDoseUnit(10.0, DoseUnit.mEq, DoseUnit.mg), throwsArgumentError);
        expect(() => UnitConverter.convertDoseUnit(10.0, DoseUnit.mmol, DoseUnit.mg), throwsArgumentError);
        expect(() => UnitConverter.convertDoseUnit(5.0, DoseUnit.mL, DoseUnit.mg), throwsArgumentError);
      });

      test('7.2: dosesPerDay parses standard Latin and clinical frequency abbreviations', () {
        expect(UnitConverter.dosesPerDay('q4h'), equals(6.0));
        expect(UnitConverter.dosesPerDay('q6h'), equals(4.0));
        expect(UnitConverter.dosesPerDay('q8h'), equals(3.0));
        expect(UnitConverter.dosesPerDay('q12h'), equals(2.0));
        expect(UnitConverter.dosesPerDay('q24h'), equals(1.0));
        expect(UnitConverter.dosesPerDay('q48h'), equals(0.5));
        expect(UnitConverter.dosesPerDay('bid'), equals(2.0));
        expect(UnitConverter.dosesPerDay('tid'), equals(3.0));
        expect(UnitConverter.dosesPerDay('qid'), equals(4.0));
        expect(UnitConverter.dosesPerDay('daily'), equals(1.0));
        expect(UnitConverter.dosesPerDay('od'), equals(1.0));
        expect(UnitConverter.dosesPerDay('qd'), equals(1.0));
        expect(UnitConverter.dosesPerDay('once'), equals(1.0));
        expect(UnitConverter.dosesPerDay('stat'), equals(1.0));
        expect(UnitConverter.dosesPerDay('q12h (bid)'), equals(2.0));
      });

      test('7.3: dosesPerDay parses Thai clinical frequency phrases', () {
        expect(UnitConverter.dosesPerDay('ทุก 8 ชม.'), equals(3.0));
        expect(UnitConverter.dosesPerDay('ทุก 6 ชั่วโมง'), equals(4.0));
        expect(UnitConverter.dosesPerDay('วันละ 2 ครั้ง'), equals(2.0));
        expect(UnitConverter.dosesPerDay('ครั้งเดียว'), equals(1.0));
      });

      test('7.4: dosesPerDay returns 0 for non-deterministic frequencies', () {
        expect(UnitConverter.dosesPerDay('continuous'), equals(0.0));
        expect(UnitConverter.dosesPerDay('prn'), equals(0.0));
        expect(UnitConverter.dosesPerDay('as needed'), equals(0.0));
        expect(UnitConverter.dosesPerDay('เมื่อจำเป็น'), equals(0.0));
        expect(UnitConverter.dosesPerDay('เมื่อมีอาการ'), equals(0.0));
        expect(UnitConverter.dosesPerDay('titrate'), equals(0.0));
        expect(UnitConverter.dosesPerDay('q6-8h'), equals(0.0));
        expect(UnitConverter.dosesPerDay('weekly'), equals(0.0));
        expect(UnitConverter.dosesPerDay(''), equals(0.0));
        expect(UnitConverter.dosesPerDay('unknown_frequency_xyz'), equals(0.0));
      });
    });
  });
}
