# Software Architecture & Technical Design — Drugph
**Course:** Introduction to Software Engineering (15031001) — Academic Year 2569  
**Milestone:** M3 (Software Design & Modeling) — Final Delivery  
**Project:** Drugph — Deterministic Clinical Drug Dosage & Safety Verification Engine  

---

## 1. สถาปัตยกรรม 3 ชั้น (Three-Tier Architecture)

ระบบ Drugph ยึดถือหลักการแบ่งสถาปัตยกรรมออกเป็น 3 ชั้น เพื่อให้เกิด **High Cohesion (ความเกาะกลุ่มภายในส่วนสูง)** และ **Low Coupling (การพึ่งพาระหว่างส่วนต่ำ)** และยึดหลัก **Separation of Concerns**:

```mermaid
graph TD
    subgraph Presentation_Layer ["1. Presentation Layer (UI / Client)"]
        UI_Calc["Calculator Screen (FR-01, FR-02, FR-03)"]
        UI_TDM["TDM Screen (FR-05)"]
        UI_Audit["Safety Banner & Audit Badge (FR-04)"]
    end

    subgraph Logic_Layer ["2. Application Logic Layer (Deterministic Engines)"]
        Eng_Renal["Renal Calculator (CrCl / CKD-EPI)"]
        Eng_Weight["Weight & Physiology Calculator (IBW / AdjBW / BSA)"]
        Eng_Dose["Pharmacist Calculator & Renal Adjustment Engine"]
        Eng_Safety["Dose Safety Checker & Alert Validator"]
        Eng_TDM["TDM Pharmacokinetic Engine (AUC24 / Ke / Vd)"]
    end

    subgraph Data_Layer ["3. Data Layer (Knowledge Base & Drug Formulary)"]
        DB_Drugs["Drug Formulary Catalog (Antibiotics, Chemo, Cardio)"]
        DB_Limits["Dose Limits & Critical Thresholds"]
        DB_RenalTiers["Renal Adjustment Criteria Tables"]
    end

    %% Flow of Calls
    UI_Calc -->|"Query dose calculation (contract)"| Eng_Dose
    UI_Calc -->|"Compute CrCl / eGFR"| Eng_Renal
    UI_Calc -->|"Compute IBW / AdjBW"| Eng_Weight
    UI_TDM -->|"Compute AUC24 / Trough"| Eng_TDM
    Eng_Dose -->|"Verify max thresholds"| Eng_Safety
    Eng_Dose -->|"Lookup drug guidelines"| DB_Drugs
    Eng_Dose -->|"Read renal tiers"| DB_RenalTiers
    Eng_Safety -->|"Read dose limits"| DB_Limits
```

### การแบ่งหน้าที่และความเป็นอิสระของแต่ละชั้น:
1. **Presentation Layer (UI):** มีหน้าที่รับข้อมูลผู้ป่วย (น้ำหนัก, ส่วนสูง, เพศ, อายุ, SCr) และแสดงผลลัพธ์ขนาดยา การ์ดคำเตือน และสถานะ Audit Badge **โดยไม่มีการตัดสินกฎทางคณิตศาสตร์หรือการแพทย์ใน UI Widget เอง**
2. **Application Logic Layer:** บรรจุสมการทางคณิตศาสตร์และการแพทย์ที่เป็น Deterministic ทั้งหมด (Cockcroft-Gault, CKD-EPI 2021, Devine IBW, Winter AdjBW, Calvert Formula, Sawchuk-Zaske PK) ประมวลผลและส่งผลลัพธ์พร้อมรายการแจ้งเตือนกลับไปยัง UI ผ่าน Data Transfer Object
3. **Data Layer:** จัดเก็บพจนานุกรมยาและตารางเกณฑ์การปรับยาตามไตที่เป็นมาตรฐานทางการแพทย์ โดยถูกห่อหุ้ม (Encapsulated) ไว้อย่างมิดชิด ไม่ให้ UI เข้าถึงได้โดยตรง

---

## 2. การตัดสินใจเชิงสถาปัตยกรรม (Architectural Decision Records - ADR)

