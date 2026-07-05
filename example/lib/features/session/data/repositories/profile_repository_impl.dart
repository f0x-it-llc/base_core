import '../../../../core/failures/app_failure.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../models/user_profile_dto.dart';
import '../sources/fake_profile_api.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._api);

  final FakeProfileApi _api;

  @override
  Future<UserProfile> getProfile(String userId) => _guard(() async {
        final row = await _api.fetchProfile(userId);
        return UserProfileDto.fromJson(row).toEntity();
      });

  @override
  Future<UserProfile> updateName({
    required String userId,
    required String name,
  }) =>
      _guard(() async {
        final row = await _api.patchName(userId, name);
        return UserProfileDto.fromJson(row).toEntity();
      });

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
