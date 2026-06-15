import 'package:teams_chat/domain/entities/message_entity.dart';
import 'package:teams_chat/domain/entities/user_entity.dart';

/// Pure domain entity representing a group or direct-message chat room.
class ChatRoomEntity {
  const ChatRoomEntity({
    required this.id,
    required this.name,
    required this.isGroup,
    required this.members,
    this.description,
    this.avatar,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
  });

  final String id;
  final String name;
  final bool isGroup;
  final List<UserEntity> members;
  final String? description;

  /// Used as the room's avatar image URL (for DMs it's the other user's photo).
  final String? avatar;

  final MessageEntity? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;

  /// Subtitle shown in the room tile (last message preview or member count).
  String get subtitle {
    if (lastMessage != null) {
      final prefix = lastMessage!.isFromMe ? 'You: ' : '';
      return '$prefix${lastMessage!.content}';
    }
    if (isGroup) return '${members.length} members';
    return 'Tap to start chatting';
  }

  ChatRoomEntity copyWith({
    String? id,
    String? name,
    bool? isGroup,
    List<UserEntity>? members,
    String? description,
    String? avatar,
    MessageEntity? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
  }) =>
      ChatRoomEntity(
        id: id ?? this.id,
        name: name ?? this.name,
        isGroup: isGroup ?? this.isGroup,
        members: members ?? this.members,
        description: description ?? this.description,
        avatar: avatar ?? this.avatar,
        lastMessage: lastMessage ?? this.lastMessage,
        lastMessageTime: lastMessageTime ?? this.lastMessageTime,
        unreadCount: unreadCount ?? this.unreadCount,
      );
}
