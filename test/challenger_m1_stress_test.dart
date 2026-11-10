// ============================================================================
// Challenger 1 Empirical Stress Test Suite — Milestone 1
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:drug_dosage_calculator/data/patient_session.dart';
import 'package:drug_dosage_calculator/ui/iv_titration_screen.dart';
import 'package:drug_dosage_calculator/ui/calculator/models/calculator_ui_state.dart';
import 'package:drug_dosage_calculator/ui/calculator/widgets/dosage_result_card.dart';

void main() {
  setUpAll(() {
    DrugDatabase.warmUp();
  });

  group('Challenger M1.1: IvRateCalculator & RateUnit Conversions Stress Test', () {
    test('1.1: mcgMin conversions and round-trip identity across extreme scales', () {
      final testCases = [
        0.001, // 0.001 mcg/min
        0.1,
        1.0,
        10.0,
        100.0,
        5000.0, // massive dose
      ];

      final testConcs = [
        16.0, // 16 mcg/mL
        32.0,
        64.0,
        160.0,
        1000.0, // 1 mg/mL
      ];

      for (final desiredMcgMin in testCases) {
        for (final conc in testConcs) {
          final pumpRate = IvRateCalculator.rateMlPerHrFromMcgMin(
            desiredMcgMin: desiredMcgMin,
            concentrationMcgPerMl: conc,
          );
          expect(pumpRate.isFinite, isTrue);
          expect(pumpRate, greaterThanOrEqualTo(0.0));

          final recoveredMcgMin = IvRateCalculator.mcgPerMin(
            concentrationMcgPerMl: conc,
            rateMlPerHr: pumpRate,
          );
          expect(recoveredMcgMin, closeTo(desiredMcgMin, 1e-9));
        }
      }
    });

    test('1.2: uMin conversions and round-trip identity across extreme scales', () {
      final testCases = [
        0.001,
        0.01,
        0.03, // standard vasopressin dose
        0.04, // max vasopressin dose
        0.1,
        10.0,
      ];

      final testConcs = [
        0.2, // 20 units / 100 mL
        0.4, // 40 units / 100 mL
        1.0, // 50 units / 50 mL
      ];

      for (final desiredUMin in testCases) {
        for (final conc in testConcs) {
          final pumpRate = IvRateCalculator.rateMlPerHrFromUnitsPerMin(
            desiredUnitsPerMin: desiredUMin,
            concentrationUnitsPerMl: conc,
          );
          expect(pumpRate.isFinite, isTrue);
          expect(pumpRate, greaterThanOrEqualTo(0.0));

          final recoveredUMin = IvRateCalculator.unitsPerMin(
            concentrationUnitsPerMl: conc,
            rateMlPerHr: pumpRate,
          );
          expect(recoveredUMin, closeTo(desiredUMin, 1e-9));
        }
      }
    });

    test('1.3: IvRateCalculator boundary guards against zero and invalid inputs', () {
      // 0 mL/hr is valid and should return 0
      expect(
        IvRateCalculator.mcgPerMin(concentrationMcgPerMl: 16.0, rateMlPerHr: 0.0),
        equals(0.0),
      );
      expect(
        IvRateCalculator.unitsPerMin(concentrationUnitsPerMl: 0.2, rateMlPerHr: 0.0),
        equals(0.0),
      );
      expect(
        IvRateCalculator.rateMlPerHrFromMcgMin(desiredMcgMin: 0.0, concentrationMcgPerMl: 16.0),
        equals(0.0),
      );
      expect(
        IvRateCalculator.rateMlPerHrFromUnitsPerMin(desiredUnitsPerMin: 0.0, concentrationUnitsPerMl: 0.2),
        equals(0.0),
      );

      // Negative values must throw ArgumentError
      expect(
        () => IvRateCalculator.mcgPerMin(concentrationMcgPerMl: 16.0, rateMlPerHr: -1.0),
        throwsArgumentError,
      );
      expect(
        () => IvRateCalculator.unitsPerMin(concentrationUnitsPerMl: 0.2, rateMlPerHr: -1.0),
        throwsArgumentError,
      );
      expect(
        () => IvRateCalculator.rateMlPerHrFromMcgMin(desiredMcgMin: -5.0, concentrationMcgPerMl: 16.0),
        throwsArgumentError,
      );
      expect(
        () => IvRateCalculator.rateMlPerHrFromUnitsPerMin(desiredUnitsPerMin: -0.01, concentrationUnitsPerMl: 0.2),
        throwsArgumentError,
      );

      // Zero concentration must throw ArgumentError (division by zero guard)
      expect(
        () => IvRateCalculator.rateMlPerHrFromMcgMin(desiredMcgMin: 10.0, concentrationMcgPerMl: 0.0),
        throwsArgumentError,
      );
      expect(
        () => IvRateCalculator.rateMlPerHrFromUnitsPerMin(desiredUnitsPerMin: 0.03, concentrationUnitsPerMl: 0.0),
        throwsArgumentError,
      );

      // Non-finite values must throw ArgumentError
      expect(
        () => IvRateCalculator.mcgPerMin(concentrationMcgPerMl: double.infinity, rateMlPerHr: 10.0),
        throwsArgumentError,
      );
      expect(
        () => IvRateCalculator.rateMlPerHrFromMcgMin(desiredMcgMin: double.nan, concentrationMcgPerMl: 16.0),
        throwsArgumentError,
      );
    });

    test('1.4: calculateInfusionMlPerHour strictly rejects mismatched biological / mass units', () {
      // uMin with mg/mL concentration -> must throw ArgumentError
      expect(
        () => IvRateCalculator.calculateInfusionMlPerHour(
          doseRatePerMin: 0.03,
          doseRateUnit: RateUnit.uMin,
          concentration: const Concentration(1.0, ConcentrationUnit.mgPerMl),
        ),
        throwsArgumentError,
      );

      // mcgMin with units/mL concentration -> must throw ArgumentError
      expect(
        () => IvRateCalculator.calculateInfusionMlPerHour(
          doseRatePerMin: 10.0,
          doseRateUnit: RateUnit.mcgMin,
          concentration: const Concentration(0.2, ConcentrationUnit.unitsPerMl),
        ),
        throwsArgumentError,
      );
    });
  });

  group('Challenger M1.2: Reverse Titration Matrix Stress Test across Extreme Ranges', () {
    const rates = [0.0, 0.1, 500.0, 999.0];
    const weights = [0.4, 10.0, 70.0, 300.0]; // 0.4 kg neonate to 300 kg morbid obesity
    const dilutions = [16.0, 32.0, 64.0, 160.0]; // mcg/mL

    test('2.1: Mathematical Oracle for all 64 rate x weight x dilution combinations', () {
      for (final rate in rates) {
        for (final weight in weights) {
          for (final conc in dilutions) {
            final expectedMcgMin = (rate * conc) / 60.0;
            final expectedMcgKgMin = (rate * conc) / (weight * 60.0);

            final actualMcgMin = IvRateCalculator.mcgPerMin(
              concentrationMcgPerMl: conc,
              rateMlPerHr: rate,
            );
            final actualMcgKgMin = IvRateCalculator.mcgPerKgPerMin(
              concentrationMcgPerMl: conc,
              rateMlPerHr: rate,
              weightKg: weight,
            );

            expect(actualMcgMin.isFinite, isTrue);
            expect(actualMcgKgMin.isFinite, isTrue);
            expect(actualMcgMin, closeTo(expectedMcgMin, 1e-9));
            expect(actualMcgKgMin, closeTo(expectedMcgKgMin, 1e-9));

            if (rate == 0.0) {
              expect(actualMcgMin, equals(0.0));
              expect(actualMcgKgMin, equals(0.0));
            }

            if (weight == 0.4 && rate == 999.0 && conc == 160.0) {
              expect(actualMcgKgMin, closeTo(6660.0, 0.01));
            }

            if (weight == 300.0 && rate == 0.1 && conc == 16.0) {
              expect(actualMcgKgMin, closeTo(0.0000888888, 1e-8));
            }
          }
        }
      }
    });

    testWidgets('2.2: IVTitrationScreen reverse titration at boundary rates (0.1, 500, 999 mL/hr) for ELBW neonate (0.4 kg)', (tester) async {
      const neonate = Patient(
        id: 'p-neonate',
        weightKg: 0.4,
        heightCm: 30.0,
        ageYears: 0,
        sex: Sex.male,
        isScrStable: true,
        serumCreatinineMgDl: 0.4,
      );
      PatientSession.instance.setPatient(neonate);

      final norepi = DrugDatabase.findById('norepinephrine')!;
      final regimen = norepi.regimens.first;

      await tester.pumpWidget(
        MaterialApp(
          home: IVTitrationScreen(
            drug: norepi,
            regimen: regimen,
            isThai: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rateInput = find.byKey(const Key('iv_titration_reverse_rate_input'));
      expect(rateInput, findsOneWidget);

      // 1. Test 0.1 mL/hr at 16 mcg/mL for 0.4 kg:
      await tester.enterText(rateInput, '0.1');
      await tester.pumpAndSettle();

      expect(find.text('0.067 mcg/kg/min'), findsOneWidget);
      expect(find.text('(0.03 mcg/min)'), findsOneWidget);

      // 2. Test 500 mL/hr at 16 mcg/mL for 0.4 kg:
      await tester.enterText(rateInput, '500');
      await tester.pumpAndSettle();

      expect(find.text('333.333 mcg/kg/min'), findsOneWidget);
      expect(find.textContaining('WARNING'), findsOneWidget);

      // 3. Test 999 mL/hr at 16 mcg/mL for 0.4 kg:
      await tester.enterText(rateInput, '999');
      await tester.pumpAndSettle();

      expect(find.text('666.000 mcg/kg/min'), findsOneWidget);
      expect(find.textContaining('WARNING'), findsOneWidget);
    });

    testWidgets('2.3: IVTitrationScreen reverse titration at boundary rates for morbidly obese adult (300 kg)', (tester) async {
      const obese = Patient(
        id: 'p-obese-300',
        weightKg: 300.0,
        heightCm: 180.0,
        ageYears: 45,
        sex: Sex.male,
        isScrStable: true,
        serumCreatinineMgDl: 1.2,
      );
      PatientSession.instance.setPatient(obese);

      final norepi = DrugDatabase.findById('norepinephrine')!;
      final regimen = norepi.regimens.first;

      await tester.pumpWidget(
        MaterialApp(
          home: IVTitrationScreen(
            drug: norepi,
            regimen: regimen,
            isThai: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rateInput = find.byKey(const Key('iv_titration_reverse_rate_input'));

      // Test 999 mL/hr at 16 mcg/mL for 300 kg:
      await tester.enterText(rateInput, '999');
      await tester.pumpAndSettle();

      expect(find.text('0.888 mcg/kg/min'), findsOneWidget);
      expect(find.text('(266.40 mcg/min)'), findsOneWidget);
    });
  });

  group('Challenger M1.3: Multi-Phase Antidote (NAC 3-Bag Protocol) Across Weights', () {
    const weightsToTest = [50.0, 70.0, 100.0, 150.0];

    for (final weight in weightsToTest) {
      test('3.1: NAC calculation math for weight = $weight kg', () {
        final patient = Patient(
          id: 'p-nac-$weight',
          weightKg: weight,
          heightCm: 170.0,
          ageYears: 30,
          sex: Sex.female,
          isScrStable: true,
          serumCreatinineMgDl: 0.8,
        );

        final nac = DrugDatabase.findById('n_acetylcysteine')!;
        final regimen = nac.regimens.firstWhere((r) => r.route == DoseRoute.ivInfusion);

        final result = PharmacistCalculator.calculateDose(
          patient: patient,
          drug: nac,
          regimen: regimen,
        );

        expect(result.success, isTrue);
        expect(result.activePhases, isNotNull);
        expect(result.activePhases!.length, equals(3));

        final effectiveWeight = weight > 100.0 ? 100.0 : weight;

        // Phase 1 (Loading): 150 mg/kg
        final phase1 = result.activePhases![0];
        final p1Dose = phase1.dosePerKg! * effectiveWeight;
        expect(p1Dose, equals(150.0 * effectiveWeight));
        expect(phase1.durationHours, equals(1.0));

        // Phase 2 (Second dose): 50 mg/kg
        final phase2 = result.activePhases![1];
        final p2Dose = phase2.dosePerKg! * effectiveWeight;
        expect(p2Dose, equals(50.0 * effectiveWeight));
        expect(phase2.durationHours, equals(4.0));

        // Phase 3 (Third dose): 100 mg/kg
        final phase3 = result.activePhases![2];
        final p3Dose = phase3.dosePerKg! * effectiveWeight;
        expect(p3Dose, equals(100.0 * effectiveWeight));
        expect(phase3.durationHours, equals(16.0));

        final totalDose = p1Dose + p2Dose + p3Dose;
        expect(totalDose, equals(300.0 * effectiveWeight));

        if (weight > 100.0) {
          expect(totalDose, equals(30000.0));
          final hasCappedWarning = result.warnings.any((w) => w.messageEn.contains('capped at 100 kg'));
          expect(hasCappedWarning, isTrue);
        } else {
          expect(totalDose, equals(300.0 * weight));
        }
      });
    }

    testWidgets('3.2: DosageResultCard renders exact delivered doses and pump rates for 70 kg patient', (tester) async {
      const patient = Patient(
        id: 'p-nac-70',
        weightKg: 70.0,
        heightCm: 170.0,
        ageYears: 30,
        sex: Sex.male,
        isScrStable: true,
        serumCreatinineMgDl: 0.9,
      );

      final nac = DrugDatabase.findById('n_acetylcysteine')!;
      final regimen = nac.regimens.firstWhere((r) => r.route == DoseRoute.ivInfusion);

      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: nac,
        regimen: regimen,
      );

      final state = CalculatorUiState.initial(nac).copyWith(
        selectedRegimen: regimen,
        result: result,
        warnings: result.warnings,
        status: CalculatorUiStatus.active,
        lastEvaluatedPatient: patient,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DosageResultCard(
                state: state,
                isThai: false,
                onBuildPatient: () => patient,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dosage_result_multiphase_card')), findsOneWidget);

      // Phase 1: 150 mg/kg * 70 = 10,500 mg, in 200 mL, 1 hr -> 200 mL/hr
      expect(find.byKey(const Key('dosage_result_phase_0')), findsOneWidget);
      expect(find.text('10,500 mg'), findsOneWidget);
      expect(find.text('200 mL'), findsOneWidget);
      expect(find.text('200 mL/hr'), findsOneWidget);

      // Phase 2: 50 mg/kg * 70 = 3,500 mg, in 500 mL, 4 hr -> 125 mL/hr
      expect(find.byKey(const Key('dosage_result_phase_1')), findsOneWidget);
      expect(find.text('3,500 mg'), findsOneWidget);
      expect(find.text('500 mL'), findsOneWidget);
      expect(find.text('125 mL/hr'), findsOneWidget);

      // Phase 3: 100 mg/kg * 70 = 7,000 mg, in 1000 mL, 16 hr -> 62.5 mL/hr
      expect(find.byKey(const Key('dosage_result_phase_2')), findsOneWidget);
      expect(find.text('7,000 mg'), findsOneWidget);
      expect(find.text('1000 mL'), findsOneWidget);
      expect(find.text('62.5 mL/hr'), findsOneWidget);
    });

    testWidgets('3.3: DosageResultCard caps 150 kg obese patient at 100 kg ceiling', (tester) async {
      const patient = Patient(
        id: 'p-nac-150',
        weightKg: 150.0,
        heightCm: 170.0,
        ageYears: 30,
        sex: Sex.male,
        isScrStable: true,
        serumCreatinineMgDl: 0.9,
      );

      final nac = DrugDatabase.findById('n_acetylcysteine')!;
      final regimen = nac.regimens.firstWhere((r) => r.route == DoseRoute.ivInfusion);

      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: nac,
        regimen: regimen,
      );

      final state = CalculatorUiState.initial(nac).copyWith(
        selectedRegimen: regimen,
        result: result,
        warnings: result.warnings,
        status: CalculatorUiStatus.active,
        lastEvaluatedPatient: patient,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DosageResultCard(
                state: state,
                isThai: false,
                onBuildPatient: () => patient,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Patient weight 150.0 kg capped at 100 kg for maximum safe ceiling'), findsOneWidget);
      expect(find.text('15,000 mg'), findsOneWidget);
      expect(find.text('5,000 mg'), findsOneWidget);
      expect(find.text('10,000 mg'), findsOneWidget);
    });
  });

  group('Challenger M1.4: Rule 5 Non-Blocking Overdose Warning Verification', () {
    testWidgets('4.1: Vasopressin reverse titration triggers Rule 5 warning when pump rate exceeds max rate', (tester) async {
      const patient = Patient(
        id: 'p-vaso',
        weightKg: 70.0,
        heightCm: 170.0,
        ageYears: 50,
        sex: Sex.male,
        isScrStable: true,
        serumCreatinineMgDl: 1.0,
      );
      PatientSession.instance.setPatient(patient);

      final vasopressin = DrugDatabase.findById('vasopressin')!;
      final regimen = vasopressin.regimens.first; // max is 0.04 units/min

      await tester.pumpWidget(
        MaterialApp(
          home: IVTitrationScreen(
            drug: vasopressin,
            regimen: regimen,
            isThai: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Standard dilution is 0.2 units/mL.
      // Normal rate 0.03 units/min = 9.0 mL/hr.
      // Overdose rate: 15.0 mL/hr -> (15.0 * 0.2) / 60 = 0.05 units/min > 0.04 max!
      final rateInput = find.byKey(const Key('iv_titration_reverse_rate_input'));
      await tester.enterText(rateInput, '15.0');
      await tester.pumpAndSettle();

      // Non-blocking: Calculated dose must remain fully visible!
      expect(find.text('0.050 units/min'), findsOneWidget);

      // Warning banner must trigger prominently
      expect(find.textContaining('⚠️ คำเตือน: อัตรานี้เกินเกณฑ์สูงสุดที่แนะนำ'), findsOneWidget);
    });

    testWidgets('4.2: RateUnit.mcgMin non-weight-based drug reverse titration ceiling check and display integrity', (tester) async {
      const patient = Patient(
        id: 'p-mcgmin-test',
        weightKg: 70.0,
        heightCm: 170.0,
        ageYears: 50,
        sex: Sex.male,
        isScrStable: true,
        serumCreatinineMgDl: 1.0,
      );
      PatientSession.instance.setPatient(patient);

      // A mock non-weight-based vasopressor or vasodilator dosed in mcg/min
      // Max rate is 20.0 mcg/min. Concentration is 0.1 mg/mL = 100 mcg/mL.
      const mockDrug = Drug(
        id: 'mock_mcgmin_drug',
        genericName: 'Mock McgMin Infusion',
        nameTh: 'ยาวิจัยไมโครกรัมต่อนาที',
        category: DrugCategory.vasopressor,
        regimens: [
          DosingRegimen(
            route: DoseRoute.ivInfusion,
            indication: 'Fixed mcg/min Infusion',
            dosingType: DosingType.titrated,
            doseUnit: DoseUnit.mcg,
            continuousRateMin: 5.0,
            continuousRateMax: 20.0,
            continuousRateUnit: 'mcg/min',
            rateUnit: RateUnit.mcgMin,
            standardDilutionMgPerMl: 0.1, // 100 mcg/mL
            frequency: Frequency.continuous,
            limits: DoseLimit(
              maxInfusionRate: 20.0,
              infusionRateUnit: 'mcg/min',
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: IVTitrationScreen(
            drug: mockDrug,
            regimen: mockDrug.regimens.first,
            isThai: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter pump rate 30.0 mL/hr:
      // Delivered dose in mcg/min = (30.0 mL/hr * 100 mcg/mL) / 60 = 50.0 mcg/min.
      // This is 2.5x the maximum ceiling of 20.0 mcg/min!
      final rateInput = find.byKey(const Key('iv_titration_reverse_rate_input'));
      await tester.enterText(rateInput, '30.0');
      await tester.pumpAndSettle();

      // CHALLENGE:
      // Does it display the primary dose in mcg/min as defined by the regimen?
      // And does the ceiling warning trigger because 50 mcg/min > 20 mcg/min?
      expect(find.textContaining('WARNING'), findsOneWidget,
          reason: 'Rule 5 Overdose warning MUST trigger when 50 mcg/min exceeds 20 mcg/min ceiling!');
    });

    testWidgets('4.3: Dexmedetomidine (RateUnit.mcgKgHr) reverse titration ceiling check and display integrity', (tester) async {
      const patient = Patient(
        id: 'p-dex-test',
        weightKg: 80.0,
        heightCm: 175.0,
        ageYears: 55,
        sex: Sex.male,
        isScrStable: true,
        serumCreatinineMgDl: 1.0,
      );
      PatientSession.instance.setPatient(patient);

      final dex = DrugDatabase.findById('dexmedetomidine')!;
      final regimen = dex.regimens.first; // 0.2 - 1.4 mcg/kg/hr, standard dilution 4 mcg/mL

      await tester.pumpWidget(
        MaterialApp(
          home: IVTitrationScreen(
            drug: dex,
            regimen: regimen,
            isThai: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter pump rate 40.0 mL/hr:
      // Delivered rate in mcg/kg/hr = (40.0 mL/hr * 4 mcg/mL) / 80 kg = 2.0 mcg/kg/hr.
      // Maximum ceiling is 1.4 mcg/kg/hr. 2.0 > 1.4 -> Overdose warning must trigger!
      final rateInput = find.byKey(const Key('iv_titration_reverse_rate_input'));
      await tester.enterText(rateInput, '40.0');
      await tester.pumpAndSettle();

      // Primary header must display 2.000 mcg/kg/hr:
      expect(find.text('2.000 mcg/kg/hr'), findsOneWidget);

      // Warning banner must trigger prominently:
      expect(find.textContaining('WARNING'), findsOneWidget,
          reason: 'Rule 5 Overdose warning MUST trigger when 2.0 mcg/kg/hr exceeds 1.4 mcg/kg/hr ceiling!');
    });
  });
}
