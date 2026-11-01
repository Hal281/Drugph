import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';

void main() {
  group('ClinicalOrderFormatter RRT Order & Note Formatting Tests', () {
    test('formatHisOrder appends [CRRT] tag for CRRT regimen', () {
      final mero = DrugDatabase.findById('meropenem')!;
      const patient = Patient(
        id: 'PT-FMT-CRRT',
        weightKg: 70,
        heightCm: 170,
        ageYears: 55,
        sex: Sex.male,
        serumCreatinineMgDl: 3.8,
        isScrStable: true,
        renalReplacementMode: RenalReplacementMode.crrt,
      );

      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: mero,
        regimen: mero.regimens.first,
      );

      final hisOrder = ClinicalOrderFormatter.formatHisOrder(
        patient: patient,
        drug: mero,
        regimen: mero.regimens.first,
        result: result,
      );

      expect(hisOrder, contains('[CRRT]'));
      expect(hisOrder, contains('1000 mg'));
      expect(hisOrder, contains('q12h'));
    });

    test('formatHisOrder appends [IHD: Post-HD Dosing] when requiresPostHdSupplement is true', () {
      final mero = DrugDatabase.findById('meropenem')!;
      const patient = Patient(
        id: 'PT-FMT-IHD',
        weightKg: 70,
        heightCm: 170,
        ageYears: 65,
        sex: Sex.male,
        serumCreatinineMgDl: 5.2,
        isScrStable: true,
        renalReplacementMode: RenalReplacementMode.ihd,
      );

      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: mero,
        regimen: mero.regimens.first,
      );

      final hisOrder = ClinicalOrderFormatter.formatHisOrder(
        patient: patient,
        drug: mero,
        regimen: mero.regimens.first,
        result: result,
      );

      expect(hisOrder, contains('[IHD: Post-HD Dosing]'));
      expect(hisOrder, contains('500 mg'));
      expect(hisOrder, contains('q24h'));
    });

    test('formatHisOrder appends [IHD] when requiresPostHdSupplement is false (e.g. Enoxaparin)', () {
      final enox = DrugDatabase.findById('enoxaparin')!;
      const patient = Patient(
        id: 'PT-FMT-ENOX',
        weightKg: 70,
        heightCm: 170,
        ageYears: 65,
        sex: Sex.male,
        serumCreatinineMgDl: 5.2,
        isScrStable: true,
        renalReplacementMode: RenalReplacementMode.ihd,
      );

      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: enox,
        regimen: enox.regimens.first,
      );

      final hisOrder = ClinicalOrderFormatter.formatHisOrder(
        patient: patient,
        drug: enox,
        regimen: enox.regimens.first,
        result: result,
      );

      expect(hisOrder, contains('[IHD]'));
      expect(hisOrder, isNot(contains('[IHD: Post-HD Dosing]')));
    });

    test('formatPharmacistNote includes Section 1 RRT parameter and Section 3 clinical instructions', () {
      final mero = DrugDatabase.findById('meropenem')!;
      const patient = Patient(
        id: 'PT-NOTE-CRRT',
        weightKg: 70,
        heightCm: 170,
        ageYears: 55,
        sex: Sex.male,
        serumCreatinineMgDl: 3.8,
        isScrStable: true,
        renalReplacementMode: RenalReplacementMode.crrt,
      );

      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: mero,
        regimen: mero.regimens.first,
      );

      final note = ClinicalOrderFormatter.formatPharmacistNote(
        patient: patient,
        drug: mero,
        regimen: mero.regimens.first,
        result: result,
        isThai: true,
      );

      expect(note, contains('Renal Replacement Therapy:'));
      expect(note, contains('CRRT'));
      expect(note, contains('RRT Instructions:'));
    });
  });
}
