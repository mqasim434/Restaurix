import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/order_repository.dart';
import '../../orders/providers/order_management_providers.dart';
import '../../products/providers/product_providers.dart';
import '../../tables/providers/table_providers.dart';
import '../providers/cart_providers.dart';
import '../providers/checkout_providers.dart';
import '../providers/discount_providers.dart';
import '../services/order_edit_service.dart';

final editingOrderIdProvider = StateProvider<String?>((ref) => null);

final orderEditLoaderProvider =
    Provider<OrderEditLoader>((ref) => OrderEditLoader(ref));

class OrderEditLoader {
  OrderEditLoader(this._ref);

  final Ref _ref;

  Future<void> loadIntoPos(String orderId) async {
    final repo = _ref.read(orderRepositoryProvider);
    final order = await repo.findById(orderId);
    if (order == null) {
      throw OrderPlacementException('Order not found');
    }

    final items = await repo.findItemsByOrderId(orderId);
    final productRepo = _ref.read(productRepositoryProvider);
    final categoryIds = <String, String?>{};

    for (final item in items) {
      if (item.productId == null) continue;
      final product = await productRepo.findById(item.productId!);
      categoryIds[item.productId!] = product?.categoryId;
    }

    final snapshot = buildOrderEditSnapshot(
      order: order,
      items: items,
      productCategoryIds: categoryIds,
    );

    var checkout = snapshot.checkout;
    if (order.tableId != null) {
      final table =
          await _ref.read(tableRepositoryProvider).findById(order.tableId!);
      checkout = checkout.copyWith(
        tableId: order.tableId,
        tableLabel: table?.label ?? 'Table',
      );
    }

    _ref.read(cartProvider.notifier).clear();
    _ref.read(cartDiscountsProvider.notifier).replaceAll(snapshot.discounts);

    for (final cartItem in snapshot.cartItems) {
      _ref.read(cartProvider.notifier).add(cartItem);
    }

    _ref.read(checkoutProvider.notifier).restoreDraft(checkout);
    _ref.read(editingOrderIdProvider.notifier).state = orderId;
  }

  void clearEditMode() {
    _ref.read(editingOrderIdProvider.notifier).state = null;
  }
}
