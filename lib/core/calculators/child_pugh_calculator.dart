// ============================================================
// Drug Dosage Calculator — Child-Pugh Hepatic Score Calculator
// ============================================================
// Pure deterministic Child-Pugh-Turcotte classification engine
// (scores 5–15 -> Class A / B / C) for hepatic dose adjustment
// and contraindication screening.
//
// Zero Flutter UI dependency, zero runtime AI/LLM.
// Primary References:
// 1. Pugh RN et al. Br J Surg. 1973;60(8):646-649.
// 2. DiPiro's Pharmacotherapy: A Pathophysiologic Approach, 12th Ed.
// 3. US FDA Guidance for Industry: Pharmacokinetics in Patients
//    with Impaired Hepatic Function.
// ============================================================

import '../models/population_criteria.dart';

/// Clinical severity grading of ascites in the Child-Pugh score.
enum ChildPughAscites {
  none(
    points: 1,
    labelEn: 'None',
    labelTh: 'ไม่มีภาวะท้องมาน (None)',
  ),
  mildOrControlled(
    points: 2,
    labelEn: 'Mild / Controlled with diuretics',
    labelTh: 'เล็กน้อย / ควบคุมได้ด้วยยาขับปัสสาวะ (Mild)',
  ),
  moderateToSevere(
    points: 3,
    labelEn: 'Moderate–Severe / Refractory',
    labelTh: 'ปานกลางถึงรุนแรง / ดื้อต่อยา (Moderate–Severe)',
  );

  final int points;
  final String labelEn;
  final String labelTh;

  const ChildPughAscites({
    required this.points,
    required this.labelEn,
    required this.labelTh,
  });
}

/// Clinical West Haven grading of hepatic encephalopathy in the Child-Pugh score.
enum ChildPughEncephalopathy {
  none(
    points: 1,
    labelEn: 'None',
    labelTh: 'ไม่มีอาการทางสมอง (None)',
  ),
  grade1To2(
    points: 2,
    labelEn: 'Grade I–II (Mild–Moderate / Controlled)',
    labelTh: 'ระดับ 1–2 (สับสนเล็กน้อยถึงปานกลาง / คุมได้)',
  ),
  grade3To4(
    points: 3,
    labelEn: 'Grade III–IV (Severe / Stupor–Coma)',
    labelTh: 'ระดับ 3–4 (ซึมมาก / โคม่า)',
  );

  final int points;
  final String labelEn;
  final String labelTh;

  const ChildPughEncephalopathy({
    required this.points,
    required this.labelEn,
    required this.labelTh,
  });
}

/// Immutable result of a Child-Pugh hepatic impairment calculation.
class ChildPughResult {
  /// Total Child-Pugh score (strictly 5 to 15).
  final int totalScore;

  /// Derived Child-Pugh classification (`classA`, `classB`, or `classC`).
  final ChildPughClass classification;

  /// Points assigned for Total Bilirubin (1–3).
  final int bilirubinPoints;

  /// Points assigned for Serum Albumin (1–3).
  final int albuminPoints;

  /// Points assigned for INR (1–3).
  final int inrPoints;

  /// Points assigned for Ascites (1–3).
  final int ascitesPoints;

  /// Points assigned for Hepatic Encephalopathy (1–3).
  final int encephalopathyPoints;

  const ChildPughResult({
    required this.totalScore,
    required this.classification,
    required this.bilirubinPoints,
    required this.albuminPoints,
    required this.inrPoints,
    required this.ascitesPoints,
    required this.encephalopathyPoints,
  });

  /// Concise English summary for clinical documentation.
  String get summaryEn =>
      '${classification.labelEn} — Score $totalScore/15';

  /// Concise Thai summary for clinical documentation.
  String get summaryTh =>
      '${classification.labelTh} — คะแนน $totalScore/15';
}

/// Non-throwing validation wrapper for UI form evaluation.
class ChildPughEvaluation {
  final ChildPughResult? result;
  final String? errorEn;
  final String? errorTh;

  const ChildPughEvaluation.success(ChildPughResult this.result)
      : errorEn = null,
        errorTh = null;

  const ChildPughEvaluation.failure({
    required String this.errorEn,
    required String this.errorTh,
  }) : result = null;

  bool get isValid => result != null;
}

/// Pure deterministic Child-Pugh hepatic function calculator.
class ChildPughCalculator {
  const ChildPughCalculator._();

  /// Scores Total Bilirubin in `mg/dL` (standard non-cholestatic thresholds):
  /// - `< 2.0 mg/dL` -> 1 point
  /// - `2.0 to 3.0 mg/dL` (inclusive) -> 2 points
  /// - `> 3.0 mg/dL` -> 3 points
  static int scoreBilirubin(double totalBilirubinMgDl) {
    _requirePositiveFinite(totalBilirubinMgDl, 'totalBilirubinMgDl');
    if (totalBilirubinMgDl < 2.0) return 1;
    if (totalBilirubinMgDl <= 3.0) return 2;
    return 3;
  }

  /// Scores Serum Albumin in `g/dL`:
  /// - `> 3.5 g/dL` -> 1 point
  /// - `2.8 to 3.5 g/dL` (inclusive) -> 2 points
  /// - `< 2.8 g/dL` -> 3 points
  static int scoreAlbumin(double serumAlbuminGDl) {
    _requirePositiveFinite(serumAlbuminGDl, 'serumAlbuminGDl');
    if (serumAlbuminGDl > 3.5) return 1;
    if (serumAlbuminGDl >= 2.8) return 2;
    return 3;
  }

