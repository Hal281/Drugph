# 00_MASTER_CONTEXT.md — Drugph v2 Shared AI Execution Context

> **อ่านไฟล์นี้เป็นอันดับแรกก่อนเริ่มทำงานใน Work Package (`WP-00` ถึง `WP-15`) ทุกครั้ง**  
> **Baseline (commit `87a330f`, วันที่ 2026-11-18):** `flutter test --no-pub` = **1,179 tests passing, 0 failed**

---

## 1. ตำแหน่งของผลิตภัณฑ์ (Product Positioning — Locked in Q1–Q8)

* **Product Identity (Q1):** **Drugph = เครื่องมือคำนวณขนาดยาเด็ก (Pediatric Dosing) และยาฉีดในโรงพยาบาล (Hospital Injectables)** — กรอกน้ำหนัก/สภาวะผู้ป่วยครั้งเดียว แล้วคำนวณตัวเลขพร้อมใช้ทันที (`mg` → `mL` สำหรับไซริงค์/ช้อนยา, จำนวนมื้อต่อวัน, การเจือจางและอัตราหยด IV) ซึ่งเป็นช่องว่างที่ Medscape และ Lexicomp ยังต้องให้ผู้ใช้กดเครื่องคิดเลขต่อเอง
* **Out-of-Scope Handling (Q2):** **ห้ามลบตัวยาเดิมออกจากฐานข้อมูลเด็ดขาด** ให้ใช้ระบบ 3 ระดับ (`DrugTier`: `core` | `extended` | `referenceOnly`)
* **Timeline & Commercial Goal (Q3, Q4):** ไม่มีเส้นตายระยะสั้น พัฒนาระยะยาวเพื่อขายเป็น Startup ให้โรงพยาบาลใช้งานจริง โดยเริ่มจาก Field Trials → Hospital Pilot → Commercial Launch
* **Clinical Verification Constraint (Q5):** ปัจจุบันยังไม่มีเภสัชกรลงนามรับรองตัวเลขอย่างเป็นทางการ ดังนั้นทุกสูตร/ตัวเลขใหม่ต้องมี `citation` และคงสถานะ `PENDING_PHARMACIST_VERIFICATION` จนกว่าจะมีผู้ลงนามใน Phase 4
* **Child-Pugh Handling (Q6):** เป็น **Optional** โดยมีค่าเริ่มต้นเป็น `"Not assessed"` (ไม่ได้ประเมิน) — หากไม่ทราบคะแนน ห้ามปรับลดโดสอัตโนมัติ แต่ต้องแสดงแถบเตือนสีเหลืองพร้อมคำแนะนำจากตำราเสมอ
* **Neonatal Dosing (Q7):** รองรับทารกแรกเกิด `< 28 วัน` (แยกตาม PNA, GA/PMA, น้ำหนัก) ใน Phase 5 หลังจาก Core Pediatric ผ่านการตรวจรับรองแล้ว
* **AI Delivery Structure (Q8):** แผนหลัก + ไฟล์ Prompt แยก 1 ไฟล์ต่อ 1 Work Package ใน `docs/prompts/feedback-v2/`

---

## 2. กฎเหล็กสำหรับ AI ทุกตัวที่รันงาน (Shared Ironclad Rules)

