import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/units.dart';
import '../core/sensors.dart';

const _kAudio = 'audio_enabled';
const _kVibration = 'vibration_enabled';
const _kThreshold = 'level_threshold';
const _kSensitivity = 'sensitivity';
const _kAngleUnit = 'angle_unit';
const _kDistanceUnit = 'distance_unit';

class AppSettings {
  final bool audioEnabled;
  final bool vibrationEnabled;
  final double levelThreshold; // degrees
  final Sensitivity sensitivity;
  final AngleUnit angleUnit;
  final DistanceUnit distanceUnit;
  final bool flashlightOn;

  const AppSettings({
    this.audioEnabled = true,
    this.vibrationEnabled = true,
    this.levelThreshold = 0.5,
    this.sensitivity = Sensitivity.smooth,
    this.angleUnit = AngleUnit.degrees,
    this.distanceUnit = DistanceUnit.metric,
    this.flashlightOn = false,
  });

  AppSettings copyWith({
    bool? audioEnabled,
    bool? vibrationEnabled,
    double? levelThreshold,
    Sensitivity? sensitivity,
    AngleUnit? angleUnit,
    DistanceUnit? distanceUnit,
    bool? flashlightOn,
  }) =>
      AppSettings(
        audioEnabled: audioEnabled ?? this.audioEnabled,
        vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
        levelThreshold: levelThreshold ?? this.levelThreshold,
        sensitivity: sensitivity ?? this.sensitivity,
        angleUnit: angleUnit ?? this.angleUnit,
        distanceUnit: distanceUnit ?? this.distanceUnit,
        flashlightOn: flashlightOn ?? this.flashlightOn,
      );
}

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final prefs = await SharedPreferences.getInstance();

    // Default distance unit based on device locale.
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final defaultDistance = Units.localeDefaultsToImperial(locale.countryCode)
        ? DistanceUnit.imperial
        : DistanceUnit.metric;

    return AppSettings(
      audioEnabled: prefs.getBool(_kAudio) ?? true,
      vibrationEnabled: prefs.getBool(_kVibration) ?? true,
      levelThreshold: prefs.getDouble(_kThreshold) ?? 0.5,
      sensitivity: Sensitivity.values.firstWhere(
        (s) => s.name == (prefs.getString(_kSensitivity) ?? ''),
        orElse: () => Sensitivity.medium,
      ),
      angleUnit: AngleUnit.values.firstWhere(
        (u) => u.name == (prefs.getString(_kAngleUnit) ?? ''),
        orElse: () => AngleUnit.degrees,
      ),
      distanceUnit: DistanceUnit.values.firstWhere(
        (u) => u.name == (prefs.getString(_kDistanceUnit) ?? ''),
        orElse: () => defaultDistance,
      ),
      flashlightOn: false, // always reset on launch
    );
  }

  Future<void> _save(AppSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setBool(_kAudio, s.audioEnabled),
      prefs.setBool(_kVibration, s.vibrationEnabled),
      prefs.setDouble(_kThreshold, s.levelThreshold),
      prefs.setString(_kSensitivity, s.sensitivity.name),
      prefs.setString(_kAngleUnit, s.angleUnit.name),
      prefs.setString(_kDistanceUnit, s.distanceUnit.name),
    ]);
  }

  Future<void> toggleAudio() async {
    final s = state.value!.copyWith(audioEnabled: !state.value!.audioEnabled);
    state = AsyncData(s);
    await _save(s);
  }

  Future<void> toggleVibration() async {
    final s = state.value!
        .copyWith(vibrationEnabled: !state.value!.vibrationEnabled);
    state = AsyncData(s);
    await _save(s);
  }

  Future<void> setThreshold(double value) async {
    final s = state.value!.copyWith(levelThreshold: value);
    state = AsyncData(s);
    await _save(s);
  }

  Future<void> setSensitivity(Sensitivity value) async {
    final s = state.value!.copyWith(sensitivity: value);
    state = AsyncData(s);
    await _save(s);
  }

  Future<void> setAngleUnit(AngleUnit value) async {
    final s = state.value!.copyWith(angleUnit: value);
    state = AsyncData(s);
    await _save(s);
  }

  Future<void> setDistanceUnit(DistanceUnit value) async {
    final s = state.value!.copyWith(distanceUnit: value);
    state = AsyncData(s);
    await _save(s);
  }

  Future<void> setFlashlight(bool on) async {
    state = AsyncData(state.value!.copyWith(flashlightOn: on));
    // Persisting flashlight state is intentionally omitted — reset on launch.
  }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
