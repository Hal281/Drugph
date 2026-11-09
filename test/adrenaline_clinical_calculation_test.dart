// ============================================================================
// Clinical Calculation & Safety Verification Suite: Adrenaline & Vasoactives
// ============================================================================
// Authoritative references:
// - AHA ACLS & PALS Guidelines 2020 (Circulation 2020)
// - World Allergy Organization (WAO) Anaphylaxis Guidelines 2020
// - US FDA Adrenalin SPL / Thai FDA / Ramathibodi IV Infusion Guide 2024
// - AGENTS.md Rules 1-5 (Zero-Error, Evidence-Based, Non-Blocking Overdose)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/core/models/specialized_dosing_models.dart';
import 'package:drug_dosage_calculator/core/calculators/specialized_dosing_calculator.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:drug_dosage_calculator/data/patient_session.dart';
import 'package:drug_dosage_calculator/ui/iv_titration_screen.dart';
import 'package:drug_dosage_calculator/ui/calculator/models/calculator_ui_state.dart';
import 'package:drug_dosage_calculator/ui/calculator/widgets/dosage_result_card.dart';
import 'package:drug_dosage_calculator/ui/calculator/widgets/sticky_calculate_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. Adrenaline (Epinephrine) Regimen Modeling & Formularies', () {
    test('Epinephrine contains exactly 5 verified regimens including IV infusion', () {
      final epi = DrugDatabase.findById('epinephrine')!;
      expect(epi.regimens.length, equals(5));

      final routes = epi.regimens.map((r) => r.route).toSet();
      expect(routes, contains(DoseRoute.im));
      expect(routes, contains(DoseRoute.ivPush));
      expect(routes, contains(DoseRoute.ivInfusion));
    });

    test('Adult Anaphylaxis IM has 1 mg/mL dilution and calculates 0.3 mL volume', () {
      final epi = DrugDatabase.findById('epinephrine')!;
      final reg = epi.regimens.firstWhere(
        (r) => r.indication?.contains('Anaphylaxis (Adult)') == true,
      );

      expect(reg.standardDilutionMgPerMl, equals(1.0));
      expect(reg.fixedDose, equals(0.3));

      const adult = Patient(
        id: 'pt-adult-ana',
        ageYears: 30,
        weightKg: 70.0,
        heightCm: 175.0,
        sex: Sex.male,
        isScrStable: true,
      );

      final result = PharmacistCalculator.calculateDose(
        patient: adult,
        drug: epi,
        regimen: reg,
      );

      expect(result.calculatedDose, equals(0.3));
      expect(result.volumeMl, equals(0.3));
      expect(result.isBlocked, isFalse);
    });

    test('Pediatric Anaphylaxis IM has 1 mg/mL dilution, preserves calculatedDose, and flags overdose (Rule 5)', () {
      final epi = DrugDatabase.findById('epinephrine')!;
      final reg = epi.regimens.firstWhere(
        (r) => r.indication?.contains('Anaphylaxis (Pediatric)') == true,
      );

      expect(reg.standardDilutionMgPerMl, equals(1.0));
      expect(reg.dosePerKg, equals(0.01));

      // 15 kg child: 0.15 mg -> 0.15 mL, safe
      const child15 = Patient(
        id: 'pt-ped-15',
        ageYears: 3,
        weightKg: 15.0,
        heightCm: 95.0,
        sex: Sex.female,
        isScrStable: true,
      );
      final res15 = PharmacistCalculator.calculateDose(
        patient: child15,
        drug: epi,
        regimen: reg,
      );
      expect(res15.calculatedDose, closeTo(0.15, 1e-6));
      expect(res15.volumeMl, closeTo(0.15, 1e-6));
      expect(res15.warnings.any((w) => w.code == DoseWarningCode.maxSingleDoseExceeded), isFalse);

      // 35 kg child: 0.35 mg -> 0.35 mL, raw dose preserved, overdose alert fires
      const child35 = Patient(
        id: 'pt-ped-35',
        ageYears: 10,
        weightKg: 35.0,
        heightCm: 140.0,
        sex: Sex.male,
        isScrStable: true,
      );
      final res35 = PharmacistCalculator.calculateDose(
        patient: child35,
        drug: epi,
        regimen: reg,
      );
      expect(res35.calculatedDose, closeTo(0.35, 1e-6));
      expect(res35.volumeMl, closeTo(0.35, 1e-6));
      expect(res35.hasHardLimitViolation, isTrue);
      expect(res35.warnings.any((w) => w.code == DoseWarningCode.maxSingleDoseExceeded), isTrue);
    });

    test('Adult Cardiac Arrest ACLS IV Push has 0.1 mg/mL dilution and calculates 10.0 mL volume', () {
      final epi = DrugDatabase.findById('epinephrine')!;
      final reg = epi.regimens.firstWhere(
        (r) => r.indication?.contains('ACLS') == true,
      );

      expect(reg.standardDilutionMgPerMl, equals(0.1));
      expect(reg.fixedDose, equals(1.0));

      const adult = Patient(
        id: 'pt-acls',
        ageYears: 55,
        weightKg: 75.0,
        heightCm: 170.0,
        sex: Sex.male,
        isScrStable: true,
      );

      final result = PharmacistCalculator.calculateDose(
        patient: adult,
        drug: epi,
        regimen: reg,
      );

      expect(result.calculatedDose, equals(1.0));
      expect(result.volumeMl, closeTo(10.0, 1e-6));
      expect(result.isBlocked, isFalse);
    });

    test('Pediatric Cardiac Arrest PALS IV Push has 0.1 mg/mL dilution and calculates 1.5 mL for 15 kg child', () {
      final epi = DrugDatabase.findById('epinephrine')!;
      final reg = epi.regimens.firstWhere(
        (r) => r.indication?.contains('PALS') == true,
      );

      expect(reg.standardDilutionMgPerMl, equals(0.1));
      expect(reg.dosePerKg, equals(0.01));

      const child15 = Patient(
        id: 'pt-pals-15',
        ageYears: 4,
        weightKg: 15.0,
        heightCm: 100.0,
        sex: Sex.female,
        isScrStable: true,
      );

      final result = PharmacistCalculator.calculateDose(
        patient: child15,
        drug: epi,
        regimen: reg,
      );

      // 0.01 mg/kg * 15 kg = 0.15 mg; 0.15 mg / 0.1 mg/mL = 1.5 mL
      expect(result.calculatedDose, closeTo(0.15, 1e-6));
      expect(result.volumeMl, closeTo(1.5, 1e-6));
      expect(result.isBlocked, isFalse);
    });

    test('Continuous IV Infusion regimen uses mcg/kg/min and 16 mcg/mL standard bag', () {
      final epi = DrugDatabase.findById('epinephrine')!;
      final reg = epi.regimens.firstWhere(
        (r) => r.route == DoseRoute.ivInfusion,
      );

      expect(reg.rateUnit, equals(RateUnit.mcgKgMin));
      expect(reg.continuousRateUnit, equals('mcg/kg/min'));
      expect(reg.continuousRateMin, equals(0.05));
      expect(reg.continuousRateMax, equals(1.0));
      expect(reg.standardDilutionMgPerMl, equals(0.016));
      expect(reg.standardDilution?.value, equals(16.0));
      expect(reg.standardDilution?.unit, equals(ConcentrationUnit.mcgPerMl));
      expect(reg.effectiveStandardDilutionMgPerMl, equals(0.016));
    });
  });

  group('2. Nurse-Reported Dosing Scenario & SpecializedDosingCalculator Hardening', () {
    test('Nurse scenario: 60 kg patient at 0.10 mcg/kg/min in 16 mcg/mL yields EXACTLY 22.5 mL/hr', () {
      final result = SpecializedDosingCalculator.calculateVasoactiveInfusion(
        drug: 'epinephrine',
        orderedDose: 0.10,
        doseUnit: 'mcg/kg/min',
        patientWeightKg: 60.0,
        concentrationMcgPerMl: 16.0,
      );

      // Math: (0.10 mcg/kg/min * 60 kg * 60 min/hr) / 16 mcg/mL = 360 / 16 = 22.5 mL/hr
      expect(result.pumpRateMlPerHr, closeTo(22.5, 1e-6));
      expect(result.deliveredMcgKgMin, closeTo(0.10, 1e-6));
      expect(result.isCeilingExceeded, isFalse);
    });

    test('70 kg patient at 0.05 mcg/kg/min in 16 mcg/mL yields EXACTLY 13.125 mL/hr', () {
      final result = SpecializedDosingCalculator.calculateVasoactiveInfusion(
        drug: 'epinephrine',
        orderedDose: 0.05,
        doseUnit: 'mcg/kg/min',
        patientWeightKg: 70.0,
        concentrationMcgPerMl: 16.0,
      );

      // Math: (0.05 * 70 * 60) / 16 = 210 / 16 = 13.125 mL/hr
      expect(result.pumpRateMlPerHr, closeTo(13.125, 1e-6));
      expect(result.deliveredMcgKgMin, closeTo(0.05, 1e-6));
      expect(result.isCeilingExceeded, isFalse);
    });

    test('Double-strength concentration (32 mcg/mL) halves the pump rate to 11.25 mL/hr for 60 kg at 0.10', () {
      final result = SpecializedDosingCalculator.calculateVasoactiveInfusion(
        drug: 'epinephrine',
        orderedDose: 0.10,
        doseUnit: 'mcg/kg/min',
        patientWeightKg: 60.0,
        concentrationMcgPerMl: 32.0,
      );

      expect(result.pumpRateMlPerHr, closeTo(11.25, 1e-6));
      expect(result.deliveredMcgKgMin, closeTo(0.10, 1e-6));
    });

    test('Strict unit normalization handles whitespace, casing, and aliases', () {
      final res1 = SpecializedDosingCalculator.calculateVasoactiveInfusion(
        drug: 'epinephrine',
        orderedDose: 0.10,
        doseUnit: '  MCG/KG/MIN  ',
        patientWeightKg: 60.0,
        concentrationMcgPerMl: 16.0,
      );
      expect(res1.pumpRateMlPerHr, closeTo(22.5, 1e-6));

      final res2 = SpecializedDosingCalculator.calculateVasoactiveInfusion(
        drug: 'epinephrine',
        orderedDose: 0.10,
        doseUnit: 'mcg/kg/minute',
        patientWeightKg: 60.0,
        concentrationMcgPerMl: 16.0,
      );
      expect(res2.pumpRateMlPerHr, closeTo(22.5, 1e-6));

      // Absolute mcg/min: 6.0 mcg/min on 60 kg yields delivered 0.10 mcg/kg/min and 22.5 mL/hr
      final res3 = SpecializedDosingCalculator.calculateVasoactiveInfusion(
        drug: 'epinephrine',
        orderedDose: 6.0,
        doseUnit: 'mcg/min',
        patientWeightKg: 60.0,
        concentrationMcgPerMl: 16.0,
      );
      expect(res3.pumpRateMlPerHr, closeTo(22.5, 1e-6));
      expect(res3.deliveredMcgKgMin, closeTo(0.10, 1e-6));
    });

    test('Unsupported unit throws ArgumentError preventing dangerous silent fallbacks', () {
      expect(
        () => SpecializedDosingCalculator.calculateVasoactiveInfusion(
          drug: 'epinephrine',
          orderedDose: 10.0,
          doseUnit: 'mg/hr',
          patientWeightKg: 60.0,
          concentrationMcgPerMl: 16.0,
        ),
        throwsArgumentError,
      );

      expect(
        () => SpecializedDosingCalculator.calculateVasoactiveInfusion(
          drug: 'epinephrine',
          orderedDose: 5.0,
          doseUnit: 'mL/hr',
          patientWeightKg: 60.0,
          concentrationMcgPerMl: 16.0,
        ),
        throwsArgumentError,
      );
    });

    test('Rule 5 Non-Blocking Overdose Policy: Exceeding 1.0 mcg/kg/min calculates full pump rate and flags ceiling', () {
      final result = SpecializedDosingCalculator.calculateVasoactiveInfusion(
        drug: 'epinephrine',
        orderedDose: 1.50,
        doseUnit: 'mcg/kg/min',
        patientWeightKg: 70.0,
        concentrationMcgPerMl: 16.0,
      );

      // (1.50 * 70 * 60) / 16 = 6300 / 16 = 393.75 mL/hr
      expect(result.pumpRateMlPerHr, closeTo(393.75, 1e-6));
      expect(result.isCeilingExceeded, isTrue);
      expect(result.warningMessage, contains('TITRATION CEILING EXCEEDED'));
      expect(result.warningMessage, contains('Rule 5 non-blocking active'));
    });
  });

  group('3. UI Presentation & Widget Verification', () {
    testWidgets('IVTitrationScreen displays formatted mcg/mL alongside mg/mL for Epinephrine', (tester) async {
      final epi = DrugDatabase.findById('epinephrine')!;
      final infusionRegimen = epi.regimens.firstWhere(
        (r) => r.route == DoseRoute.ivInfusion,
      );

      const patient = Patient(
        id: 'pt-titrate',
        ageYears: 45,
        weightKg: 60.0,
        heightCm: 170.0,
        sex: Sex.male,
        isScrStable: true,
      );
      PatientSession.instance.setPatient(patient);

      await tester.pumpWidget(
        MaterialApp(
          home: IVTitrationScreen(
            drug: epi,
            regimen: infusionRegimen,
            isThai: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Concentration label should show: 16 mcg/mL (0.016 mg/mL) [4 mg in 250 mL]
      expect(find.textContaining('16 mcg/mL (0.016 mg/mL) [4 mg in 250 mL]'), findsOneWidget);
      // Standard bedside step 0.10 mcg/kg/min for 60 kg in 16 mcg/mL must render 22.5 mL/hr
      expect(find.text('0.10'), findsOneWidget);
      expect(find.text('22.5'), findsOneWidget);
    });

    test('Adrenaline & Thai aliases resolve to VasoactiveDrug.epinephrine and unknown drug throws ArgumentError', () {
      for (final alias in ['adrenaline', 'Adrenaline', 'อะดรีนาลิน']) {
        final res = SpecializedDosingCalculator.calculateVasoactiveInfusion(
          drug: alias,
          orderedDose: 0.10,
          doseUnit: 'mcg/kg/min',
          patientWeightKg: 60.0,
        );
        expect(res.drug, equals(VasoactiveDrug.epinephrine));
        expect(res.pumpRateMlPerHr, closeTo(22.5, 1e-6));
      }

      expect(
        () => SpecializedDosingCalculator.calculateVasoactiveInfusion(
          drug: 'unknown_drug',
          orderedDose: 0.10,
          doseUnit: 'mcg/kg/min',
          patientWeightKg: 60.0,
        ),
        throwsArgumentError,
      );
    });

    testWidgets('StickyCalculateBar hides Titration Table on IM/IV Push and shows it ONLY on titrated IV Infusion', (tester) async {
      final epi = DrugDatabase.findById('epinephrine')!;
      final imReg = epi.regimens.firstWhere((r) => r.route == DoseRoute.im);
      final ivPushReg = epi.regimens.firstWhere((r) => r.route == DoseRoute.ivPush);
      final infReg = epi.regimens.firstWhere((r) => r.route == DoseRoute.ivInfusion);

      // 1. IM Anaphylaxis (1:1,000) -> MUST NOT show Titration Table button
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StickyCalculateBar(
              drug: epi,
              selectedRegimen: imReg,
              onCalculate: () {},
              isThai: true,
            ),
          ),
        ),
      );
      expect(find.text('ตารางดริปยา'), findsNothing);

      // 2. IV Push Cardiac Arrest (1:10,000) -> MUST NOT show Titration Table button
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StickyCalculateBar(
              drug: epi,
              selectedRegimen: ivPushReg,
              onCalculate: () {},
              isThai: true,
            ),
          ),
        ),
      );
      expect(find.text('ตารางดริปยา'), findsNothing);

      // 3. Continuous IV Infusion -> MUST show Titration Table button
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StickyCalculateBar(
              drug: epi,
              selectedRegimen: infReg,
              onCalculate: () {},
              isThai: true,
            ),
          ),
        ),
      );
      expect(find.text('ตารางดริปยา'), findsOneWidget);
    });

    testWidgets('IVTitrationScreen blocks non-titrated IM regimen from rendering undiluted 1,000 mcg/mL drip table', (tester) async {
      final epi = DrugDatabase.findById('epinephrine')!;
      final imReg = epi.regimens.firstWhere((r) => r.route == DoseRoute.im);

      const patient = Patient(
        id: 'pt-im-guard',
        ageYears: 35,
        weightKg: 60.0,
        heightCm: 170.0,
        sex: Sex.female,
        isScrStable: true,
      );
      PatientSession.instance.setPatient(patient);

      await tester.pumpWidget(
        MaterialApp(
          home: IVTitrationScreen(
            drug: epi,
            regimen: imReg,
            isThai: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('iv_titration_non_titrated_guard')), findsOneWidget);
      expect(find.textContaining('1000 mcg/mL'), findsNothing);
    });

    testWidgets('DosageResultCard displays full titration range (0.05–1.0 mcg/kg/min and 11.3–225.0 mL/hr) for 60 kg Adrenaline infusion', (tester) async {
      final epi = DrugDatabase.findById('epinephrine')!;
      final infReg = epi.regimens.firstWhere((r) => r.route == DoseRoute.ivInfusion);

      const pt60 = Patient(
        id: 'pt-60-inf',
        weightKg: 60.0,
        heightCm: 168.0,
        ageYears: 45,
        sex: Sex.female,
        isScrStable: true,
      );

      final res = PharmacistCalculator.calculateDose(
        patient: pt60,
        drug: epi,
        regimen: infReg,
      );

      final state = CalculatorUiState.initial(epi).copyWith(
        selectedRegimen: infReg,
        result: res,
        warnings: res.warnings,
        status: CalculatorUiStatus.active,
        lastEvaluatedPatient: pt60,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DosageResultCard(
                state: state,
                isThai: true,
                onBuildPatient: () => pt60,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0.05–1.0 mcg/kg/min'), findsOneWidget);
      expect(find.text('Pump Rate: 11.3–225.0 mL/hr'), findsOneWidget);
    });

    testWidgets('DosageResultCard renders conspicuous volumeMl badge when volume is present', (tester) async {
      final epi = DrugDatabase.findById('epinephrine')!;
      final adultAna = epi.regimens.firstWhere(
        (r) => r.indication?.contains('Anaphylaxis (Adult)') == true,
      );

      const testPatient = Patient(
        id: 'pt-test',
        weightKg: 70.0,
        heightCm: 175.0,
        ageYears: 30,
        sex: Sex.male,
        isScrStable: true,
      );

      const result = DosageResult(
        success: true,
        calculatedDose: 0.3,
        roundedDose: 0.3,
        doseUnit: DoseUnit.mg,
        volumeMl: 0.3,
        frequency: 'Stat (repeat 5-15min PRN)',
        formulaUsed: 'Fixed Dose',
        calculationInputs: {'fixedDose': 0.3},
      );

      final state = CalculatorUiState.initial(epi).copyWith(
        selectedRegimen: adultAna,
        result: result,
        status: CalculatorUiStatus.active,
        lastEvaluatedPatient: testPatient,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DosageResultCard(
                state: state,
                isThai: false,
                onBuildPatient: () => testPatient,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dosage_result_volume_badge')), findsOneWidget);
      expect(find.textContaining('Volume to Administer: 0.30 mL'), findsOneWidget);
    });
  });
}
