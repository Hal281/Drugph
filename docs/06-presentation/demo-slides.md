# Presentation Demo Slides — Drugph
**Course:** Introduction to Software Engineering (15031001) — Academic Year 2569  
**Milestone:** M3 / M4 Final Presentation & Live Demo  
**Title:** Drugph — Deterministic Clinical Drug Dosage & Safety Verification Engine  

---

### Slide 1: Title & Team
- **Drugph:** ระบบผู้ช่วยคำนวณและตรวจสอบความปลอดภัยขนาดยาทางคลินิก
- **School of Applied Digital Technology, Mae Fah Luang University**
- **สมาชิกในทีม:** Drugph Engineering Team
- **Repository:** `https://github.com/Hal281/Drugph`

---

### Slide 2: The Problem (ปัญหาที่ต้องแก้)
- **Who:** เภสัชกรโรงพยาบาล, แพทย์, และพยาบาลในหอผู้ป่วยวิกฤต (ICU)
- **Pain:** การคำนวณขนาดยาที่มีช่วงการรักษาแคบ (Narrow Therapeutic Index) และการปรับยาตามไตมีความซับซ้อนสูงมาก
- **Consequence:** หากคำนวณผิด ผู้ป่วยเสี่ยงไตวายเฉียบพลัน หูดับถาวร หรือเชื้อดื้อยาจนเสียชีวิต
- **Real Users (Gate 1):** สัมภาษณ์และยืนยันปัญหากับเภสัชกรคลินิก, พยาบาล ICU, และนักศึกษาบริบาลเภสัชกรรม

---

### Slide 3: Root Cause & Current Alternatives
- **5 Whys Analysis:** รากของปัญหาไม่ใช่ "เภสัชกรคำนวณเลขไม่เก่ง" แต่คือ **ขาดเครื่องมือ Clinical Decision Support ที่ Deterministic** ซึ่งช่วยคำนวณหลายตัวแปรพร้อมกันและแจ้งเตือนจุดเสี่ยง
- **วิธีเดิมที่ล้มเหลว:**
  - เครื่องคิดเลข + ตำรากระดาษ: ช้า และเสี่ยงต่อการดูตารางช่วง CrCl ผิดพลาด
  - Excel / เว็บนอก: ขาดการตรวจสอบ Input Validation และเสี่ยงต่อการละเมิด PDPA

---

### Slide 4: Requirements & MoSCoW MVP
- **Must Have (Core MVP):**
  - **FR-01:** คำนวณ CrCl (Cockcroft-Gault) และ eGFR (CKD-EPI 2021)
  - **FR-02:** คำนวณ Devine IBW และ AdjBW สำหรับผู้ป่วยอ้วน
  - **FR-03 (หัวใจของระบบ):** เครื่องยนต์ปรับยาตามไตอัตโนมัติ ปิดช่องว่างทศนิยม CrCl
  - **FR-04:** ระบบตรวจจับความปลอดภัย (Max Dose & Missing SCr Alert)
- **Should Have:**
  - **FR-05:** TDM Vancomycin คำนวณ Steady-State AUC₂₄ (400–600 mg·h/L) ตามมาตรฐาน ASHP 2020

---

### Slide 5: The Golden Thread (เส้นด้ายทองคำ)
> *หัวใจของการให้คะแนน: ทุกฟีเจอร์ต้องร้อยเรียงกลับไปถึงปัญหาเดิมได้ 100%*

$$\text{Problem} \longrightarrow \text{Requirement} \longrightarrow \text{Design} \longrightarrow \text{Feature} \longrightarrow \text{Test}$$

- **ปัญหา:** คนไข้อ้วนได้ยา Aminoglycosides เกินขนาดจนไตพัง
- **FR:** FR-02 (สลับใช้น้ำหนัก AdjBW เมื่ออ้วน)
- **Design:** `WeightBasedCalculator` + Strategy Pattern `adjustedIfObese`
- **Feature:** การคำนวณ Gentamicin สลับใช้น้ำหนัก AdjBW 87.56 kg อัตโนมัติ (แทน 120 kg)
- **Test:** Unit Test ตรวจสอบค่า AdjBW และขนาดยา 437.8 mg ถูกต้องแม่นยำ

---

### Slide 6: Three-Tier Architecture
- **Presentation Layer:** Flutter Web/Client Interface สวยงาม เรียบง่าย อ่านง่ายในห้องผ่าตัด
- **Application Logic Layer:** Pure Deterministic Engine แยกอิสระ ทดสอบง่าย (High Cohesion)
- **Data Layer:** ฐานข้อมูลยาและเกณฑ์ปรับยาตามไตมาตรฐานสากล (Lexicomp / Sanford Guide)
- **ADR Highlights:** ทำงานแบบ Client-side 100% เพื่อ Zero Latency, 100% Offline, และปลอดภัยต่อ PDPA

---

### Slide 7: Live Demo Walkthrough (Flow การสาธิตสด)
1. **Step 1:** กรอกข้อมูลผู้ป่วย (ชาย 60 ปี, ส่วนสูง 170 ซม., น้ำหนัก 120 กก., SCr 1.8 mg/dL)
2. **Step 2:** ดูแถบ Patient Banner ด้านบน (แสดง CrCl, eGFR, IBW, AdjBW อัตโนมัติ)
3. **Step 3:** เลือกยา Meropenem $\rightarrow$ ระบบตรวจจับ CrCl แนะนำลดขนาดเป็น 1,000 mg q12h
4. **Step 4:** แสดง Unhappy Path $\rightarrow$ ลบค่า SCr ออก $\rightarrow$ ระบบขึ้นเตือน Hard Warning สีแดงทันที และถอดป้าย Audit Passed ออก
5. **Step 5:** เปิดหน้า TDM $\rightarrow$ แสดงการ์ดสถานะ Steady-State AUC₂₄ ในช่วงเป้าหมาย 400–600 mg·h/L

---

### Slide 8: Testing & Verification
- **Flutter Test:** **23/23 Tests Passed (100% Pass Rate)**
- **Dart Analyze:** 0 Errors, 0 Warnings
- **Accuracy:** ความคลาดเคลื่อนคณิตศาสตร์ $\le \pm 0.1\%$ เทียบเท่าตำราแพทย์สากล

---

### Slide 9: AI-First Engineering Reflection
- **สิ่งที่ AI ช่วยได้มาก:** ค้นพบ Edge Case ทศนิยม CrCl 25.5 mL/min และร่างโครงสร้าง Unit Tests
- **สิ่งที่มนุษย์ต้องตรวจและแก้เอง:** ตรวจแก้ตัวเลข Devine Formula ที่ AI คำนวณหน่วยนิ้วคลาดเคลื่อน และอัปเกรดเกณฑ์ TDM สู่มาตรฐาน ASHP 2020

---

### Slide 10: Conclusion & Q&A
- **สรุปคุณค่าของ Drugph:** แม่นยำ, ปลอดภัย, รวดเร็ว, และสอดคล้องกับมาตรฐานทางคลินิก
- พร้อมตอบข้อซักถามของคณะกรรมการและอาจารย์ผู้สอน
