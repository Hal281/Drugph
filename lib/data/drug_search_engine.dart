// ============================================================
// Drug Dosage Calculator — Clinical Drug Search Engine
// ============================================================
// High-performance multi-dimensional relevance search engine
// for clinical medications.
//
// Features:
// - 10-tier clinical relevance scoring model
// - Pure deterministic evaluation with pre-computed in-memory index
// - Sub-16ms query execution (typically < 1ms on ~120 drugs)
// - Thai & English cross-matching and clinical synonym resolution
// - Bounded Levenshtein distance typo tolerance (<= 2 for len >= 4)
// - Matched reasons and query highlight tokens
//
// DISCLAIMER: SaMD prototype — for educational & clinical assistance.
// ============================================================

import '../core/models/models.dart';


/// Categories of matched dimensions with their base score weights.
enum MatchedReasonType {
  /// Exact INN generic name match (1,000 pts).
  exactGenericName(1000, 'Exact generic name match', 'ชื่อสามัญตรงกันทุกตัวอักษร'),

  /// Exact trade/brand name match (800 pts).
  exactBrandName(800, 'Exact brand name match', 'ชื่อการค้าตรงกันทุกตัวอักษร'),

  /// Generic name starts with query (500 pts).
  prefixGenericName(500, 'Generic name prefix match', 'ขึ้นต้นด้วยชื่อสามัญ'),

  /// Brand name starts with query (400 pts).
  prefixBrandName(400, 'Brand name prefix match', 'ขึ้นต้นด้วยชื่อการค้า'),

  /// Thai phonetic name exact or prefix match (400 pts).
  thaiNameMatch(400, 'Thai name match', 'ตรงกับชื่อภาษาไทย'),

  /// Generic name contains query as substring (200 pts).
  substringGenericName(200, 'Generic name substring match', 'มีคำนี้อยู่ในชื่อสามัญ'),

  /// Brand name contains query as substring (150 pts).
  substringBrandName(150, 'Brand name substring match', 'มีคำนี้อยู่ในชื่อการค้า'),

  /// Pharmacological drug class or therapeutic category match (100 pts).
  drugClassMatch(100, 'Drug class / category match', 'ตรงกับกลุ่มยาหรือประเภทการรักษา'),

  /// Clinical syndrome or regimen indication match (80 pts).
  indicationMatch(80, 'Indication / clinical keyword match', 'ตรงกับข้อบ่งใช้ทางคลินิก'),

  /// Typo tolerance / Levenshtein edit distance <= 2 for query length >= 4 (50 pts).
  fuzzyMatch(50, 'Fuzzy / typo match', 'คำใกล้เคียง (พิมพ์ผิด/คลาดเคลื่อนเล็กน้อย)');

  final int baseWeight;
  final String defaultDescriptionEn;
  final String defaultDescriptionTh;

  const MatchedReasonType(
    this.baseWeight,
    this.defaultDescriptionEn,
    this.defaultDescriptionTh,
  );
}

/// Structured explanation of why a drug matched the search query.
class MatchedReason {
  final MatchedReasonType type;
  final String descriptionEn;
  final String descriptionTh;
  final String? matchedValue;
  final int score;

  const MatchedReason({
    required this.type,
    required this.descriptionEn,
    required this.descriptionTh,
    this.matchedValue,
    required this.score,
  });

  @override
  String toString() => '$type($score pts, val: "$matchedValue")';
}

/// Exact character indices to highlight matching substrings in UI.
class TextMatchHighlight {
  final String fieldName;
  final int startIndex;
  final int endIndex;

  const TextMatchHighlight({
    required this.fieldName,
    required this.startIndex,
    required this.endIndex,
  });

  @override
  String toString() => '$fieldName[$startIndex:$endIndex]';
}

/// Search result encapsulating the matched drug, relevance score,
/// diagnostic reasons, and UI highlight tokens.
class DrugSearchResult {
  final Drug drug;
  final int score;
  final List<MatchedReason> matchedReasons;
  final List<String> highlightTokens;
  final List<TextMatchHighlight> highlights;

  const DrugSearchResult({
    required this.drug,
    required this.score,
    required this.matchedReasons,
    required this.highlightTokens,
    this.highlights = const [],
  });

  /// Primary English reason for matching.
  String get primaryReason =>
      matchedReasons.isNotEmpty ? matchedReasons.first.descriptionEn : '';

