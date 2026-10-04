// ignore_for_file: prefer_initializing_formals
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../controllers/zenverse_controller.dart';

enum CoconutAtmosphereMode {
  sunset, // 🌅 Altın Gün Batımı
  night, // 🌌 Biyolüminesans Gece
  noon, // ☀️ Tropikal Öğle
  rain, // 🌧️ Lo-Fi Yaz Yağmuru
}

enum CoconutStyleMode {
  natural, // 🥥 Doğal
  arcade, // 🕶️ Arcade (Gözlük & Kokteyl Şemsiyesi)
  cocktail, // 🍹 Tropikal Kokteyl (Pipet & Çiçek)
  king, // 👑 Ada Kralı (Altın Taç)
  lofi, // 🎧 Lo-Fi Chill (Kulaklık & Notalar)
}

class CoconutWorldPainter extends CustomPainter {
  final ZenVerseController? controller;
  final double _cameraYaw; // 0 to 360 degrees
  final double _cameraPitch; // -20 to 25 degrees
  final double _time; // elapsed seconds
  final bool _isArcadeMode;
  final double _coconutPulse; // scale bounce when tapped
  final CoconutAtmosphereMode _atmosphereMode;
  final CoconutStyleMode _styleMode;
  final double _cameraZoom;

  // Class-level reusable Paint instances to avoid per-frame GC churn
  static final Paint sharedFillPaint = Paint()..style = PaintingStyle.fill;
  static final Paint sharedStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  double get cameraYaw => controller?.cameraYaw ?? _cameraYaw;
  double get cameraPitch => controller?.cameraPitch ?? _cameraPitch;
  double get time => controller?.time ?? _time;
  bool get isArcadeMode => controller?.isArcadeMode ?? _isArcadeMode;
  double get coconutPulse => controller?.coconutPulse ?? _coconutPulse;
  CoconutAtmosphereMode get atmosphereMode =>
      controller?.atmosphereMode ?? _atmosphereMode;
  CoconutStyleMode get styleMode => controller?.styleMode ?? _styleMode;
  double get cameraZoom => controller?.cameraZoom ?? _cameraZoom;

  CoconutWorldPainter({
    this.controller,
    Listenable? repaint,
    double cameraYaw = 0.0,
    double cameraPitch = 0.0,
    double time = 0.0,
    bool isArcadeMode = false,
    double coconutPulse = 0.0,
    CoconutAtmosphereMode atmosphereMode = CoconutAtmosphereMode.sunset,
    CoconutStyleMode? styleMode,
    double cameraZoom = 1.0,
  }) : _cameraYaw = cameraYaw,
       _cameraPitch = cameraPitch,
       _time = time,
       _isArcadeMode = isArcadeMode,
       _coconutPulse = coconutPulse,
       _atmosphereMode = atmosphereMode,
       _styleMode =
           styleMode ??
           (isArcadeMode ? CoconutStyleMode.arcade : CoconutStyleMode.natural),
       _cameraZoom = cameraZoom,
       super(repaint: repaint ?? controller);

  // Helper to convert a world angle (0..360) into screen X coordinate.
  // Returns null if it is too far outside the current field of view.
  double? _worldAngleToScreenX(
    double worldDeg,
    Size size, {
    double fov = 110.0,
    double margin = 350.0,
  }) {
    final double effectiveFov = fov / cameraZoom.clamp(0.75, 1.5);
    double diff = (worldDeg - cameraYaw) % 360.0;
    if (diff > 180.0) diff -= 360.0;
    if (diff < -180.0) diff += 360.0;
    final double x = size.width * 0.5 + (diff / effectiveFov) * size.width;
    if (x < -margin || x > size.width + margin) return null;
    return x;
  }

  // Smooth cosine weight (0.0 to 1.0) depending on angular proximity to targetAngle
  double _angleWeight(double currentDeg, double targetDeg, double spreadDeg) {
    double diff = (currentDeg - targetDeg).abs() % 360.0;
    if (diff > 180.0) diff = 360.0 - diff;
    if (diff >= spreadDeg) return 0.0;
    return 0.5 * (1.0 + math.cos((diff / spreadDeg) * math.pi));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double horizonY = size.height * (0.50 + (cameraPitch / 90.0) * 0.45);

    // 1. Dynamic 360° Sky Gradient adapted to Atmosphere Mode
    _drawSky(canvas, size, horizonY);

    // 2. Stars, Shooting Stars & Crescent/Full Moon
    _drawStarsAndMoon(canvas, size, horizonY);

    // 3. Sun, Crepuscular God Rays & Atmospheric Glow at 0°
    _drawSun(canvas, size, horizonY);

    // 4. Animated Volumetric Drifting Clouds around 360°
    _drawClouds(canvas, size, horizonY);

    // 5. Distant Volcanic Islands & Multi-layered Silhouette Mountains around the horizon
    _drawDistantHorizonFeatures(canvas, size, horizonY);

    // 6. Base Ground, Sand Dunes & Ocean Split (with Bioluminescence in Night mode)
    _drawOceanAndBeachBase(canvas, size, horizonY);

    // 7. Animated Fleet of 6 Sailboats, Catamaran Yacht, Fishing Boat & Jumping Dolphins!
    _drawSailboats(canvas, size, horizonY);

    // 8. Animated Flocks of Flying Seagulls & Floating Sky Lanterns
    _drawSeagulls(canvas, size, horizonY);
    _drawSkyLanterns(canvas, size, horizonY);

    // 9. Multi-Tiered Inland Jungle Mountains, Hills & Distant Palm Canopy (75°..285°)
    _drawInlandHillsAndFoliage(canvas, size, horizonY);

    // 10. Background Palm Grove (behind village buildings)
    _drawBackgroundPalmGrove(canvas, size, horizonY);

    // 11. Coastal Village Houses, Tiki Bar with People, Pier with People, Lighthouse & Campfires with People Chatting
    _drawStructuresAndVillageLife(canvas, size, horizonY);

    // 12. Foreground & Midground Swaying Palm Trees + Tropical Shrubs + Hammock with Person
    _drawPalmTrees(canvas, size, horizonY);

    // 13. Foreground Beach Props (Umbrellas, Sandcastle, Surfboards, Signpost, Shells, Starfish, Crabs, Fireflies)
    _drawBeachDetailsAndCrabs(canvas, size, horizonY);

    // 14. Centerpiece: The Player Coconut & Shadow on the Sand
    _drawCenterCoconut(canvas, size, horizonY);

    // 15. Weather & Atmospheric Overlay (Lo-Fi Rain, Sun Flare, Vignette)
    _drawAtmosphericOverlay(canvas, size, horizonY);
  }

  void _drawSky(Canvas canvas, Size size, double horizonY) {
    final double sunProximity = _angleWeight(cameraYaw, 0.0, 180.0);

    Color topColor;
    Color upperMidColor;
    Color midColor;
    Color horizonColor;

    switch (atmosphereMode) {
      case CoconutAtmosphereMode.sunset:
        topColor = Color.lerp(
          const Color(0xFF0B0C1E),
          const Color(0xFF2B193D),
          sunProximity,
        )!;
        upperMidColor = Color.lerp(
          const Color(0xFF1F193D),
          const Color(0xFF7B2848),
          sunProximity,
        )!;
        midColor = Color.lerp(
          const Color(0xFF382757),
          const Color(0xFFD14B30),
          sunProximity,
        )!;
        horizonColor = Color.lerp(
          const Color(0xFF7A4458),
          const Color(0xFFFFBD4A),
          sunProximity,
        )!;
      case CoconutAtmosphereMode.night:
        topColor = const Color(0xFF030511);
        upperMidColor = const Color(0xFF091026);
        midColor = Color.lerp(
          const Color(0xFF101F3E),
          const Color(0xFF162C52),
          sunProximity,
        )!;
        horizonColor = Color.lerp(
          const Color(0xFF1B3A5C),
          const Color(0xFF1D4D68),
          sunProximity,
        )!;
      case CoconutAtmosphereMode.noon:
        topColor = const Color(0xFF0277BD);
        upperMidColor = const Color(0xFF039BE5);
        midColor = const Color(0xFF29B6F6);
        horizonColor = const Color(0xFFB3E5FC);
      case CoconutAtmosphereMode.rain:
        topColor = const Color(0xFF161C28);
        upperMidColor = const Color(0xFF252F40);
        midColor = Color.lerp(
          const Color(0xFF354256),
          const Color(0xFF475063),
          sunProximity,
        )!;
        horizonColor = Color.lerp(
          const Color(0xFF566173),
          const Color(0xFF7E757A),
          sunProximity,
        )!;
    }

    final Rect skyRect = Rect.fromLTWH(0, 0, size.width, horizonY + 4);
    final Paint skyPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(size.width * 0.5, 0),
        Offset(size.width * 0.5, horizonY),
        [topColor, upperMidColor, midColor, horizonColor],
        [0.0, 0.35, 0.68, 1.0],
      );
    canvas.drawRect(skyRect, skyPaint);

