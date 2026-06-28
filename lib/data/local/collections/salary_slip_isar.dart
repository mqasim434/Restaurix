import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../../core/sync/sync_action.dart';
import '../../../domain/models/salary_slip.dart';

part 'salary_slip_isar.g.dart';

@collection
class SalarySlipIsar {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;

  @Index()
  late String employeeId;

  @Index()
  late DateTime periodStart;

  @Index()
  late DateTime periodEnd;

  late double totalHours;
  late double basePay;
  double? deductions;
  late double netPay;
  late DateTime generatedAt;
  late String generatedByUserId;
  late String status;

  late DateTime createdAt;
  late DateTime updatedAt;

  bool isSynced = false;

  DateTime? deletedAt;

  late String syncAction;

  late String deviceId;

  int version = 1;

  @ignore
  SalarySlipStatus get statusEnum => SalarySlipStatus.values.byName(status);

  @ignore
  SyncAction get syncActionEnum => SyncAction.values.byName(syncAction);

  @ignore
  bool get isDeleted => deletedAt != null;

  static SalarySlipIsar create({
    required String employeeId,
    required DateTime periodStart,
    required DateTime periodEnd,
    required double totalHours,
    required double basePay,
    double? deductions,
    required double netPay,
    required String generatedByUserId,
    required String deviceId,
    SalarySlipStatus status = SalarySlipStatus.draft,
    DateTime? generatedAt,
  }) {
    final now = generatedAt ?? DateTime.now();
    return SalarySlipIsar()
      ..uuid = const Uuid().v4()
      ..employeeId = employeeId
      ..periodStart = periodStart
      ..periodEnd = periodEnd
      ..totalHours = totalHours
      ..basePay = basePay
      ..deductions = deductions
      ..netPay = netPay
      ..generatedAt = now
      ..generatedByUserId = generatedByUserId
      ..status = status.name
      ..createdAt = now
      ..updatedAt = now
      ..isSynced = false
      ..syncAction = SyncAction.create.name
      ..deviceId = deviceId
      ..version = 1;
  }

  SalarySlipIsar markUpdated({required String deviceId, SyncAction? action}) {
    updatedAt = DateTime.now();
    isSynced = false;
    syncAction = (action ?? SyncAction.update).name;
    this.deviceId = deviceId;
    version += 1;
    return this;
  }

  SalarySlipIsar markDeleted({required String deviceId}) {
    deletedAt = DateTime.now();
    updatedAt = deletedAt!;
    isSynced = false;
    syncAction = SyncAction.delete.name;
    this.deviceId = deviceId;
    version += 1;
    return this;
  }
}
