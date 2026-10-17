import 'dart:math' as math;

import '../models/transparent_calculation_result.dart';
import '../models/verified_drug_schema.dart';
import '../validators/safety_check_engine.dart';

/// Deterministic, Pure-Function Dosage Calculator (Pillar 2: Zero Runtime AI Math).
///
/// Key guarantees:
/// 1. **Unified Non-Blocking Policy**: Calculated doses and volumes are NEVER
///    zeroed out or hidden on Overdose, Renal Contraindication ("Avoid"), or
///    Allergy alerts; instead, explicit flags and red safety alerts are attached.
/// 2. **Self-Consistent Daily Cap & Frequency**: Whenever `singleDose * dosesPerDay`
///    would exceed the daily ceiling, `dosesPerDay` is deterministically reduced via
///    `floor(maxDailyDose / singleDose)` so following the single dose and frequency
///    never exceeds the maximum daily dose.
/// 3. **Precision-Matched Syringe Rounding**: Uses `2` decimal places (`0.01 mL`)
///    automatically when `exactVolumeMl < 1.0 mL` (matching a 1 mL syringe) and
///    `1` decimal place (`0.1 mL`) when `>= 1.0 mL`, alerting if rounding
///    discrepancy exceeds `3.0%` or volume is `< 0.05 mL`.
class TransparentDosageCalculator {
  const TransparentDosageCalculator._();

