// ============================================================
// Drug Dosage Calculator — Ward Pharmacist Dosing Engine
// ============================================================
// Deterministic, pure clinical calculation engine.
// Single source of truth for all dose calculations across Drugph.
//
// DISCLAIMER: SaMD prototype — not for clinical use.
// ============================================================

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
      final warnings = <DoseWarning>[];

      // --- 1. Population Applicability Check (D4, 4.1) ---
      if (regimen.population != null) {
        final popWarnings = regimen.population!.checkApplicability(patient);
        warnings.addAll(popWarnings);
      } else if (patient.ageYears < 18) {
        // Fallback adult safety gate if no explicit pediatric criteria
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

      // --- 2. Advanced Allergy Check (D9, A8) ---
      final allergyAlerts = AllergyService.evaluateAllergies(
        patientAllergies: patient.allergies,
        drugGenericName: drug.genericName,
        drugId: drug.id,
        drugClass: drug.drugClass,
        legacyAllergyClass: drug.allergyClass,
      );
      for (final alert in allergyAlerts) {
        warnings.add(DoseWarning(
          severity: alert.severity,
          code: DoseWarningCode.allergyAlert,
          messageEn: alert.messageEn,
          messageTh: alert.messageTh,
        ));
      }

      // --- 3. Contraindications & Drug-Drug Interactions (D9, A8) ---
      for (final c in drug.contraindications) {
        warnings.add(DoseWarning(
          severity: LimitSeverity.soft,
          code: DoseWarningCode.contraindicationAlert,
          messageEn: 'Contraindication: $c',
          messageTh: 'ข้อห้ามใช้/ข้อควรระวัง: $c',
        ));
      }

      // Symmetric & Active Drug Interaction Check (D9)
      for (final activeDrugId in patient.activeDrugIds) {
        final activeNorm = activeDrugId.trim().toLowerCase();
        for (final inter in drug.interactions) {
          if (inter.targetDrugId?.toLowerCase() == activeNorm) {
            final isHard = inter.severity == InteractionSeverity.contraindicated ||
                inter.severity == InteractionSeverity.major;
            warnings.add(DoseWarning(
              severity: isHard ? LimitSeverity.hard : LimitSeverity.soft,
              code: inter.severity == InteractionSeverity.contraindicated
                  ? DoseWarningCode.contraindicationAlert
                  : DoseWarningCode.severeInteractionAlert,
              messageEn:
                  '${inter.severity.labelEn} Interaction with $activeDrugId: ${inter.mechanismEn}. Action: ${inter.managementEn}',
              messageTh:
                  '${inter.severity.labelTh} ปฏิกิริยาระหว่างยากับ $activeDrugId: ${inter.mechanismTh}. คำแนะนำ: ${inter.managementTh}',
            ));
          }
        }
        for (final inter in drug.severeInteractions) {
          if (inter.toLowerCase().contains(activeNorm)) {
            warnings.add(DoseWarning(
              severity: LimitSeverity.hard,
              code: DoseWarningCode.severeInteractionAlert,
              messageEn: 'Severe interaction with active drug $activeDrugId: $inter',
              messageTh: 'ปฏิกิริยารุนแรงกับยาที่กำลังใช้อยู่ $activeDrugId: $inter',
            ));
          }
        }
      }

      // Informational notes for general severe interactions when no active drugs are specified
      if (patient.activeDrugIds.isEmpty) {
        for (final inter in drug.severeInteractions) {
          warnings.add(DoseWarning(
            severity: LimitSeverity.info,
            code: DoseWarningCode.severeInteractionAlert,
            messageEn: 'Severe drug interaction potential: $inter',
            messageTh: 'ปฏิกิริยาระหว่างยาที่สำคัญ: $inter',
          ));
        }
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

      // --- 5. Renal Function Evaluation & Database Review Check (D5, D6, A5, A11) ---
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

      // D6 Database Lint Alert: Flag drugs requiring renal adjustment without reviewed tiers
      if (drug.requiresRenalAdjustment &&
          drug.renalReviewStatus != RenalReviewStatus.notApplicable &&
          (regimen.renalAdjustments == null || regimen.renalAdjustments!.isEmpty)) {
        warnings.add(
          const DoseWarning(
            severity: LimitSeverity.hard,
            code: DoseWarningCode.severeRenalImpairment,
            messageEn:
                'DATABASE WARNING: Drug requires renal adjustment but has unreviewed/empty renal tiers.',
            messageTh:
                'เตือนฐานข้อมูล: ยานี้ต้องปรับตามไตแต่ยังไม่มีตารางปรับขนาดยาในระบบ',
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

      // --- 7. Exhaustive Dosing Calculation (A2, D1, D2) ---
      double baseDose = 0.0;
      String formulaUsed = regimen.dosingType.nameEn;

      switch (regimen.dosingType) {
        case DosingType.weightBased:
          final dosePerKg = regimen.dosePerKg ?? regimen.minDosePerKg ?? 0.0;
          baseDose = WeightBasedCalculator.calculateDose(
            weightKg: weightForDosing,
            dosePerKg: dosePerKg,
          );
          formulaUsed =
              'Weight-based ($dosePerKg ${regimen.doseUnit.symbol}/kg with $weightStrategyUsed)';
          break;

        case DosingType.fixed:
          baseDose = regimen.fixedDose ?? 0.0;
          formulaUsed =
              'Fixed Dose (${baseDose.toStringAsFixed(0)} ${regimen.doseUnit.symbol})';
          break;

        case DosingType.bsaBased:
          final bsa = BsaCalculator.mosteller(
            heightCm: patient.heightCm,
            weightKg: patient.weightKg,
          );
          final dosePerM2 = regimen.dosePerM2 ?? 0.0;
          baseDose = WeightBasedCalculator.calculateBsaDose(
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
          baseDose = WeightBasedCalculator.calvertFormula(
            targetAuc: targetAuc,
            gfrMlMin: crcl,
          );
          formulaUsed = 'Calvert Formula (AUC $targetAuc × [CrCl + 25])';
          break;

        case DosingType.titrated:
          baseDose = 0.0;
          final continuousUnitStr = regimen.rateUnit?.symbol ??
              regimen.continuousRateUnit ??
              'mcg/kg/min';
          formulaUsed =
              'Titrated Infusion (${regimen.continuousRateMin ?? 0.0} $continuousUnitStr)';
          break;

        case DosingType.renalAdjusted:
          if (regimen.fixedDose != null) {
            baseDose = regimen.fixedDose!;
            formulaUsed =
                'Renal-adjusted (${baseDose.toStringAsFixed(0)} ${regimen.doseUnit.symbol})';
          } else if (regimen.dosePerKg != null) {
            baseDose = WeightBasedCalculator.calculateDose(
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

      // --- 8. DoseBasis (Per-Dose vs Per-Day vs Per-Week) (D1) ---
      double dose = baseDose;
      if (regimen.dosingType != DosingType.titrated &&
          regimen.doseBasis == DoseBasis.perDay) {
        final dPerDay = regimen.frequency.dosesPerDay;
        if (dPerDay != null && dPerDay > 0) {
          dose = baseDose / dPerDay;
          formulaUsed +=
              ' [Total daily ${baseDose.toStringAsFixed(1)} ${regimen.doseUnit.symbol}/day divided by $dPerDay doses]';
        } else {
          warnings.add(
            const DoseWarning(
              severity: LimitSeverity.soft,
              code: DoseWarningCode.unknownFrequency,
              messageEn:
                  'Daily dose basis configured, but frequency interval is irregular/PRN. Dose not divided.',
              messageTh:
                  'กำหนดขนาดยาต่อวัน แต่ความถี่ไม่คงที่ ไม่สามารถหารขนาดยาต่อครั้งได้',
            ),
          );
        }
      }

      // --- 9. Automated Renal Adjustment & Half-Open Range Tiers (D5) ---
      double finalDose = dose;
      Frequency finalFrequency = regimen.frequency;
      bool isRenallyAdjusted = false;
      double? appliedRenalFactor;
      String? renalNotesEn;
      String? renalNotesTh;

      // Do NOT apply secondary renal factor to Calvert (GFR-based) or titrated
      if (regimen.dosingType != DosingType.gfrBased &&
          regimen.dosingType != DosingType.titrated &&
          crcl != null &&
          regimen.renalAdjustments != null) {
        for (final adj in regimen.renalAdjustments!) {
          if (adj.appliesTo(crcl)) {
            // Check for Hard Contraindication / Avoid Action (D5)
            if (adj.action == RenalAction.avoid ||
                adj.action == RenalAction.contraindicated) {
              final noteEn = adj.notes ??
                  'CONTRAINDICATED in renal impairment (CrCl < ${adj.crclMax} mL/min).';
              final noteTh = adj.notesTh ??
                  'ข้อห้ามใช้เด็ดขาดในผู้ป่วยไตบกพร่อง (CrCl < ${adj.crclMax} มล./นาที)';
              warnings.add(DoseWarning(
                severity: LimitSeverity.hard,
                code: DoseWarningCode.contraindicationAlert,
                messageEn: noteEn,
                messageTh: noteTh,
              ));
              return DosageResult.failure(
                reasonEn: noteEn,
                reasonTh: noteTh,
                formulaUsed: formulaUsed,
                crclMlMin: crcl,
                warnings: warnings,
              );
            }

            if (adj.action == RenalAction.monitorOnly) {
              warnings.add(DoseWarning(
                severity: LimitSeverity.info,
                code: DoseWarningCode.renalAdjustmentApplied,
                messageEn: adj.notes ?? 'Monitor renal function closely.',
                messageTh: adj.notesTh ?? 'ติดตามการทำงานของไตอย่างใกล้ชิด',
              ));
            } else if (adj.action == RenalAction.adjust) {
              if (adj.absoluteDose != null) {
                finalDose = adj.absoluteDose!;
                isRenallyAdjusted = true;
              } else if (adj.adjustmentFactor < 1.0) {
                finalDose = finalDose * adj.adjustmentFactor;
                isRenallyAdjusted = true;
                appliedRenalFactor = adj.adjustmentFactor;
              }

              if (adj.adjustedFrequency != null) {
                finalFrequency = adj.adjustedFrequency!;
                isRenallyAdjusted = true;
              }

              renalNotesEn = adj.notes;
              renalNotesTh = adj.notesTh;

              warnings.add(
                DoseWarning(
                  severity: LimitSeverity.info,
                  code: DoseWarningCode.renalAdjustmentApplied,
                  messageEn:
                      'Auto Renal Adjustment applied for CrCl ${crcl.toStringAsFixed(1)} mL/min${adj.notes != null ? ": ${adj.notes}" : ""}.',
                  messageTh:
                      'ปรับขนาดยาอัตโนมัติตามค่า CrCl ${crcl.toStringAsFixed(1)} mL/min${adj.notesTh != null ? ": ${adj.notesTh}" : ""}',
                ),
              );
            }
            break; // Stop at first matching tier
          }
        }
      }

      // Apixaban 2-of-3 Criteria Rule (D5)
      final isApixaban =
          drug.id == 'apixaban' || drug.genericName.toLowerCase().contains('apixaban');
      final isAf = regimen.indication?.toLowerCase().contains('af') ?? false;
      if (isApixaban && isAf) {
        int criteriaCount = 0;
        if (patient.ageYears >= 80) criteriaCount++;
        if (patient.weightKg <= 60.0) criteriaCount++;
        if ((patient.serumCreatinineMgDl ?? 0.0) >= 1.5) criteriaCount++;

        if (criteriaCount >= 2) {
          finalDose = 2.5;
          finalFrequency = Frequency.q12h;
          isRenallyAdjusted = true;
          warnings.add(
            const DoseWarning(
              severity: LimitSeverity.info,
              code: DoseWarningCode.renalAdjustmentApplied,
              messageEn:
                  'Apixaban dose reduced to 2.5 mg BID (meets ≥2 criteria: Age ≥80, Weight ≤60 kg, SCr ≥1.5 mg/dL).',
              messageTh:
                  'ปรับลดขนาดยา Apixaban เป็น 2.5 mg วันละ 2 ครั้ง (เข้าเกณฑ์ ≥2 ข้อ: อายุ ≥80, นน. ≤60 กก., SCr ≥1.5 mg/dL)',
            ),
          );
        }
      }

      // Critical renal impairment check (< 10 mL/min)
      if (crcl != null && crcl < 10.0) {
        if (!warnings.any((w) => w.code == DoseWarningCode.severeRenalImpairment)) {
          warnings.add(
            DoseWarning(
              severity: LimitSeverity.hard,
              code: DoseWarningCode.severeRenalImpairment,
              messageEn:
                  'CRITICAL RENAL IMPAIRMENT: CrCl ${crcl.toStringAsFixed(1)} mL/min < 10 mL/min.',
              messageTh:
                  'การทำงานของไตวิกฤต: CrCl ${crcl.toStringAsFixed(1)} มล./นาที ต่ำกว่า 10 มล./นาที',
            ),
          );
        }
      }

      // --- 10. Continuous Infusion & Titrated Regimens (D2) ---
      InfusionResult? infusionResult;
      if (regimen.dosingType == DosingType.titrated) {
        final rate = regimen.continuousRateMin ?? 0.0;
        final rateUnit = regimen.rateUnit ??
            (regimen.continuousRateUnit != null
                ? RateUnit.fromSymbol(regimen.continuousRateUnit!)
                : RateUnit.mcgKgMin);
        double? rateMlPerHour;

        if (regimen.standardDilutionMgPerMl != null &&
            regimen.standardDilutionMgPerMl! > 0) {
          if (rateUnit == RateUnit.mcgKgMin) {
            final mgPerHr = (rate * weightForDosing * 60.0) / 1000.0;
            rateMlPerHour = mgPerHr / regimen.standardDilutionMgPerMl!;
          } else if (rateUnit == RateUnit.mgHr) {
            rateMlPerHour = rate / regimen.standardDilutionMgPerMl!;
          } else if (rateUnit == RateUnit.uKgHr) {
            rateMlPerHour =
                (rate * weightForDosing) / regimen.standardDilutionMgPerMl!;
          }
        }

        infusionResult = InfusionResult(
          rate: rate,
          rateUnit: rateUnit,
          rateMlPerHr: rateMlPerHour,
          instructionsEn:
              'Titrate continuously according to clinical protocol ($rate ${rateUnit.symbol}).',
          instructionsTh:
              'ปรับอัตราการหยดยาอย่างต่อเนื่องตามโปรโตคอลคลินิก ($rate ${rateUnit.nameTh})',
        );
      }

      // --- 11. Formulary Rounding (4.3) ---
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

      // --- 12. Safety Limits & Daily Dose Check (A6, D1, 4.2) ---
      double? dailyDose;
      if (regimen.dosingType != DosingType.titrated) {
        final dPerDay = finalFrequency.dosesPerDay;
        if (dPerDay != null && dPerDay > 0) {
          dailyDose = finalDose * dPerDay;
        } else {
          warnings.add(
            const DoseWarning(
              severity: LimitSeverity.soft,
              code: DoseWarningCode.unknownFrequency,
              messageEn:
                  'Daily dose limits not checked because frequency is variable, PRN, or continuous.',
              messageTh:
                  'ไม่สามารถตรวจสอบขีดจำกัดขนาดยาต่อวันได้ เนื่องจากความถี่เป็นแบบเมื่อจำเป็น หรือไม่คงที่',
            ),
          );
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

      // --- 13. Infusion Preparation (A8) ---
      double? volumeMl;
      double? infusionRateMlPerHr;
      double? infusionDurationMinutes = regimen.infusionTimeMinutes;
      double? dripRateDropsPerMin;

      if (regimen.dosingType != DosingType.titrated &&
          regimen.standardDilutionMgPerMl != null &&
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
          infusionDurationMinutes > 0 &&
          finalDose > 0) {
        final actualRateMgPerMin = finalDose / infusionDurationMinutes;
        warnings.addAll(
          DoseChecker.checkInfusionRate(
            rateMgPerMin: actualRateMgPerMin,
            maxRateMgPerMin: regimen.maxInfusionRateMgPerMin!,
          ),
        );
      }

      // --- 14. Audit Inputs Snapshot (B2) ---
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
            ? null
            : finalDose,
        doseUnit: regimen.doseUnit,
        frequency: finalFrequency.displayEn,
        structuredFrequency: finalFrequency,
        dailyDose: dailyDose,
        infusionResult: infusionResult,
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
        renalNotes: renalNotesEn,
        renalNotesTh: renalNotesTh,
        roundedDose: roundedDose,
        activePhases: regimen.phases,
        warnings: warnings,
      );
    } catch (e) {
      return DosageResult.failure(
        reasonEn: 'Calculation error: $e',
        reasonTh: 'เกิดข้อผิดพลาดในการคำนวณ: $e',
      );
    }
  }

  /// Verifies an ordered prescription against recommended dosing rules (D7).
  static OrderVerificationResult verifyOrder({
    required Patient patient,
    required Drug drug,
    required DosingRegimen regimen,
    required double orderedDose,
    required Frequency orderedFrequency,
    double? orderedRate,
  }) {
    final recommended = calculateDose(
      patient: patient,
      drug: drug,
      regimen: regimen,
    );

    final verificationWarnings = <DoseWarning>[];
    verificationWarnings.addAll(recommended.warnings);

    double? deviation;
    final targetDose = recommended.roundedDose ?? recommended.calculatedDose;
    if (targetDose != null && targetDose > 0) {
      deviation = ((orderedDose - targetDose).abs() / targetDose) * 100.0;
    }

    if (deviation != null && deviation > 15.0) {
      verificationWarnings.add(
        DoseWarning(
          severity: deviation > 30.0 ? LimitSeverity.hard : LimitSeverity.soft,
          code: DoseWarningCode.maxSingleDoseExceeded,
          messageEn:
              'ORDER DEVIATION: Ordered dose ($orderedDose ${regimen.doseUnit.symbol}) deviates by ${deviation.toStringAsFixed(1)}% from recommended (${targetDose?.toStringAsFixed(1)} ${regimen.doseUnit.symbol}).',
          messageTh:
              'ขนาดยาคลาดเคลื่อน: ขนาดยาที่สั่ง ($orderedDose ${regimen.doseUnit.symbol}) ต่างจากที่แนะนำ (${targetDose?.toStringAsFixed(1)} ${regimen.doseUnit.symbol}) อยู่ ${deviation.toStringAsFixed(1)}%',
        ),
      );
    }

    final isAcceptable = !recommended.isBlocked &&
        !verificationWarnings.any((w) => w.severity == LimitSeverity.hard);

    return OrderVerificationResult(
      isAcceptable: isAcceptable,
      recommendedResult: recommended,
      orderedDose: orderedDose,
      orderedFrequency: orderedFrequency,
      deviationPercent: deviation,
      warnings: verificationWarnings,
      summaryEn: isAcceptable
          ? 'Order is clinically acceptable.'
          : 'Order requires pharmacist review or intervention.',
      summaryTh: isAcceptable
          ? 'คำสั่งใช้ยาผ่านเกณฑ์ความปลอดภัย'
          : 'คำสั่งใช้ยาต้องได้รับการตรวจสอบหรือปรึกษาแพทย์ผู้สั่ง',
    );
  }
}
