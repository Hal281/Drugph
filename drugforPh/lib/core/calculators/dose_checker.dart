// ============================================================
// Drug Dosage Calculator — Dose Safety Checker
// ============================================================
// Checks calculated doses against hard/soft limits.
// Returns a list of DoseWarning objects for the UI.
//
// Hard limit → red alert, BLOCK the order.
// Soft limit → yellow alert, WARN but allow override.
//
// DISCLAIMER: SaMD prototype — not for clinical use.
// ============================================================

import '../models/dose_limit.dart';
import '../models/drug.dart';

/// Checks a calculated dose against safety limits.
///
/// Returns an empty list if no limits are violated.
class DoseChecker {
  const DoseChecker._();

  /// Checks a [calculatedDose] against the regimen's [DoseLimit].
  ///
  /// [dailyDose] is the total daily dose if known.
  /// [weightKg] is patient weight (needed for per-kg checks).
  /// [doseUnit] is for display in warning messages.
  static List<DoseWarning> checkDose({
    required double calculatedDose,
    required DoseLimit limits,
    double? dailyDose,
    double? weightKg,
    String doseUnit = 'mg',
  }) {
    final warnings = <DoseWarning>[];

    // --- Hard limit: max single dose ---
    if (limits.maxSingleDose != null &&
        calculatedDose > limits.maxSingleDose!) {
      warnings.add(DoseWarning(
        severity: LimitSeverity.hard,
        messageEn:
            'EXCEEDS MAX SINGLE DOSE: '
            '${_fmt(calculatedDose)} $doseUnit > '
            '${_fmt(limits.maxSingleDose!)} $doseUnit (hard limit)',
        messageTh:
            'เกินขนาดยาสูงสุดต่อครั้ง: '
            '${_fmt(calculatedDose)} $doseUnit > '
            '${_fmt(limits.maxSingleDose!)} $doseUnit (ขีดจำกัดสูงสุด)',
        calculatedValue: calculatedDose,
        limitValue: limits.maxSingleDose,
        unit: doseUnit,
      ));
    }

    // --- Soft limit: approaching max single dose ---
    if (limits.softMaxSingleDose != null &&
        limits.maxSingleDose != null &&
        calculatedDose > limits.softMaxSingleDose! &&
        calculatedDose <= limits.maxSingleDose!) {
      warnings.add(DoseWarning(
        severity: LimitSeverity.soft,
        messageEn:
            'Dose approaching max limit: '
            '${_fmt(calculatedDose)} $doseUnit '
            '(soft limit: ${_fmt(limits.softMaxSingleDose!)} $doseUnit)',
        messageTh:
            'ขนาดยาใกล้ถึงขีดจำกัด: '
            '${_fmt(calculatedDose)} $doseUnit '
            '(เตือน: ${_fmt(limits.softMaxSingleDose!)} $doseUnit)',
        calculatedValue: calculatedDose,
        limitValue: limits.softMaxSingleDose,
        unit: doseUnit,
      ));
    }

    // --- Hard limit: max daily dose ---
    if (dailyDose != null &&
        limits.maxDailyDose != null &&
        dailyDose > limits.maxDailyDose!) {
      warnings.add(DoseWarning(
        severity: LimitSeverity.hard,
        messageEn:
            'EXCEEDS MAX DAILY DOSE: '
            '${_fmt(dailyDose)} $doseUnit/day > '
            '${_fmt(limits.maxDailyDose!)} $doseUnit/day',
        messageTh:
            'เกินขนาดยาสูงสุดต่อวัน: '
            '${_fmt(dailyDose)} $doseUnit/วัน > '
            '${_fmt(limits.maxDailyDose!)} $doseUnit/วัน',
        calculatedValue: dailyDose,
        limitValue: limits.maxDailyDose,
        unit: '$doseUnit/day',
      ));
    }

    // --- Hard limit: max dose per kg per day ---
    if (dailyDose != null &&
        weightKg != null &&
        weightKg > 0 &&
        limits.maxDosePerKgPerDay != null) {
      final dosePerKgPerDay = dailyDose / weightKg;
      if (dosePerKgPerDay > limits.maxDosePerKgPerDay!) {
        warnings.add(DoseWarning(
          severity: LimitSeverity.hard,
          messageEn:
              'EXCEEDS MAX DOSE/KG/DAY: '
              '${_fmt(dosePerKgPerDay)} $doseUnit/kg/day > '
              '${_fmt(limits.maxDosePerKgPerDay!)} $doseUnit/kg/day',
          messageTh:
              'เกินขนาดยาสูงสุดต่อกก.ต่อวัน: '
              '${_fmt(dosePerKgPerDay)} $doseUnit/กก./วัน > '
              '${_fmt(limits.maxDosePerKgPerDay!)} $doseUnit/กก./วัน',
          calculatedValue: dosePerKgPerDay,
          limitValue: limits.maxDosePerKgPerDay,
          unit: '$doseUnit/kg/day',
        ));
      }
    }

    // --- Info: minimum dose ---
    if (limits.minSingleDose != null &&
        calculatedDose < limits.minSingleDose!) {
      warnings.add(DoseWarning(
        severity: LimitSeverity.info,
        messageEn:
            'Dose below minimum: '
            '${_fmt(calculatedDose)} $doseUnit < '
            '${_fmt(limits.minSingleDose!)} $doseUnit',
        messageTh:
            'ขนาดยาต่ำกว่าขั้นต่ำ: '
            '${_fmt(calculatedDose)} $doseUnit < '
            '${_fmt(limits.minSingleDose!)} $doseUnit',
        calculatedValue: calculatedDose,
        limitValue: limits.minSingleDose,
        unit: doseUnit,
      ));
    }

    return warnings;
  }

