# เอกสารอ้างอิงและที่มาของข้อมูล (References & Evidence-based Data)

โปรเจกต์ `drugforPh` (Deterministic Drug Dosage Calculator Engine) ได้รวบรวมและใช้สมการคำนวณทางการแพทย์ รวมถึงขนาดยา (Dosage limits) จากแหล่งอ้างอิงมาตรฐานระดับสากล เพื่อให้มั่นใจว่าเป็น Software as a Medical Device (SaMD) ที่มีความปลอดภัยและแม่นยำ

## 1. การประเมินการทำงานของไต (Renal Function Estimation)
- **Cockcroft-Gault Equation (CrCl):**
  - *อ้างอิง:* Cockcroft DW, Gault MH. Prediction of creatinine clearance from serum creatinine. *Nephron*. 1976;16(1):31-41.
- **CKD-EPI 2021 Equation (eGFR - Race-free):**
  - *อ้างอิง:* Inker LA, Eneanya ND, Coresh J, et al. New Creatinine- and Cystatin C–Based Equations to Estimate GFR without Race. *N Engl J Med*. 2021;385:1737-1749.

## 2. การคำนวณพื้นที่ผิวของร่างกาย (Body Surface Area - BSA)
- **Mosteller Formula:**
  - *อ้างอิง:* Mosteller RD. Simplified calculation of body-surface area. *N Engl J Med*. 1987;317(17):1098.
- **DuBois Formula:**
  - *อ้างอิง:* DuBois D, DuBois EF. A formula to estimate the approximate surface area if height and weight be known. *Arch Intern Med*. 1916;17:863-871.

## 3. การติดตามระดับยาในเลือด (Therapeutic Drug Monitoring - TDM)
*ใช้สำหรับคำนวณ Pharmacokinetics ของยา Vancomycin และ Aminoglycosides (One-compartment model)*
- **ASHP/IDSA/PIDS/SIDP Guidelines for Vancomycin:** 
  - *อ้างอิง:* Rybak MJ, Le J, Lodise TP, et al. Therapeutic monitoring of vancomycin for serious methicillin-resistant Staphylococcus aureus infections: A revised consensus guideline and review. *Am J Health-Syst Pharm*. 2020;77(11):835-864.
- **Pharmacokinetic Equations (Vd, Ke, Half-life):** 
  - *อ้างอิง:* Winter ME. *Basic Clinical Pharmacokinetics*. 5th ed. Lippincott Williams & Wilkins; 2009.

## 4. ข้อมูลขนาดยาและข้อควรระวัง (Dosage Limits & Renal Adjustments)
ข้อมูลขนาดยาสูงสุด (Max limits), ขนาดยาตามน้ำหนัก (mg/kg), และการปรับยาตามค่าการทำงานของไต (Renal Dose Adjustments) อ้างอิงจาก:
- **Lexicomp® (UpToDate):** Drug Information Handbook.
- **The Sanford Guide to Antimicrobial Therapy:** สำหรับกลุ่มยาปฏิชีวนะ (Antibiotics) เช่น Meropenem, Cefepime, Ceftriaxone
- **Micromedex®:** สำหรับข้อมูล Drug Interactions และข้อห้ามใช้ (Contraindications)
