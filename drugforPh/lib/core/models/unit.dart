// ============================================================
// Drug Dosage Calculator — Unit Definitions
// ============================================================
// All unit enumerations used throughout the calculation engine.
// Type-safe units prevent mixing incompatible measurements.
//
// DISCLAIMER: This is a SaMD prototype. Do NOT use clinically
// without full medical validation and regulatory approval.
// ============================================================

/// Units for expressing drug doses.
///
/// Most drugs use [mg], but some use [mcg] (e.g. Fentanyl),
/// [units] (e.g. Heparin, Insulin), or [mEq] (e.g. KCl).
enum DoseUnit {
  mcg('mcg'),
  mg('mg'),
  g('g'),
  units('units'),
  mEq('mEq'),
  mmol('mmol'),
  mL('mL'),
  application('app'),
  puffs('puffs');

  const DoseUnit(this.symbol);
  final String symbol;

  @override
  String toString() => symbol;
}

/// Mass units with conversion factors to milligrams (base unit).
enum MassUnit {
  mcg('mcg', 0.001),
  mg('mg', 1.0),
  g('g', 1000.0),
  kg('kg', 1000000.0);

  const MassUnit(this.symbol, this.toMgFactor);
  final String symbol;

  /// Multiply a value in this unit by [toMgFactor] to get milligrams.
  final double toMgFactor;

  @override
  String toString() => symbol;
}

/// Volume units with conversion factors to milliliters (base unit).
enum VolumeUnit {
  mL('mL', 1.0),
  L('L', 1000.0);

  const VolumeUnit(this.symbol, this.toMlFactor);
  final String symbol;

  /// Multiply a value in this unit by [toMlFactor] to get milliliters.
  final double toMlFactor;

  @override
  String toString() => symbol;
}

/// Time units with conversion factors to minutes (base unit).
enum TimeUnit {
  minute('min', 1.0),
  hour('hr', 60.0),
  day('day', 1440.0);

  const TimeUnit(this.symbol, this.toMinFactor);
  final String symbol;

  /// Multiply a value in this unit by [toMinFactor] to get minutes.
  final double toMinFactor;

  @override
  String toString() => symbol;
}

/// Route of drug administration.
enum DoseRoute {
  iv('IV', 'Intravenous', 'ฉีดเข้าหลอดเลือดดำ'),
  ivPush('IV Push', 'Intravenous Push', 'ฉีดเข้าหลอดเลือดดำแบบ Push'),
  ivInfusion('IV Inf', 'Intravenous Infusion', 'หยดเข้าหลอดเลือดดำ'),
  im('IM', 'Intramuscular', 'ฉีดเข้ากล้ามเนื้อ'),
  sc('SC', 'Subcutaneous', 'ฉีดใต้ผิวหนัง'),
  po('PO', 'Oral', 'รับประทาน'),
  sl('SL', 'Sublingual', 'อมใต้ลิ้น'),
  pr('PR', 'Rectal', 'ทางทวารหนัก'),
  topical('TOP', 'Topical', 'ทาภายนอก'),
  inhalation('INH', 'Inhalation', 'สูดพ่น'),
  inhaled('INH', 'Inhalation', 'สูดพ่น'),
  intranasal('IN', 'Intranasal', 'พ่นจมูก'),
  intrathecal('IT', 'Intrathecal', 'ฉีดเข้าช่องไขสันหลัง');

  const DoseRoute(this.abbreviation, this.nameEn, this.nameTh);
  final String abbreviation;
  final String nameEn;
  final String nameTh;

  @override
  String toString() => abbreviation;
}

/// How the dose is calculated.
enum DosingType {
  fixed('Fixed Dose', 'ขนาดยาคงที่'),
  weightBased('Weight-Based', 'คำนวณตามน้ำหนักตัว'),
  bsaBased('BSA-Based', 'คำนวณตามพื้นที่ผิวร่างกาย'),
  gfrBased('GFR-Based (Calvert)', 'คำนวณตาม GFR (สูตร Calvert)'),
  renalAdjusted('Renal-Adjusted', 'ปรับตามการทำงานของไต'),
  titrated('Titrated', 'ไตเตรทตามผลการรักษา');

