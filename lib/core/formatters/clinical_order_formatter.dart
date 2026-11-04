// ============================================================
// Drug Dosage Calculator — Clinical Order & Note Formatter
// ============================================================
// Pure deterministic formatting for hospital electronic orders (HIS)
// and clinical pharmacist progress notes.
//
// Zero Flutter UI dependency, zero runtime AI/LLM, zero external SDKs.
// Strict Evidence-Based Medicine (Sanford Guide, Lexicomp, Ramathibodi).
// ============================================================

import '../models/models.dart';
import '../calculators/bsa_calculator.dart';

/// Pure deterministic formatter producing concise single-line physician
/// medication orders (for Hospital Information Systems / HIS) and structured
/// multi-line clinical progress notes (for pharmacist consultation sheets).
class ClinicalOrderFormatter {
  const ClinicalOrderFormatter._();

  /// Overdose warning codes that mandate appending an overdose tag (Ironclad Rule 5).
  static const Set<DoseWarningCode> overdoseWarningCodes = {
    DoseWarningCode.maxSingleDoseExceeded,
    DoseWarningCode.softMaxSingleDoseExceeded,
    DoseWarningCode.maxDailyDoseExceeded,
    DoseWarningCode.maxDosePerKgPerDayExceeded,
    DoseWarningCode.maxInfusionRateExceeded,
    DoseWarningCode.doseCappedAtMax,
  };

  /// Formats a concise, single-line physician medication order suitable for
  /// direct entry into Hospital Information Systems (HIS / CPOE).
  ///
  /// Output structure:
  /// `[Drug Generic Name] [Dose + Unit] [Route] [Infusion Duration if applicable] [Frequency] [Pump Rate if continuous] [Renal Adjustment Tag] [Safety Tags]`
  static String formatHisOrder({
    required Patient patient,
    required Drug drug,
    required DosingRegimen regimen,
    required DosageResult result,
    bool isThai = false,
  }) {
    final buffer = StringBuffer();

    // 1. Drug Generic Name
    buffer.write(drug.genericName);

    // 2. Continuous / Titrated IV Infusion vs Standard Intermittent/Fixed Dose
    if (result.infusionResult != null) {
      final inf = result.infusionResult!;
      final rateStr = inf.rateMax != null
          ? '${_formatNumber(inf.rate)}-${_formatNumber(inf.rateMax!)} ${inf.rateUnit.symbol}'
          : '${_formatNumber(inf.rate)} ${inf.rateUnit.symbol}';
      buffer.write(' $rateStr');

      // Route
      final routeStr = _formatRoute(regimen.route, isContinuous: true);
      buffer.write(' $routeStr');

      // Pump Rate in mL/hr
      if (inf.rateMlPerHr != null) {
        final pumpStr = inf.rateMlPerHrMax != null
            ? '${_formatNumber(inf.rateMlPerHr!)}-${_formatNumber(inf.rateMlPerHrMax!)} mL/hr'
            : '${inf.rateMlPerHr!.toStringAsFixed(1)} mL/hr';
        buffer.write(' (Pump rate: $pumpStr)');
      } else if (result.infusionRateMlPerHr != null) {
        buffer.write(
            ' (Pump rate: ${result.infusionRateMlPerHr!.toStringAsFixed(1)} mL/hr)');
      }
    } else {
      // Standard fixed / weight-based dose
      final dose = result.roundedDose ?? result.calculatedDose;
      final doseStr = dose != null ? _formatNumber(dose) : 'N/A';
      final unitStr = result.doseUnit?.symbol ?? regimen.doseUnit.symbol;
      buffer.write(' $doseStr $unitStr');

      // Route
      final routeStr = _formatRoute(regimen.route, isContinuous: false);
      buffer.write(' $routeStr');

      // Infusion duration if non-null
      final duration =
          result.infusionDurationMinutes ?? regimen.infusionTimeMinutes;
      if (duration != null) {
        buffer.write(' (infuse over ${_formatNumber(duration)} min)');
      }

      // Frequency
      final freq =
          result.adjustedFrequency ?? result.frequency ?? regimen.frequency.displayEn;
      if (freq.isNotEmpty) {
        buffer.write(' $freq');
      }
    }

    // 3. RRT mode & Post-HD Tag (M1)
    final rrtMode = result.renalReplacementMode != RenalReplacementMode.none
        ? result.renalReplacementMode
        : patient.renalReplacementMode;
    if (rrtMode.isRrt) {
      if (rrtMode == RenalReplacementMode.crrt) {
        buffer.write(' [CRRT]');
      } else if (rrtMode == RenalReplacementMode.ihd) {
        buffer.write(result.requiresPostHdSupplement
            ? ' [IHD: Post-HD Dosing]'
            : ' [IHD]');
      } else if (rrtMode == RenalReplacementMode.capd) {
        buffer.write(' [CAPD]');
      }
    }

    // 4. Renal-adjusted regimen tag
    if (result.isRenallyAdjusted) {
      final crcl = result.crclMlMin ?? patient.creatinineClearanceMlMin;
      final citation = _extractCitation(drug, regimen);
      if (crcl != null && citation != null) {
        buffer.write(' [Renal adjusted: CrCl ${crcl.toStringAsFixed(1)} mL/min; $citation]');
      } else if (crcl != null) {
        buffer.write(' [Renal adjusted: CrCl ${crcl.toStringAsFixed(1)} mL/min]');
      } else if (citation != null) {
        buffer.write(' [Renal adjusted; $citation]');
      } else {
        buffer.write(' [Renal adjusted]');
      }
    }

    // 4. Overdose warning tag
    final hasOverdose = result.warnings.any((w) => overdoseWarningCodes.contains(w.code));
    if (hasOverdose) {
      buffer.write(' [⚠️ OVERDOSE WARNING: Dose exceeds recommended limits]');
    }

    // 5. Unverified regimen tag
    final isUnverified = result.verificationStatus == VerificationStatus.unverified ||
        regimen.verificationStatus == VerificationStatus.unverified;
    if (isUnverified) {
      buffer.write(' [⚠️ UNVERIFIED REGIMEN]');
    }

    return buffer.toString().trim();
  }

