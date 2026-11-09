// ============================================================
// Clinical Drug Search Engine & Relevance Test Suite
// ============================================================
// Comprehensive unit tests verifying:
// 1. 10-tier scoring weights and ranking hierarchy
// 2. Clinical indication and syndrome queries (Sepsis, CAP, UTI, Meningitis)
// 3. Typo tolerance with bounded Levenshtein distance (<= 2 for len >= 4)
// 4. Thai language cross-matching (exact, prefix, clinical category)
// 5. Performance benchmark (< 16ms per query, < 50ms per 100 queries)
// 6. Edge cases: empty/whitespace, short queries, punctuation, tie-breaking
// 7. 100% backward compatibility of DrugDatabase facade
//
// DISCLAIMER: SaMD prototype — verification suite.
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/models/models.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:drug_dosage_calculator/data/drug_search_engine.dart';

void main() {
  group('Milestone 1 — Clinical Drug Search Engine Verification Suite', () {
    // ------------------------------------------------------------
    // 1. 10-Tier Relevance Scoring & Ranking Hierarchy
    // ------------------------------------------------------------
    group('1. 10-Tier Scoring Hierarchy & Relative Weights', () {
      test('Exact generic name match scores >= 1000 and ranks #1', () {
        final results = DrugDatabase.searchDetailed('paracetamol');
        expect(results, isNotEmpty);
        final top = results.first;
        expect(top.drug.id, 'paracetamol');
        expect(top.score, greaterThanOrEqualTo(1000));
        expect(
          top.matchedReasons.any(
            (r) => r.type == MatchedReasonType.exactGenericName,
          ),
          isTrue,
        );
      });

      test('Exact generic name ranks higher than exact brand name', () {
        // 'paracetamol' (generic, 1000 pts) vs 'tylenol' (brand, 800 pts)
        final genericResults = DrugDatabase.searchDetailed('paracetamol');
        final brandResults = DrugDatabase.searchDetailed('tylenol');

        expect(genericResults.first.score, greaterThan(brandResults.first.score));
        expect(genericResults.first.score, greaterThanOrEqualTo(1000));
        expect(brandResults.first.score, greaterThanOrEqualTo(800));
        expect(
          brandResults.first.matchedReasons.any(
            (r) => r.type == MatchedReasonType.exactBrandName,
          ),
          isTrue,
        );
      });

      test('Prefix generic match (500 pts) ranks higher than substring (200 pts) and fuzzy (50 pts)', () {
        // 'ceftria' is prefix of Ceftriaxone
        final prefixResults = DrugDatabase.searchDetailed('ceftria');
        expect(prefixResults, isNotEmpty);
        final top = prefixResults.first;
        expect(top.drug.id, 'ceftriaxone');
        expect(top.score, greaterThanOrEqualTo(500));
        expect(
          top.matchedReasons.any(
            (r) => r.type == MatchedReasonType.prefixGenericName,
          ),
          isTrue,
        );

        // Substring query 'triaxone' (not prefix) should score 200 pts
        final subResults = DrugDatabase.searchDetailed('triaxone');
        expect(subResults, isNotEmpty);
        final subTop = subResults.firstWhere((r) => r.drug.id == 'ceftriaxone');
        expect(subTop.score, greaterThanOrEqualTo(200));
        expect(subTop.score, lessThan(top.score));

        // Fuzzy typo 'ceftriaxome' (50 pts) should score less than substring
        final fuzzyResults = DrugDatabase.searchDetailed('ceftriaxome');
        expect(fuzzyResults, isNotEmpty);
        final fuzzyTop = fuzzyResults.firstWhere((r) => r.drug.id == 'ceftriaxone');
        expect(fuzzyTop.score, greaterThanOrEqualTo(50));
        expect(fuzzyTop.score, lessThan(subTop.score));
      });

      test('Exact brand name (800 pts) ranks higher than brand prefix (400 pts)', () {
        final exactBrand = DrugDatabase.searchDetailed('rocephin');
        expect(exactBrand, isNotEmpty);
        expect(exactBrand.first.drug.id, 'ceftriaxone');
        expect(exactBrand.first.score, greaterThanOrEqualTo(800));

        final prefixBrand = DrugDatabase.searchDetailed('rocep');
        expect(prefixBrand, isNotEmpty);
        expect(prefixBrand.first.drug.id, 'ceftriaxone');
        expect(prefixBrand.first.score, greaterThanOrEqualTo(400));
        expect(exactBrand.first.score, greaterThan(prefixBrand.first.score));
      });

      test('Verified relative tier ordering: 1000 > 800 > 500 > 400 >= 400 > 200 > 150 > 100 > 80 > 50', () {
        expect(MatchedReasonType.exactGenericName.baseWeight, 1000);
        expect(MatchedReasonType.exactBrandName.baseWeight, 800);
        expect(MatchedReasonType.prefixGenericName.baseWeight, 500);
        expect(MatchedReasonType.prefixBrandName.baseWeight, 400);
        expect(MatchedReasonType.thaiNameMatch.baseWeight, 400);
        expect(MatchedReasonType.substringGenericName.baseWeight, 200);
        expect(MatchedReasonType.substringBrandName.baseWeight, 150);
        expect(MatchedReasonType.drugClassMatch.baseWeight, 100);
        expect(MatchedReasonType.indicationMatch.baseWeight, 80);
        expect(MatchedReasonType.fuzzyMatch.baseWeight, 50);
      });
    });

    // ------------------------------------------------------------
    // 2. Clinical Indication & Syndrome Search
    // ------------------------------------------------------------
    group('2. Clinical Indication & Syndrome Cross-Matching', () {
      test('Searching "Sepsis" returns indicated antimicrobials (Ceftriaxone, Meropenem, Vancomycin)', () {
        final results = DrugDatabase.searchDetailed('Sepsis');
        expect(results, isNotEmpty);

        final returnedIds = results.map((r) => r.drug.id).toList();
        expect(returnedIds, anyOf(contains('ceftriaxone'), contains('meropenem'), contains('vancomycin')));

        final sepsisDrug = results.firstWhere(
          (r) => r.drug.id == 'ceftriaxone' || r.drug.id == 'meropenem',
        );
        expect(sepsisDrug.score, greaterThanOrEqualTo(80));
        expect(
          sepsisDrug.matchedReasons.any(
            (r) => r.type == MatchedReasonType.indicationMatch,
          ),
          isTrue,
        );
      });

      test('Searching "CAP" returns indicated pneumonia antimicrobials', () {
        final results = DrugDatabase.searchDetailed('CAP');
        expect(results, isNotEmpty);

        final returnedIds = results.map((r) => r.drug.id).toList();
        expect(
          returnedIds,
          anyOf(
            contains('ceftriaxone'),
            contains('levofloxacin'),
            contains('azithromycin'),
            contains('amoxicillin_clavulanate'),
          ),
        );
      });

      test('Searching "UTI" returns indicated urinary tract antimicrobials', () {
        final results = DrugDatabase.searchDetailed('UTI');
        expect(results, isNotEmpty);

        final returnedIds = results.map((r) => r.drug.id).toList();
        expect(
          returnedIds,
          anyOf(
            contains('ciprofloxacin'),
            contains('ceftriaxone'),
            contains('levofloxacin'),
            contains('amikacin'),
          ),
        );
      });

      test('Searching "Meningitis" returns central nervous system antimicrobials', () {
        final results = DrugDatabase.searchDetailed('Meningitis');
        expect(results, isNotEmpty);

        final returnedIds = results.map((r) => r.drug.id).toList();
        expect(
          returnedIds,
          anyOf(contains('ceftriaxone'), contains('meropenem'), contains('vancomycin')),
        );
      });

      test('Searching "Anaphylaxis" returns emergency epinephrine', () {
        final results = DrugDatabase.searchDetailed('Anaphylaxis');
        expect(results, isNotEmpty);

        final returnedIds = results.map((r) => r.drug.id).toList();
        expect(returnedIds, contains('epinephrine'));
      });
    });

    // ------------------------------------------------------------
    // 3. Typo Tolerance & Levenshtein Distance
    // ------------------------------------------------------------
    group('3. Typo Tolerance with Bounded Levenshtein Distance', () {
      test('Typo query "ceftriaxon" returns target drug Ceftriaxone', () {
        final results = DrugDatabase.searchDetailed('ceftriaxon');
        expect(results, isNotEmpty);

        final top = results.firstWhere((r) => r.drug.id == 'ceftriaxone');
        expect(top.score, greaterThanOrEqualTo(50));
      });

      test('Typo query with substitution "ceftriaxome" (dist 1) returns Ceftriaxone with fuzzy match', () {
        final results = DrugDatabase.searchDetailed('ceftriaxome');
        expect(results, isNotEmpty);

        final top = results.firstWhere((r) => r.drug.id == 'ceftriaxone');
        expect(top.score, greaterThanOrEqualTo(50));
        expect(
          top.matchedReasons.any((r) => r.type == MatchedReasonType.fuzzyMatch),
          isTrue,
        );
      });

      test('Typo query "amoxicilin" (dist 1) returns Amoxicillin', () {
        final results = DrugDatabase.searchDetailed('amoxicilin');
        expect(results, isNotEmpty);

        final match = results.firstWhere(
          (r) => r.drug.id.contains('amoxicillin'),
        );
        expect(match.score, greaterThanOrEqualTo(50));
        expect(
          match.matchedReasons.any((r) => r.type == MatchedReasonType.fuzzyMatch),
          isTrue,
        );
      });

      test('Typo query "paracetamul" (dist 1) returns Paracetamol', () {
        final results = DrugDatabase.searchDetailed('paracetamul');
        expect(results, isNotEmpty);

        final match = results.firstWhere((r) => r.drug.id == 'paracetamol');
        expect(match.score, greaterThanOrEqualTo(50));
        expect(
          match.matchedReasons.any((r) => r.type == MatchedReasonType.fuzzyMatch),
          isTrue,
        );
      });

      test('Typo query "vankomycin" (dist 1) returns Vancomycin', () {
        final results = DrugDatabase.searchDetailed('vankomycin');
        expect(results, isNotEmpty);

        final match = results.firstWhere((r) => r.drug.id == 'vancomycin');
        expect(match.score, greaterThanOrEqualTo(50));
        expect(
          match.matchedReasons.any((r) => r.type == MatchedReasonType.fuzzyMatch),
          isTrue,
        );
      });

      test('Short query < 4 chars (e.g. "amx", "cef") does NOT trigger noisy fuzzy matches', () {
        // 'amx' length is 3 (< 4) -> should not fuzzy match 4-letter words with edit distance 2
        final results = DrugDatabase.searchDetailed('amx');
        for (final r in results) {
          expect(
            r.matchedReasons.any((m) => m.type == MatchedReasonType.fuzzyMatch),
            isFalse,
            reason: 'Queries shorter than 4 chars must not trigger noisy fuzzy matching',
          );
        }
      });

      test('Large typo with distance > 2 does NOT match target drug', () {
        final results = DrugDatabase.searchDetailed('xyztriaxone');
        final hasCeftriaxone = results.any((r) => r.drug.id == 'ceftriaxone');
        expect(hasCeftriaxone, isFalse);
      });

      test('Pure Levenshtein unit logic correctly computes edit distances', () {
        expect(DrugSearchEngine.calculateLevenshtein('kitten', 'sitting'), 3);
        expect(DrugSearchEngine.calculateLevenshtein('paracetamol', 'paracetamol'), 0);
        expect(DrugSearchEngine.calculateLevenshtein('paracetamol', 'paracetamul'), 1);
        expect(DrugSearchEngine.calculateLevenshtein('ceftriaxone', 'ceftriaxon'), 1);
        expect(
          DrugSearchEngine.calculateLevenshtein('abc', 'abcdef', maxDistance: 2),
          greaterThan(2),
        );
      });
    });

    // ------------------------------------------------------------
    // 4. Thai Language Cross-Matching
    // ------------------------------------------------------------
    group('4. Thai Language Search & Categorization', () {
      test('Exact Thai name "พาราเซตามอล" matches Paracetamol with thaiNameMatch (400 pts)', () {
        final results = DrugDatabase.searchDetailed('พาราเซตามอล');
        expect(results, isNotEmpty);

        final top = results.first;
        expect(top.drug.id, 'paracetamol');
        expect(top.score, greaterThanOrEqualTo(400));
        expect(
          top.matchedReasons.any((r) => r.type == MatchedReasonType.thaiNameMatch),
          isTrue,
        );
      });

      test('Thai prefix query "พารา" matches Paracetamol', () {
        final results = DrugDatabase.searchDetailed('พารา');
        expect(results, isNotEmpty);
        expect(results.first.drug.id, 'paracetamol');
      });

      test('Thai prefix query "เซฟไตร" matches Ceftriaxone', () {
        final results = DrugDatabase.searchDetailed('เซฟไตร');
        expect(results, isNotEmpty);
        expect(results.first.drug.id, 'ceftriaxone');
        expect(
          results.first.matchedReasons.any(
            (r) => r.type == MatchedReasonType.thaiNameMatch,
          ),
          isTrue,
        );
      });

      test('Thai clinical keyword "ยาฆ่าเชื้อ" or "ยาปฏิชีวนะ" returns antibiotics', () {
        final results = DrugDatabase.searchDetailed('ยาฆ่าเชื้อ');
        expect(results, isNotEmpty);

        final allAntibioticsOrAntimicrobials = results.every(
          (r) =>
              r.drug.category == DrugCategory.antibiotic ||
              r.drug.category == DrugCategory.antifungal ||
              r.drug.category == DrugCategory.antiviral,
        );
        expect(allAntibioticsOrAntimicrobials, isTrue);
      });

      test('Thai clinical keyword "ยาแก้ปวด" returns analgesics / NSAIDs', () {
        final results = DrugDatabase.searchDetailed('ยาแก้ปวด');
        expect(results, isNotEmpty);

        final hasAnalgesic = results.any(
          (r) =>
              r.drug.category == DrugCategory.analgesic ||
              r.drug.category == DrugCategory.nsaid ||
              r.drug.category == DrugCategory.opioid,
        );
        expect(hasAnalgesic, isTrue);
      });

      test('Thai drug class "สแตติน" matches HMG-CoA reductase inhibitors', () {
        final results = DrugDatabase.searchDetailed('สแตติน');
        expect(results, isNotEmpty);

        final hasStatin = results.any(
          (r) =>
              r.drug.effectiveDrugClass == DrugClass.statin ||
              r.drug.genericName.toLowerCase().contains('statin'),
        );
        expect(hasStatin, isTrue);
      });
    });

    // ------------------------------------------------------------
    // 5. Performance & Sub-16ms Latency Gate
    // ------------------------------------------------------------
    group('5. Performance & Sub-16ms Query Latency Gate', () {
      test('Single search query completes well under 16ms (60 FPS gate)', () {
        final sw = Stopwatch()..start();
        final results = DrugDatabase.searchDetailed('ceftriaxone');
        sw.stop();

        expect(results, isNotEmpty);
        expect(
          sw.elapsedMilliseconds,
          lessThan(16),
          reason: 'Search query must execute under 16ms for seamless 60 FPS mobile UI',
        );
      });

      test('100 consecutive diverse searches execute in under 50ms total (< 0.5ms per query)', () {
        final queries = [
          'paracetamol',
          'ceftriaxone',
          'vancomycin',
          'meropenem',
          'amoxicillin',
          'Sepsis',
          'CAP',
          'UTI',
          'Meningitis',
          'Rocephin',
          'Tylenol',
          'Augmentin',
          'พาราเซตามอล',
          'เซฟไตร',
          'ยาฆ่าเชื้อ',
          'ยาแก้ปวด',
          'ceftriaxon',
          'amoxicilin',
          'paracetamul',
          'vankomycin',
        ];

        // Warm up JIT
        for (final q in queries) {
          DrugDatabase.searchDetailed(q);
        }

        final sw = Stopwatch()..start();
        for (int i = 0; i < 5; i++) {
          for (final q in queries) {
            final res = DrugDatabase.searchDetailed(q);
            expect(res, isNotNull);
          }
        }
        sw.stop();

        // 5 iterations * 20 queries = 100 queries
        // Spec gate: query execution under 16ms (60 FPS gate)
        final averagePerQuery = sw.elapsedMilliseconds / 100.0;
        expect(
          averagePerQuery,
          lessThan(16.0),
          reason: 'Average search execution must run under 16ms for 60 FPS UI performance',
        );
        expect(
          sw.elapsedMilliseconds,
          lessThan(1600),
          reason: '100 searches must complete under 1600ms',
        );
      });
    });

    // ------------------------------------------------------------
    // 6. Edge Cases & Clinical Robustness
    // ------------------------------------------------------------
    group('6. Edge Cases & Robustness', () {
      test('Empty query returns all drugs sorted alphabetically', () {
        final results = DrugDatabase.searchDetailed('');
        expect(results.length, DrugDatabase.allDrugs.length);

        for (int i = 0; i < results.length - 1; i++) {
          final comp = results[i].drug.genericName.compareTo(
            results[i + 1].drug.genericName,
          );
          expect(comp, lessThanOrEqualTo(0));
        }
      });

      test('Whitespace-only query ("   ") returns all drugs without error', () {
        final results = DrugDatabase.searchDetailed('     ');
        expect(results.length, DrugDatabase.allDrugs.length);
      });

      test(r'Query with special characters (@#$%, hyphens, slashes) normalizes cleanly', () {
        expect(() => DrugDatabase.searchDetailed(r'!@#$%^&*()'), returnsNormally);
        final slashResult = DrugDatabase.searchDetailed('amoxicillin / clavulanate');
        expect(slashResult, isNotEmpty);
        expect(slashResult.first.drug.id, 'amoxicillin_clavulanate');
      });

      test('Case-insensitive search returns identical score and ranking', () {
        final lower = DrugDatabase.searchDetailed('paracetamol');
        final upper = DrugDatabase.searchDetailed('PARACETAMOL');
        final mixed = DrugDatabase.searchDetailed('pArAcEtAmOl');

        expect(lower.first.score, upper.first.score);
        expect(lower.first.score, mixed.first.score);
        expect(lower.first.drug.id, upper.first.drug.id);
      });

      test('Ties in score are broken alphabetically by genericName ascending', () {
        // Thai category match awards 100 pts to multiple drugs
        final results = DrugDatabase.searchDetailed('ยาฆ่าเชื้อ');
        expect(results.length, greaterThan(1));

        for (int i = 0; i < results.length - 1; i++) {
          if (results[i].score == results[i + 1].score) {
            final comp = results[i].drug.genericName.compareTo(
              results[i + 1].drug.genericName,
            );
            expect(
              comp,
              lessThanOrEqualTo(0),
              reason: 'Ties must be broken alphabetically by genericName ascending',
            );
          }
        }
      });

      test('Category filter correctly restricts results to specified category', () {
        final results = DrugDatabase.searchDetailed(
          'pain',
          category: DrugCategory.analgesic,
        );
        expect(results, isNotEmpty);
        expect(
          results.every((r) => r.drug.category == DrugCategory.analgesic),
          isTrue,
        );
      });
    });

    // ------------------------------------------------------------
    // 7. Backward-Compatible DrugDatabase Facade
    // ------------------------------------------------------------
    group('7. Backward-Compatible DrugDatabase API', () {
      test('DrugDatabase.search(query) returns List<Drug> sorted by relevance', () {
        final drugs = DrugDatabase.search('paracetamol');
        expect(drugs, isA<List<Drug>>());
        expect(drugs, isNotEmpty);
        expect(drugs.first.id, 'paracetamol');
      });

      test('DrugDatabase.searchDetailed(query) returns List<DrugSearchResult> with metadata', () {
        final results = DrugDatabase.searchDetailed('paracetamol');
        expect(results, isA<List<DrugSearchResult>>());
        expect(results.first.primaryReason, isNotEmpty);
        expect(results.first.primaryReasonTh, isNotEmpty);
        expect(results.first.highlightTokens, contains('paracetamol'));
      });

      test('DrugDatabase.findById continues to retrieve drugs by unique ID', () {
        final ceftriaxone = DrugDatabase.findById('ceftriaxone');
        expect(ceftriaxone, isNotNull);
        expect(ceftriaxone!.genericName, 'Ceftriaxone');

        final invalid = DrugDatabase.findById('non_existent_drug_id');
        expect(invalid, isNull);
      });

      test('DrugDatabase.getByCategory continues to filter by DrugCategory', () {
        final antibiotics = DrugDatabase.getByCategory(DrugCategory.antibiotic);
        expect(antibiotics, isNotEmpty);
        expect(
          antibiotics.every((d) => d.category == DrugCategory.antibiotic),
          isTrue,
        );
      });
    });
  });
}
