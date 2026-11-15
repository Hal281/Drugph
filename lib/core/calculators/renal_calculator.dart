// ============================================================
// Drug Dosage Calculator — Renal Function Calculator
// ============================================================
// Deterministic renal function estimation formulas:
//   1. Cockcroft-Gault → CrCl (mL/min)
//   2. CKD-EPI 2021   → eGFR (mL/min/1.73 m²)
//
// References:
//   Cockcroft DW, Gault MH. Nephron 1976;16:31-41.
//   Inker LA et al. N Engl J Med 2021;385:1737-49.
//
// DISCLAIMER: SaMD prototype — not for clinical use.
// ============================================================

import 'dart:math' as math;
import '../models/unit.dart';
import 'weight_based_calculator.dart';

/// Selected body weight metric and clinical rationale for the Cockcroft-Gault
/// CrCl equation per Winter MA et al. (*Am J Health-Syst Pharm* 2012;69:293-301).
class CockcroftGaultWeightSelection {
  final double actualWeightKg;
  final double ibwKg;
  final double adjBwKg;
  final double selectedWeightKg;
  final String strategy;
  final String reasonEn;
  final String reasonTh;

  const CockcroftGaultWeightSelection({
    required this.actualWeightKg,
    required this.ibwKg,
    required this.adjBwKg,
    required this.selectedWeightKg,
    required this.strategy,
    required this.reasonEn,
    required this.reasonTh,
  });
}

/// Deterministic renal function calculations.
class RenalCalculator {
  const RenalCalculator._();

  // ------------------------------------------------------------------
  // Cockcroft-Gault equation
  //
  // CrCl (mL/min) = ((140 − age) × weight_kg × [0.85 if female])
  //                  / (72 × serum_creatinine_mg_dL)
  //
  // Body weight selection per Winter 2012 / Lexicomp:
  //   - TBW < IBW        → TBW
  //   - IBW ≤ TBW < 120% → IBW
  //   - TBW ≥ 120% IBW   → AdjBW (IBW + 0.4 × [TBW − IBW])
  // ------------------------------------------------------------------

  /// Selects the appropriate adult body weight (TBW, IBW, or AdjBW 0.4) for
  /// Cockcroft-Gault creatinine clearance estimation per Winter 2012 guidelines.
  static CockcroftGaultWeightSelection selectCockcroftGaultWeight({
    required double weightKg,
    required double heightCm,
    required Sex sex,
  }) {
    if (!weightKg.isFinite || weightKg <= 0) {
      throw ArgumentError.value(
        weightKg,
        'weightKg',
        'Weight must be a positive finite number (> 0)',
      );
    }

    final ibw = WeightBasedCalculator.idealBodyWeight(
      heightCm: heightCm,
      sex: sex,
    );
    final adjBw = WeightBasedCalculator.adjustedBodyWeight(
      actualWeightKg: weightKg,
      ibwKg: ibw,
      factor: 0.4,
    );

    if (weightKg < ibw) {
      return CockcroftGaultWeightSelection(
        actualWeightKg: weightKg,
        ibwKg: ibw,
        adjBwKg: adjBw,
        selectedWeightKg: weightKg,
        strategy: 'TBW',
        reasonEn:
            'Underweight (TBW ${weightKg.toStringAsFixed(1)} kg < IBW ${ibw.toStringAsFixed(1)} kg): Using Actual Body Weight (TBW) for Cockcroft-Gault per Winter 2012.',
        reasonTh:
            'น้ำหนักน้อยกว่าเกณฑ์ (TBW ${weightKg.toStringAsFixed(1)} กก. < IBW ${ibw.toStringAsFixed(1)} กก.): ใช้ TBW คำนวณ Cockcroft-Gault ตามเกณฑ์ Winter 2012',
      );
    }

    if (weightKg >= 1.20 * ibw) {
      return CockcroftGaultWeightSelection(
        actualWeightKg: weightKg,
        ibwKg: ibw,
        adjBwKg: adjBw,
        selectedWeightKg: adjBw,
        strategy: 'AdjBW',
        reasonEn:
            'Overweight / Obese (TBW ${weightKg.toStringAsFixed(1)} kg ≥ 120% IBW ${ibw.toStringAsFixed(1)} kg): Using Adjusted Body Weight (AdjBW₀.₄ = ${adjBw.toStringAsFixed(1)} kg) for Cockcroft-Gault.',
        reasonTh:
            'น้ำหนักเกิน / อ้วน (TBW ${weightKg.toStringAsFixed(1)} กก. ≥ 120% IBW ${ibw.toStringAsFixed(1)} กก.): ใช้ AdjBW₀.₄ (${adjBw.toStringAsFixed(1)} กก.) คำนวณ Cockcroft-Gault',
      );
    }

    return CockcroftGaultWeightSelection(
      actualWeightKg: weightKg,
      ibwKg: ibw,
      adjBwKg: adjBw,
      selectedWeightKg: ibw,
      strategy: 'IBW',
      reasonEn:
          'Normal habitus (TBW ${weightKg.toStringAsFixed(1)} kg within IBW–120% IBW): Using Ideal Body Weight (IBW = ${ibw.toStringAsFixed(1)} kg) for Cockcroft-Gault.',
      reasonTh:
          'น้ำหนักอยู่ในเกณฑ์ปกติ (TBW ${weightKg.toStringAsFixed(1)} กก. อยู่ระหว่าง IBW–120% IBW): ใช้ IBW (${ibw.toStringAsFixed(1)} กก.) คำนวณ Cockcroft-Gault',
    );
  }

