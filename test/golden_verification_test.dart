import 'dart:convert';
import 'dart:io';

import 'package:drug_dosage_calculator/core/calculators/transparent_dosage_calculator.dart';
import 'package:drug_dosage_calculator/core/models/transparent_calculation_result.dart';
import 'package:drug_dosage_calculator/core/models/verified_drug_schema.dart';
import 'package:drug_dosage_calculator/data/knowledge_base_loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const double tol = 1e-6;

  late VerifiedDrugKnowledgeBase kb;
  late Map<String, dynamic> rawDataset;
  late List<Map<String, dynamic>> allCases;

  setUpAll(() async {
    kb = await KnowledgeBaseLoader.loadFromFile(
      'assets/data/drug_knowledge_base.json',
    );
    final file = File('test/golden/golden_test_cases.json');
    rawDataset = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    allCases = (rawDataset['cases'] as List)
        .map((e) => e as Map<String, dynamic>)
        .toList(growable: false);
  });

  AllergyAssessmentStatus? parseAllergyStatus(String? raw) {
    if (raw == null) return null;
    for (final v in AllergyAssessmentStatus.values) {
      if (v.name == raw) return v;
    }
    return null;
  }

  void runDatasetCase(Map<String, dynamic> testCase) {
    final caseId = testCase['case_id'] as String;
    final input = testCase['input'] as Map<String, dynamic>;
    final expected = testCase['expected'] as Map<String, dynamic>;
    final source = testCase['source'] as Map<String, dynamic>;

    // Ensure source attribution is present on every test case
    expect(source['source_name'], isNotNull, reason: '$caseId missing source_name');
    expect((source['source_name'] as String).trim(), isNotEmpty);
    expect((source['edition'] as String).trim(), isNotEmpty);
    expect((source['page'] as String).trim(), isNotEmpty);

    // Bug 1 Fix: interaction_database must only be set on cases that actually test DDI
    final concomitants = ((input['concomitant_medications'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList();
    if (concomitants.isEmpty) {
      expect(
        source['interaction_database'],
        isNull,
        reason: '$caseId has no concomitant_medications so interaction_database must be null',
      );
    } else {
      expect(
        (source['interaction_database'] as String?)?.trim(),
        isNotEmpty,
        reason: '$caseId has concomitant_medications so interaction_database must be populated',
      );
    }

    final drugId = input['drug_id'] as String;
    final drug = kb.findDrug(drugId);
    expect(drug, isNotNull, reason: '$caseId drug "$drugId" not found in KB');

    final result = TransparentDosageCalculator.calculate(
      drug: drug!,
      weightKg: (input['weight_kg'] as num).toDouble(),
      ageYears: (input['age_years'] as num?)?.toDouble(),
      crclMlMin: (input['crcl_ml_min'] as num?)?.toDouble(),
      renalMetricType: input['renal_metric_type'] as String?,
      customDoseRateMgPerKg:
          (input['custom_dose_rate_mg_per_kg'] as num?)?.toDouble(),
      allergies: ((input['allergies'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      allergyAssessmentStatus: parseAllergyStatus(
        input['allergy_assessment_status'] as String?,
      ),
      concomitantMedications: concomitants,
    );

    // 1. Floating-point assertions using closeTo(expected, 1e-6)
    expect(
      result.rawCalculatedSingleDoseMg,
      closeTo((expected['raw_calculated_single_dose_mg'] as num).toDouble(), tol),
      reason: '$caseId rawCalculatedSingleDoseMg mismatch',
    );
    expect(
      result.rawCalculatedDailyDoseMg,
      closeTo((expected['raw_calculated_daily_dose_mg'] as num).toDouble(), tol),
      reason: '$caseId rawCalculatedDailyDoseMg mismatch',
    );
    expect(
      result.finalRecommendedSingleDoseMg,
      closeTo(
        (expected['final_recommended_single_dose_mg'] as num).toDouble(),
        tol,
      ),
      reason: '$caseId finalRecommendedSingleDoseMg mismatch',
    );
    expect(
      result.finalRecommendedDailyDoseMg,
      closeTo(
        (expected['final_recommended_daily_dose_mg'] as num).toDouble(),
        tol,
      ),
      reason: '$caseId finalRecommendedDailyDoseMg mismatch',
    );

    // Bug 2 Invariant: finalRecommendedSingleDoseMg * dosesPerDay MUST NEVER exceed finalRecommendedDailyDoseMg
    expect(
      result.finalRecommendedSingleDoseMg * result.dosesPerDay,
      lessThanOrEqualTo(result.finalRecommendedDailyDoseMg + tol),
      reason:
          '$caseId singleDose (${result.finalRecommendedSingleDoseMg}) * dosesPerDay (${result.dosesPerDay}) exceeds finalRecommendedDailyDoseMg (${result.finalRecommendedDailyDoseMg})',
    );

    expect(
      result.exactVolumeMl,
      closeTo((expected['exact_volume_ml'] as num).toDouble(), tol),
      reason: '$caseId exactVolumeMl mismatch',
    );
    expect(
      result.practicalVolumeMl,
      closeTo((expected['practical_volume_ml'] as num).toDouble(), tol),
      reason: '$caseId practicalVolumeMl mismatch',
    );
    expect(
      result.actualDeliveredSingleDoseMg,
      closeTo(
        (expected['actual_delivered_single_dose_mg'] as num).toDouble(),
        tol,
      ),
      reason: '$caseId actualDeliveredSingleDoseMg mismatch',
    );
    expect(
      result.roundingDiscrepancyMg,
      closeTo((expected['rounding_discrepancy_mg'] as num).toDouble(), tol),
      reason: '$caseId roundingDiscrepancyMg mismatch',
    );
    expect(
      result.roundingDiscrepancyPercent,
      closeTo((expected['rounding_discrepancy_percent'] as num).toDouble(), tol),
      reason: '$caseId roundingDiscrepancyPercent mismatch',
    );

    // 2. Frequency, doses per day, dispensing device, and flags
    expect(
      result.recommendedFrequency,
      equals(expected['recommended_frequency'] as String),
      reason: '$caseId recommendedFrequency mismatch',
    );
    expect(
      result.dosesPerDay,
      equals((expected['doses_per_day'] as num).toInt()),
      reason: '$caseId dosesPerDay mismatch',
    );
    expect(
      result.dispensingDeviceRecommendation,
      contains(expected['dispensing_device_contains'] as String),
      reason: '$caseId dispensingDeviceRecommendation mismatch',
    );
    expect(
      result.isSingleDoseCappedAtMax,
      equals(expected['is_single_dose_capped_at_max'] as bool),
      reason: '$caseId isSingleDoseCappedAtMax mismatch',
    );
    expect(
      result.isDailyDoseCappedAtMax,
      equals(expected['is_daily_dose_capped_at_max'] as bool),
      reason: '$caseId isDailyDoseCappedAtMax mismatch',
    );
    expect(
      result.isRenallyContraindicated,
      equals(expected['is_renally_contraindicated'] as bool),
      reason: '$caseId isRenallyContraindicated mismatch',
    );
    expect(
      result.hasAllergyAlert,
      equals(expected['has_allergy_alert'] as bool),
      reason: '$caseId hasAllergyAlert mismatch',
    );
    expect(
      result.hasDrugInteractionAlert,
      equals(expected['has_drug_interaction_alert'] as bool),
      reason: '$caseId hasDrugInteractionAlert mismatch',
    );

    // 3. Step-by-Step Breakdown completeness
    expect(result.calculationSteps, isNotEmpty);
    if (result.formulaType == 'mg_per_kg_per_day') {
      expect(
        result.calculationSteps.any((s) => s.contains('÷') && s.contains('มื้อ')),
        isTrue,
        reason:
            '$caseId mg_per_kg_per_day must explicitly show division by doses per day',
      );
    }

    // 4. Expected Alerts (type + severity + complete fields)
    final expectedAlerts = (expected['expected_alerts'] as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();
    expect(
      result.safetyAlerts.length,
      equals(expectedAlerts.length),
      reason:
          '$caseId expected ${expectedAlerts.length} alerts, got ${result.safetyAlerts.map((a) => "${a.type.name}:${a.severity.name}").toList()}',
    );

    for (final expAlert in expectedAlerts) {
      final expType = expAlert['type'] as String;
      final expSeverity = expAlert['severity'] as String;
      final matching = result.safetyAlerts.where(
        (a) => a.type.name == expType && a.severity.name == expSeverity,
      );
      expect(
        matching,
        isNotEmpty,
        reason:
            '$caseId missing expected alert ($expType, $expSeverity); actual: ${result.safetyAlerts.map((a) => "${a.type.name}:${a.severity.name}").toList()}',
      );
      for (final alert in matching) {
        expect(alert.mechanism.trim(), isNotEmpty);
        expect(alert.management.trim(), isNotEmpty);
        expect(alert.reference.trim(), isNotEmpty);
        if (alert.type == SafetyAlertType.drugInteraction) {
          expect(alert.databaseSource, isNotNull);
          expect(alert.databaseSource!.trim(), isNotEmpty);
        }
      }
    }
  }

  group('Phase 3.1 — Human Sign-Off Audit & Traceability Gate (Bug 1 Fix)', () {
    test(
      'Enforces that no case can claim source_verified: true or verified_golden without human verified_by & verified_date',
      () {
        expect(allCases.length, equals(15));

        for (final testCase in allCases) {
          final caseId = testCase['case_id'] as String;
          final sourceVerified = testCase['source_verified'] as bool;
          final group = testCase['test_group'] as String;
          final verifiedBy = testCase['verified_by'] as String?;
          final verifiedDate = testCase['verified_date'] as String?;

          if (sourceVerified || group == 'verified_golden') {
            expect(
              verifiedBy != null && verifiedBy.trim().isNotEmpty,
              isTrue,
              reason:
                  '$caseId cannot be source_verified: true without human verified_by',
            );
            expect(
              verifiedDate != null &&
                  RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(verifiedDate.trim()),
              isTrue,
              reason:
                  '$caseId cannot be source_verified: true without ISO YYYY-MM-DD verified_date',
            );
          } else {
            expect(group, equals('regression_only'));
            expect(sourceVerified, isFalse);
          }
        }
      },
    );
  });

  group(
    'Phase 3.2 — Regression Test Cases & Unverified KB Constants Pending Human Textbook Review (Bug 1, Bug 2 & Bug 7 Fixes)',
    () {
      test(
        'Runs all 15 regression_only cases (G-01 through G-15) and verifies self-consistent daily caps on G-02 & G-14',
        () {
          final regressionCases = allCases
              .where((c) => c['test_group'] == 'regression_only')
              .toList();
          expect(regressionCases.length, equals(15));

          for (final testCase in regressionCases) {
            expect(testCase['source_verified'], isFalse);
            runDatasetCase(testCase);
          }

          // Explicitly assert Bug 2 fix on G-02 and G-14:
          final g02 = regressionCases.firstWhere((c) => c['case_id'] == 'G-02');
          expect(
            (g02['expected'] as Map<String, dynamic>)['doses_per_day'],
            equals(4),
          );
          expect(
            (g02['expected'] as Map<String, dynamic>)['final_recommended_daily_dose_mg'],
            closeTo(4000.0, tol),
          );

          final g14 = regressionCases.firstWhere((c) => c['case_id'] == 'G-14');
          expect(
            (g14['expected'] as Map<String, dynamic>)['doses_per_day'],
            equals(4),
          );
          expect(
            (g14['expected'] as Map<String, dynamic>)['final_recommended_daily_dose_mg'],
            closeTo(3600.0, tol),
          );
        },
      );

      test(
        'Phase 3.3 (Regression-Only Pending Human Review): Verifies KB renal_adjustment cutoffs and tests exact boundary points (0.0, 9.99, 10.0, 29.99, 30.0, 49.99, 50.0, 59.99, 60.0)',
        () {
          final paracetamol = kb.findDrug('paracetamol_oral_susp')!;
          final amoxicillin = kb.findDrug('amoxicillin_oral_susp')!;
          final ibuprofen = kb.findDrug('ibuprofen_oral_susp')!;

          // All 3 drugs are marked pending human textbook verification
          expect(paracetamol.verificationMetadata.isFullyVerified, isFalse);
          expect(amoxicillin.verificationMetadata.isFullyVerified, isFalse);
          expect(ibuprofen.verificationMetadata.isFullyVerified, isFalse);

          // 1. Assert KB tier cutoffs match expected drug-specific boundaries
          expect(
            paracetamol.dosingRules.renalAdjustment
                .map((t) => [t.crclMinMlMin, t.crclMaxMlMin])
                .toList(),
            equals([
              [0.0, 10.0],
              [10.0, 50.0],
              [50.0, 999.0],
            ]),
          );
          expect(
            amoxicillin.dosingRules.renalAdjustment
                .map((t) => [t.crclMinMlMin, t.crclMaxMlMin])
                .toList(),
            equals([
              [0.0, 10.0],
              [10.0, 30.0],
              [30.0, 999.0],
            ]),
          );
          expect(
            ibuprofen.dosingRules.renalAdjustment
                .map((t) => [t.crclMinMlMin, t.crclMaxMlMin])
                .toList(),
            equals([
              [0.0, 30.0],
              [30.0, 60.0],
              [60.0, 999.0],
            ]),
          );

          // 2. Paracetamol exact cutoffs: 0.0, 9.99 -> q8h; 10.0, 49.99 -> q6h; 50.0 -> q4-6h
          for (final crcl in [0.0, 9.99]) {
            final res = TransparentDosageCalculator.calculate(
              drug: paracetamol,
              weightKg: 15.0,
              ageYears: 4.0,
              crclMlMin: crcl,
              allergyAssessmentStatus: AllergyAssessmentStatus.nkdaConfirmed,
            );
            expect(res.recommendedFrequency, equals('q8h'));
            expect(res.dosesPerDay, equals(3));
          }
          for (final crcl in [10.0, 49.99]) {
            final res = TransparentDosageCalculator.calculate(
              drug: paracetamol,
              weightKg: 15.0,
              ageYears: 4.0,
              crclMlMin: crcl,
              allergyAssessmentStatus: AllergyAssessmentStatus.nkdaConfirmed,
            );
            expect(res.recommendedFrequency, equals('q6h'));
            expect(res.dosesPerDay, equals(4));
          }
          final para50 = TransparentDosageCalculator.calculate(
            drug: paracetamol,
            weightKg: 15.0,
            ageYears: 4.0,
            crclMlMin: 50.0,
            allergyAssessmentStatus: AllergyAssessmentStatus.nkdaConfirmed,
          );
          expect(para50.recommendedFrequency, equals('q4-6h'));
          expect(para50.dosesPerDay, equals(5));

          // 3. Amoxicillin exact cutoffs: 0.0, 9.99 -> q24h (1 dose/day); 10.0, 29.99 -> q12h (2 doses/day); 30.0 -> q8h (3 doses/day)
          for (final crcl in [0.0, 9.99]) {
            final res = TransparentDosageCalculator.calculate(
              drug: amoxicillin,
              weightKg: 20.0,
              ageYears: 6.0,
              crclMlMin: crcl,
              allergyAssessmentStatus: AllergyAssessmentStatus.nkdaConfirmed,
            );
            expect(res.recommendedFrequency, equals('q24h'));
            expect(res.dosesPerDay, equals(1));
            expect(res.finalRecommendedSingleDoseMg, closeTo(300.0, tol));
            expect(res.finalRecommendedDailyDoseMg, closeTo(300.0, tol));
          }
          for (final crcl in [10.0, 29.99]) {
            final res = TransparentDosageCalculator.calculate(
              drug: amoxicillin,
              weightKg: 20.0,
              ageYears: 6.0,
              crclMlMin: crcl,
              allergyAssessmentStatus: AllergyAssessmentStatus.nkdaConfirmed,
            );
            expect(res.recommendedFrequency, equals('q12h'));
            expect(res.dosesPerDay, equals(2));
            expect(res.finalRecommendedSingleDoseMg, closeTo(300.0, tol));
            expect(res.finalRecommendedDailyDoseMg, closeTo(600.0, tol));
          }
          final amox30 = TransparentDosageCalculator.calculate(
            drug: amoxicillin,
            weightKg: 20.0,
            ageYears: 6.0,
            crclMlMin: 30.0,
            allergyAssessmentStatus: AllergyAssessmentStatus.nkdaConfirmed,
          );
          expect(amox30.recommendedFrequency, equals('q8h'));
          expect(amox30.dosesPerDay, equals(3));
          expect(amox30.finalRecommendedDailyDoseMg, closeTo(900.0, tol));

          // 4. Ibuprofen exact cutoffs: 0.0, 29.99 -> Contraindicated (Non-Blocking); 30.0, 59.99 -> factor 0.5; 60.0 -> factor 1.0
          for (final crcl in [0.0, 29.99]) {
            final res = TransparentDosageCalculator.calculate(
              drug: ibuprofen,
              weightKg: 20.0,
              ageYears: 7.0,
              crclMlMin: crcl,
              allergyAssessmentStatus: AllergyAssessmentStatus.nkdaConfirmed,
            );
            expect(res.isRenallyContraindicated, isTrue);
            expect(res.finalRecommendedSingleDoseMg, closeTo(200.0, tol));
            expect(res.practicalVolumeMl, closeTo(10.0, tol));
          }
          for (final crcl in [30.0, 59.99]) {
            final res = TransparentDosageCalculator.calculate(
              drug: ibuprofen,
              weightKg: 20.0,
              ageYears: 7.0,
              crclMlMin: crcl,
              allergyAssessmentStatus: AllergyAssessmentStatus.nkdaConfirmed,
            );
            expect(res.isRenallyContraindicated, isFalse);
            expect(res.renalDoseAdjustmentFactor, closeTo(0.5, tol));
            expect(res.finalRecommendedSingleDoseMg, closeTo(100.0, tol));
          }
          final ibu60 = TransparentDosageCalculator.calculate(
            drug: ibuprofen,
            weightKg: 20.0,
            ageYears: 7.0,
            crclMlMin: 60.0,
            allergyAssessmentStatus: AllergyAssessmentStatus.nkdaConfirmed,
          );
          expect(ibu60.renalDoseAdjustmentFactor, closeTo(1.0, tol));
          expect(ibu60.finalRecommendedSingleDoseMg, closeTo(200.0, tol));
        },
      );
    },
  );

  group('Phase 3.4 — Extreme, Edge, and Audit Bug Verification Tests (Bugs 3, 4, 5, 6)', () {
    test(
      'Bug 3 Fix: Enforces dose_range min/max mg/kg, max_daily_dose_mg_per_kg, and customDosesPerDay limits',
      () {
        final paracetamol = kb.findDrug('paracetamol_oral_susp')!;

        // 1. 5 kg child given customDoseRateMgPerKg = 150 mg/kg (raw = 750 mg < 1000 mg adult max,
        //    but 10x the 15 mg/kg pediatric max -> MUST cap at 75 mg and emit criticalOverdose!)
        final pedOverdose = TransparentDosageCalculator.calculate(
          drug: paracetamol,
          weightKg: 5.0,
          ageYears: 0.5,
          crclMlMin: 90.0,
          customDoseRateMgPerKg: 150.0,
          allergyAssessmentStatus: AllergyAssessmentStatus.nkdaConfirmed,
        );
        expect(pedOverdose.rawCalculatedSingleDoseMg, closeTo(750.0, tol));
        expect(pedOverdose.isMgPerKgCappedAtMax, isTrue);
        expect(pedOverdose.isSingleDoseCappedAtMax, isTrue);
        expect(pedOverdose.finalRecommendedSingleDoseMg, closeTo(75.0, tol));
        expect(
          pedOverdose.safetyAlerts.any(
            (a) =>
                a.type == SafetyAlertType.overdoseWarning &&
                a.severity == SafetyAlertSeverity.criticalOverdose,
          ),
          isTrue,
        );

        // 2. Subtherapeutic dose (< 10 mg/kg/dose for Paracetamol)
        final subtherapeutic = TransparentDosageCalculator.calculate(
          drug: paracetamol,
          weightKg: 15.0,
          ageYears: 4.0,
          crclMlMin: 90.0,
          customDoseRateMgPerKg: 5.0,
          allergyAssessmentStatus: AllergyAssessmentStatus.nkdaConfirmed,
        );
        expect(subtherapeutic.isDoseBelowMinimumRange, isTrue);
        expect(
          subtherapeutic.safetyAlerts.any(
            (a) => a.type == SafetyAlertType.subtherapeuticDoseWarning,
          ),
          isTrue,
        );

        // 3. customDosesPerDay > maxDosesPerDay (e.g. 8 > 5 for Paracetamol)
        final excessFreq = TransparentDosageCalculator.calculate(
          drug: paracetamol,
          weightKg: 15.0,
          ageYears: 4.0,
          crclMlMin: 90.0,
          customDosesPerDay: 8,
          allergyAssessmentStatus: AllergyAssessmentStatus.nkdaConfirmed,
        );
        expect(excessFreq.dosesPerDay, equals(5));
        expect(
          excessFreq.safetyAlerts.any(
            (a) => a.type == SafetyAlertType.frequencyExceedsMaxWarning,
          ),
          isTrue,
        );
      },
    );

    test(
      'Bug 4 Fix: Emits info-level unassessedInputNotice when age, CrCl, or allergy status are not assessed',
      () {
        final ibuprofen = kb.findDrug('ibuprofen_oral_susp')!;

        final unassessedResult = TransparentDosageCalculator.calculate(
          drug: ibuprofen,
          weightKg: 10.0,
          // ageYears: null, crclMlMin: null, allergyAssessmentStatus: null (defaults to notAssessed)
        );

        expect(unassessedResult.informationalNotices.length, equals(3));
        expect(
          unassessedResult.inputSummary.toFormattedString(),
          contains('ประวัติแพ้ยา: ไม่ได้ประเมิน (Not Assessed)'),
        );
        expect(
          unassessedResult.inputSummary
              .toFormattedString()
              .contains('ปฏิเสธแพ้ยา (NKDA)'),
          isFalse,
        );
      },
    );

    test(
      'Bug 5 Fix: Rejects short substring false positives ("in", "a"), matches Thai/brand/typo names, and warns on unrecognized drugs',
      () {
        final paracetamol = kb.findDrug('paracetamol_oral_susp')!;
        final amoxicillin = kb.findDrug('amoxicillin_oral_susp')!;
        final ibuprofen = kb.findDrug('ibuprofen_oral_susp')!;

        // 1. Short strings "in" and "a" must NOT falsely trigger Penicillin, Aspirin, or Warfarin!
        final shortStringResult = TransparentDosageCalculator.calculate(
          drug: amoxicillin,
          weightKg: 20.0,
          ageYears: 6.0,
          crclMlMin: 90.0,
          allergies: const ['in', 'a'],
          concomitantMedications: const ['in', 'a'],
        );
        expect(shortStringResult.hasAllergyAlert, isFalse);
        expect(shortStringResult.hasDrugInteractionAlert, isFalse);
        expect(
          shortStringResult.unrecognizedAllergies,
          containsAll(['in', 'a']),
        );
        expect(
          shortStringResult.unrecognizedConcomitantMedications,
          containsAll(['in', 'a']),
        );
        expect(
          shortStringResult.safetyAlerts.where(
            (a) => a.type == SafetyAlertType.unrecognizedMedicationNotice,
          ),
          hasLength(4),
        );

        // 2. Trade names ("Tylenol", "Marevan", "Brufen", "Keflex") and Thai names ("วาร์ฟาริน", "พาราเซตามอล")
        //    and single-character typos ("warfrin", "amoxicilin") MUST match!
        final thaiAndTypoPara = TransparentDosageCalculator.calculate(
          drug: paracetamol,
          weightKg: 20.0,
          ageYears: 6.0,
          crclMlMin: 90.0,
          allergies: const ['พาราเซตามอล'],
          concomitantMedications: const ['warfrin'],
        );
        expect(thaiAndTypoPara.hasAllergyAlert, isTrue);
        expect(thaiAndTypoPara.hasDrugInteractionAlert, isTrue);

        final brandIbu = TransparentDosageCalculator.calculate(
          drug: ibuprofen,
          weightKg: 20.0,
          ageYears: 7.0,
          crclMlMin: 90.0,
          allergies: const ['Brufen'],
          concomitantMedications: const ['Marevan', 'Renitec'],
        );
        expect(brandIbu.hasAllergyAlert, isTrue);
        expect(brandIbu.hasDrugInteractionAlert, isTrue);
        expect(
          brandIbu.safetyAlerts
              .where((a) => a.type == SafetyAlertType.drugInteraction)
              .length,
          equals(2),
        );

        // 3. Unknown concomitant drugs ("Vitamin C", "Simvastatin") emit unrecognizedMedicationNotice
        final unknownMeds = TransparentDosageCalculator.calculate(
          drug: amoxicillin,
          weightKg: 20.0,
          ageYears: 6.0,
          crclMlMin: 90.0,
          allergies: const ['', '   '],
          allergyAssessmentStatus: AllergyAssessmentStatus.nkdaConfirmed,
          concomitantMedications: const ['Vitamin C', 'Simvastatin'],
        );
        expect(unknownMeds.hasAllergyAlert, isFalse);
        expect(unknownMeds.hasDrugInteractionAlert, isFalse);
        expect(
          unknownMeds.unrecognizedConcomitantMedications,
          equals(['Vitamin C', 'Simvastatin']),
        );
        expect(
          unknownMeds.safetyAlerts.where(
            (a) => a.type == SafetyAlertType.unrecognizedMedicationNotice,
          ),
          hasLength(2),
        );
      },
    );

    test(
      'Bug 6 Fix: Precision-matched 2-decimal rounding (< 1.0 mL), > 3% discrepancy warning, and < 0.05 mL micro-volume guard',
      () {
        final paracetamol = kb.findDrug('paracetamol_oral_susp')!;

        // 1. 0.5 kg neonate: exactVolumeMl = 0.3125 mL (< 1.0 mL) -> automatically uses 2 decimals (0.31 mL, -0.80% error)
        final neonateResult = TransparentDosageCalculator.calculate(
          drug: paracetamol,
          weightKg: 0.5,
          ageYears: 0.1,
          crclMlMin: 80.0,
          allergyAssessmentStatus: AllergyAssessmentStatus.nkdaConfirmed,
        );
        expect(neonateResult.isWeightBelowMinimumCriteria, isTrue);
        expect(neonateResult.rawCalculatedSingleDoseMg, closeTo(7.5, tol));
        expect(neonateResult.exactVolumeMl, closeTo(0.3125, tol));
        expect(neonateResult.practicalVolumeDecimalsUsed, equals(2));
        expect(neonateResult.practicalVolumeMl, closeTo(0.31, tol));
        expect(neonateResult.actualDeliveredSingleDoseMg, closeTo(7.44, tol));
        expect(neonateResult.roundingDiscrepancyPercent, closeTo(-0.8, tol));
        expect(
          neonateResult.dispensingDeviceRecommendation,
          contains('1 mL Oral/Tuberculin Syringe'),
        );

        // 2. If 1-decimal rounding is explicitly forced on 0.3125 mL -> 0.3 mL (-4.0% > 3.0% threshold),
        //    emits roundingDeviationWarning!
        final coarseNeonate = TransparentDosageCalculator.calculate(
          drug: paracetamol,
          weightKg: 0.5,
          ageYears: 0.1,
          crclMlMin: 80.0,
          allergyAssessmentStatus: AllergyAssessmentStatus.nkdaConfirmed,
          practicalVolumeDecimals: 1,
        );
        expect(coarseNeonate.practicalVolumeMl, closeTo(0.3, tol));
        expect(coarseNeonate.roundingDiscrepancyPercent, closeTo(-4.0, tol));
        expect(
          coarseNeonate.safetyAlerts.any(
            (a) => a.type == SafetyAlertType.roundingDeviationWarning,
          ),
          isTrue,
        );

        // 3. Micro-volume < 0.05 mL (e.g. 0.4 kg with 2 mg/kg = 0.8 mg / 24 mg/mL = 0.0333 mL)
        //    emits contraindicated roundingDeviationWarning!
        final microVolResult = TransparentDosageCalculator.calculate(
          drug: paracetamol,
          weightKg: 0.4,
          ageYears: 0.1,
          crclMlMin: 80.0,
          customDoseRateMgPerKg: 2.0,
          allergyAssessmentStatus: AllergyAssessmentStatus.nkdaConfirmed,
        );
        expect(microVolResult.exactVolumeMl, lessThan(0.05));
        expect(
          microVolResult.safetyAlerts.any(
            (a) =>
                a.type == SafetyAlertType.roundingDeviationWarning &&
                a.severity == SafetyAlertSeverity.contraindicated,
          ),
          isTrue,
        );

        // 4. 300 kg bariatric adult: caps at 1,000 mg single / 4,000 mg daily (4 doses/day) & recommends Graduated Cup
        final bariatricResult = TransparentDosageCalculator.calculate(
          drug: paracetamol,
          weightKg: 300.0,
          ageYears: 40.0,
          crclMlMin: 90.0,
          allergyAssessmentStatus: AllergyAssessmentStatus.nkdaConfirmed,
        );
        expect(bariatricResult.rawCalculatedSingleDoseMg, closeTo(4500.0, tol));
        expect(
          bariatricResult.finalRecommendedSingleDoseMg,
          closeTo(1000.0, tol),
        );
        expect(bariatricResult.dosesPerDay, equals(4));
        expect(
          bariatricResult.finalRecommendedDailyDoseMg,
          closeTo(4000.0, tol),
        );
        expect(bariatricResult.isSingleDoseCappedAtMax, isTrue);
        expect(bariatricResult.isDailyDoseCappedAtMax, isTrue);
        expect(
          bariatricResult.dispensingDeviceRecommendation,
          contains('Graduated Medication Cup'),
        );
      },
    );

    test(
      'Rejects weight <= 0, NaN, Infinity, negative age, negative CrCl, dosesPerDay <= 0, and concentration <= 0',
      () {
        final paracetamol = kb.findDrug('paracetamol_oral_susp')!;

        for (final badWeight in [
          0.0,
          -0.1,
          -15.0,
          double.nan,
          double.infinity,
          double.negativeInfinity,
        ]) {
          expect(
            () => TransparentDosageCalculator.calculate(
              drug: paracetamol,
              weightKg: badWeight,
            ),
            throwsA(isA<InvalidPatientInputException>()),
            reason: 'Weight $badWeight must throw InvalidPatientInputException',
          );
        }

        for (final badAge in [-0.01, -5.0, double.nan, double.infinity]) {
          expect(
            () => TransparentDosageCalculator.calculate(
              drug: paracetamol,
              weightKg: 15.0,
              ageYears: badAge,
            ),
            throwsA(isA<InvalidPatientInputException>()),
          );
        }

        for (final badCrCl in [-0.01, -10.0, double.nan, double.infinity]) {
          expect(
            () => TransparentDosageCalculator.calculate(
              drug: paracetamol,
              weightKg: 15.0,
              crclMlMin: badCrCl,
            ),
            throwsA(isA<InvalidPatientInputException>()),
          );
        }

        expect(
          () => TransparentDosageCalculator.calculate(
            drug: paracetamol,
            weightKg: 15.0,
            customDosesPerDay: 0,
          ),
          throwsA(isA<InvalidPatientInputException>()),
        );

        final zeroConcMap = paracetamol.toJson();
        final infoMap = Map<String, dynamic>.from(
          zeroConcMap['drug_info'] as Map<String, dynamic>,
        );
        infoMap['concentration_mg_per_ml'] = 0.0;
        zeroConcMap['drug_info'] = infoMap;
        final zeroConcDrug = VerifiedDrugEntry.fromJson(zeroConcMap);

        expect(
          () => TransparentDosageCalculator.calculate(
            drug: zeroConcDrug,
            weightKg: 15.0,
          ),
          throwsA(isA<InvalidPatientInputException>()),
        );
      },
    );
  });
}
