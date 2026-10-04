import '../models/models.dart';
import 'calculators.dart';

/// The central core engine for a Ward Pharmacist.
/// Extracted from the UI so that we can calculate multiple drugs headlessly.
class PharmacistCalculator {
  const PharmacistCalculator._();

  /// Given a [patient], [drug], and specific [regimen], calculates the optimal
  /// dose, performs renal adjustment, rounds it, and returns the result.
  static DosageResult calculateDose({
    required Patient patient,
    required Drug drug,
    required DosingRegimen regimen,
  }) {
    double dose = 0;
    double? crcl;
    List<DoseWarning> warnings = [];

    // --- 1. Determine Dosing Weight for CrCl ---
    double crclDosingWeight = patient.weightKg;
    double ibw = WeightBasedCalculator.idealBodyWeight(
      heightCm: patient.heightCm,
      sex: patient.sex,
    );

    if (patient.weightKg < ibw) {
      crclDosingWeight = patient.weightKg; // TBW
    } else if (patient.weightKg < 1.20 * ibw) {
      crclDosingWeight = ibw; // IBW
    } else {
      crclDosingWeight = ibw + 0.4 * (patient.weightKg - ibw); // AdjBW
    }

    // --- 2. Calculate CrCl if SCr is provided ---
    if (patient.serumCreatinineMgDl != null) {
      if (!patient.isScrStable) {
        warnings.add(
          const DoseWarning(
            severity: LimitSeverity.hard,
            messageEn:
                'AKI Alert: SCr is not stable. Cockcroft-Gault is inaccurate.',
            messageTh: 'AKI Alert: ค่า SCr ไม่คงที่ สูตร Cockcroft-Gault จะไม่แม่นยำ (ห้ามใช้ CrCl นี้)',
          ),
        );
      } else {
        crcl = RenalCalculator.cockcroftGault(
          ageYears: patient.ageYears,
          weightKg: crclDosingWeight,
          sex: patient.sex,
          serumCreatinineMgDl: patient.serumCreatinineMgDl!,
        );

        // Low SCr in elderly check
        if (patient.serumCreatinineMgDl! < 0.6 && patient.ageYears >= 65) {
          warnings.add(
            const DoseWarning(
              severity: LimitSeverity.soft,
              messageEn:
                  'Elderly with low SCr (<0.6). CrCl may be overestimated.',
              messageTh: 'ผู้สูงอายุที่มี SCr ต่ำ (<0.6) ค่า CrCl ที่ได้อาจสูงเกินจริง (พิจารณาปัด SCr เป็น 0.8 หรือ 1.0)',
            ),
          );
        }
      }
    } else if (drug.requiresRenalAdjustment) {
      warnings.add(
        const DoseWarning(
          severity: LimitSeverity.hard,
          messageEn:
              'RENAL ALERT: This drug requires dose adjustment in renal impairment, but Serum Creatinine was NOT provided. Standard dose calculated assuming normal renal function (CrCl > 50 mL/min).',
          messageTh:
              'เตือนความปลอดภัย: ยานี้ต้องปรับขนาดยาตามการทำงานของไต แต่ไม่ได้ระบุค่า SCr ระบบจึงคำนวณตามขนาดปกติของผู้ป่วยที่ไตทำงานปกติ (CrCl > 50)',
        ),
      );
    }

    // --- 3. Base Dose Calculation ---
    if (regimen.dosingType == DosingType.weightBased) {
      double weightForDosing = patient.weightKg;
      if (regimen.dosingWeightStrategy == DosingWeightStrategy.ideal) {
        weightForDosing = ibw;
      } else if (regimen.dosingWeightStrategy == DosingWeightStrategy.adjustedIfObese) {
        if (WeightBasedCalculator.isObese(actualWeightKg: patient.weightKg, ibwKg: ibw)) {
          weightForDosing = WeightBasedCalculator.adjustedBodyWeight(
            actualWeightKg: patient.weightKg,
            ibwKg: ibw,
          );
          warnings.add(DoseWarning(
            severity: LimitSeverity.info,
            messageEn:
                'Using Adjusted Body Weight (${weightForDosing.toStringAsFixed(1)} kg) for dosing in obese patient.',
            messageTh:
                'ใช้น้ำหนักปรับปรุง (AdjBW ${weightForDosing.toStringAsFixed(1)} กก.) ในการคำนวณสำหรับผู้ป่วยอ้วน',
          ));
        } else if (patient.weightKg > ibw) {
          weightForDosing = ibw;
        }
      }

      dose = WeightBasedCalculator.calculateDose(
        weightKg: weightForDosing,
        dosePerKg: regimen.dosePerKg ?? 0,
      );
    } else if (regimen.dosingType == DosingType.fixed) {
      dose = regimen.fixedDose ?? 0;
    } else if (regimen.dosingType == DosingType.bsaBased) {
      final bsa = BsaCalculator.mosteller(
        heightCm: patient.heightCm,
        weightKg: patient.weightKg,
      );
      dose = WeightBasedCalculator.calculateBsaDose(
        bsaM2: bsa,
        dosePerM2: regimen.dosePerM2 ?? 0,
      );
    } else if (regimen.dosingType == DosingType.titrated) {
      dose = regimen.continuousRateMin ?? 0;
    } else if (regimen.dosingType == DosingType.gfrBased) {
      final gfr = crcl ?? 0;
      dose = WeightBasedCalculator.calvertFormula(
        targetAuc: regimen.targetAuc ?? 5.0,
        gfrMlMin: gfr,
      );
      if (crcl == null) {
        warnings.add(
          const DoseWarning(
            severity: LimitSeverity.hard,
            messageEn: 'Calvert formula requires CrCl / GFR. Please provide SCr.',
            messageTh: 'สูตร Calvert ต้องใช้ค่า CrCl / GFR กรุณาระบุค่า SCr',
          ),
        );
      }
    }

    // --- 4. Automated Renal Adjuster ---
    double finalDose = dose;
    String finalFrequency = regimen.frequency;
    bool isRenallyAdjusted = false;
    double? appliedRenalFactor;

    if (crcl != null && regimen.renalAdjustments != null) {
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
                messageEn:
                    'Auto Renal Adjustment applied (CrCl ${crcl.toStringAsFixed(1)} mL/min).',
                messageTh:
                    'ปรับขนาดยาอัตโนมัติตามค่า CrCl ${crcl.toStringAsFixed(1)} mL/min แล้ว',
              ),
            );
          }
          break; // Stop at first applicable tier
        }
      }
    }

    // --- 5. Formulary Rounding ---
    double? roundedDose;
    if (drug.availableStrengths != null &&
        drug.availableStrengths!.isNotEmpty) {
      roundedDose = DoseRounder.roundToNearestStrength(
        finalDose,
        drug.availableStrengths!,
      );
    }

    // --- 6. Safety Limits Check ---
    if (regimen.limits != null) {
      // Helper to calculate daily dose
      double calculateDailyDose(double singleDose, String freqStr) {
        final f = freqStr.toLowerCase();
        if (f.contains('q24h') || f == 'daily') return singleDose;
        if (f.contains('q12h') || f == 'bid') return singleDose * 2;
        if (f.contains('q8h') || f == 'tid') return singleDose * 3;
        if (f.contains('q6h') || f == 'qid') return singleDose * 4;
        if (f.contains('q48h')) return singleDose / 2;
        if (f.contains('q72h')) return singleDose / 3;
        return singleDose; // fallback
      }

      warnings.addAll(
        DoseChecker.checkDose(
          calculatedDose: finalDose,
          limits: regimen.limits!,
          doseUnit: regimen.doseUnit.symbol,
          weightKg: patient.weightKg,
          dailyDose: calculateDailyDose(finalDose, finalFrequency),
        ),
      );
    }

    if (drug.isHighAlert) {
      warnings.insert(0, DoseChecker.highAlertWarning(drug.genericName));
    }

    // Return the immutable result
    return DosageResult(
      success: true,
      calculatedDose: finalDose,
      doseUnit: regimen.doseUnit,
      frequency: finalFrequency,
      formulaUsed: regimen.dosingType.nameEn,
      crclMlMin: crcl,
      isRenallyAdjusted: isRenallyAdjusted,
      renalAdjustmentFactor: appliedRenalFactor,
      roundedDose: roundedDose,
      warnings: warnings,
    );
  }
}
