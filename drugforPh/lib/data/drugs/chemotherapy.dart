import '../../core/models/models.dart';

final List<Drug> chemotherapy = [
  const Drug(
    id: 'carboplatin',
    genericName: 'Carboplatin',
    brandNames: ['Paraplatin'],
    nameTh: 'คาร์โบพลาติน',
    category: DrugCategory.chemotherapy,
    isHighAlert: true,
    requiresRenalAdjustment: true,
    specialNotes: 'Dosed using Calvert formula based on GFR.',
    specialNotesTh: 'คำนวณโดสด้วยสูตร Calvert โดยใช้ค่า GFR',
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'Ovarian Cancer / Solid Tumors',
        dosingType: DosingType.gfrBased, // Calvert formula
        targetAuc: 5.0, // Often 4-6
        doseUnit: DoseUnit.mg,
        frequency: Frequency(isOnce: true, displayEn: 'Once per cycle', displayTh: 'ครั้งเดียวต่อรอบการรักษา'),
        limits: DoseLimit(
          maxSingleDose: 900.0,
        ),
      ),
    ],
  ),
  const Drug(
    id: 'methotrexate',
    genericName: 'Methotrexate',
    brandNames: ['Trexall', 'Rheumatrex'],
    nameTh: 'เมโธเทรกเซต',
    category: DrugCategory.chemotherapy,
    isHighAlert: true,
    requiresRenalAdjustment: true,
    specialNotes: 'High dose requires leucovorin rescue. Fatal if dosed daily instead of weekly for RA.',
    specialNotesTh: 'โดสสูงต้องใช้ leucovorin ช่วย. ระวังการให้ยาทุกวันแทนรายสัปดาห์ในผู้ป่วย RA',
    regimens: [
      DosingRegimen(
        route: DoseRoute.ivInfusion,
        indication: 'High-Dose Oncology',
        dosingType: DosingType.bsaBased,
        dosePerM2: 12000.0, // Up to 12 g/m2
        doseUnit: DoseUnit.mg,
        frequency: Frequency(isOnce: true, displayEn: 'Once per cycle', displayTh: 'ครั้งเดียวต่อรอบการรักษา'),
      ),
      DosingRegimen(
        route: DoseRoute.po,
        indication: 'Rheumatoid Arthritis',
        dosingType: DosingType.fixed,
        fixedDose: 7.5, // 7.5 to 25 mg weekly
        doseUnit: DoseUnit.mg,
        frequency: Frequency.weekly,
        limits: DoseLimit(
          maxSingleDose: 30.0,
        ),
      ),
    ],
  ),
];

