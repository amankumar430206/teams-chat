import 'package:teams_chat/domain/entities/user_entity.dart';

/// Data-layer model that knows how to serialize/deserialize the DummyJSON
/// user object and carries the extra [isOnline] flag we derive locally.
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.username,
    required super.email,
    required super.firstName,
    required super.lastName,
    super.avatar,
    super.isOnline,
  });

  /// Parses the DummyJSON /users item.
  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int,
        username: json['username'] as String,
        email: json['email'] as String,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        avatar: json['image'] as String?,
        // Online status is simulated: odd IDs are "online" by default.
        isOnline: (json['id'] as int).isOdd,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'image': avatar,
        'isOnline': isOnline,
      };

  factory UserModel.fromEntity(UserEntity entity) => UserModel(
        id: entity.id,
        username: entity.username,
        email: entity.email,
        firstName: entity.firstName,
        lastName: entity.lastName,
        avatar: entity.avatar,
        isOnline: entity.isOnline,
      );
}
