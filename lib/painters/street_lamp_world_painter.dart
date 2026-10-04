// ignore_for_file: prefer_initializing_formals
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../controllers/zenverse_controller.dart';
import 'coconut_world_painter.dart';

class StreetLampWorldPainter extends CustomPainter {
  final ZenVerseController? controller;
  final double _cameraYaw;
  final double _cameraPitch;
  final double _time;
  final bool _isArcadeMode;
  final double _coconutPulse;
  final CoconutAtmosphereMode _atmosphereMode;
  final CoconutStyleMode _styleMode;
  final double _cameraZoom;

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

  StreetLampWorldPainter({
    this.controller,
    Listenable? repaint,
    double cameraYaw = 0.0,
    double cameraPitch = 0.0,
    double time = 0.0,
    bool isArcadeMode = false,
    double coconutPulse = 0.0,
    CoconutAtmosphereMode atmosphereMode = CoconutAtmosphereMode.sunset,
    CoconutStyleMode styleMode = CoconutStyleMode.natural,
    double cameraZoom = 1.0,
  }) : _cameraYaw = cameraYaw,
       _cameraPitch = cameraPitch,
       _time = time,
       _isArcadeMode = isArcadeMode,
       _coconutPulse = coconutPulse,
       _atmosphereMode = atmosphereMode,
       _styleMode = styleMode,
       _cameraZoom = cameraZoom,
       super(repaint: repaint ?? controller);

  double? _worldAngleToScreenX(
    double worldDeg,
    Size size, {
    double fov = 110.0,
    double margin = 420.0,
  }) {
    final double effectiveFov = fov / cameraZoom.clamp(0.75, 1.5);
    double diff = (worldDeg - cameraYaw) % 360.0;
    if (diff > 180.0) diff -= 360.0;
    if (diff < -180.0) diff += 360.0;
    final double x = size.width * 0.5 + (diff / effectiveFov) * size.width;
    if (x < -margin || x > size.width + margin) return null;
    return x;
  }


  bool get _isNightOrRain =>
      atmosphereMode == CoconutAtmosphereMode.night ||
      atmosphereMode == CoconutAtmosphereMode.rain ||
      atmosphereMode == CoconutAtmosphereMode.sunset;

  @override
  void paint(Canvas canvas, Size size) {
    final double horizonY = size.height * (0.48 + (cameraPitch / 90.0) * 0.45);

    // 1. Sky, Moon/Sunset, Distant Cathedral Domes, 16 United Clouds & Birds
    _drawSkyAndCelestial(canvas, size, horizonY);
    _drawDistantCathedralSkyline(canvas, size, horizonY);
    _drawUnitedClouds(canvas, size, horizonY);
    _drawCityBirds(canvas, size, horizonY);

    // 2. Wet Cobblestone Plaza, Shimmering Puddle Reflections & River Canal (0°)
    _drawCobblestonePlazaAndCanal(canvas, size, horizonY);
    _drawRiverBridgeBoatsAndTram(canvas, size, horizonY);

    // 3. 128° Zone — European Townhouses, Corner French Bistro & Vintage Bookstore
    _drawEuropeanTownhousesAndShops(canvas, size, horizonY);

    // 4. 222° Zone — Illuminated Clock Tower, Park Trees, Vintage Car & Benches
    _drawClockTowerParkAndStreetScene(canvas, size, horizonY);

    // 5. 74° Zone — Grand Plaza Fountain, Street Musicians & Roasted Chestnut Cart
    _drawGrandFountainMusiciansAndCart(canvas, size, horizonY);

    // 6. 168° Zone — Lively Night Ramen Stall, Jazz Club Alley & Umbrella Strollers
    _drawRamenPavilionAndJazzAlley(canvas, size, horizonY);

    // 7. Shimmering foreground puddle reflections & stray cats
    _drawForegroundPuddlesAndCats(canvas, size, horizonY);

    // 8. Center Foreground Object — The Vintage Cast-Iron Street Lamp
    _drawCenterStreetLamp(canvas, size);

    // 9. Weather & Atmospheric Overlays (Rain streaks, Night moths, Sunbeams, Lo-Fi Vignette)
    _drawAtmosphericOverlay(canvas, size, horizonY);
  }

