import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../../widgets/clinical_evidence_sheet.dart';

/// Clinical drug header, metadata provenance badge, and safety alert cards.
class ClinicalHeaderAlerts extends StatelessWidget {
  final Drug drug;
  final DosingRegimen? selectedRegimen;
  final bool isThai;
  final Color categoryColor;

  const ClinicalHeaderAlerts({
    super.key,
    required this.drug,
    this.selectedRegimen,
    required this.isThai,
    this.categoryColor = Colors.teal,
  });

  @override
  Widget build(BuildContext context) {
    final t = isThai;

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

        if (drug.allergyClass != null)
          _buildAlertCard(
            Icons.medical_information,
            Colors.purple,
            t
                ? 'ตรวจสอบประวัติแพ้ยากลุ่ม: ${drug.allergyClass}'
                : 'Check patient allergy to: ${drug.allergyClass}',
          ),

        if (drug.severeInteractions.isNotEmpty)
          _buildListAlertCard(
            Icons.warning_amber,
            Colors.orange,
            t ? 'ระวังยาตีกัน (Severe Interactions)' : 'Severe Interactions',
            drug.severeInteractions,
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
            t ? (drug.specialNotesTh ?? drug.specialNotes!) : drug.specialNotes!,
          ),

        // Clinical Metadata Badge (Source & Last Reviewed - Interactive)
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => ClinicalEvidenceSheet.show(
              context,
              drug: drug,
              regimen: selectedRegimen,
              isThai: t,
            ),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.teal.shade50.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    size: 18,
                    color: Colors.teal.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final textScale =
                                MediaQuery.textScalerOf(context).scale(1.0);
                            final isCompact = constraints.maxWidth < 280 ||
                                textScale > 1.15;

                            if (isCompact) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t
                                        ? 'แหล่งอ้างอิงทางคลินิก (Textbook Reference)'
                                        : 'Clinical Evidence Reference',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal.shade900,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    t ? 'แตะเพื่อเปิดดูตำรา ↗' : 'Tap to view ↗',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.teal.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    t
                                        ? 'แหล่งอ้างอิงทางคลินิก (Textbook Reference)'
                                        : 'Clinical Evidence Reference',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal.shade900,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    t ? 'แตะเพื่อเปิดดูตำรา ↗' : 'Tap to view ↗',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.teal.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 2),
                        Text(
                          t
                              ? '${drug.sourceCitation} • ตรวจสอบล่าสุด: ${drug.lastReviewedDate}'
                              : '${drug.sourceCitation} • Reviewed: ${drug.lastReviewedDate}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blueGrey.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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
