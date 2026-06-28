import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env_config.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_data_table.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../data/remote/supabase_service.dart';
import '../../../features/auth/providers/auth_providers.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../domain/models/user_role.dart';
import '../providers/users_providers.dart';

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final colors = context.appColors;
    final authEnabled =
        EnvConfig.isSupabaseConfigured && SupabaseService.isInitialized;

    if (!authEnabled) {
      return Padding(
        padding: EdgeInsets.all(spacing.lg),
        child: AppEmptyState(
          title: 'Users require Supabase',
          message:
              'Configure SUPABASE_URL and SUPABASE_ANON_KEY in .env to manage login accounts.',
        ),
      );
    }

    final usersAsync = ref.watch(appUsersProvider);

    return Padding(
      padding: EdgeInsets.all(spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Login accounts linked to Supabase Auth and optional employee records',
                  style: typography.bodyMedium.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              AppButton(
                label: 'Create User',
                icon: AppIcons.add,
                onPressed: () => _openCreateDialog(context, ref),
              ),
            ],
          ),
          SizedBox(height: spacing.lg),
          Expanded(
            child: usersAsync.when(
              loading: () =>
                  const AppLoadingIndicator(message: 'Loading users...'),
              error: (error, _) => AppEmptyState(
                title: 'Failed to load users',
                message: error.toString(),
              ),
              data: (users) {
                if (users.isEmpty) {
                  return const AppEmptyState(
                    title: 'No login users yet',
                    message:
                        'Create a salesman account or add your first admin profile in Supabase.',
                  );
                }

                return AppDataTable<AppUserRecord>(
                  columns: [
                    AppDataColumn(
                      label: 'Display name',
                      flex: 2,
                      cellBuilder: (_, row) => Text(row.displayName),
                    ),
                    AppDataColumn(
                      label: 'Role',
                      cellBuilder: (_, row) => Text(row.role.name),
                    ),
                    AppDataColumn(
                      label: 'Employee link',
                      flex: 2,
                      cellBuilder: (_, row) => Text(
                        row.employeeId ?? '—',
                        style: typography.bodySmall.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                  rows: users,
                  emptyMessage: 'No users',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openCreateDialog(BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      builder: (context) => const _CreateUserDialog(),
    );
  }
}

class _CreateUserDialog extends ConsumerStatefulWidget {
  const _CreateUserDialog();

  @override
  ConsumerState<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends ConsumerState<_CreateUserDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  UserRole _role = UserRole.salesman;
  String? _employeeId;
  var _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employees = ref.watch(linkableEmployeesProvider);

    return AppDialog(
      title: 'Create login user',
      confirmLabel: _submitting ? 'Creating...' : 'Create',
      onConfirm: _submitting ? null : _submit,
      onCancel: _submitting ? null : () => Navigator.of(context).pop(),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _nameController,
            label: 'Display name',
            enabled: !_submitting,
          ),
          SizedBox(height: context.appSpacing.md),
          AppTextField(
            controller: _emailController,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
            enabled: !_submitting,
          ),
          SizedBox(height: context.appSpacing.md),
          AppTextField(
            controller: _passwordController,
            label: 'Password',
            obscureText: true,
            enabled: !_submitting,
          ),
          SizedBox(height: context.appSpacing.md),
          AppDropdown<UserRole>(
            label: 'Role',
            value: _role,
            items: UserRole.values,
            itemLabel: (role) => role.name,
            onChanged: _submitting
                ? null
                : (value) {
                    if (value != null) setState(() => _role = value);
                  },
          ),
          SizedBox(height: context.appSpacing.md),
          AppDropdown<String?>(
            label: 'Link employee (optional)',
            value: _employeeId,
            items: [null, ...employees.map((e) => e.id)],
            itemLabel: (id) {
              if (id == null) return 'None';
              return employees.firstWhere((e) => e.id == id).fullName;
            },
            onChanged: _submitting
                ? null
                : (value) => setState(() => _employeeId = value),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    if (name.isEmpty || email.isEmpty || password.length < 6) {
      AppSnackbar.show(
        context,
        message:
            'Enter display name, email, and a password of at least 6 characters',
        type: AppSnackbarType.error,
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(authRepositoryProvider).createAppUser(
            email: email,
            password: password,
            displayName: name,
            role: _role,
            employeeId: _employeeId,
          );
      ref.invalidate(appUsersProvider);
      if (mounted) {
        Navigator.of(context).pop();
        AppSnackbar.show(
          context,
          message: 'User created',
          type: AppSnackbarType.success,
        );
      }
    } on AuthException catch (error) {
      if (mounted) {
        AppSnackbar.show(
          context,
          message: error.message,
          type: AppSnackbarType.error,
        );
      }
    } catch (error) {
      if (mounted) {
        AppSnackbar.show(
          context,
          message: error.toString(),
          type: AppSnackbarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
