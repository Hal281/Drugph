import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:flutter_test/flutter_test.dart';

class _PediatricBenchmark {
  final double weightKg;
  final int ageYears;
  final int ageMonths;
  final double heightCm;

  const _PediatricBenchmark({
    required this.weightKg,
    required this.ageYears,
    required this.ageMonths,
    required this.heightCm,
  });

  int get totalMonths => ageYears * 12 + ageMonths;

  Patient toPatient() => Patient(
        id: 'sweep-${weightKg.toInt()}kg',
        weightKg: weightKg,
        heightCm: heightCm,
        ageYears: ageYears,
        ageMonths: ageMonths,
        sex: Sex.male,
        serumCreatinineMgDl: ageYears >= 1 ? 0.4 : null,
        isScrStable: true,
      );
}

void main() {
  setUpAll(DrugDatabase.warmUp);

  const benchmarks = <_PediatricBenchmark>[
    _PediatricBenchmark(weightKg: 3.0, ageYears: 0, ageMonths: 1, heightCm: 50.0),
    _PediatricBenchmark(weightKg: 5.0, ageYears: 0, ageMonths: 3, heightCm: 60.0),
    _PediatricBenchmark(weightKg: 10.0, ageYears: 1, ageMonths: 0, heightCm: 76.0),
    _PediatricBenchmark(weightKg: 15.0, ageYears: 3, ageMonths: 0, heightCm: 95.0),
    _PediatricBenchmark(weightKg: 20.0, ageYears: 6, ageMonths: 0, heightCm: 115.0),
    _PediatricBenchmark(weightKg: 30.0, ageYears: 9, ageMonths: 0, heightCm: 135.0),
    _PediatricBenchmark(weightKg: 40.0, ageYears: 12, ageMonths: 0, heightCm: 150.0),
  ];

  bool isBenchmarkEligible(DosingRegimen regimen, _PediatricBenchmark b) {
    final pop = regimen.population;
    if (pop == null) return true;
    if (pop.minAgeMonths != null && b.totalMonths < pop.minAgeMonths!) {
      return false;
    }
    if (pop.maxAgeMonths != null && b.totalMonths > pop.maxAgeMonths!) {
      return false;
    }
    if (pop.minWeightKg != null && b.weightKg < pop.minWeightKg!) {
      return false;
    }
    if (pop.maxWeightKg != null && b.weightKg > pop.maxWeightKg!) {
      return false;
    }
    return true;
  }

  group('FB-02 (WP-07): 7-Weight Pediatric Regimen Sweep Audit', () {
    test(
      'Every pediatric regimen produces valid positive finite doses, divides perDay properly, preserves frequency, and honors Rule 5 Non-Blocking Overdose across [3, 5, 10, 15, 20, 30, 40] kg',
      () {
        var totalPediatricRegimens = 0;
        var totalEvaluatedCases = 0;
        final overdoseFindings = <String>[];

        for (final drug in DrugDatabase.allDrugs) {
          for (final regimen in drug.regimens) {
            if (regimen.effectiveAudience != RegimenAudience.pediatric) {
              continue;
            }
            totalPediatricRegimens++;

            var eligibleCountForRegimen = 0;
            for (final b in benchmarks) {
              if (!isBenchmarkEligible(regimen, b)) continue;
              eligibleCountForRegimen++;
              totalEvaluatedCases++;

              final patient = b.toPatient();
              final result = PharmacistCalculator.calculateDose(
                patient: patient,
                drug: drug,
                regimen: regimen,
              );

              // Invariant 1: Success & positive finite dose (or infusion rate)
              expect(
                result.success,
                isTrue,
                reason:
                    '${drug.id} / ${regimen.indication} at ${b.weightKg} kg failed: ${result.errorMessage}',
              );

              if (regimen.route == DoseRoute.ivInfusion &&
                  regimen.dosingType == DosingType.titrated &&
                  result.infusionResult != null) {
                expect(result.infusionResult!.rate, greaterThan(0));
              } else {
                final dose = result.calculatedDose;
                expect(
                  dose != null && dose.isFinite && dose > 0,
                  isTrue,
                  reason:
                      '${drug.id} / ${regimen.indication} at ${b.weightKg} kg produced invalid dose=$dose',
                );

                // Invariant 2: DoseBasis.perDay divides daily dose across dosesPerDay
                final isDailyBasis = regimen.doseBasis == DoseBasis.perDay ||
                    regimen.frequency.doseBasis == DoseBasis.perDay;
                final dosesPerDay = regimen.frequency.dosesPerDay;
                if (regimen.dosingType == DosingType.weightBased &&
                    regimen.dosePerKg != null &&
                    isDailyBasis &&
                    dosesPerDay != null &&
                    dosesPerDay > 1 &&
                    !regimen.frequency.isOnce) {
                  final rawDaily = b.weightKg * regimen.dosePerKg!;
                  final maxSingle = regimen.limits?.maxSingleDose;
                  if (maxSingle == null || rawDaily <= maxSingle) {
                    expect(
                      dose!,
                      lessThan(rawDaily),
                      reason:
                          '${drug.id} / ${regimen.indication} (${b.weightKg} kg) perDay must divide by $dosesPerDay',
                    );
                  }
                }
              }

              // Invariant 3: Normal renal function preserves regimen frequency
              expect(
                result.structuredFrequency?.displayEn,
                equals(regimen.frequency.displayEn),
                reason:
                    '${drug.id} / ${regimen.indication} (${b.weightKg} kg) frequency drifted unexpectedly',
              );

              // Invariant 4: Rule 5 non-blocking when dose exceeds maxSingleDose
              if (regimen.limits?.maxSingleDose != null &&
                  result.calculatedDose != null &&
                  result.calculatedDose! > regimen.limits!.maxSingleDose!) {
                expect(
                  result.success,
                  isTrue,
                  reason:
                      '${drug.id} / ${regimen.indication} at ${b.weightKg} kg violated Rule 5 (failed on overdose)',
                );
                expect(
                  result.calculatedDose,
                  greaterThan(0),
                  reason:
                      '${drug.id} / ${regimen.indication} at ${b.weightKg} kg hid calculatedDose on overdose',
                );
                expect(
                  result.warnings.any(
                    (w) =>
                        w.code == DoseWarningCode.maxSingleDoseExceeded ||
                        w.code == DoseWarningCode.maxDailyDoseExceeded ||
                        w.code == DoseWarningCode.doseCappedAtMax,
                  ),
                  isTrue,
                );
                overdoseFindings.add(
                  '${drug.id} (${regimen.indication}) @ ${b.weightKg}kg: ${result.calculatedDose} > maxSingle ${regimen.limits!.maxSingleDose}',
                );
              }
            }

            expect(
              eligibleCountForRegimen,
              greaterThan(0),
              reason:
                  '${drug.id} / ${regimen.indication} had 0 eligible weights among the 7 pediatric benchmarks',
            );
          }
        }

        expect(totalPediatricRegimens, greaterThanOrEqualTo(15));
        expect(totalEvaluatedCases, greaterThanOrEqualTo(80));
        expect(overdoseFindings, isNotNull);
      },
    );

    test(
      'Adult-only regimen in child is safety-blocked with DoseWarningCode.pediatricBlocked (DEC-PED-AUDIENCE-001)',
      () {
        const child10Kg = Patient(
          id: 'adult-mismatch-child',
          weightKg: 10.0,
          heightCm: 76.0,
          ageYears: 1,
          sex: Sex.male,
          serumCreatinineMgDl: 0.4,
          isScrStable: true,
        );
        final amox = DrugDatabase.findById('amoxicillin')!;
        final adultReg = amox.regimens.firstWhere(
          (r) => r.effectiveAudience == RegimenAudience.adult,
        );

        final res = PharmacistCalculator.calculateDose(
          patient: child10Kg,
          drug: amox,
          regimen: adultReg,
        );
        expect(res.success, isFalse);
        expect(
          res.warnings.any((w) => w.code == DoseWarningCode.pediatricBlocked),
          isTrue,
        );
      },
    );
  });
}
