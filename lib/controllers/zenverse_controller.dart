import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import '../core/game_constants.dart';
import '../models/zenverse_model.dart';
import '../painters/coconut_world_painter.dart';

enum CameraRotationMode {
  manual, // ✋ Serbest Bakış (360° Oto Kapalı)
  normalOrbit, // 🔄 360° Oto Tur
  slowZenOrbit, // 🐢 Yavaş 360° Zen
  pendulumSweep, // 🎬 Sinematik Sarkaç
  guidedPoiTour, // 📍 Rehberli Durak Turu
}

/// High-performance 60-120 FPS game loop & camera controller for ZenVerse.
///
/// Passed directly as `repaint: controller` to [CustomPainter] inside a
/// [RepaintBoundary] so frame ticks repaint ONLY the canvas layer without
/// triggering `setState()` or rebuilding the Flutter UI widget tree.
class ZenVerseController extends ChangeNotifier {
  ZenVerseController({
    required this.scenicPoints,
    double initialYaw = 15.0,
    double initialPitch = 0.0,
    CoconutAtmosphereMode initialAtmosphere = CoconutAtmosphereMode.sunset,
    CoconutStyleMode initialStyle = CoconutStyleMode.natural,
    CameraRotationMode initialRotationMode = CameraRotationMode.manual,
    this.isMenuPreview = false,
  })  : _cameraYaw = initialYaw,
        _cameraPitch = initialPitch,
        _pendulumCenterYaw = initialYaw,
        _atmosphereMode = initialAtmosphere,
        _styleMode = initialStyle,
        _rotationMode = initialRotationMode {
    roundedYawNotifier = ValueNotifier<int>(initialYaw.round() % 360);
    elapsedSecondsNotifier = ValueNotifier<int>(0);
  }

  List<ScenicPoint> scenicPoints;
  final bool isMenuPreview;

  double _time = 0.0;
  double _cameraYaw;
  double _cameraPitch;
  double _yawVelocity = 0.0;
  double? _targetYaw;
  double _pendulumCenterYaw;
  double _cameraZoom = 1.0;
  double _coconutPulse = 0.0;

  CoconutStyleMode _styleMode;
  CoconutAtmosphereMode _atmosphereMode;
  CameraRotationMode _rotationMode;
  bool _autoOrbitPreview = true;

  int _poiTourIndex = 0;
  double _poiPauseTimer = 0.0;

  /// Coarse-grained notifiers for UI HUD badges so widgets only rebuild when
  /// the integer degree or integer second actually changes (not 60x/sec!).
  late final ValueNotifier<int> roundedYawNotifier;
  late final ValueNotifier<int> elapsedSecondsNotifier;

  double get time => _time;
  double get cameraYaw => _cameraYaw;
  double get cameraPitch => _cameraPitch;
  double get cameraZoom => _cameraZoom;
  double get coconutPulse => _coconutPulse;
  CoconutStyleMode get styleMode => _styleMode;
  bool get isArcadeMode => _styleMode == CoconutStyleMode.arcade;
  CoconutAtmosphereMode get atmosphereMode => _atmosphereMode;
  CameraRotationMode get rotationMode => _rotationMode;
  bool get autoOrbitPreview => _autoOrbitPreview;

  void updateScenicPoints(List<ScenicPoint> points) {
    scenicPoints = points;
    _targetYaw = null;
    notifyListeners();
  }

  /// Advances the simulation by [rawDt] seconds and notifies only the canvas
  /// repaint listener (plus coarse integer HUD notifiers when needed).
  void tick(double rawDt, {bool? isMenuPreview}) {
    final double dt = rawDt.clamp(0.001, GameConstants.maxFrameDeltaSeconds);
    _time += dt;

    if (isMenuPreview ?? this.isMenuPreview) {
      _tickMenuPreview(dt);
    } else {
      _tickSimulatorCamera(dt);
    }

    if (_coconutPulse > 0.001) {
      _coconutPulse *= math.pow(0.015, dt).toDouble();
    } else {
      _coconutPulse = 0.0;
    }

    final int newRoundedYaw = _cameraYaw.round() % 360;
    if (roundedYawNotifier.value != newRoundedYaw) {
      roundedYawNotifier.value = newRoundedYaw;
    }

    final int newElapsedSec = _time.floor();
    if (elapsedSecondsNotifier.value != newElapsedSec) {
      elapsedSecondsNotifier.value = newElapsedSec;
    }

    notifyListeners();
  }

