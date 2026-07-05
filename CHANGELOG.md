# Changelog

## 2.0.0

Complete rewrite. The package is now pure Dart (no Flutter SDK dependency)
and built on [signals](https://pub.dev/packages/signals) instead of rxdart;
dartz has been removed entirely.

### Added

- `Result<T>` — sealed `Success` / `Failed` union with `fold`, `map`,
  `flatMap`, `getOrElse`, `Result.guard`, and `toAsyncState()` bridging into
  signals' `AsyncState`.
- `Controller` — signals-based view-model base class with `run`, `runInto`,
  `watch`, ref-counted `isLoading`, a broadcast `failures` stream,
  `autoEffect` and `onDispose` lifecycle cleanup.
- `RetryPolicy` — per-call declarative retries with exponential backoff and
  a `retryIf` predicate (defaults to `Failure.isRetryable`).
- `ActivityTracker` — ref-counted loading state as `ReadonlySignal`s.
- `asyncStateSignal<T>()` — `Signal<AsyncState<T>>` seeded with loading.
- `Failure.cause` / `Failure.stackTrace` / `Failure.isRetryable`; `Failure`
  implements `Exception` so it can be thrown from lower layers and captured
  by `UseCase.call`.
- `example/` — a full clean-architecture Flutter sample app (Team Directory).

### Changed

- `UseCase.execute` returns `Future<Result<R>>`; `call` guards against all
  thrown errors, converting them to `Failed` results.
- `StreamUseCase` (renamed from `StreamingUseCase`) emits `Result` events and
  converts stream errors into `Failed` events without breaking cancellation.

### Removed

- **dartz** (`Either`, `Tuple2`, `Trampoline`) and **rxdart** dependencies.
- `DataManager`, `UseCaseGenerator`, `UseCaseExecutor`,
  `StreamingUseCaseManager` and the type-keyed `runUseCase<U, P>` registry —
  replaced by `Controller` with directly-invoked, fully typed use cases.
- `BaseBloc`, `BlocProvider`, `MultiBlocProvider`, `BaseState`,
  `ValueStreamBuilder`, `match` — use signals' `SignalBuilder` and a DI
  container (e.g. get_it) instead.
- `RetryableFailure` and the global retry loop — replaced by `RetryPolicy`.

## 1.0.0

- First release.
