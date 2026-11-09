import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/models/dosage_result.dart';
import '../../core/models/drug.dart';
import '../../core/models/patient.dart';
import '../../core/models/pk_model.dart';
import 'controllers/pk_simulation_controller.dart';
import 'widgets/pk_data_table.dart';
import 'widgets/pk_parameter_sliders.dart';
import 'widgets/steady_state_pk_chart.dart';

enum PkViewMode { chart, table }

/// Comprehensive modal simulation sheet for pharmacokinetic and pharmacodynamic modeling.
///
/// Features:
/// - Responsive modal: Wide desktop centered dialog vs mobile draggable bottom sheet.
/// - Live dual-mode toggle: Visual Interactive Curve (Canvas) vs Accessible Data Table (WCAG AAA).
/// - Dynamic Baseline vs Adjusted comparison metrics card.
/// - Real-time parameter sliders with Vancomycin Red Man Syndrome safety logic.
class PkPdSimulationSheet extends StatefulWidget {
  final Drug drug;
  final DosingRegimen regimen;
  final DosageResult? result;
  final Patient patient;
  final bool isThai;
  final PkSimulationRunner? runner;

  const PkPdSimulationSheet({
    super.key,
    required this.drug,
    required this.regimen,
    this.result,
    required this.patient,
    this.isThai = true,
    this.runner,
  });

  /// Opens the PK-PD simulation sheet adaptively according to viewport width.
  static Future<void> show(
    BuildContext context, {
    required Drug drug,
    required DosingRegimen regimen,
    DosageResult? result,
    required Patient patient,
    bool isThai = true,
    PkSimulationRunner? runner,
  }) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    if (isDesktop) {
      return showDialog(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960, maxHeight: 880),
            child: PkPdSimulationSheet(
              drug: drug,
              regimen: regimen,
              result: result,
              patient: patient,
              isThai: isThai,
              runner: runner,
            ),
          ),
        ),
      );
    } else {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.90,
          minChildSize: 0.50,
          maxChildSize: 0.96,
          builder: (_, scrollController) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: PkPdSimulationSheet(
              drug: drug,
              regimen: regimen,
              result: result,
              patient: patient,
              isThai: isThai,
              runner: runner,
            ),
          ),
        ),
      );
    }
  }

  @override
  State<PkPdSimulationSheet> createState() => _PkPdSimulationSheetState();
}

class _PkPdSimulationSheetState extends State<PkPdSimulationSheet> {
  late final PkSimulationController _controller;
  PkViewMode _activeViewMode = PkViewMode.chart;

