import 'package:flutter/material.dart';

import '../../../core/core.dart';

/// Clinical Safety Alert Banner (Rule 5: Non-blocking Overdose Policy & Critical Safety Alert).
///
/// Prominently displays red/amber alert banners for overdose or hard contraindications,
/// strictly ensuring calculated doses remain visible and actionable for emergency override.
class SafetyAlertBanner extends StatelessWidget {
  final DosageResult result;
  final List<DoseWarning> warnings;
  final bool isThai;

  const SafetyAlertBanner({
    super.key,
    required this.result,
    required this.warnings,
    required this.isThai,
  });

  static bool hasOverdose(List<DoseWarning> warnings) {
    return warnings.any(
      (w) => const {
        DoseWarningCode.maxSingleDoseExceeded,
        DoseWarningCode.softMaxSingleDoseExceeded,
        DoseWarningCode.maxDailyDoseExceeded,
        DoseWarningCode.maxDosePerKgPerDayExceeded,
        DoseWarningCode.maxInfusionRateExceeded,
        DoseWarningCode.doseCappedAtMax,
      }.contains(w.code),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = isThai;
    final isOd = hasOverdose(warnings);

    if (isOd) {
      return Container(
        key: const Key('calculator_overdose_banner'),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade400, width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                t
                    ? '⚠️ คำเตือน: ขนาดยานี้เกินเกณฑ์สูงสุดที่แนะนำ (Overdose Warning) — โปรดใช้ดุลยพินิจของแพทย์/เภสัชกรในการให้ยา'
                    : '⚠️ CLINICAL WARNING: Dose exceeds recommended maximum limits — Please use clinical discretion',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.red.shade900,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (result.hasHardLimitViolation || result.hasHardWarning) {
      return Container(
        key: const Key('calculator_critical_safety_banner'),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade400, width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.gpp_bad_rounded,
              color: Colors.red,
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                t
                    ? '⚠️ คำเตือนความปลอดภัยทางคลินิกรุนแรง (Critical Safety Alert) — พบการแพ้ยา ข้อห้ามใช้ หรือปฏิกิริยาระหว่างยารุนแรง โปรดตรวจสอบด้านล่าง'
                    : '⚠️ CRITICAL CLINICAL SAFETY ALERT: Allergy, contraindication, or severe interaction detected — Review alerts below',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.red.shade900,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
