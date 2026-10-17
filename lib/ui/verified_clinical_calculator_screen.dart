import 'package:flutter/material.dart';

import '../core/calculators/transparent_dosage_calculator.dart';
import '../core/models/transparent_calculation_result.dart';
import '../core/models/verified_drug_schema.dart';
import '../data/knowledge_base_loader.dart';
import 'widgets/calculation_breakdown_card.dart';
import 'widgets/textbook_evidence_modal.dart';

/// Pillar 3 Screen: Evidence-Based Clinical Dosage Calculator UI.
///
/// Features:
/// - Clean Clinical Color Palette (White, Medical Navy, Safe Green, Caution Orange, Danger Red, Info Blue)
/// - Explicit Unit Badges on every numeric input field (`kg`, `ปี (yr)`, `mL/min/1.73m²` / `mL/min`)
/// - Explicit 3-State Allergy Assessment (`NKDA Confirmed` vs `Not Assessed` vs `Has Allergies`)
/// - Unified Non-Blocking Safety Banners (Overdose, Renal Contraindication,
///   Synonym/Same-Class/Cross-Reactivity Allergy, Unrecognized Drug Warnings, and DDI with Database Attribution)
/// - Scoped green banner (`"ไม่พบจากรายการที่ตรวจ N รายการ (ไม่ได้แปลว่าไม่มีปฏิกิริยากับยาอื่นนอกฐานข้อมูล)"`)
/// - View Textbook Evidence Modal Button (`TextbookEvidenceModal`)
/// - Calculation Breakdown Accordion (`CalculationBreakdownCard`)
class VerifiedClinicalCalculatorScreen extends StatefulWidget {
  final VerifiedDrugKnowledgeBase? initialKnowledgeBase;

  const VerifiedClinicalCalculatorScreen({
    super.key,
    this.initialKnowledgeBase,
  });

  @override
  State<VerifiedClinicalCalculatorScreen> createState() =>
      _VerifiedClinicalCalculatorScreenState();
}

