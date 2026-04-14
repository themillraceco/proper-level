import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';

// Tilt reading — derived from accelerometer gravity vector.
// All angle values are in degrees.
class TiltReading {
  final double x; // m/s² — rightward
  final double y; // m/s² — upward (top of phone)
  final double z; // m/s² — out of screen face

  const TiltReading({required this.x, required this.y, required this.z});

  static const zero = TiltReading(x: 0, y: 0, z: 9.81);

  double get magnitude => math.sqrt(x * x + y * y + z * z);

  // ── Horizontal level (phone landscape, long edge on a surface) ──────────
  // 0° = perfectly level. Range ±90°.
  double get horizontalAngle => math.atan2(y, x) * 180 / math.pi;

  // ── Vertical level (phone portrait, edge against a wall) ────────────────
  // 0° = perfectly plumb. Range ±90°.
  double get verticalAngle => math.atan2(x, y) * 180 / math.pi;

  // ── Surface level (phone flat on a surface) ─────────────────────────────
  // Both 0° = flat.
  double get surfacePitch => math.atan2(y, z) * 180 / math.pi;
  double get surfaceRoll => math.atan2(x, z) * 180 / math.pi;

  // ── Clinometer (absolute angle of inclination from horizontal) ───────────
  // 0° = flat, 90° = vertical. Always positive.
  double get inclination {
    final horizontal = math.sqrt(x * x + y * y);
    return math.atan2(horizontal, z.abs()) * 180 / math.pi;
  }

  // Detect whether the phone is "flat" — z-axis is dominant.
  // Uses a 37° threshold (cos 37° ≈ 0.80).
  bool get isFlat => z.abs() / (magnitude + 0.001) > 0.80;

  TiltReading operator -(TiltReading offset) => TiltReading(
        x: x - offset.x,
        y: y - offset.y,
        z: z - offset.z,
      );

  TiltReading operator +(TiltReading other) => TiltReading(
        x: x + other.x,
        y: y + other.y,
        z: z + other.z,
      );

  TiltReading scale(double factor) =>
      TiltReading(x: x * factor, y: y * factor, z: z * factor);

  @override
  String toString() =>
      'TiltReading(x: ${x.toStringAsFixed(3)}, y: ${y.toStringAsFixed(3)}, z: ${z.toStringAsFixed(3)})';
}

// Low-pass filter — exponential moving average.
// alpha near 1.0 = fast (responsive); near 0.0 = smooth (damped).
class LowPassFilter {
  final double alpha;
  TiltReading _state = TiltReading.zero;

  LowPassFilter({required this.alpha});

  // Main entry point — called with sensor events in production.
  TiltReading update(AccelerometerEvent event) =>
      updateRaw(event.x, event.y, event.z);

  // Test-friendly entry point — accepts raw doubles.
  TiltReading updateRaw(double x, double y, double z) {
    _state = TiltReading(
      x: alpha * x + (1 - alpha) * _state.x,
      y: alpha * y + (1 - alpha) * _state.y,
      z: alpha * z + (1 - alpha) * _state.z,
    );
    return _state;
  }

  void reset() {
    _state = TiltReading.zero;
  }
}

// Sensitivity enum — maps to an alpha value for the low-pass filter.
enum Sensitivity {
  fast(alpha: 0.80),
  medium(alpha: 0.45),
  smooth(alpha: 0.18);

  final double alpha;
  const Sensitivity({required this.alpha});

  String get label => switch (this) {
        Sensitivity.fast => 'Fast',
        Sensitivity.medium => 'Medium',
        Sensitivity.smooth => 'Smooth',
      };
}

// Raw (unfiltered) accelerometer stream — one event per platform frame.
Stream<AccelerometerEvent> rawAccelerometerStream() =>
    accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval);
