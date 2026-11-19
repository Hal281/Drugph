import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../../../data/patient_session.dart';
import '../../theme/app_theme.dart';
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
    this.categoryColor = AppTheme.primaryTeal,
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
    final sex = patient?.sex ?? state.sex;
    final isPediatricPatient = age != null && age < 18;
    final crcl = res?.crclMlMin ??
        (isPediatricPatient
            ? (patient?.eGfrMlMinPer173m2 ??
                ((patient?.serumCreatinineMgDl != null &&
                        patient!.serumCreatinineMgDl! > 0 &&
                        age >= 1 &&
                        height != null &&
                        height > 0)
                    ? RenalCalculator.bedsideSchwartz(
                        heightCm: height,
                        serumCreatinineMgDl: patient.serumCreatinineMgDl!,
                      )
                    : null))
            : (patient?.creatinineClearanceMlMin ??
                ((patient?.serumCreatinineMgDl != null &&
                        patient!.serumCreatinineMgDl! > 0 &&
                        age != null &&
                        age >= 18 &&
                        weight != null &&
                        weight > 0 &&
                        height != null &&
                        height > 0)
                    ? RenalCalculator.cockcroftGaultAutoWeight(
                        ageYears: age,
                        weightKg: weight,
                        heightCm: height,
                        sex: sex,
                        serumCreatinineMgDl: patient.serumCreatinineMgDl!,
                      )
                    : null)));

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
            border: Border.all(color: AppTheme.borderDefault),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.badge_outlined,
                    size: 18,
                    color: AppTheme.primaryTeal,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      t ? 'ข้อมูลผู้ป่วย' : 'Patient Data',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.inkPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (patient?.patientName != null)
                    Text(
                      patient!.patientName!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.inkSecondary,
                      ),
                    ),
                  IconButton(
                    key: const Key('calculator_edit_patient_button'),
                    tooltip: t ? 'แก้ไขข้อมูลผู้ป่วย' : 'Edit patient data',
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    color: AppTheme.primaryTeal,
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
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.inkSecondary,
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
                      AppTheme.primaryTealDark,
                      AppTheme.primaryTealSoft,
                      AppTheme.primaryTealBorder,
                      maxBadgeWidth,
                      key: const Key('patient_header_fixed_dose_badge'),
                    ),
                  if (weight != null)
                    _buildBadge(
                      Icons.monitor_weight_outlined,
                      '${t ? "น้ำหนัก" : "Weight"}: $weight kg',
                      AppTheme.inkPrimary,
                      AppTheme.surfaceSubtle,
                      AppTheme.borderDefault,
                      maxBadgeWidth,
                    ),
                  if (height != null)
                    _buildBadge(
                      Icons.height,
                      '${t ? "ส่วนสูง" : "Height"}: $height cm',
                      AppTheme.inkPrimary,
                      AppTheme.surfaceSubtle,
                      AppTheme.borderDefault,
                      maxBadgeWidth,
                    ),
                  if (age != null)
                    _buildBadge(
                      Icons.cake_outlined,
                      '${t ? "อายุ" : "Age"}: $age ${t ? "ปี" : "years"}',
                      AppTheme.inkPrimary,
                      AppTheme.surfaceSubtle,
                      AppTheme.borderDefault,
                      maxBadgeWidth,
                    ),
                  if (crcl != null)
                    Builder(
                      builder: (context) {
                        final isPediatricRenal = age != null && age < 18;
                        final cgSelection = (!isPediatricRenal &&
                                weight != null &&
                                height != null &&
                                weight > 0 &&
                                height > 0)
                            ? RenalCalculator.selectCockcroftGaultWeight(
                                weightKg: weight,
                                heightCm: height,
                                sex: sex,
                              )
                            : null;
                        final Color crclTextColor;
                        final Color crclBgColor;
                        final Color crclBorderColor;
                        if (crcl < 30) {
                          crclTextColor = AppTheme.statusCritical;
                          crclBgColor = AppTheme.statusCriticalBg;
                          crclBorderColor = AppTheme.statusCriticalBorder;
                        } else if (crcl < 60) {
                          crclTextColor = const Color(0xFF92400E);
                          crclBgColor = AppTheme.statusWarningBg;
                          crclBorderColor = AppTheme.statusWarningBorder;
                        } else {
                          crclTextColor = AppTheme.primaryTealDark;
                          crclBgColor = AppTheme.primaryTealSoft;
                          crclBorderColor = AppTheme.primaryTealBorder;
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPediatricRenal
                                  ? (t
                                      ? 'eGFR (เด็ก) คำนวณด้วยสูตร Bedside Schwartz'
                                      : 'Pediatric eGFR calculated with Bedside Schwartz')
                                  : (t
                                      ? 'CrCl คำนวณด้วยสูตร Cockcroft-Gault equation'
                                      : 'CrCl calculated with Cockcroft-Gault equation'),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.inkSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            _buildBadge(
                              Icons.water_drop_outlined,
                              isPediatricRenal
                                  ? '${crcl.toStringAsFixed(1)} mL/min/1.73 m²'
                                  : '${crcl.toStringAsFixed(1)} mL/min',
                              crclTextColor,
                              crclBgColor,
                              crclBorderColor,
                              maxBadgeWidth,
                            ),
                            if (cgSelection != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(
                                  t
                                      ? 'เกณฑ์น้ำหนัก: ${cgSelection.strategy} (${cgSelection.selectedWeightKg.toStringAsFixed(1)} kg)'
                                      : 'Weight basis: ${cgSelection.strategy} (${cgSelection.selectedWeightKg.toStringAsFixed(1)} kg)',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.inkSecondary,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    )
                  else if (isPediatricPatient &&
                      age < 1 &&
                      patient?.serumCreatinineMgDl != null &&
                      patient!.serumCreatinineMgDl! > 0)
                    _buildBadge(
                      Icons.info_outline,
                      t
                          ? 'ทารก < 1 ปี: สูตร Bedside Schwartz ยังไม่รองรับ — โปรดประเมินไตโดยเฉพาะทาง'
                          : 'Infant < 1 yr: Bedside Schwartz eGFR not validated — specialist renal review required',
                      const Color(0xFF92400E),
                      AppTheme.statusWarningBg,
                      AppTheme.statusWarningBorder,
                      maxBadgeWidth,
                      key: const Key('patient_header_infant_egfr_disclaimer'),
                    ),
                  if (state.renalReplacementMode != RenalReplacementMode.none)
                    _buildBadge(
                      Icons.sync_rounded,
                      'RRT: ${t ? state.renalReplacementMode.badgeTh : state.renalReplacementMode.badgeEn}',
                      const Color(0xFF92400E),
                      AppTheme.statusWarningBg,
                      AppTheme.statusWarningBorder,
                      maxBadgeWidth,
                    ),
                  if (state.hepaticImpairment != ChildPughClass.notAssessed)
                    _buildBadge(
                      Icons.local_hospital_outlined,
                      'Child-Pugh: ${t ? state.hepaticImpairment.labelTh : state.hepaticImpairment.labelEn}${state.lastChildPughScore != null ? " (${state.lastChildPughScore}/15)" : ""}',
                      state.hepaticImpairment == ChildPughClass.none
                          ? AppTheme.primaryTealDark
                          : const Color(0xFF92400E),
                      state.hepaticImpairment == ChildPughClass.none
                          ? AppTheme.primaryTealSoft
                          : AppTheme.statusWarningBg,
                      state.hepaticImpairment == ChildPughClass.none
                          ? AppTheme.primaryTealBorder
                          : AppTheme.statusWarningBorder,
                      maxBadgeWidth,
                    )
                  else if (state.drug.requiresHepaticCaution)
                    _buildBadge(
                      Icons.local_hospital_outlined,
                      t
                          ? 'ตับ (Child-Pugh): ยังไม่ได้ประเมิน'
                          : 'Hepatic (Child-Pugh): Not assessed',
                      AppTheme.inkSecondary,
                      AppTheme.surfaceSubtle,
                      AppTheme.borderDefault,
                      maxBadgeWidth,
                      key: const Key('patient_header_hepatic_not_assessed'),
                    ),
                  if (state.dosingWeightLabel != null &&
                      state.dosingWeightValue != null)
                    _buildBadge(
                      Icons.fitness_center_outlined,
                      '${state.dosingWeightLabel}: ${state.dosingWeightValue!.toStringAsFixed(1)} kg',
                      AppTheme.inkPrimary,
                      AppTheme.surfaceSubtle,
                      AppTheme.borderDefault,
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
