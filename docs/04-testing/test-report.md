# Test Execution & Acceptance Report — Drugph
**Course:** Introduction to Software Engineering (15031001) — Academic Year 2569  
**Milestone:** M4 / Testing Verification  
**Project:** Drugph — Deterministic Clinical Drug Dosage Engine  
**Test Suite:** Automated Flutter Engine Unit Tests & Clinical Scenario Validation  
**Date of Execution:** 04/10/2026 – 05/10/2026  
**Result Summary:** 23 Tests Executed, **23 Passed (100% Success Rate)**  

---

## 1. การทดสอบตามเกณฑ์การยอมรับ (Acceptance Criteria Scenarios)

| รหัสข้อกำหนด | ฉากทดสอบ (Scenario) | สภาวะนำเข้า (Given & When) | ผลลัพธ์ที่คาดหวัง (Expected) | ผลลัพธ์จริง (Actual Result) | สถานะ |
|---|---|---|---|---|---|
| **FR-01** | Cockcroft-Gault (ชาย) | ชาย 60 ปี, Wt 70 kg, SCr 1.2 mg/dL | CrCl = 68.06 mL/min | CrCl = 68.06 mL/min | **✓ PASS** |
| **FR-01** | Cockcroft-Gault (หญิง) | หญิง 60 ปี, Wt 70 kg, SCr 1.2 mg/dL | CrCl = $68.06 \times 0.85 = 57.85$ mL/min | CrCl = 57.85 mL/min | **✓ PASS** |
| **FR-01** | CKD-EPI 2021 (Race-free) | หญิง 65 ปี, SCr 0.8 mg/dL | eGFR = 88.08 mL/min/1.73m² | eGFR = 88.08 mL/min/1.73m² | **✓ PASS** |
| **FR-02** | Devine IBW (ชาย) | ชาย ส่วนสูง 175 ซม. (68.90 นิ้ว) | $\text{IBW} = 50 + 2.3 \times 8.90 = 70.46$ kg | IBW = 70.46 kg | **✓ PASS** |
| **FR-02** | Devine IBW (หญิง) | หญิง ส่วนสูง 165 ซม. (64.96 นิ้ว) | $\text{IBW} = 45.5 + 2.3 \times 4.96 = 56.91$ kg | IBW = 56.91 kg | **✓ PASS** |
| **FR-02** | AdjBW ในคนอ้วน | ส่วนสูง 170 ซม. (IBW 65.94 kg), Wt 120 kg | $\text{AdjBW} = 65.94 + 0.4 \times 54.06 = 87.56$ kg | AdjBW = 87.56 kg | **✓ PASS** |
| **FR-02** | Aminoglycoside Obese Dosing | คำนวณ Gentamicin 5 mg/kg ในคนอ้วน 120 kg | ขนาดยาใช้ AdjBW (437.8 mg) ไม่ใช่ TBW (600 mg) | ขนาดยา = 437.81 mg | **✓ PASS** |
| **FR-03** | ปิดช่องว่างทศนิยม CrCl | Meropenem ที่ CrCl 25.5 mL/min (ก้ำกึ่ง 10–25 กับ 26–50) | ตกเข้าช่วง 26–50 mL/min แนะนำลดขนาดยา | AppliesTo(25.5) = true | **✓ PASS** |
| **FR-04** | Carboplatin Calvert GFR Cap | Calvert formula: Target AUC = 5, GFR = 150 mL/min | GFR ถูก Cap ไว้ที่ 125 mL/min ได้ขนาดยา 750 mg | ขนาดยา = 750.0 mg | **✓ PASS** |
| **FR-04** | Dose Checker (Hard Limit) | คำนวณยาเกินขนาดสูงสุดต่อวัน | เกิดข้อความแจ้งเตือนระดับ Hard Warning สีแดง | Warning.severity = hard | **✓ PASS** |
| **FR-04** | Missing SCr Guard | สั่งยาขับออกทางไตแต่ไม่มีค่า SCr | แสดงคำเตือนสีแดง ห้ามขึ้น Audit Passed | Alert สีแดงแสดงผลถูกต้อง | **✓ PASS** |
| **FR-05** | Vancomycin Steady-State AUC₂₄ | Dose 750 mg q12h, $V_d = 50$ L, $K_e = 0.06\text{ h}^{-1}$ | $\text{AUC}_{24} = 500.0$ mg·h/L (เป้าหมาย 400–600) | $\text{AUC}_{24} = 500.0$ mg·h/L | **✓ PASS** |
| **FR-05** | Vancomycin Supratherapeutic | Dose 1,000 mg q12h, $V_d = 45$ L, $K_e = 0.05\text{ h}^{-1}$ | $\text{AUC}_{24} = 888.89$ mg·h/L (พิษต่อไต) | $\text{AUC}_{24} = 888.89$ mg·h/L | **✓ PASS** |

---

## 2. ผลการรันชุดทดสอบอัตโนมัติ (Automated Flutter Test Output)

ชุดทดสอบทั้งหมดถูกรันผ่านคำสั่ง `flutter test` ในสภาพแวดล้อมจริง:

```text
00:00 +0: loading test/engine_test.dart
00:00 +0: BSA Calculator Tests Mosteller formula
00:00 +1: BSA Calculator Tests DuBois formula
00:00 +2: Renal Calculator Tests Cockcroft-Gault Male
00:00 +3: Renal Calculator Tests Cockcroft-Gault Female
00:00 +4: Renal Calculator Tests CKD-EPI 2021 Female
00:00 +5: Renal Calculator Tests CKD-EPI 2021 Male
00:00 +6: Dose Checker Tests Within limits
00:00 +7: Dose Checker Tests Exceeds hard limit
00:00 +8: Dose Checker Tests Exceeds soft limit
00:00 +9: Weight-Based & Calvert Calculator Tests Devine IBW Male
00:00 +10: Weight-Based & Calvert Calculator Tests Devine IBW Female
00:00 +11: Weight-Based & Calvert Calculator Tests Adjusted Body Weight (AdjBW)
00:00 +12: Weight-Based & Calvert Calculator Tests Calvert Formula for Carboplatin with GFR cap at 125
00:00 +13: Clinical Safety & Boundary Tests CrCl decimal boundary tolerance: 25.5 mL/min matches 26-50 tier without gap
00:00 +14: Clinical Safety & Boundary Tests Vancomycin AUC24 steady-state calculation
00:00 +15: Clinical Safety & Boundary Tests Aminoglycoside dosing weight in obese patient uses AdjBW
00:00 +16: TDM Calculator Tests calculateVd - standard 0.7 L/kg
00:00 +17: TDM Calculator Tests calculateKe - based on normal CrCl
00:00 +18: TDM Calculator Tests calculateKe - anuric patient (CrCl <= 0)
00:00 +19: TDM Calculator Tests calculateHalfLife - valid Ke
00:00 +20: TDM Calculator Tests calculateLoadingDose - standard patient
00:00 +21: TDM Calculator Tests calculateLoadingDose - capped at absolute max (obese patient)
00:00 +22: TDM Calculator Tests predictTrough - steady state calculation
00:00 +23: All tests passed!
```

---

## 3. ผลการตรวจสอบ Static Analysis (Dart Analyze)
- คำสั่ง: `dart analyze`
- ผลลัพธ์: **0 Errors, 0 Warnings** (Clean codebase)
