# Agent Instructions — base_core Clean Architecture

> Copy this file into the root of every project built on
> [base_core](https://github.com/f0x-it-llc/base_core) as `AGENTS.md` (and/or
> `CLAUDE.md` for Claude Code). Fill in the `<project-specific>` sections at
> the bottom. The reference implementation for every rule here is the
> base_core `example/` app (Team Directory) — when in doubt, imitate it.

This project uses **base_core v2 + signals + get_it** with strict,
feature-sliced clean architecture. These rules are not suggestions; a change
that violates them is wrong even if it compiles and passes tests.

## The dependency rule

Code is organized as `lib/core/` (shared, feature-agnostic) and
`lib/features/<feature>/` slices with three layers. Dependencies point
inward only:

```
presentation ──▶ domain ◀── data
```

| Layer | MAY import | MUST NOT import |
| --- | --- | --- |
| `domain/` | base_core, other files in the same feature's domain, `core/failures` | Flutter, signals, get_it, `data/`, `presentation/`, any package that does I/O |
| `data/` | base_core, own feature's `domain/`, `core/` (failures, network), transport packages (http, grpc, drift, shared_preferences, ...) | Flutter widgets, signals, `presentation/`, other features' `data/` |
| `presentation/` | base_core, signals, Flutter, get_it (lookup only), own feature's `domain/`, `core/`, other features' `presentation/` widgets | any `data/` file, transport packages, DTOs |

Cross-feature communication happens through presentation (controllers/widgets)
or through a domain contract registered in DI — never by importing another
feature's data layer.

## Feature layout (exact)

```
lib/features/<feature>/
├── domain/
│   ├── entities/<entity>.dart
│   ├── repositories/<name>_repository.dart        # abstract interface class
│   └── usecases/<verb_object>.dart                # one use case per file
├── data/
│   ├── sources/<name>_api.dart                    # transport client
│   ├── models/<entity>_dto.dart                   # wire format ↔ entity
│   └── repositories/<name>_repository_impl.dart
└── presentation/
    ├── controllers/<screen>_controller.dart
    ├── pages/<screen>_page.dart
    └── widgets/<widget>.dart
```

## Domain rules

- Entities are pure Dart: `final` fields, `copyWith`, `==`/`hashCode`. No
  JSON, no annotations, no framework types.
- Repository contracts are `abstract interface class`. They return entities
  and **throw domain `Failure`s** — never transport exceptions, never
  `Result` (wrapping into `Result` is the use case's job via `UseCase.call`).
- Every business operation is a use case: `class GetX extends
  UseCase<Params, ReturnType>` or `StreamUseCase`. Implement `execute`;
  never call `execute` directly from outside — always invoke via `call()`
  so errors become `Failed` results.
- Multi-value params are Dart 3 records with a `typedef`:
  `typedef UpdateXParams = ({String id, String name});`
- Input validation lives in the use case and returns
  `Failed(ValidationFailure(...))` — not in the controller, not in the widget.
- Use `NoParams`/`noParams` for parameterless use cases.

## Data rules

- DTOs own serialization (`fromJson`/`toJson`) and expose `toEntity()`. DTOs
  never leave the data layer.
- Repository implementations map transport errors to domain failures in
  exactly one `_guard` helper per repository (see
  `MemberRepositoryImpl._guard` in the example). No raw exception may cross
  the repository boundary.
- Transient errors (timeouts, 5xx, dropped connections) map to a failure
  with `isRetryable == true`; permanent ones (404, validation) do not.

## Presentation rules

- Every screen's state lives in a `Controller` subclass. Controllers hold
  **signals**, never `ChangeNotifier`, never streams-as-state.
- Async data goes in `asyncStateSignal<T>()` driven by `runInto(...)`.
  Derived state is `computed(...)`. Keep slices fine-grained so widgets
  rebuild only for what they read.
- Execute use cases only through `run` / `runInto` / `watch` — never call a
  use case directly from a controller method body without them (you would
  lose activity tracking, failure routing and retries).
- Retries are declared per call: `retry: const RetryPolicy(maxAttempts: 3)`.
  Never implement retry loops by hand.
- Register every owned signal and subscription for cleanup:
  `onDispose(signal.dispose)`, `autoEffect(...)`, `watch(...)` (auto-cancels).
- Controllers never import Flutter and never touch `BuildContext`.
  Navigation and snackbars belong to pages; controllers return values/expose
  signals the page reacts to.
- **Controller lifetime = DI registration**:
  - Screen-scoped → `registerFactory`; the page creates it in `initState`
    and calls `dispose()` in `dispose()`.
  - App-scoped (session, connectivity, settings) → `registerLazySingleton`
    with a `dispose:` callback; pages look it up but NEVER dispose it.
- Widgets read signals inside `SignalBuilder` **in the builder's own scope**.
  A signal read inside a nested widget's `build` is NOT tracked — pass the
  value down or read it in the enclosing `SignalBuilder`.
- Render `AsyncState` with the shared `AsyncView` widget; mount one
  `FailureListener(failures: controller.failures, ...)` per screen for
  snackbars. Handle a failure locally only with `emitFailure: false`.

## Failures

- The app defines one `sealed class AppFailure extends Failure` hierarchy in
  `core/failures/`, with a `userMessage` per case. UI switches over it
  exhaustively; never string-match on error messages.
- `UnexpectedFailure` is reserved for bugs — never construct it for a known
  failure mode; add a typed case instead.

## Dependency injection

- One composition root: `core/di/injector.dart` with a top-level
  `configureDependencies(...)`. No other file may register into get_it.
- Lifetimes: infrastructure (APIs, repositories) = lazy singletons; use
  cases = factories; controllers = per the rule above.
- Constructor injection everywhere. `getIt<T>()` lookups are allowed only in
  the composition root, in pages (to obtain controllers), and in
  session-style shared widgets.
- Fakes are injected through `configureDependencies` parameters so tests can
  substitute them.

## Testing

- Domain and controller tests are pure Dart: exercise use cases and
  controllers directly against fake repositories; no widget pumping needed.
- Widget tests pump the real app with fast, deterministic fakes (small
  latency, no random flakiness, long stream intervals) and step time with
  explicit `pump(duration)` — never rely on `pumpAndSettle` with periodic
  streams.
- Every new use case gets a test for its failure path, not just its
  happy path.

## Forbidden

- ❌ flutter_bloc, provider, riverpod, get/getx, mobx — signals is the only
  state layer.
- ❌ dartz, rxdart, fpdart — use `Result`, records, and core streams.
- ❌ Business logic in widgets or controllers (belongs in use cases).
- ❌ API/database calls from a controller (belongs in data, behind a
  repository contract).
- ❌ `try`/`catch` around use case invocations in controllers — `run`
  already guarantees a `Result`.
- ❌ Global mutable state outside DI-registered controllers.

## Definition of done

Before declaring any task complete, run and pass ALL of:

```sh
dart analyze          # zero issues, warnings included
flutter test          # all tests green
```

and verify: no layer-rule violations in the imports you added, new public
classes documented, failures typed, signals/subscriptions disposed.

---

## Project specifics (fill in per project)

- **App name / purpose:** `<project-specific>`
- **Features:** `<list feature slices and one-line responsibilities>`
- **Backend / transport:** `<http client, grpc, local db, ...>`
- **App-scoped controllers:** `<e.g. SessionController, ConnectionController>`
- **Run / build commands:** `<flutter run -d ..., codegen, etc.>`
- **Deviations from these rules (with justification):** none
