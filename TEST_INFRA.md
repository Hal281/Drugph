# Drugph End-to-End (E2E) Test Infrastructure & Clinical Quality Charter

## 1. Test Philosophy & Guiding Principles

The Drugph Clinical Decision Support System (CDSS) is designed for clinical pharmacists and intensive care physicians managing high-risk pharmacotherapy. The E2E test infrastructure enforces an **opaque-box, requirement-driven, deterministic testing methodology** derived directly from `ORIGINAL_REQUEST.md` and international clinical pharmacology consensus standards (ASHP/IDSA 2020 Vancomycin Guidelines, Sanford Guide 2024, Lexicomp, DiPiro, Rowland & Tozer, Winter's Basic Clinical Pharmacokinetics, and Bauer's Applied Clinical Pharmacokinetics).

### Core Quality Pillars:
1. **Opaque-Box Verification**: Tests evaluate system behavior strictly against clinical specifications and mathematical invariants without reliance on internal implementation details.
2. **Deterministic Output Derivation**: Every test assertion is derived from authoritative clinical literature formulas and reference models (e.g. Matzke 1984, Nicolau 1995, Sawchuk-Zaske 1976, Devine 1974, Cockcroft-Gault 1976, Bedside Schwartz, Sheiner-Tozer 1975, Michaelis-Menten kinetics, Bateman equation).
3. **Ironclad Clinical Rules Enforcement (`AGENTS.md` & `GEMINI.md`)**:
   - **Rule 1 (Zero Calculation Error)**: 100% mathematical accuracy across pharmacokinetic parameters, dose limits, unit conversions, and rate titrations.
   - **Rule 2 (Strict Evidence-Based Medicine)**: No fabricated drug data or unsupported dosing intervals.
   - **Rule 3 (Therapeutic Duplication Prevention)**: Zero tolerance for contraindicated duplicate active ingredients or classes.
   - **Rule 4 (Drug-Drug Interactions)**: Pharmacological mechanism and clinical management verification.
   - **Rule 5 (Non-Blocking Overdose Policy)**: Supratherapeutic doses or high-alert infusion rate breaches must NEVER be clamped, erased, or hidden from clinicians; they must display prominent clinical warnings while preserving exact calculated numbers and capturing structured override justifications.
4. **Isolation and Independence**: Every test case sets up its own state, executes deterministically, and produces zero cross-test interference.

---

