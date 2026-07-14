import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/device_id_service.dart';
import '../../../data/local/isar_service.dart';
import '../../../data/repositories/deal_repository.dart';
import '../../../domain/models/deal.dart';
import '../../../domain/models/deal_item.dart';
import '../../../domain/models/product.dart';
import '../../products/providers/product_providers.dart';

final dealRepositoryProvider = Provider<DealRepository>((ref) {
  return DealRepository(ref.watch(isarProvider));
});

final dealListProvider =
    AsyncNotifierProvider<DealListNotifier, List<Deal>>(DealListNotifier.new);

final dealItemsProvider =
    StreamProvider.autoDispose.family<List<DealItem>, String>(
  (ref, dealId) {
    return ref.watch(dealRepositoryProvider).watchItemsByDealId(dealId);
  },
);

final dealActionsProvider = Provider<DealActions>((ref) {
  return DealActions(
    repository: ref.watch(dealRepositoryProvider),
    deviceId: ref.watch(deviceIdProvider),
  );
});

/// Effective availability for a deal given current products and bundle items.
final dealEffectiveAvailabilityProvider =
    Provider.autoDispose.family<bool, String>((ref, dealId) {
  final deals = ref.watch(dealListProvider).valueOrNull ?? [];
  final deal = deals.where((d) => d.id == dealId).firstOrNull;
  if (deal == null) return false;

  final items = ref.watch(dealItemsProvider(dealId)).valueOrNull ?? [];
  final products = ref.watch(productListProvider).valueOrNull ?? [];
  final productsById = {for (final p in products) p.id: p};

  return deal.isEffectivelyAvailable(
    items: items,
    productsById: productsById,
  );
});

class DealMutationResult {
  const DealMutationResult({
    required this.success,
    this.errorMessage,
  });

  final bool success;
  final String? errorMessage;
}

class DealListNotifier extends AsyncNotifier<List<Deal>> {
  StreamSubscription<List<Deal>>? _subscription;

  DealRepository get _repository => ref.read(dealRepositoryProvider);
  String get _deviceId => ref.read(deviceIdProvider);

  @override
  Future<List<Deal>> build() async {
    _subscription?.cancel();
    _subscription = _repository.watchAll().listen(
      (deals) => state = AsyncValue.data(deals),
      onError: (error, stackTrace) =>
          state = AsyncValue.error(error, stackTrace),
    );
    ref.onDispose(() => _subscription?.cancel());

    return _repository.watchAll().first;
  }

  Future<DealMutationResult> create({
    required String name,
    required double price,
    String? description,
    String? imageUrl,
    String? categoryId,
    bool isAvailable = true,
    DateTime? availabilityStart,
    DateTime? availabilityEnd,
  }) async {
    if (name.trim().isEmpty) {
      return const DealMutationResult(
        success: false,
        errorMessage: 'Deal name is required',
      );
    }
    if (price < 0) {
      return const DealMutationResult(
        success: false,
        errorMessage: 'Price cannot be negative',
      );
    }

    await _repository.create(
      name: name,
      price: price,
      deviceId: _deviceId,
      description: description,
      imageUrl: imageUrl,
      categoryId: categoryId,
      isAvailable: isAvailable,
      availabilityStart: availabilityStart,
      availabilityEnd: availabilityEnd,
    );

    return const DealMutationResult(success: true);
  }

  Future<DealMutationResult> updateDeal(Deal deal) async {
    if (deal.name.trim().isEmpty) {
      return const DealMutationResult(
        success: false,
        errorMessage: 'Deal name is required',
      );
    }

    await _repository.update(deal: deal, deviceId: _deviceId);
    return const DealMutationResult(success: true);
  }

  Future<DealMutationResult> toggleAvailability(String id) async {
    await _repository.toggleAvailability(id: id, deviceId: _deviceId);
    return const DealMutationResult(success: true);
  }

  Future<DealMutationResult> delete(String id) async {
    await _repository.softDelete(id: id, deviceId: _deviceId);
    return const DealMutationResult(success: true);
  }
}

class DealActions {
  DealActions({required this.repository, required this.deviceId});

  final DealRepository repository;
  final String deviceId;

  Future<DealItem> createItem({
    required String dealId,
    required String productId,
    String? variantId,
    int quantity = 1,
  }) {
    return repository.createItem(
      dealId: dealId,
      productId: productId,
      deviceId: deviceId,
      variantId: variantId,
      quantity: quantity,
    );
  }

  Future<DealItem?> updateItem(DealItem item) {
    return repository.updateItem(item: item, deviceId: deviceId);
  }

  Future<bool> deleteItem(String id) {
    return repository.softDeleteItem(id: id, deviceId: deviceId);
  }
}

Map<String, Product> productMapById(List<Product> products) {
  return {for (final p in products) p.id: p};
}
