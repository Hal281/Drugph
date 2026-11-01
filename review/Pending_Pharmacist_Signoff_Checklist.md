# เอกสารตรวจรับรองการตัดสินใจทางคลินิกและกำหนดนโยบายการให้ยาโรงพยาบาล
# Hospital Pharmacy & Therapeutics (P&T) Committee Clinical Sign-Off Checklist
## Drugph Clinical Decision Support System — Phase 2 Pending Decisions Package

---

### ข้อมูลเอกสาร (Document Metadata)
* **ระบบ:** Drugph Clinical Dosage & Medication Safety Calculation Engine
* **เวอร์ชันแพ็กเกจ:** Phase 2 Decision Package (`DEC-PND-001` ถึง `DEC-PND-006`)
* **วัตถุประสงค์:** เครื่องมือตรวจรับรองและลงนามโดยเภสัชกรคลินิกและประธานคณะกรรมการเภสัชกรรมและการบำบัด (P&T Committee) เพื่อกำหนดขนาดยาสูงสุด (Dose Ceilings), ตัวกรองประชากร (Population Criteria), และแบบจำลองทางเภสัชจลนศาสตร์ (TDM PK Models)
* **นโยบายความปลอดภัย:** อ้างอิงตามกฎเหล็ก AGENTS.md ข้อ 1 (Zero-Error Calculation) และข้อ 2 (Strict Evidence-Based Medicine) โดยระหว่างที่ยังไม่ได้รับมติลงนาม ระบบจะคงผลการคำนวณตามมาตรฐานเดิม (Baseline) และแสดงคำเตือนทางคลินิก (Pending Verification Warnings) อย่างโปร่งใส ไม่มีการคาดเดาหรือแก้ไขตัวเลขทางคณิตศาสตร์เอง

---

## สรุปภาพรวมสำหรับคณะกรรมการ (Executive Summary)

ตารางสรุป 6 ประเด็นทางคลินิกที่เปิดให้คณะกรรมการ P&T และกลุ่มงานเภสัชกรรมคลินิกลงมติเลือกแนวทางที่สอดคล้องกับบริบทของโรงพยาบาล:

| รหัสตัดสินใจ | ตัวยา / โมเดล | กลุ่มงานทางคลินิก | พฤติกรรมปัจจุบันใน Drugph (Baseline) | ข้อเสนอแนะมาตรฐาน (Option A) | สถานะ |
|---|---|---|---|---|---|
| **DEC-PND-001** | `acyclovir` (IV) | โรคติดเชื้อ / กำกับการใช้ยาต้านจุลชีพ | ใช้ TBW; ติดเพดานยากิน 800 mg (คนไข้ $\ge 85\text{ kg}$ ติดเตือน Overdose) | ใช้น้ำหนัก IBW เมื่อ BMI $\ge 30$; ปรับเพดานยาฉีดเป็น 1,000 mg/dose | `[ ] รอลงนาม` |
| **DEC-PND-002** | `atropine` (IV/IO) | เวชศาสตร์ฉุกเฉิน / กู้ชีพเด็ก | 0.02 mg/kg; มี min 0.1 mg / max 0.5 mg (เด็ก $> 25\text{ kg}$ ติดเตือน Overdose) | ปรับตาม PALS 2020: ตั้ง `doseCap: 0.5 mg` และตัดเกณฑ์ขั้นต่ำ 0.1 mg ออก | `[ ] รอลงนาม` |
| **DEC-PND-003** | `dexamethasone` (PO) | ระบบหายใจและภูมิแพ้เด็ก | 0.6 mg/kg; max 10.0 mg (เด็ก $> 16.7\text{ kg}$ ติดเตือน Overdose) | กำหนดเพดาน `doseCap: 10.0 mg` คงที่ (RCH Melbourne / CPS) | `[ ] รอลงนาม` |
| **DEC-PND-004** | `epinephrine` (IM) | เวชศาสตร์ฉุกเฉิน / กู้ชีพเด็ก | 0.01 mg/kg; max 0.3 mg (เด็ก $> 30\text{ kg}$ ติดเตือน Overdose) | กำหนดเพดานเด็ก `doseCap: 0.3 mg` คงที่ (WAO 2020 / AAP) | `[ ] รอลงนาม` |
| **DEC-PND-005** | `salbutamol` (Neb) | ระบบหายใจและภูมิแพ้เด็ก | 0.15 mg/kg; ไม่มีตัวกรองน้ำหนัก; max 2.5 mg (เด็ก $\ge 20\text{ kg}$ ติดเตือน Overdose) | เพิ่ม `PopulationCriteria(maxWeightKg: 20)` และ `doseCap: 2.5 mg` (GINA 2023) | `[ ] รอลงนาม` |
| **DEC-PND-006** | `Hartford & Vd` (TDM) | TDM และเภสัชจลนศาสตร์ | กราฟเส้นตรงโดยประมาณ; แสดงแถบเตือนสีส้ม; Vancomycin Vd 0.52 และ 0.85 L/kg | รับรองสมการเส้นตรงเทียบ Nicolau 1995 + บันทึกหลักฐาน Vd ทางวิชาการ | `[ ] รอลงนาม` |

---

## รายละเอียด 6 ประเด็นทางคลินิก (Detailed Clinical Decision Profiles)

