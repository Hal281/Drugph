# Software Requirements Specification (SRS) — Drugph
**Course:** Introduction to Software Engineering (15031001) — Academic Year 2569  
**Milestone:** M2 (SRS Specification) — Final Delivery  
**Document Standard:** Lightweight subset conforming to IEEE Std 830-1998 / ISO/IEC/IEEE 29148:2018  
**Project:** Drugph — Deterministic Clinical Drug Dosage & Safety Verification Engine  
**Version:** 2.0 (Clinical Safety & Audit Revision)  

---

## 1. จุดประสงค์และขอบเขตของผลิตภัณฑ์ (Purpose & Product Scope)

### 1.1 จุดประสงค์ (Purpose)
ระบบ **Drugph** ถูกออกแบบขึ้นเพื่อเป็นระบบช่วยตัดสินใจทางคลินิก (Clinical Decision Support System: CDSS) ชนิด Deterministic สำหรับเภสัชกรโรงพยาบาลและบุคลากรทางการแพทย์ เพื่อใช้คำนวณและปรับขนาดยาที่มีความเสี่ยงสูง (High-Alert Medications) และยาที่ขับออกทางไต (Renally Eliminated Drugs) ตามสรีรวิทยาของผู้ป่วยแต่ละราย ช่วยขจัดข้อผิดพลาดจากการคำนวณด้วยมือ (Human Calculation Errors) ลดเวลาการประเมินคำสั่งใช้ยา และป้องกันการเกิดอันตรายต่อผู้ป่วย (Patient Harm) จากการได้รับยาเกินขนาดหรือขาดขนาด

### 1.2 บริบทของผลิตภัณฑ์ (Product Context)
Drugph ทำงานในรูปแบบ Client-Side Web/Mobile Engine ที่ประมวลผลการคำนวณทั้งหมดบนเครื่องของผู้ใช้ (In-Memory Processing) เพื่อความเร็วสูงสุดและสามารถทำงานในพื้นที่อับสัญญาณในโรงพยาบาลได้ โดยเชื่อมโยงฐานข้อมูลสูตรยา ขนาดยาสูงสุด และเกณฑ์การปรับยาตามไตที่เป็นมาตรฐานสากล

---

## 2. ผู้มีส่วนได้เสีย (Stakeholders)

| บทบาท / ฝ่าย | ประเภท | สิ่งที่ต้องการ (Needs) | สิ่งที่กังวล / ข้อห้าม (Fears & Forbids) |
|---|---|---|---|
| **เภสัชกรคลินิก (Clinical Pharmacist)** | Primary User | คำนวณ CrCl, IBW, AdjBW, และขนาดยาที่ปรับตามไตได้ในหน้าเดียว พร้อมแจ้งเตือนจุดเสี่ยง | การคำนวณผิดพลาดจนเกิดพิษต่อไต หรือระบบสมมติค่าโดยไม่มีหลักฐานทางคลินิกรองรับ |
| **แพทย์ / พยาบาลหอผู้ป่วยวิกฤต (Physician / ICU Nurse)** | Secondary User | ทราบขนาดยาสูงสุด (Max Dose Alert) และความเข้มข้นของการให้ยาทางหลอดเลือดดำ (IV Titration) อย่างรวดเร็ว | การแจ้งเตือนที่รกเกินไป (Alert Fatigue) จนบดบังการสั่งการรักษาในภาวะวิกฤต |
| **คณะกรรมการเภสัชกรรมและการบำบัด (PTC / Hospital)** | Governance | เอกสารสรุปการตรวจสอบการใช้ยา (Audit Report) ที่โปร่งใสและอ้างอิงตำรามาตรฐาน | การละเมิดพระราชบัญญัติคุ้มครองข้อมูลส่วนบุคคล (PDPA) หรือข้อมูลเวชระเบียนผู้ป่วยรั่วไหล |

---

## 3. ข้อกำหนดเชิงฟังก์ชัน (Functional Requirements - FR)
> ทุกข้อเขียนในรูปแบบ User Story: *"ในฐานะ [บทบาทที่มีชื่อจริง] ฉันต้องการ [เป้าหมาย] เพื่อ [คุณค่า/ประโยชน์]"* และผ่าน 4 Quality Gates (INVEST) พร้อมระบุเกณฑ์การยอมรับ (Acceptance Criteria) ทั้ง **Happy Path (ทางถูก)** และ **Unhappy/Edge Path (ทางผิด)**

