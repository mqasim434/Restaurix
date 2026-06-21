import '../../../core/sync/sync_action.dart';
import '../../../domain/models/category.dart';
import '../collections/category_isar.dart';

Category categoryFromIsar(CategoryIsar record) {
  return Category(
    id: record.uuid,
    name: record.name,
    imageUrl: record.imageUrl,
    sortOrder: record.sortOrder,
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

CategoryIsar applyCategoryToIsar({
  required CategoryIsar record,
  required Category category,
  required String deviceId,
  required SyncAction action,
}) {
  record
    ..name = category.name
    ..imageUrl = category.imageUrl
    ..sortOrder = category.sortOrder
    ..isActive = category.isActive
    ..markUpdated(deviceId: deviceId, action: action);
  return record;
}
