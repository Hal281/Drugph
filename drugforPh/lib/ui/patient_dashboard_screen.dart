import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/patient_session.dart';
import '../core/models/patient.dart';
import '../core/models/drug.dart';
import '../core/models/dosage_result.dart';
import '../data/drug_database.dart';
import '../core/calculators/pharmacist_calculator.dart';
import 'widgets/patient_edit_dialog.dart';
import 'tdm_screen.dart';

class PatientDashboardScreen extends StatelessWidget {
  final bool isThai;

  const PatientDashboardScreen({super.key, required this.isThai});

  void _addDrug(BuildContext context, Patient patient) {
    showSearch(
      context: context,
      delegate: _DrugSearchDelegate(isThai: isThai, patient: patient),
    );
  }

  void _copySoapNote(
    BuildContext context,
    Patient patient,
    Map<String, DosageResult> results,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('📌 [Pharmacist Note: Ward Patient Dashboard]');

    final sexStr = patient.sex.nameEn;
    buffer.writeln(
      '- Pt Info: ${patient.ageYears}Y $sexStr | Wt ${patient.weightKg} kg, Ht ${patient.heightCm} cm',
    );

    if (patient.serumCreatinineMgDl != null) {
      final crclStr =
          patient.creatinineClearanceMlMin?.toStringAsFixed(1) ?? 'Unknown';
      final stable = patient.isScrStable ? 'Stable' : 'AKI/Unstable';
      buffer.writeln(
        '- Renal function: SCr ${patient.serumCreatinineMgDl} ($stable) -> CrCl ~$crclStr mL/min',
      );
    } else {
      buffer.writeln('- Renal function: Unknown');
    }

    buffer.writeln('\n💊 [Medications]');
    if (patient.activeDrugIds.isEmpty) {
      buffer.writeln('No active medications.');
    } else {
      for (final id in patient.activeDrugIds) {
        final drug = DrugDatabase.findById(id);
        if (drug == null) continue;
        final res = results[id];
        if (res == null) continue;

        final doseStr = res.roundedDose != null
            ? '${res.roundedDose?.toStringAsFixed(0)} ${res.doseUnit?.symbol}'
            : '${res.calculatedDose?.toStringAsFixed(2)} ${res.doseUnit?.symbol}';
        final freqStr = res.frequency ?? '';

        buffer.write('- ${drug.genericName}: $doseStr $freqStr');
        if (res.isRenallyAdjusted || res.roundedDose != null) {
          final reasons = <String>[];
          if (res.isRenallyAdjusted) reasons.add('Renal adj.');
          if (res.roundedDose != null) reasons.add('Rounded');
          buffer.write(' (${reasons.join(', ')})');
        }
        buffer.writeln();
      }
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isThai ? 'คัดลอกข้อมูลแล้ว' : 'Copied to clipboard'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isThai ? 'แผงควบคุมผู้ป่วย' : 'Patient Dashboard'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
      ),
      body: ValueListenableBuilder<Patient?>(
        valueListenable: PatientSession.instance.currentPatient,
        builder: (context, patient, child) {
          if (patient == null) {
            return Center(
              child: Text(
                isThai ? 'ไม่พบข้อมูลผู้ป่วย' : 'No patient selected',
              ),
            );
          }

          // Pre-calculate all doses
          final results = <String, DosageResult>{};
          for (final id in patient.activeDrugIds) {
            final drug = DrugDatabase.findById(id);
            if (drug != null && drug.regimens.isNotEmpty) {
              results[id] = PharmacistCalculator.calculateDose(
                patient: patient,
                drug: drug,
                regimen: drug.regimens.first,
              );
            }
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // 1. Patient Vitals Card (Read-only banner for now)
              Card(
                color: Colors.blue.shade50,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.blue.shade200),
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
                          Text(
                            patient.patientName ??
                                (isThai
                                    ? 'ผู้ป่วยไม่ระบุชื่อ'
                                    : 'Unknown Patient'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          Text(
                            'HN: ${patient.hospitalNumber ?? "-"}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Age: ${patient.ageYears} yrs | Wt: ${patient.weightKg} kg | Ht: ${patient.heightCm} cm',
                      ),
                      const Divider(),
                      Row(
                        children: [
                          const Icon(Icons.water_drop, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              patient.serumCreatinineMgDl != null
                                  ? 'SCr: ${patient.serumCreatinineMgDl} mg/dL (${patient.isScrStable ? "Stable" : "AKI"})\nCrCl: ${patient.creatinineClearanceMlMin?.toStringAsFixed(1) ?? "-"} mL/min'
                                  : 'Renal function: Not provided',
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              // Open patient edit dialog
                              showDialog(
                                context: context,
                                builder: (context) => PatientEditDialog(
                                  initialPatient: patient,
                                  isThai: isThai,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Medication List Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isThai ? 'รายการยาปัจจุบัน' : 'Active Medications',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(isThai ? 'เพิ่มยา' : 'Add Drug'),
                    onPressed: () => _addDrug(context, patient),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 3. Medication Cards
              if (patient.activeDrugIds.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      isThai
                          ? 'ยังไม่มียาในรายการ\nกดปุ่ม "เพิ่มยา"'
                          : 'No active medications.\nTap "Add Drug"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...patient.activeDrugIds.map((id) {
                  final drug = DrugDatabase.findById(id);
                  if (drug == null) return const SizedBox();
                  final res = results[id];
                  if (res == null) return const SizedBox();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                drug.genericName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                onPressed: () {
                                  final newIds = List<String>.from(
                                    patient.activeDrugIds,
                                  )..remove(id);
                                  PatientSession.instance.savePatient(
                                    patient.copyWith(activeDrugIds: newIds),
                                    setAsCurrent: true,
                                  );
                                },
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isThai
                                            ? 'ขนาดยาแนะนำ:'
                                            : 'Recommended Dose:',
                                        style: TextStyle(
                                          color: Colors.green.shade900,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        res.roundedDose != null
                                            ? '${res.roundedDose?.toStringAsFixed(0)} ${res.doseUnit?.symbol} ${res.frequency}'
                                            : '${res.calculatedDose?.toStringAsFixed(2)} ${res.doseUnit?.symbol} ${res.frequency}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.green.shade900,
                                        ),
                                      ),
                                      if (res.isRenallyAdjusted ||
                                          res.roundedDose != null)
                                        Text(
                                          isThai
                                              ? '(ปรับตามไต/ปัดเศษแล้ว)'
                                              : '(Renally adjusted / Rounded)',
                                          style: TextStyle(
                                            color: Colors.green.shade700,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                // TDM Button for Vancomycin etc
                                if (drug.genericName.toLowerCase().contains(
                                  'vancomycin',
                                ))
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.bar_chart, size: 16),
                                    label: const Text('TDM'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.purple,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => TdmScreen(
                                            patient: patient,
                                            drug: drug,
                                            isThai: isThai,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                          // Warnings
                          if (res.warnings.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            ...res.warnings.map(
                              (w) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.warning_amber,
                                      size: 16,
                                      color: Colors.orange.shade700,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        isThai ? w.messageTh : w.messageEn,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange.shade900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 16),
              // 4. Copy Note Button
              ElevatedButton.icon(
                icon: const Icon(Icons.copy),
                label: Text(
                  isThai ? 'คัดลอกสรุปยาทั้งหมด (SO-Note)' : 'Copy All Notes',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
                onPressed: () => _copySoapNote(context, patient, results),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

class _DrugSearchDelegate extends SearchDelegate {
  final bool isThai;
  final Patient patient;

  _DrugSearchDelegate({required this.isThai, required this.patient});

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildList();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildList();
  }

  Widget _buildList() {
    final results = DrugDatabase.search(query);
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final drug = results[index];
        return ListTile(
          title: Text(drug.genericName),
          subtitle: Text(drug.brandNames.join(', ')),
          onTap: () {
            if (!patient.activeDrugIds.contains(drug.id)) {
              final newIds = List<String>.from(patient.activeDrugIds)
                ..add(drug.id);
              PatientSession.instance.savePatient(
                patient.copyWith(activeDrugIds: newIds),
                setAsCurrent: true,
              );
            }
            close(context, null);
          },
        );
      },
    );
  }
}