```
================================================================================
ประเด็นที่ 1: DEC-PND-001
หัวข้อ: Acyclovir IV — เพดานขนาดยาโรคสมองอักเสบจากเริม และเกณฑ์น้ำหนักในผู้ป่วยอ้วน
================================================================================
```
* **สาขาคลินิก:** โรคติดเชื้อและการกำกับการใช้ยาต้านจุลชีพ (`PendingDecisionCategory.antimicrobialStewardship`)
* **ตัวยาที่เกี่ยวข้อง:** `acyclovir` (Acyclovir Sodium for Injection)
* **ตำแหน่งโค้ดในระบบ:** `lib/data/drugs/antibiotics.dart` (lines 1188–1213)
* **ข้อถกเถียงและปัญหาทางคลินิก (Clinical Dilemma):**
  * *ภาษาไทย:* สูตรการให้ยา Acyclovir IV ในภาวะ Herpes Simplex Encephalitis (10 mg/kg ทุก 8 ชม.) ในระบบ มีการตั้งเพดานขนาดยาสูงสุดต่อครั้ง (maxSingleDose) ไว้ที่ 800 mg ซึ่งเป็นตัวเลขตกค้างของยารับประทาน (Oral Zoster) ทำให้ผู้ป่วยผู้ใหญ่ที่มีน้ำหนัก $\ge 85\text{ kg}$ ถูกแจ้งเตือนว่าได้รับยาเกินขนาด (Overdose) ทั้งที่ขนาดมาตรฐานในการรักษาต้องการยา 850–1,000 mg/dose นอกจากนี้ ในหมายเหตุแนะนำให้ใช้ IBW ในคนอ้วน แต่สูตรคำนวณปัจจุบันยังคำนวณตามน้ำหนักจริง (TBW)
  * *English:* The IV Herpes Simplex Encephalitis regimen (10 mg/kg q8h) currently enforces an oral 800 mg maxSingleDose ceiling. Consequently, patients $\ge 85\text{ kg}$ trigger an Overdose Warning (> 800 mg), even though high-dose CNS penetration requires 850–1,000 mg per dose. Additionally, the engine calculates on TBW despite text notes advising IBW in obesity.
* **พฤติกรรมปัจจุบันในระบบ (Current Baseline):**
  * คำนวณ 10 mg/kg โดยใช้ TBW; มีข้อจำกัด `limits: DoseLimit(maxSingleDose: 800.0)`.
  * ผู้ป่วย 70 kg ได้รับ 700 mg (ปกติ); ผู้ป่วย 90 kg ได้รับ 900 mg (ระบบแจ้งเตือน Overdose `maxSingleDoseExceeded`).

#### ทางเลือกทางคลินิก (Candidate Clinical Options) — โปรดทำเครื่องหมายเลือก 1 ข้อ:
- [ ] **Option A: ใช้น้ำหนัก IBW เมื่อ BMI $\ge 30\text{ kg/m}^2$ และปรับเพดานยาฉีดสูงสุดเป็น 1,000 mg ต่อครั้ง (แนะนำ)**
  * **รายละเอียด:** หากผู้ป่วยมี BMI $\ge 30\text{ kg/m}^2$ ให้ใช้น้ำหนักในอุดมคติ (IBW) คำนวณ (หรือใช้ TBW หากผอมกว่า IBW) เพื่อป้องกันภาวะผลึกยาอุดตันท่อไตเฉียบพลัน (Acyclovir crystal nephropathy) และปรับเพดานขนาดยาสูงสุดต่อครั้งของยาฉีดจาก 800 mg เป็น 1,000 mg
  * **เอกสารอ้างอิง:** *The Sanford Guide to Antimicrobial Therapy 2024; Lexicomp Drug Information 2024; Turner RB et al. Pharmacotherapy. 2016;36(8):904-910.*
  * **เหตุผลทางคลินิก:** ป้องกันภาวะไตวายจากผลึกยาในผู้ป่วยอ้วน เนื่องจากยาละลายในไขมันน้อย ($V_d \approx 0.7\text{ L/kg}$ ของ IBW) พร้อมทั้งเปิดให้ผู้ป่วยได้รับยาในขนาดที่ออกฤทธิ์ฆ่าเชื้อในสมองได้เต็มที่ถึง 1,000 mg โดยไม่เกิดการเตือน Overdose ผิดพลาด
- [ ] **Option B: ใช้น้ำหนักปรับค่า ($AdjBW_{0.4}$) ในผู้ป่วยอ้วน และยกเลิกเพดาน 800 mg**
  * **รายละเอียด:** คำนวณขนาดยาโดยใช้ $AdjBW = IBW + 0.4 \times (TBW - IBW)$ ในผู้ป่วย BMI $\ge 30\text{ kg/m}^2$ และตั้งเพดานยาฉีดสูงสุดที่ 1,000 mg
  * **เอกสารอ้างอิง:** *Pai MP, Nahata MC. Antimicrob Agents Chemother. 2010;54(12):5032-5037.*
  * **เหตุผลทางคลินิก:** ชดเชยการขยายตัวของของเหลวนอกเซลล์ในภาวะอ้วนรุนแรง
