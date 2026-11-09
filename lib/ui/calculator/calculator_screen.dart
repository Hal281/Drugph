import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../data/prescription_cart.dart';
import '../widgets/clinical_evidence_sheet.dart';
import 'controllers/calculator_controller.dart';
import 'models/calculator_ui_state.dart';
import 'widgets/clinical_breakdown_section.dart';
import 'widgets/clinical_header_alerts.dart';
import 'widgets/copy_ready_note_card.dart';
import 'widgets/dosage_result_card.dart';
import 'widgets/dosing_parameters_form.dart';
import 'widgets/dosing_weight_logic_card.dart';
import 'widgets/iv_diluent_compatibility_card.dart';
import 'widgets/patient_clinical_header.dart';
import 'widgets/regimen_selector_section.dart';
import 'widgets/sticky_calculate_bar.dart';

/// Clinical Calculator Dashboard Screen (Clean Architecture Orchestrator).
///
/// Implements:
/// - Responsive Dual-Pane Split View for widescreen devices (> 800px)
/// - Single-column mobile layout with sticky calculation bar (<= 800px)
/// - MDCalc transparent step-by-step formula breakdown
/// - Lexicomp indication-driven regimen selector & renal/hepatic badges
/// - 4 explicit UI states: Loading, Active, Empty, Warning/Error
/// - Rule 5 Non-blocking Overdose Policy
class CalculatorScreen extends StatefulWidget {
  final Drug drug;
  final bool isThai;
  final Color categoryColor;

