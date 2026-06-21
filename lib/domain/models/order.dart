import '../../core/sync/sync_action.dart';
import '../../core/sync/syncable_entity.dart';
import 'order_enums.dart';

/// Minimal order entity for table management — expanded in later modules.
class Order implements SyncableEntity {
  const Order({
    required this.id,
    required this.orderNumber,
    required this.orderType,
    this.tableId,
    required this.subtotal,
    required this.total,
    required this.paymentStatus,
    required this.status,
    required this.createdByUserId,
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
  final double subtotal;
  final double total;
  final OrderPaymentStatus paymentStatus;
  final OrderStatus status;
  final String createdByUserId;

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
    double? total,
    OrderPaymentStatus? paymentStatus,
    OrderStatus? status,
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
      subtotal: subtotal ?? this.subtotal,
      total: total ?? this.total,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      status: status ?? this.status,
      createdByUserId: createdByUserId,
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
