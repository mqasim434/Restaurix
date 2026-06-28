import 'package:flutter_test/flutter_test.dart';
import 'package:restaurix/domain/models/app_user.dart';
import 'package:restaurix/domain/models/user_role.dart';

void main() {
  group('AppUser session cache', () {
    test('round-trips through JSON encoding', () {
      const user = AppUser(
        id: 'user-1',
        authUserId: 'auth-1',
        employeeId: 'emp-1',
        name: 'Test User',
        role: UserRole.salesman,
      );

      final decoded = AppUser.decodeCached(user.encodeCached());
      expect(decoded, isNotNull);
      expect(decoded!.id, user.id);
      expect(decoded.authUserId, user.authUserId);
      expect(decoded.employeeId, user.employeeId);
      expect(decoded.name, user.name);
      expect(decoded.role, user.role);
    });

    test('decodeCached returns null for invalid JSON', () {
      expect(AppUser.decodeCached('not-json'), isNull);
    });
  });
}
