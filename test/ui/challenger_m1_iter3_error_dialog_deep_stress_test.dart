import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:drug_dosage_calculator/data/patient_session.dart';
import 'package:drug_dosage_calculator/ui/calculator_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Challenger M1 Iteration 3: Compact Viewports Error Dialog Verification', () {
    late Drug meropenem;
    late Drug vancomycin;

    setUp(() {
      PatientSession.instance.clearPatient();
      meropenem = DrugDatabase.findById('meropenem')!;
      vancomycin = DrugDatabase.findById('vancomycin')!;
    });

    Widget buildTestApp({
      required Drug drug,
      required bool isThai,
    }) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: CalculatorScreen(
          drug: drug,
          isThai: isThai,
        ),
      );
    }

    final compactViewports = [
      const Size(360, 640), // Standard compact Android/iOS
      const Size(320, 480), // Ultra-compact small phone
    ];

    testWidgets('Adversarial: Error dialog triggers on 320x480 & 360x640 with zero RenderFlex exceptions (EN & TH)', (WidgetTester tester) async {
      for (final vp in compactViewports) {
        for (final isThai in [false, true]) {
          tester.view.physicalSize = vp;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(buildTestApp(
            drug: meropenem,
            isThai: isThai,
          ));
          await tester.pumpAndSettle();

          // Attempt calculation with empty inputs to pop _showErrorDialog
          final calcBtn = find.byKey(const Key('calculator_calculate_button'));
          await tester.ensureVisible(calcBtn);
          await tester.tap(calcBtn);
          await tester.pumpAndSettle();

          // Verify AlertDialog is visible
          expect(find.byType(AlertDialog), findsOneWidget);

          // Crucial assertion: ZERO RenderFlex exceptions when dialog is active
          expect(
            tester.takeException(),
            isNull,
            reason: 'RenderFlex exception caught on ${vp.width}x${vp.height} with isThai=$isThai',
          );

          // Verify error dialog title text
          final expectedTitle = isThai ? 'ข้อมูลไม่ถูกต้อง' : 'Invalid Input';
          expect(find.text(expectedTitle), findsOneWidget);

          // Dismiss dialog
          final okBtn = find.text('OK');
          expect(okBtn, findsOneWidget);
          await tester.tap(okBtn);
          await tester.pumpAndSettle();

          expect(find.byType(AlertDialog), findsNothing);
          expect(tester.takeException(), isNull);
        }
      }
    });

    testWidgets('Adversarial: Partially invalid inputs (negative/garbage values) trigger error dialog cleanly across viewports', (WidgetTester tester) async {
      for (final vp in compactViewports) {
        for (final isThai in [false, true]) {
          tester.view.physicalSize = vp;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(buildTestApp(drug: vancomycin, isThai: isThai));
          await tester.pumpAndSettle();

          final weightField = find.byKey(const Key('calculator_weight_field'));
          await tester.ensureVisible(weightField);
          await tester.enterText(weightField, '-50');

          final heightField = find.byKey(const Key('calculator_height_field'));
          await tester.ensureVisible(heightField);
          await tester.enterText(heightField, 'invalid_height');

          final calcBtn = find.byKey(const Key('calculator_calculate_button'));
          await tester.ensureVisible(calcBtn);
          await tester.tap(calcBtn);
          await tester.pumpAndSettle();

          expect(find.byType(AlertDialog), findsOneWidget);
          expect(tester.takeException(), isNull);

          await tester.tap(find.text('OK'));
          await tester.pumpAndSettle();
          expect(find.byType(AlertDialog), findsNothing);
          expect(tester.takeException(), isNull);
        }
      }
    });
  });
}
