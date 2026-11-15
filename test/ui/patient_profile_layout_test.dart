import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:drug_dosage_calculator/data/patient_session.dart';
import 'package:drug_dosage_calculator/ui/calculator/calculator_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(DrugDatabase.warmUp);

  setUp(() {
    PatientSession.instance.setPatient(
      const Patient(
        id: 'PATIENT-PROFILE-LAYOUT-TEST',
        weightKg: 70,
        heightCm: 170,
        ageYears: 55,
        sex: Sex.female,
        serumCreatinineMgDl: 0.9,
        creatinineClearanceMlMin: 78.4,
        isScrStable: true,
      ),
    );
  });

  tearDown(PatientSession.instance.clearPatient);

  testWidgets('active patient data is summarized once on the calculator', (
    tester,
  ) async {
    final drug = DrugDatabase.allDrugs.firstWhere(
      (candidate) => candidate.id == 'amlodipine',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CalculatorScreen(
          drug: drug,
          isThai: false,
        ),
      ),
    );

    expect(find.text('Weight: 70.0 kg'), findsOneWidget);
    expect(find.text('Height: 170.0 cm'), findsOneWidget);
    expect(find.text('Age: 55 years'), findsOneWidget);
    expect(
      find.text('CrCl calculated with Cockcroft-Gault equation'),
      findsOneWidget,
    );
    expect(find.text('78.4 mL/min'), findsOneWidget);
    expect(find.byKey(const Key('calculator_weight_field')), findsNothing);
    expect(find.byKey(const Key('calculator_height_field')), findsNothing);
    expect(find.byKey(const Key('calculator_age_field')), findsNothing);
    expect(find.byKey(const Key('calculator_scr_field')), findsNothing);

    await tester.tap(
      find.byKey(const Key('calculator_edit_patient_button')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Weight (kg) *'), findsOneWidget);
  });

  testWidgets('Child-Pugh controls are optional and collapsed initially', (
    tester,
  ) async {
    final drug = DrugDatabase.allDrugs.firstWhere(
      (candidate) => candidate.id == 'amlodipine',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CalculatorScreen(
          drug: drug,
          isThai: false,
        ),
      ),
    );

    expect(
        find.byKey(const Key('calculator_child_pugh_selector')), findsNothing);

    final optionalSection = find.byKey(
      const Key('calculator_hepatic_options'),
    );
    await tester.ensureVisible(optionalSection);
    await tester.tap(optionalSection);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('calculator_child_pugh_selector')),
        findsOneWidget);
  });
}
