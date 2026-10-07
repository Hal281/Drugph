# Drugph — Clinical Project Guidelines & Core Principles
**เอกสารคู่มือแนวทางและหลักการสำคัญของโปรเจกต์ Drugph**  
*สถานะ: บังคับใช้ถาวร (Active / Immutable Core Policy)*  
*กลุ่มผู้ใช้เป้าหมาย: แพทย์ (Physicians) และเภสัชกรคลินิก (Clinical Pharmacists)*  

---

## 1. วิสัยทัศน์และจุดประสงค์ของระบบ (Vision & Scope)
**Drugph** ได้รับการพัฒนาขึ้นเพื่อเป็นเครื่องมือช่วยตัดสินใจทางคลินิก (Clinical Decision Support Tool / SaMD Prototype) สำหรับแพทย์และเภสัชกรในการบริบาลผู้ป่วย ทั้งในหอผู้ป่วยทั่วไปและหอผู้ป่วยวิกฤต (ICU/Emergency)

ระบบมุ่งเน้นการขจัดความคลาดเคลื่อนทางยา (Zero Medication Errors) ผ่านการคำนวณที่แม่นยำทางคณิตศาสตร์และเภสัชจลนศาสตร์ (Pharmacokinetics) พร้อมระบบตรวจจับความปลอดภัยก่อนการสั่งใช้ยาจริง

---

## 2. กฎเหล็ก 5 ประการของโปรเจกต์ (The 5 Ironclad Rules)

### 1. ความแม่นยำในการคำนวณ 100% (Zero Calculation Errors)
* **เกณฑ์การยอมรับ:** ความคลาดเคลื่อนทางคณิตศาสตร์ต้องเป็นศูนย์ (Zero Tolerance)
* **การคำนวณครอบคลุม:**
  * ขนาดยาตามน้ำหนักตัวจริง (TBW), น้ำหนักอุดมคติ (IBW), หรือน้ำหนักปรับแต่ง (AdjBW)
  * ขนาดยาตามพื้นที่ผิวกาย (BSA: Mosteller formula)
  * การประเมินฟังก์ชันไต (Cockcroft-Gault CrCl, CKD-EPI 2021 race-free, Schwartz pediatric eGFR)
  * เภสัชจลนศาสตร์ขั้นสูง เช่น Calvert formula (Carboplatin AUC) และ Vancomycin AUC/TDM
  * อัตราการหยดสารน้ำทางหลอดเลือดดำ (IV Infusion / Titration: mcg/kg/min, mg/hr, mL/hr, drops/min)
  * การแปลงหน่วยทุกระดับ (g $\leftrightarrow$ mg $\leftrightarrow$ mcg, Units $\leftrightarrow$ mU)
  * การปัดขนาดยาตามรูปแบบยาที่มีจำหน่ายจริงในคลังยา (Formulary Strength Rounding)
* **หลักการโค้ด:** ต้องเขียนเป็น Pure Function, Deterministic, ไร้ Side Effects และผ่าน Unit Tests ทุกเงื่อนไข

### 2. อ้างอิงจากตำราแพทย์และตำราเภสัชกรรมมาตรฐานระดับโลกเท่านั้น (Strict Evidence-Based Medicine)
* **ห้ามแต่งหรือสมมติข้อมูลขึ้นเองเด็ดขาด (Strictly No Hallucination)**
* ทุกสูตรยา, ขนาดยาสูงสุด (Dose Limits), การปรับยาตามไตและตับ (Renal/Hepatic Adjustments) ต้องอ้างอิงจากแหล่งข้อมูลที่แพทย์และเภสัชกรทั่วโลกให้การยอมรับ:
  * **ตำรามาตรฐานสากล:**
    * *Lexicomp Drug Information*
    * *The Sanford Guide to Antimicrobial Therapy*
    * *Goodman & Gilman's The Pharmacological Basis of Therapeutics*
    * *DiPiro's Pharmacotherapy: A Pathophysiologic Approach*
    * *Martindale: The Complete Drug Reference*
  * **องค์กรและแนวทางเวชปฏิบัติสากล:**
    * World Health Organization (WHO)
    * US Food and Drug Administration (US FDA) & Thai FDA (อย.)
    * Kidney Disease: Improving Global Outcomes (KDIGO)
    * American College of Cardiology / American Heart Association (ACC/AHA)
    * American Society of Health-System Pharmacists (ASHP)
    * American College of Chest Physicians (CHEST Guidelines)
    * UpToDate และ PubMed / National Library of Medicine (NLM)

