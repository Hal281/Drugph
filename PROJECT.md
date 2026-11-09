# Project: Drugph — Comprehensive Clinical Dosage, Complex Logic Remediation & Strategic Development Roadmap

## Architecture
- Layered Decoupling:
  - **Domain / Core (`lib/core/`)**: Pure entities (`Drug`, `DosingRegimen`, `Patient`), calculation engines (`PharmacistCalculator`, `RenalCalculator`, `BsaCalculator`, `WeightBasedCalculator`, `IvRateCalculator`, `UnitConverter`, `DoseRounder`, `DoseChecker`, `TdmCalculator`, `ChildPughCalculator`), validators (`InputValidator`), allergy service (`AllergyService`), therapeutic duplication & DDI service (`TherapeuticDuplicationService`, `ClinicalInteractionRegistry`), and deterministic clinical formatters (`ClinicalOrderFormatter`). Zero dependencies on Flutter UI or network SDKs.
  - **Data (`lib/data/`)**: Drug monographs, clinical database (`DrugDatabase`), and pure deterministic search engine (`DrugSearchEngine`) with in-memory tokenized index.
  - **Presentation / UI (`lib/ui/`)**:
    - `lib/ui/calculator/`: Modular clinical calculator dashboard (MDCalc live formula breakdown + Lexicomp indication-driven monographs), state controllers, and 4 UI states.
    - `lib/ui/calculator_screen.dart`: Backward-compatible re-export facade.
    - `lib/ui/widgets/clinical_search_bar.dart`: Debounced (250ms) search input with highlight tokens, clear button, and recent search history.
  - **Verification & Quality Gates**:
    - `test/core/calc_core_audit_test.dart`: Automated regression tests for core math, bounds, and validator edge cases.
    - `test/core/audited_adjustments_and_ddi_test.dart`: Automated regression tests for allergy cross-reactivity, DDI, therapeutic duplications, and IV rate calculations.
    - `test/core/calculation_subsystem_verification_test.dart`: Pure-function test suite for utility calculators (`BsaCalculator`, `RenalCalculator`, `WeightBasedCalculator`, `IvRateCalculator`, `UnitConverter`, `DoseRounder`).
    - Full regression test suite (`flutter test`: 572 tests passed) and static analysis (`dart analyze`: 0 issues).

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Multi-Dimensional Scoring Model | 10-tier scoring weights for search engine | M1 | Phase 2 |
| 2 | In-Memory Tokenized Search Index | Pre-indexed token map providing sub-16ms search query response | M1 | Phase 2 |
| 3 | Matched Reason & Detailed Search API | `DrugSearchResult` and `MatchedReason` reporting exact dimension matched | M1 | Phase 2 |
| 4 | Search UI Ergonomics | 250ms debounce, clear button ('X'), query match highlighting, and recent 5 searches | M1 | Phase 2 |
| 5 | Backward-Compatible Search API | `DrugDatabase.search` and `searchDetailed` | M1 | Phase 2 |
| 6 | Search Unit Test Suite | Unit tests in `test/data/drug_search_test.dart` | M1 | Phase 2 |
| 7 | Calculator Architecture Modularization | Decompose monolithic `calculator_screen.dart` into `lib/ui/calculator/` | M2 | Phase 2 |
| 8 | Backward-Compatible Calculator Facade | `lib/ui/calculator_screen.dart` re-exports modular components | M2 | Phase 2 |
| 9 | MDCalc Transparent Live Formula Breakdown | Live mathematical breakdown card with step-by-step substitution | M2 | Phase 2 |
| 10 | Lexicomp Indication & Adjustment Badges | Indication-driven regimen selector and organ function badges | M2 | Phase 2 |
| 11 | 4 Explicit UI States | Explicit handling of Loading, Active, Empty, and Error states | M2 | Phase 2 |
| 12 | Impeccable UI/UX & Responsive Layout | 8-point grid, WCAG AAA contrast, >= 48x48 dp touch targets | M2 | Phase 2 |
| 13 | Rule 5 Non-Blocking Overdose Invariant | Prominent red/amber overdose banner displayed without zeroing doses | M2 | Phase 2 |
| 14 | Modular Calculator Test Suite | Widget and integration tests in `test/ui/calculator_modular_test.dart` | M2 | Phase 2 |
| 15 | End-to-End Test & Static Analysis Gate | Complete verification: 100% test pass on existing tests (468/468 passed) | M3 | Phase 2 |
| 16 | `verifyOrder` Non-Positive & NaN Dose Validation | Disallow <= 0 and non-finite ordered doses; return hard warning | M4 | explorer_calc_core |
| 17 | `InputValidator` IEEE-754 Finite Value Validation | Guard against NaN and Infinity in weight, height, SCr, age | M4 | explorer_calc_core |
| 18 | ELBW/NICU Neonatal Low Weight Support in Calculator | Pass `allowNeonatalLowWeight: patient.ageYears < 1` to enable 0.4–0.99 kg | M4 | explorer_calc_core |
| 19 | Robust Exact-Strength & NaN Safe Formulary Rounding | Prevent `NaN.round()` crash and support exact commercial strengths | M4 | explorer_calc_core |
| 20 | Underweight AdjBW Clamping | Ensure AdjBW does not exceed actual weight for malnourished adults | M4 | explorer_calc_core |
| 21 | Unified Devine IBW Height < 60 in Formulation | Harmonize downward extrapolation formula across calculators | M4 | explorer_calc_core |
| 22 | Renal, BSA & IV Rate Calculator Finite Input Assertion | Throw `ArgumentError` on NaN or non-positive inputs | M4 | explorer_calc_core |
| 23 | Multi-Format Frequency Parsing | Support Thai hospital strings and common frequency suffixes | M4 | explorer_calc_core |
| 24 | Conservative Range Interval Daily Capping | Prevent daily overdose when calculating perDay doses for range intervals | M4 | explorer_calc_core |
| 25 | Infinite Float Safety in `ClinicalOrderFormatter` | Guard `.toInt()` against infinity in `_formatNumber` | M4 | explorer_calc_core |
| 26 | Biological Unit Infusion Volume Compatibility | Validate unit matching when calculating infusion volume for units/mEq | M4 | explorer_calc_core |
| 27 | Bidirectional Beta-Lactam Allergy Cross-Reactivity | Check Cephalosporin -> Penicillin and Carbapenem cross-reactivity | M5 | explorer_adjustments_ddi |
| 28 | Weight-Based IV Infusion Non-Null Assertion | Throw `ArgumentError` when `weightKg` is omitted for weight-based units | M5 | explorer_adjustments_ddi |
| 29 | Expanded Rule 3 Therapeutic Duplication Prevention | Add Dual Sulfonylureas, Dual DPP-4i, Dual SGLT2i, Dual Thiazides | M5 | explorer_adjustments_ddi |
| 30 | CYP3A4-Specific Statin-Macrolide DDI Rule | Restrict hard contraindication to CYP3A4 statins + CYP3A4 macrolides | M5 | explorer_adjustments_ddi |
| 31 | Major Clinical Drug Interactions Registry Expansion | Add Anticoagulant+NSAID, Spiro+KCl, Lithium+NSAID/ACEI/ARB | M5 | explorer_adjustments_ddi |
| 32 | Child-Pugh C Daily Dose Ceiling for Ondansetron | Implement declarative dose rule enforcing 8 mg/day maximum | M5 | explorer_adjustments_ddi |
| 33 | Renal Adjustment Contraindication Action Handling | Emptily preserve hard contraindication warning for avoid/contraindicated | M5 | explorer_adjustments_ddi |
| 34 | Comprehensive Automated Test Suite Expansion | Dedicated regression test suites in `test/core/` covering all 19 fixes | M6 | explorer_tests_git |
| 35 | Git Staging, Commit & Push to `origin/main` | Cleanly stage verified code, commit, and push to GitHub remote | M7 | explorer_tests_git |
| 36 | Class-Level Allergy Bypass Remediation | Pass `drug.effectiveDrugClass` in `PharmacistCalculator:140` | M8 (P0) | Master Audit |
| 37 | Raw Uncapped Math Exposure in Weight & TDM Calculators | Expose uncapped dose and generate non-silent cap warnings | M8 (P0) | Master Audit |
| 38 | Emergency STAT Dose Preservation on Renal Contraindication | Retain calculated dose on `RenalAction.avoid` alongside hard red warning | M8 (P0) | Master Audit |
| 39 | Native Non-Mass Unit Dilution Volume Engine | Directly compute `volumeMl` for units/unitsPerMl and mEq/mEqPerMl | M8 (P0) | Master Audit |
| 40 | Pediatric & Adolescent Obesity Dosing Strategy | Harmonize IBW and AdjBW for adolescents $\ge 12$ years | M8 (P0) | Master Audit |
| 41 | Lethal DDI & Duplication Engine Expansion | Add 6 duplicate classes & 6 major DDIs (Warfarin, Linezolid, QTc, etc.) | M8 (P0) | Master Audit |
| 42 | 27 IV Drugs Diluent & Bedside Precipitation Compatibility | Codify `IvDiluentCompatibility` (D5W, NSS, LR, stability, push times) | M9 (P1) | Master Audit |
| 43 | 93 Stub Drugs Clinical Monograph & Provenance Ingestion | Ingest Lexicomp/Sanford monograph text and pharmacist sign-off | M9 (P1) | Master Audit |
| 44 | Vancomycin AUC24/MIC Ratio & Bayesian MAP Estimation | Codify ASHP 2020 target 400-600 AUC and non-steady-state trapezoid | M9 (P1) | Master Audit |
| 45 | Kinetic GFR & Absolute eGFR De-Indexing Equation | Implement Chen 2013 AKI equation and $\text{eGFR} \times \frac{BSA}{1.73}$ | M9 (P1) | Master Audit |
| 46 | CKD-EPI 2021 & Bedside Schwartz Full Engine Integration | Connect laboratory eGFR and pediatric formula to `PharmacistCalculator` | M9 (P1) | Master Audit |
| 47 | Carboplatin GFR Capping & Renal Tier Safeguards | Explicitly cap Calvert GFR at 125 mL/min and add CrCl < 15 tiers | M9 (P1) | Master Audit |
| 48 | Two-Way Patient Session & Calculator State Synchronization | Sync edits in `CalculatorController` back to `PatientSession` | M10 (P2) | Master Audit |
| 49 | Ward Dashboard Background Computation & Indication Selector | Move multi-drug math off UI thread; remove hardcoded `regimens.first` | M10 (P2) | Master Audit |
| 50 | Orphan Pillar 3 Subsystem Resolution | Wire or harmonize `VerifiedClinicalCalculatorScreen` into main workflow | M10 (P2) | Master Audit |
| 51 | Form Validation Feedback & Schwartz CrCl in PatientEditDialog | Provide explicit field errors and pediatric renal clearance calculation | M10 (P2) | Master Audit |
| 52 | Decision Log & Registry Harmonization | Synchronize `DEC-ALLERGY-001` and digitize Hartford coordinates | M10 (P2) | Master Audit |
| 53 | Widget Test Suite for 8 Untested UI Screens | Write comprehensive widget tests covering 3,613 lines of Flutter UI | M11 (P3) | Master Audit |
| 54 | End-to-End Clinical Workflow Integration Test Suite | Build automated `integration_test/` for complete user journey | M11 (P3) | Master Audit |
| 55 | WCAG AAA Accessibility & Contrast Remediation | Fix ~3:1 contrast ratios and add `Semantics` tags to all UI controls | M11 (P3) | Master Audit |
| 56 | 8-Point Grid Discipline & Touch Target Enforcement | Eliminate fractional spacing; enforce $\ge 48\times 48\text{ dp}$ targets | M11 (P3) | Master Audit |
| 57 | Dependency Upgrade & Strict Compiler Typing Enforcement | Replace `flutter_markdown`; enable strict-casts/inference/raw-types | M11 (P3) | Master Audit |
| 58 | 1-Compartment PK-PD Simulation Engine | IV bolus, intermittent infusion, oral absorption with L'Hopital ka=ke limit, continuous infusion | M12 (P0) | Survey Spec Miner |
| 59 | 2-Compartment PK-PD Simulation Engine | Central/peripheral compartments, micro-constants k10/k12/k21, hybrid alpha/beta, biexponential | M12 (P0) | Survey Spec Miner |
| 60 | Multi-Dose Accumulation & Superposition | Accumulation factor R = 1/(1-exp(-ke*tau)), steady-state Cmax/Cmin, consecutive N-dose simulation | M12 (P0) | Survey Spec Miner |
| 61 | Deterministic PK Parameters Computation | Cmax, Cmin, Tmax, AUC0-24, ke, t1/2, clearance relationships | M12 (P0) | Survey Spec Miner |
| 62 | Therapeutic Target Windows Modeling | MEC, MTC, sub-therapeutic, therapeutic, and toxic zones complying with Rule 5 | M12 (P0) | Survey Spec Miner |
| 63 | Discrete Sampling Coordinate Generator | 200-500 points across 24h-72h, piecewise discontinuity boundary pinning | M12 (P0) | Survey Spec Miner |
| 64 | Vancomycin AUC24/MIC & Trough Dosing Engine | ASHP 2020 target (400-600 mg*h/L), first-order elimination, 2-point Sawchuk-Zaske kinetics | M13 (P0) | Survey NTI Explorer |
| 65 | Aminoglycosides Hartford Nomogram & Conventional Dosing | Hartford 7 mg/kg once-daily, 6-14h window, conventional peak (5-10/20-30) and trough (<1-2/<5) | M13 (P0) | Survey NTI Explorer |
| 66 | Phenytoin Non-Linear Michaelis-Menten Kinetics | Vmax=7 mg/kg/day, Km=4 mg/L, asymptotic saturation guard (Dose >= Vmax) | M13 (P0) | Survey NTI Explorer |
| 67 | Phenytoin Albumin & Renal Failure Correction | Sheiner-Tozer albumin equation & Winter-Tozer renal failure modification (CrCl < 20 or ESRD) | M13 (P0) | Survey NTI Explorer |
| 68 | NTI Electrolyte Disturbance Monitoring | Automated K+, Mg2+, Ca2+ digitalis toxicity checks and Na+ lithium clearance alerts | M13 (P1) | Survey NTI Explorer |
| 69 | NTI Alpha Distribution Phase Warnings | Digoxin 6-8h post-dose sampling hazard alert, Lithium 12h trough, Theophylline steady-state | M13 (P1) | Survey NTI Explorer |
| 70 | Special Populations Body Weight Selection | Enforce TBW, IBW Devine formula, and mandatory AdjBW 0.4 for obese NTI patients (BMI>=30 or TBW>1.2*IBW) | M13 (P0) | Survey NTI Explorer |
| 71 | Special Populations Renal Function Estimation | Cockcroft-Gault with elderly SCr floor (0.8 mg/dL in age >= 65), pediatric Bedside Schwartz with subpopulation k-values | M13 (P0) | Survey NTI Explorer |
| 72 | High-Alert Continuous Infusions Engine | Inotropes/vasopressors standard hospital dilutions, mcg/kg/min and mcg/min to mL/hr conversion | M13 (P0) | Survey NTI Explorer |
| 73 | High-Alert Overdose Alert & Override Justification | Rule 5 non-blocking overdose warning with structured clinical override justification logging | M13 (P0) | Survey NTI Explorer |
| 74 | Dynamic PK-PD Canvas Rendering Engine | CustomPainter PkChartPainter: MTC red zone, MEC green band, dual before/after curves, crosshair scrubber | M14 (P2) | Survey UI Explorer |
| 75 | Background Isolate Simulation Engine | Isolate.run offloading multi-dose simulations with immutable DTOs and sequence-token debouncing | M14 (P2) | Survey UI Explorer |
| 76 | Interactive Parameter Sliders & Live Comparison | Dynamic clearance, dose, and tau sliders with real-time delta metrics and curve updates | M14 (P2) | Survey UI Explorer |
| 77 | Accessible Tabular Data Fallback | WCAG 2.2 AAA compliant high-contrast data table view, screen reader Semantics, CSV export | M14 (P2) | Survey UI Explorer |
| 78 | CDSS Calculator Integration & Two-Way State Sync | Dynamic NTI detection in DosageResultCard, two-way sync of edited patient parameters to PatientSession | M14 (P2) | Survey UI Explorer |
| 79 | Comprehensive 4-Tier E2E Test Suite | Opaque-box test suite (Tiers 1-4) derived from user requirements | E2E Track | E2E Testing Track |
| 80 | Full E2E Test Suite Pass & Adversarial Hardening | Pass 100% E2E tests and adversarial coverage hardening (Tier 5 Challenger loop) | M15 | Implementation Track |
| 81 | Adrenaline Anaphylaxis IM Metric & Volume Standardization | 1 mg/mL, 0.3-0.5 mL adult, 0.01 mL/kg peds, explicit volume display | M16 | Survey Explorer 1/3 |
| 82 | Adrenaline Pediatric Anaphylaxis Prepubertal Ceiling | 0.3 mg cap per WAO 2020 / AAP, Rule 5 non-blocking display on > 30 kg | M16 | Survey Explorer 1/3 |
| 83 | Adrenaline Cardiac Arrest ACLS/PALS Concentration & Volume | 0.1 mg/mL [1:10,000], 10 mL adult, 0.1 mL/kg peds, 1.0 mg cap | M16 | Survey Explorer 1/3 |
| 84 | Adrenaline Continuous IV Infusion Regimen in Emergency Formulary | `RateUnit.mcgKgMin`, 0.05-1.0 mcg/kg/min, 16 mcg/mL standard bag | M16 | Survey Explorer 1/2 |
| 85 | Vasoactive Infusion Engine Strict Unit Typing & Bidirectional Conversion | `mcg/kg/min` <-> `mcg/min` preventing 60-fold underdose/overdose | M16 | Survey Explorer 1/2 |
| 86 | Bedside Volume in mL Display in `DosageResultCard` & Dual Concentration | Volume chip in DosageResultCard, 16 mcg/mL (4 mg/250 mL) in IV titration | M16 | Survey Explorer 1/3 |
| 87 | Pending Pharmacist Registry Evidence-Backed Ratification | DEC-PND-001 to 006: Acyclovir 1000 mg cap & IBW, Atropine 0.5 mg cap, Dexamethasone 10 mg cap, Salbutamol population filter & 2.5 mg cap, Hartford proof | M17 | Survey Explorer 2/3 |
| 88 | Checklist Documentation Drift Synchronization | Synchronize drifted line numbers in `Pending_Pharmacist_Signoff_Checklist.md` | M17 | Survey Explorer 2 |
| 89 | Comprehensive Adrenaline & Pending Registry Automated Test Suite | Unit tests covering all Adrenaline regimens, units, volumes, overdose ceilings, regressions | M18 | Implementation Track |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Clinical Drug Search Engine Upgrade | `lib/data/drug_search_engine.dart`, `lib/data/drug_database.dart` | none | DONE |
| M2 | Modular Clinical Calculator Dashboard | `lib/ui/calculator/`, `lib/ui/calculator_screen.dart` | none | DONE |
| M3 | Comprehensive Verification (Phase 2) | Full test suite, static analysis, adversarial tests, audit | M1, M2 | DONE |
| M4 | Core Calculation & Input Logic Remediation | `lib/core/calculators/`, `lib/core/validators/`, `lib/core/formatters/` | none | DONE (Verified) |
| M5 | Adjustments, DDI, Allergy & Clinical Data Remediation | `lib/core/models/`, `lib/core/calculators/dose_checker.dart`, `lib/data/drugs/` | none | DONE (Verified) |
| M6 | Comprehensive Automated Regression & Quality Gates | `test/core/`, full `flutter test` (100% pass), `dart analyze` (0 issues) | M4, M5 | DONE (Verified) |
| M7 | Git Repository Staging, Commit & GitHub Push | Stage all files, commit with clinical message, push to `origin/main` | M6 | PLANNED |
| M8 | Tier P0: Immediate Safety-Critical & Invariant Fixes | REM-01 to REM-06 (`PharmacistCalculator`, capping, units, allergy, DDI) | M7 | PLANNED |
| M9 | Tier P1: High-Priority Clinical Data & Parenteral Safety | REM-07 to REM-12 (IV compatibility, monographs, AUC PK, Kinetic GFR) | M8 | PLANNED |
| M10 | Tier P2: Architecture Unification & State Synchronization | REM-13 to REM-17 (Two-way sync, dashboard build, orphan resolution) | M9 | PLANNED |
| M11 | Tier P3: Test Coverage Hardening & Impeccable UI/UX | REM-18 to REM-22 (8 UI screen tests, E2E tests, WCAG AAA, 8-pt grid) | M10 | PLANNED |
| M12 | Core PK-PD Mathematical Modeling & Simulation Engine | `lib/core/calculators/pk_simulation_engine.dart`, `lib/core/models/pk_model.dart` | none | DONE (Verified) |
| M13 | Specialized NTI Dosing & High-Alert Infusion Engines | `lib/core/calculators/specialized_dosing_calculator.dart`, `lib/core/models/specialized_dosing_models.dart` | M12 | DONE (Verified) |
| M14 | Dynamic UI Visualization, Isolate Engine & CDSS Integration | `lib/ui/pkpd/`, `lib/ui/calculator/`, `lib/ui/calculator/controllers/` | M12, M13 | PLANNED |
| E2E | Comprehensive Opaque-Box E2E Testing Suite | `test/e2e/`, `TEST_INFRA.md`, `TEST_READY.md` (Tiers 1-4) | none (parallel) | DONE (38/38 passed) |
| M15 | Final Verification & Adversarial Hardening (Tier 5) | Pass 100% E2E tests, Adversarial Challenger loop, Forensic Integrity Audit | M14, E2E | PLANNED |
| M16 | Adrenaline Regimens, Infusion Unit Hardening & Bedside Volume | `lib/data/drugs/emergency.dart`, `specialized_dosing_calculator.dart`, `dosage_result_card.dart`, `iv_titration_screen.dart` | none | IN_PROGRESS |
| M17 | Pending Pharmacist Registry Evidence Ratification & Checklist | `lib/data/drugs/`, `pending_pharmacist_registry.dart`, `review/Pending_Pharmacist_Signoff_Checklist.md` | none | PLANNED |
| M18 | Comprehensive Adrenaline & Pending Registry Test Suite | `test/core/adrenaline_clinical_calculation_test.dart`, `test/core/pending_registry_clinical_audit_test.dart`, full regression | M16, M17 | PLANNED |


