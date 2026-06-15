import 'package:flutter/material.dart';
import 'package:teams_chat/core/theme/app_colors.dart';
import 'package:teams_chat/core/theme/app_text_styles.dart';

/// Text input + send button fixed at the bottom of the chat screen.
class MessageInputBar extends StatefulWidget {
  const MessageInputBar({
    super.key,
    required this.onSend,
    required this.onTyping,
  });

  final ValueChanged<String> onSend;

  /// Called on every keystroke (used to broadcast typing events).
  final VoidCallback onTyping;

  @override
  State<MessageInputBar> createState() => _MessageInputBarState();
}

class _MessageInputBarState extends State<MessageInputBar> {
  final _ctrl = TextEditingController();
  bool _hasText = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _ctrl.clear();
    setState(() => _hasText = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Text field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.inputBackgroundDark
                      : AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _ctrl,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  onChanged: (v) {
                    final has = v.trim().isNotEmpty;
                    if (has != _hasText) setState(() => _hasText = has);
                    if (has) widget.onTyping();
                  },
                  style: AppTextStyles.body,
                  decoration: const InputDecoration(
                    hintText: 'Message…',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    fillColor: Colors.transparent,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Send button
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _hasText
                    ? AppColors.primary
                    : AppColors.primary.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _hasText ? _send : null,
                icon: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
