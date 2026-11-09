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

  IvDiluentCompatibility? get _compatibility =>
      widget.regimen.effectiveIvDiluentCompatibility(widget.drug);

  @override
  void initState() {
    super.initState();
    _initSelectedDiluent();
  }

  @override
  void didUpdateWidget(covariant IVTitrationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.drug.id != widget.drug.id ||
        oldWidget.regimen != widget.regimen) {
      _initSelectedDiluent();
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
    final dilutionMgPerMl = regimen.effectiveStandardDilutionMgPerMl!;
    final rateUnit = regimen.rateUnit ??
        (regimen.continuousRateUnit != null
            ? RateUnit.tryFromSymbol(regimen.continuousRateUnit!)
            : null) ??
        RateUnit.mcgKgMin;

    final isBioUnit = rateUnit == RateUnit.uHr ||
        rateUnit == RateUnit.uKgHr ||
        rateUnit == RateUnit.mUMin;
    final isVasoactive = !isBioUnit &&
        (rateUnit == RateUnit.mcgKgMin ||
            rateUnit == RateUnit.mcgKgHr ||
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
      } else if ((dilutionMgPerMl - 1.6).abs() < 0.01) {
        bagNote = ' [400 mg in 250 mL]';
      } else if ((dilutionMgPerMl - 1.0).abs() < 0.01) {
        bagNote = ' [250 mg in 250 mL]';
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
}
