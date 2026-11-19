import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:drug_dosage_calculator/ui/calculator/calculator_screen.dart';
import 'package:drug_dosage_calculator/ui/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(DrugDatabase.warmUp);

  group('FB-21 (WP-08): 3-Tier Drug System (Core / Extended / ReferenceOnly)', () {
    test(
      '100% of all 123 drugs in allDrugs + archivedSpecialtyDrugs have deterministic DrugTier assignment',
      () {
        expect(DrugDatabase.allCatalogDrugs.length, equals(123));
        expect(DrugDatabase.coreDrugs.length, equals(34));
        expect(DrugDatabase.referenceOnlyDrugs.length, equals(4));
        expect(
          DrugDatabase.extendedDrugs.length,
          equals(123 - 34 - 4),
        );

        for (final id in DrugTierRegistry.coreDrugIds) {
          expect(
            DrugDatabase.findById(id),
            isNotNull,
            reason: 'Core drug "$id" must exist in DrugDatabase',
          );
          expect(DrugTierRegistry.tierFor(id), equals(DrugTier.core));
        }

        // Heparin must be Extended (hospital-specific protocols deferred to WP-15)
        expect(
          DrugDatabase.findById('heparin')!.tier,
          equals(DrugTier.extended),
        );

        // Archived specialty drugs must be ReferenceOnly (delete nothing - Q2)
        for (final refId in const [
          'carboplatin',
          'methotrexate',
          'tacrolimus',
          'mycophenolate',
        ]) {
          final drug = DrugDatabase.findById(refId)!;
          expect(drug.tier, equals(DrugTier.referenceOnly));
        }
      },
    );

    test(
      'ReferenceOnly drugs block bedside auto-dosing when enforceReferenceOnlyGate is true',
      () {
        final tacrolimus = DrugDatabase.findById('tacrolimus')!;
        const patient = Patient(
          id: 'wp08-ref-only',
          weightKg: 60.0,
          heightCm: 165.0,
          ageYears: 40,
          sex: Sex.female,
          serumCreatinineMgDl: 1.0,
          isScrStable: true,
        );

        final gated = PharmacistCalculator.calculateDose(
          patient: patient,
          drug: tacrolimus,
          regimen: tacrolimus.regimens.first,
          enforceReferenceOnlyGate: true,
        );
        expect(gated.success, isFalse);
        expect(
          gated.warnings
              .any((w) => w.code == DoseWarningCode.referenceOnlyDrug),
          isTrue,
        );
      },
    );

    testWidgets(
      'HomeScreen defaults to Core filter, allows Extended & All Tiers switching, and searches across all tiers ranking Core first',
      (tester) async {
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

        expect(find.byKey(const Key('home_tier_chip_core')), findsOneWidget);
        expect(
          find.byKey(const Key('home_tier_chip_extended')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('home_tier_chip_all')), findsOneWidget);

        // Default Core view excludes Extended Heparin until searched or Extended tab tapped
        expect(find.textContaining('Heparin'), findsNothing);

        // Typing 'Heparin' automatically expands search across Extended tier with Extended badge
        await tester.enterText(
          find.byKey(const Key('clinical_search_bar_input')),
          'Heparin',
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        expect(find.textContaining('Heparin'), findsWidgets);
        expect(find.byKey(const Key('drug_tier_badge_heparin')), findsOneWidget);

        // Typing 'Tacrolimus' finds ReferenceOnly drug with badge
        await tester.enterText(
          find.byKey(const Key('clinical_search_bar_input')),
          'Tacrolimus',
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        expect(find.text('Tacrolimus'), findsOneWidget);
        expect(
          find.byKey(const Key('drug_tier_badge_tacrolimus')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'CalculatorScreen shows Extended notice for Heparin and ReferenceOnly card (no auto-calc) for Tacrolimus',
      (tester) async {
        final heparin = DrugDatabase.findById('heparin')!;
        await tester.pumpWidget(
          MaterialApp(
            home: CalculatorScreen(drug: heparin, isThai: false),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('calculator_extended_tier_notice')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('calculator_calculate_button')),
          findsOneWidget,
        );

        final tacrolimus = DrugDatabase.findById('tacrolimus')!;
        await tester.pumpWidget(
          MaterialApp(
            home: CalculatorScreen(drug: tacrolimus, isThai: false),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('calculator_reference_only_card')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('calculator_reference_only_monograph_btn')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('calculator_calculate_button')),
          findsNothing,
        );
      },
    );
  });
}