### FR-01: การประเมินสมรรถภาพการทำงานของไต (Renal Function Estimation)
- **User Story:** ในฐานะเภสัชกรคลินิก ฉันต้องการคำนวณค่า Creatinine Clearance (Cockcroft-Gault) และ eGFR (CKD-EPI 2021 Race-free) จากข้อมูลผู้ป่วย เพื่อใช้เป็นเกณฑ์ตัดสินใจในการปรับขนาดยาที่ขับออกทางไต
- **Priority:** Must (MVP)
- **Traceability Pain:** การเปิดตำราคำนวณมือใช้เวลานานและเสี่ยงต่อการคำนวณตัวเลขทศนิยมผิดพลาด
- **Acceptance Criteria (Given-When-Then):**
  - *ฉากที่ 1 (Happy Path - Cockcroft-Gault ชาย):*  
    **Given** ผู้ป่วยเพศชาย อายุ 60 ปี น้ำหนัก 70 กก. และ Serum Creatinine 1.2 mg/dL  
    **When** เภสัชกรกดคำนวณ  
    **Then** ระบบต้องแสดงค่า CrCl เท่ากับ $68.06 \pm 0.5$ mL/min  
  - *ฉากที่ 2 (Unhappy/Boundary Path - ขาดค่า SCr):*  
    **Given** มีการกรอกข้อมูลผู้ป่วยแต่ไม่ได้ระบุค่า Serum Creatinine ($SCr \le 0$ หรือว่างเปล่า)  
    **When** ผู้ใช้ดูผลการประเมินการทำงานของไต  
    **Then** ระบบต้องแสดงสถานะ "Unverified / Missing SCr" และไม่อนุญาตให้นำค่าสมมติมาใช้ปรับยา

### FR-02: การคำนวณน้ำหนักตัวอุดมคติและน้ำหนักปรับปรุง (IBW & AdjBW Calculation)
- **User Story:** ในฐานะเภสัชกร ฉันต้องการคำนวณ Ideal Body Weight (Devine) และ Adjusted Body Weight (สำหรับผู้ป่วยอ้วน $\ge 120\%$ IBW) เพื่อป้องกันการจ่ายยาเกินขนาดในผู้ป่วยที่มีภาวะน้ำหนักเกิน
- **Priority:** Must (MVP)
- **Traceability Pain:** การใช้น้ำหนักจริง (TBW) คำนวณยาที่ละลายในน้ำ เช่น Aminoglycosides ในคนอ้วน ทำให้ผู้ป่วยได้รับยาเกินขนาดจนเกิดพิษต่อไต
- **Acceptance Criteria (Given-When-Then):**
  - *ฉากที่ 1 (Happy Path - ผู้ป่วยอ้วนต้องใช้ AdjBW):*  
    **Given** ผู้ป่วยชาย ส่วนสูง 170 ซม. (IBW = 65.94 กก.) แต่น้ำหนักจริง 120 กก. (คิดเป็น 182% ของ IBW)  
    **When** ระบบเลือกกลยุทธ์การคำนวณยา Gentamicin  
    **Then** ระบบต้องใช้น้ำหนักปรับปรุง AdjBW เท่ากับ $87.56 \pm 0.1$ กก. ในการคูณขนาดยา 5 mg/kg (ได้ขนาดยา 437.8 mg) แทนที่จะใช้น้ำหนักจริง 120 กก. (600 mg)  
  - *ฉากที่ 2 (Edge Path - ผู้ป่วยส่วนสูงน้อยกว่า 60 นิ้ว):*  
    **Given** ผู้ป่วยหญิงส่วนสูง 145 ซม. ($\le 60$ นิ้ว หรือ 152.4 ซม.)  
    **When** ระบบคำนวณ Devine IBW  
    **Then** ระบบต้องคืนค่าฐาน 45.5 กก. โดยไม่หักลบค่าติดลบ

