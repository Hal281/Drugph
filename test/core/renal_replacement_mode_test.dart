import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/core.dart';

void main() {
  group('RenalReplacementMode Domain Model Tests', () {
    test('RenalReplacementMode enums have proper localization and dialysis detection', () {
      expect(RenalReplacementMode.none.labelEn, 'None (Standard)');
      expect(RenalReplacementMode.none.labelTh, 'ปกติ (ไม่ล้างไต)');
      expect(RenalReplacementMode.none.isRrt, isFalse);

      expect(RenalReplacementMode.ihd.labelEn, 'Intermittent Hemodialysis (IHD)');
      expect(RenalReplacementMode.ihd.badgeEn, 'IHD');
      expect(RenalReplacementMode.ihd.isRrt, isTrue);
      expect(RenalReplacementMode.ihd.isIhd, isTrue);

      expect(RenalReplacementMode.capd.labelEn, 'Continuous Ambulatory Peritoneal Dialysis (CAPD)');
      expect(RenalReplacementMode.capd.badgeEn, 'CAPD');
      expect(RenalReplacementMode.capd.isRrt, isTrue);
      expect(RenalReplacementMode.capd.isCapd, isTrue);

      expect(RenalReplacementMode.crrt.labelEn, 'Continuous Renal Replacement Therapy (CRRT)');
      expect(RenalReplacementMode.crrt.badgeEn, 'CRRT');
      expect(RenalReplacementMode.crrt.isRrt, isTrue);
      expect(RenalReplacementMode.crrt.isCrrt, isTrue);
    });

    test('Patient defaults to RenalReplacementMode.none and copyWith preserves/updates mode', () {
      const p = Patient(
        id: 'PT-1',
        weightKg: 70,
        heightCm: 175,
        ageYears: 55,
        sex: Sex.male,
        serumCreatinineMgDl: 4.5,
        isScrStable: true,
      );

      expect(p.renalReplacementMode, equals(RenalReplacementMode.none));

      final pCrrt = p.copyWith(renalReplacementMode: RenalReplacementMode.crrt);
      expect(pCrrt.renalReplacementMode, equals(RenalReplacementMode.crrt));
      expect(pCrrt.id, equals('PT-1'));

      final pIhd = pCrrt.copyWith(renalReplacementMode: RenalReplacementMode.ihd);
      expect(pIhd.renalReplacementMode, equals(RenalReplacementMode.ihd));
    });

    test('RenalReplacementProtocol model properties and lookup on DosingRegimen', () {
      const protocol = RenalReplacementProtocol(
        mode: RenalReplacementMode.crrt,
        specificDose: 1000.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q8h,
        requiresPostHdSupplement: false,
        clinicalInstructionEn: '1000 mg IV q8h for CVVH/CVVHD/CVVHDF',
        clinicalInstructionTh: '1,000 มก. IV ทุก 8 ชม. สำหรับ CRRT',
        provenance: Provenance(
          source: 'Sanford Guide 2024 Table 10B',
          reviewedBy: 'Clinical Pharmacist',
          reviewedAt: '2024-10-12',
        ),
      );

      expect(protocol.mode, equals(RenalReplacementMode.crrt));
      expect(protocol.specificDose, equals(1000.0));
      expect(protocol.doseUnit, equals(DoseUnit.mg));
      expect(protocol.frequency, equals(Frequency.q8h));
      expect(protocol.requiresPostHdSupplement, isFalse);
      expect(protocol.provenance?.source, contains('Sanford Guide'));

      const regimen = DosingRegimen(
        route: DoseRoute.iv,
        indication: 'Severe Sepsis',
        dosingType: DosingType.fixed,
        fixedDose: 1000.0,
        doseUnit: DoseUnit.mg,
        frequency: Frequency.q8h,
        renalReplacementProtocols: [protocol],
      );

      expect(regimen.rrtProtocolFor(RenalReplacementMode.crrt), isNotNull);
      expect(regimen.rrtProtocolFor(RenalReplacementMode.crrt)?.specificDose, equals(1000.0));
      expect(regimen.rrtProtocolFor(RenalReplacementMode.ihd), isNull);
      expect(regimen.rrtProtocolFor(RenalReplacementMode.none), isNull);
    });
  });
}
