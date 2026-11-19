# WP-04: Clinical Terminology Standardization (`เข็มแรก` → `โดสแรก` / `Loading Dose`)

## 1. Context & Pharmacist Feedback Reference
* **Covers:** `FB-13`
* **Pharmacist Feedback:** *"ห้ามใช้คำว่า 'เข็มแรก' / 'เข็มที่ 2' กับยาฉีดเข้าหลอดเลือด (IV Infusion/Bolus) ฟังดูแปลกและไม่เป็นภาษาเภสัช/การแพทย์ ควรใช้ 'Loading Dose' / 'Maintenance Dose' หรือ 'โดสแรก (Dose แรก)' / 'โดสที่ 2'"*
* **Survey Finding:** `"เข็มแรก"` appeared at `lib/core/calculators/pharmacist_calculator.dart:449, 524, 540`. `"เข็มที่ 2"` was not found in `lib/` or `assets/`. Also check `phases` labels across IV regimens (e.g., `Amiodarone` in `lib/data/drugs/cardiovascular.dart`).

## 2. Goal
Ensure zero occurrences of colloquial `"เข็มแรก"` / `"เข็มที่"` remain anywhere in `lib/` or `assets/`, centralize standard Thai/English dosing phase labels in `ClinicalTerms`, and verify IV bolus/infusion phase wording (`Loading dose` / `Maintenance infusion`).

## 3. Exact Files & Line Numbers to Touch
* [`lib/core/calculators/pharmacist_calculator.dart`](file:///c:/Users/turbo/drugforPh/lib/core/calculators/pharmacist_calculator.dart#L449-L545)
* [NEW] `lib/core/formatters/clinical_terms.dart`
* Audit `DosingPhase` / `phases` in `lib/data/drugs/*.dart` (especially `cardiovascular.dart` Amiodarone, `neurology.dart`, `emergency.dart`, `antibiotics.dart`)
* [`test/clinical/pediatric_feedback_v2_fixes_test.dart`](file:///c:/Users/turbo/drugforPh/test/clinical/pediatric_feedback_v2_fixes_test.dart)

## 4. Implementation Steps
1. Grep the entire repository (`lib/`, `assets/`, `test/`) for `เข็มแรก`, `เข็มที่`, and `เข็ม`.
2. Verify `lib/core/calculators/pharmacist_calculator.dart` lines 449, 524, 540 use `โดสแรก (First dose)` / `โดสแรก (First/Loading dose)` and extract shared constants into `lib/core/formatters/clinical_terms.dart` (`ClinicalTerms.firstDoseTh`, `loadingDoseLabel`, `maintenanceInfusionLabel`, etc.).
3. Inspect `phases` on IV drugs (`Amiodarone`, `Phenytoin`, `Magnesium Sulfate`, `Lidocaine`/`Epinephrine`/`Norepinephrine`, etc.) and replace any informal `"เข็ม..."` phrasing with `Loading Dose` / `Maintenance Dose (Infusion)`.
4. Verify tests in `test/clinical/pediatric_feedback_v2_fixes_test.dart` (`FB-13`) assert that AKI/missing-SCr alerts use `"โดสแรก"` and scan all active `DrugDatabase` drug strings and `PharmacistCalculator` outputs to guarantee `"เข็มแรก"` / `"เข็มที่"` never appear.

## 5. Acceptance Criteria
* Zero occurrences of `เข็มแรก` or `เข็มที่ 2` in `lib/` and `assets/`.
* `ClinicalTerms` provides reusable constants for `Loading Dose`, `Maintenance Dose`, and `โดสแรก`.
* `flutter analyze` and `flutter test` pass (`>= 1,179`).

## 6. Automated Verification Commands
```powershell
cd c:\Users\turbo\drugforPh
flutter analyze
flutter test test/clinical/pediatric_feedback_v2_fixes_test.dart
flutter test --no-pub -r compact
```

## 7. Forbidden Actions
* Do NOT alter numerical doses or clinical behavior when updating wording.
* Do NOT break `test/icu_drugs_test.dart` or `test/golden_verification_test.dart`.
