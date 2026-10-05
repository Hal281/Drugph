import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/models/patient.dart';
import 'package:drug_dosage_calculator/core/models/unit.dart';

void main() {
  group('Patient copyWith & privacy tests (A4)', () {
    test('copyWith can clear nullable fields using sentinel', () {
      const patient = Patient(
        id: 'p1',
        patientName: 'Somchai Prasert',
        hospitalNumber: 'HN-123456',
        weightKg: 70,
        heightCm: 170,
        ageYears: 45,
        ageMonths: 6,
        sex: Sex.male,
        serumCreatinineMgDl: 1.2,
        creatinineClearanceMlMin: 80.0,
        eGfrMlMinPer173m2: 85.0,
        allergies: ['Penicillin'],
      );

      // Clearing serumCreatinineMgDl to null
      final clearedScr = patient.copyWith(serumCreatinineMgDl: null);
      expect(clearedScr.serumCreatinineMgDl, isNull, reason: 'SCr must be cleared to null');

      // Clearing ageMonths
      final clearedAgeMonths = patient.copyWith(ageMonths: null);
      expect(clearedAgeMonths.ageMonths, isNull);

      // Clearing name and HN
      final clearedIdent = patient.copyWith(patientName: null, hospitalNumber: null);
      expect(clearedIdent.patientName, isNull);
      expect(clearedIdent.hospitalNumber, isNull);
    });

    test('Patient.toString redacts name, HN, and allergies for PDPA/HIPAA privacy', () {
      const patient = Patient(
        id: 'p1',
        patientName: 'Somchai Prasert',
        hospitalNumber: 'HN-999888',
        weightKg: 70,
        heightCm: 170,
        ageYears: 45,
        sex: Sex.male,
        allergies: ['Amoxicillin', 'Aspirin'],
      );

      final str = patient.toString();
      expect(str.contains('Somchai Prasert'), isFalse, reason: 'Patient name must be redacted');
      expect(str.contains('HN-999888'), isFalse, reason: 'HN must be redacted');
      expect(str.contains('Amoxicillin'), isFalse, reason: 'Allergies must be redacted in toString');
    });
  });
}
