import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/device_id_service.dart';
import '../../../data/local/isar_service.dart';
import '../../../data/repositories/modifier_group_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../domain/models/item_modifier.dart';
import '../../../domain/models/modifier_group.dart';
import '../../../domain/models/modifier_selection_type.dart';
import '../../../domain/models/product.dart';
import '../../products/providers/product_providers.dart';

final modifierGroupRepositoryProvider = Provider<ModifierGroupRepository>((ref) {
  return ModifierGroupRepository(ref.watch(isarProvider));
});

final modifierGroupListProvider =
    AsyncNotifierProvider<ModifierGroupListNotifier, List<ModifierGroup>>(
  ModifierGroupListNotifier.new,
);

final groupModifiersProvider =
    StreamProvider.autoDispose.family<List<ItemModifier>, String>(
  (ref, groupId) {
    return ref.watch(modifierGroupRepositoryProvider).watchModifiersByGroup(groupId);
  },
);

final modifierGroupActionsProvider = Provider<ModifierGroupActions>((ref) {
  return ModifierGroupActions(
    repository: ref.watch(modifierGroupRepositoryProvider),
    deviceId: ref.watch(deviceIdProvider),
  );
});

final productModifierAssignmentProvider =
    Provider<ProductModifierAssignment>((ref) {
  return ProductModifierAssignment(
    productRepository: ref.watch(productRepositoryProvider),
    modifierRepository: ref.watch(modifierGroupRepositoryProvider),
    deviceId: ref.watch(deviceIdProvider),
  );
});

class ModifierMutationResult {
  const ModifierMutationResult({
    required this.success,
    this.errorMessage,
    this.warningMessage,
  });

  final bool success;
  final String? errorMessage;
  final String? warningMessage;
}

class ModifierGroupListNotifier extends AsyncNotifier<List<ModifierGroup>> {
  StreamSubscription<List<ModifierGroup>>? _subscription;

  ModifierGroupRepository get _repository =>
      ref.read(modifierGroupRepositoryProvider);

  @override
  Future<List<ModifierGroup>> build() async {
    _subscription?.cancel();
    _subscription = _repository.watchAllGroups().listen(
      (groups) => state = AsyncValue.data(groups),
      onError: (error, stackTrace) =>
          state = AsyncValue.error(error, stackTrace),
    );
    ref.onDispose(() => _subscription?.cancel());

    return _repository.watchAllGroups().first;
  }
}

class ModifierGroupActions {
  ModifierGroupActions({required this.repository, required this.deviceId});

  final ModifierGroupRepository repository;
  final String deviceId;

  Future<ModifierGroup> createGroup({
    required String name,
    ModifierSelectionType selectionType = ModifierSelectionType.multiple,
    bool isRequired = false,
    int minSelections = 0,
    int? maxSelections,
  }) {
    return repository.createGroup(
      name: name,
      deviceId: deviceId,
      selectionType: selectionType,
      isRequired: isRequired,
      minSelections: minSelections,
      maxSelections: maxSelections,
    );
  }

  Future<ModifierGroup?> updateGroup(ModifierGroup group) {
    return repository.updateGroup(group: group, deviceId: deviceId);
  }

  Future<List<Product>> findProductsUsingGroup(String groupId) {
    return repository.findProductsUsingGroup(groupId);
  }

  Future<bool> deleteGroup(String id) {
    return repository.softDeleteGroup(id: id, deviceId: deviceId);
  }

  Future<ItemModifier> createModifier({
    required String groupId,
    required String name,
    required double priceDelta,
  }) {
    return repository.createModifier(
      groupId: groupId,
      name: name,
      priceDelta: priceDelta,
      deviceId: deviceId,
    );
  }

  Future<ItemModifier?> updateModifier(ItemModifier modifier) {
    return repository.updateModifier(modifier: modifier, deviceId: deviceId);
  }

  Future<bool> deleteModifier(String id) {
    return repository.softDeleteModifier(id: id, deviceId: deviceId);
  }

  Future<void> reorderModifiers({
    required String groupId,
    required List<String> idsInOrder,
  }) {
    return repository.reorderModifiers(
      groupId: groupId,
      idsInOrder: idsInOrder,
      deviceId: deviceId,
    );
  }
}

class ProductModifierAssignment {
  ProductModifierAssignment({
    required this.productRepository,
    required this.modifierRepository,
    required this.deviceId,
  });

  final ProductRepository productRepository;
  final ModifierGroupRepository modifierRepository;
  final String deviceId;

  Future<Product?> assignGroups({
    required String productId,
    required List<String> groupIds,
  }) {
    return productRepository.updateModifierGroupIds(
      productId: productId,
      groupIds: groupIds,
      deviceId: deviceId,
    );
  }
}
