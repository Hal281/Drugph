import 'package:drug_dosage_calculator/core/models/verified_drug_schema.dart';
import 'package:drug_dosage_calculator/data/knowledge_base_loader.dart';
import 'package:drug_dosage_calculator/ui/verified_clinical_calculator_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late VerifiedDrugKnowledgeBase kb;

  setUpAll(() async {
    kb = await KnowledgeBaseLoader.loadFromFile(
      'assets/data/drug_knowledge_base.json',
    );
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: VerifiedClinicalCalculatorScreen(initialKnowledgeBase: kb),
    );
  }

  group('Phase 4 — Pillar 3 Evidence-Based Clinical UI Widget Tests', () {
    testWidgets(
      'Renders Unit Badges (kg, ปี, mL/min/1.73m²), Scoped Safe Banner, and Step-by-Step Calculation Breakdown Accordion',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(1024, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 1. Verify Unit Badges on input fields
        expect(find.byKey(const Key('unit_badge_kg')), findsOneWidget);
        expect(find.byKey(const Key('unit_badge_years')), findsOneWidget);
        expect(find.byKey(const Key('unit_badge_renal')), findsOneWidget);
        expect(find.text('kg'), findsOneWidget);
        expect(find.text('ปี (yr)'), findsOneWidget);
        expect(find.text('mL/min/1.73m²'), findsOneWidget);

        // 2. Verify primary result for 15.0 kg Paracetamol & Scoped Safe Banner (Bug 5 Fix)
        expect(
          find.byKey(const Key('primary_dosage_result_card')),
          findsOneWidget,
        );
        expect(find.text('225.0 mg/ครั้ง'), findsOneWidget);
        expect(find.text('9.4 mL/ครั้ง'), findsOneWidget);
        expect(
          find.textContaining(
            'ไม่พบข้อห้ามใช้จากรายการที่ตรวจในฐานข้อมูลของยานี้',
          ),
          findsOneWidget,
        );

        // 3. Verify Calculation Breakdown Accordion is rendered with step lines
        expect(
          find.byKey(const Key('calculation_breakdown_accordion')),
          findsOneWidget,
        );
        expect(
          find.textContaining('15.0 kg × 15.0 mg/kg/dose = 225.0 mg/ครั้ง'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Displays Non-Blocking Overdose Warning, 4 doses/day daily cap consistency, and Graduated Medication Cup for 80 kg Paracetamol',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(1024, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('input_weight_kg')),
          '80.0',
        );
        await tester.enterText(
          find.byKey(const Key('input_age_years')),
          '25.0',
        );
        await tester.pumpAndSettle();

        // Adult age switches renal badge to Cockcroft-Gault mL/min
        expect(find.text('mL/min'), findsOneWidget);

        // Both Capped (1000.0 mg / 41.7 mL, 4 doses/day = 4000.0 mg/day) and Raw (1200.0 mg / 50.0 mL) are shown
        expect(find.text('1000.0 mg/ครั้ง'), findsOneWidget);
        expect(find.text('41.7 mL/ครั้ง'), findsOneWidget);
        expect(find.text('1200.0 mg/ครั้ง (50.0 mL)'), findsOneWidget);
        expect(
          find.textContaining('4 มื้อ/วัน = 4000.0 mg/วัน'),
          findsOneWidget,
        );

        // Overdose Warning banner & Graduated Medication Cup
        expect(find.textContaining('Overdose Warning'), findsOneWidget);
        expect(
          find.textContaining('Graduated Medication Cup'),
          findsAtLeastNWidgets(1),
        );
      },
    );

    testWidgets(
      'Bug 4 & Bug 6 UI Fix: Displays 2-decimal volume (0.31 mL/ครั้ง) for 0.5 kg neonate and Info notice when NKDA is unchecked',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(1024, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter 0.5 kg neonate weight -> exactVolumeMl = 0.3125 mL -> 2 decimals (0.31 mL/ครั้ง)
        await tester.enterText(
          find.byKey(const Key('input_weight_kg')),
          '0.5',
        );
        await tester.pumpAndSettle();

        expect(find.text('0.31 mL/ครั้ง'), findsOneWidget);

        // Uncheck NKDA checkbox -> emits info-level unassessed allergy notice
        await tester.tap(find.byKey(const Key('nkda_confirmed_checkbox')));
        await tester.pumpAndSettle();

        expect(
          find.textContaining(
            'ยังไม่ได้ยืนยันประวัติแพ้ยา (Allergy Status Not Assessed)',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Renders separate Same-Class Allergy, Cross-Reactivity Allergy, and DDI banners with database attribution',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(1024, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Select Amoxicillin from dropdown
        await tester.tap(find.byKey(const Key('drug_selector_dropdown')));
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('Amoxicillin').last);
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('input_allergies')),
          'penicillin v, CEPHALEXIN',
        );
        await tester.enterText(
          find.byKey(const Key('input_concomitant_meds')),
          'Methotrexate',
        );
        await tester.pumpAndSettle();

        // Verify Same-Class Allergy, Cross-Reactivity, and Lexicomp DDI banners
        expect(
          find.textContaining('แพ้ยากลุ่มเดียวกัน (Same Pharmacological Class)'),
          findsOneWidget,
        );
        expect(
          find.textContaining('แพ้ยาข้ามกลุ่ม (Cross-Reactivity)'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Lexicomp Drug Interactions'),
          findsAtLeastNWidgets(1),
        );
      },
    );

    testWidgets(
      'View Textbook Evidence Button opens TextbookEvidenceModal and renders SimulatedTextbookEvidenceCard fallback cleanly',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(1024, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('view_textbook_evidence_button')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('textbook_evidence_modal_dialog')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('source_verification_status_banner')),
          findsOneWidget,
        );
        expect(find.textContaining('source_verified: false'), findsOneWidget);
        expect(
          find.byKey(const Key('simulated_textbook_evidence_card')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Invalid weight (0 or negative) displays invalid_input_error_banner immediately',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(1024, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.enterText(find.byKey(const Key('input_weight_kg')), '0');
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('invalid_input_error_banner')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('primary_dosage_result_card')),
          findsNothing,
        );
      },
    );
  });
}
