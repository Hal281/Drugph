import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/models/models.dart';
import 'package:drug_dosage_calculator/core/calculators/pharmacist_calculator.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';

/// Invariant sweep: runs the single engine over every drug, every regimen and
/// several patient archetypes, asserting properties that must ALWAYS hold
/// regardless of the clinical content of the database.
void main() {
  const adult = Patient(
    id: 'sweep-adult',
    ageYears: 45,
    weightKg: 70,
    heightCm: 175,
    sex: Sex.male,
    serumCreatinineMgDl: 1.0,
    isScrStable: true,
  );
  const adultNoScr = Patient(
    id: 'sweep-adult-noscr',
    ageYears: 45,
    weightKg: 70,
    heightCm: 175,
    sex: Sex.male,
    isScrStable: true,
  );
  const elderlyRenal = Patient(
    id: 'sweep-elderly',
    ageYears: 82,
    weightKg: 52,
    heightCm: 158,
    sex: Sex.female,
    serumCreatinineMgDl: 2.8,
    isScrStable: true,
  );
  const obese = Patient(
    id: 'sweep-obese',
    ageYears: 50,
    weightKg: 140,
    heightCm: 170,
    sex: Sex.male,
    serumCreatinineMgDl: 1.1,
    isScrStable: true,
  );
  const child = Patient(
    id: 'sweep-child',
    ageYears: 8,
    weightKg: 25,
    heightCm: 125,
    sex: Sex.male,
    serumCreatinineMgDl: 0.5,
    isScrStable: true,
  );

  bool isPediatricRegimen(DosingRegimen r) =>
      (r.indication ?? '').toLowerCase().contains('pediatric');

  final adultPatients = [adult, adultNoScr, elderlyRenal, obese];

  group('Engine invariant sweep', () {
    test('no regimen ever throws or yields NaN/Infinity/negative dose', () {
      final failures = <String>[];
      for (final drug in DrugDatabase.allDrugs) {
        for (final reg in drug.regimens) {
          for (final p in [...adultPatients, child]) {
            final res = PharmacistCalculator.calculateDose(
                patient: p, drug: drug, regimen: reg);
            final tag = '${drug.id} / ${reg.indication} / ${p.id}';
            if (res.warnings.any((w) => w.code == DoseWarningCode.calculationError)) {
              failures.add('$tag threw: ${res.errorMessage}');
              continue;
            }
            for (final v in [res.calculatedDose, res.roundedDose, res.dailyDose]) {
              if (v != null && (v.isNaN || v.isInfinite || v < 0)) {
                failures.add('$tag produced invalid number $v');
              }
            }
          }
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    test('every titrated regimen resolves to a KNOWN rate unit (no silent fallback)', () {
      final failures = <String>[];
      for (final drug in DrugDatabase.allDrugs) {
        for (final reg in drug.regimens) {
          if (reg.dosingType != DosingType.titrated) continue;
          if (reg.rateUnit != null) continue;
          final raw = reg.continuousRateUnit;
          if (raw == null || RateUnit.tryFromSymbol(raw) == null) {
            failures.add(
                '${drug.id} / ${reg.indication}: unresolved rate unit "$raw"');
          }
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    test('maxInfusionRateMgPerMin is only used with mg-based dose units', () {
      final failures = <String>[];
      for (final drug in DrugDatabase.allDrugs) {
        for (final reg in drug.regimens) {
          if (reg.maxInfusionRateMgPerMin != null &&
              reg.doseUnit != DoseUnit.mg) {
            failures.add(
                '${drug.id} / ${reg.indication}: unit ${reg.doseUnit.symbol} compared against mg/min');
          }
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    test('unblocked adult results never exceed the regimen hard single-dose cap', () {
      final failures = <String>[];
      for (final drug in DrugDatabase.allDrugs) {
        for (final reg in drug.regimens) {
          final cap = reg.limits?.maxSingleDose;
          if (cap == null || isPediatricRegimen(reg)) continue;
          for (final p in adultPatients) {
            final res = PharmacistCalculator.calculateDose(
                patient: p, drug: drug, regimen: reg);
            final d = res.calculatedDose;
            if (!res.isBlocked && d != null && d > cap + 1e-9) {
              failures.add('${drug.id} / ${reg.indication} / ${p.id}: $d > cap $cap not blocked');
            }
          }
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    test('pediatric regimens are usable for a child (not blocked as "adult only")', () {
      final failures = <String>[];
      for (final drug in DrugDatabase.allDrugs) {
        for (final reg in drug.regimens.where(isPediatricRegimen)) {
          final res = PharmacistCalculator.calculateDose(
              patient: child, drug: drug, regimen: reg);
          if (res.warnings.any((w) => w.code == DoseWarningCode.pediatricBlocked) ||
              !res.success) {
            failures.add(
                '${drug.id} / ${reg.indication}: blocked for 8y/25kg child (${res.errorMessage})');
          }
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    test('adult regimens are blocked for a child', () {
      final failures = <String>[];
      for (final drug in DrugDatabase.allDrugs) {
        for (final reg in drug.regimens.where((r) => !isPediatricRegimen(r))) {
          final res = PharmacistCalculator.calculateDose(
              patient: child, drug: drug, regimen: reg);
          if (!res.isBlocked) {
            failures.add('${drug.id} / ${reg.indication}: adult regimen NOT blocked for child');
          }
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    test('pediatric regimens are blocked for an adult', () {
      final failures = <String>[];
      for (final drug in DrugDatabase.allDrugs) {
        for (final reg in drug.regimens.where(isPediatricRegimen)) {
          final res = PharmacistCalculator.calculateDose(
              patient: adult, drug: drug, regimen: reg);
          if (!res.isBlocked) {
            failures.add('${drug.id} / ${reg.indication}: pediatric regimen NOT blocked for adult');
          }
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    test('renal tiers cover CrCl 0..infinity contiguously (no dosing gaps)', () {
      final failures = <String>[];
      for (final drug in DrugDatabase.allDrugs) {
        for (final reg in drug.regimens) {
          final tiers = reg.renalAdjustments;
          if (tiers == null || tiers.length < 2) continue;
          final sorted = [...tiers]..sort((a, b) => a.crclMin.compareTo(b.crclMin));
          for (var i = 0; i < sorted.length - 1; i++) {
            if (sorted[i].crclMax != sorted[i + 1].crclMin) {
              failures.add(
                  '${drug.id} / ${reg.indication}: gap/overlap between [${sorted[i].crclMin},${sorted[i].crclMax}) and [${sorted[i + 1].crclMin},${sorted[i + 1].crclMax})');
            }
          }
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });
  });
}
