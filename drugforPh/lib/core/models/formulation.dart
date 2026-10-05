/// Drug pharmaceutical dosage form and release profile (D10).
enum DrugFormulation {
  immediateReleaseTablet(labelEn: 'IR Tablet', labelTh: 'ยาเม็ดออกฤทธิ์ทันที'),
  extendedReleaseTablet(labelEn: 'XR / ER / CR Tablet', labelTh: 'ยาเม็ดออกฤทธิ์เนิ่น'),
  delayedReleaseTablet(labelEn: 'Delayed-Release / Enteric Coated', labelTh: 'ยาเม็ดเคลือบเอนเทอริก'),
  capsule(labelEn: 'Capsule', labelTh: 'ยาแคปซูล'),
  oralLiquid(labelEn: 'Oral Liquid / Solution / Syrup', labelTh: 'ยาน้ำรับประทาน'),
  ivInfusion(labelEn: 'IV Infusion', labelTh: 'ยาหยดเข้าหลอดเลือดดำ'),
  ivInjection(labelEn: 'IV Injection (Push / Bolus)', labelTh: 'ยาฉีดเข้าหลอดเลือดดำ'),
  scInjection(labelEn: 'SC Injection', labelTh: 'ยาฉีดใต้ผิวหนัง'),
  imInjection(labelEn: 'IM Injection', labelTh: 'ยาฉีดเข้ากล้ามเนื้อ'),
  topical(labelEn: 'Topical Formulation', labelTh: 'ยาทาภายนอก'),
  transdermalPatch(labelEn: 'Transdermal Patch', labelTh: 'แผ่นแปะผิวหนัง'),
  inhalation(labelEn: 'Inhalation', labelTh: 'ยาพ่นสูด');

  final String labelEn;
  final String labelTh;

  const DrugFormulation({required this.labelEn, required this.labelTh});
}
