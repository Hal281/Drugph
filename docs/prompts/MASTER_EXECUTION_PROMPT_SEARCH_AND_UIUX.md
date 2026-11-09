# MASTER AGENT EXECUTION PROMPT: Drugph Search Engine & Pro Medical UI/UX Overhaul
> **Target Runtime:** Antigravity / Gemini CLI  
> **Target Audience:** Clinical Physicians & Pharmacists (ICU, Inpatient, Outpatient)  
> **Governing Charter:** [AGENTS.md](file:///c:/Users/turbo/drugforPh/AGENTS.md) & [docs/PROJECT_GUIDELINES.md](file:///c:/Users/turbo/drugforPh/docs/PROJECT_GUIDELINES.md)

---

## 🎯 MISSION OBJECTIVE
คุณคือ **Principal Clinical Software Engineer** รับหน้าที่ยกเครื่อง 2 ระบบสำคัญของโปรเจกต์ **Drugph**:
1. **Clinical Drug Search Engine (`lib/data/drug_database.dart`)**: ปรับปรุงจาก Substring Matching ธรรมดา ให้เป็น High-Performance Multi-Dimensional Relevance Search Engine (Relevance Scoring, ค้นหาข้ามมิติ: ชื่อสามัญ/ชื่อการค้า/กลุ่มยา/ข้อบ่งใช้/ภาษาไทย, พร้อม Typo Tolerance)
2. **All-in-One Pro Medical Dashboard UI/UX (`lib/ui/calculator/`)**: ปฏิรูปและ Refactor หน้าจอคำนวณยา (`calculator_screen.dart` ขนาด > 2,000 บรรทัด) ให้แยกเป็น Modular Sub-Widgets ตาม Clean Architecture โดยผสมผสานจุดเด่นของ **MDCalc** (ความโปร่งใสของสูตรคำนวณ + Live Reactive Math) และ **Lexicomp/Sanford Guide** (Indication-Driven Regimen Selector + Renal/Hepatic Badges + Textbook Evidence Drawer) ภายใต้มาตรฐาน 8-Point Grid และ WCAG AAA

---

## ⚠️ 5 IRONCLAD CLINICAL RULES (ต้องปฏิบัติตามอย่างเด็ดขาด)
1. **Zero-Error Calculation Policy:** การคำนวณโดสยา, Weight-based (mg/kg), BSA-based (mg/m²), AUC, CrCl, eGFR, และการปัดเศษ ต้องแม่นยำ 100% ห้ามเกิด Floating-point error
2. **Strict Evidence-Based Medicine:** อ้างอิง 7 ตำราหลัก (Lexicomp, Sanford Guide, KDIGO, Thai Renal Guide, IDAT, Thai FDA, DiPiro) ห้ามกุข้อมูลยาหรือสูตรเอง
3. **Therapeutic Duplication Prevention:** ดักจับ Identical Drug และ Contraindicated Combinations (Dual NSAIDs, Dual RAS blockades, Dual Anticoagulants, Dual Statins)
4. **Drug-Drug Interactions (DDI):** ระบุ Severity, Pharmacological Mechanism และ Clinical Action เสมอ
5. **Non-Blocking Overdose Policy:** **ห้ามบล็อก ห้ามล็อกหน้าจอ และห้ามซ่อน/ลบตัวเลขขนาดยาที่คำนวณได้เด็ดขาด** (แม้จะเกินเกณฑ์ Overdose) แต่ต้องแสดง Alert Banner สีส้ม/แดงเด่นชัดเตือนแพทย์และเภสัชกร

---

## 🧱 PHASE 1: HIGH-PERFORMANCE MULTI-DIMENSIONAL SEARCH ENGINE

### 1.1 ปัญหาปัจจุบันใน `lib/data/drug_database.dart`
* ใช้เพียง `.contains()` และการเช็คตัวอักษรเรียงตัวแบบหยาบ
* ไม่มีคะแนนความตรง (Relevance Scoring) ทำให้คำที่ไม่ตรงมาก่อนคำที่ตรงเป๊ะ
* ค้นหาได้แค่ Generic Name, Brand Name, และ Thai Name ไม่สามารถค้นหาด้วย **ข้อบ่งใช้ (Indications)** หรือ **กลุ่มยา/กลไก (Drug Class/ATC)** ได้
* พิมพ์ตกหล่น 1 ตัวอักษร (Typo) เช่น "amoxicilin" หรือ "ceftriaxon" จะหาไม่เจอ

### 1.2 สถาปัตยกรรมระบบ Search ใหม่ (Target Implementation)
สร้าง Pure Service Class สำหรับ Search หรือปรับปรุง `DrugDatabase.search`:
```text
Score Weights:
├── Exact Generic Name Match: 1000 pts
├── Exact Brand Name Match: 800 pts
├── Generic Name Prefix Match (starts-with): 500 pts
├── Brand Name Prefix Match: 400 pts
├── Thai Name Exact/Prefix: 400 pts
├── Substring in Generic Name: 200 pts
├── Substring in Brand Name: 150 pts
├── Drug Class / Category Match: 100 pts
├── Indication / Clinical Keyword Match: 80 pts
└── Typo / Fuzzy Match (Levenshtein Distance <= 2 สำหรับคำยาว >= 4): 50 pts
```

### 1.3 Requirements ของ Search Engine
* **Pure & Deterministic:** คืนค่า `List<DrugSearchResult>` ที่มีคะแนนและเหตุผลที่ค้นพบ (MatchReason เช่น "Matched generic name", "Matched indication: Sepsis")
* **Thai & English Cross-Matching:** รองรับคำศัพท์ภาษาไทย (เช่น "พารา", "เซฟไตร", "ยาฆ่าเชื้อ")
* **Performance:** มี In-memory Tokenized Index หรือ Pre-computed Search Dictionary เพื่อให้ตอบสนองภายใน < 16ms (60 FPS) บน Mobile
* **UI Features:**
  - Debounce 250ms ใน Search Bar
  - Clear button ('X') สำหรับล้างข้อความทันที
  - Highlight ส่วนของคำที่ตรงกับ Search Query ใน Card
  - Recent Searches (บันทึกประวัติการค้นหาล่าสุด 5 รายการ)

---

## 🎨 PHASE 2: ALL-IN-ONE PRO MEDICAL DASHBOARD UI/UX (MDCalc + Lexicomp)

### 2.1 Refactoring Plan สำหรับ `calculator_screen.dart` (2,072 บรรทัด)
ให้แยกโค้ดออกเป็นโฟลเดอร์ `lib/ui/calculator/` ตามแนวคิด Clean Presentation:
```text
lib/ui/calculator/
├── calculator_screen.dart                 # Orchestrator & State Management (Controller/Notifier)
├── models/
│   └── calculator_ui_state.dart          # Immutable State (Patient, Regimen, Calculations, Warnings)
└── widgets/
    ├── patient_clinical_header.dart       # ข้อมูลผู้ป่วย: TBW, IBW, AdjBW, CrCl/eGFR, Child-Pugh, Renal Mode
    ├── regimen_selector_section.dart      # การเลือก Indication & Regimen (Lexicomp/Sanford style)
    ├── dosing_parameters_form.dart        # ช่องกรอกตัวเลขแบบ Ergonomic Number Pad (48x48 dp)
    ├── clinical_breakdown_section.dart    # MDCalc-style Transparent Math Formula breakdown
    ├── safety_alert_banner.dart           # Non-blocking Overdose & Contraindication Warnings
    └── clinical_action_bar.dart           # ปุ่ม Copy คำสั่งแพทย์, Add to Cart (DDI), และ Open Monograph
```

### 2.2 UI/UX Specification (Impeccable UI/UX Standard)
* **8-Point Spacing Grid:** ใช้ Padding และ Margin เป็น 4, 8, 12, 16, 24, 32 เท่านั้น
* **Color Hierarchy (Semantic Purpose):**
  - Primary / Interactive: `Teal` / `Medical Slate Blue`
  - Success / Safe Range: `Emerald Green` (`#059669`)
  - Caution / Renal-Hepatic Dose Adjustment: `Amber / Warning` (`#D97706`)
  - Critical / Overdose / Contraindication: `Crimson Red` (`#DC2626`) — *ห้ามบล็อกการแสดงผลโดส*
  - Monograph / Evidence: `Indigo` (`#4F46E5`)
* **Responsive Split-View:**
  - Width > 800px (Desktop/Tablet): Split 380px Drug Navigation List ด้านซ้าย + Calculator Dashboard ด้านขวา
  - Mobile: Smooth Single Column พร้อม Sticky Header ข้อมูลไต/น้ำหนักของผู้ป่วย
* **4 Explicit States:**
  1. *Loading:* Skeleton placeholder
  2. *Active Data:* แสดงผลลัพธ์คำนวณแบบ Realtime ทันทีที่มีการกรอกตัวเลข
  3. *Empty:* แนะนำขั้นตอนถัดไป (เช่น "กรุณาเลือก Regimen หรือระบุน้ำหนักผู้ป่วย")
  4. *Error/Warning:* ข้อความช่วยเหลือทางคลินิกที่ชัดเจน พร้อมลิงก์เปิดดูตำรา (Monograph)

---

## 🧪 PHASE 3: VERIFICATION GATES & AUTOMATED TESTING
1. **Search Engine Unit Tests (`test/data/drug_search_test.dart`):**
   - Exact match score > Partial match score
   - ค้นหาด้วย Indication (เช่น "Sepsis", "CAP") ต้องแสดงยาที่เกี่ยวข้อง
   - ค้นหาด้วย Typo (เช่น "ceftriaxon") ต้องยังคงพบ Ceftriaxone
   - ค้นหาด้วยภาษาไทย (เช่น "พาราเซตามอล") ต้องพบ Paracetamol
2. **UI Component & Calculation Tests (`test/ui/calculator_modular_test.dart`):**
   - ตรวจสอบว่า Overdose Warning แสดงผลชัดเจน แต่ `calculatedDose` ยังคงแสดงผลบนหน้าจอ (Rule #5)
   - ตรวจสอบการสลับเปลี่ยน Regimen แล้วค่าพารามิเตอร์อัปเดตแบบ Reactive
   - ตรวจสอบ Touch target ของทุก Button >= 48x48 dp
3. **Static Analysis & Formatting:**
   - รัน `dart analyze` ต้องได้ 0 warnings / 0 errors

---

## 🚀 ANTIGRAVITY EXECUTION PROTOCOL (สำหรับ AI Agent)
รันตามขั้นตอนดังต่อไปนี้:
1. เรียกใช้ Subagent `research` เพื่อสำรวจฟิลด์ข้อมูลใน `lib/data/drugs/*.dart` และ `lib/core/models/drug.dart`
2. สร้างหรือปรับปรุง Search Engine พร้อมเขียน Unit Test ใน `test/data/` และรัน `flutter test` ให้ผ่าน 100%
3. ใช้ Subagent `architect_agent` วางโครงสร้างแตกไฟล์ `lib/ui/calculator/` และ Refactor `calculator_screen.dart` ทีละ Widget
4. ตรวจสอบความสอดคล้องกับ `AGENTS.md` และรัน `flutter test` + `dart analyze` ก่อนสรุปงาน
