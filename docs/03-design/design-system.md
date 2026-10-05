# Design System & UI Tokens — Drugph
**Project:** Drugph — Clinical Assistant & Dosing Engine  
**Milestone:** M3 Design Standard  

---

## 1. ปรัชญาการออกแบบ (Design Philosophy)
ระบบ **Drugph** เป็นซอฟต์แวร์ทางการแพทย์ (Software as a Medical Device - SaMD Prototype) หน้าตาของระบบต้องเน้น **ความชัดเจน อ่านง่ายในทันที (High Legibility & Contrast)** และ **การสื่อสารสถานะความปลอดภัยที่แม่นยำ** ไม่ใช้สีที่ทำให้เกิดความสับสน และต้องมีสถานะแสดงผลที่ชัดเจนทั้งในสภาวะปกติ (Happy Path) และสภาวะอันตราย/ผิดพลาด (Unhappy Path)

---

## 2. Design Tokens กลาง (Shared Design Tokens)

### 2.1 Color Tokens (ชุดสีหลักและสีบอกสถานะ)
| Token Name | Hex Code | ความหมายและการใช้งานทางการแพทย์ |
|---|---|---|
| `--color-primary` | `#0284C7` (Sky Blue 600) | สีหลักของแอป สื่อถึงความสะอาด ความเป็นมืออาชีพทางการแพทย์ ใช้กับแถบบนและปุ่มหลัก |
| `--color-success` | `#16A34A` (Green 600) | ใช้เมื่อผลการตรวจสอบผ่านเกณฑ์ปลอดภัยครบถ้วน ("Audit Passed") |
| `--color-warning` | `#D97706` (Amber 600) | คำเตือนระดับปานกลาง (Soft Limit Exceeded / ควรปรับขนาดยา) |
| `--color-danger` | `#DC2626` (Red 600) | คำเตือนระดับวิกฤต (Hard Limit / ขาดค่า SCr / ยาเกินขนาดยันต์ตาย) |
| `--color-surface` | `#FFFFFF` | พื้นหลังของการ์ดข้อมูลและช่องกรอก |
| `--color-background`| `#F8FAFC` (Slate 50) | พื้นหลังหลักของหน้าจอ ลดแสงสะท้อนถนอมสายตาแพทย์/พยาบาล |
| `--color-text-main` | `#0F172A` (Slate 900) | ข้อความหลัก ตัวเลขผลลัพธ์ขนาดยา (คมชัดสูง) |
| `--color-text-muted`| `#64748B` (Slate 500) | คำอธิบายหน่วย คำแนะนำประกอบ หรือข้อความรอง |

### 2.2 Typography Tokens (ตัวอักษรและขนาด)
- **Font Family:** `Inter`, `-apple-system`, `BlinkMacSystemFont`, `Sarabun`, `sans-serif` (รองรับภาษาไทยและอังกฤษอย่างเป็นระเบียบ)
- `--font-display`: 24px / Bold (ขนาดยาสุทธิที่แนะนำ เช่น `1,000 mg IV q12h`)
- `--font-title`: 18px / Semi-Bold (หัวข้อหมวดหมู่ยา และชื่อผู้ป่วย)
- `--font-body`: 14px / Regular (รายละเอียดและข้อความคำแนะนำ)
- `--font-caption`: 12px / Medium (ป้ายกำกับหน่วย และหลักฐานอ้างอิง)

### 2.3 Spacing & Radius Tokens
- **Spacing Scale:** `4px` (xxs), `8px` (xs), `12px` (sm), `16px` (md), `24px` (lg), `32px` (xl)
- `--radius-card`: `12px` (ขอบมนของการ์ดข้อมูล)
- `--radius-button`: `8px` (ปุ่มกดยืนยัน)
- `--radius-badge`: `9999px` (ป้ายสถานะ Audit Status Pill)

---

## 3. ชิ้นส่วน UI หลัก (Reusable UI Components)

### 3.1 Patient Physiological Banner
- แถบแสดงข้อมูลสรีรวิทยาของผู้ป่วยด้านบนสุดเสมอ ประกอบด้วย: เพศกำเนิด, อายุ (ปี/เดือน), น้ำหนักจริง, ส่วนสูง, Devine IBW, AdjBW, และค่าไต (CrCl & eGFR)

### 3.2 Clinical Audit Badge (ป้ายบอกสถานะการตรวจสอบ)
- **Passed State:** สีเขียว `#16A34A` แสดงไอคอน Checkmark พร้อมข้อความ "Audit Passed — Safe Dose"
- **Soft Warning State:** สีส้ม `#D97706` แสดงไอคอน Alert Triangle พร้อมข้อความเตือนการปรับลดขนาดยา
- **Hard Danger State:** สีแดง `#DC2626` แสดงไอคอน Danger Octagon พร้อมข้อความ "CRITICAL: Dose Exceeds Safety Limit" หรือ "Missing Serum Creatinine"

### 3.3 Error & Empty States (การแสดงผลเมื่อผิดพลาด)
- เมื่อไม่มีการเลือกยา: แสดงหน้าจอว่างเปล่าแบบมีคำแนะนำ "กรุณาเลือกชนิดยาเพื่อเริ่มการคำนวณ" (ไม่แสดงจอเปล่าสีขาว)
- เมื่อไม่ระบุค่า SCr: การ์ดขนาดยาจะแสดงเครื่องหมายตกใจสีแดง เตือนให้ใส่ค่าแล็บก่อนจ่ายยาที่ขับออกทางไต