  /// Estimates Cockcroft-Gault CrCl automatically selecting TBW, IBW, or AdjBW
  /// based on height and sex per Winter 2012 / Lexicomp guidelines.
  static double cockcroftGaultAutoWeight({
    required int ageYears,
    required double weightKg,
    required double heightCm,
    required Sex sex,
    required double serumCreatinineMgDl,
  }) {
    final weightSelection = selectCockcroftGaultWeight(
      weightKg: weightKg,
      heightCm: heightCm,
      sex: sex,
    );
    return cockcroftGault(
      ageYears: ageYears,
      weightKg: weightSelection.selectedWeightKg,
      sex: sex,
      serumCreatinineMgDl: serumCreatinineMgDl,
    );
  }

  /// Estimates creatinine clearance using the **Cockcroft-Gault** equation.
  ///
  /// Returns CrCl in **mL/min**.
  static double cockcroftGault({
    required int ageYears,
    required double weightKg,
    required Sex sex,
    required double serumCreatinineMgDl,
  }) {
    if (!serumCreatinineMgDl.isFinite || serumCreatinineMgDl <= 0) {
      throw ArgumentError.value(
        serumCreatinineMgDl,
        'serumCreatinineMgDl',
        'Serum creatinine must be a positive finite number (> 0)',
      );
    }
    if (ageYears < 0 || ageYears > 150) {
      throw ArgumentError.value(ageYears, 'ageYears', 'Invalid age');
    }
    if (!weightKg.isFinite || weightKg <= 0) {
      throw ArgumentError.value(
        weightKg,
        'weightKg',
        'Weight must be a positive finite number (> 0)',
      );
    }

    double crcl =
        ((140.0 - ageYears) * weightKg) / (72.0 * serumCreatinineMgDl);

    if (sex == Sex.female) {
      crcl *= 0.85;
    }

    // CrCl cannot be negative (can happen if age > 140).
    return math.max(crcl, 0.0);
  }

  // ------------------------------------------------------------------
  // Bedside Schwartz equation (paediatric eGFR)
  //
  // eGFR (mL/min/1.73 m²) = 0.413 × height_cm / serum_creatinine_mg_dL
  //
  // Reference: Schwartz GJ et al. J Am Soc Nephrol 2009;20:629-37
  // (validated in children 1 to <18 years with CKD; CKiD cohort).
  // ------------------------------------------------------------------

