import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:teams_chat/core/constants/app_constants.dart';
import 'package:teams_chat/core/network/websocket_service.dart';
import 'package:teams_chat/data/models/message_model.dart';
import 'package:teams_chat/data/repositories/chat_repository.dart';
import 'package:teams_chat/domain/entities/message_entity.dart';
import 'package:teams_chat/domain/entities/user_entity.dart';
import 'package:teams_chat/presentation/features/auth/providers/auth_provider.dart';
import 'package:teams_chat/presentation/features/home/providers/home_provider.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ChatState {
  const ChatState({
    required this.messages,
    required this.typingUsers,
    this.isConnected = false,
    this.isLoadingHistory = false,
    this.error,
  });

  const ChatState.initial()
      : messages = const [],
        typingUsers = const [],
        isConnected = false,
        isLoadingHistory = true,
        error = null;

  final List<MessageEntity> messages;

  /// Names of users currently typing (shown in the indicator).
  final List<String> typingUsers;
  final bool isConnected;
  final bool isLoadingHistory;
  final String? error;

  ChatState copyWith({
    List<MessageEntity>? messages,
    List<String>? typingUsers,
    bool? isConnected,
    bool? isLoadingHistory,
    String? error,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        typingUsers: typingUsers ?? this.typingUsers,
        isConnected: isConnected ?? this.isConnected,
        isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
        error: error,
      );
}

// ---------------------------------------------------------------------------
// Provider — one StateNotifier instance per roomId
// ---------------------------------------------------------------------------

