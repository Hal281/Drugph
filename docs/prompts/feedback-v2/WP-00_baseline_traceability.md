# WP-00: Baseline Tests & Feedback Traceability Matrix

## 1. Context & Pharmacist Feedback Reference
* **Covers:** `FB-01` .. `FB-23` baseline tracking
* **Context:** Prior commits (`81b0b78`, `6237be5`, `87a330f`) already resolved several pharmacist feedback items (`Naloxone` moved to `antidote`, Amoxicillin 10 kg bug fixed, multi-indication `DosingRegimen` selector added, duplicate patient input hidden when `PatientSession` is active, static DDI list removed, and references card moved to AppBar). All executing AIs must verify the baseline before editing.

## 2. Goal
Maintain [`docs/feedback/FEEDBACK_TRACEABILITY.md`](file:///c:/Users/turbo/drugforPh/docs/feedback/FEEDBACK_TRACEABILITY.md) as the single source of truth for `FB-01`..`FB-23` status, confirm the baseline test suite (`>= 1,179` passing), and keep it updated after each WP finishes.

## 3. Exact Files & Line Numbers to Touch
* [`docs/feedback/FEEDBACK_TRACEABILITY.md`](file:///c:/Users/turbo/drugforPh/docs/feedback/FEEDBACK_TRACEABILITY.md) (Update status, test file, and commit SHA per WP)

## 4. Implementation Steps
1. Read [`00_MASTER_CONTEXT.md`](file:///c:/Users/turbo/drugforPh/docs/prompts/feedback-v2/00_MASTER_CONTEXT.md) and [`FEEDBACK_TRACEABILITY.md`](file:///c:/Users/turbo/drugforPh/docs/feedback/FEEDBACK_TRACEABILITY.md).
2. Run `flutter analyze` and `flutter test --no-pub -r compact` on a clean checkout to confirm the baseline (`>= 1,179` tests passing, 0 analyzer errors).
3. Verify the already-fixed baseline assertions exist and pass:
   - `test/drug_list_curation_test.dart` (`FB-01`, `FB-07`)
   - `test/pediatric_dosing_bug_test.dart` (`FB-02`)
   - `test/ui/patient_profile_layout_test.dart` (`FB-04`)
   - `test/ui/calculator_references_and_interactions_test.dart` (`FB-05`, `FB-06`)
4. Update the `Commit`, `Status`, and `Baseline` table rows in `FEEDBACK_TRACEABILITY.md` whenever WPs land.

## 5. Acceptance Criteria
* `FEEDBACK_TRACEABILITY.md` accurately reflects the current git commit SHA and test count (`>= 1,179`).
* Every `Done` item links directly to its verification test file.

## 6. Automated Verification Commands
```powershell
cd c:\Users\turbo\drugforPh
flutter analyze
flutter test --no-pub -r compact
```

## 7. Forbidden Actions
* Do NOT edit clinical formulas or drug definitions in this WP.
* Do NOT delete or relax any existing test assertion.
