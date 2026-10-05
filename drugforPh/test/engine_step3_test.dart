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
        isScrStable: true,
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
        isScrStable: true,
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
      expect(result.warnings.any((w) => w.messageEn.contains('manually entered Creatinine Clearance')), isTrue);
    });

    // -------------------------------------------------------------------------
    // 4.4 & E1: GFR-based Dosing (Calvert Independent Golden Values)
    // -------------------------------------------------------------------------
    test('E1: Calvert golden values (female 415.1 mg, male 586.8 mg, CrCl > 125 cap 750 mg)', () {
      final carboplatin = chemotherapy.firstWhere((d) => d.id == 'carboplatin');
      final regimen = carboplatin.regimens.first; // AUC 5

      // Female 60y / 70kg / 170cm / SCr 1.0 -> ~415.1 mg
      const femalePatient = Patient(
        id: 'p-calvert-f',
        weightKg: 70.0,
        heightCm: 170.0,
        ageYears: 60,
        sex: Sex.female,
        serumCreatinineMgDl: 1.0,
        isScrStable: true,
      );
      final resFemale = PharmacistCalculator.calculateDose(
        patient: femalePatient,
        drug: carboplatin,
        regimen: regimen,
      );
      expect(resFemale.success, isTrue);
      expect(resFemale.isRenallyAdjusted, isFalse);
      expect(resFemale.calculatedDose, closeTo(415.1, 0.5));

      // Male 45y / 70kg / 175cm / SCr 1.0 -> ~586.8 mg
      const malePatient = Patient(
        id: 'p-calvert-m',
        weightKg: 70.0,
        heightCm: 175.0,
        ageYears: 45,
        sex: Sex.male,
        serumCreatinineMgDl: 1.0,
        isScrStable: true,
      );
      final resMale = PharmacistCalculator.calculateDose(
        patient: malePatient,
        drug: carboplatin,
        regimen: regimen,
      );
      expect(resMale.success, isTrue);
      expect(resMale.calculatedDose, closeTo(586.8, 0.5));

      // CrCl > 125 cap: Male with high CrCl (>125 mL/min capped at 125 mL/min) -> 5 * (125 + 25) = 750 mg
      const cappedPatient = Patient(
        id: 'p-calvert-cap',
        weightKg: 85.0,
        heightCm: 185.0,
        ageYears: 22,
        sex: Sex.male,
        serumCreatinineMgDl: 0.6, // CrCl well over 125 mL/min
        isScrStable: true,
      );
      final resCapped = PharmacistCalculator.calculateDose(
        patient: cappedPatient,
        drug: carboplatin,
        regimen: regimen,
      );
      expect(resCapped.success, isTrue);
      expect(resCapped.calculatedDose, closeTo(750.0, 0.1));
    });

    // -------------------------------------------------------------------------
    // E1: Gentamicin through PharmacistCalculator Independent Golden Test
    // -------------------------------------------------------------------------
    test('E1: Gentamicin through PharmacistCalculator (100kg/170cm male/50y/SCr1.0)', () {
      const obeseGentPatient = Patient(
        id: 'p-gent-obese',
        weightKg: 100.0,
        heightCm: 170.0,
        ageYears: 50,
        sex: Sex.male,
        serumCreatinineMgDl: 1.0,
        isScrStable: true,
      );
      final gentamicin = antibiotics.firstWhere((d) => d.id == 'gentamicin');
      final regimen = gentamicin.regimens.first; // Extended-interval 5 mg/kg

      final res = PharmacistCalculator.calculateDose(
        patient: obeseGentPatient,
        drug: gentamicin,
        regimen: regimen,
      );

      expect(res.success, isTrue);
      expect(res.ibwKg, closeTo(65.94, 0.1));
      expect(res.adjBwKg, closeTo(79.56, 0.1));
      expect(res.calculatedDose, closeTo(397.8, 0.5));
      expect(res.crclMlMin, closeTo(99.4, 0.5));
      expect(res.dailyDose, closeTo(397.8, 0.5));
      expect(res.structuredFrequency, equals(Frequency.q24h));
    });

    // -------------------------------------------------------------------------
    // 4.6: Critical Renal Impairment (CrCl < 10)
    // -------------------------------------------------------------------------
    test('4.6: CrCl < 10 raises severe renal impairment warning with auto-adjustment and non-blocking guidance', () {
      const patient = Patient(
        id: 'p-esrd',
        weightKg: 70.0,
        heightCm: 170.0,
        ageYears: 70,
        sex: Sex.male,
        serumCreatinineMgDl: 8.0, // CrCl well below 10 mL/min
        isScrStable: true,
      );
      final drug = antibiotics.firstWhere((d) => d.id == 'meropenem');
      final regimen = drug.regimens.first;

      final result = PharmacistCalculator.calculateDose(
        patient: patient,
        drug: drug,
        regimen: regimen,
      );

      expect(result.warnings.any((w) => w.code == DoseWarningCode.severeRenalImpairment), isTrue);
      // Auto-adjusted to 500 mg q24h per CrCl < 10 tier
      expect(result.calculatedDose, equals(500.0));
      expect(result.structuredFrequency, equals(Frequency.q24h));
      expect(result.hasHardLimitViolation, isFalse);
      expect(result.isBlocked, isFalse);
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
        isScrStable: true,
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
        isScrStable: true,
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
