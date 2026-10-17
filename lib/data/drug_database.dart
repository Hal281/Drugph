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

  /// Searches drugs by generic name, brand name, or Thai name with case-insensitive
  /// and light fuzzy matching.
  static List<Drug> search(String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return allDrugs;

    final cleanQuery = trimmed.replaceAll(RegExp(r'[\s\-_/]'), '');

    return allDrugs.where((d) {
      final generic = d.genericName.toLowerCase();
      final cleanGeneric = generic.replaceAll(RegExp(r'[\s\-_/]'), '');

      // 1. Direct and normalized substring matches
      if (generic.contains(trimmed) || cleanGeneric.contains(cleanQuery)) {
        return true;
      }

      // 2. Thai name match
      if (d.nameTh != null) {
        final thai = d.nameTh!.toLowerCase();
        if (thai.contains(trimmed)) return true;
      }

      // 3. Brand names match
      for (final b in d.brandNames) {
        final brand = b.toLowerCase();
        final cleanBrand = brand.replaceAll(RegExp(r'[\s\-_/]'), '');
        if (brand.contains(trimmed) || cleanBrand.contains(cleanQuery)) {
          return true;
        }
      }

      // 4. Light fuzzy match: query chars appear in order in generic name
      if (cleanQuery.length >= 3) {
        int queryIdx = 0;
        for (int i = 0; i < cleanGeneric.length && queryIdx < cleanQuery.length; i++) {
          if (cleanGeneric[i] == cleanQuery[queryIdx]) {
            queryIdx++;
          }
        }
        if (queryIdx == cleanQuery.length) return true;
      }

      return false;
    }).toList();
  }

  /// Gets all drugs in a specific category.
  static List<Drug> getByCategory(DrugCategory category) {
    return allDrugs.where((d) => d.category == category).toList();
  }
}
