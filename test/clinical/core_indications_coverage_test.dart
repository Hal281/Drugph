import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(DrugDatabase.warmUp);

  group('FB-03 / FB-22 (WP-09): Core Drug Indications & Side Effects', () {
    test('all 34 Core drugs have >= 2 clinical indications and valid DoseBasis', () {
      final coreDrugs = DrugDatabase.coreDrugs;
      expect(coreDrugs.length, equals(34));

      for (final drug in coreDrugs) {
        expect(
          drug.regimens.length,
          greaterThanOrEqualTo(2),
          reason:
              'Core drug "${drug.id}" should expose >= 2 clinical indication regimens',
        );

        for (var i = 0; i < drug.regimens.length; i++) {
          final regimen = drug.regimens[i];
          expect(
            regimen.indication?.trim(),
            isNotEmpty,
            reason: 'Core drug "${drug.id}" regimen[$i] must define indication',
          );
          expect(
            DoseBasis.values.contains(regimen.doseBasis),
            isTrue,
            reason: 'Core drug "${drug.id}" regimen[$i] must have valid DoseBasis',
          );
          if (regimen.doseBasis == DoseBasis.perDay) {
            expect(
              regimen.frequency.dosesPerDay,
              greaterThan(0),
              reason:
                  'Core drug "${drug.id}" perDay regimen[$i] must have positive dosesPerDay',
            );
          }
        }
      }
    });

    test(
      'all 34 Core drugs provide non-empty Common & Serious side effects (EN + TH) and citations',
      () {
        for (final drug in DrugDatabase.coreDrugs) {
          expect(
            drug.hasSideEffectData,
            isTrue,
            reason: 'Core drug "${drug.id}" must report hasSideEffectData == true',
          );
          expect(
            drug.sideEffects,
            isNotEmpty,
            reason: 'Core drug "${drug.id}" missing common EN sideEffects',
          );
          expect(
            drug.sideEffectsTh,
            isNotEmpty,
            reason: 'Core drug "${drug.id}" missing common TH sideEffectsTh',
          );
          expect(
            drug.seriousSideEffects,
            isNotEmpty,
            reason: 'Core drug "${drug.id}" missing seriousSideEffects',
          );
          expect(
            drug.seriousSideEffectsTh,
            isNotEmpty,
            reason: 'Core drug "${drug.id}" missing seriousSideEffectsTh',
          );
          expect(
            drug.sourceCitation.trim(),
            isNotEmpty,
            reason: 'Core drug "${drug.id}" missing sourceCitation',
          );
        }
      },
    );

    test('new WP-09 pediatric & emergency regimens evaluate accurately', () {
      const childPatient = Patient(
        id: 'wp09-child-20kg',
        weightKg: 20.0,
        heightCm: 115.0,
        ageYears: 6,
        sex: Sex.male,
        serumCreatinineMgDl: 0.5,
        isScrStable: true,
      );

      final ceftriaxone = DrugDatabase.findById('ceftriaxone')!;
      expect(ceftriaxone.regimens.length, greaterThanOrEqualTo(2));

      final levetiracetam = DrugDatabase.findById('levetiracetam')!;
      final statusReg = levetiracetam.regimens.firstWhere(
        (r) => r.indication!.contains('Status Epilepticus (Pediatric'),
      );
      final statusRes = PharmacistCalculator.calculateDose(
        drug: levetiracetam,
        patient: childPatient,
        regimen: statusReg,
      );
      expect(statusRes.success, isTrue);
      // 60 mg/kg * 20 kg = 1200 mg once
      expect(statusRes.calculatedDose, closeTo(1200.0, 0.01));

      final dobutamine = DrugDatabase.findById('dobutamine')!;
      final pedShock = dobutamine.regimens.firstWhere(
        (r) => r.indication!.contains('Pediatric'),
      );
      final dobutRes = PharmacistCalculator.calculateDose(
        drug: dobutamine,
        patient: childPatient,
        regimen: pedShock,
      );
      expect(dobutRes.success, isTrue);
      expect(dobutRes.infusionResult, isNotNull);
    });
  });
}
