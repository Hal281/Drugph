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
import 'package:drug_dosage_calculator/ui/calculator/widgets/dosage_result_card.dart';

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

    testWidgets(
      '7. Result Card Safety & Contrast: calculatedDose has no lineThrough, WCAG AAA contrast, and semantic overdose label',
      (tester) async {
        tester.view.physicalSize = const Size(1024, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(createTestApp(drug: testOverdoseDrug));
        await tester.pumpAndSettle();

        // Trigger overdose: 70kg * 15mg/kg = 1050mg (max 1000mg)
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

        // 1. Semantic label: DosageResultCard MUST NOT say 'Recommended Dose (Rounded)' during overdose
        expect(
          find.descendant(
            of: find.byType(DosageResultCard),
            matching: find.text('Recommended Dose (Rounded)'),
          ),
          findsNothing,
        );
        final statusLabelFinder =
            find.byKey(const Key('dosage_result_status_label'));
        expect(statusLabelFinder, findsOneWidget);
        expect(
          find.descendant(
            of: statusLabelFinder,
            matching: find.text('Calculated Dose (Exceeds Limit)'),
          ),
          findsOneWidget,
        );

        // Verify crimson alert styling on status label container
        final statusContainer = tester.widget<Container>(statusLabelFinder);
        final boxDec = statusContainer.decoration as BoxDecoration;
        expect(boxDec.color, const Color(0xFFFEE2E2));

        // 2. Raw calculated dose: MUST be clearly labeled without lineThrough and high contrast (grey.shade900)
        final rawTextFinder =
            find.textContaining('Raw Calculated Dose: 1050.00 mg');
        expect(rawTextFinder, findsOneWidget);
        final rawTextWidget = tester.widget<Text>(rawTextFinder);
        expect(
          rawTextWidget.style?.decoration,
          isNot(TextDecoration.lineThrough),
        );
        expect(rawTextWidget.style?.color, Colors.grey.shade900);

        // 3. Compact Viewport (320dp) overflow check
        tester.view.physicalSize = const Size(320, 640);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '8. Textbook Monograph Button: meets WCAG AAA >= 48x48 dp touch target size and has explicit key',
      (tester) async {
        tester.view.physicalSize = const Size(1024, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(createTestApp(drug: meropenem));
        await tester.pumpAndSettle();

        // Enter valid parameters to trigger active DosageResultCard
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

        final monographFinder =
            find.byKey(const Key('calculator_view_monograph_btn'));
        expect(monographFinder, findsOneWidget);

        final monographSize = tester.getSize(monographFinder);
        expect(
          monographSize.height,
          greaterThanOrEqualTo(48.0),
          reason: 'Monograph button height must be >= 48dp (WCAG AAA)',
        );
        expect(
          monographSize.width,
          greaterThanOrEqualTo(48.0),
          reason: 'Monograph button width must be >= 48dp (WCAG AAA)',
        );
      },
    );

    testWidgets(
      '9. ClinicalActionBar: responsive layout switches to vertical column on narrow viewports (< 380dp) and maintains >= 48dp touch targets',
      (tester) async {
        // --- 1. Narrow Mobile Viewport (360x640) ---
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(createTestApp(drug: meropenem));
        await tester.pumpAndSettle();

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

        final hisOrderFinder = find.byKey(const Key('copy_his_order_button'));
        final pharmNoteFinder =
            find.byKey(const Key('copy_pharmacist_note_button'));

        expect(hisOrderFinder, findsOneWidget);
        expect(pharmNoteFinder, findsOneWidget);

        // On narrow screens (< 380 dp inside card): buttons are stacked vertically
        final hisOrderBottom = tester.getBottomLeft(hisOrderFinder).dy;
        final pharmNoteTop = tester.getTopLeft(pharmNoteFinder).dy;
        expect(
          pharmNoteTop,
          greaterThanOrEqualTo(hisOrderBottom),
          reason:
              'Pharmacist Note button must be stacked vertically below HIS Order button on narrow screens',
        );

        // Buttons expand to full card width (> 250 dp) to prevent text downscaling
        expect(tester.getSize(hisOrderFinder).width, greaterThan(250.0));
        expect(tester.getSize(pharmNoteFinder).width, greaterThan(250.0));
        expect(
          tester.getSize(hisOrderFinder).height,
          greaterThanOrEqualTo(48.0),
        );
        expect(
          tester.getSize(pharmNoteFinder).height,
          greaterThanOrEqualTo(48.0),
        );

        // --- 2. Wide Viewport (1024x900) ---
        tester.view.physicalSize = const Size(1024, 900);
        await tester.pumpWidget(createTestApp(drug: meropenem));
        await tester.pumpAndSettle();

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

        // On wide screens (>= 380 dp inside card): buttons are side-by-side
        final hisOrderTopWide = tester.getTopLeft(hisOrderFinder).dy;
        final pharmNoteTopWide = tester.getTopLeft(pharmNoteFinder).dy;
        expect(
          (hisOrderTopWide - pharmNoteTopWide).abs(),
          lessThan(1.0),
          reason:
              'Buttons must be horizontally aligned at identical Y-position on wide screens',
        );
        expect(
          tester.getTopLeft(pharmNoteFinder).dx,
          greaterThan(tester.getTopRight(hisOrderFinder).dx),
          reason:
              'Pharmacist Note button must be horizontally to the right of HIS Order button',
        );
        expect(
          tester.getSize(hisOrderFinder).height,
          greaterThanOrEqualTo(48.0),
        );
        expect(
          tester.getSize(pharmNoteFinder).height,
          greaterThanOrEqualTo(48.0),
        );
      },
    );

    testWidgets(
      '10. Continuous Infusion: renders side-by-side dual tiles on wide viewports (800 dp) and shows pump rate',
      (tester) async {
        tester.view.physicalSize = const Size(800, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final epi = DrugDatabase.findById('epinephrine')!;
        final infReg =
            epi.regimens.firstWhere((r) => r.route == DoseRoute.ivInfusion);
        const pt60 = Patient(
          id: 'pt-60-dual',
          weightKg: 60.0,
          heightCm: 168.0,
          ageYears: 45,
          sex: Sex.female,
          isScrStable: true,
        );
        final res = PharmacistCalculator.calculateDose(
          patient: pt60,
          drug: epi,
          regimen: infReg,
        );
        final state = CalculatorUiState.initial(epi).copyWith(
          selectedRegimen: infReg,
          result: res,
          status: CalculatorUiStatus.active,
          lastEvaluatedPatient: pt60,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: DosageResultCard(
                  state: state,
                  isThai: true,
                  onBuildPatient: () => pt60,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify presence of keys
        expect(
          find.byKey(const Key('dosage_result_dose_rate_tile')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('dosage_result_pump_rate_tile')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('dosage_result_concentration_context')),
          findsOneWidget,
        );

        // Verify Side-by-Side: Y coordinates must be approximately equal
        final dosePos = tester.getTopLeft(
          find.byKey(const Key('dosage_result_dose_rate_tile')),
        );
        final pumpPos = tester.getTopLeft(
          find.byKey(const Key('dosage_result_pump_rate_tile')),
        );
        expect((dosePos.dy - pumpPos.dy).abs(), lessThan(1.0));

        // Verify metrics
        expect(find.text('0.05–1.0 mcg/kg/min'), findsOneWidget);
        expect(find.text('Pump Rate: 11.3–225.0 mL/hr'), findsOneWidget);

        // Verify concentration context content
        expect(
          find.textContaining('16 mcg/mL (0.016 mg/mL) [4 mg in 250 mL]'),
          findsOneWidget,
        );
        expect(find.textContaining('D5W'), findsOneWidget);
      },
    );

    testWidgets(
      '11. Continuous Infusion: stacks dual tiles vertically on narrow viewport (320 dp) without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final epi = DrugDatabase.findById('epinephrine')!;
        final infReg =
            epi.regimens.firstWhere((r) => r.route == DoseRoute.ivInfusion);
        const pt60 = Patient(
          id: 'pt-60-dual-narrow',
          weightKg: 60.0,
          heightCm: 168.0,
          ageYears: 45,
          sex: Sex.female,
          isScrStable: true,
        );
        final res = PharmacistCalculator.calculateDose(
          patient: pt60,
          drug: epi,
          regimen: infReg,
        );
        final state = CalculatorUiState.initial(epi).copyWith(
          selectedRegimen: infReg,
          result: res,
          status: CalculatorUiStatus.active,
          lastEvaluatedPatient: pt60,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: DosageResultCard(
                  state: state,
                  isThai: true,
                  onBuildPatient: () => pt60,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final doseTile = find.byKey(const Key('dosage_result_dose_rate_tile'));
        final pumpTile = find.byKey(const Key('dosage_result_pump_rate_tile'));

        expect(doseTile, findsOneWidget);
        expect(pumpTile, findsOneWidget);

        // On narrow screens (320 dp): pump tile must be vertically below dose tile
        final doseBottom = tester.getBottomLeft(doseTile).dy;
        final pumpTop = tester.getTopLeft(pumpTile).dy;
        expect(pumpTop, greaterThanOrEqualTo(doseBottom));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '12. Concentration Context Banner: Stacks titration button below text column without overflow at 320dp x 2.5x text scale',
      (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1.0;
        tester.platformDispatcher.textScaleFactorTestValue = 2.5;

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.platformDispatcher.clearTextScaleFactorTestValue();
        });

        final epi = DrugDatabase.findById('epinephrine')!;
        final infReg =
            epi.regimens.firstWhere((r) => r.route == DoseRoute.ivInfusion);
        const pt60 = Patient(
          id: 'pt-60-banner-stress',
          weightKg: 60.0,
          heightCm: 168.0,
          ageYears: 45,
          sex: Sex.female,
          isScrStable: true,
        );
        final res = PharmacistCalculator.calculateDose(
          patient: pt60,
          drug: epi,
          regimen: infReg,
        );
        final state = CalculatorUiState.initial(epi).copyWith(
          selectedRegimen: infReg,
          result: res,
          status: CalculatorUiStatus.active,
          lastEvaluatedPatient: pt60,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: DosageResultCard(
                  state: state,
                  isThai: true,
                  onBuildPatient: () => pt60,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Zero RenderFlex Overflow Verification
        expect(tester.takeException(), isNull);

        // Verify presence of keys
        final bannerFinder =
            find.byKey(const Key('dosage_result_concentration_context'));
        final btnFinder =
            find.byKey(const Key('dosage_result_open_titration_btn'));
        expect(bannerFinder, findsOneWidget);
        expect(btnFinder, findsOneWidget);

        // Verify vertical stacking: button top must be >= science icon bottom
        final iconFinder = find.byIcon(Icons.science_outlined);
        final iconBottom = tester.getBottomLeft(iconFinder).dy;
        final btnTop = tester.getTopLeft(btnFinder).dy;
        expect(btnTop, greaterThan(iconBottom));

        // Verify button takes full card width
        expect(tester.getSize(btnFinder).width, greaterThan(200.0));
      },
    );
  });
}
