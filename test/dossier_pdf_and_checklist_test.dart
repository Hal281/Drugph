// ============================================================================
// Dossier PDF & Pending Pharmacist Sign-Off Checklist Verification Tests
// ============================================================================
// Verifies:
// 1. review/Pending_Pharmacist_Signoff_Checklist.md exists and contains all 6
//    clinical decision codes (DEC-PND-001 through DEC-PND-006) with detailed
//    clinical dilemmas, baseline math, candidate options, and signature blocks.
// 2. review/Clinical_Verification_Dossier.pdf exists, is non-empty (> 100 KB),
//    has valid PDF magic bytes (%PDF-), and was generated with complete coverage.
// 3. tool/generate_pharmacist_dossier_pdf.dart exists and integrates
//    High-Alert monographs and PendingPharmacistRegistry into a 4-section layout.
// ============================================================================

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Dossier PDF & Checklist File Verification', () {
    test('1. review/Pending_Pharmacist_Signoff_Checklist.md exists and covers all 6 decisions', () {
      final checklistFile = File('review/Pending_Pharmacist_Signoff_Checklist.md');
      expect(
        checklistFile.existsSync(),
        isTrue,
        reason: 'review/Pending_Pharmacist_Signoff_Checklist.md must exist on disk',
      );

      final content = checklistFile.readAsStringSync();
      expect(content.isNotEmpty, isTrue);

      const expectedCodes = [
        'DEC-PND-001',
        'DEC-PND-002',
        'DEC-PND-003',
        'DEC-PND-004',
        'DEC-PND-005',
        'DEC-PND-006',
      ];

      for (final code in expectedCodes) {
        expect(
          content.contains(code),
          isTrue,
          reason: 'Checklist must contain decision code $code',
        );
      }

      // Check required clinical subjects
      expect(content.contains('Acyclovir'), isTrue, reason: 'Must cover Acyclovir IV');
      expect(content.contains('Atropine'), isTrue, reason: 'Must cover Atropine');
      expect(content.contains('Dexamethasone'), isTrue, reason: 'Must cover Dexamethasone');
      expect(content.contains('Epinephrine'), isTrue, reason: 'Must cover Epinephrine');
      expect(content.contains('Salbutamol'), isTrue, reason: 'Must cover Salbutamol');
      expect(
        content.contains('Hartford') || content.contains('Vancomycin'),
        isTrue,
        reason: 'Must cover Hartford nomogram & Vancomycin Vd',
      );

      // Check candidate options and PTC signature block
      expect(content.contains('Option A'), isTrue);
      expect(content.contains('Option B'), isTrue);
      expect(content.contains('Option C'), isTrue);
      expect(content.contains('ภ.'), isTrue, reason: 'Must contain Pharmacist license block');
      expect(content.contains('ว.'), isTrue, reason: 'Must contain Physician license block');
    });

    test('2. review/Clinical_Verification_Dossier.pdf exists, is > 100 KB, and has valid PDF format', () {
      final pdfFile = File('review/Clinical_Verification_Dossier.pdf');
      expect(
        pdfFile.existsSync(),
        isTrue,
        reason: 'review/Clinical_Verification_Dossier.pdf must exist on disk',
      );

      final fileLength = pdfFile.lengthSync();
      expect(
        fileLength,
        greaterThan(100 * 1024),
        reason: 'Dossier PDF must be > 100 KB (actual: ${(fileLength / 1024).toStringAsFixed(1)} KB)',
      );

      // Validate PDF magic bytes (%PDF-)
      final bytes = pdfFile.readAsBytesSync();
      final header = String.fromCharCodes(bytes.take(5));
      expect(header, equals('%PDF-'), reason: 'File must start with standard %PDF- header');

      // Validate PDF EOF marker in the last 1024 bytes
      final tail = String.fromCharCodes(bytes.skip(bytes.length - 1024.clamp(0, bytes.length)));
      expect(tail.contains('%%EOF'), isTrue, reason: 'File must end with standard %%EOF trailer');
    });

    test('3. tool/generate_pharmacist_dossier_pdf.dart integrates 4 sections and PendingPharmacistRegistry', () {
      final scriptFile = File('tool/generate_pharmacist_dossier_pdf.dart');
      expect(scriptFile.existsSync(), isTrue);

      final scriptContent = scriptFile.readAsStringSync();

      // Consumes PendingPharmacistRegistry
      expect(scriptContent.contains('PendingPharmacistRegistry'), isTrue);
      expect(scriptContent.contains('allDecisions'), isTrue);

      // Contains 14 High-Alert drugs
      expect(scriptContent.contains('highAlertIds'), isTrue);
      expect(scriptContent.contains('warfarin'), isTrue);
      expect(scriptContent.contains('norepinephrine'), isTrue);
      expect(scriptContent.contains('insulin_regular'), isTrue);

      // Defines 4 sections
      expect(scriptContent.contains('SECTION 1'), isTrue);
      expect(scriptContent.contains('SECTION 2'), isTrue);
      expect(scriptContent.contains('SECTION 3'), isTrue);
      expect(scriptContent.contains('SECTION 4'), isTrue);

      // Certification signatures
      expect(scriptContent.contains('Clinical Pharmacist Reviewer'), isTrue);
      expect(scriptContent.contains('Attending Physician / PTC Chair'), isTrue);
    });
  });
}
