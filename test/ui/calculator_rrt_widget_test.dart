import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:drug_dosage_calculator/data/patient_session.dart';
import 'package:drug_dosage_calculator/ui/calculator_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CalculatorScreen RRT Bedside UI & Badge Widget Tests', () {
    late Drug meropenem;

    setUp(() {
      PatientSession.instance.clearPatient();
      meropenem = DrugDatabase.findById('meropenem')!;
    });

    Widget createWidgetUnderTest({bool isThai = false}) {
      return MaterialApp(
        home: CalculatorScreen(
          drug: meropenem,
          isThai: isThai,
        ),
      );
    }

    testWidgets('1. RRT SegmentedButton renders with 4 segments and default None selected', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final selectorFinder = find.byKey(const Key('calculator_rrt_selector'));
      expect(selectorFinder, findsOneWidget);

      expect(find.text('None'), findsOneWidget);
      expect(find.text('IHD'), findsOneWidget);
      expect(find.text('CAPD'), findsOneWidget);
      expect(find.text('CRRT'), findsOneWidget);

      final selectorSize = tester.getSize(selectorFinder);
      expect(selectorSize.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('2. Selecting CRRT mode displays prominent CRRT badge in result section', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap CRRT segment
      await tester.tap(find.text('CRRT'));
      await tester.pumpAndSettle();

      // Enter weight and SCr
      await tester.enterText(find.byKey(const Key('calculator_weight_field')), '70');
      await tester.enterText(find.byKey(const Key('calculator_height_field')), '170');
      await tester.enterText(find.byKey(const Key('calculator_age_field')), '55');
      await tester.enterText(find.byKey(const Key('calculator_scr_field')), '4.0');
      await tester.pumpAndSettle();

      // Tap Calculate
      final calcBtn = find.byKey(const Key('calculator_calculate_button'));
      await tester.ensureVisible(calcBtn);
      await tester.tap(calcBtn);
      await tester.pumpAndSettle();

      // Result card should render CRRT badge
      expect(find.byKey(const Key('calculator_crrt_badge')), findsOneWidget);
      expect(find.textContaining('CRRT: Continuous Dialysis Mode'), findsOneWidget);
    });

    testWidgets('3. Selecting IHD mode for Meropenem displays Post-HD badge in result section', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest(isThai: true));
      await tester.pumpAndSettle();

      // Tap IHD segment
      await tester.tap(find.text('IHD'));
      await tester.pumpAndSettle();

      // Enter patient inputs
      await tester.enterText(find.byKey(const Key('calculator_weight_field')), '70');
      await tester.enterText(find.byKey(const Key('calculator_height_field')), '170');
      await tester.enterText(find.byKey(const Key('calculator_age_field')), '65');
      await tester.enterText(find.byKey(const Key('calculator_scr_field')), '5.0');
      await tester.pumpAndSettle();

      // Tap Calculate
      final calcBtn = find.byKey(const Key('calculator_calculate_button'));
      await tester.ensureVisible(calcBtn);
      await tester.tap(calcBtn);
      await tester.pumpAndSettle();

      // Result card should render Post-HD badge
      expect(find.byKey(const Key('calculator_post_hd_badge')), findsOneWidget);
      expect(find.textContaining('Post-HD: ให้ยาหลังการฟอกเลือด'), findsOneWidget);
    });

    testWidgets('4. Responsive layout resilience without RenderFlex overflow on 360x640 and 1024x900', (WidgetTester tester) async {
      final viewports = [
        const Size(360, 640),
        const Size(1024, 900),
      ];

      for (final vp in viewports) {
        tester.view.physicalSize = vp;
        tester.view.devicePixelRatio = 1.0;

        for (final isThai in [false, true]) {
          await tester.pumpWidget(createWidgetUnderTest(isThai: isThai));
          await tester.pumpAndSettle();

          // Select CRRT
          final crrtSeg = find.text('CRRT');
          await tester.ensureVisible(crrtSeg);
          await tester.tap(crrtSeg);
          await tester.pumpAndSettle();

          // Enter inputs and calculate
          await tester.enterText(find.byKey(const Key('calculator_weight_field')), '70');
          await tester.enterText(find.byKey(const Key('calculator_height_field')), '170');
          await tester.enterText(find.byKey(const Key('calculator_age_field')), '55');
          await tester.enterText(find.byKey(const Key('calculator_scr_field')), '4.0');
          await tester.pumpAndSettle();

          final calcBtn = find.byKey(const Key('calculator_calculate_button'));
          await tester.ensureVisible(calcBtn);
          await tester.tap(calcBtn);
          await tester.pumpAndSettle();

          expect(
            tester.takeException(),
            isNull,
            reason: 'No RenderFlex overflow on ${vp.width}x${vp.height} with isThai=$isThai',
          );
        }
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
