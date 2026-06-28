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
    this.isHeld = false,
    required this.createdByUserId,
    this.notes,
    this.cancelReason,
    this.cancelRefundNote,
    this.orderDiscountType,
    this.orderDiscountValue,
    this.orderDiscountReason,
    this.promisedPrepMinutes,
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
  final bool isHeld;
  final String createdByUserId;
  final String? notes;
  final String? cancelReason;
  final String? cancelRefundNote;
  final String? orderDiscountType;
  final double? orderDiscountValue;
  final String? orderDiscountReason;
  /// Waiter/tablet override for customer-promised wait time (minutes).
  final int? promisedPrepMinutes;

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
    DeliveryMode? deliveryMode,
    String? riderId,
    String? riderName,
    String? pickupCompanyId,
    String? pickupCompanyName,
    double? subtotal,
    double? itemDiscountTotal,
    double? orderDiscountTotal,
    double? total,
    PaymentType? paymentType,
    OrderPaymentStatus? paymentStatus,
    OrderStatus? status,
    bool? isPrepaid,
    bool? isHeld,
    String? notes,
    String? cancelReason,
    String? cancelRefundNote,
    String? orderDiscountType,
    double? orderDiscountValue,
    String? orderDiscountReason,
    int? promisedPrepMinutes,
    bool clearPromisedPrepMinutes = false,
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
      deliveryMode: deliveryMode ?? this.deliveryMode,
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      pickupCompanyId: pickupCompanyId ?? this.pickupCompanyId,
      pickupCompanyName: pickupCompanyName ?? this.pickupCompanyName,
      subtotal: subtotal ?? this.subtotal,
      itemDiscountTotal: itemDiscountTotal ?? this.itemDiscountTotal,
      orderDiscountTotal: orderDiscountTotal ?? this.orderDiscountTotal,
      total: total ?? this.total,
      paymentType: paymentType ?? this.paymentType,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      status: status ?? this.status,
      isPrepaid: isPrepaid ?? this.isPrepaid,
      isHeld: isHeld ?? this.isHeld,
      createdByUserId: createdByUserId,
      notes: notes ?? this.notes,
      cancelReason: cancelReason ?? this.cancelReason,
      cancelRefundNote: cancelRefundNote ?? this.cancelRefundNote,
      orderDiscountType: orderDiscountType ?? this.orderDiscountType,
      orderDiscountValue: orderDiscountValue ?? this.orderDiscountValue,
      orderDiscountReason:
          orderDiscountReason ?? this.orderDiscountReason,
      promisedPrepMinutes: clearPromisedPrepMinutes
          ? null
          : (promisedPrepMinutes ?? this.promisedPrepMinutes),
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
