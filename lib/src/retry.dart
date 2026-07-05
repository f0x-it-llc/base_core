import 'dart:math' as math;

import 'failure.dart';

/// Declarative retry behaviour for a single use-case invocation.
///
/// Passed per call to `Controller.run`, so each operation owns its retry
/// state — there is no shared global counter.
///
/// ```dart
/// run(getUser, userId, retry: const RetryPolicy(maxAttempts: 3));
/// ```
class RetryPolicy {
  const RetryPolicy({
    this.maxAttempts = 1,
    this.delay = const Duration(milliseconds: 300),
    this.backoffFactor = 2.0,
    this.retryIf,
  }) : assert(maxAttempts >= 1, 'maxAttempts must be at least 1');

  /// No retries: the operation runs exactly once.
  static const RetryPolicy none = RetryPolicy();

  /// Total number of attempts, including the first one.
  final int maxAttempts;

  /// Delay before the first retry.
  final Duration delay;

  /// Multiplier applied to [delay] for each subsequent retry
  /// (exponential backoff). Use `1.0` for a fixed delay.
  final double backoffFactor;

  /// Predicate deciding whether a given failure is worth retrying.
  /// Defaults to [Failure.isRetryable].
  final bool Function(Failure failure)? retryIf;

  /// Whether [failure] should be retried under this policy.
  bool shouldRetry(Failure failure) =>
      retryIf?.call(failure) ?? failure.isRetryable;

  /// Delay before retry number [retryNumber] (1-based).
  Duration delayFor(int retryNumber) => Duration(
        microseconds: (delay.inMicroseconds *
                math.pow(backoffFactor, retryNumber - 1))
            .round(),
      );
}