- [ ] **Option C: คำนวณตามน้ำหนักจริง (TBW) ไม่จำกัดเพดานตายตัว พร้อมคำเตือนบังคับให้สารน้ำ**
  * **รายละเอียด:** คงการคำนวณตามน้ำหนักจริง 10 mg/kg โดยไม่ตัดเพดานที่ 1,000 mg แต่แสดงคำเตือนทางคลินิกให้สารน้ำทางหลอดเลือดอย่างเพียงพอ ($\ge 100\text{ mL/hr}$)
  * **เอกสารอ้างอิง:** *US FDA Prescribing Information: Zovirax (Acyclovir Sodium for Injection); Goodman & Gilman 14th ed.*
  * **เหตุผลทางคลินิก:** มุ่งเน้นการฆ่าเชื้อไวรัสในสมองอย่างรวดเร็วที่สุดในภาวะวิกฤตที่อาจถึงแก่ชีวิต

**มติคณะกรรมการสำหรับ DEC-PND-001:** `[  ] Option A    [  ] Option B    [  ] Option C`  
**หมายเหตุเพิ่มเติมของโรงพยาบาล:** __________________________________________________

---

```
================================================================================
ประเด็นที่ 2: DEC-PND-002
หัวข้อ: Atropine Pediatric Bradycardia — เพดานขนาดยาต่อครั้ง (0.5 mg) และขนาดยาขั้นต่ำ (0.1 mg)
================================================================================
```
* **สาขาคลินิก:** เวชศาสตร์ฉุกเฉินและการกู้ชีพ (`PendingDecisionCategory.emergencyResuscitation`)
* **ตัวยาที่เกี่ยวข้อง:** `atropine` (Atropine Sulfate Injection)
* **ตำแหน่งโค้ดในระบบ:** `lib/data/drugs/emergency.dart` (lines 88–97)
* **ข้อถกเถียงและปัญหาทางคลินิก (Clinical Dilemma):**
  * *ภาษาไทย:* การรักษาภาวะ Bradycardia ในเด็กตามแนวทาง PALS แนะนำให้ใช้ Atropine 0.02 mg/kg IV/IO ในอดีตเคยมีข้อกำหนดขนาดยาขั้นต่ำ 0.1 mg เพื่อป้องกันภาวะ Paradoxical Bradycardia แต่แนวทาง AHA PALS 2020 ได้ตัดคำแนะนำขนาดยาขั้นต่ำ 0.1 mg ออกเนื่องจากไม่มีหลักฐานเชิงประจักษ์ชัดเจน ขณะที่คงเพดานสูงสุดต่อครั้งไว้ที่ 0.5 mg ในเด็ก (1.0 mg ในวัยรุ่น) ใน Drugph ปัจจุบันกำหนด minSingleDose: 0.1 และ maxSingleDose: 0.5 แต่ยังไม่มีการใส่ doseCap ทำให้เด็กหนัก > 25 kg ติดเตือน Overdose
  * *English:* PALS recommends 0.02 mg/kg IV/IO. Historically, a minimum dose of 0.1 mg was required to avoid paradoxical bradycardia, but AHA PALS 2020 removed the 0.1 mg floor due to lack of evidence, retaining a 0.5 mg child ceiling (1.0 mg adolescent). Drugph currently uses DoseLimit(min: 0.1, max: 0.5) without an explicit doseCap, triggering Overdose for children > 25 kg.
* **พฤติกรรมปัจจุบันในระบบ (Current Baseline):**
  * คำนวณ 0.02 mg/kg IV push; มี `DoseLimit(minSingleDose: 0.1, maxSingleDose: 0.5)`.
  * เด็กน้ำหนัก 30 kg คำนวณได้ 0.6 mg และติดเตือน Overdose `maxSingleDoseExceeded` แทนที่จะตัดยอดที่ 0.5 mg.

#### ทางเลือกทางคลินิก (Candidate Clinical Options) — โปรดทำเครื่องหมายเลือก 1 ข้อ:
- [ ] **Option A: ปรับตามมาตรฐาน AHA PALS 2020: ตั้ง `doseCap: 0.5 mg` และตัดเกณฑ์ขั้นต่ำ 0.1 mg ออก (แนะนำ)**
  * **รายละเอียด:** กำหนด `doseCap: 0.5 mg` สำหรับเด็ก และตัดข้อจำกัด `minSingleDose: 0.1 mg` ออก เพื่อให้ทารกน้ำหนักตัวน้อย (< 5 kg) ได้รับยาตามสัดส่วนน้ำหนักจริง 0.02 mg/kg
  * **เอกสารอ้างอิง:** *AHA PALS Guidelines 2020; Topjian AA et al. Circulation. 2020;142(16_suppl_2):S469-S523.*
  * **เหตุผลทางคลินิก:** ตัดความเสี่ยงที่ทารกแรกเกิดจะได้รับยาเกินขนาดโดยไม่จำเป็น (Relative Overdosing) และจำกัดขนาดยาสูงสุดที่ 0.5 mg ในเด็กโตอย่างถูกต้อง
- [ ] **Option B: แนวทาง APLS (สหราชอาณาจักร): คงเกณฑ์ขั้นต่ำ 0.1 mg และตั้งเพดาน `doseCap: 0.5 mg`**
  * **รายละเอียด:** คงเกณฑ์ขั้นต่ำ 0.1 mg เพื่อป้องกัน paradoxical bradycardia จากการกระตุ้น vagal nucleus และกำหนดเพดาน `doseCap: 0.5 mg`
  * **เอกสารอ้างอิง:** *Advanced Paediatric Life Support (APLS UK) 6th ed.; Resuscitation Council UK (RCUK).*
  * **เหตุผลทางคลินิก:** ป้องกันภาวะหัวใจเต้นช้าลงตามแนวทางเวชปฏิบัติของยุโรป
