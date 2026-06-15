/// Delivery lifecycle of a chat message.
enum MessageStatus { sending, sent, delivered, failed }

/// Pure domain entity for a single chat message.
class MessageEntity {
  const MessageEntity({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    required this.timestamp,
    required this.isFromMe,
    this.status = MessageStatus.delivered,
  });

  final String id;
  final String roomId;
  final int senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final DateTime timestamp;

  /// True when this message was sent by the currently logged-in user.
  final bool isFromMe;
  final MessageStatus status;

  MessageEntity copyWith({
    String? id,
    String? roomId,
    int? senderId,
    String? senderName,
    String? senderAvatar,
    String? content,
    DateTime? timestamp,
    bool? isFromMe,
    MessageStatus? status,
  }) =>
      MessageEntity(
        id: id ?? this.id,
        roomId: roomId ?? this.roomId,
        senderId: senderId ?? this.senderId,
        senderName: senderName ?? this.senderName,
        senderAvatar: senderAvatar ?? this.senderAvatar,
        content: content ?? this.content,
        timestamp: timestamp ?? this.timestamp,
        isFromMe: isFromMe ?? this.isFromMe,
        status: status ?? this.status,
      );

  @override
  bool operator ==(Object other) =>
      other is MessageEntity && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
