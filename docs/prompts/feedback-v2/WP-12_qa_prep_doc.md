# WP-12: Professor & Hospital Defense Q&A Prep (`QA_PREP.md`)

## 1. Context & Pharmacist Feedback Reference
* **Covers:** `FB-23`
* **Pharmacist Feedback:**
  - *"ถ้าพี่เป็นจารย์จะถามว่าต่างกับที่เขาใช้กันอยู่ ปจบ ยังไงบ้าง จุดต่างกับที่มีอยู่แล้ว"*
  - *"3 คำถามหลัก: 1. Child-Pugh ใส่มาทำไม 2. Reference/สูตรอะไร 3. เกณฑ์การปรับยาไต vs ตับ (% ขับทางไต)"*

## 2. Goal
Keep [`docs/06-presentation/QA_PREP.md`](file:///c:/Users/turbo/drugforPh/docs/06-presentation/QA_PREP.md) synchronized with every architectural and clinical improvement landed in Phases 1–3 so all symbol references, drug counts, and equations remain 100% factual and match the codebase.

## 3. Exact Files & Line Numbers to Touch
* [`docs/06-presentation/QA_PREP.md`](file:///c:/Users/turbo/drugforPh/docs/06-presentation/QA_PREP.md)
* Verify cross-references against [`docs/06-presentation/demo-slides.md`](file:///c:/Users/turbo/drugforPh/docs/06-presentation/demo-slides.md) (optional alignment note; only update `QA_PREP.md` unless requested)

## 4. Implementation Steps
1. Review [`QA_PREP.md`](file:///c:/Users/turbo/drugforPh/docs/06-presentation/QA_PREP.md) after `WP-01`..`WP-11` complete.
2. Update any changed file paths, test counts, Core Formulary drug counts, and elimination percentages in Section 1 Q4 using verified textbook citations (never guess % renal excretion).
3. Ensure every claim in `QA_PREP.md` maps to a real file/function/test in the repository.

## 5. Acceptance Criteria
* Every file path, equation, and metric cited in `QA_PREP.md` exists and matches the current `main` branch.
* Answers directly address all 4 professor/pharmacist defense questions + the Phase 1–6 startup roadmap.

## 6. Automated Verification Commands
```powershell
cd c:\Users\turbo\drugforPh
flutter test --no-pub -r compact
```

## 7. Forbidden Actions
* Do NOT include unverified pharmacokinetic numbers without textbook references.
