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
// Provider (family — one instance per roomId)
// ---------------------------------------------------------------------------

final chatProvider =
    NotifierProvider.family<ChatNotifier, ChatState, String>(
  ChatNotifier.new,
);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ChatNotifier extends FamilyNotifier<ChatState, String> {
  static const _uuid = Uuid();

  String get _roomId => arg;

  StreamSubscription<Map<String, dynamic>>? _wsSub;
  Timer? _typingClearTimer;
  Timer? _simulationTimer;

  @override
  ChatState build(String roomId) {
    // Set up cleanup when this provider is disposed (on screen pop).
    ref.onDispose(_dispose);
    // Kick off async init.
    Future.microtask(() => _initialize());
    return const ChatState.initial();
  }

  // ---------------------------------------------------------------------------
  // Init
  // ---------------------------------------------------------------------------

  Future<void> _initialize() async {
    final currentUser = _currentUser;
    if (currentUser == null) return;

    final users = ref.read(homeProvider).valueOrNull?.users ?? [];

    // 1. Load message history (local cache → generate mock).
    final history = ref.read(chatRepositoryProvider).getMessageHistory(
          roomId: _roomId,
          users: users,
          currentUser: currentUser,
        );

    state = state.copyWith(
      messages: history,
      isLoadingHistory: false,
    );

    // 2. Connect WebSocket and start listening.
    await ref.read(webSocketProvider.notifier).connect();
    _listenToWebSocket();

    state = state.copyWith(isConnected: true);

    // 3. Schedule a simulated "other user" interaction for demo realism.
    _scheduleSimulation(users, currentUser);
  }

  // ---------------------------------------------------------------------------
  // WebSocket
  // ---------------------------------------------------------------------------

  void _listenToWebSocket() {
    _wsSub = ref.read(webSocketProvider.notifier).messages.listen((payload) {
      final type = payload['type'] as String?;
      final roomId = payload['roomId'] as String?;

      // Only process events for this room.
      if (roomId != _roomId) return;

      if (type == 'chat_message') _handleIncomingMessage(payload);
      if (type == 'typing') _handleTypingEvent(payload);
    });
  }

  void _handleIncomingMessage(Map<String, dynamic> payload) {
    final id = payload['id'] as String?;
    final currentUser = _currentUser;
    if (currentUser == null || id == null) return;

    // The echo server mirrors back everything we send.
    // If the message ID is already in our list (as "sent"), just upgrade it
    // to "delivered" — don't add a duplicate.
    final existing = state.messages.indexWhere((m) => m.id == id);
    if (existing != -1) {
      final updated = List<MessageEntity>.from(state.messages);
      updated[existing] =
          updated[existing].copyWith(status: MessageStatus.delivered);
      state = state.copyWith(messages: updated);
      _persistCache(updated);
      return;
    }

    // A genuinely new message from someone else.
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

  /// Sends a message from the current user.
  Future<void> sendMessage(String content) async {
    final currentUser = _currentUser;
    if (currentUser == null || content.trim().isEmpty) return;

    final id = _uuid.v4();
    final now = DateTime.now();

    // Optimistic UI — show as "sending" immediately.
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

    final updated = [...state.messages, msg];
    state = state.copyWith(messages: updated);

    // Send over WebSocket.
    ref.read(webSocketProvider.notifier).send({
      'type': 'chat_message',
      'id': id,
      'roomId': _roomId,
      'senderId': currentUser.id,
      'senderName': currentUser.fullName,
      'senderAvatar': currentUser.avatar,
      'content': content.trim(),
      'timestamp': now.toIso8601String(),
    });

    // Mark as "sent" locally even if echo hasn't returned yet.
    final sentUpdated = List<MessageEntity>.from(state.messages);
    final idx = sentUpdated.indexWhere((m) => m.id == id);
    if (idx != -1) {
      sentUpdated[idx] = sentUpdated[idx].copyWith(status: MessageStatus.sent);
      state = state.copyWith(messages: sentUpdated);
    }
  }

  /// Sends a typing event and auto-clears after the configured timeout.
  void onTyping() {
    final currentUser = _currentUser;
    if (currentUser == null) return;

    ref.read(webSocketProvider.notifier).send({
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
        ref.read(webSocketProvider.notifier).send({
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
  // Demo simulation
  // ---------------------------------------------------------------------------

  void _scheduleSimulation(List<UserEntity> users, UserEntity me) {
    final others = users.where((u) => u.id != me.id).toList();
    if (others.isEmpty) return;

    final rng = Random(_roomId.hashCode.abs());
    final other = others[rng.nextInt(others.length)];

    // Step 1 — show typing indicator after a short delay.
    _simulationTimer = Timer(
      const Duration(milliseconds: AppConstants.simulatedTypingDelayMs),
      () {
        state = state.copyWith(typingUsers: [other.firstName]);

        // Step 2 — clear indicator and deliver a message after another 2.5 s.
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
      ref.read(authProvider).valueOrNull?.user;

  void _persistCache(List<MessageEntity> messages) {
    ref.read(chatRepositoryProvider).cacheMessages(_roomId, messages);
  }

  void _dispose() {
    _wsSub?.cancel();
    _typingClearTimer?.cancel();
    _simulationTimer?.cancel();
  }
}
