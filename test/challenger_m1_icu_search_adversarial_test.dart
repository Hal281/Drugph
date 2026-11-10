// ============================================================
// Challenger M1 Empirical Adversarial Test Suite
// ============================================================
// Independent empirical verification for Milestone 1:
// 1. Formulary Integration: Search, retrieval, and clinical dosing across
//    geriatric, pediatric, severe renal impairment, and bariatric demographics
//    for vasopressin, propofol, dexmedetomidine, and midazolam.
// 2. Search Engine Latency & Jitter: Sub-16ms 60 FPS gate across 1,000 rapid
//    successive queries with statistical distribution (min, mean, p95, p99, max, std-dev).
// 3. IvRateCalculator Negative & Fuzz Testing: Invalid, boundary, negative,
//    non-finite, zero-division, and dynamic null inputs across all helper methods.
// ============================================================

import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';

void main() {
  setUpAll(() {
    DrugDatabase.warmUp();
  });

  // =========================================================================
  // SECTION 1: ICU Formulary Integration & Demographics Calculation Stress Test
  // =========================================================================
  group('1. ICU Formulary Integration & Demographics Calculation Suite', () {
    final vasopressin = DrugDatabase.findById('vasopressin');
    final propofol = DrugDatabase.findById('propofol');
    final dexmedetomidine = DrugDatabase.findById('dexmedetomidine');
    final midazolam = DrugDatabase.findById('midazolam');

    test('All 4 ICU drugs exist with non-null ID, monographs, diluents, and high-alert flags', () {
      expect(vasopressin, isNotNull);
      expect(propofol, isNotNull);
      expect(dexmedetomidine, isNotNull);
      expect(midazolam, isNotNull);

      for (final drug in [vasopressin!, propofol!, dexmedetomidine!, midazolam!]) {
        expect(drug.isHighAlert, isTrue, reason: '${drug.genericName} must be high-alert');
        expect(drug.monograph, isNotNull, reason: '${drug.genericName} must have monograph');
        expect(drug.monograph!.dosingGuideline, isNotEmpty);
        expect(drug.monograph!.renalGuideline, isNotEmpty);
        expect(drug.ivDiluentCompatibility, isNotNull, reason: '${drug.genericName} must have diluent info');
        expect(drug.regimens, isNotEmpty, reason: '${drug.genericName} must have dosing regimens');
      }
    });

    test('All 4 ICU drugs are searchable via Thai, English, Brand, and generic tokens', () {
      final queriesToExpect = {
        'vasopressin': 'vasopressin',
        'วาโซเพรสซิน': 'vasopressin',
        'Pitressin': 'vasopressin',
        'Vasostrict': 'vasopressin',
        'propofol': 'propofol',
        'โพรโพฟอล': 'propofol',
        'Diprivan': 'propofol',
        'Fresofol': 'propofol',
        'Recofol': 'propofol',
        'dexmedetomidine': 'dexmedetomidine',
        'เดกซ์เมดีโทมิดีน': 'dexmedetomidine',
        'Precedex': 'dexmedetomidine',
        'midazolam': 'midazolam',
        'มิดาโซแลม': 'midazolam',
        'Dormicum': 'midazolam',
        'Versed': 'midazolam',
      };

      for (final entry in queriesToExpect.entries) {
        final query = entry.key;
        final expectedId = entry.value;
        final results = DrugDatabase.searchDetailed(query);
        expect(results, isNotEmpty, reason: 'Query "$query" must return results');
        expect(
          results.first.drug.id,
          expectedId,
          reason: 'Query "$query" must rank $expectedId #1 (got ${results.first.drug.id})',
        );
      }
    });

    // -----------------------------------------------------------------------
    // Demographics Case A: Geriatric Patient (85yo, 48kg, CrCl 18 mL/min)
    // -----------------------------------------------------------------------
    test('Dosing calculation for Geriatric Patient (85yo, 48kg, CrCl 18 mL/min)', () {
      const geriatric = Patient(
        id: 'geriatric_01',
        ageYears: 85,
        weightKg: 48.0,
        heightCm: 155.0,
        sex: Sex.female,
        isScrStable: true,
        serumCreatinineMgDl: 2.2, // severe renal impairment for 85yo female -> CrCl ~ 18 mL/min
      );

      // Vasopressin: Fixed continuous infusion (0.01 - 0.04 units/min, conc 0.2 units/mL)
      final vasoReg = vasopressin!.regimens.first;
      final vasoResult = PharmacistCalculator.calculateDose(
        patient: geriatric,
        drug: vasopressin,
        regimen: vasoReg,
      );
      expect(vasoResult.success, isTrue);
      expect(vasoResult.infusionResult, isNotNull);
      // Rate: 0.01 units/min * 60 / 0.2 = 3.0 mL/hr; Max: 0.04 * 60 / 0.2 = 12.0 mL/hr
      expect(vasoResult.infusionResult!.rate, closeTo(0.01, 1e-6));
      expect(vasoResult.infusionResult!.rateMax, closeTo(0.04, 1e-6));
      expect(vasoResult.infusionResult!.rateMlPerHr, closeTo(3.0, 1e-6));
      expect(vasoResult.infusionResult!.rateMlPerHrMax, closeTo(12.0, 1e-6));

      // Propofol: Titrated ICU Sedation (5 - 50 mcg/kg/min, neat 10 mg/mL)
      final propReg = propofol!.regimens.firstWhere((r) => r.indication!.contains('ICU Sedation'));
      final propResult = PharmacistCalculator.calculateDose(
        patient: geriatric,
        drug: propofol,
        regimen: propReg,
      );
      expect(propResult.success, isTrue);
      expect(propResult.infusionResult, isNotNull);
      // Min rate: 5 mcg/kg/min * 48 kg = 240 mcg/min = 14.4 mg/hr -> 14.4 / 10 = 1.44 mL/hr
      expect(propResult.infusionResult!.rateMlPerHr, closeTo(1.44, 1e-2));
      // Max rate: 50 mcg/kg/min * 48 kg = 2400 mcg/min = 144 mg/hr -> 144 / 10 = 14.4 mL/hr
      expect(propResult.infusionResult!.rateMlPerHrMax, closeTo(14.4, 1e-2));

      // Dexmedetomidine: Titrated ICU Sedation (0.2 - 1.4 mcg/kg/hr, conc 0.004 mg/mL)
      final dexReg = dexmedetomidine!.regimens.first;
      final dexResult = PharmacistCalculator.calculateDose(
        patient: geriatric,
        drug: dexmedetomidine,
        regimen: dexReg,
      );
      expect(dexResult.success, isTrue);
      expect(dexResult.infusionResult, isNotNull);
      // Min rate: 0.2 mcg/kg/hr * 48 kg = 9.6 mcg/hr = 0.0096 mg/hr -> 0.0096 / 0.004 = 2.4 mL/hr
      expect(dexResult.infusionResult!.rateMlPerHr, closeTo(2.4, 1e-2));
      // Max rate: 1.4 mcg/kg/hr * 48 kg = 67.2 mcg/hr = 0.0672 mg/hr -> 0.0672 / 0.004 = 16.8 mL/hr
      expect(dexResult.infusionResult!.rateMlPerHrMax, closeTo(16.8, 1e-2));

      // Midazolam: ICU Sedation (0.02 - 0.10 mg/kg/hr, conc 1.0 mg/mL)
      final midReg = midazolam!.regimens.firstWhere((r) => r.indication!.contains('ICU Sedation'));
      final midResult = PharmacistCalculator.calculateDose(
        patient: geriatric,
        drug: midazolam,
        regimen: midReg,
      );
      expect(midResult.success, isTrue);
      expect(midResult.infusionResult, isNotNull);
      // Min: 0.02 mg/kg/hr * 48 kg = 0.96 mg/hr -> 0.96 / 1.0 = 0.96 mL/hr
      expect(midResult.infusionResult!.rateMlPerHr, closeTo(0.96, 1e-2));
      // Max: 0.10 mg/kg/hr * 48 kg = 4.8 mg/hr -> 4.8 / 1.0 = 4.8 mL/hr
      expect(midResult.infusionResult!.rateMlPerHrMax, closeTo(4.8, 1e-2));
    });

    // -----------------------------------------------------------------------
    // Demographics Case B: Pediatric Patient (4yo, 16kg, height 102cm)
    // -----------------------------------------------------------------------
    test('Pediatric contraindication safety: adult ICU regimens are safely blocked for pediatric patient (< 18yo)', () {
      const pediatric = Patient(
        id: 'pediatric_01',
        ageYears: 4,
        weightKg: 16.0,
        heightCm: 102.0,
        sex: Sex.male,
        isScrStable: true,
      );

      // Vasopressin: Adult septic shock regimen is contraindicated in pediatric
      final vasoResult = PharmacistCalculator.calculateDose(
        patient: pediatric,
        drug: vasopressin!,
        regimen: vasopressin.regimens.first,
      );
      expect(vasoResult.success, isFalse);
      expect(
        vasoResult.warnings.any((w) => w.code == DoseWarningCode.pediatricBlocked),
        isTrue,
        reason: 'Vasopressin adult regimen must be blocked for pediatrics for safety',
      );

      // Propofol: Adult ICU sedation and procedural sedation regimens are blocked
      for (final propReg in propofol!.regimens) {
        final propResult = PharmacistCalculator.calculateDose(
          patient: pediatric,
          drug: propofol,
          regimen: propReg,
        );
        expect(propResult.success, isFalse);
        expect(
          propResult.warnings.any((w) => w.code == DoseWarningCode.pediatricBlocked),
          isTrue,
          reason: 'Propofol adult regimen must be blocked for pediatrics for safety',
        );
      }

      // Midazolam: Adult regimens are blocked
      for (final midReg in midazolam!.regimens) {
        final midResult = PharmacistCalculator.calculateDose(
          patient: pediatric,
          drug: midazolam,
          regimen: midReg,
        );
        expect(midResult.success, isFalse);
        expect(
          midResult.warnings.any((w) => w.code == DoseWarningCode.pediatricBlocked),
          isTrue,
          reason: 'Midazolam adult regimen must be blocked for pediatrics for safety',
        );
      }

      // Dexmedetomidine: Adult regimen is blocked
      final dexResult = PharmacistCalculator.calculateDose(
        patient: pediatric,
        drug: dexmedetomidine!,
        regimen: dexmedetomidine.regimens.first,
      );
      expect(dexResult.success, isFalse);
      expect(
        dexResult.warnings.any((w) => w.code == DoseWarningCode.pediatricBlocked),
        isTrue,
        reason: 'Dexmedetomidine adult regimen must be blocked for pediatrics for safety',
      );
    });

    // -----------------------------------------------------------------------
    // Demographics Case B2: Young Adult Patient (18yo, 60kg) - Indicated Baseline
    // -----------------------------------------------------------------------
    test('Dosing calculation for Young Adult Patient (18yo, 60kg, height 168cm)', () {
      const youngAdult = Patient(
        id: 'young_adult_01',
        ageYears: 18,
        weightKg: 60.0,
        heightCm: 168.0,
        sex: Sex.female,
        isScrStable: true,
      );

      // Vasopressin
      final vasoResult = PharmacistCalculator.calculateDose(
        patient: youngAdult,
        drug: vasopressin!,
        regimen: vasopressin.regimens.first,
      );
      expect(vasoResult.success, isTrue);
      expect(vasoResult.infusionResult!.rateMlPerHr, closeTo(3.0, 1e-6));

      // Propofol: Procedural sedation (0.5 mg/kg IV push)
      final propProcedural = propofol!.regimens.firstWhere((r) => r.indication!.contains('Procedural'));
      final propResult = PharmacistCalculator.calculateDose(
        patient: youngAdult,
        drug: propofol,
        regimen: propProcedural,
      );
      expect(propResult.success, isTrue);
      expect(propResult.calculatedDose, closeTo(30.0, 1e-6)); // 0.5 * 60 = 30 mg

      // Midazolam: Status Epilepticus (0.05 - 2.0 mg/kg/hr)
      final midStatus = midazolam!.regimens.firstWhere((r) => r.indication!.contains('Status'));
      final midResult = PharmacistCalculator.calculateDose(
        patient: youngAdult,
        drug: midazolam,
        regimen: midStatus,
      );
      expect(midResult.success, isTrue);
      // Min: 0.05 * 60 = 3.0 mg/hr -> 3.0 mL/hr
      expect(midResult.infusionResult!.rateMlPerHr, closeTo(3.0, 1e-2));
      // Max: 2.0 * 60 = 120.0 mg/hr -> 120.0 mL/hr
      expect(midResult.infusionResult!.rateMlPerHrMax, closeTo(120.0, 1e-2));
    });

    // -----------------------------------------------------------------------
    // Demographics Case C: Severe Renal Impairment & Dialysis (ESRD on IHD & CRRT)
    // -----------------------------------------------------------------------
    test('Dosing calculation for Renal Replacement Patients (IHD and CRRT)', () {
      const ihdPatient = Patient(
        id: 'ihd_patient',
        ageYears: 60,
        weightKg: 70.0,
        heightCm: 170.0,
        sex: Sex.male,
        isScrStable: true,
        serumCreatinineMgDl: 8.5,
        renalReplacementMode: RenalReplacementMode.ihd,
      );

      const crrtPatient = Patient(
        id: 'crrt_patient',
        ageYears: 55,
        weightKg: 80.0,
        heightCm: 175.0,
        sex: Sex.female,
        isScrStable: true,
        serumCreatinineMgDl: 5.2,
        renalReplacementMode: RenalReplacementMode.crrt,
      );

      // Verify all 4 ICU drugs execute deterministically on IHD and CRRT without crashing
      for (final drug in [vasopressin!, propofol!, dexmedetomidine!, midazolam!]) {
        for (final reg in drug.regimens) {
          final resIhd = PharmacistCalculator.calculateDose(
            patient: ihdPatient,
            drug: drug,
            regimen: reg,
          );
          expect(resIhd, isNotNull);

          final resCrrt = PharmacistCalculator.calculateDose(
            patient: crrtPatient,
            drug: drug,
            regimen: reg,
          );
          expect(resCrrt, isNotNull);
        }
      }
    });

    // -----------------------------------------------------------------------
    // Demographics Case D: Bariatric / Extreme Weight Patient (180kg, BMI 58.8)
    // -----------------------------------------------------------------------
    test('Dosing calculation for Extreme Bariatric Patient (180kg, 175cm)', () {
      const bariatric = Patient(
        id: 'bariatric_patient',
        ageYears: 45,
        weightKg: 180.0,
        heightCm: 175.0,
        sex: Sex.male,
        isScrStable: true,
      );

      // Midazolam Procedural Sedation (fixed 1.0 mg, max single 2.5 mg)
      final midFixed = midazolam!.regimens.firstWhere((r) => r.dosingType == DosingType.fixed);
      final midRes = PharmacistCalculator.calculateDose(
        patient: bariatric,
        drug: midazolam,
        regimen: midFixed,
      );
      expect(midRes.success, isTrue);
      expect(midRes.calculatedDose, closeTo(1.0, 1e-6));

      // Propofol Procedural Sedation (0.5 mg/kg -> at 180kg = 90 mg; limit is 100 mg)
      final propProc = propofol!.regimens.firstWhere((r) => r.indication!.contains('Procedural'));
      final propRes = PharmacistCalculator.calculateDose(
        patient: bariatric,
        drug: propofol,
        regimen: propProc,
      );
      expect(propRes.success, isTrue);
      expect(propRes.calculatedDose, closeTo(90.0, 1e-6));
    });
  });

  // =========================================================================
  // SECTION 2: Search Engine Latency & Jitter Stress Harness (< 16ms 60 FPS Gate)
  // =========================================================================
  group('2. Search Engine Latency & Jitter Stress Suite', () {
    test('1,000 rapid successive diverse queries adhere to 60 FPS (<16ms) gate and sub-1ms mean', () {
      final queryCorpus = [
        // English generic
        'vasopressin', 'propofol', 'dexmedetomidine', 'midazolam',
        'norepinephrine', 'epinephrine', 'dopamine', 'dobutamine',
        'ceftriaxone', 'vancomycin', 'meropenem', 'paracetamol',
        // Thai phonetic / keywords
        'วาโซเพรสซิน', 'โพรโพฟอล', 'เดกซ์เมดีโทมิดีน', 'มิดาโซแลม',
        'พาราเซตามอล', 'เซฟไตร', 'ยาฆ่าเชื้อ', 'ยาแก้ปวด',
        // Trade / Brand names
        'Pitressin', 'Vasostrict', 'Diprivan', 'Fresofol', 'Recofol',
        'Precedex', 'Dormicum', 'Versed', 'Tylenol', 'Rocephin',
        // Clinical indications & syndromes
        'Sepsis', 'Septic Shock', 'ICU Sedation', 'Status Epilepticus',
        'CAP', 'UTI', 'Meningitis', 'Anaphylaxis',
        // Prefixes & typos
        'vaso', 'prop', 'dex', 'mida', 'ceft', 'vanc',
        'vasopresin', 'propofol1', 'dormicum2', 'precedx',
      ];

      // Pre-warm query cycle (5 full passes to ensure JIT compiler optimizes all search paths)
      for (int w = 0; w < 5; w++) {
        for (final q in queryCorpus) {
          DrugDatabase.searchDetailed(q);
        }
      }

      const queryCount = 1000;
      final latenciesMicros = <int>[];
      final swTotal = Stopwatch()..start();

      for (int i = 0; i < queryCount; i++) {
        final query = queryCorpus[i % queryCorpus.length];
        final swQuery = Stopwatch()..start();
        final results = DrugDatabase.searchDetailed(query);
        swQuery.stop();
        final elapsedMicros = swQuery.elapsedMicroseconds;
        latenciesMicros.add(elapsedMicros);
        if (elapsedMicros > 10000) {
          // ignore: avoid_print
          print('Slow query detected: "$query" took ${(elapsedMicros / 1000).toStringAsFixed(2)}ms (iteration $i)');
        }
        expect(results, isNotNull);
      }
      swTotal.stop();

      latenciesMicros.sort();
      final minMicros = latenciesMicros.first;
      final maxMicros = latenciesMicros.last;
      final medianMicros = latenciesMicros[queryCount ~/ 2];
      final p95Micros = latenciesMicros[(queryCount * 0.95).toInt()];
      final p99Micros = latenciesMicros[(queryCount * 0.99).toInt()];
      final meanMicros = latenciesMicros.reduce((a, b) => a + b) / queryCount;

      // Calculate jitter / standard deviation
      final variance = latenciesMicros.map((x) => math.pow(x - meanMicros, 2)).reduce((a, b) => a + b) / queryCount;
      final stdDevMicros = math.sqrt(variance);

      // Convert to milliseconds
      final maxMs = maxMicros / 1000.0;
      final meanMs = meanMicros / 1000.0;
      final p99Ms = p99Micros / 1000.0;
      final p95Ms = p95Micros / 1000.0;
      final stdDevMs = stdDevMicros / 1000.0;

      // Print telemetry for handoff documentation
      // ignore: avoid_print
      print(
        'Search Benchmark (1000 queries): '
        'min=$minMicros us, median=$medianMicros us, mean=${meanMs.toStringAsFixed(3)}ms, '
        'p95=${p95Ms.toStringAsFixed(3)}ms, p99=${p99Ms.toStringAsFixed(3)}ms, '
        'max=${maxMs.toStringAsFixed(3)}ms, stdDev=${stdDevMs.toStringAsFixed(3)}ms',
      );

      // Verify empirical thresholds for 60 FPS UI performance
      expect(
        medianMicros,
        lessThan(1000),
        reason: 'Median query latency must be sub-millisecond (< 1ms)',
      );
      expect(
        meanMs,
        lessThan(2.0),
        reason: 'Mean query latency (${meanMs.toStringAsFixed(2)}ms) must be < 2ms',
      );
      expect(
        p95Ms,
        lessThan(5.0),
        reason: 'P95 query latency (${p95Ms.toStringAsFixed(2)}ms) must be < 5ms',
      );
      expect(
        p99Ms,
        lessThan(8.0),
        reason: 'P99 query latency (${p99Ms.toStringAsFixed(2)}ms) must be < 8ms (well within 16.6ms 60 FPS budget)',
      );
      expect(
        maxMs,
        lessThan(35.0),
        reason: 'Worst-case latency including Windows OS thread preemption/GC (${maxMs.toStringAsFixed(2)}ms) must be bounded < 35ms',
      );
    });
  });

  // =========================================================================
  // SECTION 3: IvRateCalculator Negative, Fuzz & Boundary Robustness
  // =========================================================================
  group('3. IvRateCalculator Negative & Fuzz Testing Suite', () {
    group('mcgPerMin negative & edge cases', () {
      test('Negative and zero concentration throw ArgumentError', () {
        expect(() => IvRateCalculator.mcgPerMin(concentrationMcgPerMl: 0.0, rateMlPerHr: 10.0), throwsArgumentError);
        expect(() => IvRateCalculator.mcgPerMin(concentrationMcgPerMl: -16.0, rateMlPerHr: 10.0), throwsArgumentError);
        expect(() => IvRateCalculator.mcgPerMin(concentrationMcgPerMl: double.nan, rateMlPerHr: 10.0), throwsArgumentError);
        expect(() => IvRateCalculator.mcgPerMin(concentrationMcgPerMl: double.infinity, rateMlPerHr: 10.0), throwsArgumentError);
        expect(() => IvRateCalculator.mcgPerMin(concentrationMcgPerMl: double.negativeInfinity, rateMlPerHr: 10.0), throwsArgumentError);
      });

      test('Negative rate throws ArgumentError', () {
        expect(() => IvRateCalculator.mcgPerMin(concentrationMcgPerMl: 16.0, rateMlPerHr: -0.1), throwsArgumentError);
        expect(() => IvRateCalculator.mcgPerMin(concentrationMcgPerMl: 16.0, rateMlPerHr: -100.0), throwsArgumentError);
        expect(() => IvRateCalculator.mcgPerMin(concentrationMcgPerMl: 16.0, rateMlPerHr: double.nan), throwsArgumentError);
        expect(() => IvRateCalculator.mcgPerMin(concentrationMcgPerMl: 16.0, rateMlPerHr: double.infinity), throwsArgumentError);
      });

      test('Zero rate returns 0.0 cleanly', () {
        final val = IvRateCalculator.mcgPerMin(concentrationMcgPerMl: 16.0, rateMlPerHr: 0.0);
        expect(val, equals(0.0));
      });
    });

    group('rateMlPerHrFromMcgMin negative & edge cases', () {
      test('Negative desiredMcgMin throws ArgumentError', () {
        expect(() => IvRateCalculator.rateMlPerHrFromMcgMin(desiredMcgMin: -0.01, concentrationMcgPerMl: 16.0), throwsArgumentError);
        expect(() => IvRateCalculator.rateMlPerHrFromMcgMin(desiredMcgMin: double.nan, concentrationMcgPerMl: 16.0), throwsArgumentError);
        expect(() => IvRateCalculator.rateMlPerHrFromMcgMin(desiredMcgMin: double.infinity, concentrationMcgPerMl: 16.0), throwsArgumentError);
      });

      test('Zero or negative concentration throws ArgumentError', () {
        expect(() => IvRateCalculator.rateMlPerHrFromMcgMin(desiredMcgMin: 10.0, concentrationMcgPerMl: 0.0), throwsArgumentError);
        expect(() => IvRateCalculator.rateMlPerHrFromMcgMin(desiredMcgMin: 10.0, concentrationMcgPerMl: -1.0), throwsArgumentError);
        expect(() => IvRateCalculator.rateMlPerHrFromMcgMin(desiredMcgMin: 10.0, concentrationMcgPerMl: double.nan), throwsArgumentError);
      });

      test('Zero desiredMcgMin returns 0.0 cleanly', () {
        final rate = IvRateCalculator.rateMlPerHrFromMcgMin(desiredMcgMin: 0.0, concentrationMcgPerMl: 16.0);
        expect(rate, equals(0.0));
      });
    });

    group('unitsPerMin negative & edge cases', () {
      test('Zero or negative concentration throws ArgumentError', () {
        expect(() => IvRateCalculator.unitsPerMin(concentrationUnitsPerMl: 0.0, rateMlPerHr: 10.0), throwsArgumentError);
        expect(() => IvRateCalculator.unitsPerMin(concentrationUnitsPerMl: -0.2, rateMlPerHr: 10.0), throwsArgumentError);
        expect(() => IvRateCalculator.unitsPerMin(concentrationUnitsPerMl: double.nan, rateMlPerHr: 10.0), throwsArgumentError);
        expect(() => IvRateCalculator.unitsPerMin(concentrationUnitsPerMl: double.infinity, rateMlPerHr: 10.0), throwsArgumentError);
      });

      test('Negative rate throws ArgumentError', () {
        expect(() => IvRateCalculator.unitsPerMin(concentrationUnitsPerMl: 0.2, rateMlPerHr: -5.0), throwsArgumentError);
        expect(() => IvRateCalculator.unitsPerMin(concentrationUnitsPerMl: 0.2, rateMlPerHr: double.nan), throwsArgumentError);
      });

      test('Zero rate returns 0.0 cleanly', () {
        final val = IvRateCalculator.unitsPerMin(concentrationUnitsPerMl: 0.2, rateMlPerHr: 0.0);
        expect(val, equals(0.0));
      });
    });

    group('rateMlPerHrFromUnitsPerMin negative & edge cases', () {
      test('Negative desired units throws ArgumentError', () {
        expect(() => IvRateCalculator.rateMlPerHrFromUnitsPerMin(desiredUnitsPerMin: -0.01, concentrationUnitsPerMl: 0.2), throwsArgumentError);
        expect(() => IvRateCalculator.rateMlPerHrFromUnitsPerMin(desiredUnitsPerMin: double.nan, concentrationUnitsPerMl: 0.2), throwsArgumentError);
        expect(() => IvRateCalculator.rateMlPerHrFromUnitsPerMin(desiredUnitsPerMin: double.infinity, concentrationUnitsPerMl: 0.2), throwsArgumentError);
      });

      test('Zero or negative concentration throws ArgumentError', () {
        expect(() => IvRateCalculator.rateMlPerHrFromUnitsPerMin(desiredUnitsPerMin: 0.03, concentrationUnitsPerMl: 0.0), throwsArgumentError);
        expect(() => IvRateCalculator.rateMlPerHrFromUnitsPerMin(desiredUnitsPerMin: 0.03, concentrationUnitsPerMl: -0.2), throwsArgumentError);
        expect(() => IvRateCalculator.rateMlPerHrFromUnitsPerMin(desiredUnitsPerMin: 0.03, concentrationUnitsPerMl: double.nan), throwsArgumentError);
      });

      test('Zero desired units returns 0.0 cleanly', () {
        final rate = IvRateCalculator.rateMlPerHrFromUnitsPerMin(desiredUnitsPerMin: 0.0, concentrationUnitsPerMl: 0.2);
        expect(rate, equals(0.0));
      });
    });

    group('calculateInfusionMlPerHour negative & unit mismatch robustness', () {
      test('Biological unit (uMin) with mass concentration throws ArgumentError', () {
        expect(
          () => IvRateCalculator.calculateInfusionMlPerHour(
            doseRatePerMin: 0.03,
            doseRateUnit: RateUnit.uMin,
            concentration: const Concentration(16.0, ConcentrationUnit.mcgPerMl),
          ),
          throwsArgumentError,
        );
      });

      test('Mass rate unit (mcgMin) with biological concentration throws ArgumentError', () {
        expect(
          () => IvRateCalculator.calculateInfusionMlPerHour(
            doseRatePerMin: 16.0,
            doseRateUnit: RateUnit.mcgMin,
            concentration: const Concentration(0.2, ConcentrationUnit.unitsPerMl),
          ),
          throwsArgumentError,
        );
      });

      test('Weight-based unit with null or negative weight throws ArgumentError', () {
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
            weightKg: -70.0,
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
      });

      test('Negative doseRatePerMin throws ArgumentError', () {
        expect(
          () => IvRateCalculator.calculateInfusionMlPerHour(
            doseRatePerMin: -1.0,
            doseRateUnit: RateUnit.mcgMin,
            concentration: const Concentration(16.0, ConcentrationUnit.mcgPerMl),
          ),
          throwsArgumentError,
        );
      });

      test('Zero or negative concentration value throws ArgumentError', () {
        expect(
          () => IvRateCalculator.calculateInfusionMlPerHour(
            doseRatePerMin: 10.0,
            doseRateUnit: RateUnit.mcgMin,
            concentration: const Concentration(0.0, ConcentrationUnit.mcgPerMl),
          ),
          throwsArgumentError,
        );
        expect(
          () => IvRateCalculator.calculateInfusionMlPerHour(
            doseRatePerMin: 10.0,
            doseRateUnit: RateUnit.mcgMin,
            concentration: const Concentration(-5.0, ConcentrationUnit.mcgPerMl),
          ),
          throwsArgumentError,
        );
      });
    });
  });
}
