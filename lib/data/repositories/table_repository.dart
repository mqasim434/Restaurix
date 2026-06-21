import 'package:isar/isar.dart';

import '../../core/sync/sync_action.dart';
import '../../domain/models/order.dart';
import '../../domain/models/restaurant_table.dart';
import '../../domain/models/table_status.dart';
import '../local/collections/order_isar.dart';
import '../local/collections/restaurant_table_isar.dart';
import '../local/mappers/order_mapper.dart';
import '../local/mappers/restaurant_table_mapper.dart';

class TableTransferException implements Exception {
  TableTransferException(this.message);

  final String message;

  @override
  String toString() => message;
}

class TableRepository {
  TableRepository(this._isar);

  final Isar _isar;

  Stream<List<RestaurantTable>> watchByHall(String hallId) {
    return _isar.restaurantTableIsars
        .filter()
        .deletedAtIsNull()
        .hallIdEqualTo(hallId)
        .sortBySortOrder()
        .watch(fireImmediately: true)
        .map((records) => records.map(restaurantTableFromIsar).toList());
  }

  /// Available tables only — occupied/reserved tables hidden from POS picker.
  Stream<List<RestaurantTable>> watchAvailableForPos() {
    return _isar.restaurantTableIsars
        .filter()
        .deletedAtIsNull()
        .statusEqualTo(TableStatus.available.name)
        .sortByLabel()
        .watch(fireImmediately: true)
        .map((records) => records.map(restaurantTableFromIsar).toList());
  }

  Future<void> reserveForCheckout({
    required String tableId,
    required String deviceId,
  }) async {
    final record = await _isar.restaurantTableIsars
        .filter()
        .uuidEqualTo(tableId)
        .findFirst();
    if (record == null || record.isDeleted) {
      throw TableTransferException('Table not found');
    }
    if (record.statusEnum != TableStatus.available) {
      throw TableTransferException('Table is not available');
    }

    record
      ..status = TableStatus.reserved.name
      ..markUpdated(deviceId: deviceId);

    await _isar.writeTxn(() async {
      await _isar.restaurantTableIsars.put(record);
    });
  }

  Future<void> releaseCheckoutReservation({
    required String tableId,
    required String deviceId,
  }) async {
    final record = await _isar.restaurantTableIsars
        .filter()
        .uuidEqualTo(tableId)
        .findFirst();
    if (record == null || record.isDeleted) return;

    if (record.statusEnum == TableStatus.reserved) {
      record
        ..status = TableStatus.available.name
        ..markUpdated(deviceId: deviceId);

      await _isar.writeTxn(() async {
        await _isar.restaurantTableIsars.put(record);
      });
    }
  }

  Future<RestaurantTable?> findById(String id) async {
    final record =
        await _isar.restaurantTableIsars.filter().uuidEqualTo(id).findFirst();
    if (record == null || record.isDeleted) return null;
    return restaurantTableFromIsar(record);
  }

  Future<Order?> findOrderById(String id) async {
    final record =
        await _isar.orderIsars.filter().uuidEqualTo(id).findFirst();
    if (record == null || record.isDeleted) return null;
    return orderFromIsar(record);
  }

  Future<RestaurantTable> create({
    required String hallId,
    required String label,
    required String deviceId,
    int capacity = 4,
  }) async {
    final sortOrder = await _nextSortOrder(hallId);
    final record = RestaurantTableIsar.create(
      hallId: hallId,
      label: label.trim(),
      deviceId: deviceId,
      sortOrder: sortOrder,
      capacity: capacity,
    );

    await _isar.writeTxn(() async {
      await _isar.restaurantTableIsars.put(record);
    });

    return restaurantTableFromIsar(record);
  }

  Future<RestaurantTable?> update({
    required RestaurantTable table,
    required String deviceId,
  }) async {
    final record = await _isar.restaurantTableIsars
        .filter()
        .uuidEqualTo(table.id)
        .findFirst();
    if (record == null || record.isDeleted) return null;

    applyRestaurantTableToIsar(
      record: record,
      table: table,
      deviceId: deviceId,
      action: SyncAction.update,
    );

    await _isar.writeTxn(() async {
      await _isar.restaurantTableIsars.put(record);
    });

    return restaurantTableFromIsar(record);
  }

