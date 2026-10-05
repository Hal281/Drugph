import 'dose_basis.dart';

/// Structured clinical frequency value type (D1).
///
/// Replaces free-text frequency strings. Supports fixed intervals, ranges,
/// PRN/as-needed schedules, once/stat, and weekly frequencies.
class Frequency {
  /// Standard dosing interval in hours (e.g. 6 for q6h, 8 for q8h, 12 for q12h, 24 for q24h).
  final int? intervalHours;

  /// Minimum interval in hours for range-based dosing (e.g. 4 for q4-6h).
  final int? minIntervalHours;

  /// Maximum interval in hours for range-based dosing (e.g. 6 for q4-6h).
  final int? maxIntervalHours;

  /// Whether the dose is administered pro re nata (as needed).
  final bool isPrn;

  /// Whether the dose is administered weekly.
  final bool isWeekly;

  /// Whether this is a single administration event (once or stat).
  final bool isOnce;

  /// Whether this is a continuous infusion.
  final bool isContinuous;

  /// English display text (e.g. 'q8h', 'q4-6h PRN', 'Once', 'Continuous IV').
  final String displayEn;

  /// Thai display text (e.g. 'ทุก 8 ชม.', 'ทุก 4-6 ชม. เมื่อจำเป็น', 'ครั้งเดียว', 'ให้ทางหลอดเลือดดำต่อเนื่อง').
  final String displayTh;

  /// Explicit dose basis associated with this frequency (perDose, perDay, perWeek).
  final DoseBasis doseBasis;

  const Frequency({
    this.intervalHours,
    this.minIntervalHours,
    this.maxIntervalHours,
    this.isPrn = false,
    this.isWeekly = false,
    this.isOnce = false,
    this.isContinuous = false,
    required this.displayEn,
    required this.displayTh,
    this.doseBasis = DoseBasis.perDose,
  });

  // ---- Predefined Standard Clinical Frequencies ----

  static const Frequency q4h = Frequency(
    intervalHours: 4,
    displayEn: 'q4h',
    displayTh: 'ทุก 4 ชม.',
  );

  static const Frequency q6h = Frequency(
    intervalHours: 6,
    displayEn: 'q6h',
    displayTh: 'ทุก 6 ชม.',
  );

  static const Frequency q8h = Frequency(
    intervalHours: 8,
    displayEn: 'q8h',
    displayTh: 'ทุก 8 ชม.',
  );

  static const Frequency q12h = Frequency(
    intervalHours: 12,
    displayEn: 'q12h',
    displayTh: 'ทุก 12 ชม.',
  );

  static const Frequency q24h = Frequency(
    intervalHours: 24,
    displayEn: 'q24h',
    displayTh: 'ทุก 24 ชม. (วันละ 1 ครั้ง)',
  );

  static const Frequency q36h = Frequency(
    intervalHours: 36,
    displayEn: 'q36h',
    displayTh: 'ทุก 36 ชม.',
  );

  static const Frequency q48h = Frequency(
    intervalHours: 48,
    displayEn: 'q48h',
    displayTh: 'ทุก 48 ชม. (วันเว้นวัน)',
  );

  static const Frequency q72h = Frequency(
    intervalHours: 72,
    displayEn: 'q72h',
    displayTh: 'ทุก 72 ชม.',
  );

  static const Frequency q12hTo24h = Frequency(
    minIntervalHours: 12,
    maxIntervalHours: 24,
    displayEn: 'q12-24h',
    displayTh: 'ทุก 12-24 ชม.',
  );

  static const Frequency q48hTo72h = Frequency(
    minIntervalHours: 48,
    maxIntervalHours: 72,
    displayEn: 'q48-72h',
    displayTh: 'ทุก 48-72 ชม.',
  );

  static const Frequency bid = q12h;
  static const Frequency tid = q8h;
  static const Frequency qid = q6h;
  static const Frequency od = q24h;

  static const Frequency once = Frequency(
    isOnce: true,
    displayEn: 'Once',
    displayTh: 'ครั้งเดียว',
  );

  static const Frequency stat = Frequency(
    isOnce: true,
    displayEn: 'Stat',
    displayTh: 'ทันที (Stat)',
  );

  static const Frequency continuous = Frequency(
    isContinuous: true,
    displayEn: 'Continuous',
    displayTh: 'หยดต่อเนื่อง',
  );

  static const Frequency weekly = Frequency(
    isWeekly: true,
    displayEn: 'Weekly',
    displayTh: 'สัปดาห์ละ 1 ครั้ง',
    doseBasis: DoseBasis.perWeek,
  );

  static const Frequency prn = Frequency(
    isPrn: true,
    displayEn: 'PRN',
    displayTh: 'เมื่อจำเป็น',
  );

  // Common PRN & Range Frequencies
  static const Frequency q4_6hPrn = Frequency(
    minIntervalHours: 4,
    maxIntervalHours: 6,
    isPrn: true,
    displayEn: 'q4-6h PRN',
    displayTh: 'ทุก 4-6 ชม. เมื่อมีอาการ',
  );

  static const Frequency q6_8hPrn = Frequency(
    minIntervalHours: 6,
    maxIntervalHours: 8,
    isPrn: true,
    displayEn: 'q6-8h PRN',
    displayTh: 'ทุก 6-8 ชม. เมื่อมีอาการ',
  );

