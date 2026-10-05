import '../models/models.dart';
import 'calculators.dart';

/// The central core engine for a Ward Pharmacist.
/// Pure, deterministic, and side-effect free.
class PharmacistCalculator {
  const PharmacistCalculator._();

  /// Given a [patient], [drug], and specific [regimen], calculates the optimal
  /// dose, performs renal adjustment, rounds it, and returns the result.
  static DosageResult calculateDose({
    required Patient patient,
    required Drug drug,
    required DosingRegimen regimen,
  }) {
    try {
      // --- 1. Pediatric Boundary Check (4.1) ---
      if (patient.ageYears < 18) {
        return DosageResult.failure(
          reasonEn:
              'Pediatric patients (< 18 years) are not supported by this adult dosing engine.',
          reasonTh:
              'ระบบคำนวณยานี้สำหรับผู้ใหญ่ ไม่รองรับผู้ป่วยเด็ก (อายุ < 18 ปี)',
          warnings: const [
            DoseWarning(
              severity: LimitSeverity.hard,
              code: DoseWarningCode.pediatricBlocked,
              messageEn: 'Pediatric dosing (< 18 years) is blocked for safety.',
              messageTh:
                  'ไม่อนุญาตให้คำนวณขนาดยาในผู้ป่วยเด็ก (< 18 ปี) เพื่อความปลอดภัย',
            ),
          ],
        );
      }

      final warnings = <DoseWarning>[];

      // --- 2. Allergy Check (A8) ---
      for (final allergy in patient.allergies) {
        final a = allergy.trim().toLowerCase();
        if (a.isEmpty) continue;
        final gen = drug.genericName.toLowerCase();
        final aClass = drug.allergyClass?.toLowerCase() ?? '';
        if (gen.contains(a) || (aClass.isNotEmpty && aClass.contains(a))) {
          warnings.add(DoseWarning(
            severity: LimitSeverity.hard,
            code: DoseWarningCode.allergyAlert,
            messageEn:
                'PATIENT ALLERGY ALERT: Patient is allergic to "$allergy". Drug belongs to $aClass ($gen).',
            messageTh:
                'แจ้งเตือนการแพ้ยา: ผู้ป่วยมีประวัติแพ้ "$allergy" ยานี้อยู่ในกลุ่ม $aClass ($gen)',
          ));
          break;
        }
      }

      // --- 3. Contraindications & Severe Interactions (A8) ---
      for (final c in drug.contraindications) {
        warnings.add(DoseWarning(
          severity: LimitSeverity.soft,
          code: DoseWarningCode.contraindicationAlert,
          messageEn: 'Contraindication: $c',
          messageTh: 'ข้อห้ามใช้/ข้อควรระวัง: $c',
        ));
      }

      for (final inter in drug.severeInteractions) {
        warnings.add(DoseWarning(
          severity: LimitSeverity.info,
          code: DoseWarningCode.severeInteractionAlert,
          messageEn: 'Severe drug interaction potential: $inter',
          messageTh: 'ปฏิกิริยาระหว่างยาที่สำคัญ: $inter',
        ));
      }

      // --- 4. Determine Body Weight Metrics (4.5, A6) ---
      final ibw = WeightBasedCalculator.idealBodyWeight(
        heightCm: patient.heightCm,
        sex: patient.sex,
      );
      final isObese = WeightBasedCalculator.isObese(
        actualWeightKg: patient.weightKg,
        ibwKg: ibw,
      );
      final adjBw = WeightBasedCalculator.adjustedBodyWeight(
        actualWeightKg: patient.weightKg,
        ibwKg: ibw,
      );

      // Weight for Cockcroft-Gault CrCl (Winter 2010 guideline)
      double crclDosingWeight = patient.weightKg;
      if (patient.weightKg < ibw) {
        crclDosingWeight = patient.weightKg; // TBW
      } else if (patient.weightKg < 1.20 * ibw) {
        crclDosingWeight = ibw; // IBW
      } else {
        crclDosingWeight = adjBw; // AdjBW
      }

      // --- 5. Renal Function Evaluation (4.1, A5, A11) ---
      double? crcl;
      if (patient.serumCreatinineMgDl != null) {
        if (!patient.isScrStable) {
          warnings.add(
            const DoseWarning(
              severity: LimitSeverity.hard,
              code: DoseWarningCode.unstableScr,
              messageEn:
                  'AKI Alert: SCr is unstable. Cockcroft-Gault is inaccurate. Renal adjustment NOT applied.',
              messageTh:
                  'เตือน AKI: ค่า SCr ไม่คงที่ จึงไม่มีการปรับขนาดยาตามไตอัตโนมัติ',
            ),
          );
        } else {
          crcl = RenalCalculator.cockcroftGault(
            ageYears: patient.ageYears,
            weightKg: crclDosingWeight,
            sex: patient.sex,
            serumCreatinineMgDl: patient.serumCreatinineMgDl!,
          );

          if (patient.serumCreatinineMgDl! < 0.6 && patient.ageYears >= 65) {
            warnings.add(
              const DoseWarning(
                severity: LimitSeverity.soft,
                code: DoseWarningCode.generalAlert,
                messageEn:
                    'Elderly with low SCr (<0.6 mg/dL). CrCl may be overestimated.',
                messageTh:
                    'ผู้สูงอายุที่มี SCr ต่ำ (<0.6 mg/dL) ค่า CrCl ที่ได้อาจสูงเกินจริง',
              ),
            );
          }
        }
      } else if (patient.creatinineClearanceMlMin != null) {
        crcl = patient.creatinineClearanceMlMin;
        warnings.add(
          const DoseWarning(
            severity: LimitSeverity.info,
            code: DoseWarningCode.generalAlert,
            messageEn: 'Using manually entered Creatinine Clearance (CrCl).',
            messageTh: 'ใช้ค่า Creatinine Clearance (CrCl) ที่ระบุโดยตรง',
          ),
        );
      } else if (drug.requiresRenalAdjustment) {
        warnings.add(
          const DoseWarning(
            severity: LimitSeverity.hard,
            code: DoseWarningCode.scrMissing,
            messageEn:
                'RENAL ALERT: This drug requires dose adjustment in renal impairment, but Serum Creatinine was NOT provided.',
            messageTh:
                'เตือนความปลอดภัย: ยานี้ต้องปรับขนาดยาตามการทำงานของไต แต่ไม่ได้ระบุค่า SCr',
          ),
        );
      }

      // --- 6. Weight Strategy for Regimen (4.5) ---
      double weightForDosing = patient.weightKg;
      String weightStrategyUsed = 'TBW';
      switch (regimen.dosingWeightStrategy) {
        case DosingWeightStrategy.actual:
          weightForDosing = patient.weightKg;
          weightStrategyUsed = 'TBW';
          break;
        case DosingWeightStrategy.ideal:
          weightForDosing = ibw;
          weightStrategyUsed = 'IBW';
          break;
        case DosingWeightStrategy.adjustedIfObese:
          if (isObese) {
            weightForDosing = adjBw;
            weightStrategyUsed = 'AdjBW';
            warnings.add(DoseWarning(
              severity: LimitSeverity.info,
              code: DoseWarningCode.generalAlert,
              messageEn:
                  'Using Adjusted Body Weight (${adjBw.toStringAsFixed(1)} kg) for obese patient.',
              messageTh:
                  'ใช้น้ำหนักปรับปรุง (AdjBW ${adjBw.toStringAsFixed(1)} กก.) สำหรับผู้ป่วยอ้วน',
            ));
          } else if (patient.weightKg > ibw) {
            weightForDosing = ibw;
            weightStrategyUsed = 'IBW';
          } else {
            weightForDosing = patient.weightKg;
            weightStrategyUsed = 'TBW';
          }
          break;
      }

      // --- 7. Exhaustive Dosing Calculation (A2, 4.4) ---
      double dose = 0.0;
      double? continuousRate;
      String? continuousRateUnit;
      String formulaUsed = regimen.dosingType.nameEn;

      switch (regimen.dosingType) {
        case DosingType.weightBased:
          final dosePerKg = regimen.dosePerKg ?? regimen.minDosePerKg ?? 0.0;
          dose = WeightBasedCalculator.calculateDose(
            weightKg: weightForDosing,
            dosePerKg: dosePerKg,
          );
          formulaUsed =
              'Weight-based ($dosePerKg ${regimen.doseUnit.symbol}/kg with $weightStrategyUsed)';
          break;

        case DosingType.fixed:
          dose = regimen.fixedDose ?? 0.0;
          formulaUsed =
              'Fixed Dose (${dose.toStringAsFixed(0)} ${regimen.doseUnit.symbol})';
          break;

        case DosingType.bsaBased:
          final bsa = BsaCalculator.mosteller(
            heightCm: patient.heightCm,
            weightKg: patient.weightKg,
          );
          final dosePerM2 = regimen.dosePerM2 ?? 0.0;
          dose = WeightBasedCalculator.calculateBsaDose(
            bsaM2: bsa,
            dosePerM2: dosePerM2,
          );
          formulaUsed =
              'BSA-based Mosteller ($dosePerM2 ${regimen.doseUnit.symbol}/m²)';
          break;

        case DosingType.gfrBased:
          if (crcl == null) {
            return DosageResult.failure(
              reasonEn:
                  'Calvert formula requires CrCl / GFR. Please provide SCr.',
              reasonTh: 'สูตร Calvert ต้องใช้ค่า CrCl / GFR กรุณาระบุค่า SCr',
              formulaUsed: 'Calvert Formula',
              warnings: const [
                DoseWarning(
                  severity: LimitSeverity.hard,
                  code: DoseWarningCode.scrMissing,
                  messageEn:
                      'Calvert formula requires CrCl / GFR. Please provide SCr.',
                  messageTh:
                      'สูตร Calvert ต้องใช้ค่า CrCl / GFR กรุณาระบุค่า SCr',
                ),
              ],
            );
          }
          final targetAuc = regimen.targetAuc ?? 5.0;
          dose = WeightBasedCalculator.calvertFormula(
            targetAuc: targetAuc,
            gfrMlMin: crcl,
          );
          formulaUsed = 'Calvert Formula (AUC $targetAuc × [CrCl + 25])';
          break;

        case DosingType.titrated:
          continuousRate = regimen.continuousRateMin ?? 0.0;
          continuousRateUnit = regimen.continuousRateUnit ?? 'mcg/kg/min';
          dose = 0.0;
          formulaUsed = 'Titrated Infusion ($continuousRate $continuousRateUnit)';
          break;

        case DosingType.renalAdjusted:
          if (regimen.fixedDose != null) {
            dose = regimen.fixedDose!;
            formulaUsed =
                'Renal-adjusted (${dose.toStringAsFixed(0)} ${regimen.doseUnit.symbol})';
          } else if (regimen.dosePerKg != null) {
            dose = WeightBasedCalculator.calculateDose(
              weightKg: weightForDosing,
              dosePerKg: regimen.dosePerKg!,
            );
            formulaUsed =
                'Renal-adjusted (${regimen.dosePerKg} ${regimen.doseUnit.symbol}/kg)';
          } else {
            return DosageResult.failure(
              reasonEn: 'Renal-adjusted regimen has no base dose configured.',
              reasonTh: 'สูตรยาแบบปรับตามไตไม่ได้กำหนดขนาดยาเริ่มต้น',
              formulaUsed: 'Renal-adjusted',
            );
          }
          break;
      }

      // --- 8. Automated Renal Adjustment (4.4, 4.6) ---
      double finalDose = dose;
      String finalFrequency = regimen.frequency;
      bool isRenallyAdjusted = false;
      double? appliedRenalFactor;

      // Do NOT apply secondary renal factor to Calvert (GFR-based) or titrated
      if (regimen.dosingType != DosingType.gfrBased &&
          regimen.dosingType != DosingType.titrated &&
          crcl != null &&
          regimen.renalAdjustments != null) {
        for (final adj in regimen.renalAdjustments!) {
          if (adj.appliesTo(crcl)) {
            if (adj.adjustmentFactor < 1.0 || adj.adjustedFrequency != null) {
              finalDose = finalDose * adj.adjustmentFactor;
              finalFrequency = adj.adjustedFrequency ?? finalFrequency;
              isRenallyAdjusted = true;
              appliedRenalFactor = adj.adjustmentFactor;

              warnings.add(
                DoseWarning(
                  severity: LimitSeverity.info,
                  code: DoseWarningCode.renalAdjustmentApplied,
                  messageEn:
                      'Auto Renal Adjustment applied (CrCl ${crcl.toStringAsFixed(1)} mL/min).',
                  messageTh:
                      'ปรับขนาดยาอัตโนมัติตามค่า CrCl ${crcl.toStringAsFixed(1)} mL/min แล้ว',
                ),
              );
            }
            break;
          }
        }
      }

      // 4.6: Severe renal impairment check (< 10 mL/min)
      if (crcl != null) {
        final renalWarnings = DoseChecker.checkRenalAdjustment(
          crclMlMin: crcl,
          adjustments: regimen.renalAdjustments ?? [],
        );
        for (final rw in renalWarnings) {
          if (rw.code == DoseWarningCode.severeRenalImpairment &&
              !warnings
                  .any((w) => w.code == DoseWarningCode.severeRenalImpairment)) {
            warnings.add(rw);
          }
        }
      }

      // --- 9. Formulary Rounding (4.3) ---
      double? roundedDose;
      if (regimen.dosingType != DosingType.titrated &&
          drug.availableStrengths != null &&
          drug.availableStrengths!.isNotEmpty) {
        roundedDose = DoseRounder.roundToNearestStrength(
          finalDose,
          drug.availableStrengths!,
          isSplittable: drug.isSplittable,
        );
      }

      // --- 10. Safety Limits & Daily Dose Check (A6, 4.2) ---
      double? dailyDose;
      if (regimen.dosingType != DosingType.titrated) {
        final dPerDay = UnitConverter.dosesPerDay(finalFrequency);
        if (dPerDay > 0) {
          dailyDose = finalDose * dPerDay;
        }
      }

      if (regimen.limits != null && regimen.dosingType != DosingType.titrated) {
        warnings.addAll(
          DoseChecker.checkDose(
            calculatedDose: finalDose,
            limits: regimen.limits!,
            doseUnit: regimen.doseUnit.symbol,
            weightKg: weightForDosing,
            dailyDose: dailyDose,
          ),
        );
      }

      if (drug.isHighAlert) {
        warnings.insert(0, DoseChecker.highAlertWarning(drug.genericName));
      }

      // --- 11. Infusion Preparation (A8) ---
      double? volumeMl;
      double? infusionRateMlPerHr;
      double? infusionDurationMinutes = regimen.infusionTimeMinutes;
      double? dripRateDropsPerMin;

      if (regimen.standardDilutionMgPerMl != null &&
          regimen.standardDilutionMgPerMl! > 0 &&
          finalDose > 0) {
        volumeMl = finalDose / regimen.standardDilutionMgPerMl!;
        if (infusionDurationMinutes != null && infusionDurationMinutes > 0) {
          infusionRateMlPerHr = (volumeMl / infusionDurationMinutes) * 60.0;
          dripRateDropsPerMin = (volumeMl * 20.0) / infusionDurationMinutes;
        }
      }

      if (regimen.maxInfusionRateMgPerMin != null &&
          infusionDurationMinutes != null &&
          infusionDurationMinutes > 0) {
        final actualRateMgPerMin = finalDose / infusionDurationMinutes;
        warnings.addAll(
          DoseChecker.checkInfusionRate(
            rateMgPerMin: actualRateMgPerMin,
            maxRateMgPerMin: regimen.maxInfusionRateMgPerMin!,
          ),
        );
      }

      // --- 12. Audit Inputs Snapshot (B2) ---
      final auditInputs = <String, dynamic>{
        'patientId': patient.id,
        'weightKg': patient.weightKg,
        'heightCm': patient.heightCm,
        'ageYears': patient.ageYears,
        'sex': patient.sex.nameEn,
        'serumCreatinineMgDl': patient.serumCreatinineMgDl,
        'creatinineClearanceMlMin': crcl,
        'isScrStable': patient.isScrStable,
        'dosingWeightUsedKg': weightForDosing,
        'weightStrategy': weightStrategyUsed,
        'route': regimen.route.abbreviation,
        'indication': regimen.indication,
      };

      return DosageResult(
        success: true,
        calculatedDose: regimen.dosingType == DosingType.titrated
            ? continuousRate
            : finalDose,
        doseUnit: regimen.doseUnit,
        frequency: finalFrequency,
        dailyDose: dailyDose,
        volumeMl: volumeMl,
        infusionRateMlPerHr: infusionRateMlPerHr,
        infusionDurationMinutes: infusionDurationMinutes,
        dripRateDropsPerMin: dripRateDropsPerMin,
        formulaUsed: formulaUsed,
        calculationInputs: auditInputs,
        ibwKg: ibw,
        adjBwKg: adjBw,
        crclMlMin: crcl,
        isRenallyAdjusted: isRenallyAdjusted,
        renalAdjustmentFactor: appliedRenalFactor,
        roundedDose: roundedDose,
        warnings: warnings,
      );
    } catch (e) {
      return DosageResult.failure(
        reasonEn: 'Calculation error: $e',
        reasonTh: 'เกิดข้อผิดพลาดในการคำนวณ: $e',
      );
    }
  }
}
