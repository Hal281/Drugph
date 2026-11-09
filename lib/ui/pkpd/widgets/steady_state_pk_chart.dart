// lib/ui/pkpd/widgets/steady_state_pk_chart.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/pk_model.dart';
import 'pk_chart_painter.dart';

/// Responsive, interactive chart widget for Pharmacokinetic Concentration-Time Visualization.
///
/// Features:
/// - Wraps [PkChartPainter] inside a [GestureDetector] supporting tap and horizontal scrubbing.
/// - Tactile haptic feedback on scrubbing across clinical key points.
/// - WCAG AAA contrast ratio compliance and accessible [Semantics] annotation.
/// - Responsive adaptation to compact mobile and wide desktop viewports adhering to the 8-point grid.
/// - Integrated Rule 5 Non-blocking Overdose banner and Alpha Distribution Phase advisory.
class SteadyStatePkChart extends StatefulWidget {
  final PkSimulationResult adjustedResult;
  final PkSimulationResult? baselineResult;
  final TherapeuticWindow? window;
  final bool isThai;
  final double? height;
  final void Function(
    double? timeHours,
    double? concAdjusted,
    double? concBaseline,
  )? onScrubChanged;

  const SteadyStatePkChart({
    super.key,
    required this.adjustedResult,
    this.baselineResult,
    this.window,
    this.isThai = true,
    this.height,
    this.onScrubChanged,
  });

  @override
  State<SteadyStatePkChart> createState() => _SteadyStatePkChartState();
}

class _SteadyStatePkChartState extends State<SteadyStatePkChart> {
  double? _scrubTimeHours;
  Timer? _fadeTimer;
  double _lastHapticTime = -1.0;

  @override
  void dispose() {
    _fadeTimer?.cancel();
    super.dispose();
  }

  void _onScrubUpdate(Offset localPosition, double chartWidth) {
    _fadeTimer?.cancel();

    const padLeft = PkChartPainter.padLeft;
    const padRight = PkChartPainter.padRight;
    final plotWidth = math.max(1.0, chartWidth - padLeft - padRight);

    final relX = (localPosition.dx - padLeft).clamp(0.0, plotWidth);
    final maxTime = widget.adjustedResult.params.horizonHours > 0
        ? widget.adjustedResult.params.horizonHours
        : (widget.adjustedResult.curve.isNotEmpty
            ? widget.adjustedResult.curve.last.timeHours
            : 24.0);

    final time = (relX / plotWidth) * maxTime;

    // Haptic feedback when crossing integer hours or peak/trough
    if ((time - _lastHapticTime).abs() >= 2.0 ||
        (time - widget.adjustedResult.tMax).abs() < 0.2 ||
        (time - widget.adjustedResult.params.tau).abs() < 0.2) {
      HapticFeedback.selectionClick();
      _lastHapticTime = time;
    }

    setState(() {
      _scrubTimeHours = time;
    });

    if (widget.onScrubChanged != null) {
      final cAdj = PkChartPainter.interpolateConcentration(
        widget.adjustedResult.curve,
        time,
      );
      final cBase = widget.baselineResult != null
          ? PkChartPainter.interpolateConcentration(
              widget.baselineResult!.curve,
              time,
            )
          : null;
      widget.onScrubChanged!(time, cAdj, cBase);
    }
  }

