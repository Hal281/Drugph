import '../../core/models/models.dart';

final List<Drug> obstetric = [
  const Drug(
    id: 'oxytocin',
    genericName: 'Oxytocin',
    brandNames: ['Pitocin', 'Syntocinon'],
    nameTh: 'ออกซิโทซิน',
    category: DrugCategory.obstetric,
    pregnancyCategory:
        'X', // Used specifically for inducing labor, but FDA category X due to non-labor risks
    isHighAlert: true,
    severeInteractions: ['Dinoprostone', 'Misoprostol'],
    specialNotes: 'Close fetal and uterine monitoring is required.',
    specialNotesTh:
        'ต้องเฝ้าระวังอัตราการเต้นของหัวใจทารกและการหดรัดตัวของมดลูกอย่างใกล้ชิด',
    regimens: [
      DosingRegimen(
        route: DoseRoute.iv,
        indication: 'Labor induction',
        dosingType: DosingType.titrated,
        doseUnit: DoseUnit.units,
        frequency: Frequency.continuous,
        continuousRateMin: 1, // 1-2 mU/min
        continuousRateMax: 20, // Max usually 20-40 mU/min
        continuousRateUnit: 'mU/min',
        rateUnit: RateUnit.mUMin,
        standardDilutionMgPerMl: 0.01, // e.g. 10 units in 1000ml = 10 mU/ml
        population: PopulationCriteria(sex: Sex.female),
      ),
      DosingRegimen(
        route: DoseRoute.im,
        indication: 'Postpartum hemorrhage prophylaxis',
        dosingType: DosingType.fixed,
        fixedDose: 10,
        doseUnit: DoseUnit.units, // Actually IU
        frequency: Frequency.once,
        limits: DoseLimit(maxDailyDose: 10),
        population: PopulationCriteria(sex: Sex.female),
      ),
    ],
  ),
  const Drug(
    id: 'misoprostol',
    genericName: 'Misoprostol',
    brandNames: ['Cytotec'],
    nameTh: 'ไมโซพรอสทอล',
    category: DrugCategory.obstetric,
    pregnancyCategory: 'X',
    contraindications: ['Previous cesarean section (for induction)'],
    severeInteractions: ['Oxytocin (do not give simultaneously)'],
    regimens: [
      DosingRegimen(
        route: DoseRoute.po, // Or vaginal, sublingual
        indication: 'Postpartum hemorrhage',
        dosingType: DosingType.fixed,
        fixedDose: 600, // 600-800 mcg
        doseUnit: DoseUnit.mcg,
        frequency: Frequency.once,
        limits: DoseLimit(maxDailyDose: 800),
      ),
      DosingRegimen(
        route: DoseRoute.po, // or vaginal
        indication: 'Labor induction (Cervical ripening)',
        dosingType: DosingType.fixed,
        fixedDose: 25,
        doseUnit: DoseUnit.mcg,
        frequency: Frequency(minIntervalHours: 3, maxIntervalHours: 6, displayEn: 'q3-6h', displayTh: 'ทุก 3-6 ชม.'),
        limits: DoseLimit(maxDailyDose: 100), // Max total dose usually limited
      ),
    ],
  ),
  const Drug(
    id: 'methylergometrine',
    genericName: 'Methylergonovine',
    brandNames: ['Methergine'],
    nameTh: 'เมทิลเออร์โกเมทริน',
    category: DrugCategory.obstetric,
    pregnancyCategory: 'C',
    contraindications: ['Hypertension', 'Preeclampsia'],
    severeInteractions: ['Macrolides (Clarithromycin)', 'Triptans'],
    regimens: [
      DosingRegimen(
        route: DoseRoute.im,
        indication: 'Postpartum hemorrhage',
        dosingType: DosingType.fixed,
        fixedDose: 0.2,
        doseUnit: DoseUnit.mg,
        frequency: Frequency(
          minIntervalHours: 2,
          maxIntervalHours: 4,
          isPrn: true,
          displayEn: 'q2-4h PRN',
          displayTh: 'ทุก 2-4 ชม. เมื่อจำเป็น',
        ),
        limits: DoseLimit(maxDailyDose: 1), // Max 5 doses
      ),
    ],
  ),
  const Drug(
    id: 'terbutaline',
    genericName: 'Terbutaline',
    brandNames: ['Bricanyl'],
    nameTh: 'เทอร์บูทาลีน',
    category:
        DrugCategory.obstetric, // Also respiratory but often used as tocolytic
    pregnancyCategory: 'C',
    severeInteractions: ['Beta-blockers', 'MAOIs'],
    specialNotes:
        'Used off-label as a tocolytic (to stop preterm labor). Not for prolonged use > 48h.',
    specialNotesTh: 'ระวังใจสั่น หัวใจเต้นเร็ว (Tachycardia)',
    regimens: [
      DosingRegimen(
        route: DoseRoute.sc,
        indication: 'Preterm labor (Tocolysis)',
        dosingType: DosingType.fixed,
        fixedDose: 0.25,
        doseUnit: DoseUnit.mg,
        frequency: Frequency(minIntervalHours: 0, isPrn: true, displayEn: 'q20-30min PRN', displayTh: 'ทุก 20-30 นาที เมื่อจำเป็น'),
        limits: DoseLimit(
            maxDailyDose: 1), // Limited doses due to maternal cardiac risks
      ),
    ],
  ),
];
