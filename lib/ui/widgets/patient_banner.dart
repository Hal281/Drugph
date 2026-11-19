import 'package:flutter/material.dart';

import '../../core/calculators/renal_calculator.dart';
import '../../data/patient_session.dart';
import '../../core/models/patient.dart';
import '../theme/app_theme.dart';
import '../ward_list_screen.dart';
import 'patient_edit_dialog.dart';

class PatientBanner extends StatelessWidget {
  final bool isThai;

  const PatientBanner({super.key, required this.isThai});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Patient?>(
      valueListenable: PatientSession.instance.currentPatient,
      builder: (context, patient, child) {
        final hasPatient = patient != null;

        final backgroundColor =
            hasPatient ? const Color(0xFF134E4A) : AppTheme.surfaceSubtle;
        final borderColor =
            hasPatient ? const Color(0xFF0F3F3C) : AppTheme.borderStrong;
        final titleColor = hasPatient ? Colors.white : AppTheme.inkPrimary;
        final subtitleColor =
            hasPatient ? const Color(0xFFCCFBF1) : AppTheme.inkSecondary;

        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border(
              bottom: BorderSide(color: borderColor, width: 1),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showPatientDialog(context, patient),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: hasPatient
                            ? Colors.white.withValues(alpha: 0.14)
                            : AppTheme.primaryTealSoft,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: hasPatient
                              ? Colors.white.withValues(alpha: 0.22)
                              : AppTheme.primaryTealBorder,
                        ),
                      ),
                      child: Icon(
                        hasPatient
                            ? Icons.person_outline
                            : Icons.person_add_alt_1_outlined,
                        color: hasPatient ? Colors.white : AppTheme.primaryTeal,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!hasPatient)
                            Text(
                              isThai
                                  ? 'ยังไม่ได้ระบุข้อมูลผู้ป่วย (แตะเพื่อตั้งค่าน้ำหนัก/ค่าไต)'
                                  : 'No Active Patient — Tap to enter Weight / SCr',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                                color: titleColor,
                              ),
                            )
                          else ...[
                            Text(
                              patient.patientName ??
                                  (isThai
                                      ? 'ผู้ป่วยปัจจุบัน'
                                      : 'Current Patient'),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.5,
                                color: titleColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _buildPatientRenalSummary(patient),
                              style: AppTheme.monoStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: subtitleColor,
                                height: 1.35,
                              ),
                            ),
                            if (patient.allergies.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.statusCriticalBg,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppTheme.statusCriticalBorder,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.warning_amber_rounded,
                                        color: AppTheme.statusCritical,
                                        size: 13,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          isThai
                                              ? 'แพ้ยา: ${patient.allergies.join(", ")}'
                                              : 'Allergies: ${patient.allergies.join(", ")}',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: AppTheme.statusCritical,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WardListScreen(
                              currentLocale: isThai
                                  ? const Locale('th', 'TH')
                                  : const Locale('en', 'US'),
                              onLocaleChange: (_) {},
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        foregroundColor:
                            hasPatient ? Colors.white : AppTheme.primaryTeal,
                        backgroundColor: hasPatient
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.white,
                        side: BorderSide(
                          color: hasPatient
                              ? Colors.white.withValues(alpha: 0.3)
                              : AppTheme.borderStrong,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.local_hospital_outlined, size: 18),
                      label: Text(
                        isThai ? 'วอร์ด' : 'Ward',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _buildPatientRenalSummary(Patient patient) {
    final scr = patient.serumCreatinineMgDl;
    if (patient.ageYears < 18) {
      final egfr = patient.eGfrMlMinPer173m2 ??
          ((scr != null &&
                  scr > 0 &&
                  patient.ageYears >= 1 &&
                  patient.heightCm > 0)
              ? RenalCalculator.bedsideSchwartz(
                  heightCm: patient.heightCm,
                  serumCreatinineMgDl: scr,
                )
              : null);
      final egfrStr = egfr != null
          ? '${egfr.toStringAsFixed(1)} mL/min/1.73m² (Schwartz)'
          : '-';
      return '${patient.weightKg} kg | ${patient.ageYears} yrs | eGFR: $egfrStr';
    }

    final crcl = patient.creatinineClearanceMlMin ??
        ((scr != null &&
                scr > 0 &&
                patient.weightKg > 0 &&
                patient.heightCm > 0)
            ? RenalCalculator.cockcroftGaultAutoWeight(
                ageYears: patient.ageYears,
                weightKg: patient.weightKg,
                heightCm: patient.heightCm,
                sex: patient.sex,
                serumCreatinineMgDl: scr,
              )
            : null);
    final crclStr =
        crcl != null ? '${crcl.toStringAsFixed(1)} mL/min (CG)' : '-';
    return '${patient.weightKg} kg | ${patient.ageYears} yrs | CrCl: $crclStr';
  }

  void _showPatientDialog(BuildContext context, Patient? currentPatient) {
    showDialog(
      context: context,
      builder: (context) =>
          PatientEditDialog(initialPatient: currentPatient, isThai: isThai),
    );
  }
}
