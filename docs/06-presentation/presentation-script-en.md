# Presentation Script (English) — Drugph (5-Speaker Defense & Live Demo)

> **Course:** Introduction to Software Engineering (15031001) — Academic Year 2569  
> **Target Duration:** **11:30 minutes** (within the 10–12 minute window, excluding Q&A)  
> **Format:** Divided by **Speaker 1 – Speaker 5** (plus 4-speaker merge option)

---

## 1. Speaker Allocation & Timebox

| Speaker | Name (Fill In) | Scope | Duration | Cumulative |
| :--- | :--- | :--- | :---: | :---: |
| **Speaker 1** | `[Member 1]` | Intro, Real Problem (5 Whys + Gate 1 Users), MoSCoW & 5 Ironclad Rules | 02:15 | `00:00 – 02:15` |
| **Speaker 2** | `[Member 2]` | The Golden Thread, 3-Tier Clean Architecture & ADRs | 02:15 | `02:15 – 04:30` |
| **Speaker 3** | `[Member 3]` | Clinical Safety Guardrails (5 Duplication Pairs, DDI, Cross-Reactivity, Rule 5) | 01:30 | `04:30 – 06:00` |
| **Speaker 4** | `[Member 4]` | **Live Demo** (Gentamicin AdjBW → Vancomycin Rule 5 + Monograph → Cart DDI → PK/PD & TDM) | 03:15 | `06:00 – 09:15` |
| **Speaker 5** | `[Member 5]` | Verification & 48-Page Dossier, AI-First Reflection, Conclusion & Q&A | 02:15 | `09:15 – 11:30` |

> **4-Speaker Option:** Merge **Speaker 3** into **Speaker 4** (Safety Guardrails directly into Live Demo) or append Speaker 3's section to **Speaker 2**.

---

## 2. Pre-Demo Checklist

1. Launch the app in Desktop Split-View (`width > 800px`):
   ```powershell
   cd c:\Users\turbo\drugforPh
   flutter run -d chrome
   ```
2. Switch the top-right language toggle to **EN** (`TH` button visible = English active).
3. Ensure `PatientBanner` is reset (`No Patient Selected`) and `Prescription Cart` has `0` items.
4. Keep `review/Clinical_Verification_Dossier.pdf` open in a backup browser tab for Q&A.

---

## 3. Spoken Script (Speakers 1 – 5)

---

### Speaker 1: Problem, Real Users, MoSCoW & 5 Ironclad Rules (`00:00 – 02:15`)

> "Good morning/afternoon professors and committee members. We are team `[Team Name]`, presenting **Drugph** — a **deterministic** clinical drug dosage calculation and safety verification engine designed for physicians and clinical pharmacists.
>
> To be transparent up front: Drugph is currently an **Educational SaMD Prototype** built for software engineering education and verification — it is not a certified medical device for real patient care, though every component is engineered to clinical decision-support standards.
>
> The project starts from a real pain point in intensive care and internal medicine wards. High-alert, narrow-therapeutic-index drugs like Vancomycin and Gentamicin cannot use fixed doses — they must be tailored to weight, height, age, and renal function under intense time pressure.
>
> Through a **5 Whys** root cause analysis, we identified three core gaps:
> 1. Clinicians must manually chain 3 to 4 nested equations — CrCl, Ideal Body Weight, Adjusted Body Weight, and renal dosing tiers.
> 2. **The Decimal Boundary Gap:** Textbook dosing tables use integer CrCl brackets like `10–25` and `26–50 mL/min`, whereas real lab values have decimals such as `25.5 mL/min`, causing patients to fall between tiers and receive an unadjusted full dose.
> 3. Legacy hospital HIS platforms often lack deep pharmacokinetic support, while web calculators require constant internet access and pose PDPA privacy risks.
>
> In Gate 1, we interviewed three real clinical users — an **ICU Clinical Pharmacist**, an **Internal Medicine Nurse**, and a **Clinical Pharmacy Clerkship Student**. All three confirmed the need for immediate missing-SCr alerts on renally cleared drugs, strict avoidance of assumed IV dilution volumes, and ASHP 2020 Vancomycin **AUC₂₄** targeting.
>
> We translated these needs into MoSCoW requirements: **Must Have** FR-01 through FR-04 (renal estimation, IBW/AdjBW, continuous renal dosing, and safety limits) and **Should Have** FR-05 (TDM AUC₂₄).
>
> To enforce medical-software discipline, we established **5 Ironclad Rules**:
> 1. **Zero-Error Calculation:** All dosing math uses pure deterministic functions — zero AI/LLM in the dosing loop.
> 2. **Strict Evidence-Based Medicine:** Grounded solely in 7 standard references such as Sanford Guide 2024 and Lexicomp.
> 3. **Therapeutic Duplication Prevention:** Detect duplicate active ingredients and contraindicated same-class pairs.
> 4. **Real Pharmacology DDI & Allergy:** Surface mechanism, severity, and management.
> 5. **Non-Blocking Overdose Policy:** Never lock the screen or hide computed doses during an overdose — display the dose clearly alongside a high-visibility red warning banner for emergency resuscitation.
>
> I'll now hand over to `[Speaker 2]` to walk through our Golden Thread and architecture."