1. **อ่านเอกสารหลักก่อนลงมือ:** ต้องอ่าน [`AGENTS.md`](file:///c:/Users/turbo/drugforPh/AGENTS.md) และ [`docs/feedback/PHARMACIST_FEEDBACK.md`](file:///c:/Users/turbo/drugforPh/docs/feedback/PHARMACIST_FEEDBACK.md) ก่อนแก้ไขโค้ดหรือข้อมูลใด ๆ
2. **ห้ามแต่งตัวเลขทางการแพทย์เองโดยเด็ดขาด (Strict EBM — กฎข้อ 2):** ข้อมูลโดสยา, DDI, ข้อบ่งใช้, ผลข้างเคียง หรือ High-Alert flag ที่เพิ่ม/แก้ไขใหม่ต้องระบุ `citation` (ชื่อตำรา + Edition + หัวข้อ) และติดสถานะ `PENDING_PHARMACIST_VERIFICATION` หากไม่มีตำรายืนยัน ให้ใส่ `TODO(clinical-source)` แล้วหยุดแจ้งผู้ใช้
3. **ห้ามบล็อกหรือซ่อนขนาดยา Overdose (Non-Blocking Overdose Policy — กฎข้อ 5):** แสดงผล `calculatedDose` และ `roundedDose` ให้แพทย์/เภสัชกรเห็นเสมอ พร้อมคำเตือนสีแดง/ส้มเด่นชัด
4. **ห้ามลบตัวยาออก (Q2):** ให้เปลี่ยน `tier` แทนการลบ
5. **Zero-Regression Gate:** ต้องรัน `flutter analyze` และ `flutter test --no-pub` ทั้งก่อนและหลังแก้โค้ด จำนวนเทสต์ที่ผ่านต้อง **ไม่น้อยกว่า 1,179 เคส** (และห้ามแก้ test assertion เดิมเพื่อให้ผ่านโดยไม่มีเหตุผลทางคลินิก)
6. **ผูก Traceability ใน Test:** ทุกการเปลี่ยนแปลงพฤติกรรมต้องมี Unit/Widget test ใหม่ โดยตั้งชื่อ test ให้มี `FB-XX` และ `WP-XX` กำกับชัดเจน
7. **แก้เฉพาะไฟล์ที่ระบุใน WP:** หากจำเป็นต้องแตะไฟล์นอกเหนือขอบเขต WP ให้หยุดและรายงานก่อน
8. **รูปแบบรายงานหลังจบงาน:** ระบุ (1) ไฟล์ที่แก้/สร้าง, (2) เทสต์ที่เพิ่ม, (3) ผล `flutter analyze` และ `flutter test` ก่อน/หลัง, และ (4) รายการ `TODO(clinical-source)` ที่ค้างอยู่

---

## 3. สรุปสถานะ Feedback ทั้ง 23 ประเด็น (`FB-01` ถึง `FB-23`)

> ⚠️ **สำคัญ:** หลายประเด็นถูกแก้ไขแล้วใน commit `81b0b78` และ `6237be5` — **ห้ามทำซ้ำ** ให้ดูตารางนี้ประกอบก่อนลงมือ

| FB-ID | ประเด็นจากเภสัชกร | สถานะก่อนเริ่มแผน | WP ที่รับผิดชอบ |
| :--- | :--- | :---: | :---: |
| **FB-01** | Naloxone ถูกจัดอยู่หมวด "ยาแก้ปวด" | ✅ แก้แล้ว (`DrugCategory.antidote`) | [WP-00](file:///c:/Users/turbo/drugforPh/docs/prompts/feedback-v2/WP-00_baseline_traceability.md) |
| **FB-02** | Amoxicillin เด็ก 10 kg แสดง `500 mg q24h` | ✅ แก้แล้ว + มี guard ช่องว่างเลือกสูตรผู้ใหญ่ | [WP-07](file:///c:/Users/turbo/drugforPh/docs/prompts/feedback-v2/WP-07_pediatric_sweep_audit.md) |
| **FB-03** | ยา 1 ตัวล็อกสูตรเดียว (ไม่แยก Indication) | ✅ โครงสร้างพร้อมแล้ว (`Drug.regimens`) | [WP-09](file:///c:/Users/turbo/drugforPh/docs/prompts/feedback-v2/WP-09_core_indications_side_effects.md) |
| **FB-04** | กรอกข้อมูลผู้ป่วยซ้ำ 2 จุด | ✅ แก้แล้ว (`showDemographicInputs`) | [WP-00](file:///c:/Users/turbo/drugforPh/docs/prompts/feedback-v2/WP-00_baseline_traceability.md) |
| **FB-05** | แสดง Static DDI List หน้ายาตัวเดียว | ✅ ลบออกแล้ว | [WP-00](file:///c:/Users/turbo/drugforPh/docs/prompts/feedback-v2/WP-00_baseline_traceability.md) |
| **FB-06** | การ์ด "แหล่งอ้างอิง (2)" ขวางหน้าคำนวณ | ✅ ย้ายไป AppBar แล้ว | [WP-00](file:///c:/Users/turbo/drugforPh/docs/prompts/feedback-v2/WP-00_baseline_traceability.md) |
| **FB-07** | ยามะเร็ง / Tacrolimus ซับซ้อนเกินสโคป | ✅ Archived แล้ว (`archivedSpecialtyDrugs`) | [WP-08](file:///c:/Users/turbo/drugforPh/docs/prompts/feedback-v2/WP-08_drug_tier_system.md) |
| **FB-08** | ใช้ IBW/AdjBW ในคนอ้วน (Core Engine) | ✅ มี Winter 2012 ใน `RenalCalculator` | [WP-01](file:///c:/Users/turbo/drugforPh/docs/prompts/feedback-v2/WP-01_cg_dosing_weight_fix.md) |
| **FB-09** | `PatientEditDialog` เรียก CG ด้วยน้ำหนักดิบ (`wt`) | 🔴 **Open (Critical Bug)** | [WP-01](file:///c:/Users/turbo/drugforPh/docs/prompts/feedback-v2/WP-01_cg_dosing_weight_fix.md) |
| **FB-10** | แสดงชื่อสูตร `Cockcroft-Gault` & เกณฑ์น้ำหนักคู่ค่า CrCl | 🟠 Partial | [WP-06](file:///c:/Users/turbo/drugforPh/docs/prompts/feedback-v2/WP-06_renal_equation_label.md) |
| **FB-11** | ป้าย High-Alert Drug (`42` ตัว) ไม่ตรงเกณฑ์จริง | 🔴 **Open** | [WP-03](file:///c:/Users/turbo/drugforPh/docs/prompts/feedback-v2/WP-03_high_alert_reclassification.md) |
| **FB-12** | Child-Pugh ปนสถานะ `none` กับ `notAssessed` | 🔴 **Open** | [WP-02](file:///c:/Users/turbo/drugforPh/docs/prompts/feedback-v2/WP-02_child_pugh_not_assessed.md) |
| **FB-13** | คำว่า `"เข็มแรก"` ใน `PharmacistCalculator` | 🔴 **Open** | [WP-04](file:///c:/Users/turbo/drugforPh/docs/prompts/feedback-v2/WP-04_clinical_terminology.md) |
| **FB-14** | Dengue ซ้ำซ้อนระหว่าง Contraindication กับ Special Notes | 🔴 **Open** | [WP-05](file:///c:/Users/turbo/drugforPh/docs/prompts/feedback-v2/WP-05_contraindication_dedup_class_suffix.md) |
| **FB-15** | วงเล็บกลุ่มยาหลังชื่อยา เช่น `Ibuprofen (NSAIDs)` | 🟠 Check / UI | [WP-05](file:///c:/Users/turbo/drugforPh/docs/prompts/feedback-v2/WP-05_contraindication_dedup_class_suffix.md) |
| **FB-16** | ลำดับหน้าจอ: ข้อบ่งใช้บรรทัดแรก + Side Effects ชัดเจน | 🟠 Check / UI | [WP-09](file:///c:/Users/turbo/drugforPh/docs/prompts/feedback-v2/WP-09_core_indications_side_effects.md), [WP-11](file:///c:/Users/turbo/drugforPh/docs/prompts/feedback-v2/WP-11_calculator_hierarchy_ux.md) |
| **FB-17** | IV Compatibility กระชับเป็นชิป `NSS` / `D5W` | 🟠 Partial | [WP-11](file:///c:/Users/turbo/drugforPh/docs/prompts/feedback-v2/WP-11_calculator_hierarchy_ux.md) |
| **FB-18** | DDI ของ Amoxicillin เน้นคู่ยาที่พบบ่อยจริง | 🟠 Open | [WP-10](file:///c:/Users/turbo/drugforPh/docs/prompts/feedback-v2/WP-10_ddi_and_citations.md) |
| **FB-19** | แถบ "ปรับขนาดยาตับ/ไต" กดดูรายละเอียดไม่ได้ | 🟠 Check / UI | [WP-11](file:///c:/Users/turbo/drugforPh/docs/prompts/feedback-v2/WP-11_calculator_hierarchy_ux.md) |
| **FB-20** | อ้างอิง `Drug Information Handbook` (Lexicomp/APhA) | 🟠 Policy | [WP-10](file:///c:/Users/turbo/drugforPh/docs/prompts/feedback-v2/WP-10_ddi_and_citations.md) |
| **FB-21** | ตีกรอบสโคป Core vs Extended / Reference-only | 🟠 Partial | [WP-08](file:///c:/Users/turbo/drugforPh/docs/prompts/feedback-v2/WP-08_drug_tier_system.md) |
| **FB-22** | เติมข้อบ่งใช้ `>= 2-3` โรคต่อยาในกลุ่ม Core | 🔴 **Open** | [WP-09](file:///c:/Users/turbo/drugforPh/docs/prompts/feedback-v2/WP-09_core_indications_side_effects.md) |
| **FB-23** | เตรียมคำตอบอาจารย์/กรรมการ & จุดต่างจาก Medscape | 🔴 **Open** | [WP-12](file:///c:/Users/turbo/drugforPh/docs/prompts/feedback-v2/WP-12_qa_prep_doc.md) |

---

## 4. ลำดับการรันงานและการทำงานขนาน (Execution Order)

```text
Phase 0: [WP-00]
   │
   ▼
Phase 1 (ขนานได้): [WP-01] [WP-02] [WP-04] [WP-05] [WP-06]
   │  (ทำแยกจากกลุ่มขนานเพราะแก้หลายไฟล์ร่วมกัน): [WP-03] ──► [WP-07]
   ▼
Phase 2: [WP-08] ──► [WP-09] ──► [WP-10]
   │
   ▼
Phase 3: [WP-11] & [WP-12] (ขนานได้)
   │
   ▼
Phase 4: [WP-13] (บังคับก่อนทดลองใช้จริงในโรงพยาบาล)
   │
   ├──► Phase 5: [WP-14] Neonatal Module (NICU)
   └──► Phase 6: [WP-15] Startup Readiness & Hospital Sales
```

## 5. เอกสารอ้างอิงสำคัญในโปรเจกต์
* [`AGENTS.md`](file:///c:/Users/turbo/drugforPh/AGENTS.md) — กฎเหล็ก 5 ข้อ
* [`docs/feedback/PHARMACIST_FEEDBACK.md`](file:///c:/Users/turbo/drugforPh/docs/feedback/PHARMACIST_FEEDBACK.md) — บันทึก Feedback ฉบับเต็ม
* [`docs/feedback/FEEDBACK_TRACEABILITY.md`](file:///c:/Users/turbo/drugforPh/docs/feedback/FEEDBACK_TRACEABILITY.md) — ตารางติดตามสถานะ `FB-01`..`FB-23`
* [`docs/06-presentation/QA_PREP.md`](file:///c:/Users/turbo/drugforPh/docs/06-presentation/QA_PREP.md) — คู่มือตอบคำถามอาจารย์และโรงพยาบาล
* [`TRACEABILITY_MATRIX.md`](file:///c:/Users/turbo/drugforPh/TRACEABILITY_MATRIX.md) และ [`DECISIONS.md`](file:///c:/Users/turbo/drugforPh/DECISIONS.md)
