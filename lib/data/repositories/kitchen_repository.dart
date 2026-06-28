import 'dart:async';

import 'package:isar/isar.dart';

import '../../core/sync/sync_action.dart';
import '../../domain/models/kitchen_board.dart';
import '../../domain/models/order_item.dart';
import '../../domain/services/kitchen_status_timestamps.dart';
import '../../domain/services/kitchen_lifecycle.dart';
import '../../domain/services/kitchen_prep_timer.dart';
import '../local/collections/order_isar.dart';
import '../local/collections/restaurant_table_isar.dart';
import '../local/mappers/order_mapper.dart';
import '../local/mappers/restaurant_table_mapper.dart';

class KitchenRepository {
  KitchenRepository(this._isar);

  final Isar _isar;

  Stream<KitchenBoard> watchBoard() {
    late StreamSubscription<List<OrderIsar>> ordersSub;
    late StreamSubscription<List<OrderItemIsar>> itemsSub;
    final controller = StreamController<KitchenBoard>();

    Future<void> emit() async {
      if (controller.isClosed) return;
      controller.add(await _loadBoard());
    }

    ordersSub = _isar.orderIsars
        .filter()
        .deletedAtIsNull()
        .watch(fireImmediately: true)
        .listen((_) => emit());

    itemsSub = _isar.orderItemIsars
        .filter()
        .deletedAtIsNull()
        .watch(fireImmediately: true)
        .listen((_) => emit());

    controller.onCancel = () async {
      await ordersSub.cancel();
      await itemsSub.cancel();
    };

    return controller.stream;
  }

  Future<void> processDueItems({required String deviceId}) async {
    final now = DateTime.now();
    final orderRecords = await _isar.orderIsars
        .filter()
        .deletedAtIsNull()
        .findAll();

    final heldByOrderId = <String, bool>{
      for (final record in orderRecords)
        record.uuid: record.isHeld,
    };

    final itemRecords = await _isar.orderItemIsars
        .filter()
        .deletedAtIsNull()
        .findAll();

    final dueItemIds = <String>[];
    for (final record in itemRecords) {
      final item = orderItemFromIsar(record);
      if (!KitchenLifecycle.isItemVisibleOnKitchen(item)) continue;

      final due = KitchenPrepTimer.dueAdvanceStatus(
        item: item,
        now: now,
        orderIsHeld: heldByOrderId[item.orderId] ?? false,
      );
      if (due != null) {
        dueItemIds.add(item.id);
      }
    }

    if (dueItemIds.isEmpty) return;

    for (final itemId in dueItemIds) {
      await _advanceItemRecord(orderItemId: itemId, deviceId: deviceId);
    }
  }

  Future<KitchenBoard> _loadBoard() async {
    final orderRecords = await _isar.orderIsars
        .filter()
        .deletedAtIsNull()
        .findAll();

    final orders = orderRecords
        .map(orderFromIsar)
        .where(KitchenLifecycle.isOrderVisibleOnKitchen)
        .toList();

    if (orders.isEmpty) {
      return const KitchenBoard();
    }

    final orderIds = orders.map((order) => order.id).toSet();
    final itemRecords = await _isar.orderItemIsars
        .filter()
        .deletedAtIsNull()
        .findAll();

    final itemsByOrderId = <String, List<OrderItem>>{};
    for (final record in itemRecords) {
      if (!orderIds.contains(record.orderId)) continue;
      itemsByOrderId
          .putIfAbsent(record.orderId, () => [])
          .add(orderItemFromIsar(record));
    }

    final tableIds = orders
        .map((order) => order.tableId)
        .whereType<String>()
        .toSet();

    final tableLabelsById = <String, String>{};
    if (tableIds.isNotEmpty) {
      final tableRecords = await _isar.restaurantTableIsars
          .filter()
          .deletedAtIsNull()
          .findAll();
      for (final record in tableRecords) {
        if (tableIds.contains(record.uuid)) {
          tableLabelsById[record.uuid] = restaurantTableFromIsar(record).label;
        }
      }
    }

    return KitchenLifecycle.buildBoard(
      orders: orders,
      itemsByOrderId: itemsByOrderId,
      tableLabelsById: tableLabelsById,
    );
  }

  Future<void> _advanceItemRecord({
    required String orderItemId,
    required String deviceId,
  }) async {
    await _isar.writeTxn(() async {
      final record = await _isar.orderItemIsars
          .filter()
          .uuidEqualTo(orderItemId)
          .findFirst();

      if (record == null || record.isDeleted) return;

      final item = orderItemFromIsar(record);
      final next = KitchenLifecycle.nextItemStatus(item.kitchenStatus);
      if (next == null) return;

      final now = DateTime.now();
      record
        ..kitchenStatus = next.name
        ..kitchenStatusChangedAt = now;
      KitchenStatusTimestamps.applyTransition(
        nextStatus: next,
        now: now,
        currentKitchenReadyAt: record.kitchenReadyAt,
        setKitchenReadyAt: (value) => record.kitchenReadyAt = value,
      );
      record.markUpdated(deviceId: deviceId, action: SyncAction.update);
      await _isar.orderItemIsars.put(record);

      await _syncOrderStatusFromItems(
        orderId: item.orderId,
        deviceId: deviceId,
      );
    });
  }

  Future<void> _syncOrderStatusFromItems({
    required String orderId,
    required String deviceId,
  }) async {
    final orderRecord = await _isar.orderIsars
        .filter()
        .uuidEqualTo(orderId)
        .findFirst();
    if (orderRecord == null || orderRecord.isDeleted) return;

    final order = orderFromIsar(orderRecord);
    if (!KitchenLifecycle.isOrderVisibleOnKitchen(order)) return;

    final itemRecords = await _isar.orderItemIsars
        .filter()
        .deletedAtIsNull()
        .orderIdEqualTo(orderId)
        .findAll();
    final items = itemRecords.map(orderItemFromIsar).toList();

    final derived = KitchenLifecycle.deriveOrderStatus(order, items);
    if (derived == null || derived == order.status) return;

    final updated = order.copyWith(status: derived);
    applyOrderToIsar(
      record: orderRecord,
      order: updated,
      deviceId: deviceId,
      action: SyncAction.update,
    );
    await _isar.orderIsars.put(orderRecord);
  }
}