  Future<RestaurantTable?> setStatus({
    required String tableId,
    required TableStatus status,
    required String deviceId,
    bool forceRelease = false,
  }) async {
    final record = await _isar.restaurantTableIsars
        .filter()
        .uuidEqualTo(tableId)
        .findFirst();
    if (record == null || record.isDeleted) return null;

    if (status == TableStatus.available &&
        record.statusEnum == TableStatus.occupied &&
        record.currentOrderId != null &&
        !forceRelease) {
      final order = await findOrderById(record.currentOrderId!);
      if (order != null && order.isActiveOnTable) {
        throw TableTransferException(
          'Table has an active unpaid order — complete payment or use force release',
        );
      }
    }

    record
      ..status = status.name
      ..markUpdated(deviceId: deviceId);

    if (status == TableStatus.available) {
      record.currentOrderId = null;
    }

    await _isar.writeTxn(() async {
      await _isar.restaurantTableIsars.put(record);
    });

    return restaurantTableFromIsar(record);
  }

  Future<Order> startDineInOrder({
    required String tableId,
    required String createdByUserId,
    required String deviceId,
  }) async {
    final tableRecord = await _isar.restaurantTableIsars
        .filter()
        .uuidEqualTo(tableId)
        .findFirst();
    if (tableRecord == null || tableRecord.isDeleted) {
      throw TableTransferException('Table not found');
    }
    if (tableRecord.statusEnum == TableStatus.occupied) {
      throw TableTransferException('Table is already occupied');
    }

    final orderNumber = await _nextOrderNumber();
    final orderRecord = OrderIsar.createDineIn(
      tableId: tableId,
      orderNumber: orderNumber,
      createdByUserId: createdByUserId,
      deviceId: deviceId,
    );

    await _isar.writeTxn(() async {
      await _isar.orderIsars.put(orderRecord);

      tableRecord
        ..status = TableStatus.occupied.name
        ..currentOrderId = orderRecord.uuid
        ..markUpdated(deviceId: deviceId);

      await _isar.restaurantTableIsars.put(tableRecord);
    });

    return orderFromIsar(orderRecord);
  }

  Future<void> transferOrder({
    required String fromTableId,
    required String toTableId,
    required String deviceId,
  }) async {
    if (fromTableId == toTableId) {
      throw TableTransferException('Choose a different destination table');
    }

    final fromRecord = await _isar.restaurantTableIsars
        .filter()
        .uuidEqualTo(fromTableId)
        .findFirst();
    final toRecord = await _isar.restaurantTableIsars
        .filter()
        .uuidEqualTo(toTableId)
        .findFirst();

    if (fromRecord == null ||
        fromRecord.isDeleted ||
        toRecord == null ||
        toRecord.isDeleted) {
      throw TableTransferException('Table not found');
    }

    if (fromRecord.statusEnum != TableStatus.occupied ||
        fromRecord.currentOrderId == null) {
      throw TableTransferException('Source table has no active order');
    }

    if (toRecord.statusEnum == TableStatus.occupied) {
      throw TableTransferException('Destination table is already occupied');
    }

    final orderRecord = await _isar.orderIsars
        .filter()
        .uuidEqualTo(fromRecord.currentOrderId!)
        .findFirst();
    if (orderRecord == null || orderRecord.isDeleted) {
      throw TableTransferException('Active order not found');
    }

    await _isar.writeTxn(() async {
      orderRecord
        ..tableId = toTableId
        ..markUpdated(deviceId: deviceId);
      await _isar.orderIsars.put(orderRecord);

      final orderId = fromRecord.currentOrderId!;
      fromRecord
        ..status = TableStatus.available.name
        ..currentOrderId = null
        ..markUpdated(deviceId: deviceId);
      await _isar.restaurantTableIsars.put(fromRecord);

      toRecord
        ..status = TableStatus.occupied.name
        ..currentOrderId = orderId
        ..markUpdated(deviceId: deviceId);
      await _isar.restaurantTableIsars.put(toRecord);
    });
  }

  Future<bool> softDelete({
    required String id,
    required String deviceId,
  }) async {
    final record =
        await _isar.restaurantTableIsars.filter().uuidEqualTo(id).findFirst();
    if (record == null || record.isDeleted) return false;

    if (record.statusEnum == TableStatus.occupied) {
      throw TableTransferException('Cannot delete an occupied table');
    }

    record.markDeleted(deviceId: deviceId);

    await _isar.writeTxn(() async {
      await _isar.restaurantTableIsars.put(record);
    });

    return true;
  }

  Future<int> _nextSortOrder(String hallId) async {
    final records = await _isar.restaurantTableIsars
        .filter()
        .deletedAtIsNull()
        .hallIdEqualTo(hallId)
        .sortBySortOrderDesc()
        .findAll();
    if (records.isEmpty) return 0;
    return records.first.sortOrder + 1;
  }

  Future<String> _nextOrderNumber() async {
    final count = await _isar.orderIsars.filter().deletedAtIsNull().count();
    return 'T-${(count + 1).toString().padLeft(4, '0')}';
  }
}
