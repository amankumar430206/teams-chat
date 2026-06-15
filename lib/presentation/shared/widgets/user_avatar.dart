import 'package:flutter/material.dart';
import 'package:teams_chat/core/theme/app_colors.dart';
import 'package:teams_chat/core/theme/app_text_styles.dart';
import 'package:teams_chat/domain/entities/user_entity.dart';

/// Circular avatar with:
/// - Network image when [avatarUrl] is available
/// - Coloured initials fallback
/// - Optional green online-status ring
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.radius = 22,
    this.showOnlineRing = false,
    this.isOnline = false,
  });

  factory UserAvatar.fromEntity(
    UserEntity user, {
    double radius = 22,
    bool showOnlineRing = false,
  }) =>
      UserAvatar(
        name: user.fullName,
        avatarUrl: user.avatar,
        radius: radius,
        showOnlineRing: showOnlineRing,
        isOnline: user.isOnline,
      );

  final String name;
  final String? avatarUrl;
  final double radius;
  final bool showOnlineRing;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: _colorFromName(name),
      backgroundImage:
          avatarUrl != null ? NetworkImage(avatarUrl!) : null,
      child: avatarUrl == null
          ? Text(
              _initials(name),
              style: AppTextStyles.label.copyWith(
                color: Colors.white,
                fontSize: radius * 0.6,
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
    );

    if (!showOnlineRing) return avatar;

    // Wrap with a coloured ring to indicate online status.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isOnline ? AppColors.online : Colors.transparent,
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: avatar,
          ),
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.55,
              height: radius * 0.55,
              decoration: BoxDecoration(
                color: AppColors.online,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  /// Generates a deterministic colour from the name string.
  Color _colorFromName(String name) {
    const colors = [
      Color(0xFF6C63FF),
      Color(0xFF3ABFF8),
      Color(0xFF36D399),
      Color(0xFFFFBE00),
      Color(0xFFFF6584),
      Color(0xFFF87272),
      Color(0xFF818CF8),
    ];
    final index = name.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return colors[index];
  }
}
