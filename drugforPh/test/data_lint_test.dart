import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:drug_dosage_calculator/core/models/models.dart';
import 'package:drug_dosage_calculator/core/calculators/unit_converter.dart';
import 'package:drug_dosage_calculator/core/calculators/pharmacist_calculator.dart';

void main() {
  group('Addendum C: Clinical Data Lint Tests', () {
    final allDrugs = DrugDatabase.allDrugs;

    test('Database contains drugs and has unique IDs', () {
      expect(allDrugs, isNotEmpty);
      final ids = <String>{};
      for (final drug in allDrugs) {
        expect(ids.contains(drug.id), isFalse, reason: 'Duplicate drug ID found: ${drug.id}');
        ids.add(drug.id);
      }
    });

    test('Every drug has mandatory clinical metadata and non-empty generic name', () {
      for (final drug in allDrugs) {
        expect(drug.id.trim(), isNotEmpty, reason: 'Empty ID on drug ${drug.genericName}');
        expect(drug.genericName.trim(), isNotEmpty, reason: 'Empty genericName on drug ${drug.id}');
        expect(
          drug.sourceCitation.trim(),
          isNotEmpty,
          reason: 'Drug ${drug.id} missing sourceCitation clinical reference',
        );
        expect(
          drug.lastReviewedDate.trim(),
          isNotEmpty,
          reason: 'Drug ${drug.id} missing lastReviewedDate clinical review stamp',
        );
        expect(
          drug.regimens,
          isNotEmpty,
          reason: 'Drug ${drug.id} has no dosing regimens defined',
        );
      }
    });

    test('Every regimen satisfies its dosingType configuration requirements', () {
      for (final drug in allDrugs) {
        for (final reg in drug.regimens) {
          final context = 'Drug "${drug.id}", route ${reg.route.abbreviation}, indication "${reg.indication}"';

          switch (reg.dosingType) {
            case DosingType.weightBased:
              expect(
                reg.dosePerKg != null || reg.minDosePerKg != null,
                isTrue,
                reason: '$context is weightBased but lacks dosePerKg and minDosePerKg',
              );
              break;
            case DosingType.bsaBased:
              expect(
                reg.dosePerM2,
                isNotNull,
                reason: '$context is bsaBased but lacks dosePerM2',
              );
              break;
            case DosingType.gfrBased:
              expect(
                reg.targetAuc,
                isNotNull,
                reason: '$context is gfrBased but lacks targetAuc',
              );
              break;
            case DosingType.fixed:
              expect(
                reg.fixedDose,
                isNotNull,
                reason: '$context is fixed but lacks fixedDose',
              );
              break;
            case DosingType.titrated:
              expect(
                reg.continuousRateMin != null && reg.continuousRateUnit != null,
                isTrue,
                reason: '$context is titrated but lacks continuousRateMin or continuousRateUnit',
              );
              break;
            case DosingType.renalAdjusted:
              expect(
                reg.fixedDose != null || reg.dosePerKg != null || reg.renalAdjustments != null,
                isTrue,
                reason: '$context is renalAdjusted but has no dose or adjustment tier configured',
              );
              break;
          }
        }
      }
    });

    test('Every regimen has non-contradictory safety limits when defined', () {
      for (final drug in allDrugs) {
        for (final reg in drug.regimens) {
          final limits = reg.limits;
          if (limits == null) continue;
          final context = 'Limits on Drug "${drug.id}", route ${reg.route.abbreviation}';

          if (limits.maxSingleDose != null) {
            expect(limits.maxSingleDose!, greaterThan(0), reason: '$context: maxSingleDose must be > 0');
          }
          if (limits.softMaxSingleDose != null && limits.maxSingleDose != null) {
            expect(
              limits.softMaxSingleDose!,
              lessThanOrEqualTo(limits.maxSingleDose!),
              reason: '$context: softMaxSingleDose (${limits.softMaxSingleDose}) cannot exceed maxSingleDose (${limits.maxSingleDose})',
            );
          }
          if (limits.minSingleDose != null && limits.maxSingleDose != null) {
            expect(
              limits.minSingleDose!,
              lessThanOrEqualTo(limits.maxSingleDose!),
              reason: '$context: minSingleDose (${limits.minSingleDose}) cannot exceed maxSingleDose (${limits.maxSingleDose})',
            );
          }
          if (limits.maxDailyDose != null) {
            expect(limits.maxDailyDose!, greaterThan(0), reason: '$context: maxDailyDose must be > 0');
          }
          if (limits.maxDailyDose != null && limits.maxSingleDose != null) {
            expect(
              limits.maxDailyDose!,
              greaterThanOrEqualTo(limits.maxSingleDose!),
              reason: '$context: maxDailyDose (${limits.maxDailyDose}) cannot be less than maxSingleDose (${limits.maxSingleDose})',
            );
          }
        }
      }
    });

    test('Every renal adjustment tier has valid non-inverted CrCl ranges and positive factor', () {
      for (final drug in allDrugs) {
        for (final reg in drug.regimens) {
          if (reg.renalAdjustments == null) continue;
          for (final adj in reg.renalAdjustments!) {
            final context = 'Renal tier on Drug "${drug.id}" (CrCl ${adj.crclMin}-${adj.crclMax})';
            expect(
              adj.crclMin,
              lessThanOrEqualTo(adj.crclMax),
              reason: '$context: crclMin (${adj.crclMin}) must be <= crclMax (${adj.crclMax})',
            );
            expect(
              adj.crclMin,
              greaterThanOrEqualTo(0),
              reason: '$context: crclMin cannot be negative',
            );
            expect(
              adj.adjustmentFactor,
              greaterThanOrEqualTo(0),
              reason: '$context: adjustmentFactor must be >= 0',
            );
          }
        }
      }
    });

    test('Every regimen frequency string is parseable or recognized as special clinical interval', () {
      final validSpecialFrequencies = {
        'prn',
        'as needed',
        'qod',
        'every other day',
        'weekly',
        'continuous',
        'titrated',
        'once',
        'stat',
      };

      final failures = <String>[];
      bool isRecognizedSpecialInterval(String freq) {
        final f = freq.trim().toLowerCase();
        if (validSpecialFrequencies.contains(f)) return true;
        if (f.contains('prn') || f.contains('as needed')) return true;
        if (f.contains('continuous')) return true;
        if (f.contains('cycle') || f.contains('per week')) return true;
        if (f.contains('over ') || f.contains('→')) return true;
        if (RegExp(r'\b(to|or)\b').hasMatch(f)) return true;
        if (RegExp(r'q\d+\s*-\s*q?\d+h').hasMatch(f)) return true;
        if (RegExp(r'q\d+-\d+min').hasMatch(f)) return true;
        if (f.contains('resuscitation') || f.contains('recovery')) return true;
        return false;
      }

      for (final drug in allDrugs) {
        for (final reg in drug.regimens) {
          final freq = reg.frequency.trim().toLowerCase();
          final dPerDay = UnitConverter.dosesPerDay(freq);
          final isSpecial = isRecognizedSpecialInterval(freq);

          if (dPerDay <= 0 && !isSpecial) {
            failures.add('${drug.id}: "${reg.frequency}"');
          }
        }
      }
      expect(
        failures,
        isEmpty,
        reason: 'Unparseable frequencies found:\n${failures.join('\n')}',
      );
    });

    test('Titrated regimens skip vial rounding and return continuous rate', () {
      const patient = Patient(
        id: 'patient-test-titrated',
        ageYears: 45,
        weightKg: 70.0,
        heightCm: 175.0,
        sex: Sex.male,
      );
      for (final drug in allDrugs) {
        for (final reg in drug.regimens) {
          if (reg.dosingType == DosingType.titrated) {
            final result = PharmacistCalculator.calculateDose(
              drug: drug,
              patient: patient,
              regimen: reg,
            );
            // Titrated continuous infusion must NOT round to vial strengths
            expect(result.roundedDose, isNull,
                reason: 'Titrated regimen on ${drug.id} must have roundedDose == null');
            expect(result.calculatedDose, isNotNull,
                reason: 'Titrated regimen on ${drug.id} must define continuous rate in calculatedDose');
          }
        }
      }
    });
  });
}
