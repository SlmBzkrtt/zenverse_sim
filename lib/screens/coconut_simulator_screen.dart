import 'dart:async';
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../controllers/zenverse_controller.dart';
import '../core/game_constants.dart';
import '../models/zenverse_model.dart';
import '../painters/coconut_world_painter.dart';
import '../painters/cologne_christmas_world_painter.dart';
import '../painters/desert_cactus_world_painter.dart';
import '../painters/pine_forest_world_painter.dart';
import '../painters/street_lamp_world_painter.dart';
import '../painters/zen_valley_world_painter.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';

export '../controllers/zenverse_controller.dart' show CameraRotationMode;

class CoconutSimulatorScreen extends StatefulWidget {
  final ZenVerseModel simulator;
  final CoconutAtmosphereMode initialAtmosphere;
  final CoconutStyleMode initialStyle;

  const CoconutSimulatorScreen({
    super.key,
    required this.simulator,
    this.initialAtmosphere = CoconutAtmosphereMode.sunset,
    this.initialStyle = CoconutStyleMode.natural,
  });

  @override
  State<CoconutSimulatorScreen> createState() => _CoconutSimulatorScreenState();
}

class _CoconutSimulatorScreenState extends State<CoconutSimulatorScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker;
  late final ZenVerseController _gameController;

  Duration _lastElapsed = Duration.zero;
  int _lastSavedMeditationSecs = 0;

  // Ambient Desk Clock & Cinematic Letterbox Mode
  bool _isDisplayMode = false;
  bool _hideHud = false;

  // Meditative & Observational Small Texts index
  int _thoughtIndex = 0;
  Timer? _thoughtTimer;

  List<ScenicPoint> get _scenicPoints => widget.simulator.scenicPoints;
  List<String> get _thoughts => widget.simulator.thoughts;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    CologneChristmasAssets.ensureLoaded();

    _gameController = ZenVerseController(
      scenicPoints: _scenicPoints,
      initialYaw: 15.0,
      initialPitch: 0.0,
      initialAtmosphere: widget.initialAtmosphere,
      initialStyle: widget.initialStyle,
    );

    _ticker = createTicker(_onTick)..start();
    _startThoughtTimer();
    AudioService.instance.startAmbientForWorld(widget.simulator.id);
  }

  void _startThoughtTimer() {
    _thoughtTimer?.cancel();
    _thoughtTimer = Timer.periodic(
      const Duration(seconds: GameConstants.thoughtRotationIntervalSeconds),
      (_) {
        if (mounted && _thoughts.isNotEmpty) {
          setState(() {
            _thoughtIndex = (_thoughtIndex + 1) % _thoughts.length;
          });
        }
      },
    );
  }

  void _flushMeditationProgress() {
    final int currentSecs = _gameController.elapsedSecondsNotifier.value;
    final int delta = currentSecs - _lastSavedMeditationSecs;
    if (delta > 0) {
      _lastSavedMeditationSecs = currentSecs;
      StorageService.instance.addMeditationSeconds(
        widget.simulator.id,
        delta,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        if (_ticker.isActive) {
          _ticker.stop();
        }
        _thoughtTimer?.cancel();
        _flushMeditationProgress();
        AudioService.instance.pauseForLifecycle();
      case AppLifecycleState.resumed:
        if (mounted && !_ticker.isActive) {
          _lastElapsed = Duration.zero;
          _ticker.start();
        }
        _startThoughtTimer();
        AudioService.instance.resumeFromLifecycle();
    }
  }

  /// High-frequency 60–120 FPS render tick.
  /// Updates [_gameController] directly WITHOUT calling `setState()`,
  /// so only the isolated [RepaintBoundary] canvas repaints each frame.
  void _onTick(Duration elapsed) {
    final double dt = (_lastElapsed == Duration.zero)
        ? 0.016
        : (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;
    _gameController.tick(dt);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flushMeditationProgress();
    _thoughtTimer?.cancel();
    _ticker.dispose();
    _gameController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final bool modeChanged =
        _gameController.rotationMode != CameraRotationMode.manual;
    _gameController.onPanUpdate(details.delta);
    if (modeChanged && mounted) {
      setState(() {});
    }
  }

  void _onPanEnd(DragEndDetails details) {
    _gameController.onPanEnd(details.velocity.pixelsPerSecond.dx);
  }

  void _triggerCoconutPulse() {
    HapticFeedback.lightImpact();
    AudioService.instance.playInteractionChime();
    _gameController.triggerPulse();
  }

  void _animateLookTo(double targetAngle) {
    HapticFeedback.selectionClick();
    setState(() {
      _gameController.animateLookTo(targetAngle);
    });
  }

  void _cycleStyleMode() {
    _triggerCoconutPulse();
    setState(() {
      _gameController.cycleStyleMode();
    });
    StorageService.instance.saveStyleMode(
      _gameController.styleMode,
      worldId: widget.simulator.id,
    );
  }

  void _cycleRotationMode() {
    HapticFeedback.selectionClick();
    setState(() {
      _gameController.cycleRotationMode();
    });
  }

  void _cycleAtmosphereMode() {
    HapticFeedback.selectionClick();
    setState(() {
      _gameController.cycleAtmosphereMode();
    });
    StorageService.instance.saveAtmosphereMode(
      _gameController.atmosphereMode,
      worldId: widget.simulator.id,
    );
  }

  void _cycleZoom() {
    HapticFeedback.selectionClick();
    setState(() {
      _gameController.cycleZoom();
    });
  }

  String _getStyleButtonLabel() {
    final labels = widget.simulator.styleLabels;
    final idx = _gameController.styleMode.index.clamp(0, labels.length - 1);
    return labels[idx];
  }

  String _getRotationButtonLabel() {
    return switch (_gameController.rotationMode) {
      CameraRotationMode.manual => '360° Oto',
      CameraRotationMode.normalOrbit => '🔄 360° Tur',
      CameraRotationMode.slowZenOrbit => '🐢 Zen Tur',
      CameraRotationMode.pendulumSweep => '🎬 Sarkaç',
      CameraRotationMode.guidedPoiTour => '📍 Rehber Tur',
    };
  }

  String _getAtmosphereButtonLabel() {
    final labels = widget.simulator.atmosphereLabels;
    final idx =
        _gameController.atmosphereMode.index.clamp(0, labels.length - 1);
    return labels[idx];
  }

  String _getZoomButtonLabel() {
    if (_gameController.cameraZoom > 1.1) return '🔍 1.25x Yakın';
    if (_gameController.cameraZoom < 0.95) return '🔍 0.85x Geniş';
    return '🔍 1.0x Kadraj';
  }

  String _getDirectionLabel(double yaw) {
    return widget.simulator.getDirectionLabel(yaw);
  }

  String _formatMeditationDuration(int totalSecs) {
    final int mins = totalSecs ~/ 60;
    final int secs = totalSecs % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _getAmbientTimeString() {
    return switch (_gameController.atmosphereMode) {
      CoconutAtmosphereMode.sunset => '18:42',
      CoconutAtmosphereMode.night => '23:15',
      CoconutAtmosphereMode.noon => '13:20',
      CoconutAtmosphereMode.rain => '17:05',
    };
  }

  String _getAmbientWeatherString() {
    final labels = widget.simulator.ambientWeatherLabels;
    final idx =
        _gameController.atmosphereMode.index.clamp(0, labels.length - 1);
    return labels[idx];
  }

  CustomPainter _buildWorldPainter() {
    return switch (widget.simulator.id) {
      'pine_tree' => PineForestWorldPainter(controller: _gameController),
      'mossy_rock' => ZenValleyWorldPainter(controller: _gameController),
      'street_lamp' => StreetLampWorldPainter(controller: _gameController),
      'desert_cactus' => DesertCactusWorldPainter(controller: _gameController),
      'christmas_tree' =>
        CologneChristmasWorldPainter(controller: _gameController),
      _ => CoconutWorldPainter(controller: _gameController),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1026),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final ResponsiveViewport vp =
              ResponsiveViewport.fromConstraints(constraints);

          return Listener(
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                final double delta =
                    event.scrollDelta.dx.abs() > event.scrollDelta.dy.abs()
                        ? event.scrollDelta.dx
                        : event.scrollDelta.dy;
                final bool wasAuto =
                    _gameController.rotationMode != CameraRotationMode.manual;
                _gameController.onPointerScroll(delta);
                if (wasAuto && mounted) {
                  setState(() {});
                }
              }
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              onTapUp: (details) {
                if (vp.isCenterObjectHit(details.localPosition)) {
                  _triggerCoconutPulse();
                }
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Isolated 60 FPS Live 360° World Canvas (Zero Widget Rebuilds per Frame)
                  RepaintBoundary(
                    child: CustomPaint(
                      painter: _buildWorldPainter(),
                      size: Size.infinite,
                    ),
                  ),

                  // 2. Ambient Display / Cinematic Frame Mode Overlay
                  if (_isDisplayMode && !_hideHud)
                    _buildAmbientDisplayOverlay(context, vp),

                  // 3. Standard Adaptive Top & Bottom Zen HUD Overlays
                  if (!_isDisplayMode)
                    SafeArea(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 350),
                        opacity: _hideHud ? 0.0 : 1.0,
                        child: IgnorePointer(
                          ignoring: _hideHud,
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: vp.hudMaxWidth,
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildTopBar(context, vp),
                                  _buildBottomPanel(context, vp),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // 4. Minimal floating button to restore HUD when in pure Zen mode
                  if (_hideHud)
                    Positioned(
                      top: MediaQuery.paddingOf(context).top + 12,
                      right: vp.horizontalPadding,
                      child: _buildGlassIconButton(
                        icon: Icons.visibility_rounded,
                        tooltip: 'Arayüzü Göster',
                        onTap: () => setState(() => _hideHud = false),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAmbientDisplayOverlay(
    BuildContext context,
    ResponsiveViewport vp,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Top Cinematic Letterbox Bar + Ambient Clock & Telemetry
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            vp.horizontalPadding,
            MediaQuery.paddingOf(context).top + 12,
            vp.horizontalPadding,
            18,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.82),
                Colors.black.withValues(alpha: 0.45),
                Colors.transparent,
              ],
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: vp.hudMaxWidth),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            Text(
                              _getAmbientTimeString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32 * vp.uiScale,
                                fontWeight: FontWeight.w200,
                                letterSpacing: 2.0,
                              ),
                            ),
                            ValueListenableBuilder<int>(
                              valueListenable:
                                  _gameController.roundedYawNotifier,
                              builder: (context, roundedYaw, _) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFAB40)
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFFFCC80)
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Text(
                                    '$roundedYaw° • ${_getRotationButtonLabel()}',
                                    style: const TextStyle(
                                      color: Color(0xFFFFE0B2),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.simulator.displayLocationName} • ${_getAmbientWeatherString()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 11.5,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Quick controls in Display Mode
                  _buildGlassIconButton(
                    icon: Icons.wb_twilight_rounded,
                    tooltip: 'Atmosfer Değiştir',
                    onTap: _cycleAtmosphereMode,
                  ),
                  const SizedBox(width: 8),
                  _buildGlassIconButton(
                    icon: Icons.threesixty_rounded,
                    tooltip: 'Dönüş Şeklini Değiştir',
                    onTap: _cycleRotationMode,
                  ),
                  const SizedBox(width: 8),
                  _buildGlassIconButton(
                    icon: Icons.tv_off_rounded,
                    tooltip: 'Standart Görünüme Dön',
                    onTap: () => setState(() => _isDisplayMode = false),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Bottom Cinematic Letterbox Bar with Contemplative Quote
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            vp.horizontalPadding,
            24,
            vp.horizontalPadding,
            MediaQuery.paddingOf(context).bottom + 16,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withValues(alpha: 0.84),
                Colors.black.withValues(alpha: 0.42),
                Colors.transparent,
              ],
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: vp.hudMaxWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ValueListenableBuilder<int>(
                    valueListenable: _gameController.roundedYawNotifier,
                    builder: (context, _, _) {
                      return Text(
                        _getDirectionLabel(_gameController.cameraYaw),
                        style: const TextStyle(
                          color: Color(0xFFFFCC80),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _thoughtIndex = (_thoughtIndex + 1) % _thoughts.length;
                      });
                    },
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      child: Text(
                        '"${_thoughts[_thoughtIndex % _thoughts.length]}"',
                        key: ValueKey<int>(_thoughtIndex),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.90),
                          fontSize: 13.5,
                          fontStyle: FontStyle.italic,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context, ResponsiveViewport vp) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: vp.horizontalPadding,
        vertical: vp.isShortLandscape ? 6 : 10,
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildGlassIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                tooltip: 'Menüye Dön',
                onTap: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 10),
              // 360° Compass Pill (rebuilds only when integer degree changes)
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.34),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                      ),
                      child: ValueListenableBuilder<int>(
                        valueListenable: _gameController.roundedYawNotifier,
                        builder: (context, roundedYaw, _) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.explore_outlined,
                                color: Color(0xFFFFB74D),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '$roundedYaw° • ${_getDirectionLabel(_gameController.cameraYaw)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Ambient Audio Mute/Unmute Toggle
              ValueListenableBuilder<bool>(
                valueListenable: StorageService.instance.isAudioMuted,
                builder: (context, isMuted, _) {
                  return _buildGlassIconButton(
                    icon: isMuted
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    tooltip: isMuted ? 'Sesi Aç' : 'Sesi Kapat',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      AudioService.instance.toggleMute();
                    },
                  );
                },
              ),
              const SizedBox(width: 8),
              _buildGlassIconButton(
                icon: Icons.tv_rounded,
                tooltip: 'Sinematik Display & Saat Modu',
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isDisplayMode = true);
                },
              ),
              const SizedBox(width: 8),
              _buildGlassIconButton(
                icon: Icons.visibility_off_outlined,
                tooltip: 'Tam Ekran Zen Modu',
                onTap: () => setState(() => _hideHud = true),
              ),
            ],
          ),
          SizedBox(height: vp.isShortLandscape ? 6 : 10),
          // 5 Core Quick 360° Look Direction Chips (centered & non-overflowing)
          ValueListenableBuilder<int>(
            valueListenable: _gameController.roundedYawNotifier,
            builder: (context, _, _) {
              return Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (int i = 0; i < _scenicPoints.length; i++)
                    _buildQuickAngleChip(
                      _scenicPoints[i].label,
                      _scenicPoints[i].angle,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAngleChip(String label, double targetAngle) {
    double diff = (_gameController.cameraYaw - targetAngle).abs() % 360.0;
    if (diff > 180.0) diff = 360.0 - diff;
    final bool isSelected = diff < 16.0;

    return GestureDetector(
      onTap: () => _animateLookTo(targetAngle),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF8C42).withValues(alpha: 0.85)
              : Colors.black.withValues(alpha: 0.30),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFFE082)
                : Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.black
                : Colors.white.withValues(alpha: 0.92),
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel(BuildContext context, ResponsiveViewport vp) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        vp.horizontalPadding,
        0,
        vp.horizontalPadding,
        vp.isShortLandscape ? 8 : 14,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Meditative quote / status & multi-mode control card
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: vp.isShortLandscape ? 8 : 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.38),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  children: [
                    // Tappable Meditative Thought (Tap to read next small text)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _thoughtIndex =
                              (_thoughtIndex + 1) % _thoughts.length;
                        });
                      },
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 550),
                        child: Text(
                          _thoughts[_thoughtIndex % _thoughts.length],
                          key: ValueKey<int>(_thoughtIndex),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.93),
                            fontSize: 12.8,
                            fontStyle: FontStyle.italic,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: vp.isShortLandscape ? 6 : 10),
                    // Mode Control Strip (Wrapped cleanly so all modes are immediately visible & tappable)
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        // Meditation Timer Pill (Rebuilds only once per second)
                        ValueListenableBuilder<int>(
                          valueListenable:
                              _gameController.elapsedSecondsNotifier,
                          builder: (context, elapsedSecs, _) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.self_improvement_rounded,
                                    color: Color(0xFFFFCC80),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Süre: ${_formatMeditationDuration(elapsedSecs)}',
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.82),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        // 1. Coconut Style Mode (Realistic -> Arcade -> Kokteyl -> Kral -> Lo-Fi)
                        _buildModeButton(
                          label: _getStyleButtonLabel(),
                          active: _gameController.styleMode !=
                              CoconutStyleMode.natural,
                          onTap: _cycleStyleMode,
                        ),
                        // 2. 360° Camera Rotation Mode (5 Dönüş Şekli)
                        _buildModeButton(
                          label: _getRotationButtonLabel(),
                          active: _gameController.rotationMode !=
                              CameraRotationMode.manual,
                          onTap: _cycleRotationMode,
                        ),
                        // 3. Atmosphere / Time Mode (Gün Batımı -> Gece -> Öğle -> Yağmur)
                        _buildModeButton(
                          label: _getAtmosphereButtonLabel(),
                          active: _gameController.atmosphereMode !=
                              CoconutAtmosphereMode.sunset,
                          onTap: _cycleAtmosphereMode,
                        ),
                        // 4. Camera Zoom / Framing Mode
                        _buildModeButton(
                          label: _getZoomButtonLabel(),
                          active: _gameController.cameraZoom != 1.0,
                          onTap: _cycleZoom,
                        ),
                        // 5. Ambient Display Mode Toggle
                        _buildModeButton(
                          label: '🖥️ Display',
                          active: _isDisplayMode,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _isDisplayMode = !_isDisplayMode);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFFFFAB40).withValues(alpha: 0.88)
              : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? const Color(0xFFFFE082)
                : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.black : Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildGlassIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 42,
          child: AspectRatio(
            aspectRatio: 1.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.18)),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.all(11),
                      child: Icon(icon, color: Colors.white, size: 19),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
