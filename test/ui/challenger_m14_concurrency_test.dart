// ============================================================================
// Challenger M14 Adversarial Test Suite: Concurrency, Two-Way State Sync & NTI
// Target File: test/ui/challenger_m14_concurrency_test.dart
// ============================================================================

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/core/calculators/pk_simulation_engine.dart';
import 'package:drug_dosage_calculator/core/models/pk_model.dart';
import 'package:drug_dosage_calculator/data/patient_session.dart';
import 'package:drug_dosage_calculator/ui/calculator/controllers/calculator_controller.dart';
import 'package:drug_dosage_calculator/ui/calculator/models/calculator_ui_state.dart';
import 'package:drug_dosage_calculator/ui/calculator/widgets/dosage_result_card.dart';
import 'package:drug_dosage_calculator/ui/pkpd/controllers/pk_simulation_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const standardPatient = Patient(
    id: 'PT-ADVERSARIAL-001',
    patientName: 'Adversarial Patient',
    hospitalNumber: 'HN999999',
    weightKg: 70.0,
    heightCm: 175.0,
    ageYears: 45,
    sex: Sex.male,
    isScrStable: true,
    serumCreatinineMgDl: 1.0,
    creatinineClearanceMlMin: 80.0,
  );

  const vancoDrug = Drug(
    id: 'vancomycin',
    genericName: 'Vancomycin',
    brandNames: ['Vancocin'],
    category: DrugCategory.antibiotic,
    requiresTDM: true,
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Severe Sepsis',
        dosingType: DosingType.weightBased,
        dosePerKg: 15.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency(
          intervalHours: 12,
          displayEn: 'every 12 hours',
          displayTh: 'ทุก 12 ชั่วโมง',
        ),
        doseBasis: DoseBasis.perDose,
      ),
    ],
  );

  const baseParams = PkSimulationParams(
    modelType: PkModelType.oneCompartment,
    route: AdministrationRoute.ivIntermittentInfusion,
    dose: 1000.0,
    tau: 12.0,
    tInf: 1.0,
    pk1: PkParameters(vd: 49.0, ke: 0.0708),
    therapeuticWindow: TherapeuticWindow(
      mec: 10.0,
      mtc: 20.0,
      targetTroughMin: 10.0,
      targetTroughMax: 20.0,
      targetAuc24Min: 400.0,
      targetAuc24Max: 600.0,
    ),
    isSteadyState: true,
    horizonHours: 24.0,
    pointsPerPhase: 20,
  );

  // =========================================================================
  // Group 1: Sequence Token Debounce & Out-of-Order Race Stress Test
  // =========================================================================
  group('Group 1: Sequence Token Debounce & Out-of-Order Race Stress Test', () {
    test(
        'T1.1: 50 rapid parameter changes with randomized latency resolve to exact final token',
        () async {
      final random = Random(42);
      final executedRequests = <int, double>{};

      // Controller with randomized artificial delays simulating background isolate latency
      late final PkSimulationController controller;
      controller = PkSimulationController(
        drug: vancoDrug,
        patient: standardPatient,
        initialParams: baseParams,
        runner: (params) async {
          // Delay between 5ms and 50ms
          final delayMs = 5 + random.nextInt(45);
          await Future<void>.delayed(Duration(milliseconds: delayMs));
          return PkSimulationEngine.simulate(params);
        },
      );

      // Wait for initial simulation to settle
      await Future<void>.delayed(const Duration(milliseconds: 70));
      expect(controller.baselineResult, isNotNull);

      // Fire 50 rapid back-to-back parameter changes with randomized pacing (0..25ms)
      double expectedFinalDose = 1000.0;
      for (int i = 1; i <= 50; i++) {
        final newDose = 500.0 + (i * 30.0);
        expectedFinalDose = newDose;
        executedRequests[i] = newDose;

        controller.updateDose(newDose);

        final microWait = random.nextInt(25);
        if (microWait > 0) {
          await Future<void>.delayed(Duration(milliseconds: microWait));
        }
      }

      // Allow all pending timers (20ms debounce) and in-flight isolate runners to settle
      await Future<void>.delayed(const Duration(milliseconds: 400));

      // Assert final state matches the 50th request exactly
      expect(controller.adjustedResult, isNotNull);
      expect(controller.adjustedResult!.params.dose, equals(expectedFinalDose),
          reason: 'Active state must reflect the final parameter change');
      expect(controller.doseMg, equals(expectedFinalDose));
      expect(controller.isLoading, isFalse,
          reason: 'Controller must have completed loading after settle');
      expect(controller.errorMessage, isNull,
          reason: 'No errors should occur during rapid race execution');

      // Assert curve points are non-empty and correspond to the final dose
      final curve = controller.adjustedResult!.curve;
      expect(curve.isNotEmpty, isTrue);
      // Peak concentration of 2000mg must exceed baseline 1000mg
      expect(controller.adjustedResult!.cMax,
          greaterThan(controller.baselineResult!.cMax));

      controller.dispose();
    });

    test(
        'T1.2: Adversarial fast-after-slow race ensures slower earlier response never clobbers faster later response',
        () async {
      int runnerCallCount = 0;
      final controller = PkSimulationController(
        drug: vancoDrug,
        patient: standardPatient,
        initialParams: baseParams,
        runner: (params) async {
          runnerCallCount++;
          final callNum = runnerCallCount;
          if (callNum == 2) {
            // First update: intentionally very slow (120ms)
            await Future<void>.delayed(const Duration(milliseconds: 120));
          } else if (callNum == 3) {
            // Second update: very fast (5ms)
            await Future<void>.delayed(const Duration(milliseconds: 5));
          } else {
            await Future<void>.delayed(const Duration(milliseconds: 10));
          }
          return PkSimulationEngine.simulate(params);
        },
      );

      // Wait for initial simulation
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(runnerCallCount, equals(1));

      // Trigger first update (dose = 1200, will take 120ms)
      controller.updateDose(1200.0);
      await Future<void>.delayed(const Duration(milliseconds: 25)); // debounce expires, isolate starts

      // Trigger second update (dose = 1800, will take 5ms)
      controller.updateDose(1800.0);
      await Future<void>.delayed(const Duration(milliseconds: 25)); // debounce expires, isolate starts

      // At this point (approx t=55ms), request 3 (1800mg) completes around t=60ms
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(controller.adjustedResult!.params.dose, equals(1800.0));

      // Wait for the slower request 2 (1200mg) to finally complete at t=145ms
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Verify slower request 2 did NOT clobber request 3!
      expect(controller.adjustedResult!.params.dose, equals(1800.0),
          reason: 'Stale slower response must be discarded by sequence token');
      expect(controller.isLoading, isFalse);

      controller.dispose();
    });

    test(
        'T1.3: Reset to baseline during in-flight simulation does not get clobbered by stale runner',
        () async {
      final controller = PkSimulationController(
        drug: vancoDrug,
        patient: standardPatient,
        initialParams: baseParams,
        runner: (params) async {
          // 80ms delay
          await Future<void>.delayed(const Duration(milliseconds: 80));
          return PkSimulationEngine.simulate(params);
        },
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(controller.baselineResult, isNotNull);

      // User drags slider to 2500 mg
      controller.updateDose(2500.0);
      await Future<void>.delayed(const Duration(milliseconds: 25)); // debounce fires, runner starts

      // User immediately taps "Reset to Baseline" while isolate is running
      controller.resetToBaseline();
      expect(controller.doseMg, equals(1000.0));
      expect(controller.adjustedResult!.params.dose, equals(1000.0));

      // Wait for in-flight 80ms runner to finish
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Verify whether adjustedResult remained 1000.0 or was clobbered by 2500.0
      // Note: If the controller did not cancel/invalidate the in-flight request on resetToBaseline(),
      // this test surfaces the exact concurrency behavior!
      final finalDose = controller.adjustedResult!.params.dose;
      expect(finalDose, equals(1000.0),
          reason: 'Reset to baseline must not be overwritten by previous in-flight slider computation');

      controller.dispose();
    });
  });

  // =========================================================================
  // Group 2: Micro-Debounce Timer & Dispatch Cancellation Stress Test
  // =========================================================================
  group('Group 2: Micro-Debounce Timer & Dispatch Cancellation', () {
    test(
        'T2.1: 30 rapid slider updates within 2ms intervals cancel intermediate dispatches (exact runner count = 2)',
        () async {
      int runnerDispatches = 0;
      final controller = PkSimulationController(
        drug: vancoDrug,
        patient: standardPatient,
        initialParams: baseParams,
        runner: (params) async {
          runnerDispatches++;
          return PkSimulationEngine.simulate(params);
        },
      );

      // Wait for initial simulation
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(runnerDispatches, equals(1),
          reason: 'Initial simulation dispatches exactly once');

      // Rapidly fire 30 slider changes every 2ms (< 20ms debounce threshold)
      for (int i = 1; i <= 30; i++) {
        controller.updateDose(1000.0 + i * 10);
        await Future<void>.delayed(const Duration(milliseconds: 2));
      }

      // Right after loop, debounce timer of the 30th call has not yet elapsed (2ms < 20ms)
      expect(runnerDispatches, equals(1),
          reason: 'Intermediate dispatches must be cancelled before 20ms timer elapses');

      // Now wait 35ms for the final debounce timer to expire and execute
      await Future<void>.delayed(const Duration(milliseconds: 35));

      // Runner should have been dispatched exactly ONCE more
      expect(runnerDispatches, equals(2),
          reason: 'Only the final debounced parameter update should dispatch to isolate');
      expect(controller.doseMg, equals(1300.0));
      expect(controller.adjustedResult!.params.dose, equals(1300.0));

      controller.dispose();
    });

    test(
        'T2.2: Immediate trigger (updateInterval) cancels pending debounce and executes immediately',
        () async {
      int runnerDispatches = 0;
      final controller = PkSimulationController(
        drug: vancoDrug,
        patient: standardPatient,
        initialParams: baseParams,
        runner: (params) async {
          runnerDispatches++;
          return PkSimulationEngine.simulate(params);
        },
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(runnerDispatches, equals(1));

      // Start a debounced dose update
      controller.updateDose(1500.0);
      expect(runnerDispatches, equals(1));

      // At 5ms (before 20ms debounce timer), user selects interval tau = 24h (immediate trigger)
      await Future<void>.delayed(const Duration(milliseconds: 5));
      controller.updateInterval(24.0);

      // updateInterval cancels debounce timer and triggers immediate dispatch
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(runnerDispatches, equals(2),
          reason: 'Immediate trigger must dispatch without waiting for the 20ms debounce');
      expect(controller.tauHours, equals(24.0));

      controller.dispose();
    });
  });

  // =========================================================================
  // Group 3: Two-Way Patient State Synchronization Stress Test
  // =========================================================================
  group('Group 3: Two-Way Patient State Synchronization Stress Test', () {
    setUp(() {
      PatientSession.instance.clearPatient();
      PatientSession.instance.wardPatients.value = [];
    });

    test(
        'T3.1: calculate() synchronizes all patient parameters to PatientSession and updates wardPatients in-place',
        () {
      final controller = CalculatorController(drug: vancoDrug);

      controller.weightCtrl.text = '84.5';
      controller.heightCtrl.text = '182.0';
      controller.ageCtrl.text = '52';
      controller.scrCtrl.text = '1.35';
      controller.setSex(Sex.female);
      controller.setScrStable(true);
      controller.setRenalReplacementMode(RenalReplacementMode.ihd);
      controller.setHepaticImpairment(ChildPughClass.classB, score: 8);
      controller.selectRegimen(vancoDrug.regimens.first);

      final val = controller.calculate(isThai: true);
      expect(val.isValid, isTrue);

      final current = PatientSession.instance.currentPatient.value;
      expect(current, isNotNull);
      expect(current!.weightKg, equals(84.5));
      expect(current.heightCm, equals(182.0));
      expect(current.ageYears, equals(52));
      expect(current.serumCreatinineMgDl, equals(1.35));
      expect(current.sex, equals(Sex.female));
      expect(current.isScrStable, isTrue);
      expect(current.renalReplacementMode, equals(RenalReplacementMode.ihd));
      expect(current.hepaticImpairment, equals(ChildPughClass.classB));

      // Verify wardPatients list contains the saved patient
      final wardList = PatientSession.instance.wardPatients.value;
      expect(wardList.length, equals(1));
      expect(wardList.first.id, equals(current.id));
      expect(wardList.first.weightKg, equals(84.5));

      // Mutate weight and recalculate -> verify in-place update without creating duplicate patient
      controller.weightCtrl.text = '86.0';
      final val2 = controller.calculate(isThai: true);
      expect(val2.isValid, isTrue);

      final updatedWardList = PatientSession.instance.wardPatients.value;
      expect(updatedWardList.length, equals(1),
          reason: 'Subsequent calculate() must update existing patient in-place rather than appending duplicates');
      expect(updatedWardList.first.weightKg, equals(86.0));

      controller.dispose();
    });

    test(
        'T3.2: External PatientSession update updates CalculatorController without resetting text cursor or creating re-entrant loop',
        () {
      final controller = CalculatorController(drug: vancoDrug);

      // Set initial text and cursor
      controller.weightCtrl.text = '75.0';
      controller.weightCtrl.selection =
          const TextSelection.collapsed(offset: 4);

      int sessionNotifyCount = 0;
      void listener() {
        sessionNotifyCount++;
      }
      PatientSession.instance.currentPatient.addListener(listener);

      // External update with matching weight value (e.g. ward background refresh)
      PatientSession.instance.updateCurrentPatient(
        weightKg: 75.0,
        heightCm: 175.0,
        ageYears: 48,
        serumCreatinineMgDl: 1.1,
      );

      // Weight text controller must NOT reassign text when numeric value matches
      expect(controller.weightCtrl.text, equals('75.0'));
      expect(controller.weightCtrl.selection.baseOffset, equals(4),
          reason: 'Cursor position must be preserved during external sync if value is unchanged');

      // Changed fields must update
      expect(controller.ageCtrl.text, equals('48'));
      expect(controller.scrCtrl.text, equals('1.1'));

      // Ensure no circular infinite sync loop
      expect(sessionNotifyCount, equals(1));

      PatientSession.instance.currentPatient.removeListener(listener);
      controller.dispose();
    });

    test(
        'T3.3: Partial / malformed inputs do NOT leak into PatientSession and preserve previous valid clinical state',
        () {
      // 1. Establish baseline valid patient in session
      final initialPt = PatientSession.instance.updateCurrentPatient(
        weightKg: 70.0,
        heightCm: 170.0,
        ageYears: 40,
        serumCreatinineMgDl: 1.0,
        sex: Sex.male,
      );
      expect(initialPt.weightKg, equals(70.0));

      final controller = CalculatorController(drug: vancoDrug);
      expect(controller.weightCtrl.text, equals('70.0'));

      // 2. Clinician starts typing partial / invalid values
      controller.weightCtrl.text = '7'; // Incomplete weight (7 kg -> implausible BMI for 170cm)
      controller.scrCtrl.text = '.'; // Incomplete floating point string
      controller.ageCtrl.text = '999'; // Out of range age

      // 3. Clinician switches sex or RRT toggle
      controller.setSex(Sex.female);
      controller.setRenalReplacementMode(RenalReplacementMode.crrt);

      // 4. Assert inputs are invalid
      final valResult = controller.validateInputs();
      expect(valResult.isValid, isFalse);

      // 5. Critical check: PatientSession MUST NOT have been polluted with '7', '.', or '999'
      final sessionPt = PatientSession.instance.currentPatient.value;
      expect(sessionPt, isNotNull);
      expect(sessionPt!.weightKg, equals(70.0),
          reason: 'Invalid weight must not leak into PatientSession');
      expect(sessionPt.serumCreatinineMgDl, equals(1.0),
          reason: 'Invalid SCr must not leak into PatientSession');
      expect(sessionPt.ageYears, equals(40),
          reason: 'Invalid age must not leak into PatientSession');

      // 6. Clinician taps calculate() with invalid inputs
      final calcResult = controller.calculate(isThai: true);
      expect(calcResult.isValid, isFalse);
      expect(controller.state.status, equals(CalculatorUiStatus.error));

      // Session remains strictly unpolluted
      final sessionPtAfterCalc = PatientSession.instance.currentPatient.value;
      expect(sessionPtAfterCalc!.weightKg, equals(70.0));

      controller.dispose();
    });
  });

  // =========================================================================
  // Group 4: Dynamic NTI & Simulation Candidate Predicate Stress Test
  // =========================================================================
  group('Group 4: Dynamic NTI & Simulation Candidate Predicate Stress Test', () {
    Drug makeDrug({
      required String id,
      required String genericName,
      required DrugCategory category,
      bool requiresTDM = false,
      List<DosingRegimen> regimens = const [],
    }) {
      return Drug(
        id: id,
        genericName: genericName,
        category: category,
        requiresTDM: requiresTDM,
        regimens: regimens,
      );
    }

    test('T4.1: Exhaustive test across all 10+ drug categories and NTI keywords', () {
      // 1. Antibiotics
      expect(isNtiOrSimulationCandidate(makeDrug(id: 'vancomycin', genericName: 'Vancomycin', category: DrugCategory.antibiotic), null, null), isTrue);
      expect(isNtiOrSimulationCandidate(makeDrug(id: 'gentamicin', genericName: 'Gentamicin', category: DrugCategory.antibiotic), null, null), isTrue);
      expect(isNtiOrSimulationCandidate(makeDrug(id: 'amikacin', genericName: 'Amikacin', category: DrugCategory.antibiotic), null, null), isTrue);
      expect(isNtiOrSimulationCandidate(makeDrug(id: 'tobramycin', genericName: 'Tobramycin', category: DrugCategory.antibiotic), null, null), isTrue);
      expect(isNtiOrSimulationCandidate(makeDrug(id: 'amoxicillin', genericName: 'Amoxicillin', category: DrugCategory.antibiotic), null, null), isFalse);
      expect(isNtiOrSimulationCandidate(makeDrug(id: 'ceftriaxone', genericName: 'Ceftriaxone', category: DrugCategory.antibiotic), null, null), isFalse);
      expect(isNtiOrSimulationCandidate(makeDrug(id: 'meropenem', genericName: 'Meropenem', category: DrugCategory.antibiotic), null, null), isFalse);

      // 2. Cardiovascular
      expect(isNtiOrSimulationCandidate(makeDrug(id: 'digoxin', genericName: 'Digoxin', category: DrugCategory.cardiovascular), null, null), isTrue);
      expect(isNtiOrSimulationCandidate(makeDrug(id: 'metoprolol', genericName: 'Metoprolol', category: DrugCategory.cardiovascular), null, null), isFalse);
      expect(isNtiOrSimulationCandidate(makeDrug(id: 'amlodipine', genericName: 'Amlodipine', category: DrugCategory.cardiovascular), null, null), isFalse);

      // 3. Anticonvulsants
      expect(isNtiOrSimulationCandidate(makeDrug(id: 'phenytoin', genericName: 'Phenytoin', category: DrugCategory.anticonvulsant), null, null), isTrue);
      expect(isNtiOrSimulationCandidate(makeDrug(id: 'carbamazepine', genericName: 'Carbamazepine', category: DrugCategory.anticonvulsant), null, null), isTrue);
      expect(isNtiOrSimulationCandidate(makeDrug(id: 'valproic_acid', genericName: 'Sodium Valproate', category: DrugCategory.anticonvulsant), null, null), isTrue);
      expect(isNtiOrSimulationCandidate(makeDrug(id: 'levetiracetam', genericName: 'Levetiracetam', category: DrugCategory.anticonvulsant), null, null), isFalse);

      // 4. Respiratory
      expect(isNtiOrSimulationCandidate(makeDrug(id: 'theophylline', genericName: 'Theophylline', category: DrugCategory.respiratory), null, null), isTrue);
      expect(isNtiOrSimulationCandidate(makeDrug(id: 'aminophylline', genericName: 'Aminophylline', category: DrugCategory.respiratory), null, null), isTrue);
      expect(isNtiOrSimulationCandidate(makeDrug(id: 'salbutamol', genericName: 'Salbutamol', category: DrugCategory.respiratory), null, null), isFalse);

      // 5. Psychiatric
      expect(isNtiOrSimulationCandidate(makeDrug(id: 'lithium', genericName: 'Lithium Carbonate', category: DrugCategory.psychiatric), null, null), isTrue);
      expect(isNtiOrSimulationCandidate(makeDrug(id: 'sertraline', genericName: 'Sertraline', category: DrugCategory.psychiatric), null, null), isFalse);

      // 6. Immunosuppressants
      expect(isNtiOrSimulationCandidate(makeDrug(id: 'tacrolimus', genericName: 'Tacrolimus', category: DrugCategory.immunosuppressant), null, null), isTrue);
      expect(isNtiOrSimulationCandidate(makeDrug(id: 'cyclosporine', genericName: 'Cyclosporine', category: DrugCategory.immunosuppressant), null, null), isTrue);
      expect(isNtiOrSimulationCandidate(makeDrug(id: 'mycophenolate', genericName: 'Mycophenolate Mofetil', category: DrugCategory.immunosuppressant), null, null), isFalse);

      // 7. Vasopressors & Inotropes (Category & Keyword checks)
      expect(isNtiOrSimulationCandidate(makeDrug(id: 'custom_vaso', genericName: 'Custom Vaso', category: DrugCategory.vasopressor), null, null), isTrue);
      expect(isNtiOrSimulationCandidate(makeDrug(id: 'norepinephrine', genericName: 'Norepinephrine', category: DrugCategory.emergency), null, null), isTrue);
      expect(isNtiOrSimulationCandidate(makeDrug(id: 'epinephrine', genericName: 'Adrenaline', category: DrugCategory.emergency), null, null), isTrue);
      expect(isNtiOrSimulationCandidate(makeDrug(id: 'dopamine', genericName: 'Dopamine HCl', category: DrugCategory.emergency), null, null), isTrue);
      expect(isNtiOrSimulationCandidate(makeDrug(id: 'dobutamine', genericName: 'Dobutamine', category: DrugCategory.emergency), null, null), isTrue);
      expect(isNtiOrSimulationCandidate(makeDrug(id: 'nicardipine', genericName: 'Nicardipine', category: DrugCategory.antihypertensive), null, null), isTrue);
      expect(isNtiOrSimulationCandidate(makeDrug(id: 'nitroglycerin', genericName: 'Nitroglycerin', category: DrugCategory.cardiovascular), null, null), isTrue);

      // 8. Analgesics & NSAIDs
      expect(isNtiOrSimulationCandidate(makeDrug(id: 'paracetamol', genericName: 'Paracetamol', category: DrugCategory.analgesic), null, null), isFalse);
      expect(isNtiOrSimulationCandidate(makeDrug(id: 'ibuprofen', genericName: 'Ibuprofen', category: DrugCategory.nsaid), null, null), isFalse);

      // 9. Gastrointestinal
      expect(isNtiOrSimulationCandidate(makeDrug(id: 'omeprazole', genericName: 'Omeprazole', category: DrugCategory.gastrointestinal), null, null), isFalse);

      // 10. Anticoagulants
      expect(isNtiOrSimulationCandidate(makeDrug(id: 'warfarin', genericName: 'Warfarin', category: DrugCategory.anticoagulant), null, null), isFalse);
      expect(isNtiOrSimulationCandidate(makeDrug(id: 'warfarin', genericName: 'Warfarin', category: DrugCategory.anticoagulant, requiresTDM: true), null, null), isTrue);
    });

    test('T4.2: Continuous IV infusion route and titration results trigger candidate predicate', () {
      final nonNtiDrug = makeDrug(
        id: 'esomeprazole',
        genericName: 'Esomeprazole',
        category: DrugCategory.gastrointestinal,
      );

      // Standard IV Push / Bolus regimen -> false
      const ivPushRegimen = DosingRegimen(
        route: DoseRoute.ivPush,
        indication: 'Peptic Ulcer Bleed',
        dosingType: DosingType.fixed,
        fixedDose: 40.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q24h,
      );
      expect(isNtiOrSimulationCandidate(nonNtiDrug, ivPushRegimen, null), isFalse);

      // Continuous IV Infusion regimen -> true
      const ivInfusionRegimen = DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Upper GI Bleed Continuous Infusion',
        dosingType: DosingType.fixed,
        fixedDose: 8.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.continuous,
      );
      expect(isNtiOrSimulationCandidate(nonNtiDrug, ivInfusionRegimen, null), isTrue);

      // Active Titration / Infusion result present -> true
      const titratedResult = DosageResult(
        success: true,
        calculatedDose: 8.0,
        formulaUsed: 'Continuous Infusion',
        infusionResult: InfusionResult(
          rate: 8.0,
          rateUnit: RateUnit.mgHr,
          rateMlPerHr: 8.0,
        ),
      );
      expect(isNtiOrSimulationCandidate(nonNtiDrug, ivPushRegimen, titratedResult), isTrue);
    });

    test('T4.3: Case insensitivity, empty strings, and null robustness', () {
      // Mixed case
      expect(isNtiOrSimulationCandidate(makeDrug(id: 'VANCOMYCIN', genericName: 'VaNcOcIn', category: DrugCategory.antibiotic), null, null), isTrue);
      expect(isNtiOrSimulationCandidate(makeDrug(id: 'EPINEPHRINE', genericName: 'AdReNaLiNe', category: DrugCategory.emergency), null, null), isTrue);

      // Empty drug attributes
      expect(isNtiOrSimulationCandidate(makeDrug(id: '', genericName: '', category: DrugCategory.other), null, null), isFalse);
    });
  });

  // =========================================================================
  // Group 5: Scrubber Binary Search & Numerical Edge Cases
  // =========================================================================
  group('Group 5: Scrubber Binary Search & Numerical Edge Cases', () {
    test('T5.1: Boundary pinning and clamp behavior for negative and beyond-horizon times', () async {
      final controller = PkSimulationController(
        drug: vancoDrug,
        patient: standardPatient,
        initialParams: baseParams,
        runner: (p) async => PkSimulationEngine.simulate(p),
      );

      await Future<void>.delayed(const Duration(milliseconds: 30));
      final curve = controller.adjustedResult!.curve;
      expect(curve.isNotEmpty, isTrue);

      // Negative time -> clamps to curve.first
      controller.setScrubberTime(-5.0);
      expect(controller.activeAdjustedScrubberPoint, equals(curve.first));

      // Time beyond horizon -> clamps to curve.last
      controller.setScrubberTime(100.0);
      expect(controller.activeAdjustedScrubberPoint, equals(curve.last));

      // Exact zero -> curve.first
      controller.setScrubberTime(0.0);
      expect(controller.activeAdjustedScrubberPoint, equals(curve.first));

      // Null -> clears scrubber point
      controller.setScrubberTime(null);
      expect(controller.activeAdjustedScrubberPoint, isNull);

      controller.dispose();
    });

    test('T5.2: NaN target time in touch scrubber is handled gracefully without RangeError crash', () async {
      final controller = PkSimulationController(
        drug: vancoDrug,
        patient: standardPatient,
        initialParams: baseParams,
        runner: (p) async => PkSimulationEngine.simulate(p),
      );

      await Future<void>.delayed(const Duration(milliseconds: 30));

      // Touch scrubber should guard against NaN and not crash the UI with RangeError
      expect(
        () => controller.setScrubberTime(double.nan),
        returnsNormally,
        reason: 'Touch scrubber must guard against NaN to prevent RangeError: -1 crash',
      );

      controller.dispose();
    });
  });
}