  const DosingType(this.nameEn, this.nameTh);
  final String nameEn;
  final String nameTh;
}

/// Drug therapeutic categories (bilingual).
enum DrugCategory {
  antibiotic('Antibiotics', 'ยาปฏิชีวนะ'),
  antifungal('Antifungals', 'ยาต้านเชื้อรา'),
  antiviral('Antivirals', 'ยาต้านไวรัส'),
  cardiovascular('Cardiovascular', 'ยาหัวใจและหลอดเลือด'),
  vasopressor('Vasopressors/Inotropes', 'ยากระตุ้นหัวใจ'),
  analgesic('Analgesics', 'ยาแก้ปวด'),
  opioid('Opioids', 'ยากลุ่มโอปิออยด์'),
  nsaid('NSAIDs', 'ยาต้านอักเสบไม่ใช่สเตียรอยด์'),
  sedative('Sedatives', 'ยาสงบประสาท'),
  anesthetic('Anesthetics', 'ยาระงับความรู้สึก'),
  anticoagulant('Anticoagulants', 'ยาต้านการแข็งตัวของเลือด'),
  antiplatelet('Antiplatelets', 'ยาต้านเกล็ดเลือด'),
  gastrointestinal('GI Drugs', 'ยาระบบทางเดินอาหาร'),
  antiemetic('Antiemetics', 'ยาแก้คลื่นไส้อาเจียน'),
  corticosteroid('Corticosteroids', 'คอร์ติโคสเตียรอยด์'),
  endocrine('Endocrine', 'ยาระบบต่อมไร้ท่อ'),
  antidiabetic('Antidiabetics', 'ยาเบาหวาน'),
  respiratory('Respiratory', 'ยาระบบทางเดินหายใจ'),
  neurological('Neurological', 'ยาระบบประสาท'),
  anticonvulsant('Anticonvulsants', 'ยากันชัก'),
  psychiatric('Psychiatric', 'ยาจิตเวช'),
  electrolyte('Electrolytes', 'เกลือแร่/สารน้ำ'),
  emergency('Emergency', 'ยาฉุกเฉิน'),
  chemotherapy('Chemotherapy', 'ยาเคมีบำบัด'),
  immunosuppressant('Immunosuppressants', 'ยากดภูมิคุ้มกัน'),
  antihypertensive('Antihypertensives', 'ยาลดความดัน'),
  diuretic('Diuretics', 'ยาขับปัสสาวะ'),
  hematologic('Hematologic', 'ยาโลหิตวิทยา'),
  nephrology('Nephrology', 'ยาโรคไต'),
  obstetric('Obstetric', 'ยาสูติศาสตร์'),
  antidote('Antidotes', 'ยาแก้พิษ'),
  muscle_relaxant('Muscle Relaxants', 'ยาคลายกล้ามเนื้อ'),
  antiInflammatory('Anti-inflammatory', 'ยาลดการอักเสบ'),
  antihistamine('Antihistamines', 'ยาแก้แพ้'),
  supplement('Supplements', 'วิตามิน/เกลือแร่'),
  other('Other', 'อื่นๆ');

  const DrugCategory(this.nameEn, this.nameTh);
  final String nameEn;
  final String nameTh;
}

/// Biological sex — required for Cockcroft-Gault, CKD-EPI, IBW.
enum Sex {
  male('Male', 'ชาย'),
  female('Female', 'หญิง');

  const Sex(this.nameEn, this.nameTh);
  final String nameEn;
  final String nameTh;
}

/// BSA calculation formula choices.
enum BsaFormula {
  mosteller('Mosteller'),
  dubois('DuBois & DuBois'),
  haycock('Haycock (Pediatric)');

  const BsaFormula(this.name);
  final String name;
}

/// Renal function estimation formula choices.
enum RenalFormula {
  cockcroftGault('Cockcroft-Gault (CrCl)'),
  ckdEpi2021('CKD-EPI 2021 (eGFR)');

  const RenalFormula(this.name);
  final String name;
}
