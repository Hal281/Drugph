# Core Formulary V1 Draft (`WP-08` / `FB-21`)

> **Status:** **Draft awaiting Thai clinical pharmacist confirmation (`WP-13`)**  
> **Product Identity (`Q1`):** Pediatric Dosing + Hospital Injectables  
> **Non-Deletion Policy (`Q2`):** Zero drugs deleted from `DrugDatabase`; all `123` catalog drugs (`119` active + `4` archived specialty) carry a deterministic `DrugTier` via `lib/core/domain/drug_tier_registry.dart`.

---

## 1. Tier Summary
| Tier | Count | Description | Calculator Behavior |
| :--- | :---: | :--- | :--- |
| **`DrugTier.core`** | **34** | Pediatric oral liquids, acute pediatric care, and hospital IV/ICU injectables | Default Home view; prioritized for indication expansion (`WP-09`) and first-wave pharmacist sign-off (`WP-13`) |
| **`DrugTier.extended`** | **85** | Adult/general formulary drugs (including `heparin` pending hospital nomogram support in `WP-15`) | Searchable across all tiers; displays non-blocking amber `Extended Formulary` notice on calculator |
| **`DrugTier.referenceOnly`** | **4** | High-complexity oncology & transplant drugs (`carboplatin`, `methotrexate`, `tacrolimus`, `mycophenolate`) | Searchable for monograph reference; automated bedside dosing disabled (`enforceReferenceOnlyGate: true`) |
| **Total** | **123** | 100% exhaustive coverage (`DrugDatabase.allCatalogDrugs`) | Verified by `test/clinical/drug_tier_system_test.dart` |

---

## 2. Draft Core Formulary V1 (34 Drugs)

### A. Pediatric & Oral Liquids / Common Acute Care (15)
1. `paracetamol` — Paracetamol (Acetaminophen)
2. `ibuprofen` — Ibuprofen
3. `naproxen` — Naproxen
4. `amoxicillin` — Amoxicillin
5. `amoxicillin_clavulanate` — Amoxicillin / Clavulanate
6. `azithromycin` — Azithromycin
7. `cephalexin` — Cephalexin
8. `ceftriaxone` — Ceftriaxone
9. `cefazolin` — Cefazolin
10. `gentamicin` — Gentamicin
11. `vancomycin` — Vancomycin
12. `acyclovir` — Acyclovir
13. `salbutamol` — Salbutamol
14. `prednisolone` — Prednisolone
15. `dexamethasone` — Dexamethasone

### B. Hospital Injectables / Resuscitation / ICU (19)
16. `epinephrine` — Epinephrine (Adrenaline)
17. `atropine` — Atropine
18. `adenosine` — Adenosine
19. `amiodarone` — Amiodarone
20. `midazolam` — Midazolam
21. `diazepam` — Diazepam
22. `phenytoin` — Phenytoin
23. `levetiracetam` — Levetiracetam
24. `morphine` — Morphine
25. `fentanyl` — Fentanyl
26. `naloxone` — Naloxone
27. `norepinephrine` — Norepinephrine
28. `dopamine` — Dopamine
29. `dobutamine` — Dobutamine
30. `magnesium_sulfate` — Magnesium Sulfate
31. `calcium_gluconate` — Calcium Gluconate
32. `potassium_chloride` — Potassium Chloride (KCl)
33. `furosemide` — Furosemide
34. `insulin_regular` — Insulin Regular (RI)

---

## 3. Candidate Additions & Promotions Pending Pharmacist Review
* **`ondansetron`** *(already in `DrugDatabase` under `Extended`)*: `TODO(pharmacist-confirm)` — Promote to `Core` for pediatric/hospital antiemetic IV/PO use?
* **`Ampicillin`** *(not yet in catalog)*: `TODO(pharmacist-confirm)` — Add pediatric/neonatal IV ampicillin once textbook protocols are verified in Phase 5 (`WP-14`).
* **`Cloxacillin`** *(not yet in catalog)*: `TODO(pharmacist-confirm)` — Add common Thai pediatric MSSA oral/IV regimen after Thai IDAT/Lexicomp verification.
* **`Oseltamivir`** *(not yet in catalog)*: `TODO(pharmacist-confirm)` — Add weight-banded pediatric influenza dosing after Thai MOPH/CDC verification.
* **`heparin`** *(currently `Extended`)*: `TODO(pharmacist-confirm)` — Keep in `Extended` until hospital-specific weight/aPTT nomograms (`HospitalProfile` in `WP-15`) are configurable.
