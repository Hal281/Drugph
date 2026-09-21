import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/models/models.dart';
import '../core/calculators/calculators.dart';
import '../core/validators/input_validator.dart';
import '../core/audit/calculation_log.dart';
import '../data/history_service.dart';
import '../data/patient_session.dart';
import '../data/prescription_cart.dart';
import 'iv_titration_screen.dart';
import 'tdm_screen.dart';

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
  DosingRegimen? _selectedRegimen;

  DosageResult? _result;
  List<DoseWarning> _warnings = [];

  // UI Display for weight selection
  String? _dosingWeightLabel;
  double? _dosingWeightValue;
  String? _dosingWeightReason;

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

    // 3. Perform Calculations based on Regimen
    double dose = 0;
    double? crcl;
    List<DoseWarning> warnings = [];

    // --- Pharmacist Logic: Determine Dosing Weight for CrCl ---
    double? crclDosingWeight = weight;
    String dosingWeightLabel = 'TBW';
    String dosingWeightReason = 'ใช้ TBW เนื่องจากไม่มีข้อมูลส่วนสูง';
    double? ibw;

    if (weight != null && height != null) {
      ibw = WeightBasedCalculator.idealBodyWeight(heightCm: height, sex: _sex);
      if (weight < ibw) {
        crclDosingWeight = weight;
        dosingWeightLabel = 'TBW';
        dosingWeightReason =
            'ใช้ TBW เนื่องจากน้ำหนักตัวจริงน้อยกว่า IBW (${ibw.toStringAsFixed(1)} kg)';
      } else if (weight < 1.25 * ibw) {
        crclDosingWeight = ibw;
        dosingWeightLabel = 'IBW';
        dosingWeightReason = 'ใช้ IBW เนื่องจากน้ำหนักตัวอยู่ในเกณฑ์ปกติ';
      } else {
        final adjBw = ibw + 0.4 * (weight - ibw);
        crclDosingWeight = adjBw;
        dosingWeightLabel = 'AdjBW';
        dosingWeightReason =
            'ใช้ AdjBW เนื่องจากน้ำหนักตัวจริงมากกว่า 125% ของ IBW';
      }
    }

    // Update UI state for weight selection
    _dosingWeightLabel = dosingWeightLabel;
    _dosingWeightValue = crclDosingWeight;
    _dosingWeightReason = dosingWeightReason;

    // Calculate CrCl if needed and SCr is provided
    if (scr != null && age != null && crclDosingWeight != null) {
      if (!_isScrStable) {
        // AKI check: Do not calculate CrCl if not stable
        warnings.add(DoseWarning(
          severity: LimitSeverity.hard,
          messageEn: 'AKI Alert: SCr is not stable. Cockcroft-Gault is inaccurate.',
          messageTh: 'AKI Alert: ค่า SCr ไม่คงที่ สูตร Cockcroft-Gault จะไม่แม่นยำ (ห้ามใช้ CrCl นี้)',
        ));
      } else {
        crcl = RenalCalculator.cockcroftGault(
            ageYears: age, weightKg: crclDosingWeight, sex: _sex, serumCreatinineMgDl: scr);

        // Low SCr in elderly check
        if (scr < 0.6 && age >= 65) {
          warnings.add(DoseWarning(
            severity: LimitSeverity.soft,
            messageEn: 'Elderly with low SCr (<0.6). CrCl may be overestimated.',
            messageTh: 'ผู้สูงอายุที่มี SCr ต่ำ (<0.6) ค่า CrCl ที่ได้อาจสูงเกินจริง (พิจารณาปัด SCr เป็น 0.8 หรือ 1.0)',
          ));
        }
      }
    }

    final regimen = _selectedRegimen!;

    if (regimen.dosingType == DosingType.weightBased) {
      // NOTE: For drugs like Vancomycin, dosing dose is strictly TBW.
      // So we use 'weight' (TBW) here, not 'crclDosingWeight'.
      dose = WeightBasedCalculator.calculateDose(
        weightKg: weight!,
        dosePerKg: regimen.dosePerKg ?? 0,
      );
    } else if (regimen.dosingType == DosingType.fixed) {
      dose = regimen.fixedDose ?? 0;
    } else if (regimen.dosingType == DosingType.bsaBased) {
      final bsa = BsaCalculator.mosteller(heightCm: height!, weightKg: weight!);
      dose = WeightBasedCalculator.calculateBsaDose(
        bsaM2: bsa,
        dosePerM2: regimen.dosePerM2 ?? 0,
      );
    } else if (regimen.dosingType == DosingType.titrated) {
      dose = regimen.continuousRateMin ?? 0;
    }

    // 4. Automated Renal Adjuster & Formulary Rounder
    double finalDose = dose;
    String finalFrequency = regimen.frequency;
    bool isRenallyAdjusted = false;
    double? appliedRenalFactor;

    if (crcl != null && regimen.renalAdjustments != null) {
      for (final adj in regimen.renalAdjustments!) {
        if (adj.appliesTo(crcl)) {
          if (adj.adjustmentFactor < 1.0 || adj.adjustedFrequency != null) {
            finalDose = finalDose * adj.adjustmentFactor;
            finalFrequency = adj.adjustedFrequency ?? finalFrequency;
            isRenallyAdjusted = true;
            appliedRenalFactor = adj.adjustmentFactor;
            
            warnings.add(DoseWarning(
              severity: LimitSeverity.info,
              messageEn: 'Auto Renal Adjustment applied (CrCl ${crcl.toStringAsFixed(1)} mL/min).',
              messageTh: 'ปรับขนาดยาอัตโนมัติตามค่า CrCl ${crcl.toStringAsFixed(1)} mL/min แล้ว',
            ));
          }
          break; // Match only the first applicable tier
        }
      }
    }

    double? roundedDose;
    if (widget.drug.availableStrengths != null && widget.drug.availableStrengths!.isNotEmpty) {
      roundedDose = DoseRounder.roundToNearestStrength(finalDose, widget.drug.availableStrengths!);
    }

    // Safety Checks against original un-adjusted dose limits (or adjusted depending on policy, but checking against base is safer)
    if (regimen.limits != null) {
      warnings.addAll(
        DoseChecker.checkDose(
          calculatedDose: finalDose,
          limits: regimen.limits!,
          doseUnit: regimen.doseUnit.symbol,
          weightKg: weight,
          dailyDose: _calculateDailyDose(finalDose, finalFrequency),
        ),
      );
    }

    if (widget.drug.isHighAlert) {
      warnings.insert(0, DoseChecker.highAlertWarning(widget.drug.genericName));
    }

    final dosageResult = DosageResult(
      success: true,
      calculatedDose: finalDose,
      doseUnit: regimen.doseUnit,
      frequency: finalFrequency,
      formulaUsed: regimen.dosingType.nameEn,
      crclMlMin: crcl,
      isRenallyAdjusted: isRenallyAdjusted,
      renalAdjustmentFactor: appliedRenalFactor,
      roundedDose: roundedDose,
      warnings: warnings,
    );

    setState(() {
      _warnings = warnings;
      _result = dosageResult;
    });

    // 5. Save to Audit Log
    final log = CalculationLog(
      logId: DateTime.now().millisecondsSinceEpoch.toString(), // Mock UUID
      timestamp: DateTime.now(),
      userId: 'MD-001', // Mock logged in user
      patientId: 'HN-Unknown',
      drugName: widget.drug.genericName,
      drugId: widget.drug.id,
      route: regimen.route.abbreviation,
      indication: regimen.indication,
      inputs: {
        'weightKg': weight,
        'heightCm': height,
        'ageYears': age,
        'sex': _sex.nameEn,
        'scr': scr,
      },
      result: dosageResult,
      formulaUsed: regimen.dosingType.nameEn,
      softwareVersion: '0.1.0-prototype',
    );
    HistoryService().addLog(log);
  }

  double? _calculateDailyDose(double singleDose, String frequency) {
    if (frequency.contains('q24h') || frequency.contains('OD'))
      return singleDose;
    if (frequency.contains('q12h') || frequency.contains('BID'))
      return singleDose * 2;
    if (frequency.contains('q8h') || frequency.contains('TID'))
      return singleDose * 3;
    if (frequency.contains('q6h') || frequency.contains('QID'))
      return singleDose * 4;
    return null;
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Colors.red)),
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
                            Text(
                              t
                                  ? 'ข้อบ่งใช้ / วิธีบริหารยา'
                                  : 'Indication / Route',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
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
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                _heightCtrl,
                                t ? 'ส่วนสูง (cm)' : 'Height (cm)',
                                Icons.height,
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
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                _scrCtrl,
                                t ? 'Cr (mg/dL)' : 'SCr (mg/dL)',
                                Icons.water_drop_outlined,
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
                        const SizedBox(height: 8),
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
                                MaterialStateProperty.resolveWith<Color>((
                                  Set<MaterialState> states,
                                ) {
                                  if (states.contains(MaterialState.selected)) {
                                    return widget.categoryColor.withOpacity(
                                      0.2,
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
                    color: Colors.black.withOpacity(0.05),
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

  Widget _buildAlertCard(IconData icon, Color color, String text) {
    return Card(
      color: color.withOpacity(0.1),
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color.withOpacity(0.5), width: 1),
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
                  color: color.withOpacity(0.9),
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
      color: color.withOpacity(0.1),
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color.withOpacity(0.5), width: 1),
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
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color.withOpacity(0.9),
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
                      style: TextStyle(color: color.withOpacity(0.9)),
                    ),
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon,
  ) {
    return TextField(
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Result Card
        Card(
          color: Colors.green.shade50,
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Colors.green, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      t ? 'ผลการคำนวณ' : 'Calculated Result',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (res.roundedDose != null) ...[
                  Text(
                    t ? 'ขนาดยาที่แนะนำ (ปัดเศษแล้ว)' : 'Recommended Dose (Rounded)',
                    style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.w600),
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
                    '${res.frequency!}',
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
                if (widget.drug.genericName.toLowerCase().contains('vancomycin')) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
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
                      final p = PatientSession.instance.currentPatient.value ?? Patient(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        weightKg: double.tryParse(_weightCtrl.text) ?? 70,
                        heightCm: double.tryParse(_heightCtrl.text) ?? 170,
                        ageYears: int.tryParse(_ageCtrl.text) ?? 35,
                        sex: _sex,
                        creatinineClearanceMlMin: res.crclMlMin,
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
                      .toList(),
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

    // Construct the note text
    final buffer = StringBuffer();
    buffer.writeln('📌 [Pharmacist Note: Renal Dose Adjustment]');

    final sexStr = _sex == Sex.male
        ? (t ? 'ชาย' : 'Male')
        : (t ? 'หญิง' : 'Female');
    buffer.writeln(
      '- Pt Info: ${_ageCtrl.text}Y $sexStr | TBW ${_weightCtrl.text} kg, Ht ${_heightCtrl.text} cm',
    );

    if (res.crclMlMin != null) {
      buffer.writeln(
        '- Renal function: SCr ${_scrCtrl.text} (Stable) -> CrCl ~${res.crclMlMin!.toStringAsFixed(1)} mL/min (ใช้น้ำหนัก $_dosingWeightLabel)',
      );
    } else if (!_isScrStable) {
      buffer.writeln('- Renal function: SCr ${_scrCtrl.text} (Unstable / AKI)');
    } else {
      buffer.writeln('- Renal function: Unknown');
    }

    final doseStr = res.roundedDose != null
        ? '${res.roundedDose?.toStringAsFixed(0)} ${res.doseUnit?.symbol}'
        : '${res.calculatedDose?.toStringAsFixed(2)} ${res.doseUnit?.symbol}';
    final freqStr = res.frequency ?? '';
    
    buffer.write(
      '- Recommendation: แนะนำปรับยาเป็น **${widget.drug.genericName} $doseStr $freqStr**',
    );
    
    if (res.roundedDose != null || res.isRenallyAdjusted) {
      buffer.write(' (');
      final reasons = <String>[];
      if (res.isRenallyAdjusted) reasons.add('ปรับโดสตามไต');
      if (res.roundedDose != null) reasons.add('ปัดเศษตามขนาดยาที่มี');
      buffer.write(reasons.join(' และ '));
      buffer.write(')');
    }
    buffer.writeln();

    final noteText = buffer.toString();

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
                Row(
                  children: [
                    const Icon(
                      Icons.content_paste,
                      color: Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      t
                          ? 'ข้อความพร้อมคัดลอก (Copy-ready Note)'
                          : 'Copy-ready Note',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
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
}
