# Presentation Diagrams — Drugph
> ชุดไดอะแกรมสถาปัตยกรรม, Flow ความปลอดภัย, ลำดับการทำงาน Live Demo, และวงจรการตรวจรับรองทางคลินิก (Mermaid Syntax-Validated)

---

## 1. System Architecture & Safety Pipeline (3-Tier Clean Architecture)
*แสดงการแยก Layer ออกจากกันอย่างชัดเจน และยืนยันว่า `AiConsultantScreen` แยกขาดจาก `PharmacistCalculator` (Zero Runtime AI in Dosing)*

```mermaid
flowchart TB
    subgraph UI_Layer["1. Presentation Layer (lib/ui/) — Material 3 / 8-pt Grid / WCAG AAA >= 48dp"]
        Home["HomeScreen & PatientBanner"]
        CalcUI["CalculatorScreen & DosageResultCard"]
        CartUI["PrescriptionCartScreen"]
        TdmUI["TdmScreen & PkPdSimulationSheet"]
        MonographUI["ClinicalEvidenceSheet (Textbook Modal)"]
        AiUI["AiConsultantScreen (Isolated Advisory UI)"]
    end

    subgraph Core_Layer["2. Domain & Deterministic Logic Layer (lib/core/) — Pure Dart (Zero UI / Zero Network)"]
        Calc["PharmacistCalculator (Master Coordinator)"]
        Renal["RenalCalculator (CG Auto-Weight / CKD-EPI 2021)"]
        Weight["WeightBasedCalculator (Devine IBW / AdjBW 0.4)"]
        Tdm["TdmCalculator & PkSimulationEngine (ASHP 2020 AUC24)"]
        Dup["TherapeuticDuplicationService (5 Contraindicated Pairs)"]
        Allergy["AllergyService (Direct + Cross-Reactivity)"]
        Ddi["ClinicalInteractionRegistry & DoseChecker"]
        Rule5["SafetyAlertBanner Logic (Rule 5 Non-Blocking Overdose)"]
    end

    subgraph Data_Layer["3. Data & Knowledge Layer (lib/data/) — 100% Offline In-Memory"]
        DB["DrugDatabase (119 Active + 4 Archived Specialty Drugs)"]
        Search["DrugSearchEngine (JIT Regex Cache)"]
        Cart["PrescriptionCart & PatientSession"]
        Validator["SchemaValidator (Human Sign-Off Lock)"]
    end

    Home --> CalcUI
    Home --> CartUI
    CalcUI --> MonographUI
    CalcUI --> TdmUI
    CalcUI -->|"Patient & Drug DTO"| Calc
    TdmUI -->|"PK/AUC24 Params"| Tdm
    CartUI -->|"Cart Drug List"| Cart

    Calc --> Renal
    Calc --> Weight
    Calc --> Dup
    Calc --> Allergy
    Calc --> Ddi
    Calc --> Rule5

    Cart --> Dup
    Cart --> Allergy
    Cart --> Ddi

    Calc -->|"Lookup Rules & Tiers"| DB
    Home -->|"Query"| Search
    Search --> DB
    DB --> Validator
```

---

## 2. Live Demo End-to-End Sequence Diagram
*ลำดับเหตุการณ์จริงใน Live Demo (ผู้ป่วยชาย 60 ปี, 170 cm, 120 kg, SCr 1.8 mg/dL)*

```mermaid
sequenceDiagram
    autonumber
    actor Presenter as ผู้สาธิต (คนที่ 4)
    participant UI as "CalculatorScreen / Cart / TDM"
    participant Core as "PharmacistCalculator & Safety"
    participant PK as "TdmCalculator & PkSimulation"
    participant DB as "DrugDatabase (119+4 Drugs)"

    Presenter->>UI: ตั้งค่าผู้ป่วย (ชาย 60 ปี, 170 cm, 120 kg, SCr 1.8)
    Presenter->>UI: เลือก Gentamicin (Extended Interval)
    UI->>Core: calculateDose(patient, gentamicin)
    Core->>DB: อ่านกลยุทธ์น้ำหนัก (adjustedIfObese) & Renal Tiers
    DB-->>Core: คืนค่าเกณฑ์ปรับยาตามไต
    Core-->>UI: IBW 65.94 kg -> AdjBW 87.56 kg, CrCl 54.05 -> 437.81 mg q36h

    Presenter->>UI: เพิ่ม Gentamicin ลงตะกร้า แล้วเลือก Vancomycin
    UI->>Core: calculateDose(patient, vancomycin)
    Core-->>UI: 1,800.0 mg q12-24h + Soft Max Warning + Red Man >= 180 min
    Note over UI: Rule 5 Non-Blocking: แสดงแถบเตือนแดงโดยไม่ซ่อนตัวเลข 1,800 mg

    Presenter->>UI: กด "เปิดดูข้อมูลยาในตำราอ้างอิง"
    UI-->>Presenter: แสดง ClinicalEvidenceSheet (Sanford Guide 2024 Table 10A/10B)

    Presenter->>UI: เพิ่ม Vancomycin ลงตะกร้า -> เปิด PrescriptionCartScreen
    UI->>Core: checkInteractions([Gentamicin, Vancomycin])
    Core-->>UI: Major DDI: เสริมพิษต่อไตและพิษต่อการได้ยิน

    Presenter->>UI: เปิด PK-PD Simulation & เครื่องมือคำนวณ TDM
    UI->>PK: calculateAuc24(1000 mg q12h, Vd 84 L, Ke 0.0493 /h)
    PK-->>UI: Steady-State AUC24 = 483.3 mg·h/L (Target 400-600)
```

