import '../../../core/sync/sync_action.dart';
import '../../../domain/models/restaurant_table.dart';
import '../../../domain/models/table_status.dart';
import '../collections/restaurant_table_isar.dart';

RestaurantTable restaurantTableFromIsar(RestaurantTableIsar record) {
  return RestaurantTable(
    id: record.uuid,
    hallId: record.hallId,
    label: record.label,
    capacity: record.capacity,
    status: record.statusEnum,
    currentOrderId: record.currentOrderId,
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

RestaurantTableIsar applyRestaurantTableToIsar({
  required RestaurantTableIsar record,
  required RestaurantTable table,
  required String deviceId,
  required SyncAction action,
}) {
  record
    ..label = table.label
    ..capacity = table.capacity
    ..status = table.status.name
    ..currentOrderId = table.currentOrderId
    ..sortOrder = table.sortOrder
    ..markUpdated(deviceId: deviceId, action: action);
  return record;
}

TableStatus tableStatusFromWire(String value, {String? currentOrderId}) =>
    TableStatusX.fromWire(value, currentOrderId: currentOrderId);
