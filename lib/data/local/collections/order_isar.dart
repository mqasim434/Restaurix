import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../../core/sync/sync_action.dart';
import '../../../domain/models/order_enums.dart';

part 'order_isar.g.dart';

/// Minimal order storage for table assignment — full order module expands this.
@collection
class OrderIsar {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;

  late String orderNumber;

  late String orderType;

  @Index()
  String? tableId;

  double subtotal = 0;

  double total = 0;

  late String paymentStatus;

  @Index()
  late String status;

  late String createdByUserId;

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
      ..total = 0
      ..paymentStatus = OrderPaymentStatus.unpaid.name
      ..status = OrderStatus.received.name
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
