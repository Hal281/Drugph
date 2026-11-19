import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../../../data/patient_session.dart';
import '../../iv_titration_screen.dart';
import '../../pkpd/pkpd_simulation_sheet.dart';
import '../../tdm_screen.dart';
import '../../theme/app_theme.dart';
import '../../widgets/clinical_evidence_sheet.dart';
import '../models/calculator_ui_state.dart';
import 'clinical_action_bar.dart';
import 'safety_alert_banner.dart';

/// Primary Clinical Dosage Result Card.
///
/// Encapsulates:
/// - Semantic alert border & compact status banner (Green verified, Amber warning, Red critical)
/// - Non-blocking overdose banner and critical contraindication banners
/// - Dosing display (rounded formulary dose with raw dose reference, or titrated infusion rate)
/// - CrCl clearance badge & bedside RRT modality badges
/// - Monograph drawer, PK-PD modeling, and TDM calculator triggers (>= 48dp)
/// - Dual copy action bar (HIS Order & Pharmacist Note >= 48dp)
/// - Warning details list
class DosageResultCard extends StatelessWidget {
  final CalculatorUiState state;
  final bool isThai;
  final Patient Function() onBuildPatient;

  const DosageResultCard({
    super.key,
    required this.state,
    required this.isThai,
    required this.onBuildPatient,
  });

