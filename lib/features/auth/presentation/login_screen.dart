import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final colors = context.appColors;
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: EdgeInsets.all(spacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppLogo(height: 120),
                SizedBox(height: spacing.md),
                Text(
                  'Sign in to continue',
                  textAlign: TextAlign.center,
                  style: typography.bodyMedium.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: spacing.xl),
                AppTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'you@restaurant.com',
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_submitting,
                ),
                SizedBox(height: spacing.md),
                AppTextField(
                  controller: _passwordController,
                  label: 'Password',
                  obscureText: true,
                  enabled: !_submitting,
                  onSubmitted: (_) => _submit(),
                ),
                if (auth.errorMessage != null) ...[
                  SizedBox(height: spacing.md),
                  Text(
                    auth.errorMessage!,
                    style: typography.bodySmall.copyWith(color: colors.error),
                  ),
                ],
                SizedBox(height: spacing.xl),
                AppButton(
                  label: _submitting ? 'Signing in...' : 'Sign in',
                  onPressed: _submitting ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      AppSnackbar.show(
        context,
        message: 'Enter email and password',
        type: AppSnackbarType.error,
      );
      return;
    }

    setState(() => _submitting = true);
    await ref.read(authControllerProvider.notifier).signIn(
          email: email,
          password: password,
        );
    if (mounted) {
      setState(() => _submitting = false);
    }
  }
}
