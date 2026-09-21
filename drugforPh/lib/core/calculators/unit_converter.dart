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
  // Frequency parsing
  // ------------------------------------------------------------------

  /// Parses a frequency string and returns doses per day.
  ///
  /// Supported formats: 'q4h', 'q6h', 'q8h', 'q12h', 'q24h',
  /// 'q48h', 'once', 'stat', 'bid', 'tid', 'qid', 'daily'.
  static double dosesPerDay(String frequency) {
    final f = frequency.trim().toLowerCase();

    // Named frequencies
    switch (f) {
      case 'once':
      case 'stat':
      case 'daily':
      case 'od':
      case 'qd':
        return 1.0;
      case 'bid':
      case 'bd':
        return 2.0;
      case 'tid':
      case 'tds':
        return 3.0;
      case 'qid':
      case 'qds':
        return 4.0;
    }

    // qNh pattern (e.g. q4h, q6h, q8h, q12h, q24h, q48h)
    final qhMatch = RegExp(r'^q(\d+)h$').firstMatch(f);
    if (qhMatch != null) {
      final hours = int.parse(qhMatch.group(1)!);
      if (hours <= 0) return 0;
      return 24.0 / hours;
    }

    // Fallback — unknown frequency, return 0 to signal error
    return 0;
  }
}
