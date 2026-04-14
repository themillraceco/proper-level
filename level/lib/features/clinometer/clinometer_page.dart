import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../core/theme.dart';
import '../../core/units.dart';
import '../../core/haptics.dart';
import '../../core/sensors.dart';
import '../../state/settings_provider.dart';
import '../../state/freeze_provider.dart';
import '../../widgets/toolbar.dart';

// Target angle state — null means no target set.
final _targetAngleProvider = StateProvider<double?>((ref) => null);

class ClinoPage extends ConsumerStatefulWidget {
  const ClinoPage({super.key});

  @override
  ConsumerState<ClinoPage> createState() => _ClinoPageState();
}

class _ClinoPageState extends ConsumerState<ClinoPage> {
  late LevelFeedbackController _haptic;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _haptic = LevelFeedbackController(
      isVibrationEnabled: () =>
          ref.read(settingsProvider).value?.vibrationEnabled ?? false,
    );
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _haptic.reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tiltAsync = ref.watch(tiltProvider);
    final settings = ref.watch(settingsProvider).value;
    final frozen = ref.watch(freezeProvider);
    final target = ref.watch(_targetAngleProvider);

    final tilt = tiltAsync.value ?? TiltReading.zero;
    final angle = tilt.inclination;
    final threshold = settings?.levelThreshold ?? 0.5;
    final unit = settings?.angleUnit ?? AngleUnit.degrees;

    // Haptic feedback for target angle hit
    if (target != null) {
      final delta = (angle - target).abs();
      if (delta <= threshold) {
        _haptic.update(LevelState.achieved, delta);
      } else if (delta <= threshold * 10) {
        _haptic.update(LevelState.near, delta);
      } else {
        _haptic.update(LevelState.off, delta);
      }
    }

    return SafeArea(
      child: Column(
        children: [
          // ── Top bar ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _showHelp(context),
                  child: Icon(Icons.help_outline,
                      size: 18, color: AppColors.textMuted),
                ),
                const SizedBox(width: 8),
                Text('CLINOMETER',
                    style: AppTextStyles.sectionHeader()),
                const Spacer(),
                ProperToolbar(onScreenshot: null),
              ],
            ),
          ),

          const Spacer(),

          // ── Giant angle readout ──────────────────────────────────────────
          GestureDetector(
            onTap: () => ref.read(freezeProvider.notifier).toggle(),
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Text(
                      Units.formatAngle(angle, unit),
                      style: AppTextStyles.readout(fontSize: 88),
                    ),
                    if (frozen)
                      Container(
                        margin: const EdgeInsets.all(4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color:
                                  AppColors.levelAchieved.withAlpha(80)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'HOLD',
                          style: AppTextStyles.sectionHeader().copyWith(
                              color: AppColors.levelAchieved,
                              fontSize: 9),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                // Visual slope line
                _SlopeIndicator(angle: angle),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ── Target angle row ─────────────────────────────────────────────
          if (target != null)
            _TargetRow(
              target: target,
              currentAngle: angle,
              threshold: threshold,
              unit: unit,
              onClear: () =>
                  ref.read(_targetAngleProvider.notifier).state = null,
            ),

          const SizedBox(height: 32),

          // ── Controls ─────────────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: _ClinoButton(
                    label: 'SET TARGET',
                    onTap: () => _showTargetPicker(context, angle, unit),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _UnitToggle(unit: unit),
                ),
              ],
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }

  void _showTargetPicker(
      BuildContext context, double currentAngle, AngleUnit unit) {
    final controller =
        TextEditingController(text: currentAngle.toStringAsFixed(1));
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Set Target Angle',
            style: AppTextStyles.label(
                fontSize: 16, color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          style: AppTextStyles.readoutSmall(
              fontSize: 28, color: AppColors.textPrimary),
          decoration: InputDecoration(
            suffix: Text(Units.unitLabel(unit),
                style:
                    AppTextStyles.label(color: AppColors.textSecondary)),
            enabledBorder: const UnderlineInputBorder(
                borderSide:
                    BorderSide(color: AppColors.border)),
            focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(
                    color: AppColors.levelAchieved)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null) {
                ref.read(_targetAngleProvider.notifier).state = value;
              }
              Navigator.pop(context);
            },
            child: const Text('SET'),
          ),
        ],
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Clinometer',
            style: AppTextStyles.label(
                fontSize: 16, color: AppColors.textPrimary)),
        content: Text(
          'Hold your phone with the edge flat against the surface you want to measure. The angle shown is the surface\'s inclination from horizontal.\n\nUse "Set Target" to lock a desired angle — the app will alert you when you hit it. Great for stair risers, roof pitches, and bevels.',
          style:
              AppTextStyles.label(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('GOT IT'),
          ),
        ],
      ),
    );
  }
}

