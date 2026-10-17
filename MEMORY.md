# MEMORY.md — บันทึกสถานะการพัฒนาระบบ Self-Verification & Traceability (4 Pillars)

> อัปเดตล่าสุด: 2026-10-17 (หลังแก้ไข Bug เชิงลึกทั้ง 8 หมวดหมู่ครบถ้วน)

---

## สถานะรวมของแผนการดำเนินงาน 5 เฟส (Execution Roadmap)

| เฟส | รายละเอียด | สถานะ | ผลการทดสอบ / หมายเหตุ |
| :--- | :--- | :---: | :--- |
| **Phase 1** | วางโครงสร้างไฟล์และออกแบบ JSON Schema ของฐานข้อมูลยา (`drug_knowledge_base.json`) | ✅ **เสร็จสมบูรณ์** | ผ่าน Schema Validation 100% (`v1.2.0`) บังคับตรวจ `verified_by` + `verified_date` และ Canonical NLM RxCUI |
| **Phase 2** | พัฒนา Core Calculation & Safety Engine (Step-by-Step Breakdown, Max Dose, Allergy, DDI) | ✅ **เสร็จสมบูรณ์** | แก้ไขครบทั้ง 8 หมวดหมู่: บังคับเพดาน `mg/kg`, ลดจำนวนมื้อเมื่อชนเพดานรายวัน, ยกเลิก `.contains()`, ปัดเศษ 2 ตำแหน่งสำหรับไซริงค์ 1 mL |
| **Phase 3** | สร้าง Golden Dataset & รัน Automated Unit Tests (`verified_golden` vs `regression_only`) | ✅ **เสร็จสมบูรณ์** | รีเซ็ตทั้ง 15 เคสเป็น `source_verified: false` / `regression_only` จนกว่าจะมีผู้ตรวจลงนาม (`verified_by` + `verified_date`) |
| **Phase 4** | พัฒนาหน้าจอ Evidence-Based Clinical UI (Calculation Breakdown Accordion + Textbook Evidence Modal) | ✅ **เสร็จสมบูรณ์** | เพิ่ม Checkbox ยืนยัน NKDA, แสดงทศนิยมตาม `practicalVolumeDecimalsUsed`, และปรับข้อความแบนเนอร์สีเขียวให้ระบุขอบเขตชัดเจน |
| **Phase 5** | สรุปเอกสาร Traceability Matrix สำหรับพรีเซนต์อาจารย์ ([`TRACEABILITY_MATRIX.md`](file:///c:/Users/turbo/drugforPh/TRACEABILITY_MATRIX.md)) | ✅ **เสร็จสมบูรณ์** | สร้างตารางเชื่อมโยงครบทั้ง 4 เสาหลัก, ยา 3 ตัว, เคสทดสอบ `G-01`–`G-15`, การป้องกันความเสี่ยง 8 หมวดหมู่, และขั้นตอนการลงนามรับรอง |

---

## สรุปการแก้ไข Bug เชิงวิศวกรรมและคลินิกทั้ง 8 หมวดหมู่

1. **Bug 1 — ป้าย `source_verified` ต้องมีหลักฐานผู้ตรวจรับรองจริง (`verified_by` + `verified_date`):**
   - รีเซ็ตทั้ง 15 เคสใน [`test/golden/golden_test_cases.json`](file:///c:/Users/turbo/drugforPh/test/golden/golden_test_cases.json) และยาทั้ง 3 ตัวใน [`assets/data/drug_knowledge_base.json`](file:///c:/Users/turbo/drugforPh/assets/data/drug_knowledge_base.json) เป็น `source_verified: false` (`test_group: "regression_only"`), `verified_by: null`, `verified_date: null`
   - ลบ `interaction_database` ออกจากเคสที่ไม่มี DDI (`interaction_database: null`) และแก้ชื่อตำราของ G-06 ให้ไม่อ้างชื่อสมการแทนตำรา
   - บังคับใน [`SchemaValidator`](file:///c:/Users/turbo/drugforPh/lib/core/validators/schema_validator.dart) และ [`VerificationMetadata.isFullyVerified`](file:///c:/Users/turbo/drugforPh/lib/core/models/verified_drug_schema.dart) ว่าต้องมีทั้ง `source_verified == true`, `verified_by` ไม่ว่าง, และ `verified_date` รูปแบบ `YYYY-MM-DD` จึงจะแสดงป้ายสีเขียวใน UI ได้

2. **Bug 2 — ความสอดคล้องของขนาดยาต่อครั้ง × จำนวนมื้อต่อวัน กับเพดานรายวัน (G-02 & G-14):**
   - ใน [`TransparentDosageCalculator.calculate`](file:///c:/Users/turbo/drugforPh/lib/core/calculators/transparent_dosage_calculator.dart) หาก `finalRecommendedSingleDoseMg * adjustedDosesPerDay > effectiveMaxDailyDoseMg` ระบบจะลดจำนวนมื้อลงด้วยสมการ `floor(effectiveMaxDailyDoseMg / finalRecommendedSingleDoseMg)` ทันที
   - ส่งผลให้ **G-02** (`1,000 mg/ครั้ง`) ลดมื้อจาก `5` เหลือ `4 มื้อ/วัน` (`= 4,000 mg/วัน`) และ **G-14** (`900 mg/ครั้ง`) ลดมื้อจาก `5` เหลือ `4 มื้อ/วัน` (`= 3,600 mg/วัน <= 4,000 mg/วัน`) ไม่เกิดความขัดแย้งระหว่างโดสต่อครั้งกับโดสรวมต่อวันอีกต่อไป

3. **Bug 3 — บังคับตรวจ `min_mg_per_kg_per_dose`, `max_mg_per_kg_per_dose`, `max_daily_dose_mg_per_kg`, และ `customDosesPerDay`:**
   - ตรวจจับกรณีสั่งโดสต่อกิโลกรัมเกินเกณฑ์ตำราในเด็กเล็ก (เช่น เด็ก `5 kg` สั่ง `150 mg/kg` = `750 mg` ซึ่งต่ำกว่าเพดานผู้ใหญ่ `1,000 mg` แต่เกินเพดานเด็ก `15 mg/kg` ถึง 10 เท่า) โดยตัดเพดานแนะนำที่ `weightKg * maxMgPerKgPerDose` (`75 mg`) และออก `overdoseWarning` (`criticalOverdose`) ทันที
   - ออก `subtherapeuticDoseWarning` เมื่อต่ำกว่า `minMgPerKgPerDose` และออก `frequencyExceedsMaxWarning` เมื่อ `customDosesPerDay > maxDosesPerDay`

4. **Bug 4 — แยกสถานะ “ไม่ได้ประเมิน (Not Assessed)” ออกจาก “ปกติ/ปฏิเสธแพ้ยา (NKDA)”:**
   - เพิ่ม [`AllergyAssessmentStatus`](file:///c:/Users/turbo/drugforPh/lib/core/models/transparent_calculation_result.dart) (`notAssessed`, `nkdaConfirmed`, `hasAllergies`) และออกแจ้งเตือนระดับ `SafetyAlertSeverity.info` (`unassessedInputNotice`) เมื่อไม่ได้กรอกอายุ, ไม่ได้กรอกค่าไต, หรือยังไม่ได้ยืนยัน NKDA

5. **Bug 5 — ยกเลิก `.contains()` แบบสองทาง, รองรับชื่อไทย/ชื่อการค้า/คำพิมพ์ผิด, และเตือนเมื่อไม่รู้จักยา:**
   - ใน [`SafetyCheckEngine`](file:///c:/Users/turbo/drugforPh/lib/core/validators/safety_check_engine.dart) ยกเลิกการใช้ `.contains()` ที่ทำให้คำสั้นๆ เช่น `"in"` หรือ `"a"` ชนกับ `"Penicillin"` หรือ `"Warfarin"`
   - ใช้การเทียบคำตรงตัว + พจนานุกรมชื่อพ้องภาษาไทย/ชื่อการค้า (`พาราเซตามอล`, `วาร์ฟาริน`, `Tylenol`, `Brufen`, `Marevan`, `Renitec`, `Keflex`, `Augmentin`) + Levenshtein distance `<= 1` เฉพาะคำภาษาอังกฤษความยาว `>= 6` ตัวอักษร (เช่น `"warfrin"` -> `"warfarin"`)
   - หากกรอกชื่อยาที่ไม่อยู่ในฐานข้อมูลปฏิกิริยาของยานั้น จะออก `unrecognizedMedicationNotice` ทันที และเปลี่ยนข้อความแบนเนอร์สีเขียวใน UI เป็น `"ไม่พบข้อห้ามใช้จากรายการที่ตรวจในฐานข้อมูลของยานี้ N รายการ (ไม่ได้แปลว่าไม่มีปฏิกิริยากับยาอื่นนอกฐานข้อมูล)"`

6. **Bug 6 — ความละเอียดไซริงค์ 1 mL (`0.01 mL` / 2 ตำแหน่ง), เตือนเมื่อปัดเศษคลาดเคลื่อน `> 3%`, และป้องกันปริมาตรจิ๋ว `< 0.05 mL`:**
   - เมื่อ `exactVolumeMl < 1.0 mL` ระบบจะปัดเศษ `practicalVolumeMl` เป็นทศนิยม **2 ตำแหน่ง** (`0.01 mL`) โดยอัตโนมัติให้ตรงกับขีดบอกปริมาตรของกระบอกฉีดยา `1 mL` (เช่น ทารก `0.5 kg` ได้ `0.31 mL` คลาดเคลื่อนเพียง `-0.80%` แทนที่จะเป็น `0.3 mL` ที่คลาดเคลื่อน `-4.0%`)
   - แสดงผลใน UI ตาม `result.practicalVolumeDecimalsUsed` แทนการ hardcode `.toStringAsFixed(1)`
   - ออก `roundingDeviationWarning` เมื่อความคลาดเคลื่อนจากการปัดเศษเกิน `±3.0%` หรือเมื่อปริมาตรน้อยกว่า `0.05 mL`

7. **Bug 7 — จัดกลุ่มเทสต์จุดตัดค่าไตใน KB (Test 3.3) อยู่ในหมวด `regression_only`:**
   - ระบุชัดเจนใน [`test/golden_verification_test.dart`](file:///c:/Users/turbo/drugforPh/test/golden_verification_test.dart) ว่าตัวเลขจุดตัดและตัวคูณใน KB อยู่ระหว่างรอเภสัชกรตรวจรับรองจากตำราจริง

8. **Bug 8 — ปรับปรุง `SchemaValidator`, `findDrug`, และ `InputValidator`:**
   - `VerifiedDrugKnowledgeBase.findDrug` ใช้ exact match เท่านั้น (ป้องกันปัญหายาชื่อพ้อง/LASA)
   - `SchemaValidator` ตรวจสอบรหัส RxNorm (RxCUI) เทียบกับค่ามาตรฐาน NLM RxNorm (`161`, `723`, `5640`, `11289`, `6038`, `6851`, `519`, `3827`, `1191`)
