# QA_PREP.md — คู่มือตอบคำถามกรรมการ / อาจารย์ / คณะกรรมการยาโรงพยาบาล (PTC) & แผนพัฒนาต่อยอดสู่ Startup

> **วัตถุประสงค์:** ใช้เตรียมตอบคำถามเชิงคลินิก-วิศวกรรมในการสอบโปรเจกต์และการนำเสนอ Pilot กับโรงพยาบาล โดยอ้างอิงจากโค้ดและเทสต์จริงใน **Drugph**

---

## ส่วนที่ 1: คำถามหลักที่อาจารย์และเภสัชกรจะถามแน่นอน (4 ข้อ)

### Q1: "แอปนี้ต่างจาก Medscape / Lexicomp ที่เภสัชกรและหมอใช้อยู่ปัจจุบันอย่างไร?"

**คำตอบสรุป 1 ประโยค:**  
> *"Medscape เป็น **ตำราอ้างอิงแบบ Static** ที่บอกแค่สูตร `mg/kg/day` แล้วปล่อยให้หมอ/เภสัชกรไปกดเครื่องคิดเลขแบ่งมื้อและแปลงเป็น `mL` เอง — ส่วน **Drugph เป็น Deterministic Clinical Dosage Engine** ที่กรอกข้อมูลผู้ป่วยครั้งเดียวแล้วคำนวณโดสพร้อมจ่าย (`mg` + `mL` + ความถี่ + อัตราหยด IV + การปรับไต/ตับ + Overdose Safety) ออกมาให้ทันทีแบบ **Zero Manual Math**"*

| มิติการเปรียบเทียบ | Medscape / ตำราทั่วไป | **Drugph** |
| :--- | :--- | :--- |
| **ขนาดยาเด็ก (`mg/kg/day`)** | แสดงข้อความสูตร เช่น `45–90 mg/kg/day divided q8–12h` ต้องกดเครื่องคิดเลขเอง | รับน้ำหนัก → หารจำนวนมื้อ + ปัดเศษ + แปลงเป็น **`mL` / ช้อนยา** ตามความเข้มข้นขวดยาจริง (`0.01 mL` สำหรับไซริงค์ `1 mL`) |
| **ความเสี่ยงคำนวณพลาดใต้ความเร่งด่วน** | ผู้ใช้มีโอกาสสลับ `mg/kg/dose` กับ `/day` หรือลืมหารมื้อ | บังคับแยก `DoseBasis.perDose` vs `DoseBasis.perDay` ในระดับ Type System พร้อม Automated Regression Sweep (`test/pediatric_dosing_bug_test.dart`) |
| **ค่าไต & น้ำหนักคนอ้วน** | ต้องเปิดอีกหน้าเพื่อคำนวณ `Cockcroft-Gault` และ `IBW/AdjBW` แยกกัน | เลือก `TBW / IBW / AdjBW` อัตโนมัติ (Winter 2012) สำหรับผู้ใหญ่ หรือ `Bedside Schwartz` สำหรับเด็ก `1–17 ปี` และเตือนจุดตัดค่าไตแบบไร้รอยต่อ |
| **ความพร้อมใช้งานหน้างาน รพ.** | ภาษาอังกฤษล้วน, ต้องต่อเน็ตบางฟีเจอร์, ไม่เชื่อมกับ Dosing Cart ของคนไข้ | **Offline-first**, ภาษาไทย–อังกฤษ, จัด Tier ยา 3 ระดับ (**34 Core / 85 Extended / 4 ReferenceOnly = 123 ตัว**), คัดกรอง High-Alert ตาม **ISMP 2024 (Route-aware) + แยกป้าย `NTI / TDM` 11 ตัว**, จัดลำดับ DDI ตามความถี่ในเวชปฏิบัติ, และแสดง Breakdown ทุกบรรทัด |
| **นโยบาย Overdose ฉุกเฉิน** | ไม่คำนวณให้ จึงไม่เตือนแบบ Real-time ตามน้ำหนักผู้ป่วย | **Non-Blocking Overdose Policy** (กฎข้อ 5): แสดงตัวเลขที่คำนวณได้เสมอเพื่อช่วยชีวิตฉุกเฉิน แต่ขึ้นแถบเตือนวิกฤตสีแดงเด่นชัด |

---

### Q2: "`Child-Pugh Score` ใส่มาทำไม? และทำไมหน้างานจริงถึงตั้งค่าเริ่มต้นเป็น Optional / Not Assessed?"