// ── Slope line indicator ──────────────────────────────────────────────────────

class _SlopeIndicator extends StatelessWidget {
  final double angle; // degrees

  const _SlopeIndicator({required this.angle});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 40,
      child: CustomPaint(
        painter: _SlopePainter(angle: angle),
      ),
    );
  }
}

class _SlopePainter extends CustomPainter {
  final double angle;
  const _SlopePainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final len = size.width * 0.4;
    final rad = angle * math.pi / 180;

    final paint = Paint()
      ..color = AppColors.textMuted
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // Baseline (horizontal reference)
    canvas.drawLine(
        Offset(cx - len * 1.1, cy), Offset(cx + len * 1.1, cy), paint);

    // Slope line
    final slopePaint = Paint()
      ..color = AppColors.textPrimary
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx - len * math.cos(rad), cy + len * math.sin(rad)),
      Offset(cx + len * math.cos(rad), cy - len * math.sin(rad)),
      slopePaint,
    );
  }

  @override
  bool shouldRepaint(_SlopePainter old) => old.angle != angle;
}

// ── Target angle row ──────────────────────────────────────────────────────────

class _TargetRow extends StatelessWidget {
  final double target;
  final double currentAngle;
  final double threshold;
  final AngleUnit unit;
  final VoidCallback onClear;

  const _TargetRow({
    required this.target,
    required this.currentAngle,
    required this.threshold,
    required this.unit,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final delta = currentAngle - target;
    final onTarget = delta.abs() <= threshold;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(
          color: onTarget
              ? AppColors.levelAchieved.withAlpha(80)
              : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TARGET', style: AppTextStyles.sectionHeader()),
              const SizedBox(height: 2),
              Text(
                Units.formatAngle(target, unit),
                style: AppTextStyles.readoutSmall(
                    fontSize: 22,
                    color: onTarget
                        ? AppColors.levelAchieved
                        : AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('DELTA', style: AppTextStyles.sectionHeader()),
              const SizedBox(height: 2),
              Text(
                onTarget ? '✓ ON' : Units.formatDelta(delta, unit),
                style: AppTextStyles.readoutSmall(
                    fontSize: 22,
                    color: onTarget
                        ? AppColors.levelAchieved
                        : AppColors.textSecondary),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: onClear,
            child: Icon(Icons.close,
                size: 18, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ── Unit toggle ───────────────────────────────────────────────────────────────

class _UnitToggle extends ConsumerWidget {
  final AngleUnit unit;
  const _UnitToggle({required this.unit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        final next = unit == AngleUnit.degrees
            ? AngleUnit.percentGrade
            : AngleUnit.degrees;
        ref.read(settingsProvider.notifier).setAngleUnit(next);
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              unit == AngleUnit.degrees ? '°  DEG' : '%  GRADE',
              style: AppTextStyles.label(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 6),
            Icon(Icons.swap_horiz,
                size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _ClinoButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ClinoButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.sectionHeader().copyWith(
                color: AppColors.textSecondary, letterSpacing: 1.5),
          ),
        ),
      ),
    );
  }
}
