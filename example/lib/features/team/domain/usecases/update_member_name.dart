import 'package:clean_signals/clean_signals.dart';

import '../../../../core/failures/app_failure.dart';
import '../entities/member.dart';
import '../repositories/member_repository.dart';

/// Parameters as a Dart 3 record — no tuple types from dartz needed.
typedef UpdateMemberNameParams = ({String id, String name});

class UpdateMemberName extends UseCase<UpdateMemberNameParams, Member> {
  UpdateMemberName(this._repository);

  final MemberRepository _repository;

  @override
  Future<Result<Member>> execute(UpdateMemberNameParams params) async {
    final name = params.name.trim();
    if (name.isEmpty) {
      return const Failed(ValidationFailure(message: 'Name cannot be empty.'));
    }
    if (name.length < 2) {
      return const Failed(
        ValidationFailure(message: 'Name must be at least 2 characters.'),
      );
    }
    return Success(await _repository.updateName(id: params.id, name: name));
  }
}