### ADR-01: การเลือกใช้ Client-Side Deterministic Architecture เหนือ Cloud API
- **Context:** ต้องการให้ระบบทำงานได้รวดเร็ว ปลอดภัยตามกฎหมาย PDPA (NFR-05) และพร้อมใช้งานในพื้นที่อับสัญญาณในโรงพยาบาล เช่น ห้องผ่าตัดหรือห้องฉุกเฉิน (NFR-02)
- **Decision:** พัฒนาตัวคำนวณทั้งหมดเป็น Pure Dart Engine ที่คอมไพล์ทำงานฝั่ง Client 100% (บน Browser / Flutter Web / Mobile) โดยไม่มีการส่งค่าพารามิเตอร์ของผู้ป่วยออกไปยัง Remote Server
- **Consequence:** ได้ Zero Network Latency (< 10 ms), ไม่มีค่าใช้จ่าย Server โฮสต์ฐานข้อมูล และข้อมูลผู้ป่วยปลอดภัยสมบูรณ์ แต่ต้องแลกกับการอัปเดตสูตรยาที่ต้อง deploy แอปเวอร์ชันใหม่

### ADR-02: การใช้ Rounding Tolerance ปิดช่องว่างทศนิยมในตาราง Renal Adjustment
- **Context:** ในเวชปฏิบัติจริง ผลแล็บ Serum Creatinine มีทศนิยม ทำให้ CrCl เป็นเลขทศนิยม (เช่น 25.5 mL/min) ซึ่งหลุดช่องว่างระหว่างช่วงตารางยาในตำรา (เช่น 10–25 และ 26–50) ส่งผลให้คนไข้ได้ยาเต็มขนาด (FR-03)
- **Decision:** ออกแบบเมท็อด `RenalAdjustment.appliesTo(crcl)` ให้ใช้การปัดเศษ `crcl.roundToDouble()` หรือความคลาดเคลื่อน $0.5$ Unit เพื่อจัดกลุ่มผู้ป่วยเข้าช่วงการปรับยาที่ถูกต้องตามความตั้งใจของตำราแพทย์
- **Consequence:** ป้องกันการเกิด Dosing Gap 100% ผู้ป่วยได้รับยาที่ลดขนาดตามระดับการทำงานของไตอย่างปลอดภัย

---

## 3. ไดอะแกรมเชิงสถาปัตยกรรม (UML Diagrams)

### 3.1 UML Use Case Diagram (ภาพรวมระบบและผู้ใช้)
```mermaid
flowchart LR
    subgraph System_Boundary ["Drugph — Clinical Assistant Boundary"]
        UC1(["UC-01: กรอกข้อมูลผู้ป่วยและค่าแล็บ (FR-01, FR-02)"])
        UC2(["UC-02: คำนวณและปรับขนาดยาตามไตอัตโนมัติ (FR-03)"])
        UC3(["UC-03: ตรวจสอบความปลอดภัยขนาดยาสูงสุด (FR-04)"])
        UC4(["UC-04: วิเคราะห์ TDM & เป้าหมาย AUC24 (FR-05)"])
        UC5(["UC-05: ส่งออกรายงานการตรวจสอบ Audit PDF (FR-07)"])
    end

    Actor_Pharm["เภสัชกรคลินิก (Primary Actor)"]
    Actor_Nurse["พยาบาล ICU / แพทย์ (Secondary Actor)"]

    Actor_Pharm --> UC1
    Actor_Pharm --> UC2
    Actor_Pharm --> UC3
    Actor_Pharm --> UC4
    Actor_Pharm --> UC5

    Actor_Nurse --> UC1
    Actor_Nurse --> UC2
    Actor_Nurse --> UC3
```

### 3.2 Sequence Diagram: กระบวนการคำนวณและปรับขนาดยา (Dosing & Safety Flow)
```mermaid
sequenceDiagram
    autonumber
    actor Pharmacist as เภสัชกร (User)
    participant UI as CalculatorScreen (Presentation)
    participant Engine as PharmacistCalculator (Logic)
    participant RenalCalc as RenalCalculator (Logic)
    participant WeightCalc as WeightBasedCalculator (Logic)
    participant Checker as DoseChecker (Logic)
    participant DB as DrugRepository (Data)

    Pharmacist->>UI: ป้อนข้อมูลผู้ป่วย (Ht 170cm, Wt 120kg, SCr 1.2) + เลือกยา Gentamicin
    UI->>WeightCalc: idealBodyWeight(170cm, Male)
    WeightCalc-->>UI: return IBW = 65.94 kg
    UI->>WeightCalc: isObese(120kg, 65.94kg)
    WeightCalc-->>UI: return true (182% of IBW)
    UI->>WeightCalc: adjustedBodyWeight(120kg, 65.94kg)
    WeightCalc-->>UI: return AdjBW = 87.56 kg

    UI->>RenalCalc: cockcroftGault(...)
    RenalCalc-->>UI: return CrCl = 95.0 mL/min

    UI->>Engine: calculateDose(drug: Gentamicin, weight: AdjBW, crcl: CrCl)
    Engine->>DB: getDrugLimitsAndRenalTiers(Gentamicin)
    DB-->>Engine: drugRules (Strategy: adjustedIfObese)
    Engine->>Checker: verifyDoseLimits(calculatedDose, limits)
    Checker-->>Engine: safetyWarnings (Info: Using AdjBW for obesity)
    Engine-->>UI: return CalculationResult (Dose = 437.8 mg, Warnings, AuditStatus)
    UI-->>Pharmacist: แสดงผลการ์ดขนาดยา ป้ายเตือนความปลอดภัย และหลักฐานการปรับยา
```

