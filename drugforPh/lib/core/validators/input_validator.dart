// ============================================================
// Drug Dosage Calculator — Input Validator
// ============================================================
// Validates all patient and drug inputs before calculation.
// Returns structured validation results — never throws.
//
// DISCLAIMER: SaMD prototype — not for clinical use.
// ============================================================

/// Result of validating one or more input fields.
class ValidationResult {
  /// `true` if all validated fields are acceptable.
  final bool isValid;

  /// Human-readable error messages (English) keyed by field name.
  final Map<String, String> errorsEn;

  /// Human-readable error messages (Thai) keyed by field name.
  final Map<String, String> errorsTh;

  const ValidationResult({
    required this.isValid,
    this.errorsEn = const {},
    this.errorsTh = const {},
  });

  /// Convenience factory for a valid result.
  const ValidationResult.valid()
      : isValid = true,
        errorsEn = const {},
        errorsTh = const {};

  @override
  String toString() {
    if (isValid) return 'ValidationResult(VALID)';
    return 'ValidationResult(INVALID: $errorsEn)';
  }
}

/// Validates clinical inputs before they reach the calculation engine.
///
/// All methods are static and return [ValidationResult] — they never throw.
class InputValidator {
  const InputValidator._();

  /// Validates a complete set of patient inputs.
  static ValidationResult validatePatientInputs({
    required double? weightKg,
    required double? heightCm,
    required int? ageYears,
    int? ageMonths,
    double? serumCreatinineMgDl,
  }) {
    final errorsEn = <String, String>{};
    final errorsTh = <String, String>{};

    // Weight
    if (weightKg == null) {
      errorsEn['weightKg'] = 'Weight is required';
      errorsTh['weightKg'] = 'กรุณาระบุน้ำหนัก';
    } else if (weightKg <= 0) {
      errorsEn['weightKg'] = 'Weight must be greater than 0';
      errorsTh['weightKg'] = 'น้ำหนักต้องมากกว่า 0';
    } else if (weightKg > 500) {
      errorsEn['weightKg'] = 'Weight exceeds 500 kg — please verify';
      errorsTh['weightKg'] = 'น้ำหนักเกิน 500 กก. — กรุณาตรวจสอบ';
    }

    // Height
    if (heightCm == null) {
      errorsEn['heightCm'] = 'Height is required';
      errorsTh['heightCm'] = 'กรุณาระบุส่วนสูง';
    } else if (heightCm <= 0) {
      errorsEn['heightCm'] = 'Height must be greater than 0';
      errorsTh['heightCm'] = 'ส่วนสูงต้องมากกว่า 0';
    } else if (heightCm > 300) {
      errorsEn['heightCm'] = 'Height exceeds 300 cm — please verify';
      errorsTh['heightCm'] = 'ส่วนสูงเกิน 300 ซม. — กรุณาตรวจสอบ';
    }

    // Age
    if (ageYears == null) {
      errorsEn['ageYears'] = 'Age is required';
      errorsTh['ageYears'] = 'กรุณาระบุอายุ';
    } else if (ageYears < 0) {
      errorsEn['ageYears'] = 'Age cannot be negative';
      errorsTh['ageYears'] = 'อายุไม่สามารถเป็นค่าลบ';
    } else if (ageYears > 150) {
      errorsEn['ageYears'] = 'Age exceeds 150 years — please verify';
      errorsTh['ageYears'] = 'อายุเกิน 150 ปี — กรุณาตรวจสอบ';
    }

    // Age months (pediatric)
    if (ageMonths != null && (ageMonths < 0 || ageMonths > 11)) {
      errorsEn['ageMonths'] = 'Months must be 0–11';
      errorsTh['ageMonths'] = 'เดือนต้องอยู่ระหว่าง 0–11';
    }

    // Serum creatinine (optional but validated if provided)
    if (serumCreatinineMgDl != null) {
      if (serumCreatinineMgDl <= 0) {
        errorsEn['serumCreatinineMgDl'] =
            'Serum creatinine must be greater than 0';
        errorsTh['serumCreatinineMgDl'] = 'ค่าครีเอตินินต้องมากกว่า 0';
      } else if (serumCreatinineMgDl > 30) {
        errorsEn['serumCreatinineMgDl'] =
            'Serum creatinine exceeds 30 mg/dL — please verify';
        errorsTh['serumCreatinineMgDl'] =
            'ค่าครีเอตินินเกิน 30 mg/dL — กรุณาตรวจสอบ';
      }
    }

    return ValidationResult(
      isValid: errorsEn.isEmpty,
      errorsEn: errorsEn,
      errorsTh: errorsTh,
    );
  }

  /// Validates a dose value.
  static ValidationResult validateDose({
    required double? dose,
    String fieldName = 'dose',
  }) {
    if (dose == null) {
      return ValidationResult(
        isValid: false,
        errorsEn: {fieldName: 'Dose is required'},
        errorsTh: {fieldName: 'กรุณาระบุขนาดยา'},
      );
    }
    if (dose < 0) {
      return ValidationResult(
        isValid: false,
        errorsEn: {fieldName: 'Dose cannot be negative'},
        errorsTh: {fieldName: 'ขนาดยาไม่สามารถเป็นค่าลบ'},
      );
    }
    return const ValidationResult.valid();
  }

  /// Validates a positive numeric value.
  static ValidationResult validatePositive({
    required double? value,
    required String fieldNameEn,
    required String fieldNameTh,
  }) {
    if (value == null) {
      return ValidationResult(
        isValid: false,
        errorsEn: {fieldNameEn: '$fieldNameEn is required'},
        errorsTh: {fieldNameTh: 'กรุณาระบุ$fieldNameTh'},
      );
    }
    if (value <= 0) {
      return ValidationResult(
        isValid: false,
        errorsEn: {fieldNameEn: '$fieldNameEn must be greater than 0'},
        errorsTh: {fieldNameTh: '$fieldNameThต้องมากกว่า 0'},
      );
    }
    return const ValidationResult.valid();
  }
}
