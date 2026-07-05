import '../entities/user_profile.dart';

/// Domain contract for the signed-in user's profile.
abstract interface class ProfileRepository {
  Future<UserProfile> getProfile(String userId);

  Future<UserProfile> updateName({required String userId, required String name});
}
