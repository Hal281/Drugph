# Project: Drugph Phase 1

## Architecture
- Layered Decoupling:
  - **Domain / Core (`lib/core/`)**: Pure entities, calculators, validators, and deterministic clinical formatters (`ClinicalOrderFormatter`). Zero dependencies on Flutter UI or network SDKs.
  - **Data (`lib/data/`)**: Drug monographs, renal adjustment tables, formulary datasets, clinical evidence.
  - **Presentation / UI (`lib/ui/`)**: Declarative widgets (`CalculatorScreen`), state handlers, clipboard interactions, and responsive clinical UI.
- Web Shell & CI/CD:
  - `web/manifest.json`: Offline PWA manifest with clinical metadata and standalone display.
  - `web/index.html`: Responsive viewport, theme colors, and CSS/HTML pre-frame loading spinner.
  - `pubspec.yaml` & `assets/fonts/`: Local font bundling (`ThaiFont.ttf`) for 100% offline CanvasKit rendering.
  - `.github/workflows/flutter_web.yml`: Automated test & static analysis gating, zero secret exposure, offline release build.

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | PWA Manifest & Shell | Clinical metadata, standalone config, responsive viewport, theme color | M1 | ORIGINAL_REQUEST §R1 |
| 2 | Pre-Frame Web Loader | HTML/CSS loading spinner before Flutter CanvasKit first frame | M1 | ORIGINAL_REQUEST §R1 |
| 3 | Local Thai Font Bundling | `ThaiFont.ttf` registered under `flutter: fonts:` in `pubspec.yaml` and wired into app theme | M1 | ORIGINAL_REQUEST §R1 |
| 4 | Secure GitHub Pages CI/CD | Automated test/lint gate, offline build flags, zero GEMINI_API_KEY exposure | M1 | ORIGINAL_REQUEST §R1 |
| 5 | Deterministic HIS Order Formatter | 1-line HIS order covering standard, renal-adjusted, IV infusion, overdose/unverified tags | M2 | ORIGINAL_REQUEST §R2 |
| 6 | Deterministic Pharmacist Note Formatter | Structured multi-line note with patient params, regimen, calculation, provenance, safety | M2 | ORIGINAL_REQUEST §R2 |
| 7 | Result Card Dual Copy UI | Side-by-side buttons on result card, >= 48dp touch height, immediate clipboard copy & feedback | M2 | ORIGINAL_REQUEST §R2 |
| 8 | Non-Blocking Overdose Preservation | Overdose banner distinct from safety banner, calculated/rounded doses never hidden | M2 | ORIGINAL_REQUEST §R3 |
| 9 | PWA & CI Automated Test Suite | Unit tests validating manifest, index.html, font registration, theme, and workflow security | M1 | ORIGINAL_REQUEST §Verification |
| 10 | Clinical Formatter Unit Tests | Unit tests verifying all 5 clinical scenarios (standard, renal, IV titration, overdose, unverified) | M2 | ORIGINAL_REQUEST §Verification |
| 11 | Calculator Copy Widget Tests | Widget tests verifying button height (>=48dp), clipboard payload interception, SnackBar, and intact banners | M2 | ORIGINAL_REQUEST §Verification |
| 12 | End-to-End Build & Static Analysis Gate | Full verification gate: flutter test 100%, dart analyze 0 issues, flutter build web offline | M3 | ORIGINAL_REQUEST §Verification |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Offline-First PWA & CI/CD | `web/manifest.json`, `web/index.html`, `pubspec.yaml`, `lib/main.dart`, `.github/workflows/flutter_web.yml`, `test/pwa_offline_web_ci_test.dart` | none | DONE |
| M2 | Deterministic Clinical Formatter & Result Card UI | `lib/core/formatters/clinical_order_formatter.dart`, `lib/core/core.dart`, `lib/ui/calculator_screen.dart`, `test/core/clinical_order_formatter_test.dart`, `test/ui/calculator_copy_buttons_test.dart` | none | DONE |
| M3 | Comprehensive Verification Gate & Build Validation | `flutter test --no-pub`, `dart analyze`, `flutter build web --release --base-href "/Drugph/" --no-web-resources-cdn --pwa-strategy=offline-first` | M1, M2 | DONE |

## Interface Contracts
### `ClinicalOrderFormatter` Contract
- Location: `lib/core/formatters/clinical_order_formatter.dart`
- Methods:
  ```dart
  class ClinicalOrderFormatter {
    static String formatHisOrder({
      required Patient patient,
      required Drug drug,
      required DosingRegimen regimen,
      required DosageResult result,
      bool isThai = false,
    });

    static String formatPharmacistNote({
      required Patient patient,
      required Drug drug,
      required DosingRegimen regimen,
      required DosageResult result,
      bool isThai = false,
    });
  }
  ```
- Constraints: Pure Dart function, deterministic, zero UI/network imports, zero runtime LLM.

## Code Layout
- `web/manifest.json` (Web PWA Manifest)
- `web/index.html` (Web Entry Shell with Loader)
- `pubspec.yaml` (Asset & Font Declarations)
- `lib/main.dart` (Application Theme & Typography Wiring)
- `.github/workflows/flutter_web.yml` (GitHub Actions CI/CD Pipeline)
- `lib/core/formatters/clinical_order_formatter.dart` (Pure Deterministic Clinical Formatter)
- `lib/core/core.dart` (Core Export Barrel)
- `lib/ui/calculator_screen.dart` (Dosage Calculator Screen & Copy Buttons)
- `test/pwa_offline_web_ci_test.dart` (PWA & CI Configuration Tests)
- `test/core/clinical_order_formatter_test.dart` (Formatter Unit Tests)
- `test/ui/calculator_copy_buttons_test.dart` (Calculator UI Copy Widget Tests)
- `test/core/clinical_order_formatter_stress_test.dart` (Adversarial Invariant Stress Tests)
- `test/ui/calculator_copy_buttons_adversarial_test.dart` (Adversarial Touch & Safety Tests)
