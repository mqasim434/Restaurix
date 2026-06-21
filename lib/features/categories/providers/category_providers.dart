import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/device_id_service.dart';
import '../../../data/local/isar_service.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../domain/models/category.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(isarProvider));
});

final categoryListProvider =
    AsyncNotifierProvider<CategoryListNotifier, List<Category>>(
  CategoryListNotifier.new,
);

class CategoryMutationResult {
  const CategoryMutationResult({
    required this.success,
    this.warningMessage,
    this.errorMessage,
  });

  final bool success;
  final String? warningMessage;
  final String? errorMessage;
}

class CategoryListNotifier extends AsyncNotifier<List<Category>> {
  StreamSubscription<List<Category>>? _subscription;

  CategoryRepository get _repository => ref.read(categoryRepositoryProvider);
  String get _deviceId => ref.read(deviceIdProvider);

  @override
  Future<List<Category>> build() async {
    _subscription?.cancel();
    _subscription = _repository.watchAll().listen(
      (categories) => state = AsyncValue.data(categories),
      onError: (error, stackTrace) =>
          state = AsyncValue.error(error, stackTrace),
    );
    ref.onDispose(() => _subscription?.cancel());

    return _repository.watchAll().first;
  }

  Future<CategoryMutationResult> create({
    required String name,
    String? imageUrl,
    bool isActive = true,
  }) async {
    if (name.trim().isEmpty) {
      return const CategoryMutationResult(
        success: false,
        errorMessage: 'Category name is required',
      );
    }

    String? warning;
    if (await _repository.hasDuplicateName(name: name)) {
      warning = 'A category with a similar name already exists';
    }

    await _repository.create(
      name: name,
      deviceId: _deviceId,
      imageUrl: imageUrl,
      isActive: isActive,
    );

    return CategoryMutationResult(success: true, warningMessage: warning);
  }

  Future<CategoryMutationResult> updateCategory(Category category) async {
    if (category.name.trim().isEmpty) {
      return const CategoryMutationResult(
        success: false,
        errorMessage: 'Category name is required',
      );
    }

    String? warning;
    if (await _repository.hasDuplicateName(
      name: category.name,
      excludeId: category.id,
    )) {
      warning = 'A category with a similar name already exists';
    }

    await _repository.update(category: category, deviceId: _deviceId);
    return CategoryMutationResult(success: true, warningMessage: warning);
  }

  Future<CategoryMutationResult> toggleActive(Category category) async {
    final updated = category.copyWith(isActive: !category.isActive);
    await _repository.update(category: updated, deviceId: _deviceId);
    return const CategoryMutationResult(success: true);
  }

  Future<CategoryMutationResult> delete(String id) async {
    final productCount = await _repository.countProductsInCategory(id);
    if (productCount > 0) {
      return CategoryMutationResult(
        success: false,
        errorMessage: CategoryInUseException(productCount).toString(),
      );
    }

    await _repository.softDelete(id: id, deviceId: _deviceId);
    return const CategoryMutationResult(success: true);
  }

  Future<void> reorder(List<String> idsInOrder) async {
    await _repository.reorder(idsInOrder: idsInOrder, deviceId: _deviceId);
  }
}
