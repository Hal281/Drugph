# FEEDBACK_TRACEABILITY.md — ตารางติดตามผลการแก้ไข Feedback เภสัชกร (`FB-01` ถึง `FB-23`)

> **Baseline:** Commit `87a330f` (วันที่ 2026-11-18) | `flutter test --no-pub` = **1,179 tests passed, 0 failed**  
> **แหล่งที่มาของ Feedback:** [`PHARMACIST_FEEDBACK.md`](file:///c:/Users/turbo/drugforPh/docs/feedback/PHARMACIST_FEEDBACK.md)

---

## ตาราง Traceability ครบทั้ง 23 ประเด็น

| FB-ID | ประเด็นจากเภสัชกร | แหล่งที่มา | WP | สถานะ | ไฟล์หลัก / หลักฐาน | Test ที่ครอบคลุม | Commit |
| :--- | :--- | :--- | :---: | :---: | :--- | :--- | :---: |
| **FB-01** | Naloxone อยู่หมวดยาแก้ปวด → ย้ายไป Antidote | เสียง 1 (01:49) | WP-00 | ✅ Done | `lib/data/drugs/emergency.dart:387` (`DrugCategory.antidote`) | `test/drug_list_curation_test.dart` | Pre-`87a330f` |
| **FB-02** | Amoxicillin เด็ก 10 kg แสดง `500 mg q24h` + ป้องกันเลือกสูตรผู้ใหญ่ในเด็ก | เสียง 2 (10:12) | WP-07 | 🔄 Hardening | `lib/ui/calculator/models/calculator_ui_state.dart:75-107`, `lib/data/drugs/antibiotics.dart:1076-1225` | `test/pediatric_dosing_bug_test.dart`, `test/clinical/pediatric_feedback_v2_fixes_test.dart` | `81b0b78` + Pending |
| **FB-03** | ยา 1 ตัวมีหลายขนาดยาตามข้อบ่งใช้ (Indication Selector) | เสียง 2 (07:03) | WP-09 | 🔄 Structure Done / Data Pending | `lib/core/models/drug.dart:459,605,644` (`DosingRegimen`, `RegimenSelectorSection`) | `test/drug_list_curation_test.dart` | `693b7bd`, `81b0b78` |
| **FB-04** | กรอกข้อมูลผู้ป่วยซ้ำซ้อน 2 จุด | เสียง 1 (09:21) | WP-00 | ✅ Done | `lib/ui/calculator/calculator_screen.dart:168-169`, `patient_clinical_header.dart` | `test/ui/patient_profile_layout_test.dart` | Pre-`87a330f` |
| **FB-05** | แสดง Static DDI List เมื่อกดดูยาตัวเดียว | เสียง 1 (04:55) | WP-00 | ✅ Done | `lib/ui/calculator/widgets/clinical_header_alerts.dart`, `lib/ui/prescription_cart_screen.dart` | `test/ui/calculator_references_and_interactions_test.dart` | Pre-`87a330f` |
| **FB-06** | การ์ด `"แหล่งอ้างอิง (2)"` ขวางหน้าคำนวณหลัก | เสียง 2 (14:45) | WP-00 | ✅ Done | `lib/ui/calculator/calculator_screen.dart:123-132` (AppBar button) | `test/ui/calculator_references_and_interactions_test.dart` | Pre-`87a330f` |
| **FB-07** | ยามะเร็ง / Tacrolimus ยากเกินไปสำหรับสโคป | เสียง 1 (00:17) | WP-08 | ✅ Archived (จะย้ายเป็น Tier) | `lib/data/drug_database.dart:33-68` (`archivedSpecialtyDrugs`) | `test/drug_list_curation_test.dart:75-95` | Pre-`87a330f` |
| **FB-08** | ใช้ IBW/AdjBW ในผู้ป่วยอ้วนสำหรับ Cockcroft-Gault | เสียง 2 (01:26) | WP-01 | ✅ Core Engine Done | `lib/core/calculators/renal_calculator.dart:59-143` (Winter 2012) | `test/clinical/pediatric_feedback_v2_fixes_test.dart` | `81b0b78` |
| **FB-09** | `PatientEditDialog._save` เรียก `cockcroftGault` ด้วย `wt` ดิบ | Survey Discovery | WP-01 | ✅ Done (Dialog Fixed; TDM Audit Left) | `lib/ui/widgets/patient_edit_dialog.dart:79-88` (`cockcroftGaultAutoWeight`) | `test/clinical/pediatric_feedback_v2_fixes_test.dart` | Working Tree |
| **FB-10** | ระบุชื่อสมการ Cockcroft-Gault + เกณฑ์น้ำหนัก (TBW/IBW/AdjBW) & Schwartz | แชต 4, เสียง 2 (01:26) | WP-06 | 🔄 Partial (Header Done; CopyNote Pending) | `lib/ui/calculator/widgets/patient_clinical_header.dart:160-210` | `test/ui/patient_profile_layout_test.dart`, `test/clinical/pediatric_feedback_v2_fixes_test.dart` | Working Tree |
| **FB-11** | ป้าย High-Alert Drug (`42` ตัว) ติดกว้างเกินจริง | เสียง 2 (00:10) | WP-03 | ⏳ Planned | `lib/core/models/drug.dart`, `assets/data/high_alert_lists/ismp_acute_care.json` | Planned | — |
| **FB-12** | Child-Pugh ปน `none` (ปกติ) กับ `notAssessed` (ไม่ทราบ) | แชต 3, เสียง 1 (03:10), Q6 | WP-02 | ⏳ Planned | `lib/core/calculators/child_pugh_calculator.dart`, `calculator_controller.dart` | Planned | — |
| **FB-13** | ใช้คำว่า `"เข็มแรก"` แทน `"โดสแรก"` / `Loading Dose` | เสียง 2 (16:10) | WP-04 | ✅ Done (Strings Replaced; Central Constants in WP-04) | `lib/core/calculators/pharmacist_calculator.dart:449,524,540` | `test/clinical/pediatric_feedback_v2_fixes_test.dart` | Working Tree |
| **FB-14** | Dengue fever (suspected) ซ้ำซ้อนใน Contraindication และ Special Notes | เสียง 1 (04:55) | WP-05 | ✅ Done (Ibuprofen & Naproxen) | `lib/data/drugs/analgesics.dart:155-162, 318-325` | `test/clinical/pediatric_feedback_v2_fixes_test.dart` | Working Tree |
| **FB-15** | วงเล็บกลุ่มยาหลังชื่อยา เช่น `Ibuprofen (NSAIDs)` | เสียง 1 (04:55) | WP-05 | ⏳ Planned | `lib/core/models/drug_ontology.dart`, UI drug header | Planned | — |
| **FB-16** | ลำดับหน้าจอ: ข้อบ่งใช้บรรทัดแรก, Therapeutic Dose, Route, Side Effects | เสียง 1, เสียง 2 (14:45) | WP-11 | ⏳ Planned | `lib/ui/calculator/calculator_screen.dart` & child widgets | Planned | — |
| **FB-17** | IV Compatibility สั้นกระชับ (ผสม `D5W` / `NSS` ได้ไหม) | เสียง 2 (16:10) | WP-11 | 🔄 Partial | `lib/core/models/iv_diluent.dart`, `iv_diluent_compatibility_card.dart` | `test/ui/phase3_hepatic_and_diluent_widget_test.dart` | Pre-`87a330f` |
| **FB-18** | DDI ของ Amoxicillin แสดงคู่ยาที่พบบ่อยจริง (เช่น Warfarin) | เสียง 2 (12:11) | WP-10 | ⏳ Planned | `lib/data/drugs/antibiotics.dart` | Planned | — |
| **FB-19** | แถบ "ปรับขนาดยาในผู้ป่วยโรคตับ/ไต" กดดูรายละเอียดไม่ได้ | เสียง 2 (12:11) | WP-11 | ⏳ Planned | `lib/ui/calculator/widgets/*` | Planned | — |
| **FB-20** | อ้างอิง `Drug Information Handbook` (Lexicomp/APhA) แทน OpenFDA ดิบ | เสียง 2 (12:41) | WP-10 | ⏳ Planned | `lib/ui/widgets/clinical_evidence_sheet.dart`, drug provenance | Planned | — |
| **FB-21** | ตีกรอบสโคป: ยาเด็ก + ยาฉีด รพ. (Core vs Extended / Reference-only) | แชต 1, เสียง 1, Q1–Q2 | WP-08 | ⏳ Planned | `lib/core/models/drug.dart`, `lib/ui/home_screen.dart`, `docs/clinical/CORE_FORMULARY_V1.md` | Planned | — |
| **FB-22** | เติมข้อบ่งใช้อย่างน้อย `2-3` โรคต่อตัวยาใน Core Formulary | เสียง 1 (00:17), เสียง 2 | WP-09 | ⏳ Planned | `lib/data/drugs/*.dart` | Planned | — |
| **FB-23** | เตรียมคำตอบ 3–4 คำถามอาจารย์/รพ. & จุดต่างจาก Medscape | แชต 4, เสียง 1 (03:10) | WP-12 | ✅ Created | `docs/06-presentation/QA_PREP.md` | N/A (Docs) | Working Tree |

---

## สรุปผลการทดสอบ Baseline (Pre-Edit)
```text
คำสั่ง: flutter test --no-pub -r compact
วันที่: 2026-11-18 | Commit: 87a330f
ผลลัพธ์: 1,179 tests passed, 0 failed (03:45)
```
