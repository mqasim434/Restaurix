import '../../domain/models/user_role.dart';

/// Client-side route allowlist per role (Module 32).
///
/// Server-side enforcement is provided by Supabase RLS (Module 33).
abstract final class RoleRouteAccess {
  static bool isAllowed(String path, UserRole role) {
    if (role == UserRole.admin) return true;

    final normalized = _normalize(path);
    return _salesmanAllowedPrefixes.any(
      (prefix) => normalized == prefix || normalized.startsWith('$prefix/'),
    );
  }

  static String _normalize(String path) {
    if (path.isEmpty || path == '/') return '/dashboard';
    return path.endsWith('/') && path.length > 1
        ? path.substring(0, path.length - 1)
        : path;
  }

  static const _salesmanAllowedPrefixes = [
    '/dashboard',
    '/sales',
    '/orders',
    '/tables',
    '/kitchen',
  ];
}
