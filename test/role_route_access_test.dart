import 'package:flutter_test/flutter_test.dart';
import 'package:restaurix/app/navigation/role_route_access.dart';
import 'package:restaurix/domain/models/user_role.dart';

void main() {
  group('RoleRouteAccess', () {
    test('admin can access any route', () {
      expect(
        RoleRouteAccess.isAllowed('/settings', UserRole.admin),
        isTrue,
      );
      expect(
        RoleRouteAccess.isAllowed('/reports/sales', UserRole.admin),
        isTrue,
      );
    });

    test('salesman can access permitted routes and nested POS paths', () {
      expect(
        RoleRouteAccess.isAllowed('/dashboard', UserRole.salesman),
        isTrue,
      );
      expect(
        RoleRouteAccess.isAllowed('/sales/checkout', UserRole.salesman),
        isTrue,
      );
      expect(
        RoleRouteAccess.isAllowed('/orders/abc-123', UserRole.salesman),
        isTrue,
      );
      expect(
        RoleRouteAccess.isAllowed('/kitchen', UserRole.salesman),
        isTrue,
      );
    });

    test('salesman is blocked from admin-only routes', () {
      expect(
        RoleRouteAccess.isAllowed('/products', UserRole.salesman),
        isFalse,
      );
      expect(
        RoleRouteAccess.isAllowed('/settings', UserRole.salesman),
        isFalse,
      );
      expect(
        RoleRouteAccess.isAllowed('/reports', UserRole.salesman),
        isFalse,
      );
      expect(
        RoleRouteAccess.isAllowed('/sync', UserRole.salesman),
        isFalse,
      );
    });
  });
}
