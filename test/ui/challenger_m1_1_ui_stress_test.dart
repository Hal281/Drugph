// ==============================================================================
// Challenger M1-1: UI Stress & Accessibility Adversarial Test Harness
// ==============================================================================
// Independent empirical verification for:
// 1. Viewport Matrix: 320dp, 360dp, 380dp, 412dp, 800dp, 1200dp at 1.0x baseline
// 2. Touch Ergonomics: Monograph & Copy Buttons strictly >= 48x48 dp (WCAG AAA)
// 3. Adaptive Action Bar: < 380 dp vertical stack vs >= 380 dp horizontal row
// 4. Continuous Infusion Dual Rate Tiles: < 360 dp vertical stack vs >= 360 dp side-by-side
// 5. Rule 5 Visual Invariants: WCAG AAA raw dose contrast and crimson overdose badges
// 6. Empirical Adversarial Failure Modes: Reproducing exact RenderFlex overflows
//    under accessibility scaling (1.5x, 2.0x, 2.5x)
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:drug_dosage_calculator/data/patient_session.dart';
import 'package:drug_dosage_calculator/ui/calculator/calculator_screen.dart';
import 'package:drug_dosage_calculator/ui/calculator/models/calculator_ui_state.dart';
import 'package:drug_dosage_calculator/ui/calculator/widgets/clinical_action_bar.dart';
import 'package:drug_dosage_calculator/ui/calculator/widgets/dosage_result_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Challenger M1-1: UI Stress & Accessibility Adversarial Suite', () {
    late Drug meropenem;
    late Drug epinephrine;

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
      id: 'test_paracetamol_od',
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
      epinephrine = DrugDatabase.findById('epinephrine')!;

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

    // Helper to build test app
    Widget buildApp({required Widget child}) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true),
        home: child,
      );
    }

    // =========================================================================
    // Dimension 1: Baseline Viewport Matrix (320, 360, 380, 412, 800, 1200 dp) at 1.0x Scale
    // =========================================================================
    final viewportWidths = <double>[320, 360, 380, 412, 800, 1200];

    for (final width in viewportWidths) {
      testWidgets(
        '1. Baseline Viewport ${width.toInt()}dp x 1.0x Scale: Meropenem Active Screen - Zero RenderFlex Overflow',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1.0;
          tester.platformDispatcher.textScaleFactorTestValue = 1.0;

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

          // Verify Zero RenderFlex Overflow at 1.0x scale
          expect(
            tester.takeException(),
            isNull,
            reason: 'Must have zero RenderFlex overflow at ${width}dp and 1.0x scale',
          );

          expect(find.byType(DosageResultCard), findsOneWidget);
          expect(find.byKey(const Key('copy_his_order_button')), findsOneWidget);
          expect(find.byKey(const Key('copy_pharmacist_note_button')), findsOneWidget);
          expect(find.byKey(const Key('calculator_view_monograph_btn')), findsOneWidget);
        },
      );
    }

    // =========================================================================
    // Dimension 2: Continuous Infusion Baseline Matrix across All Viewports (1.0x Scale)
    // =========================================================================
    for (final width in viewportWidths) {
      testWidgets(
        '2. Continuous Infusion Viewport ${width.toInt()}dp x 1.0x Scale: Zero Overflow & Dual Rates Visible',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1.0;
          tester.platformDispatcher.textScaleFactorTestValue = 1.0;

          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
            tester.platformDispatcher.clearTextScaleFactorTestValue();
          });

          final infReg = epinephrine.regimens
              .firstWhere((r) => r.route == DoseRoute.ivInfusion);
          const pt60 = Patient(
            id: 'pt-60-epi-challenger',
            weightKg: 60.0,
            heightCm: 168.0,
            ageYears: 45,
            sex: Sex.female,
            isScrStable: true,
          );
          final res = PharmacistCalculator.calculateDose(
            patient: pt60,
            drug: epinephrine,
            regimen: infReg,
          );
          final state = CalculatorUiState.initial(epinephrine).copyWith(
            selectedRegimen: infReg,
            result: res,
            status: CalculatorUiStatus.active,
            lastEvaluatedPatient: pt60,
          );

          await tester.pumpWidget(
            buildApp(
              child: Scaffold(
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

          expect(tester.takeException(), isNull);
          expect(find.byKey(const Key('dosage_result_dose_rate_tile')), findsOneWidget);
          expect(find.byKey(const Key('dosage_result_pump_rate_tile')), findsOneWidget);
          expect(find.byKey(const Key('dosage_result_concentration_context')), findsOneWidget);
          expect(find.textContaining('mcg/kg/min'), findsWidgets);
          expect(find.textContaining('mL/hr'), findsWidgets);
        },
      );
    }

    // =========================================================================
    // Dimension 3: Ergonomic Touch Target Verification (WCAG AAA >= 48x48 dp)
    // =========================================================================
    testWidgets(
      '3. Touch Target Ergonomics: Monograph & Copy Buttons strictly satisfy >= 48x48 dp across all viewports',
      (tester) async {
        for (final width in [320.0, 360.0, 380.0, 412.0, 800.0, 1200.0]) {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(
            buildApp(child: CalculatorScreen(drug: meropenem, isThai: true)),
          );
          await tester.pumpAndSettle();

          await tester.enterText(find.byKey(const Key('calculator_weight_field')), '70');
          await tester.enterText(find.byKey(const Key('calculator_height_field')), '170');
          await tester.enterText(find.byKey(const Key('calculator_age_field')), '50');
          await tester.enterText(find.byKey(const Key('calculator_scr_field')), '1.0');
          await tester.tap(find.byKey(const Key('calculator_calculate_button')));
          await tester.pumpAndSettle();

          // Monograph button
          final monoFinder = find.byKey(const Key('calculator_view_monograph_btn'));
          expect(monoFinder, findsOneWidget);
          final monoSize = tester.getSize(monoFinder);
          expect(
            monoSize.height,
            greaterThanOrEqualTo(48.0),
            reason: 'Monograph button height must be >= 48dp on width ${width}dp',
          );
          expect(
            monoSize.width,
            greaterThanOrEqualTo(48.0),
            reason: 'Monograph button width must be >= 48dp on width ${width}dp',
          );

          // HIS Order button
          final hisFinder = find.byKey(const Key('copy_his_order_button'));
          expect(hisFinder, findsOneWidget);
          final hisSize = tester.getSize(hisFinder);
          expect(
            hisSize.height,
            greaterThanOrEqualTo(48.0),
            reason: 'HIS Order button height must be >= 48dp on width ${width}dp',
          );
          expect(
            hisSize.width,
            greaterThanOrEqualTo(48.0),
            reason: 'HIS Order button width must be >= 48dp on width ${width}dp',
          );

          // Pharmacist Note button
          final pharmFinder = find.byKey(const Key('copy_pharmacist_note_button'));
          expect(pharmFinder, findsOneWidget);
          final pharmSize = tester.getSize(pharmFinder);
          expect(
            pharmSize.height,
            greaterThanOrEqualTo(48.0),
            reason: 'Pharmacist Note button height must be >= 48dp on width ${width}dp',
          );
          expect(
            pharmSize.width,
            greaterThanOrEqualTo(48.0),
            reason: 'Pharmacist Note button width must be >= 48dp on width ${width}dp',
          );
        }

        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      },
    );

    // =========================================================================
    // Dimension 4: ClinicalActionBar Adaptive Stacking Threshold (< 380 dp)
    // =========================================================================
    group('4. ClinicalActionBar Adaptive Stacking Threshold (< 380 dp)', () {
      final sub380Widths = <double>[300.0, 320.0, 350.0, 360.0, 379.0];
      final wideWidths = <double>[380.0, 400.0, 412.0, 600.0, 800.0];

      const pt = Patient(
        id: 'pt-sub380',
        weightKg: 70.0,
        heightCm: 170.0,
        ageYears: 50,
        sex: Sex.male,
        isScrStable: true,
      );

      for (final w in sub380Widths) {
        testWidgets(
          'Action Bar at container width ${w}dp: Stacks vertically in a Column without truncation',
          (tester) async {
            tester.view.physicalSize = Size(w, 800);
            tester.view.devicePixelRatio = 1.0;
            addTearDown(() {
              tester.view.resetPhysicalSize();
              tester.view.resetDevicePixelRatio();
            });

            final res = PharmacistCalculator.calculateDose(
              patient: pt,
              drug: meropenem,
              regimen: meropenem.regimens.first,
            );
            final state = CalculatorUiState.initial(meropenem).copyWith(
              selectedRegimen: meropenem.regimens.first,
              result: res,
              status: CalculatorUiStatus.active,
              lastEvaluatedPatient: pt,
            );

            await tester.pumpWidget(
              buildApp(
                child: Scaffold(
                  body: SizedBox(
                    width: w,
                    child: ClinicalActionBar(
                      state: state,
                      isThai: true,
                      onBuildPatient: () => pt,
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();

            final hisFinder = find.byKey(const Key('copy_his_order_button'));
            final pharmFinder = find.byKey(const Key('copy_pharmacist_note_button'));

            expect(hisFinder, findsOneWidget);
            expect(pharmFinder, findsOneWidget);

            // Stacking: Pharmacist Note top must be >= HIS Order bottom
            final hisBottom = tester.getBottomLeft(hisFinder).dy;
            final pharmTop = tester.getTopLeft(pharmFinder).dy;
            expect(
              pharmTop,
              greaterThanOrEqualTo(hisBottom),
              reason: 'On width $w (<380), buttons must stack vertically',
            );

            // Both buttons expand to full available width
            expect(tester.getSize(hisFinder).width, equals(w));
            expect(tester.getSize(pharmFinder).width, equals(w));
            expect(tester.takeException(), isNull);
          },
        );
      }

      for (final w in wideWidths) {
        testWidgets(
          'Action Bar at container width ${w}dp: Aligns horizontally in a Row',
          (tester) async {
            tester.view.physicalSize = Size(w, 800);
            tester.view.devicePixelRatio = 1.0;
            addTearDown(() {
              tester.view.resetPhysicalSize();
              tester.view.resetDevicePixelRatio();
            });

            final res = PharmacistCalculator.calculateDose(
              patient: pt,
              drug: meropenem,
              regimen: meropenem.regimens.first,
            );
            final state = CalculatorUiState.initial(meropenem).copyWith(
              selectedRegimen: meropenem.regimens.first,
              result: res,
              status: CalculatorUiStatus.active,
              lastEvaluatedPatient: pt,
            );

            await tester.pumpWidget(
              buildApp(
                child: Scaffold(
                  body: SizedBox(
                    width: w,
                    child: ClinicalActionBar(
                      state: state,
                      isThai: true,
                      onBuildPatient: () => pt,
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();

            final hisFinder = find.byKey(const Key('copy_his_order_button'));
            final pharmFinder = find.byKey(const Key('copy_pharmacist_note_button'));

            // Horizontal alignment: Top dy matches within 1dp
            final hisTop = tester.getTopLeft(hisFinder).dy;
            final pharmTop = tester.getTopLeft(pharmFinder).dy;
            expect(
              (hisTop - pharmTop).abs(),
              lessThan(1.0),
              reason: 'On width $w (>=380), buttons must be horizontally aligned',
            );

            // Pharmacist note is to the right of HIS order
            expect(
              tester.getTopLeft(pharmFinder).dx,
              greaterThan(tester.getTopRight(hisFinder).dx),
              reason: 'Pharmacist note must be horizontally to the right of HIS Order',
            );
            expect(tester.takeException(), isNull);
          },
        );
      }
    });

    // =========================================================================
    // Dimension 5: Continuous Infusion Dual Rate Tiles Stacking Threshold (< 360 dp)
    // =========================================================================
    group('5. Continuous Infusion Dual Rate Tiles Stacking Threshold (< 360 dp)', () {
      final sub360Widths = <double>[280.0, 300.0, 320.0, 340.0, 359.0];
      final wideInfusionWidths = <double>[360.0, 380.0, 412.0, 600.0, 800.0];

      const pt60 = Patient(
        id: 'pt-60-challenger-dual',
        weightKg: 60.0,
        heightCm: 168.0,
        ageYears: 45,
        sex: Sex.female,
        isScrStable: true,
      );

      for (final w in sub360Widths) {
        testWidgets(
          'Dual rate tiles at inner card width ${w}dp: Stacks vertically in a Column cleanly',
          (tester) async {
            tester.view.physicalSize = Size(w + 48, 900); // 48dp = 8dp card margin + 40dp card padding
            tester.view.devicePixelRatio = 1.0;
            addTearDown(() {
              tester.view.resetPhysicalSize();
              tester.view.resetDevicePixelRatio();
            });

            final infReg = epinephrine.regimens
                .firstWhere((r) => r.route == DoseRoute.ivInfusion);
            final res = PharmacistCalculator.calculateDose(
              patient: pt60,
              drug: epinephrine,
              regimen: infReg,
            );
            final state = CalculatorUiState.initial(epinephrine).copyWith(
              selectedRegimen: infReg,
              result: res,
              status: CalculatorUiStatus.active,
              lastEvaluatedPatient: pt60,
            );

            await tester.pumpWidget(
              buildApp(
                child: Scaffold(
                  body: SizedBox(
                    width: w + 48,
                    child: SingleChildScrollView(
                      child: DosageResultCard(
                        state: state,
                        isThai: true,
                        onBuildPatient: () => pt60,
                      ),
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

            // Pump Rate tile must be stacked below Dose Rate tile
            final doseBottom = tester.getBottomLeft(doseTile).dy;
            final pumpTop = tester.getTopLeft(pumpTile).dy;
            expect(
              pumpTop,
              greaterThanOrEqualTo(doseBottom),
              reason: 'On inner width $w (<360), dual rate tiles must stack vertically',
            );

            expect(tester.takeException(), isNull);
          },
        );
      }

      for (final w in wideInfusionWidths) {
        testWidgets(
          'Dual rate tiles at inner card width ${w}dp: Renders side-by-side horizontally',
          (tester) async {
            tester.view.physicalSize = Size(w + 48, 900);
            tester.view.devicePixelRatio = 1.0;
            addTearDown(() {
              tester.view.resetPhysicalSize();
              tester.view.resetDevicePixelRatio();
            });

            final infReg = epinephrine.regimens
                .firstWhere((r) => r.route == DoseRoute.ivInfusion);
            final res = PharmacistCalculator.calculateDose(
              patient: pt60,
              drug: epinephrine,
              regimen: infReg,
            );
            final state = CalculatorUiState.initial(epinephrine).copyWith(
              selectedRegimen: infReg,
              result: res,
              status: CalculatorUiStatus.active,
              lastEvaluatedPatient: pt60,
            );

            await tester.pumpWidget(
              buildApp(
                child: Scaffold(
                  body: SizedBox(
                    width: w + 48,
                    child: SingleChildScrollView(
                      child: DosageResultCard(
                        state: state,
                        isThai: true,
                        onBuildPatient: () => pt60,
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();

            final doseTile = find.byKey(const Key('dosage_result_dose_rate_tile'));
            final pumpTile = find.byKey(const Key('dosage_result_pump_rate_tile'));

            // Horizontally aligned: Top dy matches within 1dp
            final doseTop = tester.getTopLeft(doseTile).dy;
            final pumpTop = tester.getTopLeft(pumpTile).dy;
            expect(
              (doseTop - pumpTop).abs(),
              lessThan(1.0),
              reason: 'On inner width $w (>=360), tiles must be horizontally aligned',
            );

            // Pump Rate tile is to the right of Dose Rate tile
            expect(
              tester.getTopLeft(pumpTile).dx,
              greaterThan(tester.getTopRight(doseTile).dx),
              reason: 'Pump Rate tile must be to the right of Dose Rate tile',
            );

            expect(tester.takeException(), isNull);
          },
        );
      }
    });

    // =========================================================================
    // Dimension 6: Rule 5 Visual Invariants (High Contrast & Crimson Overdose Badge)
    // =========================================================================
    testWidgets(
      '6. Rule 5 Invariants: Overdose status badge is crimson and rawCalculatedDose has zero strikethrough & high contrast',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          buildApp(child: const CalculatorScreen(drug: testOverdoseDrug, isThai: true)),
        );
        await tester.pumpAndSettle();

        // 70 kg * 15 mg/kg = 1050 mg (> 1000 mg limit)
        await tester.enterText(find.byKey(const Key('calculator_weight_field')), '70');
        await tester.enterText(find.byKey(const Key('calculator_height_field')), '170');
        await tester.enterText(find.byKey(const Key('calculator_age_field')), '35');
        await tester.enterText(find.byKey(const Key('calculator_scr_field')), '0.9');

        await tester.tap(find.byKey(const Key('calculator_calculate_button')));
        await tester.pumpAndSettle();

        // 1. Non-blocking banner is present
        expect(find.byKey(const Key('calculator_overdose_banner')), findsOneWidget);

        // 2. Both calculated and rounded doses are visible
        expect(find.textContaining('1000.00 mg'), findsOneWidget);
        expect(find.textContaining('1050.00 mg'), findsOneWidget);

        // 3. Status badge is crimson alert (not green)
        final statusLabel = find.byKey(const Key('dosage_result_status_label'));
        expect(statusLabel, findsOneWidget);
        expect(find.text('ขนาดยาที่แนะนำ (ปัดเศษแล้ว)'), findsNothing);
        expect(find.text('ขนาดยาจากการคำนวณ (เกินเกณฑ์แนะนำ)'), findsOneWidget);

        final container = tester.widget<Container>(statusLabel);
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, const Color(0xFFFEE2E2));

        // 4. Raw dose text has no strikethrough and uses grey.shade900
        final rawTextFinder = find.textContaining('ขนาดยาคำนวณจริงก่อนปัดเศษ: 1050.00 mg');
        expect(rawTextFinder, findsOneWidget);
        final textWidget = tester.widget<Text>(rawTextFinder);
        expect(textWidget.style?.decoration, isNot(TextDecoration.lineThrough));
        expect(textWidget.style?.color, Colors.grey.shade900);
      },
    );

    // =========================================================================
    // Dimension 7: Empirical Adversarial Stress & Vulnerability Proofs
    // =========================================================================
    group('7. Empirical Adversarial Failure Modes (Vulnerability Reproduction)', () {
      testWidgets(
        'Regression Prevention 1: Concentration Context Banner in DosageResultCard zero RenderFlex overflow at 320dp x 2.0x Text Scale',
        (tester) async {
          tester.view.physicalSize = const Size(320, 900);
          tester.view.devicePixelRatio = 1.0;
          tester.platformDispatcher.textScaleFactorTestValue = 2.0;

          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
            tester.platformDispatcher.clearTextScaleFactorTestValue();
          });

          final infReg = epinephrine.regimens
              .firstWhere((r) => r.route == DoseRoute.ivInfusion);
          const pt60 = Patient(
            id: 'pt-60-vulnerability-proof',
            weightKg: 60.0,
            heightCm: 168.0,
            ageYears: 45,
            sex: Sex.female,
            isScrStable: true,
          );
          final res = PharmacistCalculator.calculateDose(
            patient: pt60,
            drug: epinephrine,
            regimen: infReg,
          );
          final state = CalculatorUiState.initial(epinephrine).copyWith(
            selectedRegimen: infReg,
            result: res,
            status: CalculatorUiStatus.active,
            lastEvaluatedPatient: pt60,
          );

          await tester.pumpWidget(
            buildApp(
              child: Scaffold(
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

          // Verify zero RenderFlex overflow after responsive refactor
          expect(
            tester.takeException(),
            isNull,
            reason: 'Must have zero RenderFlex overflow on 320dp x 2.0x scale after responsive refactor',
          );
          expect(find.byKey(const Key('dosage_result_concentration_context')), findsOneWidget);
          expect(find.byKey(const Key('dosage_result_open_titration_btn')), findsOneWidget);
        },
      );

      testWidgets(
        'Regression Prevention 2: Concentration Context Banner in DosageResultCard zero RenderFlex overflow at 320dp x 2.5x Text Scale',
        (tester) async {
          tester.view.physicalSize = const Size(320, 900);
          tester.view.devicePixelRatio = 1.0;
          tester.platformDispatcher.textScaleFactorTestValue = 2.5;

          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
            tester.platformDispatcher.clearTextScaleFactorTestValue();
          });

          final infReg = epinephrine.regimens
              .firstWhere((r) => r.route == DoseRoute.ivInfusion);
          const pt60 = Patient(
            id: 'pt-60-vulnerability-proof-25',
            weightKg: 60.0,
            heightCm: 168.0,
            ageYears: 45,
            sex: Sex.female,
            isScrStable: true,
          );
          final res = PharmacistCalculator.calculateDose(
            patient: pt60,
            drug: epinephrine,
            regimen: infReg,
          );
          final state = CalculatorUiState.initial(epinephrine).copyWith(
            selectedRegimen: infReg,
            result: res,
            status: CalculatorUiStatus.active,
            lastEvaluatedPatient: pt60,
          );

          await tester.pumpWidget(
            buildApp(
              child: Scaffold(
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

          // Verify zero RenderFlex overflow after responsive refactor
          expect(
            tester.takeException(),
            isNull,
            reason: 'Must have zero RenderFlex overflow on 320dp x 2.5x scale after responsive refactor',
          );
          expect(find.byKey(const Key('dosage_result_concentration_context')), findsOneWidget);
          expect(find.byKey(const Key('dosage_result_open_titration_btn')), findsOneWidget);
        },
      );

      testWidgets(
        'Vulnerability 3 Proof: Full Screen ClinicalHeaderAlerts & DosingParametersForm Zero RenderFlex overflow at 320dp x 1.5x and 2.0x Text Scale',
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

            // Assert zero RenderFlex overflow after Milestone 2 responsive refactor
            final exc = tester.takeException();
            expect(
              exc,
              isNull,
              reason: 'Full calculator screen must have zero RenderFlex overflow under ${scale}x accessibility scale',
            );
          }
        },
      );
    });
  });
}
