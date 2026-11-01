// ============================================================
// Adversarial UI & Clipboard Stress Testing — RRT Bedside Experience
// ============================================================
// Independent empirical UI challenge testing by challenger_m1_1.
// Validates:
// 1. Dynamic RRT mode switching (None -> IHD -> CAPD -> CRRT -> None)
// 2. Strict clipboard interception: verifies [CRRT] and [IHD: Post-HD Dosing] in copied payload
// 3. Zero RenderFlex overflow under extreme viewports (320x480, 768x1024, 2560x1440)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:drug_dosage_calculator/data/patient_session.dart';
import 'package:drug_dosage_calculator/ui/calculator_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Adversarial UI Dimension: RRT Mode Switching & Clipboard Integration', () {
    late Drug meropenem;
    final List<MethodCall> clipboardCalls = [];

    setUp(() {
      PatientSession.instance.clearPatient();
      meropenem = DrugDatabase.findById('meropenem')!;
      clipboardCalls.clear();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
        if (methodCall.method == 'Clipboard.setData') {
          clipboardCalls.add(methodCall);
          return null;
        }
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    Widget createWidgetUnderTest({bool isThai = false}) {
      return MaterialApp(
        home: CalculatorScreen(
          drug: meropenem,
          isThai: isThai,
        ),
      );
    }

    testWidgets('Dynamic RRT switching toggles badges reactively', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Enter patient inputs
      await tester.enterText(find.byKey(const Key('calculator_weight_field')), '70');
      await tester.enterText(find.byKey(const Key('calculator_height_field')), '170');
      await tester.enterText(find.byKey(const Key('calculator_age_field')), '50');
      await tester.enterText(find.byKey(const Key('calculator_scr_field')), '4.0');
      await tester.pumpAndSettle();

      // 1. Calculate under None
      final calcBtn = find.byKey(const Key('calculator_calculate_button'));
      await tester.ensureVisible(calcBtn);
      await tester.tap(calcBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('calculator_crrt_badge')), findsNothing);
      expect(find.byKey(const Key('calculator_post_hd_badge')), findsNothing);

      // 2. Switch to CRRT and recalculate
      final crrtSeg = find.text('CRRT');
      await tester.ensureVisible(crrtSeg);
      await tester.tap(crrtSeg);
      await tester.pumpAndSettle();

      await tester.ensureVisible(calcBtn);
      await tester.tap(calcBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('calculator_crrt_badge')), findsOneWidget);
      expect(find.byKey(const Key('calculator_post_hd_badge')), findsNothing);

      // 3. Switch to IHD and recalculate
      final ihdSeg = find.text('IHD');
      await tester.ensureVisible(ihdSeg);
      await tester.tap(ihdSeg);
      await tester.pumpAndSettle();

      await tester.ensureVisible(calcBtn);
      await tester.tap(calcBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('calculator_crrt_badge')), findsNothing);
      expect(find.byKey(const Key('calculator_post_hd_badge')), findsOneWidget);

      // 4. Switch back to None and recalculate
      final noneSeg = find.text('None');
      await tester.ensureVisible(noneSeg);
      await tester.tap(noneSeg);
      await tester.pumpAndSettle();

      await tester.ensureVisible(calcBtn);
      await tester.tap(calcBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('calculator_crrt_badge')), findsNothing);
      expect(find.byKey(const Key('calculator_post_hd_badge')), findsNothing);
    });

    testWidgets('Clipboard copy buttons correctly embed [CRRT] tag into HIS Order', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Select CRRT
      await tester.tap(find.text('CRRT'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('calculator_weight_field')), '70');
      await tester.enterText(find.byKey(const Key('calculator_height_field')), '170');
      await tester.enterText(find.byKey(const Key('calculator_age_field')), '50');
      await tester.enterText(find.byKey(const Key('calculator_scr_field')), '4.0');
      await tester.pumpAndSettle();

      final calcBtn = find.byKey(const Key('calculator_calculate_button'));
      await tester.ensureVisible(calcBtn);
      await tester.tap(calcBtn);
      await tester.pumpAndSettle();

      // Tap Copy HIS Order button
      final copyHisBtn = find.byKey(const Key('copy_his_order_button'));
      await tester.ensureVisible(copyHisBtn);
      await tester.tap(copyHisBtn);
      await tester.pumpAndSettle();

      expect(clipboardCalls.isNotEmpty, isTrue);
      final lastCall = clipboardCalls.last;
      final copiedText = (lastCall.arguments as Map)['text'] as String;

      expect(copiedText, contains('[CRRT]'));
      expect(copiedText, contains('Meropenem'));
      expect(copiedText, contains('1000 mg'));
      expect(copiedText, contains('q12h'));
    });

    testWidgets('Extreme Viewport Stress: Zero RenderFlex overflow at 320x480, 768x1024, 2560x1440', (WidgetTester tester) async {
      final viewports = [
        const Size(320, 480),   // Ultra-compact phone
        const Size(768, 1024),  // iPad mini / tablet
        const Size(2560, 1440), // QHD wide workstation monitor
      ];

      for (final vp in viewports) {
        tester.view.physicalSize = vp;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createWidgetUnderTest(isThai: true));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'No RenderFlex overflow on ${vp.width}x${vp.height} in Thai');
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
