// lib/ui/pkpd/widgets/pk_chart_painter.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/models/pk_model.dart';

/// Canvas CustomPainter rendering high-resolution pharmacokinetic concentration-time curves.
///
/// Features:
/// - Multi-band clinical shading: MTC (toxic crimson), MEC (therapeutic target emerald), Sub-therapeutic (amber).
/// - Dual curve comparison: Baseline regimen (dashed slate grey) vs Adjusted regimen (solid vibrant violet + gradient).
/// - Dynamic Y-axis scale calculation with 15% headroom and clean tick divisors.
/// - Cmax and Cmin callout badges with boundary-safe clamping and target validation colors.
/// - Interactive crosshair scrubber: vertical dashed line, curve intersection rings, and floating tooltip pill.
class PkChartPainter extends CustomPainter {
  final PkSimulationResult adjustedResult;
  final PkSimulationResult? baselineResult;
  final TherapeuticWindow? window;
  final double? scrubTimeHours;
  final bool isThai;
  final bool isDark;

  // 8-pt aligned padding constants
  static const double padLeft = 48.0;
  static const double padRight = 24.0;
  static const double padTop = 28.0;
  static const double padBottom = 36.0;

  const PkChartPainter({
    required this.adjustedResult,
    this.baselineResult,
    this.window,
    this.scrubTimeHours,
    this.isThai = true,
    this.isDark = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final plotWidth = math.max(1.0, size.width - padLeft - padRight);
    final plotHeight = math.max(1.0, size.height - padTop - padBottom);
    final plotRect = Rect.fromLTWH(padLeft, padTop, plotWidth, plotHeight);

    if (adjustedResult.curve.isEmpty) {
      _drawEmptyState(canvas, plotRect);
      return;
    }

    final maxTime = _calculateMaxTime();
    final yMax = _calculateYMax();

    double xForTime(double t) =>
        plotRect.left + (t.clamp(0.0, maxTime) / maxTime) * plotWidth;

    double yForConc(double c) =>
        plotRect.bottom - (c.clamp(0.0, yMax) / yMax) * plotHeight;

    // 1. Draw rounded plot background
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    canvas.drawRRect(
      RRect.fromRectAndRadius(plotRect, const Radius.circular(8)),
      bgPaint,
    );

    // 2. Draw multi-band clinical shading
    _drawClinicalBands(canvas, plotRect, yForConc, yMax);

    // 3. Draw grid lines and axis ticks
    _drawGridAndAxes(canvas, plotRect, maxTime, yMax, xForTime, yForConc);

    // 4. Draw dual regimen curves (Baseline & Adjusted)
    _drawRegimenCurves(canvas, plotRect, xForTime, yForConc);

    // 5. Draw Cmax and Cmin callout badges
    _drawKeyPointBadges(canvas, plotRect, xForTime, yForConc);

    // 6. Draw interactive touch crosshair scrubber
    if (scrubTimeHours != null) {
      _drawCrosshairScrubber(canvas, plotRect, maxTime, xForTime, yForConc);
    }

    // 7. Draw plot border
    final borderPaint = Paint()
      ..color = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(plotRect, const Radius.circular(8)),
      borderPaint,
    );

    // 8. Draw unit header ("mg/L")
    _drawText(
      canvas,
      'mg/L',
      const Offset(6, 6),
      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
      fontSize: 10,
      bold: true,
    );
  }

  double _calculateMaxTime() {
    if (adjustedResult.params.horizonHours > 0) {
      return adjustedResult.params.horizonHours;
    }
    if (adjustedResult.curve.isNotEmpty) {
      return adjustedResult.curve.last.timeHours;
    }
    return 24.0;
  }

  double _calculateYMax() {
    double peak = math.max(adjustedResult.cMax, baselineResult?.cMax ?? 0.0);
    if (window != null) {
      peak = math.max(peak, window!.mtc);
      if (window!.targetPeakMax != null) {
        peak = math.max(peak, window!.targetPeakMax!);
      }
    }
    if (peak <= 0.0) return 10.0;
    final rawMax = peak * 1.15; // 15% clinical headroom
    if (rawMax <= 2.0) return (rawMax / 0.5).ceil() * 0.5;
    if (rawMax <= 10.0) return (rawMax / 2.0).ceil() * 2.0;
    if (rawMax <= 50.0) return (rawMax / 10.0).ceil() * 10.0;
    if (rawMax <= 200.0) return (rawMax / 25.0).ceil() * 25.0;
    return (rawMax / 50.0).ceil() * 50.0;
  }