  void _tickMenuPreview(double dt) {
    if (_targetYaw != null) {
      double diff = (_targetYaw! - _cameraYaw) % 360.0;
      if (diff > 180.0) diff -= 360.0;
      if (diff < -180.0) diff += 360.0;
      if (diff.abs() < 0.5) {
        _cameraYaw = _targetYaw! % 360.0;
        _targetYaw = null;
      } else {
        final double step = diff * (1.0 - math.pow(0.002, dt).toDouble());
        _cameraYaw = (_cameraYaw + step) % 360.0;
        if (_cameraYaw < 0) _cameraYaw += 360.0;
      }
    } else if (_autoOrbitPreview && _rotationMode != CameraRotationMode.manual) {
      _cameraYaw =
          (_cameraYaw + GameConstants.previewAutoOrbitSpeed * dt) % 360.0;
    }
  }

  void _tickSimulatorCamera(double dt) {
    if (_targetYaw != null) {
      double diff = (_targetYaw! - _cameraYaw) % 360.0;
      if (diff > 180.0) diff -= 360.0;
      if (diff < -180.0) diff += 360.0;

      if (diff.abs() < 0.4) {
        _cameraYaw = _targetYaw! % 360.0;
        _targetYaw = null;
      } else {
        final double step = diff * (1.0 - math.pow(0.0015, dt).toDouble());
        _cameraYaw = (_cameraYaw + step) % 360.0;
        if (_cameraYaw < 0) _cameraYaw += 360.0;
      }
      return;
    }

    switch (_rotationMode) {
      case CameraRotationMode.manual:
        if (_yawVelocity.abs() > 0.05) {
          _cameraYaw = (_cameraYaw + _yawVelocity * dt) % 360.0;
          if (_cameraYaw < 0) _cameraYaw += 360.0;
          _yawVelocity *= math.pow(0.04, dt).toDouble();
        }
      case CameraRotationMode.normalOrbit:
        _cameraYaw =
            (_cameraYaw + GameConstants.normalOrbitSpeed * dt) % 360.0;
      case CameraRotationMode.slowZenOrbit:
        _cameraYaw =
            (_cameraYaw + GameConstants.slowZenOrbitSpeed * dt) % 360.0;
      case CameraRotationMode.pendulumSweep:
        _cameraYaw =
            (_pendulumCenterYaw + math.sin(_time * 0.45) * 42.0) % 360.0;
        if (_cameraYaw < 0) _cameraYaw += 360.0;
      case CameraRotationMode.guidedPoiTour:
        if (scenicPoints.isEmpty) break;
        final double poiAngle =
            scenicPoints[_poiTourIndex % scenicPoints.length].angle;
        double diff = (poiAngle - _cameraYaw) % 360.0;
        if (diff > 180.0) diff -= 360.0;
        if (diff < -180.0) diff += 360.0;

        if (diff.abs() < 1.2) {
          _poiPauseTimer += dt;
          if (_poiPauseTimer >= GameConstants.guidedPoiPauseSeconds) {
            _poiPauseTimer = 0.0;
            _poiTourIndex = (_poiTourIndex + 1) % scenicPoints.length;
          }
        } else {
          final double step = diff.sign *
              math.min(diff.abs(), GameConstants.guidedPoiSpeed * dt);
          _cameraYaw = (_cameraYaw + step) % 360.0;
          if (_cameraYaw < 0) _cameraYaw += 360.0;
        }
    }
  }

