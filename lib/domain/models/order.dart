import '../../core/sync/sync_action.dart';
import '../../core/sync/syncable_entity.dart';
import 'order_enums.dart';

class Order implements SyncableEntity {
  const Order({
    required this.id,
    required this.orderNumber,
    required this.orderType,
    this.tableId,
    this.deliveryMode,
    this.riderId,
    this.riderName,
    this.pickupCompanyId,
    this.pickupCompanyName,
    required this.subtotal,
    required this.itemDiscountTotal,
    required this.orderDiscountTotal,
    required this.total,
    this.paymentType,
    required this.paymentStatus,
    required this.status,
    required this.isPrepaid,
    required this.createdByUserId,
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
  final String orderNumber;
  final OrderType orderType;
  final String? tableId;
  final DeliveryMode? deliveryMode;
  final String? riderId;
  final String? riderName;
  final String? pickupCompanyId;
  final String? pickupCompanyName;
  final double subtotal;
  final double itemDiscountTotal;
  final double orderDiscountTotal;
  final double total;
  final PaymentType? paymentType;
  final OrderPaymentStatus paymentStatus;
  final OrderStatus status;
  final bool isPrepaid;
  final String createdByUserId;
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

  bool get isActiveOnTable =>
      orderType == OrderType.dineIn &&
      tableId != null &&
      !status.isClosed &&
      paymentStatus != OrderPaymentStatus.refunded;

  bool get canReleaseTableWithoutOverride =>
      status.isClosed || paymentStatus.isSettled;

  Order copyWith({
    String? tableId,
    bool clearTableId = false,
    double? subtotal,
    double? itemDiscountTotal,
    double? orderDiscountTotal,
    double? total,
    PaymentType? paymentType,
    OrderPaymentStatus? paymentStatus,
    OrderStatus? status,
    bool? isPrepaid,
    String? notes,
    DateTime? updatedAt,
    bool? isSynced,
    DateTime? deletedAt,
    SyncAction? syncAction,
    String? deviceId,
    int? version,
  }) {
    return Order(
      id: id,
      orderNumber: orderNumber,
      orderType: orderType,
      tableId: clearTableId ? null : (tableId ?? this.tableId),
      deliveryMode: deliveryMode,
      riderId: riderId,
      riderName: riderName,
      pickupCompanyId: pickupCompanyId,
      pickupCompanyName: pickupCompanyName,
      subtotal: subtotal ?? this.subtotal,
      itemDiscountTotal: itemDiscountTotal ?? this.itemDiscountTotal,
      orderDiscountTotal: orderDiscountTotal ?? this.orderDiscountTotal,
      total: total ?? this.total,
      paymentType: paymentType ?? this.paymentType,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      status: status ?? this.status,
      isPrepaid: isPrepaid ?? this.isPrepaid,
      createdByUserId: createdByUserId,
      notes: notes ?? this.notes,
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
