import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../core/theme.dart';
import '../../core/audio.dart';
import '../../core/haptics.dart';
import '../../core/sensors.dart';
import '../../core/units.dart';
import '../../state/settings_provider.dart';
import '../../state/freeze_provider.dart';
import '../../widgets/bubble_vial.dart';
import '../../widgets/bullseye.dart';
import '../../widgets/angle_readout.dart';
import '../../widgets/toolbar.dart';

// ── Sub-mode detection ────────────────────────────────────────────────────────

enum LevelSubMode { horizontal, vertical, surface }

// Locked sub-mode override (null = AUTO).
final lockedSubModeProvider = StateProvider<LevelSubMode?>((ref) => null);

LevelSubMode _detectSubMode(TiltReading tilt, Orientation orientation) {
  if (tilt.isFlat) return LevelSubMode.surface;
  return orientation == Orientation.landscape
      ? LevelSubMode.horizontal
      : LevelSubMode.vertical;
}

// ── Level Page ────────────────────────────────────────────────────────────────

class LevelPage extends ConsumerStatefulWidget {
  const LevelPage({super.key});

  @override
  ConsumerState<LevelPage> createState() => _LevelPageState();
}

class _LevelPageState extends ConsumerState<LevelPage>
    with WidgetsBindingObserver {
  late AudioFeedbackController _audio;
  late LevelFeedbackController _haptic;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    WidgetsBinding.instance.addObserver(this);
    _audio = AudioFeedbackController(
      isAudioEnabled: () =>
          ref.read(settingsProvider).value?.audioEnabled ?? false,
    );
    _haptic = LevelFeedbackController(
      isVibrationEnabled: () =>
          ref.read(settingsProvider).value?.vibrationEnabled ?? false,
    );
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    WidgetsBinding.instance.removeObserver(this);
    _audio.reset();
    _haptic.reset();
    // Restore orientation
    SystemChrome.setPreferredOrientations([]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tiltAsync = ref.watch(tiltProvider);
    final settings = ref.watch(settingsProvider).value;
    final locked = ref.watch(lockedSubModeProvider);
    final frozen = ref.watch(freezeProvider);

    return OrientationBuilder(
      builder: (context, orientation) {
        final tilt = tiltAsync.value ?? TiltReading.zero;
        final subMode =
            locked ?? _detectSubMode(tilt, orientation);

        // Trigger audio & haptic feedback
        if (settings != null) {
          final angle = _relevantAngle(tilt, subMode);
          final threshold = settings.levelThreshold;
          _audio.update(absAngle: angle.abs(), threshold: threshold);

          final levelState = angle.abs() <= threshold
              ? LevelState.achieved
              : angle.abs() <= threshold * 10
                  ? LevelState.near
                  : LevelState.off;
          _haptic.update(levelState, angle.abs());
        }

        return GestureDetector(
          // Tap the entire readout area to toggle freeze
          onTap: () => ref.read(freezeProvider.notifier).toggle(),
          behavior: HitTestBehavior.opaque,
          child: _LevelScaffold(
            subMode: subMode,
            tilt: tilt,
            settings: settings,
            frozen: frozen,
            locked: locked,
          ),
        );
      },
    );
  }

  double _relevantAngle(TiltReading tilt, LevelSubMode mode) {
    return switch (mode) {
      LevelSubMode.horizontal => tilt.horizontalAngle,
      LevelSubMode.vertical => tilt.verticalAngle,
      LevelSubMode.surface =>
        // Worst-case axis for surface level
        tilt.surfacePitch.abs() > tilt.surfaceRoll.abs()
            ? tilt.surfacePitch
            : tilt.surfaceRoll,
    };
  }
}

// ── Scaffold ──────────────────────────────────────────────────────────────────

class _LevelScaffold extends ConsumerWidget {
  final LevelSubMode subMode;
  final TiltReading tilt;
  final AppSettings? settings;
  final bool frozen;
  final LevelSubMode? locked;

