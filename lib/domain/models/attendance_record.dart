import '../../core/sync/sync_action.dart';
import '../../core/sync/syncable_entity.dart';

enum AttendanceSource {
  fingerprint,
  manual,
}

extension AttendanceSourceX on AttendanceSource {
  String get label => switch (this) {
        AttendanceSource.fingerprint => 'Fingerprint',
        AttendanceSource.manual => 'Manual',
      };
}

class AttendanceRecord implements SyncableEntity {
  const AttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.checkInTime,
    this.checkOutTime,
    required this.source,
    this.createdByUserId,
    this.notes,
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
  final String employeeId;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final AttendanceSource source;
  final String? createdByUserId;
  final String? notes;

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

  bool get isOpen => checkOutTime == null;

  Duration? workedDuration({DateTime? until}) {
    final end = checkOutTime ?? until;
    if (end == null) return null;
    return end.difference(checkInTime);
  }

  AttendanceRecord copyWith({
    DateTime? checkOutTime,
    bool clearCheckOutTime = false,
    AttendanceSource? source,
    String? createdByUserId,
    String? notes,
    bool clearNotes = false,
    DateTime? updatedAt,
    bool? isSynced,
    DateTime? deletedAt,
    SyncAction? syncAction,
    String? deviceId,
    int? version,
  }) {
    return AttendanceRecord(
      id: id,
      employeeId: employeeId,
      checkInTime: checkInTime,
      checkOutTime: clearCheckOutTime ? null : (checkOutTime ?? this.checkOutTime),
      source: source ?? this.source,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      notes: clearNotes ? null : (notes ?? this.notes),
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

String formatAttendanceDuration(Duration duration) {
  final hours = duration.inMinutes / 60;
  if (hours >= 1) {
    return '${hours.toStringAsFixed(1)} h';
  }
  return '${duration.inMinutes} min';
}
