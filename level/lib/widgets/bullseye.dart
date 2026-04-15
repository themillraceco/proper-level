import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme.dart';

// 360° bullseye widget for surface level mode.
// [pitchAngle] and [rollAngle] are in degrees; both 0 = flat = centered.

class Bullseye extends StatelessWidget {
  final double pitchAngle; // Y axis (top/bottom tilt)
  final double rollAngle;  // X axis (left/right tilt)
  final double threshold;

  const Bullseye({
    super.key,
    required this.pitchAngle,
    required this.rollAngle,
    required this.threshold,
  });

  bool get _isLevel =>
      pitchAngle.abs() <= threshold && rollAngle.abs() <= threshold;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: TweenAnimationBuilder<Offset>(
        tween: Tween<Offset>(
          begin: Offset(rollAngle, pitchAngle),
          end: Offset(rollAngle, pitchAngle),
        ),
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        builder: (context, animatedOffset, _) {
          return CustomPaint(
            painter: _BullseyePainter(
              pitchAngle: animatedOffset.dy,
              rollAngle: animatedOffset.dx,
              threshold: threshold,
              isLevel: _isLevel,
            ),
          );
        },
      ),
    );
  }
}

class _BullseyePainter extends CustomPainter {
  final double pitchAngle;
  final double rollAngle;
  final double threshold;
  final bool isLevel;

  _BullseyePainter({
    required this.pitchAngle,
    required this.rollAngle,
    required this.threshold,
    required this.isLevel,
  });

  Color get _bubbleColor =>
      isLevel ? AppColors.levelAchieved : AppColors.offLevel;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - 4;

    // ── Outer circle ────────────────────────────────────────────────────────
    final bgPaint = Paint()..color = AppColors.surface;
    canvas.drawCircle(center, outerRadius, bgPaint);

    // ── Concentric precision rings ───────────────────────────────────────────
    // Rings represent ±0.5°, ±1°, ±2°, ±5°
    final ringAngles = [0.5, 1.0, 2.0, 5.0];
    for (final ringAngle in ringAngles) {
      final fraction = ringAngle / 5.0; // outermost ring = 5°
      final ringRadius = outerRadius * fraction;
      final isThresholdRing = ringAngle == threshold;
      final ringPaint = Paint()
        ..color = isThresholdRing
            ? AppColors.levelAchieved.withAlpha(80)
            : AppColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = isThresholdRing ? 1.5 : 1.0;
      canvas.drawCircle(center, ringRadius, ringPaint);
    }

    // ── Crosshairs ────────────────────────────────────────────────────────────
    final crossPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.0;
    canvas.drawLine(
      center.translate(-outerRadius, 0),
      center.translate(-outerRadius * 0.15, 0),
      crossPaint,
    );
    canvas.drawLine(
      center.translate(outerRadius * 0.15, 0),
      center.translate(outerRadius, 0),
      crossPaint,
    );
    canvas.drawLine(
      center.translate(0, -outerRadius),
      center.translate(0, -outerRadius * 0.15),
      crossPaint,
    );
    canvas.drawLine(
      center.translate(0, outerRadius * 0.15),
      center.translate(0, outerRadius),
      crossPaint,
    );

    // ── Outer border ─────────────────────────────────────────────────────────
    final borderPaint = Paint()
      ..color = isLevel
          ? AppColors.levelAchieved.withAlpha(120)
          : AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, outerRadius, borderPaint);

    // ── Bubble dot ───────────────────────────────────────────────────────────
    // Map angles to pixel offset within the outer ring.
    // 5° of tilt = reaches the outer ring edge.
    final maxOffset = outerRadius * 0.9;
    // Invert both axes so the bubble moves toward the "high" side
    final rawX = -(rollAngle / 5.0) * maxOffset;
    final rawY = -(pitchAngle / 5.0) * maxOffset;

    // Clamp to circle boundary
    final dist = math.sqrt(rawX * rawX + rawY * rawY);
    final clampedDist = dist.clamp(0, maxOffset);
    final angle = math.atan2(rawY, rawX);
    final bx = clampedDist * math.cos(angle);
    final by = clampedDist * math.sin(angle);

    final bubbleCenter = center.translate(bx, by);
    final bubbleRadius = outerRadius * 0.12;

    if (isLevel) {
      final glowPaint = Paint()
        ..color = AppColors.levelAchieved.withAlpha(50)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
      canvas.drawCircle(bubbleCenter, bubbleRadius * 2, glowPaint);
    }

    final bubbleFill = Paint()
      ..color = _bubbleColor.withAlpha(isLevel ? 230 : 180)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(bubbleCenter, bubbleRadius, bubbleFill);

    final bubbleRing = Paint()
      ..color = _bubbleColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(bubbleCenter, bubbleRadius, bubbleRing);

    // Glint
    final glint = Paint()
      ..color = Colors.white.withAlpha(60)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      bubbleCenter.translate(-bubbleRadius * 0.25, -bubbleRadius * 0.3),
      bubbleRadius * 0.3,
      glint,
    );
  }

  @override
  bool shouldRepaint(_BullseyePainter old) =>
      old.pitchAngle != pitchAngle ||
      old.rollAngle != rollAngle ||
      old.threshold != threshold ||
      old.isLevel != isLevel;
}
