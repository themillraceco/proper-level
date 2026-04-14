import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/sensors.dart';
import '../../core/units.dart';
import '../../state/settings_provider.dart';
import '../../state/sensor_provider.dart';
import '../calibration/calibration_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final calibration = ref.watch(calibrationProvider).value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Settings')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('Error loading settings', style: AppTextStyles.label())),
        data: (settings) => ListView(
          children: [
            // ── PRECISION ────────────────────────────────────────────────
            _SectionHeader(label: 'PRECISION'),
            _SliderTile(
              title: 'Level threshold',
              value: settings.levelThreshold,
              min: 0.1,
              max: 2.0,
              divisions: 19,
              displayValue: '${settings.levelThreshold.toStringAsFixed(1)}°',
              onChanged: (v) =>
                  ref.read(settingsProvider.notifier).setThreshold(v),
            ),
            _SegmentTile<Sensitivity>(
              title: 'Sensitivity',
              value: settings.sensitivity,
              options: Sensitivity.values,
              labelOf: (s) => s.label,
              onChanged: (v) {
                ref.read(settingsProvider.notifier).setSensitivity(v);
                ref.read(sensitivityProvider.notifier).state = v.alpha;
              },
            ),

            const _Divider(),

            // ── UNITS ─────────────────────────────────────────────────────
            _SectionHeader(label: 'UNITS'),
            _SegmentTile<AngleUnit>(
              title: 'Angle',
              value: settings.angleUnit,
              options: AngleUnit.values,
              labelOf: (u) => switch (u) {
                AngleUnit.degrees => 'Degrees',
                AngleUnit.percentGrade => '% Grade',
              },
              onChanged: (v) =>
                  ref.read(settingsProvider.notifier).setAngleUnit(v),
            ),
            _SegmentTile<DistanceUnit>(
              title: 'Distance',
              value: settings.distanceUnit,
              options: DistanceUnit.values,
              labelOf: (u) => switch (u) {
                DistanceUnit.metric => 'Metric',
                DistanceUnit.imperial => 'Imperial',
              },
              onChanged: (v) =>
                  ref.read(settingsProvider.notifier).setDistanceUnit(v),
            ),

            const _Divider(),

            // ── FEEDBACK ─────────────────────────────────────────────────
            _SectionHeader(label: 'FEEDBACK'),
            _SwitchTile(
              title: 'Audio',
              subtitle: 'Tone rises in pitch as you approach level',
              value: settings.audioEnabled,
              onChanged: (_) =>
                  ref.read(settingsProvider.notifier).toggleAudio(),
            ),
            _SwitchTile(
              title: 'Vibration',
              subtitle: 'Pulse tempo increases near level',
              value: settings.vibrationEnabled,
              onChanged: (_) =>
                  ref.read(settingsProvider.notifier).toggleVibration(),
            ),

            const _Divider(),

            // ── CALIBRATION ───────────────────────────────────────────────
            _SectionHeader(label: 'CALIBRATION'),
            if (calibration?.isCalibrated == true)
              _InfoTile(
                title: 'Calibrated',
                subtitle:
                    'Offset: X ${calibration!.xOffset.toStringAsFixed(3)}, '
                    'Y ${calibration.yOffset.toStringAsFixed(3)} m/s²',
                color: AppColors.levelAchieved,
              ),
            _ActionTile(
              title: 'Calibrate now',
              subtitle: 'Two-step sensor calibration',
              icon: Icons.tune_outlined,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CalibrationPage())),
            ),
            _ActionTile(
              title: 'Reset to factory',
              subtitle: 'Remove calibration offset',
              icon: Icons.restore_outlined,
              onTap: () => _confirmReset(context, ref),
              destructive: calibration?.isCalibrated == true,
            ),

            const _Divider(),

            // ── ABOUT ─────────────────────────────────────────────────────
            _SectionHeader(label: 'ABOUT'),
            _ActionTile(
              title: 'Help / How to use',
              icon: Icons.help_outline,
              onTap: () => _showHelp(context),
            ),
            _ActionTile(
              title: 'Open source licences',
              icon: Icons.code_outlined,
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'Proper Level',
                applicationVersion: '1.0.0',
              ),
            ),
            _ActionTile(
              title: 'Privacy',
              icon: Icons.privacy_tip_outlined,
              onTap: () => _showPrivacy(context),
            ),
            const _InfoTile(
              title: 'Proper Level',
              subtitle: 'Version 1.0.0 · ca.themillrace.proper.level',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Reset calibration?',
            style: AppTextStyles.label(
                fontSize: 16, color: AppColors.textPrimary)),
        content: Text(
            'This removes the calibration offset and restores factory defaults.',
            style: AppTextStyles.label(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              ref.read(calibrationProvider.notifier).reset();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
                foregroundColor: AppColors.offLevel),
            child: const Text('RESET'),
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
        title: Text('How to use Proper Level',
            style: AppTextStyles.label(
                fontSize: 16, color: AppColors.textPrimary)),
        content: SingleChildScrollView(
          child: Text(
            'LEVEL MODE\n'
            'The app automatically selects the right level type based on how you hold your phone:\n'
            '• Landscape → Horizontal level (checking shelves, countertops)\n'
            '• Portrait → Vertical level (checking walls, door frames)\n'
            '• Phone flat → Surface level 360° (countertops, appliances)\n\n'
            'CLINOMETER\n'
            'Measure any angle. Set a target angle to get alerts when you hit it.\n\n'
            'FREEZE / HOLD\n'
            'Tap the reading to freeze it. Tap again to unfreeze. '
            'Also works with the HOLD button in the toolbar. '
            'Volume-up button also toggles freeze.\n\n'
            'CALIBRATION\n'
            'Settings → Calibrate Now for the two-step sensor calibration. '
            'Corrects manufacturing variance in your phone\'s accelerometer.',
            style: AppTextStyles.label(color: AppColors.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('DONE'),
          ),
        ],
      ),
    );
  }

  void _showPrivacy(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Privacy',
            style: AppTextStyles.label(
                fontSize: 16, color: AppColors.textPrimary)),
        content: Text(
          'Proper Level collects no data. It does not require an account, '
          'internet access, or any permissions beyond sensor access and optional '
          'camera/flashlight hardware. Nothing leaves your device.\n\n'
          'The source code is available on GitHub under the MIT licence.',
          style: AppTextStyles.label(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('DONE'),
          ),
        ],
      ),
    );
  }
}

