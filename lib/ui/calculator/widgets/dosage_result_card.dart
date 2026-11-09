import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../../../data/patient_session.dart';
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
              Text(
                t
                    ? 'อัตราการหยดยา (Titrated Infusion)'
                    : 'Titrated Infusion Rate',
                style: TextStyle(
                  color: Colors.teal.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                res.infusionResult!.rateMax != null &&
                        res.infusionResult!.rateMax! > res.infusionResult!.rate
                    ? '${res.infusionResult!.rate}–${res.infusionResult!.rateMax} ${res.infusionResult!.rateUnit.symbol}'
                    : '${res.infusionResult!.rate} ${res.infusionResult!.rateUnit.symbol}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (res.infusionResult!.rateMlPerHr != null)
                Text(
                  res.infusionResult!.rateMlPerHrMax != null &&
                          res.infusionResult!.rateMlPerHrMax! >
                              res.infusionResult!.rateMlPerHr!
                      ? 'Pump Rate: ${res.infusionResult!.rateMlPerHr!.toStringAsFixed(1)}–${res.infusionResult!.rateMlPerHrMax!.toStringAsFixed(1)} mL/hr'
                      : 'Pump Rate: ${res.infusionResult!.rateMlPerHr!.toStringAsFixed(1)} mL/hr',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ] else if (res.roundedDose != null) ...[
              Text(
                t
                    ? 'ขนาดยาที่แนะนำ (ปัดเศษแล้ว)'
                    : 'Recommended Dose (Rounded)',
                style: TextStyle(
                  color: Colors.green.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${res.roundedDose?.toStringAsFixed(2)} ${res.doseUnit?.symbol}',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                res.frequency ?? '',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '(คำนวณได้: ${res.calculatedDose?.toStringAsFixed(2)} ${res.doseUnit?.symbol})',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ] else ...[
              Text(
                '${res.calculatedDose?.toStringAsFixed(2)} ${res.doseUnit?.symbol}',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
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

