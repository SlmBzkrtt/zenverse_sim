// ignore_for_file: prefer_initializing_formals
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../controllers/zenverse_controller.dart';
import 'coconut_world_painter.dart';

class ZenValleyWorldPainter extends CustomPainter {
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

  ZenValleyWorldPainter({
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

    // 1. Sky, Mount Fuji, Crimson Sun/Moon, United Volumetric Clouds & Cranes
    _drawSkyAndStars(canvas, size, horizonY);
    _drawCrimsonSunOrMoon(canvas, size, horizonY);
    _drawMountFujiAndDistantPeaks(canvas, size, horizonY);
    _drawUnitedClouds(canvas, size, horizonY);
    _drawRedCrownedCranes(canvas, size, horizonY);

    // 2. Valley Ground, Inland Zen Hills, Mirror Koi Pond (-78°..+78°), Kyoto Terraces & Mountain Stream (78°..282°)
    _drawValleyGroundAndMirrorPond(canvas, size, horizonY);

    // 3. 0° Zone — Floating Lake Torii (-12°), Golden Pavilion Kinkaku-ji (+38°), 16 Koi Fish, Lotus Pads & 2 Yakatabune Boats
    _drawItsukushimaFloatingToriiAndKinkakuJi(canvas, size, horizonY);
    _drawLotusPadsAndKoiFish(canvas, size, horizonY);
    _drawYakatabuneBoatsAndToroNagashi(canvas, size, horizonY);

    // 4. 220° Zone — Twin Waterfalls, 14 Fushimi Inari Torii Gates, Jizo Statues, Bronze Buddha, Bonsho & 38 Bamboo/Sakura/Momiji
    _drawBambooGroveAndSakuraMomijiTrees(canvas, size, horizonY);
    _drawWaterfallsBuddhaAndToriiPath(canvas, size, horizonY);

    // 5. 72° Zone — High Vermilion Arched Temple Bridge (Taiko-bashi, 72°) & Blooming Wisteria Pergola Tunnel (Fuji-dana, 94°)
    _drawTaikoBashiBridgeZone(canvas, size, horizonY);

    // 6. 126° Zone — Five-Story Pagoda (116°), Karesansui Courtyard with Raking Monk (130°), Chashitsu Tea House (136°), Shishi-odoshi (149°) & Ema Rack (155°)
    _drawPagodaAndTeaHouseZone(canvas, size, horizonY);

    // 7. 166° Zone — Cliffside Steaming Volcanic Rock Onsen & Traditional Ryokan Bathhouse (166°), Guests, Shamisen, Capybara & 2 Snow Monkeys
    _drawSteamingOnsenZone(canvas, size, horizonY);

    // 8. Foreground Shore Stones, Moss Cushions & 80 Drifting Pink Sakura Petals
    _drawForegroundShoreDetails(canvas, size, horizonY);
    _drawDriftingSakuraPetals(canvas, size, horizonY);

    // 9. Center Foreground Object — Sacred Japanese Iwakura / Suiseki Multi-Boulder Mossy Zen Rock
    _drawCenterMossyRock(canvas, size, horizonY);

    // 10. Weather & Atmospheric Overlays (Rain, Night Fireflies, Noon Sunbeams, Lo-Fi Vignette)
    _drawAtmosphericOverlays(canvas, size, horizonY);
  }

  // ===========================================================================
  // 1. SKY, STARS, MOUNT FUJI, CRIMSON SUN/MOON, CLOUDS & CRANES
  // ===========================================================================

  void _drawSkyAndStars(Canvas canvas, Size size, double horizonY) {
    final Rect skyRect = Rect.fromLTWH(
      0,
      0,
      size.width,
      math.max(horizonY + 25, size.height * 0.65),
    );
    final double sunWeight = _angleWeight(cameraYaw, 0.0, 125.0);

    List<Color> skyColors;
    const List<double> stops = [0.0, 0.35, 0.70, 1.0];

    switch (atmosphereMode) {
      case CoconutAtmosphereMode.night:
        skyColors = [
          const Color(0xFF050818),
          const Color(0xFF0E1838),
          const Color(0xFF1A2855),
          const Color(0xFF283568),
        ];
        break;
      case CoconutAtmosphereMode.noon:
        skyColors = [
          const Color(0xFF1B6CA8),
          const Color(0xFF3E95C8),
          const Color(0xFF7CC8E3),
          const Color(0xFFD7F4EC),
        ];
        break;
      case CoconutAtmosphereMode.rain:
        skyColors = [
          const Color(0xFF232B38),
          const Color(0xFF374352),
          const Color(0xFF536373),
          const Color(0xFF7B8B97),
        ];
        break;
      case CoconutAtmosphereMode.sunset:
        skyColors = [
          Color.lerp(
            const Color(0xFF1B1035),
            const Color(0xFF2D123E),
            sunWeight,
          )!,
          Color.lerp(
            const Color(0xFF561D4E),
            const Color(0xFF8C2444),
            sunWeight,
          )!,
          Color.lerp(
            const Color(0xFFA8384B),
            const Color(0xFFD94E3B),
            sunWeight,
          )!,
          Color.lerp(
            const Color(0xFFE88D5A),
            const Color(0xFFFFB85C),
            sunWeight,
          )!,
        ];
        break;
    }

    canvas.drawRect(
      skyRect,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 0),
          Offset(0, horizonY),
          skyColors,
          stops,
        ),
    );

