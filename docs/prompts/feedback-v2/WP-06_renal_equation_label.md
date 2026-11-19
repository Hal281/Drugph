# WP-06: Show Renal Equation & Dosing Weight Basis Next to CrCl / eGFR

## 1. Context & Pharmacist Feedback Reference
* **Covers:** `FB-10`
* **Pharmacist Feedback:** *"การปรับยาตามค่าไต ใช้สูตรคำนวณมาตรฐาน Cockcroft-Gault equation ไหม... ควรระบุให้ชัดเจนว่า CrCl คำนวณจากสูตร Cockcroft-Gault และในคนอ้วนใช้เกณฑ์น้ำหนักอะไร (IBW/AdjBW)"*
* **Survey Finding:** `PatientClinicalHeader` (`lib/ui/calculator/widgets/patient_clinical_header.dart:160-186`) already shows `'CrCl คำนวณด้วยสูตร Cockcroft-Gault equation'` / `'CrCl calculated with Cockcroft-Gault equation'`, **even when the patient is a child** (where `PharmacistCalculator` actually uses `Bedside Schwartz`!), and does not display the selected weight strategy (`TBW`/`IBW`/`AdjBW`) next to the CrCl value.
* **Test Guardrail:** `test/ui/patient_profile_layout_test.dart:48,51` strictly asserts `find.text('CrCl calculated with Cockcroft-Gault equation')` AND `find.text('78.4 mL/min')` for adults! **Do NOT alter those two exact `Text` strings** — put the weight basis on an accompanying sub-caption or badge instead.

## 2. Goal
Display the exact renal formula (`Cockcroft-Gault` for age $\ge 18$, `Bedside Schwartz` for age $1–17$) and the Winter 2012 weight basis (`TBW`, `IBW`, or `AdjBW` in kg) in `PatientClinicalHeader` and `PatientBanner`.

## 3. Exact Files & Line Numbers to Touch
* [`lib/ui/calculator/widgets/patient_clinical_header.dart`](file:///c:/Users/turbo/drugforPh/lib/ui/calculator/widgets/patient_clinical_header.dart#L160-L186)
* [`lib/core/formatters/clinical_order_formatter.dart`](file:///c:/Users/turbo/drugforPh/lib/core/formatters/clinical_order_formatter.dart) (fix hardcoded `CrCl: ... (Cockcroft-Gault)` in CopyReadyNoteCard when `ageYears < 18` — should say `eGFR: ... mL/min/1.73 m² (Bedside Schwartz)`)
* [`lib/ui/widgets/patient_banner.dart`](file:///c:/Users/turbo/drugforPh/lib/ui/widgets/patient_banner.dart) (check how CrCl is summarized in the top orange/teal banner)
* [`test/ui/patient_profile_layout_test.dart`](file:///c:/Users/turbo/drugforPh/test/ui/patient_profile_layout_test.dart) (must continue passing without breaking existing assertions)
* [`test/clinical/pediatric_feedback_v2_fixes_test.dart`](file:///c:/Users/turbo/drugforPh/test/clinical/pediatric_feedback_v2_fixes_test.dart) (add `FB-10` widget tests)

## 4. Implementation Steps
1. Read `lib/ui/widgets/patient_banner.dart` completely to see how CrCl is displayed when a patient is active.
2. In `PatientClinicalHeader` (`patient_clinical_header.dart:160-186`), keep:
   - Adult equation line exact: `t ? 'CrCl คำนวณด้วยสูตร Cockcroft-Gault equation' : 'CrCl calculated with Cockcroft-Gault equation'`
   - Adult CrCl badge text exact: `'${crcl.toStringAsFixed(1)} mL/min'`
   - Add a clear sub-caption or adjacent badge inside the `Column` using `RenalCalculator.selectCockcroftGaultWeight(...)`: e.g. `CG weight: ${cgSelection.strategy} (${cgSelection.selectedWeightKg.toStringAsFixed(1)} kg)` (TH: `น้ำหนักสูตร CG: ${cgSelection.strategy} (${cgSelection.selectedWeightKg.toStringAsFixed(1)} kg)`).
   - For pediatric patients (`age != null && age < 18`): change the equation text to `t ? 'eGFR (เด็ก) คำนวณด้วยสูตร Bedside Schwartz' : 'Pediatric eGFR calculated with Bedside Schwartz'` (and for `< 1 year`, show infant eGFR disclaimer).
3. Update `PatientBanner` consistently to show `Cockcroft-Gault` (adult) / `Bedside Schwartz` (pediatric).
4. Add widget tests (`FB-10`) covering:
   - Normal-weight adult (`IBW` basis shown)
   - Underweight adult (`TBW` basis shown)
   - Obese adult (`AdjBW` basis shown)
   - Pediatric patient (`age = 6`, `Bedside Schwartz` shown instead of Cockcroft-Gault).

## 5. Acceptance Criteria
* Adult headers clearly display `Cockcroft-Gault` + weight strategy (`TBW`/`IBW`/`AdjBW`) + kg used.
* Pediatric headers display `Bedside Schwartz` instead of mislabeling CrCl as Cockcroft-Gault.
* `test/ui/patient_profile_layout_test.dart` passes unchanged.

## 6. Automated Verification Commands
```powershell
cd c:\Users\turbo\drugforPh
flutter analyze
flutter test test/ui/patient_profile_layout_test.dart test/clinical/pediatric_feedback_v2_fixes_test.dart
flutter test --no-pub -r compact
```

## 7. Forbidden Actions
* Do NOT modify the existing strings `'CrCl calculated with Cockcroft-Gault equation'` or `'78.4 mL/min'` in `PatientClinicalHeader` so `patient_profile_layout_test.dart` remains green.