  @override
  Widget build(BuildContext context) {
    final t = isThai;
    final res = state.result;
    if (res == null) return const SizedBox.shrink();

    final effectiveWarnings =
        state.warnings.isNotEmpty ? state.warnings : res.warnings;
    final isOverdose = SafetyAlertBanner.hasOverdose(effectiveWarnings);

    final hasHardWarnings =
        state.warnings.any((w) => w.severity == LimitSeverity.hard);
    final hasSoftWarnings =
        state.warnings.any((w) => w.severity == LimitSeverity.soft);

    final headerBgColor = hasHardWarnings
        ? AppTheme.statusCriticalBg
        : (hasSoftWarnings ? AppTheme.statusWarningBg : AppTheme.statusSafeBg);
    final cardBorderColor = hasHardWarnings
        ? AppTheme.statusCritical
        : (hasSoftWarnings
            ? AppTheme.statusWarning
            : AppTheme.statusSafeBorder);
    final headerIcon = hasHardWarnings
        ? Icons.error_outline
        : (hasSoftWarnings
            ? Icons.warning_amber_rounded
            : Icons.check_circle_outline);
    final headerIconColor = hasHardWarnings
        ? AppTheme.statusCritical
        : (hasSoftWarnings ? AppTheme.statusWarning : AppTheme.statusSafe);
    final headerTitle = hasHardWarnings
        ? (t
            ? 'คำเตือน: พบความเสี่ยงระดับวิกฤต (Critical Alert)'
            : 'CRITICAL SAFETY ALERT')
        : (hasSoftWarnings
            ? (t ? 'ผลการคำนวณ (มีข้อควรระวัง)' : 'Calculated with Warnings')
            : (t
                ? 'ผลการคำนวณผ่านเกณฑ์ความปลอดภัย'
                : 'Calculated Result (Verified)'));

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: cardBorderColor, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: headerBgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: hasHardWarnings
                      ? AppTheme.statusCriticalBorder
                      : (hasSoftWarnings
                          ? AppTheme.statusWarningBorder
                          : AppTheme.statusSafeBorder),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(headerIcon, color: headerIconColor, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      headerTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: hasHardWarnings
                            ? AppTheme.statusCritical
                            : (hasSoftWarnings
                                ? const Color(0xFF92400E)
                                : AppTheme.statusSafe),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Safety alert banner (Rule 5: Non-blocking overdose policy)
            SafetyAlertBanner(
              result: res,
              warnings: state.warnings,
              isThai: t,
            ),

            // Dose display
            if (res.infusionResult != null) ...[
              _buildContinuousInfusionSection(
                context,
                res,
                res.infusionResult!,
                t,
                isOverdose,
              ),
            ] else if (res.roundedDose != null) ...[
              Container(
                key: const Key('dosage_result_status_label'),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOverdose
                      ? const Color(0xFFFEE2E2)
                      : AppTheme.statusSafeBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isOverdose
                        ? AppTheme.statusCriticalBorder
                        : AppTheme.statusSafeBorder,
                    width: 1,
                  ),
                ),
                child: Text(
                  isOverdose
                      ? (t
                          ? 'ขนาดยาจากการคำนวณ (เกินเกณฑ์แนะนำ)'
                          : 'Calculated Dose (Exceeds Limit)')
                      : (t
                          ? 'ขนาดยาที่แนะนำ (ปัดเศษแล้ว)'
                          : 'Recommended Dose (Rounded)'),
                  style: TextStyle(
                    color: isOverdose
                        ? const Color(0xFF991B1B)
                        : const Color(0xFF065F46),
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${res.roundedDose?.toStringAsFixed(2)} ${res.doseUnit?.symbol}',
                  style: AppTheme.monoStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.inkPrimary,
                    height: 1.15,
                  ),
                ),
              ),
              if (res.frequency != null && res.frequency!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    res.frequency!,
                    style: const TextStyle(
                      fontSize: 18,
                      color: AppTheme.inkSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (res.calculatedDose != null) ...[
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceSubtle,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.borderDefault),
                    ),
                    child: Text(
                      t
                          ? 'ขนาดยาคำนวณจริงก่อนปัดเศษ: ${res.calculatedDose?.toStringAsFixed(2)} ${res.doseUnit?.symbol}'
                          : 'Raw Calculated Dose: ${res.calculatedDose?.toStringAsFixed(2)} ${res.doseUnit?.symbol}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade900,
                      ),
                    ),
                  ),
                ),
              ],
            ] else if (res.calculatedDose != null) ...[
              if (isOverdose)
                Container(
                  key: const Key('dosage_result_status_label'),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppTheme.statusCriticalBorder,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    t
                        ? 'ขนาดยาจากการคำนวณ (เกินเกณฑ์แนะนำ)'
                        : 'Calculated Dose (Exceeds Limit)',
                    style: const TextStyle(
                      color: Color(0xFF991B1B),
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${res.calculatedDose!.toStringAsFixed(2)} ${res.doseUnit?.symbol ?? ''}',
                  style: AppTheme.monoStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.inkPrimary,
                    height: 1.15,
                  ),
                ),
              ),
              if (res.frequency != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    res.frequency!,
                    style: const TextStyle(
                      fontSize: 17,
                      color: AppTheme.inkSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ] else if (res.activePhases == null || res.activePhases!.isEmpty) ...[
              Container(
                key: const Key('dosage_result_blocked_badge'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.statusCriticalBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.statusCriticalBorder),
                ),
                child: Text(
                  t
                      ? 'ระงับการคำนวณขนาดยา — สูตรยาไม่ตรงกับกลุ่มอายุหรือเกณฑ์ความปลอดภัยของผู้ป่วย'
                      : 'Calculation Blocked — Regimen does not match patient age/safety criteria',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.statusCritical,
                  ),
                ),
              ),
            ],

            // Multi-Phase Regimen / Antidote Protocol (e.g. N-Acetylcysteine 3-Bag Regimen)
            if (res.activePhases != null && res.activePhases!.isNotEmpty) ...[
              const SizedBox(height: 14),
              _buildMultiPhaseAntidoteSection(context, res, t),
            ],

            // Clinical Dosing Badges (Oral Liquid R1, IV Reconstitution & Pump Rate R2)
            _buildClinicalDosingBadges(context, res, t),

            // CrCl Badge
            if (res.crclMlMin != null) ...[
              const SizedBox(height: 12),
              Container(
                key: const Key('dosage_result_crcl_badge'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSubtle,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderDefault),
                ),
                child: Text(
                  _formatCrClBadgeText(res),
                  textAlign: TextAlign.center,
                  style: AppTheme.monoStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryTealDark,
                    height: 1.35,
                  ),
                ),
              ),
            ],

            // RRT Result Badges
            _buildRrtResultBadges(res, t),
            const SizedBox(height: 14),

            // Monograph Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const Key('calculator_view_monograph_btn'),
                icon: const Icon(Icons.menu_book_outlined, size: 18),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    t
                        ? 'เปิดดูข้อมูลยาในตำราอ้างอิง'
                        : 'View Textbook Monograph',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: AppTheme.primaryTealDark,
                  side: const BorderSide(color: AppTheme.borderStrong),
                  backgroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => ClinicalEvidenceSheet.show(
                  context,
                  drug: state.drug,
                  regimen: state.selectedRegimen,
                  isThai: t,
                ),
              ),
            ),

            // Dynamic NTI & Continuous Infusion PK-PD Modeling Action Button
            if (isNtiOrSimulationCandidate(state.drug, state.selectedRegimen, res)) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const Key('calculator_open_pkpd_btn'),
                  icon: const Icon(Icons.show_chart_rounded, size: 20),
                  label: Text(
                    t
                        ? 'เปิดแบบจำลอง PK-PD & กราฟทำนายระดับยา'
                        : 'PK-PD Simulation & Predictive Curve',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.clinicalNavy,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    final patient = state.lastEvaluatedPatient ?? onBuildPatient();
                    PkPdSimulationSheet.show(
                      context,
                      drug: state.drug,
                      regimen: state.selectedRegimen ?? state.drug.regimens.first,
                      result: res,
                      patient: patient,
                      isThai: t,
                    );
                  },
                ),
              ),
            ],

            // TDM Button for Vancomycin / Aminoglycosides
            if (const {'vancomycin', 'gentamicin', 'amikacin'}
                    .contains(state.drug.id) ||
                state.drug.genericName
                    .toLowerCase()
                    .contains('vancomycin')) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('calculator_open_tdm_btn'),
                  icon: const Icon(Icons.analytics_outlined, size: 19),
                  label: Text(
                    t ? 'เครื่องมือคำนวณ TDM' : 'TDM Calculator',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryTealDark,
                    backgroundColor: AppTheme.primaryTealSoft,
                    side: const BorderSide(color: AppTheme.primaryTealBorder),
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    final activePt =
                        PatientSession.instance.currentPatient.value;
                    final p = onBuildPatient();
                    final tdmPatient = Patient(
                      id: p.id,
                      patientName: p.patientName,
                      hospitalNumber: p.hospitalNumber,
                      weightKg: p.weightKg,
                      heightCm: p.heightCm,
                      ageYears: p.ageYears,
                      sex: p.sex,
                      serumCreatinineMgDl: p.serumCreatinineMgDl,
                      isScrStable: p.isScrStable,
                      renalReplacementMode: p.renalReplacementMode,
                      creatinineClearanceMlMin:
                          res.crclMlMin ?? activePt?.creatinineClearanceMlMin,
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TdmScreen(
                          patient: tdmPatient,
                          drug: state.drug,
                          isThai: t,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Side-by-side Dual Copy Action Bar
            ClinicalActionBar(
              state: state,
              isThai: t,
              onBuildPatient: onBuildPatient,
            ),

            // Warning Details List
            if (state.warnings.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...state.warnings.map(
                (w) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: w.severity == LimitSeverity.hard
                        ? AppTheme.statusCriticalBg
                        : AppTheme.statusWarningBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: w.severity == LimitSeverity.hard
                          ? AppTheme.statusCriticalBorder
                          : AppTheme.statusWarningBorder,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        w.severity.icon,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t ? w.messageTh : w.messageEn,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                            color: w.severity == LimitSeverity.hard
                                ? const Color(0xFF991B1B)
                                : const Color(0xFF92400E),
                          ),
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
    );
  }

  Widget _buildClinicalDosingBadges(
    BuildContext context,
    DosageResult res,
    bool t,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Backward-compatible Volume Badge
        if (res.volumeMl != null) ...[
          const SizedBox(height: 10),
          Container(
            key: const Key('dosage_result_volume_badge'),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: AppTheme.statusInfoBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.statusInfoBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.vaccines_outlined,
                  color: AppTheme.statusInfo,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    t
                        ? 'ปริมาตรยาที่ต้องบริหาร: ${res.volumeMl! < 1.0 ? res.volumeMl!.toStringAsFixed(2) : res.volumeMl!.toStringAsFixed(1)} mL'
                        : 'Volume to Administer: ${res.volumeMl! < 1.0 ? res.volumeMl!.toStringAsFixed(2) : res.volumeMl!.toStringAsFixed(1)} mL',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.inkPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Pediatric Oral Liquid Dosing Badge (R1)
        if (res.teaspoons != null || res.liquidConcentration != null) ...[
          const SizedBox(height: 10),
          Container(
            key: const Key('dosage_result_liquid_badge'),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryTealSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.primaryTealBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.medication_liquid_outlined,
                      color: AppTheme.primaryTealDark,
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t
                            ? 'ขนาดยาน้ำรับประทาน (Pediatric Oral Liquid)'
                            : 'Pediatric Oral Liquid Dosing',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryTealDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (res.volumeMl != null)
                      Text(
                        t
                            ? 'ปริมาตร: ${res.volumeMl! < 1.0 ? res.volumeMl!.toStringAsFixed(2) : res.volumeMl!.toStringAsFixed(1)} mL'
                            : 'Volume: ${res.volumeMl! < 1.0 ? res.volumeMl!.toStringAsFixed(2) : res.volumeMl!.toStringAsFixed(1)} mL',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.inkPrimary,
                        ),
                      ),
                    if (res.teaspoons != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.primaryTealBorder),
                        ),
                        child: Text(
                          t
                              ? 'เทียบเท่า: ${UnitConverter.formatTeaspoons(res.teaspoons!, isThai: true)}'
                              : 'Household: ${UnitConverter.formatTeaspoons(res.teaspoons!, isThai: false)}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryTealDark,
                          ),
                        ),
                      ),
                  ],
                ),
                if (res.liquidConcentrationLabel != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    t
                        ? 'สูตรยาในคลัง: ${res.liquidConcentrationLabel}'
                        : 'Commercial Formulation: ${res.liquidConcentrationLabel}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.inkSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  t
                      ? 'คำแนะนำ: 1 ช้อนชา (tsp) = 5 mL | แนะนำใช้กระบอกฉีดยา (oral syringe) เพื่อความแม่นยำ'
                      : 'Guideline: 1 tsp = 5 mL | Recommend oral syringe or calibrated measuring spoon for accuracy',
                  style: const TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ],

        // Hospital IV Reconstitution Vial Draw Badge (R2)
        if (res.vialDrawVolumeMl != null) ...[
          const SizedBox(height: 10),
          Container(
            key: const Key('dosage_result_vial_draw_badge'),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSubtle,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderStrong),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.vaccines_outlined,
                      color: AppTheme.inkPrimary,
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t
                            ? 'การเตรียมยาฉีด & ปริมาตรดูดยา (Vial Reconstitution & Draw)'
                            : 'IV Reconstitution & Draw',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.inkPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  t
                      ? 'ปริมาตรดูดยาจากขวด: ${res.vialDrawVolumeMl! < 1.0 ? res.vialDrawVolumeMl!.toStringAsFixed(2) : res.vialDrawVolumeMl!.toStringAsFixed(1)} mL'
                      : 'Vial Draw Volume: ${res.vialDrawVolumeMl! < 1.0 ? res.vialDrawVolumeMl!.toStringAsFixed(2) : res.vialDrawVolumeMl!.toStringAsFixed(1)} mL',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.inkPrimary,
                  ),
                ),
                if (res.reconstitutionConcentrationMgPerMl != null ||
                    res.vialsNeeded != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (res.reconstitutionConcentrationMgPerMl != null)
                        t
                            ? 'ความเข้มข้นหลังละลาย: ${res.reconstitutionConcentrationMgPerMl!.toStringAsFixed(1)} mg/mL'
                            : 'Reconstituted Conc: ${res.reconstitutionConcentrationMgPerMl!.toStringAsFixed(1)} mg/mL',
                      if (res.vialsNeeded != null)
                        t
                            ? 'จำนวนขวดที่ใช้: ${res.vialsNeeded} ขวด'
                            : 'Vials Needed: ${res.vialsNeeded}',
                    ].join(' | '),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.inkSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],

        // IV Infusion Pump Rate Badge (R2)
        if (res.infusionRateMlPerHr != null && res.infusionResult == null) ...[
          const SizedBox(height: 10),
          Container(
            key: const Key('dosage_result_pump_rate_badge'),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryTealSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.primaryTealBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.speed_outlined,
                      color: AppTheme.primaryTealDark,
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t
                            ? 'อัตราเครื่องหยดยา & สารน้ำ (Infusion Rate & Dilution)'
                            : 'Infusion Pump Rate & Bag',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryTealDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  t
                      ? 'อัตราเครื่องหยดยา: ${res.infusionRateMlPerHr!.toStringAsFixed(1)} mL/hr'
                      : 'Infusion Pump Rate: ${res.infusionRateMlPerHr!.toStringAsFixed(1)} mL/hr',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.inkPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (res.totalInfusionVolumeMl != null)
                      t
                          ? 'ปริมาตรสารน้ำรวม: ${res.totalInfusionVolumeMl!.toStringAsFixed(0)} mL'
                          : 'Total Bag Volume: ${res.totalInfusionVolumeMl!.toStringAsFixed(0)} mL',
                    if (res.infusionDurationMinutes != null)
                      t
                          ? 'ระยะเวลา: ${res.infusionDurationMinutes!.toStringAsFixed(0)} นาที'
                          : 'Duration: ${res.infusionDurationMinutes!.toStringAsFixed(0)} min',
                    if (res.dripRateDropsPerMin != null)
                      t
                          ? 'หยดน้ำเกลือ: ${res.dripRateDropsPerMin!.toStringAsFixed(0)} drops/min'
                          : 'Gravity Drip: ${res.dripRateDropsPerMin!.toStringAsFixed(0)} gtt/min',
                  ].join(' | '),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRrtResultBadges(DosageResult res, bool t) {
    if (res.renalReplacementMode == RenalReplacementMode.none) {
      return const SizedBox.shrink();
    }

    final isCrrt = res.renalReplacementMode == RenalReplacementMode.crrt;
    final isCapd = res.renalReplacementMode == RenalReplacementMode.capd;
    final isIhd = res.renalReplacementMode == RenalReplacementMode.ihd;
    final requiresPostHd = res.requiresPostHdSupplement;

    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (isCrrt)
                Container(
                  key: const Key('calculator_crrt_badge'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTealSoft,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primaryTealBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.sync_rounded,
                        color: AppTheme.primaryTealDark,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          t
                              ? 'CRRT: เฝ้าระวังระดับยาต่อเนื่อง'
                              : 'CRRT: Continuous Dialysis Mode',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: AppTheme.primaryTealDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              if (requiresPostHd)
                Container(
                  key: const Key('calculator_post_hd_badge'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.statusWarningBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.statusWarningBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.access_time_filled,
                        color: AppTheme.statusWarning,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          t
                              ? 'Post-HD: ให้ยาหลังการฟอกเลือด'
                              : 'Post-HD: Administer after dialysis',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Color(0xFF92400E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )
              else if (isIhd)
                Container(
                  key: const Key('calculator_ihd_badge'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSubtle,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderStrong),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bloodtype_outlined,
                        color: AppTheme.inkPrimary,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          t
                              ? 'IHD: ฟอกเลือดด้วยไตเทียม'
                              : 'IHD: Hemodialysis Mode',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: AppTheme.inkPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              if (isCapd)
                Container(
                  key: const Key('calculator_capd_badge'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.statusInfoBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.statusInfoBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.swap_horiz_rounded,
                        color: AppTheme.statusInfo,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          t
                              ? 'CAPD: ล้างไตทางช่องท้อง'
                              : 'CAPD: Peritoneal Dialysis',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Color(0xFF075985),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (res.rrtInstructionTh != null ||
              res.rrtInstructionEn != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceSubtle,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderDefault),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppTheme.inkSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      (t
                              ? (res.rrtInstructionTh ?? res.rrtInstructionEn)
                              : (res.rrtInstructionEn ??
                                  res.rrtInstructionTh)) ??
                          '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.inkPrimary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================================================
  // Continuous Infusion Dual-Metric Section & Helpers
  // ==========================================================================

  Widget _buildContinuousInfusionSection(
    BuildContext context,
    DosageResult res,
    InfusionResult inf,
    bool t,
    bool isOverdose,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tune_rounded, size: 20, color: Colors.teal.shade800),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                t
                    ? 'อัตราการหยดยาปรับตามอาการ (Titrated Infusion Rates)'
                    : 'Titrated Infusion Rates',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isOverdose
                      ? const Color(0xFF7F1D1D)
                      : Colors.teal.shade900,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Dual Tiles: Responsive LayoutBuilder (Side-by-Side vs Vertical Stack)
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 360;
            final doseTile = _buildDoseRateTile(inf, t, isOverdose);
            final pumpTile = _buildPumpRateTile(inf, t, isOverdose);

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  doseTile,
                  const SizedBox(height: 10),
                  pumpTile,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: doseTile),
                const SizedBox(width: 12),
                Expanded(child: pumpTile),
              ],
            );
          },
        ),

        const SizedBox(height: 12),

        // Contextual Diluent & Concentration Banner
        _buildConcentrationContextBanner(context, res, t),
      ],
    );
  }

  /// Clinical Dose Rate Tile (Prescribed Pharmacodynamic Rate).
  Widget _buildDoseRateTile(InfusionResult inf, bool t, bool isOverdose) {
    final doseRateStr = inf.rateMax != null && inf.rateMax! > inf.rate
        ? '${inf.rate}–${inf.rateMax} ${inf.rateUnit.symbol}'
        : '${inf.rate} ${inf.rateUnit.symbol}';

    return Container(
      key: const Key('dosage_result_dose_rate_tile'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOverdose ? AppTheme.statusCritical : AppTheme.primaryTealBorder,
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isOverdose
                  ? AppTheme.statusCriticalBg
                  : AppTheme.primaryTealSoft,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isOverdose
                    ? AppTheme.statusCriticalBorder
                    : AppTheme.primaryTealBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.medical_services_outlined,
                  size: 14,
                  color: isOverdose
                      ? AppTheme.statusCritical
                      : AppTheme.primaryTealDark,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    t ? 'ขนาดยา (Dose Rate)' : 'Clinical Dose Rate',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isOverdose
                          ? AppTheme.statusCritical
                          : AppTheme.primaryTealDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Text(
              doseRateStr,
              style: AppTheme.monoStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isOverdose
                    ? AppTheme.statusCritical
                    : AppTheme.primaryTealDark,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            t ? 'ขนาดยาตามน้ำหนักตัว' : 'Patient-normalized rate',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.inkMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Volumetric Bedside Pump Rate Tile (Physical Infusion Setting).
  Widget _buildPumpRateTile(InfusionResult inf, bool t, bool isOverdose) {
    return Container(
      key: const Key('dosage_result_pump_rate_tile'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderStrong, width: 1.2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSubtle,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.borderDefault),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.speed_rounded,
                  size: 14,
                  color: AppTheme.clinicalNavy,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    t ? 'อัตราหยดเครื่อง (Pump Rate)' : 'Bedside Pump Rate',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.clinicalNavy,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (inf.rateMlPerHr != null) ...[
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                inf.rateMlPerHrMax != null &&
                        inf.rateMlPerHrMax! > inf.rateMlPerHr!
                    ? 'Pump Rate: ${inf.rateMlPerHr!.toStringAsFixed(1)}–${inf.rateMlPerHrMax!.toStringAsFixed(1)} mL/hr'
                    : 'Pump Rate: ${inf.rateMlPerHr!.toStringAsFixed(1)} mL/hr',
                style: AppTheme.monoStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.clinicalNavy,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              t ? 'ตั้งค่าเครื่อง Infusion Pump' : 'Volumetric pump setting',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.inkMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else ...[
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                t ? 'ไม่ระบุความเข้มข้น' : 'No Std Dilution',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.statusWarning,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              t ? 'โปรดตรวจสอบคู่มือผสมยา' : 'Consult monograph',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Contextual Diluent & Concentration Reference Banner.
  Widget _buildConcentrationContextBanner(
    BuildContext context,
    DosageResult res,
    bool t,
  ) {
    final reg = state.selectedRegimen ??
        (state.drug.regimens.isNotEmpty ? state.drug.regimens.first : null);
    final drug = state.drug;
    final dilutionMgPerMl = reg?.effectiveStandardDilutionMgPerMl;
    final compat = reg?.effectiveIvDiluentCompatibility(drug);

    final concText = _resolveConcentrationDisplay(reg, drug, dilutionMgPerMl);
    final diluentText = _resolveDiluentContext(compat, t);
    final hasTitrationButton = reg?.dosingType == DosingType.titrated &&
        dilutionMgPerMl != null;

    Widget buildContextTextColumn() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t
                ? 'ความเข้มข้นสารน้ำอ้างอิง (Reference Dilution):'
                : 'Reference Dilution Context:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey.shade700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            concText,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey.shade900,
            ),
          ),
          if (diluentText != null) ...[
            const SizedBox(height: 4),
            Text(
              diluentText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.teal.shade800,
              ),
            ),
          ],
        ],
      );
    }

    Widget buildTitrationButton({bool isFullWidth = false}) {
      return TextButton.icon(
        key: const Key('dosage_result_open_titration_btn'),
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.compact,
          foregroundColor: Colors.teal.shade800,
          backgroundColor: isFullWidth ? Colors.teal.shade50.withValues(alpha: 0.5) : null,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          shape: isFullWidth
              ? RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.teal.shade200, width: 1),
                )
              : null,
        ),
        icon: const Icon(Icons.table_chart_outlined, size: 16),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            t ? 'ตารางดริป' : 'Table',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => IVTitrationScreen(
                drug: drug,
                regimen: reg!,
                isThai: t,
              ),
            ),
          );
        },
      );
    }

    return Container(
      key: const Key('dosage_result_concentration_context'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueGrey.shade200, width: 1.2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(1.0);
          final isNarrow = constraints.maxWidth < 320 ||
              textScale >= 1.35 ||
              (textScale > 1.15 && constraints.maxWidth < 480);

          if (hasTitrationButton && isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.science_outlined,
                      size: 20,
                      color: Colors.blueGrey.shade800,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: buildContextTextColumn()),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: buildTitrationButton(isFullWidth: true),
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.science_outlined,
                size: 20,
                color: Colors.blueGrey.shade800,
              ),
              const SizedBox(width: 10),
              Expanded(child: buildContextTextColumn()),
              if (hasTitrationButton) ...[
                const SizedBox(width: 8),
                buildTitrationButton(isFullWidth: false),
              ],
            ],
          );
        },
      ),
    );
  }

  /// Formats the contextual concentration string with standard container bag notes.
  String _resolveConcentrationDisplay(
    DosingRegimen? reg,
    Drug drug,
    double? dilutionMgPerMl,
  ) {
    if (dilutionMgPerMl == null || dilutionMgPerMl <= 0) {
      return isThai
          ? 'ไม่พบข้อมูลความเข้มข้นสารน้ำมาตรฐาน'
          : 'No standard dilution data';
    }

    final rateUnit = reg?.rateUnit ??
        (reg?.continuousRateUnit != null
            ? RateUnit.tryFromSymbol(reg!.continuousRateUnit!)
            : null) ??
        RateUnit.mcgKgMin;

    final isBioUnit = rateUnit == RateUnit.uHr ||
        rateUnit == RateUnit.uKgHr ||
        rateUnit == RateUnit.mUMin;

    if (isBioUnit) {
      if ((dilutionMgPerMl - 1.0).abs() < 1e-4) {
        return '1 Unit/mL [100 Units in 100 mL NS]';
      } else if ((dilutionMgPerMl - 100.0).abs() < 1e-4) {
        return '100 Units/mL [25,000 Units in 250 mL]';
      } else if ((dilutionMgPerMl - 0.01).abs() < 1e-4) {
        return '10 mU/mL (0.01 Units/mL) [10 Units in 1,000 mL]';
      }
      return '$dilutionMgPerMl Units/mL';
    }

    final isVasoactive = rateUnit == RateUnit.mcgKgMin ||
        rateUnit == RateUnit.mcgKgHr ||
        drug.category == DrugCategory.vasopressor;

    if (isVasoactive) {
      final mcgPerMl = dilutionMgPerMl * 1000.0;
      final mcgStr = mcgPerMl == mcgPerMl.roundToDouble()
          ? mcgPerMl.toStringAsFixed(0)
          : mcgPerMl.toStringAsFixed(1);

      String bagNote = '';
      if ((dilutionMgPerMl - 0.016).abs() < 0.001) {
        bagNote = ' [4 mg in 250 mL]';
      } else if ((dilutionMgPerMl - 0.032).abs() < 0.001) {
        bagNote = ' [8 mg in 250 mL]';
      } else if ((dilutionMgPerMl - 1.6).abs() < 0.01) {
        bagNote = ' [400 mg in 250 mL]';
      } else if ((dilutionMgPerMl - 1.0).abs() < 0.01) {
        bagNote = ' [250 mg in 250 mL]';
      }
      return '$mcgStr mcg/mL ($dilutionMgPerMl mg/mL)$bagNote';
    }

    if ((dilutionMgPerMl - 0.1).abs() < 0.005) {
      return '0.1 mg/mL [25 mg in 250 mL]';
    }

    return '$dilutionMgPerMl mg/mL';
  }

  /// Formats preferred and compatible diluent fluid text.
  String? _resolveDiluentContext(IvDiluentCompatibility? compat, bool t) {
    if (compat == null) return null;
    final pref = compat.preferredDiluent?.code;
    final compats = compat.compatibleDiluents.map((d) => d.code).join(', ');

    if (pref != null && compats.isNotEmpty) {
      return t
          ? 'สารน้ำที่แนะนำ: $pref (เข้ากันได้: $compats)'
          : 'Preferred Fluid: $pref (Compatible: $compats)';
    } else if (pref != null) {
      return t ? 'สารน้ำที่แนะนำ: $pref' : 'Preferred Fluid: $pref';
    } else if (compats.isNotEmpty) {
      return t ? 'สารน้ำที่เข้ากันได้: $compats' : 'Compatible Fluids: $compats';
    }
    return null;
  }

  Widget _buildMultiPhaseAntidoteSection(
    BuildContext context,
    DosageResult res,
    bool t,
  ) {
    final phases = res.activePhases!;
    final patient = onBuildPatient();
    final regimen = state.selectedRegimen;
    final maxWeight = regimen?.maxDosingWeightKg;
    final isCapped = maxWeight != null && patient.weightKg > maxWeight;
    final effectiveWeight = isCapped ? maxWeight : patient.weightKg;

    return Container(
      key: const Key('dosage_result_multiphase_card'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTealSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.medication_liquid_outlined,
                  color: AppTheme.primaryTealDark,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t
                      ? 'โปรโตคอลการบริหารยาแบบหลายขั้นตอน (Sequential Protocol)'
                      : 'Multi-Phase Sequential Protocol',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.inkPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (isCapped) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.amber.shade900),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      t
                          ? 'น้ำหนักตัว ${patient.weightKg.toStringAsFixed(1)} กก. ถูกจำกัดที่ ${maxWeight.toStringAsFixed(0)} กก. ตามเกณฑ์ปลอดภัยสูงสุด'
                          : 'Patient weight ${patient.weightKg.toStringAsFixed(1)} kg capped at ${maxWeight.toStringAsFixed(0)} kg for maximum safe ceiling',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          for (int i = 0; i < phases.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _buildPhaseItem(
              context,
              index: i,
              phase: phases[i],
              effectiveWeight: effectiveWeight,
              t: t,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhaseItem(
    BuildContext context, {
    required int index,
    required DosingPhase phase,
    required double effectiveWeight,
    required bool t,
  }) {
    // 1. Calculate delivered dose
    double? doseValue;
    if (phase.dosePerKg != null) {
      doseValue = phase.dosePerKg! * effectiveWeight;
    } else if (phase.dose != null) {
      doseValue = phase.dose!;
    }
    final unitStr = phase.doseUnit?.symbol ?? 'mg';

    // 2. Extract diluent volume (e.g. "in 200 mL D5W")
    final instructionsText =
        '${phase.instructionsEn ?? ''} ${phase.instructionsTh ?? ''}';
    final mlMatch = RegExp(r'in\s+(\d+(?:\.\d+)?)\s*mL', caseSensitive: false)
        .firstMatch(instructionsText);
    final diluentMl =
        mlMatch != null ? double.tryParse(mlMatch.group(1)!) : null;

    // 3. Duration in hours
    final durationHours = phase.durationHours ??
        (phase.durationDays != null ? phase.durationDays! * 24.0 : null);

    // 4. Volumetric pump rate (mL/hr)
    final pumpRateMlPerHr =
        (diluentMl != null && durationHours != null && durationHours > 0)
            ? (diluentMl / durationHours)
            : null;

    final phaseTitle = t ? phase.nameTh : phase.nameEn;

    return Container(
      key: Key('dosage_result_phase_$index'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#${index + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  phaseTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (durationHours != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule, size: 13, color: Colors.blue.shade800),
                      const SizedBox(width: 4),
                      Text(
                        durationHours == durationHours.roundToDouble()
                            ? '${durationHours.round()} ${t ? 'ชม.' : 'hr'}'
                            : '${durationHours.toStringAsFixed(1)} ${t ? 'ชม.' : 'hr'}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t ? 'ขนาดยาที่ต้องให้:' : 'Delivered Dose:',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      doseValue != null
                          ? _formatPhaseDose(doseValue, unitStr)
                          : (phase.instructionsEn ?? '-'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              if (diluentMl != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t ? 'ปริมาตรสารน้ำ:' : 'Diluent Volume:',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${diluentMl == diluentMl.roundToDouble() ? diluentMl.round().toString() : diluentMl.toStringAsFixed(1)} mL',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              if (pumpRateMlPerHr != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        t ? 'อัตราเครื่องหยด:' : 'Pump Rate:',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.teal.shade300),
                        ),
                        child: Text(
                          '${pumpRateMlPerHr == pumpRateMlPerHr.roundToDouble() ? pumpRateMlPerHr.round().toString() : pumpRateMlPerHr.toStringAsFixed(1)} mL/hr',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (phase.instructionsEn != null || phase.instructionsTh != null) ...[
            const SizedBox(height: 6),
            Text(
              t
                  ? (phase.instructionsTh ?? phase.instructionsEn!)
                  : (phase.instructionsEn ?? phase.instructionsTh!),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatPhaseDose(double value, String unit) {
    final isInt = value == value.roundToDouble();
    final str = isInt ? value.round().toString() : value.toStringAsFixed(1);
    final parts = str.split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    final formatted = parts.length > 1 ? '$intPart.${parts[1]}' : intPart;
    return '$formatted $unit';
  }

  String _formatCrClBadgeText(DosageResult res) {
    final crclStr = res.crclMlMin!.toStringAsFixed(1);
    final eq = res.calculationInputs['renalEquationUsed'] as String?;
    final strat = res.calculationInputs['crclWeightStrategy'] as String?;
    final wt = (res.calculationInputs['crclWeightUsedKg'] as num?)?.toDouble();

    if (eq == 'Bedside Schwartz') {
      return 'CrCl: $crclStr mL/min/1.73m² (Schwartz)';
    }
    if (eq == 'Cockcroft-Gault' && strat != null && wt != null) {
      return 'CrCl: $crclStr mL/min (CG • $strat ${wt.toStringAsFixed(1)} kg)';
    }
    return 'CrCl: $crclStr mL/min';
  }
}

/// Evaluates whether the drug warrants Narrow Therapeutic Index (NTI) monitoring,
/// therapeutic drug monitoring (TDM), or pharmacokinetic simulation.
bool isNtiOrSimulationCandidate(
  Drug drug,
  DosingRegimen? regimen,
  DosageResult? result,
) {
  // 1. Explicit TDM flag
  if (drug.requiresTDM) return true;

  // 2. Narrow Therapeutic Index (NTI) Drugs
  final id = drug.id.toLowerCase();
  final name = drug.genericName.toLowerCase();
  const ntiKeywords = [
    'vancomycin',
    'gentamicin',
    'amikacin',
    'tobramycin',
    'phenytoin',
    'digoxin',
    'lithium',
    'theophylline',
    'aminophylline',
    'carbamazepine',
    'valproic',
    'valproate',
    'tacrolimus',
    'cyclosporine',
  ];
  if (ntiKeywords.any((k) => id.contains(k) || name.contains(k))) {
    return true;
  }

  // 3. Continuous Vasoactive & Inotropic Infusions
  if (drug.category == DrugCategory.vasopressor) {
    return true;
  }
  const vasoKeywords = [
    'norepinephrine',
    'noradrenaline',
    'epinephrine',
    'adrenaline',
    'dopamine',
    'dobutamine',
    'nicardipine',
    'nitroglycerin',
  ];
  if (vasoKeywords.any((k) => id.contains(k) || name.contains(k))) {
    return true;
  }

  // 4. Any continuous IV infusion regimen or active titrated result
  if (regimen?.route == DoseRoute.ivInfusion ||
      result?.infusionResult != null) {
    return true;
  }

  return false;
}

