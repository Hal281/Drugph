import 'package:flutter/material.dart';

/// Informational card explaining the clinical weight strategy (TBW, IBW, or AdjBW).
class DosingWeightLogicCard extends StatelessWidget {
  final String? label;
  final double? value;
  final String? reason;
  final Map<String, dynamic>? calculationInputs;
  final bool isThai;

  const DosingWeightLogicCard({
    super.key,
    required this.label,
    required this.value,
    this.reason,
    this.calculationInputs,
    required this.isThai,
  });

  String _resolveReason(bool t) {
    final localizedInputReason = t
        ? (calculationInputs?['crclWeightReasonTh'] as String?)
        : (calculationInputs?['crclWeightReasonEn'] as String?);
    final currentReason = reason ?? '';
    final expectedTh = 'ใช้ $label ในการคำนวณขนาดยาตามเกณฑ์คลินิก';
    final expectedEn =
        'Using $label for clinical regimen dosing calculation';

    if (t &&
        currentReason.startsWith('Using ') &&
        currentReason.endsWith('for clinical regimen dosing calculation')) {
      return expectedTh;
    }
    if (!t &&
        currentReason.startsWith('ใช้ ') &&
        currentReason.endsWith('ในการคำนวณขนาดยาตามเกณฑ์คลินิก')) {
      return expectedEn;
    }
    if (localizedInputReason != null &&
        localizedInputReason.isNotEmpty &&
        (currentReason == calculationInputs?['crclWeightReasonTh'] ||
            currentReason == calculationInputs?['crclWeightReasonEn'])) {
      return localizedInputReason;
    }
    return currentReason;
  }

  @override
  Widget build(BuildContext context) {
    if (label == null || value == null) {
      return const SizedBox.shrink();
    }

    final t = isThai;
    final resolvedReason = _resolveReason(t);

    return Card(
      color: Colors.blue.shade50,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.blue.shade200, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.monitor_weight,
              color: Colors.blue,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t
                        ? 'น้ำหนักที่ใช้คำนวณไต (Dosing Weight): $label'
                        : 'Renal Dosing Weight: $label',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${value!.toStringAsFixed(1)} kg - $resolvedReason',
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
