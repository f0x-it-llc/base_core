import '../../domain/entities/member.dart';

/// Wire representation of a member. The only place that knows the JSON
/// shape; the domain entity never touches serialization.
class MemberDto {
  const MemberDto({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
  });

  factory MemberDto.fromJson(Map<String, Object?> json) => MemberDto(
        id: json['id'] as String,
        name: json['name'] as String,
        role: json['role'] as String,
        email: json['email'] as String,
      );

  final String id;
  final String name;
  final String role;
  final String email;

  Member toEntity() => Member(id: id, name: name, role: role, email: email);
}
