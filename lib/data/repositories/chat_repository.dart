import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teams_chat/core/constants/app_constants.dart';
import 'package:teams_chat/data/datasources/local/local_storage.dart';
import 'package:teams_chat/data/datasources/remote/users_api.dart';
import 'package:teams_chat/data/models/message_model.dart';
import 'package:teams_chat/data/models/user_model.dart';
import 'package:teams_chat/domain/entities/chat_room_entity.dart';
import 'package:teams_chat/domain/entities/message_entity.dart';
import 'package:teams_chat/domain/entities/user_entity.dart';

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(
    ref.watch(usersApiProvider),
    ref.watch(localStorageProvider),
  ),
);

class ChatRepository {
  const ChatRepository(this._usersApi, this._storage);
  final UsersApi _usersApi;
  final LocalStorage _storage;

  // ---------------------------------------------------------------------------
  // Users
  // ---------------------------------------------------------------------------

  Future<List<UserEntity>> fetchUsers() async {
    final raw = await _usersApi.fetchUsers();
    return raw.map(UserModel.fromJson).toList();
  }

  // ---------------------------------------------------------------------------
  // Chat rooms (generated from user list — no real API)
  // ---------------------------------------------------------------------------

  List<ChatRoomEntity> buildRooms(List<UserEntity> users) {
    final groupRooms = [
      ChatRoomEntity(
        id: 'general',
        name: 'General',
        isGroup: true,
        description: 'Company-wide announcements',
        members: users,
        unreadCount: 3,
      ),
      ChatRoomEntity(
        id: 'engineering',
        name: 'Engineering',
        isGroup: true,
        description: 'Tech talks and code reviews',
        members: users.take(8).toList(),
        unreadCount: 1,
      ),
      ChatRoomEntity(
        id: 'design',
        name: 'Design',
        isGroup: true,
        description: 'UI/UX discussions',
        members: users.skip(2).take(6).toList(),
        unreadCount: 0,
      ),
      ChatRoomEntity(
        id: 'random',
        name: 'Random',
        isGroup: true,
        description: 'Off-topic banter 🎉',
        members: users,
        unreadCount: 0,
      ),
    ];

    // First 5 users become direct-message rooms.
    final dmRooms = users.take(5).map(
      (u) => ChatRoomEntity(
        id: 'dm_${u.id}',
        name: u.fullName,
        isGroup: false,
        description: u.username,
        members: [u],
        avatar: u.avatar,
        unreadCount: u.id % 3 == 0 ? 1 : 0,
      ),
    );

    return [...groupRooms, ...dmRooms];
  }

  // ---------------------------------------------------------------------------
  // Message history (mock — no public message API)
  // ---------------------------------------------------------------------------

  /// Returns a deterministic set of mock messages seeded by [roomId].
  /// Checks the local cache first; persists the result for future re-entry.
  List<MessageEntity> getMessageHistory({
    required String roomId,
    required List<UserEntity> users,
    required UserEntity currentUser,
  }) {
    // Try the local cache first.
    final cached = _storage.getMessages(roomId);
    if (cached != null) {
      return cached.map(MessageModel.fromJson).toList();
    }

    final messages = _generateMockHistory(
      roomId: roomId,
      users: users,
      currentUser: currentUser,
    );

    // Persist for subsequent re-entries.
    _storage.saveMessages(
      roomId,
      messages
          .map((m) => MessageModel.fromEntity(m).toJson())
          .toList(),
    );

    return messages;
  }

  List<MessageEntity> _generateMockHistory({
    required String roomId,
    required List<UserEntity> users,
    required UserEntity currentUser,
  }) {
    final rng = Random(roomId.hashCode.abs());
    final now = DateTime.now();

    const contents = [
      'Hey everyone! 👋',
      'Good morning, team!',
      'Can we schedule a quick call?',
      'Just pushed the latest changes — please review',
      'Looks great! Well done 🎉',
      'I'll take a look at this today',
      'The build is green now ✅',
      'Let's sync up before EOD',
      'Does anyone have bandwidth for a quick review?',
      'Ship it! 🚀',
      'I think we need to refactor this a bit',
      'What do you think about the new design?',
      'Meeting in 10 minutes, everyone ready?',
      'Fixed the bug, turns out it was a null check 😅',
      'Great work on the release!',
    ];

    final otherUsers = users.where((u) => u.id != currentUser.id).toList();
    if (otherUsers.isEmpty) return [];

    return List.generate(AppConstants.mockHistoryCount, (i) {
      final minutesAgo =
          (AppConstants.mockHistoryCount - i) * 4 + rng.nextInt(3);

      // Occasionally inject a "from me" message for realism.
      final fromMe = rng.nextInt(4) == 0;
      final sender = fromMe
          ? currentUser
          : otherUsers[rng.nextInt(otherUsers.length)];

      return MessageModel(
        id: 'mock_${roomId}_$i',
        roomId: roomId,
        senderId: sender.id,
        senderName: sender.fullName,
        senderAvatar: sender.avatar,
        content: contents[rng.nextInt(contents.length)],
        timestamp: now.subtract(Duration(minutes: minutesAgo)),
        isFromMe: fromMe,
        status: MessageStatus.delivered,
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Cache helpers (called by ChatNotifier after each new message)
  // ---------------------------------------------------------------------------

  Future<void> cacheMessages(
    String roomId,
    List<MessageEntity> messages,
  ) =>
      _storage.saveMessages(
        roomId,
        messages.map((m) => MessageModel.fromEntity(m).toJson()).toList(),
      );
}
