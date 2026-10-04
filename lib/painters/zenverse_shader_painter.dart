import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../controllers/zenverse_controller.dart';
import 'coconut_world_painter.dart';

/// Real-time GPU FragmentShader Post-Processing & 3D Perspective Parallax Painter
/// for ZenVerse: Chill Object Sim.
///
/// Combines:
/// 1. Custom GLSL Fragment Shader (`shaders/zenverse_fx.frag`) for GPU-accelerated
///    volumetric god-rays, water caustics, aurora ribbons, and rain refraction.
/// 2. 3D Perspective Depth Parallax particles (cameraYaw / cameraPitch / z-depth
///    projection) with reusable [Paint] instances for zero GC allocation per frame.
class ZenVerseShaderPainter extends CustomPainter {
  ZenVerseShaderPainter({
    required this.controller,
    required this.simulatorId,
  }) : super(repaint: controller);

  final ZenVerseController controller;
  final String simulatorId;

  static ui.FragmentProgram? _cachedProgram;
  static bool _loadAttempted = false;

  /// Preloads the GLSL fragment shader from assets. Safe to call in tests or
  /// before first frame; falls back gracefully if unavailable.
  static Future<ui.FragmentProgram?> preloadShader() async {
    if (_cachedProgram != null) return _cachedProgram;
    if (_loadAttempted) return null;
    _loadAttempted = true;
    try {
      _cachedProgram = await ui.FragmentProgram.fromAsset(
        'shaders/zenverse_fx.frag',
      );
      return _cachedProgram;
    } catch (_) {
      return null;
    }
  }

  // Reusable Paint objects to avoid per-frame allocations inside paint()
  static final Paint _shaderPaint = Paint()..blendMode = BlendMode.plus;
  static final Paint _bokehGlowPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _bokehCorePaint = Paint()..style = PaintingStyle.fill;
  static final Paint _flarePaint = Paint()..style = PaintingStyle.stroke;

  double _worldIndexForId(String id) {
    switch (id) {
      case 'coconut':
      case 'coconut_beach':
        return 0.0;
      case 'desert_cactus':
        return 1.0;
      case 'pine_tree':
      case 'pine_forest':
        return 2.0;
      case 'street_lamp':
      case 'cherry_bonsai':
        return 3.0;
      case 'mossy_rock':
      case 'bamboo_zen':
        return 4.0;
      case 'christmas_tree':
      case 'cologne_christmas':
        return 5.0;
      default:
        return 0.0;
    }
  }

