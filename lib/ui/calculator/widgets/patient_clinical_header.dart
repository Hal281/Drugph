import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../models/calculator_ui_state.dart';

/// Clinical summary header displaying patient parameters and vital organ function badges
/// (TBW, IBW, AdjBW, CrCl, Child-Pugh class, and RRT modality).
class PatientClinicalHeader extends StatelessWidget {
  final CalculatorUiState state;
  final bool isThai;
  final Color categoryColor;

  const PatientClinicalHeader({
    super.key,
    required this.state,
    required this.isThai,
    this.categoryColor = Colors.teal,
  });

  @override
  Widget build(BuildContext context) {
    final t = isThai;
    final res = state.result;
    final patient = state.lastEvaluatedPatient;

    if (res == null) {
      return const SizedBox.shrink();
    }

    final weight = state.weightKg ?? patient?.weightKg;
    final height = state.heightCm ?? patient?.heightCm;
    final age = state.ageYears ?? patient?.ageYears;
    final crcl = res.crclMlMin;

    final maxBadgeWidth = MediaQuery.of(context).size.width - 64;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.badge_outlined, size: 18, color: categoryColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  t ? 'สรุปข้อมูลคลินิกผู้ป่วย' : 'Patient Clinical Status',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (patient?.patientName != null)
                Text(
                  patient!.patientName!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              // Weight & Demographics
              if (weight != null)
                _buildBadge(
                  Icons.monitor_weight_outlined,
                  '$weight kg${height != null ? " • $height cm" : ""}${age != null ? " • $age y" : ""}',
                  Colors.blueGrey.shade700,
                  Colors.blueGrey.shade50,
                  Colors.blueGrey.shade200,
                  maxBadgeWidth,
                ),
              // CrCl Badge
              if (crcl != null)
                _buildBadge(
                  Icons.water_drop_outlined,
                  'CrCl: ${crcl.toStringAsFixed(1)} mL/min',
                  crcl < 30 ? Colors.red.shade900 : Colors.teal.shade900,
                  crcl < 30 ? Colors.red.shade50 : Colors.teal.shade50,
                  crcl < 30 ? Colors.red.shade300 : Colors.teal.shade300,
                  maxBadgeWidth,
                ),
              // RRT Mode Badge
              if (state.renalReplacementMode != RenalReplacementMode.none)
                _buildBadge(
                  Icons.sync_rounded,
                  'RRT: ${t ? state.renalReplacementMode.badgeTh : state.renalReplacementMode.badgeEn}',
                  Colors.indigo.shade900,
                  Colors.indigo.shade50,
                  Colors.indigo.shade300,
                  maxBadgeWidth,
                ),
              // Child-Pugh Badge
              if (state.hepaticImpairment != ChildPughClass.none)
                _buildBadge(
                  Icons.local_hospital_outlined,
                  'Child-Pugh: ${t ? state.hepaticImpairment.labelTh : state.hepaticImpairment.labelEn}${state.lastChildPughScore != null ? " (${state.lastChildPughScore}/15)" : ""}',
                  Colors.orange.shade900,
                  Colors.orange.shade50,
                  Colors.orange.shade300,
                  maxBadgeWidth,
                ),
              // Dosing Weight Badge
              if (state.dosingWeightLabel != null &&
                  state.dosingWeightValue != null)
                _buildBadge(
                  Icons.fitness_center_outlined,
                  '${state.dosingWeightLabel}: ${state.dosingWeightValue!.toStringAsFixed(1)} kg',
                  Colors.purple.shade900,
                  Colors.purple.shade50,
                  Colors.purple.shade200,
                  maxBadgeWidth,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(
    IconData icon,
    String label,
    Color textColor,
    Color bgColor,
    Color borderColor,
    double maxWidth,
  ) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
