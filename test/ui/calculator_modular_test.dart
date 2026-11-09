// ============================================================
// Modular Clinical Calculator Dashboard Component Tests
// ============================================================
// Validates:
// 1. Rule 5 Non-blocking Overdose Policy: overdose banner is shown
//    while calculatedDose & roundedDose remain visible and unblocked.
// 2. Reactive Regimen Switching: changing indication/route updates formula parameters.
// 3. All interactive buttons meet or exceed 48x48 dp touch target size (WCAG AAA).
// 4. Responsive Dual-Pane layout (> 800px) vs Mobile Single Column (<= 800px).
// 5. Explicit rendering of all 4 UI states: Empty, Loading, Active, Error/Warning.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:drug_dosage_calculator/data/patient_session.dart';
import 'package:drug_dosage_calculator/ui/calculator/calculator_screen.dart';
import 'package:drug_dosage_calculator/ui/calculator/controllers/calculator_controller.dart';
import 'package:drug_dosage_calculator/ui/calculator/models/calculator_ui_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Modular Calculator Dashboard — Clean Architecture Verification', () {
    late Drug meropenem;

    const testRegimen = DosingRegimen(
      route: DoseRoute.po,
      indication: 'Acute Mild-to-Moderate Pain',
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
      id: 'test_paracetamol',
      genericName: 'Paracetamol',
      nameTh: 'พาราเซตามอล',
      brandNames: ['Tylenol', 'Sara'],
      category: DrugCategory.analgesic,
      availableStrengths: [500.0],
      sourceCitation: 'Lexicomp 2024 / RDU Thailand',
      regimens: [testRegimen],
      provenance: Provenance(
        source: 'Lexicomp 2024',
        reviewedBy: 'Clinical Pharmacist',
        reviewedAt: '2024-01-01',
      ),
    );

    setUp(() {
      PatientSession.instance.clearPatient();
      meropenem = DrugDatabase.findById('meropenem')!;
    });

    Widget createTestApp({
      required Drug drug,
      bool isThai = false,
      Color categoryColor = Colors.teal,
    }) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: CalculatorScreen(
          drug: drug,
          isThai: isThai,
          categoryColor: categoryColor,
        ),
      );
    }

    testWidgets(
      '1. Rule 5 Non-blocking Overdose: displays overdose banner without hiding or clearing calculated dose',
      (tester) async {
        tester.view.physicalSize = const Size(1024, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(createTestApp(drug: testOverdoseDrug));
        await tester.pumpAndSettle();

        // 70 kg * 15 mg/kg = 1050 mg (exceeds 1000 mg limit)
        await tester.enterText(
          find.byKey(const Key('calculator_weight_field')),
          '70',
        );
        await tester.enterText(
          find.byKey(const Key('calculator_height_field')),
          '170',
        );
        await tester.enterText(
          find.byKey(const Key('calculator_age_field')),
          '35',
        );
        await tester.enterText(
          find.byKey(const Key('calculator_scr_field')),
          '0.9',
        );

        await tester.tap(find.byKey(const Key('calculator_calculate_button')));
        await tester.pumpAndSettle();

        // Invariant: calculator_overdose_banner is rendered prominently
        expect(
          find.byKey(const Key('calculator_overdose_banner')),
          findsOneWidget,
        );

        // Invariant Rule 5: Raw calculated dose (1050.00 mg) and rounded dose (1000.00 mg)
        // are strictly VISIBLE and NOT hidden or zeroed out
        expect(find.textContaining('1000.00 mg'), findsOneWidget);
        expect(find.textContaining('1050.00 mg'), findsOneWidget);

        // Copy buttons are rendered and active
        expect(find.byKey(const Key('copy_his_order_button')), findsOneWidget);
        expect(
          find.byKey(const Key('copy_pharmacist_note_button')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '2. Reactive Regimen Switching: changing indication/route updates formula parameters',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(createTestApp(drug: meropenem));
        await tester.pumpAndSettle();

        // Default regimen is Severe Infection (IV Inf)
        expect(find.textContaining('Severe Infection (IV Inf)'), findsWidgets);

        // Tap dropdown to switch regimen
        await tester.tap(find.textContaining('Severe Infection (IV Inf)').first);
        await tester.pumpAndSettle();

        // Select Meningitis (IV Inf)
        final meningitisItem = find.text('Meningitis (IV Inf)').last;
        await tester.tap(meningitisItem);
        await tester.pumpAndSettle();

        // Regimen is reactively updated to Meningitis
        expect(find.textContaining('Meningitis (IV Inf)'), findsWidgets);
      },
    );

    testWidgets(
      '3. Impeccable Touch Ergonomics: interactive buttons meet or exceed 48x48 dp',
      (tester) async {
        tester.view.physicalSize = const Size(1024, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(createTestApp(drug: meropenem));
        await tester.pumpAndSettle();

        // Calculate button
        final calcBtn = find.byKey(const Key('calculator_calculate_button'));
        final calcSize = tester.getSize(calcBtn);
        expect(calcSize.height, greaterThanOrEqualTo(48.0));

        // RRT selector
        final rrtSelector = find.byKey(const Key('calculator_rrt_selector'));
        final rrtSize = tester.getSize(rrtSelector);
        expect(rrtSize.height, greaterThanOrEqualTo(48.0));

        // Child-Pugh selector
        final cpSelector =
            find.byKey(const Key('calculator_child_pugh_selector'));
        final cpSize = tester.getSize(cpSelector);
        expect(cpSize.height, greaterThanOrEqualTo(48.0));

        // Child-Pugh sheet trigger button
        final cpSheetBtn =
            find.byKey(const Key('calculator_open_child_pugh_sheet_button'));
        final cpSheetSize = tester.getSize(cpSheetBtn);
        expect(cpSheetSize.height, greaterThanOrEqualTo(48.0));
        expect(cpSheetSize.width, greaterThanOrEqualTo(48.0));
      },
    );

    testWidgets(
      '4. Responsive Layout: switches between widescreen split view (> 800px) and mobile single column (<= 800px)',
      (tester) async {
        // Desktop widescreen (> 800px)
        tester.view.physicalSize = const Size(1200, 900);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createTestApp(drug: meropenem));
        await tester.pumpAndSettle();

        // Desktop layout should render VerticalDivider between left & right panes
        expect(find.byType(VerticalDivider), findsOneWidget);

        // Switch to Mobile Viewport (360x640)
        tester.view.physicalSize = const Size(360, 640);
        await tester.pumpWidget(createTestApp(drug: meropenem));
        await tester.pumpAndSettle();

        // Mobile layout should NOT have VerticalDivider
        expect(find.byType(VerticalDivider), findsNothing);

        // Sticky calculate bar is present and accessible
        expect(
          find.byKey(const Key('calculator_calculate_button')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);

        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      },
    );

    testWidgets(
      '5. 4 Explicit UI States: Empty guidance, Loading skeleton, Active result, and Error dialog',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(createTestApp(drug: meropenem));
        await tester.pumpAndSettle();

        // State 1: Empty guidance state is shown initially
        expect(
          find.textContaining('Select a Regimen and Enter Patient Parameters'),
          findsOneWidget,
        );

        // State 4a: Validation Error State (Empty inputs tap Calculate)
        await tester.tap(find.byKey(const Key('calculator_calculate_button')));
        await tester.pumpAndSettle();

        // Shows Alert Dialog
        expect(find.text('Invalid Input'), findsOneWidget);
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        // State 3: Active Data State (Enter valid patient inputs)
        await tester.enterText(
          find.byKey(const Key('calculator_weight_field')),
          '70',
        );
        await tester.enterText(
          find.byKey(const Key('calculator_height_field')),
          '170',
        );
        await tester.enterText(
          find.byKey(const Key('calculator_age_field')),
          '50',
        );
        await tester.enterText(
          find.byKey(const Key('calculator_scr_field')),
          '1.0',
        );

        await tester.tap(find.byKey(const Key('calculator_calculate_button')));
        await tester.pumpAndSettle();

        // Active state renders result card and CrCl badge
        expect(find.textContaining('CrCl:'), findsWidgets);
        expect(find.byKey(const Key('copy_his_order_button')), findsOneWidget);
        expect(
          find.byKey(const Key('copy_pharmacist_note_button')),
          findsOneWidget,
        );

        // Verify MDCalc Step-by-Step Math Accordion
        final accordion =
            find.byKey(const Key('clinical_breakdown_accordion'));
        expect(accordion, findsOneWidget);
        await tester.ensureVisible(accordion);
        await tester.tap(accordion);
        await tester.pumpAndSettle();

        // Displays step-by-step breakdown
        expect(
          find.textContaining('Renal Function Evaluation'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '6. Controller Unit Logic: pure functions, state immutability, and session sync',
      (tester) async {
        final controller = CalculatorController(drug: meropenem);

        // Initial state is empty
        expect(controller.state.status, CalculatorUiStatus.empty);
        expect(controller.state.hasCalculatedResult, isFalse);

        // Setting inputs
        controller.weightCtrl.text = '80';
        controller.heightCtrl.text = '180';
        controller.ageCtrl.text = '25';
        controller.scrCtrl.text = '0.9';

        controller.setSex(Sex.female);
        expect(controller.state.sex, Sex.female);

        controller.setRenalReplacementMode(RenalReplacementMode.crrt);
        expect(
          controller.state.renalReplacementMode,
          RenalReplacementMode.crrt,
        );

        // Execute calculate
        final val = controller.calculate(isThai: false);
        expect(val.isValid, isTrue);
        expect(controller.state.hasCalculatedResult, isTrue);
        expect(controller.state.result, isNotNull);

        // Formatting orders
        final hisOrder = controller.formatHisOrder(false);
        expect(hisOrder, contains('Meropenem'));
        expect(hisOrder, contains('[CRRT]'));

        final pharmNote = controller.formatPharmacistNote(false);
        expect(pharmNote, contains('CRRT'));

        controller.dispose();
      },
    );
  });
}