- [ ] **Option C: จำแนกเพดานตามช่วงอายุ: 0.5 mg (< 12 ปี) และ 1.0 mg (วัยรุ่น $\ge 12$ ปี)**
  * **รายละเอียด:** เพดานไม่เกิน 0.5 mg ในเด็กอายุ < 12 ปี และขยายเป็น 1.0 mg ในเด็กโต/วัยรุ่นอายุ $\ge 12$ ปี (ขนาดยารวมสูงสุดไม่เกิน 3 mg)
  * **เอกสารอ้างอิง:** *Lexicomp Pediatric & Neonatal Dosage Handbook 30th ed. 2024; Nelson Textbook of Pediatrics 21st ed.*
  * **เหตุผลทางคลินิก:** สอดคล้องกับสรีรวิทยาของวัยรุ่นที่มีขนาดร่างกายใกล้เคียงผู้ใหญ่

**มติคณะกรรมการสำหรับ DEC-PND-002:** `[  ] Option A    [  ] Option B    [  ] Option C`  
**หมายเหตุเพิ่มเติมของโรงพยาบาล:** __________________________________________________

---

```
================================================================================
ประเด็นที่ 3: DEC-PND-003
หัวข้อ: Dexamethasone Pediatric Croup — เพดานขนาดยาสูงสุดของสถาบัน (10 mg vs 16 mg)
================================================================================
```
* **สาขาคลินิก:** ระบบทางเดินหายใจและโรคภูมิแพ้ในเด็ก (`PendingDecisionCategory.respiratoryAllergy`)
* **ตัวยาที่เกี่ยวข้อง:** `dexamethasone` (Dexamethasone Oral / Injection)
* **ตำแหน่งโค้ดในระบบ:** `lib/data/drugs/emergency.dart` (lines 212–220)
* **ข้อถกเถียงและปัญหาทางคลินิก (Clinical Dilemma):**
  * *ภาษาไทย:* การใช้ Dexamethasone ในโรคครูป (Croup) ในเด็ก แนะนำขนาดยา 0.6 mg/kg รับประทานหรือฉีดครั้งเดียว ตำราแพทย์และแนวทางปฏิบัติของโรงพยาบาลมีความแตกต่างกันระหว่างเพดานสูงสุด 10 mg (ตามแนวทาง RCH Melbourne, CPS แคนาดา) กับ 16 mg (ตาม Nelson Pediatrics, Lexicomp, UpToDate) ในระบบ Drugph ปัจจุบันตั้งค่า maxSingleDose: 10.0 mg ทำให้เด็กน้ำหนักเกิน 16.7 kg ติดเตือน Overdose โดยยังไม่ได้ตัดยอดขนาดยา (doseCap) ให้คงที่
  * *English:* Dexamethasone for croup is dosed at 0.6 mg/kg single dose. Guidelines vary between a 10 mg maximum (RCH Melbourne, CPS) and a 16 mg maximum (Nelson, Lexicomp, UpToDate). Drugph currently sets maxSingleDose: 10.0 mg, triggering an Overdose Warning for children > 16.7 kg without capping.
* **พฤติกรรมปัจจุบันในระบบ (Current Baseline):**
  * คำนวณ 0.6 mg/kg รับประทานครั้งเดียว; `limits: DoseLimit(maxSingleDose: 10.0)`.
  * เด็กน้ำหนัก 20 kg คำนวณได้ 12.0 mg และแจ้งเตือน Overdose `maxSingleDoseExceeded` แทนที่จะตัดยอดเป็น 10 mg หรือ 16 mg.

#### ทางเลือกทางคลินิก (Candidate Clinical Options) — โปรดทำเครื่องหมายเลือก 1 ข้อ:
- [ ] **Option A: เพดานมาตรฐานสถาบัน 10 mg: กำหนด `doseCap: 10.0 mg` (แนะนำ)**
  * **รายละเอียด:** กำหนด `doseCap: 10.0 mg` และ `maxSingleDose: 10.0 mg` สำหรับโรคครูป ทำให้เด็กที่มีน้ำหนักตัว $\ge 16.7\text{ kg}$ ได้รับยา 10 mg พอดีโดยไม่ขึ้นเตือน Overdose
  * **เอกสารอ้างอิง:** *Royal Children’s Hospital (RCH) Melbourne Guidelines 2023; Canadian Paediatric Society (CPS); Thai Pediatric Respiratory Guidelines.*
  * **เหตุผลทางคลินิก:** งานวิจัยทางคลินิกแบบสุ่มยืนยันว่าขนาดยา 10 mg ให้ประสิทธิภาพการรักษาเทียบเท่าขนาดที่สูงกว่า ช่วยลดการสัมผัสสเตียรอยด์สังเคราะห์เกินความจำเป็น
