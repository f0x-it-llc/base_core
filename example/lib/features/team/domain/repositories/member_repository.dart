import '../entities/member.dart';

/// Domain contract for member data.
///
/// Implementations live in the data layer and throw domain [Failure]s
/// (never raw transport exceptions) — `UseCase.call` converts anything
/// thrown into a `Failed` result.
abstract interface class MemberRepository {
  Future<List<Member>> getMembers();

  Future<Member> getMember(String id);

  Future<Member> updateName({required String id, required String name});

  /// Emits the set of currently-online member ids whenever presence changes.
  Stream<Set<String>> watchOnlineIds();
}