---

### Speaker 2: The Golden Thread, 3-Tier Clean Architecture & ADRs (`02:15 – 04:30`)

> "Thank you. From a Software Engineering perspective, our central anchor is **The Golden Thread** — linking **Problem → Requirement → Design → Feature → Automated Test** without a single broken link.
>
> Take our first trace:
> - **Problem:** Obese patients receive toxic Aminoglycoside overdoses when dosed by total body weight.
> - **Requirement (FR-02):** Automatically switch to Adjusted Body Weight when weight reaches 120% of IBW or higher.
> - **Design:** `WeightBasedCalculator` and `RenalCalculator` in the domain layer.
> - **Feature:** For a 120 kg, 170 cm patient, the engine selects `AdjBW = 87.56 kg` and computes `Gentamicin 437.81 mg` instead of `600 mg`.
> - **Test:** `cockcroft_gault_renal_dosing_test.dart` verifies this exact result.
>
> Similarly, the `CrCl 25.5` boundary gap is solved via continuous tiers in `RenalAdjustment` and verified in `engine_test.dart`.
>
> Architecturally, Drugph follows a strict **3-Tier Clean Architecture** for High Cohesion and Low Coupling:
> 1. **Data Layer (`lib/data/`):** Holds **119 active drugs** and **4 archived specialty drugs**, a sub-2ms `DrugSearchEngine`, and `PrescriptionCart`.
> 2. **Domain / Logic Layer (`lib/core/`):** 100% Pure Dart with zero Flutter UI imports and zero network calls. `PharmacistCalculator`, `TdmCalculator`, and `PkSimulationEngine` live here, making exhaustive unit testing straightforward.
> 3. **Presentation Layer (`lib/ui/`):** Material 3 on an 8-pt spacing grid with WCAG AAA `>= 48 dp` touch targets. The UI only passes inputs and renders DTOs — no math is permitted inside widgets.
>
> This drove **ADR-01: 100% Client-Side Deterministic Execution**. Everything runs in local RAM with under 100 ms latency, works **100% offline** in dead-zone ORs or ICUs, and leaks zero patient data externally under **PDPA**.
>
> Next, `[Speaker 3]` will explain how our clinical safety guardrails protect against prescribing errors."

---

### Speaker 3: Clinical Safety Guardrails (`04:30 – 06:00`)

