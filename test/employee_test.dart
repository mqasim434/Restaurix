import 'package:restaurix/core/sync/sync_action.dart';
import 'package:restaurix/domain/models/employee.dart';
import 'package:flutter_test/flutter_test.dart';

Employee _employee({
  required String id,
  required String fullName,
  required String role,
  bool isActive = true,
  EmployeePayType payType = EmployeePayType.hourly,
  double? hourlyRate = 12,
  double? monthlySalaryBase,
}) {
  final now = DateTime(2024, 6, 1);
  return Employee(
    id: id,
    fullName: fullName,
    role: role,
    hireDate: now,
    payType: payType,
    hourlyRate: hourlyRate,
    monthlySalaryBase: monthlySalaryBase,
    isActive: isActive,
    createdAt: now,
    updatedAt: now,
    isSynced: false,
    syncAction: SyncAction.create,
    deviceId: 'device',
    version: 1,
  );
}

void main() {
  group('employee helpers', () {
    test('validateEmployeePay requires the matching pay field', () {
      expect(
        validateEmployeePay(
          payType: EmployeePayType.hourly,
          hourlyRate: 15,
        ),
        isNull,
      );
      expect(
        validateEmployeePay(
          payType: EmployeePayType.hourly,
          hourlyRate: 0,
        ),
        isNotNull,
      );
      expect(
        validateEmployeePay(
          payType: EmployeePayType.monthly,
          monthlySalaryBase: 50000,
        ),
        isNull,
      );
    });

    test('filterEmployees supports search and active filter', () {
      final employees = [
        _employee(id: '1', fullName: 'Alice Khan', role: 'Waiter'),
        _employee(
          id: '2',
          fullName: 'Bob Chef',
          role: 'Chef',
          isActive: false,
        ),
      ];

      expect(
        filterEmployees(
          employees: employees,
          searchQuery: 'chef',
          activeFilter: EmployeeActiveFilter.all,
        ).map((employee) => employee.id),
        ['2'],
      );
      expect(
        filterEmployees(
          employees: employees,
          searchQuery: '',
          activeFilter: EmployeeActiveFilter.activeOnly,
        ).map((employee) => employee.id),
        ['1'],
      );
      expect(
        filterEmployees(
          employees: employees,
          searchQuery: '',
          activeFilter: EmployeeActiveFilter.inactiveOnly,
        ).map((employee) => employee.id),
        ['2'],
      );
    });

    test('copyWith clears unused pay field when switching pay type', () {
      final employee = _employee(
        id: '1',
        fullName: 'Alice',
        role: 'Waiter',
        payType: EmployeePayType.hourly,
        hourlyRate: 10,
      );

      final updated = employee.copyWith(
        payType: EmployeePayType.monthly,
        monthlySalaryBase: 40000,
        clearHourlyRate: true,
      );

      expect(updated.payType, EmployeePayType.monthly);
      expect(updated.hourlyRate, isNull);
      expect(updated.monthlySalaryBase, 40000);
    });
  });
}
