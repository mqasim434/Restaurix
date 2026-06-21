import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/device_id_service.dart';
import '../../../data/local/isar_service.dart';
import '../../../data/repositories/variant_repository.dart';
import '../../../domain/models/product_variant.dart';

final variantRepositoryProvider = Provider<VariantRepository>((ref) {
  return VariantRepository(ref.watch(isarProvider));
});

final productVariantsProvider =
    StreamProvider.autoDispose.family<List<ProductVariant>, String>(
  (ref, productId) {
    return ref.watch(variantRepositoryProvider).watchByProductId(productId);
  },
);

final variantActionsProvider = Provider<VariantActions>((ref) {
  return VariantActions(
    repository: ref.watch(variantRepositoryProvider),
    deviceId: ref.watch(deviceIdProvider),
  );
});

class VariantActions {
  VariantActions({required this.repository, required this.deviceId});

  final VariantRepository repository;
  final String deviceId;

  Future<ProductVariant> create({
    required String productId,
    required String name,
    required double price,
    bool isDefault = false,
  }) {
    return repository.create(
      productId: productId,
      name: name,
      price: price,
      deviceId: deviceId,
      isDefault: isDefault,
    );
  }

  Future<ProductVariant?> update(ProductVariant variant) {
    return repository.update(variant: variant, deviceId: deviceId);
  }

  Future<ProductVariant?> setDefault({
    required String variantId,
    required String productId,
  }) {
    return repository.setDefault(
      variantId: variantId,
      productId: productId,
      deviceId: deviceId,
    );
  }

  Future<bool> delete(String id) {
    return repository.softDelete(id: id, deviceId: deviceId);
  }

  Future<void> reorder({
    required String productId,
    required List<String> idsInOrder,
  }) {
    return repository.reorder(
      productId: productId,
      idsInOrder: idsInOrder,
      deviceId: deviceId,
    );
  }
}
