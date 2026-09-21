import 'package:flutter/material.dart';
import '../core/models/drug.dart';
import '../core/models/patient.dart';
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
        ),
        body: Center(
          child: Text(isThai
              ? 'กรุณาตั้งค่าข้อมูลผู้ป่วยก่อน (ต้องใช้น้ำหนัก)'
              : 'Please set patient profile first (Weight is required)'),
        ),
      );
    }

    final wt = patient.weightKg;
    final dilutionMgPerMl = regimen.standardDilutionMgPerMl ?? 1.0;

    // Convert dilution to mcg/ml for easier math with mcg/kg/min
    final dilutionMcgPerMl = dilutionMgPerMl * 1000;

    // Typical rate range (e.g., 0.05 to 1.0 mcg/kg/min for Norepi, or whatever is passed)
    // If none provided, we just generate a generic table from 0.05 to 1.0
    final double minRate = regimen.continuousRateMin ?? 0.05;
    final double maxRate = regimen.continuousRateMax ?? 1.0;

    // Generate steps (around 10-15 rows)
    final double step = (maxRate - minRate) / 10;

    List<Map<String, double>> tableData = [];
    for (double r = minRate; r <= maxRate + 0.001; r += step) {
      // Formula: Dose (mcg/kg/min) * Weight (kg) * 60 min = mcg / hr
      // (mcg / hr) / Concentration (mcg / ml) = ml / hr
      final mcgPerHr = r * wt * 60;
      final mlPerHr = mcgPerHr / dilutionMcgPerMl;

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
                    Text('Concentration: $dilutionMgPerMl mg/mL'),
                  ],
                ),
                Icon(Icons.monitor_heart, color: Colors.red.shade300, size: 40),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(Colors.red.shade100),
                columns: const [
                  DataColumn(
                      label: Text('Dose\n(mcg/kg/min)',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text('Pump Rate\n(mL/hr)',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: tableData.map((row) {
                  return DataRow(cells: [
                    DataCell(Text(row['dose']!.toStringAsFixed(2))),
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
