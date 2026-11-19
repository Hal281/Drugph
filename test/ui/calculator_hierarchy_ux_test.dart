import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:drug_dosage_calculator/data/patient_session.dart';
import 'package:drug_dosage_calculator/ui/calculator/calculator_screen.dart';
import 'package:drug_dosage_calculator/ui/calculator/widgets/clinical_header_alerts.dart';
import 'package:drug_dosage_calculator/ui/calculator/widgets/dosage_result_card.dart';
import 'package:drug_dosage_calculator/ui/calculator/widgets/dosing_parameters_form.dart';
import 'package:drug_dosage_calculator/ui/calculator/widgets/iv_diluent_compatibility_card.dart';
import 'package:drug_dosage_calculator/ui/calculator/widgets/patient_clinical_header.dart';
import 'package:drug_dosage_calculator/ui/calculator/widgets/regimen_selector_section.dart';
import 'package:drug_dosage_calculator/ui/calculator/widgets/side_effects_summary_card.dart';
import 'package:drug_dosage_calculator/ui/widgets/clinical_evidence_sheet.dart';
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

  const adultPatient = Patient(
    id: 'ux-adult-70kg',
    weightKg: 70.0,
    heightCm: 170.0,
    ageYears: 35,
    sex: Sex.male,
    serumCreatinineMgDl: 0.9,
    isScrStable: true,
  );

  group('FB-16 / FB-17 / FB-19 (WP-11): Calculator Visual Hierarchy & Ergonomics', () {
    testWidgets(
      'Mobile 390x844 enforces clean top-to-bottom hierarchy: Regimen -> DoseResult -> SideEffects -> IV Chips -> Alerts',
      (tester) async {
        PatientSession.instance.setPatient(adultPatient);
        final ceftriaxone = DrugDatabase.findById('ceftriaxone')!;

        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            home: CalculatorScreen(
              drug: ceftriaxone,
              isThai: true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final regimenTop =
            tester.getTopLeft(find.byType(RegimenSelectorSection)).dy;
        final resultTop = tester.getTopLeft(find.byType(DosageResultCard)).dy;
        final sideEffectsTop = tester
            .getTopLeft(find.byKey(const Key('calculator_side_effects_card')))
            .dy;
        final ivCardTop = tester
            .getTopLeft(find.byKey(const Key('calculator_iv_diluent_card')))
            .dy;
        final alertsTop =
            tester.getTopLeft(find.byType(ClinicalHeaderAlerts)).dy;

        expect(regimenTop, lessThan(resultTop));
        expect(resultTop, lessThan(sideEffectsTop));
        expect(sideEffectsTop, lessThan(ivCardTop));
        expect(ivCardTop, lessThan(alertsTop));

        // Ensure SideEffectsSummaryCard handles display instead of duplicating inside ClinicalHeaderAlerts
        expect(find.text('ผลข้างเคียงสำคัญ (Side Effects)'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Compact 320x480 renders streamlined hierarchy with zero overflow',
      (tester) async {
        PatientSession.instance.setPatient(adultPatient);
        final ceftriaxone = DrugDatabase.findById('ceftriaxone')!;

        await tester.binding.setSurfaceSize(const Size(320, 480));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            home: CalculatorScreen(
              drug: ceftriaxone,
              isThai: true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(DosageResultCard), findsOneWidget);
        expect(
          find.byKey(const Key('calculator_side_effects_card')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('calculator_iv_diluent_card')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Desktop 1280x900 places PatientHeader + RegimenSelector + Parameters on Left pane and DoseResult + SideEffects on Right pane',
      (tester) async {
        PatientSession.instance.setPatient(adultPatient);
        final ceftriaxone = DrugDatabase.findById('ceftriaxone')!;

        await tester.binding.setSurfaceSize(const Size(1280, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            home: CalculatorScreen(
              drug: ceftriaxone,
              isThai: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final headerX = tester.getTopLeft(find.byType(PatientClinicalHeader)).dx;
        final regimenX =
            tester.getTopLeft(find.byType(RegimenSelectorSection)).dx;
        final paramsX = tester.getTopLeft(find.byType(DosingParametersForm)).dx;

        final resultX = tester.getTopLeft(find.byType(DosageResultCard)).dx;
        final sideEffectsX =
            tester.getTopLeft(find.byType(SideEffectsSummaryCard)).dx;
        final ivCardX =
            tester.getTopLeft(find.byType(IvDiluentCompatibilityCard)).dx;

        // Left pane flex 5 (~581px wide) vs Right pane starts >= 580px
        expect(headerX, lessThan(500));
        expect(regimenX, lessThan(500));
        expect(paramsX, lessThan(500));
        expect(resultX, greaterThan(500));
        expect(sideEffectsX, greaterThan(500));
        expect(ivCardX, greaterThan(500));

        // Left pane vertical order: PatientHeader -> RegimenSelector -> ParametersForm
        expect(
          tester.getTopLeft(find.byType(PatientClinicalHeader)).dy,
          lessThan(tester.getTopLeft(find.byType(RegimenSelectorSection)).dy),
        );
        expect(
          tester.getTopLeft(find.byType(RegimenSelectorSection)).dy,
          lessThan(tester.getTopLeft(find.byType(DosingParametersForm)).dy),
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'FB-17: IvDiluentCompatibilityCard shows compact diluent chips + permanent red incompatibility warning, expanding stability notes on tap',
      (tester) async {
        PatientSession.instance.setPatient(adultPatient);
        final ceftriaxone = DrugDatabase.findById('ceftriaxone')!;

        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            home: CalculatorScreen(
              drug: ceftriaxone,
              isThai: true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('iv_diluent_compact_chips')), findsOneWidget);
        expect(find.textContaining('NSS ✓'), findsOneWidget);
        expect(find.textContaining('D5W ✓'), findsOneWidget);
        expect(find.textContaining('ห้ามผสม LRS'), findsOneWidget);

        // Critical incompatibility warning MUST be visible even before tap
        expect(
          find.textContaining('สารน้ำที่มีแคลเซียม (เช่น LRS)'),
          findsOneWidget,
        );
        // Verbose stability note hidden initially
        expect(
          find.textContaining('เจือจางใน NSS/D5W 50–100 mL'),
          findsNothing,
        );

        // Tap IV diluent card to reveal stability & source citation
        await tester.ensureVisible(
          find.byKey(const Key('calculator_iv_diluent_card')),
        );
        await tester.tap(find.byKey(const Key('calculator_iv_diluent_card')));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('เจือจางใน NSS/D5W 50–100 mL'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'FB-19: Renal adjustment and Hepatic caution alert cards tap directly into ClinicalEvidenceSheet',
      (tester) async {
        PatientSession.instance.setPatient(adultPatient);
        final amoxClav = DrugDatabase.findById('amoxicillin_clavulanate')!;

        await tester.binding.setSurfaceSize(const Size(1280, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            home: CalculatorScreen(
              drug: amoxClav,
              isThai: true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final renalCard =
            find.byKey(const Key('clinical_alert_renal_adjustment_card'));
        final hepaticCard =
            find.byKey(const Key('clinical_alert_hepatic_caution_card'));
        expect(renalCard, findsOneWidget);
        expect(hepaticCard, findsOneWidget);

        // Tap Renal card -> opens Monograph sheet on Renal section
        await tester.ensureVisible(renalCard);
        await tester.tap(renalCard);
        await tester.pumpAndSettle();

        expect(find.byType(ClinicalEvidenceSheet), findsOneWidget);
        expect(
          find.text('เกณฑ์การปรับขนาดยาตามระดับไต (Renal Tiers)'),
          findsOneWidget,
        );

        // Close sheet & test Hepatic card tap
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        await tester.ensureVisible(hepaticCard);
        await tester.tap(hepaticCard);
        await tester.pumpAndSettle();

        expect(find.byType(ClinicalEvidenceSheet), findsOneWidget);
        expect(
          find.text('แนวทางการปรับขนาดยาในผู้ป่วยโรคตับ (Hepatic & Child-Pugh)'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'FB-05 / FB-06 regression: CalculatorScreen never embeds static DDI or Reference cards in main body',
      (tester) async {
        PatientSession.instance.setPatient(adultPatient);
        final ceftriaxone = DrugDatabase.findById('ceftriaxone')!;

        await tester.pumpWidget(
          MaterialApp(
            home: CalculatorScreen(
              drug: ceftriaxone,
              isThai: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Severe Interactions'), findsNothing);
        expect(find.text('Clinical Evidence Reference'), findsNothing);
      },
    );
  });
}