> "Thank you. On the clinical safety side, we built three defensive layers inside `lib/core/validators/` and `lib/core/models/`.
>
> **Layer 1: Therapeutic Duplication Prevention (`TherapeuticDuplicationService`)**
> Beyond identical-molecule duplicates, the engine blocks **5 contraindicated same-class combinations**:
> 1. **Dual NSAIDs** (e.g., Ibuprofen + Naproxen) — GI bleeding and acute kidney injury risk.
> 2. **Dual RAS Blockade** (ACEI + ARB, e.g., Enalapril + Losartan) — severe hyperkalemia.
> 3. **Dual Oral Anticoagulants** (Warfarin + DOAC or dual DOACs) — fatal hemorrhage risk.
> 4. **Dual Statins** — rhabdomyolysis risk.
> 5. **Dual Potassium-Sparing Diuretics** — life-threatening hyperkalemia.
>
> **Layer 2: DDI & Allergy Cross-Reactivity**
> `AllergyService` resolves generic names, Thai and international brand aliases (such as *Ponstan* or *Voltaren* mapping to NSAIDs), and distinguishes same-class hard contraindications from inter-class Beta-lactam cross-reactivity advisories. `ClinicalInteractionRegistry` catches major interactions like `Vancomycin + Gentamicin` with full mechanism and management guidance.
>
> **Layer 3: Ironclad Rule 5 — Non-Blocking Overdose Policy (`DEC-OVERDOSE-001`)**
> In an ER resuscitation, a modal that hides a dose stops clinicians from treating a dying patient. Our `SafetyAlertBanner` displays a prominent red warning banner **while keeping the exact calculated dose fully visible** for immediate clinical judgment.
>
> Now let's see all of this running live with `[Speaker 4]`."

---

### Speaker 4: Live Demo (`06:00 – 09:15`)

- *(Click `PatientBanner` → Enter Male, Age `60`, Weight `120`, Height `170`, SCr `1.8` → Save)*
> "Let's look at Drugph running live in Desktop Split-View. Today's patient is a **60-year-old male, 170 cm tall, weighing 120 kg** — 182% of his ideal weight — with a **serum creatinine of 1.8 mg/dL**."

- *(Search `Gentamicin` → Select → Calculate)*
> "Suppose he has severe sepsis and the team orders **Gentamicin**. Watch the right pane:
> 1. The engine computes **Devine IBW = `65.94 kg`**, detects obesity (`>= 120% IBW`), and automatically switches to **Adjusted Body Weight (`AdjBW`) = `87.56 kg`**, producing **`437.81 mg`** instead of a toxic `600 mg` from total body weight.
> 2. Cockcroft-Gault also uses `AdjBW`, yielding **`CrCl = 54.05 mL/min`** — rather than an inflated `74.07 mL/min` — so the interval automatically extends from `q24h` to **`q36h`**, alongside the **IV Diluent Compatibility** card."

- *(Click `Add to Cart` for Gentamicin → Search `Vancomycin` → Select → Calculate)*
> "Next, let's check **Vancomycin** for the same patient. Notice the maintenance calculation (`15 mg/kg × 120 kg`) returns **`1,800.0 mg q12–24h`**, exceeding the `1,500 mg` soft limit. The **red Overdose Warning banner** appears immediately, yet **`1,800.0 mg` remains clearly visible** — that is **Rule 5 Non-Blocking Overdose** in action. Below it, the engine warns for a minimum **`180-minute` infusion** to prevent Red Man Syndrome, and provides one-tap **`Copy HIS Order`** and **`Copy Pharmacist Note`** buttons."

- *(Click `View Textbook Monograph`)*
> "To verify the numbers against medical literature, clicking **`View Textbook Monograph`** opens `ClinicalEvidenceSheet` showing **Sanford Guide 2024 (54th Ed., Table 10A & 10B)**, renal tiers, IV dilution instructions, and provenance status."

- *(Close modal → Click `Add to Cart` for Vancomycin → Open `Prescription Cart` icon)*
> "Adding Vancomycin alongside Gentamicin and opening the **Prescription Cart** immediately triggers a **Major DDI alert** explaining additive proximal tubular nephrotoxicity and ototoxicity, recommending close SCr and TDM monitoring. Similarly, pairing **Ibuprofen + Naproxen** triggers a **Hard Contraindication for Dual NSAIDs**."

