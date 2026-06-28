import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../../core/sync/sync_action.dart';
import '../../../domain/models/employee.dart';

part 'employee_isar.g.dart';

@collection
class EmployeeIsar {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;

  late String fullName;

  late String role;

  String? phone;

  late DateTime hireDate;

  late String payType;

  double? hourlyRate;

  double? monthlySalaryBase;

  @Index()
  String? fingerprintEnrollmentId;

  @Index()
  bool isActive = true;

  late DateTime createdAt;
  late DateTime updatedAt;

  bool isSynced = false;

  DateTime? deletedAt;

  late String syncAction;

  late String deviceId;

  int version = 1;

  @ignore
  EmployeePayType get payTypeEnum => EmployeePayType.values.byName(payType);

  @ignore
  SyncAction get syncActionEnum => SyncAction.values.byName(syncAction);

  @ignore
  bool get isDeleted => deletedAt != null;

  static EmployeeIsar create({
    required String fullName,
    required String role,
    required DateTime hireDate,
    required EmployeePayType payType,
    required String deviceId,
    String? phone,
    double? hourlyRate,
    double? monthlySalaryBase,
    String? fingerprintEnrollmentId,
    bool isActive = true,
  }) {
    final now = DateTime.now();
    return EmployeeIsar()
      ..uuid = const Uuid().v4()
      ..fullName = fullName
      ..role = role
      ..phone = phone
      ..hireDate = hireDate
      ..payType = payType.name
      ..hourlyRate = hourlyRate
      ..monthlySalaryBase = monthlySalaryBase
      ..fingerprintEnrollmentId = fingerprintEnrollmentId
      ..isActive = isActive
      ..createdAt = now
      ..updatedAt = now
      ..isSynced = false
      ..syncAction = SyncAction.create.name
      ..deviceId = deviceId
      ..version = 1;
  }

  EmployeeIsar markUpdated({required String deviceId, SyncAction? action}) {
    updatedAt = DateTime.now();
    isSynced = false;
    syncAction = (action ?? SyncAction.update).name;
    this.deviceId = deviceId;
    version += 1;
    return this;
  }

  EmployeeIsar markDeleted({required String deviceId}) {
    deletedAt = DateTime.now();
    updatedAt = deletedAt!;
    isSynced = false;
    syncAction = SyncAction.delete.name;
    this.deviceId = deviceId;
    version += 1;
    return this;
  }
}
