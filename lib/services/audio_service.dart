import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import '../painters/coconut_world_painter.dart';
import 'storage_service.dart';

/// Multi-layered audio engine for ZenVerse: Chill Object Sim.
///
/// Combines:
/// 1. **Full-Length Studio Theme Music Playlist (`_musicPlayer` at ~72% volume)**:
///    Each of the 6 worlds has 2 full-length instrumental tracks stored in
///    `assets/music/<worldId>_1.m4a` and `assets/music/<worldId>_2.m4a`
///    (Tropical Bossa/Chill, Nordic Winter Waltz/Aurora, Japanese Shakuhachi/Koto,
///    European Night Saxophone/Jazz, Desert Oud/Mirage, Christmas Silent Night/Celesta).
///    Tracks play back-to-back in an endless 2-song playlist per world.
/// 2. **Subtle 360° Directional Environmental Layer (`_directionalPlayer` at 8%–14% volume)**:
///    Adds gentle, non-intrusive spatial color (soft waves, crackling fire, water
///    drips, distant bells, breeze) at 10%–15% volume with stereo panning as the
///    user rotates 360° around the world.
/// 3. **Soft Interaction SFX (`_sfxPlayer`)**:
///    Plays a gentle harmonic chime on object tap.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  AudioPlayer? _musicPlayer;
  AudioPlayer? _directionalPlayer;
  AudioPlayer? _sfxPlayer;
  StreamSubscription<void>? _musicCompleteSub;

  String? _currentWorldId;
  int _currentTrackIndex = 0; // 0 or 1 (2 full songs per world)
  String? _activeMusicAsset;

  CoconutAtmosphereMode _currentAtmosphere = CoconutAtmosphereMode.sunset;
  CoconutStyleMode _currentStyle = CoconutStyleMode.natural;

  String? _activeDirectionalKey;
  int _currentDirectionalZone = -1;

  bool _isPausedByLifecycle = false;
  bool _isUpdatingMusic = false;
  bool _isUpdatingDirectional = false;

  double _lastSpatialYaw = -999.0;
  DateTime _lastSpatialUpdate = DateTime.fromMillisecondsSinceEpoch(0);

  Directory? _tempAudioDir;
  final Map<String, String> _wavFilePathCache = <String, String>{};
  final Map<String, Uint8List> _wavMemoryCache = <String, Uint8List>{};

  /// 2 full-length music tracks per world inside `assets/music/`.
  static const Map<String, List<String>> _worldMusicPlaylists = {
    'coconut': [
      'music/coconut_1.m4a', // Bossa Antigua (Tropical Beach Bossa Nova)
      'music/coconut_2.m4a', // Port Horizon (Calm Ocean Sunset Chill)
    ],
    'pine_tree': [
      'music/pine_tree_1.m4a', // Frost Waltz (Snowy Nordic Waltz)
      'music/pine_tree_2.m4a', // Floating Cities (Aurora Borealis Ambient)
    ],
    'mossy_rock': [
      'music/mossy_rock_1.m4a', // Ishikari Lore (Japanese Shakuhachi & Koto)
      'music/mossy_rock_2.m4a', // Eastern Thought (Kyoto Zen Temple Meditation)
    ],
    'street_lamp': [
      'music/street_lamp_1.m4a', // Night on the Docks - Sax (Night Jazz Saxophone)
      'music/street_lamp_2.m4a', // Lobby Time (European Café Lounge Jazz)
    ],
    'desert_cactus': [
      'music/desert_cactus_1.m4a', // Desert City (Middle Eastern Oud & Caravan)
      'music/desert_cactus_2.m4a', // East of Tunesia (Oasis & Canyon Mirage)
    ],
    'christmas_tree': [
      'music/christmas_tree_1.m4a', // Silent Night / Stille Nacht (Instrumental)
      'music/christmas_tree_2.m4a', // Dance of the Sugar Plum Fairy (Christmas Market)
    ],
  };

  bool get isMuted => StorageService.instance.isAudioMuted.value;

  Directory _getTempAudioDir() {
    if (_tempAudioDir != null && _tempAudioDir!.existsSync()) {
      return _tempAudioDir!;
    }
    final Directory dir = Directory(
      '${Directory.systemTemp.path}/zenverse_audio_v3',
    );
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    _tempAudioDir = dir;
    return dir;
  }

  Source _getPlayableWavSource(String cacheKey, Uint8List Function() builder) {
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
        await _musicPlayer?.setVolume(0.0);
        await _directionalPlayer?.setVolume(0.0);
      } else {
        if (_currentWorldId != null) {
          _activeMusicAsset = null;
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

  /// Starts or updates the world's full-length background music playlist
  /// and primes the subtle (10%–14%) 360° directional ambient layer.
  Future<void> startAmbientForWorld(
    String worldId, {
    CoconutAtmosphereMode? atmosphere,
    CoconutStyleMode? style,
    double? initialYaw,
  }) async {
    final bool worldChanged = _currentWorldId != worldId;
    final CoconutAtmosphereMode nextAtmosphere = atmosphere ??
        StorageService.instance.loadAtmosphereMode(worldId: worldId);
    final bool atmosphereChanged = _currentAtmosphere != nextAtmosphere;

    _currentWorldId = worldId;
    _currentAtmosphere = nextAtmosphere;
    _currentStyle =
        style ?? StorageService.instance.loadStyleMode(worldId: worldId);

    if (worldChanged) {
      // Pick initial track based on atmosphere (Sunset/Noon -> Track 1, Night/Rain -> Track 2)
      _currentTrackIndex = (_currentAtmosphere == CoconutAtmosphereMode.night ||
              _currentAtmosphere == CoconutAtmosphereMode.rain)
          ? 1
          : 0;
    } else if (atmosphereChanged) {
      // Switching between Day/Sunset and Night/Rain alternates between the world's 2 songs
      final int preferredTrack =
          (_currentAtmosphere == CoconutAtmosphereMode.night ||
                  _currentAtmosphere == CoconutAtmosphereMode.rain)
              ? 1
              : 0;
      _currentTrackIndex = preferredTrack;
    }

    if (isMuted || _isPausedByLifecycle) return;

    await _ensureMusicTrackPlaying(worldId, _currentTrackIndex);

    final double yawToUse =
        initialYaw ?? (_lastSpatialYaw >= 0 ? _lastSpatialYaw : 15.0);
    await _updateDirectionalZoneAudio(
      worldId: worldId,
      yaw: yawToUse,
      forceSwitch: worldChanged,
    );
  }

  Future<void> _ensureMusicTrackPlaying(String worldId, int trackIdx) async {
    final List<String> playlist =
        _worldMusicPlaylists[worldId] ?? _worldMusicPlaylists['coconut']!;
    final String targetAsset = playlist[trackIdx % playlist.length];

    if (_activeMusicAsset == targetAsset || _isUpdatingMusic) {
      // Keep playing seamlessly without restarting if already playing this track
      try {
        await _musicPlayer?.setVolume(_getMusicVolumeForAtmosphere());
      } catch (_) {}
      return;
    }

    _isUpdatingMusic = true;
    try {
      if (_musicPlayer == null) {
        final player = AudioPlayer();
        await player.setReleaseMode(ReleaseMode.stop);
        _musicCompleteSub = player.onPlayerComplete.listen((_) {
          _onMusicTrackComplete();
        });
        _musicPlayer = player;
      }
      _activeMusicAsset = targetAsset;
      await _musicPlayer!.setVolume(_getMusicVolumeForAtmosphere());
      await _musicPlayer!.play(AssetSource(targetAsset));
    } catch (_) {
      // Gracefully ignore in headless widget tests
    } finally {
      _isUpdatingMusic = false;
    }
  }

  void _onMusicTrackComplete() {
    if (isMuted || _isPausedByLifecycle || _currentWorldId == null) return;
    // Advance to the next full-length song in this world's 2-track playlist
    _currentTrackIndex = (_currentTrackIndex + 1) % 2;
    _activeMusicAsset = null;
    _ensureMusicTrackPlaying(_currentWorldId!, _currentTrackIndex);
  }

  double _getMusicVolumeForAtmosphere() {
    return switch (_currentAtmosphere) {
      CoconutAtmosphereMode.sunset => 0.72,
      CoconutAtmosphereMode.noon => 0.74,
      CoconutAtmosphereMode.night => 0.66,
      CoconutAtmosphereMode.rain => 0.68,
    };
  }

  /// Updates the subtle 360° directional ambient color layer (10%–14% volume)
  /// as the camera rotates around the world.
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
    if (angleDiff < 4.0 &&
        now.difference(_lastSpatialUpdate).inMilliseconds < 200) {
      return;
    }
    if (now.difference(_lastSpatialUpdate).inMilliseconds < 110) {
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
    final String dirKey = 'sub_dir_${worldId}_z${spot.zoneIndex}';

    _isUpdatingDirectional = true;
    try {
      if (_directionalPlayer == null) {
        final player = AudioPlayer();
        await player.setReleaseMode(ReleaseMode.loop);
        _directionalPlayer = player;
      }

      // Strictly keep 360° directional effects in the subtle 10%–15% range
      final double targetVol =
          (spot.volume * (isMenuPreview ? 0.85 : 1.0)).clamp(0.08, 0.15);

      if (forceSwitch ||
          _activeDirectionalKey != dirKey ||
          _currentDirectionalZone != spot.zoneIndex) {
        final Source source = _getPlayableWavSource(
          dirKey,
          () => _buildSubtleDirectionalWav(worldId, spot.zoneIndex),
        );
        _currentDirectionalZone = spot.zoneIndex;
        _activeDirectionalKey = dirKey;
        await _directionalPlayer!.setVolume(targetVol);
        await _directionalPlayer!.setBalance(spot.pan);
        await _directionalPlayer!.play(source);
      } else {
        await _directionalPlayer!.setVolume(targetVol);
        await _directionalPlayer!.setBalance(spot.pan);
      }
    } catch (_) {
      // Ignore in headless test environments
    } finally {
      _isUpdatingDirectional = false;
    }
  }

  Future<void> playInteractionChime() async {
    if (isMuted || _isPausedByLifecycle) return;
    final String worldId = _currentWorldId ?? 'coconut';
    final String sfxKey = 'sfx_soft_$worldId';
    try {
      if (_sfxPlayer == null) {
        final player = AudioPlayer();
        await player.setReleaseMode(ReleaseMode.stop);
        _sfxPlayer = player;
      }
      final Source source = _getPlayableWavSource(
        sfxKey,
        () => _buildWorldChimeWav(worldId),
      );
      await _sfxPlayer!.setVolume(0.24);
      await _sfxPlayer!.play(source);
    } catch (_) {}
  }

  Future<void> pauseForLifecycle() async {
    _isPausedByLifecycle = true;
    try {
      await _musicPlayer?.pause();
      await _directionalPlayer?.pause();
    } catch (_) {}
  }

  Future<void> resumeFromLifecycle() async {
    if (!_isPausedByLifecycle) return;
    _isPausedByLifecycle = false;
    if (isMuted) return;
    try {
      await _musicPlayer?.resume();
      await _directionalPlayer?.resume();
    } catch (_) {}
  }

  Future<void> stopAmbient() async {
    try {
      await _musicPlayer?.stop();
      await _directionalPlayer?.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _musicCompleteSub?.cancel();
    _musicCompleteSub = null;
    try {
      await _musicPlayer?.dispose();
      await _directionalPlayer?.dispose();
      await _sfxPlayer?.dispose();
    } catch (_) {}
    _musicPlayer = null;
    _directionalPlayer = null;
    _sfxPlayer = null;
  }

  // ---------------------------------------------------------------------------
  // 360° DIRECTIONAL ZONE RESOLUTION (SUBTLE 10%–15% SPATIAL LAYER)
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

    // Subtle 0.09 (9%) to 0.145 (14.5%) volume so it gently colors the background music
    final double proximity = (1.0 - (bestAbsDiff / 65.0)).clamp(0.0, 1.0);
    final double volume = 0.09 + 0.055 * proximity;
    final double pan = (signedDiffForBest / 55.0).clamp(-0.55, 0.55);

    return _DirectionalSpot(
      zoneIndex: bestZone,
      volume: volume,
      pan: pan,
    );
  }

  // ---------------------------------------------------------------------------
  // GENTLE, NATURAL 360° ENVIRONMENTAL TEXTURE SYNTHESIZER (5.0s LOOP)
  // Soft surf, crackling fire, water trickle, gentle breeze — no harsh beeps.
  // ---------------------------------------------------------------------------
  Uint8List _buildSubtleDirectionalWav(String worldId, int zoneIndex) {
    const int sampleRate = 22050;
    const int durationSeconds = 5;
    const int numSamples = sampleRate * durationSeconds;
    final ByteData data = ByteData(44 + numSamples * 2);

    _writeWavHeader(data, sampleRate, numSamples);
    final math.Random rng = math.Random(worldId.hashCode ^ (zoneIndex * 197));
    double lpSlow = 0.0;
    double lpMid = 0.0;

    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      final double rad = (t / durationSeconds) * 2.0 * math.pi;
      final double white = rng.nextDouble() * 2.0 - 1.0;
      lpSlow = lpSlow * 0.975 + white * 0.025;
      lpMid = lpMid * 0.90 + white * 0.10;

      double sample = 0.0;

      switch (worldId) {
        case 'coconut':
          if (zoneIndex == 0 || zoneIndex == 1) {
            // Soft ocean surf wash & gentle pier water
            final double wave = 0.45 + 0.55 * math.sin(rad);
            sample = lpSlow * 0.65 * wave;
          } else if (zoneIndex == 3) {
            // Warm campfire crackle
            final double crackle = (rng.nextDouble() > 0.992) ? 0.25 : 0.0;
            sample = lpMid * 0.25 + crackle;
          } else {
            // Soft tropical palm breeze & distant bamboo wind chime
            final double chime = math.sin(2.0 * math.pi * 587.33 * t) *
                math.exp(-((t % 2.5) * 3.8)) *
                0.12;
            sample = lpSlow * 0.35 + chime;
          }
        case 'pine_tree':
          if (zoneIndex == 0) {
            // Soft rhythmic steam train whoosh in distance
            final double chug = (0.5 + 0.5 * math.sin(rad * 6.0));
            sample = lpMid * 0.38 * chug;
          } else if (zoneIndex == 1 || zoneIndex == 3) {
            // Bubbling warm hot tub / campfire & waterfall
            final double crackle = (rng.nextDouble() > 0.993) ? 0.20 : 0.0;
            sample = lpSlow * 0.45 + crackle;
          } else {
            // Soft alpine snow breeze & distant sleigh shimmer
            final double bell = math.sin(2.0 * math.pi * 1568.0 * t) *
                math.exp(-((t % 2.5) * 5.0)) *
                0.08;
            sample = lpSlow * 0.40 + bell;
          }
        case 'mossy_rock':
          if (zoneIndex == 0 || zoneIndex == 3) {
            // Gentle bamboo Kakei water drop & hot spring stream
            final double dropT = t % 2.5;
            final double drop = math.sin(2.0 * math.pi * 660.0 * t) *
                math.exp(-dropT * 10.0) *
                0.18;
            sample = lpSlow * 0.38 + drop;
          } else if (zoneIndex == 4) {
            // Deep, warm distant templeBonsho resonance
            final double bell = (math.sin(2.0 * math.pi * 110.0 * t) * 0.22 +
                    math.sin(2.0 * math.pi * 220.0 * t) * 0.10) *
                math.exp(-t * 0.9);
            sample = bell + lpSlow * 0.25;
          } else {
            // Soft bamboo grove rustle & Shishi-odoshi knock
            final double knockT = (t + 1.0) % 2.5;
            final double knock = math.sin(2.0 * math.pi * 380.0 * t) *
                math.exp(-knockT * 20.0) *
                0.20;
            sample = lpMid * 0.24 + knock;
          }
        case 'street_lamp':
          if (zoneIndex == 0) {
            // Soft river water & distant vintage tram bell
            final double bellT = t % 5.0;
            final double bell = math.sin(2.0 * math.pi * 1174.66 * t) *
                math.exp(-bellT * 8.0) *
                0.15;
            sample = lpSlow * 0.35 + bell;
          } else if (zoneIndex == 1) {
            // Gentle plaza stone fountain water
            sample = lpMid * (0.32 + 0.12 * math.sin(rad * 3.0));
          } else {
            // Warm evening plaza ambience
            sample = lpSlow * 0.30;
          }
        case 'desert_cactus':
          if (zoneIndex == 1) {
            // Cascading oasis waterfall & gentle caravan chime
            final double bellT = t % 2.5;
            final double bell = math.sin(2.0 * math.pi * 523.25 * t) *
                math.exp(-bellT * 6.0) *
                0.12;
            sample = lpMid * 0.38 + bell;
          } else if (zoneIndex == 3) {
            // Crackling Bedouin desert fire
            final double crackle = (rng.nextDouble() > 0.991) ? 0.22 : 0.0;
            sample = lpSlow * 0.28 + crackle;
          } else {
            // Warm canyon wind sweeping across sandstone
            final double wind = 0.4 + 0.6 * math.sin(rad);
            sample = lpSlow * 0.48 * wind;
          }
        case 'christmas_tree':
          if (zoneIndex == 0) {
            // Distant deep Cologne Cathedral bell resonance
            final double tollT = t % 2.5;
            final double bell = (math.sin(2.0 * math.pi * 196.0 * t) * 0.20 +
                    math.sin(2.0 * math.pi * 392.0 * t) * 0.09) *
                math.exp(-tollT * 1.8);
            sample = bell + lpSlow * 0.22;
          } else if (zoneIndex == 3) {
            // Warm charcoal grill sizzle & winter market murmur
            final double sizzle = (rng.nextDouble() > 0.992) ? 0.18 : 0.0;
            sample = lpMid * 0.26 + sizzle;
          } else {
            // Rhine river flow & gentle winter breeze
            sample = lpSlow * 0.36;
          }
        default:
          sample = lpSlow * 0.30;
      }

      final int pcm16 =
          (sample.clamp(-0.85, 0.85) * 32767.0).round().clamp(-32768, 32767);
      data.setInt16(44 + i * 2, pcm16, Endian.little);
    }

    _applySeamlessLoopCrossfade(data, numSamples, sampleRate);
    return data.buffer.asUint8List();
  }

  Uint8List _buildWorldChimeWav(String worldId) {
    const int sampleRate = 22050;
    const int numSamples = 6600; // ~300ms
    final ByteData data = ByteData(44 + numSamples * 2);
    _writeWavHeader(data, sampleRate, numSamples);

    final List<double> freqs = switch (worldId) {
      'coconut' => const [392.0, 587.33],
      'pine_tree' => const [523.25, 659.25],
      'mossy_rock' => const [440.0, 659.25],
      'street_lamp' => const [329.63, 493.88],
      'desert_cactus' => const [293.66, 440.0],
      'christmas_tree' => const [523.25, 783.99],
      _ => const [440.0, 659.25],
    };

    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      final double env = math.exp(-t * 13.0);
      final double signal = (math.sin(2.0 * math.pi * freqs[0] * t) * 0.36 +
              math.sin(2.0 * math.pi * freqs[1] * t) * 0.20) *
          env;
      final int pcm16 = (signal * 32767.0).round().clamp(-32768, 32767);
      data.setInt16(44 + i * 2, pcm16, Endian.little);
    }

    return data.buffer.asUint8List();
  }

  void _applySeamlessLoopCrossfade(
    ByteData data,
    int numSamples,
    int sampleRate,
  ) {
    final int fadeSamples = (sampleRate * 0.08).round();
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
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, sampleRate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
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
