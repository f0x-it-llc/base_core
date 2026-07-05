/// A team member. Pure domain entity — no serialization, no framework types.
class Member {
  const Member({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
    this.isOnline = false,
  });

  final String id;
  final String name;
  final String role;
  final String email;
  final bool isOnline;

  Member copyWith({String? name, String? role, bool? isOnline}) => Member(
        id: id,
        name: name ?? this.name,
        role: role ?? this.role,
        email: email,
        isOnline: isOnline ?? this.isOnline,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Member &&
          other.id == id &&
          other.name == name &&
          other.role == role &&
          other.email == email &&
          other.isOnline == isOnline;

  @override
  int get hashCode => Object.hash(id, name, role, email, isOnline);

  @override
  String toString() => 'Member($id, $name)';
}
