// ============================================================================
// Challenger Empirical Stress Test & Registry Invariants Oracle
// ============================================================================
// Milestone M16: Pending Pharmacist Registry Invariance Challenge
// Adversarially stress-tests:
// 1. Strict status invariants (NO AI auto-approval, strictly pendingPharmacistDecision)
// 2. Non-blocking Overdose Policy adherence (raw calculatedDose never clamped/hidden)
// 3. Epinephrine pediatric anaphylaxis weight-based dosage without clamping
// 4. Line synchronization oracle between checklist and target code
// 5. Verification dossier PDF integrity and structural assertions
// ============================================================================

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Challenger Oracle: Pending Decision Status Invariants', () {
    test('Strict Invariant: None of DEC-PND-001..006 is marked ratified or approved', () {
      expect(PendingPharmacistRegistry.count, equals(6));
      for (final decision in PendingPharmacistRegistry.allDecisions) {
        expect(
          decision.status,
          equals(PendingDecisionStatus.pendingPharmacistDecision),
          reason: 'Violation: Decision ${decision.id} must be pendingPharmacistDecision',
        );
        expect(
          decision.status == PendingDecisionStatus.ratified,
          isFalse,
          reason: 'Violation: Decision ${decision.id} was unilaterally marked as ratified!',
        );
        expect(
          decision.status == PendingDecisionStatus.underCommitteeReview,
          isFalse,
          reason: 'Violation: Decision ${decision.id} status modified without governance!',
        );
      }
    });

    test('Strict Invariant: Active calculation constants reflect untouched baseline', () {
      // DEC-PND-001: Acyclovir maxSingleDose must remain 800.0 mg (not bumped to 1000 mg)
      final acyclovir = DrugDatabase.findById('acyclovir')!;
      final hsv = acyclovir.regimens.firstWhere((r) => r.indication?.contains('Encephalitis') == true);
      expect(hsv.limits?.maxSingleDose, equals(800.0));

      // DEC-PND-002: Atropine pediatric bradycardia must retain minSingleDose 0.1 and maxSingleDose 0.5 without doseCap
      final atropine = DrugDatabase.findById('atropine')!;
      final brady = atropine.regimens.firstWhere((r) => r.indication?.contains('Bradycardia (Pediatric)') == true);
      expect(brady.limits?.minSingleDose, equals(0.1));
      expect(brady.limits?.maxSingleDose, equals(0.5));
      expect(brady.doseCap, isNull);

      // DEC-PND-003: Dexamethasone croup must retain maxSingleDose 10.0 without doseCap
      final dexa = DrugDatabase.findById('dexamethasone')!;
      final croup = dexa.regimens.firstWhere((r) => r.indication?.contains('Croup') == true);
      expect(croup.limits?.maxSingleDose, equals(10.0));
      expect(croup.doseCap, isNull);

      // DEC-PND-004: Epinephrine pediatric anaphylaxis must retain maxSingleDose 0.3 without doseCap
      final epi = DrugDatabase.findById('epinephrine')!;
      final ana = epi.regimens.firstWhere((r) => r.indication?.contains('Anaphylaxis (Pediatric)') == true);
      expect(ana.limits?.maxSingleDose, equals(0.3));
      expect(ana.doseCap, isNull);

      // DEC-PND-005: Salbutamol pediatric < 20kg must retain maxSingleDose 2.5 without doseCap
      final sal = DrugDatabase.findById('salbutamol')!;
      final neb = sal.regimens.firstWhere((r) => r.indication?.contains('Pediatric < 20kg') == true);
      expect(neb.limits?.maxSingleDose, equals(2.5));
      expect(neb.doseCap, isNull);
    });
  });

  group('Challenger Oracle: Non-Blocking Overdose Policy Fuzzing', () {
    test('Acyclovir IV 10 mg/kg: Dose is never clamped on heavy patients, warnings fire, raw dose preserved', () {
      final acyclovir = DrugDatabase.findById('acyclovir')!;
      final hsv = acyclovir.regimens.firstWhere((r) => r.indication?.contains('Encephalitis') == true);

      final weights = [50.0, 70.0, 80.0, 85.0, 90.0, 100.0, 120.0, 150.0];
      for (final w in weights) {
        final pt = Patient(
          id: 'pt-$w',
          ageYears: 40,
          weightKg: w,
          heightCm: 175.0,
          sex: Sex.male,
          isScrStable: true,
        );
        final res = PharmacistCalculator.calculateDose(
          patient: pt,
          drug: acyclovir,
          regimen: hsv,
        );

        final expectedRawDose = 10.0 * w;
        expect(res.success, isTrue, reason: 'Calculation must succeed');
        expect(res.calculatedDose, closeTo(expectedRawDose, 1e-5),
            reason: 'Calculated dose for weight $w must be exact raw mathematical dose without clamping');

        if (expectedRawDose > 800.0) {
          expect(res.warnings.any((warning) => warning.code == DoseWarningCode.maxSingleDoseExceeded), isTrue,
              reason: 'Overdose warning must fire when expectedRawDose > 800 mg');
          expect(res.isBlocked, isTrue, reason: 'isBlocked indicates hard limit violation');
        } else {
          expect(res.warnings.any((warning) => warning.code == DoseWarningCode.maxSingleDoseExceeded), isFalse);
          expect(res.isBlocked, isFalse);
        }
      }
    });

    test('Epinephrine Pediatric Anaphylaxis 0.01 mg/kg: Dose never clamped to 0.3 mg, visible even on massive overdose', () {
      final epi = DrugDatabase.findById('epinephrine')!;
      final ana = epi.regimens.firstWhere((r) => r.indication?.contains('Anaphylaxis (Pediatric)') == true);

      final pedWeights = [10.0, 15.0, 20.0, 30.0, 35.0, 40.0, 50.0, 70.0];
      for (final w in pedWeights) {
        final pt = Patient(
          id: 'ped-$w',
          ageYears: (w / 3.0).clamp(1, 15).toInt(),
          weightKg: w,
          heightCm: 100.0,
          sex: Sex.female,
          isScrStable: true,
        );
        final res = PharmacistCalculator.calculateDose(
          patient: pt,
          drug: epi,
          regimen: ana,
        );

        final expectedRawDose = 0.01 * w;
        expect(res.success, isTrue, reason: 'Calculation must succeed');
        expect(res.calculatedDose, closeTo(expectedRawDose, 1e-5),
            reason: 'Dose must not be clamped for child of $w kg');

        if (expectedRawDose > 0.30) {
          expect(res.warnings.any((warning) => warning.code == DoseWarningCode.maxSingleDoseExceeded), isTrue,
              reason: 'Overdose warning must fire when > 0.30 mg');
          expect(res.isBlocked, isTrue);
        } else {
          expect(res.warnings.any((warning) => warning.code == DoseWarningCode.maxSingleDoseExceeded), isFalse);
          expect(res.isBlocked, isFalse);
        }
      }
    });
  });

  group('Challenger Oracle: Line Synchronization Analysis', () {
    test('Empirical line check of review/Pending_Pharmacist_Signoff_Checklist.md citations', () {
      final checklist = File('review/Pending_Pharmacist_Signoff_Checklist.md').readAsStringSync();

      // Check Antibiotics file
      final abxLines = File('lib/data/drugs/antibiotics.dart').readAsLinesSync();
      int? acyclovirStart;
      int? acyclovirEnd;
      for (int i = 0; i < abxLines.length; i++) {
        if (abxLines[i].contains("id: 'acyclovir'")) {
          acyclovirStart = i + 1; // 1-based line of id
        }
        if (acyclovirStart != null && abxLines[i].contains("id: 'fluconazole'")) {
          acyclovirEnd = i + 1;
          break;
        }
      }
      expect(acyclovirStart, isNotNull);
      expect(acyclovirEnd, isNotNull);
      // id: 'acyclovir' is at line 1691 (Drug starts at 1690).
      expect(acyclovirStart, equals(1691));

      // Check Emergency file
      final emLines = File('lib/data/drugs/emergency.dart').readAsLinesSync();
      int? epiPedStart;
      int? atropinePedStart;
      int? dexaCroupStart;

      for (int i = 0; i < emLines.length; i++) {
        if (emLines[i].contains("indication: 'Anaphylaxis (Pediatric)'")) {
          epiPedStart = i + 1;
        }
        if (emLines[i].contains("indication: 'Bradycardia (Pediatric)'")) {
          atropinePedStart = i + 1;
        }
        if (emLines[i].contains("indication: 'Croup (Pediatric)'")) {
          dexaCroupStart = i + 1;
        }
      }

      expect(epiPedStart, equals(77));
      expect(atropinePedStart, equals(160));
      expect(dexaCroupStart, equals(334));

      // Verify that the checklist mentions the target files and synchronized line ranges
      expect(checklist.contains('lib/data/drugs/antibiotics.dart'), isTrue);
      expect(checklist.contains('lib/data/drugs/emergency.dart` (lines 158–166)'), isTrue);
      expect(checklist.contains('lib/data/drugs/emergency.dart` (lines 332–340)'), isTrue);
      expect(checklist.contains('lib/data/drugs/respiratory.dart'), isTrue);
    });
  });

  group('Challenger Oracle: PDF Dossier Physical Verification', () {
    test('review/Clinical_Verification_Dossier.pdf meets all physical and structural invariants', () {
      final pdfFile = File('review/Clinical_Verification_Dossier.pdf');
      expect(pdfFile.existsSync(), isTrue, reason: 'Dossier PDF must exist on disk');

      final sizeBytes = pdfFile.lengthSync();
      expect(sizeBytes, greaterThan(100 * 1024),
          reason: 'PDF size must be > 100 KB, actual: ${sizeBytes / 1024} KB');

      final bytes = pdfFile.readAsBytesSync();
      final header = String.fromCharCodes(bytes.take(5));
      expect(header, equals('%PDF-'), reason: 'PDF must start with %PDF-');

      final tail = String.fromCharCodes(bytes.skip(bytes.length - 200));
      expect(tail.contains('%%EOF'), isTrue, reason: 'PDF must terminate with %%EOF');
    });
  });
}
