import 'package:test/test.dart';
import 'package:drug_dosage_calculator/core/calculators/calculators.dart';
import 'package:drug_dosage_calculator/core/models/models.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';

void main() {
  group('Audited Adjustments, DDI, and Safety Engine Tests', () {
    // -------------------------------------------------------------------------
    // 1. Bidirectional Allergy Cross-Reactivity
    // -------------------------------------------------------------------------
    group('Bidirectional beta-lactam cross-reactivity', () {
      test('Cephalosporin allergy flags cross-reactivity warning when Penicillin is prescribed', () {
        final alerts = AllergyService.evaluateAllergies(
          patientAllergies: ['Ceftriaxone'],
          drugGenericName: 'Ampicillin',
          drugId: 'ampicillin',
          drugClass: DrugClass.betaLactamPenicillin,
          legacyAllergyClass: 'Penicillin',
        );

        expect(alerts, isNotEmpty);
        final crossAlert = alerts.firstWhere((a) => a.hasCrossReactivity);
        expect(crossAlert.severity, equals(LimitSeverity.soft));
        expect(crossAlert.hasDirectMatch, isFalse);
      });

      test('Carbapenem allergy flags cross-reactivity warning when Penicillin is prescribed', () {
        final alerts = AllergyService.evaluateAllergies(
          patientAllergies: ['Meropenem'],
          drugGenericName: 'Amoxicillin',
          drugId: 'amoxicillin',
          drugClass: DrugClass.betaLactamPenicillin,
          legacyAllergyClass: 'Penicillin',
        );

        expect(alerts, isNotEmpty);
        final crossAlert = alerts.firstWhere((a) => a.hasCrossReactivity);
        expect(crossAlert.severity, equals(LimitSeverity.soft));
        expect(crossAlert.hasDirectMatch, isFalse);
      });

      test('Penicillin allergy flags cross-reactivity warning when Carbapenem is prescribed', () {
        final alerts = AllergyService.evaluateAllergies(
          patientAllergies: ['Amoxicillin'],
          drugGenericName: 'Meropenem',
          drugId: 'meropenem',
          drugClass: DrugClass.betaLactamCarbapenem,
          legacyAllergyClass: 'Carbapenem',
        );

        expect(alerts, isNotEmpty);
        final crossAlert = alerts.firstWhere((a) => a.hasCrossReactivity);
        expect(crossAlert.severity, equals(LimitSeverity.soft));
      });
    });

    // -------------------------------------------------------------------------
    // 2. Canonical requiresHepaticCaution Property & Backward Compatibility
    // -------------------------------------------------------------------------
    group('Drug requiresHepaticCaution canonical field', () {
      test('requiresHepaticCaution is accessible and mirrored by legacy getter', () {
        const drug = Drug(
          id: 'test_hepatic',
          genericName: 'TestHepatic',
          category: DrugCategory.gastrointestinal,
          requiresHepaticCaution: true,
          regimens: [],
        );

        expect(drug.requiresHepaticCaution, isTrue);
        // Deprecated backward-compatible getter
        // ignore: deprecated_member_use_from_same_package
        expect(drug.requiresHepationCaution, isTrue);
      });
    });

    // -------------------------------------------------------------------------
    // 3. DoseChecker Renal Hard Contraindications
    // -------------------------------------------------------------------------
    group('DoseChecker renal contraindications', () {
      test('RenalAction.contraindicated triggers hard contraindication warning', () {
        final warnings = DoseChecker.checkRenalAdjustment(
          crclMlMin: 15.0,
          adjustments: [
            const RenalAdjustment(
              crclMin: 0.0,
              crclMax: 30.0,
              action: RenalAction.contraindicated,
              notes: 'Contraindicated when CrCl < 30 mL/min',
              notesTh: 'ห้ามใช้เมื่อ CrCl < 30 มล./นาที',
            ),
          ],
        );

        expect(warnings, isNotEmpty);
        final contraWarning = warnings.firstWhere(
          (w) => w.code == DoseWarningCode.contraindicationAlert,
        );
        expect(contraWarning.severity, equals(LimitSeverity.hard));
      });

      test('RenalAction.avoid triggers hard contraindication warning', () {
        final warnings = DoseChecker.checkRenalAdjustment(
          crclMlMin: 20.0,
          adjustments: [
            const RenalAdjustment(
              crclMin: 0.0,
              crclMax: 30.0,
              action: RenalAction.avoid,
              notes: 'Avoid in severe renal impairment',
            ),
          ],
        );

        expect(warnings, isNotEmpty);
        final avoidWarning = warnings.firstWhere(
          (w) => w.code == DoseWarningCode.contraindicationAlert,
        );
        expect(avoidWarning.severity, equals(LimitSeverity.hard));
      });
    });

    // -------------------------------------------------------------------------
    // 4. Therapeutic Duplications & Clinical Drug-Drug Interactions
    // -------------------------------------------------------------------------
    group('Therapeutic duplications & clinical interactions', () {
      test('Dual Sulfonylurea duplication is detected as hard contraindication', () {
        const drugA = Drug(
          id: 'glipizide',
          genericName: 'Glipizide',
          category: DrugCategory.endocrine,
          drugClass: DrugClass.sulfonylurea,
          regimens: [],
        );
        const drugB = Drug(
          id: 'glibenclamide',
          genericName: 'Glibenclamide',
          category: DrugCategory.endocrine,
          drugClass: DrugClass.sulfonylurea,
          regimens: [],
        );

        final warning = TherapeuticDuplicationService.checkDuplication(drugA, drugB);
        expect(warning, isNotNull);
        expect(warning!.severity, equals(LimitSeverity.hard));
        expect(warning.messageEn, contains('sulfonylurea'));
      });

      test('Dual DPP-4 inhibitor duplication is detected', () {
        const drugA = Drug(
          id: 'sitagliptin',
          genericName: 'Sitagliptin',
          category: DrugCategory.endocrine,
          drugClass: DrugClass.dpp4Inhibitor,
          regimens: [],
        );
        const drugB = Drug(
          id: 'linagliptin',
          genericName: 'Linagliptin',
          category: DrugCategory.endocrine,
          drugClass: DrugClass.dpp4Inhibitor,
          regimens: [],
        );

        final warning = TherapeuticDuplicationService.checkDuplication(drugA, drugB);
        expect(warning, isNotNull);
        expect(warning!.severity, equals(LimitSeverity.hard));
        expect(warning.messageEn, contains('DPP-4'));
      });

      test('Dual SGLT2 inhibitor duplication is detected', () {
        const drugA = Drug(
          id: 'empagliflozin',
          genericName: 'Empagliflozin',
          category: DrugCategory.endocrine,
          drugClass: DrugClass.sglt2Inhibitor,
          regimens: [],
        );
        const drugB = Drug(
          id: 'dapagliflozin',
          genericName: 'Dapagliflozin',
          category: DrugCategory.endocrine,
          drugClass: DrugClass.sglt2Inhibitor,
          regimens: [],
        );

        final warning = TherapeuticDuplicationService.checkDuplication(drugA, drugB);
        expect(warning, isNotNull);
        expect(warning!.severity, equals(LimitSeverity.hard));
        expect(warning.messageEn, contains('SGLT2'));
      });

      test('Dual Thiazide diuretic duplication is detected', () {
        const drugA = Drug(
          id: 'hydrochlorothiazide',
          genericName: 'Hydrochlorothiazide',
          category: DrugCategory.cardiovascular,
          drugClass: DrugClass.thiazideDiuretic,
          regimens: [],
        );
        const drugB = Drug(
          id: 'chlorthalidone',
          genericName: 'Chlorthalidone',
          category: DrugCategory.cardiovascular,
          drugClass: DrugClass.thiazideDiuretic,
          regimens: [],
        );

        final warning = TherapeuticDuplicationService.checkDuplication(drugA, drugB);
        expect(warning, isNotNull);
        expect(warning!.severity, equals(LimitSeverity.hard));
        expect(warning.messageEn, contains('thiazide'));
      });

      test('Simvastatin + Clarithromycin triggers severe CYP3A4 interaction', () {
        const simva = Drug(
          id: 'simvastatin',
          genericName: 'Simvastatin',
          category: DrugCategory.cardiovascular,
          drugClass: DrugClass.statin,
          regimens: [],
        );
        const clarithro = Drug(
          id: 'clarithromycin',
          genericName: 'Clarithromycin',
          category: DrugCategory.antibiotic,
          drugClass: DrugClass.macrolide,
          regimens: [],
        );

        final warnings = ClinicalInteractionRegistry.checkInteractions(simva, clarithro);
        expect(warnings, isNotEmpty);
        final ddi = warnings.firstWhere((w) => w.code == DoseWarningCode.severeInteractionAlert);
        expect(ddi.severity, equals(LimitSeverity.hard));
        expect(ddi.messageEn, contains('CYP3A4'));
      });

      test('Rosuvastatin + Azithromycin does NOT trigger CYP3A4 statin+macrolide alert', () {
        const rosuva = Drug(
          id: 'rosuvastatin',
          genericName: 'Rosuvastatin',
          category: DrugCategory.cardiovascular,
          drugClass: DrugClass.statin,
          regimens: [],
        );
        const azithro = Drug(
          id: 'azithromycin',
          genericName: 'Azithromycin',
          category: DrugCategory.antibiotic,
          drugClass: DrugClass.macrolide,
          regimens: [],
        );

        final warnings = ClinicalInteractionRegistry.checkInteractions(rosuva, azithro);
        expect(
          warnings.where((w) => w.messageEn.contains('strongly inhibits CYP3A4')),
          isEmpty,
        );
      });

      test('Anticoagulant + NSAID triggers severe GI bleeding warning', () {
        const warfarin = Drug(
          id: 'warfarin',
          genericName: 'Warfarin',
          category: DrugCategory.anticoagulant,
          drugClass: DrugClass.anticoagulantVka,
          regimens: [],
        );
        const ibuprofen = Drug(
          id: 'ibuprofen',
          genericName: 'Ibuprofen',
          category: DrugCategory.analgesic,
          drugClass: DrugClass.nsaid,
          regimens: [],
        );

        final warnings = ClinicalInteractionRegistry.checkInteractions(warfarin, ibuprofen);
        expect(warnings, isNotEmpty);
        expect(warnings.first.severity, equals(LimitSeverity.hard));
        expect(warnings.first.messageEn, contains('gastrointestinal ulceration'));
      });

      test('Spironolactone + Potassium chloride triggers fatal hyperkalemia warning', () {
        const spiro = Drug(
          id: 'spironolactone',
          genericName: 'Spironolactone',
          category: DrugCategory.cardiovascular,
          drugClass: DrugClass.potassiumSparingDiuretic,
          regimens: [],
        );
        const kcl = Drug(
          id: 'potassium_chloride',
          genericName: 'Potassium Chloride',
          category: DrugCategory.electrolyte,
          regimens: [],
        );

        final warnings = ClinicalInteractionRegistry.checkInteractions(spiro, kcl);
        expect(warnings, isNotEmpty);
        expect(warnings.first.severity, equals(LimitSeverity.hard));
        expect(warnings.first.messageEn, contains('fatal hyperkalemia'));
      });

      test('Lithium + NSAID or ACEI triggers lithium toxicity warning', () {
        const lithium = Drug(
          id: 'lithium',
          genericName: 'Lithium carbonate',
          category: DrugCategory.psychiatric,
          regimens: [],
        );
        const enalapril = Drug(
          id: 'enalapril',
          genericName: 'Enalapril',
          category: DrugCategory.cardiovascular,
          drugClass: DrugClass.aceInhibitor,
          regimens: [],
        );

        final warnings = ClinicalInteractionRegistry.checkInteractions(lithium, enalapril);
        expect(warnings, isNotEmpty);
        expect(warnings.first.severity, equals(LimitSeverity.hard));
        expect(warnings.first.messageEn, contains('lithium toxicity'));
      });
    });

    // -------------------------------------------------------------------------
    // 5. Ondansetron Child-Pugh C Hepatic Dose Ceiling
    // -------------------------------------------------------------------------
    group('Ondansetron severe hepatic impairment rule', () {
      test('Child-Pugh C patient receiving Ondansetron has dose capped at 8 mg/day q24h', () {
        final ondansetron = DrugDatabase.findById('ondansetron');
        expect(ondansetron, isNotNull);
        expect(ondansetron!.requiresHepaticCaution, isTrue);

        const patientSevereLiver = Patient(
          id: 'p_cirrhosis',
          weightKg: 60.0,
          heightCm: 165.0,
          ageYears: 55,
          sex: Sex.male,
          hepaticImpairment: ChildPughClass.classC,
          isScrStable: true,
        );

        final regimen = ondansetron.regimens.first;
        final result = PharmacistCalculator.calculateDose(
          drug: ondansetron,
          regimen: regimen,
          patient: patientSevereLiver,
        );

        expect(result.success, isTrue);
        expect(result.calculatedDose, lessThanOrEqualTo(8.0));
        expect(result.frequency, equals('q24h'));
        expect(
          result.warnings.any((w) => w.messageEn.contains('Child-Pugh C') || w.messageEn.contains('HEPATIC DOSE CEILING')),
          isTrue,
        );
      });
    });
  });
}
