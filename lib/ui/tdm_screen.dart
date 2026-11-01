import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../core/models/patient.dart';
import '../core/models/drug.dart';
import '../core/models/unit.dart';
import '../core/calculators/tdm_calculator.dart';
import '../core/calculators/renal_calculator.dart';
import '../core/calculators/dose_rounder.dart';
import 'widgets/clinical_evidence_sheet.dart';

class TdmScreen extends StatefulWidget {
  final Patient patient;
  final Drug drug;
  final bool isThai;

  const TdmScreen({
    super.key,
    required this.patient,
    required this.drug,
    required this.isThai,
  });

  @override
  State<TdmScreen> createState() => _TdmScreenState();
}

class _TdmScreenState extends State<TdmScreen> {
  late double _maintDose;
  late double _intervalHrs;
  double _infusionTimeHrs = 1.0;
  bool _show24HourWindow = true;

  // PK Mode: false = Empiric Population PK, true = 2-Point Sawchuk-Zaske Measured Levels
  bool _useMeasuredLevels = false;
  VancomycinVdModel _vdModel = VancomycinVdModel.standardAdult;

  // 2-Point Sawchuk-Zaske Measured Level Controllers
  late final TextEditingController _c1Ctrl;
  late final TextEditingController _c2Ctrl;
  late final TextEditingController _deltaHoursCtrl;
  late final TextEditingController _t1PostInfHoursCtrl;

  // Hartford Extended-Interval Nomogram Controllers (for Gentamicin / Amikacin)
  late final TextEditingController _hartfordLevelCtrl;
  late final TextEditingController _hartfordHoursCtrl;

  static const List<double> _standardIntervals = [8.0, 12.0, 24.0, 36.0, 48.0];
  static const List<double> _standardInfusionHours = [0.5, 1.0, 1.5, 2.0, 2.5];

  bool get _isAminoglycoside =>
      widget.drug.id == 'gentamicin' || widget.drug.id == 'amikacin';

  bool get _isAmikacin => widget.drug.id == 'amikacin';

  @override
  void initState() {
    super.initState();
    final patient = widget.patient;

    if (_isAminoglycoside) {
      final dosingWt = TdmCalculator.calculateAminoglycosideDosingWeight(
        weightKg: patient.weightKg,
        heightCm: patient.heightCm,
        isMale: patient.sex == Sex.male,
      );
      if (_isAmikacin) {
        final raw = dosingWt * 15.0;
        _maintDose = ((raw / 50.0).round() * 50.0).clamp(250.0, 1500.0);
        _c1Ctrl = TextEditingController(text: '42.0');
        _c2Ctrl = TextEditingController(text: '2.0');
        _hartfordLevelCtrl = TextEditingController(text: '10.0');
      } else {
        final raw = dosingWt * 5.0;
        _maintDose = ((raw / 20.0).round() * 20.0).clamp(80.0, 700.0);
        _c1Ctrl = TextEditingController(text: '18.0');
        _c2Ctrl = TextEditingController(text: '0.8');
        _hartfordLevelCtrl = TextEditingController(text: '4.5');
      }
      _intervalHrs = 24.0;
      _infusionTimeHrs = 1.0;
      _deltaHoursCtrl = TextEditingController(text: '10.0');
      _t1PostInfHoursCtrl = TextEditingController(text: '0.5');
      _hartfordHoursCtrl = TextEditingController(text: '8.0');
    } else {
      _maintDose = 1000.0;
      _intervalHrs = 12.0;
      _infusionTimeHrs = 1.0;
      _c1Ctrl = TextEditingController(text: '28.0');
      _c2Ctrl = TextEditingController(text: '12.5');
      _deltaHoursCtrl = TextEditingController(text: '9.0');
      _t1PostInfHoursCtrl = TextEditingController(text: '1.0');
      _hartfordLevelCtrl = TextEditingController(text: '4.5');
      _hartfordHoursCtrl = TextEditingController(text: '8.0');
    }
  }

  @override
  void dispose() {
    _c1Ctrl.dispose();
    _c2Ctrl.dispose();
    _deltaHoursCtrl.dispose();
    _t1PostInfHoursCtrl.dispose();
    _hartfordLevelCtrl.dispose();
    _hartfordHoursCtrl.dispose();
    super.dispose();
  }

