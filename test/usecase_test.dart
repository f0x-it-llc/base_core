import 'package:clean_signals/clean_signals.dart';
import 'package:test/test.dart';

class NetworkFailure extends Failure {
  const NetworkFailure([String? message]) : super(message: message);

  @override
  bool get isRetryable => true;
}

class Doubler extends UseCase<int, int> {
  @override
  Future<Result<int>> execute(int params) async => Success(params * 2);
}

class ThrowsFailure extends UseCase<NoParams, int> {
  @override
  Future<Result<int>> execute(NoParams params) async =>
      throw const NetworkFailure('offline');
}

class ThrowsError extends UseCase<NoParams, int> {
  @override
  Future<Result<int>> execute(NoParams params) async =>
      throw FormatException('bad payload');
}

class CountingStream extends StreamUseCase<int, int> {
  @override
  Stream<Result<int>> execute(int params) async* {
    for (var i = 1; i <= params; i++) {
      yield Success(i);
    }
  }
}

class FailingStream extends StreamUseCase<NoParams, int> {
  @override
  Stream<Result<int>> execute(NoParams params) async* {
    yield const Success(1);
    throw StateError('stream died');
  }
}

void main() {
  group('UseCase.call', () {
    test('returns the result of execute', () async {
      expect(await Doubler()(21), const Success<int>(42));
    });

    test('converts a thrown Failure into Failed with the same failure',
        () async {
      final result = await ThrowsFailure()(noParams);
      expect(result.failureOrNull, isA<NetworkFailure>());
      expect(result.failureOrNull!.message, 'offline');
    });

    test('converts an unexpected error into UnexpectedFailure', () async {
      final result = await ThrowsError()(noParams);
      final failure = result.failureOrNull;
      expect(failure, isA<UnexpectedFailure>());
      expect(failure!.cause, isA<FormatException>());
      expect(failure.isRetryable, isFalse);
    });
  });

  group('StreamUseCase.call', () {
    test('forwards results', () async {
      expect(
        await CountingStream()(3).toList(),
        const [Success<int>(1), Success<int>(2), Success<int>(3)],
      );
    });

    test('converts stream errors into a trailing Failed event', () async {
      final events = await FailingStream()(noParams).toList();
      expect(events.first, const Success<int>(1));
      expect(events.last.failureOrNull, isA<UnexpectedFailure>());
      expect(events.last.failureOrNull!.cause, isA<StateError>());
    });
  });
}
