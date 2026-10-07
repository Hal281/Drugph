// ============================================================
// Drug Dosage Calculator — Special Dose Rule Model (F6)
// ============================================================
// Pure declarative clinical rules attached to drug entities.
// Replaces hardcoded drug ID branches in PharmacistCalculator.
//
// DISCLAIMER: SaMD prototype — not for clinical use.
// ============================================================

import 'patient.dart';
import 'drug.dart';
import 'dose_limit.dart';

/// Context provided to a [DoseRule] for condition evaluation.
class DoseRuleContext {
  final Patient patient;
  final Drug drug;
  final DosingRegimen regimen;
  final double currentDose;
  final Frequency currentFrequency;
  final double? crclMlMin;

  const DoseRuleContext({
    required this.patient,
    required this.drug,
    required this.regimen,
    required this.currentDose,
    required this.currentFrequency,
    this.crclMlMin,
  });
}

/// The result returned when a [DoseRule] triggers.
class DoseRuleResult {
  final double? modifiedDose;
  final Frequency? modifiedFrequency;
  final bool isDoseModified;
  final bool isRenallyAdjusted;
  final String? modificationReasonEn;
  final String? modificationReasonTh;
  final List<DoseWarning> warnings;

  const DoseRuleResult({
    this.modifiedDose,
    this.modifiedFrequency,
    this.isDoseModified = false,
    this.isRenallyAdjusted = false,
    this.modificationReasonEn,
    this.modificationReasonTh,
    this.warnings = const [],
  });
}

/// A guideline-defined special dosing rule (F6).
///
/// Encapsulates clinical conditions, actions, bibliographic source, and verification status.
/// Examples:
/// - Apixaban 2-of-3 dose reduction criteria (Age >= 80, Weight <= 60 kg, SCr >= 1.5 mg/dL)
/// - Carboplatin severe renal impairment advisory (CrCl < 15 mL/min)
/// - Vancomycin ESRD / hemodialysis pulse dosing advisory (CrCl < 10 mL/min)
class DoseRule {
  final String id;
  final String name;
  final bool Function(DoseRuleContext context) applies;
  final DoseRuleResult Function(DoseRuleContext context) evaluate;
  final String sourceCitation;
  final VerificationStatus verificationStatus;

  const DoseRule({
    required this.id,
    required this.name,
    required this.applies,
    required this.evaluate,
    required this.sourceCitation,
    this.verificationStatus = VerificationStatus.verified,
  });
}
