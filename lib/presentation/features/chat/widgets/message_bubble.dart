import 'package:flutter/material.dart';
import 'package:teams_chat/core/theme/app_colors.dart';
import 'package:teams_chat/core/theme/app_text_styles.dart';
import 'package:teams_chat/core/utils/date_formatter.dart';
import 'package:teams_chat/domain/entities/message_entity.dart';
import 'package:teams_chat/presentation/shared/widgets/user_avatar.dart';

/// Single message bubble. Handles both "from me" (right-aligned) and
/// "from other" (left-aligned with avatar + name) layouts.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    this.showSenderInfo = true,
  });

  final MessageEntity message;

  /// Whether to show the avatar and sender name above this bubble.
  /// Set to false when consecutive messages from the same sender are grouped.
  final bool showSenderInfo;

  @override
  Widget build(BuildContext context) {
    return message.isFromMe
        ? _MyBubble(message: message)
        : _TheirBubble(message: message, showSenderInfo: showSenderInfo);
  }
}

// ---------------------------------------------------------------------------
// "My" bubble — right-aligned, primary colour background
// ---------------------------------------------------------------------------

class _MyBubble extends StatelessWidget {
  const _MyBubble({required this.message});
  final MessageEntity message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 64, right: 16, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.myBubble,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(4),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Text(
              message.content,
              style: AppTextStyles.body.copyWith(color: AppColors.myBubbleText),
            ),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormatter.timeOnly(message.timestamp),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(width: 4),
              _StatusIcon(status: message.status),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// "Their" bubble — left-aligned with optional avatar + name
// ---------------------------------------------------------------------------

class _TheirBubble extends StatelessWidget {
  const _TheirBubble({
    required this.message,
    required this.showSenderInfo,
  });

  final MessageEntity message;
  final bool showSenderInfo;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 64, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar column (fixed width to keep bubbles aligned)
          SizedBox(
            width: 36,
            child: showSenderInfo
                ? UserAvatar(
                    name: message.senderName,
                    avatarUrl: message.senderAvatar,
                    radius: 16,
                  )
                : null,
          ),
          const SizedBox(width: 8),

          // Bubble + meta
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showSenderInfo)
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 3),
                    child: Text(
                      message.senderName,
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.theirBubbleDark
                        : AppColors.theirBubbleLight,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                  ),
                  child: Text(
                    message.content,
                    style: AppTextStyles.body,
                  ),
                ),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Text(
                    DateFormatter.timeOnly(message.timestamp),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Delivery status icon (sent / delivered / sending / failed)
// ---------------------------------------------------------------------------

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});
  final MessageStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      MessageStatus.sending => const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: AppColors.sending,
          ),
        ),
      MessageStatus.sent => const Icon(
          Icons.check,
          size: 14,
          color: AppColors.sending,
        ),
      MessageStatus.delivered => const Icon(
          Icons.done_all_rounded,
          size: 14,
          color: AppColors.delivered,
        ),
      MessageStatus.failed => const Icon(
          Icons.error_outline_rounded,
          size: 14,
          color: AppColors.error,
        ),
    };
  }
}