- *(Return to Vancomycin → Click `📈 PK-PD Simulation & Predictive Curve` → Toggle `📋 Data Table` → Close → Click `TDM Calculator`)*
> "Finally, for narrow-therapeutic-index drugs like Vancomycin, clicking **`PK-PD Simulation & Predictive Curve`** renders an interactive 1-compartment steady-state curve, with a WCAG AAA **Data Table** toggle.
>
> Opening **`TDM Calculator`** for this patient (`CrCl 54.05 mL/min`) lets the pharmacist simulate **ASHP/IDSA 2020 Steady-State AUC₂₄**: `750 mg q12h` yields `362.5 mg·h/L` (subtherapeutic), whereas **`1,000 mg q12h`** hits **`483.3 mg·h/L`**, right inside the **`400–600 mg·h/L`** target, with built-in Red Man Syndrome rate guards.
>
> Handing over to `[Speaker 5]` for verification results and AI reflection."

---

### Speaker 5: Verification, AI-First Reflection & Closing (`09:15 – 11:30`)

> "Thank you. On software verification:
> - `dart analyze` reports **0 Errors, 0 Warnings (No issues found)**.
> - `flutter test` across **85 test files** ran **1,161 tests**, with **1,160 passing** — 100% of clinical math, Golden cases `G-01` through `G-15`, safety/DDI, widget UI, and E2E PK/PD tests passed. The single failure was a search latency benchmark (`< 1 ms` target vs `1.321 ms` median under full parallel suite load).
>
> Equally critical is **Clinical Governance** in `TRACEABILITY_MATRIX.md`. We strictly separate **Automated Code Verification** from **Human Clinical Validation**. Drug entries remain locked at `PENDING_HUMAN_VERIFICATION` until licensed clinical pharmacists (`ภ.`) and attending physicians (`ว.`) review our auto-generated **48-page `Clinical_Verification_Dossier.pdf`** against textbooks and sign off.
>
> On **AI-First Engineering**, AI accelerated edge-case discovery and scaffolding for over a thousand tests, but we caught and fixed three critical AI mistakes:
> 1. **Math Precision Error:** AI misapproximated `170 cm` in inches and wrote a test expecting `IBW 66.86 kg`. We manually recalculated Devine's formula (`170 / 2.54 = 66.929 in`) to **`65.94 kg`** (`AdjBW 87.56 kg`) and corrected the assertions.
> 2. **Outdated Guidelines:** AI initially drafted 2009 trough-only Vancomycin monitoring (`15–20 mg/L`); we upgraded the engine to **ASHP 2020 AUC₂₄**.
> 3. **Unsubstantiated Assumptions:** Early IV titration code assumed `100/250 mL` diluent volumes; we removed all guessed defaults and enforced explicit concentration inputs.
>
> The takeaway is clear: **AI boosts engineering velocity, but in medical software, Human-in-the-Loop verification is non-negotiable.**
>
> In summary, **Drugph** delivers **100% deterministic dosing**, **non-blocking clinical safety**, and **end-to-end textbook traceability**. Thank you — we are ready for your questions."

---

## 4. Q&A Defense Highlights (30–45 sec each)
- **Why not block the screen on Overdose?** → `DEC-OVERDOSE-001` (Rule 5): Emergency resuscitation clinicians need immediate numbers alongside a clear red warning banner.
- **Why no LLM in dose calculation?** → LLMs are probabilistic and prone to math hallucinations (as seen with the `66.86 vs 65.94 kg` IBW error); `AiConsultantScreen` is strictly isolated from `PharmacistCalculator`.
- **Is it ready for live hospital use?** → No — clearly labeled as an Educational SaMD Prototype (`PENDING_HUMAN_VERIFICATION`), backed by a 48-page Dossier PDF for formal `ภ.` / `ว.` sign-off.
- **Why 100% Client-Side instead of Cloud/HIS?** → `ADR-01`: Offline reliability in OR/ICU dead zones, `< 100 ms` latency, and zero external patient-data leakage under PDPA, with `Copy HIS Order` for workflow handoff.
- **What is the 1 failing test in `flutter test`?** → `challenger_m1_icu_search_adversarial_test.dart` latency benchmark (`1,321 µs` vs `< 1,000 µs` target under full parallel load); all clinical math, safety, and UI tests passed 100%.
