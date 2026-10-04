// ignore_for_file: prefer_initializing_formals
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../controllers/zenverse_controller.dart';
import 'coconut_world_painter.dart';

class PineForestWorldPainter extends CustomPainter {
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

  PineForestWorldPainter({
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

  double _angleWeight(double currentDeg, double targetDeg, double spreadDeg) {
    double diff = (currentDeg - targetDeg).abs() % 360.0;
    if (diff > 180.0) diff = 360.0 - diff;
    if (diff >= spreadDeg) return 0.0;
    return 0.5 * (1.0 + math.cos((diff / spreadDeg) * math.pi));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double horizonY = size.height * (0.50 + (cameraPitch / 90.0) * 0.45);

    // 1. Arctic Sky Gradient, Stars, Dancing Aurora Borealis, Sun/Moon & Clouds
    _drawSky(canvas, size, horizonY);
    _drawStarsAndAurora(canvas, size, horizonY);
    _drawSunAndMoon(canvas, size, horizonY);
    _drawClouds(canvas, size, horizonY);

    // 2. 360° Colossal Snow-Capped Alpine Peaks (Including at 0°!), Waterfall & Cable Car
    _drawAlpineMountainsAndWaterfall(canvas, size, horizonY);
    _drawMountainCableCar(canvas, size, horizonY);

    // 3. Glistening Snowdrifts, Frozen Mirror Glacier Lake, Stone Viaduct & Steam Snow-Train
    _drawFjordAndAlpineGroundBase(canvas, size, horizonY);
    _drawViaductAndSnowTrain(canvas, size, horizonY);

    // 4. Frozen Lake Skaters, Igloo, Fjord Vessels, Icebergs, Viking Longship & Whales
    _drawFrozenLakeSkatersAndIgloo(canvas, size, horizonY);
    _drawFjordVesselsAndWhales(canvas, size, horizonY);

    // 5. Soaring Eagles & Mountain Hawks
    _drawEaglesAndHawks(canvas, size, horizonY);

    // 6. 360° Background Pine Grove, Fire Lookout Tower & Stone Watchtower
    _drawBackgroundPineGroveAndTowers(canvas, size, horizonY);

    // 7. 74° Stave Church & Rorbuer Pier + Hot Tub,
    //    128° Alpine Ski Village, Downhill Skiers, Watermill & Chalet,
    //    165° Lapland Expedition Campfire, Sami Lavvu, Dog Sled & 7 Hikers
    _drawNordicStructuresAndCamps(canvas, size, horizonY);

    // 8. Midground Snow-Laden Pines, Reindeer Sleigh, Grazing Reindeer Herd & Snowmen
    _drawMidgroundPinesAndWildlife(canvas, size, horizonY);
    _drawForestPropsAndBoulders(canvas, size, horizonY);

    // 9. Center Foreground Object — The Massive 3D Scandinavian Pine Tree
    _drawCenterPineTree(canvas, size, horizonY);

    // 10. Weather & Atmospheric Overlay (Drifting Snowflakes, Aurora Dust, Lens Flare, Vignette)
    _drawAtmosphericOverlay(canvas, size, horizonY);
  }

  // ===========================================================================
  // 1. ARCTIC SKY, DANCING AURORA BOREALIS, SUN/MOON & VOLUMETRIC CLOUDS
  // ===========================================================================

  void _drawSky(Canvas canvas, Size size, double horizonY) {
    final double sunFocus = _angleWeight(cameraYaw, 0.0, 120.0);
    final List<Color> skyColors;
    final List<double> stops = const [0.0, 0.28, 0.58, 0.84, 1.0];

    switch (atmosphereMode) {
      case CoconutAtmosphereMode.sunset:
        // Arctic Aurora Twilight palette (distinctly Nordic & frosty)
        skyColors = [
          Color.lerp(const Color(0xFF071126), const Color(0xFF09152E), sunFocus)!,
          Color.lerp(const Color(0xFF162952), const Color(0xFF1B315E), sunFocus)!,
          Color.lerp(const Color(0xFF3B336A), const Color(0xFF4A3E78), sunFocus)!,
          Color.lerp(const Color(0xFFB56E65), const Color(0xFFD98A6C), sunFocus)!,
          Color.lerp(const Color(0xFFA8E6CF), const Color(0xFFC8F7E5), sunFocus)!,
        ];
        break;
      case CoconutAtmosphereMode.night:
        skyColors = [
          const Color(0xFF020612),
          const Color(0xFF061128),
          const Color(0xFF0B1F3F),
          const Color(0xFF103156),
          const Color(0xFF19466B),
        ];
        break;
      case CoconutAtmosphereMode.noon:
        skyColors = [
          const Color(0xFF0B3C8A),
          const Color(0xFF1967B8),
          const Color(0xFF4796E5),
          const Color(0xFF88C9F9),
          const Color(0xFFDFF4FF),
        ];
        break;
      case CoconutAtmosphereMode.rain:
        skyColors = [
          const Color(0xFF1B2738),
          const Color(0xFF2B3B50),
          const Color(0xFF41556E),
          const Color(0xFF5D738C),
          const Color(0xFF859BB2),
        ];
        break;
    }

    final Paint skyPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(0, math.max(horizonY + 30, 120)),
        skyColors,
        stops,
      );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, math.max(horizonY + 30, 120)),
      skyPaint,
    );
  }

  void _drawStarsAndAurora(Canvas canvas, Size size, double horizonY) {
    final bool isNight = atmosphereMode == CoconutAtmosphereMode.night;
    final bool isSunset = atmosphereMode == CoconutAtmosphereMode.sunset;
    if (!isNight && !isSunset) return;

    final double starOpacity = isNight ? 0.95 : 0.65;
    final Paint starPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 95; i++) {
      final double deg = (i * 37.89) % 360.0;
      final double? sx = _worldAngleToScreenX(deg, size, margin: 40);
      if (sx == null) continue;
      final double yFrac = ((i * 53.17) % 100.0) / 100.0;
      if (!isNight && yFrac > 0.68) continue;
      final double sy = horizonY * (0.04 + yFrac * 0.78);
      if (sy <= 0 || sy >= horizonY - 12) continue;

      final double twinkle =
          0.45 + 0.55 * math.sin(time * (1.8 + (i % 5) * 0.5) + i);
      final double radius = (i % 9 == 0) ? 2.1 : (i % 3 == 0 ? 1.4 : 0.9);
      starPaint.color = Colors.white.withValues(alpha: starOpacity * twinkle);
      canvas.drawCircle(Offset(sx, sy), radius, starPaint);

      if (i % 12 == 0) {
        final Paint glow = Paint()
          ..color = const Color(0xFFA7FFEB)
              .withValues(alpha: 0.35 * twinkle * starOpacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(Offset(sx, sy), radius * 2.6, glow);
      }
    }

    // Dancing Multi-Ribbon Green & Violet Aurora Borealis Curtains in BOTH Sunset & Night
    final double auroraAlpha = isNight ? 1.0 : 0.76;
    for (int ribbon = 0; ribbon < 3; ribbon++) {
      final Path auroraPath = Path();
      bool started = false;
      final double baseHeightFactor = 0.12 + ribbon * 0.10;
      final double ribbonHeight = 64.0 + ribbon * 16.0;

      final List<Offset> topPoints = [];
      final List<Offset> bottomPoints = [];

      for (int step = -2; step <= 26; step++) {
        final double sx = (step / 24.0) * size.width;
        final double worldAngle =
            cameraYaw + ((sx - size.width * 0.5) / size.width) * 110.0;
        final double wave1 = math.sin(
              worldAngle * 0.045 +
                  time * (0.65 + ribbon * 0.15) +
                  ribbon * 1.7,
            ) *
            22.0;
        final double wave2 =
            math.cos(worldAngle * 0.09 - time * 0.45 + ribbon * 2.4) * 12.0;
        final double yTop = horizonY * baseHeightFactor + wave1 + wave2;
        final double yBottom = yTop +
            ribbonHeight *
                (0.75 + 0.25 * math.sin(worldAngle * 0.06 + time * 0.8));
        topPoints.add(Offset(sx, yTop));
        bottomPoints.add(Offset(sx, yBottom));
      }

      for (int i = 0; i < topPoints.length; i++) {
        if (!started) {
          auroraPath.moveTo(topPoints[i].dx, topPoints[i].dy);
          started = true;
        } else {
          auroraPath.lineTo(topPoints[i].dx, topPoints[i].dy);
        }
      }
      for (int i = bottomPoints.length - 1; i >= 0; i--) {
        auroraPath.lineTo(bottomPoints[i].dx, bottomPoints[i].dy);
      }
      auroraPath.close();

      final Color topColor = ribbon == 1
          ? const Color(0xFFB388FF).withValues(alpha: 0.0)
          : const Color(0xFF00E676).withValues(alpha: 0.0);
      final Color midColor1 = ribbon == 1
          ? const Color(0xFFAA00FF).withValues(alpha: 0.36 * auroraAlpha)
          : const Color(0xFF00E5FF).withValues(alpha: 0.34 * auroraAlpha);
      final Color midColor2 = ribbon == 1
          ? const Color(0xFF00E676).withValues(alpha: 0.50 * auroraAlpha)
          : const Color(0xFF69F0AE).withValues(alpha: 0.56 * auroraAlpha);
      final Color botColor = const Color(0xFF00E676).withValues(alpha: 0.0);

      final Paint auroraPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, horizonY * baseHeightFactor - 30),
          Offset(0, horizonY * baseHeightFactor + ribbonHeight + 30),
          [topColor, midColor1, midColor2, botColor],
          const [0.0, 0.35, 0.78, 1.0],
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawPath(auroraPath, auroraPaint);

      // Vertical shimmering curtain rays inside the aurora
      final Paint rayPaint = Paint()
        ..strokeWidth = 2.4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      for (int r = 0; r < topPoints.length; r++) {
        final double pulse =
            0.3 + 0.7 * math.sin(time * 2.2 + r * 0.9 + ribbon).abs();
        rayPaint.color = (ribbon == 1
                ? const Color(0xFFEA80FC)
                : const Color(0xFF69F0AE))
            .withValues(alpha: 0.22 * pulse * auroraAlpha);
        canvas.drawLine(topPoints[r], bottomPoints[r], rayPaint);
      }
    }

    // Shooting stars in Night mode
    if (isNight) {
      for (int s = 0; s < 2; s++) {
        final double cycle = (time * 0.38 + s * 2.1) % 4.5;
        if (cycle < 1.1) {
          final double progress = cycle / 1.1;
          final double baseDeg = (s == 0 ? 35.0 : 210.0) + progress * 28.0;
          final double? sx = _worldAngleToScreenX(baseDeg, size);
          if (sx != null) {
            final double sy = horizonY * (0.14 + progress * 0.22);
            final Paint meteorPaint = Paint()
              ..shader = ui.Gradient.linear(
                Offset(sx, sy),
                Offset(sx - 65, sy - 28),
                [
                  Colors.white.withValues(alpha: 1.0 - progress),
                  const Color(0xFF69F0AE).withValues(alpha: 0.0),
                ],
              )
              ..strokeWidth = 2.4
              ..strokeCap = StrokeCap.round;
            canvas.drawLine(
              Offset(sx, sy),
              Offset(sx - 65, sy - 28),
              meteorPaint,
            );
          }
        }
      }
    }
  }

  void _drawSunAndMoon(Canvas canvas, Size size, double horizonY) {
    final double? sx = _worldAngleToScreenX(14.0, size, margin: 380);
    if (sx == null) return;

    if (atmosphereMode == CoconutAtmosphereMode.night) {
      final double moonY = horizonY - 165.0;
      final Offset center = Offset(sx, moonY);
      final Paint halo = Paint()
        ..shader = ui.Gradient.radial(
          center,
          135.0,
          [
            const Color(0xFFB2EBF2).withValues(alpha: 0.38),
            const Color(0xFF69F0AE).withValues(alpha: 0.14),
            Colors.transparent,
          ],
          const [0.0, 0.5, 1.0],
        );
      canvas.drawCircle(center, 135.0, halo);

      final Paint moonBody = Paint()
        ..shader = ui.Gradient.radial(
          center.translate(-10, -10),
          46.0,
          [
            const Color(0xFFFFFFF5),
            const Color(0xFFE0F7FA),
            const Color(0xFFB2EBF2),
          ],
          const [0.0, 0.65, 1.0],
        );
      canvas.drawCircle(center, 44.0, moonBody);

      final Paint crater = Paint()
        ..color = const Color(0xFF90A4AE).withValues(alpha: 0.26);
      canvas.drawCircle(center.translate(-12, -8), 8.0, crater);
      canvas.drawCircle(center.translate(14, 10), 11.0, crater);
      canvas.drawCircle(center.translate(6, -16), 5.5, crater);
      return;
    }

    final bool isNoon = atmosphereMode == CoconutAtmosphereMode.noon;
    final bool isRain = atmosphereMode == CoconutAtmosphereMode.rain;
    final double sunY = isNoon ? horizonY - 175.0 : horizonY - 135.0;
    final Offset sunCenter = Offset(sx, sunY);
    final double pulse = 1.0 + 0.04 * math.sin(time * 1.8);

    if (isRain) {
      final Paint mistGlow = Paint()
        ..shader = ui.Gradient.radial(
          sunCenter,
          140.0,
          [
            const Color(0xFFE1F5FE).withValues(alpha: 0.35),
            const Color(0xFF90CAF9).withValues(alpha: 0.10),
            Colors.transparent,
          ],
          const [0.0, 0.55, 1.0],
        );
      canvas.drawCircle(sunCenter, 140.0, mistGlow);
      canvas.drawCircle(
        sunCenter,
        36.0,
        Paint()..color = const Color(0xFFE3F2FD).withValues(alpha: 0.48),
      );
      return;
    }

    final Paint outerGlow = Paint()
      ..shader = ui.Gradient.radial(
        sunCenter,
        190.0 * pulse,
        isNoon
            ? [
                const Color(0xFFFFFDE7).withValues(alpha: 0.70),
                const Color(0xFF81D4FA).withValues(alpha: 0.25),
                Colors.transparent,
              ]
            : [
                const Color(0xFFE0F7FA).withValues(alpha: 0.75),
                const Color(0xFFFFCC80).withValues(alpha: 0.38),
                const Color(0xFF69F0AE).withValues(alpha: 0.0),
              ],
        const [0.0, 0.45, 1.0],
      );
    canvas.drawCircle(sunCenter, 190.0 * pulse, outerGlow);

    // Arctic sun halo ring (ice crystal parhelion / sundog effect)
    canvas.drawCircle(
      sunCenter,
      78.0 * pulse,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    final Paint sunCore = Paint()
      ..shader = ui.Gradient.linear(
        Offset(sunCenter.dx, sunCenter.dy - 44),
        Offset(sunCenter.dx, sunCenter.dy + 44),
        isNoon
            ? [const Color(0xFFFFFFFF), const Color(0xFFE1F5FE)]
            : [
                const Color(0xFFFFFFFF),
                const Color(0xFFFFF59D),
                const Color(0xFFFFCC80),
              ],
        isNoon ? const [0.0, 1.0] : const [0.0, 0.55, 1.0],
      );
    canvas.drawCircle(sunCenter, 42.0 * pulse, sunCore);
  }

  void _drawClouds(Canvas canvas, Size size, double horizonY) {
    for (int i = 0; i < 16; i++) {
      final double speed = 0.32 + (i % 4) * 0.11;
      final double baseDeg = (i * 22.5 + time * speed) % 360.0;
      final double? cx = _worldAngleToScreenX(baseDeg, size, margin: 260);
      if (cx == null) continue;

      final double yFrac = 0.10 + (i % 4) * 0.08;
      final double cy = horizonY * yFrac;
      final double scale = 0.82 + (i % 4) * 0.20;

      Path cloudPath = Path()
        ..addOval(
          Rect.fromCenter(
            center: Offset(cx, cy),
            width: 115 * scale,
            height: 40 * scale,
          ),
        );
      final List<Rect> puffs = [
        Rect.fromCenter(
          center: Offset(cx - 32 * scale, cy - 10 * scale),
          width: 66 * scale,
          height: 44 * scale,
        ),
        Rect.fromCenter(
          center: Offset(cx + 6 * scale, cy - 16 * scale),
          width: 76 * scale,
          height: 52 * scale,
        ),
        Rect.fromCenter(
          center: Offset(cx + 38 * scale, cy - 8 * scale),
          width: 62 * scale,
          height: 40 * scale,
        ),
      ];
      for (final rect in puffs) {
        cloudPath = Path.combine(
          PathOperation.union,
          cloudPath,
          Path()..addOval(rect),
        );
      }

      Color topCol;
      Color botCol;
      Color rimCol;
      switch (atmosphereMode) {
        case CoconutAtmosphereMode.sunset:
          topCol = const Color(0xFFE0F7FA).withValues(alpha: 0.86);
          botCol = const Color(0xFF5E548E).withValues(alpha: 0.82);
          rimCol = const Color(0xFFA7FFEB).withValues(alpha: 0.72);
          break;
        case CoconutAtmosphereMode.night:
          topCol = const Color(0xFF264160).withValues(alpha: 0.78);
          botCol = const Color(0xFF0E1D33).withValues(alpha: 0.85);
          rimCol = const Color(0xFF69F0AE).withValues(alpha: 0.35);
          break;
        case CoconutAtmosphereMode.noon:
          topCol = const Color(0xFFFFFFFF).withValues(alpha: 0.94);
          botCol = const Color(0xFFD0E8FA).withValues(alpha: 0.88);
          rimCol = const Color(0xFFFFFFFF).withValues(alpha: 0.80);
          break;
        case CoconutAtmosphereMode.rain:
          topCol = const Color(0xFF6E8296).withValues(alpha: 0.92);
          botCol = const Color(0xFF3E4F61).withValues(alpha: 0.94);
          rimCol = const Color(0xFF90A4AE).withValues(alpha: 0.45);
          break;
      }

      final Paint fillPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(cx, cy - 36 * scale),
          Offset(cx, cy + 20 * scale),
          [topCol, botCol],
        );
      canvas.drawPath(cloudPath, fillPaint);

      final Paint rimPaint = Paint()
        ..color = rimCol
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawPath(cloudPath, rimPaint);
    }
  }

  // ===========================================================================
  // 2. 360° COLOSSAL SNOW-CAPPED ALPINE PEAKS (INCLUDING AT 0°!), WATERFALL & CABLE CAR
  // ===========================================================================

  void _drawAlpineMountainsAndWaterfall(
    Canvas canvas,
    Size size,
    double horizonY,
  ) {
    final bool isNight = atmosphereMode == CoconutAtmosphereMode.night;
    final bool isSunset = atmosphereMode == CoconutAtmosphereMode.sunset;
    final bool isRain = atmosphereMode == CoconutAtmosphereMode.rain;

    // 12 Towering Jagged Snow-Capped Alpine Peaks all around 0°..360°
    // Ensures looking at 0° shows colossal Matterhorn/Lofoten glacier peaks!
    final List<Map<String, double>> peaks = [
      {'deg': -32.0, 'w': 390.0, 'h': 245.0},
      {'deg': 0.0, 'w': 430.0, 'h': 268.0}, // Colossal Center Matterhorn Peak at 0°!
      {'deg': 32.0, 'w': 395.0, 'h': 242.0},
      {'deg': 65.0, 'w': 360.0, 'h': 212.0},
      {'deg': 96.0, 'w': 380.0, 'h': 230.0},
      {'deg': 128.0, 'w': 420.0, 'h': 260.0}, // Ski Village Peak
      {'deg': 158.0, 'w': 410.0, 'h': 250.0},
      {'deg': 182.0, 'w': 450.0, 'h': 280.0}, // Glacier Waterfall Peak
      {'deg': 212.0, 'w': 415.0, 'h': 255.0}, // Gondola Upper Station Peak
      {'deg': 242.0, 'w': 385.0, 'h': 225.0},
      {'deg': 275.0, 'w': 360.0, 'h': 205.0},
      {'deg': 308.0, 'w': 375.0, 'h': 222.0},
    ];

    final Color sunlitRock = isNight
        ? const Color(0xFF1E3552)
        : (isSunset
            ? const Color(0xFF3F5277)
            : (isRain ? const Color(0xFF475B70) : const Color(0xFF4B6B88)));
    final Color shadowRock = isNight
        ? const Color(0xFF0E1B2E)
        : (isSunset
            ? const Color(0xFF23304C)
            : (isRain ? const Color(0xFF2F3E4E) : const Color(0xFF2B4257)));
    final Color sunlitSnow = isNight
        ? const Color(0xFFD0F8FF)
        : (isSunset ? const Color(0xFFF2FBFF) : const Color(0xFFFFFFFF));
    final Color shadowSnow = isNight
        ? const Color(0xFF6897BB)
        : (isSunset ? const Color(0xFF9CC5E0) : const Color(0xFFCFD8DC));

    for (int i = 0; i < peaks.length; i++) {
      final p = peaks[i];
      final double? px = _worldAngleToScreenX(p['deg']!, size, margin: 460);
      if (px == null) continue;
      final double w = p['w']!;
      final double h = p['h']!;
      final double topY = horizonY - h;

      // Left sunlit granite facet
      final Path leftFacet = Path()
        ..moveTo(px - w * 0.52, horizonY + 18)
        ..lineTo(px - w * 0.26, topY + h * 0.34)
        ..lineTo(px - w * 0.14, topY + h * 0.42)
        ..lineTo(px, topY)
        ..lineTo(px + w * 0.04, topY + h * 0.38)
        ..lineTo(px - w * 0.06, topY + h * 0.68)
        ..lineTo(px, horizonY + 18)
        ..close();
      canvas.drawPath(leftFacet, Paint()..color = sunlitRock);

      // Right shadow granite facet
      final Path rightFacet = Path()
        ..moveTo(px, topY)
        ..lineTo(px + w * 0.22, topY + h * 0.32)
        ..lineTo(px + w * 0.31, topY + h * 0.26)
        ..lineTo(px + w * 0.52, horizonY + 18)
        ..lineTo(px, horizonY + 18)
        ..lineTo(px - w * 0.06, topY + h * 0.68)
        ..lineTo(px + w * 0.04, topY + h * 0.38)
        ..close();
      canvas.drawPath(rightFacet, Paint()..color = shadowRock);

      // Deep Snow Cap (Left sunlit snow reaching 58% down the mountain!)
      final Path leftSnow = Path()
        ..moveTo(px, topY)
        ..lineTo(px - w * 0.31, topY + h * 0.54)
        ..lineTo(px - w * 0.19, topY + h * 0.46)
        ..lineTo(px - w * 0.09, topY + h * 0.60)
        ..lineTo(px + w * 0.04, topY + h * 0.48)
        ..close();
      canvas.drawPath(leftSnow, Paint()..color = sunlitSnow);

      // Deep Snow Cap (Right shadow snow)
      final Path rightSnow = Path()
        ..moveTo(px, topY)
        ..lineTo(px + w * 0.04, topY + h * 0.48)
        ..lineTo(px + w * 0.14, topY + h * 0.58)
        ..lineTo(px + w * 0.22, topY + h * 0.44)
        ..lineTo(px + w * 0.34, topY + h * 0.54)
        ..close();
      canvas.drawPath(rightSnow, Paint()..color = shadowSnow);

      // Drifting valley mist band at mountain base
      final Paint mistPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(px, horizonY - 36),
          Offset(px, horizonY + 18),
          [
            Colors.white.withValues(alpha: 0.0),
            (isNight ? const Color(0xFF80CBC4) : Colors.white)
                .withValues(alpha: 0.22),
            Colors.white.withValues(alpha: 0.0),
          ],
          const [0.0, 0.5, 1.0],
        );
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(
            px + math.sin(time * 0.4 + i) * 18,
            horizonY - 8,
          ),
          width: w * 0.9,
          height: 44,
        ),
        mistPaint,
      );
    }

    // Wide Multi-Tiered Alpine Glacier Waterfall at 182°
    final double? wx = _worldAngleToScreenX(182.0, size, margin: 320);
    if (wx != null) {
      final double groundHeight = size.height - horizonY;
      final double topY = horizonY - 175.0;
      final double botY = horizonY + groundHeight * 0.14;

      final Path fallsPath = Path()
        ..moveTo(wx - 16, topY)
        ..lineTo(wx + 16, topY)
        ..lineTo(wx + 36, horizonY - 40)
        ..lineTo(wx + 52, botY)
        ..lineTo(wx - 48, botY)
        ..lineTo(wx - 32, horizonY - 40)
        ..close();

      final Paint fallsPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(wx, topY),
          Offset(wx, botY),
          [
            const Color(0xFFE0F7FA),
            const Color(0xFF4DD0E1),
            const Color(0xFF00ACC1),
            const Color(0xFF80DEEA),
          ],
          const [0.0, 0.4, 0.8, 1.0],
        );
      canvas.drawPath(fallsPath, fallsPaint);

      final Paint streakPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.82)
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;
      for (int s = 0; s < 14; s++) {
        final double progress = ((time * 1.4 + s * 0.19) % 1.0);
        final double sy = topY + progress * (botY - topY);
        final double spread = 12.0 + progress * 28.0;
        final double offsetX = ((s % 5) - 2.0) * (spread * 0.42);
        canvas.drawLine(
          Offset(wx + offsetX, sy),
          Offset(wx + offsetX * 1.08, math.min(sy + 24.0, botY)),
          streakPaint,
        );
      }

      final Paint ledgePaint = Paint()..color = shadowRock;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(wx - 18, topY + 62),
            width: 26,
            height: 10,
          ),
          const Radius.circular(4),
        ),
        ledgePaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(wx + 20, topY + 118),
            width: 30,
            height: 12,
          ),
          const Radius.circular(4),
        ),
        ledgePaint,
      );

      final Paint mistPool = Paint()
        ..color = Colors.white.withValues(alpha: 0.78)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      for (int m = 0; m < 5; m++) {
        final double mx = wx - 36 + m * 18 + math.sin(time * 2.5 + m) * 5;
        final double my = botY - 4 + math.cos(time * 2.0 + m) * 3;
        canvas.drawOval(
          Rect.fromCenter(center: Offset(mx, my), width: 38, height: 18),
          mistPool,
        );
      }
    }
  }

  void _drawMountainCableCar(Canvas canvas, Size size, double horizonY) {
    final double? xUpper = _worldAngleToScreenX(212.0, size, margin: 480);
    final double? xLower = _worldAngleToScreenX(242.0, size, margin: 480);
    if (xUpper == null && xLower == null) return;

    final double sx1 =
        xUpper ?? _worldAngleToScreenX(212.0, size, margin: 1200) ?? -400;
    final double sx2 = xLower ??
        _worldAngleToScreenX(242.0, size, margin: 1200) ??
        size.width + 400;
    final double sy1 = horizonY - 210.0;
    final double sy2 = horizonY - 42.0;

    void drawStationTower(double tx, double ty, double scale) {
      canvas.save();
      canvas.translate(tx, ty);
      canvas.scale(scale);
      final Paint steel = Paint()
        ..color = const Color(0xFF37474F)
        ..strokeWidth = 3.2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(const Offset(-12, 34), const Offset(-4, 0), steel);
      canvas.drawLine(const Offset(12, 34), const Offset(4, 0), steel);
      canvas.drawLine(const Offset(-16, 2), const Offset(16, 2), steel);
      canvas.drawLine(const Offset(-9, 18), const Offset(9, 18), steel);
      canvas.drawRect(
        const Rect.fromLTWH(-18, 22, 36, 16),
        Paint()..color = const Color(0xFF4E342E),
      );
      canvas.drawRect(
        const Rect.fromLTWH(-12, 25, 24, 9),
        Paint()..color = const Color(0xFFFFD54F),
      );
      canvas.restore();
    }

    drawStationTower(sx1, sy1, 1.45);
    drawStationTower(sx2, sy2, 1.75);

    final Path cablePath = Path()
      ..moveTo(sx1, sy1 + 2)
      ..quadraticBezierTo(
        (sx1 + sx2) * 0.5,
        (sy1 + sy2) * 0.5 + 22.0,
        sx2,
        sy2 + 2,
      );
    canvas.drawPath(
      cablePath,
      Paint()
        ..color = const Color(0xFF263238)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );

    final double t = 0.5 + 0.42 * math.sin(time * 0.45);
    final double cx = (1 - t) * (1 - t) * sx1 +
        2 * (1 - t) * t * ((sx1 + sx2) * 0.5) +
        t * t * sx2;
    final double cy = (1 - t) * (1 - t) * (sy1 + 2) +
        2 * (1 - t) * t * ((sy1 + sy2) * 0.5 + 22.0) +
        t * t * (sy2 + 2);

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(1.85);
    final Paint hangerPaint = Paint()
      ..color = const Color(0xFF263238)
      ..strokeWidth = 2.2;
    canvas.drawCircle(const Offset(-4, 0), 3.0, hangerPaint);
    canvas.drawCircle(const Offset(4, 0), 3.0, hangerPaint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, 14), hangerPaint);

    final RRect cabinRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-18, 14, 36, 24),
      const Radius.circular(6),
    );
    canvas.drawRRect(cabinRect, Paint()..color = const Color(0xFFD32F2F));
    canvas.drawRect(
      const Rect.fromLTWH(-18, 28, 36, 4),
      Paint()..color = Colors.white,
    );
    final Paint winGlow = Paint()..color = const Color(0xFFFFF59D);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-14, 17, 12, 9),
        const Radius.circular(2),
      ),
      winGlow,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(2, 17, 12, 9),
        const Radius.circular(2),
      ),
      winGlow,
    );
    final Paint silPaint = Paint()..color = const Color(0xFF3E2723);
    canvas.drawCircle(const Offset(-8, 22), 2.5, silPaint);
    canvas.drawCircle(const Offset(8, 22), 2.5, silPaint);
    canvas.restore();
  }

  // ===========================================================================
  // 3. GLISTENING SNOWDRIFTS, FROZEN GLACIER LAKE, VIADUCT & STEAM SNOW-TRAIN
  // ===========================================================================

  void _drawFjordAndAlpineGroundBase(
    Canvas canvas,
    Size size,
    double horizonY,
  ) {
    final bool isNight = atmosphereMode == CoconutAtmosphereMode.night;
    final double groundHeight = size.height - horizonY;

    // Step 1: Deep Nordic Fjord Water Base in the upper bay (0 .. 0.34 of groundHeight)
    final Rect fjordRect = Rect.fromLTWH(
      0,
      horizonY,
      size.width,
      groundHeight * 0.36,
    );
    final Paint fjordPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(size.width * 0.5, horizonY),
        Offset(size.width * 0.5, horizonY + groundHeight * 0.34),
        isNight
            ? [
                const Color(0xFF061A2E),
                const Color(0xFF0C2E4A),
                const Color(0xFF14496B),
              ]
            : [
                const Color(0xFF0A4F70),
                const Color(0xFF147496),
                const Color(0xFF299EC2),
              ],
        const [0.0, 0.55, 1.0],
      );
    canvas.drawRect(fjordRect, fjordPaint);

    // Subtle shimmering ripples on the outer fjord water (+32°..+86° and -86°..-32°)
    final Paint waterRipplePaint = Paint()
      ..color = (isNight ? const Color(0xFF80DEEA) : Colors.white)
          .withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (int r = 0; r < 28; r++) {
      final double rDeg = -84.0 + r * 6.2;
      if (rDeg.abs() < 26.0) continue;
      final double? rx = _worldAngleToScreenX(rDeg, size, margin: 100);
      if (rx == null) continue;
      final double cycle = (time * 0.22 + r * 0.13) % 1.0;
      final double ry = horizonY + groundHeight * (0.06 + cycle * 0.18);
      final double rw = 18.0 + cycle * 44.0;
      canvas.drawLine(Offset(rx - rw * 0.5, ry), Offset(rx + rw * 0.5, ry), waterRipplePaint);
    }

    // Step 2: Natural Snow-Banked Frozen Glacier Ice Sheet at -30°..+30° (yFactor: 0.16..0.31 of groundHeight)
    final int iceSteps = 44;
    final Path iceSheetPath = Path();
    bool iceStarted = false;
    final List<Offset> iceBottomEdge = [];

    for (int i = 0; i <= iceSteps; i++) {
      final double deg = -34.0 + (i / iceSteps) * 68.0;
      final double? sx = _worldAngleToScreenX(deg, size, margin: 600);
      if (sx == null) continue;
      final double glacierWeight = _angleWeight(deg, 0.0, 34.0);
      final double topY =
          horizonY + groundHeight * (0.15 + (1.0 - glacierWeight) * 0.04);
      final double botY =
          horizonY +
          groundHeight * (0.17 + 0.135 * glacierWeight) +
          math.sin(deg * 0.18) * 2.5;
      if (!iceStarted) {
        iceSheetPath.moveTo(sx, topY);
        iceStarted = true;
      } else {
        iceSheetPath.lineTo(sx, topY);
      }
      iceBottomEdge.add(Offset(sx, botY));
    }
    if (iceStarted && iceBottomEdge.isNotEmpty) {
      for (int i = iceBottomEdge.length - 1; i >= 0; i--) {
        iceSheetPath.lineTo(iceBottomEdge[i].dx, iceBottomEdge[i].dy);
      }
      iceSheetPath.close();

      canvas.save();
      canvas.clipPath(iceSheetPath);
      canvas.drawPath(
        iceSheetPath,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(size.width * 0.5, horizonY + groundHeight * 0.15),
            Offset(size.width * 0.5, horizonY + groundHeight * 0.31),
            isNight
                ? [
                    const Color(0xFF154360),
                    const Color(0xFF1F618D),
                    const Color(0xFF2E86C1),
                  ]
                : [
                    const Color(0xFFB3E5FC),
                    const Color(0xFF81D4FA),
                    const Color(0xFFE1F5FE),
                  ],
            const [0.0, 0.55, 1.0],
          ),
      );

      // Crystalline figure-8 ice-skate scratch arcs & mirror sheen on the frozen glacier lake
      final double? lakeCenterX = _worldAngleToScreenX(0.0, size, margin: 700);
      if (lakeCenterX != null) {
        final Paint iceSheen = Paint()
          ..color = Colors.white.withValues(alpha: isNight ? 0.30 : 0.68)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6;
        final double centerIceY = horizonY + groundHeight * 0.24;
        for (int k = -2; k <= 2; k++) {
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(lakeCenterX + k * 52.0, centerIceY),
              width: 110,
              height: 20,
            ),
            iceSheen,
          );
        }
      }
      canvas.restore();
    }

    // Step 3: Continuous 360° Curved Shoreline & Uninterrupted Sculpted Alpine Snowground
    // From horizonY + groundHeight * 0.31 down to size.height (1.0), the entire lower screen is pure continuous snow!
    final int segments = 56;
    final double dx = size.width / segments;
    final Path snowBankRimPath = Path();
    final Path snowGroundPath = Path();

    for (int i = 0; i <= segments; i++) {
      final double x = i * dx;
      final double worldAngle =
          (cameraYaw + ((x / size.width) - 0.5) * (110.0 / cameraZoom)) % 360.0;
      final double positiveAngle =
          worldAngle < 0 ? worldAngle + 360.0 : worldAngle;

      // Smooth cosine bayFactor across -92°..+92°: 1.0 at 0° bay, 0.0 inland
      final double bayFactor = _angleWeight(positiveAngle, 0.0, 92.0);
      final double glacierCenterFactor = _angleWeight(positiveAngle, 0.0, 34.0);
      final double naturalDrift =
          math.sin(positiveAngle * 0.11) * 3.5 +
          math.cos(positiveAngle * 0.23) * 2.0;

      // Shoreline stays strictly at <= 0.31 of groundHeight!
      final double shoreFactor =
          0.06 + 0.19 * bayFactor + 0.055 * glacierCenterFactor;
      final double shoreY =
          horizonY + groundHeight * shoreFactor + naturalDrift;

      if (i == 0) {
        snowBankRimPath.moveTo(x, shoreY - 4.5 * bayFactor);
        snowGroundPath.moveTo(x, shoreY);
      } else {
        snowBankRimPath.lineTo(x, shoreY - 4.5 * bayFactor);
        snowGroundPath.lineTo(x, shoreY);
      }
    }

    snowBankRimPath
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    snowGroundPath
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    // Soft glistening snowbank shoreline cushion
    canvas.drawPath(
      snowBankRimPath,
      Paint()
        ..color = (isNight ? const Color(0xFF80DEEA) : Colors.white)
            .withValues(alpha: 0.88),
    );

    // Main continuous 360° Alpine Snowfield down to the bottom of the screen
    final Paint snowGroundPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(size.width * 0.5, horizonY),
        Offset(size.width * 0.5, size.height),
        isNight
            ? [
                const Color(0xFF21465E),
                const Color(0xFF173447),
                const Color(0xFF0E2231),
              ]
            : [
                const Color(0xFFFFFFFF),
                const Color(0xFFD8EEFA),
                const Color(0xFFB3DDF2),
              ],
        const [0.0, 0.55, 1.0],
      );
    canvas.drawPath(snowGroundPath, snowGroundPaint);

    // Step 4: Soft Rolling Lapland Snow Ridges & Wind-Carved Snow Ripples across the snowground
    for (int layer = 0; layer < 2; layer++) {
      final Path snowRidgePath = Path()..moveTo(0, size.height);
      final double baseFactor = 0.28 + layer * 0.16;
      for (int step = 0; step <= 32; step++) {
        final double sx = (step / 32.0) * size.width;
        final double deg =
            (cameraYaw + ((sx - size.width * 0.5) / size.width) * 110.0) %
                360.0;
        final double hillWave = math.sin(deg * 0.08 + layer * 1.5) * 8.0 +
            math.cos(deg * 0.15 - layer) * 4.5;
        snowRidgePath.lineTo(
          sx,
          horizonY + groundHeight * baseFactor + hillWave,
        );
      }
      snowRidgePath.lineTo(size.width, size.height);
      snowRidgePath.close();

      canvas.drawPath(
        snowRidgePath,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, horizonY + groundHeight * baseFactor),
            Offset(0, size.height),
            isNight
                ? [
                    Color(layer == 0 ? 0xFF1E4158 : 0xFF173447)
                        .withValues(alpha: 0.72),
                    const Color(0xFF0E2231).withValues(alpha: 0.90),
                  ]
                : [
                    Color(layer == 0 ? 0xFFF5FBFF : 0xFFE3F3FC)
                        .withValues(alpha: 0.85),
                    const Color(0xFFC5E3F6).withValues(alpha: 0.92),
                  ],
          ),
      );
    }

    // Wind-carved snow ripple lines & sparkling ice crystals across the snowground
    final Paint driftShadow = Paint()
      ..color = (isNight ? const Color(0xFF0A1926) : const Color(0xFF90C2DE))
          .withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    final Paint driftHighlight = Paint()
      ..color = Colors.white.withValues(alpha: isNight ? 0.24 : 0.68)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 54; i++) {
      final double angle = (i * 6.67 + 11.0) % 360.0;
      final double? rx = _worldAngleToScreenX(angle, size, margin: 120);
      if (rx == null) continue;
      final double depth = 0.33 + ((i * 29) % 62) / 100.0;
      final double ry = horizonY + groundHeight * depth;
      final double w = 28.0 + (i % 5) * 16.0;

      final Path p = Path()
        ..moveTo(rx - w, ry)
        ..quadraticBezierTo(rx, ry + 4.0, rx + w, ry - 1.5);
      canvas.drawPath(p, driftShadow);
      canvas.drawPath(p.shift(const Offset(0, -1.8)), driftHighlight);
    }
  }

  void _drawViaductAndSnowTrain(Canvas canvas, Size size, double horizonY) {
    // Monumental 7-Arch Stone Mountain Viaduct Bridge spanning across 0° (-42°..+42°, yFactor: 0.14 of groundHeight)
    final double? vxCenter = _worldAngleToScreenX(0.0, size, margin: 900);
    if (vxCenter == null) return;

    final double groundHeight = size.height - horizonY;
    final double bridgeY = horizonY + groundHeight * 0.14;
    const double bridgeWidth = 680.0;
    const double deckTopY = -58.0;

    canvas.save();
    canvas.translate(vxCenter, bridgeY);

    // Stone Viaduct Piers & 7 Rounded Roman Arches
    final Path viaductPath = Path()
      ..moveTo(-bridgeWidth * 0.5, 0)
      ..lineTo(-bridgeWidth * 0.5, deckTopY)
      ..lineTo(bridgeWidth * 0.5, deckTopY)
      ..lineTo(bridgeWidth * 0.5, 0);

    const int archCount = 7;
    const double span = bridgeWidth / archCount;
    for (int a = archCount - 1; a >= 0; a--) {
      final double archRight = -bridgeWidth * 0.5 + (a + 1) * span - 9.0;
      final double archLeft = -bridgeWidth * 0.5 + a * span + 9.0;
      final double archMid = (archLeft + archRight) * 0.5;
      viaductPath.lineTo(archRight, 0);
      viaductPath.lineTo(archRight, -24);
      viaductPath.quadraticBezierTo(archMid, -48, archLeft, -24);
      viaductPath.lineTo(archLeft, 0);
    }
    viaductPath.close();

    canvas.drawPath(
      viaductPath,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, deckTopY),
          const Offset(0, 0),
          [
            const Color(0xFF78909C),
            const Color(0xFF455A64),
          ],
        ),
    );

    // Snow-topped parapet wall along the viaduct deck
    canvas.drawRect(
      const Rect.fromLTWH(-bridgeWidth * 0.5, deckTopY - 5, bridgeWidth, 6),
      Paint()..color = Colors.white,
    );

    // Animated Bright Red & Gold Nordic Steam Snow-Train (Flåm / Bernina Express)
    final double trainX =
        ((time * 48.0) % (bridgeWidth + 240.0)) - (bridgeWidth * 0.5 + 120.0);

    canvas.save();
    canvas.translate(trainX, deckTopY - 4);
    canvas.scale(1.45);

    // 3 Passenger Carriages with warm glowing panoramic windows
    for (int c = 1; c <= 3; c++) {
      final double cx = -c * 46.0;
      // Coupler
      canvas.drawLine(
        Offset(cx + 38, -8),
        Offset(cx + 46, -8),
        Paint()
          ..color = const Color(0xFF263238)
          ..strokeWidth = 2.5,
      );
      // Red carriage body
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx, -22, 38, 16),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFFC62828),
      );
      // Gold stripe & snow roof
      canvas.drawRect(
        Rect.fromLTWH(cx, -9, 38, 2),
        Paint()..color = const Color(0xFFFFD54F),
      );
      canvas.drawRect(
        Rect.fromLTWH(cx - 1, -24, 40, 3),
        Paint()..color = Colors.white,
      );
      // 3 Glowing windows per carriage
      for (int w = 0; w < 3; w++) {
        canvas.drawRect(
          Rect.fromLTWH(cx + 4 + w * 11.0, -19, 8, 7),
          Paint()..color = const Color(0xFFFFF59D),
        );
      }
      // Wheels
      for (final wx in [cx + 8, cx + 30]) {
        canvas.drawCircle(
          Offset(wx, -3),
          3.5,
          Paint()..color = const Color(0xFF263238),
        );
      }
    }

    // Steam Locomotive at the front
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, -24, 16, 18),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFFB71C1C),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(14, -19, 24, 13),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF263238),
    );
    // Smokestack & golden headlamp
    canvas.drawRect(
      const Rect.fromLTWH(28, -27, 5, 9),
      Paint()..color = const Color(0xFF263238),
    );
    canvas.drawCircle(
      const Offset(39, -14),
      3.0,
      Paint()..color = const Color(0xFFFFEA00),
    );
    // Silver snowplow cowcatcher at front of locomotive
    final Path plow = Path()
      ..moveTo(38, -6)
      ..lineTo(46, -2)
      ..lineTo(38, -2)
      ..close();
    canvas.drawPath(plow, Paint()..color = const Color(0xFFCFD8DC));

    // Billowing white steam clouds from locomotive smokestack
    for (int st = 0; st < 6; st++) {
      final double p = ((time * 1.5 + st * 0.17) % 1.0);
      final double sx = 30.0 - p * 42.0;
      final double sy = -30.0 - p * 26.0;
      canvas.drawCircle(
        Offset(sx, sy),
        4.5 + p * 8.5,
        Paint()
          ..color = Colors.white.withValues(alpha: (1.0 - p) * 0.82)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }

    canvas.restore();
    canvas.restore();
  }

  // ===========================================================================
  // 4. FROZEN LAKE SKATERS, SNOW IGLOO, FJORD VESSELS, VIKING LONGSHIP & WHALES
  // ===========================================================================

  void _drawFrozenLakeSkatersAndIgloo(
    Canvas canvas,
    Size size,
    double horizonY,
  ) {
    final double groundHeight = size.height - horizonY;

    // Domed Snow Igloo on the Left Bank of the Frozen Lake (-30°, yFactor: 0.23 of groundHeight)
    final double? iglooX = _worldAngleToScreenX(-30.0, size);
    if (iglooX != null) {
      final double iglooY = horizonY + groundHeight * 0.23;
      canvas.save();
      canvas.translate(iglooX, iglooY);
      canvas.scale(1.65);

      // Igloo snow dome
      final Path dome = Path()
        ..moveTo(-28, 0)
        ..arcToPoint(
          const Offset(28, 0),
          radius: const Radius.circular(28),
          clockwise: true,
        )
        ..close();
      canvas.drawPath(
        dome,
        Paint()
          ..shader = ui.Gradient.linear(
            const Offset(-20, -28),
            const Offset(20, 0),
            [Colors.white, const Color(0xFFB3E5FC)],
          ),
      );
      // Ice-block mortar grid lines
      final Paint seamPaint = Paint()
        ..color = const Color(0xFF81D4FA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;
      canvas.drawPath(dome, seamPaint);
      canvas.drawLine(const Offset(-26, -9), const Offset(26, -9), seamPaint);
      canvas.drawLine(const Offset(-21, -18), const Offset(21, -18), seamPaint);

      // Glowing tunnel entrance on the right side
      canvas.drawArc(
        const Rect.fromLTWH(14, -15, 20, 30),
        math.pi,
        math.pi,
        true,
        Paint()..color = const Color(0xFFE1F5FE),
      );
      canvas.drawArc(
        const Rect.fromLTWH(18, -11, 13, 22),
        math.pi,
        math.pi,
        true,
        Paint()..color = const Color(0xFFFFD54F),
      );

      // Ice fisherman sitting on crate fishing through an ice hole beside the igloo
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(56, 4), width: 16, height: 6),
        Paint()..color = const Color(0xFF0277BD),
      );
      _drawArticulatedPerson(
        canvas,
        38,
        0,
        coatColor: const Color(0xFFD84315),
        sitting: true,
        fishing: true,
      );
      canvas.restore();
    }

    // 5 Animated Ice Skaters gliding in graceful figure-8 curves on the Frozen Lake (-22°..+22°)
    final List<Color> skaterCoats = [
      const Color(0xFFE53935),
      const Color(0xFF1E88E5),
      const Color(0xFF8E24AA),
      const Color(0xFF00897B),
      const Color(0xFFFDD835),
    ];
    for (int s = 0; s < 5; s++) {
      final double baseDeg = -18.0 + s * 8.5;
      final double skateDeg =
          baseDeg + math.sin(time * (1.1 + s * 0.15) + s * 1.3) * 6.5;
      final double? sx = _worldAngleToScreenX(skateDeg, size);
      if (sx == null) continue;
      final double sy = horizonY +
          groundHeight * (0.21 + (s % 3) * 0.032) +
          math.cos(time * 2.2 + s) * 3.0;

      canvas.save();
      canvas.translate(sx, sy);
      canvas.scale(1.60);
      canvas.rotate(math.cos(time * 1.2 + s) * 0.14);
      _drawArticulatedPerson(
        canvas,
        0,
        0,
        coatColor: skaterCoats[s],
        walkPhase: time * 4.5 + s,
      );
      // Silver ice skate blades at feet
      canvas.drawLine(
        const Offset(-6, 5),
        const Offset(6, 5),
        Paint()
          ..color = const Color(0xFFECEFF1)
          ..strokeWidth = 2.0,
      );
      canvas.restore();
    }
  }

  void _drawFjordVesselsAndWhales(
    Canvas canvas,
    Size size,
    double horizonY,
  ) {
    final double groundHeight = size.height - horizonY;

    // 5 Drifting Sculpted Icebergs in the Fjord Channels (-62°..-42° and +38°..+66°)
    final List<Map<String, double>> icebergs = [
      {'deg': -62.0, 'yF': 0.11, 's': 1.55},
      {'deg': -46.0, 'yF': 0.16, 's': 1.68},
      {'deg': 38.0, 'yF': 0.13, 's': 1.62},
      {'deg': 52.0, 'yF': 0.10, 's': 1.52},
      {'deg': 64.0, 'yF': 0.15, 's': 1.60},
    ];

    for (int i = 0; i < icebergs.length; i++) {
      final ib = icebergs[i];
      final double deg = ib['deg']! + math.sin(time * 0.25 + i) * 1.2;
      final double? ix = _worldAngleToScreenX(deg, size);
      if (ix == null) continue;
      final double iy =
          horizonY + groundHeight * ib['yF']! + math.sin(time * 1.4 + i) * 1.8;

      canvas.save();
      canvas.translate(ix, iy);
      canvas.scale(ib['s']!);

      final Path leftIce = Path()
        ..moveTo(-26, 0)
        ..lineTo(-18, -22)
        ..lineTo(-4, -34)
        ..lineTo(2, -16)
        ..lineTo(4, 0)
        ..close();
      final Path rightIce = Path()
        ..moveTo(-4, -34)
        ..lineTo(14, -24)
        ..lineTo(24, 0)
        ..lineTo(4, 0)
        ..lineTo(2, -16)
        ..close();
      canvas.drawPath(leftIce, Paint()..color = const Color(0xFFE0F7FA));
      canvas.drawPath(rightIce, Paint()..color = const Color(0xFF80DEEA));
      canvas.drawLine(
        const Offset(-30, 1),
        const Offset(28, 1),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.75)
          ..strokeWidth = 2.0,
      );
      canvas.restore();
    }

    // Viking Longship with Red/White Striped Sail & Round Shields (+46°)
    final double vikingDeg = 46.0 + math.sin(time * 0.18) * 4.0;
    final double? vx = _worldAngleToScreenX(vikingDeg, size);
    if (vx != null) {
      final double vy =
          horizonY + groundHeight * 0.16 + math.sin(time * 1.6) * 2.0;
      canvas.save();
      canvas.translate(vx, vy);
      canvas.scale(1.75);

      final Path hull = Path()
        ..moveTo(-38, -2)
        ..quadraticBezierTo(-46, -18, -38, -28)
        ..quadraticBezierTo(-33, -24, -32, -8)
        ..lineTo(32, -8)
        ..quadraticBezierTo(36, -20, 40, -24)
        ..quadraticBezierTo(42, -12, 34, -2)
        ..quadraticBezierTo(0, 6, -38, -2)
        ..close();
      canvas.drawPath(hull, Paint()..color = const Color(0xFF4E342E));
      canvas.drawCircle(
        const Offset(-39, -28),
        3.5,
        Paint()..color = const Color(0xFFFFCA28),
      );

      canvas.drawLine(
        const Offset(0, -8),
        const Offset(0, -48),
        Paint()
          ..color = const Color(0xFF3E2723)
          ..strokeWidth = 2.6,
      );
      for (int st = -3; st <= 2; st++) {
        final Path stripe = Path()
          ..moveTo(st * 6.0, -44)
          ..lineTo((st + 1) * 6.0, -44)
          ..quadraticBezierTo(
            (st + 1) * 6.0 + 4,
            -28,
            (st + 1) * 6.0,
            -14,
          )
          ..lineTo(st * 6.0, -14)
          ..quadraticBezierTo(st * 6.0 + 4, -28, st * 6.0, -44)
          ..close();
        canvas.drawPath(
          stripe,
          Paint()
            ..color = st.isEven
                ? const Color(0xFFD32F2F)
                : const Color(0xFFFFF8E1),
        );
      }

      for (int sh = -4; sh <= 4; sh++) {
        final double sx = sh * 6.5;
        canvas.drawLine(
          Offset(sx, -3),
          Offset(sx - 4, 6 + math.sin(time * 3.0 + sh) * 2.0),
          Paint()
            ..color = const Color(0xFFD7CCC8)
            ..strokeWidth = 1.3,
        );
        canvas.drawCircle(
          Offset(sx, -6),
          3.2,
          Paint()
            ..color = sh.isEven
                ? const Color(0xFFFFB300)
                : const Color(0xFFC62828),
        );
      }
      canvas.restore();
    }

    // Breaching Humpback Whale with Water Spout (+58° and -52°)
    for (int w = 0; w < 2; w++) {
      final double whaleDeg = w == 0 ? 58.0 : -52.0;
      final double? wx = _worldAngleToScreenX(whaleDeg, size);
      if (wx == null) continue;
      final double wy = horizonY + groundHeight * 0.18;
      final double breach = math.sin(time * 1.2 + w * 2.1);

      canvas.save();
      canvas.translate(wx, wy);
      canvas.scale(1.75);

      final Path whalePath = Path()
        ..moveTo(-28, 2)
        ..quadraticBezierTo(-4, -18 - breach * 6, 22, 2)
        ..lineTo(30, -10 - breach * 4)
        ..lineTo(38, -14 - breach * 4)
        ..lineTo(28, -2)
        ..close();
      canvas.drawPath(whalePath, Paint()..color = const Color(0xFF1C313A));

      final double spoutH = 24.0 + 10.0 * (0.5 + 0.5 * breach);
      final Paint spoutPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.82)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        const Offset(-6, -12),
        Offset(-12, -12 - spoutH),
        spoutPaint,
      );
      canvas.drawLine(
        const Offset(-6, -12),
        Offset(-6, -14 - spoutH),
        spoutPaint,
      );
      canvas.drawLine(
        const Offset(-6, -12),
        Offset(0, -12 - spoutH),
        spoutPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, 2), width: 64, height: 8),
        Paint()..color = Colors.white.withValues(alpha: 0.70),
      );
      canvas.restore();
    }
  }

  // ===========================================================================
  // 5. SOARING EAGLES & MOUNTAIN HAWKS (16 BIRDS)
  // ===========================================================================

  void _drawEaglesAndHawks(Canvas canvas, Size size, double horizonY) {
    final Paint birdPaint = Paint()
      ..color = atmosphereMode == CoconutAtmosphereMode.night
          ? const Color(0xFFCFD8DC)
          : const Color(0xFF263238)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 16; i++) {
      final double deg = (i * 22.5 + time * (1.4 + (i % 3) * 0.4)) % 360.0;
      final double? bx = _worldAngleToScreenX(deg, size);
      if (bx == null) continue;
      final double by = horizonY * (0.22 + (i % 5) * 0.11) +
          math.sin(time * 2.0 + i) * 8.0;
      final double flap = math.sin(time * (4.5 + (i % 3)) + i * 0.9) * 7.5;
      final double span = 14.0 + (i % 3) * 4.0;

      final Path wing = Path()
        ..moveTo(bx - span, by - flap)
        ..quadraticBezierTo(bx - span * 0.45, by - 5 - flap * 0.4, bx, by)
        ..quadraticBezierTo(
          bx + span * 0.45,
          by - 5 - flap * 0.4,
          bx + span,
          by - flap,
        );
      canvas.drawPath(wing, birdPaint);
    }
  }

  // ===========================================================================
  // 6. 360° BACKGROUND PINE GROVE, FIRE LOOKOUT TOWER & STONE WATCHTOWER
  // ===========================================================================

  void _drawScandinavianPine(
    Canvas canvas,
    double x,
    double y,
    double scale, {
    int seed = 0,
    bool snowHeavy = true,
  }) {
    final double sway = math.sin(time * 1.4 + seed * 0.7) * 3.5;
    canvas.save();
    canvas.translate(x, y);
    canvas.scale(scale);

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 2), width: 38, height: 9),
      Paint()..color = const Color(0xFF455A64).withValues(alpha: 0.30),
    );

    canvas.drawRect(
      const Rect.fromLTWH(-4.5, -24, 9, 26),
      Paint()..color = const Color(0xFF4E342E),
    );

    final bool isNight = atmosphereMode == CoconutAtmosphereMode.night;
    final Color darkPine =
        isNight ? const Color(0xFF0D2E2A) : const Color(0xFF1B4332);
    final Color lightPine =
        isNight ? const Color(0xFF164A41) : const Color(0xFF2D6A4F);

    for (int tier = 0; tier < 4; tier++) {
      final double ty = -20.0 - tier * 17.0;
      final double tw = 32.0 - tier * 5.8;
      final double th = 26.0 - tier * 2.5;
      final double tierSway = sway * (0.25 * (tier + 1));

      final Path foliage = Path()
        ..moveTo(tierSway, ty - th)
        ..quadraticBezierTo(
          tierSway - tw * 0.45,
          ty - th * 0.35,
          tierSway * 0.4 - tw,
          ty,
        )
        ..lineTo(tierSway * 0.4 - tw * 0.4, ty - 3)
        ..lineTo(tierSway * 0.4, ty + 2)
        ..lineTo(tierSway * 0.4 + tw * 0.4, ty - 3)
        ..lineTo(tierSway * 0.4 + tw, ty)
        ..quadraticBezierTo(
          tierSway + tw * 0.45,
          ty - th * 0.35,
          tierSway,
          ty - th,
        )
        ..close();

      canvas.drawPath(
        foliage,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(-tw, ty),
            Offset(tw, ty),
            [lightPine, darkPine],
          ),
      );

      if (snowHeavy) {
        final Path snowCap = Path()
          ..moveTo(tierSway, ty - th)
          ..lineTo(tierSway * 0.6 - tw * 0.68, ty - th * 0.25)
          ..quadraticBezierTo(
            tierSway * 0.5,
            ty - th * 0.08,
            tierSway * 0.6 + tw * 0.68,
            ty - th * 0.25,
          )
          ..close();
        canvas.drawPath(
          snowCap,
          Paint()
            ..color =
                (isNight ? const Color(0xFFD0F8FF) : const Color(0xFFFFFFFF))
                    .withValues(alpha: 0.92),
        );
      }
    }
    canvas.restore();
  }

  void _drawBackgroundPineGroveAndTowers(
    Canvas canvas,
    Size size,
    double horizonY,
  ) {
    final double groundHeight = size.height - horizonY;

    // 28 Background Snow-Laden Scandinavian Pines all around 360° (yFactor: 0.08..0.155 of groundHeight)
    for (int i = 0; i < 28; i++) {
      final double deg = (i * 12.8) % 360.0;
      // Leave a small gap right over the frozen lake center (-14°..+14°)
      if (deg < 14.0 || deg > 346.0) continue;
      final double? px = _worldAngleToScreenX(deg, size);
      if (px == null) continue;
      final double yFactor = 0.08 + (i % 4) * 0.025;
      final double py = horizonY + groundHeight * yFactor;
      final double scale = 1.25 + (i % 3) * 0.14;
      _drawScandinavianPine(canvas, px, py, scale, seed: i);
    }

    // Wooden Fire Lookout Tower at 232° (yFactor: 0.18 of groundHeight)
    final double? lookX = _worldAngleToScreenX(232.0, size);
    if (lookX != null) {
      final double lookY = horizonY + groundHeight * 0.18;
      canvas.save();
      canvas.translate(lookX, lookY);
      canvas.scale(1.75);

      final Paint timber = Paint()
        ..color = const Color(0xFF4E342E)
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(const Offset(-18, 0), const Offset(-10, -58), timber);
      canvas.drawLine(const Offset(18, 0), const Offset(10, -58), timber);
      for (int b = 0; b < 3; b++) {
        final double y1 = -b * 18.0;
        final double y2 = -(b + 1) * 18.0;
        canvas.drawLine(
          Offset(-16 + b * 2, y1),
          Offset(14 - b * 2, y2),
          timber,
        );
        canvas.drawLine(
          Offset(16 - b * 2, y1),
          Offset(-14 + b * 2, y2),
          timber,
        );
      }
      canvas.drawRect(
        const Rect.fromLTWH(-22, -62, 44, 5),
        Paint()..color = const Color(0xFF5D4037),
      );
      canvas.drawRect(
        const Rect.fromLTWH(-15, -82, 30, 20),
        Paint()..color = const Color(0xFF6D4C41),
      );
      canvas.drawRect(
        const Rect.fromLTWH(-11, -78, 22, 10),
        Paint()..color = const Color(0xFFFFD54F),
      );
      final Path roof = Path()
        ..moveTo(-22, -82)
        ..lineTo(0, -98)
        ..lineTo(22, -82)
        ..close();
      canvas.drawPath(roof, Paint()..color = const Color(0xFF1B5E20));
      canvas.drawPath(
        roof,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
      canvas.restore();
    }

    // Stone Nordic Watchtower at 288° (yFactor: 0.18 of groundHeight)
    final double? watchX = _worldAngleToScreenX(288.0, size);
    if (watchX != null) {
      final double watchY = horizonY + groundHeight * 0.18;
      canvas.save();
      canvas.translate(watchX, watchY);
      canvas.scale(1.75);

      final Path tower = Path()
        ..moveTo(-16, 0)
        ..lineTo(-13, -64)
        ..lineTo(13, -64)
        ..lineTo(16, 0)
        ..close();
      canvas.drawPath(tower, Paint()..color = const Color(0xFF546E7A));
      for (int c = -2; c <= 2; c++) {
        canvas.drawRect(
          Rect.fromLTWH(c * 6.0 - 2.0, -70, 4, 6),
          Paint()..color = const Color(0xFF455A64),
        );
      }
      canvas.drawRect(
        const Rect.fromLTWH(-4, -46, 8, 14),
        Paint()..color = const Color(0xFFFFB300),
      );
      final double flicker = math.sin(time * 7.0) * 3.0;
      canvas.drawCircle(
        Offset(0, -75 + flicker * 0.3),
        7.0,
        Paint()
          ..color = const Color(0xFFFF6D00).withValues(alpha: 0.85)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.restore();
    }
  }

  // ===========================================================================
  // 7. NORDIC STRUCTURES: 64° STAVE CHURCH, 78° RORBUER PIER & HOT TUB,
  //    128° ALPINE SKI VILLAGE & SKIERS, 165° LAPLAND EXPEDITION CAMPFIRE
  // ===========================================================================

  void _drawArticulatedPerson(
    Canvas canvas,
    double x,
    double y, {
    required Color coatColor,
    Color pantsColor = const Color(0xFF263238),
    Color hatColor = const Color(0xFFD32F2F),
    double walkPhase = 0.0,
    bool sitting = false,
    bool holdingStick = false,
    bool holdingGuitar = false,
    bool holdingMug = false,
    bool pointing = false,
    bool fishing = false,
  }) {
    canvas.save();
    canvas.translate(x, y);

    final Paint limbPaint = Paint()
      ..color = pantsColor
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    if (sitting) {
      canvas.drawLine(const Offset(0, -10), const Offset(7, -4), limbPaint);
      canvas.drawLine(const Offset(7, -4), const Offset(8, 5), limbPaint);
    } else {
      final double legSwing = math.sin(walkPhase) * 5.0;
      canvas.drawLine(
        const Offset(-2, -10),
        Offset(-3 + legSwing, 4),
        limbPaint,
      );
      canvas.drawLine(
        const Offset(2, -10),
        Offset(3 - legSwing, 4),
        limbPaint,
      );
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-6, -24, 12, 15),
        const Radius.circular(4),
      ),
      Paint()..color = coatColor,
    );
    canvas.drawRect(
      const Rect.fromLTWH(-6.5, -25, 13, 3.5),
      Paint()..color = const Color(0xFFFFF8E1),
    );

    canvas.drawCircle(
      const Offset(0, -30),
      5.0,
      Paint()..color = const Color(0xFFFFCCBC),
    );
    canvas.drawArc(
      const Rect.fromLTWH(-5.5, -36, 11, 9),
      math.pi,
      math.pi,
      true,
      Paint()..color = hatColor,
    );
    canvas.drawCircle(
      const Offset(0, -37),
      2.2,
      Paint()..color = Colors.white,
    );

    final Paint armPaint = Paint()
      ..color = coatColor
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    if (fishing) {
      canvas.drawLine(const Offset(3, -21), const Offset(12, -17), armPaint);
      canvas.drawLine(
        const Offset(11, -17),
        const Offset(26, -28),
        Paint()
          ..color = const Color(0xFF8D6E63)
          ..strokeWidth = 1.8,
      );
      canvas.drawLine(
        const Offset(26, -28),
        Offset(18 + math.sin(time * 2.0) * 1.5, 4),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.75)
          ..strokeWidth = 1.0,
      );
    } else if (pointing) {
      canvas.drawLine(const Offset(-3, -21), const Offset(-14, -27), armPaint);
    } else if (holdingGuitar) {
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(4, -14), width: 14, height: 9),
        Paint()..color = const Color(0xFFD84315),
      );
      canvas.drawLine(
        const Offset(4, -14),
        const Offset(16, -20),
        Paint()
          ..color = const Color(0xFF4E342E)
          ..strokeWidth = 2.2,
      );
    } else if (holdingStick) {
      canvas.drawLine(const Offset(3, -20), const Offset(11, -16), armPaint);
      canvas.drawLine(
        const Offset(11, -16),
        const Offset(24, -10),
        Paint()
          ..color = const Color(0xFF8D6E63)
          ..strokeWidth = 1.6,
      );
      canvas.drawCircle(
        const Offset(24, -10),
        2.6,
        Paint()..color = const Color(0xFFFFF8E1),
      );
    } else if (holdingMug) {
      canvas.drawLine(const Offset(3, -20), const Offset(10, -18), armPaint);
      canvas.drawRect(
        const Rect.fromLTWH(9, -21, 5, 6),
        Paint()..color = const Color(0xFFECEFF1),
      );
    } else {
      final double armSwing = -math.sin(walkPhase) * 4.5;
      canvas.drawLine(
        const Offset(0, -21),
        Offset(armSwing, -12),
        armPaint,
      );
    }

    canvas.restore();
  }

  void _drawNordicStructuresAndCamps(
    Canvas canvas,
    Size size,
    double horizonY,
  ) {
    final double groundHeight = size.height - horizonY;

    // -------------------------------------------------------------------------
    // Norwegian Stave Church (Borgund Stavkirke) at 64° (yFactor: 0.21 of groundHeight)
    // -------------------------------------------------------------------------
    final double? staveX = _worldAngleToScreenX(64.0, size);
    if (staveX != null) {
      final double staveY = horizonY + groundHeight * 0.21;
      canvas.save();
      canvas.translate(staveX, staveY);
      canvas.scale(1.75);

      final Paint darkTimber = Paint()..color = const Color(0xFF3E2723);
      final Paint shingleRoof = Paint()..color = const Color(0xFF271815);
      final Paint snowTrim = Paint()
        ..color = Colors.white
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke;

      // Tier 1 base hall
      canvas.drawRect(const Rect.fromLTWH(-34, -36, 68, 36), darkTimber);
      final Path roof1 = Path()
        ..moveTo(-42, -34)
        ..lineTo(0, -60)
        ..lineTo(42, -34)
        ..close();
      canvas.drawPath(roof1, shingleRoof);
      canvas.drawPath(roof1, snowTrim);

      // Tier 2 middle stave section
      canvas.drawRect(const Rect.fromLTWH(-22, -58, 44, 24), darkTimber);
      final Path roof2 = Path()
        ..moveTo(-28, -56)
        ..lineTo(0, -82)
        ..lineTo(28, -56)
        ..close();
      canvas.drawPath(roof2, shingleRoof);
      canvas.drawPath(roof2, snowTrim);

      // Tier 3 spire turret
      canvas.drawRect(const Rect.fromLTWH(-10, -80, 20, 22), darkTimber);
      final Path spire = Path()
        ..moveTo(-14, -78)
        ..lineTo(0, -108)
        ..lineTo(14, -78)
        ..close();
      canvas.drawPath(spire, shingleRoof);
      canvas.drawPath(spire, snowTrim);

      // Dragon-head gable carvings on roof peaks
      for (final side in [-1.0, 1.0]) {
        canvas.drawLine(
          Offset(side * 24, -56),
          Offset(side * 34, -66),
          Paint()
            ..color = const Color(0xFFFFCA28)
            ..strokeWidth = 2.2,
        );
      }
      // Glowing arched portal
      canvas.drawArc(
        const Rect.fromLTWH(-8, -22, 16, 44),
        math.pi,
        math.pi,
        true,
        Paint()..color = const Color(0xFFFFB300),
      );
      canvas.restore();
    }

    // -------------------------------------------------------------------------
    // 78° ZONE — NORWEGIAN FJORD PIER, RED RORBUER CABIN & STEAMING HOT TUB
    // -------------------------------------------------------------------------
    final double? pierX = _worldAngleToScreenX(78.0, size);
    if (pierX != null) {
      final double pierY = horizonY + groundHeight * 0.19;
      canvas.save();
      canvas.translate(pierX, pierY);
      canvas.scale(1.72);

      final Paint pilingPaint = Paint()..color = const Color(0xFF3E2723);
      for (int p = -5; p <= 5; p++) {
        canvas.drawRect(
          Rect.fromLTWH(p * 18.0 - 3.0, 0, 6, 20),
          pilingPaint,
        );
      }

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-102, -6, 204, 8),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFF6D4C41),
      );

      // Red-painted Norwegian Fisherman Stilt Cabin (Rorbuer) with snow roof
      canvas.drawRect(
        const Rect.fromLTWH(-36, -54, 68, 48),
        Paint()..color = const Color(0xFFB71C1C),
      );
      final Path rorbuRoof = Path()
        ..moveTo(-42, -54)
        ..lineTo(-2, -84)
        ..lineTo(38, -54)
        ..close();
      canvas.drawPath(rorbuRoof, Paint()..color = const Color(0xFF263238));
      final Paint whiteTrim = Paint()
        ..color = Colors.white
        ..strokeWidth = 3.2
        ..style = PaintingStyle.stroke;
      canvas.drawPath(rorbuRoof, whiteTrim);

      for (final wx in [-24.0, 4.0]) {
        canvas.drawRect(
          Rect.fromLTWH(wx, -42, 16, 16),
          Paint()..color = const Color(0xFFFFD54F),
        );
        canvas.drawRect(
          Rect.fromLTWH(wx, -42, 16, 16),
          whiteTrim,
        );
      }

      // Steaming Wooden Outdoor Hot Tub on the Right Deck with 3 People Relaxing!
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(66, -18), width: 44, height: 14),
        Paint()..color = const Color(0xFF4DD0E1),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(44, -18, 44, 14),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xFF8D6E63),
      );
      for (int h = 0; h < 3; h++) {
        final double hx = 54.0 + h * 12.0;
        canvas.drawCircle(
          Offset(hx, -22),
          4.2,
          Paint()..color = const Color(0xFFFFCCBC),
        );
        canvas.drawArc(
          Rect.fromLTWH(hx - 4.5, -27, 9, 7),
          math.pi,
          math.pi,
          true,
          Paint()
            ..color =
                h == 1 ? const Color(0xFFFFB300) : const Color(0xFFE53935),
        );
      }
      for (int st = 0; st < 4; st++) {
        final double p = (time * 0.7 + st * 0.25) % 1.0;
        final double sx = 54.0 + st * 8.0 + math.sin(time * 2.0 + st) * 4.0;
        final double sy = -24.0 - p * 26.0;
        canvas.drawCircle(
          Offset(sx, sy),
          4.0 + p * 5.0,
          Paint()
            ..color = Colors.white.withValues(alpha: (1.0 - p) * 0.65)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }

      _drawArticulatedPerson(
        canvas,
        -88,
        -6,
        coatColor: const Color(0xFFFF8F00),
        pointing: true,
      );
      _drawArticulatedPerson(
        canvas,
        -64,
        -6,
        coatColor: const Color(0xFF1E88E5),
        holdingMug: true,
      );
      canvas.restore();
    }

    // -------------------------------------------------------------------------
    // 128° ZONE — ALPINE SKI VILLAGE: DOWNHILL SKIERS, TIMBER LODGE (118°),
    //             WATERMILL (134°) & A-FRAME CHALET (148°)
    // -------------------------------------------------------------------------

    // 5 Animated Downhill Skiers carving S-turns down the snowy slope (112°..146°)
    for (int sk = 0; sk < 5; sk++) {
      final double progress = (time * 0.28 + sk * 0.2) % 1.0;
      final double skiDeg =
          114.0 + sk * 7.5 + math.sin(time * 2.6 + sk) * 3.5;
      final double? skx = _worldAngleToScreenX(skiDeg, size);
      if (skx != null) {
        final double sky =
            horizonY + groundHeight * (0.10 + progress * 0.14);
        canvas.save();
        canvas.translate(skx, sky);
        canvas.scale(1.55);
        // Parallel skis
        final Paint skiPaint = Paint()
          ..color = const Color(0xFFFF6D00)
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(const Offset(-10, 4), const Offset(10, 6), skiPaint);
        canvas.drawLine(const Offset(-8, 7), const Offset(12, 9), skiPaint);
        // Snow spray puff behind skis
        canvas.drawCircle(
          const Offset(-10, 3),
          5.0,
          Paint()..color = Colors.white.withValues(alpha: 0.85),
        );
        _drawArticulatedPerson(
          canvas,
          0,
          0,
          coatColor: const [
            Color(0xFFD50000),
            Color(0xFF00B0FF),
            Color(0xFF00C853),
            Color(0xFFFFAB00),
            Color(0xFFAA00FF),
          ][sk],
        );
        canvas.restore();
      }
    }

    // Grand Two-Story Alpine Timber Lodge at 118° (yFactor: 0.21 of groundHeight)
    final double? lodgeX = _worldAngleToScreenX(118.0, size);
    if (lodgeX != null) {
      final double lodgeY = horizonY + groundHeight * 0.21;
      canvas.save();
      canvas.translate(lodgeX, lodgeY);
      canvas.scale(1.75);

      canvas.drawRect(
        const Rect.fromLTWH(22, -82, 12, 50),
        Paint()..color = const Color(0xFF607D8B),
      );
      for (int sm = 0; sm < 4; sm++) {
        final double p = (time * 0.5 + sm * 0.25) % 1.0;
        canvas.drawCircle(
          Offset(28 + p * 14, -86 - p * 32),
          5.0 + p * 7.0,
          Paint()
            ..color = Colors.white.withValues(alpha: (1.0 - p) * 0.52)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }

      canvas.drawRect(
        const Rect.fromLTWH(-44, -58, 88, 58),
        Paint()..color = const Color(0xFF5D4037),
      );
      canvas.drawRect(
        const Rect.fromLTWH(-46, -30, 92, 4),
        Paint()..color = const Color(0xFF3E2723),
      );
      final Path roof = Path()
        ..moveTo(-52, -56)
        ..lineTo(0, -90)
        ..lineTo(52, -56)
        ..close();
      canvas.drawPath(roof, Paint()..color = const Color(0xFF3E2723));
      canvas.drawPath(
        roof,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0,
      );

      final Paint winPaint = Paint()..color = const Color(0xFFFFD54F);
      for (final wx in [-32.0, -8.0, 16.0]) {
        canvas.drawRect(Rect.fromLTWH(wx, -48, 14, 12), winPaint);
        canvas.drawRect(Rect.fromLTWH(wx, -20, 14, 12), winPaint);
      }
      canvas.restore();
    }

    // Rustic Watermill House at 134° with Animated Spinning Wooden Waterwheel (yFactor: 0.22)
    final double? millX = _worldAngleToScreenX(134.0, size);
    if (millX != null) {
      final double millY = horizonY + groundHeight * 0.22;
      canvas.save();
      canvas.translate(millX, millY);
      canvas.scale(1.75);

      canvas.drawRect(
        const Rect.fromLTWH(-34, -48, 62, 48),
        Paint()..color = const Color(0xFF6D4C41),
      );
      final Path millRoof = Path()
        ..moveTo(-40, -48)
        ..lineTo(-3, -76)
        ..lineTo(34, -48)
        ..close();
      canvas.drawPath(millRoof, Paint()..color = const Color(0xFF37474F));
      canvas.drawPath(
        millRoof,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5,
      );
      canvas.drawRect(
        const Rect.fromLTWH(-20, -36, 16, 14),
        Paint()..color = const Color(0xFFFFD54F),
      );

      canvas.save();
      canvas.translate(28, -16);
      canvas.rotate(time * 1.6);
      final Paint wheelPaint = Paint()
        ..color = const Color(0xFF4E342E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2;
      canvas.drawCircle(Offset.zero, 20, wheelPaint);
      canvas.drawCircle(Offset.zero, 12, wheelPaint);
      for (int sp = 0; sp < 8; sp++) {
        final double a = sp * (math.pi / 4);
        canvas.drawLine(
          Offset.zero,
          Offset(math.cos(a) * 22, math.sin(a) * 22),
          wheelPaint,
        );
      }
      canvas.restore();
      canvas.restore();
    }

    // Steep-Roofed A-Frame Mountain Chalet at 148° with Huge Glass Facade (yFactor: 0.19)
    final double? chaletX = _worldAngleToScreenX(148.0, size);
    if (chaletX != null) {
      final double chaletY = horizonY + groundHeight * 0.19;
      canvas.save();
      canvas.translate(chaletX, chaletY);
      canvas.scale(1.75);

      final Path aFrame = Path()
        ..moveTo(-38, 0)
        ..lineTo(0, -78)
        ..lineTo(38, 0)
        ..close();
      canvas.drawPath(aFrame, Paint()..color = const Color(0xFF3E2723));

      final Path glass = Path()
        ..moveTo(-26, -4)
        ..lineTo(0, -62)
        ..lineTo(26, -4)
        ..close();
      canvas.drawPath(
        glass,
        Paint()
          ..shader = ui.Gradient.linear(
            const Offset(0, -62),
            const Offset(0, -4),
            [const Color(0xFFFFF59D), const Color(0xFFFFB300)],
          ),
      );
      final Paint mullion = Paint()
        ..color = const Color(0xFF3E2723)
        ..strokeWidth = 2.2;
      canvas.drawLine(const Offset(0, -62), const Offset(0, -4), mullion);
      canvas.drawLine(const Offset(-16, -28), const Offset(16, -28), mullion);
      canvas.restore();
    }

    // -------------------------------------------------------------------------
    // 165° ZONE — LAPLAND EXPEDITION CAMPFIRE, SAMI LAVVU TENTS, DOG SLED & 7 HIKERS
    // -------------------------------------------------------------------------

    for (final tentDeg in [156.0, 176.0]) {
      final double? tx = _worldAngleToScreenX(tentDeg, size);
      if (tx == null) continue;
      final double ty = horizonY + groundHeight * 0.20;
      canvas.save();
      canvas.translate(tx, ty);
      canvas.scale(1.72);

      // Conical Sami Lavvu / Arctic Expedition Tent with protruding wooden poles
      final Path tentBody = Path()
        ..moveTo(-28, 0)
        ..lineTo(0, -42)
        ..lineTo(28, 0)
        ..close();
      canvas.drawPath(
        tentBody,
        Paint()
          ..color = tentDeg < 165.0
              ? const Color(0xFFFFB74D)
              : const Color(0xFF81C784),
      );
      canvas.drawLine(
        const Offset(-6, -48),
        const Offset(4, -36),
        Paint()
          ..color = const Color(0xFF5D4037)
          ..strokeWidth = 2.0,
      );
      canvas.drawLine(
        const Offset(6, -48),
        const Offset(-4, -36),
        Paint()
          ..color = const Color(0xFF5D4037)
          ..strokeWidth = 2.0,
      );
      final Path door = Path()
        ..moveTo(-10, 0)
        ..lineTo(0, -24)
        ..lineTo(10, 0)
        ..close();
      canvas.drawPath(door, Paint()..color = const Color(0xFFFFF176));
      canvas.restore();
    }

    // Center Lapland Campfire at 165° (yFactor: 0.22 of groundHeight)
    final double? campX = _worldAngleToScreenX(165.0, size);
    if (campX != null) {
      final double campY = horizonY + groundHeight * 0.22;
      canvas.save();
      canvas.translate(campX, campY);
      canvas.scale(1.72);

      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, 2), width: 170, height: 52),
        Paint()
          ..shader = ui.Gradient.radial(
            const Offset(0, 2),
            85,
            [
              const Color(0xFFFF9100).withValues(alpha: 0.48),
              const Color(0xFFFF3D00).withValues(alpha: 0.0),
            ],
          ),
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-58, -6, 34, 8),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xFF5D4037),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(24, -6, 34, 8),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xFF5D4037),
      );

      // 7 Articulated Campers around the roaring campfire
      _drawArticulatedPerson(
        canvas,
        -50,
        -4,
        coatColor: const Color(0xFFE53935),
        sitting: true,
        holdingGuitar: true,
      );
      _drawArticulatedPerson(
        canvas,
        -34,
        -4,
        coatColor: const Color(0xFF1E88E5),
        sitting: true,
        holdingStick: true,
      );
      _drawArticulatedPerson(
        canvas,
        -20,
        -8,
        coatColor: const Color(0xFF43A047),
        holdingMug: true,
      );
      _drawArticulatedPerson(
        canvas,
        0,
        -12,
        coatColor: const Color(0xFFFB8C00),
        holdingMug: true,
      );
      _drawArticulatedPerson(
        canvas,
        20,
        -8,
        coatColor: const Color(0xFF8E24AA),
        holdingStick: true,
      );
      _drawArticulatedPerson(
        canvas,
        34,
        -4,
        coatColor: const Color(0xFF00ACC1),
        sitting: true,
        holdingMug: true,
      );
      _drawArticulatedPerson(
        canvas,
        50,
        -4,
        coatColor: const Color(0xFFFDD835),
        sitting: true,
      );

      // Wooden Dog Sled & 2 Huskies resting beside the camp
      canvas.drawLine(
        const Offset(66, 2),
        const Offset(94, 2),
        Paint()
          ..color = const Color(0xFF5D4037)
          ..strokeWidth = 2.5,
      );
      canvas.drawRect(
        const Rect.fromLTWH(68, -6, 20, 6),
        Paint()..color = const Color(0xFF8D6E63),
      );
      for (int h = 0; h < 2; h++) {
        final double hx = 104.0 + h * 18.0;
        canvas.drawOval(
          Rect.fromCenter(center: Offset(hx, -5), width: 14, height: 8),
          Paint()..color = const Color(0xFF607D8B),
        );
        canvas.drawCircle(
          Offset(hx + 6, -9),
          4.0,
          Paint()..color = const Color(0xFFECEFF1),
        );
      }

      // 5-Layer Stone-Ring Campfire in center
      for (int st = -3; st <= 3; st++) {
        canvas.drawCircle(
          Offset(st * 4.2, 4),
          3.2,
          Paint()..color = const Color(0xFF78909C),
        );
      }
      final double flameSway = math.sin(time * 7.5) * 3.0;
      final List<Color> flameCols = [
        const Color(0xFFD50000),
        const Color(0xFFFF3D00),
        const Color(0xFFFF9100),
        const Color(0xFFFFEA00),
        const Color(0xFFFFFFFF),
      ];
      for (int f = 0; f < 5; f++) {
        final double fw = 15.0 - f * 2.5;
        final double fh = 26.0 - f * 4.2;
        final Path flame = Path()
          ..moveTo(-fw, 3)
          ..quadraticBezierTo(flameSway, -fh, fw, 3)
          ..close();
        canvas.drawPath(flame, Paint()..color = flameCols[f]);
      }

      canvas.restore();
    }
  }

  // ===========================================================================
  // 8. 218° ZONE — REINDEER SLEIGH, GRAZING REINDEER HERD, FOXES & PINE GROVE
  // ===========================================================================

  void _drawMidgroundPinesAndWildlife(
    Canvas canvas,
    Size size,
    double horizonY,
  ) {
    final double groundHeight = size.height - horizonY;

    // 18 Midground Snow-Dusted Scandinavian Pines all around 360° (yF strictly 0.18..0.28 of groundHeight!)
    final List<Map<String, double>> midPines = [
      {'deg': -42.0, 'yF': 0.22, 's': 1.65},
      {'deg': -28.0, 'yF': 0.26, 's': 1.72},
      {'deg': 28.0, 'yF': 0.25, 's': 1.70},
      {'deg': 42.0, 'yF': 0.21, 's': 1.62},
      {'deg': 66.0, 'yF': 0.20, 's': 1.58},
      {'deg': 98.0, 'yF': 0.19, 's': 1.65},
      {'deg': 108.0, 'yF': 0.26, 's': 1.72},
      {'deg': 142.0, 'yF': 0.24, 's': 1.58},
      {'deg': 186.0, 'yF': 0.21, 's': 1.68},
      {'deg': 196.0, 'yF': 0.28, 's': 1.75},
      {'deg': 206.0, 'yF': 0.19, 's': 1.60},
      {'deg': 238.0, 'yF': 0.25, 's': 1.72},
      {'deg': 248.0, 'yF': 0.20, 's': 1.62},
      {'deg': 258.0, 'yF': 0.28, 's': 1.75},
      {'deg': 268.0, 'yF': 0.22, 's': 1.64},
      {'deg': 276.0, 'yF': 0.27, 's': 1.70},
      {'deg': 294.0, 'yF': 0.23, 's': 1.60},
      {'deg': -72.0, 'yF': 0.21, 's': 1.55},
    ];

    for (int i = 0; i < midPines.length; i++) {
      final mp = midPines[i];
      final double? px = _worldAngleToScreenX(mp['deg']!, size);
      if (px == null) continue;
      final double py = horizonY + groundHeight * mp['yF']!;
      _drawScandinavianPine(canvas, px, py, mp['s']!, seed: i + 30);
    }

    // Carved Wooden Reindeer Sleigh at 210° (yFactor: 0.26 of groundHeight)
    final double? sleighX = _worldAngleToScreenX(210.0, size);
    if (sleighX != null) {
      final double sleighY = horizonY + groundHeight * 0.26;
      canvas.save();
      canvas.translate(sleighX, sleighY);
      canvas.scale(1.75);
      final Path sleighBody = Path()
        ..moveTo(-22, -4)
        ..lineTo(-18, -18)
        ..lineTo(14, -14)
        ..quadraticBezierTo(26, -16, 24, -4)
        ..close();
      canvas.drawPath(sleighBody, Paint()..color = const Color(0xFFB71C1C));
      canvas.drawLine(
        const Offset(-24, 0),
        const Offset(28, 0),
        Paint()
          ..color = const Color(0xFFFFD54F)
          ..strokeWidth = 2.5,
      );
      canvas.restore();
    }

    // Herd of 6 Animated Reindeer / Stags with Tall Branching Antlers (215°..234°, yFactor: 0.23..0.29)
    for (int r = 0; r < 6; r++) {
      final double rDeg = 215.0 + r * 3.8 + math.sin(time * 0.3 + r) * 1.2;
      final double? rx = _worldAngleToScreenX(rDeg, size);
      if (rx == null) continue;
      final double ry = horizonY + groundHeight * (0.23 + (r % 3) * 0.028);

      canvas.save();
      canvas.translate(rx, ry);
      canvas.scale(1.75);

      final bool grazing = math.sin(time * 0.9 + r * 1.7) > 0.15;
      final double headDrop = grazing ? 10.0 : 0.0;

      final Paint legPaint = Paint()
        ..color = const Color(0xFF4E342E)
        ..strokeWidth = 2.4;
      canvas.drawLine(const Offset(-9, -8), const Offset(-10, 4), legPaint);
      canvas.drawLine(const Offset(-5, -8), const Offset(-4, 4), legPaint);
      canvas.drawLine(const Offset(7, -8), const Offset(6, 4), legPaint);
      canvas.drawLine(const Offset(11, -8), const Offset(12, 4), legPaint);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-12, -18, 24, 11),
          const Radius.circular(5),
        ),
        Paint()..color = const Color(0xFF6D4C41),
      );
      canvas.drawCircle(
        const Offset(13, -15),
        3.0,
        Paint()..color = const Color(0xFFF5F5F5),
      );

      final Offset headPos = Offset(-16, -24 + headDrop);
      canvas.drawLine(
        const Offset(-10, -15),
        headPos,
        Paint()
          ..color = const Color(0xFF6D4C41)
          ..strokeWidth = 4.5
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawOval(
        Rect.fromCenter(center: headPos, width: 9, height: 5.5),
        Paint()..color = const Color(0xFF5D4037),
      );
      final Paint antlerPaint = Paint()
        ..color = const Color(0xFFD7CCC8)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(headPos, headPos.translate(-4, -12), antlerPaint);
      canvas.drawLine(
        headPos.translate(-2, -6),
        headPos.translate(-8, -9),
        antlerPaint,
      );
      canvas.drawLine(
        headPos.translate(-3, -9),
        headPos.translate(2, -13),
        antlerPaint,
      );
      canvas.restore();
    }

    // 3 Arctic Foxes trotting across the snowy ridges (192°, 252°, 282°, yFactor: 0.26..0.29)
    final List<double> foxBases = [192.0, 252.0, 282.0];
    for (int f = 0; f < foxBases.length; f++) {
      final double fDeg = foxBases[f] + math.sin(time * 0.8 + f * 2.0) * 4.5;
      final double? fx = _worldAngleToScreenX(fDeg, size);
      if (fx == null) continue;
      final double fy = horizonY + groundHeight * (0.26 + (f % 2) * 0.03);
      final double hop = math.sin(time * 5.0 + f).abs() * 3.0;

      canvas.save();
      canvas.translate(fx, fy - hop);
      canvas.scale(1.70);
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, -5), width: 14, height: 7),
        Paint()..color = Colors.white,
      );
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(9, -7), width: 10, height: 5),
        Paint()..color = const Color(0xFFECEFF1),
      );
      canvas.drawCircle(
        const Offset(-7, -8),
        3.8,
        Paint()..color = Colors.white,
      );
      canvas.restore();
    }
  }

  void _drawForestPropsAndBoulders(
    Canvas canvas,
    Size size,
    double horizonY,
  ) {
    final double groundHeight = size.height - horizonY;
    final bool isNight = atmosphereMode == CoconutAtmosphereMode.night;

    // 2 Cheerful Nordic Snowmen at 22° and 102° (yFactor: 0.27 of groundHeight)
    for (final snowDeg in [22.0, 102.0]) {
      final double? snowX = _worldAngleToScreenX(snowDeg, size);
      if (snowX == null) continue;
      final double snowY = horizonY + groundHeight * 0.27;
      canvas.save();
      canvas.translate(snowX, snowY);
      canvas.scale(1.72);
      final Paint snowPaint = Paint()..color = Colors.white;
      canvas.drawCircle(const Offset(0, -8), 10, snowPaint);
      canvas.drawCircle(const Offset(0, -21), 7.5, snowPaint);
      canvas.drawCircle(const Offset(0, -31), 5.5, snowPaint);
      canvas.drawRect(
        const Rect.fromLTWH(-6, -26, 12, 3),
        Paint()..color = const Color(0xFFD32F2F),
      );
      final Path nose = Path()
        ..moveTo(0, -31)
        ..lineTo(-8, -30)
        ..lineTo(0, -29)
        ..close();
      canvas.drawPath(nose, Paint()..color = const Color(0xFFFF6D00));
      canvas.drawRect(
        const Rect.fromLTWH(-7, -36, 14, 2),
        Paint()..color = const Color(0xFF263238),
      );
      canvas.drawRect(
        const Rect.fromLTWH(-4.5, -43, 9, 7),
        Paint()..color = const Color(0xFF263238),
      );
      canvas.restore();
    }

    // Wooden Trail Signpost at 198° (yFactor: 0.28 of groundHeight)
    final double? signX = _worldAngleToScreenX(198.0, size);
    if (signX != null) {
      final double signY = horizonY + groundHeight * 0.28;
      canvas.save();
      canvas.translate(signX, signY);
      canvas.scale(1.75);
      canvas.drawRect(
        const Rect.fromLTWH(-2, -28, 4, 28),
        Paint()..color = const Color(0xFF4E342E),
      );
      final Path arrow1 = Path()
        ..moveTo(-14, -24)
        ..lineTo(12, -24)
        ..lineTo(17, -20)
        ..lineTo(12, -16)
        ..lineTo(-14, -16)
        ..close();
      canvas.drawPath(arrow1, Paint()..color = const Color(0xFF8D6E63));
      canvas.restore();
    }

    // Snow-Capped Granite Boulders & Red-Cap Fly Agaric Mushrooms around mid-ring (0.25..0.30 of groundHeight)
    for (int b = 0; b < 14; b++) {
      final double bDeg = 72.0 + b * 16.0;
      final double? bx = _worldAngleToScreenX(bDeg, size);
      if (bx == null) continue;
      final double by = horizonY + groundHeight * (0.25 + (b % 3) * 0.024);

      canvas.save();
      canvas.translate(bx, by);
      canvas.scale(1.65);
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, -4), width: 22, height: 12),
        Paint()..color = const Color(0xFF546E7A),
      );
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(-2, -8), width: 16, height: 6),
        Paint()..color = Colors.white,
      );
      if (b.isEven) {
        canvas.drawRect(
          const Rect.fromLTWH(13, -6, 3, 6),
          Paint()..color = const Color(0xFFFFF8E1),
        );
        canvas.drawArc(
          const Rect.fromLTWH(9, -11, 11, 9),
          math.pi,
          math.pi,
          true,
          Paint()..color = const Color(0xFFD32F2F),
        );
        canvas.drawCircle(
          const Offset(13, -9),
          1.1,
          Paint()..color = Colors.white,
        );
        canvas.drawCircle(
          const Offset(16, -8),
          1.0,
          Paint()..color = Colors.white,
        );
      }
      canvas.restore();
    }

    // 8 Rotating Foreground Snow-Ground Props (fallen pine cones, snowdrifts, animal paw prints, mossy stones)
    // Placed at horizonY + groundHeight * (0.52 .. 0.82), skipping any screen X within 130px of center!
    final List<Map<String, double>> fgProps = [
      {'deg': 38.0, 'yF': 0.56, 'type': 0.0},
      {'deg': 84.0, 'yF': 0.68, 'type': 1.0},
      {'deg': 132.0, 'yF': 0.58, 'type': 2.0},
      {'deg': 174.0, 'yF': 0.74, 'type': 0.0},
      {'deg': 218.0, 'yF': 0.62, 'type': 1.0},
      {'deg': 264.0, 'yF': 0.78, 'type': 2.0},
      {'deg': 308.0, 'yF': 0.54, 'type': 0.0},
      {'deg': 346.0, 'yF': 0.70, 'type': 1.0},
    ];

    for (int p = 0; p < fgProps.length; p++) {
      final prop = fgProps[p];
      final double? px = _worldAngleToScreenX(prop['deg']!, size);
      if (px == null) continue;
      // Never touch or overlap the Center Pine Tree clearing
      if ((px - size.width * 0.5).abs() < 130.0) continue;

      final double py = horizonY + groundHeight * prop['yF']!;
      final int type = prop['type']!.toInt();

      canvas.save();
      canvas.translate(px, py);
      canvas.scale(1.45);
      if (type == 0) {
        // Soft sculpted snowdrift cushion & fallen pine cone
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(0, 2), width: 32, height: 9),
          Paint()
            ..color =
                (isNight ? const Color(0xFF1F445C) : Colors.white)
                    .withValues(alpha: 0.88),
        );
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(-4, -1), width: 9, height: 6),
          Paint()..color = const Color(0xFF4E342E),
        );
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(6, 1), width: 7, height: 5),
          Paint()..color = const Color(0xFF6D4C41),
        );
      } else if (type == 1) {
        // Trail of 3 arctic fox / reindeer paw prints in the snow
        final Paint pawPaint = Paint()
          ..color = (isNight
                  ? const Color(0xFF0A1926)
                  : const Color(0xFF8AB8D6))
              .withValues(alpha: 0.58);
        for (int s = -1; s <= 1; s++) {
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(s * 12.0, s.isEven ? -2.5 : 2.5),
              width: 6.5,
              height: 4.0,
            ),
            pawPaint,
          );
        }
      } else {
        // Small snow-dusted granite stone & red berry sprig
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(0, 0), width: 18, height: 10),
          Paint()..color = const Color(0xFF546E7A),
        );
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(-1, -3), width: 13, height: 5),
          Paint()..color = Colors.white,
        );
        canvas.drawCircle(
          const Offset(9, -2),
          2.2,
          Paint()..color = const Color(0xFFD32F2F),
        );
      }
      canvas.restore();
    }
  }

  // ===========================================================================
  // 9. CENTER FOREGROUND OBJECT — NATURALLY GROUNDED 3D SCANDINAVIAN PINE TREE
  // ===========================================================================

  void _drawCenterPineTree(Canvas canvas, Size size, double horizonY) {
    final double cx = size.width * 0.5;
    final double cy = size.height * 0.855;
    final double sway = math.sin(time * 1.6) * 3.2;
    final bool isNight = atmosphereMode == CoconutAtmosphereMode.night;

    // Proportionate scale so the tree sits grounded at 0.855 and rises prominently in the foreground
    final double pulseScale =
        (1.16 + math.sin(coconutPulse * math.pi) * 0.10) *
            (0.9 + 0.1 * cameraZoom.clamp(0.85, 1.35));

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(pulseScale);

    // 1. Soft Directional Radial Gradient Shadow cast directly onto the continuous snowfield
    final double sunRelativeRad = (-cameraYaw) * math.pi / 180.0;
    final double shadowOffsetX = -math.sin(sunRelativeRad) * 26.0;
    final double shadowOffsetY = 8.0 + math.cos(sunRelativeRad) * 5.0;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(shadowOffsetX, shadowOffsetY),
        width: 176,
        height: 34,
      ),
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(shadowOffsetX, shadowOffsetY),
          88.0,
          [
            (isNight ? const Color(0xFF05101A) : const Color(0xFF75A6C4))
                .withValues(alpha: 0.42),
            (isNight ? const Color(0xFF0A1E2E) : const Color(0xFF9AC5E0))
                .withValues(alpha: 0.16),
            Colors.transparent,
          ],
          const [0.0, 0.60, 1.0],
        ),
    );

    // 2. Thick Textured Timber Trunk starting at (0, 12) and tapering up into the boughs
    final Path trunkPath = Path()
      ..moveTo(-24, 12)
      ..quadraticBezierTo(-14, -4, -11, -58)
      ..lineTo(11, -58)
      ..quadraticBezierTo(14, -4, 24, 12)
      ..close();
    canvas.drawPath(
      trunkPath,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(-18, 0),
          const Offset(18, 0),
          [
            const Color(0xFF795548),
            const Color(0xFF4E342E),
            const Color(0xFF3E2723),
          ],
          const [0.0, 0.55, 1.0],
        ),
    );

    final Paint barkLine = Paint()
      ..color = const Color(0xFF271815).withValues(alpha: 0.55)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    for (int b = -2; b <= 2; b++) {
      canvas.drawLine(
        Offset(b * 3.5, -48),
        Offset(b * 5.2, 8),
        barkLine,
      );
    }

    // 3. Soft Organic Snowdrift Mound (snowNest) tucking the base of the trunk (y = 4..18)
    //    directly into the continuous foreground snow!
    final Path snowNest = Path()
      ..moveTo(-78, 15)
      ..quadraticBezierTo(-34, 0, 0, 5)
      ..quadraticBezierTo(34, 0, 78, 15)
      ..quadraticBezierTo(0, 22, -78, 15)
      ..close();
    canvas.drawPath(
      snowNest,
      Paint()
        ..color = isNight
            ? const Color(0xFF173447)
            : const Color(0xFFD6EEF9),
    );
    // Crisp white snow crest along the top of the root snowdrift
    final Path snowNestCrest = Path()
      ..moveTo(-64, 13)
      ..quadraticBezierTo(-26, 2, 0, 6)
      ..quadraticBezierTo(26, 2, 64, 13);
    canvas.drawPath(
      snowNestCrest,
      Paint()
        ..color = (isNight ? const Color(0xFFB2EBF2) : Colors.white)
            .withValues(alpha: 0.90)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );

    // 2 Small Snow-Dusted Granite Stones & Red-Cap Mushroom nestled in the snow beside the trunk
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-24, 12), width: 14, height: 8),
      Paint()..color = const Color(0xFF546E7A),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-25, 9.5), width: 10, height: 4),
      Paint()..color = Colors.white,
    );
    canvas.drawRect(
      const Rect.fromLTWH(20, 7, 3, 6),
      Paint()..color = const Color(0xFFFFF8E1),
    );
    canvas.drawArc(
      const Rect.fromLTWH(16, 2, 11, 9),
      math.pi,
      math.pi,
      true,
      Paint()..color = const Color(0xFFD32F2F),
    );
    canvas.drawCircle(
      const Offset(20, 4),
      1.0,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      const Offset(23, 5),
      0.9,
      Paint()..color = Colors.white,
    );

    // Cute Animated Squirrel holding an Acorn sitting naturally on the snow at (-38, 10)
    final double sqBob = math.sin(time * 4.2) * 1.4;
    canvas.save();
    canvas.translate(-38, 10 + sqBob);
    final Path sqTail = Path()
      ..moveTo(-6, 1)
      ..quadraticBezierTo(-17, -11, -8, -16)
      ..quadraticBezierTo(-2, -14, -3, 0)
      ..close();
    canvas.drawPath(sqTail, Paint()..color = const Color(0xFFD84315));
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -3), width: 10, height: 11),
      Paint()..color = const Color(0xFFBF360C),
    );
    canvas.drawCircle(
      const Offset(2.5, -10),
      4.0,
      Paint()..color = const Color(0xFFD84315),
    );
    canvas.drawCircle(
      const Offset(6.5, -5.5),
      2.6,
      Paint()..color = const Color(0xFF5D4037),
    );
    canvas.restore();

    // Warm Glowing Brass Expedition Lantern sitting naturally on the snow at (36, 8)
    canvas.drawCircle(
      const Offset(36, 2),
      10.0,
      Paint()
        ..color = const Color(0xFFFFEA00).withValues(alpha: 0.42)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(32, -4, 8, 12),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF4E342E),
    );
    canvas.drawRect(
      const Rect.fromLTWH(33.5, -2, 5, 7),
      Paint()..color = const Color(0xFFFFF59D),
    );

    // 4. 6 Lush Overlapping Tiers of Pine Boughs (-24 up to -140)
    for (int tier = 0; tier < 6; tier++) {
      final double ty = -24.0 - tier * 18.5;
      final double tw = 74.0 - tier * 10.5;
      final double th = 36.0 - tier * 2.5;
      final double tSway = sway * (0.18 * (tier + 1));

      // Deep shadow under-foliage layer for 3D volume
      final Path underLayer = Path()
        ..moveTo(tSway, ty - th + 4)
        ..lineTo(tSway * 0.5 - tw * 1.02, ty + 3)
        ..lineTo(tSway * 0.5, ty + 7)
        ..lineTo(tSway * 0.5 + tw * 1.02, ty + 3)
        ..close();
      canvas.drawPath(
        underLayer,
        Paint()
          ..color = isNight
              ? const Color(0xFF061E19)
              : const Color(0xFF0F291E),
      );

      // Serrated 3D Scandinavian pine needle bough
      final Path needleLayer = Path()
        ..moveTo(tSway, ty - th)
        ..quadraticBezierTo(
          tSway - tw * 0.42,
          ty - th * 0.38,
          tSway * 0.5 - tw,
          ty,
        )
        ..lineTo(tSway * 0.5 - tw * 0.65, ty - 4)
        ..lineTo(tSway * 0.5 - tw * 0.38, ty + 4)
        ..lineTo(tSway * 0.5 - tw * 0.15, ty - 3)
        ..lineTo(tSway * 0.5, ty + 5)
        ..lineTo(tSway * 0.5 + tw * 0.15, ty - 3)
        ..lineTo(tSway * 0.5 + tw * 0.38, ty + 4)
        ..lineTo(tSway * 0.5 + tw * 0.65, ty - 4)
        ..lineTo(tSway * 0.5 + tw, ty)
        ..quadraticBezierTo(
          tSway + tw * 0.42,
          ty - th * 0.38,
          tSway,
          ty - th,
        )
        ..close();

      canvas.drawPath(
        needleLayer,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(-tw, ty - th * 0.5),
            Offset(tw, ty),
            isNight
                ? [
                    const Color(0xFF26856E),
                    const Color(0xFF155747),
                    const Color(0xFF092E25),
                  ]
                : [
                    const Color(0xFF52B788),
                    const Color(0xFF2D6A4F),
                    const Color(0xFF1B4332),
                  ],
            const [0.0, 0.52, 1.0],
          ),
      );

      // Thick White Snow Cushions resting on every pine bough!
      final Path snowCushion = Path()
        ..moveTo(tSway, ty - th)
        ..quadraticBezierTo(
          tSway - tw * 0.38,
          ty - th * 0.46,
          tSway * 0.6 - tw * 0.78,
          ty - th * 0.15,
        )
        ..quadraticBezierTo(
          tSway * 0.6 - tw * 0.35,
          ty - th * 0.04,
          tSway * 0.6,
          ty - th * 0.12,
        )
        ..quadraticBezierTo(
          tSway * 0.6 + tw * 0.35,
          ty - th * 0.04,
          tSway * 0.6 + tw * 0.78,
          ty - th * 0.15,
        )
        ..quadraticBezierTo(
          tSway + tw * 0.38,
          ty - th * 0.46,
          tSway,
          ty - th,
        )
        ..close();
      canvas.drawPath(
        snowCushion,
        Paint()
          ..color = (isNight
                  ? const Color(0xFFD0F8FF)
                  : const Color(0xFFFFFFFF))
              .withValues(alpha: 0.94),
      );

      // 10 Detailed Hanging Pine Cones across tiers 0..4
      if (tier < 5) {
        for (final side in [-1.0, 1.0]) {
          final Offset conePos = Offset(
            tSway * 0.5 + side * tw * 0.48,
            ty + 2.5,
          );
          canvas.drawOval(
            Rect.fromCenter(center: conePos, width: 7, height: 10.5),
            Paint()..color = const Color(0xFF4E342E),
          );
          canvas.drawOval(
            Rect.fromCenter(
              center: conePos.translate(-1.0, -1.5),
              width: 4,
              height: 5.5,
            ),
            Paint()..color = const Color(0xFF8D6E63),
          );
        }
      }
    }

    // 5. Style-Specific Accessories on the Center Pine Tree (reaching up to -155)
    switch (styleMode) {
      case CoconutStyleMode.natural:
        // Perched Red Cardinal Bird on middle branch
        final Offset birdPos = Offset(sway * 0.6 + 32, -78);
        canvas.drawOval(
          Rect.fromCenter(center: birdPos, width: 13, height: 9.5),
          Paint()..color = const Color(0xFFD32F2F),
        );
        final Path crest = Path()
          ..moveTo(birdPos.dx - 3, birdPos.dy - 4)
          ..lineTo(birdPos.dx + 1.5, birdPos.dy - 10)
          ..lineTo(birdPos.dx + 4, birdPos.dy - 3)
          ..close();
        canvas.drawPath(crest, Paint()..color = const Color(0xFFB71C1C));
        canvas.drawCircle(
          birdPos.translate(4, -1.5),
          1.3,
          Paint()..color = Colors.black,
        );
        break;

      case CoconutStyleMode.arcade:
        // Red knitted winter beanie hat on the top peak + cool ski goggles/sunglasses & grin
        final double topX = sway * 1.08;
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(topX, -134),
            width: 38,
            height: 30,
          ),
          math.pi,
          math.pi,
          true,
          Paint()..color = const Color(0xFFD32F2F),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(topX, -134),
              width: 42,
              height: 8.5,
            ),
            const Radius.circular(4),
          ),
          Paint()..color = const Color(0xFFFFF8E1),
        );
        canvas.drawCircle(
          Offset(topX, -152),
          6.5,
          Paint()..color = Colors.white,
        );

        final double midX = sway * 0.65;
        final Paint framePaint = Paint()..color = const Color(0xFF111111);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(midX - 28, -94, 24, 15),
            const Radius.circular(4),
          ),
          framePaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(midX + 4, -94, 24, 15),
            const Radius.circular(4),
          ),
          framePaint,
        );
        canvas.drawLine(
          Offset(midX - 4, -88),
          Offset(midX + 4, -88),
          Paint()
            ..color = const Color(0xFFFFD54F)
            ..strokeWidth = 2.5,
        );
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(midX, -70),
            width: 26,
            height: 14,
          ),
          0.1,
          math.pi - 0.2,
          false,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.8
            ..strokeCap = StrokeCap.round,
        );
        break;

      case CoconutStyleMode.cocktail:
        // Festive Christmas / Yule Tree with 24 glowing fairy lights & star topper at -146
        final double starX = sway * 1.08;
        final Offset starCenter = Offset(starX, -144);
        canvas.drawCircle(
          starCenter,
          20,
          Paint()
            ..color = const Color(0xFFFFEA00).withValues(alpha: 0.48)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
        );
        final Path starPath = Path();
        for (int p = 0; p < 10; p++) {
          final double r = p.isEven ? 13.0 : 5.5;
          final double a = -math.pi / 2 + p * (math.pi / 5);
          final Offset pt = Offset(
            starCenter.dx + math.cos(a) * r,
            starCenter.dy + math.sin(a) * r,
          );
          if (p == 0) {
            starPath.moveTo(pt.dx, pt.dy);
          } else {
            starPath.lineTo(pt.dx, pt.dy);
          }
        }
        starPath.close();
        canvas.drawPath(starPath, Paint()..color = const Color(0xFFFFD600));

        final List<Color> bulbCols = [
          const Color(0xFFFF1744),
          const Color(0xFF00E5FF),
          const Color(0xFFFFEA00),
          const Color(0xFFE040FB),
          const Color(0xFF00E676),
        ];
        for (int b = 0; b < 24; b++) {
          final double tierFrac = b / 24.0;
          final double by = -28.0 - tierFrac * 102.0;
          final double maxW = (1.0 - tierFrac * 0.78) * 58.0;
          final double bx =
              sway * (0.25 + tierFrac * 0.7) + math.sin(b * 2.3) * maxW;
          final Color col = bulbCols[b % bulbCols.length];
          final double pulseGlow =
              0.6 + 0.4 * math.sin(time * 4.5 + b * 0.9);
          canvas.drawCircle(
            Offset(bx, by),
            6.5 * pulseGlow,
            Paint()
              ..color = col.withValues(alpha: 0.45)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
          );
          canvas.drawCircle(
            Offset(bx, by),
            3.8,
            Paint()..color = col,
          );
        }
        break;

      case CoconutStyleMode.king:
        // Ancient Wise Ent with glowing golden crown, amber eyes & perched snowy owl
        final double crownX = sway * 1.08;
        final Path crown = Path()
          ..moveTo(crownX - 18, -136)
          ..lineTo(crownX - 21, -153)
          ..lineTo(crownX - 9, -143)
          ..lineTo(crownX, -156)
          ..lineTo(crownX + 9, -143)
          ..lineTo(crownX + 21, -153)
          ..lineTo(crownX + 18, -136)
          ..close();
        canvas.drawPath(crown, Paint()..color = const Color(0xFFFFD54F));
        canvas.drawCircle(
          Offset(crownX, -143),
          3.0,
          Paint()..color = const Color(0xFF00E5FF),
        );

        final Paint runeGlow = Paint()
          ..color = const Color(0xFFFFAB00)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(-9, -56), width: 10, height: 5),
          runeGlow,
        );
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(9, -56), width: 10, height: 5),
          runeGlow,
        );
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(-9, -56), width: 7, height: 3.2),
          Paint()..color = const Color(0xFFFFF59D),
        );
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(9, -56), width: 7, height: 3.2),
          Paint()..color = const Color(0xFFFFF59D),
        );

        final Offset owlPos = Offset(sway * 0.5 + 38, -72);
        canvas.drawOval(
          Rect.fromCenter(center: owlPos, width: 13, height: 18),
          Paint()..color = Colors.white,
        );
        canvas.drawCircle(
          owlPos.translate(-2.4, -3.5),
          1.7,
          Paint()..color = const Color(0xFFFFB300),
        );
        canvas.drawCircle(
          owlPos.translate(2.4, -3.5),
          1.7,
          Paint()..color = const Color(0xFFFFB300),
        );
        break;

      case CoconutStyleMode.lofi:
        // Cozy striped knitted wool scarf around trunk + studio headphones & floating notes
        final double midX = sway * 0.55;
        final Paint bandPaint = Paint()
          ..color = const Color(0xFF37474F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5.0;
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(midX, -86),
            width: 92,
            height: 66,
          ),
          math.pi,
          math.pi,
          false,
          bandPaint,
        );
        for (final side in [-1.0, 1.0]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(midX + side * 46, -82),
                width: 14,
                height: 24,
              ),
              const Radius.circular(6),
            ),
            Paint()..color = const Color(0xFFD32F2F),
          );
        }

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-17, -20, 34, 11),
            const Radius.circular(4),
          ),
          Paint()..color = const Color(0xFFD32F2F),
        );
        canvas.drawRect(
          const Rect.fromLTWH(-9, -20, 6, 11),
          Paint()..color = const Color(0xFFFFF8E1),
        );
        canvas.drawRect(
          const Rect.fromLTWH(4, -20, 6, 11),
          Paint()..color = const Color(0xFFFFF8E1),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(5, -12, 9, 18),
            const Radius.circular(3),
          ),
          Paint()..color = const Color(0xFFD32F2F),
        );

        for (int n = 0; n < 3; n++) {
          final double np = (time * 0.55 + n * 0.33) % 1.0;
          final Offset notePos = Offset(
            midX + 54 + math.sin(time * 2.5 + n) * 7,
            -84 - np * 44,
          );
          canvas.drawCircle(
            notePos,
            3.6,
            Paint()
              ..color = const Color(0xFF80DEEA)
                  .withValues(alpha: (1.0 - np).clamp(0.0, 1.0)),
          );
        }
        break;
    }

    canvas.restore();
  }

  // ===========================================================================
  // 10. WEATHER & ATMOSPHERIC OVERLAY (GENTLE SNOW IN ALL MODES + BLIZZARD IN RAIN)
  // ===========================================================================

  void _drawAtmosphericOverlay(Canvas canvas, Size size, double horizonY) {
    final double groundHeight = size.height - horizonY;
    final bool isStorm = atmosphereMode == CoconutAtmosphereMode.rain;
    final int flakeCount = isStorm ? 95 : 38;
    final Paint snowFlakePaint = Paint()
      ..color = Colors.white.withValues(alpha: isStorm ? 0.85 : 0.68);
    final Paint sleetPaint = Paint()
      ..color = const Color(0xFFB3E5FC).withValues(alpha: 0.45)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < flakeCount; i++) {
      final double speedX = isStorm ? 45.0 : 14.0;
      final double speedY = isStorm ? 155.0 : 38.0;
      final double px =
          ((i * 73.1 + time * (speedX + (i % 4) * 8.0)) % (size.width + 80)) -
              40;
      final double py =
          (i * 49.7 + time * (speedY + (i % 5) * 14.0)) % size.height;
      if (!isStorm || i.isEven) {
        canvas.drawCircle(
          Offset(px + math.sin(time * 2.2 + i) * 6, py),
          1.8 + (i % 3) * 0.85,
          snowFlakePaint,
        );
      } else {
        canvas.drawLine(
          Offset(px, py),
          Offset(px - 6, py + 18),
          sleetPaint,
        );
      }
    }

    // Glowing Aurora Dust / Ice Crystals in Night & Sunset modes
    if (atmosphereMode == CoconutAtmosphereMode.night ||
        atmosphereMode == CoconutAtmosphereMode.sunset) {
      for (int i = 0; i < 24; i++) {
        final double deg = (i * 15.0 + math.sin(time * 0.4 + i) * 6.0) % 360.0;
        final double? fx = _worldAngleToScreenX(deg, size);
        if (fx == null) continue;
        final double fy = horizonY +
            groundHeight * (0.08 + (i % 6) * 0.04) +
            math.cos(time * 1.6 + i) * 6.0;
        final double glow = 0.35 + 0.65 * math.sin(time * 3.0 + i * 1.3).abs();
        canvas.drawCircle(
          Offset(fx, fy),
          3.2,
          Paint()
            ..color = const Color(0xFF69F0AE).withValues(alpha: 0.58 * glow)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
    }

    // Crisp Alpine Sun Lens Flare in Noon mode
    if (atmosphereMode == CoconutAtmosphereMode.noon) {
      final double? sunX = _worldAngleToScreenX(14.0, size);
      if (sunX != null) {
        final Offset sunPos = Offset(sunX, horizonY - 175.0);
        final Offset center = Offset(size.width * 0.5, size.height * 0.5);
        final Offset dir = center - sunPos;
        for (int f = 1; f <= 4; f++) {
          final Offset flarePos = sunPos + dir * (f * 0.32);
          canvas.drawCircle(
            flarePos,
            12.0 + f * 6.0,
            Paint()..color = const Color(0xFFFFF59D).withValues(alpha: 0.14),
          );
        }
      }
    }

    // Cozy Vignette in Lo-Fi style mode
    if (styleMode == CoconutStyleMode.lofi) {
      final Rect screenRect = Offset.zero & size;
      canvas.drawRect(
        screenRect,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(size.width * 0.5, size.height * 0.5),
            size.longestSide * 0.68,
            [
              Colors.transparent,
              const Color(0xFF1A0E2E).withValues(alpha: 0.42),
            ],
            const [0.55, 1.0],
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant PineForestWorldPainter oldDelegate) {
    if (controller != null && oldDelegate.controller == controller) {
      return false;
    }
    return oldDelegate.controller != controller ||
        oldDelegate.cameraYaw != cameraYaw ||
        oldDelegate.cameraPitch != cameraPitch ||
        oldDelegate.time != time ||
        oldDelegate.isArcadeMode != isArcadeMode ||
        oldDelegate.coconutPulse != coconutPulse ||
        oldDelegate.atmosphereMode != atmosphereMode ||
        oldDelegate.styleMode != styleMode ||
        oldDelegate.cameraZoom != cameraZoom;
  }
}
