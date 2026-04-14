import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/sensors.dart';
import '../core/calibration.dart';

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

// Sensitivity provider — kept separate so it can be updated
// without rebuilding the entire sensor stream.
final sensitivityProvider = StateProvider<double>((ref) => 0.45);

// Raw calibrated tilt stream. Rebuilds when calibration changes.
// Consumer widgets should watch [tiltProvider] which handles freeze.
final rawTiltProvider = StreamProvider<TiltReading>((ref) {
  final calibration = ref.watch(calibrationProvider).value ?? CalibrationData.zero;
  final alpha = ref.watch(sensitivityProvider);

  final filter = LowPassFilter(alpha: alpha);

  return rawAccelerometerStream().map((event) {
    final filtered = filter.update(event);
    return calibration.apply(filtered);
  });
});
