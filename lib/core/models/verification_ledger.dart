import 'dart:convert';

/// Aggregate pharmacist ledger verification state for a [Drug] (WP-13 / Q5).
enum DrugLedgerStatus {
  /// 100% of active regimens on the drug have valid signed entries in the ledger.
  verified,

  /// At least one active regimen is signed off, while others remain pending.
  partiallyVerified,

  /// Zero active regimens have valid pharmacist sign-off.
  unverified,
}

/// Single regimen verification entry backed by `assets/data/verification_ledger.json`.
class VerificationLedgerEntry {
  final String drugId;
  final String regimenId;
  final bool verified;
  final String? verifiedBy;
  final String? licenseNo;
  final String? verifiedDate;
  final String sourceChecked;
  final String? notes;

  const VerificationLedgerEntry({
    required this.drugId,
    required this.regimenId,
    this.verified = false,
    this.verifiedBy,
    this.licenseNo,
    this.verifiedDate,
    required this.sourceChecked,
    this.notes,
  });

  factory VerificationLedgerEntry.fromJson(Map<String, dynamic> json) {
    return VerificationLedgerEntry(
      drugId: ((json['drug_id'] as String?) ?? '').trim().toLowerCase(),
      regimenId: ((json['regimen_id'] as String?) ?? '').trim().toLowerCase(),
      verified: (json['verified'] as bool?) ?? false,
      verifiedBy: json['verified_by'] as String?,
      licenseNo: json['license_no'] as String?,
      verifiedDate: json['verified_date'] as String?,
      sourceChecked: (json['source_checked'] as String?) ?? '',
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'drug_id': drugId,
        'regimen_id': regimenId,
        'verified': verified,
        'verified_by': verifiedBy,
        'license_no': licenseNo,
        'verified_date': verifiedDate,
        'source_checked': sourceChecked,
        if (notes != null) 'notes': notes,
      };
}

/// Complete clinical pharmacist sign-off ledger parsed from JSON.
class VerificationLedger {
  final String schemaVersion;
  final List<VerificationLedgerEntry> entries;

  const VerificationLedger({
    required this.schemaVersion,
    required this.entries,
  });

  static const VerificationLedger empty = VerificationLedger(
    schemaVersion: '1.0.0',
    entries: [],
  );

  factory VerificationLedger.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['entries'] as List<dynamic>? ?? const [];
    return VerificationLedger(
      schemaVersion: (json['schema_version'] as String?) ?? '',
      entries: rawEntries
          .whereType<Map<String, dynamic>>()
          .map(VerificationLedgerEntry.fromJson)
          .toList(growable: false),
    );
  }

  static VerificationLedger parseJsonString(String rawJson) {
    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    return VerificationLedger.fromJson(decoded);
  }

  Map<String, dynamic> toJson() => {
        'schema_version': schemaVersion,
        'entries': entries.map((e) => e.toJson()).toList(growable: false),
      };

  /// All ledger entries matching [drugId] (case-insensitive).
  List<VerificationLedgerEntry> entriesForDrug(String drugId) {
    final target = drugId.trim().toLowerCase();
    return entries
        .where((e) => e.drugId.trim().toLowerCase() == target)
        .toList(growable: false);
  }

  /// Finds an entry for ([drugId], [regimenId]) (case-insensitive), or `null`.
  VerificationLedgerEntry? entryFor(String drugId, String regimenId) {
    final d = drugId.trim().toLowerCase();
    final r = regimenId.trim().toLowerCase();
    for (final entry in entries) {
      if (entry.drugId.trim().toLowerCase() == d &&
          entry.regimenId.trim().toLowerCase() == r) {
        return entry;
      }
    }
    return null;
  }
}

/// Drug-level sign-off evaluation summary enforcing 100% active regimen coverage.
class DrugVerificationSummary {
  final String drugId;
  final DrugLedgerStatus status;
  final int verifiedRegimenCount;
  final int totalRegimenCount;
  final List<String> verifiedByNames;
  final List<String> reviewerLicenses;
  final String? latestVerifiedDate;

  const DrugVerificationSummary({
    required this.drugId,
    required this.status,
    required this.verifiedRegimenCount,
    required this.totalRegimenCount,
    this.verifiedByNames = const [],
    this.reviewerLicenses = const [],
    this.latestVerifiedDate,
  });

  bool get isFullyVerified => status == DrugLedgerStatus.verified;
}

/// Pilot release readiness evaluation across Core Formulary V1 drugs (`>= 80%`).
class PilotReleaseGateResult {
  final int coreDrugCount;
  final int verifiedCoreDrugCount;
  final double coveragePercent;
  final double requiredThresholdPercent;
  final List<String> unverifiedCoreDrugIds;
  final List<String> validationErrors;

  const PilotReleaseGateResult({
    required this.coreDrugCount,
    required this.verifiedCoreDrugCount,
    required this.coveragePercent,
    required this.requiredThresholdPercent,
    required this.unverifiedCoreDrugIds,
    required this.validationErrors,
  });

  bool get isPilotReady =>
      coreDrugCount > 0 &&
      coveragePercent >= requiredThresholdPercent &&
      validationErrors.isEmpty;
}
