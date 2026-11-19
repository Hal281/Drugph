/// Standardized clinical terminology constants across Drugph.
///
/// Prevents colloquial or injection-biased phrasing when communicating
/// dosing instructions across oral, IV, SC, IM, and inhaled routes.
class ClinicalTerms {
  const ClinicalTerms._();

  static const String firstDoseTh = 'โดสแรก';
  static const String firstDoseEn = 'First dose';

  static const String loadingDoseTh = 'ขนาดยาเริ่มต้น (Loading dose)';
  static const String loadingDoseEn = 'Loading dose';

  static const String firstDoseUnadjustedPrefixTh =
      'ขนาดยาเริ่มต้น/โดสแรก (First/Loading dose) สามารถบริหารได้โดยไม่ต้องปรับ';
  static const String firstDoseUnadjustedPrefixEn =
      'First/loading dose unadjusted is acceptable';

  static const String statFirstDoseAlternativeTh =
      'ให้ยาโดสแรกแบบฉุกเฉิน (STAT First dose): สามารถบริหารยาโดสแรกได้ทันทีในภาวะฉุกเฉินระหว่างรอผลตรวจ SCr ทางห้องปฏิบัติการ';
  static const String akiFirstDoseAlternativeTh =
      'ขอยกเว้นเฉพาะราย: หากรักษาการติดเชื้อรุนแรง สามารถให้ยาโดสแรก (First dose) ได้พร้อมบันทึกเหตุผลทางคลินิก';
}
