# Clinical Advisor Program & Per-Batch Verification Guide (`WP-13`)

> **Purpose:** Streamlined **30-minute per-batch clinical review** pack for Thai Clinical Pharmacists (`ภก.`) and Pediatricians / Attending Physicians (`ว.`) to audit and formally sign off Drugph Core Formulary V1 (`34` drugs).  
> **Release Gate (`Q5`):** **$\ge 80\%$ of Core drugs (`>= 28 / 34`)** must achieve **100% signed-off active regimens** in [`assets/data/verification_ledger.json`](file:///c:/Users/turbo/drugforPh/assets/data/verification_ledger.json) before any hospital pilot deployment.

---

## 1. Per-Batch Review Cadence (30 Minutes / Batch)

All **34 Core Formulary V1 drugs** split cleanly into **7 review batches** (`5` drugs per batch; Batch 7 contains `4` drugs). Generate any batch dossier PDF on demand:

```powershell
# Generate a single 5-drug review dossier (e.g., Batch 1)
dart run tool/generate_pharmacist_dossier_pdf.dart --tier core --batch 1 --batch-size 5

# Generate all 7 Core review batches into review/batches/
dart run tool/generate_pharmacist_dossier_pdf.dart --tier core --batch all --batch-size 5

# Keep full 48-page reference dossier synchronized (unchanged default behavior)
dart run tool/generate_pharmacist_dossier_pdf.dart

# Inspect CLI help
dart run tool/generate_pharmacist_dossier_pdf.dart --help
```

| Batch | Command | Drug Count | Estimated Review Time | Focus Area |
| :---: | :--- | :---: | :---: | :--- |
| **01** | `--tier core --batch 1` | 5 | ~30 min | Batch 1 Core analgesics / acute pediatrics |
| **02** | `--tier core --batch 2` | 5 | ~30 min | Batch 2 Core antimicrobials & pediatric PO |
| **03** | `--tier core --batch 3` | 5 | ~30 min | Batch 3 Core antimicrobials & antivirals |
| **04** | `--tier core --batch 4` | 5 | ~30 min | Batch 4 Cardiovascular & IV resuscitation |
| **05** | `--tier core --batch 5` | 5 | ~30 min | Batch 5 Emergency / ICU & antidotes |
| **06** | `--tier core --batch 6` | 5 | ~30 min | Batch 6 Neurology / Sedation / Respiratory |
| **07** | `--tier core --batch 7` | 4 | ~25 min | Batch 7 Respiratory / Electrolytes / Insulin |

---

## 2. Clinical Audit Rubric (Per `AGENTS.md` & `VERIFICATION_PROTOCOL.md`)

For every regimen ID (`drug_id` + `regimen_id`) printed in the batch PDF table, reviewers verify:
1. **Dosing Basis Accuracy:** `perDose` (`mg/kg/dose`) vs `perDay` (`mg/kg/day` divided `q8h`/`q12h`) matches *Lexicomp Pediatric & Neonatal Dosage Handbook* / *The Sanford Guide 2024* / *AHA ACLS & PALS* (`Rule 1` & `Rule 2`).
2. **Dose Ceilings & Non-Blocking Overdose:** Confirm `maxSingleDose`, `maxDailyDose`, or `doseCap` boundaries and review the 7 pediatric regimens logged in [`PEDIATRIC_AUDIT_FINDINGS.md`](file:///c:/Users/turbo/drugforPh/docs/clinical/PEDIATRIC_AUDIT_FINDINGS.md) (`Rule 5`).
3. **Renal & Hepatic Criteria:** Check Cockcroft-Gault / Schwartz CrCl tier intervals (`crclMin <= CrCl < crclMax` with zero gaps) and hepatic Child-Pugh B/C cautions.
4. **IV Diluent & Infusion Compatibility:** Confirm compatible/incompatible diluents (`NSS`, `D5W`, `LRS`), concentration, and infusion duration against *Ramathibodi / Siriraj High-Alert IV Guides*.
5. **Open Institutional Decisions:** For batches containing `acyclovir`, `atropine`, `dexamethasone`, `epinephrine`, `salbutamol`, or aminoglycoside/vancomycin TDM, mark institutional option choice in [`Pending_Pharmacist_Signoff_Checklist.md`](file:///c:/Users/turbo/drugforPh/review/Pending_Pharmacist_Signoff_Checklist.md) (`DEC-PND-001`–`006`).

---

## 3. Recording Formal Sign-Off in `verification_ledger.json`

After a reviewer physically/digitally signs a batch sheet, record **every approved regimen** in [`assets/data/verification_ledger.json`](file:///c:/Users/turbo/drugforPh/assets/data/verification_ledger.json):

```json
{
  "drug_id": "amoxicillin",
  "regimen_id": "po__standard_infection_adult",
  "verified": true,
  "verified_by": "ภก. <ชื่อ-นามสกุลจริง>",
  "license_no": "ภก.XXXXX",
  "verified_date": "2026-11-20",
  "source_checked": "The Sanford Guide 2024 p.XX / Drug Information Handbook (Lexicomp / APhA)"
}
```

### Strict Anti-Hallucination & Badge Rules (`SchemaValidator`)
* **100% Active Regimens Required:** A drug only displays the green **Verified** badge on `CalculatorScreen`, `HomeScreen`, and `ClinicalEvidenceSheet` when **every active regimen** of that drug has `"verified": true` in the ledger. Partially signed drugs stay on the amber warning banner (`รอเภสัชกรตรวจสอบรับรอง (Not yet verified by a pharmacist)`).
* **Mandatory Attribution:** `SchemaValidator.validateLedgerEntry` rejects placeholder names (`Pending`, `TBD`, `Test`), missing/malformed Thai medical licenses (must match `ภก.XXXXX`, `ภ. XXXXX`, or `ว.XXXXX`), invalid calendar ISO dates (`YYYY-MM-DD`), or `(Pending)` left inside `source_checked`.
* **Pilot Gate Verification:** Run `flutter test test/clinical/verification_ledger_test.dart` after recording advisor signatures to verify ledger integrity and track coverage toward the `>= 80%` pilot release threshold.
