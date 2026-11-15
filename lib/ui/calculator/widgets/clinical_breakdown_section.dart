import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../models/calculator_ui_state.dart';

/// MDCalc-style transparent step-by-step formula breakdown accordion.
///
/// Shows clinical mathematical derivation:
/// 1. Cockcroft-Gault CrCl equation substitution
/// 2. Dosing weight strategy rationale (TBW vs IBW vs AdjBW)
/// 3. Weight-based / BSA-based formula multiplication
/// 4. Renal adjustment factor & limits capping
/// 5. Formulary rounding discrepancy
class ClinicalBreakdownSection extends StatefulWidget {
  final CalculatorUiState state;
  final bool isThai;
  final bool initiallyExpanded;

  const ClinicalBreakdownSection({
    super.key,
    required this.state,
    required this.isThai,
    this.initiallyExpanded = false,
  });

  @override
  State<ClinicalBreakdownSection> createState() =>
      _ClinicalBreakdownSectionState();
}

class _ClinicalBreakdownSectionState extends State<ClinicalBreakdownSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.isThai;
    final res = widget.state.result;
    final reg = widget.state.selectedRegimen;

    if (res == null && reg == null) {
      return const SizedBox.shrink();
    }

    final steps = _buildSteps(t);

    return Card(
      key: const Key('clinical_breakdown_card'),
      elevation: 0,
      margin: const EdgeInsets.only(top: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
      ),
      color: Colors.white,
      child: Column(
        children: [
          InkWell(
            key: const Key('clinical_breakdown_accordion'),
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calculate_outlined,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t
                              ? 'แสดงวิธีคำนวณและสูตรทีละขั้นตอน (MDCalc-style Math)'
                              : 'Step-by-Step Clinical Math Breakdown',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          res != null
                              ? '${t ? "สูตรที่ใช้" : "Formula"}: ${res.formulaUsed}'
                              : (reg != null
                                  ? '${t ? reg.dosingType.nameTh : reg.dosingType.nameEn} (${reg.route.abbreviation})'
                                  : ''),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(color: Color(0xFFE2E8F0), height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: steps.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final step = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$idx',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E40AF),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                step.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                step.detail,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF334155),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<_BreakdownStep> _buildSteps(bool t) {
    final steps = <_BreakdownStep>[];
    final res = widget.state.result;
    final reg = widget.state.selectedRegimen;

    if (res == null) {
      if (reg != null) {
        steps.add(_BreakdownStep(
          title: t ? 'สูตรยาที่เลือก' : 'Selected Regimen',
          detail:
              '${reg.indication ?? "Standard"} • ${t ? reg.dosingType.nameTh : reg.dosingType.nameEn} • ${t ? reg.route.nameTh : reg.route.nameEn}',
        ));
        steps.add(_BreakdownStep(
          title: t ? 'รอการกดคำนวณ' : 'Awaiting Calculation',
          detail: t
              ? 'กรุณากรอกข้อมูลน้ำหนัก ส่วนสูง และค่าไต แล้วกดปุ่ม "คำนวณโดสยา"'
              : 'Please enter patient parameters and tap "Calculate Dose".',
        ));
      }
      return steps;
    }

    final inputs = res.calculationInputs;
    final renalEq = inputs['renalEquationUsed'] as String?;
    final age = (inputs['ageYears'] as num?)?.toInt() ?? widget.state.ageYears;
    final scr =
        (inputs['serumCreatinineMgDl'] as num?)?.toDouble() ?? widget.state.scrMgDl;
    final height =
        (inputs['heightCm'] as num?)?.toDouble() ?? widget.state.heightCm;
    final tbw =
        (inputs['weightKg'] as num?)?.toDouble() ?? widget.state.weightKg;
    final crclWt = (inputs['crclWeightUsedKg'] as num?)?.toDouble() ??
        widget.state.dosingWeightValue;
    final crclStrat = inputs['crclWeightStrategy'] as String? ?? 'Weight';
    final effectiveAdjBw =
        res.adjBwKg ?? (inputs['adjBwKg'] as num?)?.toDouble();

    // Step 1: Renal Function
    if (res.crclMlMin != null) {
      if (renalEq == 'Bedside Schwartz' && height != null && scr != null) {
        final scrStr =
            scr == scr.roundToDouble() ? scr.toStringAsFixed(1) : scr.toString();
        steps.add(_BreakdownStep(
          title: t
              ? 'การประเมินการทำงานของไตเด็ก (Bedside Schwartz eGFR)'
              : 'Renal Function Evaluation (Bedside Schwartz eGFR)',
          detail:
              'eGFR = (0.413 × ${height.toStringAsFixed(1)} cm) / $scrStr = ${res.crclMlMin!.toStringAsFixed(1)} mL/min/1.73m²',
        ));
      } else if (renalEq == 'RRT Protocol') {
        steps.add(_BreakdownStep(
          title: t
              ? 'การประเมินการทำงานของไต (เกณฑ์ RRT)'
              : 'Renal Function Evaluation (RRT Protocol)',
          detail: t
              ? 'ประเมินร่วมกับการบำบัดทดแทนไต (CrCl เทียบเท่า: ${res.crclMlMin!.toStringAsFixed(1)} mL/min)'
              : 'Evaluated under active RRT (${res.crclMlMin!.toStringAsFixed(1)} mL/min equivalent)',
        ));
      } else if (renalEq == 'Manual CrCl') {
        steps.add(_BreakdownStep(
          title: t
              ? 'การประเมินการทำงานของไต (Manual CrCl)'
              : 'Renal Function Evaluation (Manual CrCl)',
          detail: 'Manual CrCl = ${res.crclMlMin!.toStringAsFixed(1)} mL/min',
        ));
      } else {
        final sexStr = widget.state.sex == Sex.female ? ' × 0.85' : '';
        final detailStr = (age != null && crclWt != null && scr != null)
            ? 'CrCl = [(140 - $age) × ${crclWt.toStringAsFixed(1)} kg ($crclStrat)] / (72 × ${scr == scr.roundToDouble() ? scr.toStringAsFixed(1) : scr.toString()})$sexStr = ${res.crclMlMin!.toStringAsFixed(1)} mL/min'
            : 'CrCl = [(140 - Age) × Weight] / (72 × SCr)$sexStr = ${res.crclMlMin!.toStringAsFixed(1)} mL/min';
        steps.add(_BreakdownStep(
          title: t
              ? 'การประเมินการทำงานของไต (Cockcroft-Gault CrCl)'
              : 'Renal Function Evaluation (Cockcroft-Gault)',
          detail: detailStr,
        ));
      }
    }

    // Step 2: Weight selection
    if (widget.state.dosingWeightLabel != null &&
        widget.state.dosingWeightValue != null) {
      final metricsParts = <String>[
        if (tbw != null) 'TBW: ${tbw.toStringAsFixed(1)} kg',
        if (res.ibwKg != null) 'IBW: ${res.ibwKg!.toStringAsFixed(1)} kg',
        if (effectiveAdjBw != null)
          'AdjBW: ${effectiveAdjBw.toStringAsFixed(1)} kg',
      ];
      final metricsLine =
          metricsParts.isNotEmpty ? '\n${metricsParts.join(' • ')}' : '';
      steps.add(_BreakdownStep(
        title: t
            ? 'เกณฑ์การเลือกน้ำหนัก (Dosing Weight)'
            : 'Dosing Weight Strategy',
        detail:
            '${widget.state.dosingWeightLabel} = ${widget.state.dosingWeightValue!.toStringAsFixed(1)} kg (${widget.state.dosingWeightReason ?? ""})$metricsLine',
      ));
    }

    // Step 3: Calculation equation
    if (res.calculatedDose != null) {
      steps.add(_BreakdownStep(
        title: t
            ? 'การแทนค่าในสมการหลัก (Primary Calculation)'
            : 'Primary Equation Substitution',
        detail:
            '${res.formulaUsed} ➔ ขนาดยาดิบ: ${res.calculatedDose} ${res.doseUnit?.symbol ?? ""}',
      ));
    }

    // Step 4: Infusion or Formulary Rounding
    if (res.infusionResult != null) {
      steps.add(_BreakdownStep(
        title: t ? 'อัตราการหยดยา (Infusion Titration)' : 'Infusion Titration',
        detail:
            '${res.infusionResult!.rate} ${res.infusionResult!.rateUnit.symbol}${res.infusionResult!.rateMlPerHr != null ? " (Pump Rate: ${res.infusionResult!.rateMlPerHr!.toStringAsFixed(1)} mL/hr)" : ""}',
      ));
    } else if (res.roundedDose != null) {
      steps.add(_BreakdownStep(
        title: t
            ? 'การปัดเศษยาตามขนาดเม็ด/หลอดจริง (Formulary Rounding)'
            : 'Formulary Rounding Discrepancy',
        detail:
            'เทียบขนาดยาในคลัง ➔ ปัดเป็น: ${res.roundedDose} ${res.doseUnit?.symbol ?? ""}',
      ));
    }

    // Step 5: Oral Liquid Conversion or IV Reconstitution & Infusion (R1, R2)
    if (res.teaspoons != null && res.volumeMl != null) {
      steps.add(_BreakdownStep(
        title: t
            ? 'การแปลงขนาดยาน้ำรับประทาน (Oral Liquid & Household Volume)'
            : 'Oral Liquid Formulation Conversion',
        detail:
            'ขนาดยา ${res.calculatedDose} ${res.doseUnit?.symbol ?? "mg"} ÷ ความเข้มข้น (${res.liquidConcentrationLabel ?? ""}) ➔ ${res.volumeMl!.toStringAsFixed(1)} mL (เทียบเท่า ${res.teaspoons!.toStringAsFixed(1)} ช้อนชา)',
      ));
    } else if (res.vialDrawVolumeMl != null) {
      steps.add(_BreakdownStep(
        title: t
            ? 'การละลายผงยาและดูดยาฉีด (Vial Reconstitution & Draw)'
            : 'Vial Reconstitution & Draw',
        detail:
            'ขนาดยา ${res.calculatedDose} ${res.doseUnit?.symbol ?? "mg"} ÷ ${res.reconstitutionConcentrationMgPerMl ?? ""} mg/mL ➔ ดูดยา ${res.vialDrawVolumeMl!.toStringAsFixed(1)} mL${res.vialsNeeded != null ? " (${res.vialsNeeded} ขวด)" : ""}',
      ));
    }
    if (res.infusionRateMlPerHr != null && res.infusionResult == null) {
      steps.add(_BreakdownStep(
        title: t
            ? 'อัตราเครื่องหยดยาเข้าหลอดเลือดดำ (IV Infusion Pump Rate)'
            : 'IV Infusion Pump Rate',
        detail:
            'สารน้ำ ${res.totalInfusionVolumeMl?.toStringAsFixed(0) ?? res.volumeMl?.toStringAsFixed(0) ?? ""} mL ÷ ${res.infusionDurationMinutes?.toStringAsFixed(0) ?? "60"} นาที ➔ ตั้งเครื่อง ${res.infusionRateMlPerHr!.toStringAsFixed(1)} mL/hr${res.dripRateDropsPerMin != null ? " (หยดน้ำเกลือ ${res.dripRateDropsPerMin!.toStringAsFixed(0)} gtt/min)" : ""}',
      ));
    }

    return steps;
  }
}

class _BreakdownStep {
  final String title;
  final String detail;

  const _BreakdownStep({required this.title, required this.detail});
}
