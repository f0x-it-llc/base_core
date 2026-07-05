import 'package:clean_signals/clean_signals.dart';
import 'package:signals/signals.dart';

import '../../domain/entities/member.dart';
import '../../domain/usecases/get_member.dart';
import '../../domain/usecases/update_member_name.dart';

/// View model for a single member's detail screen.
class MemberDetailController extends Controller {
  MemberDetailController(this.memberId, this._getMember, this._updateName) {
    onDispose(member.dispose);
    onDispose(saving.dispose);
  }

  final String memberId;
  final GetMember _getMember;
  final UpdateMemberName _updateName;

  final Signal<AsyncState<Member>> member = asyncStateSignal<Member>();

  /// True only while a rename is in flight — independent of [isLoading],
  /// which also covers [load], so the save button gets its own spinner.
  final Signal<bool> saving = signal(false);

  Future<void> load() => runInto(_getMember, memberId, into: member);

  /// Renames the member. Returns true on success so the UI can close the
  /// edit sheet; failures (validation, network) surface on [failures].
  ///
  /// This controller is screen-scoped (factory-registered, disposed by the
  /// page), so it can be disposed while the rename is in flight — every
  /// signal write after the `await` is guarded with [isDisposed].
  Future<bool> rename(String name) async {
    saving.value = true;
    try {
      final result = await run(
        _updateName,
        (id: memberId, name: name),
        retry: const RetryPolicy(maxAttempts: 2),
      );
      return result.fold(
        onSuccess: (updated) {
          if (!isDisposed) member.value = AsyncState.data(updated);
          return true;
        },
        onFailure: (_) => false,
      );
    } finally {
      if (!isDisposed) saving.value = false;
    }
  }
}
