// ignore_for_file: prefer_initializing_formals
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../controllers/zenverse_controller.dart';
import 'coconut_world_painter.dart';

class DesertCactusWorldPainter extends CustomPainter {
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

  DesertCactusWorldPainter({
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
    final double horizonY = size.height * (0.48 + (cameraPitch / 90.0) * 0.45);

    // 1. 4-Atmosphere 360° Desert Sky
    _drawSky(canvas, size, horizonY);

    // 2. Milky Way, Stars, Shooting Stars & Twin Moons / Crescent Moon
    _drawStarsAndMoons(canvas, size, horizonY);

    // 3. Blazing Desert Sun & Crepuscular Rays (0°)
    _drawSunAndRays(canvas, size, horizonY);

    // 4. 16 Volumetric United Clouds (PathOperation.union)
    _drawClouds(canvas, size, horizonY);

    // 5. 10 Monumental Red Sandstone Buttes, Mesas & Natural Stone Arches
    _drawMonumentalSandstoneButtes(canvas, size, horizonY);

    // 6. Sculpted Golden Sand Dunes, Ripples & Canyon Ground Base
    _drawDesertDunesAndRipples(canvas, size, horizonY);

    // 7. 24°..48° Zone: High Timber Canyon Trestle Bridge & Wild West Steam Train
    _drawCanyonTrestleAndSteamTrain(canvas, size, horizonY);

    // 8. 16 Colorful Hot Air Balloons with Burner Flame Bursts & 14 Desert Hawks
    _drawHotAirBalloons(canvas, size, horizonY);
    _drawSoaringHawks(canvas, size, horizonY);

    // 9. 74° Zone: Sparkling Turquoise Desert Oasis Lagoon, Waterfall, Flamingos & 6-Camel Caravan
    _drawOasisLagoonAndCamelCaravan(canvas, size, horizonY);

    // 10. 128° Zone: Petra Rose-Red Cliff Temple (110°), Caravanserai (124°), Bazaar (134°) & Pottery (148°)
    _drawCaravanseraiAndBazaar(canvas, size, horizonY);

    // 11. 220° Zone: Stepped Desert Pyramid & Obelisks (214°), Western Windmill (232°) & Observatory (250°)
    _drawRuinsAndObservatory(canvas, size, horizonY);

    // 12. 165° Zone: Bedouin Oasis Campfire, Woven Tent Pavilion, Musicians, Stargazers & Fennec Fox
    _drawBedouinCampfireScene(canvas, size, horizonY);

    // 13. 28 Large Saguaro, Prickly Pear & Agave Cacti, Red Rocks, Tumbleweeds, Lizards & Skulls
    _drawCactusForestAndDesertProps(canvas, size, horizonY);

    // 14. Center Foreground Hero: The Saguaro Cactus (_drawCenterCactus)
    _drawCenterCactus(canvas, size, horizonY);

    // 15. Weather & Atmospheric Overlays (Monsoon Rain, Desert Sparkles, Stardust, Heat Shimmer, Vignette)
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
          const Color(0xFF1A0D2A),
          const Color(0xFF3A153B),
          sunProximity,
        )!;
        upperMidColor = Color.lerp(
          const Color(0xFF431C4A),
          const Color(0xFF9C2738),
          sunProximity,
        )!;
        midColor = Color.lerp(
          const Color(0xFF7D2E46),
          const Color(0xFFE65124),
          sunProximity,
        )!;
        horizonColor = Color.lerp(
          const Color(0xFFC46345),
          const Color(0xFFFFC145),
          sunProximity,
        )!;
        break;
      case CoconutAtmosphereMode.night:
        topColor = const Color(0xFF040611);
        upperMidColor = const Color(0xFF0A1026);
        midColor = const Color(0xFF141E3C);
        horizonColor = Color.lerp(
          const Color(0xFF1D2C4F),
          const Color(0xFF283C66),
          sunProximity,
        )!;
        break;
      case CoconutAtmosphereMode.noon:
        topColor = const Color(0xFF0D5C9E);
        upperMidColor = const Color(0xFF2185C5);
        midColor = const Color(0xFF63B4D1);
        horizonColor = Color.lerp(
          const Color(0xFFD6EADF),
          const Color(0xFFFFE5A3),
          sunProximity,
        )!;
        break;
      case CoconutAtmosphereMode.rain:
        topColor = const Color(0xFF1C2331);
        upperMidColor = const Color(0xFF2E3846);
        midColor = const Color(0xFF4A5568);
        horizonColor = Color.lerp(
          const Color(0xFF6E6A7C),
          const Color(0xFF9E7B66),
          sunProximity,
        )!;
        break;
    }

