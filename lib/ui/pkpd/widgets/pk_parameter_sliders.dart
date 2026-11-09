import 'package:flutter/material.dart';

import '../../../core/models/drug.dart';

/// Dynamic bedside parameter controls for interactive PK-PD simulation.
///
/// Features:
/// - Renal clearance slider (10–150 mL/min).
/// - Dose slider with optimistic feedback and quick presets.
/// - Dosing interval (tau) chips.
/// - Infusion duration (tInf) chips.
/// - Live Vancomycin Red Man Syndrome alert (>10 mg/min) with one-tap auto-adjustment.
/// - Reset to baseline action button.
class PkParameterSliders extends StatelessWidget {
  final double crclMlMin;
  final double baselineCrclMlMin;
  final double currentDoseMg;
  final double baselineDoseMg;
  final double currentTauHours;
  final double baselineTauHours;
  final double currentTInfHours;
  final double baselineTInfHours;
  final Drug drug;
  final bool isThai;
  final ValueChanged<double> onCrclChanged;
  final ValueChanged<double> onDoseChanged;
  final ValueChanged<double> onTauChanged;
  final ValueChanged<double> onTInfChanged;
  final VoidCallback onResetToBaseline;

  const PkParameterSliders({
    super.key,
    required this.crclMlMin,
    required this.baselineCrclMlMin,
    required this.currentDoseMg,
    required this.baselineDoseMg,
    required this.currentTauHours,
    required this.baselineTauHours,
    required this.currentTInfHours,
    required this.baselineTInfHours,
    required this.drug,
    this.isThai = true,
    required this.onCrclChanged,
    required this.onDoseChanged,
    required this.onTauChanged,
    required this.onTInfChanged,
    required this.onResetToBaseline,
  });

  @override
  Widget build(BuildContext context) {
    final t = isThai;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Red Man Syndrome evaluation for Vancomycin
    final double infusionRateMgPerMin = (currentTInfHours > 0)
        ? currentDoseMg / (currentTInfHours * 60.0)
        : 0.0;

    final bool isVancomycin = drug.id.toLowerCase().contains('vancomycin') ||
        drug.genericName.toLowerCase().contains('vancomycin');

    final bool hasRedManRisk = isVancomycin && infusionRateMgPerMin > 10.0;

    return Card(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with Reset Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.tune_rounded, color: Color(0xFF6D28D9), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t
                              ? 'แผงควบคุมและจำลองตัวแปรยา (Parameters)'
                              : 'Simulation Parameter Controls',
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  key: const Key('pk_sliders_reset_btn'),
                  icon: const Icon(Icons.restart_alt, size: 16),
                  label: Text(t ? 'คืนค่าเริ่มต้น' : 'Reset to Baseline'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  onPressed: onResetToBaseline,
                ),
              ],
            ),

            // Live Red Man Syndrome Warning Banner
            if (hasRedManRisk) ...[
              const SizedBox(height: 12),
              _buildRedManAlert(context, infusionRateMgPerMin, t),
            ],

            const SizedBox(height: 16),

            // 1. Renal Clearance (CrCl) Slider
            _buildSliderSection(
              title: t
                  ? 'การทำงานของไต / การกำจัดยา (CrCl mL/min)'
                  : 'Renal Clearance (CrCl mL/min)',
              value: crclMlMin,
              baselineValue: baselineCrclMlMin,
              min: 10.0,
              max: 150.0,
              divisions: 28,
              unit: 'mL/min',
              activeColor: const Color(0xFF0284C7),
              onChanged: onCrclChanged,
              isDark: isDark,
            ),

            const SizedBox(height: 16),

            // 2. Dose Slider
            _buildSliderSection(
              title: t ? 'ขนาดยาต่อครั้ง (Dose mg)' : 'Dose per Administration (mg)',
              value: currentDoseMg,
              baselineValue: baselineDoseMg,
              min: 250.0,
              max: 3000.0,
              divisions: 55,
              unit: 'mg',
              activeColor: const Color(0xFF6D28D9),
              onChanged: onDoseChanged,
              isDark: isDark,
            ),

            const SizedBox(height: 16),