class _VerifiedClinicalCalculatorScreenState
    extends State<VerifiedClinicalCalculatorScreen> {
  VerifiedDrugKnowledgeBase? _kb;
  VerifiedDrugEntry? _selectedDrug;
  String? _loadError;

  final TextEditingController _weightController =
      TextEditingController(text: '15.0');
  final TextEditingController _ageController =
      TextEditingController(text: '4.0');
  final TextEditingController _crclController =
      TextEditingController(text: '90.0');
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _concomitantMedsController =
      TextEditingController();

  bool _nkdaConfirmed = true;

  TransparentCalculationResult? _calculationResult;
  String? _inputValidationError;

  @override
  void initState() {
    super.initState();
    if (widget.initialKnowledgeBase != null) {
      _kb = widget.initialKnowledgeBase;
      if (_kb!.drugs.isNotEmpty) {
        _selectedDrug = _kb!.drugs.first;
        _runCalculation();
      }
    } else {
      _loadKnowledgeBase();
    }
  }

  Future<void> _loadKnowledgeBase() async {
    try {
      final loaded = await KnowledgeBaseLoader.loadFromAssetBundle();
      if (!mounted) return;
      setState(() {
        _kb = loaded;
        if (loaded.drugs.isNotEmpty) {
          _selectedDrug = loaded.drugs.first;
        }
      });
      _runCalculation();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _ageController.dispose();
    _crclController.dispose();
    _allergiesController.dispose();
    _concomitantMedsController.dispose();
    super.dispose();
  }

  bool get _isPediatric {
    final age = double.tryParse(_ageController.text.trim());
    return age == null || age < 18.0;
  }

  void _runCalculation() {
    final drug = _selectedDrug;
    if (drug == null) return;

    final weight = double.tryParse(_weightController.text.trim());
    if (weight == null) {
      setState(() {
        _inputValidationError = 'กรุณากรอกน้ำหนักผู้ป่วยเป็นตัวเลขที่ถูกต้อง (kg)';
        _calculationResult = null;
      });
      return;
    }

    final ageText = _ageController.text.trim();
    final double? age = ageText.isEmpty ? null : double.tryParse(ageText);

    final crclText = _crclController.text.trim();
    final double? crcl = crclText.isEmpty ? null : double.tryParse(crclText);

    final allergies = _allergiesController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final allergyStatus = allergies.isNotEmpty
        ? AllergyAssessmentStatus.hasAllergies
        : (_nkdaConfirmed
            ? AllergyAssessmentStatus.nkdaConfirmed
            : AllergyAssessmentStatus.notAssessed);

    final concomitantMeds = _concomitantMedsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    try {
      final res = TransparentDosageCalculator.calculate(
        drug: drug,
        weightKg: weight,
        ageYears: age,
        crclMlMin: crcl,
        allergies: allergies,
        allergyAssessmentStatus: allergyStatus,
        concomitantMedications: concomitantMeds,
      );
      setState(() {
        _calculationResult = res;
        _inputValidationError = null;
      });
    } on InvalidPatientInputException catch (e) {
      setState(() {
        _inputValidationError = e.message;
        _calculationResult = null;
      });
    } catch (e) {
      setState(() {
        _inputValidationError = e.toString();
        _calculationResult = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Clinical Dosage & Safety Verification (4 Pillars)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          if (_selectedDrug != null)
            IconButton(
              key: const Key('appbar_textbook_evidence_button'),
              tooltip: 'ดูหลักฐานตำราอ้างอิง (Textbook Evidence)',
              icon: const Icon(Icons.menu_book_rounded),
              onPressed: () => TextbookEvidenceModal.show(
                context,
                drug: _selectedDrug!,
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'เกิดข้อผิดพลาดในการโหลดฐานข้อมูลยา:\n$_loadError',
            style: const TextStyle(color: Color(0xFFDC2626)),
          ),
        ),
      );
    }

    if (_kb == null || _selectedDrug == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPatientAndDrugInputCard(),
              const SizedBox(height: 12),
              if (_inputValidationError != null)
                _buildInputValidationErrorBanner(_inputValidationError!),
              if (_calculationResult != null) ...[
                _buildSafetyAlertBanners(_calculationResult!),
                const SizedBox(height: 8),
                _buildPrimaryResultCard(_calculationResult!),
                const SizedBox(height: 8),
                CalculationBreakdownCard(result: _calculationResult!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientAndDrugInputCard() {
    final kb = _kb!;
    final selected = _selectedDrug!;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '1. เลือกตัวยาและกรอกข้อมูลผู้ป่วย (Patient & Medication Parameters)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 12),
            // Drug Dropdown
            DropdownButtonFormField<String>(
              key: const Key('drug_selector_dropdown'),
              isExpanded: true,
              initialValue: selected.drugInfo.drugId,
              decoration: InputDecoration(
                labelText: 'ตัวยาและความเข้มข้น (Verified Drug Formulary)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              items: kb.drugs.map((d) {
                return DropdownMenuItem<String>(
                  value: d.drugInfo.drugId,
                  child: Text(
                    '${d.drugInfo.genericName} (${d.drugInfo.strengthLabel}) — [${d.dosingRules.formulaType}]',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13.5),
                  ),
                );
              }).toList(),
              onChanged: (newId) {
                if (newId == null) return;
                final found = kb.findDrug(newId);
                if (found != null) {
                  setState(() {
                    _selectedDrug = found;
                  });
                  _runCalculation();
                }
              },
            ),
            const SizedBox(height: 12),
            // Numeric Inputs Row with Unit Badges
            Row(
              children: [
                Expanded(
                  child: _buildTextFieldWithUnitBadge(
                    fieldKey: const Key('input_weight_kg'),
                    badgeKey: const Key('unit_badge_kg'),
                    controller: _weightController,
                    label: 'น้ำหนักตัว (Weight)',
                    unitBadgeText: 'kg',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextFieldWithUnitBadge(
                    fieldKey: const Key('input_age_years'),
                    badgeKey: const Key('unit_badge_years'),
                    controller: _ageController,
                    label: 'อายุ (Age)',
                    unitBadgeText: 'ปี (yr)',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextFieldWithUnitBadge(
                    fieldKey: const Key('input_crcl_ml_min'),
                    badgeKey: const Key('unit_badge_renal'),
                    controller: _crclController,
                    label: _isPediatric
                        ? 'ค่าไตเด็ก (Schwartz eGFR)'
                        : 'ค่าไตผู้ใหญ่ (CrCl)',
                    unitBadgeText:
                        _isPediatric ? 'mL/min/1.73m²' : 'mL/min',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Allergy & Concomitant Meds Inputs
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('input_allergies'),
                    controller: _allergiesController,
                    decoration: InputDecoration(
                      labelText:
                          'ประวัติแพ้ยา (คั่นด้วยลูกน้ำ เช่น Penicillin V, Aspirin)',
                      prefixIcon: const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFDC2626),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                    ),
                    onChanged: (_) => _runCalculation(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    key: const Key('input_concomitant_meds'),
                    controller: _concomitantMedsController,
                    decoration: InputDecoration(
                      labelText:
                          'ยาร่วมปัจจุบัน (คั่นด้วยลูกน้ำ เช่น Warfarin, Enalapril)',
                      prefixIcon: const Icon(
                        Icons.medication_liquid_rounded,
                        color: Color(0xFFD97706),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                    ),
                    onChanged: (_) => _runCalculation(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // NKDA Confirmation Toggle (distinguishes confirmed NKDA from unassessed allergy history)
            Row(
              children: [
                Checkbox(
                  key: const Key('nkda_confirmed_checkbox'),
                  value: _nkdaConfirmed,
                  activeColor: const Color(0xFF1E3A8A),
                  onChanged: (val) {
                    setState(() {
                      _nkdaConfirmed = val ?? false;
                    });
                    _runCalculation();
                  },
                ),
                Expanded(
                  child: Text(
                    _allergiesController.text.trim().isNotEmpty
                        ? 'สถานะแพ้ยา: มีประวัติแพ้ยาที่ระบุไว้ด้านบน'
                        : (_nkdaConfirmed
                            ? 'ยืนยันซักประวัติแล้ว: ผู้ป่วยปฏิเสธแพ้ยา (NKDA Confirmed)'
                            : 'ยังไม่ได้ซักประวัติแพ้ยา (Allergy Not Assessed — จะแสดงคำเตือนระดับ Info)'),
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  key: const Key('view_textbook_evidence_button'),
                  onPressed: () => TextbookEvidenceModal.show(
                    context,
                    drug: selected,
                  ),
                  icon: const Icon(Icons.menu_book_rounded, size: 18),
                  label: const Text(
                    'ดูเอกสารอ้างอิง (View Textbook Evidence)',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E3A8A),
                    side: const BorderSide(color: Color(0xFF1E3A8A)),
                  ),
                ),
                ElevatedButton.icon(
                  key: const Key('calculate_dosage_button'),
                  onPressed: _runCalculation,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('คำนวณและตรวจสอบความปลอดภัย'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFieldWithUnitBadge({
    required Key fieldKey,
    required Key badgeKey,
    required TextEditingController controller,
    required String label,
    required String unitBadgeText,
  }) {
    return TextField(
      key: fieldKey,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => _runCalculation(),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: Container(
          key: badgeKey,
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFDBEAFE),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF93C5FD)),
          ),
          child: Text(
            unitBadgeText,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputValidationErrorBanner(String message) {
    return Container(
      key: const Key('invalid_input_error_banner'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDC2626), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'ข้อมูลผู้ป่วยไม่ถูกต้อง (Invalid Input): $message',
              style: const TextStyle(
                color: Color(0xFF991B1B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyAlertBanners(TransparentCalculationResult res) {
    if (res.safetyAlerts.isEmpty) {
      return Container(
        key: const Key('safe_status_banner'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF16A34A)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'ไม่พบข้อห้ามใช้จากรายการที่ตรวจในฐานข้อมูลของยานี้ ${res.totalSafetyRulesEvaluated} รายการ '
                '(ไม่ได้แปลว่าไม่มีปฏิกิริยากับยาอื่นนอกฐานข้อมูล)',
                style: const TextStyle(
                  color: Color(0xFF166534),
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      key: const Key('safety_alerts_banner_list'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: res.safetyAlerts.map((alert) {
        final isInfo = alert.severity == SafetyAlertSeverity.info;
        final isRed = alert.severity == SafetyAlertSeverity.contraindicated ||
            alert.severity == SafetyAlertSeverity.criticalOverdose ||
            alert.severity == SafetyAlertSeverity.major;

        final bgColor = isInfo
            ? const Color(0xFFEFF6FF)
            : (isRed ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB));
        final borderColor = isInfo
            ? const Color(0xFF3B82F6)
            : (isRed ? const Color(0xFFDC2626) : const Color(0xFFD97706));
        final titleColor = isInfo
            ? const Color(0xFF1E40AF)
            : (isRed ? const Color(0xFF991B1B) : const Color(0xFF92400E));

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                alert.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                alert.message,
                style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 6),
              Text(
                'กลไก (Mechanism): ${alert.mechanism}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 4),
              Text(
                'การจัดการทางคลินิก (Management): ${alert.management}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'แหล่งอ้างอิง: ${alert.reference}${alert.databaseSource != null ? " | ฐานข้อมูล: ${alert.databaseSource}" : ""}',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPrimaryResultCard(TransparentCalculationResult res) {
    final hasCriticalBanner = res.isSingleDoseCappedAtMax ||
        res.isDailyDoseCappedAtMax ||
        res.isMgPerKgCappedAtMax ||
        res.isRenallyContraindicated ||
        res.hasAllergyAlert;

    final headerColor = hasCriticalBanner
        ? const Color(0xFFDC2626)
        : const Color(0xFF1E3A8A);
    final isFullyVerified = res.referenceCitation.isFullyVerified;
    final volDec = res.practicalVolumeDecimalsUsed;

    return Card(
      key: const Key('primary_dosage_result_card'),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: headerColor, width: 1.5),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'ผลลัพธ์ขนาดยาและปริมาตรที่ตวงได้จริง (${res.genericName} — ${res.strengthLabel})',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: headerColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isFullyVerified
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isFullyVerified
                        ? 'Source Verified (${res.referenceCitation.verifiedBy})'
                        : 'Pending Textbook Review',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isFullyVerified
                          ? const Color(0xFF166534)
                          : const Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _buildMetricTile(
                  label: 'ขนาดยาแนะนำต่อครั้ง (Final Dose)',
                  value:
                      '${res.finalRecommendedSingleDoseMg.toStringAsFixed(1)} mg/ครั้ง',
                  subtext:
                      'ความถี่: ${res.recommendedFrequency} (${res.dosesPerDay} มื้อ/วัน = ${res.finalRecommendedDailyDoseMg.toStringAsFixed(1)} mg/วัน)',
                  highlightColor: const Color(0xFF1E3A8A),
                ),
                _buildMetricTile(
                  label: 'ปริมาตรตวงจริง (Practical Volume)',
                  value:
                      '${res.practicalVolumeMl.toStringAsFixed(volDec)} mL/ครั้ง',
                  subtext:
                      'Exact Volume: ${res.exactVolumeMl.toStringAsFixed(3)} mL (ได้เนื้อยาจริง ${res.actualDeliveredSingleDoseMg.toStringAsFixed(1)} mg)',
                  highlightColor: const Color(0xFF166534),
                ),
                if (res.isSingleDoseCappedAtMax ||
                    res.isDailyDoseCappedAtMax ||
                    res.isMgPerKgCappedAtMax)
                  _buildMetricTile(
                    label:
                        'ขนาดยาตามน้ำหนักจริงก่อนตัดเพดาน (Non-Blocking Raw Dose)',
                    value:
                        '${res.rawCalculatedSingleDoseMg.toStringAsFixed(1)} mg/ครั้ง (${res.rawUnclippedPracticalVolumeMl.toStringAsFixed(volDec)} mL)',
                    subtext:
                        'ยอดรวมตามน้ำหนักก่อนตัดเพดาน: ${res.rawCalculatedDailyDoseMg.toStringAsFixed(1)} mg/วัน',
                    highlightColor: const Color(0xFFDC2626),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'อุปกรณ์ตวงยาที่แนะนำ: ${res.dispensingDeviceRecommendation} | '
                'ตำราอ้างอิง: ${res.referenceCitation.sourceName} (${res.referenceCitation.editionAndPage})',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E40AF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String subtext,
    required Color highlightColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: highlightColor,
          ),
        ),
        Text(
          subtext,
          style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}
