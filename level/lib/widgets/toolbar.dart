import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:torch_light/torch_light.dart';
import '../core/theme.dart';
import '../state/settings_provider.dart';
import '../state/freeze_provider.dart';

// Persistent top toolbar: flash · audio · vibe · FREEZE · screenshot
// All toggles. Freeze is the dominant one with a larger hit area.
// [onScreenshot] is called when the camera icon is tapped.

class ProperToolbar extends ConsumerWidget {
  final VoidCallback? onScreenshot;

  const ProperToolbar({super.key, this.onScreenshot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value;
    final frozen = ref.watch(freezeProvider);

    if (settings == null) return const SizedBox.shrink();

    return Row(
      children: [
        _ToolbarIcon(
          icon: Icons.flashlight_on_outlined,
          active: settings.flashlightOn,
          onTap: () => _toggleFlashlight(ref, settings),
        ),
        _ToolbarIcon(
          icon: settings.audioEnabled
              ? Icons.volume_up_outlined
              : Icons.volume_off_outlined,
          active: settings.audioEnabled,
          onTap: () =>
              ref.read(settingsProvider.notifier).toggleAudio(),
        ),
        _ToolbarIcon(
          icon: Icons.vibration_outlined,
          active: settings.vibrationEnabled,
          onTap: () =>
              ref.read(settingsProvider.notifier).toggleVibration(),
        ),
        // Freeze — larger, more prominent
        _FreezeButton(frozen: frozen),
        _ToolbarIcon(
          icon: Icons.photo_camera_outlined,
          active: false,
          onTap: onScreenshot,
          tooltip: 'Screenshot',
        ),
      ],
    );
  }

  Future<void> _toggleFlashlight(WidgetRef ref, AppSettings settings) async {
    final newState = !settings.flashlightOn;
    try {
      if (newState) {
        await TorchLight.enableTorch();
      } else {
        await TorchLight.disableTorch();
      }
      ref.read(settingsProvider.notifier).setFlashlight(newState);
    } catch (_) {
      // Device has no torch or permission denied — ignore silently.
    }
  }
}

class _ToolbarIcon extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback? onTap;
  final String? tooltip;

  const _ToolbarIcon({
    required this.icon,
    required this.active,
    this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.iconActive : AppColors.iconInactive;
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}

class _FreezeButton extends ConsumerWidget {
  final bool frozen;
  const _FreezeButton({required this.frozen});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => ref.read(freezeProvider.notifier).toggle(),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: frozen
              ? AppColors.levelAchieved.withAlpha(25)
              : Colors.transparent,
          border: Border.all(
            color: frozen ? AppColors.levelAchieved : AppColors.border,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              frozen ? Icons.lock_outline : Icons.lock_open_outlined,
              color: frozen ? AppColors.levelAchieved : AppColors.iconInactive,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              'HOLD',
              style: AppTextStyles.sectionHeader().copyWith(
                color: frozen
                    ? AppColors.levelAchieved
                    : AppColors.iconInactive,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
