// lib/ui/pkpd/controllers/pk_simulation_controller.dart
import 'dart:async';
import 'dart:isolate';
import 'dart:math';
import 'package:flutter/foundation.dart';

import '../../../core/calculators/pk_simulation_engine.dart';
import '../../../core/calculators/renal_calculator.dart';
import '../../../core/calculators/tdm_calculator.dart' hide PkDataPoint;
import '../../../core/models/drug.dart';
import '../../../core/models/patient.dart';
import '../../../core/models/pk_model.dart';
import '../../../core/models/unit.dart';

/// Runner function signature allowing dependency injection for isolate execution.
typedef PkSimulationRunner = Future<PkSimulationResult> Function(
  PkSimulationParams params,
);

/// State management controller for interactive PK-PD simulation and curve visualization.
///
/// Features:
/// - Background simulation offloaded via [Isolate.run]
/// - Sequence-token debouncing to discard stale responses during rapid slider dragging
/// - Immediate touch scrubber interpolation ($O(\log N)$ on UI thread)
/// - Baseline vs Adjusted live delta comparison
/// - Pure Dart immutable DTO passage across isolate boundary
class PkSimulationController extends ChangeNotifier {
  final Drug drug;
  final Patient patient;
  final PkSimulationRunner _runner;

  // Simulation parameters & results
  late final PkSimulationParams _baselineParams;
  late PkSimulationParams _currentParams;

  PkSimulationResult? _baselineResult;
  PkSimulationResult? _adjustedResult;
  PkSimulationComparison? _comparison;

  // Interactive slider & selector state
  late double _clearanceMlMin;
  late double _doseMg;
  late double _tauHours;
  late double _tInfHours;
  late AdministrationRoute _route;
  late PkModelType _modelType;
  late bool _isSteadyState;
  late double _horizonHours;

  // Crosshair scrubber state
  double? _scrubberTimeHours;
  PkDataPoint? _activeAdjustedScrubberPoint;
  PkDataPoint? _activeBaselineScrubberPoint;

  // Asynchronous worker and debouncing tokens
  int _latestRequestId = 0;
  Timer? _debounceTimer;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDisposed = false;

  PkSimulationController({
    required this.drug,
    required this.patient,
    PkSimulationParams? initialParams,
    PkSimulationRunner? runner,
  }) : _runner = runner ?? _defaultIsolateRunner {
    _initializeParameters(initialParams);
    _executeInitialSimulation();
  }

  // --- Getters ---
  PkSimulationParams get baselineParams => _baselineParams;
  PkSimulationParams get currentParams => _currentParams;
  PkSimulationResult? get baselineResult => _baselineResult;
  PkSimulationResult? get adjustedResult => _adjustedResult;
  PkSimulationComparison? get comparison => _comparison;

  double get clearanceMlMin => _clearanceMlMin;
  double get doseMg => _doseMg;
  double get tauHours => _tauHours;
  double get tInfHours => _tInfHours;
  AdministrationRoute get route => _route;
  PkModelType get modelType => _modelType;
  bool get isSteadyState => _isSteadyState;
  double get horizonHours => _horizonHours;

  double? get scrubberTimeHours => _scrubberTimeHours;
  PkDataPoint? get activeAdjustedScrubberPoint => _activeAdjustedScrubberPoint;
  PkDataPoint? get activeBaselineScrubberPoint => _activeBaselineScrubberPoint;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // --- Top-level Isolate Worker Entry Point ---
  static Future<PkSimulationResult> _defaultIsolateRunner(
    PkSimulationParams params,
  ) {
    return Isolate.run(() => PkSimulationEngine.simulate(params));
  }

  static double _resolveCrcl(Patient patient) {
    if (patient.creatinineClearanceMlMin != null &&
        patient.creatinineClearanceMlMin! > 0) {
      return patient.creatinineClearanceMlMin!;
    }
    if (patient.serumCreatinineMgDl != null &&
        patient.serumCreatinineMgDl! > 0) {
      return RenalCalculator.cockcroftGault(
        ageYears: patient.ageYears,
        weightKg: patient.weightKg,
        sex: patient.sex,
        serumCreatinineMgDl: patient.serumCreatinineMgDl!,
      );
    }
    return 65.0;
  }

  // --- Initialization Logic ---
  void _initializeParameters(PkSimulationParams? customParams) {
    if (customParams != null) {
      _baselineParams = customParams;
    } else {
      _baselineParams = _buildInitialParametersFromPatient();
    }
    _currentParams = _baselineParams;

    _doseMg = _baselineParams.dose;
    _tauHours = _baselineParams.tau;
    _tInfHours = _baselineParams.tInf;
    _route = _baselineParams.route;
    _modelType = _baselineParams.modelType;
    _isSteadyState = _baselineParams.isSteadyState;
    _horizonHours = _baselineParams.horizonHours;

    // Calculate baseline CrCl in mL/min
    final crcl = _resolveCrcl(patient);
    _clearanceMlMin = max(10.0, min(150.0, crcl));
  }

