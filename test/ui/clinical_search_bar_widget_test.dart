// ============================================================
// Clinical Search Bar Widget Test Suite
// ============================================================
// Verifies:
// 1. Debounced query input (250ms)
// 2. Clear button ('X') visibility and tap action (>= 48x48 dp touch target)
// 3. Recent search chips rendering and tap selection
// 4. ClinicalHighlightText spans and styles
//
// DISCLAIMER: SaMD prototype — verification suite.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/ui/widgets/clinical_search_bar.dart';

void main() {
  group('ClinicalSearchBar & ClinicalHighlightText Widget Tests', () {
    testWidgets('Renders search field with placeholder and prefix icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClinicalSearchBar(
              query: '',
              onQueryChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('clinical_search_bar_input')), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byKey(const Key('clinical_search_bar_clear_button')), findsNothing);
    });

    testWidgets('Debounces text changes by 250ms before firing callback', (tester) async {
      String latestQuery = '';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClinicalSearchBar(
              query: '',
              debounceMs: 250,
              onQueryChanged: (val) {
                latestQuery = val;
              },
            ),
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('clinical_search_bar_input')),
        'ceftriaxone',
      );

      // Immediately after typing, callback should NOT have fired yet due to 250ms debounce
      expect(latestQuery, '');

      // Advance by 100ms: still not fired
      await tester.pump(const Duration(milliseconds: 100));
      expect(latestQuery, '');

      // Advance by another 160ms (total 260ms > 250ms): callback fired!
      await tester.pump(const Duration(milliseconds: 160));
      expect(latestQuery, 'ceftriaxone');
    });

    testWidgets('Clear button ("X") appears when text is present and clears on tap (>= 48x48 dp target)', (tester) async {
      String latestQuery = 'initial';
      bool clearFired = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClinicalSearchBar(
              query: 'ceftriaxone',
              onQueryChanged: (val) {
                latestQuery = val;
              },
              onClear: () {
                clearFired = true;
              },
            ),
          ),
        ),
      );

      final clearBtnFinder = find.byKey(const Key('clinical_search_bar_clear_button'));
      expect(clearBtnFinder, findsOneWidget);

      // Verify touch target dimension >= 48x48 dp
      final clearSize = tester.getSize(clearBtnFinder);
      expect(
        clearSize.width,
        greaterThanOrEqualTo(48.0),
        reason: 'Touch target width must be >= 48 dp per Impeccable UI/UX standards',
      );
      expect(
        clearSize.height,
        greaterThanOrEqualTo(48.0),
        reason: 'Touch target height must be >= 48 dp per Impeccable UI/UX standards',
      );

      // Tap clear button
      await tester.tap(clearBtnFinder);
      await tester.pumpAndSettle();

      expect(latestQuery, '');
      expect(clearFired, isTrue);
      expect(find.byKey(const Key('clinical_search_bar_clear_button')), findsNothing);
    });

    testWidgets('Displays recent search history chips when focused with empty query', (tester) async {
      String selected = '';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClinicalSearchBar(
              query: '',
              recentQueries: const ['Sepsis', 'Paracetamol', 'UTI'],
              onQueryChanged: (_) {},
              onRecentQuerySelected: (q) {
                selected = q;
              },
            ),
          ),
        ),
      );

      // Focus the input to reveal recent searches
      await tester.tap(find.byKey(const Key('clinical_search_bar_input')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('recent_search_chip_0')), findsOneWidget);
      expect(find.text('Sepsis'), findsOneWidget);
      expect(find.text('Paracetamol'), findsOneWidget);
      expect(find.text('UTI'), findsOneWidget);

      // Tap 'Sepsis' chip
      await tester.tap(find.text('Sepsis'));
      await tester.pumpAndSettle();

      expect(selected, 'Sepsis');
    });

    testWidgets('ClinicalHighlightText renders matching query slice with highlight styling', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ClinicalHighlightText(
              text: 'Ceftriaxone Sodium',
              query: 'tria',
              style: TextStyle(color: Colors.black87),
              highlightStyle: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );

      expect(find.byType(RichText), findsOneWidget);
      final richText = tester.widget<RichText>(find.byType(RichText));
      final rootSpan = richText.text as TextSpan;

      expect(rootSpan.children, isNotNull);
      expect(rootSpan.children!.length, 3); // 'Cef' + 'tria' + 'xone Sodium'
      expect((rootSpan.children![0] as TextSpan).text, 'Cef');
      expect((rootSpan.children![1] as TextSpan).text, 'tria');
      expect((rootSpan.children![1] as TextSpan).style?.color, Colors.teal);
      expect((rootSpan.children![2] as TextSpan).text, 'xone Sodium');
    });
  });
}