1. **ใส่มาทำไม:** ยาหลายตัวในระบบถูกขับออกหรือเปลี่ยนแปลงสภาพที่ตับ (Hepatic Metabolism) เป็นหลัก เช่น `Morphine`, `Fentanyl`, `Amiodarone`, `Diazepam`, `Phenytoin`, `Valproic Acid`, `Metronidazole`, `Azithromycin`, `Warfarin` ในผู้ป่วยตับแข็งระดับ **Child-Pugh Class B/C** ยาเหล่านี้เสี่ยงสะสมจนเกิดพิษ (เช่น Encephalopathy หรือ Bleeding) จึงต้องมีเครื่องมือคำนวณ `Child-Pugh` จากผลแล็บ (Total Bilirubin, Albumin, INR) และอาการทางคลินิก (Ascites, Hepatic Encephalopathy) รองรับ
2. **ข้อจำกัดหน้างานจริงจาก Feedback เภสัชกร:** ในหอผู้ป่วย แพทย์มักไม่ได้เขียนค่า Child-Pugh Score ลงในแฟ้มหรือใบสั่งยา เภสัชกรจึงไม่มีข้อมูลนี้ในมือแม้จะรู้ว่าผู้ป่วยเป็นโรคตับ
3. **การออกแบบของ Drugph (Q6 & WP-02):** จึงตั้งค่าเริ่มต้นเป็น **`Not assessed (ไม่ได้ประเมิน)`** โดยแยกออกจากสถานะ `ปกติ (Normal)` อย่างชัดเจน:
   * หากไม่ทราบคะแนน $\rightarrow$ **ไม่ลดขนาดยาอัตโนมัติ** (ป้องกันการจ่ายยาต่ำกว่าขนาดรักษา / Subtherapeutic) แต่จะ **แสดงแถบเตือนสีเหลืองพร้อมคำแนะนำจากตำรา** สำหรับยาที่มี `requiresHepaticCaution == true`
   * หากแพทย์หรือเภสัชกรมีผลตรวจครบ $\rightarrow$ สามารถเปิด `ChildPughCalculatorSheet` คำนวณคะแนน `5–15` และปรับโดสตาม Class A/B/C ได้ทันที

---

### Q3: "สูตรคำนวณใช้อะไรเป็น Reference และน่าเชื่อถือแค่ไหน?"

ทุกสูตรในระบบเป็น **Pure Deterministic Functions** (`lib/core/calculators/`) ที่อ้างอิงจากสมการมาตรฐานทางการแพทย์ระดับสากลและมี Automated Unit/Widget Tests กว่า 1,220+ เคส (ผ่าน Sweep Test ยาเด็ก 39 สูตร = 263 การคำนวณ):

