import 'dart:io';

import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:drug_dosage_calculator/data/patient_session.dart';
import 'package:drug_dosage_calculator/data/verification_ledger_loader.dart';
import 'package:drug_dosage_calculator/ui/calculator/calculator_screen.dart';
import 'package:drug_dosage_calculator/ui/home_screen.dart';
import 'package:drug_dosage_calculator/ui/widgets/clinical_evidence_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(DrugDatabase.warmUp);

  setUp(() {
    VerificationLedgerService.resetLedger();
    PatientSession.instance.clearPatient();
  });

  tearDown(() {
    VerificationLedgerService.resetLedger();
    PatientSession.instance.clearPatient();
  });

  VerificationLedger signedLedgerForDrugs(
    Iterable<Drug> drugs, {
    String verifiedBy = 'ภก.ทดสอบ คลินิก',
    String licenseNo = 'ภก.12345',
    String verifiedDate = '2026-11-20',
  }) {
    final entries = <VerificationLedgerEntry>[];
    for (final drug in drugs) {
      for (var i = 0; i < drug.regimens.length; i++) {
        entries.add(
          VerificationLedgerEntry(
            drugId: drug.id.toLowerCase(),
            regimenId: drug.regimenIdAt(i),
            verified: true,
            verifiedBy: verifiedBy,
            licenseNo: licenseNo,
            verifiedDate: verifiedDate,
            sourceChecked: 'Drug Information Handbook (Lexicomp / APhA) 2024',
          ),
        );
      }
    }
    return VerificationLedger(schemaVersion: '1.0.0', entries: entries);
  }

  group('WP-13 (Q5): Verification Ledger Asset & SchemaValidator Governance', () {
    test(
      'assets/data/verification_ledger.json loads via rootBundle, covers 100% of Core regimens, and has zero fake sign-offs',
      () async {
        final rawJson = await rootBundle.loadString(
          VerificationLedgerLoader.assetPath,
        );
        final ledger = VerificationLedger.parseJsonString(rawJson);

        final report = SchemaValidator.validateVerificationLedger(
          ledger,
          expectedDrugs: DrugDatabase.coreDrugs,
        );
        expect(report.isValid, isTrue, reason: report.errors.join('\n'));

        final expectedRegimenCount = DrugDatabase.coreDrugs
            .fold<int>(0, (sum, d) => sum + d.regimens.length);
        expect(ledger.entries.length, equals(expectedRegimenCount));

        // Strict anti-hallucination invariant: zero unreviewed fake sign-offs
        for (final entry in ledger.entries) {
          expect(entry.verified, isFalse, reason: '${entry.drugId}::${entry.regimenId}');
          expect(entry.verifiedBy, isNull);
          expect(entry.licenseNo, isNull);
          expect(entry.verifiedDate, isNull);
        }

        // Pilot release gate must block at 0/34 verified Core drugs
        final pilotGate = VerificationLedgerService.evaluatePilotReleaseGate(
          coreDrugs: DrugDatabase.coreDrugs,
          ledger: ledger,
        );
        expect(pilotGate.coreDrugCount, equals(34));
        expect(pilotGate.verifiedCoreDrugCount, equals(0));
        expect(pilotGate.isPilotReady, isFalse);
      },
    );

    test('SchemaValidator rejects placeholder reviewers, bad licenses, bad dates, and (Pending) sources', () {
      const badReviewer = VerificationLedgerEntry(
        drugId: 'amoxicillin',
        regimenId: 'po__standard',
        verified: true,
        verifiedBy: 'Pending Review',
        licenseNo: 'ภก.12345',
        verifiedDate: '2026-11-20',
        sourceChecked: 'Lexicomp 2024',
      );
      expect(SchemaValidator.validateLedgerEntry(badReviewer), isNotEmpty);

      const badLicense = VerificationLedgerEntry(
        drugId: 'amoxicillin',
        regimenId: 'po__standard',
        verified: true,
        verifiedBy: 'ภก.สมชาย ใจดี',
        licenseNo: 'ABC-123',
        verifiedDate: '2026-11-20',
        sourceChecked: 'Lexicomp 2024',
      );
      expect(SchemaValidator.validateLedgerEntry(badLicense), isNotEmpty);

      const badCalendarDate = VerificationLedgerEntry(
        drugId: 'amoxicillin',
        regimenId: 'po__standard',
        verified: true,
        verifiedBy: 'ภก.สมชาย ใจดี',
        licenseNo: 'ภก.12345',
        verifiedDate: '2026-02-30',
        sourceChecked: 'Lexicomp 2024',
      );
      expect(SchemaValidator.validateLedgerEntry(badCalendarDate), isNotEmpty);

      const pendingSource = VerificationLedgerEntry(
        drugId: 'amoxicillin',
        regimenId: 'po__standard',
        verified: true,
        verifiedBy: 'ภก.สมชาย ใจดี',
        licenseNo: 'ว.54321',
        verifiedDate: '2026-11-20',
        sourceChecked: 'Sanford Guide (Pending)',
      );
      expect(SchemaValidator.validateLedgerEntry(pendingSource), isNotEmpty);

      const validEntry = VerificationLedgerEntry(
        drugId: 'amoxicillin',
        regimenId: 'po__standard',
        verified: true,
        verifiedBy: 'ภก.สมชาย ใจดี',
        licenseNo: 'ภ. 54321',
        verifiedDate: '2026-11-20',
        sourceChecked: 'The Sanford Guide 2024 p.88',
      );
      expect(SchemaValidator.validateLedgerEntry(validEntry), isEmpty);
    });

    test('Drug requires 100% active regimens verified; partial sign-off stays non-verified', () {
      final amox = DrugDatabase.findById('amoxicillin')!;
      expect(amox.regimens.length, greaterThanOrEqualTo(2));

      // Verify only first regimen -> partiallyVerified (NOT isFullyVerified)
      final partialLedger = VerificationLedger(
        schemaVersion: '1.0.0',
        entries: [
          VerificationLedgerEntry(
            drugId: 'amoxicillin',
            regimenId: amox.regimenIdAt(0),
            verified: true,
            verifiedBy: 'ภก.ทดสอบ',
            licenseNo: 'ภก.11111',
            verifiedDate: '2026-11-20',
            sourceChecked: 'Sanford Guide 2024',
          ),
        ],
      );
      final partialSummary = VerificationLedgerService.evaluateDrug(
        amox,
        ledger: partialLedger,
      );
      expect(partialSummary.status, equals(DrugLedgerStatus.partiallyVerified));
      expect(partialSummary.verifiedRegimenCount, equals(1));
      expect(partialSummary.isFullyVerified, isFalse);

      // Verify all active regimens -> verified
      final fullLedger = signedLedgerForDrugs([amox]);
      final fullSummary = VerificationLedgerService.evaluateDrug(
        amox,
        ledger: fullLedger,
      );
      expect(fullSummary.status, equals(DrugLedgerStatus.verified));
      expect(fullSummary.verifiedRegimenCount, equals(amox.regimens.length));
      expect(fullSummary.isFullyVerified, isTrue);
    });

    test('Pilot Release Gate blocks < 80% Core verified and passes >= 80%', () {
      final core = DrugDatabase.coreDrugs;
      expect(core.length, equals(34));

      // 27 / 34 = 79.41% -> Blocked (< 80%)
      final underThreshold = signedLedgerForDrugs(core.take(27));
      final blockedGate = VerificationLedgerService.evaluatePilotReleaseGate(
        coreDrugs: core,
        ledger: underThreshold,
      );
      // Note: expectedDrugs completeness errors also fire unless remaining unverified entries exist
      expect(blockedGate.verifiedCoreDrugCount, equals(27));
      expect(blockedGate.coveragePercent, lessThan(80.0));
      expect(blockedGate.isPilotReady, isFalse);

      // Include remaining 7 unverified entries + 28 signed -> 28 / 34 = 82.35% -> Passes!
      final fullEntries = <VerificationLedgerEntry>[
        ...signedLedgerForDrugs(core.take(28)).entries,
        for (final drug in core.skip(28))
          for (var i = 0; i < drug.regimens.length; i++)
            VerificationLedgerEntry(
              drugId: drug.id.toLowerCase(),
              regimenId: drug.regimenIdAt(i),
              verified: false,
              sourceChecked: 'Lexicomp 2024 (Pending)',
            ),
      ];
      final passGate = VerificationLedgerService.evaluatePilotReleaseGate(
        coreDrugs: core,
        ledger: VerificationLedger(schemaVersion: '1.0.0', entries: fullEntries),
      );
      expect(passGate.verifiedCoreDrugCount, equals(28));
      expect(passGate.coveragePercent, greaterThanOrEqualTo(80.0));
      expect(passGate.validationErrors, isEmpty);
      expect(passGate.isPilotReady, isTrue);
    });

    test('Generated 5-drug batch PDF (Batch 01 Core) exists and is a valid non-empty PDF', () {
      final batchPdf =
          File('review/batches/Clinical_Verification_Batch_01_core.pdf');
      expect(batchPdf.existsSync(), isTrue);
      final bytes = batchPdf.readAsBytesSync();
      expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
      expect(
        String.fromCharCodes(bytes.skip(bytes.length - 64)),
        contains('%%EOF'),
      );
    });
  });

  group('WP-13 Strict UI Verification Gate (Calculator, Home, Monograph)', () {
    testWidgets(
      'Unverified and partially verified Core drugs show amber pharmacist banner with 0 overflow on 320x480 and 1280x900',
      (tester) async {
        final amox = DrugDatabase.findById('amoxicillin')!;

        // 1. Unverified state on narrow 320x480 mobile
        await tester.binding.setSurfaceSize(const Size(320, 480));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            home: CalculatorScreen(drug: amox, isThai: true),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('calculator_unverified_pharmacist_banner')),
          findsOneWidget,
        );
        expect(
          find.textContaining('รอเภสัชกรตรวจสอบรับรอง'),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('calculator_verified_pharmacist_banner')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);

        // 2. Partial verification on 1280x900 desktop still forces amber banner
        VerificationLedgerService.loadLedger(
          VerificationLedger(
            schemaVersion: '1.0.0',
            entries: [
              VerificationLedgerEntry(
                drugId: 'amoxicillin',
                regimenId: amox.regimenIdAt(0),
                verified: true,
                verifiedBy: 'ภก.ทดสอบ',
                licenseNo: 'ภก.12345',
                verifiedDate: '2026-11-20',
                sourceChecked: 'Sanford Guide 2024',
              ),
            ],
          ),
        );
        await tester.binding.setSurfaceSize(const Size(1280, 900));
        await tester.pumpWidget(
          MaterialApp(
            home: CalculatorScreen(drug: amox, isThai: false),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('calculator_unverified_pharmacist_banner')),
          findsOneWidget,
        );
        expect(
          find.textContaining('Not yet verified by a pharmacist'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '100% ledger-verified Core drug shows green banner in CalculatorScreen, badge in HomeScreen, and stamp in ClinicalEvidenceSheet',
      (tester) async {
        final amox = DrugDatabase.findById('amoxicillin')!;
        VerificationLedgerService.loadLedger(
          signedLedgerForDrugs(
            [amox],
            verifiedBy: 'ภก.รับรอง คลินิก',
            licenseNo: 'ภก.88888',
            verifiedDate: '2026-11-20',
          ),
        );

        await tester.binding.setSurfaceSize(const Size(1280, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        // CalculatorScreen green banner + opens verified ClinicalEvidenceSheet
        await tester.pumpWidget(
          MaterialApp(
            home: CalculatorScreen(drug: amox, isThai: true),
          ),
        );
        await tester.pumpAndSettle();

        final verifiedBanner =
            find.byKey(const Key('calculator_verified_pharmacist_banner'));
        expect(verifiedBanner, findsOneWidget);
        expect(find.textContaining('ภก.88888'), findsOneWidget);

        await tester.tap(verifiedBanner);
        await tester.pumpAndSettle();
        expect(find.byType(ClinicalEvidenceSheet), findsOneWidget);
        expect(
          find.text('ข้อมูลได้รับการตรวจรับรองทางคลินิกแล้ว'),
          findsOneWidget,
        );
        expect(find.textContaining('ภก.รับรอง คลินิก (ภก.88888)'), findsOneWidget);

        // HomeScreen renders drug_verified_badge_amoxicillin only when 100% verified
        await tester.pumpWidget(
          MaterialApp(
            home: HomeScreen(
              currentLocale: const Locale('th', 'TH'),
              onLocaleChange: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('drug_verified_badge_amoxicillin')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('drug_verified_badge_vancomycin')),
          findsNothing,
        );
      },
    );
  });
}
