// ignore_for_file: prefer_initializing_formals
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/zenverse_controller.dart';
import 'coconut_world_painter.dart';

class CologneChristmasAssets {
  static ui.Image? cathedral;
  static ui.Image? stall;
  static ui.Image? stallGrill;
  static ui.Image? stallSweets;
  static ui.Image? stallCrafts;
  static ui.Image? treePavilion;
  static ui.Image? hohenzollernBridge;
  static ui.Image? altstadtHouses;
  static bool _loading = false;
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static bool get isReady =>
      cathedral != null &&
      stall != null &&
      stallGrill != null &&
      stallSweets != null &&
      stallCrafts != null &&
      treePavilion != null &&
      hohenzollernBridge != null &&
      altstadtHouses != null;

  static Future<ui.Image> _decodeAsset(String path) async {
    final ByteData data = await rootBundle.load(path);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
    );
    final ui.FrameInfo frame = await codec.getNextFrame();
    return frame.image;
  }

  static Future<void> ensureLoaded() async {
    if (isReady || _loading) return;
    _loading = true;
    try {
      cathedral = await _decodeAsset('assets/cologne/cologne_cathedral.png');
      stall = await _decodeAsset('assets/cologne/cologne_stall.png');
      stallGrill = await _decodeAsset('assets/cologne/cologne_stall_grill.png');
      stallSweets = await _decodeAsset(
        'assets/cologne/cologne_stall_sweets.png',
      );
      stallCrafts = await _decodeAsset(
        'assets/cologne/cologne_stall_crafts.png',
      );
      treePavilion = await _decodeAsset(
        'assets/cologne/cologne_tree_pavilion.png',
      );
      hohenzollernBridge = await _decodeAsset(
        'assets/cologne/cologne_hohenzollern_bridge.png',
      );
      altstadtHouses = await _decodeAsset(
        'assets/cologne/cologne_altstadt_houses.png',
      );
      revision.value++;
    } catch (_) {
      // Fallback to procedural vector layers if asset bundle is unavailable
    } finally {
      _loading = false;
    }
  }
}

class CologneChristmasWorldPainter extends CustomPainter {
  final ZenVerseController? controller;
  final double _cameraYaw;
  final double _cameraPitch;
  final double _time;
  final bool _isArcadeMode;
  final double _coconutPulse;
  final CoconutAtmosphereMode _atmosphereMode;
  final CoconutStyleMode _styleMode;
  final double _cameraZoom;

  // Class-level reusable Paint instances to avoid per-frame GC allocations
  static final Paint sharedFillPaint = Paint()..style = PaintingStyle.fill;
  static final Paint sharedStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final Paint _sharedImagePaint = Paint()
    ..filterQuality = FilterQuality.medium;
  static final Paint _sharedSnowPaint = Paint()..style = PaintingStyle.fill;

  double get cameraYaw => controller?.cameraYaw ?? _cameraYaw;
  double get cameraPitch => controller?.cameraPitch ?? _cameraPitch;
  double get time => controller?.time ?? _time;
  bool get isArcadeMode => controller?.isArcadeMode ?? _isArcadeMode;
  double get coconutPulse => controller?.coconutPulse ?? _coconutPulse;
  CoconutAtmosphereMode get atmosphereMode =>
      controller?.atmosphereMode ?? _atmosphereMode;
  CoconutStyleMode get styleMode => controller?.styleMode ?? _styleMode;
  double get cameraZoom => controller?.cameraZoom ?? _cameraZoom;

  CologneChristmasWorldPainter({
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
       super(
         repaint:
             repaint ??
             (controller != null
                 ? Listenable.merge([controller, CologneChristmasAssets.revision])
                 : null),
       );

  double? _worldAngleToScreenX(
    double worldDeg,
    Size size, {
    double fov = 110.0,
    double margin = 640.0,
  }) {
    final double effectiveFov = fov / cameraZoom.clamp(0.75, 1.5);
    double diff = (worldDeg - cameraYaw) % 360.0;
    if (diff > 180.0) diff -= 360.0;
    if (diff < -180.0) diff += 360.0;
    final double x = size.width * 0.5 + (diff / effectiveFov) * size.width;
    if (x < -margin || x > size.width + margin) return null;
    return x;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (!CologneChristmasAssets.isReady) {
      CologneChristmasAssets.ensureLoaded();
    }

    final double horizonY = size.height * (0.45 + (cameraPitch / 90.0) * 0.34);
    final double groundHeight = size.height - horizonY;

    // 1. Deep Royal-Blue / Dusk Winter Sky, Market Light Dome, Stars, Moon & Santa Sleigh
    _drawSkyAndCelestial(canvas, size, horizonY);
    _drawWinterClouds(canvas, size, horizonY);

    // 2. Roncalliplatz Granite/Basalt Paving Slabs, Warm Golden Market Glow & Distant Skyline
    _drawRoncalliplatzGroundAndSkyline(canvas, size, horizonY, groundHeight);

    // 2b. Continuous 360° Living Cologne City Skyline & Distant Landmarks (Zero Empty Horizon Gaps!)
    _drawContinuousDistantCologneSkyline(canvas, size, horizonY, groundHeight);

    // 3. 252° Zone — Rhine River, 3-Arch Hohenzollernbrücke, DB ICE Train, Cruise Ship & Groß St. Martin
    _drawRhineBridgeAndWaterfront(canvas, size, horizonY, groundHeight);

    // 4. 0° Zone — Kölner Dom (with real photographic cutout texture), Blue Musical Dome, Römisch-Germanisches Museum & Domkloster
    _drawCologneCathedralAndRoncalliplatzBuildings(
      canvas,
      size,
      horizonY,
      groundHeight,
    );

    // 5. 72° Zone — Heinzels Wintermärchen (Heumarkt) Ice Rink, Bridge, Equestrian Monument & Almhütte
    _drawHeumarktIceRinkAndSkaters(canvas, size, horizonY, groundHeight);

    // 6. 128° Zone — Altstadt Gable Houses, Rathaus Tower, Golden Entrance Arch (Lichtertor),
    //    Row of Golden-Lit Perimeter Christmas Trees & 4-Tier Weihnachtspyramide
    _drawAltstadtLichtertorAndPyramid(canvas, size, horizonY, groundHeight);

    // 7. 176° Zone — Giant Ferris Wheel (Riesenrad), Charcoal Schwenkgrill & Red-Canopied Carousel
    _drawFerrisWheelGrillAndCarousel(canvas, size, horizonY, groundHeight);

    // 8. Dense Sea of Red-Roofed Cologne Christmas Market Stalls (Marktbuden with real stall cutout texture) & Walking Crowd
    _drawRedRoofedMarketSeaAndAvenues(canvas, size, horizonY, groundHeight);

    // 9. Overhead "Sternenzelt" (70,000-LED Starry Light Tent Web & 6-Pointed Star Rays)
    _drawSternenzeltCanopyWeb(canvas, size, horizonY, groundHeight);

    // 10. Center Object — The Grand 25m Roncalliplatz Nordmann Fir Tree & Octagonal Red-Roofed Pavilion Base
    _drawCenterChristmasTreeAndPavilion(canvas, size, horizonY, groundHeight);

    // 11. Falling Winter Snowflakes & Golden Bokeh Glints
    _drawFallingSnow(canvas, size);
  }

  // ===========================================================================
  // 1. DEEP ROYAL-BLUE WINTER SKY, MARKET GLOW DOME, STARS & SANTA'S SLEIGH
  // ===========================================================================
  void _drawSkyAndCelestial(Canvas canvas, Size size, double horizonY) {
    final double groundHeight = size.height - horizonY;
    final double skyBottomY = horizonY + groundHeight * 0.225;
    final Rect skyRect = Rect.fromLTWH(0, 0, size.width, skyBottomY + 8);
    final List<Color> skyColors;
    switch (atmosphereMode) {
      case CoconutAtmosphereMode.sunset:
        // Rich evening blue-hour into warm amber-crimson horizon (matches Photo 1 & 3 royal blue sky + warm plaza glow!)
        skyColors = const [
          Color(0xFF061026),
          Color(0xFF0C1D42),
          Color(0xFF182E5E),
          Color(0xFF3A3566),
          Color(0xFF8A444E),
          Color(0xFFD97B48),
        ];
      case CoconutAtmosphereMode.night:
        skyColors = const [
          Color(0xFF030817),
          Color(0xFF07132E),
          Color(0xFF0D2149),
          Color(0xFF152E60),
          Color(0xFF1E3C73),
          Color(0xFF2B4B82),
        ];
      case CoconutAtmosphereMode.noon:
        skyColors = const [
          Color(0xFF2B587A),
          Color(0xFF4A7FA6),
          Color(0xFF76A9CC),
          Color(0xFFA9CEE8),
          Color(0xFFD5E9F7),
          Color(0xFFF2F8FC),
        ];
      case CoconutAtmosphereMode.rain:
        skyColors = const [
          Color(0xFF1B2430),
          Color(0xFF2B3847),
          Color(0xFF405163),
          Color(0xFF5A6E82),
          Color(0xFF7E93A6),
          Color(0xFFAEC0CF),
        ];
    }

    canvas.drawRect(
      skyRect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(size.width * 0.5, 0),
          Offset(size.width * 0.5, skyBottomY + 8),
          skyColors,
          const [0.0, 0.22, 0.48, 0.70, 0.87, 1.0],
        ),
    );

    // Intense warm golden-amber Christmas Market glow rising from Roncalliplatz into the sky
    for (final (double deg, double strength) in const [
      (0.0, 0.48),
      (72.0, 0.30),
      (128.0, 0.42),
      (176.0, 0.34),
    ]) {
      final double? gx = _worldAngleToScreenX(deg, size, margin: 600);
      if (gx == null) continue;
      canvas.drawRect(
        skyRect,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(gx, skyBottomY),
            size.width * 0.48,
            [
              const Color(0xFFFFCA28).withValues(alpha: strength),
              const Color(0xFFFF7043).withValues(alpha: strength * 0.42),
              Colors.transparent,
            ],
            const [0.0, 0.46, 1.0],
          ),
      );
    }

    // Twinkling stars in Night & Sunset Blue-Hour
    if (atmosphereMode == CoconutAtmosphereMode.night ||
        atmosphereMode == CoconutAtmosphereMode.sunset) {
      final double starAlphaBase = atmosphereMode == CoconutAtmosphereMode.night
          ? 0.90
          : 0.52;
      final Paint starPaint = Paint()..style = PaintingStyle.fill;
      for (int i = 0; i < 72; i++) {
        final double deg = (i * 43.7) % 360.0;
        if ((deg - 0.0).abs() < 18.0 || (deg - 360.0).abs() < 18.0) continue;
        final double? sx = _worldAngleToScreenX(deg, size, margin: 40);
        if (sx == null) continue;
        final double sy =
            horizonY * (0.04 + ((i * 31.3) % 100) / 100.0 * 0.62);
        final double twinkle =
            0.45 + 0.55 * math.sin(time * (1.8 + (i % 5) * 0.55) + i * 1.3);
        final double alpha = (starAlphaBase * twinkle).clamp(0.0, 1.0);
        starPaint.color = Colors.white.withValues(alpha: alpha);
        canvas.drawCircle(Offset(sx, sy), (i % 7 == 0) ? 1.9 : 1.1, starPaint);
      }
    }

    // Celestial body (Full Moon at 315° so it frames the Cathedral left towers without colliding)
    final double celestialDeg = 312.0;
    final double? cx = _worldAngleToScreenX(celestialDeg, size, margin: 180);
    final double cy = horizonY * 0.22;
    if (cx != null && atmosphereMode != CoconutAtmosphereMode.rain) {
      final Color coreCol = atmosphereMode == CoconutAtmosphereMode.noon
          ? const Color(0xFFFFFDE7)
          : const Color(0xFFFFF9C4);
      canvas.drawCircle(
        Offset(cx, cy),
        76.0,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(cx, cy),
            76.0,
            [
              coreCol.withValues(alpha: 0.40),
              const Color(0xFFFFD54F).withValues(alpha: 0.14),
              Colors.transparent,
            ],
            const [0.0, 0.5, 1.0],
          ),
      );
      canvas.drawCircle(Offset(cx, cy), 23.0, Paint()..color = coreCol);
    }

