// ============================================================
// Drug Dosage Calculator — Unit Converter
// ============================================================
// Type-safe conversions between mass, volume, and time units.
//
// DISCLAIMER: SaMD prototype — not for clinical use.
// ============================================================

import '../models/unit.dart';

/// Deterministic unit conversion engine.
///
/// All methods are static, pure, and side-effect-free.
class UnitConverter {
  const UnitConverter._();

  // ------------------------------------------------------------------
  // Mass conversions (mcg ↔ mg ↔ g ↔ kg)
  // ------------------------------------------------------------------

  /// Converts a mass value from one [MassUnit] to another.
  ///
  /// Example: `convertMass(500, MassUnit.mg, MassUnit.g)` → `0.5`
  static double convertMass(double value, MassUnit from, MassUnit to) {
    if (from == to) return value;
    final valueInMg = value * from.toMgFactor;
    return valueInMg / to.toMgFactor;
  }

  // ------------------------------------------------------------------
  // Volume conversions (mL ↔ L)
  // ------------------------------------------------------------------

  /// Converts a volume value from one [VolumeUnit] to another.
  static double convertVolume(double value, VolumeUnit from, VolumeUnit to) {
    if (from == to) return value;
    final valueInMl = value * from.toMlFactor;
    return valueInMl / to.toMlFactor;
  }

  // ------------------------------------------------------------------
  // Time conversions (min ↔ hr ↔ day)
  // ------------------------------------------------------------------

  /// Converts a time value from one [TimeUnit] to another.
  static double convertTime(double value, TimeUnit from, TimeUnit to) {
    if (from == to) return value;
    final valueInMin = value * from.toMinFactor;
    return valueInMin / to.toMinFactor;
  }

  // ------------------------------------------------------------------
  // Concentration helpers
  // ------------------------------------------------------------------

  /// Converts **% w/v** to **mg/mL**.
  ///
  /// 1 % w/v = 1 g per 100 mL = 10 mg/mL.
  static double percentWvToMgPerMl(double percent) => percent * 10.0;

  /// Converts **mg/mL** to **% w/v**.
  static double mgPerMlToPercentWv(double mgPerMl) => mgPerMl / 10.0;

  /// Converts **mg/mL** to **mcg/mL**.
  static double mgPerMlToMcgPerMl(double mgPerMl) => mgPerMl * 1000.0;

  /// Converts **mcg/mL** to **mg/mL**.
  static double mcgPerMlToMgPerMl(double mcgPerMl) => mcgPerMl / 1000.0;

  // ------------------------------------------------------------------
  // Volume from dose & concentration
  // ------------------------------------------------------------------

  /// Calculates the volume (mL) needed to deliver a desired dose.
  ///
  /// `volume = desiredDoseMg / concentrationMgPerMl`
  static double volumeForDoseMg({
    required double desiredDoseMg,
    required double concentrationMgPerMl,
  }) {
    if (concentrationMgPerMl <= 0) {
      throw ArgumentError.value(
        concentrationMgPerMl,
        'concentrationMgPerMl',
        'Must be > 0',
      );
    }
    return desiredDoseMg / concentrationMgPerMl;
  }

  // ------------------------------------------------------------------
  // Dose-unit convenience (DoseUnit → DoseUnit within same dimension)
  // ------------------------------------------------------------------

  /// Converts between compatible [DoseUnit] values.
  ///
  /// Only mass-compatible units (mcg, mg, g) can be converted.
  /// Throws [ArgumentError] if units are incompatible (e.g. mg → units).
  static double convertDoseUnit(double value, DoseUnit from, DoseUnit to) {
    if (from == to) return value;

    final massMap = <DoseUnit, MassUnit>{
      DoseUnit.mcg: MassUnit.mcg,
      DoseUnit.mg: MassUnit.mg,
      DoseUnit.g: MassUnit.g,
    };

    final fromMass = massMap[from];
    final toMass = massMap[to];

    if (fromMass == null || toMass == null) {
      throw ArgumentError(
        'Cannot convert between $from and $to — '
        'only mcg/mg/g conversions are supported',
      );
    }

    return convertMass(value, fromMass, toMass);
  }

  // ------------------------------------------------------------------
  // Clinical laboratory conversions (Serum Creatinine: umol/L ↔ mg/dL)
  // ------------------------------------------------------------------

