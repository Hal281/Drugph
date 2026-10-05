import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/models/models.dart';
import 'package:drug_dosage_calculator/core/calculators/calculators.dart';
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

    // =========================================================================
    // D12: Clinical Math & Boundary Verification (Schwartz, Oxytocin, NAC, Tiers)
    // =========================================================================
    test('D12: Bedside Schwartz eGFR yields exact known value 103.25 for 125cm / 0.5mg/dL', () {
      final egfr = RenalCalculator.bedsideSchwartz(
        heightCm: 125.0,
        serumCreatinineMgDl: 0.5,
      );
      // 0.413 * 125 / 0.5 = 103.25
      expect(egfr, closeTo(103.25, 0.01));
    });

    test('D12: Oxytocin 1 mU/min with 0.01 U/mL (10 mU/mL) yields 6 mL/hr', () {
      final oxy = DrugDatabase.findById('oxytocin')!;
      final reg = oxy.regimens.firstWhere((r) => r.indication == 'Labor induction');

      final res = PharmacistCalculator.calculateDose(
        patient: adultPatient,
        drug: oxy,
        regimen: reg,
      );

      expect(res.success, isTrue);
      expect(res.infusionResult, isNotNull);
      expect(res.infusionResult!.rate, equals(1.0));
      expect(res.infusionResult!.rateUnit, equals(RateUnit.mUMin));
      expect(res.infusionResult!.rateMlPerHr, closeTo(6.0, 0.01));
    });

    test('D12: NAC IV paracetamol antidote caps dosing weight at 100 kg for 140 kg patient', () {
      final nac = DrugDatabase.findById('n_acetylcysteine')!;
      final reg = nac.regimens.firstWhere((r) => r.indication?.contains('Paracetamol') == true);

      const obesePatient = Patient(
        id: 'patient-obese-140',
        ageYears: 35,
        weightKg: 140.0,
        heightCm: 175.0,
        sex: Sex.male,
      );

      final res = PharmacistCalculator.calculateDose(
        patient: obesePatient,
        drug: nac,
        regimen: reg,
      );

      expect(res.success, isTrue);
      // Base dose = 150 mg/kg * 100 kg cap = 15,000 mg (not 21,000 mg)
      expect(res.calculatedDose, equals(15000.0));
      expect(res.calculationInputs['dosingWeightUsedKg'], equals(100.0));
      expect(res.warnings.any((w) => w.messageEn.contains('capped at 100 kg')), isTrue);
    });

    test('D12: Cefazolin contiguous tiers correctly adjust for CrCl 34.9, 10.0, and 35.0', () {
      final cef = DrugDatabase.findById('cefazolin')!;
      final reg = cef.regimens.firstWhere((r) => r.indication?.contains('Systemic') == true);

      // CrCl 34.9 mL/min -> [11, 35) tier: 500 mg q12h
      final res34 = PharmacistCalculator.calculateDose(
        patient: adultPatient.copyWith(creatinineClearanceMlMin: 34.9, serumCreatinineMgDl: null),
        drug: cef,
        regimen: reg,
      );
      expect(res34.calculatedDose, equals(500.0));
      expect(res34.structuredFrequency, equals(Frequency.q12h));

      // CrCl 10.0 mL/min -> [0, 11) tier: 500 mg q24h
      final res10 = PharmacistCalculator.calculateDose(
        patient: adultPatient.copyWith(creatinineClearanceMlMin: 10.0, serumCreatinineMgDl: null),
        drug: cef,
        regimen: reg,
      );
      expect(res10.calculatedDose, equals(500.0));
      expect(res10.structuredFrequency, equals(Frequency.q24h));

      // CrCl 35.0 mL/min -> above 35 mL/min: standard 1000 mg q8h
      final res35 = PharmacistCalculator.calculateDose(
        patient: adultPatient.copyWith(creatinineClearanceMlMin: 35.0, serumCreatinineMgDl: null),
        drug: cef,
        regimen: reg,
      );
      expect(res35.calculatedDose, equals(1000.0));
      expect(res35.structuredFrequency, equals(Frequency.q8h));
    });

    test('D12: Meropenem contiguous tiers correctly adjust for CrCl 25.5, 9.5, and 26.0', () {
      final mero = DrugDatabase.findById('meropenem')!;
      final reg = mero.regimens.firstWhere((r) => r.indication == 'Severe Infection');

      // CrCl 25.5 mL/min -> [10, 26) tier: 500 mg q12h
      final res25 = PharmacistCalculator.calculateDose(
        patient: adultPatient.copyWith(creatinineClearanceMlMin: 25.5, serumCreatinineMgDl: null),
        drug: mero,
        regimen: reg,
      );
      expect(res25.calculatedDose, equals(500.0));
      expect(res25.structuredFrequency, equals(Frequency.q12h));

      // CrCl 9.5 mL/min -> [0, 10) tier: 500 mg q24h
      final res9 = PharmacistCalculator.calculateDose(
        patient: adultPatient.copyWith(creatinineClearanceMlMin: 9.5, serumCreatinineMgDl: null),
        drug: mero,
        regimen: reg,
      );
      expect(res9.calculatedDose, equals(500.0));
      expect(res9.structuredFrequency, equals(Frequency.q24h));

      // CrCl 26.0 mL/min -> [26, 50) tier: 1000 mg q12h
      final res26 = PharmacistCalculator.calculateDose(
        patient: adultPatient.copyWith(creatinineClearanceMlMin: 26.0, serumCreatinineMgDl: null),
        drug: mero,
        regimen: reg,
      );
      expect(res26.calculatedDose, equals(1000.0));
      expect(res26.structuredFrequency, equals(Frequency.q12h));
    });

    test('D12: Apixaban reduces to 2.5 mg BID when meeting >=2 criteria in AFib', () {
      final apix = DrugDatabase.findById('apixaban')!;
      final afReg = apix.regimens.firstWhere((r) => r.indication?.contains('AFib') == true);

      // Patient: 82 years, 52 kg, SCr 1.6 mg/dL (meets all 3 criteria)
      const elderlyAfPatient = Patient(
        id: 'patient-af-elderly',
        ageYears: 82,
        weightKg: 52.0,
        heightCm: 155.0,
        sex: Sex.female,
        serumCreatinineMgDl: 1.6,
      );

      final res = PharmacistCalculator.calculateDose(
        patient: elderlyAfPatient,
        drug: apix,
        regimen: afReg,
      );

      expect(res.success, isTrue);
      expect(res.calculatedDose, equals(2.5));
      expect(res.structuredFrequency, equals(Frequency.q12h));
      expect(res.warnings.any((w) => w.messageEn.contains('Apixaban dose reduced to 2.5 mg BID')), isTrue);
    });
  });
}
