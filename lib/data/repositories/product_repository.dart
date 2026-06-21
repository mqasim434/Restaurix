import 'package:isar/isar.dart';

import '../../core/sync/sync_action.dart';
import '../../domain/models/product.dart';
import '../local/collections/product_isar.dart';
import '../local/mappers/product_mapper.dart';

class ProductRepository {
  ProductRepository(this._isar);

  final Isar _isar;

  Stream<List<Product>> watchAll() {
    return _isar.productIsars
        .filter()
        .deletedAtIsNull()
        .sortByName()
        .watch(fireImmediately: true)
        .map((records) => records.map(productFromIsar).toList());
  }

  Stream<List<Product>> watchByCategory(String categoryId) {
    return _isar.productIsars
        .filter()
        .deletedAtIsNull()
        .categoryIdEqualTo(categoryId)
        .sortByName()
        .watch(fireImmediately: true)
        .map((records) => records.map(productFromIsar).toList());
  }

  Future<Product?> findById(String id) async {
    final record =
        await _isar.productIsars.filter().uuidEqualTo(id).findFirst();
    if (record == null || record.isDeleted) return null;
    return productFromIsar(record);
  }

  Future<int> countByCategory(String categoryId) async {
    return _isar.productIsars
        .filter()
        .deletedAtIsNull()
        .categoryIdEqualTo(categoryId)
        .count();
  }

  Future<Product> create({
    required String name,
    required String categoryId,
    required double basePrice,
    required String deviceId,
    String? description,
    String? imageUrl,
    bool isAvailable = true,
    String kitchenCategory = '',
    String? printerId,
  }) async {
    final record = ProductIsar.create(
      name: name.trim(),
      categoryId: categoryId,
      basePrice: basePrice,
      deviceId: deviceId,
      description: description?.trim(),
      imageUrl: imageUrl,
      isAvailable: isAvailable,
      kitchenCategory: kitchenCategory.trim(),
      printerId: printerId?.trim(),
    );

    await _isar.writeTxn(() async {
      await _isar.productIsars.put(record);
    });

    return productFromIsar(record);
  }

  Future<Product?> update({
    required Product product,
    required String deviceId,
  }) async {
    final record =
        await _isar.productIsars.filter().uuidEqualTo(product.id).findFirst();
    if (record == null || record.isDeleted) return null;

    applyProductToIsar(
      record: record,
      product: product,
      deviceId: deviceId,
      action: SyncAction.update,
    );

    await _isar.writeTxn(() async {
      await _isar.productIsars.put(record);
    });

    return productFromIsar(record);
  }

  Future<Product?> toggleAvailability({
    required String id,
    required String deviceId,
  }) async {
    final record =
        await _isar.productIsars.filter().uuidEqualTo(id).findFirst();
    if (record == null || record.isDeleted) return null;

    record
      ..isAvailable = !record.isAvailable
      ..markUpdated(deviceId: deviceId);

    await _isar.writeTxn(() async {
      await _isar.productIsars.put(record);
    });

    return productFromIsar(record);
  }

  Future<bool> softDelete({
    required String id,
    required String deviceId,
  }) async {
    final record =
        await _isar.productIsars.filter().uuidEqualTo(id).findFirst();
    if (record == null || record.isDeleted) return false;

    record.markDeleted(deviceId: deviceId);

    await _isar.writeTxn(() async {
      await _isar.productIsars.put(record);
    });

    return true;
  }
}
