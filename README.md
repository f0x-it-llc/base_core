# Base Core

A lightweight use-case and controller framework for [signals](https://pub.dev/packages/signals)-based Flutter and Dart applications.

Typed results, sealed failures, ref-counted loading state and declarative retries — in a few hundred lines of pure Dart, with no rxdart, no dartz, and no Flutter dependency in the core.

## Philosophy

- **Business logic lives in use cases.** Small, testable units that always return a `Result` — never throw across a layer boundary.
- **State is signals.** Controllers own fine-grained `signal`/`computed` state; widgets rebuild only for what they read.
- **Failures are data.** A sealed `Failure` hierarchy your UI can exhaustively `switch` over, with one broadcast stream per controller for global handling (snackbars, reporting).
- **No magic registry.** v1's type-keyed use-case registry is gone; controllers call use cases as plain typed fields. The compiler is the registry.

## Installation

```yaml
dependencies:
  base_core: ^2.0.0
  signals: ^7.0.0
```

## Core concepts

### Failure

Model your domain's failure modes as a sealed hierarchy. `isRetryable` feeds the default retry policy.

```dart
sealed class AppFailure extends Failure {
  const AppFailure({super.message, super.cause, super.stackTrace});
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure({super.message, super.cause, super.stackTrace});

  @override
  bool get isRetryable => true;
}
```

`Failure` implements `Exception`, so lower layers may `throw` one — the use-case wrapper converts it into a result.

### Result

A sealed union of `Success<T>` and `Failed<T>` with the usual combinators (`fold`, `map`, `flatMap`, `getOrElse`) and exhaustive pattern matching:

```dart
switch (result) {
  case Success(:final value): render(value);
  case Failed(:final failure): report(failure);
}
```

`result.toAsyncState()` bridges into signals' `AsyncState` for UI consumption, and `asyncStateSignal<T>()` creates a `Signal<AsyncState<T>>` seeded with loading.

### UseCase

```dart
class GetMembers extends UseCase<NoParams, List<Member>> {
  GetMembers(this._repository);

  final MemberRepository _repository;

  @override
  Future<Result<List<Member>>> execute(NoParams params) async =>
      Success(await _repository.getMembers());
}
```

Calling a use case (`await getMembers(noParams)`) is guarded: thrown `Failure`s become `Failed`, anything else becomes `Failed(UnexpectedFailure(...))`. Callers always get a `Result`.

`StreamUseCase<P, R>` is the streaming variant — error events on the source stream are converted to `Failed` events instead of crashing the subscription.

Use Dart 3 records for multi-value params (this is what dartz's `Tuple2` used to do):

```dart
typedef UpdateNameParams = ({String id, String name});

class UpdateMemberName extends UseCase<UpdateNameParams, Member> { ... }
```

### Controller

The presentation-layer base class. Owns signals, executes use cases, cleans up after itself.

```dart
class MembersController extends Controller {
  MembersController(this._getMembers, WatchOnlinePresence watchPresence) {
    watch(watchPresence, noParams, onData: _applyPresence);
    onDispose(members.dispose);
  }

  final GetMembers _getMembers;

  final members = asyncStateSignal<List<Member>>();
  final query = signal('');
  late final filtered = computed(() => /* derive from members + query */);

  Future<void> load() => runInto(
        _getMembers,
        noParams,
        into: members,
        retry: const RetryPolicy(maxAttempts: 3),
      );
}
```

What the base class provides:

| Member | Purpose |
| --- | --- |
| `run(useCase, params, ...)` | Execute, track activity, route failures, apply retries; returns the `Result`. |
| `runInto(useCase, params, into: signal)` | Same, and drives a `Signal<AsyncState<T>>` through loading → data/error. Existing data stays visible during reloads (`AsyncDataReloading`). |
| `watch(streamUseCase, params, onData: ...)` | Subscribe to a stream use case; auto-cancelled on dispose. |
| `isLoading` | `ReadonlySignal<bool>` — ref-counted across overlapping operations. |
| `failures` | Broadcast `Stream<Failure>` of every unhandled failure (after retries). |
| `autoEffect(fn)` | A signals `effect` cleaned up on dispose. |
| `onDispose(fn)` | Register any cleanup; run in reverse order by `dispose()`. |

### RetryPolicy

Per-call and self-contained — no shared counters:

```dart
run(getMembers, noParams,
    retry: const RetryPolicy(
      maxAttempts: 3,
      delay: Duration(milliseconds: 300),
      backoffFactor: 2, // 300ms, then 600ms
    ));
```

Only failures where `shouldRetry` returns true (defaults to `failure.isRetryable`) are retried, and only the final failure is emitted on `failures`.

## UI integration

Widgets read signals inside `SignalBuilder` (signals 7+):

```dart
SignalBuilder(builder: (_) {
  final state = controller.members.value;
  return switch (state) {
    AsyncData(:final value) => MemberList(value),
    AsyncError(:final error) => ErrorView(error),
    _ => const CircularProgressIndicator(),
  };
})
```

> Read every signal you depend on *inside* the `SignalBuilder`'s builder. Reads inside nested widgets' `build` methods are not tracked.

See [`example/`](example/) for a complete clean-architecture Flutter app: entities → repositories → use cases → controllers → pages, with DI via get_it, live stream updates, retryable failures and widget tests.

## AI agents

Building a project on base_core with AI agents (Claude Code, Cursor, Codex, ...)?
Copy [`templates/AGENTS.md`](templates/AGENTS.md) into your project root as
`AGENTS.md` / `CLAUDE.md` — it encodes the strict clean-architecture rules of
the example app in agent-enforceable form.

## Testing

Everything is pure Dart:

```dart
test('retries flaky calls', () async {
  final controller = MembersController(FlakyGetMembers(), FakePresence());
  await controller.load();
  expect(controller.members.value, isA<AsyncData<List<Member>>>());
});
```

## Migrating from 1.x

| v1 | v2 |
| --- | --- |
| `Either<Failure, R>` (dartz) | `Result<R>` (`Success` / `Failed`) |
| `Tuple2` (dartz) | Dart 3 records |
| `DataManager<D>` + `UseCaseGenerator` | `Controller` with plain use-case fields |
| `runUseCase<U, P>(params)` type registry | direct call: `run(useCase, params)` |
| `BehaviorSubject` state + `ValueStreamBuilder` | `signal` / `computed` + `SignalBuilder` |
| `ActivityIndicator` (rxdart) | `ActivityTracker` / `Controller.isLoading` (signals) |
| `RetryableFailure` + global retry loop | `Failure.isRetryable` + per-call `RetryPolicy` |
| `BlocProvider` / `MultiBlocProvider` | bring your own DI (e.g. get_it) |
| `onFailure` PublishSubject | `Controller.failures` broadcast stream |

## License

See [LICENSE](LICENSE).
