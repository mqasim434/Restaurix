import 'package:isar/isar.dart';

import '../../core/sync/sync_action.dart';
import '../../domain/models/item_modifier.dart';
import '../../domain/models/modifier_group.dart';
import '../../domain/models/modifier_selection_type.dart';
import '../../domain/models/product.dart';
import '../local/collections/item_modifier_isar.dart';
import '../local/collections/modifier_group_isar.dart';
import '../local/collections/product_isar.dart';
import '../local/mappers/modifier_mapper.dart';
import '../local/mappers/product_mapper.dart';

class ModifierGroupRepository {
  ModifierGroupRepository(this._isar);

  final Isar _isar;

  Stream<List<ModifierGroup>> watchAllGroups() {
    return _isar.modifierGroupIsars
        .filter()
        .deletedAtIsNull()
        .sortByName()
        .watch(fireImmediately: true)
        .map((records) => records.map(modifierGroupFromIsar).toList());
  }

  Stream<List<ItemModifier>> watchModifiersByGroup(String groupId) {
    return _isar.itemModifierIsars
        .filter()
        .groupIdEqualTo(groupId)
        .deletedAtIsNull()
        .sortBySortOrder()
        .watch(fireImmediately: true)
        .map((records) => records.map(itemModifierFromIsar).toList());
  }

  Future<List<Product>> findProductsUsingGroup(String groupId) async {
    final records = await _isar.productIsars
        .filter()
        .deletedAtIsNull()
        .modifierGroupIdsElementEqualTo(groupId)
        .findAll();
    return records.map(productFromIsar).toList();
  }

  Future<ModifierGroup> createGroup({
    required String name,
    required String deviceId,
    ModifierSelectionType selectionType = ModifierSelectionType.multiple,
    bool isRequired = false,
    int minSelections = 0,
    int? maxSelections,
  }) async {
    final record = ModifierGroupIsar.create(
      name: name.trim(),
      deviceId: deviceId,
      selectionType: selectionType,
      isRequired: isRequired,
      minSelections: minSelections,
      maxSelections: maxSelections,
    );

    await _isar.writeTxn(() async {
      await _isar.modifierGroupIsars.put(record);
    });

    return modifierGroupFromIsar(record);
  }

  Future<ModifierGroup?> updateGroup({
    required ModifierGroup group,
    required String deviceId,
  }) async {
    final record = await _isar.modifierGroupIsars
        .filter()
        .uuidEqualTo(group.id)
        .findFirst();
    if (record == null || record.isDeleted) return null;

    applyModifierGroupToIsar(
      record: record,
      group: group,
      deviceId: deviceId,
      action: SyncAction.update,
    );

    await _isar.writeTxn(() async {
      await _isar.modifierGroupIsars.put(record);
    });

    return modifierGroupFromIsar(record);
  }

  Future<bool> softDeleteGroup({
    required String id,
    required String deviceId,
  }) async {
    final record =
        await _isar.modifierGroupIsars.filter().uuidEqualTo(id).findFirst();
    if (record == null || record.isDeleted) return false;

    await _isar.writeTxn(() async {
      record.markDeleted(deviceId: deviceId);
      await _isar.modifierGroupIsars.put(record);

      final modifiers = await _isar.itemModifierIsars
          .filter()
          .groupIdEqualTo(id)
          .deletedAtIsNull()
          .findAll();
      for (final modifier in modifiers) {
        modifier.markDeleted(deviceId: deviceId);
        await _isar.itemModifierIsars.put(modifier);
      }

      await _detachGroupFromProducts(id, deviceId);
    });

    return true;
  }

  Future<ItemModifier> createModifier({
    required String groupId,
    required String name,
    required double priceDelta,
    required String deviceId,
  }) async {
    final existing = await _isar.itemModifierIsars
        .filter()
        .groupIdEqualTo(groupId)
        .deletedAtIsNull()
        .sortBySortOrderDesc()
        .findAll();
    final sortOrder = existing.isEmpty ? 0 : existing.first.sortOrder + 1;

    final record = ItemModifierIsar.create(
      groupId: groupId,
      name: name.trim(),
      priceDelta: priceDelta,
      deviceId: deviceId,
      sortOrder: sortOrder,
    );

    await _isar.writeTxn(() async {
      await _isar.itemModifierIsars.put(record);
    });

    return itemModifierFromIsar(record);
  }

  Future<ItemModifier?> updateModifier({
    required ItemModifier modifier,
    required String deviceId,
  }) async {
    final record = await _isar.itemModifierIsars
        .filter()
        .uuidEqualTo(modifier.id)
        .findFirst();
    if (record == null || record.isDeleted) return null;

    applyItemModifierToIsar(
      record: record,
      modifier: modifier,
      deviceId: deviceId,
      action: SyncAction.update,
    );

    await _isar.writeTxn(() async {
      await _isar.itemModifierIsars.put(record);
    });

    return itemModifierFromIsar(record);
  }

  Future<bool> softDeleteModifier({
    required String id,
    required String deviceId,
  }) async {
    final record =
        await _isar.itemModifierIsars.filter().uuidEqualTo(id).findFirst();
    if (record == null || record.isDeleted) return false;

    record.markDeleted(deviceId: deviceId);

    await _isar.writeTxn(() async {
      await _isar.itemModifierIsars.put(record);
    });

    return true;
  }

  Future<void> reorderModifiers({
    required String groupId,
    required List<String> idsInOrder,
    required String deviceId,
  }) async {
    await _isar.writeTxn(() async {
      for (var index = 0; index < idsInOrder.length; index++) {
        final record = await _isar.itemModifierIsars
            .filter()
            .uuidEqualTo(idsInOrder[index])
            .findFirst();
        if (record == null || record.isDeleted) continue;

        record
          ..sortOrder = index
          ..markUpdated(deviceId: deviceId);

        await _isar.itemModifierIsars.put(record);
      }
    });
  }

  Future<void> _detachGroupFromProducts(String groupId, String deviceId) async {
    final products = await _isar.productIsars
        .filter()
        .deletedAtIsNull()
        .modifierGroupIdsElementEqualTo(groupId)
        .findAll();

    for (final product in products) {
      product
        ..modifierGroupIds = product.modifierGroupIds
            .where((id) => id != groupId)
            .toList()
        ..markUpdated(deviceId: deviceId);
      await _isar.productIsars.put(product);
    }
  }
}

/// Stored on Product as a list of group UUIDs (many-to-many, no join table).
const modifierGroupAssignmentDoc =
    'Product.modifierGroupIds holds assigned ModifierGroup UUIDs.';
