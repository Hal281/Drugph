# WP-01: Fix Cockcroft-Gault Dosing Weight in `PatientEditDialog` & Audit Raw-Weight Calls

## 1. Context & Pharmacist Feedback Reference
* **Covers:** `FB-08`, `FB-09` (Critical bug discovered during codebase survey)
* **Pharmacist Feedback:** *"ถ้าผู้ป่วยเป็นคนอ้วน (Obese) หรือน้ำหนักไม่ตรงมาตรฐาน ต้องใช้ Ideal Body Weight / Adjusted Body Weight ในการคำนวณ การคำนวณยาผิดพลาดไม่ได้"*
* **Survey Finding:** `PharmacistCalculator` (`lib/core/calculators/pharmacist_calculator.dart:487-492`) and `RenalCalculator.selectCockcroftGaultWeight` (`lib/core/calculators/renal_calculator.dart:59-143`) implement Winter 2012 weight selection (`TBW < IBW -> TBW`, `IBW <= TBW < 120% IBW -> IBW`, `TBW >= 120% IBW -> AdjBW`), **but** `PatientEditDialog._save` (`lib/ui/widgets/patient_edit_dialog.dart:79-88`) calls `RenalCalculator.cockcroftGault(weightKg: wt)` using raw actual weight (`wt`) even though `ht` is validated right above on line 74.

## 2. Goal
Ensure `PatientEditDialog._save` uses `RenalCalculator.cockcroftGaultAutoWeight` so the stored `Patient.creatinineClearanceMlMin` matches `PharmacistCalculator` for underweight, normal, and obese adults, and audit every remaining call to `RenalCalculator.cockcroftGault(` across `lib/`.

## 3. Exact Files & Line Numbers to Touch
* [`lib/ui/widgets/patient_edit_dialog.dart`](file:///c:/Users/turbo/drugforPh/lib/ui/widgets/patient_edit_dialog.dart#L79-L88)
* Audit only (report findings; check whether fallback `heightCm <= 0` is safe): [`lib/ui/tdm_screen.dart`](file:///c:/Users/turbo/drugforPh/lib/ui/tdm_screen.dart#L109-L133), [`lib/core/calculators/pharmacist_calculator.dart`](file:///c:/Users/turbo/drugforPh/lib/core/calculators/pharmacist_calculator.dart#L487-L492)
* [`test/clinical/pediatric_feedback_v2_fixes_test.dart`](file:///c:/Users/turbo/drugforPh/test/clinical/pediatric_feedback_v2_fixes_test.dart)

## 4. Implementation Steps
1. Read `lib/core/calculators/renal_calculator.dart` lines 123–143 to verify the exact parameter names of `cockcroftGaultAutoWeight` (`ageYears`, `weightKg`, `heightCm`, `sex`, `serumCreatinineMgDl`).
2. Update `lib/ui/widgets/patient_edit_dialog.dart` lines 79–88:
   ```dart
   // Precise CrCl calculation using Cockcroft-Gault with Winter 2012 TBW/IBW/AdjBW selection
   double? crcl;
   if (scr != null && scr > 0 && age >= 18) {
     crcl = RenalCalculator.cockcroftGaultAutoWeight(
       ageYears: age,
       weightKg: wt,
       heightCm: ht,
       sex: _sex,
       serumCreatinineMgDl: scr,
     );
   }
   ```
3. Grep all occurrences of `cockcroftGault(` in `lib/` and verify none pass raw `TBW` when `heightCm > 0`.
4. Add unit + widget tests (`FB-09`) verifying:
   - Obese adult (`120 kg`, `170 cm`, male, `50 yrs`, `SCr 1.0`): `cockcroftGaultAutoWeight` returns `AdjBW`-based CrCl (`~109.6 mL/min`), NOT raw TBW (`150.0 mL/min`).
   - Saving this patient via `PatientEditDialog` stores the exact `cockcroftGaultAutoWeight` CrCl in `PatientSession.instance.currentPatient`.

## 5. Acceptance Criteria
* `PatientEditDialog` never stores raw-weight CrCl for obese/normal-habitus adults when height is provided.
* CrCl in `PatientSession` matches `PharmacistCalculator.calculateDose().crclMlMin` for the same patient.
* All new `FB-09` tests and existing `1,179+` tests pass.

## 6. Automated Verification Commands
```powershell
cd c:\Users\turbo\drugforPh
flutter analyze
flutter test test/clinical/pediatric_feedback_v2_fixes_test.dart
flutter test --no-pub -r compact
```

## 7. Forbidden Actions
* Do NOT modify `RenalCalculator.selectCockcroftGaultWeight` Winter 2012 thresholds (`1.2 * IBW`, `0.4` AdjBW factor).
* Do NOT skip height validation in `PatientEditDialog`.
