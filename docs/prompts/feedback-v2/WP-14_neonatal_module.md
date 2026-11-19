# WP-14: Neonatal Dosing Module (`< 28 Days` — PNA / GA / Birth Weight Bands)

## 1. Context & Pharmacist Feedback Reference
* **Covers:** Q7 (Phase 5 — after Core Pediatric is verified)
* **Pharmacist Feedback (Chat 2 & 3 — Medscape screenshot):** *"ใน Medscape ขนาดยาเด็ก/ทารกแรกเกิด (<28 วัน) เช่น แยก <1.2 kg, 1.2–2 kg, >2 kg และ <7 วัน vs >7 วัน ต้องเปิดดูแล้วมากดคำนวณเอง — อันนี้ดูได้ใช้จริง แบบเอาไปช่วยคำนวณขนาดยาเด็ก"*
* **Safety Gate:** Neonates carry extremely high medication-error risk (e.g., narrow weight bands, `0.01 mL` dosing, renal immaturity, PNA/GA dosing intervals). **MUST NOT ship to production/pilot until every neonatal dose band is signed off by a pediatric/NICU pharmacist and neonatologist.**

## 2. Goal
Design and implement a pure, deterministic neonatal dosing table engine supporting **Postnatal Age (PNA in days)**, **Gestational Age (GA in weeks)** / **Postmenstrual Age (PMA in weeks)**, and **Birth/Current Weight (`< 1.2 kg`, `1.2–2.0 kg`, `> 2.0 kg`)**, starting with NICU priority drugs once clinical sources are curated.

## 3. Exact Files & Line Numbers to Touch
* [NEW] `lib/core/models/neonatal_dose_band.dart` (`NeonatalDoseBand`, `NeonatalAgeMode`, pure matcher)
* [NEW] `lib/core/calculators/neonatal_calculator.dart` (pure function + syringe `0.01 mL` precision reuse)
* [`lib/core/models/patient.dart`](file:///c:/Users/turbo/drugforPh/lib/core/models/patient.dart) (add optional `int? postnatalAgeDays`, `int? gestationalAgeWeeks`, `double? birthWeightKg`)
* [`lib/ui/widgets/patient_edit_dialog.dart`](file:///c:/Users/turbo/drugforPh/lib/ui/widgets/patient_edit_dialog.dart) (conditional neonatal fields when age == `0 years` and `< 1 month`)
* [NEW] `docs/clinical/NEONATAL_FORMULARY_PROTOCOL.md`
* [NEW] `test/clinical/neonatal_dose_band_test.dart`

## 4. Implementation Steps
1. Model `NeonatalDoseBand`:
   - `pnaDaysMin` (inclusive) / `pnaDaysMax` (exclusive or inclusive — explicitly document and enforce **zero boundary gaps**!)
   - `gaWeeksMin` / `gaWeeksMax` (or `pmaWeeksMin` / `pmaWeeksMax`)
   - `weightKgMin` / `weightKgMax` (e.g., `< 1.2`, `1.2–2.0`, `> 2.0`)
   - `dosePerKg`, `doseUnit`, `intervalHours`, `citation`, `verifiedBy`
2. Build pure `NeonatalCalculator.matchBand(...)` + boundary validation tests proving **zero decimal/integer boundary gaps** (exact match at `7 days`, `28 days`, `1.2 kg`, `2.0 kg`, `32 weeks GA`, etc.).
3. Reuse `0.01 mL` precision rounding and `< 0.05 mL` dilution alerts from `TransparentDosageCalculator` (`MEMORY.md` Bug 6 pattern).
4. Curate starter NICU drug list ONLY from verified **Neofax / Lexicomp Pediatric & Neonatal Dosage Handbook / BNFc** tables (`Ampicillin`, `Gentamicin`, `Vancomycin`, `Cefotaxime`/`Ceftazidime`, `Caffeine citrate`, `Phenobarbital`), each flagged `PENDING_PHARMACIST_VERIFICATION` and blocked from "Verified" release UI until WP-13 ledger sign-off exists.
5. Add exhaustive boundary unit tests in `test/clinical/neonatal_dose_band_test.dart`.

## 5. Acceptance Criteria
* Zero boundary gaps across all age/weight/GA band tables (verified by automated sweep over fractional boundaries like `1.19`, `1.20`, `1.99`, `2.00` kg and `6`, `7`, `8`, `27`, `28` days).
* All neonatal regimens require explicit WP-13 sign-off before clearing the verification warning banner.

## 6. Automated Verification Commands
```powershell
cd c:\Users\turbo\drugforPh
flutter analyze
flutter test test/clinical/neonatal_dose_band_test.dart
flutter test --no-pub -r compact
```

## 7. Forbidden Actions
* **NEVER** copy unverified Medscape screenshots into production data without cross-checking Neofax / Lexicomp Pediatric & Neonatal Dosage Handbook and attaching formal citations.
* **NEVER** enable `Bedside Schwartz` or `Cockcroft-Gault` for `< 28 days` neonates.
