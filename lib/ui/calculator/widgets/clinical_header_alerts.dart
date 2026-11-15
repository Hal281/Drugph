import 'package:flutter/material.dart';

import '../../../core/core.dart';

/// Clinical drug header and single-drug safety alert cards.
class ClinicalHeaderAlerts extends StatelessWidget {
  final Drug drug;
  final bool isThai;
  final Color categoryColor;

  const ClinicalHeaderAlerts({
    super.key,
    required this.drug,
    required this.isThai,
    this.categoryColor = Colors.teal,
  });

  @override
  Widget build(BuildContext context) {
    final t = isThai;
    final sideEffects = t
        ? (drug.sideEffectsTh.isNotEmpty
            ? drug.sideEffectsTh
            : drug.sideEffects)
        : drug.sideEffects;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Brand names & Thai name
        Text(
          t && drug.nameTh != null ? drug.nameTh! : drug.brandNames.join(', '),
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),

        _buildListAlertCard(
          Icons.health_and_safety_outlined,
          Colors.deepOrange,
          t ? 'ผลข้างเคียงสำคัญ (Side Effects)' : 'Important Side Effects',
          sideEffects.isNotEmpty
              ? sideEffects
              : [
                  t
                      ? 'ยังไม่มีข้อมูลที่ยืนยันในฐานข้อมูล'
                      : 'No verified side-effect data in the database.',
                ],
        ),

        // Pre-calculate Warnings
        if (drug.pregnancyCategory != null)
          _buildAlertCard(
            Icons.pregnant_woman,
            (drug.pregnancyCategory == 'X' || drug.pregnancyCategory == 'D')
                ? Colors.red
                : Colors.orange,
            t
                ? 'ความปลอดภัยในสตรีมีครรภ์: Category ${drug.pregnancyCategory}'
                : 'Pregnancy Category: ${drug.pregnancyCategory}',
          ),

        if (drug.requiresHepaticCaution)
          _buildAlertCard(
            Icons.local_hospital,
            Colors.orange,
            t
                ? 'ควรปรับขนาดหรือระวังในผู้ป่วยโรคตับ (Hepatic caution)'
                : 'Hepatic dose adjustment / caution required',
          ),

        if (drug.contraindications.isNotEmpty)
          _buildListAlertCard(
            Icons.do_not_disturb_alt,
            Colors.red,
            t ? 'ข้อห้ามใช้ (Contraindications)' : 'Contraindications',
            drug.contraindications,
          ),

        if (drug.specialNotes != null || drug.specialNotesTh != null)
          _buildAlertCard(
            Icons.info_outline,
            Colors.blue,
            t
                ? (drug.specialNotesTh ?? drug.specialNotes!)
                : drug.specialNotes!,
          ),
      ],
    );
  }

  Widget _buildAlertCard(IconData icon, Color color, String text) {
    return Card(
      color: color.withValues(alpha: 0.1),
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color.withValues(alpha: 0.5), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: color.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListAlertCard(
    IconData icon,
    Color color,
    String title,
    List<String> items,
  ) {
    return Card(
      color: color.withValues(alpha: 0.1),
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color.withValues(alpha: 0.5), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...items.map(
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0, left: 28.0),
                child: Text(
                  '• $i',
                  style: TextStyle(color: color.withValues(alpha: 0.9)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
