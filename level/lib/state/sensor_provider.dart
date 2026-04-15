import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/sensors.dart';
import '../core/calibration.dart';
import 'settings_provider.dart';

// Loads calibration data from SharedPreferences once.
final calibrationProvider =
    AsyncNotifierProvider<CalibrationNotifier, CalibrationData>(
        CalibrationNotifier.new);

class CalibrationNotifier extends AsyncNotifier<CalibrationData> {
  @override
  Future<CalibrationData> build() => loadCalibration();

  Future<void> applyCalibration(CalibrationData data) async {
    await saveCalibration(data);
    state = AsyncData(data);
  }

  Future<void> reset() async {
    await clearCalibration();
    state = const AsyncData(CalibrationData.zero);
  }
}

// Raw calibrated tilt stream. Rebuilds only when calibration or sensitivity changes.
// Consumer widgets should watch [tiltProvider] which handles freeze.
final rawTiltProvider = StreamProvider<TiltReading>((ref) {
  final calibration = ref.watch(calibrationProvider).value ?? CalibrationData.zero;
  // Read sensitivity directly from persisted settings so the correct value is
  // applied after a restart, not the old hardcoded 0.45 default.
  final sensitivity = ref.watch(
    settingsProvider.select((s) => s.value?.sensitivity ?? Sensitivity.smooth),
  );

  final filter = LowPassFilter(alpha: sensitivity.alpha);

  return rawAccelerometerStream().map((event) {
    final filtered = filter.update(event);
    return calibration.apply(filtered);
  });
});
