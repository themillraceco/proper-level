import 'package:audioplayers/audioplayers.dart';

// Audio feedback for Proper Level.
//
// V1: requires assets/sounds/beep.mp3 to be present.
// If the file is absent, playback silently fails — no crash.
//
// TODO: add a 440Hz beep file at assets/sounds/beep.mp3
//       (short ~100ms, fade in/out, -6dBFS)
//
// The level-achieved tone plays once. The "approaching level" tone plays
// repeatedly with increasing tempo — handled by AudioFeedbackController.

class AudioFeedback {
  AudioFeedback._();

  static final AudioPlayer _player = AudioPlayer();
  static bool _initialized = false;

  static Future<void> _init() async {
    if (_initialized) return;
    await _player.setReleaseMode(ReleaseMode.stop);
    _initialized = true;
  }

  static Future<void> playBeep({double volume = 1.0}) async {
    try {
      await _init();
      await _player.setVolume(volume);
      await _player.play(AssetSource('sounds/beep.mp3'));
    } catch (_) {
      // Asset missing or audio unavailable — silent no-op for V1.
    }
  }

  static Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
  }

  static void dispose() {
    _player.dispose();
  }
}

class AudioFeedbackController {
  DateTime _lastBeep = DateTime.fromMillisecondsSinceEpoch(0);
  bool _levelHeld = false;
  final bool Function() isAudioEnabled;

  AudioFeedbackController({required this.isAudioEnabled});

  // Call every time the level state updates.
  // [absAngle] is in degrees; [threshold] is the "level achieved" threshold.
  void update({required double absAngle, required double threshold}) {
    if (!isAudioEnabled()) {
      AudioFeedback.stop();
      _levelHeld = false;
      return;
    }

    final isLevel = absAngle <= threshold;

    if (isLevel && !_levelHeld) {
      AudioFeedback.playBeep(volume: 1.0);
      _levelHeld = true;
      return;
    }

    if (!isLevel) {
      _levelHeld = false;

      if (absAngle <= 5.0) {
        // Tempo-based approach beeps — interval shrinks as angle → 0
        final intervalMs = (300 + (absAngle / 5.0) * 1200).round();
        final now = DateTime.now();
        if (now.difference(_lastBeep).inMilliseconds >= intervalMs) {
          AudioFeedback.playBeep(volume: 0.4 + 0.6 * (1 - absAngle / 5.0));
          _lastBeep = now;
        }
      }
    }
  }

  void reset() {
    AudioFeedback.stop();
    _levelHeld = false;
    _lastBeep = DateTime.fromMillisecondsSinceEpoch(0);
  }
}
