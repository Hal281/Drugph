import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../../theme/app_theme.dart';

/// Compact clinical side-effects summary card displaying Top 3 Common and
/// Top 3 Serious ("Watch For") adverse effects immediately below the dose
/// output card, with expand/collapse toggle when additional entries exist
/// (FB-16 / WP-11).
class SideEffectsSummaryCard extends StatefulWidget {
  final Drug drug;
  final bool isThai;

  const SideEffectsSummaryCard({
    super.key,
    required this.drug,
    required this.isThai,
  });

  @override
  State<SideEffectsSummaryCard> createState() => _SideEffectsSummaryCardState();
}

class _SideEffectsSummaryCardState extends State<SideEffectsSummaryCard> {
  static const int _compactCount = 3;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.drug.hasSideEffectData) {
      return const SizedBox.shrink();
    }

    final t = widget.isThai;
    final commonList = t
        ? (widget.drug.sideEffectsTh.isNotEmpty
            ? widget.drug.sideEffectsTh
            : widget.drug.sideEffects)
        : widget.drug.sideEffects;
    final seriousList = t
        ? (widget.drug.seriousSideEffectsTh.isNotEmpty
            ? widget.drug.seriousSideEffectsTh
            : widget.drug.seriousSideEffects)
        : widget.drug.seriousSideEffects;

    if (commonList.isEmpty && seriousList.isEmpty) {
      return const SizedBox.shrink();
    }

    final hasMore = commonList.length > _compactCount ||
        seriousList.length > _compactCount;
    final visibleCommon =
        _expanded ? commonList : commonList.take(_compactCount).toList();
    final visibleSerious =
        _expanded ? seriousList : seriousList.take(_compactCount).toList();

    return Card(
      key: const Key('calculator_side_effects_card'),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.borderDefault),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.health_and_safety_outlined,
                  color: AppTheme.primaryTeal,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t
                        ? 'ผลข้างเคียงและอาการต้องเฝ้าระวัง (Side Effects)'
                        : 'Side Effects & Safety Monitoring',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.inkPrimary,
                    ),
                  ),
                ),
              ],
            ),
            if (visibleCommon.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderDefault),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t ? 'พบบ่อย (Common)' : 'Common Side Effects',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.inkPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...visibleCommon.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '• $item',
                          style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: AppTheme.inkSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (visibleSerious.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.statusCriticalBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.statusCriticalBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.report_problem_outlined,
                          size: 16,
                          color: AppTheme.statusCritical,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            t
                                ? 'รุนแรง / อาการต้องเฝ้าระวัง (Watch For)'
                                : 'Serious / Watch For',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF991B1B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ...visibleSerious.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '• $item',
                          style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: Color(0xFF991B1B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (hasMore) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  key: const Key('side_effects_expand_toggle'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    foregroundColor: AppTheme.primaryTeal,
                  ),
                  onPressed: () => setState(() => _expanded = !_expanded),
                  icon: Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                  ),
                  label: Text(
                    _expanded
                        ? (t ? 'แสดงน้อยลง' : 'Show less')
                        : (t ? 'ดูผลข้างเคียงทั้งหมด' : 'Show all side effects'),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
