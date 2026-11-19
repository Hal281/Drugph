import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:drug_dosage_calculator/ui/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(DrugDatabase.warmUp);

  group('FB-11 (WP-03): ISMP 2024 High-Alert Reclassification & NTI/TDM', () {
    test(
      'JSON asset assets/data/high_alert_lists/ismp_acute_care.json matches HighAlertRegistry.ismpAcuteCare2024 100%',
      () async {
        final jsonStr = await rootBundle.loadString(
          'assets/data/high_alert_lists/ismp_acute_care.json',
        );
        final parsed = HighAlertRegistry.parseJsonAsset(jsonStr);

        expect(
          parsed.keys.toSet(),
          equals(HighAlertRegistry.ismpAcuteCare2024.keys.toSet()),
        );
        for (final entry in parsed.entries) {
          final mirror = HighAlertRegistry.ismpAcuteCare2024[entry.key]!;
          expect(entry.value.applicableRoutes, equals(mirror.applicableRoutes));
          expect(entry.value.ismpCategory, equals(mirror.ismpCategory));
          expect(entry.value.sourceEdition, equals('ISMP Acute Care 2024'));
        }
      },
    );

    test(
      'Route-specific ISMP rules distinguish IV vs PO/IM in HighAlertRegistry and PharmacistCalculator',
      () {
        // Potassium Chloride: IV Infusion = HAD, Oral = NOT HAD
        expect(
          HighAlertRegistry.isHighAlert(
            'potassium_chloride',
            route: DoseRoute.ivInfusion,
          ),
          isTrue,
        );
        expect(
          HighAlertRegistry.isHighAlert(
            'potassium_chloride',
            route: DoseRoute.po,
          ),
          isFalse,
        );

        final kcl = DrugDatabase.findById('potassium_chloride')!;
        final kclPo = kcl.regimens.firstWhere((r) => r.route == DoseRoute.po);
        final kclIv =
            kcl.regimens.firstWhere((r) => r.route == DoseRoute.ivInfusion);
        const adult = Patient(
          id: 'wp03-adult',
          weightKg: 70,
          heightCm: 170,
          ageYears: 45,
          sex: Sex.male,
          serumCreatinineMgDl: 0.9,
          isScrStable: true,
        );
        final poResult = PharmacistCalculator.calculateDose(
          patient: adult,
          drug: kcl,
          regimen: kclPo,
        );
        final ivResult = PharmacistCalculator.calculateDose(
          patient: adult,
          drug: kcl,
          regimen: kclIv,
        );
        expect(
          poResult.warnings
              .any((w) => w.code == DoseWarningCode.highAlertMedication),
          isFalse,
        );
        expect(
          ivResult.warnings
              .any((w) => w.code == DoseWarningCode.highAlertMedication),
          isTrue,
        );

        // Epinephrine: IV Push/Infusion = HAD, IM Anaphylaxis = NOT IV HAD
        expect(
          HighAlertRegistry.isHighAlert(
            'epinephrine',
            route: DoseRoute.ivInfusion,
          ),
          isTrue,
        );
        expect(
          HighAlertRegistry.isHighAlert('epinephrine', route: DoseRoute.im),
          isFalse,
        );

        // Oxytocin: IV = HAD, IM = NOT HAD
        expect(
          HighAlertRegistry.isHighAlert('oxytocin', route: DoseRoute.iv),
          isTrue,
        );
        expect(
          HighAlertRegistry.isHighAlert('oxytocin', route: DoseRoute.im),
          isFalse,
        );

        // PO-only digoxin & metoprolol in catalog are NOT flagged HAD on HomeScreen
        final digoxin = DrugDatabase.findById('digoxin')!;
        final metoprolol = DrugDatabase.findById('metoprolol')!;
        expect(HighAlertRegistry.isDrugHighAlertInCatalog(digoxin), isFalse);
        expect(HighAlertRegistry.isDrugHighAlertInCatalog(metoprolol), isFalse);
        expect(HighAlertRegistry.isNarrowTherapeuticIndex(digoxin), isTrue);
      },
    );

    test(
      'Non-ISMP drugs are unflagged and NTI/TDM drugs are cleanly categorized',
      () {
        const nonIsmpIds = [
          'rifampin',
          'naloxone',
          'haloperidol',
          'atropine',
          'colistin',
          'nicardipine',
          'epoetin_alfa',
          'mycophenolate',
          'calcium_gluconate',
          'vancomycin',
          'gentamicin',
          'amikacin',
          'phenytoin',
          'valproic_acid',
          'lithium',
          'tacrolimus',
        ];
        for (final id in nonIsmpIds) {
          final drug = DrugDatabase.findById(id)!;
          expect(
            drug.isHighAlert,
            isFalse,
            reason: '$id is not on ISMP 2024 Acute Care default list',
          );
          expect(
            HighAlertRegistry.isDrugHighAlertInCatalog(drug),
            isFalse,
            reason: '$id must not show High-Alert catalog badge by default',
          );
        }

        for (final ntiId in [
          'vancomycin',
          'gentamicin',
          'amikacin',
          'digoxin',
          'phenytoin',
          'valproic_acid',
          'lithium',
          'tacrolimus',
        ]) {
          final drug = DrugDatabase.findById(ntiId)!;
          expect(
            HighAlertRegistry.isNarrowTherapeuticIndex(drug),
            isTrue,
            reason: '$ntiId must be tagged NTI / TDM',
          );
        }

        // Glipizide (oral sulfonylurea) IS included on ISMP 2024 Acute Care
        final glipizide = DrugDatabase.findById('glipizide')!;
        expect(glipizide.isHighAlert, isTrue);
        expect(HighAlertRegistry.isDrugHighAlertInCatalog(glipizide), isTrue);
      },
    );

    test('HighAlertOverride supports per-hospital PTC add/remove overrides', () {
      const customHospitalPolicy = HighAlertOverride(
        addedDrugIds: {'vancomycin', 'calcium_gluconate'},
        removedDrugIds: {'tramadol'},
        routeOverrides: {
          'epinephrine': {'all'},
        },
      );

      expect(
        HighAlertRegistry.isHighAlert(
          'vancomycin',
          route: DoseRoute.ivInfusion,
          hospitalOverride: customHospitalPolicy,
        ),
        isTrue,
      );
      expect(
        HighAlertRegistry.isHighAlert(
          'calcium_gluconate',
          route: DoseRoute.ivPush,
          hospitalOverride: customHospitalPolicy,
        ),
        isTrue,
      );
      expect(
        HighAlertRegistry.isHighAlert(
          'tramadol',
          route: DoseRoute.po,
          hospitalOverride: customHospitalPolicy,
        ),
        isFalse,
      );
      expect(
        HighAlertRegistry.isHighAlert(
          'epinephrine',
          route: DoseRoute.im,
          hospitalOverride: customHospitalPolicy,
        ),
        isTrue,
      );
    });

    testWidgets(
      'HomeScreen displays NTI / TDM badge for Vancomycin instead of High Alert, and red High Alert badge for Warfarin',
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
          'Vancomycin',
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('drug_nti_tdm_badge_vancomycin')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('drug_high_alert_badge_vancomycin')),
          findsNothing,
        );

        await tester.enterText(
          find.byKey(const Key('clinical_search_bar_input')),
          'Warfarin',
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('drug_high_alert_badge_warfarin')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  });
}
