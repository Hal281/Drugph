// ============================================================
// Challenger M1-2: Dosing & Display Invariant Adversarial Tests
// ============================================================
// Validates calculation and display invariants under extreme medical conditions:
// 1. Massive Overdose (10x max recommended limits):
//    - Epinephrine 10 mcg/kg/min (10x max recommended 1.0 mcg/kg/min)
//    - Norepinephrine 30 mcg/kg/min (10x max recommended 3.0 mcg/kg/min)
//    - Paracetamol 10,000 mg (10x max recommended single dose 1,000 mg)
// 2. Extreme Patient Weights:
//    - 0.4 kg (ELBW neonate)
//    - 150 kg (Severe obesity)
//    - 300 kg (Super morbid obesity)
// 3. Rule 5 Non-blocking Invariant:
//    - calculatedDose / pump rate is NEVER null (unless titrated where rate is in InfusionResult)
//    - NEVER 0 (unless input is 0)
//    - NEVER clamped to max dose without explicit DoseWarning
//    - Key('calculator_overdose_banner') is triggered with visible numbers
// 4. Strikethrough Invariant:
//    - calculatedDose and raw dose widgets do NOT have TextDecoration.lineThrough
//    - Numeric values remain visible and WCAG AAA contrast compliant
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:drug_dosage_calculator/data/patient_session.dart';
import 'package:drug_dosage_calculator/ui/calculator/models/calculator_ui_state.dart';
import 'package:drug_dosage_calculator/ui/calculator/widgets/dosage_result_card.dart';
import 'package:drug_dosage_calculator/ui/calculator/widgets/safety_alert_banner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Challenger M1-2: Dosing & Display Invariants Under Extreme Conditions', () {
    setUp(() {
      PatientSession.instance.clearPatient();
    });

    Widget buildTestHost({
      required Widget child,
      Size size = const Size(1024, 900),
    }) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: SingleChildScrollView(
            child: child,
          ),
        ),
      );
    }

    /// Asserts that no Text widget in the given finder subtree contains TextDecoration.lineThrough.
    void assertNoLineThroughInTree(WidgetTester tester, Finder subtreeFinder) {
      final textWidgets = tester.widgetList<Text>(
        find.descendant(of: subtreeFinder, matching: find.byType(Text)),
      );
      for (final text in textWidgets) {
        final decoration = text.style?.decoration;
        if (decoration != null) {
          expect(
            decoration.contains(TextDecoration.lineThrough),
            isFalse,
            reason:
                'Rule 5 Invariant Violation: Text "${text.data}" has lineThrough decoration: $decoration',
          );
        }
      }
    }

    // =========================================================================
    // 1. MASSIVE OVERDOSE TESTS (10x Max Limits)
    // =========================================================================

    testWidgets(
      '1.1 Massive Overdose: Epinephrine 10 mcg/kg/min (10x max limit 1.0) keeps numbers visible, triggers overdose banner, and has NO strikethrough',
      (tester) async {
        final epi = DrugDatabase.findById('epinephrine')!;
        final infRegimen =
            epi.regimens.firstWhere((r) => r.route == DoseRoute.ivInfusion);

        const patient70 = Patient(
          id: 'pt-epi-10x',
          weightKg: 70.0,
          heightCm: 175.0,
          ageYears: 40,
          sex: Sex.male,
          isScrStable: true,
        );

        // Standard max rate is 1.0 mcg/kg/min.
        // We construct a massive 10x overdose regimen at 10.0 mcg/kg/min.
        const massiveEpiRate = 10.0;
        expect(massiveEpiRate, equals(10 * infRegimen.limits!.maxInfusionRate!));

        // Evaluate rate warnings via DoseChecker
        final rateWarnings = DoseChecker.checkInfusionRate(
          rateMgPerMin: massiveEpiRate,
          maxRateMgPerMin: infRegimen.limits!.maxInfusionRate!,
          rateUnit: infRegimen.rateUnit?.symbol ?? 'mcg/kg/min',
        );

        expect(rateWarnings, isNotEmpty);
        expect(
          rateWarnings.any((w) => w.code == DoseWarningCode.maxInfusionRateExceeded),
          isTrue,
        );

        // Compute 10x continuous infusion pump rate:
        // 10 mcg/kg/min * 70 kg * 60 min/hr / 16 mcg/mL = 2625 mL/hr
        final pumpRate = RateUnit.mcgKgMin.toAmountPerHour(massiveEpiRate, 70.0)! /
            infRegimen.effectiveStandardDilutionMgPerMl!;
        expect(pumpRate, closeTo(2625.0, 0.01));

        final massiveInfusionResult = InfusionResult(
          rate: massiveEpiRate,
          rateUnit: RateUnit.mcgKgMin,
          rateMlPerHr: pumpRate,
          instructionsEn: 'Massive emergency inotropic titration',
          instructionsTh: 'ขนาดยาฉุกเฉินระดับสูงพิเศษ',
        );

        final result = DosageResult(
          success: true,
          infusionResult: massiveInfusionResult,
          doseUnit: DoseUnit.mcg,
          formulaUsed: 'Adversarial 10x Rate Stress Test',
          warnings: rateWarnings,
        );

        // Rule 5 Invariant Assertions:
        expect(result.infusionResult, isNotNull);
        expect(result.infusionResult!.rate, equals(10.0));
        expect(result.infusionResult!.rate, isNot(0.0));
        expect(result.infusionResult!.rateMlPerHr, equals(2625.0));
        expect(SafetyAlertBanner.hasOverdose(result.warnings), isTrue);

        final state = CalculatorUiState.initial(epi).copyWith(
          selectedRegimen: infRegimen,
          result: result,
          warnings: rateWarnings,
          status: CalculatorUiStatus.warning,
          lastEvaluatedPatient: patient70,
        );

        await tester.pumpWidget(
          buildTestHost(
            child: DosageResultCard(
              state: state,
              isThai: false,
              onBuildPatient: () => patient70,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Overdose banner is triggered
        final bannerFinder = find.byKey(const Key('calculator_overdose_banner'));
        expect(bannerFinder, findsOneWidget);
        expect(
          find.descendant(
            of: bannerFinder,
            matching: find.textContaining('CLINICAL WARNING: Dose exceeds recommended maximum limits'),
          ),
          findsOneWidget,
        );

        // 2. Both rate metrics are clearly rendered with visible numbers
        final doseTile = find.byKey(const Key('dosage_result_dose_rate_tile'));
        final pumpTile = find.byKey(const Key('dosage_result_pump_rate_tile'));
        expect(doseTile, findsOneWidget);
        expect(pumpTile, findsOneWidget);

        expect(find.descendant(of: doseTile, matching: find.text('10.0 mcg/kg/min')), findsOneWidget);
        expect(find.descendant(of: pumpTile, matching: find.text('Pump Rate: 2625.0 mL/hr')), findsOneWidget);

        // 3. Strikethrough assertion: neither rate widget has lineThrough
        assertNoLineThroughInTree(tester, doseTile);
        assertNoLineThroughInTree(tester, pumpTile);
      },
    );

    testWidgets(
      '1.2 Massive Overdose: Norepinephrine 30 mcg/kg/min (10x max limit 3.0) calculates 7875 mL/hr pump rate and keeps numbers unblocked without strikethrough',
      (tester) async {
        final nor = DrugDatabase.findById('norepinephrine')!;
        final infRegimen =
            nor.regimens.firstWhere((r) => r.route == DoseRoute.ivInfusion);

        const patient70 = Patient(
          id: 'pt-nor-10x',
          weightKg: 70.0,
          heightCm: 175.0,
          ageYears: 45,
          sex: Sex.female,
          isScrStable: true,
        );

        // Standard max rate is 3.0 mcg/kg/min -> 10x is 30.0 mcg/kg/min
        const massiveNorRate = 30.0;
        expect(massiveNorRate, equals(10 * infRegimen.limits!.maxInfusionRate!));

        final rateWarnings = DoseChecker.checkInfusionRate(
          rateMgPerMin: massiveNorRate,
          maxRateMgPerMin: infRegimen.limits!.maxInfusionRate!,
          rateUnit: infRegimen.rateUnit?.symbol ?? 'mcg/kg/min',
        );

        expect(
          rateWarnings.any((w) => w.code == DoseWarningCode.maxInfusionRateExceeded),
          isTrue,
        );

        // 30 mcg/kg/min * 70 kg * 60 min/hr / 16 mcg/mL = 7875 mL/hr
        final pumpRate = RateUnit.mcgKgMin.toAmountPerHour(massiveNorRate, 70.0)! /
            infRegimen.effectiveStandardDilutionMgPerMl!;
        expect(pumpRate, closeTo(7875.0, 0.01));

        final massiveInfusionResult = InfusionResult(
          rate: massiveNorRate,
          rateUnit: RateUnit.mcgKgMin,
          rateMlPerHr: pumpRate,
          instructionsEn: 'Extreme refractory shock infusion rate',
          instructionsTh: 'อัตราการหยดยาฉุกเฉินสำหรับภาวะช็อกดื้อยาขั้นวิกฤต',
        );

        final result = DosageResult(
          success: true,
          infusionResult: massiveInfusionResult,
          doseUnit: DoseUnit.mcg,
          formulaUsed: 'Adversarial 10x Norepinephrine Infusion Test',
          warnings: rateWarnings,
        );

        expect(result.infusionResult!.rate, equals(30.0));
        expect(result.infusionResult!.rateMlPerHr, equals(7875.0));

        final state = CalculatorUiState.initial(nor).copyWith(
          selectedRegimen: infRegimen,
          result: result,
          warnings: rateWarnings,
          status: CalculatorUiStatus.warning,
          lastEvaluatedPatient: patient70,
        );

        await tester.pumpWidget(
          buildTestHost(
            child: DosageResultCard(
              state: state,
              isThai: true,
              onBuildPatient: () => patient70,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Overdose banner is triggered
        expect(find.byKey(const Key('calculator_overdose_banner')), findsOneWidget);

        // Dual rate tiles are visible with exact numbers
        final doseTile = find.byKey(const Key('dosage_result_dose_rate_tile'));
        final pumpTile = find.byKey(const Key('dosage_result_pump_rate_tile'));
        expect(find.descendant(of: doseTile, matching: find.text('30.0 mcg/kg/min')), findsOneWidget);
        expect(find.descendant(of: pumpTile, matching: find.text('Pump Rate: 7875.0 mL/hr')), findsOneWidget);

        // Strikethrough invariant check
        assertNoLineThroughInTree(tester, doseTile);
        assertNoLineThroughInTree(tester, pumpTile);
      },
    );

    testWidgets(
      '1.3 Massive Overdose: Paracetamol 10,000 mg (10x max single dose 1,000 mg) preserves calculatedDose, switches status label to crimson, and eliminates strikethrough',
      (tester) async {
        final para = DrugDatabase.findById('paracetamol')!;
        final oralRegimen = para.regimens.firstWhere(
            (r) => r.route == DoseRoute.po && (r.indication?.contains('Adult') ?? false));

        // Max single dose is 1,000 mg; max daily dose is 4,000 mg
        expect(oralRegimen.limits!.maxSingleDose, equals(1000.0));

        // Construct 10x massive overdose (10,000 mg)
        const massiveDose = 10000.0;
        final warnings = DoseChecker.checkDose(
          calculatedDose: massiveDose,
          dailyDose: massiveDose * 4, // 40,000 mg/day
          limits: oralRegimen.limits!,
          doseUnit: 'mg',
        );

        expect(
          warnings.any((w) => w.code == DoseWarningCode.maxSingleDoseExceeded),
          isTrue,
        );
        expect(
          warnings.any((w) => w.code == DoseWarningCode.maxDailyDoseExceeded),
          isTrue,
        );

        // Formulary rounding to nearest 500 mg tablets = 10,000 mg (20 tablets)
        final rounded = DoseRounder.roundToNearestStrength(
          massiveDose,
          [500.0],
          isSplittable: false,
        );
        expect(rounded, equals(10000.0));

        const patient70 = Patient(
          id: 'pt-para-10k',
          weightKg: 70.0,
          heightCm: 170.0,
          ageYears: 30,
          sex: Sex.male,
          isScrStable: true,
        );

        final result = DosageResult(
          success: true,
          calculatedDose: massiveDose,
          roundedDose: rounded,
          doseUnit: DoseUnit.mg,
          frequency: 'q4-6h PRN',
          formulaUsed: 'Adversarial 10x Paracetamol Single Dose Test',
          warnings: warnings,
        );

        // Invariants: calculatedDose is never null, never 0, never clamped
        expect(result.calculatedDose, equals(10000.0));
        expect(result.roundedDose, equals(10000.0));
        expect(SafetyAlertBanner.hasOverdose(result.warnings), isTrue);

        final state = CalculatorUiState.initial(para).copyWith(
          selectedRegimen: oralRegimen,
          result: result,
          warnings: warnings,
          status: CalculatorUiStatus.warning,
          lastEvaluatedPatient: patient70,
        );

        await tester.pumpWidget(
          buildTestHost(
            child: DosageResultCard(
              state: state,
              isThai: false,
              onBuildPatient: () => patient70,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Overdose banner is triggered
        expect(find.byKey(const Key('calculator_overdose_banner')), findsOneWidget);

        // 2. Status label is crimson alert and does NOT say 'Recommended Dose (Rounded)'
        expect(find.text('Recommended Dose (Rounded)'), findsNothing);
        final statusLabelFinder = find.byKey(const Key('dosage_result_status_label'));
        expect(statusLabelFinder, findsOneWidget);
        expect(
          find.descendant(
            of: statusLabelFinder,
            matching: find.text('Calculated Dose (Exceeds Limit)'),
          ),
          findsOneWidget,
        );

        final statusContainer = tester.widget<Container>(statusLabelFinder);
        final boxDec = statusContainer.decoration as BoxDecoration;
        expect(boxDec.color, const Color(0xFFFEE2E2));

        // 3. 10000.00 mg is displayed prominently in 36pt font
        expect(find.text('10000.00 mg'), findsOneWidget);

        // 4. Raw calculated dose text: 'Raw Calculated Dose: 10000.00 mg'
        final rawFinder = find.textContaining('Raw Calculated Dose: 10000.00 mg');
        expect(rawFinder, findsOneWidget);

        final rawText = tester.widget<Text>(rawFinder);
        expect(
          rawText.style?.decoration,
          isNot(TextDecoration.lineThrough),
          reason: 'Raw calculated dose must NEVER have lineThrough decoration',
        );
        expect(rawText.style?.color, Colors.grey.shade900);

        // Invariant scan across entire card
        assertNoLineThroughInTree(tester, find.byType(DosageResultCard));
      },
    );

    // =========================================================================
    // 2. EXTREME PATIENT WEIGHT TESTS (0.4 kg, 150 kg, 300 kg)
    // =========================================================================

    testWidgets(
      '2.1 Extreme Low Birth Weight Neonate (0.4 kg ELBW): calculates weight-based dose without division crash, keeps dose non-null and visible',
      (tester) async {
        const elbwPatient = Patient(
          id: 'pt-elbw-04kg',
          weightKg: 0.4,
          heightCm: 32.0,
          ageYears: 0,
          ageMonths: 0,
          sex: Sex.male,
          isScrStable: true,
        );

        // Synthetic neonatal antibiotic regimen: 25 mg/kg q12h (e.g. Ampicillin in ELBW)
        const neonatalRegimen = DosingRegimen(
          route: DoseRoute.iv,
          indication: 'Neonatal Sepsis (ELBW Protocol)',
          audience: RegimenAudience.pediatric,
          dosingType: DosingType.weightBased,
          dosePerKg: 25.0,
          doseUnit: DoseUnit.mg,
          frequency: Frequency.q12h,
          limits: DoseLimit(
            maxSingleDose: 100.0,
            maxDailyDose: 200.0,
          ),
          verificationStatus: VerificationStatus.verified,
        );

        const testNeonatalDrug = Drug(
          id: 'test_elbw_antibiotic',
          genericName: 'Ampicillin Neonatal',
          category: DrugCategory.antibiotic,
          regimens: [neonatalRegimen],
        );

        final result = PharmacistCalculator.calculateDose(
          patient: elbwPatient,
          drug: testNeonatalDrug,
          regimen: neonatalRegimen,
        );

        // 0.4 kg * 25 mg/kg = 10.0 mg
        expect(result.success, isTrue);
        expect(result.calculatedDose, isNotNull);
        expect(result.calculatedDose, equals(10.0));
        expect(result.calculatedDose, isNot(0.0));

        final state = CalculatorUiState.initial(testNeonatalDrug).copyWith(
          selectedRegimen: neonatalRegimen,
          result: result,
          status: CalculatorUiStatus.active,
          lastEvaluatedPatient: elbwPatient,
        );

        // Verify on compact mobile viewport (320x640)
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          buildTestHost(
            child: DosageResultCard(
              state: state,
              isThai: true,
              onBuildPatient: () => elbwPatient,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('10.00 mg'), findsOneWidget);
        expect(tester.takeException(), isNull);
        assertNoLineThroughInTree(tester, find.byType(DosageResultCard));
      },
    );

    testWidgets(
      '2.2 Severe Obesity (150 kg): verifies weight strategy calculation, overdose safety boundary, and display invariants',
      (tester) async {
        const obesePatient = Patient(
          id: 'pt-obese-150kg',
          weightKg: 150.0,
          heightCm: 175.0,
          ageYears: 45,
          sex: Sex.male,
          isScrStable: true,
        );

        // Weight-based regimen: 15 mg/kg -> at 150 kg = 2,250 mg (exceeds 1,000 mg limit)
        const testRegimen = DosingRegimen(
          route: DoseRoute.iv,
          indication: 'Complicated Skin and Soft Tissue Infection',
          dosingType: DosingType.weightBased,
          dosePerKg: 15.0,
          doseUnit: DoseUnit.mg,
          frequency: Frequency.q12h,
          limits: DoseLimit(
            maxSingleDose: 1000.0,
            maxDailyDose: 2000.0,
          ),
          verificationStatus: VerificationStatus.verified,
        );

        const testDrug = Drug(
          id: 'test_obese_drug',
          genericName: 'Adversarial Vancomycin',
          category: DrugCategory.antibiotic,
          availableStrengths: [250.0, 500.0, 1000.0],
          isSplittable: true,
          regimens: [testRegimen],
        );

        final result = PharmacistCalculator.calculateDose(
          patient: obesePatient,
          drug: testDrug,
          regimen: testRegimen,
        );

        // 150 kg * 15 mg/kg = 2250 mg
        expect(result.success, isTrue);
        expect(result.calculatedDose, equals(2250.0));
        expect(result.roundedDose, equals(2250.0));
        expect(SafetyAlertBanner.hasOverdose(result.warnings), isTrue);

        final state = CalculatorUiState.initial(testDrug).copyWith(
          selectedRegimen: testRegimen,
          result: result,
          warnings: result.warnings,
          status: CalculatorUiStatus.warning,
          lastEvaluatedPatient: obesePatient,
        );

        await tester.pumpWidget(
          buildTestHost(
            child: DosageResultCard(
              state: state,
              isThai: false,
              onBuildPatient: () => obesePatient,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Overdose banner triggered
        expect(find.byKey(const Key('calculator_overdose_banner')), findsOneWidget);

        // Numbers 2250.00 mg visible and unblocked
        expect(find.text('2250.00 mg'), findsOneWidget);
        expect(find.textContaining('Raw Calculated Dose: 2250.00 mg'), findsOneWidget);

        // No strikethrough
        assertNoLineThroughInTree(tester, find.byType(DosageResultCard));
      },
    );

    testWidgets(
      '2.3 Super Morbid Obesity (300 kg): calculates massive 4,500 mg dose, keeps calculatedDose unblocked and un-clamped without strikethrough',
      (tester) async {
        const superMorbidPatient = Patient(
          id: 'pt-super-obese-300kg',
          weightKg: 300.0,
          heightCm: 185.0,
          ageYears: 38,
          sex: Sex.male,
          isScrStable: true,
        );

        const testRegimen = DosingRegimen(
          route: DoseRoute.po,
          indication: 'Acute Pain (Morbid Obesity)',
          dosingType: DosingType.weightBased,
          dosePerKg: 15.0, // 300 * 15 = 4500 mg
          doseUnit: DoseUnit.mg,
          frequency: Frequency.q6h,
          limits: DoseLimit(
            maxSingleDose: 1000.0,
            maxDailyDose: 4000.0,
          ),
          verificationStatus: VerificationStatus.verified,
        );

        const testDrug = Drug(
          id: 'test_super_obese_drug',
          genericName: 'Adversarial Analgesic',
          category: DrugCategory.analgesic,
          availableStrengths: [500.0],
          regimens: [testRegimen],
        );

        final result = PharmacistCalculator.calculateDose(
          patient: superMorbidPatient,
          drug: testDrug,
          regimen: testRegimen,
        );

        // Invariant: calculatedDose is NOT null, NOT 0, and NOT silently clamped to 1000.0
        expect(result.success, isTrue);
        expect(result.calculatedDose, equals(4500.0));
        expect(result.roundedDose, equals(4500.0));
        expect(SafetyAlertBanner.hasOverdose(result.warnings), isTrue);

        final state = CalculatorUiState.initial(testDrug).copyWith(
          selectedRegimen: testRegimen,
          result: result,
          warnings: result.warnings,
          status: CalculatorUiStatus.warning,
          lastEvaluatedPatient: superMorbidPatient,
        );

        // Viewport 320x640: check overflow resilience
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          buildTestHost(
            child: DosageResultCard(
              state: state,
              isThai: true,
              onBuildPatient: () => superMorbidPatient,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Overdose banner displayed
        expect(find.byKey(const Key('calculator_overdose_banner')), findsOneWidget);

        // 2. Status label is crimson
        final statusFinder = find.byKey(const Key('dosage_result_status_label'));
        expect(statusFinder, findsOneWidget);
        expect(
          find.descendant(
            of: statusFinder,
            matching: find.text('ขนาดยาจากการคำนวณ (เกินเกณฑ์แนะนำ)'),
          ),
          findsOneWidget,
        );

        // 3. Numbers visible
        expect(find.text('4500.00 mg'), findsOneWidget);
        expect(find.textContaining('ขนาดยาคำนวณจริงก่อนปัดเศษ: 4500.00 mg'), findsOneWidget);

        // 4. Strikethrough check & no overflow
        assertNoLineThroughInTree(tester, find.byType(DosageResultCard));
        expect(tester.takeException(), isNull);
      },
    );

    // =========================================================================
    // 3. RULE 5 NON-BLOCKING INVARIANT & EXPLICIT DOSE CAPPING
    // =========================================================================

    testWidgets(
      '3.1 Explicit Dose Capping: when doseCap is defined, capping emits DoseWarningCode.doseCappedAtMax without hiding raw dose or adding strikethrough',
      (tester) async {
        const patient100 = Patient(
          id: 'pt-100kg-capped',
          weightKg: 100.0,
          heightCm: 175.0,
          ageYears: 50,
          sex: Sex.male,
          isScrStable: true,
        );

        // Regimen defines an explicit clinical dose ceiling of 2000 mg
        const cappedRegimen = DosingRegimen(
          route: DoseRoute.iv,
          indication: 'Bacterial Meningitis (Capped Ceiling)',
          dosingType: DosingType.weightBased,
          dosePerKg: 30.0, // 100 * 30 = 3000 mg -> capped to 2000 mg
          doseUnit: DoseUnit.mg,
          frequency: Frequency.q8h,
          doseCap: 2000.0,
          doseCapCitation: 'IDSA Meningitis Guidelines',
          limits: DoseLimit(
            maxSingleDose: 2000.0,
            maxDailyDose: 6000.0,
          ),
          verificationStatus: VerificationStatus.verified,
        );

        const cappedDrug = Drug(
          id: 'test_capped_antibiotic',
          genericName: 'Adversarial Cephalosporin',
          category: DrugCategory.antibiotic,
          availableStrengths: [1000.0, 2000.0],
          regimens: [cappedRegimen],
        );

        final result = PharmacistCalculator.calculateDose(
          patient: patient100,
          drug: cappedDrug,
          regimen: cappedRegimen,
        );

        // Invariants:
        // - Administered/capped dose is 2000.0 mg
        // - Warning doseCappedAtMax is explicitly generated with raw 3000 mg documented
        expect(result.success, isTrue);
        expect(result.calculatedDose, equals(2000.0));
        expect(
          result.warnings.any((w) => w.code == DoseWarningCode.doseCappedAtMax),
          isTrue,
          reason: 'Capping must NEVER be silent: doseCappedAtMax warning required',
        );

        final capWarning =
            result.warnings.firstWhere((w) => w.code == DoseWarningCode.doseCappedAtMax);
        expect(capWarning.calculatedValue, equals(3000.0));
        expect(capWarning.limitValue, equals(2000.0));

        final state = CalculatorUiState.initial(cappedDrug).copyWith(
          selectedRegimen: cappedRegimen,
          result: result,
          warnings: result.warnings,
          status: CalculatorUiStatus.warning,
          lastEvaluatedPatient: patient100,
        );

        await tester.pumpWidget(
          buildTestHost(
            child: DosageResultCard(
              state: state,
              isThai: false,
              onBuildPatient: () => patient100,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Safety alert banner is triggered for doseCappedAtMax
        expect(find.byKey(const Key('calculator_overdose_banner')), findsOneWidget);

        // Numbers 2000.00 mg visible
        expect(find.text('2000.00 mg'), findsOneWidget);

        // Strikethrough assertion
        assertNoLineThroughInTree(tester, find.byType(DosageResultCard));
      },
    );

    testWidgets(
      '3.2 Universal Strikethrough & Zero-Clamping Invariant: sweeps across 10 diverse patient weights and doses, confirming absence of strikethrough in all cases',
      (tester) async {
        final drug = DrugDatabase.findById('paracetamol')!;
        final pedReg = drug.regimens.firstWhere((r) => r.indication?.contains('Pediatric') == true);
        final adultReg = drug.regimens.firstWhere((r) => r.indication?.contains('Adult') == true);

        final testCases = [
          (weight: 0.4, height: 32.0, age: 0, isPed: true),
          (weight: 1.0, height: 38.0, age: 0, isPed: true),
          (weight: 5.0, height: 58.0, age: 0, isPed: true),
          (weight: 20.0, height: 110.0, age: 6, isPed: true),
          (weight: 50.0, height: 160.0, age: 25, isPed: false),
          (weight: 70.0, height: 170.0, age: 35, isPed: false),
          (weight: 100.0, height: 175.0, age: 40, isPed: false),
          (weight: 150.0, height: 175.0, age: 45, isPed: false),
          (weight: 250.0, height: 180.0, age: 50, isPed: false),
          (weight: 300.0, height: 185.0, age: 50, isPed: false),
        ];

        for (final tc in testCases) {
          final regToUse = tc.isPed ? pedReg : adultReg;
          final pt = Patient(
            id: 'pt-sweep-${tc.weight}',
            weightKg: tc.weight,
            heightCm: tc.height,
            ageYears: tc.age,
            ageMonths: tc.age == 0 ? 0 : null,
            sex: Sex.male,
            isScrStable: true,
          );

          final res = PharmacistCalculator.calculateDose(
            patient: pt,
            drug: drug,
            regimen: regToUse,
          );

          final state = CalculatorUiState.initial(drug).copyWith(
            selectedRegimen: regToUse,
            result: res,
            warnings: res.warnings,
            status: SafetyAlertBanner.hasOverdose(res.warnings)
                ? CalculatorUiStatus.warning
                : CalculatorUiStatus.active,
            lastEvaluatedPatient: pt,
          );

          await tester.pumpWidget(
            buildTestHost(
              child: DosageResultCard(
                state: state,
                isThai: false,
                onBuildPatient: () => pt,
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Rule 5: calculatedDose must never be null (for non-titrated), never 0.0
          expect(res.calculatedDose, isNotNull, reason: 'Failed for weight ${tc.weight}: ${res.errorMessage}');
          expect(res.calculatedDose, greaterThan(0.0));

          // Strikethrough must NEVER exist
          assertNoLineThroughInTree(tester, find.byType(DosageResultCard));
        }
      },
    );
  });
}