            // 3. Dosing Interval (Tau) Chips
            Text(
              t ? 'ความถี่ในการให้ยา (Interval: tau)' : 'Dosing Interval (tau)',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [6.0, 8.0, 12.0, 24.0, 48.0].map((tau) {
                final isSelected = (currentTauHours - tau).abs() < 0.1;
                final isBaseline = (baselineTauHours - tau).abs() < 0.1;
                return ChoiceChip(
                  key: Key('pk_chip_tau_${tau.toInt()}h'),
                  label: Text('q${tau.toInt()}h${isBaseline ? " (เดิม)" : ""}'),
                  selected: isSelected,
                  selectedColor: const Color(0xFF6D28D9).withValues(alpha: 0.18),
                  onSelected: (_) => onTauChanged(tau),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // 4. Infusion Duration (tInf) Chips
            Text(
              t ? 'ระยะเวลาหยดยาเข้าหลอดเลือด (tInf)' : 'Infusion Duration (tInf)',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [0.5, 1.0, 1.5, 2.0, 3.0, 4.0].map((tInf) {
                final isSelected = (currentTInfHours - tInf).abs() < 0.1;
                final isBaseline = (baselineTInfHours - tInf).abs() < 0.1;
                return ChoiceChip(
                  key: Key('pk_chip_tinf_${tInf.toString().replaceAll('.', '_')}h'),
                  label: Text('${tInf.toStringAsFixed(1)} ชม.${isBaseline ? " (เดิม)" : ""}'),
                  selected: isSelected,
                  selectedColor: const Color(0xFF6D28D9).withValues(alpha: 0.18),
                  onSelected: (_) => onTInfChanged(tInf),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderSection({
    required String title,
    required double value,
    required double baselineValue,
    required double min,
    required double max,
    required int divisions,
    required String unit,
    required Color activeColor,
    required ValueChanged<double> onChanged,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: activeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${value.toStringAsFixed(value >= 10 ? 0 : 1)} $unit',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: activeColor,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            activeTrackColor: activeColor,
            thumbColor: activeColor,
            overlayColor: activeColor.withValues(alpha: 0.15),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildRedManAlert(
    BuildContext context,
    double infusionRateMgPerMin,
    bool t,
  ) {
    return Container(
      key: const Key('pk_red_man_syndrome_alert'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2), // Red 50
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFB91C1C), width: 1.5), // Red 700
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFF7F1D1D),
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t
                      ? '⚠️ คำเตือน: เสี่ยงเกิด Red Man Syndrome (Vancomycin Flushing)'
                      : '⚠️ CRITICAL ALERT: Red Man Syndrome Risk (Flushing / Hypotension)',
                  style: const TextStyle(
                    color: Color(0xFF7F1D1D), // Red 900 (Contrast > 11:1)
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t
                      ? 'อัตราการหยดยา ${infusionRateMgPerMin.toStringAsFixed(1)} mg/min เกินเกณฑ์สูงสุดที่ปลอดภัย (ห้ามเกิน 10 mg/min). '
                          'แนะนำให้ปรับระยะเวลาหยดยาเป็นอย่างน้อย ${(currentDoseMg / 10).ceil()} นาที (${(currentDoseMg / 600).toStringAsFixed(1)} ชม.)'
                      : 'Infusion rate of ${infusionRateMgPerMin.toStringAsFixed(1)} mg/min exceeds maximum safe ceiling (10 mg/min). '
                          'Minimum recommended duration is ${(currentDoseMg / 10).ceil()} min (${(currentDoseMg / 600).toStringAsFixed(1)} hr).',
                  style: const TextStyle(
                    color: Color(0xFF7F1D1D),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                // One-tap quick auto-fix button
                InkWell(
                  key: const Key('pk_red_man_auto_adjust_btn'),
                  onTap: () {
                    final safeHours = (currentDoseMg / 600.0).clamp(1.0, 4.0);
                    final snapped = (safeHours * 2).ceil() / 2.0;
                    onTInfChanged(snapped);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7F1D1D),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      t
                          ? '⏱️ ปรับระยะเวลาเป็น ${((currentDoseMg / 600.0 * 2).ceil() / 2.0).toStringAsFixed(1)} ชม. ทันที'
                          : '⏱️ Auto-adjust to ${((currentDoseMg / 600.0 * 2).ceil() / 2.0).toStringAsFixed(1)} hr',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
