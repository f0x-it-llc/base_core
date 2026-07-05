import 'package:clean_signals/clean_signals.dart';

import '../entities/member.dart';
import '../repositories/member_repository.dart';

class GetMembers extends UseCase<NoParams, List<Member>> {
  GetMembers(this._repository);

  final MemberRepository _repository;

  @override
  Future<Result<List<Member>>> execute(NoParams params) async =>
      Success(await _repository.getMembers());
}
