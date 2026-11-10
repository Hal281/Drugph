import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../../../data/patient_session.dart';
import '../../iv_titration_screen.dart';
import '../../pkpd/pkpd_simulation_sheet.dart';
import '../../tdm_screen.dart';
import '../../widgets/clinical_evidence_sheet.dart';
import '../models/calculator_ui_state.dart';
import 'clinical_action_bar.dart';
import 'safety_alert_banner.dart';

/// Primary Clinical Dosage Result Card.
///
/// Encapsulates:
/// - Semantic alert coloring (Green verified, Amber warnings, Red critical)
/// - Non-blocking overdose banner and critical contraindication banners
/// - Dosing display (rounded formulary dose with raw strikethrough, or titrated infusion rate)
/// - CrCl clearance badge & bedside RRT modality badges
/// - Monograph drawer and TDM calculator triggers
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

    final cardBgColor = hasHardWarnings
        ? Colors.red.shade50
        : (hasSoftWarnings ? Colors.amber.shade50 : Colors.green.shade50);
    final cardBorderColor = hasHardWarnings
        ? Colors.red.shade700
        : (hasSoftWarnings ? Colors.amber.shade800 : Colors.green);
    final headerIcon = hasHardWarnings
        ? Icons.error
        : (hasSoftWarnings ? Icons.warning_amber_rounded : Icons.check_circle);
    final headerIconColor = hasHardWarnings
        ? Colors.red.shade700
        : (hasSoftWarnings ? Colors.amber.shade900 : Colors.green);
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
      color: cardBgColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: cardBorderColor, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(headerIcon, color: headerIconColor),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    headerTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: headerIconColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

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
                      : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isOverdose
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF86EFAC),
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
                        ? const Color(0xFF7F1D1D)
                        : const Color(0xFF14532D),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${res.roundedDose?.toStringAsFixed(2)} ${res.doseUnit?.symbol}',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (res.frequency != null && res.frequency!.isNotEmpty)
                Text(
                  res.frequency!,
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.bold,
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
                      color: Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Text(
                      t
                          ? 'ขนาดยาคำนวณจริงก่อนปัดเศษ: ${res.calculatedDose?.toStringAsFixed(2)} ${res.doseUnit?.symbol}'
                          : 'Raw Calculated Dose: ${res.calculatedDose?.toStringAsFixed(2)} ${res.doseUnit?.symbol}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade900,
                      ),
                    ),
                  ),
                ),
              ],
            ] else ...[
              if (isOverdose)
                Container(
                  key: const Key('dosage_result_status_label'),
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFEF4444),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    t
                        ? 'ขนาดยาจากการคำนวณ (เกินเกณฑ์แนะนำ)'
                        : 'Calculated Dose (Exceeds Limit)',
                    style: const TextStyle(
                      color: Color(0xFF7F1D1D),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${res.calculatedDose?.toStringAsFixed(2)} ${res.doseUnit?.symbol}',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (res.frequency != null)
                Text(
                  res.frequency!,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],

            // Multi-Phase Regimen / Antidote Protocol (e.g. N-Acetylcysteine 3-Bag Regimen)
            if (res.activePhases != null && res.activePhases!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildMultiPhaseAntidoteSection(context, res, t),
            ],

            // Volume to Administer Badge (High Visibility for Resuscitation / Bedside Nurses)
            if (res.volumeMl != null) ...[
              const SizedBox(height: 10),
              Container(
                key: const Key('dosage_result_volume_badge'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade300, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.vaccines,
                      color: Colors.blue.shade800,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        t
                            ? 'ปริมาตรยาที่ต้องบริหาร: ${res.volumeMl! < 1.0 ? res.volumeMl!.toStringAsFixed(2) : res.volumeMl!.toStringAsFixed(1)} mL'
                            : 'Volume to Administer: ${res.volumeMl! < 1.0 ? res.volumeMl!.toStringAsFixed(2) : res.volumeMl!.toStringAsFixed(1)} mL',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // CrCl Badge
            if (res.crclMlMin != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text(
                  'CrCl: ${res.crclMlMin!.toStringAsFixed(1)} mL/min',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],

            // RRT Result Badges
            _buildRrtResultBadges(res, t),
            const SizedBox(height: 12),

            // Monograph Button
            OutlinedButton.icon(
              key: const Key('calculator_view_monograph_btn'),
              icon: const Icon(Icons.menu_book, size: 18),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  t
                      ? 'เปิดดูข้อมูลยาในตำราอ้างอิง'
                      : 'View Textbook Monograph',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 48), // WCAG AAA >= 48dp touch target
                foregroundColor: Colors.teal.shade800,
                side: BorderSide(color: Colors.teal.shade300, width: 1.2),
                backgroundColor: Colors.white.withValues(alpha: 0.8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () => ClinicalEvidenceSheet.show(
                context,
                drug: state.drug,
                regimen: state.selectedRegimen,
                isThai: t,
              ),
            ),

            // Dynamic NTI & Continuous Infusion PK-PD Modeling Action Button
            if (isNtiOrSimulationCandidate(state.drug, state.selectedRegimen, res)) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const Key('calculator_open_pkpd_btn'),
                  icon: const Icon(Icons.show_chart_rounded, size: 22),
                  label: Text(
                    t
                        ? '📈 เปิดแบบจำลอง PK-PD & กราฟทำนายระดับยา'
                        : '📈 PK-PD Simulation & Predictive Curve',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6D28D9), // Vibrant Violet
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 48), // WCAG AAA >= 48dp touch target
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
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
              const SizedBox(height: 16),
              ElevatedButton.icon(
                key: const Key('calculator_open_tdm_btn'),
                icon: const Icon(Icons.bar_chart),
                label: Text(t ? 'เครื่องมือคำนวณ TDM' : 'TDM Calculator'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
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
            ],

            const SizedBox(height: 16),

            // Side-by-side Dual Copy Action Bar
            ClinicalActionBar(
              state: state,
              isThai: t,
              onBuildPatient: onBuildPatient,
            ),

            // Warning Details List
            if (state.warnings.isNotEmpty) ...[
              const SizedBox(height: 20),
              ...state.warnings.map(
                (w) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: w.severity == LimitSeverity.hard
                        ? Colors.red.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: w.severity == LimitSeverity.hard
                          ? Colors.red
                          : Colors.orange,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        w.severity.icon,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t ? w.messageTh : w.messageEn,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            height: 1.3,
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
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.teal.shade400, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sync_rounded,
                        color: Colors.teal.shade800,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          t
                              ? 'CRRT: เฝ้าระวังระดับยาต่อเนื่อง'
                              : 'CRRT: Continuous Dialysis Mode',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.teal.shade900,
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
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.deepPurple.shade400,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_filled,
                        color: Colors.deepPurple.shade800,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          t
                              ? 'Post-HD: ให้ยาหลังการฟอกเลือด'
                              : 'Post-HD: Administer after dialysis',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.deepPurple.shade900,
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
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.indigo.shade300, width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bloodtype,
                        color: Colors.indigo.shade800,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          t
                              ? 'IHD: ฟอกเลือดด้วยไตเทียม'
                              : 'IHD: Hemodialysis Mode',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.indigo.shade900,
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
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.blue.shade300, width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.swap_horiz_rounded,
                        color: Colors.blue.shade800,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          t
                              ? 'CAPD: ล้างไตทางช่องท้อง'
                              : 'CAPD: Peritoneal Dialysis',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.blue.shade900,
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
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      (t
                              ? (res.rrtInstructionTh ?? res.rrtInstructionEn)
                              : (res.rrtInstructionEn ??
                                  res.rrtInstructionTh)) ??
                          '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade800,
                        height: 1.3,
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdose ? const Color(0xFFEF4444) : Colors.teal.shade300,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isOverdose ? Colors.red : Colors.teal).withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Clinical Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isOverdose ? const Color(0xFFFEE2E2) : Colors.teal.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isOverdose ? const Color(0xFFF87171) : Colors.teal.shade200,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.medical_services_outlined,
                  size: 14,
                  color: isOverdose ? const Color(0xFF7F1D1D) : Colors.teal.shade800,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    t ? 'ขนาดยา (Dose Rate)' : 'Clinical Dose Rate',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isOverdose ? const Color(0xFF7F1D1D) : Colors.teal.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Numeric Rate Display
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Text(
              doseRateStr,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isOverdose ? const Color(0xFF7F1D1D) : Colors.teal.shade900,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Descriptor
          Text(
            t ? 'ขนาดยาตามน้ำหนักตัว' : 'Patient-normalized rate',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Clinical Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.indigo.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.speed_rounded,
                  size: 14,
                  color: Colors.indigo.shade800,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    t ? 'อัตราหยดเครื่อง (Pump Rate)' : 'Bedside Pump Rate',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Numeric Pump Rate Display (Maintains exact 'Pump Rate: X mL/hr' for test compatibility)
          if (inf.rateMlPerHr != null) ...[
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                inf.rateMlPerHrMax != null &&
                        inf.rateMlPerHrMax! > inf.rateMlPerHr!
                    ? 'Pump Rate: ${inf.rateMlPerHr!.toStringAsFixed(1)}–${inf.rateMlPerHrMax!.toStringAsFixed(1)} mL/hr'
                    : 'Pump Rate: ${inf.rateMlPerHr!.toStringAsFixed(1)} mL/hr',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade900,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              t ? 'ตั้งค่าเครื่อง Infusion Pump' : 'Volumetric pump setting',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else ...[
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                t ? 'ไม่ระบุความเข้มข้น' : 'No Std Dilution',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade900,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              t ? 'โปรดตรวจสอบคู่มือผสมยา' : 'Consult monograph',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.amber.shade800,
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
      return 'ไม่พบข้อมูลความเข้มข้นสารน้ำมาตรฐาน (No standard dilution)';
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.medication_liquid_rounded,
                  color: Colors.indigo.shade800,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t
                      ? 'โปรโตคอลการบริหารยาแบบหลายขั้นตอน (Sequential Protocol)'
                      : 'Multi-Phase Sequential Protocol',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade900,
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