### 3. ห้ามจ่ายยาซ้ำซ้อน (Therapeutic Duplication Prevention)
ระบบต้องตรวจจับและแจ้งเตือนทันทีเมื่อตรวจพบการสั่งยาซ้ำซ้อน:
1. **การสั่งตัวยาสำคัญเดียวกันซ้ำ (Identical Active Ingredient):** เช่น มีการสั่ง Paracetamol ในผู้ป่วยที่ได้รับ Paracetamol อยู่แล้ว
2. **การสั่งยาในกลุ่มเดียวกันที่เป็นข้อห้ามใช้ทางการแพทย์ (Contraindicated Same-Class Combinations):**
   * **Dual NSAIDs (เช่น Ibuprofen + Naproxen):** ห้ามใช้ร่วมกันเด็ดขาดเนื่องจากเพิ่มความเสี่ยงแผลทางเดินอาหาร เลือดออกรุนแรง และไตวายเฉียบพลัน โดยไม่เพิ่มประสิทธิภาพระงับปวด
   * **Dual RAS Blockade (ACEI + ARB เช่น Enalapril + Losartan):** ข้อห้ามใช้ตามแนวทาง ONTARGET trial และ KDIGO เนื่องจากเพิ่มความเสี่ยงภาวะโพแทสเซียมในเลือดสูงวิกฤต (Severe Hyperkalemia) และไตวายเฉียบพลัน
   * **Dual Oral Anticoagulants (DOAC + Warfarin หรือ DOAC + DOAC เช่น Apixaban + Warfarin):** ข้อห้ามใช้ตามแนวทาง CHEST Guideline เนื่องจากเสี่ยงต่อภาวะเลือดออกรุนแรงถึงแก่ชีวิต (Fatal Hemorrhage)
   * **Dual Statins (เช่น Simvastatin + Rosuvastatin):** ห้ามใช้ร่วมกัน เสี่ยงต่อกล้ามเนื้อลายสลาย (Rhabdomyolysis) และไตวาย
   * **Dual Potassium-Sparing Diuretics (เช่น Spironolactone ซ้ำซ้อน):** เสี่ยงต่อภาวะโพแทสเซียมสูงจนหัวใจหยุดเต้น

### 4. การตรวจจับปฏิกิริยาระหว่างยา (Drug-Drug Interactions - DDI / ยาตีกัน)
* ตรวจจับทั้งการสั่งยาเดี่ยวเทียบกับยาเดิมของผู้ป่วย และการตรวจจับพร้อมกันในตะกร้าสั่งยา (Prescription Cart)
* ตรวจจับคู่ยาตีกันระดับวิกฤต เช่น:
  * **Methotrexate + NSAIDs:** NSAID ยับยั้ง OAT1/OAT3 ในท่อไต ทำให้ Methotrexate คั่ง พิษกดไขกระดูกและไตวาย
  * **ACEI/ARB + Spironolactone:** ยับยั้งการขับโพแทสเซียม เสี่ยง Hyperkalemia วิกฤต
  * **ACEI/ARB + NSAIDs:** เสี่ยงภาวะไตวายเฉียบพลันจากการลดแรงดันกรองในไต (Hemodynamic AKI / Double Whammy)
  * **Clopidogrel + Omeprazole:** ยับยั้ง CYP2C19 ลดการสร้างสารออกฤทธิ์ของ Clopidogrel เสี่ยงลิ่มเลือดอุดตันซ้ำ
  * **Simvastatin + Macrolides (Clarithromycin/Erythromycin):** ยับยั้ง CYP3A4 รุนแรง เสี่ยงต่อ Rhabdomyolysis
  * **Digoxin + Amiodarone:** ยับยั้ง P-glycoprotein ระดับ Digoxin ในเลือดเพิ่มขึ้น 2 เท่า เสี่ยงพิษ Digitalis Toxicity
* ทุกการแจ้งเตือนต้องระบุระดับความรุนแรง, กลไกทางเภสัชวิทยา, และคำแนะนำแนวทางแก้ไข (Actionable Clinical Management)

### 5. นโยบายอนุญาตให้คำนวณ Overdose ในภาวะฉุกเฉิน (Non-Blocking Overdose Policy)
* **หลักการ:** ในสถานการณ์เร่งรีบหรือวิกฤตฉุกเฉิน แพทย์หรือเภสัชกรอาจมีความจำเป็นต้องคำนวณขนาดยาพิเศษ (STAT/Emergency) เพื่อช่วยชีวิตคนไข้
* **กฎข้อบังคับ:**
  1. **ห้ามบล็อกการคำนวณ ห้ามล็อกหน้าจอ และห้ามซ่อนตัวเลขโดสยาเด็ดขาด**
  2. ตัวเลขขนาดยาจริงที่คำนวณได้ (`calculatedDose`) และขนาดยาหลังปัดเศษ (`roundedDose`) จะต้องปรากฏบนหน้าจอให้เห็นชัดเจนเสมอ
  3. แสดงแถบแจ้งเตือนความปลอดภัยสีแดง/ส้มเด่นชัดที่ด้านบนหน้าจอ:  
     > *"⚠️ คำเตือน: ขนาดยานี้เกินเกณฑ์สูงสุดที่แนะนำ (Overdose Warning) — โปรดใช้ดุลยพินิจของแพทย์/เภสัชกรในการให้ยา"*

---

## 3. สถาปัตยกรรมระบบและความปลอดภัย (SaMD / Software Architecture)
* **Deterministic Core:** โค้ดทั้งหมดใน `lib/core/` ต้องไม่มีการสุ่มตัวเลข ไม่มีการเชื่อมต่อภายนอกที่ทำให้ผลลัพธ์ไม่เสถียร
* **Comprehensive Test Suite:** ทุกการเปลี่ยนแปลงแก้ไขฟีเจอร์หรือแก้ไขบั๊ก ต้องผ่านการทดสอบแบบ Regression Test (`flutter test`) 100% เสมอ
* **Static Analysis:** ต้องรักษามาตรฐานโค้ดให้สะอาด ปราศจาก Warning และ Lint (`flutter analyze` ต้องได้ `No issues found!`)
