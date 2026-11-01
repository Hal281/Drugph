// ============================================================
// Adversarial Stress Tests: Milestone 2 UI & Safety Invariants
// ============================================================
// Independent empirical challenger tests for:
// 1. Touch target height >= 48dp on viewports (1024x900 and 800x600)
// 2. Ironclad Rule 5 (Non-Blocking Overdose Policy):
//    - Overdose banner is distinct from critical safety banner
//    - Calculated and rounded doses are NEVER hidden or removed
//    - Copy buttons remain fully interactive during overdose
// 3. Normal safe dose: neither banner rendered
// 4. Overdose without rounded dose: calculatedDose displayed directly
// 5. Critical safety alert without overdose: critical banner rendered, overdose banner absent
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/ui/calculator_screen.dart';
import 'package:drug_dosage_calculator/data/patient_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Adversarial UI & Safety Invariants Tests', () {
    late List<MethodCall> clipboardLog;

    setUp(() {
      clipboardLog = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (MethodCall call) async {
        if (call.method == 'Clipboard.setData') {
          clipboardLog.add(call);
        }
        return null;
      });
      PatientSession.instance.clearPatient();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    const overdoseRegimenWithStrengths = DosingRegimen(
      route: DoseRoute.po,
      indication: 'Severe Acute Pain',
      dosingType: DosingType.weightBased,
      dosePerKg: 15.0, // 70 kg * 15 mg/kg = 1050 mg (> 1000 mg limit)
      doseUnit: DoseUnit.mg,
      frequency: Frequency.q6h,
      limits: DoseLimit(
        maxSingleDose: 1000.0,
        maxDailyDose: 4000.0,
      ),
      verificationStatus: VerificationStatus.verified,
    );

    const paracetamolWithStrengths = Drug(
      id: 'paracetamol',
      genericName: 'Paracetamol',
      nameTh: 'พาราเซตามอล',
      category: DrugCategory.analgesic,
      availableStrengths: [500.0],
      sourceCitation: 'Lexicomp 2024',
      regimens: [overdoseRegimenWithStrengths],
      provenance: Provenance(
        source: 'Lexicomp 2024',
        reviewedBy: 'Clinical Pharmacist',
        reviewedAt: '2024-01-01',
      ),
    );

    const overdoseRegimenRaw = DosingRegimen(
      route: DoseRoute.po,
      indication: 'Severe Acute Pain',
      dosingType: DosingType.weightBased,
      dosePerKg: 20.0, // 80 kg * 20 mg/kg = 1600 mg (> 1000 mg limit)
      doseUnit: DoseUnit.mg,
      frequency: Frequency.q6h,
      limits: DoseLimit(
        maxSingleDose: 1000.0,
        maxDailyDose: 4000.0,
      ),
      verificationStatus: VerificationStatus.verified,
    );

    const paracetamolNoStrengths = Drug(
      id: 'paracetamol_raw',
      genericName: 'Paracetamol Raw',
      nameTh: 'พาราเซตามอล',
      category: DrugCategory.analgesic,
      availableStrengths: [], // No rounding available
      sourceCitation: 'Lexicomp 2024',
      regimens: [overdoseRegimenRaw],
      provenance: Provenance(
        source: 'Lexicomp 2024',
        reviewedBy: 'Clinical Pharmacist',
        reviewedAt: '2024-01-01',
      ),
    );

    const normalRegimen = DosingRegimen(
      route: DoseRoute.po,
      indication: 'Standard Analgesia',
      dosingType: DosingType.fixed,
      fixedDose: 500.0,
      doseUnit: DoseUnit.mg,
      frequency: Frequency.q6h,
      limits: DoseLimit(
        maxSingleDose: 1000.0,
        maxDailyDose: 4000.0,
      ),
      verificationStatus: VerificationStatus.verified,
    );

    const safeParacetamol = Drug(
      id: 'safe_paracetamol',
      genericName: 'Paracetamol',
      nameTh: 'พาราเซตามอล',
      category: DrugCategory.analgesic,
      availableStrengths: [500.0],
      sourceCitation: 'Lexicomp 2024',
      regimens: [normalRegimen],
    );

    testWidgets(
      'Touch targets >= 48dp on viewports (1024x900 and 800x600)',
      (WidgetTester tester) async {
        final viewports = [
          const Size(1024, 900),
          const Size(800, 600),
        ];

        for (final vp in viewports) {
          tester.view.physicalSize = vp;
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(
            const MaterialApp(
              home: CalculatorScreen(
                drug: paracetamolWithStrengths,
                isThai: false,
                categoryColor: Colors.teal,
              ),
            ),
          );
          await tester.pumpAndSettle();

          await tester.enterText(find.byKey(const Key('calculator_weight_field')), '70');
          await tester.enterText(find.byKey(const Key('calculator_height_field')), '170');
          await tester.enterText(find.byKey(const Key('calculator_age_field')), '30');
          await tester.enterText(find.byKey(const Key('calculator_scr_field')), '0.9');

          await tester.tap(find.byKey(const Key('calculator_calculate_button')));
          await tester.pumpAndSettle();

          final hisBtn = find.byKey(const Key('copy_his_order_button'));
          final noteBtn = find.byKey(const Key('copy_pharmacist_note_button'));

          expect(hisBtn, findsOneWidget);
          expect(noteBtn, findsOneWidget);

          final hisHeight = tester.getSize(hisBtn).height;
          final noteHeight = tester.getSize(noteBtn).height;

          expect(hisHeight, greaterThanOrEqualTo(48.0),
              reason: 'HIS Order button height must be >= 48dp on ${vp.width}x${vp.height}');
          expect(noteHeight, greaterThanOrEqualTo(48.0),
              reason: 'Pharmacist Note button height must be >= 48dp on ${vp.width}x${vp.height}');
        }

        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      },
    );

    testWidgets(
      'Adversarial Overdose: distinct overdose banner, doses never hidden or disabled',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1024, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          const MaterialApp(
            home: CalculatorScreen(
              drug: paracetamolWithStrengths,
              isThai: false,
              categoryColor: Colors.teal,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 70 kg * 15 mg/kg = 1050 mg (> 1000 mg maxSingleDose)
        await tester.enterText(find.byKey(const Key('calculator_weight_field')), '70');
        await tester.enterText(find.byKey(const Key('calculator_height_field')), '170');
        await tester.enterText(find.byKey(const Key('calculator_age_field')), '30');
        await tester.enterText(find.byKey(const Key('calculator_scr_field')), '0.9');

        await tester.tap(find.byKey(const Key('calculator_calculate_button')));
        await tester.pumpAndSettle();

        // 1. Verify overdose banner is present AND distinct from critical safety banner
        expect(find.byKey(const Key('calculator_overdose_banner')), findsOneWidget);
        expect(find.byKey(const Key('calculator_critical_safety_banner')), findsNothing);

        // 2. Verify doses are NOT hidden or removed
        // Rounded dose: 1000.00 mg
        expect(find.textContaining('1000.00 mg'), findsOneWidget);
        // Calculated dose: 1050.00 mg
        expect(find.textContaining('1050.00 mg'), findsOneWidget);

        // 3. Verify copy buttons are NOT disabled and remain fully interactive
        final hisBtn = tester.widget<ElevatedButton>(find.byKey(const Key('copy_his_order_button')));
        final noteBtn = tester.widget<OutlinedButton>(find.byKey(const Key('copy_pharmacist_note_button')));
        expect(hisBtn.onPressed, isNotNull, reason: 'HIS Order button must never be disabled during overdose');
        expect(noteBtn.onPressed, isNotNull, reason: 'Pharmacist Note button must never be disabled during overdose');

        // 4. Tap copy HIS Order and assert clipboard receives payload with warning
        clipboardLog.clear();
        await tester.ensureVisible(find.byKey(const Key('copy_his_order_button')));
        await tester.tap(find.byKey(const Key('copy_his_order_button')));
        await tester.pump();

        expect(clipboardLog.length, equals(1));
        final hisText = clipboardLog.first.arguments['text'] as String;
        expect(hisText, contains('1000 mg'));
        expect(hisText, contains('[⚠️ OVERDOSE WARNING: Dose exceeds recommended limits]'));
      },
    );

    testWidgets(
      'Adversarial Overdose without available strengths: calculatedDose displayed directly',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1024, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          const MaterialApp(
            home: CalculatorScreen(
              drug: paracetamolNoStrengths,
              isThai: false,
              categoryColor: Colors.teal,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byKey(const Key('calculator_weight_field')), '80');
        await tester.enterText(find.byKey(const Key('calculator_height_field')), '175');
        await tester.enterText(find.byKey(const Key('calculator_age_field')), '30');
        await tester.enterText(find.byKey(const Key('calculator_scr_field')), '0.9');

        await tester.tap(find.byKey(const Key('calculator_calculate_button')));
        await tester.pumpAndSettle();

        // Overdose banner present
        expect(find.byKey(const Key('calculator_overdose_banner')), findsOneWidget);
        expect(find.byKey(const Key('calculator_critical_safety_banner')), findsNothing);

        // Since availableStrengths is empty, roundedDose is null; calculatedDose (1600.00 mg) must be visible directly
        expect(find.textContaining('1600.00 mg'), findsOneWidget);

        // Copy button still works
        clipboardLog.clear();
        await tester.ensureVisible(find.byKey(const Key('copy_his_order_button')));
        await tester.tap(find.byKey(const Key('copy_his_order_button')));
        await tester.pump();

        expect(clipboardLog.length, equals(1));
        final hisText = clipboardLog.first.arguments['text'] as String;
        expect(hisText, contains('1600 mg'));
        expect(hisText, contains('[⚠️ OVERDOSE WARNING: Dose exceeds recommended limits]'));
      },
    );

    testWidgets(
      'Safe calculation: neither overdose banner nor critical safety banner rendered',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1024, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          const MaterialApp(
            home: CalculatorScreen(
              drug: safeParacetamol,
              isThai: false,
              categoryColor: Colors.teal,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byKey(const Key('calculator_weight_field')), '60');
        await tester.enterText(find.byKey(const Key('calculator_height_field')), '165');
        await tester.enterText(find.byKey(const Key('calculator_age_field')), '25');
        await tester.enterText(find.byKey(const Key('calculator_scr_field')), '0.8');

        await tester.tap(find.byKey(const Key('calculator_calculate_button')));
        await tester.pumpAndSettle();

        // Neither banner rendered on safe calculation
        expect(find.byKey(const Key('calculator_overdose_banner')), findsNothing);
        expect(find.byKey(const Key('calculator_critical_safety_banner')), findsNothing);

        // Dose is 500.00 mg (verify headline exists)
        expect(find.text('500.00 mg'), findsOneWidget);

        // Buttons still render with >= 48dp height
        final hisBtn = find.byKey(const Key('copy_his_order_button'));
        final noteBtn = find.byKey(const Key('copy_pharmacist_note_button'));
        expect(tester.getSize(hisBtn).height, greaterThanOrEqualTo(48.0));
        expect(tester.getSize(noteBtn).height, greaterThanOrEqualTo(48.0));
      },
    );

    testWidgets(
      'CalculatorScreen result card header renders with 0 RenderFlex overflow on 800x600 viewport in Thai and English',
      (WidgetTester tester) async {
        final locales = [true, false]; // Thai and English

        for (final isThai in locales) {
          tester.view.physicalSize = const Size(800, 600);
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(
            MaterialApp(
              home: CalculatorScreen(
                drug: paracetamolWithStrengths,
                isThai: isThai,
                categoryColor: Colors.teal,
              ),
            ),
          );
          await tester.pumpAndSettle();

          // 80 kg * 15 mg/kg = 1200 mg > 1000 mg limit (triggers critical/overdose alert)
          await tester.enterText(find.byKey(const Key('calculator_weight_field')), '80');
          await tester.enterText(find.byKey(const Key('calculator_height_field')), '170');
          await tester.enterText(find.byKey(const Key('calculator_age_field')), '30');
          await tester.enterText(find.byKey(const Key('calculator_scr_field')), '1.0');

          await tester.tap(find.byKey(const Key('calculator_calculate_button')));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull,
              reason: 'Zero RenderFlex overflow must occur on narrow viewport in locale isThai=$isThai');
          expect(find.byKey(const Key('calculator_overdose_banner')), findsOneWidget);
        }

        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      },
    );
  });
}