final chatProvider =
    StateNotifierProvider.family<ChatNotifier, ChatState, String>(
  (ref, roomId) => ChatNotifier(roomId, ref),
);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier(this._roomId, this._ref) : super(const ChatState.initial()) {
    // Async init kicked off immediately after construction.
    Future.microtask(_initialize);
  }

  static const _uuid = Uuid();

  final String _roomId;
  final Ref _ref;

  StreamSubscription<Map<String, dynamic>>? _wsSub;
  Timer? _typingClearTimer;
  Timer? _simulationTimer;

  // ---------------------------------------------------------------------------
  // Init
  // ---------------------------------------------------------------------------

  Future<void> _initialize() async {
    final currentUser = _currentUser;
    if (currentUser == null) return;

    final users = _ref.read(homeProvider).users;

    // 1. Load message history (local cache → generate mock).
    final history = _ref.read(chatRepositoryProvider).getMessageHistory(
          roomId: _roomId,
          users: users,
          currentUser: currentUser,
        );

    state = state.copyWith(messages: history, isLoadingHistory: false);

    // 2. Connect WebSocket and start listening.
    await _ref.read(webSocketProvider.notifier).connect();
    _listenToWebSocket();

    state = state.copyWith(isConnected: true);

    // 3. Schedule simulated other-user activity for demo realism.
    _scheduleSimulation(users, currentUser);
  }

  // ---------------------------------------------------------------------------
  // WebSocket
  // ---------------------------------------------------------------------------

  void _listenToWebSocket() {
    _wsSub =
        _ref.read(webSocketProvider.notifier).messages.listen((payload) {
      final type = payload['type'] as String?;
      final roomId = payload['roomId'] as String?;

      // Ignore frames for other rooms.
      if (roomId != _roomId) return;

      if (type == 'chat_message') _handleIncomingMessage(payload);
      if (type == 'typing') _handleTypingEvent(payload);
    });
  }

  void _handleIncomingMessage(Map<String, dynamic> payload) {
    final id = payload['id'] as String?;
    final currentUser = _currentUser;
    if (currentUser == null || id == null) return;

    // Echo server mirrors back our own sends. Detect by ID and upgrade
    // status to delivered instead of inserting a duplicate.
    final existing = state.messages.indexWhere((m) => m.id == id);
    if (existing != -1) {
      final updated = List<MessageEntity>.from(state.messages);
      updated[existing] =
          updated[existing].copyWith(status: MessageStatus.delivered);
      state = state.copyWith(messages: updated);
      _persistCache(updated);
      return;
    }

    // Genuinely new message from someone else.
    final msg = MessageModel.fromWsPayload(
      payload,
      currentUserId: currentUser.id,
    );
    final updated = [...state.messages, msg];
    state = state.copyWith(messages: updated);
    _persistCache(updated);
  }

  void _handleTypingEvent(Map<String, dynamic> payload) {
    final name = payload['senderName'] as String? ?? 'Someone';
    final isTyping = payload['isTyping'] as bool? ?? false;

    final current = List<String>.from(state.typingUsers);
    if (isTyping && !current.contains(name)) {
      current.add(name);
    } else if (!isTyping) {
      current.remove(name);
    }
    state = state.copyWith(typingUsers: current);
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Sends a message from the current user with optimistic UI.
  Future<void> sendMessage(String content) async {
    final currentUser = _currentUser;
    if (currentUser == null || content.trim().isEmpty) return;

    final id = _uuid.v4();
    final now = DateTime.now();

    // Show immediately as "sending".
    final msg = MessageModel(
      id: id,
      roomId: _roomId,
      senderId: currentUser.id,
      senderName: currentUser.fullName,
      senderAvatar: currentUser.avatar,
      content: content.trim(),
      timestamp: now,
      isFromMe: true,
      status: MessageStatus.sending,
    );

    state = state.copyWith(messages: [...state.messages, msg]);

    // Transmit over WebSocket.
    _ref.read(webSocketProvider.notifier).send({
      'type': 'chat_message',
      'id': id,
      'roomId': _roomId,
      'senderId': currentUser.id,
      'senderName': currentUser.fullName,
      'senderAvatar': currentUser.avatar,
      'content': content.trim(),
      'timestamp': now.toIso8601String(),
    });

    // Upgrade to "sent" locally before the echo arrives.
    final sentList = List<MessageEntity>.from(state.messages);
    final idx = sentList.indexWhere((m) => m.id == id);
    if (idx != -1) {
      sentList[idx] = sentList[idx].copyWith(status: MessageStatus.sent);
      state = state.copyWith(messages: sentList);
    }
  }

  /// Broadcasts a typing event and auto-clears after the configured timeout.
  void onTyping() {
    final currentUser = _currentUser;
    if (currentUser == null) return;

    _ref.read(webSocketProvider.notifier).send({
      'type': 'typing',
      'roomId': _roomId,
      'senderId': currentUser.id,
      'senderName': currentUser.fullName,
      'isTyping': true,
    });

    _typingClearTimer?.cancel();
    _typingClearTimer = Timer(
      const Duration(seconds: AppConstants.typingClearAfterSeconds),
      () {
        _ref.read(webSocketProvider.notifier).send({
          'type': 'typing',
          'roomId': _roomId,
          'senderId': currentUser.id,
          'senderName': currentUser.fullName,
          'isTyping': false,
        });
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Demo simulation (typing indicator → reply after a delay)
  // ---------------------------------------------------------------------------

  void _scheduleSimulation(List<UserEntity> users, UserEntity me) {
    final others = users.where((u) => u.id != me.id).toList();
    if (others.isEmpty) return;

    final rng = Random(_roomId.hashCode.abs());
    final other = others[rng.nextInt(others.length)];

    // Step 1 — show typing indicator.
    _simulationTimer = Timer(
      const Duration(milliseconds: AppConstants.simulatedTypingDelayMs),
      () {
        state = state.copyWith(typingUsers: [other.firstName]);

        // Step 2 — clear indicator and deliver the simulated message.
        _simulationTimer = Timer(const Duration(milliseconds: 2500), () {
          state = state.copyWith(typingUsers: []);

          const simulatedMessages = [
            'Hey there! 👋',
            'Let me know when you\'re free to chat',
            'Just checking in — how\'s everything going?',
            'Great to see you here!',
            'Are we still on for the meeting later?',
          ];

          final content =
              simulatedMessages[rng.nextInt(simulatedMessages.length)];
          final msg = MessageModel(
            id: _uuid.v4(),
            roomId: _roomId,
            senderId: other.id,
            senderName: other.fullName,
            senderAvatar: other.avatar,
            content: content,
            timestamp: DateTime.now(),
            isFromMe: false,
            status: MessageStatus.delivered,
          );

          final updated = [...state.messages, msg];
          state = state.copyWith(messages: updated);
          _persistCache(updated);
        });
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  UserEntity? get _currentUser =>
      _ref.read(authProvider).user;

  void _persistCache(List<MessageEntity> messages) {
    _ref.read(chatRepositoryProvider).cacheMessages(_roomId, messages);
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _typingClearTimer?.cancel();
    _simulationTimer?.cancel();
    super.dispose();
  }
}