  PkSimulationParams _buildInitialParametersFromPatient() {
    final crcl = _resolveCrcl(patient);

    final isVanco = drug.genericName.toLowerCase().contains('vancomycin') ||
        drug.id.toLowerCase().contains('vancomycin');
    final isAmino = drug.id == 'gentamicin' || drug.id == 'amikacin';

    double vd;
    double ke;
    TherapeuticWindow window;

    if (isVanco) {
      vd = TdmCalculator.calculateVd(weightKg: patient.weightKg);
      ke = 0.00083 * crcl + 0.0044;
      window = const TherapeuticWindow(
        mec: 10.0,
        mtc: 20.0,
        targetTroughMin: 10.0,
        targetTroughMax: 20.0,
        targetAuc24Min: 400.0,
        targetAuc24Max: 600.0,
      );
    } else if (isAmino) {
      final dosingWt = TdmCalculator.calculateAminoglycosideDosingWeight(
        weightKg: patient.weightKg,
        heightCm: patient.heightCm,
        isMale: patient.sex == Sex.male,
      );
      vd = TdmCalculator.calculateAminoglycosideVd(dosingWeightKg: dosingWt);
      ke = TdmCalculator.calculateAminoglycosideKe(crclMlMin: crcl);
      window = const TherapeuticWindow(
        mec: 1.0,
        mtc: 10.0,
        targetTroughMax: 2.0,
        targetPeakMin: 5.0,
        targetPeakMax: 10.0,
      );
    } else {
      vd = 0.7 * patient.weightKg;
      ke = 0.00083 * crcl + 0.0044;
      window = const TherapeuticWindow(mec: 10.0, mtc: 25.0);
    }

    return PkSimulationParams(
      modelType: PkModelType.oneCompartment,
      route: AdministrationRoute.ivIntermittentInfusion,
      dose: 1000.0,
      tau: 12.0,
      tInf: 1.0,
      pk1: PkParameters(vd: vd, ke: ke),
      therapeuticWindow: window,
      isSteadyState: true,
      horizonHours: 24.0,
      pointsPerPhase: 40,
    );
  }

