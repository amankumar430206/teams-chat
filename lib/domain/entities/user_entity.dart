/// Pure domain entity — no Flutter, no JSON, no framework.
class UserEntity {
  const UserEntity({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.avatar,
    this.isOnline = false,
  });

  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String? avatar;
  final bool isOnline;

  String get fullName => '$firstName $lastName';

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$f$l';
  }

  UserEntity copyWith({
    int? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? avatar,
    bool? isOnline,
  }) =>
      UserEntity(
        id: id ?? this.id,
        username: username ?? this.username,
        email: email ?? this.email,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        avatar: avatar ?? this.avatar,
        isOnline: isOnline ?? this.isOnline,
      );

  @override
  bool operator ==(Object other) =>
      other is UserEntity && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