// ── Settings tile building blocks ────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) => Padding(
        padding:
            const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Text(label, style: AppTextStyles.sectionHeader()),
      );
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, color: AppColors.border);
}

class _SliderTile extends StatelessWidget {
  final String title;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String displayValue;
  final ValueChanged<double> onChanged;

  const _SliderTile({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.displayValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        title: Text(title,
            style:
                AppTextStyles.label(color: AppColors.textPrimary)),
        trailing: Text(displayValue,
            style: AppTextStyles.readoutSmall(
                fontSize: 16, color: AppColors.textSecondary)),
        subtitle: Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      );
}

class _SegmentTile<T> extends StatelessWidget {
  final String title;
  final T value;
  final List<T> options;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  const _SegmentTile({
    required this.title,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        title: Text(title,
            style:
                AppTextStyles.label(color: AppColors.textPrimary)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: SegmentedButton<T>(
            segments: options
                .map((o) => ButtonSegment<T>(
                      value: o,
                      label: Text(labelOf(o)),
                    ))
                .toList(),
            selected: {value},
            onSelectionChanged: (s) => onChanged(s.first),
            style: SegmentedButton.styleFrom(
              backgroundColor: AppColors.background,
              selectedBackgroundColor:
                  AppColors.levelAchieved.withAlpha(25),
              selectedForegroundColor: AppColors.levelAchieved,
              foregroundColor: AppColors.textSecondary,
            ),
          ),
        ),
      );
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => SwitchListTile(
        title: Text(title,
            style:
                AppTextStyles.label(color: AppColors.textPrimary)),
        subtitle: subtitle != null
            ? Text(subtitle!,
                style: AppTextStyles.label(
                    fontSize: 12,
                    color: AppColors.textMuted))
            : null,
        value: value,
        onChanged: onChanged,
      );
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;

  const _ActionTile({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon,
            size: 20,
            color: destructive
                ? AppColors.offLevel
                : AppColors.textSecondary),
        title: Text(title,
            style: AppTextStyles.label(
                color: destructive
                    ? AppColors.offLevel
                    : AppColors.textPrimary)),
        subtitle: subtitle != null
            ? Text(subtitle!,
                style: AppTextStyles.label(
                    fontSize: 12,
                    color: AppColors.textMuted))
            : null,
        trailing: const Icon(Icons.chevron_right,
            size: 16, color: AppColors.textMuted),
        onTap: onTap,
      );
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color? color;

  const _InfoTile({required this.title, this.subtitle, this.color});

  @override
  Widget build(BuildContext context) => ListTile(
        title: Text(title,
            style: AppTextStyles.label(
                color: color ?? AppColors.textPrimary)),
        subtitle: subtitle != null
            ? Text(subtitle!,
                style: AppTextStyles.label(
                    fontSize: 12,
                    color: AppColors.textMuted))
            : null,
      );
}
