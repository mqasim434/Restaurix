import '../../core/sync/sync_action.dart';
import '../../core/sync/syncable_entity.dart';

enum EmployeePayType {
  hourly,
  monthly,
}

extension EmployeePayTypeX on EmployeePayType {
  String get label => switch (this) {
        EmployeePayType.hourly => 'Hourly',
        EmployeePayType.monthly => 'Monthly salary',
      };
}

class Employee implements SyncableEntity {
  const Employee({
    required this.id,
    required this.fullName,
    required this.role,
    this.phone,
    required this.hireDate,
    required this.payType,
    this.hourlyRate,
    this.monthlySalaryBase,
    this.fingerprintEnrollmentId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.isSynced,
    this.deletedAt,
    required this.syncAction,
    required this.deviceId,
    required this.version,
  });

  @override
  final String id;
  final String fullName;
  final String role;
  final String? phone;
  final DateTime hireDate;
  final EmployeePayType payType;
  final double? hourlyRate;
  final double? monthlySalaryBase;
  final String? fingerprintEnrollmentId;
  final bool isActive;

  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final bool isSynced;
  @override
  final DateTime? deletedAt;
  @override
  final SyncAction syncAction;
  @override
  final String deviceId;
  @override
  final int version;

  double? get activePayAmount => switch (payType) {
        EmployeePayType.hourly => hourlyRate,
        EmployeePayType.monthly => monthlySalaryBase,
      };

  Employee copyWith({
    String? fullName,
    String? role,
    String? phone,
    bool clearPhone = false,
    DateTime? hireDate,
    EmployeePayType? payType,
    double? hourlyRate,
    bool clearHourlyRate = false,
    double? monthlySalaryBase,
    bool clearMonthlySalaryBase = false,
    String? fingerprintEnrollmentId,
    bool clearFingerprintEnrollmentId = false,
    bool? isActive,
    DateTime? updatedAt,
    bool? isSynced,
    DateTime? deletedAt,
    SyncAction? syncAction,
    String? deviceId,
    int? version,
  }) {
    return Employee(
      id: id,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      phone: clearPhone ? null : (phone ?? this.phone),
      hireDate: hireDate ?? this.hireDate,
      payType: payType ?? this.payType,
      hourlyRate: clearHourlyRate ? null : (hourlyRate ?? this.hourlyRate),
      monthlySalaryBase: clearMonthlySalaryBase
          ? null
          : (monthlySalaryBase ?? this.monthlySalaryBase),
      fingerprintEnrollmentId: clearFingerprintEnrollmentId
          ? null
          : (fingerprintEnrollmentId ?? this.fingerprintEnrollmentId),
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      deletedAt: deletedAt ?? this.deletedAt,
      syncAction: syncAction ?? this.syncAction,
      deviceId: deviceId ?? this.deviceId,
      version: version ?? this.version,
    );
  }
}

enum EmployeeActiveFilter {
  all,
  activeOnly,
  inactiveOnly,
}

extension EmployeeActiveFilterX on EmployeeActiveFilter {
  String get label => switch (this) {
        EmployeeActiveFilter.all => 'All',
        EmployeeActiveFilter.activeOnly => 'Active',
        EmployeeActiveFilter.inactiveOnly => 'Inactive',
      };
}

List<Employee> filterEmployees({
  required List<Employee> employees,
  required String searchQuery,
  required EmployeeActiveFilter activeFilter,
}) {
  final query = searchQuery.trim().toLowerCase();

  return employees.where((employee) {
    final matchesActive = switch (activeFilter) {
      EmployeeActiveFilter.all => true,
      EmployeeActiveFilter.activeOnly => employee.isActive,
      EmployeeActiveFilter.inactiveOnly => !employee.isActive,
    };
    if (!matchesActive) return false;
    if (query.isEmpty) return true;

    return employee.fullName.toLowerCase().contains(query) ||
        employee.role.toLowerCase().contains(query) ||
        (employee.phone?.toLowerCase().contains(query) ?? false);
  }).toList();
}

String? validateEmployeePay({
  required EmployeePayType payType,
  double? hourlyRate,
  double? monthlySalaryBase,
}) {
  return switch (payType) {
    EmployeePayType.hourly =>
      hourlyRate == null || hourlyRate <= 0
          ? 'Enter a valid hourly rate'
          : null,
    EmployeePayType.monthly =>
      monthlySalaryBase == null || monthlySalaryBase <= 0
          ? 'Enter a valid monthly salary'
          : null,
  };
}
