import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/models/models.dart';
import 'package:drug_dosage_calculator/core/calculators/pharmacist_calculator.dart';
import 'package:drug_dosage_calculator/core/calculators/weight_based_calculator.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';

void main() {
  group('Addendum D: Comprehensive Architecture & Safety Engine Tests', () {
    const adultPatient = Patient(
      id: 'patient-adult-1',
      ageYears: 45,
      weightKg: 70.0,
      heightCm: 175.0,
      sex: Sex.male,
      serumCreatinineMgDl: 1.0,
    );

    const pediatricPatient = Patient(
      id: 'patient-ped-1',
      ageYears: 8,
      weightKg: 25.0,
      heightCm: 125.0,
      sex: Sex.male,
      serumCreatinineMgDl: 0.5,
    );

    // =========================================================================
    // D0 & D7: Single Engine & verifyOrder
    // =========================================================================
    test('D0 & D7: PharmacistCalculator.verifyOrder verifies clinician prescribed dose', () {
      final amox = DrugDatabase.findById('amoxicillin_clavulanate')!;
      final reg = amox.regimens.first;

      // Prescribed 1000 mg within limits
      final safeOrder = PharmacistCalculator.verifyOrder(
        patient: adultPatient,
        drug: amox,
        regimen: reg,
        orderedDose: 1000.0,
        orderedFrequency: Frequency.q12h,
      );
      expect(safeOrder.isAcceptable, isTrue);

      // Prescribed 5000 mg exceeds max single/daily dose -> blocked
      final dangerousOrder = PharmacistCalculator.verifyOrder(
        patient: adultPatient,
        drug: amox,
        regimen: reg,
        orderedDose: 5000.0,
        orderedFrequency: Frequency.q12h,
      );
      expect(dangerousOrder.isAcceptable, isFalse);
      expect(dangerousOrder.warnings.any((w) => w.severity == LimitSeverity.hard), isTrue);
    });

    // =========================================================================
    // D1: Structured Frequency and DoseBasis
    // =========================================================================
    test('D1: Structured Frequency derives dosesPerDay and DoseBasis.perDay divides dose', () {
      expect(Frequency.q8h.dosesPerDay, equals(3.0));
      expect(Frequency.q12h.dosesPerDay, equals(2.0));
      expect(Frequency.q6h.dosesPerDay, equals(4.0));
      expect(Frequency.q24h.dosesPerDay, equals(1.0));

      const dailyRegimen = DosingRegimen(
        route: DoseRoute.po,
        indication: 'Daily Basis Test',
        dosingType: DosingType.fixed,
        fixedDose: 1200.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q8h,
        doseBasis: DoseBasis.perDay, // 1200 mg/day divided q8h (3 doses) = 400 mg/dose
      );

      const testDrug = Drug(
        id: 'test_daily_drug',
        genericName: 'Test Daily Drug',
        category: DrugCategory.antibiotic,
        regimens: [dailyRegimen],
      );

      final res = PharmacistCalculator.calculateDose(
        patient: adultPatient,
        drug: testDrug,
        regimen: dailyRegimen,
      );

      expect(res.success, isTrue);
      expect(res.calculatedDose, equals(400.0));
    });

    // =========================================================================
    // D2: Titrated Infusion with InfusionResult
    // =========================================================================
    test('D2: Titrated continuous regimen returns InfusionResult and sets calculatedDose to null', () {
      final heparin = DrugDatabase.findById('heparin')!;
      final reg = heparin.regimens.first;

      final res = PharmacistCalculator.calculateDose(
        patient: adultPatient,
        drug: heparin,
        regimen: reg,
      );

      expect(res.success, isTrue);
      expect(res.calculatedDose, isNull, reason: 'Titrated continuous infusion must not return a bare dose');
      expect(res.roundedDose, isNull);
      expect(res.infusionResult, isNotNull);
      expect(res.infusionResult!.rate, equals(18.0));
      expect(res.infusionResult!.rateUnit, equals(RateUnit.uKgHr));
    });

    // =========================================================================
    // D3: Phases - Quetiapine, Apixaban, NAC, Vancomycin
    // =========================================================================
    test('D3: Quetiapine starting dose is 50 mg and defines structured titration phases', () {
      final quetiapine = DrugDatabase.findById('quetiapine')!;
      final reg = quetiapine.regimens.first;

      expect(reg.fixedDose, equals(50.0), reason: 'Starting dose must not be target 300 mg');
      expect(reg.phases, isNotNull);
      expect(reg.phases!.length, greaterThanOrEqualTo(3));
      expect(reg.phases!.first.role, equals(DoseRole.start));
      expect(reg.phases!.any((p) => p.role == DoseRole.usual), isTrue);
      expect(reg.phases!.any((p) => p.role == DoseRole.max), isTrue);
    });

    test('D3: Apixaban DVT/PE regimen defines 7-day loading phase then 5 mg maintenance', () {
      final apixaban = DrugDatabase.findById('apixaban')!;
      final dvtReg = apixaban.regimens.firstWhere((r) => r.indication?.contains('DVT/PE') == true);

      expect(dvtReg.phases, isNotNull);
      expect(dvtReg.phases!.first.durationDays, equals(7));
      expect(dvtReg.phases!.first.dose, equals(10.0));
      expect(dvtReg.phases![1].dose, equals(5.0));
    });

    // =========================================================================
    // D4: Population Applicability & Adult Safety Gate (4.1)
    // =========================================================================
    test('D4 & 4.1: Adult regimen blocks and warns when prescribed to pediatric patient (< 18 yrs)', () {
      final vanco = DrugDatabase.findById('vancomycin')!;
      final adultReg = vanco.regimens.first;

      final res = PharmacistCalculator.calculateDose(
        patient: pediatricPatient,
        drug: vanco,
        regimen: adultReg,
      );

      // Must be blocked with pediatric blocked warning
      expect(res.isBlocked, isTrue);
      expect(res.success, isFalse);
      expect(res.warnings.any((w) => w.code == DoseWarningCode.pediatricBlocked), isTrue);
    });

    // =========================================================================
    // D5: Contiguous Half-Open Renal Ranges & GFR Exemption (4.2)
    // =========================================================================
    test('D5: Half-open range [20, 50) seamlessly handles boundary CrCl without gap', () {
      const tier = RenalAdjustment(
        crclMin: 20.0,
        crclMax: 50.0,
        action: RenalAction.adjust,
        adjustmentFactor: 0.5,
      );

      expect(tier.appliesTo(20.0), isTrue, reason: 'Inclusive lower bound');
      expect(tier.appliesTo(25.5), isTrue, reason: 'Decimal value in interval');
      expect(tier.appliesTo(49.99), isTrue, reason: 'Value just below upper bound');
      expect(tier.appliesTo(50.0), isFalse, reason: 'Exclusive upper bound');
      expect(tier.appliesTo(19.99), isFalse);
    });

    test('D5 & 4.2: Calvert formula for Carboplatin does NOT apply secondary renal factor', () {
      final carboplatin = DrugDatabase.findById('carboplatin')!;
      final reg = carboplatin.regimens.first;

      final res = PharmacistCalculator.calculateDose(
        patient: adultPatient,
        drug: carboplatin,
        regimen: reg,
      );

      expect(res.success, isTrue);
      expect(res.isRenallyAdjusted, isFalse, reason: 'Calvert formula already integrates GFR; must not double-count renal reduction');
      // Target AUC 5 with normal CrCl
      final expectedDose = WeightBasedCalculator.calvertFormula(targetAuc: 5.0, gfrMlMin: res.crclMlMin!);
      expect(res.calculatedDose, closeTo(expectedDose, 0.5));
    });

    // =========================================================================
    // D8: Hard Block on Contraindicated Renal Tiers
    // =========================================================================
    test('D8: RenalAction.contraindicated hard-blocks calculation with zero calculated dose', () {
      final metformin = DrugDatabase.findById('metformin')!;
      final reg = metformin.regimens.first;

      // Patient with severe renal failure CrCl < 30
      const renalFailurePatient = Patient(
        id: 'patient-renal-fail',
        ageYears: 65,
        weightKg: 70.0,
        heightCm: 170.0,
        sex: Sex.male,
        serumCreatinineMgDl: 4.0, // Low CrCl < 30
      );

      final res = PharmacistCalculator.calculateDose(
        patient: renalFailurePatient,
        drug: metformin,
        regimen: reg,
      );

      expect(res.isBlocked, isTrue);
      expect(res.success, isFalse);
      expect(res.calculatedDose, isNull, reason: 'Contraindicated renal tier must produce no dose');
    });

    // =========================================================================
    // D9: Allergy Cross-Reactivity & D11 Deduplication
    // =========================================================================
    test('D9: AllergyService detects exact generic match and drug class cross-reactivity', () {
      final alerts = AllergyService.evaluateAllergies(
        patientAllergies: ['Penicillin'],
        drugGenericName: 'Amoxicillin',
        drugId: 'amoxicillin',
        drugClass: DrugClass.betaLactamPenicillin,
        legacyAllergyClass: 'penicillin',
      );

      expect(alerts, isNotEmpty);
      expect(alerts.any((a) => a.severity == LimitSeverity.hard), isTrue);
    });

    test('D11: Drugs deduplicated across categories and tags populated', () {
      final allDrugs = DrugDatabase.allDrugs;
      final ids = allDrugs.map((d) => d.id).toList();
      expect(ids.toSet().length, equals(ids.length), reason: 'All drug IDs in database must be strictly unique');

      // Regular insulin exists once under endocrine
      expect(DrugDatabase.findById('regular_insulin'), isNull);
      final insulin = DrugDatabase.findById('insulin_regular');
      expect(insulin, isNotNull);
      expect(insulin!.tags, contains('metabolic'));

      // Dexamethasone merged with obstetric tag
      final dexa = DrugDatabase.findById('dexamethasone');
      expect(dexa, isNotNull);
      expect(dexa!.tags, contains('obstetric'));
      expect(dexa.regimens.any((r) => r.indication?.contains('Fetal lung') == true), isTrue);
    });
  });
}