  /// Formats a structured, multi-line clinical pharmacist consultation / progress note
  /// covering patient parameters, medication & regimen, calculation & administration,
  /// textbook provenance & verification status, and safety alerts.
  static String formatPharmacistNote({
    required Patient patient,
    required Drug drug,
    required DosingRegimen regimen,
    required DosageResult result,
    bool isThai = false,
  }) {
    final buf = StringBuffer();

    // 1. Header
    buf.writeln('==================================================');
    buf.writeln('CLINICAL PHARMACIST DOSING NOTE');
    buf.writeln('==================================================');

    // 2. Patient Parameters
    final secPatient = isThai
        ? '1. ข้อมูลผู้ป่วย (Patient Parameters)'
        : '1. PATIENT PARAMETERS';
    buf.writeln(secPatient);

    final ageStr = patient.ageMonths != null && patient.ageMonths! > 0
        ? '${patient.ageYears}y ${patient.ageMonths}m'
        : '${patient.ageYears} years';
    final sexDisplay = isThai
        ? '${patient.sex.nameTh} (${patient.sex.nameEn})'
        : patient.sex.nameEn;
    buf.writeln('  • Age: $ageStr | Sex: $sexDisplay');

    final wtBuf = StringBuffer('TBW: ${_formatNumber(patient.weightKg)} kg');
    if (result.ibwKg != null) {
      wtBuf.write(' | IBW: ${_formatNumber(result.ibwKg!)} kg');
    }
    if (result.adjBwKg != null) {
      wtBuf.write(' | AdjBW: ${_formatNumber(result.adjBwKg!)} kg');
    }
    final dosingWt = result.calculationInputs['dosingWeightUsedKg'] as num?;
    final wtStrat = result.calculationInputs['weightStrategy'] as String?;
    if (dosingWt != null && wtStrat != null && wtStrat != 'TBW') {
      wtBuf.write(' | Dosing Weight: ${_formatNumber(dosingWt.toDouble())} kg ($wtStrat)');
    }
    buf.writeln('  • Weight: $wtBuf');
    buf.writeln('  • Height: ${_formatNumber(patient.heightCm)} cm');

    // BSA
    final bsa = result.bsaM2 ?? _computeBsa(patient.weightKg, patient.heightCm);
    buf.writeln('  • BSA: ${bsa.toStringAsFixed(2)} m²');

    // Renal Function
    final scrStr = patient.serumCreatinineMgDl != null
        ? '${patient.serumCreatinineMgDl!.toStringAsFixed(2)} mg/dL'
        : 'Not documented';
    final scrStability = patient.isScrStable ? 'Stable' : 'Unstable / AKI';
    final crcl = result.crclMlMin ?? patient.creatinineClearanceMlMin;
    final crclStr = crcl != null
        ? '${crcl.toStringAsFixed(1)} mL/min (Cockcroft-Gault)'
        : 'Not available';
    buf.writeln('  • Renal Function: SCr $scrStr ($scrStability) | CrCl: $crclStr');

    final rrtMode = result.renalReplacementMode != RenalReplacementMode.none
        ? result.renalReplacementMode
        : patient.renalReplacementMode;
    if (rrtMode.isRrt) {
      final rrtName = isThai ? rrtMode.labelTh : rrtMode.labelEn;
      final postHd = result.requiresPostHdSupplement
          ? (isThai
              ? ' | กำหนดเวลาบริหารยา: หลังฟอกเลือด (Post-HD Dosing Required)'
              : ' | Post-HD Dosing Required')
          : '';
      buf.writeln('  • Renal Replacement Therapy: $rrtName$postHd');
    }

    // Allergies
    final allergyStr = patient.allergies.isNotEmpty
        ? patient.allergies.join(', ')
        : 'NKDA (No Known Drug Allergies)';
    buf.writeln('  • Allergies: $allergyStr');

    // Pregnancy / Hepatic status
    final pregStr = patient.isPregnant ? 'Pregnant' : 'Non-pregnant';
    final hepStr = patient.hepaticImpairment != null
        ? 'Child-Pugh Class ${patient.hepaticImpairment!.name.toUpperCase()}'
        : 'Normal / Not assessed';
    buf.writeln('  • Clinical Status: $pregStr | Hepatic: $hepStr');
    buf.writeln();

    // 3. Medication & Regimen
    final secDrug = isThai
        ? '2. ยาและข้อบ่งใช้ (Medication & Regimen)'
        : '2. MEDICATION & REGIMEN';
    buf.writeln(secDrug);

    final thaiName = drug.nameTh != null && drug.nameTh!.isNotEmpty
        ? ' (${drug.nameTh})'
        : '';
    buf.writeln('  • Drug: ${drug.genericName}$thaiName');
    buf.writeln('  • Route: ${regimen.route.nameEn} (${regimen.route.abbreviation})');
    buf.writeln('  • Indication: ${regimen.indication ?? "Standard Dosing"}');
    buf.writeln('  • Calculation Type: ${regimen.dosingType.nameEn}');
    buf.writeln();

    // 4. Dosing Calculation & Administration
    final secDose = isThai
        ? '3. การคำนวณและบริหารยา (Dosing Calculation & Administration)'
        : '3. DOSING CALCULATION & ADMINISTRATION';
    buf.writeln(secDose);

    if (result.infusionResult != null) {
      final inf = result.infusionResult!;
      final rateStr = inf.rateMax != null
          ? '${_formatNumber(inf.rate)}-${_formatNumber(inf.rateMax!)} ${inf.rateUnit.symbol}'
          : '${_formatNumber(inf.rate)} ${inf.rateUnit.symbol}';
      buf.writeln('  • Infusion Rate: $rateStr');
      if (inf.rateMlPerHr != null) {
        final pumpStr = inf.rateMlPerHrMax != null
            ? '${inf.rateMlPerHr!.toStringAsFixed(1)}-${inf.rateMlPerHrMax!.toStringAsFixed(1)} mL/hr'
            : '${inf.rateMlPerHr!.toStringAsFixed(1)} mL/hr';
        buf.writeln('  • Pump Rate: $pumpStr');
      }
      if (regimen.standardDilution != null) {
        buf.writeln('  • Dilution: ${regimen.standardDilution}');
      } else if (regimen.standardDilutionMgPerMl != null) {
        buf.writeln(
            '  • Dilution: ${_formatNumber(regimen.standardDilutionMgPerMl!)} mg/mL');
      }
      if (inf.instructionsEn != null) {
        final instr = isThai && inf.instructionsTh != null
            ? inf.instructionsTh!
            : inf.instructionsEn!;
        buf.writeln('  • Administration Instructions: $instr');
      }
    } else {
      if (result.roundedDose != null) {
        buf.writeln(
            '  • Recommended Dose (Rounded): ${_formatNumber(result.roundedDose!)} ${result.doseUnit?.symbol ?? regimen.doseUnit.symbol}');
        if (result.calculatedDose != null) {
          buf.writeln(
              '  • Calculated Raw Dose: ${_formatNumber(result.calculatedDose!)} ${result.doseUnit?.symbol ?? regimen.doseUnit.symbol}');
        }
      } else if (result.calculatedDose != null) {
        buf.writeln(
            '  • Recommended Dose: ${_formatNumber(result.calculatedDose!)} ${result.doseUnit?.symbol ?? regimen.doseUnit.symbol}');
      }
      final freq =
          result.adjustedFrequency ?? result.frequency ?? regimen.frequency.displayEn;
      buf.writeln('  • Frequency: $freq');
      final duration =
          result.infusionDurationMinutes ?? regimen.infusionTimeMinutes;
      if (duration != null) {
        buf.writeln('  • Infusion Duration: ${_formatNumber(duration)} min');
      }
      if (result.dailyDose != null) {
        buf.writeln(
            '  • Total Daily Dose: ${_formatNumber(result.dailyDose!)} ${result.doseUnit?.symbol ?? regimen.doseUnit.symbol}/day');
      }
    }

    // Renal adjustment details
    if (result.isRenallyAdjusted) {
      buf.writeln('  • Renal Adjustment: ACTIVE');
      if (result.renalAdjustmentFactor != null) {
        buf.writeln(
            '    - Adjustment Factor: ${(result.renalAdjustmentFactor! * 100).toStringAsFixed(0)}%');
      }
      if (result.adjustedFrequency != null) {
        buf.writeln(
            '    - Adjusted Frequency: ${result.adjustedFrequency} (Original: ${regimen.frequency.displayEn})');
      }
      if (result.renalNotes != null && result.renalNotes!.isNotEmpty) {
        final rNotes = isThai && result.renalNotesTh != null
            ? result.renalNotesTh!
            : result.renalNotes!;
        buf.writeln('    - Notes: $rNotes');
      }
    } else {
      buf.writeln('  • Renal Adjustment: None (Standard dosing)');
    }
    if (rrtMode.isRrt) {
      buf.writeln('  • RRT Modality: ${rrtMode.badgeEn} (${isThai ? rrtMode.labelTh : rrtMode.labelEn})');
      if (result.requiresPostHdSupplement) {
        buf.writeln(isThai
            ? '    - การบริหารยาเสริมหลังฟอกเลือด: จำเป็น (บริหารยาหลังเสร็จสิ้นการฟอกเลือดในวันที่ฟอกไต)'
            : '    - Administration Timing: Post-hemodialysis dosing (administer dose after dialysis session on dialysis days)');
      }
      if (result.rrtInstructionEn != null || result.renalNotes != null) {
        final instr = isThai && (result.rrtInstructionTh ?? result.renalNotesTh) != null
            ? (result.rrtInstructionTh ?? result.renalNotesTh!)
            : (result.rrtInstructionEn ?? result.renalNotes!);
        buf.writeln('    - RRT Instructions: $instr');
      }
    }
    buf.writeln();

    // 5. Textbook Provenance & Verification
    final secEvidence = isThai
        ? '4. แหล่งอ้างอิงและการรับรอง (Textbook Provenance & Verification)'
        : '4. TEXTBOOK PROVENANCE & VERIFICATION';
    buf.writeln(secEvidence);

    final source = regimen.monograph?.textbookName ??
        regimen.provenance?.source ??
        drug.monograph?.textbookName ??
        drug.provenance?.source ??
        (drug.sourceCitation.isNotEmpty
            ? drug.sourceCitation
            : 'Standard Clinical Formulary');
    final edition = regimen.monograph?.editionYear ??
        drug.monograph?.editionYear ??
        'Current Edition';
    final table = regimen.monograph?.sectionOrTable ??
        regimen.provenance?.sourceDetail ??
        drug.monograph?.sectionOrTable ??
        drug.provenance?.sourceDetail ??
        'Dosing & Administration Monograph';

    final vStatus = (result.verificationStatus == VerificationStatus.unverified ||
            regimen.verificationStatus == VerificationStatus.unverified)
        ? VerificationStatus.unverified
        : regimen.verificationStatus;
    final vStatusStr = switch (vStatus) {
      VerificationStatus.verified => 'VERIFIED',
      VerificationStatus.pendingReview => 'PENDING REVIEW',
      VerificationStatus.unverified => 'UNVERIFIED',
    };

    final reviewer = regimen.provenance?.reviewedBy ??
        drug.provenance?.reviewedBy ??
        'Clinical Pharmacist Review Panel';
    final license =
        regimen.provenance?.reviewerLicense ?? drug.provenance?.reviewerLicense;
    final reviewerFull = license != null ? '$reviewer ($license)' : reviewer;

    buf.writeln('  • Textbook Source: $source');
    buf.writeln('  • Edition / Year: $edition');
    buf.writeln('  • Section / Table: $table');
    buf.writeln('  • Verification Status: $vStatusStr');
    buf.writeln('  • Clinical Reviewer: $reviewerFull');
    buf.writeln();

    // 6. Clinical Safety Alerts & Warnings
    final secSafety = isThai
        ? '5. ความปลอดภัยและข้อเตือน (Clinical Safety Alerts & Warnings)'
        : '5. CLINICAL SAFETY ALERTS & WARNINGS';
    buf.writeln(secSafety);

    if (result.warnings.isEmpty) {
      final noAlerts = isThai
          ? 'ไม่มีการแจ้งเตือนความปลอดภัย (No active safety alerts)'
          : 'No active safety alerts';
      buf.writeln('  • $noAlerts');
    } else {
      for (final w in result.warnings) {
        final msg = isThai && w.messageTh.isNotEmpty ? w.messageTh : w.messageEn;
        if (overdoseWarningCodes.contains(w.code)) {
          final calcVsLimit = (w.calculatedValue != null && w.limitValue != null)
              ? ' [Calculated: ${_formatNumber(w.calculatedValue!)} vs Limit: ${_formatNumber(w.limitValue!)}]'
              : '';
          buf.writeln('  • ⚠️ OVERDOSE WARNING: $msg$calcVsLimit');
        } else {
          buf.writeln('  • [${w.severity.labelEn}] $msg');
        }
      }
    }

    return buf.toString().trimRight();
  }