  /// Primary Thai reason for matching.
  String get primaryReasonTh =>
      matchedReasons.isNotEmpty ? matchedReasons.first.descriptionTh : '';

  @override
  String toString() =>
      'DrugSearchResult(${drug.genericName}, score: $score, reasons: ${matchedReasons.length})';
}

/// Pre-indexed metadata for a single drug to enable sub-millisecond evaluation.
class _IndexedDrug {
  final Drug drug;
  final String normalizedGeneric;
  final String primaryGeneric;
  final List<String> genericTokens;
  final List<String> normalizedBrands;
  final List<String> brandTokens;
  final String? normalizedThai;
  final String categoryNameEn;
  final String categoryNameTh;
  final String? drugClassNameEn;
  final String? drugClassNameTh;
  final List<String> normalizedIndications;
  final List<String> indicationTokens;
  final List<String> tags;

  _IndexedDrug({
    required this.drug,
    required this.normalizedGeneric,
    required this.primaryGeneric,
    required this.genericTokens,
    required this.normalizedBrands,
    required this.brandTokens,
    required this.normalizedThai,
    required this.categoryNameEn,
    required this.categoryNameTh,
    required this.drugClassNameEn,
    required this.drugClassNameTh,
    required this.normalizedIndications,
    required this.indicationTokens,
    required this.tags,
  });

  factory _IndexedDrug.fromDrug(Drug drug) {
    final normGen = DrugSearchEngine.normalize(drug.genericName);

    // Primary generic name before parenthetical aliases or combination slashes
    final parenIdx = drug.genericName.indexOf('(');
    final slashIdx = drug.genericName.indexOf('/');
    int splitIdx = -1;
    if (parenIdx != -1 && slashIdx != -1) {
      splitIdx = parenIdx < slashIdx ? parenIdx : slashIdx;
    } else if (parenIdx != -1) {
      splitIdx = parenIdx;
    } else if (slashIdx != -1) {
      splitIdx = slashIdx;
    }

    final rawPrimary = splitIdx != -1
        ? drug.genericName.substring(0, splitIdx)
        : drug.genericName;
    final primaryGen = DrugSearchEngine.normalize(rawPrimary);

    // Extract individual word tokens from generic name
    final genTokens = drug.genericName
        .split(DrugSearchEngine._tokenSplitRegex)
        .map(DrugSearchEngine.normalize)
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();

    // Normalized brands and brand word tokens
    final normBrands = drug.brandNames
        .map(DrugSearchEngine.normalize)
        .where((b) => b.isNotEmpty)
        .toList();

    final bTokens = <String>{};
    for (final b in drug.brandNames) {
      final tokens = b
          .split(DrugSearchEngine._tokenSplitRegex)
          .map(DrugSearchEngine.normalize)
          .where((t) => t.isNotEmpty);
      bTokens.addAll(tokens);
    }

    // Normalized Thai name
    final normThai = drug.nameTh != null && drug.nameTh!.trim().isNotEmpty
        ? DrugSearchEngine.normalize(drug.nameTh!)
        : null;

    // Drug category and pharmacological class
    final catEn = DrugSearchEngine.normalize(drug.category.nameEn);
    final catTh = DrugSearchEngine.normalize(drug.category.nameTh);

    final effClass = drug.effectiveDrugClass;
    final classEn = effClass != null
        ? DrugSearchEngine.normalize(effClass.nameEn)
        : null;
    final classTh = effClass != null
        ? DrugSearchEngine.normalize(effClass.nameTh)
        : null;

    // Indications from regimens, monograph, and tags
    final rawInds = <String>{};
    for (final r in drug.regimens) {
      if (r.indication != null && r.indication!.trim().isNotEmpty) {
        rawInds.add(r.indication!);
      }
    }
    if (drug.monograph != null && drug.monograph!.dosingGuideline.isNotEmpty) {
      // Extract brief clinical keyword lines
      final lines = drug.monograph!.dosingGuideline.split('\n');
      for (final l in lines) {
        if (l.contains(':')) {
          rawInds.add(l.split(':').first.replaceAll('•', '').trim());
        }
      }
    }

    final normInds = rawInds
        .map(DrugSearchEngine.normalize)
        .where((i) => i.isNotEmpty)
        .toList();

    final indTokens = <String>{};
    for (final ind in rawInds) {
      final tokens = ind
          .split(DrugSearchEngine._indicationSplitRegex)
          .map(DrugSearchEngine.normalize)
          .where((t) => t.isNotEmpty);
      indTokens.addAll(tokens);
    }

    final normTags = drug.tags
        .map(DrugSearchEngine.normalize)
        .where((t) => t.isNotEmpty)
        .toList();

    return _IndexedDrug(
      drug: drug,
      normalizedGeneric: normGen,
      primaryGeneric: primaryGen,
      genericTokens: genTokens,
      normalizedBrands: normBrands,
      brandTokens: bTokens.toList(),
      normalizedThai: normThai,
      categoryNameEn: catEn,
      categoryNameTh: catTh,
      drugClassNameEn: classEn,
      drugClassNameTh: classTh,
      normalizedIndications: normInds,
      indicationTokens: indTokens.toList(),
      tags: normTags,
    );
  }
}

