# clean_signals — instructions for agents working on THIS repo

clean_signals is a lightweight use-case/controller framework on top of
[signals](https://pub.dev/packages/signals). Pure Dart core in `lib/`,
full clean-architecture Flutter sample in `example/`.

## Commands

```sh
dart analyze && dart test            # core library (pure Dart, no Flutter)
cd example && flutter analyze && flutter test   # sample app
```

All four must pass with zero issues before any change is done.

## Structure

- `lib/src/` — `result.dart`, `failure.dart`, `usecase.dart`,
  `controller.dart`, `activity.dart`, `retry.dart`, `logging.dart`.
  Everything is exported through `lib/clean_signals.dart`.
- `example/` — the **reference implementation** of the architecture we tell
  downstream projects to follow (see `templates/AGENTS.md`). It must stay
  exemplary: feature slices (`team/`, `session/`), strict layer boundaries,
  get_it composition root, widget tests.

## Rules for changes

- The core stays **pure Dart** — never add a Flutter dependency to
  `pubspec.yaml`; Flutter-facing helpers belong in the example or a future
  companion package.
- No new runtime dependencies without strong justification (currently:
  signals, logger, meta). dartz and rxdart must never return.
- Public API changes require, in the same change: doc comments, tests,
  README + CHANGELOG updates, and — if the usage pattern changes —
  updates to `example/` and `templates/AGENTS.md` so downstream guidance
  never drifts from reality.
- `StreamUseCase.call` deliberately uses a `StreamTransformer` (not
  `async*`): an `async*` wrapper delays subscription cancellation until the
  source's next event and leaks timers. Don't "simplify" it back.
- The example app's fakes are deliberately flaky/slow (retry + loading
  demos). Widget tests step time with explicit `pump(duration)`; periodic
  streams make `pumpAndSettle` hang — don't use it.

## Versioning

Semver against the pub package. Breaking API changes bump the major version
and get a migration note in README's "Migrating" section.
