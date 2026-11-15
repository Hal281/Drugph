import 'package:flutter_test/flutter_test.dart';

import 'package:drug_dosage_calculator/main.dart';
import 'package:drug_dosage_calculator/ui/home_screen.dart';

void main() {
  testWidgets('opens the home screen without a login page', (tester) async {
    await tester.pumpWidget(const DrugDosageApp());

    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
