# Core Formulary Indication & Side-Effect Expansion Log (`WP-09` / `FB-03` / `FB-22`)

> **Verification Status:** `PENDING_PHARMACIST_VERIFICATION` (Awaiting Batch-by-Batch Clinical Sign-off in Phase 4 / `WP-13`)  
> **Scope:** All **34 Core Formulary V1 drugs** (`DrugTierRegistry.coreDrugIds`)  
> **Automated Gate:** `test/clinical/core_indications_coverage_test.dart` + `test/clinical/pediatric_regimen_sweep_test.dart` + `test/data_lint_test.dart` (`45/45` targeted test assertions passing; `flutter analyze` = 0 issues)

---

## 1. Model Enhancements (`lib/core/models/drug.dart`)
* Added `List<String> seriousSideEffects` and `List<String> seriousSideEffectsTh` to `Drug` so the UI and Clinical Dossier cleanly distinguish frequent/mild ADRs from red-flag monitorable toxicities (`FB-16`).
* Added `bool get hasSideEffectData` getter checking all four side-effect lists (`sideEffects`, `sideEffectsTh`, `seriousSideEffects`, `seriousSideEffectsTh`).
* Preserved `drug.regimens.first` order for backward compatibility across existing unit tests while appending expanded adult/pediatric indications.

---

## 2. Batch Coverage Across All 34 Core Drugs

### Batch 1 — Pediatric Analgesics & Antipyretics (`lib/data/drugs/analgesics.dart`)
| Drug ID | Common & Serious Side Effects (EN/TH) | Regimen Coverage (`>= 2` verified) | Primary Textbook Citations | Status |
| :--- | :---: | :--- | :--- | :---: |
| `paracetamol` | ✅ | Multiple PO/IV adult & pediatric fever/pain regimens | Lexicomp DIH 2024 / RDU Thailand | `PENDING_PHARMACIST_VERIFICATION` |
| `ibuprofen` | ✅ | Adult & pediatric fever/pain/anti-inflammatory regimens | Lexicomp DIH 2024 / Harriet Lane | `PENDING_PHARMACIST_VERIFICATION` |
| `naproxen` | ✅ | Adult pain/arthritis & pediatric JIA regimens | Lexicomp DIH 2024 | `PENDING_PHARMACIST_VERIFICATION` |
| `morphine` | ✅ | IV/PO acute pain & pediatric regimens | Lexicomp DIH 2024 / Ramathibodi IV Guide | `PENDING_PHARMACIST_VERIFICATION` |
| `fentanyl` | ✅ | IV analgesia / ICU continuous infusion + citation backfill | Lexicomp DIH 2024 / Ramathibodi IV Guide | `PENDING_PHARMACIST_VERIFICATION` |

