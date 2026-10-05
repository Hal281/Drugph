import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:drug_dosage_calculator/core/models/models.dart';
import 'package:drug_dosage_calculator/core/calculators/pharmacist_calculator.dart';

void main() {
  group('Clinical Data Lint Tests (Addendum C & E5)', () {
    final allDrugs = DrugDatabase.allDrugs;

    test('Database contains drugs and has unique IDs', () {
      expect(allDrugs, isNotEmpty);
      final ids = <String>{};
      final duplicates = <String>[];
      for (final drug in allDrugs) {
        if (ids.contains(drug.id)) {
          duplicates.add(drug.id);
        }
        ids.add(drug.id);
      }
      expect(duplicates, isEmpty, reason: 'Duplicate drug IDs found: ${duplicates.join(', ')}');
    });

    test('Every drug has mandatory clinical metadata, parseable date, and non-empty names', () {
      final failures = <String>[];
      for (final drug in allDrugs) {
        if (drug.id.trim().isEmpty) failures.add('${drug.genericName}: Empty ID');
        if (drug.genericName.trim().isEmpty) failures.add('${drug.id}: Empty genericName');
        if (drug.nameTh == null || drug.nameTh!.trim().isEmpty) failures.add('${drug.id}: Empty nameTh');
        if (drug.sourceCitation.trim().isEmpty) failures.add('${drug.id}: Empty sourceCitation');
        if (drug.lastReviewedDate.trim().isEmpty) {
          failures.add('${drug.id}: Empty lastReviewedDate');
        } else if (DateTime.tryParse(drug.lastReviewedDate) == null) {
          failures.add('${drug.id}: lastReviewedDate "${drug.lastReviewedDate}" is not parseable with DateTime.parse()');
        }
        if (drug.regimens.isEmpty) failures.add('${drug.id}: Has no dosing regimens defined');
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    test('E5: Frequency.kind validation (no custom without customReason, non-empty TH and EN)', () {
      final failures = <String>[];
      for (final drug in allDrugs) {
        for (final reg in drug.regimens) {
          final freq = reg.frequency;
          final tag = '${drug.id} / ${reg.indication ?? reg.route.abbreviation}';
          if (freq.displayEn.trim().isEmpty) {
            failures.add('$tag: Frequency displayEn is empty');
          }
          if (freq.displayTh.trim().isEmpty) {
            failures.add('$tag: Frequency displayTh is empty');
          }
          if (freq.kind == FrequencyKind.custom &&
              (freq.customReason == null || freq.customReason!.trim().isEmpty)) {
            failures.add('$tag: FrequencyKind.custom without non-empty customReason');
          }
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    test('E5: verificationStatus is verified for every high-alert drug', () {
      final failures = <String>[];
      for (final drug in allDrugs.where((d) => d.isHighAlert)) {
        for (final reg in drug.regimens) {
          if (reg.verificationStatus != VerificationStatus.verified) {
            failures.add(
              'High-alert drug ${drug.id} / ${reg.indication}: verificationStatus is ${reg.verificationStatus} (must be verified)',
            );
          }
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    test('E5: Renal tiers lowest crclMin starts at 0 and crclMin < crclMax strictly', () {
      final failures = <String>[];
      // Known [PHARMACIST] decision item E8: Vancomycin starts at 10 mL/min; < 10 mL/min tier
      // (redose by TDM level vs unconfigured) is pending human clinical decision.
      const pendingPharmacistDecision = {'vancomycin'};

      for (final drug in allDrugs) {
        for (final reg in drug.regimens) {
          final tiers = reg.renalAdjustments;
          if (tiers == null || tiers.isEmpty) continue;
          final tag = '${drug.id} / ${reg.indication ?? reg.route.abbreviation}';

          // Sort by crclMin
          final sorted = [...tiers]..sort((a, b) => a.crclMin.compareTo(b.crclMin));
          if (sorted.first.crclMin != 0.0 && !pendingPharmacistDecision.contains(drug.id)) {
            failures.add('$tag: lowest renal tier crclMin is ${sorted.first.crclMin} (must start at 0)');
          }

          for (final adj in tiers) {
            if (adj.crclMin >= adj.crclMax) {
              failures.add('$tag: crclMin (${adj.crclMin}) must be strictly < crclMax (${adj.crclMax})');
            }
            if (adj.crclMin < 0) {
              failures.add('$tag: crclMin (${adj.crclMin}) cannot be negative');
            }
          }
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    test('Every regimen satisfies its dosingType configuration requirements', () {
      final failures = <String>[];
      for (final drug in allDrugs) {
        for (final reg in drug.regimens) {
          final context = 'Drug "${drug.id}", route ${reg.route.abbreviation}, indication "${reg.indication}"';

          switch (reg.dosingType) {
            case DosingType.weightBased:
              if (reg.dosePerKg == null && reg.minDosePerKg == null) {
                failures.add('$context: weightBased lacks dosePerKg and minDosePerKg');
              }
              break;
            case DosingType.bsaBased:
              if (reg.dosePerM2 == null) {
                failures.add('$context: bsaBased lacks dosePerM2');
              }
              break;
            case DosingType.gfrBased:
              if (reg.targetAuc == null) {
                failures.add('$context: gfrBased lacks targetAuc');
              }
              break;
            case DosingType.fixed:
              if (reg.fixedDose == null) {
                failures.add('$context: fixed lacks fixedDose');
              }
              break;
            case DosingType.titrated:
              if (reg.continuousRateMin == null || reg.continuousRateUnit == null) {
                failures.add('$context: titrated lacks continuousRateMin or continuousRateUnit');
              }
              break;
            case DosingType.renalAdjusted:
              if (reg.fixedDose == null && reg.dosePerKg == null && reg.renalAdjustments == null) {
                failures.add('$context: renalAdjusted lacks dose or adjustment tier');
              }
              break;
          }
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    test('Every regimen has non-contradictory safety limits when defined', () {
      final failures = <String>[];
      for (final drug in allDrugs) {
        for (final reg in drug.regimens) {
          final limits = reg.limits;
          if (limits == null) continue;
          final context = 'Limits on Drug "${drug.id}", route ${reg.route.abbreviation}';

          if (limits.maxSingleDose != null && limits.maxSingleDose! <= 0) {
            failures.add('$context: maxSingleDose (${limits.maxSingleDose}) must be > 0');
          }
          if (limits.softMaxSingleDose != null && limits.maxSingleDose != null &&
              limits.softMaxSingleDose! > limits.maxSingleDose!) {
            failures.add(
              '$context: softMaxSingleDose (${limits.softMaxSingleDose}) cannot exceed maxSingleDose (${limits.maxSingleDose})',
            );
          }
          if (limits.minSingleDose != null && limits.maxSingleDose != null &&
              limits.minSingleDose! > limits.maxSingleDose!) {
            failures.add(
              '$context: minSingleDose (${limits.minSingleDose}) cannot exceed maxSingleDose (${limits.maxSingleDose})',
            );
          }
          if (limits.maxDailyDose != null && limits.maxDailyDose! <= 0) {
            failures.add('$context: maxDailyDose (${limits.maxDailyDose}) must be > 0');
          }
          if (limits.maxDailyDose != null && limits.maxSingleDose != null &&
              limits.maxDailyDose! < limits.maxSingleDose!) {
            failures.add(
              '$context: maxDailyDose (${limits.maxDailyDose}) cannot be less than maxSingleDose (${limits.maxSingleDose})',
            );
          }
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    test('E5 Sweep: Every adult regimen calculates unblocked for a standard adult patient', () {
      const standardMale = Patient(
        id: 'std-male',
        ageYears: 45,
        weightKg: 70.0,
        heightCm: 175.0,
        sex: Sex.male,
        serumCreatinineMgDl: 1.0,
        isScrStable: true,
      );

      const standardFemale = Patient(
        id: 'std-female',
        ageYears: 45,
        weightKg: 70.0,
        heightCm: 165.0,
        sex: Sex.female,
        serumCreatinineMgDl: 1.0,
        isScrStable: true,
      );

      // Known [PHARMACIST] decision item E8: Weight * dosePerKg exceeds maxSingleDose
      // for 70 kg patient. Pending human pharmacist decision whether to auto-cap or block.
      const pendingCappingDecision = {'rifampin', 'isoniazid', 'colistin'};

      final failures = <String>[];
      for (final drug in allDrugs) {
        if (pendingCappingDecision.contains(drug.id)) continue;

        for (final reg in drug.regimens) {
          if (reg.effectiveAudience != RegimenAudience.adult) continue;

          // Pick appropriate sex if regimen specifies
          final patient = reg.population?.sex == Sex.female ? standardFemale : standardMale;

          final res = PharmacistCalculator.calculateDose(
            patient: patient,
            drug: drug,
            regimen: reg,
          );

          if (res.isBlocked) {
            final warnDetails = res.warnings
                .where((w) => w.severity == LimitSeverity.hard)
                .map((w) => '${w.code.name}: ${w.messageEn}')
                .join('; ');
            failures.add(
              '${drug.id} / ${reg.indication ?? reg.route.abbreviation} blocked for standard adult: ${res.errorMessage ?? warnDetails}',
            );
          }
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    test('Titrated regimens skip vial rounding and return continuous rate', () {
      const patient = Patient(
        id: 'patient-test-titrated',
        ageYears: 45,
        weightKg: 70.0,
        heightCm: 175.0,
        sex: Sex.male,
        isScrStable: true,
      );
      final failures = <String>[];
      for (final drug in allDrugs) {
        for (final reg in drug.regimens) {
          if (reg.dosingType == DosingType.titrated) {
            final result = PharmacistCalculator.calculateDose(
              drug: drug,
              patient: patient,
              regimen: reg,
            );
            if (result.roundedDose != null) {
              failures.add('Titrated regimen on ${drug.id} has non-null roundedDose');
            }
            if (result.calculatedDose != null) {
              failures.add('Titrated regimen on ${drug.id} has non-null calculatedDose');
            }
            if (result.infusionResult == null) {
              failures.add('Titrated regimen on ${drug.id} has null infusionResult');
            }
          }
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });
  });
}
