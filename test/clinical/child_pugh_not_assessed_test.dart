import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:drug_dosage_calculator/data/patient_session.dart';
import 'package:drug_dosage_calculator/ui/calculator/calculator_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(DrugDatabase.warmUp);

  setUp(() {
    PatientSession.instance.clearPatient();
  });

  tearDown(() {
    PatientSession.instance.clearPatient();
  });

  group('FB-12 (WP-02): Child-Pugh Not Assessed vs Normal Separation', () {
    test(
      'Patient defaults to ChildPughClass.notAssessed and emits non-blocking amber hepatic guidance on hepatic-caution drugs without auto-reduction',
      () {
        const unassessedPatient = Patient(
          id: 'wp02-unassessed',
          weightKg: 70.0,
          heightCm: 170.0,
          ageYears: 55,
          sex: Sex.male,
          serumCreatinineMgDl: 0.9,
          isScrStable: true,
        );
        expect(unassessedPatient.hepaticClass, equals(ChildPughClass.notAssessed));
        expect(unassessedPatient.isHepaticAssessed, isFalse);

        final atorvastatin = DrugDatabase.findById('atorvastatin')!;
        expect(atorvastatin.requiresHepaticCaution, isTrue);

        final unassessedRes = PharmacistCalculator.calculateDose(
          patient: unassessedPatient,
          drug: atorvastatin,
          regimen: atorvastatin.regimens.first,
        );

        expect(unassessedRes.success, isTrue);
        expect(unassessedRes.calculatedDose, equals(40.0)); // No auto-reduction
        expect(
          unassessedRes.warnings.any(
            (w) =>
                w.severity == LimitSeverity.soft &&
                w.code == DoseWarningCode.hepaticNotAssessed,
          ),
          isTrue,
        );

        // Explicitly assessed Normal clears the unassessed warning
        final assessedNormalPatient = unassessedPatient.copyWith(
          hepaticImpairment: ChildPughClass.none,
        );
        expect(assessedNormalPatient.hepaticClass, equals(ChildPughClass.none));
        expect(assessedNormalPatient.isHepaticAssessed, isTrue);

        final normalRes = PharmacistCalculator.calculateDose(
          patient: assessedNormalPatient,
          drug: atorvastatin,
          regimen: atorvastatin.regimens.first,
        );
        expect(
          normalRes.warnings.any(
            (w) => w.code == DoseWarningCode.hepaticNotAssessed,
          ),
          isFalse,
        );
      },
    );

    test(
      'Unassessed patient does NOT trigger false hepatic hard block on PopulationCriteria (e.g. Rivaroxaban)',
      () {
        final rivaroxaban = DrugDatabase.findById('rivaroxaban')!;
        const unassessedPatient = Patient(
          id: 'wp02-riva-unassessed',
          weightKg: 70.0,
          heightCm: 170.0,
          ageYears: 60,
          sex: Sex.male,
          serumCreatinineMgDl: 0.9,
          isScrStable: true,
        );

        final res = PharmacistCalculator.calculateDose(
          patient: unassessedPatient,
          drug: rivaroxaban,
          regimen: rivaroxaban.regimens.first,
        );
        expect(res.success, isTrue);
        expect(res.calculatedDose, equals(20.0));
        expect(
          res.warnings.any((w) => w.severity == LimitSeverity.hard),
          isFalse,
        );
        expect(
          res.warnings.any((w) => w.code == DoseWarningCode.hepaticNotAssessed),
          isTrue,
        );

        final noteUnassessed = ClinicalOrderFormatter.formatPharmacistNote(
          patient: unassessedPatient,
          drug: rivaroxaban,
          regimen: rivaroxaban.regimens.first,
          result: res,
        );
        expect(noteUnassessed, contains('Hepatic: Not assessed'));

        final normalPatient = unassessedPatient.copyWith(
          hepaticImpairment: ChildPughClass.none,
        );
        final resNormal = PharmacistCalculator.calculateDose(
          patient: normalPatient,
          drug: rivaroxaban,
          regimen: rivaroxaban.regimens.first,
        );
        final noteNormal = ClinicalOrderFormatter.formatPharmacistNote(
          patient: normalPatient,
          drug: rivaroxaban,
          regimen: rivaroxaban.regimens.first,
          result: resNormal,
        );
        expect(noteNormal, contains('Hepatic: Normal (Assessed)'));
      },
    );

    testWidgets(
      'DosingParametersForm defaults to Not assessed, renders all 5 options cleanly at 320x480 with zero overflow, and toggles to Normal/Class B',
      (tester) async {
        tester.view.physicalSize = const Size(320, 480);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final rivaroxaban = DrugDatabase.findById('rivaroxaban')!;
        await tester.pumpWidget(
          MaterialApp(
            home: CalculatorScreen(drug: rivaroxaban, isThai: false),
          ),
        );
        await tester.pumpAndSettle();

        // Collapsed initially even though state defaults to notAssessed
        expect(
          find.byKey(const Key('calculator_child_pugh_selector')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('patient_header_hepatic_not_assessed')),
          findsOneWidget,
        );

        final hepaticOptions = find.byKey(const Key('calculator_hepatic_options'));
        await tester.ensureVisible(hepaticOptions);
        await tester.tap(hepaticOptions);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('calculator_child_pugh_selector')),
          findsOneWidget,
        );
        expect(find.text('Not assessed'), findsOneWidget);
        expect(find.text('Normal'), findsOneWidget);
        expect(find.text('Class A'), findsOneWidget);
        expect(find.text('Class B'), findsOneWidget);
        expect(find.text('Class C'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Select Normal -> clears Not assessed header chip
        final normalChip = find.text('Normal');
        await tester.ensureVisible(normalChip);
        await tester.tap(normalChip);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('patient_header_hepatic_not_assessed')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );
  });
}