  /// Estimates paediatric GFR using the **bedside Schwartz** equation.
  ///
  /// Returns eGFR in **mL/min/1.73 m²**. Valid for ages 1 to <18 years.
  static double bedsideSchwartz({
    required double heightCm,
    required double serumCreatinineMgDl,
  }) {
    if (!serumCreatinineMgDl.isFinite || serumCreatinineMgDl <= 0) {
      throw ArgumentError.value(
        serumCreatinineMgDl,
        'serumCreatinineMgDl',
        'Serum creatinine must be a positive finite number (> 0)',
      );
    }
    if (!heightCm.isFinite || heightCm <= 0) {
      throw ArgumentError.value(
        heightCm,
        'heightCm',
        'Height must be a positive finite number (> 0)',
      );
    }
    return 0.413 * heightCm / serumCreatinineMgDl;
  }

  // ------------------------------------------------------------------
  // CKD-EPI 2021 equation (race-free)
  //
  // eGFR = 142
  //        × min(SCr/κ, 1)^α
  //        × max(SCr/κ, 1)^(−1.200)
  //        × 0.9938^age
  //        × [1.012 if female]
  //
  // Where:
  //   κ = 0.7 (female), 0.9 (male)
  //   α = −0.241 (female), −0.302 (male)
  // ------------------------------------------------------------------

  /// Estimates GFR using the **CKD-EPI 2021** equation (race-free).
  ///
  /// Returns eGFR in **mL/min/1.73 m²**.
  static double ckdEpi2021({
    required int ageYears,
    required Sex sex,
    required double serumCreatinineMgDl,
  }) {
    if (!serumCreatinineMgDl.isFinite || serumCreatinineMgDl <= 0) {
      throw ArgumentError.value(
        serumCreatinineMgDl,
        'serumCreatinineMgDl',
        'Serum creatinine must be a positive finite number (> 0)',
      );
    }
    if (ageYears < 18) {
      throw ArgumentError.value(
        ageYears,
        'ageYears',
        'CKD-EPI 2021 is validated for adults (≥ 18 years)',
      );
    }

    final double kappa = sex == Sex.female ? 0.7 : 0.9;
    final double alpha = sex == Sex.female ? -0.241 : -0.302;

    final double scrOverKappa = serumCreatinineMgDl / kappa;

    double egfr = 142.0 *
        math.pow(math.min(scrOverKappa, 1.0), alpha) *
        math.pow(math.max(scrOverKappa, 1.0), -1.200) *
        math.pow(0.9938, ageYears.toDouble());

    if (sex == Sex.female) {
      egfr *= 1.012;
    }

    return math.max(egfr, 0.0);
  }

  // ------------------------------------------------------------------
  // Convenience dispatcher
  // ------------------------------------------------------------------

  /// Calculates renal function using the specified [formula].
  ///
  /// For [RenalFormula.cockcroftGault], [weightKg] is required.
  /// For [RenalFormula.ckdEpi2021], weight is not used.
  static double calculate({
    required int ageYears,
    required Sex sex,
    required double serumCreatinineMgDl,
    double? weightKg,
    RenalFormula formula = RenalFormula.cockcroftGault,
  }) {
    switch (formula) {
      case RenalFormula.cockcroftGault:
        if (weightKg == null) {
          throw ArgumentError(
            'Cockcroft-Gault requires weightKg',
          );
        }
        return cockcroftGault(
          ageYears: ageYears,
          weightKg: weightKg,
          sex: sex,
          serumCreatinineMgDl: serumCreatinineMgDl,
        );
      case RenalFormula.ckdEpi2021:
        return ckdEpi2021(
          ageYears: ageYears,
          sex: sex,
          serumCreatinineMgDl: serumCreatinineMgDl,
        );
    }
  }
}
