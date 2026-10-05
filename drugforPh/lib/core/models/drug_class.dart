/// Drug class classifications for symmetric interaction and allergy matching (D9).
enum DrugClass {
  nsaid(nameEn: 'NSAID', nameTh: 'ยาต้านการอักเสบที่ไม่ใช่สเตียรอยด์ (NSAIDs)'),
  aceInhibitor(nameEn: 'ACE Inhibitor', nameTh: 'ยาลดความดันกลุ่ม ACE inhibitors'),
  arb(nameEn: 'Angiotensin Receptor Blocker', nameTh: 'ยาลดความดันกลุ่ม ARBs'),
  betaLactamPenicillin(nameEn: 'Penicillin', nameTh: 'ยาปฏิชีวนะกลุ่มเพนิซิลลิน'),
  betaLactamCephalosporin(nameEn: 'Cephalosporin', nameTh: 'ยาปฏิชีวนะกลุ่มเซฟาโลสปอริน'),
  betaLactamCarbapenem(nameEn: 'Carbapenem', nameTh: 'ยาปฏิชีวนะกลุ่มคาร์บาพีเนม'),
  aminoglycoside(nameEn: 'Aminoglycoside', nameTh: 'ยาปฏิชีวนะกลุ่มอะมิโนไกลโคไซด์'),
  fluoroquinolone(nameEn: 'Fluoroquinolone', nameTh: 'ยาปฏิชีวนะกลุ่มฟลูออโรควิโนโลน'),
  glycopeptide(nameEn: 'Glycopeptide', nameTh: 'ยาปฏิชีวนะกลุ่มไกลโคเปปไทด์'),
  macrolide(nameEn: 'Macrolide', nameTh: 'ยาปฏิชีวนะกลุ่มแมคโครไลด์'),
  anticoagulantVka(nameEn: 'Vitamin K Antagonist (Warfarin)', nameTh: 'ยาต้านการแข็งตัวของเลือดกลุ่ม VKA'),
  anticoagulantDoac(nameEn: 'Direct Oral Anticoagulant (DOAC)', nameTh: 'ยาต้านการแข็งตัวของเลือดกลุ่ม DOAC'),
  anticoagulantHeparin(nameEn: 'Heparin / LMWH', nameTh: 'ยาเฮพาริน / LMWH'),
  anticonvulsant(nameEn: 'Anticonvulsant', nameTh: 'ยากันชัก'),
  opioid(nameEn: 'Opioid Analgesic', nameTh: 'ยาแก้ปวดกลุ่มโอปิออยด์'),
  statin(nameEn: 'HMG-CoA Reductase Inhibitor (Statin)', nameTh: 'ยาลดไขมันกลุ่มสแตติน'),
  loopDiuretic(nameEn: 'Loop Diuretic', nameTh: 'ยาขับปัสสาวะกลุ่ม Loop'),
  potassiumSparingDiuretic(nameEn: 'Potassium-Sparing Diuretic', nameTh: 'ยาขับปัสสาวะกลุ่มประหยัดโพแทสเซียม'),
  thiazideDiuretic(nameEn: 'Thiazide Diuretic', nameTh: 'ยาขับปัสสาวะกลุ่ม Thiazide'),
  sulfonylurea(nameEn: 'Sulfonylurea', nameTh: 'ยาลดน้ำตาลกลุ่มซัลโฟนิลยูเรีย'),
  biguanide(nameEn: 'Biguanide (Metformin)', nameTh: 'ยาลดน้ำตาลกลุ่มบิ๊กวาไนด์ (Metformin)'),
  sglt2Inhibitor(nameEn: 'SGLT2 Inhibitor', nameTh: 'ยาลดน้ำตาลกลุ่ม SGLT2'),
  dpp4Inhibitor(nameEn: 'DPP-4 Inhibitor', nameTh: 'ยาลดน้ำตาลกลุ่ม DPP-4'),
  glp1Agonist(nameEn: 'GLP-1 Receptor Agonist', nameTh: 'ยากลุ่ม GLP-1 RA'),
  ssri(nameEn: 'SSRI Antidepressant', nameTh: 'ยาต้านเศร้ากลุ่ม SSRI'),
  tca(nameEn: 'Tricyclic Antidepressant', nameTh: 'ยาต้านเศร้ากลุ่ม Tricyclic'),
  atypicalAntipsychotic(nameEn: 'Atypical Antipsychotic', nameTh: 'ยาต้านโรคจิตกลุ่ม Atypical'),
  typicalAntipsychotic(nameEn: 'Typical Antipsychotic', nameTh: 'ยาต้านโรคจิตกลุ่ม Typical'),
  corticosteroid(nameEn: 'Corticosteroid', nameTh: 'ยาสเตียรอยด์'),
  calciumChannelBlocker(nameEn: 'Calcium Channel Blocker', nameTh: 'ยาลดความดันกลุ่ม Calcium Channel Blocker'),
  other(nameEn: 'Other', nameTh: 'อื่นๆ');

  final String nameEn;
  final String nameTh;

  const DrugClass({required this.nameEn, required this.nameTh});
}
