// ============================================================================
// Pending Pharmacist Registry & Baseline Invariance Test Suite
// ============================================================================
// Verifies:
// 1. Structure, schema, citations, and defaults of all 6 pending decisions
// 2. Query helper methods (findById, getByCategory, getByDrugId)
// 3. 100% calculation invariance of active baseline math in Drugph
// 4. Physical existence and completeness of review/Pending_Pharmacist_Signoff_Checklist.md
// ============================================================================

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PendingPharmacistRegistry Structure & Integrity', () {
    test('Registry contains exactly 6 pending clinical decisions', () {
      expect(PendingPharmacistRegistry.count, equals(6));
      expect(PendingPharmacistRegistry.allDecisions.length, equals(6));
    });

    test('All 6 expected decision codes exist in sequential order', () {
      final codes =
          PendingPharmacistRegistry.allDecisions.map((d) => d.id).toList();
      expect(codes, equals([
        'DEC-PND-001',
        'DEC-PND-002',
        'DEC-PND-003',
        'DEC-PND-004',
        'DEC-PND-005',
        'DEC-PND-006',
      ]));
    });

    test('Every decision adheres to honest defaults and non-empty schema', () {
      for (final decision in PendingPharmacistRegistry.allDecisions) {
        expect(decision.id.isNotEmpty, isTrue, reason: 'id must not be empty');
        expect(decision.decisionCode, equals(decision.id));
        expect(decision.titleEn.isNotEmpty, isTrue,
            reason: '${decision.id} titleEn');
        expect(decision.titleTh.isNotEmpty, isTrue,
            reason: '${decision.id} titleTh');
        expect(decision.targetFile.startsWith('lib/'), isTrue,
            reason: '${decision.id} targetFile path');
        expect(decision.affectedDrugIds.isNotEmpty, isTrue,
            reason: '${decision.id} affectedDrugIds');
        expect(decision.clinicalDilemmaEn.isNotEmpty, isTrue,
            reason: '${decision.id} clinicalDilemmaEn');
        expect(decision.clinicalDilemmaTh.isNotEmpty, isTrue,
            reason: '${decision.id} clinicalDilemmaTh');
        expect(decision.currentBaselineBehaviorEn.isNotEmpty, isTrue,
            reason: '${decision.id} currentBaselineBehaviorEn');
        expect(decision.currentBaselineBehaviorTh.isNotEmpty, isTrue,
            reason: '${decision.id} currentBaselineBehaviorTh');

        // Honest default status must be pendingPharmacistDecision
        expect(
          decision.status,
          equals(PendingDecisionStatus.pendingPharmacistDecision),
          reason: '${decision.id} must default to pendingPharmacistDecision',
        );

        // Candidate options verification (at least 3 options: A, B, C)
        expect(decision.candidateOptions.length, greaterThanOrEqualTo(3),
            reason: '${decision.id} candidate options count');
        final optionIds = decision.candidateOptions.map((o) => o.id).toList();
        expect(optionIds, containsAll(['optionA', 'optionB', 'optionC']));

        for (final option in decision.candidateOptions) {
          expect(option.id.isNotEmpty, isTrue);
          expect(option.titleEn.isNotEmpty, isTrue);
          expect(option.titleTh.isNotEmpty, isTrue);
          expect(option.descriptionEn.isNotEmpty, isTrue);
          expect(option.descriptionTh.isNotEmpty, isTrue);
          expect(option.citation.isNotEmpty, isTrue,
              reason: 'Option ${option.id} in ${decision.id} must cite literature');
          expect(option.clinicalRationale.isNotEmpty, isTrue);
        }

        // Default option resolution
        expect(optionIds.contains(decision.defaultOptionId), isTrue);
        expect(decision.defaultOption.id, equals(decision.defaultOptionId));
      }
    });

    test('DEC-PND-001 specifically covers Acyclovir IV obesity and ceiling', () {
      final dec = PendingPharmacistRegistry.findById('DEC-PND-001')!;
      expect(dec.affectedDrugIds, contains('acyclovir'));
      expect(dec.category, equals(PendingDecisionCategory.antimicrobialStewardship));
      expect(dec.targetFile, equals('lib/data/drugs/antibiotics.dart'));
      expect(dec.candidateOptions.any((o) => o.citation.contains('Sanford Guide')), isTrue);
      expect(dec.candidateOptions.any((o) => o.titleEn.contains('IBW')), isTrue);
    });

    test('DEC-PND-002 specifically covers Atropine pediatric bradycardia', () {
      final dec = PendingPharmacistRegistry.findById('DEC-PND-002')!;
      expect(dec.affectedDrugIds, contains('atropine'));
      expect(dec.category, equals(PendingDecisionCategory.emergencyResuscitation));
      expect(dec.targetFile, equals('lib/data/drugs/emergency.dart'));
      expect(dec.candidateOptions.any((o) => o.citation.contains('PALS')), isTrue);
      expect(dec.candidateOptions.any((o) => o.titleEn.contains('0.5 mg')), isTrue);
    });

    test('DEC-PND-003 specifically covers Dexamethasone croup ceiling', () {
      final dec = PendingPharmacistRegistry.findById('DEC-PND-003')!;
      expect(dec.affectedDrugIds, contains('dexamethasone'));
      expect(dec.category, equals(PendingDecisionCategory.respiratoryAllergy));
      expect(dec.targetFile, equals('lib/data/drugs/emergency.dart'));
      expect(dec.candidateOptions.any((o) => o.titleEn.contains('10 mg')), isTrue);
      expect(dec.candidateOptions.any((o) => o.titleEn.contains('16 mg')), isTrue);
    });

    test('DEC-PND-004 specifically covers Epinephrine anaphylaxis ceiling', () {
      final dec = PendingPharmacistRegistry.findById('DEC-PND-004')!;
      expect(dec.affectedDrugIds, contains('epinephrine'));
      expect(dec.category, equals(PendingDecisionCategory.emergencyResuscitation));
      expect(dec.targetFile, equals('lib/data/drugs/emergency.dart'));
      expect(dec.candidateOptions.any((o) => o.citation.contains('WAO')), isTrue);
      expect(dec.candidateOptions.any((o) => o.titleEn.contains('0.3 mg')), isTrue);
    });

    test('DEC-PND-005 specifically covers Salbutamol pediatric criteria', () {
      final dec = PendingPharmacistRegistry.findById('DEC-PND-005')!;
      expect(dec.affectedDrugIds, contains('salbutamol'));
      expect(dec.category, equals(PendingDecisionCategory.respiratoryAllergy));
      expect(dec.targetFile, equals('lib/data/drugs/respiratory.dart'));
      expect(dec.candidateOptions.any((o) => o.citation.contains('GINA')), isTrue);
      expect(dec.candidateOptions.any((o) => o.titleEn.contains('20.0')), isTrue);
    });

    test('DEC-PND-006 specifically covers Hartford nomogram & Vancomycin Vd', () {
      final dec = PendingPharmacistRegistry.findById('DEC-PND-006')!;
      expect(dec.affectedDrugIds, containsAll(['gentamicin', 'vancomycin']));
      expect(dec.category, equals(PendingDecisionCategory.pharmacokineticsTdm));
      expect(dec.targetFile, equals('lib/core/calculators/tdm_calculator.dart'));
      expect(dec.candidateOptions.any((o) => o.citation.contains('Nicolau')), isTrue);
      expect(dec.candidateOptions.any((o) => o.citation.contains('Blouin')), isTrue);
    });
  });

  group('PendingPharmacistRegistry Query Helpers', () {
    test('findById matches case-insensitively and returns null for unknowns', () {
      expect(PendingPharmacistRegistry.findById('DEC-PND-001'), isNotNull);
      expect(PendingPharmacistRegistry.findById('dec-pnd-001'), isNotNull);
      expect(PendingPharmacistRegistry.findById('DEC-PND-006'), isNotNull);
      expect(PendingPharmacistRegistry.findById('DEC-PND-999'), isNull);
    });

    test('getByCategory correctly filters by clinical specialty', () {
      final antimicrobial = PendingPharmacistRegistry.getByCategory(
          PendingDecisionCategory.antimicrobialStewardship);
      expect(antimicrobial.map((d) => d.id), contains('DEC-PND-001'));

      final emergency = PendingPharmacistRegistry.getByCategory(
          PendingDecisionCategory.emergencyResuscitation);
      expect(emergency.map((d) => d.id), containsAll(['DEC-PND-002', 'DEC-PND-004']));

      final respiratory = PendingPharmacistRegistry.getByCategory(
          PendingDecisionCategory.respiratoryAllergy);
      expect(respiratory.map((d) => d.id), containsAll(['DEC-PND-003', 'DEC-PND-005']));

      final tdm = PendingPharmacistRegistry.getByCategory(
          PendingDecisionCategory.pharmacokineticsTdm);
      expect(tdm.map((d) => d.id), contains('DEC-PND-006'));
    });

    test('getByDrugId matches affected drugs regardless of case', () {
      expect(PendingPharmacistRegistry.getByDrugId('acyclovir').length, equals(1));
      expect(PendingPharmacistRegistry.getByDrugId('ACYCLOVIR').length, equals(1));
      expect(PendingPharmacistRegistry.getByDrugId('atropine').length, equals(1));
      expect(PendingPharmacistRegistry.getByDrugId('dexamethasone').length, equals(1));
      expect(PendingPharmacistRegistry.getByDrugId('epinephrine').length, equals(1));
      expect(PendingPharmacistRegistry.getByDrugId('salbutamol').length, equals(1));
      expect(PendingPharmacistRegistry.getByDrugId('gentamicin').length, equals(1));
      expect(PendingPharmacistRegistry.getByDrugId('vancomycin').length, equals(1));
      expect(PendingPharmacistRegistry.getByDrugId('non_existent_drug').isEmpty, isTrue);
    });
  });

  group('Active Baseline Calculation Invariance (Zero Math Alteration)', () {
    test('Acyclovir IV baseline calculation remains intact', () {
      final acyclovir = DrugDatabase.findById('acyclovir')!;
      final hsvRegimen = acyclovir.regimens.firstWhere(
        (r) => r.indication?.contains('Encephalitis') == true,
      );

      // Standard adult 70 kg: 10 mg/kg * 70 kg = 700 mg (under 800 mg ceiling)
      const adult70 = Patient(
        id: 'pt-70',
        ageYears: 35,
        weightKg: 70.0,
        heightCm: 175.0,
        sex: Sex.male,
        isScrStable: true,
      );
      final res70 = PharmacistCalculator.calculateDose(
        patient: adult70,
        drug: acyclovir,
        regimen: hsvRegimen,
      );
      expect(res70.calculatedDose, equals(700.0));
      expect(res70.isBlocked, isFalse);
      expect(res70.warnings.any((w) => w.code == DoseWarningCode.maxSingleDoseExceeded), isFalse);

      // Heavy adult 90 kg: 10 mg/kg * 90 kg = 900 mg (triggers maxSingleDoseExceeded warning)
      const adult90 = Patient(
        id: 'pt-90',
        ageYears: 35,
        weightKg: 90.0,
        heightCm: 175.0,
        sex: Sex.male,
        isScrStable: true,
      );
      final res90 = PharmacistCalculator.calculateDose(
        patient: adult90,
        drug: acyclovir,
        regimen: hsvRegimen,
      );
      expect(res90.calculatedDose, equals(900.0));
      expect(res90.warnings.any((w) => w.code == DoseWarningCode.maxSingleDoseExceeded), isTrue);
    });

    test('Atropine pediatric bradycardia baseline calculation remains intact', () {
      final atropine = DrugDatabase.findById('atropine')!;
      final bradyRegimen = atropine.regimens.firstWhere(
        (r) => r.indication?.contains('Bradycardia (Pediatric)') == true,
      );

      // 10 kg toddler: 0.02 * 10 = 0.20 mg
      const child10 = Patient(
        id: 'pt-ped-10',
        ageYears: 1,
        weightKg: 10.0,
        heightCm: 75.0,
        sex: Sex.female,
        isScrStable: true,
      );
      final res10 = PharmacistCalculator.calculateDose(
        patient: child10,
        drug: atropine,
        regimen: bradyRegimen,
      );
      expect(res10.calculatedDose, closeTo(0.20, 1e-6));
      expect(res10.isBlocked, isFalse);
      expect(res10.warnings.any((w) => w.code == DoseWarningCode.maxSingleDoseExceeded), isFalse);

      // 30 kg child: 0.02 * 30 = 0.60 mg (> 0.5 mg limit -> triggers maxSingleDoseExceeded)
      const child30 = Patient(
        id: 'pt-ped-30',
        ageYears: 8,
        weightKg: 30.0,
        heightCm: 130.0,
        sex: Sex.male,
        isScrStable: true,
      );
      final res30 = PharmacistCalculator.calculateDose(
        patient: child30,
        drug: atropine,
        regimen: bradyRegimen,
      );
      expect(res30.calculatedDose, closeTo(0.60, 1e-6));
      expect(res30.warnings.any((w) => w.code == DoseWarningCode.maxSingleDoseExceeded), isTrue);
    });

    test('Dexamethasone croup baseline calculation remains intact', () {
      final dexa = DrugDatabase.findById('dexamethasone')!;
      final croupRegimen = dexa.regimens.firstWhere(
        (r) => r.indication?.contains('Croup') == true,
      );

      // 10 kg child: 0.6 * 10 = 6.0 mg
      const child10 = Patient(
        id: 'pt-croup-10',
        ageYears: 1,
        weightKg: 10.0,
        heightCm: 75.0,
        sex: Sex.male,
        isScrStable: true,
      );
      final res10 = PharmacistCalculator.calculateDose(
        patient: child10,
        drug: dexa,
        regimen: croupRegimen,
      );
      expect(res10.calculatedDose, closeTo(6.0, 1e-6));
      expect(res10.warnings.any((w) => w.code == DoseWarningCode.maxSingleDoseExceeded), isFalse);

      // 20 kg child: 0.6 * 20 = 12.0 mg (> 10 mg limit -> triggers maxSingleDoseExceeded)
      const child20 = Patient(
        id: 'pt-croup-20',
        ageYears: 5,
        weightKg: 20.0,
        heightCm: 110.0,
        sex: Sex.male,
        isScrStable: true,
      );
      final res20 = PharmacistCalculator.calculateDose(
        patient: child20,
        drug: dexa,
        regimen: croupRegimen,
      );
      expect(res20.calculatedDose, closeTo(12.0, 1e-6));
      expect(res20.warnings.any((w) => w.code == DoseWarningCode.maxSingleDoseExceeded), isTrue);
    });

    test('Epinephrine pediatric anaphylaxis baseline calculation remains intact', () {
      final epi = DrugDatabase.findById('epinephrine')!;
      final anaRegimen = epi.regimens.firstWhere(
        (r) => r.indication?.contains('Anaphylaxis (Pediatric)') == true,
      );

      // 15 kg child: 0.01 * 15 = 0.15 mg
      const child15 = Patient(
        id: 'pt-ana-15',
        ageYears: 3,
        weightKg: 15.0,
        heightCm: 95.0,
        sex: Sex.female,
        isScrStable: true,
      );
      final res15 = PharmacistCalculator.calculateDose(
        patient: child15,
        drug: epi,
        regimen: anaRegimen,
      );
      expect(res15.calculatedDose, closeTo(0.15, 1e-6));
      expect(res15.warnings.any((w) => w.code == DoseWarningCode.maxSingleDoseExceeded), isFalse);

      // 35 kg child: 0.01 * 35 = 0.35 mg (> 0.3 mg limit -> triggers maxSingleDoseExceeded)
      const child35 = Patient(
        id: 'pt-ana-35',
        ageYears: 10,
        weightKg: 35.0,
        heightCm: 140.0,
        sex: Sex.male,
        isScrStable: true,
      );
      final res35 = PharmacistCalculator.calculateDose(
        patient: child35,
        drug: epi,
        regimen: anaRegimen,
      );
      expect(res35.calculatedDose, closeTo(0.35, 1e-6));
      expect(res35.warnings.any((w) => w.code == DoseWarningCode.maxSingleDoseExceeded), isTrue);
    });

    test('Salbutamol pediatric nebulizer baseline calculation remains intact', () {
      final sal = DrugDatabase.findById('salbutamol')!;
      final nebRegimen = sal.regimens.firstWhere(
        (r) => r.indication?.contains('Pediatric < 20kg') == true,
      );

      // 10 kg child: 0.15 * 10 = 1.50 mg
      const child10 = Patient(
        id: 'pt-sal-10',
        ageYears: 1,
        weightKg: 10.0,
        heightCm: 75.0,
        sex: Sex.female,
        isScrStable: true,
      );
      final res10 = PharmacistCalculator.calculateDose(
        patient: child10,
        drug: sal,
        regimen: nebRegimen,
      );
      expect(res10.calculatedDose, closeTo(1.50, 1e-6));
      expect(res10.warnings.any((w) => w.code == DoseWarningCode.maxSingleDoseExceeded), isFalse);

      // 25 kg child: 0.15 * 25 = 3.75 mg (> 2.5 mg limit -> triggers maxSingleDoseExceeded)
      const child25 = Patient(
        id: 'pt-sal-25',
        ageYears: 7,
        weightKg: 25.0,
        heightCm: 120.0,
        sex: Sex.male,
        isScrStable: true,
      );
      final res25 = PharmacistCalculator.calculateDose(
        patient: child25,
        drug: sal,
        regimen: nebRegimen,
      );
      expect(res25.calculatedDose, closeTo(3.75, 1e-6));
      expect(res25.warnings.any((w) => w.code == DoseWarningCode.maxSingleDoseExceeded), isTrue);
    });

    test('Hartford nomogram & Vancomycin Vd math remains 100% identical to baseline', () {
      // Vancomycin Vd models
      expect(
        TdmCalculator.calculateVdWithModel(
          weightKg: 100.0,
          model: VancomycinVdModel.standardAdult,
        ),
        closeTo(70.0, 1e-6),
      );
      expect(
        TdmCalculator.calculateVdWithModel(
          weightKg: 100.0,
          model: VancomycinVdModel.obesity,
        ),
        closeTo(52.0, 1e-6),
      );
      expect(
        TdmCalculator.calculateVdWithModel(
          weightKg: 100.0,
          model: VancomycinVdModel.criticallyIllIcu,
        ),
        closeTo(85.0, 1e-6),
      );

      // Hartford nomogram zones at 10 hours post-dose
      final z24 = TdmCalculator.evaluateHartfordNomogram(
        randomLevelMgL: 4.0,
        hoursPostDose: 10.0,
      );
      expect(z24.zone, equals(HartfordNomogramZone.q24h));
      expect(z24.recommendedIntervalHours, equals(24));

      final z36 = TdmCalculator.evaluateHartfordNomogram(
        randomLevelMgL: 6.5,
        hoursPostDose: 10.0,
      );
      expect(z36.zone, equals(HartfordNomogramZone.q36h));
      expect(z36.recommendedIntervalHours, equals(36));

      final zHold = TdmCalculator.evaluateHartfordNomogram(
        randomLevelMgL: 11.5,
        hoursPostDose: 10.0,
      );
      expect(zHold.zone, equals(HartfordNomogramZone.aboveQ48hHoldAndMonitor));
      expect(zHold.recommendedIntervalHours, isNull);
    });
  });

  group('Checklist Markdown Document Verification', () {
    test('review/Pending_Pharmacist_Signoff_Checklist.md exists and covers all 6 decisions', () {
      final file = File('review/Pending_Pharmacist_Signoff_Checklist.md');
      expect(file.existsSync(), isTrue,
          reason: 'Checklist file must exist in review/');

      final content = file.readAsStringSync();
      expect(content.length, greaterThan(2000));

      for (int i = 1; i <= 6; i++) {
        final code = 'DEC-PND-00$i';
        expect(content.contains(code), isTrue,
            reason: 'Checklist must contain $code');
      }

      // Must have options and signature blocks
      expect(content.contains('Option A'), isTrue);
      expect(content.contains('Option B'), isTrue);
      expect(content.contains('Option C'), isTrue);
      expect(content.contains('ภ.'), isTrue, reason: 'Must contain pharmacist license block');
      expect(content.contains('ว.'), isTrue, reason: 'Must contain physician license block');
    });
  });
}
