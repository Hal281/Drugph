import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/models/models.dart';
import 'package:drug_dosage_calculator/core/calculators/pharmacist_calculator.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';

void main() {
  Patient patientWithCrCl({
    required double weightKg,
    required int ageYears,
    required double scrMgDl,
    Sex sex = Sex.male,
    List<String> activeDrugIds = const [],
    List<String> allergies = const [],
  }) {
    return Patient(
      id: 'test-pt',
      ageYears: ageYears,
      weightKg: weightKg,
      heightCm: 170.0,
      sex: sex,
      serumCreatinineMgDl: scrMgDl,
      isScrStable: true,
      activeDrugIds: activeDrugIds,
      allergies: allergies,
    );
  }

  group('4 Critical Antimicrobials — DrugDatabase & PharmacistCalculator Verification', () {
    test('All 4 critical antimicrobials exist in DrugDatabase with ClinicalMonograph and honest pending verification', () {
      for (final id in ['meropenem', 'vancomycin', 'colistin', 'piperacillin_tazobactam']) {
        final drug = DrugDatabase.findById(id);
        expect(drug, isNotNull, reason: 'Missing $id in DrugDatabase');
        expect(drug!.monograph, isNotNull, reason: 'Missing ClinicalMonograph on $id');
        expect(drug.monograph!.textbookName, contains('Sanford Guide'));
        expect(drug.provenance, isNotNull, reason: 'Missing Provenance on $id');
        expect(drug.provenance!.reviewerLicense, isNull,
            reason: '$id must remain unverified until signed off by a real human pharmacist');
      }
    });

    group('1. Meropenem (Sanford Guide 2024 Table 10A / Merrem FDA Label §2.2)', () {
      late Drug mero;
      late DosingRegimen severeRegimen;

      setUp(() {
        mero = DrugDatabase.findById('meropenem')!;
        severeRegimen = mero.regimens.firstWhere((r) => r.indication == 'Severe Infection');
      });

      test('Normal renal function (CrCl > 50 mL/min) -> 1000 mg IV q8h', () {
        // 40yo male, 70kg, SCr 0.9 -> CrCl ~95 mL/min
        final pt = patientWithCrCl(weightKg: 70, ageYears: 40, scrMgDl: 0.9);
        final res = PharmacistCalculator.calculateDose(patient: pt, drug: mero, regimen: severeRegimen);

        expect(res.success, isTrue);
        expect(res.calculatedDose, equals(1000.0));
        expect(res.structuredFrequency, equals(Frequency.q8h));
        expect(res.isRenallyAdjusted, isFalse);
      });

      test('Moderate renal impairment (CrCl 26–50 mL/min) -> 1000 mg IV q12h', () {
        // 65yo male, 65kg, SCr 1.8 -> CrCl ~37.6 mL/min
        final pt = patientWithCrCl(weightKg: 65, ageYears: 65, scrMgDl: 1.8);
        final res = PharmacistCalculator.calculateDose(patient: pt, drug: mero, regimen: severeRegimen);

        expect(res.success, isTrue);
        expect(res.calculatedDose, equals(1000.0));
        expect(res.structuredFrequency, equals(Frequency.q12h));
        expect(res.isRenallyAdjusted, isTrue);
      });

      test('Severe renal impairment (CrCl 10–25 mL/min) -> 500 mg IV q12h', () {
        // 70yo male, 60kg, SCr 3.2 -> CrCl ~18.2 mL/min
        final pt = patientWithCrCl(weightKg: 60, ageYears: 70, scrMgDl: 3.2);
        final res = PharmacistCalculator.calculateDose(patient: pt, drug: mero, regimen: severeRegimen);

        expect(res.success, isTrue);
        expect(res.calculatedDose, equals(500.0));
        expect(res.structuredFrequency, equals(Frequency.q12h));
        expect(res.isRenallyAdjusted, isTrue);
      });

      test('ESRD (CrCl < 10 mL/min) -> 500 mg IV q24h', () {
        // 75yo male, 55kg, SCr 6.5 -> CrCl ~7.6 mL/min
        final pt = patientWithCrCl(weightKg: 55, ageYears: 75, scrMgDl: 6.5);
        final res = PharmacistCalculator.calculateDose(patient: pt, drug: mero, regimen: severeRegimen);

        expect(res.success, isTrue);
        expect(res.calculatedDose, equals(500.0));
        expect(res.structuredFrequency, equals(Frequency.q24h));
        expect(res.isRenallyAdjusted, isTrue);
      });

      test('Detects Contraindicated DDI with Valproic Acid (breakthrough seizure risk)', () {
        final pt = patientWithCrCl(
          weightKg: 70,
          ageYears: 40,
          scrMgDl: 0.9,
          activeDrugIds: ['valproic_acid'],
        );
        final res = PharmacistCalculator.calculateDose(patient: pt, drug: mero, regimen: severeRegimen);

        expect(
          res.warnings.any(
            (w) => w.code == DoseWarningCode.contraindicationAlert && w.severity == LimitSeverity.hard,
          ),
          isTrue,
        );
      });
    });

    group('2. Vancomycin (Sanford Guide 2024 Table 10A/10B & ASHP/IDSA 2020)', () {
      late Drug vanco;
      late DosingRegimen regimen;

      setUp(() {
        vanco = DrugDatabase.findById('vancomycin')!;
        regimen = vanco.regimens.first;
      });

      test('Normal renal function (70 kg, CrCl > 90 mL/min) -> 1050 mg (rounded to 1000 mg) q12h + Loading Phase 25 mg/kg', () {
        final pt = patientWithCrCl(weightKg: 70, ageYears: 35, scrMgDl: 0.8);
        final res = PharmacistCalculator.calculateDose(patient: pt, drug: vanco, regimen: regimen);

        expect(res.success, isTrue);
        expect(res.calculatedDose, equals(1050.0)); // 15 mg/kg * 70 kg
        expect(res.roundedDose, equals(1000.0)); // 500 mg vials
        expect(res.structuredFrequency, equals(Frequency.q12h));
        expect(regimen.phases, isNotNull);
        expect(regimen.phases!.first.dosePerKg, equals(25.0));
      });

      test('Moderate renal impairment (CrCl 20–49 mL/min) -> extends interval to q24h', () {
        // 65yo male, 65kg, SCr 2.0 -> CrCl ~33.9 mL/min
        final pt = patientWithCrCl(weightKg: 65, ageYears: 65, scrMgDl: 2.0);
        final res = PharmacistCalculator.calculateDose(patient: pt, drug: vanco, regimen: regimen);

        expect(res.success, isTrue);
        expect(res.structuredFrequency, equals(Frequency.q24h));
        expect(res.isRenallyAdjusted, isTrue);
      });

      test('ESRD (CrCl < 10 mL/min) -> triggers TDM-guided pulse redosing protocol', () {
        final pt = patientWithCrCl(weightKg: 60, ageYears: 75, scrMgDl: 6.5);
        final res = PharmacistCalculator.calculateDose(patient: pt, drug: vanco, regimen: regimen);

        expect(res.success, isTrue);
        expect(res.structuredFrequency?.isPrn, isTrue);
        expect(res.warnings.any((w) => w.code == DoseWarningCode.severeRenalImpairment), isTrue);
      });

      test('Detects Major DDI with Piperacillin/Tazobactam (Synergistic AKI)', () {
        final pt = patientWithCrCl(
          weightKg: 70,
          ageYears: 45,
          scrMgDl: 1.0,
          activeDrugIds: ['piperacillin_tazobactam'],
        );
        final res = PharmacistCalculator.calculateDose(patient: pt, drug: vanco, regimen: regimen);

        expect(
          res.warnings.any((w) =>
              w.code == DoseWarningCode.severeInteractionAlert &&
              w.messageEn.toLowerCase().contains('acute interstitial nephritis')),
          isTrue,
        );
      });
    });

    group('3. Colistin / CMS (Sanford Guide 2024 Table 10 & Tsuji et al. 2019 Consensus)', () {
      late Drug colistin;
      late DosingRegimen loadingRegimen;
      late DosingRegimen maintRegimen;

      setUp(() {
        colistin = DrugDatabase.findById('colistin')!;
        loadingRegimen = colistin.regimens.firstWhere((r) => r.indication!.contains('Loading'));
        maintRegimen = colistin.regimens.firstWhere((r) => r.indication!.contains('Maintenance'));
      });

      test('Loading dose (5 mg CBA/kg) caps at 300 mg CBA (~9 MIU) and is NOT reduced in renal failure', () {
        // 70 kg patient with severe renal failure (CrCl ~8 mL/min)
        final pt = patientWithCrCl(weightKg: 70, ageYears: 75, scrMgDl: 6.5);
        final res = PharmacistCalculator.calculateDose(patient: pt, drug: colistin, regimen: loadingRegimen);

        expect(res.success, isTrue);
        expect(res.calculatedDose, equals(300.0));
        expect(res.isBlocked, isFalse);
      });

      test('Maintenance dose adjusts across CrCl tiers per Tsuji 2019 Consensus Guidelines', () {
        // Normal CrCl (>50 mL/min) -> 150 mg CBA q12h (300 mg/day)
        final ptNormal = patientWithCrCl(weightKg: 70, ageYears: 40, scrMgDl: 0.9);
        final resNormal = PharmacistCalculator.calculateDose(patient: ptNormal, drug: colistin, regimen: maintRegimen);
        expect(resNormal.calculatedDose, equals(150.0));
        expect(resNormal.structuredFrequency, equals(Frequency.q12h));

        // CrCl 30–50 mL/min -> 110 mg CBA q12h (220 mg/day)
        final ptMod = patientWithCrCl(weightKg: 65, ageYears: 65, scrMgDl: 1.8); // CrCl ~37.6
        final resMod = PharmacistCalculator.calculateDose(patient: ptMod, drug: colistin, regimen: maintRegimen);
        expect(resMod.calculatedDose, equals(110.0));
        expect(resMod.structuredFrequency, equals(Frequency.q12h));
        expect(resMod.isRenallyAdjusted, isTrue);

        // CrCl 10–30 mL/min -> 160 mg CBA q24h
        final ptSev = patientWithCrCl(weightKg: 60, ageYears: 70, scrMgDl: 3.2); // CrCl ~18.2
        final resSev = PharmacistCalculator.calculateDose(patient: ptSev, drug: colistin, regimen: maintRegimen);
        expect(resSev.calculatedDose, equals(160.0));
        expect(resSev.structuredFrequency, equals(Frequency.q24h));
        expect(resSev.isRenallyAdjusted, isTrue);

        // CrCl < 10 mL/min -> 130 mg CBA q24h
        final ptEsrd = patientWithCrCl(weightKg: 55, ageYears: 75, scrMgDl: 6.5); // CrCl ~7.6
        final resEsrd = PharmacistCalculator.calculateDose(patient: ptEsrd, drug: colistin, regimen: maintRegimen);
        expect(resEsrd.calculatedDose, equals(130.0));
        expect(resEsrd.structuredFrequency, equals(Frequency.q24h));
        expect(resEsrd.isRenallyAdjusted, isTrue);
      });

      test('Detects Major DDI with Gentamicin (nephrotoxicity & neuromuscular blockade)', () {
        final pt = patientWithCrCl(
          weightKg: 70,
          ageYears: 40,
          scrMgDl: 0.9,
          activeDrugIds: ['gentamicin'],
        );
        final res = PharmacistCalculator.calculateDose(patient: pt, drug: colistin, regimen: maintRegimen);
        expect(res.warnings.any((w) => w.code == DoseWarningCode.severeInteractionAlert), isTrue);
      });
    });

    group('4. Piperacillin / Tazobactam (Zosyn FDA Label §2.2 & Sanford Guide 2024)', () {
      late Drug piptaz;
      late DosingRegimen regimen;

      setUp(() {
        piptaz = DrugDatabase.findById('piperacillin_tazobactam')!;
        regimen = piptaz.regimens.first;
      });

      test('Normal renal function (CrCl > 40 mL/min) -> 4.5 g IV q6h', () {
        final pt = patientWithCrCl(weightKg: 70, ageYears: 40, scrMgDl: 0.9);
        final res = PharmacistCalculator.calculateDose(patient: pt, drug: piptaz, regimen: regimen);

        expect(res.success, isTrue);
        expect(res.calculatedDose, equals(4.5));
        expect(res.doseUnit, equals(DoseUnit.g));
        expect(res.structuredFrequency, equals(Frequency.q6h));
      });

      test('CrCl 20–40 mL/min -> 3.375 g IV q6h (75% of base)', () {
        // 65yo male, 65kg, SCr 2.0 -> CrCl ~33.9 mL/min
        final pt = patientWithCrCl(weightKg: 65, ageYears: 65, scrMgDl: 2.0);
        final res = PharmacistCalculator.calculateDose(patient: pt, drug: piptaz, regimen: regimen);

        expect(res.success, isTrue);
        expect(res.calculatedDose, closeTo(3.375, 0.001));
        expect(res.structuredFrequency, equals(Frequency.q6h));
        expect(res.isRenallyAdjusted, isTrue);
      });

      test('CrCl < 20 mL/min -> 2.25 g IV q6h (50% of base)', () {
        // 70yo male, 60kg, SCr 3.2 -> CrCl ~18.2 mL/min
        final pt = patientWithCrCl(weightKg: 60, ageYears: 70, scrMgDl: 3.2);
        final res = PharmacistCalculator.calculateDose(patient: pt, drug: piptaz, regimen: regimen);

        expect(res.success, isTrue);
        expect(res.calculatedDose, closeTo(2.25, 0.001));
        expect(res.structuredFrequency, equals(Frequency.q6h));
        expect(res.isRenallyAdjusted, isTrue);
      });

      test('Detects Penicillin cross-allergy and Vancomycin Major DDI', () {
        final pt = patientWithCrCl(
          weightKg: 70,
          ageYears: 40,
          scrMgDl: 0.9,
          allergies: ['Amoxicillin'],
          activeDrugIds: ['vancomycin'],
        );
        final res = PharmacistCalculator.calculateDose(patient: pt, drug: piptaz, regimen: regimen);

        expect(res.warnings.any((w) => w.code == DoseWarningCode.allergyAlert), isTrue);
        expect(res.warnings.any((w) => w.code == DoseWarningCode.severeInteractionAlert), isTrue);
      });
    });
  });
}
