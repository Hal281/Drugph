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

  /// Human-readable warning messages (English) keyed by field name.
  final Map<String, String> warningsEn;

  /// Human-readable warning messages (Thai) keyed by field name.
  final Map<String, String> warningsTh;

  const ValidationResult({
    required this.isValid,
    this.errorsEn = const {},
    this.errorsTh = const {},
    this.warningsEn = const {},
    this.warningsTh = const {},
  });

  /// Convenience factory for a valid result.
  const ValidationResult.valid()
      : isValid = true,
        errorsEn = const {},
        errorsTh = const {},
        warningsEn = const {},
        warningsTh = const {};

  /// Whether any warning messages exist.
  bool get hasWarnings => warningsEn.isNotEmpty;

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
    final warningsEn = <String, String>{};
    final warningsTh = <String, String>{};

    // Weight
    if (weightKg == null) {
      errorsEn['weightKg'] = 'Weight is required';
      errorsTh['weightKg'] = 'กรุณาระบุน้ำหนัก';
    } else if (weightKg <= 0) {
      errorsEn['weightKg'] = 'Weight must be greater than 0';
      errorsTh['weightKg'] = 'น้ำหนักต้องมากกว่า 0';
    } else if (weightKg < 1.0) {
      errorsEn['weightKg'] = 'Weight below 1 kg is implausible';
      errorsTh['weightKg'] = 'น้ำหนักต่ำกว่า 1 กก. เป็นไปไม่ได้ในทางคลินิก';
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
    } else if (heightCm < 30.0) {
      errorsEn['heightCm'] = 'Height below 30 cm is implausible';
      errorsTh['heightCm'] = 'ส่วนสูงต่ำกว่า 30 ซม. เป็นไปไม่ได้ในทางคลินิก';
    } else if (heightCm > 300) {
      errorsEn['heightCm'] = 'Height exceeds 300 cm — please verify';
      errorsTh['heightCm'] = 'ส่วนสูงเกิน 300 ซม. — กรุณาตรวจสอบ';
    }

    // Swapped height/weight cross-field check (implausible BMI)
    if (weightKg != null && heightCm != null && weightKg > 0 && heightCm > 0) {
      final heightM = heightCm / 100.0;
      final bmi = weightKg / (heightM * heightM);
      if (bmi > 120.0 || bmi < 8.0) {
        errorsEn['bmi'] =
            'Implausible BMI (${bmi.toStringAsFixed(1)}) — check if height and weight are swapped';
        errorsTh['bmi'] =
            'ค่า BMI ผิดปกติ (${bmi.toStringAsFixed(1)}) — กรุณาตรวจสอบว่ากรอกน้ำหนักและส่วนสูงสลับกันหรือไม่';
      }
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
      warningsEn: warningsEn,
      warningsTh: warningsTh,
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
  ///
  /// Uses a unified field key so [errorsEn] and [errorsTh] share the exact same key.
  static ValidationResult validatePositive({
    required double? value,
    String? fieldKey,
    required String fieldNameEn,
    required String fieldNameTh,
  }) {
    final key = fieldKey ?? fieldNameEn.toLowerCase().replaceAll(' ', '_');
    if (value == null) {
      return ValidationResult(
        isValid: false,
        errorsEn: {key: '$fieldNameEn is required'},
        errorsTh: {key: 'กรุณาระบุ$fieldNameTh'},
      );
    }
    if (value <= 0) {
      return ValidationResult(
        isValid: false,
        errorsEn: {key: '$fieldNameEn must be greater than 0'},
        errorsTh: {key: '$fieldNameThต้องมากกว่า 0'},
      );
    }
    return const ValidationResult.valid();
  }
}
