# DECISIONS.md — Clinical Pharmacist Decisions & Audit Trail

This document records all clinical decisions, human-in-the-loop policies, and open pharmacological questions requiring determination by a licensed Clinical Pharmacist under IEC 62304 / SaMD standards.

**Rule:** Items tagged `[PHARMACIST]` represent clinical judgment decisions and are NEVER marked automatically resolved by software. Every item records:
- Decision ID & Topic
- Status (`[PENDING CLINICAL PHARMACIST REVIEW]`, `[APPROVED]`, `[RATIFIED]`)
- Clinical options / trade-offs
- Responsible Pharmacist
- Date & Clinical Evidence Source

---

## 1. Renal Policy for CrCl < 10 mL/min (ESRD & Anuria)
- **ID:** `DEC-RENAL-001`
- **Topic:** Default clinical policy for severe renal impairment / CrCl < 10 mL/min when drug tiers omit explicit ESRD/dialysis dosing.
- **Status:** `[PENDING CLINICAL PHARMACIST REVIEW]`
- **Options Under Consideration:**
  - *Option A (Conservative Hard Block):* Hard-block automated dosing and mandate nephrology consult + ESRD protocol.
  - *Option B (Lowest Tier Retention):* Automatically apply the lowest reviewed tier (< 15 or < 30 mL/min) with prominent red warning.
  - *Option C (Renal Replacement Stratification):* Require explicit selection of renal replacement therapy (`none`, `hd`, `pd`, `crrt`) with distinct pulse-dosing guidelines.
- **Responsible Pharmacist:** Awaiting Hospital Pharmacy Committee / Clinical Pharmacist appointment
- **Date:** 2026-10-07
- **Source Reference:** Winter ME. *Basic Clinical Pharmacokinetics*. 5th ed.; The Sanford Guide to Antimicrobial Therapy 2024.

---

## 2. Missing SCr with Exactly One Known Criterion
- **ID:** `DEC-RENAL-002`
- **Topic:** Dosing policy for Apixaban / DOACs when serum creatinine is missing, but patient meets exactly 1 of 3 reduction criteria (e.g. Age ≥ 80, but weight and SCr unknown).
- **Status:** `[PENDING CLINICAL PHARMACIST REVIEW]`
- **Options Under Consideration:**
  - *Option A:* Hard-block pending SCr lab results.
  - *Option B:* Warn and maintain unreduced standard dose (5 mg BID) with advisory to check SCr before discharge.
  - *Option C:* Default to conservative 2.5 mg BID dose until complete criteria confirmed.
- **Responsible Pharmacist:** Clinical Specialist (Anticoagulation Stewardship)
- **Date:** 2026-10-07
- **Source Reference:** Eliquis® (apixaban) Prescribing Information (FDA 2021).

---

## 3. Adult High-Weight Dose Capping Allow-List (120 kg Sweep)
- **ID:** `DEC-CAP-001`
- **Topic:** Verification of maximum dose ceilings for obese patients (120 kg adult benchmark).
- **Status:** `[PENDING CLINICAL PHARMACIST REVIEW]`
- **Options Under Consideration:**
  - Ratify explicit `DosingRegimen.doseCap` with guideline citation for Enoxaparin (e.g., max 100 mg/dose for DVT treatment or 150 mg/dose), Acyclovir (max 1000 mg/dose), and N-acetylcysteine (100 kg weight cap).
  - Eliminate silent caps from calculation math; every cap must generate a visible `DoseWarningCode.doseCappedAtMax` warning.
- **Responsible Pharmacist:** Critical Care Pharmacist Specialist
- **Date:** 2026-10-07
- **Source Reference:** CHEST Guideline and Expert Panel Report: Antithrombotic Therapy for VTE Disease.

---

## 4. DKA Regular Insulin Titration Start Rate
- **ID:** `DEC-TITR-001`
- **Topic:** Starting headline rate vs rate range for IV regular insulin in Diabetic Ketoacidosis.
- **Status:** `[PENDING CLINICAL PHARMACIST REVIEW]`
- **Options Under Consideration:**
  - *Option A:* 0.1 Units/kg/hr fixed infusion (7.0 mL/hr at 1 U/mL for 70 kg adult).
  - *Option B:* 0.14 Units/kg/hr without loading bolus per ADA 2023 guideline.
