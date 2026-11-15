import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/main.dart';
import 'package:drug_dosage_calculator/ui/home_screen.dart';
import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/data/drugs/analgesics.dart';
import 'package:drug_dosage_calculator/data/drugs/antibiotics.dart';

void main() {
  group('R1: Pediatric Oral Liquid & Teaspoon Unit Conversions', () {
    test('UnitConverter: 5 mL per household teaspoon exact conversion', () {
      expect(UnitConverter.mlPerTeaspoon, 5.0);
      expect(UnitConverter.mlToTeaspoons(5.0), 1.0);
      expect(UnitConverter.mlToTeaspoons(10.0), 2.0);
      expect(UnitConverter.mlToTeaspoons(2.5), 0.5);
      expect(UnitConverter.mlToTeaspoons(6.25), 1.25);
      expect(UnitConverter.mlToTeaspoons(0.0), 0.0);

      expect(UnitConverter.teaspoonsToMl(1.0), 5.0);
      expect(UnitConverter.teaspoonsToMl(2.0), 10.0);
      expect(UnitConverter.teaspoonsToMl(0.5), 2.5);

      expect(UnitConverter.formatTeaspoons(1.0, isThai: false), '1 tsp');
      expect(UnitConverter.formatTeaspoons(1.5, isThai: false), '1.5 tsp');
      expect(UnitConverter.formatTeaspoons(1.0, isThai: true), '1 ช้อนชา');
      expect(UnitConverter.formatTeaspoons(0.5, isThai: true), '0.5 ช้อนชา');
    });

    test('OralLiquidConcentration: doseToVolumeMl and doseToTeaspoons', () {
      const conc120 = OralLiquidConcentration(
        label: '120 mg / 5 mL (24 mg/mL)',
        amountMg: 120.0,
        perVolumeMl: 5.0,
        brandOrForm: 'Syrup',
        citation: 'Lexicomp 2024',
        isDefault: true,
      );

      expect(conc120.concentrationMgPerMl, 24.0);
      expect(conc120.doseToVolumeMl(120.0), 5.0);
      expect(conc120.doseToTeaspoons(120.0), 1.0);

      // 10 kg child at 15 mg/kg = 150 mg dose
      expect(conc120.doseToVolumeMl(150.0), 6.25);
      expect(conc120.doseToTeaspoons(150.0), 1.25);

      const conc250 = OralLiquidConcentration(
        label: '250 mg / 5 mL (50 mg/mL)',
        amountMg: 250.0,
        perVolumeMl: 5.0,
        brandOrForm: 'Forte Suspension',
        citation: 'Lexicomp 2024',
      );

      expect(conc250.concentrationMgPerMl, 50.0);
      expect(conc250.doseToVolumeMl(250.0), 5.0);
      expect(conc250.doseToTeaspoons(250.0), 1.0);
      expect(conc250.doseToVolumeMl(150.0), 3.0);
      expect(conc250.doseToTeaspoons(150.0), 0.6);
    });

    test('PharmacistCalculator: Paracetamol pediatric oral liquid dosing', () {
      final paraDrug = analgesics.firstWhere((d) => d.id == 'paracetamol');
      final pedsRegimen = paraDrug.regimens.firstWhere(
        (r) => r.indication == 'Fever/Pain (Pediatric)',
      );

      expect(pedsRegimen.hasLiquidConcentrations, isTrue);
      expect(pedsRegimen.liquidConcentrations!.length, 2);

      const patient = Patient(
        id: 'PT-PEDS-1',
        weightKg: 10.0,
        heightCm: 75.0,
        ageYears: 1,
        sex: Sex.female,
        isScrStable: true,
      );

      // Default concentration: 120 mg / 5 mL (dose = 10 kg * 10 mg/kg = 100 mg)
      final resDefault = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: paraDrug,
        regimen: pedsRegimen,
      );

      expect(resDefault.success, isTrue);
      expect(resDefault.calculatedDose, 100.0);
      expect(resDefault.volumeMl, closeTo(100.0 / 24.0, 0.01)); // ~4.17 mL
      expect(resDefault.teaspoons, closeTo((100.0 / 24.0) / 5.0, 0.01)); // ~0.83 tsp
      expect(resDefault.liquidConcentration?.amountMg, 120.0);

      // Select Forte: 250 mg / 5 mL (50 mg/mL)
      final forteConc = pedsRegimen.liquidConcentrations!.firstWhere(
        (c) => c.amountMg == 250.0,
      );
      final resForte = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: paraDrug,
        regimen: pedsRegimen,
        liquidConcentration: forteConc,
      );

      expect(resForte.success, isTrue);
      expect(resForte.calculatedDose, 100.0);
      expect(resForte.volumeMl, 2.0); // 100 mg / 50 mg/mL = 2.0 mL
      expect(resForte.teaspoons, 0.4); // 2.0 mL / 5.0 = 0.4 tsp
    });

    test('PharmacistCalculator: Amoxicillin pediatric oral liquid dosing', () {
      final amoxDrug = antibiotics.firstWhere((d) => d.id == 'amoxicillin');
      final pedsRegimen = amoxDrug.regimens.firstWhere(
        (r) => r.indication == 'Standard Infection (Pediatric)',
      );

      expect(pedsRegimen.hasLiquidConcentrations, isTrue);

      const patient = Patient(
        id: 'PT-PEDS-AMOX',
        weightKg: 10.0,
        heightCm: 75.0,
        ageYears: 2,
        sex: Sex.male,
        isScrStable: true,
      );

      // Standard Infection: 45 mg/kg/day divided q8h = 15 mg/kg/dose = 150 mg/dose
      final res = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: amoxDrug,
        regimen: pedsRegimen,
      );

      expect(res.success, isTrue);
      expect(res.calculatedDose, 150.0);
      // Default conc is 250 mg / 5 mL (50 mg/mL)
      expect(res.volumeMl, 3.0); // 150 / 50 = 3.0 mL
      expect(res.teaspoons, 0.6); // 3.0 / 5.0 = 0.6 tsp
    });
  });

  group('R2: Hospital IV Injectable Calculations', () {
    test('ReconstitutionInfo: calculateDrawVolume and calculateVialsNeeded', () {
      const reconstVanco = ReconstitutionInfo(
        vialStrengthMg: 500.0,
        diluentName: 'SWFI',
        diluentVolumeMl: 10.0,
        resultingConcentrationMgPerMl: 50.0,
        sourceCitation: 'Lexicomp 2024',
      );

      expect(reconstVanco.resultingConcentrationMgPerMl, 50.0);
      expect(reconstVanco.calculateDrawVolume(1000.0), 20.0);
      expect(reconstVanco.calculateDrawVolume(500.0), 10.0);
      expect(reconstVanco.calculateDrawVolume(750.0), 15.0);
      expect(reconstVanco.calculateVialsNeeded(1000.0), 2);
      expect(reconstVanco.calculateVialsNeeded(750.0), 2);
      expect(reconstVanco.calculateVialsNeeded(500.0), 1);
    });

    test('IvRateCalculator: reconstitution draw volume and vials count', () {
      expect(
        IvRateCalculator.vialDrawVolume(
          desiredDoseMg: 1000.0,
          concentrationMgPerMl: 50.0,
        ),
        20.0,
      );
      expect(
        IvRateCalculator.vialDrawVolume(
          desiredDoseMg: 2000.0,
          concentrationMgPerMl: 100.0,
        ),
        20.0,
      );
      expect(
        IvRateCalculator.vialsCount(
          doseMg: 1000.0,
          vialStrengthMg: 500.0,
        ),
        2,
      );
      expect(
        IvRateCalculator.vialsCount(
          doseMg: 4500.0,
          vialStrengthMg: 4500.0,
        ),
        1,
      );
    });

    test('IvRateCalculator: pump rate (mL/hr) and gravity drip rate', () {
      // 250 mL over 60 min = 250 mL/hr
      expect(
        IvRateCalculator.infusionRateMlPerHr(
          volumeMl: 250.0,
          timeMinutes: 60.0,
        ),
        250.0,
      );

      // 100 mL over 30 min = 200 mL/hr
      expect(
        IvRateCalculator.infusionRateMlPerHr(
          volumeMl: 100.0,
          timeMinutes: 30.0,
        ),
        200.0,
      );

      // 100 mL over 180 min (3 hours) = 33.33 mL/hr
      expect(
        IvRateCalculator.infusionRateMlPerHr(
          volumeMl: 100.0,
          timeMinutes: 180.0,
        ),
        closeTo(33.33, 0.01),
      );

      // Drip rate: 100 mL over 30 min with dropFactor 20 = (100 * 20) / 30 = 66.67 gtt/min
      expect(
        IvRateCalculator.dripRateDropsPerMin(
          volumeMl: 100.0,
          timeMinutes: 30.0,
          dropFactor: 20,
        ),
        closeTo(66.67, 0.01),
      );
    });

    test('PharmacistCalculator: Vancomycin IV reconstitution and pump rate', () {
      final vancoDrug = antibiotics.firstWhere((d) => d.id == 'vancomycin');
      final regimen = vancoDrug.regimens.first;

      const patient = Patient(
        id: 'PT-IV-1',
        weightKg: 66.7, // 66.7 kg * 15 mg/kg = ~1,000 mg
        heightCm: 170.0,
        ageYears: 45,
        sex: Sex.male,
        serumCreatinineMgDl: 0.9,
        isScrStable: true,
      );

      final res = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: vancoDrug,
        regimen: regimen,
      );

      expect(res.success, isTrue);
      expect(res.roundedDose, 1000.0);
      expect(res.vialDrawVolumeMl, 20.0); // 1,000 mg / 50 mg/mL = 20 mL
      expect(res.vialsNeeded, 2); // 2 x 500 mg vials
      expect(res.totalInfusionVolumeMl, 250.0); // Standard 250 mL bag
      expect(res.infusionDurationMinutes, 100.0); // Safe duration for 1,000 mg at max 10 mg/min = 100 min
      expect(res.infusionRateMlPerHr, 150.0); // 250 mL over 100 min = 150.0 mL/hr
    });

    test('PharmacistCalculator: Meropenem IV reconstitution and pump rate', () {
      final meroDrug = antibiotics.firstWhere((d) => d.id == 'meropenem');
      final regimen = meroDrug.regimens.firstWhere(
        (r) => r.indication == 'Severe Infection',
      );

      const patient = Patient(
        id: 'PT-IV-MERO',
        weightKg: 70.0,
        heightCm: 170.0,
        ageYears: 50,
        sex: Sex.male,
        serumCreatinineMgDl: 0.8,
        isScrStable: true,
      );

      final res = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: meroDrug,
        regimen: regimen,
      );

      expect(res.success, isTrue);
      expect(res.calculatedDose, 1000.0);
      expect(res.vialDrawVolumeMl, 20.0); // 1,000 mg / 50 mg/mL = 20 mL
      expect(res.totalInfusionVolumeMl, 100.0); // Standard 100 mL bag
      expect(res.infusionRateMlPerHr, 200.0); // 100 mL / 0.5 hr = 200 mL/hr
    });

    test('PharmacistCalculator: Ceftriaxone IV reconstitution and pump rate', () {
      final cefDrug = antibiotics.firstWhere((d) => d.id == 'ceftriaxone');
      final regimen = cefDrug.regimens.firstWhere(
        (r) => r.indication == 'Severe Infection (Adult)',
      );

      const patient = Patient(
        id: 'PT-IV-CEF',
        weightKg: 70.0,
        heightCm: 170.0,
        ageYears: 55,
        sex: Sex.male,
        isScrStable: true,
      );

      final res = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: cefDrug,
        regimen: regimen,
      );

      expect(res.success, isTrue);
      expect(res.calculatedDose, 2000.0);
      expect(res.vialDrawVolumeMl, 20.0); // 2,000 mg / 100 mg/mL = 20 mL
      expect(res.totalInfusionVolumeMl, 100.0); // 100 mL bag
      expect(res.infusionRateMlPerHr, 200.0); // 100 mL / 0.5 hr = 200 mL/hr
    });
  });

  group('R3: Direct Startup without PIN Authentication', () {
    testWidgets('DrugDosageApp launches directly to HomeScreen with no PIN prompt', (tester) async {
      await tester.pumpWidget(const DrugDosageApp());
      await tester.pump();

      // Verify HomeScreen is directly present
      expect(find.byType(HomeScreen), findsOneWidget);

      // Verify no PIN or password input textfield exists
      expect(find.text('Enter PIN'), findsNothing);
      expect(find.text('กรุณาใส่รหัส PIN'), findsNothing);
      expect(find.byKey(const Key('login_pin_field')), findsNothing);
      expect(find.byKey(const Key('login_submit_button')), findsNothing);
    });
  });
}
