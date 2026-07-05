import 'package:clean_signals/clean_signals.dart';

/// Root of the app's failure hierarchy.
///
/// Sealed so that presentation code can exhaustively `switch` over every
/// failure mode the app can produce. Each failure knows the message that is
/// safe to show to a user.
sealed class AppFailure extends Failure {
  const AppFailure({super.message, super.cause, super.stackTrace});

  String get userMessage;
}

/// Transient connectivity / server failure. Retryable.
final class NetworkFailure extends AppFailure {
  const NetworkFailure({super.message, super.cause, super.stackTrace});

  @override
  bool get isRetryable => true;

  @override
  String get userMessage => 'Connection problem — please try again.';
}

/// The requested entity does not exist.
final class NotFoundFailure extends AppFailure {
  const NotFoundFailure({super.message});

  @override
  String get userMessage => "We couldn't find what you were looking for.";
}

/// User input rejected by domain rules. The message is user-facing.
final class ValidationFailure extends AppFailure {
  const ValidationFailure({required String super.message});

  @override
  String get userMessage => message!;
}

/// Maps any [Failure] (including clean_signals's [UnexpectedFailure]) to a
/// message suitable for a snackbar.
extension FailureMessage on Failure {
  String get userMessage => switch (this) {
        final AppFailure f => f.userMessage,
        _ => 'Something went wrong. Please try again.',
      };
}