  const CalculatorScreen({
    super.key,
    required this.drug,
    required this.isThai,
    this.categoryColor = Colors.teal,
  });

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  late final CalculatorController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CalculatorController(drug: widget.drug);
    _controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _handleCalculate() {
    FocusScope.of(context).unfocus();
    final valResult = _controller.calculate(isThai: widget.isThai);
    if (!valResult.isValid) {
      _showErrorDialog(
        widget.isThai ? 'ข้อมูลไม่ถูกต้อง' : 'Invalid Input',
        (widget.isThai ? valResult.errorsTh.values : valResult.errorsEn.values)
            .join('\n'),
      );
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title, style: const TextStyle(color: Colors.red)),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.isThai;
    final state = _controller.state;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(widget.drug.genericName),
        backgroundColor: widget.categoryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: t ? 'ดูข้อมูลจากตำราอ้างอิง' : 'View Textbook Monograph',
            onPressed: () => ClinicalEvidenceSheet.show(
              context,
              drug: widget.drug,
              regimen: state.selectedRegimen,
              isThai: t,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_shopping_cart),
            tooltip: t ? 'เพิ่มลงตะกร้ายา' : 'Add to Cart',
            onPressed: () {
              PrescriptionCart.instance.addDrug(widget.drug);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    t
                        ? 'เพิ่ม ${widget.drug.genericName} ลงตะกร้าแล้ว'
                        : 'Added ${widget.drug.genericName} to cart',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          if (isWide) {
            return _buildWideLayout(state);
          } else {
            return _buildMobileLayout(state);
          }
        },
      ),
    );
  }

  /// Widescreen Desktop / Tablet Dual-Pane Split View (> 800px).
  Widget _buildWideLayout(CalculatorUiState state) {
    final t = widget.isThai;

    return Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Pane: Clinical Drug Info, Patient Inputs, & Regimen Selection
            Expanded(
              flex: 5,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClinicalHeaderAlerts(
                      drug: widget.drug,
                      selectedRegimen: state.selectedRegimen,
                      isThai: t,
                      categoryColor: widget.categoryColor,
                    ),
                    const SizedBox(height: 16),
                    PatientClinicalHeader(
                      state: state,
                      isThai: t,
                      categoryColor: widget.categoryColor,
                    ),
                    RegimenSelectorSection(
                      drug: widget.drug,
                      selectedRegimen: state.selectedRegimen,
                      onRegimenChanged: _controller.selectRegimen,
                      isThai: t,
                      categoryColor: widget.categoryColor,
                    ),
                    if (state.shouldShowIvDiluentCard) ...[
                      const SizedBox(height: 16),
                      IvDiluentCompatibilityCard(
                        drug: widget.drug,
                        selectedRegimen: state.selectedRegimen!,
                        isThai: t,
                      ),
                    ],
                    const SizedBox(height: 16),
                    DosingParametersForm(
                      weightCtrl: _controller.weightCtrl,
                      heightCtrl: _controller.heightCtrl,
                      ageCtrl: _controller.ageCtrl,
                      scrCtrl: _controller.scrCtrl,
                      isScrStable: state.isScrStable,
                      onScrStableChanged: _controller.setScrStable,
                      renalReplacementMode: state.renalReplacementMode,
                      onRrtChanged: _controller.setRenalReplacementMode,
                      hepaticImpairment: state.hepaticImpairment,
                      lastChildPughScore: state.lastChildPughScore,
                      onHepaticChanged: (cp, score) =>
                          _controller.setHepaticImpairment(cp, score: score),
                      sex: state.sex,
                      onSexChanged: _controller.setSex,
                      isThai: t,
                      categoryColor: widget.categoryColor,
                    ),
                  ],
                ),
              ),
            ),
            // Vertical Divider
            VerticalDivider(width: 1, color: Colors.grey.shade300),
            // Right Pane: Transparent Calculation Breakdown, Results, & Actions
            Expanded(
              flex: 6,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (state.status == CalculatorUiStatus.loading)
                      _buildLoadingSkeleton()
                    else if (state.hasCalculatedResult) ...[
                      DosageResultCard(
                        state: state,
                        isThai: t,
                        onBuildPatient: _controller.buildCurrentPatient,
                      ),
                      const SizedBox(height: 16),
                      ClinicalBreakdownSection(
                        state: state,
                        isThai: t,
                        initiallyExpanded: true,
                      ),
                      if (state.dosingWeightLabel != null &&
                          state.dosingWeightValue != null) ...[
                        const SizedBox(height: 16),
                        DosingWeightLogicCard(
                          label: state.dosingWeightLabel,
                          value: state.dosingWeightValue,
                          reason: state.dosingWeightReason,
                          isThai: t,
                        ),
                      ],
                      const SizedBox(height: 16),
                      CopyReadyNoteCard(
                        state: state,
                        isThai: t,
                        onBuildPatient: _controller.buildCurrentPatient,
                      ),
                    ] else ...[
                      _buildEmptyGuidanceCard(t),
                      ClinicalBreakdownSection(
                        state: state,
                        isThai: t,
                        initiallyExpanded: false,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        // Sticky bottom calculate bar
        StickyCalculateBar(
          drug: widget.drug,
          selectedRegimen: state.selectedRegimen,
          onCalculate: _handleCalculate,
          isThai: t,
          categoryColor: widget.categoryColor,
        ),
      ],
    );
  }

  /// Compact Mobile Layout (<= 800px) with Sticky Bottom Calculate Bar.
  Widget _buildMobileLayout(CalculatorUiState state) {
    final t = widget.isThai;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClinicalHeaderAlerts(
                drug: widget.drug,
                selectedRegimen: state.selectedRegimen,
                isThai: t,
                categoryColor: widget.categoryColor,
              ),
              const SizedBox(height: 16),
              PatientClinicalHeader(
                state: state,
                isThai: t,
                categoryColor: widget.categoryColor,
              ),
              RegimenSelectorSection(
                drug: widget.drug,
                selectedRegimen: state.selectedRegimen,
                onRegimenChanged: _controller.selectRegimen,
                isThai: t,
                categoryColor: widget.categoryColor,
              ),
              if (state.shouldShowIvDiluentCard) ...[
                const SizedBox(height: 16),
                IvDiluentCompatibilityCard(
                  drug: widget.drug,
                  selectedRegimen: state.selectedRegimen!,
                  isThai: t,
                ),
              ],
              const SizedBox(height: 16),
              DosingParametersForm(
                weightCtrl: _controller.weightCtrl,
                heightCtrl: _controller.heightCtrl,
                ageCtrl: _controller.ageCtrl,
                scrCtrl: _controller.scrCtrl,
                isScrStable: state.isScrStable,
                onScrStableChanged: _controller.setScrStable,
                renalReplacementMode: state.renalReplacementMode,
                onRrtChanged: _controller.setRenalReplacementMode,
                hepaticImpairment: state.hepaticImpairment,
                lastChildPughScore: state.lastChildPughScore,
                onHepaticChanged: (cp, score) =>
                    _controller.setHepaticImpairment(cp, score: score),
                sex: state.sex,
                onSexChanged: _controller.setSex,
                isThai: t,
                categoryColor: widget.categoryColor,
              ),
              const SizedBox(height: 16),
              if (state.status == CalculatorUiStatus.loading)
                _buildLoadingSkeleton()
              else if (state.hasCalculatedResult) ...[
                DosageResultCard(
                  state: state,
                  isThai: t,
                  onBuildPatient: _controller.buildCurrentPatient,
                ),
                ClinicalBreakdownSection(
                  state: state,
                  isThai: t,
                  initiallyExpanded: false,
                ),
                if (state.dosingWeightLabel != null &&
                    state.dosingWeightValue != null) ...[
                  const SizedBox(height: 16),
                  DosingWeightLogicCard(
                    label: state.dosingWeightLabel,
                    value: state.dosingWeightValue,
                    reason: state.dosingWeightReason,
                    isThai: t,
                  ),
                ],
                const SizedBox(height: 16),
                CopyReadyNoteCard(
                  state: state,
                  isThai: t,
                  onBuildPatient: _controller.buildCurrentPatient,
                ),
              ] else ...[
                _buildEmptyGuidanceCard(t),
                ClinicalBreakdownSection(
                  state: state,
                  isThai: t,
                  initiallyExpanded: false,
                ),
              ],
            ],
          ),
        ),
        // Sticky Bottom Calculate Bar
        StickyCalculateBar(
          drug: widget.drug,
          selectedRegimen: state.selectedRegimen,
          onCalculate: _handleCalculate,
          isThai: t,
          categoryColor: widget.categoryColor,
        ),
      ],
    );
  }

  /// Empty Guidance State card prompt.
  Widget _buildEmptyGuidanceCard(bool t) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            Icon(
              Icons.calculate_outlined,
              size: 44,
              color: widget.categoryColor.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              t
                  ? 'เลือกสูตรยาและกรอกข้อมูลผู้ป่วยเพื่อเริ่มการคำนวณ'
                  : 'Select a Regimen and Enter Patient Parameters',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey.shade800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              t
                  ? 'ระบุน้ำหนัก ส่วนสูง อายุ และค่าไต แล้วกดปุ่ม "คำนวณโดสยา" ด้านล่าง'
                  : 'Specify weight, height, age, and SCr then tap "Calculate Dose" below.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shimmer / Loading skeleton placeholder.
  Widget _buildLoadingSkeleton() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            widget.isThai
                ? 'กำลังประมวลผลการคำนวณทางคลินิก...'
                : 'Processing clinical dosage calculations...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
