import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:drug_dosage_calculator/data/patient_session.dart';
import 'package:drug_dosage_calculator/ui/calculator/controllers/calculator_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const child10Kg = Patient(
    id: 'p-child-10kg',
    weightKg: 10.0,
    heightCm: 85.0,
    ageYears: 2,
    sex: Sex.male,
    isScrStable: true,
  );

  setUp(() {
    PatientSession.instance.clearPatient();
  });

  tearDown(() {
    PatientSession.instance.clearPatient();
  });

  group('Item 2 — Pediatric Weight-Based Dosing & Amoxicillin 10 kg Bug Fix', () {
    test('Standalone Amoxicillin for 10 kg child calculates 150 mg q8h (standard) and 450 mg q12h (AOM)', () {
      final amox = DrugDatabase.findById('amoxicillin');
      expect(amox, isNotNull, reason: 'Standalone Amoxicillin must exist in DrugDatabase.allDrugs');

      final standardPed = amox!.regimens.firstWhere(
        (r) => r.indication == 'Standard Infection (Pediatric)',
      );
      expect(standardPed.doseBasis, equals(DoseBasis.perDay));
      expect(standardPed.effectiveAudience, equals(RegimenAudience.pediatric));

      final stdResult = PharmacistCalculator.calculateDose(
        patient: child10Kg,
        drug: amox,
        regimen: standardPed,
      );
      expect(stdResult.success, isTrue);
      expect(stdResult.isBlocked, isFalse);
      expect(stdResult.calculatedDose, closeTo(150.0, 0.01));
      expect(stdResult.structuredFrequency?.displayEn, equals('q8h'));
      expect(stdResult.calculatedDose, isNot(equals(500.0)));

      final aomPed = amox.regimens.firstWhere(
        (r) => r.indication == 'Acute Otitis Media / High-Dose (Pediatric)',
      );
      expect(aomPed.doseBasis, equals(DoseBasis.perDay));
      expect(aomPed.effectiveAudience, equals(RegimenAudience.pediatric));

      final aomResult = PharmacistCalculator.calculateDose(
        patient: child10Kg,
        drug: amox,
        regimen: aomPed,
      );
      expect(aomResult.success, isTrue);
      expect(aomResult.isBlocked, isFalse);
      expect(aomResult.calculatedDose, closeTo(450.0, 0.01));
      expect(aomResult.structuredFrequency?.displayEn, equals('q12h'));
    });

    test('Standalone Amoxicillin for 10 kg child with severe renal impairment (CrCl < 10) gives 150 mg q24h, never 500 mg q24h', () {
      final amox = DrugDatabase.findById('amoxicillin')!;
      final standardPed = amox.regimens.firstWhere(
        (r) => r.indication == 'Standard Infection (Pediatric)',
      );

      const renalChild = Patient(
        id: 'p-child-10kg-renal',
        weightKg: 10.0,
        heightCm: 85.0,
        ageYears: 2,
        sex: Sex.male,
        creatinineClearanceMlMin: 8.0,
        isScrStable: true,
      );

      final result = PharmacistCalculator.calculateDose(
        patient: renalChild,
        drug: amox,
        regimen: standardPed,
      );
      expect(result.success, isTrue);
      expect(result.calculatedDose, closeTo(150.0, 0.01));
      expect(result.structuredFrequency?.displayEn, equals('q24h'));
      expect(result.isRenallyAdjusted, isTrue);
    });

    test('Amoxicillin/Clavulanate for 10 kg child calculates 225 mg q12h (standard) and 450 mg q12h (AOM)', () {
      final amoxClav = DrugDatabase.findById('amoxicillin_clavulanate')!;

      final standardPed = amoxClav.regimens.firstWhere(
        (r) => r.indication == 'Standard Infection (Pediatric)',
      );
      expect(standardPed.doseBasis, equals(DoseBasis.perDay));

      final stdResult = PharmacistCalculator.calculateDose(
        patient: child10Kg,
        drug: amoxClav,
        regimen: standardPed,
      );
      expect(stdResult.success, isTrue);
      expect(stdResult.calculatedDose, closeTo(225.0, 0.01));
      expect(stdResult.structuredFrequency?.displayEn, equals('q12h'));

      final aomPed = amoxClav.regimens.firstWhere(
        (r) => r.indication == 'Acute Otitis Media / High-Dose (Pediatric)',
      );
      expect(aomPed.doseBasis, equals(DoseBasis.perDay));

      final aomResult = PharmacistCalculator.calculateDose(
        patient: child10Kg,
        drug: amoxClav,
        regimen: aomPed,
      );
      expect(aomResult.success, isTrue);
      expect(aomResult.calculatedDose, closeTo(450.0, 0.01));
      expect(aomResult.structuredFrequency?.displayEn, equals('q12h'));
    });

    test('CalculatorController auto-switches to pediatric regimen and avoids default adult 35y/170cm trap for 10 kg child', () {
      PatientSession.instance.updateCurrentPatient(
        weightKg: 70.0,
        heightCm: 170.0,
        ageYears: 35,
        serumCreatinineMgDl: 1.0,
        sex: Sex.male,
      );

      final amox = DrugDatabase.findById('amoxicillin')!;
      final amoxController = CalculatorController(drug: amox);
      addTearDown(amoxController.dispose);

      amoxController.weightCtrl.text = '10';
      expect(
        amoxController.state.selectedRegimen?.indication,
        equals('Standard Infection (Pediatric)'),
      );

      final amoxVal = amoxController.calculate(isThai: true);
      expect(amoxVal.isValid, isTrue);
      expect(amoxController.state.result, isNotNull);
      expect(amoxController.state.result!.calculatedDose, closeTo(150.0, 0.01));
      expect(amoxController.state.result!.structuredFrequency?.displayEn, equals('q8h'));
      expect(amoxController.ageCtrl.text, equals('2'));
      expect(amoxController.heightCtrl.text, equals('85'));

      // Reset adult session baseline and test Amoxicillin/Clavulanate too
      PatientSession.instance.updateCurrentPatient(
        weightKg: 70.0,
        heightCm: 170.0,
        ageYears: 35,
        serumCreatinineMgDl: 1.0,
        sex: Sex.male,
      );

      final amoxClav = DrugDatabase.findById('amoxicillin_clavulanate')!;
      final clavController = CalculatorController(drug: amoxClav);
      addTearDown(clavController.dispose);

      clavController.weightCtrl.text = '10';
      expect(
        clavController.state.selectedRegimen?.indication,
        equals('Standard Infection (Pediatric)'),
      );

      final clavVal = clavController.calculate(isThai: true);
      expect(clavVal.isValid, isTrue);
      expect(clavController.state.result, isNotNull);
      expect(clavController.state.result!.calculatedDose, closeTo(225.0, 0.01));
      expect(clavController.state.result!.structuredFrequency?.displayEn, equals('q12h'));
    });

    test('Valproic acid uses DoseBasis.perDay so 15 mg/kg/day is divided across BID-TID in adult and pediatric', () {
      final valproate = DrugDatabase.findById('valproic_acid')!;
      final adultOral = valproate.regimens.first;
      expect(adultOral.doseBasis, equals(DoseBasis.perDay));

      const adult60Kg = Patient(
        id: 'p-adult-60kg',
        weightKg: 60.0,
        heightCm: 170.0,
        ageYears: 30,
        sex: Sex.male,
        isScrStable: true,
      );

      final adultResult = PharmacistCalculator.calculateDose(
        patient: adult60Kg,
        drug: valproate,
        regimen: adultOral,
      );
      expect(adultResult.success, isTrue);
      // 60 kg * 15 mg/kg/day = 900 mg/day; divided BID (maxIntervalHours = 12) = 450 mg/dose
      expect(adultResult.calculatedDose, closeTo(450.0, 0.01));
      expect(adultResult.dailyDose, closeTo(900.0, 0.01));

      final pediatricOral = valproate.regimens.firstWhere(
        (r) => r.indication == 'Seizures (Pediatric >= 2 years)',
      );
      expect(pediatricOral.doseBasis, equals(DoseBasis.perDay));
      expect(pediatricOral.effectiveAudience, equals(RegimenAudience.pediatric));

      const child20Kg = Patient(
        id: 'p-20kg',
        weightKg: 20.0,
        heightCm: 115.0,
        ageYears: 6,
        sex: Sex.male,
        isScrStable: true,
      );

      final pedResult = PharmacistCalculator.calculateDose(
        patient: child20Kg,
        drug: valproate,
        regimen: pediatricOral,
      );
      expect(pedResult.success, isTrue);
      // 20 kg * 15 mg/kg/day = 300 mg/day; divided BID (maxIntervalHours = 12) = 150 mg/dose
      expect(pedResult.calculatedDose, closeTo(150.0, 0.01));
      expect(pedResult.dailyDose, closeTo(300.0, 0.01));
    });
  });
}
