import 'package:base_core/base_core.dart';
import 'package:signals/signals.dart';
import 'package:test/test.dart';

class TestFailure extends Failure {
  const TestFailure([String? message]) : super(message: message);
}

void main() {
  group('Result', () {
    test('fold selects the correct branch', () {
      expect(
        const Success<int>(2)
            .fold(onSuccess: (v) => v * 10, onFailure: (_) => -1),
        20,
      );
      expect(
        const Failed<int>(TestFailure())
            .fold(onSuccess: (v) => v * 10, onFailure: (_) => -1),
        -1,
      );
    });

    test('map transforms success and passes failure through', () {
      expect(const Success<int>(2).map((v) => '$v'), const Success<String>('2'));

      const failure = TestFailure('boom');
      final mapped = const Failed<int>(failure).map((v) => '$v');
      expect(mapped, const Failed<String>(failure));
    });

    test('flatMap chains results', () {
      Result<int> half(int v) =>
          v.isEven ? Success(v ~/ 2) : const Failed(TestFailure('odd'));

      expect(const Success<int>(4).flatMap(half), const Success<int>(2));
      expect(const Success<int>(3).flatMap(half).isFailure, isTrue);
      expect(
        const Failed<int>(TestFailure()).flatMap(half).isFailure,
        isTrue,
      );
    });

    test('value and failure accessors', () {
      const failure = TestFailure();
      const success = Success<int>(1);
      const failed = Failed<int>(failure);

      expect(success.valueOrNull, 1);
      expect(success.failureOrNull, isNull);
      expect(success.requireValue, 1);
      expect(success.getOrElse((_) => 9), 1);

      expect(failed.valueOrNull, isNull);
      expect(failed.failureOrNull, failure);
      expect(() => failed.requireValue, throwsA(failure));
      expect(failed.getOrElse((_) => 9), 9);
    });

    test('exhaustive switch destructuring', () {
      const Result<int> result = Success(41);
      final out = switch (result) {
        Success(:final value) => value + 1,
        Failed() => 0,
      };
      expect(out, 42);
    });

    test('guard captures thrown failures and unexpected errors', () async {
      const failure = TestFailure();

      expect(await Result.guard(() async => 1), const Success<int>(1));
      expect(
        await Result.guard<int>(() async => throw failure),
        const Failed<int>(failure),
      );

      final unexpected = await Result.guard<int>(
        () async => throw StateError('nope'),
      );
      expect(unexpected.failureOrNull, isA<UnexpectedFailure>());
      expect(
        (unexpected.failureOrNull as UnexpectedFailure).cause,
        isA<StateError>(),
      );
    });

    test('toAsyncState maps to AsyncData / AsyncError', () {
      expect(const Success<int>(1).toAsyncState(), AsyncState.data(1));

      const failure = TestFailure('boom');
      final state = const Failed<int>(failure).toAsyncState();
      expect(state, isA<AsyncError<int>>());
      expect((state as AsyncError<int>).error, failure);
    });

    test('asyncSignal starts loading', () {
      final s = asyncStateSignal<int>();
      expect(s.value, isA<AsyncLoading<int>>());
    });
  });
}
