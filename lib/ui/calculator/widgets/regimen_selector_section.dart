import 'package:flutter/material.dart';

import '../../../core/core.dart';

/// Indication-driven dosing regimen dropdown selector (Lexicomp / Sanford Guide style)
/// with route abbreviations and renal/hepatic adjustment badges.
class RegimenSelectorSection extends StatelessWidget {
  final Drug drug;
  final DosingRegimen? selectedRegimen;
  final ValueChanged<DosingRegimen?> onRegimenChanged;
  final bool isThai;
  final Color categoryColor;

  const RegimenSelectorSection({
    super.key,
    required this.drug,
    required this.selectedRegimen,
    required this.onRegimenChanged,
    required this.isThai,
    this.categoryColor = Colors.teal,
  });

  @override
  Widget build(BuildContext context) {
    final t = isThai;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.vaccines, color: categoryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t ? 'ข้อบ่งใช้ / วิธีบริหารยา' : 'Indication / Route',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<DosingRegimen>(
                  isExpanded: true,
                  value: selectedRegimen,
                  icon: const Icon(Icons.arrow_drop_down),
                  items: drug.regimens
                      .map(
                        (r) => DropdownMenuItem(
                          value: r,
                          child: Text(
                            '${r.indication ?? "Standard"} (${r.route.abbreviation})',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: onRegimenChanged,
                ),
              ),
            ),
            if (selectedRegimen != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _buildRegimenPill(
                    t ? selectedRegimen!.route.nameTh : selectedRegimen!.route.nameEn,
                    Colors.blueGrey.shade700,
                    Colors.blueGrey.shade50,
                  ),
                  _buildRegimenPill(
                    t ? selectedRegimen!.dosingType.nameTh : selectedRegimen!.dosingType.nameEn,
                    Colors.teal.shade800,
                    Colors.teal.shade50,
                  ),
                  _buildRegimenPill(
                    t ? selectedRegimen!.frequency.displayTh : selectedRegimen!.frequency.displayEn,
                    Colors.indigo.shade800,
                    Colors.indigo.shade50,
                  ),
                  if (selectedRegimen!.renalAdjustments != null &&
                      selectedRegimen!.renalAdjustments!.isNotEmpty)
                    _buildRegimenPill(
                      t ? 'มีเกณฑ์ปรับตามไต' : 'Renal Adjusted',
                      Colors.amber.shade900,
                      Colors.amber.shade50,
                    ),
                  if (selectedRegimen!.population?.maxHepaticImpairment != null)
                    _buildRegimenPill(
                      t ? 'มีเกณฑ์ปรับตามตับ' : 'Hepatic Adjusted',
                      Colors.orange.shade900,
                      Colors.orange.shade50,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRegimenPill(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
