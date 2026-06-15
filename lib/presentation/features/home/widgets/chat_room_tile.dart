import 'package:flutter/material.dart';
import 'package:teams_chat/core/theme/app_colors.dart';
import 'package:teams_chat/core/theme/app_text_styles.dart';
import 'package:teams_chat/core/utils/date_formatter.dart';
import 'package:teams_chat/domain/entities/chat_room_entity.dart';
import 'package:teams_chat/presentation/shared/widgets/user_avatar.dart';

/// List tile for a single chat room / DM thread.
class ChatRoomTile extends StatelessWidget {
  const ChatRoomTile({
    super.key,
    required this.room,
    required this.onTap,
  });

  final ChatRoomEntity room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Avatar
            _RoomAvatar(room: room),
            const SizedBox(width: 14),

            // Name + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          room.name,
                          style: AppTextStyles.bodyBold,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (room.lastMessageTime != null)
                        Text(
                          DateFormatter.chatTimestamp(room.lastMessageTime!),
                          style: AppTextStyles.caption.copyWith(
                            color: room.unreadCount > 0
                                ? AppColors.primary
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          room.subtitle,
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.textSecondaryLight,
                            fontWeight: room.unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (room.unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.unreadBadge,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            room.unreadCount > 99
                                ? '99+'
                                : '${room.unreadCount}',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomAvatar extends StatelessWidget {
  const _RoomAvatar({required this.room});
  final ChatRoomEntity room;

  @override
  Widget build(BuildContext context) {
    if (!room.isGroup) {
      // DM — show the other user's avatar with online indicator.
      final other = room.members.isNotEmpty ? room.members.first : null;
      return UserAvatar(
        name: room.name,
        avatarUrl: room.avatar,
        radius: 26,
        showOnlineRing: other != null,
        isOnline: other?.isOnline ?? false,
      );
    }

    // Group — show a coloured container with the group icon.
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.group_rounded,
        color: AppColors.primary,
        size: 26,
      ),
    );
  }
}
