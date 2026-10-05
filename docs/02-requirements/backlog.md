# Product Backlog & MoSCoW Prioritization — Drugph
**Project:** Drugph — Deterministic Clinical Drug Dosage Engine  
**Milestone:** M2 Requirements Baseline  

---

## 1. เกณฑ์การจัดลำดับความสำคัญ (MoSCoW Rules)
- **Must Have (MVP):** ขาดไม่ได้ หากไม่มีระบบจะไม่มีความหมายทางการแพทย์ โฟกัสฟังก์ชันหลักในการคำนวณและป้องกันอันตรายต่อผู้ป่วย
- **Should Have:** สำคัญ แต่สามารถส่งมอบในรอบถัดไปได้หลังจาก MVP เดินได้สมบูรณ์
- **Could Have:** ฟังก์ชันเสริมความสะดวกสบาย ทำเมื่อมีเวลาเหลือ
- **Won't Have (This Term):** ตั้งใจไม่ทำในเทอมนี้เพื่อป้องกัน Scope บวม (Scope Creep)

---

## 2. ตาราง Product Backlog

| รหัส | รายละเอียดความต้องการ (Requirement) | ประเภท | Priority | ความสัมพันธ์กับปัญหา (Traced Pain) | สถานะการพัฒนา |
|---|---|---|---|---|---|
| **FR-01** | คำนวณค่าการทำงานของไต Cockcroft-Gault CrCl และ CKD-EPI 2021 | Functional | **Must (MVP)** | การคำนวณมือช้าและเสี่ยงตัวเลขสลับ | ✓ เสร็จสมบูรณ์ (23 Tests Pass) |
| **FR-02** | คำนวณ Devine IBW, AdjBW (สำหรับคนอ้วน), และ Mosteller BSA | Functional | **Must (MVP)** | การใช้ TBW ในคนอ้วนทำให้ยาปฏิชีวนะเกินขนาด | ✓ เสร็จสมบูรณ์ (23 Tests Pass) |
| **FR-03** | เครื่องยนต์ปรับขนาดยาตามไตอัตโนมัติ พร้อมปิดช่องว่างทศนิยม CrCl | Functional | **Must (MVP)** | ค่าไตทศนิยมหลุดช่วงปรับยาจนได้ยาเต็มขนาด | ✓ เสร็จสมบูรณ์ (23 Tests Pass) |
| **FR-04** | ระบบตรวจสอบขนาดยาสูงสุด (Dose Limits) และเตือนเมื่อขาดค่า SCr | Functional | **Must (MVP)** | ป้าย Audit Passed หลอกตาแม้ไม่ระบุค่าไต | ✓ เสร็จสมบูรณ์ (23 Tests Pass) |
| **FR-05** | คำนวณ TDM Vancomycin Pharmacokinetics และเป้าหมาย AUC₂₄ | Functional | **Should** | การดูเฉพาะ Trough ล้าสมัยและเสี่ยงไตวาย | ✓ เสร็จสมบูรณ์ (23 Tests Pass) |
| **FR-06** | เครื่องมือคำนวณสารน้ำหยดเข้าหลอดเลือดดำ (IV Infusion / Titration) | Functional | **Could** | คำนวณอัตราหยดผิดพลาดในหอผู้ป่วย | ✓ เสร็จสมบูรณ์ |
| **FR-07** | ส่งออกเอกสารสรุปการประเมินยาเป็น PDF Audit Report | Functional | **Could** | การบันทึกหลักฐานลงเวชระเบียนผู้ป่วย | ✓ มี Prototype |
| **NFR-01** | เวลาคำนวณผลลัพธ์ $\le 100$ มิลลิวินาที | Non-Functional | **Must (MVP)** | ต้องการความเร็วในการตอบสนองทางคลินิก | ✓ ผ่านการทดสอบ |
| **NFR-02** | ทำงานได้ 100% Offline ไม่พึ่งพา Internet Server | Non-Functional | **Should** | หอผู้ป่วยหรือห้องผ่าตัดอับสัญญาณ | ✓ ผ่านการทดสอบ |
| **NFR-03** | ผู้ใช้คำนวณเคสสำเร็จใน $\le 30$ วินาที | Non-Functional | **Should** | ภาระงานล้นในหอผู้ป่วยวิกฤต | ✓ ผ่านการทดสอบ |
| **NFR-04** | ความคลาดเคลื่อนทางคณิตศาสตร์ $\le \pm 0.1\%$ | Non-Functional | **Must (MVP)** | ความปลอดภัยสูงสุดของผู้ป่วย (SaMD) | ✓ 23 Tests Pass |
| **NFR-05** | ประมวลผล Local Only ตามหลัก PDPA & Security | Non-Functional | **Must (MVP)** | การรั่วไหลของข้อมูลเวชระเบียน | ✓ ผ่านการทดสอบ |
| **OUT-01**| การเชื่อมต่อระบบเวชระเบียน HIS ผ่าน HL7/FHIR | Out-of-Scope | **Won't** | ซับซ้อนเกินกว่ากรอบเวลา 1 เทอม | ✗ นอกขอบเขต |
| **OUT-02**| การจ่ายเงินและระบบคลังยาโรงพยาบาล | Out-of-Scope | **Won't** | ไม่ใช่แก่นของระบบความปลอดภัยยา | ✗ นอกขอบเขต |
