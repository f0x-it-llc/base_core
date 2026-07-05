/// Base class for domain failures.
///
/// A [Failure] describes *why* an operation could not produce a value. Model
/// your domain's failure modes as a sealed hierarchy extending this class so
/// callers can exhaustively `switch` over them:
///
/// ```dart
/// sealed class AppFailure extends Failure {
///   const AppFailure({super.message, super.cause, super.stackTrace});
/// }
///
/// final class NetworkFailure extends AppFailure {
///   const NetworkFailure({super.message, super.cause, super.stackTrace});
///
///   @override
///   bool get isRetryable => true;
/// }
/// ```
///
/// [Failure] implements [Exception] so a use case can `throw` one from deep
/// inside `execute` and have it surface as a `Failed` result — see
/// `UseCase.call`.
abstract class Failure implements Exception {
  const Failure({this.message, this.cause, this.stackTrace});

  /// Human-readable description of the failure.
  final String? message;

  /// The underlying error that caused this failure, if any.
  final Object? cause;

  /// Stack trace captured where the failure originated, if any.
  final StackTrace? stackTrace;

  /// Whether retrying the failed operation could plausibly succeed.
  ///
  /// Consulted by the default `RetryPolicy`. Override to return `true` for
  /// transient failures (timeouts, HTTP 5xx, dropped connections).
  bool get isRetryable => false;

  @override
  String toString() {
    final detail = message ?? cause?.toString();
    return detail == null ? '$runtimeType' : '$runtimeType: $detail';
  }
}

/// A failure produced from an error that no domain failure accounts for.
///
/// `UseCase.call` wraps any non-[Failure] object thrown by `execute` in an
/// [UnexpectedFailure], preserving the original error and stack trace.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({super.message, super.cause, super.stackTrace});
}
