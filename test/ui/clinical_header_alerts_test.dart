import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:drug_dosage_calculator/ui/calculator/calculator_screen.dart';
import 'package:drug_dosage_calculator/ui/calculator/widgets/clinical_header_alerts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(DrugDatabase.warmUp);

  testWidgets('clinical header shows indications and documented side effects', (
    tester,
  ) async {
    final drug = DrugDatabase.allDrugs.firstWhere(
      (candidate) => candidate.id == 'amlodipine',
    );

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

    expect(find.text('Indications'), findsOneWidget);
    final indicationFinder = find.textContaining(
      drug.availableIndications.first,
    );
    expect(indicationFinder, findsOneWidget);
    expect(find.text('Important Side Effects'), findsOneWidget);
    expect(find.textContaining('Peripheral edema'), findsOneWidget);
    expect(find.textContaining('แพ้ยา'), findsNothing);
    expect(
      tester.getTopLeft(indicationFinder).dy,
      lessThan(tester.getTopLeft(find.text('Important Side Effects')).dy),
    );
  });

  testWidgets('calculator title includes the drug class', (tester) async {
    final drug = DrugDatabase.allDrugs.firstWhere(
      (candidate) => candidate.id == 'ibuprofen',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CalculatorScreen(
          drug: drug,
          isThai: false,
        ),
      ),
    );

    expect(find.text('Ibuprofen (NSAID)'), findsOneWidget);
  });
}
