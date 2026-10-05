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
import 'coconut_simulator_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker;
  late final PageController _pageController;
  late final ZenVerseController _previewController;
  final FocusNode _keyboardFocusNode = FocusNode();

  Duration _lastElapsed = Duration.zero;
  int _selectedIndex = 0;
  bool _isInSubScreen = false;

  DateTime _lastWheelScroll = DateTime.fromMillisecondsSinceEpoch(0);
  bool _isAnimatingToPage = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    CologneChristmasAssets.ensureLoaded();

    _selectedIndex = StorageService.instance.loadSelectedWorldIndex(
      maxCount: availableSimulators.length,
    );
    final String initialWorldId = availableSimulators[_selectedIndex].id;
    final CoconutAtmosphereMode savedAtmosphere =
        StorageService.instance.loadAtmosphereMode(worldId: initialWorldId);
    final CoconutStyleMode savedStyle =
        StorageService.instance.loadStyleMode(worldId: initialWorldId);

    _previewController = ZenVerseController(
      scenicPoints: availableSimulators[_selectedIndex].scenicPoints,
      initialYaw: GameConstants.defaultPreviewYaw,
      initialPitch: GameConstants.defaultPreviewPitch,
      initialAtmosphere: savedAtmosphere,
      initialStyle: savedStyle,
      initialRotationMode: CameraRotationMode.normalOrbit,
    );

    _pageController = PageController(
      initialPage: _selectedIndex,
      viewportFraction: 0.82,
    );
    _ticker = createTicker(_onTick)..start();
    AudioService.instance.startAmbientForWorld(
      initialWorldId,
      atmosphere: savedAtmosphere,
      style: savedStyle,
      initialYaw: _previewController.cameraYaw,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isInSubScreen) return;
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        if (_ticker.isActive) {
          _ticker.stop();
        }
        AudioService.instance.pauseForLifecycle();
      case AppLifecycleState.resumed:
        if (mounted && !_ticker.isActive) {
          _lastElapsed = Duration.zero;
          _ticker.start();
        }
        AudioService.instance.resumeFromLifecycle();
    }
  }

  /// High-frequency 60–120 FPS render tick.
  /// Drives [_previewController] directly without `setState()` so the Glassmorphic
  /// menu cards, PageView, and BackdropFilters never rebuild per frame.
  void _onTick(Duration elapsed) {
    final double dt = (_lastElapsed == Duration.zero)
        ? 0.016
        : (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;
    _previewController.tick(dt, isMenuPreview: true);
    AudioService.instance.updateCameraOrientation(
      yaw: _previewController.cameraYaw,
      worldId: availableSimulators[_selectedIndex].id,
      isMenuPreview: true,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _previewController.dispose();
    _pageController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _syncPreviewWorldPreferences(ZenVerseModel sim) {
    _previewController.updateScenicPoints(sim.scenicPoints);
    _previewController.setStyleAndAtmosphere(
      style: StorageService.instance.loadStyleMode(worldId: sim.id),
      atmosphere: StorageService.instance.loadAtmosphereMode(worldId: sim.id),
    );
  }

  void _animateToSimulator(int index) {
    final int clamped = index.clamp(0, availableSimulators.length - 1);
    final ZenVerseModel nextSim = availableSimulators[clamped];
    HapticFeedback.selectionClick();
    setState(() {
      _selectedIndex = clamped;
      _syncPreviewWorldPreferences(nextSim);
    });
    StorageService.instance.saveSelectedWorldIndex(clamped);
    AudioService.instance.startAmbientForWorld(
      nextSim.id,
      atmosphere: _previewController.atmosphereMode,
      style: _previewController.styleMode,
      initialYaw: _previewController.cameraYaw,
    );

    if (!_pageController.hasClients) {
      return;
    }
    _isAnimatingToPage = true;
    _pageController
        .animateToPage(
          clamped,
          duration: const Duration(milliseconds: 340),
          curve: Curves.easeOutCubic,
        )
        .whenComplete(() {
          if (mounted) {
            _isAnimatingToPage = false;
          }
        });
  }

  void _handlePointerScroll(PointerScrollEvent event) {
    final DateTime now = DateTime.now();
    if (now.difference(_lastWheelScroll).inMilliseconds < 260) return;
    final double delta =
        event.scrollDelta.dx.abs() > event.scrollDelta.dy.abs()
            ? event.scrollDelta.dx
            : event.scrollDelta.dy;
    if (delta.abs() < 6.0) return;
    _lastWheelScroll = now;
    if (delta > 0 && _selectedIndex < availableSimulators.length - 1) {
      _animateToSimulator(_selectedIndex + 1);
    } else if (delta < 0 && _selectedIndex > 0) {
      _animateToSimulator(_selectedIndex - 1);
    }
  }

  CustomPainter _buildPreviewPainter(ZenVerseModel sim) {
    return switch (sim.id) {
      'pine_tree' => PineForestWorldPainter(controller: _previewController),
      'mossy_rock' => ZenValleyWorldPainter(controller: _previewController),
      'street_lamp' => StreetLampWorldPainter(controller: _previewController),
      'desert_cactus' =>
        DesertCactusWorldPainter(controller: _previewController),
      'christmas_tree' =>
        CologneChristmasWorldPainter(controller: _previewController),
      _ => CoconutWorldPainter(controller: _previewController),
    };
  }

  void _launchSimulator(ZenVerseModel sim) {
    HapticFeedback.mediumImpact();
    AudioService.instance.playInteractionChime();
    if (!sim.isUnlocked) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1F263E),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Row(
            children: [
              const Icon(Icons.lock_clock_rounded, color: Color(0xFFFFB74D)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${sim.title} yakında eklenecek!',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    _isInSubScreen = true;
    _ticker.stop();
    Navigator.of(context)
        .push(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 650),
            pageBuilder: (context, animation, secondaryAnimation) =>
                CoconutSimulatorScreen(
                  simulator: sim,
                  initialAtmosphere: _previewController.atmosphereMode,
                  initialStyle: _previewController.styleMode,
                ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
                child: child,
              );
            },
          ),
        )
        .then((_) {
          _isInSubScreen = false;
          if (mounted) {
            final ZenVerseModel active = availableSimulators[_selectedIndex];
            _syncPreviewWorldPreferences(active);
            if (!_ticker.isActive) {
              _lastElapsed = Duration.zero;
              _ticker.start();
            }
            AudioService.instance.startAmbientForWorld(
              active.id,
              atmosphere: _previewController.atmosphereMode,
              style: _previewController.styleMode,
              initialYaw: _previewController.cameraYaw,
            );
            setState(() {});
          }
        });
  }

  String _shortMenuLabel(ZenVerseModel sim) {
    return switch (sim.id) {
      'coconut' => '🥥 Coconut',
      'pine_tree' => '🌲 Çam Ağacı',
      'mossy_rock' => '🪨 Zen Kayası',
      'street_lamp' => '🏮 Sokak Lambası',
      'desert_cactus' => '🌵 Çöl Kaktüsü',
      'christmas_tree' => '🎄 Noel Ağacı',
      _ => sim.title.replaceAll(' Simulator', ''),
    };
  }

  @override
  Widget build(BuildContext context) {
    final ZenVerseModel activeSim = availableSimulators[_selectedIndex];
    final bool autoOrbitPreview =
        _previewController.rotationMode != CameraRotationMode.manual;

    return Scaffold(
      backgroundColor: const Color(0xFF0E1124),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final ResponsiveViewport vp =
              ResponsiveViewport.fromConstraints(constraints);

          return Focus(
            focusNode: _keyboardFocusNode,
            autofocus: true,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                  if (_selectedIndex < availableSimulators.length - 1) {
                    _animateToSimulator(_selectedIndex + 1);
                  }
                  return KeyEventResult.handled;
                } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                  if (_selectedIndex > 0) {
                    _animateToSimulator(_selectedIndex - 1);
                  }
                  return KeyEventResult.handled;
                } else if (event.logicalKey == LogicalKeyboardKey.enter ||
                    event.logicalKey == LogicalKeyboardKey.space) {
                  _launchSimulator(activeSim);
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Isolated 60 FPS Live 360° Background Preview Canvas
                RepaintBoundary(
                  child: CustomPaint(
                    painter: _buildPreviewPainter(activeSim),
                    size: Size.infinite,
                  ),
                ),

                // 2. Subtle Top & Bottom Vignette
                IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.60),
                          Colors.black.withValues(alpha: 0.08),
                          Colors.black.withValues(alpha: 0.04),
                          Colors.black.withValues(alpha: 0.76),
                        ],
                        stops: const [0.0, 0.24, 0.56, 1.0],
                      ),
                    ),
                  ),
                ),

                // 3. Adaptive Foreground Split UI
                SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: vp.hudMaxWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // A. COMPACT TOP BAR
                          _buildTopHeader(activeSim, autoOrbitPreview, vp),

                          // B. INTERACTIVE 360° LIVE STAGE
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onPanUpdate: (details) {
                                final bool wasAuto =
                                    _previewController.rotationMode !=
                                        CameraRotationMode.manual;
                                _previewController.onPanUpdate(
                                  details.delta,
                                  isPreview: true,
                                );
                                if (wasAuto && mounted) {
                                  setState(() {});
                                }
                              },
                              child: Stack(
                                children: [
                                  // Quick Scenic Point Look Chips at top of stage
                                  Positioned(
                                    top: 6,
                                    left: vp.horizontalPadding,
                                    right: vp.horizontalPadding,
                                    child: Center(
                                      child: ValueListenableBuilder<int>(
                                        valueListenable: _previewController
                                            .roundedYawNotifier,
                                        builder: (context, _, _) {
                                          return SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                for (final point
                                                    in activeSim.scenicPoints)
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 3,
                                                    ),
                                                    child: _buildStagePoiPill(
                                                      point,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),

                                  // Live 360° Stage Floating Status Pill
                                  if (!vp.isShortLandscape)
                                    Positioned(
                                      bottom: 8,
                                      left: vp.horizontalPadding,
                                      right: vp.horizontalPadding,
                                      child: Center(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(
                                              sigmaX: 10,
                                              sigmaY: 10,
                                            ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.black
                                                    .withValues(alpha: 0.42),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.20),
                                                ),
                                              ),
                                              child:
                                                  ValueListenableBuilder<int>(
                                                valueListenable:
                                                    _previewController
                                                        .roundedYawNotifier,
                                                builder:
                                                    (context, roundedYaw, _) {
                                                  return Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons
                                                            .threesixty_rounded,
                                                        color:
                                                            Color(0xFFFFCC80),
                                                        size: 15,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Flexible(
                                                        child: Text(
                                                          'Canlı 360° Sahne ($roundedYaw° • ${activeSim.getDirectionLabel(_previewController.cameraYaw)}) — Çevirmek için sahneyi sürükleyin',
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: TextStyle(
                                                            color: Colors.white
                                                                .withValues(
                                                                  alpha: 0.92,
                                                                ),
                                                            fontSize: 11.2,
                                                            fontWeight:
                                                                FontWeight.w600,
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
                                    ),
                                ],
                              ),
                            ),
                          ),

                          // C. BOTTOM CONTROL DOCK
                          _buildBottomControlDock(activeSim, vp),
                        ],
                      ),
                    ),
                  ),
                ),
                // 4. Floating ℹ️ Lisans button — bottom-right corner, always visible
                Positioned(
                  right: 14,
                  bottom: MediaQuery.paddingOf(context).bottom + 74,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _showMusicCreditsDialog();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFFFFCC80),
                            size: 14,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Lisans',
                            style: TextStyle(
                              color: Color(0xFFFFE0B2),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopHeader(
    ZenVerseModel activeSim,
    bool autoOrbitPreview,
    ResponsiveViewport vp,
  ) {
    final CoconutStyleMode previewStyle = _previewController.styleMode;
    final CoconutAtmosphereMode previewAtmosphere =
        _previewController.atmosphereMode;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        vp.horizontalPadding,
        vp.isShortLandscape ? 4 : 8,
        vp.horizontalPadding,
        4,
      ),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              // Brand Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.40),
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.22)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.threesixty_rounded,
                      color: Color(0xFFFFCC80),
                      size: 15,
                    ),
                    SizedBox(width: 6),
                    Text(
                      '360° MEDİTASYON & NESNE SİMÜLATÖRÜ',
                      style: TextStyle(
                        color: Color(0xFFFFE0B2),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.9,
                      ),
                    ),
                  ],
                ),
              ),
              // Live Preview Style, Atmosphere & Auto-Orbit Quick Toggles
              _buildPreviewControlPill(
                label:
                    'Stil: ${activeSim.styleLabels[previewStyle.index.clamp(0, activeSim.styleLabels.length - 1)]}',
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _previewController.cycleStyleMode();
                  });
                  StorageService.instance.saveStyleMode(
                    _previewController.styleMode,
                    worldId: activeSim.id,
                  );
                  AudioService.instance.startAmbientForWorld(
                    activeSim.id,
                    atmosphere: _previewController.atmosphereMode,
                    style: _previewController.styleMode,
                    initialYaw: _previewController.cameraYaw,
                  );
                },
              ),
              _buildPreviewControlPill(
                label: switch (previewAtmosphere) {
                  CoconutAtmosphereMode.sunset => 'Atmosfer: 🌅 Gün Batımı',
                  CoconutAtmosphereMode.night => 'Atmosfer: 🌙 Gece',
                  CoconutAtmosphereMode.noon => 'Atmosfer: ☀️ Öğle',
                  CoconutAtmosphereMode.rain => 'Atmosfer: 🌧️ Yağmur/Kar',
                },
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _previewController.cycleAtmosphereMode();
                  });
                  StorageService.instance.saveAtmosphereMode(
                    _previewController.atmosphereMode,
                    worldId: activeSim.id,
                  );
                  AudioService.instance.startAmbientForWorld(
                    activeSim.id,
                    atmosphere: _previewController.atmosphereMode,
                    style: _previewController.styleMode,
                    initialYaw: _previewController.cameraYaw,
                  );
                },
              ),
              _buildPreviewControlPill(
                label: autoOrbitPreview ? '🔄 Oto Önizleme' : '✋ Manuel',
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _previewController.setAutoOrbitPreview(!autoOrbitPreview);
                  });
                },
              ),
              ValueListenableBuilder<bool>(
                valueListenable: StorageService.instance.isAudioMuted,
                builder: (context, isMuted, _) {
                  return _buildPreviewControlPill(
                    label: isMuted ? '🔇 Ses Kapalı' : '🔊 Ses Açık',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      AudioService.instance.toggleMute();
                    },
                  );
                },
              ),
              _buildPreviewControlPill(
                label: 'ℹ️ Lisans',
                onTap: () {
                  HapticFeedback.selectionClick();
                  _showMusicCreditsDialog();
                },
              ),
            ],
          ),
          SizedBox(height: vp.isShortLandscape ? 3 : 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: const Text(
                    GameConstants.appTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [activeSim.themeColors[0], activeSim.themeColors[1]],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_selectedIndex + 1} / ${availableSimulators.length} DÜNYA',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          if (!vp.isShortLandscape) ...[
            const SizedBox(height: 2),
            Text(
              'Hiçbir görev yok. Sadece bir nesne ol ve etrafındaki canlı dünyayı izle.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.80),
                fontSize: 12,
                height: 1.25,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewControlPill({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildStagePoiPill(ScenicPoint point) {
    double diff = (_previewController.cameraYaw - point.angle).abs() % 360.0;
    if (diff > 180.0) diff = 360.0 - diff;
    final bool isFocused = diff < 18.0;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _previewController.animateLookTo(point.angle);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isFocused
              ? const Color(0xFFFF8C42).withValues(alpha: 0.85)
              : Colors.black.withValues(alpha: 0.38),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isFocused
                ? const Color(0xFFFFE082)
                : Colors.white.withValues(alpha: 0.18),
          ),
        ),
        child: Text(
          point.label,
          style: TextStyle(
            color: isFocused
                ? Colors.black
                : Colors.white.withValues(alpha: 0.92),
            fontSize: 11,
            fontWeight: isFocused ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControlDock(
    ZenVerseModel activeSim,
    ResponsiveViewport vp,
  ) {
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          _handlePointerScroll(event);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. 6-Simulator Quick Selector Strip (Adaptive FittedBox so all 6 worlds are always visible & clickable)
          SizedBox(
            height: vp.isShortLandscape ? 34 : 40,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: vp.horizontalPadding),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int idx = 0;
                          idx < availableSimulators.length;
                          idx++) ...[
                        if (idx > 0) const SizedBox(width: 8),
                        Builder(
                          builder: (context) {
                            final ZenVerseModel sim = availableSimulators[idx];
                            final bool active = idx == _selectedIndex;
                            return GestureDetector(
                              onTap: () => _animateToSimulator(idx),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 13,
                                  vertical: vp.isShortLandscape ? 4 : 7,
                                ),
                                decoration: BoxDecoration(
                                  gradient: active
                                      ? LinearGradient(
                                          colors: [
                                            sim.themeColors[0],
                                            sim.themeColors[1],
                                          ],
                                        )
                                      : null,
                                  color: active
                                      ? null
                                      : Colors.black.withValues(alpha: 0.48),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: active
                                        ? Colors.white.withValues(alpha: 0.85)
                                        : Colors.white.withValues(alpha: 0.20),
                                    width: active ? 1.5 : 1.0,
                                  ),
                                  boxShadow: active
                                      ? [
                                          BoxShadow(
                                            color: sim.themeColors.first
                                                .withValues(alpha: 0.45),
                                            blurRadius: 12,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${idx + 1}. ${_shortMenuLabel(sim)}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: active
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: vp.isShortLandscape ? 4 : 8),

          // 2. Adaptive, Zero-Overflow Swipeable Simulator Card Carousel
          SizedBox(
            height: vp.menuCarouselHeight,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ScrollConfiguration(
                  behavior: const MaterialScrollBehavior().copyWith(
                    dragDevices: const {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.trackpad,
                      PointerDeviceKind.stylus,
                      PointerDeviceKind.unknown,
                    },
                  ),
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(
                      parent: PageScrollPhysics(),
                    ),
                    itemCount: availableSimulators.length,
                    onPageChanged: (idx) {
                      if (_isAnimatingToPage) return;
                      final ZenVerseModel nextSim = availableSimulators[idx];
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedIndex = idx;
                        _syncPreviewWorldPreferences(nextSim);
                      });
                      StorageService.instance.saveSelectedWorldIndex(idx);
                      AudioService.instance.startAmbientForWorld(
                        nextSim.id,
                        atmosphere: _previewController.atmosphereMode,
                        style: _previewController.styleMode,
                        initialYaw: _previewController.cameraYaw,
                      );
                    },
                    itemBuilder: (context, index) {
                      final ZenVerseModel sim = availableSimulators[index];
                      final bool isSelected = index == _selectedIndex;
                      return AnimatedScale(
                        scale: isSelected ? 1.0 : 0.94,
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        child: _buildSimulatorCard(
                          sim,
                          index,
                          isSelected,
                          vp,
                        ),
                      );
                    },
                  ),
                ),

                // Left Carousel Arrow Button
                if (_selectedIndex > 0)
                  Positioned(
                    left: 12,
                    child: _buildCarouselArrowButton(
                      icon: Icons.chevron_left_rounded,
                      onTap: () => _animateToSimulator(_selectedIndex - 1),
                    ),
                  ),

                // Right Carousel Arrow Button
                if (_selectedIndex < availableSimulators.length - 1)
                  Positioned(
                    right: 12,
                    child: _buildCarouselArrowButton(
                      icon: Icons.chevron_right_rounded,
                      onTap: () => _animateToSimulator(_selectedIndex + 1),
                    ),
                  ),
              ],
            ),
          ),

          SizedBox(height: vp.isShortLandscape ? 4 : 8),

          // 3. Page Dots + Full-Width Primary Launch Button
          Padding(
            padding: EdgeInsets.fromLTRB(
              vp.horizontalPadding,
              0,
              vp.horizontalPadding,
              vp.isShortLandscape ? 6 : 12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(availableSimulators.length, (i) {
                    final bool active = i == _selectedIndex;
                    return GestureDetector(
                      onTap: () => _animateToSimulator(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 28 : 9,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? activeSim.themeColors.first
                              : Colors.white.withValues(alpha: 0.32),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  }),
                ),
                SizedBox(height: vp.isShortLandscape ? 6 : 10),
                GestureDetector(
                  onTap: () => _launchSimulator(activeSim),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: vp.isShortLandscape ? 42 : 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          activeSim.themeColors[0],
                          activeSim.themeColors[1],
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: activeSim.themeColors.first
                              .withValues(alpha: 0.45),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.48),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.play_circle_fill_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                activeSim.actionButtonLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselArrowButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.45),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 12,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildSimulatorCard(
    ZenVerseModel sim,
    int index,
    bool isSelected,
    ResponsiveViewport vp,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (!isSelected) {
          _animateToSimulator(index);
        } else {
          _launchSimulator(sim);
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            padding: EdgeInsets.fromLTRB(
              18,
              vp.isShortLandscape ? 10 : 14,
              18,
              vp.isShortLandscape ? 8 : 12,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  sim.themeColors.first.withValues(alpha: 0.34),
                  Colors.black.withValues(alpha: 0.72),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected
                    ? sim.themeColors.first.withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.18),
                width: isSelected ? 1.8 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 1. Top Row: Status Badge + Environment Name + Quick Launch Pill
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'MOD #${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sim.environmentName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [sim.themeColors[0], sim.themeColors[1]],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'BAŞLAT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(width: 3),
                          Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // 2. Middle Row: Icon + Title + Subtitle + Concise Description
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: vp.isShortLandscape ? 40 : 48,
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [sim.themeColors[0], sim.themeColors[1]],
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: sim.themeColors.first
                                    .withValues(alpha: 0.38),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            sim.icon,
                            color: Colors.white,
                            size: vp.isShortLandscape ? 21 : 25,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  sim.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: vp.isShortLandscape ? 16.0 : 18.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '• ${sim.subtitle}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFFFCC80),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            sim.description,
                            maxLines: vp.isShortLandscape ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.88),
                              fontSize: 12,
                              height: 1.32,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // 3. Bottom Row: Single-line Horizontal Feature Tags + Quote
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 24,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: sim.features.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 6),
                        itemBuilder: (context, fIdx) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.11),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '✦ ${sim.features[fIdx]}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (!vp.isShortLandscape) ...[
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.32),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          sim.quote,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFFFFE0B2)
                                .withValues(alpha: 0.92),
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMusicCreditsDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: const Color(0xFF151A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.library_music_rounded,
                        color: Color(0xFFFFCC80),
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Hakkında & Müzik Lisansları',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Görsel dünyalar ve 360° ortam/etkileşim efekt sesleri ZenVerse motoru tarafından prosedürel olarak üretilmiştir.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.32),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: const SelectableText(
                      '"Bossa Antigua", "Summer Day", "Frost Waltz", "Floating Cities", '
                      '"Ishikari Lore", "Eastern Thought", "Night on the Docks - Sax", '
                      '"Lobby Time", "Desert City", "East of Tunesia", "Silent Night", '
                      '"Dance of the Sugar Plum Fairy"\n'
                      'Kevin MacLeod (incompetech.com)\n'
                      'Licensed under Creative Commons: By Attribution 4.0 License\n'
                      'http://creativecommons.org/licenses/by/4.0/',
                      style: TextStyle(
                        color: Color(0xFFFFE0B2),
                        fontSize: 11.5,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text(
                        'Tamam',
                        style: TextStyle(
                          color: Color(0xFFFFCC80),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
