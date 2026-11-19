# WP-13: Clinical Advisor Program & Per-Batch Pharmacist Sign-Off Pipeline (Phase 4)

## 1. Context & Pharmacist Feedback Reference
* **Covers:** Q5 (Startup Gate — Mandatory before any hospital pilot)
* **Problem:** Currently all 15 golden cases (`test/golden/golden_test_cases.json`) and 3 KB drugs (`assets/data/drug_knowledge_base.json`) are `source_verified: false` (`PENDING_HUMAN_VERIFICATION`), and no pharmacist is formally signing off yet. Selling or piloting in a hospital without real pharmacist/physician verification violates `AGENTS.md` Rule 2 and clinical governance.

## 2. Goal
1. **Operational (User):** Recruit at least 1 clinical pharmacist and 1 pediatrician as Clinical Advisors (30-minute batch review format).
2. **Engineering (AI):** Upgrade `tool/generate_pharmacist_dossier_pdf.dart` to generate manageable **5-drug batch review dossiers**, introduce `assets/data/verification_ledger.json` tracking per-regimen sign-off (`drugId`, `regimenId`, `verified_by`, `license_no`, `verified_date`, `source_checked`), and enforce a strict UI gate (`verified` green badge vs persistent `"Not yet verified by a pharmacist"` banner).

## 3. Exact Files & Line Numbers to Touch
* [`tool/generate_pharmacist_dossier_pdf.dart`](file:///c:/Users/turbo/drugforPh/tool/generate_pharmacist_dossier_pdf.dart) (inspect CLI args/structure first; add `--batch <n>` / `--batch-size 5` / `--tier core` support)
* [NEW] `assets/data/verification_ledger.json` (initial schema + empty/unverified entries for Core drugs)
* [`lib/core/models/verified_drug_schema.dart`](file:///c:/Users/turbo/drugforPh/lib/core/models/verified_drug_schema.dart) & [`lib/core/validators/schema_validator.dart`](file:///c:/Users/turbo/drugforPh/lib/core/validators/schema_validator.dart)
* [`lib/core/domain/pending_pharmacist_registry.dart`](file:///c:/Users/turbo/drugforPh/lib/core/domain/pending_pharmacist_registry.dart)
* [`lib/ui/calculator/calculator_screen.dart`](file:///c:/Users/turbo/drugforPh/lib/ui/calculator/calculator_screen.dart) (banner when any active regimen lacks ledger sign-off)
* [NEW] `docs/clinical/CLINICAL_ADVISOR_PACK.md` (onboarding guide + review checklist for the Clinical Advisor)
* [NEW] `test/clinical/verification_ledger_test.dart`

## 4. Implementation Steps
1. Read `tool/generate_pharmacist_dossier_pdf.dart` and `lib/core/domain/pending_pharmacist_registry.dart`.
2. Design `assets/data/verification_ledger.json`:
   ```json
   {
     "schema_version": "1.0.0",
     "entries": [
       {
         "drug_id": "amoxicillin",
         "regimen_id": "standard_pediatric",
         "verified": false,
         "verified_by": null,
         "license_no": null,
         "verified_date": null,
         "source_checked": "Lexicomp Drug Information Handbook (Pending)"
       }
     ]
   }
   ```
3. Extend `SchemaValidator` / `VerificationLedger` so a drug only renders the **verified green badge** when **100% of its active regimens** have `verified: true`, non-empty `verified_by`, valid `license_no` (e.g. `ภก.XXXXX` / `ว.XXXXX`), and `YYYY-MM-DD` `verified_date`. Otherwise, always display the non-verified amber notice `"รอเภสัชกรตรวจสอบรับรอง (Not yet verified by a pharmacist)"`.
4. Add `--batch` / `--tier core` flags to `tool/generate_pharmacist_dossier_pdf.dart` to output 5-drug PDFs (plus signature lines per drug).
5. Write unit + widget tests (`WP-13`) verifying ledger parsing, strict license/date validation, and UI banner gating.

## 6. Automated Verification Commands
```powershell
cd c:\Users\turbo\drugforPh
flutter analyze
dart run tool/generate_pharmacist_dossier_pdf.dart --help
flutter test test/clinical/verification_ledger_test.dart test/golden_verification_test.dart
flutter test --no-pub -r compact
```

## 7. Forbidden Actions
* **NEVER** pre-populate fake `verified_by`, fake license numbers, or set `verified: true` in `verification_ledger.json` or `golden_test_cases.json` without an actual signed human review!
* Do NOT allow a pilot release gate to pass when `< 80%` of Core drugs are verified.
