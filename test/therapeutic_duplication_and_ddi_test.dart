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
  });
}
