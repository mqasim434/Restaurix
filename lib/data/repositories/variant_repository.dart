import 'package:isar/isar.dart';

import '../../core/sync/sync_action.dart';
import '../../domain/models/product_variant.dart';
import '../local/collections/product_variant_isar.dart';
import '../local/mappers/product_variant_mapper.dart';

class VariantRepository {
  VariantRepository(this._isar);

  final Isar _isar;

  Stream<List<ProductVariant>> watchByProductId(String productId) {
    return _isar.productVariantIsars
        .filter()
        .productIdEqualTo(productId)
        .deletedAtIsNull()
        .sortBySortOrder()
        .watch(fireImmediately: true)
        .map((records) => records.map(productVariantFromIsar).toList());
  }

  Future<List<ProductVariant>> getByProductId(String productId) async {
    final records = await _isar.productVariantIsars
        .filter()
        .productIdEqualTo(productId)
        .deletedAtIsNull()
        .sortBySortOrder()
        .findAll();
    return records.map(productVariantFromIsar).toList();
  }

  Future<ProductVariant> create({
    required String productId,
    required String name,
    required double price,
    required String deviceId,
    bool isDefault = false,
  }) async {
    final existing = await getByProductId(productId);
    final sortOrder = existing.isEmpty ? 0 : existing.last.sortOrder + 1;
    final shouldBeDefault = isDefault || existing.isEmpty;

    late ProductVariantIsar record;

    await _isar.writeTxn(() async {
      if (shouldBeDefault) {
        await _clearDefaultForProduct(productId, deviceId);
      }

      record = ProductVariantIsar.create(
        productId: productId,
        name: name.trim(),
        price: price,
        deviceId: deviceId,
        sortOrder: sortOrder,
        isDefault: shouldBeDefault,
      );

      await _isar.productVariantIsars.put(record);
    });

    return productVariantFromIsar(record);
  }

  Future<ProductVariant?> update({
    required ProductVariant variant,
    required String deviceId,
  }) async {
    final record = await _isar.productVariantIsars
        .filter()
        .uuidEqualTo(variant.id)
        .findFirst();
    if (record == null || record.isDeleted) return null;

    await _isar.writeTxn(() async {
      if (variant.isDefault) {
        await _clearDefaultForProduct(variant.productId, deviceId,
            exceptVariantId: variant.id);
      }

      applyVariantToIsar(
        record: record,
        variant: variant,
        deviceId: deviceId,
        action: SyncAction.update,
      );

      await _isar.productVariantIsars.put(record);
    });

    return productVariantFromIsar(record);
  }

  Future<ProductVariant?> setDefault({
    required String variantId,
    required String productId,
    required String deviceId,
  }) async {
    final record = await _isar.productVariantIsars
        .filter()
        .uuidEqualTo(variantId)
        .findFirst();
    if (record == null || record.isDeleted) return null;

    await _isar.writeTxn(() async {
      await _clearDefaultForProduct(productId, deviceId, exceptVariantId: variantId);

      record
        ..isDefault = true
        ..markUpdated(deviceId: deviceId);

      await _isar.productVariantIsars.put(record);
    });

    return productVariantFromIsar(record);
  }

  Future<bool> softDelete({
    required String id,
    required String deviceId,
  }) async {
    final record =
        await _isar.productVariantIsars.filter().uuidEqualTo(id).findFirst();
    if (record == null || record.isDeleted) return false;

    final wasDefault = record.isDefault;
    final productId = record.productId;

    await _isar.writeTxn(() async {
      record.markDeleted(deviceId: deviceId);
      await _isar.productVariantIsars.put(record);

      if (wasDefault) {
        final remaining = await _isar.productVariantIsars
            .filter()
            .productIdEqualTo(productId)
            .deletedAtIsNull()
            .sortBySortOrder()
            .findAll();
        if (remaining.length == 1) {
          remaining.first
            ..isDefault = true
            ..markUpdated(deviceId: deviceId);
          await _isar.productVariantIsars.put(remaining.first);
        }
      }
    });

    return true;
  }

  Future<void> reorder({
    required String productId,
    required List<String> idsInOrder,
    required String deviceId,
  }) async {
    await _isar.writeTxn(() async {
      for (var index = 0; index < idsInOrder.length; index++) {
        final record = await _isar.productVariantIsars
            .filter()
            .uuidEqualTo(idsInOrder[index])
            .findFirst();
        if (record == null || record.isDeleted) continue;

        record
          ..sortOrder = index
          ..markUpdated(deviceId: deviceId);

        await _isar.productVariantIsars.put(record);
      }
    });
  }

  Future<void> _clearDefaultForProduct(
    String productId,
    String deviceId, {
    String? exceptVariantId,
  }) async {
    final defaults = await _isar.productVariantIsars
        .filter()
        .productIdEqualTo(productId)
        .deletedAtIsNull()
        .isDefaultEqualTo(true)
        .findAll();

    for (final record in defaults) {
      if (record.uuid == exceptVariantId) continue;
      record
        ..isDefault = false
        ..markUpdated(deviceId: deviceId);
      await _isar.productVariantIsars.put(record);
    }
  }
}
