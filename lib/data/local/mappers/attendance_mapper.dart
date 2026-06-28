import '../../../core/sync/sync_action.dart';
import '../../../domain/models/attendance_record.dart';
import '../collections/attendance_record_isar.dart';

AttendanceRecord attendanceRecordFromIsar(AttendanceRecordIsar record) {
  return AttendanceRecord(
    id: record.uuid,
    employeeId: record.employeeId,
    checkInTime: record.checkInTime,
    checkOutTime: record.checkOutTime,
    source: record.sourceEnum,
    createdByUserId: record.createdByUserId,
    notes: record.notes,
    createdAt: record.createdAt,
    updatedAt: record.updatedAt,
    isSynced: record.isSynced,
    deletedAt: record.deletedAt,
    syncAction: record.syncActionEnum,
    deviceId: record.deviceId,
    version: record.version,
  );
}

AttendanceRecordIsar applyAttendanceRecordToIsar({
  required AttendanceRecordIsar record,
  required AttendanceRecord attendanceRecord,
  required String deviceId,
  required SyncAction action,
}) {
  record
    ..employeeId = attendanceRecord.employeeId
    ..checkInTime = attendanceRecord.checkInTime
    ..checkOutTime = attendanceRecord.checkOutTime
    ..source = attendanceRecord.source.name
    ..createdByUserId = attendanceRecord.createdByUserId
    ..notes = attendanceRecord.notes
    ..markUpdated(deviceId: deviceId, action: action);
  return record;
}
