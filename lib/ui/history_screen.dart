
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/history_service.dart';
import '../core/audit/pdf_report_generator.dart';
import 'theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  final bool isThai;

  const HistoryScreen({
    super.key,
    required this.isThai,
  });

  @override
  Widget build(BuildContext context) {
    final logs = HistoryService().logs;
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm:ss');

    return Scaffold(
      backgroundColor: AppTheme.surfaceBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isThai ? 'ประวัติการคำนวณยา' : 'Calculation History',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              isThai
                  ? 'บันทึกและตรวจสอบย้อนหลัง'
                  : 'Clinical audit trail & review',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFCCFBF1),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isThai ? 'ส่งออก PDF' : 'Export PDF',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            color: Colors.white,
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
                // Summary header (flat clinical surface, no gradient)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderDefault),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryTealSoft,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.primaryTealBorder),
                        ),
                        child: const Icon(
                          Icons.fact_check_outlined,
                          color: AppTheme.primaryTeal,
                          size: 24,
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
                                color: AppTheme.inkSecondary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${logs.length} ${isThai ? 'รายการ' : 'records'}',
                              style: AppTheme.monoStyle(
                                color: AppTheme.inkPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          PdfReportGenerator.generateAndPrint(
                            HistoryService().logs,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          foregroundColor: AppTheme.primaryTealDark,
                          side: const BorderSide(color: AppTheme.borderStrong),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.file_download_outlined, size: 18),
                        label: Text(
                          isThai ? 'PDF' : 'PDF',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      color: AppTheme.primaryTeal,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isThai
                            ? 'บันทึกการคำนวณ'
                            : 'Calculation Records',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.inkPrimary,
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
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderDefault),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryTealSoft,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.primaryTealBorder,
                                ),
                              ),
                              child: const Icon(
                                Icons.medication_outlined,
                                color: AppTheme.primaryTeal,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    log.drugName,
                                    style: const TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.inkPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    dateFormat.format(log.timestamp),
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppTheme.inkMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Calculation result
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: successful
                                ? AppTheme.statusSafeBg
                                : AppTheme.statusCriticalBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: successful
                                  ? AppTheme.statusSafeBorder
                                  : AppTheme.statusCriticalBorder,
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
                                    ? AppTheme.statusSafe
                                    : AppTheme.statusCritical,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                            ? AppTheme.statusSafe
                                            : AppTheme.statusCritical,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      successful
                                          ? doseText
                                          : (isThai
                                              ? 'ไม่สามารถคำนวณขนาดยาได้'
                                              : 'Unable to calculate dose'),
                                      style: AppTheme.monoStyle(
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.w700,
                                        color: successful
                                            ? AppTheme.inkPrimary
                                            : AppTheme.statusCritical,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Patient inputs
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceSubtle,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.borderDefault),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person_outline_rounded,
                                    size: 17,
                                    color: AppTheme.primaryTeal,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isThai
                                        ? 'ข้อมูลที่ใช้คำนวณ'
                                        : 'Calculation Inputs',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5,
                                      color: AppTheme.inkPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
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
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.statusWarningBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppTheme.statusWarningBorder,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: AppTheme.statusWarning,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
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
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF92400E),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      ...warnings.map(
                                        (warning) => Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 3),
                                          child: Text(
                                            '• ${isThai ? warning.messageTh : warning.messageEn}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              height: 1.4,
                                              color: Color(0xFF78350F),
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

                        const SizedBox(height: 12),
                        const Divider(height: 1, color: AppTheme.borderDefault),
                        const SizedBox(height: 8),

                        // Audit ID
                        Row(
                          children: [
                            const Icon(
                              Icons.verified_user_outlined,
                              size: 14,
                              color: AppTheme.inkMuted,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Audit ID: ${log.logId}',
                                style: AppTheme.monoStyle(
                                  fontSize: 10.5,
                                  color: AppTheme.inkMuted,
                                ),
                              ),
                            ),
                            Icon(
                              successful ? Icons.check_circle : Icons.error,
                              size: 15,
                              color: successful
                                  ? AppTheme.statusSafe
                                  : AppTheme.statusCritical,
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryTealSoft,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryTealBorder),
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 44,
                color: AppTheme.primaryTeal,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isThai
                  ? 'ยังไม่มีประวัติการคำนวณ'
                  : 'No Calculation History',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.inkPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isThai
                  ? 'เมื่อมีการคำนวณยา รายการจะปรากฏที่หน้านี้'
                  : 'Your medication calculation records will appear here.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.inkSecondary,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderDefault),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppTheme.primaryTeal),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: AppTheme.inkPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
