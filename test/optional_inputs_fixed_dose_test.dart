import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:drug_dosage_calculator/data/patient_session.dart';
import 'package:drug_dosage_calculator/ui/calculator/calculator_screen.dart';
import 'package:drug_dosage_calculator/ui/calculator/controllers/calculator_controller.dart';
import 'package:drug_dosage_calculator/ui/calculator/widgets/dosing_weight_logic_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PatientSession.instance.clearPatient();
  });

  tearDown(() {
    PatientSession.instance.clearPatient();
  });

  group('Item 5 — RegimenInputRequirements & Optional Adult Fixed-Dose Inputs',
      () {
    test('Drug.inputRequirementsFor classifies fixed adult vs weight/renal drugs',
        () {
      final fentanyl = DrugDatabase.findById('fentanyl')!;
      final ivPushReg =
          fentanyl.regimens.firstWhere((r) => r.route == DoseRoute.ivPush);
      final icuInfusionReg =
          fentanyl.regimens.firstWhere((r) => r.route == DoseRoute.ivInfusion);

      final fentanylPushReqs = fentanyl.inputRequirementsFor(ivPushReg);
      expect(fentanylPushReqs.isWeightRequired, isFalse);
      expect(fentanylPushReqs.isHeightRequired, isFalse);
      expect(fentanylPushReqs.isAgeRequired, isFalse);
      expect(fentanylPushReqs.isScrRequired, isFalse);
      expect(fentanylPushReqs.requiresHepaticEvaluation, isTrue);
      expect(fentanylPushReqs.canCalculateWithoutDemographics, isTrue);

      final fentanylInfusionReqs = fentanyl.inputRequirementsFor(icuInfusionReg);
      expect(fentanylInfusionReqs.isWeightRequired, isTrue);
      expect(fentanylInfusionReqs.isHeightRequired, isFalse);
      expect(fentanylInfusionReqs.canCalculateWithoutDemographics, isFalse);

      final amlodipine = DrugDatabase.findById('amlodipine')!;
      final amloReqs = amlodipine.inputRequirementsFor(amlodipine.regimens.first);
      expect(amloReqs.isWeightRequired, isFalse);
      expect(amloReqs.isHeightRequired, isFalse);
      expect(amloReqs.isAgeRequired, isFalse);
      expect(amloReqs.isScrRequired, isFalse);
      expect(amloReqs.canCalculateWithoutDemographics, isTrue);

      final apixaban = DrugDatabase.findById('apixaban')!;
      final apixabanReqs = apixaban.inputRequirementsFor(apixaban.regimens.first);
      expect(apixabanReqs.isWeightRequired, isTrue);
      expect(apixabanReqs.isAgeRequired, isTrue);
      expect(apixabanReqs.requiresRenalEvaluation, isTrue);
      expect(apixabanReqs.canCalculateWithoutDemographics, isFalse);

      final meropenem = DrugDatabase.findById('meropenem')!;
      final meroReqs = meropenem.inputRequirementsFor(meropenem.regimens.first);
      expect(meroReqs.isWeightRequired, isTrue);
      expect(meroReqs.isHeightRequired, isTrue);
      expect(meroReqs.isAgeRequired, isTrue);
      expect(meroReqs.requiresRenalEvaluation, isTrue);
      expect(meroReqs.canCalculateWithoutDemographics, isFalse);
    });

    test('CalculatorController calculates Fentanyl IV Push & Amlodipine PO without demographics and preserves empty session',
        () {
      final fentanyl = DrugDatabase.findById('fentanyl')!;
      final fentanylCtrl = CalculatorController(drug: fentanyl);
      addTearDown(fentanylCtrl.dispose);

      final valFent = fentanylCtrl.calculate(isThai: true);
      expect(valFent.isValid, isTrue);
      expect(fentanylCtrl.state.hasCalculatedResult, isTrue);
      expect(fentanylCtrl.state.result!.calculatedDose, equals(50.0));
      expect(fentanylCtrl.state.usedDefaultDemographics, isTrue);
      expect(fentanylCtrl.state.dosingWeightLabel, isNull);
      expect(fentanylCtrl.state.dosingWeightValue, isNull);
      expect(PatientSession.instance.currentPatient.value, isNull);

      final amlodipine = DrugDatabase.findById('amlodipine')!;
      final amloCtrl = CalculatorController(drug: amlodipine);
      addTearDown(amloCtrl.dispose);

      final valAmlo = amloCtrl.calculate(isThai: false);
      expect(valAmlo.isValid, isTrue);
      expect(amloCtrl.state.result!.calculatedDose, equals(5.0));
      expect(PatientSession.instance.currentPatient.value, isNull);
    });

    test('CalculatorController still rejects invalid values entered in optional fields on fixed-dose regimens',
        () {
      final amlodipine = DrugDatabase.findById('amlodipine')!;
      final ctrl = CalculatorController(drug: amlodipine);
      addTearDown(ctrl.dispose);

      ctrl.weightCtrl.text = '0';
      final zeroWeightRes = ctrl.calculate(isThai: false);
      expect(zeroWeightRes.isValid, isFalse);
      expect(zeroWeightRes.errorsEn.containsKey('weightKg'), isTrue);

      ctrl.weightCtrl.text = '';
      ctrl.ageCtrl.text = '999';
      final extremeAgeRes = ctrl.calculate(isThai: true);
      expect(extremeAgeRes.isValid, isFalse);
      expect(extremeAgeRes.errorsTh.containsKey('ageYears'), isTrue);
    });

    testWidgets(
      'Fentanyl IV Push calculates immediately without entering demographics, renders fixed-dose badge, hides DosingWeightLogicCard, and blocks blank weight when switched to ICU IV Infusion',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fentanyl = DrugDatabase.findById('fentanyl')!;
        await tester.pumpWidget(
          MaterialApp(
            home: CalculatorScreen(drug: fentanyl, isThai: true),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('calculator_input_requirements_banner')),
          findsOneWidget,
        );
        expect(find.textContaining('ขนาดยาผู้ใหญ่คงที่'), findsOneWidget);
        expect(
          find.byKey(const Key('calculator_hepatic_optional_hint')),
          findsOneWidget,
        );

        // Tap Calculate with empty Weight/Height/Age/SCr fields
        await tester.tap(find.byKey(const Key('calculator_calculate_button')));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(
          find.byKey(const Key('patient_header_fixed_dose_badge')),
          findsOneWidget,
        );
        expect(find.byType(DosingWeightLogicCard), findsNothing);
        expect(find.textContaining('50.00 mcg'), findsOneWidget);
        expect(PatientSession.instance.currentPatient.value, isNull);

        // Switch regimen from IV Push to Continuous Sedation/Analgesia (ICU) (IV Inf)
        final dropdown = find.byType(DropdownButton<DosingRegimen>);
        await tester.ensureVisible(dropdown);
        await tester.tap(dropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('Continuous Sedation').last);
        await tester.pumpAndSettle();

        expect(
          find.textContaining('ข้อมูลที่ต้องใช้สำหรับสูตรนี้: น้ำหนัก'),
          findsOneWidget,
        );

        // Tap Calculate with blank Weight on weight-based ICU infusion -> error dialog
        await tester.tap(find.byKey(const Key('calculator_calculate_button')));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.textContaining('กรุณาระบุน้ำหนัก'), findsOneWidget);
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Invalid value in optional field triggers error dialog on Amlodipine',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final amlodipine = DrugDatabase.findById('amlodipine')!;
        await tester.pumpWidget(
          MaterialApp(
            home: CalculatorScreen(drug: amlodipine, isThai: false),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('calculator_age_field')),
          '999',
        );
        await tester.tap(find.byKey(const Key('calculator_calculate_button')));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Invalid Input'), findsOneWidget);
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Compact viewports (320x480 and 320x900 @ 2.0x text scale) render without overflow on Fentanyl and Meropenem',
      (tester) async {
        final fentanyl = DrugDatabase.findById('fentanyl')!;
        final meropenem = DrugDatabase.findById('meropenem')!;

        for (final drug in [fentanyl, meropenem]) {
          tester.view.physicalSize = const Size(320, 480);
          tester.view.devicePixelRatio = 1.0;
          tester.platformDispatcher.clearTextScaleFactorTestValue();
          await tester.pumpWidget(
            MaterialApp(
              home: CalculatorScreen(
                key: ValueKey(drug.id),
                drug: drug,
                isThai: true,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          tester.view.physicalSize = const Size(320, 900);
          tester.platformDispatcher.textScaleFactorTestValue = 2.0;
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }

        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      },
    );
  });
}