  const _LevelScaffold({
    required this.subMode,
    required this.tilt,
    required this.settings,
    required this.frozen,
    required this.locked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threshold = settings?.levelThreshold ?? 0.5;
    final unit = settings?.angleUnit ?? AngleUnit.degrees;

    return SafeArea(
      child: Column(
        children: [
          // ── Top bar ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            child: Row(
              children: [
                // Help icon (?) — stub for V1
                GestureDetector(
                  onTap: () => _showHelp(context, subMode),
                  child: Icon(Icons.help_outline,
                      size: 18, color: AppColors.textMuted),
                ),
                const SizedBox(width: 8),
                // Mode label
                Text(
                  _modeLabel(subMode),
                  style: AppTextStyles.sectionHeader(),
                ),
                const SizedBox(width: 8),
                // AUTO / LOCKED pill
                _SubModePill(locked: locked),
                const Spacer(),
                ProperToolbar(onScreenshot: () => _screenshot(context)),
              ],
            ),
          ),

          // ── Level instrument ─────────────────────────────────────────────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _buildInstrument(
                  key: ValueKey(subMode),
                  subMode: subMode,
                  tilt: tilt,
                  threshold: threshold,
                  unit: unit,
                  frozen: frozen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstrument({
    required Key key,
    required LevelSubMode subMode,
    required TiltReading tilt,
    required double threshold,
    required AngleUnit unit,
    required bool frozen,
  }) {
    switch (subMode) {
      case LevelSubMode.horizontal:
        return _HorizontalLevel(
          key: key,
          tilt: tilt,
          threshold: threshold,
          unit: unit,
          frozen: frozen,
        );
      case LevelSubMode.vertical:
        return _VerticalLevel(
          key: key,
          tilt: tilt,
          threshold: threshold,
          unit: unit,
          frozen: frozen,
        );
      case LevelSubMode.surface:
        return _SurfaceLevel(
          key: key,
          tilt: tilt,
          threshold: threshold,
          unit: unit,
          frozen: frozen,
        );
    }
  }

  String _modeLabel(LevelSubMode mode) => switch (mode) {
        LevelSubMode.horizontal => 'HORIZONTAL',
        LevelSubMode.vertical => 'VERTICAL',
        LevelSubMode.surface => 'SURFACE',
      };

  void _showHelp(BuildContext context, LevelSubMode mode) {
    final (title, body) = switch (mode) {
      LevelSubMode.horizontal => (
          'Horizontal Level',
          'Hold your phone in landscape with the edge resting on the surface you want to check. The bubble moves left and right. Center it for a perfectly level reading.',
        ),
      LevelSubMode.vertical => (
          'Vertical Level',
          'Hold your phone in portrait with the edge against the wall, stud, or door frame. The bubble moves left and right. Center it for a perfectly plumb reading.',
        ),
      LevelSubMode.surface => (
          'Surface Level (360°)',
          'Place your phone flat on any surface — countertop, appliance, tile bed. The dot should sit in the center ring for level in all directions.',
        ),
    };
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title,
            style: AppTextStyles.label(fontSize: 16, color: AppColors.textPrimary)),
        content: Text(body,
            style: AppTextStyles.label(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('GOT IT'),
          ),
        ],
      ),
    );
  }