  void onPanUpdate(Offset delta, {bool isPreview = false}) {
    _targetYaw = null;
    if (isPreview || isMenuPreview) {
      _autoOrbitPreview = false;
      _rotationMode = CameraRotationMode.manual;
    } else if (_rotationMode != CameraRotationMode.manual) {
      _rotationMode = CameraRotationMode.manual;
    }
    _yawVelocity = 0.0;
    _cameraYaw =
        (_cameraYaw - delta.dx * GameConstants.horizontalDragSensitivity) %
            360.0;
    if (_cameraYaw < 0) _cameraYaw += 360.0;
    final double minP = (isPreview || isMenuPreview)
        ? GameConstants.minPreviewPitch
        : GameConstants.minPitch;
    final double maxP = (isPreview || isMenuPreview)
        ? GameConstants.maxPreviewPitch
        : GameConstants.maxPitch;
    _cameraPitch =
        (_cameraPitch + delta.dy * GameConstants.verticalDragSensitivity)
            .clamp(minP, maxP);

    roundedYawNotifier.value = _cameraYaw.round() % 360;
    notifyListeners();
  }

  void onPanEnd(double velocityPixelsPerSecondX) {
    if (velocityPixelsPerSecondX.abs() > 40.0) {
      _yawVelocity = (-velocityPixelsPerSecondX * 0.16).clamp(
        -GameConstants.maxFlingVelocity,
        GameConstants.maxFlingVelocity,
      );
    }
  }

  void onPointerScroll(double delta) {
    _targetYaw = null;
    if (!isMenuPreview) {
      _rotationMode = CameraRotationMode.manual;
    }
    _cameraYaw = (_cameraYaw + delta * 0.22) % 360.0;
    if (_cameraYaw < 0) _cameraYaw += 360.0;
    roundedYawNotifier.value = _cameraYaw.round() % 360;
    notifyListeners();
  }

  void animateLookTo(double targetAngle) {
    if (isMenuPreview) {
      _autoOrbitPreview = false;
      _rotationMode = CameraRotationMode.manual;
      _targetYaw = targetAngle % 360.0;
    } else {
      if (_rotationMode == CameraRotationMode.pendulumSweep) {
        _pendulumCenterYaw = targetAngle % 360.0;
      } else {
        _rotationMode = CameraRotationMode.manual;
      }
      _yawVelocity = 0.0;
      _targetYaw = targetAngle % 360.0;
    }
    notifyListeners();
  }

  void triggerPulse() {
    _coconutPulse = 1.0;
    notifyListeners();
  }

  void setStyleAndAtmosphere({
    required CoconutStyleMode style,
    required CoconutAtmosphereMode atmosphere,
  }) {
    if (_styleMode == style && _atmosphereMode == atmosphere) return;
    _styleMode = style;
    _atmosphereMode = atmosphere;
    notifyListeners();
  }

  void cycleStyleMode() {
    final int next = (_styleMode.index + 1) % CoconutStyleMode.values.length;
    _styleMode = CoconutStyleMode.values[next];
    notifyListeners();
  }

  void cycleAtmosphereMode() {
    final int next =
        (_atmosphereMode.index + 1) % CoconutAtmosphereMode.values.length;
    _atmosphereMode = CoconutAtmosphereMode.values[next];
    notifyListeners();
  }

  void cycleRotationMode() {
    _targetYaw = null;
    final int next =
        (_rotationMode.index + 1) % CameraRotationMode.values.length;
    _rotationMode = CameraRotationMode.values[next];
    _pendulumCenterYaw = _cameraYaw;
    _poiPauseTimer = 0.0;
    notifyListeners();
  }

  void cycleZoom() {
    if (_cameraZoom == 1.0) {
      _cameraZoom = 1.25;
    } else if (_cameraZoom == 1.25) {
      _cameraZoom = 0.85;
    } else {
      _cameraZoom = 1.0;
    }
    notifyListeners();
  }

  void setAutoOrbitPreview(bool enabled) {
    _autoOrbitPreview = enabled;
    _rotationMode =
        enabled ? CameraRotationMode.normalOrbit : CameraRotationMode.manual;
    _targetYaw = null;
    notifyListeners();
  }

  @override
  void dispose() {
    roundedYawNotifier.dispose();
    elapsedSecondsNotifier.dispose();
    super.dispose();
  }
}

