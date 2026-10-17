import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/models/models.dart';
import 'package:drug_dosage_calculator/core/calculators/calculators.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:drug_dosage_calculator/data/patient_session.dart';
import 'package:drug_dosage_calculator/ui/iv_titration_screen.dart';
import 'package:flutter/material.dart';

void main() {
  group('Unit Conversion & IV Titration Safety Tests', () {
    const patient = Patient(
      id: 'p-titration',
      weightKg: 70.0,
      heightCm: 175.0,
      ageYears: 50,
      sex: Sex.male,
      isScrStable: true,
      serumCreatinineMgDl: 1.0,
    );

    setUp(() {
      PatientSession.instance.setPatient(patient);
    });

    test('1. RateUnit mcg/kg/min (Norepinephrine): correctly computes amount per hr and pump mL/hr', () {
      final norepi = DrugDatabase.findById('norepinephrine')!;
      final regimen = norepi.regimens.first; // 0.05 - 1.0 mcg/kg/min, 0.016 mg/mL (4mg in 250mL)

      // 0.1 mcg/kg/min * 70 kg * 60 min / 1000 = 0.42 mg/hr
      // 0.42 mg/hr / 0.016 mg/mL = 26.25 mL/hr
      const rateUnit = RateUnit.mcgKgMin;
      final amountPerHr = rateUnit.toAmountPerHour(0.1, patient.weightKg);
      expect(amountPerHr, closeTo(0.42, 0.001));

      final mlPerHr = amountPerHr! / regimen.standardDilutionMgPerMl!;
      expect(mlPerHr, closeTo(26.25, 0.01));
    });

    test('2. RateUnit mg/hr (Nicardipine): correctly computes pump rate without multiplying by body weight or 60 min', () {
      final nicardipine = DrugDatabase.findById('nicardipine')!;
      final regimen = nicardipine.regimens.first; // 5 - 15 mg/hr, 0.1 mg/mL

      // 5 mg/hr / 0.1 mg/mL = 50 mL/hr (NOT 210 mL/hr)
      final rateUnit = RateUnit.fromSymbol(regimen.continuousRateUnit!);
      expect(rateUnit, equals(RateUnit.mgHr));

      final amountPerHr = rateUnit.toAmountPerHour(5.0, patient.weightKg);
      expect(amountPerHr, equals(5.0));

      final mlPerHr = amountPerHr! / regimen.standardDilutionMgPerMl!;
      expect(mlPerHr, equals(50.0));

      // Max rate: 15 mg/hr / 0.1 mg/mL = 150 mL/hr
      final maxAmountPerHr = rateUnit.toAmountPerHour(15.0, patient.weightKg);
      final maxMlPerHr = maxAmountPerHr! / regimen.standardDilutionMgPerMl!;
      expect(maxMlPerHr, equals(150.0));
    });

    test('3. RateUnit g/hr (Magnesium Sulfate): converts grams to milligrams before dividing by mg/mL dilution', () {
      final mgso4 = DrugDatabase.findById('magnesium_sulfate')!;
      final regimen = mgso4.regimens.firstWhere((r) => r.continuousRateUnit == 'g/hr');

      // 1.0 g/hr = 1000 mg/hr. Dilution = 40 mg/mL -> 1000 / 40 = 25 mL/hr
      // 2.0 g/hr = 2000 mg/hr. Dilution = 40 mg/mL -> 2000 / 40 = 50 mL/hr
      final rateUnit = RateUnit.fromSymbol(regimen.continuousRateUnit!);
      expect(rateUnit, equals(RateUnit.gHr));

      final amountPerHr1 = rateUnit.toAmountPerHour(1.0, patient.weightKg);
      expect(amountPerHr1, equals(1000.0));
      final mlPerHr1 = amountPerHr1! / regimen.standardDilutionMgPerMl!;
      expect(mlPerHr1, equals(25.0));

      final amountPerHr2 = rateUnit.toAmountPerHour(2.0, patient.weightKg);
      expect(amountPerHr2, equals(2000.0));
      final mlPerHr2 = amountPerHr2! / regimen.standardDilutionMgPerMl!;
      expect(mlPerHr2, equals(50.0));
    });

    test('4. RateUnit units/kg/hr (Heparin): scales with body weight and divides by units/mL concentration', () {
      final heparin = DrugDatabase.findById('heparin')!;
      final regimen = heparin.regimens.first; // 18 units/kg/hr, 100 units/mL

      // 18 units/kg/hr * 70 kg = 1260 units/hr
      // 1260 units/hr / 100 units/mL = 12.6 mL/hr
      final rateUnit = RateUnit.fromSymbol(regimen.continuousRateUnit!);
      expect(rateUnit, equals(RateUnit.uKgHr));

      final amountPerHr = rateUnit.toAmountPerHour(18.0, patient.weightKg);
      expect(amountPerHr, equals(1260.0));

      final mlPerHr = amountPerHr! / regimen.standardDilutionMgPerMl!;
      expect(mlPerHr, closeTo(12.6, 0.01));
    });

    testWidgets('5. IVTitrationScreen widget renders correct rate column and pump rate for Nicardipine (mg/hr)', (tester) async {
      final nicardipine = DrugDatabase.findById('nicardipine')!;
      final regimen = nicardipine.regimens.first;

      await tester.pumpWidget(
        MaterialApp(
          home: IVTitrationScreen(
            drug: nicardipine,
            regimen: regimen,
            isThai: false,
          ),
        ),
      );

      // Verify the column header shows (mg/hr), NOT (mcg/kg/min)
      expect(find.text('Dose\n(mg/hr)'), findsOneWidget);
      expect(find.text('Pump Rate\n(mL/hr)'), findsOneWidget);

      // Verify patient weight and concentration display
      expect(find.text('Patient Weight: 70.0 kg'), findsOneWidget);
      expect(find.text('Concentration: 0.1 mg/mL'), findsOneWidget);

      // For 5.0 mg/hr, the pump rate should be 50.0 mL/hr
      expect(find.text('5'), findsOneWidget);
      expect(find.text('50.0'), findsOneWidget);

      // For 15.0 mg/hr (max rate), the pump rate should be 150.0 mL/hr
      expect(find.text('15'), findsOneWidget);
      expect(find.text('150.0'), findsOneWidget);
    });

    testWidgets('6. IVTitrationScreen widget renders correct column and pump rate for Heparin (units/kg/hr)', (tester) async {
      final heparin = DrugDatabase.findById('heparin')!;
      final regimen = heparin.regimens.first;

      await tester.pumpWidget(
        MaterialApp(
          home: IVTitrationScreen(
            drug: heparin,
            regimen: regimen,
            isThai: false,
          ),
        ),
      );

      // Column header should show (units/kg/hr)
      expect(find.text('Dose\n(units/kg/hr)'), findsOneWidget);
      expect(find.text('Pump Rate\n(mL/hr)'), findsOneWidget);

      // Concentration should display Units/mL
      expect(find.text('Concentration: 100.0 Units/mL'), findsOneWidget);

      // At 18 units/kg/hr, pump rate is 12.6 mL/hr
      expect(find.text('18'), findsWidgets);
      expect(find.text('12.6'), findsWidgets);
    });

    test('7. Clinical UnitConverter laboratory conversions: SCr umol/L <-> mg/dL strictly accurate', () {
      // 88.4 umol/L = 1.0 mg/dL
      expect(UnitConverter.scrUmolPerLToMgPerDl(88.4), closeTo(1.0, 0.0001));
      expect(UnitConverter.scrMgPerDlToUmolPerL(1.0), closeTo(88.4, 0.0001));

      // 176.8 umol/L = 2.0 mg/dL
      expect(UnitConverter.scrUmolPerLToMgPerDl(176.8), closeTo(2.0, 0.0001));
      expect(UnitConverter.scrMgPerDlToUmolPerL(2.0), closeTo(176.8, 0.0001));
    });

    test('8. Clinical UnitConverter mass conversions: mcg <-> mg <-> g strictly accurate', () {
      expect(UnitConverter.convertDoseUnit(1000.0, DoseUnit.mcg, DoseUnit.mg), equals(1.0));
      expect(UnitConverter.convertDoseUnit(1.0, DoseUnit.g, DoseUnit.mg), equals(1000.0));
      expect(UnitConverter.convertDoseUnit(500.0, DoseUnit.mg, DoseUnit.g), equals(0.5));
      expect(UnitConverter.convertDoseUnit(0.25, DoseUnit.mg, DoseUnit.mcg), equals(250.0));
    });
  });
}
