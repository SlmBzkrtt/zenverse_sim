import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import '../painters/coconut_world_painter.dart';
import 'storage_service.dart';

/// Multi-layered 360° spatial & theme-reactive procedural audio engine.
///
/// Uses two concurrent looping [AudioPlayer] channels plus an SFX channel:
/// 1. **Base World + Atmosphere Player (`_ambientPlayer`)**:
///    Plays a rich, seamless 6-second soundscape tailored to both the active
///    world (`worldId`) and weather/time atmosphere (`CoconutAtmosphereMode`).
/// 2. **360° Directional Landmark Player (`_directionalPlayer`)**:
///    Dynamically switches among 5 directional landmark soundscapes per world
///    as the camera rotates (`cameraYaw` 0°–360°), adjusting stereo balance
///    and proximity volume in real time.
/// 3. **Interaction SFX Player (`_sfxPlayer`)**:
///    Plays world-tuned harmonic chimes and soft UI ticks.
///
/// Note on macOS/iOS (`audioplayers_darwin`): `BytesSource` is unimplemented
/// in `audioplayers_darwin`, so synthesized WAV buffers are cached to
/// [Directory.systemTemp] and played via [DeviceFileSource].
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  AudioPlayer? _ambientPlayer;
  AudioPlayer? _directionalPlayer;
  AudioPlayer? _sfxPlayer;

  String? _currentWorldId;
  CoconutAtmosphereMode _currentAtmosphere = CoconutAtmosphereMode.sunset;
  CoconutStyleMode _currentStyle = CoconutStyleMode.natural;

  String? _activeAmbientKey;
  String? _activeDirectionalKey;
  int _currentDirectionalZone = -1;

  bool _isPausedByLifecycle = false;
  bool _isUpdatingAmbient = false;
  bool _isUpdatingDirectional = false;

  double _lastSpatialYaw = -999.0;
  DateTime _lastSpatialUpdate = DateTime.fromMillisecondsSinceEpoch(0);

  Directory? _tempAudioDir;
  final Map<String, String> _wavFilePathCache = <String, String>{};
  final Map<String, Uint8List> _wavMemoryCache = <String, Uint8List>{};

  bool get isMuted => StorageService.instance.isAudioMuted.value;

  /// Resolves or creates the temporary directory for synthesized WAV files.
  Directory _getTempAudioDir() {
    if (_tempAudioDir != null && _tempAudioDir!.existsSync()) {
      return _tempAudioDir!;
    }
    final Directory dir = Directory(
      '${Directory.systemTemp.path}/zenverse_audio_v2',
    );
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    _tempAudioDir = dir;
    return dir;
  }

  /// Materializes a WAV buffer as a local file and returns a [Source]
  /// compatible with macOS, iOS, and Android.
  Source _getPlayableSource(String cacheKey, Uint8List Function() builder) {
    try {
      final String? existingPath = _wavFilePathCache[cacheKey];
      if (existingPath != null && File(existingPath).existsSync()) {
        return DeviceFileSource(existingPath);
      }
      final Uint8List bytes = _wavMemoryCache.putIfAbsent(cacheKey, builder);
      final Directory dir = _getTempAudioDir();
      final File file = File('${dir.path}/$cacheKey.wav');
      if (!file.existsSync() || file.lengthSync() != bytes.length) {
        file.writeAsBytesSync(bytes, flush: true);
      }
      _wavFilePathCache[cacheKey] = file.path;
      return DeviceFileSource(file.path);
    } catch (_) {
      final Uint8List bytes = _wavMemoryCache.putIfAbsent(cacheKey, builder);
      return BytesSource(bytes, mimeType: 'audio/wav');
    }
  }

  Future<void> toggleMute() async {
    final bool nextMuted = !isMuted;
    await StorageService.instance.setAudioMuted(nextMuted);
    try {
      if (nextMuted) {
        await _ambientPlayer?.setVolume(0.0);
        await _directionalPlayer?.setVolume(0.0);
      } else {
        if (_currentWorldId != null) {
          _activeAmbientKey = null;
          _activeDirectionalKey = null;
          await startAmbientForWorld(
            _currentWorldId!,
            atmosphere: _currentAtmosphere,
            style: _currentStyle,
          );
        }
      }
    } catch (_) {}
  }

  /// Starts or updates the world's base soundscape and 360° directional audio.
  Future<void> startAmbientForWorld(
    String worldId, {
    CoconutAtmosphereMode? atmosphere,
    CoconutStyleMode? style,
    double? initialYaw,
  }) async {
    _currentWorldId = worldId;
    if (atmosphere != null) {
      _currentAtmosphere = atmosphere;
    } else {
      _currentAtmosphere =
          StorageService.instance.loadAtmosphereMode(worldId: worldId);
    }
    if (style != null) {
      _currentStyle = style;
    } else {
      _currentStyle = StorageService.instance.loadStyleMode(worldId: worldId);
    }

    if (isMuted || _isPausedByLifecycle) return;

    final String styleTag =
        _currentStyle == CoconutStyleMode.lofi ? 'lofi' : 'std';
    final String ambientKey =
        'amb_${worldId}_${_currentAtmosphere.name}_$styleTag';

    if (_activeAmbientKey != ambientKey && !_isUpdatingAmbient) {
      _isUpdatingAmbient = true;
      try {
        if (_ambientPlayer == null) {
          final player = AudioPlayer();
          await player.setReleaseMode(ReleaseMode.loop);
          _ambientPlayer = player;
        }
        final Source source = _getPlayableSource(
          ambientKey,
          () => _buildWorldAmbientWav(
            worldId,
            _currentAtmosphere,
            _currentStyle,
          ),
        );
        await _ambientPlayer!.setVolume(0.48);
        await _ambientPlayer!.play(source);
        _activeAmbientKey = ambientKey;
      } catch (_) {
        // Ignore in headless test environments without platform channels
      } finally {
        _isUpdatingAmbient = false;
      }
    }

    // Also prime or update the 360° directional layer
    final double yawToUse =
        initialYaw ?? (_lastSpatialYaw >= 0 ? _lastSpatialYaw : 15.0);
    await _updateDirectionalZoneAudio(
      worldId: worldId,
      yaw: yawToUse,
      forceSwitch: true,
    );
  }

  /// Called from the camera loop / pan handler as the user rotates 360°.
  /// Throttled so platform channels are updated smoothly without frame drops.
  void updateCameraOrientation({
    required double yaw,
    String? worldId,
    bool isMenuPreview = false,
  }) {
    if (isMuted || _isPausedByLifecycle) return;
    final String activeWorld = worldId ?? _currentWorldId ?? 'coconut';
    final double normalizedYaw = ((yaw % 360.0) + 360.0) % 360.0;

    final DateTime now = DateTime.now();
    final double angleDiff = (normalizedYaw - _lastSpatialYaw).abs();
    if (angleDiff < 3.5 &&
        now.difference(_lastSpatialUpdate).inMilliseconds < 180) {
      return;
    }
    if (now.difference(_lastSpatialUpdate).inMilliseconds < 95) {
      return;
    }

    _lastSpatialYaw = normalizedYaw;
    _lastSpatialUpdate = now;

    _updateDirectionalZoneAudio(
      worldId: activeWorld,
      yaw: normalizedYaw,
      isMenuPreview: isMenuPreview,
    );
  }

  Future<void> _updateDirectionalZoneAudio({
    required String worldId,
    required double yaw,
    bool isMenuPreview = false,
    bool forceSwitch = false,
  }) async {
    if (isMuted || _isPausedByLifecycle || _isUpdatingDirectional) return;

    final _DirectionalSpot spot = _resolveClosestSpot(worldId, yaw);
    final String dirKey = 'dir_${worldId}_z${spot.zoneIndex}';

    _isUpdatingDirectional = true;
    try {
      if (_directionalPlayer == null) {
        final player = AudioPlayer();
        await player.setReleaseMode(ReleaseMode.loop);
        _directionalPlayer = player;
      }

      if (forceSwitch ||
          _activeDirectionalKey != dirKey ||
          _currentDirectionalZone != spot.zoneIndex) {
        final Source source = _getPlayableSource(
          dirKey,
          () => _buildDirectionalZoneWav(worldId, spot.zoneIndex),
        );
        _currentDirectionalZone = spot.zoneIndex;
        _activeDirectionalKey = dirKey;
        await _directionalPlayer!.setVolume(spot.volume * (isMenuPreview ? 0.78 : 1.0));
        await _directionalPlayer!.setBalance(spot.pan);
        await _directionalPlayer!.play(source);
      } else {
        await _directionalPlayer!.setVolume(spot.volume * (isMenuPreview ? 0.78 : 1.0));
        await _directionalPlayer!.setBalance(spot.pan);
      }
    } catch (_) {
      // Ignore in headless test environments
    } finally {
      _isUpdatingDirectional = false;
    }
  }

  /// Plays a world-themed harmonic chime when tapping the center object or launching.
  Future<void> playInteractionChime() async {
    if (isMuted || _isPausedByLifecycle) return;
    final String worldId = _currentWorldId ?? 'coconut';
    final String sfxKey = 'sfx_chime_$worldId';
    try {
      if (_sfxPlayer == null) {
        final player = AudioPlayer();
        await player.setReleaseMode(ReleaseMode.stop);
        _sfxPlayer = player;
      }
      final Source source = _getPlayableSource(
        sfxKey,
        () => _buildWorldChimeWav(worldId),
      );
      await _sfxPlayer!.setVolume(0.42);
      await _sfxPlayer!.play(source);
    } catch (_) {}
  }

  Future<void> pauseForLifecycle() async {
    _isPausedByLifecycle = true;
    try {
      await _ambientPlayer?.pause();
      await _directionalPlayer?.pause();
    } catch (_) {}
  }

  Future<void> resumeFromLifecycle() async {
    if (!_isPausedByLifecycle) return;
    _isPausedByLifecycle = false;
    if (isMuted) return;
    try {
      await _ambientPlayer?.resume();
      await _directionalPlayer?.resume();
    } catch (_) {}
  }

  Future<void> stopAmbient() async {
    try {
      await _ambientPlayer?.stop();
      await _directionalPlayer?.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    try {
      await _ambientPlayer?.dispose();
      await _directionalPlayer?.dispose();
      await _sfxPlayer?.dispose();
    } catch (_) {}
    _ambientPlayer = null;
    _directionalPlayer = null;
    _sfxPlayer = null;
  }

  // ---------------------------------------------------------------------------
  // 360° DIRECTIONAL ZONE RESOLUTION
  // ---------------------------------------------------------------------------
  static const List<double> _zoneCenterAngles = [0.0, 74.0, 128.0, 168.0, 235.0];

  _DirectionalSpot _resolveClosestSpot(String worldId, double yaw) {
    int bestZone = 0;
    double bestAbsDiff = 999.0;
    double signedDiffForBest = 0.0;

    for (int i = 0; i < _zoneCenterAngles.length; i++) {
      double diff = (_zoneCenterAngles[i] - yaw) % 360.0;
      if (diff > 180.0) diff -= 360.0;
      if (diff < -180.0) diff += 360.0;
      if (diff.abs() < bestAbsDiff) {
        bestAbsDiff = diff.abs();
        bestZone = i;
        signedDiffForBest = diff;
      }
    }

    // Proximity gain: louder when looking directly at the landmark, softer between zones
    final double proximity = (1.0 - (bestAbsDiff / 65.0)).clamp(0.35, 1.0);
    final double volume = (0.22 + 0.34 * proximity).clamp(0.18, 0.56);
    // Stereo pan: -0.60 (left) to +0.60 (right) relative to camera look direction
    final double pan = (signedDiffForBest / 55.0).clamp(-0.60, 0.60);

    return _DirectionalSpot(
      zoneIndex: bestZone,
      volume: volume,
      pan: pan,
    );
  }

  // ---------------------------------------------------------------------------
  // LAYER 1: WORLD + ATMOSPHERE BASE AMBIENT SYNTHESIZER (6.0s SEAMLESS LOOP)
  // ---------------------------------------------------------------------------
  Uint8List _buildWorldAmbientWav(
    String worldId,
    CoconutAtmosphereMode atmosphere,
    CoconutStyleMode style,
  ) {
    const int sampleRate = 22050;
    const int durationSeconds = 6;
    const int numSamples = sampleRate * durationSeconds;
    final ByteData data = ByteData(44 + numSamples * 2);

    _writeWavHeader(data, sampleRate, numSamples);
    final math.Random rng = math.Random(
      worldId.hashCode ^ (atmosphere.index * 31) ^ (style.index * 7),
    );

    double lpNoise1 = 0.0;
    double lpNoise2 = 0.0;

    // Select chord voicings per world & atmosphere
    final List<double> chordFreqs = _getWorldChordFreqs(worldId, atmosphere);
    final List<double> melodyNotes = _getWorldMelodyNotes(worldId, atmosphere);
    final bool isRainOrSnow = atmosphere == CoconutAtmosphereMode.rain;
    final bool isNight = atmosphere == CoconutAtmosphereMode.night;
    final bool isLoFi = style == CoconutStyleMode.lofi;

    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      final double loopProgress = t / durationSeconds;
      final double loopRad = loopProgress * 2.0 * math.pi;

      // 1. Warm harmonic pad with slow breathing modulation
      final double breath = 0.76 + 0.24 * math.sin(loopRad);
      double pad = 0.0;
      for (int c = 0; c < chordFreqs.length; c++) {
        final double freq = chordFreqs[c];
        final double detune = 1.0 + math.sin(loopRad + c) * (isLoFi ? 0.0022 : 0.0006);
        pad += math.sin(2.0 * math.pi * freq * detune * t + c * 0.9) *
            (0.14 / (1.0 + c * 0.35));
        // Soft sub-octave warmth on root
        if (c == 0) {
          pad += math.sin(2.0 * math.pi * (freq * 0.5) * t) * 0.09;
        }
      }

      // 2. Gentle melodic motif (4 notes across the 6-second loop)
      final int noteSlot = ((loopProgress * 4.0).floor()).clamp(0, 3);
      final double slotPhase = (loopProgress * 4.0) - noteSlot;
      final double noteEnv =
          math.sin(slotPhase * math.pi) * math.exp(-slotPhase * 2.4);
      final double noteFreq = melodyNotes[noteSlot % melodyNotes.length];
      double motif = 0.0;
      if (worldId == 'mossy_rock' || worldId == 'christmas_tree') {
        // Bell / Koto / Music-box pluck overtones
        motif = (math.sin(2.0 * math.pi * noteFreq * t) * 0.11 +
                math.sin(2.0 * math.pi * noteFreq * 2.0 * t) * 0.04) *
            noteEnv;
      } else if (worldId == 'street_lamp') {
        // Warm electric piano / jazz Rhodes tone
        motif = (math.sin(2.0 * math.pi * noteFreq * t) * 0.10 +
                math.sin(2.0 * math.pi * noteFreq * 3.0 * t) * 0.025) *
            noteEnv;
      } else {
        // Soft acoustic / marimba / flute overtone
        motif = math.sin(2.0 * math.pi * noteFreq * t) * 0.09 * noteEnv;
      }

      // 3. Environmental texture (Ocean waves, Alpine wind, Bamboo stream, Rain/Snow)
      final double rawNoise = rng.nextDouble() * 2.0 - 1.0;
      lpNoise1 = lpNoise1 * 0.965 + rawNoise * 0.035;
      lpNoise2 = lpNoise2 * 0.88 + rawNoise * 0.12;

      double envSound = 0.0;
      switch (worldId) {
        case 'coconut':
          // Rolling Pacific ocean surf (two wave crests per 6s loop)
          final double waveCrest =
              0.5 + 0.5 * math.sin(loopRad * 1.0 - 0.6);
          envSound = lpNoise1 * (0.22 + 0.38 * waveCrest) +
              lpNoise2 * (0.06 * waveCrest);
        case 'pine_tree':
          // Soft Nordic alpine breeze + Aurora shimmer in night mode
          final double windGust = 0.5 + 0.5 * math.sin(loopRad * 2.0);
          envSound = lpNoise1 * (isRainOrSnow ? 0.42 : 0.22) * windGust;
          if (isNight) {
            envSound += math.sin(2.0 * math.pi * 880.0 * t + math.sin(loopRad) * 3.0) *
                0.025 *
                windGust;
          }
        case 'mossy_rock':
          // Trickling Zen garden brook + night crickets
          envSound = lpNoise2 * 0.14;
          if (isNight) {
            final double cricketEnv =
                math.max(0.0, math.sin(loopRad * 6.0)) * 0.03;
            envSound += math.sin(2.0 * math.pi * 3800.0 * t) * cricketEnv;
          }
        case 'street_lamp':
          // Evening city hush + warm vinyl crackle in Lo-Fi / Rain
          envSound = lpNoise1 * 0.12;
        case 'desert_cactus':
          // Warm canyon breeze sweeping across sandstone
          final double desertBreeze = 0.45 + 0.55 * math.sin(loopRad);
          envSound = lpNoise1 * 0.24 * desertBreeze;
        case 'christmas_tree':
          // Festive sleigh shimmer & winter air
          final double bellShimmer =
              (0.5 + 0.5 * math.sin(loopRad * 8.0)) * 0.025;
          envSound = lpNoise1 * 0.14 +
              math.sin(2.0 * math.pi * 2637.0 * t) * bellShimmer;
      }

      // Weather overlay: Rain / Snowfall patter
      if (isRainOrSnow) {
        final double droplet = (rng.nextDouble() > 0.992) ? 0.18 : 0.0;
        envSound += lpNoise2 * 0.22 + droplet;
      }

      // Lo-Fi warm vinyl dust texture
      if (isLoFi && rng.nextDouble() > 0.996) {
        envSound += (rng.nextDouble() * 2.0 - 1.0) * 0.09;
      }

      final double combined = ((pad * breath) + motif + envSound) * 0.85;
      final double clamped = combined.clamp(-0.92, 0.92);
      final int pcm16 = (clamped * 32767.0).round().clamp(-32768, 32767);
      data.setInt16(44 + i * 2, pcm16, Endian.little);
    }

    _applySeamlessLoopCrossfade(data, numSamples, sampleRate);
    return data.buffer.asUint8List();
  }

  // ---------------------------------------------------------------------------
  // LAYER 2: 360° DIRECTIONAL LANDMARK SYNTHESIZER (4.0s SEAMLESS LOOP)
  // ---------------------------------------------------------------------------
  Uint8List _buildDirectionalZoneWav(String worldId, int zoneIndex) {
    const int sampleRate = 22050;
    const int durationSeconds = 4;
    const int numSamples = sampleRate * durationSeconds;
    final ByteData data = ByteData(44 + numSamples * 2);

    _writeWavHeader(data, sampleRate, numSamples);
    final math.Random rng = math.Random(worldId.hashCode ^ (zoneIndex * 131));
    double filterA = 0.0;
    double filterB = 0.0;

    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      final double loopProgress = t / durationSeconds;
      final double loopRad = loopProgress * 2.0 * math.pi;
      final double white = rng.nextDouble() * 2.0 - 1.0;
      filterA = filterA * 0.95 + white * 0.05;
      filterB = filterB * 0.82 + white * 0.18;

      double sample = 0.0;

      switch (worldId) {
        case 'coconut':
          sample = _synthCoconutZone(zoneIndex, t, loopProgress, loopRad, filterA, filterB, rng);
        case 'pine_tree':
          sample = _synthPineTreeZone(zoneIndex, t, loopProgress, loopRad, filterA, filterB, rng);
        case 'mossy_rock':
          sample = _synthMossyRockZone(zoneIndex, t, loopProgress, loopRad, filterA, filterB, rng);
        case 'street_lamp':
          sample = _synthStreetLampZone(zoneIndex, t, loopProgress, loopRad, filterA, filterB, rng);
        case 'desert_cactus':
          sample = _synthDesertCactusZone(zoneIndex, t, loopProgress, loopRad, filterA, filterB, rng);
        case 'christmas_tree':
          sample = _synthChristmasTreeZone(zoneIndex, t, loopProgress, loopRad, filterA, filterB, rng);
        default:
          sample = _synthCoconutZone(zoneIndex, t, loopProgress, loopRad, filterA, filterB, rng);
      }

      final int pcm16 =
          (sample.clamp(-0.90, 0.90) * 32767.0).round().clamp(-32768, 32767);
      data.setInt16(44 + i * 2, pcm16, Endian.little);
    }

    _applySeamlessLoopCrossfade(data, numSamples, sampleRate);
    return data.buffer.asUint8List();
  }

  /// World 1 (`coconut`) 360° Directional Zones:
  /// 0 (0°): Ocean Sunset & Seagulls | 1 (74°): Wooden Pier & Boats
  /// 2 (128°): Beach Village & Wind Chimes | 3 (168°): Campfire & Acoustic Guitar
  /// 4 (235°): Tiki Bar Marimba & Lighthouse
  double _synthCoconutZone(
    int zone,
    double t,
    double p,
    double rad,
    double lpSlow,
    double lpFast,
    math.Random rng,
  ) {
    switch (zone) {
      case 0: // 🌅 Ocean waves + distant seagull call
        final double surf = (0.4 + 0.6 * math.sin(rad)) * lpSlow * 0.55;
        final double gullWindow = (p > 0.30 && p < 0.48)
            ? math.sin(((p - 0.30) / 0.18) * math.pi)
            : 0.0;
        final double gullFreq = 1480.0 - 320.0 * ((p - 0.30) / 0.18);
        final double gull =
            math.sin(2.0 * math.pi * gullFreq * t) * gullWindow * 0.08;
        return surf + gull;
      case 1: // 🌉 Wooden pier water lapping & boat mast chime
        final double lap =
            math.max(0.0, math.sin(rad * 3.0)) * lpFast * 0.32;
        final double mastBell = math.sin(2.0 * math.pi * 1046.5 * t) *
            math.exp(-((t % 2.0) * 5.0)) *
            0.09;
        return lap + mastBell;
      case 2: // 🏡 Beach village veranda bamboo/shell wind chimes
        const List<double> chimeNotes = [587.33, 659.25, 783.99, 880.0, 1046.5];
        final int idx = ((t * 2.5).floor()) % chimeNotes.length;
        final double localT = (t * 2.5) % 1.0;
        final double chime = math.sin(2.0 * math.pi * chimeNotes[idx] * t) *
            math.exp(-localT * 4.5) *
            0.16;
        return chime + lpSlow * 0.15;
      case 3: // 🔥 Crackling campfire + 7 friends acoustic guitar strumming
        const List<double> guitarNotes = [196.0, 246.94, 293.66, 392.0, 329.63, 293.66, 246.94, 196.0];
        final int step = ((t * 2.0).floor()) % guitarNotes.length;
        final double pluckT = (t * 2.0) % 1.0;
        final double f = guitarNotes[step];
        final double guitar = (math.sin(2.0 * math.pi * f * t) * 0.20 +
                math.sin(2.0 * math.pi * f * 2.0 * t) * 0.09 +
                math.sin(2.0 * math.pi * f * 3.0 * t) * 0.04) *
            math.exp(-pluckT * 4.2);
        final double fireCrackle =
            (rng.nextDouble() > 0.985 ? 0.22 : 0.0) + lpFast * 0.12;
        return guitar + fireCrackle;
      default: // 🍹 Tiki Bar upbeat island marimba groove
        const List<double> tikiNotes = [293.66, 369.99, 440.0, 587.33, 440.0, 369.99, 329.63, 293.66];
        final int step = ((t * 4.0).floor()) % tikiNotes.length;
        final double beatT = (t * 4.0) % 1.0;
        final double f = tikiNotes[step];
        final double marimba = (math.sin(2.0 * math.pi * f * t) * 0.22 +
                math.sin(2.0 * math.pi * f * 4.0 * t) * 0.05) *
            math.exp(-beatT * 7.5);
        return marimba + lpSlow * 0.10;
    }
  }

  /// World 2 (`pine_tree`) 360° Directional Zones:
  /// 0 (0°): Viaduct Polar Express Steam Train | 1 (74°): Stavkirke & Steaming Hot Tub
  /// 2 (128°): Ski Slope & Watermill | 3 (168°): Husky Campfire & Waterfall
  /// 4 (235°): Reindeer Sleigh Bells & Cable Car
  double _synthPineTreeZone(
    int zone,
    double t,
    double p,
    double rad,
    double lpSlow,
    double lpFast,
    math.Random rng,
  ) {
    switch (zone) {
      case 0: // 🚂 Polar Express steam chug rhythm + distant train whistle
        final double chugBeat = (t * 4.0) % 1.0;
        final double chug = lpFast * math.exp(-chugBeat * 6.0) * 0.45;
        final double whistleEnv = (p > 0.55 && p < 0.82)
            ? math.sin(((p - 0.55) / 0.27) * math.pi)
            : 0.0;
        final double whistle = (math.sin(2.0 * math.pi * 349.23 * t) * 0.10 +
                math.sin(2.0 * math.pi * 440.0 * t) * 0.09 +
                math.sin(2.0 * math.pi * 523.25 * t) * 0.07) *
            whistleEnv;
        return chug + whistle;
      case 1: // ⛪ Stavkirke wooden sanctuary bell + bubbling hot tub
        final double bellEnv = math.exp(-((t % 2.0) * 2.6));
        final double churchBell = (math.sin(2.0 * math.pi * 261.63 * t) * 0.18 +
                math.sin(2.0 * math.pi * 523.25 * t) * 0.07) *
            bellEnv;
        final double bubbles =
            lpSlow * (0.25 + 0.20 * math.sin(rad * 14.0));
        return churchBell + bubbles;
      case 2: // ⛷️ Ski carving swoosh on snow + wooden watermill rhythm
        final double skiSwoosh =
            math.max(0.0, math.sin(rad * 2.0)) * lpFast * 0.36;
        final double wheelPulse = math.sin(2.0 * math.pi * 196.0 * t) *
            (0.5 + 0.5 * math.sin(rad * 4.0)) *
            0.10;
        return skiSwoosh + wheelPulse;
      case 3: // 🛷 Laponia campfire crackle + glacier waterfall rush
        final double crackle =
            (rng.nextDouble() > 0.984 ? 0.24 : 0.0) + lpFast * 0.28;
        final double nordicHarp =
            math.sin(2.0 * math.pi * 349.23 * t) *
                math.exp(-((t % 1.0) * 4.0)) *
                0.14;
        return crackle + nordicHarp;
      default: // 🦌 Reindeer sleigh jingle bells & cable car hum
        final double jingleBeat = (t * 6.0) % 1.0;
        final double sleighBells = (math.sin(2.0 * math.pi * 2093.0 * t) * 0.10 +
                math.sin(2.0 * math.pi * 2637.0 * t) * 0.08) *
            math.exp(-jingleBeat * 8.0);
        final double cableHum = math.sin(2.0 * math.pi * 130.81 * t) * 0.10;
        return sleighBells + cableHum + lpSlow * 0.12;
    }
  }

  /// World 3 (`mossy_rock`) 360° Directional Zones:
  /// 0 (0°): Lake Torii & Kakei Water Drip | 1 (74°): Bridge & Koto Melody
  /// 2 (128°): Pagoda Furin Chime & Shishi-odoshi | 3 (168°): Steaming Onsen
  /// 4 (235°): Bamboo Forest & Deep Bonsho Temple Bell
  double _synthMossyRockZone(
    int zone,
    double t,
    double p,
    double rad,
    double lpSlow,
    double lpFast,
    math.Random rng,
  ) {
    switch (zone) {
      case 0: // ⛩️ Bamboo Kakei water droplet plink + calm lake ripple
        final double dripT = t % 1.0;
        final double dripFreq = 780.0 + 420.0 * math.exp(-dripT * 18.0);
        final double waterDrop = math.sin(2.0 * math.pi * dripFreq * t) *
            math.exp(-dripT * 11.0) *
            0.24;
        return waterDrop + lpSlow * 0.16;
      case 1: // 🌸 Traditional Japanese Koto pentatonic arpeggio
        const List<double> koto = [293.66, 329.63, 392.0, 440.0, 587.33, 440.0, 392.0, 329.63];
        final int idx = ((t * 2.0).floor()) % koto.length;
        final double pluckT = (t * 2.0) % 1.0;
        final double f = koto[idx];
        final double kotoSound = (math.sin(2.0 * math.pi * f * t) * 0.22 +
                math.sin(2.0 * math.pi * f * 2.0 * t) * 0.08) *
            math.exp(-pluckT * 5.0);
        return kotoSound;
      case 2: // 🍵 Shishi-odoshi bamboo clack + Furin glass wind chime
        final double clackT = t % 2.0;
        final double bambooClack = (math.sin(2.0 * math.pi * 420.0 * t) * 0.28 +
                math.sin(2.0 * math.pi * 680.0 * t) * 0.16) *
            math.exp(-clackT * 22.0);
        final double furinT = (t + 0.7) % 1.0;
        final double furin = math.sin(2.0 * math.pi * 1760.0 * t) *
            math.exp(-furinT * 6.5) *
            0.11;
        return bambooClack + furin;
      case 3: // ♨️ Steaming Onsen hot spring water + evening frog/cricket trill
        final double springStream =
            lpSlow * 0.28 + lpFast * (0.14 + 0.08 * math.sin(rad * 6.0));
        final double shakuhachi =
            math.sin(2.0 * math.pi * 293.66 * t + math.sin(rad) * 0.4) *
                (0.5 + 0.5 * math.sin(rad)) *
                0.11;
        return springStream + shakuhachi;
      default: // 🎍 Deep bronze Bonsho temple bell + bamboo grove rustle
        final double bellT = t % 4.0;
        final double bonsho = (math.sin(2.0 * math.pi * 110.0 * t) * 0.26 +
                math.sin(2.0 * math.pi * 220.0 * t) * 0.14 +
                math.sin(2.0 * math.pi * 329.63 * t) * 0.07) *
            math.exp(-bellT * 1.1);
        return bonsho + lpFast * 0.12;
    }
  }

  /// World 4 (`street_lamp`) 360° Directional Zones:
  /// 0 (0°): Vintage Tram Bell & River Bridge | 1 (74°): Fountain & Street Trio
  /// 2 (128°): Café de Nuit Saxophonist | 3 (168°): Jazz Club Walking Bass
  /// 4 (235°): Carousel Music Box & Clock Tower Chime
  double _synthStreetLampZone(
    int zone,
    double t,
    double p,
    double rad,
    double lpSlow,
    double lpFast,
    math.Random rng,
  ) {
    switch (zone) {
      case 0: // 🚋 Vintage yellow tram double-bell "ding-ding!" + river water
        final double dingT = t % 2.0;
        double tramBell = 0.0;
        if (dingT < 0.25) {
          tramBell = math.sin(2.0 * math.pi * 1318.5 * t) *
              math.exp(-dingT * 16.0) *
              0.24;
        } else if (dingT >= 0.28 && dingT < 0.65) {
          tramBell = math.sin(2.0 * math.pi * 1568.0 * t) *
              math.exp(-(dingT - 0.28) * 14.0) *
              0.24;
        }
        return tramBell + lpSlow * 0.20;
      case 1: // 🎻 Plaza stone fountain water + Parisian accordion waltz
        const List<double> waltz = [220.0, 261.63, 329.63, 293.66, 246.94, 196.0];
        final int step = ((t * 1.5).floor()) % waltz.length;
        final double f = waltz[step];
        final double vibrato = 1.0 + math.sin(2.0 * math.pi * 5.5 * t) * 0.004;
        final double accordion = (math.sin(2.0 * math.pi * f * vibrato * t) * 0.14 +
                math.sin(2.0 * math.pi * f * 2.0 * vibrato * t) * 0.07) *
            0.9;
        return accordion + lpFast * 0.18;
      case 2: // ☕ Café de Nuit smooth solo saxophone melody
        const List<double> saxNotes = [293.66, 329.63, 392.0, 493.88, 440.0, 392.0, 329.63, 246.94];
        final int step = ((t * 2.0).floor()) % saxNotes.length;
        final double noteT = (t * 2.0) % 1.0;
        final double f = saxNotes[step];
        final double vib = 1.0 + math.sin(2.0 * math.pi * 5.0 * t) * 0.005;
        final double env = math.sin(noteT * math.pi);
        final double sax = (math.sin(2.0 * math.pi * f * vib * t) * 0.18 +
                math.sin(2.0 * math.pi * f * 2.0 * vib * t) * 0.10 +
                math.sin(2.0 * math.pi * f * 3.0 * vib * t) * 0.05) *
            env;
        return sax;
      case 3: // 🎷 Le Chat Noir Jazz Club walking upright bass & Rhodes chord
        const List<double> bassLine = [82.41, 98.0, 110.0, 123.47, 146.83, 123.47, 110.0, 98.0];
        final int step = ((t * 2.0).floor()) % bassLine.length;
        final double pluckT = (t * 2.0) % 1.0;
        final double bf = bassLine[step];
        final double bass = (math.sin(2.0 * math.pi * bf * t) * 0.26 +
                math.sin(2.0 * math.pi * bf * 2.0 * t) * 0.12) *
            math.exp(-pluckT * 3.8);
        return bass + lpSlow * 0.08;
      default: // 🕰️ Illuminated Carousel music box waltz & clock tower chime
        const List<double> boxNotes = [523.25, 659.25, 783.99, 1046.5, 987.77, 783.99, 659.25, 587.33];
        final int step = ((t * 2.0).floor()) % boxNotes.length;
        final double localT = (t * 2.0) % 1.0;
        final double f = boxNotes[step];
        final double musicBox = (math.sin(2.0 * math.pi * f * t) * 0.18 +
                math.sin(2.0 * math.pi * f * 2.0 * t) * 0.05) *
            math.exp(-localT * 5.5);
        return musicBox;
    }
  }

  /// World 5 (`desert_cactus`) 360° Directional Zones:
  /// 0 (15°): Hot Air Balloons & Canyon Steam Train | 1 (74°): Oasis Waterfall & Caravan
  /// 2 (122°): Petra Treasury & Bazaar Chimes | 3 (165°): Bedouin Fire & Oud Melody
  /// 4 (230°): Windmill & Cosmic Observatory
  double _synthDesertCactusZone(
    int zone,
    double t,
    double p,
    double rad,
    double lpSlow,
    double lpFast,
    math.Random rng,
  ) {
    switch (zone) {
      case 0: // 🚂 Balloon burner flame whoosh + Wild West canyon steam train
        final double burnerWhoosh =
            (p < 0.35 ? math.sin((p / 0.35) * math.pi) : 0.0) * lpFast * 0.45;
        final double trainChug =
            lpSlow * (0.25 + 0.25 * math.sin(rad * 8.0));
        return burnerWhoosh + trainChug;
      case 1: // 🐪 Canyon waterfall splash + camel caravan brass bells
        const List<double> bellNotes = [587.33, 739.99, 880.0, 587.33];
        final int idx = ((t * 2.0).floor()) % bellNotes.length;
        final double localT = (t * 2.0) % 1.0;
        final double caravanBell =
            math.sin(2.0 * math.pi * bellNotes[idx] * t) *
                math.exp(-localT * 6.0) *
                0.15;
        return caravanBell + lpFast * 0.25;
      case 2: // 🏛️ Petra sandstone resonance & Eastern bazaar copper chimes
        const List<double> hijaz = [293.66, 311.13, 369.99, 392.0, 440.0, 392.0, 369.99, 311.13];
        final int idx = ((t * 2.0).floor()) % hijaz.length;
        final double localT = (t * 2.0) % 1.0;
        final double f = hijaz[idx];
        final double bazaar = (math.sin(2.0 * math.pi * f * t) * 0.18 +
                math.sin(2.0 * math.pi * f * 2.0 * t) * 0.07) *
            math.exp(-localT * 4.2);
        return bazaar;
      case 3: // 🔥 Bedouin campfire crackle & acoustic Oud melody
        const List<double> oudNotes = [146.83, 220.0, 233.08, 277.18, 293.66, 277.18, 233.08, 220.0];
        final int idx = ((t * 2.0).floor()) % oudNotes.length;
        final double pluckT = (t * 2.0) % 1.0;
        final double f = oudNotes[idx];
        final double oud = (math.sin(2.0 * math.pi * f * t) * 0.22 +
                math.sin(2.0 * math.pi * f * 2.0 * t) * 0.10 +
                math.sin(2.0 * math.pi * f * 3.0 * t) * 0.05) *
            math.exp(-pluckT * 4.5);
        final double fire = (rng.nextDouble() > 0.985 ? 0.20 : 0.0) + lpFast * 0.10;
        return oud + fire;
      default: // 🔭 Spinning wooden windmill & starry observatory harmonic pad
        final double cosmic = (math.sin(2.0 * math.pi * 220.0 * t) * 0.12 +
                math.sin(2.0 * math.pi * 329.63 * t) * 0.10 +
                math.sin(2.0 * math.pi * 493.88 * t) * 0.08) *
            (0.65 + 0.35 * math.sin(rad));
        return cosmic + lpSlow * 0.14;
    }
  }

  /// World 6 (`christmas_tree`) 360° Directional Zones:
  /// 0 (0°): Cologne Cathedral Bells & Choir | 1 (72°): Heumarkt Ice Rink Waltz
  /// 2 (128°): Christmas Pyramid & Glühwein Market | 3 (176°): Ferris Wheel & Grill
  /// 4 (252°): Rhine River & Hohenzollern Bridge ICE Train
  double _synthChristmasTreeZone(
    int zone,
    double t,
    double p,
    double rad,
    double lpSlow,
    double lpFast,
    math.Random rng,
  ) {
    switch (zone) {
      case 0: // ⛪ Kölner Dom Cathedral deep tolling bell + choir pad
        final double tollT = t % 2.0;
        final double cathedralBell = (math.sin(2.0 * math.pi * 196.0 * t) * 0.22 +
                math.sin(2.0 * math.pi * 392.0 * t) * 0.12 +
                math.sin(2.0 * math.pi * 587.33 * t) * 0.06) *
            math.exp(-tollT * 1.8);
        final double choir = (math.sin(2.0 * math.pi * 261.63 * t) * 0.08 +
                math.sin(2.0 * math.pi * 329.63 * t) * 0.07) *
            (0.6 + 0.4 * math.sin(rad));
        return cathedralBell + choir;
      case 1: // ⛸️ Heumarkt Ice Rink celesta waltz + skate blade glide
        const List<double> rinkNotes = [523.25, 659.25, 783.99, 659.25, 587.33, 783.99, 659.25, 523.25];
        final int step = ((t * 2.0).floor()) % rinkNotes.length;
        final double localT = (t * 2.0) % 1.0;
        final double f = rinkNotes[step];
        final double celesta = (math.sin(2.0 * math.pi * f * t) * 0.18 +
                math.sin(2.0 * math.pi * f * 2.0 * t) * 0.05) *
            math.exp(-localT * 5.2);
        return celesta + lpFast * 0.12;
      case 2: // 🎄 Spinning Christmas Pyramid chimes & warm market carol
        const List<double> carol = [392.0, 440.0, 392.0, 329.63, 523.25, 493.88, 440.0, 392.0];
        final int step = ((t * 2.0).floor()) % carol.length;
        final double localT = (t * 2.0) % 1.0;
        final double f = carol[step];
        final double chime = (math.sin(2.0 * math.pi * f * t) * 0.20 +
                math.sin(2.0 * math.pi * f * 3.0 * t) * 0.05) *
            math.exp(-localT * 4.5);
        return chime;
      case 3: // 🎡 Schwenkgrill charcoal sizzle & fairground organ
        const List<double> organNotes = [261.63, 329.63, 392.0, 523.25, 392.0, 329.63];
        final int step = ((t * 1.5).floor()) % organNotes.length;
        final double f = organNotes[step];
        final double organ = (math.sin(2.0 * math.pi * f * t) * 0.14 +
                math.sin(2.0 * math.pi * f * 2.0 * t) * 0.07) *
            0.85;
        final double sizzle = lpFast * 0.18 + (rng.nextDouble() > 0.985 ? 0.14 : 0.0);
        return organ + sizzle;
      default: // 🌉 Rhine River water flow & Hohenzollern Bridge train hum
        final double rhineWater = lpSlow * 0.28;
        final double trainDrone = (math.sin(2.0 * math.pi * 110.0 * t) * 0.12 +
                math.sin(2.0 * math.pi * 164.81 * t) * 0.08) *
            (0.5 + 0.5 * math.sin(rad));
        return rhineWater + trainDrone;
    }
  }

  // ---------------------------------------------------------------------------
  // LAYER 3: WORLD-THEMED OBJECT INTERACTION CHIME (340ms)
  // ---------------------------------------------------------------------------
  Uint8List _buildWorldChimeWav(String worldId) {
    const int sampleRate = 22050;
    const int numSamples = 7500; // ~340ms
    final ByteData data = ByteData(44 + numSamples * 2);
    _writeWavHeader(data, sampleRate, numSamples);

    final List<double> freqs = switch (worldId) {
      'coconut' => const [392.0, 587.33, 783.99], // Tropical G5 marimba chord
      'pine_tree' => const [523.25, 659.25, 1046.5], // Crystalline Nordic C6
      'mossy_rock' => const [440.0, 659.25, 880.0], // Zen temple bell A5
      'street_lamp' => const [329.63, 493.88, 659.25], // Warm Jazz Em9 chime
      'desert_cactus' => const [293.66, 440.0, 587.33], // Desert Oud D5 harmonic
      'christmas_tree' => const [523.25, 783.99, 1318.5], // Festive sparkle E6
      _ => const [528.0, 792.0, 1056.0],
    };

    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      final double env = math.exp(-t * 11.5);
      final double signal = (math.sin(2.0 * math.pi * freqs[0] * t) * 0.42 +
              math.sin(2.0 * math.pi * freqs[1] * t) * 0.28 +
              math.sin(2.0 * math.pi * freqs[2] * t) * 0.16) *
          env;
      final int pcm16 = (signal * 32767.0).round().clamp(-32768, 32767);
      data.setInt16(44 + i * 2, pcm16, Endian.little);
    }

    return data.buffer.asUint8List();
  }

  List<double> _getWorldChordFreqs(
    String worldId,
    CoconutAtmosphereMode atmosphere,
  ) {
    final double shift = switch (atmosphere) {
      CoconutAtmosphereMode.sunset => 1.0,
      CoconutAtmosphereMode.night => 0.8909, // 2 semitones lower, deeper & calmer
      CoconutAtmosphereMode.noon => 1.0595, // 1 semitone brighter
      CoconutAtmosphereMode.rain => 0.9439, // Mellow minor/lo-fi warmth
    };

    final List<double> base = switch (worldId) {
      'coconut' => const [196.0, 246.94, 293.66, 369.99], // Gmaj7
      'pine_tree' => const [174.61, 220.0, 261.63, 329.63], // Fmaj7
      'mossy_rock' => const [220.0, 261.63, 329.63, 392.0], // Am7 Pentatonic
      'street_lamp' => const [164.81, 196.0, 246.94, 293.66], // Em7 Noir Jazz
      'desert_cactus' => const [146.83, 220.0, 277.18, 329.63], // Dadd9 Canyon
      'christmas_tree' => const [261.63, 329.63, 392.0, 493.88], // Festive Cmaj7
      _ => const [220.0, 277.18, 329.63],
    };

    return base.map((f) => f * shift).toList(growable: false);
  }

  List<double> _getWorldMelodyNotes(
    String worldId,
    CoconutAtmosphereMode atmosphere,
  ) {
    final double shift =
        atmosphere == CoconutAtmosphereMode.night ? 0.8909 : 1.0;
    final List<double> base = switch (worldId) {
      'coconut' => const [392.0, 493.88, 587.33, 493.88],
      'pine_tree' => const [349.23, 440.0, 523.25, 659.25],
      'mossy_rock' => const [440.0, 523.25, 659.25, 587.33],
      'street_lamp' => const [329.63, 392.0, 493.88, 440.0],
      'desert_cactus' => const [293.66, 369.99, 440.0, 329.63],
      'christmas_tree' => const [523.25, 659.25, 783.99, 659.25],
      _ => const [440.0, 523.25, 659.25, 523.25],
    };
    return base.map((f) => f * shift).toList(growable: false);
  }

  /// Smooths the first and last 60ms of the WAV buffer so looping has zero click.
  void _applySeamlessLoopCrossfade(
    ByteData data,
    int numSamples,
    int sampleRate,
  ) {
    final int fadeSamples = (sampleRate * 0.06).round();
    for (int i = 0; i < fadeSamples && i < numSamples ~/ 2; i++) {
      final double fadeIn = 0.5 - 0.5 * math.cos((i / fadeSamples) * math.pi);
      final int startIdx = 44 + i * 2;
      final int endIdx = 44 + (numSamples - 1 - i) * 2;

      final int sStart = data.getInt16(startIdx, Endian.little);
      final int sEnd = data.getInt16(endIdx, Endian.little);

      data.setInt16(startIdx, (sStart * fadeIn).round(), Endian.little);
      data.setInt16(endIdx, (sEnd * fadeIn).round(), Endian.little);
    }
  }

  void _writeWavHeader(ByteData data, int sampleRate, int numSamples) {
    final int dataByteSize = numSamples * 2;
    const List<int> riff = [0x52, 0x49, 0x46, 0x46]; // "RIFF"
    const List<int> wave = [0x57, 0x41, 0x56, 0x45]; // "WAVE"
    const List<int> fmt = [0x66, 0x6D, 0x74, 0x20]; // "fmt "
    const List<int> dataTag = [0x64, 0x61, 0x74, 0x61]; // "data"

    for (int i = 0; i < 4; i++) {
      data.setUint8(i, riff[i]);
      data.setUint8(8 + i, wave[i]);
      data.setUint8(12 + i, fmt[i]);
      data.setUint8(36 + i, dataTag[i]);
    }
    data.setUint32(4, 36 + dataByteSize, Endian.little);
    data.setUint32(16, 16, Endian.little); // PCM chunk size
    data.setUint16(20, 1, Endian.little); // AudioFormat = 1 (PCM)
    data.setUint16(22, 1, Endian.little); // NumChannels = 1 (Mono)
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, sampleRate * 2, Endian.little); // ByteRate
    data.setUint16(32, 2, Endian.little); // BlockAlign
    data.setUint16(34, 16, Endian.little); // BitsPerSample
    data.setUint32(40, dataByteSize, Endian.little);
  }
}

class _DirectionalSpot {
  final int zoneIndex;
  final double volume;
  final double pan;

  const _DirectionalSpot({
    required this.zoneIndex,
    required this.volume,
    required this.pan,
  });
}
