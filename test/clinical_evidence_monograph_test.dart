import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/models/models.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:drug_dosage_calculator/ui/widgets/clinical_evidence_sheet.dart';

void main() {
  group('Clinical Monograph & Evidence Sheet Tests', () {
    test('Critical antimicrobials and analgesics have ClinicalMonograph attached and honest pending verification status', () {
      final vanco = DrugDatabase.findById('vancomycin');
      expect(vanco, isNotNull);
      expect(vanco!.monograph, isNotNull);
      expect(vanco.monograph!.textbookName, contains('Sanford Guide'));
      expect(vanco.monograph!.editionYear, contains('2024'));
      expect(vanco.provenance, isNotNull);
      expect(vanco.provenance!.reviewerLicense, isNull,
          reason: 'Must not contain fabricated reviewer licenses before human pharmacist sign-off');

      final mero = DrugDatabase.findById('meropenem');
      expect(mero, isNotNull);
      expect(mero!.monograph, isNotNull);
      expect(mero.monograph!.textbookName, contains('Sanford Guide'));
      expect(mero.provenance?.reviewerLicense, isNull);

      final piptaz = DrugDatabase.findById('piperacillin_tazobactam');
      expect(piptaz, isNotNull);
      expect(piptaz!.monograph, isNotNull);
      expect(piptaz.monograph!.textbookName, contains('Sanford Guide'));
      expect(piptaz.provenance?.reviewerLicense, isNull);

      final colistin = DrugDatabase.findById('colistin');
      expect(colistin, isNotNull);
      expect(colistin!.monograph, isNotNull);
      expect(colistin.monograph!.textbookName, contains('Sanford Guide'));
      expect(colistin.provenance?.reviewerLicense, isNull);

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

    testWidgets('ClinicalEvidenceSheet renders textbook citations, dosing monograph and pending verification status', (tester) async {
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

      // Verify Honest Pending Verification Stamp (until human pharmacist signs off)
      expect(find.textContaining('รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Verification)'), findsOneWidget);
    });

    testWidgets('ClinicalEvidenceSheet renders verified stamp when drug has signed-off reviewerLicense', (tester) async {
      const signedOffDrug = Drug(
        id: 'test_signed_off',
        genericName: 'SignedOffDrug',
        category: DrugCategory.antibiotic,
        provenance: Provenance(
          source: 'The Sanford Guide 2024',
          reviewedBy: 'ภก.ทดสอบ ระบบคลินิก',
          reviewedAt: '2026-10-21',
          reviewerLicense: 'ภ. 99999',
        ),
        regimens: [
          DosingRegimen(
            route: DoseRoute.iv,
            dosingType: DosingType.fixed,
            fixedDose: 500,
            doseUnit: DoseUnit.mg,
            frequency: Frequency.q12h,
            verificationStatus: VerificationStatus.verified,
          ),
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ClinicalEvidenceSheet(
              drug: signedOffDrug,
              isThai: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('ข้อมูลได้รับการตรวจรับรองทางคลินิกแล้ว'), findsOneWidget);
      expect(find.textContaining('ภ. 99999'), findsOneWidget);
    });
  });
}
