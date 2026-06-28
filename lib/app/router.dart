import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/config/env_config.dart';
import '../data/remote/supabase_service.dart';
import '../features/attendance/presentation/attendance_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/providers/auth_providers.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/categories/presentation/categories_screen.dart';
import '../features/delivery_config/presentation/delivery_config_screen.dart';
import '../features/deals/presentation/deals_screen.dart';
import '../features/employees/presentation/employees_screen.dart';
import '../features/modifiers/presentation/modifier_groups_screen.dart';
import '../features/products/presentation/products_screen.dart';
import '../features/debug/presentation/theme_preview_screen.dart';
import '../features/kitchen/presentation/kitchen_display_screen.dart';
import '../features/orders/presentation/order_detail_screen.dart';
import '../features/orders/presentation/orders_screen.dart';
import '../features/pos/presentation/order_confirmation_screen.dart';
import '../features/pos/presentation/pos_checkout_screen.dart';
import '../features/pos/presentation/pos_screen.dart';
import '../features/reports/presentation/reports_hub_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/salary/presentation/salary_hub_screen.dart';
import '../features/placeholder/presentation/coming_soon_screen.dart';
import '../features/sync/presentation/sync_status_screen.dart';
import '../features/tables/presentation/tables_screen.dart';
import '../features/users/presentation/users_screen.dart';
import '../domain/models/user_role.dart';
import 'navigation/role_route_access.dart';
import 'shell/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  ref.watch(authControllerProvider);

  final authEnabled =
      EnvConfig.isSupabaseConfigured && SupabaseService.isInitialized;

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final path = state.uri.path;
      if (path == '/') {
        return authEnabled ? _postAuthHome(ref) : '/dashboard';
      }

      if (authEnabled) {
        final auth = ref.read(authControllerProvider);

        if (auth.status == AuthStatus.loading) {
          return null;
        }

        final isLoginRoute = path == '/login';

        if (auth.status == AuthStatus.unauthenticated && !isLoginRoute) {
          return '/login';
        }

        if (auth.status == AuthStatus.authenticated && isLoginRoute) {
          return '/dashboard';
        }
      }

      if (path == '/login' && !authEnabled) {
        return '/dashboard';
      }

      try {
        final role = ref.read(currentUserProvider).role;
        if (!RoleRouteAccess.isAllowed(path, role)) {
          return '/dashboard';
        }
      } on StateError {
        if (authEnabled && path != '/login') return '/login';
      }

      return null;
    },
    errorBuilder: (context, state) => AppShell(
      child: ComingSoonScreen(
        title: 'Page not found',
        subtitle: 'The route "${state.uri.path}" is not available yet.',
      ),
    ),
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: _shellRoutes,
      ),
      GoRoute(
        path: '/theme-preview',
        builder: (context, state) => const ThemePreviewScreen(),
      ),
      GoRoute(
        path: '/kitchen',
        builder: (context, state) {
          final container = ProviderScope.containerOf(context);
          final readOnly =
              container.read(currentUserProvider).role == UserRole.salesman;
          return KitchenDisplayScreen(readOnly: readOnly);
        },
      ),
    ],
  );
});

String _postAuthHome(Ref ref) {
  final auth = ref.read(authControllerProvider);
  if (auth.status == AuthStatus.authenticated) return '/dashboard';
  return '/login';
}

final _shellRoutes = [
  GoRoute(
    path: '/dashboard',
    pageBuilder: (context, state) => NoTransitionPage(
      key: state.pageKey,
      child: const DashboardScreen(),
    ),
  ),
  GoRoute(
    path: '/sales',
    pageBuilder: (context, state) => NoTransitionPage(
      key: state.pageKey,
      child: const PosScreen(),
    ),
    routes: [
      GoRoute(
        path: 'checkout',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const PosCheckoutScreen(),
        ),
      ),
      GoRoute(
        path: 'confirmation/:orderId',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: OrderConfirmationScreen(
            orderId: state.pathParameters['orderId']!,
          ),
        ),
      ),
    ],
  ),
  GoRoute(
    path: '/orders',
    pageBuilder: (context, state) => NoTransitionPage(
      key: state.pageKey,
      child: const OrdersScreen(),
    ),
    routes: [
      GoRoute(
        path: ':orderId',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: OrderDetailScreen(
            orderId: state.pathParameters['orderId']!,
          ),
        ),
      ),
    ],
  ),
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
  GoRoute(
    path: '/delivery-config',
    pageBuilder: (context, state) => NoTransitionPage(
      key: state.pageKey,
      child: const DeliveryConfigScreen(),
    ),
  ),
  GoRoute(
    path: '/employees',
    pageBuilder: (context, state) => NoTransitionPage(
      key: state.pageKey,
      child: const EmployeesScreen(),
    ),
  ),
  GoRoute(
    path: '/attendance',
    pageBuilder: (context, state) => NoTransitionPage(
      key: state.pageKey,
      child: const AttendanceScreen(),
    ),
  ),
  GoRoute(
    path: '/salary',
    pageBuilder: (context, state) => NoTransitionPage(
      key: state.pageKey,
      child: const SalaryHubScreen(),
    ),
  ),
  GoRoute(
    path: '/reports',
    pageBuilder: (context, state) => NoTransitionPage(
      key: state.pageKey,
      child: const ReportsHubScreen(),
    ),
  ),
  GoRoute(
    path: '/sync',
    pageBuilder: (context, state) => NoTransitionPage(
      key: state.pageKey,
      child: const SyncStatusScreen(),
    ),
  ),
  _placeholderRoute('/analytics', 'Analytics'),
  GoRoute(
    path: '/settings',
    pageBuilder: (context, state) => NoTransitionPage(
      key: state.pageKey,
      child: const SettingsScreen(),
    ),
  ),
  GoRoute(
    path: '/users',
    pageBuilder: (context, state) => NoTransitionPage(
      key: state.pageKey,
      child: const UsersScreen(),
    ),
  ),
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
