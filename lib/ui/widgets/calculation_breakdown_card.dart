import 'package:flutter/material.dart';

import '../../core/models/transparent_calculation_result.dart';

/// Pillar 3 Widget: Calculation Breakdown Accordion.
///
/// Displays the line-by-line mathematical substitution (`calculationSteps`),
/// exact vs practical volume comparison (using `practicalVolumeDecimalsUsed`
/// so `< 1.0 mL` volumes show `0.01 mL` precision), delivered dose rounding
/// discrepancy, and recommended dispensing device.
class CalculationBreakdownCard extends StatelessWidget {
  final TransparentCalculationResult result;
  final bool initiallyExpanded;

  const CalculationBreakdownCard({
    super.key,
    required this.result,
    this.initiallyExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final volDec = result.practicalVolumeDecimalsUsed;

    return Card(
      key: const Key('calculation_breakdown_card'),
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
      ),
      color: Colors.white,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: const Key('calculation_breakdown_accordion'),
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.calculate_outlined,
              color: Color(0xFF1D4ED8),
            ),
          ),
          title: const Text(
            'แสดงวิธีคิดและแทนค่าในสมการทีละบรรทัด (Step-by-Step Breakdown)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF1E3A8A),
            ),
          ),
          subtitle: Text(
            'สมการ: ${result.formulaUsed}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
          ),
          children: [
            const Divider(color: Color(0xFFE2E8F0)),
            const SizedBox(height: 8),
            // Input Summary Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                'ข้อมูลผู้ป่วยตั้งต้น (Input Summary): ${result.inputSummary.toFormattedString()}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Step-by-Step Lines
            ...result.calculationSteps.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final stepText = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$idx',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        stepText,
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.4,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            // Exact vs Practical Volume & Rounding Discrepancy Summary Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ตารางเปรียบเทียบความแม่นยำเชิงปริมาตร (Exact vs Practical Syringe Volume):',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF166534),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '• โดสตามน้ำหนักจริง (Raw Single Dose): ${result.rawCalculatedSingleDoseMg.toStringAsFixed(2)} mg/ครั้ง '
                    '| โดสแนะนำหลังเทียบเพดาน (Final Dose): ${result.finalRecommendedSingleDoseMg.toStringAsFixed(2)} mg/ครั้ง',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• ปริมาตรตามสมการเป๊ะ (Exact Volume): ${result.exactVolumeMl.toStringAsFixed(4)} mL '
                    '| ปริมาตรตวงจริง (${result.roundingRuleUsed}, $volDec ตำแหน่ง): ${result.practicalVolumeMl.toStringAsFixed(volDec)} mL',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• เนื้อยาที่ได้รับจริงเมื่อตวง ${result.practicalVolumeMl.toStringAsFixed(volDec)} mL: '
                    '${result.actualDeliveredSingleDoseMg.toStringAsFixed(2)} mg '
                    '(ส่วนต่างจากการปัดเศษ: ${result.roundingDiscrepancyMg >= 0 ? "+" : ""}${result.roundingDiscrepancyMg.toStringAsFixed(2)} mg '
                    'หรือ ${result.roundingDiscrepancyPercent >= 0 ? "+" : ""}${result.roundingDiscrepancyPercent.toStringAsFixed(2)}%)',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• อุปกรณ์ตวงยาที่แนะนำ: ${result.dispensingDeviceRecommendation}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF14532D),
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