- [ ] **Option B: เพดานระดับตติยภูมิ 16 mg: กำหนด `doseCap: 16.0 mg` และ `maxSingleDose: 16.0 mg`**
  * **รายละเอียด:** ปรับเพิ่มเพดานสูงสุดเป็น 16.0 mg เพื่อรองรับเด็กโตน้ำหนักถึง 26.7 kg ก่อนตัดยอด
  * **เอกสารอ้างอิง:** *Nelson Textbook of Pediatrics 21st ed.; Lexicomp Pediatric 2024; UpToDate: Management of Croup.*
  * **เหตุผลทางคลินิก:** ยึดตามตำราหลักของสหรัฐอเมริกาที่ระบุว่าขนาดยาถึง 16 mg มีความปลอดภัยและทนต่อยาได้ดีในครูปรุนแรง
- [ ] **Option C: สูตรสองระดับตามความรุนแรง: 0.15 mg/kg (เล็กน้อย) และ 0.6 mg/kg (รุนแรง)**
  * **รายละเอียด:** แยกเป็น 2 สูตรในระบบ: ขนาดต่ำ 0.15 mg/kg (เพดาน 8.0 mg) สำหรับครูปเล็กน้อย และขนาดมาตรฐาน 0.6 mg/kg (เพดาน 10.0 mg) สำหรับครูปรุนแรง
  * **เอกสารอ้างอิง:** *Cochrane Database of Systematic Reviews: Glucocorticoids for croup (Russell KF et al. 2018; CD001955).*
  * **เหตุผลทางคลินิก:** ให้แพทย์เลือกตามระดับคะแนน Westley Croup Score เพื่อลดการใช้ยาในกลุ่มผู้ป่วยนอก

**มติคณะกรรมการสำหรับ DEC-PND-003:** `[  ] Option A    [  ] Option B    [  ] Option C`  
**หมายเหตุเพิ่มเติมของโรงพยาบาล:** __________________________________________________

---

```
================================================================================
ประเด็นที่ 4: DEC-PND-004
หัวข้อ: Epinephrine Pediatric Anaphylaxis — เพดานขนาดยาต่อครั้ง (0.3 mg vs 0.5 mg)
================================================================================
```
* **สาขาคลินิก:** เวชศาสตร์ฉุกเฉินและการกู้ชีพ (`PendingDecisionCategory.emergencyResuscitation`)
* **ตัวยาที่เกี่ยวข้อง:** `epinephrine` (Adrenaline / Epinephrine 1:1,000 Injection)
* **ตำแหน่งโค้ดในระบบ:** `lib/data/drugs/emergency.dart` (lines 30–38)
* **ข้อถกเถียงและปัญหาทางคลินิก (Clinical Dilemma):**
  * *ภาษาไทย:* การฉีด Epinephrine (1:1,000) กล้ามเนื้อต้นขาในภาวะ Anaphylaxis ในเด็ก แนะนำขนาดยา 0.01 mg/kg แนวทางปฏิบัติสากลมีความแตกต่างกันในจุดเปลี่ยนผ่านระหว่างเพดานเด็ก (0.3 mg) กับเพดานผู้ใหญ่ (0.5 mg) โดย WAO และ AAP แนะนำเพดาน 0.3 mg ในเด็กก่อนวัยเจริญพันธุ์ (< 30 kg หรือ < 12 ปี) แต่ EAACI และ Resuscitation Council UK อนุญาตให้ขยายถึง 0.5 mg ในเด็กอายุ $\ge 12$ ปี ในระบบ Drugph ปัจจุบันตั้งค่า maxSingleDose: 0.3 mg โดยไม่มี doseCap ทำให้เด็กหนัก > 30 kg ติดเตือน Overdose
  * *English:* Epinephrine (1:1000 IM) for anaphylaxis is dosed at 0.01 mg/kg. WAO and AAP recommend a 0.3 mg ceiling for prepubertal children (< 30 kg / < 12 years). EAACI and RCUK allow 0.5 mg for children $\ge 12$ years. Drugph currently sets maxSingleDose: 0.3 mg without explicit doseCap, triggering Overdose for children > 30 kg.
* **พฤติกรรมปัจจุบันในระบบ (Current Baseline):**
  * คำนวณ 0.01 mg/kg IM; `limits: DoseLimit(maxSingleDose: 0.3)`.
  * เด็กน้ำหนัก 35 kg คำนวณได้ 0.35 mg และติดเตือน Overdose `maxSingleDoseExceeded` แทนที่จะตัดยอดที่ 0.3 mg หรือ 0.5 mg.

#### ทางเลือกทางคลินิก (Candidate Clinical Options) — โปรดทำเครื่องหมายเลือก 1 ข้อ:
- [ ] **Option A: เพดานเด็ก 0.3 mg: กำหนด `doseCap: 0.3 mg` (แนะนำ)**
  * **รายละเอียด:** กำหนด `doseCap: 0.3 mg` ในสูตร Pediatric Anaphylaxis ทำให้เด็กหนัก > 30 kg ได้รับยาที่ถูกตัดยอดเป็น 0.3 mg โดยไม่ขึ้นเตือน Overdose
  * **เอกสารอ้างอิง:** *World Allergy Organization (WAO) Guidelines 2020; AAP Anaphylaxis Policy; ชมรมโรคภูมิแพ้และภูมิคุ้มกันวิทยาในเด็กแห่งประเทศไทย.*
  * **เหตุผลทางคลินิก:** ป้องกันภาวะหัวใจเต้นเร็วผิดจังหวะหรือความดันโลหิตพุ่งสูงจากยา sympathomimetic เกินขนาดในเด็กเล็ก ขณะที่ยังคงประสิทธิภาพการรักษาชีวิต