  void _drawClinicalBands(
    Canvas canvas,
    Rect plotRect,
    double Function(double) yForConc,
    double yMax,
  ) {
    if (window == null) return;
    final w = window!;

    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(plotRect, const Radius.circular(8)));

    // A. MTC Toxic Zone (Crimson Color(0x1FDC2626))
    if (w.mtc > 0 && w.mtc < yMax) {
      final yMtc = yForConc(w.mtc);
      final mtcRect = Rect.fromLTRB(plotRect.left, plotRect.top, plotRect.right, yMtc);
      final mtcPaint = Paint()..color = const Color(0x1FDC2626);
      canvas.drawRect(mtcRect, mtcPaint);

      // Dashed boundary line
      final linePaint = Paint()
        ..color = const Color(0xFFDC2626).withValues(alpha: 0.70)
        ..strokeWidth = 1.4;
      _drawDashedLine(canvas, Offset(plotRect.left, yMtc), Offset(plotRect.right, yMtc), linePaint);

      _drawText(
        canvas,
        isThai
            ? 'MTC ขีดจำกัดพิษ (${w.mtc.toStringAsFixed(1)})'
            : 'MTC Toxic (${w.mtc.toStringAsFixed(1)})',
        Offset(plotRect.right - 6, yMtc - 14),
        alignRight: true,
        color: const Color(0xFFDC2626),
        fontSize: 9.5,
        bold: true,
      );
    }

    // B. MEC Therapeutic Target Band (Emerald Color(0x2416A34A))
    if (w.mec > 0 && w.mec < yMax) {
      final yMtc = w.mtc < yMax ? yForConc(w.mtc) : plotRect.top;
      final yMec = yForConc(w.mec);
      final mecRect = Rect.fromLTRB(plotRect.left, yMtc, plotRect.right, yMec);
      final mecPaint = Paint()..color = const Color(0x2416A34A);
      canvas.drawRect(mecRect, mecPaint);

      final mecLinePaint = Paint()
        ..color = const Color(0xFF16A34A).withValues(alpha: 0.65)
        ..strokeWidth = 1.2;
      canvas.drawLine(Offset(plotRect.left, yMec), Offset(plotRect.right, yMec), mecLinePaint);

      _drawText(
        canvas,
        isThai
            ? 'MEC เป้าหมาย (${w.mec.toStringAsFixed(1)})'
            : 'MEC Target (${w.mec.toStringAsFixed(1)})',
        Offset(plotRect.right - 6, yMec - 14),
        alignRight: true,
        color: const Color(0xFF16A34A),
        fontSize: 9.5,
        bold: true,
      );
    }

    // C. Sub-therapeutic Zone (Neutral amber tint Color(0xFFF59E0B) alpha 0.04)
    if (w.mec > 0) {
      final yMec = yForConc(w.mec);
      final subRect = Rect.fromLTRB(plotRect.left, yMec, plotRect.right, plotRect.bottom);
      final subPaint = Paint()..color = const Color(0xFFF59E0B).withValues(alpha: 0.04);
      canvas.drawRect(subRect, subPaint);
    }

