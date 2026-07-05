import 'package:base_core/base_core.dart';

import '../../../../core/failures/app_failure.dart';
import '../entities/user_profile.dart';
import '../repositories/profile_repository.dart';

typedef UpdateProfileNameParams = ({String userId, String name});

class UpdateProfileName extends UseCase<UpdateProfileNameParams, UserProfile> {
  UpdateProfileName(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Result<UserProfile>> execute(UpdateProfileNameParams params) async {
    final name = params.name.trim();
    if (name.length < 2) {
      return const Failed(
        ValidationFailure(message: 'Name must be at least 2 characters.'),
      );
    }
    return Success(
      await _repository.updateName(userId: params.userId, name: name),
    );
  }
}
