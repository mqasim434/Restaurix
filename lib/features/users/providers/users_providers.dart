import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/providers/auth_providers.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../domain/models/user_role.dart';
import '../../employees/providers/employee_providers.dart';

final appUsersProvider = FutureProvider<List<AppUserRecord>>((ref) async {
  return ref.watch(authRepositoryProvider).listAppUsers();
});

class CreateAppUserInput {
  const CreateAppUserInput({
    required this.email,
    required this.password,
    required this.displayName,
    required this.role,
    this.employeeId,
  });

  final String email;
  final String password;
  final String displayName;
  final UserRole role;
  final String? employeeId;
}

final createAppUserProvider =
    FutureProvider.family<void, CreateAppUserInput>((ref, input) async {
  await ref.read(authRepositoryProvider).createAppUser(
        email: input.email,
        password: input.password,
        displayName: input.displayName,
        role: input.role,
        employeeId: input.employeeId,
      );
  ref.invalidate(appUsersProvider);
});

/// Employees available for optional linkage when creating login users.
final linkableEmployeesProvider = Provider((ref) {
  final employeesAsync = ref.watch(filteredEmployeesProvider);
  return employeesAsync.maybeWhen(
    data: (employees) => employees.where((e) => e.isActive).toList(),
    orElse: () => const [],
  );
});
