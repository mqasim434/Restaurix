import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/debug/presentation/debug_isar_screen.dart';
import '../features/debug/presentation/theme_preview_screen.dart';
import '../features/placeholder/presentation/placeholder_home_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const PlaceholderHomeScreen(),
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