    // Atmospheric horizon mist & glow band right above the sea/land line
    final Color mistColor = switch (atmosphereMode) {
      CoconutAtmosphereMode.sunset => const Color(0xFFFFD180).withValues(alpha: 0.24),
      CoconutAtmosphereMode.night => const Color(0xFF26C6DA).withValues(alpha: 0.14),
      CoconutAtmosphereMode.noon => const Color(0xFFE1F5FE).withValues(alpha: 0.35),
      CoconutAtmosphereMode.rain => const Color(0xFF90A4AE).withValues(alpha: 0.25),
    };
    canvas.drawRect(
      Rect.fromLTWH(0, horizonY - 38, size.width, 40),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, horizonY - 38),
          Offset(0, horizonY + 2),
          [Colors.transparent, mistColor],
        ),
    );
  }

  void _drawStarsAndMoon(Canvas canvas, Size size, double horizonY) {
    if (atmosphereMode == CoconutAtmosphereMode.noon) return;

    final double nightBoost =
        atmosphereMode == CoconutAtmosphereMode.night
            ? 1.0
            : (atmosphereMode == CoconutAtmosphereMode.rain ? 0.22 : 0.72);

    // 1. Subtle Milky Way / Starlight Nebula Band over the inland sky (130°..240°)
    for (int m = 0; m < 7; m++) {
      final double mwAngle = 140.0 + m * 14.0;
      final double? mwx = _worldAngleToScreenX(mwAngle, size, margin: 180);
      if (mwx == null) continue;
      final double mwy = horizonY * (0.15 + (m % 3) * 0.08);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(mwx, mwy), width: 150, height: 48),
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(mwx, mwy),
            75,
            [
              const Color(0xFFB388FF).withValues(alpha: 0.09 * nightBoost),
              Colors.transparent,
            ],
          ),
      );
    }

    // 2. 145 Multi-sized Twinkling Stars + 4-Point Diamond Sparkle Stars
    final Paint starPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 145; i++) {
      final double starAngle = (i * 37.5 + 15.0) % 360.0;
      final double sunDistWeight =
          atmosphereMode == CoconutAtmosphereMode.night
              ? 1.0
              : (1.0 - _angleWeight(starAngle, 0.0, 72.0));
      if (sunDistWeight <= 0.05) continue;

      final double? sx = _worldAngleToScreenX(starAngle, size, margin: 20);
      if (sx == null) continue;

      final double heightFactor = ((i * 29) % 100) / 100.0;
      final double sy = horizonY * (0.03 + heightFactor * 0.68);
      if (sy <= 0 || sy >= horizonY) continue;

      final double twinkle =
          0.35 + 0.65 * math.sin(time * (1.8 + (i % 5) * 0.5) + i);
      final double alpha =
          (sunDistWeight * twinkle * (1.0 - heightFactor * 0.50) * nightBoost)
              .clamp(0.0, 1.0);

      final Color sColor = i % 9 == 0
          ? const Color(0xFFFFE0B2)
          : (i % 13 == 0 ? const Color(0xFFB3E5FC) : Colors.white);
      starPaint.color = sColor.withValues(alpha: alpha * 0.94);

      final double radius = (i % 11 == 0) ? 2.2 : ((i % 4 == 0) ? 1.4 : 0.95);
      canvas.drawCircle(Offset(sx, sy), radius, starPaint);

      // Draw crisp 4-point cross rays on bright major stars
      if (i % 14 == 0 && alpha > 0.45) {
        final Paint rayP = Paint()
          ..color = sColor.withValues(alpha: alpha * 0.65)
          ..strokeWidth = 0.9;
        canvas.drawLine(Offset(sx - 5.5, sy), Offset(sx + 5.5, sy), rayP);
        canvas.drawLine(Offset(sx, sy - 5.5), Offset(sx, sy + 5.5), rayP);
      }
    }

    // 3. Periodic Shooting Stars across the twilight / night sky!
    if (atmosphereMode == CoconutAtmosphereMode.sunset ||
        atmosphereMode == CoconutAtmosphereMode.night) {
      final double cycle = (time * 0.30) % 1.0;
      if (cycle < 0.28) {
        final double progress = cycle / 0.28;
        final double shootAngle = (145.0 + (time ~/ 3.3) * 67.0) % 360.0;
        final double? stX = _worldAngleToScreenX(shootAngle, size, margin: 120);
        if (stX != null) {
          final double startX = stX + progress * 105.0;
          final double startY = horizonY * 0.14 + progress * 44.0;
          final double alpha = math.sin(progress * math.pi);
          canvas.drawLine(
            Offset(startX, startY),
            Offset(startX - 44.0, startY - 18.0),
            Paint()
              ..shader = ui.Gradient.linear(
                Offset(startX, startY),
                Offset(startX - 44.0, startY - 18.0),
                [
                  Colors.white.withValues(alpha: alpha * 0.95),
                  Colors.transparent,
                ],
              )
              ..strokeWidth = 2.2
              ..strokeCap = StrokeCap.round,
          );
        }
      }
    }

    // 4. Glowing Crescent Moon with subtle surface craters above the coastal village at ~188°
    final double? moonX = _worldAngleToScreenX(188.0, size, margin: 100);
    if (moonX != null) {
      final double moonY = horizonY * 0.23;
      final double glowRadius =
          atmosphereMode == CoconutAtmosphereMode.night ? 58.0 : 38.0;
      canvas.drawCircle(
        Offset(moonX, moonY),
        glowRadius,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(moonX, moonY),
            glowRadius,
            [
              const Color(0xFFFFF8E1).withValues(
                alpha:
                    atmosphereMode == CoconutAtmosphereMode.night ? 0.42 : 0.25,
              ),
              Colors.transparent,
            ],
          ),
      );
      // Faint earthshine on the dark side of the moon
      canvas.drawCircle(
        Offset(moonX, moonY),
        14.5,
        Paint()..color = const Color(0xFFFFF8E1).withValues(alpha: 0.07),
      );
      final Path moonPath = Path.combine(
        PathOperation.difference,
        Path()
          ..addOval(Rect.fromCircle(center: Offset(moonX, moonY), radius: 15)),
        Path()
          ..addOval(
            Rect.fromCircle(center: Offset(moonX - 5.5, moonY - 3), radius: 12.5),
          ),
      );
      canvas.drawPath(
        moonPath,
        Paint()..color = const Color(0xFFFFF9C4).withValues(alpha: 0.95),
      );
    }
  }

  void _drawSun(Canvas canvas, Size size, double horizonY) {
    final double? sunX = _worldAngleToScreenX(0.0, size, margin: 450);
    if (sunX == null) return;

    // In Night mode, draw a luminous Full Moon / Lunar Horizon Glow at 0° with crater details
    if (atmosphereMode == CoconutAtmosphereMode.night) {
      final double moonY = horizonY - size.height * 0.15;
      final double moonR = math.min(size.width, size.height) * 0.068;
      canvas.drawCircle(
        Offset(sunX, moonY),
        moonR * 4.2,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(sunX, moonY),
            moonR * 4.2,
            [
              const Color(0xFF80DEEA).withValues(alpha: 0.28),
              const Color(0xFF26C6DA).withValues(alpha: 0.10),
              Colors.transparent,
            ],
            [0.0, 0.5, 1.0],
          ),
      );
      canvas.drawCircle(
        Offset(sunX, moonY),
        moonR,
        Paint()..color = const Color(0xFFE0F7FA).withValues(alpha: 0.95),
      );
      // Subtle lunar maria craters
      final Paint craterPaint = Paint()
        ..color = const Color(0xFFB2EBF2).withValues(alpha: 0.55);
      canvas.drawCircle(Offset(sunX - moonR * 0.3, moonY - moonR * 0.2), moonR * 0.22, craterPaint);
      canvas.drawCircle(Offset(sunX + moonR * 0.25, moonY + moonR * 0.15), moonR * 0.28, craterPaint);
      canvas.drawCircle(Offset(sunX - moonR * 0.1, moonY + moonR * 0.35), moonR * 0.16, craterPaint);
      return;
    }

    final double sunBob = math.sin(time * 0.6) * 3.0;
    final double sunY =
        atmosphereMode == CoconutAtmosphereMode.noon
            ? horizonY - size.height * 0.24 + sunBob
            : horizonY - size.height * 0.065 + sunBob;
    final double sunRadius = math.min(size.width, size.height) * 0.098;

    // 14 Crepuscular God Rays fanning upwards from the sun
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, horizonY));
    for (int r = 0; r < 14; r++) {
      final double rayAngle =
          -math.pi * 0.92 +
          (r / 13.0) * math.pi * 0.84 +
          math.sin(time * 0.35 + r) * 0.025;
      final double rayLen = sunRadius * (4.8 + (r % 3) * 1.1);
      final Offset p1 = Offset(
        sunX + math.cos(rayAngle - 0.038) * rayLen,
        sunY + math.sin(rayAngle - 0.038) * rayLen,
      );
      final Offset p2 = Offset(
        sunX + math.cos(rayAngle + 0.038) * rayLen,
        sunY + math.sin(rayAngle + 0.038) * rayLen,
      );
      final Path rayPath = Path()
        ..moveTo(sunX, sunY)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..close();

      canvas.drawPath(
        rayPath,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(sunX, sunY),
            rayLen,
            [
              const Color(0xFFFFD54F).withValues(alpha: 0.18),
              Colors.transparent,
            ],
          ),
      );
    }
    canvas.restore();

    // Multi-ring outer atmospheric solar halo
    final Paint outerGlow = Paint()
      ..shader = ui.Gradient.radial(
        Offset(sunX, sunY),
        sunRadius * 4.5,
        [
          const Color(0xFFFFB74D).withValues(alpha: 0.55),
          const Color(0xFFFF5E3A).withValues(alpha: 0.22),
          Colors.transparent,
        ],
        [0.0, 0.45, 1.0],
      );
    canvas.drawCircle(Offset(sunX, sunY), sunRadius * 4.5, outerGlow);

    // Sun core disc clipped above horizon
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, horizonY));

    final Paint sunCore = Paint()
      ..shader = ui.Gradient.linear(
        Offset(sunX, sunY - sunRadius),
        Offset(sunX, sunY + sunRadius),
        [
          const Color(0xFFFFFDE7),
          const Color(0xFFFFB300),
          const Color(0xFFFF3D00),
        ],
        [0.0, 0.58, 1.0],
      );
    canvas.drawCircle(Offset(sunX, sunY), sunRadius, sunCore);

    // Stylized atmospheric thin heat bands near the bottom of the sun
    final Paint bandPaint = Paint()
      ..color = const Color(0xFFD95638).withValues(alpha: 0.36);
    for (int i = 0; i < 5; i++) {
      final double by = sunY + sunRadius * (0.18 + i * 0.16);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(sunX, by),
          width: sunRadius * 2.1,
          height: 1.8 + i * 1.1,
        ),
        bandPaint,
      );
    }
    canvas.restore();
  }

  void _drawClouds(Canvas canvas, Size size, double horizonY) {
    // Layer 1: 18 High-altitude wispy Cirrus streaks across the upper sky
    for (int c = 0; c < 18; c++) {
      final double cAngle = (c * 20.0 + time * 0.12) % 360.0;
      final double? wx = _worldAngleToScreenX(cAngle, size, margin: 260);
      if (wx == null) continue;
      final double wy = horizonY * (0.11 + (c % 4) * 0.07);
      final double sunWarmth = _angleWeight(cAngle, 0.0, 140.0);
      final Color wispColor = Color.lerp(
        const Color(0xFF7E57C2).withValues(alpha: 0.24),
        const Color(0xFFFFCC80).withValues(alpha: 0.46),
        sunWarmth,
      )!;
      final Path wisp = Path()
        ..moveTo(wx - 95, wy)
        ..quadraticBezierTo(wx - 20, wy - 9, wx + 55, wy + 3)
        ..quadraticBezierTo(wx + 105, wy + 8, wx + 135, wy - 3);
      canvas.drawPath(
        wisp,
        Paint()
          ..color = wispColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.8
          ..strokeCap = StrokeCap.round,
      );
    }

    // Layer 2: 34 Large Volumetric Cumulus Clouds with Unified Silhouette & 3D Sunlit Rim (no internal wireframe lines!)
    for (int i = 0; i < 34; i++) {
      final double speed = 0.22 + (i % 5) * 0.12;
      final double baseAngle = (i * 10.58 + time * speed) % 360.0;
      final double? cx = _worldAngleToScreenX(baseAngle, size, margin: 360);
      if (cx == null) continue;

      final double altitude = 0.07 + ((i * 37) % 100) / 100.0 * 0.35;
      final double cy = horizonY - size.height * altitude;
      final double scale = 0.80 + ((i * 19) % 11) * 0.11;

      final double sunWarmth = _angleWeight(baseAngle, 0.0, 130.0);
      Color cloudTop;
      Color cloudBottom;
      Color rimHighlight;

      switch (atmosphereMode) {
        case CoconutAtmosphereMode.sunset:
          cloudTop = Color.lerp(
            const Color(0xFF5A457E).withValues(alpha: 0.84),
            const Color(0xFFFFE599).withValues(alpha: 0.94),
            sunWarmth,
          )!;
          cloudBottom = Color.lerp(
            const Color(0xFF281D40).withValues(alpha: 0.88),
            const Color(0xFFE65100).withValues(alpha: 0.88),
            sunWarmth,
          )!;
          rimHighlight = Color.lerp(
            const Color(0xFFFFAB91).withValues(alpha: 0.48),
            const Color(0xFFFFF59D).withValues(alpha: 0.90),
            sunWarmth,
          )!;
        case CoconutAtmosphereMode.night:
          cloudTop = const Color(0xFF1E2F4F).withValues(alpha: 0.80);
          cloudBottom = const Color(0xFF0D172A).withValues(alpha: 0.88);
          rimHighlight = const Color(0xFF80DEEA).withValues(alpha: 0.42);
        case CoconutAtmosphereMode.noon:
          cloudTop = Colors.white.withValues(alpha: 0.95);
          cloudBottom = const Color(0xFFB3E5FC).withValues(alpha: 0.88);
          rimHighlight = Colors.white;
        case CoconutAtmosphereMode.rain:
          cloudTop = const Color(0xFF546E7A).withValues(alpha: 0.90);
          cloudBottom = const Color(0xFF263238).withValues(alpha: 0.94);
          rimHighlight = const Color(0xFF90A4AE).withValues(alpha: 0.45);
      }

      final double w = 162.0 * scale;
      final double h = 32.0 * scale;

      // Unite all cloud puffs with PathOperation.union so stroking only outlines the outer cloud silhouette!
      Path unifiedCloud = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy), width: w, height: h),
            Radius.circular(h * 0.5),
          ),
        );
      final List<Rect> puffRects = [
        Rect.fromCenter(
          center: Offset(cx - w * 0.28, cy - h * 0.34),
          width: w * 0.44,
          height: h * 1.18,
        ),
        Rect.fromCenter(
          center: Offset(cx - w * 0.04, cy - h * 0.60),
          width: w * 0.50,
          height: h * 1.48,
        ),
        Rect.fromCenter(
          center: Offset(cx + w * 0.22, cy - h * 0.40),
          width: w * 0.42,
          height: h * 1.20,
        ),
        Rect.fromCenter(
          center: Offset(cx + w * 0.36, cy - h * 0.15),
          width: w * 0.30,
          height: h * 0.88,
        ),
      ];
      for (final r in puffRects) {
        unifiedCloud = Path.combine(
          PathOperation.union,
          unifiedCloud,
          Path()..addOval(r),
        );
      }

      // 1. Draw main unified cloud body with vertical gradient
      canvas.drawPath(
        unifiedCloud,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(cx, cy - 36 * scale),
            Offset(cx, cy + 18 * scale),
            [cloudTop, cloudBottom],
          ),
      );

      // 2. Soft internal 3D puff highlights (filled, no wireframe lines!)
      for (int p = 0; p < 3; p++) {
        final Rect pr = puffRects[p];
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(pr.center.dx, pr.center.dy - pr.height * 0.12),
            width: pr.width * 0.72,
            height: pr.height * 0.55,
          ),
          Paint()..color = cloudTop.withValues(alpha: 0.42),
        );
      }

      // 3. Internal sculpted underbelly shadow for 3D depth
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy + h * 0.20),
          width: w * 0.86,
          height: h * 0.46,
        ),
        Paint()..color = cloudBottom.withValues(alpha: 0.58),
      );

      // 4. Clean outer silhouette sunlit rim highlight
      canvas.drawPath(
        unifiedCloud,
        Paint()
          ..color = rimHighlight
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6 * scale,
      );
    }
  }

  void _drawDistantHorizonFeatures(Canvas canvas, Size size, double horizonY) {
    // Rich 9-Island Archipelago around the ocean horizon (scaled up 1.55x for majestic presence!)
    _drawIslandSilhouette(
      canvas,
      size,
      horizonY,
      284.0,
      175.0,
      36.0,
      const Color(0xFF43284E),
      hasVolcanoSmoke: false,
      hasVillageLights: false,
    );
    _drawIslandSilhouette(
      canvas,
      size,
      horizonY,
      298.0,
      245.0,
      58.0,
      const Color(0xFF472A52),
      hasVolcanoSmoke: false,
      hasVillageLights: true,
    );
    _drawIslandSilhouette(
      canvas,
      size,
      horizonY,
      318.0,
      350.0,
      105.0,
      const Color(0xFF351D44),
      hasVolcanoSmoke: true,
      hasVillageLights: true,
    );
    _drawIslandSilhouette(
      canvas,
      size,
      horizonY,
      334.0,
      195.0,
      42.0,
      const Color(0xFF4B2954),
      hasVolcanoSmoke: false,
      hasVillageLights: false,
    );
    _drawIslandSilhouette(
      canvas,
      size,
      horizonY,
      346.0,
      135.0,
      26.0,
      const Color(0xFF562E5C),
      hasVolcanoSmoke: false,
      hasVillageLights: false,
    );
    _drawIslandSilhouette(
      canvas,
      size,
      horizonY,
      19.0,
      148.0,
      29.0,
      const Color(0xFF542D59),
      hasVolcanoSmoke: false,
      hasVillageLights: false,
    );
    _drawIslandSilhouette(
      canvas,
      size,
      horizonY,
      36.0,
      225.0,
      48.0,
      const Color(0xFF4B2952),
      hasVolcanoSmoke: false,
      hasVillageLights: true,
    );
    _drawIslandSilhouette(
      canvas,
      size,
      horizonY,
      53.0,
      310.0,
      76.0,
      const Color(0xFF3B2248),
      hasVolcanoSmoke: false,
      hasVillageLights: true,
    );
    _drawIslandSilhouette(
      canvas,
      size,
      horizonY,
      68.0,
      200.0,
      42.0,
      const Color(0xFF42274E),
      hasVolcanoSmoke: false,
      hasVillageLights: false,
    );
  }

  void _drawIslandSilhouette(
    Canvas canvas,
    Size size,
    double horizonY,
    double worldAngle,
    double width,
    double height,
    Color color, {
    bool hasVolcanoSmoke = false,
    bool hasVillageLights = false,
  }) {
    final double? ix = _worldAngleToScreenX(worldAngle, size, margin: width);
    if (ix == null) return;

    // 1. Billowing volcanic smoke plumes + glowing lava crater if volcano
    if (hasVolcanoSmoke) {
      for (int s = 0; s < 9; s++) {
        final double progress = ((time * 0.20 + s * 0.11) % 1.0);
        final double sx =
            ix - width * 0.03 + math.sin(time * 0.9 + s) * (10.0 + progress * 26.0);
        final double sy = horizonY - height - progress * 76.0;
        final double r = 9.0 + progress * 28.0;
        canvas.drawCircle(
          Offset(sx, sy),
          r,
          Paint()
            ..color = const Color(0xFFFFCCBC).withValues(
              alpha: (1.0 - progress) * 0.28,
            ),
        );
      }
      // Glowing volcanic crater rim
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(ix - width * 0.03, horizonY - height + 2),
          width: width * 0.15,
          height: 9,
        ),
        Paint()
          ..color = const Color(0xFFFF5722).withValues(alpha: 0.85)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
    }

    // 2. Main Island Mountain Body
    final double peakX = ix - width * 0.06;
    final double peakY = horizonY - height;
    final double secondPeakX = ix + width * 0.22;
    final double secondPeakY = horizonY - height * 0.64;

    final Path path = Path()
      ..moveTo(ix - width * 0.5, horizonY + 1)
      ..quadraticBezierTo(
        ix - width * 0.28,
        horizonY - height * 0.44,
        peakX,
        peakY,
      )
      ..lineTo(ix + width * 0.02, horizonY - height * 0.92)
      ..quadraticBezierTo(
        ix + width * 0.12,
        horizonY - height * 0.54,
        secondPeakX,
        secondPeakY,
      )
      ..quadraticBezierTo(
        ix + width * 0.36,
        horizonY - height * 0.26,
        ix + width * 0.5,
        horizonY + 1,
      )
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(ix, peakY),
          Offset(ix, horizonY),
          [color, Color.lerp(color, const Color(0xFFFFAB73), 0.28)!],
        ),
    );

    // 3. 3D Sunlit Ridge Facet on the side facing the sun (0°)
    final bool sunOnRight = worldAngle > 180.0;
    final Path sunlitFacet = Path()
      ..moveTo(peakX, peakY)
      ..lineTo(ix + (sunOnRight ? width * 0.08 : -width * 0.08), horizonY)
      ..lineTo(ix + (sunOnRight ? width * 0.48 : -width * 0.48), horizonY)
      ..close();
    canvas.save();
    canvas.clipPath(path);
    canvas.drawPath(
      sunlitFacet,
      Paint()
        ..color = const Color(0xFFFFB74D).withValues(
          alpha: atmosphereMode == CoconutAtmosphereMode.night ? 0.06 : 0.16,
        ),
    );
    canvas.restore();

    // 4. Tiny Distant Palm Silhouettes along the lower ridges of the island
    final Paint tinyPalmPaint = Paint()
      ..color = color.withValues(alpha: 0.94)
      ..strokeWidth = 1.4;
    for (int p = -4; p <= 4; p++) {
      final double px = ix + p * (width * 0.09);
      final double py = horizonY - height * (0.16 + (4 - p.abs()) * 0.07);
      canvas.drawLine(Offset(px, py + 7), Offset(px, py), tinyPalmPaint);
      canvas.drawCircle(Offset(px, py), 3.0, Paint()..color = color);
    }

    // 5. Twinkling Distant Island Village Lights near the shoreline
    if (hasVillageLights && atmosphereMode != CoconutAtmosphereMode.noon) {
      for (int l = 0; l < 8; l++) {
        final double lx = ix - width * 0.26 + l * (width * 0.07);
        final double ly = horizonY - 3.5 - (l % 2) * 2.5;
        canvas.drawCircle(
          Offset(lx, ly),
          1.8,
          Paint()..color = const Color(0xFFFFE082).withValues(alpha: 0.88),
        );
      }
    }

    // 6. Crisp White Breaking Surf Line & Subtle Water Reflection at the island base
    canvas.drawLine(
      Offset(ix - width * 0.48, horizonY + 1),
      Offset(ix + width * 0.48, horizonY + 1),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.42)
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(ix, horizonY + 5),
        width: width * 0.85,
        height: 7,
      ),
      Paint()..color = color.withValues(alpha: 0.30),
    );
  }

  void _drawOceanAndBeachBase(Canvas canvas, Size size, double horizonY) {
    final double groundHeight = size.height - horizonY;
    if (groundHeight <= 0) return;

    // Step 1: Fill the entire lower half with the Ocean first (adapted to Atmosphere Mode)
    final Rect oceanRect = Rect.fromLTWH(0, horizonY, size.width, groundHeight);
    final double sunProximity = _angleWeight(cameraYaw, 0.0, 150.0);

    Color deepWater;
    Color midWater;
    Color shallowWater;
    switch (atmosphereMode) {
      case CoconutAtmosphereMode.sunset:
        deepWater = Color.lerp(
          const Color(0xFF0A2239),
          const Color(0xFF133B5C),
          sunProximity,
        )!;
        midWater = Color.lerp(
          const Color(0xFF13405E),
          const Color(0xFF1E5F74),
          sunProximity,
        )!;
        shallowWater = Color.lerp(
          const Color(0xFF1D6A82),
          const Color(0xFF289672),
          sunProximity,
        )!;
      case CoconutAtmosphereMode.night:
        deepWater = const Color(0xFF040B1A);
        midWater = const Color(0xFF091D36);
        shallowWater = const Color(0xFF0E3958);
      case CoconutAtmosphereMode.noon:
        deepWater = const Color(0xFF0277BD);
        midWater = const Color(0xFF00ACC1);
        shallowWater = const Color(0xFF26C6DA);
      case CoconutAtmosphereMode.rain:
        deepWater = const Color(0xFF1A2636);
        midWater = const Color(0xFF263849);
        shallowWater = const Color(0xFF354F60);
    }

    final Paint oceanPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(size.width * 0.5, horizonY),
        Offset(size.width * 0.5, size.height),
        [deepWater, midWater, shallowWater],
        [0.0, 0.45, 1.0],
      );
    canvas.drawRect(oceanRect, oceanPaint);

    // Step 2: Shimmering Sun / Moon Reflection on the Ocean (centered at 0°)
    _drawSunWaterShimmer(canvas, size, horizonY);

    // Step 3: Animated Ocean Waves across the sea
    _drawOceanWaves(canvas, size, horizonY);

    // Step 4: Draw the 360° Curved Shoreline, Wet Sand, Animated Foam, and Dry Sand
    final int segments = 54;
    final double dx = size.width / segments;

    final Path foamPath = Path();
    final Path wetSandPath = Path();
    final Path drySandPath = Path();

    final double tideSurge =
        math.sin(time * 1.35) * 10.0 + math.sin(time * 2.7) * 4.0;

    for (int i = 0; i <= segments; i++) {
      final double x = i * dx;
      final double worldAngle =
          (cameraYaw + ((x / size.width) - 0.5) * (110.0 / cameraZoom)) % 360.0;
      final double positiveAngle =
          worldAngle < 0 ? worldAngle + 360.0 : worldAngle;

      // Cosine factor: 1.0 at 0° (Ocean front), 0.0 at >= 115° (Inland beach)
      final double oceanFactor = _angleWeight(positiveAngle, 0.0, 118.0);

      // Ripple along the shoreline
      final double localRipple =
          math.sin(positiveAngle * 0.14 + time * 2.2) * 4.5;
      final double waveAdvance = oceanFactor * (tideSurge + localRipple);

      // Where water meets sand
      final double shoreY =
          horizonY + groundHeight * (0.44 * oceanFactor) + waveAdvance;
      final double wetSandY =
          shoreY + groundHeight * (0.09 * oceanFactor) + 4.0;

      if (i == 0) {
        foamPath.moveTo(x, shoreY - 3.5 * oceanFactor);
        wetSandPath.moveTo(x, shoreY);
        drySandPath.moveTo(x, wetSandY);
      } else {
        foamPath.lineTo(x, shoreY - 3.5 * oceanFactor);
        wetSandPath.lineTo(x, shoreY);
        drySandPath.lineTo(x, wetSandY);
      }
    }

    foamPath
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    wetSandPath
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    drySandPath
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    // Sea foam crest (Bioluminescent glowing cyan in Night mode!)
    final Color foamColor =
        atmosphereMode == CoconutAtmosphereMode.night
            ? const Color(0xFF00E5FF)
            : const Color(0xFFFFF8E7);
    final Paint foamPaint = Paint()
      ..color = foamColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawPath(foamPath, foamPaint);

    // Wet sand
    final List<Color> wetSandColors = switch (atmosphereMode) {
      CoconutAtmosphereMode.sunset => [
        const Color(0xFF9E6B52),
        const Color(0xFFB57C56),
      ],
      CoconutAtmosphereMode.night => [
        const Color(0xFF28344A),
        const Color(0xFF34425A),
      ],
      CoconutAtmosphereMode.noon => [
        const Color(0xFFC8A675),
        const Color(0xFFD8B888),
      ],
      CoconutAtmosphereMode.rain => [
        const Color(0xFF5D534A),
        const Color(0xFF6E6258),
      ],
    };
    final Paint wetSandPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(size.width * 0.5, horizonY),
        Offset(size.width * 0.5, size.height),
        wetSandColors,
      );
    canvas.drawPath(wetSandPath, wetSandPaint);

    // Beach Sand
    final List<Color> drySandColors = switch (atmosphereMode) {
      CoconutAtmosphereMode.sunset => [
        const Color(0xFFE59F65),
        const Color(0xFFD48850),
        const Color(0xFFBD6E3B),
      ],
      CoconutAtmosphereMode.night => [
        const Color(0xFF3E4A63),
        const Color(0xFF313B52),
        const Color(0xFF242C3F),
      ],
      CoconutAtmosphereMode.noon => [
        const Color(0xFFF7E1B5),
        const Color(0xFFEBD09E),
        const Color(0xFFDDC08B),
      ],
      CoconutAtmosphereMode.rain => [
        const Color(0xFF8C7A6B),
        const Color(0xFF7A6859),
        const Color(0xFF665648),
      ],
    };
    final Paint drySandPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(size.width * 0.5, horizonY),
        Offset(size.width * 0.5, size.height),
        drySandColors,
        [0.0, 0.5, 1.0],
      );
    canvas.drawPath(drySandPath, drySandPaint);

    // Secondary receding foam lace line on the wet sand
    final Path lacePath = Path();
    bool laceStarted = false;
    for (int i = 0; i <= segments; i++) {
      final double x = i * dx;
      final double worldAngle =
          (cameraYaw + ((x / size.width) - 0.5) * (110.0 / cameraZoom)) % 360.0;
      final double positiveAngle =
          worldAngle < 0 ? worldAngle + 360.0 : worldAngle;
      final double oceanFactor = _angleWeight(positiveAngle, 0.0, 108.0);
      if (oceanFactor <= 0.05) continue;

      final double localRipple =
          math.cos(positiveAngle * 0.22 - time * 1.8) * 3.5;
      final double shoreY =
          horizonY +
          groundHeight * (0.44 * oceanFactor) +
          oceanFactor * (tideSurge * 0.5 + localRipple) +
          6.0;
      if (!laceStarted) {
        lacePath.moveTo(x, shoreY);
        laceStarted = true;
      } else {
        lacePath.lineTo(x, shoreY);
      }
    }
    if (laceStarted) {
      final double laceAlpha =
          (0.38 + 0.25 * math.sin(time * 1.35)).clamp(0.1, 0.75);
      canvas.drawPath(
        lacePath,
        Paint()
          ..color = (atmosphereMode == CoconutAtmosphereMode.night
                  ? const Color(0xFF18FFFF)
                  : const Color(0xFFFFFBF0))
              .withValues(alpha: laceAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round,
      );
    }

    // Layered Sand Dunes & Sand Ripples
    _drawSandDunesAndTexture(canvas, size, horizonY);
  }

  void _drawSunWaterShimmer(Canvas canvas, Size size, double horizonY) {
    final double? sunX = _worldAngleToScreenX(0.0, size, margin: 360);
    if (sunX == null) return;

    final double groundHeight = size.height - horizonY;
    final Paint shimmerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Color topShimmer = switch (atmosphereMode) {
      CoconutAtmosphereMode.sunset => const Color(0xFFFFF59D),
      CoconutAtmosphereMode.night => const Color(0xFF80DEEA),
      CoconutAtmosphereMode.noon => const Color(0xFFFFFFFF),
      CoconutAtmosphereMode.rain => const Color(0xFFCFD8DC),
    };
    final Color bottomShimmer = switch (atmosphereMode) {
      CoconutAtmosphereMode.sunset => const Color(0xFFFF7043),
      CoconutAtmosphereMode.night => const Color(0xFF00E5FF),
      CoconutAtmosphereMode.noon => const Color(0xFF4DD0E1),
      CoconutAtmosphereMode.rain => const Color(0xFF90A4AE),
    };

    for (int i = 0; i < 42; i++) {
      final double progress = i / 42.0;
      final double y =
          horizonY + 2.5 + progress * progress * (groundHeight * 0.44);
      final double waveOffset =
          math.sin(time * 3.2 + i * 1.4) * (5.0 + progress * 26.0);
      final double width =
          (18.0 + progress * 125.0) * (0.75 + 0.25 * math.sin(time * 2.1 + i));

      shimmerPaint
        ..color = Color.lerp(
          topShimmer.withValues(alpha: 0.85),
          bottomShimmer.withValues(alpha: 0.42),
          progress,
        )!
        ..strokeWidth = 1.4 + progress * 3.0;

      canvas.drawLine(
        Offset(sunX + waveOffset - width * 0.5, y),
        Offset(sunX + waveOffset + width * 0.5, y),
        shimmerPaint,
      );
    }
  }

  void _drawOceanWaves(Canvas canvas, Size size, double horizonY) {
    final double groundHeight = size.height - horizonY;

    // 1. Shallow Turquoise Coral Reef Patches visible beneath the clear nearshore water
    for (final double reefAngle in [28.0, 52.0, 72.0, 288.0, 310.0, 338.0]) {
      final double? rx = _worldAngleToScreenX(reefAngle, size, margin: 140);
      if (rx == null) continue;
      final double ry = horizonY + groundHeight * 0.26;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(rx, ry), width: 95, height: 18),
        Paint()
          ..color = (atmosphereMode == CoconutAtmosphereMode.night
                  ? const Color(0xFF00B8D4)
                  : const Color(0xFF26A69A))
              .withValues(alpha: 0.22),
      );
    }

    // 2. 52 Multi-Crested Rolling Ocean Waves with Dark Trough Shadows & Whitecap Foam
    final Paint wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final Paint troughPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Color waveBaseColor =
        atmosphereMode == CoconutAtmosphereMode.night
            ? const Color(0xFF00E5FF)
            : const Color(0xFFFFF8E1);

    for (int i = 0; i < 52; i++) {
      final double baseAngle = -105.0 + (i * 4.1);
      final double? wx = _worldAngleToScreenX(baseAngle, size, margin: 140);
      if (wx == null) continue;

      final double cycle = ((time * 0.19 + i * 0.11) % 1.0);
      final double wy =
          horizonY + 5.0 + cycle * cycle * (groundHeight * 0.39);
      final double waveWidth = 24.0 + cycle * 115.0;
      final double alpha = math.sin(cycle * math.pi) * 0.62;

      // Dark water trough shadow right under the wave crest for 3D wave volume
      troughPaint
        ..color = const Color(0xFF071A2C).withValues(alpha: alpha * 0.55)
        ..strokeWidth = 1.8 + cycle * 3.2;
      final Path trough = Path()
        ..moveTo(wx - waveWidth * 0.48, wy + 2.5 * cycle)
        ..quadraticBezierTo(
          wx,
          wy - 1.5 * cycle,
          wx + waveWidth * 0.48,
          wy + 2.5 * cycle,
        );
      canvas.drawPath(trough, troughPaint);

      // Sunlit / Bioluminescent foam crest
      wavePaint
        ..color = waveBaseColor.withValues(alpha: alpha)
        ..strokeWidth = 1.3 + cycle * 2.6;

      final Path wave = Path()
        ..moveTo(wx - waveWidth * 0.5, wy)
        ..quadraticBezierTo(wx, wy - 4.8 * cycle, wx + waveWidth * 0.5, wy);
      canvas.drawPath(wave, wavePaint);
    }

    // 3. 45 Sparkling Specular Diamond Glints dancing across the water surface
    final Paint glintPaint = Paint()..style = PaintingStyle.fill;
    for (int g = 0; g < 45; g++) {
      final double gAngle = (-85.0 + g * 3.8) % 360.0;
      final double? gx = _worldAngleToScreenX(gAngle, size, margin: 40);
      if (gx == null) continue;
      final double spark = math.sin(time * (4.2 + (g % 4)) + g * 1.9);
      if (spark < 0.35) continue;
      final double depth = 0.05 + ((g * 19) % 34) / 100.0;
      final double gy = horizonY + groundHeight * depth;
      final double r = 1.5 + (spark - 0.35) * 2.5;
      glintPaint.color = Colors.white.withValues(alpha: (spark - 0.35) * 1.2);
      canvas.drawCircle(Offset(gx, gy), r, glintPaint);
    }
  }

  void _drawSandDunesAndTexture(Canvas canvas, Size size, double horizonY) {
    final double groundHeight = size.height - horizonY;

    // 1. Two Tiers of Sculpted Coastal Sand Dunes (Upper & Mid-Beach) to break up the flat sand!
    final List<Map<String, double>> dunes = [
      {'angle': 86.0, 'w': 320.0, 'h': 34.0, 'yF': 0.21},
      {'angle': 114.0, 'w': 380.0, 'h': 42.0, 'yF': 0.19},
      {'angle': 144.0, 'w': 420.0, 'h': 48.0, 'yF': 0.18},
      {'angle': 178.0, 'w': 450.0, 'h': 44.0, 'yF': 0.20},
      {'angle': 212.0, 'w': 410.0, 'h': 42.0, 'yF': 0.19},
      {'angle': 248.0, 'w': 360.0, 'h': 38.0, 'yF': 0.20},
      // Mid-ground rolling sandbanks
      {'angle': 102.0, 'w': 350.0, 'h': 28.0, 'yF': 0.36},
      {'angle': 138.0, 'w': 390.0, 'h': 32.0, 'yF': 0.34},
      {'angle': 194.0, 'w': 410.0, 'h': 30.0, 'yF': 0.35},
      {'angle': 236.0, 'w': 360.0, 'h': 28.0, 'yF': 0.37},
    ];

    final Color duneTop =
        atmosphereMode == CoconutAtmosphereMode.night
            ? const Color(0xFF4B5878)
            : const Color(0xFFF5BA82);
    final Color duneShadow =
        atmosphereMode == CoconutAtmosphereMode.night
            ? const Color(0xFF232C42)
            : const Color(0xFFB56630);

    for (final d in dunes) {
      final double? dx = _worldAngleToScreenX(d['angle']!, size, margin: 460);
      if (dx == null) continue;
      final double dy = horizonY + groundHeight * d['yF']!;
      final double w = d['w']!;
      final double h = d['h']!;

      final Path dunePath = Path()
        ..moveTo(dx - w * 0.5, dy)
        ..quadraticBezierTo(dx - w * 0.08, dy - h, dx + w * 0.5, dy + 6)
        ..close();

      canvas.drawPath(
        dunePath,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(dx, dy - h),
            Offset(dx, dy + 6),
            [
              duneTop.withValues(alpha: 0.78),
              duneShadow.withValues(alpha: 0.22),
            ],
          ),
      );
    }

    // 2. 85 Larger Wind-Carved Sand Ripple Lines with Dual Highlight & Shadow
    final Paint rippleShadow = Paint()
      ..color = (atmosphereMode == CoconutAtmosphereMode.night
              ? const Color(0xFF1A2234)
              : const Color(0xFF964D22))
          .withValues(alpha: 0.36)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final Paint rippleHighlight = Paint()
      ..color = (atmosphereMode == CoconutAtmosphereMode.night
              ? const Color(0xFF5C6E91)
              : const Color(0xFFFCE0B6))
          .withValues(alpha: 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 85; i++) {
      final double angle = (i * 4.23 + 8.0) % 360.0;
      final double? rx = _worldAngleToScreenX(angle, size, margin: 140);
      if (rx == null) continue;

      final double depth = 0.22 + ((i * 29) % 74) / 100.0;
      final double ry = horizonY + groundHeight * depth;
      final double w = 34.0 + (i % 6) * 20.0;

      final Path p = Path()
        ..moveTo(rx - w, ry)
        ..quadraticBezierTo(rx, ry + 5.0, rx + w, ry - 1.5);
      canvas.drawPath(p, rippleShadow);
      canvas.drawPath(p.shift(const Offset(0, -2.0)), rippleHighlight);
    }

    // 3. 300 Tactile Sand Grains, Pebbles & Shimmering Specks across the Beach!
    final Paint darkGrain = Paint()
      ..color = (atmosphereMode == CoconutAtmosphereMode.night
              ? const Color(0xFF181F30)
              : const Color(0xFF7D3F18))
          .withValues(alpha: 0.44);
    final Paint lightGrain = Paint()
      ..color = (atmosphereMode == CoconutAtmosphereMode.night
              ? const Color(0xFF7986CB)
              : const Color(0xFFFFE0B2))
          .withValues(alpha: 0.55);

    for (int g = 0; g < 300; g++) {
      final double gAngle = (g * 1.2 + (g % 7) * 3.1) % 360.0;
      final double? gx = _worldAngleToScreenX(gAngle, size, margin: 20);
      if (gx == null) continue;

      final double oceanFactor = _angleWeight(gAngle, 0.0, 110.0);
      final double minDepth = 0.20 + oceanFactor * 0.30;
      final double depth =
          minDepth + ((g * 41) % 100) / 100.0 * (0.96 - minDepth);
      final double gy = horizonY + groundHeight * depth;
      final double r = (g % 5 == 0) ? 2.5 : 1.5;

      canvas.drawCircle(
        Offset(gx, gy),
        r,
        g.isEven ? darkGrain : lightGrain,
      );
    }

    // 4. Clear Trail of 48 Footprints in the Sand along the Shoreline & Village Path (32°..220°)
    final Paint footprintPaint = Paint()
      ..color = (atmosphereMode == CoconutAtmosphereMode.night
              ? const Color(0xFF1A2336)
              : const Color(0xFF8A4B24))
          .withValues(alpha: 0.44);
    for (int f = 0; f < 48; f++) {
      final double fAngle = 32.0 + f * 3.9;
      final double? fx = _worldAngleToScreenX(fAngle, size, margin: 50);
      if (fx == null) continue;
      final double oceanFactor = _angleWeight(fAngle, 0.0, 118.0);
      final double fy =
          horizonY +
          groundHeight * (0.35 + 0.16 * oceanFactor) +
          (f.isEven ? -3.8 : 3.8);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(fx, fy), width: 7.2, height: 3.6),
        footprintPaint,
      );
    }
  }

  void _drawSailboats(Canvas canvas, Size size, double horizonY) {
    // 1. Playful Dolphins leaping out of the ocean near 16° and 342° (1.7x larger!)
    _drawJumpingDolphins(canvas, size, horizonY, 16.0, 0.0);
    _drawJumpingDolphins(canvas, size, horizonY, 342.0, 1.8);

    // 2. Sea Turtle swimming gently in the shallow turquoise water near 52° (1.85x larger!)
    _drawSwimmingSeaTurtle(canvas, size, horizonY, 52.0);

    // 3. Fleet of 6 Sailboats at various distances & angles (scaled up 1.65x!)
    final double boat1Angle = (335.0 + time * 0.42) % 360.0;
    final double boat2Angle = (26.0 - time * 0.30) % 360.0;
    final double boat3Angle = (312.0 + time * 0.22) % 360.0;
    final double boat4Angle = (48.0 - time * 0.36) % 360.0;
    final double boat5Angle = (8.0 + time * 0.26) % 360.0;
    final double boat6Angle = (296.0 - time * 0.19) % 360.0;

    _drawSingleSailboat(canvas, size, horizonY, boat3Angle, 0.90, true);
    _drawSingleSailboat(canvas, size, horizonY, boat5Angle, 0.82, false);
    _drawSingleSailboat(canvas, size, horizonY, boat6Angle, 1.02, true);
    _drawSingleSailboat(canvas, size, horizonY, boat1Angle, 1.65, true);
    _drawSingleSailboat(canvas, size, horizonY, boat2Angle, 1.28, false);
    _drawSingleSailboat(canvas, size, horizonY, boat4Angle, 1.12, false);

    // 4. Anchored Catamaran Yacht with warm party string lights & people on deck at ~326°
    _drawAnchoredCatamaran(canvas, size, horizonY, 326.0);

    // 5. Stand-Up Paddleboarder (SUP) paddling calmly across the sunset water at ~34°
    _drawPaddleboarder(
      canvas,
      size,
      horizonY,
      34.0 + math.sin(time * 0.12) * 4.0,
    );

    // 6. 2 Nearshore wooden fishing rowboats with fishermen (~63° and ~282°)
    _drawFishingBoatWithFisherman(canvas, size, horizonY, 63.0);
    _drawFishingBoatWithFisherman(canvas, size, horizonY, 282.0);
  }

  void _drawSwimmingSeaTurtle(
    Canvas canvas,
    Size size,
    double horizonY,
    double baseAngle,
  ) {
    final double tAngle = baseAngle + math.sin(time * 0.22) * 3.5;
    final double? tx = _worldAngleToScreenX(tAngle, size, margin: 120);
    if (tx == null) return;
    final double groundHeight = size.height - horizonY;
    final double ty =
        horizonY + groundHeight * 0.33 + math.sin(time * 1.6) * 2.5;

    canvas.save();
    canvas.translate(tx, ty);
    canvas.scale(1.85);
    final double flipper = math.sin(time * 3.2) * 3.5;
    // Water ripple around turtle
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 22, height: 14),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    final Paint turtlePaint = Paint()
      ..color = const Color(0xFF1B4D3E).withValues(alpha: 0.86);
    // Shell
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 16, height: 11),
      turtlePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 11, height: 7),
      Paint()..color = const Color(0xFF2E7D32).withValues(alpha: 0.75),
    );
    // Head
    canvas.drawCircle(const Offset(9.5, 0), 2.8, turtlePaint);
    // Flippers
    canvas.drawLine(
      const Offset(3, -4),
      Offset(6.5, -10 + flipper),
      turtlePaint
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      const Offset(3, 4),
      Offset(6.5, 10 - flipper),
      turtlePaint,
    );
    canvas.restore();
  }

  void _drawPaddleboarder(
    Canvas canvas,
    Size size,
    double horizonY,
    double worldAngle,
  ) {
    final double? px = _worldAngleToScreenX(worldAngle, size, margin: 140);
    if (px == null) return;
    final double groundHeight = size.height - horizonY;
    final double py =
        horizonY + groundHeight * 0.24 + math.sin(time * 2.1) * 2.2;

    canvas.save();
    canvas.translate(px, py);
    canvas.scale(1.75);

    // Water ripple & board
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 2), width: 38, height: 5.5),
      Paint()..color = Colors.white.withValues(alpha: 0.38),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 34, height: 5.0),
      Paint()..color = const Color(0xFFFFB74D),
    );
    canvas.drawLine(
      const Offset(-12, 0),
      const Offset(12, 0),
      Paint()
        ..color = const Color(0xFFE65100)
        ..strokeWidth = 1.4,
    );

    // Standing person paddling with sun hat & life vest
    final Paint pPaint = Paint()
      ..color = const Color(0xFF231520)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(const Offset(0, -22), 3.6, pPaint);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -24.5), width: 10, height: 2.8),
      Paint()..color = const Color(0xFFFFE082),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-4, -18, 8, 10),
        const Radius.circular(2.5),
      ),
      Paint()..color = const Color(0xFF00ACC1),
    );
    canvas.drawLine(const Offset(-2, -8), const Offset(-2.5, 0), pPaint);
    canvas.drawLine(const Offset(2, -8), const Offset(2.5, 0), pPaint);

    // Animated paddle stroke
    final double stroke = math.sin(time * 2.6) * 4.5;
    canvas.drawLine(
      const Offset(3.5, -15),
      Offset(9 + stroke, 3.5),
      Paint()
        ..color = const Color(0xFF4E342E)
        ..strokeWidth = 1.6,
    );

    canvas.restore();
  }

  void _drawJumpingDolphins(
    Canvas canvas,
    Size size,
    double horizonY,
    double baseAngle,
    double phaseOffset,
  ) {
    final double? dx = _worldAngleToScreenX(baseAngle, size, margin: 180);
    if (dx == null) return;

    final double groundHeight = size.height - horizonY;
    final double waterY = horizonY + groundHeight * 0.12;

    for (int d = 0; d < 3; d++) {
      final double cycle = ((time * 0.55 + phaseOffset + d * 0.32) % 2.1);
      if (cycle > 1.0) continue;

      final double t = cycle;
      final double jumpX = dx + (d * 34.0) + (t - 0.5) * 68.0;
      final double jumpArc = math.sin(t * math.pi);
      final double jumpY = waterY - jumpArc * 38.0;
      final double pitchAngle = (t - 0.5) * 1.35;

      canvas.save();
      canvas.translate(jumpX, jumpY);
      canvas.rotate(pitchAngle);
      canvas.scale(1.65);

      final Path body = Path()
        ..moveTo(-13, 2)
        ..quadraticBezierTo(-2, -8.5, 13, 0)
        ..quadraticBezierTo(2, 4.0, -13, 2)
        ..close();
      body.moveTo(-2, -3);
      body.lineTo(-6.0, -9.5);
      body.lineTo(2.0, -3);
      canvas.drawPath(body, Paint()..color = const Color(0xFF283C52));
      canvas.restore();

      if (t < 0.24 || t > 0.76) {
        canvas.drawCircle(
          Offset(jumpX, waterY + 1),
          6.5,
          Paint()..color = Colors.white.withValues(alpha: 0.80),
        );
      }
    }
  }

  void _drawAnchoredCatamaran(
    Canvas canvas,
    Size size,
    double horizonY,
    double worldAngle,
  ) {
    final double? cx = _worldAngleToScreenX(worldAngle, size, margin: 220);
    if (cx == null) return;

    final double groundHeight = size.height - horizonY;
    final double cy =
        horizonY + groundHeight * 0.14 + math.sin(time * 1.8) * 2.2;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(1.85);

    // Warm string light reflection on the water
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 8), width: 68, height: 8),
      Paint()..color = const Color(0xFFFFB74D).withValues(alpha: 0.42),
    );

    // Twin hulls & cabin deck
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-34, 0, 68, 6.0),
        const Radius.circular(3.0),
      ),
      Paint()..color = const Color(0xFFECEFF1),
    );
    final Path cabin = Path()
      ..moveTo(-21, 0)
      ..lineTo(-14, -11)
      ..lineTo(16, -11)
      ..lineTo(23, 0)
      ..close();
    canvas.drawPath(cabin, Paint()..color = const Color(0xFF37474F));

    // 2 People standing on the catamaran bow/stern deck watching the sunset
    canvas.drawCircle(
      const Offset(-25, -12),
      2.8,
      Paint()..color = const Color(0xFF231520),
    );
    canvas.drawRect(
      const Rect.fromLTWH(-27, -9, 4.5, 9),
      Paint()..color = const Color(0xFFE65100),
    );
    canvas.drawCircle(
      const Offset(25, -11.5),
      2.7,
      Paint()..color = const Color(0xFF231520),
    );
    canvas.drawRect(
      const Rect.fromLTWH(23, -8.5, 4.5, 8.5),
      Paint()..color = const Color(0xFF26A69A),
    );

    // Glowing cabin windows
    for (final double wx in [-9, 0, 9]) {
      canvas.drawRect(
        Rect.fromLTWH(wx - 3.0, -7.0, 6.0, 4.5),
        Paint()..color = const Color(0xFFFFE082),
      );
    }

    // Mast & Festoon party lights from mast to bow/stern
    canvas.drawLine(
      const Offset(0, -11),
      const Offset(0, -46),
      Paint()
        ..color = const Color(0xFFCFD8DC)
        ..strokeWidth = 2.0,
    );
    for (int l = -4; l <= 4; l++) {
      if (l == 0) continue;
      final double lx = l * 6.8;
      final double ly = -44.0 + l.abs() * 8.6;
      canvas.drawCircle(
        Offset(lx, ly),
        2.2,
        Paint()..color = const Color(0xFFFFF59D),
      );
    }

    canvas.restore();
  }

  void _drawSingleSailboat(
    Canvas canvas,
    Size size,
    double horizonY,
    double worldAngle,
    double scale,
    bool facingRight,
  ) {
    final double? bx = _worldAngleToScreenX(worldAngle, size, margin: 140);
    if (bx == null) return;

    final double bob = math.sin(time * 2.0 + worldAngle) * 2.0 * scale;
    final double tilt = math.sin(time * 1.5 + worldAngle) * 0.04;
    final double by = horizonY + 12.0 * scale + bob;

    canvas.save();
    canvas.translate(bx, by);
    canvas.rotate(tilt);
    if (!facingRight) {
      canvas.scale(-scale, scale);
    } else {
      canvas.scale(scale, scale);
    }

    // Water reflection under hull
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 7), width: 44, height: 5.0),
      Paint()..color = const Color(0xFF1A0F24).withValues(alpha: 0.40),
    );

    final Paint hullPaint = Paint()..color = const Color(0xFF23162B);
    final Path hull = Path()
      ..moveTo(-21, 0)
      ..lineTo(24, 0)
      ..lineTo(17, 7.0)
      ..lineTo(-17, 7.0)
      ..close();
    canvas.drawPath(hull, hullPaint);

    // Hull stripe & warm cabin portholes
    canvas.drawLine(
      const Offset(-19, 2.2),
      const Offset(21, 2.2),
      Paint()
        ..color = const Color(0xFFFFAB40).withValues(alpha: 0.70)
        ..strokeWidth = 1.2,
    );
    canvas.drawCircle(
      const Offset(-4, 3.8),
      2.0,
      Paint()..color = const Color(0xFFFFD54F),
    );
    canvas.drawCircle(
      const Offset(3.5, 3.8),
      1.8,
      Paint()..color = const Color(0xFFFFD54F),
    );

    // Mast & fluttering pennant flag at top
    canvas.drawLine(
      const Offset(-2, 0),
      const Offset(-2, -40),
      Paint()
        ..color = const Color(0xFF3E2723)
        ..strokeWidth = 1.8,
    );
    final Path pennant = Path()
      ..moveTo(-2, -40)
      ..lineTo(-10, -38 + math.sin(time * 5.0 + worldAngle) * 1.6)
      ..lineTo(-2, -36)
      ..close();
    canvas.drawPath(pennant, Paint()..color = const Color(0xFFFF5252));

    // Main sail
    final Paint sailPaint = Paint()
      ..color = const Color(0xFFFFE0B2).withValues(alpha: 0.95);
    final Path mainSail = Path()
      ..moveTo(-2, -3)
      ..lineTo(-2, -38)
      ..quadraticBezierTo(15, -19, 18, -3)
      ..close();
    canvas.drawPath(mainSail, sailPaint);

    // Front jib sail
    final Path jibSail = Path()
      ..moveTo(-4, -3)
      ..lineTo(-3, -32)
      ..quadraticBezierTo(-17, -16, -19, -3)
      ..close();
    canvas.drawPath(
      jibSail,
      Paint()..color = const Color(0xFFFFCC80).withValues(alpha: 0.92),
    );

    canvas.restore();
  }

  void _drawFishingBoatWithFisherman(
    Canvas canvas,
    Size size,
    double horizonY,
    double worldAngle,
  ) {
    final double? bx = _worldAngleToScreenX(worldAngle, size, margin: 180);
    if (bx == null) return;

    final double groundHeight = size.height - horizonY;
    final double bob = math.sin(time * 2.3 + worldAngle) * 2.5;
    final double by = horizonY + groundHeight * 0.18 + bob;

    canvas.save();
    canvas.translate(bx, by);
    canvas.rotate(math.sin(time * 1.7 + worldAngle) * 0.03);
    canvas.scale(1.80);

    // Wooden rowboat hull with plank lines
    final Path hull = Path()
      ..moveTo(-28, 0)
      ..lineTo(28, 0)
      ..lineTo(19, 9.5)
      ..lineTo(-19, 9.5)
      ..close();
    canvas.drawPath(hull, Paint()..color = const Color(0xFF4E342E));
    canvas.drawLine(
      const Offset(-25, 3),
      const Offset(25, 3),
      Paint()
        ..color = const Color(0xFF8D6E63)
        ..strokeWidth = 1.3,
    );

    // Oar resting on the side
    canvas.drawLine(
      const Offset(-6, 2),
      const Offset(-16, 11),
      Paint()
        ..color = const Color(0xFFA1887F)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    // Fisherman sitting silhouette
    canvas.drawCircle(
      const Offset(-4, -13),
      4.8,
      Paint()..color = const Color(0xFF231624),
    );
    // Straw hat
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-4, -16.5), width: 16, height: 4.0),
      Paint()..color = const Color(0xFFD7CCC8),
    );
    // Torso
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-9, -8.5, 10, 9.5),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF2D3A4B),
    );
    // Fishing rod, line & bobbing red-white float on the water!
    final double rodBob = math.sin(time * 2.8) * 2.0;
    canvas.drawLine(
      const Offset(0, -5),
      Offset(29, -19 + rodBob),
      Paint()
        ..color = const Color(0xFF5D4037)
        ..strokeWidth = 1.6,
    );
    canvas.drawLine(
      Offset(29, -19 + rodBob),
      const Offset(34, 7),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.58)
        ..strokeWidth = 1.0,
    );
    canvas.drawCircle(
      const Offset(34, 7),
      2.5,
      Paint()..color = const Color(0xFFFF5252),
    );

    // Warm bow lantern
    canvas.drawCircle(
      const Offset(21, -4),
      13,
      Paint()
        ..shader = ui.Gradient.radial(
          const Offset(21, -4),
          13,
          [const Color(0xFFFFB74D).withValues(alpha: 0.65), Colors.transparent],
        ),
    );
    canvas.drawCircle(
      const Offset(21, -4),
      2.8,
      Paint()..color = const Color(0xFFFFF59D),
    );

    canvas.restore();
  }

  void _drawSeagulls(Canvas canvas, Size size, double horizonY) {
    final Paint gullPaint = Paint()
      ..color = (atmosphereMode == CoconutAtmosphereMode.night
              ? const Color(0xFFCFD8DC)
              : const Color(0xFF2A1832))
          .withValues(alpha: 0.88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 28; i++) {
      final double speed =
          (i % 2 == 0 ? 3.0 : -2.4) * (0.72 + (i % 5) * 0.16);
      final double gullAngle = (i * 12.8 + time * speed) % 360.0;
      final double? gx = _worldAngleToScreenX(gullAngle, size, margin: 80);
      if (gx == null) continue;

      final double gy =
          horizonY -
          size.height * (0.09 + (i % 6) * 0.048) +
          math.sin(time * 2.0 + i) * 8.0;
      final double flap = math.sin(time * (6.5 + i * 0.35) + i * 1.3) * 8.5;
      final double span = 10.5 + (i % 4) * 3.8;

      final Path wingPath = Path()
        ..moveTo(gx - span, gy - flap)
        ..quadraticBezierTo(
          gx - span * 0.45,
          gy - 5.5 - flap * 0.3,
          gx,
          gy,
        )
        ..quadraticBezierTo(
          gx + span * 0.45,
          gy - 5.5 - flap * 0.3,
          gx + span,
          gy - flap,
        );

      canvas.drawPath(wingPath, gullPaint);
    }
  }

  void _drawSkyLanterns(Canvas canvas, Size size, double horizonY) {
    if (atmosphereMode == CoconutAtmosphereMode.noon) return;

    // 16 Larger Warm Glowing Floating Sky Lanterns rising above the coastal village bay (115°..265°)
    for (int i = 0; i < 16; i++) {
      final double baseAngle =
          115.0 + i * 9.5 + math.sin(time * 0.4 + i) * 3.5;
      final double? lx = _worldAngleToScreenX(baseAngle, size, margin: 80);
      if (lx == null) continue;

      final double riseProgress = ((time * 0.042 + i * 0.062) % 1.0);
      final double ly =
          horizonY - size.height * (0.05 + riseProgress * 0.38);
      final double alpha = math.sin(riseProgress * math.pi).clamp(0.0, 1.0);

      canvas.drawCircle(
        Offset(lx, ly),
        22.0,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(lx, ly),
            22.0,
            [
              const Color(0xFFFFAB40).withValues(alpha: alpha * 0.56),
              Colors.transparent,
            ],
          ),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(lx, ly), width: 10.5, height: 13.5),
          const Radius.circular(3.5),
        ),
        Paint()..color = const Color(0xFFFFCC80).withValues(alpha: alpha * 0.94),
      );
      canvas.drawCircle(
        Offset(lx, ly + 3),
        3.0,
        Paint()..color = const Color(0xFFFFF9C4).withValues(alpha: alpha),
      );
    }
  }

  void _drawInlandHillsAndFoliage(
    Canvas canvas,
    Size size,
    double horizonY,
  ) {
    // Tier 1: 6 Towering Tropical Mountain Peaks (85°..280°) with 3D sunlit/shadow ridges, valley mist & wide cascading waterfall!
    final List<Map<String, double>> distantMountains = [
      {'angle': 94.0, 'w': 460.0, 'h': 168.0},
      {'angle': 124.0, 'w': 520.0, 'h': 215.0},
      {'angle': 152.0, 'w': 550.0, 'h': 238.0},
      {'angle': 178.0, 'w': 610.0, 'h': 265.0}, // Has multi-tiered cascading waterfall & turquoise lagoon!
      {'angle': 216.0, 'w': 560.0, 'h': 225.0},
      {'angle': 254.0, 'w': 460.0, 'h': 165.0},
    ];

    for (int i = 0; i < distantMountains.length; i++) {
      final m = distantMountains[i];
      final double? mx = _worldAngleToScreenX(m['angle']!, size, margin: 640);
      if (mx == null) continue;

      final double width = m['w']!;
      final double height = m['h']!;
      final double baseY = horizonY + 18.0;
      final double peakX = mx - width * 0.04;
      final double peakY = baseY - height;

      final Path mtnPath = Path()
        ..moveTo(mx - width * 0.5, baseY)
        ..lineTo(mx - width * 0.34, baseY - height * 0.48)
        ..lineTo(mx - width * 0.21, baseY - height * 0.78)
        ..lineTo(peakX, peakY)
        ..lineTo(mx + width * 0.14, baseY - height * 0.84)
        ..lineTo(mx + width * 0.28, baseY - height * 0.56)
        ..lineTo(mx + width * 0.5, baseY)
        ..close();

      canvas.drawPath(
        mtnPath,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(mx, peakY),
            Offset(mx, baseY),
            [
              const Color(0xFF433158).withValues(alpha: 0.94),
              const Color(0xFF282D3E),
              const Color(0xFF1C2430),
            ],
            [0.0, 0.58, 1.0],
          ),
      );

      // 3D Sunlit Ridge Highlight Facet & Craggy Secondary Ridge Lines
      final Path ridgeFacet = Path()
        ..moveTo(peakX, peakY)
        ..lineTo(mx - width * 0.10, baseY)
        ..lineTo(mx - width * 0.46, baseY)
        ..lineTo(mx - width * 0.21, baseY - height * 0.78)
        ..close();
      canvas.save();
      canvas.clipPath(mtnPath);
      canvas.drawPath(
        ridgeFacet,
        Paint()
          ..color = const Color(0xFFFFAB73).withValues(
            alpha: atmosphereMode == CoconutAtmosphereMode.night ? 0.05 : 0.14,
          ),
      );
      // Secondary dark rock striations on right slope
      final Path shadowFacet = Path()
        ..moveTo(peakX, peakY)
        ..lineTo(mx + width * 0.14, baseY - height * 0.84)
        ..lineTo(mx + width * 0.26, baseY)
        ..lineTo(mx + width * 0.04, baseY)
        ..close();
      canvas.drawPath(
        shadowFacet,
        Paint()..color = Colors.black.withValues(alpha: 0.18),
      );
      canvas.restore();

      // Soft Valley Mist Band drifting across the mountain slopes
      final double mistDrift = math.sin(time * 0.35 + i) * 18.0;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(mx + mistDrift, baseY - height * 0.34),
          width: width * 0.72,
          height: 24.0,
        ),
        Paint()
          ..color = const Color(0xFFFFE0B2).withValues(
            alpha: atmosphereMode == CoconutAtmosphereMode.night ? 0.04 : 0.09,
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );

      // Wide, Multi-Tiered Tropical Waterfall & Turquoise Plunge Lagoon on the main peak (178°)
      if (i == 3) {
        final double wfX = peakX + 16.0;
        final double wfTop = peakY + 38.0;
        final double wfMid = peakY + height * 0.54;
        final double wfBottom = baseY - 10.0;

        // Dark wet cliff face behind the waterfall
        final Path cliffGorge = Path()
          ..moveTo(wfX - 18, wfTop - 4)
          ..lineTo(wfX + 18, wfTop - 4)
          ..lineTo(wfX + 28, wfBottom)
          ..lineTo(wfX - 14, wfBottom)
          ..close();
        canvas.drawPath(
          cliffGorge,
          Paint()..color = const Color(0xFF161D26).withValues(alpha: 0.65),
        );

        // Upper & Lower Waterfall Streams (wide multi-ribbon cascades)
        for (int stream = -1; stream <= 1; stream++) {
          final double sx = wfX + stream * 6.5;
          final Path cascade = Path()
            ..moveTo(sx - 3.5, wfTop)
            ..quadraticBezierTo(sx - 1.5, (wfTop + wfMid) * 0.5, sx + 2.0, wfMid)
            ..quadraticBezierTo(
              sx + 6.0,
              (wfMid + wfBottom) * 0.5,
              sx + 8.0 + stream * 2.5,
              wfBottom,
            );
          canvas.drawPath(
            cascade,
            Paint()
              ..color = const Color(0xFF80DEEA).withValues(alpha: 0.55)
              ..style = PaintingStyle.stroke
              ..strokeWidth = stream == 0 ? 7.5 : 4.5
              ..strokeCap = StrokeCap.round,
          );
          canvas.drawPath(
            cascade,
            Paint()
              ..color = Colors.white.withValues(alpha: 0.75)
              ..style = PaintingStyle.stroke
              ..strokeWidth = stream == 0 ? 3.5 : 2.0
              ..strokeCap = StrokeCap.round,
          );
        }

        // Rock ledge pool at mid-tier with white splash mist
        canvas.drawOval(
          Rect.fromCenter(center: Offset(wfX + 3, wfMid), width: 32, height: 8),
          Paint()..color = const Color(0xFF26C6DA).withValues(alpha: 0.70),
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(wfX + 3, wfMid - 2), width: 26, height: 7),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.48)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );

        // Animated rushing foam streaks & falling water droplets
        for (int d = 0; d < 12; d++) {
          final double p = ((time * 1.5 + d * 0.083) % 1.0);
          final double dy = wfTop + p * (wfBottom - wfTop);
          final double dx = wfX + p * 8.0 + math.sin(d * 2.1 + time * 4.0) * 5.5;
          canvas.drawOval(
            Rect.fromCenter(center: Offset(dx, dy), width: 3.2, height: 7.5),
            Paint()..color = Colors.white.withValues(alpha: 0.82 * (1.0 - p * 0.3)),
          );
        }

        // Glowing Turquoise Plunge Pool Lagoon & Mist Cloud at Waterfall Base
        canvas.drawOval(
          Rect.fromCenter(center: Offset(wfX + 8, wfBottom + 2), width: 68, height: 14),
          Paint()..color = const Color(0xFF00ACC1).withValues(alpha: 0.65),
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(wfX + 8, wfBottom - 2), width: 48, height: 14),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.45)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
        );
      }
    }

    // Tier 2: 8 Lush, Taller Rolling Coastal Jungle Hills in front of the mountains
    final List<Map<String, double>> hills = [
      {'angle': 86.0, 'w': 360.0, 'h': 88.0},
      {'angle': 112.0, 'w': 430.0, 'h': 118.0},
      {'angle': 140.0, 'w': 470.0, 'h': 136.0},
      {'angle': 168.0, 'w': 490.0, 'h': 142.0},
      {'angle': 198.0, 'w': 500.0, 'h': 146.0},
      {'angle': 226.0, 'w': 460.0, 'h': 124.0},
      {'angle': 254.0, 'w': 390.0, 'h': 98.0},
      {'angle': 278.0, 'w': 310.0, 'h': 72.0},
    ];

    for (int i = 0; i < hills.length; i++) {
      final h = hills[i];
      final double? hx = _worldAngleToScreenX(h['angle']!, size, margin: 520);
      if (hx == null) continue;

      final double width = h['w']!;
      final double height = h['h']!;
      final double baseY = horizonY + 22.0;

      final Paint hillPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(hx, baseY - height),
          Offset(hx, baseY),
          [
            i.isEven ? const Color(0xFF2D464B) : const Color(0xFF22373F),
            const Color(0xFF15242B),
          ],
        );

      final Path hillPath = Path()
        ..moveTo(hx - width * 0.5, baseY)
        ..quadraticBezierTo(
          hx - width * 0.16,
          baseY - height * 1.08,
          hx + width * 0.08,
          baseY - height * 0.88,
        )
        ..quadraticBezierTo(
          hx + width * 0.34,
          baseY - height * 0.66,
          hx + width * 0.5,
          baseY,
        )
        ..close();

      canvas.drawPath(hillPath, hillPaint);
    }

    // Tier 3: Rich Multi-Layered Tropical Rainforest Canopy along the foot of the hills (80 varied organic tree crowns)
    final Paint canopyBack = Paint()..color = const Color(0xFF15262A);
    final Paint canopyMid = Paint()..color = const Color(0xFF1D3539);
    final Paint canopySunlit = Paint()..color = const Color(0xFF294A4B);
    for (int c = 0; c < 80; c++) {
      final double cAngle = 74.0 + c * 2.6;
      final double? cx = _worldAngleToScreenX(cAngle, size, margin: 120);
      if (cx == null) continue;
      final double cy = horizonY + 20.0 - (c % 3) * 5.0;
      final double r = 22.0 + (c % 5) * 6.8;
      // Multi-puff organic tree crown instead of a single flat circle
      final Paint p = c % 3 == 0
          ? canopySunlit
          : (c.isEven ? canopyMid : canopyBack);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy - r * 0.45), width: r * 2.2, height: r * 1.55),
        p,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx - r * 0.4, cy - r * 0.25),
          width: r * 1.5,
          height: r * 1.2,
        ),
        p,
      );
    }
  }

  void _drawBackgroundPalmGrove(Canvas canvas, Size size, double horizonY) {
    final double groundHeight = size.height - horizonY;
    // 18 Tall Background Palm Trees rising high behind the village houses for a lush tropical skyline
    final List<Map<String, double>> bgPalms = [
      {'angle': 72.0, 'yFactor': 0.13, 'scale': 0.88, 'lean': -0.20},
      {'angle': 83.0, 'yFactor': 0.12, 'scale': 0.94, 'lean': 0.15},
      {'angle': 94.0, 'yFactor': 0.12, 'scale': 0.98, 'lean': -0.14},
      {'angle': 105.0, 'yFactor': 0.11, 'scale': 1.05, 'lean': 0.18},
      {'angle': 116.0, 'yFactor': 0.11, 'scale': 1.02, 'lean': -0.16},
      {'angle': 127.0, 'yFactor': 0.12, 'scale': 0.96, 'lean': 0.18},
      {'angle': 138.0, 'yFactor': 0.11, 'scale': 1.06, 'lean': -0.12},
      {'angle': 150.0, 'yFactor': 0.12, 'scale': 0.98, 'lean': 0.16},
      {'angle': 161.0, 'yFactor': 0.12, 'scale': 0.94, 'lean': -0.18},
      {'angle': 173.0, 'yFactor': 0.12, 'scale': 1.00, 'lean': 0.20},
      {'angle': 185.0, 'yFactor': 0.11, 'scale': 1.04, 'lean': -0.15},
      {'angle': 197.0, 'yFactor': 0.11, 'scale': 1.06, 'lean': -0.15},
      {'angle': 209.0, 'yFactor': 0.12, 'scale': 0.95, 'lean': 0.16},
      {'angle': 221.0, 'yFactor': 0.11, 'scale': 1.00, 'lean': -0.18},
      {'angle': 234.0, 'yFactor': 0.11, 'scale': 1.02, 'lean': 0.14},
      {'angle': 246.0, 'yFactor': 0.12, 'scale': 0.96, 'lean': -0.16},
      {'angle': 258.0, 'yFactor': 0.12, 'scale': 0.92, 'lean': 0.22},
      {'angle': 270.0, 'yFactor': 0.13, 'scale': 0.86, 'lean': -0.16},
    ];

    for (int i = 0; i < bgPalms.length; i++) {
      final p = bgPalms[i];
      final double? px = _worldAngleToScreenX(
        p['angle']!,
        size,
        margin: 280,
      );
      if (px == null) continue;
      final double py = horizonY + groundHeight * p['yFactor']!;
      _drawSinglePalmTree(
        canvas,
        Offset(px, py),
        p['scale']!,
        p['lean']!,
        i + 20,
      );
    }
  }

  void _drawStructuresAndVillageLife(
    Canvas canvas,
    Size size,
    double horizonY,
  ) {
    final double groundHeight = size.height - horizonY;

    // 0. Coastal Village Timber Boardwalk, Tropical Flower Beds, Tiki Torches & Strolling Villagers (110°..262°)
    _drawVillageBoardwalkAndTorches(
      canvas,
      size,
      horizonY + groundHeight * 0.22,
    );

    // 1. Extended Large Wooden Pier with Tied Dinghy, Pelican, Crates, 2 Lanterns & 4 People at ~74°
    _drawWoodenPierWithPeople(canvas, size, horizonY, 74.0);

    // 2. Strolling Couple walking along the sunset shoreline at ~44°
    _drawShorelineStrollers(canvas, size, horizonY + groundHeight * 0.36, 44.0);

    // 3. Village Festoon String Lights connecting the entire coastal village (115°..260°)
    _drawVillageFestoonLights(canvas, size, horizonY + groundHeight * 0.18);

    // 4. Building 1: Two-Story Coastal Timber Manor with Veranda, Flower Boxes & Chimney at ~115°
    _drawTwoStoryCoastalHouse(
      canvas,
      size,
      horizonY + groundHeight * 0.18,
      115.0,
    );

    // 5. Building 2: Coastal Surf & Dive Shack with Surfboard Rack & Stripy Awning at ~132°
    _drawSurfShack(canvas, size, horizonY + groundHeight * 0.20, 132.0);

    // 6. Building 3: Grand Beach Villa with Roof Shingles, Curtains & Lounger Deck at ~146°
    _drawBeachVilla(canvas, size, horizonY + groundHeight * 0.19, 146.0);

    // 7. Building 4: Weathered Coastal Boat House & Harbor Store with Anchor & Nets at ~180°
    _drawVillageBoatHouse(canvas, size, horizonY + groundHeight * 0.18, 180.0);

    // 8. Building 5: Cozy Beach Cafe & Bakery with Bistro Table & 2 Seated Patrons at ~192°
    _drawBeachCafeWithPatrons(
      canvas,
      size,
      horizonY + groundHeight * 0.20,
      192.0,
    );

    // 9. Building 6: Lively Tiki Bar & Cabana Lounge with Bartender & 3 Patrons at ~208°
    _drawTikiCabanaWithPeople(
      canvas,
      size,
      horizonY + groundHeight * 0.21,
      208.0,
    );

    // 10. Buildings 7, 8 & 9: Three Colorful Fisherman Village Cottages at ~228°, ~244° & ~258°
    _drawFishermanCottage(
      canvas,
      size,
      horizonY + groundHeight * 0.18,
      228.0,
      wallColor: const Color(0xFF457B8C), // Seafoam turquoise
      roofColor: const Color(0xFF4E342E),
      hasClothesline: true,
    );
    _drawFishermanCottage(
      canvas,
      size,
      horizonY + groundHeight * 0.20,
      244.0,
      wallColor: const Color(0xFFB85D43), // Warm terracotta coral
      roofColor: const Color(0xFF3E2723),
      hasClothesline: false,
    );
    _drawFishermanCottage(
      canvas,
      size,
      horizonY + groundHeight * 0.19,
      258.0,
      wallColor: const Color(0xFFD49B4B), // Ochre yellow
      roofColor: const Color(0xFF4E342E),
      hasClothesline: true,
    );

    // 11. Distant Coastal Lighthouse & Keeper's House with Rotating Beam at ~292°
    _drawLighthouse(canvas, size, horizonY + 12.0, 292.0);

    // 12. Main Beach Bonfire Gathering (Moved closer & scaled ~1.90x!) with 7 Detailed People, Dog, Guitar & Chatting at ~163°
    _drawMainCampfireWithPeople(
      canvas,
      size,
      horizonY + groundHeight * 0.38,
      163.0,
    );

    // 13. Second Cozy Cove Campfire with 3 People Chatting at ~264°
    _drawCozyCoveCampfireWithCouple(
      canvas,
      size,
      horizonY + groundHeight * 0.34,
      264.0,
    );
  }

  void _drawVillageBoardwalkAndTorches(
    Canvas canvas,
    Size size,
    double promenadeY,
  ) {
    // Timber boardwalk path, rope posts, flickering tiki torches & strolling villagers connecting the village (112°..260°)
    for (int seg = 0; seg < 30; seg++) {
      final double a1 = 110.0 + seg * 5.0;
      final double a2 = a1 + 5.2;
      final double? x1 = _worldAngleToScreenX(a1, size, margin: 200);
      final double? x2 = _worldAngleToScreenX(a2, size, margin: 200);
      if (x1 == null || x2 == null) continue;

      final double waveY = math.sin(seg * 0.6) * 4.0;
      final Rect plankRect = Rect.fromLTRB(
        math.min(x1, x2),
        promenadeY + waveY,
        math.max(x1, x2) + 2,
        promenadeY + waveY + 11.0,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(plankRect, const Radius.circular(3)),
        Paint()
          ..color = seg.isEven
              ? const Color(0xFF6D4C41).withValues(alpha: 0.88)
              : const Color(0xFF5D4037).withValues(alpha: 0.88),
      );

      // Low coastal wooden fence post & flaming tiki torch every 3 segments
      if (seg % 3 == 0) {
        final double tx = (x1 + x2) * 0.5;
        final double ty = promenadeY + waveY + 4.0;
        // Bamboo torch pole
        canvas.drawLine(
          Offset(tx, ty + 6),
          Offset(tx, ty - 34),
          Paint()
            ..color = const Color(0xFF8D6E63)
            ..strokeWidth = 3.2,
        );
        // Torch canister
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(tx, ty - 36), width: 7, height: 10),
            const Radius.circular(2),
          ),
          Paint()..color = const Color(0xFF4E342E),
        );
        // Flickering Tiki Torch Flame & Warm Glow Halo
        final double flicker = math.sin(time * 8.5 + seg) * 2.5;
        canvas.drawCircle(
          Offset(tx, ty - 45),
          22.0,
          Paint()
            ..shader = ui.Gradient.radial(
              Offset(tx, ty - 45),
              22.0,
              [
                const Color(0xFFFF9100).withValues(alpha: 0.45),
                Colors.transparent,
              ],
            ),
        );
        final Path tikiFlame = Path()
          ..moveTo(tx - 4.5, ty - 40)
          ..quadraticBezierTo(tx - 2, ty - 52, tx + flicker, ty - 56)
          ..quadraticBezierTo(tx + 3, ty - 50, tx + 4.5, ty - 40)
          ..close();
        canvas.drawPath(tikiFlame, Paint()..color = const Color(0xFFFFAB00));
        canvas.drawCircle(
          Offset(tx + flicker * 0.3, ty - 44),
          2.6,
          Paint()..color = const Color(0xFFFFF9C4),
        );
      }
    }

    // 4 Animated Villagers strolling along the village boardwalk!
    final List<Map<String, dynamic>> villagers = [
      {'baseAngle': 123.0, 'speed': 0.22, 'range': 5.5, 'color': const Color(0xFF26A69A)},
      {'baseAngle': 155.0, 'speed': -0.19, 'range': 6.0, 'color': const Color(0xFFFF7043)},
      {'baseAngle': 200.0, 'speed': 0.25, 'range': 5.0, 'color': const Color(0xFF5C6BC0)},
      {'baseAngle': 236.0, 'speed': -0.21, 'range': 6.5, 'color': const Color(0xFFEC407A)},
    ];
    for (int v = 0; v < villagers.length; v++) {
      final vm = villagers[v];
      final double vAngle =
          (vm['baseAngle'] as double) +
          math.sin(time * (vm['speed'] as double) + v * 1.7) *
              (vm['range'] as double);
      final double? vx = _worldAngleToScreenX(vAngle, size, margin: 120);
      if (vx == null) continue;
      final double vy = promenadeY + 4.0;
      final double walkBob = math.sin(time * 4.2 + v).abs() * 2.2;
      final double stride = math.sin(time * 4.2 + v) * 4.5;

      canvas.save();
      canvas.translate(vx, vy);
      canvas.scale(1.55);
      // Shadow
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, 3), width: 14, height: 4.5),
        Paint()..color = Colors.black.withValues(alpha: 0.28),
      );
      // Legs
      final Paint legP = Paint()
        ..color = const Color(0xFF231520)
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(-2, -10), Offset(-2 + stride, 2), legP);
      canvas.drawLine(const Offset(2, -10), Offset(2 - stride, 2), legP);
      // Torso
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-5, -23 - walkBob, 10, 14),
          const Radius.circular(3.5),
        ),
        Paint()..color = vm['color'] as Color,
      );
      // Head
      canvas.drawCircle(
        Offset(0, -28 - walkBob),
        4.4,
        Paint()..color = const Color(0xFFE0A380),
      );
      canvas.drawArc(
        Rect.fromCircle(center: Offset(0, -28 - walkBob), radius: 4.6),
        math.pi,
        math.pi,
        true,
        Paint()..color = const Color(0xFF2B1912),
      );
      canvas.restore();
    }
  }

  void _drawVillageFestoonLights(Canvas canvas, Size size, double baseY) {
    final List<double> poleAngles = [
      115.0,
      132.0,
      146.0,
      180.0,
      192.0,
      208.0,
      228.0,
      244.0,
      258.0,
    ];
    for (int i = 0; i < poleAngles.length - 1; i++) {
      final double? x1 = _worldAngleToScreenX(
        poleAngles[i],
        size,
        margin: 420,
      );
      final double? x2 = _worldAngleToScreenX(
        poleAngles[i + 1],
        size,
        margin: 420,
      );
      if (x1 == null || x2 == null) continue;

      final double y1 = baseY - 78;
      final double y2 = baseY - 74;
      final double midX = (x1 + x2) * 0.5;
      final double midY =
          math.max(y1, y2) + 22.0 + math.sin(time * 1.8 + i) * 2.5;

      final Path wire = Path()
        ..moveTo(x1, y1)
        ..quadraticBezierTo(midX, midY, x2, y2);
      canvas.drawPath(
        wire,
        Paint()
          ..color = const Color(0xFF2D1E18).withValues(alpha: 0.72)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );

      // Large glowing festoon bulbs along the wire
      for (int b = 1; b <= 7; b++) {
        final double t = b / 8.0;
        final double bx =
            (1 - t) * (1 - t) * x1 + 2 * (1 - t) * t * midX + t * t * x2;
        final double by =
            (1 - t) * (1 - t) * y1 + 2 * (1 - t) * t * midY + t * t * y2;
        canvas.drawCircle(
          Offset(bx, by),
          8.5,
          Paint()..color = const Color(0xFFFFB74D).withValues(alpha: 0.38),
        );
        canvas.drawCircle(
          Offset(bx, by),
          3.2,
          Paint()..color = const Color(0xFFFFF59D),
        );
      }
    }
  }

  void _drawWoodenPierWithPeople(
    Canvas canvas,
    Size size,
    double horizonY,
    double worldAngle,
  ) {
    final double? px = _worldAngleToScreenX(worldAngle, size, margin: 480);
    if (px == null) return;

    final double py = horizonY + (size.height - horizonY) * 0.22;
    canvas.save();
    canvas.translate(px, py);
    canvas.scale(1.80);
    canvas.translate(-px, -py);

    final Paint woodDark = Paint()..color = const Color(0xFF3E2723);
    final Paint woodLight = Paint()..color = const Color(0xFF6D4C41);
    final Paint bracePaint = Paint()
      ..color = const Color(0xFF2D1B17)
      ..strokeWidth = 1.6;

    // 1. Support pilings, water reflections & timber X-bracing under the pier
    for (int i = 0; i < 9; i++) {
      final double postX = px - 108 + i * 25.0;
      final double postH = 27.0 + (i % 2) * 4.0;

      // Water reflection of piling
      canvas.drawRect(
        Rect.fromLTWH(postX + 0.5, py + postH, 4.5, 12),
        Paint()..color = const Color(0xFF241614).withValues(alpha: 0.32),
      );
      // White water ripple at piling base
      canvas.drawOval(
        Rect.fromCenter(center: Offset(postX + 2.8, py + postH), width: 13, height: 3),
        Paint()..color = Colors.white.withValues(alpha: 0.35),
      );

      // Diagonal X-bracing between pilings
      if (i < 8) {
        canvas.drawLine(
          Offset(postX + 3, py + 3),
          Offset(postX + 28, py + 22),
          bracePaint,
        );
        canvas.drawLine(
          Offset(postX + 28, py + 3),
          Offset(postX + 3, py + 22),
          bracePaint,
        );
      }

      // Main piling & upper railing post
      canvas.drawRect(Rect.fromLTWH(postX, py, 6.0, postH), woodDark);
      canvas.drawRect(
        Rect.fromLTWH(postX - 3.5, py - 15, 3.8, 15),
        woodLight,
      );
      // Mooring bollard cap on post
      canvas.drawRect(
        Rect.fromLTWH(postX - 4.5, py - 16.5, 5.8, 2.0),
        Paint()..color = const Color(0xFF8D6E63),
      );
    }

    // 2. Small Tied Wooden Dinghy Boat bobbing gently next to the pier!
    final double dinghyBob = math.sin(time * 2.5) * 2.2;
    final double dinghyX = px - 68;
    final double dinghyY = py + 24 + dinghyBob;
    // Mooring rope from pier post to dinghy bow
    canvas.drawLine(
      Offset(px - 83, py + 4),
      Offset(dinghyX - 14, dinghyY),
      Paint()
        ..color = const Color(0xFFA1887F)
        ..strokeWidth = 1.2,
    );
    final Path dinghyHull = Path()
      ..moveTo(dinghyX - 18, dinghyY)
      ..lineTo(dinghyX + 18, dinghyY)
      ..lineTo(dinghyX + 13, dinghyY + 6.5)
      ..lineTo(dinghyX - 13, dinghyY + 6.5)
      ..close();
    canvas.drawPath(dinghyHull, Paint()..color = const Color(0xFF8D6E63));
    canvas.drawLine(
      Offset(dinghyX - 16, dinghyY + 2),
      Offset(dinghyX + 16, dinghyY + 2),
      Paint()
        ..color = const Color(0xFFFFF8E1)
        ..strokeWidth = 1.2,
    );

    // 3. Double Rope Railing between posts
    final Path ropeTop = Path();
    final Path ropeMid = Path();
    for (int i = 0; i < 8; i++) {
      final double x1 = px - 110 + i * 25.0;
      final double x2 = x1 + 25.0;
      if (i == 0) {
        ropeTop.moveTo(x1, py - 13);
        ropeMid.moveTo(x1, py - 7);
      }
      ropeTop.quadraticBezierTo((x1 + x2) * 0.5, py - 7.5, x2, py - 13);
      ropeMid.quadraticBezierTo((x1 + x2) * 0.5, py - 3.5, x2, py - 7);
    }
    final Paint ropePaint = Paint()
      ..color = const Color(0xFFBcaaa4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawPath(ropeTop, ropePaint);
    canvas.drawPath(ropeMid, ropePaint..strokeWidth = 1.0);

    // 4. Pier Deck Planks with Individual Transverse Plank Seams
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(px - 115, py - 4.5, 215, 7.5),
        const Radius.circular(3),
      ),
      woodLight,
    );
    for (int pl = 0; pl < 34; pl++) {
      final double seamX = px - 112 + pl * 6.3;
      canvas.drawLine(
        Offset(seamX, py - 4.5),
        Offset(seamX, py + 3.0),
        woodDark..strokeWidth = 1.1,
      );
    }

    // 5. Pier Props: Wooden Crates, coiled rope, Life Preserver & Perched Pelican!
    canvas.drawRect(
      Rect.fromLTWH(px + 46, py - 15, 13, 11),
      Paint()..color = const Color(0xFF795548),
    );
    canvas.drawRect(
      Rect.fromLTWH(px + 60, py - 12, 10, 8),
      Paint()..color = const Color(0xFF8D6E63),
    );
    canvas.drawCircle(
      Offset(px + 32, py - 9),
      5.8,
      Paint()
        ..color = const Color(0xFFFF5722)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8,
    );
    // Perched coastal pelican on piling at px - 10
    canvas.drawOval(
      Rect.fromCenter(center: Offset(px - 12, py - 19), width: 7, height: 5),
      Paint()..color = const Color(0xFFECEFF1),
    );
    canvas.drawCircle(
      Offset(px - 14, py - 23),
      2.2,
      Paint()..color = const Color(0xFFECEFF1),
    );
    canvas.drawLine(
      Offset(px - 15, py - 23),
      Offset(px - 20, py - 21.5),
      Paint()
        ..color = const Color(0xFFFFB300)
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );

    // 6. 4 Detailed People on the Pier!
    final double legSwing = math.sin(time * 2.6) * 2.8;
    canvas.drawCircle(
      Offset(px - 102, py - 20),
      4.6,
      Paint()..color = const Color(0xFFE0A380),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(px - 106.5, py - 15, 9.0, 12.5),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFE65100),
    );
    canvas.drawLine(
      Offset(px - 104, py - 3),
      Offset(px - 107 + legSwing, py + 7),
      Paint()
        ..color = const Color(0xFF231520)
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round,
    );

    final double armPoint = math.sin(time * 1.4) * 3.0;
    canvas.drawCircle(
      Offset(px - 88, py - 27),
      4.6,
      Paint()..color = const Color(0xFFE0A380),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(px - 92.5, py - 22, 9.5, 13.5),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF26A69A),
    );
    canvas.drawLine(
      Offset(px - 90, py - 9),
      Offset(px - 90, py - 3),
      Paint()
        ..color = const Color(0xFF231520)
        ..strokeWidth = 2.6,
    );
    canvas.drawLine(
      Offset(px - 86, py - 9),
      Offset(px - 86, py - 3),
      Paint()
        ..color = const Color(0xFF231520)
        ..strokeWidth = 2.6,
    );
    canvas.drawLine(
      Offset(px - 91, py - 19),
      Offset(px - 102, py - 22 + armPoint),
      Paint()
        ..color = const Color(0xFFE0A380)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    final double rodTipY = py - 26 + math.sin(time * 2.2) * 2.0;
    canvas.drawCircle(
      Offset(px - 45, py - 26),
      4.5,
      Paint()..color = const Color(0xFFE0A380),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(px - 45, py - 29.5), width: 14, height: 3.8),
      Paint()..color = const Color(0xFFFFE082),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(px - 49.5, py - 21, 9.0, 12.5),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF5C6BC0),
    );
    canvas.drawLine(
      Offset(px - 46, py - 9),
      Offset(px - 46, py - 3),
      Paint()
        ..color = const Color(0xFF231520)
        ..strokeWidth = 2.6,
    );
    canvas.drawLine(
      Offset(px - 48, py - 16),
      Offset(px - 66, rodTipY),
      Paint()
        ..color = const Color(0xFF8D6E63)
        ..strokeWidth = 1.5,
    );
    canvas.drawLine(
      Offset(px - 66, rodTipY),
      Offset(px - 68, py + 20),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.52)
        ..strokeWidth = 0.9,
    );

    final double walkBob = math.sin(time * 3.5).abs() * 1.5;
    canvas.drawCircle(
      Offset(px + 8, py - 25 - walkBob),
      4.5,
      Paint()..color = const Color(0xFFE0A380),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(px + 3.5, py - 20 - walkBob, 8.5, 12.0),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFEC407A),
    );
    canvas.drawLine(
      Offset(px + 6, py - 9),
      Offset(px + 5, py - 3),
      Paint()
        ..color = const Color(0xFF231520)
        ..strokeWidth = 2.5,
    );
    canvas.drawLine(
      Offset(px + 10, py - 9),
      Offset(px + 11, py - 3),
      Paint()
        ..color = const Color(0xFF231520)
        ..strokeWidth = 2.5,
    );

    // 7. Two Hanging Warm Lanterns on the Pier (Tip & Mid-Pier)
    for (final double lOffset in [-109.0, -22.0]) {
      final double lanternX = px + lOffset;
      final double lanternY = py - 32;
      canvas.drawRect(Rect.fromLTWH(lanternX, lanternY, 3.5, 29), woodDark);
      canvas.drawLine(
        Offset(lanternX, lanternY),
        Offset(lanternX - 10, lanternY),
        woodDark..strokeWidth = 2.4,
      );

      final double swing = math.sin(time * 2.4 + lOffset) * 2.0;
      final Offset bulbCenter = Offset(lanternX - 10 + swing, lanternY + 7);

      canvas.drawCircle(
        bulbCenter,
        24,
        Paint()
          ..shader = ui.Gradient.radial(
            bulbCenter,
            24,
            [
              const Color(0xFFFFD54F).withValues(alpha: 0.72),
              Colors.transparent,
            ],
          ),
      );
      canvas.drawCircle(
        bulbCenter,
        3.8,
        Paint()..color = const Color(0xFFFFF9C4),
      );
    }

    canvas.restore();
  }

  void _drawShorelineStrollers(
    Canvas canvas,
    Size size,
    double baseY,
    double baseAngle,
  ) {
    // 2 People strolling slowly along the wet sand shore (Scaled 1.85x!)
    final double walkAngle = baseAngle + math.sin(time * 0.18) * 6.0;
    final double? sx = _worldAngleToScreenX(walkAngle, size, margin: 160);
    if (sx == null) return;

    canvas.save();
    canvas.translate(sx, baseY);
    canvas.scale(1.85);

    final double stride1 = math.sin(time * 3.8) * 3.8;
    final double stride2 = math.sin(time * 3.8 + math.pi) * 3.8;

    // Long sunset shadows on wet sand
    final Paint shadowPaint = Paint()
      ..color = const Color(0xFF4A2C22).withValues(alpha: 0.36);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-5, 11), width: 12, height: 20),
      shadowPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(8, 11), width: 12, height: 20),
      shadowPaint,
    );

    // Person 1
    final Paint pPaint = Paint()
      ..color = const Color(0xFF2B1826)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(
      const Offset(-5, -24),
      4.2,
      Paint()..color = const Color(0xFFE0A380),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-9.5, -19.5, 8.5, 11.5),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF5D3344),
    );
    canvas.drawLine(const Offset(-6.5, -8), Offset(-6.5 + stride1, 1.5), pPaint);
    canvas.drawLine(const Offset(-3.5, -8), Offset(-3.5 - stride1, 1.5), pPaint);

    // Person 2 walking beside them
    canvas.drawCircle(
      const Offset(7, -22),
      4.0,
      Paint()..color = const Color(0xFFE0A380),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(3, -17.5, 8, 11),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF8D4959),
    );
    canvas.drawLine(const Offset(5.5, -7), Offset(5.5 + stride2, 1.5), pPaint);
    canvas.drawLine(const Offset(8.5, -7), Offset(8.5 - stride2, 1.5), pPaint);

    // Holding hands between them
    canvas.drawLine(
      const Offset(-1.5, -14),
      const Offset(3.5, -13),
      pPaint..strokeWidth = 1.8,
    );

    canvas.restore();
  }

  void _drawTwoStoryCoastalHouse(
    Canvas canvas,
    Size size,
    double baseY,
    double worldAngle,
  ) {
    final double? hx = _worldAngleToScreenX(worldAngle, size, margin: 420);
    if (hx == null) return;

    canvas.save();
    canvas.translate(hx, baseY);
    canvas.scale(1.85);

    // Ground shadow
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 6), width: 162, height: 17),
      Paint()..color = Colors.black.withValues(alpha: 0.28),
    );

    // Stilts & Wooden staircase
    final Paint darkWood = Paint()..color = const Color(0xFF3E2723);
    for (final double sx in [-54, -18, 18, 54]) {
      canvas.drawRect(Rect.fromLTWH(sx - 3, -14, 6, 20), darkWood);
    }
    // Porch deck
    canvas.drawRect(
      const Rect.fromLTWH(-66, -18, 132, 5.5),
      Paint()..color = const Color(0xFF6D4C41),
    );
    // Wooden steps down to sand
    for (int s = 0; s < 4; s++) {
      canvas.drawRect(
        Rect.fromLTWH(-12.0 - s * 2, -14.0 + s * 4.5, 24.0 + s * 4, 3),
        Paint()..color = const Color(0xFF795548),
      );
    }

    // First floor walls (warm coastal cream/ochre wood with clapboard siding lines)
    canvas.drawRect(
      const Rect.fromLTWH(-54, -66, 108, 48),
      Paint()..color = const Color(0xFFA6826C),
    );
    final Paint clapboard = Paint()
      ..color = const Color(0xFF5D4037).withValues(alpha: 0.35)
      ..strokeWidth = 1.0;
    for (int l = 1; l < 6; l++) {
      canvas.drawLine(
        Offset(-54, -66 + l * 8.0),
        Offset(54, -66 + l * 8.0),
        clapboard,
      );
    }

    // Second floor gable walls
    canvas.drawRect(
      const Rect.fromLTWH(-40, -102, 80, 36),
      Paint()..color = const Color(0xFF937264),
    );
    for (int l = 1; l < 4; l++) {
      canvas.drawLine(
        Offset(-40, -102 + l * 9.0),
        Offset(40, -102 + l * 9.0),
        clapboard,
      );
    }

    // Brick Chimney with cap & gentle rising smoke
    canvas.drawRect(
      const Rect.fromLTWH(22, -128, 12, 34),
      Paint()..color = const Color(0xFF7B4B3A),
    );
    canvas.drawRect(
      const Rect.fromLTWH(20, -130, 16, 3.5),
      Paint()..color = const Color(0xFF4E342E),
    );
    for (int sm = 0; sm < 5; sm++) {
      final double p = ((time * 0.38 + sm * 0.20) % 1.0);
      final double smX = 28.0 + math.sin(time * 1.5 + sm) * (4.5 + p * 11.0);
      final double smY = -132.0 - p * 36.0;
      canvas.drawCircle(
        Offset(smX, smY),
        4.2 + p * 7.5,
        Paint()
          ..color = const Color(0xFFE0CFC8).withValues(
            alpha: (1.0 - p) * 0.28,
          ),
      );
    }

    // Main Lower Roof Skirt & Upper Pitched Roof with Shingle Lines
    final Path lowerRoof = Path()
      ..moveTo(-68, -63)
      ..lineTo(-44, -76)
      ..lineTo(44, -76)
      ..lineTo(68, -63)
      ..close();
    canvas.drawPath(lowerRoof, darkWood);

    final Path upperRoof = Path()
      ..moveTo(-52, -98)
      ..lineTo(0, -130)
      ..lineTo(52, -98)
      ..close();
    canvas.drawPath(upperRoof, Paint()..color = const Color(0xFF4E342E));
    // Roof ridge trim
    canvas.drawPath(
      upperRoof,
      Paint()
        ..color = const Color(0xFF8D6E63)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Porch columns & railings
    for (final double colX in [-60, -22, 22, 60]) {
      canvas.drawRect(
        Rect.fromLTWH(colX - 2, -63, 4, 45),
        Paint()..color = const Color(0xFFD7CCC8),
      );
    }
    final Paint railPaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 1.8;
    canvas.drawLine(const Offset(-64, -29), const Offset(64, -29), railPaint);
    for (int r = -62; r <= 62; r += 9) {
      canvas.drawLine(
        Offset(r.toDouble(), -29),
        Offset(r.toDouble(), -18),
        railPaint,
      );
    }

    // Glowing Windows (2 downstairs + 2 upstairs) with Shutters & Flower Boxes
    final List<Rect> windows = [
      const Rect.fromLTWH(-44, -54, 22, 20),
      const Rect.fromLTWH(22, -54, 22, 20),
      const Rect.fromLTWH(-28, -90, 18, 16),
      const Rect.fromLTWH(10, -90, 18, 16),
    ];
    for (final wRect in windows) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(wRect.inflate(4), const Radius.circular(4)),
        Paint()
          ..color = const Color(0xFFFFD54F).withValues(alpha: 0.32)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(wRect, const Radius.circular(2)),
        Paint()..color = const Color(0xFFFFE082),
      );
      // Louvered Shutters
      canvas.drawRect(
        Rect.fromLTWH(wRect.left - 4.5, wRect.top, 4.0, wRect.height),
        Paint()..color = const Color(0xFF2E5248),
      );
      canvas.drawRect(
        Rect.fromLTWH(wRect.right + 0.5, wRect.top, 4.0, wRect.height),
        Paint()..color = const Color(0xFF2E5248),
      );
      // Window box with tiny flowers under the window
      canvas.drawRect(
        Rect.fromLTWH(wRect.left - 2, wRect.bottom, wRect.width + 4, 3.5),
        Paint()..color = const Color(0xFF5D4037),
      );
      canvas.drawCircle(
        Offset(wRect.left + 4, wRect.bottom - 1),
        2.0,
        Paint()..color = const Color(0xFFFF5252),
      );
      canvas.drawCircle(
        Offset(wRect.center.dx, wRect.bottom - 1),
        2.0,
        Paint()..color = const Color(0xFFFF4081),
      );
      canvas.drawCircle(
        Offset(wRect.right - 4, wRect.bottom - 1),
        2.0,
        Paint()..color = const Color(0xFFFFD54F),
      );
      // Window crossbars
      canvas.drawLine(
        Offset(wRect.center.dx, wRect.top),
        Offset(wRect.center.dx, wRect.bottom),
        darkWood..strokeWidth = 1.6,
      );
      canvas.drawLine(
        Offset(wRect.left, wRect.center.dy),
        Offset(wRect.right, wRect.center.dy),
        darkWood,
      );
    }

    // Front Door with warm glass transom & welcome lantern
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-9, -51, 18, 33),
        const Radius.circular(2),
      ),
      darkWood,
    );
    canvas.drawCircle(
      const Offset(13, -44),
      2.5,
      Paint()..color = const Color(0xFFFFF59D),
    );

    // Resident relaxing on the porch veranda watching the sunset!
    final double porchSway = math.sin(time * 1.9) * 1.0;
    canvas.drawCircle(
      Offset(-36 + porchSway, -42),
      4.2,
      Paint()..color = const Color(0xFFE0A380),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-40 + porchSway, -37, 8.5, 13),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF26A69A),
    );

    canvas.restore();
  }

  void _drawSurfShack(
    Canvas canvas,
    Size size,
    double baseY,
    double worldAngle,
  ) {
    final double? sx = _worldAngleToScreenX(worldAngle, size, margin: 320);
    if (sx == null) return;

    canvas.save();
    canvas.translate(sx, baseY);
    canvas.scale(1.85);

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 4), width: 102, height: 12),
      Paint()..color = Colors.black.withValues(alpha: 0.22),
    );

    // Rustic turquoise wood shack walls
    canvas.drawRect(
      const Rect.fromLTWH(-32, -46, 64, 46),
      Paint()..color = const Color(0xFF26897E),
    );
    // Slanted corrugated roof
    final Path roof = Path()
      ..moveTo(-40, -44)
      ..lineTo(38, -54)
      ..lineTo(40, -48)
      ..lineTo(-38, -38)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFF4E342E));

    // Decorative Surfboard Sign on top of the roof!
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -56), width: 42, height: 9),
      Paint()..color = const Color(0xFFFFCA28),
    );
    canvas.drawLine(
      const Offset(-16, -56),
      const Offset(16, -56),
      Paint()
        ..color = const Color(0xFFD84315)
        ..strokeWidth = 2.0,
    );

    // Striped sun awning over service window
    for (int st = 0; st < 6; st++) {
      canvas.drawRect(
        Rect.fromLTWH(-28.0 + st * 9.2, -38, 9.2, 8),
        Paint()
          ..color = st.isEven
              ? const Color(0xFFFF7043)
              : const Color(0xFFFFF8E1),
      );
    }

    // Glowing counter window
    canvas.drawRect(
      const Rect.fromLTWH(-22, -29, 44, 15),
      Paint()..color = const Color(0xFFFFE082),
    );

    // Surfer customer standing by the surfboard rack!
    final double surferNod = math.sin(time * 2.4) * 1.2;
    canvas.drawCircle(
      Offset(-44, -27 + surferNod),
      4.2,
      Paint()..color = const Color(0xFFE0A380),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-48, -22, 8.5, 13),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFFF7043),
    );
    canvas.drawLine(
      const Offset(-45, -9),
      const Offset(-46, 1),
      Paint()
        ..color = const Color(0xFF231520)
        ..strokeWidth = 2.4,
    );
    canvas.drawLine(
      const Offset(-42, -9),
      const Offset(-41, 1),
      Paint()
        ..color = const Color(0xFF231520)
        ..strokeWidth = 2.4,
    );

    // Surfboard rack beside the shack with 3 colorful boards
    final List<Color> boardColors = [
      const Color(0xFFFF5252),
      const Color(0xFFFFD54F),
      const Color(0xFF29B6F6),
    ];
    for (int b = 0; b < 3; b++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(42.0 + b * 7.5, -20),
          width: 6.5,
          height: 36,
        ),
        Paint()..color = boardColors[b],
      );
    }

    canvas.restore();
  }

  void _drawBeachVilla(
    Canvas canvas,
    Size size,
    double baseY,
    double worldAngle,
  ) {
    final double? hx = _worldAngleToScreenX(worldAngle, size, margin: 420);
    if (hx == null) return;

    canvas.save();
    canvas.translate(hx, baseY);
    canvas.scale(1.85);

    // Soft ground shadow
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 6), width: 182, height: 19),
      Paint()..color = Colors.black.withValues(alpha: 0.26),
    );

    // Wooden stilts & deck
    final Paint stiltPaint = Paint()..color = const Color(0xFF4E342E);
    for (final double sx in [-62, -20, 20, 62]) {
      canvas.drawRect(Rect.fromLTWH(sx - 3, -14, 6, 20), stiltPaint);
    }
    canvas.drawRect(
      const Rect.fromLTWH(-76, -18, 152, 6),
      Paint()..color = const Color(0xFF6D4C41),
    );

    // Main cabin walls (warm tropical timber)
    canvas.drawRect(
      const Rect.fromLTWH(-60, -76, 120, 58),
      Paint()..color = const Color(0xFF8D6E63),
    );
    // Horizontal siding lines
    final Paint sidingPaint = Paint()
      ..color = const Color(0xFF4E342E).withValues(alpha: 0.48)
      ..strokeWidth = 1.2;
    for (int i = 1; i < 6; i++) {
      canvas.drawLine(
        Offset(-60, -76 + i * 9.5),
        Offset(60, -76 + i * 9.5),
        sidingPaint,
      );
    }

    // Pitched Tropical Roof with Roof Dormer & Shingle Texture
    final Path roof = Path()
      ..moveTo(-78, -72)
      ..lineTo(0, -118)
      ..lineTo(78, -72)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFF4E342E));
    // Roof shingle courses
    for (int r = 1; r <= 4; r++) {
      final double ry = -72.0 - r * 9.0;
      final double halfW = 78.0 * (1.0 - r * 0.19);
      canvas.drawLine(
        Offset(-halfW, ry),
        Offset(halfW, ry),
        Paint()
          ..color = const Color(0xFF3E2723)
          ..strokeWidth = 1.2,
      );
    }

    // Glowing Windows with warm interior light & curtains
    final double flicker = 0.88 + 0.12 * math.sin(time * 3.1);
    final Paint windowGlow = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.36 * flicker)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    for (final Rect wRect in [
      const Rect.fromLTWH(-46, -60, 28, 24),
      const Rect.fromLTWH(18, -60, 28, 24),
    ]) {
      canvas.drawRect(wRect.inflate(6), windowGlow);
      canvas.drawRRect(
        RRect.fromRectAndRadius(wRect, const Radius.circular(3)),
        Paint()..color = const Color(0xFFFFE082),
      );
      // Warm interior curtains
      final Path curtainLeft = Path()
        ..moveTo(wRect.left, wRect.top)
        ..lineTo(wRect.left + 8, wRect.top)
        ..quadraticBezierTo(
          wRect.left + 5,
          wRect.center.dy,
          wRect.left + 2,
          wRect.bottom,
        )
        ..lineTo(wRect.left, wRect.bottom)
        ..close();
      canvas.drawPath(
        curtainLeft,
        Paint()..color = const Color(0xFFD84315).withValues(alpha: 0.45),
      );
      final Paint frame = Paint()
        ..color = const Color(0xFF3E2723)
        ..strokeWidth = 2.0;
      canvas.drawLine(
        Offset(wRect.center.dx, wRect.top),
        Offset(wRect.center.dx, wRect.bottom),
        frame,
      );
      canvas.drawLine(
        Offset(wRect.left, wRect.center.dy),
        Offset(wRect.right, wRect.center.dy),
        frame,
      );
    }

    // Center Door
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-10, -54, 20, 36),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF3E2723),
    );

    // String lights along the porch roof
    for (int i = 0; i < 8; i++) {
      final double lx = -60.0 + i * 17.1;
      final double ly = -69.0 + math.sin(i * 0.9) * 3.0;
      canvas.drawCircle(
        Offset(lx, ly),
        6,
        Paint()..color = const Color(0xFFFFB74D).withValues(alpha: 0.36),
      );
      canvas.drawCircle(
        Offset(lx, ly),
        2.2,
        Paint()..color = const Color(0xFFFFF59D),
      );
    }

    canvas.restore();
  }

  void _drawVillageBoatHouse(
    Canvas canvas,
    Size size,
    double baseY,
    double worldAngle,
  ) {
    final double? bx = _worldAngleToScreenX(worldAngle, size, margin: 320);
    if (bx == null) return;

    canvas.save();
    canvas.translate(bx, baseY);
    canvas.scale(1.85);

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 4), width: 124, height: 14),
      Paint()..color = Colors.black.withValues(alpha: 0.24),
    );

    // Cedar house walls with vertical board seams
    canvas.drawRect(
      const Rect.fromLTWH(-44, -58, 88, 56),
      Paint()..color = const Color(0xFF795548),
    );
    for (int b = -36; b <= 36; b += 12) {
      canvas.drawLine(
        Offset(b.toDouble(), -58),
        Offset(b.toDouble(), -2),
        Paint()
          ..color = const Color(0xFF4E342E).withValues(alpha: 0.45)
          ..strokeWidth = 1.1,
      );
    }

    // Overhanging pitched roof
    final Path roof = Path()
      ..moveTo(-56, -54)
      ..lineTo(0, -88)
      ..lineTo(56, -54)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFF3E2723));

    // Glowing window
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-32, -44, 24, 18),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFFFFE082),
    );

    // Door, Life Ring & Wooden Barrels outside
    canvas.drawRect(
      const Rect.fromLTWH(8, -42, 18, 40),
      Paint()..color = const Color(0xFF4E342E),
    );
    canvas.drawCircle(
      const Offset(34, -34),
      4.8,
      Paint()
        ..color = const Color(0xFFFF5722)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-50, -16, 12, 15),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF5D4037),
    );

    canvas.restore();
  }

  void _drawBeachCafeWithPatrons(
    Canvas canvas,
    Size size,
    double baseY,
    double worldAngle,
  ) {
    final double? cx = _worldAngleToScreenX(worldAngle, size, margin: 320);
    if (cx == null) return;

    canvas.save();
    canvas.translate(cx, baseY);
    canvas.scale(1.85);

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 4), width: 118, height: 13),
      Paint()..color = Colors.black.withValues(alpha: 0.23),
    );

    // Warm pastel coral-cream cafe walls
    canvas.drawRect(
      const Rect.fromLTWH(-36, -50, 72, 50),
      Paint()..color = const Color(0xFFD7A98C),
    );
    // Terracotta roof
    final Path roof = Path()
      ..moveTo(-44, -48)
      ..lineTo(0, -76)
      ..lineTo(44, -48)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFF8D402F));

    // Warm cafe window
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-26, -38, 26, 18),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFFFE082),
    );

    // Outdoor Bistro Table & Patio Umbrella on the right patio with 2 Seated Patrons!
    canvas.drawLine(
      const Offset(24, 0),
      const Offset(24, -36),
      Paint()
        ..color = const Color(0xFF3E2723)
        ..strokeWidth = 2.0,
    );
    final Path patioCanopy = Path()
      ..moveTo(4, -34)
      ..quadraticBezierTo(24, -48, 44, -34)
      ..close();
    canvas.drawPath(patioCanopy, Paint()..color = const Color(0xFFFF7043));
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(24, -13), width: 18, height: 4),
      Paint()..color = const Color(0xFFFFF8E1),
    );
    // 2 Patrons seated across from each other at the cafe table
    for (final int dir in [-1, 1]) {
      final double px = 24.0 + dir * 11.0;
      final double nod = math.sin(time * 2.8 + dir) * 1.0;
      canvas.drawCircle(
        Offset(px, -25 + nod),
        4.0,
        Paint()..color = const Color(0xFFE0A380),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(px - 4.2, -21, 8.4, 12.5),
          const Radius.circular(2.5),
        ),
        Paint()
          ..color = dir == -1
              ? const Color(0xFF26A69A)
              : const Color(0xFFAB47BC),
      );
    }

    canvas.restore();
  }

  void _drawTikiCabanaWithPeople(
    Canvas canvas,
    Size size,
    double baseY,
    double worldAngle,
  ) {
    final double? tx = _worldAngleToScreenX(worldAngle, size, margin: 400);
    if (tx == null) return;

    canvas.save();
    canvas.translate(tx, baseY);
    canvas.scale(1.90);

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 4), width: 148, height: 16),
      Paint()..color = Colors.black.withValues(alpha: 0.25),
    );

    // Warm interior bar glow
    final double glowPulse = 0.88 + 0.12 * math.sin(time * 4.0);
    canvas.drawCircle(
      const Offset(0, -36),
      48 * glowPulse,
      Paint()
        ..shader = ui.Gradient.radial(
          const Offset(0, -36),
          48 * glowPulse,
          [const Color(0xFFFF9800).withValues(alpha: 0.52), Colors.transparent],
        ),
    );

    // Bamboo posts & Illuminated Back-Bar Bottle Shelves
    final Paint postPaint = Paint()..color = const Color(0xFF6D4C41);
    canvas.drawRect(const Rect.fromLTWH(-48, -62, 6, 64), postPaint);
    canvas.drawRect(const Rect.fromLTWH(42, -62, 6, 64), postPaint);

    // Back-bar bottle shelves with colorful bottles
    canvas.drawRect(
      const Rect.fromLTWH(-32, -46, 64, 2),
      Paint()..color = const Color(0xFF4E342E),
    );
    final List<Color> bottleColors = [
      const Color(0xFF00E676),
      const Color(0xFFFFAB00),
      const Color(0xFF2979FF),
      const Color(0xFFFF1744),
      const Color(0xFF00E5FF),
    ];
    for (int b = 0; b < bottleColors.length; b++) {
      canvas.drawRect(
        Rect.fromLTWH(-26.0 + b * 12.0, -52, 3.2, 6),
        Paint()..color = bottleColors[b],
      );
    }

    // Bartender behind the counter shaking a cocktail!
    final double bartenderMove = math.sin(time * 2.2) * 4.5;
    canvas.drawCircle(
      Offset(bartenderMove, -44),
      4.6,
      Paint()..color = const Color(0xFFE0A380),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bartenderMove - 5.5, -39, 11, 13),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFD84315),
    );

    // Counter bar with vertical bamboo reed texture
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-50, -26, 100, 26),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF8D6E63),
    );
    for (int r = -44; r <= 44; r += 8) {
      canvas.drawLine(
        Offset(r.toDouble(), -25),
        Offset(r.toDouble(), -1),
        Paint()
          ..color = const Color(0xFF5D4037)
          ..strokeWidth = 1.2,
      );
    }
    canvas.drawRect(
      const Rect.fromLTWH(-54, -29, 108, 5),
      Paint()..color = const Color(0xFF4E342E),
    );

    // Colorful tropical drink glasses on the counter
    canvas.drawRect(
      const Rect.fromLTWH(-20, -34, 3.8, 5),
      Paint()..color = const Color(0xFF00E5FF),
    );
    canvas.drawRect(
      const Rect.fromLTWH(0, -34, 3.8, 5),
      Paint()..color = const Color(0xFFFFD54F),
    );
    canvas.drawRect(
      const Rect.fromLTWH(16, -34, 3.8, 5),
      Paint()..color = const Color(0xFFFF4081),
    );

    // 3 Patrons sitting on bar stools in front of the Tiki Bar chatting & raising drinks!
    final List<Color> patronColors = [
      const Color(0xFF26A69A),
      const Color(0xFF7E57C2),
      const Color(0xFFEF5350),
    ];
    for (int idx = 0; idx < 3; idx++) {
      final double sx = (idx - 1) * 24.0;
      final double nod = math.sin(time * 2.6 + idx * 1.4) * 1.3;
      // Stool
      canvas.drawLine(
        Offset(sx, -14),
        Offset(sx, 2),
        Paint()
          ..color = const Color(0xFF3E2723)
          ..strokeWidth = 2.4,
      );
      canvas.drawRect(
        Rect.fromCenter(center: Offset(sx, -14), width: 11, height: 3.2),
        Paint()..color = const Color(0xFF5D4037),
      );
      // Patron torso & head
      canvas.drawCircle(
        Offset(sx + nod * 0.5, -38),
        4.6,
        Paint()..color = const Color(0xFFE0A380),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(sx - 5.5, -33, 11, 19),
          const Radius.circular(4),
        ),
        Paint()..color = patronColors[idx],
      );
      // Arm raising drink
      final double armLift = math.sin(time * 2.2 + idx * 2) * 3.0;
      canvas.drawLine(
        Offset(sx, -28),
        Offset(sx + (idx == 0 ? 8 : -8), -32 + armLift),
        Paint()
          ..color = patronColors[idx]
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round,
      );
    }

    // Thatched Straw Roof (Layered)
    final Path thatch1 = Path()
      ..moveTo(-66, -54)
      ..lineTo(0, -94)
      ..lineTo(66, -54)
      ..close();
    canvas.drawPath(thatch1, Paint()..color = const Color(0xFFA1887F));

    final Path thatch2 = Path()
      ..moveTo(-56, -66)
      ..lineTo(0, -98)
      ..lineTo(56, -66)
      ..close();
    canvas.drawPath(thatch2, Paint()..color = const Color(0xFF8D6E63));

    // Hanging lanterns
    for (final double lx in [-28, 0, 28]) {
      canvas.drawCircle(
        Offset(lx, -51),
        3.4,
        Paint()..color = const Color(0xFFFFF176),
      );
    }

    canvas.restore();
  }

  void _drawFishermanCottage(
    Canvas canvas,
    Size size,
    double baseY,
    double worldAngle, {
    required Color wallColor,
    required Color roofColor,
    required bool hasClothesline,
  }) {
    final double? bx = _worldAngleToScreenX(worldAngle, size, margin: 320);
    if (bx == null) return;

    canvas.save();
    canvas.translate(bx, baseY);
    canvas.scale(1.85);

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 5), width: 118, height: 14),
      Paint()..color = Colors.black.withValues(alpha: 0.23),
    );

    // Stilts & deck
    final Paint wood = Paint()..color = const Color(0xFF4E342E);
    canvas.drawRect(const Rect.fromLTWH(-34, -14, 5, 18), wood);
    canvas.drawRect(const Rect.fromLTWH(29, -14, 5, 18), wood);
    canvas.drawRect(
      const Rect.fromLTWH(-44, -17, 88, 4),
      Paint()..color = const Color(0xFF6D4C41),
    );

    // Cottage body with subtle horizontal siding
    canvas.drawRect(
      const Rect.fromLTWH(-40, -62, 80, 45),
      Paint()..color = wallColor,
    );
    for (int s = 1; s < 5; s++) {
      canvas.drawLine(
        Offset(-40, -62 + s * 9.0),
        Offset(40, -62 + s * 9.0),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.14)
          ..strokeWidth = 1.0,
      );
    }

    // Roof
    final Path roof = Path()
      ..moveTo(-50, -58)
      ..lineTo(0, -90)
      ..lineTo(50, -58)
      ..close();
    canvas.drawPath(roof, Paint()..color = roofColor);

    // Glowing Windows (2 rectangular + 1 attic circular window)
    for (final double wx in [-26, 8]) {
      final Rect wRect = Rect.fromLTWH(wx, -48, 18, 16);
      canvas.drawRRect(
        RRect.fromRectAndRadius(wRect.inflate(3), const Radius.circular(3)),
        Paint()
          ..color = const Color(0xFFFFD54F).withValues(alpha: 0.32)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(wRect, const Radius.circular(2)),
        Paint()..color = const Color(0xFFFFE082),
      );
    }
    canvas.drawCircle(
      const Offset(0, -72),
      5.5,
      Paint()..color = const Color(0xFFFFE082),
    );

    // Door
    canvas.drawRect(
      const Rect.fromLTWH(-6, -44, 12, 27),
      Paint()..color = const Color(0xFF3E2723),
    );

    // Fluttering Clothesline beside the cottage if enabled!
    if (hasClothesline) {
      canvas.drawRect(const Rect.fromLTWH(56, -38, 2.5, 40), wood);
      canvas.drawLine(
        const Offset(40, -36),
        const Offset(56, -34),
        Paint()
          ..color = const Color(0xFFD7CCC8)
          ..strokeWidth = 1.0,
      );
      final double flutter = math.sin(time * 4.2 + worldAngle) * 2.0;
      canvas.drawRect(
        Rect.fromLTWH(43 + flutter * 0.3, -35, 5, 8),
        Paint()..color = const Color(0xFFFF5252),
      );
      canvas.drawRect(
        Rect.fromLTWH(50 + flutter * 0.3, -34, 4.5, 7),
        Paint()..color = const Color(0xFF29B6F6),
      );
    }

    canvas.restore();
  }

  void _drawLighthouse(
    Canvas canvas,
    Size size,
    double baseY,
    double worldAngle,
  ) {
    final double? lx = _worldAngleToScreenX(worldAngle, size, margin: 340);
    if (lx == null) return;

    canvas.save();
    canvas.translate(lx, baseY);
    canvas.scale(1.75);

    // Rocky headland under lighthouse
    final Path cliff = Path()
      ..moveTo(-68, 5)
      ..quadraticBezierTo(-32, -18, 0, -15)
      ..quadraticBezierTo(38, -12, 62, 5)
      ..close();
    canvas.drawPath(cliff, Paint()..color = const Color(0xFF372538));

    // Small keeper's cottage next to the lighthouse tower
    canvas.drawRect(
      const Rect.fromLTWH(10, -32, 28, 18),
      Paint()..color = const Color(0xFFCFD8DC),
    );
    final Path keeperRoof = Path()
      ..moveTo(7, -32)
      ..lineTo(24, -44)
      ..lineTo(41, -32)
      ..close();
    canvas.drawPath(keeperRoof, Paint()..color = const Color(0xFFB71C1C));
    canvas.drawRect(
      const Rect.fromLTWH(18, -26, 8, 7),
      Paint()..color = const Color(0xFFFFE082),
    );

    // Tower body
    final Path tower = Path()
      ..moveTo(-11, -12)
      ..lineTo(-7, -78)
      ..lineTo(7, -78)
      ..lineTo(11, -12)
      ..close();
    canvas.drawPath(tower, Paint()..color = const Color(0xFFECEFF1));

    // Red stripes
    final Path stripe1 = Path()
      ..moveTo(-9.5, -34)
      ..lineTo(-8.5, -50)
      ..lineTo(8.5, -50)
      ..lineTo(9.5, -34)
      ..close();
    canvas.drawPath(stripe1, Paint()..color = const Color(0xFFD32F2F));

    // Lantern room & dome
    canvas.drawRect(
      const Rect.fromLTWH(-8, -87, 16, 9),
      Paint()..color = const Color(0xFF263238),
    );
    canvas.drawCircle(
      const Offset(0, -82),
      5,
      Paint()..color = const Color(0xFFFFF59D),
    );

    // Rotating lighthouse beam
    final double beamSweep = math.sin(time * 1.4);
    final double beamLength = 150.0 * beamSweep.abs();
    final double dir = beamSweep >= 0 ? 1.0 : -1.0;

    final Path beam = Path()
      ..moveTo(0, -82)
      ..lineTo(dir * beamLength, -100)
      ..lineTo(dir * beamLength, -64)
      ..close();

    canvas.drawPath(
      beam,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, -82),
          Offset(dir * (beamLength + 1), -82),
          [
            const Color(0xFFFFF59D).withValues(alpha: 0.48),
            Colors.transparent,
          ],
        ),
    );

    canvas.restore();
  }

  void _drawMainCampfireWithPeople(
    Canvas canvas,
    Size size,
    double baseY,
    double worldAngle,
  ) {
    final double? fx = _worldAngleToScreenX(worldAngle, size, margin: 460);
    if (fx == null) return;

    canvas.save();
    canvas.translate(fx, baseY);
    canvas.scale(1.90);

    // 1. Multi-stage warm ground illumination pool on the sand
    final double pulse = 0.92 + 0.08 * math.sin(time * 7.5);
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0, 5),
        width: 245 * pulse,
        height: 58 * pulse,
      ),
      Paint()
        ..shader = ui.Gradient.radial(
          const Offset(0, 0),
          120 * pulse,
          [
            const Color(0xFFFF6D00).withValues(alpha: 0.60),
            const Color(0xFFFFAB40).withValues(alpha: 0.25),
            Colors.transparent,
          ],
          [0.0, 0.55, 1.0],
        ),
    );

    // Flanking Bamboo Tiki Torches on Left (-94) & Right (+96) of the Bonfire Camp!
    for (final double tikiX in [-94.0, 96.0]) {
      canvas.drawLine(
        Offset(tikiX, 4),
        Offset(tikiX, -38),
        Paint()
          ..color = const Color(0xFF795548)
          ..strokeWidth = 2.6,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(tikiX, -40), width: 6, height: 8),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFF4E342E),
      );
      final double tf = math.sin(time * 8.0 + tikiX) * 2.0;
      final Path tFlame = Path()
        ..moveTo(tikiX - 3.5, -44)
        ..quadraticBezierTo(tikiX - 1.5, -53, tikiX + tf, -56)
        ..quadraticBezierTo(tikiX + 2.5, -51, tikiX + 3.5, -44)
        ..close();
      canvas.drawPath(tFlame, Paint()..color = const Color(0xFFFFAB00));
    }

    // 2. Sculpted Driftwood Log Benches with wood end-grain rings, beach blanket & red cooler box!
    final Paint benchPaint = Paint()..color = const Color(0xFF5D4037);
    final Paint barkShadow = Paint()..color = const Color(0xFF3E2723);
    // Left driftwood bench
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-76, -3, 46, 10),
        const Radius.circular(5),
      ),
      benchPaint,
    );
    canvas.drawCircle(const Offset(-74, 2), 4.2, barkShadow);
    // Right driftwood bench
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(30, -3, 48, 10),
        const Radius.circular(5),
      ),
      benchPaint,
    );
    canvas.drawCircle(const Offset(76, 2), 4.2, barkShadow);

    // Vintage Red & White Beach Cooler Box beside the left bench!
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-89, -4, 13, 10),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFFD32F2F),
    );
    canvas.drawRect(
      const Rect.fromLTWH(-90, -6, 15, 2.5),
      Paint()..color = const Color(0xFFFFF8E1),
    );

    // Striped woven beach blanket on the sand to the right of the fire
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(56, 3, 36, 11),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF00897B).withValues(alpha: 0.85),
    );

    // 3. 7 Detailed People Sitting & Standing around the Bonfire Chatting & Playing Music!
    // --- Person 1 (Back-Left Standing, holding a warm drink mug & chatting with Person 2) ---
    final double sway1 = math.sin(time * 1.8) * 1.4;
    _drawCampfirePerson(
      canvas,
      pos: Offset(-68 + sway1, -5),
      headOffset: const Offset(1.2, 0.4),
      bodyColor: const Color(0xFF5C6BC0),
      hairColor: const Color(0xFF3E2723),
      rimLightOnRight: true,
      armTarget: Offset(-54 + sway1, -24),
      isSitting: false,
      hasDrinkCup: true,
      hasHat: true,
    );

    // --- Person 2 (Back-Center-Left Standing, toasting drink & laughing) ---
    final double nod2 = math.sin(time * 3.4) * 1.3;
    _drawCampfirePerson(
      canvas,
      pos: const Offset(-26, -7),
      headOffset: Offset(0.8, nod2),
      bodyColor: const Color(0xFFAD1457),
      hairColor: const Color(0xFF1A0F14),
      rimLightOnRight: true,
      armTarget: Offset(-15, -25 + nod2),
      isSitting: false,
      hasDrinkCup: true,
      isSpeaking: math.sin(time * 1.6) > 0.2,
    );

    // --- Person 3 (Left Log Outer, Sitting & Expressively Telling a Story!) ---
    final double nod3 = math.sin(time * 3.2) * 1.5;
    final double gesture3 = math.sin(time * 4.5) * 5.0;
    _drawCampfirePerson(
      canvas,
      pos: const Offset(-56, 0),
      headOffset: Offset(1.4, nod3),
      bodyColor: const Color(0xFFE65100),
      hairColor: const Color(0xFF2B1912),
      rimLightOnRight: true,
      armTarget: Offset(-38, -16 + gesture3),
      isSitting: true,
      isSpeaking: math.sin(time * 1.6) <= 0.2,
    );

    // --- Person 4 (Left Log Inner, Sitting & Roasting a Marshmallow over the flames!) ---
    final double nod4 = math.cos(time * 2.7) * 1.2;
    _drawCampfirePerson(
      canvas,
      pos: const Offset(-38, 1),
      headOffset: Offset(1.0, nod4),
      bodyColor: const Color(0xFF00838F),
      hairColor: const Color(0xFF4E342E),
      rimLightOnRight: true,
      armTarget: Offset(-20, -13 + nod4 * 0.5),
      isSitting: true,
      hasRoastingStick: true,
    );

    // --- Person 5 (Right Log Inner, Playing Acoustic Guitar & Singing!) ---
    final double guitarSway = math.sin(time * 3.0) * 1.8;
    _drawCampfirePerson(
      canvas,
      pos: Offset(40 + guitarSway * 0.4, 0),
      headOffset: Offset(-1.2, guitarSway * 0.6),
      bodyColor: const Color(0xFF2E7D32),
      hairColor: const Color(0xFF261815),
      rimLightOnRight: false,
      armTarget: Offset(33, -12 + math.sin(time * 9.5) * 2.2),
      isSitting: true,
      hasGuitar: true,
      hasHat: true,
    );

    // --- Person 6 & Person 7 (Couple sitting together on the right log/blanket leaning in!) ---
    final double nod6 = math.sin(time * 2.5 + 1.2) * 1.2;
    _drawCampfirePerson(
      canvas,
      pos: const Offset(58, 1),
      headOffset: Offset(-1.2, nod6),
      bodyColor: const Color(0xFF8E24AA),
      hairColor: const Color(0xFF1B1118),
      rimLightOnRight: false,
      armTarget: Offset(45, -14 - nod6),
      isSitting: true,
    );
    _drawCampfirePerson(
      canvas,
      pos: const Offset(73, 2),
      headOffset: Offset(-1.5, nod6 * 0.8),
      bodyColor: const Color(0xFFD84315),
      hairColor: const Color(0xFF3E2723),
      rimLightOnRight: false,
      armTarget: const Offset(60, -13),
      isSitting: true,
      isSpeaking: math.cos(time * 1.9) > 0.4,
    );

    // Friendly Beach Dog relaxing near the campfire at (-18, 9) wagging its tail!
    final double tailWag = math.sin(time * 8.0) * 2.5;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-20, 9), width: 14, height: 6.5),
      Paint()..color = const Color(0xFFA16642),
    );
    canvas.drawCircle(
      const Offset(-13, 6),
      3.5,
      Paint()..color = const Color(0xFFA16642),
    );
    canvas.drawLine(
      const Offset(-26, 8),
      Offset(-31, 4 + tailWag),
      Paint()
        ..color = const Color(0xFF8D5535)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );

    // 4. Detailed Campfire Stone Ring, Glowing Red-Orange Coal Bed & Crossed Logs
    final Paint logPaint = Paint()
      ..color = const Color(0xFF3E2723)
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(-20, 6), const Offset(18, -3), logPaint);
    canvas.drawLine(const Offset(-17, -3), const Offset(20, 6), logPaint);
    canvas.drawLine(const Offset(-6, 7), const Offset(6, -5), logPaint);

    // Glowing red-orange ember bed under the flames
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 4), width: 32, height: 9),
      Paint()
        ..color = const Color(0xFFFF3D00).withValues(alpha: 0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Ring of coastal stones around the fire pit
    for (int st = -4; st <= 4; st++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(st * 5.6, 7.8 + (st.abs() % 2) * 1.4),
          width: 6.8,
          height: 5.0,
        ),
        Paint()
          ..color = st.isEven
              ? const Color(0xFF455A64)
              : const Color(0xFF607D8B),
      );
    }

    // 5. 5-Layer Roaring Animated Dancing Flames with Lick Tongues!
    for (int i = 0; i < 5; i++) {
      final double sway = math.sin(time * (7.5 + i * 1.8) + i) * 5.5;
      final double fh =
          (34.0 - i * 5.2) * (0.86 + 0.14 * math.cos(time * 9.0 + i));
      final double fw = 18.0 - i * 2.8;

      final Path flame = Path()
        ..moveTo(-fw, 3)
        ..quadraticBezierTo(-fw * 0.55, -fh * 0.55, sway, -fh)
        ..quadraticBezierTo(fw * 0.55, -fh * 0.55, fw, 3)
        ..close();

      final Color fColor = switch (i) {
        0 => const Color(0xFFD50000),
        1 => const Color(0xFFFF3D00),
        2 => const Color(0xFFFF9100),
        3 => const Color(0xFFFFD600),
        _ => const Color(0xFFFFF9C4),
      };
      canvas.drawPath(flame, Paint()..color = fColor.withValues(alpha: 0.92));
    }

    // 6. 18 Rising Glowing Embers & Floating Musical Notes from the Guitar!
    for (int i = 0; i < 18; i++) {
      final double sparkProgress =
          ((time * (0.55 + (i % 4) * 0.18) + i * 0.11) % 1.0);
      final double sx = math.sin(sparkProgress * 8.0 + i) * 18.0;
      final double sy = -18.0 - sparkProgress * 72.0;
      final double alpha = (1.0 - sparkProgress).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(sx, sy),
        1.4 + (i % 2) * 0.6,
        Paint()..color = const Color(0xFFFFCC80).withValues(alpha: alpha),
      );
    }

    // Floating musical note particles rising above the guitarist (Person 5 at x=40)
    for (int n = 0; n < 2; n++) {
      final double np = ((time * 0.45 + n * 0.5) % 1.0);
      final double nx = 36.0 + math.sin(time * 2.5 + n) * 8.0;
      final double ny = -34.0 - np * 26.0;
      final double nAlpha = math.sin(np * math.pi).clamp(0.0, 1.0) * 0.85;
      final Paint notePaint = Paint()
        ..color = const Color(0xFFFFF59D).withValues(alpha: nAlpha)
        ..strokeWidth = 1.4;
      canvas.drawCircle(Offset(nx, ny), 2.2, notePaint);
      canvas.drawLine(Offset(nx + 2, ny), Offset(nx + 2, ny - 7), notePaint);
      canvas.drawLine(
        Offset(nx + 2, ny - 7),
        Offset(nx + 5, ny - 5.5),
        notePaint,
      );
    }

    canvas.restore();
  }

  void _drawCampfirePerson(
    Canvas canvas, {
    required Offset pos,
    required Offset headOffset,
    required Color bodyColor,
    required bool rimLightOnRight,
    required Offset armTarget,
    required bool isSitting,
    Color hairColor = const Color(0xFF1F1219),
    bool hasGuitar = false,
    bool hasRoastingStick = false,
    bool hasDrinkCup = false,
    bool hasHat = false,
    bool isSpeaking = false,
  }) {
    final double torsoTop = isSitting ? pos.dy - 24.0 : pos.dy - 33.0;
    final double torsoHeight = isSitting ? 19.0 : 21.0;
    final Offset headCenter = Offset(
      pos.dx + headOffset.dx,
      torsoTop - 6.8 + headOffset.dy,
    );

    // 1. Cast shadow away from the fire
    final double shadowDir = rimLightOnRight ? -1.0 : 1.0;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(pos.dx + shadowDir * 12, pos.dy + 5),
        width: 26,
        height: 7,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.32),
    );

    // 2. Articulated Legs (Thigh -> Knee -> Calf -> Shoe)
    final Paint pantPaint = Paint()
      ..color = const Color(0xFF1E2733)
      ..strokeWidth = 3.8
      ..strokeCap = StrokeCap.round;
    final Paint shoePaint = Paint()..color = const Color(0xFF3E2723);

    if (isSitting) {
      final double dir = rimLightOnRight ? 1.0 : -1.0;
      final Offset hip = Offset(pos.dx, pos.dy - 5);
      final Offset knee = Offset(pos.dx + dir * 8.5, pos.dy - 4.5);
      final Offset foot = Offset(pos.dx + dir * 10.5, pos.dy + 4.5);
      canvas.drawLine(hip, knee, pantPaint);
      canvas.drawLine(knee, foot, pantPaint);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(foot.dx + dir * 2.0, foot.dy),
          width: 6.0,
          height: 3.2,
        ),
        shoePaint,
      );
    } else {
      canvas.drawLine(
        Offset(pos.dx - 3.0, pos.dy - 12),
        Offset(pos.dx - 3.5, pos.dy + 4),
        pantPaint,
      );
      canvas.drawLine(
        Offset(pos.dx + 3.0, pos.dy - 12),
        Offset(pos.dx + 3.5, pos.dy + 4),
        pantPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(pos.dx - 3.5, pos.dy + 5), width: 5.5, height: 3),
        shoePaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(pos.dx + 3.5, pos.dy + 5), width: 5.5, height: 3),
        shoePaint,
      );
    }

    // 3. Sculpted Torso Jacket/Shirt with Collar & Warm Firelight Rim
    final RRect torsoRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(pos.dx, torsoTop + torsoHeight * 0.5),
        width: 13.5,
        height: torsoHeight,
      ),
      const Radius.circular(5.5),
    );
    canvas.drawRRect(torsoRect, Paint()..color = bodyColor);

    // Warm firelight rim on the side facing the fire
    final Paint rimPaint = Paint()
      ..color = const Color(0xFFFFAB40).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final double rimX = pos.dx + (rimLightOnRight ? 5.8 : -5.8);
    canvas.drawLine(
      Offset(rimX, torsoTop + 2.5),
      Offset(rimX, torsoTop + torsoHeight - 2.5),
      rimPaint,
    );

    // 4. Neck, Warm Skin-Toned Head, Hair & Optional Sun/Beanie Hat
    canvas.drawLine(
      Offset(pos.dx, torsoTop),
      Offset(headCenter.dx, headCenter.dy + 3),
      Paint()
        ..color = const Color(0xFFD79975)
        ..strokeWidth = 3.2,
    );
    // Head base
    canvas.drawCircle(
      headCenter,
      5.5,
      Paint()..color = const Color(0xFFE0A380),
    );
    // Hair / Cap on top and back of head
    canvas.drawArc(
      Rect.fromCircle(center: headCenter, radius: 5.8),
      rimLightOnRight ? math.pi * 0.55 : -math.pi * 0.35,
      math.pi * 1.35,
      true,
      Paint()..color = hairColor,
    );
    if (hasHat) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(headCenter.dx, headCenter.dy - 4.5),
          width: 15,
          height: 4.0,
        ),
        Paint()..color = const Color(0xFFD7CCC8),
      );
    }
    // Warm fire glow arc on the face
    canvas.drawArc(
      Rect.fromCircle(center: headCenter, radius: 5.4),
      rimLightOnRight ? -math.pi * 0.38 : math.pi * 0.62,
      math.pi * 0.76,
      false,
      rimPaint..strokeWidth = 1.6,
    );

    // 5. Acoustic Guitar if guitar player
    if (hasGuitar) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(pos.dx - 5, torsoTop + 11),
          width: 16,
          height: 10,
        ),
        Paint()..color = const Color(0xFFD87A3E),
      );
      canvas.drawCircle(
        Offset(pos.dx - 5, torsoTop + 11),
        2.5,
        Paint()..color = const Color(0xFF3E2723),
      );
      canvas.drawLine(
        Offset(pos.dx - 5, torsoTop + 11),
        Offset(pos.dx - 17, torsoTop + 5),
        Paint()
          ..color = const Color(0xFF4E342E)
          ..strokeWidth = 2.5,
      );
    }

    // 6. Articulated Arm (Shoulder -> Elbow -> Hand)
    final Offset shoulder = Offset(pos.dx, torsoTop + 4.5);
    final Offset elbow = Offset(
      (shoulder.dx + armTarget.dx) * 0.5 + (rimLightOnRight ? -2.0 : 2.0),
      (shoulder.dy + armTarget.dy) * 0.5 + 3.5,
    );
    final Paint sleevePaint = Paint()
      ..color = Color.lerp(bodyColor, Colors.white, 0.14)!
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(shoulder, elbow, sleevePaint);
    canvas.drawLine(elbow, armTarget, sleevePaint);
    // Warm hand at armTarget
    canvas.drawCircle(
      armTarget,
      2.2,
      Paint()..color = const Color(0xFFE0A380),
    );

    // 7. Held Props: Marshmallow Roasting Stick or Warm Mug!
    if (hasRoastingStick) {
      final Offset stickTip = Offset(armTarget.dx + 14, armTarget.dy - 3);
      canvas.drawLine(
        armTarget,
        stickTip,
        Paint()
          ..color = const Color(0xFF8D6E63)
          ..strokeWidth = 1.4,
      );
      // Glowing toasted marshmallow at the tip of the stick!
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: stickTip, width: 4.5, height: 3.5),
          const Radius.circular(1.5),
        ),
        Paint()..color = const Color(0xFFFFF8E1),
      );
    }
    if (hasDrinkCup) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(armTarget.dx, armTarget.dy - 2.5),
            width: 4.2,
            height: 5.0,
          ),
          const Radius.circular(1.2),
        ),
        Paint()..color = const Color(0xFFFFCC80),
      );
    }

    // 8. Subtle Animated Conversation Indicator ("•••") above active speaker
    if (isSpeaking) {
      final double bubbleBob = math.sin(time * 4.0) * 1.5;
      final Offset bubbleCenter = Offset(
        headCenter.dx + (rimLightOnRight ? 6 : -6),
        headCenter.dy - 12 + bubbleBob,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: bubbleCenter, width: 13, height: 7),
          const Radius.circular(3.5),
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.72),
      );
      for (int d = -1; d <= 1; d++) {
        canvas.drawCircle(
          Offset(bubbleCenter.dx + d * 3.2, bubbleCenter.dy),
          1.0,
          Paint()..color = const Color(0xFF3E2723),
        );
      }
    }
  }

  void _drawCozyCoveCampfireWithCouple(
    Canvas canvas,
    Size size,
    double baseY,
    double worldAngle,
  ) {
    final double? fx = _worldAngleToScreenX(worldAngle, size, margin: 320);
    if (fx == null) return;

    canvas.save();
    canvas.translate(fx, baseY);
    canvas.scale(1.85);

    final double pulse = 0.90 + 0.10 * math.sin(time * 6.5 + 1.0);
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0, 3),
        width: 145 * pulse,
        height: 34 * pulse,
      ),
      Paint()
        ..shader = ui.Gradient.radial(
          const Offset(0, 0),
          72 * pulse,
          [
            const Color(0xFFFF7043).withValues(alpha: 0.48),
            Colors.transparent,
          ],
        ),
    );

    // 3 Detailed People sitting & standing together by the cove fire chatting!
    final double nodA = math.sin(time * 2.5) * 1.3;
    _drawCampfirePerson(
      canvas,
      pos: const Offset(-30, 0),
      headOffset: Offset(1.2, nodA),
      bodyColor: const Color(0xFF8E24AA),
      rimLightOnRight: true,
      armTarget: Offset(-16, -13 + nodA),
      isSitting: true,
      isSpeaking: math.sin(time * 1.4) > 0.0,
    );
    _drawCampfirePerson(
      canvas,
      pos: const Offset(30, 0),
      headOffset: Offset(-1.2, -nodA),
      bodyColor: const Color(0xFF00897B),
      rimLightOnRight: false,
      armTarget: Offset(16, -13 - nodA),
      isSitting: true,
      hasDrinkCup: true,
    );
    _drawCampfirePerson(
      canvas,
      pos: const Offset(46, -4),
      headOffset: Offset(-1.0, nodA * 0.6),
      bodyColor: const Color(0xFFE65100),
      rimLightOnRight: false,
      armTarget: const Offset(34, -20),
      isSitting: false,
      hasHat: true,
    );

    // Logs, Stone Ring & Flame
    final Paint logPaint = Paint()
      ..color = const Color(0xFF3E2723)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(-14, 4), const Offset(14, -2), logPaint);
    canvas.drawLine(const Offset(-12, -2), const Offset(14, 4), logPaint);

    for (int i = 0; i < 4; i++) {
      final double sway = math.sin(time * 7.5 + i) * 4.0;
      final double fh = 24.0 - i * 4.2;
      final double fw = 12.0 - i * 2.2;
      final Path flame = Path()
        ..moveTo(-fw, 2)
        ..quadraticBezierTo(-fw * 0.45, -fh * 0.6, sway, -fh)
        ..quadraticBezierTo(fw * 0.45, -fh * 0.6, fw, 2)
        ..close();
      canvas.drawPath(
        flame,
        Paint()
          ..color = (i == 0
                  ? const Color(0xFFFF3D00)
                  : (i == 1
                        ? const Color(0xFFFF9100)
                        : (i == 2
                              ? const Color(0xFFFFD600)
                              : const Color(0xFFFFF59D))))
              .withValues(alpha: 0.92),
      );
    }

    canvas.restore();
  }

  void _drawPalmTrees(Canvas canvas, Size size, double horizonY) {
    final double groundHeight = size.height - horizonY;

    // 18 Large Midground & Foreground Palm Trees around the shore and village (Scaled 1.28x - 1.85x!)
    final List<Map<String, double>> palms = [
      {'angle': 48.0, 'yFactor': 0.18, 'scale': 1.28, 'lean': -0.28},
      {'angle': 58.0, 'yFactor': 0.21, 'scale': 1.42, 'lean': -0.22},
      {'angle': 68.0, 'yFactor': 0.24, 'scale': 1.52, 'lean': -0.18},
      {'angle': 92.0, 'yFactor': 0.28, 'scale': 1.75, 'lean': -0.16},
      {'angle': 108.0, 'yFactor': 0.26, 'scale': 1.64, 'lean': 0.14},
      {'angle': 124.0, 'yFactor': 0.23, 'scale': 1.50, 'lean': -0.12},
      {'angle': 138.0, 'yFactor': 0.22, 'scale': 1.46, 'lean': 0.16},
      {'angle': 154.0, 'yFactor': 0.26, 'scale': 1.80, 'lean': 0.22},
      {'angle': 172.0, 'yFactor': 0.22, 'scale': 1.48, 'lean': -0.15},
      {'angle': 186.0, 'yFactor': 0.24, 'scale': 1.56, 'lean': 0.12},
      {'angle': 200.0, 'yFactor': 0.23, 'scale': 1.52, 'lean': -0.14},
      {'angle': 215.0, 'yFactor': 0.29, 'scale': 1.85, 'lean': -0.20},
      {'angle': 234.0, 'yFactor': 0.23, 'scale': 1.50, 'lean': 0.18},
      {'angle': 248.0, 'yFactor': 0.25, 'scale': 1.62, 'lean': 0.24},
      {'angle': 262.0, 'yFactor': 0.22, 'scale': 1.44, 'lean': -0.18},
      {'angle': 276.0, 'yFactor': 0.20, 'scale': 1.36, 'lean': 0.26},
      {'angle': 298.0, 'yFactor': 0.19, 'scale': 1.26, 'lean': -0.22},
      {'angle': 320.0, 'yFactor': 0.21, 'scale': 1.32, 'lean': 0.20},
    ];

    // Draw a large hammock strung between the palms at 92° and 108°!
    _drawHammockBetweenPalms(canvas, size, horizonY, 92.0, 108.0);

    for (int i = 0; i < palms.length; i++) {
      final p = palms[i];
      final double angle = p['angle']!;
      final double? px = _worldAngleToScreenX(angle, size, margin: 420);
      if (px == null) continue;

      final double py = horizonY + groundHeight * p['yFactor']!;
      final double scale = p['scale']!;
      final double lean = p['lean']!;

      // Tropical bushes at the base of the palm trees
      _drawTropicalBush(canvas, Offset(px + 12 * scale, py + 2), scale);
      _drawSinglePalmTree(canvas, Offset(px, py), scale, lean, i);
    }
  }

  void _drawHammockBetweenPalms(
    Canvas canvas,
    Size size,
    double horizonY,
    double angle1,
    double angle2,
  ) {
    final double? x1 = _worldAngleToScreenX(angle1, size, margin: 360);
    final double? x2 = _worldAngleToScreenX(angle2, size, margin: 360);
    if (x1 == null || x2 == null) return;

    final double groundHeight = size.height - horizonY;
    final double y1 = horizonY + groundHeight * 0.28 - 54;
    final double y2 = horizonY + groundHeight * 0.26 - 50;
    final double sway = math.sin(time * 1.9) * 5.0;
    final double midX = (x1 + x2) * 0.5;
    final double midY = (y1 + y2) * 0.5 + 26.0 + sway;

    // Person relaxing inside the hammock with a straw hat (1.65x scale)
    canvas.drawCircle(
      Offset(midX - 13, midY - 7),
      6.8,
      Paint()..color = const Color(0xFFE0A380),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(midX - 13, midY - 11.5),
        width: 22,
        height: 6.2,
      ),
      Paint()..color = const Color(0xFFFFE082),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(midX + 3, midY - 2),
          width: 28,
          height: 11,
        ),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFF26A69A),
    );

    final Path hammock = Path()
      ..moveTo(x1, y1)
      ..quadraticBezierTo(midX, midY, x2, y2)
      ..quadraticBezierTo(midX, midY + 16.0, x1, y1);

    canvas.drawPath(
      hammock,
      Paint()..color = const Color(0xFFFFCC80).withValues(alpha: 0.94),
    );
    canvas.drawPath(
      hammock,
      Paint()
        ..color = const Color(0xFFD84315)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
  }

  void _drawTropicalBush(Canvas canvas, Offset pos, double scale) {
    final Paint bushPaint = Paint()..color = const Color(0xFF1E4635);
    canvas.drawOval(
      Rect.fromCenter(center: pos, width: 32 * scale, height: 16 * scale),
      bushPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: pos.translate(-10 * scale, 2 * scale),
        width: 24 * scale,
        height: 13 * scale,
      ),
      Paint()..color = const Color(0xFF285943),
    );
    // Tropical hibiscus blossoms on the bush
    if (scale > 0.85) {
      canvas.drawCircle(
        pos.translate(-4 * scale, -2 * scale),
        2.5 * scale,
        Paint()..color = const Color(0xFFFF5252),
      );
      canvas.drawCircle(
        pos.translate(6 * scale, 1 * scale),
        2.3 * scale,
        Paint()..color = const Color(0xFFFFAB40),
      );
    }
  }

  void _drawSinglePalmTree(
    Canvas canvas,
    Offset base,
    double scale,
    double lean,
    int seed,
  ) {
    final double windSway =
        math.sin(time * 1.6 + seed * 1.3) * 8.0 * scale +
        math.cos(time * 2.9 + seed) * 3.0 * scale;

    final double trunkHeight = 148.0 * scale;
    final Offset top = Offset(
      base.dx + lean * 75.0 * scale + windSway,
      base.dy - trunkHeight,
    );
    final Offset ctrl = Offset(
      base.dx + lean * 28.0 * scale + windSway * 0.4,
      base.dy - trunkHeight * 0.52,
    );

    // Shadow on the beach sand
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(base.dx + lean * 20 * scale, base.dy + 4),
        width: 66 * scale,
        height: 12 * scale,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.23),
    );

    // Curved Trunk
    final Path trunkPath = Path()
      ..moveTo(base.dx - 7.2 * scale, base.dy)
      ..quadraticBezierTo(
        ctrl.dx - 4.2 * scale,
        ctrl.dy,
        top.dx - 2.6 * scale,
        top.dy,
      )
      ..lineTo(top.dx + 2.6 * scale, top.dy)
      ..quadraticBezierTo(
        ctrl.dx + 4.2 * scale,
        ctrl.dy,
        base.dx + 7.2 * scale,
        base.dy,
      )
      ..close();

    final Paint trunkPaint = Paint()
      ..shader = ui.Gradient.linear(
        base,
        top,
        [const Color(0xFF3E2723), const Color(0xFF6D4C41)],
      );
    canvas.drawPath(trunkPath, trunkPaint);

    // Detailed Bark Ring Notches along the curved trunk
    final Paint ringPaint = Paint()
      ..color = const Color(0xFF271714).withValues(alpha: 0.55)
      ..strokeWidth = 1.2 * scale;
    for (int r = 1; r <= 11; r++) {
      final double t = r / 12.0;
      final double rx =
          (1 - t) * (1 - t) * base.dx +
          2 * (1 - t) * t * ctrl.dx +
          t * t * top.dx;
      final double ry =
          (1 - t) * (1 - t) * base.dy +
          2 * (1 - t) * t * ctrl.dy +
          t * t * top.dy;
      final double halfW = (6.5 * (1.0 - t * 0.55)) * scale;
      canvas.drawLine(
        Offset(rx - halfW, ry),
        Offset(rx + halfW, ry),
        ringPaint,
      );
    }

    // Coconuts clustered under the crown
    final Paint treeCoconutPaint = Paint()..color = const Color(0xFF3E2723);
    canvas.drawCircle(
      top.translate(-4 * scale, 5 * scale),
      4.8 * scale,
      treeCoconutPaint,
    );
    canvas.drawCircle(
      top.translate(4 * scale, 4 * scale),
      4.5 * scale,
      treeCoconutPaint,
    );
    canvas.drawCircle(
      top.translate(0, 8 * scale),
      4.5 * scale,
      treeCoconutPaint,
    );

    // Swaying Palm Fronds with Center Rib & Feather Leaflets
    final List<double> frondAngles = [
      -2.6,
      -2.0,
      -1.4,
      -0.6,
      0.0,
      0.6,
      1.3,
      2.0,
      2.6,
    ];
    for (int f = 0; f < frondAngles.length; f++) {
      final double baseAngle = frondAngles[f];
      final double frondFlutter =
          math.sin(time * 2.4 + seed + f * 0.9) * 0.08;
      final double fAngle = baseAngle + frondFlutter;

      final double frondLen = (60.0 + (f % 3) * 10.0) * scale;
      final Offset tip = Offset(
        top.dx + math.sin(fAngle) * frondLen,
        top.dy -
            math.cos(fAngle) * frondLen * 0.45 +
            (fAngle.abs() * 14.0 * scale),
      );
      final Offset mid = Offset(
        (top.dx + tip.dx) * 0.5,
        math.min(top.dy, tip.dy) - 18.0 * scale,
      );

      final Path frond = Path()
        ..moveTo(top.dx, top.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, tip.dx, tip.dy)
        ..quadraticBezierTo(mid.dx, mid.dy + 12.0 * scale, top.dx, top.dy)
        ..close();

      final Color frondColor = f.isEven
          ? const Color(0xFF1E4D3B)
          : const Color(0xFF2B684C);
      canvas.drawPath(frond, Paint()..color = frondColor);

      // Sunlit center rib spine along each palm frond
      if (scale >= 0.75) {
        final Path spine = Path()
          ..moveTo(top.dx, top.dy)
          ..quadraticBezierTo(mid.dx, mid.dy + 2.0 * scale, tip.dx, tip.dy);
        canvas.drawPath(
          spine,
          Paint()
            ..color = const Color(0xFF558B2F).withValues(alpha: 0.55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.1 * scale,
        );
      }
    }
  }

  void _drawBeachDetailsAndCrabs(Canvas canvas, Size size, double horizonY) {
    final double groundHeight = size.height - horizonY;

    // 1. 4 Large Striped Beach Umbrellas, Lounger Chairs & Sunbathers (~84°, ~100°, ~216°, ~274°)
    _drawBeachUmbrellaAndTowel(
      canvas,
      size,
      horizonY + groundHeight * 0.35,
      84.0,
      const Color(0xFFE53935),
      hasSunbather: true,
    );
    _drawBeachUmbrellaAndTowel(
      canvas,
      size,
      horizonY + groundHeight * 0.33,
      100.0,
      const Color(0xFFFFB300),
      hasSunbather: false,
    );
    _drawBeachUmbrellaAndTowel(
      canvas,
      size,
      horizonY + groundHeight * 0.36,
      216.0,
      const Color(0xFF1E88E5),
      hasSunbather: true,
    );
    _drawBeachUmbrellaAndTowel(
      canvas,
      size,
      horizonY + groundHeight * 0.32,
      274.0,
      const Color(0xFF00897B),
      hasSunbather: true,
    );

    // 1b. Large Beach Volleyball Net, Court & 2 Active Players at ~106°
    _drawBeachVolleyballNet(
      canvas,
      size,
      horizonY + groundHeight * 0.31,
      106.0,
    );

    // 1c. 2 Large Detailed Sandcastles with Red Flags, Buckets & Beach Balls at ~94° and ~198°
    _drawSandcastleAndBall(
      canvas,
      size,
      horizonY + groundHeight * 0.44,
      94.0,
    );
    _drawSandcastleAndBall(
      canvas,
      size,
      horizonY + groundHeight * 0.45,
      198.0,
    );

    // 2. Large Surfboards stuck in the sand at ~103°, ~150° and ~234°
    for (final map in [
      {'angle': 103.0, 'color': const Color(0xFFFF7043)},
      {'angle': 150.0, 'color': const Color(0xFF26C6DA)},
      {'angle': 234.0, 'color': const Color(0xFFAB47BC)},
    ]) {
      final double? sbx = _worldAngleToScreenX(
        map['angle'] as double,
        size,
        margin: 160,
      );
      if (sbx != null) {
        final double sby = horizonY + groundHeight * 0.32;
        canvas.save();
        canvas.translate(sbx, sby);
        canvas.scale(1.68);
        canvas.rotate(0.18);
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(0, -26), width: 18, height: 64),
          Paint()..color = map['color'] as Color,
        );
        canvas.drawRect(
          Rect.fromCenter(center: const Offset(0, -26), width: 4, height: 60),
          Paint()..color = const Color(0xFFFFF8E1),
        );
        canvas.restore();
      }
    }

    // 3. Large Rustic Wooden Directional Signpost at ~112°
    final double? signX = _worldAngleToScreenX(112.0, size, margin: 160);
    if (signX != null) {
      final double signY = horizonY + groundHeight * 0.33;
      canvas.save();
      canvas.translate(signX, signY);
      canvas.scale(1.75);
      canvas.drawRect(
        const Rect.fromLTWH(-2.5, -46, 5, 48),
        Paint()..color = const Color(0xFF4E342E),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-22, -42, 44, 9),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFF8D6E63),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-18, -30, 38, 9),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFF6D4C41),
      );
      canvas.restore();
    }

    // 4. Large Coastal Rock Clusters & Driftwood Logs along the Beach
    for (final double rockAngle in [14.0, 58.0, 140.0, 210.0, 280.0, 330.0]) {
      final double? rx = _worldAngleToScreenX(rockAngle, size, margin: 140);
      if (rx == null) continue;
      final double ry = horizonY + groundHeight * 0.50;
      canvas.save();
      canvas.translate(rx, ry);
      canvas.scale(1.80);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 28, height: 12),
        Paint()..color = const Color(0xFF455A64),
      );
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(12, 3), width: 18, height: 9),
        Paint()..color = const Color(0xFF37474F),
      );
      canvas.restore();
    }

    // 5. 24 Larger Starfish & Seashells scattered around the foreground sand
    final List<Map<String, double>> shells = [
      {'angle': 12.0, 'yFactor': 0.58},
      {'angle': 28.0, 'yFactor': 0.63},
      {'angle': 42.0, 'yFactor': 0.54},
      {'angle': 64.0, 'yFactor': 0.59},
      {'angle': 78.0, 'yFactor': 0.50},
      {'angle': 92.0, 'yFactor': 0.64},
      {'angle': 105.0, 'yFactor': 0.57},
      {'angle': 118.0, 'yFactor': 0.62},
      {'angle': 125.0, 'yFactor': 0.52},
      {'angle': 144.0, 'yFactor': 0.60},
      {'angle': 160.0, 'yFactor': 0.62},
      {'angle': 170.0, 'yFactor': 0.53},
      {'angle': 178.0, 'yFactor': 0.56},
      {'angle': 195.0, 'yFactor': 0.55},
      {'angle': 212.0, 'yFactor': 0.63},
      {'angle': 228.0, 'yFactor': 0.60},
      {'angle': 238.0, 'yFactor': 0.51},
      {'angle': 248.0, 'yFactor': 0.54},
      {'angle': 268.0, 'yFactor': 0.58},
      {'angle': 282.0, 'yFactor': 0.63},
      {'angle': 290.0, 'yFactor': 0.53},
      {'angle': 315.0, 'yFactor': 0.56},
      {'angle': 330.0, 'yFactor': 0.64},
      {'angle': 342.0, 'yFactor': 0.61},
    ];
    for (int i = 0; i < shells.length; i++) {
      final double? sx = _worldAngleToScreenX(
        shells[i]['angle']!,
        size,
        margin: 80,
      );
      if (sx == null) continue;
      final double sy = horizonY + groundHeight * shells[i]['yFactor']!;
      if (i % 2 == 0) {
        _drawStarfish(
          canvas,
          Offset(sx, sy),
          i % 4 == 0 ? const Color(0xFFE65100) : const Color(0xFFD84315),
        );
      } else {
        _drawSeashell(canvas, Offset(sx, sy));
      }
    }

    // 6. 12 Larger Animated Scuttling Beach Crabs!
    final List<double> crabHomeAngles = [
      18.0,
      48.0,
      72.0,
      98.0,
      118.0,
      148.0,
      184.0,
      204.0,
      222.0,
      254.0,
      292.0,
      328.0,
    ];
    for (int i = 0; i < crabHomeAngles.length; i++) {
      final double scuttleAngle =
          crabHomeAngles[i] +
          math.sin(time * (0.85 + (i % 3) * 0.25) + i * 1.7) * 9.5;
      final double? cx = _worldAngleToScreenX(
        scuttleAngle,
        size,
        margin: 100,
      );
      if (cx == null) continue;
      final double cy =
          horizonY + groundHeight * (0.47 + (i % 4) * 0.05);
      _drawCrab(canvas, Offset(cx, cy), time, i);
    }

    // 7. 45 Glowing fireflies / tropical pollen drifting in the evening air
    for (int i = 0; i < 45; i++) {
      final double fAngle =
          (i * 8.0 + math.sin(time * 0.5 + i) * 8.0) % 360.0;
      final double? fx = _worldAngleToScreenX(fAngle, size, margin: 40);
      if (fx == null) continue;

      final double fy =
          horizonY +
          groundHeight * (0.08 + ((i * 17) % 72) / 100.0) +
          math.sin(time * 1.8 + i) * 10.0;
      final double alpha =
          0.3 + 0.7 * (0.5 + 0.5 * math.sin(time * 3.0 + i * 1.7));

      canvas.drawCircle(
        Offset(fx, fy),
        atmosphereMode == CoconutAtmosphereMode.night ? 3.2 : 2.5,
        Paint()
          ..color = (atmosphereMode == CoconutAtmosphereMode.night
                  ? const Color(0xFF69F0AE)
                  : const Color(0xFFFFE57F))
              .withValues(alpha: alpha * 0.80),
      );
    }
  }

  void _drawBeachVolleyballNet(
    Canvas canvas,
    Size size,
    double baseY,
    double worldAngle,
  ) {
    final double? vx = _worldAngleToScreenX(worldAngle, size, margin: 220);
    if (vx == null) return;

    canvas.save();
    canvas.translate(vx, baseY);
    canvas.scale(1.85);

    // Court boundary lines on the sand
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 4), width: 88, height: 14),
      Paint()
        ..color = const Color(0xFFFFF8E1).withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final Paint polePaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 2.6;
    canvas.drawLine(const Offset(-28, 4), const Offset(-28, -28), polePaint);
    canvas.drawLine(const Offset(28, 4), const Offset(28, -28), polePaint);

    // Net mesh
    canvas.drawRect(
      const Rect.fromLTWH(-28, -26, 56, 12),
      Paint()..color = Colors.white.withValues(alpha: 0.28),
    );
    for (int m = -24; m <= 24; m += 6) {
      canvas.drawLine(
        Offset(m.toDouble(), -26),
        Offset(m.toDouble(), -14),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.25)
          ..strokeWidth = 0.7,
      );
    }
    canvas.drawLine(
      const Offset(-28, -26),
      const Offset(28, -26),
      Paint()
        ..color = const Color(0xFFFFF8E1)
        ..strokeWidth = 1.8,
    );

    // 2 Animated Beach Volleyball Players jumping & rallying a ball over the net!
    final double rallyPhase = (time * 1.4) % (2 * math.pi);
    final double ballT = 0.5 + 0.5 * math.sin(rallyPhase); // 0 (left) .. 1 (right)
    final double ballX = -22.0 + ballT * 44.0;
    final double ballY = -24.0 - math.sin(ballT * math.pi) * 20.0;

    // Left Player (-22) & Right Player (+22)
    for (final int side in [-1, 1]) {
      final double px = side * 22.0;
      final bool isHitting = (side == -1 && ballT < 0.25) || (side == 1 && ballT > 0.75);
      final double jump = isHitting ? 4.5 : math.sin(time * 3.5 + side).abs() * 1.5;
      canvas.drawCircle(
        Offset(px, -21 - jump),
        3.8,
        Paint()..color = const Color(0xFFE0A380),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(px - 4, -17 - jump, 8, 10),
          const Radius.circular(2.5),
        ),
        Paint()
          ..color = side == -1
              ? const Color(0xFFFF5252)
              : const Color(0xFF29B6F6),
      );
      canvas.drawLine(
        Offset(px - 1.8, -7 - jump),
        Offset(px - 2.2, 3 - jump * 0.5),
        Paint()
          ..color = const Color(0xFF231520)
          ..strokeWidth = 2.2,
      );
      canvas.drawLine(
        Offset(px + 1.8, -7 - jump),
        Offset(px + 2.2, 3 - jump * 0.5),
        Paint()
          ..color = const Color(0xFF231520)
          ..strokeWidth = 2.2,
      );
      // Raised arms towards the ball
      canvas.drawLine(
        Offset(px, -15 - jump),
        Offset(px - side * 4.5, -24 - jump),
        Paint()
          ..color = const Color(0xFFE0A380)
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round,
      );
    }

    // Flying Volleyball in mid-air!
    canvas.drawCircle(
      Offset(ballX, ballY),
      3.4,
      Paint()..color = const Color(0xFFFFF9C4),
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(ballX, ballY), radius: 3.4),
      0.2,
      1.8,
      false,
      Paint()
        ..color = const Color(0xFFFF9800)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    canvas.restore();
  }

  void _drawSandcastleAndBall(
    Canvas canvas,
    Size size,
    double baseY,
    double worldAngle,
  ) {
    final double? sx = _worldAngleToScreenX(worldAngle, size, margin: 180);
    if (sx == null) return;

    canvas.save();
    canvas.translate(sx, baseY);
    canvas.scale(1.85);

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 4), width: 58, height: 11),
      Paint()..color = Colors.black.withValues(alpha: 0.23),
    );

    final Paint sandTower = Paint()..color = const Color(0xFFD9945A);
    final Paint sandDark = Paint()..color = const Color(0xFF8D562E);

    // Left, Right & Center Castle Towers with Crenellations
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-19, -15, 11, 17),
        const Radius.circular(2),
      ),
      sandTower,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(8, -15, 11, 17),
        const Radius.circular(2),
      ),
      sandTower,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-9, -23, 18, 25),
        const Radius.circular(2),
      ),
      sandTower,
    );
    // Arch doorway
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-3.5, -9, 7, 11),
        const Radius.circular(3.5),
      ),
      sandDark,
    );
    // Little red flag on top of center tower
    canvas.drawLine(
      const Offset(0, -23),
      const Offset(0, -33),
      Paint()
        ..color = const Color(0xFF4E342E)
        ..strokeWidth = 1.4,
    );
    final Path flag = Path()
      ..moveTo(0, -33)
      ..lineTo(9, -30)
      ..lineTo(0, -27)
      ..close();
    canvas.drawPath(flag, Paint()..color = const Color(0xFFFF5252));

    // Turquoise Plastic Beach Bucket & Shovel beside left tower!
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-30, -6, 7.5, 8),
        const Radius.circular(1.5),
      ),
      Paint()..color = const Color(0xFF00ACC1),
    );

    // Colorful Beach Ball beside the sandcastle
    final double ballRoll = math.sin(time * 1.5 + worldAngle) * 2.5;
    final Offset ballCenter = Offset(24 + ballRoll, -4);
    canvas.drawCircle(
      ballCenter,
      6.5,
      Paint()..color = const Color(0xFFFFF8E1),
    );
    canvas.drawArc(
      Rect.fromCircle(center: ballCenter, radius: 6.5),
      0,
      math.pi * 0.7,
      true,
      Paint()..color = const Color(0xFFFF5252),
    );
    canvas.drawArc(
      Rect.fromCircle(center: ballCenter, radius: 6.5),
      math.pi,
      math.pi * 0.7,
      true,
      Paint()..color = const Color(0xFF29B6F6),
    );

    canvas.restore();
  }

  void _drawBeachUmbrellaAndTowel(
    Canvas canvas,
    Size size,
    double baseY,
    double worldAngle,
    Color stripeColor, {
    bool hasSunbather = true,
  }) {
    final double? ux = _worldAngleToScreenX(worldAngle, size, margin: 240);
    if (ux == null) return;

    canvas.save();
    canvas.translate(ux, baseY);
    canvas.scale(1.80);

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(4, 6), width: 78, height: 15),
      Paint()..color = Colors.black.withValues(alpha: 0.24),
    );

    // Wooden Beach Lounger Chair & Towel
    canvas.drawLine(
      const Offset(-26, 8),
      const Offset(16, 8),
      Paint()
        ..color = const Color(0xFF6D4C41)
        ..strokeWidth = 2.6,
    );
    canvas.drawLine(
      const Offset(-24, 8),
      const Offset(-32, -4),
      Paint()
        ..color = const Color(0xFF6D4C41)
        ..strokeWidth = 2.6,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-24, 2, 42, 7),
        const Radius.circular(3),
      ),
      Paint()..color = stripeColor.withValues(alpha: 0.88),
    );

    // Person sunbathing & relaxing on the lounger chair!
    if (hasSunbather) {
      canvas.drawCircle(
        const Offset(-24, -2),
        3.8,
        Paint()..color = const Color(0xFFE0A380),
      );
      // Sunglasses / sunhat
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(-25, -4.5), width: 10, height: 3),
        Paint()..color = const Color(0xFFFFE082),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-19, -1, 18, 5),
          const Radius.circular(2.5),
        ),
        Paint()..color = const Color(0xFFD79975),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-12, -1, 8, 5),
          const Radius.circular(2),
        ),
        Paint()..color = stripeColor,
      );
    }

    // Pole
    canvas.drawLine(
      const Offset(0, 5),
      const Offset(-4, -46),
      Paint()
        ..color = const Color(0xFF5D4037)
        ..strokeWidth = 3.0,
    );

    // Canopy
    final Path canopy = Path()
      ..moveTo(-36, -34)
      ..quadraticBezierTo(-4, -62, 28, -32)
      ..close();
    canvas.drawPath(canopy, Paint()..color = const Color(0xFFFFF8E1));

    final Path centerStripe = Path()
      ..moveTo(-14, -33)
      ..quadraticBezierTo(-4, -59, 8, -32)
      ..close();
    canvas.drawPath(centerStripe, Paint()..color = stripeColor);

    canvas.restore();
  }

  void _drawSeashell(Canvas canvas, Offset center) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(1.65);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 12, height: 8),
      Paint()..color = const Color(0xFFFFF3E0),
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset.zero, width: 10, height: 6),
      0,
      math.pi,
      false,
      Paint()
        ..color = const Color(0xFFD7CCC8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.restore();
  }

  void _drawStarfish(Canvas canvas, Offset center, Color color) {
    final Path star = Path();
    for (int i = 0; i < 10; i++) {
      final double angle = i * math.pi / 5.0;
      final double r = (i.isEven ? 9.5 : 4.2) * 1.65;
      final double x = center.dx + math.cos(angle) * r;
      final double y = center.dy + math.sin(angle) * r * 0.65;
      if (i == 0) {
        star.moveTo(x, y);
      } else {
        star.lineTo(x, y);
      }
    }
    star.close();
    canvas.drawPath(star, Paint()..color = color);
  }

  void _drawCrab(Canvas canvas, Offset pos, double t, int seed) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.scale(1.65);

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 4), width: 22, height: 6),
      Paint()..color = Colors.black.withValues(alpha: 0.22),
    );

    final Paint legPaint = Paint()
      ..color = const Color(0xFFD84315)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    // Scuttling legs
    for (int l = -1; l <= 1; l++) {
      final double legMove = math.sin(t * 12.0 + l * 1.5 + seed) * 2.5;
      canvas.drawLine(
        Offset(-6, l * 2.0),
        Offset(-13, 4.0 + l * 2.0 + legMove),
        legPaint,
      );
      canvas.drawLine(
        Offset(6, l * 2.0),
        Offset(13, 4.0 + l * 2.0 - legMove),
        legPaint,
      );
    }

    // Claws
    final double clawSnap = math.sin(t * 4.0 + seed) * 1.5;
    canvas.drawLine(
      const Offset(-6, -2),
      Offset(-11, -8 + clawSnap),
      legPaint..strokeWidth = 2.2,
    );
    canvas.drawLine(const Offset(6, -2), Offset(11, -8 - clawSnap), legPaint);

    // Body
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 16, height: 10),
      Paint()..color = const Color(0xFFE64A19),
    );

    // Little eye stalks
    canvas.drawCircle(
      const Offset(-3, -6),
      1.5,
      Paint()..color = Colors.black87,
    );
    canvas.drawCircle(
      const Offset(3, -6),
      1.5,
      Paint()..color = Colors.black87,
    );

    canvas.restore();
  }

  void _drawCenterCoconut(Canvas canvas, Size size, double horizonY) {
    final double cx = size.width * 0.5;
    final double cy = size.height * 0.77;
    final double baseRadius = math.min(size.width, size.height) * 0.135;

    // Subtle breathing / breeze micro-sway + tap pulse
    final double scale =
        (1.0 + coconutPulse * 0.08 + math.sin(time * 1.8) * 0.008) *
        (0.9 + 0.1 * cameraZoom);
    final double swayAngle =
        math.sin(time * 1.4) * 0.025 + coconutPulse * 0.12;
    final double radius = baseRadius * scale;

    canvas.save();
    canvas.translate(cx, cy);

    // 1. Dynamic Shadow on the sand (casts away from the sun at 0°)
    final double sunRelativeRad = (-cameraYaw) * math.pi / 180.0;
    final double shadowOffsetX = -math.sin(sunRelativeRad) * radius * 0.55;
    final double shadowOffsetY =
        radius * 0.72 + math.cos(sunRelativeRad) * radius * 0.16;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(shadowOffsetX, shadowOffsetY),
        width: radius * 2.35,
        height: radius * 0.68,
      ),
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(shadowOffsetX, shadowOffsetY),
          radius * 1.2,
          [
            const Color(0xFF3E1F14).withValues(alpha: 0.62),
            const Color(0xFF5D3222).withValues(alpha: 0.25),
            Colors.transparent,
          ],
          [0.0, 0.65, 1.0],
        ),
    );

    // 2. Rotate Coconut slightly with breeze / tap
    canvas.rotate(swayAngle);

    // Lighting direction relative to the sun at 0°
    final double lightX = math.sin(sunRelativeRad) * radius * 0.45;
    final double lightY =
        -radius * 0.42 - math.cos(sunRelativeRad) * radius * 0.25;

    // Slightly organic oval coconut shape
    final Rect coconutRect = Rect.fromCenter(
      center: Offset.zero,
      width: radius * 2.08,
      height: radius * 1.92,
    );

    // 3D Shaded Coconut Shell
    final Paint coconutPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(lightX, lightY),
        radius * 1.45,
        [
          const Color(0xFF8D5B4C), // Warm sunlit fibrous brown
          const Color(0xFF5D3A29), // Rich mid-tone coconut brown
          const Color(0xFF361F14), // Deep shadow core
        ],
        [0.0, 0.52, 1.0],
      );
    canvas.drawOval(coconutRect, coconutPaint);

    // Rim Light on the edge facing the sun/moon
    final Color rimColor =
        atmosphereMode == CoconutAtmosphereMode.night
            ? const Color(0xFF00E5FF)
            : const Color(0xFFFFB74D);
    final Paint rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..shader = ui.Gradient.linear(
        Offset(lightX * 1.5, lightY * 1.5),
        Offset(-lightX * 1.5, -lightY * 1.5),
        [
          rimColor.withValues(alpha: 0.75),
          Colors.transparent,
        ],
      );
    canvas.drawOval(coconutRect.deflate(1.5), rimPaint);

    // Fibrous Husks / Texture ridges rotating in 3D as the camera orbits around the coconut!
    final Paint fiberPaint = Paint()
      ..color = const Color(0xFF2B170E).withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final Paint highlightFiberPaint = Paint()
      ..color = const Color(0xFFA97862).withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 16; i++) {
      final double fiberWorldAngle = (i * 22.5 - cameraYaw) * math.pi / 180.0;
      if (math.cos(fiberWorldAngle) > -0.15) {
        final double xProj = math.sin(fiberWorldAngle) * radius * 0.92;
        final Path ridge = Path()
          ..moveTo(0, -radius * 0.88)
          ..quadraticBezierTo(xProj * 1.18, 0, xProj * 0.35, radius * 0.88);
        canvas.drawPath(ridge, i.isEven ? fiberPaint : highlightFiberPaint);
      }
    }

    // The 3 Iconic Coconut Dimples ("bowling ball eyes") fixed on the front hemisphere (around 0°..40°)
    final double dimpleAngleRad = (15.0 - cameraYaw) * math.pi / 180.0;
    if (math.cos(dimpleAngleRad) > 0.1) {
      final double dxBase = math.sin(dimpleAngleRad) * radius * 0.65;
      final double perspectiveSquash =
          math.cos(dimpleAngleRad).clamp(0.25, 1.0);
      final Paint dimplePaint = Paint()
        ..color = const Color(0xFF24130B).withValues(alpha: 0.85);

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(dxBase - 11 * perspectiveSquash, -radius * 0.24),
          width: 11 * perspectiveSquash,
          height: 13,
        ),
        dimplePaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(dxBase + 11 * perspectiveSquash, -radius * 0.22),
          width: 11 * perspectiveSquash,
          height: 13,
        ),
        dimplePaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(dxBase, -radius * 0.04),
          width: 12 * perspectiveSquash,
          height: 10,
        ),
        dimplePaint,
      );
    }

    // Coconut Style Mode Accessories!
    switch (styleMode) {
      case CoconutStyleMode.natural:
        break;
      case CoconutStyleMode.arcade:
        _drawArcadeAccessories(canvas, radius);
      case CoconutStyleMode.cocktail:
        _drawCocktailAccessories(canvas, radius);
      case CoconutStyleMode.king:
        _drawKingCrownAccessories(canvas, radius);
      case CoconutStyleMode.lofi:
        _drawLofiHeadphonesAccessories(canvas, radius);
    }

    // Sand grains nestled around the bottom of the coconut so it sits grounded in the beach
    final Path sandNest = Path()
      ..moveTo(-radius * 1.15, radius * 0.76)
      ..quadraticBezierTo(
        -radius * 0.5,
        radius * 0.58,
        0,
        radius * 0.68,
      )
      ..quadraticBezierTo(
        radius * 0.5,
        radius * 0.56,
        radius * 1.15,
        radius * 0.76,
      )
      ..quadraticBezierTo(0, radius * 1.02, -radius * 1.15, radius * 0.76)
      ..close();
    canvas.drawPath(
      sandNest,
      Paint()
        ..color = atmosphereMode == CoconutAtmosphereMode.night
            ? const Color(0xFF2B354D)
            : const Color(0xFFC87A45),
    );

    canvas.restore();
  }

  void _drawArcadeAccessories(Canvas canvas, double radius) {
    // Little cocktail umbrella sticking out of the top-right of the coconut
    canvas.save();
    canvas.translate(radius * 0.35, -radius * 0.78);
    canvas.rotate(0.38);

    // Stick
    canvas.drawLine(
      const Offset(0, 12),
      const Offset(0, -34),
      Paint()
        ..color = const Color(0xFFFFECB3)
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round,
    );

    // Pink & Cyan tropical umbrella canopy
    final Path canopy = Path()
      ..moveTo(-30, -24)
      ..quadraticBezierTo(0, -50, 30, -24)
      ..close();
    canvas.drawPath(canopy, Paint()..color = const Color(0xFFFF4081));

    final Path stripe = Path()
      ..moveTo(-12, -24)
      ..quadraticBezierTo(0, -48, 12, -24)
      ..close();
    canvas.drawPath(stripe, Paint()..color = const Color(0xFF00E5FF));

    canvas.restore();

    // Cool Retro Deal-With-It / Sunset Aviator Shades
    final Paint framePaint = Paint()..color = const Color(0xFF1A1A1A);
    final Paint lensPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, -18),
        const Offset(0, 4),
        [const Color(0xFFFF4081), const Color(0xFFFF9100)],
      );

    final RRect leftLens = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(-radius * 0.34, -radius * 0.14),
        width: radius * 0.54,
        height: radius * 0.34,
      ),
      const Radius.circular(6),
    );
    final RRect rightLens = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(radius * 0.34, -radius * 0.14),
        width: radius * 0.54,
        height: radius * 0.34,
      ),
      const Radius.circular(6),
    );

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(0, -radius * 0.22),
        width: radius * 1.4,
        height: 3.5,
      ),
      framePaint,
    );
    canvas.drawRRect(leftLens.inflate(2.5), framePaint);
    canvas.drawRRect(rightLens.inflate(2.5), framePaint);
    canvas.drawRRect(leftLens, lensPaint);
    canvas.drawRRect(rightLens, lensPaint);
  }

  void _drawCocktailAccessories(Canvas canvas, double radius) {
    // Carved white coconut flesh rim at top
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, -radius * 0.74),
        width: radius * 1.05,
        height: radius * 0.32,
      ),
      Paint()..color = const Color(0xFFFFF8E7),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, -radius * 0.74),
        width: radius * 0.82,
        height: radius * 0.20,
      ),
      Paint()..color = const Color(0xFF4DD0E1),
    );

    // Striped bent straw
    final Path straw = Path()
      ..moveTo(-radius * 0.12, -radius * 0.74)
      ..lineTo(-radius * 0.28, -radius * 1.28)
      ..lineTo(-radius * 0.52, -radius * 1.38);
    canvas.drawPath(
      straw,
      Paint()
        ..color = const Color(0xFFFF5252)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Lime wedge on the rim
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(radius * 0.42, -radius * 0.78),
        radius: radius * 0.24,
      ),
      -math.pi * 0.85,
      math.pi * 0.95,
      true,
      Paint()..color = const Color(0xFF8BC34A),
    );

    // Tropical Hibiscus Flower on the side
    final Offset flowerCenter = Offset(-radius * 0.45, -radius * 0.58);
    for (int p = 0; p < 5; p++) {
      final double a = p * (2 * math.pi / 5);
      canvas.drawCircle(
        flowerCenter.translate(math.cos(a) * 8, math.sin(a) * 8),
        7.0,
        Paint()..color = const Color(0xFFFF4081),
      );
    }
    canvas.drawCircle(
      flowerCenter,
      4.0,
      Paint()..color = const Color(0xFFFFEB3B),
    );
  }

  void _drawKingCrownAccessories(Canvas canvas, double radius) {
    // Glowing golden crown sitting atop the coconut
    final double cy = -radius * 0.78;
    final double cw = radius * 0.92;
    final Path crown = Path()
      ..moveTo(-cw * 0.5, cy)
      ..lineTo(-cw * 0.58, cy - radius * 0.45)
      ..lineTo(-cw * 0.25, cy - radius * 0.18)
      ..lineTo(0, cy - radius * 0.56)
      ..lineTo(cw * 0.25, cy - radius * 0.18)
      ..lineTo(cw * 0.58, cy - radius * 0.45)
      ..lineTo(cw * 0.5, cy)
      ..close();

    canvas.drawPath(
      crown,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, cy - radius * 0.56),
          Offset(0, cy),
          [const Color(0xFFFFF176), const Color(0xFFFFB300)],
        ),
    );
    canvas.drawPath(
      crown,
      Paint()
        ..color = const Color(0xFFE65100)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Crown jewels
    canvas.drawCircle(
      Offset(0, cy - radius * 0.18),
      4.5,
      Paint()..color = const Color(0xFFE53935),
    );
    canvas.drawCircle(
      Offset(-cw * 0.28, cy - radius * 0.12),
      3.5,
      Paint()..color = const Color(0xFF00E5FF),
    );
    canvas.drawCircle(
      Offset(cw * 0.28, cy - radius * 0.12),
      3.5,
      Paint()..color = const Color(0xFF00E5FF),
    );
  }

  void _drawLofiHeadphonesAccessories(Canvas canvas, double radius) {
    // Headband arc over the top of the coconut
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(0, -radius * 0.08),
        width: radius * 2.18,
        height: radius * 1.95,
      ),
      math.pi * 1.05,
      math.pi * 0.90,
      false,
      Paint()
        ..color = const Color(0xFF263238)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7.0
        ..strokeCap = StrokeCap.round,
    );

    // Left & Right Ear Cups
    for (final int dir in [-1, 1]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(dir * radius * 1.04, -radius * 0.05),
            width: radius * 0.28,
            height: radius * 0.56,
          ),
          const Radius.circular(10),
        ),
        Paint()..color = const Color(0xFFFF7043),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(dir * radius * 0.96, -radius * 0.05),
            width: radius * 0.12,
            height: radius * 0.48,
          ),
          const Radius.circular(6),
        ),
        Paint()..color = const Color(0xFF37474F),
      );
    }

    // Floating musical notes drifting up from the headphones
    for (int n = 0; n < 3; n++) {
      final double p = ((time * 0.45 + n * 0.33) % 1.0);
      final double nx =
          (n.isEven ? 1 : -1) * (radius * 0.8 + math.sin(time * 2.5 + n) * 12.0);
      final double ny = -radius * 0.5 - p * radius * 1.2;
      final double alpha = math.sin(p * math.pi).clamp(0.0, 1.0);
      final Paint notePaint = Paint()
        ..color = const Color(0xFF80DEEA).withValues(alpha: alpha * 0.9)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(nx, ny), 3.8, notePaint);
      canvas.drawLine(
        Offset(nx + 3, ny),
        Offset(nx + 3, ny - 11),
        notePaint..style = PaintingStyle.stroke,
      );
    }
  }

  void _drawAtmosphericOverlay(Canvas canvas, Size size, double horizonY) {
    // 1. Lo-Fi Tropical Rain Streaks & Ripples when in Rain mode
    if (atmosphereMode == CoconutAtmosphereMode.rain) {
      final Paint rainPaint = Paint()
        ..color = const Color(0xFFB0BEC5).withValues(alpha: 0.38)
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < 65; i++) {
        final double rx =
            ((i * 73.0 + time * 180.0) % (size.width + 100.0)) - 50.0;
        final double ry = ((i * 47.0 + time * 520.0) % size.height);
        canvas.drawLine(Offset(rx, ry), Offset(rx - 7.0, ry + 22.0), rainPaint);
      }
    }

    // 2. Warm sun lens flare when looking near 0°
    final double sunFocus = _angleWeight(cameraYaw, 0.0, 45.0);
    if (sunFocus > 0.01 &&
        (atmosphereMode == CoconutAtmosphereMode.sunset ||
            atmosphereMode == CoconutAtmosphereMode.noon)) {
      final Paint flarePaint = Paint()
        ..shader = ui.Gradient.radial(
          Offset(size.width * 0.5, horizonY),
          size.width * 0.55,
          [
            const Color(0xFFFFCC80).withValues(alpha: 0.16 * sunFocus),
            Colors.transparent,
          ],
        );
      canvas.drawRect(Offset.zero & size, flarePaint);
    }

    // 3. Subtle cinematic edge vignette
    final Paint vignette = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.5, size.height * 0.5),
        math.max(size.width, size.height) * 0.75,
        [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.38),
        ],
        [0.65, 1.0],
      );
    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(covariant CoconutWorldPainter oldDelegate) {
    if (controller != null && oldDelegate.controller == controller) {
      return false; // Repaints are driven directly by controller Listenable
    }
    return oldDelegate.controller != controller ||
        oldDelegate.time != time ||
        oldDelegate.cameraYaw != cameraYaw ||
        oldDelegate.cameraPitch != cameraPitch ||
        oldDelegate.isArcadeMode != isArcadeMode ||
        oldDelegate.coconutPulse != coconutPulse ||
        oldDelegate.atmosphereMode != atmosphereMode ||
        oldDelegate.styleMode != styleMode ||
        oldDelegate.cameraZoom != cameraZoom;
  }
}
