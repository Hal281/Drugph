import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/models/models.dart';
import 'package:drug_dosage_calculator/core/calculators/pharmacist_calculator.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';

void main() {
  group('Smart Dose Capping & Non-blocking Clinical Advisory Tests', () {
    const adult70Kg = Patient(
      id: 'p-70kg-tb',
      ageYears: 35,
      weightKg: 70.0,
      heightCm: 175.0,
      sex: Sex.male,
      serumCreatinineMgDl: 0.9,
      isScrStable: true,
    );

    // =========================================================================
    // 1. Weight-Based Dose Capping with Rich Clinical Alternatives
    // =========================================================================
    group('Weight-based dose capping', () {
      test('Rifampin (10 mg/kg): 70 kg patient calculates 700 mg raw, auto-caps to 600 mg, unblocked', () {
        final rifampin = DrugDatabase.findById('rifampin')!;
        final regimen = rifampin.regimens.first;

        final res = PharmacistCalculator.calculateDose(
          patient: adult70Kg,
          drug: rifampin,
          regimen: regimen,
        );

        // Core invariants
        expect(res.success, isTrue);
        expect(res.calculatedDose, equals(600.0), reason: 'Dose must be capped at 600 mg');
        expect(res.isBlocked, isFalse, reason: 'Auto-capped dose must NOT block the order');
        expect(res.hasHardLimitViolation, isFalse);

        // Warning inspection
        final capWarning = res.warnings.firstWhere(
          (w) => w.code == DoseWarningCode.doseCappedAtMax,
          orElse: () => throw TestFailure('Expected doseCappedAtMax warning not found'),
        );

        expect(capWarning.severity, equals(LimitSeverity.soft));
        expect(capWarning.calculatedValue, equals(700.0), reason: 'Records raw un-capped dose');
        expect(capWarning.limitValue, equals(600.0), reason: 'Records cap ceiling');
        expect(capWarning.messageEn, contains('Raw weight-based calculation is 700 mg'));
        expect(capWarning.messageEn, contains('exceeds the guideline ceiling of 600 mg'));
        expect(capWarning.messageTh, contains('700'));
        expect(capWarning.messageTh, contains('600'));

        // Clinical alternatives
        expect(capWarning.clinicalAlternativesEn, isNotNull);
        expect(capWarning.clinicalAlternativesEn!.length, greaterThanOrEqualTo(2));
        expect(capWarning.clinicalAlternativesEn![0], contains('Standard Ceiling'));
        expect(capWarning.clinicalAlternativesEn![1], contains('Clinician Override'));
        expect(capWarning.clinicalAlternativesTh![0], contains('ขนาดยามาตรฐานสูงสุด'));
        expect(capWarning.clinicalAlternativesTh![1], contains('ขอยกเว้นเฉพาะราย'));
      });

      test('Isoniazid (5 mg/kg): 70 kg patient calculates 350 mg raw, auto-caps to 300 mg, unblocked', () {
        final inh = DrugDatabase.findById('isoniazid')!;
        final regimen = inh.regimens.first;

        final res = PharmacistCalculator.calculateDose(
          patient: adult70Kg,
          drug: inh,
          regimen: regimen,
        );

        expect(res.success, isTrue);
        expect(res.calculatedDose, equals(300.0), reason: 'Dose must be capped at 300 mg');
        expect(res.isBlocked, isFalse);
        expect(res.hasHardLimitViolation, isFalse);

        final capWarning = res.warnings.firstWhere(
          (w) => w.code == DoseWarningCode.doseCappedAtMax,
        );
        expect(capWarning.calculatedValue, equals(350.0));
        expect(capWarning.limitValue, equals(300.0));
      });

      test('Colistin loading (5 mg/kg): 70 kg patient calculates 350 mg raw, auto-caps to 300 mg, unblocked', () {
        final colistin = DrugDatabase.findById('colistin')!;
        final loadingRegimen = colistin.regimens.firstWhere(
          (r) => r.indication?.contains('Loading') ?? false,
        );

        final res = PharmacistCalculator.calculateDose(
          patient: adult70Kg,
          drug: colistin,
          regimen: loadingRegimen,
        );

        expect(res.success, isTrue);
        expect(res.calculatedDose, equals(300.0), reason: 'Loading dose must be capped at 300 mg CBA');
        expect(res.isBlocked, isFalse);
        expect(res.hasHardLimitViolation, isFalse);

        final capWarning = res.warnings.firstWhere(
          (w) => w.code == DoseWarningCode.doseCappedAtMax,
        );
        expect(capWarning.calculatedValue, equals(350.0));
        expect(capWarning.limitValue, equals(300.0));
      });

      test('Order verification: Ordering 600 mg Rifampin for 70 kg patient has 0% deviation and is acceptable', () {
        final rifampin = DrugDatabase.findById('rifampin')!;
        final regimen = rifampin.regimens.first;

        final verify = PharmacistCalculator.verifyOrder(
          patient: adult70Kg,
          drug: rifampin,
          regimen: regimen,
          orderedDose: 600.0,
          orderedFrequency: Frequency.q24h,
        );

        expect(verify.isAcceptable, isTrue);
        expect(verify.deviationPercent, closeTo(0.0, 0.001));
        expect(verify.warnings.any((w) => w.code == DoseWarningCode.maxSingleDoseExceeded), isFalse);
      });
    });

    // =========================================================================
    // 2. Vancomycin ESRD / Hemodialysis (CrCl < 10 mL/min)
    // =========================================================================
    group('Vancomycin ESRD / Hemodialysis tier', () {
      const esrdPatient = Patient(
        id: 'p-esrd-vanc',
        ageYears: 65,
        weightKg: 70.0,
        heightCm: 170.0,
        sex: Sex.male,
        serumCreatinineMgDl: 8.5, // CrCl ~ 8 mL/min (< 10)
        isScrStable: true,
      );

      test('CrCl < 10 matches explicit [0, 10) tier with TDM pulse dosing instructions without blocking', () {
        final vanc = DrugDatabase.findById('vancomycin')!;
        final regimen = vanc.regimens.first;

        final res = PharmacistCalculator.calculateDose(
          patient: esrdPatient,
          drug: vanc,
          regimen: regimen,
        );

        expect(res.success, isTrue);
        expect(res.isBlocked, isFalse, reason: 'Vancomycin ESRD TDM dosing must NOT be blocked');
        expect(res.hasHardLimitViolation, isFalse);
        expect(res.isRenallyAdjusted, isTrue);

        // Structured frequency should reflect TDM pulse dosing
        expect(res.structuredFrequency?.isPrn, isTrue);
        expect(res.structuredFrequency?.displayEn, contains('TDM'));

        // Renal notes contain explicit clinical loading & redosing guidance
        expect(res.renalNotes, contains('Loading dose 20-25 mg/kg'));
        expect(res.renalNotes, contains('500-1000 mg'));
        expect(res.renalNotes, contains('15-20 mcg/mL'));

        // Warning contains non-blocking advisory
        final renalWarn = res.warnings.firstWhere(
          (w) => w.code == DoseWarningCode.severeRenalImpairment,
        );
        expect(renalWarn.severity, equals(LimitSeverity.soft));
        expect(renalWarn.messageEn, contains('ESRD / HEMODIALYSIS'));
      });
    });

    // =========================================================================
    // 3. Carboplatin (Calvert) in Severe Renal Impairment (CrCl < 15 mL/min)
    // =========================================================================
    group('Carboplatin Calvert severe renal advisory', () {
      const severeRenalPatient = Patient(
        id: 'p-carboplatin-crcl10',
        ageYears: 60,
        weightKg: 60.0,
        heightCm: 165.0,
        sex: Sex.female,
        creatinineClearanceMlMin: 10.0, // Manual CrCl = 10 mL/min (< 15)
        isScrStable: true,
      );

      test('Carboplatin CrCl = 10 calculates Calvert dose (175 mg) with non-blocking advisory', () {
        final carbo = DrugDatabase.findById('carboplatin')!;
        final regimen = carbo.regimens.first;

        final res = PharmacistCalculator.calculateDose(
          patient: severeRenalPatient,
          drug: carbo,
          regimen: regimen,
        );

        // Calvert formula: AUC 5 * (10 + 25) = 175 mg
        expect(res.success, isTrue);
        expect(res.calculatedDose, equals(175.0));
        expect(res.isBlocked, isFalse, reason: 'Carboplatin must NOT be hard blocked');
        expect(res.hasHardLimitViolation, isFalse);

        // Advisory warning
        final advisory = res.warnings.firstWhere(
          (w) => w.code == DoseWarningCode.severeRenalImpairment,
        );
        expect(advisory.severity, equals(LimitSeverity.soft));
        expect(advisory.messageEn, contains('SEVERE RENAL IMPAIRMENT'));
        expect(advisory.clinicalAlternativesEn, isNotNull);
        expect(advisory.clinicalAlternativesEn!.any((a) => a.contains('Target AUC Reduction')), isTrue);
        expect(advisory.clinicalAlternativesEn!.any((a) => a.contains('Hematologic Monitoring')), isTrue);
      });
    });

    // =========================================================================
    // 4. Clinical Model: Non-Blocking Renal Adjustments & Strict Hard Stops
    // =========================================================================
    group('Clinical Decision Support Hierarchy (Safe Defaults & Strict Hard Stops)', () {
      test('Meropenem at CrCl < 10 auto-adjusts to 500 mg q24h with non-blocking ESRD advisory', () {
        const esrdPatient = Patient(
          id: 'p-esrd-mero',
          ageYears: 70,
          weightKg: 70.0,
          heightCm: 170.0,
          sex: Sex.male,
          serumCreatinineMgDl: 8.0,
          isScrStable: true,
        );
        final mero = DrugDatabase.findById('meropenem')!;
        final regimen = mero.regimens.first;

        final res = PharmacistCalculator.calculateDose(
          patient: esrdPatient,
          drug: mero,
          regimen: regimen,
        );

        expect(res.warnings.any((w) => w.code == DoseWarningCode.severeRenalImpairment), isTrue);
        expect(res.calculatedDose, equals(500.0), reason: 'Adjusted to 500 mg for CrCl < 10');
        expect(res.structuredFrequency, equals(Frequency.q24h));
        expect(res.hasHardLimitViolation, isFalse);
        expect(res.isBlocked, isFalse, reason: 'Patient in ESRD can safely receive adjusted 500 mg q24h');
      });

      test('Missing SCr on renal drug emits non-blocking soft advisory for STAT first-dose emergent use', () {
        const patientNoScr = Patient(
          id: 'p-stat-noscr',
          ageYears: 50,
          weightKg: 70.0,
          heightCm: 170.0,
          sex: Sex.male,
          isScrStable: true,
        );
        final ceftazidime = DrugDatabase.findById('ceftazidime')!;
        final regimen = ceftazidime.regimens.first;

        final res = PharmacistCalculator.calculateDose(
          patient: patientNoScr,
          drug: ceftazidime,
          regimen: regimen,
        );

        expect(res.warnings.any((w) => w.code == DoseWarningCode.scrMissing), isTrue);
        final scrWarn = res.warnings.firstWhere((w) => w.code == DoseWarningCode.scrMissing);
        expect(scrWarn.severity, equals(LimitSeverity.soft));
        expect(scrWarn.clinicalAlternativesEn, isNotNull);
        expect(scrWarn.clinicalAlternativesEn!.any((a) => a.contains('STAT / Initial Empiric Dose')), isTrue);
        expect(res.hasHardLimitViolation, isFalse);
        expect(res.isBlocked, isFalse, reason: 'Does not block emergent initial dosing');
      });

      test('Strict Hard Stop: Severe Anaphylactic Allergy match remains strictly blocked', () {
        const allergicPatient = Patient(
          id: 'p-allergy',
          ageYears: 30,
          weightKg: 65.0,
          heightCm: 165.0,
          sex: Sex.female,
          serumCreatinineMgDl: 0.8,
          isScrStable: true,
          allergies: ['Penicillin'],
        );
        final amoxClav = DrugDatabase.findById('amoxicillin_clavulanate')!;
        final res = PharmacistCalculator.calculateDose(
          patient: allergicPatient,
          drug: amoxClav,
          regimen: amoxClav.regimens.first,
        );

        expect(res.warnings.any((w) => w.code == DoseWarningCode.allergyAlert), isTrue);
        expect(res.hasHardLimitViolation, isTrue);
        expect(res.isBlocked, isTrue, reason: 'Severe allergy must strictly block');
      });

      test('Strict Hard Stop: Contraindicated DDI (Meropenem + Valproate) remains strictly blocked', () {
        const ddiPatient = Patient(
          id: 'p-ddi',
          ageYears: 40,
          weightKg: 70.0,
          heightCm: 170.0,
          sex: Sex.male,
          serumCreatinineMgDl: 0.9,
          isScrStable: true,
          activeDrugIds: ['valproic_acid'],
        );
        final mero = DrugDatabase.findById('meropenem')!;
        final res = PharmacistCalculator.calculateDose(
          patient: ddiPatient,
          drug: mero,
          regimen: mero.regimens.first,
        );

        expect(res.warnings.any((w) => w.code == DoseWarningCode.contraindicationAlert), isTrue);
        expect(res.hasHardLimitViolation, isTrue);
        expect(res.isBlocked, isTrue, reason: 'Fatal DDI must strictly block');
      });

      test('Strict Hard Stop: Absolute Contraindication (Metformin CrCl < 30) remains strictly blocked', () {
        const severeRenalMetforminPatient = Patient(
          id: 'p-metformin-crcl20',
          ageYears: 65,
          weightKg: 70.0,
          heightCm: 170.0,
          sex: Sex.male,
          serumCreatinineMgDl: 3.5, // CrCl ~ 20 (< 30)
          isScrStable: true,
        );
        final metformin = DrugDatabase.findById('metformin')!;
        final res = PharmacistCalculator.calculateDose(
          patient: severeRenalMetforminPatient,
          drug: metformin,
          regimen: metformin.regimens.first,
        );

        expect(res.warnings.any((w) => w.code == DoseWarningCode.contraindicationAlert), isTrue);
        expect(res.hasHardLimitViolation, isTrue);
        expect(res.isBlocked, isTrue, reason: 'Metformin lactic acidosis contraindication must strictly block');
      });
    });
  });
}

