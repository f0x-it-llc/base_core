abstract class Failure {
  final String? message;

  Failure([this.message]);
}

extension OnFailures<T> on Stream<T> {
  Stream<T> whereFailures(List<dynamic> failures) {
    return where((failure) {
      if (failure == null) return true;
      return failures.any((f) => failure.runtimeType == f);
    });
  }
}

class RetryableFailure extends Failure {
  final dynamic params;
  final Type useCase;
  final Duration delay;

  RetryableFailure({
    required this.params,
    required this.useCase,
    String? message,
    this.delay = Duration.zero,
  }) : super(message);
}

/// Represents an unexpected failure
class UnexpectedFailure extends Failure {
  UnexpectedFailure(String message) : super(message);
}