- [ ] **Option B: แบ่งเพดานตามเกณฑ์น้ำหนัก: 0.3 mg (< 30 kg) และ 0.5 mg ($\ge 30\text{ kg}$ / วัยรุ่น)**
  * **รายละเอียด:** ไม่เกิน 0.3 mg สำหรับเด็ก < 30 kg และไม่เกิน 0.5 mg สำหรับเด็ก $\ge 30\text{ kg}$ หรือวัยรุ่น (เทียบเท่าเพดานผู้ใหญ่)
  * **เอกสารอ้างอิง:** *European Academy of Allergy and Clinical Immunology (EAACI) Guidelines 2021; RCUK 2021.*
  * **เหตุผลทางคลินิก:** รองรับสรีรวิทยาของเด็กโตและวัยรุ่นที่มีปริมาตรหลอดเลือดใกล้เคียงผู้ใหญ่
- [ ] **Option C: ขนาดยาขั้นบันไดตามอุปกรณ์ฉีดอัตโนมัติ (0.1 / 0.15 / 0.3 / 0.5 mg)**
  * **รายละเอียด:** กำหนดขนาดยาเป็นขั้นบันได: 0.1 mg (7.5-10 kg), 0.15 mg (10-25 kg), 0.3 mg (25-50 kg), 0.5 mg (> 50 kg)
  * **เอกสารอ้างอิง:** *EAACI Guidelines 2021; ASCIA Anaphylaxis Guidelines 2023.*
  * **เหตุผลทางคลินิก:** ป้องกันความผิดพลาดในการดูดยาจากหลอดแก้วในภาวะฉุกเฉินวิกฤต

**มติคณะกรรมการสำหรับ DEC-PND-004:** `[  ] Option A    [  ] Option B    [  ] Option C`  
**หมายเหตุเพิ่มเติมของโรงพยาบาล:** __________________________________________________

---

```
================================================================================
ประเด็นที่ 5: DEC-PND-005
หัวข้อ: Salbutamol Pediatric Nebulizer — การกรองกลุ่มประชากร (< 20 kg) และเพดานขนาดยา (2.5 mg)
================================================================================
```
* **สาขาคลินิก:** ระบบทางเดินหายใจและโรคภูมิแพ้ในเด็ก (`PendingDecisionCategory.respiratoryAllergy`)
* **ตัวยาที่เกี่ยวข้อง:** `salbutamol` (Salbutamol Nebules / Respules)
* **ตำแหน่งโค้ดในระบบ:** `lib/data/drugs/respiratory.dart` (lines 27–39)
* **ข้อถกเถียงและปัญหาทางคลินิก (Clinical Dilemma):**
  * *ภาษาไทย:* สูตรยาพ่น Salbutamol ใน respiratory.dart ระบุข้อบ่งใช้ว่า "Asthma / Wheezing (Pediatric < 20kg)" โดยใช้ขนาด 0.15 mg/kg, minSingleDose: 1.25 mg, maxSingleDose: 2.5 mg แต่ในตัวโค้ดยังไม่มีการใส่ PopulationCriteria(maxWeightKg: 20.0) ทำให้สูตรนี้ถูกเรียกใช้ในผู้ป่วยน้ำหนัก > 20 kg ได้ และจะแจ้งเตือน Overdose ทันที (เช่น 25 kg ได้ 3.75 mg) อีกทั้งยังไม่มีการใส่ doseCap: 2.5 mg
  * *English:* The nebulized salbutamol regimen indicates 'Pediatric < 20kg' (0.15 mg/kg, min 1.25 mg, max 2.5 mg). However, it lacks PopulationCriteria(maxWeightKg: 20.0), allowing calculation for patients > 20 kg and firing Overdose Warnings (e.g. 25 kg -> 3.75 mg). It also lacks explicit doseCap: 2.5 mg.
* **พฤติกรรมปัจจุบันในระบบ (Current Baseline):**
  * คำนวณ 0.15 mg/kg พ่นละออง; `limits: DoseLimit(minSingleDose: 1.25, maxSingleDose: 2.5)`.
  * เด็กน้ำหนัก 25 kg คำนวณได้ 3.75 mg และติดเตือน Overdose `maxSingleDoseExceeded` แทนที่จะตัดยอดเป็น 2.5 mg หรือจำกัดเฉพาะเด็กน้ำหนัก < 20 kg.

#### ทางเลือกทางคลินิก (Candidate Clinical Options) — โปรดทำเครื่องหมายเลือก 1 ข้อ:
- [ ] **Option A: เพิ่ม `PopulationCriteria(maxWeightKg: 20.0)` และกำหนด `doseCap: 2.5 mg` (แนะนำ)**
  * **รายละเอียด:** จำกัดกลุ่มผู้ป่วยด้วย `population: PopulationCriteria(maxWeightKg: 20.0)` และใส่ `doseCap: 2.5 mg` ทำให้เด็กน้ำหนัก 16.7–20 kg ได้รับยาที่ถูกตัดยอดเป็น 2.5 mg พอดี และผู้ป่วยเกิน 20 kg จะต้องใช้สูตรของเด็กโต/ผู้ใหญ่
  * **เอกสารอ้างอิง:** *Global Initiative for Asthma (GINA) 2023; British Thoracic Society (BTS/SIGN) 2023; แนวทางการดูแลรักษาโรคหืดในเด็กแห่งประเทศไทย.*
  * **เหตุผลทางคลินิก:** ทำให้ตัวกรองในระบบสอดคล้องกับข้อความทางคลินิก ป้องกันแพทย์เลือกสูตรผิดในเด็กโต และตัดเพดานขนาดยาในเด็กเล็กอย่างแม่นยำ
