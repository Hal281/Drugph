import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/models/models.dart';
import 'package:drug_dosage_calculator/core/calculators/pharmacist_calculator.dart';
import 'package:drug_dosage_calculator/data/drugs/antibiotics.dart';
import 'package:drug_dosage_calculator/data/drugs/chemotherapy.dart';

void main() {
  group('Step 3: Clinical Engine Refactor & PharmacistCalculator', () {
    // -------------------------------------------------------------------------
    // A1: Drug.findRegimen
    // -------------------------------------------------------------------------
    test('A1: findRegimen returns null on invalid indication without silent fallback', () {
      final meropenem = antibiotics.firstWhere((d) => d.id == 'meropenem');
      // Requesting non-existent indication must return null
      final notFound = meropenem.findRegimen(DoseRoute.iv, 'NonExistentIndication');
      expect(notFound, isNull);

      // Route with multiple indications and none specified must return null (force selection)
      // meropenem has 'Severe infection' and 'Meningitis' for iv
      final unselected = meropenem.findRegimen(DoseRoute.iv);
      expect(unselected, isNull);

      // Exact match works
      final meningitis = meropenem.findRegimen(DoseRoute.iv, 'Meningitis');
      expect(meningitis, isNotNull);
      expect(meningitis!.indication, equals('Meningitis'));
    });

    // -------------------------------------------------------------------------
    // 4.1: Pediatric Block
    // -------------------------------------------------------------------------
    test('4.1: Pediatric patients (< 18 years) are blocked by the adult dosing engine', () {
      const child = Patient(
        id: 'p-child',
        weightKg: 25.0,
        heightCm: 120.0,
        ageYears: 10,
        sex: Sex.male,
      );
      final drug = antibiotics.firstWhere((d) => d.id == 'amoxicillin_clavulanate');
      final regimen = drug.regimens.first;

      final result = PharmacistCalculator.calculateDose(
        patient: child,
        drug: drug,
        regimen: regimen,
      );

      expect(result.success, isFalse);
      expect(result.isBlocked, isTrue);
      expect(result.warnings.any((w) => w.code == DoseWarningCode.pediatricBlocked), isTrue);
    });

    // -------------------------------------------------------------------------
    // 4.1 & A11: Unstable SCr Alert
    // -------------------------------------------------------------------------
    test('4.1 & A11: Unstable SCr halts automated renal adjustment and raises hard warning', () {
      const patient = Patient(
        id: 'p-aki',
        weightKg: 70.0,
        heightCm: 170.0,
        ageYears: 60,
        sex: Sex.male,
        serumCreatinineMgDl: 2.5,
        isScrStable: false, // Acute Kidney Injury / unstable
      );
      final drug = antibiotics.firstWhere((d) => d.id == 'meropenem');
      final regimen = drug.regimens.first;

      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: drug,
        regimen: regimen,
      );

      expect(result.isRenallyAdjusted, isFalse);
      expect(result.warnings.any((w) => w.code == DoseWarningCode.unstableScr), isTrue);
      expect(result.hasHardLimitViolation, isTrue);
    });

    // -------------------------------------------------------------------------
    // A5: Manually Entered CrCl
    // -------------------------------------------------------------------------
    test('A5: Honors patient.creatinineClearanceMlMin when SCr is absent', () {
      const patient = Patient(
        id: 'p-crcl',
        weightKg: 70.0,
        heightCm: 170.0,
        ageYears: 50,
        sex: Sex.male,
        serumCreatinineMgDl: null,
        creatinineClearanceMlMin: 20.0, // Entered manually
      );
      final drug = antibiotics.firstWhere((d) => d.id == 'meropenem');
      final regimen = drug.regimens.first;

      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: drug,
        regimen: regimen,
      );

      expect(result.crclMlMin, equals(20.0));
      expect(result.isRenallyAdjusted, isTrue);
    });

    // -------------------------------------------------------------------------
    // 4.4: GFR-based Dosing (Calvert)
    // -------------------------------------------------------------------------
    test('4.4: Calvert formula uses CrCl directly without secondary renal factor reduction', () {
      const patient = Patient(
        id: 'p-chemo',
        weightKg: 70.0,
        heightCm: 170.0,
        ageYears: 60,
        sex: Sex.female,
        serumCreatinineMgDl: 1.0,
      );
      final carboplatin = chemotherapy.firstWhere((d) => d.id == 'carboplatin');
      final regimen = carboplatin.regimens.first;

      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: drugWithCalvert(carboplatin),
        regimen: regimen,
      );

      expect(result.success, isTrue);
      expect(result.isRenallyAdjusted, isFalse, reason: 'Calvert already accounts for renal function');
      expect(result.calculatedDose, greaterThan(0));
    });

    // -------------------------------------------------------------------------
    // 4.6: Critical Renal Impairment (CrCl < 10)
    // -------------------------------------------------------------------------
    test('4.6: CrCl < 10 raises severe renal impairment hard warning', () {
      const patient = Patient(
        id: 'p-esrd',
        weightKg: 70.0,
        heightCm: 170.0,
        ageYears: 70,
        sex: Sex.male,
        serumCreatinineMgDl: 8.0, // CrCl well below 10 mL/min
      );
      final drug = antibiotics.firstWhere((d) => d.id == 'meropenem');
      final regimen = drug.regimens.first;

      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: drug,
        regimen: regimen,
      );

      expect(result.warnings.any((w) => w.code == DoseWarningCode.severeRenalImpairment), isTrue);
      expect(result.hasHardLimitViolation, isTrue);
      expect(result.isBlocked, isTrue);
    });

    // -------------------------------------------------------------------------
    // A8: Allergy Alert
    // -------------------------------------------------------------------------
    test('A8: Allergy match against drug allergyClass raises hard allergy alert and blocks', () {
      const patient = Patient(
        id: 'p-allergic',
        weightKg: 65.0,
        heightCm: 165.0,
        ageYears: 40,
        sex: Sex.female,
        allergies: ['Penicillin'],
      );
      final amox = antibiotics.firstWhere((d) => d.id == 'amoxicillin_clavulanate');
      final regimen = amox.regimens.first;

      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: amox,
        regimen: regimen,
      );

      expect(result.warnings.any((w) => w.code == DoseWarningCode.allergyAlert), isTrue);
      expect(result.hasHardLimitViolation, isTrue);
      expect(result.isBlocked, isTrue);
    });

    // -------------------------------------------------------------------------
    // B2: Audit Trail Data Populated
    // -------------------------------------------------------------------------
    test('B2: Populates all audit metadata in DosageResult', () {
      const patient = Patient(
        id: 'p-audit',
        weightKg: 100.0,
        heightCm: 170.0, // Obese
        ageYears: 50,
        sex: Sex.male,
        serumCreatinineMgDl: 1.0,
      );
      final gentamicin = antibiotics.firstWhere((d) => d.id == 'gentamicin');
      final regimen = gentamicin.regimens.first;

      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: gentamicin,
        regimen: regimen,
      );

      expect(result.formulaUsed, isNotEmpty);
      expect(result.calculationInputs, isNotEmpty);
      expect(result.ibwKg, isNotNull);
      expect(result.adjBwKg, isNotNull);
      expect(result.dailyDose, isNotNull);
    });
  });
}

Drug drugWithCalvert(Drug base) => base;