  double _resolveCrCl(Patient patient) {
    if (patient.creatinineClearanceMlMin != null) {
      return patient.creatinineClearanceMlMin!;
    }
    if (patient.serumCreatinineMgDl != null &&
        patient.serumCreatinineMgDl! > 0 &&
        patient.ageYears >= 18) {
      return RenalCalculator.cockcroftGault(
        ageYears: patient.ageYears,
        weightKg: patient.weightKg,
        sex: patient.sex,
        serumCreatinineMgDl: patient.serumCreatinineMgDl!,
      );
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;
    final crcl = _resolveCrCl(patient);

    // --- 1. Determine Population PK Parameters ---
    final double popVd;
    final double popKe;
    final double? agDosingWeight;

    if (_isAminoglycoside) {
      agDosingWeight = TdmCalculator.calculateAminoglycosideDosingWeight(
        weightKg: patient.weightKg,
        heightCm: patient.heightCm,
        isMale: patient.sex == Sex.male,
      );
      popVd = TdmCalculator.calculateAminoglycosideVd(
        dosingWeightKg: agDosingWeight,
      );
      popKe = TdmCalculator.calculateAminoglycosideKe(crclMlMin: crcl);
    } else {
      agDosingWeight = null;
      popVd = TdmCalculator.calculateVdWithModel(
        weightKg: patient.weightKg,
        model: _vdModel,
      );
      popKe = TdmCalculator.calculateKe(crclMlMin: crcl);
    }

    // --- 2. Evaluate Optional 2-Point Sawchuk-Zaske Individualized PK ---
    SawchukZaskeAnalysis? sawchukAnalysis;
    String? sawchukError;
    if (_useMeasuredLevels) {
      final c1 = double.tryParse(_c1Ctrl.text);
      final c2 = double.tryParse(_c2Ctrl.text);
      final dt = double.tryParse(_deltaHoursCtrl.text);
      final t1Post = double.tryParse(_t1PostInfHoursCtrl.text) ?? 1.0;

      if (c1 == null || c1 <= 0 || c2 == null || c2 <= 0 || dt == null || dt <= 0) {
        sawchukError = widget.isThai
            ? 'กรุณาระบุค่า C1, C2 และระยะเวลาห่างกัน (Δt) ที่มากกว่า 0'
            : 'Please enter valid C1 > 0, C2 > 0, and Δt > 0 hours.';
      } else if (c1 <= c2) {
        sawchukError = widget.isThai
            ? 'ระดับยา Peak (C1 = $c1 mg/L) ต้องมากกว่าระดับยา Trough (C2 = $c2 mg/L)'
            : 'Earlier level C1 ($c1 mg/L) must be strictly greater than later level C2 ($c2 mg/L).';
      } else {
        try {
          sawchukAnalysis = TdmCalculator.analyzeTwoPointSawchukZaske(
            dose: _maintDose,
            tau: _intervalHrs,
            tInf: _infusionTimeHrs,
            c1: c1,
            c2: c2,
            deltaHours: dt,
            t1PostInfusionHours: math.max(0.0, t1Post),
            isVancomycin: !_isAminoglycoside,
          );
        } catch (e) {
          sawchukError = e.toString();
        }
      }
    }

    final effectiveVd = sawchukAnalysis?.individualVdLiters ?? popVd;
    final effectiveKe = sawchukAnalysis?.individualKe ?? popKe;
    final halfLife = TdmCalculator.calculateHalfLife(ke: effectiveKe);

    // --- 3. Loading Dose ---
    final double ldMinMgPerKg = _isAminoglycoside
        ? (_isAmikacin ? 15.0 : 5.0)
        : 25.0;
    final double ldMaxMgPerKg = _isAminoglycoside
        ? (_isAmikacin ? 20.0 : 7.0)
        : 30.0;
    final double ldCapMg = _isAminoglycoside
        ? (_isAmikacin ? 1500.0 : 700.0)
        : 3000.0;
    final ldBasisKg = agDosingWeight ?? patient.weightKg;
    final ldRange = TdmCalculator.calculateLoadingDose(
      weightKg: ldBasisKg,
      minMgPerKg: ldMinMgPerKg,
      maxMgPerKg: ldMaxMgPerKg,
      absoluteMaxMg: ldCapMg,
    );
    const vialStrengths = [
      250.0,
      500.0,
      750.0,
      1000.0,
      1250.0,
      1500.0,
      1750.0,
      2000.0,
      2250.0,
      2500.0,
      2750.0,
      3000.0,
    ];
    final ldMinRounded = _isAminoglycoside
        ? ldRange[0]
        : (DoseRounder.roundToNearestStrength(
              ldRange[0],
              vialStrengths,
              isSplittable: false,
            ) ??
            ldRange[0]);
    final ldMaxRounded = _isAminoglycoside
        ? ldRange[1]
        : (DoseRounder.roundToNearestStrength(
              ldRange[1],
              vialStrengths,
              isSplittable: false,
            ) ??
            ldRange[1]);

    // --- 4. Steady-State PK Profile (Cmax,ss, Cmin,ss, AUC24, Curve) ---
    final pkProfile = TdmCalculator.generateSteadyStateProfile(
      dose: _maintDose,
      tau: _intervalHrs,
      tInf: _infusionTimeHrs,
      vd: effectiveVd,
      ke: effectiveKe,
    );

    final predictedPeak = pkProfile.peakMgL;
    final predictedTrough = pkProfile.troughMgL;
    final predictedAuc24 = pkProfile.auc24MgHrL;

    // Recommended dose for target AUC24 = 500 mg·hr/L (Vancomycin) or target Peak (Aminoglycoside)
    final recommendedMaintDoseRaw = TdmCalculator.recommendDoseForTargetAuc24(
      // AUC24 400–600 (midpoint 500) is a Vancomycin-only target (ASHP/IDSA 2020).
      // Aminoglycosides are dosed by peak/MIC & trough/nomogram, so this value is
      // only rendered when !_isAminoglycoside (see AUC card below).
      targetAuc: 500.0,
      tau: _intervalHrs,
      vd: effectiveVd,
      ke: effectiveKe,
    );

    // --- 5. Optional Hartford Nomogram Evaluation (for Gentamicin / Amikacin) ---
    HartfordNomogramEvaluation? hartfordEval;
    if (_isAminoglycoside) {
      final hLevel = double.tryParse(_hartfordLevelCtrl.text);
      final hHours = double.tryParse(_hartfordHoursCtrl.text);
      if (hLevel != null && hLevel > 0 && hHours != null && hHours > 0) {
        hartfordEval = TdmCalculator.evaluateHartfordNomogram(
          randomLevelMgL: hLevel,
          hoursPostDose: hHours,
          isAmikacin: _isAmikacin,
        );
      }
    }

    final targetTroughBandMin = _isAminoglycoside ? 0.0 : 10.0;
    final targetTroughBandMax = _isAminoglycoside
        ? (_isAmikacin ? 5.0 : 2.0)
        : 20.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isThai
              ? 'การคำนวณ TDM: ${widget.drug.genericName}'
              : 'TDM: ${widget.drug.genericName}',
        ),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            key: const Key('tdm_open_monograph_btn'),
            icon: const Icon(Icons.menu_book_rounded),
            tooltip: widget.isThai ? 'เปิดดูตำราอ้างอิง' : 'Textbook Monograph',
            onPressed: () => ClinicalEvidenceSheet.show(
              context,
              drug: widget.drug,
              regimen: widget.drug.regimens.isNotEmpty
                  ? widget.drug.regimens.first
                  : null,
              isThai: widget.isThai,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // Patient summary
          Card(
            color: Colors.purple.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    widget.isThai
                        ? 'น้ำหนักจริง (TBW): ${patient.weightKg.toStringAsFixed(1)} kg | CrCl: ${crcl.toStringAsFixed(1)} mL/min'
                        : 'Weight (TBW): ${patient.weightKg.toStringAsFixed(1)} kg | CrCl: ${crcl.toStringAsFixed(1)} mL/min',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (agDosingWeight != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.isThai
                          ? 'น้ำหนักที่ใช้คำนวณ Aminoglycoside (IBW/AdjBW): ${agDosingWeight.toStringAsFixed(1)} kg'
                          : 'Aminoglycoside Dosing Weight (IBW/AdjBW): ${agDosingWeight.toStringAsFixed(1)} kg',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple.shade900,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // PK Calculation Mode Selector (Empiric Population PK vs 2-Point Sawchuk-Zaske TDM)
          Card(
            elevation: 0,
            color: const Color(0xFFF8FAFC),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.purple.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isThai
                        ? 'โหมดการคำนวณเภสัชจลนศาสตร์ (PK Calculation Method):'
                        : 'PK Calculation Method:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<bool>(
                      key: const Key('tdm_pk_mode_toggle'),
                      segments: [
                        ButtonSegment<bool>(
                          value: false,
                          icon: const Icon(Icons.groups_rounded, size: 16),
                          label: Text(
                            widget.isThai
                                ? 'Empiric (ประชากร / เริ่มต้น)'
                                : 'Empiric (Population PK)',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        ButtonSegment<bool>(
                          value: true,
                          icon: const Icon(Icons.biotech_rounded, size: 16),
                          label: Text(
                            widget.isThai
                                ? '2-Point TDM (Sawchuk-Zaske)'
                                : '2-Point Measured Levels',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                      selected: {_useMeasuredLevels},
                      onSelectionChanged: (s) =>
                          setState(() => _useMeasuredLevels = s.first),
                    ),
                  ),

                  // Vancomycin Population Vd Model Selector (when in Empiric mode)
                  if (!_useMeasuredLevels && !_isAminoglycoside) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          widget.isThai ? 'แบบจำลอง Vd:' : 'Vd Model:',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blueGrey,
                          ),
                        ),
                        ...VancomycinVdModel.values.map((m) {
                          final selected = _vdModel == m;
                          return ChoiceChip(
                            key: Key('tdm_vd_model_${m.name}'),
                            label: Text(
                              widget.isThai ? m.labelTh : m.labelEn,
                              style: const TextStyle(fontSize: 11),
                            ),
                            selected: selected,
                            visualDensity: VisualDensity.compact,
                            onSelected: (_) => setState(() => _vdModel = m),
                          );
                        }),
                      ],
                    ),
                  ],

                  // 2-Point Sawchuk-Zaske Measured Serum Concentration Inputs
                  if (_useMeasuredLevels) ...[
                    const SizedBox(height: 12),
                    Container(
                      key: const Key('tdm_sawchuk_zaske_panel'),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isThai
                                ? 'กรอกผลเจาะระดับยาในเลือด 2 จุด (Sawchuk-Zaske Individualized TDM)'
                                : 'Two-Point Serum Concentration Inputs (Sawchuk-Zaske Method)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.purple.shade800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  key: const Key('tdm_c1_input'),
                                  controller: _c1Ctrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: InputDecoration(
                                    labelText: widget.isThai
                                        ? 'Peak C₁ (mg/L)'
                                        : 'Post-Infusion C₁ (mg/L)',
                                    isDense: true,
                                    border: const OutlineInputBorder(),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  key: const Key('tdm_t1_post_input'),
                                  controller: _t1PostInfHoursCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: InputDecoration(
                                    labelText: widget.isThai
                                        ? 'เจาะหลังดริปจบ (hr)'
                                        : 'Hours Post-Infusion',
                                    isDense: true,
                                    border: const OutlineInputBorder(),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  key: const Key('tdm_c2_input'),
                                  controller: _c2Ctrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: InputDecoration(
                                    labelText: widget.isThai
                                        ? 'Trough C₂ (mg/L)'
                                        : 'Pre-Dose Trough C₂ (mg/L)',
                                    isDense: true,
                                    border: const OutlineInputBorder(),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  key: const Key('tdm_delta_t_input'),
                                  controller: _deltaHoursCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: InputDecoration(
                                    labelText: widget.isThai
                                        ? 'ระยะเวลาห่างกัน Δt (hr)'
                                        : 'Time Between Draws Δt (hr)',
                                    isDense: true,
                                    border: const OutlineInputBorder(),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                          if (sawchukError != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              sawchukError,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          if (sawchukAnalysis != null) ...[
                            if (sawchukAnalysis.hasShortSamplingIntervalWarning ||
                                sawchukAnalysis.hasDistributionPhaseWarning) ...[
                              const SizedBox(height: 8),
                              Container(
                                key: const Key('tdm_sawchuk_timing_warning'),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.amber.shade600,
                                  ),
                                ),
                                child: Text(
                                  sawchukAnalysis.hasShortSamplingIntervalWarning
                                      ? (widget.isThai
                                          ? '⚠️ คำเตือนการเจาะเลือด: ระยะเวลาห่างระหว่าง C₁ และ C₂ น้อยกว่า 2 ชม. อาจทำให้ค่า Ke คลาดเคลื่อนสูง'
                                          : '⚠️ Timing Advisory: Δt < 2.0 hours between C₁ and C₂ may amplify assay error in Ke.')
                                      : (widget.isThai
                                          ? '⚠️ คำเตือนการเจาะเลือด: การเจาะ C₁ ของ Vancomycin เร็วกว่า 1 ชม. หลังดริปจบ อยู่ในระยะกระจายตัว (α-distribution phase) อาจประเมินค่า Ke สูงเกินจริง'
                                          : '⚠️ Timing Advisory: Vancomycin C₁ drawn < 1.0 hr post-infusion falls in the α-distribution phase.'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.amber.shade900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              widget.isThai
                                  ? '✓ คำนวณพารามิเตอร์เฉพาะรายแล้ว: True Cmax = ${sawchukAnalysis.truePeakMgL.toStringAsFixed(1)} mg/L | True Cmin = ${sawchukAnalysis.trueTroughMgL.toStringAsFixed(1)} mg/L'
                                  : '✓ Individualized PK Applied: True Cmax = ${sawchukAnalysis.truePeakMgL.toStringAsFixed(1)} mg/L | True Cmin = ${sawchukAnalysis.trueTroughMgL.toStringAsFixed(1)} mg/L',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // PK Parameters
          _SectionHeader(
            title: widget.isThai
                ? (sawchukAnalysis != null
                    ? 'ค่าพารามิเตอร์ทางเภสัชจลนศาสตร์เฉพาะราย (Individualized PK)'
                    : 'ค่าพารามิเตอร์ทางเภสัชจลนศาสตร์ (Population PK)')
                : (sawchukAnalysis != null
                    ? 'Individualized PK Parameters (Sawchuk-Zaske)'
                    : 'Population PK Parameters'),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _InfoRow(
                    label: sawchukAnalysis != null
                        ? 'Individual Vd'
                        : (_isAminoglycoside
                            ? 'Vd (0.25 L/kg IBW/AdjBW)'
                            : 'Vd (${_vdModel.litersPerKg.toStringAsFixed(2)} L/kg)'),
                    value: '${effectiveVd.toStringAsFixed(1)} L',
                  ),
                  const Divider(),
                  _InfoRow(
                    label: sawchukAnalysis != null ? 'Individual Ke' : 'Ke',
                    value: '${effectiveKe.toStringAsFixed(4)} hr⁻¹',
                  ),
                  const Divider(),
                  _InfoRow(
                    label: 'Half-life (t½)',
                    value: '${halfLife.toStringAsFixed(1)} hr',
                  ),
                  const Divider(),
                  _InfoRow(
                    label: widget.isThai ? 'อัตราการกำจัดยา (CL)' : 'Clearance (CL)',
                    value: '${(effectiveVd * effectiveKe).toStringAsFixed(2)} L/hr',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Loading Dose
          _SectionHeader(
            title: widget.isThai
                ? 'ขนาดยานำ (Loading Dose / Extended-Interval Initial Dose)'
                : 'Loading Dose (LD) / Extended-Interval Dose',
          ),
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    _isAminoglycoside
                        ? (widget.isThai
                            ? 'คำนวณที่ ${ldMinMgPerKg.toStringAsFixed(0)}-${ldMaxMgPerKg.toStringAsFixed(0)} mg/kg ตาม IBW/AdjBW (สูงสุด ${ldCapMg.toStringAsFixed(0)} mg)'
                            : 'Target: ${ldMinMgPerKg.toStringAsFixed(0)}-${ldMaxMgPerKg.toStringAsFixed(0)} mg/kg IBW/AdjBW (Max ${ldCapMg.toStringAsFixed(0)} mg)')
                        : (widget.isThai
                            ? 'คำนวณที่ 25-30 mg/kg (สูงสุดไม่เกิน 3,000 mg)'
                            : 'Target: 25-30 mg/kg (Max 3,000 mg)'),
                    style: const TextStyle(color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${ldMinRounded.toStringAsFixed(0)} - ${ldMaxRounded.toStringAsFixed(0)} mg',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Hartford Extended-Interval Aminoglycoside Nomogram (for Gentamicin & Amikacin)
          if (_isAminoglycoside) ...[
            _SectionHeader(
              title: widget.isThai
                  ? 'กราฟ Hartford Extended-Interval Nomogram (เจาะระดับยาสุ่ม 6–14 ชม.)'
                  : 'Hartford Extended-Interval Nomogram (Random Level 6–14 hr)',
            ),
            Card(
              key: const Key('tdm_hartford_nomogram_card'),
              color: Colors.teal.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isThai
                          ? (_isAmikacin
                              ? 'สำหรับ Amikacin 15 mg/kg Once-Daily: ระบบจะหารระดับยาด้วย 2 อัตโนมัติเพื่อเทียบเกณฑ์ Hartford Nomogram (Nicolau 1995)'
                              : 'สำหรับ Gentamicin 7 mg/kg Once-Daily เท่านั้น: กรอกระดับยาที่เจาะหลังเริ่มดริปยา 6–14 ชั่วโมง (Nicolau 1995)')
                          : (_isAmikacin
                              ? 'For Amikacin 15 mg/kg Once-Daily: serum level is halved automatically to evaluate on the Hartford Nomogram (Nicolau 1995).'
                              : 'For Gentamicin 7 mg/kg Once-Daily only: enter random serum level drawn 6–14 hours after start of infusion (Nicolau 1995).'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.teal.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      key: const Key('tdm_hartford_pending_verification'),
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amber.shade700),
                      ),
                      child: Text(
                        widget.isThai
                            ? '⚠️ รอการตรวจรับรอง: เส้นแบ่งโซนของ Nomogram ถูกแปลงเป็นสมการเส้นตรงโดยประมาณ ยังไม่ได้เทียบกับรูปต้นฉบับ Nicolau 1995 โดยเภสัชกร — ใช้ประกอบการตัดสินใจเท่านั้น และไม่ใช้กับขนาดยา 5 mg/kg'
                            : '⚠️ Pending verification: nomogram zone boundaries are linear approximations not yet checked by a pharmacist against the original Nicolau 1995 figure. Decision support only; not valid for 5 mg/kg dosing.',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const Key('tdm_hartford_level_input'),
                            controller: _hartfordLevelCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                            decoration: InputDecoration(
                              labelText: widget.isThai
                                  ? 'ระดับยาสุ่ม (mg/L)'
                                  : 'Random Level (mg/L)',
                              filled: true,
                              fillColor: Colors.white,
                              isDense: true,
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            key: const Key('tdm_hartford_hours_input'),
                            controller: _hartfordHoursCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                            decoration: InputDecoration(
                              labelText: widget.isThai
                                  ? 'เวลาหลังเริ่มให้ยา (6–14 hr)'
                                  : 'Hours Post-Dose (6–14 hr)',
                              filled: true,
                              fillColor: Colors.white,
                              isDense: true,
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    if (hartfordEval != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        key: const Key('tdm_hartford_result_badge'),
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: hartfordEval.recommendedIntervalHours != null
                                ? Colors.teal.shade600
                                : Colors.red.shade600,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.isThai
                                  ? hartfordEval.recommendationTh
                                  : hartfordEval.recommendationEn,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color:
                                    hartfordEval.recommendedIntervalHours !=
                                        null
                                    ? Colors.teal.shade900
                                    : Colors.red.shade900,
                              ),
                            ),
                            if (hartfordEval.recommendedIntervalHours !=
                                null) ...[
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: OutlinedButton.icon(
                                  key: const Key(
                                    'tdm_apply_hartford_interval_btn',
                                  ),
                                  icon: const Icon(Icons.check_rounded, size: 16),
                                  label: Text(
                                    widget.isThai
                                        ? 'ใช้ระยะห่าง q${hartfordEval.recommendedIntervalHours}h ในกราฟจำลอง'
                                        : 'Apply q${hartfordEval.recommendedIntervalHours}h to Simulator',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  onPressed: () => setState(() {
                                    _intervalHrs = hartfordEval!
                                        .recommendedIntervalHours!
                                        .toDouble();
                                  }),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Maintenance Dose & PK Simulator
          _SectionHeader(
            title: widget.isThai
                ? 'จำลองระดับยา (Predicted Trough & Steady-State PK)'
                : 'Steady-State PK & Trough Simulator',
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _SpinnerNumberField(
                          key: const Key('tdm_dose_spinner'),
                          label: widget.isThai ? 'ขนาดยา (mg)' : 'Dose (mg)',
                          value: _maintDose,
                          step: _isAminoglycoside ? (_isAmikacin ? 50 : 20) : 250,
                          minValue: _isAminoglycoside ? 20 : 250,
                          onChanged: (v) => setState(() => _maintDose = v),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _SpinnerNumberField(
                          key: const Key('tdm_interval_spinner'),
                          label: widget.isThai
                              ? 'ความถี่ (hr)'
                              : 'Interval (hr)',
                          value: _intervalHrs,
                          step: 4,
                          minValue: 4,
                          onChanged: (v) => setState(() {
                            if (v > _infusionTimeHrs) {
                              _intervalHrs = v;
                            }
                          }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Quick Interval Chips (q8h, q12h, q24h, q36h, q48h)
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        widget.isThai ? 'ระยะห่างมาตรฐาน:' : 'Interval:',
                        style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                      ),
                      ..._standardIntervals.map((interval) {
                        final selected = (_intervalHrs - interval).abs() < 0.01;
                        return ChoiceChip(
                          key: Key('tdm_interval_chip_${interval.toInt()}'),
                          label: Text('q${interval.toInt()}h'),
                          selected: selected,
                          visualDensity: VisualDensity.compact,
                          onSelected: (_) => setState(() => _intervalHrs = interval),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Infusion Duration Chips (0.5h, 1h, 1.5h, 2h, 2.5h)
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        widget.isThai ? 'เวลาดริปยา (t_inf):' : 'Infusion Time:',
                        style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                      ),
                      ..._standardInfusionHours.map((hrs) {
                        final selected = (_infusionTimeHrs - hrs).abs() < 0.01;
                        return ChoiceChip(
                          key: Key('tdm_infusion_chip_${(hrs * 60).toInt()}m'),
                          label: Text('${hrs.toStringAsFixed(1)} hr'),
                          selected: selected,
                          visualDensity: VisualDensity.compact,
                          onSelected: (_) => setState(() => _infusionTimeHrs = hrs),
                        );
                      }),
                    ],
                  ),

                  // Non-blocking Red Man Syndrome Warning when Vancomycin infusion rate > 10 mg/min
                  if (!_isAminoglycoside && pkProfile.hasRedManSyndromeRisk) ...[
                    const SizedBox(height: 12),
                    Container(
                      key: const Key('tdm_red_man_warning'),
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFEF4444)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFDC2626),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.isThai
                                  ? '⚠️ คำเตือนอัตราการหยดยา: ${pkProfile.infusionRateMgPerMin.toStringAsFixed(1)} mg/min (> 10 mg/min) เสี่ยงเกิดภาวะ Red Man Syndrome — แนะนำเพิ่มเวลาดริปยาเป็น ≥ ${(_maintDose / 600.0).toStringAsFixed(1)} ชม.'
                                  : '⚠️ Infusion Rate Warning: ${pkProfile.infusionRateMgPerMin.toStringAsFixed(1)} mg/min (> 10 mg/min) risks Red Man Syndrome — extend infusion to ≥ ${(_maintDose / 600.0).toStringAsFixed(1)} hr.',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF991B1B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // AUC24 Primary Guideline Target Card
                  Container(
                    key: const Key('tdm_auc24_card'),
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getAucColor(predictedAuc24).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getAucColor(predictedAuc24),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isAminoglycoside
                                  ? Icons.analytics_outlined
                                  : (predictedAuc24 >= 400 && predictedAuc24 <= 600
                                      ? Icons.check_circle
                                      : Icons.warning_amber_rounded),
                              color: _getAucColor(predictedAuc24).shade900,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _isAminoglycoside
                                    ? (widget.isThai
                                        ? 'พื้นที่ใต้กราฟ 24 ชม. (AUC₂₄ Exposure)'
                                        : '24-Hour Exposure (AUC₂₄)')
                                    : (widget.isThai
                                        ? 'เป้าหมายหลัก: AUC₂₄ (ASHP 2020: 400–600 mg·hr/L)'
                                        : 'Primary Target: AUC₂₄ (ASHP 2020: 400–600 mg·hr/L)'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _getAucColor(predictedAuc24).shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${predictedAuc24.toStringAsFixed(1)} mg·hr/L',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: _getAucColor(predictedAuc24).shade900,
                          ),
                        ),
                        if (!_isAminoglycoside) ...[
                          Text(
                            predictedAuc24 < 400
                                ? (widget.isThai
                                    ? 'ต่ำกว่าเป้าหมาย (เสี่ยงรักษาไม่ได้ผล)'
                                    : 'Subtherapeutic')
                                : (predictedAuc24 <= 600
                                    ? (widget.isThai
                                        ? 'อยู่ในช่วงเป้าหมายการรักษา'
                                        : 'Target Therapeutic Range')
                                    : (widget.isThai
                                        ? 'สูงเกินเป้าหมาย (เสี่ยงต่อพิษไต AKI)'
                                        : 'Supratherapeutic / AKI Risk')),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getAucColor(predictedAuc24).shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.isThai
                                ? 'ขนาดยาที่แนะนำเพื่อให้ได้ AUC₂₄ ≈ 500: ${recommendedMaintDoseRaw.toStringAsFixed(0)} mg q${_intervalHrs.toInt()}h'
                                : 'Suggested dose for AUC₂₄ ≈ 500: ${recommendedMaintDoseRaw.toStringAsFixed(0)} mg q${_intervalHrs.toInt()}h',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Peak (Cmax,ss) and Trough (Cmin,ss) Side-by-Side Cards
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          key: const Key('tdm_peak_card'),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.indigo.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.indigo.shade300),
                          ),
                          child: Column(
                            children: [
                              Text(
                                widget.isThai
                                    ? 'ระดับยาสูงสุด Cmax,ss (Peak)'
                                    : 'Predicted Peak (Cmax,ss)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.indigo.shade900,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${predictedPeak.toStringAsFixed(1)} mg/L',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo.shade900,
                                ),
                              ),
                              Text(
                                _isAminoglycoside
                                    ? (_isAmikacin
                                        ? (widget.isThai
                                            ? 'เป้าหมาย: 40–60 (OD) / 20–35 mg/L'
                                            : 'Target: 40–60 (OD) / 20–35 mg/L')
                                        : (widget.isThai
                                            ? 'เป้าหมาย: 16–24 (OD) / 5–10 mg/L'
                                            : 'Target: 16–24 (OD) / 5–10 mg/L'))
                                    : (widget.isThai
                                        ? 'ที่เวลา t = ${_infusionTimeHrs.toStringAsFixed(1)} hr'
                                        : 'at t = ${_infusionTimeHrs.toStringAsFixed(1)} hr'),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.indigo.shade700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          key: const Key('tdm_trough_card'),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getTroughColor(predictedTrough).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getTroughColor(predictedTrough),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                widget.isThai
                                    ? 'ระดับยาต่ำสุด Cmin,ss (Trough)'
                                    : 'Predicted Trough (Cmin,ss)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _getTroughColor(predictedTrough).shade900,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${predictedTrough.toStringAsFixed(1)} mg/L',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: _getTroughColor(predictedTrough).shade900,
                                ),
                              ),
                              Text(
                                _isAminoglycoside
                                    ? (_isAmikacin
                                        ? (widget.isThai
                                            ? 'เป้าหมาย: < 2.5 (OD) / < 5 mg/L'
                                            : 'Target: < 2.5 (OD) / < 5 mg/L')
                                        : (widget.isThai
                                            ? 'เป้าหมาย: < 1.0 (OD) / < 2 mg/L'
                                            : 'Target: < 1.0 (OD) / < 2 mg/L'))
                                    : (widget.isThai
                                        ? 'เป้าหมาย: 10–20 mg/L'
                                        : 'Target: 10–20 mg/L'),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _getTroughColor(predictedTrough).shade800,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Steady-State Concentration-Time PK Graph Card
          _SectionHeader(
            title: widget.isThai
                ? 'กราฟระดับยาที่ภาวะคงที่ (Steady-State PK Curve: Cmax, Cmin & AUC)'
                : 'Steady-State Concentration-Time Graph (Cmax, Cmin & AUC)',
          ),
          Card(
            key: const Key('tdm_pk_graph_card'),
            elevation: 1,
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
                          widget.isThai
                              ? 'แบบจำลอง 1-Compartment Intermittent IV Infusion (Matzke / Sawchuk-Zaske)'
                              : '1-Compartment Intermittent IV Infusion Model (Matzke / Sawchuk-Zaske)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                      SegmentedButton<bool>(
                        key: const Key('tdm_graph_horizon_toggle'),
                        segments: [
                          ButtonSegment<bool>(
                            value: false,
                            label: Text(
                              widget.isThai ? '1 รอบ (τ)' : '1 Cycle (τ)',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          ButtonSegment<bool>(
                            value: true,
                            label: Text(
                              widget.isThai ? '24 ชั่วโมง' : '24 Hours',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                        selected: {_show24HourWindow},
                        onSelectionChanged: (s) =>
                            setState(() => _show24HourWindow = s.first),
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // CustomPaint PK Curve
                  SizedBox(
                    height: 240,
                    width: double.infinity,
                    child: SteadyStatePkChart(
                      key: const Key('tdm_steady_state_pk_chart'),
                      profile: pkProfile,
                      show24HourWindow: _show24HourWindow,
                      isThai: widget.isThai,
                      targetBandMinMgL: targetTroughBandMin,
                      targetBandMaxMgL: targetTroughBandMax,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Graph Legend
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _LegendItem(
                        color: const Color(0xFF6D28D9),
                        label: widget.isThai
                            ? 'เส้นระดับยา C_ss(t) & พื้นที่ใต้กราฟ (AUC)'
                            : 'Steady-State Curve C_ss(t) & AUC',
                      ),
                      _LegendItem(
                        color: const Color(0xFF16A34A),
                        label: _isAminoglycoside
                            ? (widget.isThai
                                ? 'ช่วงปลอดภัย Trough (< ${targetTroughBandMax.toStringAsFixed(0)} mg/L)'
                                : 'Safe Trough Band (< ${targetTroughBandMax.toStringAsFixed(0)} mg/L)')
                            : (widget.isThai
                                ? 'ช่วงเป้าหมาย Trough (10–20 mg/L)'
                                : 'Target Trough Band (10–20 mg/L)'),
                      ),
                      _LegendItem(
                        color: const Color(0xFFDC2626),
                        label: _isAminoglycoside
                            ? (widget.isThai
                                ? 'ขีดจำกัดพิษต่อไต/หู (Trough > ${targetTroughBandMax.toStringAsFixed(0)} mg/L)'
                                : 'Toxicity Threshold (Trough > ${targetTroughBandMax.toStringAsFixed(0)} mg/L)')
                            : (widget.isThai
                                ? 'ขีดจำกัดเฝ้าระวังพิษต่อไต (Trough > 20 mg/L)'
                                : 'Nephrotoxicity Threshold (Trough > 20 mg/L)'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  MaterialColor _getAucColor(double auc) {
    if (_isAminoglycoside) return Colors.blue;
    if (auc < 400) return Colors.orange;
    if (auc <= 600) return Colors.green;
    return Colors.red;
  }

  MaterialColor _getTroughColor(double trough) {
    if (_isAminoglycoside) {
      final limit = _isAmikacin ? 5.0 : 2.0;
      final strictLimit = _isAmikacin ? 2.5 : 1.0;
      if (trough <= strictLimit) return Colors.green;
      if (trough <= limit) return Colors.orange;
      return Colors.red;
    }
    if (trough < 10) return Colors.orange;
    if (trough <= 20) return Colors.green;
    return Colors.red;
  }
}

/// Deterministic CustomPaint widget that renders the steady-state concentration-time
/// curve (Cmax,ss, Cmin,ss, shaded AUC, and therapeutic trough window).
class SteadyStatePkChart extends StatelessWidget {
  final SteadyStatePkProfile profile;
  final bool show24HourWindow;
  final bool isThai;
  final double targetBandMinMgL;
  final double targetBandMaxMgL;

  const SteadyStatePkChart({
    super.key,
    required this.profile,
    this.show24HourWindow = true,
    this.isThai = true,
    this.targetBandMinMgL = 10.0,
    this.targetBandMaxMgL = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SteadyStatePkChartPainter(
        profile: profile,
        show24HourWindow: show24HourWindow,
        isThai: isThai,
        targetBandMinMgL: targetBandMinMgL,
        targetBandMaxMgL: targetBandMaxMgL,
      ),
    );
  }
}

class _SteadyStatePkChartPainter extends CustomPainter {
  final SteadyStatePkProfile profile;
  final bool show24HourWindow;
  final bool isThai;
  final double targetBandMinMgL;
  final double targetBandMaxMgL;

  _SteadyStatePkChartPainter({
    required this.profile,
    required this.show24HourWindow,
    required this.isThai,
    required this.targetBandMinMgL,
    required this.targetBandMaxMgL,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 44.0;
    const rightPad = 18.0;
    const topPad = 24.0;
    const bottomPad = 30.0;

    final plotWidth = math.max(1.0, size.width - leftPad - rightPad);
    final plotHeight = math.max(1.0, size.height - topPad - bottomPad);
    final plotRect = Rect.fromLTWH(leftPad, topPad, plotWidth, plotHeight);

    final points = show24HourWindow
        ? profile.twentyFourHourCurve
        : profile.singleIntervalCurve;
    if (points.isEmpty) return;

    final maxTime = points.last.timeHours;
    final yMaxRaw = math.max(profile.peakMgL * 1.2, targetBandMaxMgL * 1.5);
    // Round yMax up to a clean multiple of 10
    final yMax = ((yMaxRaw / 10.0).ceil() * 10.0).toDouble();

    double xForTime(double t) =>
        leftPad + (t / (maxTime <= 0 ? 1.0 : maxTime)) * plotWidth;
    double yForConc(double c) =>
        topPad + plotHeight - (c.clamp(0.0, yMax) / yMax) * plotHeight;

    // 1. Plot background
    final bgPaint = Paint()..color = const Color(0xFFF8FAFC);
    canvas.drawRRect(
      RRect.fromRectAndRadius(plotRect, const Radius.circular(6)),
      bgPaint,
    );

    // 2. Therapeutic Trough Band (targetBandMinMgL – targetBandMaxMgL)
    final yTopBand = yForConc(targetBandMaxMgL);
    final yBotBand = yForConc(targetBandMinMgL);
    final bandRect = Rect.fromLTRB(
      leftPad,
      yTopBand,
      leftPad + plotWidth,
      yBotBand,
    );
    final bandPaint = Paint()
      ..color = const Color(0xFF22C55E).withValues(alpha: 0.14);
    canvas.drawRect(bandRect, bandPaint);

    // Threshold lines
    if (targetBandMinMgL > 0) {
      final targetLinePaint = Paint()
        ..color = const Color(0xFF16A34A).withValues(alpha: 0.5)
        ..strokeWidth = 1.0;
      canvas.drawLine(
        Offset(leftPad, yBotBand),
        Offset(leftPad + plotWidth, yBotBand),
        targetLinePaint,
      );
    }

    final toxLinePaint = Paint()
      ..color = const Color(0xFFDC2626).withValues(alpha: 0.65)
      ..strokeWidth = 1.2;
    canvas.drawLine(
      Offset(leftPad, yTopBand),
      Offset(leftPad + plotWidth, yTopBand),
      toxLinePaint,
    );

    // 3. Horizontal & Vertical Grid Lines + Axis Labels
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0;

    const yTicks = 5;
    for (var i = 0; i <= yTicks; i++) {
      final concVal = (yMax / yTicks) * i;
      final y = yForConc(concVal);
      canvas.drawLine(Offset(leftPad, y), Offset(leftPad + plotWidth, y), gridPaint);
      _drawText(
        canvas,
        concVal.toStringAsFixed(0),
        Offset(leftPad - 6, y - 6),
        alignRight: true,
        color: const Color(0xFF64748B),
        fontSize: 10,
      );
    }

    // X-axis ticks
    final xStep = maxTime <= 12
        ? 2.0
        : (maxTime <= 24 ? 4.0 : 8.0);
    for (double t = 0; t <= maxTime + 1e-6; t += xStep) {
      final x = xForTime(t);
      canvas.drawLine(Offset(x, topPad), Offset(x, topPad + plotHeight), gridPaint);
      _drawText(
        canvas,
        '${t.toInt()}h',
        Offset(x - 10, topPad + plotHeight + 6),
        color: const Color(0xFF64748B),
        fontSize: 10,
      );
    }

    // 4. Shaded Area Under the Curve (AUC) and PK Concentration Curve
    final curvePath = Path();
    final areaPath = Path();

    for (var i = 0; i < points.length; i++) {
      final px = xForTime(points[i].timeHours);
      final py = yForConc(points[i].concentrationMgL);
      if (i == 0) {
        curvePath.moveTo(px, py);
        areaPath.moveTo(px, topPad + plotHeight);
        areaPath.lineTo(px, py);
      } else {
        curvePath.lineTo(px, py);
        areaPath.lineTo(px, py);
      }
    }
    areaPath.lineTo(xForTime(points.last.timeHours), topPad + plotHeight);
    areaPath.close();

    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF7C3AED).withValues(alpha: 0.30),
          const Color(0xFF7C3AED).withValues(alpha: 0.04),
        ],
      ).createShader(plotRect);
    canvas.drawPath(areaPath, areaPaint);

    final curvePaint = Paint()
      ..color = const Color(0xFF6D28D9)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(curvePath, curvePaint);

    // 5. Highlight Cmax,ss (at t = tInf) and Cmin,ss (at t = tau)
    final peakX = xForTime(profile.tInfHours);
    final peakY = yForConc(profile.peakMgL);
    final troughX = xForTime(profile.tauHours);
    final troughY = yForConc(profile.troughMgL);

    final markerFill = Paint()..color = Colors.white;
    final peakStroke = Paint()
      ..color = const Color(0xFF312E81)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final troughStroke = Paint()
      ..color = const Color(0xFF15803D)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Peak point
    canvas.drawCircle(Offset(peakX, peakY), 4.5, markerFill);
    canvas.drawCircle(Offset(peakX, peakY), 4.5, peakStroke);
    _drawCalloutBadge(
      canvas,
      text: 'Cmax ${profile.peakMgL.toStringAsFixed(1)} mg/L',
      anchor: Offset(peakX, peakY),
      plotRect: plotRect,
      bgColor: const Color(0xFF312E81),
      above: true,
    );

    // Trough point
    canvas.drawCircle(Offset(troughX, troughY), 4.5, markerFill);
    canvas.drawCircle(Offset(troughX, troughY), 4.5, troughStroke);
    _drawCalloutBadge(
      canvas,
      text: 'Cmin ${profile.troughMgL.toStringAsFixed(1)} mg/L',
      anchor: Offset(troughX, troughY),
      plotRect: plotRect,
      bgColor: const Color(0xFF15803D),
      above: false,
    );

    // Axis border
    final borderPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawRect(plotRect, borderPaint);

    // Y-axis unit label
    _drawText(
      canvas,
      'mg/L',
      const Offset(6, 4),
      color: const Color(0xFF475569),
      fontSize: 10,
      bold: true,
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    bool alignRight = false,
    Color color = Colors.black87,
    double fontSize = 10,
    bool bold = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final drawOffset =
        alignRight ? Offset(offset.dx - tp.width, offset.dy) : offset;
    tp.paint(canvas, drawOffset);
  }

  void _drawCalloutBadge(
    Canvas canvas, {
    required String text,
    required Offset anchor,
    required Rect plotRect,
    required Color bgColor,
    required bool above,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    const padH = 6.0;
    const padV = 3.0;
    final boxW = tp.width + padH * 2;
    final boxH = tp.height + padV * 2;

    double left = (anchor.dx - boxW / 2).clamp(
      plotRect.left + 2,
      plotRect.right - boxW - 2,
    );
    double top = above ? (anchor.dy - boxH - 7) : (anchor.dy + 7);
    top = top.clamp(2.0, plotRect.bottom - boxH - 2);

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, boxW, boxH),
      const Radius.circular(4),
    );
    canvas.drawRRect(rrect, Paint()..color = bgColor);
    tp.paint(canvas, Offset(left + padH, top + padV));
  }

  @override
  bool shouldRepaint(covariant _SteadyStatePkChartPainter oldDelegate) {
    return oldDelegate.profile.peakMgL != profile.peakMgL ||
        oldDelegate.profile.troughMgL != profile.troughMgL ||
        oldDelegate.profile.tauHours != profile.tauHours ||
        oldDelegate.profile.tInfHours != profile.tInfHours ||
        oldDelegate.show24HourWindow != show24HourWindow ||
        oldDelegate.targetBandMinMgL != targetBandMinMgL ||
        oldDelegate.targetBandMaxMgL != targetBandMaxMgL ||
        oldDelegate.isThai != isThai;
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.purple,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _SpinnerNumberField extends StatelessWidget {
  final String label;
  final double value;
  final double step;
  final double? minValue;
  final ValueChanged<double> onChanged;

  const _SpinnerNumberField({
    super.key,
    required this.label,
    required this.value,
    required this.step,
    this.minValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMin = minValue ?? step;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed:
                  value > effectiveMin ? () => onChanged(value - step) : null,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            Expanded(
              child: Text(
                value.toStringAsFixed(0),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => onChanged(value + step),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ],
    );
  }
}
