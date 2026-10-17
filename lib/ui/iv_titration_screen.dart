import 'package:flutter/material.dart';
import '../core/models/drug.dart';
import '../data/patient_session.dart';

class IVTitrationScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final patient = PatientSession.instance.currentPatient.value;

    if (patient == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isThai ? 'ตารางดริปยา' : 'IV Titration Table'),
          backgroundColor: Colors.red.shade800,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Text(isThai
              ? 'กรุณาตั้งค่าข้อมูลผู้ป่วยก่อน (ต้องใช้น้ำหนัก)'
              : 'Please set patient profile first (Weight is required)'),
        ),
      );
    }

    if (regimen.standardDilutionMgPerMl == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isThai ? 'ตารางดริปยา' : 'IV Titration Table'),
          backgroundColor: Colors.red.shade800,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  isThai ? 'ไม่พบข้อมูลความเข้มข้นสารน้ำมาตรฐาน' : 'No Standard Dilution Specified',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
        ),
      );
    }

    final wt = patient.weightKg;
    final dilutionMgPerMl = regimen.standardDilutionMgPerMl!;
    final rateUnit = regimen.rateUnit ??
        (regimen.continuousRateUnit != null
            ? RateUnit.tryFromSymbol(regimen.continuousRateUnit!)
            : null) ??
        RateUnit.mcgKgMin;

    final isBioUnit = rateUnit == RateUnit.uHr || rateUnit == RateUnit.uKgHr;
    final concUnitStr = isBioUnit ? 'Units/mL' : 'mg/mL';

    // Typical rate range (e.g., 0.05 to 1.0 mcg/kg/min for Norepi, or 5 to 15 mg/hr for Nicardipine)
    final double minRate = regimen.continuousRateMin ?? 0.05;
    final double maxRate = regimen.continuousRateMax ?? (minRate > 0 ? minRate * 4 : 1.0);

    // Generate steps (10 rows)
    final double step = (maxRate > minRate)
        ? (maxRate - minRate) / 10
        : (minRate > 0 ? minRate / 10 : 0.1);

    List<Map<String, double>> tableData = [];
    for (double r = minRate; r <= maxRate + 0.0001; r += step) {
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
            '${drug.genericName} - ${isThai ? 'ตารางดริปยา' : 'Titration'}'),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Patient Weight: $wt kg',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Concentration: $dilutionMgPerMl $concUnitStr'),
                  ],
                ),
                Icon(Icons.monitor_heart, color: Colors.red.shade300, size: 40),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.red.shade100),
                columns: [
                  DataColumn(
                      label: Text(
                          '${isThai ? "ขนาดยา" : "Dose"}\n(${rateUnit.symbol})',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text(
                          '${isThai ? "อัตราหยด" : "Pump Rate"}\n(mL/hr)',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: tableData.map((row) {
                  final doseVal = row['dose']!;
                  final doseText = doseVal < 1.0
                      ? doseVal.toStringAsFixed(2)
                      : (doseVal == doseVal.roundToDouble()
                          ? doseVal.toStringAsFixed(0)
                          : doseVal.toStringAsFixed(1));
                  return DataRow(cells: [
                    DataCell(Text(doseText)),
                    DataCell(Text(row['rate']!.toStringAsFixed(1),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo))),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
