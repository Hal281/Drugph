import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/calculators/pharmacist_calculator.dart';
import 'package:drug_dosage_calculator/core/models/models.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:drug_dosage_calculator/ui/home_screen.dart';

void main() {
  group('Item 1: Drug List Curation (Pharmacist Feedback)', () {
    test(
      'Naloxone is reclassified to DrugCategory.antidote with monograph and excluded from analgesics',
      () {
        final naloxone = DrugDatabase.allDrugs.firstWhere(
          (d) => d.id == 'naloxone',
        );

        expect(naloxone.category, equals(DrugCategory.antidote));
        expect(naloxone.monograph, isNotNull);
        expect(naloxone.provenance, isNotNull);
        expect(naloxone.sourceCitation, isNotEmpty);
        expect(DateTime.tryParse(naloxone.lastReviewedDate), isNotNull);

        final analgesics = DrugDatabase.getByCategory(DrugCategory.analgesic);
        expect(analgesics.any((d) => d.id == 'naloxone'), isFalse);

        final antidotes = DrugDatabase.getByCategory(DrugCategory.antidote);
        expect(antidotes.any((d) => d.id == 'naloxone'), isTrue);
      },
    );

    test(
      'Naproxen is in NSAIDs with complete monograph, adult fixed regimen, and pediatric weight-based regimen',
      () {
        final naproxen = DrugDatabase.allDrugs.firstWhere(
          (d) => d.id == 'naproxen',
        );

        expect(naproxen.category, equals(DrugCategory.nsaid));
        expect(naproxen.drugClass, equals(DrugClass.nsaid));
        expect(naproxen.monograph, isNotNull);
        expect(naproxen.provenance, isNotNull);
        expect(naproxen.specialNotes, isNotEmpty);
        expect(naproxen.specialNotesTh, isNotEmpty);

        final adultRegimen = naproxen.regimens.firstWhere(
          (r) => r.effectiveAudience == RegimenAudience.adult,
        );
        final pedRegimen = naproxen.regimens.firstWhere(
          (r) => r.effectiveAudience == RegimenAudience.pediatric,
        );

        expect(adultRegimen.dosingType, equals(DosingType.fixed));
        expect(pedRegimen.dosingType, equals(DosingType.weightBased));

        const childPatient = Patient(
          id: 'ped-naproxen-test',
          ageYears: 6,
          weightKg: 20.0,
          heightCm: 115.0,
          sex: Sex.male,
          serumCreatinineMgDl: 0.5,
          isScrStable: true,
        );

        final result = PharmacistCalculator.calculateDose(
          patient: childPatient,
          drug: naproxen,
          regimen: pedRegimen,
        );
        expect(result.isBlocked, isFalse);
        expect(result.calculatedDose, closeTo(100.0, 0.01));
      },
    );

    test(
      'Chemotherapy and transplant immunosuppressants are excluded from active catalog/search but resolvable via findById',
      () {
        const archivedIds = [
          'carboplatin',
          'methotrexate',
          'tacrolimus',
          'mycophenolate',
        ];

        final searchAll = DrugDatabase.search('');

        for (final id in archivedIds) {
          expect(
            DrugDatabase.allDrugs.any((d) => d.id == id),
            isFalse,
            reason: '$id must not appear in active DrugDatabase.allDrugs',
          );
          expect(
            searchAll.any((d) => d.id == id),
            isFalse,
            reason: '$id must not appear in active DrugDatabase.search',
          );
          expect(
            DrugDatabase.archivedSpecialtyDrugs.any((d) => d.id == id),
            isTrue,
            reason: '$id must be archived in archivedSpecialtyDrugs',
          );

          final resolved = DrugDatabase.findById(id);
          expect(
            resolved,
            isNotNull,
            reason: '$id must remain resolvable via DrugDatabase.findById',
          );
        }

        final tacrolimus = DrugDatabase.findById('tacrolimus')!;
        final mycophenolate = DrugDatabase.findById('mycophenolate')!;
        expect(tacrolimus.category, equals(DrugCategory.immunosuppressant));
        expect(tacrolimus.drugClass, equals(DrugClass.immunosuppressant));
        expect(mycophenolate.category, equals(DrugCategory.immunosuppressant));
        expect(mycophenolate.drugClass, equals(DrugClass.immunosuppressant));
      },
    );

    testWidgets(
      'HomeScreen Analgesics filter includes Paracetamol, Naproxen, Tramadol and excludes Naloxone; hides Chemotherapy/Immunosuppressants',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 900));
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

        // Archived categories should not exist anywhere in the active database
        expect(
          DrugDatabase.allDrugs.any(
            (d) =>
                d.category == DrugCategory.chemotherapy ||
                d.category == DrugCategory.immunosuppressant,
          ),
          isFalse,
        );
        expect(find.text('Chemotherapy'), findsNothing);
        expect(find.text('Immunosuppressants'), findsNothing);

        final categoryScrollable = find.descendant(
          of: find.byWidgetPredicate((w) => w is SizedBox && w.height == 95),
          matching: find.byType(Scrollable),
        );

        // Scroll horizontally to Antidotes category chip and verify Naloxone
        await tester.scrollUntilVisible(
          find.text('Antidotes'),
          200,
          scrollable: categoryScrollable,
        );
        await tester.ensureVisible(find.text('Antidotes'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Antidotes'));
        await tester.pumpAndSettle();
        expect(find.text('Naloxone'), findsOneWidget);

        // Scroll back to Analgesics category chip and verify pain meds
        await tester.scrollUntilVisible(
          find.text('Analgesics'),
          -200,
          scrollable: categoryScrollable,
        );
        await tester.ensureVisible(find.text('Analgesics'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Analgesics'));
        await tester.pumpAndSettle();

        expect(find.text('Paracetamol (Acetaminophen)'), findsOneWidget);
        expect(find.text('Naproxen'), findsOneWidget);
        expect(find.text('Ibuprofen'), findsOneWidget);
        expect(find.text('Naloxone'), findsNothing);

        final drugListScrollable = find.byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        );
        await tester.scrollUntilVisible(
          find.text('Tramadol'),
          200,
          scrollable: drugListScrollable,
        );
        expect(find.text('Tramadol'), findsOneWidget);
      },
    );
  });
}
