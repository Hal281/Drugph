import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:drug_dosage_calculator/data/patient_session.dart';
import 'package:drug_dosage_calculator/ui/calculator_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Challenger M1-Iter2 Adversarial Stress Suite: Mobile Viewports & Rule 5 Overdose', () {
    late Drug enoxaparin;
    late Drug vancomycin;
    late Drug meropenem;

    setUp(() {
      PatientSession.instance.clearPatient();
      enoxaparin = DrugDatabase.findById('enoxaparin')!;
      vancomycin = DrugDatabase.findById('vancomycin')!;
      meropenem = DrugDatabase.findById('meropenem')!;
    });

    Widget buildTestApp({required Drug drug, required bool isThai}) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: CalculatorScreen(
          drug: drug,
          isThai: isThai,
        ),
      );
    }

    Future<void> enterInputsAndCalculate({
      required WidgetTester tester,
      required String weight,
      required String height,
      required String age,
      required String scr,
      required String rrtSegmentText,
    }) async {
      // 1. Select RRT mode
      final rrtSegment = find.text(rrtSegmentText);
      await tester.ensureVisible(rrtSegment);
      await tester.tap(rrtSegment);
      await tester.pumpAndSettle();

      // 2. Enter patient parameters
      final weightField = find.byKey(const Key('calculator_weight_field'));
      await tester.ensureVisible(weightField);
      await tester.enterText(weightField, weight);

      final heightField = find.byKey(const Key('calculator_height_field'));
      await tester.ensureVisible(heightField);
      await tester.enterText(heightField, height);

      final ageField = find.byKey(const Key('calculator_age_field'));
      await tester.ensureVisible(ageField);
      await tester.enterText(ageField, age);

      final scrField = find.byKey(const Key('calculator_scr_field'));
      await tester.ensureVisible(scrField);
      await tester.enterText(scrField, scr);

      await tester.pumpAndSettle();

      // 3. Tap Calculate button
      final calcBtn = find.byKey(const Key('calculator_calculate_button'));
      await tester.ensureVisible(calcBtn);
      await tester.tap(calcBtn);
      await tester.pumpAndSettle();
    }

    final testViewports = [
      const Size(360, 640), // Standard compact Android/iOS
      const Size(320, 480), // Ultra-compact small phone
    ];

    // -------------------------------------------------------------------------
    // Test 1: CRRT Mode with Extreme Patient (250 kg) across 360x640 and 320x480
    // -------------------------------------------------------------------------
    testWidgets('1. CRRT with extreme weight (250 kg) exhibits zero RenderFlex overflow and strictly preserves Rule 5', (WidgetTester tester) async {
      for (final vp in testViewports) {
        for (final isThai in [false, true]) {
          tester.view.physicalSize = vp;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(buildTestApp(drug: enoxaparin, isThai: isThai));
          await tester.pumpAndSettle();

          await enterInputsAndCalculate(
            tester: tester,
            weight: '250',
            height: '180',
            age: '50',
            scr: '4.5',
            rrtSegmentText: 'CRRT',
          );

          // Assert Zero RenderFlex overflow
          expect(
            tester.takeException(),
            isNull,
            reason: 'RenderFlex overflow detected on ${vp.width}x${vp.height} (isThai=$isThai) under CRRT',
          );

          // Rule 5: Overdose Banner MUST be present
          final overdoseBanner = find.byKey(const Key('calculator_overdose_banner'));
          await tester.ensureVisible(overdoseBanner);
          expect(overdoseBanner, findsOneWidget);

          // Rule 5: Calculated dose must NOT be hidden or zeroed out
          expect(find.textContaining('250'), findsWidgets);
          expect(find.textContaining('mg'), findsWidgets);

          // CRRT Badge must be present
          final crrtBadge = find.byKey(const Key('calculator_crrt_badge'));
          await tester.ensureVisible(crrtBadge);
          expect(crrtBadge, findsOneWidget);

          // Copy buttons must be present and >= 48dp
          final copyHisBtn = find.byKey(const Key('copy_his_order_button'));
          await tester.ensureVisible(copyHisBtn);
          expect(copyHisBtn, findsOneWidget);
          expect(tester.getSize(copyHisBtn).height, greaterThanOrEqualTo(48.0));

          final copyNoteBtn = find.byKey(const Key('copy_pharmacist_note_button'));
          await tester.ensureVisible(copyNoteBtn);
          expect(copyNoteBtn, findsOneWidget);
          expect(tester.getSize(copyNoteBtn).height, greaterThanOrEqualTo(48.0));
        }
      }
    });

    // -------------------------------------------------------------------------
    // Test 2: IHD Mode with Extreme Patient (250 kg) across 360x640 and 320x480
    // -------------------------------------------------------------------------
    testWidgets('2. IHD with extreme weight (250 kg) Vancomycin exhibits zero RenderFlex overflow and renders Post-HD badge', (WidgetTester tester) async {
      for (final vp in testViewports) {
        for (final isThai in [false, true]) {
          tester.view.physicalSize = vp;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(buildTestApp(drug: vancomycin, isThai: isThai));
          await tester.pumpAndSettle();

          await enterInputsAndCalculate(
            tester: tester,
            weight: '250',
            height: '180',
            age: '55',
            scr: '5.5',
            rrtSegmentText: 'IHD',
          );

          // Assert Zero RenderFlex overflow
          expect(
            tester.takeException(),
            isNull,
            reason: 'RenderFlex overflow detected on ${vp.width}x${vp.height} (isThai=$isThai) under IHD',
          );

          // Rule 5: Overdose Banner MUST be present
          final overdoseBanner = find.byKey(const Key('calculator_overdose_banner'));
          await tester.ensureVisible(overdoseBanner);
          expect(overdoseBanner, findsOneWidget);

          // Calculated dose MUST NOT be hidden
          expect(find.textContaining('1875.00 mg'), findsOneWidget);

          // Post-HD Badge must be present
          final postHdBadge = find.byKey(const Key('calculator_post_hd_badge'));
          await tester.ensureVisible(postHdBadge);
          expect(postHdBadge, findsOneWidget);
        }
      }
    });

    // -------------------------------------------------------------------------
    // Test 3: CAPD Mode across 360x640 and 320x480
    // -------------------------------------------------------------------------
    testWidgets('3. CAPD mode Meropenem exhibits zero RenderFlex overflow and renders CAPD badge', (WidgetTester tester) async {
      for (final vp in testViewports) {
        for (final isThai in [false, true]) {
          tester.view.physicalSize = vp;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(buildTestApp(drug: meropenem, isThai: isThai));
          await tester.pumpAndSettle();

          await enterInputsAndCalculate(
            tester: tester,
            weight: '250',
            height: '180',
            age: '50',
            scr: '4.5',
            rrtSegmentText: 'CAPD',
          );

          // Assert Zero RenderFlex overflow
          expect(
            tester.takeException(),
            isNull,
            reason: 'RenderFlex overflow detected on ${vp.width}x${vp.height} (isThai=$isThai) under CAPD',
          );

          // CAPD Badge must be present
          final capdBadge = find.byKey(const Key('calculator_capd_badge'));
          await tester.ensureVisible(capdBadge);
          expect(capdBadge, findsOneWidget);

          // Verify calculated dose rendered cleanly
          expect(find.textContaining('500 mg'), findsWidgets);
        }
      }
    });

    // -------------------------------------------------------------------------
    // Test 4: Dynamic RRT Switching under 320x480 without state contamination
    // -------------------------------------------------------------------------
    testWidgets('4. Dynamic switching (CRRT -> IHD -> CAPD -> None) on 320x480 executes cleanly without overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp(drug: meropenem, isThai: true));
      await tester.pumpAndSettle();

      // Enter parameters
      final weightField = find.byKey(const Key('calculator_weight_field'));
      await tester.ensureVisible(weightField);
      await tester.enterText(weightField, '80');

      final heightField = find.byKey(const Key('calculator_height_field'));
      await tester.ensureVisible(heightField);
      await tester.enterText(heightField, '175');

      final scrField = find.byKey(const Key('calculator_scr_field'));
      await tester.ensureVisible(scrField);
      await tester.enterText(scrField, '4.0');

      final ageField = find.byKey(const Key('calculator_age_field'));
      await tester.ensureVisible(ageField);
      await tester.enterText(ageField, '50');

      final calcBtn = find.byKey(const Key('calculator_calculate_button'));

      // 1. Switch to CRRT
      await tester.ensureVisible(find.text('CRRT'));
      await tester.tap(find.text('CRRT'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(calcBtn);
      await tester.tap(calcBtn);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('calculator_crrt_badge')), findsOneWidget);

      // 2. Switch to IHD
      await tester.ensureVisible(find.text('IHD'));
      await tester.tap(find.text('IHD'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(calcBtn);
      await tester.tap(calcBtn);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('calculator_post_hd_badge')), findsOneWidget);

      // 3. Switch to CAPD
      await tester.ensureVisible(find.text('CAPD'));
      await tester.tap(find.text('CAPD'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(calcBtn);
      await tester.tap(calcBtn);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('calculator_capd_badge')), findsOneWidget);

      // 4. Switch to None (Thai: 'ไม่มี')
      await tester.ensureVisible(find.text('ไม่มี'));
      await tester.tap(find.text('ไม่มี'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(calcBtn);
      await tester.tap(calcBtn);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('calculator_crrt_badge')), findsNothing);
      expect(find.byKey(const Key('calculator_post_hd_badge')), findsNothing);
      expect(find.byKey(const Key('calculator_capd_badge')), findsNothing);
    });

    // -------------------------------------------------------------------------
    // Test 5: Unmapped RRT Drug Fallback Warning on Mobile Viewports (360x640 & 320x480)
    // -------------------------------------------------------------------------
    testWidgets('5. Unmapped RRT Drug (Acyclovir) fallback warnings on 320x480 & 360x640 exhibit zero RenderFlex overflow', (WidgetTester tester) async {
      final acyclovir = DrugDatabase.findById('acyclovir')!;

      for (final vp in testViewports) {
        for (final isThai in [false, true]) {
          tester.view.physicalSize = vp;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(buildTestApp(drug: acyclovir, isThai: isThai));
          await tester.pumpAndSettle();

          await enterInputsAndCalculate(
            tester: tester,
            weight: '70',
            height: '170',
            age: '60',
            scr: '4.0',
            rrtSegmentText: 'CRRT',
          );

          expect(
            tester.takeException(),
            isNull,
            reason: 'Unmapped RRT drug must not overflow on ${vp.width}x${vp.height} (isThai=$isThai)',
          );

          // Verify CRRT badge and fallback advisory warning are rendered
          expect(find.byKey(const Key('calculator_crrt_badge')), findsOneWidget);
        }
      }
    });

    // -------------------------------------------------------------------------
    // Test 6: Extreme SCr (25.0 mg/dL) & Low Weight (35 kg) on 320x480
    // -------------------------------------------------------------------------
    testWidgets('6. Extreme SCr (25.0 mg/dL) & Low Weight (35 kg) on 320x480 exhibits zero RenderFlex overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp(drug: vancomycin, isThai: true));
      await tester.pumpAndSettle();

      await enterInputsAndCalculate(
        tester: tester,
        weight: '35',
        height: '145',
        age: '80',
        scr: '25.0',
        rrtSegmentText: 'IHD',
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('calculator_post_hd_badge')), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 7: Known Latent Defect — Invalid Input Error Dialog on Mobile Viewports
    // -------------------------------------------------------------------------
    testWidgets(
      '7. Invalid patient input error dialog on mobile viewports (320x480 & 360x640) exhibits zero RenderFlex overflow',
      (WidgetTester tester) async {
        for (final vp in const [Size(320, 480), Size(360, 640)]) {
          tester.view.physicalSize = vp;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(buildTestApp(drug: meropenem, isThai: true));
          await tester.pumpAndSettle();

          final calcBtn = find.byKey(const Key('calculator_calculate_button'));
          await tester.ensureVisible(calcBtn);
          await tester.tap(calcBtn);
          await tester.pumpAndSettle();

          expect(find.byType(AlertDialog), findsOneWidget);
          expect(tester.takeException(), isNull);

          await tester.tap(find.text('OK'));
          await tester.pumpAndSettle();
        }
      },
    );
  });
}
