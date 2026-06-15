import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teams_chat/core/theme/app_colors.dart';
import 'package:teams_chat/core/theme/app_text_styles.dart';
import 'package:teams_chat/core/utils/date_formatter.dart';
import 'package:teams_chat/domain/entities/message_entity.dart';
import 'package:teams_chat/presentation/features/chat/providers/chat_provider.dart';
import 'package:teams_chat/presentation/features/chat/widgets/message_bubble.dart';
import 'package:teams_chat/presentation/features/chat/widgets/message_input_bar.dart';
import 'package:teams_chat/presentation/features/chat/widgets/typing_indicator_widget.dart';
import 'package:teams_chat/core/network/websocket_service.dart';
import 'package:teams_chat/presentation/shared/widgets/app_loading.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  final String roomId;
  final String roomName;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollCtrl.hasClients) return;
    final target = _scrollCtrl.position.maxScrollExtent;
    if (animated) {
      _scrollCtrl.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollCtrl.jumpTo(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider(widget.roomId));
    final wsState = ref.watch(webSocketProvider);

    // Auto-scroll when new messages arrive.
    ref.listen(chatProvider(widget.roomId), (prev, next) {
      if ((next.messages.length) > (prev?.messages.length ?? 0)) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _scrollToBottom());
      }
    });

    return Scaffold(
      appBar: _ChatAppBar(roomName: widget.roomName, roomId: widget.roomId),
      body: Column(
        children: [
          // Connection lost banner
          if (!wsState.isConnected && !chatState.isLoadingHistory)
            _ConnectionBanner(isConnecting: wsState.isConnecting),

          // Message list
          Expanded(
            child: chatState.isLoadingHistory
                ? const AppLoading(message: 'Loading messages…')
                : _MessageList(
                    messages: chatState.messages,
                    scrollController: _scrollCtrl,
                  ),
          ),

          // Typing indicator
          TypingIndicatorWidget(typingUsers: chatState.typingUsers),

          // Input bar
          MessageInputBar(
            onSend: (text) =>
                ref.read(chatProvider(widget.roomId).notifier).sendMessage(text),
            onTyping: () =>
                ref.read(chatProvider(widget.roomId).notifier).onTyping(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// App bar
// ---------------------------------------------------------------------------

class _ChatAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const _ChatAppBar({required this.roomName, required this.roomId});

  final String roomName;
  final String roomId;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatProvider(roomId));
    final memberCount = chatState.messages.isNotEmpty
        ? null
        : null; // Could derive from home if needed

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(roomName, style: AppTextStyles.bodyBold),
          if (chatState.typingUsers.isNotEmpty)
            Text(
              '${chatState.typingUsers.first} is typing…',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Text(
              'Teams Chat',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline_rounded),
          tooltip: 'Room info',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Room: $roomName ($roomId)'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Message list
// ---------------------------------------------------------------------------

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.messages,
    required this.scrollController,
  });

  final List<MessageEntity> messages;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: AppColors.textSecondaryLight,
            ),
            const SizedBox(height: 12),
            Text(
              'No messages yet.\nSay hello! 👋',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final prev = index > 0 ? messages[index - 1] : null;

        // Show date separator if this message is on a different day.
        final showDate = prev == null ||
            !_isSameDay(prev.timestamp, msg.timestamp);

        // Group consecutive messages from the same sender.
        final showSenderInfo = prev == null ||
            prev.senderId != msg.senderId ||
            msg.timestamp.difference(prev.timestamp).inMinutes > 5;

        return Column(
          children: [
            if (showDate) _DateDivider(date: msg.timestamp),
            MessageBubble(
              message: msg,
              showSenderInfo: showSenderInfo && !msg.isFromMe,
            ),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ---------------------------------------------------------------------------
// Date divider
// ---------------------------------------------------------------------------

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              DateFormatter.sectionHeader(date),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Connection lost banner
// ---------------------------------------------------------------------------

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({required this.isConnecting});
  final bool isConnecting;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: isConnecting ? Colors.orange : AppColors.error,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isConnecting)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Colors.white,
              ),
            )
          else
            const Icon(Icons.wifi_off, size: 14, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            isConnecting ? 'Reconnecting…' : 'Connection lost',
            style: AppTextStyles.caption.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
