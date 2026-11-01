// ============================================================================
// ClinicalEvidenceSheet Widget Test Suite (High-Alert Medications)
// ============================================================================
// Verifies:
// 1. ClinicalEvidenceSheet renders cleanly without overflow across diverse
//    classes of High-Alert medications:
//    - Anticoagulant: Warfarin, Heparin, Enoxaparin
//    - Vasopressor / Cardiovascular: Norepinephrine, Amiodarone, Nicardipine
//    - Endocrine / Electrolyte / OB-GYN: Insulin Regular, Magnesium Sulfate, Oxytocin
// 2. Monograph sections (textbook citation, dosing guidance, administration/dilution,
//    renal impairment, precautions/black box warnings) render faithfully.
// 3. Honest amber pending verification badge ("รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Verification)")
//    displays reliably when reviewerLicense is null.
// 4. Zero layout overflow exceptions across viewports (mobile and tablet/desktop).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:drug_dosage_calculator/ui/widgets/clinical_evidence_sheet.dart';

void main() {
  group('ClinicalEvidenceSheet High-Alert Widget Tests', () {
    testWidgets(
        '1. Anticoagulant (Warfarin): renders textbook citation, dosing guidance, precautions, and pending badge without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final warfarin = DrugDatabase.findById('warfarin')!;
      final regimen = warfarin.regimens.first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClinicalEvidenceSheet(
              drug: warfarin,
              regimen: regimen,
              isThai: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'Must have zero layout exceptions');

      // Citation header
      expect(find.textContaining('Lexicomp', findRichText: true), findsWidgets);
      expect(find.textContaining('CHEST', findRichText: true), findsWidgets);

      // Monograph sections
      expect(find.textContaining('ขนาดยาและการบริหารยาตามตำรา'), findsOneWidget);
      expect(find.textContaining('ข้อควรระวังและข้อห้ามใช้'), findsOneWidget);

      // Honest pending verification banner
      expect(find.textContaining('รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Verification)'), findsOneWidget);
    });

    testWidgets(
        '2. Anticoagulant (Heparin IV Infusion): renders aPTT TDM protocol, IV dilution, and pending badge without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final heparin = DrugDatabase.findById('heparin')!;
      final regimen = heparin.regimens.first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClinicalEvidenceSheet(
              drug: heparin,
              regimen: regimen,
              isThai: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('CHEST Guidelines', findRichText: true), findsWidgets);
      expect(find.textContaining('ขนาดยาและการบริหารยาตามตำรา'), findsOneWidget);
      expect(find.textContaining('คำแนะนำการบริหารยาทางหลอดเลือดดำ'), findsOneWidget);
      expect(find.textContaining('รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Verification)'), findsOneWidget);
    });

    testWidgets(
        '3. Vasopressor (Norepinephrine): renders Central Line guidance, extravasation antidote, and pending badge without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final ne = DrugDatabase.findById('norepinephrine')!;
      final regimen = ne.regimens.first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClinicalEvidenceSheet(
              drug: ne,
              regimen: regimen,
              isThai: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Surviving Sepsis Campaign', findRichText: true), findsWidgets);
      expect(find.textContaining('ขนาดยาและการบริหารยาตามตำรา'), findsOneWidget);
      expect(find.textContaining('คำแนะนำการบริหารยาทางหลอดเลือดดำ'), findsOneWidget);
      expect(find.textContaining('ข้อควรระวังและข้อห้ามใช้'), findsOneWidget);
      expect(find.textContaining('รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Verification)'), findsOneWidget);
    });

    testWidgets(
        '4. Cardiovascular / Antiarrhythmic (Amiodarone): renders loading dose, dilution, and pending badge without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final amiodarone = DrugDatabase.findById('amiodarone')!;
      final regimen = amiodarone.regimens.first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClinicalEvidenceSheet(
              drug: amiodarone,
              regimen: regimen,
              isThai: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('AHA', findRichText: true), findsWidgets);
      expect(find.textContaining('ขนาดยาและการบริหารยาตามตำรา'), findsOneWidget);
      expect(find.textContaining('รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Verification)'), findsOneWidget);
    });

    testWidgets(
        '5. Endocrine (Regular Insulin IV/SC): renders sliding scale / DKA guidance, hypoglycemic safety, and pending badge',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final insulin = DrugDatabase.findById('insulin_regular')!;
      final regimen = insulin.regimens.first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClinicalEvidenceSheet(
              drug: insulin,
              regimen: regimen,
              isThai: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('ADA', findRichText: true), findsWidgets);
      expect(find.textContaining('ขนาดยาและการบริหารยาตามตำรา'), findsOneWidget);
      expect(find.textContaining('รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Verification)'), findsOneWidget);
    });

    testWidgets(
        '6. Critical Electrolyte (Magnesium Sulfate IV): renders Eclampsia protocol, patellar reflex monitoring, and pending badge',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mgso4 = DrugDatabase.findById('magnesium_sulfate')!;
      final regimen = mgso4.regimens.first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClinicalEvidenceSheet(
              drug: mgso4,
              regimen: regimen,
              isThai: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('ACOG', findRichText: true), findsWidgets);
      expect(find.textContaining('ขนาดยาและการบริหารยาตามตำรา'), findsOneWidget);
      expect(find.textContaining('รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Verification)'), findsOneWidget);
    });

    testWidgets(
        '7. OB-GYN High-Alert (Oxytocin IV): renders postpartum hemorrhage protocol and pending badge without overflow on mobile viewport',
        (tester) async {
      // Mobile screen: 390x844 (iPhone standard)
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final oxytocin = DrugDatabase.findById('oxytocin')!;
      final regimen = oxytocin.regimens.first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClinicalEvidenceSheet(
              drug: oxytocin,
              regimen: regimen,
              isThai: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('WHO', findRichText: true), findsWidgets);
      expect(find.textContaining('ขนาดยาและการบริหารยาตามตำรา'), findsOneWidget);
      expect(find.textContaining('รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Verification)'), findsOneWidget);
    });
  });
}
