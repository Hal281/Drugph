# WP-15: Startup Readiness — Hospital Customization, PDPA, SaMD Regulatory & Pilot Kit (Phase 6)

## 1. Context & Pharmacist Feedback Reference
* **Covers:** Q3, Q4, Startup Goal (`"จะเอาเป็น startup ขายให้โรงพยาบาล ให้เภสัชและหมอใช้ เริ่มจากทดสอบ ทดลองใช้ แล้วขายจริง"`)
* **Key Feedback Realities:**
  - *"รายการ High-Alert Drug ของแต่ละโรงพยาบาลจะไม่เท่ากัน"*
  - Hospitals stock specific vial/suspension concentrations and specific protocols (e.g., local Heparin nomograms, hospital antimicrobial restriction policies).
  - Selling clinical decision support software to Thai hospitals carries strict legal obligations (**PDPA** and **Thai FDA SaMD — Software as a Medical Device**).

## 2. Goal
Build the multi-hospital configuration layer, zero-PII privacy defaults, incident audit export, Thai FDA SaMD regulatory checklist, and hospital pilot evaluation kit needed to transition safely from student project to hospital startup.

## 3. Exact Files & Line Numbers to Touch
* [NEW] `lib/core/models/hospital_profile.dart` & `assets/data/hospitals/default_hospital_profile.json`
  - Configurable `highAlertOverrides` (connects to WP-03 `HighAlertRegistry`)
  - Configurable `stockedConcentrations` (e.g., Amoxicillin suspension `125 mg/5 mL` vs `250 mg/5 mL` stocked by that hospital)
  - Configurable `protocolUrls` / local antibiotic guidelines (future Heparin nomogram slot)
* [`lib/core/audit/calculation_log.dart`](file:///c:/Users/turbo/drugforPh/lib/core/audit/calculation_log.dart) & [`lib/core/audit/pdf_report_generator.dart`](file:///c:/Users/turbo/drugforPh/lib/core/audit/pdf_report_generator.dart) (add incident-review export & anonymized audit CSV/JSON export)
* [`lib/ui/widgets/patient_edit_dialog.dart`](file:///c:/Users/turbo/drugforPh/lib/ui/widgets/patient_edit_dialog.dart) (enforce **Zero-PII-by-default**: patientName & HN off/anonymous by default, local-only storage disclaimer, quick "Clear Patient Session" button)
* [NEW] `docs/startup/PRIVACY_AND_SAMD_CHECKLIST.md` (PDPA Privacy Notice template + Thai FDA SaMD research action plan)
* [NEW] `docs/startup/HOSPITAL_PILOT_KIT.md` (1-page pitch "Drugph vs Medscape", 5-minute ward demo script, pharmacist UAT evaluation form, target KPIs: time-to-dose reduction & error-catch rate, pricing & PTC committee outreach playbook)
* [NEW] `test/clinical/hospital_profile_config_test.dart`

## 4. Implementation Steps
1. Implement `HospitalProfile` JSON loader allowing a hospital pharmacy department to override:
   - Custom HAD list (`add` / `remove` drugs & routes)
   - Available formulary concentrations (syrup mg/mL, IV vial mg/vial) so `mL` / vial draw calculations always reflect what is actually on that hospital's shelf!
2. Audit `PatientSession` and `HistoryService` (`lib/data/history_service.dart`): ensure zero patient names/HNs are logged remotely or sent to any external server (including `ai_consultant_screen.dart` — enforce PII stripping before any AI prompt!).
3. Draft `PRIVACY_AND_SAMD_CHECKLIST.md` clearly separating what is technical (zero-PII offline architecture, immutable calculation audit log) from what requires formal legal/Thai FDA consultation **before commercial sales**.
4. Draft `HOSPITAL_PILOT_KIT.md` tailored to Thai hospital PTC committees (Pharmacy and Therapeutics Committee).
5. Write unit tests verifying hospital HAD overrides, custom concentration `mL` recalculation, and PII stripping in audit exports.

## 5. Acceptance Criteria
* Switching hospital profile changes available suspension concentrations and HAD badges deterministically.
* Calculation audit logs strip or omit PII when exported in anonymized mode.
* Pilot kit + regulatory checklist are complete and make zero false legal claims.

## 6. Automated Verification Commands
```powershell
cd c:\Users\turbo\drugforPh
flutter analyze
flutter test test/clinical/hospital_profile_config_test.dart
flutter test --no-pub -r compact
```

## 7. Forbidden Actions
* **NEVER** transmit patient name, HN, or identifiable demographics over network endpoints (including Gemini proxy).
* **NEVER** claim Thai FDA SaMD exemption or approval without an actual regulatory determination document.