- [ ] **Option B: สร้าง 2 สูตรแยกตามน้ำหนักใน respiratory.dart (< 20 kg และ $\ge 20\text{ kg}$)**
  * **รายละเอียด:** แยกเป็น 2 สูตรชัดเจน: (1) เด็ก < 20 kg ขนาด 0.15 mg/kg (เพดาน 2.5 mg) และ (2) เด็ก $\ge 20\text{ kg}$ / ผู้ใหญ่ ขนาดคงที่ 5.0 mg พ่นฝอย (เพดาน 5.0 mg)
  * **เอกสารอ้างอิง:** *NHLBI EPR-3 Asthma Guidelines; Lexicomp Pediatric.*
  * **เหตุผลทางคลินิก:** ครอบคลุมการสั่งยาข้างเตียงสำหรับทุกกลุ่มอายุในหน้าจอเดียว
- [ ] **Option C: ใช้ขนาดยาคงที่ 2.5 mg พ่นละอองสำหรับเด็กอายุ $\ge 1$ ปีทุกคน**
  * **รายละเอียด:** ปรับใช้หลอดยามาตรฐานขนาดยาคงที่ 2.5 mg พ่นสำหรับเด็กทุกคนที่อายุ $\ge 1$ ปี โดยสำรองการคำนวณตามน้ำหนักไว้สำหรับทารก < 1 ปีเท่านั้น
  * **เอกสารอ้างอิง:** *Royal Children’s Hospital (RCH) Melbourne 2023; BNF for Children (BNFC) 2023-2024.*
  * **เหตุผลทางคลินิก:** ลดความผิดพลาดของพยาบาลในการเจือจางหรือแบ่งยาจากหลอด

**มติคณะกรรมการสำหรับ DEC-PND-005:** `[  ] Option A    [  ] Option B    [  ] Option C`  
**หมายเหตุเพิ่มเติมของโรงพยาบาล:** __________________________________________________

---

```
================================================================================
ประเด็นที่ 6: DEC-PND-006
หัวข้อ: Hartford Nomogram Digitization & Vancomycin Vd Models
================================================================================
```
* **สาขาคลินิก:** การตรวจติดตามระดับยาในเลือดและเภสัชจลนศาสตร์ (`PendingDecisionCategory.pharmacokineticsTdm`)
* **ตัวยาที่เกี่ยวข้อง:** `gentamicin`, `tobramycin`, `amikacin`, `vancomycin`
* **ตำแหน่งโค้ดในระบบ:** `lib/core/calculators/tdm_calculator.dart` (lines 546–685) & `lib/ui/tdm_screen.dart` (lines 720–739)
* **ข้อถกเถียงและปัญหาทางคลินิก (Clinical Dilemma):**
  * *ภาษาไทย:* ใน tdm_calculator.dart การประเมิน Hartford Nomogram สำหรับ Aminoglycoside ขนาด 7 mg/kg วันละครั้ง ใช้สมการเส้นตรงโดยประมาณที่ผู้พัฒนาใส่ไว้เบื้องต้น (เส้นแบ่ง q24h/q36h: 9.0 ถึง 2.0 mg/L; q36h/q48h: 11.0 ถึง 4.5 mg/L; ขอบบน q48h: 13.0 ถึง 7.0 mg/L ระหว่าง 6 ถึง 14 ชม.) ซึ่งสมการเส้นตรงนี้ยังไม่ได้รับการตรวจสอบเทียบพิกัดจุดกับกราฟต้นฉบับของ Nicolau et al. 1995 โดยเภสัชกร หน้าจอ UI จึงต้องแสดงแถบเตือนสีส้ม (`Key('tdm_hartford_pending_verification')`) ไว้เสมอ นอกจากนี้ ค่า Vd ของ Vancomycin สำหรับคนอ้วน (0.52 L/kg) และผู้ป่วยวิกฤต ICU (0.85 L/kg) จำเป็นต้องมีหลักฐานทางเภสัชจลนศาสตร์รองรับอย่างชัดเจน
  * *English:* Hartford Nomogram (7 mg/kg) uses linear boundary approximations: q24/q36 (9.0->2.0), q36/q48 (11.0->4.5), q48 upper (13.0->7.0 mg/L) from 6h to 14h. These linear boundaries have not been audited against the original Nicolau 1995 curves by a pharmacist, triggering a persistent warning badge in TdmScreen. Vancomycin Vd models (0.70, 0.52, 0.85 L/kg) also require explicit pharmacokinetic literature grounding.
* **พฤติกรรมปัจจุบันในระบบ (Current Baseline):**
  * คำนวณ Hartford Nomogram 7 mg/kg ด้วยสมการเชิงเส้นตรง $dt = \text{hoursPostDose} - 6.0$; แสดงแถบเตือนสีส้ม `tdm_hartford_pending_verification` ใน UI.
  * Vancomycin Vd ใช้ค่ามาตรฐาน 0.70 L/kg, คนอ้วน 0.52 L/kg, และ ICU 0.85 L/kg.

