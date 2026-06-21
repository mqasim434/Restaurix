import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/cart_item.dart';

/// Session-scoped cart — survives sidebar navigation within the app session.
final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(
  CartNotifier.new,
);

final cartTotalProvider = Provider<double>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold(0.0, (sum, item) => sum + item.lineTotal);
});

final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).fold(0, (sum, item) => sum + item.quantity);
});

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => const [];

  void add(CartItem item) {
    final items = [...state];
    final index = items.indexWhere((existing) => existing.matchesConfiguration(item));

    if (index >= 0) {
      final existing = items[index];
      items[index] = existing.copyWith(quantity: existing.quantity + item.quantity);
    } else {
      items.add(item);
    }

    state = items;
  }

  void remove(String lineId) {
    state = state.where((item) => item.lineId != lineId).toList();
  }

  void updateQuantity(String lineId, int quantity) {
    if (quantity <= 0) {
      remove(lineId);
      return;
    }

    state = [
      for (final item in state)
        if (item.lineId == lineId) item.copyWith(quantity: quantity) else item,
    ];
  }

  void clear() {
    state = const [];
  }
}