/// Pre-computed in-memory search index for instantaneous clinical retrieval.
class DrugSearchIndex {
  final List<_IndexedDrug> _indexedDrugs;

  const DrugSearchIndex._(this._indexedDrugs);

  /// Builds a compiled index from a list of drugs.
  factory DrugSearchIndex.fromDrugs(List<Drug> drugs) {
    final indexed = drugs.map((d) => _IndexedDrug.fromDrug(d)).toList();
    return DrugSearchIndex._(indexed);
  }

  /// Number of drugs indexed.
  int get length => _indexedDrugs.length;

  /// Pure deterministic search over the compiled index.
  List<DrugSearchResult> search(
    String query, {
    DrugCategory? categoryFilter,
    int? limit,
  }) {
    final trimmed = query.trim();
    final cleanQuery = DrugSearchEngine.normalize(trimmed);

    // Empty query returns all drugs with default zero score, sorted alphabetically
    if (cleanQuery.isEmpty) {
      var candidates = _indexedDrugs;
      if (categoryFilter != null) {
        candidates =
            candidates.where((i) => i.drug.category == categoryFilter).toList();
      }
      final results = candidates.map((i) {
        return DrugSearchResult(
          drug: i.drug,
          score: 0,
          matchedReasons: const [],
          highlightTokens: const [],
        );
      }).toList();

      results.sort((a, b) => a.drug.genericName.compareTo(b.drug.genericName));
      if (limit != null && limit > 0 && results.length > limit) {
        return results.sublist(0, limit);
      }
      return results;
    }

    final List<DrugSearchResult> matchedResults = [];

    // Check if query matches predefined clinical synonyms or Thai category keywords
    final synonymDrugIds = DrugSearchEngine.resolveClinicalSynonym(cleanQuery);
    final synonymCategories = DrugSearchEngine.resolveThaiCategory(cleanQuery);
    final synonymClasses = DrugSearchEngine.resolveThaiDrugClass(cleanQuery);

    for (final item in _indexedDrugs) {
      if (categoryFilter != null && item.drug.category != categoryFilter) {
        continue;
      }

      int score = 0;
      final List<MatchedReason> reasons = [];
      final List<TextMatchHighlight> highlights = [];

      bool genericExactOrPrefix = false;
      bool brandExactOrPrefix = false;

      // ----------------------------------------------------
      // Tier 1: Exact Generic Name Match (1,000 pts)
      // ----------------------------------------------------
      if (cleanQuery == item.normalizedGeneric ||
          cleanQuery == item.primaryGeneric ||
          item.genericTokens.contains(cleanQuery)) {
        score += MatchedReasonType.exactGenericName.baseWeight;
        genericExactOrPrefix = true;
        reasons.add(MatchedReason(
          type: MatchedReasonType.exactGenericName,
          descriptionEn: 'Exact generic name match',
          descriptionTh: 'ชื่อสามัญตรงกันทุกตัวอักษร',
          matchedValue: item.drug.genericName,
          score: MatchedReasonType.exactGenericName.baseWeight,
        ));
        highlights.add(TextMatchHighlight(
          fieldName: 'genericName',
          startIndex: 0,
          endIndex: item.drug.genericName.length,
        ));
      }

      // ----------------------------------------------------
      // Tier 2: Exact Brand Name Match (800 pts)
      // ----------------------------------------------------
      String? matchedBrandExact;
      for (int i = 0; i < item.normalizedBrands.length; i++) {
        if (cleanQuery == item.normalizedBrands[i] ||
            item.brandTokens.contains(cleanQuery)) {
          matchedBrandExact = item.drug.brandNames[i];
          break;
        }
      }
      if (matchedBrandExact != null) {
        score += MatchedReasonType.exactBrandName.baseWeight;
        brandExactOrPrefix = true;
        reasons.add(MatchedReason(
          type: MatchedReasonType.exactBrandName,
          descriptionEn: 'Exact brand name match',
          descriptionTh: 'ชื่อการค้าตรงกันทุกตัวอักษร',
          matchedValue: matchedBrandExact,
          score: MatchedReasonType.exactBrandName.baseWeight,
        ));
        highlights.add(TextMatchHighlight(
          fieldName: 'brandNames',
          startIndex: 0,
          endIndex: matchedBrandExact.length,
        ));
      }

      // ----------------------------------------------------
      // Tier 3: Generic Name Prefix Match (500 pts)
      // ----------------------------------------------------
      if (!genericExactOrPrefix &&
          (item.normalizedGeneric.startsWith(cleanQuery) ||
              item.primaryGeneric.startsWith(cleanQuery) ||
              item.genericTokens.any((t) => t.startsWith(cleanQuery)))) {
        score += MatchedReasonType.prefixGenericName.baseWeight;
        genericExactOrPrefix = true;
        reasons.add(MatchedReason(
          type: MatchedReasonType.prefixGenericName,
          descriptionEn: 'Generic name prefix match',
          descriptionTh: 'ขึ้นต้นด้วยชื่อสามัญ',
          matchedValue: item.drug.genericName,
          score: MatchedReasonType.prefixGenericName.baseWeight,
        ));
        highlights.add(TextMatchHighlight(
          fieldName: 'genericName',
          startIndex: 0,
          endIndex: cleanQuery.length <= item.drug.genericName.length
              ? cleanQuery.length
              : item.drug.genericName.length,
        ));
      }

      // ----------------------------------------------------
      // Tier 4: Brand Name Prefix Match (400 pts)
      // ----------------------------------------------------
      if (!brandExactOrPrefix) {
        String? prefixBrand;
        for (int i = 0; i < item.normalizedBrands.length; i++) {
          if (item.normalizedBrands[i].startsWith(cleanQuery)) {
            prefixBrand = item.drug.brandNames[i];
            break;
          }
        }
        if (prefixBrand != null) {
          score += MatchedReasonType.prefixBrandName.baseWeight;
          brandExactOrPrefix = true;
          reasons.add(MatchedReason(
            type: MatchedReasonType.prefixBrandName,
            descriptionEn: 'Brand name prefix match',
            descriptionTh: 'ขึ้นต้นด้วยชื่อการค้า',
            matchedValue: prefixBrand,
            score: MatchedReasonType.prefixBrandName.baseWeight,
          ));
        }
      }

      // ----------------------------------------------------
      // Tier 5: Thai Name Match (Exact or Prefix or Substring) (400 pts)
      // ----------------------------------------------------
      if (item.normalizedThai != null &&
          (item.normalizedThai!.startsWith(cleanQuery) ||
              item.normalizedThai! == cleanQuery ||
              item.normalizedThai!.contains(cleanQuery))) {
        score += MatchedReasonType.thaiNameMatch.baseWeight;
        reasons.add(MatchedReason(
          type: MatchedReasonType.thaiNameMatch,
          descriptionEn: 'Thai name match',
          descriptionTh: 'ตรงกับชื่อภาษาไทย',
          matchedValue: item.drug.nameTh,
          score: MatchedReasonType.thaiNameMatch.baseWeight,
        ));
      }

      // ----------------------------------------------------
      // Tier 6: Substring in Generic Name (200 pts)
      // ----------------------------------------------------
      if (!genericExactOrPrefix && item.normalizedGeneric.contains(cleanQuery)) {
        score += MatchedReasonType.substringGenericName.baseWeight;
        reasons.add(MatchedReason(
          type: MatchedReasonType.substringGenericName,
          descriptionEn: 'Generic name substring match',
          descriptionTh: 'มีคำนี้อยู่ในชื่อสามัญ',
          matchedValue: item.drug.genericName,
          score: MatchedReasonType.substringGenericName.baseWeight,
        ));
      }

      // ----------------------------------------------------
      // Tier 7: Substring in Brand Name (150 pts)
      // ----------------------------------------------------
      if (!brandExactOrPrefix) {
        String? subBrand;
        for (int i = 0; i < item.normalizedBrands.length; i++) {
          if (item.normalizedBrands[i].contains(cleanQuery)) {
            subBrand = item.drug.brandNames[i];
            break;
          }
        }
        if (subBrand != null) {
          score += MatchedReasonType.substringBrandName.baseWeight;
          reasons.add(MatchedReason(
            type: MatchedReasonType.substringBrandName,
            descriptionEn: 'Brand name substring match',
            descriptionTh: 'มีคำนี้อยู่ในชื่อการค้า',
            matchedValue: subBrand,
            score: MatchedReasonType.substringBrandName.baseWeight,
          ));
        }
      }

      // ----------------------------------------------------
      // Tier 8: Drug Class / Category Match (100 pts)
      // ----------------------------------------------------
      bool isClassMatched = false;
      String? classMatchLabel;

      if (cleanQuery.length >= 3) {
        if (item.categoryNameEn.contains(cleanQuery) ||
            item.categoryNameTh.contains(cleanQuery)) {
          isClassMatched = true;
          classMatchLabel = item.drug.category.nameEn;
        } else if (item.drugClassNameEn != null &&
            item.drugClassNameEn!.contains(cleanQuery)) {
          isClassMatched = true;
          classMatchLabel = item.drug.effectiveDrugClass?.nameEn;
        } else if (item.drugClassNameTh != null &&
            item.drugClassNameTh!.contains(cleanQuery)) {
          isClassMatched = true;
          classMatchLabel = item.drug.effectiveDrugClass?.nameTh;
        }
      }

      // Check Thai synonyms
      if (!isClassMatched && synonymCategories.isNotEmpty) {
        if (synonymCategories.contains(item.drug.category)) {
          isClassMatched = true;
          classMatchLabel = item.drug.category.nameTh;
        }
      }
      if (!isClassMatched && synonymClasses.isNotEmpty) {
        final eff = item.drug.effectiveDrugClass;
        if (eff != null && synonymClasses.contains(eff)) {
          isClassMatched = true;
          classMatchLabel = eff.nameTh;
        }
      }

      if (isClassMatched) {
        score += MatchedReasonType.drugClassMatch.baseWeight;
        reasons.add(MatchedReason(
          type: MatchedReasonType.drugClassMatch,
          descriptionEn: 'Drug class / category match',
          descriptionTh: 'ตรงกับกลุ่มยาหรือประเภทการรักษา',
          matchedValue: classMatchLabel,
          score: MatchedReasonType.drugClassMatch.baseWeight,
        ));
      }

      // ----------------------------------------------------
      // Tier 9: Indication / Clinical Keyword Match (80 pts)
      // ----------------------------------------------------
      bool isIndicationMatched = false;
      String? matchedIndicationText;

      if (cleanQuery.length >= 2) {
        for (int i = 0; i < item.normalizedIndications.length; i++) {
          if (item.normalizedIndications[i].contains(cleanQuery)) {
            isIndicationMatched = true;
            matchedIndicationText = item.drug.regimens
                .map((r) => r.indication)
                .firstWhere(
                  (ind) =>
                      ind != null &&
                      DrugSearchEngine.normalize(ind) ==
                          item.normalizedIndications[i],
                  orElse: () => item.normalizedIndications[i],
                );
            break;
          }
        }

        if (!isIndicationMatched) {
          for (final tok in item.indicationTokens) {
            if (tok.contains(cleanQuery)) {
              isIndicationMatched = true;
              matchedIndicationText = tok;
              break;
            }
          }
        }

        if (!isIndicationMatched && item.tags.any((t) => t.contains(cleanQuery))) {
          isIndicationMatched = true;
          matchedIndicationText = item.tags.firstWhere((t) => t.contains(cleanQuery));
        }
      }

      // Check clinical synonym mapping (e.g. Sepsis -> Ceftriaxone)
      if (!isIndicationMatched && synonymDrugIds.isNotEmpty) {
        if (synonymDrugIds.contains(item.drug.id) ||
            synonymDrugIds.any((id) => item.drug.id.contains(id))) {
          isIndicationMatched = true;
          matchedIndicationText = trimmed;
        }
      }

      if (isIndicationMatched) {
        score += MatchedReasonType.indicationMatch.baseWeight;
        reasons.add(MatchedReason(
          type: MatchedReasonType.indicationMatch,
          descriptionEn: 'Matched clinical indication ($matchedIndicationText)',
          descriptionTh: 'ตรงกับข้อบ่งใช้: $matchedIndicationText',
          matchedValue: matchedIndicationText,
          score: MatchedReasonType.indicationMatch.baseWeight,
        ));
      }

      // ----------------------------------------------------
      // Tier 10: Fuzzy / Typo Match (Levenshtein dist <= 2, len >= 4) (50 pts)
      // ----------------------------------------------------
      if (!genericExactOrPrefix &&
          !brandExactOrPrefix &&
          cleanQuery.length >= 4) {
        int bestDist = 999;
        String? bestTarget;

        // Compare against primary generic name
        final primLen = item.primaryGeneric.length;
        if ((cleanQuery.length - primLen).abs() <= 2) {
          final distPrimary = DrugSearchEngine.calculateLevenshtein(
            cleanQuery,
            item.primaryGeneric,
            maxDistance: 2,
          );
          if (distPrimary <= 2 && distPrimary < bestDist) {
            bestDist = distPrimary;
            bestTarget = item.drug.genericName;
          }
        }

        // Compare against individual generic tokens
        if (bestDist > 1) {
          for (final tok in item.genericTokens) {
            if (tok.length >= 4 && (cleanQuery.length - tok.length).abs() <= 2) {
              final dist = DrugSearchEngine.calculateLevenshtein(
                cleanQuery,
                tok,
                maxDistance: 2,
              );
              if (dist <= 2 && dist < bestDist) {
                bestDist = dist;
                bestTarget = tok;
                if (bestDist <= 1) break;
              }
            }
          }
        }

        // Compare against brand names
        if (bestDist > 1) {
          for (int bIdx = 0; bIdx < item.normalizedBrands.length; bIdx++) {
            final bNorm = item.normalizedBrands[bIdx];
            if (bNorm.length >= 4 &&
                (cleanQuery.length - bNorm.length).abs() <= 2) {
              final dist = DrugSearchEngine.calculateLevenshtein(
                cleanQuery,
                bNorm,
                maxDistance: 2,
              );
              if (dist <= 2 && dist < bestDist) {
                bestDist = dist;
                bestTarget = item.drug.brandNames[bIdx];
                if (bestDist <= 1) break;
              }
            }
          }
        }

        if (bestDist <= 2 && bestTarget != null) {
          score += MatchedReasonType.fuzzyMatch.baseWeight;
          reasons.add(MatchedReason(
            type: MatchedReasonType.fuzzyMatch,
            descriptionEn: 'Fuzzy match (distance: $bestDist)',
            descriptionTh: 'คำใกล้เคียง (ต่าง $bestDist ตัวอักษร)',
            matchedValue: bestTarget,
            score: MatchedReasonType.fuzzyMatch.baseWeight,
          ));
        }
      }

      // If at least one matching tier fired, record result
      if (score > 0) {
        matchedResults.add(DrugSearchResult(
          drug: item.drug,
          score: score,
          matchedReasons: reasons,
          highlightTokens: [trimmed],
          highlights: highlights,
        ));
      }
    }

    // Tie-breaking specification:
    // 1. Relevance score descending
    // 2. genericName ascending (alphabetical)
    matchedResults.sort((a, b) {
      final scoreComp = b.score.compareTo(a.score);
      if (scoreComp != 0) return scoreComp;
      return a.drug.genericName.compareTo(b.drug.genericName);
    });

    if (limit != null && limit > 0 && matchedResults.length > limit) {
      return matchedResults.sublist(0, limit);
    }

    return matchedResults;
  }
}

