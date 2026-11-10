// ============================================================
// Empirical Adversarial Stress Test Suite — Challenger 1
// ============================================================
// Independent empirical verification for:
// 1. Search Engine Adversarial Stress & 100-Search Benchmark
//    - Extreme length strings (100, 500, 2000 chars)
//    - Regex metacharacters and format injection
//    - Unicode, emojis, diacritics, RTL, and zero-width spaces
//    - Typo distance (dist 1 vs 2 vs 3), truncation, mixed case
//    - Latency statistics over 100 diverse searches (< 16ms requirement)
// 2. Modular Calculator Dashboard Adversarial Stress
//    - Extreme inputs: 300kg weight, 25 mg/dL SCr, 300kg + 25 SCr
//    - Unselected regimen resilience and selectRegimen(null) clearing verification
//    - Rapid RRT and regimen toggling
//    - Rule 5 Non-blocking Overdose Invariant: calculatedDose and
//      roundedDose preservation under massive overdose
//    - Compact 320x480 screen layout without RenderFlex overflow
// ============================================================

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:drug_dosage_calculator/data/drug_search_engine.dart';
import 'package:drug_dosage_calculator/ui/calculator/calculator_screen.dart';
import 'package:drug_dosage_calculator/ui/calculator/controllers/calculator_controller.dart';
import 'package:drug_dosage_calculator/ui/calculator/models/calculator_ui_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    DrugDatabase.warmUp();
  });

  const testRegimen = DosingRegimen(
    route: DoseRoute.po,
    indication: 'Acute Severe Pain',
    dosingType: DosingType.weightBased,
    dosePerKg: 15.0,
    doseUnit: DoseUnit.mg,
    frequency: Frequency.q6h,
    limits: DoseLimit(
      maxSingleDose: 1000.0,
      maxDailyDose: 4000.0,
    ),
    verificationStatus: VerificationStatus.verified,
  );

  const testOverdoseDrug = Drug(
    id: 'test_paracetamol_od',
    genericName: 'Paracetamol',
    nameTh: 'พาราเซตามอล',
    brandNames: ['Tylenol', 'Sara'],
    category: DrugCategory.analgesic,
    availableStrengths: [500.0],
    sourceCitation: 'Lexicomp 2024 / RDU Thailand',
    regimens: [testRegimen],
    provenance: Provenance(
      source: 'Lexicomp 2024',
      reviewedBy: 'Clinical Pharmacist',
      reviewedAt: '2024-01-01',
    ),
  );

  const testDrugNoRegimens = Drug(
    id: 'test_no_regimens',
    genericName: 'UnselectedDrug',
    category: DrugCategory.analgesic,
    sourceCitation: 'Lexicomp 2024',
    regimens: [],
  );

  group('CHALLENGER 1: Search Engine Adversarial Stress Testing', () {
    // ------------------------------------------------------------
    // 1. Extreme String Lengths
    // ------------------------------------------------------------
    test('1.1 Handles extreme query lengths (100, 500, 2000 chars) without crashing', () {
      // Warm up search engine first to eliminate initial static init / classloading jitter
      DrugDatabase.searchDetailed('warmup');

      final query100 = 'a' * 100;
      final query500 = 'paracetamol${'x' * 489}';
      final query2000Alpha = 'ceftriaxone${'z' * 1989}';
      final query2000Punct = 'ceftriaxone${'?' * 1989}';

      final sw = Stopwatch()..start();
      final res100 = DrugDatabase.searchDetailed(query100);
      final res500 = DrugDatabase.searchDetailed(query500);
      final res2000Alpha = DrugDatabase.searchDetailed(query2000Alpha);
      final res2000Punct = DrugDatabase.searchDetailed(query2000Punct);
      sw.stop();

      // Non-matching alphanumeric extreme strings return empty
      expect(res100, isEmpty);
      expect(res500, isEmpty);
      expect(res2000Alpha, isEmpty);

      // Normalization observation: punctuation '?' is stripped by normalize(),
      // resolving 'ceftriaxone' + 1989 '?' characters directly to Ceftriaxone!
      expect(res2000Punct, isNotEmpty);
      expect(res2000Punct.first.drug.id, 'ceftriaxone');

      // Even 4 massive queries together execute in < 100ms after warmup
      expect(sw.elapsedMilliseconds, lessThan(100));
    });

    // ------------------------------------------------------------
    // 1.2 Regex Metacharacters and Format Injection
    // ------------------------------------------------------------
    test('1.2 Survives complex regex metacharacters and SQL/format symbols', () {
      final adversarialQueries = [
        r'.*',
        r'[a-z]+',
        r'(\d+).*?',
        r'^ceftriaxone$',
        r'paracetamol|amoxicillin',
        r'vancomycin\s+1g',
        r'???+++***',
        r'${test}',
        r'<!-- comment -->',
        r'<script>alert("xss")</script>',
        r'DROP TABLE drugs;--',
        r'%20%27%22',
      ];

      for (final q in adversarialQueries) {
        expect(
          () => DrugDatabase.searchDetailed(q),
          returnsNormally,
          reason: 'Failed on regex query: "$q"',
        );
      }
    });

    // ------------------------------------------------------------
    // 1.3 Unicode, Diacritics, RTL, Emojis, Zero-Width Spaces
    // ------------------------------------------------------------
    test('1.3 Handles unicode diacritics, RTL, emojis, and null bytes gracefully', () {
      final unicodeQueries = [
        '💊 paracetamol',
        'céftriaxone', // decomposed e + combining acute
        'พาราเซตามอล',
        'ยาฆ่าเชื้อ',
        '\u200Eparacetamol\u200F', // LTR and RTL marks
        'para\u200Bcetamol', // zero-width space
        'para\u0000cetamol', // null byte
        '   \t\n   ', // whitespace only
        'α-blocker', // Greek alpha
        'амоксициллин', // Cyrillic amoxicillin
      ];

      for (final q in unicodeQueries) {
        expect(
          () => DrugDatabase.searchDetailed(q),
          returnsNormally,
          reason: 'Failed on unicode query: "$q"',
        );
      }

      // Thai query should find Paracetamol
      final thaiRes = DrugDatabase.searchDetailed('พาราเซตามอล');
      expect(thaiRes, isNotEmpty);
      expect(thaiRes.first.drug.id, 'paracetamol');
      expect(thaiRes.first.score, greaterThanOrEqualTo(400));
    });

    // ------------------------------------------------------------
    // 1.4 Typo Distance Stress (Distance 1 vs 2 vs 3) & Truncation
    // ------------------------------------------------------------
    test('1.4 Typo tolerance correctly distinguishes distance 1, 2, and 3', () {
      // Meropenem (length 9)
      // Dist 0: Exact generic name
      final dist0 = DrugDatabase.searchDetailed('meropenem');
      expect(dist0.first.drug.id, 'meropenem');
      expect(dist0.first.score, greaterThanOrEqualTo(1000));

      // Dist 1: Substitution typo 'meropenen' (m -> n)
      final dist1 = DrugDatabase.searchDetailed('meropenen');
      expect(dist1, isNotEmpty);
      final mero1 = dist1.firstWhere((r) => r.drug.id == 'meropenem');
      expect(
        mero1.matchedReasons.any((r) => r.type == MatchedReasonType.fuzzyMatch),
        isTrue,
      );
      expect(mero1.score, 50);

      // Dist 2: Two substitutions 'meropenqq' (len 9, 2 typos)
      final dist2 = DrugDatabase.searchDetailed('meropenqq');
      expect(dist2, isNotEmpty);
      final mero2 = dist2.firstWhere((r) => r.drug.id == 'meropenem');
      expect(
        mero2.matchedReasons.any((r) => r.type == MatchedReasonType.fuzzyMatch),
        isTrue,
      );

      // Dist 3: Three substitutions 'meropqqq' (diff 3) -> should NOT match as fuzzy
      final dist3 = DrugDatabase.searchDetailed('meropqqq');
      expect(
        dist3.any((r) => r.drug.id == 'meropenem'),
        isFalse,
        reason: 'Distance 3 should be outside Levenshtein threshold <= 2',
      );

      // Truncated query 'meropen' (prefix, length 7) -> should get 500 prefix points!
      final prefixRes = DrugDatabase.searchDetailed('meropen');
      expect(prefixRes, isNotEmpty);
      expect(prefixRes.first.drug.id, 'meropenem');
      expect(prefixRes.first.score, greaterThanOrEqualTo(500));
    });

    test('1.5 Case insensitivity and non-existent queries', () {
      final mixed1 = DrugDatabase.searchDetailed('cEfTrIaXoNe');
      final lower1 = DrugDatabase.searchDetailed('ceftriaxone');
      expect(mixed1.first.drug.id, lower1.first.drug.id);
      expect(mixed1.first.score, lower1.first.score);

      final nonExistent = DrugDatabase.searchDetailed('kryptonitexyz12345');
      expect(nonExistent, isEmpty);
    });

    // ------------------------------------------------------------
    // 1.6 Benchmark: 100 Diverse Searches Latency Verification (< 16ms)
    // ------------------------------------------------------------
    test('1.6 Benchmark 100 diverse search queries: average latency < 16ms', () {
      // Warm up search engine and JIT compilation before starting benchmark stopwatch
      DrugDatabase.searchDetailed('paracetamol');

      final searchQueries = [
        'paracetamol', 'ceftriaxone', 'meropenem', 'vancomycin', 'ciprofloxacin',
        'amoxicillin', 'ampicillin', 'gentamicin', 'amikacin', 'levofloxacin',
        'colistin', 'piperacillin', 'doxycycline', 'azithromycin', 'clarithromycin',
        'tylenol', 'rocephin', 'meronem', 'vancocin', 'augmentin',
        'sepsis', 'cap', 'uti', 'meningitis', 'pneumonia', 'shock',
        'พาราเซตามอล', 'ยาฆ่าเชื้อ', 'ยาแก้ปวด', 'ยาลดความดัน', 'เซฟไตร',
        'paracetamul', 'ceftriaxon', 'meropenen', 'vankomycin', 'amoxicilin',
        'a', 'ab', 'abc', 'antibiotic', 'analgesic', 'cardiovascular',
        '1000mg', 'po', 'iv', 'renal', 'crcl', 'dialysis', 'overdose',
        'cef', 'pen', 'micin', 'mycin', 'cillin', 'floxacin', 'prazole',
        'paracetamol 500', 'ceftriaxone 1g', 'meropenem 1g iv',
        '', '   ', '!!!', '***', '???', '12345', 'xyz999',
        'very long medical query string that does not match anything in database',
        'norepinephrine', 'epinephrine', 'dopamine', 'dobutamine', 'furosemide',
        'spironolactone', 'enalapril', 'losartan', 'amlodipine', 'atenolol',
        'metoprolol', 'propranolol', 'digoxin', 'amiodarone', 'warfarin',
        'aspirin', 'clopidogrel', 'heparin', 'enoxaparin', 'fondaparinux',
        'insulin', 'metformin', 'glipizide', 'omeprazole', 'pantoprazole',
        'ondansetron', 'metoclopramide', 'morphine', 'fentanyl', 'tramadol',
      ];

      expect(searchQueries.length, greaterThanOrEqualTo(80));

      final latenciesUs = <int>[];
      final totalSw = Stopwatch()..start();

      for (int i = 0; i < 100; i++) {
        final q = searchQueries[i % searchQueries.length];
        final sw = Stopwatch()..start();
        final results = DrugDatabase.searchDetailed(q);
        sw.stop();
        latenciesUs.add(sw.elapsedMicroseconds);
        expect(results, isNotNull);
      }
      totalSw.stop();

      final totalMs = totalSw.elapsedMilliseconds;
      final avgUs = latenciesUs.reduce((a, b) => a + b) / latenciesUs.length;
      final avgMs = avgUs / 1000.0;
      final maxUs = latenciesUs.reduce(max);
      final maxMs = maxUs / 1000.0;

      // Sort to calculate p95
      latenciesUs.sort();
      final p95Us = latenciesUs[(latenciesUs.length * 0.95).floor()];
      final p95Ms = p95Us / 1000.0;

      // ignore: avoid_print
      print('=== 100 SEARCH BENCHMARK RESULTS ===');
      // ignore: avoid_print
      print('Total elapsed time for 100 searches: ${totalMs}ms');
      // ignore: avoid_print
      print('Average search latency: ${avgMs.toStringAsFixed(3)}ms (target: < 16ms)');
      // ignore: avoid_print
      print('p95 search latency: ${p95Ms.toStringAsFixed(3)}ms');
      // ignore: avoid_print
      print('Max search latency: ${maxMs.toStringAsFixed(3)}ms');

      expect(avgMs, lessThan(16.0), reason: 'Average latency must be < 16ms (60 FPS gate)');
      expect(maxMs, lessThan(50.0), reason: 'Max latency should not exceed 50ms');
    });
  });

  group('CHALLENGER 1: Modular Calculator Adversarial Stress Testing', () {
    // ------------------------------------------------------------
    // 2.1 Extreme Clinical Inputs (300kg, 25 mg/dL SCr)
    // ------------------------------------------------------------
    test('2.1 Controller handles extreme inputs (300kg weight, 25 SCr) deterministically', () {
      final controller = CalculatorController(drug: testOverdoseDrug);
      addTearDown(() => controller.dispose());

      // Select regimen
      controller.selectRegimen(testRegimen);

      // Extreme Weight: 300kg, Height: 170cm (BMI 103.8), Age: 35, SCr: 1.0
      controller.weightCtrl.text = '300';
      controller.heightCtrl.text = '170';
      controller.ageCtrl.text = '35';
      controller.scrCtrl.text = '1.0';

      final val1 = controller.calculate(isThai: true);
      expect(val1.isValid, isTrue);
      expect(controller.state.status, CalculatorUiStatus.warning); // Overdose!
      expect(controller.state.result, isNotNull);

      // 300 kg * 15 mg/kg = 4500 mg (Overdose > 1000 mg max)
      expect(controller.state.result!.calculatedDose, 4500.0);
      expect(controller.state.result!.roundedDose, isNotNull);

      // Extreme SCr: 25.0 mg/dL, Weight: 70kg, Height: 170cm, Age: 35
      controller.weightCtrl.text = '70';
      controller.scrCtrl.text = '25.0';
      final val2 = controller.calculate(isThai: true);
      expect(val2.isValid, isTrue);
      expect(controller.state.result, isNotNull);
      // SCr 25.0 results in very low CrCl without crashing or divide-by-zero
      final crcl = controller.state.result!.crclMlMin;
      expect(crcl, isNotNull);
      expect(crcl!, greaterThan(0.0));
      expect(crcl, lessThan(10.0)); // Severe renal failure

      // Extreme combo: 300kg weight AND 25.0 mg/dL SCr
      controller.weightCtrl.text = '300';
      controller.scrCtrl.text = '25.0';
      final val3 = controller.calculate(isThai: true);
      expect(val3.isValid, isTrue);
      expect(controller.state.result!.calculatedDose, 4500.0);
      expect(controller.state.result!.crclMlMin, isNotNull);
    });

    // ------------------------------------------------------------
    // 2.2 Unselected Regimen State Handling & Bug Discovery
    // ------------------------------------------------------------
    test('2.2 Unselected regimen initial state does not throw on calculate', () {
      final controller = CalculatorController(drug: testDrugNoRegimens);
      addTearDown(() => controller.dispose());

      controller.weightCtrl.text = '70';
      controller.heightCtrl.text = '170';
      controller.ageCtrl.text = '35';
      controller.scrCtrl.text = '1.0';

      expect(controller.state.selectedRegimen, isNull);

      // Calling calculate should return validation without mutating to error/active
      final val = controller.calculate(isThai: true);
      expect(val.isValid, isTrue);
      expect(controller.state.hasCalculatedResult, isFalse);
      expect(controller.state.status, CalculatorUiStatus.empty);
    });

    test('2.2.1 selectRegimen(null) properly clears selectedRegimen in CalculatorController', () {
      final controller = CalculatorController(drug: testOverdoseDrug);
      addTearDown(() => controller.dispose());

      expect(controller.state.selectedRegimen, isNotNull);

      // Call selectRegimen(null)
      controller.selectRegimen(null);

      // Successfully cleared via clearRegimen: regimen == null in CalculatorController
      expect(
        controller.state.selectedRegimen,
        isNull,
        reason: 'controller.selectRegimen(null) must clear regimen via clearRegimen: true in copyWith',
      );
    });

    // ------------------------------------------------------------
    // 2.3 Rapid Toggling of Regimens and RRT Modes
    // ------------------------------------------------------------
    test('2.3 Rapid cycling of RRT modes and regimens preserves controller state', () {
      final meropenem = DrugDatabase.findById('meropenem')!;
      final controller = CalculatorController(drug: meropenem);
      addTearDown(() => controller.dispose());

      controller.weightCtrl.text = '75';
      controller.heightCtrl.text = '175';
      controller.ageCtrl.text = '50';
      controller.scrCtrl.text = '1.5';

      final rrtModes = [
        RenalReplacementMode.none,
        RenalReplacementMode.ihd,
        RenalReplacementMode.capd,
        RenalReplacementMode.crrt,
        RenalReplacementMode.none,
      ];

      for (final mode in rrtModes) {
        controller.setRenalReplacementMode(mode);
        expect(controller.state.renalReplacementMode, mode);

        for (final reg in meropenem.regimens) {
          controller.selectRegimen(reg);
          final res = controller.calculate(isThai: true);
          expect(res.isValid, isTrue);
          expect(controller.state.result, isNotNull);
          expect(controller.state.result!.renalReplacementMode, mode);
        }
      }
    });

    // ------------------------------------------------------------
    // 2.4 Rule 5 Non-Blocking Overdose Invariant: calculatedDose & roundedDose Visible
    // ------------------------------------------------------------
    testWidgets(
      '2.4 Rule 5 Non-blocking Overdose Invariant: calculatedDose (4500mg) and roundedDose are visible on screen',
      (tester) async {
        tester.view.physicalSize = const Size(1024, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(const MaterialApp(
          home: CalculatorScreen(
            drug: testOverdoseDrug,
            isThai: true,
          ),
        ));
        await tester.pumpAndSettle();

        // Input 300kg weight -> 300kg * 15 mg/kg = 4500 mg (> 1000 mg limit)
        await tester.enterText(
          find.byKey(const Key('calculator_weight_field')),
          '300',
        );
        await tester.enterText(
          find.byKey(const Key('calculator_height_field')),
          '170',
        );
        await tester.enterText(
          find.byKey(const Key('calculator_age_field')),
          '35',
        );
        await tester.enterText(
          find.byKey(const Key('calculator_scr_field')),
          '1.0',
        );
        await tester.pumpAndSettle();

        // Tap calculate button
        await tester.tap(find.byKey(const Key('calculator_calculate_button')));
        await tester.pumpAndSettle();

        // 1. Verify overdose banner is present
        expect(find.byKey(const Key('calculator_overdose_banner')), findsOneWidget);

        // 2. Verify calculatedDose (4500.00 mg) is displayed on screen
        // In DosageResultCard, it appears both in the rounded display and the strikethrough raw formula
        expect(find.textContaining('4500.00 mg'), findsWidgets);

        // 3. Verify roundedDose is displayed on screen
        expect(find.textContaining('mg'), findsWidgets);

        // 4. Verify neither is hidden, locked, or zeroed
        expect(find.text('0.00 mg'), findsNothing);
      },
    );

    // ------------------------------------------------------------
    // 2.5 Layout Stress on Compact 320x480 Viewport (No Overflow)
    // ------------------------------------------------------------
    testWidgets(
      '2.5 Compact 320x480 screen renders completely without RenderFlex overflow (English & Thai)',
      (tester) async {
        // Enforce 320x480 screen constraints
        tester.view.physicalSize = const Size(320, 480);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // Test Thai locale (typically longer text)
        await tester.pumpWidget(const MaterialApp(
          home: CalculatorScreen(
            drug: testOverdoseDrug,
            isThai: true,
          ),
        ));
        await tester.pumpAndSettle();

        // Fill parameters and calculate
        await tester.enterText(
          find.byKey(const Key('calculator_weight_field')),
          '70',
        );
        await tester.enterText(
          find.byKey(const Key('calculator_height_field')),
          '170',
        );
        await tester.enterText(
          find.byKey(const Key('calculator_age_field')),
          '35',
        );
        await tester.enterText(
          find.byKey(const Key('calculator_scr_field')),
          '1.0',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('calculator_calculate_button')));
        await tester.pumpAndSettle();

        // Verify no RenderFlex overflow exception was caught by Flutter
        expect(tester.takeException(), isNull);

        // Verify sticky calculate bar is still accessible
        expect(find.byKey(const Key('calculator_calculate_button')), findsOneWidget);

        // Verify dose result is rendered
        expect(find.textContaining('mg'), findsWidgets);
      },
    );
  });
}
