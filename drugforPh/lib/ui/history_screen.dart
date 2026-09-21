import 'package:flutter/material.dart';
import '../data/history_service.dart';
import 'package:intl/intl.dart';
import '../core/audit/pdf_report_generator.dart';

class HistoryScreen extends StatelessWidget {
  final bool isThai;

  const HistoryScreen({super.key, required this.isThai});

  @override
  Widget build(BuildContext context) {
    final logs = HistoryService().logs;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(isThai ? 'ประวัติการคำนวณ (Log)' : 'Calculation History'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: isThai ? 'สร้างไฟล์ PDF' : 'Export PDF',
            onPressed: () {
              if (HistoryService().logs.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isThai ? 'ไม่มีข้อมูลให้พิมพ์' : 'No data to export'),
                  ),
                );
                return;
              }
              PdfReportGenerator.generateAndPrint(HistoryService().logs);
            },
          ),
        ],
      ),
      body: logs.isEmpty
          ? Center(
              child: Text(
                isThai ? 'ไม่มีประวัติการคำนวณ' : 'No history found',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                final dateFormat = DateFormat('dd MMM yyyy, HH:mm:ss');

                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                log.drugName,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey),
                              ),
                            ),
                            Text(
                              dateFormat.format(log.timestamp),
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        const Divider(),

                        // Result
                        if (log.result.success)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              '${log.result.calculatedDose?.toStringAsFixed(2)} ${log.result.doseUnit?.symbol} ${log.result.frequency}',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green),
                            ),
                          )
                        else
                          const Text('Error during calculation',
                              style: TextStyle(color: Colors.red)),

                        const SizedBox(height: 8),

                        // Patient Inputs
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isThai ? 'ข้อมูลผู้ป่วย' : 'Patient Inputs',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(
                                'Weight: ${log.inputs['weightKg'] ?? '-'} kg | Age: ${log.inputs['ageYears'] ?? '-'} y\n'
                                'Sex: ${log.inputs['sex']} | SCr: ${log.inputs['scr'] ?? '-'} mg/dL',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ),

                        if (log.result.warnings.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.warning,
                                  color: Colors.orange, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                isThai
                                    ? 'มีการแจ้งเตือนความปลอดภัย ${log.result.warnings.length} รายการ'
                                    : '${log.result.warnings.length} Safety Warnings',
                                style: const TextStyle(
                                    color: Colors.orange,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 8),
                        Text(
                          'Audit ID: ${log.logId}',
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
