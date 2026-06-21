import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/categories/presentation/categories_screen.dart';
import '../features/deals/presentation/deals_screen.dart';
import '../features/modifiers/presentation/modifier_groups_screen.dart';
import '../features/products/presentation/products_screen.dart';
import '../features/debug/presentation/theme_preview_screen.dart';
import '../features/pos/presentation/pos_screen.dart';
import '../features/placeholder/presentation/coming_soon_screen.dart';
import '../features/tables/presentation/tables_screen.dart';
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
    ],
  );
});

final _shellRoutes = [
  _placeholderRoute('/dashboard', 'Dashboard'),
  GoRoute(
    path: '/sales',
    pageBuilder: (context, state) => NoTransitionPage(
      key: state.pageKey,
      child: const PosScreen(),
    ),
  ),
  _placeholderRoute('/orders', 'Orders'),
  GoRoute(
    path: '/products',
    pageBuilder: (context, state) => NoTransitionPage(
      key: state.pageKey,
      child: const ProductsScreen(),
    ),
  ),
  GoRoute(
    path: '/categories',
    pageBuilder: (context, state) => NoTransitionPage(
      key: state.pageKey,
      child: const CategoriesScreen(),
    ),
  ),
  GoRoute(
    path: '/modifier-groups',
    pageBuilder: (context, state) => NoTransitionPage(
      key: state.pageKey,
      child: const ModifierGroupsScreen(),
    ),
  ),
  GoRoute(
    path: '/deals',
    pageBuilder: (context, state) => NoTransitionPage(
      key: state.pageKey,
      child: const DealsScreen(),
    ),
  ),
  GoRoute(
    path: '/tables',
    pageBuilder: (context, state) => NoTransitionPage(
      key: state.pageKey,
      child: const TablesScreen(),
    ),
  ),
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
