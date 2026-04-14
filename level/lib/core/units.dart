import 'dart:math' as math;

enum AngleUnit { degrees, percentGrade }

enum DistanceUnit { metric, imperial }

class Units {
  Units._();

  static String formatAngle(double degrees, AngleUnit unit) {
    switch (unit) {
      case AngleUnit.degrees:
        return '${degrees.abs().toStringAsFixed(1)}°';
      case AngleUnit.percentGrade:
        final pct = math.tan(degrees * math.pi / 180) * 100;
        return '${pct.abs().toStringAsFixed(1)}%';
    }
  }

  static String formatDelta(double degrees, AngleUnit unit) {
    final sign = degrees >= 0 ? '+' : '−';
    switch (unit) {
      case AngleUnit.degrees:
        return '$sign${degrees.abs().toStringAsFixed(1)}°';
      case AngleUnit.percentGrade:
        final pct = math.tan(degrees * math.pi / 180) * 100;
        return '$sign${pct.abs().toStringAsFixed(1)}%';
    }
  }

  static String unitLabel(AngleUnit unit) {
    return switch (unit) {
      AngleUnit.degrees => '°',
      AngleUnit.percentGrade => '%',
    };
  }

  // Returns true if the given locale string implies imperial units.
  // Only US, Liberia (LR), and Myanmar (MM) use imperial.
  static bool localeDefaultsToImperial(String? localeCountryCode) {
    const imperial = {'US', 'LR', 'MM'};
    return imperial.contains(localeCountryCode?.toUpperCase());
  }
}
