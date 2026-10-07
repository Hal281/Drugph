/// Provenance tracking clinical source, review stamp, and reviewer (D11).
class Provenance {
  /// Guideline, drug label, or textbook source with year/version
  /// (e.g. 'FDA Label 2024 / Sanford Guide 2023').
  final String source;

  /// Reviewing pharmacist or clinician name/credential.
  final String reviewedBy;

  /// Date when the dosing rule was clinically reviewed (ISO 8601 YYYY-MM-DD).
  final String reviewedAt;

  const Provenance({
    required this.source,
    required this.reviewedBy,
    required this.reviewedAt,
  });
}

/// Status of renal tier review for a drug (D6, D12).
enum RenalReviewStatus {
  /// Drug has been reviewed and specific CrCl adjustment tiers are established.
  reviewedWithTiers,

  /// Drug has been reviewed and confirmed to NOT require renal adjustment (e.g. biliary elimination).
  notApplicable,

  /// Drug is flagged for clinical pharmacist review.
  pendingReview,

  /// Drug has not been reviewed for renal dosing rules (F1 safe default).
  unreviewed,
}

/// Clinical verification status for SaMD regimens (E5, F1).
enum VerificationStatus {
  verified,
  pendingReview,
  unverified,
}

