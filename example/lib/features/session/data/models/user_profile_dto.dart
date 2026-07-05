import '../../domain/entities/user_profile.dart';

class UserProfileDto {
  const UserProfileDto({
    required this.id,
    required this.name,
    required this.email,
    required this.title,
  });

  factory UserProfileDto.fromJson(Map<String, Object?> json) => UserProfileDto(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        title: json['title'] as String,
      );

  final String id;
  final String name;
  final String email;
  final String title;

  UserProfile toEntity() =>
      UserProfile(id: id, name: name, email: email, title: title);
}
