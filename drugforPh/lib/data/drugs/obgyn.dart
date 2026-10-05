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
        frequency: 'continuous',
        continuousRateMin: 1, // 1-2 mU/min
        continuousRateMax: 20, // Max usually 20-40 mU/min
        continuousRateUnit: 'milliunits/min',
        standardDilutionMgPerMl: 0.01, // e.g. 10 units in 1000ml = 10 mU/ml
      ),
      DosingRegimen(
        route: DoseRoute.im,
        indication: 'Postpartum hemorrhage prophylaxis',
        dosingType: DosingType.fixed,
        fixedDose: 10,
        doseUnit: DoseUnit.units, // Actually IU
        frequency: 'Once after delivery',
        limits: DoseLimit(maxDailyDose: 10),
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
        frequency: 'Once',
        limits: DoseLimit(maxDailyDose: 800),
      ),
      DosingRegimen(
        route: DoseRoute.po, // or vaginal
        indication: 'Labor induction (Cervical ripening)',
        dosingType: DosingType.fixed,
        fixedDose: 25,
        doseUnit: DoseUnit.mcg,
        frequency: 'q3-6h',
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
        frequency: 'q2-4h PRN',
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
        frequency: 'q20-30min PRN',
        limits: DoseLimit(
            maxDailyDose: 1), // Limited doses due to maternal cardiac risks
      ),
    ],
  ),
  const Drug(
    id: 'dexamethasone_ob',
    genericName: 'Dexamethasone',
    brandNames: ['Dexa'],
    nameTh: 'เดกซาเมทาโซน',
    category: DrugCategory.obstetric,
    pregnancyCategory: 'C',
    regimens: [
      DosingRegimen(
        route: DoseRoute.im,
        indication: 'Fetal lung maturity',
        dosingType: DosingType.fixed,
        fixedDose: 6,
        doseUnit: DoseUnit.mg,
        frequency: 'q12h (for 4 doses)',
        limits: DoseLimit(maxDailyDose: 12),
      ),
    ],
  ),
];
