import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/models/verified_drug_schema.dart';
import '../core/validators/schema_validator.dart';

/// Loads and validates `assets/data/drug_knowledge_base.json` (Pillar 1),
/// and provides crash-safe fallback rendering when textbook screenshot `.png`
/// files in `assets/evidence/` have not been placed yet.
class KnowledgeBaseLoader {
  static const String defaultAssetPath = 'assets/data/drug_knowledge_base.json';

  const KnowledgeBaseLoader._();

  /// Parses a JSON string and validates it against [SchemaValidator].
  /// Throws [FormatException] if validation fails.
  static VerifiedDrugKnowledgeBase loadFromJsonString(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Root of drug_knowledge_base.json must be a JSON object.',
      );
    }
    final kb = VerifiedDrugKnowledgeBase.fromJson(decoded);
    final report = SchemaValidator.validateKnowledgeBase(kb);
    if (!report.isValid) {
      throw FormatException(
        'Drug Knowledge Base failed schema validation:\n - ${report.errors.join('\n - ')}',
      );
    }
    return kb;
  }

  /// Loads `drug_knowledge_base.json` from the local filesystem (for tests & CLI).
  static Future<VerifiedDrugKnowledgeBase> loadFromFile([
    String filePath = defaultAssetPath,
  ]) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException(
        'Verified drug knowledge base file not found',
        filePath,
      );
    }
    final content = await file.readAsString();
    return loadFromJsonString(content);
  }

  /// Loads `drug_knowledge_base.json` via Flutter's [AssetBundle].
  static Future<VerifiedDrugKnowledgeBase> loadFromAssetBundle([
    AssetBundle? bundle,
    String assetPath = defaultAssetPath,
  ]) async {
    final effectiveBundle = bundle ?? rootBundle;
    final content = await effectiveBundle.loadString(assetPath);
    return loadFromJsonString(content);
  }

  /// Checks whether an evidence image file currently exists on disk without
  /// throwing an exception.
  static bool doesEvidenceImageExistSync(String evidenceImagePath) {
    if (evidenceImagePath.trim().isEmpty) return false;
    try {
      return File(evidenceImagePath).existsSync();
    } catch (_) {
      return false;
    }
  }

  /// Renders the textbook evidence image from [VerificationMetadata.evidenceImagePath],
  /// using `Image.asset(..., errorBuilder: ...)` so that if the `.png` file has
  /// not been placed in `assets/evidence/` yet, it renders a clean, structured
  /// simulated textbook reference card instead of crashing.
  static Widget buildEvidenceImageWithFallback({
    required VerificationMetadata metadata,
    String? genericName,
  }) {
    return Image.asset(
      metadata.evidenceImagePath,
      fit: BoxFit.contain,
      errorBuilder: (BuildContext context, Object error, StackTrace? stack) {
        return SimulatedTextbookEvidenceCard(
          metadata: metadata,
          genericName: genericName,
        );
      },
    );
  }
}

/// Fallback widget rendered by `Image.asset`'s `errorBuilder` when the physical
/// `.png` file in `assets/evidence/` is not yet present.
class SimulatedTextbookEvidenceCard extends StatelessWidget {
  final VerificationMetadata metadata;
  final String? genericName;

  const SimulatedTextbookEvidenceCard({
    super.key,
    required this.metadata,
    this.genericName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('simulated_textbook_evidence_card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_rounded, color: Color(0xFF1E40AF)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  genericName != null && genericName!.isNotEmpty
                      ? 'เอกสารอ้างอิงจากตำรา: $genericName'
                      : 'หน้าจำลองเอกสารอ้างอิงจากตำรา (Textbook Evidence)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Text(
            'ตำราอ้างอิง (Source): ${metadata.sourceName}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'ฉบับและเลขหน้า (Edition & Page): ${metadata.editionAndPage}',
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            'ฐานข้อมูลมาตรฐาน (DailyMed URL): ${metadata.referenceUrl}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF2563EB)),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'หมายเหตุ: แสดงหน้าจำลองข้อมูลตำราอัตโนมัติ (ยังไม่ได้วางไฟล์ภาพ ${metadata.evidenceImagePath})',
              style: const TextStyle(fontSize: 11, color: Color(0xFF92400E)),
            ),
          ),
        ],
      ),
    );
  }
}
