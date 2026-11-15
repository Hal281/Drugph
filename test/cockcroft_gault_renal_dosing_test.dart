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

  group('Item 4 — Cockcroft-Gault Weight Selection (Winter 2012: TBW / IBW / AdjBW)', () {
    test('Underweight adult (TBW < IBW) selects TBW and catches renal impairment that IBW would miss', () {
      // Female 75y, 42.0 kg, 165.0 cm -> IBW = 56.91 kg; TBW < IBW -> uses TBW (42.0 kg)
      final selection = RenalCalculator.selectCockcroftGaultWeight(
        weightKg: 42.0,
        heightCm: 165.0,
        sex: Sex.female,
      );

      expect(selection.strategy, equals('TBW'));
      expect(selection.selectedWeightKg, closeTo(42.0, 0.01));
      expect(selection.ibwKg, closeTo(56.91, 0.05));
      expect(selection.reasonEn, contains('Actual Body Weight'));

      // CrCl = ((140 - 75) * 42) / (72 * 1.3) * 0.85 = 24.79 mL/min (< 30 threshold)
      final crcl = RenalCalculator.cockcroftGaultAutoWeight(
        ageYears: 75,
        weightKg: 42.0,
        heightCm: 165.0,
        sex: Sex.female,
        serumCreatinineMgDl: 1.3,
      );
      expect(crcl, closeTo(24.79, 0.05));

      final cipro = DrugDatabase.findById('ciprofloxacin')!;
      const patient = Patient(
        id: 'p-underweight-renal',
        weightKg: 42.0,
        heightCm: 165.0,
        ageYears: 75,
        sex: Sex.female,
        serumCreatinineMgDl: 1.3,
        isScrStable: true,
      );

      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: cipro,
        regimen: cipro.regimens.first, // 500 mg PO q12h -> halves if CrCl < 30
      );

      expect(result.success, isTrue);
      expect(result.crclMlMin, closeTo(24.79, 0.05));
      expect(result.isRenallyAdjusted, isTrue);
      expect(result.calculatedDose, closeTo(250.0, 0.01));
      expect(result.calculationInputs['crclWeightStrategy'], equals('TBW'));
      expect(result.calculationInputs['crclWeightUsedKg'], closeTo(42.0, 0.01));
      expect(result.calculationInputs['renalEquationUsed'], equals('Cockcroft-Gault'));
    });

    test('Normal-weight adult (IBW <= TBW < 120% IBW) selects IBW', () {
      // Male 35y, 70.0 kg, 170.0 cm -> IBW = 65.94 kg, 120% IBW = 79.12 kg -> uses IBW
      final selection = RenalCalculator.selectCockcroftGaultWeight(
        weightKg: 70.0,
        heightCm: 170.0,
        sex: Sex.male,
      );

      expect(selection.strategy, equals('IBW'));
      expect(selection.ibwKg, closeTo(65.94, 0.05));
      expect(selection.selectedWeightKg, closeTo(65.94, 0.05));

      // CrCl = ((140 - 35) * 65.937) / (72 * 0.9) = 106.84 mL/min
      final crcl = RenalCalculator.cockcroftGaultAutoWeight(
        ageYears: 35,
        weightKg: 70.0,
        heightCm: 170.0,
        sex: Sex.male,
        serumCreatinineMgDl: 0.9,
      );
      expect(crcl, closeTo(106.84, 0.05));

      final cephalexin = DrugDatabase.findById('cephalexin')!;
      final controller = CalculatorController(drug: cephalexin);
      addTearDown(controller.dispose);

      controller.weightCtrl.text = '70';
      controller.heightCtrl.text = '170';
      controller.ageCtrl.text = '35';
      controller.scrCtrl.text = '0.9';
      controller.setSex(Sex.male);

      final val = controller.calculate(isThai: false);
      expect(val.isValid, isTrue);
      expect(controller.state.result?.crclMlMin, closeTo(106.84, 0.05));
      expect(controller.state.dosingWeightLabel, equals('IBW'));
      expect(controller.state.dosingWeightValue, closeTo(65.94, 0.05));
      expect(controller.state.dosingWeightReason, contains('Ideal Body Weight'));
    });

    test('Obese adult (TBW >= 120% IBW) selects AdjBW 0.4 and prevents overestimation of renal clearance', () {
      // Male 68y, 120.0 kg, 170.0 cm -> IBW = 65.94 kg, AdjBW = 87.56 kg, SCr = 2.0
      final selection = RenalCalculator.selectCockcroftGaultWeight(
        weightKg: 120.0,
        heightCm: 170.0,
        sex: Sex.male,
      );

      expect(selection.strategy, equals('AdjBW'));
      expect(selection.ibwKg, closeTo(65.94, 0.05));
      expect(selection.adjBwKg, closeTo(87.56, 0.05));
      expect(selection.selectedWeightKg, closeTo(87.56, 0.05));

      // AdjBW CrCl = ((140 - 68) * 87.562) / (72 * 2.0) = 43.78 mL/min (< 50 Meropenem tier)
      // (Raw TBW would have yielded 60.0 mL/min and missed Meropenem renal adjustment)
      final crcl = RenalCalculator.cockcroftGaultAutoWeight(
        ageYears: 68,
        weightKg: 120.0,
        heightCm: 170.0,
        sex: Sex.male,
        serumCreatinineMgDl: 2.0,
      );
      expect(crcl, closeTo(43.78, 0.05));

      final meropenem = DrugDatabase.findById('meropenem')!;
      final controller = CalculatorController(drug: meropenem);
      addTearDown(controller.dispose);

      controller.weightCtrl.text = '120';
      controller.heightCtrl.text = '170';
      controller.ageCtrl.text = '68';
      controller.scrCtrl.text = '2.0';
      controller.setSex(Sex.male);

      final val = controller.calculate(isThai: true);
      expect(val.isValid, isTrue);
      expect(controller.state.result?.crclMlMin, closeTo(43.78, 0.05));
      expect(controller.state.result?.isRenallyAdjusted, isTrue);
      expect(controller.state.dosingWeightLabel, equals('AdjBW'));
      expect(controller.state.dosingWeightValue, closeTo(87.56, 0.05));
      expect(controller.state.dosingWeightReason, contains('AdjBW'));
    });
  });

  group('Item 4 — Cockcroft-Gault & Schwartz UI Transparency on CalculatorScreen', () {
    testWidgets('Displays AdjBW CrCl badge, DosingWeightLogicCard, and substituted Cockcroft-Gault formula in breakdown', (tester) async {
      tester.view.physicalSize = const Size(1024, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final cephalexin = DrugDatabase.findById('cephalexin')!;
      await tester.pumpWidget(
        MaterialApp(
          home: CalculatorScreen(drug: cephalexin, isThai: false),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('calculator_weight_field')),
        '110',
      );
      await tester.enterText(
        find.byKey(const Key('calculator_height_field')),
        '170',
      );
      await tester.enterText(
        find.byKey(const Key('calculator_age_field')),
        '50',
      );
      await tester.enterText(
        find.byKey(const Key('calculator_scr_field')),
        '1.2',
      );

      await tester.tap(find.byKey(const Key('calculator_calculate_button')));
      await tester.pumpAndSettle();

      // CrCl badge displays CG equation and AdjBW weight used
      expect(
        find.descendant(
          of: find.byKey(const Key('dosage_result_crcl_badge')),
          matching: find.text('CrCl: 87.0 mL/min (CG • AdjBW 83.6 kg)'),
        ),
        findsOneWidget,
      );

      // DosingWeightLogicCard displays AdjBW (not TBW)
      expect(
        find.descendant(
          of: find.byType(DosingWeightLogicCard),
          matching: find.textContaining('AdjBW'),
        ),
        findsWidgets,
      );
      expect(
        find.descendant(
          of: find.byType(DosingWeightLogicCard),
          matching: find.textContaining('83.6 kg'),
        ),
        findsOneWidget,
      );

      // Step-by-step math breakdown displays substituted formula values and weight table
      expect(
        find.textContaining('CrCl = [(140 - 50) × 83.6 kg (AdjBW)] / (72 × 1.2) = 87.0 mL/min'),
        findsOneWidget,
      );
      expect(
        find.textContaining('TBW: 110.0 kg • IBW: 65.9 kg • AdjBW: 83.6 kg'),
        findsOneWidget,
      );
    });

    testWidgets('Displays Bedside Schwartz equation for pediatric patients and has zero overflow on 320x480 viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final cephalexin = DrugDatabase.findById('cephalexin')!;
      await tester.pumpWidget(
        MaterialApp(
          home: CalculatorScreen(drug: cephalexin, isThai: false),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('calculator_weight_field')),
        '15',
      );
      await tester.enterText(
        find.byKey(const Key('calculator_height_field')),
        '100',
      );
      await tester.enterText(
        find.byKey(const Key('calculator_age_field')),
        '4',
      );
      await tester.enterText(
        find.byKey(const Key('calculator_scr_field')),
        '0.5',
      );

      final calcBtn = find.byKey(const Key('calculator_calculate_button'));
      await tester.ensureVisible(calcBtn);
      await tester.tap(calcBtn);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.descendant(
          of: find.byKey(const Key('dosage_result_crcl_badge')),
          matching: find.text('CrCl: 82.6 mL/min/1.73m² (Schwartz)'),
        ),
        findsOneWidget,
      );

      final accordion = find.byKey(const Key('clinical_breakdown_accordion'));
      await tester.ensureVisible(accordion);
      await tester.tap(accordion);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.textContaining('eGFR = (0.413 × 100.0 cm) / 0.5 = 82.6 mL/min/1.73m²'),
        findsOneWidget,
      );
    });
  });
}
