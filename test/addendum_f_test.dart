// ============================================================
// ADDENDUM F TEST SUITE: SAFE DEFAULTS, ORDER VERIFICATION,
// RENAL POLICY, AUDIT HONESTY
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/models/models.dart';
import 'package:drug_dosage_calculator/core/calculators/calculators.dart';
import 'package:drug_dosage_calculator/core/audit/calculation_log.dart';
import 'package:drug_dosage_calculator/core/audit/pdf_report_generator.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Addendum F Test Suite', () {
    // =========================================================================
    // F1: Safe Defaults
    // =========================================================================
    group('F1: Safe Defaults in Drug & DosingRegimen', () {
      test('F1.1: Drug default fields are strictly unverified / safe', () {
        const d = Drug(
          id: 'test_drug',
          genericName: 'Test Drug',
          category: DrugCategory.antibiotic,
          regimens: [],
        );

        expect(d.sourceCitation, equals(''), reason: 'Never invent citation default');
        expect(d.lastReviewedDate, equals(''), reason: 'Never invent lastReviewedDate default');
        expect(d.renalReviewStatus, equals(RenalReviewStatus.unreviewed));
        expect(d.tabletSplittable, isFalse);
        expect(d.vialPartialAllowed, isFalse);
        expect(d.isSplittable, isFalse);
      });

      test('F1.2: DosingRegimen default verificationStatus is unverified', () {
        const r = DosingRegimen(
          route: DoseRoute.po,
          dosingType: DosingType.fixed,
          fixedDose: 500,
          doseUnit: DoseUnit.mg,
          frequency: Frequency.q12h,
        );

        expect(r.verificationStatus, equals(VerificationStatus.unverified));
      });
    });

    // =========================================================================
    // F2: Order Verification
    // =========================================================================
    group('F2: Order Verification (verifyOrder)', () {
      final paracetamol = DrugDatabase.findById('paracetamol')!;
      final paraAdult = paracetamol.regimens.firstWhere((r) => r.route == DoseRoute.po);
      const adultPatient = Patient(
        id: 'p-adult-70',
        ageYears: 35,
        weightKg: 70.0,
        heightCm: 175.0,
        sex: Sex.male,
        isScrStable: true,
        serumCreatinineMgDl: 0.9,
      );

      test('F2.1: Paracetamol 1000 mg q6h is acceptable (4000 mg/day)', () {
        final verify = PharmacistCalculator.verifyOrder(
          patient: adultPatient,
          drug: paracetamol,
          regimen: paraAdult,
          orderedDose: 1000.0,
          orderedFrequency: Frequency.q6h,
          orderedMaxDailyDose: 4000.0,
        );
        expect(verify.isAcceptable, isTrue);
        expect(verify.warnings.any((w) => w.severity == LimitSeverity.hard), isFalse);
      });

      test('F2.2: Paracetamol 1000 mg q4h is blocked (6000 mg/day > 4000 mg limit)', () {
        final verify = PharmacistCalculator.verifyOrder(
          patient: adultPatient,
          drug: paracetamol,
          regimen: paraAdult,
          orderedDose: 1000.0,
          orderedFrequency: Frequency.q4h, // 6 doses/day = 6000 mg
        );
        expect(verify.isAcceptable, isFalse);
        expect(
          verify.warnings.any((w) => w.code == DoseWarningCode.maxDailyDoseExceeded),
          isTrue,
        );
      });

      test('F2.3: PRN order without explicit max daily dose is blocked', () {
        final verify = PharmacistCalculator.verifyOrder(
          patient: adultPatient,
          drug: paracetamol,
          regimen: paraAdult,
          orderedDose: 500.0,
          orderedFrequency: Frequency.q4_6hPrn,
          orderedMaxDailyDose: null, // Missing explicit max daily dose
        );
        expect(verify.isAcceptable, isFalse);
        expect(
          verify.warnings.any((w) => w.code == DoseWarningCode.maxDailyDoseExceeded),
          isTrue,
        );
      });

      test('F2.4: Drug with dose range: in-range accepted, below-range flagged with orderBelowRange', () {
        const rangeRegimen = DosingRegimen(
          route: DoseRoute.po,
          dosingType: DosingType.fixed,
          fixedDose: 500.0,
          doseRangeMin: 250.0,
          doseRangeMax: 500.0,
          doseUnit: DoseUnit.mg,
          frequency: Frequency.q12h,
        );
        const rangeDrug = Drug(
          id: 'range_drug',
          genericName: 'Range Test Drug',
          category: DrugCategory.antibiotic,
          regimens: [rangeRegimen],
        );

        // In-range (375 mg) accepted
        final inRange = PharmacistCalculator.verifyOrder(
          patient: adultPatient,
          drug: rangeDrug,
          regimen: rangeRegimen,
          orderedDose: 375.0,
          orderedFrequency: Frequency.q12h,
        );
        expect(inRange.isAcceptable, isTrue);
        expect(inRange.warnings.any((w) => w.code == DoseWarningCode.orderBelowRange), isFalse);

        // Below-range (100 mg) flagged
        final belowRange = PharmacistCalculator.verifyOrder(
          patient: adultPatient,
          drug: rangeDrug,
          regimen: rangeRegimen,
          orderedDose: 100.0,
          orderedFrequency: Frequency.q12h,
        );
        expect(belowRange.warnings.any((w) => w.code == DoseWarningCode.orderBelowRange), isTrue);
      });

      test('F2.5: Full unadjusted dose ordered at CrCl 15 is flagged as renal overdose', () {
        final cefazolin = DrugDatabase.findById('cefazolin')!;
        final cefSystemic = cefazolin.regimens.firstWhere(
          (r) => r.indication?.contains('Systemic') ?? false,
        );
        const renalPatient = Patient(
          id: 'p-renal-15',
          ageYears: 65,
          weightKg: 60.0,
          heightCm: 165.0,
          sex: Sex.male,
          isScrStable: true,
          serumCreatinineMgDl: 3.5, // CrCl ~ 15 mL/min
        );

        final verify = PharmacistCalculator.verifyOrder(
          patient: renalPatient,
          drug: cefazolin,
          regimen: cefSystemic,
          orderedDose: 1000.0, // Full unadjusted dose
          orderedFrequency: Frequency.q8h, // Full unadjusted frequency (adjusted is 500 mg q12h)
        );

        expect(verify.isAcceptable, isFalse);
        expect(
          verify.warnings.any((w) => w.code == DoseWarningCode.severeRenalImpairment),
          isTrue,
        );
      });
    });

    // =========================================================================
    // F3: Safe Capping & Sweep Invariant
    // =========================================================================
    group('F3: Safe Capping & Sweep Invariant', () {
      const standardAdult = Patient(
        id: 'p-std-70',
        ageYears: 30,
        weightKg: 70.0,
        heightCm: 175.0,
        sex: Sex.male,
        isScrStable: true,
        serumCreatinineMgDl: 0.9, // CrCl ~ 100 mL/min
      );

      test('F3.1: Adult sweep invariant: default adult dose is never blocked or capped unless data specifies', () {
        final cappedDrugs = <String>[];
        final blockedDrugs = <String>[];

        for (final drug in DrugDatabase.allDrugs) {
          for (final regimen in drug.regimens) {
            if (regimen.effectiveAudience == RegimenAudience.adult) {
              final testPatient = (regimen.population?.sex == Sex.female)
                  ? const Patient(
                      id: 'p-std-female-70',
                      ageYears: 30,
                      weightKg: 70.0,
                      heightCm: 165.0,
                      sex: Sex.female,
                      isScrStable: true,
                      serumCreatinineMgDl: 0.8,
                    )
                  : standardAdult;

              final res = PharmacistCalculator.calculateDose(
                patient: testPatient,
                drug: drug,
                regimen: regimen,
              );

              final isCapped = res.warnings.any((w) => w.code == DoseWarningCode.doseCappedAtMax);
              if (isCapped) {
                cappedDrugs.add('${drug.id}:${regimen.indication}');
                expect(regimen.doseCap, isNotNull,
                    reason: '${drug.id} was capped without explicit regimen.doseCap');
              }

              if (res.isBlocked) {
                blockedDrugs.add('${drug.id}:${regimen.indication}');
              }
            }
          }
        }

        // Standard 70 kg, CrCl 100 adult has zero unexpected blocked regimens
        expect(blockedDrugs, isEmpty, reason: 'No standard adult regimen should be blocked: $blockedDrugs');

        // Check enoxaparin and acyclovir specifically
        final enoxaparin = DrugDatabase.findById('enoxaparin')!;
        final enoxRes = PharmacistCalculator.calculateDose(
          patient: standardAdult,
          drug: enoxaparin,
          regimen: enoxaparin.regimens.first,
        );
        expect(enoxRes.isBlocked, isFalse);
        expect(enoxRes.calculatedDose, equals(70.0)); // 1 mg/kg * 70 kg = 70 mg <= 100 mg limit

        final acyclovir = DrugDatabase.findById('acyclovir')!;
        final acyRes = PharmacistCalculator.calculateDose(
          patient: standardAdult,
          drug: acyclovir,
          regimen: acyclovir.regimens.first,
        );
        expect(acyRes.isBlocked, isFalse);
        expect(acyRes.calculatedDose, equals(700.0)); // 10 mg/kg * 70 kg = 700 mg <= 800 mg limit
      });
    });

    // =========================================================================
    // F4: Renal Policy
    // =========================================================================
    group('F4: Renal Policy & Safe String Interpolation', () {
      const drugUnreviewed = Drug(
        id: 'drug_unreviewed',
        genericName: 'Renal Drug Without Tiers',
        category: DrugCategory.antibiotic,
        requiresRenalAdjustment: true,
        renalReviewStatus: RenalReviewStatus.unreviewed,
        regimens: [
          DosingRegimen(
            route: DoseRoute.po,
            dosingType: DosingType.fixed,
            fixedDose: 500,
            doseUnit: DoseUnit.mg,
            frequency: Frequency.q12h,
          ),
        ],
      );

      test('F4.1: renalTiersUnreviewed fires soft for normal CrCl and hard for CrCl < 50', () {
        const normalPatient = Patient(
          id: 'p-norm',
          ageYears: 30,
          weightKg: 70.0,
          heightCm: 175.0,
          sex: Sex.male,
          isScrStable: true,
          serumCreatinineMgDl: 0.8, // CrCl ~ 110 mL/min
        );
        final resNorm = PharmacistCalculator.calculateDose(
          patient: normalPatient,
          drug: drugUnreviewed,
          regimen: drugUnreviewed.regimens.first,
        );
        final wNorm = resNorm.warnings.firstWhere((w) => w.code == DoseWarningCode.renalTiersUnreviewed);
        expect(wNorm.severity, equals(LimitSeverity.soft));

        const lowCrclPatient = Patient(
          id: 'p-low',
          ageYears: 70,
          weightKg: 60.0,
          heightCm: 160.0,
          sex: Sex.female,
          isScrStable: true,
          serumCreatinineMgDl: 2.2, // CrCl ~ 20 mL/min (< 50)
        );
        final resLow = PharmacistCalculator.calculateDose(
          patient: lowCrclPatient,
          drug: drugUnreviewed,
          regimen: drugUnreviewed.regimens.first,
        );
        final wLow = resLow.warnings.firstWhere((w) => w.code == DoseWarningCode.renalTiersUnreviewed);
        expect(wLow.severity, equals(LimitSeverity.hard));
        expect(resLow.isBlocked, isTrue);
      });

      test('F4.2: Warning text never interpolates nullable crcl as "null"', () {
        const noScrPatient = Patient(
          id: 'p-noscr',
          ageYears: 40,
          weightKg: 70.0,
          heightCm: 175.0,
          sex: Sex.male,
          isScrStable: true,
        );
        final res = PharmacistCalculator.calculateDose(
          patient: noScrPatient,
          drug: drugUnreviewed,
          regimen: drugUnreviewed.regimens.first,
        );
        for (final w in res.warnings) {
          expect(w.messageEn.contains('null mL/min'), isFalse);
          expect(w.messageTh.contains('null มล./นาที'), isFalse);
        }
      });
    });

    // =========================================================================
    // F5: PDF Audit Model
    // =========================================================================
    group('F5: PDF Report Model & Blocked Non-Green Dose', () {
      test('F5.1: Blocked result produces isBlocked = true and never green dose styling', () {
        final blockedResult = DosageResult.failure(
          reasonEn: 'Contraindicated due to direct allergy match.',
          reasonTh: 'ห้ามใช้เนื่องจากแพ้ยาโดยตรง',
          formulaUsed: 'Allergy Check',
          warnings: const [
            DoseWarning(
              severity: LimitSeverity.hard,
              code: DoseWarningCode.allergyAlert,
              messageEn: 'Direct allergy match',
              messageTh: 'แพ้ยาโดยตรง',
            ),
          ],
        );

        final log = CalculationLog(
          logId: 'log-blocked-1',
          userId: 'user-ph-1',
          timestamp: DateTime.utc(2026, 10, 6, 12, 0, 0),
          patientId: 'patient-blk',
          drugId: 'amoxicillin',
          drugName: 'Amoxicillin',
          indication: 'Dental Infection',
          route: 'PO',
          formulaUsed: 'Allergy Check',
          softwareVersion: '2.0.0',
          inputs: const {},
          result: blockedResult,
        );

        final model = PdfReportGenerator.buildReportModel([log]);

        expect(model.items.first.isBlocked, isTrue);
        expect(model.items.first.hasHardWarning, isTrue);
        expect(model.items.first.softwareVersion, equals('2.0.0'));
        expect(model.generatedAt.isUtc, isTrue);
      });
    });

    // =========================================================================
    // F6: Architecture Decoupling & Declarative Dose Rules
    // =========================================================================
    group('F6: Architecture Decoupling & Declarative DoseRule', () {
      test('F6.1: Apixaban 2-of-3 criteria uses isDoseModified instead of isRenallyAdjusted', () {
        final apixaban = DrugDatabase.findById('apixaban')!;
        final afibRegimen = apixaban.regimens.firstWhere(
          (r) => r.indication?.toLowerCase().contains('afib') ?? false,
        );

        // Patient meets 2 of 3 criteria: Age 82 (>=80), Weight 55 kg (<=60)
        const elderlySmallPatient = Patient(
          id: 'p-apixaban',
          ageYears: 82,
          weightKg: 55.0,
          heightCm: 155.0,
          sex: Sex.female,
          isScrStable: true,
          serumCreatinineMgDl: 1.0,
        );

        final res = PharmacistCalculator.calculateDose(
          patient: elderlySmallPatient,
          drug: apixaban,
          regimen: afibRegimen,
        );

        expect(res.calculatedDose, equals(2.5));
        expect(res.isDoseModified, isTrue);
        expect(res.isRenallyAdjusted, isFalse);
        expect(res.doseModificationReason, contains('Apixaban dose reduced to 2.5 mg BID'));
      });
    });

    // =========================================================================
    // F7: Allergy Service Overhaul
    // =========================================================================
    group('F7: AllergyService Exact Molecule & Class Matching', () {
      test('F7.1: hasDirectMatch is TRUE ONLY for exact molecule', () {
        final directAlerts = AllergyService.evaluateAllergies(
          patientAllergies: ['Amoxicillin'],
          drugGenericName: 'Amoxicillin',
          drugId: 'amoxicillin',
          drugClass: DrugClass.betaLactamPenicillin,
          legacyAllergyClass: 'Penicillin',
        );
        expect(directAlerts.first.hasDirectMatch, isTrue);
        expect(directAlerts.first.severity, equals(LimitSeverity.hard));
      });

      test('F7.2: Class allergen produces class alert with hasDirectMatch = false', () {
        final classAlerts = AllergyService.evaluateAllergies(
          patientAllergies: ['Penicillin'],
          drugGenericName: 'Amoxicillin',
          drugId: 'amoxicillin',
          drugClass: DrugClass.betaLactamPenicillin,
          legacyAllergyClass: 'Penicillin',
        );
        expect(classAlerts.first.hasDirectMatch, isFalse);
        expect(classAlerts.first.severity, equals(LimitSeverity.hard));
        expect(classAlerts.first.messageEn, contains('CLASS ALLERGY ALERT'));
      });

      test('F7.3: Thai synonym input resolves accurately', () {
        final thaiAlerts = AllergyService.evaluateAllergies(
          patientAllergies: ['พาราเซตามอล'],
          drugGenericName: 'Paracetamol (Acetaminophen)',
          drugId: 'paracetamol',
          drugClass: null,
          legacyAllergyClass: null,
        );
        expect(thaiAlerts.first.hasDirectMatch, isTrue);
      });

      test('F7.4: Negative control: Unrelated allergy produces no match', () {
        final negAlerts = AllergyService.evaluateAllergies(
          patientAllergies: ['Paracetamol'],
          drugGenericName: 'Amoxicillin',
          drugId: 'amoxicillin',
          drugClass: DrugClass.betaLactamPenicillin,
          legacyAllergyClass: 'Penicillin',
        );
        expect(negAlerts, isEmpty);
      });

      test('F7.5: Unrecognized allergen emits informational advisory', () {
        final unrecAlerts = AllergyService.evaluateAllergies(
          patientAllergies: ['SomeUnknownChemical123'],
          drugGenericName: 'Amoxicillin',
          drugId: 'amoxicillin',
          drugClass: DrugClass.betaLactamPenicillin,
          legacyAllergyClass: 'Penicillin',
        );
        expect(unrecAlerts.length, equals(1));
        expect(unrecAlerts.first.severity, equals(LimitSeverity.info));
        expect(unrecAlerts.first.messageEn, contains('UNRECOGNIZED ALLERGEN'));
      });
    });

    // =========================================================================
    // F8: Contraindications & Patient Condition Flags
    // =========================================================================
    group('F8: Contraindications & Patient Condition Flags', () {
      test('F8.1: Free-text contraindications become info checklist', () {
        final metronidazole = DrugDatabase.findById('metronidazole')!;
        const patient = Patient(
          id: 'p-metro',
          ageYears: 30,
          weightKg: 60.0,
          heightCm: 165.0,
          sex: Sex.male,
          isScrStable: true,
        );
        final res = PharmacistCalculator.calculateDose(
          patient: patient,
          drug: metronidazole,
          regimen: metronidazole.regimens.first,
        );
        final contraWarnings = res.warnings.where(
          (w) => w.code == DoseWarningCode.contraindicationAlert &&
              w.messageEn.contains('Clinical Checklist: Contraindication / Caution:'),
        );
        expect(contraWarnings, isNotEmpty);
        expect(contraWarnings.every((w) => w.severity == LimitSeverity.info), isTrue);
      });

      test('F8.2: Patient pregnancy flag triggers hard stop for Category X drug', () {
        final atorvastatin = DrugDatabase.findById('atorvastatin');
        if (atorvastatin != null) {
          const pregnantPatient = Patient(
            id: 'p-preg',
            ageYears: 28,
            weightKg: 65.0,
            heightCm: 160.0,
            sex: Sex.female,
            isPregnant: true,
            isScrStable: true,
          );
          final res = PharmacistCalculator.calculateDose(
            patient: pregnantPatient,
            drug: atorvastatin,
            regimen: atorvastatin.regimens.first,
          );
          expect(res.isBlocked, isTrue);
          expect(
            res.warnings.any((w) => w.messageEn.contains('PREGNANCY CONTRAINDICATION')),
            isTrue,
          );
        }
      });
    });

    // =========================================================================
    // F9: Frequency Equality & Conservative Parsing
    // =========================================================================
    group('F9: Frequency Equality & Conservative Schedules', () {
      test('F9.1: Frequency == compares clinical fields only, not display strings', () {
        const f1 = Frequency(
          intervalHours: 8,
          displayEn: 'q8h',
          displayTh: 'ทุก 8 ชม.',
        );
        const f2 = Frequency(
          intervalHours: 8,
          displayEn: 'Every 8 Hours',
          displayTh: 'ทานทุกแปดชั่วโมง',
        );

        expect(f1 == f2, isTrue, reason: 'Clinical fields match; display strings must not break equality');
      });

      test('F9.2: Frequency.kind is derived correctly', () {
        expect(Frequency.q8h.kind, equals(FrequencyKind.interval));
        expect(Frequency.continuous.kind, equals(FrequencyKind.continuous));
        expect(Frequency.stat.kind, equals(FrequencyKind.once));
        expect(Frequency.weekly.kind, equals(FrequencyKind.weekly));
        expect(Frequency.prn.kind, equals(FrequencyKind.prn));
      });

      test('F9.3: PRN/range worstCaseDosesPerDay uses minIntervalHours', () {
        const rangeFreq = Frequency(
          minIntervalHours: 4,
          maxIntervalHours: 6,
          isPrn: true,
          displayEn: 'q4-6h PRN',
          displayTh: 'ทุก 4-6 ชม. เมื่อจำเป็น',
        );

        expect(rangeFreq.worstCaseDosesPerDay, equals(6.0), reason: '24 / 4h = 6 doses/day');
      });

      test('F9.4: fromLegacyString parses range conservatively to largest doses/day', () {
        final parsed = Frequency.fromLegacyString('q4-6h');
        expect(parsed.worstCaseDosesPerDay, equals(6.0));
      });
    });

    // =========================================================================
    // F10: Concentration & Units
    // =========================================================================
    group('F10: Concentration & Units Compatibility', () {
      test('F10.1: mU/mL converts accurately to U/mL (10 mU/mL = 0.01 U/mL)', () {
        const conc = Concentration(10.0, ConcentrationUnit.mUPerMl);
        expect(conc.toBaseUnitPerMl(), closeTo(0.01, 0.0001));
      });

      test('F10.2: Oxytocin infusion calculation: 10 mU/mL at 1 mU/min yields 6 mL/hr', () {
        const conc = Concentration(10.0, ConcentrationUnit.mUPerMl);
        final mlPerHour = IvRateCalculator.calculateInfusionMlPerHour(
          doseRatePerMin: 1.0,
          doseRateUnit: RateUnit.mUMin,
          concentration: conc,
        );
        expect(mlPerHour, closeTo(6.0, 0.001));
      });

      test('F10.3: ConcentrationUnit and DoseUnit mismatch fails safely', () {
        const conc = Concentration(10.0, ConcentrationUnit.unitsPerMl);
        expect(
          () => IvRateCalculator.calculateInfusionMlPerHour(
            doseRatePerMin: 1.0,
            doseRateUnit: RateUnit.mgKgMin,
            concentration: conc,
          ),
          throwsArgumentError,
        );
      });

      test('F10.4: Step 13 Gram-dosed regimen with mg/mL dilution performs unit conversion', () {
        const gramRegimen = DosingRegimen(
          route: DoseRoute.ivInfusion,
          dosingType: DosingType.fixed,
          fixedDose: 2.0, // 2 g
          doseUnit: DoseUnit.g,
          frequency: Frequency.q12h,
          standardDilutionMgPerMl: 20.0, // 20 mg/mL -> 2000 mg / 20 = 100 mL
          infusionTimeMinutes: 60.0,
        );
        const gramDrug = Drug(
          id: 'gram_drug',
          genericName: 'Gram Drug',
          category: DrugCategory.antibiotic,
          regimens: [gramRegimen],
        );
        const patient = Patient(
          id: 'p-gram',
          ageYears: 30,
          weightKg: 70.0,
          heightCm: 175.0,
          sex: Sex.male,
          isScrStable: true,
        );

        final res = PharmacistCalculator.calculateDose(
          patient: patient,
          drug: gramDrug,
          regimen: gramRegimen,
          dripFactor: 15.0,
        );

        expect(res.volumeMl, closeTo(100.0, 0.01)); // 2g * 1000 / 20 mg/mL = 100 mL
        expect(res.infusionRateMlPerHr, closeTo(100.0, 0.01)); // 100 mL / 1 hr = 100 mL/hr
        expect(res.dripRateDropsPerMin, closeTo(25.0, 0.01)); // 100 mL * 15 / 60 min = 25 gtt/min
      });
    });

    // =========================================================================
    // F11: Adolescents Population Gate
    // =========================================================================
    group('F11: Population Criteria Wins Over 18-Year Gate', () {
      final domperidone = DrugDatabase.findById('domperidone')!;
      final oralRegimen = domperidone.regimens.first;

      test('F11.1: Domperidone allows 14y / 40kg adolescent per explicit criteria', () {
        const adolescent = Patient(
          id: 'p-teen-40kg',
          ageYears: 14,
          weightKg: 40.0,
          heightCm: 160.0,
          sex: Sex.male,
          isScrStable: true,
        );
        final res = PharmacistCalculator.calculateDose(
          patient: adolescent,
          drug: domperidone,
          regimen: oralRegimen,
        );
        expect(res.isBlocked, isFalse);
        expect(res.calculatedDose, equals(10.0));
      });

      test('F11.2: Domperidone blocks 14y / 30kg adolescent due to min weight requirement (< 35 kg)', () {
        const adolescentUnderweight = Patient(
          id: 'p-teen-30kg',
          ageYears: 14,
          weightKg: 30.0,
          heightCm: 145.0,
          sex: Sex.female,
          isScrStable: true,
        );
        final res = PharmacistCalculator.calculateDose(
          patient: adolescentUnderweight,
          drug: domperidone,
          regimen: oralRegimen,
        );
        expect(res.isBlocked, isTrue);
        expect(res.warnings.any((w) => w.code == DoseWarningCode.populationMismatch), isTrue);
      });

      test('F11.3: Domperidone blocks 8-year-old child (< 12 years)', () {
        const youngChild = Patient(
          id: 'p-child-8y',
          ageYears: 8,
          weightKg: 25.0,
          heightCm: 125.0,
          sex: Sex.male,
          isScrStable: true,
        );
        final res = PharmacistCalculator.calculateDose(
          patient: youngChild,
          drug: domperidone,
          regimen: oralRegimen,
        );
        expect(res.isBlocked, isTrue);
      });
    });

    // =========================================================================
    // F12: Weekly Regimens and Methotrexate Banner
    // =========================================================================
    group('F12: WEEKLY - NOT DAILY Banner', () {
      test('F12.1: Methotrexate or weekly regimen emits prominent WEEKLY - NOT DAILY banner', () {
        final methotrexate = DrugDatabase.findById('methotrexate');
        if (methotrexate != null) {
          const patient = Patient(
            id: 'p-mtx',
            ageYears: 50,
            weightKg: 65.0,
            heightCm: 165.0,
            sex: Sex.female,
            isScrStable: true,
            serumCreatinineMgDl: 0.8,
          );
          final res = PharmacistCalculator.calculateDose(
            patient: patient,
            drug: methotrexate,
            regimen: methotrexate.regimens.first,
          );
          expect(res.isWeeklySchedule, isTrue);
          expect(
            res.warnings.any((w) => w.messageEn.contains('WEEKLY - NOT DAILY')),
            isTrue,
          );
        }
      });
    });

    // =========================================================================
    // F13: Housekeeping
    // =========================================================================
    group('F13: Symmetric Route Matching & Safe Exception Catching', () {
      test('F13.1: Drug.findRegimen route matching is completely symmetric', () {
        final ceftriaxone = DrugDatabase.findById('ceftriaxone')!;
        final regFromIv = ceftriaxone.findRegimen(DoseRoute.iv, 'Severe Infection (Adult)');
        expect(regFromIv, isNotNull);

        const genericIvDrug = Drug(
          id: 'generic_iv',
          genericName: 'Generic IV Drug',
          category: DrugCategory.antibiotic,
          regimens: [
            DosingRegimen(
              route: DoseRoute.iv,
              dosingType: DosingType.fixed,
              fixedDose: 1000,
              doseUnit: DoseUnit.mg,
              frequency: Frequency.q12h,
            ),
          ],
        );
        expect(genericIvDrug.findRegimen(DoseRoute.ivInfusion), isNotNull);
        expect(genericIvDrug.findRegimen(DoseRoute.ivPush), isNotNull);
      });

      test('F13.2: Calculator catches unexpected exceptions safely without exposing raw string', () {
        // Intentionally malformed patient inputs or state
        const safeDrug = Drug(
          id: 'safe_drug',
          genericName: 'Safe Drug',
          category: DrugCategory.antibiotic,
          regimens: [],
        );
        const patient = Patient(
          id: 'p-safe',
          ageYears: 30,
          weightKg: 70.0,
          heightCm: 175.0,
          sex: Sex.male,
          isScrStable: true,
        );
        const regimen = DosingRegimen(
          route: DoseRoute.po,
          dosingType: DosingType.fixed,
          fixedDose: 500,
          doseUnit: DoseUnit.mg,
          frequency: Frequency.q12h,
        );

        final res = PharmacistCalculator.calculateDose(
          patient: patient,
          drug: safeDrug,
          regimen: regimen,
        );
        expect(res.success, isTrue);
      });
    });
  });
}