  /// Checks infusion rate against the drug's maximum.
  static List<DoseWarning> checkInfusionRate({
    required double rateMgPerMin,
    required double maxRateMgPerMin,
  }) {
    final warnings = <DoseWarning>[];

    if (rateMgPerMin > maxRateMgPerMin) {
      warnings.add(DoseWarning(
        severity: LimitSeverity.hard,
        messageEn:
            'EXCEEDS MAX INFUSION RATE: '
            '${_fmt(rateMgPerMin)} mg/min > '
            '${_fmt(maxRateMgPerMin)} mg/min',
        messageTh:
            'เกินอัตราหยดสูงสุด: '
            '${_fmt(rateMgPerMin)} มก./นาที > '
            '${_fmt(maxRateMgPerMin)} มก./นาที',
        calculatedValue: rateMgPerMin,
        limitValue: maxRateMgPerMin,
        unit: 'mg/min',
      ));
    }

    return warnings;
  }

  /// Generates a renal adjustment warning if applicable.
  static List<DoseWarning> checkRenalAdjustment({
    required double crclMlMin,
    required List<RenalAdjustment> adjustments,
  }) {
    final warnings = <DoseWarning>[];

    for (final adj in adjustments) {
      if (adj.appliesTo(crclMlMin) && adj.adjustmentFactor < 1.0) {
        warnings.add(DoseWarning(
          severity: LimitSeverity.soft,
          messageEn:
              'Renal dose adjustment: CrCl ${_fmt(crclMlMin)} mL/min '
              '→ reduce dose to ${(adj.adjustmentFactor * 100).toStringAsFixed(0)}%'
              '${adj.adjustedFrequency != null ? ", change frequency to ${adj.adjustedFrequency}" : ""}',
          messageTh:
              'ปรับโดสตามไต: CrCl ${_fmt(crclMlMin)} mL/min '
              '→ ลดโดสเหลือ ${(adj.adjustmentFactor * 100).toStringAsFixed(0)}%'
              '${adj.adjustedFrequency != null ? ", เปลี่ยนความถี่เป็น ${adj.adjustedFrequency}" : ""}',
          calculatedValue: crclMlMin,
          limitValue: adj.adjustmentFactor,
          unit: 'mL/min',
        ));
        break; // Only first matching tier
      }
    }

    // Critical renal impairment warning
    if (crclMlMin < 10) {
      warnings.add(DoseWarning(
        severity: LimitSeverity.hard,
        messageEn:
            'SEVERE RENAL IMPAIRMENT: CrCl ${_fmt(crclMlMin)} mL/min. '
            'Consult nephrologist before dosing.',
        messageTh:
            'ไตวายรุนแรง: CrCl ${_fmt(crclMlMin)} mL/min. '
            'ปรึกษาอายุรแพทย์โรคไตก่อนสั่งยา',
        calculatedValue: crclMlMin,
        unit: 'mL/min',
      ));
    }

    return warnings;
  }

  /// Generates a high-alert medication warning.
  static DoseWarning highAlertWarning(String drugName) {
    return DoseWarning(
      severity: LimitSeverity.soft,
      messageEn:
          '⚠️ HIGH-ALERT MEDICATION: $drugName requires independent '
          'double-check before administration.',
      messageTh:
          '⚠️ ยาที่มีความเสี่ยงสูง: $drugName ต้องตรวจสอบซ้ำ '
          'โดยบุคลากรอีกคนก่อนให้ยา',
    );
  }

  // Format number with up to 2 decimal places, no trailing zeros.
  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    if ((v * 10) == (v * 10).roundToDouble()) return v.toStringAsFixed(1);
    return v.toStringAsFixed(2);
  }
}
