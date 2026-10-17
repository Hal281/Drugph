import 'package:drug_dosage_calculator/core/models/verified_drug_schema.dart';
import 'package:drug_dosage_calculator/core/validators/schema_validator.dart';
import 'package:drug_dosage_calculator/data/knowledge_base_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 1 — Verified Drug Knowledge Base Schema Validation', () {
    late VerifiedDrugKnowledgeBase kb;

    setUpAll(() async {
      kb = await KnowledgeBaseLoader.loadFromFile(
        'assets/data/drug_knowledge_base.json',
      );
    });

    test('drug_knowledge_base.json loads and passes SchemaValidator 100%', () {
      final report = SchemaValidator.validateKnowledgeBase(kb);
      expect(
        report.errors,
        isEmpty,
        reason: 'Expected 0 schema errors, got: ${report.errors}',
      );
      expect(report.isValid, isTrue);
      expect(kb.drugs.length, greaterThanOrEqualTo(3));
    });

    test(
      'All 3 prototype drugs (Paracetamol, Amoxicillin, Ibuprofen) are present and complete',
      () {
        final paracetamol = kb.findDrug('paracetamol_oral_susp');
        final amoxicillin = kb.findDrug('amoxicillin_oral_susp');
        final ibuprofen = kb.findDrug('ibuprofen_oral_susp');

        expect(paracetamol, isNotNull);
        expect(amoxicillin, isNotNull);
        expect(ibuprofen, isNotNull);

        for (final drug in [paracetamol!, amoxicillin!, ibuprofen!]) {
          expect(drug.drugInfo.rxnormId, isNotEmpty);
          expect(drug.drugInfo.concentrationMgPerMl, greaterThan(0));
          expect(drug.dosingRules.nonBlockingOverdosePolicy, isTrue);
          expect(drug.safetyChecks.allergyCrossReactivity, isNotEmpty);
          expect(drug.safetyChecks.drugInteractions, isNotEmpty);
          expect(drug.verificationMetadata.sourceName, isNotEmpty);
          expect(drug.verificationMetadata.editionAndPage, isNotEmpty);
          expect(
            drug.verificationMetadata.evidenceImagePath,
            startsWith('assets/evidence/'),
          );
          // All entries start as source_verified: false until human sign-off
          expect(drug.verificationMetadata.sourceVerified, isFalse);
          expect(drug.verificationMetadata.isFullyVerified, isFalse);
        }
      },
    );

    test(
      'Bug 1 & Bug 8 Fix: SchemaValidator rejects source_verified=true without verified_by & verified_date, and rejects mismatched canonical RxNorm IDs',
      () {
        // 1. Claiming source_verified=true without verified_by / verified_date must fail
        final rawMap = kb.drugs.first.toJson();
        final metaMap = Map<String, dynamic>.from(
          rawMap['verification_metadata'] as Map<String, dynamic>,
        );
        metaMap['source_verified'] = true;
        metaMap['verified_by'] = null;
        metaMap['verified_date'] = null;
        rawMap['verification_metadata'] = metaMap;

        final unsignedVerifiedEntry = VerifiedDrugEntry.fromJson(rawMap);
        expect(
          unsignedVerifiedEntry.verificationMetadata.isFullyVerified,
          isFalse,
        );
        final unsignedErrors = SchemaValidator.validateDrugEntry(
          unsignedVerifiedEntry,
        );
        expect(
          unsignedErrors.any((e) => e.contains('without complete human sign-off')),
          isTrue,
        );

        // 2. Providing both verified_by and YYYY-MM-DD verified_date passes
        metaMap['verified_by'] = 'ภก. สมชาย ใจดี (ภ.12345)';
        metaMap['verified_date'] = '2026-10-17';
        rawMap['verification_metadata'] = metaMap;
        final signedEntry = VerifiedDrugEntry.fromJson(rawMap);
        expect(signedEntry.verificationMetadata.isFullyVerified, isTrue);
        expect(SchemaValidator.validateDrugEntry(signedEntry), isEmpty);

        // 3. Mismatched RxCUI (e.g. putting "999999" on Paracetamol instead of "161") is rejected
        final badRxcuiMap = kb.drugs.first.toJson();
        final infoMap = Map<String, dynamic>.from(
          badRxcuiMap['drug_info'] as Map<String, dynamic>,
        );
        infoMap['rxnorm_id'] = '999999';
        badRxcuiMap['drug_info'] = infoMap;
        final badRxcuiEntry = VerifiedDrugEntry.fromJson(badRxcuiMap);
        final rxcuiErrors = SchemaValidator.validateDrugEntry(badRxcuiEntry);
        expect(
          rxcuiErrors.any((e) => e.contains('canonical NLM RxCUI')),
          isTrue,
        );
      },
    );

    test(
      'Bug 8 Fix: VerifiedDrugKnowledgeBase.findDrug uses exact match on ID/RxCUI/Name/Synonyms and never matches partial substrings',
      () {
        expect(kb.findDrug('paracetamol_oral_susp'), isNotNull);
        expect(kb.findDrug('161'), isNotNull);
        expect(kb.findDrug('Paracetamol'), isNotNull);
        expect(kb.findDrug('พาราเซตามอล'), isNotNull);
        expect(kb.findDrug('Brufen'), isNotNull);

        // Partial substrings must NOT match (prevents LASA drug mix-ups)
        expect(kb.findDrug('para'), isNull);
        expect(kb.findDrug('amox'), isNull);
        expect(kb.findDrug('in'), isNull);
        expect(kb.findDrug('a'), isNull);
      },
    );

    test(
      'Fix #1: Renal adjustment uses contiguous bounds (crcl >= min && crcl < max) with zero decimal gaps',
      () {
        final paracetamol = kb.findDrug('paracetamol_oral_susp')!;
        final amoxicillin = kb.findDrug('amoxicillin_oral_susp')!;
        final ibuprofen = kb.findDrug('ibuprofen_oral_susp')!;

        // Paracetamol: [0.0, 10.0), [10.0, 50.0), [50.0, 999.0)
        expect(
          paracetamol.dosingRules
              .findRenalAdjustmentForCrCl(9.95)
              ?.adjustedInterval,
          equals('q8h'),
        );
        expect(
          paracetamol.dosingRules
              .findRenalAdjustmentForCrCl(10.0)
              ?.adjustedInterval,
          equals('q6h'),
        );
        expect(
          paracetamol.dosingRules
              .findRenalAdjustmentForCrCl(49.95)
              ?.adjustedInterval,
          equals('q6h'),
        );
        expect(
          paracetamol.dosingRules
              .findRenalAdjustmentForCrCl(50.0)
              ?.adjustedInterval,
          equals('q4-6h'),
        );

        // Amoxicillin: [0.0, 10.0), [10.0, 30.0), [30.0, 999.0)
        expect(
          amoxicillin.dosingRules
              .findRenalAdjustmentForCrCl(9.95)
              ?.adjustedInterval,
          equals('q24h'),
        );
        expect(
          amoxicillin.dosingRules
              .findRenalAdjustmentForCrCl(10.0)
              ?.adjustedInterval,
          equals('q12h'),
        );
        expect(
          amoxicillin.dosingRules
              .findRenalAdjustmentForCrCl(29.95)
              ?.adjustedInterval,
          equals('q12h'),
        );
        expect(
          amoxicillin.dosingRules
              .findRenalAdjustmentForCrCl(30.0)
              ?.adjustedInterval,
          equals('q8h'),
        );

        // Ibuprofen: [0.0, 30.0), [30.0, 60.0), [60.0, 999.0)
        expect(
          ibuprofen.dosingRules
              .findRenalAdjustmentForCrCl(29.95)
              ?.isContraindicated,
          isTrue,
        );
        expect(
          ibuprofen.dosingRules
              .findRenalAdjustmentForCrCl(29.95)
              ?.doseAdjustmentFactor,
          equals(1.0),
        );
        expect(
          ibuprofen.dosingRules
              .findRenalAdjustmentForCrCl(30.0)
              ?.doseAdjustmentFactor,
          equals(0.5),
        );
        expect(
          ibuprofen.dosingRules
              .findRenalAdjustmentForCrCl(59.95)
              ?.doseAdjustmentFactor,
          equals(0.5),
        );
        expect(
          ibuprofen.dosingRules
              .findRenalAdjustmentForCrCl(60.0)
              ?.doseAdjustmentFactor,
          equals(1.0),
        );
      },
    );

    test(
      'SchemaValidator rejects renal_adjustment tiers that contain a decimal gap (e.g. 9.9 to 10.0)',
      () {
        final rawMap = kb.drugs.first.toJson();
        final dosingMap = Map<String, dynamic>.from(
          rawMap['dosing_rules'] as Map<String, dynamic>,
        );
        dosingMap['renal_adjustment'] = [
          {
            'crcl_min_ml_min': 0.0,
            'crcl_max_ml_min': 9.9,
            'adjusted_interval': 'q8h',
            'dose_adjustment_factor': 1.0,
            'clinical_note': 'Bad gap tier',
          },
          {
            'crcl_min_ml_min': 10.0,
            'crcl_max_ml_min': 999.0,
            'adjusted_interval': 'q4-6h',
            'dose_adjustment_factor': 1.0,
            'clinical_note': 'Upper tier',
          },
        ];
        rawMap['dosing_rules'] = dosingMap;

        final flawedEntry = VerifiedDrugEntry.fromJson(rawMap);
        final errors = SchemaValidator.validateDrugEntry(flawedEntry);
        expect(
          errors.any((e) => e.contains('decimal gap or overlap detected')),
          isTrue,
        );
      },
    );

    test(
      'Fix #2: reference_url uses valid DailyMed search query URLs and rejects fake setid=161 links',
      () {
        for (final drug in kb.drugs) {
          final url = drug.verificationMetadata.referenceUrl;
          expect(
            url,
            startsWith(
              'https://dailymed.nlm.nih.gov/dailymed/search.cfm?labeltype=all&query=',
            ),
          );
          expect(url.contains('setid='), isFalse);
        }

        // Verify validator catches fake setid=161
        final rawMap = kb.drugs.first.toJson();
        final metaMap = Map<String, dynamic>.from(
          rawMap['verification_metadata'] as Map<String, dynamic>,
        );
        metaMap['reference_url'] =
            'https://dailymed.nlm.nih.gov/dailymed/drugInfo.cfm?setid=161';
        rawMap['verification_metadata'] = metaMap;

        final flawedEntry = VerifiedDrugEntry.fromJson(rawMap);
        final errors = SchemaValidator.validateDrugEntry(flawedEntry);
        expect(
          errors.any((e) => e.contains('invalid non-UUID DailyMed setid')),
          isTrue,
        );
      },
    );

    testWidgets(
      'Fix #3: Missing .png in assets/evidence/ gracefully renders SimulatedTextbookEvidenceCard via errorBuilder without crashing',
      (WidgetTester tester) async {
        final paracetamol = kb.findDrug('paracetamol_oral_susp')!;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: KnowledgeBaseLoader.buildEvidenceImageWithFallback(
                metadata: paracetamol.verificationMetadata,
                genericName: paracetamol.drugInfo.genericName,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const Key('simulated_textbook_evidence_card')),
          findsOneWidget,
        );
        expect(
          find.textContaining('The Harriet Lane Handbook'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Page 912-913'),
          findsOneWidget,
        );
      },
    );
  });
}
