import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/device_id_service.dart';
import '../../../data/local/isar_service.dart';
import '../../../data/repositories/employee_repository.dart';
import '../../../domain/models/employee.dart';

final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  return EmployeeRepository(ref.watch(isarProvider));
});

final employeeListProvider =
    AsyncNotifierProvider<EmployeeListNotifier, List<Employee>>(
  EmployeeListNotifier.new,
);

final activeEmployeesProvider = StreamProvider<List<Employee>>((ref) {
  return ref.watch(employeeRepositoryProvider).watchActive();
});

final employeeSearchQueryProvider = StateProvider<String>((ref) => '');

final employeeActiveFilterProvider =
    StateProvider<EmployeeActiveFilter>((ref) => EmployeeActiveFilter.all);

final filteredEmployeesProvider = Provider<AsyncValue<List<Employee>>>((ref) {
  final employeesAsync = ref.watch(employeeListProvider);
  final query = ref.watch(employeeSearchQueryProvider);
  final activeFilter = ref.watch(employeeActiveFilterProvider);

  return employeesAsync.whenData(
    (employees) => filterEmployees(
      employees: employees,
      searchQuery: query,
      activeFilter: activeFilter,
    ),
  );
});

class EmployeeMutationResult {
  const EmployeeMutationResult({
    required this.success,
    this.errorMessage,
  });

  final bool success;
  final String? errorMessage;
}

class EmployeeListNotifier extends AsyncNotifier<List<Employee>> {
  StreamSubscription<List<Employee>>? _subscription;

  EmployeeRepository get _repository => ref.read(employeeRepositoryProvider);
  String get _deviceId => ref.read(deviceIdProvider);

  @override
  Future<List<Employee>> build() async {
    _subscription?.cancel();
    _subscription = _repository.watchAll().listen(
      (employees) => state = AsyncValue.data(employees),
      onError: (error, stackTrace) =>
          state = AsyncValue.error(error, stackTrace),
    );
    ref.onDispose(() => _subscription?.cancel());

    return _repository.watchAll().first;
  }

  Future<EmployeeMutationResult> create({
    required String fullName,
    required String role,
    required DateTime hireDate,
    required EmployeePayType payType,
    String? phone,
    double? hourlyRate,
    double? monthlySalaryBase,
    bool isActive = true,
  }) async {
    if (fullName.trim().isEmpty) {
      return const EmployeeMutationResult(
        success: false,
        errorMessage: 'Full name is required',
      );
    }
    if (role.trim().isEmpty) {
      return const EmployeeMutationResult(
        success: false,
        errorMessage: 'Job role is required',
      );
    }

    final payError = validateEmployeePay(
      payType: payType,
      hourlyRate: hourlyRate,
      monthlySalaryBase: monthlySalaryBase,
    );
    if (payError != null) {
      return EmployeeMutationResult(success: false, errorMessage: payError);
    }

    await _repository.create(
      fullName: fullName,
      role: role,
      hireDate: hireDate,
      payType: payType,
      deviceId: _deviceId,
      phone: phone,
      hourlyRate: hourlyRate,
      monthlySalaryBase: monthlySalaryBase,
      isActive: isActive,
    );

    return const EmployeeMutationResult(success: true);
  }

  Future<EmployeeMutationResult> updateEmployee(Employee employee) async {
    if (employee.fullName.trim().isEmpty) {
      return const EmployeeMutationResult(
        success: false,
        errorMessage: 'Full name is required',
      );
    }
    if (employee.role.trim().isEmpty) {
      return const EmployeeMutationResult(
        success: false,
        errorMessage: 'Job role is required',
      );
    }

    final payError = validateEmployeePay(
      payType: employee.payType,
      hourlyRate: employee.hourlyRate,
      monthlySalaryBase: employee.monthlySalaryBase,
    );
    if (payError != null) {
      return EmployeeMutationResult(success: false, errorMessage: payError);
    }

    final updated = await _repository.update(
      employee: employee,
      deviceId: _deviceId,
    );
    if (updated == null) {
      return const EmployeeMutationResult(
        success: false,
        errorMessage: 'Employee not found',
      );
    }

    return const EmployeeMutationResult(success: true);
  }

  Future<EmployeeMutationResult> setActive({
    required Employee employee,
    required bool isActive,
  }) async {
    final updated = await _repository.setActive(
      id: employee.id,
      isActive: isActive,
      deviceId: _deviceId,
    );
    if (updated == null) {
      return const EmployeeMutationResult(
        success: false,
        errorMessage: 'Employee not found',
      );
    }

    return const EmployeeMutationResult(success: true);
  }

  Future<EmployeeMutationResult> delete(String id) async {
    final deleted = await _repository.softDelete(id: id, deviceId: _deviceId);
    if (!deleted) {
      return const EmployeeMutationResult(
        success: false,
        errorMessage: 'Employee not found',
      );
    }

    return const EmployeeMutationResult(success: true);
  }
}
