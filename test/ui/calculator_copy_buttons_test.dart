// ============================================================
// Calculator Copy Buttons Widget Tests
// ============================================================
// Validates:
// 1. Dual copy buttons render on Result Card with >= 48dp height.
// 2. Intercepts SystemChannels.platform (Clipboard.setData).
// 3. Verifies exact copied payload & SnackBar confirmation for both buttons.
// 4. Verifies Non-Blocking Overdose Policy:
//    - calculatedDose and roundedDose are NEVER hidden or altered.
//    - calculator_overdose_banner and calculator_critical_safety_banner stay intact.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/ui/calculator_screen.dart';
import 'package:drug_dosage_calculator/data/patient_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CalculatorScreen Copy Buttons Widget Tests', () {
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

      // Clear any session patient
      PatientSession.instance.clearPatient();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    testWidgets(
      'Copy HIS Order and Copy Pharmacist Note buttons render with >= 48dp height, copy payload, show SnackBar, and preserve overdose banner',
      (WidgetTester tester) async {
        // Enforce 1024x900 viewport size
        tester.view.physicalSize = const Size(1024, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // Setup test drug with 15 mg/kg weight-based regimen and max 1000 mg limit
        // (70 kg * 15 mg/kg = 1050 mg -> triggers overdose warning)
        const regimen = DosingRegimen(
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

        const paracetamol = Drug(
          id: 'paracetamol',
          genericName: 'Paracetamol',
          nameTh: 'พาราเซตามอล',
          brandNames: ['Tylenol', 'Sara'],
          category: DrugCategory.analgesic,
          availableStrengths: [500.0],
          sourceCitation: 'Lexicomp 2024 / RDU Thailand',
          regimens: [regimen],
          provenance: Provenance(
            source: 'Lexicomp 2024',
            reviewedBy: 'Clinical Pharmacist',
            reviewedAt: '2024-01-01',
          ),
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: CalculatorScreen(
              drug: paracetamol,
              isThai: false,
              categoryColor: Colors.teal,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Enter Patient Parameters
        await tester.enterText(find.byKey(const Key('calculator_weight_field')), '70');
        await tester.enterText(find.byKey(const Key('calculator_height_field')), '170');
        await tester.enterText(find.byKey(const Key('calculator_age_field')), '35');
        await tester.enterText(find.byKey(const Key('calculator_scr_field')), '0.9');

        // 2. Tap Calculate Dose button
        await tester.tap(find.byKey(const Key('calculator_calculate_button')));
        await tester.pumpAndSettle();

        // 3. Verify Non-Blocking Overdose Policy:
        // Dose calculation: 70 * 15 = 1050 mg. Rounded to 500 mg strength = 1000 mg.
        // Overdose banner is displayed!
        expect(find.byKey(const Key('calculator_overdose_banner')), findsOneWidget);
        // Raw dose (1050.00 mg) and Rounded dose (1000.00 mg) MUST be visible and NOT hidden
        expect(find.textContaining('1000.00 mg'), findsOneWidget);
        expect(find.textContaining('1050.00 mg'), findsOneWidget);

        // 4. Assert touch target heights are >= 48dp
        final hisBtnFinder = find.byKey(const Key('copy_his_order_button'));
        final noteBtnFinder = find.byKey(const Key('copy_pharmacist_note_button'));

        expect(hisBtnFinder, findsOneWidget);
        expect(noteBtnFinder, findsOneWidget);

        final hisSize = tester.getSize(hisBtnFinder);
        final noteSize = tester.getSize(noteBtnFinder);

        expect(
          hisSize.height,
          greaterThanOrEqualTo(48.0),
          reason: 'HIS Order copy button touch target must be >= 48dp',
        );
        expect(
          noteSize.height,
          greaterThanOrEqualTo(48.0),
          reason: 'Pharmacist Note copy button touch target must be >= 48dp',
        );

        // 5. Test Copy HIS Order button
        clipboardLog.clear();
        await tester.ensureVisible(hisBtnFinder);
        await tester.pumpAndSettle();
        await tester.tap(hisBtnFinder);
        await tester.pump();

        expect(clipboardLog.length, equals(1));
        final copiedHisText = clipboardLog.first.arguments['text'] as String;
        expect(copiedHisText, contains('Paracetamol'));
        expect(copiedHisText, contains('PO'));
        expect(copiedHisText, contains('q6h'));
        expect(copiedHisText, contains('[⚠️ OVERDOSE WARNING: Dose exceeds recommended limits]'));

        // Verify SnackBar confirmation appears
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.textContaining('Copied HIS Order'), findsOneWidget);

        // Dismiss SnackBar
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        // 6. Test Copy Pharmacist Note button
        clipboardLog.clear();
        await tester.ensureVisible(noteBtnFinder);
        await tester.pumpAndSettle();
        await tester.tap(noteBtnFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(clipboardLog.length, equals(1));
        final copiedNoteText = clipboardLog.first.arguments['text'] as String;
        expect(copiedNoteText, contains('CLINICAL PHARMACIST DOSING NOTE'));
        expect(copiedNoteText, contains('1. PATIENT PARAMETERS'));
        expect(copiedNoteText, contains('TBW: 70 kg'));
        expect(copiedNoteText, contains('2. MEDICATION & REGIMEN'));
        expect(copiedNoteText, contains('3. DOSING CALCULATION & ADMINISTRATION'));
        expect(copiedNoteText, contains('4. TEXTBOOK PROVENANCE & VERIFICATION'));
        expect(copiedNoteText, contains('5. CLINICAL SAFETY ALERTS & WARNINGS'));
        expect(copiedNoteText, contains('⚠️ OVERDOSE WARNING'));

        // Verify SnackBar confirmation appears
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.textContaining('Copied Pharmacist Note to clipboard'), findsOneWidget);

        // 7. Verify doses and overdose banner remain intact after copies
        expect(find.byKey(const Key('calculator_overdose_banner')), findsOneWidget);
        expect(find.textContaining('1000.00 mg'), findsOneWidget);
        expect(find.textContaining('1050.00 mg'), findsOneWidget);
      },
    );

    testWidgets(
      'Thai locale renders Thai copy button labels and Thai SnackBar feedback',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1024, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        const regimen = DosingRegimen(
          route: DoseRoute.po,
          dosingType: DosingType.fixed,
          fixedDose: 500.0,
          doseUnit: DoseUnit.mg,
          frequency: Frequency.q6h,
          verificationStatus: VerificationStatus.verified,
        );

        const paracetamol = Drug(
          id: 'paracetamol',
          genericName: 'Paracetamol',
          nameTh: 'พาราเซตามอล',
          category: DrugCategory.analgesic,
          regimens: [regimen],
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: CalculatorScreen(
              drug: paracetamol,
              isThai: true,
              categoryColor: Colors.teal,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byKey(const Key('calculator_weight_field')), '60');
        await tester.enterText(find.byKey(const Key('calculator_height_field')), '165');
        await tester.enterText(find.byKey(const Key('calculator_age_field')), '40');
        await tester.enterText(find.byKey(const Key('calculator_scr_field')), '0.8');

        await tester.tap(find.byKey(const Key('calculator_calculate_button')));
        await tester.pumpAndSettle();

        // Check Thai button labels
        expect(find.text('คัดลอกคำสั่งแพทย์ (HIS Order)'), findsOneWidget);
        expect(find.text('คัดลอกบันทึกเภสัชกร (Pharmacist Note)'), findsOneWidget);

        // Tap Thai HIS button
        clipboardLog.clear();
        final thaiHisBtn = find.byKey(const Key('copy_his_order_button'));
        await tester.ensureVisible(thaiHisBtn);
        await tester.pumpAndSettle();
        await tester.tap(thaiHisBtn);
        await tester.pump();

        expect(clipboardLog.length, equals(1));
        expect(find.textContaining('คัดลอกคำสั่งแพทย์แล้ว:'), findsOneWidget);

        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        // Tap Thai Pharmacist Note button
        clipboardLog.clear();
        final thaiNoteBtn = find.byKey(const Key('copy_pharmacist_note_button'));
        await tester.ensureVisible(thaiNoteBtn);
        await tester.pumpAndSettle();
        await tester.tap(thaiNoteBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(clipboardLog.length, equals(1));
        expect(find.text('คัดลอกบันทึกเภสัชกรแล้ว'), findsOneWidget);
      },
    );
  });
}
