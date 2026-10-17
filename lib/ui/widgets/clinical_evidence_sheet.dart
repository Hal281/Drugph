import 'package:flutter/material.dart';
import '../../core/models/models.dart';

/// Interactive modal bottom sheet / dialog that displays the clinical textbook
/// monograph and evidence for the selected drug and regimen.
class ClinicalEvidenceSheet extends StatelessWidget {
  final Drug drug;
  final DosingRegimen? regimen;
  final bool isThai;

  const ClinicalEvidenceSheet({
    super.key,
    required this.drug,
    this.regimen,
    this.isThai = true,
  });

  /// Displays the monograph as a responsive modal bottom sheet or dialog.
  static Future<void> show(
    BuildContext context, {
    required Drug drug,
    DosingRegimen? regimen,
    bool isThai = true,
  }) {
    final isDesktop = MediaQuery.of(context).size.width > 700;
    if (isDesktop) {
      return showDialog(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680, maxHeight: 750),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ClinicalEvidenceSheet(drug: drug, regimen: regimen, isThai: isThai),
            ),
          ),
        ),
      );
    }

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: ClinicalEvidenceSheet(
              drug: drug,
              regimen: regimen,
              isThai: isThai,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mono = regimen?.monograph ?? drug.monograph;
    final textbookName = mono?.textbookName ??
        (drug.sourceCitation.isNotEmpty
            ? drug.sourceCitation
            : (isThai ? 'รอยืนยันแหล่งอ้างอิง (UNVERIFIED)' : 'Unverified Citation'));
    final edition = mono?.editionYear ?? (drug.lastReviewedDate.isNotEmpty ? drug.lastReviewedDate : 'Current Version');
    final section = mono?.sectionOrTable;

    final isVerified = drug.provenance != null ||
        (regimen?.verificationStatus == VerificationStatus.verified);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.menu_book_rounded, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isThai ? 'ข้อมูลอ้างอิงจากตำราแพทย์' : 'Textbook Monograph & Evidence',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: isThai ? 'ปิด' : 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drug & Citation Header Card
            _buildCitationHeader(textbookName, edition, section, isVerified),
            const SizedBox(height: 16),

            // Standard Dosing Monograph
            _buildSectionCard(
              title: isThai ? 'ขนาดยาและการบริหารยาตามตำรา' : 'Official Dosing & Administration',
              icon: Icons.medication_liquid_rounded,
              color: Colors.teal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (mono?.dosingGuideline != null)
                    Text(
                      mono!.dosingGuideline,
                      style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF1E293B)),
                    )
                  else if (regimen != null) ...[
                    _buildKeyValue(
                      isThai ? 'ข้อบ่งใช้' : 'Indication',
                      regimen!.indication ?? (isThai ? 'ขนาดยามาตรฐาน' : 'Standard Dosing'),
                    ),
                    _buildKeyValue(
                      isThai ? 'สูตรขนาดยา' : 'Regimen Formula',
                      '${regimen!.dosingType.nameEn}: ${regimen!.fixedDose ?? regimen!.dosePerKg ?? regimen!.dosePerM2 ?? ''} ${regimen!.doseUnit.symbol} ${regimen!.frequency.displayEn}',
                    ),
                    if (regimen!.limits?.maxSingleDose != null)
                      _buildKeyValue(
                        isThai ? 'ขนาดยาสูงสุดต่อครั้ง' : 'Max Single Dose',
                        '${regimen!.limits!.maxSingleDose} ${regimen!.doseUnit.symbol}',
                      ),
                    if (regimen!.limits?.maxDailyDose != null)
                      _buildKeyValue(
                        isThai ? 'ขนาดยาสูงสุดต่อวัน' : 'Max Daily Dose',
                        '${regimen!.limits!.maxDailyDose} ${regimen!.doseUnit.symbol}/day',
                      ),
                  ] else
                    Text(
                      isThai
                          ? 'ยา ${drug.genericName} (${drug.nameTh ?? ''}) สำหรับใช้รักษาตามข้อบ่งใช้ที่ระบุในคู่มือ'
                          : '${drug.genericName} therapeutic dosing guidelines.',
                      style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Renal Adjustment Tiers (ตารางการปรับยาตามไตจากตำรา)
            if (regimen?.renalAdjustments != null && regimen!.renalAdjustments!.isNotEmpty) ...[
              _buildSectionCard(
                title: isThai ? 'เกณฑ์การปรับขนาดยาตามระดับไต (Renal Tiers)' : 'Renal Impairment Adjustments',
                icon: Icons.water_drop_rounded,
                color: Colors.blue.shade700,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (mono?.renalGuideline != null) ...[
                      Text(
                        mono!.renalGuideline!,
                        style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _buildRenalTable(regimen!.renalAdjustments!),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // IV Infusion / Preparation (ถ้ามี)
            if (regimen?.standardDilutionMgPerMl != null ||
                regimen?.standardDilution != null ||
                mono?.administrationGuideline != null) ...[
              _buildSectionCard(
                title: isThai ? 'คำแนะนำการบริหารยาทางหลอดเลือดดำ (IV Preparation)' : 'IV Dilution & Infusion',
                icon: Icons.science_rounded,
                color: Colors.indigo.shade600,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (mono?.administrationGuideline != null)
                      Text(
                        mono!.administrationGuideline!,
                        style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF1E293B)),
                      ),
                    if (regimen?.effectiveStandardDilutionMgPerMl != null) ...[
                      const SizedBox(height: 8),
                      _buildKeyValue(
                        isThai ? 'ความเข้มข้นสารน้ำมาตรฐาน' : 'Standard Dilution',
                        '${regimen!.effectiveStandardDilutionMgPerMl} mg/mL',
                      ),
                    ],
                    if (regimen?.infusionTimeMinutes != null)
                      _buildKeyValue(
                        isThai ? 'ระยะเวลาหยดยาที่แนะนำ' : 'Infusion Duration',
                        '${regimen!.infusionTimeMinutes!.toStringAsFixed(0)} นาที (min)',
                      ),
                    if (regimen?.maxInfusionRateMgPerMin != null)
                      _buildKeyValue(
                        isThai ? 'อัตราการให้ยาสูงสุด' : 'Max Infusion Rate',
                        '${regimen!.maxInfusionRateMgPerMin} mg/min',
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Precautions & Black Box Warnings
            if (drug.contraindications.isNotEmpty ||
                mono?.clinicalNotes != null ||
                drug.specialNotes != null ||
                drug.specialNotesTh != null) ...[
              _buildSectionCard(
                title: isThai ? 'ข้อควรระวังและข้อห้ามใช้ทางคลินิก' : 'Precautions & Contraindications',
                icon: Icons.warning_amber_rounded,
                color: Colors.amber.shade800,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (mono?.clinicalNotes != null) ...[
                      Text(
                        mono!.clinicalNotes!,
                        style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF9A3412)),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (drug.specialNotesTh != null || drug.specialNotes != null) ...[
                      Text(
                        isThai ? (drug.specialNotesTh ?? drug.specialNotes!) : (drug.specialNotes ?? ''),
                        style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (drug.contraindications.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        isThai ? 'ข้อห้ามใช้เด็ดขาด (Contraindications):' : 'Contraindications:',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red),
                      ),
                      const SizedBox(height: 4),
                      ...drug.contraindications.map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 2),
                          child: Text('• $c', style: const TextStyle(fontSize: 13, color: Color(0xFFDC2626))),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Clinical Review Stamp (ตรายางรับรองโดยเภสัชกร)
            _buildReviewerStampCard(isVerified),
          ],
        ),
      ),
    );
  }

  Widget _buildCitationHeader(String textbook, String edition, String? section, bool isVerified) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.auto_stories_rounded, color: Colors.teal.shade700, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      drug.genericName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (drug.nameTh != null)
                      Text(
                        drug.nameTh!,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      isThai ? 'หมวด: ${drug.category.nameTh}' : 'Category: ${drug.category.nameEn}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.bookmark_added_rounded, size: 16, color: Colors.teal),
              const SizedBox(width: 6),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                    children: [
                      TextSpan(
                        text: isThai ? 'ตำราอ้างอิง: ' : 'Textbook: ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: textbook,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade800,
                        ),
                      ),
                      TextSpan(text: ' ($edition)'),
                      if (section != null) TextSpan(text: '\n• $section'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildKeyValue(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$key:',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRenalTable(List<RenalAdjustment> tiers) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(1.2),
            1: FlexColumnWidth(2.0),
          },
          border: TableBorder.all(color: const Color(0xFFE2E8F0)),
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    isThai ? 'ระดับ CrCl' : 'CrCl Level',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    isThai ? 'การปรับขนาดยา / คำแนะนำ' : 'Adjustment / Action',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                  ),
                ),
              ],
            ),
            ...tiers.map((t) {
              final crclRange = t.crclMax == double.infinity
                  ? '≥ ${t.crclMin.toInt()} mL/min'
                  : '${t.crclMin.toInt()} - ${t.crclMax.toInt()} mL/min';
              final actionText = t.absoluteDose != null
                  ? '${t.absoluteDose} mg ${t.adjustedFrequency?.displayEn ?? ""}'
                  : (t.adjustmentFactor < 1.0
                      ? '${(t.adjustmentFactor * 100).toInt()}% ของขนาดปกติ ${t.adjustedFrequency?.displayEn ?? ""}'
                      : (t.notesTh ?? t.notes ?? t.action.labelTh));

              return TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      crclRange,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      actionText,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewerStampCard(bool isVerified) {
    final prov = drug.provenance;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isVerified ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isVerified ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isVerified ? Icons.verified_rounded : Icons.pending_actions_rounded,
            color: isVerified ? const Color(0xFF16A34A) : const Color(0xFFD97706),
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isVerified
                      ? (isThai ? 'ข้อมูลได้รับการตรวจรับรองทางคลินิกแล้ว' : 'Clinically Verified Monograph')
                      : (isThai ? 'รอการลงนามรับรองโดยเภสัชกรคลินิก (Pending Verification)' : 'Pending Clinical Pharmacist Verification'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isVerified ? const Color(0xFF15803D) : const Color(0xFFB45309),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  prov != null
                      ? '${isThai ? "ผู้ตรวจ:" : "Reviewer:"} ${prov.reviewedBy} ${prov.reviewerLicense != null ? "(${prov.reviewerLicense})" : ""} • ${prov.reviewedAt}'
                      : (isThai
                          ? 'ข้อมูลอยู่ในชุดตรวจสอบ Clinical Dossier เพื่อให้อาจารย์และเภสัชกรตรวจเซ็นรับรอง'
                          : 'Monograph included in Clinical Dossier awaiting formal verification.'),
                  style: TextStyle(
                    fontSize: 12,
                    color: isVerified ? const Color(0xFF166534) : const Color(0xFF92400E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