  // ---------------------------------------------------------------------------
  // Internal Helpers
  // ---------------------------------------------------------------------------

  static String _formatRoute(DoseRoute route, {required bool isContinuous}) {
    if (isContinuous) {
      if (route == DoseRoute.iv || route == DoseRoute.ivInfusion) {
        return 'IV infusion';
      }
      return route.abbreviation;
    }
    if (route == DoseRoute.iv || route == DoseRoute.ivInfusion) {
      return 'IV';
    }
    return route.abbreviation;
  }

  static String? _extractCitation(Drug drug, DosingRegimen regimen) {
    if (regimen.provenance != null && regimen.provenance!.source.trim().isNotEmpty) {
      return regimen.provenance!.source.trim();
    }
    if (regimen.monograph != null &&
        regimen.monograph!.textbookName.trim().isNotEmpty) {
      final name = regimen.monograph!.textbookName.trim();
      final year = regimen.monograph!.editionYear.trim();
      return year.isNotEmpty ? '$name $year' : name;
    }
    if (drug.provenance != null && drug.provenance!.source.trim().isNotEmpty) {
      return drug.provenance!.source.trim();
    }
    if (drug.monograph != null && drug.monograph!.textbookName.trim().isNotEmpty) {
      final name = drug.monograph!.textbookName.trim();
      final year = drug.monograph!.editionYear.trim();
      return year.isNotEmpty ? '$name $year' : name;
    }
    if (drug.sourceCitation.trim().isNotEmpty) {
      return drug.sourceCitation.trim();
    }
    if (regimen.doseCapCitation != null &&
        regimen.doseCapCitation!.trim().isNotEmpty) {
      return regimen.doseCapCitation!.trim();
    }
    return null;
  }

  static double _computeBsa(double weightKg, double heightCm) {
    if (weightKg > 0 && heightCm > 0) {
      return BsaCalculator.mosteller(heightCm: heightCm, weightKg: weightKg);
    }
    return 0.0;
  }

  static String _formatNumber(double value) {
    if (!value.isFinite) return value.toString();
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    for (int decimals = 1; decimals <= 4; decimals++) {
      final fixed = value.toStringAsFixed(decimals);
      if (double.parse(fixed) == value) {
        return fixed;
      }
    }
    final fixed = value.toStringAsFixed(4);
    return fixed.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }
}
