// ============================================================
// Drug Dosage Calculator — Ward Pharmacist Dosing Engine
// ============================================================
// Deterministic, pure clinical calculation engine.
// Single source of truth for all dose calculations across Drugph.
//
// DISCLAIMER: SaMD prototype — not for clinical use.
// ============================================================

import '../models/models.dart';
import '../validators/input_validator.dart';
import '../../data/drug_database.dart';
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

      // --- 0. Input Validation (A12) ---
      final valRes = InputValidator.validatePatientInputs(
        weightKg: patient.weightKg,
        heightCm: patient.heightCm,
        ageYears: patient.ageYears,
        ageMonths: patient.ageMonths,
        serumCreatinineMgDl: patient.serumCreatinineMgDl,
      );
      if (!valRes.isValid) {
        final errEn = valRes.errorsEn.values.join('; ');
        final errTh = valRes.errorsTh.values.join('; ');
        return DosageResult.failure(
          reasonEn: errEn,
          reasonTh: errTh,
          formulaUsed: 'Input Validation',
          warnings: [
            DoseWarning(
              severity: LimitSeverity.hard,
              code: DoseWarningCode.calculationError,
              messageEn: errEn,
              messageTh: errTh,
            ),
          ],
        );
      }
      for (final key in valRes.warningsEn.keys) {
        warnings.add(DoseWarning(
          severity: LimitSeverity.soft,
          code: DoseWarningCode.generalAlert,
          messageEn: valRes.warningsEn[key]!,
          messageTh: valRes.warningsTh[key] ?? valRes.warningsEn[key]!,
        ));
      }

      // --- 1. Audience & Population Applicability Check (D4, 4.1) ---
      final isChild = patient.ageYears < 18;

      if (regimen.effectiveAudience == RegimenAudience.adult && isChild) {
        return DosageResult.failure(
          reasonEn:
              'Pediatric patients (< 18 years) are not supported by this adult dosing regimen.',
          reasonTh:
              'สูตรยานี้สำหรับผู้ใหญ่ ไม่รองรับผู้ป่วยเด็ก (อายุ < 18 ปี)',
          warnings: const [
            DoseWarning(
              severity: LimitSeverity.hard,
              code: DoseWarningCode.pediatricBlocked,
              messageEn: 'Pediatric dosing (< 18 years) is blocked for safety on adult regimens.',
              messageTh:
                  'ไม่อนุญาตให้ใช้สูตรยาสำหรับผู้ใหญ่ในผู้ป่วยเด็ก (< 18 ปี) เพื่อความปลอดภัย',
            ),
          ],
        );
      }

      if (regimen.effectiveAudience == RegimenAudience.pediatric && !isChild) {
        return DosageResult.failure(
          reasonEn:
              'Adult patients (≥ 18 years) cannot be dosed using a pediatric-only regimen.',
          reasonTh:
              'ผู้ป่วยผู้ใหญ่ (อายุ ≥ 18 ปี) ไม่สามารถใช้สูตรยาเฉพาะสำหรับเด็กได้',
          warnings: const [
            DoseWarning(
              severity: LimitSeverity.hard,
              code: DoseWarningCode.populationMismatch,
              messageEn: 'Pediatric regimen selected for an adult patient.',
              messageTh: 'เลือกสูตรยาเด็กสำหรับผู้ป่วยผู้ใหญ่',
            ),
          ],
        );
      }

      if (regimen.population != null) {
        final popWarnings = regimen.population!.checkApplicability(patient);
        warnings.addAll(popWarnings);
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
        final activeDrug = DrugDatabase.findById(activeDrugId);

        // Check current drug's interactions targeting active drug ID or active drug class
        for (final inter in drug.interactions) {
          final matchesId = inter.targetDrugId?.toLowerCase() == activeNorm;
          final matchesClass = inter.targetClass != null &&
              activeDrug?.drugClass == inter.targetClass;
          if (matchesId || matchesClass) {
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

        // Symmetric check: Check active drug's interactions targeting current drug ID or current drug class
        if (activeDrug != null) {
          for (final inter in activeDrug.interactions) {
            final matchesId = inter.targetDrugId?.toLowerCase() == drug.id.toLowerCase();
            final matchesClass = inter.targetClass != null &&
                drug.drugClass == inter.targetClass;
            if (matchesId || matchesClass) {
              final isHard = inter.severity == InteractionSeverity.contraindicated ||
                  inter.severity == InteractionSeverity.major;
              if (!warnings.any((w) => w.messageEn.contains('Interaction with $activeDrugId') || w.messageEn.contains('between ${drug.genericName} and $activeDrugId'))) {
                warnings.add(DoseWarning(
                  severity: isHard ? LimitSeverity.hard : LimitSeverity.soft,
                  code: inter.severity == InteractionSeverity.contraindicated
                      ? DoseWarningCode.contraindicationAlert
                      : DoseWarningCode.severeInteractionAlert,
                  messageEn:
                      '${inter.severity.labelEn} Interaction between ${drug.genericName} and $activeDrugId: ${inter.mechanismEn}. Action: ${inter.managementEn}',
                  messageTh:
                      '${inter.severity.labelTh} ปฏิกิริยาระหว่างยา ${drug.genericName} กับ $activeDrugId: ${inter.mechanismTh}. คำแนะนำ: ${inter.managementTh}',
                ));
              }
            }
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
      // Devine IBW is adult-only (≥18 years). For pediatric patients, TBW is used.
      final double ibw;
      final bool isObese;
      final double adjBw;
      double crclDosingWeight = patient.weightKg;

      if (isChild) {
        ibw = patient.weightKg;
        isObese = false;
        adjBw = patient.weightKg;
        crclDosingWeight = patient.weightKg;
      } else {
        ibw = WeightBasedCalculator.idealBodyWeight(
          heightCm: patient.heightCm,
          sex: patient.sex,
        );
        isObese = WeightBasedCalculator.isObese(
          actualWeightKg: patient.weightKg,
          ibwKg: ibw,
        );
        adjBw = WeightBasedCalculator.adjustedBodyWeight(
          actualWeightKg: patient.weightKg,
          ibwKg: ibw,
        );

        // Weight for Cockcroft-Gault CrCl (Winter 2010 guideline)
        if (patient.weightKg < ibw) {
          crclDosingWeight = patient.weightKg; // TBW
        } else if (patient.weightKg < 1.20 * ibw) {
          crclDosingWeight = ibw; // IBW
        } else {
          crclDosingWeight = adjBw; // AdjBW
        }
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
        } else if (isChild) {
          if (patient.ageYears >= 1) {
            crcl = RenalCalculator.bedsideSchwartz(
              heightCm: patient.heightCm,
              serumCreatinineMgDl: patient.serumCreatinineMgDl!,
            );
            warnings.add(
              DoseWarning(
                severity: LimitSeverity.info,
                code: DoseWarningCode.generalAlert,
                messageEn:
                    'Estimated GFR calculated via Bedside Schwartz equation (${crcl.toStringAsFixed(1)} mL/min/1.73 m²).',
                messageTh:
                    'ประเมิน eGFR ด้วยสูตร Bedside Schwartz (${crcl.toStringAsFixed(1)} มล./นาที/1.73 ตร.ม.) สำหรับผู้ป่วยเด็ก',
              ),
            );
          } else {
            // Infant < 1 year
            warnings.add(
              DoseWarning(
                severity: drug.requiresRenalAdjustment
                    ? LimitSeverity.hard
                    : LimitSeverity.soft,
                code: DoseWarningCode.generalAlert,
                messageEn:
                    'Infant (< 1 year): Standard eGFR equations are not validated. Consult pediatric nephrology/specialist dosing.',
                messageTh:
                    'ทารก (< 1 ปี): ไม่มีสูตรประเมินการทำงานของไตมาตรฐาน โปรดปรึกษาแพทย์เฉพาะทางเด็ก',
              ),
            );
          }
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
        const alt1En =
            'STAT / Initial Empiric Dose: For acute/emergency care, clinician may administer the initial standard dose safely while awaiting STAT laboratory serum creatinine results (Recommended for emergent therapy).';
        const alt1Th =
            'ขนาดยาฉุกเฉิน / เข็มแรก (STAT): สำหรับภาวะฉุกเฉิน สามารถบริหารยาขนาดยาเริ่มต้นมาตรฐานได้ทันทีในเข็มแรกระหว่างรอผลตรวจ Serum Creatinine ด่วน (แนะนำสำหรับกรณีวิกฤต/ฉุกเฉิน)';

        const alt2En =
            'Enter Serum Creatinine: Obtain STAT point-of-care or laboratory SCr/CrCl to calculate renal function and enable automated renal adjustment for subsequent doses.';
        const alt2Th =
            'ระบุค่าไต: เจาะตรวจ SCr หรือ CrCl ด่วน เพื่อให้ระบบคำนวณการทำงานของไตและปรับขนาดยาอัตโนมัติในมื้อถัดไป';

        const alt3En =
            'Clinician Override: Proceed with unadjusted dose if patient has recently documented normal renal function and stable urine output.';
        const alt3Th =
            'ขอยกเว้นเฉพาะราย: ให้ขนาดยาปกติได้หากผู้ป่วยมีประวัติการทำงานของไตปกติและปัสสาวะออกดีสม่ำเสมอ';

        warnings.add(
          const DoseWarning(
            severity: LimitSeverity.soft,
            code: DoseWarningCode.scrMissing,
            messageEn:
                'RENAL ALERT: This drug is eliminated renally and requires dose adjustment in kidney impairment, but Serum Creatinine is missing. '
                'Alternatives: 1) $alt1En 2) $alt2En 3) $alt3En',
            messageTh:
                'เตือนความปลอดภัย: ยานี้ขับออกทางไตและต้องปรับขนาดยาตามการทำงานของไต แต่ยังไม่ได้ระบุค่า SCr ในระบบ '
                'ทางเลือก: 1) $alt1Th 2) $alt2Th 3) $alt3Th',
            clinicalAlternativesEn: [alt1En, alt2En, alt3En],
            clinicalAlternativesTh: [alt1Th, alt2Th, alt3Th],
          ),
        );
      }

      // D6 Database Lint Alert: Flag drugs requiring renal adjustment without reviewed tiers
      if (drug.requiresRenalAdjustment &&
          regimen.dosingType != DosingType.gfrBased &&
          drug.renalReviewStatus != RenalReviewStatus.notApplicable &&
          (regimen.renalAdjustments == null || regimen.renalAdjustments!.isEmpty)) {
        warnings.add(
          DoseWarning(
            severity: LimitSeverity.soft,
            code: DoseWarningCode.severeRenalImpairment,
            messageEn:
                'DATABASE WARNING: Automated renal adjustment tiers are unreviewed for this drug regimen. '
                'Please verify dose manually via clinical reference (Lexicomp/Sanford) for CrCl ${crcl?.toStringAsFixed(1)} mL/min.',
            messageTh:
                'เตือนฐานข้อมูล: ยานี้ต้องปรับตามไตแต่ยังไม่มีตารางปรับขนาดยาในระบบ '
                'โปรดตรวจสอบขนาดยาจากคู่มืออ้างอิง (Lexicomp/Sanford) ด้วยตนเองสำหรับ CrCl ${crcl?.toStringAsFixed(1)} มล./นาที',
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

      // Cap dosing weight if regimen defines maxDosingWeightKg (e.g. IV NAC max 100 kg)
      if (regimen.maxDosingWeightKg != null &&
          weightForDosing > regimen.maxDosingWeightKg!) {
        final rawWeight = weightForDosing;
        weightForDosing = regimen.maxDosingWeightKg!;
        warnings.add(DoseWarning(
          severity: LimitSeverity.info,
          code: DoseWarningCode.generalAlert,
          messageEn:
              'Dosing weight capped at ${regimen.maxDosingWeightKg!.toStringAsFixed(0)} kg (actual: ${rawWeight.toStringAsFixed(1)} kg) per clinical guideline cap.',
          messageTh:
              'จำกัดน้ำหนักคำนวณยาสูงสุดไม่เกิน ${regimen.maxDosingWeightKg!.toStringAsFixed(0)} กก. (น้ำหนักจริง ${rawWeight.toStringAsFixed(1)} กก.) ตามแนวทางการรักษา',
        ));
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

      // --- 8.1 Smart Dose Capping with Rich Clinical Advisory (Weight-based) ---
      if (regimen.dosingType == DosingType.weightBased && regimen.limits != null) {
        final capSingle = regimen.limits!.maxSingleDose;
        final capDaily = regimen.limits!.maxDailyDose;
        final dPerDay = regimen.frequency.dosesPerDay ?? 1;

        double? effectiveCap;
        if (capSingle != null && dose > capSingle) {
          effectiveCap = capSingle;
        } else if (capDaily != null && (dose * dPerDay) > capDaily) {
          effectiveCap = capDaily / dPerDay;
        }

        if (effectiveCap != null && dose > effectiveCap) {
          final rawDose = dose;
          dose = effectiveCap;

          String fmtVal(double v) => v == v.roundToDouble()
              ? v.toStringAsFixed(0)
              : ((v * 10) == (v * 10).roundToDouble()
                  ? v.toStringAsFixed(1)
                  : v.toStringAsFixed(2));

          final alt1En =
              'Standard Ceiling: Administer guideline maximum capped dose of '
              '${fmtVal(effectiveCap)} ${regimen.doseUnit.symbol} '
              '${regimen.route.abbreviation.toUpperCase()} ${regimen.frequency.displayEn} (Recommended).';
          final alt1Th =
              'ขนาดยามาตรฐานสูงสุด: ให้ยาตามเกณฑ์เพดานสูงสุดที่จำกัดไว้ '
              '${fmtVal(effectiveCap)} ${regimen.doseUnit.symbol} '
              '${regimen.route.abbreviation.toUpperCase()} ${regimen.frequency.displayTh} (แนะนำเป็นอันดับแรก)';

          final alt2En =
              'Clinician Override: If treating high-MIC, resistant, or severe disseminated/CNS infection, '
              'clinician may consider dosing up to raw weight-based dose (${fmtVal(rawDose)} ${regimen.doseUnit.symbol}) '
              'under infectious disease specialist consultation with therapeutic drug monitoring (TDM) and toxicity surveillance.';
          final alt2Th =
              'ขอยกเว้นเฉพาะราย: หากรักษาการติดเชื้อสายพันธุ์ดื้อยา รุนแรง หรือลุกลามเข้าระบบประสาทส่วนกลาง '
              'แพทย์เฉพาะทางอาจพิจารณาขนาดยาเต็มตามน้ำหนักตัว (${fmtVal(rawDose)} ${regimen.doseUnit.symbol}) '
              'โดยต้องติดตามระดับยาในเลือดและเฝ้าระวังพิษจากยาอย่างใกล้ชิด';

          warnings.add(DoseWarning(
            severity: LimitSeverity.soft,
            code: DoseWarningCode.doseCappedAtMax,
            messageEn:
                'DOSE CAPPED AT GUIDELINE MAXIMUM: Raw weight-based calculation is '
                '${fmtVal(rawDose)} ${regimen.doseUnit.symbol}, which exceeds the guideline ceiling of '
                '${fmtVal(effectiveCap)} ${regimen.doseUnit.symbol}. Dose automatically capped to '
                '${fmtVal(effectiveCap)} ${regimen.doseUnit.symbol}. '
                'Alternatives: 1) $alt1En 2) $alt2En',
            messageTh:
                'จำกัดขนาดยาสูงสุดตามแนวทาง: ขนาดยาตามน้ำหนักตัวคำนวณได้ '
                '${fmtVal(rawDose)} ${regimen.doseUnit.symbol} ซึ่งเกินเพดานที่แนะนำ '
                '(${fmtVal(effectiveCap)} ${regimen.doseUnit.symbol}). ปรับลดลงมาที่ '
                '${fmtVal(effectiveCap)} ${regimen.doseUnit.symbol} อัตโนมัติ '
                'ทางเลือก: 1) $alt1Th 2) $alt2Th',
            calculatedValue: rawDose,
            limitValue: effectiveCap,
            unit: regimen.doseUnit.symbol,
            clinicalAlternativesEn: [alt1En, alt2En],
            clinicalAlternativesTh: [alt1Th, alt2Th],
          ));
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
      final indicationLower = regimen.indication?.toLowerCase() ?? '';
      final isAf = RegExp(r'\bafib\b|atrial fibrillation|\bnvaf\b')
          .hasMatch(indicationLower);
      if (isApixaban && isAf) {
        int criteriaCount = 0;
        if (patient.ageYears >= 80) criteriaCount++;
        if (patient.weightKg <= 60.0) criteriaCount++;
        if (patient.serumCreatinineMgDl != null) {
          if (patient.serumCreatinineMgDl! >= 1.5) criteriaCount++;
        } else {
          warnings.add(
            const DoseWarning(
              severity: LimitSeverity.soft,
              code: DoseWarningCode.scrMissing,
              messageEn:
                  'Serum creatinine is missing: Apixaban 2-of-3 dose reduction criteria cannot be fully evaluated.',
              messageTh:
                  'ไม่มีค่า Serum Creatinine: ไม่สามารถประเมินเกณฑ์การปรับลดขนาดยา Apixaban 2 ใน 3 ข้อได้อย่างสมบูรณ์',
            ),
          );
        }

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

      // --- Carboplatin & GFR-based Severe Renal Impairment Advisory (< 15 mL/min) ---
      if ((drug.id == 'carboplatin' || regimen.dosingType == DosingType.gfrBased) &&
          crcl != null &&
          crcl < 15.0) {
        const alt1En =
            'Target AUC Reduction: Reduce target AUC by 20–30% (e.g. target AUC 3–4 instead of 5–6) to mitigate severe thrombocytopenia and myelosuppression (Recommended).';
        const alt1Th =
            'ปรับลดเป้าหมาย AUC: ลดเป้าหมาย AUC ลง 20–30% (เช่น ปรับเป็น AUC 3–4 แทน 5–6) เพื่อลดความเสี่ยงเกล็ดเลือดต่ำและกดไขกระดูกรุนแรง (แนะนำ)';
        const alt2En =
            'Intensive Hematologic Monitoring: If maintaining AUC, monitor weekly CBC with platelet nadir counts and prepare for transfusion support.';
        const alt2Th =
            'ติดตามโลหิตวิทยาอย่างเข้มงวด: หากคงขนาดยาเดิม ต้องตรวจ CBC และเกล็ดเลือดทุกสัปดาห์และเตรียมพร้อมรับมือเกล็ดเลือดต่ำวิกฤต';
        const alt3En =
            'Oncology Consultation: Consult medical oncology to consider alternative non-nephrotoxic chemotherapy.';
        const alt3Th =
            'ปรึกษาแพทย์มะเร็งวิทยา: พิจารณาเปลี่ยนไปใช้ยาเคมีบำบัดสูตรอื่นที่ไม่มีผลต่อไต';

        warnings.add(
          DoseWarning(
            severity: LimitSeverity.soft,
            code: DoseWarningCode.severeRenalImpairment,
            messageEn:
                'SEVERE RENAL IMPAIRMENT (CrCl ${crcl.toStringAsFixed(1)} mL/min < 15 mL/min): '
                'Calvert formula accuracy is limited in severe renal dysfunction. Recommend oncology consult. '
                'Alternatives: 1) $alt1En 2) $alt2En 3) $alt3En',
            messageTh:
                'ไตบกพร่องรุนแรง (CrCl ${crcl.toStringAsFixed(1)} มล./นาที < 15 มล./นาที): '
                'การคำนวณโดส Carboplatin ในผู้ป่วยไตบกพร่องรุนแรงเสี่ยงต่อภาวะกดไขกระดูกและเกล็ดเลือดต่ำวิกฤต '
                'ทางเลือก: 1) $alt1Th 2) $alt2Th 3) $alt3Th',
            calculatedValue: crcl,
            limitValue: 15.0,
            unit: 'mL/min',
            clinicalAlternativesEn: [alt1En, alt2En, alt3En],
            clinicalAlternativesTh: [alt1Th, alt2Th, alt3Th],
          ),
        );
      }

      // Critical renal impairment check (< 10 mL/min)
      if (crcl != null && crcl < 10.0) {
        final isVancomycin = drug.id == 'vancomycin';
        final isCarboplatin =
            drug.id == 'carboplatin' || regimen.dosingType == DosingType.gfrBased;

        if (isVancomycin) {
          if (!warnings.any((w) => w.code == DoseWarningCode.severeRenalImpairment)) {
            warnings.add(
              DoseWarning(
                severity: LimitSeverity.soft,
                code: DoseWarningCode.severeRenalImpairment,
                messageEn:
                    'ESRD / HEMODIALYSIS (CrCl ${crcl.toStringAsFixed(1)} mL/min): Vancomycin clearance is severely reduced. Do NOT dose on a fixed schedule. Follow TDM pulse dosing: Loading dose 20–25 mg/kg, check pre-dialysis trough, and redose 500–1000 mg only when trough < 15–20 mcg/mL.',
                messageTh:
                    'ไตวายระยะสุดท้าย / ฟอกเลือด (CrCl ${crcl.toStringAsFixed(1)} มล./นาที): การขจัดยา Vancomycin ลดลงอย่างมาก ห้ามให้ยาตามเวลาปกติ ให้ใช้การบริหารยาแบบ TDM Pulse Dosing: Loading dose 20–25 มก./กก., เจาะ trough ก่อนฟอกไต และให้ซ้ำ 500–1000 มก. เมื่อ trough < 15–20 mcg/mL เท่านั้น',
                calculatedValue: crcl,
                unit: 'mL/min',
              ),
            );
          }
        } else if (isCarboplatin) {
          // Handled above by GFR-based severe renal advisory, do not emit generic hard block
        } else {
          if (!warnings.any((w) => w.code == DoseWarningCode.severeRenalImpairment)) {
            final hasAdjustedTier = isRenallyAdjusted;
            final alt1En = hasAdjustedTier
                ? 'Renal Tier Adjustment Applied: Dose has been adjusted to ${finalDose.toStringAsFixed(1)} ${regimen.doseUnit.symbol} ${finalFrequency.displayEn} per clinical guideline tier for severe renal dysfunction (Recommended).'
                : 'ESRD / Hemodialysis Protocol: Adjust dose per institutional ESRD/hemodialysis guidelines and administer dose post-hemodialysis on dialysis days (Recommended).';
            final alt1Th = hasAdjustedTier
                ? 'ปรับลดขนาดยาตามเกณฑ์ไตวายแล้ว: ระบบได้ปรับขนาดยาเป็น ${finalDose.toStringAsFixed(1)} ${regimen.doseUnit.symbol} ${finalFrequency.displayTh} ตามตารางแนะนำสำหรับผู้ป่วยไตวาย (แนะนำ)'
                : 'แนวทางไตวายระยะสุดท้าย / ฟอกเลือด: ปรับขนาดยาตามโปรโตคอลฟอกเลือด และบริหารยาหลังฟอกเลือดในวันที่ฟอกไต (แนะนำ)';

            const alt2En =
                'Nephrology & TDM Consultation: Consult nephrologist for therapeutic drug monitoring, dialysis clearance evaluation, and renal replacement schedule.';
            const alt2Th =
                'ปรึกษาอายุรแพทย์โรคไต: ติดตามระดับยาในเลือด ประเมินการขจัดยาผ่านเครื่องฟอกไต และวางแผนการให้ยาร่วมกับการฟอกไต';

            const alt3En =
                'Clinician Override: Proceed with clinical override if acute therapeutic necessity outweighs drug accumulation risk under close clinical surveillance.';
            const alt3Th =
                'ขอยกเว้นเฉพาะราย: สั่งใช้ยาได้ตามดุลยพินิจของแพทย์หากประโยชน์ในการรักษาสูงกว่าความเสี่ยง โดยต้องเฝ้าระวังผลข้างเคียงอย่างใกล้ชิด';

            warnings.add(
              DoseWarning(
                severity: LimitSeverity.soft,
                code: DoseWarningCode.severeRenalImpairment,
                messageEn:
                    'CRITICAL RENAL IMPAIRMENT: CrCl ${crcl.toStringAsFixed(1)} mL/min < 10 mL/min. '
                    'Alternatives: 1) $alt1En 2) $alt2En 3) $alt3En',
                messageTh:
                    'การทำงานของไตวิกฤต: CrCl ${crcl.toStringAsFixed(1)} มล./นาที ต่ำกว่า 10 มล./นาที '
                    'ทางเลือก: 1) $alt1Th 2) $alt2Th 3) $alt3Th',
                calculatedValue: crcl,
                limitValue: 10.0,
                unit: 'mL/min',
                clinicalAlternativesEn: [alt1En, alt2En, alt3En],
                clinicalAlternativesTh: [alt1Th, alt2Th, alt3Th],
              ),
            );
          }
        }
      }

      // --- 10. Continuous Infusion & Titrated Regimens (D2) ---
      InfusionResult? infusionResult;
      if (regimen.dosingType == DosingType.titrated) {
        final rate = regimen.continuousRateMin ?? 0.0;
        final rateMax = (regimen.continuousRateMax != null &&
                regimen.continuousRateMax! > rate)
            ? regimen.continuousRateMax
            : null;
        // No silent default: an unknown/missing unit throws and is reported
        // as a calculation error (unit confusion is a dosing-error hazard).
        final RateUnit rateUnit;
        if (regimen.rateUnit != null) {
          rateUnit = regimen.rateUnit!;
        } else if (regimen.continuousRateUnit != null) {
          rateUnit = RateUnit.fromSymbol(regimen.continuousRateUnit!);
        } else {
          rateUnit = RateUnit.mcgKgMin;
        }

        double? mlPerHr(double r) {
          final conc = regimen.effectiveStandardDilutionMgPerMl;
          if (conc == null || conc <= 0) return null;
          if (rateUnit == RateUnit.mlHr) return r;
          final amountPerHr = rateUnit.toAmountPerHour(r, weightForDosing);
          return amountPerHr == null ? null : amountPerHr / conc;
        }

        final rangeEn = rateMax != null
            ? '$rate–$rateMax ${rateUnit.symbol}'
            : '$rate ${rateUnit.symbol}';
        final rangeTh = rateMax != null
            ? '$rate–$rateMax ${rateUnit.nameTh}'
            : '$rate ${rateUnit.nameTh}';

        infusionResult = InfusionResult(
          rate: rate,
          rateMax: rateMax,
          rateUnit: rateUnit,
          rateMlPerHr: mlPerHr(rate),
          rateMlPerHrMax: rateMax != null ? mlPerHr(rateMax) : null,
          instructionsEn:
              'Titrate continuously according to clinical protocol ($rangeEn).',
          instructionsTh:
              'ปรับอัตราการหยดยาอย่างต่อเนื่องตามโปรโตคอลคลินิก ($rangeTh)',
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

        if (roundedDose != null && roundedDose != finalDose) {
          final roundedDailyDose = (finalFrequency.dosesPerDay != null && finalFrequency.dosesPerDay! > 0)
              ? roundedDose * finalFrequency.dosesPerDay!
              : null;
          final roundedLimitWarnings = DoseChecker.checkDose(
            calculatedDose: roundedDose,
            limits: regimen.limits!,
            doseUnit: regimen.doseUnit.symbol,
            weightKg: weightForDosing,
            dailyDose: roundedDailyDose,
          );
          for (final rw in roundedLimitWarnings) {
            if (!warnings.any((w) => w.code == rw.code)) {
              warnings.add(DoseWarning(
                severity: rw.severity,
                code: rw.code,
                messageEn: 'Rounded dose (${roundedDose.toStringAsFixed(1)} ${regimen.doseUnit.symbol}): ${rw.messageEn}',
                messageTh: 'ขนาดยาหลังปัดเศษ (${roundedDose.toStringAsFixed(1)} ${regimen.doseUnit.symbol}): ${rw.messageTh}',
                calculatedValue: rw.calculatedValue,
                limitValue: rw.limitValue,
                unit: rw.unit,
              ));
            }
          }
        }
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
        ibwKg: isChild ? null : ibw,
        adjBwKg: isChild ? null : adjBw,
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
        warnings: [
          DoseWarning(
            severity: LimitSeverity.hard,
            code: DoseWarningCode.calculationError,
            messageEn: 'Calculation error: $e',
            messageTh: 'เกิดข้อผิดพลาดในการคำนวณ: $e',
          ),
        ],
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

    // Check if ordered dose is below regimen minimum
    if (regimen.limits?.minSingleDose != null &&
        orderedDose < regimen.limits!.minSingleDose!) {
      verificationWarnings.add(
        DoseWarning(
          severity: LimitSeverity.info,
          code: DoseWarningCode.minDoseNotReached,
          messageEn:
              'Ordered dose below minimum: $orderedDose ${regimen.doseUnit.symbol} < ${regimen.limits!.minSingleDose} ${regimen.doseUnit.symbol}',
          messageTh:
              'ขนาดยาที่สั่งต่ำกว่าเกณฑ์ขั้นต่ำ: $orderedDose ${regimen.doseUnit.symbol} < ${regimen.limits!.minSingleDose} ${regimen.doseUnit.symbol}',
        ),
      );
    }

    // Check if ordered frequency interval differs from recommended interval
    if (recommended.structuredFrequency != null &&
        recommended.structuredFrequency!.intervalHours != null &&
        orderedFrequency.intervalHours != null &&
        recommended.structuredFrequency!.intervalHours != orderedFrequency.intervalHours) {
      verificationWarnings.add(
        DoseWarning(
          severity: LimitSeverity.soft,
          code: DoseWarningCode.unknownFrequency,
          messageEn:
              'FREQUENCY MISMATCH: Ordered frequency (${orderedFrequency.displayEn}) differs from recommended (${recommended.structuredFrequency!.displayEn}).',
          messageTh:
              'ความถี่การให้ยาคลาดเคลื่อน: ความถี่ที่สั่ง (${orderedFrequency.displayTh}) ต่างจากที่แนะนำ (${recommended.structuredFrequency!.displayTh})',
        ),
      );
    }

    // Check if ordered frequency has unknown/variable doses per day
    if (orderedFrequency.dosesPerDay == null &&
        !orderedFrequency.isContinuous &&
        !orderedFrequency.isOnce) {
      verificationWarnings.add(
        const DoseWarning(
          severity: LimitSeverity.soft,
          code: DoseWarningCode.unknownFrequency,
          messageEn:
              'Ordered frequency has irregular or variable dosing interval; daily dose limits cannot be verified.',
          messageTh:
              'ความถี่การให้ยาที่สั่งไม่คงที่ ไม่สามารถตรวจสอบขนาดยาสะสมต่อวันได้',
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