  /// Calculates the medication dosage and evaluates all safety rules for a patient.
  ///
  /// Throws [InvalidPatientInputException] if `weightKg <= 0`, `ageYears < 0`,
  /// `crclMlMin < 0`, `dosesPerDay <= 0`, or `concentrationMgPerMl <= 0`.
  static TransparentCalculationResult calculate({
    required VerifiedDrugEntry drug,
    required double weightKg,
    double? ageYears,
    double? crclMlMin,
    String? renalMetricType,
    List<String> allergies = const [],
    AllergyAssessmentStatus? allergyAssessmentStatus,
    List<String> concomitantMedications = const [],
    double? customDoseRateMgPerKg,
    int? customDosesPerDay,
    int? practicalVolumeDecimals,
  }) {
    final info = drug.drugInfo;
    final rules = drug.dosingRules;

    final requestedDosesPerDay = customDosesPerDay ?? rules.maxDosesPerDay;
    final effectiveDoseRate = customDoseRateMgPerKg ??
        rules.doseRange.recommendedMgPerKgPerDose;

    // 1. Validate inputs strictly (no negative, zero, NaN, or Infinite values)
    SafetyCheckEngine.validatePatientInputs(
      weightKg: weightKg,
      ageYears: ageYears,
      crclMlMin: crclMlMin,
      dosesPerDay: requestedDosesPerDay,
      customDoseRateMgPerKg: effectiveDoseRate,
      concentrationMgPerMl: info.concentrationMgPerMl,
    );

    final effectiveDosesPerDay = requestedDosesPerDay > rules.maxDosesPerDay
        ? rules.maxDosesPerDay
        : requestedDosesPerDay;

    final hasNonEmptyAllergy = allergies.any((a) => a.trim().isNotEmpty);
    final effectiveAllergyStatus = hasNonEmptyAllergy
        ? AllergyAssessmentStatus.hasAllergies
        : (allergyAssessmentStatus ?? AllergyAssessmentStatus.notAssessed);

    final effectiveRenalMetricType = renalMetricType ??
        ((ageYears != null && ageYears < 18.0)
            ? 'eGFR_schwartz_ml_min_1_73m2'
            : 'crcl_cockcroft_gault_ml_min');

    final inputSummary = TransparentPatientInputSummary(
      weightKg: weightKg,
      ageYears: ageYears,
      crclMlMin: crclMlMin,
      renalMetricType: effectiveRenalMetricType,
      allergies: List.unmodifiable(allergies),
      allergyAssessmentStatus: effectiveAllergyStatus,
      concomitantMedications: List.unmodifiable(concomitantMedications),
    );

    final steps = <String>[];
    final alerts = <TransparentSafetyAlert>[];
    final formulaType = rules.formulaType.trim();
    final citation =
        '${drug.verificationMetadata.sourceName} (${drug.verificationMetadata.editionAndPage})';

    // Check patient age & weight criteria (non-blocking clinical alert)
    var isAgeBelowMinimum = false;
    var isWeightBelowMinimum = false;

    if (ageYears != null) {
      final minAgeYears = rules.patientCriteria.minAgeMonths / 12.0;
      if (ageYears + 1e-9 < minAgeYears) {
        isAgeBelowMinimum = true;
        alerts.add(
          TransparentSafetyAlert(
            type: SafetyAlertType.patientCriteriaWarning,
            severity: SafetyAlertSeverity.contraindicated,
            title:
                '🚨 อายุผู้ป่วยต่ำกว่าเกณฑ์ขั้นต่ำของสูตรยานี้ (< ${rules.patientCriteria.minAgeMonths} เดือน)',
            message:
                'อายุผู้ป่วย (${(ageYears * 12.0).toStringAsFixed(1)} เดือน / ${ageYears.toStringAsFixed(2)} ปี) ต่ำกว่าเกณฑ์ขั้นต่ำที่กำหนดไว้ (${rules.patientCriteria.minAgeMonths} เดือน)',
            mechanism:
                'ทารกอายุน้อยมีอัตราการกรองของไตและการกำจัดยาทางตับที่ยังพัฒนาไม่สมบูรณ์ เสี่ยงต่อพิษจากยารุนแรง (เช่น NSAIDs ในทารก < 6 เดือนเสี่ยงต่อไตวายเฉียบพลัน)',
            management:
                'หลีกเลี่ยงการใช้ในทารกอายุต่ำกว่า ${rules.patientCriteria.minAgeMonths} เดือน หรือปรึกษาแพทย์ผู้เชี่ยวชาญทารกแรกเกิด',
            reference: citation,
          ),
        );
      }
    }

    if (weightKg + 1e-9 < rules.patientCriteria.minWeightKg) {
      isWeightBelowMinimum = true;
      alerts.add(
        TransparentSafetyAlert(
          type: SafetyAlertType.patientCriteriaWarning,
          severity: SafetyAlertSeverity.major,
          title:
              '⚠️ น้ำหนักผู้ป่วยต่ำกว่าเกณฑ์มาตรฐาน (< ${rules.patientCriteria.minWeightKg.toStringAsFixed(1)} kg)',
          message:
              'น้ำหนักผู้ป่วย (${weightKg.toStringAsFixed(2)} kg) ต่ำกว่าเกณฑ์ขั้นต่ำของสูตรยานี้ (${rules.patientCriteria.minWeightKg.toStringAsFixed(1)} kg)',
          mechanism:
              'ผู้ป่วยทารกคลอดก่อนกำหนดหรือน้ำหนักตัวน้อยมากอาจต้องการสูตรการให้ยาเฉพาะสำหรับ Neonatal ICU',
          management:
              'ตรวจสอบขนาดยาสำหรับทารกแรกเกิดน้ำหนักน้อย (Neofax / Harriet Lane Neonatal Dosing)',
          reference: citation,
        ),
      );
    }

    // 2. Step-by-Step Weight-Based Dose Calculation (supports both mg/kg/dose and mg/kg/day)
    late final String formulaUsed;
    late final double rawCalculatedDailyDoseMg;
    late final double rawCalculatedSingleDoseMg;
    late final double maxWeightBasedSingleDoseMg;

    if (formulaType == 'mg_per_kg_per_day') {
      formulaUsed =
          'Single Dose (mg) = (Weight [kg] × Daily Dose Rate [mg/kg/day]) ÷ Doses Per Day, then Volume (mL) = Dose (mg) ÷ Concentration (mg/mL)';
      rawCalculatedDailyDoseMg = weightKg * effectiveDoseRate;
      rawCalculatedSingleDoseMg =
          rawCalculatedDailyDoseMg / requestedDosesPerDay;
      maxWeightBasedSingleDoseMg =
          (weightKg * rules.doseRange.maxMgPerKgPerDose) / effectiveDosesPerDay;

      steps.add(
        'ขั้นที่ 1 (คำนวณขนาดยารวมต่อวันตามน้ำหนัก - mg/kg/day): '
        '${_fmt(weightKg)} kg × ${_fmt(effectiveDoseRate)} mg/kg/day = ${_fmt(rawCalculatedDailyDoseMg)} mg/day',
      );
      steps.add(
        'ขั้นที่ 2 (แบ่งขนาดยาตามจำนวนมื้อต่อวัน - ${rules.frequencyHours}, $requestedDosesPerDay มื้อ/วัน): '
        '${_fmt(rawCalculatedDailyDoseMg)} mg/day ÷ $requestedDosesPerDay มื้อ = ${_fmt(rawCalculatedSingleDoseMg)} mg/ครั้ง',
      );
    } else {
      formulaUsed =
          'Single Dose (mg) = Weight [kg] × Dose Rate [mg/kg/dose], then Volume (mL) = Dose (mg) ÷ Concentration (mg/mL)';
      rawCalculatedSingleDoseMg = weightKg * effectiveDoseRate;
      rawCalculatedDailyDoseMg =
          rawCalculatedSingleDoseMg * requestedDosesPerDay;
      maxWeightBasedSingleDoseMg =
          weightKg * rules.doseRange.maxMgPerKgPerDose;

      steps.add(
        'ขั้นที่ 1 (คำนวณขนาดยาต่อครั้งตามน้ำหนัก - mg/kg/dose): '
        '${_fmt(weightKg)} kg × ${_fmt(effectiveDoseRate)} mg/kg/dose = ${_fmt(rawCalculatedSingleDoseMg)} mg/ครั้ง '
        '(หากให้สูงสุด $requestedDosesPerDay มื้อ/วัน = ${_fmt(rawCalculatedDailyDoseMg)} mg/day)',
      );
    }

    // 3. Dose-Range & Ceiling Check (min/max mg/kg, max_daily_dose_mg_per_kg, max_single_dose_mg, max_daily_dose_mg)
    final isDoseBelowMinimumRange =
        effectiveDoseRate + 1e-9 < rules.doseRange.minMgPerKgPerDose;
    final isMgPerKgCappedAtMax =
        effectiveDoseRate > rules.doseRange.maxMgPerKgPerDose + 1e-9;

    final effectiveMaxSingleDoseMg = math.min(
      rules.maxSingleDoseMg,
      maxWeightBasedSingleDoseMg,
    );
    final maxWeightBasedDailyDoseMg = rules.maxDailyDoseMgPerKg > 0
        ? weightKg * rules.maxDailyDoseMgPerKg
        : rules.maxDailyDoseMg;
    final effectiveMaxDailyDoseMg = math.min(
      rules.maxDailyDoseMg,
      maxWeightBasedDailyDoseMg,
    );

    final isSingleCapped =
        rawCalculatedSingleDoseMg > effectiveMaxSingleDoseMg + 1e-9;
    final isDailyCapped =
        rawCalculatedDailyDoseMg > effectiveMaxDailyDoseMg + 1e-9;

    final double cappedSingleDoseMg = isSingleCapped
        ? effectiveMaxSingleDoseMg
        : rawCalculatedSingleDoseMg;

    final ceilingStepNumber = steps.length + 1;
    if (isSingleCapped || isDailyCapped || isMgPerKgCappedAtMax) {
      steps.add(
        'ขั้นที่ $ceilingStepNumber (ตรวจสอบเพดานยาสูงสุด - Overdose Ceiling Check): '
        'ค่าที่คำนวณได้ตามน้ำหนักจริง = ${_fmt(rawCalculatedSingleDoseMg)} mg/ครั้ง '
        '(${_fmt(rawCalculatedDailyDoseMg)} mg/วัน) > ค่าเพดานสูงสุดตามตำรา = ${_fmt(effectiveMaxSingleDoseMg)} mg/ครั้ง '
        '(${_fmt(effectiveMaxDailyDoseMg)} mg/วัน) -> ปรับใช้ขนาดยาแนะนำต่อครั้ง ${_fmt(cappedSingleDoseMg)} mg/ครั้ง '
        '(คงแสดงค่าตามน้ำหนักจริงควบคู่ตามกฎ Non-Blocking Overdose Policy)',
      );
    } else {
      steps.add(
        'ขั้นที่ $ceilingStepNumber (ตรวจสอบเพดานยาสูงสุด - Max Dose Check): '
        'ค่าที่คำนวณได้ตามน้ำหนักจริง ${_fmt(rawCalculatedSingleDoseMg)} mg/ครั้ง '
        '<= เพดานสูงสุดตามตำรา ${_fmt(effectiveMaxSingleDoseMg)} mg/ครั้ง '
        '(และ ${_fmt(rawCalculatedDailyDoseMg)} mg/วัน <= ${_fmt(effectiveMaxDailyDoseMg)} mg/วัน -> อยู่ในเกณฑ์ปลอดภัย)',
      );
    }

    // 4. Renal Adjustment Check (crcl >= min && crcl < max)
    double renalFactor = 1.0;
    String recommendedFrequency = rules.frequencyHours;
    int adjustedDosesPerDay = effectiveDosesPerDay;
    bool isRenallyContraindicated = false;
    final renalStepNumber = steps.length + 1;

    if (crclMlMin != null) {
      final matchedTier = rules.findRenalAdjustmentForCrCl(crclMlMin);
      if (matchedTier != null) {
        isRenallyContraindicated = matchedTier.isContraindicated ||
            matchedTier.doseAdjustmentFactor == 0.0;
        renalFactor = matchedTier.doseAdjustmentFactor > 0.0
            ? matchedTier.doseAdjustmentFactor
            : 1.0;
        recommendedFrequency = matchedTier.adjustedInterval;
        adjustedDosesPerDay =
            matchedTier.adjustedDosesPerDay ?? effectiveDosesPerDay;

        steps.add(
          'ขั้นที่ $renalStepNumber (ตรวจสอบการปรับยาตามค่าไต - ${_fmt(crclMlMin)} ${inputSummary.renalUnitLabel}): '
          'เข้าเกณฑ์ช่วง [${_fmt(matchedTier.crclMinMlMin)} <= ค่าไต < ${_fmt(matchedTier.crclMaxMlMin)}] '
          '-> ตัวคูณขนาดยาต่อครั้ง = $renalFactor, ความถี่แนะนำ = $recommendedFrequency '
          '${isRenallyContraindicated ? "[ข้อห้ามใช้/หลีกเลี่ยง Avoid — แสดงตัวเลขตามนโยบาย Non-Blocking]" : ""}'
          ' (${matchedTier.clinicalNote})',
        );

        alerts.addAll(
          SafetyCheckEngine.evaluateRenalAlert(
            drug: drug,
            crclMlMin: crclMlMin,
            matchedTier: matchedTier,
          ),
        );
      } else {
        steps.add(
          'ขั้นที่ $renalStepNumber (ตรวจสอบการปรับยาตามค่าไต - ${_fmt(crclMlMin)} ${inputSummary.renalUnitLabel}): '
          'ใช้ขนาดยาปกติ (ตัวคูณ = 1.0, ความถี่ = $recommendedFrequency)',
        );
      }
    } else {
      steps.add(
        'ขั้นที่ $renalStepNumber (ตรวจสอบการปรับยาตามค่าไต): '
        'ไม่ได้ระบุค่าไต -> สมมติการทำงานของไตปกติชั่วคราว (ตัวคูณ = 1.0, ความถี่ = $recommendedFrequency)',
      );
    }

    final double finalRecommendedSingleDoseMg =
        cappedSingleDoseMg * renalFactor;

    // 5. Enforce Self-Consistent Daily Dose & Frequency (Bug 2 Fix):
    // If finalRecommendedSingleDoseMg * adjustedDosesPerDay > effectiveMaxDailyDoseMg,
    // reduce adjustedDosesPerDay via floor(effectiveMaxDailyDoseMg / finalRecommendedSingleDoseMg)
    // so that singleDose * dosesPerDay never exceeds the daily cap!
    var isFrequencyReducedForDailyMax = false;
    if (finalRecommendedSingleDoseMg > 0.0 &&
        finalRecommendedSingleDoseMg * adjustedDosesPerDay >
            effectiveMaxDailyDoseMg + 1e-9) {
      final maxSafeDoses = math.max(
        1,
        (effectiveMaxDailyDoseMg / finalRecommendedSingleDoseMg).floor(),
      );
      if (maxSafeDoses < adjustedDosesPerDay) {
        final previousDoses = adjustedDosesPerDay;
        adjustedDosesPerDay = maxSafeDoses;
        isFrequencyReducedForDailyMax = true;
        recommendedFrequency =
            '$recommendedFrequency (สูงสุดไม่เกิน $adjustedDosesPerDay มื้อ/วัน)';
        final freqStepNumber = steps.length + 1;
        steps.add(
          'ขั้นที่ $freqStepNumber (จำกัดจำนวนมื้อต่อวันเพื่อไม่ให้เกินเพดานรายวัน - Daily Cap Consistency): '
          'เนื่องจาก ${_fmt(finalRecommendedSingleDoseMg)} mg/ครั้ง × $previousDoses มื้อ/วัน '
          '= ${_fmt(finalRecommendedSingleDoseMg * previousDoses)} mg/วัน > เพดานรายวัน ${_fmt(effectiveMaxDailyDoseMg)} mg/วัน '
          '-> ลดจำนวนมื้อสูงสุดเหลือ floor(${_fmt(effectiveMaxDailyDoseMg)} ÷ ${_fmt(finalRecommendedSingleDoseMg)}) = $adjustedDosesPerDay มื้อ/วัน '
          '(รวม ${_fmt(finalRecommendedSingleDoseMg * adjustedDosesPerDay)} mg/วัน)',
        );
      }
    }

    final double rawRenalDailyMg =
        finalRecommendedSingleDoseMg * adjustedDosesPerDay;
    final double finalRecommendedDailyDoseMg =
        rawRenalDailyMg > effectiveMaxDailyDoseMg
            ? effectiveMaxDailyDoseMg
            : rawRenalDailyMg;

    // Evaluate Max Dose / Dose Range / Frequency alerts now that final daily dose is known
    alerts.insertAll(
      isAgeBelowMinimum && isWeightBelowMinimum
          ? 2
          : (isAgeBelowMinimum || isWeightBelowMinimum ? 1 : 0),
      SafetyCheckEngine.evaluateMaxDoseAlerts(
        drug: drug,
        weightKg: weightKg,
        effectiveDoseRateMgPerKg: effectiveDoseRate,
        requestedDosesPerDay: requestedDosesPerDay,
        rawCalculatedSingleDoseMg: rawCalculatedSingleDoseMg,
        rawCalculatedDailyDoseMg: rawCalculatedDailyDoseMg,
        finalRecommendedSingleDoseMg: finalRecommendedSingleDoseMg,
        finalRecommendedDailyDoseMg: finalRecommendedDailyDoseMg,
        effectiveMaxSingleDoseMg: effectiveMaxSingleDoseMg,
        effectiveMaxDailyDoseMg: effectiveMaxDailyDoseMg,
      ),
    );

    // 6. Volume Conversion (Exact Volume vs Practical Volume with Precision-Matched Syringe Rounding)
    final double exactVolumeMl =
        finalRecommendedSingleDoseMg / info.concentrationMgPerMl;
    final int decimalsUsed = practicalVolumeDecimals ??
        ((exactVolumeMl > 0.0 && exactVolumeMl < 1.0) ? 2 : 1);

    final double practicalVolumeMl = roundHalfAwayFromZero(
      exactVolumeMl,
      decimalsUsed,
    );

    final double actualDeliveredSingleDoseMg =
        practicalVolumeMl * info.concentrationMgPerMl;
    final double roundingDiscrepancyMg =
        actualDeliveredSingleDoseMg - finalRecommendedSingleDoseMg;
    final double roundingDiscrepancyPercent =
        finalRecommendedSingleDoseMg > 0.0
            ? (roundingDiscrepancyMg / finalRecommendedSingleDoseMg) * 100.0
            : 0.0;

    final String dispensingDevice =
        recommendDispensingDevice(exactVolumeMl > 0 ? exactVolumeMl : practicalVolumeMl);

    final double rawUnclippedExactVolumeMl =
        rawCalculatedSingleDoseMg / info.concentrationMgPerMl;
    final int rawDecimalsUsed = practicalVolumeDecimals ??
        ((rawUnclippedExactVolumeMl > 0.0 && rawUnclippedExactVolumeMl < 1.0)
            ? 2
            : 1);
    final double rawUnclippedPracticalVolumeMl = roundHalfAwayFromZero(
      rawUnclippedExactVolumeMl,
      rawDecimalsUsed,
    );

    final volumeStepNumber = steps.length + 1;
    steps.add(
      'ขั้นที่ $volumeStepNumber (แปลงเป็นปริมาตรยาน้ำ - ความเข้มข้น ${info.strengthLabel} หรือ ${_fmt(info.concentrationMgPerMl)} mg/mL): '
      '${_fmt(finalRecommendedSingleDoseMg)} mg ÷ ${_fmt(info.concentrationMgPerMl)} mg/mL '
      '= ${_fmtVolumeExact(exactVolumeMl)} mL (Exact Volume) '
      '-> ปัดเศษแบบ Round Half Away From Zero ($decimalsUsed ตำแหน่ง) = ${practicalVolumeMl.toStringAsFixed(decimalsUsed)} mL (Practical Volume, '
      'ได้เนื้อยาจริง ${_fmt(actualDeliveredSingleDoseMg)} mg, คลาดเคลื่อน ${roundingDiscrepancyPercent >= 0 ? "+" : ""}${roundingDiscrepancyPercent.toStringAsFixed(2)}%) '
      '| อุปกรณ์ตวงแนะนำ: $dispensingDevice',
    );

    // Check micro-volume (< 0.05 mL or rounded to 0.0 mL) and rounding discrepancy (> 3%)
    if (exactVolumeMl < 0.05 || practicalVolumeMl <= 0.0) {
      alerts.add(
        TransparentSafetyAlert(
          type: SafetyAlertType.roundingDeviationWarning,
          severity: SafetyAlertSeverity.contraindicated,
          title:
              '🚨 ปริมาตรยาต่อครั้งน้อยเกินไป (< 0.05 mL) ไม่สามารถตวงด้วยกระบอกฉีดยามาตรฐานได้อย่างปลอดภัย',
          message:
              'ปริมาตรที่คำนวณได้ (${_fmtVolumeExact(exactVolumeMl)} mL -> ปัดเศษ ${practicalVolumeMl.toStringAsFixed(decimalsUsed)} mL) ต่ำกว่าขีดความสามารถในการตวงของกระบอกฉีดยา 1 mL มาตรฐาน',
          mechanism:
              'การตวงปริมาตรน้อยกว่า 0.05 mL มีความคลาดเคลื่อนสัมพัทธ์สูงมาก หรืออาจถูกปัดเศษเป็น 0.0 mL จนผู้ป่วยไม่ได้รับยา',
          management:
              'ห้ามตวงโดยตรง — โปรดเลือกตำรับยาที่มีความเข้มข้นต่ำกว่า หรือเจือจางยา (Extemporaneous Dilution) ตามแนวทางเภสัชกรรมโรงพยาบาล',
          reference: citation,
        ),
      );
    } else if (roundingDiscrepancyPercent.abs() > 3.0 + 1e-9) {
      alerts.add(
        TransparentSafetyAlert(
          type: SafetyAlertType.roundingDeviationWarning,
          severity: roundingDiscrepancyPercent.abs() > 10.0
              ? SafetyAlertSeverity.major
              : SafetyAlertSeverity.moderate,
          title:
              '⚠️ ความคลาดเคลื่อนจากการปัดเศษปริมาตรยาเกินเกณฑ์ (> 3.0%): ${roundingDiscrepancyPercent >= 0 ? "+" : ""}${roundingDiscrepancyPercent.toStringAsFixed(2)}%',
          message:
              'การปัดเศษปริมาตรจาก ${_fmtVolumeExact(exactVolumeMl)} mL เป็น ${practicalVolumeMl.toStringAsFixed(decimalsUsed)} mL ทำให้ได้รับเนื้อยาจริง ${_fmt(actualDeliveredSingleDoseMg)} mg (ต่างจากขนาดยาแนะนำ ${_fmt(finalRecommendedSingleDoseMg)} mg คิดเป็น ${roundingDiscrepancyPercent >= 0 ? "+" : ""}${roundingDiscrepancyPercent.toStringAsFixed(2)}%)',
          mechanism:
              'ปริมาตรยาน้อยหรือการปัดเศษทศนิยมหยาบเกินไปทำให้สัดส่วนเนื้อยาที่ผู้ป่วยได้รับเบี่ยงเบนเกิน ±3%',
          management:
              'พิจารณาใช้กระบอกฉีดยาขนาด 1 mL (ความละเอียด 0.01 mL) เพื่อตวงปริมาตรที่มีทศนิยม 2 ตำแหน่ง',
          reference: citation,
        ),
      );
    }

    // 7. Allergy (Synonym / Same-Class / Cross-Reactivity), DDI, and Unassessed Input Checks
    final allergyOutput = SafetyCheckEngine.evaluateAllergiesDetailed(
      drug: drug,
      patientAllergies: allergies,
    );
    final ddiOutput = SafetyCheckEngine.evaluateDrugInteractionsDetailed(
      drug: drug,
      concomitantMedications: concomitantMedications,
    );
    final unassessedNotices = SafetyCheckEngine.evaluateUnassessedInputs(
      drug: drug,
      ageYears: ageYears,
      crclMlMin: crclMlMin,
      allergyAssessmentStatus: effectiveAllergyStatus,
    );

    alerts.addAll(allergyOutput.matchedAlerts);
    alerts.addAll(ddiOutput.matchedAlerts);
    alerts.addAll(unassessedNotices);

    final hasTrueAllergyAlert = allergyOutput.matchedAlerts.any(
      (a) =>
          a.type == SafetyAlertType.allergySynonymMatch ||
          a.type == SafetyAlertType.allergySameClass ||
          a.type == SafetyAlertType.allergyCrossReactivity,
    );
    final hasTrueDdiAlert = ddiOutput.matchedAlerts.any(
      (a) => a.type == SafetyAlertType.drugInteraction,
    );

    final totalRulesEvaluated = 2 + // Max single & daily ceiling rules
        rules.renalAdjustment.length +
        drug.safetyChecks.allergyCrossReactivity.length +
        drug.safetyChecks.drugInteractions.length;

    return TransparentCalculationResult(
      inputSummary: inputSummary,
      formulaUsed: formulaUsed,
      calculationSteps: List.unmodifiable(steps),
      safetyAlerts: List.unmodifiable(alerts),
      referenceCitation: drug.verificationMetadata,
      drugId: info.drugId,
      genericName: info.genericName,
      strengthLabel: info.strengthLabel,
      concentrationMgPerMl: info.concentrationMgPerMl,
      formulaType: formulaType,
      dosesPerDay: adjustedDosesPerDay,
      recommendedFrequency: recommendedFrequency,
      roundingRuleUsed: 'ROUND_HALF_AWAY_FROM_ZERO',
      rawCalculatedDailyDoseMg: rawCalculatedDailyDoseMg,
      rawCalculatedSingleDoseMg: rawCalculatedSingleDoseMg,
      renalDoseAdjustmentFactor: renalFactor,
      finalRecommendedSingleDoseMg: finalRecommendedSingleDoseMg,
      finalRecommendedDailyDoseMg: finalRecommendedDailyDoseMg,
      exactVolumeMl: exactVolumeMl,
      practicalVolumeMl: practicalVolumeMl,
      practicalVolumeDecimalsUsed: decimalsUsed,
      actualDeliveredSingleDoseMg: actualDeliveredSingleDoseMg,
      roundingDiscrepancyMg: roundingDiscrepancyMg,
      roundingDiscrepancyPercent: roundingDiscrepancyPercent,
      dispensingDeviceRecommendation: dispensingDevice,
      rawUnclippedExactVolumeMl: rawUnclippedExactVolumeMl,
      rawUnclippedPracticalVolumeMl: rawUnclippedPracticalVolumeMl,
      isSingleDoseCappedAtMax: isSingleCapped,
      isDailyDoseCappedAtMax: isDailyCapped,
      isMgPerKgCappedAtMax: isMgPerKgCappedAtMax,
      isDoseBelowMinimumRange: isDoseBelowMinimumRange,
      isFrequencyReducedForDailyMax: isFrequencyReducedForDailyMax,
      isRenallyContraindicated: isRenallyContraindicated,
      hasAllergyAlert: hasTrueAllergyAlert,
      hasDrugInteractionAlert: hasTrueDdiAlert,
      isAgeBelowMinimumCriteria: isAgeBelowMinimum,
      isWeightBelowMinimumCriteria: isWeightBelowMinimum,
      totalSafetyRulesEvaluated: totalRulesEvaluated,
      unrecognizedAllergies:
          List.unmodifiable(allergyOutput.unrecognizedAllergies),
      unrecognizedConcomitantMedications:
          List.unmodifiable(ddiOutput.unrecognizedMedications),
    );
  }

