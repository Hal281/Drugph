import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:drug_dosage_calculator/data/prescription_cart.dart';
import 'package:drug_dosage_calculator/core/models/models.dart';
import 'package:drug_dosage_calculator/core/calculators/pharmacist_calculator.dart';

void main() {
  group('Therapeutic Duplication & Medical Evidence DDI Tests', () {
    // -------------------------------------------------------------------------
    // 1. Therapeutic Duplication (Same-Class & Same-Drug)
    // -------------------------------------------------------------------------
    test('1. Dual NSAID Duplication: Ibuprofen prescribed with active Naproxen triggers Hard Duplication Alert', () {
      const patient = Patient(
        id: 'p-nsaid-dup',
        weightKg: 65.0,
        heightCm: 170.0,
        ageYears: 45,
        sex: Sex.male,
        isScrStable: true,
        activeDrugIds: ['naproxen'],
      );

      final ibuprofen = DrugDatabase.findById('ibuprofen')!;
      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: ibuprofen,
        regimen: ibuprofen.regimens.first,
      );

      final dupWarnings = result.warnings.where(
        (w) => w.code == DoseWarningCode.therapeuticDuplication,
      );
      expect(dupWarnings, isNotEmpty);
      expect(dupWarnings.first.severity, equals(LimitSeverity.hard));
      expect(dupWarnings.first.messageEn, contains('THERAPEUTIC DUPLICATION'));
      expect(dupWarnings.first.messageEn, contains('NSAID'));
    });

    test('2. Dual RAS Blockade: Enalapril (ACEI) prescribed with active Losartan (ARB) triggers Hard Contraindication', () {
      const patient = Patient(
        id: 'p-ras-dup',
        weightKg: 70.0,
        heightCm: 175.0,
        ageYears: 60,
        sex: Sex.male,
        isScrStable: true,
        activeDrugIds: ['losartan'],
      );

      final enalapril = DrugDatabase.findById('enalapril')!;
      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: enalapril,
        regimen: enalapril.regimens.first,
      );

      final dupWarnings = result.warnings.where(
        (w) => w.code == DoseWarningCode.therapeuticDuplication,
      );
      expect(dupWarnings, isNotEmpty);
      expect(dupWarnings.first.severity, equals(LimitSeverity.hard));
      expect(dupWarnings.first.messageEn, contains('RAS Blockade'));
    });

    test('3. Dual Oral Anticoagulant: Apixaban (DOAC) with active Warfarin (VKA) triggers Hard Duplication', () {
      const patient = Patient(
        id: 'p-oac-dup',
        weightKg: 70.0,
        heightCm: 170.0,
        ageYears: 65,
        sex: Sex.female,
        isScrStable: true,
        activeDrugIds: ['warfarin'],
      );

      final apixaban = DrugDatabase.findById('apixaban')!;
      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: apixaban,
        regimen: apixaban.regimens.first,
      );

      final dupWarnings = result.warnings.where(
        (w) => w.code == DoseWarningCode.therapeuticDuplication,
      );
      expect(dupWarnings, isNotEmpty);
      expect(dupWarnings.first.severity, equals(LimitSeverity.hard));
      expect(dupWarnings.first.messageEn, contains('Anticoagulant'));
    });

    test('4. Identical Drug Duplication: Paracetamol prescribed when patient already taking Paracetamol', () {
      const patient = Patient(
        id: 'p-para-dup',
        weightKg: 60.0,
        heightCm: 165.0,
        ageYears: 30,
        sex: Sex.female,
        isScrStable: true,
        activeDrugIds: ['paracetamol'],
      );

      final paracetamol = DrugDatabase.findById('paracetamol')!;
      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: paracetamol,
        regimen: paracetamol.regimens.first,
      );

      final dupWarnings = result.warnings.where(
        (w) => w.code == DoseWarningCode.therapeuticDuplication,
      );
      expect(dupWarnings, isNotEmpty);
      expect(dupWarnings.first.severity, equals(LimitSeverity.hard));
      expect(dupWarnings.first.messageEn, contains('DUPLICATE ACTIVE DRUG'));
    });

    test('4b. Dual Statins: Atorvastatin with active Simvastatin triggers Hard Contraindication Alert', () {
      const patient = Patient(
        id: 'p-statin-dup',
        weightKg: 70.0,
        heightCm: 175.0,
        ageYears: 55,
        sex: Sex.male,
        isScrStable: true,
        activeDrugIds: ['simvastatin'],
      );

      final atorvastatin = DrugDatabase.findById('atorvastatin')!;
      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: atorvastatin,
        regimen: atorvastatin.regimens.first,
      );

      final dupWarnings = result.warnings.where(
        (w) => w.code == DoseWarningCode.therapeuticDuplication,
      );
      expect(dupWarnings, isNotEmpty);
      expect(dupWarnings.first.severity, equals(LimitSeverity.hard));
      expect(dupWarnings.first.messageEn, contains('statins'));
    });

    test('4c. Dual Potassium-Sparing Diuretics: Spironolactone with active Eplerenone triggers Hard Contraindication Alert', () {
      const patient = Patient(
        id: 'p-ksparing-dup',
        weightKg: 70.0,
        heightCm: 175.0,
        ageYears: 65,
        sex: Sex.male,
        isScrStable: true,
        activeDrugIds: ['eplerenone'],
      );

      final spironolactone = DrugDatabase.findById('spironolactone')!;
      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: spironolactone,
        regimen: spironolactone.regimens.first,
      );

      final dupWarnings = result.warnings.where(
        (w) => w.code == DoseWarningCode.therapeuticDuplication,
      );
      expect(dupWarnings, isNotEmpty);
      expect(dupWarnings.first.severity, equals(LimitSeverity.hard));
      expect(dupWarnings.first.messageEn, contains('potassium-sparing'));
    });

    test('4d. Dual DOAC + DOAC: Apixaban with active Rivaroxaban triggers Hard Contraindication Alert', () {
      const patient = Patient(
        id: 'p-doac-dup',
        weightKg: 70.0,
        heightCm: 170.0,
        ageYears: 68,
        sex: Sex.female,
        isScrStable: true,
        activeDrugIds: ['rivaroxaban'],
      );

      final apixaban = DrugDatabase.findById('apixaban')!;
      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: apixaban,
        regimen: apixaban.regimens.first,
      );

      final dupWarnings = result.warnings.where(
        (w) => w.code == DoseWarningCode.therapeuticDuplication,
      );
      expect(dupWarnings, isNotEmpty);
      expect(dupWarnings.first.severity, equals(LimitSeverity.hard));
      expect(dupWarnings.first.messageEn, contains('Anticoagulant'));
    });

    test('4e. Dual Parenteral Anticoagulant: Heparin with active Enoxaparin triggers Hard Contraindication Alert', () {
      const patient = Patient(
        id: 'p-heparin-dup',
        weightKg: 70.0,
        heightCm: 175.0,
        ageYears: 60,
        sex: Sex.male,
        isScrStable: true,
        activeDrugIds: ['enoxaparin'],
      );

      final heparin = DrugDatabase.findById('heparin')!;
      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: heparin,
        regimen: heparin.regimens.first,
      );

      final dupWarnings = result.warnings.where(
        (w) => w.code == DoseWarningCode.therapeuticDuplication,
      );
      expect(dupWarnings, isNotEmpty);
      expect(dupWarnings.first.severity, equals(LimitSeverity.hard));
      expect(dupWarnings.first.messageEn, contains('parenteral anticoagulants'));
    });

    test('5. PrescriptionCart flags Therapeutic Duplication between items in cart', () {
      final cart = PrescriptionCart.instance;
      cart.clearCart();
      cart.addDrug(DrugDatabase.findById('ibuprofen')!);
      cart.addDrug(DrugDatabase.findById('naproxen')!);

      final warnings = cart.checkInteractions(false);
      expect(
        warnings.any((w) => w.contains('DUPLICATION') || w.contains('NSAID')),
        isTrue,
      );
      cart.clearCart();
    });

    // -------------------------------------------------------------------------
    // 2. Advanced Allergy Matching (Dose suffix & Brand names)
    // -------------------------------------------------------------------------
    test('6. Allergy record with dosage suffix "Amoxicillin 500mg" matches Amoxicillin as direct match', () {
      final alerts = AllergyService.evaluateAllergies(
        patientAllergies: ['Amoxicillin 500mg'],
        drugGenericName: 'Amoxicillin',
        drugId: 'amoxicillin',
        drugClass: DrugClass.betaLactamPenicillin,
        legacyAllergyClass: 'Penicillin',
      );

      expect(alerts, isNotEmpty);
      expect(alerts.first.hasDirectMatch, isTrue);
      expect(alerts.first.severity, equals(LimitSeverity.hard));
    });

    test('7. Thai brand name "Ponstan" resolves to Mefenamic acid and triggers NSAID cross-reactivity for Ibuprofen', () {
      final alerts = AllergyService.evaluateAllergies(
        patientAllergies: ['พอนสแตน'],
        drugGenericName: 'Ibuprofen',
        drugId: 'ibuprofen',
        drugClass: DrugClass.nsaid,
        legacyAllergyClass: null,
      );

      expect(alerts, isNotEmpty);
      expect(alerts.first.hasCrossReactivity, isTrue);
      expect(alerts.first.severity, equals(LimitSeverity.soft));
    });

    test('8. Brand name "Voltaren" resolves to Diclofenac and triggers NSAID cross-reactivity for Ibuprofen', () {
      final alerts = AllergyService.evaluateAllergies(
        patientAllergies: ['Voltaren'],
        drugGenericName: 'Ibuprofen',
        drugId: 'ibuprofen',
        drugClass: DrugClass.nsaid,
        legacyAllergyClass: null,
      );

      expect(alerts, isNotEmpty);
      expect(alerts.first.hasCrossReactivity, isTrue);
      expect(alerts.first.severity, equals(LimitSeverity.soft));
    });

    // -------------------------------------------------------------------------
    // 3. Textbook-Grounded Drug-Drug Interactions (Lexicomp / Sanford Evidence)
    // -------------------------------------------------------------------------
    test('9. Methotrexate + Ibuprofen triggers Major Interaction Alert (OAT inhibition & MTX toxicity)', () {
      const patient = Patient(
        id: 'p-mtx-nsaid',
        weightKg: 60.0,
        heightCm: 160.0,
        ageYears: 55,
        sex: Sex.female,
        isScrStable: true,
        activeDrugIds: ['ibuprofen'],
      );

      final mtx = DrugDatabase.findById('methotrexate')!;
      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: mtx,
        regimen: mtx.regimens.first,
      );

      final ddiWarnings = result.warnings.where(
        (w) => w.code == DoseWarningCode.severeInteractionAlert || w.code == DoseWarningCode.contraindicationAlert,
      );
      expect(ddiWarnings, isNotEmpty);
      expect(ddiWarnings.any((w) => w.messageEn.contains('Methotrexate') || w.messageEn.contains('NSAID') || w.messageEn.contains('ibuprofen')), isTrue);
    });

    test('10. Enalapril + Spironolactone triggers Major Hyperkalemia Interaction Alert', () {
      const patient = Patient(
        id: 'p-ace-spiro',
        weightKg: 70.0,
        heightCm: 170.0,
        ageYears: 65,
        sex: Sex.male,
        isScrStable: true,
        activeDrugIds: ['spironolactone'],
      );

      final enalapril = DrugDatabase.findById('enalapril')!;
      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: enalapril,
        regimen: enalapril.regimens.first,
      );

      final ddiWarnings = result.warnings.where(
        (w) => w.code == DoseWarningCode.severeInteractionAlert,
      );
      expect(ddiWarnings, isNotEmpty);
      expect(ddiWarnings.any((w) => w.messageEn.contains('Hyperkalemia') || w.messageEn.contains('potassium')), isTrue);
    });

    test('11. Clopidogrel + Omeprazole triggers CYP2C19 Interaction Alert', () {
      const patient = Patient(
        id: 'p-clop-ome',
        weightKg: 65.0,
        heightCm: 165.0,
        ageYears: 60,
        sex: Sex.male,
        isScrStable: true,
        activeDrugIds: ['omeprazole'],
      );

      final clopidogrel = DrugDatabase.findById('clopidogrel')!;
      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: clopidogrel,
        regimen: clopidogrel.regimens.first,
      );

      final ddiWarnings = result.warnings.where(
        (w) => w.code == DoseWarningCode.severeInteractionAlert,
      );
      expect(ddiWarnings, isNotEmpty);
      expect(ddiWarnings.any((w) => w.messageEn.contains('CYP2C19') || w.messageEn.contains('Omeprazole')), isTrue);
    });

    test('12. Simvastatin + Clarithromycin triggers Major Rhabdomyolysis DDI Alert', () {
      const patient = Patient(
        id: 'p-simva-clari',
        weightKg: 70.0,
        heightCm: 170.0,
        ageYears: 62,
        sex: Sex.male,
        isScrStable: true,
        activeDrugIds: ['clarithromycin'],
      );

      final simvastatin = DrugDatabase.findById('simvastatin')!;
      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: simvastatin,
        regimen: simvastatin.regimens.first,
      );

      final ddiWarnings = result.warnings.where(
        (w) => w.code == DoseWarningCode.severeInteractionAlert || w.code == DoseWarningCode.contraindicationAlert,
      );
      expect(ddiWarnings, isNotEmpty);
      expect(ddiWarnings.any((w) => w.messageEn.contains('CYP3A4') || w.messageEn.contains('rhabdomyolysis') || w.messageEn.contains('statin')), isTrue);
    });

    // -------------------------------------------------------------------------
    // 4. Emergency Vasoactive Regimens End-to-End Pump Rate Verification
    // -------------------------------------------------------------------------
    group('4. Emergency Vasoactive Regimens End-to-End Pump Rate Verification', () {
      const patient70 = Patient(
        id: 'pt-70',
        weightKg: 70.0,
        heightCm: 175.0,
        ageYears: 50,
        sex: Sex.male,
        isScrStable: true,
      );

      test('Norepinephrine: 70 kg at 0.01 mcg/kg/min yields 2.625 mL/hr, at 3.0 mcg/kg/min yields 787.5 mL/hr', () {
        final norepi = DrugDatabase.findById('norepinephrine')!;
        final reg = norepi.regimens.first;
        final res = PharmacistCalculator.calculateDose(
          patient: patient70,
          drug: norepi,
          regimen: reg,
        );
        expect(res.infusionResult, isNotNull);
        expect(res.infusionResult!.rateUnit, equals(RateUnit.mcgKgMin));
        expect(res.infusionResult!.rate, equals(0.01));
        expect(res.infusionResult!.rateMax, equals(3.0));
        expect(res.infusionResult!.rateMlPerHr, closeTo(2.625, 0.001));
        expect(res.infusionResult!.rateMlPerHrMax, closeTo(787.5, 0.01));
      });

      test('Dopamine: 70 kg at 2.0 mcg/kg/min yields 5.25 mL/hr, at 20.0 mcg/kg/min yields 52.5 mL/hr', () {
        final dopa = DrugDatabase.findById('dopamine')!;
        final reg = dopa.regimens.first;
        final res = PharmacistCalculator.calculateDose(
          patient: patient70,
          drug: dopa,
          regimen: reg,
        );
        expect(res.infusionResult, isNotNull);
        expect(res.infusionResult!.rateUnit, equals(RateUnit.mcgKgMin));
        expect(res.infusionResult!.rate, equals(2.0));
        expect(res.infusionResult!.rateMax, equals(20.0));
        expect(res.infusionResult!.rateMlPerHr, closeTo(5.25, 0.001));
        expect(res.infusionResult!.rateMlPerHrMax, closeTo(52.5, 0.01));
      });

      test('Dobutamine: 70 kg at 2.0 mcg/kg/min yields 8.4 mL/hr, at 20.0 mcg/kg/min yields 84.0 mL/hr', () {
        final dobut = DrugDatabase.findById('dobutamine')!;
        final reg = dobut.regimens.first;
        final res = PharmacistCalculator.calculateDose(
          patient: patient70,
          drug: dobut,
          regimen: reg,
        );
        expect(res.infusionResult, isNotNull);
        expect(res.infusionResult!.rateUnit, equals(RateUnit.mcgKgMin));
        expect(res.infusionResult!.rate, equals(2.0));
        expect(res.infusionResult!.rateMax, equals(20.0));
        expect(res.infusionResult!.rateMlPerHr, closeTo(8.4, 0.001));
        expect(res.infusionResult!.rateMlPerHrMax, closeTo(84.0, 0.01));
      });
    });
  });
}
