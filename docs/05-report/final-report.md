# Final Project Report — Drugph
**Course:** Introduction to Software Engineering (15031001) — Academic Year 2569  
**Milestone:** Final Project Report (30% Evaluation Track)  
**Project Title:** Drugph — Deterministic Clinical Drug Dosage & Safety Verification Engine  
**Team:** Drugph Engineering Team  
**Repository:** [https://github.com/Hal281/Drugph](https://github.com/Hal281/Drugph)  

---

## 1. หน้าปกและข้อมูลโครงการ (Cover & Project Summary)
- **ชื่อโครงการ:** Drugph (โปรแกรมผู้ช่วยคำนวณและตรวจสอบความปลอดภัยขนาดยาทางคลินิก)
- **สาขาวิชา:** Software Engineering, School of Applied Digital Technology, Mae Fah Luang University
- **หมวดหมู่โครงการ:** Clinical Decision Support Software / Medical Prototype (SaMD)
- **ลิงก์ Repository:** `https://github.com/Hal281/Drugph`
- **สถานะ:** Fully Implemented Prototype with 23 Automated Unit Tests (100% Pass)

---

## 2. ปัญหาและกลุ่มผู้ใช้จริง (Problem & Target Users)
เภสัชกรโรงพยาบาลและบุคลากรทางการแพทย์ในหอผู้ป่วยวิกฤต (ICU) ต้องเผชิญกับภาระงานล้นและความเสี่ยงต่อ **ความคลาดเคลื่อนทางยา (Medication Errors)** จากการคำนวณสูตรปรับขนาดยาตามสรีรวิทยาและค่าการทำงานของไตที่มีความซับซ้อน (Cockcroft-Gault, CKD-EPI, Devine IBW, AdjBW) 

### การสัมภาษณ์และยืนยันปัญหากับผู้ใช้จริง 3 คน (Gate 1 Validation):
1. **ภก. คลินิกประจำหอผู้ป่วย:** ยืนยันว่าการดูตารางปรับยาในตำรามักมี "ช่องว่างของตัวเลขทศนิยม CrCl" (เช่น 25.5 mL/min) ทำให้เสี่ยงจ่ายยาเต็มขนาด และต้องการระบบที่เตือนเมื่อลืมใส่ค่า Serum Creatinine
2. **พยาบาลวิชาชีพ ICU:** ยืนยันว่าการคำนวณอัตราหยดยาทางหลอดเลือดดำ (IV Titration) มักเสี่ยงต่อการสมมติปริมาตรสารน้ำผิดพลาด
3. **นักศึกษาฝึกงานบริบาลเภสัชกรรม:** ต้องการเครื่องมือคำนวณ TDM Vancomycin ที่แสดงผลทั้ง Trough Level และเป้าหมาย Steady-State AUC₂₄ (400–600 mg·h/L) ตามมาตรฐาน ASHP 2020

---

## 3. สรุปความต้องการของระบบ (Requirements Summary)

### 3.1 Functional Requirements & MoSCoW
- **FR-01 (Must):** คำนวณค่าการทำงานของไต Cockcroft-Gault CrCl และ CKD-EPI 2021 Race-free
- **FR-02 (Must):** คำนวณน้ำหนักตัวอุดมคติ (Devine IBW) และน้ำหนักปรับปรุง (AdjBW) สำหรับผู้ป่วยอ้วน ($\ge 120\%$ IBW)
- **FR-03 (Must - หัวใจของระบบ):** เครื่องยนต์ปรับขนาดยาตามไตอัตโนมัติ (Renal Dosing Engine) พร้อมปิดช่องว่างทศนิยม CrCl
- **FR-04 (Must):** ระบบตรวจสอบขนาดยาสูงสุด (Dose Limits) และแจ้งเตือนจุดอันตราย (Missing SCr / Max Dose Alert)
- **FR-05 (Should):** การคำนวณเภสัชจลนศาสตร์ TDM Vancomycin และเป้าหมาย Steady-State AUC₂₄

### 3.2 Measurable Non-Functional Requirements
- **NFR-01 (Performance):** คำนวณผลลัพธ์และแจ้งเตือนความปลอดภัยภายในเวลา $\le 100$ มิลลิวินาที
- **NFR-02 (Reliability):** ทำงานแบบ Offline 100% Client-side ไม่ต้องพึ่งพาเครือข่ายอินเทอร์เน็ต
- **NFR-04 (Medical Accuracy):** ความคลาดเคลื่อนทางคณิตศาสตร์ $\le \pm 0.1\%$ เมื่อเทียบกับตำราอ้างอิงสากล
- **NFR-05 (Security & PDPA):** ประมวลผลข้อมูลผู้ป่วยใน RAM ของเครื่องเท่านั้น ไม่มี Network Leakage สู่ภายนอก

---

## 4. สถาปัตยกรรมและการออกแบบ (Architecture & Design)
ระบบถูกออกแบบด้วยสถาปัตยกรรม **3-Tier Architecture** ที่มี Low Coupling และ High Cohesion:
1. **Presentation Layer (Flutter Web/App):** ส่วนติดต่อผู้ใช้ แบ่งเป็น Calculator Screen, TDM Screen, และ IV Titration Screen
2. **Application Logic Layer (Deterministic Engine):** คลาส `PharmacistCalculator`, `RenalCalculator`, `WeightBasedCalculator`, `DoseChecker`, และ `TdmCalculator`
3. **Data Layer (Drug Catalog):** พจนานุกรมยาและตารางเกณฑ์ปรับยาตามไตที่เป็นทางการแพทย์

---

## 5. ตารางร้อยเรื่องสู่เป้าหมาย (The Golden Thread Traceability Table)
> **หัวใจสำคัญของการประเมินผล:** ตารางนี้แสดงให้เห็นว่าทุกฟีเจอร์ในระบบสามารถสาวกลับไปถึงปัญหาตั้งต้น และสาวไปข้างหน้าถึงการทดสอบได้อย่างสมบูรณ์ ไม่ขาดตอน (Coherence):

| ปัญหา (Pain / Problem) | → Requirement (FR/NFR) | → สถาปัตยกรรม & การออกแบบ (Design) | → ฟีเจอร์ที่สร้างจริง (Feature Built) | → การทดสอบและการยืนยันผล (Verification & Test) |
|---|---|---|---|---|
| **เภสัชกรคำนวณฟังก์ชันไตช้าและเสี่ยงตัวเลขสลับ** | **FR-01** (Must)<br>ประเมิน CrCl และ eGFR | `RenalCalculator`<br>• Cockcroft-Gault<br>• CKD-EPI 2021 | แถบแสดงค่า CrCl และ eGFR อัตโนมัติใน Patient Banner | Unit Tests: ชาย (CrCl 68.06) หญิง (57.85) และ CKD-EPI (88.08) ✓ ผ่าน 100% |
| **คนไข้อ้วนได้ยา Aminoglycosides เกินขนาดจนไตวาย** | **FR-02** (Must)<br>คำนวณ Devine IBW และ AdjBW | `WeightBasedCalculator`<br>• Devine Formula<br>• Winter AdjBW | กลยุทธ์ `adjustedIfObese`: สลับใช้น้ำหนัก AdjBW อัตโนมัติเมื่อคนไข้อ้วน $\ge 120\%$ IBW | Unit Tests: ชาย 170cm หนัก 120kg ได้ AdjBW 87.56kg และได้ยา 437.8mg (ไม่ใช่ 600mg) ✓ ผ่าน |
| **CrCl ทศนิยม (เช่น 25.5) หลุดช่วงปรับยาจนได้ยาเต็มขนาด** | **FR-03** (Must)<br>เครื่องยนต์ปรับยาตามไตปิดช่องว่าง | `RenalAdjustment`<br>• Decimal tolerance logic<br>• AppliesTo boundary check | กลไกจัดกลุ่ม CrCl ทศนิยมเข้าช่วงการรักษาอย่างปลอดภัย ไม่หลุดเป็น Full dose | Unit Tests: CrCl 25.5 ตกเข้าช่วง 26–50 mL/min แนะนำลดขนาดยา Meropenem ถูกต้อง ✓ ผ่าน |
| **การจ่ายยาขับออกทางไตโดยไม่ตรวจแล็บ / ยาเกินขนาด** | **FR-04** (Must)<br>Dose Checker & Missing SCr Alert | `DoseChecker`<br>• Hard/Soft warnings<br>• SCr validator | แถบเตือนสีแดง "Missing Serum Creatinine" และการ์ดเตือนเมื่อเกิน Max Daily Dose | Unit Tests: Hard limit warning เมื่อเกินขนาดยา + ขาด SCr ขึ้นแถบเตือนสีแดงทันที ✓ ผ่าน |
| **การติดตาม Vancomycin ด้วย Trough อย่างเดียวเสี่ยงไตพัง** | **FR-05** (Should)<br>คำนวณ TDM Steady-State AUC₂₄ | `TdmCalculator`<br>• Sawchuk-Zaske PK<br>• AUC24 Target Engine | หน้าจอ TDM แสดงการ์ด AUC₂₄ เป้าหมาย 400–600 mg·h/L ตามแนวทาง ASHP 2020 | Unit Tests: Dose 750mg q12h ได้ AUC 500.0 (เขียว) และ Dose 1000mg ได้ AUC 888.9 (แดง) ✓ ผ่าน |

---

## 6. สรุปผลการทดสอบ (Testing Results)
- **Automated Unit Tests:** **23/23 tests ผ่าน 100%** (`flutter test`)
- **Static Analysis:** **0 Errors, 0 Warnings** (`dart analyze`)
- **Acceptance Criteria Verification:** ผ่านการทดสอบครบทุกฉากทั้ง Happy Path และ Unhappy Path

---

## 7. ส่วนร่วมของสมาชิกในทีม (Individual Contribution via GitHub)
- การทำงานทั้งหมดของทีมถูกบันทึกและตรวจสอบได้ผ่าน Git Commits ใน GitHub Repository ([https://github.com/Hal281/Drugph](https://github.com/Hal281/Drugph))
- ประวัติการ Commit แสดงให้เห็นถึงการพัฒนาอย่างเป็นขั้นตอน ตั้งแต่การจัดโครงสร้างเอกสาร M1–M2, การ Refactor สูตรคณิตศาสตร์ทางคลินิก, การปิดช่องโหว่ความปลอดภัย Dosing Engine, และการสร้างชุดการทดสอบ Unit Tests
