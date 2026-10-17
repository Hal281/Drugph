# AGENTS.md — กฎเหล็กและแนวทางหลักของโปรเจกต์ Drugph
> **คำสั่งถาวรสำหรับ AI Assistants / Pair Programmers ทุกคน**  
> เอกสารนี้บันทึก "กฎเหล็ก (Ironclad Rules)" และแนวคิดพื้นฐานของโปรเจกต์ **Drugph** ตามเจตนารมณ์ของผู้พัฒนา  
> **ก่อนเริ่มตอบคำถาม คิดแผน หรือเขียนโค้ด ให้ยึดถือและปฏิบัติตามกฎในเอกสารนี้อย่างเคร่งครัดทุกครั้ง**

---

## 1. จุดประสงค์และกลุ่มผู้ใช้งาน (Target Users & Scope)
* **ผู้ใช้งานหลัก:** **แพทย์ (Physicians)** และ **เภสัชกรคลินิก (Clinical Pharmacists)**
* **ขอบเขต:** แอปพลิเคชันคำนวณขนาดยา (Clinical Dosage Calculation), ตรวจสอบความปลอดภัยทางยา, ตรวจสอบการแพ้ยา, ป้องกันการจ่ายยาซ้ำซ้อน, และตรวจจับปฏิกิริยาระหว่างยา (Drug-Drug Interactions - DDI)
* ระบบต้องมีความเป็นมืออาชีพ มีความน่าเชื่อถือทางคลินิกสูงสุด และรองรับการทำงานทั้งในหอผู้ป่วยทั่วไปและหอผู้ป่วยวิกฤต (ICU/Emergency)

---

## 2. กฎเหล็ก 5 ข้อ (Core Ironclad Rules)

### 📌 กฎข้อที่ 1: ความแม่นยำในการคำนวณ 100% ห้ามมีข้อผิดพลาด (Zero-Error Calculation Policy)
* การคำนวณโดสยา, การคำนวณตามน้ำหนัก (Weight-based mg/kg), พื้นที่ผิวกาย (BSA-based mg/m²), เภสัชจลนศาสตร์ (AUC/CrCl/eGFR), การแปลงหน่วย (Unit Conversion เช่น g, mg, mcg, mL), การปรับอัตราการหยดยา (IV Infusion / Titration), และการปัดเศษยา (Formulary Rounding) **ต้องแม่นยำ ถูกต้อง 100% ห้ามมีข้อผิดพลาดโดยเด็ดขาด**
* โค้ดส่วนคำนวณต้องเป็น Pure Function, Deterministic, ปราศจาก Side Effects, และมี Unit Tests ครอบคลุมทุก Edge Case เสมอ

### 📌 กฎข้อที่ 2: อ้างอิงจากตำราแพทย์และตำราเภสัชกรรมมาตรฐานเท่านั้น (Strict Evidence-Based Medicine)
* **ห้ามคาดเดา ห้ามอนุมาน หรือห้ามแต่งข้อมูลทางการแพทย์ขึ้นมาเอง (Strictly No Hallucination)**
* ข้อมูลยาทุกตัว, ช่วงขนาดยา, ขนาดยาสูงสุด (Dose Limits), การปรับยาตามไตและตับ, และการเตือนต่าง ๆ ต้องอ้างอิงจาก:
  1. **ตำราแพทย์และเภสัชกรรมระดับสากล:** Lexicomp Drug Information, Sanford Guide to Antimicrobial Therapy, Goodman & Gilman's The Pharmacological Basis of Therapeutics, DiPiro's Pharmacotherapy, Martindale
  2. **แหล่งข้อมูลทางการแพทย์ที่แพทย์และเภสัชกรทั่วโลกให้การยอมรับ:** WHO, US FDA, Thai FDA (อย.), KDIGO Clinical Practice Guidelines, ACC/AHA, ASHP Guidelines, CHEST Guidelines, UpToDate, PubMed / NCBI

### 📌 กฎข้อที่ 3: ห้ามจ่ายยาซ้ำซ้อน (Therapeutic Duplication Prevention)
* ตรวจสอบและแจ้งเตือนอย่างเด็ดขาดเมื่อมีการสั่งยาซ้ำซ้อน:
  1. **ยาตัวเดิมซ้ำ (Identical Active Ingredient):** เช่น สั่งใช้ Paracetamol ซ้ำซ้อน
  2. **ยาต่างโมเลกุลในกลุ่มเดียวกันที่เป็นข้อห้ามใช้ (Contraindicated Same-Class Combinations):**
     * **Dual NSAIDs** (เช่น Ibuprofen + Naproxen) $\rightarrow$ ห้ามใช้ซ้ำซ้อน เสี่ยงแผลทะลุ เลือดออกในกระเพาะ และไตวายเฉียบพลัน
     * **Dual RAS Blockade** (ACEI + ARB เช่น Enalapril + Losartan) $\rightarrow$ ข้อห้ามใช้ตามแนวทาง ONTARGET / KDIGO เสี่ยงต่อภาวะโพแทสเซียมในเลือดสูงวิกฤต (Severe Hyperkalemia)
     * **Dual Oral Anticoagulants** (DOAC + Warfarin หรือ DOAC + DOAC เช่น Apixaban + Warfarin) $\rightarrow$ เสี่ยงเลือดออกรุนแรงถึงแก่ชีวิต (Fatal Hemorrhage)
     * **Dual Statins** (เช่น Simvastatin + Rosuvastatin) $\rightarrow$ เสี่ยงกล้ามเนื้อลายสลาย (Rhabdomyolysis)
     * **Dual Potassium-Sparing Diuretics** (เช่น Spironolactone ซ้ำซ้อน) $\rightarrow$ เสี่ยงภาวะโพแทสเซียมคั่งจนหัวใจหยุดเต้น

