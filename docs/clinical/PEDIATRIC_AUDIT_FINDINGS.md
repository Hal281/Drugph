# Pediatric Regimen 7-Weight Sweep Audit Findings (`WP-07` / `FB-02`)

> **Test Suite:** `test/clinical/pediatric_regimen_sweep_test.dart`  
> **Scope:** All `39` pediatric regimens (`effectiveAudience == RegimenAudience.pediatric`) across `DrugDatabase.allDrugs`, evaluated at 7 pediatric weight/age benchmarks: `[3 kg (1m), 5 kg (3m), 10 kg (1y), 15 kg (3y), 20 kg (6y), 30 kg (9y), 40 kg (12y)]` (`263` evaluated cases).  
> **Status:** `263 / 263` evaluated cases succeeded with positive finite doses, correct `DoseBasis.perDay` division across `dosesPerDay`, stable frequency retention under normal renal function, and Rule 5 Non-Blocking Overdose compliance.

---

## 1. Arithmetic & Frequency Integrity Summary
* **Zero `NaN`, zero negative/zero doses, and zero un-divided `perDay` bugs** across all 39 pediatric regimens.
* **Adult ↔ Pediatric Mismatch Safety (`DEC-PED-AUDIENCE-001`):** Selecting an adult-only regimen for a child remains safety-blocked (`DoseWarningCode.pediatricBlocked`) in `PharmacistCalculator.calculateDose` while offering a 1-tap regimen switcher banner in the UI.

---

## 2. Regimens Triggering `maxSingleDose` Overdose Warnings at Higher Pediatric Weights

The following **7 pediatric regimens** have no `doseCap` configured in `DosingRegimen`, so `weight × dosePerKg` exceeds `limits.maxSingleDose` for larger children (triggering a **non-blocking Rule 5 warning** rather than silently capping):

| Drug (`id`) | Regimen Indication | Weight(s) Triggered | Computed Dose vs. `maxSingleDose` | Action Status |
| :--- | :--- | :--- | :--- | :--- |
| `amoxicillin` | Standard Infection (Pediatric) | `40.0 kg` | `600.0 mg` > `500.0 mg` | `TODO(clinical-source)`: Confirm with pharmacist whether to add `doseCap: 500.0` (q8h) vs keep Rule 5 warning |
| `amoxicillin` | Acute Otitis Media / High-Dose (Pediatric) | `30.0 kg`, `40.0 kg` | `1350.0 mg`, `1800.0 mg` > `1000.0 mg` | `TODO(clinical-source)`: Confirm adult ceiling `1000 mg/dose` (2000 mg/day) `doseCap` per AAP AOM / Sanford 2024 |
| `amoxicillin_clavulanate` | Standard Infection (Pediatric) | `40.0 kg` | `900.0 mg` > `875.0 mg` | `TODO(clinical-source)`: Confirm adult ceiling `875 mg/dose` `doseCap` for children ≥ 40 kg |
| `salbutamol` | Asthma / Wheezing (Pediatric < 20kg) | `20.0`, `30.0`, `40.0 kg` | `3.0`, `4.5`, `6.0 mg` > `2.5 mg` | `TODO(clinical-source)`: Add `PopulationCriteria(maxWeightKg: 20.0)` and/or `doseCap: 2.5 mg` after pharmacist review |
| `epinephrine` | Anaphylaxis (Pediatric) | `40.0 kg` | `0.4 mg` > `0.3 mg` | `TODO(clinical-source)`: Confirm PALS `0.3 mg` prepubertal max vs `0.5 mg` adolescent/adult cap (`doseCap`) |
| `atropine` | Bradycardia (Pediatric) | `30.0`, `40.0 kg` | `0.6 mg`, `0.8 mg` > `0.5 mg` | `TODO(clinical-source)`: Confirm AHA PALS single-dose cap (`0.5 mg` child / `1.0 mg` adolescent) |
| `dexamethasone` | Croup (Pediatric) | `20.0`, `30.0`, `40.0 kg` | `12.0`, `18.0`, `24.0 mg` > `10.0 mg` | `TODO(clinical-source)`: Confirm Croup ceiling (`10 mg` or `16 mg` single dose) per AAP / Lexicomp Pediatric |

> **Policy Note:** Per `WP-07` strict EBM rules, none of these textbook `dosePerKg` or `maxSingleDose` numbers were altered automatically. They remain safe under Rule 5 (displaying the computed value alongside the loud red Overdose Warning) until signed off by a clinical pharmacist in Phase 4 (`WP-13`).
