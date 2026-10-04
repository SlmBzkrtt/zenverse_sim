import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'storage_service.dart';

/// Multi-platform ambient soundscape & UI SFX service powered by `audioplayers`.
/// Synthesizes lightweight, zero-asset-overhead mono WAV buffers once per
/// world and loops them via `AudioPlayer`, with automatic pause/resume on
/// app lifecycle changes.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  AudioPlayer? _ambientPlayer;
  AudioPlayer? _sfxPlayer;
  String? _currentWorldId;
  bool _isPausedByLifecycle = false;

  final Map<String, Uint8List> _ambientWavCache = <String, Uint8List>{};
  Uint8List? _chimeWavCache;

  bool get isMuted => StorageService.instance.isAudioMuted.value;

  Future<void> toggleMute() async {
    final bool nextMuted = !isMuted;
    await StorageService.instance.setAudioMuted(nextMuted);
    try {
      if (nextMuted) {
        await _ambientPlayer?.setVolume(0.0);
      } else {
        await _ambientPlayer?.setVolume(0.32);
        if (_currentWorldId != null) {
          await startAmbientForWorld(_currentWorldId!);
        }
      }
    } catch (_) {}
  }

  Future<void> startAmbientForWorld(String worldId) async {
    _currentWorldId = worldId;
    if (isMuted || _isPausedByLifecycle) return;
    try {
      if (_ambientPlayer == null) {
        final player = AudioPlayer();
        await player.setReleaseMode(ReleaseMode.loop);
        _ambientPlayer = player;
      }
      final Uint8List wavBytes = _ambientWavCache.putIfAbsent(
        worldId,
        () => _buildAmbientLoopWav(worldId),
      );
      await _ambientPlayer!.setVolume(0.32);
      await _ambientPlayer!.play(BytesSource(wavBytes));
    } catch (_) {
      // Gracefully ignore in headless widget tests where platform channel is absent
    }
  }

  Future<void> playInteractionChime() async {
    if (isMuted || _isPausedByLifecycle) return;
    try {
      if (_sfxPlayer == null) {
        final player = AudioPlayer();
        await player.setReleaseMode(ReleaseMode.stop);
        _sfxPlayer = player;
      }
      _chimeWavCache ??= _buildSoftChimeWav();
      await _sfxPlayer!.setVolume(0.24);
      await _sfxPlayer!.play(BytesSource(_chimeWavCache!));
    } catch (_) {}
  }

  Future<void> pauseForLifecycle() async {
    _isPausedByLifecycle = true;
    try {
      await _ambientPlayer?.pause();
    } catch (_) {}
  }

  Future<void> resumeFromLifecycle() async {
    if (!_isPausedByLifecycle) return;
    _isPausedByLifecycle = false;
    if (isMuted) return;
    try {
      await _ambientPlayer?.resume();
    } catch (_) {}
  }

  Future<void> stopAmbient() async {
    try {
      await _ambientPlayer?.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    try {
      await _ambientPlayer?.dispose();
      await _sfxPlayer?.dispose();
    } catch (_) {}
    _ambientPlayer = null;
    _sfxPlayer = null;
  }

  /// Generates a seamless 4-second 22.05kHz 16-bit mono WAV loop tailored to each world.
  Uint8List _buildAmbientLoopWav(String worldId) {
    const int sampleRate = 22050;
    const int durationSeconds = 4;
    const int numSamples = sampleRate * durationSeconds;
    final ByteData data = ByteData(44 + numSamples * 2);

    _writeWavHeader(data, sampleRate, numSamples);
    final math.Random rng = math.Random(worldId.hashCode);
    double lpState = 0.0;

    final List<double> chordFreqs = switch (worldId) {
      'coconut' => const [196.0, 246.94, 293.66, 369.99], // Warm Tropical Gmaj7
      'pine_tree' => const [174.61, 220.0, 261.63, 329.63], // Nordic Fmaj7
      'mossy_rock' => const [220.0, 293.66, 329.63, 440.0], // Zen Pentatonic
      'street_lamp' => const [164.81, 196.0, 246.94, 293.66], // Lo-Fi Em7
      'desert_cactus' => const [146.83, 220.0, 277.18, 329.63], // Canyon Dadd9
      'christmas_tree' => const [261.63, 329.63, 392.0, 493.88], // Festive Cmaj7
      _ => const [220.0, 277.18, 329.63],
    };

    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      final double loopAngle = (t / durationSeconds) * 2.0 * math.pi;
      final double swell = 0.72 + 0.28 * math.sin(loopAngle);

      double harmonicSum = 0.0;
      for (int c = 0; c < chordFreqs.length; c++) {
        final double freq = chordFreqs[c];
        harmonicSum +=
            math.sin(2.0 * math.pi * freq * t + c * 0.8) * (0.14 / (c + 1));
      }

      // Soft filtered breeze / ocean / wind noise
      final double white = (rng.nextDouble() * 2.0 - 1.0) * 0.04;
      lpState = lpState * 0.96 + white * 0.04;

      final double sample = ((harmonicSum + lpState) * swell).clamp(-0.9, 0.9);
      final int pcm16 = (sample * 32767.0).round().clamp(-32768, 32767);
      data.setInt16(44 + i * 2, pcm16, Endian.little);
    }

    return data.buffer.asUint8List();
  }

  /// Generates a gentle 280ms wooden/chime tap sound effect.
  Uint8List _buildSoftChimeWav() {
    const int sampleRate = 22050;
    const int numSamples = 6174; // ~280ms
    final ByteData data = ByteData(44 + numSamples * 2);
    _writeWavHeader(data, sampleRate, numSamples);

    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      final double env = math.exp(-t * 14.0);
      final double signal = (math.sin(2.0 * math.pi * 528.0 * t) * 0.45 +
              math.sin(2.0 * math.pi * 792.0 * t) * 0.22) *
          env;
      final int pcm16 = (signal * 32767.0).round().clamp(-32768, 32767);
      data.setInt16(44 + i * 2, pcm16, Endian.little);
    }

    return data.buffer.asUint8List();
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

