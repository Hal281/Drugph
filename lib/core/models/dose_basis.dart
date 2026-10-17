/// Explicit basis for a drug dose calculation (D1).
///
/// Distinguishes between doses administered per single administration event,
/// doses specified as total daily dose to be divided, and weekly doses.
enum DoseBasis {
  /// Dose is specified per single administration event (e.g. 500 mg q8h).
  perDose,

  /// Dose is specified as total daily dose to be divided into individual administrations
  /// (e.g. Amoxicillin/Clavulanate 45 mg/kg/day divided q12h).
  perDay,

  /// Dose is specified per week (e.g. Methotrexate 15 mg once weekly).
  perWeek,
}
