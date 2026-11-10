import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:drug_dosage_calculator/ui/calculator/models/calculator_ui_state.dart';
import 'package:drug_dosage_calculator/ui/calculator/widgets/dosage_result_card.dart';

void main() {
  late Drug nac;
  late DosingRegimen antidoteRegimen;

  setUpAll(() {
    nac = DrugDatabase.findById('n_acetylcysteine')!;
    antidoteRegimen = nac.regimens.firstWhere(
      (r) => (r.indication ?? '').contains('Paracetamol Overdose Antidote'),
    );
  });

  group('DosageResultCard Multi-Phase Antidote UI Tests', () {
    testWidgets('renders all 3 bags with correct dose, diluent, duration, and pump rate for 70 kg patient',
        (tester) async {
      const pt70 = Patient(
        id: 'pt-70',
        weightKg: 70.0,
        heightCm: 170.0,
        ageYears: 35,
        sex: Sex.male,
        serumCreatinineMgDl: 0.9,
        isScrStable: true,
      );

      final res = PharmacistCalculator.calculateDose(
        patient: pt70,
        drug: nac,
        regimen: antidoteRegimen,
      );

      final state = CalculatorUiState.initial(nac).copyWith(
        selectedRegimen: antidoteRegimen,
        result: res,
        warnings: res.warnings,
        status: CalculatorUiStatus.active,
        lastEvaluatedPatient: pt70,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DosageResultCard(
                state: state,
                isThai: false,
                onBuildPatient: () => pt70,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify multi-phase container card
      expect(find.byKey(const Key('dosage_result_multiphase_card')), findsOneWidget);
      expect(find.text('Multi-Phase Sequential Protocol'), findsOneWidget);

      // 2. Verify all 3 phase cards exist
      expect(find.byKey(const Key('dosage_result_phase_0')), findsOneWidget);
      expect(find.byKey(const Key('dosage_result_phase_1')), findsOneWidget);
      expect(find.byKey(const Key('dosage_result_phase_2')), findsOneWidget);

      // 3. Verify Bag 1: 150 mg/kg * 70 kg = 10,500 mg, 200 mL, 1 hr -> 200 mL/hr
      expect(find.text('Bag 1 (Loading)'), findsOneWidget);
      expect(find.text('10,500 mg'), findsOneWidget);
      expect(find.text('200 mL'), findsOneWidget);
      expect(find.text('1 hr'), findsOneWidget);
      expect(find.text('200 mL/hr'), findsOneWidget);

      // 4. Verify Bag 2: 50 mg/kg * 70 kg = 3,500 mg, 500 mL, 4 hr -> 125 mL/hr
      expect(find.text('Bag 2 (Second dose)'), findsOneWidget);
      expect(find.text('3,500 mg'), findsOneWidget);
      expect(find.text('500 mL'), findsOneWidget);
      expect(find.text('4 hr'), findsOneWidget);
      expect(find.text('125 mL/hr'), findsOneWidget);

      // 5. Verify Bag 3: 100 mg/kg * 70 kg = 7,000 mg, 1000 mL, 16 hr -> 62.5 mL/hr
      expect(find.text('Bag 3 (Third dose)'), findsOneWidget);
      expect(find.text('7,000 mg'), findsOneWidget);
      expect(find.text('1000 mL'), findsOneWidget);
      expect(find.text('16 hr'), findsOneWidget);
      expect(find.text('62.5 mL/hr'), findsOneWidget);
    });

    testWidgets('enforces max dosing weight cap of 100 kg for 120 kg patient',
        (tester) async {
      const pt120 = Patient(
        id: 'pt-120',
        weightKg: 120.0,
        heightCm: 180.0,
        ageYears: 42,
        sex: Sex.male,
        serumCreatinineMgDl: 1.0,
        isScrStable: true,
      );

      final res = PharmacistCalculator.calculateDose(
        patient: pt120,
        drug: nac,
        regimen: antidoteRegimen,
      );

      final state = CalculatorUiState.initial(nac).copyWith(
        selectedRegimen: antidoteRegimen,
        result: res,
        warnings: res.warnings,
        status: CalculatorUiStatus.active,
        lastEvaluatedPatient: pt120,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DosageResultCard(
                state: state,
                isThai: false,
                onBuildPatient: () => pt120,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Capped weight notice displayed
      expect(
        find.textContaining('Patient weight 120.0 kg capped at 100 kg'),
        findsOneWidget,
      );

      // Bag 1: 150 mg/kg * 100 kg (capped) = 15,000 mg
      expect(find.text('15,000 mg'), findsOneWidget);
      expect(find.text('200 mL/hr'), findsOneWidget);

      // Bag 2: 50 mg/kg * 100 kg (capped) = 5,000 mg
      expect(find.text('5,000 mg'), findsOneWidget);
      expect(find.text('125 mL/hr'), findsOneWidget);

      // Bag 3: 100 mg/kg * 100 kg (capped) = 10,000 mg
      expect(find.text('10,000 mg'), findsOneWidget);
      expect(find.text('62.5 mL/hr'), findsOneWidget);
    });

    testWidgets('renders Thai labels correctly when isThai is true',
        (tester) async {
      const pt70 = Patient(
        id: 'pt-70',
        weightKg: 70.0,
        heightCm: 170.0,
        ageYears: 35,
        sex: Sex.male,
        serumCreatinineMgDl: 0.9,
        isScrStable: true,
      );

      final res = PharmacistCalculator.calculateDose(
        patient: pt70,
        drug: nac,
        regimen: antidoteRegimen,
      );

      final state = CalculatorUiState.initial(nac).copyWith(
        selectedRegimen: antidoteRegimen,
        result: res,
        warnings: res.warnings,
        status: CalculatorUiStatus.active,
        lastEvaluatedPatient: pt70,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DosageResultCard(
                state: state,
                isThai: true,
                onBuildPatient: () => pt70,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dosage_result_multiphase_card')), findsOneWidget);
      expect(find.text('โปรโตคอลการบริหารยาแบบหลายขั้นตอน (Sequential Protocol)'), findsOneWidget);
      expect(find.text('ถุงที่ 1 (Loading)'), findsOneWidget);
      expect(find.text('ถุงที่ 2'), findsOneWidget);
      expect(find.text('ถุงที่ 3'), findsOneWidget);
      expect(find.text('10,500 mg'), findsOneWidget);
      expect(find.text('3,500 mg'), findsOneWidget);
      expect(find.text('7,000 mg'), findsOneWidget);
    });
  });
}
