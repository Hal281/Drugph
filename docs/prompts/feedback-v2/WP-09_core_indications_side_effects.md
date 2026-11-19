# WP-09: Expand Indications (>= 2–3 per Core Drug) & Structured Side Effects

## 1. Context & Pharmacist Feedback Reference
* **Covers:** `FB-03`, `FB-16`, `FB-22`
* **Pharmacist Feedback:**
  - *"ยาแต่ละตัวมีข้อบ่งใช้หลายโรค ควรเติมให้มีอย่างน้อย 2–3 ข้อบ่งใช้ต่อยา 1 ตัว (เช่น Amoxicillin หูชั้นกลางอักเสบ 80 mg/kg/day vs ติดเชื้อทั่วไป 25–50 mg/kg/day; Amitriptyline นอนหลับ vs ซึมเศร้า vs ป้องกันไมเกรน)"*
  - *"ต้องมีผลข้างเคียง (Side Effects) ในหน้าข้อมูลยา"*

## 2. Goal
Bring every **Core Formulary** drug (defined in WP-08) up to `>= 2–3` evidence-backed `DosingRegimen` entries (where clinically applicable) and populate structured `commonSideEffects` / `seriousSideEffects` fields on `Drug` for clean UI rendering in WP-11.

## 3. Exact Files & Line Numbers to Touch
* [`lib/core/models/drug.dart`](file:///c:/Users/turbo/drugforPh/lib/core/models/drug.dart) (add optional `List<String> commonSideEffects`, `List<String> seriousSideEffects` or structured TH/EN side-effect fields on `Drug`)
* `lib/data/drugs/antibiotics.dart`, `analgesics.dart`, `cardiovascular.dart`, `emergency.dart`, `neurology.dart`, `respiratory.dart`, `psychiatry.dart` (execute in **batches of 5 Core drugs per PR/step**)
* [NEW] `docs/clinical/INDICATION_EXPANSION_LOG.md` (track citation + `PENDING_PHARMACIST_VERIFICATION` per regimen added)
* [NEW] `test/clinical/core_indications_coverage_test.dart`

## 4. Implementation Steps
1. **Strict Evidence Rule (Rule 2):** Do NOT guess doses. For every added indication regimen or side-effect entry, verify against priority sources:
   1. Lexicomp *Drug Information Handbook* / *Pediatric & Neonatal Dosage Handbook*
   2. BNF for Children (BNFc)
   3. Sanford Guide / IDAT (antimicrobials) / Rama/Siriraj IV manuals
   If you cannot verify a textbook number during the run, put `TODO(clinical-source)` in `INDICATION_EXPANSION_LOG.md` and skip adding unverified numbers.
2. Process Core drugs in **batches of 5** (starting with Batch 1: `amoxicillin`, `amoxicillin_clavulanate`, `paracetamol`, `ibuprofen`, `amiodarone`; Batch 2: `ceftriaxone`, `gentamicin`, `vancomycin`, `acyclovir`, `furosemide`, etc.).
3. Add explicit `commonSideEffects` / `seriousSideEffects` (TH + EN) and `sourceCitation` on each batch.
4. Set verification metadata / provenance on modified regimens to `PENDING_PHARMACIST_VERIFICATION` (`sourceVerified: false` until WP-13 sign-off).
5. Add `test/clinical/core_indications_coverage_test.dart` (`FB-22`) checking that Core drugs with multi-indication therapy have `>= 2` regimens, non-empty `commonSideEffects`, valid `DoseBasis`, and non-empty `sourceCitation`.

## 5. Acceptance Criteria
* Every completed Core drug batch has textbook-cited indications, valid `DoseBasis` (`perDose` vs `perDay`), and structured `commonSideEffects` / `seriousSideEffects`.
* All new doses remain flagged `PENDING_PHARMACIST_VERIFICATION` (never falsely marked verified).
* Zero regression across all 1,179+ tests.

## 6. Automated Verification Commands
```powershell
cd c:\Users\turbo\drugforPh
flutter analyze
flutter test test/clinical/core_indications_coverage_test.dart test/clinical/pediatric_regimen_sweep_test.dart
flutter test --no-pub -r compact
```

## 7. Forbidden Actions
* **NEVER** invent or extrapolate dosing numbers, frequencies, or max limits from memory without a cited textbook reference.
* Do NOT modify `golden_test_cases.json` verification flags.
