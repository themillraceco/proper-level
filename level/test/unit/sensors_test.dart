import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:level/core/sensors.dart';
import 'package:level/core/calibration.dart';

void main() {
  const g = 9.81;

  group('TiltReading — surface level (phone flat)', () {
    test('phone perfectly flat → surfacePitch and surfaceRoll are 0', () {
      const tilt = TiltReading(x: 0, y: 0, z: g);
      expect(tilt.surfacePitch, closeTo(0.0, 0.01));
      expect(tilt.surfaceRoll, closeTo(0.0, 0.01));
    });

    test('tilted 10° in pitch → surfacePitch ≈ 10°', () {
      final rad = 10.0 * math.pi / 180;
      final tilt =
          TiltReading(x: 0, y: g * math.sin(rad), z: g * math.cos(rad));
      expect(tilt.surfacePitch, closeTo(10.0, 0.5));
    });

    test('tilted 10° in roll → surfaceRoll ≈ 10°', () {
      final rad = 10.0 * math.pi / 180;
      final tilt =
          TiltReading(x: g * math.sin(rad), y: 0, z: g * math.cos(rad));
      expect(tilt.surfaceRoll, closeTo(10.0, 0.5));
    });
  });

  group('TiltReading — vertical level (phone portrait, against wall)', () {
    test('phone perfectly plumb → verticalAngle ≈ 0', () {
      const tilt = TiltReading(x: 0, y: g, z: 0);
      expect(tilt.verticalAngle, closeTo(0.0, 0.01));
    });

    test('tilted 5° left → verticalAngle ≈ 5°', () {
      final rad = 5.0 * math.pi / 180;
      final tilt =
          TiltReading(x: g * math.sin(rad), y: g * math.cos(rad), z: 0);
      expect(tilt.verticalAngle, closeTo(5.0, 0.5));
    });
  });

  group('TiltReading — horizontal level (phone landscape)', () {
    test('phone level in landscape → horizontalAngle ≈ 0', () {
      // In landscape, x-axis points up; y=0 means level.
      const tilt = TiltReading(x: g, y: 0, z: 0);
      expect(tilt.horizontalAngle, closeTo(0.0, 0.01));
    });

    test('tilted 8° in landscape → horizontalAngle ≈ 8°', () {
      final rad = 8.0 * math.pi / 180;
      final tilt = TiltReading(
          x: g * math.cos(rad), y: g * math.sin(rad), z: 0);
      expect(tilt.horizontalAngle, closeTo(8.0, 0.5));
    });
  });

  group('TiltReading — inclination (clinometer)', () {
    test('phone flat → inclination ≈ 0°', () {
      const tilt = TiltReading(x: 0, y: 0, z: g);
      expect(tilt.inclination, closeTo(0.0, 0.5));
    });

    test('phone vertical → inclination ≈ 90°', () {
      const tilt = TiltReading(x: 0, y: g, z: 0);
      expect(tilt.inclination, closeTo(90.0, 0.5));
    });

    test('phone at 45° → inclination ≈ 45°', () {
      final v = g / math.sqrt(2);
      final tilt = TiltReading(x: 0, y: v, z: v);
      expect(tilt.inclination, closeTo(45.0, 0.5));
    });
  });

  group('TiltReading — isFlat', () {
    test('flat phone → isFlat is true', () {
      const tilt = TiltReading(x: 0, y: 0, z: g);
      expect(tilt.isFlat, isTrue);
    });

    test('upright phone → isFlat is false', () {
      const tilt = TiltReading(x: 0, y: g, z: 0);
      expect(tilt.isFlat, isFalse);
    });

    test('tilted 40° → isFlat is false (past 37° threshold)', () {
      final rad = 40.0 * math.pi / 180;
      final tilt =
          TiltReading(x: 0, y: g * math.sin(rad), z: g * math.cos(rad));
      expect(tilt.isFlat, isFalse);
    });

    test('tilted 20° → isFlat is true (within 37° threshold)', () {
      final rad = 20.0 * math.pi / 180;
      final tilt =
          TiltReading(x: 0, y: g * math.sin(rad), z: g * math.cos(rad));
      expect(tilt.isFlat, isTrue);
    });
  });

  group('LowPassFilter', () {
    test('alpha=1.0 passes samples through unchanged', () {
      final filter = LowPassFilter(alpha: 1.0);
      filter.updateRaw(1.0, 2.0, g);
      final result = filter.updateRaw(3.0, 4.0, g);
      expect(result.x, closeTo(3.0, 0.001));
      expect(result.y, closeTo(4.0, 0.001));
    });

    test('alpha=0.0 freezes at initial state (TiltReading.zero)', () {
      final filter = LowPassFilter(alpha: 0.0);
      final result = filter.updateRaw(5.0, 5.0, g);
      // With alpha=0, output = 0*new + 1*old = old = TiltReading.zero
      expect(result.x, closeTo(0.0, 0.001));
      expect(result.y, closeTo(0.0, 0.001));
    });

    test('output converges toward input over iterations', () {
      final filter = LowPassFilter(alpha: 0.5);
      TiltReading result = TiltReading.zero;
      for (var i = 0; i < 20; i++) {
        result = filter.updateRaw(10.0, 0.0, g);
      }
      expect(result.x, closeTo(10.0, 0.1));
    });

    test('reset returns filter to zero state', () {
      final filter = LowPassFilter(alpha: 0.9);
      filter.updateRaw(5.0, 5.0, g);
      filter.reset();
      final result = filter.updateRaw(0.0, 0.0, g);
      // After reset, state is zero; with alpha=0.9: x = 0.9*0 + 0.1*0 = 0
      expect(result.x, closeTo(0.0, 0.001));
    });
  });

  group('CalibrationData', () {
    test('zero calibration has no effect', () {
      const raw = TiltReading(x: 1.0, y: 2.0, z: g);
      final corrected = CalibrationData.zero.apply(raw);
      expect(corrected.x, closeTo(1.0, 0.001));
      expect(corrected.y, closeTo(2.0, 0.001));
      expect(corrected.z, closeTo(g, 0.001));
    });

    test('offset is subtracted from raw reading', () {
      const raw = TiltReading(x: 1.5, y: 0.8, z: g);
      const calib = CalibrationData(xOffset: 0.5, yOffset: 0.3);
      final corrected = calib.apply(raw);
      expect(corrected.x, closeTo(1.0, 0.001));
      expect(corrected.y, closeTo(0.5, 0.001));
    });

    test('isCalibrated returns false for zero offsets', () {
      expect(CalibrationData.zero.isCalibrated, isFalse);
    });

    test('isCalibrated returns true when any offset is non-zero', () {
      const calib = CalibrationData(xOffset: 0.1);
      expect(calib.isCalibrated, isTrue);
    });

    test('two-step calibration recovers sensor bias, ignoring surface tilt',
        () {
      // True sensor bias
      const biasX = 0.2;
      const biasY = 0.1;
      // Surface tilt (unknown to the user, doesn't need to be zero)
      const tiltX = 0.5;
      const tiltY = -0.3;

      // Step 1: phone normal orientation
      const step1 = TiltReading(x: biasX + tiltX, y: biasY + tiltY, z: g);
      // Step 2: phone rotated 180° around Z → surface tilt flips, bias stays
      const step2 = TiltReading(x: biasX - tiltX, y: biasY - tiltY, z: g);

      final helper = TwoStepCalibration();
      helper.captureStep1(step1);
      final result = helper.captureStep2(step2);

      expect(result, isNotNull);
      // Recovered offset should equal the bias
      expect(result!.xOffset, closeTo(biasX, 0.001));
      expect(result.yOffset, closeTo(biasY, 0.001));

      // Applying calibration to step1 reading should give back surface tilt
      final corrected = result.apply(step1);
      expect(corrected.x, closeTo(tiltX, 0.001));
      expect(corrected.y, closeTo(tiltY, 0.001));
    });

    test('captureStep2 without step1 returns null', () {
      final helper = TwoStepCalibration();
      final result = helper.captureStep2(TiltReading.zero);
      expect(result, isNull);
    });

    test('serialisation round-trip preserves offsets', () {
      const original = CalibrationData(xOffset: 0.18, yOffset: -0.05, zOffset: 0.02);
      final json = original.toJson();
      final restored = CalibrationData.fromJson(json);
      expect(restored.xOffset, closeTo(original.xOffset, 0.0001));
      expect(restored.yOffset, closeTo(original.yOffset, 0.0001));
      expect(restored.zOffset, closeTo(original.zOffset, 0.0001));
    });
  });
}
