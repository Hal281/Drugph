# Drugph — Deterministic Clinical Drug Dosage & Safety Engine

[![Flutter Test](https://img.shields.io/badge/Flutter%20Tests-23%2F23%20Passed-brightgreen)](file:///docs/04-testing/test-report.md)
[![Dart Analyze](https://img.shields.io/badge/Dart%20Analyze-0%20Issues-brightgreen)](file:///docs/04-testing/test-report.md)
[![Architecture](https://img.shields.io/badge/Architecture-3--Tier%20Layered-blue)](file:///docs/03-design/architecture.md)
[![Milestone](https://img.shields.io/badge/Milestone-M4%20Final%20Project-purple)](file:///docs/05-report/final-report.md)

> **Intro to Software Engineering (15031001) — Academic Year 2569**  
> School of Applied Digital Technology, Mae Fah Luang University  
> **Team:** Drugph Engineering Team  
> **GitHub Repository:** [https://github.com/Hal281/Drugph](https://github.com/Hal281/Drugph)  

---

## 📌 บทนำและภาพรวมของโครงการ (Project Overview)
**Drugph** เป็นระบบช่วยตัดสินใจและตรวจสอบความปลอดภัยขนาดยาทางคลินิก (Deterministic Clinical Drug Dosage & Decision Support Prototype) พัฒนาขึ้นเพื่อช่วยเภสัชกรโรงพยาบาลและบุคลากรทางการแพทย์ในหอผู้ป่วยวิกฤต (ICU) และอายุรกรรม ในการประเมินสรีรวิทยาของผู้ป่วย คำนวณปรับขนาดยาที่ขับออกทางไต และตรวจสอบขนาดยาสูงสุดแบบเรียลไทม์ เพื่อป้องกันความคลาดเคลื่อนทางยา (Medication Errors) ที่เป็นอันตรายต่อชีวิต

---

## 🧵 The Golden Thread (ตารางร้อยเรื่องสู่การประเมิน)
*คะแนนไม่ได้ให้ที่ความสวยของแอป แต่ให้ที่ความต่อเนื่องของเส้นด้ายตั้งแต่ ปัญหา $\rightarrow$ ข้อกำหนด $\rightarrow$ การออกแบบ $\rightarrow$ ฟีเจอร์ $\rightarrow$ การทดสอบ:*

| ปัญหา (Problem) | $\rightarrow$ Requirement (FR) | $\rightarrow$ การออกแบบ (Design) | $\rightarrow$ ฟีเจอร์ที่สร้าง (Feature) | $\rightarrow$ การทดสอบ (Test) |
|---|---|---|---|---|
| **คำนวณฟังก์ชันไตช้า/ผิดพลาด** | **FR-01 (Must)**<br>CrCl & eGFR | `RenalCalculator`<br>Cockcroft-Gault / CKD-EPI | แถบแสดงค่า CrCl และ eGFR อัตโนมัติใน Patient Banner | 3 Unit Tests (ชาย, หญิง, CKD-EPI) ✓ ผ่าน |
| **คนไข้อ้วนได้ยาปฏิชีวนะเกินขนาด** | **FR-02 (Must)**<br>Devine IBW & AdjBW | `WeightBasedCalculator`<br>Strategy: `adjustedIfObese` | คำนวณ Gentamicin สลับใช้น้ำหนัก AdjBW 87.56 kg ในคนอ้วน 120 kg | Unit Test ขนาดยา 437.8 mg (ไม่ใช่ 600 mg) ✓ ผ่าน |
| **CrCl ทศนิยม (25.5) หลุดช่วงปรับยา** | **FR-03 (Must)**<br>Renal Dosing Engine | `RenalAdjustment`<br>Rounding Tolerance logic | จัดกลุ่มทศนิยมเข้าช่วง 26–50 mL/min แนะนำลดขนาดยา Meropenem | Unit Test appliesTo(25.5) = true ✓ ผ่าน |
| **จ่ายยาขับออกทางไตโดยไม่ตรวจแล็บ** | **FR-04 (Must)**<br>Safety & Dose Checker | `DoseChecker`<br>Hard/Soft Warning Validator | แถบเตือนสีแดง "Missing SCr" และเตือนเมื่อเกิน Max Daily Dose | Unit Test ตรวจจับ Hard warning ✓ ผ่าน |
| **การดูเฉพาะ Trough เสี่ยงไตวาย** | **FR-05 (Should)**<br>TDM AUC₂₄ Calculator | `TdmCalculator`<br>Sawchuk-Zaske / ASHP 2020 | หน้าจอ TDM แสดงการ์ด Steady-State AUC₂₄ (เป้าหมาย 400–600) | Unit Test AUC 500 (เขียว) และ 888 (แดง) ✓ ผ่าน |

---

## 📂 สารบัญเอกสารประกอบโครงการ (Project Documentation Index)

เอกสารทุกชิ้นได้รับการจัดทำและจัดเก็บอย่างเป็นระบบตามมาตรฐานวิชาและหลักสูตรวิศวกรรมซอฟต์แวร์:

```
docs/
├── 01-charter/
│   └── charter.md            # M1: Team Charter, ปัญหา 5 Whys, ผู้ใช้จริง 3 คน, TAM/SAM/SOM, Scope, SDLC
├── 02-requirements/
│   ├── spec.md               # M2: SRS ฉบับสมบูรณ์ 7 ส่วนตามมาตรฐาน IEEE/ISO, User Stories, G-W-T Acceptance
│   └── backlog.md            # M2: Product Backlog จัดลำดับความสำคัญตามเกณฑ์ MoSCoW (Must, Should, Could, Won't)
├── 03-design/
│   ├── architecture.md       # M3: สถาปัตยกรรม 3 ชั้น, ADRs บันทึกเหตุผล, UML Use Case, Sequence, Class Diagram
│   └── design-system.md      # M3: Design Tokens (สี, ฟอนต์, ระยะห่าง, UI Components, และ Error States)
├── 04-testing/
│   └── test-report.md        # M4: ตารางผลการทดสอบ Acceptance Scenarios และหลักฐาน Unit Tests 23 ข้อ (100% Pass)
├── 05-report/
│   ├── final-report.md       # M3/M4: Final Project Report ฉบับสมบูรณ์ พร้อมตาราง Golden Thread
│   └── ai-use-statement.md   # M3: บันทึกการใช้งาน AI อย่างโปร่งใส (สิ่งที่เวิร์ก, จุดที่คนแก้, บทเรียนที่ได้รับ)
└── 06-presentation/
    └── demo-slides.md        # M3: โครงสไลด์นำเสนอ Demo เล่าเรื่อง Problem → Solution ตอน Present
```

---

## 🚀 วิธีการเปิดใช้งาน Prototype และการรันระบบ (Quick Start)

### 1. วิธีเปิดดู Prototype ในเว็บเบราว์เซอร์ (Clickable Prototype)
โปรเจกต์นี้สามารถเปิดใช้งานได้ทันทีในเบราว์เซอร์ (ไม่ต้องติดตั้ง Database เพิ่มเติม):
1. **ผ่านเว็บเบราว์เซอร์โดยตรง:** หากมีการโฮสต์ผ่าน GitHub Pages หรือเปิดดูไฟล์ build ได้ที่โฟลเดอร์ `web/`
2. **รันผ่านเครื่องคอมพิวเตอร์:**
   ```bash
   cd drugforPh
   flutter pub get
   flutter run -d chrome
   ```
   หรือรันบน Windows Desktop:
   ```bash
   flutter run -d windows
   ```

### 2. วิธีการรันชุดทดสอบอัตโนมัติ (Automated Unit Tests)
เพื่อพิสูจน์ความถูกต้องของสูตรคำนวณและข้อกำหนดทั้งหมดตามเกณฑ์:
```bash
flutter test
```
*ผลลัพธ์จะแสดงชุดทดสอบทั้ง 23 รายการผ่านทั้งหมด (23/23 tests passed)*

### 3. วิธีการตรวจสอบคุณภาพโค้ด (Static Analysis)
```bash
dart analyze
```
*ผลลัพธ์: 0 Warnings, 0 Errors*

---

## 📚 ตำราและการอ้างอิงทางการแพทย์ (Medical References)
1. **Cockcroft-Gault:** Cockcroft DW, Gault MH. *Nephron*. 1976;16(1):31-41.
2. **CKD-EPI 2021 (Race-free):** Inker LA et al. *N Engl J Med*. 2021;385:1737-1749.
3. **Ideal Body Weight:** Devine BJ. *Drug Intell Clin Pharm*. 1974;8:650-655.
4. **Adjusted Body Weight:** Winter MA et al. *Am J Health-Syst Pharm*. 2012.
5. **Body Surface Area:** Mosteller RD. *N Engl J Med*. 1987;317:1098.
6. **Carboplatin Calvert Formula:** Calvert AH et al. *J Clin Oncol*. 1989;7(11):1748-1756.
7. **Vancomycin TDM & AUC₂₄:** Rybak MJ et al. *Am J Health-Syst Pharm*. 2020;77(11):835-864. (ASHP/IDSA/PIDS/SIDP Guidelines)
