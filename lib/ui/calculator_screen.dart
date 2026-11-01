import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../core/core.dart';
import '../data/history_service.dart';
import '../data/patient_session.dart';
import '../data/prescription_cart.dart';
import 'iv_titration_screen.dart';
import 'tdm_screen.dart';
import 'widgets/child_pugh_sheet.dart';
import 'widgets/clinical_evidence_sheet.dart';

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
  // Input controllers
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _scrCtrl = TextEditingController();

  Sex _sex = Sex.male;
  bool _isScrStable = true;
  RenalReplacementMode _renalReplacementMode = RenalReplacementMode.none;
  ChildPughClass _hepaticImpairment = ChildPughClass.none;
  int? _lastChildPughScore;
  DosingRegimen? _selectedRegimen;

  DosageResult? _result;
  List<DoseWarning> _warnings = [];

  // UI Display for weight selection
  String? _dosingWeightLabel;
  double? _dosingWeightValue;
  String? _dosingWeightReason;

  Patient? _lastEvaluatedPatient;

  @override
  void initState() {
    super.initState();
    if (widget.drug.regimens.isNotEmpty) {
      _selectedRegimen = widget.drug.regimens.first;
    }
    _syncFromSession();
    PatientSession.instance.currentPatient.addListener(_syncFromSession);
  }

  void _syncFromSession() {
    final p = PatientSession.instance.currentPatient.value;
    if (p != null) {
      _weightCtrl.text = p.weightKg.toString();
      _heightCtrl.text = p.heightCm.toString();
      _ageCtrl.text = p.ageYears.toString();
      _scrCtrl.text = p.serumCreatinineMgDl?.toString() ?? '';
      _sex = p.sex;
      _renalReplacementMode = p.renalReplacementMode;
      _hepaticImpairment = p.hepaticImpairment ?? ChildPughClass.none;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    PatientSession.instance.currentPatient.removeListener(_syncFromSession);
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _ageCtrl.dispose();
    _scrCtrl.dispose();
    super.dispose();
  }

  Patient _buildCurrentPatient() {
    final sessionPatient = PatientSession.instance.currentPatient.value;
    final weight =
        double.tryParse(_weightCtrl.text) ?? sessionPatient?.weightKg ?? 70.0;
    final height =
        double.tryParse(_heightCtrl.text) ?? sessionPatient?.heightCm ?? 170.0;
    final age = int.tryParse(_ageCtrl.text) ?? sessionPatient?.ageYears ?? 35;
    final scr =
        double.tryParse(_scrCtrl.text) ?? sessionPatient?.serumCreatinineMgDl;

    return Patient(
      id: sessionPatient?.id ??
          'PATIENT-${DateTime.now().millisecondsSinceEpoch}',
      patientName: sessionPatient?.patientName,
      hospitalNumber: sessionPatient?.hospitalNumber,
      weightKg: weight,
      heightCm: height,
      ageYears: age,
      sex: _sex,
      serumCreatinineMgDl: scr,
      isScrStable: _isScrStable,
      renalReplacementMode: _renalReplacementMode,
      allergies: sessionPatient?.allergies ?? const [],
      activeDrugIds: sessionPatient?.activeDrugIds ?? const [],
      isPregnant: sessionPatient?.isPregnant ?? false,
      hepaticImpairment:
          _hepaticImpairment == ChildPughClass.none ? null : _hepaticImpairment,
    );
  }

  void _calculate() {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    // 1. Parse inputs
    final weight = double.tryParse(_weightCtrl.text); // TBW
    final height = double.tryParse(_heightCtrl.text);
    final age = int.tryParse(_ageCtrl.text);
    final scr = double.tryParse(_scrCtrl.text);

    // 2. Validate
    final valResult = InputValidator.validatePatientInputs(
      weightKg: weight,
      heightCm: height,
      ageYears: age,
      serumCreatinineMgDl: scr,
    );

    if (!valResult.isValid) {
      _showErrorDialog(
        widget.isThai ? 'ข้อมูลไม่ถูกต้อง' : 'Invalid Input',
        (widget.isThai ? valResult.errorsTh.values : valResult.errorsEn.values)
            .join('\n'),
      );
      return;
    }

    if (_selectedRegimen == null) return;

    // Build Patient from inputs and session (D0)
    final sessionPatient = PatientSession.instance.currentPatient.value;
    final patient = Patient(
      id: sessionPatient?.id ??
          'PATIENT-${DateTime.now().millisecondsSinceEpoch}',
      patientName: sessionPatient?.patientName,
      hospitalNumber: sessionPatient?.hospitalNumber,
      weightKg: weight!,
      heightCm: height!,
      ageYears: age!,
      sex: _sex,
      serumCreatinineMgDl: scr,
      isScrStable: _isScrStable,
      renalReplacementMode: _renalReplacementMode,
      allergies: sessionPatient?.allergies ?? const [],
      activeDrugIds: sessionPatient?.activeDrugIds ?? const [],
      isPregnant: sessionPatient?.isPregnant ?? false,
      hepaticImpairment:
          _hepaticImpairment == ChildPughClass.none ? null : _hepaticImpairment,
    );

    // Call central calculation engine (D0)
    final dosageResult = PharmacistCalculator.calculateDose(
      patient: patient,
      drug: widget.drug,
      regimen: _selectedRegimen!,
    );

    final weightStrategy =
        dosageResult.calculationInputs['weightStrategy'] as String? ?? 'TBW';
    final dosingWeightUsed =
        dosageResult.calculationInputs['dosingWeightUsedKg'] as double?;

    setState(() {
      _lastEvaluatedPatient = patient;
      _warnings = dosageResult.warnings;
      _result = dosageResult;
      _dosingWeightLabel = weightStrategy;
      _dosingWeightValue = dosingWeightUsed ?? weight;
      _dosingWeightReason = 'ใช้ $weightStrategy ในการคำนวณตามเกณฑ์คลินิก';
    });

    // Save to Audit Log with real UUID and logged-in clinician ID (D0)
    final log = CalculationLog(
      logId: const Uuid().v4(),
      timestamp: DateTime.now(),
      userId: PatientSession.instance.currentUserId,
      patientId: patient.id,
      drugName: widget.drug.genericName,
      drugId: widget.drug.id,
      route: _selectedRegimen!.route.abbreviation,
      indication: _selectedRegimen!.indication,
      inputs: dosageResult.calculationInputs,
      result: dosageResult,
      formulaUsed: dosageResult.formulaUsed,
      softwareVersion: '0.1.0-prototype',
    );
    HistoryService().addLog(log);
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
              regimen: _selectedRegimen,
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              100,
            ), // padding for bottom button
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header info
                Text(
                  t && widget.drug.nameTh != null
                      ? widget.drug.nameTh!
                      : widget.drug.brandNames.join(', '),
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                // Pre-calculate Warnings
                if (widget.drug.pregnancyCategory != null)
                  _buildAlertCard(
                    Icons.pregnant_woman,
                    (widget.drug.pregnancyCategory == 'X' ||
                            widget.drug.pregnancyCategory == 'D')
                        ? Colors.red
                        : Colors.orange,
                    t
                        ? 'ความปลอดภัยในสตรีมีครรภ์: Category ${widget.drug.pregnancyCategory}'
                        : 'Pregnancy Category: ${widget.drug.pregnancyCategory}',
                  ),

                if (widget.drug.requiresHepaticCaution)
                  _buildAlertCard(
                    Icons.local_hospital,
                    Colors.orange,
                    t
                        ? 'ควรปรับขนาดหรือระวังในผู้ป่วยโรคตับ (Hepatic caution)'
                        : 'Hepatic dose adjustment / caution required',
                  ),

                if (widget.drug.allergyClass != null)
                  _buildAlertCard(
                    Icons.medical_information,
                    Colors.purple,
                    t
                        ? 'ตรวจสอบประวัติแพ้ยากลุ่ม: ${widget.drug.allergyClass}'
                        : 'Check patient allergy to: ${widget.drug.allergyClass}',
                  ),

                if (widget.drug.severeInteractions.isNotEmpty)
                  _buildListAlertCard(
                    Icons.warning_amber,
                    Colors.orange,
                    t
                        ? 'ระวังยาตีกัน (Severe Interactions)'
                        : 'Severe Interactions',
                    widget.drug.severeInteractions,
                  ),

                if (widget.drug.contraindications.isNotEmpty)
                  _buildListAlertCard(
                    Icons.do_not_disturb_alt,
                    Colors.red,
                    t ? 'ข้อห้ามใช้ (Contraindications)' : 'Contraindications',
                    widget.drug.contraindications,
                  ),

                if (widget.drug.specialNotes != null ||
                    widget.drug.specialNotesTh != null)
                  _buildAlertCard(
                    Icons.info_outline,
                    Colors.blue,
                    t
                        ? (widget.drug.specialNotesTh ??
                              widget.drug.specialNotes!)
                        : widget.drug.specialNotes!,
                  ),

                // Clinical Metadata Badge (Source & Last Reviewed - Interactive)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => ClinicalEvidenceSheet.show(
                      context,
                      drug: widget.drug,
                      regimen: _selectedRegimen,
                      isThai: t,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.teal.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.menu_book_rounded,
                            size: 18,
                            color: Colors.teal.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        t ? 'แหล่งอ้างอิงทางคลินิก (Textbook Reference)' : 'Clinical Evidence Reference',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.teal.shade900,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      t ? 'แตะเพื่อเปิดดูตำรา ↗' : 'Tap to view ↗',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.teal.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  t
                                      ? '${widget.drug.sourceCitation} • ตรวจสอบล่าสุด: ${widget.drug.lastReviewedDate}'
                                      : '${widget.drug.sourceCitation} • Reviewed: ${widget.drug.lastReviewedDate}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blueGrey.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Regimen Selection
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.vaccines, color: widget.categoryColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                t
                                    ? 'ข้อบ่งใช้ / วิธีบริหารยา'
                                    : 'Indication / Route',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<DosingRegimen>(
                              isExpanded: true,
                              value: _selectedRegimen,
                              icon: const Icon(Icons.arrow_drop_down),
                              items: widget.drug.regimens
                                  .map(
                                    (r) => DropdownMenuItem(
                                      value: r,
                                      child: Text(
                                        '${r.indication ?? "Standard"} (${r.route.abbreviation})',
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedRegimen = val;
                                  _result = null; // Clear previous result
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_shouldShowIvDiluentCard) ...[
                  const SizedBox(height: 16),
                  _buildIvDiluentCompatibilityCard(),
                ],

                const SizedBox(height: 16),

                // Patient Inputs
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person, color: widget.categoryColor),
                            const SizedBox(width: 8),
                            Text(
                              t ? 'ข้อมูลผู้ป่วย' : 'Patient Data',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                _weightCtrl,
                                t ? 'น้ำหนัก (kg)' : 'Weight (kg)',
                                Icons.monitor_weight_outlined,
                                key: const Key('calculator_weight_field'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                _heightCtrl,
                                t ? 'ส่วนสูง (cm)' : 'Height (cm)',
                                Icons.height,
                                key: const Key('calculator_height_field'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                _ageCtrl,
                                t ? 'อายุ (ปี)' : 'Age (years)',
                                Icons.cake_outlined,
                                key: const Key('calculator_age_field'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                _scrCtrl,
                                t ? 'Cr (mg/dL)' : 'SCr (mg/dL)',
                                Icons.water_drop_outlined,
                                key: const Key('calculator_scr_field'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(
                            t
                                ? 'ค่า SCr คงที่ (Stable / ไม่ใช่ AKI)'
                                : 'SCr is stable (No AKI)',
                            style: TextStyle(
                              fontSize: 14,
                              color: _isScrStable
                                  ? Colors.grey.shade800
                                  : Colors.red,
                              fontWeight: _isScrStable
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                          value: _isScrStable,
                          onChanged: (val) {
                            setState(() {
                              _isScrStable = val ?? true;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        // Renal Replacement Therapy (RRT) Selector
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            t
                                ? 'การบำบัดทดแทนไต (Renal Replacement Therapy):'
                                : 'Renal Replacement Therapy (RRT):',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: SegmentedButton<RenalReplacementMode>(
                            key: const Key('calculator_rrt_selector'),
                            showSelectedIcon: false,
                            segments: [
                              ButtonSegment<RenalReplacementMode>(
                                value: RenalReplacementMode.none,
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    t ? 'ไม่มี' : 'None',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                              const ButtonSegment<RenalReplacementMode>(
                                value: RenalReplacementMode.ihd,
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'IHD',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                              const ButtonSegment<RenalReplacementMode>(
                                value: RenalReplacementMode.capd,
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'CAPD',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                              const ButtonSegment<RenalReplacementMode>(
                                value: RenalReplacementMode.crrt,
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'CRRT',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ],
                            selected: {_renalReplacementMode},
                            onSelectionChanged: (Set<RenalReplacementMode> newSelection) {
                              setState(() {
                                _renalReplacementMode = newSelection.first;
                              });
                            },
                            style: ButtonStyle(
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: WidgetStateProperty.all(
                                const EdgeInsets.symmetric(horizontal: 2),
                              ),
                              backgroundColor:
                                  WidgetStateProperty.resolveWith<Color>((
                                Set<WidgetState> states,
                              ) {
                                if (states.contains(WidgetState.selected)) {
                                  return widget.categoryColor.withValues(
                                    alpha: 0.2,
                                  );
                                }
                                return Colors.white;
                              }),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Child-Pugh Hepatic Function Selector + Interactive Calculator Button
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          alignment: WrapAlignment.spaceBetween,
                          children: [
                            Text(
                              t
                                  ? 'การทำงานของตับ (Child-Pugh):'
                                  : 'Hepatic Function (Child-Pugh):',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            ConstrainedBox(
                              constraints: const BoxConstraints(
                                minHeight: 48,
                                minWidth: 48,
                              ),
                              child: TextButton.icon(
                                key: const Key(
                                  'calculator_open_child_pugh_sheet_button',
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: widget.categoryColor,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                ),
                                onPressed: () async {
                                  final res =
                                      await ChildPughCalculatorSheet.show(
                                    context,
                                    isThai: t,
                                    accentColor: widget.categoryColor,
                                  );
                                  if (res != null && mounted) {
                                    setState(() {
                                      _hepaticImpairment = res.classification;
                                      _lastChildPughScore = res.totalScore;
                                    });
                                  }
                                },
                                icon: const Icon(
                                  Icons.calculate_outlined,
                                  size: 18,
                                ),
                                label: Text(
                                  _lastChildPughScore != null
                                      ? (t
                                          ? 'คำนวณ Child-Pugh ($_lastChildPughScore/15)'
                                          : 'Child-Pugh Calc ($_lastChildPughScore/15)')
                                      : (t
                                          ? 'คำนวณคะแนน Child-Pugh'
                                          : 'Calculate Score'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: SegmentedButton<ChildPughClass>(
                            key: const Key('calculator_child_pugh_selector'),
                            showSelectedIcon: false,
                            segments: [
                              ButtonSegment<ChildPughClass>(
                                value: ChildPughClass.none,
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    t ? 'ปกติ' : 'Normal',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const ButtonSegment<ChildPughClass>(
                                value: ChildPughClass.classA,
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Class A',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const ButtonSegment<ChildPughClass>(
                                value: ChildPughClass.classB,
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Class B',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const ButtonSegment<ChildPughClass>(
                                value: ChildPughClass.classC,
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Class C',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            selected: {_hepaticImpairment},
                            onSelectionChanged:
                                (Set<ChildPughClass> newSelection) {
                              setState(() {
                                _hepaticImpairment = newSelection.first;
                                _lastChildPughScore = null;
                              });
                            },
                            style: ButtonStyle(
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: WidgetStateProperty.all(
                                const EdgeInsets.symmetric(horizontal: 2),
                              ),
                              backgroundColor:
                                  WidgetStateProperty.resolveWith<Color>((
                                Set<WidgetState> states,
                              ) {
                                if (states.contains(WidgetState.selected)) {
                                  return widget.categoryColor.withValues(
                                    alpha: 0.2,
                                  );
                                }
                                return Colors.white;
                              }),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Sex Selector
                        SegmentedButton<Sex>(
                          segments: [
                            ButtonSegment(
                              value: Sex.male,
                              label: Text(t ? 'ชาย' : 'Male'),
                              icon: const Icon(Icons.male),
                            ),
                            ButtonSegment(
                              value: Sex.female,
                              label: Text(t ? 'หญิง' : 'Female'),
                              icon: const Icon(Icons.female),
                            ),
                          ],
                          selected: {_sex},
                          onSelectionChanged: (Set<Sex> newSelection) {
                            setState(() {
                              _sex = newSelection.first;
                            });
                          },
                          style: ButtonStyle(
                            backgroundColor:
                                WidgetStateProperty.resolveWith<Color>((
                                  Set<WidgetState> states,
                                ) {
                                  if (states.contains(WidgetState.selected)) {
                                    return widget.categoryColor.withValues(
                                      alpha: 0.2,
                                    );
                                  }
                                  return Colors.white;
                                }),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Results Section
                if (_result != null) _buildResultSection(),
              ],
            ),
          ),

          // Sticky Bottom Button
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    if (_selectedRegimen?.standardDilutionMgPerMl != null) ...[
                      Expanded(
                        child: SizedBox(
                          height: 54,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                              side: BorderSide(
                                color: Colors.red.shade700,
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => IVTitrationScreen(
                                    drug: widget.drug,
                                    regimen: _selectedRegimen!,
                                    isThai: t,
                                  ),
                                ),
                              );
                            },
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                t ? 'ตารางดริปยา' : 'Titration Table',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          key: const Key('calculator_calculate_button'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.categoryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _calculate,
                          child: Text(
                            t ? 'คำนวณโดสยา' : 'Calculate Dose',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _shouldShowIvDiluentCard {
    final reg = _selectedRegimen;
    if (reg == null) return false;
    final isIv = reg.route == DoseRoute.iv ||
        reg.route == DoseRoute.ivPush ||
        reg.route == DoseRoute.ivInfusion;
    return isIv && reg.effectiveIvDiluentCompatibility(widget.drug) != null;
  }

  Widget _buildIvDiluentCompatibilityCard() {
    final t = widget.isThai;
    final reg = _selectedRegimen!;
    final compat = reg.effectiveIvDiluentCompatibility(widget.drug)!;

    return Card(
      key: const Key('calculator_iv_diluent_card'),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: compat.incompatibleDiluents.isNotEmpty
              ? Colors.red.shade300
              : Colors.teal.shade300,
        ),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.water_drop_rounded,
                  color: compat.incompatibleDiluents.isNotEmpty
                      ? Colors.red.shade700
                      : Colors.teal.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t
                        ? 'ความเข้ากันได้ของสารน้ำผสมยา (IV Diluent Compatibility)'
                        : 'IV Diluent Compatibility & Precipitation Safety',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...compat.compatibleDiluents.map((d) {
                  final pref = compat.isPreferred(d);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: pref
                            ? Colors.teal.shade700
                            : Colors.teal.shade300,
                        width: pref ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          pref ? Icons.star_rounded : Icons.check_circle,
                          size: 15,
                          color: Colors.teal.shade800,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            pref
                                ? '${d.code} (${t ? "แนะนำหลัก" : "Preferred"})'
                                : '${d.code} (${t ? "ผสมได้" : "Compatible"})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                ...compat.incompatibleDiluents.map((d) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.shade700,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.block_rounded,
                          size: 15,
                          color: Colors.red.shade800,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${t ? "ห้ามผสม" : "Avoid"} ${d.code}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
            if (compat.incompatibilityReasonEn != null ||
                compat.incompatibilityReasonTh != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: Colors.red.shade800,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t
                            ? (compat.incompatibilityReasonTh ??
                                compat.incompatibilityReasonEn!)
                            : (compat.incompatibilityReasonEn ??
                                compat.incompatibilityReasonTh!),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (compat.stabilityNoteEn != null ||
                compat.stabilityNoteTh != null) ...[
              const SizedBox(height: 8),
              Text(
                t
                    ? (compat.stabilityNoteTh ?? compat.stabilityNoteEn!)
                    : (compat.stabilityNoteEn ?? compat.stabilityNoteTh!),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blueGrey.shade800,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              '${t ? "อ้างอิง" : "Source"}: ${compat.sourceCitation}',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(IconData icon, Color color, String text) {
    return Card(
      color: color.withValues(alpha: 0.1),
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color.withValues(alpha: 0.5), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: color.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListAlertCard(
    IconData icon,
    Color color,
    String title,
    List<String> items,
  ) {
    return Card(
      color: color.withValues(alpha: 0.1),
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color.withValues(alpha: 0.5), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...items
                .map(
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0, left: 28.0),
                    child: Text(
                      '• $i',
                      style: TextStyle(color: color.withValues(alpha: 0.9)),
                    ),
                  ),
                )
                ,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    Key? key,
  }) {
    return TextField(
      key: key,
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    final t = widget.isThai;
    final res = _result!;
    final hasHardWarnings = _warnings.any((w) => w.severity == LimitSeverity.hard);
    final hasSoftWarnings = _warnings.any((w) => w.severity == LimitSeverity.soft);

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
        ? (t ? 'คำเตือน: พบความเสี่ยงระดับวิกฤต (Critical Alert)' : 'CRITICAL SAFETY ALERT')
        : (hasSoftWarnings
            ? (t ? 'ผลการคำนวณ (มีข้อควรระวัง)' : 'Calculated with Warnings')
            : (t ? 'ผลการคำนวณผ่านเกณฑ์ความปลอดภัย' : 'Calculated Result (Verified)'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Result Card
        Card(
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
                if (_warnings.any(
                  (w) => const {
                    DoseWarningCode.maxSingleDoseExceeded,
                    DoseWarningCode.softMaxSingleDoseExceeded,
                    DoseWarningCode.maxDailyDoseExceeded,
                    DoseWarningCode.maxDosePerKgPerDayExceeded,
                    DoseWarningCode.maxInfusionRateExceeded,
                    DoseWarningCode.doseCappedAtMax,
                  }.contains(w.code),
                )) ...[
                  Container(
                    key: const Key('calculator_overdose_banner'),
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade400, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            t
                                ? '⚠️ คำเตือน: ขนาดยานี้เกินเกณฑ์สูงสุดที่แนะนำ (Overdose Warning) — โปรดใช้ดุลยพินิจของแพทย์/เภสัชกรในการให้ยา'
                                : '⚠️ CLINICAL WARNING: Dose exceeds recommended maximum limits — Please use clinical discretion',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.red.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (res.hasHardLimitViolation || res.hasHardWarning) ...[
                  Container(
                    key: const Key('calculator_critical_safety_banner'),
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade400, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.gpp_bad_rounded, color: Colors.red, size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            t
                                ? '⚠️ คำเตือนความปลอดภัยทางคลินิกรุนแรง (Critical Safety Alert) — พบการแพ้ยา ข้อห้ามใช้ หรือปฏิกิริยาระหว่างยารุนแรง โปรดตรวจสอบด้านล่าง'
                                : '⚠️ CRITICAL CLINICAL SAFETY ALERT: Allergy, contraindication, or severe interaction detected — Review alerts below',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.red.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (res.infusionResult != null) ...[
                  Text(
                    t ? 'อัตราการหยดยา (Titrated Infusion)' : 'Titrated Infusion Rate',
                    style: TextStyle(
                        color: Colors.teal.shade800, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${res.infusionResult!.rate} ${res.infusionResult!.rateUnit.symbol}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (res.infusionResult!.rateMlPerHr != null)
                    Text(
                      'Pump Rate: ${res.infusionResult!.rateMlPerHr!.toStringAsFixed(1)} mL/hr',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ] else if (res.roundedDose != null) ...[
                  Text(
                    t ? 'ขนาดยาที่แนะนำ (ปัดเศษแล้ว)' : 'Recommended Dose (Rounded)',
                    style: TextStyle(
                        color: Colors.green.shade800, fontWeight: FontWeight.w600),
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
                _buildRrtResultBadges(res, t),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.menu_book, size: 18),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      t ? 'เปิดดูข้อมูลยาในตำราอ้างอิง' : 'View Textbook Monograph',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.teal.shade800,
                    side: BorderSide(color: Colors.teal.shade300, width: 1.2),
                    backgroundColor: Colors.white.withValues(alpha: 0.8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () => ClinicalEvidenceSheet.show(
                    context,
                    drug: widget.drug,
                    regimen: _selectedRegimen,
                    isThai: t,
                  ),
                ),
                if (const {'vancomycin', 'gentamicin', 'amikacin'}.contains(widget.drug.id) ||
                    widget.drug.genericName.toLowerCase().contains('vancomycin')) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    key: const Key('calculator_open_tdm_btn'),
                    icon: const Icon(Icons.bar_chart),
                    label: Text(t ? 'เครื่องมือคำนวณ TDM' : 'TDM Calculator'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: () {
                      final activePt = PatientSession.instance.currentPatient.value;
                      final p = Patient(
                        id: activePt?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                        weightKg: double.tryParse(_weightCtrl.text) ?? activePt?.weightKg ?? 70,
                        heightCm: double.tryParse(_heightCtrl.text) ?? activePt?.heightCm ?? 170,
                        ageYears: int.tryParse(_ageCtrl.text) ?? activePt?.ageYears ?? 35,
                        sex: _sex,
                        serumCreatinineMgDl: double.tryParse(_scrCtrl.text) ?? activePt?.serumCreatinineMgDl,
                        isScrStable: _isScrStable,
                        renalReplacementMode: _renalReplacementMode,
                        creatinineClearanceMlMin: res.crclMlMin ?? activePt?.creatinineClearanceMlMin,
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TdmScreen(
                            patient: p,
                            drug: widget.drug,
                            isThai: t,
                          ),
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 16),
                // Side-by-side Copy Controls (R2)
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          key: const Key('copy_his_order_button'),
                          icon: const Icon(Icons.content_paste_go, size: 18),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              t
                                  ? 'คัดลอกคำสั่งแพทย์ (HIS Order)'
                                  : 'Copy HIS Order',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade700,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            final p = _lastEvaluatedPatient ?? _buildCurrentPatient();
                            final orderText = ClinicalOrderFormatter.formatHisOrder(
                              patient: p,
                              drug: widget.drug,
                              regimen: _selectedRegimen!,
                              result: res,
                              isThai: t,
                            );
                            Clipboard.setData(ClipboardData(text: orderText));
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                content: Text(
                                  t
                                      ? 'คัดลอกคำสั่งแพทย์แล้ว: $orderText'
                                      : 'Copied HIS Order: $orderText',
                                ),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          key: const Key('copy_pharmacist_note_button'),
                          icon: const Icon(Icons.assignment, size: 18),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              t
                                  ? 'คัดลอกบันทึกเภสัชกร (Pharmacist Note)'
                                  : 'Copy Pharmacist Note',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.teal.shade900,
                            side: BorderSide(color: Colors.teal.shade700, width: 1.5),
                            minimumSize: const Size(0, 48),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            final p = _lastEvaluatedPatient ?? _buildCurrentPatient();
                            final noteText =
                                ClinicalOrderFormatter.formatPharmacistNote(
                              patient: p,
                              drug: widget.drug,
                              regimen: _selectedRegimen!,
                              result: res,
                              isThai: t,
                            );
                            Clipboard.setData(ClipboardData(text: noteText));
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                content: Text(
                                  t
                                      ? 'คัดลอกบันทึกเภสัชกรแล้ว'
                                      : 'Copied Pharmacist Note to clipboard',
                                ),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                if (_warnings.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  ..._warnings
                      .map(
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
                      )
                      ,
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Weight Selection Logic Card
        if (_dosingWeightLabel != null && _dosingWeightValue != null)
          Card(
            color: Colors.blue.shade50,
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.blue.shade200, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.monitor_weight,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t
                              ? 'น้ำหนักที่ใช้คำนวณไต (Dosing Weight): $_dosingWeightLabel'
                              : 'Renal Dosing Weight: $_dosingWeightLabel',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_dosingWeightValue!.toStringAsFixed(1)} kg - ${_dosingWeightReason ?? ""}',
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Copy-ready Note Card
        _buildCopyReadyNote(),
      ],
    );
  }

  Widget _buildCopyReadyNote() {
    final t = widget.isThai;
    final res = _result!;
    final p = _lastEvaluatedPatient ?? _buildCurrentPatient();
    final noteText = ClinicalOrderFormatter.formatPharmacistNote(
      patient: p,
      drug: widget.drug,
      regimen: _selectedRegimen!,
      result: res,
      isThai: t,
    );

    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.content_paste,
                        color: Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t
                              ? 'ข้อความพร้อมคัดลอก (Copy-ready Note)'
                              : 'Copy-ready Note',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, color: Colors.blue),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: noteText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          t ? 'คัดลอกข้อความแล้ว' : 'Copied to clipboard',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const Divider(),
            SelectableText(
              noteText,
              style: const TextStyle(
                fontFamily: 'Courier',
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.teal.shade400, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sync_rounded, color: Colors.teal.shade800, size: 18),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          t ? 'CRRT: เฝ้าระวังระดับยาต่อเนื่อง' : 'CRRT: Continuous Dialysis Mode',
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.deepPurple.shade400, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time_filled, color: Colors.deepPurple.shade800, size: 18),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          t ? 'Post-HD: ให้ยาหลังการฟอกเลือด' : 'Post-HD: Administer after dialysis',
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.indigo.shade300, width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bloodtype, color: Colors.indigo.shade800, size: 18),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          t ? 'IHD: ฟอกเลือดด้วยไตเทียม' : 'IHD: Hemodialysis Mode',
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade300, width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swap_horiz_rounded, color: Colors.blue.shade800, size: 18),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          t ? 'CAPD: ล้างไตทางช่องท้อง' : 'CAPD: Peritoneal Dialysis',
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
          if (res.rrtInstructionTh != null || res.rrtInstructionEn != null) ...[
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
                  Icon(Icons.info_outline, size: 16, color: Colors.grey.shade700),
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
