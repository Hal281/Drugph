import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../../theme/app_theme.dart';

/// IV Diluent Compatibility and Precipitation Safety Card.
///
/// Displays compact compatible/incompatible diluent chips at a glance while
/// always keeping critical red incompatibility warnings prominent. Verbose
/// stability notes and citations expand cleanly on tap (FB-17).
class IvDiluentCompatibilityCard extends StatefulWidget {
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
  State<IvDiluentCompatibilityCard> createState() =>
      _IvDiluentCompatibilityCardState();
}

class _IvDiluentCompatibilityCardState
    extends State<IvDiluentCompatibilityCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.isThai;
    final compat =
        widget.selectedRegimen.effectiveIvDiluentCompatibility(widget.drug);
    if (compat == null) return const SizedBox.shrink();

    final hasIncompatible = compat.incompatibleDiluents.isNotEmpty;
    final hasIncompatReason = compat.incompatibilityReasonEn != null ||
        compat.incompatibilityReasonTh != null;
    final hasStability =
        compat.stabilityNoteEn != null || compat.stabilityNoteTh != null;

    return Card(
      key: const Key('calculator_iv_diluent_card'),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hasIncompatible
              ? AppTheme.statusCriticalBorder
              : AppTheme.borderDefault,
        ),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.water_drop_outlined,
                    color: hasIncompatible
                        ? AppTheme.statusCritical
                        : AppTheme.primaryTeal,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t
                          ? 'สารน้ำผสมยา (IV Diluent Compatibility)'
                          : 'IV Diluent Compatibility',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.inkPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    fit: FlexFit.loose,
                    child: Text(
                      _isExpanded
                          ? (t ? 'ซ่อน' : 'Hide')
                          : (t ? 'ความคงตัว' : 'Stability'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryTeal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: AppTheme.primaryTeal,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ...compat.compatibleDiluents.map((d) {
                    final pref = compat.isPreferred(d);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTealSoft,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: pref
                              ? AppTheme.primaryTeal
                              : AppTheme.primaryTealBorder,
                          width: pref ? 1.2 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            pref ? Icons.star_rounded : Icons.check_circle_outline,
                            size: 14,
                            color: AppTheme.primaryTealDark,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              pref
                                  ? '${d.code} ✓ (${t ? "แนะนำ" : "Preferred"})'
                                  : '${d.code} ✓',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryTealDark,
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
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.statusCriticalBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppTheme.statusCritical,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.block_rounded,
                            size: 14,
                            color: AppTheme.statusCritical,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${t ? "ห้ามผสม" : "Avoid"} ${d.code}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.statusCritical,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
              if (hasIncompatReason) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.statusCriticalBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.statusCriticalBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: AppTheme.statusCritical,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t
                              ? (compat.incompatibilityReasonTh ??
                                  compat.incompatibilityReasonEn!)
                              : (compat.incompatibilityReasonEn ??
                                  compat.incompatibilityReasonTh!),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF991B1B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_isExpanded) ...[
                if (hasStability) ...[
                  const SizedBox(height: 10),
                  Text(
                    t
                        ? (compat.stabilityNoteTh ?? compat.stabilityNoteEn!)
                        : (compat.stabilityNoteEn ?? compat.stabilityNoteTh!),
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: AppTheme.inkPrimary,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  '${t ? "อ้างอิง" : "Source"}: ${compat.sourceCitation}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.inkMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
