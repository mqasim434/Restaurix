import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router.dart';
import '../config/desktop_features.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../../features/notifications/providers/notification_providers.dart';

/// Floating in-app alerts (e.g. mobile orders arriving via Realtime sync).
class AppNotificationOverlay extends ConsumerWidget {
  const AppNotificationOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationControllerProvider);
    if (notifications.isEmpty) {
      return const SizedBox.shrink();
    }

    final spacing = context.appSpacing;
    final top = MediaQuery.paddingOf(context).top + spacing.sm;

    return Positioned(
      top: top,
      right: spacing.lg,
      width: 380,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final notification in notifications)
            Padding(
              padding: EdgeInsets.only(bottom: spacing.sm),
              child: _NotificationCard(notification: notification),
            ),
        ],
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  const _NotificationCard({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;

    return Material(
      elevation: 6,
      shadowColor: colors.shadow,
      borderRadius: context.appRadius.mdBorder,
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: notification.orderId == null
            ? null
            : () {
                ref
                    .read(notificationControllerProvider.notifier)
                    .dismiss(notification.id);
                final router = ref.read(routerProvider);
                if (notification.isMobileOrder) {
                  router.go(DesktopFeatures.tabletOrdersRoute);
                  return;
                }
                router.go('/orders/${notification.orderId}');
              },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: colors.secondary),
          ),
          padding: EdgeInsets.all(spacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.tablet_android_outlined,
                color: colors.secondary,
                size: spacing.lg,
              ),
              SizedBox(width: spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: typography.titleSmall.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                    SizedBox(height: spacing.xs),
                    Text(
                      notification.message,
                      style: typography.bodySmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (notification.orderId != null) ...[
                      SizedBox(height: spacing.xs),
                      Text(
                        notification.isMobileOrder
                            ? 'Tap to view tablet orders'
                            : 'Tap to open order',
                        style: typography.labelSmall.copyWith(
                          color: colors.secondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: spacing.xs),
              Semantics(
                label: 'Dismiss',
                button: true,
                child: InkWell(
                  onTap: () => ref
                      .read(notificationControllerProvider.notifier)
                      .dismiss(notification.id),
                  borderRadius: context.appRadius.smBorder,
                  child: Padding(
                    padding: EdgeInsets.all(spacing.xs),
                    child: Icon(
                      AppIcons.close,
                      size: spacing.md,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