/// Clinical drug search engine providing pure, deterministic relevance evaluation.
class DrugSearchEngine {
  final DrugSearchIndex _index;

  DrugSearchEngine(List<Drug> dataset)
      : _index = DrugSearchIndex.fromDrugs(dataset);

  DrugSearchEngine.withIndex(this._index);

  /// Performs a multi-dimensional relevance search over the indexed drug dataset.
  List<DrugSearchResult> search(
    String query, {
    DrugCategory? categoryFilter,
    int? limit,
  }) {
    return _index.search(query, categoryFilter: categoryFilter, limit: limit);
  }

  static final RegExp _punctRegex = RegExp(r'[\s\-_/.,!?;:\(\)\[\]]');
  static final RegExp _tokenSplitRegex = RegExp(r'[\s\-_/(),]');
  static final RegExp _indicationSplitRegex = RegExp(r'[\s\-_/(),:•]');

  /// Pre-warms the search index and JIT compiler caches.
  void warmUp() {
    search('ceftriaxone');
    search('paracetamol');
  }

  /// Normalizes a query or text string by lowercasing and stripping punctuation.
  static String normalize(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll(_punctRegex, '');
  }

  static final List<int> _scratchPrev = List<int>.filled(128, 0);
  static final List<int> _scratchCurr = List<int>.filled(128, 0);

