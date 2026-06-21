import '../../core/sync/sync_action.dart';
import '../../core/sync/syncable_entity.dart';
import 'discount.dart';
import 'order_enums.dart';

class OrderItemModifier {
  const OrderItemModifier({
    this.modifierId,
    required this.name,
    required this.priceDelta,
  });

  final String? modifierId;
  final String name;
  final double priceDelta;
}

class OrderLineDiscount {
  const OrderLineDiscount({
    required this.scope,
    required this.type,
    required this.value,
    required this.amountApplied,
    this.targetId,
    this.reason,
  });

  final DiscountScope scope;
  final DiscountType type;
  final double value;
  final double amountApplied;
  final String? targetId;
  final String? reason;
}

class OrderItem implements SyncableEntity {
  const OrderItem({
    required this.id,
    required this.orderId,
    this.productId,
    this.dealId,
    required this.name,
    this.variantName,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    this.modifiers = const [],
    this.appliedDiscounts = const [],
    required this.kitchenStatus,
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
  final String orderId;
  final String? productId;
  final String? dealId;
  final String name;
  final String? variantName;
  final double unitPrice;
  final int quantity;
  final double lineTotal;
  final List<OrderItemModifier> modifiers;
  final List<OrderLineDiscount> appliedDiscounts;
  final KitchenStatus kitchenStatus;

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
}
