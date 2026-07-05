/// The signed-in user's profile. Pure domain entity.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.title,
  });

  final String id;
  final String name;
  final String email;
  final String title;

  UserProfile copyWith({String? name}) => UserProfile(
        id: id,
        name: name ?? this.name,
        email: email,
        title: title,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          other.id == id &&
          other.name == name &&
          other.email == email &&
          other.title == title;

  @override
  int get hashCode => Object.hash(id, name, email, title);

  @override
  String toString() => 'UserProfile($id, $name)';
}
