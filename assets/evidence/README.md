# Textbook Evidence Image Assets (`assets/evidence/`)

โฟลเดอร์นี้สำหรับจัดเก็บรูปภาพแคปหน้าหนังสือตำราแพทย์/เภสัชกรรม (`.png`) ที่อ้างอิงใน `verification_metadata.evidence_image_path` ของไฟล์ `assets/data/drug_knowledge_base.json`

## รายชื่อไฟล์อ้างอิงสำหรับยาต้นแบบ
- `paracetamol_harriet_lane_p912.png` — The Harriet Lane Handbook, 23rd Edition, Page 912-913
- `amoxicillin_sanford_2024_p218.png` — The Sanford Guide to Antimicrobial Therapy, 54th Edition, Page 218
- `ibuprofen_harriet_lane_p815.png` — The Harriet Lane Handbook, 23rd Edition, Page 815

> **หมายเหตุทางวิศวกรรม (Graceful Fallback Policy):**
> ในกรณีที่ยังไม่ได้นำไฟล์ภาพจริง (`.png`) มาวางในโฟลเดอร์นี้ ระบบและ UI (`errorBuilder` / `KnowledgeBaseLoader`) จะแสดง **"หน้าจำลองเอกสารอ้างอิงจากตำรา (Simulated Textbook Reference Card)"** พร้อมชื่อหนังสือ, Edition, เลขหน้า, และลิงก์ฐานข้อมูล DailyMed แทนโดยอัตโนมัติ เพื่อป้องกันแอปแครช 100%
