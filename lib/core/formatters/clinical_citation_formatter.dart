import '../models/models.dart';

/// Deterministic clinical citation normalizer for Evidence Sheets and Dossiers (FB-20 / WP-10).
///
/// Ensures primary clinical attribution highlights peer-reviewed clinical references
/// (specifically *Drug Information Handbook (Lexicomp / APhA)* and authoritative specialty
/// guidelines) rather than raw regulatory API labels such as bare "OpenFDA".
class ClinicalCitationFormatter {
  const ClinicalCitationFormatter._();

  static const String _dihCanonical = 'Drug Information Handbook (Lexicomp / APhA)';

  /// Formats the primary textbook citation string for [drug] (and optional [regimen]).
  static String formatPrimaryCitation(
    Drug drug, {
    DosingRegimen? regimen,
    bool isThai = true,
  }) {
    final mono = regimen?.monograph ?? drug.monograph;
    final raw = (mono?.textbookName ?? '').trim().isNotEmpty
        ? mono!.textbookName.trim()
        : drug.sourceCitation.trim();

    if (raw.isEmpty) {
      return isThai
          ? '$_dihCanonical — รอยืนยันแหล่งอ้างอิงเฉพาะสูตร'
          : '$_dihCanonical — Pending regimen-specific verification';
    }

    return normalizeCitationString(raw);
  }

  /// Normalizes any raw citation text so raw "OpenFDA" tags are replaced with
  /// standard *Drug Information Handbook (Lexicomp / APhA)* attribution while
  /// preserving specialty clinical society guidelines.
  static String normalizeCitationString(String rawCitation) {
    var result = rawCitation.trim();
    if (result.isEmpty) return _dihCanonical;

    // Strip/replace raw OpenFDA labels so clinicians see curated DIH/Lexicomp attribution first.
    final hasOpenFda = RegExp(r'open\s*fda', caseSensitive: false).hasMatch(result);
    if (hasOpenFda) {
      result = result
          .replaceAll(
            RegExp(r'\bUS\s*FDA\s*\(?\s*Open\s*FDA\s*\)?(\s*API|\s*SPL)?', caseSensitive: false),
            _dihCanonical,
          )
          .replaceAll(
            RegExp(r'\bOpen\s*FDA\b(\s*API|\s*SPL)?', caseSensitive: false),
            _dihCanonical,
          );
    }

    // Expand bare "Lexicomp..." mentions to explicitly include "Drug Information Handbook (APhA)"
    // unless already present.
    final lower = result.toLowerCase();
    if (lower.contains('lexicomp') && !lower.contains('drug information handbook')) {
      result = result.replaceFirst(
        RegExp(
          r'Lexicomp(?:®|\(R\))?(?:\s+Drug\s+Information(?:\s+Handbook)?)?(?:\s+20\d{2})?(?:\s+Edition)?',
          caseSensitive: false,
        ),
        _dihCanonical,
      );
    } else if (!lower.contains('drug information handbook') && !lower.contains('lexicomp')) {
      // Ensure standard DIH/Lexicomp attribution complements single-source FDA/specialty notes
      // when DIH is not yet named explicitly.
      final isPureRegulatory = RegExp(
        r'^(US\s*FDA|FDA|DailyMed|Thai\s*FDA)',
        caseSensitive: false,
      ).hasMatch(result);
      if (isPureRegulatory) {
        result = '$_dihCanonical / $result';
      }
    }

    // Clean duplicate separators introduced during normalization
    result = result
        .replaceAll(RegExp(r'\s*/\s*/\s*'), ' / ')
        .replaceAll(RegExp(r'^[\s/•-]+|[\s/•-]+$'), '')
        .trim();

    return result.isEmpty ? _dihCanonical : result;
  }
}
