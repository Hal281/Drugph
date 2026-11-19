import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:drug_dosage_calculator/data/prescription_cart.dart';
import 'package:drug_dosage_calculator/ui/prescription_cart_screen.dart';
import 'package:drug_dosage_calculator/ui/widgets/clinical_evidence_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(DrugDatabase.warmUp);

  setUp(() {
    PrescriptionCart.instance.clearCart();
  });

  tearDown(() {
    PrescriptionCart.instance.clearCart();
  });

  group('FB-18 (WP-10): Practice-Frequency DDI Ranking & Collapsible UI', () {
    test(
      'PrescriptionCart prioritizes common Amoxicillin + Warfarin above less-common Methotrexate without fallback duplicates',
      () {
        final cart = PrescriptionCart.instance;
        final amox = DrugDatabase.findById('amoxicillin')!;
        final warfarin = DrugDatabase.findById('warfarin')!;
        final mtx = DrugDatabase.findById('methotrexate')!;

        cart.addDrug(amox);
        cart.addDrug(methotrexateDrug(mtx));
        cart.addDrug(warfarin);

        final alerts = cart.evaluateAlerts();
        expect(alerts.length, equals(2));

        // 1st alert MUST be Common in Practice: Amoxicillin + Warfarin
        expect(alerts[0].category, equals(CartAlertCategory.ddi));
        expect(alerts[0].frequency, equals(InteractionFrequency.common));
        expect(alerts[0].severity, equals(InteractionSeverity.moderate));
        expect(alerts[0].messageEn, contains('Warfarin'));
        expect(alerts[0].messageEn, contains('Risk Rating C'));
        expect(alerts[0].source, contains('Drug Information Handbook'));

        // 2nd alert MUST be Less Common: Amoxicillin + Methotrexate
        expect(alerts[1].category, equals(CartAlertCategory.ddi));
        expect(alerts[1].frequency, equals(InteractionFrequency.lessCommon));
        expect(alerts[1].severity, equals(InteractionSeverity.major));
        expect(alerts[1].messageEn, contains('Methotrexate'));
        expect(alerts[1].messageEn, contains('Risk Rating D'));
      },
    );

    test('Amoxicillin/Clavulanate also surfaces Common DDI with Warfarin', () {
      final cart = PrescriptionCart.instance;
      cart.addDrug(DrugDatabase.findById('amoxicillin_clavulanate')!);
      cart.addDrug(DrugDatabase.findById('warfarin')!);

      final alerts = cart.evaluateAlerts();
      expect(alerts, isNotEmpty);
      expect(alerts.first.frequency, equals(InteractionFrequency.common));
      expect(alerts.first.messageEn, contains('Warfarin'));
    });

    testWidgets(
      'PrescriptionCartScreen shows Common DDIs immediately and collapses Less Common DDIs by default',
      (tester) async {
        final cart = PrescriptionCart.instance;
        cart.addDrug(DrugDatabase.findById('amoxicillin')!);
        cart.addDrug(DrugDatabase.findById('warfarin')!);
        cart.addDrug(DrugDatabase.findById('methotrexate')!);

        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          const MaterialApp(
            home: PrescriptionCartScreen(isThai: true),
          ),
        );
        await tester.pumpAndSettle();

        // Common DDI visible immediately
        expect(find.byKey(const Key('cart_common_alerts_section')), findsOneWidget);
        expect(find.textContaining('Warfarin'), findsWidgets);

        // Less common tile exists and is collapsed initially
        final lessCommonTile = find.byKey(const Key('cart_less_common_ddi_tile'));
        expect(lessCommonTile, findsOneWidget);
        expect(find.textContaining('Risk Rating D'), findsNothing);

        // Expand collapsible tile to inspect Methotrexate details
        await tester.tap(lessCommonTile);
        await tester.pumpAndSettle();

        expect(find.textContaining('Risk Rating D'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('FB-20 (WP-10): Lexicomp / Drug Information Handbook Citation Standard', () {
    test('ClinicalCitationFormatter replaces raw OpenFDA with DIH attribution', () {
      expect(
        ClinicalCitationFormatter.normalizeCitationString('OpenFDA'),
        equals('Drug Information Handbook (Lexicomp / APhA)'),
      );
      final normalizedSpl =
          ClinicalCitationFormatter.normalizeCitationString('US FDA (OpenFDA SPL)');
      expect(normalizedSpl, contains('Drug Information Handbook (Lexicomp / APhA)'));
      expect(normalizedSpl.toLowerCase(), isNot(contains('openfda')));

      final normalizedLexi =
          ClinicalCitationFormatter.normalizeCitationString('Lexicomp 2024');
      expect(normalizedLexi, contains('Drug Information Handbook (Lexicomp / APhA)'));
    });

    testWidgets(
      'ClinicalEvidenceSheet renders Drug Information Handbook (Lexicomp / APhA) without raw OpenFDA',
      (tester) async {
        final amox = DrugDatabase.findById('amoxicillin')!;

        await tester.pumpWidget(
          MaterialApp(
            home: ClinicalEvidenceSheet(
              drug: amox,
              regimen: amox.regimens.first,
              isThai: true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final citationFinder =
            find.byKey(const Key('clinical_evidence_citation_text'));
        expect(citationFinder, findsOneWidget);
        expect(
          find.textContaining('Drug Information Handbook (Lexicomp / APhA)'),
          findsOneWidget,
        );
        expect(
          find.textContaining('OpenFDA', skipOffstage: false),
          findsNothing,
        );
      },
    );
  });
}

Drug methotrexateDrug(Drug d) => d;
