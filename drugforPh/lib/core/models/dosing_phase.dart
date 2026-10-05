import 'frequency.dart';
import 'rate_unit.dart';
import 'unit.dart';

/// Clinical phase of a multi-step regimen (D3).
enum PhaseType {
  loading(labelEn: 'Loading Dose', labelTh: 'ขนาดยาเริ่มต้น (Loading)'),
  maintenance(labelEn: 'Maintenance', labelTh: 'ขนาดยาต่อเนื่อง (Maintenance)'),
  taper(labelEn: 'Taper / De-escalation', labelTh: 'การปรับลดยา (Taper)'),
  bolus(labelEn: 'Initial Bolus', labelTh: 'ฉีดเข้าหลอดเลือดดำทันที (Bolus)'),
  infusion(labelEn: 'Continuous Infusion', labelTh: 'หยดเข้าหลอดเลือดดำต่อเนื่อง (Infusion)');

  final String labelEn;
  final String labelTh;

  const PhaseType({required this.labelEn, required this.labelTh});
}

/// Role of a dose within a phase or titration schedule (D3).
enum DoseRole {
  start(labelEn: 'Starting Dose', labelTh: 'ขนาดเริ่มต้น'),
  usual(labelEn: 'Target / Usual Dose', labelTh: 'ขนาดเป้าหมายปกติ'),
  max(labelEn: 'Maximum Dose', labelTh: 'ขนาดสูงสุด');

  final String labelEn;
  final String labelTh;

  const DoseRole({required this.labelEn, required this.labelTh});
}

/// A structured dosing phase within a multi-phase treatment protocol (D3).
class DosingPhase {
  final PhaseType type;
  final DoseRole role;
  final String nameEn;
  final String nameTh;
  final double? dose;
  final double? dosePerKg;
  final DoseUnit? doseUnit;
  final Frequency? frequency;
  final double? rate;
  final RateUnit? rateUnit;
  final int? durationDays;
  final int? durationDoses;
  final double? durationHours;
  final String? instructionsEn;
  final String? instructionsTh;

  const DosingPhase({
    required this.type,
    this.role = DoseRole.usual,
    required this.nameEn,
    required this.nameTh,
    this.dose,
    this.dosePerKg,
    this.doseUnit,
    this.frequency,
    this.rate,
    this.rateUnit,
    this.durationDays,
    this.durationDoses,
    this.durationHours,
    this.instructionsEn,
    this.instructionsTh,
  });
}
