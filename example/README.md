# Team Directory — clean_signals sample app

A small but complete Flutter app demonstrating how a large-scale application
implements clean architecture on top of **clean_signals v2 + signals + get_it**.

It shows a live team directory: a searchable member list with real-time
online presence, a detail screen, and a rename flow with domain validation —
backed by a deliberately *flaky* fake API so you can watch the retry policy
and failure routing do their jobs. A second feature slice (`session`)
demonstrates **app-scoped state**: the signed-in user's profile, readable
from any page, with edits propagating to every widget that displays it.

## Running

The example ships without platform folders to stay lean. Generate them once,
then run:

```sh
cd example
flutter create . --platforms=linux,android,ios
flutter run
```

Tests need no platforms:

```sh
flutter test
```

## Architecture

Each feature is a vertical slice with three layers. Dependencies point
inward only: `presentation → domain ← data`.

```
lib/
├── main.dart                        # logger + DI bootstrap + demo sign-in
├── core/                            # shared, feature-agnostic code
│   ├── di/injector.dart             # composition root (get_it)
│   ├── demo_users.dart              # demo account ids (auth stand-in)
│   ├── failures/app_failure.dart    # sealed AppFailure hierarchy + user messages
│   ├── network/api_exception.dart   # shared transport error type
│   └── widgets/
│       ├── async_view.dart          # AsyncState → loading / error / data UI
│       └── failure_listener.dart    # Controller.failures → snackbars
└── features/
    ├── session/                     # APP-SCOPED state: the signed-in user
    │   ├── domain/                  # UserProfile, ProfileRepository, use cases
    │   ├── data/                    # FakeProfileApi, DTO, repository impl
    │   └── presentation/
    │       ├── controllers/session_controller.dart   # get_it lazy singleton
    │       ├── widgets/session_avatar.dart           # mounted in any AppBar
    │       └── pages/profile_page.dart
    └── team/
        ├── domain/                  # pure Dart, zero dependencies outward
        │   ├── entities/member.dart
        │   ├── repositories/member_repository.dart      # contract
        │   └── usecases/
        │       ├── get_members.dart                     # UseCase<NoParams, List<Member>>
        │       ├── get_member.dart                      # UseCase<String, Member>
        │       ├── update_member_name.dart              # record params + validation
        │       └── watch_online_presence.dart           # StreamUseCase
        ├── data/                    # implements the domain contract
        │   ├── sources/fake_team_api.dart               # simulated transport (latency, 500s)
        │   ├── models/member_dto.dart                   # wire format ↔ entity mapping
        │   └── repositories/member_repository_impl.dart # ApiException → AppFailure
        └── presentation/
            ├── controllers/         # Controller subclasses holding signals
            │   ├── members_controller.dart
            │   └── member_detail_controller.dart
            └── pages/
                ├── members_page.dart
                └── member_detail_page.dart
```

## App-scoped state (the session feature)

The v1 pattern of "singleton DataManagers subscribed via Blocs" becomes two
orthogonal decisions here:

- **Lifetime** is decided by DI registration. `SessionController` is a
  `registerLazySingleton` (with a `dispose:` callback so only the container
  ever tears it down); `MembersController` is a `registerFactory` owned and
  disposed by its page.
- **Observability** needs no widget-tree plumbing. Signals are subscribable
  without a `BuildContext`, so `SessionAvatar` (in the members page AppBar)
  and `ProfilePage` both read `getIt<SessionController>()` directly. Renaming
  yourself on the profile page updates the avatar chip on the members page
  with zero wiring between them — `test/app_test.dart` proves it.

Fine-grained slices matter for exactly this shared state: widgets read
`displayName` / `initial` computeds rather than the whole profile, so they
rebuild only when their slice changes. "Switch demo user" shows a full
session swap rippling through every reader; note `signIn` resets the state
to loading *deliberately* (a user switch must not show stale data, unlike a
same-user refresh where `runInto` keeps data visible).

In a real app with login/logout, pair this with get_it scopes so everything
derived from *who is signed in* gets a clean slate:

```dart
// login:
getIt.pushNewScope();
registerUserScopedDependencies();   // session controller, user repos, caches

// logout — disposes and unregisters everything in the scope:
await getIt.popScope();
```

## What to look at

**Failure flow, end to end** — `FakeTeamApi` throws `ApiException(500)`;
`MemberRepositoryImpl` maps it to a retryable `NetworkFailure`;
`MembersController.load()` runs `GetMembers` with
`RetryPolicy(maxAttempts: 3)`, which absorbs the first two failures; had all
attempts failed, the failure lands once on `controller.failures` and
`FailureListener` shows a snackbar with `failure.userMessage`.

**Fine-grained reactivity** — `MembersController` exposes `members`
(async list state), `query` (search text) and `filtered` / `onlineCount`
(computed). Typing in the search box recomputes `filtered` only; the
"N online" chip rebuilds only when the count changes.

**Live streams** — `WatchOnlinePresence` is a `StreamUseCase` subscribed via
`Controller.watch` in the controller's constructor and cancelled
automatically by `dispose()` when the page unmounts.

**Records instead of tuples** — `UpdateMemberName` takes
`({String id, String name})` and returns a `ValidationFailure` for bad
input, which surfaces as a snackbar via the same failure pipeline.

**Controller lifecycle** — pages own their controllers: created from get_it
in `initState`, `dispose()`d in `dispose`. Repositories and the API client
are singletons; use cases and controllers are factories.

## Conventions worth copying

- The domain layer never imports Flutter, signals-flutter, or the data layer.
- Transport exceptions never cross the repository boundary — they are mapped
  to domain failures in exactly one place.
- Read every signal you depend on *inside* a `SignalBuilder` builder;
  reads in nested widgets' `build` methods are not tracked.
- One `FailureListener` per screen, wired to that screen's controller.
