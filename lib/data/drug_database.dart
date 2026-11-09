// ============================================================
// Drug Dosage Calculator — Drug Database
// ============================================================
// In-memory registry of all available drugs.
// In a real application, this might be loaded from a local SQLite
// database or a securely updated JSON file.
//
// DISCLAIMER: SaMD prototype — not for clinical use.
// ============================================================

import '../core/models/models.dart';
import 'drug_search_engine.dart';
import 'drugs/antibiotics.dart';
import 'drugs/chemotherapy.dart';
import 'drugs/cardiovascular.dart';
import 'drugs/analgesics.dart';
import 'drugs/gastrointestinal.dart';
import 'drugs/respiratory.dart';
import 'drugs/metabolic.dart';
import 'drugs/neurology.dart';
import 'drugs/emergency.dart';
import 'drugs/specialty.dart';
import 'drugs/psychiatry.dart';
import 'drugs/obgyn.dart';
import 'drugs/endocrine.dart';
import 'drugs/nephrology.dart';

/// Central repository for all drug definitions.
class DrugDatabase {
  const DrugDatabase._();

  /// All drugs currently loaded in the system.
  static final List<Drug> allDrugs = [
    ...antibiotics,
    ...chemotherapy,
    ...cardiovascular,
    ...analgesics,
    ...gastrointestinal,
    ...respiratory,
    ...metabolic,
    ...neurology,
    ...emergency,
    ...topical,
    ...anticoagulants,
    ...supplements,
    ...psychiatry,
    ...obstetric,
    ...endocrine,
    ...nephrology,
  ];

  /// Finds a drug by its unique [id].
  static Drug? findById(String id) {
    try {
      return allDrugs.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Pre-computed multi-dimensional search engine instance over [allDrugs].
  static final DrugSearchEngine _searchEngine = DrugSearchEngine(allDrugs);

  /// Searches drugs using the 10-tier multi-dimensional relevance scoring engine.
  ///
  /// Maintains 100% backward compatibility returning [List<Drug>] sorted by
  /// relevance score descending, then by genericName ascending.
  static List<Drug> search(String query, {DrugCategory? category}) {
    return _searchEngine
        .search(query, categoryFilter: category)
        .map((r) => r.drug)
        .toList();
  }

  /// Detailed clinical search returning [DrugSearchResult] objects containing
  /// relevance scores, matched reasons, and character highlight ranges.
  static List<DrugSearchResult> searchDetailed(
    String query, {
    DrugCategory? category,
    int? limit,
  }) {
    return _searchEngine.search(query, categoryFilter: category, limit: limit);
  }

  /// Gets all drugs in a specific category.
  static List<Drug> getByCategory(DrugCategory category) {
    return allDrugs.where((d) => d.category == category).toList();
  }
}