  static const Frequency q8hPrn = Frequency(
    intervalHours: 8,
    isPrn: true,
    displayEn: 'q8h PRN',
    displayTh: 'ทุก 8 ชม. เมื่อมีอาการ',
  );

  static const Frequency q6hPrn = Frequency(
    intervalHours: 6,
    isPrn: true,
    displayEn: 'q6h PRN',
    displayTh: 'ทุก 6 ชม. เมื่อมีอาการ',
  );

  /// Derives doses per day from the structured fields.
  ///
  /// Returns `null` if doses per day cannot be deterministically computed
  /// (e.g. PRN, variable interval range, continuous infusion).
  double? get dosesPerDay {
    if (isPrn || isContinuous) return null;
    if (minIntervalHours != null || maxIntervalHours != null) return null;
    if (isOnce) return 1.0;
    if (isWeekly) return 1.0 / 7.0;
    if (intervalHours != null && intervalHours! > 0) {
      return 24.0 / intervalHours!;
    }
    return null;
  }

  /// Parses legacy frequency strings into structured [Frequency] instances.
  factory Frequency.fromLegacyString(
    String raw, {
    DoseBasis doseBasis = DoseBasis.perDose,
  }) {
    final lower = raw.trim().toLowerCase();
    if (lower.isEmpty) {
      return Frequency(
        displayEn: raw,
        displayTh: raw,
        doseBasis: doseBasis,
      );
    }

    final withoutParens = lower.replaceAll(RegExp(r'\([^)]*\)'), '').trim();

    if (withoutParens == 'once' || withoutParens == 'single dose') {
      return Frequency.once;
    }
    if (withoutParens == 'stat') {
      return Frequency.stat;
    }
    if (withoutParens.contains('continuous')) {
      return Frequency.continuous;
    }
    if (withoutParens.contains('weekly') || withoutParens.contains('per week')) {
      return Frequency.weekly;
    }

    // Interval patterns
    final qhMatch = RegExp(r'\bq(\d+)h\b').firstMatch(withoutParens);
    final isPrnMatch = withoutParens.contains('prn') || withoutParens.contains('as needed');
    final rangeMatch = RegExp(r'q?(\d+)\s*-\s*q?(\d+)h').firstMatch(withoutParens);

    if (rangeMatch != null) {
      final minH = int.parse(rangeMatch.group(1)!);
      final maxH = int.parse(rangeMatch.group(2)!);
      return Frequency(
        minIntervalHours: minH,
        maxIntervalHours: maxH,
        isPrn: isPrnMatch,
        displayEn: raw,
        displayTh: 'ทุก $minH-$maxH ชม.${isPrnMatch ? ' เมื่อจำเป็น' : ''}',
        doseBasis: doseBasis,
      );
    }

    if (qhMatch != null) {
      final hours = int.parse(qhMatch.group(1)!);
      if (hours == 4 && !isPrnMatch) return Frequency.q4h;
      if (hours == 6 && !isPrnMatch) return Frequency.q6h;
      if (hours == 8 && !isPrnMatch) return Frequency.q8h;
      if (hours == 12 && !isPrnMatch) return Frequency.q12h;
      if (hours == 24 && !isPrnMatch) return Frequency.q24h;
      if (hours == 48 && !isPrnMatch) return Frequency.q48h;
      if (hours == 72 && !isPrnMatch) return Frequency.q72h;

      return Frequency(
        intervalHours: hours,
        isPrn: isPrnMatch,
        displayEn: raw,
        displayTh: 'ทุก $hours ชม.${isPrnMatch ? ' เมื่อจำเป็น' : ''}',
        doseBasis: doseBasis,
      );
    }

    // Standard Latin tokens
    if (RegExp(r'\b(qid|qds)\b').hasMatch(withoutParens)) {
      return const Frequency(intervalHours: 6, displayEn: 'QID', displayTh: 'วันละ 4 ครั้ง');
    }
    if (RegExp(r'\b(tid|tds)\b').hasMatch(withoutParens)) {
      return const Frequency(intervalHours: 8, displayEn: 'TID', displayTh: 'วันละ 3 ครั้ง');
    }
    if (RegExp(r'\b(bid|bd)\b').hasMatch(withoutParens)) {
      return const Frequency(intervalHours: 12, displayEn: 'BID', displayTh: 'วันละ 2 ครั้ง');
    }
    if (RegExp(r'\b(daily|od|qd)\b').hasMatch(withoutParens)) {
      return Frequency.q24h;
    }

    return Frequency(
      isPrn: isPrnMatch,
      displayEn: raw,
      displayTh: raw,
      doseBasis: doseBasis,
    );
  }

  @override
  String toString() => displayEn;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Frequency &&
          runtimeType == other.runtimeType &&
          intervalHours == other.intervalHours &&
          minIntervalHours == other.minIntervalHours &&
          maxIntervalHours == other.maxIntervalHours &&
          isPrn == other.isPrn &&
          isWeekly == other.isWeekly &&
          isOnce == other.isOnce &&
          isContinuous == other.isContinuous &&
          doseBasis == other.doseBasis &&
          displayEn == other.displayEn;

  @override
  int get hashCode =>
      intervalHours.hashCode ^
      minIntervalHours.hashCode ^
      maxIntervalHours.hashCode ^
      isPrn.hashCode ^
      isWeekly.hashCode ^
      isOnce.hashCode ^
      isContinuous.hashCode ^
      doseBasis.hashCode ^
      displayEn.hashCode;
}
