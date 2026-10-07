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
    Drug? Function(String id)? drugLookup,
    List<Drug>? activeDrugs,
    double dripFactor = 20.0,
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

      // --- 1. Audience & Population Applicability Check (D4, 4.1, F11) ---
      if (regimen.population != null) {
        final popWarnings = regimen.population!.checkApplicability(patient);
        warnings.addAll(popWarnings);
        final hardPopWarning = popWarnings.cast<DoseWarning?>().firstWhere(
              (w) => w?.severity == LimitSeverity.hard,
              orElse: () => null,
            );
        if (hardPopWarning != null) {
          return DosageResult.failure(
            reasonEn: hardPopWarning.messageEn,
            reasonTh: hardPopWarning.messageTh,
            formulaUsed: 'Population Criteria Check',
            warnings: warnings,
          );
        }
      }

      final hasExplicitAgeCriteria = regimen.population?.minAgeMonths != null ||
          regimen.population?.maxAgeMonths != null;
      final isChild = patient.ageYears < 18;

      if (!hasExplicitAgeCriteria &&
          regimen.effectiveAudience == RegimenAudience.adult &&
          isChild) {
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

      if (!hasExplicitAgeCriteria &&
          regimen.effectiveAudience == RegimenAudience.pediatric &&
          !isChild) {
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

      // --- 3. Contraindications & Drug-Drug Interactions (D9, A8, F8) ---
      // Free-text contraindications become an info checklist, never soft warnings (F8)
      for (final c in drug.contraindications) {
        warnings.add(DoseWarning(
          severity: LimitSeverity.info,
          code: DoseWarningCode.contraindicationAlert,
          messageEn: 'Clinical Checklist: Contraindication / Caution: $c',
          messageTh: 'รายการตรวจสอบทางคลินิก: ข้อห้ามใช้ / ข้อควรระวัง: $c',
        ));
      }

      // Patient condition flags evaluation (pregnancy, hepatic impairment) (F8)
      if (patient.isPregnant) {
        final isContraindicatedPregnancy = drug.pregnancyCategory == 'X' ||
            regimen.population?.contraindicatedPregnancy == true ||
            drug.contraindications.any((c) =>
                c.toLowerCase().contains('pregnan') ||
                c.toLowerCase().contains('การตั้งครรภ์'));
        if (isContraindicatedPregnancy) {
          warnings.add(DoseWarning(
            severity: LimitSeverity.hard,
            code: DoseWarningCode.contraindicationAlert,
            messageEn:
                'PREGNANCY CONTRAINDICATION: ${drug.genericName} is strictly contraindicated during pregnancy.',
            messageTh:
                'ข้อห้ามใช้ในหญิงตั้งครรภ์: ห้ามใช้ยา ${drug.genericName} ในสตรีมีครรภ์เด็ดขาด',
          ));
        }
      }

      if (patient.hepaticClass != null && patient.hepaticClass != ChildPughClass.none) {
        if (drug.requiresHepationCaution) {
          final isSevere = patient.hepaticClass == ChildPughClass.classC;
          warnings.add(DoseWarning(
            severity: isSevere ? LimitSeverity.hard : LimitSeverity.soft,
            code: DoseWarningCode.contraindicationAlert,
            messageEn:
                'HEPATIC IMPAIRMENT: Patient has ${patient.hepaticClass!.labelEn}. ${drug.genericName} requires hepatic dosage caution or surveillance.',
            messageTh:
                'การทำงานของตับบกพร่อง: ผู้ป่วยมีภาวะ ${patient.hepaticClass!.labelTh} ยา ${drug.genericName} ต้องปรับขนาดยาหรือเฝ้าระวังอย่างใกล้ชิด',
          ));
        }
      }

      // Symmetric & Active Drug Interaction Check (D9, F6, G4)
      for (final activeDrugId in patient.activeDrugIds) {
        final activeNorm = activeDrugId.trim().toLowerCase();
        final resolvedClass = DrugOntology.resolveDrugClass(activeDrugId, activeDrugId, null);
        final activeDrug = activeDrugs?.cast<Drug?>().firstWhere(
              (d) => d?.id.toLowerCase() == activeNorm,
              orElse: () => null,
            ) ??
            drugLookup?.call(activeDrugId) ??
            Drug(
              id: activeNorm,
              genericName: DrugOntology.resolveGenericName(activeDrugId),
              category: DrugCategory.other,
              regimens: const [],
              drugClass: resolvedClass,
            );

        // 1. Therapeutic Duplication Check
        final duplication = TherapeuticDuplicationService.checkDuplication(drug, activeDrug);
        if (duplication != null) {
          warnings.add(duplication);
        }

        // 2. Clinical Interaction Registry (Lexicomp / Sanford Evidence)
        final clinicalInters = ClinicalInteractionRegistry.checkInteractions(drug, activeDrug);
        for (final interWarning in clinicalInters) {
          if (!warnings.any((w) => w.messageEn == interWarning.messageEn)) {
            warnings.add(interWarning);
          }
        }

        // 3. Structured current drug's interactions targeting active drug ID or active drug class
        for (final inter in drug.interactions) {
          final matchesId = inter.targetDrugId?.toLowerCase() == activeNorm;
          final matchesClass = inter.targetClass != null &&
              activeDrug.effectiveDrugClass == inter.targetClass;
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

        // 4. Symmetric check: Check active drug's interactions targeting current drug ID or current drug class
        for (final inter in activeDrug.interactions) {
          final matchesId = inter.targetDrugId?.toLowerCase() == drug.id.toLowerCase();
          final matchesClass = inter.targetClass != null &&
              drug.effectiveDrugClass == inter.targetClass;
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

        // 5. Unstructured severe interactions
        for (final inter in drug.severeInteractions) {
          if (inter.toLowerCase().contains(activeNorm)) {
            if (!warnings.any((w) => w.messageEn.contains('Severe interaction with active drug $activeDrugId'))) {
              warnings.add(DoseWarning(
                severity: LimitSeverity.hard,
                code: DoseWarningCode.severeInteractionAlert,
                messageEn: 'Severe interaction with active drug $activeDrugId: $inter',
                messageTh: 'ปฏิกิริยารุนแรงกับยาที่กำลังใช้อยู่ $activeDrugId: $inter',
              ));
            }
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
      if (!patient.isScrStable) {
        warnings.add(
          const DoseWarning(
            severity: LimitSeverity.hard,
            code: DoseWarningCode.unstableScr,
            messageEn:
                'AKI Alert: SCr is unstable. Cockcroft-Gault is inaccurate. Renal adjustment NOT applied.',
            messageTh:
                'เตือน AKI: ค่า SCr ไม่คงที่ จึงไม่มีการปรับขนาดยาตามไตอัตโนมัติ',
            clinicalAlternativesEn: [
              'STAT / Emergent Dose: If treating life-threatening infection, evaluate clinical override with documented rationale.',
              'Kinetic / AKI Protocol: Re-evaluate SCr trajectory and urine output before subsequent maintenance doses.',
            ],
            clinicalAlternativesTh: [
              'ขอยกเว้นเฉพาะราย: หากรักษาการติดเชื้อรุนแรง สามารถให้ยาเข็มแรกได้พร้อมบันทึกเหตุผลทางคลินิก',
              'ติดตามแนวโน้มไต: ติดตามค่า SCr ซ้ำและปริมาณปัสสาวะเพื่อปรับขนาดยาต่อเนื่องตามแนวทาง AKI',
            ],
          ),
        );
      } else if (patient.serumCreatinineMgDl != null) {
        if (isChild) {
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
        if (drug.renalDataPolicy != RenalDataPolicy.notNeeded) {
          final isHardBlock = drug.renalDataPolicy == RenalDataPolicy.block;
          final firstDoseTextEn = drug.firstDoseUnadjustedOk
              ? ' First/loading dose unadjusted is acceptable (${drug.firstDoseCitation ?? "Clinical reference"}). Subsequent maintenance dosing requires serum creatinine.'
              : '';
          final firstDoseTextTh = drug.firstDoseUnadjustedOk
              ? ' ขนาดยาเริ่มต้น/เข็มแรกสามารถบริหารได้โดยไม่ต้องปรับ (${drug.firstDoseCitation ?? "เอกสารอ้างอิง"}) แต่มื้อต่อไปต้องระบุค่าไต'
              : '';

          warnings.add(
            DoseWarning(
              severity: isHardBlock ? LimitSeverity.hard : LimitSeverity.soft,
              code: DoseWarningCode.scrMissing,
              messageEn:
                  'RENAL SAFETY ALERT: ${drug.genericName} is eliminated renally and requires dosage adjustment in kidney impairment, but Serum Creatinine is missing.$firstDoseTextEn Obtain STAT laboratory SCr for maintenance therapy.',
              messageTh:
                  'เตือนความปลอดภัย: ยา ${drug.genericName} ขับออกทางไตและต้องปรับขนาดยาตามการทำงานของไต แต่ยังไม่ได้ระบุค่า SCr ในระบบ$firstDoseTextTh โปรดเจาะตรวจ SCr ด่วนเพื่อปรับขนาดยาต่อเนื่อง',
              clinicalAlternativesEn: [
                'STAT / Initial Empiric Dose: Administer first unadjusted dose emergently while pending urgent serum creatinine lab result.',
                'Awaiting Laboratory Confirmation: Obtain STAT serum creatinine before maintenance doses.',
              ],
              clinicalAlternativesTh: [
                'ให้ยาเข็มแรกแบบฉุกเฉิน (STAT): สามารถบริหารยาเข็มแรกได้ทันทีในภาวะฉุกเฉินระหว่างรอผลตรวจ SCr ทางห้องปฏิบัติการ',
                'รอผลตรวจยืนยัน: ส่งตรวจค่า SCr เร่งด่วนก่อนบริหารยามื้อถัดไป',
              ],
            ),
          );
        }
      }

      // Database Review Check: Flag drugs requiring renal adjustment without reviewed tiers (F4)
      if (drug.requiresRenalAdjustment &&
          regimen.dosingType != DosingType.gfrBased &&
          drug.renalReviewStatus != RenalReviewStatus.notApplicable &&
          (regimen.renalAdjustments == null || regimen.renalAdjustments!.isEmpty)) {
        final isKnownLowCrCl = crcl != null && crcl < 50.0;
        final crclSuffixEn =
            crcl != null ? ' for documented CrCl ${crcl.toStringAsFixed(1)} mL/min' : '';
        final crclSuffixTh =
            crcl != null ? ' สำหรับ CrCl ${crcl.toStringAsFixed(1)} มล./นาที' : '';

        warnings.add(
          DoseWarning(
            severity: isKnownLowCrCl ? LimitSeverity.hard : LimitSeverity.soft,
            code: DoseWarningCode.renalTiersUnreviewed,
            messageEn:
                'DATABASE WARNING: Automated renal adjustment tiers are unreviewed for this drug regimen. '
                'Please verify dose manually via clinical reference (Lexicomp/Sanford)$crclSuffixEn.',
            messageTh:
                'เตือนฐานข้อมูล: ยานี้ต้องปรับตามไตแต่ยังไม่มีตารางปรับขนาดยาในระบบ '
                'โปรดตรวจสอบขนาดยาจากคู่มืออ้างอิง (Lexicomp/Sanford) ด้วยตนเอง$crclSuffixTh',
            calculatedValue: crcl,
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
      double? calculatedBsa;
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
          calculatedBsa = isChild
              ? BsaCalculator.haycock(
                  heightCm: patient.heightCm,
                  weightKg: patient.weightKg,
                )
              : BsaCalculator.mosteller(
                  heightCm: patient.heightCm,
                  weightKg: patient.weightKg,
                );
          final dosePerM2 = regimen.dosePerM2 ?? 0.0;
          baseDose = WeightBasedCalculator.calculateBsaDose(
            bsaM2: calculatedBsa,
            dosePerM2: dosePerM2,
          );
          final bsaFormulaName = isChild ? 'Haycock' : 'Mosteller';
          formulaUsed =
              'BSA-based $bsaFormulaName ($dosePerM2 ${regimen.doseUnit.symbol}/m²)';
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

      // --- 8.1 Explicit Clinical Dose Capping (F3) ---
      // Dose capping applies ONLY when explicitly configured via DosingRegimen.doseCap.
      // DosingRegimen.limits represent hard/soft safety boundaries evaluated in DoseChecker (Step 11).
      if (regimen.doseCap != null && dose > regimen.doseCap!) {
        final rawDose = dose;
        dose = regimen.doseCap!;

        String fmtVal(double v) => v == v.roundToDouble()
            ? v.toStringAsFixed(0)
            : ((v * 10) == (v * 10).roundToDouble()
                ? v.toStringAsFixed(1)
                : v.toStringAsFixed(2));

        final capSource = regimen.doseCapCitation != null
            ? ' per guideline (${regimen.doseCapCitation})'
            : '';

        warnings.add(DoseWarning(
          severity: LimitSeverity.soft,
          code: DoseWarningCode.doseCappedAtMax,
          messageEn:
              'DOSE CAPPED: Raw weight-based calculation is ${fmtVal(rawDose)} ${regimen.doseUnit.symbol}, '
              'which exceeds the guideline ceiling of ${fmtVal(regimen.doseCap!)} ${regimen.doseUnit.symbol}$capSource.',
          messageTh:
              'จำกัดขนาดยาสูงสุด: ขนาดยาคำนวณตามน้ำหนักได้ ${fmtVal(rawDose)} ${regimen.doseUnit.symbol} '
              'ซึ่งเกินเกณฑ์เพดานสูงสุด ${fmtVal(regimen.doseCap!)} ${regimen.doseUnit.symbol}$capSource',
          calculatedValue: rawDose,
          limitValue: regimen.doseCap,
          unit: regimen.doseUnit.symbol,
          clinicalAlternativesEn: [
            'Standard Ceiling: Administer capped dose of ${fmtVal(regimen.doseCap!)} ${regimen.doseUnit.symbol}.',
            'Clinician Override: If clinical condition strictly warrants higher dose, document override rationale.',
          ],
          clinicalAlternativesTh: [
            'ขนาดยามาตรฐานสูงสุด: ให้ยาตามเกณฑ์เพดานสูงสุด ${fmtVal(regimen.doseCap!)} ${regimen.doseUnit.symbol}',
            'ขอยกเว้นเฉพาะราย: บันทึกเหตุผลทางคลินิกหากมีความจำเป็นต้องใช้ขนาดยาสูงกว่าเกณฑ์เพดาน',
          ],
        ));
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

              final doseChanged = finalDose != dose;
              final freqChanged = finalFrequency != regimen.frequency;
              if (doseChanged || freqChanged) {
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
            }
            break; // Stop at first matching tier
          }
        }
      }

      // --- 9.5 Declarative Dose Rules (F6) ---
      bool isDoseModified = false;
      String? doseModificationReason;

      final ruleCtx = DoseRuleContext(
        patient: patient,
        drug: drug,
        regimen: regimen,
        currentDose: finalDose,
        currentFrequency: finalFrequency,
        crclMlMin: crcl,
      );

      for (final rule in drug.doseRules) {
        if (rule.applies(ruleCtx)) {
          final res = rule.evaluate(ruleCtx);
          if (res.modifiedDose != null) {
            finalDose = res.modifiedDose!;
          }
          if (res.modifiedFrequency != null) {
            finalFrequency = res.modifiedFrequency!;
          }
          if (res.isDoseModified) {
            isDoseModified = true;
            doseModificationReason = res.modificationReasonEn;
          }
          if (res.isRenallyAdjusted) {
            isRenallyAdjusted = true;
          }
          warnings.addAll(res.warnings);
        }
      }

      // Critical renal impairment check (< 10 mL/min) [PHARMACIST]
      if (crcl != null && crcl < 10.0) {
        if (!warnings.any((w) => w.code == DoseWarningCode.severeRenalImpairment)) {
          final checkerWarnings = DoseChecker.checkRenalAdjustment(
            crclMlMin: crcl,
            adjustments: regimen.renalAdjustments ?? [],
          );
          for (final cw in checkerWarnings) {
            if (cw.code == DoseWarningCode.severeRenalImpairment &&
                !warnings.any((w) => w.code == DoseWarningCode.severeRenalImpairment)) {
              warnings.add(cw);
            }
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

      // --- 13. Infusion Preparation (A8, F10) ---
      double? volumeMl;
      double? infusionRateMlPerHr;
      double? infusionDurationMinutes = regimen.infusionTimeMinutes;
      double? dripRateDropsPerMin;

      // Normalize dose to milligrams (mg) for dilution and infusion rate checks
      double doseMg = finalDose;
      if (regimen.doseUnit == DoseUnit.g) {
        doseMg = UnitConverter.convertDoseUnit(finalDose, DoseUnit.g, DoseUnit.mg);
      } else if (regimen.doseUnit == DoseUnit.mcg) {
        doseMg = UnitConverter.convertDoseUnit(finalDose, DoseUnit.mcg, DoseUnit.mg);
      }

      final effDilution = regimen.effectiveStandardDilutionMgPerMl;
      if (regimen.dosingType != DosingType.titrated &&
          effDilution != null &&
          effDilution > 0 &&
          finalDose > 0) {
        volumeMl = doseMg / effDilution;
        if (infusionDurationMinutes != null && infusionDurationMinutes > 0) {
          infusionRateMlPerHr = (volumeMl / infusionDurationMinutes) * 60.0;
          dripRateDropsPerMin = (volumeMl * dripFactor) / infusionDurationMinutes;
        }
      }

      if (regimen.maxInfusionRateMgPerMin != null &&
          infusionDurationMinutes != null &&
          infusionDurationMinutes > 0 &&
          finalDose > 0) {
        final actualRateMgPerMin = doseMg / infusionDurationMinutes;
        warnings.addAll(
          DoseChecker.checkInfusionRate(
            rateMgPerMin: actualRateMgPerMin,
            maxRateMgPerMin: regimen.maxInfusionRateMgPerMin!,
          ),
        );
      }

      // --- 13.5 Weekly Regimen Banner Check (F12) ---
      final isWeeklySchedule = drug.id.toLowerCase() == 'methotrexate' ||
          regimen.frequency.isWeekly ||
          regimen.frequency.kind == FrequencyKind.weekly ||
          (regimen.frequency.intervalHours != null &&
              regimen.frequency.intervalHours! >= 168);

      if (isWeeklySchedule) {
        warnings.add(
          const DoseWarning(
            severity: LimitSeverity.hard,
            code: DoseWarningCode.weeklyRegimenBanner,
            messageEn:
                'WEEKLY - NOT DAILY: Verify dosing frequency. Daily administration of weekly regimens can be fatal.',
            messageTh:
                'รับประทานสัปดาห์ละ 1 ครั้งเท่านั้น - ห้ามรับประทานทุกวัน (อันตรายถึงชีวิต)',
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
        bsaM2: calculatedBsa,
        ibwKg: isChild ? null : ibw,
        adjBwKg: isChild ? null : adjBw,
        crclMlMin: crcl,
        isRenallyAdjusted: isRenallyAdjusted,
        isDoseModified: isDoseModified,
        doseModificationReason: doseModificationReason,
        renalAdjustmentFactor: appliedRenalFactor,
        renalNotes: renalNotesEn,
        renalNotesTh: renalNotesTh,
        roundedDose: roundedDose,
        activePhases: regimen.phases,
        isWeeklySchedule: isWeeklySchedule,
        verificationStatus: regimen.verificationStatus,
        warnings: warnings,
      );
    } catch (e, stackTrace) {
      // Diagnostic logging without raw error exposure in clinical UI (F13)
      assert(() {
        // ignore: avoid_print
        print('PharmacistCalculator caught calculation error: $e\n$stackTrace');
        return true;
      }());
      return DosageResult.failure(
        reasonEn: 'Calculation error occurred during dosing evaluation.',
        reasonTh: 'เกิดข้อผิดพลาดในการประมวลผลการคำนวณขนาดยา',
        formulaUsed: 'Error Handler',
        warnings: const [
          DoseWarning(
            severity: LimitSeverity.hard,
            code: DoseWarningCode.calculationError,
            messageEn: 'Calculation error occurred during dosing evaluation.',
            messageTh: 'เกิดข้อผิดพลาดในการประมวลผลการคำนวณขนาดยา',
          ),
        ],
      );
    }
  }

  /// Verifies an ordered prescription against recommended dosing rules (D7, F2).
  static OrderVerificationResult verifyOrder({
    required Patient patient,
    required Drug drug,
    required DosingRegimen regimen,
    required double orderedDose,
    required Frequency orderedFrequency,
    double? orderedRate,
    double? orderedMaxDailyDose,
    Drug? Function(String id)? drugLookup,
    List<Drug>? activeDrugs,
  }) {
    final recommended = calculateDose(
      patient: patient,
      drug: drug,
      regimen: regimen,
      drugLookup: drugLookup,
      activeDrugs: activeDrugs,
    );

    final verificationWarnings = <DoseWarning>[];

    // Inherit non-dose specific warnings (allergies, contraindications, severe interactions, weekly banner)
    for (final w in recommended.warnings) {
      if (w.code == DoseWarningCode.allergyAlert ||
          w.code == DoseWarningCode.contraindicationAlert ||
          w.code == DoseWarningCode.severeInteractionAlert ||
          w.code == DoseWarningCode.pediatricBlocked ||
          w.code == DoseWarningCode.weeklyRegimenBanner) {
        verificationWarnings.add(w);
      }
    }

    // 1. Deviation from default recommended dose (INFORMATIONAL ONLY, F2)
    final targetDose = recommended.roundedDose ?? recommended.calculatedDose;
    double? deviation;
    if (targetDose != null && targetDose > 0) {
      deviation = ((orderedDose - targetDose).abs() / targetDose) * 100.0;
      if (deviation > 5.0) {
        verificationWarnings.add(
          DoseWarning(
            severity: LimitSeverity.info,
            code: DoseWarningCode.orderDeviation,
            messageEn:
                'ORDER DEVIATION (Informational): Ordered dose ($orderedDose ${regimen.doseUnit.symbol}) deviates by ${deviation.toStringAsFixed(1)}% from guideline recommended (${targetDose.toStringAsFixed(1)} ${regimen.doseUnit.symbol}).',
            messageTh:
                'ขนาดยาต่างจากเกณฑ์แนะนำ (ข้อมูล): ขนาดยาที่สั่ง ($orderedDose ${regimen.doseUnit.symbol}) ต่างจากค่าแนะนำ (${targetDose.toStringAsFixed(1)} ${regimen.doseUnit.symbol}) อยู่ ${deviation.toStringAsFixed(1)}%',
          ),
        );
      }
    }

    // 2. Regimen Dose Range Verification (F2)
    if (regimen.doseRangeMin != null && orderedDose < regimen.doseRangeMin!) {
      verificationWarnings.add(
        DoseWarning(
          severity: LimitSeverity.soft,
          code: DoseWarningCode.orderBelowRange,
          messageEn:
              'ORDER BELOW RANGE: Ordered dose ($orderedDose ${regimen.doseUnit.symbol}) is below recommended range (${regimen.doseRangeMin}–${regimen.doseRangeMax ?? "-"} ${regimen.doseUnit.symbol}).',
          messageTh:
              'ขนาดยาต่ำกว่าช่วงแนะนำ: ขนาดยาที่สั่ง ($orderedDose ${regimen.doseUnit.symbol}) ต่ำกว่าเกณฑ์ขั้นต่ำของช่วงที่แนะนำ (${regimen.doseRangeMin}–${regimen.doseRangeMax ?? "-"} ${regimen.doseUnit.symbol})',
          calculatedValue: orderedDose,
          limitValue: regimen.doseRangeMin,
          unit: regimen.doseUnit.symbol,
        ),
      );
    }
    if (regimen.doseRangeMax != null && orderedDose > regimen.doseRangeMax!) {
      verificationWarnings.add(
        DoseWarning(
          severity: LimitSeverity.hard,
          code: DoseWarningCode.maxSingleDoseExceeded,
          messageEn:
              'ORDER ABOVE RANGE: Ordered dose ($orderedDose ${regimen.doseUnit.symbol}) exceeds recommended range maximum (${regimen.doseRangeMax} ${regimen.doseUnit.symbol}).',
          messageTh:
              'ขนาดยาสูงกว่าช่วงแนะนำ: ขนาดยาที่สั่ง ($orderedDose ${regimen.doseUnit.symbol}) เกินเกณฑ์สูงสุดของช่วงที่แนะนำ (${regimen.doseRangeMax} ${regimen.doseUnit.symbol})',
          calculatedValue: orderedDose,
          limitValue: regimen.doseRangeMax,
          unit: regimen.doseUnit.symbol,
        ),
      );
    }

    // 3. Frequency Mismatch Check (F2)
    if (recommended.structuredFrequency != null &&
        recommended.structuredFrequency!.intervalHours != null &&
        orderedFrequency.intervalHours != null &&
        recommended.structuredFrequency!.intervalHours != orderedFrequency.intervalHours) {
      verificationWarnings.add(
        DoseWarning(
          severity: LimitSeverity.soft,
          code: DoseWarningCode.frequencyMismatch,
          messageEn:
              'FREQUENCY MISMATCH: Ordered frequency (${orderedFrequency.displayEn}) differs from recommended (${recommended.structuredFrequency!.displayEn}).',
          messageTh:
              'ความถี่การให้ยาคลาดเคลื่อน: ความถี่ที่สั่ง (${orderedFrequency.displayTh}) ต่างจากที่แนะนำ (${recommended.structuredFrequency!.displayTh})',
        ),
      );
    }

    if (orderedFrequency.isPrn ||
        orderedFrequency.kind == FrequencyKind.custom ||
        orderedFrequency.dosesPerDay == null) {
      verificationWarnings.add(
        const DoseWarning(
          severity: LimitSeverity.soft,
          code: DoseWarningCode.frequencyMismatch,
          messageEn:
              'Ordered frequency has irregular or variable schedule. Total daily dose cannot be automatically verified.',
          messageTh:
              'ความถี่การให้ยาไม่สม่ำเสมอหรือไม่แน่นอน ไม่สามารถตรวจสอบขนาดยาสูงสุดต่อวันได้โดยอัตโนมัติ',
        ),
      );
    }

    // 4. Daily Doses & PRN / Range Schedule Verification (F2)
    final worstCaseDosesPerDay = orderedFrequency.worstCaseDosesPerDay ?? 1.0;
    final double computedWorstCaseDailyDose = orderedDose * worstCaseDosesPerDay;

    double effectiveOrderedDailyDose;
    if (orderedFrequency.isPrn || orderedFrequency.kind == FrequencyKind.range) {
      if (orderedMaxDailyDose == null) {
        // PRN / range order without explicit max daily dose is BLOCKED (F2)
        verificationWarnings.add(
          const DoseWarning(
            severity: LimitSeverity.hard,
            code: DoseWarningCode.maxDailyDoseExceeded,
            messageEn:
                'PRN / RANGE ORDER BLOCKED: An explicit maximum daily dose must be specified for PRN or interval-range orders.',
            messageTh:
                'ไม่อนุมัติคำสั่งยา PRN / แบบช่วงเวลา: ต้องระบุขนาดยาสูงสุดต่อวันให้ชัดเจนสำหรับคำสั่งยาเมื่อจำเป็นหรือแบบช่วงเวลา',
          ),
        );
        effectiveOrderedDailyDose = computedWorstCaseDailyDose;
      } else {
        effectiveOrderedDailyDose = orderedMaxDailyDose;
      }
    } else {
      effectiveOrderedDailyDose = orderedMaxDailyDose ?? computedWorstCaseDailyDose;
    }

    // 5. Run DoseChecker on the ORDERED Dose & Frequency (F2)
    final dosingWeight = (recommended.calculationInputs['dosingWeightUsedKg'] as num?)?.toDouble() ??
        patient.weightKg;

    if (regimen.limits != null) {
      final limitWarnings = DoseChecker.checkDose(
        calculatedDose: orderedDose,
        weightKg: dosingWeight,
        limits: regimen.limits!,
        doseUnit: regimen.doseUnit.symbol,
        dailyDose: effectiveOrderedDailyDose,
      );
      verificationWarnings.addAll(limitWarnings);
    }

    // 6. Infusion Rate Check (if orderedRate is provided, F2)
    if (orderedRate != null && regimen.limits?.maxInfusionRate != null) {
      final rateWarnings = DoseChecker.checkInfusionRate(
        rateMgPerMin: orderedRate,
        maxRateMgPerMin: regimen.limits!.maxInfusionRate!,
      );
      verificationWarnings.addAll(rateWarnings);
    }

    // 7. Renal Adjustment Verification for Ordered Dose (F2)
    // If recommended dose/regimen was renally adjusted, but unadjusted dose/frequency is ordered at low CrCl:
    if (recommended.isRenallyAdjusted && targetDose != null) {
      final isFullUnadjustedDose = orderedDose > targetDose * 1.15;
      final isUnadjustedFreq = recommended.adjustedFrequency != null &&
          orderedFrequency.displayEn != recommended.adjustedFrequency;

      if (isFullUnadjustedDose || isUnadjustedFreq) {
        final crclVal = recommended.crclMlMin;
        final crclStr = crclVal != null ? ' (CrCl ${crclVal.toStringAsFixed(1)} mL/min)' : '';
        verificationWarnings.add(
          DoseWarning(
            severity: LimitSeverity.hard,
            code: DoseWarningCode.severeRenalImpairment,
            messageEn:
                'RENAL OVERDOSE ALERT: Full unadjusted dose/frequency ordered for patient with renal impairment$crclStr. Guideline recommends ${targetDose.toStringAsFixed(1)} ${regimen.doseUnit.symbol} ${recommended.frequency}.',
            messageTh:
                'เตือนขนาดยาเกินเกณฑ์ไต: มีการสั่งยาขนาดเต็มโดยไม่ปรับลดในผู้ป่วยไตบกพร่อง$crclStr ขนาดยาแนะนำตามไตคือ ${targetDose.toStringAsFixed(1)} ${regimen.doseUnit.symbol} ${recommended.frequency}',
            calculatedValue: orderedDose,
            limitValue: targetDose,
            unit: regimen.doseUnit.symbol,
          ),
        );
      }
    }

    final hasHardViolation = verificationWarnings.any(
      (w) =>
          w.severity == LimitSeverity.hard &&
          w.code != DoseWarningCode.weeklyRegimenBanner,
    );
    final isAcceptable = !recommended.isBlocked && !hasHardViolation;

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