  /// Deterministic Round Half Away From Zero (`>= 0.5` rounds up for positive values).
  /// Uses a tiny epsilon (`1e-12`) to prevent IEEE-754 binary float representation
  /// artifacts (e.g. `1.25 * 10 = 12.499999999999998`) from mis-rounding.
  static double roundHalfAwayFromZero(double value, int decimals) {
    if (value == 0.0 || value.isNaN || value.isInfinite) return value;
    double factor = 1.0;
    for (var i = 0; i < decimals; i++) {
      factor *= 10.0;
    }
    final sign = value < 0 ? -1.0 : 1.0;
    final scaled = value.abs() * factor;
    final rounded = (scaled + 0.5 + 1e-12).floorToDouble();
    return (sign * rounded) / factor;
  }

  /// Deterministic clinical dispensing device selection based on volume (`mL`).
  static String recommendDispensingDevice(double volumeMl) {
    if (volumeMl <= 1.0) {
      return '1 mL Oral/Tuberculin Syringe (กระบอกฉีดยาขนาด 1 mL ความละเอียด 0.01 mL)';
    } else if (volumeMl <= 5.0) {
      return '5 mL Oral Syringe (กระบอกฉีดยาป้อนยาขนาด 5 mL ความละเอียด 0.1 mL)';
    } else if (volumeMl <= 10.0) {
      return '10 mL Oral Syringe (กระบอกฉีดยาป้อนยาขนาด 10 mL ความละเอียด 0.1-0.2 mL)';
    } else if (volumeMl <= 20.0) {
      return '20 mL Oral Syringe (กระบอกฉีดยาป้อนยาขนาด 20 mL)';
    } else {
      return 'Graduated Medication Cup (ถ้วยตวงยามาตรฐาน หรือพิจารณาเปลี่ยนเป็นยาเม็ด เนื่องจากปริมาตรเกินกระบอกฉีดยา 20 mL)';
    }
  }

  static String _fmt(double value) {
    if ((value - value.roundToDouble()).abs() < 1e-9) {
      return value.toStringAsFixed(1);
    }
    return value.toStringAsFixed(2);
  }

  static String _fmtVolumeExact(double value) {
    final twoDec = (value * 100).roundToDouble() / 100.0;
    if ((value - twoDec).abs() < 1e-9) {
      return value.toStringAsFixed(2);
    }
    return value.toStringAsFixed(4);
  }
}
