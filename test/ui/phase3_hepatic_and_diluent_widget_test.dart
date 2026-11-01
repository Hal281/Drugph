import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:drug_dosage_calculator/data/patient_session.dart';
import 'package:drug_dosage_calculator/ui/calculator_screen.dart';
import 'package:drug_dosage_calculator/ui/iv_titration_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Drug findDrug(String id) =>
      DrugDatabase.allDrugs.firstWhere((d) => d.id == id);

  setUp(() {
    PatientSession.instance.setPatient(
      const Patient(
        id: 'TEST-PHASE3',
        weightKg: 70.0,
        heightCm: 170.0,
        ageYears: 60,
        sex: Sex.male,
        serumCreatinineMgDl: 0.9,
        isScrStable: true,
      ),
    );
  });

  tearDown(() {
    PatientSession.instance.clearPatient();
  });

  group('Phase 3 UI — Child-Pugh Hepatic Calculator & DOAC Safety', () {
    testWidgets(
      'Child-Pugh bottom sheet computes Class B (9/15) and triggers Rivaroxaban hard contraindication with 0 overflow on 360x640',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final rivaroxaban = findDrug('rivaroxaban');
        await tester.pumpWidget(
          MaterialApp(
            home: CalculatorScreen(
              drug: rivaroxaban,
              isThai: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final openSheetBtn = find.byKey(
          const Key('calculator_open_child_pugh_sheet_button'),
        );
        await tester.ensureVisible(openSheetBtn);
        await tester.tap(openSheetBtn);
        await tester.pumpAndSettle();

        // Enter Bilirubin 2.5 (2 pts), Albumin 3.0 (2 pts), INR 1.9 (2 pts), Ascites Mild (2 pts), Encephalopathy None (1 pt) = 9/15 (Class B)
        await tester.enterText(
          find.byKey(const Key('child_pugh_bilirubin_field')),
          '2.5',
        );
        await tester.enterText(
          find.byKey(const Key('child_pugh_albumin_field')),
          '3.0',
        );
        await tester.enterText(
          find.byKey(const Key('child_pugh_inr_field')),
          '1.9',
        );
        await tester.pumpAndSettle();

        final mildAscitesText = find.text('Mild (2)');
        await tester.ensureVisible(mildAscitesText);
        await tester.tap(mildAscitesText);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('child_pugh_result_badge')), findsOneWidget);
        expect(find.textContaining('Score 9/15'), findsOneWidget);

        final applyBtn = find.byKey(const Key('child_pugh_apply_button'));
        await tester.ensureVisible(applyBtn);
        await tester.tap(applyBtn);
        await tester.pumpAndSettle();

        // Tap Calculate Dose
        await tester.tap(find.byKey(const Key('calculator_calculate_button')));
        await tester.pumpAndSettle();

        expect(find.text('CRITICAL SAFETY ALERT'), findsOneWidget);
        expect(find.textContaining('Child-Pugh B'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Direct Child-Pugh selector on Apixaban allows Class B with caution and blocks Class C',
      (tester) async {
        final apixaban = findDrug('apixaban');
        await tester.pumpWidget(
          MaterialApp(
            home: CalculatorScreen(
              drug: apixaban,
              isThai: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Select Class B directly
        final classBBtn = find.text('Class B');
        await tester.ensureVisible(classBBtn);
        await tester.tap(classBBtn);
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('calculator_calculate_button')));
        await tester.pumpAndSettle();

        expect(find.text('Calculated with Warnings'), findsOneWidget);

        // Select Class C directly -> hard contraindication
        final classCBtn = find.text('Class C');
        await tester.ensureVisible(classCBtn);
        await tester.tap(classCBtn);
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('calculator_calculate_button')));
        await tester.pumpAndSettle();

        expect(find.text('CRITICAL SAFETY ALERT'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('Phase 3 UI — IV Diluent Compatibility Card & Interactive Precipitation Banner', () {
    testWidgets(
      'CalculatorScreen displays IV diluent compatibility card on Phenytoin IV with 0 overflow on 320x480, and hides it on PO regimen',
      (tester) async {
        tester.view.physicalSize = const Size(320, 480);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final phenytoin = findDrug('phenytoin');
        await tester.pumpWidget(
          MaterialApp(
            home: CalculatorScreen(
              drug: phenytoin,
              isThai: true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('calculator_iv_diluent_card')),
          findsOneWidget,
        );
        expect(find.textContaining('ห้ามผสม D5W'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Switch regimen dropdown from IV to PO -> card must hide
        final dropdown = find.byType(DropdownButton<DosingRegimen>);
        await tester.ensureVisible(dropdown);
        await tester.tap(dropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('(PO)').last);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('calculator_iv_diluent_card')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'IVTitrationScreen renders red incompatibility banner immediately when LRS is selected on Nicardipine while keeping pump rates visible',
      (tester) async {
        final nicardipine = findDrug('nicardipine');
        await tester.pumpWidget(
          MaterialApp(
            home: IVTitrationScreen(
              drug: nicardipine,
              regimen: nicardipine.regimens.first,
              isThai: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Initially defaults to preferred NSS -> no red warning banner
        expect(
          find.byKey(const Key('iv_titration_incompatibility_banner')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('iv_titration_compatible_badge')),
          findsOneWidget,
        );
        expect(find.text('150.0'), findsOneWidget);

        // Tap incompatible LRS chip -> instant Red Incompatibility Banner + pump rates remain visible
        await tester.tap(find.byKey(const Key('iv_titration_diluent_lrs')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('iv_titration_incompatibility_banner')),
          findsOneWidget,
        );
        expect(find.textContaining('INCOMPATIBLE DILUENT (LRS)'), findsOneWidget);
        expect(find.text('150.0'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'IVTitrationScreen warns on Norepinephrine + NSS oxidation and Phenytoin + D5W precipitation on narrow 320x480 viewport',
      (tester) async {
        tester.view.physicalSize = const Size(320, 480);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final norepi = findDrug('norepinephrine');
        await tester.pumpWidget(
          MaterialApp(
            home: IVTitrationScreen(
              drug: norepi,
              regimen: norepi.regimens.first,
              isThai: true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('iv_titration_incompatibility_banner')),
          findsNothing,
        );

        await tester.tap(find.byKey(const Key('iv_titration_diluent_nss')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('iv_titration_incompatibility_banner')),
          findsOneWidget,
        );
        expect(find.textContaining('ห้ามผสมใน NSS'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Also verify non-titrated IV drug (Phenytoin) on 320x480
        final phenytoin = findDrug('phenytoin');
        await tester.pumpWidget(
          MaterialApp(
            home: IVTitrationScreen(
              drug: phenytoin,
              regimen: phenytoin.regimens.first,
              isThai: true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('iv_titration_diluent_d5w')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('iv_titration_incompatibility_banner')),
          findsOneWidget,
        );
        expect(find.textContaining('ห้ามผสมใน D5W'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