### 📌 กฎข้อที่ 4: การตรวจจับปฏิกิริยาระหว่างยา (Drug-Drug Interactions - DDI)
* การตรวจจับยาตีกันต้องอ้างอิงจากตำราแพทย์และกลไกทางเภสัชวิทยาจริง (เช่น CYP enzyme inhibition/induction, P-gp transport, Renal tubular secretion)
* ต้องระบุทั้ง **ระดับความรุนแรง (Severity)**, **กลไกการตีกัน (Mechanism)**, และ **คำแนะนำในการจัดการทางคลินิก (Management/Action)**

### 📌 กฎข้อที่ 5: นโยบายอนุญาตให้คำนวณ Overdose เพื่อภาวะฉุกเฉิน (Non-Blocking Overdose Policy)
* **หัวใจสำคัญ:** ระบบอนุญาตให้แพทย์หรือเภสัชกรคำนวณโดสยาที่เกินเกณฑ์ปลอดภัย (Overdose) ได้ เผื่อในสถานการณ์ฉุกเฉินวิกฤตที่แพทย์/เภสัชกรมีความจำเป็นต้องคำนวณขนาดยาพิเศษเพื่อช่วยชีวิตคนไข้
* **ข้อห้ามเด็ดขาด:** **ห้ามบล็อก ห้ามล็อกหน้าจอ และห้ามซ่อน/ลบตัวเลขขนาดยาที่คำนวณได้ออกไปเด็ดขาด** (ตัวเลข `calculatedDose` และ `roundedDose` ต้องแสดงผลให้แพทย์/เภสัชกรเห็นชัดเจนเสมอ)
* **สิ่งที่ต้องทำ:** แสดงแถบหรือกล่องเตือนสีแดง/ส้มเด่นชัดที่ด้านบนหน้าจอ แจ้งเตือนอย่างชัดเจนว่า:
  > *"⚠️ คำเตือน: ขนาดยานี้เกินเกณฑ์สูงสุดที่แนะนำ (Overdose Warning) — โปรดใช้ดุลยพินิจของแพทย์/เภสัชกรในการให้ยา"*

---

## 3. เอกสารอ้างอิงเพิ่มเติมในโปรเจกต์
หากมีข้อสงสัยหรือต้องการตรวจสอบรายละเอียดเชิงลึก ให้ศึกษาเอกสารในโฟลเดอร์ `docs/`:
* [`docs/PROJECT_GUIDELINES.md`](file:///c:/Users/turbo/drugforPh/docs/PROJECT_GUIDELINES.md) — คู่มือแนวทางระบบเชิงละเอียด (Clinical & Engineering Charter)
* [`docs/VERIFICATION_PROTOCOL.md`](file:///c:/Users/turbo/drugforPh/docs/VERIFICATION_PROTOCOL.md) — ระเบียบปฏิบัติการตรวจรับรองข้อมูลและสูตรคำนวณยาทางคลินิก
* [`docs/01-charter/charter.md`](file:///c:/Users/turbo/drugforPh/docs/01-charter/charter.md) — ปัญหาจริงและ Root Cause Analysis
* [`DECISIONS.md`](file:///c:/Users/turbo/drugforPh/DECISIONS.md) — บันทึกการตัดสินใจทางคลินิกและสถาปัตยกรรม

---

## 4. ระเบียบปฏิบัติการตรวจรับรองข้อมูลยา (Clinical Verification Protocol)
1. **แหล่งอ้างอิงมาตรฐาน:** ข้อมูลยาทุกตัวต้องอ้างอิงจาก 7 ตำรามาตรฐานที่แพทย์และเภสัชกรไทยใช้จริง (The Sanford Guide 2024, Lexicomp 2024, คู่มือปรับยาโรคไตสมาคมโรคไตไทย, แนวทางสมาคมโรคติดเชื้อไทย IDAT, บัญชียาหลักแห่งชาติ/RDU Thailand, คู่มือยาฉีดรามาธิบดี/ศิริราช, DiPiro)
2. **การแสดงผล Monograph:** หน้าจอคำนวณยาต้องเชื่อมต่อกับ `ClinicalEvidenceSheet` เพื่อให้แพทย์/เภสัชกรสามารถเปิดดูข้อมูลตำราของยานั้น ๆ ได้ทันที
3. **การสร้างเอกสารให้เภสัชกรตรวจ:** ใช้คำสั่ง `dart run tool/generate_pharmacist_dossier_pdf.dart` เพื่อส่งออกเอกสาร `review/Clinical_Verification_Dossier.pdf` (พร้อมช่องลงนาม ภก. และ ว.)