  // ===========================================================================
  // 1. SKY, CELESTIAL BODIES, CATHEDRAL SKYLINE, UNITED CLOUDS & CITY BIRDS
  // ===========================================================================
  void _drawSkyAndCelestial(Canvas canvas, Size size, double horizonY) {
    List<Color> skyColors;
    switch (atmosphereMode) {
      case CoconutAtmosphereMode.sunset:
        // Amber-violet Parisian dusk
        skyColors = const [
          Color(0xFF1A1033),
          Color(0xFF3E1E54),
          Color(0xFF8A396B),
          Color(0xFFD96B43),
          Color(0xFFF6B26B),
        ];
        break;
      case CoconutAtmosphereMode.night:
        // Deep midnight blue with city light pollution glow near horizon
        skyColors = const [
          Color(0xFF050714),
          Color(0xFF0D152E),
          Color(0xFF19264B),
          Color(0xFF2B3558),
          Color(0xFF473B54),
        ];
        break;
      case CoconutAtmosphereMode.noon:
        // Crisp European afternoon sky
        skyColors = const [
          Color(0xFF1E62B5),
          Color(0xFF3E88D6),
          Color(0xFF72B2EC),
          Color(0xFFAAD5F7),
          Color(0xFFE5F2FC),
        ];
        break;
      case CoconutAtmosphereMode.rain:
        // Moody Lo-Fi rainy night with wet reflections
        skyColors = const [
          Color(0xFF0A0F1D),
          Color(0xFF151E34),
          Color(0xFF23304C),
          Color(0xFF35415C),
          Color(0xFF4C4F69),
        ];
        break;
    }

    final Paint skyPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, horizonY + 40),
        skyColors,
        const [0.0, 0.28, 0.58, 0.84, 1.0],
      );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, horizonY + 40),
      skyPaint,
    );

    // Stars in Night / Sunset / Rain modes
    if (atmosphereMode != CoconutAtmosphereMode.noon) {
      final double starBaseAlpha =
          atmosphereMode == CoconutAtmosphereMode.night
              ? 0.90
              : (atmosphereMode == CoconutAtmosphereMode.sunset ? 0.42 : 0.22);
      for (int i = 0; i < 90; i++) {
        final double starDeg = (i * 37.3) % 360.0;
        final double? sx = _worldAngleToScreenX(starDeg, size, margin: 40);
        if (sx == null) continue;
        final double sy = ((i * 53.7) % 100.0) / 100.0 * (horizonY * 0.78);
        final double twinkle =
            0.55 + 0.45 * math.sin(time * (1.8 + (i % 5) * 0.4) + i);
        final double r = (i % 7 == 0) ? 2.1 : 1.2;
        canvas.drawCircle(
          Offset(sx, sy),
          r,
          Paint()
            ..color = const Color(0xFFFFF8E7)
                .withValues(alpha: (starBaseAlpha * twinkle).clamp(0.0, 1.0)),
        );
      }
    }

    // Celestial orb: Giant glowing full moon in night/rain, warm sun in sunset/noon
    final double celestialDeg =
        (atmosphereMode == CoconutAtmosphereMode.night ||
                atmosphereMode == CoconutAtmosphereMode.rain)
            ? 28.0
            : 352.0;
    final double? cx = _worldAngleToScreenX(celestialDeg, size, margin: 260);
    if (cx != null) {
      final double cy = horizonY -
          size.height *
              (atmosphereMode == CoconutAtmosphereMode.sunset ? 0.16 : 0.27);
      if (atmosphereMode == CoconutAtmosphereMode.night ||
          atmosphereMode == CoconutAtmosphereMode.rain) {
        // Giant glowing full moon
        final double moonR = 48.0;
        canvas.drawCircle(
          Offset(cx, cy),
          moonR * 3.2,
          Paint()
            ..shader = ui.Gradient.radial(
              Offset(cx, cy),
              moonR * 3.2,
              [
                const Color(0xFFFFF3C4).withValues(alpha: 0.32),
                const Color(0xFF90CAF9).withValues(alpha: 0.10),
                Colors.transparent,
              ],
              const [0.0, 0.5, 1.0],
            ),
        );
        canvas.drawCircle(
          Offset(cx, cy),
          moonR,
          Paint()..color = const Color(0xFFFFFDE7),
        );
        // Subtle lunar craters
        final Paint craterPaint = Paint()
          ..color = const Color(0xFFE0D8B8).withValues(alpha: 0.55);
        canvas.drawCircle(Offset(cx - 14, cy - 10), 9, craterPaint);
        canvas.drawCircle(Offset(cx + 16, cy + 8), 12, craterPaint);
        canvas.drawCircle(Offset(cx - 6, cy + 18), 6.5, craterPaint);
      } else {
        // Parisian Sunset / Noon Sun
        final double sunR =
            atmosphereMode == CoconutAtmosphereMode.sunset ? 56.0 : 42.0;
        final Color coreColor = atmosphereMode == CoconutAtmosphereMode.sunset
            ? const Color(0xFFFFE082)
            : const Color(0xFFFFFDE7);
        final Color haloColor = atmosphereMode == CoconutAtmosphereMode.sunset
            ? const Color(0xFFFF7043)
            : const Color(0xFFFFECB3);
        canvas.drawCircle(
          Offset(cx, cy),
          sunR * 3.6,
          Paint()
            ..shader = ui.Gradient.radial(
              Offset(cx, cy),
              sunR * 3.6,
              [
                haloColor.withValues(alpha: 0.45),
                haloColor.withValues(alpha: 0.12),
                Colors.transparent,
              ],
              const [0.0, 0.5, 1.0],
            ),
        );
        canvas.drawCircle(Offset(cx, cy), sunR, Paint()..color = coreColor);
      }
    }
  }

  void _drawDistantCathedralSkyline(
    Canvas canvas,
    Size size,
    double horizonY,
  ) {
    final Color farSilColor = switch (atmosphereMode) {
      CoconutAtmosphereMode.sunset => const Color(0xFF2B193D),
      CoconutAtmosphereMode.night => const Color(0xFF0E1528),
      CoconutAtmosphereMode.noon => const Color(0xFF6B8CB8),
      CoconutAtmosphereMode.rain => const Color(0xFF1A2337),
    };
    final Color midSilColor = switch (atmosphereMode) {
      CoconutAtmosphereMode.sunset => const Color(0xFF1F122E),
      CoconutAtmosphereMode.night => const Color(0xFF090E1C),
      CoconutAtmosphereMode.noon => const Color(0xFF51719C),
      CoconutAtmosphereMode.rain => const Color(0xFF131B2B),
    };

    // Continuous 360° distant European skyline with cathedral domes & spires
    for (int i = 0; i < 36; i++) {
      final double deg = i * 10.0;
      final double? sx = _worldAngleToScreenX(deg, size, margin: 220);
      if (sx == null) continue;

      final double w = 78.0 + (i % 4) * 22.0;
      final double h = 52.0 + (i % 5) * 18.0;
      final Rect bRect = Rect.fromLTWH(sx - w * 0.5, horizonY - h, w, h + 6);
      canvas.drawRect(bRect, Paint()..color = farSilColor);

      // Cathedral dome every 4th sector
      if (i % 4 == 0) {
        final double domeR = w * 0.36;
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(sx, horizonY - h),
            width: domeR * 2,
            height: domeR * 2.2,
          ),
          math.pi,
          math.pi,
          true,
          Paint()..color = farSilColor,
        );
        // Spire needle + cupola lantern
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(sx, horizonY - h - domeR * 1.15),
            width: 8,
            height: 14,
          ),
          Paint()..color = farSilColor,
        );
        canvas.drawLine(
          Offset(sx, horizonY - h - domeR * 1.2),
          Offset(sx, horizonY - h - domeR * 1.75),
          Paint()
            ..color = farSilColor
            ..strokeWidth = 2.4,
        );
      } else if (i % 3 == 0) {
        // Gothic twin spires
        final Path spire = Path()
          ..moveTo(sx - w * 0.28, horizonY - h)
          ..lineTo(sx - w * 0.16, horizonY - h - 42)
          ..lineTo(sx - w * 0.04, horizonY - h)
          ..moveTo(sx + w * 0.04, horizonY - h)
          ..lineTo(sx + w * 0.16, horizonY - h - 42)
          ..lineTo(sx + w * 0.28, horizonY - h)
          ..close();
        canvas.drawPath(spire, Paint()..color = midSilColor);
      }

      // Tiny glowing skyline windows at dusk/night/rain
      if (_isNightOrRain) {
        final Paint winPaint = Paint()
          ..color = const Color(0xFFFFD54F).withValues(alpha: 0.45);
        for (int r = 0; r < 3; r++) {
          for (int c = 0; c < 4; c++) {
            if ((i + r + c) % 2 == 0) {
              canvas.drawRect(
                Rect.fromLTWH(
                  sx - w * 0.35 + c * (w * 0.20),
                  horizonY - h + 10 + r * 12.0,
                  4.0,
                  6.5,
                ),
                winPaint,
              );
            }
          }
        }
      }
    }
  }

  void _drawUnitedClouds(Canvas canvas, Size size, double horizonY) {
    // 16 united volumetric clouds using Path.combine(PathOperation.union, ...)
    final Color cloudFill = switch (atmosphereMode) {
      CoconutAtmosphereMode.sunset =>
        const Color(0xFF5D376E).withValues(alpha: 0.78),
      CoconutAtmosphereMode.night =>
        const Color(0xFF19243E).withValues(alpha: 0.76),
      CoconutAtmosphereMode.noon =>
        const Color(0xFFFFFFFF).withValues(alpha: 0.88),
      CoconutAtmosphereMode.rain =>
        const Color(0xFF28344B).withValues(alpha: 0.86),
    };
    final Color cloudRim = switch (atmosphereMode) {
      CoconutAtmosphereMode.sunset =>
        const Color(0xFFFFAB73).withValues(alpha: 0.75),
      CoconutAtmosphereMode.night =>
        const Color(0xFF90CAF9).withValues(alpha: 0.38),
      CoconutAtmosphereMode.noon =>
        const Color(0xFFE3F2FD).withValues(alpha: 0.95),
      CoconutAtmosphereMode.rain =>
        const Color(0xFF78909C).withValues(alpha: 0.42),
    };

    for (int i = 0; i < 16; i++) {
      final double baseDeg = (i * 22.5 + time * (0.45 + (i % 3) * 0.15)) % 360.0;
      final double? cx = _worldAngleToScreenX(baseDeg, size, margin: 220);
      if (cx == null) continue;

      final double cy =
          horizonY * (0.18 + (i % 4) * 0.12) + math.sin(time * 0.5 + i) * 3.0;
      final double scale = 0.95 + (i % 3) * 0.25;

      final List<Rect> puffs = [
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: 96 * scale,
          height: 44 * scale,
        ),
        Rect.fromCenter(
          center: Offset(cx - 38 * scale, cy + 6 * scale),
          width: 68 * scale,
          height: 34 * scale,
        ),
        Rect.fromCenter(
          center: Offset(cx + 40 * scale, cy + 5 * scale),
          width: 72 * scale,
          height: 36 * scale,
        ),
        Rect.fromCenter(
          center: Offset(cx - 16 * scale, cy - 14 * scale),
          width: 62 * scale,
          height: 36 * scale,
        ),
        Rect.fromCenter(
          center: Offset(cx + 18 * scale, cy - 12 * scale),
          width: 58 * scale,
          height: 34 * scale,
        ),
      ];

      Path unitedCloud = Path()..addOval(puffs.first);
      for (int p = 1; p < puffs.length; p++) {
        final Path puffPath = Path()..addOval(puffs[p]);
        unitedCloud = Path.combine(PathOperation.union, unitedCloud, puffPath);
      }

      canvas.drawPath(unitedCloud, Paint()..color = cloudFill);
      canvas.drawPath(
        unitedCloud,
        Paint()
          ..color = cloudRim
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }
  }

  void _drawCityBirds(Canvas canvas, Size size, double horizonY) {
    final Paint birdPaint = Paint()
      ..color = (atmosphereMode == CoconutAtmosphereMode.noon
              ? const Color(0xFF263238)
              : const Color(0xFF120B1D))
          .withValues(alpha: 0.78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    for (int f = 0; f < 4; f++) {
      final double flockDeg = (f * 90.0 + time * 3.2) % 360.0;
      final double? fx = _worldAngleToScreenX(flockDeg, size, margin: 180);
      if (fx == null) continue;
      final double fy = horizonY * (0.26 + (f % 2) * 0.14);
      for (int b = 0; b < 5; b++) {
        final double bx = fx + (b - 2) * 18.0;
        final double by =
            fy + (b - 2).abs() * 7.0 + math.sin(time * 6.0 + b) * 3.0;
        final double wingY = math.sin(time * 8.5 + b * 0.9) * 5.5;
        final Path bird = Path()
          ..moveTo(bx - 8, by + wingY)
          ..quadraticBezierTo(bx - 4, by - 4, bx, by)
          ..quadraticBezierTo(bx + 4, by - 4, bx + 8, by + wingY);
        canvas.drawPath(bird, birdPaint);
      }
    }
  }

  // ===========================================================================
  // 2. WET COBBLESTONE PLAZA, SHIMMERING PUDDLES & CANAL BRIDGE / TRAM (0°)
  // ===========================================================================
  void _drawCobblestonePlazaAndCanal(
    Canvas canvas,
    Size size,
    double horizonY,
  ) {
    final double groundHeight = size.height - horizonY;

    // Base wet cobblestone plaza gradient
    final List<Color> plazaColors = switch (atmosphereMode) {
      CoconutAtmosphereMode.sunset => const [
          Color(0xFF2D2338),
          Color(0xFF231C2E),
          Color(0xFF181422),
        ],
      CoconutAtmosphereMode.night => const [
          Color(0xFF141B2D),
          Color(0xFF101626),
          Color(0xFF0A0E19),
        ],
      CoconutAtmosphereMode.noon => const [
          Color(0xFF7B797E),
          Color(0xFF636166),
          Color(0xFF4D4B50),
        ],
      CoconutAtmosphereMode.rain => const [
          Color(0xFF1A2436),
          Color(0xFF141C2B),
          Color(0xFF0D131F),
        ],
    };

    canvas.drawRect(
      Rect.fromLTWH(0, horizonY, size.width, groundHeight),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, horizonY),
          Offset(0, size.height),
          plazaColors,
          const [0.0, 0.55, 1.0],
        ),
    );

    // Perspective Stone-Embankment River Canal Basin (-62°..+62°) using _worldAngleToScreenX
    final double? leftEdgeX = _worldAngleToScreenX(-62.0, size, margin: 1400);
    final double? rightEdgeX = _worldAngleToScreenX(62.0, size, margin: 1400);
    if (leftEdgeX != null && rightEdgeX != null && rightEdgeX > leftEdgeX) {
      final double canalTop = horizonY + groundHeight * 0.02;
      final double canalBottom = horizonY + groundHeight * 0.18;

      final Path canalBasin = Path()
        ..moveTo(leftEdgeX + 28, canalTop)
        ..lineTo(rightEdgeX - 28, canalTop)
        ..lineTo(rightEdgeX, canalBottom)
        ..lineTo(leftEdgeX, canalBottom)
        ..close();

      canvas.save();
      canvas.clipPath(canalBasin);

      canvas.drawRect(
        Rect.fromLTRB(leftEdgeX, canalTop, rightEdgeX, canalBottom),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, canalTop),
            Offset(0, canalBottom),
            const [
              Color(0xFF0A192F),
              Color(0xFF153456),
              Color(0xFF0E233B),
            ],
            const [0.0, 0.52, 1.0],
          ),
      );

      // Golden & neon water ripples inside the perspective canal basin
      for (int r = 0; r < 32; r++) {
        final double rDeg = -56.0 + r * 3.6;
        final double? rx = _worldAngleToScreenX(rDeg, size, margin: 180);
        if (rx == null) continue;
        final double ry =
            canalTop + 7.0 + (r % 5) * ((canalBottom - canalTop - 14.0) / 5.0);
        final double rw = 26.0 + 11.0 * math.sin(time * 2.4 + r);
        canvas.drawLine(
          Offset(rx - rw * 0.5, ry),
          Offset(rx + rw * 0.5, ry),
          Paint()
            ..color = (r.isEven
                    ? const Color(0xFFFFD54F)
                    : const Color(0xFFFF8A65))
                .withValues(alpha: 0.48)
            ..strokeWidth = 2.2
            ..strokeCap = StrokeCap.round,
        );
      }
      canvas.restore();

      // Far-bank & foreground stone quay walls with bevelled coping stones
      final Paint quayWallPaint = Paint()..color = const Color(0xFF454152);
      final Paint quayCapPaint = Paint()..color = const Color(0xFF686378);
      canvas.drawRect(
        Rect.fromLTRB(
          leftEdgeX + 26,
          canalTop - 5,
          rightEdgeX - 26,
          canalTop + 4,
        ),
        quayWallPaint,
      );
      canvas.drawRect(
        Rect.fromLTRB(leftEdgeX, canalBottom - 6, rightEdgeX, canalBottom + 7),
        quayWallPaint,
      );
      canvas.drawRect(
        Rect.fromLTRB(leftEdgeX, canalBottom - 8, rightEdgeX, canalBottom - 4),
        quayCapPaint,
      );

      // Left & right angled stone embankment walls closing the canal at -62° and +62°
      final Paint sideBankPaint = Paint()
        ..color = const Color(0xFF524D60)
        ..strokeWidth = 8.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(leftEdgeX + 28, canalTop),
        Offset(leftEdgeX, canalBottom),
        sideBankPaint,
      );
      canvas.drawLine(
        Offset(rightEdgeX - 28, canalTop),
        Offset(rightEdgeX, canalBottom),
        sideBankPaint,
      );

      // Ornate wrought-iron riverside railings along the quay
      final Paint railPaint = Paint()
        ..color = const Color(0xFF1B1D24)
        ..strokeWidth = 2.2;
      canvas.drawLine(
        Offset(leftEdgeX, canalBottom - 19),
        Offset(rightEdgeX, canalBottom - 19),
        railPaint,
      );
      for (double deg = -60.0; deg <= 60.0; deg += 3.0) {
        final double? postX = _worldAngleToScreenX(deg, size, margin: 200);
        if (postX == null) continue;
        canvas.drawLine(
          Offset(postX, canalBottom - 19),
          Offset(postX, canalBottom - 5),
          railPaint,
        );
      }

      // Parisian Riverside Green Bookstalls (Bouquinistes) along the stone parapet
      for (final double bDeg in [-48.0, -26.0, 26.0, 48.0]) {
        final double? bx = _worldAngleToScreenX(bDeg, size, margin: 220);
        if (bx == null) continue;
        canvas.save();
        canvas.translate(bx, canalBottom - 6);
        canvas.scale(1.55);
        // Heritage dark-green book box & propped-open lid
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-18, -14, 36, 12),
            const Radius.circular(2),
          ),
          Paint()..color = const Color(0xFF1B4332),
        );
        canvas.drawRect(
          const Rect.fromLTWH(-16, -22, 32, 8),
          Paint()..color = const Color(0xFF2D6A4F),
        );
        // Colorful vintage prints, yellow/red books & warm clip-lamp
        for (int k = 0; k < 6; k++) {
          canvas.drawRect(
            Rect.fromLTWH(-14.0 + k * 4.8, -12, 3.8, 8),
            Paint()
              ..color = k.isEven
                  ? const Color(0xFFFFCA28)
                  : const Color(0xFFE53935),
          );
        }
        canvas.drawCircle(
          const Offset(0, -23),
          3.5,
          Paint()..color = const Color(0xFFFFF59D).withValues(alpha: 0.85),
        );
        canvas.restore();
      }
    }

    // Sculpted European radial cobblestone fan arcs & stone joints across the plaza
    final Paint cobbleArcPaint = Paint()
      ..color = Colors.white.withValues(
        alpha: atmosphereMode == CoconutAtmosphereMode.noon ? 0.14 : 0.08,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    final Paint cobbleShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int row = 1; row <= 10; row++) {
      final double rowFrac = row / 10.0;
      final double y =
          horizonY + groundHeight * (0.24 + math.pow(rowFrac, 1.35) * 0.74);
      final double stepW = 54.0 + row * 14.0;
      final double yawOffset = (cameraYaw / 360.0) * stepW * 6.0;

      for (double x = -stepW + (yawOffset % stepW);
          x < size.width + stepW;
          x += stepW) {
        final Rect fanRect = Rect.fromCenter(
          center: Offset(x, y + stepW * 0.28),
          width: stepW * 1.15,
          height: stepW * 0.62,
        );
        canvas.drawArc(
          fanRect,
          math.pi * 1.12,
          math.pi * 0.76,
          false,
          cobbleShadowPaint,
        );
        canvas.drawArc(
          fanRect.translate(0, -1.5),
          math.pi * 1.12,
          math.pi * 0.76,
          false,
          cobbleArcPaint,
        );
      }
    }

    // 18 Shimmering Wet Puddles across 360° reflecting neon pinks, cafe golds, and streetlamp halos
    for (int p = 0; p < 18; p++) {
      final double puddleDeg = (p * 20.0 + 7.0) % 360.0;
      final double? px = _worldAngleToScreenX(puddleDeg, size, margin: 180);
      if (px == null || (px - size.width * 0.5).abs() < 135.0) continue;
      final double py = horizonY + groundHeight * (0.46 + (p % 4) * 0.11);
      final double pw = 76.0 + (p % 4) * 28.0;
      final double ph = 16.0 + (p % 3) * 7.0;

      final Color reflectColor = switch (p % 3) {
        0 => const Color(0xFFFFB74D), // Warm cafe gold
        1 => const Color(0xFFFF4081), // Neon pink/magenta
        _ => const Color(0xFF4FC3F7), // Moon/cyan street reflection
      };

      final Rect puddleRect =
          Rect.fromCenter(center: Offset(px, py), width: pw, height: ph);
      canvas.drawOval(
        puddleRect,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(px, py),
            pw * 0.6,
            [
              reflectColor.withValues(
                alpha: atmosphereMode == CoconutAtmosphereMode.rain
                    ? 0.52
                    : 0.36,
              ),
              const Color(0xFF101828).withValues(alpha: 0.65),
            ],
          ),
      );
      canvas.drawOval(
        puddleRect,
        Paint()
          ..color = reflectColor.withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  void _drawRiverBridgeBoatsAndTram(
    Canvas canvas,
    Size size,
    double horizonY,
  ) {
    final double groundHeight = size.height - horizonY;

    // 0A. Far-Bank Illuminated Eiffel / Galata-style Panoramic Landmark Tower at -18°
    final double? towerX = _worldAngleToScreenX(-18.0, size, margin: 380);
    if (towerX != null) {
      final double towerBaseY = horizonY + groundHeight * 0.03;
      canvas.save();
      canvas.translate(towerX, towerBaseY);
      canvas.scale(1.65);

      // Warm golden beacon halo at top
      canvas.drawCircle(
        const Offset(0, -142),
        46,
        Paint()
          ..shader = ui.Gradient.radial(
            const Offset(0, -142),
            46,
            [
              const Color(0xFFFFE082).withValues(alpha: 0.48),
              Colors.transparent,
            ],
          ),
      );

      // Stone & iron cylindrical Galata/Eiffel hybrid landmark tower
      final Path towerBody = Path()
        ..moveTo(-26, 0)
        ..lineTo(-18, -98)
        ..lineTo(18, -98)
        ..lineTo(26, 0)
        ..close();
      canvas.drawPath(towerBody, Paint()..color = const Color(0xFF4A3F55));
      // Observation gallery & illuminated arches
      canvas.drawRect(
        const Rect.fromLTWH(-22, -106, 44, 9),
        Paint()..color = const Color(0xFFD4AF37),
      );
      for (int a = -2; a <= 2; a++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(a * 6.5, -86), width: 4.2, height: 10),
            const Radius.circular(2),
          ),
          Paint()..color = const Color(0xFFFFE082),
        );
      }
      // Conical copper-patina roof & spire
      final Path cone = Path()
        ..moveTo(-21, -106)
        ..lineTo(0, -146)
        ..lineTo(21, -106)
        ..close();
      canvas.drawPath(cone, Paint()..color = const Color(0xFF264653));
      canvas.drawLine(
        const Offset(0, -146),
        const Offset(0, -164),
        Paint()
          ..color = const Color(0xFFFFD54F)
          ..strokeWidth = 2.2,
      );
      //Rotating searchlight beam in night/rain/sunset
      if (_isNightOrRain) {
        final double beamSwing = math.sin(time * 0.9) * 55.0;
        final Path searchBeam = Path()
          ..moveTo(0, -142)
          ..lineTo(beamSwing - 95, -220)
          ..lineTo(beamSwing + 95, -220)
          ..close();
        canvas.drawPath(
          searchBeam,
          Paint()
            ..shader = ui.Gradient.linear(
              const Offset(0, -142),
              Offset(beamSwing, -220),
              [
                const Color(0xFFFFF59D).withValues(alpha: 0.26),
                Colors.transparent,
              ],
            ),
        );
      }
      canvas.restore();
    }

    // 0B. Far-Bank Illuminated Domed Basilica at +22°
    final double? basilicaX = _worldAngleToScreenX(22.0, size, margin: 380);
    if (basilicaX != null) {
      final double basilicaY = horizonY + groundHeight * 0.03;
      canvas.save();
      canvas.translate(basilicaX, basilicaY);
      canvas.scale(1.65);

      // Pediment & colonnade base
      canvas.drawRect(
        const Rect.fromLTWH(-44, -52, 88, 52),
        Paint()..color = const Color(0xFF433B52),
      );
      final Path pediment = Path()
        ..moveTo(-48, -52)
        ..lineTo(0, -72)
        ..lineTo(48, -52)
        ..close();
      canvas.drawPath(pediment, Paint()..color = const Color(0xFF5A506B));
      // Grand illuminated central dome & flanking cupolas
      canvas.drawArc(
        Rect.fromCenter(center: const Offset(0, -68), width: 52, height: 58),
        math.pi,
        math.pi,
        true,
        Paint()..color = const Color(0xFF344E5C),
      );
      for (final double dx in [-32.0, 32.0]) {
        canvas.drawArc(
          Rect.fromCenter(center: Offset(dx, -52), width: 22, height: 26),
          math.pi,
          math.pi,
          true,
          Paint()..color = const Color(0xFF344E5C),
        );
      }
      // Rose window & warm colonnade lights
      canvas.drawCircle(
        const Offset(0, -34),
        8.5,
        Paint()..color = const Color(0xFFFFCA28).withValues(alpha: 0.85),
      );
      for (int c = -3; c <= 3; c++) {
        canvas.drawRect(
          Rect.fromCenter(center: Offset(c * 10.5, -14), width: 4.5, height: 18),
          Paint()..color = const Color(0xFFFFE082).withValues(alpha: 0.72),
        );
      }
      canvas.restore();
    }

    // 1. 3-Arch Stone & Iron River Bridge at 0° (scale 1.65x)
    final double? bridgeX = _worldAngleToScreenX(0.0, size, margin: 450);
    if (bridgeX != null) {
      final double bridgeY = horizonY + groundHeight * 0.11;
      canvas.save();
      canvas.translate(bridgeX, bridgeY);
      canvas.scale(1.65);

      // Bridge stone deck & arches
      final Path bridgePath = Path()
        ..moveTo(-150, -22)
        ..lineTo(150, -22)
        ..lineTo(150, 12)
        ..lineTo(110, 12)
        ..arcToPoint(
          const Offset(45, 12),
          radius: const Radius.elliptical(32, 24),
          clockwise: false,
        )
        ..lineTo(32, 12)
        ..arcToPoint(
          const Offset(-32, 12),
          radius: const Radius.elliptical(32, 26),
          clockwise: false,
        )
        ..lineTo(-45, 12)
        ..arcToPoint(
          const Offset(-110, 12),
          radius: const Radius.elliptical(32, 24),
          clockwise: false,
        )
        ..lineTo(-150, 12)
        ..close();

      canvas.drawPath(bridgePath, Paint()..color = const Color(0xFF4A4656));
      canvas.drawPath(
        bridgePath,
        Paint()
          ..color = const Color(0xFF7E788C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );

      // Ornate bridge streetlamps along the parapet
      for (final double lx in [-95.0, -38.0, 38.0, 95.0]) {
        canvas.drawLine(
          Offset(lx, -22),
          Offset(lx, -44),
          Paint()
            ..color = const Color(0xFF1F242D)
            ..strokeWidth = 2.2,
        );
        canvas.drawCircle(
          Offset(lx, -46),
          7.0,
          Paint()
            ..color = const Color(0xFFFFE082).withValues(alpha: 0.38),
        );
        canvas.drawCircle(
          Offset(lx, -46),
          3.2,
          Paint()..color = const Color(0xFFFFF8E1),
        );
      }
      canvas.restore();
    }

    // 2. 2 Illuminated Canal Dinner Boats (Bateaux-Mouches) gliding across the water
    for (int b = 0; b < 2; b++) {
      final double dir = b == 0 ? 1.0 : -1.0;
      final double boatDeg = -36.0 + ((time * 3.5 * dir + b * 42.0) % 72.0);
      final double? bx = _worldAngleToScreenX(boatDeg, size, margin: 260);
      if (bx == null) continue;
      final double by = horizonY + groundHeight * (b == 0 ? 0.08 : 0.14);

      canvas.save();
      canvas.translate(bx, by);
      canvas.scale(1.65 * dir, 1.65);

      // Hull
      final Path hull = Path()
        ..moveTo(-42, 0)
        ..lineTo(44, 0)
        ..lineTo(34, 10)
        ..lineTo(-34, 10)
        ..close();
      canvas.drawPath(hull, Paint()..color = const Color(0xFF1E293B));

      // Illuminated glass cabin roof
      final Path cabin = Path()
        ..moveTo(-28, 0)
        ..lineTo(-22, -10)
        ..lineTo(24, -10)
        ..lineTo(30, 0)
        ..close();
      canvas.drawPath(
        cabin,
        Paint()..color = const Color(0xFFFFECB3).withValues(alpha: 0.85),
      );
      canvas.drawPath(
        cabin,
        Paint()
          ..color = const Color(0xFFE65100)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      // Warm reflection under boat
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, 13), width: 68, height: 6),
        Paint()..color = const Color(0xFFFFD54F).withValues(alpha: 0.35),
      );
      canvas.restore();
    }

    // 3. Vintage Wrought-Iron Tram Stop Shelter (+38°) with illuminated route map & waiting passengers
    final double? stopX = _worldAngleToScreenX(38.0, size, margin: 320);
    if (stopX != null) {
      final double stopY = horizonY + groundHeight * 0.22;
      canvas.save();
      canvas.translate(stopX, stopY);
      canvas.scale(1.65);

      // Arched wrought-iron pavilion roof & glass back wall
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-28, -44, 56, 44),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFF1B3B2B).withValues(alpha: 0.85),
      );
      canvas.drawRect(
        const Rect.fromLTWH(-24, -38, 30, 30),
        Paint()..color = const Color(0xFFB3E5FC).withValues(alpha: 0.32),
      );
      // Illuminated city route map lightbox
      canvas.drawRect(
        const Rect.fromLTWH(8, -38, 16, 28),
        Paint()..color = const Color(0xFFFFF8E1),
      );
      canvas.drawLine(
        const Offset(11, -32),
        const Offset(21, -16),
        Paint()
          ..color = const Color(0xFFD32F2F)
          ..strokeWidth = 1.6,
      );
      // Arched canopy header with "TRAMWAY" sign
      final Path roof = Path()
        ..moveTo(-32, -44)
        ..quadraticBezierTo(0, -56, 32, -44)
        ..close();
      canvas.drawPath(roof, Paint()..color = const Color(0xFF122A1E));
      // Waiting passenger under shelter
      _drawArticulatedPerson(
        canvas,
        const Offset(-8, 2),
        coatColor: const Color(0xFF3949AB),
        scarfColor: const Color(0xFFFFCA28),
        sway: math.sin(time * 2.0) * 1.0,
      );
      canvas.restore();
    }

    // 4. Vintage Yellow & Red Electric Tram (-38°..+46°, 1.65x scale)
    final double? trackLeftX = _worldAngleToScreenX(-58.0, size, margin: 1200);
    final double? trackRightX = _worldAngleToScreenX(58.0, size, margin: 1200);
    if (trackLeftX != null &&
        trackRightX != null &&
        trackRightX > trackLeftX) {
      final double trackY = horizonY + groundHeight * 0.22;
      final double wireY = trackY - 128.0;
      canvas.drawLine(
        Offset(trackLeftX, wireY),
        Offset(trackRightX, wireY),
        Paint()
          ..color = const Color(0xFF263238).withValues(alpha: 0.75)
          ..strokeWidth = 1.5,
      );
      canvas.drawLine(
        Offset(trackLeftX, trackY),
        Offset(trackRightX, trackY),
        Paint()
          ..color = const Color(0xFF90A4AE).withValues(alpha: 0.58)
          ..strokeWidth = 2.4,
      );
      canvas.drawLine(
        Offset(trackLeftX, trackY + 7),
        Offset(trackRightX, trackY + 7),
        Paint()
          ..color = const Color(0xFF90A4AE).withValues(alpha: 0.58)
          ..strokeWidth = 2.4,
      );
    }

    final double tramPhase = (time * 0.09) % 1.0;
    final double tramDeg = -38.0 + tramPhase * 84.0;
    final double? tramX = _worldAngleToScreenX(tramDeg, size, margin: 380);
    if (tramX != null) {
      final double tramY = horizonY + groundHeight * 0.22;
      canvas.save();
      canvas.translate(tramX, tramY);
      canvas.scale(1.65);

      // Tram shadow
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, 4), width: 148, height: 14),
        Paint()..color = Colors.black.withValues(alpha: 0.45),
      );

      // Lower crimson body + upper vintage mustard-yellow cabin
      final RRect lowerBody = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-68, -32, 136, 28),
        const Radius.circular(6),
      );
      canvas.drawRRect(lowerBody, Paint()..color = const Color(0xFFB71C1C));

      final RRect upperBody = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-66, -58, 132, 28),
        const Radius.circular(6),
      );
      canvas.drawRRect(upperBody, Paint()..color = const Color(0xFFFBC02D));

      // Roof clerestory & diamond pantograph reaching overhead wire
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-54, -65, 108, 7),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xFF37474F),
      );
      final Path pantograph = Path()
        ..moveTo(-12, -65)
        ..lineTo(0, -78)
        ..lineTo(12, -65)
        ..moveTo(-12, -65)
        ..lineTo(0, -58)
        ..lineTo(12, -65);
      canvas.drawPath(
        pantograph,
        Paint()
          ..color = const Color(0xFF263238)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
      // Electric spark on pantograph
      if ((time * 7).floor() % 5 == 0) {
        canvas.drawCircle(
          const Offset(0, -78),
          5.5,
          Paint()..color = const Color(0xFF80D8FF),
        );
      }

      // 5 glowing tram windows with passenger silhouettes inside
      for (int w = 0; w < 5; w++) {
        final double wx = -54.0 + w * 23.5;
        final RRect winRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(wx, -53, 18, 19),
          const Radius.circular(3),
        );
        canvas.drawRRect(
          winRect,
          Paint()..color = const Color(0xFFFFF59D),
        );
        // Passenger head & shoulders silhouette
        canvas.drawCircle(
          Offset(wx + 9, -43),
          3.8,
          Paint()..color = const Color(0xFF3E2723),
        );
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(wx + 9, -35),
            width: 11,
            height: 9,
          ),
          math.pi,
          math.pi,
          true,
          Paint()..color = const Color(0xFF3E2723),
        );
      }

      // Warm golden headlight beam & wheels
      final Path beam = Path()
        ..moveTo(68, -20)
        ..lineTo(135, -36)
        ..lineTo(135, 6)
        ..close();
      canvas.drawPath(
        beam,
        Paint()
          ..shader = ui.Gradient.linear(
            const Offset(68, -18),
            const Offset(135, -18),
            [
              const Color(0xFFFFF59D).withValues(alpha: 0.55),
              Colors.transparent,
            ],
          ),
      );
      canvas.drawCircle(
        const Offset(68, -20),
        4.5,
        Paint()..color = const Color(0xFFFFFDE7),
      );
      for (final double wheelX in [-46.0, -22.0, 22.0, 46.0]) {
        canvas.drawCircle(
          Offset(wheelX, -2),
          6.0,
          Paint()..color = const Color(0xFF212121),
        );
      }
      canvas.restore();
    }
  }

  // ===========================================================================
  // 3. 74° ZONE — MONTMARTRE PAINTER, GRAND PLAZA FOUNTAIN, TRIO & COLONNE MORRIS
  // ===========================================================================
  void _drawGrandFountainMusiciansAndCart(
    Canvas canvas,
    Size size,
    double horizonY,
  ) {
    final double groundHeight = size.height - horizonY;

    // 3A. Montmartre Street Painter at a Wooden Easel (58°, 1.75x scale) under a warm lamp
    final double? painterX = _worldAngleToScreenX(58.0, size, margin: 340);
    if (painterX != null) {
      final double painterY = horizonY + groundHeight * 0.20;
      canvas.save();
      canvas.translate(painterX, painterY);
      canvas.scale(1.75);

      // Warm pool of light under the easel
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, 8), width: 72, height: 16),
        Paint()..color = const Color(0xFFFFD54F).withValues(alpha: 0.28),
      );

      // Artist wearing beret & holding palette
      _drawArticulatedPerson(
        canvas,
        const Offset(-14, 4),
        coatColor: const Color(0xFF283593),
        scarfColor: const Color(0xFFE53935),
        sway: math.sin(time * 2.6) * 1.4,
      );
      // French beret on artist's head
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(-14, -28), width: 11, height: 4.5),
        Paint()..color = const Color(0xFFB71C1C),
      );
      // Wooden tripod easel & framed sunset canvas
      final Paint easelPaint = Paint()
        ..color = const Color(0xFF6D4C41)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(8, 6), const Offset(16, -34), easelPaint);
      canvas.drawLine(const Offset(24, 6), const Offset(16, -34), easelPaint);
      canvas.drawLine(const Offset(16, 6), const Offset(16, -34), easelPaint);
      // Canvas with miniature Parisian bridge & sunset painting
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(5, -29, 22, 16),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFFFFF8E1),
      );
      canvas.drawRect(
        const Rect.fromLTWH(7, -27, 18, 7),
        Paint()..color = const Color(0xFFFF8A65),
      );
      canvas.drawRect(
        const Rect.fromLTWH(7, -20, 18, 5),
        Paint()..color = const Color(0xFF1E88E5),
      );
      // Warm brass clip-lamp illuminating the canvas
      canvas.drawCircle(
        const Offset(16, -33),
        5.0,
        Paint()..color = const Color(0xFFFFE082).withValues(alpha: 0.65),
      );
      canvas.restore();
    }

    // 3B. Classic Green Domed Morris Poster Column (Colonne Morris, 88°)
    final double? morrisX = _worldAngleToScreenX(88.0, size, margin: 320);
    if (morrisX != null) {
      final double morrisY = horizonY + groundHeight * 0.19;
      canvas.save();
      canvas.translate(morrisX, morrisY);
      canvas.scale(1.75);

      // Cylindrical column body
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-14, -56, 28, 56),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xFF1B4332),
      );
      // Wrap-around vintage theater & cabaret posters (yellow, crimson, cyan)
      canvas.drawRect(
        const Rect.fromLTWH(-11, -46, 10, 18),
        Paint()..color = const Color(0xFFFFCA28),
      );
      canvas.drawRect(
        const Rect.fromLTWH(1, -46, 10, 18),
        Paint()..color = const Color(0xFFD32F2F),
      );
      canvas.drawRect(
        const Rect.fromLTWH(-11, -24, 22, 14),
        Paint()..color = const Color(0xFFFFF8E1),
      );
      // Ornate hexagonal green canopy dome & brass finial spire
      final Path dome = Path()
        ..moveTo(-18, -56)
        ..quadraticBezierTo(0, -74, 18, -56)
        ..close();
      canvas.drawPath(dome, Paint()..color = const Color(0xFF2D6A4F));
      canvas.drawLine(
        const Offset(0, -68),
        const Offset(0, -80),
        Paint()
          ..color = const Color(0xFFFFD54F)
          ..strokeWidth = 2.0,
      );
      canvas.restore();
    }

    // 3C. Grand 3-Tiered Sculpted Plaza Fountain (74°, 1.72x scale)
    final double? fx = _worldAngleToScreenX(74.0, size, margin: 450);
    if (fx == null) return;

    final double fy = horizonY + groundHeight * 0.19;
    canvas.save();
    canvas.translate(fx, fy);
    canvas.scale(1.72);

    // Wet plaza halo under the fountain
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 12), width: 220, height: 42),
      Paint()
        ..shader = ui.Gradient.radial(
          const Offset(0, 12),
          110,
          [
            const Color(0xFF4FC3F7).withValues(alpha: 0.34),
            const Color(0xFFFFB74D).withValues(alpha: 0.20),
            Colors.transparent,
          ],
          const [0.0, 0.6, 1.0],
        ),
    );

    // Ornate 3-tiered stone plaza water fountain
    // Bottom pool basin
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 6), width: 136, height: 28),
      Paint()..color = const Color(0xFF5C586B),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 3), width: 122, height: 21),
      Paint()..color = const Color(0xFF0288D1),
    );
    // Glowing underwater pool lights
    for (final double lx in [-38.0, 0.0, 38.0]) {
      canvas.drawCircle(
        Offset(lx, 4),
        9.0,
        Paint()..color = const Color(0xFF80D8FF).withValues(alpha: 0.68),
      );
    }

    // Pedestal & Tier 2
    canvas.drawRect(
      const Rect.fromLTWH(-14, -34, 28, 38),
      Paint()..color = const Color(0xFF726D82),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -34), width: 84, height: 16),
      Paint()..color = const Color(0xFF6A657A),
    );
    // Pedestal & Tier 3
    canvas.drawRect(
      const Rect.fromLTWH(-9, -66, 18, 32),
      Paint()..color = const Color(0xFF7E798E),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -66), width: 48, height: 11),
      Paint()..color = const Color(0xFF8A849B),
    );
    // Top finial
    canvas.drawCircle(
      const Offset(0, -78),
      7.0,
      Paint()..color = const Color(0xFF9E98B0),
    );

    // Animated splashing cyan & golden water arcs
    final Paint waterArcPaint = Paint()
      ..color = const Color(0xFFB3E5FC).withValues(alpha: 0.80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final Paint goldSprayPaint = Paint()
      ..color = const Color(0xFFFFE082).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (int side in [-1, 1]) {
      final double surge = math.sin(time * 4.2 + side) * 4.0;
      final Path topArc = Path()
        ..moveTo(0, -82)
        ..quadraticBezierTo(side * 22.0, -102 + surge, side * 22.0, -66);
      final Path midArc = Path()
        ..moveTo(side * 22.0, -66)
        ..quadraticBezierTo(side * 42.0, -62 + surge, side * 38.0, -34);
      final Path lowArc = Path()
        ..moveTo(side * 38.0, -34)
        ..quadraticBezierTo(side * 60.0, -24 + surge, side * 54.0, 2);
      canvas.drawPath(topArc, waterArcPaint);
      canvas.drawPath(midArc, waterArcPaint);
      canvas.drawPath(lowArc, waterArcPaint);
      canvas.drawPath(midArc, goldSprayPaint);
    }

    // Street Musician Trio on the right side of the fountain (Violinist, Accordionist, Upright Bassist)
    _drawArticulatedPerson(
      canvas,
      const Offset(80, 8),
      coatColor: const Color(0xFF4A148C),
      scarfColor: const Color(0xFFFFD54F),
      sway: math.sin(time * 3.8) * 3.0,
      hasViolin: true,
    );
    _drawArticulatedPerson(
      canvas,
      const Offset(104, 11),
      coatColor: const Color(0xFF1B5E20),
      scarfColor: const Color(0xFFFF7043),
      sway: math.cos(time * 3.8) * 3.0,
      hasGuitar: true,
    );
    // Upright Bassist with wooden double bass
    _drawArticulatedPerson(
      canvas,
      const Offset(128, 10),
      coatColor: const Color(0xFF263238),
      scarfColor: const Color(0xFFFFCA28),
      sway: math.sin(time * 3.2 + 1.0) * 2.5,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(121, -4), width: 11, height: 18),
      Paint()..color = const Color(0xFF6D4C41),
    );
    canvas.drawLine(
      const Offset(121, -24),
      const Offset(121, 5),
      Paint()
        ..color = const Color(0xFF3E2723)
        ..strokeWidth = 2.0,
    );

    // Open velvet-lined instrument case with golden coins
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(96, 20), width: 24, height: 9),
      Paint()..color = const Color(0xFF212121),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(96, 20), width: 19, height: 6),
      Paint()..color = const Color(0xFFB71C1C),
    );
    canvas.drawCircle(
      const Offset(95, 20),
      2.2,
      Paint()..color = const Color(0xFFFFD54F),
    );

    // Floating golden musical notes above the trio
    for (int n = 0; n < 4; n++) {
      final double np = (time * 0.55 + n * 0.25) % 1.0;
      final double nx = 88.0 + n * 9.0 + math.sin(time * 3.0 + n) * 5.0;
      final double ny = -34.0 - np * 36.0;
      final double alpha = math.sin(np * math.pi).clamp(0.0, 1.0);
      final Paint npaint = Paint()
        ..color = const Color(0xFFFFD54F).withValues(alpha: alpha)
        ..strokeWidth = 1.8;
      canvas.drawCircle(Offset(nx, ny), 3.0, npaint);
      canvas.drawLine(Offset(nx + 2.5, ny), Offset(nx + 2.5, ny - 9), npaint);
    }

    // 4 Applauding / Chatting Pedestrians watching the musicians
    _drawArticulatedPerson(
      canvas,
      const Offset(152, 16),
      coatColor: const Color(0xFF0D47A1),
      scarfColor: const Color(0xFFFFECB3),
      sway: math.sin(time * 2.5) * 1.5,
      chatBubble: true,
    );
    _drawArticulatedPerson(
      canvas,
      const Offset(170, 18),
      coatColor: const Color(0xFF880E4F),
      scarfColor: const Color(0xFF80DEEA),
      sway: -math.sin(time * 2.5) * 1.5,
    );
    _drawArticulatedPerson(
      canvas,
      const Offset(-58, 15),
      coatColor: const Color(0xFF3E2723),
      scarfColor: const Color(0xFFFFAB91),
      sway: math.sin(time * 2.1) * 1.5,
      chatBubble: true,
    );
    _drawArticulatedPerson(
      canvas,
      const Offset(-78, 17),
      coatColor: const Color(0xFF263238),
      scarfColor: const Color(0xFFFFF59D),
      sway: math.cos(time * 2.1) * 1.5,
    );

    // Vintage Roasted Chestnut & Coffee Cart with vendor (-126, 10)
    canvas.save();
    canvas.translate(-126, 10);
    // Vendor behind cart
    _drawArticulatedPerson(
      canvas,
      const Offset(0, -4),
      coatColor: const Color(0xFF4E342E),
      scarfColor: const Color(0xFFD32F2F),
      sway: math.sin(time * 2.0) * 1.2,
    );
    // Wooden & brass cart body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-26, -22, 52, 24),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF6D4C41),
    );
    // Glowing brazier coals
    canvas.drawRect(
      const Rect.fromLTWH(-18, -27, 22, 5),
      Paint()..color = const Color(0xFFFF6D00),
    );
    // Striped canopy roof
    final Path canopy = Path()
      ..moveTo(-32, -48)
      ..lineTo(32, -48)
      ..lineTo(26, -58)
      ..lineTo(-26, -58)
      ..close();
    canvas.drawPath(canopy, Paint()..color = const Color(0xFFC62828));
    // Spoked wooden wheel
    canvas.drawCircle(
      const Offset(-12, 4),
      9.0,
      Paint()
        ..color = const Color(0xFFFFB300)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
    // Rising roasted chestnut steam puffs
    for (int s = 0; s < 3; s++) {
      final double sp = (time * 0.6 + s * 0.33) % 1.0;
      canvas.drawCircle(
        Offset(-8 + math.sin(time * 2.5 + s) * 4.0, -30 - sp * 26.0),
        4.0 + sp * 5.0,
        Paint()
          ..color = Colors.white.withValues(
            alpha: (1.0 - sp) * 0.42,
          ),
      );
    }
    canvas.restore();

    canvas.restore();
  }

  // ===========================================================================
  // 4. CONTINUOUS 360° EUROPEAN CITYSCAPE (62°..298°), CAFÉ DE NUIT & BOOKSHOP
  // ===========================================================================
  void _drawEuropeanTownhousesAndShops(
    Canvas canvas,
    Size size,
    double horizonY,
  ) {
    final double groundHeight = size.height - horizonY;

    // Continuous, gap-free 360° Old European Cityscape Panorama (62°..298°)
    // 18 grand interconnected Haussmann, Baroque, Amsterdam-stepped-gable, and Art Nouveau buildings
    final List<Color> facadeColors = const [
      Color(0xFF8D6E63),
      Color(0xFF9E7B66),
      Color(0xFF785A4E),
      Color(0xFFA1887F),
      Color(0xFF6D5950),
      Color(0xFF8C7365),
      Color(0xFF7E685B),
      Color(0xFF947664),
    ];

    for (int t = 0; t < 18; t++) {
      final double tDeg = 64.0 + t * 13.5;
      final double? tx = _worldAngleToScreenX(tDeg, size, margin: 460);
      if (tx == null) continue;

      final double ty = horizonY + groundHeight * 0.17;
      canvas.save();
      canvas.translate(tx, ty);
      canvas.scale(1.78);

      final double bw = 96.0 + (t % 3) * 12.0; // 96px..120px wide (zero sky gaps!)
      final double bh = 136.0 + (t % 4) * 12.0;

      // Stone/brick architectural facade
      canvas.drawRect(
        Rect.fromLTWH(-bw * 0.5, -bh, bw, bh),
        Paint()..color = facadeColors[t % facadeColors.length],
      );
      // Horizontal Haussmann stone cornice belts
      canvas.drawRect(
        Rect.fromLTWH(-bw * 0.5, -bh + 44, bw, 3.5),
        Paint()..color = const Color(0xFFD7CCC8).withValues(alpha: 0.45),
      );
      canvas.drawRect(
        Rect.fromLTWH(-bw * 0.5, -bh + 88, bw, 3.5),
        Paint()..color = const Color(0xFFD7CCC8).withValues(alpha: 0.45),
      );
      canvas.drawRect(
        Rect.fromLTWH(-bw * 0.5, -bh, bw, bh),
        Paint()
          ..color = const Color(0xFF3E2723).withValues(alpha: 0.48)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      // Architectural Roofline Variety: Haussmann Mansard, Amsterdam Stepped Gable, or Baroque Dome
      final int roofStyle = t % 3;
      if (roofStyle == 0) {
        // Parisian Haussmann Mansard slate roof & dormer windows
        final Path roof = Path()
          ..moveTo(-bw * 0.52, -bh)
          ..lineTo(bw * 0.52, -bh)
          ..lineTo(bw * 0.42, -bh - 28)
          ..lineTo(-bw * 0.42, -bh - 28)
          ..close();
        canvas.drawPath(roof, Paint()..color = const Color(0xFF263238));
        for (final double dx in [-bw * 0.22, bw * 0.22]) {
          canvas.drawRect(
            Rect.fromCenter(center: Offset(dx, -bh - 12), width: 12, height: 14),
            Paint()..color = const Color(0xFFFFE082).withValues(alpha: 0.80),
          );
        }
      } else if (roofStyle == 1) {
        // Amsterdam Stepped Gable roofline
        final Path gable = Path()
          ..moveTo(-bw * 0.48, -bh)
          ..lineTo(-bw * 0.48, -bh - 10)
          ..lineTo(-bw * 0.30, -bh - 10)
          ..lineTo(-bw * 0.30, -bh - 20)
          ..lineTo(-bw * 0.14, -bh - 20)
          ..lineTo(-bw * 0.14, -bh - 30)
          ..lineTo(bw * 0.14, -bh - 30)
          ..lineTo(bw * 0.14, -bh - 20)
          ..lineTo(bw * 0.30, -bh - 20)
          ..lineTo(bw * 0.30, -bh - 10)
          ..lineTo(bw * 0.48, -bh - 10)
          ..lineTo(bw * 0.48, -bh)
          ..close();
        canvas.drawPath(gable, Paint()..color = const Color(0xFF4E342E));
      } else {
        // Art Nouveau / Baroque Turret Dome & terracotta chimneys
        final Path mansard = Path()
          ..moveTo(-bw * 0.52, -bh)
          ..lineTo(bw * 0.52, -bh)
          ..lineTo(bw * 0.44, -bh - 24)
          ..lineTo(-bw * 0.44, -bh - 24)
          ..close();
        canvas.drawPath(mansard, Paint()..color = const Color(0xFF2C3E50));
        canvas.drawArc(
          Rect.fromCenter(center: Offset(0, -bh - 20), width: 34, height: 32),
          math.pi,
          math.pi,
          true,
          Paint()..color = const Color(0xFF344E5C),
        );
      }

      // Terracotta chimney pots
      canvas.drawRect(
        Rect.fromLTWH(-bw * 0.34, -bh - 36, 8, 10),
        Paint()..color = const Color(0xFF8D4E38),
      );
      canvas.drawRect(
        Rect.fromLTWH(bw * 0.26, -bh - 36, 8, 10),
        Paint()..color = const Color(0xFF8D4E38),
      );

      // Upstairs apartment windows (2 floors x 3 columns) with warm light, silhouettes & Juliet balconies
      for (int floor = 0; floor < 2; floor++) {
        final double wy = -bh + 14.0 + floor * 42.0;
        for (int col = 0; col < 3; col++) {
          final double wx = -34.0 + col * 27.0;
          final RRect winR = RRect.fromRectAndRadius(
            Rect.fromLTWH(wx, wy, 15, 26),
            const Radius.circular(2.5),
          );
          final bool warmLit = (t + floor + col) % 3 != 0;
          canvas.drawRRect(
            winR,
            Paint()
              ..color = warmLit
                  ? const Color(0xFFFFE082)
                  : const Color(0xFF37474F),
          );

          if (warmLit && floor == 0 && col == 0) {
            canvas.drawCircle(
              Offset(wx + 7.5, wy + 16),
              3.5,
              Paint()..color = const Color(0xFF3E2723),
            );
          } else if (warmLit && floor == 1 && col == 2) {
            canvas.drawCircle(
              Offset(wx + 7.5, wy + 8),
              4.0,
              Paint()..color = const Color(0xFF2E7D32),
            );
          }

          // Wrought-iron Juliet balcony & flower box
          canvas.drawRect(
            Rect.fromLTWH(wx - 1.5, wy + 19, 18, 7),
            Paint()
              ..color = const Color(0xFF1C2026)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.3,
          );
          canvas.drawRect(
            Rect.fromLTWH(wx + 1, wy + 23, 13, 3.5),
            Paint()..color = const Color(0xFF5D4037),
          );
          canvas.drawCircle(
            Offset(wx + 5, wy + 22),
            2.2,
            Paint()..color = const Color(0xFFE91E63),
          );
          canvas.drawCircle(
            Offset(wx + 10, wy + 22),
            2.2,
            Paint()..color = const Color(0xFFFFC107),
          );
        }
      }
      canvas.restore();
    }

    // Corner French Bistro ("Café de Nuit") at 124°, scale 1.75x
    final double? bistroX = _worldAngleToScreenX(124.0, size, margin: 450);
    if (bistroX != null) {
      final double bistroY = horizonY + groundHeight * 0.19;
      canvas.save();
      canvas.translate(bistroX, bistroY);
      canvas.scale(1.75);

      // Upstairs Juliet Balcony Saxophonist performing live above Café de Nuit
      canvas.save();
      canvas.translate(0, -78);
      canvas.drawRect(
        const Rect.fromLTWH(-18, -8, 36, 10),
        Paint()
          ..color = const Color(0xFF1B1D24)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
      _drawArticulatedPerson(
        canvas,
        const Offset(0, 2),
        coatColor: const Color(0xFF1A237E),
        scarfColor: const Color(0xFFFFD54F),
        sway: math.sin(time * 4.0) * 2.2,
      );
      // Golden saxophone & floating balcony notes
      canvas.drawCircle(
        const Offset(8, -12),
        3.5,
        Paint()..color = const Color(0xFFFFCA28),
      );
      for (int n = 0; n < 3; n++) {
        final double np = (time * 0.6 + n * 0.33) % 1.0;
        canvas.drawCircle(
          Offset(14.0 + n * 6.0, -18.0 - np * 22.0),
          2.2,
          Paint()
            ..color = const Color(0xFFFFD54F)
                .withValues(alpha: (1.0 - np).clamp(0.0, 1.0)),
        );
      }
      canvas.restore();

      // Warm golden glass storefront glow on the cobblestones
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, 14), width: 170, height: 34),
        Paint()
          ..shader = ui.Gradient.radial(
            const Offset(0, 14),
            85,
            [
              const Color(0xFFFFB74D).withValues(alpha: 0.48),
              Colors.transparent,
            ],
          ),
      );

      // Ground-floor wooden bistro facade & golden windows
      canvas.drawRect(
        const Rect.fromLTWH(-64, -48, 128, 48),
        Paint()..color = const Color(0xFF4E1C1A),
      );
      canvas.drawRect(
        const Rect.fromLTWH(-56, -40, 48, 34),
        Paint()..color = const Color(0xFFFFE082),
      );
      canvas.drawRect(
        const Rect.fromLTWH(8, -40, 48, 34),
        Paint()..color = const Color(0xFFFFE082),
      );

      // Red-and-cream striped awning
      for (int s = 0; s < 10; s++) {
        final double sx = -66.0 + s * 13.2;
        final Path stripe = Path()
          ..moveTo(sx, -48)
          ..lineTo(sx + 13.2, -48)
          ..lineTo(sx + 11.2, -36)
          ..lineTo(sx - 2.0, -36)
          ..close();
        canvas.drawPath(
          stripe,
          Paint()
            ..color = s.isEven
                ? const Color(0xFFC62828)
                : const Color(0xFFFFF8E1),
        );
      }

      // Festoon string lights along the terrace
      for (int b = 0; b < 9; b++) {
        final double bx = -60.0 + b * 15.0;
        final double by = -33.0 + math.sin(b * 0.8) * 2.5;
        canvas.drawCircle(
          Offset(bx, by),
          4.2,
          Paint()..color = const Color(0xFFFFD54F).withValues(alpha: 0.45),
        );
        canvas.drawCircle(
          Offset(bx, by),
          2.0,
          Paint()..color = const Color(0xFFFFFDE7),
        );
      }

      // Brass patio heaters & 3 outdoor bistro tables with 6 seated patrons + waiter
      for (final double hx in [-56.0, 56.0]) {
        canvas.drawLine(
          Offset(hx, 8),
          Offset(hx, -26),
          Paint()
            ..color = const Color(0xFFD4AF37)
            ..strokeWidth = 2.0,
        );
        canvas.drawCircle(
          Offset(hx, -26),
          6.0,
          Paint()..color = const Color(0xFFFF6D00).withValues(alpha: 0.68),
        );
      }

      for (int tbl = 0; tbl < 3; tbl++) {
        final double tx = -38.0 + tbl * 38.0;
        // Bistro round table with white tablecloth
        canvas.drawLine(
          Offset(tx, 14),
          Offset(tx, 2),
          Paint()
            ..color = const Color(0xFF212121)
            ..strokeWidth = 2.0,
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(tx, 2), width: 22, height: 7),
          Paint()..color = const Color(0xFFFFF8E1),
        );
        // Wine glass / coffee cup
        canvas.drawCircle(
          Offset(tx - 3, 0),
          1.8,
          Paint()..color = const Color(0xFF880E4F),
        );
        canvas.drawCircle(
          Offset(tx + 4, 0),
          1.8,
          Paint()..color = const Color(0xFFFFFDE7),
        );
      }

      // 6 seated patrons sipping coffee/wine and chatting (•••)
      _drawArticulatedPerson(
        canvas,
        const Offset(-48, 12),
        coatColor: const Color(0xFF283593),
        scarfColor: const Color(0xFFFFCC80),
        sway: math.sin(time * 2.2) * 1.2,
        chatBubble: true,
      );
      _drawArticulatedPerson(
        canvas,
        const Offset(-28, 12),
        coatColor: const Color(0xFFAD1457),
        scarfColor: const Color(0xFFFFF59D),
        sway: -math.sin(time * 2.2) * 1.2,
      );
      _drawArticulatedPerson(
        canvas,
        const Offset(-10, 13),
        coatColor: const Color(0xFF00695C),
        scarfColor: const Color(0xFFFFAB91),
        sway: math.cos(time * 2.4) * 1.2,
        chatBubble: true,
      );
      _drawArticulatedPerson(
        canvas,
        const Offset(8, 13),
        coatColor: const Color(0xFF37474F),
        scarfColor: const Color(0xFFFFCC80),
        sway: -math.cos(time * 2.4) * 1.2,
      );
      _drawArticulatedPerson(
        canvas,
        const Offset(28, 12),
        coatColor: const Color(0xFF4E342E),
        scarfColor: const Color(0xFF80DEEA),
        sway: math.sin(time * 2.6) * 1.2,
      );
      _drawArticulatedPerson(
        canvas,
        const Offset(48, 12),
        coatColor: const Color(0xFF6A1B9A),
        scarfColor: const Color(0xFFFFE082),
        sway: -math.sin(time * 2.6) * 1.2,
        chatBubble: true,
      );

      // Waiter carrying a silver tray
      _drawArticulatedPerson(
        canvas,
        const Offset(18, 16),
        coatColor: const Color(0xFF212121),
        scarfColor: const Color(0xFFFFFFFF),
        sway: math.sin(time * 3.2) * 1.5,
      );
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(25, -2), width: 12, height: 4),
        Paint()..color = const Color(0xFFCFD8DC),
      );

      canvas.restore();
    }

    // Vintage Bookstore & Vinyl Record Shop at 148°, scale 1.72x
    final double? bookX = _worldAngleToScreenX(148.0, size, margin: 400);
    if (bookX != null) {
      final double bookY = horizonY + groundHeight * 0.19;
      canvas.save();
      canvas.translate(bookX, bookY);
      canvas.scale(1.72);

      // Heritage forest-green wooden facade
      canvas.drawRect(
        const Rect.fromLTWH(-46, -46, 92, 46),
        Paint()..color = const Color(0xFF1B4332),
      );
      // Warm amber display window with vinyl records & stacked books
      canvas.drawRect(
        const Rect.fromLTWH(-38, -36, 76, 28),
        Paint()..color = const Color(0xFFFFECB3),
      );
      canvas.drawCircle(
        const Offset(-18, -22),
        7.0,
        Paint()..color = const Color(0xFF212121),
      );
      canvas.drawCircle(
        const Offset(-18, -22),
        2.2,
        Paint()..color = const Color(0xFFE53935),
      );
      canvas.drawCircle(
        const Offset(18, -22),
        7.0,
        Paint()..color = const Color(0xFF212121),
      );
      canvas.drawCircle(
        const Offset(18, -22),
        2.2,
        Paint()..color = const Color(0xFF1E88E5),
      );

      // Green & gold awning
      final Path bookAwning = Path()
        ..moveTo(-48, -46)
        ..lineTo(48, -46)
        ..lineTo(44, -35)
        ..lineTo(-44, -35)
        ..close();
      canvas.drawPath(bookAwning, Paint()..color = const Color(0xFF2D6A4F));

      // Outdoor wooden book browser carts
      for (final double cx in [-24.0, 22.0]) {
        canvas.drawRect(
          Rect.fromLTWH(cx - 12, -8, 24, 12),
          Paint()..color = const Color(0xFF6D4C41),
        );
        // Colorful book spines
        for (int b = 0; b < 5; b++) {
          canvas.drawRect(
            Rect.fromLTWH(cx - 10 + b * 4.2, -13, 3.5, 5),
            Paint()
              ..color = b.isEven
                  ? const Color(0xFFD32F2F)
                  : const Color(0xFF1976D2),
          );
        }
      }

      // Customer browsing books under the awning
      _drawArticulatedPerson(
        canvas,
        const Offset(-6, 10),
        coatColor: const Color(0xFF5D4037),
        scarfColor: const Color(0xFFFFCA28),
        sway: math.sin(time * 1.8) * 1.0,
      );
      canvas.restore();
    }
  }

  // ===========================================================================
  // 5. 168° ZONE — LE CHAT NOIR JAZZ MARQUEE & NIGHT RAMEN / CREPE PAVILION
  // ===========================================================================
  void _drawRamenPavilionAndJazzAlley(
    Canvas canvas,
    Size size,
    double horizonY,
  ) {
    final double groundHeight = size.height - horizonY;

    // 5A. Glowing Jazz Club & Cinema Marquee ("LE CHAT NOIR • JAZZ", 162°)
    final double? marqueeX = _worldAngleToScreenX(162.0, size, margin: 420);
    if (marqueeX != null) {
      final double marqueeY = horizonY + groundHeight * 0.19;
      canvas.save();
      canvas.translate(marqueeX, marqueeY);
      canvas.scale(1.72);

      // Velvet club entrance & warm magenta/gold sidewalk reflection
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, 12), width: 130, height: 24),
        Paint()..color = const Color(0xFFE040FB).withValues(alpha: 0.28),
      );
      canvas.drawRect(
        const Rect.fromLTWH(-44, -46, 88, 46),
        Paint()..color = const Color(0xFF1A1026),
      );
      // Crimson velvet curtains in club doorway
      canvas.drawRect(
        const Rect.fromLTWH(-16, -34, 32, 34),
        Paint()..color = const Color(0xFF880E4F),
      );
      // Illuminated Broadway/Parisian bulb-bordered marquee sign
      final RRect marqueeBox = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-52, -62, 104, 18),
        const Radius.circular(4),
      );
      canvas.drawRRect(marqueeBox, Paint()..color = const Color(0xFFFFF8E1));
      canvas.drawRRect(
        marqueeBox,
        Paint()
          ..color = const Color(0xFFD4AF37)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );
      final TextPainter mtp = TextPainter(
        text: const TextSpan(
          text: 'LE CHAT NOIR • JAZZ',
          style: TextStyle(
            color: Color(0xFF1A1026),
            fontSize: 7.2,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      mtp.paint(canvas, Offset(-mtp.width * 0.5, -53 - mtp.height * 0.5));
      canvas.restore();
    }

    // 5B. Late-Night Ramen & Street Crepe Pavilion (170°, yFactor: 0.20, 1.72x scale)
    final double? rx = _worldAngleToScreenX(170.0, size, margin: 480);
    if (rx == null) return;

    final double ry = horizonY + groundHeight * 0.20;
    canvas.save();
    canvas.translate(rx, ry);
    canvas.scale(1.72);

    // Warm neon & lantern reflection pool on the wet cobblestones
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 16), width: 240, height: 48),
      Paint()
        ..shader = ui.Gradient.radial(
          const Offset(0, 16),
          120,
          [
            const Color(0xFFFF5252).withValues(alpha: 0.38),
            const Color(0xFFFFB74D).withValues(alpha: 0.28),
            const Color(0xFFE040FB).withValues(alpha: 0.16),
            Colors.transparent,
          ],
          const [0.0, 0.45, 0.75, 1.0],
        ),
    );

    // Wooden Late-Night Ramen & Street Crepe Pavilion structure
    canvas.drawRect(
      const Rect.fromLTWH(-58, -56, 116, 56),
      Paint()..color = const Color(0xFF3E2723),
    );
    // Warm lit counter interior
    canvas.drawRect(
      const Rect.fromLTWH(-50, -48, 100, 28),
      Paint()..color = const Color(0xFFFFCC80),
    );
    // Chef cooking behind the counter with white toque hat
    canvas.drawCircle(
      const Offset(0, -34),
      5.5,
      Paint()..color = const Color(0xFFFFCCBC),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-5, -45, 10, 8),
        const Radius.circular(3),
      ),
      Paint()..color = Colors.white,
    );
    canvas.drawRect(
      const Rect.fromLTWH(-8, -28, 16, 10),
      Paint()..color = Colors.white,
    );

    // Curved East-meets-Europe tiled pavilion roof
    final Path roof = Path()
      ..moveTo(-70, -56)
      ..quadraticBezierTo(0, -78, 70, -56)
      ..lineTo(62, -48)
      ..lineTo(-62, -48)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFF263238));

    // Hanging red & amber paper lanterns under the eaves
    for (int l = 0; l < 6; l++) {
      final double lx = -50.0 + l * 20.0;
      final double sway = math.sin(time * 2.8 + l) * 1.5;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(lx + sway, -45),
          width: 10,
          height: 14,
        ),
        Paint()
          ..color = l.isEven
              ? const Color(0xFFFF5252)
              : const Color(0xFFFFB300),
      );
    }

    // Glowing vertical & horizontal Neon Signs: JAZZ, RAMEN, CRÊPES
    _drawNeonSignBox(
      canvas,
      const Offset(-82, -74),
      'JAZZ',
      const Color(0xFFE040FB),
    );
    _drawNeonSignBox(
      canvas,
      const Offset(0, -74),
      'RAMEN',
      const Color(0xFFFF5252),
    );
    _drawNeonSignBox(
      canvas,
      const Offset(82, -70),
      'CRÊPES',
      const Color(0xFF00E5FF),
    );

    // Rising noodle & crepe steam clouds
    for (int s = 0; s < 4; s++) {
      final double sp = (time * 0.55 + s * 0.25) % 1.0;
      final double sx = -18.0 + s * 12.0 + math.sin(time * 2.4 + s) * 4.0;
      final double sy = -26.0 - sp * 34.0;
      canvas.drawCircle(
        Offset(sx, sy),
        5.0 + sp * 7.0,
        Paint()
          ..color = Colors.white.withValues(alpha: (1.0 - sp) * 0.38),
      );
    }

    // 7 Articulated People sitting on stools & standing at high tables with umbrellas
    final List<Offset> patronOffsets = const [
      Offset(-92, 12),
      Offset(-68, 14),
      Offset(-38, 12),
      Offset(-12, 14),
      Offset(16, 14),
      Offset(52, 12),
      Offset(84, 14),
    ];
    final List<Color> patronCoats = const [
      Color(0xFF1565C0),
      Color(0xFFAD1457),
      Color(0xFF2E7D32),
      Color(0xFF4E342E),
      Color(0xFF6A1B9A),
      Color(0xFF00838F),
      Color(0xFFC62828),
    ];

    for (int p = 0; p < patronOffsets.length; p++) {
      _drawArticulatedPerson(
        canvas,
        patronOffsets[p],
        coatColor: patronCoats[p],
        scarfColor: const Color(0xFFFFE082),
        sway: math.sin(time * 2.4 + p) * 1.4,
        hasUmbrella: p == 0 || p == 5,
        chatBubble: p.isEven,
      );
    }

    // Friendly street dog/cat beside the ramen stall
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(36, 16), width: 14, height: 8),
      Paint()..color = const Color(0xFFD7CCC8),
    );
    canvas.drawCircle(
      const Offset(42, 12),
      4.2,
      Paint()..color = const Color(0xFFD7CCC8),
    );

    canvas.restore();
  }

  void _drawNeonSignBox(
    Canvas canvas,
    Offset center,
    String label,
    Color neonColor,
  ) {
    final double flicker = 0.85 + 0.15 * math.sin(time * 9.0 + center.dx);
    final RRect box = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: 52, height: 16),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      box,
      Paint()..color = const Color(0xFF12131A).withValues(alpha: 0.90),
    );
    canvas.drawRRect(
      box,
      Paint()
        ..color = neonColor.withValues(alpha: flicker)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: neonColor.withValues(alpha: flicker),
          fontSize: 8.2,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width * 0.5, tp.height * 0.5));
  }

  // ===========================================================================
  // 6. 222° ZONE — METROPOLITAIN SUBWAY, ASTRONOMICAL CLOCK TOWER & CAROUSEL
  // ===========================================================================
  void _drawClockTowerParkAndStreetScene(
    Canvas canvas,
    Size size,
    double horizonY,
  ) {
    final double groundHeight = size.height - horizonY;

    // 1. 16 Large Autumn/City Sycamore & Linden Trees (1.35x..1.65x scale) with fairy lights
    for (int i = 0; i < 16; i++) {
      final double treeDeg = (192.0 + i * 7.5) % 360.0;
      final double? tx = _worldAngleToScreenX(treeDeg, size, margin: 320);
      if (tx == null) continue;

      final double ty = horizonY + groundHeight * (0.18 + (i % 3) * 0.03);
      final double scale = 1.35 + (i % 3) * 0.15;

      canvas.save();
      canvas.translate(tx, ty);
      canvas.scale(scale);

      // Trunk
      canvas.drawRect(
        const Rect.fromLTWH(-5, -48, 10, 48),
        Paint()..color = const Color(0xFF3E2723),
      );
      // Warm fairy lights wrapped around the trunk
      for (int f = 0; f < 5; f++) {
        canvas.drawCircle(
          Offset((f.isEven ? -3.0 : 3.0), -10.0 - f * 7.5),
          1.8,
          Paint()..color = const Color(0xFFFFE082),
        );
      }

      // United autumn/evening foliage canopy
      final Color leafColor = (i % 2 == 0)
          ? const Color(0xFFB85D19)
          : const Color(0xFF8C3B2B);
      final List<Rect> canopyOvals = [
        Rect.fromCenter(center: const Offset(0, -68), width: 56, height: 42),
        Rect.fromCenter(center: const Offset(-18, -58), width: 38, height: 32),
        Rect.fromCenter(center: const Offset(18, -58), width: 38, height: 32),
        Rect.fromCenter(center: const Offset(0, -84), width: 42, height: 32),
      ];
      Path canopyPath = Path()..addOval(canopyOvals.first);
      for (int c = 1; c < canopyOvals.length; c++) {
        canopyPath = Path.combine(
          PathOperation.union,
          canopyPath,
          Path()..addOval(canopyOvals[c]),
        );
      }
      canvas.drawPath(canopyPath, Paint()..color = leafColor);
      canvas.restore();
    }

    // 2. Iconic Art Nouveau "METROPOLITAIN" Subway Entrance at 202° (1.72x scale)
    final double? metroX = _worldAngleToScreenX(202.0, size, margin: 360);
    if (metroX != null) {
      final double metroY = horizonY + groundHeight * 0.19;
      canvas.save();
      canvas.translate(metroX, metroY);
      canvas.scale(1.72);

      // Descending stone stairwell & wrought-iron balustrade
      canvas.drawRect(
        const Rect.fromLTWH(-28, -12, 56, 14),
        Paint()..color = const Color(0xFF454152),
      );
      canvas.drawRect(
        const Rect.fromLTWH(-24, -18, 48, 8),
        Paint()..color = const Color(0xFF2D6A4F),
      );
      // Art Nouveau curved green iron arch & twin glowing amber flower-bud globe lamps
      final Path metroArch = Path()
        ..moveTo(-24, -12)
        ..lineTo(-24, -42)
        ..quadraticBezierTo(0, -56, 24, -42)
        ..lineTo(24, -12);
      canvas.drawPath(
        metroArch,
        Paint()
          ..color = const Color(0xFF2D6A4F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6,
      );
      // Red/gold "METROPOLITAIN" sign plaque
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-22, -46, 44, 9),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFFB71C1C),
      );
      final TextPainter metroTp = TextPainter(
        text: const TextSpan(
          text: 'METROPOLITAIN',
          style: TextStyle(
            color: Color(0xFFFFE082),
            fontSize: 5.0,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      metroTp.paint(canvas, Offset(-metroTp.width * 0.5, -41.5 - metroTp.height * 0.5));
      // Twin glowing amber globe lamps drooping from organic stalks
      for (final double lx in [-26.0, 26.0]) {
        canvas.drawCircle(
          Offset(lx, -42),
          6.5,
          Paint()..color = const Color(0xFFFFB300).withValues(alpha: 0.45),
        );
        canvas.drawCircle(
          Offset(lx, -42),
          3.4,
          Paint()..color = const Color(0xFFFFF8E1),
        );
      }
      canvas.restore();
    }

    // 3. Prague-Style Astronomical & Gothic Clock Tower at 222° (1.78x scale)
    final double? clockX = _worldAngleToScreenX(222.0, size, margin: 420);
    if (clockX != null) {
      final double clockY = horizonY + groundHeight * 0.19;
      canvas.save();
      canvas.translate(clockX, clockY);
      canvas.scale(1.78);

      // Stone tower shaft
      canvas.drawRect(
        const Rect.fromLTWH(-28, -165, 56, 165),
        Paint()..color = const Color(0xFF5D536B),
      );
      canvas.drawRect(
        const Rect.fromLTWH(-28, -165, 56, 165),
        Paint()
          ..color = const Color(0xFF2B2533)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );

      // Belfry arch
      final Path belfry = Path()
        ..moveTo(-12, -132)
        ..lineTo(-12, -152)
        ..arcToPoint(
          const Offset(12, -152),
          radius: const Radius.circular(12),
        )
        ..lineTo(12, -132)
        ..close();
      canvas.drawPath(belfry, Paint()..color = const Color(0xFF1F1A24));

      // Steep Gothic spire + corner turrets & golden weathervane finial
      final Path spire = Path()
        ..moveTo(-32, -165)
        ..lineTo(0, -232)
        ..lineTo(32, -165)
        ..close();
      canvas.drawPath(spire, Paint()..color = const Color(0xFF263238));
      for (final double tx in [-24.0, 24.0]) {
        final Path turret = Path()
          ..moveTo(tx - 5, -165)
          ..lineTo(tx, -194)
          ..lineTo(tx + 5, -165)
          ..close();
        canvas.drawPath(turret, Paint()..color = const Color(0xFF37474F));
      }
      canvas.drawLine(
        const Offset(0, -232),
        const Offset(0, -246),
        Paint()
          ..color = const Color(0xFFFFD54F)
          ..strokeWidth = 2.0,
      );

      // Upper Illuminated Clock Face with animated hands
      const Offset faceCenter = Offset(0, -104);
      canvas.drawCircle(
        faceCenter,
        24.0,
        Paint()..color = const Color(0xFFFFE082).withValues(alpha: 0.35),
      );
      canvas.drawCircle(
        faceCenter,
        18.0,
        Paint()..color = const Color(0xFFFFF8E1),
      );
      canvas.drawCircle(
        faceCenter,
        18.0,
        Paint()
          ..color = const Color(0xFFB7950B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );
      final double minAngle = time * 0.35;
      final double hourAngle = time * 0.03 + 1.2;
      canvas.drawLine(
        faceCenter,
        faceCenter + Offset(math.cos(hourAngle) * 9, math.sin(hourAngle) * 9),
        Paint()
          ..color = const Color(0xFF212121)
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        faceCenter,
        faceCenter + Offset(math.cos(minAngle) * 14, math.sin(minAngle) * 14),
        Paint()
          ..color = const Color(0xFF212121)
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round,
      );

      // Lower Prague-style Blue & Gold Astronomical Zodiac Dial
      const Offset astroCenter = Offset(0, -60);
      canvas.drawCircle(
        astroCenter,
        16.0,
        Paint()..color = const Color(0xFF0D47A1),
      );
      canvas.drawCircle(
        astroCenter,
        16.0,
        Paint()
          ..color = const Color(0xFFFFD54F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
      canvas.drawCircle(
        astroCenter + Offset(math.cos(time * 0.2) * 5, math.sin(time * 0.2) * 5),
        7.5,
        Paint()
          ..color = const Color(0xFFFFD54F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
      canvas.restore();
    }

    // 4. Red Classic Telephone Booth at 212° (1.72x scale) with someone inside + Bicycle
    final double? boothX = _worldAngleToScreenX(212.0, size, margin: 320);
    if (boothX != null) {
      final double boothY = horizonY + groundHeight * 0.25;
      canvas.save();
      canvas.translate(boothX, boothY);
      canvas.scale(1.72);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-14, -48, 28, 48),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xFFC62828),
      );
      canvas.drawRect(
        const Rect.fromLTWH(-10, -40, 20, 32),
        Paint()..color = const Color(0xFFFFECB3),
      );
      // Person silhouette inside booth
      canvas.drawCircle(
        const Offset(0, -28),
        4.2,
        Paint()..color = const Color(0xFF263238),
      );
      canvas.drawRect(
        const Rect.fromLTWH(-5, -23, 10, 15),
        Paint()..color = const Color(0xFF263238),
      );

      // Classic bicycle leaning against the railing next to booth
      canvas.drawCircle(
        const Offset(26, -7),
        7.0,
        Paint()
          ..color = const Color(0xFFCFD8DC)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
      canvas.drawCircle(
        const Offset(44, -7),
        7.0,
        Paint()
          ..color = const Color(0xFFCFD8DC)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
      canvas.drawLine(
        const Offset(26, -7),
        const Offset(35, -16),
        Paint()
          ..color = const Color(0xFF29B6F6)
          ..strokeWidth = 1.8,
      );
      canvas.drawLine(
        const Offset(35, -16),
        const Offset(44, -7),
        Paint()
          ..color = const Color(0xFF29B6F6)
          ..strokeWidth = 1.8,
      );
      canvas.restore();
    }

    // 5. 4 Wrought-Iron Park Benches (yFactor: 0.20, 1.72x scale) with couples under umbrellas
    final List<double> benchAngles = const [218.0, 238.0, 264.0, 290.0];
    for (int b = 0; b < benchAngles.length; b++) {
      final double? bx =
          _worldAngleToScreenX(benchAngles[b], size, margin: 320);
      if (bx == null) continue;
      final double by = horizonY + groundHeight * 0.20;

      canvas.save();
      canvas.translate(bx, by);
      canvas.scale(1.72);

      // Wrought-iron bench frame & wooden slats
      canvas.drawRect(
        const Rect.fromLTWH(-24, -14, 48, 8),
        Paint()..color = const Color(0xFF5D4037),
      );
      canvas.drawRect(
        const Rect.fromLTWH(-26, -6, 52, 4),
        Paint()..color = const Color(0xFF4E342E),
      );
      canvas.drawLine(
        const Offset(-22, -6),
        const Offset(-22, 2),
        Paint()
          ..color = const Color(0xFF212121)
          ..strokeWidth = 2.2,
      );
      canvas.drawLine(
        const Offset(22, -6),
        const Offset(22, 2),
        Paint()
          ..color = const Color(0xFF212121)
          ..strokeWidth = 2.2,
      );

      // Couple sitting under an umbrella on the bench
      _drawArticulatedPerson(
        canvas,
        const Offset(-7, 0),
        coatColor: const Color(0xFF3949AB),
        scarfColor: const Color(0xFFFFD54F),
        sway: math.sin(time * 1.8 + b) * 0.8,
        hasUmbrella: true,
      );
      _drawArticulatedPerson(
        canvas,
        const Offset(8, 0),
        coatColor: const Color(0xFFD81B60),
        scarfColor: const Color(0xFFFFF59D),
        sway: -math.sin(time * 1.8 + b) * 0.8,
      );
      canvas.restore();
    }

    // 6. Classic Vintage Coupe Car at 252° (1.72x scale) parked by the curb with glowing headlights
    final double? carX = _worldAngleToScreenX(252.0, size, margin: 380);
    if (carX != null) {
      final double carY = horizonY + groundHeight * 0.21;
      canvas.save();
      canvas.translate(carX, carY);
      canvas.scale(1.72);

      // Wet reflection under car
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, 6), width: 112, height: 14),
        Paint()..color = Colors.black.withValues(alpha: 0.48),
      );

      // Classic rounded coupe body (midnight teal-blue)
      final Path carBody = Path()
        ..moveTo(-48, 0)
        ..lineTo(-48, -14)
        ..quadraticBezierTo(-36, -20, -24, -20)
        ..lineTo(-14, -34)
        ..quadraticBezierTo(4, -38, 22, -32)
        ..lineTo(30, -18)
        ..quadraticBezierTo(46, -16, 50, -10)
        ..lineTo(50, 0)
        ..close();
      canvas.drawPath(carBody, Paint()..color = const Color(0xFF1A365D));
      // Cabin windows
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-12, -31, 30, 11),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFF90CAF9).withValues(alpha: 0.75),
      );

      // Whitewall tires
      for (final double wx in [-28.0, 28.0]) {
        canvas.drawCircle(
          Offset(wx, 0),
          9.5,
          Paint()..color = const Color(0xFF1E1E1E),
        );
        canvas.drawCircle(
          Offset(wx, 0),
          5.5,
          Paint()..color = const Color(0xFFFFF8E1),
        );
      }

      // Glowing golden headlight cones
      final Path headBeam = Path()
        ..moveTo(50, -10)
        ..lineTo(118, -22)
        ..lineTo(118, 8)
        ..close();
      canvas.drawPath(
        headBeam,
        Paint()
          ..shader = ui.Gradient.linear(
            const Offset(50, -10),
            const Offset(118, -10),
            [
              const Color(0xFFFFF59D).withValues(alpha: 0.62),
              Colors.transparent,
            ],
          ),
      );
      canvas.drawCircle(
        const Offset(49, -10),
        4.0,
        Paint()..color = const Color(0xFFFFFDE7),
      );
      canvas.restore();
    }

    // 7. Vintage Parisian Carousel / Street Organ at 276° (1.72x scale) with glowing canopy & horses
    final double? carouselX = _worldAngleToScreenX(276.0, size, margin: 380);
    if (carouselX != null) {
      final double carouselY = horizonY + groundHeight * 0.20;
      canvas.save();
      canvas.translate(carouselX, carouselY);
      canvas.scale(1.72);

      // Warm golden carousel reflection on the wet cobblestones
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, 10), width: 136, height: 24),
        Paint()..color = const Color(0xFFFFD54F).withValues(alpha: 0.35),
      );
      // Circular wooden platform base
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-46, -6, 92, 10),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFF8D4E38),
      );
      // Central ornate brass organ column
      canvas.drawRect(
        const Rect.fromLTWH(-8, -48, 16, 42),
        Paint()..color = const Color(0xFFD4AF37),
      );
      // 3 Animated Bobbing Carousel Horses on brass poles
      for (int h = -1; h <= 1; h++) {
        final double hx = h * 24.0;
        final double bob = math.sin(time * 3.6 + h * 1.4) * 4.5;
        canvas.drawLine(
          Offset(hx, -6),
          Offset(hx, -48),
          Paint()
            ..color = const Color(0xFFFFD54F)
            ..strokeWidth = 1.6,
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(hx, -22 + bob), width: 14, height: 8),
          Paint()..color = const Color(0xFFFFF8E1),
        );
        canvas.drawCircle(
          Offset(hx + 5, -27 + bob),
          3.5,
          Paint()..color = const Color(0xFFFFF8E1),
        );
      }
      // Striped crimson & cream conical carousel canopy
      final Path canopy = Path()
        ..moveTo(-50, -48)
        ..lineTo(0, -76)
        ..lineTo(50, -48)
        ..close();
      canvas.drawPath(canopy, Paint()..color = const Color(0xFFC62828));
      final Path centerStripe = Path()
        ..moveTo(-18, -48)
        ..lineTo(0, -76)
        ..lineTo(18, -48)
        ..close();
      canvas.drawPath(centerStripe, Paint()..color = const Color(0xFFFFF8E1));
      // Glowing festoon bulbs around canopy rim
      for (int b = -4; b <= 4; b++) {
        canvas.drawCircle(
          Offset(b * 11.0, -48),
          2.4,
          Paint()..color = const Color(0xFFFFE082),
        );
      }
      canvas.restore();
    }
  }

  // ===========================================================================
  // 7. FOREGROUND PUDDLES & 6 STRAY CITY CATS (WITH 140PX CENTER EXCLUSION ZONE)
  // ===========================================================================
  void _drawForegroundPuddlesAndCats(
    Canvas canvas,
    Size size,
    double horizonY,
  ) {
    final double groundHeight = size.height - horizonY;
    final List<double> catAngles = const [
      42.0,
      115.0,
      154.0,
      208.0,
      260.0,
      318.0,
    ];
    for (int c = 0; c < catAngles.length; c++) {
      final double? cx = _worldAngleToScreenX(catAngles[c], size, margin: 200);
      if (cx == null) continue;
      if ((cx - size.width * 0.5).abs() < 140) continue;
      final double cy = horizonY + groundHeight * (0.50 + (c % 2) * 0.14);

      canvas.save();
      canvas.translate(cx, cy);
      canvas.scale(1.65);

      // Shimmering rain puddle beside the cat
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(-18, 2), width: 32, height: 9),
        Paint()..color = const Color(0xFF4FC3F7).withValues(alpha: 0.25),
      );

      final Color fur = c.isEven
          ? const Color(0xFF263238)
          : const Color(0xFFD87A3B);
      // Body & head
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, -4), width: 12, height: 8),
        Paint()..color = fur,
      );
      canvas.drawCircle(
        const Offset(5, -9),
        4.0,
        Paint()..color = fur,
      );
      // Pointy ears
      final Path ears = Path()
        ..moveTo(2, -11)
        ..lineTo(3, -15)
        ..lineTo(5, -12)
        ..moveTo(5, -12)
        ..lineTo(7, -15)
        ..lineTo(8, -11)
        ..close();
      canvas.drawPath(ears, Paint()..color = fur);
      // Animated swaying tail
      final double tailSway = math.sin(time * 3.2 + c) * 3.0;
      final Path tail = Path()
        ..moveTo(-5, -4)
        ..quadraticBezierTo(-11, -10 + tailSway, -9, -15);
      canvas.drawPath(
        tail,
        Paint()
          ..color = fur
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round,
      );
      canvas.restore();
    }
  }

  void _drawArticulatedPerson(
    Canvas canvas,
    Offset pos, {
    required Color coatColor,
    required Color scarfColor,
    double sway = 0.0,
    bool hasUmbrella = false,
    bool hasViolin = false,
    bool hasGuitar = false,
    bool chatBubble = false,
  }) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 1), width: 14, height: 4),
      Paint()..color = Colors.black.withValues(alpha: 0.38),
    );

    // Legs
    canvas.drawLine(
      const Offset(-2.5, 0),
      const Offset(-2.5, -10),
      Paint()
        ..color = const Color(0xFF1C2026)
        ..strokeWidth = 2.4,
    );
    canvas.drawLine(
      const Offset(2.5, 0),
      const Offset(2.5, -10),
      Paint()
        ..color = const Color(0xFF1C2026)
        ..strokeWidth = 2.4,
    );

    // Coat torso
    final RRect coat = RRect.fromRectAndRadius(
      Rect.fromLTWH(-5.5 + sway * 0.2, -23, 11, 14),
      const Radius.circular(3.5),
    );
    canvas.drawRRect(coat, Paint()..color = coatColor);

    // Scarf
    canvas.drawRect(
      Rect.fromLTWH(-4.5 + sway * 0.2, -24, 9, 3),
      Paint()..color = scarfColor,
    );

    // Head
    canvas.drawCircle(
      Offset(sway * 0.3, -28),
      4.2,
      Paint()..color = const Color(0xFFFFCCBC),
    );

    if (hasViolin) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(5 + sway * 0.3, -21),
          width: 8,
          height: 4.5,
        ),
        Paint()..color = const Color(0xFF8D4004),
      );
      canvas.drawLine(
        Offset(1, -24),
        Offset(10, -17),
        Paint()
          ..color = const Color(0xFFFFECB3)
          ..strokeWidth = 1.2,
      );
    }

    if (hasGuitar) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(2 + sway * 0.2, -16),
          width: 11,
          height: 6.5,
        ),
        Paint()..color = const Color(0xFFD87A3B),
      );
    }

    if (hasUmbrella) {
      canvas.drawLine(
        Offset(4, -18),
        Offset(4, -39),
        Paint()
          ..color = const Color(0xFFCFD8DC)
          ..strokeWidth = 1.4,
      );
      final Path umbrellaDome = Path()
        ..moveTo(-12, -37)
        ..quadraticBezierTo(4, -49, 20, -37)
        ..close();
      canvas.drawPath(
        umbrellaDome,
        Paint()..color = const Color(0xFF1E293B).withValues(alpha: 0.92),
      );
    }

    if (chatBubble) {
      final double pulse = 0.75 + 0.25 * math.sin(time * 3.5 + pos.dx);
      final RRect bubble = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, -39),
          width: 14,
          height: 7,
        ),
        const Radius.circular(3.5),
      );
      canvas.drawRRect(
        bubble,
        Paint()..color = Colors.white.withValues(alpha: 0.85 * pulse),
      );
      for (int d = -1; d <= 1; d++) {
        canvas.drawCircle(
          Offset(d * 3.2, -39),
          1.0,
          Paint()..color = const Color(0xFF263238),
        );
      }
    }

    canvas.restore();
  }

  // ===========================================================================
  // 8. CENTER FOREGROUND OBJECT — THE VINTAGE CAST-IRON STREET LAMP
  // ===========================================================================
  void _drawCenterStreetLamp(Canvas canvas, Size size) {
    final Offset baseCenter = Offset(size.width * 0.5, size.height * 0.875);
    final double pulseScale =
        (math.min(size.width, size.height) / 920.0).clamp(0.76, 0.96) *
        0.62 *
        (1.0 + math.sin(coconutPulse * math.pi) * 0.08) *
        (0.9 + 0.1 * cameraZoom.clamp(0.85, 1.35));

    canvas.save();
    canvas.translate(baseCenter.dx, baseCenter.dy);
    canvas.scale(pulseScale);

    final bool isGoldKing = styleMode == CoconutStyleMode.king;
    final bool isCyberArcade = styleMode == CoconutStyleMode.arcade;

    final Color poolCore = isCyberArcade
        ? const Color(0xFF00E5FF)
        : const Color(0xFFFFD54F);
    final Color poolMid = isCyberArcade
        ? const Color(0xFFFF007F)
        : const Color(0xFFFF8F00);

    // Directional Ground Shadow rotating with -cameraYaw away from the canal sunset/moon at 0°
    final double shadowAngle = -cameraYaw + math.pi * 0.5;
    final double shadowOffsetX = math.cos(shadowAngle) * 28.0;
    final double shadowOffsetY = 12.0 + math.sin(shadowAngle) * 6.0;
    final Rect dirShadowRect = Rect.fromCenter(
      center: Offset(shadowOffsetX, shadowOffsetY),
      width: 190,
      height: 44,
    );
    canvas.drawOval(
      dirShadowRect,
      Paint()
        ..shader = ui.Gradient.radial(
          dirShadowRect.center,
          95,
          [
            Colors.black.withValues(alpha: 0.46),
            Colors.black.withValues(alpha: 0.18),
            Colors.transparent,
          ],
          const [0.0, 0.60, 1.0],
        ),
    );

    // 0. Dramatic Downward Volumetric Golden / Neon Light Cone from (0, -264) to (-155..+155, 22)
    final Path volumetricCone = Path()
      ..moveTo(-24, -264)
      ..lineTo(24, -264)
      ..lineTo(155, 22)
      ..lineTo(-155, 22)
      ..close();
    canvas.drawPath(
      volumetricCone,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, -264),
          const Offset(0, 22),
          [
            poolCore.withValues(alpha: 0.28),
            poolMid.withValues(alpha: 0.12),
            Colors.transparent,
          ],
          const [0.0, 0.58, 1.0],
        ),
    );
    // Floating illuminated dust motes / rain droplets inside the volumetric beam
    for (int m = 0; m < 16; m++) {
      final double mp = (time * 0.25 + m * 0.0625) % 1.0;
      final double my = -248.0 + mp * 246.0;
      final double spread = 20.0 + mp * 95.0;
      final double mx =
          math.sin(time * 1.4 + m * 2.1) * spread * 0.75;
      final double alpha = math.sin(mp * math.pi) * 0.55;
      canvas.drawCircle(
        Offset(mx, my),
        1.4 + (m % 2) * 0.7,
        Paint()..color = poolCore.withValues(alpha: alpha.clamp(0.0, 1.0)),
      );
    }

    // 1. Warm golden or cyberpunk neon light reflection directly on the continuous wet cobblestone plaza
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 10), width: 310, height: 64),
      Paint()
        ..shader = ui.Gradient.radial(
          const Offset(0, 10),
          155,
          [
            poolCore.withValues(alpha: 0.44),
            poolMid.withValues(alpha: 0.20),
            Colors.transparent,
          ],
          const [0.0, 0.55, 1.0],
        ),
    );

    // Cast-iron / Royal-gold palette
    final Color ironDark = isGoldKing
        ? const Color(0xFF8C6200)
        : const Color(0xFF14181F);
    final Color ironMid = isGoldKing
        ? const Color(0xFFD4AF37)
        : const Color(0xFF26303D);
    final Color ironHighlight = isGoldKing
        ? const Color(0xFFFFF59D)
        : const Color(0xFF546E7A);

    // Dynamic light direction on the 3D lamp as cameraYaw rotates
    final double lightDirX =
        math.sin(-cameraYaw * math.pi / 180.0).clamp(-1.0, 1.0);

    // Seamless Cobblestone Curbing Socket & 3D Rotating Embedded Plaza Stones
    final Color plazaStoneDark = switch (atmosphereMode) {
      CoconutAtmosphereMode.sunset => const Color(0xFF1E192B),
      CoconutAtmosphereMode.night => const Color(0xFF131624),
      CoconutAtmosphereMode.noon => const Color(0xFF3E3A4B),
      CoconutAtmosphereMode.rain => const Color(0xFF171C28),
    };
    final Color plazaStoneMid = switch (atmosphereMode) {
      CoconutAtmosphereMode.sunset => const Color(0xFF2B243A),
      CoconutAtmosphereMode.night => const Color(0xFF1D2236),
      CoconutAtmosphereMode.noon => const Color(0xFF524D63),
      CoconutAtmosphereMode.rain => const Color(0xFF242B3D),
    };
    final Path curbSocket = Path()
      ..moveTo(-68, 12)
      ..quadraticBezierTo(-36, -3, 0, 1)
      ..quadraticBezierTo(36, -3, 68, 12)
      ..quadraticBezierTo(42, 25, 0, 23)
      ..quadraticBezierTo(-42, 25, -68, 12)
      ..close();
    canvas.drawPath(curbSocket, Paint()..color = plazaStoneMid);

    // 12 radial granite cobblestones orbiting 360° around the lamp curb
    for (int s = 0; s < 12; s++) {
      final double sRad = (s * 30.0 - cameraYaw) * math.pi / 180.0;
      final double sx = math.sin(sRad) * 48.0;
      final double sy = 10.0 + math.cos(sRad) * 9.5;
      final double sWidth = 6.5 + 4.5 * math.cos(sRad).abs();
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(sx, sy), width: sWidth, height: 5.2),
          const Radius.circular(2),
        ),
        Paint()..color = s.isEven ? plazaStoneDark : plazaStoneMid,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(sx, sy), width: sWidth, height: 5.2),
          const Radius.circular(2),
        ),
        Paint()
          ..color = poolCore.withValues(alpha: 0.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9,
      );
    }

    // Fallen autumn sycamore leaves orbiting 360° on the curb
    const List<(double, double, Color)> leafRing = [
      (25.0, 56.0, Color(0xFFD84315)),
      (78.0, 42.0, Color(0xFFFF8F00)),
      (145.0, 58.0, Color(0xFFEF6C00)),
      (215.0, 46.0, Color(0xFFFFB300)),
      (285.0, 54.0, Color(0xFFD84315)),
      (330.0, 38.0, Color(0xFFFF8F00)),
    ];
    for (final (double deg, double radDist, Color lc) in leafRing) {
      final double lRad = (deg - cameraYaw) * math.pi / 180.0;
      final double lx = math.sin(lRad) * radDist;
      final double ly = 11.0 + math.cos(lRad) * (radDist * 0.22);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(lx, ly), width: 7.5, height: 4.0),
        Paint()..color = lc,
      );
    }

    // Helper to draw the 6 orbiting cast-iron plaza bollards & slack chains (back pass vs front pass)
    void drawOrbitingBollardsAndChains({required bool frontPass}) {
      final Paint chainPaint = Paint()
        ..color = ironHighlight.withValues(alpha: frontPass ? 0.80 : 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = frontPass ? 1.6 : 1.2;

      for (int b = 0; b < 6; b++) {
        final double bRad1 = (b * 60.0 - cameraYaw) * math.pi / 180.0;
        final double bRad2 = ((b + 1) * 60.0 - cameraYaw) * math.pi / 180.0;
        final double midCos = (math.cos(bRad1) + math.cos(bRad2)) * 0.5;
        if ((midCos >= 0.0) == frontPass) {
          final double x1 = math.sin(bRad1) * 76.0;
          final double y1 = 10.0 + math.cos(bRad1) * 14.0 - 16.0;
          final double x2 = math.sin(bRad2) * 76.0;
          final double y2 = 10.0 + math.cos(bRad2) * 14.0 - 16.0;
          canvas.drawPath(
            Path()
              ..moveTo(x1, y1)
              ..quadraticBezierTo(
                (x1 + x2) * 0.5,
                (y1 + y2) * 0.5 + 8.5,
                x2,
                y2,
              ),
            chainPaint,
          );
        }
      }

      for (int b = 0; b < 6; b++) {
        final double bRad = (b * 60.0 - cameraYaw) * math.pi / 180.0;
        final double bCos = math.cos(bRad);
        if ((bCos >= 0.0) != frontPass) continue;
        final double bolX = math.sin(bRad) * 76.0;
        final double bolY = 10.0 + bCos * 14.0;
        final double bScale = 0.86 + 0.16 * bCos;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(bolX, bolY - 10 * bScale),
              width: 6.8 * bScale,
              height: 20.0 * bScale,
            ),
            const Radius.circular(3),
          ),
          Paint()..color = bCos >= 0 ? ironMid : ironDark,
        );
        canvas.drawCircle(
          Offset(bolX, bolY - 21 * bScale),
          3.8 * bScale,
          Paint()..color = ironHighlight,
        );
      }
    }

    // Back-hemisphere bollards & chains behind the lamp post
    drawOrbitingBollardsAndChains(frontPass: false);

    // 2. Fluted Octagonal Cast-Iron Pedestal Base & Column with 3D rotating facets
    final RRect lowerPlinth = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-26, -18, 52, 26),
      const Radius.circular(6),
    );
    canvas.drawRRect(
      lowerPlinth,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(-26 + lightDirX * 8, 0),
          Offset(26 + lightDirX * 8, 0),
          [ironDark, ironMid, ironHighlight, ironDark],
          const [0.0, 0.35, 0.70, 1.0],
        ),
    );

    final Path taperedBase = Path()
      ..moveTo(-22, -18)
      ..lineTo(-13, -72)
      ..lineTo(13, -72)
      ..lineTo(22, -18)
      ..close();
    canvas.drawPath(
      taperedBase,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(-22 + lightDirX * 6, 0),
          Offset(22 + lightDirX * 6, 0),
          [ironDark, ironMid, ironHighlight, ironDark],
          const [0.0, 0.35, 0.70, 1.0],
        ),
    );

    // 8 rotating octagonal pedestal facet seams & embossed cast-iron panels
    for (int f = 0; f < 8; f++) {
      final double fRad = (f * 45.0 - cameraYaw) * math.pi / 180.0;
      final double fCos = math.cos(fRad);
      if (fCos <= -0.10) continue;
      final double fSin = math.sin(fRad);
      final double botX = fSin * 21.0;
      final double topX = fSin * 12.5;
      canvas.drawLine(
        Offset(botX, 6),
        Offset(topX, -72),
        Paint()
          ..color = (f.isEven ? ironHighlight : ironDark)
              .withValues(alpha: (0.28 + 0.45 * fCos).clamp(0.0, 1.0))
          ..strokeWidth = 1.5,
      );
    }

    // Main tall fluted post (-72 to -226)
    canvas.drawRect(
      const Rect.fromLTWH(-8.5, -226, 17, 154),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(-8.5 + lightDirX * 3, 0),
          Offset(8.5 + lightDirX * 3, 0),
          [ironDark, ironMid, ironHighlight, ironDark],
          const [0.0, 0.35, 0.70, 1.0],
        ),
    );
    // 8 3D-rotating fluted vertical grooves around the cylindrical post
    for (int g = 0; g < 8; g++) {
      final double gRad = (g * 45.0 - cameraYaw) * math.pi / 180.0;
      final double gCos = math.cos(gRad);
      if (gCos <= -0.05) continue;
      final double gx = math.sin(gRad) * 7.6;
      canvas.drawLine(
        Offset(gx, -76),
        Offset(gx, -222),
        Paint()
          ..color = (g.isEven ? ironDark : ironHighlight)
              .withValues(alpha: (0.25 + 0.50 * gCos).clamp(0.0, 1.0))
          ..strokeWidth = 1.3,
      );
    }

    // Decorative collar rings with rotating brass rivets
    for (final double ry in [-72.0, -140.0, -212.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(0, ry), width: 28, height: 8),
          const Radius.circular(4),
        ),
        Paint()..color = ironHighlight,
      );
      for (int r = 0; r < 6; r++) {
        final double rRad = (r * 60.0 - cameraYaw) * math.pi / 180.0;
        if (math.cos(rRad) <= 0.0) continue;
        canvas.drawCircle(
          Offset(math.sin(rRad) * 11.5, ry),
          1.4,
          Paint()..color = ironDark,
        );
      }
    }

    // 2B. Two Classic Enameled Parisian Street Sign Plates rotating 360° in 3D
    // Mounted at 270° (Left at yaw=0) and 90° (Right at yaw=0), sorted by depth
    final List<(double, double, String)> signSpecs = const [
      (270.0, -178.0, '⬅ CAFÉ DE NUIT'),
      (90.0, -166.0, 'JAZZ CLUB ➡'),
    ];
    final List<(double, double, double, String)> sortedSigns = [
      for (final (double deg, double sy, String sText) in signSpecs)
        (
          math.cos((deg - cameraYaw) * math.pi / 180.0),
          (deg - cameraYaw) * math.pi / 180.0,
          sy,
          sText,
        ),
    ]..sort((a, b) => a.$1.compareTo(b.$1));

    for (final (double sCos, double sRad, double sy, String sText)
        in sortedSigns) {
      final double sSin = math.sin(sRad);
      // Horizontal foreshortening as the plate rotates in 3D
      final double foreshorten = sSin.abs().clamp(0.18, 1.0);
      final double plateW = 72.0 * foreshorten;
      final double centerX = sSin * 44.0;
      final Offset sCenter = Offset(centerX, sy + sCos * 2.0);

      // Mounting bracket ring to post
      canvas.drawLine(
        Offset(0, sy),
        sCenter,
        Paint()
          ..color = ironMid
          ..strokeWidth = 2.6,
      );

      final RRect signPlate = RRect.fromRectAndRadius(
        Rect.fromCenter(center: sCenter, width: plateW, height: 14),
        const Radius.circular(2.5),
      );
      canvas.drawRRect(signPlate, Paint()..color = const Color(0xFF0D2B56));
      canvas.drawRRect(
        signPlate.deflate(1.4),
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1,
      );
      if (foreshorten > 0.34) {
        canvas.save();
        canvas.translate(sCenter.dx, sCenter.dy);
        canvas.scale(foreshorten, 1.0);
        final TextPainter stp = TextPainter(
          text: TextSpan(
            text: sText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 6.8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        stp.paint(canvas, Offset(-stp.width * 0.5, -stp.height * 0.5));
        canvas.restore();
      }
    }

    // Ornate crossbar, twin scroll brackets & 2 Hanging Flower Baskets rotating 360° at -216
    final double barRad = (90.0 - cameraYaw) * math.pi / 180.0;
    final double barSpan = (math.sin(barRad).abs() * 84.0).clamp(18.0, 84.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, -216), width: barSpan, height: 6),
        const Radius.circular(3),
      ),
      Paint()..color = ironMid,
    );

    final List<double> bracketAngles = [270.0, 90.0];
    bracketAngles.sort((a, b) {
      final double ca = math.cos((a - cameraYaw) * math.pi / 180.0);
      final double cb = math.cos((b - cameraYaw) * math.pi / 180.0);
      return ca.compareTo(cb);
    });
    for (final double bDeg in bracketAngles) {
      final double bRad = (bDeg - cameraYaw) * math.pi / 180.0;
      final double bSin = math.sin(bRad);
      final double bCos = math.cos(bRad);
      final double bx = bSin * 34.0;
      final double byOff = bCos * 3.5;

      final Path scroll = Path()
        ..moveTo(bSin * 8.0, -192 + byOff * 0.4)
        ..quadraticBezierTo(bx, -196 + byOff, bx, -216 + byOff)
        ..quadraticBezierTo(bSin * 20.0, -228 + byOff * 0.5, bSin * 22.0, -234);
      canvas.drawPath(
        scroll,
        Paint()
          ..color = ironHighlight
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round,
      );

      // Hanging flower basket with trailing ivy & red geraniums suspended in 3D
      final double basketScale = 0.88 + 0.14 * bCos;
      canvas.drawLine(
        Offset(bx, -214 + byOff),
        Offset(bx, -200 + byOff),
        Paint()
          ..color = ironDark
          ..strokeWidth = 1.4,
      );
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(bx, -200 + byOff),
          width: 16 * basketScale,
          height: 12 * basketScale,
        ),
        0,
        math.pi,
        true,
        Paint()..color = const Color(0xFF5D4037),
      );
      canvas.drawCircle(
        Offset(bx - 4 * basketScale, -202 + byOff),
        3.5 * basketScale,
        Paint()..color = const Color(0xFF2E7D32),
      );
      canvas.drawCircle(
        Offset(bx + 4 * basketScale, -202 + byOff),
        3.5 * basketScale,
        Paint()..color = const Color(0xFF388E3C),
      );
      canvas.drawCircle(
        Offset(bx, -204 + byOff),
        2.8 * basketScale,
        Paint()..color = const Color(0xFFE53935),
      );
      canvas.drawCircle(
        Offset(bx + bSin * 3.0, -201 + byOff),
        2.4 * basketScale,
        Paint()..color = const Color(0xFFFF80AB),
      );
    }

    // 3. Radial Golden / Neon Light Halo around the Lantern Head (center at 0, -264)
    const Offset lanternCenter = Offset(0, -264);
    final double haloRadius = 165.0 + math.sin(time * 3.2) * 8.0;
    canvas.drawCircle(
      lanternCenter,
      haloRadius,
      Paint()
        ..shader = ui.Gradient.radial(
          lanternCenter,
          haloRadius,
          [
            poolCore.withValues(alpha: 0.70),
            poolMid.withValues(alpha: 0.28),
            Colors.transparent,
          ],
          const [0.0, 0.42, 1.0],
        ),
    );

    // 4. 6-Sided Hexagonal Bevelled Glass Lantern Chamber & Rotating Brass Finials
    final Path glassChamber = Path()
      ..moveTo(-22, -234)
      ..lineTo(-32, -288)
      ..lineTo(32, -288)
      ..lineTo(22, -234)
      ..close();

    // Back-hemisphere hexagonal frame bars (drawn behind the glowing bulb)
    for (int k = 0; k < 6; k++) {
      final double kRad = (k * 60.0 - cameraYaw) * math.pi / 180.0;
      if (math.cos(kRad) >= 0.0) continue;
      final double kSin = math.sin(kRad);
      canvas.drawLine(
        Offset(kSin * 21.5, -234),
        Offset(kSin * 31.5, -288),
        Paint()
          ..color = ironDark.withValues(alpha: 0.50)
          ..strokeWidth = 1.4,
      );
    }

    canvas.drawPath(
      glassChamber,
      Paint()
        ..shader = ui.Gradient.radial(
          lanternCenter,
          38,
          [
            const Color(0xFFFFFDE7),
            isCyberArcade
                ? const Color(0xFF00E5FF).withValues(alpha: 0.86)
                : const Color(0xFFFFCA28).withValues(alpha: 0.84),
            isCyberArcade
                ? const Color(0xFFFF007F).withValues(alpha: 0.56)
                : const Color(0xFFFF8F00).withValues(alpha: 0.50),
          ],
          const [0.0, 0.55, 1.0],
        ),
    );

    // Glowing Edison bulb & 3D rotating filament loop inside the lantern
    canvas.drawCircle(
      lanternCenter,
      10.5,
      Paint()..color = const Color(0xFFFFFFFF),
    );
    final double filSpan =
        (math.cos(cameraYaw * math.pi / 180.0) * 4.8).clamp(-4.8, 4.8);
    final Path filament = Path()
      ..moveTo(-filSpan * 0.75, -255)
      ..lineTo(-filSpan, -267)
      ..quadraticBezierTo(0, -274, filSpan, -267)
      ..lineTo(filSpan * 0.75, -255);
    canvas.drawPath(
      filament,
      Paint()
        ..color = const Color(0xFFFF6F00)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.9,
    );

    // Outer chamber silhouette & front-hemisphere rotating hexagonal frame bars + glass highlights
    canvas.drawPath(
      glassChamber,
      Paint()
        ..color = ironDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6,
    );
    for (int k = 0; k < 6; k++) {
      final double kRad = (k * 60.0 - cameraYaw) * math.pi / 180.0;
      final double kCos = math.cos(kRad);
      if (kCos < 0.0) continue;
      final double kSin = math.sin(kRad);
      canvas.drawLine(
        Offset(kSin * 21.5, -234),
        Offset(kSin * 31.5, -288),
        Paint()
          ..color = ironDark
          ..strokeWidth = 1.6 + 0.6 * kCos,
      );
      // Rotating bevelled glass highlight streak on front panes
      final double paneMidRad = ((k * 60.0 + 30.0) - cameraYaw) * math.pi / 180.0;
      if (math.cos(paneMidRad) > 0.25) {
        final double pSin = math.sin(paneMidRad);
        canvas.drawLine(
          Offset(pSin * 24.0, -282),
          Offset(pSin * 16.0, -240),
          Paint()
            ..color = Colors.white.withValues(
              alpha: (0.48 * math.cos(paneMidRad)).clamp(0.0, 0.50),
            )
            ..strokeWidth = 2.0
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // Lantern cupola dome & 6 rotating brass corner finials
    final Path dome = Path()
      ..moveTo(-36, -288)
      ..quadraticBezierTo(0, -320, 36, -288)
      ..close();
    canvas.drawPath(dome, Paint()..color = ironMid);
    // Dome ribs rotating in 3D
    for (int k = 0; k < 6; k++) {
      final double kRad = (k * 60.0 - cameraYaw) * math.pi / 180.0;
      final double kSin = math.sin(kRad);
      final double kCos = math.cos(kRad);
      if (kCos >= -0.1) {
        canvas.drawPath(
          Path()
            ..moveTo(kSin * 33.0, -288)
            ..quadraticBezierTo(kSin * 14.0, -304, 0, -305),
          Paint()
            ..color = ironHighlight.withValues(alpha: 0.45)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.3,
        );
      }
      // 6 rotating brass corner finials on the hexagonal rim
      if (kCos >= -0.25) {
        canvas.drawCircle(
          Offset(kSin * 32.0, -290 + kCos * 2.0),
          2.6 + 0.6 * kCos,
          Paint()..color = const Color(0xFFFFD54F),
        );
      }
    }
    canvas.drawLine(
      const Offset(0, -304),
      const Offset(0, -326),
      Paint()
        ..color = ironHighlight
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round,
    );

    // 5. Style-Specific Accessories on the Street Lamp (all rotating in 3D with cameraYaw)
    switch (styleMode) {
      case CoconutStyleMode.natural:
        _drawNaturalLampDetails(canvas, lanternCenter);
        break;
      case CoconutStyleMode.arcade:
        _drawArcadeLampDetails(canvas, lanternCenter);
        break;
      case CoconutStyleMode.cocktail:
        _drawCocktailJazzLampDetails(canvas, lanternCenter);
        break;
      case CoconutStyleMode.king:
        _drawKingRoyalLampDetails(canvas, lanternCenter);
        break;
      case CoconutStyleMode.lofi:
        _drawLofiCozyLampDetails(canvas, lanternCenter);
        break;
    }

    // Front-hemisphere bollards & chains in front of the lamp post
    drawOrbitingBollardsAndChains(frontPass: true);

    canvas.restore();
  }

  void _drawNaturalLampDetails(Canvas canvas, Offset lanternCenter) {
    // 3D spiraling green ivy vine wrapped around the lower cast-iron post
    final double yawRad = cameraYaw * math.pi / 180.0;
    for (int seg = 0; seg < 24; seg++) {
      final double t0 = seg / 24.0;
      final double t1 = (seg + 1) / 24.0;
      final double a0 = t0 * math.pi * 4.0 - yawRad;
      final double a1 = t1 * math.pi * 4.0 - yawRad;
      if (math.cos(a0) < -0.15 && math.cos(a1) < -0.15) continue;
      final double r0 = 16.0 - t0 * 7.5;
      final double r1 = 16.0 - t1 * 7.5;
      final double y0 = 4.0 - t0 * 142.0;
      final double y1 = 4.0 - t1 * 142.0;
      canvas.drawLine(
        Offset(math.sin(a0) * r0, y0),
        Offset(math.sin(a1) * r1, y1),
        Paint()
          ..color = const Color(0xFF2E7D32)
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round,
      );
      if (seg % 3 == 0 && math.cos(a0) > 0.0) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(math.sin(a0) * (r0 + 3.0), y0),
            width: 9.0,
            height: 5.5,
          ),
          Paint()..color = const Color(0xFF4CAF50),
        );
      }
    }

    // 4 fluttering nocturnal moths orbiting the warm lantern light in 3D
    for (int m = 0; m < 4; m++) {
      final double angle =
          time * (2.2 + m * 0.35) + m * (math.pi * 0.5) - yawRad;
      final double mx = lanternCenter.dx + math.sin(angle) * (44.0 + m * 7.0);
      final double my =
          lanternCenter.dy + math.cos(angle * 1.4) * (16.0 + m * 4.0);
      final double wing = math.sin(time * 18.0 + m) * 4.0;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(mx - 3, my),
          width: 6,
          height: (4 + wing).abs().clamp(2.0, 8.0),
        ),
        Paint()..color = const Color(0xFFFFF59D),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(mx + 3, my),
          width: 6,
          height: (4 + wing).abs().clamp(2.0, 8.0),
        ),
        Paint()..color = const Color(0xFFFFF59D),
      );
    }
  }

  void _drawArcadeLampDetails(Canvas canvas, Offset lanternCenter) {
    final double yawRad = cameraYaw * math.pi / 180.0;
    // Neon magenta & cyan plasma glow tubes rotating 360° around the post
    for (final (double deg, Color tubeColor) in const [
      (270.0, Color(0xFFFF007F)),
      (90.0, Color(0xFF00E5FF)),
    ]) {
      final double tRad = deg * math.pi / 180.0 - yawRad;
      final double tx = math.sin(tRad) * 11.5;
      canvas.drawLine(
        Offset(tx, -74),
        Offset(tx, -210),
        Paint()
          ..color = tubeColor.withValues(
            alpha: math.cos(tRad) >= -0.2 ? 0.95 : 0.45,
          )
          ..strokeWidth = 3.2
          ..strokeCap = StrokeCap.round,
      );
    }

    // Retro synthwave stickers rotating around the lower post
    final double stCos = math.cos(-yawRad);
    final double stSin = math.sin(-yawRad);
    if (stCos > -0.15) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(stSin * 6.0, -114),
            width: 16.0 * stCos.abs().clamp(0.25, 1.0),
            height: 12,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFFFFEA00),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(stSin * 6.5, -96),
          width: 13.0 * stCos.abs().clamp(0.25, 1.0),
          height: 13.0,
        ),
        Paint()..color = const Color(0xFFFF007F),
      );
    }

    // Cool pixel/visor sunglasses rotating in 3D over the glass lantern
    final double vShift = stSin * 14.0;
    final double vScaleX = 0.45 + 0.55 * stCos.abs();
    canvas.save();
    canvas.translate(vShift, 0);
    canvas.scale(vScaleX, 1.0);
    final Path visor = Path()
      ..moveTo(-30, -270)
      ..lineTo(30, -270)
      ..lineTo(24, -254)
      ..lineTo(5, -254)
      ..lineTo(0, -261)
      ..lineTo(-5, -254)
      ..lineTo(-24, -254)
      ..close();
    canvas.drawPath(visor, Paint()..color = const Color(0xFF11131C));
    canvas.drawPath(
      visor,
      Paint()
        ..color = const Color(0xFF00E5FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
    canvas.restore();
  }

  void _drawCocktailJazzLampDetails(Canvas canvas, Offset lanternCenter) {
    final double yawRad = cameraYaw * math.pi / 180.0;
    final double fedSin = math.sin(0.35 - yawRad);
    // Tilted midnight jazz fedora hat rotating in 3D on top of the lantern dome
    canvas.save();
    canvas.translate(fedSin * 6.0, -304);
    canvas.rotate(fedSin * 0.20);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 68, height: 14),
      Paint()..color = const Color(0xFF1C2331),
    );
    final Path crown = Path()
      ..moveTo(-20, 0)
      ..lineTo(-15, -22)
      ..quadraticBezierTo(fedSin * 4.0, -18, 15, -22)
      ..lineTo(20, 0)
      ..close();
    canvas.drawPath(crown, Paint()..color = const Color(0xFF283246));
    // Crimson ribbon band
    canvas.drawRect(
      const Rect.fromLTWH(-18, -5, 36, 4),
      Paint()..color = const Color(0xFFD32F2F),
    );
    canvas.restore();

    // Golden brass saxophone orbiting the base of the lamp at 70°
    final double saxRad = (70.0 - cameraYaw) * math.pi / 180.0;
    final double saxX = math.sin(saxRad) * 20.0;
    final double saxY = -12.0 + math.cos(saxRad) * 5.0;
    final double saxDir = math.sin(saxRad) >= 0 ? 1.0 : -1.0;
    canvas.save();
    canvas.translate(saxX, saxY);
    canvas.scale(saxDir, 1.0);
    final Path sax = Path()
      ..moveTo(-6, -38)
      ..lineTo(4, -8)
      ..quadraticBezierTo(8, 6, 16, 0)
      ..lineTo(20, -12);
    canvas.drawPath(
      sax,
      Paint()
        ..color = const Color(0xFFFFCA28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(20, -13), width: 11, height: 8),
      Paint()..color = const Color(0xFFFF8F00),
    );
    canvas.restore();

    // Floating jazz musical notes orbiting around the lantern in 3D
    for (int n = 0; n < 4; n++) {
      final double p = (time * 0.5 + n * 0.25) % 1.0;
      final double nRad = (n * 90.0 + 35.0 - cameraYaw) * math.pi / 180.0;
      final double nx = math.sin(nRad) * (40.0 + n * 5.0);
      final double ny = lanternCenter.dy - p * 45.0 + math.cos(nRad) * 6.0;
      final Paint npaint = Paint()
        ..color = const Color(0xFFFFD54F)
            .withValues(alpha: math.sin(p * math.pi).clamp(0.0, 1.0))
        ..strokeWidth = 2.0;
      canvas.drawCircle(Offset(nx, ny), 3.5, npaint);
      canvas.drawLine(Offset(nx + 3, ny), Offset(nx + 3, ny - 10), npaint);
    }
  }

  void _drawKingRoyalLampDetails(Canvas canvas, Offset lanternCenter) {
    final double yawRad = cameraYaw * math.pi / 180.0;
    // Crimson velvet royal banner hanging from the crossbar and rotating in 3D
    final double banWidth =
        (44.0 * math.cos(yawRad).abs()).clamp(10.0, 44.0);
    final double banHalf = banWidth * 0.5;
    final Path banner = Path()
      ..moveTo(-banHalf, -214)
      ..lineTo(banHalf, -214)
      ..lineTo(banHalf, -162)
      ..lineTo(0, -174)
      ..lineTo(-banHalf, -162)
      ..close();
    canvas.drawPath(banner, Paint()..color = const Color(0xFFB71C1C));
    canvas.drawPath(
      banner,
      Paint()
        ..color = const Color(0xFFFFD54F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Royal golden crown finial atop the dome with 6 rotating 3D points
    final Path crownBase = Path()
      ..moveTo(-18, -304)
      ..lineTo(-20, -313)
      ..lineTo(20, -313)
      ..lineTo(18, -304)
      ..close();
    canvas.drawPath(crownBase, Paint()..color = const Color(0xFFFFD54F));
    for (int p = 0; p < 6; p++) {
      final double pRad = (p * 60.0 - cameraYaw) * math.pi / 180.0;
      if (math.cos(pRad) < -0.25) continue;
      final double px = math.sin(pRad) * 18.0;
      canvas.drawPath(
        Path()
          ..moveTo(px - 4.5, -312)
          ..lineTo(px, -325)
          ..lineTo(px + 4.5, -312)
          ..close(),
        Paint()..color = const Color(0xFFFFD54F),
      );
      canvas.drawCircle(
        Offset(px, -325),
        2.0,
        Paint()..color = p.isEven ? const Color(0xFFE53935) : const Color(0xFF00E5FF),
      );
    }

    // City pigeon wearing a tiny golden crown perched on the rotating crossbar (90°)
    final double pigRad = (90.0 - cameraYaw) * math.pi / 180.0;
    final double pigX = math.sin(pigRad) * 28.0;
    final double pigY = -222.0 + math.cos(pigRad) * 2.5;
    final double pigDir = math.cos(pigRad) >= 0 ? 1.0 : -1.0;
    canvas.save();
    canvas.translate(pigX, pigY);
    canvas.scale(pigDir, 1.0);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 0), width: 13, height: 8),
      Paint()..color = const Color(0xFF90A4AE),
    );
    canvas.drawCircle(
      const Offset(5, -5),
      4.2,
      Paint()..color = const Color(0xFF78909C),
    );
    final Path tinyCrown = Path()
      ..moveTo(2, -8)
      ..lineTo(3, -13)
      ..lineTo(5, -10)
      ..lineTo(7, -13)
      ..lineTo(8, -8)
      ..close();
    canvas.drawPath(tinyCrown, Paint()..color = const Color(0xFFFFD54F));
    canvas.restore();
  }

  void _drawLofiCozyLampDetails(Canvas canvas, Offset lanternCenter) {
    final double yawRad = cameraYaw * math.pi / 180.0;
    // Giant studio headphones rotating in 3D over the glass lantern
    final double bandSpan =
        (72.0 * math.cos(yawRad).abs()).clamp(22.0, 72.0);
    canvas.drawArc(
      Rect.fromCenter(
        center: const Offset(0, -270),
        width: bandSpan,
        height: 68,
      ),
      math.pi * 1.05,
      math.pi * 0.90,
      false,
      Paint()
        ..color = const Color(0xFF263238)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.5
        ..strokeCap = StrokeCap.round,
    );
    for (final double earDeg in [270.0, 90.0]) {
      final double eRad = earDeg * math.pi / 180.0 - yawRad;
      final double ex = math.sin(eRad) * 32.0;
      final double ey = -262.0 + math.cos(eRad) * 3.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(ex, ey),
            width: 11,
            height: 24,
          ),
          const Radius.circular(5),
        ),
        Paint()..color = const Color(0xFFFF7043),
      );
    }

    // Warm striped knitted scarf wrapped around the lamp neck (-228) with 3D rotating stripes & tail
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-15, -234, 30, 11),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFD32F2F),
    );
    for (int st = 0; st < 6; st++) {
      final double stRad = (st * 60.0 - cameraYaw) * math.pi / 180.0;
      if (math.cos(stRad) <= 0.0) continue;
      final double sx = math.sin(stRad) * 11.0;
      canvas.drawRect(
        Rect.fromCenter(center: Offset(sx, -228.5), width: 4.2, height: 11),
        Paint()..color = const Color(0xFFFFF8E1),
      );
    }
    // Hanging scarf tail orbiting at 35° and swaying in the breeze
    final double tailRad = (35.0 - cameraYaw) * math.pi / 180.0;
    final double tailX = math.sin(tailRad) * 10.5;
    final double scarfSway = math.sin(time * 2.5) * 3.0;
    final Path scarfTail = Path()
      ..moveTo(tailX - 3.5, -224)
      ..quadraticBezierTo(
        tailX + 4 + scarfSway,
        -206,
        tailX + scarfSway,
        -190,
      )
      ..lineTo(tailX + 8 + scarfSway, -190)
      ..quadraticBezierTo(tailX + 10 + scarfSway, -206, tailX + 3.5, -224)
      ..close();
    canvas.drawPath(scarfTail, Paint()..color = const Color(0xFFD32F2F));

    // Sleepy orange tabby cat curled up at the base of the post orbiting at 295°
    final double catRad = (295.0 - cameraYaw) * math.pi / 180.0;
    final double catX = math.sin(catRad) * 22.0;
    final double catY = 6.0 + math.cos(catRad) * 6.0;
    canvas.save();
    canvas.translate(catX, catY);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 22, height: 12),
      Paint()..color = const Color(0xFFE67E22),
    );
    canvas.drawCircle(
      const Offset(7, -2),
      5.5,
      Paint()..color = const Color(0xFFD35400),
    );
    final double zp = (time * 0.45) % 1.0;
    final TextPainter ztp = TextPainter(
      text: TextSpan(
        text: 'zZz',
        style: TextStyle(
          color: const Color(0xFFFFF8E1).withValues(alpha: 1.0 - zp),
          fontSize: 9.0 + zp * 3.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    ztp.paint(canvas, Offset(6, -16 - zp * 16));
    canvas.restore();
  }

  // ===========================================================================
  // 9. WEATHER & ATMOSPHERIC OVERLAYS
  // ===========================================================================
  void _drawAtmosphericOverlay(Canvas canvas, Size size, double horizonY) {
    // 1. Slanted rain streaks & puddle splash rings in Rain mode (or Lofi style)
    if (atmosphereMode == CoconutAtmosphereMode.rain ||
        styleMode == CoconutStyleMode.lofi) {
      final Paint rainPaint = Paint()
        ..color = const Color(0xFFB3E5FC).withValues(alpha: 0.36)
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < 75; i++) {
        final double rx =
            ((i * 71.0 + time * 190.0) % (size.width + 120.0)) - 60.0;
        final double ry = (i * 49.0 + time * 560.0) % size.height;
        canvas.drawLine(Offset(rx, ry), Offset(rx - 8.0, ry + 24.0), rainPaint);
      }

      // Animated raindrop splash ripples on the cobblestone ground
      for (int s = 0; s < 18; s++) {
        final double sp = (time * 1.6 + s * 0.19) % 1.0;
        final double sx = ((s * 97.0) % size.width);
        final double sy =
            horizonY + (size.height - horizonY) * (0.28 + (s % 6) * 0.11);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(sx, sy),
            width: 6.0 + sp * 22.0,
            height: 2.0 + sp * 6.0,
          ),
          Paint()
            ..color = const Color(0xFFE1F5FE).withValues(alpha: (1.0 - sp) * 0.45)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.1,
        );
      }
    }

    // 2. Floating fireflies & nocturnal glow specks in Night mode
    if (atmosphereMode == CoconutAtmosphereMode.night) {
      for (int f = 0; f < 22; f++) {
        final double fx =
            ((f * 83.0 + math.sin(time * 0.9 + f) * 28.0) % size.width);
        final double fy = horizonY +
            (size.height - horizonY) * (0.15 + (f % 7) * 0.11) +
            math.cos(time * 1.4 + f) * 10.0;
        final double glow = 0.4 + 0.6 * math.sin(time * 3.2 + f * 1.3);
        canvas.drawCircle(
          Offset(fx, fy),
          2.6,
          Paint()
            ..color = const Color(0xFFFFF59D).withValues(alpha: glow * 0.75),
        );
      }
    }

    // 3. Warm diagonal sunbeams in Noon / Sunset modes
    if (atmosphereMode == CoconutAtmosphereMode.noon ||
        atmosphereMode == CoconutAtmosphereMode.sunset) {
      final Paint beamPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(size.width * 0.2, 0),
          Offset(size.width * 0.6, size.height * 0.8),
          [
            const Color(0xFFFFECB3).withValues(alpha: 0.10),
            Colors.transparent,
          ],
        );
      canvas.drawRect(Offset.zero & size, beamPaint);
    }

    // 4. Cozy Lo-Fi / European Evening Vignette
    final double vignetteAlpha =
        styleMode == CoconutStyleMode.lofi ? 0.50 : 0.36;
    final Paint vignette = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.5, size.height * 0.5),
        math.max(size.width, size.height) * 0.76,
        [
          Colors.transparent,
          Colors.black.withValues(alpha: vignetteAlpha),
        ],
        const [0.62, 1.0],
      );
    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(covariant StreetLampWorldPainter oldDelegate) {
    if (controller != null && oldDelegate.controller == controller) {
      return false;
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