#### ทางเลือกทางคลินิก (Candidate Clinical Options) — โปรดทำเครื่องหมายเลือก 1 ข้อ:
- [ ] **Option A: รับรองสมการเส้นตรงของ Hartford พร้อมตรวจพิกัดโดยเภสัชกร + บันทึกหลักฐาน Vd มาตรฐาน (แนะนำ)**
  * **รายละเอียด:** ตรวจรับรองความถูกต้องของสมการเส้นตรงเทียบกับกราฟ Nicolau 1995 โดยเภสัชกร พร้อมบันทึกเอกสารอ้างอิงของ Vancomycin Vd 0.52 L/kg (Blouin 1982, Bauer 2008) และ 0.85 L/kg ในภาวะติดเชื้อกระแสเลือด (Revilla 2010, Roberts 2011) โดยคงแถบเตือนไว้จนกว่าจะมีการลงนามสมบูรณ์
  * **เอกสารอ้างอิง:** *Nicolau DP et al. Antimicrob Agents Chemother. 1995;39(3):650-655; Blouin RA et al. 1982; Roberts JA et al. Crit Care Med. 2011.*
  * **เหตุผลทางคลินิก:** รักษาความต่อเนื่องทางคณิตศาสตร์ ไม่กระทบผลการทดสอบเดิม (Zero Regression) พร้อมมีหลักฐานทางเภสัชจลนศาสตร์รองรับครบถ้วน
- [ ] **Option B: แปลงเส้นโค้งด้วยสมการพหุนามความแม่นยำสูงจาก Nicolau 1995 + คำนวณ Vd แบบไดนามิกตาม $AdjBW_{0.4}$**
  * **รายละเอียด:** แทนที่สมการเส้นตรงด้วยสมการ polynomial กำลังสองที่ถอดจากกราฟต้นฉบับ Nicolau 1995 และปรับการคำนวณ Vd ของ Vancomycin ในคนอ้วนเป็น 0.70 L/kg ของ AdjBW 0.4 แบบไดนามิก
  * **เอกสารอ้างอิง:** *Nicolau DP et al. 1995; Rybak MJ et al. Am J Health-Syst Pharm. 2020;77(11):835-864.*
  * **เหตุผลทางคลินิก:** ตัดความคลาดเคลื่อน 0.1–0.3 mg/L บริเวณจุดตัดหัวท้ายของกราฟ
- [ ] **Option C: บังคับตรวจระดับยา 2 จุด (Sawchuk-Zaske) เมื่อตกนอกโซน q24h หรือในผู้ป่วย ICU/อ้วน**
  * **รายละเอียด:** กำหนดให้ต้องเจาะเลือดตรวจ 2 จุดเพื่อคำนวณเภสัชจลนศาสตร์แบบ Sawchuk-Zaske เมื่อผลตกอยู่ในโซน q36h, q48h หรือเกินเกณฑ์ แทนที่จะขยายรอบการให้ยาตามการคาดเดาเพียงอย่างเดียว
  * **เอกสารอ้างอิง:** *The Sanford Guide to Antimicrobial Therapy 2024; Murphy JE. Clinical Pharmacokinetics 6th ed.*
  * **เหตุผลทางคลินิก:** เพิ่มความปลอดภัยสูงสุดในผู้ป่วยที่มีการทำงานของไตเปลี่ยนแปลงอย่างรวดเร็ว

**มติคณะกรรมการสำหรับ DEC-PND-006:** `[  ] Option A    [  ] Option B    [  ] Option C`  
**หมายเหตุเพิ่มเติมของโรงพยาบาล:** __________________________________________________

---

## ส่วนลงนามรับรองนโยบายโรงพยาบาล (Institutional Ratification Sign-Off)

ขอรับรองว่าได้ตรวจสอบรายละเอียดทางคลินิก เอกสารอ้างอิง และตัวเลือกเชิงนโยบายทั้ง 6 ประเด็นข้างต้นอย่างละเอียดถี่ถ้วนแล้ว โดยมีมติให้นำทางเลือกที่ได้ทำเครื่องหมายไว้ไปปรับใช้เป็นนโยบายโรงพยาบาลในระบบคำนวณยา Drugph ประจำสถาบันต่อไป

### 1. เภสัชกรคลินิกผู้ตรวจสอบ (Reviewing Clinical Pharmacist)
* ลายมือชื่อ: ............................................................................................
* ชื่อ-นามสกุล: ............................................................................................
* เลขที่ใบประกอบวิชาชีพเภสัชกรรม (ภ.): ...........................................
* วันที่: ......... / ......... / 256...

### 2. หัวหน้ากลุ่มงานเภสัชกรรม (Director of Pharmacy)
* ลายมือชื่อ: ............................................................................................
* ชื่อ-นามสกุล: ............................................................................................
* เลขที่ใบประกอบวิชาชีพเภสัชกรรม (ภ.): ...........................................
* วันที่: ......... / ......... / 256...

### 3. ประธานคณะกรรมการเภสัชกรรมและการบำบัด / อาจารย์แพทย์ผู้รับผิดชอบ (PTC Chair / Attending Physician)
* ลายมือชื่อ: ............................................................................................
* ชื่อ-นามสกุล: ............................................................................................
* เลขที่ใบประกอบวิชาชีพเวชกรรม (ว.): .............................................
* โรงพยาบาล / สถาบัน: .........................................................................
* วันที่: ......... / ......... / 256...
