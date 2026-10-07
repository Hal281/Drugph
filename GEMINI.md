# GEMINI.md — Antigravity Project Instructions for Drugph

โปรเจกต์นี้มีกฎเหล็กและแนวทางการพัฒนาที่ถูกกำหนดไว้อย่างเคร่งครัดโดยเจ้าของโปรเจกต์
กรุณาอ่านและปฏิบัติตามคำสั่งใน [AGENTS.md](file:///c:/Users/turbo/drugforPh/AGENTS.md) และ [docs/PROJECT_GUIDELINES.md](file:///c:/Users/turbo/drugforPh/docs/PROJECT_GUIDELINES.md) เสมอ

### สรุปสาระสำคัญที่ต้องปฏิบัติตามทุกครั้ง:
1. **Target Users:** แพทย์และเภสัชกรคลินิก
2. **Zero Errors:** ห้ามคำนวณผิดพลาดเด็ดขาด สูตร ตัวเลข การแปลงหน่วยต้องถูกต้อง 100%
3. **Strict Evidence:** อ้างอิงตำราแพทย์/เภสัชกรรมระดับสากลเท่านั้น (Lexicomp, Sanford Guide, Goodman & Gilman, WHO, US FDA) ห้ามกุข้อมูล
4. **Therapeutic Duplication:** ห้ามจ่ายยาซ้ำซ้อน ทั้งตัวยาเดิมและยาในกลุ่มเดียวกันที่เป็นข้อห้ามใช้ทางการแพทย์ (Dual NSAIDs, Dual RAS blockade, Dual anticoagulants, Dual statins)
5. **Non-Blocking Overdose Policy:** อนุญาตให้คำนวณ Overdose ได้เพื่อช่วยคนไข้ในภาวะฉุกเฉิน ห้ามบล็อกหรือซ่อนตัวเลขโดสยา แต่ต้องแสดงคำเตือนสีแดงเด่นชัดเสมอ
