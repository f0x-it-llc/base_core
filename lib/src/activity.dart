import 'package:signals/signals.dart';

/// Ref-counted activity (loading) tracking backed by signals.
///
/// Overlapping operations are counted, so [isLoading] stays `true` until the
/// last in-flight operation completes — no flicker when one operation ends
/// while another is still running.
class ActivityTracker {
  ActivityTracker();

  final Signal<int> _count = signal(0);
  bool _disposed = false;

  /// Number of operations currently in flight.
  late final ReadonlySignal<int> pending = _count.readonly();

  /// Whether at least one tracked operation is in flight.
  late final ReadonlySignal<bool> isLoading = computed(() => _count.value > 0);

  /// Runs [operation], keeping [isLoading] `true` for its duration.
  ///
  /// Counter updates are skipped once [dispose] has run, so an operation
  /// still in flight when the tracker is torn down completes without
  /// writing to a disposed signal.
  Future<T> track<T>(Future<T> Function() operation) async {
    if (!_disposed) _count.value++;
    try {
      return await operation();
    } finally {
      if (!_disposed) _count.value--;
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    isLoading.dispose();
    _count.dispose();
  }
}
