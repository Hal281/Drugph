import 'package:flutter/material.dart';

import '../../../core/core.dart';

/// IV Diluent Compatibility and Precipitation Safety Card.
///
/// Highlights preferred IV fluids (e.g. D5W, 0.9% NS), displays clear warnings
/// and biochemical precipitation risks for contraindicated fluids (e.g. LR, sterile water).
class IvDiluentCompatibilityCard extends StatelessWidget {
  final Drug drug;
  final DosingRegimen selectedRegimen;
  final bool isThai;

  const IvDiluentCompatibilityCard({
    super.key,
    required this.drug,
    required this.selectedRegimen,
    required this.isThai,
  });

  @override
  Widget build(BuildContext context) {
    final t = isThai;
    final compat = selectedRegimen.effectiveIvDiluentCompatibility(drug);
    if (compat == null) return const SizedBox.shrink();

    return Card(
      key: const Key('calculator_iv_diluent_card'),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: compat.incompatibleDiluents.isNotEmpty
              ? Colors.red.shade300
              : Colors.teal.shade300,
        ),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.water_drop_rounded,
                  color: compat.incompatibleDiluents.isNotEmpty
                      ? Colors.red.shade700
                      : Colors.teal.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t
                        ? 'ความเข้ากันได้ของสารน้ำผสมยา (IV Diluent Compatibility)'
                        : 'IV Diluent Compatibility & Precipitation Safety',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...compat.compatibleDiluents.map((d) {
                  final pref = compat.isPreferred(d);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: pref
                            ? Colors.teal.shade700
                            : Colors.teal.shade300,
                        width: pref ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          pref ? Icons.star_rounded : Icons.check_circle,
                          size: 15,
                          color: Colors.teal.shade800,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            pref
                                ? '${d.code} (${t ? "แนะนำหลัก" : "Preferred"})'
                                : '${d.code} (${t ? "ผสมได้" : "Compatible"})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                ...compat.incompatibleDiluents.map((d) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.shade700,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.block_rounded,
                          size: 15,
                          color: Colors.red.shade800,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${t ? "ห้ามผสม" : "Avoid"} ${d.code}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
            if (compat.incompatibilityReasonEn != null ||
                compat.incompatibilityReasonTh != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: Colors.red.shade800,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t
                            ? (compat.incompatibilityReasonTh ??
                                compat.incompatibilityReasonEn!)
                            : (compat.incompatibilityReasonEn ??
                                compat.incompatibilityReasonTh!),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (compat.stabilityNoteEn != null ||
                compat.stabilityNoteTh != null) ...[
              const SizedBox(height: 8),
              Text(
                t
                    ? (compat.stabilityNoteTh ?? compat.stabilityNoteEn!)
                    : (compat.stabilityNoteEn ?? compat.stabilityNoteTh!),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blueGrey.shade800,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              '${t ? "อ้างอิง" : "Source"}: ${compat.sourceCitation}',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
