# High-Alert Drug (HAD) Reclassification Audit (`WP-03` / `FB-11`)

> **Authoritative Standard:** *ISMP List of High-Alert Medications in Acute Care Settings* (**2024 Edition**)  
> **Machine-Readable Registry:** `assets/data/high_alert_lists/ismp_acute_care.json` & `lib/core/domain/high_alert_registry.dart`  
> **Pharmacist Feedback Addressed (`FB-11`):** *"เอารายชื่อ High-Alert Drug มาจากไหน... มีหลายตัวยาที่ไม่ใช่ High-Alert Drug แต่ถูกติดป้ายหมด... High-Alert Drug คือยาที่บริหารผิดพลาดแล้วเสี่ยง Overdose/Toxicity รุนแรงถึงชีวิต รายการของแต่ละ รพ. จะไม่เท่ากัน"*

---

## 1. Key Architectural Changes
1. **Route-Aware Checking:** `HighAlertRegistry.isHighAlert(drugId, route: regimen.route)` checks administration routes so oral KCl (`po`), oral Digoxin (`po`), oral Metoprolol (`po`), IM Epinephrine (`im` anaphylaxis), and IM Oxytocin (`im`) do **not** trigger false IV-only ISMP High-Alert alarms while IV routes remain strictly protected.
2. **NTI / TDM Separation:** Drugs requiring therapeutic drug monitoring or having a Narrow Therapeutic Index (`vancomycin`, `gentamicin`, `amikacin`, `digoxin` PO, `phenytoin`, `valproic_acid`, `lithium`, `tacrolimus`) now display a distinct **`NTI / TDM`** badge rather than diluting red High-Alert alerts.
3. **Hospital PTC Override Hook:** `HighAlertOverride(addedDrugIds, removedDrugIds, routeOverrides)` lets individual hospitals customize HAD policies in Phase 6 (`WP-15`).

---

## 2. Full Reclassification Audit Table (42 Prior Flagged + 2 ISMP 2024 Catalog Additions)

