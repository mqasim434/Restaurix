import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurix/domain/models/cart_item.dart';
import 'package:restaurix/features/pos/providers/cart_providers.dart';

void main() {
  group('CartItem', () {
    test('matchesConfiguration ignores modifier order', () {
      const modifiersA = [
        CartModifier(id: 'b', groupId: 'g1', name: 'B', priceDelta: 1),
        CartModifier(id: 'a', groupId: 'g1', name: 'A', priceDelta: 0.5),
      ];
      const modifiersB = [
        CartModifier(id: 'a', groupId: 'g1', name: 'A', priceDelta: 0.5),
        CartModifier(id: 'b', groupId: 'g1', name: 'B', priceDelta: 1),
      ];

      final left = CartItem(
        lineId: '1',
        productId: 'p1',
        name: 'Burger',
        unitPrice: 10,
        modifiers: modifiersA,
      );
      final right = CartItem(
        lineId: '2',
        productId: 'p1',
        name: 'Burger',
        unitPrice: 10,
        modifiers: modifiersB,
      );

      expect(left.matchesConfiguration(right), isTrue);
    });

    test('matchesConfiguration treats different modifiers as separate lines', () {
      final left = CartItem(
        lineId: '1',
        productId: 'p1',
        name: 'Burger',
        unitPrice: 10,
        modifiers: const [
          CartModifier(id: 'a', groupId: 'g1', name: 'A', priceDelta: 0),
        ],
      );
      final right = CartItem(
        lineId: '2',
        productId: 'p1',
        name: 'Burger',
        unitPrice: 10,
        modifiers: const [
          CartModifier(id: 'b', groupId: 'g1', name: 'B', priceDelta: 0),
        ],
      );

      expect(left.matchesConfiguration(right), isFalse);
    });
  });

  group('CartNotifier', () {
    test('add merges matching configurations', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(cartProvider.notifier);
      notifier.add(
        CartItem(
          lineId: 'line-1',
          productId: 'p1',
          name: 'Burger',
          unitPrice: 9,
        ),
      );
      notifier.add(
        CartItem(
          lineId: 'line-2',
          productId: 'p1',
          name: 'Burger',
          unitPrice: 9,
        ),
      );

      final items = container.read(cartProvider);
      expect(items, hasLength(1));
      expect(items.first.quantity, 2);
      expect(container.read(cartTotalProvider), 18);
    });
  });
}
