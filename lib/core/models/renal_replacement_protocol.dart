// ============================================================
// Drug Dosage Calculator — Renal Replacement Protocol Model
// ============================================================
// Evidence-based dosing protocols for patients on RRT (IHD, CAPD, CRRT).
// Grounded in The Sanford Guide 2024 Table 10B, Lexicomp, and KDIGO.
//
// Zero Flutter UI dependency, 100% pure Dart.
// ============================================================

import 'frequency.dart';
import 'provenance.dart';
import 'renal_adjustment.dart';
import 'renal_replacement_mode.dart';
import 'unit.dart';

/// Structured evidence-based dosing protocol for an RRT modality.
class RenalReplacementProtocol {
  /// The specific RRT modality this protocol applies to (IHD, CAPD, CRRT).
  final RenalReplacementMode mode;

  /// Clinical action required (adjust, avoid, contraindicated, monitorOnly).
  final RenalAction action;

  /// Proportional multiplier relative to standard dose (e.g. 0.5 = 50% dose).
  final double? doseFactor;

  /// Specific absolute dose override in drug's unit (e.g. 500.0 mg or 1000.0 mg).
  final double? specificDose;

  /// Optional explicit unit of [specificDose].
  final DoseUnit? doseUnit;

  /// Structured frequency override for this RRT modality (e.g. Frequency.q24h).
  final Frequency? frequency;

  /// Whether administration must be timed post-hemodialysis or supplemental dose given.
  final bool requiresPostHdSupplement;

  /// Clinical instruction and administration timing in English.
  final String? clinicalInstructionEn;

  /// Clinical instruction and administration timing in Thai.
  final String? clinicalInstructionTh;

  /// Provenance and textbook citation for this RRT protocol.
  final Provenance? provenance;

  const RenalReplacementProtocol({
    required this.mode,
    this.action = RenalAction.adjust,
    this.doseFactor,
    this.specificDose,
    this.doseUnit,
    this.frequency,
    this.requiresPostHdSupplement = false,
    this.clinicalInstructionEn,
    this.clinicalInstructionTh,
    this.provenance,
  }) : assert(
          mode != RenalReplacementMode.none,
          'RenalReplacementProtocol cannot be configured for mode.none',
        );

  @override
  String toString() =>
      'RenalReplacementProtocol(${mode.badgeEn}: dose=${specificDose ?? doseFactor}, freq=${frequency?.displayEn}, postHD=$requiresPostHdSupplement)';
}
