import 'package:base_core/base_core.dart';
import 'package:signals/signals.dart';

import '../../domain/entities/member.dart';
import '../../domain/usecases/get_members.dart';
import '../../domain/usecases/watch_online_presence.dart';

/// View model for the members list screen.
///
/// Fine-grained state: [members] holds the async list, [query] the search
/// text, and [filtered] / [onlineCount] are derived — only widgets reading
/// the signals that actually changed rebuild.
class MembersController extends Controller {
  MembersController(this._getMembers, WatchOnlinePresence watchPresence) {
    // Live presence updates for as long as the controller is alive; the
    // subscription is cancelled automatically by dispose(). Presence is
    // cosmetic, so its failures never reach the snackbar stream.
    watch(watchPresence, noParams, onData: _applyPresence, emitFailures: false);

    onDispose(members.dispose);
    onDispose(query.dispose);
  }

  final GetMembers _getMembers;

  /// The member list through its load lifecycle (loading / data / error).
  final Signal<AsyncState<List<Member>>> members =
      asyncStateSignal<List<Member>>();

  /// Search box text.
  final Signal<String> query = signal('');

  /// Members matching [query], name or role.
  late final ReadonlySignal<List<Member>> filtered = computed(() {
    final state = members.value;
    if (!state.hasValue) return const <Member>[];
    final needle = query.value.trim().toLowerCase();
    if (needle.isEmpty) return state.requireValue;
    return [
      for (final member in state.requireValue)
        if (member.name.toLowerCase().contains(needle) ||
            member.role.toLowerCase().contains(needle))
          member,
    ];
  });

  late final ReadonlySignal<int> onlineCount = computed(() {
    final state = members.value;
    if (!state.hasValue) return 0;
    return state.requireValue.where((m) => m.isOnline).length;
  });

  /// Loads the member list. The fake backend fails the first two calls with
  /// a retryable NetworkFailure; the policy absorbs them transparently.
  Future<void> load() => runInto(
        _getMembers,
        noParams,
        into: members,
        retry: const RetryPolicy(
          maxAttempts: 3,
          delay: Duration(milliseconds: 300),
        ),
      );

  void _applyPresence(Set<String> onlineIds) {
    final state = members.value;
    if (!state.hasValue) return;
    members.value = AsyncState.data([
      for (final member in state.requireValue)
        member.copyWith(isOnline: onlineIds.contains(member.id)),
    ]);
  }
}