  void _screenshot(BuildContext context) {
    // TODO: implement with screenshot package in Phase 4
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surface,
        content: Text('Screenshot coming soon.',
            style: AppTextStyles.label(color: AppColors.textSecondary)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ── Sub-mode override pill ────────────────────────────────────────────────────

class _SubModePill extends ConsumerWidget {
  final LevelSubMode? locked;
  const _SubModePill({required this.locked});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showOverrideSheet(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              locked == null ? 'AUTO' : locked!.name.toUpperCase(),
              style: AppTextStyles.sectionHeader()
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(width: 3),
            Icon(Icons.keyboard_arrow_down,
                size: 12, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  void _showOverrideSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ModeOption(
                label: 'Auto-detect',
                active: ref.watch(lockedSubModeProvider) == null,
                onTap: () {
                  ref.read(lockedSubModeProvider.notifier).state = null;
                  Navigator.pop(context);
                }),
            for (final mode in LevelSubMode.values)
              _ModeOption(
                label: mode.name[0].toUpperCase() + mode.name.substring(1),
                active: ref.watch(lockedSubModeProvider) == mode,
                onTap: () {
                  ref.read(lockedSubModeProvider.notifier).state = mode;
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ModeOption({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label,
          style: AppTextStyles.label(
              fontSize: 15,
              color: active ? AppColors.levelAchieved : AppColors.textPrimary)),
      trailing: active
          ? const Icon(Icons.check, color: AppColors.levelAchieved, size: 18)
          : null,
      onTap: onTap,
    );
  }
}

// ── Horizontal Level ──────────────────────────────────────────────────────────

class _HorizontalLevel extends StatelessWidget {
  final TiltReading tilt;
  final double threshold;
  final AngleUnit unit;
  final bool frozen;

  const _HorizontalLevel({
    super.key,
    required this.tilt,
    required this.threshold,
    required this.unit,
    required this.frozen,
  });

  @override
  Widget build(BuildContext context) {
    final angle = tilt.horizontalAngle;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            children: [
              Container(width: 20, height: 1.5, color: AppColors.border),
              const SizedBox(width: 4),
              Expanded(
                child: BubbleVial(
                  angle: angle,
                  threshold: threshold,
                  horizontal: true,
                ),
              ),
              const SizedBox(width: 4),
              Container(width: 20, height: 1.5, color: AppColors.border),
            ],
          ),
        ),
        const SizedBox(height: 40),
        _FreezeableReadout(
          frozen: frozen,
          child: AngleReadout(
            angle: angle,
            threshold: threshold,
            unit: unit,
          ),
        ),
      ],
    );
  }
}

// ── Vertical Level ────────────────────────────────────────────────────────────

class _VerticalLevel extends StatelessWidget {
  final TiltReading tilt;
  final double threshold;
  final AngleUnit unit;
  final bool frozen;

  const _VerticalLevel({
    super.key,
    required this.tilt,
    required this.threshold,
    required this.unit,
    required this.frozen,
  });

  @override
  Widget build(BuildContext context) {
    final angle = tilt.verticalAngle;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          children: [
            Container(width: 1.5, height: 20, color: AppColors.border),
            const SizedBox(height: 4),
            Expanded(
              child: BubbleVial(
                angle: angle,
                threshold: threshold,
                horizontal: false,
              ),
            ),
            const SizedBox(height: 4),
            Container(width: 1.5, height: 20, color: AppColors.border),
          ],
        ),
        const SizedBox(width: 48),
        _FreezeableReadout(
          frozen: frozen,
          child: AngleReadout(
            angle: angle,
            threshold: threshold,
            unit: unit,
          ),
        ),
      ],
    );
  }
}

// ── Surface Level ─────────────────────────────────────────────────────────────

class _SurfaceLevel extends StatelessWidget {
  final TiltReading tilt;
  final double threshold;
  final AngleUnit unit;
  final bool frozen;

  const _SurfaceLevel({
    super.key,
    required this.tilt,
    required this.threshold,
    required this.unit,
    required this.frozen,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Bullseye(
            pitchAngle: tilt.surfacePitch,
            rollAngle: tilt.surfaceRoll,
            threshold: threshold,
          ),
        ),
        const SizedBox(height: 40),
        _FreezeableReadout(
          frozen: frozen,
          child: DualAngleReadout(
            pitchAngle: tilt.surfacePitch,
            rollAngle: tilt.surfaceRoll,
            threshold: threshold,
            unit: unit,
          ),
        ),
      ],
    );
  }
}

// ── Freeze indicator wrapper ──────────────────────────────────────────────────

class _FreezeableReadout extends StatelessWidget {
  final Widget child;
  final bool frozen;

  const _FreezeableReadout({required this.child, required this.frozen});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        child,
        if (frozen)
          Container(
            margin: const EdgeInsets.only(top: 0, right: 0),
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.levelAchieved.withAlpha(20),
              border: Border.all(
                  color: AppColors.levelAchieved.withAlpha(80)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'HOLD',
              style: AppTextStyles.sectionHeader()
                  .copyWith(color: AppColors.levelAchieved, fontSize: 9),
            ),
          ),
      ],
    );
  }
}
