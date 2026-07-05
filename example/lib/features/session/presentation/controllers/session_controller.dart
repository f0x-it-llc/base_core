import 'package:clean_signals/clean_signals.dart';
import 'package:signals/signals.dart';

import '../../../../core/demo_users.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/usecases/get_profile.dart';
import '../../domain/usecases/update_profile_name.dart';

/// App-scoped session state: the signed-in user's profile.
///
/// Registered as a **lazy singleton** in the composition root and never
/// disposed by pages. Any widget anywhere reads its signals through a
/// `SignalBuilder` — no provider in the widget tree required — and rebuilds
/// when (and only when) the slice it reads changes.
///
/// In a real app with login/logout, pair this with get_it scopes: push a
/// scope at login that registers user-scoped services, pop it at logout.
class SessionController extends Controller {
  SessionController(this._getProfile, this._updateName) {
    onDispose(profile.dispose);
    onDispose(saving.dispose);
  }

  final GetProfile _getProfile;
  final UpdateProfileName _updateName;

  /// The signed-in user's profile through its load lifecycle.
  final Signal<AsyncState<UserProfile>> profile =
      asyncStateSignal<UserProfile>();

  /// True only while a rename is in flight.
  final Signal<bool> saving = signal(false);

  /// Fine-grained slices: a widget showing only the name rebuilds only when
  /// the name changes, not on every profile mutation.
  late final ReadonlySignal<String> displayName =
      computed(() => profile.value.value?.name ?? '');

  late final ReadonlySignal<String> initial = computed(() {
    final name = displayName.value;
    return name.isEmpty ? '?' : name[0];
  });

  String? get userId => profile.value.value?.id;

  /// Loads [userId]'s profile as the active session.
  ///
  /// Resets to loading first: unlike a refresh of the *same* data (where
  /// `runInto` keeps stale data visible), a user switch must never show the
  /// previous user's profile.
  Future<void> signIn(String userId) {
    profile.value = AsyncState.loading();
    return runInto(
      _getProfile,
      userId,
      into: profile,
      retry: const RetryPolicy(maxAttempts: 3),
    );
  }

  /// Demo affordance: signs in as the next demo account, so you can watch
  /// every session-reading widget in the app react.
  Future<void> switchDemoUser() {
    final index = demoUserIds.indexOf(userId ?? '');
    final next = demoUserIds[(index + 1) % demoUserIds.length];
    return signIn(next);
  }

  /// Renames the signed-in user. Returns true on success; failures surface
  /// on [failures].
  Future<bool> rename(String name) async {
    final id = userId;
    if (id == null) return false;
    saving.value = true;
    try {
      final result = await run(_updateName, (userId: id, name: name));
      return result.fold(
        onSuccess: (updated) {
          profile.value = AsyncState.data(updated);
          return true;
        },
        onFailure: (_) => false,
      );
    } finally {
      saving.value = false;
    }
  }
}