  /// Converts serum creatinine from micromoles per liter (umol/L) to milligrams per deciliter (mg/dL).
  ///
  /// Formula: `mg/dL = umol/L / 88.4`
  ///
  /// Clinical Reference:
  /// Winter ME. Basic Clinical Pharmacokinetics. 5th ed. Lippincott Williams & Wilkins; 2010.
  /// (Creatinine MW = 113.12 g/mol: 1 mg/dL = 10 mg/L / 113.12 = 0.0884 mmol/L = 88.4 umol/L).
  static double scrUmolPerLToMgPerDl(double umolPerL) => umolPerL / 88.4;

  /// Converts serum creatinine from milligrams per deciliter (mg/dL) to micromoles per liter (umol/L).
  ///
  /// Formula: `umol/L = mg/dL * 88.4`
  ///
  /// Clinical Reference:
  /// Winter ME. Basic Clinical Pharmacokinetics. 5th ed. Lippincott Williams & Wilkins; 2010.
  static double scrMgPerDlToUmolPerL(double mgPerDl) => mgPerDl * 88.4;

  // ------------------------------------------------------------------
  // Imperial ↔ Metric conversions (lb ↔ kg, in ↔ cm)
  // ------------------------------------------------------------------

  /// Converts weight from pounds (lb) to kilograms (kg).
  /// International avoirdupois pound = 0.45359237 kg.
  static double lbToKg(double lb) => lb * 0.45359237;

  /// Converts weight from kilograms (kg) to pounds (lb).
  static double kgToLb(double kg) => kg / 0.45359237;

  /// Converts height from inches to centimeters (cm).
  /// 1 inch = 2.54 cm.
  static double inToCm(double inches) => inches * 2.54;

  /// Converts height from centimeters (cm) to inches.
  static double cmToIn(double cm) => cm / 2.54;

  // ------------------------------------------------------------------
  // Frequency parsing
  // ------------------------------------------------------------------

  /// Parses a frequency string and returns doses per day.
  ///
  /// Supported standard formats: 'q4h', 'q6h', 'q8h', 'q12h', 'q24h',
  /// 'q48h', 'once', 'stat', 'bid', 'tid', 'qid', 'daily', 'od', 'qd'.
  ///
  /// Returns 0.0 for variable/unsupported frequencies where doses per day
  /// cannot be deterministically computed: e.g. ranges ('q6-8h'), 'prn',
  /// 'qod', 'weekly', 'continuous'.
  static double dosesPerDay(String frequency) {
    final raw = frequency.trim().toLowerCase();
    if (raw.isEmpty) return 0.0;

    // Strip parentheses content (e.g. 'q12h (bid)' -> 'q12h', 'q24h (od)' -> 'q24h')
    final f = raw.replaceAll(RegExp(r'\([^)]*\)'), '').trim();

    // Variable or unsupported frequencies returning 0
    if (f == 'prn' ||
        f == 'as needed' ||
        f == 'qod' ||
        f == 'every other day' ||
        f == 'weekly' ||
        f == 'continuous' ||
        f.contains('continuous') ||
        f.contains('prn') ||
        f.contains('as needed') ||
        f.contains('titrate') ||
        f.contains('per week') ||
        f.contains('cycle') ||
        RegExp(r'q\d+\s*-\s*q?\d+h').hasMatch(f) ||
        RegExp(r'\b(to|or)\b').hasMatch(f)) {
      return 0.0;
    }

    // 1. qNh pattern (e.g. q4h, q6h, q8h, q12h, q24h, q48h)
    final qhMatch = RegExp(r'\bq(\d+)h\b').firstMatch(f);
    if (qhMatch != null) {
      final hours = int.parse(qhMatch.group(1)!);
      if (hours <= 0) return 0.0;
      return 24.0 / hours;
    }

    // 2. Named standard frequencies
    if (RegExp(r'\b(qid|qds)\b').hasMatch(f)) {
      return 4.0;
    }
    if (RegExp(r'\b(tid|tds)\b').hasMatch(f)) {
      return 3.0;
    }
    if (RegExp(r'\b(bid|bd)\b').hasMatch(f)) {
      return 2.0;
    }
    if (RegExp(r'\b(once|stat|daily|od|qd|single dose)\b').hasMatch(f)) {
      return 1.0;
    }

    // Fallback — unknown frequency, return 0 to signal error
    return 0.0;
  }
}