  /// Scores International Normalized Ratio (`INR`):
  /// - `< 1.7` -> 1 point
  /// - `1.7 to 2.3` (inclusive) -> 2 points
  /// - `> 2.3` -> 3 points
  static int scoreInr(double inr) {
    _requirePositiveFinite(inr, 'inr');
    if (inr < 1.7) return 1;
    if (inr <= 2.3) return 2;
    return 3;
  }

  /// Maps a total Child-Pugh score (`5–15`) to [ChildPughClass]:
  /// - `5–6` -> [ChildPughClass.classA]
  /// - `7–9` -> [ChildPughClass.classB]
  /// - `10–15` -> [ChildPughClass.classC]
  static ChildPughClass classifyScore(int totalScore) {
    if (totalScore < 5 || totalScore > 15) {
      throw ArgumentError.value(
        totalScore,
        'totalScore',
        'Child-Pugh total score must be between 5 and 15 inclusive.',
      );
    }
    if (totalScore <= 6) return ChildPughClass.classA;
    if (totalScore <= 9) return ChildPughClass.classB;
    return ChildPughClass.classC;
  }

  /// Deterministically computes the [ChildPughResult] from all 5 clinical inputs.
  ///
  /// Throws [ArgumentError] if any laboratory measurement is `<= 0`, `NaN`,
  /// `Infinite`, or outside physiologically plausible upper bounds.
  static ChildPughResult calculate({
    required double totalBilirubinMgDl,
    required double serumAlbuminGDl,
    required double inr,
    required ChildPughAscites ascites,
    required ChildPughEncephalopathy encephalopathy,
  }) {
    final validationError = _validateInputs(
      totalBilirubinMgDl: totalBilirubinMgDl,
      serumAlbuminGDl: serumAlbuminGDl,
      inr: inr,
    );
    if (validationError != null) {
      throw ArgumentError(validationError.en);
    }

    final biliPts = scoreBilirubin(totalBilirubinMgDl);
    final albPts = scoreAlbumin(serumAlbuminGDl);
    final inrPts = scoreInr(inr);
    final ascPts = ascites.points;
    final encPts = encephalopathy.points;

    final total = biliPts + albPts + inrPts + ascPts + encPts;
    final classification = classifyScore(total);

    return ChildPughResult(
      totalScore: total,
      classification: classification,
      bilirubinPoints: biliPts,
      albuminPoints: albPts,
      inrPoints: inrPts,
      ascitesPoints: ascPts,
      encephalopathyPoints: encPts,
    );
  }

  /// Non-throwing evaluation helper for bedside UI forms.
  static ChildPughEvaluation evaluate({
    required double? totalBilirubinMgDl,
    required double? serumAlbuminGDl,
    required double? inr,
    required ChildPughAscites ascites,
    required ChildPughEncephalopathy encephalopathy,
  }) {
    if (totalBilirubinMgDl == null ||
        serumAlbuminGDl == null ||
        inr == null) {
      return const ChildPughEvaluation.failure(
        errorEn: 'Please enter valid numeric values for Bilirubin, Albumin, and INR.',
        errorTh: 'กรุณากรอกค่าตัวเลข Bilirubin, Albumin และ INR ให้ครบถ้วน',
      );
    }
    final err = _validateInputs(
      totalBilirubinMgDl: totalBilirubinMgDl,
      serumAlbuminGDl: serumAlbuminGDl,
      inr: inr,
    );
    if (err != null) {
      return ChildPughEvaluation.failure(errorEn: err.en, errorTh: err.th);
    }
    return ChildPughEvaluation.success(
      calculate(
        totalBilirubinMgDl: totalBilirubinMgDl,
        serumAlbuminGDl: serumAlbuminGDl,
        inr: inr,
        ascites: ascites,
        encephalopathy: encephalopathy,
      ),
    );
  }

  static void _requirePositiveFinite(double value, String name) {
    if (value.isNaN || value.isInfinite || value <= 0) {
      throw ArgumentError.value(
        value,
        name,
        '$name must be a finite number greater than 0.',
      );
    }
  }

  static ({String en, String th})? _validateInputs({
    required double totalBilirubinMgDl,
    required double serumAlbuminGDl,
    required double inr,
  }) {
    if (totalBilirubinMgDl.isNaN ||
        totalBilirubinMgDl.isInfinite ||
        totalBilirubinMgDl <= 0 ||
        totalBilirubinMgDl > 100.0) {
      return (
        en: 'Total Bilirubin must be > 0 and <= 100 mg/dL.',
        th: 'ค่า Total Bilirubin ต้องมากกว่า 0 และไม่เกิน 100 mg/dL',
      );
    }
    if (serumAlbuminGDl.isNaN ||
        serumAlbuminGDl.isInfinite ||
        serumAlbuminGDl <= 0 ||
        serumAlbuminGDl > 10.0) {
      return (
        en: 'Serum Albumin must be > 0 and <= 10 g/dL.',
        th: 'ค่า Serum Albumin ต้องมากกว่า 0 และไม่เกิน 10 g/dL',
      );
    }
    if (inr.isNaN || inr.isInfinite || inr < 0.5 || inr > 30.0) {
      return (
        en: 'INR must be between 0.5 and 30.0.',
        th: 'ค่า INR ต้องอยู่ระหว่าง 0.5 ถึง 30.0',
      );
    }
    return null;
  }
}
