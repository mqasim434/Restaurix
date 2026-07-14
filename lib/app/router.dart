import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/config/desktop_features.dart';
import '../core/config/env_config.dart';
import '../data/remote/supabase_service.dart';
import '../features/attendance/presentation/attendance_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/providers/auth_providers.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/credit_customers/presentation/credit_customer_detail_screen.dart';
import '../features/credit_customers/presentation/credit_customers_screen.dart';
import '../features/categories/presentation/categories_screen.dart';
import '../features/delivery_config/presentation/delivery_config_screen.dart';
import '../features/deals/presentation/deals_screen.dart';
import '../features/employees/presentation/employees_screen.dart';
import '../features/products/presentation/products_screen.dart';
import '../features/debug/presentation/theme_preview_screen.dart';
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
import '../features/tablet_orders/presentation/tablet_orders_screen.dart';
import '../features/tables/presentation/tables_screen.dart';
import '../features/users/presentation/users_screen.dart';
import 'navigation/role_route_access.dart';
import 'shell/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  ref.watch(authControllerProvider);

  final authEnabled =
      EnvConfig.isSupabaseConfigured && SupabaseService.isInitialized;

  return GoRouter(
    initialLocation: DesktopFeatures.homeRoute,
    redirect: (context, state) {
      final path = state.uri.path;
      if (path == '/') {
        return authEnabled ? _postAuthHome(ref) : DesktopFeatures.homeRoute;
      }

      if (DesktopFeatures.hidePosAndDashboard &&
          (path == '/dashboard' || path.startsWith('/sales'))) {
        return DesktopFeatures.tabletOrdersRoute;
      }

      if (authEnabled) {
        final auth = ref.read(authControllerProvider);

        if (auth.status == AuthStatus.loading) {
          return path == '/login' ? null : '/login';
        }

        final isLoginRoute = path == '/login';

        if (auth.status == AuthStatus.unauthenticated && !isLoginRoute) {
          return '/login';
        }

        if (auth.status == AuthStatus.authenticated && isLoginRoute) {
          return DesktopFeatures.homeRoute;
        }
      }

      if (path == '/login' && !authEnabled) {
        return DesktopFeatures.homeRoute;
      }

      if (path == '/analytics') {
        return DesktopFeatures.homeRoute;
      }

      try {
        final role = ref.read(currentUserProvider).role;
        if (!RoleRouteAccess.isAllowed(path, role)) {
          return DesktopFeatures.homeRoute;
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
        builder: (context, state, child) {
          if (authEnabled) {
            final auth = ProviderScope.containerOf(context)
                .read(authControllerProvider);
            if (auth.status != AuthStatus.authenticated) {
              return const SizedBox.shrink();
            }
          }
          return AppShell(child: child);
        },
        routes: _shellRoutes,
      ),
      GoRoute(
        path: '/theme-preview',
        builder: (context, state) => const ThemePreviewScreen(),
      ),
    ],
  );
});

String _postAuthHome(Ref ref) {
  final auth = ref.read(authControllerProvider);
  if (auth.status == AuthStatus.authenticated) return DesktopFeatures.homeRoute;
  return '/login';
}

final _shellRoutes = [
  GoRoute(
    path: DesktopFeatures.tabletOrdersRoute,
    pageBuilder: (context, state) => NoTransitionPage(
      key: state.pageKey,
      child: const TabletOrdersScreen(),
    ),
  ),
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
    path: '/credit-customers',
    pageBuilder: (context, state) => NoTransitionPage(
      key: state.pageKey,
      child: const CreditCustomersScreen(),
    ),
    routes: [
      GoRoute(
        path: ':customerId',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: CreditCustomerDetailScreen(
            customerId: state.pathParameters['customerId']!,
          ),
        ),
      ),
    ],
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
