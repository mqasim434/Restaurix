import '../../../core/sync/sync_action.dart';
import '../../../domain/models/salary_slip.dart';
import '../collections/salary_slip_isar.dart';

SalarySlip salarySlipFromIsar(SalarySlipIsar record) {
  return SalarySlip(
    id: record.uuid,
    employeeId: record.employeeId,
    periodStart: record.periodStart,
    periodEnd: record.periodEnd,
    totalHours: record.totalHours,
    basePay: record.basePay,
    deductions: record.deductions,
    netPay: record.netPay,
    generatedAt: record.generatedAt,
    generatedByUserId: record.generatedByUserId,
    status: record.statusEnum,
    createdAt: record.createdAt,
    updatedAt: record.updatedAt,
    isSynced: record.isSynced,
    deletedAt: record.deletedAt,
    syncAction: record.syncActionEnum,
    deviceId: record.deviceId,
    version: record.version,
  );
}

SalarySlipIsar applySalarySlipToIsar({
  required SalarySlipIsar record,
  required SalarySlip slip,
  required String deviceId,
  required SyncAction action,
}) {
  record
    ..employeeId = slip.employeeId
    ..periodStart = slip.periodStart
    ..periodEnd = slip.periodEnd
    ..totalHours = slip.totalHours
    ..basePay = slip.basePay
    ..deductions = slip.deductions
    ..netPay = slip.netPay
    ..generatedAt = slip.generatedAt
    ..generatedByUserId = slip.generatedByUserId
    ..status = slip.status.name
    ..markUpdated(deviceId: deviceId, action: action);
  return record;
}