## Interface Contracts
### `PkSimulationEngine` & `PkSimulationParams`
- Location: `lib/core/calculators/pk_simulation_engine.dart`, `lib/core/models/pk_model.dart`
- Guarantees: Pure, deterministic functions. Computes 1-compartment and 2-compartment curves across 4 routes (IV Bolus, IV Intermittent Infusion, Oral Absorption, Continuous Infusion). Handles $k_a = k_e$ with exact L'Hopital limit. Discretizes 200-500 points with boundary pinning. Zero UI dependencies (pure Dart primitive DTOs for safe isolate passage).

### `SpecializedDosingCalculator` & `NtiSafetyGuard`
- Location: `lib/core/calculators/specialized_dosing_calculator.dart`, `lib/core/models/`
- Guarantees: Deterministic calculation for Vancomycin AUC/MIC (400-600) and trough; Aminoglycoside Hartford nomogram and peak/trough checks; Phenytoin Michaelis-Menten with saturation guard and Sheiner-Tozer / Winter-Tozer albumin correction; NTI electrolyte monitoring and distribution phase timing warnings; Special populations weight (TBW/IBW/AdjBW) and renal (elderly floor, pediatric Schwartz subpopulation k-values); High-alert continuous infusions (inotropes/vasopressors) with Rule 5 non-blocking overdose warning and `ClinicalOverrideJustification` logging.

