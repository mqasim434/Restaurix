import '../../../core/sync/sync_action.dart';
import '../../../domain/models/order.dart';
import '../../../domain/models/order_enums.dart';
import '../collections/order_isar.dart';

Order orderFromIsar(OrderIsar record) {
  return Order(
    id: record.uuid,
    orderNumber: record.orderNumber,
    orderType: record.orderTypeEnum,
    tableId: record.tableId,
    subtotal: record.subtotal,
    total: record.total,
    paymentStatus: record.paymentStatusEnum,
    status: record.statusEnum,
    createdByUserId: record.createdByUserId,
    createdAt: record.createdAt,
    updatedAt: record.updatedAt,
    isSynced: record.isSynced,
    deletedAt: record.deletedAt,
    syncAction: record.syncActionEnum,
    deviceId: record.deviceId,
    version: record.version,
  );
}

OrderIsar applyOrderToIsar({
  required OrderIsar record,
  required Order order,
  required String deviceId,
  required SyncAction action,
}) {
  record
    ..orderNumber = order.orderNumber
    ..orderType = order.orderType.wireValue
    ..tableId = order.tableId
    ..subtotal = order.subtotal
    ..total = order.total
    ..paymentStatus = order.paymentStatus.name
    ..status = order.status.name
    ..createdByUserId = order.createdByUserId
    ..markUpdated(deviceId: deviceId, action: action);
  return record;
}

OrderType orderTypeFromWire(String value) =>
    OrderType.values.firstWhere((t) => t.wireValue == value);
