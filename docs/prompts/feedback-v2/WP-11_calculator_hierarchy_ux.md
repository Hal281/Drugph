# WP-11: Minimalist Calculator Screen Hierarchy, Compact IV Chips & Tappable Renal/Hepatic Banner

## 1. Context & Pharmacist Feedback Reference
* **Covers:** `FB-16`, `FB-17`, `FB-19`
* **Pharmacist Feedback:**
  - `FB-16`: *"หน้าคำนวณโดสควรคลีนที่สุด ข้อบ่งใช้ (Indications) อยู่บรรทัดแรก... 3 สิ่งที่ต้องเห็นชัดเจนที่สุดคือ 1. ขนาดยาที่ใช้รักษา (Therapeutic Dose) 2. วิถีทางและวิธีการบริหารยา (Route & Admin) 3. ผลข้างเคียงที่สำคัญ (Side Effects)... Desktop ควรวางฝั่งซ้ายบนเป็นข้อมูลผู้ป่วย+ข้อบ่งใช้ ฝั่งขวาเป็นกล่องตรวจสอบแพ้ยา/ยาตีกัน"*
  - `FB-17`: *"IV Compatibility ในแอปเขียนยาวเกินไป ควรสรุปสั้น ๆ ว่าผสมกับ D5W หรือ NSS ได้ไหม"*
  - `FB-19`: *"แถบ 'ควรปรับขนาดในผู้ป่วยโรคตับ/ไต' กดเข้าไปดูรายละเอียดไม่ได้"*

## 2. Goal
Streamline `CalculatorScreen` visual hierarchy for rapid bedside/ward scanning on both mobile and desktop (`maxWidth > 800`), summarize IV compatibility into compact `NSS` / `D5W` chips (expandable on tap), and make the renal/hepatic adjustment notice tappable to open exact adjustment tables/guidance.

## 3. Exact Files & Line Numbers to Touch
* [`lib/ui/calculator/calculator_screen.dart`](file:///c:/Users/turbo/drugforPh/lib/ui/calculator/calculator_screen.dart#L152-L350)
* `lib/ui/calculator/widgets/regimen_selector_section.dart` (ensure Indication selector sits at the very top of drug decision flow)
* [`lib/ui/calculator/widgets/dosage_result_card.dart`](file:///c:/Users/turbo/drugforPh/lib/ui/calculator/widgets/dosage_result_card.dart)
* [`lib/ui/calculator/widgets/iv_diluent_compatibility_card.dart`](file:///c:/Users/turbo/drugforPh/lib/ui/calculator/widgets/iv_diluent_compatibility_card.dart#L9-L217)
* `lib/ui/calculator/widgets/clinical_header_alerts.dart` & side effects display widget (`[NEW]` `lib/ui/calculator/widgets/side_effects_summary_card.dart`)
* Tests in `test/ui/calculator_hierarchy_ux_test.dart` (plus verify `test/ui/patient_profile_layout_test.dart`, `test/ui/phase3_hepatic_and_diluent_widget_test.dart`, `test/ui/calculator_references_and_interactions_test.dart`)

## 4. Implementation Steps
1. Read `lib/ui/calculator/calculator_screen.dart` lines 100–350 and `iv_diluent_compatibility_card.dart` lines 1–217 carefully.
2. **Enforce Top-to-Bottom Visual Hierarchy:**
   - Top header: `Drug Name (Class)` + `DrugTier` badge (`WP-05`/`WP-08`)
   - Mobile & Desktop right/main flow:
     1. **Indication Selector** (`RegimenSelectorSection`) on the first line
     2. **Therapeutic Dose Card** (`DosageResultCard` — large `mg` + `mL` / syringe + frequency)
     3. **Route & Administration** (clearly grouped directly with or immediately below dose)
     4. **Top 3–5 Side Effects** (concise chip/bullet card from `WP-09`)
     5. **Collapsible / Tappable Details:** Step-by-step calculation breakdown, compact **IV Compatibility Chips** (`NSS ✓` / `D5W ✓` / `LRS ✗`, expandable on tap for full dilution text so existing `phase3_hepatic_and_diluent_widget_test.dart` warnings on incompatible diluents stay visible!), and tappable **Renal / Hepatic Adjustment** alert that opens the drug's `renalGuideline` / `renalAdjustments` table or `ClinicalEvidenceSheet` focused on the renal/hepatic tab!
3. Check Desktop layout (`maxWidth > 800`): left column = Patient Profile + Parameters + Indication; right column = Alerts (Allergy/DDI/HAD) + Dose Result + Route/Admin + Side Effects + Collapsibles.
4. Preserve all existing keys and strings asserted in `patient_profile_layout_test.dart`, `phase3_hepatic_and_diluent_widget_test.dart`, and `calculator_references_and_interactions_test.dart`.
5. Add widget tests (`FB-16`, `FB-17`, `FB-19`) verifying render order (`y` coordinates top-to-bottom), compact `NSS`/`D5W` chip presence + tap-to-expand, and tapping the renal/hepatic adjustment banner opens adjustment details.

## 5. Acceptance Criteria
* Indication $\rightarrow$ Dose $\rightarrow$ Route/Admin $\rightarrow$ Side Effects order is verified via widget position assertions on mobile & desktop viewports (including `320x480` narrow viewport).
* Tapping `"ปรับขนาดในผู้ป่วยโรคตับ/ไต"` opens actionable renal/hepatic details (`FB-19`).
* Compact IV compatibility chips render cleanly without clutter, while incompatible diluent warnings (e.g. Norepinephrine + NSS, Phenytoin + D5W) remain unmissable.

## 6. Automated Verification Commands
```powershell
cd c:\Users\turbo\drugforPh
flutter analyze
flutter test test/ui/calculator_hierarchy_ux_test.dart test/ui/phase3_hepatic_and_diluent_widget_test.dart test/ui/patient_profile_layout_test.dart test/ui/calculator_references_and_interactions_test.dart
flutter test --no-pub -r compact
```

## 7. Forbidden Actions
* Do NOT re-add the "แหล่งอ้างอิง (2)" card onto the main calculator body (`FB-06`).
* Do NOT hide or auto-collapse incompatible IV diluent red warnings (`Norepinephrine + NSS`, `Phenytoin + D5W`) or overdose warnings (Rule 5).
