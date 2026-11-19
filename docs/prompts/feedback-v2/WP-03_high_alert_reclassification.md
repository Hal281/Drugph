# WP-03: Reclassify High-Alert Drugs (HAD) Against ISMP & Support Hospital Overrides

## 1. Context & Pharmacist Feedback Reference
* **Covers:** `FB-11`
* **Pharmacist Feedback:** *"เอารายชื่อ High-Alert Drug มาจากไหน... มีหลายตัวยาที่ไม่ใช่ High-Alert Drug แต่ถูกติดป้ายหมด... High-Alert Drug คือยาที่บริหารผิดพลาดแล้วเสี่ยง Overdose/Toxicity รุนแรงถึงชีวิต รายการของแต่ละ รพ. จะไม่เท่ากัน"*
* **Survey Finding:** Currently **42 drugs** in `lib/data/drugs/*.dart` hardcode `isHighAlert: true` on `Drug` (including questionable entries such as Rifampin, Naloxone, Haloperidol, Atropine, Vancomycin, aminoglycosides, Phenytoin, Valproic Acid, Lithium, Epoetin alfa, MMF, Nicardipine, Calcium Gluconate).

## 2. Goal
Replace the broad hardcoded `isHighAlert` flags with an evidence-backed `HighAlertRegistry` grounded in the **ISMP List of High-Alert Medications in Acute Care Settings** (route-aware, e.g. IV vs oral opioids, KCl concentrate injection, magnesium sulfate injection, oxytocin IV), plus an override hook for per-hospital HAD lists (consumed later in WP-15).

## 3. Exact Files & Line Numbers to Touch
* [NEW] `assets/data/high_alert_lists/ismp_acute_care.json`
* [NEW] `lib/core/domain/high_alert_registry.dart`
* [NEW] `docs/clinical/HIGH_ALERT_RECLASSIFICATION.md`
* [`lib/core/models/drug.dart`](file:///c:/Users/turbo/drugforPh/lib/core/models/drug.dart#L510-L578)
* [`lib/core/calculators/pharmacist_calculator.dart`](file:///c:/Users/turbo/drugforPh/lib/core/calculators/pharmacist_calculator.dart#L1132-L1134) & `lib/core/calculators/dose_checker.dart:258-270`
* [`lib/ui/home_screen.dart`](file:///c:/Users/turbo/drugforPh/lib/ui/home_screen.dart#L534-L611)
* `pubspec.yaml` (register new asset path if needed)
* New test `test/clinical/high_alert_reclassification_test.dart`

## 4. Implementation Steps
1. **Strict Verification Rule:** Consult the actual **ISMP List of High-Alert Medications in Acute Care Settings** (web/PDF or verified reference; **never unflag or flag from memory**). Record the exact ISMP category and edition/year for every drug in `docs/clinical/HIGH_ALERT_RECLASSIFICATION.md`.
2. Build `assets/data/high_alert_lists/ismp_acute_care.json` storing entries with `drugId`, `applicableRoutes` (e.g. `["iv", "im", "sc"]` vs `["all"]`), `ismpCategory`, `sourceEdition`, and `rationale`.
3. Create pure `HighAlertRegistry`:
   - `bool isHighAlert(String drugId, {DoseRoute? route, HighAlertOverride? hospitalOverride})`
   - Supports optional hospital override JSON (adds or removes drugs/routes per hospital PTC policy).
4. Audit all 42 currently flagged drugs in `HIGH_ALERT_RECLASSIFICATION.md` with columns: `Drug | Current isHighAlert | ISMP Acute Care Category | Proposed Route-Specific Flag | Decision (Keep / Route-Only / Remove) | Citation`.
   - Pay special attention to pharmacist-flagged candidates: Rifampin, Naloxone, Haloperidol, Atropine, Vancomycin, Gentamicin, Amikacin, Colistin, Phenytoin, Valproic Acid, Lithium, Epoetin alfa, MMF, Nicardipine, Calcium Gluconate.
5. Update `HomeScreen` and `PharmacistCalculator` to consult `HighAlertRegistry` (keeping `Drug.isHighAlert` backward-compatible or delegating cleanly so existing unit tests don't break unintentionally; update tests that explicitly test old hardcoded HAD flags only where justified in `HIGH_ALERT_RECLASSIFICATION.md`).
6. Add `test/clinical/high_alert_reclassification_test.dart` (`FB-11`) testing snapshot membership, route-specificity (e.g. IV electrolyte concentrate vs oral), and custom hospital override behavior.

## 5. Acceptance Criteria
* Every HAD classification in `ismp_acute_care.json` and `HIGH_ALERT_RECLASSIFICATION.md` cites an explicit ISMP category and edition.
* Non-ISMP drugs (e.g. Rifampin, Naloxone if not on ISMP acute care list) no longer falsely display the red High-Alert badge.
* Route-specific high-alert rules (e.g. IV KCl concentrate, IV MgSO4, IV Oxytocin) work accurately.
* `flutter analyze` and `flutter test` pass (`>= 1,179` + new tests).

## 6. Automated Verification Commands
```powershell
cd c:\Users\turbo\drugforPh
flutter analyze
flutter test test/clinical/high_alert_reclassification_test.dart
flutter test --no-pub -r compact
```

## 7. Forbidden Actions
* Do NOT reclassify any drug from memory without verifying against the ISMP Acute Care High-Alert Medications list.
* Do NOT delete drugs from `DrugDatabase`.