| Drug (`id`) | Prior `isHighAlert` | ISMP Acute Care 2024 Category | Route-Specific Flag | Decision | Citation |
| :--- | :---: | :--- | :--- | :--- | :--- |
| `tramadol` | `true` | Opioids (all routes) | All routes | **Keep** | ISMP Acute Care 2024 |
| `morphine` | `true` | Opioids (all routes) | All routes | **Keep** | ISMP Acute Care 2024 |
| `fentanyl` | `true` | Opioids (all routes) | All routes | **Keep** | ISMP Acute Care 2024 |
| `warfarin` | `true` | Antithrombotic agents — Anticoagulants | All routes (+ `NTI/TDM`) | **Keep** | ISMP Acute Care 2024 |
| `enoxaparin` | `true` | Antithrombotic agents — LMWH | All routes | **Keep** | ISMP Acute Care 2024 |
| `heparin` | `true` | Antithrombotic agents — UFH | All routes | **Keep** | ISMP Acute Care 2024 |
| `apixaban` | `true` | Antithrombotic agents — DOACs/Xa inhibitors | All routes | **Keep** | ISMP Acute Care 2024 |
| `rivaroxaban` | `true` | Antithrombotic agents — DOACs/Xa inhibitors | All routes | **Keep** | ISMP Acute Care 2024 |
| `insulin_regular` | `true` | Insulin, subcutaneous and IV | All routes | **Keep** | ISMP Acute Care 2024 |
| `insulin_glargine` | `true` | Insulin, subcutaneous and IV | All routes | **Keep** | ISMP Acute Care 2024 |
| `glipizide` | `false` | Hypoglycemics, oral (sulfonylureas) | All routes | **Add** | ISMP Acute Care 2024 |
| `propofol` | `true` | Anesthetic agents, general, inhaled and IV | All routes | **Keep** | ISMP Acute Care 2024 |
| `carboplatin` | `true` | Chemotherapeutic agents, parenteral/oral | All routes (`ReferenceOnly`) | **Keep** | ISMP Acute Care 2024 |
| `methotrexate` | `true` | Chemotherapy / Oral non-oncologic MTX | All routes (`ReferenceOnly`) | **Keep** | ISMP Acute Care 2024 |
| `norepinephrine` | `true` | Adrenergic agonists, IV | `ivInfusion, ivPush, iv, io` | **Route-Only** | ISMP Acute Care 2024 |
| `epinephrine` | `true` | Adrenergic agonists, IV | `ivInfusion, ivPush, iv, io` (NOT `im`) | **Route-Only** | ISMP Acute Care 2024 |
| `dopamine` | `true` | Adrenergic agonists, IV | `ivInfusion, ivPush, iv, io` | **Route-Only** | ISMP Acute Care 2024 |
| `dobutamine` | `true` | Inotropic / Adrenergic agonists, IV | `ivInfusion, iv` | **Route-Only** | ISMP Acute Care 2024 |
| `vasopressin` | `true` | Vasopressin, IV and intraosseous | `ivInfusion, iv, io` | **Route-Only** | ISMP Acute Care 2024 |
| `amiodarone` | `true` | Antiarrhythmics, IV | `ivInfusion, ivPush, iv` | **Route-Only** | ISMP Acute Care 2024 |
| `adenosine` | `true` | Antiarrhythmics, IV | `ivInfusion, ivPush, iv` | **Route-Only** | ISMP Acute Care 2024 |
| `midazolam` | `true` | Moderate sedation IV / Ped oral sedation | `ivInfusion, ivPush, iv, po` | **Route-Only** | ISMP Acute Care 2024 |
| `dexmedetomidine` | `true` | Moderate sedation agents, IV | `ivInfusion, ivPush, iv` | **Route-Only** | ISMP Acute Care 2024 |
| `magnesium_sulfate` | `true` | Specific Medications: Magnesium sulfate inj. | `ivInfusion, ivPush, iv, im` | **Route-Only** | ISMP Acute Care 2024 |
| `oxytocin` | `true` | Specific Medications: Oxytocin, IV | `iv, ivInfusion` (NOT `im`) | **Route-Only** | ISMP Acute Care 2024 |
| `potassium_chloride` | `true` | Specific Medications: KCl inj. concentrate | `ivInfusion, iv` (NOT `po`) | **Route-Only** | ISMP Acute Care 2024 |
| `digoxin` | `true` | Inotropic medications, IV (PO not on list) | `iv` only in registry; DB is `po` | **Remove HAD -> `NTI / TDM`** | ISMP Acute Care 2024 |
| `metoprolol` | `false` | Adrenergic antagonists, IV (PO not on list) | `iv` only in registry; DB is `po` | **Route-Only (PO safe)** | ISMP Acute Care 2024 |
| `vancomycin` | `true` | Not on ISMP Acute Care list | — | **Remove HAD -> `NTI / TDM`** | ISMP Acute Care 2024 |
| `gentamicin` | `true` | Not on ISMP Acute Care list | — | **Remove HAD -> `NTI / TDM`** | ISMP Acute Care 2024 |
| `amikacin` | `true` | Not on ISMP Acute Care list | — | **Remove HAD -> `NTI / TDM`** | ISMP Acute Care 2024 |
| `phenytoin` | `true` | Not on ISMP Acute Care list | — | **Remove HAD -> `NTI / TDM`** | ISMP Acute Care 2024 |
| `valproic_acid` | `true` | Not on ISMP Acute Care list | — | **Remove HAD -> `NTI / TDM`** | ISMP Acute Care 2024 |
| `lithium` | `true` | Not on ISMP Acute Care list | — | **Remove HAD -> `NTI / TDM`** | ISMP Acute Care 2024 |
| `tacrolimus` | `true` | Not on ISMP Acute Care list | — | **Remove HAD -> `NTI / TDM`** | ISMP Acute Care 2024 |
| `rifampin` | `true` | Not on ISMP Acute Care list | — | **Remove** | ISMP Acute Care 2024 |
| `naloxone` | `true` | Not on ISMP Acute Care list | — | **Remove** | ISMP Acute Care 2024 |
| `haloperidol` | `true` | Not on ISMP Acute Care list | — | **Remove** | ISMP Acute Care 2024 |
| `atropine` | `true` | Not on ISMP Acute Care list | — | **Remove** | ISMP Acute Care 2024 |
| `colistin` | `true` | Not on ISMP Acute Care list | — | **Remove** | ISMP Acute Care 2024 |
| `nicardipine` | `true` | Not on ISMP Acute Care list | — | **Remove** *(PTC override eligible)* | ISMP Acute Care 2024 |
| `epoetin_alfa` | `true` | Not on ISMP Acute Care list | — | **Remove** | ISMP Acute Care 2024 |
| `mycophenolate` | `true` | Not on ISMP Acute Care list | — | **Remove** | ISMP Acute Care 2024 |
| `calcium_gluconate` | `true` | Not on ISMP Acute Care list | — | **Remove** *(PTC override eligible)* | ISMP Acute Care 2024 |
