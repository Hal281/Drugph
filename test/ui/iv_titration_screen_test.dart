// ============================================================
// IV Titration Screen Multi-Strength & Reverse Titration Tests
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/models/models.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:drug_dosage_calculator/data/patient_session.dart';
import 'package:drug_dosage_calculator/ui/iv_titration_screen.dart';

void main() {
  group('IVTitrationScreen Multi-Strength Presets & Reverse Titration', () {
    const testPatient = Patient(
      id: 'pt-titration-test',
      weightKg: 80.0,
      heightCm: 175.0,
      ageYears: 55,
      sex: Sex.male,
      isScrStable: true,
      serumCreatinineMgDl: 1.0,
    );

    setUp(() {
      PatientSession.instance.setPatient(testPatient);
    });

    testWidgets('1. Norepinephrine: Standard 1x concentration renders correct pump rates', (tester) async {
      final norepi = DrugDatabase.findById('norepinephrine')!;
      final regimen = norepi.regimens.first;

      await tester.pumpWidget(
        MaterialApp(
          home: IVTitrationScreen(
            drug: norepi,
            regimen: regimen,
            isThai: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // At 80 kg, single strength 16 mcg/mL (0.016 mg/mL):
      // Dose 0.05 mcg/kg/min: (0.05 * 80 * 60) / 16 = 15.0 mL/hr
      expect(find.text('0.05'), findsWidgets);
      expect(find.text('15.0'), findsWidgets);

      // Verify preset selector is present
      expect(find.byKey(const Key('iv_titration_preset_selector')), findsOneWidget);
      expect(find.byKey(const Key('iv_titration_preset_1x')), findsOneWidget);
      expect(find.byKey(const Key('iv_titration_preset_2x')), findsOneWidget);
      expect(find.byKey(const Key('iv_titration_preset_4x')), findsOneWidget);
      expect(find.byKey(const Key('iv_titration_preset_syringe')), findsOneWidget);
    });

    testWidgets('2. Norepinephrine: Selecting Double Strength (2x) dynamically halves volumetric pump rates', (tester) async {
      final norepi = DrugDatabase.findById('norepinephrine')!;
      final regimen = norepi.regimens.first;

      await tester.pumpWidget(
        MaterialApp(
          home: IVTitrationScreen(
            drug: norepi,
            regimen: regimen,
            isThai: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 2x preset (32 mcg/mL)
      await tester.tap(find.byKey(const Key('iv_titration_preset_2x')));
      await tester.pumpAndSettle();

      // At 80 kg, double strength 32 mcg/mL (0.032 mg/mL):
      // Dose 0.05 mcg/kg/min: (0.05 * 80 * 60) / 32 = 7.5 mL/hr
      expect(find.text('7.5'), findsWidgets);

      // Dose 0.10 mcg/kg/min: (0.10 * 80 * 60) / 32 = 15.0 mL/hr
      expect(find.text('0.10'), findsWidgets);
      expect(find.text('15.0'), findsWidgets);
    });

    testWidgets('3. Norepinephrine: Selecting Quad Strength (4x) dynamically quarters volumetric pump rates', (tester) async {
      final norepi = DrugDatabase.findById('norepinephrine')!;
      final regimen = norepi.regimens.first;

      await tester.pumpWidget(
        MaterialApp(
          home: IVTitrationScreen(
            drug: norepi,
            regimen: regimen,
            isThai: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 4x preset (64 mcg/mL)
      await tester.tap(find.byKey(const Key('iv_titration_preset_4x')));
      await tester.pumpAndSettle();

      // At 80 kg, quad strength 64 mcg/mL (0.064 mg/mL):
      // Dose 0.10 mcg/kg/min: (0.10 * 80 * 60) / 64 = 7.5 mL/hr
      expect(find.text('7.5'), findsWidgets);
    });

    testWidgets('4. Reverse Titration: Entering pump rate calculates exact delivered mcg/kg/min and mcg/min', (tester) async {
      final norepi = DrugDatabase.findById('norepinephrine')!;
      final regimen = norepi.regimens.first;

      await tester.pumpWidget(
        MaterialApp(
          home: IVTitrationScreen(
            drug: norepi,
            regimen: regimen,
            isThai: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Reverse titration card is displayed
      expect(find.byKey(const Key('iv_titration_reverse_result_card')), findsOneWidget);
      final rateInput = find.byKey(const Key('iv_titration_reverse_rate_input'));
      expect(rateInput, findsOneWidget);

      // Enter pump rate: 30.0 mL/hr at single strength (16 mcg/mL) for 80 kg patient:
      // Delivered mcg/min = (30 * 16) / 60 = 8.0 mcg/min
      // Delivered mcg/kg/min = 8.0 / 80 = 0.100 mcg/kg/min
      await tester.enterText(rateInput, '30.0');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('iv_titration_reverse_result_mcg_kg_min')), findsOneWidget);
      expect(find.text('0.100 mcg/kg/min'), findsOneWidget);
      expect(find.byKey(const Key('iv_titration_reverse_result_mcg_min')), findsOneWidget);
      expect(find.text('(8.00 mcg/min)'), findsOneWidget);
    });

    testWidgets('5. Reverse Titration: Overdose ceiling warning displayed when pump rate exceeds max rate', (tester) async {
      final norepi = DrugDatabase.findById('norepinephrine')!;
      final regimen = norepi.regimens.first; // max is 3.0 mcg/kg/min

      await tester.pumpWidget(
        MaterialApp(
          home: IVTitrationScreen(
            drug: norepi,
            regimen: regimen,
            isThai: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Single strength (16 mcg/mL), 80 kg. To exceed 3.0 mcg/kg/min:
      // Rate = (3.5 * 80 * 60) / 16 = 1050 mL/hr
      await tester.enterText(find.byKey(const Key('iv_titration_reverse_rate_input')), '1050');
      await tester.pumpAndSettle();

      // Rule 5: Non-blocking warning banner is shown, dose remains visible
      expect(find.textContaining('3.500 mcg/kg/min'), findsOneWidget);
      expect(find.textContaining('⚠️ คำเตือน: อัตรานี้เกินเกณฑ์สูงสุดที่แนะนำ'), findsOneWidget);
    });
  });
}
