import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teams_chat/core/theme/app_text_styles.dart';
import 'package:teams_chat/presentation/features/auth/providers/auth_provider.dart';
import 'package:teams_chat/presentation/shared/widgets/app_button.dart';
import 'package:teams_chat/presentation/shared/widgets/app_error_view.dart';
import 'package:teams_chat/presentation/shared/widgets/app_text_field.dart';

/// Form section extracted from [LoginScreen] to keep the screen clean.
class LoginFormWidget extends ConsumerStatefulWidget {
  const LoginFormWidget({super.key, required this.isLoading});
  final bool isLoading;

  @override
  ConsumerState<LoginFormWidget> createState() => _LoginFormWidgetState();
}

class _LoginFormWidgetState extends ConsumerState<LoginFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    await ref.read(authProvider.notifier).login(
          username: _usernameCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
        );

    // Show error if login failed (auth guard handles navigation on success).
    if (mounted) {
      final error = ref.read(authProvider).valueOrNull?.error;
      if (error != null) showErrorSnackBar(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sign In', style: AppTextStyles.heading3),
          const SizedBox(height: 24),

          AppTextField(
            controller: _usernameCtrl,
            label: 'Username',
            hint: 'Enter your username',
            prefixIcon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Username is required' : null,
          ),

          const SizedBox(height: 20),

          AppTextField(
            controller: _passwordCtrl,
            label: 'Password',
            hint: 'Enter your password',
            prefixIcon: Icons.lock_outline_rounded,
            isPassword: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Password is required' : null,
          ),

          const SizedBox(height: 32),

          AppButton(
            label: 'Sign In',
            onPressed: _submit,
            isLoading: widget.isLoading,
            icon: Icons.login_rounded,
          ),
        ],
      ),
    );
  }
}