### `PkChartPainter` & `PkSimulationController`
- Location: `lib/ui/pkpd/widgets/pk_chart_painter.dart`, `lib/ui/pkpd/controllers/pk_simulation_controller.dart`
- Guarantees: CustomPainter rendering MTC toxic red zone, MEC target green zone, sub-therapeutic zone, dual baseline/adjusted curves, and interactive touch scrubber crosshairs. Simulation execution offloaded via `Isolate.run` with sequence-token debouncing to guarantee sub-0.5ms UI rendering and zero touch stutter.

## Code Layout
```
lib/
├── core/
│   ├── calculators/
│   │   ├── pk_simulation_engine.dart         <-- Pure math engine for PK-PD modeling (M12)
│   │   ├── specialized_dosing_calculator.dart <-- Specialized NTI & High-Alert Dosing (M13)
│   │   ├── tdm_calculator.dart                <-- TDM individual kinetics and Hartford nomogram
│   │   ├── pharmacist_calculator.dart         <-- Ward dosage verification
│   │   ├── renal_calculator.dart              <-- Cockcroft-Gault, Schwartz, CKD-EPI
│   │   └── weight_based_calculator.dart       <-- TBW, IBW, AdjBW
│   └── models/
│       ├── pk_model.dart                      <-- PK route, compartment, parameters, simulation result (M12)
│       ├── specialized_dosing_models.dart     <-- NTI targets, Hartford intervals, override justification (M13)
│       └── patient.dart
├── ui/
│   ├── pkpd/
│   │   ├── controllers/
│   │   │   └── pk_simulation_controller.dart  <-- Isolate worker management, sequence tokens (M14)
│   │   └── widgets/
│   │       ├── pk_chart_painter.dart          <-- CustomPainter: MTC/MEC bands, dual curves, scrubber (M14)
│   │       ├── steady_state_pk_chart.dart     <-- Interactive gesture chart widget (M14)
│   │       ├── pk_data_table.dart             <-- Accessible WCAG AAA fallback table (M14)
│   │       ├── pk_parameter_sliders.dart      <-- Clearance, dose, tau sliders with live delta (M14)
│   │       └── pkpd_simulation_sheet.dart     <-- Full modal / bedside TDM sheet (M14)
│   └── calculator/
│       ├── controllers/
│       │   └── calculator_controller.dart     <-- Two-way PatientSession sync (M14)
│       └── widgets/
│           └── dosage_result_card.dart        <-- Dynamic NTI detection & PK-PD entry point (M14)
test/
├── core/
│   ├── pk_simulation_engine_test.dart        <-- Unit tests for M12
│   └── specialized_dosing_calculator_test.dart <-- Unit tests for M13
├── ui/
│   └── pkpd_chart_widget_test.dart            <-- Widget tests for M14
└── e2e/
    ├── e2e_pkpd_simulation_test.dart          <-- E2E Testing Track
    └── e2e_specialized_dosing_test.dart       <-- E2E Testing Track
```
