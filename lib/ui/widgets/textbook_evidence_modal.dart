import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/models/verified_drug_schema.dart';
import '../../data/knowledge_base_loader.dart';

/// Pillar 3 Widget: Textbook Evidence Modal.
///
/// Displays the textbook source name, edition, page number, human verification
/// status (`isFullyVerified`: requires `sourceVerified == true` AND non-empty
/// `verifiedBy` AND `verifiedDate`), renal adjustment table, and textbook page
/// screenshot (with automatic fallback via `errorBuilder` when the `.png` file
/// is not yet placed in `assets/evidence/`).
class TextbookEvidenceModal extends StatelessWidget {
  final VerifiedDrugEntry drug;

  const TextbookEvidenceModal({
    super.key,
    required this.drug,
  });

  static Future<void> show(
    BuildContext context, {
    required VerifiedDrugEntry drug,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        key: const Key('textbook_evidence_modal_dialog'),
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
          child: TextbookEvidenceModal(drug: drug),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = drug.drugInfo;
    final meta = drug.verificationMetadata;
    final rules = drug.dosingRules;
    final isVerified = meta.isFullyVerified;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Color(0xFF1E3A8A),
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'หลักฐานอ้างอิงจากตำราแพทย์ (Textbook Evidence)',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    Text(
                      '${info.genericName} — ${info.strengthLabel} (RxNorm ID: ${info.rxnormId})',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const Key('close_textbook_evidence_modal'),
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(height: 24),
          // Scrollable Body
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Verification Status Banner (Requires source_verified + verified_by + verified_date)
                  Container(
                    key: const Key('source_verification_status_banner'),
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isVerified
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isVerified
                            ? const Color(0xFF86EFAC)
                            : const Color(0xFFFCD34D),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isVerified
                              ? Icons.verified_rounded
                              : Icons.pending_actions_rounded,
                          color: isVerified
                              ? const Color(0xFF166534)
                              : const Color(0xFF92400E),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isVerified
                                ? 'สถานะ: ตรวจเทียบหน้าหนังสือจริงโดย ${meta.verifiedBy} เมื่อ ${meta.verifiedDate} (source_verified: true)'
                                : 'สถานะ: รอเภสัชกร/อาจารย์เปิดตำราเทียบเลขหน้าจริงและลงนามรับรอง (source_verified: ${meta.sourceVerified} | ${meta.verifiedStatus})',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isVerified
                                  ? const Color(0xFF166534)
                                  : const Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Citation Details Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMetaRow(
                          'ชื่อตำราอ้างอิง (Source):',
                          meta.sourceName,
                        ),
                        const SizedBox(height: 6),
                        _buildMetaRow(
                          'ฉบับและเลขหน้า (Edition & Page):',
                          meta.editionAndPage,
                        ),
                        const SizedBox(height: 6),
                        _buildMetaRow(
                          'ผู้ตรวจรับรอง (Verified By):',
                          meta.verifiedBy ??
                              'ยังไม่ได้ตรวจรับรอง (Pending Pharmacist/Faculty Sign-Off)',
                        ),
                        const SizedBox(height: 6),
                        _buildMetaRow(
                          'วันที่ตรวจรับรอง (Verified Date):',
                          meta.verifiedDate ?? '-',
                        ),
                        const SizedBox(height: 6),
                        _buildMetaRow(
                          'สูตรมาตรฐาน (${rules.formulaType}):',
                          'แนะนำ ${rules.doseRange.recommendedMgPerKgPerDose} (ช่วง ${rules.doseRange.minMgPerKgPerDose}-${rules.doseRange.maxMgPerKgPerDose}) | '
                          'Max Single: ${rules.maxSingleDoseMg} mg | Max Daily: ${rules.maxDailyDoseMg} mg',
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'ลิงก์ฐานข้อมูลมาตรฐาน: ${meta.referenceUrl}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF1D4ED8),
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: meta.referenceUrl),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('คัดลอกลิงก์อ้างอิงแล้ว'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy, size: 16),
                              label: const Text('คัดลอก URL'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Renal Adjustment Tiers Table
                  const Text(
                    'ตารางเกณฑ์การปรับลดขนาดยาตามค่าไต (crcl >= min && crcl < max):',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...rules.renalAdjustment.map((tier) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: tier.isContraindicated
                            ? const Color(0xFFFEF2F2)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: tier.isContraindicated
                              ? const Color(0xFFFECACA)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Text(
                        '[${tier.crclMinMlMin.toStringAsFixed(1)} <= ค่าไต < ${tier.crclMaxMlMin.toStringAsFixed(1)}] '
                        '-> ความถี่: ${tier.adjustedInterval} | ตัวคูณโดส: ${tier.doseAdjustmentFactor} '
                        '(${tier.clinicalNote})',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: tier.isContraindicated
                              ? const Color(0xFF991B1B)
                              : const Color(0xFF334155),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  const Text(
                    'รูปภาพหน้าหนังสืออ้างอิง (Textbook Evidence Image):',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  KnowledgeBaseLoader.buildEvidenceImageWithFallback(
                    metadata: meta,
                    genericName: info.genericName,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
        children: [
          TextSpan(
            text: '$label ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}
