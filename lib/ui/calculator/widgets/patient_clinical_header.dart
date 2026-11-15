import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../../../data/patient_session.dart';
import '../models/calculator_ui_state.dart';
import '../../widgets/patient_edit_dialog.dart';

/// Patient profile summary and entry point for the shared patient editor.
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
    final patient = PatientSession.instance.currentPatient.value ??
        state.lastEvaluatedPatient;

    final weight = state.usedDefaultDemographics
        ? null
        : (state.weightKg ?? patient?.weightKg);
    final height = state.usedDefaultDemographics
        ? null
        : (state.heightCm ?? patient?.heightCm);
    final age = state.usedDefaultDemographics
        ? null
        : (state.ageYears ?? patient?.ageYears);
    final crcl = res?.crclMlMin ?? patient?.creatinineClearanceMlMin;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxBadgeWidth = constraints.maxWidth > 28
            ? constraints.maxWidth - 28
            : constraints.maxWidth;

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
                      t ? 'ข้อมูลผู้ป่วย' : 'Patient Data',
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
                  IconButton(
                    key: const Key('calculator_edit_patient_button'),
                    tooltip: t ? 'แก้ไขข้อมูลผู้ป่วย' : 'Edit patient data',
                    icon: const Icon(Icons.edit_outlined),
                    color: categoryColor,
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => PatientEditDialog(
                        initialPatient:
                            PatientSession.instance.currentPatient.value,
                        isThai: t,
                      ),
                    ),
                  ),
                ],
              ),
              if (weight == null && height == null && age == null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    t
                        ? 'กรอกข้อมูลผู้ป่วยผ่านแถบนี้หรือแถบผู้ป่วยด้านบน'
                        : 'Enter patient details from this profile or the patient banner.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (state.usedDefaultDemographics &&
                      state.dosingWeightValue == null)
                    _buildBadge(
                      Icons.medication_outlined,
                      t
                          ? 'ผู้ใหญ่ (ขนาดยาคงที่ — ไม่ใช้น้ำหนัก/ส่วนสูง)'
                          : 'Adult (Fixed Dose — Weight/Height Not Used)',
                      Colors.teal.shade900,
                      Colors.teal.shade50,
                      Colors.teal.shade200,
                      maxBadgeWidth,
                      key: const Key('patient_header_fixed_dose_badge'),
                    ),
                  if (weight != null)
                    _buildBadge(
                      Icons.monitor_weight_outlined,
                      '${t ? "น้ำหนัก" : "Weight"}: $weight kg',
                      Colors.blueGrey.shade700,
                      Colors.blueGrey.shade50,
                      Colors.blueGrey.shade200,
                      maxBadgeWidth,
                    ),
                  if (height != null)
                    _buildBadge(
                      Icons.height,
                      '${t ? "ส่วนสูง" : "Height"}: $height cm',
                      Colors.blueGrey.shade700,
                      Colors.blueGrey.shade50,
                      Colors.blueGrey.shade200,
                      maxBadgeWidth,
                    ),
                  if (age != null)
                    _buildBadge(
                      Icons.cake_outlined,
                      '${t ? "อายุ" : "Age"}: $age ${t ? "ปี" : "years"}',
                      Colors.blueGrey.shade700,
                      Colors.blueGrey.shade50,
                      Colors.blueGrey.shade200,
                      maxBadgeWidth,
                    ),
                  if (crcl != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t
                              ? 'CrCl คำนวณด้วยสูตร Cockcroft-Gault equation'
                              : 'CrCl calculated with Cockcroft-Gault equation',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        _buildBadge(
                          Icons.water_drop_outlined,
                          '${crcl.toStringAsFixed(1)} mL/min',
                          crcl < 30
                              ? Colors.red.shade900
                              : Colors.teal.shade900,
                          crcl < 30 ? Colors.red.shade50 : Colors.teal.shade50,
                          crcl < 30
                              ? Colors.red.shade300
                              : Colors.teal.shade300,
                          maxBadgeWidth,
                        ),
                      ],
                    ),
                  if (state.renalReplacementMode != RenalReplacementMode.none)
                    _buildBadge(
                      Icons.sync_rounded,
                      'RRT: ${t ? state.renalReplacementMode.badgeTh : state.renalReplacementMode.badgeEn}',
                      Colors.indigo.shade900,
                      Colors.indigo.shade50,
                      Colors.indigo.shade300,
                      maxBadgeWidth,
                    ),
                  if (state.hepaticImpairment != ChildPughClass.none)
                    _buildBadge(
                      Icons.local_hospital_outlined,
                      'Child-Pugh: ${t ? state.hepaticImpairment.labelTh : state.hepaticImpairment.labelEn}${state.lastChildPughScore != null ? " (${state.lastChildPughScore}/15)" : ""}',
                      Colors.orange.shade900,
                      Colors.orange.shade50,
                      Colors.orange.shade300,
                      maxBadgeWidth,
                    ),
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
      },
    );
  }

  Widget _buildBadge(
    IconData icon,
    String label,
    Color textColor,
    Color bgColor,
    Color borderColor,
    double maxWidth, {
    Key? key,
  }) {
    return Container(
      key: key,
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
