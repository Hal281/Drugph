import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../data/prescription_cart.dart';
import '../../data/patient_session.dart';
import '../theme/app_theme.dart';
import '../widgets/clinical_evidence_sheet.dart';
import 'controllers/calculator_controller.dart';
import 'models/calculator_ui_state.dart';
import 'widgets/clinical_breakdown_section.dart';
import 'widgets/clinical_header_alerts.dart';
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
/// - Responsive Dual-Pane Split View for widescreen devices (>= 960px)
/// - Single-column layout with sticky calculation bar (< 960px)
/// - Reactive real-time dose preview alongside explicit calculate logging
/// - MDCalc transparent step-by-step formula breakdown
/// - Lexicomp indication-driven regimen selector & interactive renal/hepatic links
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
    this.categoryColor = AppTheme.primaryTeal,
  });

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  late final CalculatorController _controller;
  bool _isRecomputing = false;

  @override
  void initState() {
    super.initState();
    _controller = CalculatorController(drug: widget.drug);
    _controller.addListener(_onControllerUpdate);
    _controller.weightCtrl.addListener(_onLiveInputChanged);
    _controller.heightCtrl.addListener(_onLiveInputChanged);
    _controller.ageCtrl.addListener(_onLiveInputChanged);
    _controller.scrCtrl.addListener(_onLiveInputChanged);
    PatientSession.instance.currentPatient.addListener(_onLiveInputChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (PatientSession.instance.currentPatient.value != null) {
        _triggerReactivePreview();
      }
    });
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _onLiveInputChanged() {
    _triggerReactivePreview();
  }

  void _triggerReactivePreview() {
    if (!mounted || _isRecomputing) return;
    _isRecomputing = true;
    try {
      _controller.recalculatePreview(isThai: widget.isThai);
    } finally {
      _isRecomputing = false;
    }
  }

  void _handleRegimenChanged(DosingRegimen? regimen) {
    _controller.selectRegimen(regimen);
    _triggerReactivePreview();
  }

  void _handleLiquidConcentrationChanged(OralLiquidConcentration? conc) {
    _controller.selectLiquidConcentration(conc);
    _triggerReactivePreview();
  }

  void _handleScrStableChanged(bool stable) {
    _controller.setScrStable(stable);
    _triggerReactivePreview();
  }

  void _handleRrtChanged(RenalReplacementMode mode) {
    _controller.setRenalReplacementMode(mode);
    _triggerReactivePreview();
  }

  void _handleHepaticChanged(ChildPughClass cp, int? score) {
    _controller.setHepaticImpairment(cp, score: score);
    _triggerReactivePreview();
  }

  void _handleSexChanged(Sex sex) {
    _controller.setSex(sex);
    _triggerReactivePreview();
  }

  @override
  void dispose() {
    PatientSession.instance.currentPatient.removeListener(_onLiveInputChanged);
    _controller.weightCtrl.removeListener(_onLiveInputChanged);
    _controller.heightCtrl.removeListener(_onLiveInputChanged);
    _controller.ageCtrl.removeListener(_onLiveInputChanged);
    _controller.scrCtrl.removeListener(_onLiveInputChanged);
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
            const Icon(Icons.error_outline, color: AppTheme.statusCritical),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: AppTheme.statusCritical),
              ),
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
    final drugClass = widget.drug.effectiveDrugClass;
    final drugClassName = t
        ? drugClass?.shortBadgeTh ?? widget.drug.category.nameTh
        : drugClass?.shortBadgeEn ?? widget.drug.category.nameEn;

    return Scaffold(
      backgroundColor: AppTheme.surfaceBackground,
      appBar: AppBar(
        title: Text(
          '${widget.drug.genericName} ($drugClassName)',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AppTheme.primaryTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: t ? 'ดูข้อมูลจากตำราอ้างอิง' : 'View Textbook Monograph',
            onPressed: () => ClinicalEvidenceSheet.show(
              context,
              drug: widget.drug,
              regimen: state.selectedRegimen,
              isThai: t,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_shopping_cart_outlined),
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
          final isWide = constraints.maxWidth >= 960;
          if (isWide) {
            return _buildWideLayout(state);
          } else {
            return _buildMobileLayout(state);
          }
        },
      ),
    );
  }

  Widget _buildRegimenSelector(CalculatorUiState state, bool t) {
    return RegimenSelectorSection(
      drug: widget.drug,
      selectedRegimen: state.selectedRegimen,
      selectedLiquidConcentration: state.selectedLiquidConcentration,
      patientAgeYears: state.usedDefaultDemographics
          ? null
          : (state.ageYears ??
              PatientSession.instance.currentPatient.value?.ageYears),
      patientWeightKg: state.usedDefaultDemographics
          ? null
          : (state.weightKg ??
              PatientSession.instance.currentPatient.value?.weightKg),
      onRegimenChanged: _handleRegimenChanged,
      onLiquidConcentrationChanged: _handleLiquidConcentrationChanged,
      isThai: t,
      categoryColor: AppTheme.primaryTeal,
    );
  }

  Widget _buildParametersForm(
    CalculatorUiState state,
    bool t,
    bool showDemographicInputs,
  ) {
    return DosingParametersForm(
      weightCtrl: _controller.weightCtrl,
      heightCtrl: _controller.heightCtrl,
      ageCtrl: _controller.ageCtrl,
      scrCtrl: _controller.scrCtrl,
      isScrStable: state.isScrStable,
      onScrStableChanged: _handleScrStableChanged,
      renalReplacementMode: state.renalReplacementMode,
      onRrtChanged: _handleRrtChanged,
      hepaticImpairment: state.hepaticImpairment,
      lastChildPughScore: state.lastChildPughScore,
      onHepaticChanged: _handleHepaticChanged,
      sex: state.sex,
      onSexChanged: _handleSexChanged,
      isThai: t,
      categoryColor: AppTheme.primaryTeal,
      inputRequirements: state.inputRequirements,
      showDemographicInputs: showDemographicInputs,
    );
  }

  List<Widget> _buildOutcomeAndGuidanceSection(
    CalculatorUiState state,
    bool t, {
    required bool isWide,
  }) {
    return [
      if (state.status == CalculatorUiStatus.loading)
        _buildLoadingSkeleton()
      else if (state.hasCalculatedResult)
        DosageResultCard(
          state: state,
          isThai: t,
          onBuildPatient: _controller.buildCurrentPatient,
        )
      else
        _buildEmptyGuidanceCard(t),
      if (state.shouldShowIvDiluentCard) ...[
        const SizedBox(height: 16),
        IvDiluentCompatibilityCard(
          drug: widget.drug,
          selectedRegimen: state.selectedRegimen!,
          isThai: t,
        ),
      ],
      const SizedBox(height: 16),
      ClinicalHeaderAlerts(
        drug: widget.drug,
        isThai: t,
        categoryColor: AppTheme.primaryTeal,
      ),
      const SizedBox(height: 8),
      ClinicalBreakdownSection(
        state: state,
        isThai: t,
        initiallyExpanded: isWide && state.hasCalculatedResult,
      ),
      if (state.hasCalculatedResult &&
          state.dosingWeightLabel != null &&
          state.dosingWeightValue != null) ...[
        const SizedBox(height: 16),
        DosingWeightLogicCard(
          label: state.dosingWeightLabel,
          value: state.dosingWeightValue,
          reason: state.dosingWeightReason,
          calculationInputs: state.result?.calculationInputs,
          isThai: t,
        ),
      ],
    ];
  }

  /// Widescreen Desktop / Tablet Dual-Pane Split View (>= 960px).
  Widget _buildWideLayout(CalculatorUiState state) {
    final t = widget.isThai;
    final showDemographicInputs =
        PatientSession.instance.currentPatient.value == null;
    final isReferenceOnly = widget.drug.tier == DrugTier.referenceOnly;

    return Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Pane: Patient Profile & Parameters
            Expanded(
              flex: 5,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTierBanner(t),
                    PatientClinicalHeader(
                      state: state,
                      isThai: t,
                      categoryColor: AppTheme.primaryTeal,
                    ),
                    if (!isReferenceOnly)
                      _buildParametersForm(state, t, showDemographicInputs),
                  ],
                ),
              ),
            ),
            const VerticalDivider(width: 1, color: AppTheme.borderDefault),
            // Right Pane: Indication/Regimen, Dose Output, Diluent, Safety Alerts, & Math Breakdown
            Expanded(
              flex: 6,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: isReferenceOnly
                      ? [
                          _buildReferenceOnlyCard(state, t),
                          const SizedBox(height: 16),
                          ClinicalHeaderAlerts(
                            drug: widget.drug,
                            isThai: t,
                            categoryColor: AppTheme.primaryTeal,
                          ),
                        ]
                      : [
                          _buildRegimenSelector(state, t),
                          const SizedBox(height: 16),
                          ..._buildOutcomeAndGuidanceSection(
                            state,
                            t,
                            isWide: true,
                          ),
                        ],
                ),
              ),
            ),
          ],
        ),
        if (!isReferenceOnly)
          StickyCalculateBar(
            drug: widget.drug,
            selectedRegimen: state.selectedRegimen,
            onCalculate: _handleCalculate,
            isThai: t,
            categoryColor: AppTheme.primaryTeal,
          ),
      ],
    );
  }

  /// Single-Column Clinical Flow (< 960px) with Sticky Bottom Calculate Bar.
  Widget _buildMobileLayout(CalculatorUiState state) {
    final t = widget.isThai;
    final showDemographicInputs =
        PatientSession.instance.currentPatient.value == null;
    final isReferenceOnly = widget.drug.tier == DrugTier.referenceOnly;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: isReferenceOnly
                ? [
                    _buildTierBanner(t),
                    _buildReferenceOnlyCard(state, t),
                    const SizedBox(height: 16),
                    ClinicalHeaderAlerts(
                      drug: widget.drug,
                      isThai: t,
                      categoryColor: AppTheme.primaryTeal,
                    ),
                  ]
                : [
                    _buildTierBanner(t),
                    PatientClinicalHeader(
                      state: state,
                      isThai: t,
                      categoryColor: AppTheme.primaryTeal,
                    ),
                    _buildRegimenSelector(state, t),
                    const SizedBox(height: 16),
                    _buildParametersForm(state, t, showDemographicInputs),
                    const SizedBox(height: 16),
                    ..._buildOutcomeAndGuidanceSection(
                      state,
                      t,
                      isWide: false,
                    ),
                  ],
          ),
        ),
        if (!isReferenceOnly)
          StickyCalculateBar(
            drug: widget.drug,
            selectedRegimen: state.selectedRegimen,
            onCalculate: _handleCalculate,
            isThai: t,
            categoryColor: AppTheme.primaryTeal,
          ),
      ],
    );
  }

  Widget _buildTierBanner(bool t) {
    final tier = widget.drug.tier;
    if (tier == DrugTier.core) {
      return const SizedBox.shrink();
    }
    if (tier == DrugTier.extended) {
      return Container(
        key: const Key('calculator_extended_tier_notice'),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.statusWarningBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.statusWarningBorder),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.layers_outlined,
              size: 18,
              color: Color(0xFF92400E),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                t
                    ? 'Extended Formulary — ยานอกรายการหลัก Core (ยังไม่ผ่านการตรวจสอบระดับ Core โปรดตรวจซ้ำกับตำรา)'
                    : 'Extended Formulary — Not yet verified at Core Pediatric/IV level; verify against reference monograph.',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF92400E),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildReferenceOnlyCard(CalculatorUiState state, bool t) {
    return Container(
      key: const Key('calculator_reference_only_card'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.statusCriticalBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.menu_book_rounded,
                color: AppTheme.statusCritical,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t
                      ? 'Reference Only — ยาเฉพาะทาง (ปิดการคำนวณอัตโนมัติ)'
                      : 'Reference Only — Specialist Oncology / Transplant Protocol',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.statusCritical,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            t
                ? 'ยานี้จัดอยู่ในกลุ่มยาเฉพาะทางที่มีความซับซ้อนสูง ระบบปิดการคำนวณขนาดยาอัตโนมัติเพื่อความปลอดภัย กรุณาเปิดดูตำราอ้างอิงและอิงตามโปรโตคอลเฉพาะทางของโรงพยาบาล'
                : 'Automated bedside dose calculation is disabled for high-complexity oncology/transplant agents. Consult the textbook monograph and institutional specialist protocol.',
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.inkPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            key: const Key('calculator_reference_only_monograph_btn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: () => ClinicalEvidenceSheet.show(
              context,
              drug: widget.drug,
              regimen: state.selectedRegimen,
              isThai: t,
            ),
            icon: const Icon(Icons.menu_book_outlined),
            label: Text(
              t ? 'เปิดดูตำราอ้างอิง (Monograph)' : 'Open Textbook Monograph',
            ),
          ),
        ],
      ),
    );
  }

  /// Empty Guidance State card prompt.
  Widget _buildEmptyGuidanceCard(bool t) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderDefault),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primaryTealSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.primaryTealBorder),
            ),
            child: const Icon(
              Icons.calculate_outlined,
              size: 24,
              color: AppTheme.primaryTeal,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            t
                ? 'เลือกสูตรยาและกรอกข้อมูลผู้ป่วยเพื่อเริ่มการคำนวณ'
                : 'Select a Regimen and Enter Patient Parameters',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.inkPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t
                ? 'ระบบจะคำนวณอัตโนมัติทันทีที่ข้อมูลครบถ้วน หรือกดปุ่ม "คำนวณโดสยา" ด้านล่าง'
                : 'Dose updates automatically once required parameters are filled, or tap "Calculate Dose" below.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppTheme.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Loading skeleton placeholder.
  Widget _buildLoadingSkeleton() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderDefault),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(color: AppTheme.primaryTeal),
          const SizedBox(height: 16),
          Text(
            widget.isThai
                ? 'กำลังประมวลผลการคำนวณทางคลินิก...'
                : 'Processing clinical dosage calculations...',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