## 2. Four-Tier Testing Methodology

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    TIER 4: REAL-WORLD CLINICAL SCENARIOS               │
│     ICU Septic Shock Resuscitation, Ward TDM Rounding, NICU/PICU Dosing │
├─────────────────────────────────────────────────────────────────────────┤
│                TIER 3: PAIRWISE COMBINATORIAL & CROSS-FEATURE           │
│   Sepsis AKI + Vanco, Obese + Hartford, Cirrhosis + Phenytoin, Override │
├─────────────────────────────────────────────────────────────────────────┤
│                 TIER 2: BOUNDARY VALUES & CORNER CASES                  │
│   ka=ke Singularity, Zero Clearance, Dose>=Vmax, Sarcopenia SCr Floor   │
├─────────────────────────────────────────────────────────────────────────┤
│                   TIER 1: FEATURE COVERAGE (PARTITIONS)                 │
│   1-Comp/2-Comp Routes, Steady-State, NTI Dosing, Weight/Renal, Vasos   │
└─────────────────────────────────────────────────────────────────────────┘
```

### Tier 1: Feature Coverage (Category-Partition)
Systematically covers each functional requirement across all defined partitions:
- **PK-PD Modeling (R1)**:
  - Compartment models: 1-Compartment, 2-Compartment ($V_c, V_p, k_{10}, k_{12}, k_{21}, \alpha, \beta, A, B$).
  - Administration routes: IV Bolus, IV Intermittent Infusion ($T_{\inf}$), Oral Absorption ($k_a, F$), Continuous Infusion ($k_0$).
  - Multi-dose accumulation: Accumulation factor $R = \frac{1}{1 - e^{-k_e \tau}}$, steady-state profiles ($C_{\max, ss}, C_{\min, ss}$).
  - Parameter derivations: $C_{\max}, C_{\min}, T_{\max}, \text{AUC}_{0-24}, t_{1/2}, k_e$.
  - Target windows: Sub-therapeutic ($< \text{MEC}$), Therapeutic ($\text{MEC} \le C \le \text{MTC}$), Toxic/Overdose ($> \text{MTC}$).
- **Specialized Dosing & Safety (R2)**:
  - Vancomycin: ASHP 2020 target $\text{AUC}_{24}/\text{MIC} \in [400, 600]\text{ mg}\cdot\text{h/L}$, surrogate trough targets ($15–20\text{ mcg/mL}$ vs $10–15\text{ mcg/mL}$).
  - Aminoglycosides: Hartford once-daily nomogram (7 mg/kg q24h, q36h, q48h, hold), conventional peak/trough validation ($C_{\max} \ge 8\times\text{MIC}$, trough $< 1–2\text{ mcg/mL}$).
  - Phenytoin: Non-linear Michaelis-Menten kinetics ($V_{\max} = 7\text{ mg/kg/day}, K_m = 4\text{ mg/L}$), Sheiner-Tozer albumin correction, Winter-Tozer renal modification ($CrCl < 20$).
  - NTI Electrolytes & Distribution: Hypokalemia ($K^+ < 3.5$) and hypomagnesemia ($Mg^{2+} < 1.7$) toxicity potentiators for Digoxin; Digoxin $6–8\text{h}$ alpha distribution sampling warning.
  - Special Populations: Weight selection (TBW, Devine IBW, AdjBW 0.4; mandatory AdjBW for obese patients on aminoglycosides); Renal function (Cockcroft-Gault with elderly SCr floor $0.8\text{ mg/dL}$, pediatric Bedside Schwartz with subpopulation $k$-values $0.33, 0.45, 0.413$).
  - High-Alert Infusions: Inotropes/vasopressors (Norepinephrine, Epinephrine, Dopamine, Dobutamine) standard and double dilutions, rate conversions ($\text{mcg/kg/min} \to \text{mL/hr}$), and titration limit alerts.

### Tier 2: Boundary Value Analysis & Corner Cases
Exercises extreme limits, mathematical singular points, and system resilience:
- Bateman equation singularity: Exact L'Hôpital limit evaluation when $k_a = k_e$ ($C(t) = \frac{F D k_e}{V_d} t e^{-k_e t}, T_{\max} = 1/k_e$).
- Renal clearance bounds: Anuria ($CrCl = 0$, baseline non-renal $k_e$) and augmented renal clearance ($CrCl \ge 180\text{ mL/min}$).
- Absorption dynamics: Flip-flop kinetics ($k_a < k_e$, terminal slope reflects absorption).
- Infusion duration limits: $T_{\inf} \to 0$ smoothly converging to IV bolus; $T_{\inf} \ge \tau$ rejected with `ArgumentError`.
- Capacity limits: Phenytoin dose reaching or exceeding $V_{\max}$ ($Dose \ge V_{\max}$), triggering saturation guard.
- Patient morphology extremes: Cachectic/underweight ($TBW < IBW$ preventing toxic overestimation), morbid obesity ($BMI \ge 35$), sarcopenic geriatric patient ($SCr < 0.8\text{ mg/dL}$ triggering $0.8$ floor).
- Input safety: Negative, zero, or non-finite inputs ($NaN, \infty$).

### Tier 3: Pairwise Combinatorial & Cross-Feature Integration
Verifies interactions between orthogonal clinical dimensions:
- Dynamic PK comparisons: Multi-dose oral vs IV intermittent regimens under fluctuating clearance (CrCl slider dynamics).
- Complex clinical combinations:
  - Sepsis ICU patient with Acute Kidney Injury (AKI) receiving Vancomycin.
  - Morbidly obese diabetic patient receiving Gentamicin Hartford nomogram (enforcing AdjBW 0.4).
  - Cirrhotic hypoalbuminemic patient on Phenytoin (Sheiner-Tozer correction predicting toxicity despite normal raw level).
  - Refractory septic shock patient receiving Norepinephrine exceeding standard ceiling ($> 1.0\text{ mcg/kg/min}$) with structured clinical override justification logging.

### Tier 4: Real-World Hospital Workload Scenarios
End-to-end simulations of actual ward and intensive care clinical workflows:
1. **ICU Septic Shock Resuscitation Protocol**:
   - Arterial hypotension resuscitation with titrated Norepinephrine.
   - Empiric Vancomycin loading dose ($25–30\text{ mg/kg}$) with Red Man Syndrome rate capping.
   - Capillary leak volume expansion ($V_d = 0.85\text{ L/kg}$) and therapeutic target attainment.
2. **Clinical Pharmacist Ward TDM Morning Rounding**:
   - 2-point Sawchuk-Zaske kinetic evaluation on post-infusion levels.
   - Detecting and flagging premature Digoxin levels drawn at $2\text{h}$ post-dose ($< 6–8\text{h}$ distribution window).
   - Recommending extended Hartford interval for slow aminoglycoside clearance.
3. **Neonatal & Pediatric Antimicrobial Dosing**:
   - Preterm infant ($< 37\text{ weeks}$, $k=0.33$) Schwartz clearance estimation.
   - Infant Gentamicin dosing avoiding pediatric toxic accumulation.

---

## 3. Directory Layout & Architecture

```
test/
├── core/
│   ├── calculators_test.dart
│   ├── tdm_calculator_test.dart
│   └── ...
├── ui/
│   ├── calculator_modular_test.dart
│   └── ...
└── e2e/
    ├── e2e_pkpd_modeling_test.dart         <-- R1 Comprehensive PK-PD Suite (Tiers 1-4)
    └── e2e_specialized_dosing_test.dart    <-- R2 Specialized Dosing Suite (Tiers 1-4)
```

---

## 4. Test Execution & Verification Commands

### Execute Full E2E Test Suite
```powershell
flutter test test/e2e/
```

### Execute PK-PD Modeling E2E Suite
```powershell
flutter test test/e2e/e2e_pkpd_modeling_test.dart
```

### Execute Specialized Dosing E2E Suite
```powershell
flutter test test/e2e/e2e_specialized_dosing_test.dart
```

### Run Static Analysis
```powershell
dart analyze test/e2e/
```
