import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../../core/sync/sync_action.dart';
import '../../../domain/models/attendance_record.dart';

part 'attendance_record_isar.g.dart';

@collection
class AttendanceRecordIsar {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;

  @Index()
  late String employeeId;

  late DateTime checkInTime;

  DateTime? checkOutTime;

  late String source;

  String? createdByUserId;

  String? notes;

  late DateTime createdAt;
  late DateTime updatedAt;

  bool isSynced = false;

  DateTime? deletedAt;

  late String syncAction;

  late String deviceId;

  int version = 1;

  @ignore
  AttendanceSource get sourceEnum => AttendanceSource.values.byName(source);

  @ignore
  SyncAction get syncActionEnum => SyncAction.values.byName(syncAction);

  @ignore
  bool get isDeleted => deletedAt != null;

  @ignore
  bool get isOpen => checkOutTime == null;

  static AttendanceRecordIsar create({
    required String employeeId,
    required DateTime checkInTime,
    required AttendanceSource source,
    required String deviceId,
    String? createdByUserId,
    String? notes,
  }) {
    final now = DateTime.now();
    return AttendanceRecordIsar()
      ..uuid = const Uuid().v4()
      ..employeeId = employeeId
      ..checkInTime = checkInTime
      ..source = source.name
      ..createdByUserId = createdByUserId
      ..notes = notes
      ..createdAt = now
      ..updatedAt = now
      ..isSynced = false
      ..syncAction = SyncAction.create.name
      ..deviceId = deviceId
      ..version = 1;
  }

  AttendanceRecordIsar markUpdated({required String deviceId, SyncAction? action}) {
    updatedAt = DateTime.now();
    isSynced = false;
    syncAction = (action ?? SyncAction.update).name;
    this.deviceId = deviceId;
    version += 1;
    return this;
  }

  AttendanceRecordIsar markDeleted({required String deviceId}) {
    deletedAt = DateTime.now();
    updatedAt = deletedAt!;
    isSynced = false;
    syncAction = SyncAction.delete.name;
    this.deviceId = deviceId;
    version += 1;
    return this;
  }
}