### 3.3 Class Diagram / Logical Data Model (โครงสร้างข้อมูลเชิงตรรกะ)
```mermaid
classDiagram
    class Patient {
        +double weightKg
        +double heightCm
        +int ageYears
        +int ageMonths
        +Sex sex
        +double? serumCreatinine
        +double bsa
        +double ibw
        +double adjBw
        +double? crcl
        +double? egfr
    }

    class Drug {
        +String id
        +String nameEn
        +String nameTh
        +DrugCategory category
        +List~DosingRegimen~ regimens
        +DoseLimits limits
        +List~RenalAdjustment~ renalAdjustments
    }

    class DosingRegimen {
        +String indication
        +DosingType dosingType
        +DosingWeightStrategy dosingWeightStrategy
        +double? dosePerKg
        +double? fixedDose
        +int intervalHours
    }

    class RenalAdjustment {
        +double crclMin
        +double crclMax
        +double adjustmentFactor
        +int? adjustedIntervalHours
        +String commentEn
        +bool appliesTo(double crcl)
    }

    class DoseLimits {
        +double? maxSingleDoseMg
        +double? maxDailyDoseMg
    }

    class DoseWarning {
        +LimitSeverity severity
        +String messageEn
        +String messageTh
    }

    Patient "1" --> "0..*" Drug : evaluates for
    Drug "1" *-- "1..*" DosingRegimen : contains
    Drug "1" *-- "0..*" RenalAdjustment : defines
    Drug "1" *-- "1" DoseLimits : enforces
    DoseLimits ..> DoseWarning : produces
```

---

## 4. โมเดลข้อมูลเชิงตรรกะ (Logical Data Model - Tech Agnostic)

| เอนทิตี (Entity) | ฟิลด์ข้อมูล (Fields & Types) | ความสัมพันธ์ (Relationship) | ความต้องการที่รองรับ (Traced FR) |
|---|---|---|---|
| **Patient** | `id: String`, `weightKg: Float`, `heightCm: Float`, `ageYears: Int`, `sex: Enum[Male,Female]`, `serumCreatinine: Float?` | 1 ราย มีการประเมินได้หลายคำสั่งยา | FR-01, FR-02 |
| **Drug** | `id: String`, `genericName: String`, `category: Enum`, `standardDose: Float`, `isHighAlert: Bool` | 1 ชนิดยา มีหลายขนาดตามข้อบ่งใช้ | FR-03, FR-04 |
| **RenalTier** | `crclMin: Float`, `crclMax: Float`, `doseFactor: Float`, `adjustedInterval: Int` | เป็นส่วนประกอบของ Drug | FR-03 |
| **SafetyAlert** | `severity: Enum[Info, Soft, Hard]`, `message: String`, `actionRequired: String` | เกิดขึ้นจากการตรวจสอบขนาดยา | FR-04 |
| **TdmRecord** | `doseMg: Float`, `tauHours: Int`, `kePerHour: Float`, `vdLiters: Float`, `targetAucMin: Float`, `targetAucMax: Float` | 1 เคส TDM เชื่อมกับ Patient | FR-05 |

*หมายเหตุ: โมเดลข้อมูลนี้เป็นเชิงตรรกะ ไม่มีการผูกติดกับรูปแบบตาราง SQL หรือ Firestore Document โดยสามารถนำไปประยุกต์ใช้กับหน่วยความจำแบบ In-Memory State ได้โดยตรง*
