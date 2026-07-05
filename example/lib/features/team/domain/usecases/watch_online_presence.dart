import 'package:base_core/base_core.dart';

import '../repositories/member_repository.dart';

/// Live presence feed: emits the ids of members currently online.
class WatchOnlinePresence extends StreamUseCase<NoParams, Set<String>> {
  WatchOnlinePresence(this._repository);

  final MemberRepository _repository;

  @override
  Stream<Result<Set<String>>> execute(NoParams params) =>
      _repository.watchOnlineIds().map(Success.new);
}
