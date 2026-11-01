import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const required21InjectableDrugIds = <String>[
    'phenytoin',
    'heparin',
    'potassium_chloride',
    'norepinephrine',
    'dopamine',
    'amiodarone',
    'furosemide',
    'nicardipine',
    'epinephrine',
    'magnesium_sulfate',
    'dobutamine',
    'insulin_regular',
    'oxytocin',
    'vancomycin',
    'gentamicin',
    'amikacin',
    'meropenem',
    'ceftriaxone',
    'cefazolin',
    'piperacillin_tazobactam',
    'colistin',
  ];

  Drug findDrug(String id) =>
      DrugDatabase.allDrugs.firstWhere((d) => d.id == id);

  group('IV Diluent Compatibility — 21 Hospital Injectable Drugs Audit', () {
    test('All 21 core injectable hospital drugs define valid, non-contradictory IvDiluentCompatibility', () {
      expect(required21InjectableDrugIds.length, 21);

      for (final id in required21InjectableDrugIds) {
        final drug = findDrug(id);
        final compat = drug.ivDiluentCompatibility;
        expect(
          compat,
          isNotNull,
          reason: 'Injectable drug "$id" must define ivDiluentCompatibility',
        );

        expect(
          compat!.compatibleDiluents,
          isNotEmpty,
          reason: '"$id" must have at least one compatible diluent',
        );

        // Disjoint invariant: no diluent can be both compatible and incompatible
        for (final d in compat.compatibleDiluents) {
          expect(
            compat.isIncompatible(d),
            isFalse,
            reason: '"$id" lists ${d.code} as both compatible and incompatible',
          );
        }

        // Preferred diluent must be a member of compatibleDiluents
        if (compat.preferredDiluent != null) {
          expect(
            compat.isCompatible(compat.preferredDiluent!),
            isTrue,
            reason:
                '"$id" preferredDiluent (${compat.preferredDiluent!.code}) must be in compatibleDiluents',
          );
        }

        // Every incompatible diluent rule must carry bilingual clinical explanations
        if (compat.incompatibleDiluents.isNotEmpty) {
          expect(compat.incompatibilityReasonEn, isNotNull);
          expect(compat.incompatibilityReasonEn!.trim(), isNotEmpty);
          expect(compat.incompatibilityReasonTh, isNotNull);
          expect(compat.incompatibilityReasonTh!.trim(), isNotEmpty);
        }

        // Honest provenance & authoritative textbook/SPL citation
        expect(compat.sourceCitation.trim(), isNotEmpty);
        expect(compat.verificationStatus, VerificationStatus.pendingReview);

        // Bedside UI diluent list always includes NSS, D5W, and LRS
        expect(
          compat.bedsideCheckDiluents,
          containsAll([IvDiluent.nss, IvDiluent.d5w, IvDiluent.lrs]),
        );
      }
    });

    test('Critical bedside physical precipitation & potency hazards are accurately encoded', () {
      // 1. Phenytoin + D5W / LRS -> microcrystalline precipitation; NSS only
      final phenytoin = findDrug('phenytoin').ivDiluentCompatibility!;
      expect(phenytoin.isPreferred(IvDiluent.nss), isTrue);
      expect(phenytoin.isCompatible(IvDiluent.nss), isTrue);
      expect(phenytoin.isIncompatible(IvDiluent.d5w), isTrue);
      expect(phenytoin.isIncompatible(IvDiluent.d5nss), isTrue);
      expect(phenytoin.isIncompatible(IvDiluent.lrs), isTrue);

      // 2. Ceftriaxone + LRS -> fatal insoluble ceftriaxone-calcium precipitation
      final ceftriaxone = findDrug('ceftriaxone').ivDiluentCompatibility!;
      expect(ceftriaxone.isCompatible(IvDiluent.nss), isTrue);
      expect(ceftriaxone.isCompatible(IvDiluent.d5w), isTrue);
      expect(ceftriaxone.isIncompatible(IvDiluent.lrs), isTrue);

      // 3. Amiodarone continuous infusion -> D5W only; incompatible with NSS & LRS
      final amiodarone = findDrug('amiodarone').ivDiluentCompatibility!;
      expect(amiodarone.isPreferred(IvDiluent.d5w), isTrue);
      expect(amiodarone.isCompatible(IvDiluent.d5w), isTrue);
      expect(amiodarone.isIncompatible(IvDiluent.nss), isTrue);
      expect(amiodarone.isIncompatible(IvDiluent.lrs), isTrue);

      // 4. Norepinephrine -> D5W / D5NSS required; NSS alone causes oxidation loss of potency
      final norepi = findDrug('norepinephrine').ivDiluentCompatibility!;
      expect(norepi.isPreferred(IvDiluent.d5w), isTrue);
      expect(norepi.isCompatible(IvDiluent.d5w), isTrue);
      expect(norepi.isCompatible(IvDiluent.d5nss), isTrue);
      expect(norepi.isIncompatible(IvDiluent.nss), isTrue);

      // 5. Nicardipine -> incompatible with LRS (US FDA Cardene IV SPL §2.3)
      final nicardipine = findDrug('nicardipine').ivDiluentCompatibility!;
      expect(nicardipine.isCompatible(IvDiluent.nss), isTrue);
      expect(nicardipine.isCompatible(IvDiluent.d5w), isTrue);
      expect(nicardipine.isIncompatible(IvDiluent.lrs), isTrue);

      // 6. Meropenem -> NSS preferred (~4h RT stability vs ~1h in D5W for extended infusion)
      final meropenem = findDrug('meropenem').ivDiluentCompatibility!;
      expect(meropenem.isPreferred(IvDiluent.nss), isTrue);
      expect(meropenem.stabilityNoteEn, contains('4 hours'));
    });
  });
}
