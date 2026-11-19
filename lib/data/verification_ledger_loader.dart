import 'package:flutter/services.dart' show rootBundle;

import '../core/core.dart';

/// Loads `assets/data/verification_ledger.json` into [VerificationLedgerService].
class VerificationLedgerLoader {
  const VerificationLedgerLoader._();

  static const String assetPath = 'assets/data/verification_ledger.json';
  static bool _hasAttemptedLoad = false;

  /// Loads and activates the verification ledger JSON asset.
  ///
  /// Gracefully leaves [VerificationLedgerService.currentLedger] untouched
  /// (failing closed as unverified) if the asset bundle is unavailable.
  static Future<void> ensureLoaded({bool forceReload = false}) async {
    if (_hasAttemptedLoad && !forceReload) return;
    _hasAttemptedLoad = true;
    try {
      final rawJson = await rootBundle.loadString(assetPath);
      VerificationLedgerService.loadFromJsonString(rawJson);
    } catch (_) {
      // Fail closed: empty ledger treats every drug/regimen as unverified.
    }
  }
}
