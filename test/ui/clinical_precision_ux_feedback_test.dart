import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:drug_dosage_calculator/data/patient_session.dart';
import 'package:drug_dosage_calculator/ui/calculator/calculator_screen.dart';
import 'package:drug_dosage_calculator/ui/calculator/widgets/dosage_result_card.dart';
import 'package:drug_dosage_calculator/ui/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(DrugDatabase.warmUp);

  setUp(() {
    PatientSession.instance.clearPatient();
  });

  tearDown(() {
    PatientSession.instance.clearPatient();
  });

  group('Clinical Precision UI/UX & Pharmacist Feedback Verification', () {
    testWidgets(
      'FB-19: Tapping regimen renal-adjusted chip opens ClinicalEvidenceSheet to Renal section',
      (tester) async {
        final meropenem = DrugDatabase.findById('meropenem')!;

        await tester.pumpWidget(
          MaterialApp(
            home: CalculatorScreen(drug: meropenem, isThai: false),
          ),
        );
        await tester.pumpAndSettle();

        final renalChip = find.byKey(const Key('regimen_renal_adjusted_chip'));
        expect(renalChip, findsOneWidget);
        await tester.ensureVisible(renalChip);
        await tester.tap(renalChip);
        await tester.pumpAndSettle();

        expect(find.text('Textbook Monograph & Evidence'), findsOneWidget);
        expect(find.text('Renal Impairment Adjustments'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'FB-19: Tapping hepatic caution alert card opens ClinicalEvidenceSheet to Hepatic guidance',
      (tester) async {
        final paracetamol = DrugDatabase.findById('paracetamol')!;

        await tester.pumpWidget(
          MaterialApp(
            home: CalculatorScreen(drug: paracetamol, isThai: false),
          ),
        );
        await tester.pumpAndSettle();

        final hepaticCard =
            find.byKey(const Key('clinical_alert_hepatic_caution_card'));
        expect(hepaticCard, findsOneWidget);
        await tester.ensureVisible(hepaticCard);
        await tester.tap(hepaticCard);
        await tester.pumpAndSettle();

        expect(find.text('Textbook Monograph & Evidence'), findsOneWidget);
        expect(
          find.text('Hepatic Impairment & Child-Pugh Guidance'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'FB-17: IV diluent card collapses stability notes by default while keeping incompatibility alerts visible, and expands on tap',
      (tester) async {
        final phenytoin = DrugDatabase.findById('phenytoin')!;

        await tester.pumpWidget(
          MaterialApp(
            home: CalculatorScreen(drug: phenytoin, isThai: false),
          ),
        );
        await tester.pumpAndSettle();

        final diluentCard =
            find.byKey(const Key('calculator_iv_diluent_card'));
        expect(diluentCard, findsOneWidget);

        // Critical incompatibility warning is always visible
        expect(
          find.textContaining('D5W, D5NSS, and LRS may cause precipitation'),
          findsOneWidget,
        );
        // Verbose stability note is collapsed initially
        expect(find.textContaining('0.22-micron filter'), findsNothing);

        await tester.ensureVisible(diluentCard);
        await tester.tap(diluentCard);
        await tester.pumpAndSettle();

        expect(find.textContaining('0.22-micron filter'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Reactive calculation: Active PatientSession auto-calculates dose on CalculatorScreen without pressing Calculate',
      (tester) async {
        PatientSession.instance.setPatient(
          const Patient(
            id: 'TEST-AUTO-CALC',
            weightKg: 70.0,
            heightCm: 170.0,
            ageYears: 55,
            sex: Sex.male,
            serumCreatinineMgDl: 1.0,
            isScrStable: true,
          ),
        );

        final meropenem = DrugDatabase.findById('meropenem')!;
        await tester.pumpWidget(
          MaterialApp(
            home: CalculatorScreen(drug: meropenem, isThai: false),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(DosageResultCard), findsOneWidget);
        expect(
          find.byKey(const Key('dosage_result_status_label')),
          findsOneWidget,
        );
        expect(find.textContaining('CrCl:'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'FB-15: HomeScreen renders drug class in parentheses next to generic name',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1024, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            home: HomeScreen(
              currentLocale: const Locale('en', 'US'),
              onLocaleChange: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('clinical_search_bar_input')),
          'Ibuprofen',
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        expect(find.text('Ibuprofen'), findsOneWidget);
        expect(find.text('(NSAID)'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