| สูตร / เกณฑ์การคำนวณ | แหล่งอ้างอิงมาตรฐาน (Primary Citation) | ตำแหน่งในโค้ด |
| :--- | :--- | :--- |
| **Creatinine Clearance (ผู้ใหญ่ $\ge 18$ ปี)** | Cockcroft DW, Gault MH. *Nephron*. 1976;16(1):31–41 | `RenalCalculator.cockcroftGault` (`lib/core/calculators/renal_calculator.dart`) |
| **Dosing Weight Selection ใน Cockcroft-Gault (TBW/IBW/AdjBW)** | Winter MA, Guhr KN, Berg GM. *Pharmacotherapy*. 2012;32(7):604–612 (ใช้ TBW หากต่ำกว่า IBW, ใช้ IBW หากปกติ, ใช้ AdjBW factor `0.4` หาก TBW $\ge 120\%$ IBW) | `RenalCalculator.selectCockcroftGaultWeight` (`renal_calculator.dart:59-121`) |
| **Ideal Body Weight (IBW)** | Devine BJ. *Drug Intell Clin Pharm*. 1974;8:650–655 | `WeightBasedCalculator` (`lib/core/calculators/weight_based_calculator.dart`) |
| **Pediatric eGFR (เด็ก $1–17$ ปี)** | Schwartz GJ et al. *J Am Soc Nephrol*. 2009;20(3):629–637 (`0.413 × Height_cm / SCr`) | `RenalCalculator.bedsideSchwartz` (`renal_calculator.dart:195`) |
| **Body Surface Area (BSA)** | Mosteller RD. *N Engl J Med*. 1987;317(17):1098 | `BsaCalculator` (`lib/core/calculators/bsa_calculator.dart`) |
| **ข้อมูลยา, ขนาดยา, DDI, IV Compatibility** | *Drug Information Handbook* (Lexicomp / APhA), The Sanford Guide 2024, ISMP Acute Care 2024, คู่มือปรับยาโรคไตสมาคมโรคไตไทย, แนวทาง IDAT, บัญชียาหลักแห่งชาติ (RDU), คู่มือยาฉีดรามาธิบดี/ศิริราช, DiPiro | `ClinicalCitationFormatter`, `ClinicalEvidenceSheet`, [`REFERENCES.md`](file:///c:/Users/turbo/drugforPh/REFERENCES.md) |

*(หมายเหตุความโปร่งใสทางคลินิก: ในส่วนข้อมูลยาและ Golden Test Cases ระบบมีการแยกระดับ [`VerificationMetadata.isFullyVerified`](file:///c:/Users/turbo/drugforPh/lib/core/models/verified_drug_schema.dart) ชัดเจน หากยังไม่มีเภสัชกรลงนามรับรองจะแสดงสถานะ `PENDING_HUMAN_VERIFICATION` ไม่แอบอ้างว่าผ่านการรับรองแล้ว)*

---

### Q4: "เกณฑ์การเลือกปรับยาตามค่าไต vs ค่าตับ (Renal vs Hepatic Elimination %)"

ในทางเภสัชจลนศาสตร์ (Pharmacokinetics) ระบบพิจารณาจาก **สัดส่วนการกำจัดยาหลัก (Primary Elimination Pathway)**:
* **ยาที่ขับออกทางไตในรูปเดิม (Unchanged Renal Excretion) สูง หรือมี Active Metabolite ขับทางไต** $\rightarrow$ ต้องตั้ง `requiresRenalAdjustment: true` และใช้ **Cockcroft-Gault / Bedside Schwartz**
* **ยาที่ถูก Metabolize ที่ตับเป็นหลัก (Hepatic Extraction / CYP450 / Glucuronidation)** $\rightarrow$ ต้องตั้ง `requiresHepaticCaution: true` และแสดงคำแนะนำ **Child-Pugh** (ไม่ต้องลดโดสตาม CrCl เว้นแต่มีผลทางอ้อม)

| ตัวยาตัวอย่าง | เส้นทางกำจัดยาหลัก | Renal / Hepatic Flag ในระบบ | เหตุผลทางคลินิก |
| :--- | :--- | :--- | :--- |
| **Vancomycin, Gentamicin, Amikacin** | **ไต (> 80–90% unchanged)** | Renal (`true`) / Hepatic (`false`) | ขับทางไตเกือบทั้งหมด ยาพอกพูนง่าย เกิด Nephrotoxicity / Ototoxicity |
| **Amoxicillin, Cephalexin, Cefazolin** | **ไต (60–90% unchanged)** | Renal (`true`) / Hepatic (`false`) | ต้องขยายช่วงเวลาให้ยา (Interval extension) เมื่อ CrCl ลดลง |
| **Acyclovir (IV/PO), Levetiracetam** | **ไต (~60–80%)** | Renal (`true`) / Hepatic (`false`) | Acyclovir เสี่ยงตกผลึกในท่อไตและ Neurotoxicity หากไม่ลดตาม CrCl |
| **Morphine** | **ตับ (Glucuronidation) + ไตขับ Active Metabolite (M3G/M6G)** | Renal (`true`) / Hepatic (`true`) | ตับเสีย $\rightarrow$ ลด Metabolism; ไตเสีย $\rightarrow$ M6G คั่ง กดการหายใจนาน |
| **Fentanyl, Amiodarone, Diazepam** | **ตับเป็นหลัก (CYP3A4 / Hepatic metabolism)** | Hepatic (`true`) | ขับทางไตในรูปเดิมน้อยมาก (< 10%) จึงต้องระวังในตับแข็งมากกว่าไตเสื่อม |
| **Ceftriaxone** | **ไต (~33–67%) + น้ำดี/ตับ (Dual elimination)** | Hepatic (`true`) (ระวังเมื่อตับ+ไตเสียคู่) | ขับออกได้ทั้งสองทาง ปกติไม่ต้องปรับในไตเสื่อมเดี่ยว ๆ แต่ต้องจำกัดโดสเมื่อตับและไตเสื่อมร่วมกัน |
| **Paracetamol** | **ตับ (Glucuronidation/Sulfation/CYP2E1)** | Hepatic (`true`) | ผู้ป่วยโรคตับเรื้อรังต้องจำกัดขนาดสูงสุดต่อวัน (เช่น $\le 2\text{ g/day}$) เพื่อลดเสี่ยงตับวาย |

*(หมายเหตุ: ตัวเลข % ข้างต้นใช้ประกอบการอธิบายหลักการทางเภสัชจลนศาสตร์ในห้องสอบ สำหรับค่าตัวเลขปรับโดสจริงในแอปต้องอ้างอิงและลงนามจากตำราใน Phase 4)*

---

## ส่วนที่ 2: แผนพัฒนาแอป Drugph ต่อยอดสู่การใช้งานจริงและ Startup ขายโรงพยาบาล

| Phase | เป้าหมายหลัก | งานสำคัญ | เกณฑ์ผ่านก่อนขยับเฟสถัดไป (Gate) |
| :---: | :--- | :--- | :--- |
| **Phase 1** *(✅ Done)* | **Clinical Correctness** | ปิด Bug เปิดค้าง: CG Auto-Weight (`PatientEditDialog`/`PkSimulationController`), แยก Child-Pugh `notAssessed` (`WP-02`), คัดกรอง High-Alert ตาม **ISMP 2024 Route-aware + `NTI / TDM` badge** (`WP-03`), แก้ศัพท์ `ClinicalTerms` `"โดสแรก"` (`WP-04`), ป้ายกลุ่มยา (`WP-05`), แสดงชื่อสมการ+เกณฑ์น้ำหนัก+เตือน `< 1 yr` (`WP-06`), และ Sweep Test ยาเด็ก (`DEC-PED-AUDIENCE-001`, `WP-07`) | `flutter analyze` = 0 issues, Full Suite ผ่าน 100% (`1,208+` tests), Pediatric Sweep (39 regimens / 263 cases) ผ่าน |
| **Phase 2** *(✅ Done)* | **Scope Tiering, Core Data & DDI/Citation** | แบ่ง `DrugTier` (`34 Core / 85 Extended / 4 ReferenceOnly` รวม 123 ตัว, `WP-08`), เติม $\ge 2$ ข้อบ่งใช้ + Common/Serious Side Effects ครบ 34 Core drugs (`WP-09`), จัดอันดับ DDI ตามความถี่ (`Amoxicillin + Warfarin` ก่อน `Methotrexate`) + อ้างอิง **Drug Information Handbook (Lexicomp / APhA)** (`WP-10`) | Core Formulary V1 ครบทั้ง 34 ตัว, `flutter test` (`1,220` tests ณ Commit `520073a`) ผ่าน 100%, ติดสถานะรอเภสัชกรตรวจ |
| **Phase 3** *(✅ Done)* | **Minimalist UX & Defense Prep** | จัดลำดับหน้าคำนวณให้เห็น **ข้อบ่งใช้ $\rightarrow$ Therapeutic Dose (`mg/mL`) $\rightarrow$ Side Effects (Common/Serious) $\rightarrow$ Compact IV Chips $\rightarrow$ Alerts**; แถบปรับไต/ตับกดเปิด `ClinicalEvidenceSheet` ได้ทันที (`WP-11`); ซิงค์ `QA_PREP.md` และ `FEEDBACK_TRACEABILITY.md` (`WP-12`) | `calculator_hierarchy_ux_test.dart` ผ่านทั้ง Mobile (`390x844`, `320x480`) & Desktop (`1280x900`), Full Gate ผ่าน 100% |
| **Phase 4** | **Clinical Advisor & Sign-off Pipeline** | สรรหาเภสัชกรคลินิก + กุมารแพทย์อย่างน้อยอย่างละ 1 ท่าน, ปรับ `generate_pharmacist_dossier_pdf.dart` ให้ออกเป็นชุดละ 5 ตัว, สร้าง `verification_ledger.json` เชื่อมกับ Badge สีเขียว | **$\ge 80\%$ ของ Core Drugs มีผู้ลงนามรับรอง (`verified_by` + เลขใบประกอบฯ)** ก่อนเข้า Pilot |
| **Phase 5** | **Neonatal Module (NICU Wedge)** | พัฒนาระบบตารางโดสทารกแรกเกิด (`< 28 วัน`: PNA + GA/PMA + Birth Weight) ซึ่งเป็น Pain Point ใหญ่ที่สุดของ Medscape และเป็นจุดขายสำคัญให้ห้องเด็ก/NICU | เภสัชกร/กุมารแพทย์ทารกแรกเกิดลงนามรับรองครบทุก Band |
| **Phase 6** | **Startup & Hospital Sales Readiness** | รองรับ Config เฉพาะโรงพยาบาล (Formulary ความเข้มข้นที่มีจริงใน รพ. + บัญชี High-Alert ประจำ รพ.), PDPA Zero-PII-by-default, ตรวจสอบสถานะ **SaMD (อย. เครื่องมือแพทย์)**, และชุด Pilot Kit + KPI (ลดเวลาคำนวณ / ดักจับ Error) | ผ่านเกณฑ์กฎหมาย อย./PDPA และสรุปผล Field Trial จากโรงพยาบาลนำร่อง |
