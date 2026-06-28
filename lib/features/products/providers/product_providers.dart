import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/device_id_service.dart';
import '../../../data/local/isar_service.dart';
import '../../../core/constants.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../domain/models/product.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(isarProvider));
});

final productListProvider =
    AsyncNotifierProvider<ProductListNotifier, List<Product>>(
  ProductListNotifier.new,
);

/// Category filter — null means all categories.
final productCategoryFilterProvider = StateProvider<String?>((ref) => null);

/// Debounced search query applied to product name filtering.
final productSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final productsAsync = ref.watch(productListProvider);
  final categoryFilter = ref.watch(productCategoryFilterProvider);
  final searchQuery = ref.watch(productSearchQueryProvider).trim().toLowerCase();

  return productsAsync.when(
    loading: () => const AsyncValue.loading(),
    error: AsyncValue.error,
    data: (products) {
      var filtered = products;

      if (categoryFilter != null) {
        filtered =
            filtered.where((p) => p.categoryId == categoryFilter).toList();
      }

      if (searchQuery.isNotEmpty) {
        filtered = filtered
            .where((p) => p.name.toLowerCase().contains(searchQuery))
            .toList();
      }

      return AsyncValue.data(filtered);
    },
  );
});

class ProductMutationResult {
  const ProductMutationResult({
    required this.success,
    this.errorMessage,
  });

  final bool success;
  final String? errorMessage;
}

class ProductListNotifier extends AsyncNotifier<List<Product>> {
  StreamSubscription<List<Product>>? _subscription;

  ProductRepository get _repository => ref.read(productRepositoryProvider);
  String get _deviceId => ref.read(deviceIdProvider);

  @override
  Future<List<Product>> build() async {
    _subscription?.cancel();
    _subscription = _repository.watchAll().listen(
      (products) => state = AsyncValue.data(products),
      onError: (error, stackTrace) =>
          state = AsyncValue.error(error, stackTrace),
    );
    ref.onDispose(() => _subscription?.cancel());

    return _repository.watchAll().first;
  }

  Future<ProductMutationResult> create({
    required String name,
    required String categoryId,
    required double basePrice,
    String? description,
    String? imageUrl,
    bool isAvailable = true,
    String kitchenCategory = '',
    String? printerId,
    int estimatedPrepMinutes = AppConstants.defaultProductPrepMinutes,
  }) async {
    if (name.trim().isEmpty) {
      return const ProductMutationResult(
        success: false,
        errorMessage: 'Product name is required',
      );
    }
    if (categoryId.isEmpty) {
      return const ProductMutationResult(
        success: false,
        errorMessage: 'Category is required',
      );
    }
    if (basePrice < 0) {
      return const ProductMutationResult(
        success: false,
        errorMessage: 'Price cannot be negative',
      );
    }

    await _repository.create(
      name: name,
      categoryId: categoryId,
      basePrice: basePrice,
      deviceId: _deviceId,
      description: description,
      imageUrl: imageUrl,
      isAvailable: isAvailable,
      kitchenCategory: kitchenCategory,
      printerId: printerId,
      estimatedPrepMinutes: estimatedPrepMinutes,
    );

    return const ProductMutationResult(success: true);
  }

  Future<ProductMutationResult> updateProduct(Product product) async {
    if (product.name.trim().isEmpty) {
      return const ProductMutationResult(
        success: false,
        errorMessage: 'Product name is required',
      );
    }

    await _repository.update(product: product, deviceId: _deviceId);
    return const ProductMutationResult(success: true);
  }

  Future<ProductMutationResult> toggleAvailability(String id) async {
    await _repository.toggleAvailability(id: id, deviceId: _deviceId);
    return const ProductMutationResult(success: true);
  }

  Future<ProductMutationResult> delete(String id) async {
    await _repository.softDelete(id: id, deviceId: _deviceId);
    return const ProductMutationResult(success: true);
  }
}
