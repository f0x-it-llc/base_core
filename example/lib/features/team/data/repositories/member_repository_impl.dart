import '../../../../core/failures/app_failure.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/member.dart';
import '../../domain/repositories/member_repository.dart';
import '../models/member_dto.dart';
import '../sources/fake_team_api.dart';

/// Data-layer implementation of [MemberRepository].
///
/// Owns the translation boundary: transport exceptions become domain
/// [AppFailure]s here, and DTOs become entities. Nothing above this layer
/// knows [ApiException] exists.
class MemberRepositoryImpl implements MemberRepository {
  MemberRepositoryImpl(this._api);

  final FakeTeamApi _api;

  @override
  Future<List<Member>> getMembers() => _guard(() async {
        final rows = await _api.fetchMembers();
        return [for (final row in rows) MemberDto.fromJson(row).toEntity()];
      });

  @override
  Future<Member> getMember(String id) => _guard(() async {
        final row = await _api.fetchMember(id);
        return MemberDto.fromJson(row).toEntity();
      });

  @override
  Future<Member> updateName({required String id, required String name}) =>
      _guard(() async {
        final row = await _api.patchMemberName(id, name);
        return MemberDto.fromJson(row).toEntity();
      });

  @override
  Stream<Set<String>> watchOnlineIds() =>
      _api.presenceEvents().map((ids) => ids.toSet());

  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on ApiException catch (e, stackTrace) {
      throw switch (e.statusCode) {
        404 => NotFoundFailure(message: e.body),
        _ => NetworkFailure(message: e.body, cause: e, stackTrace: stackTrace),
      };
    }
  }
}
