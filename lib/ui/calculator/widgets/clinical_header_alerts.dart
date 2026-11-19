import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../../theme/app_theme.dart';
import '../../widgets/clinical_evidence_sheet.dart';

/// Clinical drug safety notes, contraindications, side effects, and interactive
/// hepatic adjustment guidance card.
class ClinicalHeaderAlerts extends StatelessWidget {
  final Drug drug;
  final bool isThai;
  final Color categoryColor;

  const ClinicalHeaderAlerts({
    super.key,
    required this.drug,
    required this.isThai,
    this.categoryColor = AppTheme.primaryTeal,
  });

  @override
  Widget build(BuildContext context) {
    final t = isThai;
    final sideEffects = t
        ? (drug.sideEffectsTh.isNotEmpty
            ? drug.sideEffectsTh
            : drug.sideEffects)
        : drug.sideEffects;
    final subtitleText =
        t && drug.nameTh != null ? drug.nameTh! : drug.brandNames.join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (subtitleText.trim().isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              subtitleText,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.inkSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],

        if (drug.contraindications.isNotEmpty)
          _buildListAlertCard(
            icon: Icons.do_not_disturb_alt_outlined,
            accentColor: AppTheme.statusCritical,
            bgColor: AppTheme.statusCriticalBg,
            borderColor: AppTheme.statusCriticalBorder,
            textColor: const Color(0xFF991B1B),
            title: t ? 'ข้อห้ามใช้ (Contraindications)' : 'Contraindications',
            items: drug.contraindications,
          ),

        _buildListAlertCard(
          icon: Icons.health_and_safety_outlined,
          accentColor: AppTheme.statusWarning,
          bgColor: AppTheme.statusWarningBg,
          borderColor: AppTheme.statusWarningBorder,
          textColor: const Color(0xFF92400E),
          title: t ? 'ผลข้างเคียงสำคัญ (Side Effects)' : 'Important Side Effects',
          items: sideEffects.isNotEmpty
              ? sideEffects
              : [
                  t
                      ? 'ยังไม่มีข้อมูลที่ยืนยันในฐานข้อมูล'
                      : 'No verified side-effect data in the database.',
                ],
        ),

        if (drug.pregnancyCategory != null)
          _buildAlertCard(
            icon: Icons.pregnant_woman_outlined,
            accentColor: (drug.pregnancyCategory == 'X' ||
                    drug.pregnancyCategory == 'D')
                ? AppTheme.statusCritical
                : AppTheme.statusWarning,
            bgColor: (drug.pregnancyCategory == 'X' ||
                    drug.pregnancyCategory == 'D')
                ? AppTheme.statusCriticalBg
                : AppTheme.statusWarningBg,
            borderColor: (drug.pregnancyCategory == 'X' ||
                    drug.pregnancyCategory == 'D')
                ? AppTheme.statusCriticalBorder
                : AppTheme.statusWarningBorder,
            textColor: (drug.pregnancyCategory == 'X' ||
                    drug.pregnancyCategory == 'D')
                ? const Color(0xFF991B1B)
                : const Color(0xFF92400E),
            text: t
                ? 'ความปลอดภัยในสตรีมีครรภ์: Category ${drug.pregnancyCategory}'
                : 'Pregnancy Category: ${drug.pregnancyCategory}',
          ),

        if (drug.requiresHepaticCaution)
          _buildAlertCard(
            key: const Key('clinical_alert_hepatic_caution_card'),
            icon: Icons.local_hospital_outlined,
            accentColor: AppTheme.statusWarning,
            bgColor: AppTheme.statusWarningBg,
            borderColor: AppTheme.statusWarningBorder,
            textColor: const Color(0xFF92400E),
            text: t
                ? 'ควรปรับขนาดหรือระวังในผู้ป่วยโรคตับ (Hepatic caution)'
                : 'Hepatic dose adjustment / caution required',
            actionLabel: t ? 'ดูแนวทาง ↗' : 'Guidance ↗',
            onTap: () => ClinicalEvidenceSheet.show(
              context,
              drug: drug,
              isThai: t,
              initialSection: 'hepatic',
            ),
          ),

        if (drug.specialNotes != null || drug.specialNotesTh != null)
          _buildAlertCard(
            icon: Icons.info_outline,
            accentColor: AppTheme.statusInfo,
            bgColor: AppTheme.statusInfoBg,
            borderColor: AppTheme.statusInfoBorder,
            textColor: const Color(0xFF075985),
            text: t
                ? (drug.specialNotesTh ?? drug.specialNotes!)
                : drug.specialNotes!,
          ),
      ],
    );
  }

  Widget _buildAlertCard({
    Key? key,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
    required String text,
    String? actionLabel,
    VoidCallback? onTap,
  }) {
    final content = Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                if (actionLabel != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          actionLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.open_in_new, size: 14, color: accentColor),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: onTap != null
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onTap,
                child: content,
              ),
            )
          : content,
    );
  }

  Widget _buildListAlertCard({
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
    required String title,
    required List<String> items,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: accentColor, size: 19),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...items.map(
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 3.0, left: 27.0),
                child: Text(
                  '• $i',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