    if (atmosphereMode == CoconutAtmosphereMode.night ||
        atmosphereMode == CoconutAtmosphereMode.sunset) {
      final double baseAlpha = atmosphereMode == CoconutAtmosphereMode.night
          ? 0.90
          : 0.35;
      final Paint starPaint = Paint()..style = PaintingStyle.fill;
      for (int i = 0; i < 95; i++) {
        final double starDeg = (i * 37.3 + 11.0) % 360.0;
        final double? sx = _worldAngleToScreenX(starDeg, size, margin: 40);
        if (sx == null) continue;
        final double yFrac = 0.04 + ((i * 53) % 100) / 100.0 * 0.62;
        final double sy = horizonY * yFrac;
        if (sy <= 0 || sy >= horizonY - 12) continue;

        final double twinkle =
            0.45 + 0.55 * math.sin(time * (1.7 + (i % 5) * 0.4) + i);
        starPaint.color = Colors.white.withValues(
          alpha: (baseAlpha * twinkle * (1.0 - yFrac * 0.55)).clamp(0.0, 1.0),
        );
        final double r = (i % 6 == 0) ? 1.8 : 1.1;
        canvas.drawCircle(Offset(sx, sy), r, starPaint);
      }
    }
  }

  void _drawCrimsonSunOrMoon(Canvas canvas, Size size, double horizonY) {
    final double? cx = _worldAngleToScreenX(0.0, size, margin: 480);
    if (cx == null) return;

    final double cy = horizonY - size.height * 0.165;
    final double baseRadius = size.shortestSide * 0.165;

    if (atmosphereMode == CoconutAtmosphereMode.night) {
      for (int i = 3; i >= 1; i--) {
        canvas.drawCircle(
          Offset(cx, cy),
          baseRadius * (1.0 + i * 0.45),
          Paint()
            ..color = const Color(0xFFB5D2FF).withValues(alpha: 0.08 / i)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
        );
      }
      canvas.drawCircle(
        Offset(cx, cy),
        baseRadius * 0.92,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(cx - baseRadius * 0.2, cy - baseRadius * 0.2),
            baseRadius * 1.1,
            [
              const Color(0xFFFFFDE8),
              const Color(0xFFE5EEFF),
              const Color(0xFFB8CBE8),
            ],
            const [0.0, 0.7, 1.0],
          ),
      );
      final Paint craterPaint = Paint()
        ..color = const Color(0xFF96AED0).withValues(alpha: 0.22);
      canvas.drawCircle(
        Offset(cx - baseRadius * 0.28, cy - baseRadius * 0.12),
        baseRadius * 0.18,
        craterPaint,
      );
      canvas.drawCircle(
        Offset(cx + baseRadius * 0.22, cy + baseRadius * 0.20),
        baseRadius * 0.14,
        craterPaint,
      );
      return;
    }

    final Color coreColor = atmosphereMode == CoconutAtmosphereMode.noon
        ? const Color(0xFFFFFCE0)
        : (atmosphereMode == CoconutAtmosphereMode.rain
              ? const Color(0xFFD5DCE2).withValues(alpha: 0.45)
              : const Color(0xFFFFE678));
    final Color rimColor = atmosphereMode == CoconutAtmosphereMode.noon
        ? const Color(0xFFFFC952)
        : (atmosphereMode == CoconutAtmosphereMode.rain
              ? const Color(0xFF8C9BA8).withValues(alpha: 0.25)
              : const Color(0xFFE32929));

    for (int i = 4; i >= 1; i--) {
      canvas.drawCircle(
        Offset(cx, cy),
        baseRadius * (1.1 + i * 0.48),
        Paint()
          ..color = rimColor.withValues(alpha: 0.11 / i)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
      );
    }

    canvas.drawCircle(
      Offset(cx, cy),
      baseRadius,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(cx, cy - baseRadius),
          Offset(cx, cy + baseRadius),
          [coreColor, rimColor],
        ),
    );
  }

  void _drawMountFujiAndDistantPeaks(
    Canvas canvas,
    Size size,
    double horizonY,
  ) {
    final Path rangePath = Path()..moveTo(0, horizonY + 5);
    for (double sx = 0; sx <= size.width + 20; sx += 18) {
      final double effectiveFov = 110.0 / cameraZoom.clamp(0.75, 1.5);
      final double worldDeg =
          (cameraYaw + ((sx - size.width * 0.5) / size.width) * effectiveFov) %
          360.0;
      final double rad = worldDeg * math.pi / 180.0;
      final double h =
          38.0 +
          26.0 * math.sin(rad * 3.0 + 0.6) +
          18.0 * math.cos(rad * 7.0 - 0.8) +
          12.0 * math.sin(rad * 13.0);
      rangePath.lineTo(sx, horizonY - h.clamp(16.0, 92.0));
    }
    rangePath.lineTo(size.width, horizonY + 5);
    rangePath.close();

    final Color mountainTint = atmosphereMode == CoconutAtmosphereMode.night
        ? const Color(0xFF101935)
        : (atmosphereMode == CoconutAtmosphereMode.noon
              ? const Color(0xFF4F7D96)
              : (atmosphereMode == CoconutAtmosphereMode.rain
                    ? const Color(0xFF3E4E5E)
                    : const Color(0xFF471F44)));
    canvas.drawPath(rangePath, Paint()..color = mountainTint);

    // Iconic Snow-Capped Mount Fuji at 0° (1.85x scale)
    final double? fujiX = _worldAngleToScreenX(0.0, size, margin: 580);
    if (fujiX != null) {
      canvas.save();
      canvas.translate(fujiX, horizonY + 2);
      canvas.scale(1.85);

      final Path fujiBody = Path()
        ..moveTo(-210, 0)
        ..cubicTo(-135, -18, -75, -76, -34, -142)
        ..lineTo(-16, -145)
        ..lineTo(0, -143)
        ..lineTo(18, -146)
        ..lineTo(34, -142)
        ..cubicTo(75, -76, 135, -18, 210, 0)
        ..close();

      final Color fujiTop = atmosphereMode == CoconutAtmosphereMode.night
          ? const Color(0xFF1A284E)
          : (atmosphereMode == CoconutAtmosphereMode.noon
                ? const Color(0xFF28557A)
                : const Color(0xFF3D1D47));
      final Color fujiBottom = atmosphereMode == CoconutAtmosphereMode.night
          ? const Color(0xFF0E162B)
          : (atmosphereMode == CoconutAtmosphereMode.noon
                ? const Color(0xFF4A7D9B)
                : const Color(0xFF6B2D52));

      canvas.drawPath(
        fujiBody,
        Paint()
          ..shader = ui.Gradient.linear(
            const Offset(0, -146),
            const Offset(0, 0),
            [fujiTop, fujiBottom],
          ),
      );

      final Path snowCap = Path()
        ..moveTo(-34, -142)
        ..lineTo(-16, -145)
        ..lineTo(0, -143)
        ..lineTo(18, -146)
        ..lineTo(34, -142)
        ..cubicTo(48, -118, 60, -96, 68, -82)
        ..lineTo(46, -95)
        ..lineTo(31, -78)
        ..lineTo(15, -96)
        ..lineTo(0, -76)
        ..lineTo(-14, -95)
        ..lineTo(-30, -80)
        ..lineTo(-47, -96)
        ..lineTo(-68, -82)
        ..cubicTo(-60, -96, -48, -118, -34, -142)
        ..close();

      final Color snowHighlight = atmosphereMode == CoconutAtmosphereMode.sunset
          ? const Color(0xFFFFEFE6)
          : (atmosphereMode == CoconutAtmosphereMode.night
                ? const Color(0xFFDCE8FF)
                : Colors.white);
      final Color snowShadow = atmosphereMode == CoconutAtmosphereMode.sunset
          ? const Color(0xFFE5A4B4)
          : const Color(0xFFA7C4DE);

      canvas.drawPath(
        snowCap,
        Paint()
          ..shader = ui.Gradient.linear(
            const Offset(0, -146),
            const Offset(0, -76),
            [snowHighlight, snowShadow],
          ),
      );

      canvas.drawRect(
        const Rect.fromLTWH(-220, -24, 440, 26),
        Paint()
          ..shader = ui.Gradient.linear(
            const Offset(0, -24),
            const Offset(0, 2),
            [
              Colors.white.withValues(alpha: 0.0),
              (atmosphereMode == CoconutAtmosphereMode.sunset
                      ? const Color(0xFFFFB07B)
                      : const Color(0xFFD8F0EC))
                  .withValues(alpha: 0.32),
            ],
          ),
      );
      canvas.restore();
    }
  }

  void _drawUnitedClouds(Canvas canvas, Size size, double horizonY) {
    for (int i = 0; i < 18; i++) {
      final double speed = 0.45 + (i % 4) * 0.18;
      final double worldDeg = (i * 20.0 + time * speed) % 360.0;
      final double? cx = _worldAngleToScreenX(worldDeg, size, margin: 280);
      if (cx == null) continue;

      final double yFrac = 0.12 + (i % 5) * 0.085;
      final double cy = horizonY * yFrac;
      final double scale = 1.15 + (i % 4) * 0.24;

      canvas.save();
      canvas.translate(cx, cy);
      canvas.scale(scale);

      const List<Rect> puffs = [
        Rect.fromLTWH(-68, -10, 56, 26),
        Rect.fromLTWH(-42, -26, 62, 36),
        Rect.fromLTWH(-6, -32, 68, 42),
        Rect.fromLTWH(34, -18, 54, 28),
        Rect.fromLTWH(-52, -4, 120, 22),
      ];

      Path unitedCloud = Path()..addOval(puffs.first);
      for (int p = 1; p < puffs.length; p++) {
        final Path nextOval = Path()..addOval(puffs[p]);
        unitedCloud = Path.combine(PathOperation.union, unitedCloud, nextOval);
      }

      Color cloudTop;
      Color cloudBottom;
      Color rimColor;

      switch (atmosphereMode) {
        case CoconutAtmosphereMode.night:
          cloudTop = const Color(0xFF283A66).withValues(alpha: 0.78);
          cloudBottom = const Color(0xFF131D38).withValues(alpha: 0.85);
          rimColor = const Color(0xFF90B4FF).withValues(alpha: 0.35);
          break;
        case CoconutAtmosphereMode.noon:
          cloudTop = Colors.white.withValues(alpha: 0.92);
          cloudBottom = const Color(0xFFD2E8F2).withValues(alpha: 0.88);
          rimColor = Colors.white;
          break;
        case CoconutAtmosphereMode.rain:
          cloudTop = const Color(0xFF607080).withValues(alpha: 0.88);
          cloudBottom = const Color(0xFF3B4754).withValues(alpha: 0.92);
          rimColor = const Color(0xFF92A4B5).withValues(alpha: 0.35);
          break;
        case CoconutAtmosphereMode.sunset:
          cloudTop = const Color(0xFFFFD19A).withValues(alpha: 0.90);
          cloudBottom = const Color(0xFF98345A).withValues(alpha: 0.86);
          rimColor = const Color(0xFFFFEA9F).withValues(alpha: 0.75);
          break;
      }

      canvas.drawPath(
        unitedCloud,
        Paint()
          ..shader = ui.Gradient.linear(
            const Offset(0, -34),
            const Offset(0, 18),
            [cloudTop, cloudBottom],
          ),
      );

      canvas.drawPath(
        unitedCloud,
        Paint()
          ..color = rimColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );

      canvas.restore();
    }
  }

  void _drawRedCrownedCranes(Canvas canvas, Size size, double horizonY) {
    for (int i = 0; i < 16; i++) {
      final double worldDeg =
          (i * 22.5 + time * (2.2 + (i % 3) * 0.45)) % 360.0;
      final double? sx = _worldAngleToScreenX(worldDeg, size, margin: 160);
      if (sx == null) continue;

      final double sy =
          horizonY * (0.18 + (i % 5) * 0.08) +
          math.sin(time * 2.5 + i) * 8.0;
      final double s = 1.15 + (i % 3) * 0.25;
      final double flap = math.sin(time * 6.2 + i * 0.9);

      canvas.save();
      canvas.translate(sx, sy);
      canvas.scale(s);

      final Paint whitePaint = Paint()
        ..color = const Color(0xFFFDFBF7)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.6;
      final Path bodyPath = Path()
        ..moveTo(-14, 4)
        ..quadraticBezierTo(-2, 0, 14, -3);
      canvas.drawPath(bodyPath, whitePaint);

      canvas.drawLine(
        const Offset(-12, 3),
        const Offset(-24, 7),
        Paint()
          ..color = const Color(0xFF1F242D)
          ..strokeWidth = 1.3,
      );

      final Path wingPath = Path()
        ..moveTo(-2, 0)
        ..quadraticBezierTo(-8, -15 * flap - 6, -18, -20 * flap)
        ..moveTo(2, -1)
        ..quadraticBezierTo(8, -14 * flap - 5, 16, -18 * flap);
      canvas.drawPath(
        wingPath,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );

      canvas.drawCircle(
        const Offset(15, -4),
        2.0,
        Paint()..color = const Color(0xFFE02424),
      );
      canvas.drawLine(
        const Offset(16, -3),
        const Offset(22, -2),
        Paint()
          ..color = const Color(0xFFD69E2E)
          ..strokeWidth = 1.4,
      );

      canvas.restore();
    }
  }

  // ===========================================================================
  // 2. INLAND HILLS, SCULPTED KYOTO TERRACES (78°..282°) & MIRROR POND (-78°..+78°)
  // ===========================================================================

  void _drawInlandZenHillsAndCanopy(
    Canvas canvas,
    Size size,
    double horizonY,
  ) {
    // Richly layered mid-horizon Kyoto mountains & forested hills across all 360° (with lower lakeside banks across -75°..+75°)
    for (int layer = 0; layer < 2; layer++) {
      final Path hillPath = Path()..moveTo(0, horizonY + 14);
      for (double sx = 0; sx <= size.width + 20; sx += 16) {
        final double effectiveFov = 110.0 / cameraZoom.clamp(0.75, 1.5);
        final double worldDeg =
            (cameraYaw + ((sx - size.width * 0.5) / size.width) * effectiveFov) %
            360.0;
        final double rad = worldDeg * math.pi / 180.0;
        final double lakeBasinWeight = _angleWeight(worldDeg, 0.0, 78.0);
        final double heightScale = 1.0 - lakeBasinWeight * 0.68;
        final double wave =
            (math.sin(rad * 4.0 + layer * 1.2) * 22.0 +
                math.cos(rad * 9.0) * 12.0) *
            heightScale;
        final double baseRise = (layer == 0 ? 34.0 : 18.0) * heightScale;
        final double sy =
            horizonY + (layer == 0 ? 2.0 : 6.0) - baseRise - wave.abs();
        hillPath.lineTo(sx, sy);
      }
      hillPath.lineTo(size.width, horizonY + 14);
      hillPath.close();

      final Color hillColor = layer == 0
          ? (atmosphereMode == CoconutAtmosphereMode.night
                ? const Color(0xFF122834)
                : const Color(0xFF28524B))
          : (atmosphereMode == CoconutAtmosphereMode.night
                ? const Color(0xFF18363B)
                : const Color(0xFF336650));
      canvas.drawPath(hillPath, Paint()..color = hillColor);
    }
  }

  void _drawValleyGroundAndMirrorPond(
    Canvas canvas,
    Size size,
    double horizonY,
  ) {
    final double span = size.height - horizonY;
    final Rect groundRect = Rect.fromLTWH(0, horizonY, size.width, span);

    // 1. Base sculpted Kyoto mossy temple ground across all 360°
    //    Everything from horizonY + span * 0.35 down to size.height (1.0) is continuous, uninterrupted mossy ground!
    List<Color> groundColors;
    switch (atmosphereMode) {
      case CoconutAtmosphereMode.night:
        groundColors = [
          const Color(0xFF102822),
          const Color(0xFF16382E),
          const Color(0xFF0E241E),
        ];
        break;
      case CoconutAtmosphereMode.noon:
        groundColors = [
          const Color(0xFF3B7A4A),
          const Color(0xFF2E693E),
          const Color(0xFF245432),
        ];
        break;
      case CoconutAtmosphereMode.rain:
        groundColors = [
          const Color(0xFF2B4E42),
          const Color(0xFF26453A),
          const Color(0xFF1E362D),
        ];
        break;
      case CoconutAtmosphereMode.sunset:
        groundColors = [
          const Color(0xFF3A5F43),
          const Color(0xFF2D5039),
          const Color(0xFF223D2B),
        ];
        break;
    }

    canvas.drawRect(
      groundRect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, horizonY),
          Offset(0, size.height),
          groundColors,
          const [0.0, 0.45, 1.0],
        ),
    );

    // Mid-horizon Kyoto hills & distant shoreline banks overlapping the horizon seam smoothly
    _drawInlandZenHillsAndCanopy(canvas, size, horizonY);

    // Subtle organic mossy turf undulations across the foreground & mid-ground so the ground feels rich and natural
    for (int m = 0; m < 18; m++) {
      final double deg = m * 20.0;
      final double? mx = _worldAngleToScreenX(deg, size, margin: 360);
      if (mx == null) continue;
      final double my = horizonY + span * (0.40 + (m % 4) * 0.13);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(mx, my), width: 280, height: 38),
        Paint()
          ..color = (m.isEven
                  ? const Color(0xFF3E6E48)
                  : const Color(0xFF23422E))
              .withValues(alpha: 0.22),
      );
    }

    // 2. Sculpted Kyoto Mossy Temple Terraces, Bamboo Forest Floor & Flagstone Walkways (78°..282°)
    _drawInlandTempleTerracesAndStream(canvas, size, horizonY, span);

    // 3. Emerald-Turquoise Mirror Koi Pond ONLY in the front upper/mid basin (-78°..+78°, span * 0.02 .. 0.34)
    final Path pondPath = Path();
    final List<Offset> topShorePoints = [];
    final List<Offset> bottomShorePoints = [];

    for (double deg = -78.0; deg <= 78.0; deg += 3.0) {
      final double? sx = _worldAngleToScreenX(deg, size, margin: 900);
      if (sx == null) continue;
      final double edgeFactor = (deg.abs() / 78.0).clamp(0.0, 1.0);
      // Strictly keep pond in span * 0.02 .. 0.28 so foreground (0.30..1.0) is uninterrupted mossy land
      final double topY =
          horizonY + span * (0.02 + math.pow(edgeFactor, 2.2) * 0.06);
      final double bottomY =
          horizonY +
          span *
              (0.28 -
                  math.pow(edgeFactor, 1.8) * 0.10 +
                  math.sin(deg * 0.12) * 0.012);
      topShorePoints.add(Offset(sx, topY));
      bottomShorePoints.add(Offset(sx, bottomY));
    }

    if (topShorePoints.length >= 2) {
      pondPath.moveTo(topShorePoints.first.dx, topShorePoints.first.dy);
      for (int i = 1; i < topShorePoints.length; i++) {
        pondPath.lineTo(topShorePoints[i].dx, topShorePoints[i].dy);
      }
      for (int i = bottomShorePoints.length - 1; i >= 0; i--) {
        pondPath.lineTo(bottomShorePoints[i].dx, bottomShorePoints[i].dy);
      }
      pondPath.close();

      final Color pondTop = atmosphereMode == CoconutAtmosphereMode.sunset
          ? const Color(0xFF3A7B84)
          : (atmosphereMode == CoconutAtmosphereMode.night
                ? const Color(0xFF0D2C40)
                : const Color(0xFF209B92));
      final Color pondBottom = atmosphereMode == CoconutAtmosphereMode.sunset
          ? const Color(0xFF174950)
          : (atmosphereMode == CoconutAtmosphereMode.night
                ? const Color(0xFF071B29)
                : const Color(0xFF14635C));

      // Mossy stone shoreline embankment rim around the Koi Pond
      canvas.drawPath(
        pondPath,
        Paint()
          ..color = const Color(0xFF5A646C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9.0
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.drawPath(
        pondPath,
        Paint()
          ..color = const Color(0xFF438A4E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0
          ..strokeJoin = StrokeJoin.round,
      );

      // Fill the Mirror Koi Pond water basin
      canvas.drawPath(
        pondPath,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, horizonY),
            Offset(0, horizonY + span * 0.35),
            [pondTop, pondBottom],
          ),
      );

      // Subtle inner water highlight rim along the pond shore
      canvas.drawPath(
        pondPath,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    }

    // 4. Reflection of Mount Fuji & Sun/Moon on the Mirror Koi Pond at 0° (strictly inside span * 0.04..0.30)
    final double? reflX = _worldAngleToScreenX(0.0, size, margin: 450);
    if (reflX != null) {
      final Color shimmerColor = atmosphereMode == CoconutAtmosphereMode.night
          ? const Color(0xFF9AC5FF)
          : (atmosphereMode == CoconutAtmosphereMode.sunset
                ? const Color(0xFFFF7B54)
                : const Color(0xFFFFF2B2));
      for (int r = 0; r < 14; r++) {
        final double ry = horizonY + span * (0.04 + r * 0.018);
        final double rw =
            (92.0 - r * 4.5) + math.sin(time * 2.8 + r * 0.7) * 9.0;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(reflX, ry), width: rw, height: 3.0),
            const Radius.circular(2),
          ),
          Paint()
            ..color = shimmerColor.withValues(
              alpha: (0.42 - r * 0.022).clamp(0.05, 0.45),
            ),
        );
      }
    }
  }

  void _drawInlandTempleTerracesAndStream(
    Canvas canvas,
    Size size,
    double horizonY,
    double span,
  ) {
    // 1. Sculpted mossy terraces & bamboo forest floor mounds across 78°..282° (in mid-ring 0.14..0.26)
    for (int t = 0; t < 14; t++) {
      final double deg = 82.0 + t * 14.2;
      final double? tx = _worldAngleToScreenX(deg, size, margin: 420);
      if (tx == null) continue;
      final double ty = horizonY + span * (0.14 + (t % 3) * 0.055);
      canvas.save();
      canvas.translate(tx, ty);
      canvas.drawOval(
        const Rect.fromLTWH(-125, -16, 250, 34),
        Paint()
          ..color = (t.isEven
                  ? const Color(0xFF437A49)
                  : const Color(0xFF2F5E38))
              .withValues(alpha: 0.45),
      );
      // Stone retaining wall edge on temple terraces
      if (t % 2 == 0) {
        for (int s = -4; s <= 4; s++) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(s * 20.0 - 9.0, 10, 18, 6),
              const Radius.circular(3),
            ),
            Paint()..color = const Color(0xFF68717A),
          );
        }
      }
      canvas.restore();
    }

    // 2. Winding Flagstone Temple Walkway (Ishidatami) from 76° to 278° at span * 0.31
    for (double deg = 76.0; deg <= 278.0; deg += 3.2) {
      final double? sx = _worldAngleToScreenX(deg, size, margin: 160);
      if (sx == null) continue;
      final double sy =
          horizonY +
          span * (0.31 + math.sin(deg * 0.065) * 0.016);
      canvas.save();
      canvas.translate(sx, sy);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-13, -4, 26, 8),
          const Radius.circular(3.5),
        ),
        Paint()
          ..color = ((deg ~/ 3) % 2 == 0)
              ? const Color(0xFF8C949C)
              : const Color(0xFF757E86),
      );
      canvas.restore();
    }

    // 3. Winding Stone-Lined Mountain Stream flowing from Twin Waterfalls (185°) into the Koi Pond (282°) along span * 0.20..0.28
    final Path streamPath = Path();
    final List<Offset> streamPoints = [];
    for (double deg = 185.0; deg <= 284.0; deg += 3.5) {
      final double? sx = _worldAngleToScreenX(deg, size, margin: 500);
      if (sx == null) continue;
      final double progress = (deg - 185.0) / (284.0 - 185.0);
      final double sy =
          horizonY +
          span *
              (0.20 +
                  progress * 0.08 +
                  math.sin(progress * math.pi * 3.0) * 0.018);
      streamPoints.add(Offset(sx, sy));
    }
    if (streamPoints.length >= 2) {
      streamPath.moveTo(streamPoints.first.dx, streamPoints.first.dy);
      for (int i = 1; i < streamPoints.length; i++) {
        streamPath.lineTo(streamPoints[i].dx, streamPoints[i].dy);
      }
      // Stone-lined stream banks
      canvas.drawPath(
        streamPath,
        Paint()
          ..color = const Color(0xFF5C666E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 18.0
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      // Turquoise mountain stream water
      canvas.drawPath(
        streamPath,
        Paint()
          ..color = const Color(0xFF26A69A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 11.0
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      // Animated white water ripples along the mountain stream
      canvas.drawPath(
        streamPath,
        Paint()
          ..color = const Color(0xFFB2EBF2).withValues(alpha: 0.65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round,
      );
    }

    // Gentle inlet channel under the Taiko-bashi Bridge at 74° (at span * 0.24)
    final double? bridgeChannelX = _worldAngleToScreenX(74.0, size, margin: 420);
    if (bridgeChannelX != null) {
      final double cy = horizonY + span * 0.24;
      canvas.save();
      canvas.translate(bridgeChannelX, cy);
      canvas.drawOval(
        const Rect.fromLTWH(-175, -14, 350, 38),
        Paint()..color = const Color(0xFF566068),
      );
      canvas.drawOval(
        const Rect.fromLTWH(-164, -9, 328, 28),
        Paint()..color = const Color(0xFF1F8A82),
      );
      canvas.restore();
    }
  }

  // ===========================================================================
  // 3. 0° ZONE — FLOATING LAKE TORII (-12°), GOLDEN PAVILION (+38°),
  //    LOTUS PADS, 16 KOI FISH & 2 YAKATABUNE BOATS (-70°..+70°)
  // ===========================================================================

  void _drawItsukushimaFloatingToriiAndKinkakuJi(
    Canvas canvas,
    Size size,
    double horizonY,
  ) {
    final double span = size.height - horizonY;

    // 1. Giant Vermilion Floating Lake Torii Gate (Itsukushima style, -12°, 1.90x scale)
    final double? toriiX = _worldAngleToScreenX(-12.0, size, margin: 480);
    if (toriiX != null) {
      final double ty = horizonY + span * 0.14;
      canvas.save();
      canvas.translate(toriiX, ty);
      canvas.scale(1.90);

      // Shimmering vermilion reflection in the mirror lake water
      for (int r = 0; r < 7; r++) {
        final double ry = 4.0 + r * 5.0;
        final double wave = math.sin(time * 3.0 + r) * 2.5;
        canvas.drawLine(
          Offset(-24 + wave, ry),
          Offset(-16 + wave, ry),
          Paint()
            ..color = const Color(0xFFD32F2F).withValues(alpha: 0.42 - r * 0.05)
            ..strokeWidth = 3.2,
        );
        canvas.drawLine(
          Offset(16 + wave, ry),
          Offset(24 + wave, ry),
          Paint()
            ..color = const Color(0xFFD32F2F).withValues(alpha: 0.42 - r * 0.05)
            ..strokeWidth = 3.2,
        );
      }

      // Expanding water ripple around the submerged pillars
      canvas.drawOval(
        const Rect.fromLTWH(-46, -4, 92, 12),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.32)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );

      // Side outrigger Ryobu Torii support pillars (Chigo-bashira)
      for (double sx in [-32.0, -10.0, 10.0, 32.0]) {
        canvas.drawRect(
          Rect.fromLTWH(sx - 2.2, -24, 4.4, 26),
          Paint()..color = const Color(0xFFB71C1C),
        );
      }
      canvas.drawRect(
        const Rect.fromLTWH(-35, -16, 28, 3.2),
        Paint()..color = const Color(0xFFC62828),
      );
      canvas.drawRect(
        const Rect.fromLTWH(7, -16, 28, 3.2),
        Paint()..color = const Color(0xFFC62828),
      );

      // Main towering vermilion pillars
      canvas.drawRect(
        const Rect.fromLTWH(-23, -64, 7.5, 66),
        Paint()..color = const Color(0xFFD82920),
      );
      canvas.drawRect(
        const Rect.fromLTWH(15.5, -64, 7.5, 66),
        Paint()..color = const Color(0xFFD82920),
      );
      // Black base wraps (Nemaki)
      canvas.drawRect(
        const Rect.fromLTWH(-24, -10, 9.5, 12),
        Paint()..color = const Color(0xFF1A1E24),
      );
      canvas.drawRect(
        const Rect.fromLTWH(14.5, -10, 9.5, 12),
        Paint()..color = const Color(0xFF1A1E24),
      );

      // Crossbeam (Nuki) & Golden Nameplate Plaque (Gaku)
      canvas.drawRect(
        const Rect.fromLTWH(-36, -48, 72, 6),
        Paint()..color = const Color(0xFFD82920),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-6, -61, 12, 13),
          const Radius.circular(1.5),
        ),
        Paint()..color = const Color(0xFF1A237E),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-6, -61, 12, 13),
          const Radius.circular(1.5),
        ),
        Paint()
          ..color = const Color(0xFFFFD54F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );

      // Sweeping Curved Upper Lintel (Kasagi & Shimaki)
      final Path kasagi = Path()
        ..moveTo(-46, -68)
        ..quadraticBezierTo(0, -60, 46, -68)
        ..lineTo(42, -60)
        ..quadraticBezierTo(0, -54, -42, -60)
        ..close();
      canvas.drawPath(kasagi, Paint()..color = const Color(0xFF1F242D));
      final Path shimaki = Path()
        ..moveTo(-42, -61)
        ..quadraticBezierTo(0, -55, 42, -61)
        ..lineTo(40, -56)
        ..quadraticBezierTo(0, -51, -40, -56)
        ..close();
      canvas.drawPath(shimaki, Paint()..color = const Color(0xFFE53935));

      canvas.restore();
    }

    // 2. Gleaming Two-Story Golden Pavilion (Kinkaku-ji style, +38°, 1.85x scale)
    final double? kinkakuX = _worldAngleToScreenX(38.0, size, margin: 480);
    if (kinkakuX != null) {
      final double ky = horizonY + span * 0.15;
      canvas.save();
      canvas.translate(kinkakuX, ky);
      canvas.scale(1.85);

      // Golden water reflection beneath the peninsula
      canvas.drawOval(
        const Rect.fromLTWH(-62, 6, 124, 22),
        Paint()
          ..color = const Color(0xFFFFCA28).withValues(alpha: 0.34)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
      );

      // Mossy rock peninsula & stone foundation extending into the lake
      canvas.drawOval(
        const Rect.fromLTWH(-74, -4, 148, 18),
        Paint()..color = const Color(0xFF455A64),
      );
      canvas.drawOval(
        const Rect.fromLTWH(-66, -8, 132, 12),
        Paint()..color = const Color(0xFF43A047),
      );

      // First Floor (Shinden-zukuri white plaster & dark wood)
      canvas.drawRect(
        const Rect.fromLTWH(-44, -28, 88, 22),
        Paint()..color = const Color(0xFFF5F0E1),
      );
      for (double px = -42; px <= 42; px += 14) {
        canvas.drawLine(
          Offset(px, -28),
          Offset(px, -6),
          Paint()
            ..color = const Color(0xFF4E342E)
            ..strokeWidth = 2.0,
        );
      }
      // First Eave Roof
      final Path roof1 = Path()
        ..moveTo(-58, -26)
        ..quadraticBezierTo(0, -35, 58, -26)
        ..lineTo(50, -22)
        ..lineTo(-50, -22)
        ..close();
      canvas.drawPath(roof1, Paint()..color = const Color(0xFF2B313B));

      // Second Floor (Gleaming Pure Gold Leaf Bukke-zukuri)
      final Rect floor2 = const Rect.fromLTWH(-36, -50, 72, 22);
      canvas.drawRect(
        floor2,
        Paint()
          ..shader = ui.Gradient.linear(
            floor2.topLeft,
            floor2.bottomRight,
            const [
              Color(0xFFFFF176),
              Color(0xFFFFCA28),
              Color(0xFFD4AF37),
            ],
            const [0.0, 0.5, 1.0],
          ),
      );
      // Golden balcony railing & lattice windows
      canvas.drawRect(
        const Rect.fromLTWH(-40, -33, 80, 4),
        Paint()..color = const Color(0xFFFFB300),
      );
      for (int w = -2; w <= 2; w++) {
        canvas.drawRect(
          Rect.fromLTWH(w * 12.0 - 4.0, -45, 8, 10),
          Paint()..color = const Color(0xFF5D4037),
        );
      }

      // Upper Pyramidal Hip Roof with upturned corners
      final Path roof2 = Path()
        ..moveTo(-50, -48)
        ..quadraticBezierTo(-22, -68, 0, -72)
        ..quadraticBezierTo(22, -68, 50, -48)
        ..lineTo(42, -44)
        ..lineTo(-42, -44)
        ..close();
      canvas.drawPath(roof2, Paint()..color = const Color(0xFF252B34));
      canvas.drawPath(
        roof2,
        Paint()
          ..color = const Color(0xFFFFD54F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );

      // Iconic Golden Phoenix (Houou) Roof Finial on the apex
      canvas.drawCircle(
        const Offset(0, -75),
        3.2,
        Paint()..color = const Color(0xFFFFD54F),
      );
      final Path phoenixWings = Path()
        ..moveTo(-8, -81)
        ..quadraticBezierTo(-3, -75, 0, -76)
        ..quadraticBezierTo(3, -75, 8, -81);
      canvas.drawPath(
        phoenixWings,
        Paint()
          ..color = const Color(0xFFFFEA00)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round,
      );

      canvas.restore();
    }
  }

  void _drawLotusPadsAndKoiFish(Canvas canvas, Size size, double horizonY) {
    final double span = size.height - horizonY;

    // 35 Floating Green Lotus Pads with blooming Pink Lotus Flowers (-72°..+72°)
    for (int i = 0; i < 35; i++) {
      final double worldDeg = -70.0 + (i * 140.0 / 35.0) + (i % 3) * 2.2;
      final double? sx = _worldAngleToScreenX(worldDeg, size, margin: 160);
      if (sx == null) continue;

      final double yFactor = 0.10 + (i % 7) * 0.032;
      final double sy =
          horizonY + span * yFactor + math.sin(time * 1.6 + i) * 2.5;
      final double padScale = (1.35 + (i % 4) * 0.22) * (0.75 + yFactor);

      canvas.save();
      canvas.translate(sx, sy);
      canvas.scale(padScale);

      final Path padPath = Path()
        ..addArc(
          const Rect.fromLTWH(-18, -9, 36, 18),
          0.25,
          math.pi * 2 - 0.5,
        )
        ..lineTo(0, 0)
        ..close();
      canvas.drawPath(padPath, Paint()..color = const Color(0xFF2E8555));
      canvas.drawPath(
        padPath,
        Paint()
          ..color = const Color(0xFF56B87A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );

      if (i % 2 == 0) {
        for (int p = -2; p <= 2; p++) {
          canvas.save();
          canvas.rotate(p * 0.35);
          canvas.drawOval(
            const Rect.fromLTWH(-3.5, -12, 7, 11),
            Paint()
              ..color = p.abs() == 2
                  ? const Color(0xFFF48FB1)
                  : const Color(0xFFFCE4EC),
          );
          canvas.restore();
        }
        canvas.drawCircle(
          const Offset(0, -4),
          2.6,
          Paint()..color = const Color(0xFFFFD54F),
        );
      }

      canvas.restore();
    }

    // 16 Large Animated Orange/White/Gold Koi Fish swimming in S-curves inside the Koi Pond
    for (int k = 0; k < 16; k++) {
      final double dir = (k % 2 == 0) ? 1.0 : -1.0;
      final double baseDeg = -64.0 + k * 8.5;
      final double swimDeg =
          (baseDeg + dir * math.sin(time * 0.55 + k) * 6.5) % 360.0;
      final double? sx = _worldAngleToScreenX(swimDeg, size, margin: 180);
      if (sx == null) continue;

      final double yFactor = 0.12 + (k % 5) * 0.044;
      final double sy =
          horizonY + span * yFactor + math.cos(time * 1.4 + k) * 3.5;
      final double scale = 1.84 + (k % 3) * 0.08;

      canvas.save();
      canvas.translate(sx, sy);
      canvas.scale(scale * dir, scale);

      final double ripplePhase = (time * 0.9 + k * 0.37) % 1.0;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: 34 + ripplePhase * 28,
          height: 14 + ripplePhase * 11,
        ),
        Paint()
          ..color = Colors.white.withValues(alpha: (1.0 - ripplePhase) * 0.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1,
      );

      final double wag = math.sin(time * 5.2 + k * 1.3) * 4.5;
      final Color koiBase = (k % 3 == 0)
          ? const Color(0xFFFF6D24)
          : (k % 3 == 1
                ? const Color(0xFFFFF8E7)
                : const Color(0xFFFFB72B));

      final Path koiBody = Path()
        ..moveTo(14, 0)
        ..quadraticBezierTo(6, -6, -6, -3 + wag * 0.3)
        ..quadraticBezierTo(-15, wag * 0.6, -22, -5 + wag)
        ..lineTo(-19, wag * 0.7)
        ..lineTo(-23, 5 + wag)
        ..quadraticBezierTo(-15, 3 + wag * 0.6, -6, 4 + wag * 0.3)
        ..quadraticBezierTo(6, 6, 14, 0)
        ..close();

      canvas.drawPath(koiBody, Paint()..color = koiBase);

      if (k % 3 != 2) {
        canvas.drawOval(
          const Rect.fromLTWH(-4, -3.5, 9, 6),
          Paint()..color = const Color(0xFFD92B2B),
        );
        canvas.drawOval(
          const Rect.fromLTWH(4, -2.5, 6, 4.5),
          Paint()..color = const Color(0xFFD92B2B),
        );
      }

      canvas.drawOval(
        const Rect.fromLTWH(1, -8, 6, 4),
        Paint()..color = koiBase.withValues(alpha: 0.85),
      );
      canvas.drawOval(
        const Rect.fromLTWH(1, 4, 6, 4),
        Paint()..color = koiBase.withValues(alpha: 0.85),
      );

      canvas.restore();
    }
  }

  void _drawYakatabuneBoatsAndToroNagashi(
    Canvas canvas,
    Size size,
    double horizonY,
  ) {
    final double span = size.height - horizonY;

    // 2 Traditional Wooden Yakatabune Roofed Lantern Boats
    final List<double> boatAngles = [
      -28.0 + math.sin(time * 0.25) * 5.0,
      24.0 + math.cos(time * 0.22) * 5.0,
    ];
    final List<double> boatYFactors = [0.16, 0.20];

    for (int b = 0; b < 2; b++) {
      final double? bx = _worldAngleToScreenX(
        boatAngles[b],
        size,
        margin: 340,
      );
      if (bx == null) continue;

      final double by =
          horizonY +
          span * boatYFactors[b] +
          math.sin(time * 1.8 + b * 2.0) * 3.0;

      canvas.save();
      canvas.translate(bx, by);
      canvas.scale(1.75 * (b == 0 ? 1.0 : -1.0), 1.75);

      canvas.drawOval(
        const Rect.fromLTWH(-52, 8, 104, 16),
        Paint()
          ..color = const Color(0xFFFF9838).withValues(alpha: 0.32)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      final Path hull = Path()
        ..moveTo(-64, 0)
        ..lineTo(-48, 12)
        ..lineTo(48, 12)
        ..lineTo(68, -6)
        ..lineTo(54, -2)
        ..lineTo(-52, -2)
        ..close();
      canvas.drawPath(hull, Paint()..color = const Color(0xFF4A2C18));
      canvas.drawLine(
        const Offset(-50, 4),
        const Offset(52, 4),
        Paint()
          ..color = const Color(0xFFC58B4E)
          ..strokeWidth = 1.6,
      );

      canvas.drawRect(
        const Rect.fromLTWH(-34, -22, 68, 20),
        Paint()..color = const Color(0xFFFFDF9E).withValues(alpha: 0.88),
      );
      for (double px = -34; px <= 34; px += 17) {
        canvas.drawLine(
          Offset(px, -22),
          Offset(px, -2),
          Paint()
            ..color = const Color(0xFF3E2212)
            ..strokeWidth = 2.0,
        );
      }

      final Path roof = Path()
        ..moveTo(-48, -21)
        ..quadraticBezierTo(-24, -34, 0, -34)
        ..quadraticBezierTo(24, -34, 48, -21)
        ..lineTo(40, -18)
        ..lineTo(-40, -18)
        ..close();
      canvas.drawPath(roof, Paint()..color = const Color(0xFF232832));
      canvas.drawPath(
        roof,
        Paint()
          ..color = const Color(0xFFD99B38)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );

      for (int l = -2; l <= 2; l++) {
        final double lx = l * 15.0;
        canvas.drawOval(
          Rect.fromCenter(center: Offset(lx, -15), width: 7, height: 9),
          Paint()..color = const Color(0xFFFF4F2E),
        );
        canvas.drawCircle(
          Offset(lx, -15),
          2.2,
          Paint()..color = const Color(0xFFFFF3B0),
        );
      }

      _drawArticulatedPerson(
        canvas,
        const Offset(-44, -10),
        scale: 0.85,
        kimonoColor: const Color(0xFF284B7E),
        obiColor: const Color(0xFFE2B857),
        hasKasaHat: true,
      );
      canvas.drawLine(
        const Offset(-48, -12),
        const Offset(-64, 16),
        Paint()
          ..color = const Color(0xFF8B6B3E)
          ..strokeWidth = 1.6,
      );
      _drawArticulatedPerson(
        canvas,
        const Offset(8, -8),
        scale: 0.78,
        kimonoColor: const Color(0xFFD84358),
        obiColor: const Color(0xFFFFE082),
        isSeated: true,
      );

      canvas.restore();
    }

    // 12 Floating Toro Nagashi Water Lanterns drifting on the pond
    for (int t = 0; t < 12; t++) {
      final double deg = -58.0 + t * 10.5 + math.sin(time * 0.7 + t) * 2.5;
      final double? tx = _worldAngleToScreenX(deg, size, margin: 100);
      if (tx == null) continue;
      final double ty =
          horizonY + span * (0.12 + (t % 4) * 0.035) + math.cos(time + t) * 2.0;

      canvas.save();
      canvas.translate(tx, ty);
      canvas.scale(1.65);

      canvas.drawOval(
        const Rect.fromLTWH(-10, 2, 20, 7),
        Paint()
          ..color = const Color(0xFFFFA726).withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawRect(
        const Rect.fromLTWH(-7, 1, 14, 3),
        Paint()..color = const Color(0xFF5D3A1A),
      );
      canvas.drawRect(
        const Rect.fromLTWH(-5, -9, 10, 10),
        Paint()..color = const Color(0xFFFFF0C2),
      );
      canvas.drawRect(
        const Rect.fromLTWH(-5, -9, 10, 10),
        Paint()
          ..color = const Color(0xFF6D4C41)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
      canvas.restore();
    }
  }

  // ===========================================================================
  // 4. 72° ZONE — HIGH VERMILION ARCHED TEMPLE BRIDGE (TAIKO-BASHI, 72°)
  //    & BLOOMING WISTERIA PERGOLA TUNNEL (FUJI-DANA, 94°)
  // ===========================================================================

  void _drawTaikoBashiBridgeZone(Canvas canvas, Size size, double horizonY) {
    final double span = size.height - horizonY;

    // 1. High Vermilion Arched Drum Bridge (Taiko-bashi, 72°, 1.75x scale)
    final double? bx = _worldAngleToScreenX(72.0, size, margin: 520);
    if (bx != null) {
      final double by = horizonY + span * 0.19;

      canvas.save();
      canvas.translate(bx, by);
      canvas.scale(1.75);

      // Sculpted stone & moss embankments on both ends of the bridge
      for (double side in [-1.0, 1.0]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(side * 124.0, 20.0),
              width: 44,
              height: 22,
            ),
            const Radius.circular(6),
          ),
          Paint()..color = const Color(0xFF606972),
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(side * 124.0, 11.0),
            width: 38,
            height: 8,
          ),
          Paint()..color = const Color(0xFF4CAF50),
        );
      }

      _drawStoneToroLantern(canvas, const Offset(-138, 12), scale: 1.05);
      _drawStoneToroLantern(canvas, const Offset(138, 12), scale: 1.05);

      for (double px in [-92.0, -52.0, 0.0, 52.0, 92.0]) {
        final double archY = -48.0 * math.cos((px / 125.0) * (math.pi / 2));
        canvas.drawLine(
          Offset(px, archY + 6),
          Offset(px, 28),
          Paint()
            ..color = const Color(0xFF8C1D18)
            ..strokeWidth = 5.5,
        );
        canvas.drawLine(
          Offset(px, 28),
          Offset(px, 44),
          Paint()
            ..color = const Color(0xFF8C1D18).withValues(alpha: 0.28)
            ..strokeWidth = 4.5,
        );
      }

      final Path bridgeDeck = Path()
        ..moveTo(-125, 16)
        ..quadraticBezierTo(0, -64, 125, 16)
        ..lineTo(125, 26)
        ..quadraticBezierTo(0, -50, -125, 26)
        ..close();
      canvas.drawPath(bridgeDeck, Paint()..color = const Color(0xFFC92A22));

      final Path topRail = Path()
        ..moveTo(-125, 0)
        ..quadraticBezierTo(0, -82, 125, 0);
      canvas.drawPath(
        topRail,
        Paint()
          ..color = const Color(0xFFE53935)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.2
          ..strokeCap = StrokeCap.round,
      );

      for (int post = -5; post <= 5; post++) {
        final double t = post / 5.0;
        final double px = t * 116.0;
        final double deckY = 16.0 - (1.0 - t * t) * 40.0;
        final double railY = deckY - 16.0;
        canvas.drawLine(
          Offset(px, deckY),
          Offset(px, railY),
          Paint()
            ..color = const Color(0xFFB71C1C)
            ..strokeWidth = 3.0,
        );
        canvas.drawCircle(
          Offset(px, railY - 2),
          2.8,
          Paint()..color = const Color(0xFFFFD54F),
        );
      }

      // 4 Articulated People in colorful Kimono/Yukata strolling across the bridge
      final double walkBob = math.sin(time * 3.2) * 1.5;
      _drawArticulatedPerson(
        canvas,
        Offset(-44, -18 + walkBob),
        scale: 0.96,
        kimonoColor: const Color(0xFFE91E63),
        obiColor: const Color(0xFFFFD54F),
        hasParasol: true,
        parasolColor: const Color(0xFFFF5252),
      );
      _drawArticulatedPerson(
        canvas,
        Offset(-18, -26 - walkBob),
        scale: 0.98,
        kimonoColor: const Color(0xFF283593),
        obiColor: const Color(0xFFB0BEC5),
      );
      _drawArticulatedPerson(
        canvas,
        Offset(16, -27 + walkBob),
        scale: 0.95,
        kimonoColor: const Color(0xFF8E24AA),
        obiColor: const Color(0xFFFFF176),
        hasParasol: true,
        parasolColor: const Color(0xFFBA68C8),
        hasSpeechBubble: true,
      );
      _drawArticulatedPerson(
        canvas,
        Offset(48, -16 - walkBob),
        scale: 0.92,
        kimonoColor: const Color(0xFF00897B),
        obiColor: const Color(0xFFFFCA28),
      );

      canvas.restore();
    }

    // 2. Blooming Purple & Pink Wisteria Pergola Tunnel (Fuji-dana, 94°, 1.75x scale)
    final double? wisteriaX = _worldAngleToScreenX(94.0, size, margin: 460);
    if (wisteriaX != null) {
      final double wy = horizonY + span * 0.21;
      canvas.save();
      canvas.translate(wisteriaX, wy);
      canvas.scale(1.75);

      // Flagstone garden path beneath the trellis
      canvas.drawOval(
        const Rect.fromLTWH(-72, -4, 144, 18),
        Paint()..color = const Color(0xFF7B848C),
      );

      // Wooden trellis pillars & overhead arbor beams
      for (double px in [-54.0, -18.0, 18.0, 54.0]) {
        canvas.drawRect(
          Rect.fromLTWH(px - 2.5, -48, 5, 52),
          Paint()..color = const Color(0xFF4E342E),
        );
      }
      canvas.drawRect(
        const Rect.fromLTWH(-64, -52, 128, 5),
        Paint()..color = const Color(0xFF3E2723),
      );
      canvas.drawRect(
        const Rect.fromLTWH(-60, -46, 120, 3.5),
        Paint()..color = const Color(0xFF5D4037),
      );

      // Lush green vine canopy on top of the trellis
      for (int c = -3; c <= 3; c++) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(c * 17.0, -53.0),
            width: 28,
            height: 10,
          ),
          Paint()..color = const Color(0xFF388E3C),
        );
      }

      // 17 Hanging Purple, Lavender & Pink Wisteria Floral Cascades swaying in the breeze
      for (int f = -8; f <= 8; f++) {
        final double fx = f * 7.2;
        final double sway = math.sin(time * 2.6 + f * 0.5) * 2.4;
        final double cascadeLen = 20.0 + (f.abs() % 3) * 6.5;
        final Color topColor = f.isEven
            ? const Color(0xFF8E24AA)
            : const Color(0xFFAB47BC);
        final Color tipColor = f.isEven
            ? const Color(0xFFE1BEE7)
            : const Color(0xFFF8BBD0);

        for (int b = 0; b < 5; b++) {
          final double t = b / 4.0;
          final double by = -45.0 + t * cascadeLen;
          final double bxOff = fx + sway * t;
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(bxOff, by),
              width: 6.5 - t * 2.5,
              height: 6.0,
            ),
            Paint()..color = Color.lerp(topColor, tipColor, t)!,
          );
        }
      }

      canvas.restore();
    }
  }

  // ===========================================================================
  // 5. 126° ZONE — FIVE-STORY PAGODA (116°), KARESANSUI COURTYARD WITH MONK (130°),
  //    TEA HOUSE (136°), SHISHI-ODOSHI (149°) & EMA RACK (155°)
  // ===========================================================================

  void _drawPagodaAndTeaHouseZone(Canvas canvas, Size size, double horizonY) {
    final double span = size.height - horizonY;

    // 1. Raked White Gravel Karesansui Courtyard at 130° with a Zen Monk raking the gravel
    final double? gardenX = _worldAngleToScreenX(130.0, size, margin: 580);
    if (gardenX != null) {
      final double gy = horizonY + span * 0.19;
      canvas.save();
      canvas.translate(gardenX, gy);
      canvas.scale(1.85);

      // Dark timber/stone courtyard border around the white Karesansui gravel
      canvas.drawOval(
        const Rect.fromLTWH(-192, -28, 384, 64),
        Paint()..color = const Color(0xFF5D646B),
      );
      canvas.drawOval(
        const Rect.fromLTWH(-185, -24, 370, 56),
        Paint()..color = const Color(0xFFE5DFD3).withValues(alpha: 0.94),
      );

      final Paint rakePaint = Paint()
        ..color = const Color(0xFFB8B0A0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3;
      for (int r = -3; r <= 3; r++) {
        final Path wavePath = Path()..moveTo(-165, r * 6.0);
        for (double wx = -165; wx <= 165; wx += 15) {
          wavePath.quadraticBezierTo(
            wx + 7.5,
            r * 6.0 + ((wx ~/ 15) % 2 == 0 ? -3.5 : 3.5),
            wx + 15,
            r * 6.0,
          );
        }
        canvas.drawPath(wavePath, rakePaint);
      }

      // Sacred accent stones inside the Karesansui courtyard
      for (final Offset stonePos in [
        const Offset(-95, 4),
        const Offset(88, -4),
      ]) {
        canvas.drawOval(
          Rect.fromCenter(center: stonePos, width: 26, height: 14),
          Paint()..color = const Color(0xFF4A535B),
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: stonePos.translate(0, -3),
            width: 16,
            height: 7,
          ),
          Paint()..color = const Color(0xFF4CAF50),
        );
      }

      // Zen Monk in dark robes raking the white gravel with a wooden rake (Kumade)
      final double rakeSweep = math.sin(time * 2.4) * 5.0;
      _drawArticulatedPerson(
        canvas,
        Offset(-34, 8),
        scale: 0.90,
        kimonoColor: const Color(0xFF37474F),
        obiColor: const Color(0xFFD7B377),
      );
      // Wooden Kumade rake handle & head
      canvas.drawLine(
        const Offset(-30, -4),
        Offset(-14 + rakeSweep, 12),
        Paint()
          ..color = const Color(0xFF8D6E3F)
          ..strokeWidth = 1.8,
      );
      canvas.drawLine(
        Offset(-18 + rakeSweep, 12),
        Offset(-10 + rakeSweep, 12),
        Paint()
          ..color = const Color(0xFF6D4C41)
          ..strokeWidth = 2.6,
      );

      canvas.restore();
    }

    // 2. Five-Story Vermilion Pagoda at 116° (1.92x scale)
    final double? pagodaX = _worldAngleToScreenX(116.0, size, margin: 480);
    if (pagodaX != null) {
      final double py = horizonY + span * 0.17;
      canvas.save();
      canvas.translate(pagodaX, py);
      canvas.scale(1.92);

      // Stone foundation platform & steps
      canvas.drawRect(
        const Rect.fromLTWH(-54, 0, 108, 14),
        Paint()..color = const Color(0xFF7D848C),
      );
      canvas.drawRect(
        const Rect.fromLTWH(-18, 2, 36, 12),
        Paint()..color = const Color(0xFF9AA2AA),
      );

      // 5 Tiers rising upward
      for (int tier = 0; tier < 5; tier++) {
        final double ty = -tier * 28.0;
        final double w = 78.0 - tier * 10.0;

        canvas.drawRect(
          Rect.fromLTWH(-w * 0.42, ty - 22, w * 0.84, 22),
          Paint()..color = const Color(0xFFB7241E),
        );
        canvas.drawRect(
          Rect.fromLTWH(-w * 0.18, ty - 16, w * 0.36, 10),
          Paint()..color = const Color(0xFFFFD88A),
        );

        final Path roof = Path()
          ..moveTo(-w * 0.72, ty - 19)
          ..quadraticBezierTo(-w * 0.35, ty - 28, 0, ty - 30)
          ..quadraticBezierTo(w * 0.35, ty - 28, w * 0.72, ty - 19)
          ..lineTo(w * 0.58, ty - 15)
          ..lineTo(-w * 0.58, ty - 15)
          ..close();
        canvas.drawPath(roof, Paint()..color = const Color(0xFF222730));
        canvas.drawPath(
          roof,
          Paint()
            ..color = const Color(0xFFD99F36)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.1,
        );

        final double chimeSwing = math.sin(time * 3.0 + tier) * 2.0;
        canvas.drawLine(
          Offset(-w * 0.65, ty - 18),
          Offset(-w * 0.65 + chimeSwing, ty - 11),
          Paint()
            ..color = const Color(0xFFFFD54F)
            ..strokeWidth = 1.2,
        );
        canvas.drawLine(
          Offset(w * 0.65, ty - 18),
          Offset(w * 0.65 + chimeSwing, ty - 11),
          Paint()
            ..color = const Color(0xFFFFD54F)
            ..strokeWidth = 1.2,
        );
      }

      // Golden Sorin spire on top of the 5th roof
      canvas.drawLine(
        const Offset(0, -166),
        const Offset(0, -206),
        Paint()
          ..color = const Color(0xFFFFCA28)
          ..strokeWidth = 3.2,
      );
      for (int ring = 0; ring < 5; ring++) {
        canvas.drawLine(
          Offset(-6 + ring * 0.6, -172 - ring * 6.0),
          Offset(6 - ring * 0.6, -172 - ring * 6.0),
          Paint()
            ..color = const Color(0xFFFFE082)
            ..strokeWidth = 1.6,
        );
      }

      _drawStoneToroLantern(canvas, const Offset(-64, 8), scale: 0.95);
      canvas.restore();
    }

    // 3. Traditional Wooden Tea House (Chashitsu) at 136° (1.88x scale)
    final double? teaX = _worldAngleToScreenX(136.0, size, margin: 480);
    if (teaX != null) {
      final double ty = horizonY + span * 0.18;
      canvas.save();
      canvas.translate(teaX, ty);
      canvas.scale(1.88);

      // Stone foundation & wooden Engawa veranda deck
      canvas.drawRect(
        const Rect.fromLTWH(-82, 4, 164, 8),
        Paint()..color = const Color(0xFF687078),
      );
      canvas.drawRect(
        const Rect.fromLTWH(-78, -4, 156, 10),
        Paint()..color = const Color(0xFF6D4428),
      );
      canvas.drawRect(
        const Rect.fromLTWH(-68, -54, 136, 50),
        Paint()..color = const Color(0xFF4A2E1B),
      );

      for (int s = -1; s <= 1; s++) {
        final Rect shojiRect = Rect.fromLTWH(s * 40.0 - 18.0, -48, 36, 42);
        canvas.drawRect(
          shojiRect,
          Paint()
            ..shader = ui.Gradient.linear(
              shojiRect.topCenter,
              shojiRect.bottomCenter,
              [const Color(0xFFFFF3C4), const Color(0xFFFFB74D)],
            ),
        );
        final Paint gridPaint = Paint()
          ..color = const Color(0xFF5D3A1A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1;
        canvas.drawRect(shojiRect, gridPaint);
        canvas.drawLine(
          Offset(shojiRect.center.dx, shojiRect.top),
          Offset(shojiRect.center.dx, shojiRect.bottom),
          gridPaint,
        );
        for (int row = 1; row <= 3; row++) {
          final double ry = shojiRect.top + row * 10.5;
          canvas.drawLine(
            Offset(shojiRect.left, ry),
            Offset(shojiRect.right, ry),
            gridPaint,
          );
        }
      }

      final Path teaRoof = Path()
        ..moveTo(-92, -50)
        ..quadraticBezierTo(-45, -78, 0, -82)
        ..quadraticBezierTo(45, -78, 92, -50)
        ..lineTo(82, -44)
        ..lineTo(-82, -44)
        ..close();
      canvas.drawPath(teaRoof, Paint()..color = const Color(0xFF28303B));
      canvas.drawPath(
        teaRoof,
        Paint()
          ..color = const Color(0xFFC58B43)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );

      canvas.drawOval(
        const Rect.fromLTWH(-64, -44, 16, 22),
        Paint()..color = const Color(0xFFE53935),
      );
      canvas.drawOval(
        const Rect.fromLTWH(-64, -44, 16, 22),
        Paint()
          ..color = const Color(0xFFFFD54F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1,
      );

      _drawArticulatedPerson(
        canvas,
        const Offset(-36, -6),
        scale: 0.90,
        kimonoColor: const Color(0xFF33691E),
        obiColor: const Color(0xFFFFD54F),
        isSeated: true,
      );
      canvas.drawRect(
        const Rect.fromLTWH(-20, -4, 44, 5),
        Paint()..color = const Color(0xFF4E2A14),
      );
      for (double cx in [-12.0, 0.0, 12.0]) {
        canvas.drawRect(
          Rect.fromLTWH(cx - 2.5, -8, 5, 4),
          Paint()..color = const Color(0xFF66BB6A),
        );
      }
      _drawArticulatedPerson(
        canvas,
        const Offset(-4, -6),
        scale: 0.88,
        kimonoColor: const Color(0xFFC2185B),
        obiColor: const Color(0xFFFFF176),
        isSeated: true,
        hasSpeechBubble: true,
      );
      _drawArticulatedPerson(
        canvas,
        const Offset(24, -6),
        scale: 0.88,
        kimonoColor: const Color(0xFF1976D2),
        obiColor: const Color(0xFFFFCC80),
        isSeated: true,
      );
      _drawArticulatedPerson(
        canvas,
        const Offset(48, -6),
        scale: 0.86,
        kimonoColor: const Color(0xFF7B1FA2),
        obiColor: const Color(0xFFFFE082),
        isSeated: true,
      );

      canvas.restore();
    }

    // 4. Animated Bamboo Water Clacker (Shishi-odoshi, 149°, 1.82x scale)
    final double? shishiX = _worldAngleToScreenX(149.0, size, margin: 320);
    if (shishiX != null) {
      final double sy = horizonY + span * 0.19;
      canvas.save();
      canvas.translate(shishiX, sy);
      canvas.scale(1.82);

      canvas.drawOval(
        const Rect.fromLTWH(-22, -2, 44, 16),
        Paint()..color = const Color(0xFF5A636A),
      );
      canvas.drawOval(
        const Rect.fromLTWH(-17, 1, 34, 10),
        Paint()..color = const Color(0xFF4DD0E1),
      );

      canvas.drawLine(
        const Offset(-16, 4),
        const Offset(-16, -28),
        Paint()
          ..color = const Color(0xFF689F38)
          ..strokeWidth = 4.5,
      );
      canvas.drawLine(
        const Offset(-16, -26),
        const Offset(-4, -22),
        Paint()
          ..color = const Color(0xFF689F38)
          ..strokeWidth = 3.5,
      );

      final double cycle = (time * 0.65) % 1.0;
      final double tiltAngle = cycle < 0.72
          ? -0.25 + (cycle / 0.72) * 0.45
          : 0.55 - ((cycle - 0.72) / 0.28) * 0.80;

      canvas.save();
      canvas.translate(2, -12);
      canvas.rotate(tiltAngle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-14, -3, 28, 6),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFF7CB342),
      );
      canvas.restore();

      if (cycle > 0.65 && cycle < 0.88) {
        canvas.drawLine(
          const Offset(12, -8),
          const Offset(10, 5),
          Paint()
            ..color = const Color(0xFFB2EBF2)
            ..strokeWidth = 2.2,
        );
      }
      canvas.restore();
    }

    // 5. Wooden Ema Wish Plaque Rack at 155°
    final double? emaX = _worldAngleToScreenX(155.0, size, margin: 320);
    if (emaX != null) {
      final double ey = horizonY + span * 0.19;
      canvas.save();
      canvas.translate(emaX, ey);
      canvas.scale(1.80);

      canvas.drawLine(
        const Offset(-24, 10),
        const Offset(-24, -36),
        Paint()
          ..color = const Color(0xFF5D3A1A)
          ..strokeWidth = 3.5,
      );
      canvas.drawLine(
        const Offset(24, 10),
        const Offset(24, -36),
        Paint()
          ..color = const Color(0xFF5D3A1A)
          ..strokeWidth = 3.5,
      );
      canvas.drawLine(
        const Offset(-28, -36),
        const Offset(28, -36),
        Paint()
          ..color = const Color(0xFF3E2723)
          ..strokeWidth = 5.0,
      );

      for (int row = 0; row < 3; row++) {
        for (int col = -2; col <= 2; col++) {
          final double swing = math.sin(time * 3.4 + row + col) * 1.5;
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset(col * 9.0 + swing, -26.0 + row * 10.0),
              width: 6.5,
              height: 5.0,
            ),
            Paint()..color = const Color(0xFFE6C280),
          );
        }
      }
      canvas.restore();
    }
  }

  // ===========================================================================
  // 6. 166° ZONE — CLIFFSIDE STEAMING VOLCANIC ROCK ONSEN & RYOKAN BATHHOUSE
  // ===========================================================================

  void _drawSteamingOnsenZone(Canvas canvas, Size size, double horizonY) {
    final double? ox = _worldAngleToScreenX(166.0, size, margin: 540);
    if (ox == null) return;

    final double span = size.height - horizonY;
    final double oy = horizonY + span * 0.18;

    canvas.save();
    canvas.translate(ox, oy);
    canvas.scale(1.65);

    // 1. Traditional Wooden Ryokan Bathhouse Facade with Indigo Noren Curtains behind the bamboo screen
    canvas.drawRect(
      const Rect.fromLTWH(-44, -84, 134, 62),
      Paint()..color = const Color(0xFF4A2E1B),
    );
    // Warm glowing Ryokan Shoji windows
    for (int w = 0; w < 2; w++) {
      final Rect win = Rect.fromLTWH(-32.0 + w * 74.0, -72, 34, 32);
      canvas.drawRect(win, Paint()..color = const Color(0xFFFFECB3));
      canvas.drawRect(
        win,
        Paint()
          ..color = const Color(0xFF3E2723)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }
    // Indigo Noren Entrance Curtains (3 panels with white Onsen Yumoto crest)
    for (int n = -1; n <= 1; n++) {
      final Rect noren = Rect.fromLTWH(20.0 + n * 11.5 - 5.0, -72, 10.5, 28);
      canvas.drawRRect(
        RRect.fromRectAndRadius(noren, const Radius.circular(1.5)),
        Paint()..color = const Color(0xFF1A237E),
      );
      canvas.drawCircle(
        noren.center,
        3.0,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }
    // Sweeping Tiled Ryokan Roof
    final Path ryokanRoof = Path()
      ..moveTo(-58, -80)
      ..quadraticBezierTo(23, -106, 104, -80)
      ..lineTo(96, -74)
      ..lineTo(-50, -74)
      ..close();
    canvas.drawPath(ryokanRoof, Paint()..color = const Color(0xFF262D36));
    canvas.drawPath(
      ryokanRoof,
      Paint()
        ..color = const Color(0xFFD49A3D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );

    // 2. Woven Bamboo Privacy Screen (Takegaki) on the left of the Onsen
    for (int i = -6; i <= 0; i++) {
      final double bx = i * 14.0 - 20.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(bx, -52, 12, 38),
          const Radius.circular(3),
        ),
        Paint()
          ..color = i.isEven
              ? const Color(0xFF8D6E3F)
              : const Color(0xFF795B30),
      );
    }
    canvas.drawLine(
      const Offset(-104, -38),
      const Offset(-8, -38),
      Paint()
        ..color = const Color(0xFF3E2723)
        ..strokeWidth = 2.2,
    );
    canvas.drawLine(
      const Offset(-104, -24),
      const Offset(-8, -24),
      Paint()
        ..color = const Color(0xFF3E2723)
        ..strokeWidth = 2.2,
    );

    // 3. Glowing Turquoise Mineral Hot Spring Pool
    const Rect poolRect = Rect.fromLTWH(-108, -14, 216, 44);
    canvas.drawOval(
      poolRect,
      Paint()
        ..shader = ui.Gradient.radial(
          const Offset(0, 8),
          110,
          [
            const Color(0xFF80DEEA),
            const Color(0xFF26C6DA),
            const Color(0xFF00838F),
          ],
          const [0.0, 0.65, 1.0],
        ),
    );

    // Volcanic boulders rimming the Onsen pool
    const List<Offset> rockOffsets = [
      Offset(-106, 2),
      Offset(-92, -12),
      Offset(-64, -16),
      Offset(-28, -17),
      Offset(14, -17),
      Offset(56, -15),
      Offset(90, -10),
      Offset(106, 4),
      Offset(92, 22),
      Offset(54, 28),
      Offset(0, 30),
      Offset(-54, 28),
      Offset(-92, 22),
    ];
    for (int r = 0; r < rockOffsets.length; r++) {
      final Offset ro = rockOffsets[r];
      canvas.drawOval(
        Rect.fromCenter(center: ro, width: 34, height: 20),
        Paint()
          ..color = r.isEven
              ? const Color(0xFF454D55)
              : const Color(0xFF576069),
      );
      if (r % 3 == 0) {
        canvas.drawOval(
          Rect.fromCenter(
            center: ro.translate(0, -5),
            width: 20,
            height: 8,
          ),
          Paint()..color = const Color(0xFF4CAF50),
        );
      }
    }

    // 3 bathers submerged up to shoulders in steaming mineral water
    _drawOnsenBather(
      canvas,
      const Offset(-52, 2),
      hasHeadTowel: true,
      hasSpeechBubble: true,
    );
    _drawOnsenBather(
      canvas,
      const Offset(-16, 6),
      hasHeadTowel: false,
    );
    _drawOnsenBather(
      canvas,
      const Offset(24, 4),
      hasHeadTowel: true,
    );

    // Cute Capybara with white towel on head on left rock edge
    canvas.save();
    canvas.translate(-78, 8);
    canvas.drawOval(
      const Rect.fromLTWH(-11, -6, 22, 13),
      Paint()..color = const Color(0xFF8D5B3C),
    );
    canvas.drawOval(
      const Rect.fromLTWH(5, -11, 12, 10),
      Paint()..color = const Color(0xFF9C6846),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(6, -14, 9, 3.5),
        const Radius.circular(1.5),
      ),
      Paint()..color = Colors.white,
    );
    canvas.restore();

    // 2 Japanese Snow Monkeys (Nihonzaru) soaking & grooming on right side
    for (int m = 0; m < 2; m++) {
      canvas.save();
      canvas.translate(56.0 + m * 20.0, 4.0 - m * 5.0);
      canvas.drawCircle(
        const Offset(0, 2),
        8.0 - m * 0.8,
        Paint()..color = const Color(0xFFA1887F),
      );
      canvas.drawCircle(
        const Offset(0, -5),
        6.5 - m * 0.5,
        Paint()..color = const Color(0xFFBCAAA4),
      );
      canvas.drawOval(
        const Rect.fromLTWH(-4, -7, 8, 6),
        Paint()..color = const Color(0xFFF48FB1),
      );
      if (m == 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-5, -12, 10, 3.5),
            const Radius.circular(1.5),
          ),
          Paint()..color = Colors.white,
        );
      }
      canvas.restore();
    }

    // Floating wooden Sake tray (Tokkuri carafe & Ochoko cups) on the water
    final double trayBob = math.sin(time * 2.2) * 1.5;
    canvas.save();
    canvas.translate(4, 14 + trayBob);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-10, -2, 20, 5),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFFD7A86E),
    );
    canvas.drawOval(
      const Rect.fromLTWH(-3, -9, 6, 8),
      Paint()..color = const Color(0xFFF5F5F5),
    );
    canvas.drawRect(
      const Rect.fromLTWH(-8, -5, 3.5, 3),
      Paint()..color = const Color(0xFFF5F5F5),
    );
    canvas.drawRect(
      const Rect.fromLTWH(4.5, -5, 3.5, 3),
      Paint()..color = const Color(0xFFF5F5F5),
    );
    canvas.restore();

    // Wooden Hinoki bath buckets stacked on side boulder
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-98, 12, 12, 9),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFFE2B478),
    );
    canvas.drawLine(
      const Offset(-98, 15),
      const Offset(-86, 15),
      Paint()
        ..color = const Color(0xFF5D4037)
        ..strokeWidth = 1.2,
    );

    // 3 People in Yukata robes sitting on the boulders outside the pool (including Shamisen musician)
    _drawArticulatedPerson(
      canvas,
      const Offset(-42, -20),
      scale: 0.90,
      kimonoColor: const Color(0xFF5C6BC0),
      obiColor: const Color(0xFFFFD54F),
      isSeated: true,
    );
    _drawArticulatedPerson(
      canvas,
      const Offset(44, -18),
      scale: 0.92,
      kimonoColor: const Color(0xFFEC407A),
      obiColor: const Color(0xFFFFF176),
      isSeated: true,
      hasSpeechBubble: true,
    );
    _drawArticulatedPerson(
      canvas,
      const Offset(88, -8),
      scale: 0.94,
      kimonoColor: const Color(0xFF26A69A),
      obiColor: const Color(0xFFFFCA28),
      isSeated: true,
      hasShamisen: true,
    );

    _drawStoneToroLantern(canvas, const Offset(112, -4), scale: 0.98);

    // Rising animated Onsen steam clouds
    for (int s = 0; s < 9; s++) {
      final double steamPhase = (time * 0.38 + s * 0.14) % 1.0;
      final double sx = -75.0 + s * 18.5 + math.sin(time * 1.5 + s) * 6.0;
      final double sy = 8.0 - steamPhase * 52.0;
      final double alpha = math.sin(steamPhase * math.pi) * 0.34;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(sx, sy),
          width: 28 + steamPhase * 22,
          height: 16 + steamPhase * 12,
        ),
        Paint()
          ..color = Colors.white.withValues(alpha: alpha.clamp(0.0, 0.4))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    canvas.restore();
  }

  // ===========================================================================
  // 7. 220° ZONE — TWIN WATERFALLS (185°), 14 FUSHIMI INARI TORII GATES (204°..230°),
  //    STONE JIZO STATUES (240°), BRONZE BUDDHA (254°), BONSHO BELL (280°) & 38 BAMBOO STALKS
  // ===========================================================================

  void _drawWaterfallsBuddhaAndToriiPath(
    Canvas canvas,
    Size size,
    double horizonY,
  ) {
    final double span = size.height - horizonY;

    // 1. Twin Cascading Zen Waterfalls at 185° plunging down mossy cliffs
    final double? wfX = _worldAngleToScreenX(185.0, size, margin: 450);
    if (wfX != null) {
      final double wfY = horizonY + span * 0.16;
      canvas.save();
      canvas.translate(wfX, wfY);
      canvas.scale(1.82);

      final Path cliff = Path()
        ..moveTo(-68, 22)
        ..lineTo(-54, -68)
        ..lineTo(54, -68)
        ..lineTo(68, 22)
        ..close();
      canvas.drawPath(cliff, Paint()..color = const Color(0xFF37424A));

      for (double cx in [-22.0, 22.0]) {
        canvas.drawRect(
          Rect.fromLTWH(cx - 10, -66, 20, 86),
          Paint()
            ..shader = ui.Gradient.linear(
              Offset(cx, -66),
              Offset(cx, 20),
              [
                const Color(0xFFE0F7FA),
                const Color(0xFF80DEEA),
                const Color(0xFFE0F7FA),
              ],
              const [0.0, 0.5, 1.0],
            ),
        );
        for (int st = 0; st < 6; st++) {
          final double dropY = -62.0 + ((time * 55.0 + st * 14.0) % 80.0);
          canvas.drawLine(
            Offset(cx - 6.0 + (st % 3) * 6.0, dropY),
            Offset(cx - 6.0 + (st % 3) * 6.0, dropY + 10.0),
            Paint()
              ..color = Colors.white.withValues(alpha: 0.85)
              ..strokeWidth = 1.8,
          );
        }
      }

      canvas.drawOval(
        const Rect.fromLTWH(-52, 12, 104, 18),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.48)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.restore();
    }

    // 2. Winding Mountain Path of 14 Fushimi Inari Vermilion Torii Gates (204°..230°)
    //    Climbing UP from span * 0.21 toward span * 0.11 on the mountain slope!
    for (int g = 13; g >= 0; g--) {
      final double gateDeg = 204.0 + g * (26.0 / 13.0);
      final double? gx = _worldAngleToScreenX(gateDeg, size, margin: 360);
      if (gx == null) continue;

      final double depthT = g / 13.0;
      final double gy = horizonY + span * (0.21 - depthT * 0.10);
      final double gateScale = 1.68 * (1.0 - depthT * 0.36);

      canvas.save();
      canvas.translate(gx, gy);
      canvas.scale(gateScale);

      canvas.drawRect(
        const Rect.fromLTWH(-26, 0, 52, 5),
        Paint()..color = const Color(0xFF8D949B),
      );

      final Color toriiRed = Color.lerp(
        const Color(0xFFD32F2F),
        const Color(0xFF9A1B1B),
        depthT * 0.6,
      )!;
      canvas.drawRect(
        const Rect.fromLTWH(-20, -44, 5.5, 44),
        Paint()..color = toriiRed,
      );
      canvas.drawRect(
        const Rect.fromLTWH(14.5, -44, 5.5, 44),
        Paint()..color = toriiRed,
      );
      canvas.drawRect(
        const Rect.fromLTWH(-20.5, -8, 6.5, 8),
        Paint()..color = const Color(0xFF1E2229),
      );
      canvas.drawRect(
        const Rect.fromLTWH(14.0, -8, 6.5, 8),
        Paint()..color = const Color(0xFF1E2229),
      );

      canvas.drawRect(
        const Rect.fromLTWH(-25, -34, 50, 4.5),
        Paint()..color = toriiRed,
      );
      final Path kasagi = Path()
        ..moveTo(-30, -46)
        ..quadraticBezierTo(0, -42, 30, -46)
        ..lineTo(28, -41)
        ..quadraticBezierTo(0, -38, -28, -41)
        ..close();
      canvas.drawPath(kasagi, Paint()..color = const Color(0xFF21252B));
      canvas.drawRect(
        const Rect.fromLTWH(-27, -42, 54, 3.5),
        Paint()..color = toriiRed,
      );

      if (g == 1 || g == 6 || g == 11) {
        _drawArticulatedPerson(
          canvas,
          Offset(math.sin(time * 2.0 + g) * 4.0, -2),
          scale: 0.72,
          kimonoColor: g == 1
              ? const Color(0xFFF5F5F5)
              : (g == 6 ? const Color(0xFF3949AB) : const Color(0xFFD81B60)),
          obiColor: const Color(0xFFFFB300),
          hasKasaHat: g != 6,
        );
      }

      canvas.restore();
    }

    // 3. Stone Jizo Statues (Ojizo-sama) with crimson bibs & knitted caps at 240°
    final double? jizoX = _worldAngleToScreenX(240.0, size, margin: 320);
    if (jizoX != null) {
      final double jy = horizonY + span * 0.20;
      canvas.save();
      canvas.translate(jizoX, jy);
      canvas.scale(1.80);

      // Mossy stone ledge base
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-42, 2, 84, 10),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xFF5D666E),
      );
      canvas.drawOval(
        const Rect.fromLTWH(-36, -1, 72, 6),
        Paint()..color = const Color(0xFF43A047),
      );

      for (int j = -2; j <= 2; j++) {
        final double jx = j * 15.0;
        final double hScale = 1.0 - (j.abs() * 0.06);
        canvas.save();
        canvas.translate(jx, 2);
        canvas.scale(hScale);

        // Carved grey stone Jizo body & round head
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-5.5, -18, 11, 18),
            const Radius.circular(5),
          ),
          Paint()..color = const Color(0xFF8C969E),
        );
        canvas.drawCircle(
          const Offset(0, -23),
          5.5,
          Paint()..color = const Color(0xFF9EA7AF),
        );
        // Red knitted cap & crimson votive bib (Yodarekake)
        canvas.drawArc(
          const Rect.fromLTWH(-5.5, -29, 11, 8),
          math.pi,
          math.pi,
          true,
          Paint()..color = const Color(0xFFD32F2F),
        );
        final Path bib = Path()
          ..moveTo(-5.5, -18)
          ..quadraticBezierTo(0, -9, 5.5, -18)
          ..close();
        canvas.drawPath(bib, Paint()..color = const Color(0xFFE53935));

        canvas.restore();
      }
      canvas.restore();
    }

    // 4. Giant Meditating Bronze Buddha Statue (Daibutsu) at 254° (1.90x scale)
    final double? buddhaX = _worldAngleToScreenX(254.0, size, margin: 420);
    if (buddhaX != null) {
      final double by = horizonY + span * 0.19;
      canvas.save();
      canvas.translate(buddhaX, by);
      canvas.scale(1.90);

      canvas.drawCircle(
        const Offset(0, -42),
        36,
        Paint()
          ..color = const Color(0xFFFFD54F).withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
      canvas.drawCircle(
        const Offset(0, -42),
        28,
        Paint()
          ..color = const Color(0xFFD4AF37).withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );

      // Stone & bronze lotus pedestal base
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-40, -6, 80, 14),
          const Radius.circular(5),
        ),
        Paint()..color = const Color(0xFF6E787F),
      );

      final Path buddhaBody = Path()
        ..moveTo(-34, -6)
        ..quadraticBezierTo(-32, -32, -16, -42)
        ..lineTo(16, -42)
        ..quadraticBezierTo(32, -32, 34, -6)
        ..close();
      canvas.drawPath(buddhaBody, Paint()..color = const Color(0xFF607D6E));

      canvas.drawCircle(
        const Offset(0, -52),
        11,
        Paint()..color = const Color(0xFF6E8C7D),
      );
      canvas.drawCircle(
        const Offset(0, -63),
        4.5,
        Paint()..color = const Color(0xFF567365),
      );
      canvas.drawLine(
        const Offset(-5, -52),
        const Offset(-2, -52),
        Paint()
          ..color = const Color(0xFF263238)
          ..strokeWidth = 1.2,
      );
      canvas.drawLine(
        const Offset(2, -52),
        const Offset(5, -52),
        Paint()
          ..color = const Color(0xFF263238)
          ..strokeWidth = 1.2,
      );

      canvas.drawRect(
        const Rect.fromLTWH(-6, 4, 12, 6),
        Paint()..color = const Color(0xFF4E342E),
      );
      final Path smoke = Path()
        ..moveTo(0, 4)
        ..quadraticBezierTo(
          math.sin(time * 2.2) * 8.0,
          -12,
          math.cos(time * 1.8) * 6.0,
          -28,
        );
      canvas.drawPath(
        smoke,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );

      canvas.restore();
    }

    // 5. Temple Bell Pavilion (Bonsho) at 280° (1.85x scale) with a monk swinging the striker beam
    final double? bellX = _worldAngleToScreenX(280.0, size, margin: 380);
    if (bellX != null) {
      final double bellY = horizonY + span * 0.19;
      canvas.save();
      canvas.translate(bellX, bellY);
      canvas.scale(1.85);

      canvas.drawRect(
        const Rect.fromLTWH(-34, 2, 68, 8),
        Paint()..color = const Color(0xFF6C757D),
      );
      canvas.drawRect(
        const Rect.fromLTWH(-28, -46, 5, 50),
        Paint()..color = const Color(0xFF4E2C18),
      );
      canvas.drawRect(
        const Rect.fromLTWH(23, -46, 5, 50),
        Paint()..color = const Color(0xFF4E2C18),
      );
      final Path bellRoof = Path()
        ..moveTo(-42, -44)
        ..quadraticBezierTo(0, -64, 42, -44)
        ..lineTo(34, -39)
        ..lineTo(-34, -39)
        ..close();
      canvas.drawPath(bellRoof, Paint()..color = const Color(0xFF262D36));

      // Giant Bronze Temple Bell (Bonsho)
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-11, -35, 22, 26),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xFF5D6D5E),
      );

      // Animated swinging wooden Shumoku striker beam & Monk pulling the rope
      final double swingX = math.sin(time * 2.5) * 4.5;
      canvas.drawLine(
        Offset(18 + swingX * 0.5, -39),
        Offset(18 + swingX, -22),
        Paint()
          ..color = const Color(0xFFD7B377)
          ..strokeWidth = 1.2,
      );
      canvas.drawLine(
        Offset(6 + swingX, -22),
        Offset(32 + swingX, -22),
        Paint()
          ..color = const Color(0xFF8D6E63)
          ..strokeWidth = 4.2
          ..strokeCap = StrokeCap.round,
      );

      _drawArticulatedPerson(
        canvas,
        const Offset(26, 2),
        scale: 0.84,
        kimonoColor: const Color(0xFF37474F),
        obiColor: const Color(0xFFE0A94F),
      );

      canvas.restore();
    }
  }

  void _drawBambooGroveAndSakuraMomijiTrees(
    Canvas canvas,
    Size size,
    double horizonY,
  ) {
    final double span = size.height - horizonY;

    // 38 Towering Arashiyama Green Bamboo Stalks (1.4x..1.9x scale) across 186°..294°
    for (int b = 0; b < 38; b++) {
      final double deg = 186.0 + (b * 108.0 / 38.0);
      final double? bx = _worldAngleToScreenX(deg, size, margin: 220);
      if (bx == null) continue;

      final double yFactor = 0.10 + (b % 5) * 0.04;
      final double by = horizonY + span * yFactor;
      final double scale = 1.42 + (b % 4) * 0.16;
      final double sway = math.sin(time * 1.4 + b * 0.7) * 5.0;

      canvas.save();
      canvas.translate(bx, by);
      canvas.scale(scale);

      final Color stalkColor = b.isEven
          ? const Color(0xFF43A047)
          : const Color(0xFF2E7D32);

      double curX = 0;
      double curY = 0;
      for (int seg = 0; seg < 6; seg++) {
        final double nextX = curX + sway * (seg + 1) * 0.12;
        final double nextY = curY - 16.0;
        canvas.drawLine(
          Offset(curX, curY),
          Offset(nextX, nextY),
          Paint()
            ..color = stalkColor
            ..strokeWidth = 4.2 - seg * 0.35
            ..strokeCap = StrokeCap.butt,
        );
        canvas.drawLine(
          Offset(nextX - 2.6, nextY),
          Offset(nextX + 2.6, nextY),
          Paint()
            ..color = const Color(0xFFA5D6A7)
            ..strokeWidth = 1.4,
        );
        if (seg >= 2) {
          final double side = (seg.isEven ? 1.0 : -1.0);
          for (int lf = 0; lf < 3; lf++) {
            canvas.save();
            canvas.translate(nextX, nextY);
            canvas.rotate(side * (0.4 + lf * 0.28));
            canvas.drawOval(
              Rect.fromLTWH(0, -1.8, 13.0 * side, 3.6),
              Paint()..color = const Color(0xFF66BB6A),
            );
            canvas.restore();
          }
        }
        curX = nextX;
        curY = nextY;
      }

      canvas.restore();
    }

    // 14 Weeping Pink Sakura & Red Autumn Maple (Momiji) Trees framing the 360° valley
    const List<double> treeAngles = [
      24.0,
      56.0,
      84.0,
      104.0,
      124.0,
      144.0,
      159.0,
      176.0,
      198.0,
      234.0,
      268.0,
      298.0,
      318.0,
      342.0,
    ];

    for (int t = 0; t < treeAngles.length; t++) {
      final double? tx = _worldAngleToScreenX(
        treeAngles[t],
        size,
        margin: 340,
      );
      if (tx == null) continue;

      final double yFactor = 0.14 + (t % 4) * 0.04;
      final double ty = horizonY + span * yFactor;
      final double scale = 1.55 + (t % 3) * 0.15;
      final bool isSakura = t % 3 != 1;

      canvas.save();
      canvas.translate(tx, ty);
      canvas.scale(scale);

      final Path trunk = Path()
        ..moveTo(-7, 6)
        ..quadraticBezierTo(-4, -18, -2, -40)
        ..lineTo(-22, -56)
        ..moveTo(0, -38)
        ..lineTo(24, -58)
        ..moveTo(2, -40)
        ..quadraticBezierTo(4, -18, 7, 6);
      canvas.drawPath(
        trunk,
        Paint()
          ..color = const Color(0xFF3E2723)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.5
          ..strokeCap = StrokeCap.round,
      );

      final Color mainFoliage = isSakura
          ? const Color(0xFFF8BBD0)
          : const Color(0xFFD84315);
      final Color highlightFoliage = isSakura
          ? const Color(0xFFFCE4EC)
          : const Color(0xFFFF7043);
      final Color shadowFoliage = isSakura
          ? const Color(0xFFF06292)
          : const Color(0xFFBF360C);

      const List<Rect> canopyBlobs = [
        Rect.fromLTWH(-44, -68, 42, 28),
        Rect.fromLTWH(2, -68, 42, 28),
        Rect.fromLTWH(-28, -84, 56, 34),
        Rect.fromLTWH(-36, -54, 72, 24),
      ];
      for (final Rect r in canopyBlobs) {
        canvas.drawOval(
          r.shift(const Offset(0, 3)),
          Paint()..color = shadowFoliage,
        );
        canvas.drawOval(r, Paint()..color = mainFoliage);
        canvas.drawOval(
          r.deflate(5).shift(const Offset(-2, -3)),
          Paint()..color = highlightFoliage,
        );
      }

      canvas.restore();
    }
  }

  // ===========================================================================
  // 8. FOREGROUND SHORE DETAILS & 80 DRIFTING SAKURA PETALS
  // ===========================================================================

  void _drawForegroundShoreDetails(Canvas canvas, Size size, double horizonY) {
    final double span = size.height - horizonY;

    // 1. Mid-ring shoreline & walkway border stones along span * 0.33..0.35
    for (int i = 0; i < 16; i++) {
      final double deg = i * 22.5;
      final double? sx = _worldAngleToScreenX(deg, size, margin: 160);
      if (sx == null) continue;

      final double sy = horizonY + span * (0.33 + (i % 2) * 0.02);
      canvas.save();
      canvas.translate(sx, sy);
      canvas.scale(1.35);

      canvas.drawOval(
        const Rect.fromLTWH(-16, -5, 32, 11),
        Paint()..color = const Color(0xFF4A555E),
      );
      canvas.drawOval(
        const Rect.fromLTWH(-11, -7, 22, 6),
        Paint()..color = const Color(0xFF43A047),
      );
      canvas.restore();
    }

    // 2. 10 Small Foreground Kyoto Ground Details (flat mossy stepping stones,
    //    fallen sakura petal clusters, small glowing ground lanterns, tiny mossy pebbles)
    //    at horizonY + span * (0.50 .. 0.82), skipping any screen X within 145px of center!
    for (int i = 0; i < 10; i++) {
      final double deg = i * 36.0 + 14.0;
      final double? sx = _worldAngleToScreenX(deg, size, margin: 120);
      if (sx == null) continue;
      if ((sx - size.width * 0.5).abs() < 145.0) continue;

      final double yFactor = 0.50 + (i % 4) * 0.095;
      final double sy = horizonY + span * yFactor;

      canvas.save();
      canvas.translate(sx, sy);

      if (i % 3 == 0) {
        // Flat mossy Kyoto stepping stone (Tobi-ishi) with fallen sakura petals
        canvas.drawOval(
          const Rect.fromLTWH(-22, -7, 44, 15),
          Paint()..color = const Color(0xFF56616A),
        );
        canvas.drawOval(
          const Rect.fromLTWH(-18, -6, 36, 11),
          Paint()..color = const Color(0xFF6E7982),
        );
        canvas.drawOval(
          const Rect.fromLTWH(-14, -8, 18, 6),
          Paint()..color = const Color(0xFF438A4E),
        );
        canvas.drawOval(
          const Rect.fromLTWH(6, -2, 6, 3.5),
          Paint()..color = const Color(0xFFF8BBD0),
        );
      } else if (i % 3 == 1) {
        // Cluster of dark river pebbles & fallen pink sakura petals on the moss
        canvas.drawOval(
          const Rect.fromLTWH(-14, -4, 16, 8),
          Paint()..color = const Color(0xFF3E4750),
        );
        canvas.drawOval(
          const Rect.fromLTWH(2, -2, 11, 6),
          Paint()..color = const Color(0xFF525C65),
        );
        for (final Offset po in [
          const Offset(-6, 4),
          const Offset(8, -5),
          const Offset(12, 3),
        ]) {
          canvas.drawOval(
            Rect.fromCenter(center: po, width: 6.5, height: 4.0),
            Paint()..color = const Color(0xFFF48FB1),
          );
        }
      } else {
        // Small low mossy garden Oki-doro ground lantern
        canvas.drawOval(
          const Rect.fromLTWH(-12, 0, 24, 8),
          Paint()..color = const Color(0xFF4A545C),
        );
        canvas.drawRect(
          const Rect.fromLTWH(-5, -9, 10, 9),
          Paint()..color = const Color(0xFFFFE082),
        );
        final Path cap = Path()
          ..moveTo(-10, -9)
          ..quadraticBezierTo(0, -16, 10, -9)
          ..close();
        canvas.drawPath(cap, Paint()..color = const Color(0xFF5C666E));
      }

      canvas.restore();
    }
  }

  void _drawDriftingSakuraPetals(Canvas canvas, Size size, double horizonY) {
    final Paint petalPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 80; i++) {
      final double worldDeg =
          (i * 4.5 + time * (4.0 + (i % 5) * 0.9)) % 360.0;
      final double? px = _worldAngleToScreenX(worldDeg, size, margin: 80);
      if (px == null) continue;

      final double fallCycle =
          ((time * (0.07 + (i % 4) * 0.018)) + i * 0.13) % 1.0;
      final double py =
          fallCycle * size.height * 0.92 + math.sin(time * 2.4 + i) * 10.0;
      final double rot = time * 2.2 + i;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(rot);

      petalPaint.color = (i.isEven
              ? const Color(0xFFF8BBD0)
              : const Color(0xFFF48FB1))
          .withValues(alpha: 0.88);

      final Path petal = Path()
        ..moveTo(0, -4.5)
        ..quadraticBezierTo(4.2, -1.5, 2.0, 4.0)
        ..lineTo(0, 2.2)
        ..lineTo(-2.0, 4.0)
        ..quadraticBezierTo(-4.2, -1.5, 0, -4.5)
        ..close();
      canvas.drawPath(petal, petalPaint);
      canvas.restore();
    }
  }

  // ===========================================================================
  // 9. CENTER FOREGROUND OBJECT — SACRED JAPANESE IWAKURA / SUISEKI
  //    MULTI-BOULDER TEMPLE ROCK FORMATION (_drawCenterMossyRock)
  // ===========================================================================

  void _drawCenterMossyRock(Canvas canvas, Size size, double horizonY) {
    final double cx = size.width * 0.5;
    final double cy = size.height * 0.845;
    final double pulseScale =
        1.0 + coconutPulse * 0.08 + math.sin(time * 1.8) * 0.006;
    final double baseScale = (math.min(size.width, size.height) / 900.0).clamp(
      0.78,
      1.05,
    );
    final double totalScale =
        baseScale * pulseScale * (0.9 + 0.1 * cameraZoom.clamp(0.85, 1.35));

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(totalScale);

    // 1. Directional Radial Ground Shadow on the mossy Kyoto earth (rotates with -cameraYaw like CoconutWorldPainter)
    final double sunRelativeRad = (-cameraYaw) * math.pi / 180.0;
    final double shadowOffsetX = -math.sin(sunRelativeRad) * 26.0;
    final double shadowOffsetY = 18.0 + math.cos(sunRelativeRad) * 8.0;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(shadowOffsetX, shadowOffsetY),
        width: 276.0,
        height: 64.0,
      ),
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(shadowOffsetX, shadowOffsetY),
          138.0,
          [
            const Color(0xFF091812).withValues(alpha: 0.65),
            const Color(0xFF122B20).withValues(alpha: 0.32),
            Colors.transparent,
          ],
          const [0.0, 0.62, 1.0],
        ),
    );

    // Subtle ambient contact shadow directly under the rock base
    canvas.drawOval(
      const Rect.fromLTWH(-122, 4, 244, 34),
      Paint()
        ..color = const Color(0xFF07130E).withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // 2. Sculpted Multi-Boulder Iwakura / Suiseki Formation (-116..+116 wide, rising to -130 tall)
    // Left Wing Boulder (supporting the bamboo Kakei water spout & carved rock basin)
    final Path leftBoulder = Path()
      ..moveTo(-114, 18)
      ..cubicTo(-122, -8, -112, -48, -86, -74)
      ..cubicTo(-64, -92, -38, -82, -28, -48)
      ..lineTo(-34, 20)
      ..close();
    canvas.drawPath(
      leftBoulder,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(-108, -80),
          const Offset(-35, 22),
          [
            const Color(0xFF66727C),
            const Color(0xFF454E57),
            const Color(0xFF2B3238),
          ],
          const [0.0, 0.55, 1.0],
        ),
    );

    // Right Wing Boulder (terraced meditation ledge boulder)
    final Path rightBoulder = Path()
      ..moveTo(26, 20)
      ..lineTo(34, -56)
      ..cubicTo(52, -86, 82, -82, 104, -52)
      ..cubicTo(118, -26, 120, -2, 112, 18)
      ..close();
    canvas.drawPath(
      rightBoulder,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(40, -82),
          const Offset(112, 20),
          [
            const Color(0xFF606B75),
            const Color(0xFF3E4750),
            const Color(0xFF242A30),
          ],
          const [0.0, 0.55, 1.0],
        ),
    );

    // Towering Central Sacred Iwakura Peak Boulder (rising to -130)
    final Path centralPeak = Path()
      ..moveTo(-76, 22)
      ..cubicTo(-84, -14, -66, -74, -36, -112)
      ..cubicTo(-14, -132, 16, -132, 38, -108)
      ..cubicTo(66, -70, 80, -14, 74, 22)
      ..cubicTo(34, 32, -34, 32, -76, 22)
      ..close();
    canvas.drawPath(
      centralPeak,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(-42, -130),
          const Offset(56, 26),
          [
            const Color(0xFF75818B),
            const Color(0xFF4D5760),
            const Color(0xFF2B3239),
          ],
          const [0.0, 0.52, 1.0],
        ),
    );

    // Chiseled 3D rock facets & natural granite crevices
    final Path leftPeakFacet = Path()
      ..moveTo(-66, 16)
      ..lineTo(-42, -74)
      ..lineTo(-6, -124)
      ..lineTo(-8, -22)
      ..lineTo(-32, 22)
      ..close();
    canvas.drawPath(
      leftPeakFacet,
      Paint()..color = const Color(0xFF88949E).withValues(alpha: 0.34),
    );

    final Path rightPeakShadowFacet = Path()
      ..moveTo(-6, -124)
      ..lineTo(36, -104)
      ..lineTo(66, 14)
      ..lineTo(18, 24)
      ..lineTo(-8, -22)
      ..close();
    canvas.drawPath(
      rightPeakShadowFacet,
      Paint()..color = const Color(0xFF1F252B).withValues(alpha: 0.42),
    );

    // Natural dark rock crevices
    final Paint crevicePaint = Paint()
      ..color = const Color(0xFF1B2026).withValues(alpha: 0.68)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(-34, -84)
        ..lineTo(-18, -42)
        ..lineTo(-28, 4),
      crevicePaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(24, -74)
        ..lineTo(14, -26)
        ..lineTo(30, 8),
      crevicePaint,
    );

    // 3. Small Carved Stone Steps ascending the front-right base of the boulder
    for (int st = 0; st < 4; st++) {
      final double sx = 26.0 - st * 8.0;
      final double sy = 18.0 - st * 7.5;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(sx, sy), width: 22, height: 6.0),
          const Radius.circular(2.5),
        ),
        Paint()..color = const Color(0xFF8A949D),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(sx, sy - 1.2),
            width: 20,
            height: 3.0,
          ),
          const Radius.circular(2.0),
        ),
        Paint()..color = const Color(0xFFB0B9C2),
      );
    }

    // 4. Lush Multi-Layered Velvet Green Moss Cushions draping the boulders
    const List<Rect> mossCushions = [
      Rect.fromLTWH(-36, -130, 72, 30), // Crown summit moss
      Rect.fromLTWH(-64, -96, 66, 28), // Upper-left shoulder moss
      Rect.fromLTWH(8, -92, 62, 26), // Upper-right shoulder moss
      Rect.fromLTWH(-104, -76, 60, 26), // Left boulder crest moss
      Rect.fromLTWH(44, -72, 62, 26), // Right boulder crest moss
      Rect.fromLTWH(-112, -26, 50, 22), // Left mid ledge moss
      Rect.fromLTWH(56, -24, 54, 24), // Right mid ledge moss
      Rect.fromLTWH(-52, 2, 64, 22), // Base apron moss
    ];
    for (final Rect mr in mossCushions) {
      canvas.drawOval(
        mr.shift(const Offset(0, 3)),
        Paint()..color = const Color(0xFF1B5E20),
      );
      canvas.drawOval(
        mr,
        Paint()
          ..shader = ui.Gradient.linear(
            mr.topCenter,
            mr.bottomCenter,
            [const Color(0xFF7CB342), const Color(0xFF338A3E)],
          ),
      );
      canvas.drawOval(
        mr.deflate(6).shift(const Offset(-3, -3)),
        Paint()..color = const Color(0xFF9CCC65).withValues(alpha: 0.78),
      );
    }

    // 5. Miniature Bamboo Water Spout (Kakei) on the left ledge trickling into a carved rock basin
    // Carved stone water basin (Tsukubai ledge) on left boulder
    canvas.drawOval(
      const Rect.fromLTWH(-98, -18, 44, 16),
      Paint()..color = const Color(0xFF374047),
    );
    canvas.drawOval(
      const Rect.fromLTWH(-92, -15, 32, 11),
      Paint()..color = const Color(0xFF26C6DA),
    );
    // Bamboo upright post & angled Kakei spout pipe
    canvas.drawLine(
      const Offset(-108, -8),
      const Offset(-108, -46),
      Paint()
        ..color = const Color(0xFF689F38)
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      const Offset(-110, -38),
      const Offset(-80, -28),
      Paint()
        ..color = const Color(0xFF8BC34A)
        ..strokeWidth = 4.2
        ..strokeCap = StrokeCap.round,
    );
    // Animated crystal water stream & falling droplets into the rock basin
    canvas.drawLine(
      const Offset(-80, -27),
      const Offset(-76, -9),
      Paint()
        ..color = const Color(0xFFB2EBF2).withValues(alpha: 0.85)
        ..strokeWidth = 2.0,
    );
    for (int d = 0; d < 3; d++) {
      final double dropT = (time * 3.2 + d * 0.33) % 1.0;
      canvas.drawCircle(
        Offset(-80 + dropT * 4.0, -27 + dropT * 18.0),
        1.8,
        Paint()..color = Colors.white,
      );
    }
    // Expanding white splash ripple inside the carved rock basin
    final double basinRipple = (time * 1.8) % 1.0;
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(-76, -9),
        width: 8 + basinRipple * 16,
        height: 3 + basinRipple * 5,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: (1.0 - basinRipple) * 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // 6. Blooming Pink Azalea / Sakura Sprigs & Fallen Sakura Petals on the rock
    for (final Offset azPos in [
      const Offset(-54, -76),
      const Offset(64, -54),
      const Offset(-82, 6),
      const Offset(74, 8),
    ]) {
      for (int p = 0; p < 3; p++) {
        canvas.drawCircle(
          azPos.translate((p - 1) * 5.5, (p.isEven ? -2.0 : 2.0)),
          4.2,
          Paint()
            ..color = p == 1
                ? const Color(0xFFFCE4EC)
                : const Color(0xFFF06292),
        );
      }
    }

    for (final Offset po in [
      const Offset(-28, -92),
      const Offset(24, -84),
      const Offset(-58, -32),
      const Offset(54, -18),
    ]) {
      canvas.drawOval(
        Rect.fromCenter(center: po, width: 8, height: 5),
        Paint()..color = const Color(0xFFF8BBD0),
      );
    }

    // 7. Style-Specific Customizations (natural, arcade, cocktail, king, lofi)
    final CoconutStyleMode activeStyle =
        isArcadeMode && styleMode == CoconutStyleMode.natural
        ? CoconutStyleMode.arcade
        : styleMode;

    switch (activeStyle) {
      case CoconutStyleMode.natural:
        _drawNaturalRockDetails(canvas);
        break;
      case CoconutStyleMode.arcade:
        _drawArcadeRockDetails(canvas);
        break;
      case CoconutStyleMode.cocktail:
        _drawShimenawaShrineRockDetails(canvas);
        break;
      case CoconutStyleMode.king:
        _drawSakuraSpiritKingDetails(canvas);
        break;
      case CoconutStyleMode.lofi:
        _drawLofiZenMasterDetails(canvas);
        break;
    }

    // 8. Ground Integration Nest (mossNest & river pebbles tucked over the bottom edge y = 6..28,
    //    painted in the exact foreground mossy earth tones so the boulder sits embedded in the ground!)
    final Color turfBase = atmosphereMode == CoconutAtmosphereMode.night
        ? const Color(0xFF16382E)
        : (atmosphereMode == CoconutAtmosphereMode.noon
              ? const Color(0xFF2E693E)
              : (atmosphereMode == CoconutAtmosphereMode.rain
                    ? const Color(0xFF26453A)
                    : const Color(0xFF2D5039)));
    final Color turfHighlight = atmosphereMode == CoconutAtmosphereMode.night
        ? const Color(0xFF1F4B3E)
        : const Color(0xFF3A6B44);

    final Path mossNest = Path()
      ..moveTo(-124, 18)
      ..quadraticBezierTo(-82, 4, -38, 15)
      ..quadraticBezierTo(0, 6, 40, 15)
      ..quadraticBezierTo(84, 5, 122, 18)
      ..quadraticBezierTo(60, 32, 0, 30)
      ..quadraticBezierTo(-60, 32, -124, 18)
      ..close();
    canvas.drawPath(mossNest, Paint()..color = turfBase);

    // Secondary soft mossy turf mounds & dark basalt river pebbles embedding the rock base
    for (final Rect mound in [
      const Rect.fromLTWH(-112, 10, 56, 16),
      const Rect.fromLTWH(-34, 12, 68, 16),
      const Rect.fromLTWH(52, 10, 58, 16),
    ]) {
      canvas.drawOval(mound, Paint()..color = turfHighlight);
    }

    for (final Rect pebble in [
      const Rect.fromLTWH(-94, 14, 18, 9),
      const Rect.fromLTWH(-46, 18, 15, 8),
      const Rect.fromLTWH(28, 17, 19, 9),
      const Rect.fromLTWH(82, 14, 16, 8),
    ]) {
      canvas.drawOval(pebble, Paint()..color = const Color(0xFF3B444C));
    }

    // Fallen pink sakura petals resting in the mossy nest at the base of the rock
    for (final Offset basePetal in [
      const Offset(-72, 20),
      const Offset(-12, 22),
      const Offset(54, 21),
    ]) {
      canvas.drawOval(
        Rect.fromCenter(center: basePetal, width: 7.5, height: 4.5),
        Paint()..color = const Color(0xFFF8BBD0),
      );
    }

    canvas.restore();
  }

  void _drawNaturalRockDetails(Canvas canvas) {
    // Delicate green fern frond sprouting from upper-left moss cushion
    final Path fernStem = Path()
      ..moveTo(-42, -98)
      ..quadraticBezierTo(-62, -122, -52, -142);
    canvas.drawPath(
      fernStem,
      Paint()
        ..color = const Color(0xFF558B2F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
    for (int f = 1; f <= 5; f++) {
      final double fy = -100.0 - f * 7.5;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(-62, fy), width: 11, height: 4.5),
        Paint()..color = const Color(0xFF8BC34A),
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(-48, fy), width: 11, height: 4.5),
        Paint()..color = const Color(0xFF8BC34A),
      );
    }

    // Cute breathing green tree frog (Amagaeru) perched atop the summit moss cushion
    final double throatPulse = 1.0 + math.sin(time * 4.5) * 0.22;
    canvas.save();
    canvas.translate(8, -126);
    canvas.drawOval(
      const Rect.fromLTWH(-13, -8, 26, 16),
      Paint()..color = const Color(0xFF66BB6A),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0, 1),
        width: 12 * throatPulse,
        height: 8.5 * throatPulse,
      ),
      Paint()..color = const Color(0xFFC8E6C9),
    );
    for (double ex in [-6.5, 6.5]) {
      canvas.drawCircle(
        Offset(ex, -8),
        4.4,
        Paint()..color = const Color(0xFF43A047),
      );
      canvas.drawCircle(
        Offset(ex, -8.5),
        2.5,
        Paint()..color = Colors.black,
      );
      canvas.drawCircle(
        Offset(ex - 0.8, -9.5),
        0.9,
        Paint()..color = Colors.white,
      );
    }
    canvas.restore();

    // Animated Hovering Iridescent Blue-Green Dragonfly (Haguro-tonbo) near the bamboo water spout
    final double dfX = -68.0 + math.sin(time * 2.8) * 14.0;
    final double dfY = -104.0 + math.cos(time * 3.6) * 8.0;
    final double wingBuzz = math.sin(time * 28.0) * 0.25;
    canvas.save();
    canvas.translate(dfX, dfY);
    canvas.rotate(-0.18 + math.sin(time * 2.0) * 0.08);

    // Translucent iridescent wings (4 wings)
    for (double side in [-1.0, 1.0]) {
      for (double pair in [-0.22, 0.22]) {
        canvas.save();
        canvas.rotate(side * (0.45 + pair + wingBuzz));
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(side * 12.0, 0),
            width: 22,
            height: 4.5,
          ),
          Paint()
            ..color = const Color(0xFF80DEEA).withValues(alpha: 0.68),
        );
        canvas.restore();
      }
    }
    // Metallic emerald-teal dragonfly abdomen, thorax & head
    canvas.drawLine(
      const Offset(0, -5),
      const Offset(0, 16),
      Paint()
        ..color = const Color(0xFF00BFA5)
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      const Offset(0, -6),
      3.2,
      Paint()..color = const Color(0xFF00897B),
    );
    canvas.restore();
  }

  void _drawArcadeRockDetails(Canvas canvas) {
    // Red Karate Headband (Hachimaki) tied around the central peak boulder with fluttering tails
    final Path headband = Path()
      ..moveTo(-66, -74)
      ..quadraticBezierTo(0, -60, 66, -74)
      ..lineTo(62, -86)
      ..quadraticBezierTo(0, -72, -62, -86)
      ..close();
    canvas.drawPath(headband, Paint()..color = const Color(0xFFD32F2F));

    final double tailWave = math.sin(time * 6.0) * 6.0;
    canvas.drawCircle(
      const Offset(64, -79),
      7.0,
      Paint()..color = const Color(0xFFB71C1C),
    );
    final Path tail1 = Path()
      ..moveTo(66, -79)
      ..quadraticBezierTo(88, -88 + tailWave, 108, -76 - tailWave);
    final Path tail2 = Path()
      ..moveTo(66, -77)
      ..quadraticBezierTo(86, -66 - tailWave, 104, -56 + tailWave);
    canvas.drawPath(
      tail1,
      Paint()
        ..color = const Color(0xFFE53935)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      tail2,
      Paint()
        ..color = const Color(0xFFC62828)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.2
        ..strokeCap = StrokeCap.round,
    );

    // Cool Aviator / Pixel Sunglasses
    final Paint framePaint = Paint()..color = const Color(0xFF111418);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-54, -58, 46, 25),
        const Radius.circular(5),
      ),
      framePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(8, -58, 46, 25),
        const Radius.circular(5),
      ),
      framePaint,
    );
    canvas.drawRect(const Rect.fromLTWH(-8, -54, 16, 4), framePaint);

    final Paint glarePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      const Offset(-44, -52),
      const Offset(-32, -40),
      glarePaint,
    );
    canvas.drawLine(const Offset(16, -52), const Offset(28, -40), glarePaint);

    final Path smile = Path()
      ..moveTo(-24, -18)
      ..quadraticBezierTo(0, -2, 24, -18);
    canvas.drawPath(
      smile,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.6
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawShimenawaShrineRockDetails(Canvas canvas) {
    // Sacred Shimenawa braided rice-straw rope tied around the central peak
    for (int seg = -5; seg <= 5; seg++) {
      final double sx = seg * 13.5;
      final double sy = -52.0 + (seg * seg) * 0.25;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(sx, sy), width: 18, height: 10),
        Paint()
          ..color = seg.isEven
              ? const Color(0xFFD7B377)
              : const Color(0xFFC29B5C),
      );
    }

    for (double sx in [-46.0, -15.0, 15.0, 46.0]) {
      final Path shide = Path()
        ..moveTo(sx, -46)
        ..lineTo(sx - 5, -36)
        ..lineTo(sx + 4, -36)
        ..lineTo(sx - 6, -26)
        ..lineTo(sx + 3, -26)
        ..lineTo(sx - 2, -16);
      canvas.drawPath(
        shide,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.6
          ..strokeJoin = StrokeJoin.miter,
      );
    }

    _drawStoneToroLantern(canvas, const Offset(0, -124), scale: 1.08);
  }

  void _drawSakuraSpiritKingDetails(Canvas canvas) {
    canvas.drawCircle(
      const Offset(0, -56),
      132,
      Paint()
        ..color = const Color(0xFFFFD54F).withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );

    final Path bonsaiBranch = Path()
      ..moveTo(-8, -122)
      ..quadraticBezierTo(-24, -150, -48, -154)
      ..moveTo(-4, -124)
      ..quadraticBezierTo(12, -156, 46, -160)
      ..moveTo(0, -140)
      ..lineTo(0, -170);
    canvas.drawPath(
      bonsaiBranch,
      Paint()
        ..color = const Color(0xFF4E342E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.5
        ..strokeCap = StrokeCap.round,
    );

    for (final Offset bo in [
      const Offset(-46, -156),
      const Offset(-18, -162),
      const Offset(8, -170),
      const Offset(42, -160),
    ]) {
      canvas.drawOval(
        Rect.fromCenter(center: bo, width: 38, height: 22),
        Paint()..color = const Color(0xFFF48FB1),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: bo.translate(-2, -3),
          width: 26,
          height: 14,
        ),
        Paint()..color = const Color(0xFFFCE4EC),
      );
    }

    final Paint runeGlow = Paint()
      ..color = const Color(0xFF64FFDA)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final Paint runeCore = Paint()
      ..color = const Color(0xFFE0F2F1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;

    for (final Offset eye in [const Offset(-26, -54), const Offset(26, -54)]) {
      canvas.drawCircle(eye, 7, runeGlow);
      canvas.drawCircle(eye, 5, runeCore);
    }
    canvas.drawCircle(const Offset(0, -32), 8, runeGlow);
    canvas.drawCircle(const Offset(0, -32), 6, runeCore);

    for (int b = 0; b < 2; b++) {
      final double angle = time * 2.4 + b * math.pi;
      final Offset bPos = Offset(
        math.cos(angle) * 76.0,
        -138.0 + math.sin(angle * 2.0) * 14.0,
      );
      final double wingFlap = 0.4 + 0.6 * math.sin(time * 12.0 + b).abs();
      canvas.save();
      canvas.translate(bPos.dx, bPos.dy);
      canvas.scale(wingFlap, 1.0);
      canvas.drawOval(
        const Rect.fromLTWH(-8, -6, 7, 10),
        Paint()..color = const Color(0xFFFFD54F),
      );
      canvas.drawOval(
        const Rect.fromLTWH(1, -6, 7, 10),
        Paint()..color = const Color(0xFFFFD54F),
      );
      canvas.restore();
    }
  }

  void _drawLofiZenMasterDetails(Canvas canvas) {
    final Path headbandArc = Path()
      ..addArc(
        const Rect.fromLTWH(-84, -138, 168, 106),
        math.pi * 1.08,
        math.pi * 0.84,
      );
    canvas.drawPath(
      headbandArc,
      Paint()
        ..color = const Color(0xFF263238)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7.5
        ..strokeCap = StrokeCap.round,
    );

    for (double side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(side * 78.0, -56.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-10, -22, 20, 44),
          const Radius.circular(9),
        ),
        Paint()..color = const Color(0xFF37474F),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-6, -16, 12, 32),
          const Radius.circular(6),
        ),
        Paint()..color = const Color(0xFFFF7043),
      );
      canvas.restore();
    }

    final Path kasaHat = Path()
      ..moveTo(-78, -112)
      ..quadraticBezierTo(0, -162, 78, -112)
      ..quadraticBezierTo(0, -104, -78, -112)
      ..close();
    canvas.drawPath(kasaHat, Paint()..color = const Color(0xFFD7B377));
    canvas.drawPath(
      kasaHat,
      Paint()
        ..color = const Color(0xFF8D6E3F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    canvas.save();
    canvas.translate(74, -68);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-10, -14, 20, 18),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF4DB6AC),
    );
    final Path steam = Path()
      ..moveTo(0, -16)
      ..quadraticBezierTo(
        math.sin(time * 3.0) * 5.0,
        -26,
        math.cos(time * 2.5) * 4.0,
        -36,
      );
    canvas.drawPath(
      steam,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  // ===========================================================================
  // 10. WEATHER & ATMOSPHERIC OVERLAYS
  // ===========================================================================

  void _drawAtmosphericOverlays(Canvas canvas, Size size, double horizonY) {
    if (atmosphereMode == CoconutAtmosphereMode.rain) {
      final Paint rainPaint = Paint()
        ..color = const Color(0xFFD0E8F2).withValues(alpha: 0.42)
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < 85; i++) {
        final double rx =
            ((i * 47.0 - time * 110.0) % (size.width + 80)) - 40.0;
        final double ry =
            ((i * 73.0 + time * 460.0) % (size.height + 60)) - 30.0;
        canvas.drawLine(Offset(rx, ry), Offset(rx - 7, ry + 24), rainPaint);
      }

      for (int r = 0; r < 18; r++) {
        final double phase = (time * 1.4 + r * 0.21) % 1.0;
        final double rx = (r * 67.0) % size.width;
        final double ry =
            horizonY + 24.0 + ((r * 43.0) % (size.height - horizonY - 40));
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(rx, ry),
            width: 8 + phase * 26,
            height: 3 + phase * 9,
          ),
          Paint()
            ..color = Colors.white.withValues(alpha: (1.0 - phase) * 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0,
        );
      }
    } else if (atmosphereMode == CoconutAtmosphereMode.night) {
      for (int f = 0; f < 34; f++) {
        final double deg = (f * 10.6 + math.sin(time * 0.8 + f) * 5.0) % 360.0;
        final double? fx = _worldAngleToScreenX(deg, size, margin: 60);
        if (fx == null) continue;
        final double fy =
            horizonY +
            (size.height - horizonY) * (0.14 + (f % 6) * 0.13) +
            math.cos(time * 2.0 + f) * 8.0;
        final double glow = 0.4 + 0.6 * math.sin(time * 3.8 + f * 1.3).abs();

        canvas.drawCircle(
          Offset(fx, fy),
          6.0 * glow,
          Paint()
            ..color = const Color(0xFFB2FF59).withValues(alpha: 0.38 * glow)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
        canvas.drawCircle(
          Offset(fx, fy),
          1.8,
          Paint()..color = const Color(0xFFF4FF81),
        );
      }
    } else if (atmosphereMode == CoconutAtmosphereMode.noon) {
      final double? sunX = _worldAngleToScreenX(0.0, size, margin: 500);
      if (sunX != null) {
        for (int b = -2; b <= 2; b++) {
          final Path beam = Path()
            ..moveTo(sunX + b * 24.0, 0)
            ..lineTo(sunX + b * 115.0 - 45.0, size.height)
            ..lineTo(sunX + b * 115.0 + 45.0, size.height)
            ..close();
          canvas.drawPath(
            beam,
            Paint()..color = const Color(0xFFFFF9C4).withValues(alpha: 0.045),
          );
        }
      }
    }

    if (styleMode == CoconutStyleMode.lofi) {
      final Rect fullRect = Offset.zero & size;
      canvas.drawRect(
        fullRect,
        Paint()
          ..shader = ui.Gradient.radial(
            fullRect.center,
            size.longestSide * 0.68,
            [
              Colors.transparent,
              const Color(0xFF1F1124).withValues(alpha: 0.36),
            ],
            const [0.62, 1.0],
          ),
      );
    }
  }

  // ===========================================================================
  // SHARED HELPERS: STONE TORO LANTERNS & ARTICULATED PEOPLE
  // ===========================================================================

  void _drawStoneToroLantern(
    Canvas canvas,
    Offset pos, {
    double scale = 1.0,
  }) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.scale(scale);

    final Paint stonePaint = Paint()..color = const Color(0xFF78828A);
    canvas.drawRect(const Rect.fromLTWH(-8, -3, 16, 4), stonePaint);
    canvas.drawRect(const Rect.fromLTWH(-4, -18, 8, 15), stonePaint);
    canvas.drawRect(const Rect.fromLTWH(-7, -21, 14, 3), stonePaint);

    canvas.drawRect(
      const Rect.fromLTWH(-5.5, -29, 11, 8),
      Paint()..color = const Color(0xFFFFCC4D),
    );
    canvas.drawCircle(
      const Offset(0, -25),
      11,
      Paint()
        ..color = const Color(0xFFFFA726).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    final Path roof = Path()
      ..moveTo(-11, -29)
      ..quadraticBezierTo(0, -37, 11, -29)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFF5C666E));
    canvas.drawCircle(
      const Offset(0, -35),
      2.2,
      Paint()..color = const Color(0xFF5C666E),
    );

    canvas.restore();
  }

  void _drawOnsenBather(
    Canvas canvas,
    Offset pos, {
    bool hasHeadTowel = false,
    bool hasSpeechBubble = false,
  }) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);

    canvas.drawOval(
      const Rect.fromLTWH(-9, -4, 18, 9),
      Paint()..color = const Color(0xFFF3C6A5),
    );
    canvas.drawCircle(
      const Offset(0, -10),
      5.8,
      Paint()..color = const Color(0xFFF7D2B7),
    );
    canvas.drawArc(
      const Rect.fromLTWH(-6, -16, 12, 9),
      math.pi,
      math.pi,
      true,
      Paint()..color = const Color(0xFF1F242D),
    );

    if (hasHeadTowel) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-5, -18, 10, 3.5),
          const Radius.circular(1.5),
        ),
        Paint()..color = Colors.white,
      );
    }

    if (hasSpeechBubble) {
      _drawSpeechBubble(canvas, const Offset(10, -24));
    }

    canvas.restore();
  }

  void _drawArticulatedPerson(
    Canvas canvas,
    Offset pos, {
    double scale = 1.0,
    required Color kimonoColor,
    required Color obiColor,
    bool isSeated = false,
    bool hasParasol = false,
    Color parasolColor = const Color(0xFFE53935),
    bool hasKasaHat = false,
    bool hasSpeechBubble = false,
    bool hasShamisen = false,
  }) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.scale(scale);

    final double bodyHeight = isSeated ? 14.0 : 22.0;
    final Path kimono = Path()
      ..moveTo(-5, -bodyHeight)
      ..lineTo(5, -bodyHeight)
      ..lineTo(isSeated ? 9 : 7, 0)
      ..lineTo(isSeated ? -9 : -7, 0)
      ..close();
    canvas.drawPath(kimono, Paint()..color = kimonoColor);

    canvas.drawRect(
      Rect.fromLTWH(-5.5, -bodyHeight * 0.58, 11.0, 4.0),
      Paint()..color = obiColor,
    );

    final double armSwing = math.sin(time * 2.8 + pos.dx) * 2.0;
    canvas.drawLine(
      Offset(-4, -bodyHeight + 3),
      Offset(-9, -bodyHeight * 0.45 + armSwing),
      Paint()
        ..color = kimonoColor
        ..strokeWidth = 3.8
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(4, -bodyHeight + 3),
      Offset(9, -bodyHeight * 0.45 - armSwing),
      Paint()
        ..color = kimonoColor
        ..strokeWidth = 3.8
        ..strokeCap = StrokeCap.round,
    );

    final Offset headCenter = Offset(0, -bodyHeight - 5.5);
    canvas.drawCircle(
      headCenter,
      5.2,
      Paint()..color = const Color(0xFFF7D2B7),
    );
    canvas.drawArc(
      Rect.fromCircle(center: headCenter, radius: 5.4),
      math.pi * 0.9,
      math.pi * 1.2,
      true,
      Paint()..color = const Color(0xFF1B1E24),
    );

    if (hasKasaHat) {
      final Path hat = Path()
        ..moveTo(-11, headCenter.dy - 2)
        ..quadraticBezierTo(0, headCenter.dy - 11, 11, headCenter.dy - 2)
        ..close();
      canvas.drawPath(hat, Paint()..color = const Color(0xFFD7B377));
    }

    if (hasParasol) {
      canvas.drawLine(
        Offset(6, -bodyHeight * 0.5),
        Offset(8, headCenter.dy - 14),
        Paint()
          ..color = const Color(0xFF5D4037)
          ..strokeWidth = 1.5,
      );
      final Path parasol = Path()
        ..moveTo(-8, headCenter.dy - 10)
        ..quadraticBezierTo(8, headCenter.dy - 22, 24, headCenter.dy - 10)
        ..close();
      canvas.drawPath(parasol, Paint()..color = parasolColor);
    }

    if (hasShamisen) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-4, -bodyHeight * 0.65, 7, 6),
          const Radius.circular(1.5),
        ),
        Paint()..color = const Color(0xFFFFF8E1),
      );
      canvas.drawLine(
        Offset(2, -bodyHeight * 0.55),
        Offset(15, -bodyHeight - 4),
        Paint()
          ..color = const Color(0xFF4E342E)
          ..strokeWidth = 2.0,
      );
      for (int n = 0; n < 2; n++) {
        final double notePhase = (time * 0.75 + n * 0.5) % 1.0;
        final Offset notePos = Offset(
          14.0 + n * 8.0 + math.sin(time * 3.0 + n) * 3.0,
          headCenter.dy - 6.0 - notePhase * 18.0,
        );
        canvas.drawCircle(
          notePos,
          2.2,
          Paint()
            ..color = const Color(0xFFFFD54F).withValues(
              alpha: (1.0 - notePhase).clamp(0.0, 1.0),
            ),
        );
      }
    }

    if (hasSpeechBubble) {
      _drawSpeechBubble(canvas, Offset(10, headCenter.dy - 12));
    }

    canvas.restore();
  }

  void _drawSpeechBubble(Canvas canvas, Offset pos) {
    final double pulse = 0.85 + 0.15 * math.sin(time * 4.0);
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.scale(pulse);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-9, -6, 18, 10),
        const Radius.circular(5),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.92),
    );
    for (int d = -1; d <= 1; d++) {
      canvas.drawCircle(
        Offset(d * 4.2, -1),
        1.2,
        Paint()..color = const Color(0xFF37474F),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ZenValleyWorldPainter oldDelegate) {
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
