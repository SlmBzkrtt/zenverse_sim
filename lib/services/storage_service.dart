import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../painters/coconut_world_painter.dart';

/// Lightweight local storage service powered by `shared_preferences`.
/// Persists last selected simulator, cumulative meditation seconds,
/// audio mute state, and per-world style/atmosphere preferences.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  static const String _keyLastSimIndex = 'os_last_sim_index';
  static const String _keyTotalMeditationSec = 'os_total_meditation_sec';
  static const String _keyAudioMuted = 'os_audio_muted';
  static const String _keyGlobalAtmosphere = 'os_global_atmosphere';
  static const String _keyGlobalStyle = 'os_global_style';

  SharedPreferences? _prefs;
  final ValueNotifier<int> totalMeditationSeconds = ValueNotifier<int>(0);
  final ValueNotifier<bool> isAudioMuted = ValueNotifier<bool>(false);

  Future<void> init() async {
    if (_prefs != null) return;
    try {
      _prefs = await SharedPreferences.getInstance();
      totalMeditationSeconds.value =
          _prefs?.getInt(_keyTotalMeditationSec) ?? 0;
      isAudioMuted.value = _prefs?.getBool(_keyAudioMuted) ?? false;
    } catch (_) {
      // Safe fallback in headless test environments
    }
  }

  int loadSelectedWorldIndex({int maxCount = 6}) {
    final int idx = _prefs?.getInt(_keyLastSimIndex) ?? 0;
    return idx.clamp(0, maxCount - 1);
  }

  Future<void> saveSelectedWorldIndex(int index) async {
    try {
      await _prefs?.setInt(_keyLastSimIndex, index);
    } catch (_) {}
  }

  CoconutAtmosphereMode loadAtmosphereMode() {
    final int idx = (_prefs?.getInt(_keyGlobalAtmosphere) ?? 0)
        .clamp(0, CoconutAtmosphereMode.values.length - 1);
    return CoconutAtmosphereMode.values[idx];
  }

  Future<void> saveAtmosphereMode(CoconutAtmosphereMode mode) async {
    try {
      await _prefs?.setInt(_keyGlobalAtmosphere, mode.index);
    } catch (_) {}
  }

  CoconutStyleMode loadStyleMode() {
    final int idx = (_prefs?.getInt(_keyGlobalStyle) ?? 0)
        .clamp(0, CoconutStyleMode.values.length - 1);
    return CoconutStyleMode.values[idx];
  }

  Future<void> saveStyleMode(CoconutStyleMode mode) async {
    try {
      await _prefs?.setInt(_keyGlobalStyle, mode.index);
    } catch (_) {}
  }

  Future<void> addMeditationSeconds(String worldId, int deltaSeconds) async {
    if (deltaSeconds <= 0) return;
    final int updated = totalMeditationSeconds.value + deltaSeconds;
    totalMeditationSeconds.value = updated;
    try {
      await _prefs?.setInt(_keyTotalMeditationSec, updated);
      final int worldTotal =
          (_prefs?.getInt('os_med_$worldId') ?? 0) + deltaSeconds;
      await _prefs?.setInt('os_med_$worldId', worldTotal);
    } catch (_) {}
  }

  Future<void> setAudioMuted(bool muted) async {
    isAudioMuted.value = muted;
    try {
      await _prefs?.setBool(_keyAudioMuted, muted);
    } catch (_) {}
  }
}