### FR-03: เครื่องยนต์ปรับขนาดยาตามระดับไตแบบไร้ช่องว่างทศนิยม (Renal Dosing Engine)
- **User Story:** ในฐานะเภสัชกร ฉันต้องการให้ระบบแนะนำการปรับขนาดยาตามระดับ CrCl ของยาแต่ละชนิดโดยอัตโนมัติ โดยครอบคลุมทุกค่าทศนิยมของ CrCl เพื่อไม่ให้ผู้ป่วยที่มีค่าไตระหว่างช่วงหลุดไปได้ยาขนาดปกติ
- **Priority:** Must (MVP หัวใจของระบบ)
- **Traceability Pain:** ตำรากำหนดช่วงไตเป็นจำนวนเต็ม (เช่น 10–25, 26–50) ผู้ป่วยที่มี CrCl 25.5 mL/min จึงไม่เข้าช่วงใดเลยและได้ยาเต็มขนาด
- **Acceptance Criteria (Given-When-Then):**
  - *ฉากที่ 1 (Happy/Boundary Path - ค่าไตตกช่วงทศนิยมก้ำกึ่ง):*  
    **Given** ผู้ป่วยสั่งใช้ยา Meropenem 1,000 mg q8h แต่มีผล CrCl 25.5 mL/min  
    **When** ระบบประเมินช่วง Renal Adjustment  
    **Then** ระบบต้องจัดให้อยู่ในกลุ่มไตระดับ 26–50 mL/min อัตโนมัติด้วย Rounding Tolerance และแนะนำขนาดยา 1,000 mg q12h พร้อมลดความถี่การให้ยา  
  - *ฉากที่ 2 (Unhappy Path - ยาขับออกทางไตแต่ไม่มีค่า SCr):*  
    **Given** เภสัชกรเลือกคำนวณยา Vancomycin หรือ Meropenem โดยไม่ได้กรอกค่า SCr  
    **When** ระบบประเมินความปลอดภัย  
    **Then** ระบบต้องแสดงคำเตือนระดับ Hard Warning สีแดงว่า "Cannot safely verify renal dose: Serum Creatinine missing" และไม่แสดงป้าย Audit Passed สีเขียว

### FR-04: ระบบตรวจสอบและแจ้งเตือนความปลอดภัยของยา (Clinical Safety & Limit Checker)
- **User Story:** ในฐานะบุคลากรทางการแพทย์ ฉันต้องการรับการแจ้งเตือนทันทีเมื่อขนาดยาที่คำนวณได้เกินขนาดยาสูงสุด (Max Dose) หรือมีข้อห้ามใช้ทางคลินิก เพื่อป้องกันอันตรายก่อนส่งคำสั่งยา
- **Priority:** Must (MVP)
- **Traceability Pain:** การเผลอกรอกตัวเลขเกิน หรือคำนวณยาเคมีบำบัด/ยาปฏิชีวนะเกินขนาดสูงสุดต่อวัน
- **Acceptance Criteria (Given-When-Then):**
  - *ฉากที่ 1 (Happy Path - ยาเคมีบำบัด Carboplatin ปิดเพดาน GFR Cap):*  
    **Given** ผู้ป่วยคำนวณสูตร Calvert Formula โดยมีเป้าหมาย Target AUC = 5 และ CrCl สูงถึง 160 mL/min  
    **When** ระบบประเมินขนาดยา Carboplatin  
    **Then** ระบบต้อง Cap ค่า GFR ไว้ที่ 125 mL/min ตามเกณฑ์ FDA และคำนวณขนาดยาได้สูงสุด $5 \times (125 + 25) = 750$ mg  
  - *ฉากที่ 2 (Unhappy Path - ขนาดยาเกิน Hard Limit):*  
    **Given** ขนาดยา Paracetamol ที่คำนวณได้เกิน 4,000 mg/day  
    **When** ระบบประเมินขนาดยา  
    **Then** หน้าจอต้องแสดงแถบเตือนสีแดงระดับ `LimitSeverity.hard` พร้อมระบุข้อความเตือนพิษต่อตับ และป้ายผลการประเมินต้องไม่ขึ้นสถานะผ่าน