  /// Calculates bounded Levenshtein edit distance with early exit threshold.
  ///
  /// Guarantees O(1) heap allocation and sub-microsecond evaluation for short queries.
  static int calculateLevenshtein(
    String a,
    String b, {
    int maxDistance = 2,
  }) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    if ((a.length - b.length).abs() > maxDistance) return maxDistance + 1;

    // Ensure 'a' is shorter to minimize row buffer allocations
    if (a.length > b.length) {
      final temp = a;
      a = b;
      b = temp;
    }

    final aLen = a.length;
    final bLen = b.length;

    List<int> prev;
    List<int> curr;

    if (aLen < 128) {
      prev = _scratchPrev;
      curr = _scratchCurr;
      for (int i = 0; i <= aLen; i++) {
        prev[i] = i;
      }
    } else {
      prev = List<int>.generate(aLen + 1, (i) => i);
      curr = List<int>.filled(aLen + 1, 0);
    }

    for (int j = 1; j <= bLen; j++) {
      curr[0] = j;
      int minInRow = j;
      final bCode = b.codeUnitAt(j - 1);

      for (int i = 1; i <= aLen; i++) {
        final aCode = a.codeUnitAt(i - 1);
        final cost = (aCode == bCode) ? 0 : 1;
        final insertion = curr[i - 1] + 1;
        final deletion = prev[i] + 1;
        final substitution = prev[i - 1] + cost;

        int minVal = insertion < deletion ? insertion : deletion;
        if (substitution < minVal) minVal = substitution;
        curr[i] = minVal;
        if (minVal < minInRow) minInRow = minVal;
      }

      if (minInRow > maxDistance) {
        return maxDistance + 1;
      }

      final temp = prev;
      prev = curr;
      curr = temp;
    }

