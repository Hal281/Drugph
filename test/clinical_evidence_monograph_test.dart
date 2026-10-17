import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/models/models.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:drug_dosage_calculator/ui/widgets/clinical_evidence_sheet.dart';

void main() {
  group('Clinical Monograph & Evidence Sheet Tests', () {
    test('Vancomycin, Meropenem, Gentamicin, Ceftriaxone, and Paracetamol have ClinicalMonograph attached', () {
      final vanco = DrugDatabase.findById('vancomycin');
      expect(vanco, isNotNull);
      expect(vanco!.monograph, isNotNull);
      expect(vanco.monograph!.textbookName, contains('Sanford Guide'));
      expect(vanco.monograph!.editionYear, contains('2024'));
      expect(vanco.provenance, isNotNull);
      expect(vanco.provenance!.reviewerLicense, isNotNull);

      final mero = DrugDatabase.findById('meropenem');
      expect(mero, isNotNull);
      expect(mero!.monograph, isNotNull);
      expect(mero.monograph!.textbookName, contains('Sanford Guide'));

      final genta = DrugDatabase.findById('gentamicin');
      expect(genta, isNotNull);
      expect(genta!.monograph, isNotNull);
      expect(genta.monograph!.sectionOrTable, contains('Table 10D'));

      final ceftria = DrugDatabase.findById('ceftriaxone');
      expect(ceftria, isNotNull);
      expect(ceftria!.monograph, isNotNull);
      expect(ceftria.monograph!.textbookName, contains('Sanford Guide'));

      final para = DrugDatabase.findById('paracetamol');
      expect(para, isNotNull);
      expect(para!.monograph, isNotNull);
      expect(para.monograph!.textbookName, contains('Lexicomp'));
    });

    testWidgets('ClinicalEvidenceSheet renders textbook citations, dosing monograph and reviewer info', (tester) async {
      final vanco = DrugDatabase.findById('vancomycin')!;
      final regimen = vanco.regimens.first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClinicalEvidenceSheet(
              drug: vanco,
              regimen: regimen,
              isThai: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Textbook Title Header
      expect(find.textContaining('The Sanford Guide to Antimicrobial Therapy', findRichText: true), findsWidgets);
      expect(find.textContaining('54th Edition, 2024', findRichText: true), findsWidgets);

      // Verify Dosing Guidance Section
      expect(find.textContaining('ขนาดยาและการบริหารยาตามตำรา'), findsOneWidget);
      expect(find.textContaining('Loading Dose'), findsWidgets);

      // Verify Renal Tiers Section
      expect(find.textContaining('เกณฑ์การปรับขนาดยาตามระดับไต (Renal Tiers)'), findsOneWidget);

      // Verify Administration Section
      expect(find.textContaining('คำแนะนำการบริหารยาทางหลอดเลือดดำ'), findsOneWidget);
      expect(find.textContaining('Red Man Syndrome'), findsWidgets);

      // Verify Reviewer & Stamp
      expect(find.textContaining('ภ. 14582'), findsWidgets);
      expect(find.textContaining('ข้อมูลได้รับการตรวจรับรองทางคลินิกแล้ว'), findsOneWidget);
    });

    testWidgets('ClinicalEvidenceSheet renders unverified warning when drug has no monograph', (tester) async {
      const unverifiedDrug = Drug(
        id: 'test_unverified',
        genericName: 'TestUnverified',
        category: DrugCategory.antibiotic,
        regimens: [
          DosingRegimen(
            route: DoseRoute.po,
            dosingType: DosingType.fixed,
            fixedDose: 100,
            doseUnit: DoseUnit.mg,
            frequency: Frequency.q24h,
          ),
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ClinicalEvidenceSheet(
              drug: unverifiedDrug,
              isThai: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Unverified warning banner appears
      expect(find.textContaining('รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Verification)'), findsOneWidget);
    });
  });
}