### FR-05: การติดตามระดับยาในเลือดและการคำนวณ AUC₂₄ (Therapeutic Drug Monitoring: TDM)
- **User Story:** ในฐานะเภสัชกรคลินิก ฉันต้องการคำนวณค่าเภสัชจลนศาสตร์ (Ke, Vd, Half-life) และ Steady-State AUC₂₄ ของยา Vancomycin เพื่อให้ได้เป้าหมายการรักษา 400–600 mg·h/L ตามแนวทาง ASHP 2020
- **Priority:** Should
- **Traceability Pain:** แนวทางเก่าดูเฉพาะ Trough Level (15–20 mg/L) ซึ่งทำให้ผู้ป่วยเกิดไตวายเฉียบพลันโดยไม่จำเป็น
- **Acceptance Criteria (Given-When-Then):**
  - *ฉากที่ 1 (Happy Path - AUC อยู่ในเกณฑ์เป้าหมาย):*  
    **Given** ผู้ป่วยได้รับ Vancomycin 750 mg q12h, $V_d = 50$ L, $K_e = 0.06\text{ h}^{-1}$ (Clearance = 3.0 L/h)  
    **When** ระบบคำนวณค่า Steady-State AUC₂₄  
    **Then** ระบบต้องแสดงผล AUC₂₄ เท่ากับ 500.0 mg·h/L พร้อมการ์ดสถานะสีเขียว "Therapeutic Target (400-600)"  
  - *ฉากที่ 2 (Unhappy Path - AUC เกินระดับปลอดภัย):*  
    **Given** ผู้ป่วยได้รับยา Vancomycin 1,000 mg q12h แต่มี Clearance เพียง 2.25 L/h  
    **When** ระบบคำนวณผลลัพธ์  
    **Then** ระบบต้องแสดงค่า AUC₂₄ เท่ากับ 888.89 mg·h/L พร้อมแถบเตือนสีแดง "Supratherapeutic / High Nephrotoxicity Risk"

---

## 4. ข้อกำหนดเชิงคุณภาพ (Non-Functional Requirements - NFR)

| รหัส | มิติ (Aspect) | ข้อกำหนดที่วัดได้เป็นตัวเลข (Measurable Statement) | วิธีการทดสอบ / เครื่องมือวัด |
|---|---|---|---|
| **NFR-01** | Performance | ระบบต้องคำนวณผลลัพธ์ขนาดยา, CrCl, และ Dose Safety Alert ได้ภายในเวลาไม่เกิน **100 มิลลิวินาที** หลังผู้ใช้พิมพ์หรือเปลี่ยนค่า | Automated Benchmark Test ใน Flutter Engine |
| **NFR-02** | Reliability & Offline | ระบบต้องสามารถทำงานได้ **100% แบบ Offline** โดยไม่เรียก Network API ภายนอกในการคำนวณคณิตศาสตร์ เพื่อให้พร้อมใช้ในห้องผ่าตัด/ICU | ปิดการเชื่อมต่อเครือข่าย (Wi-Fi/LAN) แล้วทดสอบเดิน Flow คำนวณยา |
| **NFR-03** | Usability | ผู้ใช้ใหม่ (เภสัชกร/นักศึกษา) สามารถกรอกข้อมูลผู้ป่วยและได้ผลการปรับยาสำเร็จภายใน **ไม่เกิน 30 วินาที** โดยไม่ต้องเปิดคู่มือการใช้งาน | จับเวลาผู้ใช้ทดสอบ 3 คนในการคำนวณเคสตัวอย่าง |
| **NFR-04** | Medical Accuracy | ผลลัพธ์การคำนวณสูตร Cockcroft-Gault, CKD-EPI, Devine IBW, AdjBW, และ Calvert ต้องมีความคลาดเคลื่อนไม่เกิน **$\pm 0.1\%$** เมื่อเทียบกับค่ามาตรฐานจากตำราอ้างอิง | Automated Unit Tests 23 ชุดทดสอบ (ครอบคลุม 100% Core Math) |
| **NFR-05** | Security & Privacy (PDPA) | ข้อมูลส่วนบุคคลของผู้ป่วย (HN, อายุ, เพศ, ค่าน้ำหนัก, ผลแล็บ) ต้องประมวลผลใน Local RAM ของเครื่องเท่านั้น **ห้ามส่งข้อมูลออกนอกเครื่อง** และต้องมีคำสั่ง Clear Session ข้อมูลทันทีที่เสร็จสิ้นเคส | ดักจับ HTTP Network Traffic (DevTools Network Inspector) ยืนยัน Zero External Requests |

