import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/env_config.dart';
import '../../data/remote/supabase_service.dart';
import '../../core/constants.dart';
import '../../core/sync/sync_engine.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/user_role.dart';
import '../../features/sync/providers/sync_engine_providers.dart';
import '../../features/sync/providers/sync_queue_providers.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../navigation/navigation_provider.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const expandedWidth = 240.0;
  static const collapsedWidth = 72.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final isExpanded = ref.watch(sidebarExpandedProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: Row(
        children: [
          AppSidebar(isExpanded: isExpanded),
          Expanded(
            child: Column(
              children: [
                const AppTopBar(),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AppSidebar extends ConsumerWidget {
  const AppSidebar({super.key, required this.isExpanded});

  final bool isExpanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final navItems = ref.watch(navigationItemsProvider);
    final location = GoRouterState.of(context).uri.path;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isExpanded ? AppShell.expandedWidth : AppShell.collapsedWidth,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(right: BorderSide(color: colors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: spacing.xxl + spacing.sm,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing.md),
              child: Row(
                children: [
                  Icon(Icons.restaurant_menu_rounded, color: colors.primary),
                  if (isExpanded) ...[
                    SizedBox(width: spacing.sm),
                    Expanded(
                      child: Text(
                        AppConstants.appName,
                        style: typography.titleMedium.copyWith(
                          color: colors.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Divider(height: 1, color: colors.divider),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: spacing.sm),
              itemCount: navItems.length,
              itemBuilder: (context, index) {
                final item = navItems[index];
                final isSelected = _isSelected(location, item.path);

                return _SidebarTile(
                  item: item,
                  isExpanded: isExpanded,
                  isSelected: isSelected,
                  onTap: () => context.go(item.path),
                );
              },
            ),
          ),
          Divider(height: 1, color: colors.divider),
          _SidebarToggle(isExpanded: isExpanded),
        ],
      ),
    );
  }

  bool _isSelected(String location, String path) {
    if (path == '/dashboard') {
      return location == path || location == '/';
    }
    return location == path || location.startsWith('$path/');
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.item,
    required this.isExpanded,
    required this.isSelected,
    required this.onTap,
  });

  final NavItem item;
  final bool isExpanded;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;

    final background = isSelected ? colors.primaryContainer : colors.transparent;
    final foreground =
        isSelected ? colors.onPrimaryContainer : colors.onSurfaceVariant;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.sm,
        vertical: spacing.xs / 2,
      ),
      child: Material(
        color: background,
        borderRadius: context.appRadius.mdBorder,
        child: InkWell(
          onTap: onTap,
          borderRadius: context.appRadius.mdBorder,
          hoverColor: colors.hover,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.sm,
              vertical: spacing.sm,
            ),
            child: Row(
              children: [
                Icon(item.icon, color: foreground, size: spacing.lg),
                if (isExpanded) ...[
                  SizedBox(width: spacing.sm),
                  Expanded(
                    child: Text(
                      item.label,
                      style: typography.labelLarge.copyWith(color: foreground),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarToggle extends ConsumerWidget {
  const _SidebarToggle({required this.isExpanded});

  final bool isExpanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final spacing = context.appSpacing;

    return IconButton(
      tooltip: isExpanded ? 'Collapse sidebar' : 'Expand sidebar',
      icon: Icon(
        isExpanded ? AppIcons.collapse : AppIcons.expand,
        color: colors.onSurfaceVariant,
      ),
      onPressed: () {
        ref.read(sidebarExpandedProvider.notifier).state = !isExpanded;
      },
      padding: EdgeInsets.all(spacing.md),
    );
  }
}

class AppTopBar extends ConsumerWidget {
  const AppTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final user = ref.watch(currentUserProvider);
    final pendingSyncCount = ref.watch(pendingSyncCountProvider);
    final syncState = ref.watch(syncUiStateProvider);
    final isAdmin = user.role == UserRole.admin;
    final syncEnabled = isAdmin &&
        EnvConfig.isSupabaseConfigured &&
        syncState.runState != SyncRunState.disabled;

    return Container(
      height: spacing.xxl + spacing.sm,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      padding: EdgeInsets.symmetric(horizontal: spacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _titleForLocation(GoRouterState.of(context).uri.path, ref),
              style: typography.titleLarge.copyWith(color: colors.onSurface),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (syncEnabled) ...[
            IconButton(
              tooltip: 'Sync status',
              icon: Icon(
                syncState.runState == SyncRunState.syncing
                    ? Icons.sync_rounded
                    : Icons.cloud_sync_outlined,
                color: colors.onSurfaceVariant,
              ),
              onPressed: () => context.go('/sync'),
            ),
          ],
          if (isAdmin && pendingSyncCount > 0) ...[
            Tooltip(
              message:
                  '$pendingSyncCount change${pendingSyncCount == 1 ? '' : 's'} pending sync — open sync status',
              child: InkWell(
                onTap: () => context.go('/sync'),
                borderRadius: context.appRadius.fullBorder,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.sm,
                    vertical: spacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: colors.warningContainer,
                    borderRadius: context.appRadius.fullBorder,
                    border: Border.all(color: colors.warning),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: spacing.md,
                        color: colors.onWarningContainer,
                      ),
                      SizedBox(width: spacing.xs),
                      Text(
                        '$pendingSyncCount',
                        style: typography.labelLarge.copyWith(
                          color: colors.onWarningContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: spacing.md),
          ],
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.md,
              vertical: spacing.sm,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: context.appRadius.fullBorder,
              border: Border.all(color: colors.border),
            ),
            child: PopupMenuButton<String>(
              tooltip: 'Account',
              offset: Offset(0, spacing.xxl),
              onSelected: (value) async {
                if (value == 'sign_out') {
                  await ref.read(authControllerProvider.notifier).signOut();
                  if (context.mounted) context.go('/login');
                }
              },
              itemBuilder: (context) => [
                if (EnvConfig.isSupabaseConfigured &&
                    SupabaseService.isInitialized)
                  const PopupMenuItem(
                    value: 'sign_out',
                    child: Text('Sign out'),
                  ),
              ],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: spacing.sm + spacing.xs,
                    backgroundColor: colors.primaryContainer,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: typography.labelMedium.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ),
                  SizedBox(width: spacing.sm),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: typography.labelLarge.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                      Text(
                        user.role.name,
                        style: typography.labelSmall.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: spacing.xs),
                  Icon(
                    Icons.expand_more,
                    color: colors.onSurfaceVariant,
                    size: spacing.md,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _titleForLocation(String path, WidgetRef ref) {
    final items = ref.read(navigationItemsProvider);
    for (final item in items) {
      if (item.path == path || (path == '/' && item.path == '/dashboard')) {
        return item.label;
      }
      if (path.startsWith('${item.path}/')) {
        return item.label;
      }
    }
    if (path == '/sync') return 'Sync Status';
    return 'Restaurix';
  }
}