    final Paint skyPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, horizonY + 30),
        [topColor, upperMidColor, midColor, horizonColor],
        [0.0, 0.34, 0.70, 1.0],
      );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, horizonY + 32),
      skyPaint,
    );

    // Distant monsoon lightning flash in rain mode
    if (atmosphereMode == CoconutAtmosphereMode.rain) {
      final double flashCycle = (time * 0.45) % 4.0;
      if (flashCycle < 0.18) {
        final double flashX =
            _worldAngleToScreenX(295.0, size, margin: 500) ?? size.width * 0.3;
        final Path bolt = Path()
          ..moveTo(flashX, horizonY * 0.12)
          ..lineTo(flashX - 16, horizonY * 0.36)
          ..lineTo(flashX + 8, horizonY * 0.42)
          ..lineTo(flashX - 22, horizonY * 0.78);
        canvas.drawPath(
          bolt,
          Paint()
            ..color = const Color(0xFFE0F7FA).withValues(alpha: 0.85)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.6,
        );
      }
    }
  }

  void _drawStarsAndMoons(Canvas canvas, Size size, double horizonY) {
    final double starOpacity = atmosphereMode == CoconutAtmosphereMode.night
        ? 0.95
        : (atmosphereMode == CoconutAtmosphereMode.sunset ? 0.38 : 0.0);
    if (starOpacity <= 0.01) return;

    // Milky Way diagonal glowing band in night mode
    if (atmosphereMode == CoconutAtmosphereMode.night) {
      final double mwX =
          _worldAngleToScreenX(210.0, size, margin: 800) ?? size.width * 0.5;
      canvas.save();
      canvas.translate(mwX, horizonY * 0.42);
      canvas.rotate(-0.38);
      final Paint mwPaint = Paint()
        ..shader = ui.Gradient.radial(
          Offset.zero,
          size.width * 0.55,
          [
            const Color(0xFF9575CD).withValues(alpha: 0.24),
            const Color(0xFF4DD0E1).withValues(alpha: 0.12),
            Colors.transparent,
          ],
          [0.0, 0.5, 1.0],
        );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: size.width * 1.1,
          height: horizonY * 0.36,
        ),
        mwPaint,
      );
      canvas.restore();
    }

    // Twinkling stars across 360°
    for (int i = 0; i < 85; i++) {
      final double deg = (i * 41.3) % 360.0;
      final double? sx = _worldAngleToScreenX(deg, size, margin: 40);
      if (sx == null) continue;
      final double sy = ((i * 67.7) % 100.0) / 100.0 * (horizonY * 0.82);
      final double twinkle =
          0.45 + 0.55 * math.sin(time * (1.8 + (i % 5) * 0.4) + i);
      final double r = (i % 7 == 0) ? 2.1 : 1.2;
      canvas.drawCircle(
        Offset(sx, sy),
        r,
        Paint()
          ..color = const Color(0xFFFFF8E1)
              .withValues(alpha: (starOpacity * twinkle).clamp(0.0, 1.0)),
      );
    }

    // Shooting star in night mode
    if (atmosphereMode == CoconutAtmosphereMode.night) {
      final double shootPhase = (time * 0.35) % 3.0;
      if (shootPhase < 0.65) {
        final double p = shootPhase / 0.65;
        final double? baseSx = _worldAngleToScreenX(190.0, size, margin: 600);
        if (baseSx != null) {
          final Offset head = Offset(
            baseSx + p * 180.0,
            horizonY * 0.16 + p * 75.0,
          );
          final Offset tail = Offset(head.dx - 55.0, head.dy - 22.0);
          canvas.drawLine(
            tail,
            head,
            Paint()
              ..shader = ui.Gradient.linear(tail, head, [
                Colors.transparent,
                const Color(0xFFFFF59D).withValues(alpha: 0.9),
              ])
              ..strokeWidth = 2.2
              ..strokeCap = StrokeCap.round,
          );
        }
      }
    }

    // Twin Desert Moons / Glowing Crescent Moon around 200°..222°
    final double? moonX = _worldAngleToScreenX(212.0, size, margin: 240);
    if (moonX != null) {
      final double moonY = horizonY * 0.24;
      canvas.drawCircle(
        Offset(moonX, moonY),
        62,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(moonX, moonY),
            62,
            [
              const Color(0xFFFFF59D).withValues(alpha: 0.28 * starOpacity),
              Colors.transparent,
            ],
          ),
      );
      final Path crescent = Path.combine(
        PathOperation.difference,
        Path()..addOval(Rect.fromCircle(center: Offset(moonX, moonY), radius: 26)),
        Path()
          ..addOval(
            Rect.fromCircle(center: Offset(moonX + 10, moonY - 6), radius: 22),
          ),
      );
      canvas.drawPath(
        crescent,
        Paint()
          ..color = const Color(0xFFFFFDE7).withValues(alpha: starOpacity),
      );

      // Companion small amber desert moon
      final Offset moon2 = Offset(moonX - 54, moonY + 26);
      canvas.drawCircle(
        moon2,
        9.5,
        Paint()
          ..color = const Color(0xFFFFCC80)
              .withValues(alpha: (starOpacity * 0.85).clamp(0.0, 1.0)),
      );
    }
  }

  void _drawSunAndRays(Canvas canvas, Size size, double horizonY) {
    if (atmosphereMode == CoconutAtmosphereMode.night) return;
    final double? sunX = _worldAngleToScreenX(0.0, size, margin: 360);
    if (sunX == null) return;

    final bool isNoon = atmosphereMode == CoconutAtmosphereMode.noon;
    final double sunY = isNoon ? horizonY * 0.28 : horizonY * 0.66;
    final double sunRadius = isNoon ? 44.0 : 66.0;

    // Outer desert sun halo
    canvas.drawCircle(
      Offset(sunX, sunY),
      sunRadius * 3.2,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(sunX, sunY),
          sunRadius * 3.2,
          [
            const Color(0xFFFF8F00).withValues(alpha: 0.36),
            const Color(0xFFE65100).withValues(alpha: 0.12),
            Colors.transparent,
          ],
          [0.0, 0.5, 1.0],
        ),
    );

    // Crepuscular god rays fanning out from the sun
    for (int i = 0; i < 9; i++) {
      final double angle = -math.pi * 0.88 + (i / 8.0) * math.pi * 0.76;
      final double rayLen = size.height * 0.55;
      final Path ray = Path()
        ..moveTo(sunX, sunY)
        ..lineTo(
          sunX + math.cos(angle - 0.045) * rayLen,
          sunY + math.sin(angle - 0.045) * rayLen,
        )
        ..lineTo(
          sunX + math.cos(angle + 0.045) * rayLen,
          sunY + math.sin(angle + 0.045) * rayLen,
        )
        ..close();
      canvas.drawPath(
        ray,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(sunX, sunY),
            rayLen,
            [
              const Color(0xFFFFE082).withValues(alpha: 0.14),
              Colors.transparent,
            ],
          ),
      );
    }

    // Main blazing desert sun disc
    canvas.drawCircle(
      Offset(sunX, sunY),
      sunRadius,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(sunX, sunY - sunRadius),
          Offset(sunX, sunY + sunRadius),
          [
            const Color(0xFFFFFDE7),
            const Color(0xFFFFCA28),
            const Color(0xFFFF6F00),
          ],
          [0.0, 0.55, 1.0],
        ),
    );
  }

  void _drawClouds(Canvas canvas, Size size, double horizonY) {
    for (int i = 0; i < 16; i++) {
      final double baseDeg =
          (i * 22.5 + time * (0.32 + (i % 3) * 0.11)) % 360.0;
      final double? cx = _worldAngleToScreenX(baseDeg, size, margin: 280);
      if (cx == null) continue;

      final double cy = horizonY * (0.14 + (i % 5) * 0.11);
      final double scale = 0.85 + (i % 4) * 0.25;

      // Unite all cloud puffs with PathOperation.union so there are no internal wireframe lines
      Path cloudPath = Path()
        ..addOval(
          Rect.fromCenter(
            center: Offset(cx, cy),
            width: 96 * scale,
            height: 34 * scale,
          ),
        );
      final List<List<double>> puffs = [
        [-28.0, -8.0, 52.0, 32.0],
        [6.0, -13.0, 62.0, 38.0],
        [34.0, -5.0, 48.0, 28.0],
        [-46.0, 3.0, 42.0, 24.0],
        [48.0, 4.0, 40.0, 22.0],
      ];
      for (final List<double> p in puffs) {
        final Path puff = Path()
          ..addOval(
            Rect.fromCenter(
              center: Offset(cx + p[0] * scale, cy + p[1] * scale),
              width: p[2] * scale,
              height: p[3] * scale,
            ),
          );
        cloudPath = Path.combine(PathOperation.union, cloudPath, puff);
      }

      Color topC;
      Color botC;
      Color rimC;
      switch (atmosphereMode) {
        case CoconutAtmosphereMode.sunset:
          topC = const Color(0xFFFFCC80).withValues(alpha: 0.82);
          botC = const Color(0xFFD84315).withValues(alpha: 0.68);
          rimC = const Color(0xFFFFECB3).withValues(alpha: 0.72);
          break;
        case CoconutAtmosphereMode.night:
          topC = const Color(0xFF283593).withValues(alpha: 0.48);
          botC = const Color(0xFF1A237E).withValues(alpha: 0.38);
          rimC = const Color(0xFF7986CB).withValues(alpha: 0.35);
          break;
        case CoconutAtmosphereMode.noon:
          topC = const Color(0xFFFFFFFF).withValues(alpha: 0.88);
          botC = const Color(0xFFFFE0B2).withValues(alpha: 0.70);
          rimC = const Color(0xFFFFFDE7).withValues(alpha: 0.85);
          break;
        case CoconutAtmosphereMode.rain:
          topC = const Color(0xFF78909C).withValues(alpha: 0.82);
          botC = const Color(0xFF37474F).withValues(alpha: 0.88);
          rimC = const Color(0xFFB0BEC5).withValues(alpha: 0.45);
          break;
      }

      canvas.drawPath(
        cloudPath,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(cx, cy - 26 * scale),
            Offset(cx, cy + 18 * scale),
            [topC, botC],
          ),
      );
      canvas.drawPath(
        cloudPath,
        Paint()
          ..color = rimC
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }
  }

  void _drawMonumentalSandstoneButtes(
    Canvas canvas,
    Size size,
    double horizonY,
  ) {
    // 10 Towering Red Sandstone Buttes, Mesas & Natural Stone Arches (175px..265px tall)
    final List<Map<String, double>> buttes = [
      {'deg': 16.0, 'w': 260.0, 'h': 230.0, 'arch': 1.0},
      {'deg': 54.0, 'w': 235.0, 'h': 195.0, 'arch': 0.0},
      {'deg': 88.0, 'w': 245.0, 'h': 205.0, 'arch': 1.0},
      {'deg': 118.0, 'w': 270.0, 'h': 225.0, 'arch': 0.0},
      {'deg': 152.0, 'w': 225.0, 'h': 180.0, 'arch': 1.0},
      {'deg': 188.0, 'w': 285.0, 'h': 255.0, 'arch': 0.0},
      {'deg': 224.0, 'w': 245.0, 'h': 200.0, 'arch': 0.0},
      {'deg': 264.0, 'w': 255.0, 'h': 215.0, 'arch': 1.0},
      {'deg': 298.0, 'w': 275.0, 'h': 245.0, 'arch': 0.0},
      {'deg': 336.0, 'w': 250.0, 'h': 210.0, 'arch': 1.0},
    ];

    final bool isNight = atmosphereMode == CoconutAtmosphereMode.night;

    for (int i = 0; i < buttes.length; i++) {
      final Map<String, double> b = buttes[i];
      final double? bx = _worldAngleToScreenX(b['deg']!, size, margin: 380);
      if (bx == null) continue;

      final double bw = b['w']!;
      final double bh = b['h']!;
      final double baseY = horizonY + 14.0;

      Path mesa = Path()
        ..moveTo(bx - bw * 0.55, baseY)
        ..lineTo(bx - bw * 0.42, baseY - bh * 0.36)
        ..lineTo(bx - bw * 0.28, baseY - bh * 0.88)
        ..lineTo(bx - bw * 0.18, baseY - bh)
        ..lineTo(bx + bw * 0.16, baseY - bh * 0.97)
        ..lineTo(bx + bw * 0.27, baseY - bh * 0.82)
        ..lineTo(bx + bw * 0.38, baseY - bh * 0.35)
        ..lineTo(bx + bw * 0.55, baseY)
        ..close();

      // Carve a natural sandstone arch in selected mesas
      if (b['arch'] == 1.0) {
        final Path archHole = Path()
          ..moveTo(bx - bw * 0.14, baseY)
          ..quadraticBezierTo(
            bx,
            baseY - bh * 0.55,
            bx + bw * 0.14,
            baseY,
          )
          ..close();
        mesa = Path.combine(PathOperation.difference, mesa, archHole);
      }

      final Color litColor = isNight
          ? const Color(0xFF3E273B)
          : const Color(0xFFD85A32);
      final Color shadowColor = isNight
          ? const Color(0xFF1F1629)
          : const Color(0xFF7B2B22);

      canvas.drawPath(
        mesa,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(bx - bw * 0.4, baseY - bh),
            Offset(bx + bw * 0.4, baseY),
            [litColor, shadowColor],
          ),
      );

      // Horizontal sedimentary strata stripes clipped inside the mesa
      canvas.save();
      canvas.clipPath(mesa);
      for (int s = 1; s <= 6; s++) {
        final double sy = baseY - (bh * s / 7.0);
        canvas.drawLine(
          Offset(bx - bw * 0.55, sy),
          Offset(bx + bw * 0.55, sy + (s.isEven ? 6 : -4)),
          Paint()
            ..color = (s.isEven
                    ? const Color(0xFFFFAB91)
                    : const Color(0xFF4E1A14))
                .withValues(alpha: isNight ? 0.20 : 0.38)
            ..strokeWidth = 3.2,
        );
      }
      canvas.restore();

      // Sunlit golden sandstone rim highlight
      canvas.drawPath(
        mesa,
        Paint()
          ..color = const Color(0xFFFFCC80)
              .withValues(alpha: isNight ? 0.18 : 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    }
  }

  void _drawDesertDunesAndRipples(
    Canvas canvas,
    Size size,
    double horizonY,
  ) {
    final bool isNight = atmosphereMode == CoconutAtmosphereMode.night;
    final Color topSand = isNight
        ? const Color(0xFF2C223E)
        : (atmosphereMode == CoconutAtmosphereMode.noon
            ? const Color(0xFFF5C36C)
            : const Color(0xFFE07A3C));
    final Color midSand = isNight
        ? const Color(0xFF211A30)
        : (atmosphereMode == CoconutAtmosphereMode.noon
            ? const Color(0xFFE5A44B)
            : const Color(0xFFC45B2C));
    final Color bottomSand = isNight
        ? const Color(0xFF151022)
        : const Color(0xFF8D3B1E);

    // Base desert floor fill
    canvas.drawRect(
      Rect.fromLTWH(0, horizonY, size.width, size.height - horizonY),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, horizonY),
          Offset(0, size.height),
          [topSand, midSand, bottomSand],
          [0.0, 0.48, 1.0],
        ),
    );

    // 4 Sweeping Layered Golden Sand Dune Ridges across the 360° panorama
    final double yawShift = (cameraYaw / 360.0) * math.pi * 4.0;
    for (int layer = 0; layer < 4; layer++) {
      final double layerY =
          horizonY + (size.height - horizonY) * (0.08 + layer * 0.14);
      final Path dune = Path()..moveTo(0, size.height);
      dune.lineTo(0, layerY);
      for (double x = 0; x <= size.width + 20; x += 24) {
        final double wave = math.sin(x * 0.008 + yawShift + layer * 1.4) *
                (18.0 + layer * 6.0) +
            math.cos(x * 0.004 - yawShift * 0.5 + layer) * 10.0;
        dune.lineTo(x, layerY + wave);
      }
      dune.lineTo(size.width, size.height);
      dune.close();

      final Color duneLit = Color.lerp(
        topSand,
        const Color(0xFFFFCC80),
        isNight ? 0.05 : (0.22 - layer * 0.04),
      )!;
      final Color duneShade = Color.lerp(
        midSand,
        bottomSand,
        (layer + 1) * 0.22,
      )!;

      canvas.drawPath(
        dune,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, layerY - 25),
            Offset(0, layerY + 120),
            [duneLit, duneShade],
          ),
      );
    }

    // Wind-blown sand ripples across midground
    final Paint ripplePaint = Paint()
      ..color = const Color(0xFFFFE0B2)
          .withValues(alpha: isNight ? 0.08 : 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    for (int r = 0; r < 22; r++) {
      final double deg = (r * 16.3) % 360.0;
      final double? rx = _worldAngleToScreenX(deg, size, margin: 160);
      if (rx == null) continue;
      final double ry =
          horizonY + (size.height - horizonY) * (0.22 + (r % 6) * 0.11);
      final Path rp = Path()
        ..moveTo(rx - 48, ry)
        ..quadraticBezierTo(rx, ry - 6, rx + 48, ry + 2);
      canvas.drawPath(rp, ripplePaint);
    }
  }

  void _drawCanyonTrestleAndSteamTrain(
    Canvas canvas,
    Size size,
    double horizonY,
  ) {
    // Spanning a canyon gorge at 24°..48° (centered at 36°, yFactor: 0.18, 1.85x scale)
    final double? bridgeX = _worldAngleToScreenX(36.0, size, margin: 480);
    if (bridgeX == null) return;

    final double groundHeight = size.height - horizonY;
    final double baseY = horizonY + groundHeight * 0.14;
    final bool isNight = atmosphereMode == CoconutAtmosphereMode.night;

    canvas.save();
    canvas.translate(bridgeX, baseY);
    canvas.scale(1.72);

    // Deep red-rock canyon gorge beneath the trestle bridge
    final Path gorge = Path()
      ..moveTo(-135, -30)
      ..lineTo(-105, -28)
      ..lineTo(-82, 18)
      ..lineTo(82, 18)
      ..lineTo(105, -28)
      ..lineTo(135, -30)
      ..lineTo(135, 22)
      ..lineTo(-135, 22)
      ..close();
    canvas.drawPath(
      gorge,
      Paint()
        ..color = isNight
            ? const Color(0xFF1A1023)
            : const Color(0xFF5D1F16),
    );

    // Canyon abutment cliffs on left & right
    final Paint cliffPaint = Paint()
      ..color = isNight
          ? const Color(0xFF382236)
          : const Color(0xFFB84326);
    canvas.drawRect(const Rect.fromLTWH(-135, -30, 34, 48), cliffPaint);
    canvas.drawRect(const Rect.fromLTWH(101, -30, 34, 48), cliffPaint);

    // High Timber Trestle Bridge deck & lattice bents
    final Paint timberPaint = Paint()
      ..color = const Color(0xFF4E342E)
      ..strokeWidth = 2.2;
    final Paint crossBracePaint = Paint()
      ..color = const Color(0xFF6D4C41)
      ..strokeWidth = 1.2;

    for (int b = -4; b <= 4; b++) {
      final double bx = b * 22.0;
      // Vertical / battered trestle legs
      canvas.drawLine(Offset(bx - 3, -28), Offset(bx - 6, 18), timberPaint);
      canvas.drawLine(Offset(bx + 3, -28), Offset(bx + 6, 18), timberPaint);
      // Horizontal & X-bracing
      canvas.drawLine(
        Offset(bx - 5, -12),
        Offset(bx + 5, -12),
        crossBracePaint,
      );
      canvas.drawLine(
        Offset(bx - 6, 3),
        Offset(bx + 6, 3),
        crossBracePaint,
      );
      if (b < 4) {
        canvas.drawLine(
          Offset(bx + 3, -28),
          Offset(bx + 19, -12),
          crossBracePaint,
        );
        canvas.drawLine(
          Offset(bx + 19, -28),
          Offset(bx + 3, -12),
          crossBracePaint,
        );
      }
    }

    // Steel rail deck & crossties
    canvas.drawRect(
      const Rect.fromLTWH(-125, -31, 250, 4.0),
      Paint()..color = const Color(0xFF3E2723),
    );
    canvas.drawLine(
      const Offset(-125, -31.5),
      const Offset(125, -31.5),
      Paint()
        ..color = const Color(0xFFB0BEC5)
        ..strokeWidth = 1.2,
    );

    // Animated Wild West Steam Locomotive + Coal Tender + 2 Red Passenger Cars
    final double trainProgress = (time * 0.14) % 1.0;
    final double trainX = 110.0 - trainProgress * 220.0; // Chugging right-to-left

    canvas.save();
    canvas.clipRect(const Rect.fromLTWH(-132, -95, 264, 75));

    // Locomotive boiler, cowcatcher, cab & brass smokestack
    final double locoX = trainX;
    // Cowcatcher on front (left)
    final Path cowcatcher = Path()
      ..moveTo(locoX - 18, -31)
      ..lineTo(locoX - 12, -31)
      ..lineTo(locoX - 12, -36)
      ..close();
    canvas.drawPath(cowcatcher, Paint()..color = const Color(0xFFB71C1C));

    // Warm headlight beam in sunset/night
    final Path beam = Path()
      ..moveTo(locoX - 14, -40)
      ..lineTo(locoX - 54, -48)
      ..lineTo(locoX - 54, -31)
      ..close();
    canvas.drawPath(
      beam,
      Paint()
        ..color = const Color(0xFFFFF59D)
            .withValues(alpha: isNight ? 0.45 : 0.22),
    );

    // Black cylindrical boiler & cab
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(locoX - 13, -43, 22, 10),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF212121),
    );
    canvas.drawRect(
      Rect.fromLTWH(locoX + 4, -48, 10, 15),
      Paint()..color = const Color(0xFF8D1D1D),
    );
    // Brass dome & funnel smokestack
    canvas.drawCircle(
      Offset(locoX - 2, -44),
      2.8,
      Paint()..color = const Color(0xFFFFCA28),
    );
    final Path stack = Path()
      ..moveTo(locoX - 11, -43)
      ..lineTo(locoX - 13, -52)
      ..lineTo(locoX - 7, -52)
      ..lineTo(locoX - 9, -43)
      ..close();
    canvas.drawPath(stack, Paint()..color = const Color(0xFF37474F));

    // Coal tender + 2 Red Wild West Passenger Coaches with lit windows
    canvas.drawRect(
      Rect.fromLTWH(locoX + 16, -42, 14, 9),
      Paint()..color = const Color(0xFF263238),
    );
    for (int car = 0; car < 2; car++) {
      final double cx = locoX + 33.0 + car * 29.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx, -45, 25, 12),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFFB71C1C),
      );
      canvas.drawRect(
        Rect.fromLTWH(cx - 1, -46.5, 27, 2.2),
        Paint()..color = const Color(0xFFFFB300),
      );
      for (int w = 0; w < 4; w++) {
        canvas.drawRect(
          Rect.fromLTWH(cx + 2.5 + w * 5.5, -42.5, 3.8, 4.5),
          Paint()..color = const Color(0xFFFFF59D),
        );
      }
    }

    // Red driving wheels along train
    for (int wh = 0; wh < 10; wh++) {
      canvas.drawCircle(
        Offset(locoX - 10.0 + wh * 9.5, -32.2),
        2.4,
        Paint()..color = const Color(0xFFD32F2F),
      );
    }

    // Billowing white steam & smoke puffs trailing from the smokestack
    for (int p = 0; p < 7; p++) {
      final double age = ((time * 1.8 + p * 0.35) % 2.4) / 2.4;
      final double sx = locoX - 10.0 + age * 46.0;
      final double sy = -54.0 - age * 26.0 + math.sin(time * 3.0 + p) * 2.5;
      final double sr = 4.0 + age * 8.5;
      canvas.drawCircle(
        Offset(sx, sy),
        sr,
        Paint()
          ..color = const Color(0xFFFFF8E1)
              .withValues(alpha: (1.0 - age) * 0.72),
      );
    }

    canvas.restore();
    canvas.restore();
  }

  void _drawHotAirBalloons(Canvas canvas, Size size, double horizonY) {
    // 16 Colorful Hot Air Balloons (0.95x..1.90x scale) drifting at different altitudes
    final List<List<Color>> palettes = [
      [const Color(0xFFE53935), const Color(0xFFFFB300), const Color(0xFF1E88E5)],
      [const Color(0xFF8E24AA), const Color(0xFFFF7043), const Color(0xFFFFCA28)],
      [const Color(0xFF00897B), const Color(0xFFFFD54F), const Color(0xFFD81B60)],
      [const Color(0xFF3949AB), const Color(0xFF26C6DA), const Color(0xFFFFA726)],
      [const Color(0xFFC2185B), const Color(0xFFFFEE58), const Color(0xFF00ACC1)],
    ];

    for (int i = 0; i < 16; i++) {
      final double baseDeg = (i * 22.5 + time * (0.42 + (i % 3) * 0.14)) % 360.0;
      final double? bx = _worldAngleToScreenX(baseDeg, size, margin: 220);
      if (bx == null) continue;

      final double bob = math.sin(time * 1.4 + i * 0.9) * 8.0;
      final double by = horizonY * (0.16 + (i % 5) * 0.13) + bob;
      final double scale = 0.95 + (i % 5) * 0.2375; // 0.95x .. 1.90x

      canvas.save();
      canvas.translate(bx, by);
      canvas.scale(scale);

      final List<Color> colors = palettes[i % palettes.length];

      // Burner flame burst (periodic glowing fire inside the balloon throat)
      final bool burnerActive = ((time * 1.1 + i * 0.73) % 2.6) < 0.85;
      if (burnerActive || atmosphereMode == CoconutAtmosphereMode.night) {
        canvas.drawCircle(
          const Offset(0, 12),
          22,
          Paint()
            ..shader = ui.Gradient.radial(
              const Offset(0, 12),
              22,
              [
                const Color(0xFFFFF176).withValues(alpha: 0.75),
                const Color(0xFFFF6D00).withValues(alpha: 0.32),
                Colors.transparent,
              ],
              [0.0, 0.55, 1.0],
            ),
        );
      }

      // Envelope path
      final Path envelope = Path()
        ..moveTo(0, -34)
        ..cubicTo(26, -34, 30, -6, 12, 16)
        ..lineTo(7, 22)
        ..lineTo(-7, 22)
        ..lineTo(-12, 16)
        ..cubicTo(-30, -6, -26, -34, 0, -34)
        ..close();

      canvas.drawPath(envelope, Paint()..color = colors[0]);

      // Vertical colored gores & horizontal decorative band clipped to envelope
      canvas.save();
      canvas.clipPath(envelope);
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, -6), width: 34, height: 58),
        Paint()..color = colors[1],
      );
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, -6), width: 16, height: 58),
        Paint()..color = colors[2],
      );
      canvas.drawRect(
        const Rect.fromLTWH(-32, -12, 64, 7),
        Paint()..color = const Color(0xFFFFF8E1),
      );
      if (burnerActive) {
        canvas.drawCircle(
          const Offset(0, 14),
          14,
          Paint()
            ..color = const Color(0xFFFFAB00).withValues(alpha: 0.55),
        );
      }
      canvas.restore();

      // Envelope outline
      canvas.drawPath(
        envelope,
        Paint()
          ..color = const Color(0xFF3E2723).withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );

      // Visible burner flame between envelope skirt and basket
      if (burnerActive) {
        final Path flame = Path()
          ..moveTo(-3.5, 28)
          ..quadraticBezierTo(0, 18, 3.5, 28)
          ..close();
        canvas.drawPath(flame, Paint()..color = const Color(0xFFFFEB3B));
      }

      // Rigging cables & wicker basket with tiny passenger silhouettes
      final Paint ropePaint = Paint()
        ..color = const Color(0xFF4E342E)
        ..strokeWidth = 0.9;
      canvas.drawLine(const Offset(-5, 22), const Offset(-4, 31), ropePaint);
      canvas.drawLine(const Offset(5, 22), const Offset(4, 31), ropePaint);

      // Passenger silhouettes inside basket
      canvas.drawCircle(
        const Offset(-2.2, 29.0),
        1.8,
        Paint()..color = const Color(0xFF263238),
      );
      canvas.drawCircle(
        const Offset(2.2, 29.2),
        1.7,
        Paint()..color = const Color(0xFF37474F),
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-6, 30.5, 12, 7.5),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFF8D6E63),
      );

      canvas.restore();
    }
  }

  void _drawSoaringHawks(Canvas canvas, Size size, double horizonY) {
    // 14 Soaring desert hawks/vultures riding thermal currents
    final Paint birdPaint = Paint()
      ..color = const Color(0xFF2D1B18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 14; i++) {
      final double deg = (i * 25.7 + time * (1.6 + (i % 3) * 0.4)) % 360.0;
      final double? hx = _worldAngleToScreenX(deg, size, margin: 120);
      if (hx == null) continue;
      final double hy =
          horizonY * (0.20 + (i % 4) * 0.12) + math.sin(time * 2.2 + i) * 6.0;
      final double flap = math.sin(time * 4.5 + i * 1.3) * 5.0;
      final Path wing = Path()
        ..moveTo(hx - 12, hy - flap)
        ..quadraticBezierTo(hx - 5, hy - 4, hx, hy)
        ..quadraticBezierTo(hx + 5, hy - 4, hx + 12, hy - flap);
      canvas.drawPath(wing, birdPaint);
    }
  }

  void _drawOasisLagoonAndCamelCaravan(
    Canvas canvas,
    Size size,
    double horizonY,
  ) {
    final double groundHeight = size.height - horizonY;

    // 1. Sparkling Turquoise Desert Oasis Lagoon fed by a Red-Rock Canyon Waterfall at 64° (1.68x scale)
    final double? oasisX = _worldAngleToScreenX(64.0, size, margin: 480);
    if (oasisX != null) {
      final double lagoonY = horizonY + groundHeight * 0.18;
      final bool isNight = atmosphereMode == CoconutAtmosphereMode.night;

      canvas.save();
      canvas.translate(oasisX, lagoonY);
      canvas.scale(1.68);

      // Tiered Red-Rock Canyon Cliff on the left feeding the Oasis Waterfall
      final Path cliff = Path()
        ..moveTo(-132, -8)
        ..lineTo(-124, -64)
        ..lineTo(-94, -72)
        ..lineTo(-68, -60)
        ..lineTo(-56, -12)
        ..close();
      canvas.drawPath(
        cliff,
        Paint()
          ..shader = ui.Gradient.linear(
            const Offset(-124, -72),
            const Offset(-60, -10),
            isNight
                ? [const Color(0xFF4A2C3D), const Color(0xFF231526)]
                : [const Color(0xFFD85A32), const Color(0xFF8D3220)],
          ),
      );

      // Cascading Turquoise & White Foaming Canyon Waterfall pouring into the lagoon
      final Path falls = Path()
        ..moveTo(-102, -68)
        ..quadraticBezierTo(-92, -38, -84, -8)
        ..lineTo(-70, -8)
        ..quadraticBezierTo(-78, -38, -88, -68)
        ..close();
      canvas.drawPath(
        falls,
        Paint()
          ..shader = ui.Gradient.linear(
            const Offset(-95, -68),
            const Offset(-78, -8),
            [
              const Color(0xFFE0F7FA),
              const Color(0xFF4DD0E1),
              const Color(0xFF00ACC1),
            ],
            [0.0, 0.55, 1.0],
          ),
      );
      // Animated falling water streaks & mist spray at waterfall base
      for (int w = 0; w < 4; w++) {
        final double wy = -62.0 + ((time * 38.0 + w * 14.0) % 50.0);
        canvas.drawLine(
          Offset(-94.0 + w * 4.2, wy),
          Offset(-92.0 + w * 4.2, wy + 8.0),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.80)
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round,
        );
      }
      for (int m = 0; m < 4; m++) {
        final double pulse = 0.6 + 0.4 * math.sin(time * 4.0 + m);
        canvas.drawCircle(
          Offset(-88.0 + m * 6.5, -8.0 + (m.isEven ? 1.5 : -1.0)),
          4.2 * pulse,
          Paint()..color = Colors.white.withValues(alpha: 0.55),
        );
      }

      // Sandy golden shoreline rim
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 230, height: 66),
        Paint()..color = const Color(0xFFF4C27F),
      );

      // Shimmering emerald-turquoise water
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 208, height: 54),
        Paint()
          ..shader = ui.Gradient.linear(
            const Offset(-95, -24),
            const Offset(95, 24),
            isNight
                ? [
                    const Color(0xFF006064),
                    const Color(0xFF00ACC1),
                    const Color(0xFF26C6DA),
                  ]
                : [
                    const Color(0xFF00BFA5),
                    const Color(0xFF26C6DA),
                    const Color(0xFF80DEEA),
                  ],
            [0.0, 0.55, 1.0],
          ),
      );

      // Sunset & waterfall ripples shimmering on the lagoon surface
      for (int r = 0; r < 7; r++) {
        final double rx = -65.0 + r * 22.0 + math.sin(time * 2.4 + r) * 4.0;
        final double ry = -12.0 + (r % 3) * 11.0;
        canvas.drawLine(
          Offset(rx - 12, ry),
          Offset(rx + 12, ry),
          Paint()
            ..color = const Color(0xFFFFECB3).withValues(alpha: 0.65)
            ..strokeWidth = 1.8
            ..strokeCap = StrokeCap.round,
        );
      }

      // Water lilies & reeds around the lagoon edges
      for (int l = 0; l < 6; l++) {
        final double lx = -72.0 + l * 28.0;
        final double ly = (l.isEven ? 14.0 : -14.0);
        canvas.drawOval(
          Rect.fromCenter(center: Offset(lx, ly), width: 10, height: 5),
          Paint()..color = const Color(0xFF43A047),
        );
        if (l.isEven) {
          canvas.drawCircle(
            Offset(lx, ly - 1.5),
            2.4,
            Paint()..color = const Color(0xFFF48FB1),
          );
        }
      }

      // 5 Pink Flamingos wading in the turquoise oasis water
      final List<Offset> flamingoPos = [
        const Offset(-56, 5),
        const Offset(-36, 10),
        const Offset(-8, -3),
        const Offset(26, -5),
        const Offset(48, 7),
      ];
      for (int f = 0; f < flamingoPos.length; f++) {
        final Offset fp = flamingoPos[f];
        final double headBob = math.sin(time * 2.2 + f * 1.4) * 2.5;
        // Thin legs + water ripple
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(fp.dx, fp.dy + 9),
            width: 12,
            height: 3.5,
          ),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.45)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8,
        );
        canvas.drawLine(
          Offset(fp.dx - 1, fp.dy),
          Offset(fp.dx - 1, fp.dy + 9),
          Paint()
            ..color = const Color(0xFFF48FB1)
            ..strokeWidth = 1.1,
        );
        canvas.drawLine(
          Offset(fp.dx + 2, fp.dy),
          Offset(fp.dx + 3, fp.dy + 7),
          Paint()
            ..color = const Color(0xFFF48FB1)
            ..strokeWidth = 1.1,
        );
        // Body
        canvas.drawOval(
          Rect.fromCenter(center: fp, width: 12, height: 7.0),
          Paint()..color = const Color(0xFFFF80AB),
        );
        // S-curved neck and head
        final Path neck = Path()
          ..moveTo(fp.dx + 4, fp.dy - 1)
          ..quadraticBezierTo(
            fp.dx + 9,
            fp.dy - 7,
            fp.dx + 6,
            fp.dy - 13 + headBob,
          );
        canvas.drawPath(
          neck,
          Paint()
            ..color = const Color(0xFFFF4081)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawCircle(
          Offset(fp.dx + 6, fp.dy - 13 + headBob),
          2.3,
          Paint()..color = const Color(0xFFFF80AB),
        );
      }

      // Timber oasis pier & stone water-well on the right bank
      canvas.drawRect(
        const Rect.fromLTWH(58, -8, 38, 8),
        Paint()..color = const Color(0xFF6D4C41),
      );
      for (int p = 0; p < 4; p++) {
        canvas.drawRect(
          Rect.fromLTWH(62.0 + p * 10.0, -8, 2.5, 14),
          Paint()..color = const Color(0xFF4E342E),
        );
      }
      // Stone oasis well with timber roof
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(96, -16, 22, 16),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFFA1887F),
      );
      canvas.drawLine(
        const Offset(99, -16),
        const Offset(99, -32),
        Paint()
          ..color = const Color(0xFF5D4037)
          ..strokeWidth = 2.2,
      );
      canvas.drawLine(
        const Offset(115, -16),
        const Offset(115, -32),
        Paint()
          ..color = const Color(0xFF5D4037)
          ..strokeWidth = 2.2,
      );
      final Path wellRoof = Path()
        ..moveTo(93, -30)
        ..lineTo(107, -40)
        ..lineTo(121, -30)
        ..close();
      canvas.drawPath(wellRoof, Paint()..color = const Color(0xFF8D6E63));

      // 2 Travelers filling terracotta water jugs & resting by the well
      _drawArticulatedTraveler(
        canvas,
        const Offset(84, 0),
        const Color(0xFF1E88E5),
        const Color(0xFFFFF8E1),
        phase: time * 2.0,
        holdingJug: true,
      );
      _drawArticulatedTraveler(
        canvas,
        const Offset(128, 2),
        const Color(0xFFD81B60),
        const Color(0xFFFFCC80),
        phase: time * 2.0 + 1.2,
        isSeated: true,
      );

      // Lush Date Palms framing the oasis lagoon
      _drawDatePalmTree(canvas, const Offset(-104, -8), 70.0, -0.14);
      _drawDatePalmTree(canvas, const Offset(-64, -18), 78.0, 0.08);
      _drawDatePalmTree(canvas, const Offset(78, -16), 74.0, 0.12);
      _drawDatePalmTree(canvas, const Offset(114, -10), 66.0, -0.08);

      canvas.restore();
    }

    // 2. Large 6-Camel Silk Road Caravan at 78° walking along the golden dune ridge (1.68x scale)
    final double? caravanX = _worldAngleToScreenX(78.0, size, margin: 520);
    if (caravanX != null) {
      final double caravanY = horizonY + groundHeight * 0.20;
      canvas.save();
      canvas.translate(caravanX, caravanY);
      canvas.scale(1.68);

      // Lead Bedouin guide in flowing indigo robes holding lead rope & staff
      _drawArticulatedTraveler(
        canvas,
        const Offset(-145, 6),
        const Color(0xFF283593),
        const Color(0xFFFFF8E1),
        phase: time * 2.6,
        holdingStaff: true,
      );

      final List<Color> packColors = [
        const Color(0xFFC62828),
        const Color(0xFF00838F),
        const Color(0xFF6A1B9A),
        const Color(0xFFEF6C00),
        const Color(0xFF2E7D32),
        const Color(0xFFAD1457),
      ];

      for (int c = 0; c < 6; c++) {
        final double cx = -102.0 + c * 44.0;
        final double cy = math.sin(c * 0.9) * 3.5;
        _drawWalkingCamel(
          canvas,
          Offset(cx, cy),
          packColors[c],
          time * 2.8 + c * 0.7,
          hasRider: c.isOdd,
        );
        // Lead rope connecting camels
        if (c > 0) {
          canvas.drawLine(
            Offset(cx - 44.0 + 13.0, cy - 14.0),
            Offset(cx - 22.0, cy - 28.0),
            Paint()
              ..color = const Color(0xFF5D4037)
              ..strokeWidth = 1.1,
          );
        } else {
          canvas.drawLine(
            const Offset(-134, -10),
            Offset(cx - 22.0, cy - 28.0),
            Paint()
              ..color = const Color(0xFF5D4037)
              ..strokeWidth = 1.1,
          );
        }
      }

      // Rear Bedouin guide walking behind the caravan
      _drawArticulatedTraveler(
        canvas,
        const Offset(148, 7),
        const Color(0xFF8D6E63),
        const Color(0xFFFFECB3),
        phase: time * 2.6 + 1.5,
        holdingStaff: true,
      );

      canvas.restore();
    }
  }

  void _drawWalkingCamel(
    Canvas canvas,
    Offset pos,
    Color packColor,
    double walkPhase, {
    bool hasRider = false,
  }) {
    // Internally scaled 1.85x so each camel is ~36px wide and ~32px tall before world 1.88x scaling (~65px on screen)
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.scale(1.85);

    final double stride = math.sin(walkPhase) * 3.5;
    final Paint camelPaint = Paint()..color = const Color(0xFFC68B59);
    final Paint legPaint = Paint()
      ..color = const Color(0xFFA46B3E)
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round;

    // 4 Articulated walking legs
    canvas.drawLine(
      const Offset(-6, -4),
      Offset(-6 + stride, 9),
      legPaint,
    );
    canvas.drawLine(
      const Offset(-3, -4),
      Offset(-3 - stride, 9),
      legPaint,
    );
    canvas.drawLine(
      const Offset(5, -4),
      Offset(5 - stride, 9),
      legPaint,
    );
    canvas.drawLine(
      const Offset(8, -4),
      Offset(8 + stride, 9),
      legPaint,
    );

    // Body & hump
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(1, -7),
        width: 19.5,
        height: 10.5,
      ),
      camelPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(1, -13),
        width: 10.5,
        height: 9.5,
      ),
      camelPaint,
    );

    // Drooping camel tail
    canvas.drawLine(
      const Offset(10, -7),
      Offset(12.5 + stride * 0.2, -1),
      Paint()
        ..color = const Color(0xFF8D5524)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );

    // Colorful Persian saddle blanket & pack
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: const Offset(1, -11),
          width: 11.5,
          height: 8.5,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = packColor,
    );
    canvas.drawLine(
      const Offset(-4.2, -11),
      const Offset(6.2, -11),
      Paint()
        ..color = const Color(0xFFFFD54F)
        ..strokeWidth = 1.4,
    );

    // Bedouin Rider seated on the saddle of every second camel
    if (hasRider) {
      final Path riderRobe = Path()
        ..moveTo(-2.5, -21)
        ..lineTo(3.5, -21)
        ..lineTo(4.5, -12)
        ..lineTo(-3.5, -12)
        ..close();
      canvas.drawPath(riderRobe, Paint()..color = const Color(0xFF1A237E));
      // Rider head & turban
      canvas.drawCircle(
        const Offset(0.5, -23.5),
        2.4,
        Paint()..color = const Color(0xFFD7A17E),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(0.5, -25.0),
          width: 5.8,
          height: 3.2,
        ),
        Paint()..color = const Color(0xFFFFF8E1),
      );
      // Rider arm holding reins
      canvas.drawLine(
        const Offset(-1.5, -19),
        const Offset(-11.5, -16.5),
        Paint()
          ..color = const Color(0xFF5D4037)
          ..strokeWidth = 0.9,
      );
    }

    // Curved neck & head (facing left toward the oasis)
    final Path neck = Path()
      ..moveTo(-7, -6)
      ..quadraticBezierTo(
        -13,
        -10,
        -11,
        -17,
      );
    canvas.drawPath(
      neck,
      Paint()
        ..color = const Color(0xFFC68B59)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(-13, -17.5),
        width: 6.5,
        height: 3.8,
      ),
      camelPaint,
    );

    // Swinging warm lantern hanging from the camel pack
    const Offset lanternPos = Offset(-5, -6);
    canvas.drawCircle(
      lanternPos,
      5.5,
      Paint()
        ..color = const Color(0xFFFFB300).withValues(alpha: 0.35),
    );
    canvas.drawCircle(
      lanternPos,
      1.8,
      Paint()..color = const Color(0xFFFFF59D),
    );

    canvas.restore();
  }

  void _drawDatePalmTree(
    Canvas canvas,
    Offset base,
    double height,
    double lean,
  ) {
    final double sway = math.sin(time * 1.7 + base.dx) * 3.5;
    final Offset crown = Offset(
      base.dx + lean * height + sway,
      base.dy - height,
    );

    final Path trunk = Path()
      ..moveTo(base.dx - 3.2, base.dy)
      ..quadraticBezierTo(
        base.dx + lean * height * 0.35,
        base.dy - height * 0.5,
        crown.dx - 1.5,
        crown.dy,
      )
      ..lineTo(crown.dx + 1.5, crown.dy)
      ..quadraticBezierTo(
        base.dx + lean * height * 0.35 + 3.0,
        base.dy - height * 0.5,
        base.dx + 3.2,
        base.dy,
      )
      ..close();
    canvas.drawPath(trunk, Paint()..color = const Color(0xFF6D4C41));

    // Golden date clusters beneath crown
    canvas.drawCircle(
      Offset(crown.dx - 3, crown.dy + 3),
      3.0,
      Paint()..color = const Color(0xFFFFB300),
    );
    canvas.drawCircle(
      Offset(crown.dx + 3, crown.dy + 3),
      3.0,
      Paint()..color = const Color(0xFFFFA000),
    );

    // 7 Arching palm fronds
    final List<double> angles = [-2.5, -2.0, -1.5, -1.0, -0.5, -0.1, 0.35];
    for (int i = 0; i < angles.length; i++) {
      final double a = angles[i];
      final double fx = crown.dx + math.cos(a) * 26.0;
      final double fy = crown.dy + math.sin(a) * 18.0 + 7.0;
      final Path frond = Path()
        ..moveTo(crown.dx, crown.dy)
        ..quadraticBezierTo(
          (crown.dx + fx) * 0.5,
          crown.dy - 10.0,
          fx,
          fy,
        )
        ..quadraticBezierTo(
          (crown.dx + fx) * 0.5,
          crown.dy - 3.0,
          crown.dx,
          crown.dy,
        );
      canvas.drawPath(
        frond,
        Paint()
          ..color = i.isEven
              ? const Color(0xFF2E7D32)
              : const Color(0xFF43A047),
      );
    }
  }

  void _drawCaravanseraiAndBazaar(
    Canvas canvas,
    Size size,
    double horizonY,
  ) {
    final double groundHeight = size.height - horizonY;
    final bool isNight = atmosphereMode == CoconutAtmosphereMode.night;

    // 1. Petra-Style Rose-Red Rock-Cut Cliff Temple (El-Khazneh / The Treasury) at 110° (yFactor: 0.16, 1.68x scale)
    final double? petraX = _worldAngleToScreenX(110.0, size, margin: 460);
    if (petraX != null) {
      final double baseY = horizonY + groundHeight * 0.16;
      canvas.save();
      canvas.translate(petraX, baseY);
      canvas.scale(1.68);

      // Towering Rose-Red Sandstone Cliff Face housing the carved monument
      final Path cliffFace = Path()
        ..moveTo(-88, 2)
        ..lineTo(-82, -96)
        ..lineTo(-48, -112)
        ..lineTo(48, -110)
        ..lineTo(84, -92)
        ..lineTo(88, 2)
        ..close();
      canvas.drawPath(
        cliffFace,
        Paint()
          ..shader = ui.Gradient.linear(
            const Offset(-80, -110),
            const Offset(80, 0),
            isNight
                ? [const Color(0xFF4A2538), const Color(0xFF241324)]
                : [const Color(0xFFC85A48), const Color(0xFF7D2E28)],
          ),
      );

      // Recessed dark rock-cut portico niche
      canvas.drawRect(
        const Rect.fromLTWH(-52, -88, 104, 88),
        Paint()..color = const Color(0xFF2B1212),
      );

      const Color roseStone = Color(0xFFE88D72);
      const Color roseHighlight = Color(0xFFFFB499);

      // Lower Order: 6 Corinthian Sandstone Columns + Entablature + Triangular Pediment
      for (final double cx in [-44.0, -27.0, -12.0, 12.0, 27.0, 44.0]) {
        canvas.drawRect(
          Rect.fromLTWH(cx - 2.8, -42, 5.6, 40),
          Paint()..color = roseStone,
        );
        // Ornate capital
        canvas.drawRect(
          Rect.fromLTWH(cx - 4.0, -45, 8.0, 3.2),
          Paint()..color = roseHighlight,
        );
      }
      // Sanctuary entrance portal
      canvas.drawRect(
        const Rect.fromLTWH(-8, -28, 16, 26),
        Paint()
          ..color = isNight
              ? const Color(0xFFFFB300).withValues(alpha: 0.75)
              : const Color(0xFF160808),
      );
      // Lower entablature frieze & central triangular pediment
      canvas.drawRect(
        const Rect.fromLTWH(-50, -50, 100, 5),
        Paint()..color = roseHighlight,
      );
      final Path pediment = Path()
        ..moveTo(-34, -50)
        ..lineTo(0, -61)
        ..lineTo(34, -50)
        ..close();
      canvas.drawPath(pediment, Paint()..color = roseStone);

      // Upper Order: Broken Pediment bays + Central Circular Tholos + Royal Funerary Urn
      // Left & right broken-pediment wings
      final Path leftWing = Path()
        ..moveTo(-48, -50)
        ..lineTo(-48, -76)
        ..lineTo(-20, -84)
        ..lineTo(-20, -50)
        ..close();
      final Path rightWing = Path()
        ..moveTo(48, -50)
        ..lineTo(48, -76)
        ..lineTo(20, -84)
        ..lineTo(20, -50)
        ..close();
      canvas.drawPath(leftWing, Paint()..color = roseStone);
      canvas.drawPath(rightWing, Paint()..color = roseStone);

      // Central Tholos (round temple rotunda) & conical roof
      canvas.drawRect(
        const Rect.fromLTWH(-13, -78, 26, 26),
        Paint()..color = roseHighlight,
      );
      final Path tholosRoof = Path()
        ..moveTo(-16, -78)
        ..lineTo(0, -91)
        ..lineTo(16, -78)
        ..close();
      canvas.drawPath(tholosRoof, Paint()..color = roseStone);
      // Royal Khazneh Urn crowning the tholos
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, -95), width: 7.5, height: 9.0),
        Paint()..color = const Color(0xFFFFCC80),
      );

      // Flaming Siq torches flanking the Petra Treasury entrance
      for (final double tx in [-58.0, 58.0]) {
        canvas.drawCircle(
          Offset(tx, -12),
          7.5,
          Paint()..color = const Color(0xFFFF8F00).withValues(alpha: 0.42),
        );
        canvas.drawCircle(
          Offset(tx, -12),
          2.8,
          Paint()..color = const Color(0xFFFFF176),
        );
      }

      canvas.restore();
    }

    // 2. Sandstone Caravanserai Fortress & Adobe Village at 124° (yFactor: 0.18, 1.68x scale)
    final double? fortX = _worldAngleToScreenX(124.0, size, margin: 420);
    if (fortX != null) {
      final double baseY = horizonY + groundHeight * 0.18;
      canvas.save();
      canvas.translate(fortX, baseY);
      canvas.scale(1.68);

      // Mud-brick walls, Badgir windcatcher towers & golden domes
      canvas.drawRect(
        const Rect.fromLTWH(-78, -46, 62, 46),
        Paint()..color = const Color(0xFFD79968),
      );
      canvas.drawRect(
        const Rect.fromLTWH(-18, -58, 74, 58),
        Paint()..color = const Color(0xFFE0A97B),
      );
      canvas.drawRect(
        const Rect.fromLTWH(52, -42, 48, 42),
        Paint()..color = const Color(0xFFCC8B5A),
      );

      // Traditional Badgir (Windcatcher) tower on the left & right
      for (final double wx in [-62.0, 66.0]) {
        canvas.drawRect(
          Rect.fromLTWH(wx, -74, 22, 32),
          Paint()..color = const Color(0xFFC88755),
        );
        for (int v = 0; v < 3; v++) {
          canvas.drawRect(
            Rect.fromLTWH(wx + 3.0 + v * 6.0, -70, 3.5, 18),
            Paint()..color = const Color(0xFF4E342E),
          );
        }
      }

      // Golden Caravanserai central dome + crescent finial
      final Path dome = Path()
        ..moveTo(-6, -58)
        ..quadraticBezierTo(19, -92, 44, -58)
        ..close();
      canvas.drawPath(
        dome,
        Paint()
          ..shader = ui.Gradient.linear(
            const Offset(-6, -86),
            const Offset(44, -58),
            [const Color(0xFFFFD54F), const Color(0xFFEF6C00)],
          ),
      );
      canvas.drawLine(
        const Offset(19, -76),
        const Offset(19, -85),
        Paint()
          ..color = const Color(0xFFFFECB3)
          ..strokeWidth = 1.6,
      );

      // Protruding wooden roof beams (khorjin style) & rooftop carpet
      for (int b = 0; b < 12; b++) {
        canvas.drawCircle(
          Offset(-72.0 + b * 14.0, b < 4 ? -42.0 : (b < 9 ? -53.0 : -38.0)),
          1.8,
          Paint()..color = const Color(0xFF4E342E),
        );
      }
      canvas.drawRect(
        const Rect.fromLTWH(-42, -46, 16, 11),
        Paint()..color = const Color(0xFFC62828),
      );

      // Grand arched keyhole gate & glowing windows
      final Path gate = Path()
        ..moveTo(8, 0)
        ..lineTo(8, -24)
        ..arcToPoint(const Offset(30, -24), radius: const Radius.circular(11))
        ..lineTo(30, 0)
        ..close();
      canvas.drawPath(
        gate,
        Paint()
          ..color = isNight
              ? const Color(0xFFFFB300)
              : const Color(0xFF3E2723),
      );

      for (final Offset win in [
        const Offset(-58, -26),
        const Offset(-36, -26),
        const Offset(66, -24),
        const Offset(84, -24),
      ]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: win, width: 8, height: 12),
            const Radius.circular(4),
          ),
          Paint()
            ..color = isNight
                ? const Color(0xFFFFE082)
                : const Color(0xFF5D4037),
        );
      }

      canvas.restore();
    }

    // 3. Grand Persian Carpet & Spice Bazaar at 134° (yFactor: 0.19, 1.68x scale)
    final double? bazaarX = _worldAngleToScreenX(134.0, size, margin: 460);
    if (bazaarX != null) {
      final double baseY = horizonY + groundHeight * 0.19;
      canvas.save();
      canvas.translate(bazaarX, baseY);
      canvas.scale(1.68);

      // Sandstone arcade backdrop
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-74, -42, 148, 42),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xFFD69361),
      );

      // Colorful woven bazaar canopy stripes
      for (int s = 0; s < 10; s++) {
        canvas.drawRect(
          Rect.fromLTWH(-76.0 + s * 15.2, -46, 15.2, 9),
          Paint()
            ..color = s.isEven
                ? const Color(0xFFC62828)
                : (s % 3 == 0
                    ? const Color(0xFF00838F)
                    : const Color(0xFFFFB300)),
        );
      }

      // Hanging Persian rugs with geometric diamond patterns
      final List<Color> rugColors = [
        const Color(0xFFB71C1C),
        const Color(0xFF1A237E),
        const Color(0xFF00695C),
        const Color(0xFFAD1457),
      ];
      for (int r = 0; r < 4; r++) {
        final double rx = -62.0 + r * 34.0;
        canvas.drawRect(
          Rect.fromLTWH(rx, -34, 18, 26),
          Paint()..color = rugColors[r],
        );
        canvas.drawRect(
          Rect.fromLTWH(rx + 2.5, -31.5, 13, 21),
          Paint()
            ..color = const Color(0xFFFFD54F)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0,
        );
        canvas.drawCircle(
          Offset(rx + 9, -21),
          3.5,
          Paint()..color = const Color(0xFFFFECB3),
        );
      }

      // Spice sacks filled with saffron, turmeric, sumac & paprika mounds
      final List<Color> spiceColors = [
        const Color(0xFFFFB300),
        const Color(0xFFD32F2F),
        const Color(0xFF8E24AA),
        const Color(0xFFE65100),
        const Color(0xFF43A047),
      ];
      for (int sp = 0; sp < 5; sp++) {
        final double sx = -45.0 + sp * 18.0;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(sx, -6, 11, 7),
            const Radius.circular(2),
          ),
          Paint()..color = const Color(0xFFA1887F),
        );
        final Path spiceCone = Path()
          ..moveTo(sx + 1, -6)
          ..quadraticBezierTo(sx + 5.5, -13, sx + 10, -6)
          ..close();
        canvas.drawPath(spiceCone, Paint()..color = spiceColors[sp]);
      }

      // Festoon string of glowing brass bazaar lamps
      for (int l = 0; l < 7; l++) {
        final Offset lp = Offset(-60.0 + l * 20.0, -35.0 + (l.isEven ? 2 : 0));
        canvas.drawCircle(
          lp,
          6.0,
          Paint()
            ..color = const Color(0xFFFFCA28).withValues(alpha: 0.38),
        );
        canvas.drawCircle(
          lp,
          2.2,
          Paint()..color = const Color(0xFFFFF59D),
        );
      }

      // Merchant + 5 Shoppers/Travelers browsing rugs & drinking mint tea at low table
      _drawArticulatedTraveler(
        canvas,
        const Offset(-14, 1),
        const Color(0xFF6A1B9A),
        const Color(0xFFFFD54F),
        phase: time * 2.4,
      );
      _drawArticulatedTraveler(
        canvas,
        const Offset(-56, 4),
        const Color(0xFF00838F),
        const Color(0xFFFFF8E1),
        phase: time * 2.1 + 0.6,
      );
      _drawArticulatedTraveler(
        canvas,
        const Offset(-34, 5),
        const Color(0xFFD84315),
        const Color(0xFFFFCC80),
        phase: time * 2.1 + 1.4,
      );
      _drawArticulatedTraveler(
        canvas,
        const Offset(16, 4),
        const Color(0xFF2E7D32),
        const Color(0xFFFFF8E1),
        phase: time * 2.2 + 2.0,
      );

      // Low brass tea table on the right with 2 seated travelers sipping mint tea
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(54, 5), width: 18, height: 6),
        Paint()..color = const Color(0xFFFFB300),
      );
      _drawArticulatedTraveler(
        canvas,
        const Offset(39, 6),
        const Color(0xFF1565C0),
        const Color(0xFFFFECB3),
        phase: time * 1.9 + 0.5,
        isSeated: true,
      );
      _drawArticulatedTraveler(
        canvas,
        const Offset(69, 6),
        const Color(0xFFAD1457),
        const Color(0xFFFFF8E1),
        phase: time * 1.9 + 1.8,
        isSeated: true,
      );

      canvas.restore();
    }

    // 4. Adobe Pottery & Lantern Workshop at 148° (yFactor: 0.18, 1.68x scale)
    final double? potteryX = _worldAngleToScreenX(148.0, size, margin: 380);
    if (potteryX != null) {
      final double baseY = horizonY + groundHeight * 0.18;
      canvas.save();
      canvas.translate(potteryX, baseY);
      canvas.scale(1.68);

      // Adobe workshop & dome kiln
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-44, -34, 62, 34),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xFFCF8A58),
      );
      final Path kiln = Path()
        ..moveTo(22, 0)
        ..quadraticBezierTo(38, -36, 54, 0)
        ..close();
      canvas.drawPath(kiln, Paint()..color = const Color(0xFFB86B3D));
      canvas.drawArc(
        const Rect.fromLTWH(31, -12, 14, 14),
        math.pi,
        math.pi,
        true,
        Paint()..color = const Color(0xFFFF6F00),
      );

      // Terracotta amphora jars stacked outside
      for (int j = 0; j < 6; j++) {
        final double jx = -38.0 + j * 10.5;
        canvas.drawOval(
          Rect.fromCenter(center: Offset(jx, -5), width: 7.5, height: 11),
          Paint()
            ..color = j.isEven
                ? const Color(0xFFD84315)
                : const Color(0xFFBF360C),
        );
        canvas.drawRect(
          Rect.fromLTWH(jx - 2, -12, 4, 3),
          Paint()..color = const Color(0xFFE64A19),
        );
      }

      // Potter working at spinning wheel
      _drawArticulatedTraveler(
        canvas,
        const Offset(6, 2),
        const Color(0xFF5D4037),
        const Color(0xFFFFCC80),
        phase: time * 3.0,
        isSeated: true,
      );

      canvas.restore();
    }
  }

  void _drawBedouinCampfireScene(
    Canvas canvas,
    Size size,
    double horizonY,
  ) {
    final double groundHeight = size.height - horizonY;

    // Patterned Bedouin Tent Pavilion + Roaring Campfire at 165° (yFactor: 0.20, 1.70x scale)
    final double? campX = _worldAngleToScreenX(165.0, size, margin: 480);
    if (campX == null) return;

    final double baseY = horizonY + groundHeight * 0.20;
    canvas.save();
    canvas.translate(campX, baseY);
    canvas.scale(1.70);

    // 1. Patterned Bedouin Tent Pavilion slightly to the left (representing 158°..163°)
    final Path tentCanopy = Path()
      ..moveTo(-112, -8)
      ..lineTo(-82, -42)
      ..lineTo(-46, -34)
      ..lineTo(-18, -44)
      ..lineTo(12, -10)
      ..close();
    canvas.drawPath(tentCanopy, Paint()..color = const Color(0xFF8D2828));

    // Geometric woven Bedouin stripes on the tent roof
    canvas.drawLine(
      const Offset(-102, -16),
      const Offset(2, -18),
      Paint()
        ..color = const Color(0xFFFFCA28)
        ..strokeWidth = 2.6,
    );
    canvas.drawLine(
      const Offset(-94, -24),
      const Offset(-8, -26),
      Paint()
        ..color = const Color(0xFF26A69A)
        ..strokeWidth = 2.2,
    );

    // Tent poles & warm interior glow
    for (final double px in [-106.0, -82.0, -46.0, -18.0, 8.0]) {
      canvas.drawLine(
        Offset(px, -36),
        Offset(px, 2),
        Paint()
          ..color = const Color(0xFF4E342E)
          ..strokeWidth = 2.0,
      );
    }

    // 2. Persian Carpets & Floor Cushions spread on the sand around the fire
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-18, 12), width: 165, height: 34),
      Paint()..color = const Color(0xFF7B1FA2).withValues(alpha: 0.45),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-74, 4, 56, 14),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFB71C1C),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(16, 4, 58, 14),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF00695C),
    );

    // Golden brass samovar / Arabic coffee & tea set on carpet
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-22, 9), width: 14, height: 4.5),
      Paint()..color = const Color(0xFFFFB300),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-22, 4), width: 6, height: 9),
      Paint()..color = const Color(0xFFFFD54F),
    );

    // Flanking desert torch braziers
    for (final double tx in [-92.0, 84.0]) {
      canvas.drawLine(
        Offset(tx, 8),
        Offset(tx, -22),
        Paint()
          ..color = const Color(0xFF4E342E)
          ..strokeWidth = 2.2,
      );
      canvas.drawCircle(
        Offset(tx, -25),
        10,
        Paint()
          ..color = const Color(0xFFFF8F00).withValues(alpha: 0.38),
      );
      canvas.drawCircle(
        Offset(tx, -25),
        3.8,
        Paint()..color = const Color(0xFFFFF176),
      );
    }

    // 3. 7 Articulated Travelers & Nomads around the campfire
    // Seated musician playing Oud / Lute on the left with floating musical notes
    _drawArticulatedTraveler(
      canvas,
      const Offset(-58, 6),
      const Color(0xFF283593),
      const Color(0xFFFFD54F),
      phase: time * 3.2,
      isSeated: true,
      playingOud: true,
    );
    // Seated tea pourer
    _drawArticulatedTraveler(
      canvas,
      const Offset(-36, 8),
      const Color(0xFF00695C),
      const Color(0xFFFFF8E1),
      phase: time * 2.4 + 0.8,
      isSeated: true,
    );
    // Standing nomad storyteller with ••• speech bubble
    _drawArticulatedTraveler(
      canvas,
      const Offset(-78, 2),
      const Color(0xFFAD1457),
      const Color(0xFFFFCC80),
      phase: time * 2.6 + 1.2,
      hasSpeechBubble: true,
    );
    // Seated stargazers & listeners on the right side of the bonfire
    _drawArticulatedTraveler(
      canvas,
      const Offset(26, 8),
      const Color(0xFFD84315),
      const Color(0xFFFFF8E1),
      phase: time * 2.2 + 1.9,
      isSeated: true,
    );
    _drawArticulatedTraveler(
      canvas,
      const Offset(48, 7),
      const Color(0xFF4527A0),
      const Color(0xFFFFECB3),
      phase: time * 2.5 + 2.5,
      isSeated: true,
      hasSpeechBubble: ((time * 0.4) % 2.0) > 1.0,
    );
    _drawArticulatedTraveler(
      canvas,
      const Offset(68, 4),
      const Color(0xFF1565C0),
      const Color(0xFFFFD54F),
      phase: time * 2.1 + 3.1,
    );
    _drawArticulatedTraveler(
      canvas,
      const Offset(-12, 3),
      const Color(0xFF6D4C41),
      const Color(0xFFFFF8E1),
      phase: time * 2.3 + 0.4,
    );

    // Floating musical notes rising from the Oud player
    for (int n = 0; n < 3; n++) {
      final double np = (time * 0.55 + n * 0.33) % 1.0;
      final double nx = -56.0 + math.sin(time * 2.8 + n) * 8.0;
      final double ny = -24.0 - np * 28.0;
      final double alpha = math.sin(np * math.pi).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(nx, ny),
        2.4,
        Paint()
          ..color = const Color(0xFFFFD54F).withValues(alpha: alpha * 0.9),
      );
      canvas.drawLine(
        Offset(nx + 2.2, ny),
        Offset(nx + 2.2, ny - 6.5),
        Paint()
          ..color = const Color(0xFFFFD54F).withValues(alpha: alpha * 0.9)
          ..strokeWidth = 1.3,
      );
    }

    // 4. Roaring 5-Layer Desert Bonfire at center (4, 8)
    // Ambient ground fire glow
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(4, 12), width: 76, height: 22),
      Paint()
        ..shader = ui.Gradient.radial(
          const Offset(4, 12),
          38,
          [
            const Color(0xFFFF6D00).withValues(alpha: 0.55),
            Colors.transparent,
          ],
        ),
    );
    // Crossed desert logs & stones
    canvas.drawLine(
      const Offset(-10, 12),
      const Offset(16, 6),
      Paint()
        ..color = const Color(0xFF3E2723)
        ..strokeWidth = 3.6
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      const Offset(-8, 6),
      const Offset(18, 12),
      Paint()
        ..color = const Color(0xFF4E342E)
        ..strokeWidth = 3.6
        ..strokeCap = StrokeCap.round,
    );

    final List<Color> flameColors = [
      const Color(0xFFB71C1C),
      const Color(0xFFE65100),
      const Color(0xFFFF9800),
      const Color(0xFFFFEB3B),
      const Color(0xFFFFFDE7),
    ];
    for (int f = 0; f < 5; f++) {
      final double fw = 22.0 - f * 3.6;
      final double fh = 28.0 - f * 4.2 + math.sin(time * 7.0 + f) * 3.0;
      final double sway = math.sin(time * 5.5 + f * 0.8) * 2.8;
      final Path flame = Path()
        ..moveTo(4 - fw * 0.5, 9)
        ..quadraticBezierTo(4 - fw * 0.3, 9 - fh * 0.5, 4 + sway, 9 - fh)
        ..quadraticBezierTo(4 + fw * 0.3, 9 - fh * 0.5, 4 + fw * 0.5, 9)
        ..close();
      canvas.drawPath(flame, Paint()..color = flameColors[f]);
    }

    // Rising campfire sparks
    for (int s = 0; s < 7; s++) {
      final double sp = (time * 0.7 + s * 0.14) % 1.0;
      final double sx = 4.0 + math.sin(time * 4.0 + s * 1.7) * 10.0;
      final double sy = 4.0 - sp * 38.0;
      canvas.drawCircle(
        Offset(sx, sy),
        1.3,
        Paint()
          ..color = const Color(0xFFFFEA00).withValues(alpha: 1.0 - sp),
      );
    }

    // 5. Cute Fennec Fox with oversized ears relaxing near the fire
    const Offset fox = Offset(19, 14);
    canvas.drawOval(
      Rect.fromCenter(center: fox, width: 10, height: 5.5),
      Paint()..color = const Color(0xFFF4C27F),
    );
    // Fluffy cream tail
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(fox.dx + 6, fox.dy + 1),
        width: 6.5,
        height: 3.2,
      ),
      Paint()..color = const Color(0xFFFFECB3),
    );
    // Head & iconic huge Fennec Fox ears
    canvas.drawCircle(
      Offset(fox.dx - 4.5, fox.dy - 2.5),
      3.0,
      Paint()..color = const Color(0xFFF4C27F),
    );
    final Path leftEar = Path()
      ..moveTo(fox.dx - 6, fox.dy - 4)
      ..lineTo(fox.dx - 9, fox.dy - 11)
      ..lineTo(fox.dx - 4, fox.dy - 5)
      ..close();
    final Path rightEar = Path()
      ..moveTo(fox.dx - 4, fox.dy - 5)
      ..lineTo(fox.dx - 2, fox.dy - 12)
      ..lineTo(fox.dx - 1.5, fox.dy - 4)
      ..close();
    canvas.drawPath(leftEar, Paint()..color = const Color(0xFFF4C27F));
    canvas.drawPath(rightEar, Paint()..color = const Color(0xFFF4C27F));

    canvas.restore();
  }

  void _drawArticulatedTraveler(
    Canvas canvas,
    Offset pos,
    Color robeColor,
    Color turbanColor, {
    required double phase,
    bool isSeated = false,
    bool holdingStaff = false,
    bool holdingJug = false,
    bool playingOud = false,
    bool hasSpeechBubble = false,
  }) {
    // Internally scaled 1.85x so a standing traveler is ~30px tall before world scaling (~55px on screen)
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.scale(1.85);

    final double armWave = math.sin(phase) * 3.0;
    final double legStep = isSeated ? 0.0 : math.sin(phase) * 2.4;

    // Legs
    final Paint legPaint = Paint()
      ..color = const Color(0xFF3E2723)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    if (!isSeated) {
      canvas.drawLine(
        const Offset(-1.8, -5),
        Offset(-1.8 + legStep, 2),
        legPaint,
      );
      canvas.drawLine(
        const Offset(1.8, -5),
        Offset(1.8 - legStep, 2),
        legPaint,
      );
    }

    // Flowing Bedouin robe / tunic
    final Path robe = Path()
      ..moveTo(-3.5, -13)
      ..lineTo(3.5, -13)
      ..lineTo(isSeated ? 5.5 : 4.2, isSeated ? -1.0 : -3.0)
      ..lineTo(isSeated ? -5.5 : -4.2, isSeated ? -1.0 : -3.0)
      ..close();
    canvas.drawPath(robe, Paint()..color = robeColor);

    // Articulated arms
    final Paint armPaint = Paint()
      ..color = robeColor
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      const Offset(-3, -11),
      Offset(-6.5, -7 + armWave * 0.5),
      armPaint,
    );
    canvas.drawLine(
      const Offset(3, -11),
      Offset(6.5, -8 - armWave * 0.5),
      armPaint,
    );

    // Head & desert turban / keffiyeh
    canvas.drawCircle(
      const Offset(0, -16),
      2.8,
      Paint()..color = const Color(0xFFD7A17E),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0, -17.5),
        width: 6.8,
        height: 3.8,
      ),
      Paint()..color = turbanColor,
    );

    // Optional wooden walking staff
    if (holdingStaff) {
      canvas.drawLine(
        const Offset(-6.5, -16),
        const Offset(-6.5, 2),
        Paint()
          ..color = const Color(0xFF5D4037)
          ..strokeWidth = 1.2,
      );
    }

    // Optional terracotta water jug
    if (holdingJug) {
      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(6.5, -7),
          width: 4.5,
          height: 6.0,
        ),
        Paint()..color = const Color(0xFFD84315),
      );
    }

    // Optional Oud / desert lute
    if (playingOud) {
      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(3.5, -7.5),
          width: 7.5,
          height: 5.2,
        ),
        Paint()..color = const Color(0xFF8D6E63),
      );
      canvas.drawLine(
        const Offset(6, -8),
        const Offset(11, -11),
        Paint()
          ..color = const Color(0xFF4E342E)
          ..strokeWidth = 1.4,
      );
    }

    // Optional animated ••• speech bubble
    if (hasSpeechBubble) {
      final Rect bubbleRect = Rect.fromCenter(
        center: const Offset(0, -25),
        width: 14,
        height: 7.5,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(bubbleRect, const Radius.circular(3.5)),
        Paint()..color = const Color(0xFFFFF8E1).withValues(alpha: 0.92),
      );
      for (int d = -1; d <= 1; d++) {
        canvas.drawCircle(
          Offset(d * 3.2, -25),
          1.0,
          Paint()..color = const Color(0xFF4E342E),
        );
      }
    }

    canvas.restore();
  }

  void _drawRuinsAndObservatory(
    Canvas canvas,
    Size size,
    double horizonY,
  ) {
    final double groundHeight = size.height - horizonY;

    // 1. Stepped Ancient Desert Pyramid, Temple Ruins & Twin Obelisks at 214° (yFactor: 0.20, 1.68x scale)
    final double? ruinsX = _worldAngleToScreenX(214.0, size, margin: 480);
    if (ruinsX != null) {
      final double baseY = horizonY + groundHeight * 0.20;
      canvas.save();
      canvas.translate(ruinsX, baseY);
      canvas.scale(1.68);

      // 5-Tier Stepped Ancient Sandstone Pyramid rising behind the temple ruins
      for (int step = 0; step < 5; step++) {
        final double sw = 128.0 - step * 22.0;
        final double sh = 14.0;
        final double sy = -8.0 - (step + 1) * sh;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(-sw * 0.5, sy, sw, sh + 1.0),
            const Radius.circular(2),
          ),
          Paint()
            ..color = step.isEven
                ? const Color(0xFFD6915C)
                : const Color(0xFFC27A46),
        );
      }
      // Central stepped ceremonial staircase up the pyramid face
      final Path stairs = Path()
        ..moveTo(-11, -8)
        ..lineTo(-7, -78)
        ..lineTo(7, -78)
        ..lineTo(11, -8)
        ..close();
      canvas.drawPath(stairs, Paint()..color = const Color(0xFFA86434));

      // Stepped sandstone temple platform
      canvas.drawRect(
        const Rect.fromLTWH(-78, -8, 156, 8),
        Paint()..color = const Color(0xFFC88755),
      );

      // Twin carved obelisks with golden pyramidions
      for (final double ox in [-68.0, 62.0]) {
        final Path obelisk = Path()
          ..moveTo(ox - 6, -8)
          ..lineTo(ox - 4, -58)
          ..lineTo(ox, -68)
          ..lineTo(ox + 4, -58)
          ..lineTo(ox + 6, -8)
          ..close();
        canvas.drawPath(obelisk, Paint()..color = const Color(0xFFD99B66));
        final Path cap = Path()
          ..moveTo(ox - 4, -58)
          ..lineTo(ox, -68)
          ..lineTo(ox + 4, -58)
          ..close();
        canvas.drawPath(cap, Paint()..color = const Color(0xFFFFD54F));

        // Hieroglyph carvings along the obelisk shaft
        for (int h = 0; h < 5; h++) {
          canvas.drawCircle(
            Offset(ox, -50.0 + h * 8.0),
            1.3,
            Paint()..color = const Color(0xFF5D4037),
          );
        }
      }

      // 4 Temple columns with broken architrave lintel
      for (int c = 0; c < 4; c++) {
        final double cx = -38.0 + c * 25.0;
        final double ch = (c == 2) ? 28.0 : 44.0;
        canvas.drawRect(
          Rect.fromLTWH(cx - 4.2, -8 - ch, 8.4, ch),
          Paint()..color = const Color(0xFFE5B285),
        );
      }
      canvas.drawRect(
        const Rect.fromLTWH(-45, -58, 64, 6.5),
        Paint()..color = const Color(0xFFCC8B5A),
      );

      // Flaming stone temple braziers
      for (final double bx in [-50.0, 48.0]) {
        canvas.drawRect(
          Rect.fromLTWH(bx - 4, -18, 8, 10),
          Paint()..color = const Color(0xFF6D4C41),
        );
        canvas.drawCircle(
          Offset(bx, -21),
          8.5,
          Paint()
            ..color = const Color(0xFFFF9800).withValues(alpha: 0.42),
        );
        canvas.drawCircle(
          Offset(bx, -21),
          3.2,
          Paint()..color = const Color(0xFFFFF176),
        );
      }

      // 2 Archaeologists/travelers exploring the hieroglyphs
      _drawArticulatedTraveler(
        canvas,
        const Offset(-22, 2),
        const Color(0xFF8D6E63),
        const Color(0xFFFFECB3),
        phase: time * 2.2,
        holdingStaff: true,
      );
      _drawArticulatedTraveler(
        canvas,
        const Offset(28, 3),
        const Color(0xFF00838F),
        const Color(0xFFFFF8E1),
        phase: time * 2.2 + 1.3,
      );

      canvas.restore();
    }

    // 2. Spinning Western Wooden Windmill & Redwood Water-Tower at 232° (yFactor: 0.19, 1.68x scale)
    final double? millX = _worldAngleToScreenX(232.0, size, margin: 400);
    if (millX != null) {
      final double baseY = horizonY + groundHeight * 0.19;
      canvas.save();
      canvas.translate(millX, baseY);
      canvas.scale(1.68);

      // Redwood Water-Tower on timber stilts beside the windmill
      final Paint postPaint = Paint()
        ..color = const Color(0xFF5D4037)
        ..strokeWidth = 2.4;
      canvas.drawLine(const Offset(-34, 0), const Offset(-30, -28), postPaint);
      canvas.drawLine(const Offset(-16, 0), const Offset(-20, -28), postPaint);
      canvas.drawLine(const Offset(-33, -12), const Offset(-17, -12), postPaint);
      // Cylindrical redwood tank with iron hoops & conical roof
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-34, -48, 18, 20),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFFA14A2E),
      );
      canvas.drawLine(
        const Offset(-34, -42),
        const Offset(-16, -42),
        Paint()
          ..color = const Color(0xFF37474F)
          ..strokeWidth = 1.4,
      );
      canvas.drawLine(
        const Offset(-34, -34),
        const Offset(-16, -34),
        Paint()
          ..color = const Color(0xFF37474F)
          ..strokeWidth = 1.4,
      );
      final Path tankRoof = Path()
        ..moveTo(-36, -48)
        ..lineTo(-25, -56)
        ..lineTo(-14, -48)
        ..close();
      canvas.drawPath(tankRoof, Paint()..color = const Color(0xFF6D4C41));

      // Tall A-Frame Western Windmill Derrick
      canvas.drawLine(const Offset(2, 0), const Offset(12, -68), postPaint);
      canvas.drawLine(const Offset(24, 0), const Offset(14, -68), postPaint);
      for (int r = 1; r <= 4; r++) {
        final double ry = -r * 14.0;
        final double halfW = 11.0 - r * 2.0;
        canvas.drawLine(
          Offset(13 - halfW, ry),
          Offset(13 + halfW, ry),
          Paint()
            ..color = const Color(0xFF6D4C41)
            ..strokeWidth = 1.4,
        );
      }
      // Tail vane
      final Path vane = Path()
        ..moveTo(13, -68)
        ..lineTo(29, -73)
        ..lineTo(29, -63)
        ..close();
      canvas.drawPath(vane, Paint()..color = const Color(0xFFB0BEC5));

      // Spinning multi-blade galvanized turbine wheel
      canvas.save();
      canvas.translate(13, -68);
      canvas.rotate(time * 2.4);
      for (int b = 0; b < 8; b++) {
        final double a = (b / 8.0) * math.pi * 2.0;
        canvas.drawLine(
          Offset.zero,
          Offset(math.cos(a) * 16.0, math.sin(a) * 16.0),
          Paint()
            ..color = const Color(0xFFCFD8DC)
            ..strokeWidth = 2.0
            ..strokeCap = StrokeCap.round,
        );
      }
      canvas.drawCircle(
        Offset.zero,
        16.0,
        Paint()
          ..color = const Color(0xFF90A4AE)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      canvas.drawCircle(
        Offset.zero,
        3.0,
        Paint()..color = const Color(0xFFD84315),
      );
      canvas.restore();

      canvas.restore();
    }

    // 3. Domed Desert Astronomy Observatory at 250° (yFactor: 0.20, 1.68x scale)
    final double? obsX = _worldAngleToScreenX(250.0, size, margin: 450);
    if (obsX != null) {
      final double baseY = horizonY + groundHeight * 0.20;
      canvas.save();
      canvas.translate(obsX, baseY);
      canvas.scale(1.68);

      // Cylindrical adobe/stone observatory base
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-36, -34, 72, 34),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xFFD79968),
      );

      // Rotating copper & silver telescope dome
      final Path dome = Path()
        ..moveTo(-38, -34)
        ..arcToPoint(
          const Offset(38, -34),
          radius: const Radius.circular(38),
        )
        ..close();
      canvas.drawPath(
        dome,
        Paint()
          ..shader = ui.Gradient.linear(
            const Offset(-36, -68),
            const Offset(36, -34),
            [
              const Color(0xFFECEFF1),
              const Color(0xFF90A4AE),
              const Color(0xFFD87A4A),
            ],
            [0.0, 0.6, 1.0],
          ),
      );

      // Observatory slit & protruding main refractor telescope tube
      canvas.drawLine(
        const Offset(8, -56),
        const Offset(28, -74),
        Paint()
          ..color = const Color(0xFF37474F)
          ..strokeWidth = 5.5
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        const Offset(29, -75),
        3.0,
        Paint()..color = const Color(0xFF80DEEA),
      );

      // 2 Outdoor Brass Telescopes on wooden tripods with Astronomers peering at the sky
      for (int t = 0; t < 2; t++) {
        final double tx = (t == 0) ? -64.0 : 62.0;
        final double dir = (t == 0) ? -1.0 : 1.0;

        // Tripod legs
        final Paint tripodPaint = Paint()
          ..color = const Color(0xFF5D4037)
          ..strokeWidth = 1.8;
        canvas.drawLine(Offset(tx, -18), Offset(tx - 8, 2), tripodPaint);
        canvas.drawLine(Offset(tx, -18), Offset(tx + 8, 2), tripodPaint);
        canvas.drawLine(Offset(tx, -18), Offset(tx, 3), tripodPaint);

        // Gleaming brass telescope tube aimed skyward
        canvas.drawLine(
          Offset(tx - dir * 6, -15),
          Offset(tx + dir * 13, -27),
          Paint()
            ..color = const Color(0xFFFFCA28)
            ..strokeWidth = 3.4
            ..strokeCap = StrokeCap.round,
        );

        // Astronomer standing right beside the eyepiece
        _drawArticulatedTraveler(
          canvas,
          Offset(tx - dir * 14, 2),
          t == 0 ? const Color(0xFF1A237E) : const Color(0xFF00695C),
          const Color(0xFFFFE082),
          phase: time * 1.8 + t,
        );
      }

      canvas.restore();
    }
  }

  void _drawCactusForestAndDesertProps(
    Canvas canvas,
    Size size,
    double horizonY,
  ) {
    final double groundHeight = size.height - horizonY;

    // 28 Large Saguaro, Prickly Pear & Agave Cacti (1.3x..1.72x scale) strictly in upper/mid ring (yFactor: 0.09 .. 0.19)
    for (int i = 0; i < 28; i++) {
      final double deg = (i * 12.85 + 8.0) % 360.0;
      final double? cx = _worldAngleToScreenX(deg, size, margin: 220);
      if (cx == null) continue;

      final double yFactor = 0.09 + (i % 5) * 0.025; // 0.09 .. 0.19
      final double cy = horizonY + groundHeight * yFactor;
      final double scale = 1.30 + (i % 4) * 0.14; // 1.30x .. 1.72x

      canvas.save();
      canvas.translate(cx, cy);
      canvas.scale(scale);

      // Ground shadow
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(4, 2), width: 24, height: 6),
        Paint()..color = Colors.black.withValues(alpha: 0.24),
      );

      final int type = i % 3;
      if (type == 0) {
        // Tall Saguaro Cactus with arms
        final Paint sagPaint = Paint()..color = const Color(0xFF2E7D32);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-4.5, -38, 9, 40),
            const Radius.circular(4.5),
          ),
          sagPaint,
        );
        // Left arm
        final Path leftArm = Path()
          ..moveTo(-4, -20)
          ..quadraticBezierTo(-14, -20, -14, -30)
          ..lineTo(-14, -34);
        canvas.drawPath(
          leftArm,
          Paint()
            ..color = const Color(0xFF2E7D32)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5.5
            ..strokeCap = StrokeCap.round,
        );
        // Right arm
        final Path rightArm = Path()
          ..moveTo(4, -15)
          ..quadraticBezierTo(14, -15, 14, -25)
          ..lineTo(14, -30);
        canvas.drawPath(
          rightArm,
          Paint()
            ..color = const Color(0xFF388E3C)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5.2
            ..strokeCap = StrokeCap.round,
        );
        // Desert flower on crown
        canvas.drawCircle(
          const Offset(0, -39),
          2.6,
          Paint()..color = const Color(0xFFFF4081),
        );
      } else if (type == 1) {
        // Prickly Pear (Opuntia) paddle cactus with magenta blooms
        final List<Offset> pads = [
          const Offset(0, -8),
          const Offset(-7, -16),
          const Offset(6, -15),
          const Offset(-2, -23),
        ];
        for (final Offset p in pads) {
          canvas.drawOval(
            Rect.fromCenter(center: p, width: 10, height: 13),
            Paint()..color = const Color(0xFF43A047),
          );
          canvas.drawCircle(
            Offset(p.dx, p.dy - 7),
            2.0,
            Paint()..color = const Color(0xFFE91E63),
          );
        }
      } else {
        // Spiky Blue-Green Desert Agave rosette
        for (int leaf = -3; leaf <= 3; leaf++) {
          final double a = leaf * 0.34;
          final Path blade = Path()
            ..moveTo(0, 0)
            ..quadraticBezierTo(
              math.sin(a) * 10,
              -10,
              math.sin(a) * 16,
              -18 + leaf.abs() * 2.0,
            )
            ..quadraticBezierTo(math.sin(a) * 6, -6, 0, 0);
          canvas.drawPath(
            blade,
            Paint()
              ..color = leaf.isEven
                  ? const Color(0xFF26A69A)
                  : const Color(0xFF00897B),
          );
        }
      }

      canvas.restore();
    }

    // Rolling animated tumbleweeds blowing across the foreground desert sand (yFactor: 0.48 .. 0.68)
    for (int t = 0; t < 6; t++) {
      final double deg = (t * 60.0 + time * 9.5) % 360.0;
      final double? x = _worldAngleToScreenX(deg, size, margin: 120);
      if (x == null) continue;
      if ((x - size.width * 0.5).abs() < 140) continue;

      final double yFactor = 0.48 + (t % 3) * 0.10;
      final double bounce = (math.sin(time * 6.5 + t * 1.7).abs()) * 14.0;
      final double ty = horizonY + groundHeight * yFactor - bounce;

      canvas.save();
      canvas.translate(x, ty);
      canvas.rotate(time * 4.5 + t);
      final Paint twPaint = Paint()
        ..color = const Color(0xFF8D6E63)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 22, height: 18),
        twPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 16, height: 22),
        twPaint,
      );
      canvas.restore();
    }

    // Bleached desert cow/camel skulls, red sandstone boulders & darting lizards (yFactor: 0.54 .. 0.76)
    final List<double> propAngles = [28.0, 95.0, 188.0, 272.0, 318.0];
    for (int p = 0; p < propAngles.length; p++) {
      final double? x = _worldAngleToScreenX(propAngles[p], size, margin: 160);
      if (x == null) continue;
      if ((x - size.width * 0.5).abs() < 140) continue;

      final double yFactor = 0.54 + (p % 3) * 0.11;
      final double py = horizonY + groundHeight * yFactor;

      canvas.save();
      canvas.translate(x, py);
      canvas.scale(1.55);

      // Red desert boulder
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(-16, -4), width: 26, height: 14),
        Paint()..color = const Color(0xFF9C3D26),
      );

      // Bleached skull with curved horns
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(8, -2), width: 11, height: 7),
        Paint()..color = const Color(0xFFF5F5DC),
      );
      canvas.drawArc(
        const Rect.fromLTWH(0, -9, 16, 10),
        math.pi * 1.1,
        math.pi * 0.8,
        false,
        Paint()
          ..color = const Color(0xFFD7CCC8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );

      // Desert lizard sunning on the rock
      final double lizardScuttle = math.sin(time * 3.5 + p) * 2.0;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(-16 + lizardScuttle, -11),
          width: 9,
          height: 3.2,
        ),
        Paint()..color = const Color(0xFF689F38),
      );

      canvas.restore();
    }
  }

  void _drawCenterCactus(Canvas canvas, Size size, double horizonY) {
    final double cx = size.width * 0.5;
    final double cy = size.height * 0.865;
    final double baseScale =
        (math.min(size.width, size.height) / 920.0).clamp(0.76, 0.98) *
        (1.0 + coconutPulse * 0.08) *
        (0.9 + 0.1 * cameraZoom);
    final double armSway = math.sin(time * 2.1) * 0.045;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(baseScale);

    // 1. Lo-Fi Neon Sunset Aura behind the cactus when in Lo-Fi style
    if (styleMode == CoconutStyleMode.lofi) {
      canvas.drawCircle(
        const Offset(0, -82),
        125,
        Paint()
          ..shader = ui.Gradient.radial(
            const Offset(0, -82),
            125,
            [
              const Color(0xFFFF4081).withValues(alpha: 0.34),
              const Color(0xFF00E5FF).withValues(alpha: 0.18),
              Colors.transparent,
            ],
            [0.0, 0.55, 1.0],
          ),
      );
    }

    // 2. Soft Directional Radial Gradient Shadow on the Desert Sand (rotating with -cameraYaw away from sun at 0°)
    final double sunRelativeRad = (-cameraYaw) * math.pi / 180.0;
    final double shadowOffsetX = -math.sin(sunRelativeRad) * 34.0;
    final double shadowOffsetY = 8.0 + math.cos(sunRelativeRad) * 9.0;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(shadowOffsetX, shadowOffsetY),
        width: 196,
        height: 44,
      ),
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(shadowOffsetX, shadowOffsetY),
          98,
          [
            const Color(0xFF3E1F14).withValues(alpha: 0.56),
            const Color(0xFF5D3222).withValues(alpha: 0.22),
            Colors.transparent,
          ],
          [0.0, 0.62, 1.0],
        ),
    );

    // 3. Left & Right Expressive Swaying Cactus Arms with 100% Accurate Spine Geometry
    for (final int dir in [-1, 1]) {
      canvas.save();
      final double attachY = dir < 0 ? -74.0 : -62.0;
      canvas.translate(dir * 25.0, attachY);
      canvas.rotate(dir * armSway);

      final Path armPath = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(dir * 40.0, 0, dir * 42.0, -28.0)
        ..lineTo(dir * 42.0, -58.0);

      // Arm shadow stroke + 3D green arm body (radius = 15px outer, 12px inner)
      canvas.drawPath(
        armPath,
        Paint()
          ..color = const Color(0xFF1B5E20)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 30.0
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawPath(
        armPath,
        Paint()
          ..color = const Color(0xFF388E3C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 24.0
          ..strokeCap = StrokeCap.round,
      );
      // Inner sunlit rib highlight on the arm
      canvas.drawPath(
        armPath,
        Paint()
          ..color = const Color(0xFF81C784).withValues(alpha: 0.65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7.0
          ..strokeCap = StrokeCap.round,
      );

      // Accurately attached golden spines ONLY along the vertical upper arm (sy = -28..-56)
      // where the arm center is at x = dir * 42.0 (outer edge dir * 56.0, inner edge dir * 28.0)
      final Paint spinePaint = Paint()
        ..color = const Color(0xFFFFF59D)
        ..strokeWidth = 1.25
        ..strokeCap = StrokeCap.round;
      for (int s = 0; s < 4; s++) {
        final double sy = -28.0 - s * 9.5;
        // Outer arm edge spine
        canvas.drawLine(
          Offset(dir * 56.0, sy),
          Offset(dir * 62.0, sy - 2.5),
          spinePaint,
        );
        // Inner arm edge spine
        canvas.drawLine(
          Offset(dir * 28.0, sy),
          Offset(dir * 22.0, sy - 2.5),
          spinePaint,
        );
      }
      // Spines along the lower curved horizontal elbow
      canvas.drawLine(
        Offset(dir * 22.0, 13.0),
        Offset(dir * 25.0, 18.0),
        spinePaint,
      );
      canvas.drawLine(
        Offset(dir * 38.0, 6.0),
        Offset(dir * 43.0, 11.0),
        spinePaint,
      );
      canvas.drawLine(
        Offset(dir * 51.0, -12.0),
        Offset(dir * 57.0, -10.0),
        spinePaint,
      );

      canvas.restore();
    }

    // 3b. 3rd Smaller Upper-Right Cactus Arm Bud (attached at x = 23, y = -108)
    canvas.save();
    canvas.translate(23.0, -108.0);
    canvas.rotate(armSway * 0.8);
    final Path budPath = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(22.0, 0, 24.0, -14.0)
      ..lineTo(24.0, -30.0);
    canvas.drawPath(
      budPath,
      Paint()
        ..color = const Color(0xFF1B5E20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20.0
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      budPath,
      Paint()
        ..color = const Color(0xFF43A047)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 15.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      budPath,
      Paint()
        ..color = const Color(0xFFA5D6A7).withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round,
    );
    // Attached spines along the vertical upper section of the 3rd arm bud (x = 24, radius = 10)
    final Paint budSpinePaint = Paint()
      ..color = const Color(0xFFFFF59D)
      ..strokeWidth = 1.1;
    for (final double bsy in [-16.0, -23.0, -30.0]) {
      canvas.drawLine(Offset(33.0, bsy), Offset(38.0, bsy - 2.2), budSpinePaint);
      canvas.drawLine(Offset(15.0, bsy), Offset(10.5, bsy - 2.2), budSpinePaint);
    }
    // Small pink desert flower bud on the 3rd arm tip
    canvas.drawCircle(
      const Offset(24.0, -40.0),
      4.2,
      Paint()..color = const Color(0xFFFF80AB),
    );
    canvas.drawCircle(
      const Offset(24.0, -40.0),
      2.0,
      Paint()..color = const Color(0xFFFFEB3B),
    );
    canvas.restore();

    // 4. Main Center Saguaro Trunk with 3D Vertical Ribs & Fine Spines (trunk top at y = -152)
    final RRect trunkRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-34, -152, 68, 160),
      const Radius.circular(34),
    );
    canvas.drawRRect(
      trunkRect,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(-34, -80),
          const Offset(34, -80),
          [
            const Color(0xFF66BB6A),
            const Color(0xFF2E7D32),
            const Color(0xFF1B5E20),
          ],
          [0.0, 0.55, 1.0],
        ),
    );

    // 3D Vertical Ribs along the trunk
    for (int r = -2; r <= 2; r++) {
      final double rx = r * 11.8;
      canvas.drawLine(
        Offset(rx, -140 + r.abs() * 5.0),
        Offset(rx, 5),
        Paint()
          ..color = r <= 0
              ? const Color(0xFFA5D6A7).withValues(alpha: 0.55)
              : const Color(0xFF0D3B10).withValues(alpha: 0.45)
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );

      // Fine spine clusters along each vertical rib
      for (int sp = 0; sp < 7; sp++) {
        final double spy = -130.0 + sp * 19.0 + (r.isEven ? 0.0 : 7.0);
        final Paint spPaint = Paint()
          ..color = const Color(0xFFFFF9C4).withValues(alpha: 0.82)
          ..strokeWidth = 1.15;
        canvas.drawLine(Offset(rx, spy), Offset(rx - 4.2, spy - 2.8), spPaint);
        canvas.drawLine(Offset(rx, spy), Offset(rx + 4.2, spy - 2.8), spPaint);
      }
    }

    // 4b. Blooming Golden Barrel Cactus at (-42, -4) & Prickly Pear Cluster at (40, -6)
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-42, -4), width: 30, height: 28),
      Paint()
        ..shader = ui.Gradient.radial(
          const Offset(-46, -8),
          18,
          [const Color(0xFF81C784), const Color(0xFF2E7D32)],
        ),
    );
    for (int br = -2; br <= 2; br++) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(-42.0 + br * 3.5, -4),
          width: 10,
          height: 26,
        ),
        -math.pi * 0.5,
        math.pi,
        false,
        Paint()
          ..color = const Color(0xFFFFF59D).withValues(alpha: 0.65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1,
      );
    }
    // Golden crown blossom on the Barrel Cactus
    canvas.drawCircle(
      const Offset(-42, -18),
      5.0,
      Paint()..color = const Color(0xFFFFCA28),
    );
    canvas.drawCircle(
      const Offset(-42, -18),
      2.4,
      Paint()..color = const Color(0xFFFF6F00),
    );

    // Prickly Pear Paddle Cluster with Magenta Blooms nestled at (40, -6)
    for (final List<double> pad in [
      [40.0, -6.0, 18.0, 22.0],
      [51.0, -16.0, 14.0, 18.0],
      [34.0, -19.0, 13.0, 16.0],
    ]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(pad[0], pad[1]),
          width: pad[2],
          height: pad[3],
        ),
        Paint()..color = const Color(0xFF43A047),
      );
      canvas.drawCircle(
        Offset(pad[0], pad[1] - pad[3] * 0.52),
        3.2,
        Paint()..color = const Color(0xFFFF4081),
      );
    }

    // 4c. Organic Wind-Sculpted Sand Dune Ripple Nest (sandNest) tucking the Saguaro & side cacti directly into the continuous desert ground!
    final Color nestTopColor = switch (atmosphereMode) {
      CoconutAtmosphereMode.sunset => const Color(0xFFE07A47),
      CoconutAtmosphereMode.night => const Color(0xFF1E2640),
      CoconutAtmosphereMode.noon => const Color(0xFFD99B52),
      CoconutAtmosphereMode.rain => const Color(0xFF5E4B46),
    };
    final Color nestBaseColor = switch (atmosphereMode) {
      CoconutAtmosphereMode.sunset => const Color(0xFFC95B32),
      CoconutAtmosphereMode.night => const Color(0xFF151022),
      CoconutAtmosphereMode.noon => const Color(0xFFC98A42),
      CoconutAtmosphereMode.rain => const Color(0xFF4A3A36),
    };

    final Path sandNest = Path()
      ..moveTo(-88, 12)
      ..quadraticBezierTo(-56, -2, -26, 4)
      ..quadraticBezierTo(0, -3, 26, 4)
      ..quadraticBezierTo(56, -2, 88, 12)
      ..quadraticBezierTo(0, 24, -88, 12)
      ..close();
    canvas.drawPath(
      sandNest,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, -3),
          const Offset(0, 22),
          [nestTopColor, nestBaseColor],
        ),
    );

    // Wind-blown sand ripples & small red sandstone pebbles on the sandNest
    final Paint nestRipplePaint = Paint()
      ..color = const Color(0xFFFFE0B2).withValues(
        alpha: atmosphereMode == CoconutAtmosphereMode.night ? 0.14 : 0.34,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final Path ripple1 = Path()
      ..moveTo(-64, 8)
      ..quadraticBezierTo(-22, 2, 18, 7)
      ..quadraticBezierTo(44, 10, 68, 6);
    final Path ripple2 = Path()
      ..moveTo(-46, 14)
      ..quadraticBezierTo(0, 9, 48, 15);
    canvas.drawPath(ripple1, nestRipplePaint);
    canvas.drawPath(ripple2, nestRipplePaint);

    // Small red sandstone pebbles nestled in the sand
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-56, 9), width: 18, height: 8),
      Paint()..color = const Color(0xFF8D3B24),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-24, 11), width: 9, height: 4.5),
      Paint()..color = const Color(0xFFA14A2E),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(48, 10), width: 15, height: 7),
      Paint()..color = const Color(0xFF9C3D26),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(28, 13), width: 8, height: 4),
      Paint()..color = const Color(0xFF8D3B24),
    );

    // 4d. Animated Desert Horned Lizard / Gecko Basking at (-56, 6)
    final double geckoBob = math.sin(time * 3.8) * 1.4;
    canvas.save();
    canvas.translate(-56.0, 6.0);
    // Curving gecko tail
    final Path geckoTail = Path()
      ..moveTo(-6, 1)
      ..quadraticBezierTo(-15, -2 + geckoBob, -19, 3);
    canvas.drawPath(
      geckoTail,
      Paint()
        ..color = const Color(0xFFD4A359)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
    // Little legs
    final Paint geckoLegPaint = Paint()
      ..color = const Color(0xFFB8863B)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(-3, 1), const Offset(-5, 5), geckoLegPaint);
    canvas.drawLine(const Offset(4, 1), const Offset(6, 5), geckoLegPaint);
    // Patterned body
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 0), width: 14, height: 6.5),
      Paint()..color = const Color(0xFFE6B86A),
    );
    // Head & cute horned crown bobbing in the sun
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(8.0, -2.0 + geckoBob * 0.6),
        width: 7.5,
        height: 5.2,
      ),
      Paint()..color = const Color(0xFFE6B86A),
    );
    canvas.drawCircle(
      Offset(9.5, -2.8 + geckoBob * 0.6),
      1.0,
      Paint()..color = const Color(0xFF212121),
    );
    canvas.restore();

    // 5. Style-Specific Accessories on the Hero Saguaro Cactus
    switch (styleMode) {
      case CoconutStyleMode.natural:
        _drawNaturalBloomingFlower(canvas, const Offset(0, -154));
        break;
      case CoconutStyleMode.arcade:
        _drawSheriffCowboyAccessories(canvas);
        break;
      case CoconutStyleMode.cocktail:
        _drawMariachiFiestaAccessories(canvas);
        break;
      case CoconutStyleMode.king:
        _drawOasisEmperorAccessories(canvas);
        break;
      case CoconutStyleMode.lofi:
        _drawLofiMirageAccessories(canvas);
        break;
    }

    canvas.restore();
  }

  void _drawNaturalBloomingFlower(Canvas canvas, Offset pos) {
    for (int p = 0; p < 8; p++) {
      final double angle = (p / 8.0) * math.pi * 2.0 + time * 0.3;
      final Offset petal = Offset(
        pos.dx + math.cos(angle) * 11.0,
        pos.dy + math.sin(angle) * 7.0,
      );
      canvas.drawCircle(petal, 6.5, Paint()..color = const Color(0xFFFF4081));
    }
    canvas.drawCircle(pos, 6.0, Paint()..color = const Color(0xFFFFD54F));
  }

  void _drawSheriffCowboyAccessories(Canvas canvas) {
    // Western Leather Cowboy Hat on the crown
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -148), width: 108, height: 22),
      Paint()..color = const Color(0xFF6D4C41),
    );
    final Path hatCrown = Path()
      ..moveTo(-32, -148)
      ..quadraticBezierTo(-26, -186, -10, -178)
      ..quadraticBezierTo(0, -172, 10, -178)
      ..quadraticBezierTo(26, -186, 32, -148)
      ..close();
    canvas.drawPath(hatCrown, Paint()..color = const Color(0xFF8D6E63));
    canvas.drawRect(
      const Rect.fromLTWH(-30, -154, 60, 6),
      Paint()..color = const Color(0xFF3E2723),
    );

    // Cool Aviator Sunglasses
    final Paint framePaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    for (final double lx in [-14.0, 14.0]) {
      final RRect lens = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(lx, -116), width: 22, height: 16),
        const Radius.circular(6),
      );
      canvas.drawRRect(lens, Paint()..color = const Color(0xFF102027));
      canvas.drawRRect(lens, framePaint);
    }
    canvas.drawLine(const Offset(-3, -118), const Offset(3, -118), framePaint);

    // Red Paisley Bandana around the neck
    final Path bandana = Path()
      ..moveTo(-34, -88)
      ..quadraticBezierTo(0, -78, 34, -88)
      ..lineTo(0, -58)
      ..close();
    canvas.drawPath(bandana, Paint()..color = const Color(0xFFD32F2F));

    // Golden 6-Pointed Sheriff Star Badge on chest
    final Offset badge = const Offset(16, -98);
    final Path star = Path();
    for (int i = 0; i < 12; i++) {
      final double r = i.isEven ? 10.0 : 4.6;
      final double a = (i / 12.0) * math.pi * 2.0 - math.pi * 0.5;
      final Offset pt = Offset(
        badge.dx + math.cos(a) * r,
        badge.dy + math.sin(a) * r,
      );
      if (i == 0) {
        star.moveTo(pt.dx, pt.dy);
      } else {
        star.lineTo(pt.dx, pt.dy);
      }
    }
    star.close();
    canvas.drawPath(star, Paint()..color = const Color(0xFFFFD54F));
  }

  void _drawMariachiFiestaAccessories(Canvas canvas) {
    // Colorful Embroidered Mexican Sombrero
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -148), width: 132, height: 28),
      Paint()..color = const Color(0xFFFFCA28),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -148), width: 118, height: 20),
      Paint()
        ..color = const Color(0xFFD81B60)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );
    final Path cone = Path()
      ..moveTo(-26, -150)
      ..quadraticBezierTo(0, -200, 26, -150)
      ..close();
    canvas.drawPath(cone, Paint()..color = const Color(0xFFFFB300));

    // Festive Poncho Stripes across chest
    final List<Color> ponchoColors = [
      const Color(0xFFE53935),
      const Color(0xFFFFEB3B),
      const Color(0xFF00ACC1),
      const Color(0xFF8E24AA),
    ];
    for (int s = 0; s < ponchoColors.length; s++) {
      canvas.drawRect(
        Rect.fromLTWH(-33, -94.0 + s * 6.5, 66, 5.0),
        Paint()..color = ponchoColors[s],
      );
    }

    // Miniature Acoustic Guitar & Maraca
    canvas.save();
    canvas.translate(-20, -58);
    canvas.rotate(-0.35);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 8), width: 24, height: 20),
      Paint()..color = const Color(0xFFD84315),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -5), width: 18, height: 15),
      Paint()..color = const Color(0xFFE64A19),
    );
    canvas.drawCircle(
      const Offset(0, 1),
      4.2,
      Paint()..color = const Color(0xFF3E2723),
    );
    canvas.drawRect(
      const Rect.fromLTWH(-2.2, -26, 4.4, 16),
      Paint()..color = const Color(0xFF5D4037),
    );
    canvas.restore();
  }

  void _drawOasisEmperorAccessories(Canvas canvas) {
    // Gleaming Pharaoh / Sultan Golden Crown with Turquoise & Ruby Jewels
    final Path crown = Path()
      ..moveTo(-28, -148)
      ..lineTo(-32, -178)
      ..lineTo(-15, -163)
      ..lineTo(0, -184)
      ..lineTo(15, -163)
      ..lineTo(32, -178)
      ..lineTo(28, -148)
      ..close();
    canvas.drawPath(
      crown,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(-28, -184),
          const Offset(28, -148),
          [const Color(0xFFFFF176), const Color(0xFFFF8F00)],
        ),
    );
    canvas.drawCircle(
      const Offset(0, -161),
      4.8,
      Paint()..color = const Color(0xFF00E5FF),
    );
    canvas.drawCircle(
      const Offset(-15, -156),
      3.6,
      Paint()..color = const Color(0xFFE91E63),
    );
    canvas.drawCircle(
      const Offset(15, -156),
      3.6,
      Paint()..color = const Color(0xFFE91E63),
    );

    // Blooming magenta flowers on both arms
    _drawNaturalBloomingFlower(canvas, const Offset(-67, -134));
    _drawNaturalBloomingFlower(canvas, const Offset(67, -122));

    // Hovering Emerald Hummingbird sipping nectar near the crown
    final Offset hb = Offset(
      52.0 + math.sin(time * 4.2) * 6.0,
      -162.0 + math.cos(time * 5.4) * 5.0,
    );
    canvas.drawOval(
      Rect.fromCenter(center: hb, width: 14, height: 7),
      Paint()..color = const Color(0xFF00BFA5),
    );
    canvas.drawLine(
      Offset(hb.dx - 7, hb.dy),
      Offset(hb.dx - 18, hb.dy + 2),
      Paint()
        ..color = const Color(0xFF263238)
        ..strokeWidth = 1.4,
    );
    final double wingBlur = math.sin(time * 24.0) * 8.0;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(hb.dx + 2, hb.dy - 6 + wingBlur * 0.3),
        width: 12,
        height: 6,
      ),
      Paint()..color = const Color(0xFF80CBC4).withValues(alpha: 0.75),
    );
  }

  void _drawLofiMirageAccessories(Canvas canvas) {
    // Giant Retro Headphones arching over the cactus crown & ear cups
    canvas.drawArc(
      Rect.fromCenter(
        center: const Offset(0, -118),
        width: 86,
        height: 90,
      ),
      math.pi * 1.02,
      math.pi * 0.96,
      false,
      Paint()
        ..color = const Color(0xFF263238)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7.0
        ..strokeCap = StrokeCap.round,
    );
    for (final int dir in [-1, 1]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(dir * 39.0, -114.0),
            width: 15,
            height: 32,
          ),
          const Radius.circular(8),
        ),
        Paint()..color = const Color(0xFFFF4081),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(dir * 35.0, -114.0),
            width: 6.5,
            height: 26,
          ),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xFF00E5FF),
      );
    }

    // Floating synthwave musical notes
    for (int n = 0; n < 3; n++) {
      final double p = (time * 0.45 + n * 0.33) % 1.0;
      final double nx =
          (n.isEven ? 1 : -1) * (50.0 + math.sin(time * 2.5 + n) * 10.0);
      final double ny = -128.0 - p * 58.0;
      final double alpha = math.sin(p * math.pi).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(nx, ny),
        3.6,
        Paint()
          ..color = const Color(0xFF80DEEA).withValues(alpha: alpha * 0.9),
      );
      canvas.drawLine(
        Offset(nx + 3, ny),
        Offset(nx + 3, ny - 10),
        Paint()
          ..color = const Color(0xFF80DEEA).withValues(alpha: alpha * 0.9)
          ..strokeWidth = 2.0,
      );
    }
  }

  void _drawAtmosphericOverlay(Canvas canvas, Size size, double horizonY) {
    // 1. Rare Desert Monsoon Rain & Blooming Desert Sparkles in Rain Mode
    if (atmosphereMode == CoconutAtmosphereMode.rain) {
      final Paint rainPaint = Paint()
        ..color = const Color(0xFFB0BEC5).withValues(alpha: 0.40)
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < 65; i++) {
        final double rx =
            ((i * 73.0 + time * 180.0) % (size.width + 100.0)) - 50.0;
        final double ry = (i * 47.0 + time * 520.0) % size.height;
        canvas.drawLine(Offset(rx, ry), Offset(rx - 7.0, ry + 22.0), rainPaint);
      }

      // Blooming desert rain sparkles on the ground
      for (int s = 0; s < 18; s++) {
        final double sx = ((s * 61.0) % size.width);
        final double sy =
            horizonY + ((s * 37.0) % (size.height - horizonY));
        final double pulse = 0.5 + 0.5 * math.sin(time * 3.5 + s);
        canvas.drawCircle(
          Offset(sx, sy),
          2.2 * pulse,
          Paint()
            ..color = const Color(0xFFFF80AB).withValues(alpha: 0.65 * pulse),
        );
      }
    }

    // 2. Glowing Fireflies & Desert Stardust in Night Mode
    if (atmosphereMode == CoconutAtmosphereMode.night) {
      for (int f = 0; f < 22; f++) {
        final double fx =
            ((f * 83.0 + math.sin(time * 0.9 + f) * 26.0) % size.width);
        final double fy =
            horizonY * 0.65 + ((f * 53.0 + time * 12.0) % (size.height * 0.55));
        final double glow = 0.4 + 0.6 * math.sin(time * 2.8 + f * 1.3);
        canvas.drawCircle(
          Offset(fx, fy),
          2.6,
          Paint()
            ..color = const Color(0xFFFFEA00).withValues(alpha: 0.70 * glow),
        );
      }
    }

    // 3. Desert Heat Shimmer & Warm Sun Lens Flare in Noon / Sunset Mode
    final double sunFocus = _angleWeight(cameraYaw, 0.0, 48.0);
    if (sunFocus > 0.01 &&
        (atmosphereMode == CoconutAtmosphereMode.sunset ||
            atmosphereMode == CoconutAtmosphereMode.noon)) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(size.width * 0.5, horizonY),
            size.width * 0.55,
            [
              const Color(0xFFFFCC80).withValues(alpha: 0.17 * sunFocus),
              Colors.transparent,
            ],
          ),
      );
    }

    // 4. Warm Retro Vignette (enhanced in Lo-Fi mode)
    final Color vignetteEdge = styleMode == CoconutStyleMode.lofi
        ? const Color(0xFF2A0845).withValues(alpha: 0.44)
        : Colors.black.withValues(alpha: 0.36);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(size.width * 0.5, size.height * 0.5),
          math.max(size.width, size.height) * 0.75,
          [Colors.transparent, vignetteEdge],
          [0.65, 1.0],
        ),
    );
  }

  @override
  bool shouldRepaint(covariant DesertCactusWorldPainter oldDelegate) {
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
