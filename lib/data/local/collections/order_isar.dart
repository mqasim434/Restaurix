import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../../core/sync/sync_action.dart';
import '../../../domain/models/order_enums.dart';

part 'order_isar.g.dart';

@embedded
class OrderItemModifierEmbedded {
  String? modifierId;
  late String name;
  double priceDelta = 0;
}

@embedded
class OrderLineDiscountEmbedded {
  late String scope;
  late String type;
  double value = 0;
  double amountApplied = 0;
  String? reason;
}

@collection
class OrderIsar {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;

  @Index()
  late String orderNumber;

  late String orderType;

  @Index()
  String? tableId;

  String? deliveryMode;

  String? riderId;
  String? riderName;
  String? pickupCompanyId;
  String? pickupCompanyName;

  double subtotal = 0;
  double itemDiscountTotal = 0;
  double orderDiscountTotal = 0;
  double total = 0;

  String? paymentType;

  late String paymentStatus;

  @Index()
  late String status;

  bool isPrepaid = false;

  late String createdByUserId;

  String? notes;

  late DateTime createdAt;
  late DateTime updatedAt;

  bool isSynced = false;

  DateTime? deletedAt;

  late String syncAction;

  late String deviceId;

  int version = 1;

  @ignore
  OrderType get orderTypeEnum => OrderType.values.firstWhere(
        (t) => t.wireValue == orderType,
        orElse: () => OrderType.dineIn,
      );

  @ignore
  DeliveryMode? get deliveryModeEnum {
    if (deliveryMode == null) return null;
    return DeliveryMode.values.firstWhere(
      (m) => m.wireValue == deliveryMode,
      orElse: () => DeliveryMode.ownRider,
    );
  }

  @ignore
  PaymentType? get paymentTypeEnum {
    if (paymentType == null) return null;
    return PaymentType.values.byName(paymentType!);
  }

  @ignore
  OrderPaymentStatus get paymentStatusEnum =>
      OrderPaymentStatus.values.byName(paymentStatus);

  @ignore
  OrderStatus get statusEnum => OrderStatus.values.byName(status);

  @ignore
  SyncAction get syncActionEnum => SyncAction.values.byName(syncAction);

  @ignore
  bool get isDeleted => deletedAt != null;

  static OrderIsar createDineIn({
    required String tableId,
    required String orderNumber,
    required String createdByUserId,
    required String deviceId,
  }) {
    final now = DateTime.now();
    return OrderIsar()
      ..uuid = const Uuid().v4()
      ..orderNumber = orderNumber
      ..orderType = OrderType.dineIn.wireValue
      ..tableId = tableId
      ..subtotal = 0
      ..itemDiscountTotal = 0
      ..orderDiscountTotal = 0
      ..total = 0
      ..paymentStatus = OrderPaymentStatus.unpaid.name
      ..status = OrderStatus.received.name
      ..isPrepaid = false
      ..createdByUserId = createdByUserId
      ..createdAt = now
      ..updatedAt = now
      ..isSynced = false
      ..syncAction = SyncAction.create.name
      ..deviceId = deviceId
      ..version = 1;
  }

  OrderIsar markUpdated({required String deviceId, SyncAction? action}) {
    updatedAt = DateTime.now();
    isSynced = false;
    syncAction = (action ?? SyncAction.update).name;
    this.deviceId = deviceId;
    version += 1;
    return this;
  }

  OrderIsar markDeleted({required String deviceId}) {
    deletedAt = DateTime.now();
    updatedAt = deletedAt!;
    isSynced = false;
    syncAction = SyncAction.delete.name;
    this.deviceId = deviceId;
    version += 1;
    return this;
  }
}

@collection
class OrderItemIsar {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;

  @Index()
  late String orderId;

  String? productId;
  String? dealId;

  late String name;
  String? variantName;

  double unitPrice = 0;
  int quantity = 1;
  double lineTotal = 0;

  List<OrderItemModifierEmbedded> modifiers = [];
  List<OrderLineDiscountEmbedded> appliedDiscounts = [];

  late String kitchenStatus;

  late DateTime createdAt;
  late DateTime updatedAt;

  bool isSynced = false;

  DateTime? deletedAt;

  late String syncAction;

  late String deviceId;

  int version = 1;

  @ignore
  KitchenStatus get kitchenStatusEnum =>
      KitchenStatus.values.byName(kitchenStatus);

  @ignore
  SyncAction get syncActionEnum => SyncAction.values.byName(syncAction);

  @ignore
  bool get isDeleted => deletedAt != null;
}
