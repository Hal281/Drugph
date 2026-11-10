import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';

void main() {
  setUpAll(() {
    DrugDatabase.warmUp();
  });

  group('Milestone 1 — Critical ICU Drugs Formulary Verification Suite', () {
    test('Vasopressin is registered in DrugDatabase with complete clinical monograph and dilution', () {
      final drug = DrugDatabase.findById('vasopressin');
      expect(drug, isNotNull);
      expect(drug!.genericName, 'Vasopressin');
      expect(drug.isHighAlert, isTrue);
      expect(drug.category, DrugCategory.vasopressor);
      expect(drug.nameTh, 'วาโซเพรสซิน');

      // Monograph & Provenance
      expect(drug.monograph, isNotNull);
      expect(drug.monograph!.textbookName, contains('Surviving Sepsis Campaign'));
      expect(drug.provenance, isNotNull);

      // Dilution compatibility: 20 units in 100 mL = 0.2 units/mL
      expect(drug.ivDiluentCompatibility, isNotNull);
      expect(drug.ivDiluentCompatibility!.preferredDiluent, IvDiluent.nss);
      expect(drug.ivDiluentCompatibility!.compatibleDiluents, contains(IvDiluent.d5w));
      expect(drug.ivDiluentCompatibility!.stabilityNoteEn, contains('0.2 units/mL'));

      // Regimen: fixed 0.03 units/min (range 0.01 - 0.04)
      expect(drug.regimens, isNotEmpty);
      final reg = drug.regimens.first;
      expect(reg.route, DoseRoute.ivInfusion);
      expect(reg.dosingType, DosingType.titrated);
      expect(reg.rateUnit, RateUnit.uMin);
      expect(reg.continuousRateMin, 0.01);
      expect(reg.continuousRateMax, 0.04);
      expect(reg.standardDilutionMgPerMl, 0.2);
      expect(reg.limits?.maxInfusionRate, 0.04);

      // Search retrieval
      final searchResults = DrugDatabase.searchDetailed('vasopressin');
      expect(searchResults.first.drug.id, 'vasopressin');
      final searchTh = DrugDatabase.searchDetailed('วาโซเพรสซิน');
      expect(searchTh.first.drug.id, 'vasopressin');
      final searchBrand = DrugDatabase.searchDetailed('Pitressin');
      expect(searchBrand.first.drug.id, 'vasopressin');
    });

    test('Propofol is registered with PRIS warnings, neat emulsion specs, and ICU sedation titration', () {
      final drug = DrugDatabase.findById('propofol');
      expect(drug, isNotNull);
      expect(drug!.genericName, 'Propofol');
      expect(drug.isHighAlert, isTrue);
      expect(drug.category, DrugCategory.sedative);
      expect(drug.nameTh, 'โพรโพฟอล');

      // PRIS boxed warning in specialNotes and monograph
      expect(drug.specialNotes, contains('PRIS Warning'));
      expect(drug.specialNotesTh, contains('PRIS'));
      expect(drug.monograph!.dosingGuideline, contains('PRIS'));

      // Dilution compatibility: Neat lipid emulsion (10 mg/mL = 1%), incompatible with electrolytes
      expect(drug.ivDiluentCompatibility, isNotNull);
      expect(drug.ivDiluentCompatibility!.compatibleDiluents, contains(IvDiluent.d5w));
      expect(drug.ivDiluentCompatibility!.incompatibleDiluents, contains(IvDiluent.nss));
      expect(drug.ivDiluentCompatibility!.incompatibilityReasonEn, contains('Emulsion breakdown'));

      // Regimens: ICU sedation (5-50 mcg/kg/min) and Procedural sedation
      final icuReg = drug.regimens.firstWhere((r) => r.indication!.contains('ICU Sedation'));
      expect(icuReg.rateUnit, RateUnit.mcgKgMin);
      expect(icuReg.continuousRateMin, 5.0);
      expect(icuReg.continuousRateMax, 50.0);
      expect(icuReg.standardDilutionMgPerMl, 10.0);
      expect(icuReg.limits?.maxInfusionRate, 83.0); // PRIS threshold

      // Search retrieval
      final searchRes = DrugDatabase.searchDetailed('propofol');
      expect(searchRes.first.drug.id, 'propofol');
      final searchDiprivan = DrugDatabase.searchDetailed('diprivan');
      expect(searchDiprivan.first.drug.id, 'propofol');
    });

    test('Dexmedetomidine is registered with delirium-sparing indication, 4 mcg/mL dilution', () {
      final drug = DrugDatabase.findById('dexmedetomidine');
      expect(drug, isNotNull);
      expect(drug!.genericName, 'Dexmedetomidine');
      expect(drug.isHighAlert, isTrue);
      expect(drug.category, DrugCategory.sedative);
      expect(drug.nameTh, 'เดกซ์เมดีโทมิดีน');

      // Monograph & Provenance
      expect(drug.monograph, isNotNull);
      expect(drug.monograph!.textbookName, contains('PADIS Guidelines'));
      expect(drug.provenance, isNotNull);

      // Dilution: 200 mcg in 50 mL = 4 mcg/mL (0.004 mg/mL)
      expect(drug.ivDiluentCompatibility, isNotNull);
      expect(drug.ivDiluentCompatibility!.preferredDiluent, IvDiluent.nss);
      expect(drug.ivDiluentCompatibility!.stabilityNoteEn, contains('4 mcg/mL'));

      // Regimen: 0.2-1.4 mcg/kg/hr
      expect(drug.regimens, isNotEmpty);
      final reg = drug.regimens.first;
      expect(reg.rateUnit, RateUnit.mcgKgHr);
      expect(reg.continuousRateMin, 0.2);
      expect(reg.continuousRateMax, 1.4);
      expect(reg.standardDilutionMgPerMl, 0.004);
      expect(reg.limits?.maxInfusionRate, 1.4);

      // Search retrieval
      final searchRes = DrugDatabase.searchDetailed('dexmedetomidine');
      expect(searchRes.first.drug.id, 'dexmedetomidine');
      final searchPrecedex = DrugDatabase.searchDetailed('precedex');
      expect(searchPrecedex.first.drug.id, 'dexmedetomidine');
    });

    test('Midazolam is registered with ICU sedation and refractory status epilepticus regimens', () {
      final drug = DrugDatabase.findById('midazolam');
      expect(drug, isNotNull);
      expect(drug!.genericName, 'Midazolam');
      expect(drug.isHighAlert, isTrue);
      expect(drug.category, DrugCategory.sedative);
      expect(drug.nameTh, 'มิดาโซแลม');

      // Dilution: 50 mg in 50 mL = 1 mg/mL
      expect(drug.ivDiluentCompatibility, isNotNull);
      expect(drug.ivDiluentCompatibility!.preferredDiluent, IvDiluent.nss);
      expect(drug.ivDiluentCompatibility!.stabilityNoteEn, contains('1.0 mg/mL'));

      // Regimens: ICU Sedation (0.02-0.10 mg/kg/hr), Status Epilepticus (0.05-2.0 mg/kg/hr)
      final icuReg = drug.regimens.firstWhere((r) => r.indication!.contains('ICU Sedation'));
      expect(icuReg.rateUnit, RateUnit.mgKgHr);
      expect(icuReg.continuousRateMin, 0.02);
      expect(icuReg.continuousRateMax, 0.10);
      expect(icuReg.standardDilutionMgPerMl, 1.0);

      final statusReg = drug.regimens.firstWhere((r) => r.indication!.contains('Refractory Status'));
      expect(statusReg.rateUnit, RateUnit.mgKgHr);
      expect(statusReg.continuousRateMin, 0.05);
      expect(statusReg.continuousRateMax, 2.0);

      // Search retrieval
      final searchRes = DrugDatabase.searchDetailed('midazolam');
      expect(searchRes.first.drug.id, 'midazolam');
      final searchDormicum = DrugDatabase.searchDetailed('dormicum');
      expect(searchDormicum.first.drug.id, 'midazolam');
    });

    test('All 4 ICU drugs are present in DrugDatabase.allDrugs', () {
      final ids = DrugDatabase.allDrugs.map((d) => d.id).toSet();
      expect(ids.contains('vasopressin'), isTrue);
      expect(ids.contains('propofol'), isTrue);
      expect(ids.contains('dexmedetomidine'), isTrue);
      expect(ids.contains('midazolam'), isTrue);
    });
  });
}
