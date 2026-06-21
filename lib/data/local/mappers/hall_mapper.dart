import '../../../core/sync/sync_action.dart';
import '../../../domain/models/hall.dart';
import '../collections/hall_isar.dart';

Hall hallFromIsar(HallIsar record) {
  return Hall(
    id: record.uuid,
    name: record.name,
    sortOrder: record.sortOrder,
    createdAt: record.createdAt,
    updatedAt: record.updatedAt,
    isSynced: record.isSynced,
    deletedAt: record.deletedAt,
    syncAction: record.syncActionEnum,
    deviceId: record.deviceId,
    version: record.version,
  );
}

HallIsar applyHallToIsar({
  required HallIsar record,
  required Hall hall,
  required String deviceId,
  required SyncAction action,
}) {
  record
    ..name = hall.name
    ..sortOrder = hall.sortOrder
    ..markUpdated(deviceId: deviceId, action: action);
  return record;
}