    return prev[aLen];
  }

  /// Clinical indication & syndrome synonym map resolving clinical terms
  /// to drug IDs.
  static final Map<String, List<String>> _clinicalIndicationSynonyms = {
    'sepsis': [
      'ceftriaxone',
      'meropenem',
      'vancomycin',
      'piperacillin_tazobactam',
      'norepinephrine',
      'cefazolin',
      'cefotaxime',
    ],
    'septicshock': [
      'norepinephrine',
      'epinephrine',
      'dopamine',
      'hydrocortisone',
      'meropenem',
      'vasopressin',
    ],
    'cap': [
      'ceftriaxone',
      'azithromycin',
      'levofloxacin',
      'amoxicillin_clavulanate',
      'clarithromycin',
      'cefotaxime',
    ],
    'pneumonia': [
      'ceftriaxone',
      'azithromycin',
      'levofloxacin',
      'amoxicillin_clavulanate',
      'piperacillin_tazobactam',
      'meropenem',
      'cefotaxime',
    ],
    'meningitis': [
      'ceftriaxone',
      'meropenem',
      'ampicillin',
      'vancomycin',
      'dexamethasone',
      'cefotaxime',
    ],
    'uti': [
      'ciprofloxacin',
      'ceftriaxone',
      'levofloxacin',
      'amoxicillin_clavulanate',
      'fosfomycin',
      'cotrimoxazole',
      'nitrofurantoin',
      'amikacin',
      'gentamicin',
    ],
    'anaphylaxis': [
      'epinephrine',
      'chlorpheniramine',
      'hydrocortisone',
      'diphenhydramine',
    ],
    'shock': [
      'norepinephrine',
      'epinephrine',
      'dopamine',
      'dobutamine',
    ],
    'hypertension': [
      'amlodipine',
      'losartan',
      'enalapril',
      'hydralazine',
      'nicardipine',
    ],
    'pain': [
      'paracetamol',
      'ibuprofen',
      'tramadol',
      'morphine',
      'fentanyl',
    ],
  };

  /// Resolves normalized clinical keywords to associated target drug IDs.
  static List<String> resolveClinicalSynonym(String normalizedQuery) {
    if (_clinicalIndicationSynonyms.containsKey(normalizedQuery)) {
      return _clinicalIndicationSynonyms[normalizedQuery]!;
    }
    // Check partial key matches
    for (final entry in _clinicalIndicationSynonyms.entries) {
      if (entry.key.contains(normalizedQuery) ||
          normalizedQuery.contains(entry.key)) {
        return entry.value;
      }
    }
    return const [];
  }

  /// Thai clinical keyword map to therapeutic drug categories.
  static final Map<String, List<DrugCategory>> _thaiCategoryMap = {
    'ยาฆ่าเชื้อ': [
      DrugCategory.antibiotic,
      DrugCategory.antifungal,
      DrugCategory.antiviral,
    ],
    'ยาปฏิชีวนะ': [
      DrugCategory.antibiotic,
    ],
    'ยาแก้ปวด': [
      DrugCategory.analgesic,
      DrugCategory.nsaid,
      DrugCategory.opioid,
    ],
    'ยาต้านอักเสบ': [
      DrugCategory.nsaid,
      DrugCategory.antiInflammatory,
      DrugCategory.corticosteroid,
    ],
    'ยาลดความดัน': [
      DrugCategory.antihypertensive,
      DrugCategory.cardiovascular,
    ],
    'ยาเบาหวาน': [
      DrugCategory.antidiabetic,
      DrugCategory.endocrine,
    ],
    'ยากันชัก': [
      DrugCategory.anticonvulsant,
      DrugCategory.neurological,
    ],
    'ยาจิตเวช': [
      DrugCategory.psychiatric,
    ],
    'ยาขับปัสสาวะ': [
      DrugCategory.diuretic,
    ],
    'ยาละลายลิ่มเลือด': [
      DrugCategory.anticoagulant,
      DrugCategory.antiplatelet,
    ],
    'ยาต้านเกล็ดเลือด': [
      DrugCategory.antiplatelet,
    ],
    'ยาลดกรด': [
      DrugCategory.gastrointestinal,
    ],
    'ยาแก้แพ้': [
      DrugCategory.antihistamine,
    ],
    'ยาขยายหลอดลม': [
      DrugCategory.respiratory,
    ],
  };

  /// Resolves Thai category keywords to matching [DrugCategory] list.
  static List<DrugCategory> resolveThaiCategory(String normalizedQuery) {
    for (final entry in _thaiCategoryMap.entries) {
      final normKey = normalize(entry.key);
      if (normKey == normalizedQuery ||
          normKey.contains(normalizedQuery) ||
          normalizedQuery.contains(normKey)) {
        return entry.value;
      }
    }
    return const [];
  }

  /// Thai pharmacological class keywords map.
  static final Map<String, List<DrugClass>> _thaiDrugClassMap = {
    'สแตติน': [DrugClass.statin],
    'ยาลดไขมัน': [DrugClass.statin],
    'เพนิซิลลิน': [DrugClass.betaLactamPenicillin],
    'เซฟาโลสปอริน': [DrugClass.betaLactamCephalosporin],
    'คาร์บาพีเนม': [DrugClass.betaLactamCarbapenem],
    'โอปิออยด์': [DrugClass.opioid],
    'เอ็นเสด': [DrugClass.nsaid],
  };

  /// Resolves Thai class keywords to matching [DrugClass] list.
  static List<DrugClass> resolveThaiDrugClass(String normalizedQuery) {
    for (final entry in _thaiDrugClassMap.entries) {
      final normKey = normalize(entry.key);
      if (normKey == normalizedQuery ||
          normKey.contains(normalizedQuery) ||
          normalizedQuery.contains(normKey)) {
        return entry.value;
      }
    }
    return const [];
  }
}
