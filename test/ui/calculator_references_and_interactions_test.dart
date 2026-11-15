import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:drug_dosage_calculator/ui/calculator/calculator_screen.dart';
import 'package:drug_dosage_calculator/ui/calculator/widgets/clinical_header_alerts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(DrugDatabase.warmUp);

  testWidgets('single-drug header omits interaction and reference cards', (
    tester,
  ) async {
    final drug = DrugDatabase.allDrugs.firstWhere(
      (candidate) => candidate.id == 'amlodipine',
    );

    expect(drug.severeInteractions, isNotEmpty);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClinicalHeaderAlerts(
            drug: drug,
            isThai: false,
          ),
        ),
      ),
    );

    expect(find.text('Severe Interactions'), findsNothing);
    expect(find.text('Clinical Evidence Reference'), findsNothing);
    expect(find.text('Tap to view ↗'), findsNothing);
  });

  testWidgets('textbook reference opens from the calculator app bar', (
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

    final referenceButton = find.byTooltip('View Textbook Monograph');
    expect(referenceButton, findsOneWidget);
    await tester.tap(referenceButton);
    await tester.pumpAndSettle();

    expect(find.text('Textbook Monograph & Evidence'), findsOneWidget);
  });
}
