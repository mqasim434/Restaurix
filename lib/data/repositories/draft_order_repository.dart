import 'package:isar/isar.dart';

import '../../domain/models/draft_order.dart';
import '../../domain/models/pos_draft_snapshot.dart';
import '../../domain/models/table_status.dart';
import '../local/collections/draft_order_isar.dart';
import '../local/collections/restaurant_table_isar.dart';
import '../local/mappers/draft_order_mapper.dart';

class DraftOrderException implements Exception {
  DraftOrderException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DraftOrderRepository {
  DraftOrderRepository(this._isar);

  final Isar _isar;

  Stream<List<DraftOrder>> watchAll() {
    return _isar.draftOrderIsars
        .filter()
        .deletedAtIsNull()
        .sortByUpdatedAtDesc()
        .watch(fireImmediately: true)
        .map((records) => records.map(draftOrderFromIsar).toList());
  }

  Future<int> countActive() async {
    return _isar.draftOrderIsars.filter().deletedAtIsNull().count();
  }

  Future<DraftOrder> save({
    required PosDraftSnapshot snapshot,
    required String createdByUserId,
    required String deviceId,
    String? label,
  }) async {
    if (snapshot.cartItems.isEmpty) {
      throw DraftOrderException('Add at least one item before saving a draft');
    }

    final record = DraftOrderIsar.create(
      payloadJson: encodeSnapshot(snapshot),
      createdByUserId: createdByUserId,
      deviceId: deviceId,
      label: label,
      tableId: snapshot.checkout.tableId,
    );

    await _isar.writeTxn(() async {
      await _isar.draftOrderIsars.put(record);

      // Keep dine-in tables held while the customer waits — reserved counts as
      // held for draft purposes until the draft is discarded or placed.
      if (snapshot.checkout.tableId != null) {
        await _ensureTableHeld(
          tableId: snapshot.checkout.tableId!,
          deviceId: deviceId,
        );
      }
    });

    return draftOrderFromIsar(record);
  }

  /// Resumes a draft into POS and removes it from the drafts list.
  ///
  /// Drafts are consumed on resume so staff always continue a single active
  /// session without stale duplicate drafts lingering after reopen.
  Future<PosDraftSnapshot> resume({
    required String draftId,
    required String deviceId,
  }) async {
    final record = await _isar.draftOrderIsars
        .filter()
        .uuidEqualTo(draftId)
        .findFirst();
    if (record == null || record.isDeleted) {
      throw DraftOrderException('Draft not found');
    }

    final snapshot = snapshotFromDraft(draftOrderFromIsar(record));

    await _isar.writeTxn(() async {
      record.markDeleted(deviceId: deviceId);
      await _isar.draftOrderIsars.put(record);
    });

    return snapshot;
  }

  Future<void> discard({
    required String draftId,
    required String deviceId,
  }) async {
    final record = await _isar.draftOrderIsars
        .filter()
        .uuidEqualTo(draftId)
        .findFirst();
    if (record == null || record.isDeleted) return;

    await _isar.writeTxn(() async {
      record.markDeleted(deviceId: deviceId);
      await _isar.draftOrderIsars.put(record);

      if (record.tableId != null) {
        await _releaseTableIfHeld(
          tableId: record.tableId!,
          deviceId: deviceId,
        );
      }
    });
  }

  Future<void> _ensureTableHeld({
    required String tableId,
    required String deviceId,
  }) async {
    final table = await _isar.restaurantTableIsars
        .filter()
        .uuidEqualTo(tableId)
        .findFirst();
    if (table == null || table.isDeleted) return;

    if (table.statusEnum == TableStatus.available) {
      table
        ..status = TableStatus.reserved.name
        ..markUpdated(deviceId: deviceId);
      await _isar.restaurantTableIsars.put(table);
    }
  }

  Future<void> _releaseTableIfHeld({
    required String tableId,
    required String deviceId,
  }) async {
    final table = await _isar.restaurantTableIsars
        .filter()
        .uuidEqualTo(tableId)
        .findFirst();
    if (table == null || table.isDeleted) return;

    if (table.statusEnum == TableStatus.reserved &&
        table.currentOrderId == null) {
      table
        ..status = TableStatus.available.name
        ..markUpdated(deviceId: deviceId);
      await _isar.restaurantTableIsars.put(table);
    }
  }
}