### Batch 2 — Core Pediatric & Hospital Antimicrobials (`lib/data/drugs/antibiotics.dart`)
| Drug ID | Common & Serious Side Effects (EN/TH) | Regimen Coverage & WP-09 Additions | Primary Textbook Citations | Status |
| :--- | :---: | :--- | :--- | :---: |
| `amoxicillin` | ✅ | Adult standard + Pediatric standard (45 mg/kg/day div q8h) + AOM/CAP high-dose (80–90 mg/kg/day div q12h) | Sanford Guide 2024 / Lexicomp Pediatric 2024 / RDU | `PENDING_PHARMACIST_VERIFICATION` |
| `amoxicillin_clavulanate` | ✅ | Adult + Pediatric standard & high-dose AOM/sinusitis/CAP | Sanford Guide 2024 / Lexicomp 2024 | `PENDING_PHARMACIST_VERIFICATION` |
| `azithromycin` | ✅ | Adult & pediatric CAP/atypical respiratory & STI regimens | Sanford Guide 2024 / Lexicomp 2024 | `PENDING_PHARMACIST_VERIFICATION` |
| `cephalexin` | ✅ | Adult SSTI/UTI + pediatric weight-based regimens | Sanford Guide 2024 / Lexicomp Pediatric 2024 | `PENDING_PHARMACIST_VERIFICATION` |
| `ceftriaxone` | ✅ | Adult severe infection/meningitis + pediatric sepsis/meningitis regimens | Sanford Guide 2024 / Harriet Lane | `PENDING_PHARMACIST_VERIFICATION` |
| `cefazolin` | ✅ | Appended pediatric surgical prophylaxis (`30 mg/kg`, max `2,000 mg`) & pediatric systemic (`50 mg/kg/day` q8h) + citation backfill | ASHP/IDSA Surgical Prophylaxis / Lexicomp Pediatric 2024 | `PENDING_PHARMACIST_VERIFICATION` |
| `gentamicin` | ✅ | Appended pediatric EID (`5–7.5 mg/kg` q24h) & pediatric traditional (`2.5 mg/kg` q8h) | Lexicomp Pediatric 2024 / AAP Red Book | `PENDING_PHARMACIST_VERIFICATION` |
| `vancomycin` | ✅ | Appended pediatric bacteremia/sepsis & pediatric CNS/meningitis (`60 mg/kg/day` IV div q6h) regimens | IDSA / Lexicomp Pediatric 2024 | `PENDING_PHARMACIST_VERIFICATION` |
| `acyclovir` | ✅ | Appended mucocutaneous HSV (`5 mg/kg` q8h) & HSV encephalitis / VZV (`10 mg/kg` q8h) + citation backfill | Lexicomp DIH 2024 / US FDA Zovirax SPL | `PENDING_PHARMACIST_VERIFICATION` |

### Batch 3 — Cardiovascular & Resuscitation IV (`lib/data/drugs/cardiovascular.dart`)
| Drug ID | Common & Serious Side Effects (EN/TH) | Regimen Coverage & WP-09 Additions | Primary Textbook Citations | Status |
| :--- | :---: | :--- | :--- | :---: |
| `norepinephrine` | ✅ | Appended Pediatric Septic Shock (`0.05–2.0 mcg/kg/min` IV infusion, `VerificationStatus.pendingReview`) | Surviving Sepsis Campaign Pediatric / Lexicomp 2024 | `PENDING_PHARMACIST_VERIFICATION` |
| `dopamine` | ✅ | Appended Pediatric Shock (`2–20 mcg/kg/min` IV infusion, `VerificationStatus.pendingReview`) | Surviving Sepsis Campaign Pediatric / Ramathibodi IV Guide | `PENDING_PHARMACIST_VERIFICATION` |
| `amiodarone` | ✅ | Appended AHA ACLS Cardiac Arrest (`300 mg` IV push) & PALS Pediatric Arrest (`5 mg/kg` IV bolus, max `300 mg`, `pendingReview`) | AHA ACLS 2020 / AHA PALS 2020 / Ramathibodi IV Guide | `PENDING_PHARMACIST_VERIFICATION` |
| `furosemide` | ✅ | IV/PO loop diuresis regimens + citation backfill | Lexicomp DIH 2024 / ACC-AHA HF | `PENDING_PHARMACIST_VERIFICATION` |
| `adenosine` | ✅ | Adult & pediatric SVT rapid IV bolus regimens + citation backfill | AHA ACLS/PALS 2020 / Lexicomp DIH 2024 | `PENDING_PHARMACIST_VERIFICATION` |

