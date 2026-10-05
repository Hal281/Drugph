# บันทึกการใช้งาน AI อย่างโปร่งใส (AI-Use Statement & Reflection)
**Course:** Introduction to Software Engineering (15031001) — Academic Year 2569  
**Milestone:** M3 / M4 Final Delivery Component  
**Project:** Drugph — Deterministic Clinical Drug Dosage Engine  

---

## 1. ขอบเขตการใช้งาน AI (Where AI Was Used)
ในโปรเจกต์ Drugph ทีมได้นำ Agentic AI (Google Antigravity / Gemini) มาช่วยในการพัฒนากระบวนการ Software Engineering ในมิติต่าง ๆ ดังนี้:
1. **การตรวจสอบและระบุช่องโหว่ทางคณิตศาสตร์ (Edge Case Identification):** ให้ AI ช่วยค้นหาช่องว่างของตัวเลขทศนิยมใน `RenalAdjustment` ซึ่งพบว่า CrCl ระหว่าง 25.01–25.99 mL/min จะหลุดการปรับยาในโค้ดเดิม
2. **การเขียนโครงสร้างชุดทดสอบอัตโนมัติ (Test Scaffolding):** ให้ AI ช่วยร่างโค้ดทดสอบ Unit Test สำหรับสูตรคณิตศาสตร์ใน `test/engine_test.dart`
3. **การแปลงและล้างโค้ดที่ล้าสมัย (Automated Code Cleanup):** ให้ AI ช่วยจัดการคำสั่งที่เลิกใช้ (Deprecations) ใน Flutter เช่น `withOpacity` $\rightarrow$ `withValues` และ `value` $\rightarrow$ `initialValue`
4. **การร่างเอกสารตามมาตรฐาน SE (SRS & Architecture Drafting):** ให้ AI ช่วยจัดระเบียบโครงสร้างเอกสารตามรูปแบบ IEEE 830 และสร้าง Mermaid Diagrams

---

## 2. สิ่งที่ AI ทำได้ดี (What Worked Well)
- **การตรวจจับ Pattern ที่ซ้ำซ้อน:** AI สามารถกวาดตรวจโค้ดใน 28 ไฟล์ และชี้จุดที่มีการใช้ bang operator (`!`) ฟุ่มเฟือย และแจ้งเตือนจุดที่ไม่มี Input Validation
- **ความรวดเร็วในการจัดทำโครงเอกสารและไดอะแกรม:** สามารถแปลงความสัมพันธ์ของคลาสออกมาเป็นโค้ด Mermaid ได้อย่างเป็นระเบียบและถูกต้องตามหลัก UML

---

## 3. สิ่งที่ AI ทำพลาดและมนุษย์ต้องตรวจสอบ/แก้ไขเอง (What Failed & Human Fixes)
1. **ความคลาดเคลื่อนในการคำนวณคณิตศาสตร์ทางคลินิก (Math Halucination / Precision Error):**
   - *สิ่งที่เกิดขึ้น:* ในตอนร่าง Unit Test สำหรับผู้ป่วยชายส่วนสูง 170 ซม. AI กำหนดค่าคาดหวังของ Ideal Body Weight (IBW) ไว้ที่ 66.86 กก. ซึ่งทำให้การคำนวณ AdjBW ผิดเป็น 88.11 กก.
   - *การแก้ไขโดยมนุษย์:* ทีมได้คำนวณสูตร Devine ด้วยตนเองตามตำรา: $170\text{ cm} / 2.54 = 66.929$ นิ้ว $\rightarrow 50 + 2.3 \times (66.929 - 60) = 65.94$ กก. และคำนวณ $\text{AdjBW} = 65.94 + 0.4 \times (120 - 65.94) = 87.56$ กก. จากนั้นแก้ Test Assertion จนได้ผลลัพธ์ที่ถูกต้องแท้จริง
2. **ข้อมูลแนวทางเวชปฏิบัติที่ล้าสมัย (Outdated Clinical Guidelines):**
   - *สิ่งที่เกิดขึ้น:* AI เคยร่างคำแนะนำการติดตามยา Vancomycin โดยดูเฉพาะ Trough Level (15–20 mg/L) ซึ่งเป็นแนวทางเดิมปี 2009
   - *การแก้ไขโดยมนุษย์:* ทีมได้ปรับแก้โมเดลและหน้าจอให้สอดคล้องกับแนวทางสากลฉบับปัจจุบันของ ASHP/IDSA 2020 โดยเพิ่มการคำนวณ Steady-State AUC₂₄ (เป้าหมาย 400–600 mg·h/L)
3. **การสมมติค่าโดยไม่มีหลักฐานรองรับ (Unsubstantiated Clinical Assumptions):**
   - *สิ่งที่เกิดขึ้น:* ในโมดูล IV Titration โค้ดเดิมมีการสมมติปริมาตรสารน้ำเจือจาง (100 mL หรือ 250 mL) ขึ้นมาเองสำหรับยาที่ไม่มีข้อมูล
   - *การแก้ไขโดยมนุษย์:* ปรับให้ระบบบล็อกการคำนวณและบังคับให้ผู้ใช้ระบุ Standard Dilution Concentration mg/mL ก่อนเสมอ เพื่อความปลอดภัยของผู้ป่วย

---

## 4. บทเรียนสำคัญ (Key Lessons Learned)
> *"AI เป็นเครื่องมือเพิ่มความเร็วในการเขียนโค้ดและช่วยมองหาจุดบกพร่องได้อย่างยอดเยี่ยม แต่ในซอฟต์แวร์ทางการแพทย์ (Software as a Medical Device) ตรรกะทางคณิตศาสตร์และมาตรฐานการรักษายังคงต้องผ่านการตรวจสอบ ยืนยัน และรับรองโดยมนุษย์เสมอ (Human-in-the-Loop Verification is Non-Negotiable)"*