    canvas.restore();
  }

  void _drawGridAndAxes(
    Canvas canvas,
    Rect plotRect,
    double maxTime,
    double yMax,
    double Function(double) xForTime,
    double Function(double) yForConc,
  ) {
    final gridPaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0;

    // 5 Horizontal Grid Lines & numeric labels
    const yTicks = 5;
    for (var i = 0; i <= yTicks; i++) {
      final conc = (yMax / yTicks) * i;
      final y = yForConc(conc);
      canvas.drawLine(Offset(plotRect.left, y), Offset(plotRect.right, y), gridPaint);
      _drawText(
        canvas,
        conc >= 10 ? conc.toStringAsFixed(0) : conc.toStringAsFixed(1),
        Offset(plotRect.left - 6, y - 6),
        alignRight: true,
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        fontSize: 9.5,
      );
    }

    // Vertical Time Grid Lines
    final timeStep = maxTime <= 12
        ? 2.0
        : (maxTime <= 24 ? 4.0 : (maxTime <= 48 ? 8.0 : 12.0));
    for (double t = 0; t <= maxTime + 1e-6; t += timeStep) {
      final x = xForTime(t);
      canvas.drawLine(Offset(x, plotRect.top), Offset(x, plotRect.bottom), gridPaint);
      _drawText(
        canvas,
        '${t.toInt()}h',
        Offset(x, plotRect.bottom + 6),
        alignCenter: true,
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        fontSize: 9.5,
      );
    }

    // Time Axis Title
    _drawText(
      canvas,
      isThai ? 'เวลา (ชม.)' : 'Time (hr)',
      Offset(plotRect.right, plotRect.bottom + 20),
      alignRight: true,
      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
      fontSize: 9.0,
      bold: true,
    );
  }

  void _drawRegimenCurves(
    Canvas canvas,
    Rect plotRect,
    double Function(double) xForTime,
    double Function(double) yForConc,
  ) {
    // A. Baseline Regimen (Dashed slate grey Color(0xFF94A3B8))
    if (baselineResult != null && baselineResult!.curve.isNotEmpty) {
      final basePath = Path();
      final basePoints = baselineResult!.curve;
      for (var i = 0; i < basePoints.length; i++) {
        final x = xForTime(basePoints[i].timeHours);
        final y = yForConc(basePoints[i].concentrationMgL);
        if (i == 0) {
          basePath.moveTo(x, y);
        } else {
          basePath.lineTo(x, y);
        }
      }
      final basePaint = Paint()
        ..color = const Color(0xFF94A3B8)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      _drawDashedPath(canvas, basePath, basePaint, dashWidth: 6.0, dashSpace: 4.0);
    }

    // B. Adjusted Regimen (Solid vibrant violet Color(0xFF6D28D9) with gradient fill)
    final adjPoints = adjustedResult.curve;
    if (adjPoints.isNotEmpty) {
      final curvePath = Path();
      final areaPath = Path();

      for (var i = 0; i < adjPoints.length; i++) {
        final x = xForTime(adjPoints[i].timeHours);
        final y = yForConc(adjPoints[i].concentrationMgL);
        if (i == 0) {
          curvePath.moveTo(x, y);
          areaPath.moveTo(x, plotRect.bottom);
          areaPath.lineTo(x, y);
        } else {
          curvePath.lineTo(x, y);
          areaPath.lineTo(x, y);
        }
      }
      areaPath.lineTo(xForTime(adjPoints.last.timeHours), plotRect.bottom);
      areaPath.close();

      // Under-curve gradient fill
      final areaPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF7C3AED).withValues(alpha: 0.25),
            const Color(0xFF7C3AED).withValues(alpha: 0.02),
          ],
        ).createShader(plotRect);
      canvas.drawPath(areaPath, areaPaint);

      // Curve solid stroke
      final curvePaint = Paint()
        ..color = const Color(0xFF6D28D9)
        ..strokeWidth = 2.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(curvePath, curvePaint);
    }
  }

  void _drawKeyPointBadges(
    Canvas canvas,
    Rect plotRect,
    double Function(double) xForTime,
    double Function(double) yForConc,
  ) {
    // 1. Cmax Peak Badge
    final peakX = xForTime(adjustedResult.tMax);
    final peakY = yForConc(adjustedResult.cMax);
    final isOverdose = window != null && adjustedResult.cMax > window!.mtc;

    // Peak ring marker
    canvas.drawCircle(Offset(peakX, peakY), 4.5, Paint()..color = Colors.white);
    canvas.drawCircle(
      Offset(peakX, peakY),
      4.5,
      Paint()
        ..color = isOverdose ? const Color(0xFFDC2626) : const Color(0xFF312E81)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );

    _drawCalloutBadge(
      canvas,
      text: 'Cmax ${adjustedResult.cMax.toStringAsFixed(1)} mg/L',
      anchor: Offset(peakX, peakY),
      plotRect: plotRect,
      bgColor: isOverdose ? const Color(0xFFDC2626) : const Color(0xFF312E81),
      above: true,
    );

    // 2. Cmin Trough Badge
    final tau = adjustedResult.params.tau;
    final troughTime = tau > 0 ? tau : adjustedResult.curve.last.timeHours;
    final troughX = xForTime(troughTime);
    final troughY = yForConc(adjustedResult.cMin);

    Color troughColor = const Color(0xFF15803D); // Emerald default
    if (window != null) {
      if (adjustedResult.cMin > window!.mtc) {
        troughColor = const Color(0xFFDC2626); // Toxic
      } else if (adjustedResult.cMin < window!.mec) {
        troughColor = const Color(0xFFD97706); // Sub-therapeutic amber
      }
    }

    // Trough ring marker
    canvas.drawCircle(Offset(troughX, troughY), 4.5, Paint()..color = Colors.white);
    canvas.drawCircle(
      Offset(troughX, troughY),
      4.5,
      Paint()
        ..color = troughColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );

    _drawCalloutBadge(
      canvas,
      text: 'Cmin ${adjustedResult.cMin.toStringAsFixed(1)} mg/L',
      anchor: Offset(troughX, troughY),
      plotRect: plotRect,
      bgColor: troughColor,
      above: false,
    );
  }

  void _drawCrosshairScrubber(
    Canvas canvas,
    Rect plotRect,
    double maxTime,
    double Function(double) xForTime,
    double Function(double) yForConc,
  ) {
    final t = scrubTimeHours!.clamp(0.0, maxTime);
    final x = xForTime(t);

    // Vertical dashed crosshair line
    final linePaint = Paint()
      ..color = isDark ? Colors.white70 : const Color(0xFF0F172A)
      ..strokeWidth = 1.5;
    _drawDashedLine(
      canvas,
      Offset(x, plotRect.top),
      Offset(x, plotRect.bottom),
      linePaint,
      dashWidth: 4,
      dashSpace: 4,
    );

    // Interpolate concentrations
    final cAdj = interpolateConcentration(adjustedResult.curve, t);
    final yAdj = yForConc(cAdj);

    // Adjusted intersection ring
    canvas.drawCircle(
      Offset(x, yAdj),
      5.5,
      Paint()
        ..color = const Color(0xFF6D28D9)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(Offset(x, yAdj), 2.5, Paint()..color = Colors.white);

    double? cBase;
    if (baselineResult != null && baselineResult!.curve.isNotEmpty) {
      cBase = interpolateConcentration(baselineResult!.curve, t);
      final yBase = yForConc(cBase);
      canvas.drawCircle(
        Offset(x, yBase),
        4.5,
        Paint()
          ..color = const Color(0xFF94A3B8)
          ..strokeWidth = 1.8
          ..style = PaintingStyle.stroke,
      );
      canvas.drawCircle(Offset(x, yBase), 2.0, Paint()..color = Colors.white);
    }

    // Floating Tooltip Pill
    final timeStr = 't = ${t.toStringAsFixed(1)}h';
    final adjStr = isThai
        ? 'ปรับ: ${cAdj.toStringAsFixed(1)} mg/L'
        : 'Adj: ${cAdj.toStringAsFixed(1)} mg/L';
    String pillText = '$timeStr | $adjStr';
    if (cBase != null) {
      final baseStr = isThai
          ? 'เดิม: ${cBase.toStringAsFixed(1)} mg/L'
          : 'Base: ${cBase.toStringAsFixed(1)} mg/L';
      pillText += ' | $baseStr';
      if (cBase > 1e-6) {
        final delta = ((cAdj - cBase) / cBase) * 100.0;
        final deltaSign = delta >= 0 ? '+' : '';
        pillText += ' ($deltaSign${delta.toStringAsFixed(0)}%)';
      }
    }

    _drawFloatingPill(canvas, text: pillText, anchorX: x, plotRect: plotRect);
  }

  void _drawFloatingPill(
    Canvas canvas, {
    required String text,
    required double anchorX,
    required Rect plotRect,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    const padH = 8.0;
    const padV = 4.0;
    final boxW = tp.width + padH * 2;
    final boxH = tp.height + padV * 2;

    final left = (anchorX - boxW / 2).clamp(
      plotRect.left + 4,
      plotRect.right - boxW - 4,
    );
    final top = plotRect.top + 6.0;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, boxW, boxH),
      const Radius.circular(6),
    );
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF0F172A));
    tp.paint(canvas, Offset(left + padH, top + padV));
  }

  void _drawCalloutBadge(
    Canvas canvas, {
    required String text,
    required Offset anchor,
    required Rect plotRect,
    required Color bgColor,
    required bool above,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    const padH = 6.0;
    const padV = 3.0;
    final boxW = tp.width + padH * 2;
    final boxH = tp.height + padV * 2;

    final left = (anchor.dx - boxW / 2).clamp(
      plotRect.left + 2,
      plotRect.right - boxW - 2,
    );
    double top = above ? (anchor.dy - boxH - 7) : (anchor.dy + 7);
    top = top.clamp(plotRect.top + 2, plotRect.bottom - boxH - 2);

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, boxW, boxH),
      const Radius.circular(4),
    );
    canvas.drawRRect(rrect, Paint()..color = bgColor);
    tp.paint(canvas, Offset(left + padH, top + padV));
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset p1,
    Offset p2,
    Paint paint, {
    double dashWidth = 4.0,
    double dashSpace = 4.0,
  }) {
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    if (length <= 0) return;
    final unitX = dx / length;
    final unitY = dy / length;

    double dist = 0.0;
    while (dist < length) {
      final len = math.min(dashWidth, length - dist);
      canvas.drawLine(
        Offset(p1.dx + unitX * dist, p1.dy + unitY * dist),
        Offset(p1.dx + unitX * (dist + len), p1.dy + unitY * (dist + len)),
        paint,
      );
      dist += dashWidth + dashSpace;
    }
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint, {
    double dashWidth = 6.0,
    double dashSpace = 4.0,
  }) {
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final len = math.min(dashWidth, metric.length - distance);
        canvas.drawPath(metric.extractPath(distance, distance + len), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    bool alignRight = false,
    bool alignCenter = false,
    Color color = Colors.black87,
    double fontSize = 10,
    bool bold = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    double dx = offset.dx;
    if (alignRight) dx -= tp.width;
    if (alignCenter) dx -= tp.width / 2;
    tp.paint(canvas, Offset(dx, offset.dy));
  }

  void _drawEmptyState(Canvas canvas, Rect plotRect) {
    _drawText(
      canvas,
      isThai
          ? 'ไม่มีข้อมูลจุดกราฟสำหรับการจำลองนี้'
          : 'No simulation points available',
      plotRect.center,
      alignCenter: true,
      color: Colors.grey,
      fontSize: 12,
    );
  }

  /// O(log N) binary search curve interpolation on boundary-pinned curve points.
  static double interpolateConcentration(
    List<PkDataPoint> curve,
    double targetTime,
  ) {
    if (curve.isEmpty) return 0.0;
    if (targetTime <= curve.first.timeHours) return curve.first.concentrationMgL;
    if (targetTime >= curve.last.timeHours) return curve.last.concentrationMgL;

    int low = 0;
    int high = curve.length - 1;
    while (low <= high) {
      final mid = (low + high) >> 1;
      if (curve[mid].timeHours <= targetTime) {
        if (mid == curve.length - 1 || curve[mid + 1].timeHours > targetTime) {
          low = mid;
          break;
        }
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    final p1 = curve[low];
    final p2 = curve[math.min(low + 1, curve.length - 1)];
    final dt = p2.timeHours - p1.timeHours;
    if (dt.abs() < 1e-9) return p1.concentrationMgL;
    final frac = (targetTime - p1.timeHours) / dt;
    return p1.concentrationMgL +
        frac * (p2.concentrationMgL - p1.concentrationMgL);
  }

  @override
  bool shouldRepaint(covariant PkChartPainter oldDelegate) {
    return oldDelegate.adjustedResult != adjustedResult ||
        oldDelegate.baselineResult != baselineResult ||
        oldDelegate.window != window ||
        oldDelegate.scrubTimeHours != scrubTimeHours ||
        oldDelegate.isThai != isThai ||
        oldDelegate.isDark != isDark;
  }
}
