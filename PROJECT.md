# Project: Drugph Comprehensive Multi-Perspective Audit & Remediation

## Architecture
- **Layer 1: Core Domain & Pure Calculators** (`lib/core/calculators/`, `lib/core/models/`, `lib/core/validators/`)
  - Deterministic calculation engines: `RenalCalculator`, `BsaCalculator`, `WeightBasedCalculator`, `IvRateCalculator`, `PharmacistCalculator`, `SpecializedDosingCalculator`.
  - Zero dependencies on Flutter UI; 100% pure functions, mathematically guarded against zero-division, negative inputs, non-finite values, and extreme ranges.
- **Layer 2: Clinical Data, Knowledge Base & Safety Interceptors** (`lib/data/`, `lib/data/drugs/`, `lib/data/safety/`)
  - Formularies, clinical monographs, provenance, `TherapeuticDuplicationService`, `ClinicalInteractionRegistry`.
- **Layer 3: Presentation & User Interface** (`lib/ui/`, `lib/ui/calculator/`, `lib/ui/widgets/`)
  - Responsive widgets, bedside `ClinicalEvidenceSheet`, `DosageResultCard`, `SafetyAlertBanner`, `IVTitrationScreen`, `PatientDashboardScreen`.

## Feature Inventory
| # | Feature | Description | Milestone | Source | Status |
|---|---------|-------------|-----------|--------|--------|
| 1 | Baseline Static & Dynamic Stability | `flutter analyze` 0 issues, 1,134 unit/widget tests passing 100% | M1 | Tester Survey | VERIFIED |
| 2 | Pure Arithmetic Safety & Boundary Guards | Division-by-zero, negative, non-finite, extreme weight/CrCl guards in pure calculators | M1 | Tester/Pharmacist | VERIFIED |
| 3 | Rule 5 Non-blocking Overdose Policy | Preserving exact calculated/rounded doses in bold 36pt font while displaying prominent crimson warning banner | M1 | All Auditors | VERIFIED |
| 4 | Multi-Strength Vasopressor Concentration Presets | Enable Single (16 mcg/mL), Double (32 mcg/mL), Quad (64 mcg/mL), and Syringe Pump concentrations in `IVTitrationScreen` | M1 | Physician Survey | VERIFIED |
| 5 | Reverse Titration Calculator | Bidirectional titration calculation (`mL/hr -> mcg/kg/min`, `mcg/min`, `mcg/kg/hr`) with Rule 5 overdose banner | M1 | Physician Survey | VERIFIED |
| 6 | `RateUnit.mcgMin` Support | Standard non-weight-based rate unit (`mcg/min`) for vasopressor titrations | M1 | Physician Survey | VERIFIED |
| 7 | Missing Critical ICU Formularies | Registration of `Vasopressin`, `Propofol`, `Dexmedetomidine`, and `Midazolam` (121 total drugs) | M1 | Physician Survey | VERIFIED |
| 8 | Multi-Phase Antidote UI Rendering | Render `activePhases` (e.g. 3-bag NAC paracetamol antidote) in `DosageResultCard` with 100 kg obesity cap | M1 | Physician Survey | VERIFIED |
| 9 | Search Engine Cold-Start Resilience | Pre-warm / optimize `DrugSearchEngine` with cached regexes (mean 0.465ms latency) | M1 | Pharmacist/Tester | VERIFIED |
| 10 | 320dp 1.5x Text Scale Layout Overflow Fix | Remediate 92-99px RenderFlex horizontal overflow in `clinical_header_alerts.dart` and `dosing_parameters_form.dart` | M2 | Tester Survey | VERIFIED |
| 11 | Interactive Data Entry & Sanitization | Validate live interactive behavior, unit switching, keyboard types, and responsive layout across screens | M2 | All Perspectives | VERIFIED |
| 12 | Comprehensive Multi-Perspective Audit Report | Formal report detailing Tester/Dev, Pharmacist, and Physician observations, risk assessments, and remediations | M3 | Requirement R1 | VERIFIED |
| 13 | Final Clinical & Engineering Verification Gate | Automated tests pass (0 failures), static analysis passes (0 issues), dossier PDF regenerated | M3 | All Perspectives | VERIFIED |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Emergency & High-Alert Clinical Calculation Remediation | Vasopressor multi-strength presets, reverse titration, `RateUnit.mcgMin`, ICU drugs (`vasopressin`, `propofol`, `dexmedetomidine`, `midazolam`), multi-phase antidote rendering, search engine cold-start | Survey complete | DONE |
| M2 | UI/UX Layout, Accessibility & Live Data Entry Remediation | Fix 320dp 1.5x text scale RenderFlex overflows in alerts & forms, test interactive live data entry, input sanitization, and unit pickers | M1 | DONE |
| M3 | Multi-Perspective Audit Report & Final Acceptance Gate | Generate comprehensive multi-perspective audit report (`review/Multi_Perspective_Audit_Report.md`), verify `flutter test`, `dart analyze`, and dossier generation | M1, M2 | DONE |

## Key Verification Artifacts
- Formal Report: `c:\Users\turbo\drugforPh\review\Multi_Perspective_Audit_Report.md`
- Pharmacist Dossier PDF: `c:\Users\turbo\drugforPh\review\Clinical_Verification_Dossier.pdf` (48 pages, 121 drugs, 235.2 KB)
- Full Test Suite: `flutter test` (1,134 passed, 0 failed)
- Static Analysis: `dart analyze` (0 issues found)