- **Responsible Pharmacist:** Endocrinology Clinical Pharmacist
- **Date:** 2026-10-07
- **Source Reference:** American Diabetes Association (ADA) Standards of Care in Diabetes 2024; Kitabchi AE, et al. *Diabetes Care* 2009.

---

## 5. Acute Kidney Injury (Unstable SCr) Dosing & Kinetic GFR
- **ID:** `DEC-AKI-001`
- **Topic:** Automated dosing lock vs kinetic GFR estimates for rapidly changing creatinine.
- **Status:** `[PENDING CLINICAL PHARMACIST REVIEW]`
- **Decision:** Current engine implements a strict safety block (`LimitSeverity.hard`, `DoseWarningCode.unstableScr`) for renally-eliminated drugs, requiring documented clinical override for life-threatening empiric therapy while pending kinetic stabilization.
- **Responsible Pharmacist:** Nephrology & ICU Clinical Pharmacist
- **Date:** 2026-10-07
- **Source Reference:** KDIGO Clinical Practice Guideline for Acute Kidney Injury; Chen S. Retooling the Creatinine Clearance Equation to Estimate Kinetic GFR when the Plasma Creatinine Is Changing Acutely. *J Am Soc Nephrol*. 2013.

---

## 6. Emergency & Critical Care Overdose Non-Blocking Display Policy
- **ID:** `DEC-OVERDOSE-001`
- **Topic:** Numerical dose display behavior during overdose / limit exceeded events in emergency resuscitation.
- **Status:** `[RATIFIED CLINICAL POLICY]`
- **Policy Determination:**
  - Clinical pharmacists and physicians in emergency resuscitation require immediate access to computed numbers (dose, rounded dose, infusion pump rates, and dilution volumes) without encountering workflow-blocking modals or obscured text fields.
  - In emergency/rapid resuscitation contexts, the calculation engine flags overdose conditions via `LimitSeverity.hard` / `maxSingleDoseExceeded` / `maxDailyDoseExceeded`, and the UI displays the numbers immediately accompanied by a high-visibility warning banner (`⚠️ คำเตือน: ขนาดยานี้เกินเกณฑ์สูงสุดที่แนะนำ (Overdose Warning) — โปรดใช้ดุลยพินิจของแพทย์/เภสัชกรในการให้ยา`).
  - No blocking modal dialog or hidden text field shall obstruct rapid clinical execution.
- **Responsible Clinician:** Lead Clinical Pharmacist & Attending Physician
- **Date:** 2026-10-07
- **Source Reference:** Clinical Emergency Resuscitation Workflow Policy; SaMD Usability in Critical Care (IEC 62366-1).

---

## 7. Pharmacological Class Allergy vs. Cross-Reactivity Severity
- **ID:** `DEC-ALLERGY-001`
- **Topic:** Differentiation between intra-class contraindications and inter-class cross-reactivity.
- **Status:** `[RATIFIED CLINICAL POLICY]`
- **Policy Determination:**
  - **Direct Molecule Match:** Exact same active moiety (e.g. Amoxicillin -> Amoxicillin) = `LimitSeverity.hard` (`hasDirectMatch: true`).
  - **Intra-Class Beta-Lactams & Antimicrobials:** Patient allergic to a specific molecule (e.g. Amoxicillin) receiving another molecule within the same class (e.g. Ampicillin under `betaLactamPenicillin`) = Hard Class Contraindication (`LimitSeverity.hard`, `CLASS ALLERGY ALERT`).
  - **Inter-Class Beta-Lactam Cross-Reactivity:** Penicillin allergy vs. Cephalosporin (2–5%) or Carbapenem (~1%) = Soft Advisory (`LimitSeverity.soft`, `hasCrossReactivity: true`).
  - **NSAID Class:** Specific NSAID molecule (e.g. Mefenamic acid) vs. different NSAID (e.g. Ibuprofen) = Soft Cross-Reactivity (`LimitSeverity.soft`, `hasCrossReactivity: true`, COX-1 mediated advisory). A patient reporting whole-class allergy ("NSAID" / "เอ็นเสด") = Hard Contraindication (`LimitSeverity.hard`).
- **Responsible Pharmacist:** Infectious Disease & Allergy Stewardship Pharmacist
- **Date:** 2026-10-07
- **Source Reference:** Macy E, et al. *JAMA Netw Open*. 2021; Shenoy ES, et al. Evaluation and Management of Penicillin Allergy: A Review. *JAMA*. 2019.
