import 'patient.dart';
import 'unit.dart';
import 'dose_limit.dart';

/// Child-Pugh classification for hepatic impairment (D4).
enum ChildPughClass {
  none(labelEn: 'None (Normal)', labelTh: 'ปกติ'),
  classA(labelEn: 'Child-Pugh A (Mild)', labelTh: 'Child-Pugh A (ตับทำงานบกพร่องเล็กน้อย)'),
  classB(labelEn: 'Child-Pugh B (Moderate)', labelTh: 'Child-Pugh B (ตับทำงานบกพร่องปานกลาง)'),
  classC(labelEn: 'Child-Pugh C (Severe)', labelTh: 'Child-Pugh C (ตับทำงานบกพร่องรุนแรง)'),
  sentinel(labelEn: '', labelTh: '');

  final String labelEn;
  final String labelTh;

  const ChildPughClass({required this.labelEn, required this.labelTh});

  static List<ChildPughClass> get clinicalValues => [none, classA, classB, classC];
}

/// Structured population applicability criteria for a dosing regimen (D4).
class PopulationCriteria {
  /// Minimum age in completed months (inclusive).
  final int? minAgeMonths;

  /// Maximum age in completed months (inclusive).
  final int? maxAgeMonths;

  /// Minimum body weight in kg (inclusive).
  final double? minWeightKg;

  /// Maximum body weight in kg (inclusive).
  final double? maxWeightKg;

  /// Target sex, if restricted to a specific biological sex.
  final Sex? sex;

  /// Whether this regimen is approved / safe in pregnancy.
  final bool? pregnancySafe;

  /// Whether this regimen is strictly contraindicated in pregnancy.
  final bool contraindicatedPregnancy;

  /// Maximum tolerated hepatic impairment level.
  final ChildPughClass? maxHepaticImpairment;

  const PopulationCriteria({
    this.minAgeMonths,
    this.maxAgeMonths,
    this.minWeightKg,
    this.maxWeightKg,
    this.sex,
    this.pregnancySafe,
    this.contraindicatedPregnancy = false,
    this.maxHepaticImpairment,
  });

  /// Standard adult population criteria (>= 18 years, TBW >= 40 kg).
  static const PopulationCriteria adultStandard = PopulationCriteria(
    minAgeMonths: 216, // 18 years
    minWeightKg: 40.0,
  );

  /// Validates a [patient] against these population constraints.
  List<DoseWarning> checkApplicability(Patient patient) {
    final warnings = <DoseWarning>[];

    // Age check
    final patientAgeMonths = patient.ageYears * 12 + (patient.ageMonths ?? 0);
    if (minAgeMonths != null && patientAgeMonths < minAgeMonths!) {
      warnings.add(DoseWarning(
        severity: LimitSeverity.hard,
        code: DoseWarningCode.pediatricBlocked,
        messageEn:
            'Patient age ($patientAgeMonths months) is below minimum age ($minAgeMonths months) for this regimen.',
        messageTh:
            'อายุผู้ป่วย ($patientAgeMonths เดือน) ต่ำกว่าเกณฑ์ขั้นต่ำ ($minAgeMonths เดือน) สำหรับสูตรยานี้',
      ));
    }
    if (maxAgeMonths != null && patientAgeMonths > maxAgeMonths!) {
      warnings.add(DoseWarning(
        severity: LimitSeverity.hard,
        code: DoseWarningCode.generalAlert,
        messageEn:
            'Patient age ($patientAgeMonths months) exceeds maximum age ($maxAgeMonths months) for this regimen.',
        messageTh:
            'อายุผู้ป่วย ($patientAgeMonths เดือน) เกินเกณฑ์สูงสุด ($maxAgeMonths เดือน) สำหรับสูตรยานี้',
      ));
    }

    // Weight check
    if (minWeightKg != null && patient.weightKg < minWeightKg!) {
      warnings.add(DoseWarning(
        severity: LimitSeverity.hard,
        code: DoseWarningCode.generalAlert,
        messageEn:
            'Patient weight (${patient.weightKg.toStringAsFixed(1)} kg) is below minimum weight ($minWeightKg kg) for this regimen.',
        messageTh:
            'น้ำหนักผู้ป่วย (${patient.weightKg.toStringAsFixed(1)} กก.) ต่ำกว่าเกณฑ์ขั้นต่ำ ($minWeightKg กก.) สำหรับสูตรยานี้',
      ));
    }
    if (maxWeightKg != null && patient.weightKg > maxWeightKg!) {
      warnings.add(DoseWarning(
        severity: LimitSeverity.soft,
        code: DoseWarningCode.generalAlert,
        messageEn:
            'Patient weight (${patient.weightKg.toStringAsFixed(1)} kg) exceeds standard maximum weight ($maxWeightKg kg). Verify dosing strategy.',
        messageTh:
            'น้ำหนักผู้ป่วย (${patient.weightKg.toStringAsFixed(1)} กก.) เกินเกณฑ์มาตรฐาน ($maxWeightKg กก.) โปรดตรวจสอบขนาดยา',
      ));
    }

    // Sex check
    if (sex != null && patient.sex != sex) {
      warnings.add(DoseWarning(
        severity: LimitSeverity.hard,
        code: DoseWarningCode.populationMismatch,
        messageEn: 'Regimen is clinically indicated for ${sex!.nameEn} patients only.',
        messageTh: 'สูตรยานี้มีข้อบ่งใช้เฉพาะผู้ป่วยเพศ ${sex!.nameTh} เท่านั้น',
      ));
    }

    // Pregnancy check
    if (patient.isPregnant && contraindicatedPregnancy) {
      warnings.add(const DoseWarning(
        severity: LimitSeverity.hard,
        code: DoseWarningCode.contraindicationAlert,
        messageEn: 'PREGNANCY CONTRAINDICATION: This drug/regimen is strictly contraindicated in pregnancy.',
        messageTh: 'ข้อห้ามใช้ในหญิงตั้งครรภ์: ยา/สูตรยานี้ห้ามใช้เด็ดขาดในสตรีมีครรภ์',
      ));
    }

    // Hepatic check
    if (maxHepaticImpairment != null && patient.hepaticImpairment != null) {
      if (patient.hepaticImpairment!.index > maxHepaticImpairment!.index) {
        warnings.add(DoseWarning(
          severity: LimitSeverity.hard,
          code: DoseWarningCode.contraindicationAlert,
          messageEn:
              'Patient hepatic impairment (${patient.hepaticImpairment!.labelEn}) exceeds maximum allowable level (${maxHepaticImpairment!.labelEn}).',
          messageTh:
              'ระดับการทำงานของตับ (${patient.hepaticImpairment!.labelTh}) รุนแรงกว่าเกณฑ์ที่อนุญาตให้ใช้สูตรนี้ (${maxHepaticImpairment!.labelTh})',
        ));
      }
    }

    return warnings;
  }
}
