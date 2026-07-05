import 'dart:async';

import 'package:clean_signals/clean_signals.dart';
import 'package:signals/signals.dart';
import 'package:test/test.dart';

class NetworkFailure extends Failure {
  const NetworkFailure([String? message]) : super(message: message);

  @override
  bool get isRetryable => true;
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([String? message]) : super(message: message);
}

/// Succeeds only after [failuresBeforeSuccess] failed attempts.
class FlakyUseCase extends UseCase<int, int> {
  FlakyUseCase(this.failuresBeforeSuccess, {this.failure = const NetworkFailure()});

  final int failuresBeforeSuccess;
  final Failure failure;
  int attempts = 0;

  @override
  Future<Result<int>> execute(int params) async {
    attempts++;
    if (attempts <= failuresBeforeSuccess) return Failed(failure);
    return Success(params);
  }
}

class SlowUseCase extends UseCase<NoParams, int> {
  SlowUseCase(this.gate);

  final Completer<void> gate;

  @override
  Future<Result<int>> execute(NoParams params) async {
    await gate.future;
    return const Success(5);
  }
}

class TickerUseCase extends StreamUseCase<int, int> {
  @override
  Stream<Result<int>> execute(int params) async* {
    for (var i = 1; i <= params; i++) {
      yield Success(i);
    }
    yield const Failed(NetworkFailure('tick lost'));
  }
}

class TestController extends Controller {
  Future<Result<R>> exec<P, R>(
    UseCase<P, R> useCase,
    P params, {
    RetryPolicy retry = RetryPolicy.none,
    bool emitFailure = true,
  }) =>
      run(useCase, params, retry: retry, emitFailure: emitFailure);

  Future<Result<R>> execInto<P, R>(
    UseCase<P, R> useCase,
    P params, {
    required Signal<AsyncState<R>> into,
  }) =>
      runInto(useCase, params, into: into);

  StreamSubscription<Result<R>> listen<P, R>(
    StreamUseCase<P, R> useCase,
    P params, {
    required void Function(R) onData,
  }) =>
      watch(useCase, params, onData: onData);

  void addCleanup(void Function() fn) => onDispose(fn);
}

void main() {
  group('Controller.run', () {
    test('returns success and does not emit failures', () async {
      final controller = TestController();
      final failures = <Failure>[];
      controller.failures.listen(failures.add);

      final result = await controller.exec(FlakyUseCase(0), 42);
      expect(result, const Success<int>(42));

      await Future<void>.delayed(Duration.zero);
      expect(failures, isEmpty);
      controller.dispose();
    });

    test('tracks isLoading while running', () async {
      final controller = TestController();
      final gate = Completer<void>();

      final pending = controller.exec(SlowUseCase(gate), noParams);
      await Future<void>.delayed(Duration.zero);
      expect(controller.isLoading.value, isTrue);

      gate.complete();
      await pending;
      expect(controller.isLoading.value, isFalse);
      controller.dispose();
    });

    test('emits the failure on the failures stream', () async {
      final controller = TestController();
      final failures = <Failure>[];
      controller.failures.listen(failures.add);

      final result = await controller.exec(
        FlakyUseCase(99, failure: const NotFoundFailure('missing')),
        1,
      );
      expect(result.isFailure, isTrue);

      await Future<void>.delayed(Duration.zero);
      expect(failures, hasLength(1));
      expect(failures.single, isA<NotFoundFailure>());
      controller.dispose();
    });

    test('emitFailure: false keeps the failure local', () async {
      final controller = TestController();
      final failures = <Failure>[];
      controller.failures.listen(failures.add);

      await controller.exec(FlakyUseCase(99), 1, emitFailure: false);
      await Future<void>.delayed(Duration.zero);
      expect(failures, isEmpty);
      controller.dispose();
    });

    test('retries retryable failures up to maxAttempts and succeeds',
        () async {
      final controller = TestController();
      final useCase = FlakyUseCase(2);

      final result = await controller.exec(
        useCase,
        7,
        retry: const RetryPolicy(
          maxAttempts: 3,
          delay: Duration(milliseconds: 1),
        ),
      );

      expect(result, const Success<int>(7));
      expect(useCase.attempts, 3);
      controller.dispose();
    });

    test('stops retrying when attempts are exhausted, emitting one failure',
        () async {
      final controller = TestController();
      final useCase = FlakyUseCase(99);
      final failures = <Failure>[];
      controller.failures.listen(failures.add);

      final result = await controller.exec(
        useCase,
        7,
        retry: const RetryPolicy(
          maxAttempts: 3,
          delay: Duration(milliseconds: 1),
        ),
      );

      expect(result.isFailure, isTrue);
      expect(useCase.attempts, 3);

      await Future<void>.delayed(Duration.zero);
      expect(failures, hasLength(1), reason: 'only the final failure is emitted');
      controller.dispose();
    });

    test('does not retry non-retryable failures', () async {
      final controller = TestController();
      final useCase = FlakyUseCase(99, failure: const NotFoundFailure());

      await controller.exec(
        useCase,
        7,
        retry: const RetryPolicy(
          maxAttempts: 5,
          delay: Duration(milliseconds: 1),
        ),
      );
      expect(useCase.attempts, 1);
      controller.dispose();
    });
  });

  group('Controller.runInto', () {
    test('drives loading → data', () async {
      final controller = TestController();
      final state = asyncStateSignal<int>();
      final gate = Completer<void>();

      final pending =
          controller.execInto(SlowUseCase(gate), noParams, into: state);
      expect(state.value, isA<AsyncLoading<int>>());

      gate.complete();
      await pending;
      expect(state.value, AsyncState.data(5));
      controller.dispose();
    });

    test('keeps existing data visible while reloading', () async {
      final controller = TestController();
      final state = asyncStateSignal<int>();

      await controller.execInto(FlakyUseCase(0), 1, into: state);
      expect(state.value, AsyncState.data(1));

      final gate = Completer<void>();
      final pending =
          controller.execInto(SlowUseCase(gate), noParams, into: state);
      expect(state.value.isLoading, isTrue);
      expect(state.value.hasValue, isTrue, reason: 'stale data stays visible');
      expect(state.value.requireValue, 1);

      gate.complete();
      await pending;
      expect(state.value, AsyncState.data(5));
      controller.dispose();
    });

    test('drives loading → error on failure', () async {
      final controller = TestController();
      final state = asyncStateSignal<int>();

      await controller.execInto(FlakyUseCase(99), 1, into: state);
      expect(state.value, isA<AsyncError<int>>());
      expect((state.value as AsyncError<int>).error, isA<NetworkFailure>());
      controller.dispose();
    });
  });

  group('Controller.watch', () {
    test('routes stream successes to onData and failures to failures stream',
        () async {
      final controller = TestController();
      final values = <int>[];
      final failures = <Failure>[];
      controller.failures.listen(failures.add);

      controller.listen(TickerUseCase(), 3, onData: values.add);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(values, [1, 2, 3]);
      expect(failures, hasLength(1));
      controller.dispose();
    });

    test('dispose cancels watched streams', () async {
      final controller = TestController();
      final values = <int>[];

      controller.listen(TickerUseCase(), 1000, onData: values.add);
      controller.dispose();
      final seen = values.length;

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(values.length, seen, reason: 'no events after dispose');
    });
  });

  group('Controller.dispose', () {
    test('runs cleanups in reverse order and is idempotent', () {
      final controller = TestController();
      final order = <String>[];
      controller.addCleanup(() => order.add('first'));
      controller.addCleanup(() => order.add('second'));

      controller.dispose();
      controller.dispose();
      expect(order, ['second', 'first']);
    });
  });
}
