/// Structured unit for continuous infusion rates (D2).
enum RateUnit {
  mcgKgMin(symbol: 'mcg/kg/min', nameEn: 'mcg/kg/min', nameTh: 'มคก./กก./นาที'),
  mcgKgHr(symbol: 'mcg/kg/hr', nameEn: 'mcg/kg/hr', nameTh: 'มคก./กก./ชม.'),
  mgKgHr(symbol: 'mg/kg/hr', nameEn: 'mg/kg/hr', nameTh: 'มก./กก./ชม.'),
  mgKgMin(symbol: 'mg/kg/min', nameEn: 'mg/kg/min', nameTh: 'มก./กก./นาที'),
  uKgHr(symbol: 'units/kg/hr', nameEn: 'units/kg/hr', nameTh: 'ยูนิต/กก./ชม.'),
  uHr(symbol: 'units/hr', nameEn: 'units/hr', nameTh: 'ยูนิต/ชม.'),
  mgHr(symbol: 'mg/hr', nameEn: 'mg/hr', nameTh: 'มก./ชม.'),
  gHr(symbol: 'g/hr', nameEn: 'g/hr', nameTh: 'กรัม/ชม.'),
  mUMin(symbol: 'mU/min', nameEn: 'mU/min', nameTh: 'มิลลิยูนิต/นาที'),
  mlHr(symbol: 'mL/hr', nameEn: 'mL/hr', nameTh: 'มล./ชม.');

  final String symbol;
  final String nameEn;
  final String nameTh;

  const RateUnit({
    required this.symbol,
    required this.nameEn,
    required this.nameTh,
  });

  /// Resolves a raw symbol string to a structured [RateUnit], or `null` when
  /// the symbol is not recognised. Prefer this over [fromSymbol] in any
  /// safety-relevant path: a silent fallback to a different unit (e.g.
  /// mU/min shown as mcg/kg/min) is a dosing-error hazard.
  static RateUnit? tryFromSymbol(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower == 'milliunits/min' || lower == 'milliunit/min') {
      return RateUnit.mUMin;
    }
    for (final unit in RateUnit.values) {
      if (unit.symbol.toLowerCase() == lower ||
          unit.name.toLowerCase() == lower) {
        return unit;
      }
    }
    return null;
  }

  /// Resolves a raw symbol string to a structured [RateUnit].
  ///
  /// Throws [ArgumentError] for unknown symbols (no silent fallback).
  static RateUnit fromSymbol(String raw) {
    final unit = tryFromSymbol(raw);
    if (unit == null) {
      throw ArgumentError.value(raw, 'raw', 'Unknown infusion rate unit');
    }
    return unit;
  }

  /// Converts [rate] (expressed in this unit) to an absolute amount per hour:
  /// mg/hr for mass-based units, units/hr for unit-based units (U, mU).
  ///
  /// Returns `null` for [mlHr] (already a volume rate; there is no mass
  /// amount to derive) and when the unit is weight-based but [weightKg] is
  /// not positive.
  double? toAmountPerHour(double rate, double weightKg) {
    switch (this) {
      case RateUnit.mcgKgMin:
        return weightKg > 0 ? rate * weightKg * 60.0 / 1000.0 : null;
      case RateUnit.mcgKgHr:
        return weightKg > 0 ? rate * weightKg / 1000.0 : null;
      case RateUnit.mgKgHr:
        return weightKg > 0 ? rate * weightKg : null;
      case RateUnit.mgKgMin:
        return weightKg > 0 ? rate * weightKg * 60.0 : null;
      case RateUnit.uKgHr:
        return weightKg > 0 ? rate * weightKg : null;
      case RateUnit.uHr:
        return rate;
      case RateUnit.mgHr:
        return rate;
      case RateUnit.gHr:
        return rate * 1000.0;
      case RateUnit.mUMin:
        // 1 mU/min = 60 mU/hr = 0.06 units/hr
        return rate * 60.0 / 1000.0;
      case RateUnit.mlHr:
        return null;
    }
  }
}

/// The structured result of a continuous or titrated infusion calculation (D2).
class InfusionResult {
  /// The numeric rate in [rateUnit].
  final double rate;

  /// Upper bound of the titration range in [rateUnit], when the regimen
  /// defines one (null for a single fixed rate).
  final double? rateMax;

  /// The unit of the infusion rate.
  final RateUnit rateUnit;

  /// Calculated pump rate in mL/hr if standard dilution concentration is known.
  final double? rateMlPerHr;

  /// Pump rate in mL/hr at [rateMax], when both are known.
  final double? rateMlPerHrMax;

  /// Infusion duration in minutes, if fixed-duration.
  final double? durationMinutes;

  /// Gravity drip rate in drops/min (assuming 20 drops/mL standard set).
  final double? dripRateDropsPerMin;

  /// English administration instructions.
  final String? instructionsEn;

  /// Thai administration instructions.
  final String? instructionsTh;

  const InfusionResult({
    required this.rate,
    this.rateMax,
    required this.rateUnit,
    this.rateMlPerHr,
    this.rateMlPerHrMax,
    this.durationMinutes,
    this.dripRateDropsPerMin,
    this.instructionsEn,
    this.instructionsTh,
  });
}
