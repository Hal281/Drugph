import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChildPughCalculator — Pure Deterministic Boundary Verification', () {
    test('Total Bilirubin scoring boundaries (<2.0 -> 1, 2.0..3.0 -> 2, >3.0 -> 3)', () {
      expect(ChildPughCalculator.scoreBilirubin(0.1), 1);
      expect(ChildPughCalculator.scoreBilirubin(1.99), 1);
      expect(ChildPughCalculator.scoreBilirubin(2.0), 2);
      expect(ChildPughCalculator.scoreBilirubin(2.5), 2);
      expect(ChildPughCalculator.scoreBilirubin(3.0), 2);
      expect(ChildPughCalculator.scoreBilirubin(3.01), 3);
      expect(ChildPughCalculator.scoreBilirubin(15.0), 3);
    });

    test('Serum Albumin scoring boundaries (>3.5 -> 1, 2.8..3.5 -> 2, <2.8 -> 3)', () {
      expect(ChildPughCalculator.scoreAlbumin(4.5), 1);
      expect(ChildPughCalculator.scoreAlbumin(3.51), 1);
      expect(ChildPughCalculator.scoreAlbumin(3.5), 2);
      expect(ChildPughCalculator.scoreAlbumin(3.1), 2);
      expect(ChildPughCalculator.scoreAlbumin(2.8), 2);
      expect(ChildPughCalculator.scoreAlbumin(2.79), 3);
      expect(ChildPughCalculator.scoreAlbumin(1.8), 3);
    });

    test('INR scoring boundaries (<1.7 -> 1, 1.7..2.3 -> 2, >2.3 -> 3)', () {
      expect(ChildPughCalculator.scoreInr(0.9), 1);
      expect(ChildPughCalculator.scoreInr(1.69), 1);
      expect(ChildPughCalculator.scoreInr(1.7), 2);
      expect(ChildPughCalculator.scoreInr(2.0), 2);
      expect(ChildPughCalculator.scoreInr(2.3), 2);
      expect(ChildPughCalculator.scoreInr(2.31), 3);
      expect(ChildPughCalculator.scoreInr(4.5), 3);
    });

    test('Total score 5..15 maps deterministically to Class A (5-6), Class B (7-9), Class C (10-15)', () {
      expect(ChildPughCalculator.classifyScore(5), ChildPughClass.classA);
      expect(ChildPughCalculator.classifyScore(6), ChildPughClass.classA);

      expect(ChildPughCalculator.classifyScore(7), ChildPughClass.classB);
      expect(ChildPughCalculator.classifyScore(8), ChildPughClass.classB);
      expect(ChildPughCalculator.classifyScore(9), ChildPughClass.classB);

      for (int score = 10; score <= 15; score++) {
        expect(ChildPughCalculator.classifyScore(score), ChildPughClass.classC);
      }

      expect(() => ChildPughCalculator.classifyScore(4), throwsArgumentError);
      expect(() => ChildPughCalculator.classifyScore(16), throwsArgumentError);
    });

    test('Full 5-parameter calculate() computes exact points across Class A, B, and C', () {
      final classA = ChildPughCalculator.calculate(
        totalBilirubinMgDl: 1.2,
        serumAlbuminGDl: 4.0,
        inr: 1.1,
        ascites: ChildPughAscites.none,
        encephalopathy: ChildPughEncephalopathy.none,
      );
      expect(classA.totalScore, 5);
      expect(classA.classification, ChildPughClass.classA);

      final classB = ChildPughCalculator.calculate(
        totalBilirubinMgDl: 2.4, // 2
        serumAlbuminGDl: 3.1, // 2
        inr: 1.8, // 2
        ascites: ChildPughAscites.mildOrControlled, // 2
        encephalopathy: ChildPughEncephalopathy.none, // 1
      );
      expect(classB.totalScore, 9);
      expect(classB.classification, ChildPughClass.classB);

      final classC = ChildPughCalculator.calculate(
        totalBilirubinMgDl: 5.2, // 3
        serumAlbuminGDl: 2.1, // 3
        inr: 2.8, // 3
        ascites: ChildPughAscites.moderateToSevere, // 3
        encephalopathy: ChildPughEncephalopathy.grade3To4, // 3
      );
      expect(classC.totalScore, 15);
      expect(classC.classification, ChildPughClass.classC);
    });

    test('Rejects NaN, Infinite, zero, negative, and physiologically out-of-range lab values', () {
      for (final bad in [0.0, -1.5, double.nan, double.infinity, 150.0]) {
        expect(
          () => ChildPughCalculator.calculate(
            totalBilirubinMgDl: bad,
            serumAlbuminGDl: 3.8,
            inr: 1.1,
            ascites: ChildPughAscites.none,
            encephalopathy: ChildPughEncephalopathy.none,
          ),
          throwsArgumentError,
        );
      }

      final evalMissing = ChildPughCalculator.evaluate(
        totalBilirubinMgDl: null,
        serumAlbuminGDl: 3.8,
        inr: 1.1,
        ascites: ChildPughAscites.none,
        encephalopathy: ChildPughEncephalopathy.none,
      );
      expect(evalMissing.isValid, isFalse);
      expect(evalMissing.errorEn, isNotEmpty);
      expect(evalMissing.errorTh, isNotEmpty);

      final evalBadInr = ChildPughCalculator.evaluate(
        totalBilirubinMgDl: 1.2,
        serumAlbuminGDl: 3.8,
        inr: 0.2, // < 0.5
        ascites: ChildPughAscites.none,
        encephalopathy: ChildPughEncephalopathy.none,
      );
      expect(evalBadInr.isValid, isFalse);
    });
  });

  group('DOAC Hepatic Contraindication Integration (US FDA SPL)', () {
    Patient patientWithHepatic(ChildPughClass cls) => Patient(
          id: 'P-HEP-${cls.name}',
          weightKg: 70.0,
          heightCm: 170.0,
          ageYears: 60,
          sex: Sex.male,
          serumCreatinineMgDl: 0.9,
          isScrStable: true,
          hepaticImpairment: cls == ChildPughClass.none ? null : cls,
        );

    test('Rivaroxaban: allowed in Child-Pugh A, hard contraindication in Child-Pugh B & C', () {
      final rivaroxaban =
          DrugDatabase.allDrugs.firstWhere((d) => d.id == 'rivaroxaban');
      final regimen = rivaroxaban.regimens.first;

      final resA = PharmacistCalculator.calculateDose(
        patient: patientWithHepatic(ChildPughClass.classA),
        drug: rivaroxaban,
        regimen: regimen,
      );
      expect(resA.calculatedDose, 20.0);
      expect(
        resA.warnings.any((w) => w.severity == LimitSeverity.hard),
        isFalse,
      );

      for (final blockedClass in [
        ChildPughClass.classB,
        ChildPughClass.classC,
      ]) {
        final resBlocked = PharmacistCalculator.calculateDose(
          patient: patientWithHepatic(blockedClass),
          drug: rivaroxaban,
          regimen: regimen,
        );
        expect(
          resBlocked.warnings.any(
            (w) =>
                w.severity == LimitSeverity.hard &&
                w.code == DoseWarningCode.contraindicationAlert,
          ),
          isTrue,
          reason: 'Rivaroxaban must trigger hard contraindication in $blockedClass',
        );
      }
    });

    test('Apixaban: allowed with soft caution in Child-Pugh B, hard contraindication in Child-Pugh C', () {
      final apixaban =
          DrugDatabase.allDrugs.firstWhere((d) => d.id == 'apixaban');

      for (final regimen in apixaban.regimens) {
        final resB = PharmacistCalculator.calculateDose(
          patient: patientWithHepatic(ChildPughClass.classB),
          drug: apixaban,
          regimen: regimen,
        );
        expect(resB.calculatedDose, greaterThan(0));
        expect(
          resB.warnings.any((w) => w.severity == LimitSeverity.hard),
          isFalse,
        );
        expect(
          resB.warnings.any(
            (w) =>
                w.severity == LimitSeverity.soft &&
                w.code == DoseWarningCode.contraindicationAlert,
          ),
          isTrue,
        );

        final resC = PharmacistCalculator.calculateDose(
          patient: patientWithHepatic(ChildPughClass.classC),
          drug: apixaban,
          regimen: regimen,
        );
        expect(
          resC.warnings.any(
            (w) =>
                w.severity == LimitSeverity.hard &&
                w.code == DoseWarningCode.contraindicationAlert,
          ),
          isTrue,
        );
      }
    });
  });
}
