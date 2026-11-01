import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drug_dosage_calculator/core/calculators/tdm_calculator.dart';
import 'package:drug_dosage_calculator/core/models/models.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';
import 'package:drug_dosage_calculator/ui/tdm_screen.dart';

void main() {
  group('TDM Calculator Pure Math Tests', () {
    test('calculateVd - standard 0.7 L/kg', () {
      final vd = TdmCalculator.calculateVd(weightKg: 70);
      expect(vd, closeTo(49.0, 0.1));
    });

    test('calculateKe - based on normal CrCl', () {
      final ke = TdmCalculator.calculateKe(crclMlMin: 100);
      // (0.00083 * 100) + 0.0044 = 0.083 + 0.0044 = 0.0874
      expect(ke, closeTo(0.0874, 0.0001));
    });

    test('calculateKe - anuric patient (CrCl == 0)', () {
      final ke = TdmCalculator.calculateKe(crclMlMin: 0);
      expect(ke, closeTo(0.0044, 0.0001));
    });

    test('calculateHalfLife - valid Ke', () {
      final t12 = TdmCalculator.calculateHalfLife(ke: 0.0874);
      // ln(2) / 0.0874 = 0.693147 / 0.0874 ≈ 7.93
      expect(t12, closeTo(7.93, 0.1));
    });

    test('calculateLoadingDose - standard patient', () {
      final doseRange = TdmCalculator.calculateLoadingDose(weightKg: 70);
      // 70 * 25 = 1750, 70 * 30 = 2100
      expect(doseRange[0], equals(1750.0));
      expect(doseRange[1], equals(2100.0));
    });

    test('calculateLoadingDose - capped at absolute max (obese patient)', () {
      final doseRange = TdmCalculator.calculateLoadingDose(
        weightKg: 150,
        absoluteMaxMg: 3000.0,
      );
      expect(doseRange[0], equals(3000.0));
      expect(doseRange[1], equals(3000.0));
    });

    test('predictPeak and predictTrough - 1-compartment steady state equations', () {
      // 1000 mg q12h infused over 1h, Vd = 49.0 L, Ke = 0.0874 hr^-1
      final peak = TdmCalculator.predictPeak(
        dose: 1000,
        tau: 12,
        tInf: 1,
        vd: 49.0,
        ke: 0.0874,
      );
      final trough = TdmCalculator.predictTrough(
        dose: 1000,
        tau: 12,
        tInf: 1,
        vd: 49.0,
        ke: 0.0874,
      );
      // peakSS = (1000 / (1 * 49 * 0.0874)) * (1 - e^-0.0874) / (1 - e^(-0.0874 * 12)) ≈ 30.08 mg/L
      // troughSS = peakSS * e^(-0.0874 * 11) ≈ 11.50 mg/L
      expect(peak, closeTo(30.08, 0.05));
      expect(trough, closeTo(11.50, 0.05));
    });

    test('concentrationAtSteadyStateTime is continuous at t=0, t=tInf (Cmax,ss), and t=tau (Cmin,ss)', () {
      const dose = 1000.0;
      const tau = 12.0;
      const tInf = 1.0;
      const vd = 49.0;
      const ke = 0.0874;

      final peak = TdmCalculator.predictPeak(dose: dose, tau: tau, tInf: tInf, vd: vd, ke: ke);
      final trough = TdmCalculator.predictTrough(dose: dose, tau: tau, tInf: tInf, vd: vd, ke: ke);

      final c0 = TdmCalculator.concentrationAtSteadyStateTime(
        timeHours: 0.0,
        dose: dose,
        tau: tau,
        tInf: tInf,
        vd: vd,
        ke: ke,
      );
      final cPeak = TdmCalculator.concentrationAtSteadyStateTime(
        timeHours: tInf,
        dose: dose,
        tau: tau,
        tInf: tInf,
        vd: vd,
        ke: ke,
      );
      final cTau = TdmCalculator.concentrationAtSteadyStateTime(
        timeHours: tau,
        dose: dose,
        tau: tau,
        tInf: tInf,
        vd: vd,
        ke: ke,
      );

      expect(c0, closeTo(trough, 1e-6));
      expect(cPeak, closeTo(peak, 1e-6));
      expect(cTau, closeTo(trough, 1e-6));
    });

    test('generateSteadyStateProfile generates accurate curves and trapezoidal AUC matches analytical AUC_tau', () {
      final profile = TdmCalculator.generateSteadyStateProfile(
        dose: 1000.0,
        tau: 12.0,
        tInf: 1.5,
        vd: 49.0,
        ke: 0.0874,
        pointsPerPhase: 100,
      );

      expect(profile.singleIntervalCurve.first.timeHours, equals(0.0));
      expect(profile.singleIntervalCurve.first.concentrationMgL, closeTo(profile.troughMgL, 1e-6));
      expect(profile.singleIntervalCurve.last.timeHours, equals(12.0));
      expect(profile.singleIntervalCurve.last.concentrationMgL, closeTo(profile.troughMgL, 1e-6));

      // Verify exact peak point is included at t = tInf
      final peakPoint = profile.singleIntervalCurve.firstWhere(
        (p) => (p.timeHours - 1.5).abs() < 1e-6,
      );
      expect(peakPoint.concentrationMgL, closeTo(profile.peakMgL, 1e-6));

      // Numerical trapezoidal integration over [0, tau] must match analytical Dose / (Vd * Ke)
      double trapezoidalAuc = 0.0;
      for (var i = 1; i < profile.singleIntervalCurve.length; i++) {
        final p0 = profile.singleIntervalCurve[i - 1];
        final p1 = profile.singleIntervalCurve[i];
        trapezoidalAuc += 0.5 * (p0.concentrationMgL + p1.concentrationMgL) * (p1.timeHours - p0.timeHours);
      }
      expect(trapezoidalAuc, closeTo(profile.aucTauMgHrL, 0.05));
      expect(profile.auc24MgHrL, closeTo(profile.aucTauMgHrL * 2.0, 1e-6));

      // 1000 mg over 1.5 hr (90 min) = 11.11 mg/min > 10 mg/min -> Red Man Syndrome risk
      expect(profile.infusionRateMgPerMin, closeTo(11.11, 0.05));
      expect(profile.hasRedManSyndromeRisk, isTrue);
    });

    test('calculateVdWithModel supports Standard (0.70), Obesity (0.52), and ICU Sepsis (0.85) models', () {
      expect(
        TdmCalculator.calculateVdWithModel(
          weightKg: 100.0,
          model: VancomycinVdModel.standardAdult,
        ),
        closeTo(70.0, 1e-6),
      );
      expect(
        TdmCalculator.calculateVdWithModel(
          weightKg: 100.0,
          model: VancomycinVdModel.obesity,
        ),
        closeTo(52.0, 1e-6),
      );
      expect(
        TdmCalculator.calculateVdWithModel(
          weightKg: 100.0,
          model: VancomycinVdModel.criticallyIllIcu,
        ),
        closeTo(85.0, 1e-6),
      );
    });

    test('analyzeTwoPointSawchukZaske recovers exact Vd, Ke, Cmax, and Cmin from 2 post-infusion levels', () {
      // Ground truth regimen: 1000 mg q12h infused over 1.0h, Vd = 45.0 L, Ke = 0.09 hr^-1
      const dose = 1000.0;
      const tau = 12.0;
      const tInf = 1.0;
      const trueVd = 45.0;
      const trueKe = 0.09;

      final expectedPeak = TdmCalculator.predictPeak(
        dose: dose,
        tau: tau,
        tInf: tInf,
        vd: trueVd,
        ke: trueKe,
      );
      final expectedTrough = TdmCalculator.predictTrough(
        dose: dose,
        tau: tau,
        tInf: tInf,
        vd: trueVd,
        ke: trueKe,
      );

      // Draw C1 at 1.0 hr after completion of infusion (t = 2.0h) and C2 at trough (t = 12.0h, deltaHours = 10.0h)
      final c1 = TdmCalculator.concentrationAtSteadyStateTime(
        timeHours: 2.0,
        dose: dose,
        tau: tau,
        tInf: tInf,
        vd: trueVd,
        ke: trueKe,
      );
      final c2 = expectedTrough;

      final analysis = TdmCalculator.analyzeTwoPointSawchukZaske(
        dose: dose,
        tau: tau,
        tInf: tInf,
        c1: c1,
        c2: c2,
        deltaHours: 10.0,
        t1PostInfusionHours: 1.0,
        isVancomycin: true,
      );

      expect(analysis.individualKe, closeTo(trueKe, 1e-6));
      expect(analysis.truePeakMgL, closeTo(expectedPeak, 1e-5));
      expect(analysis.trueTroughMgL, closeTo(expectedTrough, 1e-5));
      expect(analysis.individualVdLiters, closeTo(trueVd, 1e-4));
      expect(analysis.hasShortSamplingIntervalWarning, isFalse);
      expect(analysis.hasDistributionPhaseWarning, isFalse);
    });

    test('evaluateHartfordNomogram classifies Gentamicin and Amikacin random levels into q24h, q36h, q48h, and Hold zones', () {
      // At 10 hours post-dose (midpoint of 6-14h):
      // q24 boundary = 9.0 - (7/8)*4 = 5.5 mg/L
      // q36 boundary = 11.0 - (6.5/8)*4 = 7.75 mg/L
      // q48 boundary = 13.0 - (6.0/8)*4 = 10.0 mg/L
      final z24 = TdmCalculator.evaluateHartfordNomogram(
        randomLevelMgL: 4.0,
        hoursPostDose: 10.0,
      );
      expect(z24.zone, equals(HartfordNomogramZone.q24h));
      expect(z24.recommendedIntervalHours, equals(24));

      final z36 = TdmCalculator.evaluateHartfordNomogram(
        randomLevelMgL: 6.5,
        hoursPostDose: 10.0,
      );
      expect(z36.zone, equals(HartfordNomogramZone.q36h));
      expect(z36.recommendedIntervalHours, equals(36));

      // Amikacin 18.0 mg/L at 10h -> halved to 9.0 mg/L -> falls in q48h zone (between 7.75 and 10.0)
      final z48Amikacin = TdmCalculator.evaluateHartfordNomogram(
        randomLevelMgL: 18.0,
        hoursPostDose: 10.0,
        isAmikacin: true,
      );
      expect(z48Amikacin.normalizedGentamicinEquivalentMgL, closeTo(9.0, 1e-6));
      expect(z48Amikacin.zone, equals(HartfordNomogramZone.q48h));
      expect(z48Amikacin.recommendedIntervalHours, equals(48));

      final zHold = TdmCalculator.evaluateHartfordNomogram(
        randomLevelMgL: 11.5,
        hoursPostDose: 10.0,
      );
      expect(zHold.zone, equals(HartfordNomogramZone.aboveQ48hHoldAndMonitor));
      expect(zHold.recommendedIntervalHours, isNull);
    });
  });

  group('TdmScreen & SteadyStatePkChart Widget Tests', () {
    testWidgets('TdmScreen renders Cmax,ss, Cmin,ss, AUC24, PK Graph, and responds to interval & infusion chips', (tester) async {
      const patient = Patient(
        id: 'tdm-pt-1',
        ageYears: 45,
        weightKg: 70.0,
        heightCm: 172.0,
        sex: Sex.male,
        serumCreatinineMgDl: 0.9,
        isScrStable: true,
      );
      final vanco = DrugDatabase.findById('vancomycin')!;

      await tester.pumpWidget(
        MaterialApp(
          home: TdmScreen(
            patient: patient,
            drug: vanco,
            isThai: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Peak, Trough, and AUC24 are rendered
      expect(find.byKey(const Key('tdm_auc24_card')), findsOneWidget);
      expect(find.byKey(const Key('tdm_peak_card')), findsOneWidget);
      expect(find.byKey(const Key('tdm_trough_card')), findsOneWidget);

      // Default 1000 mg over 1.0 hr = 16.7 mg/min (> 10 mg/min) -> shows Red Man Syndrome warning
      expect(find.byKey(const Key('tdm_red_man_warning')), findsOneWidget);

      // Tap 2.0 hr infusion chip -> 1000 mg over 120 min = 8.3 mg/min (<= 10 mg/min) -> warning clears
      await tester.ensureVisible(find.byKey(const Key('tdm_infusion_chip_120m')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tdm_infusion_chip_120m')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tdm_red_man_warning')), findsNothing);

      // Tap q8h interval chip -> updates interval to 8 hr
      await tester.ensureVisible(find.byKey(const Key('tdm_interval_chip_8')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tdm_interval_chip_8')));
      await tester.pumpAndSettle();
      expect(find.text('8'), findsWidgets);

      // Scroll down to verify the Steady-State PK Graph and horizon toggle are rendered
      await tester.scrollUntilVisible(
        find.byKey(const Key('tdm_steady_state_pk_chart')),
        200.0,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tdm_steady_state_pk_chart')), findsOneWidget);
      expect(find.byKey(const Key('tdm_graph_horizon_toggle')), findsOneWidget);
    });

    testWidgets('TdmScreen supports 2-Point Sawchuk-Zaske Measured Levels and Aminoglycoside Hartford Nomogram', (tester) async {
      const patient = Patient(
        id: 'tdm-pt-2',
        ageYears: 55,
        weightKg: 75.0,
        heightCm: 170.0,
        sex: Sex.male,
        serumCreatinineMgDl: 1.1,
        isScrStable: true,
      );
      final genta = DrugDatabase.findById('gentamicin')!;

      await tester.pumpWidget(
        MaterialApp(
          home: TdmScreen(
            patient: patient,
            drug: genta,
            isThai: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Hartford Nomogram card is rendered for Gentamicin
      expect(find.byKey(const Key('tdm_hartford_nomogram_card')), findsOneWidget);
      expect(find.byKey(const Key('tdm_hartford_result_badge')), findsOneWidget);

      // Enter 8.5 mg/L at 8.0 hr -> q36h zone (q24 boundary at 8h is 7.25, q36 boundary is 9.375)
      await tester.enterText(find.byKey(const Key('tdm_hartford_level_input')), '8.5');
      await tester.pumpAndSettle();
      expect(find.textContaining('Zone q36h'), findsOneWidget);

      // Switch to 2-Point Sawchuk-Zaske mode
      await tester.ensureVisible(find.text('2-Point Measured Levels'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2-Point Measured Levels'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tdm_sawchuk_zaske_panel')), findsOneWidget);
      expect(find.textContaining('Individualized PK Applied'), findsOneWidget);
    });
  });
}