  Future<void> _executeInitialSimulation() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final baseResult = await _runner(_baselineParams);
      if (_isDisposed) return;
      _baselineResult = baseResult;
      _adjustedResult = baseResult;
      _comparison = PkSimulationEngine.compareRegimens(
        baseline: baseResult,
        adjusted: baseResult,
      );
    } catch (e) {
      if (_isDisposed) return;
      _errorMessage = 'Simulation failed: $e';
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  // --- Interactive Slider & Control Mutators ---

  /// Adjusts CrCl/clearance slider with optimistic UI update and 20ms debounce.
  void updateClearance(double crClMlMin) {
    if ((_clearanceMlMin - crClMlMin).abs() < 1e-4) return;
    _clearanceMlMin = crClMlMin;

    final isAmino = drug.id == 'gentamicin' || drug.id == 'amikacin';
    final newKe = isAmino
        ? TdmCalculator.calculateAminoglycosideKe(crclMlMin: crClMlMin)
        : (0.00083 * crClMlMin + 0.0044);

    final currentPk1 = _currentParams.pk1!;
    _currentParams = _currentParams.copyWith(
      pk1: currentPk1.copyWith(ke: newKe),
    );

    _scheduleSimulationDebounced();
  }

  /// Adjusts dose slider with optimistic UI update and 20ms debounce.
  void updateDose(double doseMg) {
    if ((_doseMg - doseMg).abs() < 1e-4) return;
    _doseMg = doseMg;
    _currentParams = _currentParams.copyWith(dose: doseMg);
    _scheduleSimulationDebounced();
  }

  /// Selects dosing interval tau (e.g. q6h, q8h, q12h, q24h).
  void updateInterval(double tauHours) {
    if ((_tauHours - tauHours).abs() < 1e-4) return;
    _tauHours = tauHours;
    _horizonHours = max(24.0, 2 * tauHours);
    _currentParams = _currentParams.copyWith(
      tau: tauHours,
      horizonHours: _horizonHours,
    );
    _triggerSimulationImmediate();
  }

  /// Selects infusion duration (e.g. 1.0h, 2.0h).
  void updateInfusionDuration(double tInfHours) {
    if ((_tInfHours - tInfHours).abs() < 1e-4) return;
    _tInfHours = tInfHours;
    _currentParams = _currentParams.copyWith(tInf: tInfHours);
    _scheduleSimulationDebounced();
  }

  /// Switches route of administration.
  void updateRoute(AdministrationRoute route) {
    if (_route == route) return;
    _route = route;
    _currentParams = _currentParams.copyWith(route: route);
    _triggerSimulationImmediate();
  }

  /// Resets adjusted parameters back to baseline.
  void resetToBaseline() {
    _debounceTimer?.cancel();
    _latestRequestId++;
    _isLoading = false;
    _errorMessage = null;

    _currentParams = _baselineParams;
    _doseMg = _baselineParams.dose;
    _tauHours = _baselineParams.tau;
    _tInfHours = _baselineParams.tInf;
    _route = _baselineParams.route;
    _horizonHours = _baselineParams.horizonHours;

    final crcl = _resolveCrcl(patient);
    _clearanceMlMin = max(10.0, min(150.0, crcl));

    _adjustedResult = _baselineResult;
    if (_baselineResult != null) {
      _comparison = PkSimulationEngine.compareRegimens(
        baseline: _baselineResult!,
        adjusted: _baselineResult!,
      );
    }
    _updateScrubberPoints();
    notifyListeners();
  }

  // --- Asynchronous Worker & Sequence-Token Debounce ---

  void _scheduleSimulationDebounced() {
    _debounceTimer?.cancel();
    _isLoading = true;
    notifyListeners();

    _debounceTimer = Timer(const Duration(milliseconds: 20), () {
      _dispatchIsolateSimulation();
    });
  }

  void _triggerSimulationImmediate() {
    _debounceTimer?.cancel();
    _dispatchIsolateSimulation();
  }

  Future<void> _dispatchIsolateSimulation() async {
    final requestId = ++_latestRequestId;
    _isLoading = true;
    _errorMessage = null;

    try {
      final result = await _runner(_currentParams);

      // Discard stale in-flight results or if controller was disposed
      if (requestId != _latestRequestId || _isDisposed) {
        return;
      }

      _adjustedResult = result;
      if (_baselineResult != null) {
        _comparison = PkSimulationEngine.compareRegimens(
          baseline: _baselineResult!,
          adjusted: result,
        );
      }
      _updateScrubberPoints();
    } catch (e) {
      if (requestId != _latestRequestId || _isDisposed) return;
      _errorMessage = 'Calculation error: $e';
    } finally {
      if (requestId == _latestRequestId && !_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  // --- Touch Scrubber Interpolation ($O(\log N)$ on UI Thread) ---

  /// Updates active scrubber position and computes interpolated concentration.
  void setScrubberTime(double? timeHours) {
    if (_scrubberTimeHours == timeHours) return;
    _scrubberTimeHours = timeHours;
    _updateScrubberPoints();
    notifyListeners();
  }

  void _updateScrubberPoints() {
    final t = _scrubberTimeHours;
    if (t == null) {
      _activeAdjustedScrubberPoint = null;
      _activeBaselineScrubberPoint = null;
      return;
    }

    if (_adjustedResult != null) {
      _activeAdjustedScrubberPoint = _interpolatePoint(_adjustedResult!.curve, t);
    }
    if (_baselineResult != null) {
      _activeBaselineScrubberPoint = _interpolatePoint(_baselineResult!.curve, t);
    }
  }

  /// Binary search + linear interpolation on boundary-pinned curve.
  PkDataPoint? _interpolatePoint(List<PkDataPoint> curve, double targetTime) {
    if (curve.isEmpty) return null;
    if (!targetTime.isFinite) return null;
    if (targetTime <= curve.first.timeHours) return curve.first;
    if (targetTime >= curve.last.timeHours) return curve.last;

    int low = 0;
    int high = curve.length - 1;

    while (low <= high) {
      final mid = (low + high) >> 1;
      final midTime = curve[mid].timeHours;

      if ((midTime - targetTime).abs() < 1e-5) {
        return curve[mid];
      } else if (midTime < targetTime) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    // low is now index of first point > targetTime, high is low - 1
    final p0 = curve[high];
    final p1 = curve[low];
    final dt = p1.timeHours - p0.timeHours;
    if (dt <= 0) return p0;

    final fraction = (targetTime - p0.timeHours) / dt;
    final c =
        p0.concentrationMgL + fraction * (p1.concentrationMgL - p0.concentrationMgL);

    return PkDataPoint(
      timeHours: targetTime,
      concentrationMgL: max(0.0, c),
      isInfusing: p0.isInfusing && p1.isInfusing,
      zone: _currentParams.therapeuticWindow?.classify(c),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _debounceTimer?.cancel();
    super.dispose();
  }
}
