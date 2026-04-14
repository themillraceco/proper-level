import 'package:vibration/vibration.dart';

// Haptic feedback patterns for Proper Level.
//
// Philosophy: haptics are the primary alert channel when working in
// tight spots where you can't see the screen. Keep patterns distinct,
// non-annoying, and increasing in urgency as you approach level.

enum LevelState { off, near, achieved }

class HapticFeedback {
  HapticFeedback._();

  // Called continuously while approaching level; tempo increases as angle
  // decreases toward zero. Pass the current abs angle in degrees.
  static Future<void> approachingLevel(double absAngle) async {
    if (!await Vibration.hasVibrator()) return;

    // Only fire if angle is within 5° — outside that, silence.
    if (absAngle > 5.0) return;

    Vibration.vibrate(duration: 40, amplitude: 80);
    // Caller throttles via pulseIntervalMs() — see LevelFeedbackController.
  }

  static int pulseIntervalMs(double absAngle) {
    if (absAngle > 5.0) return 99999; // no pulse outside 5°
    return (300 + (absAngle / 5.0) * 1200).round();
  }

  // Sustained buzz when level is achieved.
  static Future<void> levelAchieved() async {
    if (!await Vibration.hasVibrator()) return;
    Vibration.vibrate(pattern: [0, 80, 60, 80], amplitude: 180);
  }

  // Double-tap for clinometer target angle match.
  static Future<void> targetMatched() async {
    if (!await Vibration.hasVibrator()) return;
    Vibration.vibrate(pattern: [0, 60, 80, 60], amplitude: 160);
  }

  // Cancel any ongoing vibration.
  static void cancel() {
    Vibration.cancel();
  }
}

// Tracks which haptic state was last fired so we don't spam the vibrator.
class LevelFeedbackController {
  LevelState _lastState = LevelState.off;
  DateTime _lastPulse = DateTime.fromMillisecondsSinceEpoch(0);
  final bool Function() isVibrationEnabled;

  LevelFeedbackController({required this.isVibrationEnabled});

  void update(LevelState newState, double absAngle) {
    if (!isVibrationEnabled()) {
      if (_lastState != LevelState.off) {
        HapticFeedback.cancel();
        _lastState = LevelState.off;
      }
      return;
    }

    if (newState == LevelState.achieved && _lastState != LevelState.achieved) {
      HapticFeedback.levelAchieved();
      _lastState = LevelState.achieved;
      return;
    }

    if (newState == LevelState.near) {
      final now = DateTime.now();
      final intervalMs = HapticFeedback.pulseIntervalMs(absAngle);
      if (now.difference(_lastPulse).inMilliseconds >= intervalMs) {
        HapticFeedback.approachingLevel(absAngle);
        _lastPulse = now;
      }
      _lastState = LevelState.near;
      return;
    }

    if (newState == LevelState.off && _lastState != LevelState.off) {
      HapticFeedback.cancel();
      _lastState = LevelState.off;
    }
  }

  void reset() {
    HapticFeedback.cancel();
    _lastState = LevelState.off;
    _lastPulse = DateTime.fromMillisecondsSinceEpoch(0);
  }
}

