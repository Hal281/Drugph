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

    // Step 1: Renal Function
    if (res.crclMlMin != null) {
      final sexStr = widget.state.sex == Sex.female ? ' × 0.85' : '';
      steps.add(_BreakdownStep(
        title: t
            ? 'การประเมินการทำงานของไต (Cockcroft-Gault CrCl)'
            : 'Renal Function Evaluation (Cockcroft-Gault)',
        detail:
            'CrCl = [(140 - Age) × Weight] / (72 × SCr)$sexStr = ${res.crclMlMin!.toStringAsFixed(1)} mL/min',
      ));
    }

    // Step 2: Weight selection
    if (widget.state.dosingWeightLabel != null &&
        widget.state.dosingWeightValue != null) {
      steps.add(_BreakdownStep(
        title: t
            ? 'เกณฑ์การเลือกน้ำหนัก (Dosing Weight)'
            : 'Dosing Weight Strategy',
        detail:
            '${widget.state.dosingWeightLabel} = ${widget.state.dosingWeightValue!.toStringAsFixed(1)} kg (${widget.state.dosingWeightReason ?? ""})',
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

    return steps;
  }
}

class _BreakdownStep {
  final String title;
  final String detail;

  const _BreakdownStep({required this.title, required this.detail});
}
