
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/patient_session.dart';
import '../core/models/patient.dart';
import '../core/models/dosage_result.dart';
import '../data/drug_database.dart';
import '../core/calculators/pharmacist_calculator.dart';
import 'widgets/patient_edit_dialog.dart';
import 'tdm_screen.dart';

class PatientDashboardScreen extends StatelessWidget {
  final bool isThai;

  const PatientDashboardScreen({
    super.key,
    required this.isThai,
  });

  static const Color primary = Color(0xFF08A88A);
  static const Color darkTeal = Color(0xFF087F70);
  static const Color mint = Color(0xFFE7F7F2);
  static const Color background = Color(0xFFF5FAF9);
  static const Color textDark = Color(0xFF253C3A);

  void _addDrug(BuildContext context, Patient patient) {
    showSearch(
      context: context,
      delegate: _DrugSearchDelegate(
        isThai: isThai,
        patient: patient,
      ),
    );
  }

  void _copySoapNote(
    BuildContext context,
    Patient patient,
    Map<String, DosageResult> results,
  ) {
    final buffer = StringBuffer();

    buffer.writeln(
      '[Pharmacist Note: Ward Patient Dashboard]',
    );

    buffer.writeln(
      '- Pt Info: ${patient.ageYears}Y '
      '${patient.sex.nameEn} | '
      'Wt ${patient.weightKg} kg, '
      'Ht ${patient.heightCm} cm',
    );

    if (patient.serumCreatinineMgDl != null) {
      final crcl = patient.creatinineClearanceMlMin
              ?.toStringAsFixed(1) ??
          'Unknown';

      final renalStatus =
          patient.isScrStable ? 'Stable' : 'AKI/Unstable';

      buffer.writeln(
        '- Renal function: '
        'SCr ${patient.serumCreatinineMgDl} '
        '($renalStatus) -> CrCl ~$crcl mL/min',
      );
    } else {
      buffer.writeln('- Renal function: Unknown');
    }

    buffer.writeln('\n[Medications]');

    if (patient.activeDrugIds.isEmpty) {
      buffer.writeln('No active medications.');
    } else {
      for (final id in patient.activeDrugIds) {
        final drug = DrugDatabase.findById(id);
        final res = results[id];

        if (drug == null || res == null) continue;

        final dose = res.roundedDose != null
            ? '${res.roundedDose!.toStringAsFixed(0)} '
                '${res.doseUnit?.symbol ?? ''}'
            : '${res.calculatedDose?.toStringAsFixed(2) ?? '-'} '
                '${res.doseUnit?.symbol ?? ''}';

        buffer.write(
          '- ${drug.genericName}: $dose ${res.frequency ?? ''}',
        );

        final reasons = <String>[];

        if (res.isRenallyAdjusted) {
          reasons.add('Renal adjustment');
        }

        if (res.roundedDose != null) {
          reasons.add('Rounded');
        }

        if (reasons.isNotEmpty) {
          buffer.write(' (${reasons.join(', ')})');
        }

        buffer.writeln();
      }
    }

    Clipboard.setData(
      ClipboardData(text: buffer.toString()),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isThai ? 'คัดลอกข้อมูลแล้ว' : 'Copied to clipboard',
        ),
        backgroundColor: darkTeal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: textDark,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: mint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.local_hospital_rounded,
                color: darkTeal,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isThai
                        ? 'ระบบคำนวณขนาดยา'
                        : 'Drug Dose Calculator',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  Text(
                    isThai
                        ? 'แผงควบคุมผู้ป่วย'
                        : 'Patient Dashboard',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blueGrey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: ValueListenableBuilder<Patient?>(
        valueListenable:
            PatientSession.instance.currentPatient,
        builder: (context, patient, child) {
          if (patient == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: mint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_search_rounded,
                        size: 52,
                        color: darkTeal,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isThai
                          ? 'ยังไม่ได้เลือกผู้ป่วย'
                          : 'No patient selected',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isThai
                          ? 'กรุณาเลือกหรือเพิ่มข้อมูลผู้ป่วยก่อนเริ่มคำนวณยา'
                          : 'Select or add a patient before calculating doses.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.blueGrey,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Keep the existing dose calculation logic.
          final results = <String, DosageResult>{};

          for (final id in patient.activeDrugIds) {
            final drug = DrugDatabase.findById(id);

            if (drug != null && drug.regimens.isNotEmpty) {
              results[id] =
                  PharmacistCalculator.calculateDose(
                patient: patient,
                drug: drug,
                regimen: drug.regimens.first,
              );
            }
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Patient information
              _sectionTitle(
                isThai ? 'ข้อมูลผู้ป่วย' : 'Patient Information',
                Icons.person_outline_rounded,
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: const Color(0xFFDCEFE9),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: darkTeal.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: mint,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 30,
                            color: darkTeal,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                patient.patientName ??
                                    (isThai
                                        ? 'ผู้ป่วยไม่ระบุชื่อ'
                                        : 'Unknown Patient'),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'HN: ${patient.hospitalNumber ?? '-'}',
                                style: const TextStyle(
                                  color: darkTeal,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: isThai
                              ? 'แก้ไขข้อมูลผู้ป่วย'
                              : 'Edit patient',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => PatientEditDialog(
                                initialPatient: patient,
                                isThai: isThai,
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: darkTeal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _infoChip(
                          Icons.cake_outlined,
                          isThai
                              ? '${patient.ageYears} ปี'
                              : '${patient.ageYears} years',
                        ),
                        _infoChip(
                          Icons.monitor_weight_outlined,
                          '${patient.weightKg} kg',
                        ),
                        _infoChip(
                          Icons.height_rounded,
                          '${patient.heightCm} cm',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.water_drop_outlined,
                            color: darkTeal,
                            size: 26,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isThai
                                      ? 'การทำงานของไต'
                                      : 'Renal Function',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: textDark,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  patient.serumCreatinineMgDl != null
                                      ? 'SCr: ${patient.serumCreatinineMgDl} mg/dL'
                                      : (isThai
                                          ? 'ไม่มีข้อมูล SCr'
                                          : 'SCr not provided'),
                                  style: const TextStyle(fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  patient.serumCreatinineMgDl != null
                                      ? 'CrCl: ${patient.creatinineClearanceMlMin?.toStringAsFixed(1) ?? '-'} mL/min'
                                      : (isThai
                                          ? 'ไม่สามารถแสดงค่า CrCl ได้'
                                          : 'CrCl unavailable'),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: darkTeal,
                                  ),
                                ),
                                if (patient.serumCreatinineMgDl != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: Text(
                                      patient.isScrStable
                                          ? (isThai
                                              ? 'สถานะ SCr: คงที่'
                                              : 'SCr status: Stable')
                                          : (isThai
                                              ? 'สถานะ SCr: ไม่คงที่'
                                              : 'SCr status: Unstable'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: patient.isScrStable
                                            ? darkTeal
                                            : Colors.deepOrange.shade700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              // Medication section
              Row(
                children: [
                  Expanded(
                    child: _sectionTitle(
                      isThai
                          ? 'รายการยาปัจจุบัน'
                          : 'Active Medications',
                      Icons.medication_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _addDrug(context, patient),
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 19),
                    label: Text(
                      isThai ? 'เพิ่มยา' : 'Add Drug',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (patient.activeDrugIds.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 34,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFDCEFE9),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.medication_liquid_outlined,
                        size: 46,
                        color: Color(0xFF9ABDB4),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isThai
                            ? 'ยังไม่มีรายการยา'
                            : 'No medications added',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isThai
                            ? 'กด “เพิ่มยา” เพื่อค้นหาและเพิ่มรายการยา'
                            : 'Tap "Add Drug" to search and add a medication.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.blueGrey,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...patient.activeDrugIds.map((id) {
                  final drug = DrugDatabase.findById(id);
                  final res = results[id];

                  if (drug == null || res == null) {
                    return const SizedBox.shrink();
                  }

                  final doseText = res.roundedDose != null
                      ? '${res.roundedDose!.toStringAsFixed(0)} '
                          '${res.doseUnit?.symbol ?? ''}'
                      : '${res.calculatedDose?.toStringAsFixed(2) ?? '-'} '
                          '${res.doseUnit?.symbol ?? ''}';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFDCEFE9),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: darkTeal.withValues(alpha: 0.035),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: mint,
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: const Icon(
                                Icons.medication_rounded,
                                color: darkTeal,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                drug.genericName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: isThai
                                  ? 'นำยาออกจากรายการ'
                                  : 'Remove medication',
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                final newIds = List<String>.from(
                                  patient.activeDrugIds,
                                )..remove(id);

                                PatientSession.instance.savePatient(
                                  patient.copyWith(
                                    activeDrugIds: newIds,
                                  ),
                                  setAsCurrent: true,
                                );
                              },
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.blueGrey,
                                size: 21,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Calculated dose
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: mint,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: const Color(0xFFCBEAE0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calculate_outlined,
                                    size: 18,
                                    color: darkTeal,
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      isThai
                                          ? 'ขนาดยาที่คำนวณได้'
                                          : 'Calculated Dose',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: darkTeal,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                doseText,
                                style: const TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                  color: darkTeal,
                                ),
                              ),
                              if (res.frequency != null &&
                                  res.frequency!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  res.frequency!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: textDark,
                                  ),
                                ),
                              ],
                              if (res.isRenallyAdjusted ||
                                  res.roundedDose != null) ...[
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    if (res.isRenallyAdjusted)
                                      _statusChip(
                                        isThai
                                            ? 'ปรับตามการทำงานของไต'
                                            : 'Renal adjustment',
                                        Icons.water_drop_outlined,
                                      ),
                                    if (res.roundedDose != null)
                                      _statusChip(
                                        isThai
                                            ? 'ปัดเศษขนาดยา'
                                            : 'Rounded dose',
                                        Icons.check_circle_outline,
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Drug-specific TDM
                        if (drug.genericName
                            .toLowerCase()
                            .contains('vancomycin')) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
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
                              style: OutlinedButton.styleFrom(
                                foregroundColor: darkTeal,
                                side: const BorderSide(
                                  color: primary,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(
                                Icons.monitor_heart_outlined,
                                size: 19,
                              ),
                              label: const Text('TDM'),
                            ),
                          ),
                        ],

                        // Warnings
                        if (res.warnings.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7E9),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: const Color(0xFFF2D7A4),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.warning_amber_rounded,
                                      color: Color(0xFFB66B00),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 7),
                                    Text(
                                      isThai
                                          ? 'คำเตือน'
                                          : 'Warnings',
                                      style: const TextStyle(
                                        color: Color(0xFF925600),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ...res.warnings.map(
                                  (warning) => Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 6),
                                    child: Text(
                                      '• ${isThai ? warning.messageTh : warning.messageEn}',
                                      style: const TextStyle(
                                        color: Color(0xFF79531B),
                                        fontSize: 13,
                                        height: 1.5,
                                      ),
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
                }),

              const SizedBox(height: 10),

              // Copy pharmacist note
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: () =>
                      _copySoapNote(context, patient, results),
                  style: FilledButton.styleFrom(
                    backgroundColor: darkTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  icon: const Icon(Icons.copy_all_rounded),
                  label: Text(
                    isThai
                        ? 'คัดลอกสรุปยาทั้งหมด (SOAP Note)'
                        : 'Copy Medication Summary (SOAP Note)',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                isThai
                    ? 'โปรดตรวจสอบผลคำนวณและคำเตือนก่อนนำไปใช้ทางคลินิก'
                    : 'Review all calculated doses and warnings before clinical use.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.blueGrey,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: darkTeal, size: 23),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: const Color(0xFFE0EDE9),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: darkTeal),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: textDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: const Color(0xFFB8DED2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: darkTeal),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: darkTeal,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DrugSearchDelegate extends SearchDelegate {
  final bool isThai;
  final Patient patient;

  _DrugSearchDelegate({
    required this.isThai,
    required this.patient,
  });

  static const Color primary = Color(0xFF08A88A);
  static const Color darkTeal = Color(0xFF087F70);

  @override
  String get searchFieldLabel =>
      isThai ? 'ค้นหาชื่อสามัญหรือชื่อการค้า' : 'Search medications';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        tooltip: isThai ? 'ล้างคำค้นหา' : 'Clear search',
        icon: const Icon(Icons.clear_rounded),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildList();

  @override
  Widget buildSuggestions(BuildContext context) => _buildList();

  Widget _buildList() {
    final results = DrugDatabase.search(query);

    if (results.isEmpty) {
      return Center(
        child: Text(
          isThai ? 'ไม่พบรายการยา' : 'No medications found',
          style: const TextStyle(color: Colors.blueGrey),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final drug = results[index];
        final alreadyAdded =
            patient.activeDrugIds.contains(drug.id);

        return Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(
              color: Color(0xFFDCEFE9),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 5,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE7F7F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.medication_rounded,
                color: darkTeal,
              ),
            ),
            title: Text(
              drug.genericName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              drug.brandNames.join(', '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Icon(
              alreadyAdded
                  ? Icons.check_circle
                  : Icons.add_circle_outline,
              color: alreadyAdded ? darkTeal : primary,
            ),
            onTap: () {
              if (!alreadyAdded) {
                final newIds =
                    List<String>.from(patient.activeDrugIds)
                      ..add(drug.id);

                PatientSession.instance.savePatient(
                  patient.copyWith(activeDrugIds: newIds),
                  setAsCurrent: true,
                );
              }

              close(context, null);
            },
          ),
        );
      },
    );
  }
}