---

## 3. Clinical Safety & Rule 5 Non-Blocking Decision Flowchart
*กลไกการคัดกรองความปลอดภัย 5 ชั้น และเหตุผลที่ Rule 5 ยังคงแสดงตัวเลขโดสยาเสมอ*

```mermaid
flowchart LR
    Start(["รับข้อมูลผู้ป่วย + รายการยา"]) --> Validate{"InputValidator\nข้อมูลถูกต้องและครบ?"}
    Validate -- "SCr ว่าง (ยาขับออกทางไต)" --> MissingSCr["Hard Warning: Missing SCr\nไม่ออกป้าย Audit Passed"]
    Validate -- "ข้อมูลครบ" --> CalcMath["คำนวณ Pure Dart\nIBW / AdjBW / CrCl / Dose"]

    CalcMath --> CheckDup{"TherapeuticDuplication\nซ้ำตัวเดิม หรือ 5 คู่ห้ามใช้?"}
    CheckDup -- "พบ (Dual NSAIDs/RAS/OAC/Statin/K-sparing)" --> HardDup["Hard Alert: ข้อห้ามใช้จากการจ่ายยาซ้ำซ้อน"]
    CheckDup -- "ไม่พบ" --> CheckAllergy

    CheckAllergy{"Allergy & DDI\nแพ้ยาตรงตัว / ข้ามกลุ่ม / ตีกัน?"}
    CheckAllergy -- "พบ" --> AlertDDI["แสดง Severity + Mechanism + Management"]
    CheckAllergy -- "ไม่พบ" --> CheckLimit

    HardDup --> CheckLimit
    AlertDDI --> CheckLimit

    CheckLimit{"DoseChecker\nเกิน Max Single/Daily Limit?"}
    CheckLimit -- "ไม่เกิน" --> SafeCard["แสดงผลสีเขียว: ผ่านเกณฑ์ปลอดภัย"]
    CheckLimit -- "เกิน Limit (Overdose)" --> Rule5["Rule 5 Non-Blocking Policy:\nขึ้น Overdose Banner สีแดง + คงตัวเลขโดสจริงไว้"]
```

---

## 4. 5-Step Clinical Verification & Governance State Lifecycle
*วงจรชีวิตข้อมูลยาจาก `PENDING_HUMAN_VERIFICATION` สู่ `VERIFIED` ตาม `VERIFICATION_PROTOCOL.md` และ `TRACEABILITY_MATRIX.md`*

```mermaid
stateDiagram-v2
    [*] --> DraftedByDevOrAI: "ขั้นที่ 1: ร่างข้อมูลยาจาก 7 ตำรามาตรฐาน"
    DraftedByDevOrAI --> PendingHumanVerification: "SchemaValidator ล็อก source_verified = false"
    PendingHumanVerification --> DossierExported: "ขั้นที่ 2: รัน generate_pharmacist_dossier_pdf.dart (48 หน้า)"
    DossierExported --> PharmacistReviewed: "ขั้นที่ 3: เภสัชกรคลินิกตรวจเทียบตำรา & ลงนาม (ภ.XXXXX)"
    PharmacistReviewed --> PhysicianApproved: "ขั้นที่ 4: อาจารย์แพทย์ / PTC อนุมัติ (ว.XXXXX)"
    PhysicianApproved --> VerifiedInSource: "ขั้นที่ 5: บันทึก Provenance + verified_by + verified_date"
    VerifiedInSource --> [*]: "UI แสดงป้าย Source Verified อย่างเป็นทางการ"
```
