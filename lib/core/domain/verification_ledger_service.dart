import '../models/models.dart';
import '../validators/schema_validator.dart';

/// Pure-Dart service evaluating clinical pharmacist sign-off status from the
/// active [VerificationLedger] (WP-13 / Q5).
///
/// Enforces the strict **100% active regimen** rule: a drug only qualifies for
/// verified status when *every* active [DosingRegimen] on that drug has a
/// valid, human-signed ledger entry (`verified: true`, real reviewer name,
/// valid Thai license `ภก./ภ./ว.`, and valid ISO `YYYY-MM-DD` date).
class VerificationLedgerService {
  VerificationLedgerService._();

  static VerificationLedger _activeLedger = VerificationLedger.empty;

  /// Currently loaded ledger snapshot (defaults to empty until loaded from asset or test).
  static VerificationLedger get currentLedger => _activeLedger;

  /// Replaces the active in-memory ledger (primarily at app startup or in tests).
  static void loadLedger(VerificationLedger ledger) {
    _activeLedger = ledger;
  }

  /// Parses raw JSON ledger content and activates it.
  static void loadFromJsonString(String rawJson) {
    _activeLedger = VerificationLedger.parseJsonString(rawJson);
  }

  /// Resets the active ledger back to [VerificationLedger.empty].
  static void resetLedger() {
    _activeLedger = VerificationLedger.empty;
  }

  /// Evaluates [drug] against [ledger] (or [currentLedger] when omitted).
  static DrugVerificationSummary evaluateDrug(
    Drug drug, {
    VerificationLedger? ledger,
  }) {
    final targetLedger = ledger ?? _activeLedger;
    final totalRegimens = drug.regimens.length;

    if (totalRegimens == 0) {
      return DrugVerificationSummary(
        drugId: drug.id,
        status: DrugLedgerStatus.unverified,
        verifiedRegimenCount: 0,
        totalRegimenCount: 0,
      );
    }

    var verifiedCount = 0;
    final names = <String>{};
    final licenses = <String>{};
    String? latestDate;

    for (var i = 0; i < totalRegimens; i++) {
      final regId = drug.regimenIdAt(i);
      final entry = targetLedger.entryFor(drug.id, regId);
      if (entry != null &&
          entry.verified &&
          SchemaValidator.validateLedgerEntry(entry).isEmpty) {
        verifiedCount++;
        final name = entry.verifiedBy!.trim();
        final license = entry.licenseNo!.trim();
        final date = entry.verifiedDate!.trim();
        names.add(name);
        licenses.add(license);
        if (latestDate == null || date.compareTo(latestDate) > 0) {
          latestDate = date;
        }
      }
    }

    final status = verifiedCount == totalRegimens
        ? DrugLedgerStatus.verified
        : (verifiedCount > 0
            ? DrugLedgerStatus.partiallyVerified
            : DrugLedgerStatus.unverified);

    return DrugVerificationSummary(
      drugId: drug.id,
      status: status,
      verifiedRegimenCount: verifiedCount,
      totalRegimenCount: totalRegimens,
      verifiedByNames: List.unmodifiable(names),
      reviewerLicenses: List.unmodifiable(licenses),
      latestVerifiedDate: latestDate,
    );
  }

  /// Whether a specific active [regimen] of [drug] has a valid signed ledger entry.
  static bool isRegimenVerified(
    Drug drug,
    DosingRegimen regimen, {
    VerificationLedger? ledger,
  }) {
    final targetLedger = ledger ?? _activeLedger;
    final regId = drug.regimenIdFor(regimen);
    final entry = targetLedger.entryFor(drug.id, regId);
    if (entry == null || !entry.verified) return false;
    return SchemaValidator.validateLedgerEntry(entry).isEmpty;
  }

  /// Evaluates the Phase 4 Pilot Release Gate (`>= 80%` Core drugs 100% verified).
  static PilotReleaseGateResult evaluatePilotReleaseGate({
    required Iterable<Drug> coreDrugs,
    VerificationLedger? ledger,
    double requiredThresholdPercent = 80.0,
  }) {
    final targetLedger = ledger ?? _activeLedger;
    final coreList = coreDrugs.toList(growable: false);
    final validation = SchemaValidator.validateVerificationLedger(
      targetLedger,
      expectedDrugs: coreList,
    );

    var verifiedCount = 0;
    final unverifiedIds = <String>[];
    for (final drug in coreList) {
      final summary = evaluateDrug(drug, ledger: targetLedger);
      if (summary.isFullyVerified) {
        verifiedCount++;
      } else {
        unverifiedIds.add(drug.id);
      }
    }

    final coverage =
        coreList.isEmpty ? 0.0 : (verifiedCount / coreList.length) * 100.0;

    return PilotReleaseGateResult(
      coreDrugCount: coreList.length,
      verifiedCoreDrugCount: verifiedCount,
      coveragePercent: coverage,
      requiredThresholdPercent: requiredThresholdPercent,
      unverifiedCoreDrugIds: List.unmodifiable(unverifiedIds),
      validationErrors: validation.errors,
    );
  }
}
