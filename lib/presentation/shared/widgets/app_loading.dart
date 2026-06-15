import 'package:flutter/material.dart';
import 'package:teams_chat/core/theme/app_colors.dart';
import 'package:teams_chat/core/theme/app_text_styles.dart';

/// Full-screen centered loading indicator.
class AppLoading extends StatelessWidget {
  const AppLoading({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: AppTextStyles.small.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Slim inline loading bar shown at the top of a screen.
class AppLoadingBar extends StatelessWidget {
  const AppLoadingBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const LinearProgressIndicator(
      minHeight: 2,
      backgroundColor: Colors.transparent,
      color: AppColors.primary,
    );
  }
}
