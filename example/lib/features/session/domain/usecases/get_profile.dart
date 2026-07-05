import 'package:base_core/base_core.dart';

import '../entities/user_profile.dart';
import '../repositories/profile_repository.dart';

class GetProfile extends UseCase<String, UserProfile> {
  GetProfile(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Result<UserProfile>> execute(String params) async =>
      Success(await _repository.getProfile(params));
}
