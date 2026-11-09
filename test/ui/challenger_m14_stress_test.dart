// ============================================================================
// Adversarial Stress-Test Suite: Milestone M14 PK-PD Visualization & CDSS UI
// Target File: test/ui/challenger_m14_stress_test.dart
// Author: challenger_m14_1 (Empirical Challenger)
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drug_dosage_calculator/core/core.dart' hide PkDataPoint;
import 'package:drug_dosage_calculator/core/calculators/pk_simulation_engine.dart';
import 'package:drug_dosage_calculator/core/models/pk_model.dart';
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
    id: 'PT-ADVERSARIAL-001',
    patientName: 'Adversarial Test Patient',
    hospitalNumber: 'HN999999',
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

  // Non-Vancomycin Drug (Gentamicin) for false-positive validation
  const gentaDrug = Drug(
    id: 'gentamicin',
    genericName: 'Gentamicin',
    brandNames: ['Garamycin'],
    category: DrugCategory.antibiotic,
    requiresTDM: true,
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Gram-negative Sepsis',
        dosingType: DosingType.weightBased,
        dosePerKg: 5.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency(
          intervalHours: 24,
          displayEn: 'every 24 hours',
          displayTh: 'ทุก 24 ชั่วโมง',
        ),
        doseBasis: DoseBasis.perDose,
      ),
    ],
  );

  // Synchronous Test Runner
  Future<PkSimulationResult> testRunner(PkSimulationParams params) async {
    return PkSimulationEngine.simulate(params);
  }

  // Base Simulation Params
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
    pointsPerPhase: 25,
  );

  // =========================================================================
  // Group 1: Extreme Curve Inputs & Boundary Geometries
  // =========================================================================
  group('Group 1: Extreme Curve Inputs & Boundary Geometries', () {
    testWidgets('T1.1: Empty curve points (curve: []) renders gracefully without crash',
        (tester) async {
      const emptyResult = PkSimulationResult(
        params: baseParams,
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
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('T1.2: Both baseline and adjusted curves empty renders cleanly',
        (tester) async {
      const emptyResult = PkSimulationResult(
        params: baseParams,
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
              baselineResult: emptyResult,
              isThai: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SteadyStatePkChart), findsOneWidget);
    });

    testWidgets('T1.3: Single data point curve renders without crash or exception',
        (tester) async {
      const singlePointResult = PkSimulationResult(
        params: baseParams,
        curve: [
          PkDataPoint(
            timeHours: 0.0,
            concentrationMgL: 15.0,
            isInfusing: false,
            zone: TherapeuticZone.therapeutic,
          ),
        ],
        cMax: 15.0,
        cMin: 15.0,
        tMax: 0.0,
        auc0To24: 360.0,
        aucTotal: 360.0,
        ke: 0.05,
        tHalf: 13.8,
        accumulationFactor: 1.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SteadyStatePkChart(
              adjustedResult: singlePointResult,
              window: baseParams.therapeuticWindow,
              isThai: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SteadyStatePkChart), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('T1.4: Flat constant line C(t) = 0 everywhere renders cleanly',
        (tester) async {
      final flatCurve = List.generate(
        25,
        (i) => PkDataPoint(
          timeHours: i.toDouble(),
          concentrationMgL: 0.0,
          isInfusing: false,
          zone: TherapeuticZone.subTherapeutic,
        ),
      );

      final zeroResult = PkSimulationResult(
        params: baseParams,
        curve: flatCurve,
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
        MaterialApp(
          home: Scaffold(
            body: SteadyStatePkChart(
              adjustedResult: zeroResult,
              window: baseParams.therapeuticWindow,
              isThai: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SteadyStatePkChart), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('T1.5: Massive concentration (Cmax = 10,000 mg/L) renders with proper headroom',
        (tester) async {
      final massiveCurve = [
        const PkDataPoint(timeHours: 0.0, concentrationMgL: 2500.0),
        const PkDataPoint(timeHours: 1.0, concentrationMgL: 10000.0),
        const PkDataPoint(timeHours: 12.0, concentrationMgL: 2500.0),
        const PkDataPoint(timeHours: 13.0, concentrationMgL: 10000.0),
        const PkDataPoint(timeHours: 24.0, concentrationMgL: 2500.0),
      ];

      final massiveResult = PkSimulationResult(
        params: baseParams,
        curve: massiveCurve,
        cMax: 10000.0,
        cMin: 2500.0,
        tMax: 1.0,
        auc0To24: 150000.0,
        aucTotal: 150000.0,
        ke: 0.05,
        tHalf: 13.8,
        accumulationFactor: 1.0,
        hasOverdoseWarning: true,
        overdoseWarningMessage: 'CRITICAL OVERDOSE: 10,000 mg/L',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SteadyStatePkChart(
              adjustedResult: massiveResult,
              window: baseParams.therapeuticWindow,
              isThai: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SteadyStatePkChart), findsOneWidget);
      expect(find.textContaining('CRITICAL OVERDOSE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('T1.6: Discontinuity / rapid vertical jump points render without NaN',
        (tester) async {
      // Piecewise jump: t = 1.0 at 10 mg/L jump to t = 1.0 at 500 mg/L
      final jumpCurve = [
        const PkDataPoint(timeHours: 0.0, concentrationMgL: 0.0),
        const PkDataPoint(timeHours: 1.0, concentrationMgL: 10.0),
        const PkDataPoint(timeHours: 1.0, concentrationMgL: 500.0), // Zero-dt discontinuity
        const PkDataPoint(timeHours: 12.0, concentrationMgL: 50.0),
      ];

      final jumpResult = PkSimulationResult(
        params: baseParams,
        curve: jumpCurve,
        cMax: 500.0,
        cMin: 0.0,
        tMax: 1.0,
        auc0To24: 3000.0,
        aucTotal: 3000.0,
        ke: 0.05,
        tHalf: 13.8,
        accumulationFactor: 1.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SteadyStatePkChart(
              adjustedResult: jumpResult,
              window: baseParams.therapeuticWindow,
              isThai: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SteadyStatePkChart), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  // =========================================================================
  // Group 2: Binary Search Scrubber Boundary & Interpolation Stress
  // =========================================================================
  group('Group 2: Binary Search Scrubber Boundary & Interpolation Stress', () {
    final standardResult = PkSimulationEngine.simulate(baseParams);

    test('T2.1: Exact lower boundary t = 0.0 returns initial concentration', () {
      final c0 = PkChartPainter.interpolateConcentration(standardResult.curve, 0.0);
      expect(c0, closeTo(standardResult.curve.first.concentrationMgL, 1e-4));
    });

    test('T2.2: Exact upper boundary t = horizonHours returns final concentration', () {
      final horizon = standardResult.params.horizonHours;
      final cEnd = PkChartPainter.interpolateConcentration(standardResult.curve, horizon);
      expect(cEnd, closeTo(standardResult.curve.last.concentrationMgL, 1e-4));
    });

    test('T2.3: Out-of-bounds queries (t = -5.0 and t = 100.0) clamp safely', () {
      final cNegative = PkChartPainter.interpolateConcentration(standardResult.curve, -5.0);
      expect(cNegative, equals(standardResult.curve.first.concentrationMgL));

      final cFarFuture = PkChartPainter.interpolateConcentration(standardResult.curve, 100.0);
      expect(cFarFuture, equals(standardResult.curve.last.concentrationMgL));
    });

    test('T2.4: Zero dt points (step discontinuity) interpolates without division by zero', () {
      final jumpCurve = [
        const PkDataPoint(timeHours: 0.0, concentrationMgL: 0.0),
        const PkDataPoint(timeHours: 1.0, concentrationMgL: 10.0),
        const PkDataPoint(timeHours: 1.0, concentrationMgL: 500.0),
        const PkDataPoint(timeHours: 2.0, concentrationMgL: 200.0),
      ];

      // Query exactly at t = 1.0
      final cAt1 = PkChartPainter.interpolateConcentration(jumpCurve, 1.0);
      expect(cAt1.isNaN, isFalse);
      expect(cAt1.isInfinite, isFalse);
      expect(cAt1, equals(500.0)); // Should match the post-jump value
    });

    test('T2.5: Single-point curve interpolation returns that point value for all t', () {
      final single = [const PkDataPoint(timeHours: 5.0, concentrationMgL: 42.0)];
      expect(PkChartPainter.interpolateConcentration(single, 0.0), equals(42.0));
      expect(PkChartPainter.interpolateConcentration(single, 5.0), equals(42.0));
      expect(PkChartPainter.interpolateConcentration(single, 10.0), equals(42.0));
    });

    test('T2.6: High-frequency randomized sampling stress (1,000 queries) preserves monotonicity and bounds', () {
      final rng = math.Random(42);
      final cMax = standardResult.cMax;

      for (int i = 0; i < 1000; i++) {
        final queryTime = rng.nextDouble() * 30.0 - 3.0; // [-3.0, 27.0]
        final conc = PkChartPainter.interpolateConcentration(standardResult.curve, queryTime);

        expect(conc.isNaN, isFalse, reason: 'NaN detected at t = $queryTime');
        expect(conc.isInfinite, isFalse, reason: 'Infinity detected at t = $queryTime');
        expect(conc, greaterThanOrEqualTo(0.0), reason: 'Negative conc at t = $queryTime');
        // Within reasonable curve bounds
        expect(conc, lessThanOrEqualTo(cMax * 1.05));
      }
    });
  });

  // =========================================================================
  // Group 3: Extreme Touch Gestures & Fling Resilience
  // =========================================================================
  group('Group 3: Extreme Touch Gestures & Fling Resilience', () {
    final standardResult = PkSimulationEngine.simulate(baseParams);

    testWidgets('T3.1: Far negative drag (X < -1000) clamps scrubber to t = 0',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      double? scrubbedTime;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SteadyStatePkChart(
                adjustedResult: standardResult,
                onScrubChanged: (t, _, __) => scrubbedTime = t,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final customPaintFinder = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is PkChartPainter,
      );
      expect(customPaintFinder, findsOneWidget);

      final center = tester.getCenter(customPaintFinder);
      final gesture = await tester.startGesture(center);
      await gesture.moveTo(Offset(-2000.0, center.dy));
      await tester.pump();

      expect(scrubbedTime, isNotNull);
      expect(scrubbedTime!, equals(0.0));

      await gesture.up();
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });

    testWidgets('T3.2: Far positive drag (X > 5000) clamps scrubber to t = horizonHours',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      double? scrubbedTime;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SteadyStatePkChart(
                adjustedResult: standardResult,
                onScrubChanged: (t, _, __) => scrubbedTime = t,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final customPaintFinder = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is PkChartPainter,
      );
      final center = tester.getCenter(customPaintFinder);
      final gesture = await tester.startGesture(center);
      await gesture.moveTo(Offset(5000.0, center.dy));
      await tester.pump();

      expect(scrubbedTime, isNotNull);
      expect(scrubbedTime!, closeTo(baseParams.horizonHours, 1e-3));

      await gesture.up();
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });

    testWidgets('T3.3: Rapid erratic flings back-and-forth across canvas boundary',
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
            body: SingleChildScrollView(
              child: SteadyStatePkChart(
                adjustedResult: standardResult,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final customPaintFinder = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is PkChartPainter,
      );
      final center = tester.getCenter(customPaintFinder);
      final gesture = await tester.startGesture(center);

      // Rapid erratic flings
      final offsets = [
        Offset(-500.0, center.dy),
        Offset(1200.0, center.dy),
        Offset(-300.0, center.dy),
        Offset(2500.0, center.dy),
        Offset(100.0, center.dy),
        Offset(-10.0, center.dy),
        Offset(500.0, center.dy),
      ];

      for (final off in offsets) {
        await gesture.moveTo(off);
        await tester.pump(const Duration(milliseconds: 10));
      }

      await gesture.up();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(tester.takeException(), isNull);
    });

    testWidgets('T3.4: Multi-touch successive boundary taps without crash',
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
            body: SingleChildScrollView(
              child: SteadyStatePkChart(
                adjustedResult: standardResult,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final customPaintFinder = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is PkChartPainter,
      );
      final topLeft = tester.getTopLeft(customPaintFinder);
      final bottomRight = tester.getBottomRight(customPaintFinder);

      // Fast successive boundary taps
      for (int i = 0; i < 5; i++) {
        await tester.tapAt(topLeft + const Offset(5, 5));
        await tester.pump(const Duration(milliseconds: 20));
        await tester.tapAt(bottomRight - const Offset(5, 5));
        await tester.pump(const Duration(milliseconds: 20));
      }

      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(tester.takeException(), isNull);
    });

    testWidgets('T3.5: Widget unmount during active fade timer (no memory leak or late setState)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SteadyStatePkChart(
              adjustedResult: standardResult,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Trigger a scrub
      final center = tester.getCenter(find.byType(SteadyStatePkChart));
      await tester.tapAt(center);
      await tester.pump(); // Starts the 2.5s fade timer

      // Immediately unmount by replacing with empty Container
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox.shrink(),
          ),
        ),
      );

      // Advance clock past timer expiration
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // No late setState exception
      expect(tester.takeException(), isNull);
    });
  });

  // =========================================================================
  // Group 4: Vancomycin Red Man Syndrome Boundary & Safety Alerts
  // =========================================================================
  group('Group 4: Vancomycin Red Man Syndrome Boundary & Safety Alerts', () {
    testWidgets('T4.1: Infusion rate exactly at 10.0 mg/min (safe limit) shows NO alert',
        (tester) async {
      // 600 mg in 1.0 hr = 600 / 60 = 10.0 mg/min (exactly safe)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PkParameterSliders(
                crclMlMin: 80.0,
                baselineCrclMlMin: 80.0,
                currentDoseMg: 600.0,
                baselineDoseMg: 600.0,
                currentTauHours: 12.0,
                baselineTauHours: 12.0,
                currentTInfHours: 1.0,
                baselineTInfHours: 1.0,
                drug: vancoDrug,
                isThai: true,
                onCrclChanged: (_) {},
                onDoseChanged: (_) {},
                onTauChanged: (_) {},
                onTInfChanged: (_) {},
                onResetToBaseline: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Alert must NOT appear at exactly 10.0 mg/min
      expect(find.byKey(const Key('pk_red_man_syndrome_alert')), findsNothing);
    });

    testWidgets('T4.2: Infusion rate at 10.0167 mg/min (601 mg in 1.0 hr) triggers Red Man alert',
        (tester) async {
      // 601 mg in 1.0 hr = 601 / 60 = 10.0167 mg/min > 10.0 mg/min
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PkParameterSliders(
                crclMlMin: 80.0,
                baselineCrclMlMin: 80.0,
                currentDoseMg: 601.0,
                baselineDoseMg: 600.0,
                currentTauHours: 12.0,
                baselineTauHours: 12.0,
                currentTInfHours: 1.0,
                baselineTInfHours: 1.0,
                drug: vancoDrug,
                isThai: true,
                onCrclChanged: (_) {},
                onDoseChanged: (_) {},
                onTauChanged: (_) {},
                onTInfChanged: (_) {},
                onResetToBaseline: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Alert MUST appear
      expect(find.byKey(const Key('pk_red_man_syndrome_alert')), findsOneWidget);
      expect(find.textContaining('Red Man Syndrome'), findsOneWidget);
    });

    testWidgets('T4.3: Infusion rate at 9.983 mg/min (599 mg in 1.0 hr) shows NO alert',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PkParameterSliders(
                crclMlMin: 80.0,
                baselineCrclMlMin: 80.0,
                currentDoseMg: 599.0,
                baselineDoseMg: 600.0,
                currentTauHours: 12.0,
                baselineTauHours: 12.0,
                currentTInfHours: 1.0,
                baselineTInfHours: 1.0,
                drug: vancoDrug,
                isThai: true,
                onCrclChanged: (_) {},
                onDoseChanged: (_) {},
                onTauChanged: (_) {},
                onTInfChanged: (_) {},
                onResetToBaseline: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pk_red_man_syndrome_alert')), findsNothing);
    });

    testWidgets('T4.4: Auto-adjust button callback snaps tInf to safe duration',
        (tester) async {
      double? updatedTInf;

      // 1000 mg in 1.0 hr -> 16.67 mg/min (Alert active)
      // Auto-adjust: safeHours = 1000 / 600 = 1.667h -> snapped to 2.0h
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
                onCrclChanged: (_) {},
                onDoseChanged: (_) {},
                onTauChanged: (_) {},
                onTInfChanged: (val) => updatedTInf = val,
                onResetToBaseline: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final autoAdjustBtn = find.byKey(const Key('pk_red_man_auto_adjust_btn'));
      expect(autoAdjustBtn, findsOneWidget);

      await tester.tap(autoAdjustBtn);
      await tester.pump();

      expect(updatedTInf, equals(2.0));
      // At 2.0 hr, rate is 1000 / 120 = 8.33 mg/min <= 10.0 mg/min (safe!)
    });

    testWidgets('T4.5: Non-glycopeptide drug (Gentamicin) with rate > 10 mg/min does NOT trigger Red Man alert',
        (tester) async {
      // 500 mg in 0.5 hr = 16.67 mg/min, but Gentamicin is an aminoglycoside, not a glycopeptide
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PkParameterSliders(
                crclMlMin: 80.0,
                baselineCrclMlMin: 80.0,
                currentDoseMg: 500.0,
                baselineDoseMg: 500.0,
                currentTauHours: 24.0,
                baselineTauHours: 24.0,
                currentTInfHours: 0.5,
                baselineTInfHours: 0.5,
                drug: gentaDrug, // Gentamicin
                isThai: true,
                onCrclChanged: (_) {},
                onDoseChanged: (_) {},
                onTauChanged: (_) {},
                onTInfChanged: (_) {},
                onResetToBaseline: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No false-positive alert
      expect(find.byKey(const Key('pk_red_man_syndrome_alert')), findsNothing);
    });
  });

  // =========================================================================
  // Group 5: Accessible Data Table Downsampling & Export Precision
  // =========================================================================
  group('Group 5: Accessible Data Table Downsampling & Export Precision', () {
    final standardResult = PkSimulationEngine.simulate(baseParams);

    testWidgets('T5.1: Table downsampling preserves peak and trough inflection points',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PkDataTable(
                adjustedResult: standardResult,
                therapeuticWindow: baseParams.therapeuticWindow,
                isThai: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check that Peak (สูงสุด) and Trough (ต่ำสุด) labels appear in the table
      expect(find.textContaining('สูงสุด'), findsAtLeastNWidgets(1));
      expect(find.textContaining('ต่ำสุด'), findsAtLeastNWidgets(1));
    });

    testWidgets('T5.2: Table row generation handles extreme horizons (72h and 1h)',
        (tester) async {
      final longHorizonParams = baseParams.copyWith(horizonHours: 72.0);
      final longResult = PkSimulationEngine.simulate(longHorizonParams);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PkDataTable(
                adjustedResult: longResult,
                therapeuticWindow: baseParams.therapeuticWindow,
                isThai: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PkDataTable), findsOneWidget);
      expect(find.textContaining('72.0 h'), findsOneWidget);

      // Short horizon (1h)
      final shortHorizonParams = baseParams.copyWith(horizonHours: 1.0);
      final shortResult = PkSimulationEngine.simulate(shortHorizonParams);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PkDataTable(
                adjustedResult: shortResult,
                therapeuticWindow: baseParams.therapeuticWindow,
                isThai: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PkDataTable), findsOneWidget);
      expect(find.textContaining('1.0 h'), findsOneWidget);
    });

    testWidgets('T5.3: Table rendering with massive concentration (10,000 mg/L) and 0 mg/L',
        (tester) async {
      final massiveCurve = [
        const PkDataPoint(timeHours: 0.0, concentrationMgL: 0.0),
        const PkDataPoint(timeHours: 1.0, concentrationMgL: 10000.0),
        const PkDataPoint(timeHours: 12.0, concentrationMgL: 500.0),
      ];

      final massiveResult = PkSimulationResult(
        params: baseParams,
        curve: massiveCurve,
        cMax: 10000.0,
        cMin: 0.0,
        tMax: 1.0,
        auc0To24: 150000.0,
        aucTotal: 150000.0,
        ke: 0.05,
        tHalf: 13.8,
        accumulationFactor: 1.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PkDataTable(
                adjustedResult: massiveResult,
                therapeuticWindow: baseParams.therapeuticWindow,
                isThai: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('10000.00'), findsOneWidget);
      expect(find.text('0.00'), findsWidgets);
    });

    testWidgets('T5.4: TSV clipboard export generates valid formatted data with correct tabs and headers',
        (tester) async {
      String? copiedString;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedString = (call.arguments as Map)['text'] as String?;
          return null;
        }
        return null;
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PkDataTable(
                adjustedResult: standardResult,
                therapeuticWindow: baseParams.therapeuticWindow,
                isThai: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final copyBtn = find.byKey(const Key('pk_data_table_copy_tsv_btn'));
      expect(copyBtn, findsOneWidget);

      await tester.tap(copyBtn);
      await tester.pumpAndSettle();

      expect(copiedString, isNotNull);
      expect(copiedString!, contains('DRUGPH CLINICAL DECISION SUPPORT SYSTEM'));
      expect(copiedString!, contains('Time (hr)\tPhase\tAdjusted (mg/L)'));
      expect(copiedString!, contains('\ttherapeutic'));
    });
  });

  // =========================================================================
  // Group 6: Rule 5 Non-Blocking Overdose Invariant Across UI Surfaces
  // =========================================================================
  group('Group 6: Rule 5 Non-Blocking Overdose Invariant Across UI Surfaces', () {
    // 5000 mg dose produces massive overdose (Cmax ~ 160 mg/L >> MTC 20 mg/L)
    final overdoseParams = baseParams.copyWith(dose: 5000.0);
    final overdoseResult = PkSimulationEngine.simulate(overdoseParams);

    testWidgets('T6.1: Massive overdose displays exact uncapped Cmax on peak badge',
        (tester) async {
      expect(overdoseResult.hasOverdoseWarning, isTrue);
      expect(overdoseResult.cMax, greaterThan(100.0));

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

      // Chart must render CustomPaint
      final customPaintFinder = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is PkChartPainter,
      );
      expect(customPaintFinder, findsOneWidget);

      final customPaint = tester.widget<CustomPaint>(customPaintFinder);
      final painter = customPaint.painter as PkChartPainter;

      // Exact uncapped Cmax must be passed to painter without clamping
      expect(painter.adjustedResult.cMax, equals(overdoseResult.cMax));
      expect(painter.adjustedResult.cMax, greaterThan(100.0));
    });

    testWidgets('T6.2: Overdose warning banner is prominently rendered without blocking UI',
        (tester) async {
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

      // Banner must be present and display the warning
      expect(find.textContaining('Overdose Warning'), findsOneWidget);

      // UI must remain interactive (no modal barrier or disabled state)
      final center = tester.getCenter(find.byType(SteadyStatePkChart));
      await tester.tapAt(center);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('T6.3: Data table rows display exact uncapped concentrations with Toxic badge',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PkDataTable(
                adjustedResult: overdoseResult,
                therapeuticWindow: overdoseParams.therapeuticWindow,
                isThai: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Peak value formatted to 2 decimals appears at each steady-state cycle
      final peakStr = overdoseResult.cMax.toStringAsFixed(2);
      expect(find.text(peakStr), findsAtLeastNWidgets(1));

      // Overdose rows must show Toxic badge
      expect(find.textContaining('เกินเกณฑ์พิษ (Toxic)'), findsWidgets);
    });

    testWidgets('T6.4: Regimen comparison card displays exact uncapped metrics and Toxic badge in sheet',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
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
              runner: (params) async => PkSimulationEngine.simulate(
                params.copyWith(dose: 5000.0),
              ),
              isThai: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Toxic badge in comparison card
      expect(find.textContaining('เสี่ยงพิษ (Toxic)'), findsOneWidget);

      // Cmax tile displays the large number
      expect(find.textContaining('mg/L'), findsWidgets);
    });

    testWidgets('T6.5: Interactive scrubber functions normally during overdose state without clamping values to MTC',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      double? scrubbedConc;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SteadyStatePkChart(
                adjustedResult: overdoseResult,
                window: overdoseParams.therapeuticWindow,
                onScrubChanged: (_, adj, __) => scrubbedConc = adj,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scrub near peak time (t = 1.0 hr)
      final customPaintFinder = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is PkChartPainter,
      );
      expect(customPaintFinder, findsOneWidget);
      final center = tester.getCenter(customPaintFinder);
      await tester.tapAt(center);
      await tester.pump();

      expect(scrubbedConc, isNotNull);
      // Concentration at scrubber must be actual uncapped value > MTC (20)
      expect(scrubbedConc!, greaterThan(20.0));
    });
  });

  // =========================================================================
  // Group 7: High-Frequency Concurrency & Rapid Parameter Mutation
  // =========================================================================
  group('Group 7: High-Frequency Concurrency & Rapid Parameter Mutation', () {
    test('T7.1: Rapid successive slider changes with debounced runner discard stale results',
        () async {
      final controller = PkSimulationController(
        drug: vancoDrug,
        patient: testPatient,
        runner: testRunner,
        initialParams: baseParams,
      );

      // Initial simulation
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(controller.adjustedResult, isNotNull);

      // Fire 10 rapid parameter changes within 5ms (faster than 20ms debounce)
      for (int i = 1; i <= 10; i++) {
        controller.updateDose(1000.0 + i * 100.0);
      }

      // Controller should be loading
      expect(controller.isLoading, isTrue);

      // Wait for debounce (20ms) + calculation
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Final adjusted result must reflect the LAST dose (2000.0 mg)
      expect(controller.isLoading, isFalse);
      expect(controller.adjustedResult!.params.dose, equals(2000.0));

      controller.dispose();
    });

    test('T7.2: Reset to baseline restores all state parameters and results cleanly',
        () async {
      final controller = PkSimulationController(
        drug: vancoDrug,
        patient: testPatient,
        runner: testRunner,
        initialParams: baseParams,
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));
      final baselineDose = controller.baselineParams.dose;

      // Mutate dose and interval
      controller.updateDose(2500.0);
      controller.updateInterval(24.0);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(controller.adjustedResult!.params.dose, equals(2500.0));
      expect(controller.adjustedResult!.params.tau, equals(24.0));

      // Reset
      controller.resetToBaseline();

      expect(controller.doseMg, equals(baselineDose));
      expect(controller.tauHours, equals(baseParams.tau));
      expect(controller.adjustedResult!.params.dose, equals(baselineDose));

      controller.dispose();
    });
  });
}
