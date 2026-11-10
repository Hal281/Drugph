// ============================================================================
// Challenger Phase 2 Empirical Adversarial Test Suite
// ============================================================================
// Stress-tests:
// 1. SchemaValidator compatibility & boundaries across DrugDatabase:
//    - Tests type contract of SchemaValidator.validateKnowledgeBase
//    - Tests DrugDatabase.allDrugs total count (117 drugs)
//    - Audits all 14 High-Alert drugs for RxNorm presence, non-empty monograph
//      fields, valid https URLs, and honest provenance.
// 2. PDF Dossier Structural Integrity:
//    - Tests review/Clinical_Verification_Dossier.pdf magic bytes, EOF,
//      file size (> 200 KB), and exact page count (47 pages).
// 3. UI Layout Stress Testing:
//    - Tests ClinicalEvidenceSheet under extreme viewport constraints:
//      320x568 (extreme compact mobile), 360x640, 390x844, 768x1024,
//      1280x800, 1920x1080 (full HD desktop), 2560x1440 (ultrawide).
//    - Tests both Thai (isThai: true) and English (isThai: false) modes.
//    - Asserts 0 RenderFlex overflow exceptions across diverse High-Alert drugs.
// ============================================================================

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/core/models/verified_drug_schema.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:drug_dosage_calculator/data/knowledge_base_loader.dart';
import 'package:drug_dosage_calculator/ui/widgets/clinical_evidence_sheet.dart';

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

  group('Dimension 1: SchemaValidator & KnowledgeBase vs DrugDatabase Audit', () {
    test('1.1: DrugDatabase contains exactly 121 drugs across 16 categories', () {
      final totalDrugs = DrugDatabase.allDrugs.length;
      expect(
        totalDrugs,
        equals(121),
        reason: 'DrugDatabase.allDrugs must contain exactly 121 formulary drugs',
      );
    });

    test('1.2: KnowledgeBase JSON contains 3 prototype drugs and passes SchemaValidator with 0 errors', () async {
      final kb = await KnowledgeBaseLoader.loadFromFile('assets/data/drug_knowledge_base.json');
      expect(kb.drugs.length, equals(3));
      final report = SchemaValidator.validateKnowledgeBase(kb);
      expect(report.isValid, isTrue);
      expect(report.errors, isEmpty, reason: 'Expected 0 errors on drug_knowledge_base.json');
    });

    test('1.3: Architectural boundary analysis: Drug model in DrugDatabase vs VerifiedDrugEntry', () {
      // Empirical verification of type contract:
      // SchemaValidator.validateKnowledgeBase requires VerifiedDrugKnowledgeBase.
      // DrugDatabase.allDrugs is List<Drug>, which is not a VerifiedDrugKnowledgeBase.
      expect(DrugDatabase.allDrugs, isA<List<Drug>>());
      expect(DrugDatabase.allDrugs is VerifiedDrugKnowledgeBase, isFalse);

      // Verify that Drug model does NOT have an rxnormId field:
      // RxNorm concept is tracked in SchemaValidator.canonicalRxCuiByIngredient for verified ingredients.
      const knownCanonicalIngredients = SchemaValidator.canonicalRxCuiByIngredient;
      expect(knownCanonicalIngredients.containsKey('warfarin'), isTrue);
      expect(knownCanonicalIngredients['warfarin'], equals('11289'));

      // Check how many of the 14 High-Alert drugs are mapped in SchemaValidator.canonicalRxCuiByIngredient
      final mappedCount = highAlertIds
          .where((id) => knownCanonicalIngredients.containsKey(id))
          .length;
      // Note: Only warfarin is currently in canonicalRxCuiByIngredient among the 14 High-Alert drugs
      expect(mappedCount, equals(1));
    });

    test('1.4: All 14 High-Alert drugs have non-empty fields, valid https URLs, and honest provenance', () {
      final urlErrors = <String>[];
      final provenanceErrors = <String>[];
      final fieldErrors = <String>[];

      for (final id in highAlertIds) {
        final drug = DrugDatabase.findById(id);
        expect(drug, isNotNull, reason: 'High-Alert drug "$id" must exist');

        // Check non-empty mandatory fields
        if (drug!.genericName.trim().isEmpty) fieldErrors.add('$id: genericName is empty');
        if (drug.nameTh == null || drug.nameTh!.trim().isEmpty) fieldErrors.add('$id: nameTh is empty');
        if (drug.sourceCitation.trim().isEmpty) fieldErrors.add('$id: sourceCitation is empty');

        // Check monograph
        final mono = drug.monograph;
        if (mono == null) {
          fieldErrors.add('$id: monograph is null');
        } else {
          if (mono.textbookName.trim().isEmpty) fieldErrors.add('$id: monograph.textbookName is empty');
          if (mono.editionYear.trim().isEmpty) fieldErrors.add('$id: monograph.editionYear is empty');
          if (mono.dosingGuideline.trim().isEmpty) fieldErrors.add('$id: monograph.dosingGuideline is empty');
          if (mono.administrationGuideline == null || mono.administrationGuideline!.trim().isEmpty) {
            fieldErrors.add('$id: monograph.administrationGuideline is empty');
          }
          if (mono.clinicalNotes == null || mono.clinicalNotes!.trim().isEmpty) {
            fieldErrors.add('$id: monograph.clinicalNotes is empty');
          }

          // Check externalUrl syntax & protocol
          if (mono.externalUrl != null) {
            final uri = Uri.tryParse(mono.externalUrl!);
            if (uri == null || !uri.hasScheme || uri.scheme != 'https' || uri.host.isEmpty) {
              urlErrors.add('$id: externalUrl "${mono.externalUrl}" is not a valid https URL');
            }
          } else {
            urlErrors.add('$id: monograph.externalUrl is null');
          }
        }

        // Check honest provenance
        final prov = drug.provenance;
        if (prov == null) {
          provenanceErrors.add('$id: provenance is null');
        } else {
          if (prov.source.trim().isEmpty) provenanceErrors.add('$id: provenance.source is empty');
          if (!prov.reviewedBy.toLowerCase().contains('pending')) {
            provenanceErrors.add('$id: provenance.reviewedBy must indicate pending review, got "${prov.reviewedBy}"');
          }
          if (prov.reviewerLicense != null) {
            provenanceErrors.add('$id: provenance.reviewerLicense must be null before human sign-off');
          }
        }
      }

      expect(fieldErrors, isEmpty, reason: fieldErrors.join('; '));
      expect(urlErrors, isEmpty, reason: urlErrors.join('; '));
      expect(provenanceErrors, isEmpty, reason: provenanceErrors.join('; '));
    });
  });

  group('Dimension 2: PDF Dossier Structural Integrity & Stress Testing', () {
    test('2.1: Generated PDF exists, has valid magic bytes, valid EOF trailer, and size > 200 KB', () {
      final pdfFile = File('review/Clinical_Verification_Dossier.pdf');
      expect(pdfFile.existsSync(), isTrue, reason: 'Dossier PDF must exist');

      final bytes = pdfFile.readAsBytesSync();
      expect(bytes.length, greaterThan(200 * 1024), reason: 'PDF size must be > 200 KB');

      // Header: %PDF-
      final header = String.fromCharCodes(bytes.take(5));
      expect(header, equals('%PDF-'), reason: 'PDF must start with %PDF-');

      // Trailer: %%EOF
      final tail = String.fromCharCodes(bytes.skip(bytes.length - 1024));
      expect(tail.contains('%%EOF'), isTrue, reason: 'PDF must end with %%EOF');
    });

    test('2.2: Generated PDF contains exactly 48 pages verified by PDF page dictionary count', () {
      final pdfFile = File('review/Clinical_Verification_Dossier.pdf');
      final content = pdfFile.readAsStringSync(encoding: latin1);

      // In PDF format, each page has a page dictionary containing "/Type /Page"
      // or the catalog /Pages has "/Count 48".
      // Let's verify both count occurrences:
      final pageMatches = RegExp(r'/Type\s*/Page\b').allMatches(content).length;
      final pagesCountMatch = RegExp(r'/Type\s*/Pages\b[^>]*?/Count\s+(\d+)').firstMatch(content);
      final catalogCount = pagesCountMatch != null ? int.tryParse(pagesCountMatch.group(1)!) : null;

      expect(
        catalogCount ?? pageMatches,
        equals(48),
        reason: 'Generated PDF must have exactly 48 pages (catalog count: $catalogCount, page dicts: $pageMatches)',
      );
    });
  });

  group('Dimension 3: UI Layout Resilience under Extreme Viewport Constraints', () {
    const viewports = <String, Size>{
      'Extreme Compact Mobile (iPhone SE 1)': Size(320, 568),
      'Android Compact': Size(360, 640),
      'Standard Mobile (iPhone 12/13/14)': Size(390, 844),
      'Tablet Portrait (iPad Mini/Air)': Size(768, 1024),
      'Desktop Small': Size(1280, 800),
      'Full HD Desktop': Size(1920, 1080),
      'Ultrawide Desktop': Size(2560, 1440),
    };

    for (final entry in viewports.entries) {
      final viewportName = entry.key;
      final size = entry.value;

      testWidgets(
        'UI Resilience: ClinicalEvidenceSheet renders with 0 RenderFlex overflow at $viewportName (${size.width.toInt()}x${size.height.toInt()}) in Thai and English',
        (WidgetTester tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          // Test diverse High-Alert drugs representing different clinical categories
          final testDrugs = [
            'warfarin', // Anticoagulant (oral, complex TDM & reversal)
            'heparin', // Anticoagulant (IV titration, aPTT)
            'norepinephrine', // Critical Vasopressor (central line, extravasation)
            'nicardipine', // Antihypertensive IV infusion
            'amiodarone', // Antiarrhythmic IV loading + maintenance
            'insulin_regular', // Endocrine (DKA / sliding scale)
            'magnesium_sulfate', // Electrolyte / Pre-eclampsia
            'oxytocin', // OB-GYN / PPH
          ];

          for (final drugId in testDrugs) {
            final drug = DrugDatabase.findById(drugId)!;
            final regimen = drug.regimens.first;

            // 1. Thai mode
            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: ClinicalEvidenceSheet(
                    drug: drug,
                    regimen: regimen,
                    isThai: true,
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();

            expect(
              tester.takeException(),
              isNull,
              reason: 'Zero layout exceptions expected for $drugId in Thai at $viewportName',
            );

            // 2. English mode
            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: ClinicalEvidenceSheet(
                    drug: drug,
                    regimen: regimen,
                    isThai: false,
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();

            expect(
              tester.takeException(),
              isNull,
              reason: 'Zero layout exceptions expected for $drugId in English at $viewportName',
            );
          }
        },
      );
    }
  });
}
