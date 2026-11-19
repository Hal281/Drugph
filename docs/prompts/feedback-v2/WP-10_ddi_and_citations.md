# WP-10: Common Clinical DDI Curation & `Drug Information Handbook` Citation Upgrade

## 1. Context & Pharmacist Feedback Reference
* **Covers:** `FB-18`, `FB-20`
* **Pharmacist Feedback:**
  - `FB-18`: *"รายการ Severe Interaction ของ Amoxicillin (Methotrexate, Probenecid, Allopurinol) ไม่ค่อยพบบ่อยในเคสทั่วไป ควรคัดเฉพาะคู่ยาที่พบบ่อยจริง (Most Common)"*
  - `FB-20`: *"ไม่ควรดึงข้อมูลดิบจาก OpenFDA ที่บางครั้งไม่ละเอียด... แนะนำให้อ้างอิงตำรา Drug Information Handbook (Lexicomp/APhA) ฉบับปีล่าสุดที่เภสัชกรไทยใช้เปิดจริง"*

## 2. Goal
1. Rank/categorize drug interactions (`common` vs `lessCommon`) so `PrescriptionCartScreen` and multi-drug DDI checks prioritize **high-frequency clinical DDI pairs** (e.g. `Amoxicillin` + `Warfarin` INR elevation with textbook citation, keeping `Methotrexate`/`Probenecid`/`Allopurinol` tagged appropriately as less common / special-population rather than deleting real interactions).
2. Add `Drug Information Handbook (Lexicomp/APhA)` as a first-class citation structure in drug monographs and `ClinicalEvidenceSheet` (`lib/ui/widgets/clinical_evidence_sheet.dart`).

## 3. Exact Files & Line Numbers to Touch
* `lib/core/models/drug_interaction.dart` (check existing `DrugInteraction` class and `InteractionSeverity`; add optional `bool isCommonInPractice = true` or `InteractionFrequencyTier`)
* `lib/data/drugs/antibiotics.dart` (Amoxicillin & Core antibiotics DDI entries)
* `lib/core/models/therapeutic_duplication.dart` (`ClinicalInteractionRegistry`)
* `lib/ui/widgets/clinical_evidence_sheet.dart`
* [NEW] `test/clinical/ddi_and_citation_test.dart`

## 4. Implementation Steps
1. Read `lib/core/models/drug.dart` / `drug_interaction.dart` and `lib/data/drugs/antibiotics.dart` around `amoxicillin` interactions.
2. Verify any new DDI pair (such as `Amoxicillin` + `Warfarin` broad-spectrum antibiotic INR potentiation via gut flora vitamin K reduction) in Lexicomp / *Drug Information Handbook* and add `source`, `mechanismTh/En`, `managementTh/En`, and frequency tag. Keep real interactions (`Methotrexate`, `Probenecid`, `Allopurinol`) marked appropriately so safety coverage is not reduced while common pairs surface first in cart summaries.
3. Update `ClinicalEvidenceSheet` (`lib/ui/widgets/clinical_evidence_sheet.dart`) to cleanly format *Drug Information Handbook (Lexicomp/APhA)* citations alongside Thai clinical guidelines (Sanford, Thai Renal Society, IDAT, RDU, Rama/Siriraj IV manuals).
4. Add unit + widget tests (`FB-18`, `FB-20`).

## 5. Acceptance Criteria
* Multi-drug DDI checks sort/prioritize common clinical interactions first while preserving true less-common major interactions.
* Every Core drug DDI & monograph citation identifies its textbook/edition clearly.
* Static DDI list remains absent from the single-drug calculator header (`FB-05`).

## 6. Automated Verification Commands
```powershell
cd c:\Users\turbo\drugforPh
flutter analyze
flutter test test/clinical/ddi_and_citation_test.dart test/ui/calculator_references_and_interactions_test.dart
flutter test --no-pub -r compact
```

## 7. Forbidden Actions
* Do NOT re-introduce a static DDI list onto single-drug screens (`FB-05`).
* Do NOT fabricate DDI mechanisms or severity ratings without a textbook citation.
