import 'package:isar/isar.dart';

import '../../core/sync/sync_action.dart';
import '../../domain/models/deal.dart';
import '../../domain/models/deal_item.dart';
import '../local/collections/deal_isar.dart';
import '../local/collections/deal_item_isar.dart';
import '../local/mappers/deal_mapper.dart';

class DealRepository {
  DealRepository(this._isar);

  final Isar _isar;

  Stream<List<Deal>> watchAll() {
    return _isar.dealIsars
        .filter()
        .deletedAtIsNull()
        .sortByName()
        .watch(fireImmediately: true)
        .map((records) => records.map(dealFromIsar).toList());
  }

  Stream<List<DealItem>> watchItemsByDealId(String dealId) {
    return _isar.dealItemIsars
        .filter()
        .dealIdEqualTo(dealId)
        .deletedAtIsNull()
        .watch(fireImmediately: true)
        .map((records) => records.map(dealItemFromIsar).toList());
  }

  Future<List<DealItem>> getItemsByDealId(String dealId) async {
    final records = await _isar.dealItemIsars
        .filter()
        .dealIdEqualTo(dealId)
        .deletedAtIsNull()
        .findAll();
    return records.map(dealItemFromIsar).toList();
  }

  Future<Deal?> findById(String id) async {
    final record = await _isar.dealIsars.filter().uuidEqualTo(id).findFirst();
    if (record == null || record.isDeleted) return null;
    return dealFromIsar(record);
  }

  Future<Deal> create({
    required String name,
    required double price,
    required String deviceId,
    String? description,
    String? imageUrl,
    String? categoryId,
    bool isAvailable = true,
    DateTime? availabilityStart,
    DateTime? availabilityEnd,
  }) async {
    final record = DealIsar.create(
      name: name.trim(),
      price: price,
      deviceId: deviceId,
      description: description?.trim(),
      imageUrl: imageUrl,
      categoryId: categoryId,
      isAvailable: isAvailable,
      availabilityStart: availabilityStart,
      availabilityEnd: availabilityEnd,
    );

    await _isar.writeTxn(() async {
      await _isar.dealIsars.put(record);
    });

    return dealFromIsar(record);
  }

  Future<Deal?> update({
    required Deal deal,
    required String deviceId,
  }) async {
    final record =
        await _isar.dealIsars.filter().uuidEqualTo(deal.id).findFirst();
    if (record == null || record.isDeleted) return null;

    applyDealToIsar(
      record: record,
      deal: deal,
      deviceId: deviceId,
      action: SyncAction.update,
    );

    await _isar.writeTxn(() async {
      await _isar.dealIsars.put(record);
    });

    return dealFromIsar(record);
  }

  Future<Deal?> toggleAvailability({
    required String id,
    required String deviceId,
  }) async {
    final record =
        await _isar.dealIsars.filter().uuidEqualTo(id).findFirst();
    if (record == null || record.isDeleted) return null;

    record
      ..isAvailable = !record.isAvailable
      ..markUpdated(deviceId: deviceId);

    await _isar.writeTxn(() async {
      await _isar.dealIsars.put(record);
    });

    return dealFromIsar(record);
  }

  Future<bool> softDelete({
    required String id,
    required String deviceId,
  }) async {
    final record =
        await _isar.dealIsars.filter().uuidEqualTo(id).findFirst();
    if (record == null || record.isDeleted) return false;

    await _isar.writeTxn(() async {
      record.markDeleted(deviceId: deviceId);
      await _isar.dealIsars.put(record);

      final items = await _isar.dealItemIsars
          .filter()
          .dealIdEqualTo(id)
          .deletedAtIsNull()
          .findAll();
      for (final item in items) {
        item.markDeleted(deviceId: deviceId);
        await _isar.dealItemIsars.put(item);
      }
    });

    return true;
  }

  Future<DealItem> createItem({
    required String dealId,
    required String productId,
    required String deviceId,
    String? variantId,
    int quantity = 1,
  }) async {
    final record = DealItemIsar.create(
      dealId: dealId,
      productId: productId,
      deviceId: deviceId,
      variantId: variantId,
      quantity: quantity,
    );

    await _isar.writeTxn(() async {
      await _isar.dealItemIsars.put(record);
    });

    return dealItemFromIsar(record);
  }

  Future<DealItem?> updateItem({
    required DealItem item,
    required String deviceId,
  }) async {
    final record =
        await _isar.dealItemIsars.filter().uuidEqualTo(item.id).findFirst();
    if (record == null || record.isDeleted) return null;

    applyDealItemToIsar(
      record: record,
      item: item,
      deviceId: deviceId,
      action: SyncAction.update,
    );

    await _isar.writeTxn(() async {
      await _isar.dealItemIsars.put(record);
    });

    return dealItemFromIsar(record);
  }

  Future<bool> softDeleteItem({
    required String id,
    required String deviceId,
  }) async {
    final record =
        await _isar.dealItemIsars.filter().uuidEqualTo(id).findFirst();
    if (record == null || record.isDeleted) return false;

    record.markDeleted(deviceId: deviceId);

    await _isar.writeTxn(() async {
      await _isar.dealItemIsars.put(record);
    });

    return true;
  }
}
