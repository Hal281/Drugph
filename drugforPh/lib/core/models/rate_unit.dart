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

  /// Resolves a raw symbol string to a structured [RateUnit].
  static RateUnit fromSymbol(String raw) {
    final lower = raw.trim().toLowerCase();
    for (final unit in RateUnit.values) {
      if (unit.symbol.toLowerCase() == lower || unit.name.toLowerCase() == lower) {
        return unit;
      }
    }
    return RateUnit.mcgKgMin;
  }
}

/// The structured result of a continuous or titrated infusion calculation (D2).
class InfusionResult {
  /// The numeric rate in [rateUnit].
  final double rate;

  /// The unit of the infusion rate.
  final RateUnit rateUnit;

  /// Calculated pump rate in mL/hr if standard dilution concentration is known.
  final double? rateMlPerHr;

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
    required this.rateUnit,
    this.rateMlPerHr,
    this.durationMinutes,
    this.dripRateDropsPerMin,
    this.instructionsEn,
    this.instructionsTh,
  });
}
