# WP-05: Contraindication Deduplication & Drug Class Suffix Display

## 1. Context & Pharmacist Feedback Reference
* **Covers:** `FB-14`, `FB-15`
* **Pharmacist Feedback:**
  - `FB-14`: *"ในหน้า Ibuprofen ช่อง Contraindication เขียน 'Dengue fever (suspected)' ดูไม่เป็นทางการ และด้านล่างมีข้อความ 'หลีกเลี่ยงในผู้ป่วยที่สงสัยไข้เลือดออก ทานพร้อมอาหาร...' ซึ่งซ้ำซ้อนกับ Contraindication ด้านบน ควรตัดส่วนที่ซ้ำออก"*
  - `FB-15`: *"ข้อความ 'ตรวจสอบประวัติแพ้ยากลุ่มนี้ (NSAIDs / Aspirin)' บรรทัดแรกไม่มีประโยชน์ ควรเอาชื่อกลุ่มยาไปวงเล็บอยู่หลังชื่อยาแทน เช่น `Ibuprofen (NSAIDs)`"*

## 2. Goal
Remove Dengue contraindication duplication from `specialNotes` / `specialNotesTh` on NSAIDs (`Ibuprofen`, `Naproxen`) while keeping formal textbook contraindication wording, and standardize displaying the pharmacological class suffix in parentheses after the generic drug name (`Ibuprofen (NSAIDs)`) across drug headers.

## 3. Exact Files & Line Numbers to Touch
* [`lib/data/drugs/analgesics.dart`](file:///c:/Users/turbo/drugforPh/lib/data/drugs/analgesics.dart#L130-L158) (Ibuprofen) & [`lib/data/drugs/analgesics.dart`](file:///c:/Users/turbo/drugforPh/lib/data/drugs/analgesics.dart#L305-L316) (Naproxen)
* Audit `lib/data/drugs/*.dart` for any other `contraindications` duplicated verbatim in `specialNotes`
* [`lib/core/models/drug_ontology.dart`](file:///c:/Users/turbo/drugforPh/lib/core/models/drug_ontology.dart) & drug display header widget in `lib/ui/calculator/` (inspect where `drug.genericName` is rendered in the calculator header and search list)
* Tests in `test/clinical/pediatric_feedback_v2_fixes_test.dart` and widget test for class suffix

## 4. Implementation Steps
1. Verify `lib/data/drugs/analgesics.dart` (`Ibuprofen` & `Naproxen`):
   - `contraindications`: formal textbook phrasing including `'Suspected or confirmed Dengue hemorrhagic fever (thrombocytopenia/bleeding risk)'`, `'Active GI bleeding or peptic ulcer disease'`, `'Severe renal impairment (CrCl < 30 mL/min)'`.
   - `specialNotes` / `specialNotesTh`: keep **administration/practical counseling only** (e.g. taking with food/milk after meals, avoiding Dual NSAIDs) — **do NOT repeat Dengue fever**.
2. Inspect `lib/ui/calculator/calculator_screen.dart` and header widgets to find where the drug title (`drug.genericName`) is rendered.
3. Add a pure helper (e.g. `drug.displayNameWithClass` or `DrugOntology.classBadgeFor(drug)`) that formats e.g. `Ibuprofen (NSAIDs)`, `Amoxicillin (Penicillin)` where `DrugClass` maps cleanly to concise clinical abbreviations, avoiding ugly duplicates if `genericName` already contains the class.
4. Check `DrugDatabase.allDrugs` for any alerts/notes matching `"ตรวจสอบประวัติแพ้ยากลุ่มนี้"` and remove redundant static banner lines if superseded by the header class badge + `SafetyCheckEngine`.
5. Write widget + unit tests (`FB-14`, `FB-15`) verifying:
   - `Ibuprofen` and `Naproxen` keep Dengue in `contraindications` only, absent from `specialNotes`/`specialNotesTh`.
   - Calculator header renders `Ibuprofen (NSAIDs)` cleanly.

## 5. Acceptance Criteria
* Zero duplication of Dengue fever between `contraindications` and `specialNotes` on NSAIDs.
* Drug title displays pharmacological class in parentheses cleanly (`Ibuprofen (NSAIDs)`).
* Existing `test/drug_list_curation_test.dart` assertions (`naproxen.specialNotes` non-empty) and all `1,179+` tests pass.

## 6. Automated Verification Commands
```powershell
cd c:\Users\turbo\drugforPh
flutter analyze
flutter test test/clinical/pediatric_feedback_v2_fixes_test.dart test/drug_list_curation_test.dart
flutter test --no-pub -r compact
```

## 7. Forbidden Actions
* Do NOT remove real contraindications from `Drug.contraindications`.
* Do NOT disable `SafetyCheckEngine` / `TherapeuticDuplicationService` allergy & dual-NSAID checks.
