class Provenance {
  /// Guideline, drug label, or textbook source with year/version
  /// (e.g. 'FDA Label 2024 / Sanford Guide 2023').
  final String source;

  /// Reviewing pharmacist or clinician name/credential.
  final String reviewedBy;

  /// Date when the dosing rule was clinically reviewed (ISO 8601 YYYY-MM-DD).
  final String reviewedAt;

  /// Detailed section, table, or page reference within the source.
  final String? sourceDetail;

  /// License number of the reviewing pharmacist (e.g. 'ภ. 12345').
  final String? reviewerLicense;

  /// Approving faculty member, attending physician, or committee chair.
  final String? approvedBy;

  const Provenance({
    required this.source,
    required this.reviewedBy,
    required this.reviewedAt,
    this.sourceDetail,
    this.reviewerLicense,
    this.approvedBy,
  });
}

/// Structured clinical textbook monograph for bedside reference.
class ClinicalMonograph {
  /// Name of textbook / clinical guideline (e.g. 'The Sanford Guide to Antimicrobial Therapy').
  final String textbookName;

  /// Edition or publication year (e.g. '54th Edition, 2024').
  final String editionYear;

  /// Specific table, section, or page in the textbook.
  final String? sectionOrTable;

  /// Clinical dosing summary from the textbook monograph.
  final String dosingGuideline;

  /// Specific renal impairment dosing table / guideline from the textbook.
  final String? renalGuideline;

  /// IV administration, dilution, and infusion rate guidance (e.g. from Ramathibodi/Siriraj manual).
  final String? administrationGuideline;

  /// Clinical precautions, toxicity warnings, and monitoring advice from the textbook.
  final String? clinicalNotes;

  /// Public URL to monograph or prescribing information (DailyMed, FDA, etc.).
  final String? externalUrl;

  const ClinicalMonograph({
    required this.textbookName,
    required this.editionYear,
    this.sectionOrTable,
    required this.dosingGuideline,
    this.renalGuideline,
    this.administrationGuideline,
    this.clinicalNotes,
    this.externalUrl,
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


