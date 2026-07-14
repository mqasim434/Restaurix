import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_notification_overlay.dart';
import 'router.dart';
import 'sync_lifecycle.dart';

class RestaurixApp extends ConsumerWidget {
  const RestaurixApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return SyncLifecycle(
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: router,
        builder: (context, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              if (child != null) child,
              const AppNotificationOverlay(),
            ],
          );
        },
      ),
    );
  }
}
