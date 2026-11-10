import 'package:flutter/material.dart';
import '../core/models/drug.dart';
import '../core/models/unit.dart';
import '../data/patient_session.dart';

class IVTitrationScreen extends StatefulWidget {
  final Drug drug;
  final DosingRegimen regimen;
  final bool isThai;

  const IVTitrationScreen({
    super.key,
    required this.drug,
    required this.regimen,
    required this.isThai,
  });

  @override
  State<IVTitrationScreen> createState() => _IVTitrationScreenState();
}

class _IVTitrationScreenState extends State<IVTitrationScreen> {
  IvDiluent? _selectedDiluent;
  double? _selectedDilutionMgPerMl;
  final TextEditingController _reverseRateController = TextEditingController();
  double? _reversePumpRate;

  IvDiluentCompatibility? get _compatibility =>
      widget.regimen.effectiveIvDiluentCompatibility(widget.drug);

  @override
  void initState() {
    super.initState();
    _initSelectedDiluent();
    _selectedDilutionMgPerMl =
        widget.regimen.effectiveStandardDilutionMgPerMl;
  }

  @override
  void dispose() {
    _reverseRateController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant IVTitrationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.drug.id != widget.drug.id ||
        oldWidget.regimen != widget.regimen) {
      _initSelectedDiluent();
      _selectedDilutionMgPerMl =
          widget.regimen.effectiveStandardDilutionMgPerMl;
    }
  }

  void _initSelectedDiluent() {
    final compat = _compatibility;
    if (compat != null) {
      _selectedDiluent = compat.preferredDiluent ??
          (compat.compatibleDiluents.isNotEmpty
              ? compat.compatibleDiluents.first
              : IvDiluent.nss);
    } else {
      _selectedDiluent = null;
    }
  }

  Widget _buildDiluentCompatibilitySection(IvDiluentCompatibility compat) {
    final t = widget.isThai;
    final selected = _selectedDiluent;
    final isIncompat = selected != null && compat.isIncompatible(selected);
    final isCompat = selected != null && compat.isCompatible(selected);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t
                ? 'ตรวจสอบความเข้ากันได้ของสารน้ำผสมยา (IV Diluent Check):'
                : 'Bedside IV Diluent Compatibility Check:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey.shade900,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            key: const Key('iv_titration_diluent_selector'),
            spacing: 8,
            runSpacing: 8,
            children: compat.bedsideCheckDiluents.map((diluent) {
              final isSelected = selected == diluent;
              final bad = compat.isIncompatible(diluent);
              final pref = compat.isPreferred(diluent);

              final Color borderColor = bad
                  ? (isSelected ? Colors.red.shade800 : Colors.red.shade300)
                  : (isSelected ? Colors.teal.shade800 : Colors.grey.shade400);
              final Color bgColor = bad
                  ? (isSelected ? Colors.red.shade100 : Colors.red.shade50)
                  : (isSelected ? Colors.teal.shade100 : Colors.white);
              final Color fgColor = bad
                  ? Colors.red.shade900
                  : (isSelected ? Colors.teal.shade900 : Colors.grey.shade900);

              return Semantics(
                button: true,
                selected: isSelected,
                label: '${diluent.code} ${bad ? "Incompatible" : "Compatible"}',
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: 48,
                    minWidth: 64,
                  ),
                  child: Material(
                    color: bgColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: borderColor,
                        width: isSelected ? 2.0 : 1.0,
                      ),
                    ),
                    child: InkWell(
                      key: Key('iv_titration_diluent_${diluent.name}'),
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() => _selectedDiluent = diluent),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              bad
                                  ? Icons.block_rounded
                                  : (pref
                                      ? Icons.star_rounded
                                      : Icons.check_circle_outline),
                              size: 16,
                              color: fgColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              diluent.code,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: fgColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (isIncompat) ...[
            const SizedBox(height: 12),
            Container(
              key: const Key('iv_titration_incompatibility_banner'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade800, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.dangerous_rounded,
                        color: Colors.red.shade900,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t
                              ? '⚠️ ห้ามผสมใน ${selected.code} (เสี่ยงตกตะกอน / ยาเสื่อมฤทธิ์)'
                              : '⚠️ INCOMPATIBLE DILUENT (${selected.code}) — PRECIPITATION / POTENCY HAZARD',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t
                        ? (compat.incompatibilityReasonTh ??
                            compat.incompatibilityReasonEn ??
                            'ห้ามผสมยานี้ใน ${selected.code}')
                        : (compat.incompatibilityReasonEn ??
                            compat.incompatibilityReasonTh ??
                            'Do NOT dilute ${widget.drug.genericName} in ${selected.code}.'),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.red.shade900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (compat.compatibleDiluents.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      t
                          ? 'สารน้ำที่เข้ากันได้: ${compat.compatibleDiluents.map((d) => d.code).join(", ")}'
                          : 'Use compatible diluent: ${compat.compatibleDiluents.map((d) => d.code).join(", ")}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade900,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else if (isCompat) ...[
            const SizedBox(height: 8),
            Container(
              key: const Key('iv_titration_compatible_badge'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.teal.shade300),
              ),
              child: Text(
                t
                    ? '✓ ${selected.nameTh}: เข้ากันได้${compat.isPreferred(selected) ? " (สารน้ำหลักที่แนะนำ)" : ""}'
                    : '✓ ${selected.nameEn}: Compatible${compat.isPreferred(selected) ? " (Preferred primary diluent)" : ""}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.teal.shade900,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final drug = widget.drug;
    final regimen = widget.regimen;
    final isThai = widget.isThai;
    final compat = _compatibility;
    final patient = PatientSession.instance.currentPatient.value;

    if (patient == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isThai ? 'ตารางดริปยา' : 'IV Titration Table'),
          backgroundColor: Colors.red.shade800,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              if (compat != null) _buildDiluentCompatibilitySection(compat),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Text(
                    isThai
                        ? 'กรุณาตั้งค่าข้อมูลผู้ป่วยก่อน (ต้องใช้น้ำหนัก)'
                        : 'Please set patient profile first (Weight is required)',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (regimen.dosingType != DosingType.titrated) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isThai ? 'ตารางดริปยา' : 'IV Titration Table'),
          backgroundColor: Colors.red.shade800,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              if (compat != null) _buildDiluentCompatibilitySection(compat),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  key: const Key('iv_titration_non_titrated_guard'),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade700, width: 2),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.dangerous_rounded,
                        size: 56,
                        color: Colors.red.shade800,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isThai
                            ? 'ข้อบ่งใช้นี้ไม่ใช่การหยดยาต่อเนื่อง (Non-Titrated Regimen)'
                            : 'Not a Continuous Titrated IV Infusion',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isThai
                            ? 'สูตร "${regimen.indication ?? drug.genericName}" (${regimen.route.abbreviation}) ไม่ใช่สูตรดริปต่อเนื่อง กรุณาเลือกข้อบ่งใช้ชนิด IV Infusion (mcg/kg/min) หากต้องการตารางปรับอัตราหยดยา'
                            : 'Regimen "${regimen.indication ?? drug.genericName}" (${regimen.route.abbreviation}) is not a continuous titrated infusion. Select the continuous IV Infusion regimen for titration pump rates.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red.shade900,
                        ),
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

    if (regimen.effectiveStandardDilutionMgPerMl == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isThai ? 'ตารางดริปยา' : 'IV Titration Table'),
          backgroundColor: Colors.red.shade800,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              if (compat != null) _buildDiluentCompatibilitySection(compat),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isThai
                          ? 'ไม่พบข้อมูลความเข้มข้นสารน้ำมาตรฐาน'
                          : 'No Standard Dilution Specified',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isThai
                          ? 'เพื่อความปลอดภัยของผู้ป่วย ระบบไม่อนุญาตให้สมมติปริมาตรสารน้ำเอง กรุณาปรึกษาเภสัชกรหรือตรวจสอบคู่มือการผสมยาก่อนบริหารยา'
                          : 'To ensure patient safety, arbitrary IV fluid dilution cannot be assumed. Please consult a pharmacist or clinical IV monograph.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final wt = patient.weightKg;
    final dilutionMgPerMl =
        _selectedDilutionMgPerMl ?? regimen.effectiveStandardDilutionMgPerMl!;
    final rateUnit = regimen.rateUnit ??
        (regimen.continuousRateUnit != null
            ? RateUnit.tryFromSymbol(regimen.continuousRateUnit!)
            : null) ??
        RateUnit.mcgKgMin;

    final isBioUnit = rateUnit == RateUnit.uHr ||
        rateUnit == RateUnit.uKgHr ||
        rateUnit == RateUnit.mUMin ||
        rateUnit == RateUnit.uMin;
    final isVasoactive = !isBioUnit &&
        (rateUnit == RateUnit.mcgKgMin ||
            rateUnit == RateUnit.mcgKgHr ||
            rateUnit == RateUnit.mcgMin ||
            drug.category == DrugCategory.vasopressor);

    String concentrationDisplay;
    if (isBioUnit) {
      concentrationDisplay = '$dilutionMgPerMl Units/mL';
    } else if (isVasoactive) {
      final mcgPerMl = dilutionMgPerMl * 1000.0;
      final mcgStr = mcgPerMl == mcgPerMl.roundToDouble()
          ? mcgPerMl.toStringAsFixed(0)
          : mcgPerMl.toStringAsFixed(1);

      String bagNote = '';
      if ((dilutionMgPerMl - 0.016).abs() < 0.001) {
        bagNote = ' [4 mg in 250 mL]';
      } else if ((dilutionMgPerMl - 0.032).abs() < 0.001) {
        bagNote = ' [8 mg in 250 mL]';
      } else if ((dilutionMgPerMl - 0.064).abs() < 0.001) {
        bagNote = ' [16 mg in 250 mL]';
      } else if ((dilutionMgPerMl - 0.080).abs() < 0.001) {
        bagNote = ' [4 mg in 50 mL]';
      } else if ((dilutionMgPerMl - 0.160).abs() < 0.001) {
        bagNote = ' [8 mg in 50 mL]';
      } else if ((dilutionMgPerMl - 1.6).abs() < 0.01) {
        bagNote = ' [400 mg in 250 mL]';
      } else if ((dilutionMgPerMl - 3.2).abs() < 0.01) {
        bagNote = ' [800 mg in 250 mL]';
      } else if ((dilutionMgPerMl - 1.0).abs() < 0.01) {
        bagNote = ' [250 mg in 250 mL]';
      } else if ((dilutionMgPerMl - 2.0).abs() < 0.01) {
        bagNote = ' [500 mg in 250 mL]';
      }
      concentrationDisplay = '$mcgStr mcg/mL ($dilutionMgPerMl mg/mL)$bagNote';
    } else {
      concentrationDisplay = '$dilutionMgPerMl mg/mL';
    }

    final double minRate = regimen.continuousRateMin ?? 0.05;
    final double maxRate =
        regimen.continuousRateMax ?? (minRate > 0 ? minRate * 4 : 1.0);

    List<double> doseSteps;
    if (rateUnit == RateUnit.mcgKgMin &&
        (minRate - 0.05).abs() < 1e-6 &&
        (maxRate - 1.0).abs() < 1e-6) {
      // Standard clinical bedside steps for Adrenaline (Epinephrine) 0.05–1.0 mcg/kg/min
      doseSteps = const [
        0.05,
        0.10,
        0.15,
        0.20,
        0.25,
        0.30,
        0.40,
        0.50,
        0.75,
        1.00,
      ];
    } else if (rateUnit == RateUnit.mcgKgMin &&
        (minRate - 0.01).abs() < 1e-6 &&
        (maxRate - 3.0).abs() < 1e-6) {
      // Standard clinical bedside steps for Norepinephrine 0.01–3.0 mcg/kg/min
      doseSteps = const [
        0.01,
        0.02,
        0.05,
        0.10,
        0.15,
        0.20,
        0.25,
        0.50,
        1.00,
        2.00,
        3.00,
      ];
    } else if (rateUnit == RateUnit.mcgKgMin &&
        (minRate - 2.0).abs() < 1e-6 &&
        (maxRate - 20.0).abs() < 1e-6) {
      // Standard clinical bedside steps for Dopamine / Dobutamine 2.0–20.0 mcg/kg/min
      doseSteps = const [
        2.0,
        2.5,
        5.0,
        7.5,
        10.0,
        12.5,
        15.0,
        17.5,
        20.0,
      ];
    } else {
      final double step = (maxRate > minRate)
          ? (maxRate - minRate) / 10
          : (minRate > 0 ? minRate / 10 : 0.1);
      doseSteps = [];
      for (double r = minRate; r <= maxRate + 0.0001; r += step) {
        doseSteps.add(r);
      }
    }

    final List<Map<String, double>> tableData = [];
    for (final r in doseSteps) {
      double mlPerHr = 0.0;
      if (rateUnit == RateUnit.mlHr) {
        mlPerHr = r;
      } else {
        final amountPerHr = rateUnit.toAmountPerHour(r, wt);
        if (amountPerHr != null && dilutionMgPerMl > 0) {
          mlPerHr = amountPerHr / dilutionMgPerMl;
        }
      }

      tableData.add({
        'dose': r,
        'rate': mlPerHr,
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${drug.genericName} - ${isThai ? 'ตารางดริปยา' : 'Titration'}',
        ),
        backgroundColor: Colors.red.shade800,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.red.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Patient Weight: $wt kg',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Concentration: $concentrationDisplay'),
                    ],
                  ),
                ),
                Icon(Icons.monitor_heart, color: Colors.red.shade300, size: 40),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (compat != null) _buildDiluentCompatibilitySection(compat),
                  _buildConcentrationPresetsSection(isThai, dilutionMgPerMl),
                  _buildReverseTitrationCard(
                    isThai,
                    wt,
                    dilutionMgPerMl,
                    rateUnit,
                    maxRate,
                    isVasoactive,
                  ),
                  Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor:
                            WidgetStateProperty.all(Colors.red.shade100),
                      columns: [
                        DataColumn(
                          label: Text(
                            '${isThai ? "ขนาดยา" : "Dose"}\n(${rateUnit.symbol})',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            '${isThai ? "อัตราหยด" : "Pump Rate"}\n(mL/hr)',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                      rows: tableData.map((row) {
                        final doseVal = row['dose']!;
                        final doseText = doseVal < 1.0
                            ? doseVal.toStringAsFixed(2)
                            : (doseVal == doseVal.roundToDouble()
                                ? doseVal.toStringAsFixed(0)
                                : doseVal.toStringAsFixed(1));
                        return DataRow(
                          cells: [
                            DataCell(Text(doseText)),
                            DataCell(
                              Text(
                                row['rate']!.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                            ),
                          ],
                        );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<ConcentrationPreset> _getConcentrationPresets() {
    final drugId = widget.drug.id.toLowerCase();
    final base = widget.regimen.effectiveStandardDilutionMgPerMl ?? 0.016;

    if (drugId.contains('norepinephrine') ||
        drugId.contains('noradrenaline')) {
      return const [
        ConcentrationPreset(
          key: 'iv_titration_preset_1x',
          labelEn: 'Single (1x)',
          labelTh: 'ปกติ 1x',
          dilutionMgPerMl: 0.016, // 4 mg in 250 mL
          descriptionEn: '4 mg in 250 mL (16 mcg/mL)',
          descriptionTh: '4 มก. ใน 250 มล. (16 มคก./มล.)',
        ),
        ConcentrationPreset(
          key: 'iv_titration_preset_2x',
          labelEn: 'Double (2x)',
          labelTh: 'Double 2x',
          dilutionMgPerMl: 0.032, // 8 mg in 250 mL
          descriptionEn: '8 mg in 250 mL (32 mcg/mL)',
          descriptionTh: '8 มก. ใน 250 มล. (32 มคก./มล.)',
        ),
        ConcentrationPreset(
          key: 'iv_titration_preset_4x',
          labelEn: 'Quad (4x)',
          labelTh: 'Quad 4x',
          dilutionMgPerMl: 0.064, // 16 mg in 250 mL
          descriptionEn: '16 mg in 250 mL (64 mcg/mL)',
          descriptionTh: '16 มก. ใน 250 มล. (64 มคก./มล.)',
        ),
        ConcentrationPreset(
          key: 'iv_titration_preset_syringe',
          labelEn: 'Syringe Pump',
          labelTh: 'Syringe 50mL',
          dilutionMgPerMl: 0.080, // 4 mg in 50 mL
          descriptionEn: '4 mg in 50 mL (80 mcg/mL)',
          descriptionTh: '4 มก. ใน 50 มล. (80 มคก./มล.)',
        ),
        ConcentrationPreset(
          key: 'iv_titration_preset_syringe_double',
          labelEn: 'Syringe 2x',
          labelTh: 'Syringe 2x',
          dilutionMgPerMl: 0.160, // 8 mg in 50 mL
          descriptionEn: '8 mg in 50 mL (160 mcg/mL)',
          descriptionTh: '8 มก. ใน 50 มล. (160 มคก./มล.)',
        ),
      ];
    } else if (drugId.contains('epinephrine') ||
        drugId.contains('adrenaline')) {
      return const [
        ConcentrationPreset(
          key: 'iv_titration_preset_1x',
          labelEn: 'Single (1x)',
          labelTh: 'ปกติ 1x',
          dilutionMgPerMl: 0.016,
          descriptionEn: '4 mg in 250 mL (16 mcg/mL)',
          descriptionTh: '4 มก. ใน 250 มล. (16 มคก./มล.)',
        ),
        ConcentrationPreset(
          key: 'iv_titration_preset_2x',
          labelEn: 'Double (2x)',
          labelTh: 'Double 2x',
          dilutionMgPerMl: 0.032,
          descriptionEn: '8 mg in 250 mL (32 mcg/mL)',
          descriptionTh: '8 มก. ใน 250 มล. (32 มคก./มล.)',
        ),
        ConcentrationPreset(
          key: 'iv_titration_preset_syringe',
          labelEn: 'Syringe Pump',
          labelTh: 'Syringe 50mL',
          dilutionMgPerMl: 0.080,
          descriptionEn: '4 mg in 50 mL (80 mcg/mL)',
          descriptionTh: '4 มก. ใน 50 มล. (80 มคก./มล.)',
        ),
      ];
    } else if (drugId.contains('dopamine')) {
      return const [
        ConcentrationPreset(
          key: 'iv_titration_preset_1x',
          labelEn: 'Single (1x)',
          labelTh: 'ปกติ 1x',
          dilutionMgPerMl: 1.6,
          descriptionEn: '400 mg in 250 mL (1,600 mcg/mL)',
          descriptionTh: '400 มก. ใน 250 มล. (1,600 มคก./มล.)',
        ),
        ConcentrationPreset(
          key: 'iv_titration_preset_2x',
          labelEn: 'Double (2x)',
          labelTh: 'Double 2x',
          dilutionMgPerMl: 3.2,
          descriptionEn: '800 mg in 250 mL (3,200 mcg/mL)',
          descriptionTh: '800 มก. ใน 250 มล. (3,200 มคก./มล.)',
        ),
        ConcentrationPreset(
          key: 'iv_titration_preset_syringe',
          labelEn: 'Syringe Pump',
          labelTh: 'Syringe 50mL',
          dilutionMgPerMl: 4.0,
          descriptionEn: '200 mg in 50 mL (4,000 mcg/mL)',
          descriptionTh: '200 มก. ใน 50 มล. (4,000 มคก./มล.)',
        ),
      ];
    } else if (drugId.contains('dobutamine')) {
      return const [
        ConcentrationPreset(
          key: 'iv_titration_preset_1x',
          labelEn: 'Single (1x)',
          labelTh: 'ปกติ 1x',
          dilutionMgPerMl: 1.0,
          descriptionEn: '250 mg in 250 mL (1,000 mcg/mL)',
          descriptionTh: '250 มก. ใน 250 มล. (1,000 มคก./มล.)',
        ),
        ConcentrationPreset(
          key: 'iv_titration_preset_2x',
          labelEn: 'Double (2x)',
          labelTh: 'Double 2x',
          dilutionMgPerMl: 2.0,
          descriptionEn: '500 mg in 250 mL (2,000 mcg/mL)',
          descriptionTh: '500 มก. ใน 250 มล. (2,000 มคก./มล.)',
        ),
        ConcentrationPreset(
          key: 'iv_titration_preset_syringe',
          labelEn: 'Syringe Pump',
          labelTh: 'Syringe 50mL',
          dilutionMgPerMl: 5.0,
          descriptionEn: '250 mg in 50 mL (5,000 mcg/mL)',
          descriptionTh: '250 มก. ใน 50 มล. (5,000 มคก./มล.)',
        ),
      ];
    } else if (drugId.contains('vasopressin')) {
      return const [
        ConcentrationPreset(
          key: 'iv_titration_preset_1x',
          labelEn: 'Standard (1x)',
          labelTh: 'มาตรฐาน (1x)',
          dilutionMgPerMl: 0.2,
          descriptionEn: '20 units in 100 mL (0.2 U/mL)',
          descriptionTh: '20 ยูนิต ใน 100 มล. (0.2 U/มล.)',
        ),
        ConcentrationPreset(
          key: 'iv_titration_preset_2x',
          labelEn: 'Double (2x)',
          labelTh: 'Double (2x)',
          dilutionMgPerMl: 0.4,
          descriptionEn: '40 units in 100 mL (0.4 U/mL)',
          descriptionTh: '40 ยูนิต ใน 100 มล. (0.4 U/มล.)',
        ),
        ConcentrationPreset(
          key: 'iv_titration_preset_syringe',
          labelEn: 'Syringe Pump',
          labelTh: 'Syringe 50mL',
          dilutionMgPerMl: 1.0,
          descriptionEn: '50 units in 50 mL (1.0 U/mL)',
          descriptionTh: '50 ยูนิต ใน 50 มล. (1.0 U/มล.)',
        ),
      ];
    } else {
      return [
        ConcentrationPreset(
          key: 'iv_titration_preset_1x',
          labelEn: 'Standard (1x)',
          labelTh: 'มาตรฐาน (1x)',
          dilutionMgPerMl: base,
          descriptionEn: '$base mg/mL',
          descriptionTh: '$base มก./มล.',
        ),
        ConcentrationPreset(
          key: 'iv_titration_preset_2x',
          labelEn: 'Double (2x)',
          labelTh: 'Double (2x)',
          dilutionMgPerMl: base * 2.0,
          descriptionEn: '${base * 2.0} mg/mL',
          descriptionTh: '${base * 2.0} มก./มล.',
        ),
        ConcentrationPreset(
          key: 'iv_titration_preset_4x',
          labelEn: 'Quad (4x)',
          labelTh: 'Quad (4x)',
          dilutionMgPerMl: base * 4.0,
          descriptionEn: '${base * 4.0} mg/mL',
          descriptionTh: '${base * 4.0} มก./มล.',
        ),
      ];
    }
  }

  Widget _buildConcentrationPresetsSection(
    bool isThai,
    double currentDilution,
  ) {
    final presets = _getConcentrationPresets();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isThai
                ? 'เลือกความเข้มข้นสารน้ำ (Concentration Presets):'
                : 'Select Concentration Preset:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey.shade900,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            key: const Key('iv_titration_preset_selector'),
            spacing: 8,
            runSpacing: 8,
            children: presets.map((preset) {
              final isSelected =
                  (currentDilution - preset.dilutionMgPerMl).abs() < 1e-4;
              final Color borderColor = isSelected
                  ? Colors.red.shade800
                  : Colors.grey.shade400;
              final Color bgColor = isSelected
                  ? Colors.red.shade100
                  : Colors.white;
              final Color fgColor = isSelected
                  ? Colors.red.shade900
                  : Colors.grey.shade900;

              return ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48, minWidth: 64),
                child: Material(
                  color: bgColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: borderColor,
                      width: isSelected ? 2.0 : 1.0,
                    ),
                  ),
                  child: InkWell(
                    key: Key(preset.key),
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      setState(() {
                        _selectedDilutionMgPerMl = preset.dilutionMgPerMl;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                size: 16,
                                color: fgColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isThai ? preset.labelTh : preset.labelEn,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: fgColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isThai ? preset.descriptionTh : preset.descriptionEn,
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected
                                  ? Colors.red.shade800
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildReverseTitrationCard(
    bool isThai,
    double wt,
    double dilutionMgPerMl,
    RateUnit rateUnit,
    double maxRate,
    bool isVasoactive,
  ) {
    double? deliveredRate;
    double? deliveredMcgKgMin;
    double? deliveredMcgMin;

    if (_reversePumpRate != null &&
        _reversePumpRate! > 0 &&
        _reversePumpRate!.isFinite &&
        dilutionMgPerMl.isFinite) {
      final pRate = _reversePumpRate!;
      final mcgPerMl = dilutionMgPerMl * 1000.0;
      final hasValidWt = wt > 0 && wt.isFinite;

      if (rateUnit == RateUnit.mcgMin) {
        deliveredMcgMin = (pRate * mcgPerMl) / 60.0;
        deliveredMcgKgMin = hasValidWt ? deliveredMcgMin / wt : null;
        deliveredRate = deliveredMcgMin;
      } else if (rateUnit == RateUnit.mcgKgMin ||
          (isVasoactive && rateUnit != RateUnit.mcgKgHr)) {
        deliveredMcgKgMin =
            hasValidWt ? (pRate * mcgPerMl) / (wt * 60.0) : null;
        deliveredMcgMin = (pRate * mcgPerMl) / 60.0;
        deliveredRate = deliveredMcgKgMin;
      } else if (rateUnit == RateUnit.mcgKgHr) {
        deliveredRate = hasValidWt ? (pRate * mcgPerMl) / wt : null;
        deliveredMcgKgMin =
            (deliveredRate != null) ? deliveredRate / 60.0 : null;
        deliveredMcgMin =
            (deliveredMcgKgMin != null && hasValidWt) ? deliveredMcgKgMin * wt : null;
      } else if (rateUnit == RateUnit.mgKgHr) {
        deliveredRate = hasValidWt ? (pRate * dilutionMgPerMl) / wt : null;
      } else if (rateUnit == RateUnit.mgKgMin) {
        deliveredRate =
            hasValidWt ? (pRate * dilutionMgPerMl) / (wt * 60.0) : null;
      } else if (rateUnit == RateUnit.mgHr) {
        deliveredRate = pRate * dilutionMgPerMl;
      } else if (rateUnit == RateUnit.uHr) {
        deliveredRate = pRate * dilutionMgPerMl;
      } else if (rateUnit == RateUnit.uMin) {
        deliveredRate = (pRate * dilutionMgPerMl) / 60.0;
      } else if (rateUnit == RateUnit.mUMin) {
        deliveredRate = (pRate * dilutionMgPerMl * 1000.0) / 60.0;
      } else {
        deliveredRate = pRate;
      }
    }

    final isCeilingExceeded =
        deliveredRate != null && deliveredRate > maxRate;

    return Container(
      key: const Key('iv_titration_reverse_result_card'),
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCeilingExceeded
            ? const Color(0xFFFEF2F2)
            : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCeilingExceeded
              ? const Color(0xFFDC2626)
              : const Color(0xFF16A34A),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.swap_horizontal_circle_outlined,
                color: isCeilingExceeded
                    ? const Color(0xFF991B1B)
                    : const Color(0xFF166534),
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isThai
                      ? 'คำนวณย้อนกลับ (Reverse Titration: mL/hr ➔ Dose)'
                      : 'Bedside Reverse Titration (mL/hr ➔ Dose)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isCeilingExceeded
                        ? const Color(0xFF991B1B)
                        : const Color(0xFF166534),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isThai
                ? 'ป้อนอัตราหยดของเครื่อง Infusion Pump (mL/hr) เพื่อคำนวณขนาดยาจริงที่ผู้ป่วยได้รับ'
                : 'Enter current infusion pump rate in mL/hr to calculate delivered clinical dose:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('iv_titration_reverse_rate_input'),
                  controller: _reverseRateController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: isThai
                        ? 'อัตราเครื่องหยดยา (mL/hr)'
                        : 'Pump Rate (mL/hr)',
                    hintText: 'e.g. 15.0',
                    prefixIcon: const Icon(Icons.speed, size: 20),
                    suffixText: 'mL/hr',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      final clean = val.trim().replaceAll(',', '.');
                      _reversePumpRate = double.tryParse(clean);
                    });
                  },
                ),
              ),
              if (_reverseRateController.text.isNotEmpty) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _reverseRateController.clear();
                      _reversePumpRate = null;
                    });
                  },
                ),
              ],
            ],
          ),
          if (deliveredRate != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCeilingExceeded
                      ? Colors.red.shade300
                      : Colors.teal.shade200,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    isThai
                        ? 'ขนาดยาที่ผู้ป่วยกำลังได้รับ:'
                        : 'Delivered Dose to Patient:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (rateUnit == RateUnit.mcgMin && deliveredMcgMin != null) ...[
                    Text(
                      key: const Key('iv_titration_reverse_result_mcg_min'),
                      '${deliveredMcgMin.toStringAsFixed(2)} mcg/min',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isCeilingExceeded
                            ? Colors.red.shade900
                            : Colors.teal.shade900,
                      ),
                    ),
                    if (deliveredMcgKgMin != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        key: const Key('iv_titration_reverse_result_mcg_kg_min'),
                        '(${deliveredMcgKgMin.toStringAsFixed(3)} mcg/kg/min)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.indigo.shade800,
                        ),
                      ),
                    ],
                  ] else if ((rateUnit == RateUnit.mcgKgMin ||
                          (isVasoactive && rateUnit != RateUnit.mcgKgHr)) &&
                      deliveredMcgKgMin != null) ...[
                    Text(
                      key: const Key('iv_titration_reverse_result_mcg_kg_min'),
                      '${deliveredMcgKgMin.toStringAsFixed(3)} mcg/kg/min',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isCeilingExceeded
                            ? Colors.red.shade900
                            : Colors.teal.shade900,
                      ),
                    ),
                    if (deliveredMcgMin != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        key: const Key('iv_titration_reverse_result_mcg_min'),
                        '(${deliveredMcgMin.toStringAsFixed(2)} mcg/min)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.indigo.shade800,
                        ),
                      ),
                    ],
                  ] else ...[
                    Text(
                      '${deliveredRate.toStringAsFixed(3)} ${rateUnit.symbol}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isCeilingExceeded
                            ? Colors.red.shade900
                            : Colors.teal.shade900,
                      ),
                    ),
                    if (rateUnit == RateUnit.mcgKgHr && deliveredMcgKgMin != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '(${deliveredMcgKgMin.toStringAsFixed(3)} mcg/kg/min)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.indigo.shade800,
                        ),
                      ),
                    ],
                  ],
                  if (isCeilingExceeded) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isThai
                            ? '⚠️ คำเตือน: อัตรานี้เกินเกณฑ์สูงสุดที่แนะนำ (${maxRate.toStringAsFixed(2)} ${rateUnit.symbol})'
                            : '⚠️ WARNING: Exceeds maximum titration ceiling (${maxRate.toStringAsFixed(2)} ${rateUnit.symbol})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Structured concentration preset representation.
class ConcentrationPreset {
  final String key;
  final String labelEn;
  final String labelTh;
  final double dilutionMgPerMl;
  final String descriptionEn;
  final String descriptionTh;

  const ConcentrationPreset({
    required this.key,
    required this.labelEn,
    required this.labelTh,
    required this.dilutionMgPerMl,
    required this.descriptionEn,
    required this.descriptionTh,
  });
}
