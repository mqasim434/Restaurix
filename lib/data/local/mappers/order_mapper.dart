import '../../../core/sync/sync_action.dart';
import '../../../domain/models/discount.dart';
import '../../../domain/models/order.dart';
import '../../../domain/models/order_enums.dart';
import '../../../domain/models/order_item.dart';
import '../collections/order_isar.dart';

Order orderFromIsar(OrderIsar record) {
  return Order(
    id: record.uuid,
    orderNumber: record.orderNumber,
    orderType: record.orderTypeEnum,
    tableId: record.tableId,
    deliveryMode: record.deliveryModeEnum,
    riderId: record.riderId,
    riderName: record.riderName,
    pickupCompanyId: record.pickupCompanyId,
    pickupCompanyName: record.pickupCompanyName,
    subtotal: record.subtotal,
    itemDiscountTotal: record.itemDiscountTotal,
    orderDiscountTotal: record.orderDiscountTotal,
    total: record.total,
    paymentType: record.paymentTypeEnum,
    paymentStatus: record.paymentStatusEnum,
    status: record.statusEnum,
    isPrepaid: record.isPrepaid,
    isHeld: record.isHeld,
    createdByUserId: record.createdByUserId,
    notes: record.notes,
    cancelReason: record.cancelReason,
    cancelRefundNote: record.cancelRefundNote,
    orderDiscountType: record.orderDiscountType,
    orderDiscountValue: record.orderDiscountValue,
    orderDiscountReason: record.orderDiscountReason,
    createdAt: record.createdAt,
    updatedAt: record.updatedAt,
    isSynced: record.isSynced,
    deletedAt: record.deletedAt,
    syncAction: record.syncActionEnum,
    deviceId: record.deviceId,
    version: record.version,
  );
}

void applyOrderFieldsToIsar({
  required OrderIsar record,
  required Order order,
}) {
  record
    ..orderNumber = order.orderNumber
    ..orderType = order.orderType.wireValue
    ..tableId = order.tableId
    ..deliveryMode = order.deliveryMode?.wireValue
    ..riderId = order.riderId
    ..riderName = order.riderName
    ..pickupCompanyId = order.pickupCompanyId
    ..pickupCompanyName = order.pickupCompanyName
    ..subtotal = order.subtotal
    ..itemDiscountTotal = order.itemDiscountTotal
    ..orderDiscountTotal = order.orderDiscountTotal
    ..total = order.total
    ..paymentType = order.paymentType?.name
    ..paymentStatus = order.paymentStatus.name
    ..status = order.status.name
    ..isPrepaid = order.isPrepaid
    ..isHeld = order.isHeld
    ..createdByUserId = order.createdByUserId
    ..notes = order.notes
    ..cancelReason = order.cancelReason
    ..cancelRefundNote = order.cancelRefundNote
    ..orderDiscountType = order.orderDiscountType
    ..orderDiscountValue = order.orderDiscountValue
    ..orderDiscountReason = order.orderDiscountReason;
}

OrderIsar applyOrderToIsar({
  required OrderIsar record,
  required Order order,
  required String deviceId,
  required SyncAction action,
}) {
  applyOrderFieldsToIsar(record: record, order: order);
  record.markUpdated(deviceId: deviceId, action: action);
  return record;
}

OrderType orderTypeFromWire(String value) =>
    OrderType.values.firstWhere((t) => t.wireValue == value);

OrderItem orderItemFromIsar(OrderItemIsar record) {
  return OrderItem(
    id: record.uuid,
    orderId: record.orderId,
    productId: record.productId,
    dealId: record.dealId,
    name: record.name,
    variantName: record.variantName,
    unitPrice: record.unitPrice,
    quantity: record.quantity,
    lineTotal: record.lineTotal,
    modifiers: [
      for (final modifier in record.modifiers)
        OrderItemModifier(
          modifierId: modifier.modifierId,
          name: modifier.name,
          priceDelta: modifier.priceDelta,
        ),
    ],
    appliedDiscounts: [
      for (final discount in record.appliedDiscounts)
        OrderLineDiscount(
          scope: DiscountScope.values.byName(discount.scope),
          type: DiscountType.values.byName(discount.type),
          value: discount.value,
          amountApplied: discount.amountApplied,
          targetId: discount.targetId,
          reason: discount.reason,
        ),
    ],
    kitchenStatus: record.kitchenStatusEnum,
    createdAt: record.createdAt,
    updatedAt: record.updatedAt,
    isSynced: record.isSynced,
    deletedAt: record.deletedAt,
    syncAction: record.syncActionEnum,
    deviceId: record.deviceId,
    version: record.version,
  );
}

OrderItemIsar orderItemToIsar({
  required OrderItem item,
  required String deviceId,
  required SyncAction action,
}) {
  return OrderItemIsar()
    ..uuid = item.id
    ..orderId = item.orderId
    ..productId = item.productId
    ..dealId = item.dealId
    ..name = item.name
    ..variantName = item.variantName
    ..unitPrice = item.unitPrice
    ..quantity = item.quantity
    ..lineTotal = item.lineTotal
    ..modifiers = [
      for (final modifier in item.modifiers)
        (OrderItemModifierEmbedded()
          ..modifierId = modifier.modifierId
          ..name = modifier.name
          ..priceDelta = modifier.priceDelta),
    ]
    ..appliedDiscounts = [
      for (final discount in item.appliedDiscounts)
        (OrderLineDiscountEmbedded()
          ..scope = discount.scope.name
          ..type = discount.type.name
          ..value = discount.value
          ..amountApplied = discount.amountApplied
          ..targetId = discount.targetId
          ..reason = discount.reason),
    ]
    ..kitchenStatus = item.kitchenStatus.name
    ..createdAt = item.createdAt
    ..updatedAt = item.updatedAt
    ..isSynced = item.isSynced
    ..deletedAt = item.deletedAt
    ..syncAction = action.name
    ..deviceId = deviceId
    ..version = item.version;
}

AppliedDiscount? wholeOrderDiscountFromOrder(Order order) {
  if (order.orderDiscountValue == null || order.orderDiscountType == null) {
    return null;
  }

  return AppliedDiscount(
    scope: DiscountScope.wholeOrder,
    type: DiscountType.values.byName(order.orderDiscountType!),
    value: order.orderDiscountValue!,
    reason: order.orderDiscountReason,
  );
}

class OrderDiscountSnapshot {
  const OrderDiscountSnapshot({
    required this.type,
    required this.value,
    this.reason,
  });

  final String type;
  final double value;
  final String? reason;
}

OrderDiscountSnapshot? wholeOrderDiscountSnapshot(
  List<AppliedDiscount> discounts,
) {
  final whole = discounts.where(
    (discount) => discount.scope == DiscountScope.wholeOrder,
  );
  if (whole.isEmpty) return null;
  final discount = whole.first;
  return OrderDiscountSnapshot(
    type: discount.type.name,
    value: discount.value,
    reason: discount.reason,
  );
}