### Batch 4 — Emergency & Critical Care (`lib/data/drugs/emergency.dart`)
| Drug ID | Common & Serious Side Effects (EN/TH) | Regimen Coverage & WP-09 Additions | Primary Textbook Citations | Status |
| :--- | :---: | :--- | :--- | :---: |
| `epinephrine` | ✅ | Cardiac arrest, anaphylaxis (IM), infusion regimens | AHA ACLS/PALS 2020 / Lexicomp 2024 | `PENDING_PHARMACIST_VERIFICATION` |
| `atropine` | ✅ | Bradycardia & organophosphate poisoning + citation backfill | AHA ACLS/PALS 2020 / Lexicomp DIH 2024 | `PENDING_PHARMACIST_VERIFICATION` |
| `magnesium_sulfate` | ✅ | Eclampsia/torsades/asthma regimens | Ramathibodi IV Guide / AHA ACLS 2020 | `PENDING_PHARMACIST_VERIFICATION` |
| `dexamethasone` | ✅ | Anti-inflammatory/cerebral edema/croup/COVID regimens + citation backfill | Lexicomp DIH 2024 / RECOVERY Trial / Thai NLEM | `PENDING_PHARMACIST_VERIFICATION` |
| `naloxone` | ✅ | Adult & pediatric opioid reversal regimens | AHA / Lexicomp DIH 2024 | `PENDING_PHARMACIST_VERIFICATION` |
| `dobutamine` | ✅ | Appended Pediatric Shock / Low Cardiac Output Syndrome (`2–20 mcg/kg/min` IV, `VerificationStatus.pendingReview`) | Surviving Sepsis Campaign Pediatric 2020 / Lexicomp 2024 | `PENDING_PHARMACIST_VERIFICATION` |

### Batch 5 — Neurology & Sedation (`lib/data/drugs/neurology.dart`)
| Drug ID | Common & Serious Side Effects (EN/TH) | Regimen Coverage & WP-09 Additions | Primary Textbook Citations | Status |
| :--- | :---: | :--- | :--- | :---: |
| `diazepam` | ✅ | Status epilepticus / anxiety/sedation + citation backfill | Lexicomp DIH 2024 / AES 2016 / Ramathibodi IV Guide | `PENDING_PHARMACIST_VERIFICATION` |
| `phenytoin` | ✅ | IV loading & maintenance + citation backfill | Lexicomp DIH 2024 / AES 2016 / Ramathibodi IV Guide | `PENDING_PHARMACIST_VERIFICATION` |
| `levetiracetam` | ✅ | Appended AES Status Epilepticus Adult (`60 mg/kg` IV once, max `4,500 mg`) & Pediatric (`60 mg/kg` IV once, max `4,500 mg`, `pendingReview`) + citation backfill | AES Guideline 2016 / ESETT Trial / Lexicomp DIH 2024 | `PENDING_PHARMACIST_VERIFICATION` |
| `midazolam` | ✅ | Procedural sedation & continuous ICU infusion | Ramathibodi High-Alert IV Guide 2024 / PADIS 2018 | `PENDING_PHARMACIST_VERIFICATION` |

### Batch 6 — Respiratory (`lib/data/drugs/respiratory.dart`)
| Drug ID | Common & Serious Side Effects (EN/TH) | Regimen Coverage & WP-09 Additions | Primary Textbook Citations | Status |
| :--- | :---: | :--- | :--- | :---: |
| `salbutamol` | ✅ | Adult & pediatric acute bronchospasm / nebulization + citation backfill | GINA 2024 / Lexicomp DIH 2024 | `PENDING_PHARMACIST_VERIFICATION` |
| `prednisolone` | ✅ | Adult & pediatric asthma exacerbation regimens + citation backfill | GINA 2024 / Lexicomp DIH 2024 | `PENDING_PHARMACIST_VERIFICATION` |

### Batch 7 — Electrolytes & High-Alert Endocrine (`lib/data/drugs/specialty.dart`, `lib/data/drugs/endocrine.dart`)
| Drug ID | Common & Serious Side Effects (EN/TH) | Regimen Coverage & WP-09 Additions | Primary Textbook Citations | Status |
| :--- | :---: | :--- | :--- | :---: |
| `potassium_chloride` | ✅ | Peripheral/central IV replacement & oral supplementation + citation backfill | ISMP 2024 / Ramathibodi IV Guide / Lexicomp DIH 2024 | `PENDING_PHARMACIST_VERIFICATION` |
| `calcium_gluconate` | ✅ | Hypocalcemia & hyperkalemia cardioprotection + citation backfill | AHA ACLS 2020 / Lexicomp DIH 2024 | `PENDING_PHARMACIST_VERIFICATION` |
| `insulin_regular` | ✅ | SC prandial/sliding scale & DKA continuous IV infusion | ADA Standards 2024 / US FDA Humulin R / Ramathibodi | `PENDING_PHARMACIST_VERIFICATION` |
