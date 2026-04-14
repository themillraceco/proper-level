import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/units.dart';

// Large monospaced angle readout with status label.
// Color transitions: gray (off) → white (near) → yellow (level).

class AngleReadout extends StatelessWidget {
  final double angle; // degrees
  final double threshold; // degrees — level achieved below this
  final AngleUnit unit;
  final bool showStatusLabel;

  const AngleReadout({
    super.key,
    required this.angle,
    required this.threshold,
    this.unit = AngleUnit.degrees,
    this.showStatusLabel = true,
  });

  LevelStatus get _status {
    final abs = angle.abs();
    if (abs <= threshold) return LevelStatus.achieved;
    if (abs <= threshold * 10) return LevelStatus.near;
    return LevelStatus.off;
  }

  Color get _color => switch (_status) {
        LevelStatus.achieved => AppColors.levelAchieved,
        LevelStatus.near => AppColors.nearLevel,
        LevelStatus.off => AppColors.offLevel,
      };

  String get _statusText => switch (_status) {
        LevelStatus.achieved => 'LEVEL',
        LevelStatus.near => 'NEAR',
        LevelStatus.off => 'OFF',
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          Units.formatAngle(angle, unit),
          style: AppTextStyles.readout(color: _color),
        ),
        if (showStatusLabel) ...[
          const SizedBox(height: 8),
          Text(
            _statusText,
            style: AppTextStyles.statusLabel(color: _color),
          ),
        ],
      ],
    );
  }
}

// Dual readout for surface level mode (X and Y axes).
class DualAngleReadout extends StatelessWidget {
  final double pitchAngle;
  final double rollAngle;
  final double threshold;
  final AngleUnit unit;

  const DualAngleReadout({
    super.key,
    required this.pitchAngle,
    required this.rollAngle,
    required this.threshold,
    this.unit = AngleUnit.degrees,
  });

  Color _angleColor(double angle) {
    final abs = angle.abs();
    if (abs <= threshold) return AppColors.levelAchieved;
    if (abs <= threshold * 10) return AppColors.nearLevel;
    return AppColors.offLevel;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _AxisReadout(
          label: 'X',
          angle: rollAngle,
          unit: unit,
          color: _angleColor(rollAngle),
        ),
        const SizedBox(width: 40),
        _AxisReadout(
          label: 'Y',
          angle: pitchAngle,
          unit: unit,
          color: _angleColor(pitchAngle),
        ),
      ],
    );
  }
}

class _AxisReadout extends StatelessWidget {
  final String label;
  final double angle;
  final AngleUnit unit;
  final Color color;

  const _AxisReadout({
    required this.label,
    required this.angle,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppTextStyles.sectionHeader()),
        const SizedBox(height: 4),
        Text(
          Units.formatAngle(angle, unit),
          style: AppTextStyles.readoutSmall(fontSize: 32, color: color),
        ),
      ],
    );
  }
}

enum LevelStatus { off, near, achieved }
