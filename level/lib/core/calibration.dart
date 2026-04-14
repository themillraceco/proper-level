import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'sensors.dart';

const _kCalibrationKey = 'calibration_v1';

// Calibration offset — subtracted from every raw TiltReading.
// A zeroed CalibrationData means no correction is applied.
class CalibrationData {
  final double xOffset;
  final double yOffset;
  final double zOffset;

  const CalibrationData({
    this.xOffset = 0,
    this.yOffset = 0,
    this.zOffset = 0,
  });

  static const zero = CalibrationData();

  bool get isCalibrated => xOffset != 0 || yOffset != 0 || zOffset != 0;

  TiltReading apply(TiltReading raw) => TiltReading(
        x: raw.x - xOffset,
        y: raw.y - yOffset,
        z: raw.z - zOffset,
      );

  Map<String, dynamic> toJson() =>
      {'x': xOffset, 'y': yOffset, 'z': zOffset};

  factory CalibrationData.fromJson(Map<String, dynamic> json) =>
      CalibrationData(
        xOffset: (json['x'] as num?)?.toDouble() ?? 0,
        yOffset: (json['y'] as num?)?.toDouble() ?? 0,
        zOffset: (json['z'] as num?)?.toDouble() ?? 0,
      );
}

// Two-step calibration helper.
//
// Step 1: phone flat on a surface — capture reading A.
// Step 2: phone rotated 180° end-for-end (around Z) — capture reading B.
//
// Because a Z-rotation negates x and y but not z:
//   A = (θ + b_x, θ + b_y, b_z)  [surface tilt θ plus sensor bias b]
//   B = (−θ + b_x, −θ + b_y, b_z)
//   offset = (A + B) / 2 = (b_x, b_y, b_z)  ← pure sensor bias
//
// Subtracting this offset from future readings removes sensor bias
// regardless of the surface imperfection used for calibration.
class TwoStepCalibration {
  TiltReading? _step1;

  void captureStep1(TiltReading reading) {
    _step1 = reading;
  }

  // Returns the computed CalibrationData if both steps are complete, else null.
  CalibrationData? captureStep2(TiltReading reading) {
    final s1 = _step1;
    if (s1 == null) return null;

    final offset = CalibrationData(
      xOffset: (s1.x + reading.x) / 2,
      yOffset: (s1.y + reading.y) / 2,
      zOffset: (s1.z + reading.z) / 2,
    );
    _step1 = null;
    return offset;
  }

  bool get hasStep1 => _step1 != null;
  void reset() => _step1 = null;
}

// Persistence helpers.
Future<CalibrationData> loadCalibration() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kCalibrationKey);
  if (raw == null) return CalibrationData.zero;
  try {
    return CalibrationData.fromJson(
        jsonDecode(raw) as Map<String, dynamic>);
  } catch (_) {
    return CalibrationData.zero;
  }
}

Future<void> saveCalibration(CalibrationData data) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kCalibrationKey, jsonEncode(data.toJson()));
}

Future<void> clearCalibration() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_kCalibrationKey);
}
