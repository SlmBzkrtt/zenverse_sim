import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Centralized constants, camera physics parameters, theme colors,
/// and responsive viewport scaling utilities for ZenVerse: Chill Object Sim.
abstract final class GameConstants {
  // ---------------------------------------------------------------------------
  // 1. APP & STORE METADATA
  // ---------------------------------------------------------------------------
  static const String appTitle = 'ZenVerse: Chill Object Sim';
  static const String bundleId = 'com.selimbozkurt.zenverse_sim';

  /// Supported device orientations locked to Portrait for mobile/store targets.
  static const List<DeviceOrientation> supportedOrientations = [
    DeviceOrientation.portraitUp,
  ];

  // ---------------------------------------------------------------------------
  // 2. LOGICAL DESIGN RESOLUTION & RESPONSIVE BREAKPOINTS
  // ---------------------------------------------------------------------------
  static const double designWidth = 1080.0;
  static const double designHeight = 1920.0;

  static const double compactMaxWidth = 600.0;
  static const double mediumMaxWidth = 1024.0;
  static const double maxHudContentWidth = 1080.0;
  static const double maxCarouselCardWidth = 720.0;

  // ---------------------------------------------------------------------------
  // 3. CAMERA & GAME LOOP PHYSICS CONSTANTS
  // ---------------------------------------------------------------------------
  static const double defaultFov = 110.0;
  static const double defaultPreviewYaw = 18.0;
  static const double defaultPreviewPitch = 2.0;
  static const int thoughtRotationIntervalSeconds = 10;

  static const double minPitch = -18.0;
  static const double maxPitch = 22.0;
  static const double minPreviewPitch = -14.0;
  static const double maxPreviewPitch = 18.0;

  static const double previewAutoOrbitSpeed = 6.5; // deg/sec
  static const double normalOrbitSpeed = 10.5; // deg/sec
  static const double slowZenOrbitSpeed = 4.2; // deg/sec
  static const double guidedPoiSpeed = 24.0; // deg/sec
  static const double guidedPoiPauseSeconds = 4.2;

  static const double horizontalDragSensitivity = 0.32;
  static const double verticalDragSensitivity = 0.12;
  static const double maxFlingVelocity = 180.0;
  static const double maxFrameDeltaSeconds = 0.05; // Clamp dt spike on resume

  // ---------------------------------------------------------------------------
  // 4. CORE THEME PALETTE
  // ---------------------------------------------------------------------------
  static const Color scaffoldBg = Color(0xFF0E1124);
  static const Color simulatorBg = Color(0xFF0F1026);
  static const Color accentOrange = Color(0xFFFF8C42);
  static const Color accentAmber = Color(0xFFFFB74D);
  static const Color accentGold = Color(0xFFFFE082);
  static const Color snackBarBg = Color(0xFF1F263E);
}

/// Provides adaptive layout measurements derived from `BoxConstraints`
/// so all UI docks, cards, hit-boxes, and typography scale smoothly across
/// small phones, foldables, tablets, and resizable desktop windows without
/// hardcoded pixel heights or overflows.
class ResponsiveViewport {
  final double width;
  final double height;

  const ResponsiveViewport({
    required this.width,
    required this.height,
  });

  factory ResponsiveViewport.fromConstraints(BoxConstraints constraints) {
    return ResponsiveViewport(
      width: constraints.maxWidth.isFinite ? constraints.maxWidth : 800.0,
      height: constraints.maxHeight.isFinite ? constraints.maxHeight : 800.0,
    );
  }

  bool get isCompactWidth => width < GameConstants.compactMaxWidth;
  bool get isShortHeight => height < 660.0;
  bool get isVeryShortHeight => height < 520.0;
  bool get isLandscape => width > height * 1.12;
  bool get isShortLandscape => isLandscape && height < 560.0;

  /// Maximum width of the foreground HUD dock so buttons and cards stay
  /// proportionally centered on ultra-wide tablets and desktop monitors.
  double get hudMaxWidth =>
      width > 1100.0 ? GameConstants.maxHudContentWidth : double.infinity;

  /// Scale factor relative to a reference phone/tablet viewport.
  double get uiScale {
    final double shortest = math.min(width, height);
    return (shortest / 420.0).clamp(0.80, 1.25);
  }

  /// Dynamic height for the Main Menu simulator card carousel so it never
  /// squeezes the 360° interactive stage on short or landscape windows.
  double get menuCarouselHeight {
    if (isVeryShortHeight) {
      return (height * 0.34).clamp(138.0, 168.0);
    }
    if (isShortHeight) {
      return (height * 0.31).clamp(168.0, 196.0);
    }
    return (height * 0.275).clamp(192.0, 224.0);
  }

  /// Adaptive viewportFraction for the PageView so cards don't stretch
  /// edge-to-edge on ultra-wide desktop monitors.
  double get carouselViewportFraction {
    if (width >= 1200) return 0.56;
    if (width >= 900) return 0.68;
    if (width >= 650) return 0.76;
    return 0.86;
  }

  /// Proportional center object hit-test radius on the 360° canvas.
  double get centerObjectHitRadiusX => (width * 0.14).clamp(72.0, 145.0);

  /// Dynamic hit-test for the grounded center object on any screen resolution.
  bool isCenterObjectHit(Offset localPosition) {
    final bool hitX =
        (localPosition.dx - width * 0.5).abs() <= centerObjectHitRadiusX;
    final bool hitY =
        localPosition.dy >= height * 0.58 && localPosition.dy <= height * 0.92;
    return hitX && hitY;
  }

  /// Horizontal padding that adapts to screen width.
  double get horizontalPadding => isCompactWidth ? 12.0 : 20.0;
}

