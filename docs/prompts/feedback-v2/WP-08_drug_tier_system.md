# WP-08: Drug Tier System (`Core` / `Extended` / `ReferenceOnly`) & Core Formulary Draft

## 1. Context & Pharmacist Feedback Reference
* **Covers:** `FB-21`, Q1, Q2
* **Pharmacist Feedback:** *"โปรเจคค่อนข้างกว้างเลย น่าจะโฟกัสที่ยาฉีดใน รพ. หรือยาน้ำของเด็ก... ตัดยามะเร็งและ Tacrolimus ทิ้ง... ควรเลือกยากลุ่มละ 1–3 ตัวที่เป็นยาพื้นฐานแต่ทำข้อมูลให้สมบูรณ์แบบ 100% ก่อน"*
* **Locked Decisions (Q1 & Q2):**
  - Focus **Core** on Pediatric drugs + Hospital Injectables.
  - **Delete NOTHING.** Assign every drug a tier (`core`, `extended`, `referenceOnly`), placing Heparin in `extended` for now (hospital-specific protocols) and keeping the 4 archived specialty drugs (`Carboplatin`, `Methotrexate`, `Tacrolimus`, `Mycophenolate Mofetil`) in `referenceOnly`.

## 2. Goal
Add `enum DrugTier { core, extended, referenceOnly }` across the domain model and `HomeScreen` catalog filter chips (defaulting to `Core`), block automated dose calculation for `referenceOnly` drugs (showing monograph + specialist protocol notice instead), and produce `docs/clinical/CORE_FORMULARY_V1.md` for pharmacist confirmation.

## 3. Exact Files & Line Numbers to Touch
* [`lib/core/models/drug.dart`](file:///c:/Users/turbo/drugforPh/lib/core/models/drug.dart) (add `enum DrugTier` and `final DrugTier tier;` field on `Drug`, or a registry mapping in `lib/core/domain/drug_tier_registry.dart` if safer — check backward compatibility across all 122 constructors!)
* [`lib/core/calculators/pharmacist_calculator.dart`](file:///c:/Users/turbo/drugforPh/lib/core/calculators/pharmacist_calculator.dart) (return reference-only result state when `tier == DrugTier.referenceOnly`)
* [`lib/data/drug_database.dart`](file:///c:/Users/turbo/drugforPh/lib/data/drug_database.dart)
* [`lib/ui/home_screen.dart`](file:///c:/Users/turbo/drugforPh/lib/ui/home_screen.dart) (add tier filter chips `Core (Pediatric & IV)` | `Extended` | `All`, default = `Core`, plus clear badge on `Extended` drugs)
* [`lib/ui/calculator/calculator_screen.dart`](file:///c:/Users/turbo/drugforPh/lib/ui/calculator/calculator_screen.dart) (show `"Extended — not yet verified at Core level"` notice when `tier == extended`, or `"Reference Only"` card when `referenceOnly`)
* [NEW] `docs/clinical/CORE_FORMULARY_V1.md`
* [NEW] `test/clinical/drug_tier_system_test.dart`

## 4. Implementation Steps
1. Create `enum DrugTier { core, extended, referenceOnly }` and a central exhaustive mapping for all 122 drugs (`DrugTierRegistry.tierFor(drugId)` or field with default `DrugTier.extended` + explicit Core & ReferenceOnly sets verified by unit test so zero drugs are left unclassified).
2. Candidate Core Formulary V1 draft (document in `docs/clinical/CORE_FORMULARY_V1.md` as **Draft awaiting pharmacist confirmation**):
   - Pediatric & Oral Liquids / Common Acute: `paracetamol`, `ibuprofen`, `naproxen`, `amoxicillin`, `amoxicillin_clavulanate`, `azithromycin`, `cephalexin`, `ceftriaxone`, `cefazolin`, `gentamicin`, `vancomycin`, `acyclovir`, `salbutamol`, `prednisolone`, `dexamethasone`
   - Hospital Injectables / Resuscitation / ICU: `epinephrine`, `atropine`, `adenosine`, `amiodarone`, `midazolam`, `diazepam`, `phenytoin`, `levetiracetam`, `morphine`, `fentanyl`, `naloxone`, `norepinephrine`, `dopamine`, `dobutamine`, `magnesium_sulfate`, `calcium_gluconate`, `potassium_chloride`, `furosemide`, `insulin_regular`
   - Missing common pediatric drugs to flag as `TODO(pharmacist-confirm)` (do NOT fabricate numbers): `Ampicillin`, `Cloxacillin`, `Ondansetron`, `Oseltamivir`
   - `heparin` -> `DrugTier.extended` (hospital-specific nomograms; move to configurable protocol in WP-15)
   - `carboplatin`, `methotrexate`, `tacrolimus`, `mycophenolate` -> `DrugTier.referenceOnly`
3. Update `HomeScreen` to show `Core | Extended | All` filter chips (keep `All` accessible and ensure existing `HomeScreen` tests that search for an Extended drug either fall back nicely or search across All when query is non-empty — check `test/home_screen_test.dart` / `test/` before changing default search behavior!).
4. Add `test/clinical/drug_tier_system_test.dart` (`FB-21`) asserting:
   - Every single drug in `DrugDatabase.allDrugs` + `archivedSpecialtyDrugs` has an explicit tier assignment.
   - `referenceOnly` drugs cannot emit an automatic dose calculation and instead display the specialist protocol notice.
   - `heparin` is in `extended`.

## 5. Acceptance Criteria
* 100% of drugs have a deterministic `DrugTier`.
* `Core` filter highlights pediatric + hospital injectables; `Extended` shows secondary badge; `ReferenceOnly` shows monograph only.
* Zero existing `HomeScreen` search tests break.

## 6. Automated Verification Commands
```powershell
cd c:\Users\turbo\drugforPh
flutter analyze
flutter test test/clinical/drug_tier_system_test.dart test/drug_list_curation_test.dart
flutter test --no-pub -r compact
```

## 7. Forbidden Actions
* Do NOT delete any drug from `DrugDatabase` (Q2).
* Do NOT invent doses for missing candidate drugs (`Ampicillin`, `Cloxacillin`, `Ondansetron`, `Oseltamivir`) — list them only as proposals in `CORE_FORMULARY_V1.md`.
