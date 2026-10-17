
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/history_service.dart';
import '../core/audit/pdf_report_generator.dart';

class HistoryScreen extends StatelessWidget {
  final bool isThai;

  const HistoryScreen({
    super.key,
    required this.isThai,
  });

  static const Color primary = Color(0xFF08A88A);
  static const Color darkTeal = Color(0xFF087F70);
  static const Color mint = Color(0xFFE7F7F2);
  static const Color background = Color(0xFFF5FAF9);
  static const Color textDark = Color(0xFF253C3A);

  @override
  Widget build(BuildContext context) {
    final logs = HistoryService().logs;
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm:ss');

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: textDark,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: mint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.history_rounded,
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
                        ? 'ประวัติการคำนวณยา'
                        : 'Calculation History',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  Text(
                    isThai
                        ? 'บันทึกและตรวจสอบย้อนหลัง'
                        : 'Review previous calculations',
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
        actions: [
          IconButton(
            tooltip: isThai ? 'ส่งออก PDF' : 'Export PDF',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            color: darkTeal,
            onPressed: () {
              final currentLogs = HistoryService().logs;

              if (currentLogs.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isThai
                          ? 'ไม่มีประวัติให้ส่งออก'
                          : 'No history available to export',
                    ),
                    backgroundColor: darkTeal,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              PdfReportGenerator.generateAndPrint(currentLogs);
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: logs.isEmpty
          ? _buildEmptyState()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Summary header
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF08A88A),
                        Color(0xFF087F70),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.fact_check_outlined,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isThai
                                  ? 'รายการคำนวณทั้งหมด'
                                  : 'Total Calculations',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${logs.length} ${isThai ? 'รายการ' : 'records'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: isThai
                            ? 'สร้างรายงาน PDF'
                            : 'Generate PDF report',
                        onPressed: () {
                          PdfReportGenerator.generateAndPrint(
                            HistoryService().logs,
                          );
                        },
                        icon: const Icon(
                          Icons.file_download_outlined,
                          color: Colors.white,
                          size: 27,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      color: darkTeal,
                      size: 22,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        isThai
                            ? 'บันทึกการคำนวณ'
                            : 'Calculation Records',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                ...logs.reversed.map((log) {
                  final successful = log.result.success;
                  final warnings = log.result.warnings;

                  final doseText =
                      '${log.result.calculatedDose?.toStringAsFixed(2) ?? '-'} '
                      '${log.result.doseUnit?.symbol ?? ''} '
                      '${log.result.frequency ?? ''}'.trim();

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
                        // Drug name and timestamp
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    log.drugName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    dateFormat.format(log.timestamp),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Calculation result
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: successful
                                ? mint
                                : const Color(0xFFFFF0EF),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: successful
                                  ? const Color(0xFFCBEAE0)
                                  : const Color(0xFFF3C9C6),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                successful
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.error_outline_rounded,
                                color: successful
                                    ? darkTeal
                                    : Colors.red.shade700,
                                size: 23,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      successful
                                          ? (isThai
                                              ? 'ผลการคำนวณ'
                                              : 'Calculation Result')
                                          : (isThai
                                              ? 'การคำนวณไม่สำเร็จ'
                                              : 'Calculation Failed'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: successful
                                            ? darkTeal
                                            : Colors.red.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      successful
                                          ? doseText
                                          : (isThai
                                              ? 'ไม่สามารถคำนวณขนาดยาได้'
                                              : 'Unable to calculate dose'),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: successful
                                            ? darkTeal
                                            : Colors.red.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Patient inputs
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: background,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFE0EDE9),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person_outline_rounded,
                                    size: 19,
                                    color: darkTeal,
                                  ),
                                  const SizedBox(width: 7),
                                  Text(
                                    isThai
                                        ? 'ข้อมูลที่ใช้คำนวณ'
                                        : 'Calculation Inputs',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: textDark,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _inputChip(
                                    Icons.monitor_weight_outlined,
                                    'Weight',
                                    '${log.inputs['weightKg'] ?? '-'} kg',
                                  ),
                                  _inputChip(
                                    Icons.cake_outlined,
                                    'Age',
                                    '${log.inputs['ageYears'] ?? '-'} y',
                                  ),
                                  _inputChip(
                                    Icons.person_outline,
                                    'Sex',
                                    '${log.inputs['sex'] ?? '-'}',
                                  ),
                                  _inputChip(
                                    Icons.water_drop_outlined,
                                    'SCr',
                                    '${log.inputs['scr'] ?? '-'} mg/dL',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Safety warnings
                        if (warnings.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7E9),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: const Color(0xFFF2D7A4),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Color(0xFFB66B00),
                                  size: 22,
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isThai
                                            ? 'คำเตือนความปลอดภัย ${warnings.length} รายการ'
                                            : '${warnings.length} Safety Warnings',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF925600),
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      ...warnings.map(
                                        (warning) => Padding(
                                          padding:
                                              const EdgeInsets.only(
                                            bottom: 4,
                                          ),
                                          child: Text(
                                            '• ${isThai ? warning.messageTh : warning.messageEn}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              height: 1.4,
                                              color: Color(0xFF79531B),
                                            ),
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

                        const SizedBox(height: 14),
                        const Divider(
                          height: 1,
                          color: Color(0xFFE8F0ED),
                        ),
                        const SizedBox(height: 10),

                        // Audit ID
                        Row(
                          children: [
                            const Icon(
                              Icons.verified_user_outlined,
                              size: 15,
                              color: Colors.blueGrey,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Audit ID: ${log.logId}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.blueGrey,
                                ),
                              ),
                            ),
                            Icon(
                              successful
                                  ? Icons.check_circle
                                  : Icons.error,
                              size: 15,
                              color: successful
                                  ? darkTeal
                                  : Colors.red.shade400,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(25),
              decoration: const BoxDecoration(
                color: mint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 52,
                color: darkTeal,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isThai
                  ? 'ยังไม่มีประวัติการคำนวณ'
                  : 'No Calculation History',
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isThai
                  ? 'เมื่อมีการคำนวณยา รายการจะปรากฏที่หน้านี้'
                  : 'Your medication calculation records will appear here.',
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

  Widget _inputChip(
    IconData icon,
    String label,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE0EDE9),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: darkTeal),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: const TextStyle(
              fontSize: 11,
              color: textDark,
            ),
          ),
        ],
      ),
    );
  }
}
