import 'package:isar/isar.dart';

import '../../core/sync/sync_action.dart';
import '../../domain/models/category.dart';
import '../local/collections/category_isar.dart';
import '../local/collections/product_isar.dart';
import '../local/mappers/category_mapper.dart';

class CategoryRepository {
  CategoryRepository(this._isar);

  final Isar _isar;

  Stream<List<Category>> watchAll() {
    return _isar.categoryIsars
        .filter()
        .deletedAtIsNull()
        .sortBySortOrder()
        .watch(fireImmediately: true)
        .map((records) => records.map(categoryFromIsar).toList());
  }

  Future<List<Category>> getAllActive() async {
    final records = await _isar.categoryIsars
        .filter()
        .deletedAtIsNull()
        .sortBySortOrder()
        .findAll();
    return records.map(categoryFromIsar).toList();
  }

  Future<Category?> findById(String id) async {
    final record =
        await _isar.categoryIsars.filter().uuidEqualTo(id).findFirst();
    if (record == null || record.isDeleted) return null;
    return categoryFromIsar(record);
  }

  Future<bool> hasDuplicateName({
    required String name,
    String? excludeId,
  }) async {
    final normalized = name.trim().toLowerCase();
    final records = await _isar.categoryIsars
        .filter()
        .deletedAtIsNull()
        .findAll();

    return records.any(
      (record) =>
          record.uuid != excludeId &&
          record.name.trim().toLowerCase() == normalized,
    );
  }

  /// Returns count of products linked to this category.
  Future<int> countProductsInCategory(String categoryId) async {
    return _isar.productIsars
        .filter()
        .deletedAtIsNull()
        .categoryIdEqualTo(categoryId)
        .count();
  }

  Future<Category> create({
    required String name,
    required String deviceId,
    String? imageUrl,
    bool isActive = true,
  }) async {
    final nextSortOrder = await _nextSortOrder();
    final record = CategoryIsar.create(
      name: name.trim(),
      deviceId: deviceId,
      sortOrder: nextSortOrder,
      imageUrl: imageUrl,
      isActive: isActive,
    );

    await _isar.writeTxn(() async {
      await _isar.categoryIsars.put(record);
    });

    return categoryFromIsar(record);
  }

  Future<Category?> update({
    required Category category,
    required String deviceId,
  }) async {
    final record =
        await _isar.categoryIsars.filter().uuidEqualTo(category.id).findFirst();
    if (record == null || record.isDeleted) return null;

    applyCategoryToIsar(
      record: record,
      category: category,
      deviceId: deviceId,
      action: SyncAction.update,
    );

    await _isar.writeTxn(() async {
      await _isar.categoryIsars.put(record);
    });

    return categoryFromIsar(record);
  }

  Future<bool> softDelete({
    required String id,
    required String deviceId,
  }) async {
    final record =
        await _isar.categoryIsars.filter().uuidEqualTo(id).findFirst();
    if (record == null || record.isDeleted) return false;

    record.markDeleted(deviceId: deviceId);

    await _isar.writeTxn(() async {
      await _isar.categoryIsars.put(record);
    });

    return true;
  }

  Future<void> reorder({
    required List<String> idsInOrder,
    required String deviceId,
  }) async {
    await _isar.writeTxn(() async {
      for (var index = 0; index < idsInOrder.length; index++) {
        final record = await _isar.categoryIsars
            .filter()
            .uuidEqualTo(idsInOrder[index])
            .findFirst();
        if (record == null || record.isDeleted) continue;

        record
          ..sortOrder = index
          ..markUpdated(deviceId: deviceId);

        await _isar.categoryIsars.put(record);
      }
    });
  }

  Future<int> _nextSortOrder() async {
    final records = await _isar.categoryIsars
        .filter()
        .deletedAtIsNull()
        .sortBySortOrderDesc()
        .findAll();
    if (records.isEmpty) return 0;
    return records.first.sortOrder + 1;
  }
}

/// Thrown when a category cannot be deleted because products reference it.
class CategoryInUseException implements Exception {
  CategoryInUseException(this.productCount);

  final int productCount;

  @override
  String toString() =>
      'Cannot delete — $productCount product${productCount == 1 ? '' : 's'} '
      'use this category';
}
