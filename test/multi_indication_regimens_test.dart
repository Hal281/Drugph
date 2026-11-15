import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:drug_dosage_calculator/data/patient_session.dart';
import 'package:drug_dosage_calculator/ui/calculator/controllers/calculator_controller.dart';
import 'package:drug_dosage_calculator/ui/calculator/widgets/regimen_selector_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const adultPatient = Patient(
    id: 'p-adult-70kg',
    weightKg: 70.0,
    heightCm: 170.0,
    ageYears: 35,
    sex: Sex.male,
    serumCreatinineMgDl: 0.9,
    isScrStable: true,
  );

  const child15Kg = Patient(
    id: 'p-child-15kg',
    weightKg: 15.0,
    heightCm: 100.0,
    ageYears: 4,
    sex: Sex.male,
    isScrStable: true,
  );

  setUp(() {
    PatientSession.instance.clearPatient();
  });

  tearDown(() {
    PatientSession.instance.clearPatient();
  });

  group('Item 3 — Multi-Indication Drug Dosing Regimens', () {
    test('Cephalexin provides Adult (Standard & Severe) and Pediatric (Mild-Moderate & Otitis Media) regimens with renal tiers', () {
      final cephalexin = DrugDatabase.findById('cephalexin');
      expect(cephalexin, isNotNull);
      expect(cephalexin!.drugClass, equals(DrugClass.betaLactamCephalosporin));
      expect(cephalexin.monograph, isNotNull);
      expect(cephalexin.provenance, isNotNull);
      expect(cephalexin.regimens.length, equals(4));

      // Adult standard: 500 mg q12h -> 1,000 mg/day
      final adultStd = cephalexin.regimens[0];
      expect(adultStd.effectiveAudience, equals(RegimenAudience.adult));
      final adultStdResult = PharmacistCalculator.calculateDose(
        patient: adultPatient,
        drug: cephalexin,
        regimen: adultStd,
      );
      expect(adultStdResult.success, isTrue);
      expect(adultStdResult.calculatedDose, closeTo(500.0, 0.01));
      expect(adultStdResult.dailyDose, closeTo(1000.0, 0.01));

      // Adult severe: 500 mg q6h -> 2,000 mg/day
      final adultSevere = cephalexin.regimens[1];
      expect(adultSevere.effectiveAudience, equals(RegimenAudience.adult));
      final adultSevereResult = PharmacistCalculator.calculateDose(
        patient: adultPatient,
        drug: cephalexin,
        regimen: adultSevere,
      );
      expect(adultSevereResult.success, isTrue);
      expect(adultSevereResult.calculatedDose, closeTo(500.0, 0.01));
      expect(adultSevereResult.dailyDose, closeTo(2000.0, 0.01));

      // Adult severe renal impairment (CrCl 10 mL/min) -> 250 mg q12h
      const renalAdult = Patient(
        id: 'p-adult-renal-10',
        weightKg: 70.0,
        heightCm: 170.0,
        ageYears: 65,
        sex: Sex.male,
        creatinineClearanceMlMin: 10.0,
        isScrStable: true,
      );
      final renalResult = PharmacistCalculator.calculateDose(
        patient: renalAdult,
        drug: cephalexin,
        regimen: adultStd,
      );
      expect(renalResult.success, isTrue);
      expect(renalResult.isRenallyAdjusted, isTrue);
      expect(renalResult.calculatedDose, closeTo(250.0, 0.01));
      expect(renalResult.structuredFrequency?.displayEn, equals('q12h'));

      // Pediatric mild-moderate: 50 mg/kg/day divided q12h -> 375 mg q12h (750 mg/day) for 15 kg
      final pedMild = cephalexin.regimens[2];
      expect(pedMild.effectiveAudience, equals(RegimenAudience.pediatric));
      expect(pedMild.doseBasis, equals(DoseBasis.perDay));
      final pedMildResult = PharmacistCalculator.calculateDose(
        patient: child15Kg,
        drug: cephalexin,
        regimen: pedMild,
      );
      expect(pedMildResult.success, isTrue);
      expect(pedMildResult.calculatedDose, closeTo(375.0, 0.01));
      expect(pedMildResult.dailyDose, closeTo(750.0, 0.01));
      expect(pedMildResult.structuredFrequency?.displayEn, equals('q12h'));

      // Pediatric AOM / Severe: 75 mg/kg/day divided q6h -> 281.25 mg q6h (1,125 mg/day) for 15 kg
      final pedAom = cephalexin.regimens[3];
      expect(pedAom.effectiveAudience, equals(RegimenAudience.pediatric));
      expect(pedAom.doseBasis, equals(DoseBasis.perDay));
      final pedAomResult = PharmacistCalculator.calculateDose(
        patient: child15Kg,
        drug: cephalexin,
        regimen: pedAom,
      );
      expect(pedAomResult.success, isTrue);
      expect(pedAomResult.calculatedDose, closeTo(281.25, 0.01));
      expect(pedAomResult.dailyDose, closeTo(1125.0, 0.01));
      expect(pedAomResult.structuredFrequency?.displayEn, equals('q6h'));
    });

    test('Metronidazole supports Adult PO/IV/C. diff and Pediatric PO/IV 30 mg/kg/day divided q8h/q6h', () {
      final metro = DrugDatabase.findById('metronidazole');
      expect(metro, isNotNull);
      expect(metro!.drugClass, equals(DrugClass.nitroimidazole));
      expect(metro.monograph, isNotNull);
      expect(metro.provenance, isNotNull);
      expect(metro.regimens.length, equals(5));

      // First regimen stays Adult PO 400 mg q8h
      expect(
        metro.regimens.first.indication,
        equals('Anaerobic Infection / Trichomoniasis (Adult)'),
      );
      final adultResult = PharmacistCalculator.calculateDose(
        patient: adultPatient,
        drug: metro,
        regimen: metro.regimens.first,
      );
      expect(adultResult.success, isTrue);
      expect(adultResult.calculatedDose, closeTo(400.0, 0.01));

      // Pediatric PO: 30 mg/kg/day divided q8h -> 150 mg/dose (450 mg/day) for 15 kg
      final pedPo = metro.regimens.firstWhere(
        (r) => r.indication == 'Anaerobic Bacterial Infection (Pediatric PO)',
      );
      expect(pedPo.effectiveAudience, equals(RegimenAudience.pediatric));
      expect(pedPo.doseBasis, equals(DoseBasis.perDay));
      final pedPoResult = PharmacistCalculator.calculateDose(
        patient: child15Kg,
        drug: metro,
        regimen: pedPo,
      );
      expect(pedPoResult.success, isTrue);
      expect(pedPoResult.calculatedDose, closeTo(150.0, 0.01));
      expect(pedPoResult.dailyDose, closeTo(450.0, 0.01));
      expect(pedPoResult.structuredFrequency?.displayEn, equals('q8h'));

      // Pediatric IV: 30 mg/kg/day divided q6h -> 112.5 mg/dose (450 mg/day) for 15 kg
      final pedIv = metro.regimens.firstWhere(
        (r) => r.indication == 'Anaerobic Bacterial Infection (Pediatric IV)',
      );
      expect(pedIv.effectiveAudience, equals(RegimenAudience.pediatric));
      expect(pedIv.doseBasis, equals(DoseBasis.perDay));
      final pedIvResult = PharmacistCalculator.calculateDose(
        patient: child15Kg,
        drug: metro,
        regimen: pedIv,
      );
      expect(pedIvResult.success, isTrue);
      expect(pedIvResult.calculatedDose, closeTo(112.5, 0.01));
      expect(pedIvResult.dailyDose, closeTo(450.0, 0.01));
      expect(pedIvResult.structuredFrequency?.displayEn, equals('q6h'));
    });

    test('Ceftriaxone separates Adult (1 g / 2 g / Meningitis 2 g q12h) & Pediatric regimens, and controller defaults child to Standard Infection', () {
      final ceftriaxone = DrugDatabase.findById('ceftriaxone')!;
      expect(ceftriaxone.regimens.length, equals(5));
      expect(ceftriaxone.regimens.first.indication, equals('Severe Infection (Adult)'));

      // Adult Standard CAP/UTI: 1,000 mg q24h
      final adultStd = ceftriaxone.regimens.firstWhere(
        (r) => r.indication == 'Standard Infection / CAP / UTI (Adult)',
      );
      final adultStdRes = PharmacistCalculator.calculateDose(
        patient: adultPatient,
        drug: ceftriaxone,
        regimen: adultStd,
      );
      expect(adultStdRes.success, isTrue);
      expect(adultStdRes.calculatedDose, closeTo(1000.0, 0.01));

      // Adult Meningitis: 2,000 mg IV q12h -> 4,000 mg/day
      final adultMen = ceftriaxone.regimens.firstWhere(
        (r) => r.indication == 'Bacterial Meningitis (Adult)',
      );
      final adultMenRes = PharmacistCalculator.calculateDose(
        patient: adultPatient,
        drug: ceftriaxone,
        regimen: adultMen,
      );
      expect(adultMenRes.success, isTrue);
      expect(adultMenRes.calculatedDose, closeTo(2000.0, 0.01));
      expect(adultMenRes.dailyDose, closeTo(4000.0, 0.01));
      expect(adultMenRes.structuredFrequency?.displayEn, equals('q12h'));

      // Pediatric Standard: 50 mg/kg/day q24h -> 750 mg/dose for 15 kg
      final pedStd = ceftriaxone.regimens.firstWhere(
        (r) => r.indication == 'Standard Infection (Pediatric)',
      );
      final pedStdRes = PharmacistCalculator.calculateDose(
        patient: child15Kg,
        drug: ceftriaxone,
        regimen: pedStd,
      );
      expect(pedStdRes.success, isTrue);
      expect(pedStdRes.calculatedDose, closeTo(750.0, 0.01));
      expect(pedStdRes.dailyDose, closeTo(750.0, 0.01));

      // Pediatric Meningitis: 100 mg/kg/day divided q12h -> 750 mg/dose, 1,500 mg/day for 15 kg
      final pedMen = ceftriaxone.regimens.firstWhere(
        (r) => r.indication == 'Meningitis (Pediatric)',
      );
      final pedMenRes = PharmacistCalculator.calculateDose(
        patient: child15Kg,
        drug: ceftriaxone,
        regimen: pedMen,
      );
      expect(pedMenRes.success, isTrue);
      expect(pedMenRes.calculatedDose, closeTo(750.0, 0.01));
      expect(pedMenRes.dailyDose, closeTo(1500.0, 0.01));
      expect(pedMenRes.structuredFrequency?.displayEn, equals('q12h'));

      // Controller auto-selects Standard Infection (Pediatric), not Meningitis, for a 15 kg child
      PatientSession.instance.updateCurrentPatient(
        weightKg: 15.0,
        heightCm: 100.0,
        ageYears: 4,
        sex: Sex.male,
      );
      final controller = CalculatorController(drug: ceftriaxone);
      addTearDown(controller.dispose);
      expect(
        controller.state.selectedRegimen?.indication,
        equals('Standard Infection (Pediatric)'),
      );
      final val = controller.calculate(isThai: true);
      expect(val.isValid, isTrue);
      expect(controller.state.result?.calculatedDose, closeTo(750.0, 0.01));
    });

    test('Ciprofloxacin distinguishes cystitis (250 mg), standard UTI (500 mg), severe bone/Pseudomonas (750 mg), and IV (400 mg)', () {
      final cipro = DrugDatabase.findById('ciprofloxacin')!;
      expect(cipro.drugClass, equals(DrugClass.fluoroquinolone));
      expect(cipro.monograph, isNotNull);
      expect(cipro.provenance, isNotNull);
      expect(cipro.regimens.length, equals(4));

      final cystitis = cipro.regimens.firstWhere(
        (r) => r.indication == 'Uncomplicated Cystitis / UTI (Adult)',
      );
      final severePo = cipro.regimens.firstWhere(
        (r) => r.indication == 'Severe Pseudomonas / Bone & Joint Infection (Adult PO)',
      );

      final cysRes = PharmacistCalculator.calculateDose(
        patient: adultPatient,
        drug: cipro,
        regimen: cystitis,
      );
      expect(cysRes.success, isTrue);
      expect(cysRes.calculatedDose, closeTo(250.0, 0.01));

      final sevRes = PharmacistCalculator.calculateDose(
        patient: adultPatient,
        drug: cipro,
        regimen: severePo,
      );
      expect(sevRes.success, isTrue);
      expect(sevRes.calculatedDose, closeTo(750.0, 0.01));

      // Severe renal impairment (CrCl 20) steps down 750 mg q12h -> 500 mg q24h
      const crcl20Adult = Patient(
        id: 'p-adult-crcl20',
        weightKg: 70.0,
        heightCm: 170.0,
        ageYears: 65,
        sex: Sex.male,
        creatinineClearanceMlMin: 20.0,
        isScrStable: true,
      );
      final renalSevRes = PharmacistCalculator.calculateDose(
        patient: crcl20Adult,
        drug: cipro,
        regimen: severePo,
      );
      expect(renalSevRes.success, isTrue);
      expect(renalSevRes.isRenallyAdjusted, isTrue);
      expect(renalSevRes.calculatedDose, closeTo(500.0, 0.01));
      expect(renalSevRes.structuredFrequency?.displayEn, equals('q24h'));
    });

    test('Ibuprofen provides distinct pain vs anti-inflammatory regimens for both Adults and Pediatrics (>6 months)', () {
      final ibuprofen = DrugDatabase.findById('ibuprofen')!;
      expect(ibuprofen.regimens.length, equals(4));

      // Adult OA/RA: 600 mg PO q8h -> 1,800 mg/day
      final adultOa = ibuprofen.regimens.firstWhere(
        (r) => r.indication == 'Osteoarthritis / Rheumatoid Arthritis / Inflammatory (Adult)',
      );
      final adultOaRes = PharmacistCalculator.calculateDose(
        patient: adultPatient,
        drug: ibuprofen,
        regimen: adultOa,
      );
      expect(adultOaRes.success, isTrue);
      expect(adultOaRes.calculatedDose, closeTo(600.0, 0.01));
      expect(adultOaRes.dailyDose, closeTo(1800.0, 0.01));

      // Pediatric Fever/Pain: 10 mg/kg/dose -> 150 mg/dose for 15 kg
      final pedPain = ibuprofen.regimens.firstWhere(
        (r) => r.indication == 'Fever/Pain (Pediatric >6 months)',
      );
      final pedPainRes = PharmacistCalculator.calculateDose(
        patient: child15Kg,
        drug: ibuprofen,
        regimen: pedPain,
      );
      expect(pedPainRes.success, isTrue);
      expect(pedPainRes.calculatedDose, closeTo(150.0, 0.01));

      // Pediatric JIA: 35 mg/kg/day divided q8h -> 175 mg/dose (525 mg/day) for 15 kg
      final pedJia = ibuprofen.regimens.firstWhere(
        (r) => r.indication == 'Juvenile Idiopathic Arthritis / Inflammatory (Pediatric >6 months)',
      );
      final pedJiaRes = PharmacistCalculator.calculateDose(
        patient: child15Kg,
        drug: ibuprofen,
        regimen: pedJia,
      );
      expect(pedJiaRes.success, isTrue);
      expect(pedJiaRes.calculatedDose, closeTo(175.0, 0.01));
      expect(pedJiaRes.dailyDose, closeTo(525.0, 0.01));
      expect(pedJiaRes.structuredFrequency?.displayEn, equals('q8h'));
    });
  });

  group('Item 3 — RegimenSelectorSection UI Badges & Responsive Layout', () {
    testWidgets('Displays regimen count badge, pediatric audience pill, dose rate pill, and clinical note box', (tester) async {
      final cephalexin = DrugDatabase.findById('cephalexin')!;
      final pedAom = cephalexin.regimens.firstWhere(
        (r) => r.indication == 'Otitis Media / Severe Infection (Pediatric PO)',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RegimenSelectorSection(
                drug: cephalexin,
                selectedRegimen: pedAom,
                onRegimenChanged: (_) {},
                isThai: false,
                categoryColor: Colors.teal,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('regimen_count_badge')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('regimen_count_badge')),
          matching: find.text('4 Regimens'),
        ),
        findsOneWidget,
      );

      expect(find.byKey(const Key('regimen_audience_pill')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('regimen_audience_pill')),
          matching: find.text('Pediatric'),
        ),
        findsOneWidget,
      );

      expect(find.byKey(const Key('regimen_dose_rate_pill')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('regimen_dose_rate_pill')),
          matching: find.text('75–100 mg/kg/day'),
        ),
        findsOneWidget,
      );

      expect(find.byKey(const Key('regimen_clinical_note_box')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('regimen_clinical_note_box')),
          matching: find.textContaining('75–100 mg/kg/day'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Switches cleanly to Thai labels and Adult fixed-dose pill without overflow on 320x480 screen', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cephalexin = DrugDatabase.findById('cephalexin')!;
      final adultStd = cephalexin.regimens.first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: RegimenSelectorSection(
                drug: cephalexin,
                selectedRegimen: adultStd,
                onRegimenChanged: (_) {},
                isThai: true,
                categoryColor: Colors.indigo,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.descendant(
          of: find.byKey(const Key('regimen_count_badge')),
          matching: find.text('4 สูตร'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('regimen_audience_pill')),
          matching: find.text('ผู้ใหญ่ (Adult)'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('regimen_dose_rate_pill')),
          matching: find.text('500 mg/ครั้ง'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('regimen_clinical_note_box')), findsOneWidget);
    });
  });
}
