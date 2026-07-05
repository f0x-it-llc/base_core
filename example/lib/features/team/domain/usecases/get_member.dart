import 'package:base_core/base_core.dart';

import '../entities/member.dart';
import '../repositories/member_repository.dart';

class GetMember extends UseCase<String, Member> {
  GetMember(this._repository);

  final MemberRepository _repository;

  @override
  Future<Result<Member>> execute(String params) async =>
      Success(await _repository.getMember(params));
}
