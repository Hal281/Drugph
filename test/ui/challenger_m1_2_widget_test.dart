import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:drug_dosage_calculator/data/patient_session.dart';
import 'package:drug_dosage_calculator/ui/calculator_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Challenger M1-2 Adversarial Widget Tests: Overdose & RRT Badges Coexistence', () {
    late Drug enoxaparin;
    late Drug vancomycin;

    setUp(() {
      PatientSession.instance.clearPatient();
      enoxaparin = DrugDatabase.findById('enoxaparin')!;
      vancomycin = DrugDatabase.findById('vancomycin')!;
    });

    Widget createEnoxaparinWidget({bool isThai = false}) {
      return MaterialApp(
        home: CalculatorScreen(
          drug: enoxaparin,
          isThai: isThai,
        ),
      );
    }

    Widget createVancomycinWidget({bool isThai = false}) {
      return MaterialApp(
        home: CalculatorScreen(
          drug: vancomycin,
          isThai: isThai,
        ),
      );
    }

    testWidgets('1. Extreme weight (250 kg) on CRRT displays Overdose Banner and CRRT badge without hiding dose (Rule 5)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createEnoxaparinWidget(isThai: false));
      await tester.pumpAndSettle();

      // Select CRRT mode
      await tester.tap(find.text('CRRT'));
      await tester.pumpAndSettle();

      // Enter extreme weight (250 kg)
      await tester.enterText(find.byKey(const Key('calculator_weight_field')), '250');
      await tester.enterText(find.byKey(const Key('calculator_height_field')), '180');
      await tester.enterText(find.byKey(const Key('calculator_age_field')), '50');
      await tester.enterText(find.byKey(const Key('calculator_scr_field')), '4.5');
      await tester.pumpAndSettle();

      // Tap Calculate
      final calcBtn = find.byKey(const Key('calculator_calculate_button'));
      await tester.ensureVisible(calcBtn);
      await tester.tap(calcBtn);
      await tester.pumpAndSettle();

      // 1. Overdose banner MUST be visible per Rule 5
      expect(find.byKey(const Key('calculator_overdose_banner')), findsOneWidget);
      expect(find.textContaining('CLINICAL WARNING: Dose exceeds recommended maximum limits'), findsOneWidget);

      // 2. CRRT badge MUST be visible
      expect(find.byKey(const Key('calculator_crrt_badge')), findsOneWidget);
      expect(find.textContaining('CRRT: Continuous Dialysis Mode'), findsOneWidget);

      // 3. Calculated / Rounded dose MUST be visible and NOT hidden or zeroed out
      expect(find.textContaining('250'), findsWidgets);
      expect(find.textContaining('mg'), findsWidgets);
    });

    testWidgets('2. Extreme weight (250 kg) Vancomycin on IHD displays Overdose Banner and Post-HD badge simultaneously', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createVancomycinWidget(isThai: true));
      await tester.pumpAndSettle();

      // Select IHD mode
      await tester.tap(find.text('IHD'));
      await tester.pumpAndSettle();

      // Enter 250 kg
      await tester.enterText(find.byKey(const Key('calculator_weight_field')), '250');
      await tester.enterText(find.byKey(const Key('calculator_height_field')), '180');
      await tester.enterText(find.byKey(const Key('calculator_age_field')), '60');
      await tester.enterText(find.byKey(const Key('calculator_scr_field')), '6.0');
      await tester.pumpAndSettle();

      // Tap Calculate
      final calcBtn = find.byKey(const Key('calculator_calculate_button'));
      await tester.ensureVisible(calcBtn);
      await tester.tap(calcBtn);
      await tester.pumpAndSettle();

      // 1. Overdose banner MUST be rendered
      expect(find.byKey(const Key('calculator_overdose_banner')), findsOneWidget);
      expect(find.textContaining('ขนาดยานี้เกินเกณฑ์สูงสุดที่แนะนำ (Overdose Warning)'), findsOneWidget);

      // 2. Post-HD badge MUST be rendered
      expect(find.byKey(const Key('calculator_post_hd_badge')), findsOneWidget);
      expect(find.textContaining('Post-HD: ให้ยาหลังการฟอกเลือด'), findsOneWidget);

      // 3. Calculated dose (1875.00 mg) must be visible and NOT hidden
      expect(find.textContaining('1875.00 mg'), findsOneWidget);
    });

    testWidgets('3. Coexistence of Overdose Banner, RRT Badges, and Dosing Result exhibits zero RenderFlex overflow on 360x640 mobile', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      for (final isThai in [false, true]) {
        await tester.pumpWidget(createEnoxaparinWidget(isThai: isThai));
        await tester.pumpAndSettle();

        // Select CRRT
        await tester.ensureVisible(find.text('CRRT'));
        await tester.tap(find.text('CRRT'));
        await tester.pumpAndSettle();

        // Enter 250 kg
        await tester.enterText(find.byKey(const Key('calculator_weight_field')), '250');
        await tester.enterText(find.byKey(const Key('calculator_height_field')), '180');
        await tester.enterText(find.byKey(const Key('calculator_age_field')), '50');
        await tester.enterText(find.byKey(const Key('calculator_scr_field')), '4.5');
        await tester.pumpAndSettle();

        final calcBtn = find.byKey(const Key('calculator_calculate_button'));
        await tester.ensureVisible(calcBtn);
        await tester.tap(calcBtn);
        await tester.pumpAndSettle();

        // Assert no overflow exceptions thrown on 360x640
        expect(tester.takeException(), isNull, reason: 'Zero RenderFlex overflow on 360x640 mobile (isThai=$isThai)');
      }
    });
  });
}
