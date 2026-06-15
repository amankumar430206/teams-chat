import 'package:teams_chat/domain/entities/message_entity.dart';

/// Data-layer model — JSON round-trip for local caching.
class MessageModel extends MessageEntity {
  const MessageModel({
    required super.id,
    required super.roomId,
    required super.senderId,
    required super.senderName,
    super.senderAvatar,
    required super.content,
    required super.timestamp,
    required super.isFromMe,
    super.status,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
        id: json['id'] as String,
        roomId: json['roomId'] as String,
        senderId: json['senderId'] as int,
        senderName: json['senderName'] as String,
        senderAvatar: json['senderAvatar'] as String?,
        content: json['content'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        isFromMe: json['isFromMe'] as bool,
        status: MessageStatus.values.firstWhere(
          (s) => s.name == (json['status'] as String? ?? 'delivered'),
          orElse: () => MessageStatus.delivered,
        ),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'roomId': roomId,
        'senderId': senderId,
        'senderName': senderName,
        'senderAvatar': senderAvatar,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'isFromMe': isFromMe,
        'status': status.name,
      };

  factory MessageModel.fromEntity(MessageEntity e) => MessageModel(
        id: e.id,
        roomId: e.roomId,
        senderId: e.senderId,
        senderName: e.senderName,
        senderAvatar: e.senderAvatar,
        content: e.content,
        timestamp: e.timestamp,
        isFromMe: e.isFromMe,
        status: e.status,
      );

  /// Builds a MessageModel from a decoded WebSocket payload.
  factory MessageModel.fromWsPayload(
    Map<String, dynamic> json, {
    required int currentUserId,
  }) =>
      MessageModel(
        id: json['id'] as String,
        roomId: json['roomId'] as String,
        senderId: json['senderId'] as int,
        senderName: json['senderName'] as String,
        senderAvatar: json['senderAvatar'] as String?,
        content: json['content'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        isFromMe: (json['senderId'] as int) == currentUserId,
        status: MessageStatus.delivered,
      );
}
