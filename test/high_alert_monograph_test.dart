// ============================================================================
// High-Alert Medications Monograph & Honest Provenance Test Suite
// ============================================================================
// Verifies:
// 1. All 14 core hospital High-Alert medications have complete ClinicalMonograph
//    (textbookName, editionYear, dosingGuideline, administrationGuideline, clinicalNotes)
//    and Provenance records.
// 2. SchemaValidator validation of the verified knowledge base passes with zero errors.
// 3. Honest provenance audit: reviewedBy indicates pending clinical pharmacist sign-off,
//    and reviewerLicense is strictly null before actual human sign-off.
// 4. Regimens have VerificationStatus.pendingReview while pre-existing verified
//    clinical rules (apixaban_2_of_3_criteria) remain VerificationStatus.verified.
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:drug_dosage_calculator/data/knowledge_base_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const highAlertIds = [
    'warfarin',
    'heparin',
    'enoxaparin',
    'apixaban',
    'rivaroxaban',
    'norepinephrine',
    'epinephrine',
    'dopamine',
    'dobutamine',
    'nicardipine',
    'amiodarone',
    'insulin_regular',
    'magnesium_sulfate',
    'oxytocin',
  ];

  group('High-Alert Medications Monograph & Provenance Verification', () {
    test('All 14 core hospital High-Alert drugs exist in DrugDatabase', () {
      expect(highAlertIds.length, equals(14));
      for (final id in highAlertIds) {
        final drug = DrugDatabase.findById(id);
        expect(drug, isNotNull, reason: 'High-Alert drug "$id" must exist in DrugDatabase');
        expect(drug!.isHighAlert, isTrue, reason: '$id must have isHighAlert == true');
      }
    });

    test('Every High-Alert drug has complete ClinicalMonograph with all required fields', () {
      for (final id in highAlertIds) {
        final drug = DrugDatabase.findById(id)!;
        final mono = drug.monograph;

        expect(mono, isNotNull, reason: 'Drug "$id" must have a non-null ClinicalMonograph');
        expect(mono!.textbookName.trim().isNotEmpty, isTrue,
            reason: '$id monograph must specify textbookName');
        expect(mono.editionYear.trim().isNotEmpty, isTrue,
            reason: '$id monograph must specify editionYear');
        expect(mono.dosingGuideline.trim().isNotEmpty, isTrue,
            reason: '$id monograph must specify dosingGuideline');
        expect(mono.administrationGuideline, isNotNull,
            reason: '$id monograph must have non-null administrationGuideline');
        expect(mono.administrationGuideline!.trim().isNotEmpty, isTrue,
            reason: '$id monograph must have non-empty administrationGuideline');
        expect(mono.clinicalNotes, isNotNull,
            reason: '$id monograph must have non-null clinicalNotes');
        expect(mono.clinicalNotes!.trim().isNotEmpty, isTrue,
            reason: '$id monograph must have non-empty clinicalNotes');
      }
    });

    test('Every High-Alert drug has honest Provenance with pending reviewer sign-off', () {
      for (final id in highAlertIds) {
        final drug = DrugDatabase.findById(id)!;
        final prov = drug.provenance;

        expect(prov, isNotNull, reason: 'Drug "$id" must have a non-null Provenance');
        expect(prov!.source.trim().isNotEmpty, isTrue,
            reason: '$id provenance must have non-empty source');

        // Honest review status: must indicate pending clinical pharmacist review
        expect(
          prov.reviewedBy.toLowerCase().contains('pending') ||
              prov.reviewedBy.contains('เภสัชกร') ||
              prov.reviewedBy == 'Pending Clinical Pharmacist Sign-off',
          isTrue,
          reason: '$id reviewedBy must reflect pending pharmacist sign-off, got "${prov.reviewedBy}"',
        );

        // Strict audit honesty: reviewerLicense must be null before human sign-off
        expect(
          prov.reviewerLicense,
          isNull,
          reason: '$id reviewerLicense must be null before human pharmacist sign-off (Zero Hallucination)',
        );
      }
    });

    test('Regimens have VerificationStatus.pendingReview while apixaban_2_of_3_criteria remains verified', () {
      for (final id in highAlertIds) {
        final drug = DrugDatabase.findById(id)!;
        expect(drug.regimens, isNotEmpty, reason: '$id must have regimens');

        for (final reg in drug.regimens) {
          expect(
            reg.verificationStatus,
            equals(VerificationStatus.pendingReview),
            reason: 'Regimen "${reg.indication}" for "$id" must be marked VerificationStatus.pendingReview',
          );
        }
      }

      // Assert that pre-existing verified rule apixaban_2_of_3_criteria strictly remains verified
      final apixaban = DrugDatabase.findById('apixaban')!;
      final apixabanRule = apixaban.doseRules.firstWhere(
        (r) => r.id == 'apixaban_2_of_3_criteria',
        orElse: () => throw TestFailure('apixaban_2_of_3_criteria rule not found on apixaban'),
      );
      expect(
        apixabanRule.verificationStatus,
        equals(VerificationStatus.verified),
        reason: 'apixaban_2_of_3_criteria must strictly preserve VerificationStatus.verified',
      );
    });

    test('KnowledgeBase validates against SchemaValidator without errors', () async {
      final kb = await KnowledgeBaseLoader.loadFromFile('assets/data/drug_knowledge_base.json');
      final report = SchemaValidator.validateKnowledgeBase(kb);

      expect(
        report.errors,
        isEmpty,
        reason: 'SchemaValidator found errors in knowledge base: ${report.errors.join(", ")}',
      );
      expect(report.isValid, isTrue);
    });

    test('High-Alert drugs have valid clinical classification and safety metadata', () {
      for (final id in highAlertIds) {
        final drug = DrugDatabase.findById(id)!;
        expect(drug.genericName.isNotEmpty, isTrue);
        expect(drug.nameTh, isNotNull);
        expect(drug.nameTh!.isNotEmpty, isTrue);
        expect(drug.sourceCitation.isNotEmpty, isTrue);

        // Anticoagulants must have TDM or renal adjustment flags
        if (id == 'warfarin' || id == 'heparin') {
          expect(drug.requiresTDM, isTrue, reason: '$id requires INR/aPTT monitoring');
        }
        if (id == 'enoxaparin' || id == 'apixaban' || id == 'rivaroxaban') {
          expect(drug.requiresRenalAdjustment, isTrue, reason: '$id requires renal dose adjustment');
        }

        // Vasopressors & Resuscitation medications must have route and administration guidance
        if (id == 'norepinephrine' || id == 'epinephrine' || id == 'dopamine' || id == 'dobutamine') {
          final adminText = '${drug.monograph!.dosingGuideline} ${drug.monograph!.administrationGuideline} ${drug.monograph!.clinicalNotes}'.toLowerCase();
          final hasGuidance = adminText.contains('infusion') ||
              adminText.contains('ฉีด') ||
              adminText.contains('iv') ||
              adminText.contains('im') ||
              adminText.contains('central line');
          expect(hasGuidance, isTrue, reason: '$id must contain route/administration guidance');
        }
      }
    });
  });
}