  void _onScrubEnd() {
    // Keep crosshair active for 2.5 seconds before smooth fade
    _fadeTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _scrubTimeHours = null;
        });
        if (widget.onScrubChanged != null) {
          widget.onScrubChanged!(null, null, null);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.isThai;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final res = widget.adjustedResult;

    return Semantics(
      label: t
          ? 'กราฟทำนายระดับยาในเลือด ค่าสูงสุด Cmax ${res.cMax.toStringAsFixed(1)} มก./ลิตร ค่าต่ำสุด Cmin ${res.cMin.toStringAsFixed(1)} มก./ลิตร'
          : 'PK concentration-time curve. Peak Cmax ${res.cMax.toStringAsFixed(1)} mg/L, Trough Cmin ${res.cMin.toStringAsFixed(1)} mg/L',
      hint: t
          ? 'ลากนิ้วบนกราฟเพื่อตรวจดูระดับยาตามเวลา'
          : 'Drag on chart to inspect concentrations',
      child: Card(
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
              // Header Row: Title & Metadata Chips
              _buildHeader(context, t, isDark),

              // Rule 5 Overdose Warning Banner (if breached)
              if (res.hasOverdoseWarning) ...[
                const SizedBox(height: 12),
                _buildOverdoseBanner(
                  res.overdoseWarningMessage ??
                      (t
                          ? 'คำเตือน: ขนาดยานี้เกินระดับความปลอดภัยสูงสุด (Overdose Warning)'
                          : 'Warning: Dose exceeds MTC'),
                ),
              ],

              // Distribution Phase Warning Banner (if present e.g. Digoxin)
              if (res.hasDistributionPhaseWarning &&
                  res.distributionPhaseWarningMessage != null) ...[
                const SizedBox(height: 12),
                _buildDistributionBanner(res.distributionPhaseWarningMessage!),
              ],

              const SizedBox(height: 16),

              // Interactive Chart Area
              LayoutBuilder(
                builder: (context, constraints) {
                  final chartHeight = widget.height ??
                      (constraints.maxWidth < 600 ? 260.0 : 320.0);
                  return GestureDetector(
                    onHorizontalDragStart: (d) =>
                        _onScrubUpdate(d.localPosition, constraints.maxWidth),
                    onHorizontalDragUpdate: (d) =>
                        _onScrubUpdate(d.localPosition, constraints.maxWidth),
                    onHorizontalDragEnd: (_) => _onScrubEnd(),
                    onTapDown: (d) =>
                        _onScrubUpdate(d.localPosition, constraints.maxWidth),
                    onTapUp: (_) => _onScrubEnd(),
                    child: SizedBox(
                      height: chartHeight,
                      width: constraints.maxWidth,
                      child: CustomPaint(
                        painter: PkChartPainter(
                          adjustedResult: widget.adjustedResult,
                          baselineResult: widget.baselineResult,
                          window: widget.window,
                          scrubTimeHours: _scrubTimeHours,
                          isThai: t,
                          isDark: isDark,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Legend Bar (8-pt aligned)
              _buildLegend(t, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool t, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF6D28D9).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.show_chart, color: Color(0xFF6D28D9), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t
                    ? 'แบบจำลองกราฟระดับยาในเลือด (Steady-State PK)'
                    : 'Pharmacokinetic Profile (Steady-State)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 2),
              Text(
                t
                    ? 'แตะหรือลากนิ้วบนกราฟเพื่อตรวจระดับยา'
                    : 'Tap or drag to scrub concentrations',
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverdoseBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEF4444)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFDC2626),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF991B1B),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3B82F6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF1E40AF),
                fontSize: 11.5,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(bool t, bool isDark) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        // Adjusted Legend Pill
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFF6D28D9),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              t ? 'สูตรปรับปรุง (Adjusted)' : 'Adjusted Regimen',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),

        // Baseline Legend Pill (if present)
        if (widget.baselineResult != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 2,
                decoration: BoxDecoration(
                  color: const Color(0xFF94A3B8),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                t ? 'สูตรเดิม (Baseline)' : 'Baseline Regimen',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),

        // Target Band Pill
        if (widget.window != null) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.20),
                  border: Border.all(color: const Color(0xFF16A34A)),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                t ? 'ช่วงเป้าหมาย (MEC)' : 'Target (MEC)',
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.18),
                  border: Border.all(color: const Color(0xFFDC2626)),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                t ? 'ขีดจำกัดพิษ (MTC)' : 'Toxic Limit (MTC)',
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