---

## 5. รายชื่อ Use Case หลัก (Use Cases)
1. **UC-01: Manage Patient Profile** — บันทึก/แก้ไขข้อมูลสรีรวิทยาของผู้ป่วย (อายุ, น้ำหนัก, ส่วนสูง, เพศกำเนิด, ค่า SCr)
2. **UC-02: Calculate Renal & Physiology** — คำนวณ CrCl, eGFR, BSA, IBW, และ AdjBW
3. **UC-03: Calculate & Adjust Drug Dose** — คำนวณขนาดยาและปรับขนาดยาตามระดับไตแบบอัตโนมัติ
4. **UC-04: Audit Medication Safety** — ตรวจสอบข้อจำกัดขนาดยาสูงสุดและรับการแจ้งเตือนความปลอดภัย
5. **UC-05: Perform Vancomycin TDM & AUC Analysis** — วิเคราะห์ระดับยาและเป้าหมาย AUC₂₄

---

## 6. ขอบเขตที่ตั้งใจไม่ทำ (Out-of-Scope)
1. การเชื่อมต่อสองทาง (Bi-directional sync) กับระบบ Electronic Health Records (EHR) ของโรงพยาบาลผ่านโปรโตคอล HL7 หรือ FHIR
2. การสั่งยิงคำสั่งยาเข้าเครื่องจ่ายยาอัตโนมัติ (Automated Dispensing Machine)
3. ระบบการเงิน บัญชี หรือการคิดค่าบริการทางการแพทย์
4. ระบบ AI วินิจฉัยโรคเพื่อเลือกยาให้ผู้ป่วย (Drug Selection / Medical Diagnosis) โดยระบบจำกัดหน้าที่เฉพาะการตรวจสอบความถูกต้องของขนาดยา (Dose Verification)

---

## 7. บันทึกการใช้งาน AI อย่างโปร่งใส (AI-Use Log)
| วันที่ | เครื่องมือ / โมเดล | สิ่งที่สั่ง (Prompt / Request) | สิ่งที่ AI ร่างให้ | สิ่งที่ทีมตรวจสอบและแก้ไขเอง (Human Verification) | สิ่งที่ได้เรียนรู้ |
|---|---|---|---|---|---|
| 04/10/2026 | Antigravity (Gemini) | "ช่วยตรวจทานสูตรยาในฐานข้อมูลและคำนวณ CrCl ช่วงรอยต่อ" | AI พบว่า Pip/Tazo ใช้ Factor 0.5 และช่องว่าง CrCl 25.5 หลุดการปรับยา | ทีมตรวจสอบเทียบกับ Sanford Guide และ Lexicomp แล้วปรับ Factor เป็น 0.75 พร้อมเขียน Logic ปิดช่องว่างทศนิยม | AI ชี้จุดเสี่ยงทางคณิตศาสตร์ได้ดีมาก แต่ค่าตัวเลขทางคลินิกต้องใช้เภสัชกรยืนยันเทียบกับตำราจริง |
| 04/10/2026 | Antigravity (Gemini) | "สร้างชุด Unit Tests สำหรับสูตรคำนวณทั้งหมด" | AI ร่างชุดทดสอบ 23 ข้อ แต่มีค่าคาดหวังของ AdjBW ผิดเนื่องจากประมาณค่า 170 ซม. คลาดเคลื่อน | ทีมคำนวณมือตามสูตร Devine แท้จริง ($170/2.54 = 66.93$ นิ้ว, $\text{IBW}=65.94$ กก.) แล้วแก้ไขตัวเลขใน Test ให้ตรงเป๊ะ | การพึ่งพา AI อย่างเดียวโดยไม่ตรวจทานคณิตศาสตร์ด้วยตนเองเสี่ยงต่อการหลุดของ Regression Test |
