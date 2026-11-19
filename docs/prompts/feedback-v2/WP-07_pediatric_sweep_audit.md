# WP-07: Pediatric Regimen Sweep Audit & Adult-Regimen-in-Child Warning Guard

## 1. Context & Pharmacist Feedback Reference
* **Covers:** `FB-02` (hardening)
* **Pharmacist Feedback:** *"ทดสอบเด็ก 10 kg เปิด Amoxicillin ออกมาเป็น 500 mg q24h ทั้งที่ 50 mg/kg/day ต้องแบ่งมื้อ q8h หรือ q12h — ต้องตรวจสอบสูตรยาเด็กของยาทุกตัวในฐานข้อมูลให้ถูกต้อง 100%"*
* **Survey Finding:** Auto-selection (`CalculatorUiState.selectBestRegimenForPatient`, `calculator_ui_state.dart:75-107`) fixed the default Amoxicillin 10 kg bug and is tested in `test/pediatric_dosing_bug_test.dart`. **However**, two gaps remain:
  1. Only a handful of drugs are tested; there is no systematic sweep across **every pediatric regimen of all 118+ drugs** at standard child weights (`3, 5, 10, 15, 20, 30, 40 kg`).
  2. A clinician/user can still **manually tap an `audience: adult` fixed-dose regimen** while an active patient is a child (`age < 18` or `weight < 25 kg` with unknown age) without seeing a loud warning!

## 2. Goal
1. Write a comprehensive automated sweep test across all drugs and all pediatric weight-based regimens to verify dose-basis arithmetic, frequency consistency, and non-blocking overdose warnings.
2. Add a non-blocking red/amber clinical alert when a user manually selects an `adult` regimen for a pediatric patient (`age < 18` or `weightKg < 25`).
3. Log any anomaly discovered in the sweep into `docs/clinical/PEDIATRIC_AUDIT_FINDINGS.md` for pharmacist verification **without guessing or fabricating clinical numbers**.

## 3. Exact Files & Line Numbers to Touch
* [`lib/core/calculators/pharmacist_calculator.dart`](file:///c:/Users/turbo/drugforPh/lib/core/calculators/pharmacist_calculator.dart) & [`lib/ui/calculator/models/calculator_ui_state.dart`](file:///c:/Users/turbo/drugforPh/lib/ui/calculator/models/calculator_ui_state.dart#L75-L107)
* [NEW] `test/clinical/pediatric_regimen_sweep_test.dart`
* [NEW if any regimen anomalies found] `docs/clinical/PEDIATRIC_AUDIT_FINDINGS.md`

## 4. Implementation Steps
1. Read `PharmacistCalculator.calculateDose` around `regimen.effectiveAudience` handling and `DoseWarningCode`.
2. Add an audience-mismatch check (Rule 5 — **Non-Blocking**):
   - If `patient.ageYears < 18` (or `patient.weightKg < 25 && usedDefaultAge`) and `regimen.effectiveAudience == RegimenAudience.adult`, still compute and display the dose (never block!), AND prepend a prominent warning:
     - TH: `"⚠️ คำเตือน: สูตรยาที่เลือกเป็นขนาดยาสำหรับผู้ใหญ่ แต่ข้อมูลผู้ป่วยปัจจุบันเป็นเด็ก — โปรดตรวจสอบและเลือกสูตรเด็กหรือยืนยันความตั้งใจทางคลินิก"`
     - EN: `"⚠️ Warning: Selected regimen is an Adult dose, but current patient profile is Pediatric — verify selection or confirm clinical override."`
3. Create `test/clinical/pediatric_regimen_sweep_test.dart` iterating over every drug in `DrugDatabase.allDrugs` × every regimen with `effectiveAudience == RegimenAudience.pediatric` across weights `[3.0, 5.0, 10.0, 15.0, 20.0, 30.0, 40.0]` kg:
   - Invariant 1: `result.calculatedDose` is finite and `> 0` (never `NaN` or negative).
   - Invariant 2: If `doseBasis == DoseBasis.perDay` and `!frequency.isOnce` and `frequency.dosesPerDay > 1` (and no renal interval extension triggered), `result.calculatedDose * frequency.dosesPerDay` aligns with `weight * effectiveDosePerKg` (capped at daily max if applicable), never returning raw un-divided daily dose at `q24h`.
   - Invariant 3: `result.structuredFrequency` matches `regimen.frequency` when CrCl is normal (no accidental swap with another regimen's frequency).
   - Invariant 4: If `calculatedDose > maxSingleDose`, `result.isBlocked == false` and an overdose warning is present (Rule 5).
4. Record any anomalies in `docs/clinical/PEDIATRIC_AUDIT_FINDINGS.md` with `TODO(clinical-source)`.

## 5. Acceptance Criteria
* Pediatric sweep test runs cleanly across all pediatric regimens in `DrugDatabase.allDrugs` at all 7 weights.
* Selecting an adult regimen for a 10 kg / 2-year-old child displays a clear non-blocking mismatch warning while still showing the calculated number.
* Any clinical number issues discovered are documented cleanly rather than guessed.

## 6. Automated Verification Commands
```powershell
cd c:\Users\turbo\drugforPh
flutter analyze
flutter test test/clinical/pediatric_regimen_sweep_test.dart test/pediatric_dosing_bug_test.dart
flutter test --no-pub -r compact
```

## 7. Forbidden Actions
* Do NOT block or hide `calculatedDose` when an adult regimen is selected for a child (violates Rule 5).
* Do NOT alter textbook dose values (`dosePerKg`, `maxSingleDose`) without citing a verified source from `AGENTS.md`.
