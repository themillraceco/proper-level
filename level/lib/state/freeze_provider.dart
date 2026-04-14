import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/sensors.dart';
import 'sensor_provider.dart';

// Freeze state — when frozen, the last TiltReading is held.
// When unfrozen, live sensor data flows through.

class FreezeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void freeze() => state = true;
  void unfreeze() => state = false;
  void toggle() => state = !state;
}

final freezeProvider =
    NotifierProvider<FreezeNotifier, bool>(FreezeNotifier.new);

// Holds the last-known reading when freeze is activated.
final _frozenReadingProvider = StateProvider<TiltReading?>((ref) => null);

// The single reading that all UI widgets consume.
// Returns the frozen reading when frozen, live reading otherwise.
final tiltProvider = Provider<AsyncValue<TiltReading>>((ref) {
  final frozen = ref.watch(freezeProvider);

  if (frozen) {
    final snapshot = ref.read(_frozenReadingProvider);
    if (snapshot != null) {
      return AsyncData(snapshot);
    }
    // Freeze was triggered before first reading — fall through to live.
  }

  final live = ref.watch(rawTiltProvider);

  // Keep the frozen-reading cache up to date while not frozen.
  live.whenData((reading) {
    if (!frozen) {
      ref.read(_frozenReadingProvider.notifier).state = reading;
    }
  });

  return live;
});
