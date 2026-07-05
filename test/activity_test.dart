import 'dart:async';

import 'package:base_core/base_core.dart';
import 'package:test/test.dart';

void main() {
  group('ActivityTracker', () {
    test('isLoading reflects overlapping operations (ref-counted)', () async {
      final tracker = ActivityTracker();
      expect(tracker.isLoading.value, isFalse);

      final first = Completer<void>();
      final second = Completer<void>();

      final f1 = tracker.track(() => first.future);
      final f2 = tracker.track(() => second.future);
      expect(tracker.isLoading.value, isTrue);
      expect(tracker.pending.value, 2);

      first.complete();
      await f1;
      expect(tracker.isLoading.value, isTrue,
          reason: 'one operation still in flight');

      second.complete();
      await f2;
      expect(tracker.isLoading.value, isFalse);
      expect(tracker.pending.value, 0);

      tracker.dispose();
    });

    test('decrements even when the operation throws', () async {
      final tracker = ActivityTracker();

      await expectLater(
        tracker.track(() async => throw StateError('boom')),
        throwsStateError,
      );
      expect(tracker.isLoading.value, isFalse);

      tracker.dispose();
    });

    test('returns the operation result', () async {
      final tracker = ActivityTracker();
      expect(await tracker.track(() async => 7), 7);
      tracker.dispose();
    });
  });

  group('RetryPolicy', () {
    test('delayFor applies exponential backoff', () {
      const policy = RetryPolicy(
        maxAttempts: 4,
        delay: Duration(milliseconds: 100),
        backoffFactor: 2,
      );
      expect(policy.delayFor(1), const Duration(milliseconds: 100));
      expect(policy.delayFor(2), const Duration(milliseconds: 200));
      expect(policy.delayFor(3), const Duration(milliseconds: 400));
    });

    test('shouldRetry defaults to Failure.isRetryable and honours retryIf',
        () {
      const retryable = _Retryable();
      const plain = UnexpectedFailure(message: 'x');

      const byDefault = RetryPolicy(maxAttempts: 2);
      expect(byDefault.shouldRetry(retryable), isTrue);
      expect(byDefault.shouldRetry(plain), isFalse);

      final custom = RetryPolicy(
        maxAttempts: 2,
        retryIf: (f) => f is UnexpectedFailure,
      );
      expect(custom.shouldRetry(retryable), isFalse);
      expect(custom.shouldRetry(plain), isTrue);
    });
  });
}

class _Retryable extends Failure {
  const _Retryable();

  @override
  bool get isRetryable => true;
}