    // Animated Santa's Reindeer Sleigh silhouette flying across the high winter sky
    if (atmosphereMode == CoconutAtmosphereMode.night ||
        atmosphereMode == CoconutAtmosphereMode.sunset) {
      final double sleighDeg = (38.0 + time * 5.0) % 360.0;
      final double? sleighX = _worldAngleToScreenX(
        sleighDeg,
        size,
        margin: 180,
      );
      if (sleighX != null) {
        final double sleighY =
            horizonY * (0.16 + 0.02 * math.sin(time * 2.2));
        _drawSantaSleighSilhouette(canvas, Offset(sleighX, sleighY));
      }
    }
  }

  void _drawSantaSleighSilhouette(Canvas canvas, Offset center) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-0.08 + 0.04 * math.sin(time * 2.5));

    for (int i = 1; i <= 8; i++) {
      final double dx = -22.0 - i * 8.5;
      final double dy = 3.5 + math.sin(time * 5.0 + i) * 2.5;
      canvas.drawCircle(
        Offset(dx, dy),
        (2.3 - i * 0.20).clamp(0.5, 2.3),
        Paint()
          ..color = const Color(
            0xFFFFE082,
          ).withValues(alpha: (0.82 - i * 0.08).clamp(0.1, 0.82)),
      );
    }

    final Paint silhouettePaint = Paint()..color = const Color(0xFF090D1A);
    final Path sleigh = Path()
      ..moveTo(-20, 4)
      ..lineTo(4, 4)
      ..quadraticBezierTo(10, 4, 12, -4)
      ..lineTo(6, -3)
      ..lineTo(-4, -3)
      ..lineTo(-8, -9)
      ..lineTo(-18, -8)
      ..close();
    canvas.drawPath(sleigh, silhouettePaint);
    canvas.drawCircle(const Offset(-4, -7), 4.0, silhouettePaint);
    canvas.drawCircle(const Offset(-13, -7), 4.8, silhouettePaint);

    for (int r = 0; r < 3; r++) {
      final double rx = 20.0 + r * 16.0;
      final double ry = -1.0 - r * 1.1 + math.sin(time * 7.0 + r * 1.4) * 2.0;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(rx, ry), width: 9.5, height: 4.2),
        silhouettePaint,
      );
      canvas.drawCircle(Offset(rx + 5.5, ry - 3.2), 2.1, silhouettePaint);
      if (r == 2) {
        canvas.drawCircle(
          Offset(rx + 8.0, ry - 3.2),
          2.0,
          Paint()..color = const Color(0xFFFF1744),
        );
      }
    }
    canvas.restore();
  }

  void _drawWinterClouds(Canvas canvas, Size size, double horizonY) {
    final Color cloudFill = atmosphereMode == CoconutAtmosphereMode.noon
        ? Colors.white.withValues(alpha: 0.78)
        : const Color(0xFF162747).withValues(alpha: 0.52);
    final Color cloudRim = atmosphereMode == CoconutAtmosphereMode.noon
        ? const Color(0xFFE1F5FE).withValues(alpha: 0.85)
        : const Color(0xFF6488B8).withValues(alpha: 0.28);

    final Paint fillPaint = Paint()..color = cloudFill;
    final Paint rimPaint = Paint()
      ..color = cloudRim
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 0; i < 12; i++) {
      final double baseDeg = (i * 30.0 + 48.0 + time * 0.25) % 360.0;
      // Keep sky behind Kölner Dom (-28°..+28°) crisp and clear like Photo 1 & 3!
      if (baseDeg < 30.0 || baseDeg > 330.0) continue;
      final double? cx = _worldAngleToScreenX(baseDeg, size, margin: 160);
      if (cx == null) continue;

      final double cy = horizonY * (0.14 + (i % 3) * 0.11);
      final double scale = 0.70 + (i % 3) * 0.15;

      Path unitedCloud = Path()
        ..addOval(
          Rect.fromCenter(
            center: Offset(cx, cy),
            width: 66 * scale,
            height: 22 * scale,
          ),
        );
      for (final Rect r in [
        Rect.fromCenter(
          center: Offset(cx - 22 * scale, cy + 3 * scale),
          width: 42 * scale,
          height: 18 * scale,
        ),
        Rect.fromCenter(
          center: Offset(cx + 23 * scale, cy + 3 * scale),
          width: 44 * scale,
          height: 18 * scale,
        ),
        Rect.fromCenter(
          center: Offset(cx, cy - 7 * scale),
          width: 38 * scale,
          height: 20 * scale,
        ),
      ]) {
        unitedCloud = Path.combine(
          PathOperation.union,
          unitedCloud,
          Path()..addOval(r),
        );
      }
      canvas.drawPath(unitedCloud, fillPaint);
      canvas.drawPath(unitedCloud, rimPaint);
    }
  }

  // ===========================================================================
  // 2. RONCALLIPLATZ GRANITE/BASALT PAVING SLABS & WARM GOLDEN MARKET GLOW
  // ===========================================================================
  void _drawRoncalliplatzGroundAndSkyline(
    Canvas canvas,
    Size size,
    double horizonY,
    double groundHeight,
  ) {
    final double plazaTopY = horizonY + groundHeight * 0.215;
    final Rect groundRect = Rect.fromLTWH(
      0,
      plazaTopY,
      size.width,
      size.height - plazaTopY,
    );

    // Authentic Roncalliplatz granite paving slabs & warm golden market illumination (Photo 1, 2 & 3)
    final List<Color> plazaColors;
    switch (atmosphereMode) {
      case CoconutAtmosphereMode.sunset:
      case CoconutAtmosphereMode.night:
        plazaColors = const [
          Color(0xFF33292E),
          Color(0xFF42363A),
          Color(0xFF594C4E),
          Color(0xFF75686A),
          Color(0xFF968B8A),
          Color(0xFFADA4A1),
        ];
      case CoconutAtmosphereMode.noon:
        plazaColors = const [
          Color(0xFF6E7880),
          Color(0xFF88929A),
          Color(0xFFA3ADB5),
          Color(0xFFBEC7CE),
          Color(0xFFD5DCE2),
          Color(0xFFE8EDF2),
        ];
      case CoconutAtmosphereMode.rain:
        plazaColors = const [
          Color(0xFF222A33),
          Color(0xFF333E4A),
          Color(0xFF495766),
          Color(0xFF647485),
          Color(0xFF8494A4),
          Color(0xFFA6B5C4),
        ];
    }

    canvas.drawRect(
      groundRect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(size.width * 0.5, plazaTopY),
          Offset(size.width * 0.5, size.height),
          plazaColors,
          const [0.0, 0.16, 0.34, 0.56, 0.78, 1.0],
        ),
    );

    // Soft warm horizon transition haze blending the sky bottom into the Roncalliplatz stone floor
    final Rect horizonBlendRect = Rect.fromLTWH(
      0,
      plazaTopY - 20,
      size.width,
      40,
    );
    canvas.drawRect(
      horizonBlendRect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, plazaTopY - 20),
          Offset(0, plazaTopY + 20),
          [
            const Color(0xFF3A2C35).withValues(alpha: 0.0),
            const Color(0xFF3A2C35).withValues(alpha: 0.52),
            const Color(0xFF33292E).withValues(alpha: 0.82),
            const Color(0xFF33292E).withValues(alpha: 0.0),
          ],
          const [0.0, 0.45, 0.72, 1.0],
        ),
    );

    // Subtle distant Cologne city window glints along the plaza horizon
    for (int h = 0; h < 48; h++) {
      final double hDeg = h * 7.5;
      final double? hx = _worldAngleToScreenX(hDeg, size, margin: 120);
      if (hx == null) continue;
      final double hy = plazaTopY - 6.0 + (h % 4) * 3.2;
      canvas.drawCircle(
        Offset(hx, hy),
        1.2 + (h % 2) * 0.5,
        Paint()
          ..color = const Color(
            0xFFFFE082,
          ).withValues(alpha: 0.25 + (h % 3) * 0.08),
      );
    }

    // Intense Golden-Amber & Crimson Light Carpet under the Roncalliplatz Christmas Market (Photo 1 & 3!)
    for (final (double deg, double yf, Color col, double rad) in const [
      (0.0, 0.42, Color(0xFFFFD54F), 360.0),
      (-24.0, 0.46, Color(0xFFFF8F00), 260.0),
      (24.0, 0.46, Color(0xFFFF8F00), 260.0),
      (-42.0, 0.52, Color(0xFFFF5252), 210.0),
      (42.0, 0.52, Color(0xFFFF5252), 210.0),
      (72.0, 0.36, Color(0xFF81D4FA), 240.0),
      (118.0, 0.44, Color(0xFFFFB300), 260.0),
      (144.0, 0.44, Color(0xFFFF7043), 250.0),
      (176.0, 0.38, Color(0xFFFFD54F), 220.0),
      (252.0, 0.36, Color(0xFFFFCA28), 230.0),
      (298.0, 0.38, Color(0xFFFFB74D), 210.0),
    ]) {
      final double? px = _worldAngleToScreenX(deg, size, margin: 450);
      if (px == null) continue;
      final double py = horizonY + groundHeight * yf;
      canvas.save();
      canvas.translate(px, py);
      canvas.scale(1.9, 0.46);
      canvas.translate(-px, -py);
      canvas.drawCircle(
        Offset(px, py),
        rad,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(px, py),
            rad,
            [
              col.withValues(alpha: 0.44),
              col.withValues(alpha: 0.18),
              Colors.transparent,
            ],
            const [0.0, 0.55, 1.0],
          ),
      );
      canvas.restore();
    }

    // Perspective Granite Paving Slab Grid (Exact Rectangular Stone Slabs from Photo 2!)
    final Paint seamPaint = Paint()
      ..color = const Color(0xFF2B2628).withValues(alpha: 0.32)
      ..strokeWidth = 1.0;
    final Paint highlightSeamPaint = Paint()
      ..color = const Color(0xFFFFF59D).withValues(alpha: 0.14)
      ..strokeWidth = 0.9;

    // Horizontal perspective slab seams
    for (int row = 1; row <= 18; row++) {
      final double t = row / 18.0;
      final double y =
          horizonY + groundHeight * (0.215 + 0.785 * math.pow(t, 1.65));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), seamPaint);
      canvas.drawLine(
        Offset(0, y + 1.2),
        Offset(size.width, y + 1.2),
        highlightSeamPaint,
      );
    }

    // Radial perspective walkway joint lines rotating with cameraYaw (Photo 2 stone tiles!)
    for (int col = 0; col < 36; col++) {
      final double deg = col * 10.0;
      final double? topX = _worldAngleToScreenX(
        deg,
        size,
        fov: 110.0,
        margin: 400,
      );
      if (topX == null) continue;
      final double topY = horizonY + groundHeight * 0.22;
      final double bottomX =
          size.width * 0.5 + (topX - size.width * 0.5) * 2.85;
      canvas.drawLine(
        Offset(topX, topY),
        Offset(bottomX, size.height),
        seamPaint,
      );
    }
  }

  // ===========================================================================
  // 2B. NON-REPEATING ARCHITECTURAL SLICE HELPER & 360° LIVING COLOGNE SKYLINE
  // ===========================================================================
  /// Renders one of 8 distinct photorealistic historic Cologne architectural modules
  /// cropped and composited from `cologne_altstadt_houses.png` and `cologne_cathedral.png`
  /// with optional stone/plaster color modulation so the background streetwall is 100%
  /// photorealistic, densely layered, and NEVER repeats as a recognizable strip!
  void _drawSingleAltstadtHouseSlice(
    Canvas canvas, {
    required int sliceIndex,
    required double centerX,
    required double baseY,
    required double width,
    required double height,
    Color? tintColor,
    bool addDormerOrChimney = false,
  }) {
    final ui.Image? img = CologneChristmasAssets.altstadtHouses;
    final ui.Image? domImg = CologneChristmasAssets.cathedral;
    final int modIdx = sliceIndex.abs() % 8;

    if (img != null) {
      final double iw = img.width.toDouble();
      final double ih = img.height.toDouble();
      final Paint p = Paint()..filterQuality = FilterQuality.medium;
      if (tintColor != null) {
        p.colorFilter = ColorFilter.mode(tintColor, BlendMode.modulate);
      }

      if (modIdx == 5) {
        // Module 5: Grand Multi-Bay Mansard Palace / Hotel Facade (e.g. Excelsior Hotel Ernst, Dom-Hotel, Guildhall)
        // Lower 4 stories cropped from wide multi-house window bays + upper slate mansard roof with dormers
        final Rect lowerSrc = Rect.fromLTRB(
          iw * 0.142,
          ih * 0.54,
          iw * 0.535,
          ih * 0.99,
        );
        final Rect lowerDst = Rect.fromLTWH(
          centerX - width * 0.5,
          baseY - height * 0.68,
          width,
          height * 0.68,
        );
        canvas.drawImageRect(img, lowerSrc, lowerDst, p);

        final Rect roofSrc = Rect.fromLTRB(
          iw * 0.535,
          ih * 0.32,
          iw * 0.698,
          ih * 0.60,
        );
        final Rect roofDst = Rect.fromLTWH(
          centerX - width * 0.52,
          baseY - height,
          width * 1.04,
          height * 0.36,
        );
        canvas.drawImageRect(img, roofSrc, roofDst, p);
      } else if (modIdx == 6) {
        // Module 6: Floodlit Romanesque Basilica Tower & Corner Turrets (cropped from Groß St. Martin tower)
        final Rect towerSrc = Rect.fromLTRB(
          iw * 0.758,
          ih * 0.02,
          iw * 0.988,
          ih * 0.99,
        );
        final Rect towerDst = Rect.fromLTWH(
          centerX - width * 0.5,
          baseY - height,
          width,
          height,
        );
        canvas.drawImageRect(img, towerSrc, towerDst, p);
      } else if (modIdx == 7 && domImg != null) {
        // Module 7: Floodlit Gothic Stonework Gable, Rose Window & Belfry Spire (cropped from South Transept)
        final double dw = domImg.width.toDouble();
        final double dh = domImg.height.toDouble();
        final Rect gothicSrc = Rect.fromLTRB(
          dw * 0.48,
          dh * 0.18,
          dw * 0.69,
          dh * 0.98,
        );
        final Rect gothicDst = Rect.fromLTWH(
          centerX - width * 0.5,
          baseY - height,
          width,
          height,
        );
        canvas.drawImageRect(domImg, gothicSrc, gothicDst, p);
      } else {
        // Modules 0..4: Individual Historic Altstadt Stepped & Bell-Gable Townhouses
        final (double x0, double x1, double y0, double y1) =
            switch (modIdx % 5) {
              0 => (0.008, 0.142, 0.33, 0.99), // Rose-Terracotta Gable ("Fischmarkt No. 38")
              1 => (0.142, 0.274, 0.33, 0.99), // Ochre-Gold Gable ("Sankt Martin")
              2 => (0.274, 0.401, 0.35, 0.99), // Sage-Green Gable ("Kölsch Est. 1650")
              3 => (0.401, 0.535, 0.34, 0.99), // Crimson-Brick Brauhaus ("Brauhaus")
              _ => (0.535, 0.698, 0.32, 0.99), // Wide Slate-Blue Shingled Gable
            };
        final Rect src = Rect.fromLTRB(iw * x0, ih * y0, iw * x1, ih * y1);
        final Rect dst = Rect.fromLTWH(
          centerX - width * 0.5,
          baseY - height,
          width,
          height,
        );
        canvas.drawImageRect(img, src, dst, p);
      }

      if (addDormerOrChimney) {
        // Subtle warm architectural floodlight glow on the historic facade
        final Offset glowCenter = Offset(centerX, baseY - height * 0.32);
        canvas.drawCircle(
          glowCenter,
          width * 0.38,
          Paint()
            ..shader = ui.Gradient.radial(
              glowCenter,
              width * 0.38,
              [
                const Color(0xFFFFE082).withValues(alpha: 0.18),
                Colors.transparent,
              ],
            ),
        );
      }
    } else {
      const List<Color> fallbackCols = [
        Color(0xFFD97757),
        Color(0xFFE6B85C),
        Color(0xFF7FA682),
        Color(0xFFC86464),
        Color(0xFF5C6BC0),
        Color(0xFFD7CCC8),
        Color(0xFFbcaaa4),
        Color(0xFF90A4AE),
      ];
      final Color col = fallbackCols[modIdx % fallbackCols.length];
      canvas.drawRect(
        Rect.fromLTWH(
          centerX - width * 0.5,
          baseY - height * 0.72,
          width,
          height * 0.72,
        ),
        Paint()..color = col,
      );
      final Path gable = Path()
        ..moveTo(centerX - width * 0.5, baseY - height * 0.72)
        ..lineTo(centerX, baseY - height)
        ..lineTo(centerX + width * 0.5, baseY - height * 0.72)
        ..close();
      canvas.drawPath(gable, Paint()..color = col);
    }
  }

  /// Renders a continuous, zero-gap 360° Cologne distant cityscape silhouette,
  /// famous skyscrapers (Colonius TV Tower, Kölnturm, KölnTriangle, Messeturm),
  /// Deutz riverbank landmarks (Lanxess Arena, St. Heribert, Hyatt Regency, Severinsbrücke),
  /// and Romanesque church spires so the background is a dense, living city in every direction.
  void _drawContinuousDistantCologneSkyline(
    Canvas canvas,
    Size size,
    double horizonY,
    double groundHeight,
  ) {
    final double landHorizonY = horizonY + groundHeight * 0.222;
    final double deutzHorizonY = horizonY + groundHeight * 0.182;

    // 1. Continuous 360° Distant Cologne City Blocks (90 varied blocks every 4° — zero empty horizon!)
    for (int i = 0; i < 90; i++) {
      final double deg = i * 4.0;
      final double? bx = _worldAngleToScreenX(deg, size, margin: 140);
      if (bx == null) continue;

      final bool isRhineDeutzZone = deg >= 196.0 && deg <= 302.0;
      final double baseY = isRhineDeutzZone ? deutzHorizonY : landHorizonY;
      final double bw = 54.0 + (i % 3) * 14.0;
      final double bh = isRhineDeutzZone
          ? (22.0 + (i * 17 % 22))
          : (46.0 + (i * 23 % 42));

      final Color bodyColor = switch (i % 5) {
        0 => const Color(0xFF1A2030),
        1 => const Color(0xFF212132),
        2 => const Color(0xFF25212E),
        3 => const Color(0xFF1B2434),
        _ => const Color(0xFF231E2A),
      };
      final Rect blockRect = Rect.fromLTWH(
        bx - bw * 0.5,
        baseY - bh,
        bw,
        bh + 6.0,
      );
      canvas.drawRect(blockRect, Paint()..color = bodyColor);

      // Varied roofline: Mansard roof, stepped gable, or pitched slate roof
      final int roofStyle = i % 3;
      if (roofStyle == 0) {
        final Path mansard = Path()
          ..moveTo(bx - bw * 0.5, baseY - bh)
          ..lineTo(bx - bw * 0.38, baseY - bh - 11.0)
          ..lineTo(bx + bw * 0.38, baseY - bh - 11.0)
          ..lineTo(bx + bw * 0.5, baseY - bh)
          ..close();
        canvas.drawPath(mansard, Paint()..color = const Color(0xFF141824));
      } else if (roofStyle == 1) {
        final Path gable = Path()
          ..moveTo(bx - bw * 0.42, baseY - bh)
          ..lineTo(bx, baseY - bh - 16.0)
          ..lineTo(bx + bw * 0.42, baseY - bh)
          ..close();
        canvas.drawPath(gable, Paint()..color = const Color(0xFF171C2A));
      }

      // Subtle warm glowing apartment & office window glints
      final int rows = (bh / 10.0).clamp(2, 5).toInt();
      final int cols = (bw / 12.0).clamp(3, 6).toInt();
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          if ((i + r * 3 + c * 7) % 4 == 0) continue;
          final double wx = bx - bw * 0.36 + c * (bw * 0.72 / (cols - 1));
          final double wy = baseY - bh + 7.0 + r * 8.5;
          final Color winCol = (i + c) % 5 == 0
              ? const Color(0xFFFFB74D)
              : const Color(0xFFFFE082);
          canvas.drawRect(
            Rect.fromCenter(center: Offset(wx, wy), width: 3.2, height: 3.8),
            Paint()..color = winCol.withValues(alpha: 0.34 + (r % 2) * 0.12),
          );
        }
      }
    }

    // 2. COLONIUS FERNSEHTURM (336°) — Cologne's 266m Telecommunications Tower in the distant night mist!
    final double? coloniusX = _worldAngleToScreenX(336.0, size, margin: 220);
    if (coloniusX != null) {
      final double base = landHorizonY - 10.0;
      final Path shaft = Path()
        ..moveTo(coloniusX - 5.0, base)
        ..lineTo(coloniusX - 2.0, base - 190.0)
        ..lineTo(coloniusX + 2.0, base - 190.0)
        ..lineTo(coloniusX + 5.0, base)
        ..close();
      canvas.drawPath(
        shaft,
        Paint()..color = const Color(0xFF37474F).withValues(alpha: 0.85),
      );
      final Path saucerLower = Path()
        ..moveTo(coloniusX - 16.0, base - 130.0)
        ..lineTo(coloniusX - 22.0, base - 138.0)
        ..lineTo(coloniusX + 22.0, base - 138.0)
        ..lineTo(coloniusX + 16.0, base - 130.0)
        ..close();
      canvas.drawPath(saucerLower, Paint()..color = const Color(0xFF1E272C));
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(coloniusX, base - 140.0),
          width: 40.0,
          height: 3.5,
        ),
        Paint()..color = const Color(0xFFFFE082).withValues(alpha: 0.78),
      );
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(coloniusX, base - 151.0),
          width: 24.0,
          height: 3.8,
        ),
        Paint()..color = const Color(0xFF80D8FF).withValues(alpha: 0.65),
      );
      canvas.drawLine(
        Offset(coloniusX, base - 190.0),
        Offset(coloniusX, base - 232.0),
        Paint()
          ..color = const Color(0xFFB0BEC5).withValues(alpha: 0.75)
          ..strokeWidth = 1.4,
      );
      final double beaconAlpha = 0.45 + 0.55 * math.sin(time * 3.8).abs();
      for (final double by in [base - 156.0, base - 200.0, base - 232.0]) {
        canvas.drawCircle(
          Offset(coloniusX, by),
          2.2,
          Paint()..color = const Color(0xFFFF1744).withValues(alpha: beaconAlpha),
        );
      }
    }

    // 3. SEVERINSBRÜCKE (191°) — Cologne's Iconic A-Frame Cable-Stayed Bridge!
    final double? sevX = _worldAngleToScreenX(191.0, size, margin: 360);
    if (sevX != null) {
      final double deckY = deutzHorizonY - 2.0;
      final Offset pylonPeak = Offset(sevX + 18.0, deckY - 76.0);
      final Paint cablePaint = Paint()
        ..color = const Color(0xFF4DB6AC).withValues(alpha: 0.48)
        ..strokeWidth = 1.0;
      for (int c = -5; c <= 5; c++) {
        if (c == 0) continue;
        canvas.drawLine(
          pylonPeak,
          Offset(pylonPeak.dx + c * 20.0, deckY),
          cablePaint,
        );
      }
      final Paint pylonPaint = Paint()
        ..color = const Color(0xFF284E4B)
        ..strokeWidth = 3.6
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(pylonPeak.dx - 15.0, deckY + 16.0),
        pylonPeak,
        pylonPaint,
      );
      canvas.drawLine(
        Offset(pylonPeak.dx + 15.0, deckY + 16.0),
        pylonPeak,
        pylonPaint,
      );
      canvas.drawLine(
        Offset(sevX - 100.0, deckY),
        Offset(sevX + 120.0, deckY),
        Paint()
          ..color = const Color(0xFF263238)
          ..strokeWidth = 3.2,
      );
      for (int l = -4; l <= 5; l++) {
        canvas.drawCircle(
          Offset(sevX + l * 20.0, deckY - 2.0),
          1.5,
          Paint()..color = const Color(0xFFFFE082).withValues(alpha: 0.78),
        );
      }
    }

    // 4. DEUTZ RIGHT-BANK PANORAMA ACROSS THE RHINE (215°..292°):
    //    Rendered with atmospheric night haze & photorealistic stone/glass slices!
    final double? arenaX = _worldAngleToScreenX(220.0, size, margin: 320);
    if (arenaX != null) {
      final double base = deutzHorizonY;
      canvas.drawCircle(
        Offset(arenaX, base - 26.0),
        58.0,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(arenaX, base - 26.0),
            58.0,
            [
              const Color(0xFF00E5FF).withValues(alpha: 0.25),
              const Color(0xFF2979FF).withValues(alpha: 0.08),
              Colors.transparent,
            ],
            const [0.0, 0.55, 1.0],
          ),
      );
      final Path drum = Path()
        ..moveTo(arenaX - 48.0, base)
        ..quadraticBezierTo(arenaX, base - 38.0, arenaX + 48.0, base)
        ..close();
      canvas.drawPath(drum, Paint()..color = const Color(0xFF162C42));
      final Path arch = Path()
        ..moveTo(arenaX - 58.0, base)
        ..quadraticBezierTo(arenaX, base - 68.0, arenaX + 58.0, base);
      canvas.drawPath(
        arch,
        Paint()
          ..color = const Color(0xFF80D8FF).withValues(alpha: 0.72)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4,
      );
      for (int s = -4; s <= 4; s++) {
        final double sx = arenaX + s * 10.0;
        final double archY = base - 34.0 * (1.0 - (s / 5.5) * (s / 5.5));
        canvas.drawLine(
          Offset(sx, archY),
          Offset(sx, base - 8.0),
          Paint()
            ..color = const Color(0xFF80D8FF).withValues(alpha: 0.32)
            ..strokeWidth = 0.9,
        );
      }
    }

    // Deutz Embankment Historic Silhouettes: Alt St. Heribert Basilica (235°), Hyatt Regency (264°),
    // KölnTriangle Glass Tower (275°), and Koelnmesse Rheinhallen (287°)
    final double? heribertX = _worldAngleToScreenX(235.0, size, margin: 240);
    if (heribertX != null) {
      _drawSingleAltstadtHouseSlice(
        canvas,
        sliceIndex: 6,
        centerX: heribertX,
        baseY: deutzHorizonY + 4.0,
        width: 58.0,
        height: 92.0,
        tintColor: const Color(0xFF90A4AE),
      );
    }

    final double? hyattX = _worldAngleToScreenX(264.0, size, margin: 260);
    if (hyattX != null) {
      _drawSingleAltstadtHouseSlice(
        canvas,
        sliceIndex: 5,
        centerX: hyattX,
        baseY: deutzHorizonY + 3.0,
        width: 82.0,
        height: 54.0,
        tintColor: const Color(0xFFB0BEC5),
      );
    }

    // KölnTriangle (LVR-Turm, 275°) — Atmospheric Glass Skyscraper opposite Kölner Dom
    final double? triangleX = _worldAngleToScreenX(275.0, size, margin: 260);
    if (triangleX != null) {
      final double base = deutzHorizonY;
      const double tw = 40.0;
      const double th = 108.0;
      final RRect towerRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(triangleX - tw * 0.5, base - th, tw, th),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      );
      canvas.drawRRect(
        towerRect,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(triangleX - tw * 0.5, base - th),
            Offset(triangleX + tw * 0.5, base),
            const [Color(0xFF1F364D), Color(0xFF142334), Color(0xFF1B3044)],
            const [0.0, 0.55, 1.0],
          ),
      );
      // Subtle illuminated office window grid on KölnTriangle
      for (int f = 1; f < 16; f++) {
        for (int c = 0; c < 4; c++) {
          if ((f + c) % 3 == 0) continue;
          canvas.drawRect(
            Rect.fromLTWH(
              triangleX - tw * 0.38 + c * 8.0,
              base - th + 8.0 + f * 6.2,
              5.2,
              2.2,
            ),
            Paint()
              ..color = (f % 4 == 0
                      ? const Color(0xFF80D8FF)
                      : const Color(0xFFFFE082))
                  .withValues(alpha: 0.42),
          );
        }
      }
    }

    // Koelnmesse Tower ("Messeturm") & Historic Red-Brick Rheinhallen (287°)
    final double? messeX = _worldAngleToScreenX(287.0, size, margin: 260);
    if (messeX != null) {
      _drawSingleAltstadtHouseSlice(
        canvas,
        sliceIndex: 7,
        centerX: messeX,
        baseY: deutzHorizonY + 3.0,
        width: 56.0,
        height: 92.0,
        tintColor: const Color(0xFFB0BEC5),
      );
    }
  }

  // ===========================================================================
  // 3. 252° ZONE — RHINE RIVER, HOHENZOLLERNBRÜCKE, ICE TRAIN & ST. MARTIN
  // ===========================================================================
  void _drawRhineBridgeAndWaterfront(
    Canvas canvas,
    Size size,
    double horizonY,
    double groundHeight,
  ) {
    final double? rhineLeft = _worldAngleToScreenX(194.0, size, margin: 720);
    final double? rhineRight = _worldAngleToScreenX(318.0, size, margin: 720);
    // Water surface sits naturally BELOW the Hohenzollern Bridge deck (at the stone river piers),
    // never rising into the sky above the bridge!
    final double waterTop = horizonY + groundHeight * 0.178;
    final double waterBottom = horizonY + groundHeight * 0.275;

    if (rhineLeft != null || rhineRight != null) {
      final double x1 = (rhineLeft ?? -360.0).clamp(-380.0, size.width + 380.0);
      final double x2 = (rhineRight ?? size.width + 360.0).clamp(
        -380.0,
        size.width + 380.0,
      );
      if (x2 > x1 + 10.0) {
        final double taperW = math.min(135.0, (x2 - x1) * 0.24);
        final Path riverPath = Path()
          ..moveTo(x1, waterTop + 6)
          ..quadraticBezierTo(
            x1 + taperW * 0.5,
            waterTop,
            x1 + taperW,
            waterTop,
          )
          ..lineTo(x2 - taperW, waterTop)
          ..quadraticBezierTo(
            x2 - taperW * 0.5,
            waterTop,
            x2,
            waterTop + 6,
          )
          ..quadraticBezierTo(
            x2 - taperW * 0.35,
            waterBottom,
            x2 - taperW,
            waterBottom,
          )
          ..lineTo(x1 + taperW, waterBottom)
          ..quadraticBezierTo(
            x1 + taperW * 0.35,
            waterBottom,
            x1,
            waterTop + 6,
          )
          ..close();

        // Use saveLayer so we can feather both horizontal ends of the Rhine river smoothly!
        final Rect layerBounds = Rect.fromLTRB(
          x1 - 10,
          waterTop - 16,
          x2 + 10,
          waterBottom + 20,
        );
        canvas.saveLayer(layerBounds, Paint());

        // Soft distant Deutz riverbank mist & twilight transition along waterTop
        canvas.drawRect(
          Rect.fromLTRB(x1, waterTop - 12, x2, waterTop + 14),
          Paint()
            ..shader = ui.Gradient.linear(
              Offset(x1, waterTop - 12),
              Offset(x1, waterTop + 14),
              [
                const Color(0xFF1E2942).withValues(alpha: 0.0),
                const Color(0xFF16243B).withValues(alpha: 0.65),
                const Color(0xFF0E2038).withValues(alpha: 0.92),
              ],
              const [0.0, 0.52, 1.0],
            ),
        );

        canvas.save();
        canvas.clipPath(riverPath);

        final Rect waterRect = Rect.fromLTRB(x1, waterTop, x2, waterBottom);
        canvas.drawRect(
          waterRect,
          Paint()
            ..shader = ui.Gradient.linear(
              Offset(x1, waterTop),
              Offset(x1, waterBottom),
              const [
                Color(0xFF142842),
                Color(0xFF112C4A),
                Color(0xFF163859),
                Color(0xFF1D466B),
              ],
              const [0.0, 0.32, 0.70, 1.0],
            ),
        );

        // Warm amber sunset reflection glaze on the Rhine water surface
        canvas.drawRect(
          waterRect,
          Paint()
            ..shader = ui.Gradient.linear(
              Offset(x1, waterTop),
              Offset(x1, waterBottom),
              [
                const Color(0xFFFFB74D).withValues(alpha: 0.22),
                const Color(0xFFFF8A65).withValues(alpha: 0.10),
                Colors.transparent,
              ],
              const [0.0, 0.45, 1.0],
            ),
        );

        // Shimmering vertical water reflections of Deutz landmarks (Lanxess Arena, St. Heribert, Hyatt, KölnTriangle, Messeturm)
        for (final (double refDeg, Color refColor, double refW) in const [
          (220.0, Color(0xFF40C4FF), 48.0),
          (235.0, Color(0xFFFFD54F), 32.0),
          (264.0, Color(0xFFFFB74D), 52.0),
          (275.0, Color(0xFF80D8FF), 38.0),
          (287.0, Color(0xFFFFCA28), 36.0),
        ]) {
          final double? rx = _worldAngleToScreenX(refDeg, size, margin: 240);
          if (rx == null) continue;
          canvas.drawRect(
            Rect.fromLTWH(rx - refW * 0.5, waterTop, refW, waterBottom - waterTop),
            Paint()
              ..shader = ui.Gradient.linear(
                Offset(rx, waterTop),
                Offset(rx, waterBottom),
                [
                  refColor.withValues(alpha: 0.36),
                  refColor.withValues(alpha: 0.12),
                  Colors.transparent,
                ],
                const [0.0, 0.65, 1.0],
              ),
          );
        }

        // Warm golden bridge & city light reflections shimmering on the Rhine ripples
        for (int r = 0; r < 46; r++) {
          final double rx =
              x1 +
              taperW * 0.5 +
              ((r * 27.0 + time * 7.5) %
                  (x2 - x1 - taperW).clamp(20.0, 2400.0));
          final double ry =
              waterTop + 4.0 + (r % 7) * ((waterBottom - waterTop - 7.0) / 7.0);
          final Color refCol = r % 4 == 0
              ? const Color(0xFF40C4FF)
              : const Color(0xFFFFCA28);
          canvas.drawLine(
            Offset(rx - 11, ry),
            Offset(rx + 11, ry),
            Paint()
              ..color = refCol.withValues(alpha: 0.42)
              ..strokeWidth = 1.5
              ..strokeCap = StrokeCap.round,
          );
        }
        canvas.restore();

        // 3D Cologne Sandstone Quay Wall (Rheinufermauer / Frankenwerft) along the curved shoreline
        final Path quayWall = Path()
          ..moveTo(x1, waterTop + 6)
          ..quadraticBezierTo(
            x1 + taperW * 0.35,
            waterBottom,
            x1 + taperW,
            waterBottom,
          )
          ..lineTo(x2 - taperW, waterBottom)
          ..quadraticBezierTo(
            x2 - taperW * 0.35,
            waterBottom,
            x2,
            waterTop + 6,
          )
          ..lineTo(x2, waterTop + 14)
          ..quadraticBezierTo(
            x2 - taperW * 0.35,
            waterBottom + 11,
            x2 - taperW,
            waterBottom + 11,
          )
          ..lineTo(x1 + taperW, waterBottom + 11)
          ..quadraticBezierTo(
            x1 + taperW * 0.35,
            waterBottom + 11,
            x1,
            waterTop + 14,
          )
          ..close();
        canvas.drawPath(
          quayWall,
          Paint()
            ..shader = ui.Gradient.linear(
              Offset(x1, waterBottom - 2),
              Offset(x1, waterBottom + 11),
              const [Color(0xFF6D635B), Color(0xFF4A423C), Color(0xFF2D2825)],
              const [0.0, 0.45, 1.0],
            ),
        );
        // Stone coping highlight line along top of the quay wall
        final Path copingLine = Path()
          ..moveTo(x1, waterTop + 6)
          ..quadraticBezierTo(
            x1 + taperW * 0.35,
            waterBottom,
            x1 + taperW,
            waterBottom,
          )
          ..lineTo(x2 - taperW, waterBottom)
          ..quadraticBezierTo(
            x2 - taperW * 0.35,
            waterBottom,
            x2,
            waterTop + 6,
          );
        canvas.drawPath(
          copingLine,
          Paint()
            ..color = const Color(0xFFBDB3A8).withValues(alpha: 0.65)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );

        // Horizontal feather mask so the left & right ends of the Rhine dissolve seamlessly
        // underneath the historic Altstadt waterfront buildings!
        canvas.drawRect(
          layerBounds,
          Paint()
            ..blendMode = BlendMode.dstIn
            ..shader = ui.Gradient.linear(
              Offset(x1, waterTop),
              Offset(x2, waterTop),
              [
                Colors.white.withValues(alpha: 0.0),
                Colors.white.withValues(alpha: 0.92),
                Colors.white,
                Colors.white.withValues(alpha: 0.92),
                Colors.white.withValues(alpha: 0.0),
              ],
              const [0.0, 0.14, 0.50, 0.86, 1.0],
            ),
        );
        canvas.restore();
      }
    }

    // Photorealistic 3-Span Hohenzollernbrücke (252°) + Animated German DB ICE High-Speed Train! (UNTOUCHED!)
    final double? bridgeCenterX = _worldAngleToScreenX(
      252.0,
      size,
      margin: 580,
    );
    if (bridgeCenterX != null) {
      final double deckY = horizonY + groundHeight * 0.165;
      const double bridgeWidth = 490.0;
      final double startX = bridgeCenterX - bridgeWidth * 0.5;

      // Golden vertical water reflections under the Hohenzollern Bridge piers & arches
      for (int p = 0; p < 4; p++) {
        final double px = startX + 35.0 + p * (bridgeWidth - 70.0) / 3.0;
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(px, (deckY + waterBottom) * 0.5 + 10),
            width: 34.0,
            height: (waterBottom - deckY).clamp(16.0, 60.0),
          ),
          Paint()
            ..shader = ui.Gradient.linear(
              Offset(px, deckY + 12),
              Offset(px, waterBottom),
              [
                const Color(0xFFFFB300).withValues(alpha: 0.42),
                const Color(0xFFFF8F00).withValues(alpha: 0.14),
                Colors.transparent,
              ],
              const [0.0, 0.65, 1.0],
            ),
        );
      }

      // Animated German DB ICE High-Speed Train gliding across the Hohenzollern Bridge deck
      final double trainOffset =
          ((time * 38.0) % (bridgeWidth + 140.0)) - 70.0;
      final double trainX = startX + trainOffset;
      canvas.save();
      canvas.clipRect(
        Rect.fromLTWH(startX + 24, deckY - 36, bridgeWidth - 48, 38),
      );
      final RRect trainBody = RRect.fromRectAndRadius(
        Rect.fromLTWH(trainX, deckY - 13, 124, 11.5),
        const Radius.circular(6),
      );
      canvas.drawRRect(trainBody, Paint()..color = const Color(0xFFF5F5F5));
      canvas.drawRect(
        Rect.fromLTWH(trainX + 4, deckY - 7.2, 116, 2.6),
        Paint()..color = const Color(0xFFD32F2F),
      );
      for (int w = 0; w < 9; w++) {
        canvas.drawRect(
          Rect.fromLTWH(trainX + 10 + w * 11.5, deckY - 11.5, 7.5, 3.6),
          Paint()..color = const Color(0xFFFFF59D),
        );
      }
      canvas.restore();

      final ui.Image? bridgeImg = CologneChristmasAssets.hohenzollernBridge;
      if (bridgeImg != null) {
        final Rect srcRect = Rect.fromLTWH(
          0,
          0,
          bridgeImg.width.toDouble(),
          bridgeImg.height.toDouble(),
        );
        final Rect dstRect = Rect.fromLTRB(
          startX,
          deckY - 82.0,
          startX + bridgeWidth,
          deckY + 42.0,
        );
        canvas.drawImageRect(
          bridgeImg,
          srcRect,
          dstRect,
          Paint()..filterQuality = FilterQuality.medium,
        );
      } else {
        // Procedural fallback for headless unit tests
        const double archSpan = bridgeWidth / 3.0;
        final Paint pierPaint = Paint()..color = const Color(0xFF544E48);
        for (int p = 0; p <= 3; p++) {
          final double px = startX + p * archSpan;
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset(px, deckY + 14),
              width: 18,
              height: 30,
            ),
            pierPaint,
          );
        }
        final Paint archMainPaint = Paint()
          ..color = const Color(0xFFD4A359)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.6;
        for (int a = 0; a < 3; a++) {
          final double ax1 = startX + a * archSpan;
          final double ax2 = ax1 + archSpan;
          final double archHeight = (a == 1) ? 64.0 : 52.0;
          final Path lowerArch = Path()
            ..moveTo(ax1, deckY)
            ..quadraticBezierTo(
              (ax1 + ax2) * 0.5,
              deckY - archHeight,
              ax2,
              deckY,
            );
          canvas.drawPath(lowerArch, archMainPaint);
        }
        canvas.drawRect(
          Rect.fromLTWH(startX - 12, deckY - 3.0, bridgeWidth + 24, 6.5),
          Paint()..color = const Color(0xFF37424A),
        );
      }
    }

    // Illuminated KD Christmas River Cruise Ship gliding along the Rhine (236°)
    final double? shipX = _worldAngleToScreenX(
      236.0 + math.sin(time * 0.35) * 4.5,
      size,
      margin: 280,
    );
    if (shipX != null) {
      final double shipY = horizonY + groundHeight * 0.225;
      canvas.save();
      canvas.translate(shipX, shipY);
      canvas.scale(1.75);
      final Path hull = Path()
        ..moveTo(-48, 0)
        ..lineTo(48, 0)
        ..lineTo(39, 8.5)
        ..lineTo(-41, 8.5)
        ..close();
      canvas.drawPath(hull, Paint()..color = const Color(0xFFF5F7F8));
      canvas.drawLine(
        const Offset(-44, 3.5),
        const Offset(44, 3.5),
        Paint()
          ..color = const Color(0xFFC62828)
          ..strokeWidth = 2.2,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-35, -7.5, 66, 7.5),
          const Radius.circular(2),
        ),
        Paint()..color = Colors.white,
      );
      for (int w = 0; w < 8; w++) {
        canvas.drawRect(
          Rect.fromLTWH(-31 + w * 7.6, -5.5, 5.2, 3.6),
          Paint()..color = const Color(0xFFFFD54F),
        );
      }
      for (int l = 0; l <= 12; l++) {
        final double lx = -42 + l * 7.0;
        final double ly = -10.5 - math.sin((l / 12.0) * math.pi) * 7.0;
        canvas.drawCircle(
          Offset(lx, ly),
          1.5,
          Paint()..color = const Color(0xFFFFEE58),
        );
      }
      canvas.restore();
    }

    // Second Rhine River Vessel ("Weihnachtsschiff / Rheinschiff" at 276°)
    final double? bargeX = _worldAngleToScreenX(
      276.0 - math.cos(time * 0.28) * 3.8,
      size,
      margin: 240,
    );
    if (bargeX != null) {
      final double bargeY = horizonY + groundHeight * 0.242;
      canvas.save();
      canvas.translate(bargeX, bargeY);
      canvas.scale(1.42);
      final Path hull = Path()
        ..moveTo(-42, 0)
        ..lineTo(42, 0)
        ..lineTo(35, 6.5)
        ..lineTo(-36, 6.5)
        ..close();
      canvas.drawPath(hull, Paint()..color = const Color(0xFF263238));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-26, -6.5, 52, 6.5),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFFECEFF1),
      );
      for (int w = 0; w < 6; w++) {
        canvas.drawRect(
          Rect.fromLTWH(-22 + w * 7.5, -4.8, 5.0, 3.2),
          Paint()..color = const Color(0xFFFFE082),
        );
      }
      canvas.restore();
    }

    // Photorealistic Right Bank (305°): Floodlit Romanesque Groß St. Martin Church & Fischmarkt Houses!
    // Photorealistic 2-Layer North Altstadt & Fischmarkt Streetwall (296°..326°)
    // Drawn before Groß St. Martin (305°) so the iconic Romanesque Basilica tower stands cleanly in front!
    final double northBaseY = horizonY + groundHeight * 0.270;
    for (final (double hDeg, int sliceIdx, double hw, double hh, Color? tint, double yOff)
        in const [
      // Back row behind Fischmarkt & North Altstadt (298°..322° — taller atmospheric roofs & towers)
      (298.5, 5, 112.0, 178.0, Color(0xFFCFD8DC), -16.0),
      (305.5, 7, 92.0, 196.0, Color(0xFFD7CCC8), -16.0),
      (316.5, 5, 110.0, 176.0, Color(0xFFCFD8DC), -16.0),
      (322.0, 6, 84.0, 198.0, Color(0xFFD7CCC8), -14.0),
      // Front row connecting Groß St. Martin (314°) to Excelsior Hotel Ernst (326°)
      (316.5, 2, 62.0, 152.0, Color(0xFFE0F2F1), 0.0),
      (320.5, 4, 70.0, 162.0, null, 0.0),
      (324.5, 1, 60.0, 148.0, Color(0xFFFFECB3), 0.0),
    ]) {
      final double? hx = _worldAngleToScreenX(hDeg, size, margin: 340);
      if (hx == null) continue;
      _drawSingleAltstadtHouseSlice(
        canvas,
        sliceIndex: sliceIdx,
        centerX: hx,
        baseY: northBaseY + yOff,
        width: hw,
        height: hh,
        tintColor: tint,
        addDormerOrChimney: yOff == 0.0,
      );
    }

    // Photorealistic Right Bank (305°): Floodlit Romanesque Groß St. Martin Church & Fischmarkt Houses!
    final ui.Image? altstadtImg = CologneChristmasAssets.altstadtHouses;
    final double? stMartinX = _worldAngleToScreenX(305.0, size, margin: 420);
    if (stMartinX != null) {
      final double baseY = horizonY + groundHeight * 0.275;
      if (altstadtImg != null) {
        final Rect srcRect = Rect.fromLTWH(
          0,
          0,
          altstadtImg.width.toDouble(),
          altstadtImg.height.toDouble(),
        );
        final Rect dstRect = Rect.fromCenter(
          center: Offset(stMartinX, baseY - 94.0),
          width: 340.0,
          height: 196.0,
        );
        canvas.drawImageRect(
          altstadtImg,
          srcRect,
          dstRect,
          _sharedImagePaint,
        );
      } else {
        canvas.save();
        canvas.translate(stMartinX, baseY);
        canvas.scale(1.85);
        final Paint churchPaint = Paint()..color = const Color(0xFF7D7268);
        final Paint roofPaint = Paint()..color = const Color(0xFF2E3B43);
        canvas.drawRect(
          Rect.fromCenter(center: const Offset(0, -18), width: 48, height: 36),
          churchPaint,
        );
        canvas.drawRect(
          Rect.fromCenter(center: const Offset(0, -42), width: 28, height: 52),
          churchPaint,
        );
        final Path mainSpire = Path()
          ..moveTo(-14, -68)
          ..lineTo(0, -106)
          ..lineTo(14, -68)
          ..close();
        canvas.drawPath(mainSpire, roofPaint);
        canvas.restore();
      }
    }

    // Left Bank of the Rhine Embankment (191°..209°) — 2-Layer Deep Non-Repeating Waterfront Streetwall!
    final double southBankBaseY = horizonY + groundHeight * 0.275;
    for (final (double hDeg, int sliceIdx, double hw, double hh, Color? tint, double yOff)
        in const [
      // Back row (taller historic customs hall & Romanesque Pegelturm)
      (194.5, 5, 104.0, 168.0, Color(0xFFCFD8DC), -16.0),
      (201.5, 6, 78.0, 186.0, Color(0xFFD7CCC8), -12.0),
      // Front row (individual waterfront gables)
      (192.5, 4, 64.0, 148.0, Color(0xFFEFEBE9), 0.0),
      (197.5, 0, 58.0, 142.0, null, 0.0),
      (202.5, 2, 58.0, 146.0, Color(0xFFFFF3E0), 0.0),
      (207.0, 3, 56.0, 138.0, Color(0xFFFFCCBC), 0.0),
    ]) {
      final double? hx = _worldAngleToScreenX(hDeg, size, margin: 300);
      if (hx == null) continue;
      _drawSingleAltstadtHouseSlice(
        canvas,
        sliceIndex: sliceIdx,
        centerX: hx,
        baseY: southBankBaseY + yOff,
        width: hw,
        height: hh,
        tintColor: tint,
        addDormerOrChimney: yOff == 0.0,
      );
    }

    // Continuous Wrought-Iron Rhine Promenade Railing with Colorful Love Locks (Liebesschlösser) & Vintage River Lampposts (204°..294°)
    final double? lockStart = _worldAngleToScreenX(204.0, size, margin: 460);
    final double? lockEnd = _worldAngleToScreenX(294.0, size, margin: 460);
    if (lockStart != null || lockEnd != null) {
      final double rStart = (lockStart ?? -120.0).clamp(
        -140.0,
        size.width + 140.0,
      );
      final double rEnd = (lockEnd ?? size.width + 120.0).clamp(
        -140.0,
        size.width + 140.0,
      );
      if (rEnd > rStart + 8.0) {
        final double railY = waterBottom;
        final Paint railPaint = Paint()
          ..color = const Color(0xFF263238)
          ..strokeWidth = 2.2;
        canvas.drawLine(
          Offset(rStart, railY - 14),
          Offset(rEnd, railY - 14),
          railPaint,
        );
        canvas.drawLine(Offset(rStart, railY), Offset(rEnd, railY), railPaint);
        for (double bx = rStart; bx <= rEnd; bx += 12.0) {
          canvas.drawLine(
            Offset(bx, railY - 14),
            Offset(bx, railY),
            Paint()
              ..color = const Color(0xFF37474F)
              ..strokeWidth = 1.2,
          );
        }
        const List<Color> lockColors = [
          Color(0xFFFF5252),
          Color(0xFFFFD740),
          Color(0xFF40C4FF),
          Color(0xFFFF4081),
          Color(0xFF69F0AE),
        ];
        final int count = ((rEnd - rStart) / 6.0).clamp(6, 110).toInt();
        for (int i = 0; i < count; i++) {
          canvas.drawCircle(
            Offset(rStart + i * 6.0, railY - 11.0 + (i % 3) * 3.4),
            2.0,
            Paint()..color = lockColors[i % lockColors.length],
          );
        }
      }
    }

    // Fairy-Lit Bare Winter Plane Trees (Platanen) & Vintage Globe Lampposts along Frankenwerft Promenade
    for (final double tDeg in const [211.0, 222.0, 232.0, 272.0, 283.0, 293.0]) {
      final double? tx = _worldAngleToScreenX(tDeg, size, margin: 180);
      if (tx == null) continue;
      final double ty = waterBottom + 5.0;
      final Paint trunkP = Paint()
        ..color = const Color(0xFF3E2723)
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(tx, ty), Offset(tx, ty - 48.0), trunkP);
      for (int b = -3; b <= 3; b++) {
        if (b == 0) continue;
        canvas.drawLine(
          Offset(tx, ty - 22.0 - b.abs() * 4.0),
          Offset(tx + b * 10.5, ty - 44.0 - b.abs() * 3.0),
          trunkP,
        );
        canvas.drawCircle(
          Offset(tx + b * 7.5, ty - 34.0 - b.abs() * 2.5),
          2.2,
          Paint()..color = const Color(0xFFFFF59D).withValues(alpha: 0.84),
        );
      }
    }

    for (double lDeg = 212.0; lDeg <= 288.0; lDeg += 19.0) {
      final double? lx = _worldAngleToScreenX(lDeg, size, margin: 160);
      if (lx == null) continue;
      final double ly = waterBottom + 3.0;
      canvas.drawLine(
        Offset(lx, ly),
        Offset(lx, ly - 36.0),
        Paint()
          ..color = const Color(0xFF1C262B)
          ..strokeWidth = 2.4,
      );
      canvas.drawCircle(
        Offset(lx, ly - 38.0),
        9.0,
        Paint()
          ..color = const Color(0xFFFFE082).withValues(alpha: 0.35),
      );
      canvas.drawCircle(
        Offset(lx, ly - 38.0),
        3.6,
        Paint()..color = const Color(0xFFFFF9C4),
      );
    }
  }

  // ===========================================================================
  // 4. 0° ZONE — PHOTO-ACCURATE KÖLNER DOM, MUSICAL DOME & RONCALLIPLATZ FLANKS
  // ===========================================================================
  void _drawCologneCathedralAndRoncalliplatzBuildings(
    Canvas canvas,
    Size size,
    double horizonY,
    double groundHeight,
  ) {
    final double? domX = _worldAngleToScreenX(0.0, size, margin: 980);
    if (domX == null) return;

    final double domBaseY = horizonY + groundHeight * 0.26;
    const double scale = 1.85;

    // -------------------------------------------------------------------------
    // A. ELECTRIC-BLUE MUSICAL DOME KÖLN (Right Background of Kölner Dom in Photos 1 & 3!)
    // -------------------------------------------------------------------------
    final double? musicalDomeX = _worldAngleToScreenX(28.0, size, margin: 420);
    if (musicalDomeX != null) {
      final double mdBaseY = horizonY + groundHeight * 0.20;
      // Neon sapphire-blue glow in the night sky
      canvas.drawCircle(
        Offset(musicalDomeX, mdBaseY - 24),
        78.0,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(musicalDomeX, mdBaseY - 24),
            78.0,
            [
              const Color(0xFF00B0FF).withValues(alpha: 0.55),
              const Color(0xFF2962FF).withValues(alpha: 0.22),
              Colors.transparent,
            ],
            const [0.0, 0.52, 1.0],
          ),
      );
      // Iconic 3 wave-arched blue-illuminated roof peaks of the Musical Dome
      for (int a = -1; a <= 1; a++) {
        final double ax = musicalDomeX + a * 26.0;
        final Path blueTent = Path()
          ..moveTo(ax - 22, mdBaseY)
          ..quadraticBezierTo(ax, mdBaseY - 36, ax + 22, mdBaseY)
          ..close();
        canvas.drawPath(
          blueTent,
          Paint()
            ..shader = ui.Gradient.linear(
              Offset(ax, mdBaseY - 36),
              Offset(ax, mdBaseY),
              const [Color(0xFF40C4FF), Color(0xFF1565C0), Color(0xFF0D2149)],
              const [0.0, 0.5, 1.0],
            ),
        );
        canvas.drawPath(
          blueTent,
          Paint()
            ..color = const Color(0xFF80D8FF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
      }
    }

    // -------------------------------------------------------------------------
    // B. THE MONUMENTAL KÖLNER DOM (EXACT RONCALLIPLATZ VIEW FROM PHOTOS 1 & 3!)
    //    - Left half: Colossal Twin West Towers (Nordturm & Südturm, 157m)
    //    - Center-Right half: Floodlit Silver-Grey Nave Roof, Flying Buttresses,
    //      Grand South Transept Façade (Südquerhaus) & Slender Crossing Spire (Dachreiter)
    // -------------------------------------------------------------------------
    // Architectural floodlight aura behind the Cathedral
    canvas.drawCircle(
      Offset(domX, domBaseY - 95 * scale),
      210 * scale,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(domX, domBaseY - 95 * scale),
          210 * scale,
          [
            const Color(0xFFFFE082).withValues(alpha: 0.30),
            const Color(0xFFB0BEC5).withValues(alpha: 0.12),
            Colors.transparent,
          ],
          const [0.0, 0.55, 1.0],
        ),
    );

    final ui.Image? domImg = CologneChristmasAssets.cathedral;
    if (domImg != null) {
      // Photorealistic Kölner Dom architectural cutout integrated directly into our scene
      final double domW = 365.0 * scale;
      final double domH = 262.0 * scale;
      final Rect srcRect = Rect.fromLTWH(
        0,
        0,
        domImg.width.toDouble(),
        domImg.height.toDouble(),
      );
      final Rect dstRect = Rect.fromLTRB(
        domX - domW * 0.46,
        domBaseY - domH + 12.0 * scale,
        domX + domW * 0.54,
        domBaseY + 12.0 * scale,
      );
      canvas.drawImageRect(
        domImg,
        srcRect,
        dstRect,
        Paint()..filterQuality = FilterQuality.medium,
      );
    } else {
      final Paint darkStonePaint = Paint()..color = const Color(0xFF282522);
      final Paint midStonePaint = Paint()..color = const Color(0xFF423D37);
      final Paint floodlitStonePaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(domX, domBaseY),
          Offset(domX, domBaseY - 245 * scale),
          const [
            Color(0xFFD6C3A5),
            Color(0xFFA89882),
            Color(0xFF756A5C),
            Color(0xFF4A433B),
            Color(0xFF332E29),
          ],
          const [0.0, 0.25, 0.55, 0.80, 1.0],
        );
      final Paint gothicRibPaint = Paint()
        ..color = const Color(0xFFDED0B8).withValues(alpha: 0.76)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1;
      final Paint whiteFialePaint = Paint()..color = const Color(0xFFE0D6C5);

      // 1. Long Gothic Nave (Langhaus) & Floodlit Silver-Grey Lead Roof (Kirchendach)
      final double naveLeft = domX - 30 * scale;
      final double naveRight = domX + 86 * scale;
      final double naveWallTop = domBaseY - 82 * scale;
      final double naveRoofRidge = domBaseY - 114 * scale;

      final Path silverNaveRoof = Path()
        ..moveTo(naveLeft, naveWallTop)
        ..lineTo(naveLeft + 12 * scale, naveRoofRidge)
        ..lineTo(naveRight - 14 * scale, naveRoofRidge)
        ..lineTo(naveRight, naveWallTop)
        ..close();
      canvas.drawPath(
        silverNaveRoof,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(domX, naveRoofRidge),
            Offset(domX, naveWallTop),
            const [
              Color(0xFFCFD8DC),
              Color(0xFFECEFF1),
              Color(0xFF90A4AE),
            ],
            const [0.0, 0.55, 1.0],
          ),
      );
      canvas.drawLine(
        Offset(naveLeft + 12 * scale, naveRoofRidge),
        Offset(naveRight - 14 * scale, naveRoofRidge),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.85)
          ..strokeWidth = 1.8,
      );

      canvas.drawRect(
        Rect.fromLTRB(naveLeft, naveWallTop, naveRight, domBaseY),
        darkStonePaint,
      );

      for (int bay = 0; bay < 10; bay++) {
        final double bx = naveLeft + 6 * scale + bay * 11.2 * scale;
        final Path bayWindow = Path()
          ..moveTo(bx - 3.6 * scale, domBaseY - 42 * scale)
          ..lineTo(bx - 3.6 * scale, naveWallTop + 12 * scale)
          ..quadraticBezierTo(
            bx,
            naveWallTop + 3 * scale,
            bx + 3.6 * scale,
            naveWallTop + 12 * scale,
          )
          ..lineTo(bx + 3.6 * scale, domBaseY - 42 * scale)
          ..close();
        canvas.drawPath(
          bayWindow,
          Paint()..color = const Color(0xFF263238),
        );
        canvas.drawPath(bayWindow, gothicRibPaint);

        final Path gablet = Path()
          ..moveTo(bx - 4.5 * scale, domBaseY - 42 * scale)
          ..lineTo(bx, domBaseY - 52 * scale)
          ..lineTo(bx + 4.5 * scale, domBaseY - 42 * scale)
          ..close();
        canvas.drawPath(gablet, whiteFialePaint);

        final double pierX = bx + 5.6 * scale;
        canvas.drawRect(
          Rect.fromLTRB(
            pierX - 1.8 * scale,
            naveWallTop - 4 * scale,
            pierX + 1.8 * scale,
            domBaseY,
          ),
          floodlitStonePaint,
        );
        final Path fiale = Path()
          ..moveTo(pierX - 2.2 * scale, naveWallTop - 4 * scale)
          ..lineTo(pierX, naveWallTop - 22 * scale)
          ..lineTo(pierX + 2.2 * scale, naveWallTop - 4 * scale)
          ..close();
        canvas.drawPath(fiale, whiteFialePaint);
      }

      final double transeptX = domX + 26.0 * scale;

      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(transeptX, naveRoofRidge - 14 * scale),
          width: 11 * scale,
          height: 28 * scale,
        ),
        Paint()..color = const Color(0xFFCFD8DC),
      );
      final Path dachreiterSpire = Path()
        ..moveTo(transeptX - 5.5 * scale, naveRoofRidge - 28 * scale)
        ..lineTo(transeptX, naveRoofRidge - 78 * scale)
        ..lineTo(transeptX + 5.5 * scale, naveRoofRidge - 28 * scale)
        ..close();
      canvas.drawPath(
        dachreiterSpire,
        Paint()..color = const Color(0xFFB0BEC5),
      );
      canvas.drawCircle(
        Offset(transeptX, naveRoofRidge - 80 * scale),
        2.2 * scale,
        Paint()..color = const Color(0xFFFFF59D),
      );

      final Rect transeptBody = Rect.fromCenter(
        center: Offset(transeptX, domBaseY - 44 * scale),
        width: 42 * scale,
        height: 88 * scale,
      );
      canvas.drawRect(transeptBody, floodlitStonePaint);
      canvas.drawRect(transeptBody, gothicRibPaint);

      final Path transeptGable = Path()
        ..moveTo(transeptX - 21 * scale, domBaseY - 88 * scale)
        ..lineTo(transeptX, domBaseY - 126 * scale)
        ..lineTo(transeptX + 21 * scale, domBaseY - 88 * scale)
        ..close();
      canvas.drawPath(transeptGable, midStonePaint);
      canvas.drawPath(transeptGable, gothicRibPaint);

      for (final double side in [-1.0, 1.0]) {
        final double ptx = transeptX + side * 19.5 * scale;
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(ptx, domBaseY - 56 * scale),
            width: 5.5 * scale,
            height: 112 * scale,
          ),
          floodlitStonePaint,
        );
        final Path turretSpire = Path()
          ..moveTo(ptx - 3.2 * scale, domBaseY - 112 * scale)
          ..lineTo(ptx, domBaseY - 134 * scale)
          ..lineTo(ptx + 3.2 * scale, domBaseY - 112 * scale)
          ..close();
        canvas.drawPath(turretSpire, whiteFialePaint);
      }

      final Path southWindow = Path()
        ..moveTo(transeptX - 12.5 * scale, domBaseY - 38 * scale)
        ..lineTo(transeptX - 12.5 * scale, domBaseY - 68 * scale)
        ..quadraticBezierTo(
          transeptX,
          domBaseY - 86 * scale,
          transeptX + 12.5 * scale,
          domBaseY - 68 * scale,
        )
        ..lineTo(transeptX + 12.5 * scale, domBaseY - 38 * scale)
        ..close();
      canvas.drawPath(
        southWindow,
        Paint()..color = const Color(0xFF1F2429),
      );
      canvas.drawPath(southWindow, gothicRibPaint);
      canvas.drawCircle(
        Offset(transeptX, domBaseY - 68 * scale),
        8.5 * scale,
        gothicRibPaint,
      );
      for (int l = -2; l <= 2; l++) {
        canvas.drawLine(
          Offset(transeptX + l * 4.2 * scale, domBaseY - 60 * scale),
          Offset(transeptX + l * 4.2 * scale, domBaseY - 38 * scale),
          gothicRibPaint,
        );
      }

      for (final double pOff in [-12.0, 0.0, 12.0]) {
        final double pw = (pOff == 0.0 ? 11.0 : 7.5) * scale;
        final double ph = (pOff == 0.0 ? 28.0 : 21.0) * scale;
        final double px = transeptX + pOff * scale;
        final Path portal = Path()
          ..moveTo(px - pw * 0.5, domBaseY)
          ..lineTo(px - pw * 0.5, domBaseY - ph * 0.6)
          ..quadraticBezierTo(
            px,
            domBaseY - ph,
            px + pw * 0.5,
            domBaseY - ph * 0.6,
          )
          ..lineTo(px + pw * 0.5, domBaseY)
          ..close();
        canvas.drawPath(portal, Paint()..color = const Color(0xFF1A1715));
        canvas.drawPath(portal, gothicRibPaint);
      }

      for (int tIdx = 0; tIdx < 2; tIdx++) {
        final double tx = domX + (tIdx == 0 ? -42.0 : -11.0) * scale;
        final double towerScale = tIdx == 1 ? 1.0 : 0.94;

        final double shaftH = 114.0 * towerScale * scale;
        final double shaftW = 30.0 * towerScale * scale;
        final Rect shaftRect = Rect.fromCenter(
          center: Offset(tx, domBaseY - shaftH * 0.5),
          width: shaftW,
          height: shaftH,
        );
        canvas.drawRect(shaftRect, floodlitStonePaint);
        canvas.drawRect(shaftRect, gothicRibPaint);

        final double belfryTop = domBaseY - 150.0 * towerScale * scale;
        final Rect belfryRect = Rect.fromLTRB(
          tx - 11.5 * towerScale * scale,
          belfryTop,
          tx + 11.5 * towerScale * scale,
          domBaseY - shaftH,
        );
        canvas.drawRect(belfryRect, midStonePaint);
        canvas.drawRect(belfryRect, gothicRibPaint);

        for (final double bOff in [-13.5, -4.5, 4.5, 13.5]) {
          final double bx = tx + bOff * towerScale * scale;
          canvas.drawLine(
            Offset(bx, domBaseY),
            Offset(bx, domBaseY - shaftH),
            Paint()
              ..color = const Color(0xFFE0D4C0).withValues(alpha: 0.72)
              ..strokeWidth = 1.6,
          );
          final double pinH =
              (bOff.abs() > 9 ? 26.0 : 16.0) * towerScale * scale;
          final Path pin = Path()
            ..moveTo(bx - 2.4 * scale, domBaseY - shaftH)
            ..lineTo(bx, domBaseY - shaftH - pinH)
            ..lineTo(bx + 2.4 * scale, domBaseY - shaftH)
            ..close();
          canvas.drawPath(pin, whiteFialePaint);
        }

        for (int tier = 0; tier < 3; tier++) {
          final double wy = domBaseY - (34 + tier * 38) * towerScale * scale;
          final double wH = (tier == 1 ? 26.0 : 20.0) * towerScale * scale;
          for (final double wxOff in [-5.2, 5.2]) {
            final double lx = tx + wxOff * towerScale * scale;
            final Path lancet = Path()
              ..moveTo(lx - 2.8 * scale, wy + wH * 0.45)
              ..lineTo(lx - 2.8 * scale, wy - wH * 0.25)
              ..quadraticBezierTo(
                lx,
                wy - wH * 0.65,
                lx + 2.8 * scale,
                wy - wH * 0.25,
              )
              ..lineTo(lx + 2.8 * scale, wy + wH * 0.45)
              ..close();
            canvas.drawPath(
              lancet,
              Paint()
                ..color = tier == 0
                    ? const Color(0xFFFFD54F).withValues(alpha: 0.45)
                    : const Color(0xFF1A1816),
            );
            canvas.drawPath(lancet, gothicRibPaint);
          }
        }

        for (final double cOff in [-12.0, -7.5, 7.5, 12.0]) {
          final double cx = tx + cOff * towerScale * scale;
          final double ch = (cOff.abs() > 9 ? 24.0 : 16.0) * towerScale * scale;
          final Path cornerPin = Path()
            ..moveTo(cx - 2.0 * scale, belfryTop)
            ..lineTo(cx, belfryTop - ch)
            ..lineTo(cx + 2.0 * scale, belfryTop)
            ..close();
          canvas.drawPath(cornerPin, whiteFialePaint);
        }

        final double spirePeakY = domBaseY - 252.0 * towerScale * scale;
        final double spireHalfW = 11.8 * towerScale * scale;
        final Path spirePath = Path()
          ..moveTo(tx - spireHalfW, belfryTop)
          ..lineTo(tx, spirePeakY)
          ..lineTo(tx + spireHalfW, belfryTop)
          ..close();
        canvas.drawPath(
          spirePath,
          Paint()..color = const Color(0xFF2E2924).withValues(alpha: 0.88),
        );

        for (final double rFactor in [-1.0, -0.45, 0.0, 0.45, 1.0]) {
          canvas.drawLine(
            Offset(tx + rFactor * spireHalfW, belfryTop),
            Offset(tx, spirePeakY),
            Paint()
              ..color = const Color(0xFFD6C6AE).withValues(alpha: 0.82)
              ..strokeWidth = rFactor.abs() == 1.0 ? 1.6 : 1.0,
          );
        }

        for (int c = 1; c <= 11; c++) {
          final double frac = c / 12.0;
          final double cy = belfryTop + (spirePeakY - belfryTop) * frac;
          final double halfW = spireHalfW * (1.0 - frac);
          canvas.drawLine(
            Offset(tx - halfW, cy),
            Offset(tx + halfW, cy),
            gothicRibPaint,
          );
          canvas.drawCircle(
            Offset(tx - halfW - 1.3, cy),
            1.25,
            whiteFialePaint,
          );
          canvas.drawCircle(
            Offset(tx + halfW + 1.3, cy),
            1.25,
            whiteFialePaint,
          );
        }

        canvas.drawLine(
          Offset(tx, spirePeakY),
          Offset(tx, spirePeakY - 10 * scale),
          Paint()
            ..color = const Color(0xFFE0D4C0)
            ..strokeWidth = 2.0,
        );
        canvas.drawCircle(
          Offset(tx, spirePeakY - 5.5 * scale),
          2.8 * scale,
          whiteFialePaint,
        );
      }
    }

    // -------------------------------------------------------------------------
    // C. LEFT & RIGHT RONCALLIPLATZ FLANKING BUILDINGS (326°..346° & 28°..56°)
    //    2-Layer Deep Photorealistic Streetwall framing Kölner Dom with zero gaps!
    // -------------------------------------------------------------------------
    final double flankBaseY = horizonY + groundHeight * 0.265;
    for (final (double hDeg, int sliceIdx, double hw, double hh, Color? tint, double yOff)
        in const [
      // Left Wing Back Row (327°..343° — Taller atmospheric palaces & towers)
      (328.5, 7, 92.0, 196.0, Color(0xFFD7CCC8), -16.0),
      (336.5, 5, 118.0, 184.0, Color(0xFFCFD8DC), -18.0),
      // Left Wing Front Row (Excelsior Hotel Ernst at 331° + Kurienhaus gables)
      (326.5, 3, 62.0, 154.0, Color(0xFFFFCCBC), 0.0),
      (332.0, 5, 116.0, 168.0, Color(0xFFFFF3E0), 0.0),
      (338.5, 1, 62.0, 152.0, Color(0xFFFFE0B2), 0.0),
      (343.0, 4, 68.0, 158.0, null, 0.0),
      // Right Wing Back Row (29°..54° — Taller atmospheric Gothic & Mansard roofs)
      (33.5, 5, 114.0, 182.0, Color(0xFFCFD8DC), -16.0),
      (43.0, 6, 86.0, 204.0, Color(0xFFD7CCC8), -16.0),
      (51.5, 5, 108.0, 178.0, Color(0xFFCFD8DC), -14.0),
      // Right Wing Front Row (Domkloster 4 Palace, Römisch-Germanisches Wing & Brauhaus Früh am Dom)
      (30.5, 4, 68.0, 158.0, Color(0xFFEFEBE9), 0.0),
      (36.0, 5, 106.0, 164.0, Color(0xFFFFF8E1), 0.0),
      (42.5, 0, 60.0, 154.0, Color(0xFFFFE0B2), 0.0),
      (47.5, 2, 62.0, 160.0, null, 0.0),
      (53.0, 3, 66.0, 162.0, Color(0xFFFFCCBC), 0.0),
    ]) {
      final double? hx = _worldAngleToScreenX(hDeg, size, margin: 380);
      if (hx == null) continue;
      _drawSingleAltstadtHouseSlice(
        canvas,
        sliceIndex: sliceIdx,
        centerX: hx,
        baseY: flankBaseY + yOff,
        width: hw,
        height: hh,
        tintColor: tint,
        addDormerOrChimney: yOff == 0.0,
      );
    }

    // Grove of 5 bare winter sycamore trees wrapped in glowing golden fairy lights at 342°
    final double? leftWingX = _worldAngleToScreenX(342.0, size, margin: 380);
    if (leftWingX != null) {
      final double lBaseY = horizonY + groundHeight * 0.285;
      canvas.save();
      canvas.translate(leftWingX, lBaseY);
      canvas.scale(1.75);
      for (int tree = 0; tree < 5; tree++) {
        final double btx = -68.0 + tree * 30.0;
        final double bty = 10.0 - tree * 3.0;
        final Paint branchPaint = Paint()
          ..color = const Color(0xFF2D221B)
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(btx, bty), Offset(btx, bty - 40), branchPaint);
        for (int br = -2; br <= 2; br++) {
          if (br == 0) continue;
          canvas.drawLine(
            Offset(btx, bty - 16 - br.abs() * 4),
            Offset(btx + br * 9.0, bty - 36 - br.abs() * 3),
            branchPaint,
          );
          canvas.drawCircle(
            Offset(btx + br * 6.0, bty - 26 - br.abs() * 2),
            2.2,
            Paint()..color = const Color(0xFFFFF59D).withValues(alpha: 0.88),
          );
        }
      }
      canvas.restore();
    }
  }

  // ===========================================================================
  // 5. 72° ZONE — HEINZELS WINTERMÄRCHEN (HEUMARKT) ICE RINK, GÜRZENICH & ALMHÜTTE
  // ===========================================================================
  void _drawHeumarktIceRinkAndSkaters(
    Canvas canvas,
    Size size,
    double horizonY,
    double groundHeight,
  ) {
    final double? rinkCenterX = _worldAngleToScreenX(72.0, size, margin: 920);
    if (rinkCenterX == null) return;

    final double lodgeBaseY = horizonY + groundHeight * 0.262;

    // 1. 2-Layer Deep Photorealistic Heumarkt Streetwall & Gürzenich Banquet Hall (58°..94°)
    for (final (double hDeg, int sliceIdx, double hw, double hh, Color? tint, double yOff)
        in const [
      // Back row (Gothic Gürzenich belfry at 60°, Romanesque Overstolzenhaus tower at 74°, Guildhall at 86°)
      (60.0, 7, 98.0, 208.0, Color(0xFFD7CCC8), -16.0),
      (68.5, 5, 114.0, 182.0, Color(0xFFCFD8DC), -18.0),
      (78.0, 6, 88.0, 204.0, Color(0xFFD7CCC8), -16.0),
      (88.0, 5, 112.0, 178.0, Color(0xFFCFD8DC), -16.0),
      // Front row (Gürzenich Banquet Hall at 59° + Full-Height Non-Repeating Heumarkt Patrizier Houses)
      (58.5, 5, 96.0, 166.0, Color(0xFFFFECB3), 0.0),
      (64.5, 0, 60.0, 156.0, null, 0.0),
      (69.5, 2, 60.0, 164.0, Color(0xFFFFECB3), 0.0),
      (74.5, 1, 62.0, 158.0, null, 0.0),
      (80.0, 4, 68.0, 168.0, Color(0xFFE1BEE7), 0.0),
      (85.5, 3, 60.0, 154.0, Color(0xFFFFCCBC), 0.0),
      (91.0, 5, 92.0, 162.0, Color(0xFFFFF9C4), 0.0),
    ]) {
      final double? hx = _worldAngleToScreenX(hDeg, size, margin: 340);
      if (hx == null) continue;
      _drawSingleAltstadtHouseSlice(
        canvas,
        sliceIndex: sliceIdx,
        centerX: hx,
        baseY: lodgeBaseY + yOff,
        width: hw,
        height: hh,
        tintColor: tint,
        addDormerOrChimney: yOff == 0.0,
      );
    }

    // Foreground 2-Story Alpine Timber Lodge ("Heinzels Almhütte") directly behind the Heumarkt Ice Rink (72°)
    final ui.Image? chaletImg =
        CologneChristmasAssets.stallGrill ?? CologneChristmasAssets.stall;
    if (chaletImg != null) {
      canvas.drawImageRect(
        chaletImg,
        Rect.fromLTWH(
          0,
          0,
          chaletImg.width.toDouble(),
          chaletImg.height.toDouble(),
        ),
        Rect.fromCenter(
          center: Offset(rinkCenterX, lodgeBaseY - 40.0),
          width: 152.0,
          height: 96.0,
        ),
        Paint()..filterQuality = FilterQuality.medium,
      );
    }

    // Perimeter Golden Fir Trees framing the left and right edges of the Heumarkt Ice Rink
    for (final double tDeg in const [62.0, 65.5, 81.5, 85.5, 89.5]) {
      final double? tx = _worldAngleToScreenX(tDeg, size, margin: 200);
      if (tx == null) continue;
      _drawGoldenPerimeterFirTree(
        canvas,
        Offset(tx, horizonY + groundHeight * 0.27),
        seed: tDeg.toInt(),
      );
    }

    // 2. Sweeping Heumarkt Outdoor Ice Skating Rink (baseY = horizonY + groundHeight * 0.33)
    final double rinkBaseY = horizonY + groundHeight * 0.33;
    const double rinkW = 410.0;
    final double rinkH = (groundHeight * 0.16).clamp(38.0, 74.0);
    final Rect rinkRect = Rect.fromCenter(
      center: Offset(rinkCenterX, rinkBaseY),
      width: rinkW,
      height: rinkH,
    );

    canvas.drawOval(
      rinkRect.inflate(7.5),
      Paint()..color = const Color(0xFF5D4037),
    );
    canvas.drawOval(
      rinkRect,
      Paint()
        ..shader = ui.Gradient.linear(
          rinkRect.topLeft,
          rinkRect.bottomRight,
          const [
            Color(0xFFB3E5FC),
            Color(0xFFE1F5FE),
            Color(0xFF81D4FA),
            Color(0xFFE0F7FA),
          ],
          const [0.0, 0.38, 0.72, 1.0],
        ),
    );

    final Paint trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.58)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    canvas.drawOval(rinkRect.deflate(16.0), trackPaint);

    // Equestrian Bronze Monument (Reiterstandbild Friedrich Wilhelm III) in center of ice rink
    final Offset monumentBase = Offset(rinkCenterX - 36, rinkBaseY - 4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(monumentBase.dx, monumentBase.dy - 14),
          width: 22,
          height: 26,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF787068),
    );
    final Paint bronzePaint = Paint()..color = const Color(0xFF4DB6AC);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(monumentBase.dx, monumentBase.dy - 32),
        width: 19,
        height: 9.5,
      ),
      bronzePaint,
    );
    canvas.drawCircle(
      Offset(monumentBase.dx + 8, monumentBase.dy - 39),
      4.2,
      bronzePaint,
    );

    // Illuminated Timber Footbridge arching over the ice rink
    final Offset bridgeCenter = Offset(rinkCenterX + 54, rinkBaseY - 6);
    final Path bridgeArch = Path()
      ..moveTo(bridgeCenter.dx - 50, bridgeCenter.dy + 12)
      ..quadraticBezierTo(
        bridgeCenter.dx,
        bridgeCenter.dy - 26,
        bridgeCenter.dx + 50,
        bridgeCenter.dy + 12,
      );
    canvas.drawPath(
      bridgeArch,
      Paint()
        ..color = const Color(0xFF5D4037)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0,
    );

    // 8 Animated Ice Skaters gliding on the rink
    const List<Color> skaterCoats = [
      Color(0xFFE53935),
      Color(0xFF1E88E5),
      Color(0xFF8E24AA),
      Color(0xFF43A047),
      Color(0xFFFB8C00),
      Color(0xFFD81B60),
      Color(0xFF00ACC1),
      Color(0xFF3949AB),
    ];
    for (int i = 0; i < 8; i++) {
      final double phase = time * (0.90 + (i % 3) * 0.16) + i * 0.78;
      final double sx = rinkCenterX + math.sin(phase) * (rinkW * 0.40);
      final double sy = rinkBaseY + math.sin(phase * 2.0) * (rinkH * 0.35);
      final double lean = math.cos(phase) * 0.18;
      _drawIceSkater(
        canvas,
        Offset(sx, sy),
        coatColor: skaterCoats[i],
        lean: lean,
        phase: phase,
      );
    }
  }

  void _drawIceSkater(
    Canvas canvas,
    Offset pos, {
    required Color coatColor,
    required double lean,
    required double phase,
  }) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.scale(1.72, 1.72);
    canvas.rotate(lean);

    final double stride = math.sin(phase * 4.0) * 3.6;
    final Paint legPaint = Paint()
      ..color = const Color(0xFF263238)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      const Offset(-1.5, -6),
      Offset(-2.5 - stride, 0),
      legPaint,
    );
    canvas.drawLine(
      const Offset(1.5, -6),
      Offset(2.5 + stride, -1.0),
      legPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, -10), width: 7.5, height: 9.5),
        const Radius.circular(3),
      ),
      Paint()..color = coatColor,
    );
    canvas.drawCircle(
      const Offset(0, -17),
      2.8,
      Paint()..color = const Color(0xFFFFCCBC),
    );
    canvas.drawCircle(
      const Offset(0, -19.5),
      1.5,
      Paint()..color = Colors.white,
    );
    canvas.restore();
  }

  // ===========================================================================
  // 6. 128° ZONE — HISTORISCHES RATHAUS, NON-REPEATING ALTSTADT HOUSES & PYRAMID
  // ===========================================================================
  void _drawAltstadtLichtertorAndPyramid(
    Canvas canvas,
    Size size,
    double horizonY,
    double groundHeight,
  ) {
    final double altstadtBaseY = horizonY + groundHeight * 0.255;

    // 1 & 2. Continuous 2-Layer Deep Photorealistic Streetwall of Alter Markt & Historisches Rathaus (96°..164°)
    //        Features the towering 61m Historisches Rathaus Tower at 118.5° (slice 6 + slice 7)
    //        and 2 overlapping rows of full-height, non-repeating historic facades!
    for (final (double hDeg, int sliceIdx, double hw, double hh, Color? tint, double yOff)
        in const [
      // Back row (taller historic towers, Gothic spires & Mansard palaces filling every rooftop gap!)
      (99.5, 5, 110.0, 184.0, Color(0xFFCFD8DC), -18.0),
      (108.5, 7, 88.0, 202.0, Color(0xFFD7CCC8), -16.0),
      (118.5, 6, 114.0, 246.0, Color(0xFFFFECB3), -8.0), // Towering Historisches Rathaus Köln Belfry!
      (128.5, 5, 118.0, 186.0, Color(0xFFCFD8DC), -18.0),
      (139.0, 7, 92.0, 204.0, Color(0xFFD7CCC8), -16.0),
      (149.0, 5, 112.0, 182.0, Color(0xFFCFD8DC), -18.0),
      (158.0, 6, 86.0, 198.0, Color(0xFFD7CCC8), -14.0),
      // Front row (15 full-height non-repeating Alter Markt Patrizier houses & Rathaus Renaissance Loggia)
      (96.5, 0, 58.0, 154.0, null, 0.0),
      (101.0, 4, 66.0, 168.0, Color(0xFFFFF3E0), 0.0),
      (105.5, 5, 88.0, 160.0, Color(0xFFFFF8E1), 0.0),
      (110.0, 2, 58.0, 158.0, Color(0xFFE8F5E9), 0.0),
      (114.0, 1, 56.0, 152.0, Color(0xFFFFCCBC), 0.0),
      (118.5, 7, 96.0, 174.0, Color(0xFFFFE0B2), 0.0), // Ornate Gothic/Renaissance Rathaus Loggia Base!
      (123.5, 3, 60.0, 160.0, null, 0.0),
      (128.0, 5, 92.0, 164.0, Color(0xFFFFECB3), 0.0),
      (132.5, 4, 64.0, 172.0, null, 0.0),
      (137.0, 0, 58.0, 152.0, Color(0xFFF8BBD0), 0.0),
      (141.5, 2, 60.0, 162.0, null, 0.0),
      (146.0, 5, 88.0, 158.0, Color(0xFFE0F2F1), 0.0),
      (150.5, 1, 58.0, 154.0, null, 0.0),
      (155.0, 3, 62.0, 166.0, Color(0xFFFFE0B2), 0.0),
      (160.0, 4, 66.0, 158.0, Color(0xFFD1C4E9), 0.0),
    ]) {
      final double? hx = _worldAngleToScreenX(hDeg, size, margin: 340);
      if (hx == null) continue;
      _drawSingleAltstadtHouseSlice(
        canvas,
        sliceIndex: sliceIdx,
        centerX: hx,
        baseY: altstadtBaseY + yOff,
        width: hw,
        height: hh,
        tintColor: tint,
        addDormerOrChimney: yOff == 0.0 && hDeg.toInt().isEven,
      );
    }

    // 3. Historic Jan-von-Werth-Brunnen Sandstone Market Fountain Monument at 108°
    final double? fountainX = _worldAngleToScreenX(108.0, size, margin: 240);
    if (fountainX != null) {
      final double fBaseY = horizonY + groundHeight * 0.285;
      canvas.save();
      canvas.translate(fountainX, fBaseY);
      canvas.scale(1.55);
      canvas.drawRect(
        Rect.fromCenter(center: const Offset(0, -6), width: 32, height: 12),
        Paint()..color = const Color(0xFF787068),
      );
      canvas.drawRect(
        Rect.fromCenter(center: const Offset(0, -24), width: 12, height: 32),
        Paint()..color = const Color(0xFF8D8278),
      );
      canvas.drawCircle(
        const Offset(0, -44),
        5.0,
        Paint()..color = const Color(0xFF4DB6AC),
      );
      canvas.restore();
    }

    // 4. Towering 4-Tier Wooden Erzgebirge Christmas Pyramid (Weihnachtspyramide) at 128° (baseY = 0.35)
    final double? pyrX = _worldAngleToScreenX(128.0, size, margin: 280);
    if (pyrX != null) {
      _drawWeihnachtspyramide(
        canvas,
        Offset(pyrX, horizonY + groundHeight * 0.35),
      );
    }

    // 5. Row of 14 Densely-Lit Golden Perimeter Christmas Trees & 2 Glowing Entrance Portals (Lichtertor at 104° & 156°)
    for (int t = 0; t < 14; t++) {
      final double treeDeg = 98.0 + t * 4.8;
      final double? tx = _worldAngleToScreenX(treeDeg, size, margin: 200);
      if (tx == null) continue;
      final double ty = horizonY + groundHeight * 0.265;
      _drawGoldenPerimeterFirTree(canvas, Offset(tx, ty), seed: t);
    }

    for (final double torDeg in const [104.0, 156.0]) {
      final double? torX = _worldAngleToScreenX(torDeg, size, margin: 240);
      if (torX == null) continue;
      final double torY = horizonY + groundHeight * 0.30;
      canvas.save();
      canvas.translate(torX, torY);
      canvas.scale(1.68);
      for (int s = 0; s < 5; s++) {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(0, -s * 2.8),
            width: 34,
            height: 2.2,
          ),
          Paint()..color = const Color(0xFF8D8278),
        );
      }
      final Paint goldArchPaint = Paint()..color = const Color(0xFFFFF59D);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-22, -32, 7, 32),
          const Radius.circular(2),
        ),
        goldArchPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(15, -32, 7, 32),
          const Radius.circular(2),
        ),
        goldArchPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-22, -36, 44, 7),
          const Radius.circular(2),
        ),
        goldArchPaint,
      );
      canvas.restore();
    }
  }

  void _drawGoldenPerimeterFirTree(
    Canvas canvas,
    Offset base, {
    required int seed,
  }) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.scale(1.55);

    final Path cone = Path()
      ..moveTo(-12, 0)
      ..lineTo(0, -34)
      ..lineTo(12, 0)
      ..close();
    canvas.drawPath(cone, Paint()..color = const Color(0xFF1B4D20));
    for (int r = 0; r < 6; r++) {
      final double ry = -3.0 - r * 5.0;
      final double rw = 10.0 * (1.0 - r / 6.5);
      for (int c = -2; c <= 2; c++) {
        canvas.drawCircle(
          Offset((c / 2.2) * rw, ry + (c.isEven ? 0.8 : -0.8)),
          1.3,
          Paint()..color = const Color(0xFFFFF59D),
        );
      }
    }
    canvas.drawCircle(
      const Offset(0, -35.5),
      2.6,
      Paint()..color = const Color(0xFFFFEE58),
    );
    canvas.restore();
  }

  void _drawWeihnachtspyramide(Canvas canvas, Offset base) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.scale(1.68, 1.68);
    canvas.translate(-base.dx, -base.dy);

    // Photorealistic Timber Tavern Base under the Christmas Pyramid
    final ui.Image? baseStall =
        CologneChristmasAssets.stall ?? CologneChristmasAssets.stallCrafts;
    if (baseStall != null) {
      canvas.drawImageRect(
        baseStall,
        Rect.fromLTWH(
          0,
          0,
          baseStall.width.toDouble(),
          baseStall.height.toDouble(),
        ),
        Rect.fromCenter(
          center: Offset(base.dx, base.dy - 26.0),
          width: 74.0,
          height: 58.0,
        ),
        Paint()..filterQuality = FilterQuality.medium,
      );
    }

    final Paint woodPaint = Paint()..color = const Color(0xFF5D4037);
    final Paint trimPaint = Paint()..color = const Color(0xFFFFD54F);
    final double pyrStartY = baseStall != null ? base.dy - 46.0 : base.dy;

    for (int t = 0; t < 4; t++) {
      final double ty = pyrStartY - t * 18.5;
      final double tw = 38.0 - t * 6.5;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(base.dx, ty - 9.5),
            width: tw,
            height: 18,
          ),
          const Radius.circular(2.5),
        ),
        woodPaint,
      );
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(base.dx, ty - 9.5),
          width: tw - 7,
          height: 11.5,
        ),
        Paint()..color = const Color(0xFFFFF59D).withValues(alpha: 0.90),
      );
      final double figOffset = math.sin(time * 2.4 + t) * (tw * 0.24);
      canvas.drawCircle(
        Offset(base.dx + figOffset, ty - 8.5),
        2.8,
        Paint()..color = const Color(0xFFB71C1C),
      );
      canvas.drawCircle(
        Offset(base.dx - tw * 0.5 - 2, ty - 4),
        1.9,
        trimPaint,
      );
      canvas.drawCircle(
        Offset(base.dx + tw * 0.5 + 2, ty - 4),
        1.9,
        trimPaint,
      );
    }

    final Offset rotorCenter = Offset(base.dx, pyrStartY - 80.0);
    for (int b = 0; b < 8; b++) {
      final double ang = time * 3.4 + (b * math.pi / 4.0);
      canvas.drawLine(
        rotorCenter,
        Offset(
          rotorCenter.dx + math.cos(ang) * 24.0,
          rotorCenter.dy + math.sin(ang) * 5.2,
        ),
        Paint()
          ..color = const Color(0xFFEFEBE9)
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.restore();
  }

  // ===========================================================================
  // 7. 176° ZONE — MALAKOFFTURM, SCHOKOLADENMUSEUM, FERRIS WHEEL & CAROUSEL
  // ===========================================================================
  void _drawFerrisWheelGrillAndCarousel(
    Canvas canvas,
    Size size,
    double horizonY,
    double groundHeight,
  ) {
    final double harborBaseY = horizonY + groundHeight * 0.262;

    // 0A. 2-Layer Deep Photorealistic Rheinauhafen Customs Hall, Malakoffturm & Schokoladenmuseum (164°..190°)
    //     Fills the background behind the Ferris Wheel & Harbour Market with 100% photorealistic architecture!
    for (final (double hDeg, int sliceIdx, double hw, double hh, Color? tint, double yOff)
        in const [
      // Back row (Taller historic customs towers & harbor warehouse roofs)
      (167.5, 5, 112.0, 178.0, Color(0xFFCFD8DC), -16.0),
      (175.5, 6, 88.0, 202.0, Color(0xFFFFCCBC), -14.0), // Historic Malakoffturm / Harbour Watchtower!
      (184.0, 7, 94.0, 194.0, Color(0xFFD7CCC8), -14.0),
      // Front row (Red-brick customs gables, Schokoladenmuseum Customs Hall & Rhine warehouses)
      (164.5, 2, 60.0, 154.0, null, 0.0),
      (169.5, 3, 64.0, 160.0, Color(0xFFFFCCBC), 0.0),
      (174.5, 5, 96.0, 158.0, Color(0xFFFFE0B2), 0.0),
      (181.0, 4, 72.0, 164.0, Color(0xFFE0F7FA), 0.0),
      (186.5, 3, 62.0, 152.0, Color(0xFFFFCCBC), 0.0),
    ]) {
      final double? hx = _worldAngleToScreenX(hDeg, size, margin: 320);
      if (hx == null) continue;
      _drawSingleAltstadtHouseSlice(
        canvas,
        sliceIndex: sliceIdx,
        centerX: hx,
        baseY: harborBaseY + yOff,
        width: hw,
        height: hh,
        tintColor: tint,
        addDormerOrChimney: yOff == 0.0,
      );
    }

    // 1. Giant 48m Illuminated Ferris Wheel (Riesenrad) at 172° (baseY = 0.24)
    final double? wheelX = _worldAngleToScreenX(172.0, size, margin: 360);
    if (wheelX != null) {
      final double wheelBaseY = horizonY + groundHeight * 0.24;
      const double radius = 94.0;
      final Offset wheelCenter = Offset(wheelX, wheelBaseY - radius - 16);

      final Paint supportPaint = Paint()
        ..color = const Color(0xFFECEFF1)
        ..strokeWidth = 4.5;
      canvas.drawLine(
        wheelCenter,
        Offset(wheelX - 52, wheelBaseY),
        supportPaint,
      );
      canvas.drawLine(
        wheelCenter,
        Offset(wheelX + 52, wheelBaseY),
        supportPaint,
      );

      canvas.drawCircle(
        wheelCenter,
        radius,
        Paint()
          ..color = const Color(0xFFFFD54F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.6,
      );
      canvas.drawCircle(
        wheelCenter,
        radius * 0.70,
        Paint()
          ..color = const Color(0xFF4FC3F7).withValues(alpha: 0.82)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );

      for (int i = 0; i < 16; i++) {
        final double ang = time * 0.32 + (i * math.pi / 8.0);
        final Offset rimPt = Offset(
          wheelCenter.dx + math.cos(ang) * radius,
          wheelCenter.dy + math.sin(ang) * radius,
        );
        canvas.drawLine(
          wheelCenter,
          rimPt,
          Paint()
            ..color = const Color(0xFFFFF59D).withValues(alpha: 0.72)
            ..strokeWidth = 1.4,
        );
        final RRect gondola = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(rimPt.dx, rimPt.dy + 8.0),
            width: 12.5,
            height: 11.0,
          ),
          const Radius.circular(3.5),
        );
        canvas.drawRRect(
          gondola,
          Paint()
            ..color = i.isEven
                ? const Color(0xFFD32F2F)
                : const Color(0xFFF5F5F5),
        );
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(rimPt.dx, rimPt.dy + 7.0),
            width: 8.0,
            height: 4.5,
          ),
          Paint()..color = const Color(0xFFFFF9C4),
        );
      }
      canvas.drawCircle(
        wheelCenter,
        11.0,
        Paint()..color = const Color(0xFFFFF59D),
      );
    }

    // 2. German Charcoal Swing-Grill (Schwenkgrill) Pavilion at 188° (baseY = 0.35)
    final double? grillX = _worldAngleToScreenX(188.0, size, margin: 260);
    if (grillX != null) {
      _drawSchwenkgrillHut(
        canvas,
        Offset(grillX, horizonY + groundHeight * 0.35),
      );
    }

    // 3. Red-Canopied Christmas Carousel (Karussell) at 37° (right side of Roncalliplatz in Photo 1 & 3!) AND at 204°
    for (final double cDeg in [37.0, 204.0]) {
      final double? carouselX = _worldAngleToScreenX(cDeg, size, margin: 260);
      if (carouselX != null) {
        _drawRedCanopyCarousel(
          canvas,
          Offset(
            carouselX,
            horizonY + groundHeight * (cDeg == 37.0 ? 0.35 : 0.33),
          ),
        );
      }
    }
  }

  void _drawSchwenkgrillHut(Canvas canvas, Offset base) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.scale(1.75, 1.75);
    canvas.translate(-base.dx, -base.dy);

    // Soft radial warm firelight reflection on the cobblestones
    canvas.save();
    canvas.translate(base.dx, base.dy + 2.0);
    canvas.scale(2.4, 0.34);
    canvas.drawCircle(
      Offset.zero,
      28.0,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset.zero,
          28.0,
          [
            const Color(0xFFFF6D00).withValues(alpha: 0.40),
            const Color(0xFFFFAB00).withValues(alpha: 0.16),
            Colors.transparent,
          ],
          const [0.0, 0.55, 1.0],
        ),
    );
    canvas.restore();

    final ui.Image? grillImg =
        CologneChristmasAssets.stallGrill ?? CologneChristmasAssets.stall;
    if (grillImg != null) {
      final Rect srcRect = Rect.fromLTWH(
        0,
        0,
        grillImg.width.toDouble(),
        grillImg.height.toDouble(),
      );
      final Rect dstRect = Rect.fromCenter(
        center: Offset(base.dx, base.dy - 31.0),
        width: 84.0,
        height: 68.0,
      );
      canvas.drawImageRect(
        grillImg,
        srcRect,
        dstRect,
        Paint()..filterQuality = FilterQuality.medium,
      );
    } else {
      final Paint postPaint = Paint()
        ..color = const Color(0xFF4E342E)
        ..strokeWidth = 3.4;
      canvas.drawLine(
        Offset(base.dx - 24, base.dy),
        Offset(base.dx - 24, base.dy - 29),
        postPaint,
      );
      canvas.drawLine(
        Offset(base.dx + 24, base.dy),
        Offset(base.dx + 24, base.dy - 29),
        postPaint,
      );

      final Path roof = Path()
        ..moveTo(base.dx - 31, base.dy - 29)
        ..lineTo(base.dx, base.dy - 48)
        ..lineTo(base.dx + 31, base.dy - 29)
        ..close();
      canvas.drawPath(roof, Paint()..color = const Color(0xFFB71C1C));
    }

    // Animated rising savory grill smoke wisps & ember flicker inside the Schwenkgrill window
    final double swingX = base.dx + math.sin(time * 2.8) * 2.5;
    for (int s = 0; s < 3; s++) {
      final double smokeProgress = (time * 0.65 + s * 0.33) % 1.0;
      final double sy = base.dy - 20 - smokeProgress * 22.0;
      final double sx =
          swingX + math.sin(time * 2.0 + s * 1.7) * (2.5 + smokeProgress * 4.5);
      canvas.drawCircle(
        Offset(sx, sy),
        2.2 + smokeProgress * 3.8,
        Paint()
          ..color = Colors.white.withValues(
            alpha: (1.0 - smokeProgress) * 0.22,
          ),
      );
    }
    canvas.restore();
  }

  void _drawRedCanopyCarousel(Canvas canvas, Offset base) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.scale(1.68, 1.68);
    canvas.translate(-base.dx, -base.dy);

    const double w = 58.0;
    const double h = 28.0;

    // Soft radial golden floor reflection around the vintage carousel
    canvas.save();
    canvas.translate(base.dx, base.dy + 2.0);
    canvas.scale(2.3, 0.34);
    canvas.drawCircle(
      Offset.zero,
      26.0,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset.zero,
          26.0,
          [
            const Color(0xFFFFD54F).withValues(alpha: 0.36),
            const Color(0xFFFF8F00).withValues(alpha: 0.14),
            Colors.transparent,
          ],
          const [0.0, 0.55, 1.0],
        ),
    );
    canvas.restore();

    // Ornate wooden carousel platform deck
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(base.dx, base.dy - 3),
          width: w,
          height: 6.5,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF4E342E),
    );
    canvas.drawLine(
      Offset(base.dx - w * 0.48, base.dy - 3),
      Offset(base.dx + w * 0.48, base.dy - 3),
      Paint()
        ..color = const Color(0xFFFFD54F)
        ..strokeWidth = 1.4,
    );

    // Warm golden interior carousel glow & central mirrored column
    final Rect interiorRect = Rect.fromCenter(
      center: Offset(base.dx, base.dy - h * 0.5 - 3),
      width: w * 0.84,
      height: h - 4,
    );
    canvas.drawRect(
      interiorRect,
      Paint()
        ..shader = ui.Gradient.linear(
          interiorRect.topCenter,
          interiorRect.bottomCenter,
          const [Color(0xFFFFF9C4), Color(0xFFFFB300)],
        ),
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(base.dx, base.dy - h * 0.5 - 3),
        width: 7.0,
        height: h - 4,
      ),
      Paint()..color = const Color(0xFFD7CCC8),
    );

    // Animated prancing carousel horses on brass poles
    for (int p = -1; p <= 1; p++) {
      final double phase = time * 2.2 + p * 2.1;
      final double px = base.dx + math.sin(phase) * (w * 0.30);
      final double py = base.dy - 13.0 + math.cos(phase * 2.0) * 2.5;
      canvas.drawLine(
        Offset(px, base.dy - h),
        Offset(px, base.dy - 6),
        Paint()
          ..color = const Color(0xFFFFD54F)
          ..strokeWidth = 1.3,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(px, py), width: 9.5, height: 5.2),
        Paint()
          ..color = p == 0 ? const Color(0xFFB71C1C) : const Color(0xFFFAFAFA),
      );
      canvas.drawCircle(
        Offset(px + 4.0, py - 3.2),
        2.2,
        Paint()
          ..color = p == 0 ? const Color(0xFFB71C1C) : const Color(0xFFFAFAFA),
      );
    }

    // Striped crimson-red and cream-gold domed carousel canopy
    final Path redCone = Path()
      ..moveTo(base.dx - w * 0.60, base.dy - h)
      ..lineTo(base.dx, base.dy - h - 19)
      ..lineTo(base.dx + w * 0.60, base.dy - h)
      ..close();
    canvas.drawPath(
      redCone,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(base.dx, base.dy - h - 19),
          Offset(base.dx, base.dy - h),
          const [Color(0xFFFF1744), Color(0xFFC62828), Color(0xFF8E0000)],
          const [0.0, 0.55, 1.0],
        ),
    );
    // Gold canopy ribs & scalloped valence with warm festoon lights
    for (final double rFactor in [-0.38, -0.18, 0.0, 0.18, 0.38]) {
      canvas.drawLine(
        Offset(base.dx, base.dy - h - 19),
        Offset(base.dx + w * rFactor, base.dy - h),
        Paint()
          ..color = const Color(0xFFFFE082).withValues(alpha: 0.78)
          ..strokeWidth = 1.3,
      );
    }
    canvas.drawLine(
      Offset(base.dx - w * 0.60, base.dy - h),
      Offset(base.dx + w * 0.60, base.dy - h),
      Paint()
        ..color = const Color(0xFF1B5E20)
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );
    for (int b = -4; b <= 4; b++) {
      canvas.drawCircle(
        Offset(base.dx + b * 7.2, base.dy - h),
        1.4,
        Paint()..color = const Color(0xFFFFF59D),
      );
    }
    _drawHerrnhuterStar(canvas, Offset(base.dx, base.dy - h - 20.5), 4.2);
    canvas.restore();
  }

  // ===========================================================================
  // 8. DENSE SEA OF DISTINCT RED-ROOFED COLOGNE MARKET STALLS, PLAZA PROPS & CROWD
  // ===========================================================================
  void _drawRedRoofedMarketSeaAndAvenues(
    Canvas canvas,
    Size size,
    double horizonY,
    double groundHeight,
  ) {
    // 1. MULTI-ROW SEA OF BRIGHT CRIMSON-RED PYRAMID/GABLE ROOFS WITH 5 DISTINCT STALL TYPES:
    //    - type 0: Glühwein, Punsch & Lebkuchen-Herzen Hütte (cologne_stall.png)
    //    - type 1: Original Kölner Schwenkgrill & Bratwurst Hütte (cologne_stall_grill.png)
    //    - type 2: Gebrannte Mandeln, Belgische Waffeln & Schokofrüchte Hütte (cologne_stall_sweets.png)
    //    - type 3: Erzgebirge Holzkunst, Herrnhuter Sterne & Nussknacker Hütte (cologne_stall_crafts.png)
    //    - type 4: Star- & Pyramid-Crowned Specialty Hütte (with mini spinning roof pyramid & star cluster)
    final List<(double deg, double yFactor, String label, String stallNo, int type)>
    marketStalls = const [
      // Row A (Upper Roncalliplatz near Cathedral steps, yFactor = 0.28..0.31)
      (-32.0, 0.28, 'DOM-GLÜHWEIN', '12', 0),
      (-22.0, 0.29, 'DOM-SPEKULATIUS', '14', 2),
      (-12.0, 0.28, 'HERRNHUTER STERNE', '18', 3),
      (12.0, 0.28, 'KÖLNER REIBEKUCHEN', '21', 1),
      (22.0, 0.29, 'FEUERZANGENBOWLE', '24', 0),
      (31.0, 0.28, 'GEBRANNTE MANDELN', '27', 2),

      // Row B (Mid-Upper Plaza Market Lanes, yFactor = 0.34..0.38)
      (-36.0, 0.35, 'HEISSE MARONEN', '34', 1),
      (-25.0, 0.36, 'KÄTHE WOHLFAHRT', '38', 3),
      (-15.0, 0.35, 'SCHOKO-FRÜCHTE', '42', 2),
      (15.0, 0.35, 'THÜRINGER BRATWURST', '46', 1),
      (25.0, 0.36, 'ERZGEBIRGE HOLZKUNST', '49', 3),
      (35.0, 0.35, 'DOM-WAFFELN', '52', 2),

      // Row C (Mid-Lower Plaza Market Lanes framing the Christmas Tree, yFactor = 0.43..0.48)
      (-39.0, 0.44, 'FLAMMKUCHEN & RACLETTE', '61', 1),
      (-27.0, 0.45, 'KRIPPENSPIEL & GLAS', '65', 3),
      (-16.0, 0.44, 'DOM-GLÜHWEIN & PUNSCH', '68', 0),
      (16.0, 0.44, 'SCHUPFNUDELN & KRAUT', '71', 1),
      (27.0, 0.45, 'LEBKUCHENHERZEN', '74', 2),
      (39.0, 0.44, 'AACHENER PRINTEN', '78', 0),

      // Row D (Closer Foreground-Flank Stalls creating the Photo 2 Eye-Level Corridor! yFactor = 0.54..0.58)
      (-34.0, 0.55, 'HANDWERKSKUNST', '82', 3),
      (-21.0, 0.56, 'GLÜHWEIN-PYRAMIDE', '71', 4),
      (21.0, 0.56, 'BELGISCHE WAFFELN', '72', 2),
      (34.0, 0.55, 'KÖLSCH & GLÜHWEIN', '85', 0),

      // Heumarkt Ice Rink Flanking Market Stalls (46°..94°)
      (47.0, 0.34, 'APFELGLÜHWEIN', '88', 0),
      (52.0, 0.48, 'HEUMARKT-MANDELN', '90', 2),
      (57.0, 0.56, 'HOLZKUNST & STERNE', '91', 3),
      (87.0, 0.56, 'KÖLNER SCHWENKGRILL', '92', 1),
      (92.0, 0.46, 'EISBAHN-PUNSCH', '93', 0),

      // Alter Markt & Heinzelmännchen Market Lanes (96°..164°)
      (97.0, 0.34, 'NASCHGASSE MANDELN', '94', 2),
      (105.0, 0.30, 'GLÜHWEIN-SCHÄNKE', '98', 0),
      (108.0, 0.55, 'HANDWERKSGASSE', '100', 3),
      (114.0, 0.41, 'BRATWURST & POMMES', '102', 1),
      (120.0, 0.50, 'SPIELZEUGGASSE', '105', 4),
      (136.0, 0.49, 'LEBKUCHEN & WAFFELN', '108', 2),
      (143.0, 0.40, 'KÄTHE WOHLFAHRT', '112', 3),
      (148.0, 0.55, 'SCHWENKGRILL-HÜTTE', '114', 1),
      (153.0, 0.32, 'DOM-LIKÖR & HONIG', '115', 0),
      (161.0, 0.43, 'RÄUCHERMÄNNCHEN', '118', 3),

      // Altstadt Ferris Wheel & Schwenkgrill Avenue Stalls (165°..222°)
      (165.0, 0.54, 'ALTSTADT-GLÜHWEIN', '120', 0),
      (169.0, 0.38, 'SCHWENKGRILL-STUBE', '121', 1),
      (184.0, 0.36, 'FEUERZANGENBOWLE', '122', 2),
      (192.0, 0.48, 'DAMPFNUDELN & WAFFELN', '123', 2),
      (199.0, 0.56, 'KÖLNER HOLZKUNST', '125', 3),
      (208.0, 0.42, 'GRILLHÜTTE AM RIESENRAD', '126', 1),
      (216.0, 0.35, 'HAFEN-GLÜHWEIN', '127', 0),
      (223.0, 0.52, 'STERNE & NUSSKNACKER', '129', 4),

      // Rhine Promenade & Hohenzollern Approach Stalls (230°..320°)
      (232.0, 0.40, 'RHEINUFER-PUNSCH', '130', 0),
      (239.0, 0.54, 'MANDELN & WAFFELN', '132', 2),
      (272.0, 0.54, 'DOMBRÜCKE-GRILLHÜTTE', '134', 1),
      (280.0, 0.42, 'HOLZKUNST AM RHEIN', '135', 3),
      (290.0, 0.35, 'KÖLSCHE SPEZIALITÄTEN', '137', 0),
      (300.0, 0.48, 'STERNE & LATERNE', '139', 4),
      (309.0, 0.55, 'SCHWENKGRILL & WURST', '141', 1),
      (316.0, 0.39, 'MANDELBRÄTEREI', '144', 2),
    ];

    final List<(double, double, String, String, int)> sortedStalls =
        List.of(marketStalls)..sort((a, b) => a.$2.compareTo(b.$2));

    for (int i = 0; i < sortedStalls.length; i++) {
      final (double deg, double yf, String label, String stallNo, int type) =
          sortedStalls[i];
      final double? sx = _worldAngleToScreenX(deg, size, margin: 320);
      if (sx == null) continue;
      final double sy = horizonY + groundHeight * yf;
      // Keep center tree trunk pedestal area (|x - cx| < 120 when yf > 0.47) unobstructed
      if (yf > 0.47 && (sx - size.width * 0.5).abs() < 125.0) continue;

      final double depthScale = 1.34 + (yf - 0.26) * 2.20;
      _drawPhotoAccurateCologneStall(
        canvas,
        Offset(sx, sy),
        label: label,
        stallNumber: stallNo,
        type: type,
        scale: depthScale,
        seed: i,
      );
    }

    // 2. RICH CHRISTMAS SQUARE STREET FURNITURE & AMBIENCE PROPS
    //    Standing Glühwein oak barrels (Stehtische), decorated mini fir trees in barrels,
    //    cast-iron garland streetlamps, steam-locomotive chestnut roasters & timber market arches!
    _drawMarketPlazaPropsAndFurniture(canvas, size, horizonY, groundHeight);

    // 3. Bustling Winter Crowd in Puffer Coats Strolling All 360° Market Lanes + Cute Little Black Dog from Photo 2!
    const List<Color> pufferColors = [
      Color(0xFF788276), // Olive-grey puffer from Photo 2 left!
      Color(0xFF1C2430), // Black/navy winter coat from Photo 2 center!
      Color(0xFF37474F), // Charcoal jacket from Photo 2 right!
      Color(0xFF9E2A2B), // Festive crimson coat
      Color(0xFF283593), // Deep royal blue parka
      Color(0xFF4E342E), // Brown wool coat
      Color(0xFF00695C), // Pine green parka
      Color(0xFF5D4037), // Warm cocoa puffer
    ];

    final List<(double deg, double yf, bool hasDog)> crowdPositions = const [
      (-31.0, 0.39, false),
      (-20.0, 0.42, false),
      (-11.0, 0.34, false),
      (-14.0, 0.49, false),
      (-9.0, 0.58, false),
      (9.0, 0.58, true), // Cute little black dog on a leash from Photo 2!
      (14.0, 0.48, false),
      (11.0, 0.34, false),
      (20.0, 0.42, false),
      (31.0, 0.39, false),
      (-26.0, 0.62, false),
      (26.0, 0.62, false),
      (-16.0, 0.64, false),
      (16.0, 0.64, false),
      (46.0, 0.42, false),
      (55.0, 0.52, false),
      (62.0, 0.58, false),
      (84.0, 0.58, false),
      (91.0, 0.50, false),
      (98.0, 0.42, false),
      (109.0, 0.46, false),
      (118.0, 0.54, false),
      (126.0, 0.44, false),
      (133.0, 0.52, true),
      (141.0, 0.45, false),
      (150.0, 0.40, false),
      (163.0, 0.50, false),
      (170.0, 0.45, false),
      (183.0, 0.44, false),
      (191.0, 0.54, false),
      (198.0, 0.42, false),
      (209.0, 0.48, false),
      (220.0, 0.44, false),
      (235.0, 0.48, false),
      (243.0, 0.56, false),
      (256.0, 0.46, true),
      (268.0, 0.55, false),
      (278.0, 0.48, false),
      (288.0, 0.42, false),
      (302.0, 0.52, false),
      (312.0, 0.44, false),
    ];

    for (int v = 0; v < crowdPositions.length; v++) {
      final (double baseDeg, double yf, bool hasDog) = crowdPositions[v];
      final double walkShift =
          math.sin(time * (0.55 + (v % 3) * 0.14) + v) * 1.4;
      final double? vx = _worldAngleToScreenX(
        baseDeg + walkShift,
        size,
        margin: 180,
      );
      if (vx == null) continue;
      if (yf > 0.47 && (vx - size.width * 0.5).abs() < 118.0) continue;

      final double vy = horizonY + groundHeight * yf;
      final double vScale = 1.42 + (yf - 0.30) * 2.10;
      _drawRealisticMarketVisitor(
        canvas,
        Offset(vx, vy),
        scale: vScale,
        coatColor: pufferColors[v % pufferColors.length],
        beanieColor: v % 3 == 0
            ? const Color(0xFFD32F2F)
            : (v.isEven ? const Color(0xFFCFD8DC) : const Color(0xFFF48FB1)),
        hasMug: v % 2 == 0,
        hasBackpack: v % 3 == 1,
        hasLittleBlackDog: hasDog,
        seed: v,
      );
    }
  }

  void _drawMarketPlazaPropsAndFurniture(
    Canvas canvas,
    Size size,
    double horizonY,
    double groundHeight,
  ) {
    // A. Illuminated Timber Market Avenue Arches ("WEIHNACHTSMARKT AM KÖLNER DOM")
    for (final (double archDeg, double yf) in const [
      (-24.0, 0.38),
      (24.0, 0.38),
      (128.0, 0.42),
      (252.0, 0.40),
    ]) {
      final double? ax = _worldAngleToScreenX(archDeg, size, margin: 240);
      if (ax == null) continue;
      final double ay = horizonY + groundHeight * yf;
      if ((ax - size.width * 0.5).abs() < 115.0) continue;
      _drawTimberMarketPortalArch(
        canvas,
        Offset(ax, ay),
        scale: 1.25 + (yf - 0.30) * 1.5,
      );
    }

    // B. Decorated Mini Nordmann Fir Trees in Rustic Wooden Barrels (Tannenbäumchen im Holzfass)
    final List<(double deg, double yf)> barrelTrees = const [
      (-29.0, 0.50),
      (-13.0, 0.40),
      (13.0, 0.40),
      (29.0, 0.50),
      (-38.0, 0.61),
      (38.0, 0.61),
      (50.0, 0.42),
      (94.0, 0.51),
      (112.0, 0.48),
      (140.0, 0.52),
      (167.0, 0.46),
      (195.0, 0.51),
      (228.0, 0.47),
      (276.0, 0.49),
      (304.0, 0.51),
    ];
    for (int t = 0; t < barrelTrees.length; t++) {
      final (double deg, double yf) = barrelTrees[t];
      final double? tx = _worldAngleToScreenX(deg, size, margin: 160);
      if (tx == null) continue;
      if (yf > 0.46 && (tx - size.width * 0.5).abs() < 120.0) continue;
      final double ty = horizonY + groundHeight * yf;
      _drawBarrelMiniFirTree(
        canvas,
        Offset(tx, ty),
        scale: 1.30 + (yf - 0.32) * 1.85,
        seed: t,
      );
    }

    // C. Standing Oak Glühwein Barrel Tables (Stehtische / Weinfässer) with Steaming Mugs & Lanterns
    final List<(double deg, double yf)> barrelTables = const [
      (-24.0, 0.61),
      (-12.0, 0.53),
      (12.0, 0.53),
      (24.0, 0.61),
      (-30.0, 0.48),
      (30.0, 0.48),
      (49.0, 0.54),
      (60.0, 0.60),
      (85.0, 0.60),
      (103.0, 0.50),
      (116.0, 0.58),
      (139.0, 0.57),
      (158.0, 0.51),
      (174.0, 0.52),
      (188.0, 0.56),
      (204.0, 0.52),
      (236.0, 0.58),
      (248.0, 0.50),
      (266.0, 0.58),
      (284.0, 0.52),
      (312.0, 0.56),
    ];
    for (int b = 0; b < barrelTables.length; b++) {
      final (double deg, double yf) = barrelTables[b];
      final double? bx = _worldAngleToScreenX(deg, size, margin: 160);
      if (bx == null) continue;
      if (yf > 0.46 && (bx - size.width * 0.5).abs() < 122.0) continue;
      final double by = horizonY + groundHeight * yf;
      _drawGluhweinBarrelTable(
        canvas,
        Offset(bx, by),
        scale: 1.35 + (yf - 0.34) * 1.95,
        seed: b,
      );
    }

    // D. Cast-Iron Steam-Locomotive Chestnut Braziers ("HEISSE-MARONEN-LOKOMOTIVE")
    for (final (double mDeg, double yf) in const [
      (-18.0, 0.63),
      (18.0, 0.63),
      (125.0, 0.58),
      (180.0, 0.58),
      (260.0, 0.58),
    ]) {
      final double? mx = _worldAngleToScreenX(mDeg, size, margin: 180);
      if (mx == null) continue;
      if ((mx - size.width * 0.5).abs() < 130.0) continue;
      final double my = horizonY + groundHeight * yf;
      _drawMaronenLocomotiveCart(
        canvas,
        Offset(mx, my),
        scale: 1.45 + (yf - 0.40) * 1.8,
      );
    }

    // E. Historic Cologne Cast-Iron Garland Streetlamps (Kölner Kandelaber)
    for (final (double lDeg, double yf) in const [
      (-28.0, 0.41),
      (-10.0, 0.36),
      (10.0, 0.36),
      (28.0, 0.41),
      (54.0, 0.44),
      (90.0, 0.44),
      (110.0, 0.42),
      (146.0, 0.42),
      (178.0, 0.42),
      (212.0, 0.42),
      (242.0, 0.44),
      (270.0, 0.44),
      (296.0, 0.42),
    ]) {
      final double? lx = _worldAngleToScreenX(lDeg, size, margin: 180);
      if (lx == null) continue;
      if (yf > 0.44 && (lx - size.width * 0.5).abs() < 120.0) continue;
      final double ly = horizonY + groundHeight * yf;
      _drawGarlandStreetlamp(
        canvas,
        Offset(lx, ly),
        scale: 1.32 + (yf - 0.32) * 1.75,
      );
    }
  }

  void _drawTimberMarketPortalArch(
    Canvas canvas,
    Offset base, {
    required double scale,
  }) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.scale(scale, scale);

    final Paint timberPaint = Paint()..color = const Color(0xFF3E2723);
    // Left & right timber posts
    canvas.drawRect(const Rect.fromLTWH(-28, -44, 4.2, 44), timberPaint);
    canvas.drawRect(const Rect.fromLTWH(23.8, -44, 4.2, 44), timberPaint);

    // Gabled timber arch beam & crimson mini-roof
    final Path archRoof = Path()
      ..moveTo(-32, -42)
      ..lineTo(0, -54)
      ..lineTo(32, -42)
      ..lineTo(28, -38)
      ..lineTo(0, -48)
      ..lineTo(-28, -38)
      ..close();
    canvas.drawPath(archRoof, Paint()..color = const Color(0xFFB71C1C));

    // Pine garland & fairy lights along the arch
    final Path garland = Path()
      ..moveTo(-30, -41)
      ..lineTo(0, -52)
      ..lineTo(30, -41);
    canvas.drawPath(
      garland,
      Paint()
        ..color = const Color(0xFF1B5E20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round,
    );
    for (int i = -3; i <= 3; i++) {
      canvas.drawCircle(
        Offset(i * 7.5, -42.0 - (3 - i.abs()) * 2.4),
        1.2,
        Paint()..color = const Color(0xFFFFF59D),
      );
    }
    _drawHerrnhuterStar(canvas, const Offset(0, -55), 3.8);
    canvas.restore();
  }

  void _drawBarrelMiniFirTree(
    Canvas canvas,
    Offset base, {
    required double scale,
    required int seed,
  }) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.scale(scale, scale);

    // Soft ground shadow
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 1.5), width: 16, height: 4.5),
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );

    // Wooden barrel tub with iron hoops
    final RRect tub = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(0, -4.5), width: 10.5, height: 9.0),
      const Radius.circular(1.8),
    );
    canvas.drawRRect(tub, Paint()..color = const Color(0xFF5D4037));
    canvas.drawLine(
      const Offset(-5.2, -6.5),
      const Offset(5.2, -6.5),
      Paint()
        ..color = const Color(0xFF263238)
        ..strokeWidth = 1.1,
    );
    canvas.drawLine(
      const Offset(-5.2, -2.5),
      const Offset(5.2, -2.5),
      Paint()
        ..color = const Color(0xFF263238)
        ..strokeWidth = 1.1,
    );

    // 3-tier lush mini Nordmann Fir tree
    for (int t = 0; t < 3; t++) {
      final double bottomY = -8.5 - t * 5.8;
      final double topY = bottomY - 9.0 + t * 1.0;
      final double hw = 8.5 - t * 2.1;
      final Path tier = Path()
        ..moveTo(0, topY)
        ..lineTo(-hw, bottomY)
        ..lineTo(hw, bottomY)
        ..close();
      canvas.drawPath(
        tier,
        Paint()
          ..color = t.isEven
              ? const Color(0xFF1B5E20)
              : const Color(0xFF2E7D32),
      );
    }

    // Fairy lights & red baubles on the mini tree
    for (int b = 0; b < 5; b++) {
      final double bx = (b % 2 == 0 ? -1.0 : 1.0) * (4.5 - b * 0.7);
      final double by = -10.5 - b * 3.4;
      canvas.drawCircle(
        Offset(bx, by),
        1.1,
        Paint()..color = const Color(0xFFFFF59D),
      );
      canvas.drawCircle(
        Offset(-bx * 0.8, by - 1.2),
        1.2,
        Paint()..color = const Color(0xFFD32F2F),
      );
    }
    _drawHerrnhuterStar(canvas, const Offset(0, -29.0), 2.4);
    canvas.restore();
  }

  void _drawGluhweinBarrelTable(
    Canvas canvas,
    Offset base, {
    required double scale,
    required int seed,
  }) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.scale(scale, scale);

    // Warm lantern floor glow & shadow under the oak barrel
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 1.5), width: 22, height: 6.0),
      Paint()..color = const Color(0xFFFFCA28).withValues(alpha: 0.24),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 1.0), width: 13, height: 4.0),
      Paint()..color = Colors.black.withValues(alpha: 0.42),
    );

    // Oak wine barrel body (Weinfass-Stehtisch)
    final RRect barrel = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(0, -7.5), width: 11.5, height: 15.0),
      const Radius.circular(3.5),
    );
    canvas.drawRRect(
      barrel,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(-6, -7.5),
          const Offset(6, -7.5),
          const [Color(0xFF4E342E), Color(0xFF795548), Color(0xFF3E2723)],
          const [0.0, 0.45, 1.0],
        ),
    );
    // Forged iron barrel hoops
    for (final double hy in [-12.0, -7.5, -3.0]) {
      canvas.drawLine(
        Offset(-5.6, hy),
        Offset(5.6, hy),
        Paint()
          ..color = const Color(0xFF212121)
          ..strokeWidth = 1.2,
      );
    }
    // Round wooden table top platter
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -15.2), width: 15.5, height: 3.8),
      Paint()..color = const Color(0xFF8D6E63),
    );

    // Red ceramic Dom-Glühwein mugs & warm candle lantern on top of barrel
    canvas.drawRect(
      const Rect.fromLTWH(-4.8, -18.2, 2.5, 3.0),
      Paint()..color = const Color(0xFFC62828),
    );
    canvas.drawRect(
      const Rect.fromLTWH(2.4, -18.0, 2.5, 3.0),
      Paint()..color = const Color(0xFFC62828),
    );
    canvas.drawCircle(
      const Offset(0, -17.5),
      1.8,
      Paint()..color = const Color(0xFFFFF59D),
    );

    // Rising white Glühwein steam wisps
    final double steamShift = math.sin(time * 3.0 + seed) * 1.2;
    canvas.drawCircle(
      Offset(-3.5 + steamShift, -20.5 - ((time * 2.0 + seed) % 1.0) * 4.0),
      1.3,
      Paint()..color = Colors.white.withValues(alpha: 0.32),
    );
    canvas.restore();
  }

  void _drawMaronenLocomotiveCart(
    Canvas canvas,
    Offset base, {
    required double scale,
  }) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.scale(scale, scale);

    // Warm glowing coal reflection on the pavement
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 2.0), width: 32, height: 8.0),
      Paint()..color = const Color(0xFFFF6D00).withValues(alpha: 0.32),
    );

    // Cast-iron steam-locomotive body ("HEISSE MARONEN")
    final Paint ironPaint = Paint()..color = const Color(0xFF212121);
    final Paint brassPaint = Paint()..color = const Color(0xFFFFB300);

    // Boiler cylinder & cab
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-12, -15, 18, 9.5),
        const Radius.circular(2.5),
      ),
      ironPaint,
    );
    canvas.drawRect(const Rect.fromLTWH(4, -20, 8, 14.5), ironPaint);
    // Smokestack chimney on front left
    canvas.drawRect(const Rect.fromLTWH(-10, -22, 3.5, 7.5), ironPaint);
    canvas.drawLine(
      const Offset(-11, -22),
      const Offset(-5.5, -22),
      brassPaint..strokeWidth = 1.5,
    );

    // Glowing orange-red chestnut roasting firebox slot
    canvas.drawRect(
      const Rect.fromLTWH(-8, -11.5, 10, 3.2),
      Paint()..color = const Color(0xFFFF5722),
    );
    // Brass trim bands & spoked iron wheels
    canvas.drawLine(
      const Offset(-4, -15),
      const Offset(-4, -5.5),
      brassPaint..strokeWidth = 1.2,
    );
    for (final double wx in [-7.5, 1.5, 8.5]) {
      canvas.drawCircle(Offset(wx, -3.5), 3.5, ironPaint);
      canvas.drawCircle(
        Offset(wx, -3.5),
        3.5,
        Paint()
          ..color = const Color(0xFFFFB300)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }

    // Puffing white steam from the chestnut locomotive chimney
    for (int p = 0; p < 3; p++) {
      final double prog = (time * 0.85 + p * 0.33) % 1.0;
      canvas.drawCircle(
        Offset(
          -8.2 + math.sin(time * 2.5 + p) * 2.5,
          -24.0 - prog * 14.0,
        ),
        1.8 + prog * 2.8,
        Paint()..color = Colors.white.withValues(alpha: (1.0 - prog) * 0.34),
      );
    }
    canvas.restore();
  }

  void _drawGarlandStreetlamp(
    Canvas canvas,
    Offset base, {
    required double scale,
  }) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.scale(scale, scale);

    // Cast-iron pole
    canvas.drawLine(
      Offset.zero,
      const Offset(0, -38),
      Paint()
        ..color = const Color(0xFF1C242B)
        ..strokeWidth = 2.2,
    );
    // Spiral pine garland wrapped around the lamppost
    for (int g = 0; g < 6; g++) {
      final double gy = -5.0 - g * 5.0;
      canvas.drawLine(
        Offset(-2.0, gy),
        Offset(2.0, gy - 2.5),
        Paint()
          ..color = const Color(0xFF1B5E20)
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        Offset(g.isEven ? -1.5 : 1.5, gy - 1.2),
        0.9,
        Paint()..color = const Color(0xFFFFF59D),
      );
    }
    // Ornate cross-arm & twin glowing globes
    canvas.drawLine(
      const Offset(-8.5, -35),
      const Offset(8.5, -35),
      Paint()
        ..color = const Color(0xFF1C242B)
        ..strokeWidth = 1.6,
    );
    for (final double gx in [-8.5, 8.5]) {
      canvas.drawCircle(
        Offset(gx, -37.0),
        6.5,
        Paint()..color = const Color(0xFFFFE082).withValues(alpha: 0.32),
      );
      canvas.drawCircle(
        Offset(gx, -37.0),
        2.6,
        Paint()..color = const Color(0xFFFFF9C4),
      );
    }
    _drawHerrnhuterStar(canvas, const Offset(0, -40.5), 2.8);
    canvas.restore();
  }

  void _drawPhotoAccurateCologneStall(
    Canvas canvas,
    Offset base, {
    required String label,
    required String stallNumber,
    required int type,
    required double scale,
    required int seed,
  }) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.scale(scale, scale);
    canvas.translate(-base.dx, -base.dy);

    const double w = 66.0;
    const double h = 38.0;

    // 1. Soft radial warm amber light reflection & contact shadow on the granite tiles
    canvas.save();
    canvas.translate(base.dx, base.dy + 2.0);
    canvas.scale(2.3, 0.34);
    canvas.drawCircle(
      Offset.zero,
      26.0,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset.zero,
          26.0,
          [
            const Color(0xFFFFD54F).withValues(alpha: 0.34),
            const Color(0xFFFF8F00).withValues(alpha: 0.14),
            Colors.transparent,
          ],
          const [0.0, 0.55, 1.0],
        ),
    );
    canvas.drawCircle(
      const Offset(0, -3.0),
      16.5,
      Paint()
        ..shader = ui.Gradient.radial(
          const Offset(0, -3.0),
          16.5,
          [
            Colors.black.withValues(alpha: 0.48),
            Colors.black.withValues(alpha: 0.18),
            Colors.transparent,
          ],
          const [0.0, 0.65, 1.0],
        ),
    );
    canvas.restore();

    // Select distinct photographic stall sprite based on stall product type (0..4)!
    ui.Image? stallImg;
    switch (type % 5) {
      case 0:
        stallImg = CologneChristmasAssets.stall; // Glühwein & Lebkuchen-Herzen
      case 1:
        stallImg =
            CologneChristmasAssets.stallGrill ??
            CologneChristmasAssets.stall; // Schwenkgrill & Bratwurst
      case 2:
        stallImg =
            CologneChristmasAssets.stallSweets ??
            CologneChristmasAssets.stall; // Gebrannte Mandeln & Waffeln
      case 3:
        stallImg =
            CologneChristmasAssets.stallCrafts ??
            CologneChristmasAssets.stall; // Holzkunst, Sterne & Nussknacker
      case 4:
        stallImg = seed.isEven
            ? (CologneChristmasAssets.stallCrafts ??
                  CologneChristmasAssets.stall)
            : (CologneChristmasAssets.stallSweets ??
                  CologneChristmasAssets.stall);
    }

    if (stallImg != null) {
      // 2. Render the Photorealistic Cologne Market Stall Cutout
      final Rect srcRect = Rect.fromLTWH(
        0,
        0,
        stallImg.width.toDouble(),
        stallImg.height.toDouble(),
      );
      final Rect dstRect = Rect.fromCenter(
        center: Offset(base.dx, base.dy - 30.5),
        width: 82.0,
        height: 66.0,
      );
      canvas.drawImageRect(
        stallImg,
        srcRect,
        dstRect,
        Paint()..filterQuality = FilterQuality.medium,
      );

      // 3. Product-Specific Animated Details & Live Twinkling Garland Micro-LEDs!
      final double pulse = 0.65 + 0.35 * math.sin(time * 4.2 + seed * 1.3);
      canvas.drawCircle(
        Offset(base.dx, base.dy - 57.0),
        6.5 * pulse,
        Paint()..color = const Color(0xFFFFF59D).withValues(alpha: 0.30 * pulse),
      );
      for (int l = -3; l <= 3; l++) {
        final double bulbPulse =
            0.55 + 0.45 * math.sin(time * 4.8 + seed + l * 1.4);
        canvas.drawCircle(
          Offset(base.dx + l * 8.0, base.dy - 34.5),
          1.15 * bulbPulse,
          Paint()
            ..color =
                const Color(0xFFFFF59D).withValues(alpha: 0.78 * bulbPulse),
        );
      }

      if (type == 1) {
        // Sizzling Schwenkgrill smoke wisps & orange charcoal fire glow
        for (int s = 0; s < 2; s++) {
          final double prog = (time * 0.7 + s * 0.5 + seed * 0.2) % 1.0;
          canvas.drawCircle(
            Offset(
              base.dx + math.sin(time * 2.2 + s + seed) * 3.0,
              base.dy - 20.0 - prog * 14.0,
            ),
            1.8 + prog * 2.5,
            Paint()
              ..color = Colors.white.withValues(alpha: (1.0 - prog) * 0.20),
          );
        }
      } else if (type == 4) {
        // Specialty Pyramid- & Star-Crowned Stall: add extra hanging 3D Moravian stars & spinning mini roof rotor!
        _drawHerrnhuterStar(canvas, Offset(base.dx - 26.0, base.dy - 32.0), 3.2);
        _drawHerrnhuterStar(canvas, Offset(base.dx + 26.0, base.dy - 32.0), 3.2);
        final Offset miniRotor = Offset(base.dx, base.dy - 63.0);
        for (int r = 0; r < 6; r++) {
          final double ang = time * 3.6 + r * (math.pi / 3.0);
          canvas.drawLine(
            miniRotor,
            Offset(
              miniRotor.dx + math.cos(ang) * 11.0,
              miniRotor.dy + math.sin(ang) * 2.6,
            ),
            Paint()
              ..color = const Color(0xFFFFE082)
              ..strokeWidth = 1.5
              ..strokeCap = StrokeCap.round,
          );
        }
      }

      canvas.restore();
      return;
    }

    // Procedural fallback when assets are not decoded (e.g., headless unit tests)
    final RRect cabinRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(base.dx, base.dy - h * 0.5),
        width: w,
        height: h,
      ),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(cabinRect, Paint()..color = const Color(0xFF422A20));

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(base.dx, base.dy - 7.5),
        width: w - 10,
        height: 11.5,
      ),
      Paint()..color = const Color(0xFFEFEBE4),
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(base.dx, base.dy - 7.5),
        width: w - 14,
        height: 8.5,
      ),
      Paint()
        ..color = const Color(0xFF422A20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );

    final Rect counterWindow = Rect.fromCenter(
      center: Offset(base.dx, base.dy - h * 0.60),
      width: w - 10,
      height: 17,
    );
    canvas.drawRect(
      counterWindow,
      Paint()
        ..shader = ui.Gradient.linear(
          counterWindow.topCenter,
          counterWindow.bottomCenter,
          const [Color(0xFFFFF59D), Color(0xFFFFB74D)],
        ),
    );

    canvas.drawRect(
      Rect.fromLTWH(
        counterWindow.right - 14,
        counterWindow.top + 2,
        12,
        11,
      ),
      Paint()..color = const Color(0xFF2E3532),
    );
    for (int line = 0; line < 3; line++) {
      canvas.drawLine(
        Offset(counterWindow.right - 12, counterWindow.top + 4.5 + line * 2.8),
        Offset(counterWindow.right - 4, counterWindow.top + 4.5 + line * 2.8),
        Paint()
          ..color = const Color(0xFFFFE082).withValues(alpha: 0.75)
          ..strokeWidth = 0.8,
      );
    }

    final double nod = math.sin(time * 2.6 + seed) * 1.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(base.dx - 5, base.dy - h * 0.48),
          width: 10,
          height: 9,
        ),
        const Radius.circular(2.5),
      ),
      Paint()..color = const Color(0xFFD32F2F),
    );
    canvas.drawCircle(
      Offset(base.dx - 5, base.dy - h * 0.64 + nod),
      3.4,
      Paint()..color = const Color(0xFFFFCCBC),
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(base.dx - 5, base.dy - h * 0.68 + nod),
        width: 7,
        height: 5,
      ),
      math.pi,
      math.pi,
      true,
      Paint()..color = const Color(0xFFB71C1C),
    );

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(base.dx, base.dy - 14.0),
        width: w - 4,
        height: 2.8,
      ),
      Paint()..color = const Color(0xFFF5F0E6),
    );

    final Offset starBadgePos = Offset(base.dx - w * 0.42, base.dy - h + 7.5);
    canvas.drawCircle(
      starBadgePos,
      4.2,
      Paint()..color = const Color(0xFFE6B84C),
    );
    final TextPainter numTp = TextPainter(
      text: TextSpan(
        text: stallNumber,
        style: const TextStyle(
          color: Color(0xFF2D1E18),
          fontSize: 3.6,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    numTp.paint(
      canvas,
      Offset(
        starBadgePos.dx - numTp.width * 0.5,
        starBadgePos.dy - numTp.height * 0.5,
      ),
    );

    final Path redRoof = Path()
      ..moveTo(base.dx - w * 0.60, base.dy - h + 2)
      ..lineTo(base.dx, base.dy - h - 19)
      ..lineTo(base.dx + w * 0.60, base.dy - h + 2)
      ..close();
    canvas.drawPath(
      redRoof,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(base.dx, base.dy - h - 19),
          Offset(base.dx, base.dy - h + 2),
          const [
            Color(0xFFFF1744),
            Color(0xFFD50000),
            Color(0xFF9B0000),
          ],
          const [0.0, 0.55, 1.0],
        ),
    );
    canvas.drawLine(
      Offset(base.dx, base.dy - h - 19),
      Offset(base.dx - w * 0.25, base.dy - h + 2),
      Paint()
        ..color = const Color(0xFF7F0000).withValues(alpha: 0.45)
        ..strokeWidth = 1.0,
    );
    canvas.drawLine(
      Offset(base.dx, base.dy - h - 19),
      Offset(base.dx + w * 0.25, base.dy - h + 2),
      Paint()
        ..color = const Color(0xFFFF8A80).withValues(alpha: 0.35)
        ..strokeWidth = 1.0,
    );

    final Path garlandPath = Path()
      ..moveTo(base.dx - w * 0.60, base.dy - h + 2.5)
      ..lineTo(base.dx, base.dy - h - 18.0)
      ..lineTo(base.dx + w * 0.60, base.dy - h + 2.5);
    canvas.drawPath(
      garlandPath,
      Paint()
        ..color = const Color(0xFF1E4620)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawLine(
      Offset(base.dx - w * 0.58, base.dy - h + 2.5),
      Offset(base.dx + w * 0.58, base.dy - h + 2.5),
      Paint()
        ..color = const Color(0xFF1E4620)
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.round,
    );

    for (int l = -4; l <= 4; l++) {
      canvas.drawCircle(
        Offset(base.dx + l * 7.5, base.dy - h + 2.5),
        1.25,
        Paint()..color = const Color(0xFFFFF59D),
      );
    }

    _drawHerrnhuterStar(canvas, Offset(base.dx, base.dy - h - 20.5), 4.8);
    _drawHerrnhuterStar(
      canvas,
      Offset(base.dx - w * 0.58, base.dy - h + 1.0),
      3.2,
    );
    _drawHerrnhuterStar(
      canvas,
      Offset(base.dx + w * 0.58, base.dy - h + 1.0),
      3.2,
    );

    final Rect signRect = Rect.fromCenter(
      center: Offset(base.dx, base.dy - h - 4.5),
      width: w * 0.82,
      height: 7.5,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(signRect, const Radius.circular(2)),
      Paint()..color = const Color(0xFFE6B84C),
    );
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Color(0xFF2D1E18),
          fontSize: 4.3,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(base.dx - tp.width * 0.5, base.dy - h - 4.5 - tp.height * 0.5),
    );
    canvas.restore();
  }

  void _drawHerrnhuterStar(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center,
      radius * 1.7,
      Paint()..color = const Color(0xFFFFB300).withValues(alpha: 0.36),
    );
    final Path star = Path();
    for (int i = 0; i < 16; i++) {
      final double ang = (i * math.pi / 8.0) - math.pi * 0.5;
      final double r = i.isEven ? radius : radius * 0.38;
      final double sx = center.dx + math.cos(ang) * r;
      final double sy = center.dy + math.sin(ang) * r;
      if (i == 0) {
        star.moveTo(sx, sy);
      } else {
        star.lineTo(sx, sy);
      }
    }
    star.close();
    canvas.drawPath(star, Paint()..color = const Color(0xFFFFCA28));
    canvas.drawCircle(
      center,
      radius * 0.32,
      Paint()..color = const Color(0xFFFFF9C4),
    );
  }

  void _drawRealisticMarketVisitor(
    Canvas canvas,
    Offset pos, {
    required double scale,
    required Color coatColor,
    required Color beanieColor,
    bool hasMug = false,
    bool hasBackpack = false,
    bool hasLittleBlackDog = false,
    required int seed,
  }) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.scale(scale, scale);
    canvas.translate(-pos.dx, -pos.dy);

    final double bob = math.sin(time * 2.8 + seed) * 0.8;
    // Ground shadow
    canvas.drawOval(
      Rect.fromCenter(center: pos, width: 11, height: 3.8),
      Paint()..color = Colors.black.withValues(alpha: 0.30),
    );
    // Dark denim/winter trousers & boots
    final Paint legPaint = Paint()
      ..color = const Color(0xFF1F2933)
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(pos.dx - 2.2, pos.dy - 7),
      Offset(pos.dx - 2.2, pos.dy),
      legPaint,
    );
    canvas.drawLine(
      Offset(pos.dx + 2.2, pos.dy - 7),
      Offset(pos.dx + 2.2, pos.dy),
      legPaint,
    );

    // Quilted winter puffer jacket (like the visitors in Photo 2!)
    final RRect jacketRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(pos.dx, pos.dy - 12 + bob),
        width: 9.5,
        height: 12.0,
      ),
      const Radius.circular(3.2),
    );
    canvas.drawRRect(jacketRect, Paint()..color = coatColor);
    // Quilted puffer horizontal seams
    for (int q = -1; q <= 1; q++) {
      canvas.drawLine(
        Offset(pos.dx - 4.2, pos.dy - 12 + bob + q * 3.0),
        Offset(pos.dx + 4.2, pos.dy - 12 + bob + q * 3.0),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.22)
          ..strokeWidth = 0.7,
      );
    }

    if (hasBackpack) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(pos.dx, pos.dy - 12 + bob),
            width: 6.5,
            height: 7.5,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFF37474F),
      );
    }

    // Head & knitted winter beanie
    canvas.drawCircle(
      Offset(pos.dx, pos.dy - 20 + bob),
      3.0,
      Paint()..color = const Color(0xFFFFCCBC),
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(pos.dx, pos.dy - 21 + bob),
        width: 6.6,
        height: 5.2,
      ),
      math.pi,
      math.pi,
      true,
      Paint()..color = beanieColor,
    );

    if (hasMug) {
      canvas.drawRect(
        Rect.fromLTWH(pos.dx + 4.8, pos.dy - 13.5 + bob, 3.0, 3.8),
        Paint()..color = const Color(0xFFC62828),
      );
    }

    // Cute Little Black Dog walking beside its owner on the stone pavement (Exact detail from Photo 2!)
    if (hasLittleBlackDog) {
      final Offset dogPos = Offset(pos.dx - 11.0, pos.dy + 1.0);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(dogPos.dx, dogPos.dy - 3.0),
          width: 6.5,
          height: 4.2,
        ),
        Paint()..color = const Color(0xFF1A1A1A),
      );
      canvas.drawCircle(
        Offset(dogPos.dx + 2.8, dogPos.dy - 5.5),
        2.4,
        Paint()..color = const Color(0xFF1A1A1A),
      );
      canvas.drawLine(
        Offset(dogPos.dx - 2.0, dogPos.dy - 2),
        Offset(dogPos.dx - 2.0, dogPos.dy),
        Paint()
          ..color = const Color(0xFF1A1A1A)
          ..strokeWidth = 1.3,
      );
      canvas.drawLine(
        Offset(dogPos.dx + 2.0, dogPos.dy - 2),
        Offset(dogPos.dx + 2.0, dogPos.dy),
        Paint()
          ..color = const Color(0xFF1A1A1A)
          ..strokeWidth = 1.3,
      );
      // Leash line
      canvas.drawLine(
        Offset(pos.dx - 4.0, pos.dy - 10 + bob),
        Offset(dogPos.dx + 2.0, dogPos.dy - 5.0),
        Paint()
          ..color = const Color(0xFF5D4037)
          ..strokeWidth = 0.8,
      );
    }

    canvas.restore();
  }

  // ===========================================================================
  // 9. OVERHEAD "STERNENZELT" (70,000-LED STARRY LIGHT TENT WEB, PHOTOS 1, 2 & 3!)
  // ===========================================================================
  void _drawSternenzeltCanopyWeb(
    Canvas canvas,
    Size size,
    double horizonY,
    double groundHeight,
  ) {
    final bool isPhotoreal = CologneChristmasAssets.treePavilion != null;
    final double treeCenterX = size.width * 0.5;
    final double treeCrownY = isPhotoreal
        ? size.height * 0.885 - 204.0 * 1.32
        : size.height * 0.855 - 156.0 * 1.15;

    // 1. 6-Pointed Glowing Star-Ray Wings of the Roncalliplatz Sternenzelt (Photos 1 & 3!)
    //    Plus the dense overhead radial cables & concentric horizontal light wires (Photo 2!)
    final List<double> mastAngles = [
      -42.0,
      -26.0,
      -12.0,
      12.0,
      26.0,
      42.0,
      68.0,
      104.0,
      132.0,
      158.0,
      195.0,
      235.0,
      278.0,
      318.0,
    ];

    final List<Offset> visibleMastTops = [];

    for (int m = 0; m < mastAngles.length; m++) {
      final double mastDeg = mastAngles[m];
      final double? mastX = _worldAngleToScreenX(mastDeg, size, margin: 520);
      if (mastX == null) continue;
      final double mastBaseY = horizonY + groundHeight * 0.38;
      final double mastTopY = isPhotoreal
          ? treeCrownY + 26.0 + (m % 3) * 8.0
          : mastBaseY - 112.0;
      visibleMastTops.add(Offset(mastX, mastTopY));

      // Steel/Timber Sternenzelt perimeter mast pole anchored in the market plaza
      canvas.drawLine(
        Offset(mastX, mastBaseY),
        Offset(mastX, mastTopY),
        Paint()
          ..color = const Color(0xFF2D241E)
          ..strokeWidth = 2.0,
      );
      _drawHerrnhuterStar(canvas, Offset(mastX, mastTopY), 3.4);

      // Radial cable from the Center Tree's Sternenzelt Ring out to this mast
      final Offset p0 = Offset(treeCenterX, treeCrownY);
      final Offset p2 = Offset(mastX, mastTopY);
      final Offset p1 = Offset(
        (p0.dx + p2.dx) * 0.5,
        math.max(p0.dy, p2.dy) + 14.0,
      );

      final Path radialCable = Path()
        ..moveTo(p0.dx, p0.dy)
        ..quadraticBezierTo(p1.dx, p1.dy, p2.dx, p2.dy);
      canvas.drawPath(
        radialCable,
        Paint()
          ..color = const Color(0xFFFFE082).withValues(alpha: 0.50)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.15,
      );

      // Dense warm golden micro-LEDs along each radial cable
      for (int b = 1; b <= 14; b++) {
        final double t = b / 15.0;
        final double bx =
            (1 - t) * (1 - t) * p0.dx +
            2 * (1 - t) * t * p1.dx +
            t * t * p2.dx;
        final double by =
            (1 - t) * (1 - t) * p0.dy +
            2 * (1 - t) * t * p1.dy +
            t * t * p2.dy;
        final double pulse =
            0.65 + 0.35 * math.sin(time * 4.2 + m * 0.7 + b * 1.1);
        canvas.drawCircle(
          Offset(bx, by),
          1.8 * pulse,
          Paint()
            ..color = const Color(
              0xFFFFF59D,
            ).withValues(alpha: 0.85 * pulse),
        );
      }
    }

    // 2. Concentric Horizontal Light Strands Webbing Between Adjacent Radial Cables (Exact look of Photo 2 overhead!)
    for (int i = 0; i < visibleMastTops.length - 1; i++) {
      final Offset mA = visibleMastTops[i];
      final Offset mB = visibleMastTops[i + 1];
      if ((mA.dx - mB.dx).abs() > size.width * 0.55) continue;

      final Offset p0 = Offset(treeCenterX, treeCrownY);
      for (int ring = 1; ring <= 6; ring++) {
        final double rFrac = ring / 7.0;
        final Offset aPt = Offset.lerp(p0, mA, rFrac)!;
        final Offset bPt = Offset.lerp(p0, mB, rFrac)!;
        final Path webLine = Path()
          ..moveTo(aPt.dx, aPt.dy)
          ..quadraticBezierTo(
            (aPt.dx + bPt.dx) * 0.5,
            (aPt.dy + bPt.dy) * 0.5 + 4.5,
            bPt.dx,
            bPt.dy,
          );
        canvas.drawPath(
          webLine,
          Paint()
            ..color = const Color(0xFFFFD54F).withValues(alpha: 0.34)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.85,
        );
        // Tiny warm LEDs along the concentric web rung
        for (int k = 1; k <= 5; k++) {
          final double kt = k / 6.0;
          final Offset ledPt = Offset.lerp(aPt, bPt, kt)!;
          canvas.drawCircle(
            Offset(ledPt.dx, ledPt.dy + 2.0),
            1.2,
            Paint()..color = const Color(0xFFFFF59D).withValues(alpha: 0.78),
          );
        }
      }
    }
  }

  // ===========================================================================
  // 10. CENTER OBJECT — THE GRAND 25M RONCALLIPLATZ CHRISTMAS TREE &
  //     OCTAGONAL RED-ROOFED TREE PAVILION BASE (EXACT MATCH TO PHOTOS 1, 2 & 3!)
  // ===========================================================================
  void _drawCenterChristmasTreeAndPavilion(
    Canvas canvas,
    Size size,
    double horizonY,
    double groundHeight,
  ) {
    final ui.Image? treeImg = CologneChristmasAssets.treePavilion;
    if (treeImg != null) {
      _drawPhotorealisticCenterTreeAndPavilion(canvas, size, treeImg);
      return;
    }

    final double cx = size.width * 0.5;
    final double cy = size.height * 0.865;
    final double pulseScale = 1.15 * (1.0 + coconutPulse * 0.06);
    final double sway = math.sin(time * 1.5) * 0.010;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(pulseScale, pulseScale);

    // 1. Warm Golden-Amber Light Aura Cast by the Tree & Pavilion onto the Granite Plaza
    canvas.save();
    canvas.scale(2.4, 0.44);
    canvas.drawCircle(
      const Offset(0, 6),
      84.0,
      Paint()
        ..shader = ui.Gradient.radial(
          const Offset(0, 6),
          84.0,
          [
            const Color(0xFFFFD54F).withValues(alpha: 0.45),
            const Color(0xFFFF8F00).withValues(alpha: 0.18),
            Colors.transparent,
          ],
          const [0.0, 0.55, 1.0],
        ),
    );
    canvas.restore();

    // 2. UPPER & MIDDLE NORDMANN FIR TREE CROWN (Rising out of the center of the Octagonal Pavilion, y = -28 up to -168!)
    canvas.save();
    canvas.rotate(sway);

    // Warm golden glow halo enveloping the entire Christmas Tree (Photos 1 & 3!)
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -96), width: 128, height: 156),
      Paint()
        ..shader = ui.Gradient.radial(
          const Offset(0, -96),
          82.0,
          [
            const Color(0xFFFFE082).withValues(alpha: 0.34),
            const Color(0xFFFFB300).withValues(alpha: 0.12),
            Colors.transparent,
          ],
          const [0.0, 0.58, 1.0],
        ),
    );

    // 9 Dense, Feathered Natural Nordmann Fir Tiers with Hundreds of Warm Golden Micro-LEDs & Red/Gold Ornaments
    for (int tier = 0; tier < 9; tier++) {
      final double t = tier / 8.0;
      final double tierBottomY = -28.0 - tier * 15.2;
      final double tierTopY = tierBottomY - 28.0 + tier * 1.2;
      final double halfWidth = 64.0 * (1.0 - t * 0.78);

      // Deep interior pine shadow
      final Path shadowCone = Path()
        ..moveTo(0, tierTopY + 2)
        ..lineTo(-halfWidth * 0.94, tierBottomY + 1)
        ..lineTo(halfWidth * 0.94, tierBottomY + 1)
        ..close();
      canvas.drawPath(shadowCone, Paint()..color = const Color(0xFF0E2914));

      // Feathered Nordmann Fir branch boughs (Photo 2 natural evergreen silhouette!)
      final Path bough = Path()..moveTo(0, tierTopY);
      bough.quadraticBezierTo(
        -halfWidth * 0.52,
        (tierTopY + tierBottomY) * 0.5,
        -halfWidth,
        tierBottomY - 2,
      );
      for (int s = 0; s < 7; s++) {
        final double sx1 = -halfWidth + (s / 7.0) * (halfWidth * 2.0);
        final double sx2 = -halfWidth + ((s + 1) / 7.0) * (halfWidth * 2.0);
        final double midX = (sx1 + sx2) * 0.5;
        bough.quadraticBezierTo(
          midX,
          tierBottomY + 5.5,
          sx2,
          tierBottomY - 1.8,
        );
      }
      bough.quadraticBezierTo(
        halfWidth * 0.52,
        (tierTopY + tierBottomY) * 0.5,
        0,
        tierTopY,
      );
      bough.close();

      canvas.drawPath(
        bough,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(-halfWidth, tierBottomY),
            Offset(halfWidth, tierBottomY),
            const [
              Color(0xFF14381C),
              Color(0xFF21572A),
              Color(0xFF2E6F36),
              Color(0xFF1F4F26),
              Color(0xFF113018),
            ],
            const [0.0, 0.28, 0.52, 0.76, 1.0],
          ),
      );

      // Dense carpet of warm golden fairy lights across every branch tier (Photos 1 & 3!)
      final int bulbCount = 11 - tier;
      for (int b = 0; b < bulbCount; b++) {
        final double bt = (b + 0.5) / bulbCount;
        final double bx = (bt - 0.5) * 2.0 * (halfWidth * 0.86);
        final double by =
            tierBottomY -
            5.0 -
            (b % 3) * 4.2 +
            math.sin(bt * math.pi) * 3.5;
        final double glowPulse =
            0.68 + 0.32 * math.sin(time * 4.5 + tier * 1.1 + b * 1.7);

        final Color lightColor = styleMode == CoconutStyleMode.cocktail
            ? [
                const Color(0xFFFF4081),
                const Color(0xFF00E5FF),
                const Color(0xFFFFEE58),
                const Color(0xFF69F0AE),
              ][(tier + b) % 4]
            : const Color(0xFFFFF59D);

        canvas.drawCircle(
          Offset(bx, by),
          4.0 * glowPulse,
          Paint()..color = lightColor.withValues(alpha: 0.42),
        );
        canvas.drawCircle(
          Offset(bx, by),
          1.6,
          Paint()..color = lightColor,
        );

        // Red and Gold Ornaments on the branches (visible in Photo 2!)
        if ((b + tier) % 2 == 0) {
          final Offset baublePos = Offset(bx + 2.5, by + 3.5);
          if (styleMode == CoconutStyleMode.cocktail) {
            _drawLebkuchenHeartOrnament(canvas, baublePos);
          } else if (styleMode == CoconutStyleMode.king) {
            _drawRoyalVelvetBow(canvas, baublePos);
          } else {
            final Color bc = (tier + b) % 3 == 0
                ? const Color(0xFFFFB300)
                : const Color(0xFFD32F2F);
            canvas.drawCircle(baublePos, 3.2, Paint()..color = bc);
            canvas.drawCircle(
              Offset(baublePos.dx - 1.0, baublePos.dy - 1.0),
              1.0,
              Paint()..color = Colors.white.withValues(alpha: 0.80),
            );
          }
        }
      }
    }

    // Steel Sternenzelt Anchor Ring near the upper tree crown (Photo 2!)
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -148), width: 30, height: 6.5),
      Paint()
        ..color = const Color(0xFFFFD54F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // Style-Specific Tree Topper & Accessories (Topper at y = -168)
    _drawStyleSpecificTreeFeatures(canvas);

    canvas.restore(); // end tree crown sway

    // 3. THE AUTHENTIC OCTAGONAL RED-ROOFED TREE PAVILION BASE (`Baum-Pavillon / Rondell` from Photo 2 & Stage from Photos 1 & 3!)
    //    Encircles the base of our Christmas Tree (y = -34 down to +14), grounding it 100% into the Roncalliplatz market!
    _drawTreeBaseOctagonalPavilion(canvas);

    canvas.restore();
  }

  void _drawTreeBaseOctagonalPavilion(Canvas canvas) {
    // Octagonal wooden pavilion walls (3 visible facets: Left-Angled, Center-Front, Right-Angled — exact match to Photo 2!)
    const double baseBottomY = 12.0;
    const double counterY = -8.0;
    const double eavesY = -28.0;

    final Paint darkTimberPaint = Paint()..color = const Color(0xFF3E2723);
    final Paint creamPanelPaint = Paint()..color = const Color(0xFFEFEBE4);

    // Left Facet (-54 to -22)
    final Path leftWall = Path()
      ..moveTo(-54, baseBottomY - 6)
      ..lineTo(-22, baseBottomY)
      ..lineTo(-22, eavesY)
      ..lineTo(-54, eavesY - 4)
      ..close();
    canvas.drawPath(leftWall, darkTimberPaint);

    // Center Front Facet (-22 to +22)
    final Rect centerWall = Rect.fromLTRB(-22, eavesY, 22, baseBottomY);
    canvas.drawRect(centerWall, darkTimberPaint);

    // Right Facet (+22 to +54)
    final Path rightWall = Path()
      ..moveTo(22, baseBottomY)
      ..lineTo(54, baseBottomY - 6)
      ..lineTo(54, eavesY - 4)
      ..lineTo(22, eavesY)
      ..close();
    canvas.drawPath(rightWall, darkTimberPaint);

    // Cream-white lower wainscoting panels on all 3 visible facets (Photo 2!)
    for (final Rect panel in const [
      Rect.fromLTRB(-49, counterY + 2, -25, baseBottomY - 4),
      Rect.fromLTRB(-19, counterY + 3, 19, baseBottomY - 2),
      Rect.fromLTRB(25, counterY + 2, 49, baseBottomY - 4),
    ]) {
      canvas.drawRect(panel, creamPanelPaint);
      canvas.drawRect(
        panel.deflate(2.0),
        Paint()
          ..color = const Color(0xFF4E342E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }

    // Warm Illuminated Display Windows on Left, Center & Right Facets (Photo 2!)
    for (final Rect win in const [
      Rect.fromLTRB(-48, eavesY + 4, -25, counterY - 1),
      Rect.fromLTRB(-18, eavesY + 4, 18, counterY - 1),
      Rect.fromLTRB(25, eavesY + 4, 48, counterY - 1),
    ]) {
      canvas.drawRect(
        win,
        Paint()
          ..shader = ui.Gradient.linear(
            win.topCenter,
            win.bottomCenter,
            const [Color(0xFFFFF9C4), Color(0xFFFFCA28)],
          ),
      );
      // Red velvet & jewelry/ornament display shelves inside the windows (Photo 2!)
      canvas.drawRect(
        Rect.fromLTRB(win.left + 2, win.bottom - 5, win.right - 2, win.bottom),
        Paint()..color = const Color(0xFFB71C1C),
      );
      for (double dx = win.left + 5; dx < win.right - 4; dx += 6.5) {
        canvas.drawCircle(
          Offset(dx, win.center.dy - 1),
          1.8,
          Paint()..color = const Color(0xFF263238),
        );
      }
    }

    // White/Cream Counter Ledge wrapping around the 3 facets
    final Path counterLedge = Path()
      ..moveTo(-56, counterY - 2)
      ..lineTo(-22, counterY)
      ..lineTo(22, counterY)
      ..lineTo(56, counterY - 2);
    canvas.drawPath(
      counterLedge,
      Paint()
        ..color = const Color(0xFFF5F0E6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6,
    );

    // Iconic Scalloped / Zig-Zagging Bright Crimson-Red Crown Roof (`Gezacktes Rotes Zeltdach`, Photo 2!)
    final Path crownRoof = Path()
      ..moveTo(-62, eavesY - 4)
      ..lineTo(-40, eavesY - 18)
      ..lineTo(-22, eavesY - 3)
      ..lineTo(0, eavesY - 22)
      ..lineTo(22, eavesY - 3)
      ..lineTo(40, eavesY - 18)
      ..lineTo(62, eavesY - 4)
      ..lineTo(42, eavesY - 30)
      ..lineTo(-42, eavesY - 30)
      ..close();
    canvas.drawPath(
      crownRoof,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, eavesY - 30),
          const Offset(0, eavesY),
          const [Color(0xFFFF1744), Color(0xFFD50000), Color(0xFF9B0000)],
          const [0.0, 0.5, 1.0],
        ),
    );

    // Lush Green Pine Garland (`Tannengirlande`) with Twinkling Lights tracing the Zig-ZagGable Eaves (Photo 2!)
    final Path zigZagGarland = Path()
      ..moveTo(-62, eavesY - 4)
      ..lineTo(-40, eavesY - 18)
      ..lineTo(-22, eavesY - 3)
      ..lineTo(0, eavesY - 22)
      ..lineTo(22, eavesY - 3)
      ..lineTo(40, eavesY - 18)
      ..lineTo(62, eavesY - 4);
    canvas.drawPath(
      zigZagGarland,
      Paint()
        ..color = const Color(0xFF1B4D20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Glowing 3D Yellow-Orange Moravian Stars (`Herrnhuter Sterne`) on every peak of the pavilion roof (Photo 2!)
    _drawHerrnhuterStar(canvas, const Offset(-40, eavesY - 20), 4.5);
    _drawHerrnhuterStar(canvas, const Offset(0, eavesY - 25), 5.5);
    _drawHerrnhuterStar(canvas, const Offset(40, eavesY - 20), 4.5);

    // Yellow Star Sign Plaque under the center gable peak (Photo 2!)
    final RRect centerBadge = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: const Offset(0, eavesY + 2),
        width: 24,
        height: 5.5,
      ),
      const Radius.circular(2),
    );
    canvas.drawRRect(centerBadge, Paint()..color = const Color(0xFFE6B84C));

    // Festive Gifts & Nutcracker Guards arranged around the front base of the Pavilion
    _drawTreeBaseGiftsAndToys(canvas);
  }

  void _drawLebkuchenHeartOrnament(Canvas canvas, Offset c) {
    canvas.drawCircle(
      Offset(c.dx - 1.8, c.dy - 1),
      2.6,
      Paint()..color = const Color(0xFF8D4E2A),
    );
    canvas.drawCircle(
      Offset(c.dx + 1.8, c.dy - 1),
      2.6,
      Paint()..color = const Color(0xFF8D4E2A),
    );
    final Path bottom = Path()
      ..moveTo(c.dx - 4.2, c.dy)
      ..lineTo(c.dx, c.dy + 4.6)
      ..lineTo(c.dx + 4.2, c.dy)
      ..close();
    canvas.drawPath(bottom, Paint()..color = const Color(0xFF8D4E2A));
  }

  void _drawRoyalVelvetBow(Canvas canvas, Offset c) {
    final Paint bowPaint = Paint()..color = const Color(0xFFB71C1C);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(c.dx - 3.2, c.dy), width: 5.5, height: 3.6),
      bowPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(c.dx + 3.2, c.dy), width: 5.5, height: 3.6),
      bowPaint,
    );
    canvas.drawCircle(c, 1.8, Paint()..color = const Color(0xFFFFD54F));
  }

  void _drawStyleSpecificTreeFeatures(Canvas canvas) {
    const Offset topperPos = Offset(0, -168);

    canvas.drawCircle(
      topperPos,
      28.0,
      Paint()
        ..shader = ui.Gradient.radial(
          topperPos,
          28.0,
          [
            const Color(0xFFFFF59D).withValues(alpha: 0.82),
            const Color(0xFFFFB300).withValues(alpha: 0.30),
            Colors.transparent,
          ],
          const [0.0, 0.5, 1.0],
        ),
    );

    if (styleMode == CoconutStyleMode.arcade) {
      final Path santaHat = Path()
        ..moveTo(-18, -150)
        ..quadraticBezierTo(-2, -180, 22, -158)
        ..lineTo(14, -150)
        ..close();
      canvas.drawPath(santaHat, Paint()..color = const Color(0xFFD32F2F));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: const Offset(-1, -149),
            width: 38,
            height: 7,
          ),
          const Radius.circular(4),
        ),
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        const Offset(23, -158),
        5.5,
        Paint()..color = Colors.white,
      );

      final Paint framePaint = Paint()..color = const Color(0xFF111111);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: const Offset(-12, -108), width: 20, height: 11),
          const Radius.circular(2),
        ),
        framePaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: const Offset(12, -108), width: 20, height: 11),
          const Radius.circular(2),
        ),
        framePaint,
      );
      canvas.drawRect(
        Rect.fromCenter(center: const Offset(0, -109), width: 8, height: 3),
        framePaint,
      );
    } else if (styleMode == CoconutStyleMode.king) {
      final Path crown = Path()
        ..moveTo(-14, -156)
        ..lineTo(-17, -172)
        ..lineTo(-7, -163)
        ..lineTo(0, -176)
        ..lineTo(7, -163)
        ..lineTo(17, -172)
        ..lineTo(14, -156)
        ..close();
      canvas.drawPath(crown, Paint()..color = const Color(0xFFFFD54F));
    } else {
      _drawHerrnhuterStar(canvas, topperPos, 15.5);
    }

    if (styleMode == CoconutStyleMode.lofi) {
      canvas.drawArc(
        Rect.fromCenter(center: const Offset(0, -96), width: 76, height: 52),
        math.pi * 0.95,
        math.pi * 1.10,
        false,
        Paint()
          ..color = const Color(0xFF37474F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.2,
      );
      for (final double side in [-1.0, 1.0]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(side * 38, -92),
              width: 10.5,
              height: 20,
            ),
            const Radius.circular(5),
          ),
          Paint()..color = const Color(0xFFD32F2F),
        );
      }
    }
  }

  void _drawTreeBaseGiftsAndToys(Canvas canvas) {
    final List<(Offset, Size, Color, Color)> gifts = [
      (
        const Offset(-48, 12),
        const Size(15, 12),
        const Color(0xFFD32F2F),
        const Color(0xFFFFD54F),
      ),
      (
        const Offset(-31, 15),
        const Size(13, 10),
        const Color(0xFF1976D2),
        const Color(0xFFFFF59D),
      ),
      (
        const Offset(31, 15),
        const Size(14, 11),
        const Color(0xFF388E3C),
        const Color(0xFFFF5252),
      ),
      (
        const Offset(48, 12),
        const Size(16, 13),
        const Color(0xFF8E24AA),
        const Color(0xFFFFD54F),
      ),
    ];

    for (final (pos, boxSize, boxColor, ribbonColor) in gifts) {
      final Rect r = Rect.fromCenter(
        center: Offset(pos.dx, pos.dy - boxSize.height * 0.5),
        width: boxSize.width,
        height: boxSize.height,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(2.0)),
        Paint()..color = boxColor,
      );
      final Paint rib = Paint()
        ..color = ribbonColor
        ..strokeWidth = 1.8;
      canvas.drawLine(
        Offset(r.center.dx, r.top),
        Offset(r.center.dx, r.bottom),
        rib,
      );
      canvas.drawLine(
        Offset(r.left, r.center.dy),
        Offset(r.right, r.center.dy),
        rib,
      );
    }

    final List<double> nutcrackerX = styleMode == CoconutStyleMode.king
        ? [-62.0, 62.0]
        : [62.0];
    for (final double nx in nutcrackerX) {
      _drawNutcrackerSoldier(canvas, Offset(nx, 10));
    }
  }

  void _drawNutcrackerSoldier(Canvas canvas, Offset base) {
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(base.dx, base.dy - 4),
        width: 6,
        height: 8,
      ),
      Paint()..color = const Color(0xFF1565C0),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(base.dx, base.dy - 12),
          width: 8.5,
          height: 10,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFFC62828),
    );
    canvas.drawCircle(
      Offset(base.dx, base.dy - 20),
      3.4,
      Paint()..color = const Color(0xFFFFCCBC),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(base.dx, base.dy - 26),
          width: 7.5,
          height: 7.5,
        ),
        const Radius.circular(1.5),
      ),
      Paint()..color = const Color(0xFF212121),
    );
  }

  void _drawPhotorealisticCenterTreeAndPavilion(
    Canvas canvas,
    Size size,
    ui.Image treeImg,
  ) {
    final double cx = size.width * 0.5;
    final double cy = size.height * 0.885;
    final double pulseScale = 1.32 * (1.0 + coconutPulse * 0.06);
    final double sway = math.sin(time * 1.5) * 0.007;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(pulseScale, pulseScale);

    // 1. Soft Photographic Ground Ambient Occlusion & Warm Golden Light Reflection on the Plaza
    canvas.save();
    canvas.scale(2.7, 0.36);
    canvas.drawCircle(
      const Offset(0, 18),
      92.0,
      Paint()
        ..shader = ui.Gradient.radial(
          const Offset(0, 18),
          92.0,
          [
            const Color(0xFFFFD54F).withValues(alpha: 0.38),
            const Color(0xFFFF8F00).withValues(alpha: 0.16),
            Colors.transparent,
          ],
          const [0.0, 0.55, 1.0],
        ),
    );
    canvas.drawCircle(
      const Offset(0, 14),
      56.0,
      Paint()
        ..shader = ui.Gradient.radial(
          const Offset(0, 14),
          56.0,
          [
            Colors.black.withValues(alpha: 0.62),
            Colors.black.withValues(alpha: 0.28),
            Colors.transparent,
          ],
          const [0.0, 0.62, 1.0],
        ),
    );
    canvas.restore();

    // 2. Radiant Golden Halo behind the 25m Nordmann Fir Crown
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -118), width: 170, height: 200),
      Paint()
        ..shader = ui.Gradient.radial(
          const Offset(0, -118),
          100.0,
          [
            const Color(0xFFFFE082).withValues(alpha: 0.28),
            const Color(0xFFFFB300).withValues(alpha: 0.10),
            Colors.transparent,
          ],
          const [0.0, 0.60, 1.0],
        ),
    );

    // 3. Photorealistic Cologne Christmas Tree + Octagonal Red-Roofed Wooden Pavilion (`Baum-Pavillon`)
    canvas.save();
    canvas.rotate(sway * 0.45);
    final Rect srcRect = Rect.fromLTWH(
      0,
      0,
      treeImg.width.toDouble(),
      treeImg.height.toDouble(),
    );
    const Rect dstRect = Rect.fromLTRB(-136.0, -242.0, 136.0, 18.0);
    canvas.drawImageRect(
      treeImg,
      srcRect,
      dstRect,
      Paint()..filterQuality = FilterQuality.medium,
    );

    // 4. Live 60 FPS Twinkling Micro-LED Sparkles & Style Ornaments across the Photorealistic Tree
    for (int tier = 0; tier < 8; tier++) {
      final double t = tier / 7.0;
      final double y = -56.0 - tier * 20.5;
      final double halfW = 64.0 * (1.0 - t * 0.76);
      final int count = 9 - tier;
      for (int b = 0; b < count; b++) {
        final double bt = (b + 0.5) / count;
        final double bx = (bt - 0.5) * 2.0 * halfW;
        final double by = y + math.sin(bt * math.pi + tier) * 4.0;
        final double pulse =
            0.45 + 0.55 * math.sin(time * 4.8 + tier * 1.3 + b * 1.9);

        final Color bulbCol = styleMode == CoconutStyleMode.cocktail
            ? [
                const Color(0xFFFF4081),
                const Color(0xFF00E5FF),
                const Color(0xFFFFEE58),
                const Color(0xFF69F0AE),
              ][(tier + b) % 4]
            : const Color(0xFFFFF59D);

        if (pulse > 0.62 || styleMode == CoconutStyleMode.cocktail) {
          canvas.drawCircle(
            Offset(bx, by),
            3.2 * pulse,
            Paint()..color = bulbCol.withValues(alpha: 0.48 * pulse),
          );
          canvas.drawCircle(
            Offset(bx, by),
            1.2,
            Paint()..color = bulbCol.withValues(alpha: 0.92),
          );
        }

        if ((tier + b) % 3 == 0) {
          if (styleMode == CoconutStyleMode.cocktail) {
            _drawLebkuchenHeartOrnament(canvas, Offset(bx + 2.0, by + 3.0));
          } else if (styleMode == CoconutStyleMode.king) {
            _drawRoyalVelvetBow(canvas, Offset(bx + 2.0, by + 3.0));
          }
        }
      }
    }

    // 5. Interactive Style Mode Accessories on the Photorealistic Tree
    if (styleMode != CoconutStyleMode.natural) {
      canvas.save();
      canvas.translate(0, -64.0);
      _drawStyleSpecificTreeFeatures(canvas);
      canvas.restore();
      _drawTreeBaseGiftsAndToys(canvas);
    }
    canvas.restore();

    canvas.restore();
  }

  // ===========================================================================
  // 11. FALLING WINTER SNOWFLAKES ACROSS THE VIEW
  // ===========================================================================
  void _drawFallingSnow(Canvas canvas, Size size) {
    final int flakeCount = atmosphereMode == CoconutAtmosphereMode.rain
        ? 120
        : 64;
    final Paint flakePaint = _sharedSnowPaint;

    for (int i = 0; i < flakeCount; i++) {
      final double speed = 22.0 + (i % 5) * 9.0;
      final double drift = math.sin(time * 1.4 + i * 0.7) * 18.0;
      final double sx =
          ((i * 53.7 + drift - cameraYaw * 2.2) % size.width + size.width) %
          size.width;
      final double sy = ((i * 41.3 + time * speed) % size.height);
      final double r = 1.1 + (i % 3) * 0.8;
      final double alpha = 0.42 + (i % 4) * 0.14;
      flakePaint.color = Colors.white.withValues(alpha: alpha.clamp(0.0, 0.92));
      canvas.drawCircle(Offset(sx, sy), r, flakePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CologneChristmasWorldPainter oldDelegate) {
    if (controller != null && oldDelegate.controller == controller) {
      return false; // Repaints are driven directly by controller Listenable
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
