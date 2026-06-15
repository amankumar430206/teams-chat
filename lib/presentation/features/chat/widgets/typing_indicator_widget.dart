import 'package:flutter/material.dart';
import 'package:teams_chat/core/theme/app_colors.dart';
import 'package:teams_chat/core/theme/app_text_styles.dart';

/// Animated "X is typing…" indicator with bouncing dots.
class TypingIndicatorWidget extends StatefulWidget {
  const TypingIndicatorWidget({super.key, required this.typingUsers});

  /// Names of users currently typing.
  final List<String> typingUsers;

  @override
  State<TypingIndicatorWidget> createState() => _TypingIndicatorWidgetState();
}

class _TypingIndicatorWidgetState extends State<TypingIndicatorWidget>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      )..repeat(
          reverse: true,
          // Stagger each dot by 150ms
          period: Duration(milliseconds: 400 + i * 150),
        ),
    );

    _animations = _controllers
        .map(
          (c) => Tween<double>(begin: 0, end: -6).animate(
            CurvedAnimation(parent: c, curve: Curves.easeInOut),
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  String get _label {
    final names = widget.typingUsers;
    if (names.isEmpty) return '';
    if (names.length == 1) return '${names[0]} is typing';
    if (names.length == 2) return '${names[0]} and ${names[1]} are typing';
    return 'Several people are typing';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.typingUsers.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 16, 4),
      child: Row(
        children: [
          // Bouncing dots
          Row(
            children: List.generate(3, (i) {
              return AnimatedBuilder(
                animation: _animations[i],
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, _animations[i].value),
                  child: Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(width: 8),
          Text(
            _label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondaryLight,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
