import '../../../core/sync/sync_action.dart';
import '../../../domain/models/employee.dart';
import '../collections/employee_isar.dart';

Employee employeeFromIsar(EmployeeIsar record) {
  return Employee(
    id: record.uuid,
    fullName: record.fullName,
    role: record.role,
    phone: record.phone,
    hireDate: record.hireDate,
    payType: record.payTypeEnum,
    hourlyRate: record.hourlyRate,
    monthlySalaryBase: record.monthlySalaryBase,
    fingerprintEnrollmentId: record.fingerprintEnrollmentId,
    isActive: record.isActive,
    createdAt: record.createdAt,
    updatedAt: record.updatedAt,
    isSynced: record.isSynced,
    deletedAt: record.deletedAt,
    syncAction: record.syncActionEnum,
    deviceId: record.deviceId,
    version: record.version,
  );
}

EmployeeIsar applyEmployeeToIsar({
  required EmployeeIsar record,
  required Employee employee,
  required String deviceId,
  required SyncAction action,
}) {
  record
    ..fullName = employee.fullName
    ..role = employee.role
    ..phone = employee.phone
    ..hireDate = employee.hireDate
    ..payType = employee.payType.name
    ..hourlyRate = employee.hourlyRate
    ..monthlySalaryBase = employee.monthlySalaryBase
    ..fingerprintEnrollmentId = employee.fingerprintEnrollmentId
    ..isActive = employee.isActive
    ..markUpdated(deviceId: deviceId, action: action);
  return record;
}
