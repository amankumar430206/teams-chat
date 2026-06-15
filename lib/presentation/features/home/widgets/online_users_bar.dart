import 'package:flutter/material.dart';
import 'package:teams_chat/core/theme/app_text_styles.dart';
import 'package:teams_chat/domain/entities/user_entity.dart';
import 'package:teams_chat/presentation/shared/widgets/user_avatar.dart';

/// Horizontal scrolling row of online users shown at the top of the home screen.
class OnlineUsersBar extends StatelessWidget {
  const OnlineUsersBar({super.key, required this.users});
  final List<UserEntity> users;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: users.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final user = users[index];
          return _OnlineUserChip(user: user);
        },
      ),
    );
  }
}

class _OnlineUserChip extends StatelessWidget {
  const _OnlineUserChip({required this.user});
  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      child: Column(
        children: [
          UserAvatar.fromEntity(
            user,
            radius: 26,
            showOnlineRing: true,
          ),
          const SizedBox(height: 6),
          Text(
            user.firstName,
            style: AppTextStyles.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
