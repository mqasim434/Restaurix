import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/debug/presentation/debug_isar_screen.dart';
import '../features/debug/presentation/theme_preview_screen.dart';
import '../features/placeholder/presentation/coming_soon_screen.dart';
import 'shell/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      if (state.uri.path == '/') return '/dashboard';
      return null;
    },
    errorBuilder: (context, state) => AppShell(
      child: ComingSoonScreen(
        title: 'Page not found',
        subtitle: 'The route "${state.uri.path}" is not available yet.',
      ),
    ),
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: _shellRoutes,
      ),
      GoRoute(
        path: '/theme-preview',
        builder: (context, state) => const ThemePreviewScreen(),
      ),
      GoRoute(
        path: '/debug-isar',
        builder: (context, state) => const DebugIsarScreen(),
      ),
    ],
  );
});

final _shellRoutes = [
  _placeholderRoute('/dashboard', 'Dashboard'),
  _placeholderRoute('/sales', 'Sales (POS)'),
  _placeholderRoute('/orders', 'Orders'),
  _placeholderRoute('/products', 'Products'),
  _placeholderRoute('/categories', 'Categories'),
  _placeholderRoute('/deals', 'Deals'),
  _placeholderRoute('/tables', 'Tables'),
  _placeholderRoute('/employees', 'Employees'),
  _placeholderRoute('/attendance', 'Attendance'),
  _placeholderRoute('/reports', 'Reports'),
  _placeholderRoute('/analytics', 'Analytics'),
  _placeholderRoute('/settings', 'Settings'),
  _placeholderRoute('/users', 'Users'),
];

GoRoute _placeholderRoute(String path, String title) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => NoTransitionPage(
      key: state.pageKey,
      child: ComingSoonScreen(title: title),
    ),
  );
}
