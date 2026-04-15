import 'package:flutter/material.dart';
import '../core/theme.dart';

// A spirit level vial widget — the glass tube with a bubble.
// Set [horizontal] = true for a horizontal vial, false for a vertical vial.
// [angle] is in degrees; 0 = bubble centered = level.

class BubbleVial extends StatelessWidget {
  final double angle; // degrees, 0 = level
  final double threshold; // degrees — level achieved
  final bool horizontal;

  const BubbleVial({
    super.key,
    required this.angle,
    required this.threshold,
    this.horizontal = true,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: angle, end: angle),
      duration: const Duration(milliseconds: 80),
      curve: Curves.easeOutCubic,
      builder: (context, animatedAngle, _) {
        return horizontal
            ? SizedBox(
                width: double.infinity,
                height: 72,
                child: CustomPaint(
                  painter: _VialPainter(
                    angle: animatedAngle,
                    threshold: threshold,
                    horizontal: true,
                  ),
                ),
              )
            : SizedBox(
                width: 72,
                height: double.infinity,
                child: CustomPaint(
                  painter: _VialPainter(
                    angle: animatedAngle,
                    threshold: threshold,
                    horizontal: false,
                  ),
                ),
              );
      },
    );
  }
}

class _VialPainter extends CustomPainter {
  final double angle;
  final double threshold;
  final bool horizontal;

  _VialPainter({
    required this.angle,
    required this.threshold,
    required this.horizontal,
  });

  Color get _bubbleColor {
    final abs = angle.abs();
    if (abs <= threshold) return AppColors.levelAchieved;
    if (abs <= threshold * 10) return AppColors.nearLevel;
    return AppColors.offLevel;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final isLevel = angle.abs() <= threshold;

    // ── Vial tube ──────────────────────────────────────────────────────────
    final tubeRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final tubeRRect =
        RRect.fromRectAndRadius(tubeRect, const Radius.circular(36));

    // Background
    final bgPaint = Paint()..color = AppColors.surface;
    canvas.drawRRect(tubeRRect, bgPaint);

    // Border
    final borderPaint = Paint()
      ..color = isLevel ? AppColors.levelAchieved.withAlpha(100) : AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(tubeRRect, borderPaint);

    // Center tick marks
    _drawCenterTicks(canvas, size);

    // ── Bubble ─────────────────────────────────────────────────────────────
    final bubbleRadius = horizontal
        ? (size.height / 2) * 0.62
        : (size.width / 2) * 0.62;

    // Map angle to pixel offset. Clamp to 90% of travel range.
    final maxOffset = (horizontal ? size.width : size.height) / 2 -
        bubbleRadius -
        4;

    // Scale: 1° ≈ 12px of bubble movement, clamped.
    final rawOffset = (angle / 30.0) * maxOffset;
    final offset = rawOffset.clamp(-maxOffset, maxOffset);

    final center = horizontal
        ? Offset(size.width / 2 + offset, size.height / 2)
        : Offset(size.width / 2, size.height / 2 + offset);

    // Bubble fill
    final bubbleFill = Paint()
      ..color = _bubbleColor.withAlpha(isLevel ? 230 : 180)
      ..style = PaintingStyle.fill;

    // Subtle glow when level
    if (isLevel) {
      final glowPaint = Paint()
        ..color = AppColors.levelAchieved.withAlpha(40)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(center, bubbleRadius * 1.4, glowPaint);
    }

    canvas.drawCircle(center, bubbleRadius, bubbleFill);

    // Bubble ring
    final bubbleRing = Paint()
      ..color = _bubbleColor.withAlpha(isLevel ? 255 : 120)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, bubbleRadius, bubbleRing);

    // Highlight (inner glint)
    final glint = Paint()
      ..color = Colors.white.withAlpha(60)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      center + Offset(-bubbleRadius * 0.25, -bubbleRadius * 0.3),
      bubbleRadius * 0.3,
      glint,
    );
  }

  void _drawCenterTicks(Canvas canvas, Size size) {
    final tickPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.0;

    if (horizontal) {
      // Vertical tick at center top and center bottom
      final cx = size.width / 2;
      canvas.drawLine(Offset(cx, 4), Offset(cx, size.height * 0.35), tickPaint);
      canvas.drawLine(
          Offset(cx, size.height * 0.65), Offset(cx, size.height - 4), tickPaint);
    } else {
      final cy = size.height / 2;
      canvas.drawLine(Offset(4, cy), Offset(size.width * 0.35, cy), tickPaint);
      canvas.drawLine(
          Offset(size.width * 0.65, cy), Offset(size.width - 4, cy), tickPaint);
    }
  }

  @override
  bool shouldRepaint(_VialPainter old) =>
      old.angle != angle ||
      old.threshold != threshold ||
      old.horizontal != horizontal;
}

// Extension arms on either side of the vial (the visual "rails")
class VialRails extends StatelessWidget {
  final bool horizontal;
  const VialRails({super.key, this.horizontal = true});

  @override
  Widget build(BuildContext context) {
    if (horizontal) {
      return Row(
        children: [
          Container(width: 24, height: 2, color: AppColors.border),
          const Expanded(child: SizedBox()),
          Container(width: 24, height: 2, color: AppColors.border),
        ],
      );
    }
    return Column(
      children: [
        Container(width: 2, height: 24, color: AppColors.border),
        const Expanded(child: SizedBox()),
        Container(width: 2, height: 24, color: AppColors.border),
      ],
    );
  }
}