  @override
  void initState() {
    super.initState();
    _controller = PkSimulationController(
      drug: widget.drug,
      patient: widget.patient,
      runner: widget.runner,
      initialParams: _buildInitialParams(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  PkSimulationParams? _buildInitialParams() {
    // If dosage result is available, extract calculated dose & tau if possible
    final res = widget.result;
    if (res == null) return null;

    final rDose = res.roundedDose;
    final cDose = res.calculatedDose;
    final double dose;
    if (rDose != null && rDose > 0) {
      dose = rDose;
    } else if (cDose != null && cDose > 0) {
      dose = cDose;
    } else {
      dose = 1000.0;
    }

    double tau = 12.0;
    final interval = widget.regimen.frequency.intervalHours;
    if (interval != null && interval > 0) {
      tau = interval.toDouble();
    }

    final isVanco = widget.drug.genericName.toLowerCase().contains('vancomycin') ||
        widget.drug.id.toLowerCase().contains('vancomycin');

    final crcl = widget.patient.creatinineClearanceMlMin ?? 65.0;
    final vd = isVanco ? 0.7 * widget.patient.weightKg : 0.7 * widget.patient.weightKg;
    final ke = isVanco ? (0.00083 * crcl + 0.0044) : (0.00083 * crcl + 0.0044);

    final window = isVanco
        ? const TherapeuticWindow(
            mec: 10.0,
            mtc: 20.0,
            targetTroughMin: 10.0,
            targetTroughMax: 20.0,
            targetAuc24Min: 400.0,
            targetAuc24Max: 600.0,
          )
        : const TherapeuticWindow(mec: 10.0, mtc: 25.0);

    return PkSimulationParams(
      modelType: PkModelType.oneCompartment,
      route: AdministrationRoute.ivIntermittentInfusion,
      dose: dose > 0 ? dose : 1000.0,
      tau: tau,
      tInf: 1.0,
      pk1: PkParameters(vd: vd, ke: ke),
      therapeuticWindow: window,
      isSteadyState: true,
      horizonHours: math.max(24.0, 2 * tau),
      pointsPerPhase: 40,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.isThai;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final adjRes = _controller.adjustedResult;
        final baseRes = _controller.baselineResult;
        final comp = _controller.comparison;

        return Column(
          children: [
            // Drag Handle for bottom sheet
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6D28D9).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.show_chart_rounded, color: Color(0xFF6D28D9), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t
                              ? 'แบบจำลอง PK-PD: ${widget.drug.genericName}'
                              : 'PK-PD Modeling: ${widget.drug.genericName}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          t
                              ? 'น้ำหนัก ${widget.patient.weightKg.toStringAsFixed(1)} kg | CrCl ${_controller.clearanceMlMin.toStringAsFixed(0)} mL/min'
                              : 'Wt ${widget.patient.weightKg.toStringAsFixed(1)} kg | CrCl ${_controller.clearanceMlMin.toStringAsFixed(0)} mL/min',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Mode Toggle (SegmentedButton)
                    Center(
                      child: SegmentedButton<PkViewMode>(
                        key: const Key('pkpd_view_mode_segmented_btn'),
                        segments: [
                          ButtonSegment(
                            value: PkViewMode.chart,
                            label: Text(t ? '📊 กราฟเส้น (Visual Curve)' : '📊 Visual Curve'),
                            icon: const Icon(Icons.show_chart_rounded),
                          ),
                          ButtonSegment(
                            value: PkViewMode.table,
                            label: Text(t ? '📋 ตารางข้อมูล (Data Table)' : '📋 Data Table'),
                            icon: const Icon(Icons.table_rows_rounded),
                          ),
                        ],
                        selected: {_activeViewMode},
                        onSelectionChanged: (set) {
                          setState(() {
                            _activeViewMode = set.first;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Live Comparison Metrics Banner
                    if (comp != null && adjRes != null)
                      _buildComparisonMetricsCard(comp, adjRes, t, isDark),

                    const SizedBox(height: 16),

                    // Visualization Area (Chart or Table)
                    if (adjRes != null) ...[
                      if (_activeViewMode == PkViewMode.chart)
                        SteadyStatePkChart(
                          adjustedResult: adjRes,
                          baselineResult: baseRes,
                          window: _controller.currentParams.therapeuticWindow,
                          isThai: t,
                          onScrubChanged: (time, adj, base) {
                            _controller.setScrubberTime(time);
                          },
                        )
                      else
                        PkDataTable(
                          adjustedResult: adjRes,
                          baselineResult: baseRes,
                          therapeuticWindow: _controller.currentParams.therapeuticWindow,
                          isThai: t,
                          highlightedTimeHours: _controller.scrubberTimeHours,
                          onRowSelected: (time) {
                            _controller.setScrubberTime(time);
                          },
                        ),
                    ] else if (_controller.isLoading) ...[
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Parameter Sliders
                    PkParameterSliders(
                      crclMlMin: _controller.clearanceMlMin,
                      baselineCrclMlMin: _controller.baselineParams.pk1?.ke != null
                          ? ((_controller.baselineParams.pk1!.ke - 0.0044) / 0.00083).clamp(10.0, 150.0)
                          : 65.0,
                      currentDoseMg: _controller.doseMg,
                      baselineDoseMg: _controller.baselineParams.dose,
                      currentTauHours: _controller.tauHours,
                      baselineTauHours: _controller.baselineParams.tau,
                      currentTInfHours: _controller.tInfHours,
                      baselineTInfHours: _controller.baselineParams.tInf,
                      drug: widget.drug,
                      isThai: t,
                      onCrclChanged: _controller.updateClearance,
                      onDoseChanged: _controller.updateDose,
                      onTauChanged: _controller.updateInterval,
                      onTInfChanged: _controller.updateInfusionDuration,
                      onResetToBaseline: _controller.resetToBaseline,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildComparisonMetricsCard(
    PkSimulationComparison comp,
    PkSimulationResult adj,
    bool t,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t ? 'สรุปผลการเปรียบเทียบขนาดยา (Regimen Comparison)' : 'Regimen Comparison Summary',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              _buildTargetBadge(adj, t),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Cmax',
                  value: '${adj.cMax.toStringAsFixed(1)} mg/L',
                  deltaPct: comp.percentChangeCMax,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Cmin (Trough)',
                  value: '${adj.cMin.toStringAsFixed(1)} mg/L',
                  deltaPct: comp.percentChangeCMin,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'AUC24',
                  value: adj.auc0To24.toStringAsFixed(0),
                  deltaPct: comp.percentChangeAuc24,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required double deltaPct,
    required bool isDark,
  }) {
    final hasDelta = deltaPct.abs() >= 0.1;
    final isIncrease = deltaPct > 0;
    final deltaText = hasDelta
        ? '${isIncrease ? "+" : ""}${deltaPct.toStringAsFixed(1)}%'
        : '0.0%';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            deltaText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: !hasDelta
                  ? (isDark ? Colors.white54 : Colors.black54)
                  : (isIncrease ? const Color(0xFF14532D) : const Color(0xFF7F1D1D)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetBadge(PkSimulationResult res, bool t) {
    final win = _controller.currentParams.therapeuticWindow;
    if (win == null) return const SizedBox.shrink();

    final isToxic = res.cMin > win.mtc || res.cMax > win.mtc;
    final isSub = res.cMin < win.mec;

    if (isToxic) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFB91C1C)),
        ),
        child: Text(
          t ? '⚠️ เสี่ยงพิษ (Toxic)' : '⚠️ Toxic Risk',
          style: const TextStyle(
            color: Color(0xFF7F1D1D),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (isSub) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFB45309)),
        ),
        child: Text(
          t ? '⚠️ ต่ำกว่าเกณฑ์' : '⚠️ Sub-therapeutic',
          style: const TextStyle(
            color: Color(0xFF451A03),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF15803D)),
        ),
        child: Text(
          t ? '✓ ในช่วงเป้าหมาย' : '✓ In Target Window',
          style: const TextStyle(
            color: Color(0xFF052E16),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }
}
