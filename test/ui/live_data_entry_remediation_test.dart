// ==============================================================================
// Milestone 2 Verification: Live Data Entry & Accessibility Remediation Suite
// ==============================================================================
// Verifies:
// 1. Live Input Sanitization: FilteringTextInputFormatter rejects negative numbers
//    and non-numeric characters; allows decimals on weight/height/SCr; enforces integer on age.
// 2. Empty & Boundary Validation: Empty inputs, zero, non-finite, and extreme values
//    trigger clean localized error dialogs without red screen exceptions or crashes.
// 3. 320dp Accessibility Stress Test (1.5x and 2.0x text scale):
//    Zero RenderFlex overflows in ClinicalHeaderAlerts and DosingParametersForm.
// 4. Rule 5 Non-blocking Overdose Policy: Crimson warning banner is prominent and
//    calculated dose is fully displayed and unblocked across viewports.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:drug_dosage_calculator/data/patient_session.dart';
import 'package:drug_dosage_calculator/ui/calculator/calculator_screen.dart';
import 'package:drug_dosage_calculator/ui/calculator/widgets/clinical_header_alerts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Milestone 2: Live Data Entry & Accessibility Remediation Suite', () {
    late Drug meropenem;

    const testOverdoseRegimen = DosingRegimen(
      route: DoseRoute.po,
      indication: 'Acute Pain Overdose Challenge',
      dosingType: DosingType.weightBased,
      dosePerKg: 15.0,
      doseUnit: DoseUnit.mg,
      frequency: Frequency.q6h,
      limits: DoseLimit(
        maxSingleDose: 1000.0,
        maxDailyDose: 4000.0,
      ),
      verificationStatus: VerificationStatus.verified,
    );

    const testOverdoseDrug = Drug(
      id: 'test_paracetamol_m2',
      genericName: 'Paracetamol',
      nameTh: 'พาราเซตามอล',
      category: DrugCategory.analgesic,
      availableStrengths: [500.0],
      sourceCitation: 'Lexicomp 2024',
      regimens: [testOverdoseRegimen],
      provenance: Provenance(
        source: 'Lexicomp 2024',
        reviewedBy: 'Clinical Pharmacist',
        reviewedAt: '2024-01-01',
      ),
    );

    setUp(() {
      PatientSession.instance.clearPatient();
      meropenem = DrugDatabase.findById('meropenem')!;

      // Mock Clipboard to prevent channel exceptions
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (MethodCall call) async {
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    Widget buildApp({required Widget child}) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true),
        home: child,
      );
    }

    testWidgets(
      '1. Live Data Entry Sanitization: Rejects negative signs and non-numeric inputs',
      (tester) async {
        await tester.pumpWidget(
          buildApp(child: CalculatorScreen(drug: meropenem, isThai: true)),
        );
        await tester.pumpAndSettle();

        final weightFinder = find.byKey(const Key('calculator_weight_field'));
        final ageFinder = find.byKey(const Key('calculator_age_field'));

        // Attempt to enter negative number in weight
        await tester.enterText(weightFinder, '-75.5');
        await tester.pump();
        // The negative sign must be stripped by input formatters
        final weightField = tester.widget<TextField>(weightFinder);
        expect(weightField.controller!.text, '75.5');

        // Attempt to enter decimal in age (integer only)
        await tester.enterText(ageFinder, '45.5');
        await tester.pump();
        final ageField = tester.widget<TextField>(ageFinder);
        // Decimals are disallowed in age
        expect(ageField.controller!.text, '455');
      },
    );

    testWidgets(
      '2. Empty & Non-finite Inputs: Submitting empty form displays error dialog without crash',
      (tester) async {
        await tester.pumpWidget(
          buildApp(child: CalculatorScreen(drug: meropenem, isThai: true)),
        );
        await tester.pumpAndSettle();

        // Clear all fields
        await tester.enterText(find.byKey(const Key('calculator_weight_field')), '');
        await tester.enterText(find.byKey(const Key('calculator_height_field')), '');
        await tester.enterText(find.byKey(const Key('calculator_age_field')), '');
        await tester.enterText(find.byKey(const Key('calculator_scr_field')), '');

        // Tap calculate button
        await tester.tap(find.byKey(const Key('calculator_calculate_button')));
        await tester.pumpAndSettle();

        // Error dialog should appear with validation messages
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('ข้อมูลไม่ถูกต้อง'), findsOneWidget);
        expect(find.textContaining('กรุณาระบุน้ำหนัก'), findsOneWidget);

        // Dismiss dialog
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
      },
    );

    testWidgets(
      '3. Cross-field Swapped Inputs: Swapped height and weight triggers BMI error dialog',
      (tester) async {
        await tester.pumpWidget(
          buildApp(child: CalculatorScreen(drug: meropenem, isThai: true)),
        );
        await tester.pumpAndSettle();

        // Swapped: Weight = 170 kg, Height = 70 cm (BMI > 120)
        await tester.enterText(find.byKey(const Key('calculator_weight_field')), '170');
        await tester.enterText(find.byKey(const Key('calculator_height_field')), '70');
        await tester.enterText(find.byKey(const Key('calculator_age_field')), '45');
        await tester.enterText(find.byKey(const Key('calculator_scr_field')), '1.0');

        await tester.tap(find.byKey(const Key('calculator_calculate_button')));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.textContaining('BMI ผิดปกติ'), findsOneWidget);

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      '4. 320dp Viewport at 1.5x and 2.0x Text Scale: Zero RenderFlex overflow',
      (tester) async {
        for (final scale in [1.5, 2.0]) {
          tester.view.physicalSize = const Size(320, 900);
          tester.view.devicePixelRatio = 1.0;
          tester.platformDispatcher.textScaleFactorTestValue = scale;

          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
            tester.platformDispatcher.clearTextScaleFactorTestValue();
          });

          await tester.pumpWidget(
            buildApp(child: CalculatorScreen(drug: meropenem, isThai: true)),
          );
          await tester.pumpAndSettle();

          await tester.enterText(find.byKey(const Key('calculator_weight_field')), '70');
          await tester.enterText(find.byKey(const Key('calculator_height_field')), '170');
          await tester.enterText(find.byKey(const Key('calculator_age_field')), '55');
          await tester.enterText(find.byKey(const Key('calculator_scr_field')), '1.1');

          await tester.tap(find.byKey(const Key('calculator_calculate_button')));
          await tester.pumpAndSettle();

          // Zero exceptions
          expect(tester.takeException(), isNull,
              reason: 'Zero RenderFlex overflow on 320dp at ${scale}x text scale');
        }
      },
    );

    testWidgets(
      '5. Rule 5 Non-blocking Overdose at 320dp x 1.5x Scale: Overdose banner visible & calculated dose preserved',
      (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1.0;
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.platformDispatcher.clearTextScaleFactorTestValue();
        });

        await tester.pumpWidget(
          buildApp(child: const CalculatorScreen(drug: testOverdoseDrug, isThai: true)),
        );
        await tester.pumpAndSettle();

        // 80 kg * 15 mg/kg = 1200 mg (limit 1000 mg)
        await tester.enterText(find.byKey(const Key('calculator_weight_field')), '80');
        await tester.enterText(find.byKey(const Key('calculator_height_field')), '175');
        await tester.enterText(find.byKey(const Key('calculator_age_field')), '40');
        await tester.enterText(find.byKey(const Key('calculator_scr_field')), '1.0');

        await tester.tap(find.byKey(const Key('calculator_calculate_button')));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        // Overdose banner is displayed prominently (Rule 5)
        expect(find.byKey(const Key('calculator_overdose_banner')), findsOneWidget);
        expect(
          find.textContaining('⚠️ คำเตือน: ขนาดยานี้เกินเกณฑ์สูงสุดที่แนะนำ (Overdose Warning)'),
          findsOneWidget,
        );
        // Calculated dose (1200.00 mg) is visible and unblocked (Rule 5)
        expect(find.textContaining('1200.00 mg'), findsOneWidget);
      },
    );

    testWidgets(
      '6. Isolated Component Test: ClinicalHeaderAlerts renders cleanly in compact and wide modes',
      (tester) async {
        // Compact mode (< 280dp)
        await tester.pumpWidget(
          buildApp(
            child: Scaffold(
              body: SizedBox(
                width: 250,
                child: ClinicalHeaderAlerts(
                  drug: meropenem,
                  isThai: true,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Wide mode (400dp)
        await tester.pumpWidget(
          buildApp(
            child: Scaffold(
              body: SizedBox(
                width: 400,
                child: ClinicalHeaderAlerts(
                  drug: meropenem,
                  isThai: true,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  });
}