  double _modeValue(ZenVerseShaderMode mode) {
    switch (mode) {
      case ZenVerseShaderMode.cinematicGodRays:
        return 1.0;
      case ZenVerseShaderMode.auroraDream:
        return 2.0;
      case ZenVerseShaderMode.cozyRefraction:
        return 3.0;
      case ZenVerseShaderMode.off:
        return 0.0;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final ZenVerseShaderMode mode = controller.shaderMode;
    if (mode == ZenVerseShaderMode.off) return;

    if (!_loadAttempted) {
      preloadShader();
    }

    final double time = controller.time;
    final double yaw = controller.cameraYaw;
    final double pitch = controller.cameraPitch;
    final CoconutAtmosphereMode atmo = controller.atmosphereMode;
    final double worldId = _worldIndexForId(simulatorId);

    // 1. GPU GLSL Fragment Shader Pass (Volumetric God-Rays, Caustics, Aurora, Lens FX)
    final ui.FragmentProgram? program = _cachedProgram;
    if (program != null) {
      final ui.FragmentShader shader = program.fragmentShader();
      shader.setFloat(0, size.width); // uSize.x
      shader.setFloat(1, size.height); // uSize.y
      shader.setFloat(2, time); // uTime
      shader.setFloat(3, yaw); // uYaw
      shader.setFloat(4, pitch); // uPitch
      shader.setFloat(5, atmo.index.toDouble()); // uAtmosphere
      shader.setFloat(6, worldId); // uWorldId
      shader.setFloat(7, _modeValue(mode)); // uMode

      _shaderPaint
        ..shader = shader
        ..blendMode = BlendMode.srcOver;
      canvas.drawRect(Offset.zero & size, _shaderPaint);
      _shaderPaint.shader = null;
    }

    // 2. 3D Depth-Projected Parallax Bokeh & Anamorphic Lens Glints
    _paint3DParallaxDepthParticles(
      canvas,
      size,
      time: time,
      yaw: yaw,
      pitch: pitch,
      atmo: atmo,
      mode: mode,
      worldId: worldId,
    );
  }

  void _paint3DParallaxDepthParticles(
    Canvas canvas,
    Size size, {
    required double time,
    required double yaw,
    required double pitch,
    required CoconutAtmosphereMode atmo,
    required ZenVerseShaderMode mode,
    required double worldId,
  }) {
    final double w = size.width;
    final double h = size.height;
    final double yawRad = yaw * math.pi / 180.0;
    final double pitchOffset = (pitch / 45.0) * h * 0.22;

    // Select world-aware accent palette
    final Color primaryTint;
    final Color secondaryTint;
    if (worldId == 5.0) {
      // Cologne Christmas warm gold & frost cyan
      primaryTint = const Color(0xFFFFD56B);
      secondaryTint = const Color(0xFFA8E6FF);
    } else if (worldId == 3.0) {
      // Cherry Bonsai sakura rose & pearl
      primaryTint = const Color(0xFFFFB3D1);
      secondaryTint = const Color(0xFFFFF0F6);
    } else if (worldId == 4.0) {
      // Bamboo Zen emerald firefly &jade
      primaryTint = const Color(0xFF80FFAC);
      secondaryTint = const Color(0xFFD4FFEA);
    } else if (atmo == CoconutAtmosphereMode.night) {
      primaryTint = const Color(0xFF7CE8FF);
      secondaryTint = const Color(0xFFB388FF);
    } else if (atmo == CoconutAtmosphereMode.sunset) {
      primaryTint = const Color(0xFFFFB76B);
      secondaryTint = const Color(0xFFFF6B9D);
    } else {
      primaryTint = const Color(0xFFFFF3B0);
      secondaryTint = const Color(0xFF8CE9FF);
    }

    // Project 22 multi-depth 3D particles across near, mid, and far Z planes
    const int count = 22;
    for (int i = 0; i < count; i++) {
      final double seed = i * 1.6180339;
      // zDepth in [0.25 .. 1.0]: smaller z = further away, larger z = closer foreground
      final double zDepth = 0.25 + ((i * 7) % 15) / 20.0;
      final double parallaxFactor = 0.4 + zDepth * 1.35;

      // World angle of particle in [0..2pi]
      final double baseAngle = (seed * 2.39996) % (math.pi * 2);
      final double driftX = math.sin(time * (0.25 + zDepth * 0.2) + seed) * 0.14;
      final double relAngle =
          ((baseAngle + driftX - yawRad * parallaxFactor) % (math.pi * 2) +
                  math.pi * 2) %
              (math.pi * 2);

      // Map visible front hemisphere [0..pi] onto screen X
      if (relAngle > math.pi * 1.15) continue;
      final double normX = (relAngle / (math.pi * 1.15));
      final double px = normX * w;

      // Vertical float with 3D pitch parallax
      final double baseNormY = ((seed * 3.17) % 0.82) + 0.08;
      final double floatY =
          math.cos(time * (0.4 + zDepth * 0.35) + seed * 2.1) * 14.0 * zDepth;
      final double py =
          baseNormY * h + floatY + pitchOffset * (0.35 + zDepth * 0.65);

      if (py < -20 || py > h + 20) continue;

      final double pulse =
          0.45 + 0.55 * math.sin(time * (1.4 + (i % 4) * 0.35) + seed * 3.0);
      final double radius = (2.2 + zDepth * 7.5) * (0.8 + pulse * 0.35);
      final Color particleColor = i.isEven ? primaryTint : secondaryTint;

      final double alphaGlow =
          (0.06 + zDepth * 0.12) * pulse * (mode == ZenVerseShaderMode.auroraDream ? 1.35 : 1.0);
      _bokehGlowPaint.color =
          particleColor.withValues(alpha: alphaGlow.clamp(0.0, 0.35));
      canvas.drawCircle(Offset(px, py), radius * 2.2, _bokehGlowPaint);

      _bokehCorePaint.color =
          Colors.white.withValues(alpha: (alphaGlow * 1.9).clamp(0.0, 0.65));
      canvas.drawCircle(Offset(px, py), radius * 0.48, _bokehCorePaint);
    }

    // 3. Cinematic Anamorphic Sun/Moon Lens Hex Glint when looking near light azimuth
    if (mode == ZenVerseShaderMode.cinematicGodRays ||
        mode == ZenVerseShaderMode.auroraDream) {
      final double lightCenterX = w * (0.5 + math.sin(yawRad) * 0.28);
      final double lightCenterY =
          h * (0.26 + (pitch / 90.0) * 0.35).clamp(0.08, 0.52);
      final Offset screenCenter = Offset(w * 0.5, h * 0.5);
      final Offset flareAxis = screenCenter - Offset(lightCenterX, lightCenterY);

      for (int k = 1; k <= 3; k++) {
        final double t = k * 0.42;
        final Offset flarePos = Offset(lightCenterX, lightCenterY) + flareAxis * t;
        final double ringRadius = 12.0 + k * 11.0 + math.sin(time + k) * 2.5;
        _flarePaint
          ..color = primaryTint.withValues(alpha: 0.085 / k)
          ..strokeWidth = 1.4;
        canvas.drawCircle(flarePos, ringRadius, _flarePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ZenVerseShaderPainter oldDelegate) {
    return oldDelegate.controller != controller ||
        oldDelegate.simulatorId != simulatorId;
  }
}
