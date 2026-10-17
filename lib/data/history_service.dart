import '../core/audit/calculation_log.dart';

/// In-memory singleton service for storing calculation history.
/// For a real SaMD, this would save to a secure local database (e.g. SQLite/Hive).
class HistoryService {
  static final HistoryService _instance = HistoryService._internal();

  factory HistoryService() {
    return _instance;
  }

  HistoryService._internal();

  final List<CalculationLog> _logs = [];

  /// Get all logs sorted by newest first
  List<CalculationLog> get logs {
    final sorted = List<CalculationLog>.from(_logs);
    sorted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted;
  }

  void addLog(CalculationLog log) {
    _logs.add(log);
  }

  void clearLogs() {
    _logs.clear();
  }
}
