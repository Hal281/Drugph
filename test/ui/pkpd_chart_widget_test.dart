// ============================================================================
// Automated Widget Test Suite: PK-PD Simulation & Accessible CDSS UI
// Target File: test/ui/pkpd_chart_widget_test.dart
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/core/calculators/pk_simulation_engine.dart';
import 'package:drug_dosage_calculator/core/models/pk_model.dart';
import 'package:drug_dosage_calculator/data/patient_session.dart';
import 'package:drug_dosage_calculator/ui/calculator/controllers/calculator_controller.dart';
import 'package:drug_dosage_calculator/ui/calculator/models/calculator_ui_state.dart';
import 'package:drug_dosage_calculator/ui/calculator/widgets/dosage_result_card.dart';
import 'package:drug_dosage_calculator/ui/pkpd/controllers/pk_simulation_controller.dart';
import 'package:drug_dosage_calculator/ui/pkpd/pkpd_simulation_sheet.dart';
import 'package:drug_dosage_calculator/ui/pkpd/widgets/pk_chart_painter.dart';
import 'package:drug_dosage_calculator/ui/pkpd/widgets/pk_data_table.dart';
import 'package:drug_dosage_calculator/ui/pkpd/widgets/pk_parameter_sliders.dart';
import 'package:drug_dosage_calculator/ui/pkpd/widgets/steady_state_pk_chart.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Standard Test Patient
  const testPatient = Patient(
    id: 'PT-TEST-001',
    patientName: 'Test Patient',
    hospitalNumber: 'HN123456',
    weightKg: 70.0,
    heightCm: 175.0,
    ageYears: 45,
    sex: Sex.male,
    isScrStable: true,
    serumCreatinineMgDl: 1.0,
    creatinineClearanceMlMin: 80.0,
  );

  // Standard Vancomycin Drug
  const vancoDrug = Drug(
    id: 'vancomycin',
    genericName: 'Vancomycin',
    brandNames: ['Vancocin'],
    category: DrugCategory.antibiotic,
    requiresTDM: true,
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'MRSA Sepsis',
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

  // Synchronous Test Runner for PkSimulationEngine
  Future<PkSimulationResult> testRunner(PkSimulationParams params) async {
    return PkSimulationEngine.simulate(params);
  }

  // Precomputed baseline and adjusted results
  const baselineParams = PkSimulationParams(
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

  final adjustedParams = baselineParams.copyWith(dose: 1250.0);

  final baselineResult = PkSimulationEngine.simulate(baselineParams);
  final adjustedResult = PkSimulationEngine.simulate(adjustedParams);

  // =========================================================================
  // Group 1: CustomPainter Rendering & Multi-Band Shading
  // =========================================================================
  group('Group 1: PkChartPainter & SteadyStatePkChart Rendering', () {
    testWidgets('T1.1: Multi-Band Shading and dual curves render in CustomPaint',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SteadyStatePkChart(
              adjustedResult: adjustedResult,
              baselineResult: baselineResult,
              window: baselineParams.therapeuticWindow,
              isThai: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify widget presence
      expect(find.byType(SteadyStatePkChart), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);

      // Verify CustomPaint uses PkChartPainter
      final customPaintFinder = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is PkChartPainter,
      );
      expect(customPaintFinder, findsOneWidget);

      final customPaint = tester.widget<CustomPaint>(customPaintFinder);
      final painter = customPaint.painter as PkChartPainter;
      expect(painter.adjustedResult, equals(adjustedResult));
      expect(painter.baselineResult, equals(baselineResult));
      expect(painter.window, equals(baselineParams.therapeuticWindow));

      // Verify Legend labels
      expect(find.text('สูตรปรับปรุง (Adjusted)'), findsOneWidget);
      expect(find.text('สูตรเดิม (Baseline)'), findsOneWidget);
      expect(find.text('ช่วงเป้าหมาย (MEC)'), findsOneWidget);
      expect(find.text('ขีดจำกัดพิษ (MTC)'), findsOneWidget);
    });

    testWidgets('T1.2: Overdose and Distribution Phase banners display properly',
        (tester) async {
      final overdoseParams = baselineParams.copyWith(dose: 4000.0);
      final overdoseResult = PkSimulationEngine.simulate(overdoseParams);
      expect(overdoseResult.hasOverdoseWarning, isTrue);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SteadyStatePkChart(
              adjustedResult: overdoseResult,
              window: overdoseParams.therapeuticWindow,
              isThai: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Rule 5 Overdose banner must be displayed
      expect(
        find.textContaining('Overdose Warning'),
        findsOneWidget,
      );
    });

    testWidgets('T1.3: Empty curve points render gracefully without crash',
        (tester) async {
      const emptyResult = PkSimulationResult(
        params: baselineParams,
        curve: [],
        cMax: 0.0,
        cMin: 0.0,
        tMax: 0.0,
        auc0To24: 0.0,
        aucTotal: 0.0,
        ke: 0.05,
        tHalf: 13.8,
        accumulationFactor: 1.0,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SteadyStatePkChart(
              adjustedResult: emptyResult,
              isThai: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SteadyStatePkChart), findsOneWidget);
    });
  });

  // =========================================================================
  // Group 2: Touch Scrubber Gestures & Crosshair Tooltip
  // =========================================================================
  group('Group 2: Scrubber Gestures & Floating Tooltip Pill', () {
    testWidgets('T2.1: Horizontal drag updates scrubber time and triggers callback',
        (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      double? reportedTime;
      double? reportedAdj;
      double? reportedBase;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SteadyStatePkChart(
              adjustedResult: adjustedResult,
              baselineResult: baselineResult,
              window: baselineParams.therapeuticWindow,
              isThai: true,
              onScrubChanged: (t, adj, base) {
                reportedTime = t;
                reportedAdj = adj;
                reportedBase = base;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final chartCenter = tester.getCenter(find.byType(SteadyStatePkChart));

      // Drag across canvas
      final gesture = await tester.startGesture(chartCenter);
      await gesture.moveBy(const Offset(60, 0));
      await tester.pump();

      expect(reportedTime, isNotNull);
      expect(reportedTime! > 0, isTrue);
      expect(reportedAdj, isNotNull);
      expect(reportedAdj! > 0, isTrue);
      expect(reportedBase, isNotNull);
      expect(reportedBase! > 0, isTrue);

      await gesture.up();
      await tester.pump();
    });

    testWidgets('T2.2: Tap down updates scrubber immediately', (tester) async {
      double? tappedTime;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SteadyStatePkChart(
              adjustedResult: adjustedResult,
              isThai: true,
              onScrubChanged: (t, adj, base) {
                tappedTime = t;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final chartCenter = tester.getCenter(find.byType(SteadyStatePkChart));
      await tester.tapAt(chartCenter);
      await tester.pump();

      expect(tappedTime, isNotNull);
    });
  });

  // =========================================================================
  // Group 3: Accessible Data Table Fallback & EMR TSV Clipboard Copy
  // =========================================================================
  group('Group 3: Accessible Data Table Fallback & TSV Copy', () {
    late List<MethodCall> clipboardLog;

    setUp(() {
      clipboardLog = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboardLog.add(call);
        }
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    testWidgets('T3.1: SegmentedButton toggles view mode between Chart and Table',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PkPdSimulationSheet(
              drug: vancoDrug,
              regimen: vancoDrug.regimens.first,
              patient: testPatient,
              isThai: true,
              runner: testRunner,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially chart is visible
      expect(find.byType(SteadyStatePkChart), findsOneWidget);
      expect(find.byType(PkDataTable), findsNothing);

      // Tap Segmented button for table
      final tableSegmentFinder = find.byKey(const Key('pkpd_view_mode_segmented_btn'));
      expect(tableSegmentFinder, findsOneWidget);

      await tester.tap(find.text('📋 ตารางข้อมูล (Data Table)'));
      await tester.pumpAndSettle();

      // Chart hidden, Table visible
      expect(find.byType(PkDataTable), findsOneWidget);
      expect(find.byType(SteadyStatePkChart), findsNothing);
    });

    testWidgets('T3.2: PkDataTable displays 6 columns and copies TSV to clipboard',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PkDataTable(
                adjustedResult: adjustedResult,
                baselineResult: baselineResult,
                therapeuticWindow: baselineParams.therapeuticWindow,
                isThai: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify columns
      expect(find.text('เวลา (ชม.)'), findsOneWidget);
      expect(find.text('สถานะ'), findsOneWidget);
      expect(find.text('สูตรปรับ (mg/L)'), findsOneWidget);
      expect(find.text('สูตรเดิม (mg/L)'), findsOneWidget);
      expect(find.text('ผลต่าง (Δ%)'), findsOneWidget);
      expect(find.text('ช่วงทางคลินิก'), findsOneWidget);

      // Verify Copy TSV button
      final copyBtn = find.byKey(const Key('pk_data_table_copy_tsv_btn'));
      expect(copyBtn, findsOneWidget);

      await tester.tap(copyBtn);
      await tester.pump();

      // Check clipboard payload
      expect(clipboardLog.length, equals(1));
      final text = clipboardLog.first.arguments['text'] as String;
      expect(text, contains('PK-PD DOSING SIMULATION TABLE'));
      expect(text, contains('Time (hr)\tPhase\tAdjusted (mg/L)\tBaseline (mg/L)\tDelta (%)\tClinical Zone'));

      // Check floating SnackBar
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('คัดลอกตารางข้อมูลระดับยา (TSV) แล้ว'), findsOneWidget);
    });
  });

  // =========================================================================
  // Group 4: Parameter Sliders & Live Red Man Syndrome Warning
  // =========================================================================
  group('Group 4: Parameter Sliders & Vancomycin Safety Alerts', () {
    testWidgets('T4.1: Parameter sliders trigger callbacks on manipulation',
        (tester) async {
      double? changedCrcl;
      double? changedDose;
      double? changedTau;
      double? changedTInf;
      bool resetCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PkParameterSliders(
                crclMlMin: 80.0,
                baselineCrclMlMin: 80.0,
                currentDoseMg: 1000.0,
                baselineDoseMg: 1000.0,
                currentTauHours: 12.0,
                baselineTauHours: 12.0,
                currentTInfHours: 1.0,
                baselineTInfHours: 1.0,
                drug: vancoDrug,
                isThai: true,
                onCrclChanged: (v) => changedCrcl = v,
                onDoseChanged: (v) => changedDose = v,
                onTauChanged: (v) => changedTau = v,
                onTInfChanged: (v) => changedTInf = v,
                onResetToBaseline: () => resetCalled = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Drag CrCl slider
      final sliders = find.byType(Slider);
      expect(sliders, findsNWidgets(2));
      await tester.drag(sliders.at(0), const Offset(50, 0));
      await tester.pump();
      expect(changedCrcl, isNotNull);

      // Drag Dose slider
      await tester.drag(sliders.at(1), const Offset(50, 0));
      await tester.pump();
      expect(changedDose, isNotNull);

      // Tap q8h chip
      await tester.tap(find.byKey(const Key('pk_chip_tau_8h')));
      await tester.pump();
      expect(changedTau, equals(8.0));

      // Tap 2.0 hr tInf chip
      await tester.tap(find.byKey(const Key('pk_chip_tinf_2_0h')));
      await tester.pump();
      expect(changedTInf, equals(2.0));

      // Tap reset button
      await tester.tap(find.byKey(const Key('pk_sliders_reset_btn')));
      await tester.pump();
      expect(resetCalled, isTrue);
    });

    testWidgets('T4.2: Red Man Syndrome alert appears when Vancomycin rate > 10 mg/min',
        (tester) async {
      double? autoAdjustedTInf;

      // 1500 mg in 1.0 h = 25 mg/min > 10 mg/min ceiling
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PkParameterSliders(
                crclMlMin: 80.0,
                baselineCrclMlMin: 80.0,
                currentDoseMg: 1500.0,
                baselineDoseMg: 1000.0,
                currentTauHours: 12.0,
                baselineTauHours: 12.0,
                currentTInfHours: 1.0,
                baselineTInfHours: 1.0,
                drug: vancoDrug,
                isThai: true,
                onCrclChanged: (_) {},
                onDoseChanged: (_) {},
                onTauChanged: (_) {},
                onTInfChanged: (v) => autoAdjustedTInf = v,
                onResetToBaseline: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Red Man Syndrome warning banner must be visible
      expect(find.byKey(const Key('pk_red_man_syndrome_alert')), findsOneWidget);
      expect(find.textContaining('เสี่ยงเกิด Red Man Syndrome'), findsOneWidget);

      // Tap one-tap auto adjust button
      final autoAdjustBtn = find.byKey(const Key('pk_red_man_auto_adjust_btn'));
      expect(autoAdjustBtn, findsOneWidget);

      await tester.tap(autoAdjustBtn);
      await tester.pump();

      // 1500 mg / 600 = 2.5 hr
      expect(autoAdjustedTInf, equals(2.5));
    });
  });

  // =========================================================================
  // Group 5: CDSS Integration & DosageResultCard NTI Entry Point
  // =========================================================================
  group('Group 5: DosageResultCard NTI Entry & Predicate', () {
    test('T5.1: isNtiOrSimulationCandidate correctly identifies candidate drugs', () {
      const gentamicin = Drug(
        id: 'gentamicin',
        genericName: 'Gentamicin',
        category: DrugCategory.antibiotic,
        requiresTDM: true,
        regimens: [],
      );
      const phenytoin = Drug(
        id: 'phenytoin',
        genericName: 'Phenytoin',
        category: DrugCategory.anticonvulsant,
        regimens: [],
      );
      const digoxin = Drug(
        id: 'digoxin',
        genericName: 'Digoxin',
        category: DrugCategory.cardiovascular,
        regimens: [],
      );
      const paracetamol = Drug(
        id: 'paracetamol',
        genericName: 'Paracetamol',
        category: DrugCategory.analgesic,
        regimens: [],
      );

      expect(isNtiOrSimulationCandidate(vancoDrug, null, null), isTrue);
      expect(isNtiOrSimulationCandidate(gentamicin, null, null), isTrue);
      expect(isNtiOrSimulationCandidate(phenytoin, null, null), isTrue);
      expect(isNtiOrSimulationCandidate(digoxin, null, null), isTrue);
      expect(isNtiOrSimulationCandidate(paracetamol, null, null), isFalse);
    });

    testWidgets('T5.2: DosageResultCard renders PKPD button for Vancomycin and opens sheet',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const mockResult = DosageResult(
        success: true,
        calculatedDose: 1000.0,
        roundedDose: 1000.0,
        doseUnit: DoseUnit.mg,
        formulaUsed: 'Weight-based 15 mg/kg',
      );

      final state = CalculatorUiState.initial(vancoDrug).copyWith(
        selectedRegimen: vancoDrug.regimens.first,
        result: mockResult,
        status: CalculatorUiStatus.active,
        lastEvaluatedPatient: testPatient,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DosageResultCard(
                state: state,
                isThai: true,
                onBuildPatient: () => testPatient,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify button renders
      final pkpdBtn = find.byKey(const Key('calculator_open_pkpd_btn'));
      expect(pkpdBtn, findsOneWidget);
      expect(find.textContaining('เปิดแบบจำลอง PK-PD & กราฟทำนายระดับยา'), findsOneWidget);

      // Tap button to verify sheet opens
      await tester.tap(pkpdBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(PkPdSimulationSheet), findsOneWidget);
    });
  });

  // =========================================================================
  // Group 6: Two-Way Patient State Synchronization
  // =========================================================================
  group('Group 6: CalculatorController & PatientSession Two-Way Sync', () {
    setUp(() {
      PatientSession.instance.clearPatient();
    });

    testWidgets('T6.1: calculate() synchronizes validated patient to PatientSession',
        (tester) async {
      final controller = CalculatorController(drug: vancoDrug);

      controller.weightCtrl.text = '82.0';
      controller.heightCtrl.text = '178.0';
      controller.ageCtrl.text = '50';
      controller.scrCtrl.text = '1.1';
      controller.selectRegimen(vancoDrug.regimens.first);

      final res = controller.calculate(isThai: true);
      expect(res.isValid, isTrue);

      final activePt = PatientSession.instance.currentPatient.value;
      expect(activePt, isNotNull);
      expect(activePt!.weightKg, equals(82.0));
      expect(activePt.heightCm, equals(178.0));
      expect(activePt.ageYears, equals(50));
      expect(activePt.serumCreatinineMgDl, equals(1.1));

      controller.dispose();
    });

    testWidgets('T6.2: PatientSession updates propagate to CalculatorController without text jump',
        (tester) async {
      final controller = CalculatorController(drug: vancoDrug);

      // Inbound update from session
      PatientSession.instance.updateCurrentPatient(
        weightKg: 95.0,
        heightCm: 180.0,
        ageYears: 60,
        serumCreatinineMgDl: 1.4,
      );

      expect(controller.weightCtrl.text, equals('95.0'));
      expect(controller.heightCtrl.text, equals('180.0'));
      expect(controller.ageCtrl.text, equals('60'));
      expect(controller.scrCtrl.text, equals('1.4'));

      controller.dispose();
    });
  });

  // =========================================================================
  // Group 7: PkSimulationController Concurrency & State Management
  // =========================================================================
  group('Group 7: PkSimulationController Concurrency & State Management', () {
    test('T7.1: Controller initializes baseline and adjusted results correctly', () async {
      final controller = PkSimulationController(
        drug: vancoDrug,
        patient: testPatient,
        runner: testRunner,
        initialParams: baselineParams,
      );

      // Wait for initial simulation
      for (var i = 0; i < 50 && (controller.isLoading || controller.baselineResult == null); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      expect(controller.baselineResult, isNotNull);
      expect(controller.adjustedResult, isNotNull);
      expect(controller.comparison, isNotNull);
      expect(controller.doseMg, equals(1000.0));
      expect(controller.tauHours, equals(12.0));
      expect(controller.tInfHours, equals(1.0));

      controller.dispose();
    });

    test('T7.2: Parameter updates recalculate adjusted regimen and comparison', () async {
      final controller = PkSimulationController(
        drug: vancoDrug,
        patient: testPatient,
        runner: testRunner,
        initialParams: baselineParams,
      );
      for (var i = 0; i < 50 && (controller.isLoading || controller.baselineResult == null); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      // Update dose to 1500 mg
      controller.updateDose(1500.0);
      for (var i = 0; i < 50 && (controller.isLoading || controller.doseMg != 1500.0 || controller.adjustedResult?.params.dose != 1500.0); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      expect(controller.doseMg, equals(1500.0));
      expect(controller.adjustedResult, isNotNull);
      expect(controller.adjustedResult!.cMax > controller.baselineResult!.cMax, isTrue);
      expect(controller.comparison!.percentChangeCMax > 0, isTrue);

      // Update interval to 24h
      controller.updateInterval(24.0);
      for (var i = 0; i < 50 && (controller.isLoading || controller.tauHours != 24.0 || controller.adjustedResult?.params.tau != 24.0); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(controller.tauHours, equals(24.0));

      // Reset to baseline
      controller.resetToBaseline();
      expect(controller.doseMg, equals(1000.0));
      expect(controller.tauHours, equals(12.0));

      controller.dispose();
    });

    test('T7.3: Sequence-token mechanism discards stale out-of-order in-flight results', () async {
      // Mock runner with artificial delays
      var requestCount = 0;
      final controller = PkSimulationController(
        drug: vancoDrug,
        patient: testPatient,
        initialParams: baselineParams,
        runner: (params) async {
          requestCount++;
          final current = requestCount;
          if (current == 2) {
            // First update: delay 100ms
            await Future<void>.delayed(const Duration(milliseconds: 100));
          } else {
            // Second update: resolve immediately
            await Future<void>.delayed(const Duration(milliseconds: 10));
          }
          return PkSimulationEngine.simulate(params);
        },
      );
      for (var i = 0; i < 50 && (controller.isLoading || controller.baselineResult == null); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      // Request 1: dose = 1250 mg (takes 100ms)
      controller.updateDose(1250.0);
      await Future<void>.delayed(const Duration(milliseconds: 30));

      // Request 2: dose = 1750 mg (takes 10ms, finishes first!)
      controller.updateDose(1750.0);
      for (var i = 0; i < 50 && (controller.isLoading || controller.adjustedResult?.params.dose != 1750.0); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      // Result must reflect Request 2 (1750 mg), not stale Request 1 (1250 mg)
      expect(controller.adjustedResult!.params.dose, equals(1750.0));

      controller.dispose();
    });

    test('T7.4: Binary search scrubber finds exact interpolated concentration', () async {
      final controller = PkSimulationController(
        drug: vancoDrug,
        patient: testPatient,
        runner: testRunner,
        initialParams: baselineParams,
      );
      for (var i = 0; i < 50 && (controller.isLoading || controller.baselineResult == null); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      controller.setScrubberTime(6.0);
      expect(controller.activeAdjustedScrubberPoint, isNotNull);
      expect(controller.activeAdjustedScrubberPoint!.timeHours, equals(6.0));
      expect(controller.activeAdjustedScrubberPoint!.concentrationMgL > 0, isTrue);

      controller.setScrubberTime(null);
      expect(controller.activeAdjustedScrubberPoint, isNull);

      controller.dispose();
    });

    test('T7.5: Rule 5 Non-blocking Overdose policy preserves calculated numbers', () async {
      final controller = PkSimulationController(
        drug: vancoDrug,
        patient: testPatient,
        runner: testRunner,
        initialParams: baselineParams,
      );
      for (var i = 0; i < 50 && (controller.isLoading || controller.baselineResult == null); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      // Set extreme overdose 4000 mg
      controller.updateDose(4000.0);
      for (var i = 0; i < 50 && (controller.isLoading || controller.doseMg != 4000.0 || controller.adjustedResult?.params.dose != 4000.0); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      expect(controller.adjustedResult, isNotNull);
      expect(controller.adjustedResult!.hasOverdoseWarning, isTrue);
      expect(controller.adjustedResult!.cMax > 50.0, isTrue);
      expect(controller.adjustedResult!.curve.isNotEmpty, isTrue);

      controller.dispose();
    });
  });
}

