# WP-02: Separate Child-Pugh "Not Assessed" from "Normal"

## 1. Context & Pharmacist Feedback Reference
* **Covers:** `FB-12`, Q6 design decision
* **Pharmacist Feedback:** *"ความจริงคือเภสัชไม่มีข้อมูล Child-Pugh score นี้ แม้ว่าผู้ป่วยเป็นโรคตับ (เพราะหมอไม่ได้เขียนลงแฟ้มข้อมูล)"*
* **Locked Decision (Q6):** Make Child-Pugh optional and default to **"Not assessed"** (`ไม่ได้ประเมิน`). When Child-Pugh is not assessed, **never auto-adjust the dose**, and display a non-blocking amber/yellow clinical banner with the textbook hepatic guidance if `drug.requiresHepaticCaution == true`. Keep the score calculator available for clinicians who do have labs/clinical findings.
* **Survey Finding:** Currently `ChildPughClass.none` is overloaded as both "Normal" and "Not assessed" in `lib/ui/calculator/models/calculator_ui_state.dart:57` and `lib/ui/calculator/controllers/calculator_controller.dart:121,162,199,363,502,519`.

## 2. Goal
Distinguish `notAssessed` (default) from `none`/Normal so hepatic-caution drugs emit clear unassessed amber guidance without falsely labeling the liver as "Normal" or silently skipping warning visibility.

## 3. Exact Files & Line Numbers to Touch
* `lib/core/calculators/child_pugh_calculator.dart` (check `ChildPughClass` definition; add `notAssessed` OR support `ChildPughClass?` cleanly — choose whichever has smaller blast radius across `core` & `ui` and document why)
* [`lib/core/calculators/pharmacist_calculator.dart`](file:///c:/Users/turbo/drugforPh/lib/core/calculators/pharmacist_calculator.dart#L180-L200) (check hepatic adjustment & warnings block)
* [`lib/ui/calculator/models/calculator_ui_state.dart`](file:///c:/Users/turbo/drugforPh/lib/ui/calculator/models/calculator_ui_state.dart#L57)
* [`lib/ui/calculator/controllers/calculator_controller.dart`](file:///c:/Users/turbo/drugforPh/lib/ui/calculator/controllers/calculator_controller.dart#L121-L525)
* [`lib/ui/calculator/widgets/dosing_parameters_form.dart`](file:///c:/Users/turbo/drugforPh/lib/ui/calculator/widgets/dosing_parameters_form.dart#L304-L450)
* [`lib/ui/calculator/widgets/patient_clinical_header.dart`](file:///c:/Users/turbo/drugforPh/lib/ui/calculator/widgets/patient_clinical_header.dart#L196-L204)
* [`lib/core/formatters/clinical_order_formatter.dart`](file:///c:/Users/turbo/drugforPh/lib/core/formatters/clinical_order_formatter.dart) (separate `'Normal / Not assessed'` into explicit `'Normal'` vs `'Not assessed'`)
* New tests in `test/clinical/child_pugh_not_assessed_test.dart` (and preserve `test/ui/patient_profile_layout_test.dart`)

## 4. Implementation Steps
1. Inspect `ChildPughClass` in `lib/core/calculators/child_pugh_calculator.dart` and grep all usages across `lib/` and `test/`.
2. Introduce explicit `"Not assessed"` representation:
   - Either add `ChildPughClass.notAssessed` as the default (preserving `ChildPughClass.none` as "ปกติ / Normal" for backward compatibility with existing tests), or handle `null` explicitly on `Patient.hepaticImpairment` while defaulting UI state to `notAssessed`.
   - Ensure `PharmacistCalculator.calculateDose` treats `notAssessed` identically to no automatic hepatic reduction (same dose as Normal), **plus** emits a `LimitSeverity.soft` / amber `DoseWarning` when `drug.requiresHepaticCaution == true` containing the drug's textbook hepatic guidance (`drug.monograph?.clinicalNotes` / hepatic caution summary) and reminding the clinician that Child-Pugh was not assessed.
3. Update `DosingParametersForm` chips to: `ไม่ได้ประเมิน (ค่าเริ่มต้น) | ปกติ | Class A | Class B | Class C` (EN: `Not assessed (default) | Normal | Class A | Class B | Class C`), keeping the Child-Pugh calculator modal accessible.
4. Keep `calculator_hepatic_options` collapsed initially so `test/ui/patient_profile_layout_test.dart:66-94` continues to pass unchanged.
5. Add unit & widget tests tagged `FB-12` / `WP-02`:
   - Default state is `notAssessed`.
   - Hepatic-caution drug (e.g., `fentanyl` or `morphine`) with `notAssessed` displays the amber guidance banner AND yields the unadjusted (Normal) calculated dose.
   - Selecting `Class C` still triggers full Child-Pugh Class C hepatic adjustment as before.

## 5. Acceptance Criteria
* Default hepatic state is `"Not assessed"`, not `"Normal"`.
* `drug.requiresHepaticCaution == true` shows a clear non-blocking yellow/amber banner with hepatic dosing advice even when Child-Pugh is omitted.
* All existing tests (including `patient_profile_layout_test.dart`) + new `FB-12` tests pass.

## 6. Automated Verification Commands
```powershell
cd c:\Users\turbo\drugforPh
flutter analyze
flutter test test/clinical/child_pugh_not_assessed_test.dart test/ui/patient_profile_layout_test.dart
flutter test --no-pub -r compact
```

## 7. Forbidden Actions
* Do NOT remove the in-app Child-Pugh score calculator sheet.
* Do NOT block dosing calculations when Child-Pugh is not assessed.
* Do NOT auto-reduce doses blindly when hepatic status is unknown.
