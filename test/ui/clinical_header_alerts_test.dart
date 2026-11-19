import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:drug_dosage_calculator/ui/calculator/calculator_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(DrugDatabase.warmUp);

  testWidgets('calculator shows indications before side effects', (
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
    await tester.pumpAndSettle();

    expect(find.text('Indications'), findsOneWidget);
    final indicationFinder = find.text('• ${drug.availableIndications.first}');
    expect(indicationFinder, findsOneWidget);
    expect(find.text('Side Effects & Safety Monitoring'), findsOneWidget);
    expect(find.textContaining('Peripheral edema'), findsOneWidget);
    expect(find.textContaining('แพ้ยา'), findsNothing);
    expect(
      tester.getTopLeft(indicationFinder).dy,
      lessThan(tester.getTopLeft(find.text('Side Effects & Safety Monitoring')).dy),
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
