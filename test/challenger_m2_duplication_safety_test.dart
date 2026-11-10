import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:drug_dosage_calculator/data/prescription_cart.dart';
import 'package:drug_dosage_calculator/core/models/models.dart';
import 'package:drug_dosage_calculator/core/calculators/pharmacist_calculator.dart';

void main() {
  group('M2-2 Duplication Safety Challenger: Empirical Stress Test Suite', () {
    // =========================================================================
    // 1. Identical Molecule Duplication: 100% of all registered drugs paired with self
    // =========================================================================
    group('1. Identical Molecule Duplication (Every Drug in DrugDatabase paired with itself)', () {
      final allDrugs = DrugDatabase.allDrugs;

      test('DrugDatabase has non-empty catalogue of registered drugs', () {
        expect(allDrugs, isNotEmpty);
        // Ensure every drug has a non-empty ID and genericName
        for (final drug in allDrugs) {
          expect(drug.id, isNotEmpty, reason: 'Drug id must not be empty');
          expect(drug.genericName, isNotEmpty, reason: 'Drug genericName must not be empty: ${drug.id}');
        }
      });

      test('Direct TherapeuticDuplicationService: 100% of registered drugs trigger duplication warning when paired with self', () {
        int testedCount = 0;
        int detectedCount = 0;
        final failures = <String>[];

        for (final drug in allDrugs) {
          testedCount++;
          final warning = TherapeuticDuplicationService.checkDuplication(drug, drug);

          if (warning != null &&
              warning.code == DoseWarningCode.therapeuticDuplication &&
              warning.severity == LimitSeverity.hard &&
              warning.messageEn.contains('DUPLICATE ACTIVE DRUG')) {
            detectedCount++;
          } else {
            failures.add('${drug.id} (${drug.genericName}) failed identical duplication check');
          }
        }

        expect(failures, isEmpty, reason: 'Identical duplication failures: $failures');
        expect(detectedCount, equals(testedCount));
        expect(testedCount, equals(allDrugs.length));
      });

      test('Case-insensitive ID matching: Uppercase and Mixed-case IDs must trigger duplication warning', () {
        for (final drug in allDrugs) {
          final upperDrug = Drug(
            id: drug.id.toUpperCase(),
            genericName: drug.genericName,
            category: drug.category,
            drugClass: drug.drugClass,
            regimens: const [],
          );

          final warning = TherapeuticDuplicationService.checkDuplication(drug, upperDrug);
          expect(
            warning,
            isNotNull,
            reason: 'Case-insensitive self check failed for ${drug.id} vs ${upperDrug.id}',
          );
          expect(warning!.severity, equals(LimitSeverity.hard));
          expect(warning.code, equals(DoseWarningCode.therapeuticDuplication));
        }
      });

      test('PharmacistCalculator integration: 100% of registered drugs trigger duplication warning when in activeDrugIds', () {
        const standardPatient = Patient(
          id: 'test-patient-self-dup',
          weightKg: 60.0,
          heightCm: 165.0,
          ageYears: 35,
          sex: Sex.female,
          serumCreatinineMgDl: 0.9,
          isScrStable: true,
        );

        int checked = 0;
        final failures = <String>[];

        for (final drug in allDrugs) {
          if (drug.regimens.isEmpty) continue;
          checked++;

          final patientWithActiveDrug = Patient(
            id: standardPatient.id,
            weightKg: standardPatient.weightKg,
            heightCm: standardPatient.heightCm,
            ageYears: standardPatient.ageYears,
            sex: standardPatient.sex,
            serumCreatinineMgDl: standardPatient.serumCreatinineMgDl,
            isScrStable: standardPatient.isScrStable,
            activeDrugIds: [drug.id],
          );

          final calcResult = PharmacistCalculator.calculateDose(
            patient: patientWithActiveDrug,
            drug: drug,
            regimen: drug.regimens.first,
          );

          final dupWarnings = calcResult.warnings.where(
            (w) => w.code == DoseWarningCode.therapeuticDuplication &&
                w.severity == LimitSeverity.hard &&
                w.messageEn.contains('DUPLICATE ACTIVE DRUG'),
          );

          if (dupWarnings.isEmpty) {
            failures.add(drug.id);
          }
        }

        expect(failures, isEmpty, reason: 'Calculator identical duplication failures: $failures');
        expect(checked, greaterThan(0));
      });
    });

    // =========================================================================
    // 2. Dual NSAIDs All Combination Pairs
    // =========================================================================
    group('2. Dual NSAIDs All Combination Pairs', () {
      // Gather NSAIDs from Database and well-known catalog
      final nsaidDrugs = <Drug>[
        DrugDatabase.findById('ibuprofen')!,
        DrugDatabase.findById('naproxen')!,
        // Also synthesize additional known NSAIDs to stress-test ontology resolution
        const Drug(
          id: 'celecoxib',
          genericName: 'Celecoxib',
          category: DrugCategory.nsaid,
          drugClass: DrugClass.nsaid,
          regimens: [],
        ),
        const Drug(
          id: 'indomethacin',
          genericName: 'Indomethacin',
          category: DrugCategory.nsaid,
          drugClass: DrugClass.nsaid,
          regimens: [],
        ),
        const Drug(
          id: 'diclofenac',
          genericName: 'Diclofenac',
          category: DrugCategory.nsaid,
          drugClass: DrugClass.nsaid,
          regimens: [],
        ),
        const Drug(
          id: 'meloxicam',
          genericName: 'Meloxicam',
          category: DrugCategory.nsaid,
          drugClass: DrugClass.nsaid,
          regimens: [],
        ),
        // Drug with null explicit drugClass falling back to DrugOntology
        const Drug(
          id: 'celecoxib',
          genericName: 'Celecoxib (Ontology Fallback)',
          category: DrugCategory.nsaid,
          drugClass: null,
          regimens: [],
        ),
      ];

      test('All combination pairs of NSAIDs (N x (N - 1)) trigger Dual NSAID warning with 0 false negatives', () {
        int pairsTested = 0;
        final failures = <String>[];

        for (int i = 0; i < nsaidDrugs.length; i++) {
          for (int j = 0; j < nsaidDrugs.length; j++) {
            if (i == j) continue; // Same instance tested in identical group
            final drugA = nsaidDrugs[i];
            final drugB = nsaidDrugs[j];

            pairsTested++;
            final warning = TherapeuticDuplicationService.checkDuplication(drugA, drugB);

            if (warning == null) {
              failures.add('Missing warning for ${drugA.id} + ${drugB.id}');
              continue;
            }

            expect(warning.severity, equals(LimitSeverity.hard),
                reason: 'Severity must be hard for ${drugA.id} + ${drugB.id}');
            expect(warning.code, equals(DoseWarningCode.therapeuticDuplication),
                reason: 'Code must be therapeuticDuplication for ${drugA.id} + ${drugB.id}');
            expect(
              warning.messageEn.contains('NSAID') || warning.messageEn.contains('DUPLICATE ACTIVE DRUG'),
              isTrue,
              reason: 'Message must cite NSAID or duplicate active drug for ${drugA.id} + ${drugB.id}',
            );
          }
        }

        expect(failures, isEmpty, reason: 'Failed NSAID pairs: $failures');
        expect(pairsTested, equals(nsaidDrugs.length * (nsaidDrugs.length - 1)));
      });

      test('PharmacistCalculator Dual NSAID: Ibuprofen prescribed with active Naproxen', () {
        final ibuprofen = DrugDatabase.findById('ibuprofen')!;
        const patient = Patient(
          id: 'p-nsaid-test',
          weightKg: 65.0,
          heightCm: 170.0,
          ageYears: 45,
          sex: Sex.male,
          isScrStable: true,
          activeDrugIds: ['naproxen'],
        );

        final result = PharmacistCalculator.calculateDose(
          patient: patient,
          drug: ibuprofen,
          regimen: ibuprofen.regimens.first,
        );

        final dupWarnings = result.warnings.where(
          (w) => w.code == DoseWarningCode.therapeuticDuplication &&
              w.severity == LimitSeverity.hard &&
              w.messageEn.contains('NSAID'),
        );
        expect(dupWarnings, isNotEmpty);
      });
    });

    // =========================================================================
    // 3. Dual RAS Blockade All Combination Pairs (ACEI + ARB)
    // =========================================================================
    group('3. Dual RAS Blockade (ACEI + ARB, ACEI + ACEI, ARB + ARB)', () {
      final rasDrugs = <Drug>[
        DrugDatabase.findById('enalapril')!,
        DrugDatabase.findById('losartan')!,
        // Additional ACE inhibitors and ARBs to stress-test cross-class matrix
        const Drug(
          id: 'captopril',
          genericName: 'Captopril',
          category: DrugCategory.cardiovascular,
          drugClass: DrugClass.aceInhibitor,
          regimens: [],
        ),
        const Drug(
          id: 'lisinopril',
          genericName: 'Lisinopril',
          category: DrugCategory.cardiovascular,
          drugClass: DrugClass.aceInhibitor,
          regimens: [],
        ),
        const Drug(
          id: 'ramipril',
          genericName: 'Ramipril',
          category: DrugCategory.cardiovascular,
          drugClass: DrugClass.aceInhibitor,
          regimens: [],
        ),
        const Drug(
          id: 'valsartan',
          genericName: 'Valsartan',
          category: DrugCategory.cardiovascular,
          drugClass: DrugClass.arb,
          regimens: [],
        ),
        const Drug(
          id: 'candesartan',
          genericName: 'Candesartan',
          category: DrugCategory.cardiovascular,
          drugClass: DrugClass.arb,
          regimens: [],
        ),
        const Drug(
          id: 'telmisartan',
          genericName: 'Telmisartan',
          category: DrugCategory.cardiovascular,
          drugClass: DrugClass.arb,
          regimens: [],
        ),
        // Ontology fallback
        const Drug(
          id: 'irbesartan',
          genericName: 'Irbesartan (Ontology Fallback)',
          category: DrugCategory.cardiovascular,
          drugClass: null,
          regimens: [],
        ),
      ];

      test('All combination pairs of ACEI + ARB trigger Dual RAS Blockade warning with 0 false negatives', () {
        int pairsTested = 0;
        final failures = <String>[];

        for (int i = 0; i < rasDrugs.length; i++) {
          for (int j = 0; j < rasDrugs.length; j++) {
            if (i == j) continue;
            final drugA = rasDrugs[i];
            final drugB = rasDrugs[j];

            pairsTested++;
            final warning = TherapeuticDuplicationService.checkDuplication(drugA, drugB);

            if (warning == null) {
              failures.add('Missing warning for ${drugA.id} + ${drugB.id}');
              continue;
            }

            expect(warning.severity, equals(LimitSeverity.hard),
                reason: 'Severity must be hard for ${drugA.id} + ${drugB.id}');
            expect(warning.code, equals(DoseWarningCode.therapeuticDuplication),
                reason: 'Code must be therapeuticDuplication for ${drugA.id} + ${drugB.id}');
            expect(
              warning.messageEn.contains('RAS Blockade') || warning.messageEn.contains('DUPLICATE ACTIVE DRUG'),
              isTrue,
              reason: 'Message must cite RAS Blockade for ${drugA.id} + ${drugB.id}',
            );
          }
        }

        expect(failures, isEmpty, reason: 'Failed RAS pairs: $failures');
        expect(pairsTested, equals(rasDrugs.length * (rasDrugs.length - 1)));
      });

      test('Cross-pair: Enalapril (ACEI) + Losartan (ARB) via PharmacistCalculator', () {
        final enalapril = DrugDatabase.findById('enalapril')!;
        const patient = Patient(
          id: 'p-ras-test',
          weightKg: 70.0,
          heightCm: 175.0,
          ageYears: 60,
          sex: Sex.male,
          isScrStable: true,
          activeDrugIds: ['losartan'],
        );

        final result = PharmacistCalculator.calculateDose(
          patient: patient,
          drug: enalapril,
          regimen: enalapril.regimens.first,
        );

        final dupWarnings = result.warnings.where(
          (w) => w.code == DoseWarningCode.therapeuticDuplication &&
              w.severity == LimitSeverity.hard &&
              w.messageEn.contains('RAS Blockade'),
        );
        expect(dupWarnings, isNotEmpty);
      });
    });

    // =========================================================================
    // 4. Dual Anticoagulants All Combination Pairs
    // =========================================================================
    group('4. Dual Anticoagulants All Combination Pairs (Warfarin, Apixaban, Rivaroxaban, Dabigatran, Edoxaban)', () {
      final oacDrugs = <Drug>[
        DrugDatabase.findById('warfarin')!,
        DrugDatabase.findById('apixaban')!,
        DrugDatabase.findById('rivaroxaban')!,
        // Synthesized Dabigatran & Edoxaban using DrugOntology
        const Drug(
          id: 'dabigatran',
          genericName: 'Dabigatran',
          category: DrugCategory.cardiovascular,
          drugClass: DrugClass.anticoagulantDoac,
          regimens: [],
        ),
        const Drug(
          id: 'edoxaban',
          genericName: 'Edoxaban',
          category: DrugCategory.cardiovascular,
          drugClass: DrugClass.anticoagulantDoac,
          regimens: [],
        ),
        // Dabigatran with null drugClass testing DrugOntology fallback
        const Drug(
          id: 'dabigatran',
          genericName: 'Dabigatran (Ontology Fallback)',
          category: DrugCategory.cardiovascular,
          drugClass: null,
          regimens: [],
        ),
      ];

      test('All combination pairs of Oral Anticoagulants trigger Dual Anticoagulant warning with 0 false negatives', () {
        int pairsTested = 0;
        final failures = <String>[];

        for (int i = 0; i < oacDrugs.length; i++) {
          for (int j = 0; j < oacDrugs.length; j++) {
            if (i == j) continue;
            final drugA = oacDrugs[i];
            final drugB = oacDrugs[j];

            pairsTested++;
            final warning = TherapeuticDuplicationService.checkDuplication(drugA, drugB);

            if (warning == null) {
              failures.add('Missing warning for ${drugA.id} + ${drugB.id}');
              continue;
            }

            expect(warning.severity, equals(LimitSeverity.hard),
                reason: 'Severity must be hard for ${drugA.id} + ${drugB.id}');
            expect(warning.code, equals(DoseWarningCode.therapeuticDuplication),
                reason: 'Code must be therapeuticDuplication for ${drugA.id} + ${drugB.id}');
            expect(
              warning.messageEn.contains('Anticoagulant') || warning.messageEn.contains('DUPLICATE ACTIVE DRUG'),
              isTrue,
              reason: 'Message must cite Anticoagulant for ${drugA.id} + ${drugB.id}',
            );
          }
        }

        expect(failures, isEmpty, reason: 'Failed Oral Anticoagulant pairs: $failures');
        expect(pairsTested, equals(oacDrugs.length * (oacDrugs.length - 1)));
      });

      test('Dual Parenteral Anticoagulant (Heparin + Enoxaparin) triggers Hard Duplication Alert', () {
        final heparin = DrugDatabase.findById('heparin')!;
        final enoxaparin = DrugDatabase.findById('enoxaparin')!;

        final warning = TherapeuticDuplicationService.checkDuplication(heparin, enoxaparin);
        expect(warning, isNotNull);
        expect(warning!.severity, equals(LimitSeverity.hard));
        expect(warning.code, equals(DoseWarningCode.therapeuticDuplication));
        expect(warning.messageEn, contains('parenteral anticoagulants'));
      });
    });

    // =========================================================================
    // 5. Dual Statins All Combination Pairs
    // =========================================================================
    group('5. Dual Statins All Combination Pairs (Simvastatin, Atorvastatin, Rosuvastatin, Pravastatin, Lovastatin)', () {
      final statinDrugs = <Drug>[
        DrugDatabase.findById('simvastatin')!,
        DrugDatabase.findById('atorvastatin')!,
        DrugDatabase.findById('rosuvastatin')!,
        const Drug(
          id: 'pravastatin',
          genericName: 'Pravastatin',
          category: DrugCategory.cardiovascular,
          drugClass: DrugClass.statin,
          regimens: [],
        ),
        const Drug(
          id: 'lovastatin',
          genericName: 'Lovastatin',
          category: DrugCategory.cardiovascular,
          drugClass: DrugClass.statin,
          regimens: [],
        ),
        // Statin with null drugClass testing DrugOntology fallback
        const Drug(
          id: 'simvastatin',
          genericName: 'Simvastatin (Ontology Fallback)',
          category: DrugCategory.cardiovascular,
          drugClass: null,
          regimens: [],
        ),
      ];

      test('All combination pairs of Statins trigger Dual Statin warning with 0 false negatives', () {
        int pairsTested = 0;
        final failures = <String>[];

        for (int i = 0; i < statinDrugs.length; i++) {
          for (int j = 0; j < statinDrugs.length; j++) {
            if (i == j) continue;
            final drugA = statinDrugs[i];
            final drugB = statinDrugs[j];

            pairsTested++;
            final warning = TherapeuticDuplicationService.checkDuplication(drugA, drugB);

            if (warning == null) {
              failures.add('Missing warning for ${drugA.id} + ${drugB.id}');
              continue;
            }

            expect(warning.severity, equals(LimitSeverity.hard),
                reason: 'Severity must be hard for ${drugA.id} + ${drugB.id}');
            expect(warning.code, equals(DoseWarningCode.therapeuticDuplication),
                reason: 'Code must be therapeuticDuplication for ${drugA.id} + ${drugB.id}');
            expect(
              warning.messageEn.contains('statins') || warning.messageEn.contains('DUPLICATE ACTIVE DRUG'),
              isTrue,
              reason: 'Message must cite statins for ${drugA.id} + ${drugB.id}',
            );
          }
        }

        expect(failures, isEmpty, reason: 'Failed Statin pairs: $failures');
        expect(pairsTested, equals(statinDrugs.length * (statinDrugs.length - 1)));
      });

      test('PharmacistCalculator Dual Statin: Atorvastatin prescribed with active Simvastatin', () {
        final atorvastatin = DrugDatabase.findById('atorvastatin')!;
        const patient = Patient(
          id: 'p-statin-test',
          weightKg: 70.0,
          heightCm: 175.0,
          ageYears: 55,
          sex: Sex.male,
          isScrStable: true,
          activeDrugIds: ['simvastatin'],
        );

        final result = PharmacistCalculator.calculateDose(
          patient: patient,
          drug: atorvastatin,
          regimen: atorvastatin.regimens.first,
        );

        final dupWarnings = result.warnings.where(
          (w) => w.code == DoseWarningCode.therapeuticDuplication &&
              w.severity == LimitSeverity.hard &&
              w.messageEn.contains('statins'),
        );
        expect(dupWarnings, isNotEmpty);
      });
    });

    // =========================================================================
    // 6. Dual Potassium-Sparing Diuretics All Combination Pairs
    // =========================================================================
    group('6. Dual Potassium-Sparing Diuretics (Spironolactone, Eplerenone, Amiloride)', () {
      final kSparingDrugs = <Drug>[
        DrugDatabase.findById('spironolactone')!,
        const Drug(
          id: 'eplerenone',
          genericName: 'Eplerenone',
          category: DrugCategory.cardiovascular,
          drugClass: DrugClass.potassiumSparingDiuretic,
          regimens: [],
        ),
        const Drug(
          id: 'amiloride',
          genericName: 'Amiloride',
          category: DrugCategory.cardiovascular,
          drugClass: DrugClass.potassiumSparingDiuretic,
          regimens: [],
        ),
        // Eplerenone with null drugClass testing DrugOntology fallback
        const Drug(
          id: 'eplerenone',
          genericName: 'Eplerenone (Ontology Fallback)',
          category: DrugCategory.cardiovascular,
          drugClass: null,
          regimens: [],
        ),
      ];

      test('All combination pairs of Potassium-Sparing Diuretics trigger Dual Potassium-Sparing warning with 0 false negatives', () {
        int pairsTested = 0;
        final failures = <String>[];

        for (int i = 0; i < kSparingDrugs.length; i++) {
          for (int j = 0; j < kSparingDrugs.length; j++) {
            if (i == j) continue;
            final drugA = kSparingDrugs[i];
            final drugB = kSparingDrugs[j];

            pairsTested++;
            final warning = TherapeuticDuplicationService.checkDuplication(drugA, drugB);

            if (warning == null) {
              failures.add('Missing warning for ${drugA.id} + ${drugB.id}');
              continue;
            }

            expect(warning.severity, equals(LimitSeverity.hard),
                reason: 'Severity must be hard for ${drugA.id} + ${drugB.id}');
            expect(warning.code, equals(DoseWarningCode.therapeuticDuplication),
                reason: 'Code must be therapeuticDuplication for ${drugA.id} + ${drugB.id}');
            expect(
              warning.messageEn.contains('potassium-sparing') || warning.messageEn.contains('DUPLICATE ACTIVE DRUG'),
              isTrue,
              reason: 'Message must cite potassium-sparing for ${drugA.id} + ${drugB.id}',
            );
          }
        }

        expect(failures, isEmpty, reason: 'Failed Potassium-Sparing pairs: $failures');
        expect(pairsTested, equals(kSparingDrugs.length * (kSparingDrugs.length - 1)));
      });

      test('PharmacistCalculator Dual Potassium-Sparing: Spironolactone prescribed with active Eplerenone', () {
        final spironolactone = DrugDatabase.findById('spironolactone')!;
        const patient = Patient(
          id: 'p-ksparing-test',
          weightKg: 70.0,
          heightCm: 175.0,
          ageYears: 65,
          sex: Sex.male,
          isScrStable: true,
          activeDrugIds: ['eplerenone'],
        );

        final result = PharmacistCalculator.calculateDose(
          patient: patient,
          drug: spironolactone,
          regimen: spironolactone.regimens.first,
        );

        final dupWarnings = result.warnings.where(
          (w) => w.code == DoseWarningCode.therapeuticDuplication &&
              w.severity == LimitSeverity.hard &&
              w.messageEn.contains('potassium-sparing'),
        );
        expect(dupWarnings, isNotEmpty);
      });
    });

    // =========================================================================
    // 7. Zero False Positive Check: Clinically Valid Combinations
    // =========================================================================
    group('7. Zero False Positive Check: Clinically Valid Multi-Drug Combinations', () {
      test('Legitimate cross-class regimens must NOT trigger therapeutic duplication warning', () {
        final validPairs = <List<String>>[
          ['paracetamol', 'ibuprofen'],        // Analgesic + NSAID
          ['enalapril', 'amlodipine'],         // ACEI + CCB
          ['losartan', 'hydrochlorothiazide'], // ARB + Thiazide
          ['atorvastatin', 'metformin'],       // Statin + Biguanide
          ['warfarin', 'paracetamol'],         // OAC + Analgesic
          ['ceftriaxone', 'azithromycin'],     // Cephalosporin + Macrolide (CAP regimen)
          ['meropenem', 'vancomycin'],         // Carbapenem + Glycopeptide (Febrile Neutropenia)
          ['furosemide', 'spironolactone'],    // Loop + K-sparing (Heart Failure / Cirrhosis Ascites)
          ['omeprazole', 'clarithromycin'],    // PPI + Macrolide (H. pylori eradication)
          ['aspirin', 'clopidogrel'],          // Dual Antiplatelet (DAPT - antiplatelet, not OAC)
        ];

        for (final pair in validPairs) {
          final drugA = DrugDatabase.findById(pair[0]) ??
              Drug(id: pair[0], genericName: pair[0], category: DrugCategory.other, regimens: const []);
          final drugB = DrugDatabase.findById(pair[1]) ??
              Drug(id: pair[1], genericName: pair[1], category: DrugCategory.other, regimens: const []);

          final warning = TherapeuticDuplicationService.checkDuplication(drugA, drugB);
          expect(
            warning,
            isNull,
            reason: 'Legitimate combination ${pair[0]} + ${pair[1]} falsely triggered duplication: ${warning?.messageEn}',
          );
        }
      });
    });

    // =========================================================================
    // 8. PrescriptionCart Multi-Drug Duplication Detection
    // =========================================================================
    group('8. PrescriptionCart Multi-Drug Duplication Detection', () {
      test('PrescriptionCart detects duplication when two contraindicated drugs are in cart', () {
        final cart = PrescriptionCart.instance;
        cart.clearCart();

        final simva = DrugDatabase.findById('simvastatin')!;
        final atorva = DrugDatabase.findById('atorvastatin')!;

        cart.addDrug(simva);
        expect(cart.checkInteractions(false), isEmpty);

        cart.addDrug(atorva);
        final warnings = cart.checkInteractions(false);
        expect(
          warnings.any((w) => w.contains('statins') || w.contains('DUPLICATE')),
          isTrue,
          reason: 'PrescriptionCart failed to detect dual statin in cart: $warnings',
        );

        cart.clearCart();
      });
    });

    // =========================================================================
    // 9. Boundary Distinction: DDI vs Therapeutic Duplication
    // =========================================================================
    group('9. Boundary Distinction: DDI vs Therapeutic Duplication', () {
      test('Drug-Drug Interactions (different classes) must NOT be misclassified as Therapeutic Duplication', () {
        final ddiPairs = <List<String>>[
          ['methotrexate', 'ibuprofen'],    // MTX + NSAID
          ['enalapril', 'spironolactone'],  // ACEI + K-sparing
          ['enalapril', 'ibuprofen'],       // ACEI + NSAID
          ['clopidogrel', 'omeprazole'],    // Antiplatelet + PPI
          ['simvastatin', 'clarithromycin'],// Statin + Macrolide
          ['digoxin', 'amiodarone'],        // Digoxin + P-gp inhibitor
          ['warfarin', 'ibuprofen'],        // OAC + NSAID
          ['spironolactone', 'potassium_chloride'], // K-sparing + KCl
          ['lithium', 'ibuprofen'],         // Lithium + NSAID
        ];

        for (final pair in ddiPairs) {
          final drugA = DrugDatabase.findById(pair[0]) ??
              Drug(
                id: pair[0],
                genericName: pair[0],
                category: DrugCategory.other,
                drugClass: DrugOntology.resolveDrugClass(pair[0], null, null),
                regimens: const [],
              );
          final drugB = DrugDatabase.findById(pair[1]) ??
              Drug(
                id: pair[1],
                genericName: pair[1],
                category: DrugCategory.other,
                drugClass: DrugOntology.resolveDrugClass(pair[1], null, null),
                regimens: const [],
              );

          // 1. Therapeutic Duplication must be NULL
          final dupWarning = TherapeuticDuplicationService.checkDuplication(drugA, drugB);
          expect(
            dupWarning,
            isNull,
            reason: 'DDI pair ${pair[0]} + ${pair[1]} must not trigger therapeutic duplication: ${dupWarning?.messageEn}',
          );

          // 2. Clinical Interaction Registry must detect the interaction
          final ddiWarnings = ClinicalInteractionRegistry.checkInteractions(drugA, drugB);
          expect(
            ddiWarnings,
            isNotEmpty,
            reason: 'DDI pair ${pair[0]} + ${pair[1]} should be detected by ClinicalInteractionRegistry',
          );
        }
      });
    });

    // =========================================================================
    // 10. Commutative Symmetry Invariance Test
    // =========================================================================
    group('10. Commutative Symmetry Invariance (checkDuplication(A, B) <=> checkDuplication(B, A))', () {
      test('Duplication detection is symmetric for all contraindicated class combinations', () {
        final candidateDrugs = <Drug>[
          DrugDatabase.findById('ibuprofen')!,
          DrugDatabase.findById('naproxen')!,
          DrugDatabase.findById('enalapril')!,
          DrugDatabase.findById('losartan')!,
          DrugDatabase.findById('warfarin')!,
          DrugDatabase.findById('apixaban')!,
          DrugDatabase.findById('rivaroxaban')!,
          DrugDatabase.findById('simvastatin')!,
          DrugDatabase.findById('atorvastatin')!,
          DrugDatabase.findById('spironolactone')!,
        ];

        for (int i = 0; i < candidateDrugs.length; i++) {
          for (int j = 0; j < candidateDrugs.length; j++) {
            final a = candidateDrugs[i];
            final b = candidateDrugs[j];

            final warnAB = TherapeuticDuplicationService.checkDuplication(a, b);
            final warnBA = TherapeuticDuplicationService.checkDuplication(b, a);

            if (warnAB == null) {
              expect(warnBA, isNull,
                  reason: 'Asymmetry detected: checkDuplication(${a.id}, ${b.id}) is null but checkDuplication(${b.id}, ${a.id}) is not null');
            } else {
              expect(warnBA, isNotNull,
                  reason: 'Asymmetry detected: checkDuplication(${a.id}, ${b.id}) produced warning but checkDuplication(${b.id}, ${a.id}) was null');
              expect(warnAB.severity, equals(warnBA!.severity),
                  reason: 'Severity mismatch in symmetry for ${a.id} <-> ${b.id}');
              expect(warnAB.code, equals(warnBA.code),
                  reason: 'Code mismatch in symmetry for ${a.id} <-> ${b.id}');
            }
          }
        }
      });
    });

    // =========================================================================
    // 11. Extended Same-Class Contraindications
    // =========================================================================
    group('11. Extended Same-Class Duplications in TherapeuticDuplicationService', () {
      test('All other duplicate classes in TherapeuticDuplicationService trigger Hard warning', () {
        final classPairs = <Map<String, dynamic>>[
          {
            'name': 'Dual Loop Diuretics',
            'a': const Drug(id: 'furosemide', genericName: 'Furosemide', category: DrugCategory.cardiovascular, drugClass: DrugClass.loopDiuretic, regimens: []),
            'b': const Drug(id: 'torsemide', genericName: 'Torsemide', category: DrugCategory.cardiovascular, drugClass: DrugClass.loopDiuretic, regimens: []),
            'token': 'loop diuretics',
          },
          {
            'name': 'Dual SSRIs',
            'a': const Drug(id: 'fluoxetine', genericName: 'Fluoxetine', category: DrugCategory.psychiatric, drugClass: DrugClass.ssri, regimens: []),
            'b': const Drug(id: 'sertraline', genericName: 'Sertraline', category: DrugCategory.psychiatric, drugClass: DrugClass.ssri, regimens: []),
            'token': 'SSRIs',
          },
          {
            'name': 'Dual Opioids',
            'a': const Drug(id: 'morphine', genericName: 'Morphine', category: DrugCategory.opioid, drugClass: DrugClass.opioid, regimens: []),
            'b': const Drug(id: 'fentanyl', genericName: 'Fentanyl', category: DrugCategory.opioid, drugClass: DrugClass.opioid, regimens: []),
            'token': 'opioids',
          },
          {
            'name': 'Dual Benzodiazepines',
            'a': const Drug(id: 'diazepam', genericName: 'Diazepam', category: DrugCategory.neurological, drugClass: DrugClass.benzodiazepine, regimens: []),
            'b': const Drug(id: 'lorazepam', genericName: 'Lorazepam', category: DrugCategory.neurological, drugClass: DrugClass.benzodiazepine, regimens: []),
            'token': 'benzodiazepines',
          },
          {
            'name': 'Dual Beta-Blockers',
            'a': const Drug(id: 'metoprolol', genericName: 'Metoprolol', category: DrugCategory.cardiovascular, drugClass: DrugClass.betaBlocker, regimens: []),
            'b': const Drug(id: 'propranolol', genericName: 'Propranolol', category: DrugCategory.cardiovascular, drugClass: DrugClass.betaBlocker, regimens: []),
            'token': 'beta-blockers',
          },
          {
            'name': 'Dual PPIs',
            'a': const Drug(id: 'omeprazole', genericName: 'Omeprazole', category: DrugCategory.gastrointestinal, drugClass: DrugClass.protonPumpInhibitor, regimens: []),
            'b': const Drug(id: 'pantoprazole', genericName: 'Pantoprazole', category: DrugCategory.gastrointestinal, drugClass: DrugClass.protonPumpInhibitor, regimens: []),
            'token': 'proton pump inhibitors',
          },
          {
            'name': 'Dual Sulfonylureas',
            'a': const Drug(id: 'glipizide', genericName: 'Glipizide', category: DrugCategory.endocrine, drugClass: DrugClass.sulfonylurea, regimens: []),
            'b': const Drug(id: 'glibenclamide', genericName: 'Glibenclamide', category: DrugCategory.endocrine, drugClass: DrugClass.sulfonylurea, regimens: []),
            'token': 'sulfonylureas',
          },
          {
            'name': 'Dual DPP-4 Inhibitors',
            'a': const Drug(id: 'sitagliptin', genericName: 'Sitagliptin', category: DrugCategory.endocrine, drugClass: DrugClass.dpp4Inhibitor, regimens: []),
            'b': const Drug(id: 'linagliptin', genericName: 'Linagliptin', category: DrugCategory.endocrine, drugClass: DrugClass.dpp4Inhibitor, regimens: []),
            'token': 'DPP-4 inhibitors',
          },
          {
            'name': 'Dual SGLT2 Inhibitors',
            'a': const Drug(id: 'empagliflozin', genericName: 'Empagliflozin', category: DrugCategory.endocrine, drugClass: DrugClass.sglt2Inhibitor, regimens: []),
            'b': const Drug(id: 'dapagliflozin', genericName: 'Dapagliflozin', category: DrugCategory.endocrine, drugClass: DrugClass.sglt2Inhibitor, regimens: []),
            'token': 'SGLT2 inhibitors',
          },
          {
            'name': 'Dual Thiazide Diuretics',
            'a': const Drug(id: 'hydrochlorothiazide', genericName: 'Hydrochlorothiazide', category: DrugCategory.cardiovascular, drugClass: DrugClass.thiazideDiuretic, regimens: []),
            'b': const Drug(id: 'indapamide', genericName: 'Indapamide', category: DrugCategory.cardiovascular, drugClass: DrugClass.thiazideDiuretic, regimens: []),
            'token': 'thiazide diuretics',
          },
        ];

        for (final item in classPairs) {
          final drugA = item['a'] as Drug;
          final drugB = item['b'] as Drug;
          final token = item['token'] as String;

          final warning = TherapeuticDuplicationService.checkDuplication(drugA, drugB);
          expect(warning, isNotNull, reason: 'Failed to detect ${item['name']}');
          expect(warning!.severity, equals(LimitSeverity.hard));
          expect(warning.code, equals(DoseWarningCode.therapeuticDuplication));
          expect(warning.messageEn.toLowerCase(), contains(token.toLowerCase()));
        }
      });
    });

    // =========================================================================
    // 12. Complex Polypharmacy Regimen Test
    // =========================================================================
    group('12. Complex Polypharmacy Regimen Stress Test', () {
      test('Prescribing Apixaban to a patient with 5 concurrent cardiovascular medications triggers Dual Anticoagulant', () {
        const complexPatient = Patient(
          id: 'polypharmacy-pt',
          weightKg: 75.0,
          heightCm: 172.0,
          ageYears: 68,
          sex: Sex.male,
          serumCreatinineMgDl: 1.1,
          isScrStable: true,
          activeDrugIds: [
            'losartan',       // ARB
            'spironolactone', // K-sparing
            'atorvastatin',   // Statin
            'furosemide',     // Loop diuretic
            'warfarin',       // Oral anticoagulant VKA
          ],
        );

        final apixaban = DrugDatabase.findById('apixaban')!;
        final result = PharmacistCalculator.calculateDose(
          patient: complexPatient,
          drug: apixaban,
          regimen: apixaban.regimens.first,
        );

        // Must catch warfarin duplication
        final dupWarnings = result.warnings.where(
          (w) => w.code == DoseWarningCode.therapeuticDuplication &&
              w.severity == LimitSeverity.hard &&
              w.messageEn.contains('Anticoagulant'),
        );

        expect(dupWarnings, isNotEmpty,
            reason: 'Failed to identify Warfarin + Apixaban duplication in polypharmacy cocktail');
      });
    });
  });
}
