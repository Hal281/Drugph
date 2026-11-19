import 'dart:io';

import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:drug_dosage_calculator/data/patient_session.dart';
import 'package:drug_dosage_calculator/ui/calculator/calculator_screen.dart';
import 'package:drug_dosage_calculator/ui/calculator/controllers/calculator_controller.dart';
import 'package:drug_dosage_calculator/ui/pkpd/controllers/pk_simulation_controller.dart';
import 'package:drug_dosage_calculator/ui/widgets/patient_banner.dart';
import 'package:drug_dosage_calculator/ui/widgets/patient_edit_dialog.dart';
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

  group('Feedback v2 Phase 1 Fixes (WP-01, WP-04, WP-05, WP-06, WP-07)', () {
    test(
      'FB-09 (WP-01): cockcroftGaultAutoWeight uses AdjBW for obese adult and matches PharmacistCalculator',
      () {
        const obesePatient = Patient(
          id: 'obese-adult-fb09',
          weightKg: 120.0,
          heightCm: 170.0,
          ageYears: 50,
          sex: Sex.male,
          serumCreatinineMgDl: 1.0,
          isScrStable: true,
        );

        final selection = RenalCalculator.selectCockcroftGaultWeight(
          weightKg: obesePatient.weightKg,
          heightCm: obesePatient.heightCm,
          sex: obesePatient.sex,
        );
        expect(selection.strategy, equals('AdjBW'));

        final autoCrcl = RenalCalculator.cockcroftGaultAutoWeight(
          ageYears: obesePatient.ageYears,
          weightKg: obesePatient.weightKg,
          heightCm: obesePatient.heightCm,
          sex: obesePatient.sex,
          serumCreatinineMgDl: obesePatient.serumCreatinineMgDl!,
        );
        final rawCrcl = RenalCalculator.cockcroftGault(
          ageYears: obesePatient.ageYears,
          weightKg: obesePatient.weightKg,
          sex: obesePatient.sex,
          serumCreatinineMgDl: obesePatient.serumCreatinineMgDl!,
        );

        expect(rawCrcl, closeTo(150.0, 0.01));
        expect(autoCrcl, lessThan(120.0));
        expect(autoCrcl, closeTo(109.6, 0.5));

        final amox = DrugDatabase.findById('amoxicillin')!;
        final adultRegimen = amox.regimens.firstWhere(
          (r) => r.effectiveAudience == RegimenAudience.adult,
        );
        final calcResult = PharmacistCalculator.calculateDose(
          patient: obesePatient,
          drug: amox,
          regimen: adultRegimen,
        );
        expect(calcResult.crclMlMin, closeTo(autoCrcl, 0.01));
      },
    );

    testWidgets(
      'FB-09 (WP-01): PatientEditDialog saves Winter 2012 AdjBW CrCl instead of raw TBW CrCl for obese adult',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: PatientEditDialog(isThai: false),
            ),
          ),
        );

        await tester.enterText(
          find.widgetWithText(TextField, 'Weight (kg) *'),
          '120',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Height (cm) *'),
          '170',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Age (years) *'),
          '50',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Serum Creatinine (mg/dL)'),
          '1.0',
        );

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        final saved = PatientSession.instance.currentPatient.value;
        expect(saved, isNotNull);

        final expectedAutoCrcl = RenalCalculator.cockcroftGaultAutoWeight(
          ageYears: 50,
          weightKg: 120.0,
          heightCm: 170.0,
          sex: Sex.male,
          serumCreatinineMgDl: 1.0,
        );
        expect(saved!.creatinineClearanceMlMin, closeTo(expectedAutoCrcl, 0.01));
        expect(saved.creatinineClearanceMlMin, isNot(closeTo(150.0, 0.5)));
      },
    );

    test(
      'FB-13 (WP-04): PharmacistCalculator warnings never contain colloquial "เข็มแรก" and use "โดสแรก"',
      () {
        final amox = DrugDatabase.findById('amoxicillin')!;
        final adultRegimen = amox.regimens.firstWhere(
          (r) => r.effectiveAudience == RegimenAudience.adult,
        );

        const akiPatient = Patient(
          id: 'aki-fb13',
          weightKg: 60.0,
          heightCm: 165.0,
          ageYears: 45,
          sex: Sex.female,
          serumCreatinineMgDl: 2.0,
          isScrStable: false,
        );
        final akiResult = PharmacistCalculator.calculateDose(
          patient: akiPatient,
          drug: amox,
          regimen: adultRegimen,
        );

        const missingScrPatient = Patient(
          id: 'missing-scr-fb13',
          weightKg: 60.0,
          heightCm: 165.0,
          ageYears: 45,
          sex: Sex.female,
          isScrStable: true,
        );
        final missingScrResult = PharmacistCalculator.calculateDose(
          patient: missingScrPatient,
          drug: amox,
          regimen: adultRegimen,
        );

        final allWarningText = [
          ...akiResult.warnings,
          ...missingScrResult.warnings,
        ]
            .expand((w) => [w.messageTh, ...?w.clinicalAlternativesTh])
            .join('\n');

        expect(allWarningText, isNot(contains('เข็มแรก')));
        expect(allWarningText, isNot(contains('เข็มที่ 2')));
        expect(allWarningText, contains('โดสแรก'));
      },
    );

    test(
      'FB-14 (WP-05): Ibuprofen and Naproxen keep Dengue in contraindications only without duplicating in specialNotes',
      () {
        for (final id in ['ibuprofen', 'naproxen']) {
          final drug = DrugDatabase.findById(id)!;
          expect(
            drug.contraindications.any((c) => c.toLowerCase().contains('dengue')),
            isTrue,
            reason: '$id must retain Dengue hemorrhagic fever in contraindications',
          );
          expect(
            drug.specialNotes?.toLowerCase().contains('dengue') ?? false,
            isFalse,
            reason: '$id specialNotes must not duplicate Dengue contraindication',
          );
          expect(
            drug.specialNotesTh?.contains('ไข้เลือดออก') ?? false,
            isFalse,
            reason: '$id specialNotesTh must not duplicate Dengue contraindication',
          );
        }
      },
    );

    testWidgets(
      'FB-10 (WP-06): PatientClinicalHeader shows Cockcroft-Gault weight basis for obese adult and Bedside Schwartz for pediatric patient',
      (tester) async {
        final amox = DrugDatabase.findById('amoxicillin')!;

        PatientSession.instance.setPatient(
          const Patient(
            id: 'obese-header-fb10',
            weightKg: 120.0,
            heightCm: 170.0,
            ageYears: 50,
            sex: Sex.male,
            serumCreatinineMgDl: 1.0,
            isScrStable: true,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: CalculatorScreen(drug: amox, isThai: false),
          ),
        );
        await tester.tap(find.byKey(const Key('calculator_calculate_button')));
        await tester.pumpAndSettle();

        expect(
          find.text('CrCl calculated with Cockcroft-Gault equation'),
          findsOneWidget,
        );
        expect(find.textContaining('Weight basis: AdjBW'), findsOneWidget);

        PatientSession.instance.setPatient(
          const Patient(
            id: 'child-header-fb10',
            weightKg: 18.0,
            heightCm: 110.0,
            ageYears: 5,
            sex: Sex.male,
            serumCreatinineMgDl: 0.5,
            isScrStable: true,
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('calculator_calculate_button')));
        await tester.pumpAndSettle();

        expect(
          find.text('Pediatric eGFR calculated with Bedside Schwartz'),
          findsOneWidget,
        );
        expect(find.text('90.9 mL/min/1.73 m²'), findsOneWidget);
        expect(
          find.text('CrCl calculated with Cockcroft-Gault equation'),
          findsNothing,
        );
      },
    );

    test(
      'FB-02 (WP-07): Pediatric regimen sweep across all drugs for 10 kg child has finite positive doses and divides daily regimens properly',
      () {
        const child10Kg = Patient(
          id: 'sweep-child-10kg',
          weightKg: 10.0,
          heightCm: 85.0,
          ageYears: 2,
          sex: Sex.male,
          isScrStable: true,
        );

        var testedRegimens = 0;
        for (final drug in DrugDatabase.allDrugs) {
          for (final regimen in drug.regimens) {
            if (regimen.effectiveAudience != RegimenAudience.pediatric) {
              continue;
            }
            if (regimen.dosingType != DosingType.weightBased ||
                regimen.dosePerKg == null) {
              continue;
            }
            testedRegimens++;

            final result = PharmacistCalculator.calculateDose(
              patient: child10Kg,
              drug: drug,
              regimen: regimen,
            );

            final dose = result.calculatedDose;
            expect(
              dose != null && dose.isFinite && dose > 0,
              isTrue,
              reason: '${drug.id} (${regimen.indication}) must yield positive finite dose',
            );

            final isDailyBasis = regimen.doseBasis == DoseBasis.perDay ||
                regimen.frequency.doseBasis == DoseBasis.perDay;
            final dosesPerDay = regimen.frequency.dosesPerDay;
            if (isDailyBasis &&
                dosesPerDay != null &&
                dosesPerDay > 1 &&
                !regimen.frequency.isOnce) {
              final rawDaily = child10Kg.weightKg * regimen.dosePerKg!;
              final maxSingleCap = regimen.limits?.maxSingleDose;
              if (maxSingleCap == null || rawDaily <= maxSingleCap) {
                expect(
                  dose!,
                  lessThan(rawDaily),
                  reason:
                      '${drug.id} (${regimen.indication}) perDay regimen must divide across $dosesPerDay doses/day instead of giving full daily dose once',
                );
              }
            }
          }
        }

        expect(testedRegimens, greaterThan(10));
      },
    );

    test(
      'Live QA Bug A: Weight-only entry (10 kg, blank Age/Height) on fresh Amoxicillin calculates 150 mg q8h',
      () {
        final amox = DrugDatabase.findById('amoxicillin')!;
        final ctrl = CalculatorController(drug: amox);
        addTearDown(ctrl.dispose);

        ctrl.weightCtrl.text = '10';
        expect(
          ctrl.state.selectedRegimen?.effectiveAudience,
          equals(RegimenAudience.pediatric),
        );

        final val = ctrl.calculate(isThai: true);
        expect(val.isValid, isTrue);
        expect(ctrl.ageCtrl.text, equals('2'));
        expect(ctrl.heightCtrl.text, equals('85'));
        expect(ctrl.state.result?.calculatedDose, closeTo(150.0, 0.01));
        expect(ctrl.state.result?.structuredFrequency?.displayEn, equals('q8h'));
      },
    );

    test(
      'Live QA Bug B & Pregnancy Filter: Single-drug calculation emits no DDI list and no pregnancy warning for 2yo Male Ibuprofen',
      () {
        final ibuprofen = DrugDatabase.findById('ibuprofen')!;
        final pedRegimen = ibuprofen.regimens.firstWhere(
          (r) => r.effectiveAudience == RegimenAudience.pediatric,
        );
        const boy10Kg = Patient(
          id: 'qa-boy-10kg',
          weightKg: 10.0,
          heightCm: 85.0,
          ageYears: 2,
          sex: Sex.male,
          serumCreatinineMgDl: 0.4,
          isScrStable: true,
        );

        final singleResult = PharmacistCalculator.calculateDose(
          patient: boy10Kg,
          drug: ibuprofen,
          regimen: pedRegimen,
        );
        expect(singleResult.success, isTrue);
        expect(
          singleResult.warnings.any(
            (w) => w.code == DoseWarningCode.severeInteractionAlert,
          ),
          isFalse,
        );
        expect(
          singleResult.warnings.any(
            (w) => w.messageEn.toLowerCase().contains('pregnancy'),
          ),
          isFalse,
        );

        // Ibuprofen + Warfarin must still warn about severe DDI
        final coMedResult = PharmacistCalculator.calculateDose(
          patient: boy10Kg.copyWith(activeDrugIds: ['warfarin']),
          drug: ibuprofen,
          regimen: pedRegimen,
        );
        expect(
          coMedResult.warnings.any(
            (w) => w.code == DoseWarningCode.severeInteractionAlert,
          ),
          isTrue,
        );
      },
    );

    test(
      'Live QA Bug C & Rounding: Pharmacist Note prints pediatric eGFR (Bedside Schwartz), omits Non-pregnant for males, and rounds IBW/AdjBW to 1 decimal',
      () {
        final amox = DrugDatabase.findById('amoxicillin')!;
        final pedReg = amox.regimens.firstWhere(
          (r) => r.effectiveAudience == RegimenAudience.pediatric,
        );
        const boy10Kg = Patient(
          id: 'qa-note-boy',
          weightKg: 10.0,
          heightCm: 85.0,
          ageYears: 2,
          sex: Sex.male,
          serumCreatinineMgDl: 0.4,
          isScrStable: true,
        );
        final pedRes = PharmacistCalculator.calculateDose(
          patient: boy10Kg,
          drug: amox,
          regimen: pedReg,
        );
        final pedNote = ClinicalOrderFormatter.formatPharmacistNote(
          patient: boy10Kg,
          drug: amox,
          regimen: pedReg,
          result: pedRes,
          isThai: true,
        );
        expect(pedNote, contains('eGFR: 87.8 mL/min/1.73 m² (Bedside Schwartz)'));
        expect(pedNote, isNot(contains('Cockcroft-Gault')));
        expect(pedNote, isNot(contains('Non-pregnant')));

        final ceph = DrugDatabase.findById('cephalexin')!;
        final adultReg = ceph.regimens.first;
        const obeseMale = Patient(
          id: 'qa-note-obese',
          weightKg: 120.0,
          heightCm: 165.0,
          ageYears: 60,
          sex: Sex.male,
          serumCreatinineMgDl: 1.2,
          isScrStable: true,
        );
        final obeseRes = PharmacistCalculator.calculateDose(
          patient: obeseMale,
          drug: ceph,
          regimen: adultReg,
        );
        final obeseNote = ClinicalOrderFormatter.formatPharmacistNote(
          patient: obeseMale,
          drug: ceph,
          regimen: adultReg,
          result: obeseRes,
        );
        expect(obeseNote, contains('IBW: 61.4 kg'));
        expect(obeseNote, contains('AdjBW: 84.8 kg'));
        expect(obeseNote, contains('CrCl: 78.6 mL/min (Cockcroft-Gault)'));
        expect(obeseNote, isNot(contains('Non-pregnant')));
      },
    );

    test(
      'Live QA Ibuprofen/Paracetamol/Amoxicillin/Cephalexin Side Effects populated',
      () {
        for (final id in [
          'ibuprofen',
          'paracetamol',
          'naproxen',
          'amoxicillin',
          'cephalexin',
        ]) {
          final drug = DrugDatabase.findById(id)!;
          expect(drug.sideEffects, isNotEmpty, reason: '$id missing EN sideEffects');
          expect(drug.sideEffectsTh, isNotEmpty, reason: '$id missing TH sideEffectsTh');
        }
      },
    );

    testWidgets(
      'Live QA Blocked Mismatch & Banner Persistence: Adult/Child mismatch never renders "null null", shows switch banner, and PatientBanner retains CrCl/eGFR',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final amox = DrugDatabase.findById('amoxicillin')!;
        PatientSession.instance.setPatient(
          Patient(
            id: 'qa-obese-banner',
            weightKg: 120.0,
            heightCm: 165.0,
            ageYears: 60,
            sex: Sex.male,
            serumCreatinineMgDl: 1.2,
            creatinineClearanceMlMin: RenalCalculator.cockcroftGaultAutoWeight(
              ageYears: 60,
              weightKg: 120.0,
              heightCm: 165.0,
              sex: Sex.male,
              serumCreatinineMgDl: 1.2,
            ),
            isScrStable: true,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  const PatientBanner(isThai: true),
                  Expanded(
                    child: CalculatorScreen(drug: amox, isThai: true),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('CrCl: 78.6 mL/min (CG)'), findsOneWidget);

        // Calculate standard adult regimen -> banner must NOT revert to CrCl: -
        await tester.tap(find.byKey(const Key('calculator_calculate_button')));
        await tester.pumpAndSettle();
        expect(find.textContaining('CrCl: 78.6 mL/min (CG)'), findsOneWidget);

        // Manually select Pediatric regimen for 60yo adult -> warning banner + no "null null"
        final dropdown = find.byType(DropdownButton<DosingRegimen>);
        await tester.tap(dropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('Standard Infection (Pediatric)').last);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('regimen_audience_mismatch_banner')), findsOneWidget);

        await tester.tap(find.byKey(const Key('calculator_calculate_button')));
        await tester.pumpAndSettle();

        expect(find.textContaining('null null'), findsNothing);
        expect(find.byKey(const Key('dosage_result_blocked_badge')), findsOneWidget);

        // Click 1-tap switch button to restore adult regimen
        await tester.tap(find.byKey(const Key('regimen_audience_switch_button')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('regimen_audience_mismatch_banner')), findsNothing);
      },
    );

    test(
      'FB-09 (WP-01): PkSimulationController uses Winter 2012 AdjBW for obese adult and Bedside Schwartz for pediatric patient',
      () {
        const obeseAdult = Patient(
          id: 'pk-obese-fb09',
          weightKg: 120.0,
          heightCm: 170.0,
          ageYears: 50,
          sex: Sex.male,
          serumCreatinineMgDl: 1.0,
          isScrStable: true,
        );
        final expectedAdjCrcl = RenalCalculator.cockcroftGaultAutoWeight(
          ageYears: 50,
          weightKg: 120.0,
          heightCm: 170.0,
          sex: Sex.male,
          serumCreatinineMgDl: 1.0,
        );
        expect(
          PkSimulationController.resolveCrclForPatient(obeseAdult),
          closeTo(expectedAdjCrcl, 0.01),
        );

        const childPatient = Patient(
          id: 'pk-child-fb09',
          weightKg: 18.0,
          heightCm: 110.0,
          ageYears: 5,
          sex: Sex.male,
          serumCreatinineMgDl: 0.5,
          isScrStable: true,
        );
        final expectedSchwartz = RenalCalculator.bedsideSchwartz(
          heightCm: 110.0,
          serumCreatinineMgDl: 0.5,
        );
        expect(
          PkSimulationController.resolveCrclForPatient(childPatient),
          closeTo(expectedSchwartz, 0.01),
        );
      },
    );

    test(
      'FB-13 (WP-04): ClinicalTerms standardizes first-dose labels and lib/ contains zero colloquial "เข็มแรก"/"เข็มที่"',
      () {
        expect(ClinicalTerms.firstDoseTh, equals('โดสแรก'));
        expect(ClinicalTerms.loadingDoseEn, equals('Loading dose'));

        final libDir = Directory('lib');
        final offenders = <String>[];
        for (final entity in libDir.listSync(recursive: true)) {
          if (entity is File && entity.path.endsWith('.dart')) {
            final content = entity.readAsStringSync();
            if (content.contains('เข็มแรก') || content.contains('เข็มที่')) {
              offenders.add(entity.path);
            }
          }
        }
        expect(offenders, isEmpty, reason: 'Colloquial needle wording found in: $offenders');
      },
    );

    testWidgets(
      'FB-10 (WP-06): PatientClinicalHeader shows explicit < 1 year infant eGFR disclaimer when SCr is entered',
      (tester) async {
        final amox = DrugDatabase.findById('amoxicillin')!;
        PatientSession.instance.setPatient(
          const Patient(
            id: 'infant-header-fb10',
            weightKg: 6.0,
            heightCm: 62.0,
            ageYears: 0,
            ageMonths: 4,
            sex: Sex.female,
            serumCreatinineMgDl: 0.4,
            isScrStable: true,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: CalculatorScreen(drug: amox, isThai: false),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('patient_header_infant_egfr_disclaimer')),
          findsOneWidget,
        );
        expect(find.textContaining('Infant < 1 yr'), findsOneWidget);
      },
    );
  });
}
